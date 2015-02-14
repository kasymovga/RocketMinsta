void SUB_Null() {};
float SUB_True() { return 1; }
float SUB_False() { return 0; }

void(vector destangle, float tspeed, void() func) SUB_CalcAngleMove;
void()  SUB_CalcMoveDone;
void() SUB_CalcAngleMoveDone;
//void() SUB_UseTargets;
void() SUB_Remove;

void spawnfunc_info_null (void)
{
	remove(self);
	// if anything breaks, tell the mapper to fix his map! info_null is meant to remove itself immediately.
}

void setanim(entity e, vector anim, float looping, float override, float restart)
{
	if (anim_x == e.animstate_startframe)
	if (anim_y == e.animstate_numframes)
	if (anim_z == e.animstate_framerate)
	{
		if(restart)
		{
			if(restart > 0)
			if(anim_y == 1) // ZYM animation
				BITXOR_ASSIGN(e.effects, EF_TELEPORT_BIT);
		}
		else
			return;
	}
	e.animstate_startframe = anim_x;
	e.animstate_numframes = anim_y;
	e.animstate_framerate = anim_z;
	e.animstate_starttime = servertime - 0.1 * serverframetime; // shift it a little bit into the past to prevent float inaccuracy hiccups
	e.animstate_endtime = e.animstate_starttime + e.animstate_numframes / e.animstate_framerate;
	e.animstate_looping = looping;
	e.animstate_override = override;
	e.frame = e.animstate_startframe;
};

void updateanim(entity e)
{
	if (time >= e.animstate_endtime)
	{
		if (e.animstate_looping)
		{
			e.animstate_starttime = e.animstate_endtime;
			e.animstate_endtime = e.animstate_starttime + e.animstate_numframes / e.animstate_framerate;
		}
		e.animstate_override = FALSE;
	}
	e.frame = e.animstate_startframe + bound(0, (time - e.animstate_starttime) * e.animstate_framerate, e.animstate_numframes - 1);
	//print(ftos(time), " -> ", ftos(e.frame), "\n");
};

float animparseerror;
vector animparseline(float animfile)
{
	local string line;
	local float c;
	local vector anim;
	if (animfile < 0)
		return '0 1 2';
	line = fgets(animfile);
	c = tokenize_console(line);
	if (c < 3)
	{
		animparseerror = TRUE;
		return '0 1 2';
	}
	anim_x = stof(argv(0));
	anim_y = stof(argv(1));
	anim_z = stof(argv(2));
	// don't allow completely bogus values
	if (anim_x < 0 || anim_y < 1 || anim_z < 0.001)
		anim = '0 1 2';
	return anim;
};

/*
==================
SUB_Remove

Remove self
==================
*/
void SUB_Remove (void)
{
	remove (self);
}

/*
==================
SUB_Friction

Applies some friction to self
==================
*/
.float friction;
void SUB_Friction (void)
{
	self.nextthink = time;
	if(self.flags & FL_ONGROUND)
		self.velocity = self.velocity * (1 - frametime * self.friction);
}

/*
==================
SUB_VanishOrRemove

Makes client invisible or removes non-client
==================
*/
void SUB_VanishOrRemove (entity ent)
{
	if (ent.flags & FL_CLIENT)
	{
		// vanish
		ent.model = "";
		ent.effects = 0;
		ent.glow_size = 0;
		ent.pflags = 0;
	}
	else
	{
		// remove
		remove (ent);
	}
}

.float glow_size_original;

void SUB_SetFade_Think (void)
{
	self.think = SUB_SetFade_Think;
	self.nextthink = self.fade_time;
	self.alpha = 1 - (time - self.fade_time) * self.fade_rate;
	self.glow_size = self.glow_size_original * self.alpha;
	if (self.alpha < 0.01)
		SUB_VanishOrRemove(self);
	self.alpha = bound(0.01, self.alpha, 1);
}

