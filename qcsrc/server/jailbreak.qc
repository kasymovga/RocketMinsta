
//
//	Initialization
//

void JB_Init() {
	if(inWarmupStage)
		warmup = time;
	else
		warmup = time + cvar("g_start_delay");
	
	precache_sound("ctf/red_capture.wav");
	precache_sound("ctf/blue_capture.wav");
	precache_sound("kh/alarm.wav");
	precache_sound("jailbreak/jb_red.wav");
	precache_sound("jailbreak/jb_blue.wav");
	precache_sound("jailbreak/imprison.wav");
	
	ScoreRules_JB();
	JB_Torture_RegisterAll();
	
	entity e = spawn();
	e.classname = "jailbreak_logic";
	e.think = JB_Frame;
    e.teamswap = JB_TeamSwap;
	e.nextthink = time;
    
    g_jailbreak_claim = cvar("g_jailbreak_controlpoint_claim");
    
    addstat(STAT_REDALIVE, AS_INT, redalive_stat);
    addstat(STAT_BLUEALIVE, AS_INT, bluealive_stat);
    addstat(STAT_CAPTURE_PROGRESS, AS_FLOAT, jb_unlock_progress);
    addstat(STAT_PRISONED, AS_INT, jb_isprisoned);
    addstat(STAT_ROUNDLOST, AS_INT, jb_roundlost);
    addstat(STAT_JBMSG, AS_INT, jb_message);
    
    g_jailbreak_jail_deathmatch = cvar("g_jailbreak_jail_deathmatch");
    InitializeEntity(world, JB_DelayedInit, INITPRIO_GAMETYPE);
}

void JB_Log(string s) {
	print(strcat("Jailbreak: ", s, "\n"));
}

void JB_BLog(string s) {
	bprint(strcat("Jailbreak: ", s, "\n"));
}

void JB_AddDoor(entity door, float theteam, vector vdata, string sdata, entity cpoint) {
    if(door.classname != "door" && door.classname != "door_rotating") {
        JB_BLog(strcat("Warning: ^3", JB_ControlPoint_Name(cpoint), "^7 at ", vtos(cpoint.origin), " is linked with an entity of unhandled class (^3", door.classname, "^7)!"));
        return;
    }
    
    if(!JB_FIRSTDOOR(theteam))
        JB_SETFIRSTDOOR(theteam, door);
    
    if(JB_LASTDOOR(theteam))
        JB_NEXTDOOR(JB_LASTDOOR(theteam)) = door;
    
    JB_SETLASTDOOR(theteam, door);
}

void JB_DelayedInit() {
    entity e;
    
    SUB_ForEachTarget_Init();
    FOR_EACH_JB_CONTROLPOINT(e)
        SUB_ForEachTarget(e, JB_AddDoor, TRUE, e.jb_team_initial, '0 0 0', string_null, e);
}

float jb_doors_opened[2];
void JB_MaybeOpenDoor(entity door, float openjails, vector vdata, string sdata, entity cpoint) {
    if(openjails == OPENJAILS_LOCKED && door.jaildoormode != JAILDOORMODE_OPEN)
        return;
    
    if(openjails == OPENJAILS_OPEN && door.jaildoormode == JAILDOORMODE_CLOSED)
        return;
    
    // OPENJAILS_LOCKED_FORCE is handled in JB_NonJBInit
    // For OPENJAILS_OPEN_FORCE, the below is always executed
    
    entity oldself = self;
    self = door;
    float opened = TRUE;
    
    switch(door.classname) {
        case "door":
            door_init_startopen();
            break;
        
        case "door_rotating":
            door_rotating_init_startopen();
            InitMovingBrushTrigger();
            break;
        
        default:
            JB_BLog(strcat("Warning: ^3", JB_ControlPoint_Name(cpoint), "^7 at ", vtos(cpoint.origin), " is linked with an entity of unhandled class (^3", door.classname, "^7)!"));
            opened = FALSE;
            break;
    }
    
    self = oldself;
    
    if(opened) {
        float idx = Team_Index(cpoint.team);
        jb_doors_opened[idx] = jb_doors_opened[idx] + 1;
    }
}

// This is called for non-jailbreak modes only, to alter jb-specific entities on the map
void JB_NonJBInit() {
    entity e;
    float openjails = cvar("g_jailbreak_nonjb_openjails");
    
    SUB_ForEachTarget_Init();
    FOR_EACH_JB_CONTROLPOINT(e) if(e.team != JB_TEAM_NEUTRAL) {
        if(openjails != OPENJAILS_LOCKED_FORCE)
            SUB_ForEachTarget(e, JB_MaybeOpenDoor, TRUE, openjails, '0 0 0', string_null, e);
        e.think = SUB_Remove;
        e.nextthink = time;
    }
    
    // If all jail doors are locked, it means that the jail is not intended to be accessible.
    // We have to keep the jail sectors then to ensure it's not possible to get in with translocator (or something more evil to be added in the future).
    // Otherwise, they have to be removed. TODO: do something about maps with multiple jails (if we ever get any).
    
    for(e = findchain(classname, "jailbreak_jail"); e; e = e.chain) {
        float idx = Team_Index(e.team);
        if(!g_nadgets || jb_doors_opened[idx]) {
            e.think = SUB_Remove;
            e.nextthink = time;
        }
    }
}

//
//	Gametype logic
//

void JB_Frame() {
    float redsout, bluesout;
    
    if(jb_recount) {
        TeamCount_RecountPlayers(JB_AliveCheck);
        jb_recount = FALSE;
    }
    
    self.nextthink = time;
    DEPENDON(JB_GAME_ACTIVE)
    
    if(gameover)
        return;
    
    if(JB_TotalPlayersOnTeam(COLOR_TEAM1) < 1)
        return;
        
    if(JB_TotalPlayersOnTeam(COLOR_TEAM2) < 1)
        return;
    
    redsout  = !(JB_AlivePlayersOnTeam(COLOR_TEAM1) || JB_JailIsOpen(COLOR_TEAM2));
    bluesout = !(JB_AlivePlayersOnTeam(COLOR_TEAM2) || JB_JailIsOpen(COLOR_TEAM1));
    
    if(redsout && bluesout)
        JB_TeamWins(0);
    else if(redsout)
        JB_TeamWins(COLOR_TEAM2);
    else if(bluesout)
        JB_TeamWins(COLOR_TEAM1);
}

