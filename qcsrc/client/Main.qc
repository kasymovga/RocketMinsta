// --------------------------------------------------------------------------
// BEGIN REQUIRED CSQC FUNCTIONS
//include "main.qh"

#define DP_CSQC_ENTITY_REMOVE_IS_B0RKED

void cvar_clientsettemp(string cv, string val)
{
	entity e;
	for(e = world; (e = find(e, classname, "saved_cvar_value")); )
		if(e.netname == cv)
			goto saved;
	e = spawn();
	e.classname = "saved_cvar_value";
	e.netname = strzone(cv);
	e.message = strzone(cvar_string(cv));
:saved
	cvar_set(cv, val);
}

void cvar_clientsettemp_restore()
{
	entity e;
	for(e = world; (e = find(e, classname, "saved_cvar_value")); )
			cvar_set(e.netname, e.message);
}

void() menu_show_error =
{
	drawstring('0 200 0', "ERROR - MENU IS VISIBLE BUT NO MENU WAS DEFINED!", '8 8 0', '1 0 0', 1, 0);
};

// CSQC_Init : Called every time the CSQC code is initialized (essentially at map load)
// Useful for precaching things

void() menu_sub_null =
{
};

#ifdef USE_FTE
float __engine_check;
#endif

string forcefog;
void WaypointSprite_Load();
void CSQC_Init(void)
{
#ifdef USE_FTE
#pragma target ID
	__engine_check = checkextension("DP_SV_WRITEPICTURE");
	if(!__engine_check)
	{
		print("^3Your engine build is outdated\n^3This Server uses a newer QC VM. Please update!\n");
		localcmd("\ndisconnect\n");
		return;
	}
#pragma target FTE
#endif
	
	check_unacceptable_compiler_bugs();

	float i;
	CSQC_CheckEngine();
	dprint_load();

	binddb = db_create();
	tempdb = db_create();
	compressShortVector_init();

	drawfont = 0;
	menu_visible = FALSE;
	menu_show = menu_show_error;
	menu_action = menu_sub_null;

	for(i = 0; i < 255; ++i)
		if(getplayerkey(i, "viewentity") == "")
			break;
	maxclients = i;

	//ctf_temp_1 = "";
	// localcmd("alias order \"cmd order $*\""); enable if ctf-command thingy is used
	//registercmd("ctf_menu");
	registercmd("ons_map");
	//registercmd("menu_action");

	registercmd("+button3");
	registercmd("-button3");
	registercmd("+button4");
	registercmd("-button4");
	registercmd("+showaccuracy");registercmd("-showaccuracy");

#ifndef CAMERATEST
	if(isdemo())
	{
#endif
		registercmd("+forward");registercmd("-forward");
		registercmd("+back");registercmd("-back");
		registercmd("+moveup");registercmd("-moveup");
		registercmd("+movedown");registercmd("-movedown");
		registercmd("+moveright");registercmd("-moveright");
		registercmd("+moveleft");registercmd("-moveleft");
		registercmd("+roll_right");registercmd("-roll_right");
		registercmd("+roll_left");registercmd("-roll_left");
#ifndef CAMERATEST
	}
#endif
	registercvar("sbar_usecsqc", "1");
	registercvar("sbar_columns", "default", CVAR_SAVE);
    registercvar("rm_visualdamage_fontsize", "20", CVAR_SAVE);
    registercvar("rm_visualdamage_limit", "20", CVAR_SAVE);
    registercvar("rm_showplayername", "1", CVAR_SAVE);
    registercvar("cl_effects_lightningarc_count", "3", CVAR_SAVE);
    registercvar("g_waypointsprite_pointer_scale", "1", CVAR_SAVE);
    registercvar("g_waypointsprite_pointer_edgefadescale", "1", CVAR_SAVE);
    gametype = 0;

	// sbar_fields uses strunzone on the titles!
	for(i = 0; i < MAX_SBAR_FIELDS; ++i)
		sbar_title[i] = strzone("(null)");

	postinit = false;

	calledhooks = 0;

	teams = Sort_Spawn();
	players = Sort_Spawn();

	GetTeam(COLOR_SPECTATOR, true); // add specs first

	cvar_clientsettemp("_supports_weaponpriority", "1");

	RegisterWeapons();

	WaypointSprite_Load();

	Projectile_Precache();
	GibSplash_Precache();
	Casings_Precache();
	DamageInfo_Precache();
	Announcer_Precache();

	get_mi_min_max_texcoords(1); // try the CLEVER way first
	minimapname = strcat("gfx/", mi_shortname, "_radar.tga");
	shortmapname = mi_shortname;
    whatsgoingon = ISFAGGOTMAP(shortmapname);
    
	if(precache_pic(minimapname) == "")
	{
		// but maybe we have a non-clever minimap
		minimapname = strcat("gfx/", mi_shortname, "_mini.tga");
		if(precache_pic(minimapname) == "")
			minimapname = ""; // FAIL
		else
			get_mi_min_max_texcoords(0); // load new texcoords
	}

	mi_center = (mi_min + mi_max) * 0.5;
	mi_scale = mi_max - mi_min;
	minimapname = strzone(minimapname);
	
	vote_statstring = strzone("");
	rm_watermark = RM_BUILD_NAME " " RM_BUILD_VERSION " " RM_BUILD_COMMIT " " RM_BUILD_DATE;
	rm_wm_width = stringwidth(rm_watermark, TRUE);
	
	bigprint_string = strzone("");
	bigprint_comment = strzone("");
	
	centerprint_init = 0;
	
	print("^1", rm_watermark, "\n");
	
	// hack for DSN users
	if(substring(cvar_string("g_nexuizversion"), 0, strlen("2.5.1")) == "2.5.1")
	{
		print("^1Outdated engine detected. Some features will be unavailable.\n");
		oldengine = 1;
	}
	
    dtrack_total = DamageTracker_CreateKeeper(world);
    dtrack_taken = DamageTracker_CreateKeeper(world);
    dtrack_total_spec = DamageTracker_CreateKeeper(world);
    dtrack_taken_spec = DamageTracker_CreateKeeper(world);
    
	IP2C_Init();
    registercvar("_g_nadgets_select_available", "0", 0);
    localcmd("cl_particles_reloadeffects\n");
}

// CSQC_Shutdown : Called every time the CSQC code is shutdown (changing maps, quitting, etc)
void CSQC_Shutdown(void)
{
#ifdef USE_FTE
#pragma TARGET id
	if(!__engine_check)
		return 0;
#pragma TARGET fte
#endif

	HUDSkin_Unload();
	IP2C_Shutdown();

	remove(teams);
	remove(players);
	db_close(binddb);
	db_close(tempdb);

	cvar_clientsettemp_restore();

	if(camera_active)
		cvar_set("chase_active",ftos(chase_active_backup));

	//if(cvar("rm_madoka"))
	//	localcmd("loadfont user2 gfx/vera-sans-big\n");
	
	if not(isdemo())
	{
		if not(calledhooks & HOOK_START)
			localcmd("\n_cl_hook_gamestart nop;");
		if not(calledhooks & HOOK_END)
			localcmd("\ncl_hook_gameend;");
	}
}

.float has_team;
float SetTeam(entity o, float Team)
{
	entity tm;
	if(teamplay)
	{
		switch(Team)
		{
			case -1:
			case COLOR_TEAM1:
			case COLOR_TEAM2:
			case COLOR_TEAM3:
			case COLOR_TEAM4:
				break;
			default:
				if(GetTeam(Team, false) == NULL)
				{
					print("trying to switch to unsupported team ", ftos(Team), "\n");
					Team = COLOR_SPECTATOR;
				}
				break;
		}
	}
	else
	{
		switch(Team)
		{
			case -1:
			case 0:
				break;
			default:
				if(GetTeam(Team, false) == NULL)
				{
					print("trying to switch to unsupported team ", ftos(Team), "\n");
					Team = COLOR_SPECTATOR;
				}
				break;
		}
	}
	if(Team == -1) // leave
	{
		if(o.has_team)
		{
			//print("(DISCONNECT) leave team ", ftos(o.team), "\n");
			tm = GetTeam(o.team, false);
			tm.team_size -= 1;
			o.has_team = 0;
			return TRUE;
		}
	}
	else
	{
		if not(o.has_team)
		{
			//print("(CONNECT) enter team ", ftos(o.team), "\n");
			o.team = Team;
			tm = GetTeam(Team, true);
			tm.team_size += 1;
			o.has_team = 1;
			return TRUE;
		}
		else if(Team != o.team)
		{
			//print("(CHANGE) leave team ", ftos(o.team), "\n");
			tm = GetTeam(o.team, false);
			tm.team_size -= 1;
			o.team = Team;
			//print("(CHANGE) enter team ", ftos(o.team), "\n");
			tm = GetTeam(Team, true);
			tm.team_size += 1;
			return TRUE;
		}
	}
	return FALSE;
}

void Playerchecker_Think()
{
	float i;
	entity e;
	for(i = 0; i < maxclients; ++i)
	{
		e = playerslots[i];
		if(GetPlayerName(i) == "")
		{
			if(e.sort_prev)
			{
				//print("playerchecker: KILL KILL KILL\n");
				// player disconnected
				SetTeam(e, -1);
				RemovePlayer(e);
				e.sort_prev = world;
				//e.gotscores = 0;
			}
		}
		else
		{
			if not(e.sort_prev)
			{
				//print("playerchecker: SPAWN SPAWN SPAWN\n");
				// player connected
				if not(e)
					playerslots[i] = e = spawn();
				e.sv_entnum = i;
				//e.gotscores = 0; // we might already have the scores...
				SetTeam(e, GetPlayerColor(i)); // will not hurt; later updates come with Sbar_UpdatePlayerTeams
				RegisterPlayer(e);
				Sbar_UpdatePlayerPos(e);
			}
		}
	}
	self.nextthink = time + 0.2;
}

