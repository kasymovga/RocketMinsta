
// these are used to store the last key press time for each of the keys..
.float last_FORWARD_KEY_time;
.float last_BACKWARD_KEY_time;
.float last_LEFT_KEY_time;
.float last_RIGHT_KEY_time;


// these store the movement direction at the time of the dodge action happening.
.float dodging_direction_x;
.float dodging_direction_y;

// this indicates the last time a dodge was executed. used to check if another one is allowed
// and to ramp up the dodge acceleration in the physics hook.
.float last_dodging_time;

// set to 1 to indicate dodging has started.. reset by physics hook after dodge has been done..
.float dodging_action;

// This is the velocity gain to be added over the ramp time.
// It will decrease from frame to frame during dodging_action = 1
// until it's 0.
.float dodging_velocity_gain;

// the jump part of the dodge cannot be ramped
.float dodging_single_action;

void dodging_Initialize() {
	// print("dodging_Initialize\n");

	self.last_FORWARD_KEY_time = 0;
	self.last_BACKWARD_KEY_time = 0;
	self.last_RIGHT_KEY_time = 0;
	self.last_LEFT_KEY_time = 0;
	self.last_dodging_time = 0;
	self.dodging_action = 0;
	self.dodging_velocity_gain = 0;
	self.dodging_single_action = 0;
	self.dodging_direction_x = 0;
	self.dodging_direction_y = 0;
	
	self.lastkeypressed = 0;
}

// returns 1 if the player is close to a wall
float check_close_to_wall(float threshold) {
	if (cvar("g_dodging_wall_dodging") == 0)
		return 0;

	vector trace_start;
	vector trace_end;

	trace_start = self.origin;

	trace_end = self.origin + (1000*v_right);
	tracebox(trace_start, self.mins, self.maxs, trace_end, TRUE, self);
	if (trace_fraction < 1 && vlen (self.origin - trace_endpos) < threshold)
		return 1;

	trace_end = self.origin - (1000*v_right);
	tracebox(trace_start, self.mins, self.maxs, trace_end, TRUE, self);
	if (trace_fraction < 1 && vlen (self.origin - trace_endpos) < threshold)
		return 1;

	trace_end = self.origin + (1000*v_forward);
	tracebox(trace_start, self.mins, self.maxs, trace_end, TRUE, self);
	if (trace_fraction < 1 && vlen (self.origin - trace_endpos) < threshold)
		return 1;

	trace_end = self.origin - (1000*v_forward);
	tracebox(trace_start, self.mins, self.maxs, trace_end, TRUE, self);
	if (trace_fraction < 1 && vlen (self.origin - trace_endpos) < threshold)
		return 1;

	return 0;
}

float check_close_to_ground(float threshold) {
	if (self.flags & FL_ONGROUND)
		return 1;

	return 0;
}

