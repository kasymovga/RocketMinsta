
void Freeze_Init(void) {
    if(!teams_matter || g_jailbreak || g_clanarena || (!cvar("g_freeze") && !g_freezetag))
        return;
    
    g_freeze = TRUE;
    Freeze_Precache();
    
    addstat(STAT_REDALIVE, AS_INT, redalive_stat);
    addstat(STAT_BLUEALIVE, AS_INT, bluealive_stat);
    addstat(STAT_YELLOWALIVE, AS_INT, yellowalive_stat);
    addstat(STAT_PINKALIVE, AS_INT, pinkalive_stat);
    addstat(STAT_FROZEN, AS_INT, frozen);
    addstat(STAT_REVIVE_PROGRESS, AS_FLOAT, revprogress);
    
    if(g_soulmates)
        addstat(STAT_SM_HASGEM, AS_INT, sm_canattach);
    
    g_freeze_globalwarming_reset = TRUE;
    
    entity e = spawn();
    e.think = Freeze_Frame;
    e.nextthink = time;
}

void Freeze_Precache(void) {
    precache_sound("kh/alarm.wav");
    precache_sound("freezetag/freezing.wav");
    precache_model("models/ice/ice.md3");
}

string Freeze_CVarName(string s) {
    if(g_freezetag)
        return strcat("g_freezetag_", s);
    return strcat("g_freeze_", s);
}

void Freeze_GlobalWarming_Warn(float s) {
    entity e; FOR_EACH_PLAYER(e)
        bigprint_spec(e, strcat(ftos(floor(s)), " seconds until ^xFB0Global Warming"), "", 2);
}

void Freeze_Frame(void) {
    float gw, r, wr;
    self.nextthink = time;
    
    if(!Freeze_GameInProgress()) {
        g_freeze_globalwarming_reset = TRUE;
        g_freeze_globalwarming_warned = 0;
        return;
    }
    
    gw = Freeze_CVar("global_warming");
    
    if(gw) {
        if(g_freeze_globalwarming_reset && !g_freeze_globalwarming_warned) {
            Freeze_SetGlobalWarming(gw);
            g_freeze_globalwarming_reset = FALSE;
        }
        
        r = 1;
        wr = Freeze_CVar("global_warming_minratio");
        
        if(!g_freeze_globalwarming_warned && wr < 1) {
            r = min(r, (teamcount_playerstotal[0]? teamcount_playersalive[0]/teamcount_playerstotal[0] : 1));
            r = min(r, (teamcount_playerstotal[1]? teamcount_playersalive[1]/teamcount_playerstotal[1] : 1));
            r = min(r, (teamcount_playerstotal[2]? teamcount_playersalive[2]/teamcount_playerstotal[2] : 1));
            r = min(r, (teamcount_playerstotal[3]? teamcount_playersalive[3]/teamcount_playerstotal[3] : 1));
        } else r = 0;
        
        if(r <= wr) {
            g_freeze_globalwarming -= frametime;
            
            if(g_freeze_globalwarming < 5 && g_freeze_globalwarming_warned < 2) {
                Freeze_GlobalWarming_Warn(5);
                g_freeze_globalwarming_warned = 2;
            } else if(g_freeze_globalwarming < 10 && g_freeze_globalwarming_warned < 1) {
                Freeze_GlobalWarming_Warn(10);
                g_freeze_globalwarming_warned = 1;
            } else if(g_freeze_globalwarming <= 0) {
                play2all("kh/alarm.wav");
                entity e; FOR_EACH_PLAYER(e)
                    bigprint_spec(e, "^xFB0Global Warming!", "Everyone has been unfrozen!", 3);
                Freeze_UnfreezeAll();
            }
        }
    }
}

float Freeze_GameInProgress(void) {
    //return !(!g_freeze || time < game_starttime || time < warmup || (g_vip && (!vip_started || vip_ended)) || (g_total_domination && !tdom_maycap));
    return roundstate == ROUNDSTATE_GAME;
}

void Freeze_Ice_Think() {
    setorigin(self, self.owner.origin - '0 0 16');
    self.nextthink = time;
    self.alpha = 1 - self.owner.revprogress;
}