void Porto_Init();
void TrueAim_Init();

float rmconfig_initialized;

#define RM_OUTDATED { print("^xFB0Detected an outdated RMconfig, initializing required cvars...\n"); rm_helptime = time + 20; }

#ifdef RM_SUPPORT_MADOKA
entity tmpmadoka;
#endif

float GetBigfont() {
	return ((rm_oldbigfont || sv_oldfag)? sbar_bigfont_real : sbar_rmbigfont);
}

void SetMadokaFont(float v)
{
	#ifdef RM_SUPPORT_MADOKA
	switch(v)
	{
		case MDKF_SET:
			sbar_bigfont = sbar_madokafont;
			//print("SetMadokaFont: sbar_bigfont = ", ftos(sbar_bigfont), "\n");
			break;
		case MDKF_UNSET:
			sbar_bigfont = GetBigfont();
			//print("SetMadokaFont: sbar_bigfont = ", ftos(sbar_bigfont), "\n");
			break;
		default: case MDKF_AUTO:
			if(madoka_locked)
			{
				if(cvar("rm_specmadoka"))
				{
					sbar_bigfont = (madokalockstate? sbar_madokafont : GetBigfont());
					return;
				}
				/*else
				{
					madoka_locked = 0;
				}*/
			}
			
			sbar_bigfont = (rm_madoka? sbar_madokafont : GetBigfont());
			//print("SetMadokaFont: sbar_bigfont = ", ftos(sbar_bigfont), " (AUTOSET)\n");
			break;
	}
	#else
	sbar_bigfont = GetBigfont();
	#endif
}

void ReloadMenu_f()
{
	if(!self.cnt)
	{
		cvar_set("rm_loadedmenu", RM_BUILD_MENUSUM);
		localcmd("menu_restart; r_restart\n");
		self.cnt = 1;
		self.nextthink = time + 1;
	}
	else
	{
		if(rm_helptime)
			localcmd("menu_cmd directmenu RMConfig\n");
			
		gui_reloading = 0;
		remove(self);
	}
}

void ReloadMenu()
{
	gui_reloading = 1;
	entity e = spawn();
	e.think = ReloadMenu_f;
	e.nextthink = time + 1;
}

void FPSReporter_Think() {
	localcmd("cmd fpsreport ", ftos(floor(cl_fps)), "\n");
	self.nextthink = time + sv_showfps;
}

void FPSReporter_Init() {
	if not(sv_showfps)
		return;
	
	entity e = spawn();
	e.think = FPSReporter_Think;
	e.nextthink = time + 1;
}

void PostInit(void)
{
	print(strcat("PostInit\n    maxclients = ", ftos(maxclients), "\n"));
	localcmd(strcat("\nsbar_columns_set ", cvar_string("sbar_columns"), ";\n"));

	entity playerchecker;
	playerchecker = spawn();
	playerchecker.think = Playerchecker_Think;
	playerchecker.nextthink = time + 0.2;

	Porto_Init();
	TrueAim_Init();

	MapInfo_Get_ByName(shortmapname, 0, 0);
	
	switch(cvar("rm_initialized"))
	{
		case 0:
		case 1:
			localcmd("seta rm_showspec 1; showspec 1\n");
			localcmd("seta rm_showdamage 1; showdamage 1\n");
			localcmd("seta rm_teamlasers 1; teamlasers 1\n");
		case 2:
		case 3:
		case 4:
		case 5:
			localcmd("seta rm_nobigtext 0; nobigtext 0\n");
		case 6:
		case 7:
			localcmd("seta rm_madoka 0; madoka 0\n");
		case 8:
			localcmd("seta rm_hidebigcomments 0; hidebigcomments 0\n");
		case 9:
			localcmd("seta rm_legacyvote 0; legacyvote 0\n");
		case 10:
			localcmd("seta rm_anonspec 0; anonspec 0\n");
		case 11:
			localcmd("seta rm_hidewatermark 0; hidewatermark 0\n");
		case 12:
			//deprecated, but gets set to be friendly to servers with older RM
			localcmd("seta rm_dontmesswithfonts 0; dontmesswithfonts 0\n");
		case 13:
			localcmd("seta rm_specmadoka 1; specmadoka 1\n");
		case 14:
			localcmd("seta rm_crosshealth 0; crosshealth 0\n");
		case 15:
			localcmd("seta rm_simpleeffects 0; simpleeffects 0\n");
		case 16:
        case 17:
			localcmd("seta rm_shownames 1; shownames 1\n");
		case 18:
			localcmd("seta rm_visualscore 1; visualscore 1\n");
		case 19:
			localcmd("seta rm_oldhud 0; oldhud 0\n");
		case 20:
			//localcmd("seta rm_althud 0; althud 0\n");
		case 21:
			localcmd("seta rm_althud 1; althud 1\n");
		case 22:
			//localcmd("alias afk \"cmd afk\"\n");
		case 23:
			localcmd("seta rm_noflags 0; noflags 0\n");
		case 24:
			localcmd("seta rm_hudskin \"default\"\n");
		case 25:	// yep, nothing here
		case 26:
		case 27:
		case 28:
		case 29:
			localcmd("seta rm_nogamemenu 0; nogamemenu 0\n");
		case 30:
			localcmd("seta rm_notimer 0; notimer 0\n");
		case 31:
			localcmd("seta rm_nokillsound 0; nokillsound 0\n");
		case 32:
			localcmd("seta rm_hidecountry 0; hidecountry 0\n");
		case 33:
			localcmd("seta rm_showrankings 1; showrankings 1\n");
        case 34:
        case 35:
			localcmd("seta rm_shownames_teamonly 0; shownames_teamonly 0\n");
		case 36:
			localcmd("seta rm_freezetag_danger 1; freezetag_danger 1\n");
			localcmd("seta rm_freezetag_danger_silent 1; freezetag_danger_silent 1\n");
		case 37:
			localcmd("seta rm_oldbigfont 0; oldbigfont 0\n");
        case 38:
            // fight evil with evil
            if(cvar("cl_gunalign") == 3)
                localcmd("seta cl_gunalign 1; sendcvar cl_gunalign\n");
        case 39:
            cvar_set("_rm_hg_optout", "0");
        case 40:
            localcmd("seta rm_showtimer 0; showtimer 0\n");
        case 41:
            localcmd("seta rm_shownadgetregen 0; shownadgetregen 0\n");
            
		//More to come here with each update
		localcmd("seta rm_initialized 42\n");
		RM_OUTDATED
		break;
	}
	
	localcmd("alias afk \"cmd afk\"\n");
	localcmd("alias rmcfg \"menu_cmd directmenu RMConfig\"\n");
	rm_showspec   = cvar("rm_showspec");
	rm_showdamage = cvar("rm_showdamage");
	rm_teamlasers = cvar("rm_teamlasers");
	rm_nobigtext  = cvar("rm_nobigtext");
	rm_hidebigcomments = cvar("rm_hidebigcomments");
	rm_legacyvote = cvar("rm_legacyvote");
	rm_hidewatermark = cvar("rm_hidewatermark");
	rm_madoka = cvar("rm_madoka");
	rm_crosshealth = cvar("rm_crosshealth");
	rm_simpleeffects = cvar("rm_simpleeffects");
	rm_shownames = cvar("rm_shownames");
	rm_visualscore = cvar("rm_visualscore");
	rm_oldhud_option = cvar("rm_oldhud");
	rm_althud_option = cvar("rm_althud");
	rm_oldhud = rm_oldhud_option;
	rm_althud = rm_althud_option;
	rm_noflags = cvar("rm_noflags");
	rm_showrankings = cvar("rm_showrankings");
	rm_shownames_teamonly = cvar("rm_shownames_teamonly");
	rm_oldbigfont = cvar("rm_oldbigfont");
    rm_showtimer = cvar("rm_showtimer");
    rm_shownadgetregen = cvar("rm_shownadgetregen");
	
	registercmd("rmhelp");
	registercmd("showspec");
	registercmd("showdamage");
	registercmd("teamlasers");
	registercmd("nobigtext");
	registercmd("madoka");
	registercmd("hidebigcomments");
	registercmd("legacyvote");
	registercmd("anonspec");
	registercmd("hidewatermark");
	registercmd("dontmesswithfonts");
	registercmd("specmadoka");
	registercmd("crosshealth");
	registercmd("simpleeffects");
	registercmd("shownames");
	registercmd("visualscore");
	registercmd("oldhud");
	registercmd("althud");
	registercmd("noflags");
	registercmd("notimer");
	registercmd("nogamemenu");
	registercmd("nokillsound");
	registercmd("hidecountry");
	registercmd("showrankings");
	registercmd("shownames_teamonly");
	registercmd("oldbigfont");
	registercmd("freezetag_danger");
	registercmd("freezetag_danger_silent");
    registercmd("showtimer");
    registercmd("shownadgetregen");
	// -- //
	registercmd("hudskin");
	
	bigprint(strcat("^2", shortmapname), ((MapInfo_Map_title != "<TITLE>")? MapInfo_Map_title : ""), 2);
	
	#ifdef RM_SUPPORT_MADOKA
	if(sv_showspecs_extra)
		localcmd("cmd madoka ", cvar_string("rm_madoka"), "\n");
	tmpmadoka = spawn();
	
	//loadfont("user3", "gfx/madoka-rune");
	//For some reason, widths are all screwd up if loading through the wrapper... what the FUCK!?
	localcmd("loadfont user3 gfx/madoka-rune\n");
	localcmd("loadfont user4 gfx/iceland\n");		// RM bigfont
	localcmd("loadfont infobar gfx/vera-sans-big\n");
	SetMadokaFont(MDKF_AUTO);
	#endif
	
	if(sv_showspecs_extra)
		localcmd("cmd hudinfo ", cvar_string("rm_oldhud"), " ", cvar_string("rm_althud"), "\n");
	localcmd("cmd anonspec ", cvar_string("rm_anonspec"), "\n");
	localcmd("cmd nokillsound ", ftos(cvar("rm_nokillsound")), "\n");
	localcmd("cmd hidecountry ", cvar_string ("rm_hidecountry"), "\n");
	
	if(cvar("_cl_afkstate"))
		localcmd("cmd afk\n");
	
	HUDSkin_Load(cvar_string("rm_hudskin"));
	
	screenfade = time + 0.1;
	fovlock = -1;
	
	registercvar("rm_loadedmenu", "");
	if(cvar_string("rm_loadedmenu") != RM_BUILD_MENUSUM)
		ReloadMenu();
	else if(rm_helptime)
		localcmd("menu_cmd directmenu RMConfig\n");
	
	localcmd("cmd menu_request\n"); // workaround against restarts
	FPSReporter_Init();
	DPRM_Start();
	
	postinit = true;
}