/*
==================
SUB_SetFade

Fade 'ent' out when time >= 'when'
==================
*/
void SUB_SetFade (entity ent, float when, float fadetime)
{
	//if (ent.flags & FL_CLIENT) // && ent.deadflag != DEAD_NO)
	//	return;
	//ent.alpha = 1;
	ent.fade_rate = 1/fadetime;
	ent.fade_time = when;
	ent.think = SUB_SetFade_Think;
	ent.nextthink = when;
	ent.glow_size_original = ent.glow_size;
}

/*
=============
SUB_CalcMove

calculate self.velocity and self.nextthink to reach dest from
self.origin traveling at speed
===============
*/
void SUB_CalcMoveDone (void)
{
	// After moving, set origin to exact final destination

	setorigin (self, self.finaldest);
	self.velocity = '0 0 0';
	self.nextthink = -1;
	if (self.think1)
		self.think1 ();
}

void SUB_CalcMove (vector tdest, float tspeed, void() func)
{
	vector	delta;
	float	traveltime;

	if (!tspeed)
		objerror ("No speed is defined!");

	self.think1 = func;
	self.finaldest = tdest;
	self.think = SUB_CalcMoveDone;

	if (tdest == self.origin)
	{
		self.velocity = '0 0 0';
		self.nextthink = self.ltime + 0.1;
		return;
	}

	delta = tdest - self.origin;
	traveltime = vlen (delta) / tspeed;

	if (traveltime < 0.1)
	{
		self.velocity = '0 0 0';
		self.nextthink = self.ltime + 0.1;
		return;
	}

	self.velocity = delta * (1/traveltime);	// QuakeC doesn't allow vector/float division

	self.nextthink = self.ltime + traveltime;
}

void SUB_CalcMoveEnt (entity ent, vector tdest, float tspeed, void() func)
{
	entity	oldself;

	oldself = self;
	self = ent;

	SUB_CalcMove (tdest, tspeed, func);

	self = oldself;
}

/*
=============
SUB_CalcAngleMove

calculate self.avelocity and self.nextthink to reach destangle from
self.angles rotating

The calling function should make sure self.think is valid
===============
*/
void SUB_CalcAngleMoveDone (void)
{
	// After rotating, set angle to exact final angle
	self.angles = self.finalangle;
	self.avelocity = '0 0 0';
	self.nextthink = -1;
	if (self.think1)
		self.think1 ();
}

// FIXME: I fixed this function only for rotation around the main axes
void SUB_CalcAngleMove (vector destangle, float tspeed, void() func)
{
	vector	delta;
	float	traveltime;

	if (!tspeed)
		objerror ("No speed is defined!");

	// take the shortest distance for the angles
	self.angles_x -= 360 * floor((self.angles_x - destangle_x) / 360 + 0.5);
	self.angles_y -= 360 * floor((self.angles_y - destangle_y) / 360 + 0.5);
	self.angles_z -= 360 * floor((self.angles_z - destangle_z) / 360 + 0.5);
	delta = destangle - self.angles;
	traveltime = vlen (delta) / tspeed;

	self.think1 = func;
	self.finalangle = destangle;
	self.think = SUB_CalcAngleMoveDone;

	if (traveltime < 0.1)
	{
		self.avelocity = '0 0 0';
		self.nextthink = self.ltime + 0.1;
		return;
	}

	self.avelocity = delta * (1 / traveltime);
	self.nextthink = self.ltime + traveltime;
}

void SUB_CalcAngleMoveEnt (entity ent, vector destangle, float tspeed, void() func)
{
	entity	oldself;

	oldself = self;
	self = ent;

	SUB_CalcAngleMove (destangle, tspeed, func);

	self = oldself;
}

/*
==================
main

unused but required by the engine
==================
*/
void main (void)
{

}

// Misc

.entity trace_savedowner;

void trace_start_for(entity o) {
    if(!cvar("sv_gameplayfix_shootownentities"))
        return;

    entity e; for(;(e = findentity(e, owner, o));) {
        e.trace_savedowner = o;
        e.owner = world;
    }
}

void trace_end_for(entity o) {
    entity e; for(;(e = findentity(e, trace_savedowner, o));) {
        e.trace_savedowner = world;
        e.owner = o;
    }
}

