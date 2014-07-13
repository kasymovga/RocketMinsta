void vip_ResetVIPInfo();

.void() vip_updatestate_f;
.void() vip_regenhealth_f;
.void() vip_regenarmor_f;

.float vip_healthregentime;
.float vip_armorregentime;

.float vip_armorregen_next;
.float vip_healthregen_next;
.float vip_grenregen_next;

entity vip_sg_startroundentity;

void vip_removegem(entity g)
{
	remove(g.enemy);
	remove(g);
}

void vip_ClearSoulGems()
{
	if(vip_redgem)
		vip_removegem(vip_redgem);
	
	if(vip_bluegem)
		vip_removegem(vip_bluegem);
}

void vip_RespawnSoulGems()
{
	if(!vip_soulgem)
		return;
	
	vip_redgem.reset2();
	vip_bluegem.reset2();
}

void vip_delayedinit()
{
	if(vip_soulgem)
	{
		if(!vip_redgem || !vip_bluegem)
		{
			bprint("^5Can't spawn soulgems on this map, falling back to random selection!\n");
			vip_ClearSoulGems();
			vip_soulgem = 0;
		}
	}
	
	if(inWarmupStage)
		vip_AssignVIPs();
	else
		defer(time + cvar("g_start_delay"), vip_AssignVIPs);
	
	vip_started = !vip_soulgem;
}

vector vip_SoulGemColormod(float theteam)
{
	switch(theteam)
	{
		case COLOR_TEAM1:
			return '1 .8 .8';
		case COLOR_TEAM2:
			return '.8 .8 1';
		default:
			return '.2 .2 .2';
	}
}

vector vip_SoulGemColormod2(float theteam)
{
	switch(theteam)
	{
		case COLOR_TEAM1:
			return '1 .4 .4';
		case COLOR_TEAM2:
			return '.4 .4 1';
		default:
			return '.1 .1 .1';
	}
}

float vip_SoulGemGlow(float theteam) {
	switch(theteam) {
		case COLOR_TEAM1:
			return 251;
		case COLOR_TEAM2:
			return 210;
		default:
			return 0;
	}
}

void vip_SoulGem_think() {
	self.glow_size = 256 + cos(time * 2) * 64;
	self.nextthink = time + 0.1;
}

void vip_SoulGem_touch()
{
	if(other.classname != "player")
		return;
	
	if(self.gem_pickedup)
		return;
	
	if(other.team != self.team)
		return;
	
	switch(other.team)
	{
		case COLOR_TEAM1:
			vip_AssignCustomRedVIP(other);
			break;
		case COLOR_TEAM2:
			vip_AssignCustomBlueVIP(other);
			break;
	}
	
	if(redvip && bluevip)
	{
		local entity e;
		FOR_EACH_PLAYER(e)
		{
			bigprint_clear_spec(e);
			bigprint_spec(e, "^5Begin!", "", 1);
			
			shooting_forbidden = FALSE;
			
			local entity oldself;
			oldself = self;
			self = e;
			PutClientInServer();
            HG_ResetState(self);
			self = oldself;
			
			if(ISVIP(e))
				vip_ResetHealthArmor(e);
		}
		vip_started = 1;
		vip_ended = 0;
        roundstate = ROUNDSTATE_GAME;
	}
	
	self.gem_pickedup = 1;
	self.alpha = 0;
	self.enemy.alpha = 0;
	self.colormod = vip_SoulGemColormod(-self.team);
	self.enemy.colormod = vip_SoulGemColormod2(-self.team);
	
	if(self.waypointsprite_attached)
		WaypointSprite_Kill(self.waypointsprite_attached);
}

void WHAT_THE_FUCK_think()
{
	vip_SpawnSoulGem(self.origin, self.team);
	remove(self);
}

void vip_SoulGem_reset()
{
	self.gem_pickedup = 0;
	self.alpha = self.enemy.alpha = 0.8;
	self.colormod = vip_SoulGemColormod(self.team);
	self.enemy.colormod = vip_SoulGemColormod2(self.team);
	
	// "run here" waypoint
	if(!self.waypointsprite_attached) {
		WaypointSprite_Spawn("RUN HERE TO BECOME THE VIP!", 0, 0, self, '0 0 64', world, self.team, self, waypointsprite_attached, TRUE);
        WaypointSprite_UpdateTextColors(self.waypointsprite_attached, '1 0.3 0.6', '0 0 0', '0 0 0');
    }
}