float Freeze_GetPlayersAlive(float t) {
    return teamcount_playersalive[Team_Index(t)];
}

float Freeze_GetPlayersTotal(float t) {
    return teamcount_playerstotal[Team_Index(t)];
}

float Freeze_AliveCheck(entity plr) {
    return !plr.frozen;
}

void Freeze_RecountPlayers(void) {
    TeamCount_RecountPlayers(Freeze_AliveCheck);
}

entity Freeze_SpawnIceBlock(entity plr) {
    entity ice = spawn();
    ice.owner = plr;
    ice.classname = "freeze_ice";
    ice.think = Freeze_Ice_Think;
    ice.nextthink = time;
    ice.frame = floor(random() * 21); // ice model has 20 different looking frames
    ice.effects |= EF_ADDITIVE;
    setmodel(ice, "models/ice/ice.md3");
    setorigin(ice, plr.origin - '0 0 16');
    plr.iceblock = ice;
    if(Freeze_CVar("freezesound"))
        sound(self, CHAN_TRIGGER, "freezetag/freezing.wav", VOL_BASE, ATTN_NORM);
    return ice;
}

entity Freeze_SpawnWaypoint(entity plr) {
    entity w = WaypointSprite_Spawn("Frozen!", 0, 0, plr, '0 0 64', world, plr.team, plr, freeze_waypoint, TRUE);
    WaypointSprite_UpdateTextColors(plr.freeze_waypoint, '0.2 1 1', '0 0 0', '0 0 0');
    WaypointSprite_UpdateTeamRadar(plr.freeze_waypoint, RADARICON_WAYPOINT, '0.25 0.90 1');
    return w;
}

void Freeze_FreezePlayer(entity plr, entity attacker) {
    if(plr.frozen)
        return;
    
    plr.revrow = 0;
    plr.frozen = 1;
    
    plr.revprogress = 0;
    plr.freezetime = plr.freezetime_real = time;
    plr.meltprogress = 0;
    RemoveGrapplingHook(plr);
    
    if(!plr.iceblock)
        Freeze_SpawnIceBlock(plr);
        
    plr.iceblock.team = plr.team;
    if(Freeze_CVar("iceblocks_teamcolored"))
        plr.iceblock.skin = TeamColorSkin(plr.team);
        
    if(!plr.freeze_waypoint)
        Freeze_SpawnWaypoint(plr);
    
    if(attacker == plr) {
        PlayerScore_Add(plr, SP_SCORE, -Freeze_CVar("penalty_death"));
    } else if(attacker.classname == "player") {
        if(attacker.team != plr.team) {
            PlayerScore_Add(plr, SP_SCORE, -Freeze_CVar("penalty_death"));
            PlayerScore_Add(attacker, SP_SCORE, Freeze_CVar("score_freeze"));
        } else // teamkill
            PlayerScore_Add(attacker, SP_SCORE, -Freeze_CVar("penalty_teamkill"));
    }
    
    PlayerScore_Set(plr, SP_FROZENSTATUS, 1);
    Freeze_RecountPlayers();
}

void Freeze_UnfreezePlayer(entity plr)
{
    if(!plr || !plr.frozen)
        return;
    
    plr.frozen = 0;
    plr.revprogress = 0;
    plr.disableclientprediction = 0;
    
    if(plr.iceblock) {
        remove(plr.iceblock);
        plr.iceblock = world;
    }
    
    if(plr.freeze_waypoint)
        WaypointSprite_Disown(plr.freeze_waypoint, 0.5);
    
    if(g_nadgets) {
        if(cvar("g_nadgets_regen_time")) {
            plr.hg_power = 0;
        } else HG_PlayerSpawnEx(plr);
    }
    
    PlayerScore_Set(plr, SP_FROZENSTATUS, 0);
    Freeze_RecountPlayers();
}

void Freeze_SetGlobalWarming(float d) {
    if(d < 10) {
        if(d < 5)
            g_freeze_globalwarming_warned = 2;
        else 
            g_freeze_globalwarming_warned = 1;
    } else
        g_freeze_globalwarming_warned = 0;
    
    g_freeze_globalwarming = d;
}