// CSQC_ConsoleCommand : Used to parse commands in the console that have been registered with the "registercmd" function
// Return value should be 1 if CSQC handled the command, otherwise return 0 to have the engine handle it.
float button_zoom;
void Cmd_Sbar_SetFields(float);
void Cmd_Sbar_Help(float);

void(float bufhandle, string pattern, string antipattern) buf_cvarlist = #517;

#define VALUEREQUIRED if(argc < 2) { print(strCmd, " is ", (cvar(strcat("rm_", strCmd))? "^2ON" : "^1OFF"), "\nUsage: ^2", strCmd, " 1^7 to enable, ^2", strCmd, " 0 ^7to disable.\n"); return true; }
#define RMSETTINGREPORT { print(strCmd, " is now ", (cvar(strcat("rm_", strCmd))? "^2ON\n" : "^1OFF\n")); localcmd("menu_cmd update_rmvars\n"); }
float CSQC_ConsoleCommand(string strMessage)
{
	float argc;
	// Tokenize String
	//argc = tokenize(strMessage);
	argc = tokenize_console(strMessage);

	// Acquire Command
	local string strCmd;
	strCmd = argv(0);

	if(strCmd == "+button4") { // zoom
		// return false, because the message shall be sent to the server anyway (for demos/speccing)
		if(ignore_plus_zoom)
		{
			--ignore_plus_zoom;
			return false;
		}
		button_zoom = 1;
		return true;
	} else if(strCmd == "-button4") { // zoom
		if(ignore_minus_zoom)
		{
			--ignore_minus_zoom;
			return false;
		}
		button_zoom = 0;
		return true;
	} else if(strCmd == "+button3") { // secondary
		button_attack2 = 1;
		return false;
	} else if(strCmd == "-button3") { // secondary
		button_attack2 = 0;
		return false;
	} else if(strCmd == "+showscores") {
		sb_showscores = true;
		return true;
	} else if(strCmd == "-showscores") {
		sb_showscores = false;
		return true;
	} else if(strCmd == "+showaccuracy") {
		//sb_showaccuracy = true;
		
		//if(cvar("_g_rocketminsta"))
		//	bigprint("Accuracy statistics are disabled", "", 2);
		//else
			sb_showaccuracy = true;
			
		return true;
	} else if(strCmd == "-showaccuracy") {
		sb_showaccuracy = false;
		return true;
	}
	else if(strCmd == "rmhelp")
	{
		print("^xFB0RocketMinsta configuration options. ^7To enable an option, type ^2optionname 1^7. To disable, ^2optionname 0^7.\n\n");
		print("^2showspec^7: If enabled, you will see who is spectating you unless the server forbids it (enabled by default)\n");
		print("^2showdamage^7: If enabled, you will see how much damage you deal or take on each hit unless the server forbids it (enabled by default)\n");
		print("^2teamlasers^7: If enabled, laser projectiles will have a team specific color unless the server forbids it (enabled by default)\n");
		print("^2nobigtext^7: If enabled, the top-center big messages (bigprints) will be redirected into the bottom centerprint area (disabled by default)\n");
		print("^2hidebigcomments^7: If enabled, comments for bigprints will not be shown (disabled by default)\n");
		print("^2legacyvote^7: If enabled, votes will be displayed in plaintext instead of a dialog (disabled by default)\n");
		print("^2anonspec^7: Anonymous spectator mode. If enabled, players will not see when you're spectating them, unless the server forbids it (disabled by default)\n");
		print("^2hidewatermark^7: If enabled, the RM build information watermark will not be drawn (disabled by default)\n");
		print("^2crosshealth^7: If enabled, the crosshair color will reflect current health (disabled by default)\n");
		print("^2dontmesswithfonts^7: Deprecated, kept for compatibility\n");
		print("^2simpleeffects^7: Enables simple fade effects for onscreen notifications instead of fancy ones (disabled by default)\n");
		print("^2shownames^7: If enabled, names of players will be shown above their heads (disabled by default)\n");
		print("^2shownames_teamonly^7: If enabled, shownames will work only for allies (disabled by default)\n");
		print("^2visualscore^7: If enabled, changes to your score will be displayed (enabled by default)\n");
		print("^2oldhud^7: If enabled, standard Nexuiz HUD will be used (disabled by default)\n");
		print("^2althud^7: If enabled, use an alternative layout for the HUD (disabled by default)\n");
		print("^2noflags^7: If enabled, plain-text country codes will be shown instead of flags (disabled by default)\n");
		print("^2notimer^7: If enabled, the 'time' column will not be shown in the scoreboard (disabled by default)\n");
		print("^2nogamemenu^7: If enabled, will go directly to the main menu when activating menu in-game (disabled by default)\n");
		print("^2nokillsound^7: If enabled, the kill sound will not be used (you'll hear the default hit sound instead) (disabled by default)\n");
		print("^2hidecountry^7: If enabled, your flag in the scoreboard will be replaced with a question mark sign, unless the server forbids it (disabled by default)\n");
		print("^2showrankings^7: If enabled, will show a mini-scoreboard in the HUD (enabled by default)\n");
        print("^2showtimer^7: If enabled, will always show the timer (disabled by default)\n");
        print("^2shownadgetregen^7: If enabled, will show the remaining nadget regeneration time in seconds (RM HUD only) (disabled by default)\n");
		print("^2oldbigfont^7: If enabled, will use Nexuiz's default 'bigfont' instead of the RM one\n");
		print("^2freezetag_danger^7: If enabled, you will be able to place 'danger' waypoints using the fire button while frozen (enabled by default)\n");
		print("^2freezetag_danger_silent^7: If enabled, danger waypoints placed with the fire button shortcut will not post a teamchat message (enabled by default)\n");
		#ifdef RM_SUPPORT_MADOKA
		#ifdef RM_SHOW_MADOKA_IN_RMHELP
		print("^2madoka^7: If enabled, big text will be shown using Madoka runes instead of normal characters. By enabling this option, you automatically accept The Contract (disabled by default)\n");
		print("^2specmadoka^7: If enabled, you will see if your spectatee uses Madoka runes or not (enabled by default)\n");
		#endif
		#endif
		
		print("\nIn addition, these commands are available:\n");
		print("^5afk^7: Marks you as being away\n");
		print("^5hudskin^7: Lists or switches HUD skins and displays other HUD-related information\n");
		return true;
	}
	else if(
		strCmd == "showspec" 			||
		strCmd == "showdamage" 			||
		strCmd == "teamlasers"			||
		strCmd == "nobigtext"			||
		strCmd == "hidebigcomments"		||
		strCmd == "legacyvote"			||
		strCmd == "hidewatermark"		||
		strCmd == "dontmesswithfonts"	||
		strCmd == "crosshealth"			||
		strCmd == "simpleeffects"		||
		strCmd == "shownames"			||
		strCmd == "visualscore"			||
		strCmd == "oldhud"				||
		strCmd == "althud"				||
		strCmd == "noflags"				||
		strCmd == "notimer"				||
		strCmd == "nogamemenu"			||
		strCmd == "nokillsound"			||
		strCmd == "showrankings"		||
        strCmd == "showtimer"           ||
        strCmd == "shownadgetregen"     ||
		strCmd == "shownames_teamonly"  ||
		strCmd == "oldbigfont"			||
		strCmd == "freezetag_danger"	||
		strCmd == "freezetag_danger_silent")
	{
		VALUEREQUIRED
		cvar_set(strcat("rm_", strCmd), argv(1));
		rm_showspec = cvar("rm_showspec");
		rm_showdamage = cvar("rm_showdamage");
		rm_teamlasers = cvar("rm_teamlasers");
		rm_nobigtext = cvar("rm_nobigtext");
		rm_hidebigcomments = cvar("rm_hidebigcomments");
		rm_legacyvote = cvar("rm_legacyvote");
		rm_hidewatermark = cvar("rm_hidewatermark");
		rm_crosshealth = cvar("rm_crosshealth");
		rm_simpleeffects = cvar("rm_simpleeffects");
		rm_shownames = cvar("rm_shownames");
		rm_visualscore = cvar("rm_visualscore");
		rm_oldhud_option = cvar("rm_oldhud");
		rm_althud_option = cvar("rm_althud");
		rm_noflags = cvar("rm_noflags");
		rm_showrankings = cvar("rm_showrankings");
		rm_shownames_teamonly = cvar("rm_shownames_teamonly");
		rm_oldbigfont = cvar("rm_oldbigfont");
        rm_showtimer = cvar("rm_showtimer");
        rm_shownadgetregen = cvar("rm_shownadgetregen");
		
		if(strCmd == "oldhud" || strCmd == "althud")
		{
			if(hudlocked)
				print("^1Won't change HUD while spectating\n");
			else
			{
				rm_oldhud = rm_oldhud_option;
				rm_althud = rm_althud_option;
				
				localcmd("cmd hudinfo ", cvar_string("rm_oldhud"), " ", cvar_string("rm_althud"), " ", cvar_string("rm_hudskin"), "\n");
			}
		}
		else if(strCmd == "notimer")
			localcmd("cl_cmd sbar_columns_set default\n");
		else if(strCmd == "nokillsound")
			localcmd("cmd nokillsound ", ftos(cvar("rm_nokillsound")), "\n");
		
		SetMadokaFont(MDKF_AUTO);
		RMSETTINGREPORT
		return true;
	}
	else if(strCmd == "madoka")
	{
		#ifdef RM_SUPPORT_MADOKA
		if(is_tmpmadoka)
		{
			print("^0Your Soul Gem darkened and turned into a Grief Seed\n");
			localcmd("disconnect\n");
			return true;
		}
		
		VALUEREQUIRED
		
		if(madoka_locked && cvar("rm_specmadoka"))
		{
			print("^1Won't change madoka while spectating\n");
			return true;
		}
		
		cvar_set(strcat("rm_", strCmd), argv(1));
		//loadfont("user2", (cvar("rm_madoka") ? "madoka-rune" : "vera-sans-big"));
		rm_madoka = cvar("rm_madoka");
		SetMadokaFont(MDKF_AUTO);
		
		if(sv_showspecs_extra)
			localcmd("cmd madoka ", cvar_string("rm_madoka"), "\n");
		RMSETTINGREPORT
		return true;
		#else
		print("^1This RocketMinsta build has been compiled without madoka-rune support\n");
		return false;
		#endif
	}
	else if(strCmd == "anonspec")
	{
		VALUEREQUIRED
		cvar_set(strcat("rm_", strCmd), argv(1));
		localcmd("cmd anonspec ", cvar_string("rm_anonspec"), "\n");
		RMSETTINGREPORT
		return true;
	}
	else if(strCmd == "specmadoka")
	{
		VALUEREQUIRED
		cvar_set(strcat("rm_", strCmd), argv(1));
		
		//if(!cvar("rm_specmadoka"))
		//	loadfont("user2", (cvar("rm_madoka") ? "madoka-rune" : "vera-sans-big"));
		SetMadokaFont(MDKF_AUTO);
		
		RMSETTINGREPORT
		return true;
	}
	else if(strCmd == "hudskin")
	{
		if(argc < 2)
		{
			print("\n^xFB0The following HUD skins are available:\n");
			
			local float i, seed, globsize, hsglob = search_begin("gfx/hud/skins/*/skininfo", FALSE, TRUE);
			local string tmpname, displayname;
			globsize = search_getsize(hsglob);
			
			seed = floor(random() * globsize);
			for(i = 0; i < globsize; ++i)
			{
				tmpname = search_getfilename(hsglob, i);
				tmpname = substring(tmpname, strlen("gfx/hud/skins/"), strlen(tmpname));
				tmpname = substring(tmpname, 0, strlen(tmpname) - strlen("/skininfo"));
				
				if(i == seed)
					displayname = tmpname;
					
				print("^5    ", tmpname);
				
				if(tmpname == hudskin_name)
					print(" ^8(current)\n");
				else print("\n");
			}
			search_end(hsglob);
			
			print("\nTo change the HUD skin, type: ^2hudskin SKINNAME\nFor example, ^2hudskin ", displayname, "\n");
			print("\nYou can also use ^2althud 0^7 to disable the alternative HUD layout (will use a layout similar to Nexuiz default instead), or use ^2oldhud 1^7 to disable RocketMinsta HUD entriely\n");
			
			return true;
		}
		
		if(!hudlocked)
		{
			HUDSkin_Load(argv(1));
			cvar_set("rm_hudskin", hudskin_name);
			localcmd("menu_cmd update_rmvars\n");
			if(sv_showspecs_extra)
				localcmd("cmd hudinfo ", cvar_string("rm_oldhud"), " ", cvar_string("rm_althud"), " ", cvar_string("rm_hudskin"), "\n");
		}
		else
		{
			print("^1Can't change the HUD skin while spectating a player, please join the game or become an observer and try again\n");
			return true;
		}
		
		return true;
	}
	else if (strCmd == "hidecountry")
	{
		VALUEREQUIRED
		cvar_set ("rm_hidecountry", argv (1));
		rm_hidecountry = cvar ("rm_hidecountry");
		localcmd ("cmd hidecountry ", cvar_string ("rm_hidecountry"), "\n");
		RMSETTINGREPORT
		return true;
	}

	if(camera_active)
	if(strCmd == "+forward" || strCmd == "-back") {
		++camera_direction_x;
		return true;
	} else if(strCmd == "-forward" || strCmd == "+back") {
		--camera_direction_x;
		return true;
	} else if(strCmd == "+moveright" || strCmd == "-moveleft") {
		--camera_direction_y;
		return true;
	} else if(strCmd == "-moveright" || strCmd == "+moveleft") {
		++camera_direction_y;
		return true;
	} else if(strCmd == "+moveup" || strCmd == "-movedown") {
		++camera_direction_z;
		return true;
	} else if(strCmd == "-moveup" || strCmd == "+movedown") {
		--camera_direction_z;
		return true;
	} else if(strCmd == "+roll_right" || strCmd == "-roll_left") {
		++camera_roll;
		return true;
	} else if(strCmd == "+roll_left" || strCmd == "-roll_right") {
		--camera_roll;
		return true;
	}

	return false;
}

