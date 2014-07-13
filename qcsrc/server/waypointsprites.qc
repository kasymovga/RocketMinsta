..entity owned_by_field;
.float rule;
.string model1;
.string model2;
.string model3;
.vector clr1;
.vector clr2;
.vector clr3;
.float ownerteam;

.float(entity) waypointsprite_visible_for_player;

void WaypointSprite_UpdateSprites(entity e, string m1, string m2, string m3)
{
	if(m1 != e.model1)
	{
        if(e.model1)
            strunzone(e.model1);
		e.model1 = strzone(m1);
		e.SendFlags |= 2;
	}
	if(m2 != e.model2)
	{
		if(e.model2)
            strunzone(e.model2);
		e.model2 = strzone(m2);
		e.SendFlags |= 4;
	}
	if(m3 != e.model3)
	{
		if(e.model3)
            strunzone(e.model3);
		e.model3 = strzone(m3);
		e.SendFlags |= 8;
	}
}

void WaypointSprite_UpdateTextColors(entity e, vector cl1, vector cl2, vector cl3) {
    if(cl1 != e.clr1 || cl2 != e.clr2 || cl3 != e.clr3) {
        e.clr1 = cl1;
        e.clr2 = cl2;
        e.clr3 = cl3;
        e.SendFlags |= 32;
    }
}

void WaypointSprite_UpdateHealth(entity e, float f)
{
	f = bound(0, f, e.max_health);
	if(f != e.health || e.pain_finished)
	{
		e.health = f;
		e.pain_finished = 0;
		e.SendFlags |= 0x80;
	}
}

void WaypointSprite_UpdateMaxHealth(entity e, float f)
{
    if(!f)
        f = -1;
    
	if(f != e.max_health || e.pain_finished)
	{
		e.max_health = f;
		e.pain_finished = 0;
		e.SendFlags |= 0x80;
	}
}

void WaypointSprite_UpdateBuildFinished(entity e, float f)
{
	if(f != e.pain_finished || e.max_health)
	{
		e.max_health = 0;
		e.pain_finished = f;
		e.SendFlags |= 0x80;
	}
}

void WaypointSprite_UpdateOrigin(entity e, vector o)
{
	if(o != e.origin)
	{
		setorigin(e, o);
		e.SendFlags |= 64;
	}
}

void WaypointSprite_UpdateRule(entity e, float t, float r)
{
	// no check, as this is never called without doing an actual change (usually only once)
	e.rule = r;
	e.team = t;
	e.SendFlags |= 1;
}

void WaypointSprite_UpdateTeamRadar(entity e, float icon, vector col)
{
	// no check, as this is never called without doing an actual change (usually only once)
	e.cnt = (icon & 0x7F) | (e.cnt & 0x80);
	e.colormod = col;
	e.SendFlags |= 32;
}

void WaypointSprite_Ping(entity e)
{
	// ALWAYS sends (this causes a radar circle), thus no check

    if(!e)
        return;

	e.cnt |= 0x80;
	e.SendFlags |= 32;
}

void WaypointSprite_FadeOutIn(entity e, float t)
{
	if(!e.fade_time)
	{
		e.fade_time = t;
		e.teleport_time = time + t;
	}
	else if(t < (e.teleport_time - time))
	{
		// accelerate the waypoint's dying
		// ensure:
		//   (e.teleport_time - time) / wp.fade_time stays
		//   e.teleport_time = time + fadetime
		float current_fadetime;
		current_fadetime = e.teleport_time - time;
		e.teleport_time = time + t;
		e.fade_time = e.fade_time * t / current_fadetime;
	}

	e.SendFlags |= 16;
}

float waypointsprite_limitedrange, waypointsprite_deployed_lifetime, waypointsprite_deadlifetime;
void WaypointSprite_Init()
{
	waypointsprite_limitedrange = cvar("g_waypointsprite_limitedrange");
	waypointsprite_deployed_lifetime = cvar("g_waypointsprite_deployed_lifetime");
	waypointsprite_deadlifetime = cvar("g_waypointsprite_deadlifetime");
}
void WaypointSprite_InitClient(entity e)
{
}

void WaypointSprite_Kill(entity wp)
{
	if(!wp)
		return;
	if(wp.owner)
		wp.owner.(wp.owned_by_field) = world;
    if(wp.model1)
        strunzone(wp.model1);
    if(wp.model2)
        strunzone(wp.model2);
    if(wp.model3)
        strunzone(wp.model3);
	remove(wp);
}

void WaypointSprite_Disown(entity wp, float fadetime)
{
	if(!wp)
		return;
	if(wp.classname != "sprite_waypoint")
	{
		backtrace("Trying to disown a non-waypointsprite");
		return;
	}
	if(wp.owner)
	{
		if(wp.exteriormodeltoclient == wp.owner)
			wp.exteriormodeltoclient = world;
		wp.owner.(wp.owned_by_field) = world;
		wp.owner = world;

		WaypointSprite_FadeOutIn(wp, fadetime);
	}
}

