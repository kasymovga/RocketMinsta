
.entity zapper_beam;
.float zapper_range;
.float zapper_expire;
.float zapper_tracespeed;
.float zapper_lastdmg;
.float zapper_dmgdelay;
.float zapper_arc_hit;
.float zapper_heat;
.float zapper_coolofftime;

.entity zapper_shotorgsentfor;

.vector zapper_beam_start, zapper_beam_end;

float W_Zapper_Attack1_CheckAmmo(entity p) {
    return p.ammo_cells >= cvar("g_balance_zapper_primary_ammo");
}

float W_Zapper_Attack2_CheckAmmo(entity p) {
    return p.ammo_cells >= cvar("g_balance_zapper_secondary_ammo");
}

vector W_Zapper_LocalShotOrg(entity p) {
    entity o = self.owner;
    self.owner = p;
    vector v = shotorg_adjust('30 10 -18', TRUE, TRUE);
    self.owner = o;
    return v;
}

float W_Zapper_Beam_Send(entity to, float sf) {
    sf &~= 8;

    if(to.zapper_shotorgsentfor != self) {
        if(to == self.owner || (to.enemy == self.owner && to.classname == "spectator")) {
            sf |= 8;
        }
    }

    WriteByte(MSG_ENTITY, ENT_CLIENT_ZAPPER);
    WriteByte(MSG_ENTITY, sf);

    if(sf & 1) {
        float o = num_for_edict(self.owner);

        if(o > maxclients)
            o = 0;

        WriteByte(MSG_ENTITY, o);

        if(!o)
            WriteByte(MSG_ENTITY, self.team);
    }

    if(sf & 2) {
        WriteCoord(MSG_ENTITY, self.zapper_beam_start_x);
        WriteCoord(MSG_ENTITY, self.zapper_beam_start_y);
        WriteCoord(MSG_ENTITY, self.zapper_beam_start_z);
    }

    if(sf & 4) {
        WriteCoord(MSG_ENTITY, self.zapper_beam_end_x);
        WriteCoord(MSG_ENTITY, self.zapper_beam_end_y);
        WriteCoord(MSG_ENTITY, self.zapper_beam_end_z);
    }

    if(sf & 8) {
        WriteInt24_t(MSG_ENTITY, compressShotOrigin(W_Zapper_LocalShotOrg(self.owner)));
        to.zapper_shotorgsentfor = self;
    }

    return TRUE;
}

float W_Zapper_Beam_Expired(void) {
    if(time > self.zapper_expire)
        return TRUE;

    if(self.owner.zapper_heat >= 1)
        return TRUE;

    if(self.owner.weapon != WEP_ZAPPER)
        return TRUE;

    if(self.owner.deadflag != DEAD_NO)
        return TRUE;

    if(self.owner.frozen)
        return TRUE;

    if(self.owner.hg_stealth)
        return TRUE;

    if(!W_Zapper_Attack1_CheckAmmo(self.owner))
        return TRUE;

    return FALSE;
}

void W_Zapper_Beam_Think(void) {
    if(W_Zapper_Beam_Expired()) {
        if(self.owner.zapper_beam == self)
            self.owner.zapper_beam = world;
        remove(self);
        return;
    }

    makevectors(self.owner.v_angle);
    W_SetupShot(self.owner, FALSE, 0, "", -1);

    float fract;
    entity targ;
    vector end = w_shotorg + w_shotdir * self.zapper_range;
    entity o = self.owner;

    if(self.zapper_tracespeed) {
        if(!self.origin)
            self.origin = end;
        else
            self.origin += (end - self.origin) * frametime * self.zapper_tracespeed;

        end = self.origin;
    }

    traceline_antilag(o, w_shotorg, end, FALSE, self);

    targ = trace_ent;
    end = trace_endpos;
    fract = trace_fraction;

    float dt = time - self.zapper_lastdmg;
    float rate = W_WeaponRateFactorFor(self.owner);
    float damageIsDps = FALSE;
    
    if(dt < frametime)
    if(almost_equals(dt, frametime))
        dt = frametime;
    
    float wantedTicrate = self.zapper_dmgdelay * rate;
    
    if(wantedTicrate <= 0) {
        wantedTicrate = dt;
        damageIsDps = TRUE;
    } else if(almost_equals(dt, wantedTicrate)) {
        dt = wantedTicrate;
    }
    
    for ( ;dt >= wantedTicrate; dt -= wantedTicrate) {
        float damage = cvar("g_balance_zapper_primary_damage");
        float force  = cvar("g_balance_zapper_primary_force");
        
        if(damageIsDps) {
            damage = damage * wantedTicrate;
            force = force * wantedTicrate;
        }
        
        W_Accuracy_RegisterShot(o, o.weapon);
        W_Accuracy_RegisterHit(o, targ, o.weapon);

        if(targ.takedamage) {
            float d = (end - w_shotorg) * w_shotdir;

            float mindist = cvar("g_balance_zapper_primary_damagefalloff_mindist");
            float maxdist = cvar("g_balance_zapper_primary_damagefalloff_maxdist");
            float halflifedist = cvar("g_balance_zapper_primary_damagefalloff_halflife");
            float forcehalflifedist = cvar("g_balance_zapper_primary_damagefalloff_forcehalflife");

            damage *= ExponentialFalloff(mindist, maxdist, halflifedist, d);
            force  *= ExponentialFalloff(mindist, maxdist, forcehalflifedist, d);

            Damage(targ, self, self.owner, damage, WEP_ZAPPER, end, force * w_shotdir);
        }

        if(fract < 1)
        if(targ.solid == SOLID_BSP && !(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT))
            Damage_DamageInfo(end, damage, 0, 0, force * w_shotdir, WEP_ZAPPER, self);

        if(!(o.items & IT_UNLIMITED_AMMO))
            o.ammo_cells -= cvar("g_balance_zapper_primary_ammo");

        self.zapper_lastdmg += wantedTicrate;
    }

    vector org = gettaginfo(self.owner.exteriorweaponentity, gettagindex(self.owner.exteriorweaponentity, "_"));

    if(org)
        org = org + v_forward * self.owner.exteriorweaponentity.maxs_x * 0.66 + v_up * self.owner.exteriorweaponentity.maxs_z * 0.4;
    else
        org = w_shotorg;

    if(org != self.zapper_beam_start) {
        self.SendFlags |= 2;
        self.zapper_beam_start = org;
    }

    if(end != self.zapper_beam_end) {
        self.SendFlags |= 4;
        self.zapper_beam_end = end;
    }

    if(self.owner.zapper_heat >= 0) {
        self.owner.zapper_heat = bound(0, self.owner.zapper_heat + (cvar("g_balance_zapper_primary_heatup") * frametime) / rate, 1);
        self.owner.zapper_coolofftime = time;
    }

    self.nextthink = time;
}

