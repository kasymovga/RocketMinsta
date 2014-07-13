.float minstanex_lasthit;

//<akari>
//
//    This function implements the explosive attack of minstanex
//    It is a dirty copypaste from the grenadelauncher with some modifications
//

void W_RM_Explode (void)
{
	if(other.takedamage == DAMAGE_AIM)
		if(other.classname == "player")
			if(IsDifferentTeam(self.owner, other))
				if(other.deadflag == DEAD_NO)
					if(IsFlying(other))
						announce(self.owner, "announcer/male/airshot.wav");

	self.event_damage = SUB_Null;
	self.takedamage = DAMAGE_NO;
	RadiusDamage (self, self.owner, cvar("g_rocketminsta_splash_damage"), cvar("g_rocketminsta_splash_edgedamage"), cvar("g_rocketminsta_splash_radius"), world, cvar("g_rocketminsta_splash_force"), self.projectiledeathtype, other);

	remove (self);
}

void W_RM_Touch (void)
{
	PROJECTILE_TOUCH;
	W_RM_Explode ();
}

void W_Explosive_Attack (float attacktype)
{
	float SPEED;
	SPEED = 90000000;
	
	local entity gren;

	local float expl_damage = cvar("g_rocketminsta_splash_damage") / 2; //I'm not even sure why is this here?
	local float expl_recoil;
	expl_recoil = 4;
	
	if(cvar("g_rocketminsta_norecoil"))
		expl_recoil = 0;
	
	W_SetupShot_ProjectileSize (self, '0 0 -3', '0 0 -3', FALSE, expl_recoil, "", expl_damage);
	w_shotdir = v_forward; // no TrueAim for grenades please

	//pointparticles(particleeffectnum("grenadelauncher_muzzleflash"), w_shotorg, w_shotdir * 1000, 1);

	gren = spawn ();
	gren.owner = self;
	gren.classname = "plasma_prim";
	gren.bot_dodge = TRUE;
	gren.bot_dodgerating = cvar("g_rocketminsta_splash_damage");
	gren.movetype = MOVETYPE_FLY;
	PROJECTILE_MAKETRIGGER(gren);
	
	//maybe later
	/*switch(cvar("g_rocketminsta_explostyle"))
	{
		case 1:
			gren.projectiledeathtype = WEP_ELECTRO;
			break;
		case 2:
			gren.projectiledeathtype = WEP_MINSTANEX;
			break;
		default:
			gren.projectiledeathtype = WEP_ROCKET_LAUNCHER;
	}*/
	
	gren.projectiledeathtype = attacktype;
	
	setorigin(gren, w_shotorg);
	setsize(gren, '0 0 -3', '0 0 -3');
    PROJECTILE_FIX(gren)

	gren.think = adaptor_think2use;
	gren.use = W_RM_Explode;
	gren.touch = W_RM_Touch;
	gren.velocity = w_shotdir * SPEED;
	W_SetupProjectileVelocity(gren);

	gren.angles = vectoangles (gren.velocity);
	gren.flags = FL_PROJECTILE;

	CSQCProjectile(gren, TRUE, PROJECTILE_GRENADE, TRUE);
}

//Attack function for the rage mode
void W_Hook_Attack2(void);
void W_Rage_Attack (void)
{
	//Just cast another explosive attack. For now.
	W_Explosive_Attack(WEP_ELECTRO);
}
//</akari>

float RM_TeamLaserEffect(entity pl)
{
	if(!cvar("g_rocketminsta_laser_teamcolor"))
		return PROJECTILE_ELECTRO_BEAM;
	
	switch(pl.team)
    {
		case COLOR_TEAM1:   // Red
			return PROJECTILE_RM_LASER_RED;
		case COLOR_TEAM2:   // Blue
			return PROJECTILE_RM_LASER_BLUE;
		case COLOR_TEAM3:   // Yellow
			return PROJECTILE_RM_LASER_YELLOW;
		case COLOR_TEAM4:   // Pink
			return PROJECTILE_RM_LASER_PINK;
		default:
			return PROJECTILE_ELECTRO_BEAM;
    }
}

.float goodhits;

