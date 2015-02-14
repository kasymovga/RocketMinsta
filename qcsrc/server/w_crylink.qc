.float gravity;
.float crylink_waitrelease;
.entity crylink_lastgroup;

.entity queuenext;
.entity queueprev;
.entity realowner;

string(string format, ...) sprintf = #627;

// These are pretty nifty.
// TODO: maybe move them elsewhere and use for the rest of the weapons?
// Also, this needs a manual update when the autocvars branch is merged.

#define WEP_CVAR(wepname,name) cvar("g_balance_" #wepname "_" #name)
#define WEP_CVAR_PRI(wepname,name) WEP_CVAR(wepname, primary_##name)
#define WEP_CVAR_SEC(wepname,name) WEP_CVAR(wepname, secondary_##name)
#define WEP_CVAR_BOTH(wepname,isprimary,name) ((isprimary) ? WEP_CVAR_PRI(wepname, name) : WEP_CVAR_SEC(wepname, name))

#define MAX_DAMAGEEXTRARADIUS 16

void W_Crylink_CheckLinks(entity e)
{
    float i;
    entity p;

    if not(cvar("developer"))
        return;

    if(e == world)
        print("W_Crylink_CheckLinks: entity is world\n");
    if(e.classname != "spike" || wasfreed(e))
        print("W_Crylink_CheckLinks: entity is not a spike but a ", e.classname, " (freed: ", ftos(wasfreed(e)), ")\n");

    p = e;
    for(i = 0; i < 1000; ++i)
    {
        if(p.queuenext.queueprev != p || p.queueprev.queuenext != p)
            print("W_Crylink_CheckLinks: queue is inconsistent\n");
        p = p.queuenext;
        if(p == e)
            break;
    }
    if(i >= 1000)
        print("W_Crylink_CheckLinks: infinite chain\n");
}

void W_Crylink_Dequeue_Raw(entity own, entity prev, entity me, entity next)
{
    W_Crylink_CheckLinks(next);
    if(me == own.crylink_lastgroup)
        own.crylink_lastgroup = ((me == next) ? world : next);
    prev.queuenext = next;
    next.queueprev = prev;
    me.classname = "spike_oktoremove";
    if(me != next)
        W_Crylink_CheckLinks(next);
}

void W_Crylink_Dequeue(entity e)
{
    W_Crylink_Dequeue_Raw(e.realowner, e.queueprev, e, e.queuenext);
}

void W_Crylink_Reset(void)
{
    W_Crylink_Dequeue(self);
    remove(self);
}

// force projectile to explode
void W_Crylink_LinkExplode(entity e, entity e2)
{
    float a;

    if(e == e2)
        return;

    a = bound(0, 1 - (time - e.fade_time) * e.fade_rate, 1);

    if(e == e.realowner.crylink_lastgroup)
        e.realowner.crylink_lastgroup = world;
        
    float isprimary = !(e.projectiledeathtype & HITTYPE_SECONDARY);
        
    RadiusDamage(e, e.realowner, WEP_CVAR_BOTH(crylink, isprimary, damage) * a, WEP_CVAR_BOTH(crylink, isprimary, edgedamage) * a, WEP_CVAR_BOTH(crylink, isprimary, radius), world, WEP_CVAR_BOTH(crylink, isprimary, force) * a, e.projectiledeathtype, other);

    W_Crylink_LinkExplode(e.queuenext, e2);

    e.classname = "spike_oktoremove";
    remove(e);
}

