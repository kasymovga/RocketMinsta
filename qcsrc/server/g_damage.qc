.float dmg;
.float dmg_edge;
.float dmg_force;
.float dmg_radius;

.entity dps_target;
.float dps_starttime;
.float dps_damage;
.float dps_hits;

float RadiusDamage_running;
vector RadiusDamage_blastorigin;

void DPS_Message(entity p, string s) {
    sprint(p, strcat("^2DPS: ^7", s, "\n"));
}

void DPS_Finish(entity plr) {
    if(!sv_dps)
        return;
    
    if(!plr)
        return;
    
    if(!plr.dps_target) {
        DPS_Message(plr, "No previous target");
        return;
    }
    
    float killtime = time - plr.dps_starttime;
    float avgdps = plr.dps_damage / killtime;
    DPS_Message(plr, strcat("Average DPS against ", plr.dps_target.netname, " ^7: ", ftos(avgdps), ". Kill scored in ", ftos(killtime), strcat(" seconds, ", ftos(plr.dps_hits), " hits")));
    
    plr.dps_target = world;
    plr.dps_hits = 0;
    plr.dps_damage = 0;
    plr.dps_starttime = 0;
}

void DPS_Record(entity plr, entity targ, float damage) {
    if(!sv_dps)
        return;
    
    if(!plr || !targ)
        return;
    
    if(plr.dps_target != targ)
        DPS_Finish(plr);
    
    if(!plr.dps_target) {
        DPS_Message(plr, strcat("Recording DPS against ", targ.netname));
        plr.dps_target = targ;
        plr.dps_starttime = time;
    }
    
    plr.dps_hits += 1;
    plr.dps_damage += damage;
}

void DPS_FinishForTarget(entity targ) {
    if(!sv_dps)
        return;
    
    if(!targ)
        return;
    
    entity plr; FOR_EACH_PLAYER(plr) {
        if(plr.dps_target == targ)
            DPS_Finish(plr);
    }
}

void inf_infect_player(entity, entity);

float Damage_DamageInfo_SendEntity(entity to, float sf)
{
	WriteByte(MSG_ENTITY, ENT_CLIENT_DAMAGEINFO);
	WriteShort(MSG_ENTITY, self.projectiledeathtype);
	WriteCoord(MSG_ENTITY, floor(self.origin_x));
	WriteCoord(MSG_ENTITY, floor(self.origin_y));
	WriteCoord(MSG_ENTITY, floor(self.origin_z));
	WriteByte(MSG_ENTITY, bound(1, self.dmg, 255));
	WriteByte(MSG_ENTITY, bound(0, self.dmg_radius, 255));
	WriteByte(MSG_ENTITY, bound(1, self.dmg_edge, 255));
	WriteShort(MSG_ENTITY, self.oldorigin_x);
    WriteByte(MSG_ENTITY, self.team-1);
	return TRUE;
}

void Damage_DamageInfo(vector org, float coredamage, float edgedamage, float rad, vector force, float deathtype, entity dmgowner)
{
	// TODO maybe call this from non-edgedamage too?
	// TODO maybe make the client do the particle effects for the weapons and the impact sounds using this info?

	entity e;

	if(!sound_allowed(MSG_BROADCAST, dmgowner))
		deathtype |= 0x8000;

	e = spawn();
	setorigin(e, org);
	e.projectiledeathtype = deathtype;
	e.dmg = coredamage;
	e.dmg_edge = edgedamage;
	e.dmg_radius = rad;
	e.dmg_force = vlen(force);
	e.velocity = force;
    e.team = dmgowner.team;
	e.oldorigin_x = compressShortVector(e.velocity);

	Net_LinkEntity(e, FALSE, 0.2, Damage_DamageInfo_SendEntity);
}

#define DAMAGE_CENTERPRINT_SPACER NEWLINES

float checkrules_firstblood;

float yoda;
float damage_goodhits;
float damage_gooddamage;
float headshot;
float damage_headshotbonus; // bonus multiplier for head shots, set to 0 after use

.float dmg_team;
.float teamkill_complain;
.float teamkill_soundtime;
.entity teamkill_soundsource;
.entity pusher;
.float taunt_soundtime;


float IsDifferentTeam(entity a, entity b)
{
	if(teams_matter)
	{
		if(a.team == b.team)
			return 0;
	}
	else
	{
		if(a == b)
			return 0;
	}
	return 1;
}

float IsFlying(entity a)
{
	if(a.flags & FL_ONGROUND)
		return 0;
	if(a.waterlevel >= WATERLEVEL_SWIMMING)
		return 0;
	traceline(a.origin, a.origin - '0 0 48', MOVE_NORMAL, a);
	if(trace_fraction < 1)
		return 0;
	return 1;
}

void UpdateFrags(entity player, float f)
{
	PlayerTeamScore_AddScore(player, f);
}

// NOTE: f=0 means still count as a (positive) kill, but count no frags for it
void W_SwitchWeapon_Force(entity e, float w);
void GiveFrags (entity attacker, entity inflictor, entity targ, float f)
{
	float w;

	// TODO route through PlayerScores instead
	if(gameover || jb_roundover) return;

	if(!prec_check_aggression(attacker, inflictor, targ)) return;

	if(f < 0)
	{
		if(targ == attacker)
		{
			// suicide
		    PlayerScore_Add(attacker, SP_SUICIDES, 1);
		}
		else
		{
			// teamkill
			PlayerScore_Add(attacker, SP_KILLS, -1); // or maybe add a teamkills field?
		}
	}
	else
	{
		// regular frag
		PlayerScore_Add(attacker, SP_KILLS, 1);
	}

	//if(targ != attacker)
		PlayerScore_Add(targ, SP_DEATHS, 1);

	if(g_arena)
		if(cvar("g_arena_roundbased"))
			return;

	if(targ != attacker) // not for suicides
	if(g_weaponarena_random)
	{
		// after a frag, choose another random weapon set
		if(inWarmupStage)
			w = warmup_start_weapons;
		else
			w = start_weapons;

		attacker.weapons = randombits(w - (w & W_WeaponBit(attacker.weapon)), g_weaponarena_random, TRUE);
		if(attacker.weapons < 0)
		{
			// error from randombits: no weapon available
			// this means we can just give ALL weapons
			attacker.weapons = w;
		}
		if not(attacker.weapons & W_WeaponBit(attacker.weapon))
			W_SwitchWeapon_Force(attacker, w_getbestweapon(attacker));
	}

	// FIXME fix the mess this is (we have REAL points now!)
	if(g_runematch)
	{
		f = RunematchHandleFrags(attacker, targ, f);
	}
	else if(g_keyhunt)
	{
		f = kh_HandleFrags(attacker, targ, f);
	}
	else if(g_lms)
	{
		// remove a life
		float tl;
		tl = PlayerScore_Add(targ, SP_LMS_LIVES, -1);
		if(tl < lms_lowest_lives)
			lms_lowest_lives = tl;
		if(tl <= 0)
		{
			if(!lms_next_place)
				lms_next_place = player_count;
			PlayerScore_Add(targ, SP_LMS_RANK, lms_next_place); // won't ever spawn again
			--lms_next_place;
		}
		f = 0;
	}
	else if(g_ctf)
	{
		if(g_ctf_ignore_frags)
			f = 0;
	}
	else if(g_freezetag || g_totaldomination || g_vip || g_jailbreak || g_clanarena)
	{
		f = 0;
	}

	attacker.totalfrags += f;

	if(f)
		UpdateFrags(attacker, f);
}

string AppendItemcodes(string s, entity player)
{
	float w;
	w = player.weapon;
	//if(w == 0)
	//	w = player.switchweapon;
	if(w == 0)
		w = player.cnt; // previous weapon!
	s = strcat(s, ftos(w));
	if(time < player.strength_finished)
		s = strcat(s, "S");
	if(time < player.invincible_finished)
		s = strcat(s, "I");
	if(player.flagcarried != world)
		s = strcat(s, "F");
	if(player.BUTTON_CHAT)
		s = strcat(s, "T");
	if(player.kh_next)
		s = strcat(s, "K");
	if(player.runes)
		s = strcat(s, "|", ftos(player.runes));
	return s;
}

void LogDeath(string mode, float deathtype, entity killer, entity killed)
{
	string s;
	if(!cvar("sv_eventlog"))
		return;
	s = strcat(":kill:", mode);
	s = strcat(s, ":", ftos(killer.playerid));
	s = strcat(s, ":", ftos(killed.playerid));
	s = strcat(s, ":type=", ftos(deathtype));
	s = strcat(s, ":items=");
	s = AppendItemcodes(s, killer);
	if(killed != killer)
	{
		s = strcat(s, ":victimitems=");
		s = AppendItemcodes(s, killed);
	}
	GameLogEcho(s);
}

.float pushltime;
.float rage;
.float lastkill;

float CheckJailDM(entity attacker, entity targ) {
    if(g_jailbreak)
    if(g_jailbreak_jail_deathmatch)
    if(targ.team == attacker.team)
    if(targ.jb_isprisoned)
    if(attacker.jb_isprisoned)
    if(!JB_JailIsOpen(JB_GetEnemyTeamOf(targ.team)))
        return TRUE;
    return FALSE;
}