void W_MinstaNex_Attack (void)
{
	float flying;
	flying = IsFlying(self); // do this BEFORE to make the trace values from FireRailgunBullet last

	

	yoda = 0;
	damage_goodhits = 0;
	headshot = 0;
	
	//<akari>
	//Executes the explosive attack
	
	if(cvar("g_rocketminsta"))
	{
		W_Explosive_Attack(WEP_ROCKET_LAUNCHER);
	}
	
	W_SetupShot (self, TRUE, 0, RM_SOUND_MINSTA, 0);
	FireRailgunBullet (w_shotorg, w_shotorg + w_shotdir * MAX_SHOT_DISTANCE, ((cvar("g_balance_minstanex_damage") >= 0)? cvar("g_balance_minstanex_damage") : 10000000000),
					   cvar("g_balance_minstanex_force"), 0, 0, 0, 0, WEP_MINSTANEX);
    //</akari>

	if(g_minstagib)
	{
		if(yoda)
			announce(self, "announcer/male/yoda.wav");
		
		if(headshot)
		{
			announce(self, "announcer/male/headshot.wav");
			bigprint_spec(self, "^1Head ^7shot!", "", 1);
		}
	}
	else
	{
		if(yoda && flying)
			announce(self, "announcer/male/yoda.wav");
		if(headshot)
		{
			announce(self, "announcer/male/headshot.wav");
			print("h\n");
		}
		if(damage_goodhits && self.minstanex_lasthit)
		{
			if(announce(self, "announcer/male/impressive.wav"))
				damage_goodhits = 0; // only every second time
		}
	}

	self.minstanex_lasthit = damage_goodhits;

	pointparticles(particleeffectnum("nex_muzzleflash"), w_shotorg, w_shotdir * 1000, 1);

	// teamcolor / hit beam effect
	if(teamplay)
	{
	    switch(self.team)
	    {
            case COLOR_TEAM1:   // Red
                if(damage_goodhits)
                    trailparticles(world, particleeffectnum("TE_TEI_G3RED_HIT"), w_shotorg, trace_endpos);
                else
                    trailparticles(world, particleeffectnum("TE_TEI_G3RED"), w_shotorg, trace_endpos);
                break;
            case COLOR_TEAM2:   // Blue
                if(damage_goodhits)
                    trailparticles(world, particleeffectnum("TE_TEI_G3BLUE_HIT"), w_shotorg, trace_endpos);
                else
                    trailparticles(world, particleeffectnum("TE_TEI_G3BLUE"), w_shotorg, trace_endpos);
                break;
            case COLOR_TEAM3:   // Yellow
                if(damage_goodhits)
                    trailparticles(world, particleeffectnum("TE_TEI_G3YELLOW_HIT"), w_shotorg, trace_endpos);
                else
                    trailparticles(world, particleeffectnum("TE_TEI_G3YELLOW"), w_shotorg, trace_endpos);
                break;
            case COLOR_TEAM4:   // Pink
                if(damage_goodhits)
                    trailparticles(world, particleeffectnum("TE_TEI_G3PINK_HIT"), w_shotorg, trace_endpos);
                else
                    trailparticles(world, particleeffectnum("TE_TEI_G3PINK"), w_shotorg, trace_endpos);
                break;
	    }
	}
	else
        trailparticles(world, particleeffectnum("TE_TEI_G3"), w_shotorg, trace_endpos);

	// flash and burn the wall
	if (trace_ent.solid == SOLID_BSP && !(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT))
		Damage_DamageInfo(trace_endpos, 10000, 0, 0, 800 * w_shotdir, WEP_MINSTANEX, self);

	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
	{
		if (g_minstagib)
			self.ammo_cells = self.ammo_cells - 1;
		else
			self.ammo_cells = self.ammo_cells - cvar("g_balance_minstanex_ammo");
	}
	
	if(damage_goodhits)
		self.goodhits++;
	else
		self.goodhits = 0;
	
	switch(self.goodhits)
	{
		case 3:
			bigprint_spec(self, "^5Impressive!", strcat(ftos(self.goodhits), " insta hits in a row"), 1);
			announce(self, "announcer/male/impressive.wav");
			break;
		case 7:
			bigprint_spec(self, "^5Amazing!", strcat(ftos(self.goodhits), " insta hits in a row"), 1);
			announce(self, "announcer/male/amazing.wav");
			break;
	}
}

