
/*
Domination as a plugin for netquake mods
by LordHavoc (lordhavoc@ghdigital.com)

How to add domination points to a mod:
1. Add this line to progs.src above world.qc:
domination.qc
2. Comment out all lines in ClientObituary in client.qc that begin with targ.frags  or attacker.frags.
3. Add this above spawnfunc_worldspawn in world.qc:
void() dom_init;
4. Add this line to the end of spawnfunc_worldspawn in world.qc:
dom_init();

Note: The only teams who can use dom control points are identified by spawnfunc_dom_team entities (if none exist these default to red and blue and use only quake models/sounds).
*/

void dom_recountpoints()
{
    totalpoints = redpoints = bluepoints = 0;

    local entity e;
    FOR_EACH_DOM_CONTROLPOINT(e)
	{
		++totalpoints;
		
		if(e.goalentity.team == COLOR_TEAM1)
			++redpoints;
		else if(e.goalentity.team == COLOR_TEAM2)
			++bluepoints;
	}

    FOR_EACH_CLIENT(e)
    {
        e.totalpoints_stat = totalpoints;
        e.redpoints_stat   = redpoints  ;
        e.bluepoints_stat  = bluepoints ;
    }
}

void tdom_EndRound()
{
	G_EndRound(5, cvar("g_totaldomination_warmup"), dom_recountpoints, func_null, func_null);
}

void() dom_controlpoint_setup;

void LogDom(string mode, float team_before, entity actor)
{
	string s;
	if(!cvar("sv_eventlog"))
		return;
	s = strcat(":dom:", mode);
	s = strcat(s, ":", ftos(team_before));
	s = strcat(s, ":", ftos(actor.playerid));
	GameLogEcho(s);
}

void() dom_spawnteams;

void tdom_checkwinner()
{
    local entity e;
    dom_recountpoints(); 
	
	if(!bluepoints && redpoints && redpoints == totalpoints)
	{
		//bprint("^5Total domination: ^1RED WINS\n");
		FOR_EACH_PLAYER(e)
		{
			bigprint_spec(e, "^1Red ^7Scores!", "All control points have been captured", 5);
			
			if(e.team == COLOR_TEAM1)
				hudflash_teamcolor_default_spec(e);
		}
		bprint("^1Red team ^5wins the round since they have captured all of the control points\n");
		play2all("ctf/red_capture.wav");
		TeamScore_AddToTeam(COLOR_TEAM1, ST_SCORE, 1);
		tdom_EndRound();
	}
	
	if(!redpoints && bluepoints && bluepoints == totalpoints)
	{
		//bprint("^5Total domination: ^4BLUE WINS\n");
		FOR_EACH_PLAYER(e)
		{
			bigprint_spec(e, "^4Blue ^7Scores!", "All control points have been captured", 5);
				
			if(e.team == COLOR_TEAM2)
				hudflash_teamcolor_default_spec(e);
		}
		bprint("^4Blue team ^5wins the round since they have captured all of the control points\n");
		play2all("ctf/blue_capture.wav");
		TeamScore_AddToTeam(COLOR_TEAM2, ST_SCORE, 1);
		tdom_EndRound();
	}
}