void Obituary (entity attacker, entity inflictor, entity targ, float deathtype)
{
	string	s, a;
	float p, w;
    float spawnfrag;
    float jaildm;

	local float maxrage = 5;
	local float rage_timeout = 3;

	local string ragemeter;

	if(g_prec) if(inflictor.classname == "prec_rune") {
		prec_check_aggression(attacker, inflictor, targ); return; }

	if(g_jailbreak)
	if(jb_roundover) {
		attacker = world;
		
		if(targ.jb_roundlost) {
			targ.angles = jb_activecamera.angles;
			targ.angles_z = 0;
			targ.fixangle = TRUE;
		}
	}
    
    jaildm = CheckJailDM(attacker, targ);
    targ.hg_shield = 0;
    
    DPS_Finish(targ);
    if(attacker.dps_target == targ)
        DPS_Finish(attacker);
    DPS_FinishForTarget(targ);

	if(attacker.classname == "player")
	if(targ.classname == "player" && targ != attacker)
	{
		if(time - attacker.lastkill > rage_timeout)
			attacker.rage = 0;

		attacker.lastkill = time;
		attacker.rage = attacker.rage + 1;
		targ.rage = 0;

		ragemeter = "^1";

		local float i;
		i = 2;
		while(i < maxrage)
		{
			if(attacker.rage == i)
				ragemeter = strcat(ragemeter, "^0");
			else
				ragemeter = strcat(ragemeter, "");

			++i;
		}
		if(attacker.rage-1 >= maxrage)
			ragemeter = strcat(ragemeter, "");
		else
			ragemeter = strcat(ragemeter, "^0");
        
        spawnfrag = (cvar("g_spawnshieldmode") && ((time <= targ.spawnshieldtime) || (time <= attacker.spawnshieldtime)));
	}

	float _hfrag;

	if (targ.classname == "player" || targ.classname == "corpse")
	{
		if(targ.hg_power > 0)
		{
			targ.hg_power = 0;
			entity o;
			o = self;
			self = targ;
			HG_Attack();
			self = o;
		}
        
        HG_DetonateAll(targ);
        
        if(!g_freezetag && !g_jailbreak) {
            if(cvar("g_nadgets_resetonrespawn"))
                targ.hg_ammo = 0;
        }
		
		if (targ.classname == "corpse")
			s = "A corpse";
		else
			s = targ.netname;
		a = attacker.netname;

		prec_check_aggression(attacker, inflictor, targ); // only called here for point keeping

		if (targ == attacker)
		{
			if (deathtype == DEATH_TEAMCHANGE) {
				centerprint_spec(targ, strcat(DAMAGE_CENTERPRINT_SPACER, "You are now on: ", ColoredTeamName(targ.team)));
			} else if (deathtype == DEATH_AUTOTEAMCHANGE) {
				centerprint_spec(targ, strcat(DAMAGE_CENTERPRINT_SPACER, "You have been moved into a different team to improve team balance\nYou are now on: ", ColoredTeamName(targ.team)));
				return;
			} else if (deathtype == DEATH_CAMP) {
				if(sv_gentle)
					centerprint_spec(targ, strcat(DAMAGE_CENTERPRINT_SPACER, "^1Reconsider your tactics, camper!"));
				else
					centerprint_spec(targ, strcat(DAMAGE_CENTERPRINT_SPACER, "^1Die camper!"));
			} else if (deathtype == DEATH_NOAMMO) {
				if(sv_gentle)
					centerprint_spec(targ, strcat(DAMAGE_CENTERPRINT_SPACER, "^1You are reinserted into the game for running out of ammo..."));
				else
					centerprint_spec(targ, strcat(DAMAGE_CENTERPRINT_SPACER, "^1You were killed for running out of ammo..."));
			} else if (deathtype == DEATH_ROT) {
				if(sv_gentle)
					centerprint_spec(targ, strcat(DAMAGE_CENTERPRINT_SPACER, "^1You need to preserve your health"));
				else
					centerprint_spec(targ, strcat(DAMAGE_CENTERPRINT_SPACER, "^1You grew too old without taking your medicine"));
			} else if(deathtype == DEATH_MIRRORDAMAGE) {
                                if(g_prec) {
			        	if(sv_gentle)
				        	centerprint_spec(targ, strcat(DAMAGE_CENTERPRINT_SPACER, "^1Go aginst the rune carrier!"));
				        else
					        centerprint_spec(targ, strcat(DAMAGE_CENTERPRINT_SPACER, "^1Shoot the rune carrier!"));
                                } else {
			        	if(sv_gentle)
				        	centerprint_spec(targ, strcat(DAMAGE_CENTERPRINT_SPACER, "^1Don't go against team mates!"));
				        else
					        centerprint_spec(targ, strcat(DAMAGE_CENTERPRINT_SPACER, "^1Don't shoot your team mates!"));
                                }
            } else if(deathtype == DEATH_NOISE) {
                centerprint_spec(targ, "^1You were too noisy to live");
			} else {
				if(sv_gentle)
					centerprint_spec(targ, strcat(DAMAGE_CENTERPRINT_SPACER, "^1You need to be more careful!"));
				else
					centerprint_spec(targ, strcat(DAMAGE_CENTERPRINT_SPACER, "^1You killed your own dumb self!"));
			}

			if(sv_gentle) {
				if (deathtype == DEATH_CAMP)
					bprint ("^1",s, "^1 thought he found a nice camping ground\n");
				else if (deathtype == DEATH_MIRRORDAMAGE) {
                                        if(!g_prec)
				        	bprint ("^1",s, "^1 didn't become friends with the Lord of Teamplay\n");
				} else
					bprint ("^1",s, "^1 will be reinserted into the game due to his own actions\n");

				if(deathtype != DEATH_TEAMCHANGE)
				{
					LogDeath("suicide", deathtype, targ, targ);
					GiveFrags(attacker, inflictor, targ, -1);
				}
				if (targ.killcount > 2)
					bprint ("^1",s,"^1 faded after a ",ftos(targ.killcount)," point spree\n");
			} else {
				w = DEATH_WEAPONOF(deathtype);
				if(WEP_VALID(w))
				{
					w_deathtypestring = "couldn't resist the urge to self-destruct";
					w_deathtype = deathtype;
					weapon_action(w, WR_SUICIDEMESSAGE);
 					bprint("^1", s, "^1 ", w_deathtypestring, "\n");
				}
				else if (deathtype == DEATH_KILL)
					bprint ("^1",s, "^1 couldn't take it anymore\n");
				else if (deathtype == DEATH_ROT)
					bprint ("^1",s, "^1 died\n");
				else if (deathtype == DEATH_NOAMMO)
					bprint ("^7",s, "^7 committed suicide. What's the point of living without ammo?\n");
				else if (deathtype == DEATH_CAMP)
					bprint ("^1",s, "^1 thought he found a nice camping ground\n");
				else if (deathtype == DEATH_MIRRORDAMAGE) {
                                        if(!g_prec)
				        	bprint ("^1",s, "^1 didn't become friends with the Lord of Teamplay\n");
				} else if (deathtype == DEATH_CHEAT)
					bprint ("^1",s, "^1 unfairly eliminated himself\n");
				else if (deathtype == DEATH_FIRE)
					bprint ("^1",s, "^1 burned to death\n");
				else if (deathtype == DEATH_HG_NAPALM)
					bprint ("^1",s, "^1 played with fire\n");
                else if (deathtype == DEATH_NOISE)
                    bprint ("^1",s, "^1 was too noisy to live\n");
				else if (deathtype != DEATH_TEAMCHANGE)
					bprint ("^1",s, "^1 couldn't resist the urge to self-destruct\n");
					
				if(deathtype != DEATH_TEAMCHANGE)
				{
					LogDeath("suicide", deathtype, targ, targ);
					GiveFrags(attacker, inflictor, targ, -1);
				}
				if (targ.killcount > 2)
					bprint ("^1",s,"^1 ended it all after a ",ftos(targ.killcount)," kill spree\n");
			}
		}
		else if (attacker.classname == "player" || attacker.classname == "gib")
		{
			if(teams_matter && attacker.team == targ.team && !jaildm)
			{
				if(sv_gentle) {
					centerprint_spec(attacker, strcat(DAMAGE_CENTERPRINT_SPACER, "^1Moron! You went against a team mate!"));
					bprint ("^1", a, "^1 took action against a team mate\n");
				} else {
					centerprint_spec(attacker, strcat(DAMAGE_CENTERPRINT_SPACER, "^1Moron! You fragged ", s, "^1, a team mate!"));
					centerprint_spec(targ, strcat(DAMAGE_CENTERPRINT_SPACER, "^1You were fragged by ^7", a, "^1, the teamkilling moron"));
					bprint ("^1", a, "^1 mows down a team mate\n");
				}
				GiveFrags(attacker, inflictor, targ, -1);
				if (targ.killcount > 2) {
					if(sv_gentle)
						bprint ("^1",s,"'s ^1",ftos(targ.killcount)," scoring spree was ended by a team mate!\n");
					else
						bprint ("^1",s,"'s ^1",ftos(targ.killcount)," kill spree was ended by a team mate!\n");
				}
				if (attacker.killcount > 2) {
					if(sv_gentle)
						bprint ("^1",a,"^1 ended a ",ftos(attacker.killcount)," scoring spree by going against a team mate\n");
					else
						bprint ("^1",a,"^1 ended a ",ftos(attacker.killcount)," kill spree by killing a team mate\n");
				}
				attacker.killcount = 0;

				LogDeath("tk", deathtype, attacker, targ);
			}
			else
			{
				inf_infect_player(attacker, targ);

				attacker.killsound = 1;

				string blood_message, victim_message;
				if (!checkrules_firstblood)
				if(prec_check_aggression(attacker, inflictor, targ))
				{
					checkrules_firstblood = TRUE;
					if(sv_gentle)
					{
						bprint("^1",a, "^1 was the first to score", "\n");
						blood_message = "^1First point\n";
						//victim_message = "^1First victim\n";  // or First casualty
					}
					else
					{
						bprint("^1",a, "^1 drew first blood", "\n");
						//blood_message = "^1First blood\n";
						//victim_message = "^1First victim\n";  // or First casualty

						bigprint_spec(attacker, "^7First ^1Blood", "", 1);
						bigprint_spec(targ, "^7First ^0Victim", "", 1);
					}
				}

				if(sv_gentle > 0) {
					centerprint_spec(attacker, strcat(DAMAGE_CENTERPRINT_SPACER, "^4You scored against ^7", s));
					centerprint_spec(targ, strcat(DAMAGE_CENTERPRINT_SPACER, a,"^1 scored against you ^7"));
				} else {
					if(g_minstagib)
					{
                        if(spawnfrag)
                        {
                            centerprint_spec(attacker, strcat(DAMAGE_CENTERPRINT_SPACER, blood_message, "^4You ^2spawn^4fragged ^7", s));
                            centerprint_spec(targ, strcat(DAMAGE_CENTERPRINT_SPACER, victim_message, "^1You were ^2spawn^1fragged by ^7", a));
                        }
						else if(DEATH_ISWEAPON(deathtype, WEP_LASER) || DEATH_ISWEAPON(deathtype, WEP_ELECTRO))
						{
							play2(attacker, "announcer/male/awesome.wav");
					                if(prec_check_aggression(attacker, inflictor, targ))
						                PlayerScore_Add(attacker, SP_SCORE, cvar("g_rocketminsta_score_laserfrag"));
							
							if(cvar("sv_extendfragmessages"))
							{
								centerprint_spec(attacker, strcat(DAMAGE_CENTERPRINT_SPACER, blood_message, "^4You ^xF80laser^4fragged ^7", s));
								centerprint_spec(targ, strcat(DAMAGE_CENTERPRINT_SPACER, victim_message, "^1You were ^xF80laser^1fragged by ^7", a));
							}
							else
							{
								centerprint_spec(attacker, strcat(DAMAGE_CENTERPRINT_SPACER, blood_message, "^4You fragged ^7", s));
								centerprint_spec(targ, strcat(DAMAGE_CENTERPRINT_SPACER, victim_message, "^1You were fragged by ^7", a));
							}
						}
						else if(deathtype == DEATH_NOAMMO)
						{
							bprint("^1", s, "^1 was hookfragged by ", a, "\n");
					                if(prec_check_aggression(attacker, inflictor, targ))
						        	PlayerScore_Add(attacker, SP_SCORE, cvar("g_rocketminsta_score_hookfrag"));

							if(cvar("sv_extendfragmessages"))
							{
								centerprint_spec(attacker, strcat(DAMAGE_CENTERPRINT_SPACER, blood_message, "^4You ^7hook^4fragged ^7", s));
								centerprint_spec(targ, strcat(DAMAGE_CENTERPRINT_SPACER, victim_message, "^1You were ^7hook^1fragged by ^7", a));
							}
							else
							{
								centerprint_spec(attacker, strcat(DAMAGE_CENTERPRINT_SPACER, blood_message, "^4You fragged ^7", s));
								centerprint_spec(targ, strcat(DAMAGE_CENTERPRINT_SPACER, victim_message, "^1You were fragged by ^7", a));
							}

							play2(attacker, "announcer/male/awesome.wav");
							bigprint_spec(attacker, "Holy ^1Shit", "Awesome frag", 1);
					                if(prec_check_aggression(attacker, inflictor, targ))
						        	PlayerScore_Add(attacker, SP_HOOKFRAGS, 1);
						}
						else if(DEATH_ISWEAPON(deathtype, WEP_MINSTANEX))
						{
							if(cvar("sv_extendfragmessages"))
							{
								centerprint_spec(attacker, strcat(DAMAGE_CENTERPRINT_SPACER, blood_message, "^4You ^5insta^4fragged ^7", s));
								centerprint_spec(targ, strcat(DAMAGE_CENTERPRINT_SPACER, victim_message, "^1You were ^5insta^1fragged by ^7", a));
							}
							else
							{
								centerprint_spec(attacker, strcat(DAMAGE_CENTERPRINT_SPACER, blood_message, "^4You fragged ^7", s));
								centerprint_spec(targ, strcat(DAMAGE_CENTERPRINT_SPACER, victim_message, "^1You were fragged by ^7", a));
							}

							if(!g_dm && !g_tdm) if(g_minstagib) if(cvar("g_rocketminsta"))
					                        if(prec_check_aggression(attacker, inflictor, targ))
							        	PlayerScore_Add(attacker, SP_SCORE, 1);
						}
						//That's how I detect hookfrags. No, seriously!
						else if(targ.pushltime == 1337)
						{
							bprint("^1", s, "^1 was hookfragged by ", a, "\n");
					                if(prec_check_aggression(attacker, inflictor, targ))
							        PlayerScore_Add(attacker, SP_SCORE, cvar("g_rocketminsta_score_hookfrag"));
							        //centerprint(attacker, "^7Hookfrag!");

							if(cvar("sv_extendfragmessages"))
							{
								centerprint_spec(attacker, strcat(DAMAGE_CENTERPRINT_SPACER, blood_message, "^4You ^7hook^4fragged ^7", s));
								centerprint_spec(targ, strcat(DAMAGE_CENTERPRINT_SPACER, victim_message, "^1You were ^7hook^1fragged by ^7", a));
							}
							else
							{
								centerprint_spec(attacker, strcat(DAMAGE_CENTERPRINT_SPACER, blood_message, "^4You fragged ^7", s));
								centerprint_spec(targ, strcat(DAMAGE_CENTERPRINT_SPACER, victim_message, "^1You were fragged by ^7", a));
							}

                            if(prec_check_aggression(attacker, inflictor, targ))
                                PlayerScore_Add(attacker, SP_HOOKFRAGS, 1);
							play2(attacker, "announcer/male/awesome.wav");
							_hfrag = 1;
						}
						else
						{
							centerprint_spec(attacker, strcat(DAMAGE_CENTERPRINT_SPACER, blood_message, "^4You fragged ^7", s));
							centerprint_spec(targ, strcat(DAMAGE_CENTERPRINT_SPACER, victim_message, "^1You were fragged by ^7", a));
							
							if(g_vip) if(prec_check_aggression(attacker, inflictor, targ))
								PlayerScore_Add(attacker, SP_SCORE, 1);
						}
					}
					else
					{
						string tail;
						
						if(cvar("sv_extendfragmessages")) {
							tail = DamageTracker_DamageSourceName(deathtype, FALSE);
                            
							if(tail != "")
								tail = strcat(" with ^7", tail);
						}
						
						centerprint_spec(attacker, strcat(DAMAGE_CENTERPRINT_SPACER, blood_message, "^4You ", (spawnfrag? "^2spawn^4":""), "fragged ^7", s, "^4", tail));
						centerprint_spec(targ, strcat(DAMAGE_CENTERPRINT_SPACER, victim_message, "^1You were ", (spawnfrag? "^2spawn^1":""), "fragged by ^7", a, "^1", tail));
						
						if(g_vip) if(prec_check_aggression(attacker, inflictor, targ)) if(!spawnfrag)
							PlayerScore_Add(attacker, SP_SCORE, 1);
					}
					attacker.taunt_soundtime = time + 1;
				}

				if(sv_gentle) {
					bprint ("^1",s, "^1 needs a restart thanks to ", a, "\n");
				} else {
					w = DEATH_WEAPONOF(deathtype);
					if(WEP_VALID(w))
					{
						w_deathtypestring = "was blasted by";
						w_deathtype = deathtype;
						weapon_action(w, WR_KILLMESSAGE);
						p = strstrofs(w_deathtypestring, "#", 0);
						if(p < 0)
							bprint("^1", s, "^1 ", w_deathtypestring, " ", a, "\n");
						else
							bprint("^1", s, "^1 ", substring(w_deathtypestring, 0, p), a, "^1", substring(w_deathtypestring, p+1, strlen(w_deathtypestring) - (p+1)), "\n");
					}
					else if (deathtype == DEATH_TELEFRAG || deathtype == HG_TRANSLOC)
						bprint ("^1",s, "^1 was telefragged by ", a, "\n");
					else if (deathtype == DEATH_DROWN)
						bprint ("^1",s, "^1 was drowned by ", a, "\n");
					else if (deathtype == DEATH_SLIME)
						bprint ("^1",s, "^1 was slimed by ", a, "\n");
					else if (deathtype == DEATH_LAVA)
						bprint ("^1",s, "^1 was cooked by ", a, "\n");
					else if (deathtype == DEATH_FALL)
						bprint ("^1",s, "^1 was grounded by ", a, "\n");
					else if (deathtype == DEATH_SHOOTING_STAR)
						bprint ("^1",s, "^1 was shot into space by ", a, "\n");
					else if (deathtype == DEATH_SWAMP)
						bprint ("^1",s, "^1 was conserved by ", a, "\n");
					else if (deathtype == DEATH_HURTTRIGGER && inflictor.message2 != "")
					{
						if(!_hfrag)
						{
							p = strstrofs(inflictor.message2, "#", 0);
							if(p < 0)
								bprint("^1", s, "^1 ", inflictor.message2, " ", a, "\n");
							else
								bprint("^1", s, "^1 ", substring(inflictor.message2, 0, p), a, "^1", substring(inflictor.message2, p+1, strlen(inflictor.message2) - (p+1)), "\n");
						}
					}
					else if(deathtype == DEATH_TURRET)
						bprint ("^1",s, "^1 was pushed into the line of fire by ^1", a, "\n");
					else if(deathtype == DEATH_TOUCHEXPLODE)
						bprint ("^1",s, "^1 was pushed into an accident by ^1", a, "\n");
					else if(deathtype == DEATH_CHEAT)
						bprint ("^1",s, "^1 was unfairly eliminated by ^1", a, "\n");
					else if(deathtype == DEATH_FIRE)
						bprint ("^1",s, "^1 was burnt to death by ^1", a, "\n");
					else if(deathtype == DEATH_HG_NORMAL)
						bprint ("^1", s, "^1 didn't notice ", a, "^1's grenade\n");
					else if(deathtype == DEATH_HG_NAPALM)
                        bprint ("^1", s, "^1 engaged in ", a, "^1's hot napalm action\n");
                    else if(deathtype == DEATH_HG_REMOTE) {
                        if(targ == inflictor)   // fire damage does this
                            bprint ("^1", s, "^1 was incinerated by ", a, "^1's fire trap\n");
                        else
                            bprint ("^1", s, "^1 fell for ", a, "^1's trap\n");
                    } else if(deathtype == DEATH_HG_PLASMA)
                        bprint ("^1", s, "^1 was blasted by ", a, "^1's plasma bomb\n");
                    else if(deathtype == DEATH_HG_PLASMA_SHARD)
                        bprint ("^1", s, "^1 took a walk over ", a, "^1's hot plasma\n");
                    else if(deathtype == DEATH_HG_SHIELD)
                        bprint ("^1", s, "^1 suffered from death feedback induced by ", a, "^1's reflective shield\n");
                    else if(deathtype == DEATH_HG_GG)
                        bprint ("^1", s, "^1 has been outskilled by ", a, "^1's gg button, gg!\n");
					else
						bprint ("^1",s, "^1 was fragged by ", a, "\n");
				}

				if(g_ctf && targ.flagcarried)
				{
					UpdateFrags(attacker, ctf_score_value("score_kill"));
					PlayerScore_Add(attacker, SP_CTF_FCKILLS, 1);
					hudflash_teamcolor_default_spec(attacker);
					GiveFrags(attacker, inflictor, targ, 0); // for logging
				}
				else if(!spawnfrag && !jaildm)
					GiveFrags(attacker, inflictor, targ, 1);

				if (targ.killcount > 2) {
					if(sv_gentle)
						bprint ("^1",s,"'s ^1", ftos(targ.killcount), " scoring spree was ended by ", a, "\n");
					else
						bprint ("^1",s,"'s ^1", ftos(targ.killcount), " kill spree was ended by ", a, "\n");
				}

				attacker.killcount = attacker.killcount + 1;

				if (attacker.killcount > 2) {
					if(sv_gentle)
						bprint ("^1",a,"^1 made ",ftos(attacker.killcount)," scores in a row\n");
					else
						bprint ("^1",a,"^1 has ",ftos(attacker.killcount)," frags in a row\n");
				}

				LogDeath("frag", deathtype, attacker, targ);

				if (attacker.killcount == 3)
				{
					//We already have a triple kill in another context

					/*if(sv_gentle) {
						bprint (a,"^7 made a ^1TRIPLE SCORE\n");
					} else {
						bprint (a,"^7 made a ^1TRIPLE FRAG\n");
						announce(attacker, "announcer/male/03kills.wav");
						bigprint_spec(attacker, "^xFB0triple^7frag", strcat(ftos(attacker.killcount), " frags in a row"), 1);
					}*/
				}
				else if (attacker.killcount == 5)
				{
					if(sv_gentle) {
						bprint (a,"^7 unleashes ^1SCORING RAGE\n");
					} else {
						bprint (a,"^7 unleashes ^1RAGE\n");
						announce(attacker, "announcer/male/05kills.wav");
						bigprint_spec(attacker, "^xFA0Rage!", strcat(ftos(attacker.killcount), " frags in a row"), 1);
					}
				}
				else if (attacker.killcount == 10)
				{
					if(sv_gentle) {
						bprint (a,"^7 made ^1TEN SCORES IN A ROW!\n");
					} else {
						bprint (a,"^7 starts the ^1MASSACRE!\n");
						announce(attacker, "announcer/male/10kills.wav");
						bigprint_spec(attacker, "^xF80Massacre!", strcat(ftos(attacker.killcount), " frags in a row"), 1);
					}
				}
				else if (attacker.killcount == 15)
				{
					if(sv_gentle) {
						bprint (a,"^7 made ^1FIFTEEN SCORES IN A ROW!\n");
					} else {
						bprint (a,"^7 executes ^1MAYHEM!\n");
						announce(attacker, "announcer/male/15kills.wav");
						bigprint_spec(attacker, "^xF60Mayhem!", strcat(ftos(attacker.killcount), " frags in a row"), 1);
					}
				}
				else if (attacker.killcount == 20)
				{
					if(sv_gentle) {
						bprint (a,"^7 made ^1TWENTY SCORES IN A ROW!\n");
					} else {
						bprint (a,"^7 is a ^1BERSERKER!\n");
						announce(attacker, "announcer/male/20kills.wav");
						bigprint_spec(attacker, "^xF40Berserker!", strcat(ftos(attacker.killcount), " frags in a row"), 1);
					}
				}
				else if (attacker.killcount == 25)
				{
					if(sv_gentle) {
						bprint (a,"^7 made ^1TWENTY FIFE SCORES IN A ROW!\n");
					} else {
						bprint (a,"^7 inflicts ^1CARNAGE!\n");
						announce(attacker, "announcer/male/25kills.wav");
						bigprint_spec(attacker, "^xF20Carnage!", strcat(ftos(attacker.killcount), " frags in a row"), 1);
					}
				}
				else if (attacker.killcount == 30)
				{
					if(sv_gentle) {
						bprint (a,"^7 made ^1THIRTY SCORES IN A ROW!\n");
					} else {
						bprint (a,"^7 unleashes ^1ARMAGEDDON!\n");
						announce(attacker, "announcer/male/30kills.wav");
						bigprint_spec(attacker, "^1Armageddon!", strcat(ftos(attacker.killcount), " frags in a row"), 1);
					}
				}

                #define RAGESOUND announce(attacker, "porto/fire.wav");
                switch(attacker.rage) {
                    case 0:
                    case 1:
                        break;

                    case 2: RAGESOUND
                        bigprint_spec(attacker, "^2Double ^7Kill!", ragemeter, 1);
                        bprint(attacker.netname, " ^7scored a ^2DOUBLE ^7KILL!\n");
                        break;
                    case 3: RAGESOUND
                        bigprint_spec(attacker, "^3Triple ^7Kill!", ragemeter, 1);
                        bprint(attacker.netname, " ^7scored a ^3TRIPLE ^7KILL!\n");
                        break;
                    case 4: RAGESOUND
                        bigprint_spec(attacker, "^6Quad ^7Kill!", ragemeter, 1);
                        bprint(attacker.netname, " ^7scored a ^6QUAD ^7KILL!\n");
                        break;
                    case 5: RAGESOUND
                        bigprint_spec(attacker, "^5Ultra ^7Kill!", ragemeter, 1);
                        bprint(attacker.netname, " ^7scored an ^5ULTRA ^7KILL!\n");
                        break;
                    case 6: RAGESOUND
                        bigprint_spec(attacker, "^1Monster ^7Kill!", ragemeter, 1);
                        bprint(attacker.netname, " ^7scored a ^1MONSTER ^7KILL!\n");
                        break;
                    case 7: RAGESOUND
                        bigprint_spec(attacker, "^2Hax ^7Kill!", ragemeter, 1);
                        bprint(attacker.netname, " ^7scored a ^2HAX ^7KILL!\n");
                        break;
                    case 8: RAGESOUND
                        bigprint_spec(attacker, "^3Aimbot ^7Kill!", ragemeter, 1);
                        bprint(attacker.netname, " ^7scored an ^3AIMBOT ^7KILL!\n");
                        break;
                    case 9: RAGESOUND
                        bigprint_spec(attacker, "^6Fegget ^7Kill!", ragemeter, 1);
                        bprint(attacker.netname, " ^7scored a ^6FEGGET ^7KILL!\n");
                        break;
                    case 10: RAGESOUND
                        bigprint_spec(attacker, "^5Yo Momma ^7Kill!", ragemeter, 1);
                        bprint(attacker.netname, " ^7scored a ^5YO MOMMA ^7KILL!\n");
                        break;
                    case 11: RAGESOUND
                        bigprint_spec(attacker, "^xE90Potato ^7Kill!", ragemeter, 1);
                        bprint(attacker.netname, " ^7scored a ^xE90POTATO ^7KILL!\n");
                        break;
                    default: case 12: RAGESOUND
                        bigprint_spec(attacker, "^1Kill la ^7Kill!", ragemeter, 1);
                        bprint(attacker.netname, " ^7scored a ^1KILL LA ^7KILL!\n");
                        break;
                }
                #undef RAGESOUND
                
                if(g_nadgets)
                if(DEATH_ISHG(deathtype))
                    PlayerScore_Add(attacker, SP_NADEFRAGS, 1);
			}
		}
		else
		{
			centerprint_spec(targ, strcat(DAMAGE_CENTERPRINT_SPACER, "^1Watch your step!"));
			if (deathtype == DEATH_HURTTRIGGER && inflictor.message != "")
				bprint ("^1",s, "^1 ", inflictor.message, "\n");
			else if (deathtype == DEATH_DROWN)
				if(sv_gentle)
					bprint ("^1",s, "^1 was in the water for too long\n");
				else
					bprint ("^1",s, "^1 drowned\n");
			else if (deathtype == DEATH_SLIME)
				bprint ("^1",s, "^1 was slimed\n");
			else if (deathtype == DEATH_LAVA)
				if(sv_gentle)
					bprint ("^1",s, "^1 found a hot place\n");
				else
					bprint ("^1",s, "^1 turned into hot slag\n");
			else if (deathtype == DEATH_FALL)
				if(sv_gentle)
					bprint ("^1",s, "^1 tested gravity (and it worked)\n");
				else
					bprint ("^1",s, "^1 hit the ground with a crunch\n");
			else if (deathtype == DEATH_SHOOTING_STAR)
				bprint ("^1",s, "^1 became a shooting star\n");
			else if (deathtype == DEATH_SWAMP)
				if(sv_gentle)
					bprint ("^1",s, "^1 discovered a swamp\n");
				else
					bprint ("^1",s, "^1 is now conserved for centuries to come\n");
			else if(deathtype == DEATH_TURRET)
				bprint ("^1",s, "^1 was mowed down by a turret \n");
			else if(deathtype == DEATH_TOUCHEXPLODE)
				bprint ("^1",s, "^1 died in an accident\n");
			else if(deathtype == DEATH_CHEAT)
				bprint ("^1",s, "^1 was unfairly eliminated\n");
			else if(deathtype == DEATH_FIRE)
				if(sv_gentle)
					bprint ("^1",s, "^1 felt a little hot\n");
				else
					bprint ("^1",s, "^1 burnt to death\n");
			else if(!jb_roundover)
				if(sv_gentle)
					bprint ("^1",s, "^1 needs a restart\n");
				else
					bprint ("^1",s, "^1 died\n");
			
			if(!jb_roundover) {
				GiveFrags(targ, inflictor, targ, -1);
					
				if(PlayerScore_Add(targ, SP_SCORE, 0) == -5) {
					announce(targ, "announcer/male/botlike.wav");
					bigprint_spec(targ, "^0Bot^7like!", "", 1);
				}
			}

			if (targ.killcount > 2)
				if(sv_gentle)
					bprint ("^1",s,"^1 needs a restart after a ",ftos(targ.killcount)," scoring spree\n");
				else
					bprint ("^1",s,"^1 died with a ",ftos(targ.killcount)," kill spree\n");

			LogDeath("accident", deathtype, targ, targ);
		}

		targ.death_origin = targ.origin;
		if(targ != attacker)
			targ.killer_origin = attacker.origin;
		// FIXME: this should go in PutClientInServer
		if (targ.killcount)
			targ.killcount = 0;
	}
}