.float minstagib_nextthink;
void minstagib_ammocheck (void)
{
	if (time < self.minstagib_nextthink || self.deadflag || gameover)
		return;

	if(g_minstagib)
	if(!cvar("g_rocketminsta"))
	if not(g_freeze && self.frozen)
	if (self.ammo_cells <= 0)
	{
		#define AMMO_DEATHMESSAGE(m) bigprint_spec(self, m, "", 1)
		
		if (self.health == 5)
		{
			//AMMO_DEATHMESSAGE("you're dead now");
			Damage(self, self, self, 5, DEATH_NOAMMO, self.origin, '0 0 0');
			announce(self, "announcer/robotic/terminated.wav");
		}
		else if (self.health == 10)
		{
			AMMO_DEATHMESSAGE("^11^7 second left to find some ammo");
			Damage(self, self, self, 5, DEATH_NOAMMO, self.origin, '0 0 0');
			announce(self, "announcer/robotic/1.wav");
		}
		else if (self.health == 20)
		{
			AMMO_DEATHMESSAGE("^12^7 seconds left to find some ammo");
			Damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
			announce(self, "announcer/robotic/2.wav");
		}
		else if (self.health == 30)
		{
			AMMO_DEATHMESSAGE("^13^7 seconds left to find some ammo");
			Damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
			announce(self, "announcer/robotic/3.wav");
		}
		else if (self.health == 40)
		{
			AMMO_DEATHMESSAGE("^14^7 seconds left to find some ammo");
			Damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
			announce(self, "announcer/robotic/4.wav");
		}
		else if (self.health == 50)
		{
			AMMO_DEATHMESSAGE("^15^7 seconds left to find some ammo");
			Damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
			announce(self, "announcer/robotic/5.wav");
		}
		else if (self.health == 60)
		{
			AMMO_DEATHMESSAGE("^36^7 seconds left to find some ammo");
			Damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
			announce(self, "announcer/robotic/6.wav");
		}
		else if (self.health == 70)
		{
			AMMO_DEATHMESSAGE("^37^7 seconds left to find some ammo");
			Damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
			announce(self, "announcer/robotic/7.wav");
		}
		else if (self.health == 80)
		{
			AMMO_DEATHMESSAGE("^38^7 seconds left to find some ammo");
			Damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
			announce(self, "announcer/robotic/8.wav");
		}
		else if (self.health == 90)
		{
			AMMO_DEATHMESSAGE("^39^7 seconds left to find some ammo");
			Damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
			announce(self, "announcer/robotic/9.wav");
		}
		else if (self.health == 100)
		{
			AMMO_DEATHMESSAGE("^310^7 seconds left to find some ammo");
			Damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
			if not(self.flags & FL_GODMODE)
				announce(self, "announcer/robotic/10.wav");
		}
	}
	
	if(!g_freeze || !self.frozen)
	if(cvar("g_rocketminsta") && cvar("g_rocketminsta_health_drain") && self.health > cvar("g_rocketminsta_health_min"))
	{
		self.health -= cvar("g_rocketminsta_health_drain");
	}
	
	self.minstagib_nextthink = time + 1;
}

void spawnfunc_weapon_minstanex (void); // defined in t_items.qc

.float rm_force;
.float rm_damage;
.float rm_edmg;

void W_RM_Alt_Explode (void)
{
	if(other.takedamage == DAMAGE_AIM)
		if(other.classname == "player")
			if(IsDifferentTeam(self.owner, other))
				if(other.deadflag == DEAD_NO)
					if(IsFlying(other))
						announce(self.owner, "announcer/male/electrobitch.wav");

	self.event_damage = SUB_Null;
	self.takedamage = DAMAGE_NO;

	RadiusDamage (self, self.owner, self.rm_damage, self.rm_edmg, cvar("g_rocketminsta_laser_radius"), world, self.rm_force, self.projectiledeathtype, other);
	remove (self);
}

void W_RM_Alt_Touch(void);

void W_RM_Alt_Touch(void)
{
	PROJECTILE_TOUCH;
	RadiusDamage (self, self.owner, self.rm_damage, self.rm_edmg, cvar("g_rocketminsta_laser_radius"), world, self.rm_force, self.projectiledeathtype, other);
	remove(self);
}