void traceline_skipnonsolid(vector start, vector end, float t, entity forent) {
    if (!cvar("sv_skip_nonsolid_surfaces")) {
        traceline(start, end, t, forent);
        return;
    }
    float prev_trace_fract = 0;
    float tries;
    for (tries = 10; tries > 0; tries--) {
        traceline(start, end, t, forent);
        if(trace_fraction == 1)
            break;
        trace_fraction = prev_trace_fract + (trace_fraction * (1 - prev_trace_fract));
        if(trace_ent || !(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NONSOLID))
            break;
        if (trace_endpos == start) {
            start += normalize(end - start) * 0.01;
            if (tries == 1) print("Can't escape from nonsolid!\n");
        } else
            start = trace_endpos;
        prev_trace_fract = trace_fraction;
    }
}

void tracebox_skipnonsolid(vector start, vector mi, vector ma, vector end, float nomonst, entity forent) {
    if (!cvar("sv_skip_nonsolid_surfaces")) {
        tracebox(start, mi, ma, end, nomonst, forent);
        return;
    }
    float prev_trace_fract = 0;
    float tries;
    for (tries = 10; tries > 0; tries--) {
        tracebox(start, mi, ma, end, nomonst, forent);
        if(trace_fraction == 1)
            break;
        trace_fraction = prev_trace_fract + (trace_fraction * (1 - prev_trace_fract));
        if(trace_ent || !(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NONSOLID))
            break;
        if (trace_endpos == start) {
            start += normalize(end - start) * 0.01;
            if (tries == 1) print("Can't escape from nonsolid!\n");
        } else
            start = trace_endpos;
        prev_trace_fract = trace_fraction;
    }
}

void tracetoss_skipnonsolid(entity ent, entity ignore, float toss_frametime, float toss_count) {
    if (!cvar("sv_skip_nonsolid_surfaces")) {
        vector v0;
        float g0;
        v0 = ent.velocity;
        g0 = ent.gravity;
        ent.velocity = ent.velocity * toss_frametime * 20;
        ent.gravity *= (toss_frametime * toss_frametime * 400);
        tracetoss(ent, ignore);
        ent.velocity= v0;
        ent.gravity = g0;
        return;
    }
    //Almost full copy of darkplaces tracetoss but with tracebox_skipnonsolid instead tracebox.
    float i;
    vector velocity_save = ent.velocity;
    vector avelocity_save = ent.avelocity;
    vector origin_save = ent.origin;
    vector angles_save = ent.angles;
    for (i = 0; i < toss_count; i++) {
        ent.velocity_y = ent.velocity_y - (ent.gravity * (vlen(trace_endpos - ent.origin) / vlen(ent.velocity)));
        ent.angles = ent.angles + (ent.avelocity *  toss_frametime);
        tracebox_skipnonsolid(ent.origin, ent.mins, ent.maxs, ent.origin + (ent.velocity * toss_frametime), FALSE, ent);
        if (trace_fraction < 1) break;
        ent.origin = trace_endpos;
    }
    ent.velocity = velocity_save;
    ent.avelocity = avelocity_save;
    ent.origin = origin_save;
    ent.angles = angles_save;
}

/*
==================
traceline_antilag

A version of traceline that must be used by SOLID_SLIDEBOX things that want to hit SOLID_CORPSE things with a trace attack
Additionally it moves players back into the past before the trace and restores them afterward.
==================
*/
void tracebox_antilag_force (entity source, vector v1, vector mi, vector ma, vector v2, float nomonst, entity forent, float lag)
{
	local entity player;
	local float _oldsolid;

	// check whether antilagged traces are enabled
	if (lag < 0.001)
		lag = 0;
	if (clienttype(forent) != CLIENTTYPE_REAL)
		lag = 0; // only antilag for clients

	// change shooter to SOLID_BBOX so the shot can hit corpses
	if(source)
	{
		_oldsolid = source.dphitcontentsmask;
		source.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_CORPSE;
	}

	if (lag)
	{
		// take players back into the past
		player = player_list;
		while (player)
		{
			antilag_takeback(player, time - lag);
			player = player.nextplayer;
		}
	}

	// do the trace
	tracebox_skipnonsolid (v1, mi, ma, v2, nomonst, forent);

	// restore players to current positions
	if (lag)
	{
		player = player_list;
		while (player)
		{
			antilag_restore(player);
			player = player.nextplayer;
		}
	}

	// restore shooter solid type
	if(source)
		source.dphitcontentsmask = _oldsolid;
}

