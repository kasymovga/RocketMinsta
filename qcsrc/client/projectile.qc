.float spawntime;
.vector trail_oldorigin;
.float trail_oldtime;
.float extradata;

void SUB_Null()
{
}

void SUB_Stop()
{
	self.move_velocity = self.move_avelocity = '0 0 0';
	self.move_movetype = MOVETYPE_NONE;
}

.float count; // set if clientside projectile
.float cnt; // sound index
.float gravity;
.float snd_looping;
.float silent;

float rm_particleeffectnum(string p) {
    float n = particleeffectnum(p);
    
    if(n < 0) {
        print("ERROR: RM particle effect ", p, " missing! Will try to use a fallback. Try restarting the game to fix this problem.\n");
        
        switch(p) {
            case "RM_HG_PLASMA_TEAM1":
            case "RM_HG_PLASMA_TEAM2":
            case "RM_HG_PLASMA_TEAM3":
            case "RM_HG_PLASMA_TEAM4":
                return particleeffectnum("TR_NEXUIZPLASMA");
                
            case "RM_HG_PLASMA_SHARD_EXPLODE_TEAM1":
            case "RM_HG_PLASMA_SHARD_EXPLODE_TEAM2":
            case "RM_HG_PLASMA_SHARD_EXPLODE_TEAM3":
            case "RM_HG_PLASMA_SHARD_EXPLODE_TEAM4":
                return particleeffectnum("electro_ballexplode");
            
            case "RM_HG_PLASMA_EXPLODE_TEAM1":
            case "RM_HG_PLASMA_EXPLODE_TEAM2":
            case "RM_HG_PLASMA_EXPLODE_TEAM3":
            case "RM_HG_PLASMA_EXPLODE_TEAM4":
                return particleeffectnum("hookbomb_explode");
            
            case "RM_HG_NAPALM_FIRE_TEAM1":
            case "RM_HG_NAPALM_FIRE_TEAM2":
            case "RM_HG_NAPALM_FIRE_TEAM3":
            case "RM_HG_NAPALM_FIRE_TEAM4":
                return particleeffectnum("fire_big");
            
            case "RM_HG_NAPALM_TRAIL_TEAM1":
            case "RM_HG_NAPALM_TRAIL_TEAM2":
            case "RM_HG_NAPALM_TRAIL_TEAM3":
            case "RM_HG_NAPALM_TRAIL_TEAM4":
                return particleeffectnum("firemine");
            
            case "RM_HEAL":
                return particleeffectnum("electro_impact");
            
            case "RM_EXPLOSION":
                return particleeffectnum("rocket_explode");
        }
    }
    
    return n;
}

#define rm_particleeffectnum_team(p,t,d) rm_particleeffectnum(strcat(p "_TEAM", ftos(TeamNumber(t, d))))

float TeamNumber(float t, float d) {
    if(!rm_teamlasers)
        return d;
    
    switch(t) {
        case COLOR_TEAM1:
            return 1;
        case COLOR_TEAM2:
            return 2;
        case COLOR_TEAM3:
            return 3;
        case COLOR_TEAM4:
            return 4;
        default:
            return d;
    }
} 

