
void W_Flak_Projectile_Touch(void) {
    PROJECTILE_TOUCH;

    if(other.takedamage) {
        float damage, bnc, frc;

        if(other != self.enemy && (other != self.realowner || self.projectiledeathtype & HITTYPE_BOUNCE)) {
            if(self.projectiledeathtype & HITTYPE_SECONDARY) {
                bnc = pow(cvar("g_balance_flak_secondary_damage_bouncefactor"), self.cnt);
                damage = cvar("g_balance_flak_secondary_damage") * bnc;
                frc = cvar("g_balance_flak_secondary_force") * bnc;
            } else {
                bnc = pow(cvar("g_balance_flak_primary_damage_bouncefactor"), self.cnt);
                damage = cvar("g_balance_flak_primary_damage") * bnc;
                frc = cvar("g_balance_flak_primary_force") * bnc;
            }

            vector force = normalize(NearestPointOnBox(other, self.origin) - self.origin + self.velocity) * frc;

            self.owner = self.realowner;
            Damage(other, self, self.realowner, damage, self.projectiledeathtype, self.origin, force);

            if(W_Accuracy_IsGoodHit(self.realowner, other))
                W_Accuracy_RegisterActualDamage(self.realowner, WEP_FLAK, damage);
        }

        pointparticles(particleeffectnum("hagar_bounce"), self.origin, self.velocity, 1);

        float passThrough;
        if(self.projectiledeathtype & HITTYPE_SECONDARY)
            passThrough = cvar("g_balance_flak_secondary_passthrough");
        else
            passThrough = cvar("g_balance_flak_primary_passthrough");

        if(passThrough <= 0) {
            remove(self);
            return;
        }

        // semi-fix for "melee" hits
        if(other == self.realowner && !(self.projectiledeathtype & HITTYPE_BOUNCE))
            self.velocity = self.velocity * -1;

        // pass through - we don't want to bounce here, overwrite velocity later
        self.oldvelocity = self.velocity * passThrough;

        // we don't want to hit the same entity again right away
        self.owner = other;
        if(other.iscreature)
            self.enemy = other;
    } else if(other.solid == SOLID_BSP) {   
        spamsound(self, CHAN_PROJECTILE, strcat("weapons/casings", ftos(floor(random() * 3) + 1), ".wav"), VOL_BASE * 0.7, ATTN_NORM);
        //pointparticles(particleeffectnum("hagar_bounce"), self.origin, self.velocity, 1);
        self.owner = world;
        self.projectiledeathtype |= HITTYPE_BOUNCE;
        self.cnt += 1;
    }
}

void W_Flak_Projectile_Think(void) {
    if(time > self.spawnshieldtime) {
        remove(self);
        return;
    }

    if(self.oldvelocity) {
        self.velocity = self.oldvelocity;
        self.oldvelocity = '0 0 0';
        UpdateCSQCProjectile(self);
    }

    self.nextthink = time;
}

entity W_Flak_Projectile(entity o, float damage, float grav, float lt, float spd, float upspd, float bnc, float deathtype) {
    entity e = spawn();
    e.owner = e.realowner = o;
    e.classname = "flak_proj";
    e.bot_dodge = TRUE;
    e.bot_dodgerating = damage;
    e.movetype = MOVETYPE_BOUNCE;
    PROJECTILE_MAKETRIGGER(e);
    e.projectiledeathtype = deathtype;
    e.gravity = grav;
    e.bouncefactor = bnc;
    setorigin(e, w_shotorg);
    setsize(e, '0 0 -3', '0 0 -3');

    e.spawnshieldtime = time + lt;
    e.nextthink = time;
    e.think = W_Flak_Projectile_Think;
    e.touch = W_Flak_Projectile_Touch;
    e.velocity = v_forward * spd + v_up * upspd;
    W_SetupProjectileVelocity(e);

    e.angles = vectoangles(e.velocity);
    e.flags = FL_PROJECTILE;

    CSQCProjectile(e, TRUE, PROJECTILE_FLAK, TRUE);   
    return e;
}