void vip_SpawnSoulGem(vector orig, float theteam)
{
	if(!vip_soulgem)
		return;
	
	bprint("vip_SpawnSoulGem(", vtos(orig), ", ", ftos(theteam), ")\n");
	
	local entity e;
	e = spawn();
	e.classname = "vip_soulgem";
	e.target = "###item###";
	e.team = theteam;
	e.movetype = MOVETYPE_NONE;
	e.touch = vip_SoulGem_touch;
	e.think = vip_SoulGem_think;
	e.nextthink = time + random();
	e.solid = SOLID_TRIGGER;
	e.flags = FL_ITEM;
	e.reset2 = vip_SoulGem_reset;
	setmodel(e, "models/runematch/rune.mdl");
	setsize(e, '0 0 -35', '0 0 0');
	
	e.glow_size = 256;
	e.glow_color = vip_SoulGemGlow(theteam);
	e.glow_trail = 1;
	
	e.enemy = spawn();
	e.enemy.enemy = e;
	e.enemy.classname = "vip_soulgem_effect";
	setmodel(e.enemy, "models/runematch/curse.mdl");
	e.origin = orig;
	e.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_PLAYERCLIP;
	setorigin (e, e.origin);
	setattachment(e.enemy, e, "");

	if (!move_out_of_solid(e))
		bprint("\x01^!WARNING: ^7failed to move soulgem out of solid, expect weird shit and breakages\n");
	
	local entity oldself;
	oldself = self;
	self = e;
	droptofloor();
	self = oldself;

	e.colormod = vip_SoulGemColormod(theteam);
	e.enemy.colormod = vip_SoulGemColormod2(theteam);

	e.alpha = e.enemy.alpha = 0.8;
	e.effects = e.enemy.effects = (EF_ADDITIVE | EF_FULLBRIGHT);
	
	// "run here" waypoint
	if(!e.waypointsprite_attached) {
		WaypointSprite_Spawn("RUN HERE TO BECOME THE VIP!", 0, 0, e, '0 0 64', world, e.team, e, waypointsprite_attached, TRUE);
        WaypointSprite_UpdateTextColors(e.waypointsprite_attached, '1 0.3 0.6', '0 0 0', '0 0 0');
    }
	
	//MoveToRandomMapLocation(e, DPCONTENTS_SOLID | DPCONTENTS_CORPSE | DPCONTENTS_PLAYERCLIP, DPCONTENTS_SLIME | DPCONTENTS_LAVA | DPCONTENTS_SKY | DPCONTENTS_BODY | DPCONTENTS_DONOTENTER, Q3SURFACEFLAG_SKY, 10, 1024, 256);
	
	local entity WHAT_THE_FUCK;
	switch(theteam)
	{
		case COLOR_TEAM1:
			if(vip_redgem)
				vip_removegem(vip_redgem);
			
			if(redgem_loc == '0 0 0')
				redgem_loc = e.origin;
			
			vip_redgem = e;
			
			/// HOLY FUCKING COCKS FROM HELL
			/// THIS SHIT BLOWS MY MIIIIND
			if(e.origin != redgem_loc)
			{
				bprint("^1WTF?!?!?!??!?!?!??!\n");
				vip_removegem(e);
				
				WHAT_THE_FUCK = spawn();
				WHAT_THE_FUCK.think = WHAT_THE_FUCK_think;
				WHAT_THE_FUCK.team = theteam;
				WHAT_THE_FUCK.origin = orig;
				WHAT_THE_FUCK.nextthink = time + 0.01;
			}
			
			return;
		case COLOR_TEAM2:
			if(vip_bluegem)
				vip_removegem(vip_bluegem);
			
			if(bluegem_loc == '0 0 0')
				bluegem_loc = e.origin;
			vip_bluegem = e;
			
			/// SEE COMMENT ABOVE
			if(e.origin != bluegem_loc)
			{
				bprint("^4WTF?!?!?!??!?!?!??!\n");
				vip_removegem(e);
				
				WHAT_THE_FUCK = spawn();
				WHAT_THE_FUCK.think = WHAT_THE_FUCK_think;
				WHAT_THE_FUCK.team = theteam;
				WHAT_THE_FUCK.origin = orig;
				WHAT_THE_FUCK.nextthink = time + 0.01;
			}

			return;
		default:
			error(strcat("Tried to spawn a Soul Gem for an invalid team ", ftos(theteam)));
	}
}