void Freeze_UnfreezeAll(void) {
    entity e; FOR_EACH_PLAYER(e) if(e.frozen)
        Freeze_UnfreezePlayer(e);
    g_freeze_globalwarming_reset = TRUE;
    g_freeze_globalwarming_warned = 0;
}

void Freeze_SaveSpawnState(entity plr) {
    plr.spawnstate_saved = TRUE;
    plr.spawnstate_team = plr.team;
    plr.spawnstate_origin = plr.origin;
    plr.spawnstate_angles = plr.angles;
}

void Freeze_RestoreSpawnState(entity plr) {
    if(plr.spawnstate_saved && plr.team == plr.spawnstate_team) {
        plr.angles = plr.spawnstate_angles;
        plr.angles_z = 0;
        plr.fixangle = 1;
        setorigin(plr, plr.spawnstate_origin + '0 0 1' * (1 - plr.mins_z - 24));
    }
    
    plr.spawnstate_saved = FALSE;
}

void Freeze_DangerShortcut(void) {
    if(self.BUTTON_ATCK) {
        if(!self.danger_used) {
            stuffcmd(self, "cl_cmd danger\n");
            self.danger_used = 1;
        }
    } else self.danger_used = 0;
}

void Freeze_RespawnPlayer(entity p) {
    entity sp = SelectSpawnPoint(FALSE);
        
    if(!sp) {
        bprint("Coudln't select a spawn point for ", p.netname, "^7!\n");
    } else
        TeleportPlayer(p, p, sp.origin, sp.angles, '0 0 0', '0 0 0', '0 0 0');
}

string W_ThrowNewWeapon(entity, float, float, vector, vector);
float Freeze_Hook_PlayerDies(entity attacker, vector frce, float deathtype) {
    if(!g_freeze)
        return 0;
    
    if(roundstate != ROUNDSTATE_GAME)
        return 0;
    
    if(g_vip && ISVIP(self))
        return 0;
    
    if(!self.frozen) {
        Boobs_DropAllAndRespawn(frce);
        Freeze_FreezePlayer(self, attacker);
    }
    
    self.health = Freeze_CVar("frozen_health");
    self.armorvalue = Freeze_CVar("frozen_armor");
    
    if(g_minstagib)
        W_ThrowNewWeapon(self, WEP_MINSTANEX, 0, self.origin, self.velocity);
    
    if(attacker && attacker != self)
        attacker.frozenrow = 0;
    
    self.frozenrow += 1;
    float r = Freeze_CVar("frozen_row_respawn");
    
    if(deathtype == DEATH_HURTTRIGGER)
        Freeze_RespawnPlayer(self);
    else if(r) if(self.frozenrow >= r) {
        Freeze_RespawnPlayer(self);
        if(self.frozenrow > 1)
            bigprint_spec(self, "", strcat("^5You were moved to a random spawn point after dying ", ftos(self.frozenrow), " times in a row"), 5);
        self.frozenrow = 0;
    }
    
    AloneWarning(self.team, Freeze_AliveCheck);
    
    return 1;
}

void Freeze_Hook_PlayerQuits(void) {
    if(!g_freeze)
        return;
    
    sm_RemovePlayer();
    Freeze_UnfreezePlayer(self);
    Freeze_SaveSpawnState(self);
    // Do it in the next frame
    defer(0, Freeze_RecountPlayers);
}

void Freeze_Hook_PlayerSpawns(void) {
    if(!g_freeze)
        return;
    
    Freeze_UnfreezePlayer(self);
    
    if(!Freeze_GameInProgress())
        return;
    
    self.revprogress = 0;
    self.meltprogress = 0;
    
    Freeze_RecountPlayers();
    if(Freeze_GetPlayersTotal(self.team) - 1 > 0) {
        centerprint_spec(self, "^5You spawned after the game started, you'll spawn frozen\n");
        Freeze_FreezePlayer(self, world);
        Freeze_RestoreSpawnState(self);
    }
}