.vector view_ofs;
entity debug_shotorg;
void ShotOrg_Draw()
{
	self.origin = view_origin + view_forward * self.view_ofs_x + view_right * self.view_ofs_y + view_up * self.view_ofs_z;
	self.angles = view_angles;
	self.angles_x = -self.angles_x;
	if not(self.cnt)
		R_AddEntity(self);
}
void ShotOrg_Draw2D()
{
	vector coord2d_topleft, coord2d_topright, coord2d;
	string s;
	vector fs;

	s = vtos(self.view_ofs);
	s = substring(s, 1, strlen(s) - 2);
	if(tokenize_console(s) == 3)
		s = strcat(argv(0), " ", argv(1), " ", argv(2));

	coord2d_topleft = project_3d_to_2d(self.origin + view_up * 4 - view_right * 4);
	coord2d_topright = project_3d_to_2d(self.origin + view_up * 4 + view_right * 4);

	fs = '1 1 0' * ((coord2d_topright_x - coord2d_topleft_x) / stringwidth(s, FALSE));

	coord2d = coord2d_topleft;
	if(fs_x < 8)
	{
		coord2d_x += (coord2d_topright_x - coord2d_topleft_x) * (1 - 8 / fs_x) * 0.5;
		fs = '8 8 0';
	}
	coord2d_y -= fs_y;
	coord2d_z = 0;
	drawstring(coord2d, s, fs, '1 1 1', 1, 0);
}

void ShotOrg_Spawn()
{
	debug_shotorg = spawn();
	debug_shotorg.draw = ShotOrg_Draw;
	debug_shotorg.draw2d = ShotOrg_Draw2D;
	debug_shotorg.renderflags = RF_VIEWMODEL;
	debug_shotorg.effects = EF_FULLBRIGHT;
	precache_model("models/shotorg_adjuster.md3");
	setmodel(debug_shotorg, "models/shotorg_adjuster.md3");
	debug_shotorg.scale = 2;
	debug_shotorg.view_ofs = '25 8 -8';
}

#ifdef RM_SUPPORT_MADOKA
.float oldspecmadoka;
void TmpMadoka_Think()
{
	//if(!cvar("rm_madoka"))
	//	loadfont("user2", "vera-sans-big");
	
	cvar_set("rm_specmadoka", ftos(self.oldspecmadoka));
	is_tmpmadoka = 0;
	SetMadokaFont(MDKF_AUTO);
}

void madokaprint(string m, string c, float t)
{
	if(is_tmpmadoka) return;
	
	is_tmpmadoka = 1;
	
	tmpmadoka_fadetime = time + t + 1;
	tmpmadoka.think = TmpMadoka_Think;
	tmpmadoka.nextthink = tmpmadoka_fadetime;
	tmpmadoka.oldspecmadoka = cvar("rm_specmadoka");
	cvar_set("rm_specmadoka", "0");
	//loadfont("user2", "madoka-rune");
	SetMadokaFont(MDKF_SET);
	localcmd("play2 misc/powerup\n");
	
	if(!cvar("rm_dontmesswithfonts"))
	if(!rm_nobigtext)
	//We will either print runic text here, or won't print anything at all.
		bigprint(m, c, t);
}
#endif