void dompoint_captured ()
{
	local entity head;
	local float old_delay, old_team, real_team;

	// now that the delay has expired, switch to the latest team to lay claim to this point
	head = self.owner;

	real_team = self.cnt;
	self.cnt = -1;

	LogDom("taken", self.team, self.dmg_inflictor);
	self.dmg_inflictor = world;

	self.goalentity = head;
	self.model = head.mdl;
	self.modelindex = head.dmg;
	self.skin = head.skin;

	//bprint(head.message);
	//bprint("\n");

	//bprint(^3head.netname);
	//bprint(head.netname);
	//bprint(self.message);
	//bprint("\n");

	//bprint("^3", head.netname, "^3", self.message, "\n");
	
	string teamname_full;
	
	if(self.enemy.team == COLOR_TEAM1)
		teamname_full = "^1Red team";
	else if(self.enemy.team == COLOR_TEAM2)
		teamname_full = "^4Blue team";
	else if(self.enemy.team == COLOR_TEAM3)
		teamname_full = "^3Yellow team";
	else
		teamname_full = "^6Pink team";
	
	bprint(self.enemy.netname, " ^5has captured a control point for the ", teamname_full, "\n");
	centerprint_spec(self.enemy, "^5You have captured a control point!");
	hudflash_teamcolor_default_spec(self.enemy);
	
	if(self.enemy.playerid == self.enemy_playerid)
		PlayerScore_Add(self.enemy, SP_DOM_TAKES, 1);
	else
		self.enemy = world;

	if (head.noise != "")
		if(self.enemy)
			sound(self.enemy, CHAN_AUTO, head.noise, VOL_BASE, ATTN_NORM);
		else
			sound(self, CHAN_TRIGGER, head.noise, VOL_BASE, ATTN_NORM);
	if (head.noise1 != "")
		play2all(head.noise1);

	//self.nextthink = time + cvar("g_domination_point_rate");
	//self.think = dompointthink;

	if(cvar("g_domination_point_rate"))
		self.delay = time + cvar("g_domination_point_rate");
	else
		self.delay = time + self.wait;

	// do trigger work
	old_delay = self.delay;
	old_team = self.team;
	self.team = real_team;
	self.delay = 0;
	activator = self;
	SUB_UseTargets ();
	self.delay = old_delay;
	self.team = old_team;
    
    WaypointSprite_UpdateTextColors(self.sprite, TeamColor(self.goalentity.team), '0 0 0', '0 0 0');
	WaypointSprite_UpdateTeamRadar(self.sprite, RADARICON_DOMPOINT, colormapPaletteColor(self.goalentity.team - 1, 0));
	WaypointSprite_Ping(self.sprite);

	self.captime = time;
	
	if(g_totaldomination)
		tdom_checkwinner();
	else
		dom_recountpoints(); 
};

void AnimateDomPoint()
{
	if(self.pain_finished > time)
		return;
	self.pain_finished = time + self.t_width;
	if(self.nextthink > self.pain_finished)
		self.nextthink = self.pain_finished;

	self.frame = self.frame + 1;
	if(self.frame > self.t_length)
		self.frame = 0;
}

void dompointthink()
{
	local float waittime;
	local float fragamt;

	self.nextthink = time + 0.1;
    
    if(!self.sprite) {
        waypoint_spawnforitem(self);
        WaypointSprite_SpawnFixed(strcat("Point ", chr2str(str2chr("A", 0) + dom_numpts)), self.origin + '0 0 37', self, sprite);
        WaypointSprite_UpdateTextColors(self.sprite, '0 1 1', '0 0 0', '0 0 0');
        WaypointSprite_UpdateTeamRadar(self.sprite, RADARICON_DOMPOINT, '0 1 1');
        ++dom_numpts;
    }
    
    if(time - self.pointupdatetime > 0.15) {
		self.dom_captureprogress = bound(0, self.dom_captureprogress - frametime * cvar("g_domination_capture_clearspeed"), 1);
        self.dom_capturingplayer = world;
    }
	
	//self.frame = self.frame + 1;
	//if(self.frame > 119)
	//	self.frame = 0;
	AnimateDomPoint();

	// give points

	if (gameover || self.delay > time || time < game_starttime)	// game has ended, don't keep giving points
		return;

	waittime = cvar("g_domination_point_rate");
	if(!waittime)
		waittime = self.wait;
	self.delay = time + waittime;

	// give credit to the team
	// NOTE: this defaults to 0
	if (self.goalentity.netname != "")
	{
		fragamt = cvar("g_domination_point_amt");
		if(!fragamt)
			fragamt = self.DOMPOINTFRAGS;
			
		if(!g_totaldomination)
			TeamScore_AddToTeam(self.goalentity.team, ST_SCORE, fragamt);
			
		TeamScore_AddToTeam(self.goalentity.team, ST_DOM_TICKS, fragamt);

		// give credit to the individual player, if he is still there
		if (self.enemy.playerid == self.enemy_playerid)
		{
			PlayerScore_Add(self.enemy, SP_SCORE, fragamt);
			PlayerScore_Add(self.enemy, SP_DOM_TICKS, fragamt);
		}
		else
			self.enemy = world;
	}
}