void VisualDamage(entity attacker, entity targ, float hdmg, float admg, float htype, vector hitloc);

.float heal_next_particle;

void HealScore(entity targ, entity healer, float heal) {
    if(targ == healer)
        return;
    
    PlayerScore_Add(healer, SP_HEALING, heal);
    PlayerScore_Add(healer, SP_SCORE, heal * cvar(strcat("g_healing_score_", gametype_ID_to_Name(game))));
}

float Heal(entity targ, entity inflictor, entity healer, float heal, float pauserot, vector hitloc) {   
    if(roundstate != ROUNDSTATE_GAME)
        heal = 0;
    
    if(g_clanarena) if(inflictor.classname != "hg_linker") {
        float lim = cvar("g_clanarena_heal_limit");
        if(lim)
            heal = max(0, min(heal, lim - targ.health));
    }
    
    heal = max(0, min(heal, g_balance_health_limit - targ.health));
    
    targ.health += heal;
    targ.pauserothealth_finished = max(targ.pauserothealth_finished, time + pauserot);
    
    if(time > targ.heal_next_particle) {
        te_heal(targ);
        targ.heal_next_particle = time + 0.2;
    }
    
    if(heal) {
        VisualDamage(healer, targ, heal, 0, VDMG_TYPE_HEAL | (headshot? VDMG_TYPE_CRIT : 0), hitloc);
        HealScore(targ, healer, heal);
        sound(targ, CHAN_TRIGGER, "misc/mediumhealth.wav", VOL_BASE, ATTN_NORM);
    }
    
    return heal;
}

