
float ca_recount;

void CA_Frame(void) {
    self.nextthink = time;
    if(ca_recount) {
        TeamCount_RecountPlayers(CA_AliveCheck);
        CA_CheckWinner();
        ca_recount = FALSE;
    }
}

void CA_Initialize(void) {
    ca_teams = bound(2, cvar("g_clanarena_teams"), 4);
    
    addstat(STAT_REDALIVE, AS_INT, redalive_stat);
    addstat(STAT_BLUEALIVE, AS_INT, bluealive_stat);
    addstat(STAT_YELLOWALIVE, AS_INT, yellowalive_stat);
    addstat(STAT_PINKALIVE, AS_INT, pinkalive_stat);
    
    precache_sound("ctf/red_capture.wav");
    precache_sound("ctf/blue_capture.wav");
    precache_sound("kh/capture.wav");
    
    g_clanarena_pickups = cvar("g_clanarena_pickups");
    
    if(inWarmupStage)
        warmup = time;
    else
        warmup = time + cvar("g_start_delay");
    
    entity ca = spawn();
    ca.think = CA_Frame;
    ca.nextthink = time;
    
    sv_nicehealth = cvar("g_clanarena_start_health") + cvar("g_clanarena_start_armor");
}

float CA_AliveCheck(entity plr) {
    return !plr.jb_specteam && plr.health > 0;
}

void CA_EndRound(void) {
    G_EndRound(5, cvar("g_clanarena_warmup"), CA_RecountPlayers, func_null, func_null);
    CA_RecountPlayers();
}

void CA_RecountPlayers(void) {
    ca_recount = TRUE;
}

void CA_CheckWinner(void) {
    /*
     * XXX: this is mostly copypaste from Freezetag_CheckWinner, it need to be generalized somehow
     */
    
    string teamname, teamname_full;
    float winnerteam, i, teams_found, alivefound;
    entity e;
    
    if(roundstate != ROUNDSTATE_GAME)
        return;
    
    for(i = 0; i < ca_teams; ++i) {
        if(teamcount_playerstotal[i]) {
            if(teamcount_playersalive[i]) {
                alivefound = TRUE;
                if(!winnerteam)
                    winnerteam = Team_FromIndex(i);
                else
                    return;
            }
            
            ++teams_found;
        }
    }
    
    if((!winnerteam && alivefound) || teams_found < 2)
        return;
    
    if(winnerteam == COLOR_TEAM1) {
        teamname = "^1Red";
        teamname_full = "^1Red team";
        if(ft_teams < 3) play2all("ctf/red_capture.wav");
    } else if(winnerteam == COLOR_TEAM2) {
        teamname = "^4Blue";
        teamname_full = "^4Blue team";
        if(ft_teams < 3) play2all("ctf/blue_capture.wav");
    } else if(winnerteam == COLOR_TEAM3) {
        teamname = "^3Yellow";
        teamname_full = "^3Yellow team";
    } else if(winnerteam == COLOR_TEAM4) {
        teamname = "^6Pink";
        teamname_full = "^6Pink team";
    } else {
        FOR_EACH_PLAYER(e)
            bigprint_spec(e, "Round Draw!", "", 5);
        CA_EndRound();
        return;
    }
    
    if(ft_teams > 2)
        play2all("kh/capture.wav");
    
    FOR_EACH_PLAYER(e) {
        bigprint_spec(e, strcat(teamname, " ^7Scores!"), "All opponents are down", 5);
        
        if(e.team == winnerteam)
            hudflash_teamcolor_default_spec(e);
    }
    
    bprint(teamname_full, "^5 wins the round since all their opponents got wrecked\n");
    TeamScore_AddToTeam(winnerteam, ST_SCORE, +1);
    
    CA_EndRound();
}

void CA_PlayerDies(entity attacker) {
    if(!g_clanarena)
        return;
    
    if(roundstate != ROUNDSTATE_GAME)
        return;
    
    if(attacker.classname == "player") {
        if(self == attacker) {
        } else if(self.team == attacker.team) {
            PlayerScore_Add(attacker, SP_SCORE, -cvar("g_clanarena_penalty_teamkill"));
        } else {
            PlayerScore_Add(attacker, SP_SCORE,  cvar("g_clanarena_score_kill"));
        }
    }
    
    PlayerScore_Add(self, SP_SCORE, -cvar("g_clanarena_penalty_death"));
    PlayerScore_Set(self, SP_FROZENSTATUS, 1);
    
    AloneWarning(self.team, CA_AliveCheck);
    CA_RecountPlayers();
}

void CA_PlayerLeaves(void) {
    if(g_clanarena)
        CA_RecountPlayers();
}

void CA_PlayerJoins(void) {
    if(g_clanarena) {
        // TODO: do this more efficiently
        if(roundstate == ROUNDSTATE_GAME)
        if(self.classname == "player") 
        if(teamcount_playerstotal[Team_Index(self.team)]) {
            PlayerScore_Set(self, SP_FROZENSTATUS, 1);
            JB_JailSpectate();
        }
        CA_RecountPlayers();
    }
}

float CA_AttemptRespawn(void) {
    if(!g_clanarena)
        return FALSE;
    
    if(roundstate == ROUNDSTATE_GAME) {
        JB_JailSpectate();
        return TRUE;
    }
    
    if(roundstate == ROUNDSTATE_OVER)
        return TRUE;
        
    return FALSE;
}