void W_Flak_Attack1(void) {
    float pcount = cvar("g_balance_flak_primary_projectiles"), i;

    if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
        self.ammo_shells -= cvar("g_balance_flak_primary_ammo");

    float damage = cvar("g_balance_flak_primary_damage");
    W_SetupShot_ProjectileSize(self, '0 0 -3', '0 0 -3', FALSE, 4, "weapons/flak_fire.wav", damage * pcount);
    w_shotdir = v_forward;

    float mygravity = cvar("g_balance_flak_primary_gravity");
    float lifetime = cvar("g_balance_flak_primary_lifetime");
    float myspeed = cvar("g_balance_flak_primary_speed");
    float speed_up = cvar("g_balance_flak_primary_speed_up");
    float mybouncefactor = cvar("g_balance_flak_primary_bouncefactor");
    float spread_up = cvar("g_balance_flak_primary_spread_up");
    float spread_side = cvar("g_balance_flak_primary_spread_side");

    for(i = 0; i < pcount; ++i) {
        vector a = vectoangles(w_shotdir);

        fixedmakevectors(a + '1 0 0' *  random() * spread_up + '0 1 0' * crandom() * spread_side);

        W_Flak_Projectile(self, damage, mygravity, lifetime, myspeed, speed_up, mybouncefactor, WEP_FLAK);
    }

    entity flash = spawn();
    setmodel(flash, "models/uziflash.md3");
    flash.think = SUB_Remove;
    flash.nextthink = time + 0.06;
    flash.effects = EF_ADDITIVE | EF_FULLBRIGHT | EF_LOWPRECISION;
    W_AttachToShotorg(flash, '5 0 0');
}

void W_Flak_Attack2(void) {
    float pcount = cvar("g_balance_flak_secondary_projectiles"), i;

    if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
        self.ammo_shells -= cvar("g_balance_flak_secondary_ammo");

    float damage = cvar("g_balance_flak_secondary_damage");
    W_SetupShot_ProjectileSize(self, '0 0 -3', '0 0 -3', FALSE, 4, "weapons/flak_fire2.wav", damage * pcount);
    w_shotdir = v_forward;

    float mygravity = cvar("g_balance_flak_secondary_gravity");
    float lifetime = cvar("g_balance_flak_secondary_lifetime");
    float myspeed = cvar("g_balance_flak_secondary_speed");
    float speed_up = cvar("g_balance_flak_secondary_speed_up");
    float mybouncefactor = cvar("g_balance_flak_secondary_bouncefactor");
    float spread_up = cvar("g_balance_flak_secondary_spread_up");
    float spread_side = cvar("g_balance_flak_secondary_spread_side");

    for(i = 0; i < pcount; ++i) {
        vector a = vectoangles(w_shotdir);

        fixedmakevectors(a + '1 0 0' *  random() * spread_up + '0 1 0' * crandom() * spread_side);

        W_Flak_Projectile(self, damage, mygravity, lifetime, myspeed, speed_up, mybouncefactor,
                          WEP_FLAK | HITTYPE_SECONDARY | HITTYPE_BOUNCE);
    }

    entity flash = spawn();
    setmodel(flash, "models/uziflash.md3");
    flash.think = SUB_Remove;
    flash.nextthink = time + 0.06;
    flash.effects = EF_ADDITIVE | EF_FULLBRIGHT | EF_LOWPRECISION;
    W_AttachToShotorg(flash, '5 0 0');
}

void W_Flak_Bomb_Explode(void) {
    vector dir = normalize(self.velocity);
    dir = dir - 2 * (dir * trace_plane_normal) * trace_plane_normal; 

    if(other.takedamage == DAMAGE_AIM)
        if(other.classname == "player")
            if(IsDifferentTeam(self.owner, other))
                if(IsFlying(other))
                    announce(self.owner, "announcer/male/airshot.wav");

    self.event_damage = SUB_Null;
    self.takedamage = DAMAGE_NO;
    RadiusDamage(self, self.owner, cvar("g_balance_flak_secondary_bomb_damage"), cvar("g_balance_flak_secondary_bomb_edgedamage"), cvar("g_balance_flak_secondary_bomb_radius"), world, cvar("g_balance_flak_secondary_bomb_force"), self.projectiledeathtype, other);

    float i, c = cvar("g_balance_flak_secondary_projectiles");
    w_shotorg = self.origin;

    float spread_up, spread_side;

    if(other.takedamage == DAMAGE_AIM && other.iscreature) {
        spread_side = 360;
        spread_up = 360;
    } else {
        spread_side = cvar("g_balance_flak_secondary_spread_side");
        spread_up = cvar("g_balance_flak_secondary_spread_up");
    }

    float damage = cvar("g_balance_flak_secondary_damage");
    float mygravity = cvar("g_balance_flak_secondary_gravity");
    float lifetime = cvar("g_balance_flak_secondary_lifetime");
    float myspeed = cvar("g_balance_flak_secondary_speed");
    float speed_up = cvar("g_balance_flak_secondary_speed_up");
    float mybouncefactor = cvar("g_balance_flak_secondary_bouncefactor");

    for(i = 0; i < c; ++i) {
        vector a = vectoangles(dir);

        fixedmakevectors(a + '1 0 0' * crandom() * spread_up
                           + '0 1 0' * crandom() * spread_side);

        entity p = W_Flak_Projectile(self.owner, damage, mygravity, lifetime, myspeed, speed_up, mybouncefactor,
                          WEP_FLAK | HITTYPE_SECONDARY | HITTYPE_BOUNCE);

        // do not hit the direct hit entity with shrapnel right away (causes very inconsistent behavior)
        p.owner = other;
    }

    remove (self);
}