void GameCommand(string msg)
{
	float argc;
	argc = tokenize_console(msg);

	if(argv(0) == "help" || argc == 0)
	{
		print("Usage: cl_cmd COMMAND..., where possible commands are:\n");
		print("  settemp cvar value\n");
		print("  radar\n");
		print("  sbar_columns_set ...\n");
		print("  sbar_columns_help\n");
		print("  bigprint text command staytime\n");
		#ifdef RM_SUPPORT_MADOKA
		print("  madokaprint text command staytime\n");
		#endif
		GameCommand_Generic("help");
		return;
	}

	if(GameCommand_Generic(msg))
		return;

	string cmd;
	cmd = argv(0);
	if(cmd == "mv_download") {
		Cmd_MapVote_MapDownload(argc);
	}
	else if(cmd == "settemp") {
		cvar_clientsettemp(argv(1), argv(2));
	}
	else if(cmd == "radar") {
		ons_showmap = !ons_showmap;
	}
	else if(cmd == "sbar_columns_set") {
		Cmd_Sbar_SetFields(argc);
	}
	else if(cmd == "sbar_columns_help") {
		Cmd_Sbar_Help(argc);
	}
#ifdef BLURTEST
	else if(cmd == "blurtest") {
		blurtest_time0 = time;
		blurtest_time1 = time + stof(argv(1));
		blurtest_radius = stof(argv(2));
		blurtest_power = stof(argv(3));
	}
#endif
	else if(cmd == "shotorg_move") {
		if(!debug_shotorg)
			ShotOrg_Spawn();
		else
			debug_shotorg.view_ofs = debug_shotorg.view_ofs + stov(argv(1));
		localcmd("sv_cmd debug_shotorg \"", vtos(debug_shotorg.view_ofs), "\"\n");
	}
	else if(cmd == "shotorg_movez") {
		if(!debug_shotorg)
			ShotOrg_Spawn();
		else
			debug_shotorg.view_ofs = debug_shotorg.view_ofs + stof(argv(1)) * (debug_shotorg.view_ofs * (1 / debug_shotorg.view_ofs_x)); // closer/farther, same xy pos
		localcmd("sv_cmd debug_shotorg \"", vtos(debug_shotorg.view_ofs), "\"\n");
	}
	else if(cmd == "shotorg_set") {
		if(!debug_shotorg)
			ShotOrg_Spawn();
		else
			debug_shotorg.view_ofs = stov(argv(1));
		localcmd("sv_cmd debug_shotorg \"", vtos(debug_shotorg.view_ofs), "\"\n");
	}
	else if(cmd == "shotorg_setz") {
		if(!debug_shotorg)
			ShotOrg_Spawn();
		else
			debug_shotorg.view_ofs = debug_shotorg.view_ofs * (stof(argv(1)) / debug_shotorg.view_ofs_x); // closer/farther, same xy pos
		localcmd("sv_cmd debug_shotorg \"", vtos(debug_shotorg.view_ofs), "\"\n");
	}
	else if(cmd == "shotorg_toggle_hide") {
		if(debug_shotorg)
		{
			debug_shotorg.cnt = !debug_shotorg.cnt;
		}
	}
	else if(cmd == "shotorg_end") {
		if(debug_shotorg)
		{
			print(vtos(debug_shotorg.view_ofs), "\n");
			remove(debug_shotorg);
			debug_shotorg = world;
		}
		localcmd("sv_cmd debug_shotorg\n");
	}
	else if(cmd == "votestat")
	{
		strunzone(vote_statstring);
		vote_statstring = strzone(strcat("^2Yes^7: ", argv(1), " ^1No^7: ", argv(2), " (", argv(3), " needed)"));
	}
	#ifdef RM_SUPPORT_MADOKA
	/*else if(cmd == "walpurgis")
	{
		madokaprint("^1x ^0WALPURGIS NIGHT ^10", "", 5);
	}*/
	else if(cmd == "lockmadoka")
	{
		//print("lockmadoka(", argv(1), ")\n");
		
		if(cvar("rm_specmadoka"))
		{
			madoka_locked = 1;
			madokalockstate = stof(argv(1));
			SetMadokaFont(madokalockstate);
			//loadfont("user2", (stof(argv(1))? "madoka-rune" : "vera-sans-big"));
		}
	}
	/*
	else if(cmd == "lockhud")
	{
		hudlocked = 1;
		hudlocked_old = stof(argv(1));
		hudlocked_alt = stof(argv(2));
		
		rm_althud = hudlocked_alt;
		rm_oldhud = hudlocked_old;
		
		if(argv(3) != hudskin_name)
			HUDSkin_Load(argv(3));
	}
	else if(cmd == "lockfov")
	{
		fovlock = stof(argv(1));
	}
	else if(cmd == "speczoom")
	{
		speczoom_speed = stof(argv(1));
		speczoom_factor = stof(argv(2));
	}
	*/
	else if(cmd == "madokaprint")
	{
		if(argc < 3)
		{
			print("Usage: madokaprint text comment staytime\n");
			return;
		}
		
		madokaprint(argv(1), argv(2), stof(argv(3)));
	}
	#endif
	else if(cmd == "bigprint")
	{
		if(argc < 3)
		{
			print("Usage: bigprint text comment staytime\n");
			return;
		}
		
		bigprint(argv(1), argv(2), stof(argv(3)));
	}
	else if(cmd == "hudflash")
	{
		if(argc < 4)
		{
			print("Usage: hudflash color time intensivity alpha\n");
			return;
		}
		
		hudflash(stov(argv(1)), stof(argv(2)), stof(argv(3)), stof(argv(4)));
	}
	else if(cmd == "hudskin")
	{
		HUDSkin_Load(argv(1));
	}
	else if(cmd == "hudskin_unload")
	{
		HUDSkin_Unload();
	}
	else if(cmd == "hudskin_eval")
	{
		HUDSkin_Eval(substring(msg, strlen(cmd) + 1, strlen(msg)));
	}
	else if(cmd == "crc16")
	{
		if(argc < 3)
			print("Usage: crc16 bool:caseinsensitive string\n");
		else
			print(ftos(crc16(stof(argv(1)), argv(2))), "\n");
	}
	else if(cmd == "danger") {
		if not(cvar("rm_freezetag_danger"))
			return;
		
		if(cvar("rm_freezetag_danger_silent")) {
			localcmd("g_waypointsprite_team_danger_p\n");
			return;
		}
		
		// dirty dirty hacks
		// I love them
		
		string userbind = cvar_string("userbind7_press");
		if(strstrofs(userbind, "g_waypointsprite_team_danger_p", 0) >= 0 && strstrofs(userbind, "%p", 0) >= 0)
			localcmd("_userbind_call userbind7_press\n");
		else
			localcmd("say_team enemy seen (^4%p^7 at ^2%y^7); g_waypointsprite_team_danger_p\n");
	}
	else
	{
		print("Invalid command. For a list of supported commands, try cl_cmd help.\n");
	}

	return;
}

// CSQC_InputEvent : Used to perform actions based on any key pressed, key released and mouse on the client.
// Return value should be 1 if CSQC handled the input, otherwise return 0 to have the input passed to the engine.
// All keys are in ascii.
// bInputType = 0 is key pressed, 1 is key released, 2 is mouse input.
// In the case of keyboard input, nPrimary is the ascii code, and nSecondary is 0.
// In the case of mouse input, nPrimary is xdelta, nSecondary is ydelta.
float CSQC_InputEvent(float bInputType, float nPrimary, float nSecondary)
{
	local float bSkipKey;
	bSkipKey = false;

	if(MapVote_InputEvent(bInputType, nPrimary, nSecondary))
		return true;

	if(menu_visible)
		if(menu_action(bInputType, nPrimary, nSecondary))
			return TRUE;
	return bSkipKey;
}

// END REQUIRED CSQC FUNCTIONS
// --------------------------------------------------------------------------

// --------------------------------------------------------------------------
// BEGIN OPTIONAL CSQC FUNCTIONS
void Ent_ReadEntCS()
{
	InterpolateOrigin_Undo();

	self.classname = "entcs_receiver";
	self.sv_entnum = ReadByte() - 1;
	self.origin_x = ReadShort();
	self.origin_y = ReadShort();
	self.origin_z = ReadShort();
	self.angles_y = ReadByte() * 360.0 / 256;
	self.origin_z = self.angles_x = self.angles_z = 0;

	InterpolateOrigin_Note();
}

void Ent_Remove();

void Ent_RemovePlayerScore()
{
	float i;

	if(self.owner)
	{
		SetTeam(self.owner, -1);
		self.owner.gotscores = 0;
		for(i = 0; i < MAX_SCORE; ++i)
			self.owner.(scores[i]) = 0; // clear all scores
	}
}

.entity bestscore_next;
void UpdateBestScore(float teem, float sfield) {
    float best, scr, better;
    entity bestscore_head, bestscore_tail, c;
    
    for(c = players.sort_next; c; c = c.sort_next) {
        if(GetPlayerColor(c.sv_entnum) != teem)
            continue;
        
        c.(hasbestscore[sfield]) = FALSE;
        scr = c.(scores[sfield]);
        
        if(!bestscore_head)
            better = TRUE;
        if(scores_flags[sfield] & SFL_LOWER_IS_BETTER)
            better = scr < best;
        else
            better = scr > best;
        
        if(better) {
            c.bestscore_next = world;
            best = scr;
            bestscore_head = bestscore_tail = c;
        } else if(scr == best) {
            c.bestscore_next = world;
            if(bestscore_tail)
                bestscore_tail.bestscore_next = c;
            else
                bestscore_head = c;
            bestscore_tail = c;
        }
    }
    
    for(c = bestscore_head; c; c = c.bestscore_next)
        c.(hasbestscore[sfield]) = TRUE;
}

void Ent_ReadPlayerScore()
{
	float i, n;
	float isNew;
	entity o;

	// damnit -.- don't want to go change every single .sv_entnum in sbar.qc AGAIN
	// (no I've never heard of M-x replace-string, sed, or anything like that)
	isNew = !self.owner; // workaround for DP bug
	n = ReadByte()-1;

#ifdef DP_CSQC_ENTITY_REMOVE_IS_B0RKED
	if(!isNew && n != self.sv_entnum)
	{
		print("A CSQC entity changed its owner!\n");
		isNew = true;
		Ent_Remove();
		self.enttype = ENT_CLIENT_SCORES;
	}
#endif

	self.sv_entnum = n;

	if not(playerslots[self.sv_entnum])
		playerslots[self.sv_entnum] = spawn();
	o = self.owner = playerslots[self.sv_entnum];
	o.sv_entnum = self.sv_entnum;
	o.gotscores = 1;

	//if not(o.sort_prev)
	//	RegisterPlayer(o);
	//playerchecker will do this for us later, if it has not already done so

	float sf, lf;
#if MAX_SCORE <= 8
	sf = ReadByte();
	lf = ReadByte();
#elif MAX_SCORE <= 16
	sf = ReadShort();
	lf = ReadShort();
#else
	sf = ReadInt24_t();
	lf = ReadInt24_t();
#endif
	float p;
	
	float oldscore = o.(scores[SP_SCORE]);
	
	for(i = 0, p = 1; i < MAX_SCORE; ++i, p *= 2)
	{
		if(sf & p)
		{
            if(lf & p)
                o.(scores[i]) = ReadInt24_t();
            else
                o.(scores[i]) = ReadChar();
            
            if(i != SP_PLAYTIME && i != SP_ACCURACY)
                UpdateBestScore(GetPlayerColor(o.sv_entnum), i);
		}
	}

	float newscore = o.(scores[SP_SCORE]);
	
	if(self.sv_entnum == player_localentnum - 1 || self.sv_entnum == spectatee_status - 1)
	{
		if(oldscore != newscore)
		{
			score_visual(newscore - oldscore);
		}
	}

	if(o.sort_prev)
		Sbar_UpdatePlayerPos(o); // if not registered, we cannot do this yet!

	self.entremove = Ent_RemovePlayerScore;
}