// adjust towards center
// returns the origin where they will meet... and the time till the meeting is
// stored in w_crylink_linkjoin_time.
// could possibly network this origin and time, and display a special particle
// effect when projectiles meet there :P
// jspeed: joining speed (calculate this as join spread * initial speed)
float w_crylink_linkjoin_time;
vector W_Crylink_LinkJoin(entity e, float jspeed)
{
    vector avg_origin, avg_velocity;
    vector targ_origin;
    float avg_dist, n;
    entity p;

    W_Crylink_CheckLinks(e);

    w_crylink_linkjoin_time = 0;

    avg_origin = e.origin;
    avg_velocity = e.velocity;
    n = 1;
    for(p = e; (p = p.queuenext) != e; )
    {
        avg_origin += p.origin;
        avg_velocity += p.velocity;
        ++n;
    }
    avg_origin *= (1.0 / n);
    avg_velocity *= (1.0 / n);

    if(n < 2)
        return avg_origin; // nothing to do

    // yes, mathematically we can do this in ONE step, but beware of 32bit floats...
    avg_dist = pow(vlen(e.origin - avg_origin), 2);
    for(p = e; (p = p.queuenext) != e; )
        avg_dist += pow(vlen(p.origin - avg_origin), 2);
    avg_dist *= (1.0 / n);
    avg_dist = sqrt(avg_dist);

    if(avg_dist == 0)
        return avg_origin; // no change needed

    if(jspeed == 0)
    {
        e.velocity = avg_velocity;
        UpdateCSQCProjectile(e);
        for(p = e; (p = p.queuenext) != e; )
        {
            p.velocity = avg_velocity;
            UpdateCSQCProjectile(p);
        }
        targ_origin = avg_origin + 1000000000 * normalize(avg_velocity); // HUUUUUUGE
    }
    else
    {
        w_crylink_linkjoin_time = avg_dist / jspeed;
        targ_origin = avg_origin + w_crylink_linkjoin_time * avg_velocity;

        e.velocity = (targ_origin - e.origin) * (1.0 / w_crylink_linkjoin_time);
        UpdateCSQCProjectile(e);
        for(p = e; (p = p.queuenext) != e; )
        {
            p.velocity = (targ_origin - p.origin) * (1.0 / w_crylink_linkjoin_time);
            UpdateCSQCProjectile(p);
        }

        // analysis:
        //   jspeed -> +infinity:
        //      w_crylink_linkjoin_time -> +0
        //      targ_origin -> avg_origin
        //      p->velocity -> HUEG towards center
        //   jspeed -> 0:
        //      w_crylink_linkjoin_time -> +/- infinity
        //      targ_origin -> avg_velocity * +/- infinity
        //      p->velocity -> avg_velocity
        //   jspeed -> -infinity:
        //      w_crylink_linkjoin_time -> -0
        //      targ_origin -> avg_origin
        //      p->velocity -> HUEG away from center
    }

    W_Crylink_CheckLinks(e);

    return targ_origin;
}

void W_Crylink_LinkJoinEffect_Think(void)
{
    // is there at least 2 projectiles very close?
    entity e, p;
    float n;
    e = self.owner.crylink_lastgroup;
    n = 0;
    if(e)
    {
        if(vlen(e.origin - self.origin) < vlen(e.velocity) * frametime)
            ++n;
        for(p = e; (p = p.queuenext) != e; )
        {
            if(vlen(p.origin - self.origin) < vlen(p.velocity) * frametime)
                ++n;
        }
        if(n >= 2)
        {
            float isprimary = !(e.projectiledeathtype & HITTYPE_SECONDARY);
            
            if(WEP_CVAR_BOTH(crylink, isprimary, joinexplode))
            {
                n /= WEP_CVAR_BOTH(crylink, isprimary, shots);
                RadiusDamage(
                    e,
                    e.realowner,
                    WEP_CVAR_BOTH(crylink, isprimary, joinexplode_damage) * n,
                    WEP_CVAR_BOTH(crylink, isprimary, joinexplode_edgedamage) * n,
                    WEP_CVAR_BOTH(crylink, isprimary, joinexplode_radius) * n,
                    e.realowner,
                    WEP_CVAR_BOTH(crylink, isprimary, joinexplode_force) * n,
                    e.projectiledeathtype,
                    other
                );
                pointparticles(particleeffectnum("crylink_joinexplode"), self.origin, '0 0 0', n);
            }
        }
    }
    remove(self);
}