void JB_TeamSwap() {
    entity of = jb_door_red_first;
    entity ol = jb_door_red_last;
    jb_door_red_first = jb_door_blue_first;
    jb_door_red_last = jb_door_blue_last;
    jb_door_blue_first = of;
    jb_door_blue_last = ol;
}

float JB_JailIsOpen(float theteam) {
    entity e;
    FOR_EACH_JB_DOOR(e, theteam) if(e.state != STATE_BOTTOM)
        return TRUE;
    return FALSE;
}

void JB_TeleportToJail(entity p) {
    if(p.jb_specteam)
        return;
    
    vector a;
    float et = JB_GetEnemyTeamOf(p.team);
    entity spot = JB_ChooseJailSpawnpoint(et);
    
    float tries;
    tries = 3;
    
    while(!spot && tries) {
        spot = JB_ChooseJailSpawnpoint(et);
        tries--;
    }
    
    if(!spot) {
        JB_BLog(strcat("Failed to pick a jail spawnpoint for ", self.netname, "^7, cannot imprison!"));
        return;
    }
    
    a = spot.angles;
    a_z = 0;
    TeleportPlayer_NextFrame(spot, self, spot.origin, a, '0 0 0', '0 0 0', '0 0 0');
}

void JB_Imprison(entity attacker) {
	if(self.jb_isprisoned) {
		JB_Log(strcat("Tried to imprison a prisoned player (", self.netname, ")"));
		return;
	}
	
    self.health = cvar("g_jailbreak_prisoner_health");
	self.armorvalue = cvar("g_jailbreak_prisoner_armor");
	
    
    self.jb_had_unlimited_ammo = (self.items & IT_UNLIMITED_WEAPON_AMMO);
    
    if(!self.jb_had_unlimited_ammo)
        self.items |= IT_UNLIMITED_WEAPON_AMMO;
        
	self.jb_fragrow = 0;
	
	if(attacker.classname == "player")
	if(attacker.team != self.team) {
		attacker.jb_fragrow += 1;
		
		if(cvar("g_jailbreak_frag_bonusgrenade"))
		if(attacker.jb_fragrow >= cvar("g_jailbreak_frag_bonusgrenade_requirement")) {
			HG_GiveBonus(attacker, HG_NameToType(cvar_string("g_jailbreak_frag_bonusgrenade_type")), 1,
								   strcat(ftos(attacker.jb_fragrow), " frags in a row")
			);
			attacker.jb_fragrow = 0;
		}
	}
	
	JB_Log(strcat("Imprisoning ", self.netname, "^7, attacker: ", etos(attacker), " with netname: ", attacker.netname));
	JB_TeleportToJail(self);
    
	self.jb_isprisoned = TRUE;
	self.jb_prisontime = time;
    self.jb_jaildm_aggressive = FALSE;
    
    if(!self.jb_specteam) {
        announce(self, "jailbreak/imprison.wav");
        bigprint_spec(self, "You're in a jail, prisoner!", ((attacker && attacker != self)? strcat("You've been imprisoned by ^3", attacker.netname) : ""), 10);
        
        if(g_nadgets) {
            if(!cvar("g_nadgets_regen_time"))
                self.hg_ammo = 0;
            self.hg_bonus = 0;
        }
    }
    
	PlayerScore_Set(self, SP_FROZENSTATUS, 1);
	JB_CountPlayers();
}

float JB_AliveCheck(entity p) {
    return !p.jb_isprisoned;
}

void JB_TorturePrisonersLater_Think() {
	JB_TorturePrisoners(self.team);
	remove(self);
}

void JB_TorturePrisonersLater(float theteam, float thedelay) {
	entity e = spawn();
	e.team = theteam;
	e.think = JB_TorturePrisonersLater_Think;
	e.nextthink = time + thedelay;
}

void JB_Release(entity saviour) {
	if(!self.jb_isprisoned) {
		JB_Log(strcat("Tried to release a free player (", self.netname, ")"));
		return;
	}
	
	self.jb_isprisoned = FALSE;
    
    if(!self.jb_had_unlimited_ammo)
        self.items &~= IT_UNLIMITED_WEAPON_AMMO;
    
    if(g_jailbreak_jail_deathmatch) {
        self.health = max(self.health, cvar("g_jailbreak_prisoner_health"));
        self.armorvalue = max(self.armorvalue, cvar("g_jailbreak_prisoner_armor"));
    }
    
	if(g_nadgets)
    if(!cvar("g_nadgets_regen_time"))
		HG_PlayerSpawn();
	
	PlayerScore_Set(self, SP_FROZENSTATUS, 0);
	JB_CountPlayers();
}

void JB_TeamWins(float theteam) {
	string teamname, teamname_full;
    entity e;
    
    if(!theteam) {
        FOR_EACH_PLAYER(e)
            bigprint_spec(e, "Round Draw!", "", 5);
        JB_EndRound(5);
        return;
    }
    
	switch(theteam) {
		case COLOR_TEAM1:	teamname = "^1Red";		play2all("ctf/red_capture.wav");	break;
		case COLOR_TEAM2:	teamname = "^4Blue";	play2all("ctf/blue_capture.wav");	break;
	}
	
	teamname_full = ColoredTeamName(theteam);
	
	FOR_EACH_PLAYER(e) {
		bigprint_spec(e, strcat(teamname, "^7 Scores!"), "All opponents are imprisoned", JB_TORTURE_DURATION);
		
		if(e.team == theteam)
			hudflash_teamcolor_default_spec(e);
	}
	
	bprint(teamname_full, "^5 wins the round since all their opponents are in a jail\n");
	TeamScore_AddToTeam(theteam, ST_SCORE, +1);
	
	JB_ActivateCamera(theteam, JB_TORTURE_DURATION);
	JB_TorturePrisonersLater(theteam, 3);
	JB_EndRound(JB_TORTURE_DURATION);
}

void JB_CountPlayers() {
    //TeamCount_RecountPlayers(JB_AliveCheck);
    jb_recount = TRUE;
}