void W_RM_Alt_Attack()
{
	local entity proj;
	float counter;
	float total = cvar("g_rocketminsta_laser_count");
	float spread = cvar("g_rocketminsta_laser_spread");
	float rndspread = cvar("g_rocketminsta_laser_spread_randomize");
	counter = 0;

	W_SetupShot_ProjectileSize (self, '0 0 -3', '0 0 -3', FALSE, (cvar("g_rocketminsta_norecoil")? 0 : 2), RM_SOUND_LASER_PRIMARY, cvar("g_rocketminsta_laser_damage"));

	pointparticles(particleeffectnum("electro_muzzleflash"), w_shotorg, w_shotdir * 1000, 1);

	while(counter < total)
	{
		proj = spawn ();
		proj.classname = "plasma_prim";
		proj.owner = self;
		proj.bot_dodge = TRUE;
		
		proj.rm_force = cvar("g_rocketminsta_laser_force") / total;
		proj.rm_damage = cvar("g_rocketminsta_laser_damage") / total;
		proj.rm_edmg = proj.rm_damage;
		
		proj.bot_dodgerating = self.rm_damage;
		proj.use = W_RM_Alt_Explode;
		proj.think = adaptor_think2use;
		proj.nextthink = time + cvar("g_rocketminsta_laser_lifetime");
		proj.cnt = 3;
		PROJECTILE_MAKETRIGGER(proj);
		proj.projectiledeathtype = WEP_ELECTRO;
		setorigin(proj, w_shotorg);

		proj.movetype = MOVETYPE_BOUNCEMISSILE;
		proj.velocity = (w_shotdir + (((counter + 0.5) / total) * 2 - 1) * v_right * (spread * (rndspread? random() : 1))) * cvar("g_rocketminsta_laser_speed");
		proj.velocity_z = proj.velocity_z + cvar("g_rocketminsta_laser_zspread") * (random() - 0.5);
		W_SetupProjectileVelocity(proj);
		proj.angles = vectoangles(proj.velocity);
		proj.touch = W_RM_Alt_Touch; //W_Plasma_TouchExplode;
		setsize(proj, '0 0 -3', '0 0 -3');
		proj.flags = FL_PROJECTILE;


		CSQCProjectile(proj, TRUE, RM_TeamLaserEffect(self), TRUE);
		counter++;
	}
}

void W_RM_Alt_Attack_Single()
{
	local entity proj;
	float total = cvar("g_rocketminsta_laser_count");
	float spread = cvar("g_rocketminsta_laser_spread");

	W_SetupShot_ProjectileSize (self, '0 0 -3', '0 0 -3', FALSE, 0, RM_SOUND_LASER_SECONDARY, cvar("g_rocketminsta_laser_damage"));

	pointparticles(particleeffectnum("electro_muzzleflash"), w_shotorg, w_shotdir * 1000, 1);

	proj = spawn ();
	proj.classname = "plasma_prim";
	proj.owner = self;
	proj.bot_dodge = TRUE;
	
	proj.rm_force = cvar("g_rocketminsta_laser_force");
	proj.rm_damage = cvar("g_rocketminsta_laser_damage") / total;
	proj.rm_edmg = proj.rm_damage;
	
	proj.bot_dodgerating = self.rm_damage;
	proj.use = W_RM_Alt_Explode;
	proj.think = adaptor_think2use;
	proj.nextthink = time + cvar("g_rocketminsta_laser_lifetime");
	proj.cnt = 3;
	PROJECTILE_MAKETRIGGER(proj);
	proj.projectiledeathtype = WEP_ELECTRO;
	setorigin(proj, w_shotorg);

	proj.movetype = MOVETYPE_BOUNCEMISSILE;
	proj.velocity = w_shotdir * cvar("g_rocketminsta_laser_speed");
	W_SetupProjectileVelocity(proj);
	proj.angles = vectoangles(proj.velocity);
	proj.touch = W_RM_Alt_Touch; //W_Plasma_TouchExplode;
	setsize(proj, '0 0 -3', '0 0 -3');
	proj.flags = FL_PROJECTILE;


	CSQCProjectile(proj, TRUE, RM_TeamLaserEffect(self), TRUE);
}

.float jump_interval2;
.float held_down;

.float nextfiretime;