float W_Crylink_Touch_WouldHitFriendly(entity projectile, float rad)
{
    entity head = findradius((projectile.origin + (projectile.mins + projectile.maxs) * 0.5), rad + MAX_DAMAGEEXTRARADIUS);
    float hit_friendly = 0;
    float hit_enemy = 0;

    while(head)
    {
        if((head.takedamage != DAMAGE_NO) && (head.deadflag == DEAD_NO))
        {
            if(IsDifferentTeam(head, projectile.realowner))
                ++hit_enemy;
            else
                ++hit_friendly;
        }
            
        head = head.chain;
    }

    return (hit_enemy ? FALSE : hit_friendly);
}


// NO bounce protection, as bounces are limited!
void W_Crylink_Touch(void)
{
    PROJECTILE_SKIPNONSOLID
    float finalhit;
    float f;
    float isprimary = !(self.projectiledeathtype & HITTYPE_SECONDARY);

    // We can not just use PROJECTILE_TOUCH here, because we have to dequeue before removing.

    if(SUB_OwnerCheck())
        return;

    if(SUB_NoImpactCheck()) {
        W_Crylink_Dequeue(self);
        remove(self);
        return;
    }

    if(trace_ent && trace_ent.solid > SOLID_TRIGGER)
        UpdateCSQCProjectileNextFrame(self);

    float a;
    a = bound(0, 1 - (time - self.fade_time) * self.fade_rate, 1);

    finalhit = ((self.cnt <= 0) || (other.takedamage != DAMAGE_NO));
    if(finalhit)
        f = 1;
    else
        f = WEP_CVAR_BOTH(crylink, isprimary, bouncedamagefactor);
    if(a)
        f *= a;

    float totaldamage = RadiusDamage(self, self.realowner, WEP_CVAR_BOTH(crylink, isprimary, damage) * f, WEP_CVAR_BOTH(crylink, isprimary, edgedamage) * f, WEP_CVAR_BOTH(crylink, isprimary, radius), world, WEP_CVAR_BOTH(crylink, isprimary, force) * f, self.projectiledeathtype, other);
        
    if(totaldamage && ((WEP_CVAR_BOTH(crylink, isprimary, linkexplode) == 2) || ((WEP_CVAR_BOTH(crylink, isprimary, linkexplode) == 1) && !W_Crylink_Touch_WouldHitFriendly(self, WEP_CVAR_BOTH(crylink, isprimary, radius)))))
    {
        if(self == self.realowner.crylink_lastgroup)
            self.realowner.crylink_lastgroup = world;
        W_Crylink_LinkExplode(self.queuenext, self);
        self.classname = "spike_oktoremove";
        remove(self);
        return;
    }
    else if(finalhit)
    {
        // just unlink
        W_Crylink_Dequeue(self);
        remove(self);
        return;
    }
    self.cnt = self.cnt - 1;
    self.angles = vectoangles(self.velocity);
    self.owner = world;
    self.projectiledeathtype |= HITTYPE_BOUNCE;
    // commented out as it causes a little hitch...
    //if(proj.cnt == 0)
    //  CSQCProjectile(proj, TRUE, PROJECTILE_CRYLINK, TRUE);
}


void W_Crylink_Fadethink(void)
{
    W_Crylink_Dequeue(self);
    remove(self);
}

void W_Crylink_SetupProjVelocity(entity proj, vector dir, vector upDir, float pSpeed, float pUpSpeed, float pZSpeed)
{
    dir = dir + upDir * (pUpSpeed / pSpeed);
    dir_z += pZSpeed / pSpeed;
    pSpeed *= vlen(dir);
    dir = normalize(dir);

    proj.velocity = W_CalculateProjectileVelocity(proj.owner.velocity, pSpeed * dir);
}