void JB_HandleProjectile(entity proj) {
	DEPENDON(g_jailbreak)
	
	if(proj.owner.classname == "player" || proj.owner.classname == "corpse") {
		if(proj.owner.jb_isprisoned)
			proj.jb_proj_ownerstate = JB_PROJ_OWNERSTATE_IMPRISONED;
		else
			proj.jb_proj_ownerstate = JB_PROJ_OWNERSTATE_FREE;
	}
}

//
//	Torture logic
//

var jb_torture_logic jb_torture_logic1;
var jb_torture_logic jb_torture_logic2;

#define JITTER(v,j) (v) + (j) * 2 * (random() - 0.5)

jb_torture_logic JB_Torture_PickFunction() {
	/*
	entity e;
	
	RandomSelection_Init();
	for(;(e = find(e, classname, "jailbreak_torture_logic"));)
		RandomSelection_Add(e, 0, string_null, 1, 1);
	return RandomSelection_chosen_ent.use;
	*/
	
	return ((random() < 0.5)? jb_torture_logic1 : jb_torture_logic2);
}

void JB_TorturePrisoners(float theteam) {
	entity spot, logic;
	
	//	Here we will choose two random torture logics to run at the same time
	RandomSelection_Init();
	for(;(logic = find(logic, classname, "jailbreak_torture_logic"));)
		RandomSelection_Add(logic, 0, string_null, 1, 1);
	jb_torture_logic1 = RandomSelection_chosen_ent.use;
	RandomSelection_Init();
	for(;(logic = find(logic, classname, "jailbreak_torture_logic"));)
		if(logic.use != jb_torture_logic1)
			RandomSelection_Add(logic, 0, string_null, 1, 1);
	jb_torture_logic2 = RandomSelection_chosen_ent.use;
	
	for(;(spot = find(spot, classname, "info_jailbreak_torturespawn"));)
		if(spot.team == theteam)
			JB_Torture_Start(spot);
}

void JB_Torture_Think() {
	if(gameover) {
		remove(self);
		return;
	}
	
	makevectors(self.angles);
	//self.nextthink = time + JITTER(self.jb_torture_delay, self.jb_torture_delay_jitter);
	
	float j = self.jb_torture_delay - JITTER(self.jb_torture_delay, self.jb_torture_delay_jitter);
	
	if(j > 0)
		j = 0.5 * j;
	
	self.nextthink = time + max(0.1, self.jb_torture_delay + j);
	self.jb_torture_suggestedforce = JITTER(self.jb_torture_force, self.jb_torture_force_jitter);
	
	var jb_torture_logic logic;
	logic = JB_Torture_PickFunction();
	
	if(!logic) {
		JB_Log("Failed to pick torture logic!");
		//remove(self);
		return;
	}
	
	logic();
}

void JB_Torture_Start(entity spot) {
	entity e = spawn();
	e.classname = "jailbreak_torture";
	e.reset = SUB_Remove;
	e.reset2 = e.reset;
	e.think = JB_Torture_Think;
	e.angles = spot.angles;
	e.jb_torture_delay = spot.jb_torture_delay;
	e.jb_torture_delay_jitter = spot.jb_torture_delay_jitter;
	e.jb_torture_force = spot.jb_torture_force;
	e.jb_torture_force_jitter = spot.jb_torture_force_jitter;
	e.owner = spot;
	e.team = e.owner.team;
	setorigin(e, spot.origin);
	e.nextthink = time + JITTER(0, e.jb_torture_delay_jitter);
}

void JB_Torture_Register(jb_torture_logic logic) {
	entity e = spawn();
	e.classname = "jailbreak_torture_logic";
	e.use = logic;
}

void JB_Torture_Napalm_Touch() {
	self.cnt -= 1;
	
	if(!self.cnt)
		remove(self);
	
	W_Firemine_Touch();
}

void JB_Torture_Napalm() {
	local entity proj;
	local vector kick;

	proj = spawn ();
	proj.owner = self;
	proj.classname = "jb_torture_napalm";
	proj.movetype = MOVETYPE_BOUNCE;
	proj.projectiledeathtype = DEATH_HG_NAPALM;
	proj.touch = JB_Torture_Napalm_Touch;
	PROJECTILE_MAKETRIGGER(proj);
	setsize (proj, '0 0 0', '0 0 0');
	setorigin (proj, self.origin);
	proj.org_explosion = self.origin;
	proj.think = HG_Napalm_Think;
	proj.nextthink = time;
	proj.damageforcescale = 1;
	proj.cnt = 3; //	max bounces
	kick_z = self.jb_torture_suggestedforce;
	kick_x = (random () - 0.5) * 2 * kick_z;
	kick_y = (random () - 0.5) * 2 * kick_z;
	proj.velocity = kick;
	proj.pushltime = time + 3;
	W_SetupProjectileVelocity(proj);

	proj.angles = vectoangles(proj.velocity);
	proj.flags = FL_PROJECTILE;

	CSQCProjectile(proj, TRUE, PROJECTILE_FIREMINE, TRUE);
}

void JB_Torture_Plasma() {
	float i, j;
	
	vector oldangles = self.angles;
	for(i = 0; i < 2; ++i) {
		self.angles_y -= 30 * random();
		self.angles_x += JITTER(0, 20);
		self.angles_z += JITTER(0, 20);
		
		if(i)
			W_Electro_Attack2();
		else
			W_Electro_Attack();
		
		for(j = 0; j < 2; ++j) {
			if(random() < 0.5) {
				self.angles = oldangles;
				self.angles_y += JITTER(0, 20);
				self.angles_x += JITTER(0, 25);
				self.angles_z += JITTER(0, 25);
				
				if(random() < 0.5)
					W_Crylink_Attack();
				else
					W_Crylink_Attack2();
			}
		}
		
		self.angles = oldangles;
	}
}

void JB_Torture_Grenade_Explode (void)
{
	self.event_damage = SUB_Null;
	self.takedamage = DAMAGE_NO;
	RadiusDamage (self, self.owner, 100, 100, 250, world, 700, self.projectiledeathtype, other);
	remove (self);
}