void AngelHeal(entity targ, entity healer) {    
    if(g_clanarena) {
        return;
    }
    float heal = cvar("g_buffs_angel_heal");
    float healmax = cvar("g_buffs_angel_healmax");
    float healhp = max(0, min(heal, healmax - targ.health) );
    float healarm = max(0, min(heal, healmax - targ.armorvalue) );
    float pauserot = cvar ("g_buffs_angel_pauserot");
    
    targ.health += healhp;
    targ.armorvalue += healarm;

    targ.pauserothealth_finished = max(targ.pauserothealth_finished, time + pauserot);
    targ.pauserotarmor_finished = max(targ.pauserotarmor_finished, time + pauserot);
    
    if(time > targ.heal_next_particle) {
        te_heal(targ);
        targ.heal_next_particle = time + 0.2;
    }
    

    if (healhp || healarm) 
      {
        VisualDamage(healer, targ, healhp, healarm, VDMG_TYPE_HEAL);
        HealScore(targ, healer, healhp + healarm);
        sound(self, CHAN_AUTO, "kh/capture.wav", 0.4, 1.5);

        if (healer != targ) 	te_csqc_lightningarc(targ.origin, healer.origin, FALSE, healer.team);
      }
}

// these are updated by each Damage call for use in button triggering and such
entity damage_targ;
entity damage_inflictor;
entity damage_attacker;

