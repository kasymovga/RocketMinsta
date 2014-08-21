
void CreatureFrame (void)
{
	local entity oldself;
	local float dm;
	oldself = self;
	//self = findfloat(world, iscreature, TRUE);
	//while(self)
    FOR_EACH_CLIENTSLOT(self) if(self.iscreature)
	{
		if (self.movetype != MOVETYPE_NOCLIP)
		{
			if (self.waterlevel)
			{
				if (!(self.flags & FL_INWATER))
				{
					self.flags |= FL_INWATER;
					self.dmgtime = 0;
				}
				if (self.waterlevel != WATERLEVEL_SUBMERGED)
				{
					if(self.air_finished < time + 9)
						PlayerSound(playersound_gasp, CHAN_PLAYER, VOICETYPE_PLAYERSOUND);
					self.air_finished = time + 12;
					self.dmg = 2;
				}
				else if (self.air_finished < time)
				{	// drown!
					if (!self.deadflag)
					if (self.pain_finished < time)
					{
						Damage (self, world, world, 5, DEATH_DROWN, self.origin, '0 0 0');
						self.pain_finished = time + 0.5;
					}
				}
				if (self.dmgtime < time)
				{
					self.dmgtime = time + 0.1;
					if (self.watertype == CONTENT_LAVA)
					{
						if (self.watersound_finished < time)
						{
							self.watersound_finished = time + 0.5;
							sound (self, CHAN_PLAYER, "player/lava.wav", VOL_BASE, ATTN_NORM);
						}
						Damage (self, world, world, 6 * self.waterlevel, DEATH_LAVA, self.origin, '0 0 0');
					}
					else if (self.watertype == CONTENT_SLIME)
					{
						if (self.watersound_finished < time)
						{
							self.watersound_finished = time + 0.5;
							sound (self, CHAN_PLAYER, "player/slime.wav", VOL_BASE, ATTN_NORM);
						}
						Damage (self, world, world, 2 * self.waterlevel, DEATH_SLIME, self.origin, '0 0 0');
					}
				}
			}
			else
			{
				if (self.flags & FL_INWATER)
				{
					// play leave water sound
					self.flags &~= FL_INWATER;
					self.dmgtime = 0;
				}
				self.air_finished = time + 12;
				self.dmg = 2;
			}
			// check for falling damage
			if(!self.hook.state)
			{
				dm = vlen(self.oldvelocity) - vlen(self.velocity); // dm is now the velocity DECREASE. Velocity INCREASE should never cause a sound or any damage.
				if (self.deadflag)
					dm = (dm - g_balance_falldamage_deadminspeed) * g_balance_falldamage_factor;
				else
					dm = min((dm - g_balance_falldamage_minspeed) * g_balance_falldamage_factor, g_balance_falldamage_maxdamage);
				if (dm > 0)
				{
					Damage (self, world, world, dm, DEATH_FALL, self.origin, '0 0 0');
				}
				else if(vlen(self.velocity) > 100000 && cvar("developer"))
				{
					dprint(strcat(self.netname, " became too fast, please investigate: ", vtos(self.spawnorigin), "\n"));
					Damage (self, world, world, 50000, DEATH_SHOOTING_STAR, self.origin, '0 0 0');
				}
			}

			// play stupid sounds
			if (g_footsteps)
			if (!gameover)
			if (self.flags & FL_ONGROUND)
			if (vlen(self.velocity) > sv_maxspeed * 0.6)
			if (!self.deadflag)
                        if (!BUFFS_PRESENT(self, BUFF_NINJA))
			if (time < self.lastground + 0.2)
			{
				if((time > self.nextstep) || (time < (self.nextstep - 10.0)))
				{
					self.nextstep = time + 0.3 + random() * 0.1;
					trace_dphitq3surfaceflags = 0;
					tracebox(self.origin, self.mins, self.maxs, self.origin - '0 0 1', MOVE_NOMONSTERS, self);
					/*
					if(trace_fraction == 1)
						dprint("nohit\n");
					else
						dprint(ftos(trace_dphitq3surfaceflags), "\n");
					*/
					if not(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOSTEPS)
					{
						if(trace_dphitq3surfaceflags & Q3SURFACEFLAG_METALSTEPS)
							GlobalSound(globalsound_metalstep, CHAN_PLAYER, VOICETYPE_PLAYERSOUND);
						else
							GlobalSound(globalsound_step, CHAN_PLAYER, VOICETYPE_PLAYERSOUND);
					}
				}
			}
			self.oldvelocity = self.velocity;
		}
		//self = findfloat(self, iscreature, TRUE);
	}
	self = oldself;
}