void JB_Torture_Grenades() {
	makevectors(self.angles + randomvec() * 30);
	W_SetupShot_ProjectileSize(self, '0 0 -3', '0 0 -3', FALSE, 4, "weapons/grenade_fire.wav", 100);
	w_shotdir = v_forward;
	w_shotorg = self.origin;
	
	pointparticles(particleeffectnum("grenadelauncher_muzzleflash"), w_shotorg, w_shotdir * 1000, 1);
	
	entity gren = spawn();
	gren.owner = self;
	gren.classname = "jb_torture_copypasta_from_g_nadgets";
	gren.bot_dodge = TRUE;
	gren.bot_dodgerating = 300;
	gren.movetype = MOVETYPE_BOUNCE;
	PROJECTILE_MAKETRIGGER(gren);
	gren.projectiledeathtype = WEP_GRENADE_LAUNCHER;
	gren.hg_type = DEATH_HG_NORMAL;		// HG_Grenade_Explode and such use this -- I don't feel like copypasting them too
	setsize(gren, '0 0 -3', '0 0 -3');
	setorigin(gren, w_shotorg);

	gren.nextthink = time + 3;
	gren.think = adaptor_think2use;
	gren.use = JB_Torture_Grenade_Explode; //HG_Grenade_Explode;
	gren.touch = HG_Grenade_Touch;
    gren.cnt = 9001;
	gren.takedamage = DAMAGE_YES;
	gren.health = 1;
	gren.damageforcescale = 4;
	gren.event_damage = W_Grenade_Damage;
	gren.velocity = w_shotdir * self.jb_torture_suggestedforce + v_up * (self.jb_torture_suggestedforce + crandom() * 0.2 * self.jb_torture_suggestedforce);
	W_SetupProjectileVelocity(gren);
	
	gren.angles = vectoangles (gren.velocity);
	gren.flags = FL_PROJECTILE;
	
	CSQCProjectile(gren, TRUE, PROJECTILE_GRENADE_BOUNCING, TRUE);
}

void JB_Torture_Zap_AimAt(vector org, entity targ) {
	vector shotanle = vectoangles(org - targ.origin);
	shotanle_y += 180;
	makevectors(shotanle);
}

void JB_Torture_Zap() {
	entity unlucky_guy, p;

	RandomSelection_Init();
	FOR_EACH_PLAYER(p) if(p.team != self.team) if(p.deadflag == DEAD_NO)
		RandomSelection_Add(p, 0, string_null, 1, 1);
	unlucky_guy = RandomSelection_chosen_ent;
	
	if(!unlucky_guy) {
		// nobody left alive? shoot the corpses / death origins
		RandomSelection_Init();
		FOR_EACH_PLAYER(p) if(p.team != self.team)
			RandomSelection_Add(p, 0, string_null, 1, 1);
		unlucky_guy = RandomSelection_chosen_ent;
	}
	
	// this should not happen, but just in case...
	if(!unlucky_guy)
		return;

	JB_Torture_Zap_AimAt(self.origin, unlucky_guy);
	sound(self, CHAN_WEAPON, "weapons/nexfire.wav", VOL_BASE, ATTN_NORM);
	
	FireRailgunBullet (self.origin, self.origin + v_forward * 1024, 70, 700, 0, 0, 0, 0, WEP_NEX);
	w_shotorg = self.origin;	// needed for the beam to appear correctly
	SendCSQCNexBeamParticle();
	
	// flash and burn the wall
	if (trace_ent.solid == SOLID_BSP && !(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT))
		Damage_DamageInfo(trace_endpos, 200, 0, 0, 700 * v_forward, WEP_NEX, self);
}

void JB_Torture_RegisterAll() {
	JB_Torture_Register(JB_Torture_Napalm);
	JB_Torture_Register(JB_Torture_Plasma);
	JB_Torture_Register(JB_Torture_Grenades);
	JB_Torture_Register(JB_Torture_Zap);
}

#undef JITTER

//
//	Callbacks
//

float JB_PlayerDies(entity frag_attacker) {
	DEPENDON_F(g_jailbreak && JB_GAME_ACTIVE, 0)
	
	if(!self.jb_isprisoned) {
		if(frag_attacker == self || !frag_attacker)
			PlayerScore_Add(self, SP_SCORE, -cvar("g_jailbreak_penalty_death"));
		else if(frag_attacker.classname == "player") {
			if(frag_attacker.team != self.team) {
				PlayerScore_Add(self, SP_SCORE, -cvar("g_jailbreak_penalty_death"));
				PlayerScore_Add(frag_attacker, SP_SCORE, cvar("g_jailbreak_score_imprison"));
                
                float rng = cvar("g_jailbreak_defense_range");
                entity cp;
                if(rng) FOR_EACH_JB_CONTROLPOINT(cp) {
                    if((cp.team == frag_attacker.team) || (cp.team == JB_TEAM_NEUTRAL && cp.jb_active)) {
                        // Rewards control point defense if fragging nearby your team's or neutral cp.
                        // In case of neutral cp, it has to be active (no defense farming in the beginning of the round)
                        if(vlen(cp.origin - self.origin) < rng) {
                            bigprint_spec(frag_attacker, "^5Defense!", "", 2);
                            PlayerScore_Add(frag_attacker, SP_SCORE, cvar("g_jailbreak_score_defense"));
                            PlayerScore_Add(frag_attacker, SP_JB_DEFENSE, 1);
                            break;
                        }
                    }
                }
			}
			else PlayerScore_Add(frag_attacker, SP_SCORE, -cvar("g_jailbreak_penalty_teamkill"));
		}
		
		Boobs_DropAllAndRespawn(frag_force);
		JB_Imprison(frag_attacker);
        AloneWarning(self.team, JB_AliveCheck);
	} else {
		JB_Log(strcat("Prisoned player ", self.netname, " ^7just died. Should this really happen?"));
		PutClientInServer();
	}
	
	return 1;
}

void JB_PlayerSpawn() {
    DEPENDON(g_jailbreak)
    
    self.jb_isprisoned = FALSE;
    PlayerScore_Set(self, SP_FROZENSTATUS, 0);
    
    self.jb_fragrow = 0;
    
    if(jb_activecamera)
        JB_SetCameraWithAngles(self, jb_activecamera, JB_TORTURE_DURATION);
    
    if not(JB_GAME_ACTIVE) {
        if(self.jb_specteam)
            JB_Imprison(world);
        return;
    }
    
    TeamCount_RecountPlayers(JB_AliveCheck);
    if(JB_TotalPlayersOnTeam(self.team) - 1 > 0 || self.jb_specteam) {	// allow to spawn non-prisoned if there are no players on that team
        JB_Imprison(world);
        self.hg_clearammo = 1;
    }
    
    self.jb_roundlost = FALSE;
}