void vip_init()
{
    if(inWarmupStage)
        warmup = time;
    else
        warmup = time + cvar("g_start_delay");
    
    precache_sound("ctf/red_capture.wav");
    precache_sound("ctf/blue_capture.wav");
    ScoreRules_vip();
	
	vip_soulgem = cvar("g_vip_soulgem");
	
	if(vip_soulgem)
	{
		precache_model("models/runematch/curse.mdl");
		precache_model("models/runematch/rune.mdl");
	}
	
	precache_sound("kh/capture.wav");
	InitializeEntity(world, vip_delayedinit, INITPRIO_GAMETYPE);
}

void vip_EndRound_Finalize() {
	vip_started = TRUE;
	vip_AssignVIPs();
}

void vip_EndRound_Think() {
	vip_started = 0;
    vip_ended = 0;
}

void vip_EndRound()
{
	next_round = time + 5;
	
	if(!vip_soulgem)
		G_EndRound(5, cvar("g_vip_warmup"), SUB_Null, vip_EndRound_Think, vip_EndRound_Finalize);
	else {
        roundstate = ROUNDSTATE_OVER;
		defer(5.1, vip_SoulGem_StartRound);
    }
    
    defer(5.1, vip_ClearVIPs);
    vip_ended = 1;
    vip_ResetVIPInfo();
    
    if(vip_sg_startroundentity)
		remove(vip_sg_startroundentity);
}

void vip_SoulGem_StartRound_Think()
{
	if(!redvip || !bluevip)
	{
        roundstate = ROUNDSTATE_OVER;
		vip_started = 0;
		vip_ended = 0;
		
		local entity e;
		FOR_EACH_PLAYER(e)
		{
			bigprint_clear_spec(e);
			
			if((e.team == COLOR_TEAM1 && redvip) || (e.team == COLOR_TEAM2 && bluevip))
				bigprint_spec(e, "Waiting for an enemy VIP", "", 5);
			else
				bigprint_spec(e, "Waiting for VIPs", "Pickup your Soul Gem to become a VIP", 5);
		}
		
		self.nextthink = time + 5;
	}
	else remove(self);
}

void vip_SoulGem_StartRound()
{
	if(vip_sg_startroundentity)
		remove(vip_sg_startroundentity);
	
	vip_sg_startroundentity = spawn();
	vip_sg_startroundentity.think = vip_SoulGem_StartRound_Think;
	vip_sg_startroundentity.nextthink = time + 5;
}

entity vip_PickRedVIP()
{
	local float players;
	players = 0;
	entity my_player, player;
	
	FOR_EACH_PLAYER(player)
		if(player.deadflag == DEAD_NO)
			if(player.team == COLOR_TEAM1)
			{
				++players;
				if(random() * players <= 1)
					my_player = player;
			}
	
	return my_player;
}

entity vip_PickBlueVIP()
{
	local float players;
	players = 0;
	entity my_player, player;
	
	FOR_EACH_PLAYER(player)
		if(player.deadflag == DEAD_NO)
			if(player.team == COLOR_TEAM2)
			{
				++players;
				if(random() * players <= 1)
					my_player = player;
			}
	
	return my_player;
}

.float vip_maxarmor_old;
.float vip_maxhealth_old;
.float vip_health_old;
.float vip_armor_old;