void Ent_ReadTeamScore()
{
	float i;
	entity o;

	self.team = ReadByte();
	o = self.owner = GetTeam(self.team, true); // these team numbers can always be trusted

	float sf, lf;
#if MAX_TEAMSCORE <= 8
	sf = ReadByte();
	lf = ReadByte();
#else
	sf = ReadShort();
	lf = ReadShort();
#endif
	float p;
	for(i = 0, p = 1; i < MAX_TEAMSCORE; ++i, p *= 2)
		if(sf & p)
		{
			if(lf & p)
				o.(teamscores[i]) = ReadInt24_t();
			else
				o.(teamscores[i]) = ReadChar();
		}

	Sbar_UpdateTeamPos(o);
}

void Net_Reset()
{
}

void Ent_ClientData()
{
	float f;
	float newspectatee_status;

	f = ReadByte();

	sb_showscores_force = (f & 1);

	if(f & 2)
	{
		newspectatee_status = ReadByte();
		if(newspectatee_status == player_localentnum)
			newspectatee_status = -1; // observing
	}
	else
		newspectatee_status = 0;

	spectatorbutton_zoom = (f & 4);

	if(f & 8)
	{
		angles_held_status = 1;
		angles_held_x = ReadAngle();
		angles_held_y = ReadAngle();
		angles_held_z = 0;
	}
	else
		angles_held_status = 0;

	if(newspectatee_status != spectatee_status)
	{
		// clear race stuff
		race_laptime = 0;
		race_checkpointtime = 0;
	}
	spectatee_status = newspectatee_status;
}

void Ent_Nagger()
{
	float nags, i, j, b, f;

	nags = ReadByte();

	if(nags & 128)
	{
		if(vote_called_vote)
			strunzone(vote_called_vote);
		vote_called_vote = strzone(ColorTranslateRGB(ReadString()));
        if(vote_called_vote == "")
            vote_active = 0;
	}

	if(nags & 1)
	{
		for(j = 0; j < maxclients; ++j)
			if(playerslots[j])
				playerslots[j].ready = 1;
		for(i = 1; i <= maxclients; i += 8)
		{
			f = ReadByte();
			for(j = i-1, b = 1; b < 256; b *= 2, ++j)
				if not(f & b)
					if(playerslots[j])
						playerslots[j].ready = 0;
		}
	}

	ready_waiting = (nags & 1);
	ready_waiting_for_me = (nags & 2);
	vote_waiting = (nags & 4);
	vote_waiting_for_me = ((nags & 8) && !isdemo());
	warmup_stage = (nags & 16);
}

void Ent_RandomSeed()
{
	float s;
	prandom_debug();
	s = ReadShort();
	psrandom(s);
}

void Ent_ShowNames()
{
    float sf;

    // entity init, TODO can this be done only once somehow?
    self.the_entnum = ReadByte(); // TODO: fixme to only send once somehow
    self.draw2d = Draw_ShowNames;
    //self.movetype = MOVETYPE_FLY; // movetype needed so we can traceline?
    self.mins = '-20 -20 -24';
    self.maxs = '20 20 45';

    sf = ReadByte();

    if(sf & 1)
    {
        self.origin_x = ReadShort();
        self.origin_y = ReadShort();
        self.origin_z = ReadShort();
    }
    if(sf & 2)
    {
        if(sf & 16)
            self.healthvalue = ReadShort();
        else
            self.healthvalue = ReadByte();
        
        if(sf & 32)
            self.armorvalue = ReadShort();
        else
            self.armorvalue = ReadByte();
    }

    if(sf & 128) // same team
        self.sameteam = TRUE;
    else
        self.sameteam = FALSE;
}

// CSQC_Ent_Update : Called every frame that the server has indicated an update to the SSQC / CSQC entity has occured.
// The only parameter reflects if the entity is "new" to the client, meaning it just came into the client's PVS.
void Ent_RadarLink();
void Ent_Init();
void Ent_ScoresInfo();
void(float bIsNewEntity) CSQC_Ent_Update =
{
	float t;
	float savetime;
	t = ReadByte();

	// set up the "time" global for received entities to be correct for interpolation purposes
	savetime = time;
	if(servertime)
	{
		time = servertime;
	}
	else
	{
		serverprevtime = time;
		serverdeltatime = getstatf(STAT_MOVEVARS_TICRATE) * getstatf(STAT_MOVEVARS_TIMESCALE);
		time = serverprevtime + serverdeltatime;
	}

#ifdef DP_CSQC_ENTITY_REMOVE_IS_B0RKED
	if(self.enttype)
		if(t != self.enttype)
		{
			print("A CSQC entity changed its type!\n");
			Ent_Remove();
			bIsNewEntity = 1;
		}
#endif
	self.enttype = t;
	switch(t)
	{
		case ENT_CLIENT: break;
		case ENT_CLIENT_ENTCS: Ent_ReadEntCS(); break;
		case ENT_CLIENT_SCORES: Ent_ReadPlayerScore(); break;
		case ENT_CLIENT_TEAMSCORES: Ent_ReadTeamScore(); break;
		case ENT_CLIENT_POINTPARTICLES: Ent_PointParticles(); break;
		case ENT_CLIENT_RAINSNOW: Ent_RainOrSnow(); break;
		case ENT_CLIENT_LASER: Ent_Laser(); break;
		case ENT_CLIENT_NAGGER: Ent_Nagger(); break;
		case ENT_CLIENT_WAYPOINT: Ent_WaypointSprite(); break;
		case ENT_CLIENT_RADARLINK: Ent_RadarLink(); break;
		case ENT_CLIENT_PROJECTILE: Ent_Projectile(); break;
		case ENT_CLIENT_GIBSPLASH: Ent_GibSplash(bIsNewEntity); break;
		case ENT_CLIENT_DAMAGEINFO: Ent_DamageInfo(bIsNewEntity); break;
		case ENT_CLIENT_CASING: Ent_Casing(bIsNewEntity); break;
		case ENT_CLIENT_INIT: Ent_Init(); break;
		case ENT_CLIENT_SCORES_INFO: Ent_ScoresInfo(); break;
		case ENT_CLIENT_MAPVOTE: Ent_MapVote(); break;
		case ENT_CLIENT_CLIENTDATA: Ent_ClientData(); break;
		case ENT_CLIENT_RANDOMSEED: Ent_RandomSeed(); break;
		case ENT_CLIENT_WALL: Ent_Wall(); break;
		case ENT_CLIENT_MODELEFFECT: Ent_ModelEffect(bIsNewEntity); break;
		case ENT_CLIENT_SHOWNAMES: Ent_ShowNames(); break;
		default:
			error(strcat("unknown entity type in CSQC_Ent_Update: ", ftos(self.enttype), "\n"));
			break;
	}

	time = savetime;
};
// Destructor, but does NOT deallocate the entity by calling remove(). Also
// used when an entity changes its type. For an entity that someone interacts
// with others, make sure it can no longer do so.
void Ent_Remove()
{
	if(self.entremove)
		self.entremove();

	self.enttype = 0;
	self.classname = "";
	self.draw = menu_sub_null;
	self.entremove = menu_sub_null;
	// TODO possibly set more stuff to defaults
}
// CSQC_Ent_Remove : Called when the server requests a SSQC / CSQC entity to be removed.  Essentially call remove(self) as well.
void CSQC_Ent_Remove()
{
	if(self.enttype)
		Ent_Remove();
	remove(self);
}

void Gamemode_Init()
{
	if(gametype == GAME_ONSLAUGHT) {
		print(strcat("Using ", minimapname, " as minimap.\n"));
		precache_pic("gfx/ons-cp-neutral.tga");
		precache_pic("gfx/ons-cp-red.tga");
		precache_pic("gfx/ons-cp-blue.tga");
		precache_pic("gfx/ons-frame.tga");
		precache_pic("gfx/ons-frame-team.tga");
	} else if(gametype == GAME_KEYHUNT) {
		precache_pic("gfx/sb_key_carrying");
		precache_pic("gfx/sb_key_carrying_outline");
	}

	if not(isdemo())
	{
		localcmd("\n_cl_hook_gamestart ", gametype_ID_to_Name(gametype), ";");
		calledhooks |= HOOK_START;
	}
}
// CSQC_Parse_StuffCmd : Provides the stuffcmd string in the first parameter that the server provided.  To execute standard behavior, simply execute localcmd with the string.
void CSQC_Parse_StuffCmd(string strMessage)
{
	localcmd(strMessage);
}
// CSQC_Parse_Print : Provides the print string in the first parameter that the server provided.  To execute standard behavior, simply execute print with the string.
void CSQC_Parse_Print(string strMessage)
{
	print(ColorTranslateRGB(strMessage));
}

// CSQC_Parse_CenterPrint : Provides the centerprint string in the first parameter that the server provided.
void CSQC_Parse_CenterPrint(string strMessage)
{
	centerprint(strMessage);
}

string MakeFog(vector rgb, float a) {
	return strcat(ftos(a), " ", ftos(rgb_x), " ", ftos(rgb_y), " ", ftos(rgb_z));
}

void ForceFogString(string fog) {
	localcmd(strcat("\nfog ", fog, "\nr_fog_exp2 0\nr_drawfog 1\n"));
}

