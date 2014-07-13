
//
//  NOTE: most of the Freeze Tag logic is now handled by the g_freeze mutator, see g_freeze.qc.
//

void FreezeTag_EndRound()
{
    G_EndRound(5, cvar("g_freezetag_warmup"), Freeze_RecountPlayers, func_null, func_null);
    Freeze_RecountPlayers();
    defer(5, sm_Clear);
}

void FreezeTag_Frame()
{
    FreezeTag_CheckWinner();
    self.nextthink = time;
}

void FreezeTag_Initialize()
{
    ft_teams = cvar("g_freezetag_teams_override");
    if(ft_teams < 2)
        ft_teams = cvar("g_freezetag_teams");
    ft_teams = bound(2, ft_teams, 4);
    
    precache_sound("ctf/red_capture.wav");
    precache_sound("ctf/blue_capture.wav");
    precache_sound("kh/capture.wav");
    
    if(inWarmupStage)
        warmup = time;
    else
        warmup = time + cvar("g_start_delay");
    
    ScoreRules_freezetag();
    
    entity e = spawn();
    e.think = FreezeTag_Frame;
    e.nextthink = time;
    
    defer(0.2, sm_Init);
}

void FreezeTag_CheckWinner()
{
    string teamname, teamname_full;
    float winnerteam, i, teams_found, alivefound;
    entity e;
    
    DEPENDON(g_freezetag)
    
    if(intermission_running)
        return;

    if(time <= game_starttime) // game didn't even start yet! nobody can win in that case.
        return;

    if(roundstate != ROUNDSTATE_GAME)
        return;
    
    for(i = 0; i < ft_teams; ++i) {
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
        FreezeTag_EndRound();
        return;
    }
    
    if(ft_teams > 2)
        play2all("kh/capture.wav");
    
    FOR_EACH_PLAYER(e) {
        bigprint_spec(e, strcat(teamname, " ^7Scores!"), "All opponents are frozen", 5);
        
        if(e.team == winnerteam)
            hudflash_teamcolor_default_spec(e);
    }
    
    bprint(teamname_full, "^5 wins the round since all their opponents were frozen\n");
    TeamScore_AddToTeam(winnerteam, ST_SCORE, +1);

    //next_round = time + 5;
    FreezeTag_EndRound();
}