void W_Zapper_Attack1(void) {
    if(!W_Zapper_Attack1_CheckAmmo(self))
        return;

    sound(self, CHAN_WEAPON, "weapons/zapper_fire.wav", VOL_BASE, ATTN_NORM);

    entity o, e = spawn();
    e.classname = "zapper_beam";
    e.think = W_Zapper_Beam_Think;
    e.owner = self;

    e.zapper_tracespeed = cvar("g_balance_zapper_primary_tracespeed");
    e.zapper_range = cvar("g_balance_zapper_primary_range");
    e.zapper_expire = time + cvar("g_balance_zapper_primary_lifetime");
    e.zapper_dmgdelay = cvar("g_balance_zapper_primary_ticrate");
    e.zapper_lastdmg = time - e.zapper_dmgdelay * W_WeaponRateFactorFor(self);
    
    Net_LinkEntity(e, FALSE, 0, W_Zapper_Beam_Send);

    self.zapper_shotorgsentfor = world;

    o = self;
    self = e;
    self.think();
    self = o;
    
    self.zapper_beam = e;
}

void W_Zapper_Attack2_Effect(float ateam, vector from, vector to) {
    WriteByte(MSG_BROADCAST, SVC_TEMPENTITY);
    WriteByte(MSG_BROADCAST, TE_CSQC_ZAPPERLIGHTNING);
    
    WriteByte(MSG_BROADCAST, ateam-1);
    WriteCoord(MSG_BROADCAST, from_x);
    WriteCoord(MSG_BROADCAST, from_y);
    WriteCoord(MSG_BROADCAST, from_z);
    WriteCoord(MSG_BROADCAST, to_x);
    WriteCoord(MSG_BROADCAST, to_y);
    WriteCoord(MSG_BROADCAST, to_z);
}

void W_Zapper_Attack2_Arc(entity targ, entity attacker, float damage) {
    float arc = cvar("g_balance_zapper_secondary_arc");

    if(arc <= 0)
        return;

    float targetTeamMates = (teams_matter && Buffs_BuffPower(attacker, BUFF_MEDIC) && targ.team == attacker.team);
    
    if(targ.team == attacker.team && !targetTeamMates)
        return;
    
    float targetFrozen = targ.frozen && !targetTeamMates;
    float targetAlive = !targetFrozen && !targetTeamMates;
    float deathtype = WEP_ZAPPER | HITTYPE_SECONDARY;

    Buffs_ArcDamage_Proc(targ, attacker, damage, deathtype, deathtype | HITTYPE_BOUNCE, 1,
                         attacker.maxs_z * '0 0 0.5',
                         cvar("g_balance_zapper_secondary_arc_range"), arc, 1,
                         cvar("g_balance_zapper_secondary_arc_force"),
                         targetTeamMates, targetFrozen, targetAlive, zapper_arc_hit);
    
    entity e; for(e = world; (e = findfloat(e, zapper_arc_hit, TRUE));)
        e.zapper_arc_hit = FALSE;
}