void traceline_antilag_force(entity source, vector v1, vector v2, float nomonst, entity forent, float lag) {
    tracebox_antilag_force(source, v1, '0 0 0', '0 0 0', v2, nomonst, forent, lag);
}

void traceline_antilag(entity source, vector v1, vector v2, float nomonst, entity forent) {
    float lag;
    if(cvar("g_antilag") != 2)
        lag = 0;
    else if(forent.antilag_debug)
        lag = forent.antilag_debug;
    else
        lag = ANTILAG_LATENCY(forent);

    traceline_antilag_force(source, v1, v2, nomonst, forent, lag);
}

void tracebox_antilag(entity source, vector v1, vector mi, vector ma, vector v2, float nomonst, entity forent) {
    float lag;

    if(cvar("g_antilag") != 2)
        lag = 0;
    else if(forent.antilag_debug)
        lag = forent.antilag_debug;
    else
        lag = ANTILAG_LATENCY(forent);

    tracebox_antilag_force(source, v1, mi, ma, v2, nomonst, forent, lag);
}


/*
==================
tracerail

Traces a straight line from start to end, passing through solid entities and marking them. Stops upon hitting a BSP_SOLID.
Stores the trace state for each hit entity in its .tracerail_* fields (e.g. trace_endpos -> e.tracerail_endpos).
Each hit entity gets a reference to the next one stored in .tracerail_next and TRUE in .tracerail_hit.
Returns the first hit entity.

You HAVE to call tracerail_finalize() on the first hit entity as soon as you don't need the trace information anymore.
You can't call another tracerail() before tracerail_finalize().
(hint: do NOT call it inside of Damage())
==================
*/

float tracerail_active;
.float tracerail_hit;
.entity tracerail_next;
.float tracerail_allsolid;
.float tracerail_startsolid;
.float tracerail_fraction;
.vector tracerail_endpos;
.vector tracerail_plane_normal;
.float tracerail_plane_dist;
.float tracerail_inopen;
.float tracerail_inwater;
.float tracerail_oldsolid;
.float tracerail_dpstartcontents;
.float tracerail_dphitcontents;
.float tracerail_dphitq3surfaceflags;
.string tracerail_dphittexturename;

entity tracerail(vector start, vector end, float t, entity forent) {
    float tries;
    entity first, last, e;
    
    if(tracerail_active) {
        backtrace("Attempted to tracerail before finalizing a previous tracerail - things will break.");
        traceline(start, end, t, forent);
        return trace_ent;
    }

    tracerail_active = TRUE;

    while(TRUE) {
        traceline_skipnonsolid(start, end, t, forent);

        if(!trace_ent) {
            if(trace_fraction == 1)
                break;

            if(!cvar("sv_gameplayfix_zerohitcontents") || trace_dphitcontents)
                break;
            
            if(++tries == 3)
                break;
            
            start = trace_endpos;
            continue;
        }

        if(!first)
            first = trace_ent;

        if(last)
            last.tracerail_next = trace_ent;

        last = trace_ent;
        last.tracerail_hit = TRUE;
        last.tracerail_oldsolid = last.solid;
        last.tracerail_allsolid = trace_allsolid;
        last.tracerail_startsolid = trace_startsolid;
        last.tracerail_fraction = trace_fraction;
        last.tracerail_endpos = trace_endpos;
        last.tracerail_plane_normal = trace_plane_normal;
        last.tracerail_plane_dist = trace_plane_dist;
        last.tracerail_inopen = trace_inopen;
        last.tracerail_inwater = trace_inwater;
        last.tracerail_dpstartcontents = trace_dpstartcontents;
        last.tracerail_dphitcontents = trace_dphitcontents;
        last.tracerail_dphitq3surfaceflags = trace_dphitq3surfaceflags;
        last.tracerail_dphittexturename = trace_dphittexturename;

        if(trace_ent.solid == SOLID_BSP && trace_dphitcontents & DPCONTENTS_OPAQUE)
            break;

        // make it non-solid so we can hit the next one
        trace_ent.solid = SOLID_NOT;
    }

    // restore solid
    for(e = first; e; e = e.tracerail_next)
        e.solid = e.tracerail_oldsolid;

    return first;
}