void WaypointSprite_Think()
{
	float doremove;

	doremove = FALSE;

	if(self.fade_time)
	{
		if(time >= self.teleport_time)
			doremove = TRUE;
	}

	if(self.exteriormodeltoclient)
		WaypointSprite_UpdateOrigin(self, self.exteriormodeltoclient.origin + self.view_ofs);

	if(doremove)
		WaypointSprite_Kill(self);
	else
		self.nextthink = time; // WHY?!?
}

float WaypointSprite_visible_for_player(entity e)
{
	// personal waypoints
	if(self.enemy)
		if(self.enemy != e) {
			return FALSE;
        }
        
	// team waypoints
	if(self.team && self.rule == SPRITERULE_DEFAULT)
	{
		if(self.team != e.team)
			return FALSE;
		if(e.classname != "player")
			return FALSE;
	}
    
	return TRUE;
}

float WaypointSprite_Customize()
{
	// this is not in SendEntity because it shall run every frame, not just every update
    
	// make spectators see what the player would see
	entity e;
	e = other;
	if(e.classname == "spectator")
		e = e.enemy;

	return self.waypointsprite_visible_for_player(e);
}

void WriteColor(float msg, vector c) {
    WriteByte(MSG_ENTITY, c_x * 255.0);
    WriteByte(MSG_ENTITY, c_y * 255.0);
    WriteByte(MSG_ENTITY, c_z * 255.0);
}

float WaypointSprite_SendEntity(entity to, float sendflags)
{
	float dt;

	WriteByte(MSG_ENTITY, ENT_CLIENT_WAYPOINT);

    if(!self.pain_finished && !self.max_health)
        sendflags &~= 0x80;

    // sendflags = sendflags & 0x7F;
	
	if(g_nexball)
		sendflags &~= 0x80;
    // else if(self.max_health || (self.pain_finished && (time < self.pain_finished + 0.25)))
    // sendflags |= 0x80;
    //
    //  ...
    //
    //  I wonder what the fuck was this here for. Other than wasting my time.
    //

	WriteByte(MSG_ENTITY, sendflags);

	if(sendflags & 0x80)
	{
		if(self.max_health > 0)
		{
            WriteByte(MSG_ENTITY, (self.health / self.max_health) * 191.0);
		}
		else
		{
			dt = self.pain_finished - time;
			dt = bound(0, dt * 32, 16383);
			WriteByte(MSG_ENTITY, (dt & 0xFF00) / 256 + 192);
			WriteByte(MSG_ENTITY, (dt & 0x00FF));
		}
	}

	if(sendflags & 64)
	{
		WriteCoord(MSG_ENTITY, self.origin_x);
		WriteCoord(MSG_ENTITY, self.origin_y);
		WriteCoord(MSG_ENTITY, self.origin_z);
	}

	if(sendflags & 1)
	{
		WriteByte(MSG_ENTITY, self.team);
		WriteByte(MSG_ENTITY, self.rule);
        if(self.rule == SPRITERULE_DEFAULT)
            WriteByte(MSG_ENTITY, self.ownerteam);
	}

    if(sendflags & 2) {
        WriteString(MSG_ENTITY, self.model1);
        if(self.model1 == "Frozen!")    // hack for Freeze - attach waypoint to shownames
            WriteByte(MSG_ENTITY, num_for_edict(self.exteriormodeltoclient));
    }

	if(sendflags & 4)
		WriteString(MSG_ENTITY, self.model2);

	if(sendflags & 8)
		WriteString(MSG_ENTITY, self.model3);

	if(sendflags & 16)
	{
		WriteCoord(MSG_ENTITY, self.fade_time);
		WriteCoord(MSG_ENTITY, self.teleport_time);
		WriteShort(MSG_ENTITY, self.fade_rate); // maxdist
		float f;
		f = 0;
		if(self.currentammo)
			f |= 1; // hideable
		if(self.exteriormodeltoclient == to)
			f |= 2; // my own
		WriteByte(MSG_ENTITY, f);
	}

	if(sendflags & 32)
	{
		WriteByte(MSG_ENTITY, self.cnt); // icon on radar
		WriteColor(MSG_ENTITY, self.colormod);
        WriteColor(MSG_ENTITY, self.clr1);
        WriteColor(MSG_ENTITY, self.clr2);
        WriteColor(MSG_ENTITY, self.clr3);
	}
    
    return TRUE;
}

void WaypointSprite_Reset()
{
	// if a WP wants to time out, let it time out immediately; other WPs ought to be reset/killed by their owners

	if(self.fade_time) // there was there before: || g_keyhunt, do we really need this?
		WaypointSprite_Kill(self);
}