void W_Flak_Bomb_Touch(void) {
    PROJECTILE_TOUCH;
    self.use();
}

void W_Flak_Bomb_Damage(entity inflictor, entity attacker, float damage, float deathtype, vector hitloc, vector force) {
    W_Grenade_Damage(inflictor, attacker, damage, deathtype, hitloc, force);
}

void W_Flak_Attack3(void) {
    if not(self.items & IT_UNLIMITED_WEAPON_AMMO) {
        self.ammo_shells = self.ammo_shells - cvar("g_balance_flak_secondary_ammo");
        self.ammo_rockets = self.ammo_rockets - cvar("g_balance_flak_secondary_ammo_rockets");
    }

    W_SetupShot_ProjectileSize (self, '0 0 -3', '0 0 -3', FALSE, 4, "weapons/flak_fire3.wav", cvar("g_balance_flak_secondary_bomb_damage"));
    w_shotdir = v_forward;

    entity e = spawn();
    e.owner = self;
    e.classname = "flak_bomb";
    e.bot_dodge = TRUE;
    e.bot_dodgerating = cvar("g_balance_flak_secondary_bomb_damage");
    e.movetype = MOVETYPE_BOUNCE;
    PROJECTILE_MAKETRIGGER(e);
    e.projectiledeathtype = WEP_FLAK | HITTYPE_SECONDARY;
    setsize(e, '0 0 -3', '0 0 -3');
    setorigin(e, w_shotorg);

    e.nextthink = time + cvar("g_balance_flak_secondary_bomb_lifetime");
    e.think = adaptor_think2use;
    e.use = W_Flak_Bomb_Explode;
    e.touch = W_Flak_Bomb_Touch;
    e.takedamage = DAMAGE_YES;
    e.health = cvar("g_balance_flak_secondary_bomb_health");
    e.damageforcescale = cvar("g_balance_flak_secondary_bomb_damageforcescale");
    e.event_damage = W_Flak_Bomb_Damage;
    e.velocity = w_shotdir * cvar("g_balance_flak_secondary_bomb_speed") + v_up * cvar("g_balance_flak_secondary_bomb_speed_up");
    W_SetupProjectileVelocity(e);

    e.angles = vectoangles(e.velocity);
    e.flags = FL_PROJECTILE;

    CSQCProjectile(e, TRUE, PROJECTILE_FLAK_BOMB, TRUE);
}

void spawnfunc_weapon_flak(void) {
    weapon_defaultspawnfunc(WEP_FLAK);
}

float w_flak(float req) {
    if(req == WR_AIM) {
        if(random() < 0.35 && cvar("g_balance_flak_secondary_bomb") && self.ammo_rockets >= cvar("g_balance_flak_secondary_ammo_rockets"))
            self.BUTTON_ATCK2 = bot_aim(cvar("g_balance_flak_secondary_bomb_speed"), cvar("g_balance_flak_secondary_bomb_speed_up"), cvar("g_balance_flak_secondary_bomb_lifetime"), TRUE);
        else
            self.BUTTON_ATCK = bot_aim(cvar("g_balance_flak_primary_speed"), cvar("g_balance_flak_primary_speed_up"), cvar("g_balance_flak_primary_lifetime"), TRUE);
    } else if(req == WR_THINK) {
        if(self.BUTTON_ATCK)
        if(weapon_prepareattack(0, cvar("g_balance_flak_primary_refire"))) {
            W_Flak_Attack1();
            weapon_thinkf(WFRAME_FIRE1, cvar("g_balance_flak_primary_animtime"), w_ready);
        }

        if(self.BUTTON_ATCK2)
        if(weapon_prepareattack(1, cvar("g_balance_flak_secondary_refire"))) {
            if(cvar("g_balance_flak_secondary_bomb"))
                W_Flak_Attack3();
            else
                W_Flak_Attack2();
            weapon_thinkf(WFRAME_FIRE2, cvar("g_balance_flak_secondary_animtime"), w_ready);
        }
    } else if(req == WR_PRECACHE) {
        precache_sound("weapons/flak_fire.wav");
        precache_sound("weapons/flak_fire2.wav");
        precache_sound("weapons/flak_fire3.wav");
        precache_sound("weapons/casings1.wav");
        precache_sound("weapons/casings2.wav");
        precache_sound("weapons/casings3.wav");
    } else if(req == WR_SETUP)
        weapon_setup(WEP_FLAK);
    else if(req == WR_CHECKAMMO1)
        return self.ammo_shells >= cvar("g_balance_flak_primary_ammo");
    else if(req == WR_CHECKAMMO2)
        return self.ammo_shells >= cvar("g_balance_flak_secondary_ammo") && self.ammo_rockets >= cvar("g_balance_flak_secondary_ammo_rockets");

    return TRUE;
}