void ForceFog(vector rgb, float a) {
	ForceFogString(MakeFog(rgb, a));
}

void Fog_Force()
{
	// TODO somehow thwart prvm_globalset client ...

	if(forcefog != "" || whatsgoingon) {
		
		if(forcefog == "nyan" || whatsgoingon) {
			float a = 0.5 + 0.5 * sin(0.5 * time);
			vector hsl;
			hsl_x = a * 2 * PI;
			hsl_y = 1;
			hsl_z = 0.8 - 0.2 * sin(1.11 * time) * cos(2.22 * time);
			ForceFog(hsl_to_rgb(hsl), 0.02 * (1 - 0.5 * cos(1.13 * time)));
			
			if(cvar("r_glsl")) {
				cvar_clientsettemp("r_glsl_saturation", ftos(3 * cos(time * 0.25)));
			}
            
            cvar_clientsettemp("volume", ftos(max(0.1, cvar("volume"))));
            cvar_clientsettemp("bgmvolume", ftos(max(0.5, cvar("bgmvolume"))));
		}
		
		else ForceFogString(forcefog);
	}
}

void Gamemode_Init();
void Ent_ScoresInfo()
{
	float i;
	self.classname = "ent_client_scores_info";
	gametype = ReadByte();
	for(i = 0; i < MAX_SCORE; ++i)
	{
		scores_label[i] = strzone(ReadString());
		scores_flags[i] = ReadByte();
	}
	for(i = 0; i < MAX_TEAMSCORE; ++i)
	{
		teamscores_label[i] = strzone(ReadString());
		teamscores_flags[i] = ReadByte();
	}
	Sbar_InitScores();
	Gamemode_Init();
}

void Ent_Init()
{
	float i;
	self.classname = "ent_client_init";

	nb_pb_period = ReadByte() / 32; //Accuracy of 1/32th

	for(i = 0; i < 24; ++i)
		weaponimpulse[i] = ReadByte() - 1;
	hook_shotorigin_x = ReadCoord();
	hook_shotorigin_y = ReadCoord();
	hook_shotorigin_z = ReadCoord();

	if(forcefog)
		strunzone(forcefog);
	forcefog = strzone(ReadString());

	armorblockpercent = ReadByte() / 255.0;
	sv_showspecs_extra = ReadByte();
	sv_showfps = ReadByte();
	sv_oldfag = ReadByte();
	g_nadgets = ReadByte();
    cvar_set("_g_nadgets_select_available", ftos(g_nadgets? ReadByte() : 0));
    g_freeze = ReadByte();
    sv_scoreboard_heal_column = ReadByte();
    sv_damagestats = ReadByte();
    sv_nicehealth = ReadShort();
    sv_showacc = ReadByte();

	if(!postinit)
		PostInit();
}

void Net_ReadRace()
{
	float b;

	b = ReadByte();

	switch(b)
	{
		case RACE_NET_CHECKPOINT_HIT_QUALIFYING:
			race_checkpoint = ReadByte();
			race_time = ReadInt24_t();
			race_previousbesttime = ReadInt24_t();
			if(race_previousbestname)
				strunzone(race_previousbestname);
			race_previousbestname = strzone(ColorTranslateRGB(ReadString()));

			race_checkpointtime = time;

			if(race_checkpoint == 0 || race_checkpoint == 254)
			{
				race_penaltyaccumulator = 0;
				race_laptime = time; // valid
			}

			break;

		case RACE_NET_CHECKPOINT_CLEAR:
			race_laptime = 0;
			race_checkpointtime = 0;
			break;

		case RACE_NET_CHECKPOINT_NEXT_SPEC_QUALIFYING:
			race_laptime = ReadCoord();
			race_checkpointtime = -99999;
			// fall through
		case RACE_NET_CHECKPOINT_NEXT_QUALIFYING:
			race_nextcheckpoint = ReadByte();

			race_nextbesttime = ReadInt24_t();
			if(race_nextbestname)
				strunzone(race_nextbestname);
			race_nextbestname = strzone(ColorTranslateRGB(ReadString()));
			break;

		case RACE_NET_CHECKPOINT_HIT_RACE:
			race_mycheckpoint = ReadByte();
			race_mycheckpointtime = time;
			race_mycheckpointdelta = ReadInt24_t();
			race_mycheckpointlapsdelta = ReadByte();
			if(race_mycheckpointlapsdelta >= 128)
				race_mycheckpointlapsdelta -= 256;
			if(race_mycheckpointenemy)
				strunzone(race_mycheckpointenemy);
			race_mycheckpointenemy = strzone(ColorTranslateRGB(ReadString()));
			break;

		case RACE_NET_CHECKPOINT_HIT_RACE_BY_OPPONENT:
			race_othercheckpoint = ReadByte();
			race_othercheckpointtime = time;
			race_othercheckpointdelta = ReadInt24_t();
			race_othercheckpointlapsdelta = ReadByte();
			if(race_othercheckpointlapsdelta >= 128)
				race_othercheckpointlapsdelta -= 256;
			if(race_othercheckpointenemy)
				strunzone(race_othercheckpointenemy);
			race_othercheckpointenemy = strzone(ColorTranslateRGB(ReadString()));
			break;

		case RACE_NET_PENALTY_RACE:
			race_penaltyeventtime = time;
			race_penaltytime = ReadShort();
			//race_penaltyaccumulator += race_penaltytime;
			if(race_penaltyreason)
				strunzone(race_penaltyreason);
			race_penaltyreason = strzone(ReadString());
			break;

		case RACE_NET_PENALTY_QUALIFYING:
			race_penaltyeventtime = time;
			race_penaltytime = ReadShort();
			race_penaltyaccumulator += race_penaltytime;
			if(race_penaltyreason)
				strunzone(race_penaltyreason);
			race_penaltyreason = strzone(ReadString());
			break;
	}
}

void Net_ReadSpawn()
{
	zoomin_effect = 1;
	current_viewzoom = 0.6;
}

void Net_ReadBigPrint()
{
	bigprint(ReadString(), ReadString(), ReadShort());
}

void Net_ReadMadokaPrint()
{
	#ifdef RM_SUPPORT_MADOKA
	madokaprint(ReadString(), ReadString(), ReadShort());
	#else
	print("Warning: the server attempted a madokaprint, but RM has been built without madoka-rune support! This should never happen, the mod is B0RKED!!\n");
	#endif
}

void Net_ReadSpecInfo()
{
	local float i;
	
	if(ReadByte()) {
		float md = ReadByte();
		
		if(cvar("rm_specmadoka")) {
			madoka_locked = TRUE;
			madokalockstate = md;
			SetMadokaFont(madokalockstate);
		}
		
		hudlocked = TRUE;
		rm_oldhud = hudlocked_old = ReadByte();
		rm_althud = hudlocked_alt = ReadByte();
		
		string skn = ReadString();
		if(skn != hudskin_name)
			HUDSkin_Load(skn);
		
		fovlock = ReadByte();
		speczoom_speed  = ReadByte() * 0.1;
		speczoom_factor = ReadByte() * 0.1;
	}
	
	num_spectators = ReadByte();
	for(i = 0; i < num_spectators; ++i)
	{
		local float slot = ReadByte();
		if(i < MAX_SPECTATORS)
			spectatorlist[i] = slot - 1;
	}
}

void Net_VoteDialog(float highlight) {
	if(highlight) {
		vote_highlighted = ReadShort();
		return;
	}

	vote_yescount = ReadShort();
	vote_nocount = ReadShort();
	vote_needed = ReadShort();
	vote_active = 1;
}

void Net_VoteDialogReset() {
	vote_active = 0;
}

void Net_ReadMorningRescue()
{
	#ifdef RM_SUPPORT_MORNINGRESCUE
	if(morningrescue)
		return;
	
	localcmd("play2 sound/misc/morningrescue\n");
	morningrescue = 1;
	mr_appeartime = time;
	mr_fadetime   = time + 9;
	#else
	error("Server attempted a MorningRescue, but the mod has been built without RM_SUPPORT_MORNINGRESCUE! EVERYTHING IS FUCKED UP BIG TIME.");
	#endif
}

void Net_ReadClearBigPrint()
{
    bigprint(" ", "", 0);
    //bigprint("", "", 0);
}

void Net_ReadHudFlash(float teamcolor)
{
	local float a, i, t;
	local vector c;
	
	//c = decompressShortVector(ReadShort());
	
	if(teamcolor)
		c = GetTeamRGB(myteam);
	else
	{
		c_x = ReadCoord();
		c_y = ReadCoord();
		c_z = ReadCoord();
	}
	
	t = ReadCoord();
	i = ReadCoord();
	a = ReadCoord();
	
	hudflash(c, t, i, a);
}

void Net_ReadVIPInfo(float teem)
{
	switch(teem)
	{
		case COLOR_TEAM1:
			vip_red_maxhealth = ReadShort();
			vip_red_health = ReadShort();
			
			if(vip_red_name)
				strunzone(vip_red_name);
			vip_red_name = strzone(strdecolorize(ReadString()));
			return;
		
		case COLOR_TEAM2:
			vip_blue_maxhealth = ReadShort();
			vip_blue_health = ReadShort();
			
			if(vip_blue_name)
				strunzone(vip_blue_name);
			vip_blue_name = strzone(strdecolorize(ReadString()));
			return;
	}
	
	print("^1WARNING: ^7Received VipInfo for an unknown team: ", ftos(teem), "\n");
	print("Dump: \n");
	print("^5 -> ", ftos(ReadShort()), "\n");
	print("^5 -> ", ftos(ReadShort()), "\n");
	print("^5 -> ", ftos(ReadShort()), "\n");
	print("^5 -> ", ftos(ReadShort()), "\n");
}

