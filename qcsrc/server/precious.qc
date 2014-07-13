// Chaiomanot: Jan 6th-7th 2012: precious.qc created, Precious added...
// Chaiomanot: Jan 8th 2012: Largely re-written this file, smaller footprint, more adaptable. Now that I get QuakeC better, it's not as buggy (actually not at all, so far).
// Chaiomanot: Jan 9th 2012: Added rune pulsation. Added not-in-play reasoning. Made rune take revenge ;-).
// Chaiomanot: Jan 10th 2012: Made playable by bots. Fixed a couple of minor bugs (of course they're in there). But I can't figure out how to solve the bug that causes the rune to float mid-air when dropped (happens rarely) - so it's staying for now.

//---- rune operations ----

entity prec_rune_create ()
{
    // create the rune and define it's behavior
    prec_controller.pain_finished = 0;
    local entity rune;
    rune = spawn();
    rune.classname = "prec_rune";
    rune.netname   = "The Precious";
    rune.netname2  = "your Precious";
    rune.netname3  = "his Precious";
    rune.movetype  = MOVETYPE_BOUNCE;
    rune.solid     = SOLID_BBOX;
    rune.flags     = FL_ITEM;
    rune.owner     = world;
    rune.think     = prec_rune_think;
    rune.touch     = prec_rune_touch;
    rune.prec_time = 0;
	rune.event_damage     = prec_rune_damage;
	rune.takedamage       = DAMAGE_AIM;
	rune.damageforcescale = cvar("g_prec_rune_damageforcescale");
	rune.killindicator    = world;
	rune.killsound	      = 1;
	rune.bot_pickup          = 1;
	rune.bot_pickupevalfunc  = prec_rune_bot_eval_pickup;
    setmodel(rune         , "models/runematch/rune.mdl");
    setsize(rune          , '0 0 -15', '0 0 0');
    setattachment(rune    , world, "");
    setorigin(rune        , '0 0 0');
    rune.velocity         = '0 0 200';

    // make the rune glow
	if(cvar("g_prec_rune_glow"))
	{
		rune.glow_size  = 256;
		rune.glow_color = 11;
		rune.glow_trail = 1;
		rune.effects = rune.effects | EF_LOWPRECISION;
    }

    // put the rune somewhere random
    if(!MoveToRandomMapLocation(rune, DPCONTENTS_SOLID | DPCONTENTS_CORPSE | DPCONTENTS_PLAYERCLIP, DPCONTENTS_SLIME | DPCONTENTS_LAVA | DPCONTENTS_SKY | DPCONTENTS_BODY | DPCONTENTS_DONOTENTER, Q3SURFACEFLAG_SKY, 128, 1024, 256))
    {
		bprint(strcat("^1Couldn't find a suitable place to spawn ^7", rune.netname, "^1, will try again\n"));
		// destroy the rune
		remove(rune);
		prec_controller.pain_finished = cvar("g_prec_rune_spawn_delay") + 0.1;
		// hand the world to the caller (our safe null substitute)
		return world;
	}

    // announce the rune's availability
    local string spawn_msg;
	spawn_msg = strcat("^7", rune.netname, "^7 has spawned");
    bprint(strcat(spawn_msg, "\n"));
    local entity pi;
    FOR_EACH_PLAYER(pi)
        centerprint_spec(pi, strcat(NEWLINES, spawn_msg));
    play2all(kh_sound_alarm);

    // give it a waypoint
    WaypointSprite_Spawn("pointer_cyan", 0, 0, rune, '0 0 32', world, 0, rune, waypointsprite_attached, 1);

    // hand it to the caller, all prepared
    rune.pain_finished = cvar("g_prec_rune_patience");
    rune.nextthink = time + 0.1;
    return rune;
}

void prec_rune_collect (entity rune, entity player)
{
    // make sure the attacher is a living player
    if(player.classname != "player" || player.health <= 0)
        return;
	// make sure the player wants to pick up the rune
	if(player.BUTTON_USE || player.prec_time > time)
        return;

    // attach the rune to the player
    rune.solid = SOLID_NOT;
    rune.owner = player;
    player.prec_rune = rune;
	rune.killindicator = player;
    rune.velocity = '0 0 0';
    setattachment(rune, player, "");
    setorigin(rune, rune.origin);

    // announce the rune's new carrier
    local string pickup_msg;
	pickup_msg = strcat("^7", rune.owner.netname, "^7 took ", rune.netname, "!");
    bprint(strcat(pickup_msg, "\n"));
    
    local entity pi;
    FOR_EACH_PLAYER(pi) {
		/*
		if(pi == rune.owner)
			centerprint_spec(pi, strcat(NEWLINES, "^7You took ", rune.netname));
		else
			centerprint_spec(pi, strcat(NEWLINES, pickup_msg));
		*/
		
		if(pi == rune.owner)
			bigprint_spec(pi, strcat("^7You took ", rune.netname, "!"), "", 5);
		else
			bigprint_spec(pi, "", pickup_msg, 5);
	}
    
    // we don't want the collection sound to interfere with the revenge sound
    if(player.prec_grudge <= 0)
		play2all(kh_sound_collect);
	rune.killsound = 1;

	// give or take the player points for pickup up the rune
	if(cvar("g_prec_points_rune_collect"))
		PlayerScore_Add(player, SP_SCORE, cvar("g_prec_points_rune_collect"));
	PlayerScore_Add(player, SP_PREC_PICKUPS, 1);

    // update it's waypoint
    WaypointSprite_Kill(rune.waypointsprite_attached);
	WaypointSprite_Spawn("pointer_red", 0, 0, rune.owner, '0 0 64', world, 0, rune, waypointsprite_attached, 1);
	
	player.health = max(player.health, 200);
	player.armorvalue = max(player.armorvalue, 200);
	if(g_nadgets)
		player.hg_ammo = max(player.hg_ammo, cvar("g_nadgets_ammo") * 2);
}