void W_Crylink_Attack(void)
{
    float counter, shots;
    entity proj, prevproj, firstproj;
    vector s;
    vector forward, right, up;
    float maxdmg;

    if(!(self.items & IT_UNLIMITED_AMMO))
        self.ammo_cells -= WEP_CVAR_PRI(crylink, ammo);

    maxdmg = WEP_CVAR_PRI(crylink, damage) * WEP_CVAR_PRI(crylink, shots);
    maxdmg *= 1 + WEP_CVAR_PRI(crylink, bouncedamagefactor) * WEP_CVAR_PRI(crylink, bounces);
    if(WEP_CVAR_PRI(crylink, joinexplode))
        maxdmg += WEP_CVAR_PRI(crylink, joinexplode_damage);

    W_SetupShot(self, FALSE, 2, "weapons/crylink_fire.wav", maxdmg);
    forward = v_forward;
    right = v_right;
    up = v_up;

    shots = WEP_CVAR_PRI(crylink, shots);
    pointparticles(particleeffectnum("crylink_muzzleflash"), w_shotorg, w_shotdir * 1000, shots);
    proj = prevproj = firstproj = world;
    for(counter = 0; counter < shots; ++counter)
    {
        proj = spawn();
        proj.reset = W_Crylink_Reset;
        proj.realowner = proj.owner = self;
        proj.classname = "spike";
        proj.bot_dodge = TRUE;
        proj.bot_dodgerating = WEP_CVAR_PRI(crylink, damage);
        if(shots == 1) {
            proj.queuenext = proj;
            proj.queueprev = proj;
        }
        else if(counter == 0) { // first projectile, store in firstproj for now
            firstproj = proj;
        }
        else if(counter == shots - 1) { // last projectile, link up with first projectile
            prevproj.queuenext = proj;
            firstproj.queueprev = proj;
            proj.queuenext = firstproj;
            proj.queueprev = prevproj;
        }
        else { // else link up with previous projectile
            prevproj.queuenext = proj;
            proj.queueprev = prevproj;
        }

        prevproj = proj;

        proj.movetype = MOVETYPE_BOUNCEMISSILE;
        PROJECTILE_MAKETRIGGER(proj);
        proj.projectiledeathtype = WEP_CRYLINK;
        //proj.gravity = 0.001;

        setorigin(proj, w_shotorg);
        setsize(proj, '0 0 0', '0 0 0');


        s = '0 0 0';
        if(counter == 0)
            s = '0 0 0';
        else
        {
            makevectors('0 360 0' * (0.75 + (counter - 0.5) / (shots - 1)));
            s_y = v_forward_x;
            s_z = v_forward_y;
        }
        s = s * WEP_CVAR_PRI(crylink, spread);
        W_Crylink_SetupProjVelocity(proj, w_shotdir + right * s_y + up * s_z, v_up, WEP_CVAR_PRI(crylink, speed), 0, 0);
        proj.touch = W_Crylink_Touch;

        proj.think = W_Crylink_Fadethink;
        if(counter == 0)
        {
            proj.fade_time = time + WEP_CVAR_PRI(crylink, middle_lifetime);
            proj.fade_rate = 1 / WEP_CVAR_PRI(crylink, middle_fadetime);
            proj.nextthink = time + WEP_CVAR_PRI(crylink, middle_lifetime) + WEP_CVAR_PRI(crylink, middle_fadetime);
        }
        else
        {
            proj.fade_time = time + WEP_CVAR_PRI(crylink, other_lifetime);
            proj.fade_rate = 1 / WEP_CVAR_PRI(crylink, other_fadetime);
            proj.nextthink = time + WEP_CVAR_PRI(crylink, other_lifetime) + WEP_CVAR_PRI(crylink, other_fadetime);
        }
        proj.teleport_time = time + WEP_CVAR_PRI(crylink, joindelay);
        proj.cnt = WEP_CVAR_PRI(crylink, bounces);
        //proj.scale = 1 + 1 * proj.cnt;

        proj.angles = vectoangles(proj.velocity);

        //proj.glow_size = 20;

        proj.flags = FL_PROJECTILE;
    
        CSQCProjectile(proj, TRUE, (proj.cnt ? PROJECTILE_CRYLINK_BOUNCING : PROJECTILE_CRYLINK), TRUE);

        other = proj;
    }
    if(WEP_CVAR_PRI(crylink, joinspread) != 0)
    {
        self.crylink_lastgroup = proj;
        W_Crylink_CheckLinks(proj);
        self.crylink_waitrelease = 1;
    }
}