void JB_RemovePlayer() {
	DEPENDON(g_jailbreak)
	
	if(self.jb_isprisoned && !self.jb_specteam)
		JB_Release(world);
	
	self.jb_roundlost = FALSE;
    JB_CountPlayers();
}

.float pointupdatetime;
void JB_PlayerPreThink() {
    DEPENDON(g_jailbreak)
    
    if(self.jb_specteam)
        return;
    
    if(roundstate == ROUNDSTATE_WARMUP) {
        PlayerScore_Set(self, SP_FROZENSTATUS, 0);
        self.jb_isprisoned_prev = 0;
    }
        
    if(!JB_GAME_ACTIVE) {
        self.jb_unlock_progress = 0;
        self.jb_message = JBMSG_NONE;
        return;
    }
    
    if(self.BUTTON_HOOK && !self.BUTTON_JUMP && self.jb_isprisoned)
        if(JB_AlivePlayersOnTeam(self.team))
            if(!JB_JailIsOpen(JB_GetEnemyTeamOf(self.team)))
                JB_JailSpectate();
    
    float ps = min(1, self.jb_isprisoned);
    if(ps != self.jb_isprisoned_prev) {
        if(!ps) {
            bprint(self.netname, "^3 has broken free!\n");
            PlayerScore_Set(self, SP_FROZENSTATUS, 0);
        } else
            PlayerScore_Set(self, SP_FROZENSTATUS, 1);
        self.jb_isprisoned_prev = ps;
    }
    
    if(time - self.pointupdatetime >= 0.01) {
        self.jb_unlock_progress = 0;
        self.jb_message = JBMSG_NONE;
    }
    
    if(time - self.jb_prisontime < 0.5)
        return;
    
    if(self.jb_isprisoned == 1) {
        print("^1BUG: ^7", self.netname, " ^7somehow got out of jail without touching the jail sector! Trying to put him back in.\n");
        JB_TeleportToJail(self);
    } else if(self.jb_isprisoned)
        if(time > self.jb_jail_resettime)
            JB_Release(self.jb_saviour);
}

//
//	Round logic
//

void JB_EndRound_Finalize() {
	jb_roundover = FALSE;
	defer(0.1, JB_CountPlayers);
}

void JB_PrepareNextRound() {
    print("JB: preparing next round\n");
    jb_activecamera = world;
    entity e; FOR_EACH_CLIENT(e) {
        if(clienttype(e) == CLIENTTYPE_REAL)
            JB_ClearCamera(e);
        e.jb_roundlost = FALSE;
    }
    self.endround_think2 = func_null;
}

void JB_EndRound(float t) {
	G_EndRound(t, cvar("g_jailbreak_warmup"), JB_CountPlayers, JB_PrepareNextRound, JB_EndRound_Finalize);
	jb_roundover = TRUE;
	JB_CountPlayers();
}

//
//	Utility functions
//

entity JB_ChooseJailSpawnpoint(float theteam) {
	entity spot;
	
	RandomSelection_Init();
	for(;(spot = find(spot, classname, "info_jailbreak_jailspawn"));) if(spot.team == theteam) {
		RandomSelection_Add(spot, 0, string_null, 1, 1);
	}
	
	spot = RandomSelection_chosen_ent;
	if(!spot)
		JB_Log(strcat("JB_ChooseJailSpawnpoint(", ftos(theteam), ") failed!"));
	
	return spot;
}

float JB_GetEnemyTeamOf(float t) {
	return ((t == COLOR_TEAM1)? COLOR_TEAM2 : COLOR_TEAM1);
}

float JB_TotalPlayersOnTeam(float theteam) {
    float idx = Team_Index(theteam);
    return teamcount_playerstotal[idx];
}

float JB_AlivePlayersOnTeam(float theteam) {
	float idx = Team_Index(theteam);
    return teamcount_playersalive[idx];
}

entity JB_FindCamera(float theteam) {
	RandomSelection_Init();
	
	entity e;
	for(;(e = find(e, classname, "info_jailbreak_jailcamera"));) if(e.team == theteam)
		RandomSelection_Add(e, 0, string_null, 1, 1);
	
	return RandomSelection_chosen_ent;
}

//float SVC_SETVIEWPORT = 5;   
//float SVC_SETVIEWANGLES = 10;

float jb_ce_pvs, jb_ce_trace;

void JB_RestoreCullEntities() {
	cvar_set("sv_cullentities_pvs", ftos(jb_ce_pvs));
	cvar_set("sv_cullentities_trace", ftos(jb_ce_trace));
	remove(self);
}

void JB_ActivateCamera(float theteam, float timeout) {
	entity cam = JB_FindCamera(theteam);
	
	if(!cam) {
		JB_Log(strcat("JB_ActivateCamera: the ", ColoredTeamName(theteam), "^7 has no camera entities, mapper sucks!"));
		return;
	}
	
	jb_ce_pvs = cvar("sv_cullentities_pvs");
	jb_ce_trace = cvar("sv_cullentities_trace");
	
	// without this we won't be able to watch them burn!
	cvar_settemp("sv_cullentities_pvs", "0");
	cvar_settemp("sv_cullentities_trace", "0");
	
	entity e = spawn();
	e.think = JB_RestoreCullEntities;
	e.nextthink = time + timeout;
	
	entity p; FOR_EACH_PLAYER(p) {
		if(clienttype(p) == CLIENTTYPE_REAL) {
			if(p.team == theteam) {
				p.angles = cam.angles;
				p.angles_z = 0;
				p.fixangle = TRUE;
				p.jb_roundlost = FALSE;
			} else p.jb_roundlost = TRUE;
		}
		
		entity s; FOR_EACH_REALCLIENT(s) if(s == p || (s.classname == "spectator" && s.enemy == p))
			JB_SetCamera(s, cam, timeout);
	}
	
	jb_activecamera = cam;
}

//
//	Setup functions
//

void JB_SetupJailSpawnpoint() {
	if not(g_jailbreak) {
		remove(self);
		return;
	}
	
	self.classname = "info_jailbreak_jailspawn";
    self.teamswap = SwapTeams_Generic;
}