float damage_linkmode;
entity damage_origtarget;

.float ignore_next;
.float dmg_jaildm;

void Damage_RecordDamage(entity attacker, float deathtype, float damage);

float IsHeadshot(entity targ, entity attacker, vector hitloc) {
    // find height of hit on player axis
    // if above view_ofs and below maxs, and also in the middle half of the bbox, it is head shot
    
    vector headmins, headmaxs, org;
    org = antilag_takebackorigin(targ, time - ANTILAG_LATENCY(attacker));
    headmins = org + '0.6 0 0' * targ.mins_x + '0 0.6 0' * targ.mins_y + '0 0 1' * (1.3 * targ.view_ofs_z - 0.3 * targ.maxs_z);
    headmaxs = org + '0.6 0 0' * targ.maxs_x + '0 0.6 0' * targ.maxs_y + '0 0 1' * targ.maxs_z;
    
    return trace_hits_box(railgun_start, railgun_end, headmins, headmaxs);
}

void Damage(entity targ, entity inflictor, entity attacker, float damage, float deathtype, vector hitloc, vector force)
{
	float mirrordamage;
	float mirrorforce;
	float teamdamage0;
    float jaildm;
	entity attacker_save;
	mirrordamage = 0;
	mirrorforce = 0;

	float armordamage;
	armordamage = 0;
    
	if(gameover || targ.killcount == -666)
		return;
    
    if not(damage_linkmode) {
        if(targ.hg_shield && deathtype == DEATH_HG_TRANSLOC)
        if(cvar("g_nadgets_transloc_counters_shield"))
            damage = cvar("g_nadgets_transloc_damage_shield") * Buffs_NadgetPower(attacker);
        
        if(BUFFS_PRESENT(attacker, BUFF_BASH) && !RadiusDamage_running && deathtype != DEATH_BASH && !inflictor.iscreature && !DEATH_ISHG(deathtype)) {
            Buffs_BashDamage(attacker, inflictor, targ, damage, hitloc);
        }

        if (BUFFS_PRESENT(attacker, BUFF_ZEN)) damage = damage * cvar("g_buffs_zen_damage_mult");

        
        
        if(targ.iscreature && BUFFS_PRESENT(attacker, BUFF_MEDIC) && (!DEATH_ISSPECIAL(deathtype) || deathtype == DEATH_BASH || deathtype == DEATH_ARC)) {
            if((teams_matter && attacker.team == targ.team) || attacker == targ) {
                float heal;
                
                if(deathtype == DEATH_ARC)
                    // arc scales off the original heal, so leave it as is
                    heal = damage;
                else {
                    heal = damage * cvar("g_buffs_medic_healfactor") * Buffs_BuffPower(attacker, BUFF_MEDIC);
                    
                    if(attacker == targ)
                        heal *= cvar("g_buffs_medic_selfhealfactor");
                    
                    if(damage_headshotbonus)
                    if(cvar("g_buffs_medic_headshot"))
                    if(IsHeadshot(targ, attacker, hitloc)) {
                        heal *= 1 + damage_headshotbonus;
                        headshot = TRUE;
                    }
                }
                
                heal = bound(0, cvar("g_buffs_medic_maxhealth") - targ.health, heal);
                heal = Heal(targ, inflictor, attacker, heal, cvar("g_buffs_medic_pauserot"), hitloc);
                
                if(heal)
                    Damage_RecordDamage(attacker, deathtype, heal);
                
                targ.hg_plasmalock = 0;
                
                if(attacker != targ)
                    Buffs_VampireDamage(attacker, attacker, heal * cvar("g_buffs_medic_selfhealfactor"), deathtype);
                
                if(BUFFS_PRESENT(attacker, BUFF_ARC) && deathtype != DEATH_ARC) {
                    Buffs_ArcDamage(targ, attacker, heal, deathtype);
                    Buffs_ArcDamage_Finalize();
                }
                return;
            } else if(!attacker.hg_shield)
                damage = damage * (1 - (1 - cvar("g_buffs_medic_damagefactor")) * Buffs_BuffPower(attacker, BUFF_MEDIC));
        }
        
        damage_origtarget = targ;
        if(targ.hg_linker && (deathtype != HG_TRANSLOC || cvar("g_nadgets_transloc_damage")) && deathtype != HG_GG && !DEATH_ISSPECIAL(deathtype)) {
            if(teams_matter && targ.team == attacker.team)
                return;
            
            damage_linkmode = TRUE;
            entity e, linklist = findchainentity(hg_linker, targ.hg_linker);
            float denom;
            
            for(e = linklist; e; e = e.chain) IF_HG_LINKER_APPLICABLE(e)
                ++denom;
            
            if(denom) for(e = linklist; e; e = e.chain) IF_HG_LINKER_APPLICABLE(e) {
                float d = damage / denom;
                
                if(e != targ)
                    te_csqc_lightningarc(targ.origin, e.origin, FALSE, targ.team);
                    
                damage_origtarget = e;
                Damage(e, inflictor, attacker, d * targ.hg_linker.hg_linker_factor, deathtype, hitloc, ((e == targ)? force : 0.5 * vlen(force) * normalize(e.origin - targ.origin)));
                
                if(targ.hg_linker.owner.scorekeeper)
                    HealScore(targ, targ.hg_linker.owner, max(0, d - d * targ.hg_linker.hg_linker_factor));
            }
            
            damage_linkmode = FALSE;
            return;
        }
    }

	// I just feel like there are WAY too many checks for these in this function
	// By the way, this function is one of the messiest pieces of code here, it could compete with vip.qc ;)
	float targ_is_player = (targ.classname == "player");
	float attacker_is_player = (attacker.classname == "player");
    
    if(g_jailbreak && targ_is_player && jb_roundover)   
        damage = damage * cvar("g_jailbreak_torture_damagefactor");
    else {
        jaildm = CheckJailDM(attacker, targ);
        if(jaildm)
            attacker.jb_jaildm_aggressive = TRUE;
    }
    
	local float t_oldhealth = targ.health;
	local float t_oldarmor = targ.armorvalue;

	local entity oldself;
	oldself = self;
	self = targ;
        damage_targ = targ;
        damage_inflictor = inflictor;
        damage_attacker = attacker;
		attacker_save = attacker;

	local float took_extra;
    
	if(targ_is_player)
		if(targ.hook)
			if(targ.hook.aiment)
				if(targ.hook.aiment == attacker)
					RemoveGrapplingHook(targ); // STOP THAT, you parasite!

	// special rule: gravity bomb does not hit team mates (other than for disconnecting the hook)
	if(DEATH_ISWEAPON(deathtype, WEP_HOOK) || DEATH_ISWEAPON(deathtype, WEP_TUBA))
	{
		if(targ_is_player)
			if not(IsDifferentTeam(targ, attacker))
			{
				self = oldself;
				return;
			}
	}
    
	if(deathtype == DEATH_KILL || deathtype == DEATH_TEAMCHANGE || deathtype == DEATH_AUTOTEAMCHANGE)
	{
		// These are ALWAYS lethal
		// No damage modification here
		// Instead, prepare the victim for his death...
		
		targ.armorvalue = 0;
		targ.spawnshieldtime = 0;
		targ.health = 0.9; // this is < 1
		targ.flags -= targ.flags & FL_GODMODE;
        
		damage = 100000;
	}
	else if(deathtype == DEATH_MIRRORDAMAGE || deathtype == DEATH_NOAMMO || targ.classname == "hg_grenade" || deathtype == DEATH_NOISE)
	{
		// no processing
	}
	else
	{
		if(targ_is_player) if(attacker_is_player)
		{
			if(targ != attacker)
				if(!prec_check_aggression(attacker, inflictor, targ))
				{
					attacker.typehitsound += 1;
					mirrordamage = damage * cvar("g_prec_mirrordamage");
					bigprint_spec(attacker, "", "^1You have to shoot the rune carrier!", 2);
				}
			
			if(g_inf)
				if(targ.team == COLOR_TEAM1)
					damage = damage * cvar("g_inf_damage_multiplier");

			// Chaiomanot Feb 25 2012: The below is _really_ cheap. Shame on you, author.
			if (!targ.isbot)
				if (attacker.isbot)
					damage = damage * bound(0.1, (skill + 5) * 0.1, 1);
			
			if(g_jailbreak)
            if(!jaildm)
			if not(DEATH_ISSPECIAL(deathtype)) {
				if(targ.jb_isprisoned)
					damage = damage * cvar("g_jailbreak_prisonerdamagefactor_take");
				
				switch(inflictor.jb_proj_ownerstate) {
					case JB_PROJ_OWNERSTATE_IMPRISONED:
						damage = damage * cvar("g_jailbreak_prisonerdamagefactor_deal");
						break;
						
					case JB_PROJ_OWNERSTATE_FREE:
						break;
						
					case JB_PROJ_OWNERSTATE_UNDEFINED: default:
						if(attacker.jb_isprisoned)
							damage = damage * cvar("g_jailbreak_prisonerdamagefactor_deal");
						break;
				}
			}
            
            if(deathtype == DEATH_TELEFRAG || (deathtype == HG_TRANSLOC && !cvar("g_nadgets_transloc_damage")))
            if((g_jailbreak && (attacker.jb_isprisoned || targ.jb_isprisoned)) || (g_vip && ISVIP(targ))) {
                damage = 0;
                force = '0 0 0';
            }
		}
        
		// nullify damage if teamplay is on
        if(!jaildm)
		if(deathtype != DEATH_TELEFRAG && deathtype != HG_TRANSLOC && deathtype != HG_GG)
		if(attacker_is_player)
		{
			if(targ_is_player && targ != attacker && (IS_INDEPENDENT_PLAYER(attacker) || IS_INDEPENDENT_PLAYER(targ)))
			{
				damage = 0;
				force = '0 0 0';
			}
			else if(attacker.team == targ.team)
			{
				if(teamplay == 1)
					damage = 0;
				else if(attacker != targ)
				{
					if(teamplay == 3)
						damage = 0;
					else if(teamplay == 4)
					{
						if(targ_is_player && targ.deadflag == DEAD_NO)
						{
                            float ff = cvar("g_friendlyfire");
                            if(g_clanarena) ff = ff * cvar("g_clanarena_teamdamage");
							teamdamage0 = max(attacker.dmg_team, cvar("g_teamdamage_threshold"));
							attacker.dmg_team = attacker.dmg_team + damage;
							if(attacker.dmg_team > teamdamage0)
								mirrordamage = cvar("g_mirrordamage") * (attacker.dmg_team - teamdamage0);
							mirrorforce = cvar("g_mirrordamage") * vlen(force);
							if(g_minstagib)
							{
								if(ff == 0)
									damage = 0;
							}
							else
								damage = ff * damage;
							// mirrordamage will be used LATER
						}
						else
							damage = 0;
					}
				}
			}
		}

		if(targ_is_player)
		if(attacker_is_player)
		if(attacker != targ)
		{
			targ.lms_traveled_distance = cvar("g_lms_campcheck_distance");
			attacker.lms_traveled_distance = cvar("g_lms_campcheck_distance");
		}

		if(roundstate != ROUNDSTATE_GAME && !(g_jailbreak && roundstate == ROUNDSTATE_OVER && targ.jb_isprisoned))
		if(deathtype != DEATH_HURTTRIGGER)
		{
			damage = 0;

			if(targ != attacker)
			{
				force = '0 0 0';

				if(roundstate != ROUNDSTATE_OVER) if(attacker_is_player) if(targ_is_player)
					bigprint_spec(attacker, "", "^1The round hasn't started yet, you can't inflict any damage!", 2);
			}

			/*
			if(deathtype == DEATH_HURTTRIGGER)
			{
				oldself = self;
				self = targ;
				PutClientInServer();
				self = oldself;

				if(ISVIP(targ))
				vip_ResetHealthArmor(targ);
			}
			*/
		}

		if(targ_is_player)
		if (g_minstagib)
		{
			if ((deathtype == DEATH_FALL)  ||
				(deathtype == DEATH_DROWN) ||
				(deathtype == DEATH_SLIME) ||
				(deathtype == DEATH_LAVA))
			{
				self = oldself;
				return;
			}

			local float ex = cvar("g_rocketminsta");
			local float ex_armor = cvar("g_rocketminsta_armor");
			float armor_passthrough = cvar("g_rocketminsta_armor_passthrough");

			if(ex)
			{
				if(targ.ignore_next && DEATH_ISWEAPON(deathtype, WEP_ROCKET_LAUNCHER))
				{
					damage = 0;
					targ.ignore_next = 0;
				}
				
				if(DEATH_ISWEAPON(deathtype, WEP_ROCKET_LAUNCHER))
				if(attacker != targ && cvar("g_rocketminsta_splash_selfonly"))
				{
					damage = 0;
					force = '0 0 0';
				}
			}

			if (targ.armorvalue && DEATH_ISWEAPON(deathtype, WEP_MINSTANEX) && damage && (cvar("g_balance_minstanex_damage") <= 0))
			{
				if(!ex || !ex_armor)
				{
					took_extra = 1;
					targ.armorvalue -= 1;
					centerprint_spec(targ, strcat(DAMAGE_CENTERPRINT_SPACER, "^3Remaining extra lives: ",ftos(targ.armorvalue)));
					damage = 0;
					targ.hitsound += 1;
					attacker.armorhitsound += 1; // TODO change this to a future specific hitsound for armor hit
				}
				else
				{
					if(!armor_passthrough || targ.armorvalue >= 100)
					{
						armordamage = min(100, targ.armorvalue);
						targ.armorvalue -= armordamage;
						damage = 0;
					}
					else if(armor_passthrough)
					{
						armordamage = targ.armorvalue;
						damage = (100 - targ.armorvalue) * cvar("g_rocketminsta_armor_factor");
						targ.armorvalue = 0;
					}

					attacker.armorhitsound += 1;
					targ.hitsound += 1;
					targ.ignore_next = 1;
				}
			}

			if(ex)
			{
				if (DEATH_ISWEAPON(deathtype, WEP_LASER) || DEATH_ISWEAPON(deathtype, WEP_ELECTRO))
				{
					if(targ == attacker)
					{
						damage = 0;
					}
				}
				
				if(damage)
				if(ex_armor)
				if(targ.armorvalue)
				if(!DEATH_ISWEAPON(deathtype, WEP_MINSTANEX) || (cvar("g_balance_minstanex_damage") >= 0))
				if not(DEATH_ISSPECIAL(deathtype))
				{
					armordamage = damage * cvar("g_rocketminsta_armor_factor");
					
					if(targ == attacker)
						armordamage *= cvar("g_balance_selfdamagepercent");
					else
						attacker.armorhitsound += 1;

					if(armor_passthrough)
					{
						float rest;
						rest = targ.armorvalue - armordamage;

						if(rest < 0)
							damage = -rest;
						else
							damage = 0;
					}
					else
						damage = 0;

					targ.armorvalue -= min(targ.armorvalue, armordamage);
				}
			}
			else
			{
				if (DEATH_ISWEAPON(deathtype, WEP_LASER))
				{
					damage = 0;
					if (targ != attacker)
					{
						if (targ_is_player)
							bigprint_spec(attacker, "", "^1Secondary fire inflicts no damage!", 1);
						damage = 0;
						mirrordamage = 0;
						force = '0 0 0';
						// keep mirrorforce
						attacker = targ;
					}
				}
			}
		}
        
		if(g_freeze) if(targ.frozen)
		{
            if(deathtype == DEATH_HURTTRIGGER || (damage && Freeze_CVar("teleport_out_of_lava") && (deathtype == DEATH_LAVA || deathtype == DEATH_SLIME)))
                Freeze_RespawnPlayer(targ);
            
			damage = 0;
			force = force * Freeze_CVar("frozen_force");

			if(targ.team != attacker.team || Freeze_CVar("melt_teamdamage"))
			{
				targ.meltprogress = 0;
				targ.freezetime = time;
				targ.meltprogress = 0;
				targ.revprogress = 0;
			}
		}

        // apply invincibility multiplier
        if (targ.items & IT_INVINCIBLE && !g_minstagib)
            damage = damage * cvar("g_balance_powerup_invincible_takedamage");

        if(deathtype != DEATH_ARC) {
            if not(DEATH_ISSPECIAL(deathtype))
            {
                damage *= g_weapondamagefactor;
                mirrordamage *= g_weapondamagefactor;
                force = force * g_weaponforcefactor;
                mirrorforce *= g_weaponforcefactor;
            }
            
            // apply strength multiplier
            if ((attacker.items & IT_STRENGTH) && !g_minstagib)
            {
                if(targ == attacker)
                {
                    damage = damage * cvar("g_balance_powerup_strength_selfdamage");
                    force = force * cvar("g_balance_powerup_strength_selfforce");
                }
                else
                {
                    damage = damage * cvar("g_balance_powerup_strength_damage");
                    force = force * cvar("g_balance_powerup_strength_force");
                }
            }

            if (targ == attacker) {
                damage = damage * cvar("g_balance_selfdamagepercent");	// Partial damage if the attacker hits himself
                if(g_clanarena)
                    damage = damage * cvar("g_clanarena_selfdamage");
            }

            // CTF: reduce damage/force
            if(g_ctf)
            if(targ == attacker)
            if(targ.flagcarried)
            {
                damage = damage * cvar("g_ctf_flagcarrier_selfdamage");
                force = force * cvar("g_ctf_flagcarrier_selfforce");
            }

            if(g_runematch)
            {
                // apply strength rune
                if (attacker.runes & RUNE_STRENGTH)
                {
                    if(attacker.runes & CURSE_WEAK) // have both curse & rune
                    {
                        damage = damage * cvar("g_balance_rune_strength_combo_damage");
                        force = force * cvar("g_balance_rune_strength_combo_force");
                    }
                    else
                    {
                        damage = damage * cvar("g_balance_rune_strength_damage");
                        force = force * cvar("g_balance_rune_strength_force");
                    }
                }
                else if (attacker.runes & CURSE_WEAK)
                {
                    damage = damage * cvar("g_balance_curse_weak_damage");
                    force = force * cvar("g_balance_curse_weak_force");
                }

                // apply defense rune
                if (targ.runes & RUNE_DEFENSE)
                {
                    if (targ.runes & CURSE_VULNER) // have both curse & rune
                        damage = damage * cvar("g_balance_rune_defense_combo_takedamage");
                    else
                        damage = damage * cvar("g_balance_rune_defense_takedamage");
                }
                else if (targ.runes & CURSE_VULNER)
                    damage = damage * cvar("g_balance_curse_vulner_takedamage");
            }
        }

		// count the damage
		if(attacker)
		if(!targ.deadflag)
		if(targ.takedamage == DAMAGE_AIM)
		if(targ != attacker)
		{
            if(!DEATH_ISHG(deathtype)) {
                if(targ_is_player) {
                    if(IsHeadshot(damage_origtarget, attacker, hitloc))
                        deathtype |= HITTYPE_HEADSHOT;
                } else if(targ.classname == "turret_head") {
                    deathtype |= HITTYPE_HEADSHOT;
                }
            }
            
			if(deathtype & HITTYPE_HEADSHOT)
				damage *= 1 + damage_headshotbonus;

			if(targ.iscreature && targ.deadflag == DEAD_NO && targ.classname != "body")
			{
				if(IsDifferentTeam(targ, attacker) || jaildm)
				{
					if(damage > 0)
					{
						if(targ.BUTTON_CHAT)
							attacker.typehitsound += 1;
						else if(targ.armorvalue)
                            attacker.armorhitsound += 1;
                        else
							attacker.hitsound += 1;

						damage_goodhits += 1;
						damage_gooddamage += damage;

						if not(DEATH_ISSPECIAL(deathtype))
						{
							if(!g_minstagib)
							if(IsFlying(targ))
								yoda = 1;

							if(g_minstagib)
							if(targ.items & IT_STRENGTH)
								yoda = 1;

							if(deathtype & HITTYPE_HEADSHOT)
								headshot = 1;
						}
					}
				}
				else
				{
					if(deathtype != DEATH_FIRE)
						attacker.typehitsound += 1;
					if(mirrordamage > 0)
						if(time > attacker.teamkill_complain)
						{
							attacker.teamkill_complain = time + 5;
							attacker.teamkill_soundtime = time + 0.4;
							attacker.teamkill_soundsource = targ;
						}
				}
			}
		}
	}

	// apply push
	if (self.damageforcescale)
	if (vlen(force))
	{
		self.velocity = self.velocity + self.damageforcescale * force;

		if(DEATH_ISWEAPON(deathtype, WEP_ROCKET_LAUNCHER))
			self.velocity = self.velocity * cvar("g_rocketminsta_splash_velocity_influence");
		else if(DEATH_ISWEAPON(deathtype, WEP_ELECTRO))
			self.velocity = self.velocity * cvar("g_rocketminsta_laser_velocity_influence");
		else
			self.velocity = self.velocity * cvar("g_balance_push_velocityinfluence");

		self.flags &~= FL_ONGROUND;
		UpdateCSQCProjectile(self);
	}
	// apply damage
	if(damage || (self.damageforcescale && vlen(force)))
	if(self.event_damage) {
        self.dmg_jaildm = jaildm;
        self.event_damage(inflictor, attacker, damage, deathtype, hitloc, force);
        if(t_oldhealth > self.health) {
            if(!teams_matter || self.team != attacker.team) {
                self.lastdamage = time;
                if(self.hg_stealth && self.hg_stealthalpha > 0.2) {
                    self.hg_stealth = 0;
                    self.hg_stealth_saved = 0;
                    self.hg_stealthtime = 0; // no action delay if forcefully decloaked
                }
            }
            
            entity e;
            if(g_jailbreak && self.jb_unlock_progress) {
                FOR_EACH_JB_CONTROLPOINT(e)
                    if(e.jb_capturingplayer == self)
                        e.jb_unlock_progress = bound(0, e.jb_unlock_progress - cvar("g_jailbreak_controlpoint_unlock_damage_pushback"), 1);
            } else if(g_domination && self.dom_captureprogress) {
                FOR_EACH_DOM_CONTROLPOINT(e)
                    if(e.dom_capturingplayer == self)
                        e.dom_captureprogress = bound(0, e.dom_captureprogress - cvar("g_domination_capture_damage_pushback"), 1);
            }
        }
        
        if(attacker_is_player)
        if(!targ_is_player)
        if(t_oldarmor > targ.armorvalue || t_oldhealth > targ.health) {
            float dtype = VDMG_TYPE_HIT | VDMG_TYPE_NOTPLAYERTARGET;
            if(deathtype & HITTYPE_HEADSHOT)
                dtype |= VDMG_TYPE_CRIT;
            VisualDamage(attacker, targ, min(rint(t_oldhealth - targ.health), t_oldhealth), min(rint(t_oldarmor - targ.armorvalue), t_oldarmor), dtype, hitloc);
        }
    }
	self = oldself;

	if(g_minstagib && targ_is_player && attacker_is_player)
	{
		float olddamage;
		olddamage = damage;
		
		damage = max(0, min(t_oldhealth, damage));
		armordamage = max(0, min(t_oldarmor, armordamage));
        
        if(damage || armordamage)
            VisualDamage(attacker, targ, damage, armordamage, ((deathtype & HITTYPE_HEADSHOT)? VDMG_TYPE_CRIT : VDMG_TYPE_HIT), hitloc);
        
		if(took_extra)
			armordamage = 100;

		if(attacker_is_player)
		if(g_vip) if(vip_started) if(!vip_ended) if(ISVIP(targ))
		{
			PlayerScore_Add(attacker, SP_SCORE, damage * 0.1);
			
			if(took_extra)
				PlayerScore_Add(attacker, SP_SCORE, (armordamage * 0.1));
			else
				PlayerScore_Add(attacker, SP_SCORE, (armordamage / cvar("g_rocketminsta_armor_factor")) * 0.1);

			if(attacker != targ) if(damage || armordamage)
				hudflash_teamcolor_default_spec(attacker);
		}
		
		damage = olddamage;
	}

	if(targ_is_player && attacker_is_player && attacker != targ && attacker.health > 2)
	{
		// Savage: vampire mode
		if (g_vampire)
		if (!g_minstagib)
		if (time > self.spawnshieldtime)
		{
			attacker.health += damage;
		}
		if(g_runematch)
		{
			if (attacker.runes & RUNE_VAMPIRE)
			{
			// apply vampire rune
				if (attacker.runes & CURSE_EMPATHY) // have the curse too
				{
					//attacker.health = attacker.health + damage * cvar("g_balance_rune_vampire_combo_absorb");
					attacker.health = bound(
						cvar("g_balance_curse_empathy_minhealth"), // LA: was 3, now 40
						attacker.health + damage * cvar("g_balance_rune_vampire_combo_absorb"),
						cvar("g_balance_rune_vampire_maxhealth"));	// LA: was 1000, now 500
				}
				else
				{
					//attacker.health = attacker.health + damage * cvar("g_balance_rune_vampire_absorb");
					attacker.health = bound(
						attacker.health,	// LA: was 3, but changed so that you can't lose health
											// empathy won't let you gain health in the same way...
						attacker.health + damage * cvar("g_balance_rune_vampire_absorb"),
						cvar("g_balance_rune_vampire_maxhealth"));	// LA: was 1000, now 500
					}
			}
			// apply empathy curse
			else if (attacker.runes & CURSE_EMPATHY)
			{
				attacker.health = bound(
					cvar("g_balance_curse_empathy_minhealth"), // LA: was 3, now 20
					attacker.health + damage * cvar("g_balance_curse_empathy_takedamage"),
					attacker.health);
			}
		}
	}

	// apply mirror damage if any
	if not(g_minstagib && cvar("g_rocketminsta"))
	if(mirrordamage > 0 || mirrorforce > 0)
	{
		attacker = attacker_save;
		if(g_minstagib)
			if(mirrordamage > 0)
			{
				// just lose extra LIVES, don't kill the player for mirror damage
				if(attacker.armorvalue > 0)
				{
					attacker.armorvalue = attacker.armorvalue - 1;
					centerprint_spec(attacker, strcat(DAMAGE_CENTERPRINT_SPACER, "^3Remaining extra lives: ",ftos(attacker.armorvalue)));
					attacker.hitsound += 1;
				}
				mirrordamage = 0;
			}
		force = normalize(attacker.origin + attacker.view_ofs - hitloc) * mirrorforce;
		Damage(attacker, inflictor, attacker, mirrordamage, DEATH_MIRRORDAMAGE, attacker.origin, force);
	}
}