// This returns the player who's been afk for the longest amount of time
entity GetAFKKickVictim() {
	entity v, e;
    
	FOR_EACH_REALCLIENT(e) if(time - e.jointime > 30) if(e.is_away)
		if(!v || v.parm_idlesince > e.parm_idlesince)
			v = e;
	
	return v;
}

/*
=============
StartFrame

Called before each frame by the server
=============
*/
void RuneMatchGivePoints();
float RedirectionThink();

float cvarupdatetime;
string oldfog;

entity SelectSpawnPoint (float anypoint);
void StartFrame (void)
{
    entity e;
    
	remove = remove_unsafely; // not during spawning!
	serverprevtime = servertime;
	servertime = time;
	serverframetime = frametime;

#ifdef PROFILING
	if(time > client_cefc_accumulatortime + 1)
	{
		float t, pp, c_seeing, c_seen;
		entity cl;
		t = client_cefc_accumulator / (time - client_cefc_accumulatortime);
		print("CEFC time: ", ftos(t * 1000), "ms; ");
		c_seeing = 0;
		c_seen = 0;
		FOR_EACH_CLIENT(cl)
		{
			if(clienttype(cl) == CLIENTTYPE_REAL)
				++c_seeing;
			if(cl.classname == "player")
				++c_seen;
		}
		print("CEFC calls per second: ", ftos(c_seeing * (c_seen - 1) / t), "; ");
		print("CEFC 100% load at: ", ftos(solve_quadratic(t, -t, -1) * '0 1 0'), "\n");

		client_cefc_accumulatortime = time;
		client_cefc_accumulator = 0;
	}
#endif

	dprint_load(); // load dprint status from cvar
    
	for(e = world; (e = findfloat(e, csqcprojectile_clientanimate, 1)); )
		CSQCProjectile_Check(e);

	if(RedirectionThink())
		return;

	UncustomizeEntitiesRun();
	InitializeEntitiesRun();

    if(time > cvarupdatetime) {   // do we REALLY need to update those every frame? Most of these aren't even going to be changed midgame
        sv_gravity = cvar("sv_gravity");
        sv_maxairspeed = cvar("sv_maxairspeed");
        sv_maxspeed = cvar("sv_maxspeed");
        sv_friction = cvar("sv_friction");
        sv_accelerate = cvar("sv_accelerate");
        sv_airaccelerate = cvar("sv_airaccelerate");
        sv_airaccel_sideways_friction = cvar("sv_airaccel_sideways_friction");
        sv_airaccel_qw = cvar("sv_airaccel_qw");
        sv_stopspeed = cvar("sv_stopspeed");
        sv_airstopaccelerate = cvar("sv_airstopaccelerate");
        sv_airstrafeaccelerate = cvar("sv_airstrafeaccelerate");
        sv_maxairstrafespeed = cvar("sv_maxairstrafespeed");
        sv_aircontrol = cvar("sv_aircontrol");
        sv_warsowbunny_airforwardaccel = cvar("sv_warsowbunny_airforwardaccel");
        sv_warsowbunny_accel = cvar("sv_warsowbunny_accel");
        sv_warsowbunny_topspeed = cvar("sv_warsowbunny_topspeed");
        sv_warsowbunny_turnaccel = cvar("sv_warsowbunny_turnaccel");
        sv_warsowbunny_backtosideratio = cvar("sv_warsowbunny_backtosideratio");
        teamplay = cvar("teamplay");
        sys_ticrate = cvar("sys_ticrate");
        sv_jumpvelocity = cvar("sv_jumpvelocity");
        sv_gameplayfix_q2airaccelerate = cvar("sv_gameplayfix_q2airaccelerate");
        sv_autoaway = cvar("sv_autoaway");
        g_walljump = cvar("g_walljump");
        g_walljump_delay = cvar("g_walljump_delay");
        g_dodging = cvar("g_dodging");

        if(g_dodging) {
            g_dodging_delay = cvar("g_dodging_delay");
            g_dodging_ramp_time = cvar("g_dodging_ramp_time");
            
            if(g_freeze)
                g_freezetag_dodging_frozen = Freeze_CVar("dodging_frozen");
        }
        
        g_balance_health_rotstable = cvar("g_balance_health_rotstable");
        g_balance_armor_rotstable = cvar("g_balance_armor_rotstable");
        g_balance_fuel_rotstable = cvar("g_balance_fuel_rotstable");
        g_balance_health_regenstable = cvar("g_balance_health_regenstable");
        g_balance_armor_regenstable = cvar("g_balance_armor_regenstable");
        g_balance_fuel_regenstable = cvar("g_balance_fuel_regenstable");
        g_balance_health_limit = cvar("g_balance_health_limit");
        g_balance_armor_limit = cvar("g_balance_armor_limit");
        g_balance_fuel_limit = cvar("g_balance_fuel_limit");
        
        g_balance_falldamage_deadminspeed = cvar("g_balance_falldamage_deadminspeed");
        g_balance_falldamage_factor = cvar("g_balance_falldamage_factor");
        g_balance_falldamage_minspeed = cvar("g_balance_falldamage_minspeed");
        g_balance_falldamage_maxdamage = cvar("g_balance_falldamage_maxdamage");
        
        sv_defaultcharacter = cvar("sv_defaultcharacter");
        sv_defaultplayercolors = cvar("sv_defaultplayercolors");
        sv_forcespecies = cvar("sv_forcespecies");
        
        cvarupdatetime = time + 1;
    }

	if(timeoutStatus == 1) // just before the timeout (when timeoutStatus will be 2)
		orig_slowmo = cvar("slowmo"); // slowmo will be restored after the timeout

	if(teams_matter && !teamplay)
		teamplay = 3;
	if(!teams_matter && teamplay)
		teamplay = 0;

	skill = cvar("skill");

	Spawnqueue_Check();

	// if in warmup stage and limit for warmup is hit start match
	if (!forbidrestart)
	if (inWarmupStage)
	// But not during the god damn intermission you dump piece of shit
	if (!intermission_running)
	if ((g_warmup_limit > 0 && time >= g_warmup_limit)
	 || (g_warmup_limit == 0 && cvar("timelimit") != 0 && time >= cvar("timelimit") * 60))
	{
		ReadyRestart();
		return;
	}

	CreatureFrame ();
	CheckRules_World ();

	AuditTeams();

	RuneMatchGivePoints();
	bot_serverframe();

	if(cvar("spawn_debugview"))
	{
		RandomSelection_Init();
		for(self = world; (self = find(self, classname, "player")); )
			RandomSelection_Add(self, 0, string_null, 1, 0);
		self = RandomSelection_chosen_ent;
		SelectSpawnPoint(0);
	}

	FOR_EACH_PLAYER(self)
		self.porto_forbidden = max(0, self.porto_forbidden - 1);
	
	if(ShouldForceFog()) {
		string newfog = GetForcedFog();
		
		if(newfog != oldfog) {
			print("Fog settings updated\n");
			
			if(oldfog)
				strunzone(oldfog);
			oldfog = strzone(newfog);
			
			FOR_EACH_REALCLIENT(self)
				stuffcmd(self, strcat("prvm_globalset client forcefog \"", newfog, "\"\n"));
		}
	} else if(oldfog) {
		print("Fog disabled\n");
		strunzone(oldfog);
		oldfog = string_null;
		
		FOR_EACH_REALCLIENT(self) {
			stuffcmd(self, "prvm_globalset client forcefog \"\"\n");
			stuffcmd(self, "defer 0 \"fog 0\"\n");
		}
	}
	
	if(totalclients >= maxclients) if(cvar("sv_autoaway_kick")) {
		entity v = GetAFKKickVictim();
		
		if(v) {
			bprint("^3", v.netname, " ^7has been kicked for being AFK for ", ftos(floor((time - v.parm_idlesince) / 60)), " minutes while the server is full\n");
			dropclient(v);
		}
	}
    
    if(time >= game_starttime)
    if(roundstate == ROUNDSTATE_PREGAME) {
        roundstate = ROUNDSTATE_GAME;
        TeamCount_RecountPlayers(TeamCount_AliveCheck_Null);
    }
    
    //for(e = world; (e = findfloat(e, sub_target_used, TRUE));)
    //    e.sub_target_used = FALSE;
}