void JB_Jail_Touch() {
	//JB_Log(strcat(other.netname, "^7 is in the ", ColoredTeamName(self.team), " ^7jail"));
	
    if(g_nadgets)
    if(other.hg_type == HG_TRANSLOC)
    if(other.classname == "hg_grenade") {
        other.jb_jail_resettime = time + frametime * 5;
        return;
    }
    
    if(!g_jailbreak)
        return;
    
	if(other.classname != "player")
		return;
	
	if not(other.jb_isprisoned) {
		other.velocity = other.velocity * -1.5;
		return;
	}
	
    other.jb_isprisoned = 2;
    
	if(other.team == self.team)
		return;
	
	other.jb_jail_resettime = time + frametime * 5;
}

void JB_SetupJail() {
	self.classname = "jailbreak_jail";
	self.touch = JB_Jail_Touch;
    self.teamswap = SwapTeams_Generic;
	EXACTTRIGGER_INIT;
}

void JB_SetupJailCamera() {
	if not(g_jailbreak) {
		remove(self);
		return;
	}
	
	self.classname = "info_jailbreak_jailcamera";
    self.teamswap = SwapTeams_Generic;
}

void JB_SetupTortureSpawnpoint() {
	if not(g_jailbreak) {
		remove(self);
		return;
	}
	
	self.classname = "info_jailbreak_torturespawn";
    self.teamswap = SwapTeams_Generic;
	
	if(!self.jb_torture_force)
		self.jb_torture_force = 400;
	
	if(!self.jb_torture_force_jitter)
		self.jb_torture_force_jitter = self.jb_torture_force * 0.1;
	
	if(!self.jb_torture_delay)
		self.jb_torture_delay = 2;
	
	if(!self.jb_torture_delay_jitter)
		self.jb_torture_delay_jitter = self.jb_torture_delay * 0.5;
}

.entity sprite;
void AnimateDomPoint();

string JB_ControlPoint_ModelForTeam(float t) {
    switch(t) {
        case COLOR_TEAM1:       return "models/domination/dom_red_baseless.md3";
        case COLOR_TEAM2:       return "models/domination/dom_blue_baseless.md3";
        default:                return "models/domination/dom_yellow_baseless.md3";
    }
}

string JB_ControlPoint_WaypointForTeam(float t) {
    switch(t) {
        case COLOR_TEAM1:       return "dom-red";
        case COLOR_TEAM2:       return "dom-blue";
        default:                return "dom-yellow";
    }
}

float JB_ControlPoint_Cooldown(entity e) {
    float base, pw, f, c;
    
    c = e.jb_capturecount;
    
    if(e.team == JB_TEAM_NEUTRAL) {
        base = cvar("g_jailbreak_controlpoint_idletime_neutral");
        pw   = cvar("g_jailbreak_controlpoint_idletime_neutral_power");
        f    = cvar("g_jailbreak_controlpoint_idletime_neutral_factor");
    } else {
        base = cvar("g_jailbreak_controlpoint_idletime");
        pw   = cvar("g_jailbreak_controlpoint_idletime_power");
        f    = cvar("g_jailbreak_controlpoint_idletime_factor");
    }
    
    return base + pow(c, pw) * f * base;
}

float JB_ControlPoint_InitialCooldown(entity e) {
    return cvar((e.team == JB_TEAM_NEUTRAL)? "g_jailbreak_controlpoint_idletime_neutral_initial" : "g_jailbreak_controlpoint_idletime_initial");
}

void JB_ControlPoint_Activate(entity e) {
    e.jb_active = TRUE;
    e.jb_cooldown = 0;
    //e.jb_cooldown_max = 0;
    setmodel(e, JB_ControlPoint_ModelForTeam(e.team));
    WaypointSprite_UpdateMaxHealth(e.jb_waypoint, 0);
    WaypointSprite_UpdateHealth(e.jb_waypoint, 0);
}

void JB_ControlPoint_Deactivate(entity e, float cooldown) {
    e.jb_cooldown_max = max(e.jb_cooldown_max, cooldown);
    e.jb_cooldown     = max(e.jb_cooldown,     cooldown);
    
    JB_Log(strcat(etos(e), ": ", ftos(e.jb_cooldown), "s cooldown. Team: ", ftos(e.team), ", Caps: ", ftos(e.jb_capturecount)));
    
    if(e.jb_active && e.jb_cooldown > 0) {
        setmodel(e, "models/domination/dom_unclaimed_baseless.md3");
        e.jb_active = FALSE;
    }
}

void JB_ControlPoint_UpdateCooldownProgress(entity e) {
    WaypointSprite_UpdateMaxHealth(e.jb_waypoint, e.jb_cooldown_max);
    WaypointSprite_UpdateHealth(e.jb_waypoint, e.jb_cooldown_max - e.jb_cooldown);
}

void JB_ControlPoint_DefendWaypoint() {
    entity plr;
    float detected;
    float rng;
    
    if(time < self.jb_defendthink_next)
        return;
    
    rng = cvar("g_jailbreak_controlpoint_detect_enemies");
    
    FOR_EACH_PLAYER(plr) if(plr.team != self.team) if(!plr.jb_isprisoned) {
        if(vlen(self.origin - plr.origin) < rng)
        if(checkpvs(self.origin, plr)) {
            detected = TRUE;
            break;
        }
    }
    
    if(detected)
        WaypointSprite_UpdateSprites(self.jb_waypoint, self.jb_waypoint.model1, "DEFEND!", self.jb_waypoint.model3);
    else
        WaypointSprite_UpdateSprites(self.jb_waypoint, self.jb_waypoint.model1, "", self.jb_waypoint.model3);
    
    self.jb_defendthink_next = time + 0.1;
}

void JB_ControlPoint_Think() {
    self.nextthink = time;
    AnimateDomPoint();
    JB_ControlPoint_DefendWaypoint();
    
    if(time < game_starttime || jb_roundover)
        return;
    
    if(self.jb_cooldown) {
        JB_ControlPoint_UpdateCooldownProgress(self);
    } else if(!self.jb_active) {
        JB_ControlPoint_Activate(self);
    }
    
    if(time - self.pointupdatetime >= 0.1) {
        self.jb_unlock_progress = 0;
        self.jb_capturingplayer = world;
    }
    
    self.jb_cooldown = max(0, self.jb_cooldown - frametime);
}