void vip_ResetVIPInfo()
{
	local entity e;
	FOR_EACH_REALCLIENT(e) if(e.classname != "")
	{
		msg_entity = e;
		
		WriteByte(MSG_ONE, SVC_TEMPENTITY);
		WriteByte(MSG_ONE, TE_CSQC_VIPINFO);
		WriteByte(MSG_ONE, COLOR_TEAM1 - 1);
		WriteShort(MSG_ONE, 0);
		WriteShort(MSG_ONE, 0);
		WriteString(MSG_ONE, "");
		
		WriteByte(MSG_ONE, SVC_TEMPENTITY);
		WriteByte(MSG_ONE, TE_CSQC_VIPINFO);
		WriteByte(MSG_ONE, COLOR_TEAM2 - 1);
		WriteShort(MSG_ONE, 0);
		WriteShort(MSG_ONE, 0);
		WriteString(MSG_ONE, "");
	}
}

void vip_SendVIPInfo(float maxv, float v)
{
	//bprint("^6vip_SendHealthArmor for ", self.owner.netname, "\n");
	
	if (!vip_ended && vip_started)
	if (self.health 		!= self.vip_health_old 		||
		self.armorvalue 	!= self.vip_armor_old		||
		self.vip_maxarmor 	!= self.vip_maxarmor_old	||
		self.vip_maxhealth	!= self.vip_maxhealth_old	){
		
		if(self.waypointsprite_attached)
		{
			WaypointSprite_UpdateMaxHealth(self.waypointsprite_attached, maxv);
			WaypointSprite_UpdateHealth(self.waypointsprite_attached, v);
		}
		
		local entity e;
		FOR_EACH_REALCLIENT(e) if(e.classname != "")
		{
			msg_entity = e;
			WriteByte(MSG_ONE, SVC_TEMPENTITY);
			WriteByte(MSG_ONE, TE_CSQC_VIPINFO);
			WriteByte(MSG_ONE, self.team - 1); // wtf?
			WriteShort(MSG_ONE, maxv);
			WriteShort(MSG_ONE, v);
			WriteString(MSG_ONE, self.netname);
		}
		
		self.vip_health_old = self.health;
		self.vip_armor_old = self.armorvalue;
		self.vip_maxhealth_old = self.vip_maxhealth;
		self.vip_maxarmor_old = self.vip_maxarmor;
	}
}

float vip_EnemiesMultiplier(entity pl, string cvarname)
{
	local entity e;
	local float c;
	
	if(!cvar(cvarname))
		return 1;
	
	FOR_EACH_PLAYER(e) if(e.team != pl.team)
		++c;
	
	return (c? c : 1); //NEVER return 0 here
}

void vip_RegenerateHealth()
{
	self.vip_maxhealth = cvar("g_vip_health") * vip_EnemiesMultiplier(self, "g_vip_health_dependonenemies");
	
	self.health = max(self.health, min(self.health + cvar("g_vip_regenerate_health_amount"),
		self.vip_maxhealth
	));
	
	self.vip_healthregen_next = time + cvar("g_vip_regenerate_health_delay");
}

void vip_RegenerateArmor()
{
	self.vip_maxarmor = cvar("g_vip_armor") * vip_EnemiesMultiplier(self, "g_vip_armor_dependonenemies");
	
	self.armorvalue = max(self.armorvalue, min(self.armorvalue + cvar("g_vip_regenerate_armor_amount"),
		self.vip_maxarmor
	));
	
	self.vip_armorregen_next = time + cvar("g_vip_regenerate_armor_delay");
}

void vip_RegenerateExtra()
{
	self.vip_maxarmor = cvar("g_vip_extralives") * vip_EnemiesMultiplier(self, "g_vip_extralives_dependonenemies");
	
	self.armorvalue = max(self.armorvalue, min(self.armorvalue + cvar("g_vip_regenerate_extra_amount"),
		self.vip_maxarmor
	));
	
	self.vip_armorregen_next = time + cvar("g_vip_regenerate_extra_delay");
}

void vip_UpdateState_Health()
{
	vip_SendVIPInfo(self.vip_maxhealth, self.health);
}

void vip_UpdateState_Armor()
{
	vip_SendVIPInfo(
		self.vip_maxhealth * cvar("g_rocketminsta_armor_factor") + self.vip_maxarmor,
		self.health * cvar("g_rocketminsta_armor_factor") + self.armorvalue
	);
}