vector NearestPointOnBox(entity box, vector org)
{
	vector m1, m2, nearest;

	m1 = box.mins + box.origin;
	m2 = box.maxs + box.origin;

	nearest_x = bound(m1_x, org_x, m2_x);
	nearest_y = bound(m1_y, org_y, m2_y);
	nearest_z = bound(m1_z, org_z, m2_z);

	return nearest;
}

.float actual_damage[WEP_COUNT]; //amount of damage done
.float max_damage[WEP_COUNT]; //the maximum damage of the weapon

void Damage_RecordDamage(entity attacker, float deathtype, float damage)
{
	float weaponid;
	weaponid = DEATH_WEAPONOF(deathtype);
    
	if not(inWarmupStage)
	if(weaponid)
    if(!DEATH_ISHG(deathtype))
    if(!g_minstagib || DEATH_ISWEAPON(deathtype, WEP_MINSTANEX))
	if(clienttype(attacker) == CLIENTTYPE_REAL)
	{
		// Track damage done and update the stat to be sent later in g_world.qc
		attacker.actual_damage[weaponid] += damage;
		attacker.damage_hits = weaponid + 64 * rint(attacker.actual_damage[weaponid]);
	}
}

.float damage_noinfo;
.float damage_nextarceffect;
float RadiusDamage (entity inflictor, entity attacker, float coredamage, float edgedamage, float rad, entity ignore, float forceintensity, float deathtype, entity directhitentity)
// Returns total damage applies to creatures
{
	entity	targ;
	float	finaldmg;
	float	power;
	vector	blastorigin;
	vector	force;
	vector  diff;
	vector  center;
	vector  nearest;
	float   total_damage_to_creatures;
	entity  next;
	float   tfloordmg;
	float   tfloorforce;

	float stat_damagedone;
	float stat_maxdamage;

	if(RadiusDamage_running)
	{
		string save;
		print("RadiusDamage called recursively!\n");
		print("Expect stuff to go HORRIBLY wrong.\n");
		print("Causing a stack trace...\n");
		save = cvar_string("prvm_backtraceforwarnings");
		cvar_set("prvm_backtraceforwarnings", "1");
		fclose(-1); // calls VM_Warning
		cvar_set("prvm_backtraceforwarnings", save);
		return 0;
	}

	RadiusDamage_running = 1;

	tfloordmg = cvar("g_throughfloor_damage");
	tfloorforce = cvar("g_throughfloor_force");

	RadiusDamage_blastorigin = blastorigin = (inflictor.origin + (inflictor.mins + inflictor.maxs) * 0.5);
	total_damage_to_creatures = 0;
    
    if(deathtype != DEATH_BASH)
    if(!inflictor.damage_noinfo && deathtype != (WEP_HOOK | HITTYPE_SECONDARY | HITTYPE_BOUNCE)) // only send gravity bomb damage once
	{
		force = inflictor.velocity;
		if(vlen(force) == 0)
			force = '0 0 -1';
		else
			force = normalize(force);
		if(forceintensity >= 0)
			Damage_DamageInfo(blastorigin, coredamage, edgedamage, rad, forceintensity * force, deathtype, attacker);
		else
			Damage_DamageInfo(blastorigin, coredamage, edgedamage, -rad, (-forceintensity) * force, deathtype, attacker);
	}

	stat_damagedone = 0;
	stat_maxdamage = 0;

	targ = findradius (blastorigin, rad);
	while (targ)
	{
		next = targ.chain;
		if (targ != inflictor)
			if (ignore != targ) if(targ.takedamage)
			{
				// LordHavoc: measure distance to nearest point on target (not origin)
				// (this guarentees 100% damage on a touch impact)
				nearest = NearestPointOnBox(targ, blastorigin);
				diff = nearest - blastorigin;
				// round up a little on the damage to ensure full damage on impacts
				// and turn the distance into a fraction of the radius
				power = 1 - ((vlen (diff) - 2) / rad);
				//bprint(" ");
				//bprint(ftos(power));
				//if (targ == attacker)
				//	print(ftos(power), "\n");
				if (power > 0)
				{
					if (power > 1)
						power = 1;
					finaldmg = coredamage * power + edgedamage * (1 - power);
					if (finaldmg > 0)
					{
						float a;
						float c;
						float hits;
						float total;
						float hitratio;
                        float forcescale;
						vector hitloc;
                        
						center = targ.origin + (targ.mins + targ.maxs) * 0.5;
						// if it's a player, use the view origin as reference
						if (targ.classname == "player")
							center = targ.origin + targ.view_ofs;
						force = normalize(center - blastorigin);
                        
                        if(cvar("g_blast_alwaysfullforce"))
                            forcescale = 1;
                        else
                            forcescale = finaldmg / coredamage;
                        
						force = force * forcescale * forceintensity;
						
						// test line of sight to multiple positions on box,
						// and do damage if any of them hit
						hits = 0;
						if (targ.classname == "player")
							total = ceil(bound(1, finaldmg, 50));
						else
							total = ceil(bound(1, finaldmg/10, 5));
						hitloc = nearest;
						c = 0;
						while (c < total)
						{
							traceline(blastorigin, nearest, MOVE_NOMONSTERS, inflictor);
							if (trace_fraction == 1 || trace_ent == targ)
							{
								hits = hits + 1;
								if (hits > 1)
									hitloc = hitloc + nearest;
								else
									hitloc = nearest;
							}
							nearest_x = targ.origin_x + targ.mins_x + random() * targ.size_x;
							nearest_y = targ.origin_y + targ.mins_y + random() * targ.size_y;
							nearest_z = targ.origin_z + targ.mins_z + random() * targ.size_z;
							c = c + 1;
						}
						nearest = hitloc * (1 / max(1, hits));
						hitratio = (hits / total);
						a = bound(0, tfloordmg + (1-tfloordmg) * hitratio, 1);
						finaldmg = finaldmg * a;
						a = bound(0, tfloorforce + (1-tfloorforce) * hitratio, 1);
						force = force * a;
						//if (targ == attacker)
						//{
						//	print("hits ", ftos(hits), " / ", ftos(total));
						//	print(" finaldmg ", ftos(finaldmg), " force ", vtos(force));
						//	print(" (", ftos(a), ")\n");
						//}
						if(hits || tfloordmg || tfloorforce)
						{
							if(targ.iscreature)
							{
								total_damage_to_creatures += finaldmg;

								if(targ.flags & FL_CLIENT)
								if(targ.deadflag == DEAD_NO)
								if(targ != attacker)
								if(!teamplay || targ.team != attacker.team)
								{
									stat_damagedone += finaldmg;
									stat_maxdamage += coredamage;
								}
							}
                            
                            if(targ == directhitentity && deathtype == DEATH_BASH) {
                                targ.vdmg_ignorenext = TRUE;
                                finaldmg = 0;
                            }
                            
                            if(targ == directhitentity || DEATH_ISSPECIAL(deathtype) || DEATH_ISHG(deathtype))
                                Damage (targ, inflictor, attacker, finaldmg, deathtype, nearest, force);
                            else
                                Damage (targ, inflictor, attacker, finaldmg, deathtype | HITTYPE_SPLASH, nearest, force);
						}
					}
				}
			}
		targ = next;
	}

	RadiusDamage_running = 0;

	Damage_RecordDamage(attacker, deathtype, min(stat_maxdamage, stat_damagedone));

	return total_damage_to_creatures;
}