void tracerail_finalize(entity ents) {
    entity ent, ent2;

    for(ent = ents; ent; ent = ent2) {
        ent2 = ent.tracerail_next;

        ent.tracerail_oldsolid = 0;
        ent.tracerail_allsolid = 0;
        ent.tracerail_startsolid = 0;
        ent.tracerail_fraction = 0;
        ent.tracerail_endpos = '0 0 0';
        ent.tracerail_plane_normal = '0 0 0';
        ent.tracerail_plane_dist = 0;
        ent.tracerail_inopen = 0;
        ent.tracerail_inwater = 0;
        ent.tracerail_dpstartcontents = 0;
        ent.tracerail_dphitcontents = 0;
        ent.tracerail_dphitq3surfaceflags = 0;
        ent.tracerail_dphittexturename = string_null;

        ent.tracerail_hit = FALSE;
        ent.tracerail_next = world;
    }

    tracerail_active = FALSE;
}

entity tracerail_antilag_force(entity source, vector start, vector end, float t, entity forent, float lag) {
    entity player, e;
    float oldmask;

    if(lag < 0.001)
        lag = 0;

    if(lag)
    if(clienttype(source) != CLIENTTYPE_REAL)
        lag = 0;

    if(source) {
        oldmask = source.dphitcontentsmask;
        source.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_CORPSE;
    }

    if(lag) for(player = player_list; player; player = player.nextplayer)
        antilag_takeback(player, time - lag);

    e = tracerail(start, end, t, forent);

    if(lag) for(player = player_list; player; player = player.nextplayer)
        antilag_restore(player);

    if(source)
        source.dphitcontentsmask = oldmask;

    return e;
}

entity tracerail_antilag(entity source, vector start, vector end, float t, entity forent) {
    float lag;

    if(cvar("g_antilag") != 2)
        lag = 0;
    else if(forent.antilag_debug)
        lag = forent.antilag_debug;
    else
        lag = ANTILAG_LATENCY(forent);

    return tracerail_antilag_force(source, start, end, t, forent, lag);
}

float tracebox_inverted (vector v1, vector mi, vector ma, vector v2, float nomonsters, entity forent) // returns the number of traces done, for benchmarking
{
	vector pos, dir, t;
	float nudge;

	//nudge = 2 * cvar("collision_impactnudge"); // why not?
	nudge = 0.5;

	dir = normalize(v2 - v1);

	pos = v1 + dir * nudge;

	float c;
	c = 0;

	for(;;)
	{
		if((pos - v1) * dir >= (v2 - v1) * dir)
		{
			// went too far
			trace_fraction = 1;
			trace_endpos = v2;
			return c;
		}

		tracebox(pos, mi, ma, v2, nomonsters, forent);
		++c;

		if(c == 50)
		{
			dprint("HOLY SHIT! When tracing from ", vtos(v1), " to ", vtos(v2), "\n");
			dprint("  Nudging gets us nowhere at ", vtos(pos), "\n");
			dprint("  trace_endpos is ", vtos(trace_endpos), "\n");
			dprint("  trace distance is ", ftos(vlen(pos - trace_endpos)), "\n");
		}

		if(trace_startsolid)
		{
			// we started inside solid.
			// then trace from endpos to pos
			t = trace_endpos;
			tracebox(t, mi, ma, pos, nomonsters, forent);
			++c;
			if(trace_startsolid)
			{
				// t is still inside solid? bad
				// force advance, then, and retry
				pos = t + dir * nudge;
			}
			else
			{
				// we actually LEFT solid!
				trace_fraction = ((trace_endpos - v1) * dir) / ((v2 - v1) * dir);
				return c;
			}
		}
		else
		{
			// pos is outside solid?!? but why?!? never mind, just return it.
			trace_endpos = pos;
			trace_fraction = ((trace_endpos - v1) * dir) / ((v2 - v1) * dir);
			return c;
		}
	}
}