void W_Crylink_Attack2(void)
{
    float counter, shots;
    entity proj, prevproj, firstproj;
    vector s;
    vector forward, right, up;
    float maxdmg;

    if(!(self.items & IT_UNLIMITED_AMMO))
        self.ammo_cells -= WEP_CVAR_SEC(crylink, ammo);

    maxdmg = WEP_CVAR_SEC(crylink, damage) * WEP_CVAR_SEC(crylink, shots);
    maxdmg *= 1 + WEP_CVAR_SEC(crylink, bouncedamagefactor) * WEP_CVAR_SEC(crylink, bounces);
    if(WEP_CVAR_SEC(crylink, joinexplode))
        maxdmg += WEP_CVAR_SEC(crylink, joinexplode_damage);

    W_SetupShot(self, FALSE, 2, "weapons/crylink_fire2.wav", maxdmg);
    forward = v_forward;
    right = v_right;
    up = v_up;

    shots = WEP_CVAR_SEC(crylink, shots);
    pointparticles(particleeffectnum("crylink_muzzleflash"), w_shotorg, w_shotdir * 1000, shots);
    proj = prevproj = firstproj = world;
    for(counter = 0; counter < shots; ++counter)
    {
        proj = spawn();
        proj.reset = W_Crylink_Reset;
        proj.realowner = proj.owner = self;
        proj.classname = "spike";
        proj.bot_dodge = TRUE;
        proj.bot_dodgerating = WEP_CVAR_SEC(crylink, damage);
        if(shots == 1) {
            proj.queuenext = proj;
            proj.queueprev = proj;
        }
        else if(counter == 0) { // first projectile, store in firstproj for now
            firstproj = proj;
        }
        else if(counter == shots - 1) { // last projectile, link up with first projectile
            prevproj.queuenext = proj;
            firstproj.queueprev = proj;
            proj.queuenext = firstproj;
            proj.queueprev = prevproj;
        }
        else { // else link up with previous projectile
            prevproj.queuenext = proj;
            proj.queueprev = prevproj;
        }

        prevproj = proj;

        proj.movetype = MOVETYPE_BOUNCEMISSILE;
        PROJECTILE_MAKETRIGGER(proj);
        proj.projectiledeathtype = WEP_CRYLINK | HITTYPE_SECONDARY;
        //proj.gravity = 0.001;

        setorigin(proj, w_shotorg);
        setsize(proj, '0 0 0', '0 0 0');

        if(WEP_CVAR_SEC(crylink, spreadtype) == 1)
        {
            s = '0 0 0';
            if(counter == 0)
                s = '0 0 0';
            else
            {
                makevectors('0 360 0' * (0.75 + (counter - 0.5) / (shots - 1)));
                s_y = v_forward_x;
                s_z = v_forward_y;
            }
            s = s * WEP_CVAR_SEC(crylink, spread);
            s = w_shotdir + right * s_y + up * s_z;
        }
        else
        {
            s = (w_shotdir + (((counter + 0.5) / shots) * 2 - 1) * v_right * WEP_CVAR_SEC(crylink, spread));
        }

        W_Crylink_SetupProjVelocity(proj, s, v_up, WEP_CVAR_SEC(crylink, speed), 0, 0);
        proj.touch = W_Crylink_Touch;
        proj.think = W_Crylink_Fadethink;
        if(counter == (shots - 1) / 2)
        {
            proj.fade_time = time + WEP_CVAR_SEC(crylink, middle_lifetime);
            proj.fade_rate = 1 / WEP_CVAR_SEC(crylink, middle_fadetime);
            proj.nextthink = time + WEP_CVAR_SEC(crylink, middle_lifetime) + WEP_CVAR_SEC(crylink, middle_fadetime);
        }
        else
        {
            proj.fade_time = time + WEP_CVAR_SEC(crylink, other_lifetime);
            proj.fade_rate = 1 / WEP_CVAR_SEC(crylink, other_fadetime);
            proj.nextthink = time + WEP_CVAR_SEC(crylink, other_lifetime) + WEP_CVAR_SEC(crylink, other_fadetime);
        }
        proj.teleport_time = time + WEP_CVAR_SEC(crylink, joindelay);
        proj.cnt = WEP_CVAR_SEC(crylink, bounces);
        //proj.scale = 1 + 1 * proj.cnt;

        proj.angles = vectoangles(proj.velocity);

        //proj.glow_size = 20;

        proj.flags = FL_PROJECTILE;
        
        CSQCProjectile(proj, TRUE, (proj.cnt ? PROJECTILE_CRYLINK_BOUNCING : PROJECTILE_CRYLINK), TRUE);

        other = proj;
    }
    if(WEP_CVAR_SEC(crylink, joinspread) != 0)
    {
        self.crylink_lastgroup = proj;
        W_Crylink_CheckLinks(proj);
        self.crylink_waitrelease = 2;
    }
}