.vector originjitter;
.vector anglesjitter;
.float anglejitter;
.string cvarfilter;
void SV_OnEntityPreSpawnFunction()
{
	if(self.cvarfilter != "")
	{
		float n, i, o, inv;
		string s, k, v;
		inv = 0;

		s = self.cvarfilter;
		if(substring(s, 0, 1) == "+")
		{
			s = substring(s, 1, -1);
		}
		else if(substring(s, 0, 1) == "-")
		{
			inv = 1;
			s = substring(s, 1, -1);
		}

		n = tokenize(s);
		for(i = 0; i < n; ++i)
		{
			s = argv(i);
			// syntax:
			// var>x
			// var<x
			// var>=x
			// var<=x
			// var==x
			// var!=x
			// var===x
			// var!==x
			if((o = strstrofs(s, ">=", 0)) >= 0)
			{
				k = substring(s, 0, o);
				v = substring(s, o+2, -1);
				if(cvar(k) < stof(v))
					goto cvar_fail;
			}
			else if((o = strstrofs(s, "<=", 0)) >= 0)
			{
				k = substring(s, 0, o);
				v = substring(s, o+2, -1);
				if(cvar(k) > stof(v))
					goto cvar_fail;
			}
			else if((o = strstrofs(s, ">", 0)) >= 0)
			{
				k = substring(s, 0, o);
				v = substring(s, o+1, -1);
				if(cvar(k) <= stof(v))
					goto cvar_fail;
			}
			else if((o = strstrofs(s, "<", 0)) >= 0)
			{
				k = substring(s, 0, o);
				v = substring(s, o+1, -1);
				if(cvar(k) >= stof(v))
					goto cvar_fail;
			}
			else if((o = strstrofs(s, "==", 0)) >= 0)
			{
				k = substring(s, 0, o);
				v = substring(s, o+2, -1);
				if(cvar(k) != stof(v))
					goto cvar_fail;
			}
			else if((o = strstrofs(s, "!=", 0)) >= 0)
			{
				k = substring(s, 0, o);
				v = substring(s, o+2, -1);
				if(cvar(k) == stof(v))
					goto cvar_fail;
			}
			else if((o = strstrofs(s, "===", 0)) >= 0)
			{
				k = substring(s, 0, o);
				v = substring(s, o+2, -1);
				if(cvar_string(k) != v)
					goto cvar_fail;
			}
			else if((o = strstrofs(s, "!==", 0)) >= 0)
			{
				k = substring(s, 0, o);
				v = substring(s, o+2, -1);
				if(cvar_string(k) == v)
					goto cvar_fail;
			}
			else if(substring(s, 0, 1) == "!")
			{
				k = substring(s, 1, -1);
				if(cvar(k))
					goto cvar_fail;
			}
			else
			{
				k = s;
				if not(cvar(k))
					goto cvar_fail;
			}
		}
		inv = !inv;
:cvar_fail
		// now inv is 1 if we want to keep the item, and 0 if we want to get rid of it
		if not(inv)
		{
			//print("cvarfilter fail\n");
			remove(self);
			return;
		}
	}

	// support special -1 and -2 angle from radiant
	if (self.angles == '0 -1 0')
		self.angles = '-90 0 0';
	else if (self.angles == '0 -2 0')
		self.angles = '+90 0 0';

	if(self.originjitter_x != 0)
		self.origin_x = self.origin_x + (random() * 2 - 1) * self.originjitter_x;
	if(self.originjitter_y != 0)
		self.origin_y = self.origin_y + (random() * 2 - 1) * self.originjitter_y;
	if(self.originjitter_z != 0)
		self.origin_z = self.origin_z + (random() * 2 - 1) * self.originjitter_z;
	if(self.anglesjitter_x != 0)
		self.angles_x = self.angles_x + (random() * 2 - 1) * self.anglesjitter_x;
	if(self.anglesjitter_y != 0)
		self.angles_y = self.angles_y + (random() * 2 - 1) * self.anglesjitter_y;
	if(self.anglesjitter_z != 0)
		self.angles_z = self.angles_z + (random() * 2 - 1) * self.anglesjitter_z;
	if(self.anglejitter != 0)
		self.angles_y = self.angles_y + (random() * 2 - 1) * self.anglejitter;
}
