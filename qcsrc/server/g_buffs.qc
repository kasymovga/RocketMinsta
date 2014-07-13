
#define ON_BUFF_ADDED(b) if(self.buffs & (b)) if not(self.oldbuffs & (b))
#define ON_BUFF_REMOVED(b) if(self.oldbuffs & (b)) if not(self.buffs & (b))

void Buffs_Init(void) {
    float i, b;
    
    g_buffs = cvar("g_buffs");
    
    if(g_clanarena)
        g_buffs = (g_buffs && cvar("g_clanarena_buffs"));
    
    if(!g_buffs)
        return;
    
    g_buffs_team_only = cvar("g_buffs_team_only");
    g_buffs_stack = cvar("g_buffs_stack");
    g_buffs_noteam = cvar("g_buffs_noteam");
    g_buffs_randomize = cvar("g_buffs_randomize");
    g_buffs_randomize_dual = cvar("g_buffs_randomize_dual");
    g_buffs_randomize_byinstance = cvar("g_buffs_randomize_byinstance");
    g_buffs_randomize_chaos = cvar("g_buffs_randomize_chaos");
    g_buffs_randomize_interval = cvar("g_buffs_randomize_interval");
    g_buffs_spawn_on_powerups = cvar("g_buffs_spawn_on_powerups");
    g_buffs_lockon = cvar("g_buffs_lockon");
    
    if(g_clanarena)
        g_buffs_team_only = cvar("g_clanarena_buffs_team_only");
    
    precache_sound("misc/strength_respawn.wav");
    precache_sound("misc/shield_respawn.wav");
    precache_sound("misc/arc1.wav");
    precache_sound("misc/arc2.wav");
    precache_model("models/buffs/buff_ring.md3");
    
    addstat(STAT_BUFFS, AS_INT, buffstat);
    

    float enabled;
    for(i = 0, b = 1; i < BUFF_COUNT; ++i, b *= 2) {
        g_buffs_enabled[i] = cvar(strcat("g_buffs_", Buffs_TypeToName(b)));
        
        if(b == BUFF_MEDIC && !teams_matter)
            g_buffs_enabled[i] = FALSE;
            
        if(b == BUFF_WRATH && !g_nadgets)
            g_buffs_enabled[i] = FALSE;
            
        if(b == BUFF_ADEPT && !g_nadgets)
            g_buffs_enabled[i] = FALSE;
        
        if(g_buffs_enabled[i]) {
            string s = strcat("models/buffs/buff_", Buffs_TypeToName(b), ".md3");
            if(!fexists(s)) {
                s = "models/buffs/buff.md3";
                print("No model found for the ", Buffs_TypeToName(b), " Buff! Falling back to default.\n");
            }
            
            g_buffs_model[i] = strzone(s);
            precache_model(g_buffs_model[i]);
            ++enabled;
        }
    }
    
    if(enabled < 2)
        g_buffs_randomize_dual = 0;
    
    InitializeEntity(world, Buffs_Init_Delayed, INITPRIO_LAST);
}

void Buffs_Randomize_Reset(void) {
    float i;
    
    for(i = 0; i < BUFF_COUNT; ++i) {
        g_buffs_replacements[i] = 0;
        g_buffs_used[i] = 0;
        g_buffs_used_dual[i] = 0;
        g_buffs_randomize_ulevel = 0;
        g_buffs_randomize_ulevel_dual = 0;
    }
}

float Buffs_Randomize_Yield(void) {
    float found, sub, choosen, j;
    RandomSelection_Init();
    
    while(!found) {
        for(j = 0; j < BUFF_COUNT; ++j)
            if(g_buffs_enabled[j] && (g_buffs_used[j] < g_buffs_randomize_ulevel || g_buffs_randomize_chaos)) {
                RandomSelection_Add(world, j, string_null, cvar(strcat("g_buffs_", Buffs_TypeToName(pow(2, j)), "_randomspawn_weight")), 1);
                ++found;
            }
        
        if(!found)
            ++g_buffs_randomize_ulevel;
    }
    
    choosen = RandomSelection_chosen_float;
    g_buffs_used[choosen] = g_buffs_randomize_ulevel;
    sub = pow(2, choosen);
    
    if(g_buffs_randomize_dual >= 1 || random() < g_buffs_randomize_dual) {
        RandomSelection_Init();
        found = 0;
        
        while(!found) {
            for(j = 0; j < BUFF_COUNT; ++j)
                if(g_buffs_enabled[j] && j != choosen && (g_buffs_used_dual[j] < g_buffs_randomize_ulevel_dual || g_buffs_randomize_chaos)) {
                    RandomSelection_Add(world, j, string_null, cvar(strcat("g_buffs_", Buffs_TypeToName(pow(2, j)), "_randomspawn_weight")), 1);
                    ++found;
                }
            
            if(!found)
                ++g_buffs_randomize_ulevel_dual;
        }
        
        g_buffs_used_dual[RandomSelection_chosen_float] = g_buffs_randomize_ulevel_dual;
        sub = sub | pow(2, RandomSelection_chosen_float);
    }
    
    return sub;
}