.float nextparticle;
void Projectile_DrawTrail(vector to)
{
	vector from;
	float t0;
	from = self.trail_oldorigin;
	t0 = self.trail_oldtime;
	self.trail_oldorigin = to;
	self.trail_oldtime = time;

	g_minstagib = getstati(STAT_MINSTA);

	if(from == to)
	{
		switch(self.cnt)
		{
            case PROJECTILE_HG_NAPALMSHARD:
                goto flame;
            case PROJECTILE_HG_NAPALM:
			case PROJECTILE_FIREMINE:
            case PROJECTILE_HG_TRANSLOC:
				to_z += 1;
				break;
			case PROJECTILE_ELECTRO:
                //trailparticles(self, particleeffectnum("TR_NEXUIZPLASMA"), from, to);
                trailparticles(self, rm_particleeffectnum_team("RM_HG_PLASMA", self.team, 2), from, to);
                return;
            case PROJECTILE_HEAL_PARTICLE_EMITTER:
                break;
			default:
				return;
		}
	}

	switch(self.cnt)
	{
		case PROJECTILE_ROCKET:
			trailparticles(self, particleeffectnum("TR_ROCKET"), from, to);
			break;
		case PROJECTILE_CRYLINK:
			trailparticles(self, particleeffectnum("TR_CRYLINKPLASMA"), from, to);
			break;
		case PROJECTILE_CRYLINK_BOUNCING:
			trailparticles(self, particleeffectnum("TR_CRYLINKPLASMA"), from, to);
			break;
			
		case PROJECTILE_ELECTRO:
			//trailparticles(self, particleeffectnum("TR_NEXUIZPLASMA"), from, to);
            trailparticles(self, rm_particleeffectnum_team("RM_HG_PLASMA", self.team, 2), from, to);
			break;
			
		case PROJECTILE_ELECTRO_BEAM:
			trailparticles(self, particleeffectnum("TR_NEXUIZPLASMA"), from, to);
			break;

		case PROJECTILE_RM_LASER_RED:
			trailparticles(self, particleeffectnum((rm_teamlasers? "TE_TEI_G3RED_HIT" 		: "TR_NEXUIZPLASMA")), from, to);
			break;
				
		case PROJECTILE_RM_LASER_BLUE:
			trailparticles(self, particleeffectnum((rm_teamlasers? "TE_TEI_G3BLUE_HIT" 		: "TR_NEXUIZPLASMA")), from, to);
			break;
				
		case PROJECTILE_RM_LASER_YELLOW:
			trailparticles(self, particleeffectnum((rm_teamlasers? "TE_TEI_G3YELLOW_HIT" 	: "TR_NEXUIZPLASMA")), from, to);
			break;
				
		case PROJECTILE_RM_LASER_PINK:
			trailparticles(self, particleeffectnum((rm_teamlasers? "TE_TEI_G3PINK_HIT" 		: "TR_NEXUIZPLASMA")), from, to);
			break;
			
		case PROJECTILE_GRENADE:
			if(g_minstagib)
				trailparticles(self, particleeffectnum("TR_NEXUIZPLASMA"), from, to);
			else
				trailparticles(self, particleeffectnum("TR_KNIGHTSPIKE"), from, to);
			break;
		case PROJECTILE_GRENADE_BOUNCING: case PROJECTILE_HG_GENERIC:
			trailparticles(self, particleeffectnum("TR_KNIGHTSPIKE"), from, to);
			break;
        case PROJECTILE_HG_PLASMA:
            trailparticles(self, rm_particleeffectnum_team("RM_HG_PLASMA", self.team, 2), from, to);
            break;
        case PROJECTILE_HG_LASER:
            trailparticles(self, rm_particleeffectnum_team("RM_HG_PLASMA", self.team, 1), from, to);
            break;
        case PROJECTILE_HG_TRANSLOC:
            if(!rm_teamlasers)
                return trailparticles(self, particleeffectnum("TE_TEI_G3PINK_HIT"), from, to);
        
            switch(self.team) {
                case COLOR_TEAM1:           trailparticles(self, particleeffectnum("TE_TEI_G3RED_HIT"),     from, to); break;
                case COLOR_TEAM2:           trailparticles(self, particleeffectnum("TE_TEI_G3BLUE_HIT"),    from, to); break;
                case COLOR_TEAM3:           trailparticles(self, particleeffectnum("TE_TEI_G3YELLOW_HIT"),  from, to); break;
                case COLOR_TEAM4: default:  trailparticles(self, particleeffectnum("TE_TEI_G3PINK_HIT"),    from, to); break;
            } break;
		case PROJECTILE_PORTO_RED:
			trailparticles(self, particleeffectnum("TR_WIZSPIKE"), from, to);
			break;
		case PROJECTILE_PORTO_BLUE:
			trailparticles(self, particleeffectnum("TR_WIZSPIKE"), from, to);
			break;
		case PROJECTILE_HOOKBOMB:
			trailparticles(self, particleeffectnum("TR_KNIGHTSPIKE"), from, to);
			break;
		case PROJECTILE_HAGAR:  case PROJECTILE_HG_REMOTE:
			trailparticles(self, particleeffectnum("TR_GRENADE"), from, to);
			break;
		case PROJECTILE_HAGAR_BOUNCING:
			trailparticles(self, particleeffectnum("TR_GRENADE"), from, to);
			break;
		case PROJECTILE_BULLET:
			trailparticles(self, particleeffectnum("tr_bullet"), from, to);
			break;
		case PROJECTILE_BULLET_GLOWING:
			trailparticles(self, particleeffectnum("tr_rifle"), from, to);
			break;
		case PROJECTILE_FIREMINE:
			trailparticles(self, particleeffectnum("firemine"), from, to);
			break;
        case PROJECTILE_HG_NAPALM:
            trailparticles(self, rm_particleeffectnum_team("RM_HG_NAPALM_TRAIL", self.team, 1), from, to);
            break;
		case PROJECTILE_FIREBALL:
			trailparticles(self, particleeffectnum("fireball"), from, to);
			break;
        case PROJECTILE_HG_NAPALMSHARD:
            trailparticles(self, rm_particleeffectnum_team("RM_HG_NAPALM_TRAIL", self.team, 1), from, to);
:flame
            if(time >= self.nextparticle) {
                vector v = randomvec();
                v_z = (v_z + 1) * 0.25;
                pointparticles(rm_particleeffectnum_team("RM_HG_NAPALM_FIRE", self.team, 1), self.origin + v * self.extradata * 0.7, '0 0 0', 1);
                self.nextparticle = time + 0.15 + random() * 0.15;
            }
            break;
        case PROJECTILE_HEAL_PARTICLE_EMITTER:
            if(time >= self.nextparticle) {
                vector v = randomvec();
                pointparticles(rm_particleeffectnum("RM_HEAL"), self.origin + v * self.extradata * 0.5, '0 0 0', 1);
                self.nextparticle = time + 0.15 + random() * 0.15;
            }
            break;
		default:
			break;
	}
}

