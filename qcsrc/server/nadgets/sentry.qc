
float HG_Sentry_TargetIsTaken(entity emitter, entity targ) {
    for(var e = emitter.owner.hg_sentry_emitter_next; e; e = e.hg_sentry_emitter_next)
        if(e != emitter && e.enemy == targ)
            return TRUE;
    return FALSE;
}

float HG_Sentry_TargetIsValid(entity emitter, entity e) {
    var sentry = emitter.owner;

    if(!sentry.realowner)
        return FALSE;

    if(PlayerIsDead(e))
        return FALSE;

    if(!IsDifferentTeam(e, sentry.realowner) && !Buffs_Present(sentry.realowner, BUFF_MEDIC))
        return FALSE;

    if(HG_Sentry_TargetIsTaken(emitter, e))
        return FALSE;

    vector o = sentry.origin + sentry.view_ofs;
    vector t = e.origin + e.view_ofs;

    if(vlen(o - t) > CVAR(g_nadgets_sentry_beam_range))
        return FALSE;

    traceline(o, t, MOVE_NORMAL, sentry);

    if(trace_ent != e)
        return FALSE;

    return TRUE;
}

entity HG_Sentry_FindTarget(entity emitter) {
    var sentry = emitter.owner;

    entity targ, p;
    float range = CVAR(g_nadgets_sentry_beam_range), mindist, dist;
    float medic = Buffs_Present(sentry.realowner, BUFF_MEDIC), medicflag, diffteam;
    vector t, o = sentry.origin + sentry.view_ofs;

    mindist = range;

    if(!sentry.realowner)
        return world;

    FOR_EACH_PLAYER(p) if(!PlayerIsDead(p)) {
        diffteam = (p != sentry.realowner && IsDifferentTeam(sentry, p));

        if(diffteam) {
            if(medicflag)
                continue;
        } else if(!medic)
            continue;

        if(HG_Sentry_TargetIsTaken(emitter, p))
            continue;

        t = WarpZone_FindNearestOrigin(o, p.origin + p.view_ofs, FALSE);
        dist = WarpZone_FindNearestOrigin_length;

        if(diffteam || (!diffteam && medicflag)) {
            if(dist > mindist)
                continue;
        } else if(dist > range)
            continue;

        WarpZone_TraceLine(o, t, MOVE_NORMAL, sentry);

        if(trace_ent != p)
            continue;

        mindist = dist;
        targ = p;

        if(!diffteam)
            medicflag = TRUE;
    }

    return targ;
}

void HG_Sentry_Beam_Think(void) {
    entity targ = self.enemy.enemy;
    vector end = targ.origin + targ.view_ofs * (0.5 + 0.5 * sin(time * 5 + num_for_edict(self)));
    vector start = self.owner.origin + self.owner.view_ofs;
    vector end_transformed;

    end = WarpZone_FindNearestOrigin(start, end, TRUE);
    WarpZone_TraceLine(start, end, MOVE_NORMAL, self);

    targ = trace_ent;
    end_transformed = trace_endpos;
    end = WarpZone_UnTransformOrigin(WarpZone_trace_transform, trace_endpos);

    if(!self.origin)
        self.origin = end;
    else
        self.origin += (end - self.origin) * frametime * 10;

    end = self.origin;

    if(targ.takedamage == DAMAGE_AIM && time > self.cnt) {
        Damage(targ, self, self.owner.realowner, CVAR(g_nadgets_sentry_beam_dps) * 0.1, HG_SENTRY, end, CVAR(g_nadgets_sentry_beam_force) * normalize(end_transformed - WarpZone_TransformOrigin(WarpZone_trace_transform, start)));
        self.cnt = time + 0.1; // FIXME: this is inaccurate
    }

    end -= normalize(end - start) * 5;

    if(start != self.zapper_beam_start) {
        self.zapper_beam_start = start;
        self.SendFlags |= 2;
    }

    if(end != self.zapper_beam_end) {
        self.zapper_beam_end = end;
        self.SendFlags |= 4;
    }

    self.nextthink = time;
}