void prec_rune_drop (entity rune, float deliberate)
{
    // make sure the rune is attached
    if(rune.owner.classname != "player")
        return;

	// give or take the player points for dropping the rune
	if(cvar("g_prec_points_rune_drop"))
		PlayerScore_Add(rune.owner, SP_SCORE, cvar("g_prec_points_rune_drop"));

    // announce the rune's availability
    local string drop_msg;
	if(deliberate)
		drop_msg = strcat("^7", rune.owner.netname, "^7 decided ", rune.netname3, "^7 wasn't worth it");
	else
		drop_msg = strcat("^7", rune.owner.netname, "^7 couldn't take care of ", rune.netname3);
    bprint(strcat(drop_msg, "\n"));
    local entity pi;
    FOR_EACH_PLAYER(pi) {
        if(pi == rune.owner) {
			if(!deliberate)
				centerprint_spec(pi, strcat("^7You lost ", rune.netname2));
        } else
			centerprint_spec(pi, drop_msg);
    }
    if(rune.killsound)
		play2all(kh_sound_drop);

    // detach the rune from the player
    rune.owner.prec_time = time + 2;
	setattachment(rune, world, "");
    setorigin(rune, rune.owner.origin);
	rune.velocity = rune.owner.velocity * cvar("g_prec_rune_throwforcescale");
	rune.velocity_z = rune.velocity_z + 300;
    rune.solid = SOLID_TRIGGER;
    rune.owner.prec_rune = world;
    rune.owner = world;
    rune.pain_finished = cvar("g_prec_rune_patience");

    // update it's waypoint
    WaypointSprite_Kill(rune.waypointsprite_attached);
    WaypointSprite_Spawn("pointer_cyan", 0, 0, rune, '0 0 32', world, 0, rune, waypointsprite_attached, 1);
}

void prec_rune_destroy (entity rune, float desired)
{
	// make sure someone doesn't still have the rune
	prec_rune_drop(rune, 0);

	// announce the rune's destruction
	local string des_msg;
	if(desired)
		des_msg = strcat("^7", self.netname, "^7 got lonely");
	else if(self.killindicator.classname == "player") {
		des_msg = strcat("^7", self.killindicator.netname, "^7 broke ", self.netname3);
		// hold a grudge against who ever is responsible
		if(cvar("g_prec_rune_revenge"))
			rune.killindicator.prec_grudge = rune.killindicator.prec_grudge + 1;
		//PlayerScore_Add(rune.killindicator, 9, 1);
	} else
		des_msg = strcat("^7", self.netname, "^7 broke");
    bprint(strcat(des_msg, "\n"));
    local entity pi;
    FOR_EACH_PLAYER(pi) {
        if(pi == self.killindicator && !desired)
			centerprint_spec(pi, strcat("^7You broke ", rune.netname2));
        else
			centerprint_spec(pi, des_msg);
    }
    play2all(kh_sound_destroy);

	// remove the rune's waypoint
    WaypointSprite_Kill(rune.waypointsprite_attached);

    // destroy the rune
	remove(rune);
    prec_controller.pain_finished = 0.1;
}

//---- rune events ----