void dompointtouch()
{
	local entity head;
    
    if(time < game_starttime)
        return;
    
	if(other.classname != "player")
		return;
	if(other.health < 1)
		return;
    if(g_freeze && other.frozen)
        return;
    
    if(time - other.hg_stealthtime < cvar("g_nadgets_cloak_actiondelay"))
        return;
    
	if(time < self.captime + 0.3)
		return;

    if(self.dom_capturingplayer && self.dom_capturingplayer != other)
        return;

	if(g_totaldomination)
	if(roundstate != ROUNDSTATE_GAME)
		return;
    
	// only valid teams can claim it
	head = find(world, classname, "dom_team");
	while(head && head.team != other.team)
		head = find(head, classname, "dom_team");
	if(!head || head.netname == "" || head == self.goalentity)
		return;

    float rate = cvar("g_domination_capture_speed");
    if(other.hg_shield)
        rate *= cvar("g_nadgets_shield_progressrate");

	self.dom_captureprogress = bound(0, self.dom_captureprogress + frametime * rate, 1);
	self.pointupdatetime = time;
    other.pointupdatetime = time;
    self.dom_capturingplayer = other;

    other.dom_captureprogress = self.dom_captureprogress;
	if(self.dom_captureprogress < 1)
	{
		//bprint(other.netname, "^7.dom_captureprogress = ", ftos(other.dom_captureprogress), "\n");
		return;
	}
	self.dom_captureprogress = 0;
    other.dom_captureprogress = self.dom_captureprogress;

	// delay capture

	self.team = self.goalentity.team; // this stores the PREVIOUS team!

	self.cnt = other.team;
	self.owner = head; // team to switch to after the delay
	self.dmg_inflictor = other;

	// self.state = 1;
	// self.delay = time + cvar("g_domination_point_capturetime");
	//self.nextthink = time + cvar("g_domination_point_capturetime");
	//self.think = dompoint_captured;

	// go to neutral team in the mean time
	head = find(world, classname, "dom_team");
	while (head && head.netname != "")
		head = find(head, classname, "dom_team");
	if(head == world)
		return;

    /*
	WaypointSprite_UpdateSprites(self.sprite, "dom-neut", "", "");
	WaypointSprite_UpdateTeamRadar(self.sprite, RADARICON_DOMPOINT, '0 1 1');
	WaypointSprite_Ping(self.sprite);
    */

	self.goalentity = head;
	self.model = head.mdl;
	self.modelindex = head.dmg;
	self.skin = head.skin;

	self.enemy = other; // individual player scoring
	self.enemy_playerid = other.playerid;
	dompoint_captured();
};

float domination_PlayerPreThink()
{
	DEPENDON_F(g_domination, 0)
	
	if(time - self.pointupdatetime >= 0.01)
		self.dom_captureprogress = bound(0, self.dom_captureprogress - frametime * cvar("g_domination_capture_clearspeed"), 1);
	
	return 1;
}