void Buffs_Randomize(entity blist, float force) {
    float i, j;
    entity b;
    
    if(g_buffs_randomize >= 2)
        force = TRUE;
    
    Buffs_Randomize_Reset();
    
    if(force && g_buffs_randomize_byinstance <= 1) for(i = 0; i < BUFF_COUNT; ++i)
        g_buffs_replacements[i] = Buffs_Randomize_Yield();
    
    if(!blist)
        blist = findchain(classname, "item_buff");
    
    for(b = blist; b; b = b.chain) {
        if(b.origbuffs == BUFF_RANDOM || g_buffs_randomize_byinstance > 1 || (g_buffs_randomize_byinstance && !b.team))
            b.buffs = Buffs_Randomize_Yield();
        else if(force) {
            i = Buffs_TypeToIndex(b.origbuffs);
            j = g_buffs_replacements[i];
            if(j) b.buffs = j;
        }
    }
}

#define BUFFS_RANDOMIZER_NEXTTHINK (time + max3(game_starttime - time, next_round_starttime - time, 0) + g_buffs_randomize_interval)

void Buffs_Randomizer_Think(void) {
    if(roundstate == ROUNDSTATE_GAME)
        Buffs_Randomize(world, TRUE);
    self.nextthink = BUFFS_RANDOMIZER_NEXTTHINK;
}

void Buffs_Randomizer_Reset(void) {
    self.nextthink = BUFFS_RANDOMIZER_NEXTTHINK;
}

float buff_teamfound[4];
void Buffs_Init_Delayed(void) {
    entity blist, b, o;
    float idx, teams_found, teams_total, bcnt = g_buffs_count;
    
    if(g_buffs_spawn_on_powerups && !g_buffs_team_only) {
        o = self;
        for(b = findchain(classname, "buff_placeholder"); b; b = b.chain) {
            if(bcnt) {
                b.nextthink = time;
                b.think = SUB_Remove;
            } else {
                self = b;
                self.buffs = BUFF_RANDOM;
                Buffs_BuffPickup_Setup();
                if(self.owner && !wasfreed(self.owner)) {
                    remove(self.owner);
                    self.owner = world;
                }
            }
        }
        self = o;
    }
    
    if(teams_matter) {
        teams_total = TeamCount_TotalTeams();

        blist = findchain(classname, "item_buff");
        for(b = blist; b; b = b.chain) if(b.team) {
            idx = Team_Index(b.team);
            if(!buff_teamfound[idx]) {
                buff_teamfound[idx] = TRUE;
                ++teams_found;
            }
            
            if(b.team == COLOR_TEAM3 && teams_total < 3 || b.team == COLOR_TEAM4 && teams_total < 4) {
                b.think = Buffs_BuffPickup_Remove;
                b.nextthink = time;
            }
        }
        
        if(teams_total > teams_found)
        for(b = blist; b; b = b.chain) if(b.team) {
            b.think = Buffs_BuffPickup_Remove;
            b.nextthink = time;
        }
    }
    
    Buffs_Randomize(blist, g_buffs_randomize);
    
    if(g_buffs_randomize)
    if(g_buffs_randomize_interval)
    if(cvar("g_buffs_randomize_interval_force") || !EndRound_Allowed()) {
        entity e = spawn();
        e.classname = "buff_randomizer";
        e.reset = Buffs_Randomize_Reset;
        e.think = Buffs_Randomizer_Think;
        e.nextthink = BUFFS_RANDOMIZER_NEXTTHINK;
    }
}

float Buffs_BuffPower(entity p, float b) {
    if(p.nobuffs)
        return 0;
    
    if(p.buffs & b)
        return 1;
    
    if(p.hg_linker.buffs & b)
        return p.hg_linker.hg_linker_buffpower;
    
    return 0;
}

string Buffs_GenName(float b) {
    string r;
    float o, first = TRUE;
    
    r = Buffs_TypeToExpandedName(b);
    
    if(r != "Unknown")
        return r;
    
    for(o = BUFF_FIRST; o <= BUFF_LAST; o *= 2)
        if(b & o) {
            if(first) {
                r = Buffs_TypeToExpandedName(o);
                first = FALSE;
            } else {
                r = strcat(r, " + ", Buffs_TypeToExpandedName(o));
            }
        }
    
    return r;
}

vector Buffs_GenColor(float b) {
    vector c;
    float o, n;
    
    c = Buffs_TypeToColor(b);
    
    if(c != '0 0 0')
        return c;
    
    for(o = BUFF_FIRST; o <= BUFF_LAST; o *= 2)
        if(b & o) {
            c += Buffs_TypeToColor(o);
            ++n;
        }
    
    // actually, this looks like shit
    return c * (1/n);
}