void prec_rune_think ()
{
    self.nextthink = time + 0.1;
	if(self.owner == world)
	{
		// destroy the rune if broke
		if(self.pain_finished <= 0) {
			prec_rune_destroy(self, 0);
			return;
		}

		// destroy the rune if grew lonely
		self.pain_finished = self.pain_finished - 0.1;
		if(self.pain_finished <= 0) {
			prec_rune_destroy(self, 1);
			return;
		}
	}
	else
	{
		// rotate the rune around it's carrier
		self.velocity = '0 0 0';
		vector ang;
		ang_y = mod(time, 360) * 90;
		makevectors(ang);
		setorigin(self, v_forward * 32);

		// drop the rune if the player doesn't want it anymore
		if(self.owner.BUTTON_USE)
		   prec_rune_drop(self, 1);

		// take revenge on the player if he offended the rune
		if(self.owner.prec_grudge > 0)
		{
			// announce the rune's revenge
			local string rev_msg;
			rev_msg = strcat("^7", self.owner.netname, "^1 didn't get along with ", self.netname3);
			bprint(strcat(rev_msg, "\n"));
			local entity pi;
			FOR_EACH_PLAYER(pi) {
				if(pi == self.owner) centerprint_spec(pi, strcat("^7Apparently ", self.netname2, "^7 remembers you"));
				else centerprint_spec(pi, rev_msg);
			}

			// zap the player
			local vector force;
			force = self.owner.velocity * -10;
			force_z = force_z + 300;
			sound(self.owner, CHAN_AUTO, "porto/explode.wav", 1, 1);
			self.owner.prec_grudge = self.owner.prec_grudge - 1;
			GiveFrags(self.owner, self, self.owner, -1);
			Damage(self.owner, self, self, 10000, DEATH_KILL, self.origin, force);
		}
    }

	// pulsate the rune's glow
	self.glow_size = 256 + cos(mod(time, 360) * 2) * 64;
}

void prec_rune_touch ()
{
    self.nextthink = time + 0.1;
	if(self.owner == world)
		prec_rune_collect(self, other);
}

void prec_rune_damage (entity inflictor, entity attacker, float damage, float deathtype, vector hitloc, vector force)
{
	if(self.owner == world)
	{
		if(vlen(force) <= 0)
			return;
		// considering noone is holding it, remember who last touched the rune
		self.killindicator = attacker;
	}
}

float prec_rune_bot_eval_pickup (entity player, entity rune)
{
	if(rune.owner == world) return 30000; // megas are 10000
	return 0;
}

//---- precious game tests and events ----

void prec_player_die (entity player, entity frag_attacker)
{
    // if we're not playing ka, don't interfere with the caller's natural routine
    if(!g_prec) return;
	
    // is the dieing player holding a rune that needs to be dropped?
    if(player.prec_rune.classname == "prec_rune") {
        prec_rune_drop(player.prec_rune, 0);
        
        if(frag_attacker.classname == "player" && frag_attacker != self) {
			PlayerScore_Add(frag_attacker, SP_SCORE, cvar("g_prec_points_rckill"));
			PlayerScore_Add(frag_attacker, SP_PREC_CARRIERKILLS, 1);
		}
	}
}

float prec_check_aggression (entity attacker, entity inflictor, entity targ)
{
    // if we're not playing ka, don't interfere with the caller's natural routine
    if(!g_prec) return 1;
    // make sure the target is actually a player (if it's not, don't interfere)
    if(targ.classname != "player") return 1;
    // allow a point change for the death of the rune carrier
	if(targ.prec_rune.classname == "prec_rune")
	{
		// only sound the drop if we don't think destruction follows
		if(inflictor.classname == "trigger_hurt" ||
		   inflictor.classname == "prec_rune") targ.prec_rune.killsound = 0;
		else targ.prec_rune.killsound = 1;
		//// mark this rune carrier's death on the attacker's scoreboard
		//if(targ.health < 1)
		//	if(attacker.classname == "player")
		//		PlayerScore_Add(attacker, 8, 1);
		return 1;
	}
    // allow a point change for for fragging someone while holding the rune
    if(attacker.prec_rune.classname == "prec_rune") return 1;
    // no runes, no points
    return 0;
}

//---- precious game control ----

void prec_controller_think ()
{
    self.nextthink = time + 0.1;
	if(self.pain_finished)
	{
		// the rune does not exist, so we'll keep things up

		// don't try to spaw the rune unless the game is in play
		if(gameover || time < game_starttime)
			return;

		// respawn the rune after it's been gone for long enough
		self.pain_finished = self.pain_finished + 0.1;
		if(self.pain_finished > cvar("g_prec_rune_spawn_delay"))
			prec_rune_create();
	}
	else
	{
		// the rune exists, and is on it's own
	}
}

void prec_init ()
{
    // precache our stuff
    precache_model("models/runematch/rune.mdl");
    precache_sound(kh_sound_collect);
    precache_sound(kh_sound_drop);
    precache_sound(kh_sound_destroy);
    precache_sound(kh_sound_alarm);
	precache_sound("porto/explode.wav");

    // create the keepaway controller
    prec_controller = spawn();
    prec_controller.classname = "prec_controller";
    prec_controller.netname   = "Precious Controller";
    prec_controller.movetype  = MOVETYPE_NONE;
    prec_controller.solid     = SOLID_NOT;
    prec_controller.nextthink = time + 0.1;
    prec_controller.think     = prec_controller_think;
    prec_controller.pain_finished = 0.1;
    
    ScoreRules_Prec();
}