void JB_ControlPoint_SwitchTeam(entity e, float t) {
    e.team = t;
    WaypointSprite_UpdateSprites(e.jb_waypoint, e.jb_waypoint.model1, "", e.jb_waypoint.model3);
    WaypointSprite_UpdateTeamRadar(e.jb_waypoint, RADARICON_FLAG, colormapPaletteColor(e.team - 1, FALSE));
    WaypointSprite_UpdateTextColors(e.jb_waypoint, TeamColor(e.team), e.jb_waypoint.clr2, e.jb_waypoint.clr3);
    e.jb_waypoint.ownerteam = e.team;
    e.jb_waypoint.SendFlags |= 1;
}

void JB_TriggerTeamControlPoints(float t) {
    entity o;
    o = self;
    
    FOR_EACH_JB_CONTROLPOINT(self)
        if(self.jb_team_initial == t)
            SUB_UseTargets_PreventReuse();
    
    FOR_EACH_CLIENT(self) if(self.jb_specteam && self.jb_specteam != t) {
        self.classname = "player";
        PutClientInServer();
    }
    
    self = o;
}

string JB_ControlPoint_Name(entity p) {
    string clr, tm, end;
    
    switch(p.team) {
        case COLOR_TEAM1:   clr = "^1"; tm = "Red"; break;
        case COLOR_TEAM2:   clr = "^4"; tm = "Blue"; break;
        default:            clr = "^3"; tm = "Neutral"; break;
    }
    
    end = strcat(" (Point ", chr2str(str2chr("A", 0) + p.cnt), ")");
    
    if(!p.netname)
        return strcat(clr, tm, " Control Point", end);
    return strcat(clr, strdecolorize(p.netname), end);
}

void JB_ControlPoint_Capture(entity player) {
    entity e;
    float pc;
    
    activator = self;
    
    if(self.team == JB_TEAM_NEUTRAL || g_jailbreak_claim)
        JB_TriggerTeamControlPoints(JB_GetEnemyTeamOf(player.team));
    else SUB_UseTargets();
	
	string teamname, cpname;
	switch(player.team) {
		case COLOR_TEAM1: teamname = "^1REDS"	; break ;
		case COLOR_TEAM2: teamname = "^4BLUES"	; break ;
		default			: teamname = "^6FAGS"	; break ;
	}
    
    cpname = JB_ControlPoint_Name(self);
    
    entity o = self;
    FOR_EACH_CLIENT(self) if(!self.iscreature) if(self.jb_specteam == player.team)
        LeaveSpectatorMode();
    self = o;
    
	FOR_EACH_PLAYER(e) {
		bigprint_spec(e, 	strcat("Jailbreak! The ", teamname, " ^7are escaping!"),
							strcat(cpname, "^7 captured by ^3", player.netname), 5);
		
		if(e.jb_isprisoned && e.team == player.team) {
			bigprint_spec(e, "You're free! Run away!", "", 5);
            pc++;
        }
        
	}
    
    sound(world, CHAN_VOICE, strcat("jailbreak/jb_", ((player.team == COLOR_TEAM1)? "red" : "blue"), ".wav"), VOL_BASEVOICE, ATTN_NONE);
	bprint(player.netname, " ^5has captured the ", cpname, "^5! The ", ColoredTeamName(player.team), " ^5is escaping!\n");
	PlayerScore_Add(player, SP_SCORE, ((self.team == JB_TEAM_NEUTRAL)? cvar("g_jailbreak_score_jbreak_neutralmultiplier") : 1)
                                    * (cvar("g_jailbreak_score_jbreak") + cvar("g_jailbreak_score_jbreak_perplayer") * pc));
	PlayerScore_Add(player, SP_JB_JBREAKS, 1);
    PlayerScore_Add(player, SP_JB_FREED, pc);
	play2all("kh/alarm.wav");
    
    if(cvar("g_jailbreak_controlpoint_claim_noneutral"))
    if(self.team == JB_TEAM_NEUTRAL)
        return;
    
    JB_ControlPoint_SwitchTeam(self, player.team);
}

void JB_ControlPoint_Touch() {
    if(jb_roundover)
        return;
    
    if(other.health < 1)
        return;
        
    if(other.classname != "player")
        return;
    
    if(time - other.hg_stealthtime < cvar("g_nadgets_cloak_actiondelay"))
        return;
    
    other.pointupdatetime = time;
    
    if(other.team == self.team) {
        other.jb_message = JBMSG_WRONGTEAM;
        return;
    }
        
    if(!self.jb_active) {
        other.jb_message = JBMSG_NOTREADY;
        return;
    }
    
    if(self.jb_capturingplayer && self.jb_capturingplayer != other) {
        other.jb_message = JBMSG_TOOLATE;
        return;
    }
    
    if(JB_TotalPlayersOnTeam(other.team) == JB_AlivePlayersOnTeam(other.team)) {
        other.jb_message = JBMSG_ALLALIVE;
        return;
    }
    
    entity cp;
    if(self.team != JB_TEAM_NEUTRAL) FOR_EACH_JB_CONTROLPOINT(cp)
        if(cp.team == JB_TEAM_NEUTRAL) if(cp.jb_unlock_progress) if(cp.jb_capturingplayer.team == other.team) {
            other.jb_message = JBMSG_CAPPINGNEUTRAL;
            break;
        }
    
    if(other.jb_message != JBMSG_CAPPINGNEUTRAL || self.team == JB_TEAM_NEUTRAL) {
        float rate = cvar("g_jailbreak_controlpoint_unlock_speed");
        if(other.hg_shield)
            rate *= cvar("g_nadgets_shield_progressrate");
        
        self.jb_unlock_progress = bound(0, self.jb_unlock_progress + frametime * rate, 1);
    }
	self.pointupdatetime = time;
    self.jb_capturingplayer = other;
	other.jb_unlock_progress = self.jb_unlock_progress;
	
	if(self.jb_unlock_progress >= 1) {
		JB_ControlPoint_Capture(other);
        
        JB_ControlPoint_Deactivate(self, JB_ControlPoint_Cooldown(self));
        entity e; FOR_EACH_JB_CONTROLPOINT(e) if(e != self)
            if(e.team == other.team)
                JB_ControlPoint_Deactivate(e, cvar("g_jailbreak_controlpoint_idletime_global_own"));
            else if(e.team == JB_TEAM_NEUTRAL || e.team == JB_GetEnemyTeamOf(other.team))
                JB_ControlPoint_Deactivate(e, cvar("g_jailbreak_controlpoint_idletime_global"));
                
        self.jb_capturecount += 1;
	}
}