void vip_UpdateState_Extras()
{
	vip_SendVIPInfo(self.vip_maxarmor, self.armorvalue);
}

void vip_Waypoint(entity pl) {
    if(pl.waypointsprite_attached)
        return;
    
    WaypointSprite_Spawn("VIP", 0, 0, pl, '0 0 64', world, 0, pl, waypointsprite_attached, TRUE);
    WaypointSprite_UpdateTextColors(pl.waypointsprite_attached, TeamColor(pl.team), '0 0 0', '0 0 0');
    if(pl.waypointsprite_attached)
        WaypointSprite_UpdateTeamRadar(pl.waypointsprite_attached, RADARICON_WAYPOINT, TeamColor(pl.team));
}

void vip_MakePlayerVIP(entity pl)
{
	if(pl.waypointsprite_attached)
	{
		print("vip_MakePlayerVIP on player with waypointsprite_attached: ", pl.netname, "\n");
		WaypointSprite_Kill(pl.waypointsprite_attached);
	}
	
	// causes the state updater to re-send the VIP info no matter what
	pl.vip_maxarmor_old = pl.vip_maxarmor_old = pl.vip_armor_old = pl.vip_health_old = -1;

	if(!g_minstagib || cvar("g_rocketminsta"))
	{
		pl.vip_maxhealth = cvar("g_vip_health") * vip_EnemiesMultiplier(pl, "g_vip_health_dependonenemies");
		
		if(cvar("g_vip_regenerate_health"))
		{
			pl.vip_regenhealth_f = vip_RegenerateHealth;
			pl.vip_healthregentime = time;
			pl.vip_healthregen_next = time + cvar("g_vip_regenerate_extra_delay");
		}
	}
	
	if(!g_minstagib || (cvar("g_rocketminsta") && cvar("g_rocketminsta_armor")))
	{
		pl.vip_maxarmor = cvar("g_vip_armor") * vip_EnemiesMultiplier(pl, "g_vip_armor_dependonenemies");
		
		if(cvar("g_vip_regenerate_armor"))
		{
			pl.vip_regenarmor_f = vip_RegenerateArmor;
			pl.vip_armorregentime = time;
			pl.vip_armorregen_next = time + cvar("g_vip_regenerate_armor_delay");
		}
		
		pl.vip_updatestate_f = vip_UpdateState_Armor;
	}
	else // in minstagib, we will just give him a bunch of extralives
	{
		pl.vip_maxhealth = 100;
		pl.vip_maxarmor = cvar("g_vip_extralives") * vip_EnemiesMultiplier(pl, "g_vip_extralives_dependonenemies");
		
		if(pl.vip_maxarmor)
			pl.vip_updatestate_f = vip_UpdateState_Extras;
		else
			pl.vip_updatestate_f = vip_UpdateState_Health;
		
		if(cvar("g_vip_regenerate_extra"))
		{
			pl.vip_regenarmor_f = vip_RegenerateExtra;
			pl.vip_armorregentime = time;
			pl.vip_armorregen_next = time + cvar("g_vip_regenerate_extra_delay");
		}
	}
	
	pl.vip_grenregen_next = time + cvar("g_vip_regenerate_grenades_delay");
	vip_ResetHealthArmor(pl);

	switch(pl.team)
	{
		case COLOR_TEAM1:
			bigprint_spec(pl, "You are the ^1RED^7 vip!", "Survive or your team will lose!", 2);
			bprint(pl.netname, " ^7is now the ^1RED^7 VIP!\n");
			break;
		
		case COLOR_TEAM2:
			bigprint_spec(pl, "You are the ^4BLUE^7 vip!", "Survive or your team will lose!", 2);
			bprint(pl.netname, " ^7is now the ^4BLUE^7 VIP!\n");
			break;
		
		default:
			bigprint_spec(pl, "You are... wtf?!?!?", "^1THE MOD IS B0RKED", 2);
			bprint(pl.netname, " ^7screwed everything up\n");
			break;
	}
	
    vip_Waypoint(pl);
	entity e; FOR_EACH_PLAYER(e) if(e.team == pl.team) if(e != pl)
		centerprint_spec(e, strcat(pl.netname, "^7 is now your VIP!"));
		
	play2all("kh/capture.wav");
}