/*QUAKED spawnfunc_dom_team (0 .5 .8) (-32 -32 -24) (32 32 32)
Team declaration for Domination gameplay, this allows you to decide what team
names and control point models are used in your map.

Note: If you use spawnfunc_dom_team entities you must define at least 3 and only two
can have netname set!  The nameless team owns all control points at start.

Keys:
"netname"
 Name of the team (for example Red Team, Blue Team, Green Team, Yellow Team, Life, Death, etc)
"cnt"
 Scoreboard color of the team (for example 4 is red and 13 is blue)
"model"
 Model to use for control points owned by this team (for example
 "progs/b_g_key.mdl" is a gold keycard, and "progs/b_s_key.mdl" is a silver
 keycard)
"skin"
 Skin of the model to use (for team skins on a single model)
"noise"
 Sound to play when this team captures a point.
 (this is a localized sound, like a small alarm or other effect)
"noise1"
 Narrator speech to play when this team captures a point.
 (this is a global sound, like "Red team has captured a control point")
*/

void spawnfunc_dom_team()
{
	if(!g_domination || cvar("g_domination_teams_override") >= 2)
	{
		remove(self);
		return;
	}
	precache_model(self.model);
	if (self.noise != "")
		precache_sound(self.noise);
	if (self.noise1 != "")
		precache_sound(self.noise1);
	self.classname = "dom_team";
	setmodel(self, self.model); // precision not needed
	self.mdl = self.model;
	self.dmg = self.modelindex;
	self.model = "";
	self.modelindex = 0;
	// this would have to be changed if used in quakeworld
	if(self.cnt)
		self.team = self.cnt + 1; // WHY are these different anyway?
};

void dom_controlpoint_setup()
{
	local entity head;
	// find the spawnfunc_dom_team representing unclaimed points
	head = find(world, classname, "dom_team");
	while(head && head.netname != "")
		head = find(head, classname, "dom_team");
	if (!head)
		objerror("no spawnfunc_dom_team with netname \"\" found\n");

	// copy important properties from spawnfunc_dom_team entity
	self.goalentity = head;
	setmodel(self, head.mdl); // precision already set
	self.skin = head.skin;
	self.enemy = world;
	
	self.cnt = -1;

	if(!self.message)
		self.message = " has captured a control point";

	if(!self.DOMPOINTFRAGS)
		self.DOMPOINTFRAGS = 1;
	if(!self.wait)
		self.wait = 5;

	if(!self.t_width)
		self.t_width = 0.02; // frame animation rate
	if(!self.t_length)
		self.t_length = 239; // maximum frame

	self.think = dompointthink;
	self.nextthink = time;
	self.touch = dompointtouch;
	self.solid = SOLID_TRIGGER;
	self.flags = FL_ITEM;
	setsize(self, '-32 -32 -32', '32 32 32');
	//setorigin(self, self.origin + '0 0 20');
	droptofloor();

    if(self.sprite)
        WaypointSprite_UpdateTextColors(self.sprite, '0 1 1', '0 0 0', '0 0 0');

    dom_recountpoints();
};