entity HG_Sentry_Beam_Spawn(entity emitter) {
    var e = spawn(), sentry = emitter.owner;
    e.classname = "hg_sentry_beam";
    e.owner = sentry;
    e.enemy = emitter;
    e.team = sentry.team;
    e.zapper_beam_start = sentry.origin + sentry.view_ofs;
    e.zapper_beam_end = e.zapper_beam_start;
    e.think = HG_Sentry_Beam_Think;
    e.nextthink = time;

    Net_LinkEntity(e, FALSE, 0, W_Zapper_Beam_Send);

    return e;
}

entity HG_Sentry_Emitter_Spawn(entity sentry) {
    return spawn() {
        classname: "hg_sentry_emitter",
        owner: sentry,
        origin: sentry.origin + sentry.view_ofs,
        think: inline void(void) {
            var sentry = self.owner;

            if(time < sentry.cnt || sentry.hg_sentry_energy < CVAR(g_nadgets_sentry_beam_energyrequired)) {
                if(self.zapper_beam)
                    remove(self.zapper_beam);
                self.zapper_beam = world;
                self.enemy = world;
            } else if(!self.zapper_beam) {
                if(!HG_Sentry_TargetIsValid(self, self.enemy))
                    self.enemy = world;

                if(!self.enemy)
                    self.enemy = HG_Sentry_FindTarget(self);

                if(self.enemy)
                    self.zapper_beam = HG_Sentry_Beam_Spawn(self);
            } else {
                if(self.enemy && !HG_Sentry_TargetIsValid(self, self.enemy))
                    self.enemy = HG_Sentry_FindTarget(self);

                if(!self.enemy) {
                    remove(self.zapper_beam);
                    self.zapper_beam = world;
                    self.enemy = world;
                }
            }

            self.nextthink = time;
        },
        nextthink: time
    };
}

void HG_Sentry_Emitter_Remove(entity emitter) {
    if(emitter.zapper_beam)
        remove(emitter.zapper_beam);
    remove(emitter);
}

void HG_Sentry_Interrupt_Capture(void) {
    if(self.hg_sentry_capture_player)
        self.hg_sentry_capture_player.hg_sentry_capture_progress = 0;
    self.hg_sentry_capture_player = world;
    self.hg_sentry_capture_progress = 0;
}

void HG_Sentry_SetOwner(entity sentry, entity newowner) {
    HG_Waypoint_Remove(sentry.hg_waypoint);

    sentry.team = if(teams_matter) newowner.team else 0;
    sentry.colormap = num_for_edict(newowner);
    sentry.aiment.colormap = sentry.colormap;

    if(newowner) {
        sentry.skin = 0;
        sentry.aiment.effects &~= EF_NODRAW;
        sentry.aiment.color = '0.3 0.3 0.3' + 0.7 * TeamColor(if(teams_matter) sentry.team else COLOR_TEAM3);
    } else {
        sentry.skin = 1;
        sentry.aiment.effects |= EF_NODRAW;
    }

    if(sentry.realowner.classname == "player")
        sentry.realowner.hg_detonables -= 1;

    sentry.realowner = newowner;
    sentry.aiment.realowner = newowner;

    if(newowner) {
        newowner.hg_detonables += 1;
        centerprint_spec(newowner, strcat("^3You have claimed a ^1", HG_TypeToExpandedName(HG_SENTRY), "^3!"));
    }
}

void HG_Sentry_Remove(void) {
    dropentities(self);
    HG_Sentry_Interrupt_Capture();

    if(self.realowner.classname == "player")
        self.realowner.hg_detonables -= 1;

    if(self.hg_waypoint)
        WaypointSprite_Disown(self.hg_waypoint, 0.5);

    if(self.aiment) {
        stopsound(self.aiment, CHAN_PROJECTILE);
        remove(self.aiment);
    }

    for(var e; (e = find(e, classname, "hg_sentry_emitter"));)
        if(e.owner == self)
            HG_Sentry_Emitter_Remove(e);

    remove(self);
}

void HG_Sentry_Explode(void) {
    te_blast(self.origin + self.view_ofs);
    HG_Sentry_Remove();
}