float Buffs_BuffModel_Customize(void) {
    entity oself = self;
    if(!self.owner.iscreature)  // called for a multibuff model - check against the parent model
        self = self.owner;
    
    float sameteam = (teams_matter && (other.team == self.owner.team || (other.classname == "spectator" && other.enemy.team == self.owner.team)));
    if(self.owner.hg_stealth && !sameteam)
        return FALSE;
    
    if(other == self.owner || (other.classname == "spectator" && other.enemy == self.owner)) {
        oself.alpha = -1;
    } else {
        oself.alpha = 1;
    }
    
    return TRUE;
}

float Buffs_TeamWaypoint_VisibleForPlayer(entity plr) {
    if(plr == self.owner)
        return FALSE;
    return WaypointSprite_visible_for_player(plr);
}

void Buffs_SetTeamWaypoint(entity plr, string txt, vector clr, float btype) {
    entity wp = plr.buff_teamwp;
    
    if(!wp) {
        wp = WaypointSprite_Spawn(txt, 0, 0, plr, '0 0 120', world, plr.team, plr, buff_teamwp, TRUE);
        wp.buff_waypoint.waypointsprite_visible_for_player = Buffs_TeamWaypoint_VisibleForPlayer;
    } else
        WaypointSprite_UpdateSprites(wp, txt, "", "");
    
    WaypointSprite_UpdateTeamRadar(wp, RADARICON_GENERATOR, clr);
    WaypointSprite_UpdateTextColors(wp, clr, '0 0 0', '0 0 0');
    wp.buffs = btype;
}

void Buffs_RemoveTeamWaypoint(entity plr) {
    WaypointSprite_Disown(plr.buff_teamwp, 0.5);
}

.entity buffmdl[BUFF_COUNT];

void Buffs_SetBuffModel_MultiBuffModel_Think(void) {
    if(!self.owner || wasfreed(self.owner) || self.owner.buffs != self.buffstat) {
        remove(self);
        return;
    }
    
    self.effects = self.owner.effects;
    self.effects &~= EF_NODRAW;
    self.light_lev = self.owner.light_lev * 0.7;
    self.pflags = self.owner.pflags;
    self.color = self.colormod = Buffs_GenColor(self.buffs);
    self.alpha = self.owner.alpha;
    
    vector ang;
    ang_y = mod(time * 120 + self.cnt, 360);
    makevectors(ang);
    setorigin(self, self.owner.origin + v_forward * 10 + v_up * 3 * sin(time * 0.32 + self.cnt));
    self.angles_y = ang_y + 90;
    
    self.nextthink = time;
    return;
}

void Buffs_SetBuffModel_SetupMultiBuffModel(entity bmdl, entity parent, float offs) {
    bmdl.owner = parent;
    float bi = Buffs_TypeToIndex(bmdl.buffs);
    Buffs_SetBuffModel(bmdl, bmdl.buffs);
    bmdl.owner = parent;
    bmdl.customizeentityforclient = parent.customizeentityforclient;
    bmdl.pflags = PFLAGS_FULLDYNAMIC;
    bmdl.scale = (parent.scale? parent.scale : 1); // * 0.90;
    bmdl.cnt = offs;
    bmdl.think = Buffs_SetBuffModel_MultiBuffModel_Think;
    bmdl.buffstat = parent.buffs;
    bmdl.nextthink = time;
}

void Buffs_SetBuffModel(entity ment, float thebuffs) {
    float idx = Buffs_TypeToIndex(thebuffs);
    float i, j, b;
    
    if(idx >= 0) {
        // single model - use ment to display it
        
        for(i = 0; i < BUFF_COUNT; ++i) {
            if(ment.(buffmdl[i])) {
                remove(ment.(buffmdl[i]));
                ment.(buffmdl[i]) = world;
            }
        }
        
        ment.effects &~= EF_NODRAW;
        
        vector omins = ment.mins;
        vector omaxs = ment.maxs;
        
        setmodel(ment, g_buffs_model[Buffs_TypeToIndex(thebuffs)]);
        setsize(ment, omins, omaxs);
    } else {
        // multiple buffs - hide ment and use additional models
        
        ment.effects |= EF_NODRAW;
        
        for(i = 0, b = 1; b <= BUFF_LAST; b *= 2) if(thebuffs & b) {
            if(!ment.(buffmdl[i]) || wasfreed(ment.(buffmdl[i])))
                ment.(buffmdl[i]) = spawn();
            ment.(buffmdl[i]).buffs = b;
            ++i;
        }
        
        for(j = 0; j < BUFF_COUNT; ++j) {
            if(j >= i) {
                if(ment.(buffmdl[j])) {
                    remove(ment.(buffmdl[j]));
                    ment.(buffmdl[j]) = world;
                }
            } else Buffs_SetBuffModel_SetupMultiBuffModel(ment.(buffmdl[j]), ment, (j/i)*360);
            
        }
    }
}