// player has joined game, get him on a team
// depreciated
/*void dom_player_join_team(entity pl)
{
	entity head;
	float c1, c2, c3, c4, totalteams, smallestteam, smallestteam_count, selectedteam;
	float balance_teams, force_balance, balance_type;

	balance_teams = cvar("g_balance_teams");
	balance_teams = cvar("g_balance_teams_force");

	c1 = c2 = c3 = c4 = -1;
	totalteams = 0;

	// first find out what teams are allowed
	head = find(world, classname, "dom_team");
	while(head)
	{
		if(head.netname != "")
		{
			//if(head.team == pl.team)
			//	selected = head;
			if(head.team == COLOR_TEAM1)
			{
					c1 = 0;
			}
			if(head.team == COLOR_TEAM2)
			{
					c2 = 0;
			}
			if(head.team == COLOR_TEAM3)
			{
					c3 = 0;
			}
			if(head.team == COLOR_TEAM4)
			{
					c4 = 0;
			}
		}
		head = find(head, classname, "dom_team");
	}

	// make sure there are at least 2 teams to join
	if(c1 >= 0)
		totalteams = totalteams + 1;
	if(c2 >= 0)
		totalteams = totalteams + 1;
	if(c3 >= 0)
		totalteams = totalteams + 1;
	if(c4 >= 0)
		totalteams = totalteams + 1;

	if(totalteams <= 1)
		error("dom_player_join_team: Too few teams available for domination\n");

	// whichever teams that are available are set to 0 instead of -1

	// if we don't care what team he ends up on, put him on whatever team he entered as.
	// if he's not on a valid team, then put him on the smallest team
	if(!balance_teams && !force_balance)
	{
		if(     c1 >= 0 && pl.team == COLOR_TEAM1)
			selectedteam = pl.team;
		else if(c2 >= 0 && pl.team == COLOR_TEAM2)
			selectedteam = pl.team;
		else if(c3 >= 0 && pl.team == COLOR_TEAM3)
			selectedteam = pl.team;
		else if(c4 >= 0 && pl.team == COLOR_TEAM4)
			selectedteam = pl.team;
		else
			selectedteam = -1;
		if(selectedteam > 0)
		{
			SetPlayerColors(pl, selectedteam - 1);
			return;
		}
		// otherwise end up on the smallest team (handled below)
	}

	// now count how many players are on each team already

	head = find(world, classname, "player");
	while(head)
	{
		//if(head.netname != "")
		{
			if(head.team == COLOR_TEAM1)
			{
				if(c1 >= 0)
					c1 = c1 + 1;
			}
			if(head.team == COLOR_TEAM2)
			{
				if(c2 >= 0)
					c2 = c2 + 1;
			}
			if(head.team == COLOR_TEAM3)
			{
				if(c3 >= 0)
					c3 = c3 + 1;
			}
			if(head.team == COLOR_TEAM4)
			{
				if(c4 >= 0)
					c4 = c4 + 1;
			}
		}
		head = find(head, classname, "player");
	}

	// c1...c4 now have counts of each team
	// figure out which is smallest, giving priority to the team the player is already on as a tie-breaker

	smallestteam = 0;
	smallestteam_count = 999;

	// 2 gives priority to what team you're already on, 1 goes in order
	balance_type = 1;

	if(balance_type == 1)
	{
		if(c1 >= 0 && c1 < smallestteam_count)
		{
			smallestteam = 1;
			smallestteam_count = c1;
		}
		if(c2 >= 0 && c2 < smallestteam_count)
		{
			smallestteam = 2;
			smallestteam_count = c2;
		}
		if(c3 >= 0 && c3 < smallestteam_count)
		{
			smallestteam = 3;
			smallestteam_count = c3;
		}
		if(c4 >= 0 && c4 < smallestteam_count)
		{
			smallestteam = 4;
			smallestteam_count = c4;
		}
	}
	else
	{
		if(c1 >= 0 && (c1 < smallestteam_count ||
					(c1 == smallestteam_count && self.team == COLOR_TEAM1) ) )
		{
			smallestteam = 1;
			smallestteam_count = c1;
		}
		if(c2 >= 0 && c2 < (c2 < smallestteam_count ||
					(c2 == smallestteam_count && self.team == COLOR_TEAM2) ) )
		{
			smallestteam = 2;
			smallestteam_count = c2;
		}
		if(c3 >= 0 && c3 < (c3 < smallestteam_count ||
					(c3 == smallestteam_count && self.team == COLOR_TEAM3) ) )
		{
			smallestteam = 3;
			smallestteam_count = c3;
		}
		if(c4 >= 0 && c4 < (c4 < smallestteam_count ||
					(c4 == smallestteam_count && self.team == COLOR_TEAM4) ) )
		{
			smallestteam = 4;
			smallestteam_count = c4;
		}
	}

	if(smallestteam == 1)
	{
		selectedteam = COLOR_TEAM1 - 1;
	}
	if(smallestteam == 2)
	{
		selectedteam = COLOR_TEAM2 - 1;
	}
	if(smallestteam == 3)
	{
		selectedteam = COLOR_TEAM3 - 1;
	}
	if(smallestteam == 4)
	{
		selectedteam = COLOR_TEAM4 - 1;
	}

	SetPlayerColors(pl, selectedteam);
}
*/
/*QUAKED spawnfunc_dom_controlpoint (0 .5 .8) (-16 -16 -24) (16 16 32)
Control point for Domination gameplay.
*/
void spawnfunc_dom_controlpoint()
{
	if(!g_domination)
	{
		remove(self);
		return;
	}
	self.think = dom_controlpoint_setup;
	self.nextthink = time + 0.1;
	self.reset = dom_controlpoint_setup;

	if(!self.scale)
		self.scale = 1.0; //0.6;

	//if(!self.glow_size)
	//	self.glow_size = cvar("g_domination_point_glow");
	self.effects = self.effects | EF_LOWPRECISION;
	if (cvar("g_domination_point_fullbright"))
		self.effects |= EF_FULLBRIGHT;
};