void HG_Sentry_Orphaned_Think(void) {
    var range = CVAR(g_nadgets_sentry_capture_range);
    var dmgdelay = CVAR(g_nadgets_sentry_capture_damage_delay);
    var caprate = CVAR(g_nadgets_sentry_capture_speed);
    var e;

    if(self.hg_sentry_capture_player) {
        e = self.hg_sentry_capture_player;

        if(PlayerIsDead(e) || time - e.lastdamage < dmgdelay || vlen(e.origin - self.origin) > range)
            HG_Sentry_Interrupt_Capture();
        else {
            traceline(self.origin, e.origin, MOVE_NOMONSTERS, self);
            if(trace_fraction < 1)
                HG_Sentry_Interrupt_Capture();
        }
    }

    if(!self.hg_sentry_capture_player) FOR_EACH_PLAYER(e) {
        if(PlayerIsDead(e))
            continue;

        if(time - e.lastdamage < dmgdelay || vlen(e.origin - self.origin) > range)
            continue;

        traceline(self.origin, e.origin, MOVE_NOMONSTERS, self);
        if(trace_fraction < 1)
            continue;

        self.hg_sentry_capture_player = e;
        break;
    }

    if(self.hg_sentry_capture_player) {
        e = self.hg_sentry_capture_player;

        self.hg_sentry_capture_progress = approach(self.hg_sentry_capture_progress, 1.0, caprate * frametime);
        e.hg_sentry_capture_progress = self.hg_sentry_capture_progress;

        if(self.hg_sentry_capture_progress == 1) {
            HG_Sentry_SetOwner(self, e);
            defer(0, HG_Sentry_Interrupt_Capture);
        }
        self.hg_sentry_capture_player.buff_stealth_time = time;
    }
}

void HG_Sentry_Think(void) {
    var o = self.realowner;

    if(o && ((teams_matter && self.team != o.team) || !o.iscreature))
        o = world;

    if(!o || PlayerIsDead(o)) {
        if(CVAR(g_nadgets_sentry_disown_on_death) && roundstate == ROUNDSTATE_GAME) {
            HG_Sentry_SetOwner(self, world);
        } else if(!o) {
            HG_Sentry_Explode();
            return;
        }
    }

    if(self.health < CVAR(g_nadgets_sentry_health))
        self.health = approach(self.health, 0, frametime * CVAR(g_nadgets_sentry_health_degenerate_when_damaged));

    if(!self.health) {
        HG_Sentry_Explode();
        return;
    }

    if(self.health < CVAR(g_nadgets_sentry_health)) {
        self.effects |= EF_FLAME;
    } else {
        self.effects &~= EF_FLAME;
    }

    self.hg_sentry_energy = approach(self.hg_sentry_energy, 1, frametime * CVAR(g_nadgets_sentry_energy_regen));

    if(self.realowner)
        HG_Waypoint();
    else
        HG_Sentry_Orphaned_Think();

    setorigin(self.aiment, self.origin + self.view_ofs);
    self.aiment.scale = bound(0.01, self.hg_sentry_energy, 1);
    self.aiment.light_lev = 100 + self.aiment.scale * 200;

    o = self;
    self = self.aiment;
    HealParticleEmitter(o.realowner);
    self = o;

    self.nextthink = time;

	if (CVAR(g_nadgets_sentry_levitation)) {
		vector new_origin = self.spawnorigin + '0 0 8' * sin(time);
		tracebox(new_origin, self.mins, self.maxs, new_origin, MOVE_NORMAL, self);
		if not(trace_startsolid)
			setorigin(self, new_origin);
	}
}

void HG_Sentry_Damage(entity inflictor, entity attacker, float damage, float deathtype, vector hitloc, vector force) {
    if(!self.realowner || IsDifferentTeam(attacker, self.realowner)) {
        if(DEATH_ISHG(deathtype))
            damage *= CVAR(g_nadgets_sentry_damagefactor_nadgets);
        else
            damage *= CVAR(g_nadgets_sentry_damagefactor);

        self.health = bound(0, self.health - damage, self.health);
    } else {
        if(DEATH_ISHG(deathtype))
            damage *= CVAR(g_nadgets_sentry_repairfactor_nadgets);
        else
            damage *= CVAR(g_nadgets_sentry_repairfactor);

        Heal(self, inflictor, attacker, damage, 0, CVAR(g_nadgets_sentry_health), 0, deathtype, 0, 0, hitloc, '0 0 0');
    }

    if(self.health <= 0)
        HG_Sentry_Explode();
}