void JB_ControlPoint_Reset() {
    self.jb_capturecount = 0;
    self.jb_active = TRUE;
    self.jb_cooldown = 0;
    self.jb_cooldown_max = 0;
    JB_ControlPoint_Deactivate(self, JB_ControlPoint_InitialCooldown(self));
    WaypointSprite_UpdateMaxHealth(self.jb_waypoint, 0);
    WaypointSprite_UpdateHealth(self.jb_waypoint, 0);
    JB_ControlPoint_SwitchTeam(self, cvar("g_jailbreak_controlpoint_claim_allneutral")? JB_TEAM_NEUTRAL : self.jb_team_initial);
}

void JB_ControlPoint_TeamSwap() {
    if(self.jb_team_initial != JB_TEAM_NEUTRAL)
        self.jb_team_initial = TeamCount_NextTeam(self.jb_team_initial);
}

void JB_SetupControlPoint() {
    if(!jb_cp_first) {
        jb_cp_first = self;
    }
    
    if(jb_cp_last)
        jb_cp_last.jb_cp_next = self;
        
    jb_cp_last = self;
    
	if not(g_jailbreak) {
		// removal is done in JB_NonJBInit
		return;
	}
	
	self.classname = "jailbreak_controlpoint";
    self.jb_team_initial = self.team;
    
    if(cvar("g_jailbreak_controlpoint_claim_allneutral"))
        self.team = JB_TEAM_NEUTRAL;
	
	setmodel(self, JB_ControlPoint_ModelForTeam(self.team));
	self.skin = 0;
	
	if(!self.t_width)
		self.t_width = 0.02; // frame animation rate
	if(!self.t_length)
		self.t_length = 239; // maximum frame
		
	self.think = JB_ControlPoint_Think;
	self.nextthink = time;
	self.touch = JB_ControlPoint_Touch;
	self.solid = SOLID_TRIGGER;
	self.flags = FL_ITEM;
    self.reset = JB_ControlPoint_Reset;
    self.teamswap = JB_ControlPoint_TeamSwap;
    self.jb_capturecount = 0;
    self.jb_active = TRUE;
    self.cnt = jb_cp_num;
    JB_ControlPoint_Deactivate(self, JB_ControlPoint_InitialCooldown(self));
	setsize(self, '-32 -32 -32', '32 32 32');
	setorigin(self, self.origin + '0 0 20');
	droptofloor();
	
	waypoint_spawnforitem_force(self, self.origin);
	self.nearestwaypointtimeout = 0; // activate waypointing again
	self.basewaypoint = self.nearestwaypoint;
	WaypointSprite_SpawnFixed(strcat("Point ", chr2str(str2chr("A", 0) + jb_cp_num)), self.origin + '0 0 37', self, jb_waypoint);
    self.jb_waypoint.ownerteam = self.team;
    self.jb_waypoint.SendFlags |= 1;
	WaypointSprite_UpdateTeamRadar(self.jb_waypoint, RADARICON_FLAG, colormapPaletteColor(self.team - 1, FALSE));
    WaypointSprite_UpdateTextColors(self.jb_waypoint, TeamColor(self.team), '1 0.5 0', '0 0 0');
    WaypointSprite_UpdateSprites(self.jb_waypoint, self.jb_waypoint.model1, self.jb_waypoint.model2, "");
    
    ++jb_cp_num;
}

//
//  Jail-spectating
//

void JB_JailSpectate() {
    self.jb_specteam = self.team;
}

void JB_JailSpec_Proxy_CopyFields(entity to, entity from) {
    entity o = self;
    self = to;
    SpectateCopy(from);
    self = o;
    
    to.jb_isprisoned = from.jb_isprisoned;
    to.velocity = '0 0 0';
    
    if(!to.iscreature) {
        setmodel(to, from.model);
    }
}

void JB_JailSpec_Proxy_Think() {
    player_regen();
    HG_Frame();
    self.nextthink = time;
}

entity JB_JailSpec_CreateProxy() {
    if(!g_jailbreak)
        return world;
    
    entity p = spawn();
    JB_JailSpec_Proxy_CopyFields(p, self);
    p.think = JB_JailSpec_Proxy_Think;
    p.nextthink = time;
    p.owner = self;
    self.jb_jailspec_proxy = p;
    return p;
}

//
//	Spawn functions
//

#define JB_SPAWNFUNC(e,s,t) void spawnfunc_##e() { self.team = t; s(); }

JB_SPAWNFUNC(info_jailbreak_jailspawn_red, JB_SetupJailSpawnpoint, COLOR_TEAM1)
JB_SPAWNFUNC(info_jailbreak_jailspawn_blue, JB_SetupJailSpawnpoint, COLOR_TEAM2)

JB_SPAWNFUNC(func_jailbreak_jail_red, JB_SetupJail, COLOR_TEAM1)
JB_SPAWNFUNC(func_jailbreak_jail_blue, JB_SetupJail, COLOR_TEAM2)

JB_SPAWNFUNC(info_jailbreak_jailcamera_red, JB_SetupJailCamera, COLOR_TEAM1)
JB_SPAWNFUNC(info_jailbreak_jailcamera_blue, JB_SetupJailCamera, COLOR_TEAM2)

JB_SPAWNFUNC(info_jailbreak_torturespawn_red, JB_SetupTortureSpawnpoint, COLOR_TEAM1)
JB_SPAWNFUNC(info_jailbreak_torturespawn_blue, JB_SetupTortureSpawnpoint, COLOR_TEAM2)

JB_SPAWNFUNC(jailbreak_controlpoint_red, JB_SetupControlPoint, COLOR_TEAM1)
JB_SPAWNFUNC(jailbreak_controlpoint_blue, JB_SetupControlPoint, COLOR_TEAM2)
JB_SPAWNFUNC(jailbreak_controlpoint_neutral, JB_SetupControlPoint, JB_TEAM_NEUTRAL)