void Buffs_ClientFrame(void) {
    if(!g_buffs)
        return;
    
    self.buffstat = self.buffs;
    if(self.hg_linker.hg_linker_buffpower)
        self.buffstat = self.buffstat | self.hg_linker.buffs;
    
    if(self.classname != "player") {
        if(self.buff_model) {
            remove(self.buff_model);
            self.buff_model = world;
        }
        
        if(self.buff_teamwp)
            Buffs_RemoveTeamWaypoint(self);
        
        return;
    }
    
    if(self.buffs != self.oldbuffs) {
        ON_BUFF_ADDED(BUFF_SUPPLY) {
            self.campingrifle_bulletcounter = 9001;
            
            if(!g_weaponarena) {
                float a = cvar("g_buffs_supply_grant_ammo");
                self.ammo_cells += a;
                self.ammo_shells += a;
                self.ammo_rockets += a;
                self.ammo_nails += a;
            }
        }
        
        ON_BUFF_ADDED(BUFF_GUARD) {
            if(g_clanarena)
                self.health = max(min(cvar("g_clanarena_heal_limit"), cvar("g_buffs_guard_pickup_health")), self.health);
            else {
                self.health = max(cvar("g_buffs_guard_pickup_health"), self.health);
                self.armorvalue = max(cvar("g_buffs_guard_pickup_armor"), self.armorvalue);
            }
        }
        
        ON_BUFF_REMOVED(BUFF_VAMPIRE) {
            self.buff_vamp_ticks = self.buff_vamp_healthpool = self.buff_vamp_nexttick = 0;
        }
        
        ON_BUFF_ADDED(BUFF_VAMPIRE) {
            self.buff_vamp_ticks = self.buff_vamp_healthpool = self.buff_vamp_nexttick = 0;
        }
        
        ON_BUFF_REMOVED(BUFF_ADEPT) {
            self.hg_stealth_saved = 0;
        }
        
        self.oldbuffs = self.buffs;
    }
    
    if(self.buffstat != self.oldbuffstat) {
        if(self.buff_model && self.buffstat) {
            self.buff_model.color = self.buff_model.colormod = Buffs_GenColor(self.buffstat);
            Buffs_SetBuffModel(self.buff_model, self.buffstat);
        }
        self.oldbuffstat = self.buffstat;
    }
    
    if(self.buffstat) {
        if(!self.buff_model) {
            entity m = spawn();
            float bi = Buffs_TypeToIndex(self.buffstat);
            setsize(m, '0 0 -40', '0 0 40');
            m.customizeentityforclient = Buffs_BuffModel_Customize;
            m.owner = self;
            m.pflags = PFLAGS_FULLDYNAMIC;
            m.color = m.colormod = Buffs_GenColor(self.buffstat);
            m.light_lev = 200;
            m.effects = EF_ADDITIVE | EF_FULLBRIGHT;
            Buffs_SetBuffModel(m, self.buffstat);
            self.buff_model = m;
        }
        
        setorigin(self.buff_model, self.origin + '0 0 70');
        self.buff_model.angles_y = 200 * time;
    } else if(self.buff_model) {
        remove(self.buff_model);
        self.buff_model = world;
    }
    
    if(BUFFS_PRESENT(self, BUFF_VAMPIRE)) {
        if(self.buff_vamp_ticks > 0) if(time > self.buff_vamp_nexttick) {
            float heal = self.buff_vamp_healthpool / self.buff_vamp_ticks;
            Heal(self, world, self, heal, cvar("g_buffs_vampire_pauserot"), '0 0 0');
            self.buff_vamp_healthpool -= heal;
            self.buff_vamp_ticks -= 1;
            self.buff_vamp_nexttick = time + 1;
        }
    }

    if(BUFFS_PRESENT(self, BUFF_ANGEL)) {
      if(time > self.buff_angel_nexttick) {
	  self.buff_angel_nexttick = time + 2;

	  float heal = cvar("g_buffs_angel_heal");
	 

	  entity p;

	  FOR_EACH_PLAYER(p) {
	    if(p.team != self.team) {
	      continue;
	    }
	    if(vlen(self.origin - p.origin) <= cvar("g_buffs_angel_range"))
	      AngelHeal(p, self);
	    }
	  }
    }
    
    if(!self.buff_teamwp) {
        if(BUFFS_PRESENT(self, BUFF_MEDIC))
            Buffs_SetTeamWaypoint(self, "HEALER", Buffs_TypeToColor(BUFF_MEDIC), BUFF_MEDIC);
    } else if(!BUFFS_PRESENT(self, self.buff_teamwp.buffs))
        Buffs_RemoveTeamWaypoint(self);
}

#undef ON_BUFF_ADDED
#undef ON_BUFF_REMOVED

float Buffs_NadgetPower(entity plr) {
    float bp = Buffs_BuffPower(plr, BUFF_WRATH);
    
    if(!bp)
        return 1;
    
    return bp * cvar("g_buffs_wrath_hgpower");
}

float Buffs_NadgetRegen(entity plr) {
    return (1 + (cvar("g_buffs_supply_hg_regenscale") - 1) * Buffs_BuffPower(self, BUFF_SUPPLY)) *
           (1 + (cvar("g_buffs_wrath_hgregen")        - 1) * Buffs_BuffPower(self, BUFF_WRATH));
}