void HG_Sentry_MEODP_Death(entity attacker, entity inflictor) {
    HG_Sentry_Explode();
}

void HG_Sentry_Trigger(void) {
    entity e, aimtarg, aimtransform;
    vector o, aimloc, aimloc_untransformed;

    makevectors(self.v_angle);
    W_SetupShot(self, FALSE, 0, "", -1);
    o = w_shotorg;

    tracebox_antilag(self, o, '0 0 0', '0 0 0', o + w_shotdir * MAX_SHOT_DISTANCE, MOVE_NORMAL, self, TRUE);

    while(trace_ent && trace_ent.classname == "hg_sentry" && !IsDifferentTeam(trace_ent, self))
        tracebox_antilag(self, trace_endpos + w_shotdir, '0 0 0', '0 0 0', trace_endpos + w_shotdir * MAX_SHOT_DISTANCE, MOVE_NORMAL, self, TRUE);

    aimtransform = WarpZone_trace_transform;
    aimloc = trace_endpos;
    aimloc_untransformed = WarpZone_UnTransformOrigin(aimtransform, aimloc);
    aimtarg = trace_ent;

    float c_dmg = CVAR(g_nadgets_sentry_shock_damage);
    float c_frc = CVAR(g_nadgets_sentry_shock_force);
    float c_cost;

    if(Buffs_Present(self, BUFF_ADEPT))
        c_cost = CVAR(g_nadgets_sentry_adept_shock_energy_cost);
    else
        c_cost = CVAR(g_nadgets_sentry_shock_energy_cost);

    float found, triggered;

    for(e = world; (e = find(e, classname, "hg_sentry"));) if(e.realowner == self) {
        ++found;

        if(e.hg_sentry_energy < c_cost)
            continue;

        o = e.origin + e.view_ofs;

        #define IS_GOOD_HIT (vlen(trace_endpos - aimloc) < 1 || (aimtarg && aimtarg.takedamage && trace_ent == aimtarg))

        // Aiming directly, sentry can hit directly -OR- aiming through a warpzone, sentry can hit through the same warpzone
        tracebox_antilag(self, o, '0 0 0', '0 0 0', aimloc_untransformed, MOVE_NORMAL, self, TRUE);

        if(!IS_GOOD_HIT) {
            // Aiming through a warpzone, sentry can hit directly
            tracebox_antilag(self, o, '0 0 0', '0 0 0', aimloc, MOVE_NORMAL, self, TRUE);
        }

        entity wz = warpzone_chain_begin;
        while(!IS_GOOD_HIT && wz) {
            // Sentry can hit neither directly nor through the warpzone we aimed through (if any).
            // Let's see if we can hit through another warpzone.
            tracebox_antilag(self, o, '0 0 0', '0 0 0', WarpZone_UnTransformOrigin(wz, aimloc), MOVE_NORMAL, self, TRUE);
            wz = wz.warpzone_chain;
        }

        if(IS_GOOD_HIT) {
            vector end_visual = WarpZone_UnTransformOrigin(WarpZone_trace_transform, trace_endpos);
            vector dir = normalize(end_visual - o);

            tracebox_antilag(self, o, '0 0 0', '0 0 0', o + dir * MAX_SHOT_DISTANCE, MOVE_NORMAL, self, TRUE);

            entity targ = trace_ent;
            vector endpos = trace_endpos;
            float noimpact = (trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT);
            vector force = c_frc * dir;

            Damage(targ, self, self, c_dmg, HG_SENTRY | HITTYPE_SECONDARY, endpos, force);
            sound(e, CHAN_WEAPON, strcat("misc/arc", ftos(1 + (random() > 0.5)), ".wav"), VOL_BASE, ATTN_NORM);
            W_Zapper_Attack2_Effect(if(teams_matter) self.team else COLOR_TEAM3, o, o, end_visual);

            if(targ.takedamage && Buffs_Present(self, BUFF_ADEPT)) {
                var arc = CVAR(g_nadgets_sentry_adept_shock_arc);

                if(arc) {
                    ArcDamage(targ, self, c_dmg, HG_SENTRY | HITTYPE_SECONDARY | HITTYPE_BOUNCE,
                        CVAR(g_nadgets_sentry_adept_shock_arc_range), arc,
                        CVAR(g_nadgets_sentry_adept_shock_arc_force), COLOR_TEAM3, sentry_arc_hit
                    );
                }
            }

            if(targ.solid == SOLID_BSP && !noimpact)
                Damage_DamageInfo(endpos, c_dmg, 0, 0, force, WEP_ZAPPER | HITTYPE_SECONDARY, self);

            e.hg_sentry_energy = bound(0, e.hg_sentry_energy - c_cost, 1);
            ++triggered;
        }

        #undef IS_GOOD_HIT
    }

    if(triggered)
        sound(self, CHAN_WEAPON2, "weapons/rocket_mode.wav", VOL_BASE, ATTN_NORM);
    else if(found)
        sound(self, CHAN_WEAPON2, "weapons/unavailable.wav", VOL_BASE, ATTN_NORM);
}