// code from here on is just to support maps that don't have control point and team entities
void dom_spawnteam (string teamname, float teamcolor, string pointmodel, float pointskin, string capsound, string capnarration, string capmessage)
{
	local entity oldself;
	oldself = self;
	self = spawn();
	self.classname = "dom_team";
	self.netname = teamname;
	self.cnt = teamcolor;
	self.model = pointmodel;
	self.skin = pointskin;
	self.noise = capsound;
	self.noise1 = capnarration;
	self.message = capmessage;

	// this code is identical to spawnfunc_dom_team
	setmodel(self, self.model); // precision not needed
	self.mdl = self.model;
	self.dmg = self.modelindex;
	self.model = "";
	self.modelindex = 0;
	// this would have to be changed if used in quakeworld
	self.team = self.cnt + 1;

	//eprint(self);
	self = oldself;
};

void dom_spawnpoint(vector org)
{
	entity oldself;
	oldself = self;
	self = spawn();
	self.classname = "dom_controlpoint";
	setorigin(self, org + '0 0 1' * (1 - self.mins_z + 24));
	spawnfunc_dom_controlpoint();
	self = oldself;
};

// spawn some default teams if the map is not set up for domination
void dom_spawnteams()
{
	float numteams;
	/*
	if(cvar("g_domination_teams_override") < 2)
		numteams = cvar("g_domination_default_teams");
	else
		numteams = cvar("g_domination_teams_override");
	*/
	
	numteams = 2;
	
	// LordHavoc: edit this if you want to change defaults
	dom_spawnteam("Red", COLOR_TEAM1-1, "models/domination/dom_red_baseless.md3", 0, "domination/claim.wav", "", "Red team has captured a control point");
	dom_spawnteam("Blue", COLOR_TEAM2-1, "models/domination/dom_blue_baseless.md3", 0, "domination/claim.wav", "", "Blue team has captured a control point");
	if(numteams > 2)
		dom_spawnteam("Yellow", COLOR_TEAM3-1, "models/domination/dom_yellow_baseless.md3", 0, "domination/claim.wav", "", "Yellow team has captured a control point");
	if(numteams > 3)
		dom_spawnteam("Pink", COLOR_TEAM4-1, "models/domination/dom_pink_baseless.md3", 0, "domination/claim.wav", "", "Pink team has captured a control point");
	dom_spawnteam("", 0, "models/domination/dom_unclaimed_baseless.md3", 0, "", "", "");
};

float dom_spawnpointsfor(string clname)
{
	entity head;
	float i;
	
	for(head = world; (head = find(head, classname, clname));) {
		bprint("^5Domination: ^7found a ", head.classname, " at ", vtos(head.origin), "\n");
		dom_spawnpoint(head.origin);
		++i;
	}
	
	bprint("^5Domination:^7 spawned ", ftos(i), " controlpoints for ^6", clname, "\n");
	return i;
}