float Buffs_NadgetCooldown(entity plr) {
    float bp = Buffs_BuffPower(plr, BUFF_WRATH);
    
    if(!bp)
        return 1;
    
    return bp * cvar("g_buffs_wrath_hgcooldown");
}

float Buffs_NadgetRegenDmgPause(entity plr) {
    return (1 - (1 - cvar("g_buffs_wrath_hgregen_damagepause")) * Buffs_BuffPower(plr, BUFF_WRATH));
}

float Buffs_TenacityDamage(entity targ, entity attacker, float damage, float deathtype) {
    if(!BUFFS_PRESENT(targ, BUFF_TENACITY))
        return damage;
    
    if(DEATH_ISSPECIAL(deathtype) && deathtype != DEATH_ARC && deathtype != DEATH_BASH)
        return damage;
    
    if(targ == attacker)
        return damage * (1 - (1 - cvar("g_buffs_tenacity_takedamage_self")) * Buffs_BuffPower(targ, BUFF_TENACITY));
    
    if(DEATH_ISHG(deathtype) || (deathtype & HITTYPE_SPLASH) || deathtype == DEATH_ARC || deathtype == DEATH_BASH)
        return damage * (1 - (1 - cvar("g_buffs_tenacity_takedamage_aoe")) * Buffs_BuffPower(targ, BUFF_TENACITY));
    
    return damage * (1 - (1 - cvar("g_buffs_tenacity_takedamage")) * Buffs_BuffPower(targ, BUFF_TENACITY));
}

void Buffs_VampireDamage(entity targ, entity a, float damage, float deathtype) {
    if(damage <= 0)
        return;
    
    // paranoid sanity check, should not happen
    if(!a.buff_vamp_ticks  &&  a.buff_vamp_healthpool ||
        a.buff_vamp_ticks  && !a.buff_vamp_healthpool)
        a.buff_vamp_ticks  =   a.buff_vamp_healthpool = 0;
    
    float ticks = cvar("g_buffs_vampire_time");
    float factor = cvar("g_buffs_vampire_factor") * Buffs_BuffPower(a, BUFF_VAMPIRE);
    
    if(ticks > 0) {
        // refresh duration, extend the pool
        a.buff_vamp_ticks = ticks;
        a.buff_vamp_healthpool += damage * factor;
    } else {
        // instant-healing mode, don't use the buffer, just heal
        Heal(a, world, a, damage * factor, cvar("g_buffs_vampire_pauserot"), '0 0 0');
    }
}

void Buffs_ArcEffect(vector from, vector to, float t) {
    te_csqc_lightningarc(from, to, t, t);
}

void Buffs_ArcDamage(entity targ, entity attacker, float damage, float deathtype) {
    entity oldself = self;
    entity plr, newtarget;
    float dist, shortest;
    
    vector arcoffset = attacker.maxs_z * '0 0 0.5';
    
    float targetTeamMates = (teams_matter && BUFFS_PRESENT(attacker, BUFF_MEDIC) && targ.team == attacker.team);
    float targetFrozen = targ.frozen && !targetTeamMates;
    float targetAlive = !targetFrozen && !targetTeamMates;
    
    if(targ.team == attacker.team && !targetTeamMates)
        return;
    
    if(targetFrozen)
        damage = 1;
    else {
        if(DEATH_ISHG(deathtype))
            damage = damage * cvar("g_buffs_arc_multiplier_hg");
        damage = damage * cvar("g_buffs_arc_multiplier") * Buffs_BuffPower(attacker, BUFF_ARC);
    }
    
    if(damage < 1)
        return;
    
    newtarget = world;
    shortest = cvar("g_buffs_arc_range");
    targ.buffs_arc_hit = TRUE;
    
    FOR_EACH_PLAYER(plr)
    if(plr != attacker)
    if(plr != targ)
    if(plr.deadflag == DEAD_NO)
    if(!plr.hg_stealth || (targetTeamMates && plr.team == attacker.team))
    if(!plr.jb_isprisoned)
    if(!plr.buffs_arc_hit) {
        float sameteam = (teams_matter && plr.team == attacker.team);
        if((!sameteam && ((!plr.frozen && targetAlive) || (plr.frozen && targetFrozen))) || (sameteam && targetTeamMates)) {
            dist = vlen(plr.origin - targ.origin);
            if(dist < shortest) {
                traceline(targ.origin + arcoffset, plr.origin + arcoffset, MOVE_NORMAL, targ);
                
                if(trace_fraction != 1 && trace_ent == plr) {
                    shortest = dist;
                    newtarget = plr;
                }
            }
        }
    }
    
    if(newtarget) {
        Buffs_ArcEffect(targ.origin + arcoffset, newtarget.origin + arcoffset, (targetTeamMates? 0 : (teams_matter? attacker.team : COLOR_TEAM2)));
        Damage(newtarget, attacker, attacker, damage, DEATH_ARC, '0 0 0', normalize(newtarget.origin - targ.origin) * cvar("g_buffs_arc_pushback"));
        Buffs_ArcDamage(newtarget, attacker, damage, DEATH_ARC);
        if(targetTeamMates)
            sound(newtarget, CHAN_PROJECTILE, "kh/capture.wav", 0.4, ATTN_NORM);
        else
            sound(newtarget, CHAN_PROJECTILE, strcat("misc/arc", ftos(1 + (random() > 0.5)), ".wav"), VOL_BASE, ATTN_NORM * 0.3);
            
    }
    
    self = oldself;
}