void vip_PlayerPreThink()
{
	DEPENDON(g_vip)
	if(!ISVIP(self))
		return;
	
	vip_Waypoint(self);
	
	if(self.vip_updatestate_f)
		self.vip_updatestate_f();
	else
		bprint("^1URGENT: ^7", self.netname, " has no vip_updatestate_f! Everything is fucked up!\n");
	
	if(time >= self.vip_armorregen_next)
	{
		if(self.vip_regenarmor_f)
			self.vip_regenarmor_f();
		//else
		//	bprint("^1URGENT: ^7", self.netname, " has no vip_regenarmor_f! Everything is fucked up!\n");
	}
		
	if(time >= self.vip_healthregen_next)
	{
		if(self.vip_regenhealth_f)
			self.vip_regenhealth_f();
		//else
		//	bprint("^1URGENT: ^7", self.netname, " has no vip_regenhealth_f! Everything is fucked up!\n");
	}
	
    // XXX: this code needs an update for the new grenade regen mechanics
    if(!cvar("g_nadgets_regen_time"))
	if(cvar("g_vip_regenerate_grenades"))
	if(self.hg_ammo < cvar("g_nadgets_ammo"))
	if(time >= self.vip_grenregen_next)
	{
		self.hg_ammo += cvar("g_vip_regenerate_grenades_amount");
		self.vip_grenregen_next = time + cvar("g_vip_regenerate_grenades_delay");
	}
}

void vip_ResetHealthArmor(entity vip)
{
	vip.health = vip.vip_maxhealth;
	vip.armorvalue = vip.vip_maxarmor;
}

void vip_AssignCustomRedVIP(entity newvip)
{
	if(redvip)
	{
		bprint("^5VIP^7: tried to assign the ^1RED^7 vip, but there is already one!\n");
		return;
	}
	
	redvip = newvip;
	
	if(redvip)
		vip_MakePlayerVIP(redvip);
}

void vip_AssignCustomBlueVIP(entity newvip)
{
	if(bluevip)
	{
		bprint("^5VIP^7: tried to assign the ^4BLUE^7 vip, but there is already one!\n");
		return;
		
	}
	
	bluevip = newvip;
	
	if(bluevip)
		vip_MakePlayerVIP(bluevip);
}

void vip_AssignRedVIP()
{
	vip_AssignCustomRedVIP(vip_PickRedVIP());
	
	if(!redvip)
	{
		print("^5VIP^7: not enough players on the red team, polling until there are some...\n");
		defer(1, vip_AssignRedVIP);
		return;
	}
}

void vip_AssignBlueVIP()
{
	vip_AssignCustomBlueVIP(vip_PickBlueVIP());
	
	if(!bluevip)
	{
		print("^5VIP^7: not enough players on the blue team, polling until there are some...\n");
		defer(1, vip_AssignBlueVIP);
		return;
	}
}

void vip_ClearVIP_Common(entity pl)
{
	if(pl.waypointsprite_attached)
		WaypointSprite_Kill(pl.waypointsprite_attached);
}

void vip_ClearRedVIP()
{
	vip_ClearVIP_Common(redvip);
	redvip = world;
	
	if(vip_soulgem)
	{
		local entity oldself;
		oldself = self;
		self = vip_redgem;
		vip_redgem.reset2();
		self = oldself;
	}
}

void vip_ClearBlueVIP()
{
	vip_ClearVIP_Common(bluevip);
	bluevip = world;
	
	if(vip_soulgem)
	{
		local entity oldself;
		oldself = self;
		self = vip_bluegem;
		vip_bluegem.reset2();
		self = oldself;
	}
}

void vip_ClearVIPs()
{
	vip_ClearRedVIP();
	vip_ClearBlueVIP();
}