.float fire_damagepersec;
.float fire_endtime;
.float fire_deathtype;
.entity fire_owner;
.float fire_hitsound;
.entity fire_burner;

void fireburner_think();

float Fire_IsBurning(entity e)
{
	return (time < e.fire_endtime);
}

.float fire_last;
#define FIRE_DELAY cvar("g_fire_damage_frequency")

float Fire_AddDamage(entity e, entity o, float d, float t, float dt)
{
	float dps;
	float maxtime, mintime, maxdamage, mindamage, maxdps, mindps, totaldamage, totaltime;

	if(e.classname == "player")
	{
		if(e.deadflag)
			return -1;
        
        if(self.jb_proj_ownerstate != JB_PROJ_OWNERSTATE_UNDEFINED)
            e.jb_proj_ownerstate = self.jb_proj_ownerstate;
	}
	else
	{
		if(!e.fire_burner)
		{
			// print("adding a fire burner to ", e.classname, "\n");
			e.fire_burner = spawn();
			e.fire_burner.classname = "fireburner";
			e.fire_burner.reset = SUB_Remove;
			e.fire_burner.think = fireburner_think;
			e.fire_burner.nextthink = time;
			e.fire_burner.owner = e;
		}
	}

	t = max(t, 0.1);
	dps = d / t;
	if(Fire_IsBurning(e))
	{
		mintime = e.fire_endtime - time;
		maxtime = max(mintime, t);

		mindps = e.fire_damagepersec;
		maxdps = max(mindps, dps);

		if(maxtime > mintime || maxdps > mindps)
		{
			mindamage = mindps * mintime;
			maxdamage = mindamage + d;

			// interval [mintime, maxtime] * [mindps, maxdps]
			// intersected with
			// [mindamage, maxdamage]
			// maximum of this!

			if(maxdamage >= maxtime * maxdps)
			{
				totaltime = maxtime;
				totaldamage = maxtime * maxdps;

				// this branch increases totaldamage if either t > mintime, or dps > mindps
			}
			else
			{
				// maxdamage is inside the interval!
				// first, try to use mindps; only if this fails, increase dps as needed
				totaltime = min(maxdamage / mindps, maxtime); // maxdamage / mindps >= mindamage / mindps = mintime
				totaldamage = maxdamage;
				// can totaldamage / totaltime be >= maxdps?
				// max(mindps, maxdamage / maxtime) >= maxdps?
				// we know maxdamage < maxtime * maxdps
				// so it cannot be

				// this branch ALWAYS increases totaldamage, but requires maxdamage < maxtime * maxdps
			}

			// total conditions for increasing:
			//     maxtime > mintime OR maxdps > mindps OR maxtime * maxdps > maxdamage
			// however:
			//     if maxtime = mintime, maxdps = mindps
			// then:
			//     maxdamage = mindamage + d
			//     mindamage = mindps * mintime = maxdps * maxtime < maxdamage!
			// so the last condition is not needed

			e.fire_damagepersec = totaldamage / totaltime;
			e.fire_endtime = time + totaltime;
			if(totaldamage > 1.2 * mindamage)
			{
				e.fire_deathtype = dt;
				if(e.fire_owner != o)
				{
					e.fire_owner = o;
					e.fire_hitsound = FALSE;
				}
			}
			return max(0, totaldamage - mindamage); // can never be negative, but to make sure
		}
		else
			return 0;
	}
	else
	{
		e.fire_damagepersec = dps;
		e.fire_endtime = time + t;
		e.fire_deathtype = dt;
		e.fire_owner = o;
		e.fire_hitsound = FALSE;
        e.fire_last = time - FIRE_DELAY;
		return d;
	}
}