void traceline_inverted (vector v1, vector v2, float nomonsters, entity forent)
{
#if 0
	vector pos, dir, t;
	float nudge;

	//nudge = 2 * cvar("collision_impactnudge"); // why not?
	nudge = 0.5;

	dir = normalize(v2 - v1);

	pos = v1 + dir * nudge;

	for(;;)
	{
		if((pos - v1) * dir >= (v2 - v1) * dir)
		{
			// went too far
			trace_fraction = 1;
			return;
		}

		traceline(pos, v2, nomonsters, forent);

		if(trace_startsolid)
		{
			// we started inside solid.
			// then trace from endpos to pos
			t = trace_endpos;
			traceline(t, pos, nomonsters, forent);
			if(trace_startsolid)
			{
				// t is inside solid? bad
				// force advance, then
				pos = pos + dir * nudge;
			}
			else
			{
				// we actually LEFT solid!
				trace_fraction = ((trace_endpos - v1) * dir) / ((v2 - v1) * dir);
				return;
			}
		}
		else
		{
			// pos is outside solid?!? but why?!? never mind, just return it.
			trace_endpos = pos;
			trace_fraction = ((trace_endpos - v1) * dir) / ((v2 - v1) * dir);
			return;
		}
	}
#else
	tracebox_inverted(v1, '0 0 0', '0 0 0', v2, nomonsters, forent);
}

/*
==================
findbetterlocation

Returns a point at least 12 units away from walls
(useful for explosion animations, although the blast is performed where it really happened)
Ripped from DPMod
==================
*/
vector findbetterlocation (vector org, float mindist)
{
	vector	loc;
	vector vec;
	float c, h;

	vec = mindist * '1 0 0';
	c = 0;
	while (c < 6)
	{
		traceline (org, org + vec, TRUE, world);
		vec = vec * -1;
		if (trace_fraction < 1)
		{
			loc = trace_endpos;
			traceline (loc, loc + vec, TRUE, world);
			if (trace_fraction >= 1)
				org = loc + vec;
		}
		if (c & 1)
		{
			h = vec_y;
			vec_y = vec_x;
			vec_x = vec_z;
			vec_z = h;
		}
		c = c + 1;
	}

	return org;
}

/*
==================
crandom

Returns a random number between -1.0 and 1.0
==================
*/
float crandom (void)
{
	return 2 * (random () - 0.5);
}

/*
==================
Angc used for animations
==================
*/


float angc (float a1, float a2)
{
	float	a;

	while (a1 > 180)
		a1 = a1 - 360;
	while (a1 < -179)
		a1 = a1 + 360;

	while (a2 > 180)
		a2 = a2 - 360;
	while (a2 < -179)
		a2 = a2 + 360;

	a = a1 - a2;
	while (a > 180)
		a = a - 360;
	while (a < -179)
		a = a + 360;

	return a;
}

.string lodtarget1;
.string lodtarget2;
.string lodmodel1;
.string lodmodel2;
.float lodmodelindex0;
.float lodmodelindex1;
.float lodmodelindex2;
.float loddistance1;
.float loddistance2;

vector NearestPointOnBox(entity box, vector org);
float LOD_customize()
{
	float d;

	if(cvar("loddebug"))
	{
		d = cvar("loddebug");
		if(d == 1)
			self.modelindex = self.lodmodelindex0;
		else if(d == 2)
			self.modelindex = self.lodmodelindex1;
		else // if(d == 3)
			self.modelindex = self.lodmodelindex2;
		return TRUE;
	}

	// TODO csqc network this so it only gets sent once
	d = vlen(NearestPointOnBox(self, other.origin) - other.origin);
	if(d < self.loddistance1)
		self.modelindex = self.lodmodelindex0;
	else if(!self.lodmodelindex2 || d < self.loddistance2)
		self.modelindex = self.lodmodelindex1;
	else
		self.modelindex = self.lodmodelindex2;

	return TRUE;
}