void Buffs_ArcDamage_Finalize(void) {
    entity e; for(e = world; (e = findfloat(e, buffs_arc_hit, TRUE));)
        e.buffs_arc_hit = FALSE;
}

.float lastbash;

void Buffs_BashDamage_Proc(entity attacker, entity inflictor, entity ignore, float damage) {
    if(time - attacker.lastbash < cvar("g_buffs_bash_cooldown") * W_WeaponRateFactor())
        return;
    
    float p = Buffs_BuffPower(attacker, BUFF_BASH);
    RadiusDamage(inflictor, attacker, damage * cvar("g_buffs_bash_coremultiplier") * p, damage * cvar("g_buffs_bash_edgemultiplier") * p, cvar("g_buffs_bash_radius"), world, damage * cvar("g_buffs_bash_damageforcescale"), DEATH_BASH, ignore);
    te_blast(RadiusDamage_blastorigin);
    attacker.lastbash = time;
}

void Buffs_BashDamage_Think(void) {
    entity o = self;
    self = self.chain;
    Buffs_BashDamage_Proc(o.owner, o, o.aiment, o.cnt);
    self = o;
    remove(self);
}

void Buffs_BashDamage(entity attacker, entity inflictor, entity ignore, float damage, vector loc) {
    entity e = spawn();
    e.aiment = ignore;
    e.enemy = inflictor;
    e.owner = attacker;
    e.cnt = damage;
    e.think = Buffs_BashDamage_Think;
    e.chain = self;
    e.nextthink = time;
    
    if(loc != '0 0 0')
        setorigin(e, loc);
    else
        setorigin(e, inflictor.origin);
}

float Buffs_BuffPickup_Waypoint_VisibleForPlayer(entity plr) {
    if((!self.owner.buff_active && !self.owner.buff_activetime) || plr.buffs & self.owner.buffs || (plr.buffs && !g_buffs_stack))
        return FALSE;
    return WaypointSprite_visible_for_player(plr);
}

void Buffs_BuffPickup_SpawnWaypoint(entity e) {
    WaypointSprite_Spawn(Buffs_GenName(e.buffs), 0, 0, world, e.origin + '0 0 40', world, e.team, e, buff_waypoint, TRUE);
    WaypointSprite_UpdateTextColors(e.buff_waypoint, e.colormod, '0 0 0', '0 0 0');
    WaypointSprite_UpdateTeamRadar(e.buff_waypoint, RADARICON_FLAG, e.colormod);
    e.buff_waypoint.waypointsprite_visible_for_player = Buffs_BuffPickup_Waypoint_VisibleForPlayer;
}

void Buffs_BuffPickup_SetCooldown(float cd) {
    cd = max(0, cd);
    
    if(!self.buff_waypoint)
        Buffs_BuffPickup_SpawnWaypoint(self);
    
    WaypointSprite_UpdateBuildFinished(self.buff_waypoint, time + cd);
    self.buff_activetime = cd;
    self.buff_active = !cd;
}

void Buffs_BuffPickup_Think(void) {
    if(time < 1)
        return;
    
    if(self.buff_lockon)
    if(time > self.buff_lockon_updatetime)
        self.buff_lockon = world;
    
    if(roundstate == ROUNDSTATE_GAME)
    if(!self.buff_activetime_updated) {
        Buffs_BuffPickup_SetCooldown(self.buff_activetime);
        self.buff_activetime_updated = TRUE;
    }
    
    if(self.buffs != self.oldbuffs) {
        self.color = self.colormod = Buffs_GenColor(self.buffs);
        self.enemy.colormod = (self.team? TeamColor(self.team) + '0.1 0.1 0.1' : self.colormod);
        
        if(self.buff_waypoint) {
            WaypointSprite_Disown(self.buff_waypoint, 1);
            Buffs_BuffPickup_SpawnWaypoint(self);
        }
        
        Buffs_SetBuffModel(self, self.buffs);
        self.oldbuffs = self.buffs;
    }
    
    if(!self.buff_active && !self.buff_activetime)
    if(!self.owner || self.owner.frozen || self.owner.jb_isprisoned || self.owner.deadflag != DEAD_NO || !self.owner.iscreature || !(self.owner.buffs & self.buffs)) {
        if(self.owner.buff_cdoverride) {
            Buffs_BuffPickup_SetCooldown(max(0, self.owner.buff_cdoverride) + frametime);
            self.owner.buff_cdoverride = 0;
        } else
            Buffs_BuffPickup_SetCooldown(cvar("g_buffs_reactivate_delay") + frametime);
        self.owner = world;
    }
    
    if(self.buff_activetime) {
        if(roundstate == ROUNDSTATE_GAME) {
            self.buff_activetime = max(0, self.buff_activetime - frametime);
            
            if(!self.buff_activetime) {
                self.buff_active = TRUE;
                sound(self, CHAN_TRIGGER, "misc/strength_respawn.wav", VOL_BASE, ATTN_NORM); 
            }
        }
    }
    
    if(!self.buff_active) {
        self.alpha = 0.3;
        self.effects &~= EF_FULLBRIGHT | EF_ADDITIVE;
        self.pflags = 0;
    } else {
        self.alpha = 1;
        self.effects |= EF_FULLBRIGHT | EF_ADDITIVE;
        self.light_lev = 220 + 36 * sin(time);
        self.pflags = PFLAGS_FULLDYNAMIC;
        
        if(self.team && !self.buff_waypoint)
            Buffs_BuffPickup_SpawnWaypoint(self);
    }
    
    self.nextthink = time;
    self.angles_y = time * 110.1;
}