entity WaypointSprite_Spawn(
	string spr, // sprite
	float lifetime, float maxdistance, // lifetime, max distance
	entity ref, vector ofs, // position
	entity showto, float t, // show to whom? Use a flag to indicate a team
	entity own, .entity ownfield, // remove when own gets killed
	float hideable // true when it should be controlled by cl_hidewaypoints
)
{
	entity wp;
	wp = spawn();
	wp.classname = "sprite_waypoint";
	wp.teleport_time = time + lifetime;
	wp.fade_time = lifetime;
	wp.exteriormodeltoclient = ref;
	if(ref)
	{
		wp.view_ofs = ofs;
		setorigin(wp, ref.origin + ofs);
	}
	else
		setorigin(wp, ofs);
	wp.enemy = showto;
	wp.team = t;
	wp.owner = own;
	wp.currentammo = hideable;
	if(own)
	{
		if(own.ownfield)
			remove(own.ownfield);
		own.ownfield = wp;
		wp.owned_by_field = ownfield;
	}
	wp.fade_rate = maxdistance;
	wp.think = WaypointSprite_Think;
	wp.nextthink = time;
	wp.model1 = strzone(spr);
	wp.customizeentityforclient = WaypointSprite_Customize;
	wp.waypointsprite_visible_for_player = WaypointSprite_visible_for_player;
	wp.reset2 = WaypointSprite_Reset;
	Net_LinkEntity(wp, FALSE, 0, WaypointSprite_SendEntity);
	return wp;
}

entity WaypointSprite_SpawnFixed(
	string spr,
	vector ofs,
	entity own,
	.entity ownfield
)
{
	return WaypointSprite_Spawn(spr, 0, 0, world, ofs, world, 0, own, ownfield, TRUE);
}

.entity waypointsprite_deployed_fixed;
entity WaypointSprite_DeployFixed(
	string spr,
	float limited_range,
	vector ofs
)
{
	float t, maxdistance;
	if(teams_matter)
		t = self.team;
	else
		t = 0;
	if(limited_range)
		maxdistance = waypointsprite_limitedrange;
	else
		maxdistance = 0;
	return WaypointSprite_Spawn(spr, waypointsprite_deployed_lifetime, maxdistance, world, ofs, world, t, self, waypointsprite_deployed_fixed, FALSE);
}

.entity waypointsprite_deployed_personal;
entity WaypointSprite_DeployPersonal(
	string spr,
	vector ofs
)
{
	return WaypointSprite_Spawn(spr, 0, 0, world, ofs, world, 0, self, waypointsprite_deployed_personal, FALSE);
}

.entity waypointsprite_attached;
.entity waypointsprite_attachedforcarrier;
entity WaypointSprite_Attach(
	string spr,
	float limited_range
)
{
	float t, maxdistance;
	if(self.waypointsprite_attachedforcarrier)
		return world; // can't attach to FC
	if(teams_matter)
		t = self.team;
	else
		t = 0;
	if(limited_range)
		maxdistance = waypointsprite_limitedrange;
	else
		maxdistance = 0;
	return WaypointSprite_Spawn(spr, waypointsprite_deployed_lifetime, maxdistance, self, '0 0 64', world, t, self, waypointsprite_attached, FALSE);
}

entity WaypointSprite_AttachCarrier(
	string spr,
	entity carrier
)
{
	entity e;
	WaypointSprite_Kill(carrier.waypointsprite_attached); // FC overrides attached
	e = WaypointSprite_Spawn(spr, 0, 0, carrier, '0 0 64', world, carrier.team, carrier, waypointsprite_attachedforcarrier, FALSE);
	if(e)
	{
		WaypointSprite_UpdateMaxHealth(e, '1 0 0' * healtharmor_maxdamage(start_health, start_armorvalue, cvar("g_balance_armor_blockpercent")) * 2);
		WaypointSprite_UpdateHealth(e, '1 0 0' * healtharmor_maxdamage(carrier.health, carrier.armorvalue, cvar("g_balance_armor_blockpercent")));
	}
	return e;
}

void WaypointSprite_DetachCarrier(entity carrier)
{
	WaypointSprite_Disown(carrier.waypointsprite_attachedforcarrier, waypointsprite_deadlifetime);
}

void WaypointSprite_ClearPersonal()
{
	WaypointSprite_Kill(self.waypointsprite_deployed_personal);
}

void WaypointSprite_ClearOwned()
{
	WaypointSprite_Kill(self.waypointsprite_deployed_fixed);
	WaypointSprite_Kill(self.waypointsprite_deployed_personal);
	WaypointSprite_Kill(self.waypointsprite_attached);
}

void WaypointSprite_PlayerDead()
{
	WaypointSprite_Disown(self.waypointsprite_attached, waypointsprite_deadlifetime);
	WaypointSprite_DetachCarrier(self);
}

void WaypointSprite_PlayerGone()
{
	WaypointSprite_Disown(self.waypointsprite_deployed_fixed, waypointsprite_deadlifetime);
	WaypointSprite_Kill(self.waypointsprite_deployed_personal);
	WaypointSprite_Disown(self.waypointsprite_attached, waypointsprite_deadlifetime);
    WaypointSprite_Kill(self.buff_teamwp);
	WaypointSprite_DetachCarrier(self);
}