.float cvar_cl_dodging_timeout;
float dodging_GetPressedKeys()
{
	float length;
	float tap_direction_x;
	float tap_direction_y;

	tap_direction_x = 0;
	tap_direction_y = 0;

	float dodge_detected;
	if not(g_dodging)
		return 0;

	if(g_freeze && self.frozen) {
        if not(g_freezetag_dodging_frozen)
            return 0;
    }

    if(time < self.hg_plasmalock)
        return 0;
    
    //if(self.hg_stealth)
    //    return 0;

    if(self.hg_shield)
    if(!cvar("g_dodging_shielded"))
        return 0;
    
	dodge_detected = 0;
    self.cvar_cl_dodging_timeout = 0.2;

	// first check if the last dodge is far enough back in time so we can dodge again
	if ((time - self.last_dodging_time) < g_dodging_delay)
		return 0;
    
    //if(check_close_to_wall(cvar("g_dodging_wall_distance_threshold")))
    //    sprint(self, strcat("close to wall ", ftos(time), "\n"));
    
	if not(check_close_to_ground(cvar("g_dodging_height_threshold")))
    if not(check_close_to_wall(cvar("g_dodging_wall_distance_threshold")))
		return 0;

	if (self.movement_x > 0) {
		// is this a state change?
		if (!(self.pressedkeys & KEY_FORWARD)) {
			if(self.lastkeypressed != KEY_BACKWARD) {
				if ((time - self.last_FORWARD_KEY_time) < self.cvar_cl_dodging_timeout)	{ 
					tap_direction_x = 1.0;
					dodge_detected = 1;
					self.lastkeypressed = 0;
				}
			}
			self.last_FORWARD_KEY_time = time;
 		}
	}

	if (self.movement_x < 0) {
		// is this a state change?
 		if (!(self.pressedkeys & KEY_BACKWARD)) {
			if(self.lastkeypressed != KEY_FORWARD) {
				tap_direction_x = -1.0;
				if ((time - self.last_BACKWARD_KEY_time) < self.cvar_cl_dodging_timeout)	{ 
					dodge_detected = 1;
					self.lastkeypressed = 0;
				}
			}
			self.last_BACKWARD_KEY_time = time;
 		}
	}

	if (self.movement_y > 0) {
		// is this a state change?
		if (!(self.pressedkeys & KEY_RIGHT)) {
			if(self.lastkeypressed != KEY_LEFT) {
				tap_direction_y = 1.0;
				if ((time - self.last_RIGHT_KEY_time) < self.cvar_cl_dodging_timeout)	{ 
					dodge_detected = 1;
					self.lastkeypressed = 0;
				}
			}
			self.last_RIGHT_KEY_time = time;
 		}
	}

	if (self.movement_y < 0) {
		// is this a state change?
		if (!(self.pressedkeys & KEY_LEFT)) {
			if(self.lastkeypressed != KEY_RIGHT) {
				tap_direction_y = -1.0;
				if ((time - self.last_LEFT_KEY_time) < self.cvar_cl_dodging_timeout)	{ 
					dodge_detected = 1;
					self.lastkeypressed = 0;
				}
			}
			self.last_LEFT_KEY_time = time;
 		}
	}



	if (dodge_detected == 1) {
		self.last_dodging_time = time;

		self.dodging_action = 1;
		self.dodging_single_action = 1;

		self.dodging_velocity_gain = cvar("g_dodging_horiz_speed");

		self.dodging_direction_x = tap_direction_x;
		self.dodging_direction_y = tap_direction_y;

		// normalize the dodging_direction vector.. (unlike UT99) XD
		length = length + self.dodging_direction_x * self.dodging_direction_x;
		length = length + self.dodging_direction_y * self.dodging_direction_y;
		length = sqrt(length);

		self.dodging_direction_x = self.dodging_direction_x * 1.0/length;
		self.dodging_direction_y = self.dodging_direction_y * 1.0/length;
	}

	return 0;
}


float dodging_PlayerPhysics()
{
	float common_factor;
	float new_velocity_gain;
	float velocity_difference;
	float forcemod;
	forcemod = 1;

	new_velocity_gain = 0;
    
	// when swimming, no dodging allowed..
	if (self.waterlevel >= WATERLEVEL_SWIMMING)
        goto cleanup;
	
	if(g_freeze) if(self.frozen) {
		if(g_freezetag_dodging_frozen)
			forcemod = Freeze_CVar("dodging_frozen_forcefactor");
		else
            goto cleanup;
	}
	
	// make sure v_up, v_right and v_forward are sane
	makevectors(self.angles);

	// if we have e.g. 0.5 sec ramptime and a frametime of 0.25, then the ramp code 
	// will be called ramp_time/frametime times = 2 times. so, we need to 
	// add 0.5 * the total speed each frame until the dodge action is done..
	common_factor = frametime / g_dodging_ramp_time;

	// if ramp time is smaller than frametime we get problems ;D
	if (common_factor > 1) 
		common_factor = 1;

	new_velocity_gain = self.dodging_velocity_gain - (common_factor * cvar("g_dodging_horiz_speed") * forcemod);
	if (new_velocity_gain < 0)
		new_velocity_gain = 0;

	velocity_difference = self.dodging_velocity_gain - new_velocity_gain;

	// ramp up dodging speed by adding some velocity each frame.. TODO: do it! :D
	if (self.dodging_action == 1) {
		//disable jump key during dodge accel phase
		if (self.movement_z > 0) self.movement_z = 0;

		self.velocity = 
			  self.velocity 
			+ ((self.dodging_direction_y * velocity_difference) * v_right)
			+ ((self.dodging_direction_x * velocity_difference) * v_forward);

		self.dodging_velocity_gain = self.dodging_velocity_gain - velocity_difference;
	}

	// the up part of the dodge is a single shot action
	if (self.dodging_single_action == 1) {
		self.flags &~= FL_ONGROUND;

		self.velocity = 
			  self.velocity 
			+ (cvar("g_dodging_up_speed") * forcemod * v_up);

		if(cvar("g_dodging_sound"))
			PlayerSound(playersound_jump, CHAN_PLAYER, VOICETYPE_PLAYERSOUND);

		setanim(self, self.anim_jump, TRUE, FALSE, TRUE);

		self.dodging_single_action = 0;
	}

	// are we done with the dodging ramp yet?
	if((self.dodging_action == 1) && ((time - self.last_dodging_time) > g_dodging_ramp_time))
	{
:cleanup
		// reset state so next dodge can be done correctly
		self.dodging_action = 0;
		self.dodging_direction_x = 0;
		self.dodging_direction_y = 0;
	}

	return 0;
}