void Projectile_Draw()
{
	vector rot;
	vector trailorigin;
	float f;
	float drawn;
	float t;

	f = self.move_flags;

	if(self.count & 0x80)
	{
		//self.move_flags &~= FL_ONGROUND;
		Movetype_Physics_MatchServer();
		if(!(self.move_flags & FL_ONGROUND))
			self.angles = vectoangles(self.velocity);
	}
	else
	{
		InterpolateOrigin_Do();
	}

	if(self.count & 0x80)
	{
		drawn = (time >= self.spawntime - 0.02);
		t = max(time, self.spawntime);
	}
	else
	{
		drawn = (self.iflags & IFLAG_VALID);
		t = time;
	}

	if(!(f & FL_ONGROUND))
	{
		rot = '0 0 0';
		switch(self.cnt)
		{
			/*
			case PROJECTILE_GRENADE:
				rot = '-2000 0 0'; // forward
				break;
			*/
			
			case PROJECTILE_HG_GENERIC:
			case PROJECTILE_HG_NAPALM:
            //case PROJECTILE_HG_REMOTE:
			//case PROJECTILE_HG_PLASMA:
			case PROJECTILE_GRENADE_BOUNCING:
				rot = '0 -1000 0'; // sideways
				break;
			case PROJECTILE_HOOKBOMB:
				rot = '1000 0 0'; // forward
				break;
			default:
				break;
		}
		self.angles = AnglesTransform_Multiply(self.angles, rot * (t - self.spawntime));
	}

	fixedmakevectors(self.angles);

	trailorigin = self.origin;
	switch(self.cnt)
	{
		case PROJECTILE_GRENADE:
		case PROJECTILE_GRENADE_BOUNCING:
		case PROJECTILE_HG_GENERIC:
        case PROJECTILE_HG_PLASMA:
		case PROJECTILE_HG_NAPALM:
        case PROJECTILE_HG_TRANSLOC:
        case PROJECTILE_HG_REMOTE:
        case PROJECTILE_HG_LASER:
			trailorigin += v_right * 1 + v_forward * -10;
			break;
		default:
			break;
	}
	if(drawn)
		Projectile_DrawTrail(trailorigin);
	else
	{
		self.trail_oldorigin = trailorigin;
		self.trail_oldtime = time;
	}

	if(!drawn)
		return;

	switch(self.cnt)
	{
		/*
		case PROJECTILE_BULLET_GLOWING:
			R_AddDynamicLight(self.origin, 50, '1 1 0');
			break;
		*/
		default:
			break;
	}

	self.renderflags = 0;

	R_AddEntity(self);
}