void W_Zapper_Attack2(void) {
    float damage = cvar("g_balance_zapper_secondary_damage");
    float force  = cvar("g_balance_zapper_secondary_force");
    float range  = cvar("g_balance_zapper_secondary_range");

    makevectors(self.v_angle);
    W_SetupShot(self, TRUE, 5, strcat("misc/arc", ftos(1 + (random() > 0.5)), ".wav"), damage);
    
    entity targ;
    vector end = w_shotorg + w_shotdir * range;
    entity pts = Buffs_MEODP_Hitscan_Begin(self);

    entity temp = spawn();
    traceline_antilag(self, w_shotorg, end, FALSE, temp);
    remove(temp);

    targ = trace_ent;
    end = trace_endpos;

    W_SetHitscanVisuals(self, end);

    if(targ.takedamage) {
        float d = (end - w_shotorg) * w_shotdir;

        float mindist = cvar("g_balance_zapper_secondary_damagefalloff_mindist");
        float maxdist = cvar("g_balance_zapper_secondary_damagefalloff_maxdist");
        float halflifedist = cvar("g_balance_zapper_secondary_damagefalloff_halflife");
        float forcehalflifedist = cvar("g_balance_zapper_secondary_damagefalloff_forcehalflife");

        damage *= ExponentialFalloff(mindist, maxdist, halflifedist, d);
        force  *= ExponentialFalloff(mindist, maxdist, forcehalflifedist, d);

        if(targ.iscreature)
            W_Zapper_Attack2_Arc(targ, self, damage);

        Damage(targ, self, self, damage, WEP_ZAPPER | HITTYPE_SECONDARY, end, force * w_shotdir);
    }

    Buffs_MEODP_Hitscan_End(pts);

    W_Accuracy_RegisterShot(self, self.weapon);
    W_Accuracy_RegisterHit(self, targ, self.weapon);

    W_Zapper_Attack2_Effect(self.team, w_shotorg_visual, end);

    if(targ.solid == SOLID_BSP && !(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT))
        Damage_DamageInfo(end, damage, 0, 0, force * w_shotdir, WEP_ZAPPER | HITTYPE_SECONDARY, self);

    if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
        self.ammo_cells = self.ammo_cells - cvar("g_balance_zapper_secondary_ammo");

}

void W_Zapper_Cooloff(void) {
    if(self.zapper_heat < 0)
        return;

    float a = bound(0, (time - self.zapper_coolofftime) * cvar("g_balance_zapper_primary_cooloff_accel"), 1);

    if(!a)
        return;

    self.zapper_heat = bound(0, self.zapper_heat - cvar("g_balance_zapper_primary_cooloff") * frametime * a, 1);
}

float w_zapper(float req) {
    if (req == WR_AIM) {
        if(vlen(self.origin-self.enemy.origin) < cvar("g_balance_zapper_primary_range"))
            self.BUTTON_ATCK = bot_aim(1000000, 0, 0.001, FALSE);
        else
            self.BUTTON_ATCK2 = bot_aim(1000000, 0, 0.001, FALSE);
    } else if(req == WR_THINK) {
        if(self.BUTTON_ATCK) {
            if(self.weaponentity.state != WS_RAISE && self.weaponentity.state != WS_DROP) {
                if(self.zapper_heat >= 1) {
                    W_SwitchWeapon_OutOfAmmo(self);
                } else {
                    if(self.zapper_beam)
                        self.zapper_beam.zapper_expire = time + cvar("g_balance_zapper_primary_lifetime");
                    else if(weapon_prepareattack(0, cvar("g_balance_zapper_primary_refire")))   
                        W_Zapper_Attack1();
                    weapon_thinkf(WFRAME_FIRE1, cvar("g_balance_zapper_animtime"), w_ready);
                }
            }
        } else if(self.BUTTON_ATCK2 && cvar("g_balance_zapper_secondary")) {
            if(weapon_prepareattack(0, cvar("g_balance_zapper_secondary_refire"))) {
                W_Zapper_Attack2();
                weapon_thinkf(WFRAME_FIRE1, cvar("g_balance_zapper_animtime"), w_ready);
            }
        }
    } else if(req == WR_PRECACHE) {
        precache_sound("weapons/zapper_fire.wav");
        precache_sound("weapons/zapper_fly.wav");
        precache_sound("misc/arc1.wav");
        precache_sound("misc/arc2.wav");
    } else if(req == WR_RESETPLAYER){
        if(cvar("g_balance_zapper_primary_heatup"))
            self.zapper_heat = 0;
        else
            self.zapper_heat = -1;
    } else if(req == WR_SETUP)
        weapon_setup(WEP_ZAPPER);
    else if(req == WR_CHECKAMMO1)
        return W_Zapper_Attack1_CheckAmmo(self);
    else if(req == WR_CHECKAMMO2)
        return W_Zapper_Attack2_CheckAmmo(self);
    return TRUE;
};

void spawnfunc_weapon_zapper(void) {
    weapon_defaultspawnfunc(WEP_ZAPPER);
}