void spawnfunc_weapon_crylink (void)
{
	weapon_defaultspawnfunc(WEP_CRYLINK);
}

float w_crylink(float req)
{
	if (req == WR_AIM)
	{
		if (random() > 0.15)
			self.BUTTON_ATCK = bot_aim(cvar("g_balance_crylink_primary_speed"), 0, cvar("g_balance_crylink_primary_middle_lifetime"), FALSE);
		else
			self.BUTTON_ATCK2 = bot_aim(cvar("g_balance_crylink_secondary_speed"), 0, cvar("g_balance_crylink_secondary_middle_lifetime"), FALSE);
	}
	else if (req == WR_THINK)
	{
		if (self.BUTTON_ATCK)
		if (weapon_prepareattack(0, cvar("g_balance_crylink_primary_refire")))
		{
			W_Crylink_Attack();
			weapon_thinkf(WFRAME_FIRE1, cvar("g_balance_crylink_primary_animtime"), w_ready);
		}

		if (self.BUTTON_ATCK2)
		if (weapon_prepareattack(1, cvar("g_balance_crylink_secondary_refire")))
		{
			W_Crylink_Attack2();
			weapon_thinkf(WFRAME_FIRE2, cvar("g_balance_crylink_secondary_animtime"), w_ready);
		}

        if((self.crylink_waitrelease == 1 && !self.BUTTON_ATCK) || (self.crylink_waitrelease == 2 && !self.BUTTON_ATCK2))
        {
            if(!self.crylink_lastgroup || time > self.crylink_lastgroup.teleport_time)
            {
                // fired and released now!
                if(self.crylink_lastgroup)
                {
                    vector pos;
                    entity linkjoineffect;
                    float isprimary = (self.crylink_waitrelease == 1);
                    
                    pos = W_Crylink_LinkJoin(self.crylink_lastgroup, WEP_CVAR_BOTH(crylink, isprimary, joinspread) * WEP_CVAR_BOTH(crylink, isprimary, speed));

                    linkjoineffect = spawn();
                    linkjoineffect.think = W_Crylink_LinkJoinEffect_Think;
                    linkjoineffect.classname = "linkjoineffect";
                    linkjoineffect.nextthink = time + w_crylink_linkjoin_time;
                    linkjoineffect.owner = self;
                    setorigin(linkjoineffect, pos);

                    sound(linkjoineffect, CHAN_PROJECTILE, "weapons/rm_laser2.wav", VOL_BASE, ATTN_NORM);
                }
                self.crylink_waitrelease = 0;
                if(!w_crylink(WR_CHECKAMMO1) && !w_crylink(WR_CHECKAMMO2))
                if(!(self.items & IT_UNLIMITED_WEAPON_AMMO))
                {
                    // ran out of ammo!
                    self.cnt = WEP_CRYLINK;
                    self.switchweapon = w_getbestweapon(self);
                }
            }
        }
        
	}
	else if (req == WR_PRECACHE)
	{
		precache_sound ("weapons/crylink_fire.wav");
		precache_sound ("weapons/crylink_fire2.wav");
        precache_sound ("weapons/rm_laser2.wav");
	}
	else if (req == WR_SETUP)
		weapon_setup(WEP_CRYLINK);
	else if (req == WR_CHECKAMMO1)
		return self.ammo_cells >= cvar("g_balance_crylink_primary_ammo");
	else if (req == WR_CHECKAMMO2)
		return self.ammo_cells >= cvar("g_balance_crylink_secondary_ammo");
	return TRUE;
};