void Fire_ApplyDamage(entity e)
{
	float t, d, hi, ty;

    if(time - e.fire_last < FIRE_DELAY)
        return;

	// water and slime stop fire
	if(e.waterlevel)
	if(e.watertype != CONTENT_LAVA)
		e.fire_endtime = 0;

    if(!e.fire_owner.iscreature)
        e.fire_endtime = 0;

	if not(Fire_IsBurning(e))
		return;

	t = min(time - e.fire_last, e.fire_endtime - time);
    
    if(t < 0) {
        backtrace("Abnormal fire damage tick (negative time)");
        t = 0;
    }
    
	d = e.fire_damagepersec * t;
	hi = e.fire_owner.hitsound;
	ty = e.fire_owner.typehitsound;
	Damage(e, e, e.fire_owner, d, e.fire_deathtype, e.origin, '0 0 0');
	if(e.fire_hitsound && e.fire_owner)
	{
		e.fire_owner.hitsound = hi;
		e.fire_owner.typehitsound = ty;
	}
	e.fire_hitsound = TRUE;

	Damage_RecordDamage(e.fire_owner, e.fire_deathtype, d);

	if not(IS_INDEPENDENT_PLAYER(e))
	FOR_EACH_PLAYER(other) if(e != other)
	{
		if(other.classname == "player")
		if(other.deadflag == DEAD_NO)
		if not(IS_INDEPENDENT_PLAYER(other))
		if(boxesoverlap(e.absmin, e.absmax, other.absmin, other.absmax))
		{
			t = cvar("g_balance_firetransfer_time") * (e.fire_endtime - time);
			d = cvar("g_balance_firetransfer_damage") * e.fire_damagepersec * t;
			Fire_AddDamage(other, e, d, t, e.fire_deathtype);
		}
	}
    
    e.fire_last = time;
}

void Fire_ApplyEffect(entity e)
{
	if(Fire_IsBurning(e))
		e.effects |= EF_FLAME;
	else
		e.effects &~= EF_FLAME;
}

void fireburner_think()
{
	// for players, this is done in the regular loop
	if(wasfreed(self.owner))
	{
		remove(self);
		return;
	}
	Fire_ApplyEffect(self.owner);
	if(!Fire_IsBurning(self.owner))
	{
		self.owner.fire_burner = world;
		remove(self);
		return;
	}
	Fire_ApplyDamage(self.owner);
	self.nextthink = time;
}