void Net_Camera() {
	if(!ReadByte()) {
		camera_expiretime = -1;
		return;
	}
	
	camera_origin_x = ReadShort();
	camera_origin_y = ReadShort();
	camera_origin_z = ReadShort();
	
	if(time <= camera_expiretime || camera_drawviewmodel_locked)
		dprint("Warning: Net_Camera while a camera is still active\n");
	else {
		camera_drawviewmodel_backup = cvar("r_drawviewmodel");
		camera_drawviewmodel_locked = TRUE;
	}
	
	camera_expiretime = time + ReadShort();
    
    if(camera_expiretime < time)
        camera_expiretime = -2;
}

void Net_ServerInfo() {
    sv_hostname = strzone(ReadString());
    sv_rm_build = strzone(ReadString());
    sv_rm_version = strzone(ReadString());
    sv_rm_date = strzone(ReadString());
    sv_rm_commit = strzone(ReadString());
    sv_motd = strzone(ReadString());
}

void Net_Heal() {
    vector o;
    o_x = ReadCoord();
    o_y = ReadCoord();
    o_z = ReadCoord();
    pointparticles(rm_particleeffectnum("RM_HEAL"), o, '0 0 0', 1);
}

entity Net_DamageTracker_KeeperFromFlags(float dtflags) {
    if(dtflags & DTFLAG_DONE) {
        if(dtflags & DTFLAG_SPEC)
            return dtrack_total_spec;
        else
            return dtrack_total;
    } else if(dtflags & DTFLAG_TAKEN) {
        if(dtflags & DTFLAG_SPEC)
            return dtrack_taken_spec;
        else
            return dtrack_taken;
    }
    
    return world;
}

void Net_DamageTracker() {
    float dtype, damage, dtflags, i, ecnt;
    entity k;
    
    dtflags = ReadByte();
    k = Net_DamageTracker_KeeperFromFlags(dtflags);
    
    if(!k)
        error(strcat("Got invalid damage tracker flags from server: ", ftos(dtflags)));
    
    if(dtflags & DTFLAG_OVERWRITE) {
        ecnt = ReadByte();
        
        DamageTracker_Wipe(k);
        for(i = 0; i < ecnt; ++i) {
            dtype = ReadShort();
            damage = ReadShort();
            DamageTracker_Record(k, dtype, damage);
            // assume it's sorted by the server already
        }
    } else {        
        dtype = ReadShort();
        damage = ReadShort();
        DamageTracker_Record(k, dtype, damage);
        DamageTracker_Sort(k);
    }
}

// CSQC_Parse_TempEntity : Handles all temporary entity network data in the CSQC layer.
// You must ALWAYS first acquire the temporary ID, which is sent as a byte.
// Return value should be 1 if CSQC handled the temporary entity, otherwise return 0 to have the engine process the event.
float CSQC_Parse_TempEntity()
{
	// Acquire TE ID
	local float nTEID;
	nTEID = ReadByte();

	switch(nTEID)
	{
		case TE_CSQC_PICTURE:
			Net_MapVote_Picture();
			return TRUE;
		case TE_CSQC_RACE:
			Net_ReadRace();
			return TRUE;
		case 13: // TE_BEAM
			Net_GrapplingHook();
			return TRUE;
		case TE_CSQC_SPAWN:
			Net_ReadSpawn();
			return TRUE;
		case TE_CSQC_ZCURVEPARTICLES:
			Net_ReadZCurveParticles();
			return TRUE;
		case TE_CSQC_NEXGUNBEAMPARTICLE:
			Net_ReadNexgunBeamParticle();
			return TRUE;
        case TE_CSQC_LIGHTNINGARC:
            Net_ReadLightningarc();
			return TRUE;
        case TE_CSQC_BIGPRINT:
			Net_ReadBigPrint();
			return TRUE;
		case TE_CSQC_SPECINFO:
			Net_ReadSpecInfo();
			return TRUE;
		case TE_CSQC_VOTE:
			Net_VoteDialog(ReadByte());
			return TRUE;
		case TE_CSQC_VOTERESET:
			Net_VoteDialogReset();
			return TRUE;
		case TE_CSQC_MADOKAPRINT:
			Net_ReadMadokaPrint();
			return TRUE;
		case TE_CSQC_MORNINGRESCUE:
			Net_ReadMorningRescue();
			return TRUE;
        case TE_CSQC_CLEARBIGPRINT:
            Net_ReadClearBigPrint();
			return TRUE;
		case TE_CSQC_HUDFLASH:
			Net_ReadHudFlash(FALSE);
			return TRUE;
		case TE_CSQC_HUDFLASH_TEAMCOLOR:
			Net_ReadHudFlash(TRUE);
			return TRUE;
		case TE_CSQC_VIPINFO:
			Net_ReadVIPInfo(ReadByte());
			return TRUE;
		case TE_CSQC_CAMERA:
			Net_Camera();
			return TRUE;
		case TE_CSQC_SERVERINFO:
			Net_ServerInfo();
			return TRUE;
        case TE_CSQC_VISUALDAMAGE:
            Net_VisualDamage();
            return TRUE;
        case TE_CSQC_HEAL:
            Net_Heal();
            return TRUE;
        case TE_CSQC_BLAST:
            Net_ReadBlast();
            return TRUE;
        case TE_CSQC_DTRACK:
            Net_DamageTracker();
            return TRUE;
    }

	// pass to the engine
	return FALSE;
}

string getcommandkey(string text, string command)
{
	string keys;
	float n, j, k, l;

	if (!sbar_showbinds)
		return text;

	keys = db_get(binddb, command);
	if (!keys)
	{
		n = tokenize(findkeysforcommand(command)); // uses '...' strings
		for(j = 0; j < n; ++j)
		{
			k = stof(argv(j));
			if(k != -1)
			{
				if ("" == keys)
					keys = keynumtostring(k);
				else
					keys = strcat(keys, ", ", keynumtostring(k));

				++l;
				if (sbar_showbinds_limit > 0 && sbar_showbinds_limit >= l) break;
			}

		}
		db_put(binddb, command, keys);
	}

	if ("" == keys) {
		if (sbar_showbinds > 1)
			return strcat(text, " (not bound)");
		else
			return text;
	}
	else if (sbar_showbinds > 1)
		return strcat(text, " (", keys, ")");
	else
		return keys;
}

//////////////////////////////

float bigprint_noold;

void bigprint_old(string bigstr, string comment, float fadeTime)
{
	if(is_tmpmadoka) return;
    
	obp_draw = 1;
	
	if(bigprint_oldstring)
		fstrunzone(bigprint_oldstring);
	//if(bigprint_oldcomment)
	//	fstrunzone(bigprint_oldcomment);
	
	bigprint_oldstring = strzone(bigstr);
	//bigprint_oldcomment = strzone(comment);
	
	bigprint_oldfadetime = fadeTime - 0.1;
	bigprint_oldappeartime = time;
}

void bigprint(string bigstr, string comment, float staytime)
{
    float no = FALSE;
    if(staytime < 0) {
        staytime = -staytime;
        no = TRUE;
    }
    
	if(rm_nobigtext)
	{
		local string s;
		s = bigstr;
		
		if(comment != "") {
			if(s == "")
				s = comment;
			else
				s = strcat(s, "\n", comment);
		}
		
		centerprint(s);
		return;
	}
	
	if(bigstr != "")
	{
		bp_draw = 1;
        
        if(!bigprint_noold)
            bigprint_old(bigprint_string, bigprint_comment, bigprint_fadetime);
		
		if(bigprint_string)
			fstrunzone(bigprint_string);
		
		bigprint_string = strzone(bigstr);
		bigprint_fadetime = time + staytime;
		bigprint_appeartime = time;
	}
	
    bigprint_noold = no;
    
	if(comment != "")
	{
		
		if(substring(comment, 0, 1) == "\x01")
		{
			if(rm_shownames)
				return;
			
			comment = substring(comment, 1, strlen(comment));
			bigprint_nofadein = 1;
		}
		else
			bigprint_nofadein = 0;
		
		bpc_draw = 1;
		
		if(bigprint_comment)
			fstrunzone(bigprint_comment);
		
		bigprint_comment = strzone(comment);
		bigprint_commentfadetime = time + staytime;
		bigprint_commentappeartime = time;
	}
}

void score_visual(float score)
{
	//centerprint(ftos(score));
	
	string s;
	vector c;
	
	if(score < 0)
	{
		c = '1 0 0';
		s = ftos(score);
	}
	else
	{
		c = '0 1 0';
		c_z = c_x = max(0, 1 - score / SCORECOLOR_MAXSCORE);
		s = strcat("+", ftos(score));
	}
	
	if(score_strings_num >= MAX_SCORESTRINGS)
	{
		local float k2;
		for(k2 = 0; k2 < MAX_SCORESTRINGS-1; ++k2)
		{
			if(score_strings[k2]) strunzone(score_strings[k2]);
			score_strings[k2] = strzone(score_strings[k2+1]);
			score_strings_fadeout[k2] = score_strings_fadeout[k2+1];
			score_strings_color[k2] = score_strings_color[k2+1];
			score_strings_appear[k2] = score_strings_appear[k2+1];
			score_strings_alphamod[k2] = score_strings_alphamod[k2+1] * 0.8;
		}
		
		strunzone(score_strings[k2]);
		score_strings_num--;
	}
	
	score_strings[score_strings_num] = strzone(s);
	score_strings_fadeout[score_strings_num] = time + 2;
	score_strings_color[score_strings_num] = c;
	score_strings_alphamod[score_strings_num] = 1.0;
	score_strings_appear[score_strings_num] = time;
	++score_strings_num;
}

void hudflash(vector colour, float staytime, float intensivity, float alph)
{
	if(sv_oldfag)
		return;
	
	hudflash_color = colour;
	hudflash_intensivity = intensivity;
	hudflash_alpha = alph;
	hudflash_appeartime = time;
	hudflash_fadetime = time + staytime;
	hudflash_enabled = TRUE;
}