void LOD_uncustomize()
{
	self.modelindex = self.lodmodelindex0;
}

void LODmodel_attach()
{
	entity e;

	if(!self.loddistance1)
		self.loddistance1 = 1000;
	if(!self.loddistance2)
		self.loddistance2 = 2000;
	self.lodmodelindex0 = self.modelindex;

	if(self.lodtarget1 != "")
	{
		e = find(world, targetname, self.lodtarget1);
		if(e)
		{
			self.lodmodel1 = e.model;
			remove(e);
		}
	}
	if(self.lodtarget2 != "")
	{
		e = find(world, targetname, self.lodtarget2);
		if(e)
		{
			self.lodmodel2 = e.model;
			remove(e);
		}
	}

	if(cvar("loddebug") < 0)
	{
		self.lodmodel1 = self.lodmodel2 = ""; // don't even initialize
	}

	if(self.lodmodel1 != "")
	{
		vector mi, ma;
		mi = self.mins;
		ma = self.maxs;

		precache_model(self.lodmodel1);
		setmodel(self, self.lodmodel1);
		self.lodmodelindex1 = self.modelindex;

		if(self.lodmodel2 != "")
		{
			precache_model(self.lodmodel2);
			setmodel(self, self.lodmodel2);
			self.lodmodelindex2 = self.modelindex;
		}

		self.modelindex = self.lodmodelindex0;
		setsize(self, mi, ma);
	}

	if(self.lodmodelindex1)
		SetCustomizer(self, LOD_customize, LOD_uncustomize);
}

void SetBrushEntityModel()
{
 	if(self.model != "")
 	{
 		precache_model(self.model);
 		setmodel(self, self.model); // no precision needed
		InitializeEntity(self, LODmodel_attach, INITPRIO_FINDTARGET);
 	}
	setorigin(self, self.origin);
	if(self.scale)
		setsize(self, self.mins * self.scale, self.maxs * self.scale);
	else
		setsize(self, self.mins, self.maxs);
}

void SetBrushEntityModelNoLOD()
{
 	if(self.model != "")
 	{
 		precache_model(self.model);
 		setmodel(self, self.model); // no precision needed
 	}
	setorigin(self, self.origin);
	if(self.scale)
		setsize(self, self.mins * self.scale, self.maxs * self.scale);
	else
		setsize(self, self.mins, self.maxs);
}

/*
================
InitTrigger
================
*/

void SetMovedir()
{
	if (self.movedir != '0 0 0')
		self.movedir = normalize(self.movedir);
	else
	{
		makevectors (self.angles);
		self.movedir = v_forward;
	}

	self.angles = '0 0 0';
};

void InitTrigger()
{
// trigger angles are used for one-way touches.  An angle of 0 is assumed
// to mean no restrictions, so use a yaw of 360 instead.
	if (self.movedir == '0 0 0')
	if (self.angles != '0 0 0')
		SetMovedir ();
	self.solid = SOLID_TRIGGER;
	SetBrushEntityModel();
	self.movetype = MOVETYPE_NONE;
	self.modelindex = 0;
	self.model = "";
};

void InitSolidBSPTrigger()
{
// trigger angles are used for one-way touches.  An angle of 0 is assumed
// to mean no restrictions, so use a yaw of 360 instead.
	if (self.movedir == '0 0 0')
	if (self.angles != '0 0 0')
		SetMovedir ();
	self.solid = SOLID_BSP;
	SetBrushEntityModel();
	self.movetype = MOVETYPE_NONE; // why was this PUSH? -div0
//	self.modelindex = 0;
	self.model = "";
};

float InitMovingBrushTrigger()
{
// trigger angles are used for one-way touches.  An angle of 0 is assumed
// to mean no restrictions, so use a yaw of 360 instead.
	self.solid = SOLID_BSP;
	SetBrushEntityModel();
	self.movetype = MOVETYPE_PUSH;
	if(self.modelindex == 0)
	{
		objerror("InitMovingBrushTrigger: no brushes found!");
		return 0;
	}
	return 1;
};