void loopsound(entity e, float ch, string samp, float vol, float attn)
{
	if(self.silent)
		return;

	sound(e, ch, samp, vol, attn);
	e.snd_looping = 1;
}

void Ent_RemoveProjectile()
{
	if(self.snd_looping)
		sound(self, CHAN_PROJECTILE, "misc/null.wav", VOL_BASE, ATTN_NORM);

	if(self.count & 0x80)
	{
		tracebox(self.origin, self.mins, self.maxs, self.origin + self.velocity * 0.05, MOVE_NORMAL, self);
		Projectile_DrawTrail(trace_endpos);
	}
}

void Ent_Projectile()
{
	float f;

	// projectile properties:
	//   kind (interpolated, or clientside)
	//
	//   modelindex
	//   origin
	//   scale
	//   if clientside:
	//     velocity
	//     gravity
	//   soundindex (hardcoded list)
	//   effects
	//
	// projectiles don't send angles, because they always follow the velocity
	
	f = ReadByte();
	self.count = (f & 0x80);
	self.iflags = (self.iflags & IFLAG_INTERNALMASK) | IFLAG_AUTOANGLES | IFLAG_ANGLES;
	self.solid = SOLID_TRIGGER;
	//self.effects = EF_NOMODELFLAGS;

	// this should make collisions with bmodels more exact, but it leads to
	// projectiles no longer being able to lie on a bmodel
	self.move_nomonsters = MOVE_WORLDONLY;
	if(f & 0x40)
		self.move_flags |= FL_ONGROUND;
	else
		self.move_flags &~= FL_ONGROUND;

	if(!self.move_time)
	{
		// for some unknown reason, we don't need to care for
		// sv_gameplayfix_delayprojectiles here.
		self.move_time = time;
		self.spawntime = time;
	}
	else
		self.move_time = max(self.move_time, time);

	if(!(self.count & 0x80))
		InterpolateOrigin_Undo();

	if(f & 1)
	{
		self.origin_x = ReadCoord();
		self.origin_y = ReadCoord();
		self.origin_z = ReadCoord();
		if(self.count & 0x80)
		{
			self.velocity_x = ReadCoord();
			self.velocity_y = ReadCoord();
			self.velocity_z = ReadCoord();
			self.gravity = ReadCoord();

			self.move_origin = self.origin;
			self.move_velocity = self.velocity;
		}

		if(time == self.spawntime || (self.count & 0x80) || (f & 0x20))
			self.trail_oldorigin = self.origin;
	}

	if(f & 2)
	{
		self.cnt = ReadByte();
        self.team = ReadByte() - 1;

        if(self.cnt == PROJECTILE_HG_NAPALMSHARD ||
           self.cnt == PROJECTILE_ELECTRO ||
           self.cnt == PROJECTILE_HEAL_PARTICLE_EMITTER)
            self.extradata = ReadByte();

		self.silent = (self.cnt & 0x80);
		self.cnt = (self.cnt & 0x7F);

		self.scale = 1;
        
		switch(self.cnt)
		{
			case PROJECTILE_ELECTRO: setmodel(self, "models/ebomb.mdl"); break;
			case PROJECTILE_ROCKET: setmodel(self, "models/rocket.md3"); self.scale = 2; break;
			case PROJECTILE_BULLET: setmodel(self, "models/tracer.mdl"); break;
			case PROJECTILE_BULLET_GLOWING: setmodel(self, "models/tracer.mdl"); break;
			case PROJECTILE_CRYLINK: setmodel(self, "models/plasmatrail.mdl"); break;
			case PROJECTILE_CRYLINK_BOUNCING: setmodel(self, "models/plasmatrail.mdl"); break;
			case PROJECTILE_RM_LASER_RED:
			case PROJECTILE_RM_LASER_BLUE:
			case PROJECTILE_RM_LASER_YELLOW:
			case PROJECTILE_RM_LASER_PINK:
			case PROJECTILE_ELECTRO_BEAM: setmodel(self, "models/elaser.mdl"); break;
			case PROJECTILE_GRENADE: if(!g_minstagib) setmodel(self, "models/grenademodel.md3"); break;
			case PROJECTILE_GRENADE_BOUNCING: if(!g_minstagib) setmodel(self, "models/grenademodel.md3"); break;
			case PROJECTILE_HG_GENERIC: case PROJECTILE_HG_NAPALM: case PROJECTILE_HG_PLASMA:
                setmodel(self, "models/grenademodel.md3");
                self.skin = TeamColorSkin(self.team);
                break;
            case PROJECTILE_HG_REMOTE:
                self.alpha = 1;
                setmodel(self, "models/mine.md3");
                self.skin = TeamColorSkin(self.team);
                break;
            case PROJECTILE_HG_LASER: setmodel(self, "models/elaser.mdl"); break;
            case PROJECTILE_HG_TRANSLOC: setmodel(self, "models/runematch/rune.mdl"); self.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_PLAYERCLIP; break;
			case PROJECTILE_LASER: setmodel(self, "models/laser.mdl"); break;
			case PROJECTILE_HLAC: setmodel(self, "models/hlac_bullet.md3"); break;
			case PROJECTILE_PORTO_RED: setmodel(self, "models/grenademodel.md3"); self.scale = 4; break;
			case PROJECTILE_PORTO_BLUE: setmodel(self, "models/grenademodel.md3"); self.scale = 4; break;
			case PROJECTILE_HOOKBOMB: setmodel(self, "models/grenademodel.md3"); break;
			case PROJECTILE_HAGAR: setmodel(self, "models/hagarmissile.mdl"); self.scale = 0.4; break;
			case PROJECTILE_HAGAR_BOUNCING: setmodel(self, "models/hagarmissile.mdl"); self.scale = 0.4; break;
			case PROJECTILE_FIREBALL: self.model = ""; self.modelindex = 0; break; // particle effect is good enough
			case PROJECTILE_FIREMINE: self.model = ""; self.modelindex = 0; break; // particle effect is good enough
            case PROJECTILE_HG_NAPALMSHARD: case PROJECTILE_HEAL_PARTICLE_EMITTER: self.model = ""; self.modelindex = 0; break;
			default:
				error("Received invalid CSQC projectile, can't work with this!");
				break;
		}

		self.mins = '0 0 0';
		self.maxs = '0 0 0';
		self.colormod = '0 0 0';
		self.move_touch = SUB_Stop;
		self.move_movetype = MOVETYPE_TOSS;
        
        if(self.cnt == PROJECTILE_HG_TRANSLOC)
            self.colormod = '1 1 1' * 0.3 + GetTeamRGB(self.team) * 0.7;
        
		switch(self.cnt)
		{
			case PROJECTILE_ELECTRO:
				// only new engines support sound moving with object
				loopsound(self, CHAN_PROJECTILE, "weapons/electro_fly.wav", VOL_BASE, ATTN_NORM);
				self.mins = '0 0 -3';
				self.maxs = '0 0 -3';
				self.move_movetype = MOVETYPE_BOUNCE;
				self.move_touch = SUB_Null;
				break;
			case PROJECTILE_ROCKET:
				loopsound(self, CHAN_PROJECTILE, "weapons/rocket_fly.wav", VOL_BASE, ATTN_NORM);
				self.mins = '-3 -3 -3';
				self.maxs = '3 3 3';
				break;
			case PROJECTILE_GRENADE:
				self.mins = '0 0 -3';
				self.maxs = '0 0 -3';
				break;
			case PROJECTILE_GRENADE_BOUNCING:
			case PROJECTILE_HG_GENERIC:
            case PROJECTILE_HG_PLASMA:
			case PROJECTILE_HG_NAPALM:
            case PROJECTILE_HG_TRANSLOC:
            case PROJECTILE_HG_REMOTE:
            case PROJECTILE_HG_LASER:
                if(g_nadgets == 2) {   // g_nadgets_oldhitboxes
                    self.mins = '0 0 -3';
                    self.maxs = '0 0 -3';
                } else {
                    self.mins = '-8 -4 -3';
                    self.maxs = ' 8  4  3';
                }
                
                self.move_movetype = MOVETYPE_BOUNCE;
                self.move_touch = SUB_Null;
				break;
			case PROJECTILE_PORTO_RED:
				self.colormod = '2 1 1';
				self.alpha = 0.5;
				self.move_movetype = MOVETYPE_BOUNCE;
				self.move_touch = SUB_Null;
				break;
			case PROJECTILE_PORTO_BLUE:
				self.colormod = '1 1 2';
				self.alpha = 0.5;
				self.move_movetype = MOVETYPE_BOUNCE;
				self.move_touch = SUB_Null;
				break;
			case PROJECTILE_HAGAR_BOUNCING:
				self.move_movetype = MOVETYPE_BOUNCE;
				self.move_touch = SUB_Null;
				break;
			case PROJECTILE_CRYLINK_BOUNCING:
				self.move_movetype = MOVETYPE_BOUNCE;
				self.move_touch = SUB_Null;
				break;
			case PROJECTILE_FIREBALL:
				loopsound(self, CHAN_PROJECTILE, "weapons/fireball_fly2.wav", VOL_BASE, ATTN_NORM);
				self.mins = '-16 -16 -16';
				self.maxs = '16 16 16';
				break;
            case PROJECTILE_HG_NAPALMSHARD:
			case PROJECTILE_FIREMINE:
				loopsound(self, CHAN_PROJECTILE, "weapons/fire_burn.wav", VOL_BASE, ATTN_NORM);
				self.move_movetype = MOVETYPE_BOUNCE;
				self.move_touch = SUB_Null;
				self.mins = '-4 -4 -4';
				self.maxs = '4 4 4';
				break;
			default:
				break;
		}
	}

	if(self.gravity)
	{
		if(self.move_movetype == MOVETYPE_FLY)
			self.move_movetype = MOVETYPE_TOSS;
		if(self.move_movetype == MOVETYPE_BOUNCEMISSILE)
			self.move_movetype = MOVETYPE_BOUNCE;
	}
	else
	{
		if(self.move_movetype == MOVETYPE_TOSS)
			self.move_movetype = MOVETYPE_FLY;
		if(self.move_movetype == MOVETYPE_BOUNCE)
			self.move_movetype = MOVETYPE_BOUNCEMISSILE;
	}

	if(!(self.count & 0x80))
		InterpolateOrigin_Note();
	
	self.draw = Projectile_Draw;
	self.entremove = Ent_RemoveProjectile;
}

void Projectile_Precache()
{
	precache_model("models/ebomb.mdl");
	precache_model("models/elaser.mdl");
	precache_model("models/grenademodel.md3");
	precache_model("models/mine.md3");
	precache_model("models/hagarmissile.mdl");
	precache_model("models/hlac_bullet.md3");
	precache_model("models/laser.mdl");
	precache_model("models/plasmatrail.mdl");
	precache_model("models/rocket.md3");
	precache_model("models/tracer.mdl");
    precache_model("models/runematch/rune.mdl");
	precache_sound("weapons/electro_fly.wav");
	precache_sound("weapons/rocket_fly.wav");
	precache_sound("weapons/fire_burn.wav");
	precache_sound("weapons/fireball_fly2.wav");
}