void Buffs_BuffPickup_Ring_Think(void) {
    self.nextthink = time;
    self.angles_y = time * 157.1;
    self.alpha = self.owner.alpha;
    self.effects = self.owner.effects;
    
    self.effects &~= EF_STARDUST | EF_NODRAW;
    
    if(self.owner.team)
        self.effects &~= EF_ADDITIVE;
    
    setorigin(self, self.owner.origin + '0 0 15');
}

void Buffs_BuffPickup_ResetWaypoint(void) {
    if(self.buff_waypoint)
        WaypointSprite_Kill(self.buff_waypoint);
    
    if(self.buff_activetime)
        Buffs_BuffPickup_SpawnWaypoint(self);
}

void Buffs_BuffPickup_Reset(void) {
    self.owner = world;
    Buffs_BuffPickup_SetCooldown(cvar("g_buffs_activate_delay"));
    Buffs_BuffPickup_ResetWaypoint();
    self.buff_activetime_updated = FALSE;
}

void Buffs_BuffPickup_GiveTo(entity plr) {
    if(self.owner || BUFFS_PRESENT(plr, self.buffs) || (plr.buffs && !g_buffs_stack))
        return;
    
    self.owner = plr;
    self.buff_active = FALSE;
    
    string bname = strcat(rgb_to_hexcolor(self.colormod), Buffs_GenName(self.buffs), "^7 Buff!");
    string tn = (self.team? strcat(Team_ColorCode(self.team), strtoupper(Team_ColorName(self.team)), " ") : "");
    
    bprint("^3", plr.netname, " ^7got the ", tn, bname, "\n");
    bigprint_spec(plr, strcat("You got the ", bname), "", 3);
    sound(other, CHAN_TRIGGER, "misc/shield_respawn.wav", VOL_BASE, ATTN_NORM); 
    BUFFS_GIVE(plr, self.buffs);
}

void Buffs_BuffPickup_Touch(void) {
    if(self.team && other.team != self.team)
        return;
    
    if(other.deadflag != DEAD_NO)
        return;
    
    if(other.frozen)
        return;
    
    if(other.jb_isprisoned)
        return;
    
    if(other.classname != "player")
        return;
    
    if(!self.buff_active) {
        if(g_buffs_lockon && (!self.buff_lockon || self.buff_lockon == other)) {
            self.buff_lockon = other;
            self.buff_lockon_updatetime = time + 0.5;
        }
        return;
    }
    
    if(self.buff_lockon && self.buff_lockon != other)
        return;
    
    Buffs_BuffPickup_GiveTo(other);
    self.buff_lockon = world;
}

void Buffs_BuffPickup_TeamSwap(void) {
    self.team = TeamCount_NextTeam(self.team);
    if(self.buff_waypoint)
        self.buff_waypoint.team = self.team;
    self.enemy.colormod = (self.team? TeamColor(self.team) + '0.1 0.1 0.1' : self.colormod);
}