HG_HOOKFUNCTION(sentry, Attack) {
    vector o = self.origin;

    entity e = spawn();
    setmodel(e, "models/rtzsentry.iqm");
    setsize(e, HG_SENTRY_MINS, HG_SENTRY_MAXS);
    setorigin(e, o);

    if(!move_out_of_solid(e, MOVE_NOMONSTERS)) {
        remove(e);
        bigprint_spec(self, "Can't put a sentry here!", "", 1);
        return HG_ATTACK_FAIL_COOLDOWN;
    }

	e.spawnorigin = e.origin;
    e.classname = "hg_sentry";
    e.team = self.team;
    e.realowner = self; // can't use owner here because we want to be blocked by it
    e.solid = SOLID_BBOX;
    e.movetype = if (CVAR(g_nadgets_sentry_levitation)) MOVETYPE_NONE else MOVETYPE_TOSS;
    e.angles = '0 360 0' * random();
    e.reset = HG_Sentry_Remove;
    e.think = HG_Sentry_Think;
    e.nextthink = time;
    e.hg_type = HG_SENTRY;
    e.view_ofs = '0 0 100';
    e.takedamage = DAMAGE_AIM;
    e.colormap = num_for_edict(e.realowner);
    e.health = CVAR(g_nadgets_sentry_health);
    e.event_damage = HG_Sentry_Damage;
    e.cnt = time + CVAR(g_nadgets_sentry_beam_initialdelay);

    self.hg_detonables += 1;

    Buffs_MEODP_Point_Attach(e, HG_Sentry_MEODP_Death);

    entity c = spawn();
    setmodel(c, "models/ebomb.mdl");
    c.skin = 3;
    c.colormap = e.colormap;
    c.pflags = PFLAGS_FULLDYNAMIC;
    c.color = '0.3 0.3 0.3' + 0.7 * TeamColor(if(self.team > 0) self.team else COLOR_TEAM3);
    c.owner = self;
    c.effects |= EF_DOUBLESIDED;
    sound(c, CHAN_PROJECTILE, "weapons/electro_fly.wav", 0.5, 2);

    e.aiment = c;

    var tail = e;
    for(var i = 0; i < CVAR(g_nadgets_sentry_beam_amount); ++i) {
        tail.hg_sentry_emitter_next = HG_Sentry_Emitter_Spawn(e);
        tail = tail.hg_sentry_emitter_next;
    }

    // TODO: a better sound?
    spamsound(self, CHAN_PROJECTILE, "weapons/grenade_stick.wav", 1, ATTN_NORM);
    return HG_ATTACK_OK;
}

HG_HOOKFUNCTION(sentry, Init) {
    addstat(STAT_HGSENTRYCAPTURE, AS_FLOAT, hg_sentry_capture_progress);
    return HG_INIT_OK;
}