float w_minstanex(float req)
{
	float rapid = cvar("g_rocketminsta_laser_rapid");
	
	if (req == WR_AIM)
	{
		if(self.ammo_cells>0 && time >= self.nextfiretime)
			self.BUTTON_ATCK = bot_aim(1000000, 0, 1, FALSE);
		else
			self.BUTTON_ATCK2 = bot_aim(
				((cvar("g_rocketminsta_laser_new"))?
					cvar("g_rocketminsta_laser_speed"):
					cvar("g_balance_laser_primary_speed"))
				, 0, 
				((cvar("g_rocketminsta_laser_new"))?
					cvar("g_rocketminsta_laser_lifetime"):
					cvar("g_balance_laser_primary_lifetime")), FALSE);
	}
	else if (req == WR_THINK)
	{
		if (self.BUTTON_ATCK2 || (self.BUTTON_ATCK && !self.ammo_cells && cvar("g_rocketminsta")))
		{
			if(g_freeze)
			if(self.frozen)
				return TRUE;
			
			if(cvar("g_rocketminsta") && cvar("g_rocketminsta_laser_new"))
			{
				if (self.jump_interval <= time && !self.held_down)
				{
					if(rapid)
						self.held_down = TRUE;
					self.jump_interval = time + cvar("g_rocketminsta_laser_refire");
					self.jump_interval2 = time + cvar("g_rocketminsta_laser_rapid_delay");
					//self.goodhits = 0;
					W_RM_Alt_Attack();
				}
				else if(rapid && self.jump_interval2 <= time && self.held_down)
				{
					self.jump_interval2 = time + cvar("g_rocketminsta_laser_rapid_refire");
					//self.goodhits = 0;
					W_RM_Alt_Attack_Single();
				}
			}
			else if (self.jump_interval <= time)
			{
				self.jump_interval = time + 0.9 * W_WeaponRateFactor();
				//self.goodhits = 0;
				W_Laser_Attack(FALSE);
			}
		}
		else
			self.held_down = FALSE;
		
		if (self.BUTTON_ATCK)
		{
			if (weapon_prepareattack(0, cvar("g_balance_minstanex_refire")))
			{
				W_MinstaNex_Attack();
				weapon_thinkf(WFRAME_FIRE1, cvar("g_balance_minstanex_animtime"), w_ready);
				self.nextfiretime = time + cvar("g_balance_minstanex_refire");
			}
		}
	}
	else if (req == WR_PRECACHE)
	{
		precache_model ("models/nexflash.md3");
		
		precache_model ("models/weapons/g_minstanex.md3");
		precache_model ("models/weapons/v_minstanex.md3");
		precache_model ("models/weapons/h_minstanex.dpm");
		
		precache_model ("models/weapons/g_nex.md3");
		precache_model ("models/weapons/v_nex.md3");
		precache_model ("models/weapons/h_nex.dpm");
		
		precache_sound (RM_SOUND_MINSTA);
		precache_sound ("weapons/nexwhoosh1.wav");
		precache_sound ("weapons/nexwhoosh2.wav");
		precache_sound ("weapons/nexwhoosh3.wav");
		w_laser(WR_PRECACHE);
		
		precache_sound (RM_SOUND_LASER_PRIMARY);
		precache_sound (RM_SOUND_LASER_SECONDARY);
	}
	else if (req == WR_SETUP)
	{
		weapon_setup(WEP_MINSTANEX);
		self.minstanex_lasthit = 0;
	}
	else if (req == WR_CHECKAMMO1)
	{
		if (g_minstagib)
			return self.ammo_cells >= 1;
		else
			return self.ammo_cells >= cvar("g_balance_minstanex_ammo");
	}
	else if (req == WR_CHECKAMMO2)
		return TRUE;
	else if (req == WR_SUICIDEMESSAGE)
		//<akari>
		//Since suiciding with the nexgun is now possible, I think we should replace this message
		//w_deathtypestring = "did the impossible";
		w_deathtypestring = "should use a smaller gun";
		//</akari>
	else if (req == WR_KILLMESSAGE)
		w_deathtypestring = "has been vaporized by";
	else if (req == WR_RESETPLAYER)
	{
		self.minstanex_lasthit = 0;
	}
	return TRUE;
};