void Buffs_BuffPickup_Setup(void) {
    if(!g_buffs || (self.team && !teams_matter) || (g_buffs_team_only && !self.team)) {
        remove(self);
        return;
    }
    
    if not(g_buffs_randomize)
    if not(g_buffs_enabled[Buffs_TypeToIndex(self.buffs)]) {
        remove(self);
        return;
    }
    
    if(g_buffs_noteam)
        self.team = 0;
        
    if(cvar("g_buffs_team_swap"))
        self.team = TeamCount_NextTeam(self.team);
    
    self.origbuffs = self.buffs;
    self.classname = "item_buff";
    self.flags = FL_ITEM;
    self.solid = SOLID_TRIGGER;
    self.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY;
    self.movetype = MOVETYPE_TOSS;
    self.effects = EF_ADDITIVE | EF_FULLBRIGHT | EF_STARDUST | EF_NOSHADOW;
    self.think = Buffs_BuffPickup_Think;
    self.touch = Buffs_BuffPickup_Touch;
    self.reset = Buffs_BuffPickup_Reset;
    self.teamswap = Buffs_BuffPickup_TeamSwap;
    self.nextthink = time;
    self.scale = 1.5;
    Buffs_BuffPickup_SetCooldown(cvar("g_buffs_activate_delay"));
    self.buff_active = !self.buff_activetime;
    self.color = self.colormod = Buffs_GenColor(self.buffs);
    self.pflags = PFLAGS_FULLDYNAMIC;
    self.gravity = 100;
    
    setsize(self, '-15 -15 -40', '15 15 40');
    Buffs_SetBuffModel(self, self.buffs);
    
    self.enemy = spawn();
    self.enemy.owner = self;
    self.enemy.think = Buffs_BuffPickup_Ring_Think;
    self.enemy.nextthink = time;
    self.enemy.effects = self.effects;
    self.enemy.alpha = self.alpha;
    self.enemy.scale = self.scale * 1.2;
    self.enemy.team = self.team;
    self.enemy.gravity = self.gravity;
    self.enemy.colormod = (self.team? TeamColor(self.team) + '0.1 0.1 0.1' : self.colormod);
    
    move_out_of_solid(self);
    droptofloor();
    
    setsize(self.enemy, self.mins, self.maxs);
    setorigin(self.enemy, self.origin + self.maxs * 0.5 * self.scale);
    setmodel(self.enemy, "models/buffs/buff_ring.md3");
    
    ++g_buffs_count;
}

void Buffs_BuffPickup_Remove(void) {
    if(self.buff_waypoint)
        WaypointSprite_Kill(self.buff_waypoint);
    if(self.enemy)
        remove(self.enemy);
    remove(self);
}

void Buffs_BuffPickup_Placeholder(void) {
    if(!g_buffs || !g_buffs_spawn_on_powerups)
        return;
    
    entity e = spawn();
    setorigin(e, self.origin);
    e.owner = self;
    e.classname = "buff_placeholder";
    
    //error(strcat(vtos(e.origin), " ", vtos(e.owner.origin), " ", e.owner.classname));
}

void Buffs_BuffPickup_SetupQ3TACompat(string rune) {
    if(self.spawnflags & 2)
        self.team = COLOR_TEAM1;
    else if(self.spawnflags & 4)
        self.team = COLOR_TEAM2;
    
    if not((self.buffs = Buffs_NameToType(cvar_string(strcat("g_buffs_q3ta_", rune))))) {
        remove(self);
        return;
    }
    
    Buffs_BuffPickup_Setup();
}

#define BUFF_SPAWNFUNC(e,b,t) void spawnfunc_item_buff_##e() { self.buffs = b; self.team = t; Buffs_BuffPickup_Setup(); }
#define BUFF_SPAWNFUNC_Q3TA_COMPAT(o,r) void spawnfunc_##o() { Buffs_BuffPickup_SetupQ3TACompat(r); }
#define BUFF_SPAWNFUNCS(e,b)                         \
        BUFF_SPAWNFUNC(e,           b,  0)           \
        BUFF_SPAWNFUNC(e##_team1,   b,  COLOR_TEAM1) \
        BUFF_SPAWNFUNC(e##_team2,   b,  COLOR_TEAM2) \
        BUFF_SPAWNFUNC(e##_team3,   b,  COLOR_TEAM3) \
        BUFF_SPAWNFUNC(e##_team4,   b,  COLOR_TEAM4) 

BUFF_SPAWNFUNCS(arc,        BUFF_ARC)
BUFF_SPAWNFUNCS(guard,      BUFF_GUARD)
BUFF_SPAWNFUNCS(supply,     BUFF_SUPPLY)
BUFF_SPAWNFUNCS(haste,      BUFF_HASTE)
BUFF_SPAWNFUNCS(medic,      BUFF_MEDIC)
BUFF_SPAWNFUNCS(bash,       BUFF_BASH)
BUFF_SPAWNFUNCS(vampire,    BUFF_VAMPIRE)
BUFF_SPAWNFUNCS(tenacity,   BUFF_TENACITY)
BUFF_SPAWNFUNCS(wrath,      BUFF_WRATH)
BUFF_SPAWNFUNCS(adept,      BUFF_ADEPT)
BUFF_SPAWNFUNCS(random,     BUFF_RANDOM)

BUFF_SPAWNFUNC_Q3TA_COMPAT(item_doubler,    "doubler")
BUFF_SPAWNFUNC_Q3TA_COMPAT(item_guard,      "guard")
BUFF_SPAWNFUNC_Q3TA_COMPAT(item_scout,      "scount")
BUFF_SPAWNFUNC_Q3TA_COMPAT(item_ammoregen,  "ammoregen")