void Freeze_RevivePlayer(entity plr, entity revlist) {
    float first = TRUE;
    string names;
    entity e;
    float pcnt = 1;
    
    if(!plr.frozen)
        return;
    
    Freeze_UnfreezePlayer(plr);
    plr.revtime = time;
    
    // EVERY team mate nearby gets a point (even if multiple!)
    
    if(Freeze_CVar("score_revival_shared"))
        for(e = revlist.chain; e; e = e.chain)
            ++pcnt;
    
    for(e = revlist; e; e = e.chain) {
        PlayerScore_Add(e, SP_REVIVALS, 1);
        PlayerScore_Add(e, SP_SCORE, Freeze_CVar("score_revival") / pcnt);
        
        e.health = max(e.health, Freeze_CVar("revive_heal"));
        centerprint_spec(e, strcat("^5You revived ^7", plr.netname, "\n"));
        
        e.revrow++;
        if(Freeze_CVar("revive_bonusgrenade"))
        if(e.revrow >= Freeze_CVar("revive_bonusgrenade_requirement")) {
            HG_GiveBonus(e, HG_NameToType(Freeze_CVarString("revive_bonusgrenade_type")), 1,
                        strcat(ftos(e.revrow), " revivals in a row")
            );
            e.revrow = 0;
        }
        
        if(first) {
            names = e.netname;
            first = FALSE;
        } else
            names = strcat(names, "^7, ", e.netname);
        
        e.revprogress = plr.revprogress;
        e.revresettime = time + frametime * 2;
    }
    
    plr.hg_plasmalock = 0;
    centerprint_spec(plr, strcat("^5You were revived by ^7", names, "\n"));
    bprint("^7", names, "^5 revived ^7", plr.netname, "\n");
}