.float dom_used;
float dom_spawnextrapoints(float numpts, float minpts) {
    entity head, phead, pt;
    float i, maxdst, mindst, dst;
    
    if(numpts >= minpts)
        return 0;
    
    while(i < minpts-numpts) {
        maxdst = 0;
        for(head = world; (head = find(head, classname, "info_player_deathmatch"));) {
            mindst = 0;
            for(phead = world; (phead = find(phead, classname, "dom_controlpoint"));) {
                dst = vlen(phead.origin - head.origin);
                if(!mindst || dst < mindst)
                    mindst = dst;
            }
            
            if(mindst >= maxdst) {
                maxdst = mindst;
                pt = head;
            }
        }
        
        if(!pt) {
            print("Spawning of extra domination points aborted!\n");
            return i;
        }
        
        dom_spawnpoint(pt.origin);
        ++i;
    }
    
    return i;
}

void dom_removeall(string clname)
{
	local entity head;
	head = find(world, classname, "");
	
	for(head = world; (head = find(head, classname, clname));)
	{
		bprint("^5Domination: ^7removed a ", head.classname, " at ", vtos(head.origin), "\n");
		remove(head);
	}
}

void dom_cp_placeholder()
{
	local entity oldself = self;
	
	self = spawn();
	self.classname = "dom_cp_placeholder";
	self.origin = oldself.origin;
	setorigin(self, oldself.origin);
	
	bprint("^5Domination: ^7spawned a dom_cp_placeholder at ", vtos(self.origin), "\n");
}

void dom_delayedinit()
{
	// if no teams are found, spawn defaults, if custom teams are set, use them
	//if (find(world, classname, "dom_team") == world || cvar("g_domination_teams_override") >= 2)
	
	dom_removeall("dom_team");
	dom_spawnteams();

	local float i, j, n;
	i = 0;
	
	if(find(world, classname, "dom_controlpoint") == world)
	{
		//dom_removeall("dom_controlpoint");
		
		n = tokenizebyseparator(cvar_string("g_domination_spawnpoints"), " ");
		for(j = 0; j < n; ++j)
			i += dom_spawnpointsfor(argv(j));
		
        i += dom_spawnextrapoints(i, cvar("g_domination_spawnpoints_min"));
        
		n = tokenizebyseparator(cvar_string("g_domination_removeitems"), " ");
		for(j = 0; j < n; ++j)
			dom_removeall(argv(j));
        
		bprint("^5Domination:^7 spawned ", ftos(i), " controlpoints\n");
	}
	else
	{
		bprint("^5Domination:^7 map already contains contolpoints, spawning nothing\n");
		
		n = tokenizebyseparator(cvar_string("g_domination_removeitems"), " ");
		for(j = 0; j < n; ++j)
			dom_removeall(argv(j));
	}
	
	dom_recountpoints();
	ScoreRules_dom();
};

void totaldom_init()
{
	if(inWarmupStage)
		warmup = time;
	else
		warmup = time + cvar("g_start_delay");
	
	precache_sound("ctf/red_capture.wav");
    precache_sound("ctf/blue_capture.wav");
}

void dom_init()
{
	// we have to precache default models/sounds even if they might not be
	// used because spawnfunc_worldspawn is executed before any other entities are read,
	// so we don't even know yet if this map is set up for domination...
	precache_model("models/domination/dom_red_baseless.md3");
	precache_model("models/domination/dom_blue_baseless.md3");
	precache_model("models/domination/dom_yellow_baseless.md3");
	precache_model("models/domination/dom_pink_baseless.md3");
	precache_model("models/domination/dom_unclaimed_baseless.md3");
	precache_sound("domination/claim.wav");
	InitializeEntity(world, dom_delayedinit, INITPRIO_GAMETYPE);

	// teamplay is always on in domination, defaults to hurt self but not teammates
	//if(!teams_matter)
	//	cvar_set("teamplay", "3");
	
    dom_recountpoints();
	if(g_totaldomination)
		totaldom_init();
};