void vip_AssignVIPs()
{
	if(vip_soulgem)
	{
        roundstate = ROUNDSTATE_OVER;
		vip_SoulGem_StartRound();
		return;
	}
	
	vip_AssignRedVIP();
	vip_AssignBlueVIP();
}

void vip_ClearVIPs_MaybeAssign()
{
	vip_ClearVIPs();
	
	if(vip_started)
		defer(1, vip_AssignVIPs);
}

void vip_RedVIPDown()
{
	local entity e;
	FOR_EACH_PLAYER(e)
	{
		bigprint_spec(e, "^4Blue ^7Scores!", "The enemy VIP is down", 5);
		
		if(e.team == COLOR_TEAM2)
			hudflash_teamcolor_default_spec(e);
	}
	bprint("^4Blue team ^5wins the round since the enemy VIP is dead\n");
	play2all("ctf/blue_capture.wav");
	TeamScore_AddToTeam(COLOR_TEAM2, ST_SCORE, 1);
	
	if(bluevip && bluevip.classname == "player")
	{
		PlayerScore_Add(bluevip, SP_VIP_SURVIVALS, 1);
		PlayerScore_Add(bluevip, SP_SCORE, cvar((vip_soulgem? "g_vip_score_survival_soulgem" : "g_vip_score_survival")));
	}
	
	vip_EndRound();
}

void vip_BlueVIPDown()
{
	local entity e;
	FOR_EACH_PLAYER(e)
	{
		bigprint_spec(e, "^1Red ^7Scores!", "The enemy VIP is down", 5);
		
		if(e.team == COLOR_TEAM1)
			hudflash_teamcolor_default_spec(e);
	}
	bprint("^1Red team ^5wins the round since the enemy VIP is dead\n");
	play2all("ctf/red_capture.wav");
	TeamScore_AddToTeam(COLOR_TEAM1, ST_SCORE, 1);
	
	if(redvip && redvip.classname == "player")
	{
		PlayerScore_Add(redvip, SP_VIP_SURVIVALS, 1);
		PlayerScore_Add(redvip, SP_SCORE, cvar((vip_soulgem? "g_vip_score_survival_soulgem" : "g_vip_score_survival")));
	}
	vip_EndRound();
}

float vip_PlayerDies(entity frag_attacker, entity frag_target, float deathtype)
{
	DEPENDON_F(g_vip, 0)
	
	if(vip_ended)
		return 0;
	
	if(!vip_started)
	{
		if(ISREDVIP(frag_target))
		{
			vip_ClearRedVIP();
			
			if(!vip_soulgem)
				vip_AssignRedVIP();
		}
		else if(ISBLUEVIP(frag_target))
		{
			vip_ClearBlueVIP();
			
			if(!vip_soulgem)
				vip_AssignBlueVIP();
		}
		
		return 0;
	}
	
	if(!ISVIP(frag_target))
		return 0;
	
	if(frag_attacker) if(frag_attacker.classname == "player")
	{
		PlayerScore_Add(frag_attacker, SP_VIP_VIPKILLS, 1);
		
		if(DEATH_ISSPECIAL(deathtype) || deathtype == DEATH_HURTTRIGGER)
			PlayerScore_Add(frag_attacker, SP_SCORE, cvar("g_vip_score_vipkill_special"));
		else
			PlayerScore_Add(frag_attacker, SP_SCORE, cvar("g_vip_score_vipkill"));
	}
	
	if(ISREDVIP(frag_target))
		vip_RedVIPDown();
	else if(ISBLUEVIP(frag_target))
		vip_BlueVIPDown();
	
	return 0;
}

float vip_RemovePlayer()
{
	DEPENDON_F(g_vip, 0)
	
	if(vip_ended)
		return 0;
	
	if(ISREDVIP(self))
	{
		vip_ClearRedVIP();
		
		if(vip_started)
			vip_RedVIPDown();
		else if(!vip_soulgem)
			vip_AssignRedVIP();
	}
	else if(ISBLUEVIP(self))
	{
		vip_ClearBlueVIP();
		
		if(vip_started)
			vip_BlueVIPDown();
		else if(!vip_soulgem)
			vip_AssignBlueVIP();
	}
	
	return 0;
}