void Freeze_Hook_PlayerPreThink(void) {
    vector revive_extra_size;
    entity rfirst, rlast, h;
    
    if(!g_freeze)
        return;
    
    if(roundstate == ROUNDSTATE_WARMUP)
        PlayerScore_Set(self, SP_FROZENSTATUS, 0);
    
    if(!Freeze_GameInProgress()) {
        self.revprogress = 0;
        self.meltprogress = 0;
        return;
    }
    
    if(!self.frozen) {
        if(time > self.revresettime)
            self.revprogress = 0;
        
        if(self.iceblock) {
            remove(self.iceblock);
            self.iceblock = world;
        }
        
        if(self.freeze_waypoint) {
            WaypointSprite_Disown(self.freeze_waypoint, 0.5);
            PlayerScore_Set(self, SP_FROZENSTATUS, 0);
            Freeze_RecountPlayers();
        }
        
        sm_Frame();
        return;
    }
    
    // frozen
    
    float ftime = Freeze_CVar("respawn");
    if(ftime)
    if(time - self.freezetime_real > ftime) {
        Freeze_UnfreezePlayer(self);
        Freeze_RespawnPlayer(self);
        centerprint_spec(self, strcat("^5You have been respawned after staying frozen for ", ftos(ftime), " seconds\n"));
        bprint(self.netname, " ^5has been respawned after staying frozen for ", ftos(ftime), " seconds\n");
        return;
    }
    
    if(!self.iceblock)
        Freeze_SpawnIceBlock(self);
    
    if(self.iceblock.team != self.team) {
        if(Freeze_CVar("iceblocks_teamcolored"))
            self.iceblock.skin = TeamColorSkin(self.team);
        self.iceblock.team = self.team;
        WaypointSprite_Disown(self.freeze_waypoint, 0.5);
    }
    
    if(!self.freeze_waypoint) {
        PlayerScore_Set(self, SP_FROZENSTATUS, 1);
        Freeze_SpawnWaypoint(self);
        Freeze_RecountPlayers();
    }
    
    Freeze_DangerShortcut();
    self.BUTTON_ATCK = self.BUTTON_ATCK2 = FALSE;
    
    float rmod;
    float allow;
    
    if(time < self.hg_plasmalock)
        return;
    
    // Find all players withing revival radius and build a linked list
    if(self.freezetime + Freeze_CVar("revive_delay") < time) {
        revive_extra_size = '1 1 1' * Freeze_CVar("revive_extra_size");
        
        FOR_EACH_PLAYER(other)
            if(time - other.hg_stealthtime >= cvar("g_nadgets_cloak_actiondelay"))
            if(self != other && !other.frozen && other.team == self.team)
            if(time - other.revtime >= Freeze_CVar("revive_delay_after_revived"))
            if(time - other.lastdamage >= Freeze_CVar("revive_delay_for_reviver"))
            if(boxesoverlap(self.absmin - revive_extra_size, self.absmax + revive_extra_size, other.absmin, other.absmax))
            {
                allow = Freeze_CVar("revive_through_walls");
                
                if(!allow) {
                    vector o = self.origin + self.view_ofs;
                    vector e = other.origin + other.view_ofs;
                    
                    traceline(o, e, TRUE, self);
                    allow = (trace_endpos == e);
                    
                    if(!allow)
                        allow = (vlen(trace_endpos - e) < Freeze_CVar("revive_wall_trace_tolerance"));
                }
                
                if(allow) {
                    if(!rfirst)
                        rfirst = other;
                        
                    if(rlast)
                        rlast.chain = other;
                        
                    rlast = other;
                    other.chain = world;
                    
                    float lmod = 1;
                    if(other.hg_shield)
                        lmod *= cvar("g_nadgets_shield_progressrate");
                    if(BUFFS_PRESENT(other, BUFF_MEDIC))
                        lmod = lmod + (cvar("g_buffs_medic_revivefactor") - lmod) * Buffs_BuffPower(other, BUFF_MEDIC);
                    rmod = max(rmod, lmod);
                }
            }
    }
        
    if(rfirst) // OK, there is at least one teammate reviving us
    {
        float rate = Freeze_CVar("revive_speed") * rmod;
        
        self.revfinished = 0;
        self.revprogress = bound(0, self.revprogress + frametime * rate, 1);

        if(self.revprogress >= 1) {
            Freeze_RevivePlayer(self, rfirst);
            return;
        } else for(other = rfirst; other; other = other.chain) {
            other.revprogress = self.revprogress;
            other.revresettime = time + frametime * 2;
        }
    } else if(self.revfinished) {
        if(Freeze_CVar("melt"))
        {
            for(h = world; (h = find(h, classname, "grapplinghook")); )
                if(h.aiment == self)
                    return;
            
            if(self.freezetime + Freeze_CVar("melt_delay") <= time) {
                self.meltprogress = bound(0, self.meltprogress + frametime * Freeze_CVar("melt_speed"), 1);
                
                if(self.meltprogress >= 1) {
                    self.meltprogress = 0;
                    Freeze_UnfreezePlayer(self);
                    bprint(self.netname, "^5's iceblock has melted\n");
                    centerprint_spec(self, "^5Your iceblock has melted");
                    return;
                }
            }
            
            self.revprogress = self.meltprogress;
            self.revresettime = time + frametime * 2;
        }
        else
            self.meltprogress = 0;
    } else { // only if no teammate is nearby will we reset
        self.revprogress = bound(0, self.revprogress - frametime * Freeze_CVar("revive_clearspeed"), 1);
        self.meltprogress = self.revprogress;
        
        if(!self.revprogress)
            self.revfinished = 1;
    }
}

void Freeze_Hook_PlayerPhysics(void) {
    if(!g_freeze)
        return;
    
    if(self.frozen) {
        float s = Freeze_CVar("frozen_movespeed");
        
        if(s > 0) {
            if(Freeze_CVar("movespeed_dependonmelt"))
                s *= self.revprogress;
            
            self.movement_x = (
                (self.movement_x > 0)?
                    bound( 0, self.movement_x, s)
                :	bound(-s, self.movement_x, 0)
            );
            
            self.movement_y = (
                (self.movement_y > 0)?
                    bound( 0, self.movement_y, s)
                :	bound(-s, self.movement_y, 0)
            );
            
            self.movement_z = (
                (self.movement_z > 0)?
                    bound( 0, self.movement_z, s)
                :	bound(-s, self.movement_z, 0)
            );
        } else
            self.movement = '0 0 0';
        
        self.disableclientprediction = 1;
    }
}
