#define ANIM_NO         0
#define ANIM_REVERSE    1
#define ANIM_WALK       2
#define ANIM_RUN        3
#define ANIM_STRAFE_L   4
#define ANIM_STRAFE_R   5
#define ANIM_TURN       6
#define ANIM_JUMP       7
#define ANIM_LAND       8
#define ANIM_PAIN       9
#define ANIM_MEELE      10
#define ANIM_SWIM       11
#define ANIM_ROAM       12

#define WVM_IDLE_UP 25
#define WVM_IDLE    50

#define WVM_PATH  1000
#define WVM_ENEMY 2000
#define WVM_STOP  3000
#define WVM_DODGE 4000
#define  WVM_PANIC 10000
#define walker_verbs_move verbs_move

#define WVA_MINIGUN 100
#define WVA_LASER   400
#define WVA_ROCKET  500
#define WVA_SHIELD  900
#define WVA_MEELE   1000
#define walker_verbs_attack verbs_attack

#define WVI_IDLE 1
#define WVI_ROAM 10
#define walker_verbs_idle verbs_idle

.float animflag;
.entity wkr_spawn;
.float isboss;

.float boss_shield;
.float boss_shield_next;
.float boss_laser_next;

#define WALKER_MIN '-70 -70 5'
#define WALKER_MAX '70 70 90'

#define WALKER_PATH(s,e) pathlib_astar(s,e)

.entity bosswaypoint;

float walker_firecheck()
{
    if (self.animflag == ANIM_MEELE)
        return 0;

    return turret_stdproc_firecheck();
}

void walker_meele_do_dmg()
{
    vector where;
    entity e;
    makevectors(self.angles);
    where = self.origin + v_forward * 128;

    //w_deathtypestring = "tried to hug the cute spider thingy.";
    e = findradius(where,64);
    while (e)
    {
        if (turret_validate_target(self,e,self.target_validate_flags))
            if (e != self && e.owner != self)
                Damage(e,self,self,cvar("g_turrets_unit_walker_std_meele_dmg"),DEATH_TURRET,'0 0 0', v_forward * cvar("g_turrets_unit_walker_std_meele_force") );

        e = e.chain;
    }
}

void walker_animate()
{
    vector real_angle;
    float  vz;

    real_angle = vectoangles(self.steerto) - self.angles;
    vz         = self.velocity_z;

    if (self.tur_head.frame != 0)
        self.tur_head.frame = self.tur_head.frame +1;

    if (self.tur_head.frame > 12)
        self.tur_head.frame = 0;
    
    if(self.bosswaypoint)
        WaypointSprite_UpdateHealth(self.bosswaypoint, self.health);
    
    switch (self.animflag)
    {

    case ANIM_NO:
        if (self.frame != 0)
            self.frame = 0;

        movelib_beak_simple(cvar("g_turrets_unit_walker_speed_stop"));

        break;

    case ANIM_REVERSE:
        if ((self.frame < 5) || (self.frame > 25))
            self.frame = 25;

        self.frame = self.frame -1;
        movelib_move_simple(v_forward * -1 ,cvar("g_turrets_unit_walker_speed_walk"),0.6);

        if (self.frame < 5)
            self.frame = 25;

        break;

    case ANIM_TURN:

        if ((self.frame < 30) || (self.frame > 55))
            self.frame = 30;

        self.frame = self.frame + 1;

        self.angles_y += bound(-15,shortangle_f(real_angle_y,self.angles_y),15);

        movelib_beak_simple(cvar("g_turrets_unit_walker_speed_stop"));

        if (self.frame > 55)
            self.frame = 35;

        break;

    case ANIM_WALK:
        if ((self.frame < 5) || (self.frame > 25))
            self.frame = 5;

        self.frame = self.frame +1;
        self.angles_y += bound(-10,shortangle_f(real_angle_y,self.angles_y),10);
        movelib_move_simple(v_forward ,cvar("g_turrets_unit_walker_speed_walk"),0.6);

        if (self.frame > 25)
            self.frame = 5;

        break;

    case ANIM_ROAM:
        if ((self.frame < 5) || (self.frame > 25))
            self.frame = 5;

        self.frame = self.frame +1;

        self.angles_y += bound(-5,shortangle_f(real_angle_y,self.angles_y),5);

        movelib_move_simple(v_forward ,cvar("g_turrets_unit_walker_speed_roam"),0.5);

        if (self.frame > 25)
            self.frame = 5;

        break;

    case ANIM_SWIM:
        if ((self.frame < 142) || (self.frame > 151))
            self.frame = 142;

        self.frame = self.frame +1;

        self.angles_y += bound(-10,shortangle_f(real_angle_y,self.angles_y),10);
        self.angles_x += bound(-10,shortangle_f(real_angle_x,self.angles_x),10);

        movelib_move_simple(v_forward, cvar("g_turrets_unit_walker_speed_swim"),0.3);
        vz = self.velocity_z + sin(time * 4) * 8;

        if (self.frame > 151)
            self.frame = 146;

        break;

    case ANIM_RUN:

        if ((self.frame < 5) || (self.frame > 25))
            self.frame = 5;

        self.angles_y += bound(-5,shortangle_f(real_angle_y,self.angles_y),5);
        movelib_move_simple(v_forward, cvar("g_turrets_unit_walker_speed_run"),0.6);

        if (self.frame > 25)
            self.frame = 5;

        break;

    case ANIM_STRAFE_L:
        if ((self.frame < 30) || (self.frame > 55))
            self.frame = 30;

        self.frame = self.frame + 1;
        self.angles_y += bound(-2.5,shortangle_f(real_angle_y,self.angles_y),2.5);
        movelib_move_simple(v_right * -1, cvar("g_turrets_unit_walker_speed_walk"),0.8);

        if (self.frame > 55)
            self.frame = 35;
        break;

    case ANIM_STRAFE_R:
        if ((self.frame < 60) || (self.frame > 65))
            self.frame = 60;

        self.frame = self.frame + 1;
        self.angles_y += bound(-2.5,shortangle_f(real_angle_y,self.angles_y),2.5);
        movelib_move_simple(v_right, cvar("g_turrets_unit_walker_speed_walk"),0.8);

        if (self.frame > 85)
            self.frame = 65;

        break;

    case ANIM_JUMP:
        if ((self.frame < 95) || (self.frame > 100))
            self.frame = 95;

        self.velocity += '0 0 1' * cvar("g_turrets_unit_walker_speed_jump");

        if (self.frame > 100)
            self.frame = self.frame + 1;

        break;

    case ANIM_LAND:
        if ((self.frame < 100) || (self.frame > 107))
            self.frame = 100;

        self.frame = self.frame + 1;

        if (self.frame > 107)
            self.animflag = ANIM_NO;

        break;

    case ANIM_PAIN:
        if ((self.frame < 60) || (self.frame > 95))
            self.frame = 90;

        self.frame = self.frame + 1;

        if (self.frame > 95)
            self.animflag = ANIM_NO;

        break;

    case ANIM_MEELE:
        if ((self.frame < 123) || (self.frame > 140))
            self.frame = 123;

        movelib_beak_simple(cvar("g_turrets_unit_walker_speed_stop"));

        self.frame = self.frame + 2;

        if (self.frame == 133)
            walker_meele_do_dmg();

        if (self.frame > 140)
        {
            self.animflag = ANIM_NO;
            self.frame = 0;
        }
    }

    self.velocity_z = vz;

    if (self.flags & FL_ONGROUND)
        movelib_groundalign4point(300,100,0.25);

}


void walker_rocket_explode()
{
    vector org2;

    if (self.event_damage != SUB_Null)
    {
        self.event_damage = SUB_Null;
        self.think = walker_rocket_explode;
        self.nextthink = time;
        return;
    }

    sound (self, CHAN_PROJECTILE, "weapons/rocket_impact.wav", VOL_BASE, ATTN_NORM);
    org2 = findbetterlocation (self.origin, 16);

    pointparticles(particleeffectnum("rocket_explode"), org2, '0 0 0', 1);
    //w_deathtypestring = "got blasted to oblivion";
    RadiusDamage (self, self.owner, cvar("g_turrets_unit_walker_std_rocket_dmg"), 0, cvar("g_turrets_unit_walker_std_rocket_radius"), world, cvar("g_turrets_unit_walker_std_rocket_force"), DEATH_TURRET, world);

    remove (self);
}

void walker_rocket_damage (entity inflictor, entity attacker, float damage, float deathtype, vector hitloc, vector vforce)
{
    self.health = self.health - damage;
    self.velocity = self.velocity + vforce;
    if (self.health <= 0)
        walker_rocket_explode();
}

#define WALKER_ROCKET_MOVE movelib_move_simple(newdir,cvar("g_turrets_unit_walker_std_rocket_speed"),cvar("g_turrets_unit_walker_std_rocket_tunrate")); UpdateCSQCProjectile(self)
void walker_rocket_loop();
void walker_rocket_think()
{
    vector newdir;
    float edist;
    float itime;
    float m_speed;

    self.nextthink = time;

    edist = vlen(self.enemy.origin - self.origin);

    // Simulate crude guidance
    if (self.cnt < time)
    {
        if (edist < 1000)
            self.tur_shotorg = randomvec() * min(edist,64);
        else
            self.tur_shotorg = randomvec() * min(edist,256);

        self.cnt = time + 0.5;
    }

    if (edist < 256)
        self.tur_shotorg = '0 0 0';


    if (self.tur_health < time)
    {
        self.think = walker_rocket_explode;
        self.nextthink = time;
        return;
    }

    if (self.shot_dmg != 1337)
        if (random() < 0.01)
        {
            walker_rocket_loop();
            return;
        }

    m_speed = vlen(self.velocity) + cvar("g_turrets_unit_walker_std_rocket_speed_add");

    // Enemy dead? just keep on the current heading then.
    if ((self.enemy == world) || (self.enemy.deadflag != DEAD_NO))
    {
        // Make sure we dont return to tracking a respawned player
        self.enemy = world;
    }

    if (self.enemy)
    {
        itime = max(edist / m_speed,1);
        newdir = steerlib_pull(self.enemy.origin + self.tur_shotorg);
    }
    else
    {
        newdir  = normalize(self.velocity);
    }

    WALKER_ROCKET_MOVE;
}

void walker_rocket_loop3()
{
    vector newdir;
    self.nextthink = time;

    if (self.tur_health < time)
    {
        self.think = walker_rocket_explode;
        return;
    }

    if (vlen(self.origin - self.tur_shotorg) < 128 )
    {
        self.think = walker_rocket_think;
        return;
    }

    newdir = steerlib_pull(self.tur_shotorg);
    WALKER_ROCKET_MOVE;

    self.angles = vectoangles(self.velocity);
}

void walker_rocket_loop2()
{
    vector newdir;

    self.nextthink = time;

    if (self.tur_health < time)
    {
        self.think = walker_rocket_explode;
        return;
    }

    if (vlen(self.origin - self.tur_shotorg) < 128 )
    {
        self.tur_shotorg = self.origin - '0 0 200';
        self.think = walker_rocket_loop3;
        return;
    }

    newdir = steerlib_pull(self.tur_shotorg);
    WALKER_ROCKET_MOVE;
}

void walker_rocket_loop()
{
    self.nextthink = time;
    self.tur_shotorg = self.origin + '0 0 400';
    self.think = walker_rocket_loop2;
    self.shot_dmg = 1337;
}

void walker_fire_rocket(vector org)
{

    entity rocket;


    self.angles_x *= -1;
    makevectors(self.angles);
    self.angles_x *= -1;

    te_explosion (org);

    rocket = spawn ();
    setorigin(rocket, org);

    sound (self, CHAN_WEAPON, "weapons/hagar_fire.wav", VOL_BASE, ATTN_NORM);
    setsize (rocket, '-3 -3 -3', '3 3 3'); // give it some size so it can be shot

    rocket.classname          = "walker_rocket";
    rocket.owner              = self;

    rocket.bot_dodge          = TRUE;
    rocket.bot_dodgerating    = 50;

    rocket.takedamage         = DAMAGE_YES;

    rocket.damageforcescale   = 2;
    rocket.health             = 25;
    rocket.tur_shotorg        = randomvec() * 512;
    rocket.cnt                = time + 1;
    rocket.enemy              = self.enemy;

    if (random() < 0.01)
        rocket.think          = walker_rocket_loop;
    else
        rocket.think          = walker_rocket_think;

    rocket.event_damage       = walker_rocket_damage;

    rocket.nextthink          = time;// + 0.25;
    rocket.movetype           = MOVETYPE_FLY;
    rocket.velocity           = normalize((v_forward + v_up * 0.5) + (randomvec() * 0.2)) * cvar("g_turrets_unit_walker_std_rocket_speed");
    rocket.angles             = vectoangles(rocket.velocity);
    rocket.touch              = walker_rocket_explode;
    rocket.flags              = FL_PROJECTILE;
    rocket.solid              = SOLID_BBOX;
    rocket.tur_health         = time + 9;

    CSQCProjectile(rocket, FALSE, PROJECTILE_ROCKET, FALSE); // no culling, has fly sound
}

void rv_think()
{
    float f;
    vector org;
    entity oldself;

    if (self.owner.deadflag != DEAD_NO)
    {
        remove(self);
        return;
    }

    self.cnt = self.cnt -1;

    if (self.cnt < 0)
    {
        remove(self);
        return;
    }

    if (self.cnt > 1)
        f = gettagindex(self.owner,"tag_rocket01");
    else
        f = gettagindex(self.owner,"tag_rocket02");

    org = gettaginfo(self.owner,f);

    self.nextthink = time + 0.2;
    oldself = self;
    self = self.owner;
    walker_fire_rocket(org);
    self = oldself;
}

float walker_moveverb_path(float eval)
{
    switch (eval)
    {
    case VCM_EVAL:

        if (self.animflag == ANIM_MEELE)
            return VS_CALL_NO;

        if (self.pathcurrent)
            return verb.verb_static_value;

        return VS_CALL_NO;

    case VCM_DO:
        // Do we have a path?
        if not(self.pathcurrent)
        {
            return VS_CALL_NO;
        }
        else
        {
            // Are we close enougth to a path node to switch to the next?
            if (vlen(self.origin  - self.pathcurrent.origin) < 64)
                if (self.pathcurrent.path_next == world)
                {
                    // Path endpoint reached
                    pathlib_deletepath(self.pathcurrent.owner);
                    self.pathcurrent = world;

                    if (self.pathgoal)
                    {
                        if (self.pathgoal.use)
                            self.pathgoal.use();

                        if (self.pathgoal.enemy)
                        {
                            self.pathcurrent = WALKER_PATH(self.pathgoal.origin,self.pathgoal.enemy.origin);
                            self.pathgoal = self.pathgoal.enemy;
                        }
                    }
                    else
                        self.pathgoal = world;
                }
                else
                    self.pathcurrent = self.pathcurrent.path_next;
        }


        if (self.pathcurrent)
        {
            switch (self.waterlevel)
            {
            case 0:
                self.animflag = ANIM_WALK;
            case 1:
            case 2:
                if (self.animflag == ANIM_WALK)
                    self.animflag = ANIM_WALK;
                else
                    self.animflag = ANIM_SWIM;
                break;
            case 3:
                self.animflag = ANIM_SWIM;
            }

            self.moveto = self.pathcurrent.origin;
            self.steerto = steerlib_attract2(self.moveto,0.5,500,0.95);

            return VS_CALL_YES_DOING;
        }
        else
            return VS_CALL_YES_DONE;

    case VCM_REMOVE:

        if (self.pathcurrent)
            pathlib_deletepath(self.pathcurrent.owner);

        self.pathcurrent = world;

        return VS_CALL_YES_DONE;
    }

    return VS_CALL_YES_DONE;
}

float walker_moveverb_enemy(float eval)
{
    switch (eval)
    {
    case VCM_EVAL:

        if (self.enemy)
            if (self.spawnflags & TSF_NO_PATHBREAK)
                if (self.pathcurrent)
                    return VS_CALL_NO;

        if (self.animflag == ANIM_MEELE)
            return VS_CALL_NO;

        if (self.enemy == world)
            return VS_CALL_NO;

        //if (tracewalk(self.enemy, self.origin, self.mins, self.maxs, self.enemy.origin, MOVE_NORMAL))
        return verb.verb_static_value;

        //return VS_CALL_NO;

    case VCM_DO:
        switch (self.waterlevel)
        {
        case 0:
            if (self.tur_dist_enemy > 500)
                self.animflag = ANIM_RUN;
            else
                self.animflag = ANIM_WALK;
        case 1:
        case 2:
            if (self.animflag != ANIM_SWIM)
                self.animflag = ANIM_WALK;
            else
                self.animflag = ANIM_SWIM;
            break;
        case 3:
            self.animflag = ANIM_SWIM;
        }

        self.moveto = self.enemy.origin;
        self.steerto = steerlib_attract2(self.moveto,0.5,500,0.95);

        return VS_CALL_YES_DOING;
    }

    return VS_CALL_YES_DONE;
}

float walker_moveverb_idle_pause(float eval)
{
    switch (eval)
    {
    case VCM_EVAL:

        if (self.animflag == ANIM_MEELE)
            return VS_CALL_NO;

        return verb.verb_static_value;

    case VCM_DO:

        self.moveto   = self.origin;
        self.steerto  = v_forward;
        self.animflag = ANIM_NO;

        return VS_CALL_YES_DOING;
    }

    return VS_CALL_YES_DONE;
}

float walker_moveverb_idle_roam(float eval)
{
    switch (eval)
    {
    case VCM_EVAL:

        if (self.animflag == ANIM_MEELE)
            return VS_CALL_NO;

        return verb.verb_static_value;

    case VCM_DO:
        if(verb.wait < time)
        {
            trace_fraction = 0;
            while(trace_fraction != 1.0)
            {
                self.moveto = self.origin + (v_forward * 256);
                self.moveto += v_right * (random() * 256);
                self.moveto -= v_right * (random() * 256);

                tracebox(self.origin+'0 0 64',self.mins,self.maxs,self.moveto + '0 0 64',MOVE_NORMAL,self);
            }
            verb.wait = time + 10;
        }
        else
        {
            if(verb.wait - time < 9)
                if(vlen(self.moveto - self.origin) < 32)
                {
                    verbstack_push(self.walker_verbs_move, walker_moveverb_idle_pause,   WVM_IDLE + WVM_IDLE_UP, random() * (verb.wait - time), self);
                    self.animflag = ANIM_NO;
                    return VS_CALL_REMOVE;
                }
        }

        self.steerto = steerlib_attract(self.moveto,256);
        te_lightning1(self,self.origin + '0 0 64',self.moveto + '0 0 64');



        switch (self.waterlevel)
        {
        case 0:
            self.animflag = ANIM_ROAM;
        case 1:
        case 2:
            if (self.animflag != ANIM_SWIM)
                self.animflag = ANIM_ROAM;

            break;
        case 3:
            self.animflag = ANIM_SWIM;
        }

        return VS_CALL_YES_DOING;
    }

    return VS_CALL_YES_DONE;
}

float walker_moveverb_idle(float eval)
{
    switch (eval)
    {
    case VCM_EVAL:

        if (self.animflag == ANIM_MEELE)
            return VS_CALL_NO;

        return verb.verb_static_value;

    case VCM_DO:

        //if (random() < 0.5)
            verbstack_push(self.walker_verbs_move, walker_moveverb_idle_pause,   WVM_IDLE + WVM_IDLE_UP, random() * 5, self);
        //else
        //    verbstack_push(self.walker_verbs_move, walker_moveverb_idle_roam,   WVM_IDLE + WVM_IDLE_UP,  random() * 15);

        return VS_CALL_YES_DOING;
    }

    return VS_CALL_YES_DONE;
}

float walker_attackverb_meele(float eval)
{
    switch (eval)
    {
    case VCM_EVAL:

        vector wish_angle;

        if (cvar("g_turrets_nofire"))
            return VS_CALL_NO;

        if (self.animflag == ANIM_SWIM || self.animflag == ANIM_MEELE)
            return VS_CALL_NO;

        if (!self.enemy)
            return VS_CALL_NO;

        wish_angle = angleofs(self,self.enemy);

        if (self.tur_dist_enemy < cvar("g_turrets_unit_walker_std_meele_range"))
            if (fabs(wish_angle_y) < 15)
                return verb.verb_static_value;

        return VS_CALL_NO;

    case VCM_DO:

        self.moveto   = self.enemy.origin;
        self.steerto  = steerlib_attract2(self.moveto,0.5,500,0.95);
        self.animflag = ANIM_MEELE;

        return VS_CALL_YES_DOING;
    }

    return VS_CALL_YES_DONE;
}

float walker_attackverb_rockets(float eval)
{
    switch (eval)
    {
    case VCM_EVAL:
        if (self.tur_head.attack_finished_single > time)
            return VS_CALL_NO;

        if not(self.enemy)
            return VS_CALL_NO;

        if (cvar("g_turrets_nofire"))
            return VS_CALL_NO;

        if (self.tur_dist_enemy < cvar("g_turrets_unit_walker_std_rockets_range_min"))
            return VS_CALL_NO;

        if (self.tur_dist_enemy > cvar("g_turrets_unit_walker_std_rockets_range"))
            return VS_CALL_NO;

        return verb.verb_static_value;

    case VCM_DO:

        entity rv;

        rv           = spawn();
        rv.think     = rv_think;
        rv.nextthink = time;
        rv.cnt       = 4;
        rv.owner     = self;

        self.tur_head.attack_finished_single = time + cvar("g_turrets_unit_walker_std_rocket_refire");

        return VS_CALL_YES_DONE;
    }

    return VS_CALL_YES_DONE;
}

void walker_boss_shield_think(void) {
    self.owner.boss_shield = approach(self.owner.boss_shield, -0.5, frametime);
    self.alpha = bound(0, self.owner.boss_shield + 0.5, 1);
    
    if not(self.alpha) {
        remove(self);
        return;
    }
    
    self.nextthink = time;
}

float walker_boss_attackverb_shield(float eval) {
    switch(eval) {
        case VCM_EVAL:
            if not(self.enemy)
                return VS_CALL_NO;

            if(cvar("g_turrets_nofire"))
                return VS_CALL_NO;
            
            if(self.boss_shield)
                return VS_CALL_NO;
            
            if(self.boss_shield_next > time)
                return VS_CALL_NO;
            
            return verb.verb_static_value;

        case VCM_DO:
            self.boss_shield = 15;
            self.boss_shield_next = time + 60 - 15 * random();
            
            sound(self, CHAN_AUTO, "misc/powerup_shield.wav", 1, ATTN_NORM);
            
            entity e = spawn();
            e.owner = self;
            e.think = walker_boss_shield_think;
            e.nextthink = time;
            e.effects = EF_ADDITIVE | EF_FULLBRIGHT;
            e.glow_size = 256;
            e.glow_color = 230;
            e.glow_trail = 1;
            e.alpha = 1;
            e.avelocity = '14 0 22';
            e.movetype = MOVETYPE_FOLLOW;
            e.aiment = e.owner;
            e.colormod = '1 1 0';
            setorigin(e, self.origin);
            setmodel(e, "models/ctf/shield.md3");
            e.scale = 1.3;
            setsize(e, e.scale * e.mins, e.scale * e.maxs);
            
            return VS_CALL_YES_DONE;
    }

    return VS_CALL_YES_DONE;
}

void walker_boss_laser_explode(void) {
    RadiusDamage(self, self.owner, 125, 70, 130, world, 300, self.projectiledeathtype, other);
}

void walker_boss_laser_use(void) {
    walker_boss_laser_explode();
    remove(self);
}

void walker_boss_laser_hit(void) {
    PROJECTILE_TOUCH;
    self.cnt += 1;
    
    if(self.cnt == 3)
        self.use();
    else
        walker_boss_laser_explode();
}

void walker_boss_laser_think(void) {
    float lc = 15, i;
    float offs = random();
    
    if(!self.owner || self.owner.health < 1) {
        remove(self);
        return;
    }
    
    // self.owner.solid = SOLID_CORPSE;
    
    sound(self, CHAN_AUTO, "RM_SOUND_LASER_PRIMARY", 1, ATTN_NORM);
    for(i = 0; i < lc; ++i) {
        vector sorg = self.owner.origin + self.owner.maxs_z * '0 0 0.5';
        makevectors('0 360 0' * (offs + i/lc) + '15 0 0' * (random() - 0.5));
        
        entity p = spawn();
        p.owner = self.owner;
        p.movetype = MOVETYPE_BOUNCEMISSILE;
        p.projectiledeathtype = DEATH_HG_LASER;
        setsize(p, '0 0 0', '0 0 1');
        setorigin(p, sorg);
        PROJECTILE_MAKETRIGGER(p);
        p.dphitcontentsmask &~= DPCONTENTS_CORPSE;
        p.velocity = 700 * v_forward;
        p.angles = vectoangles(p.velocity);
        p.flags = FL_PROJECTILE;
        p.team = COLOR_TEAM4;
        p.reset = SUB_Remove;
        p.touch = walker_boss_laser_hit;
        p.use = walker_boss_laser_use;
        p.think = adaptor_think2use;
        p.nextthink = time + 5;
        
        CSQCProjectile(p, TRUE, HG_TypeToCSQCProjType(HG_LASER), TRUE);
    }
    
    if(self.cnt < 2 || random() > 0.5) {
        self.nextthink = time + 0.5;
        self.cnt += 1;
    } else {
        remove(self);
    }
}

float walker_boss_attackverb_laser(float eval) {
    switch(eval) {
        case VCM_EVAL:
            if not(self.enemy)
                return VS_CALL_NO;

            if(cvar("g_turrets_nofire"))
                return VS_CALL_NO;
            
            if(self.boss_laser_next > time)
                return VS_CALL_NO;
            
            return verb.verb_static_value;

        case VCM_DO:
            self.boss_laser_next = time + 15 - 5 * random();
        
            entity e = spawn();
            e.owner = self;
            e.think = walker_boss_laser_think;
            e.nextthink = time + 0.3;
            
            return VS_CALL_YES_DONE;
    }

    return VS_CALL_YES_DONE;
}

float walker_boss_damagehook(entity inflictor, entity attacker, float damage, float deathtype, vector hitloc, vector force) {
    if(attacker == self)
        return -1;
    
    if(self.boss_shield > 0) {
        float take = damage * 0.2;
        float reflect = damage - take;
        
        if(attacker.iscreature)
        if(deathtype != DEATH_HG_SHIELD)
        if(deathtype != DEATH_HG_TRANSLOC) {
            FireRailgunBullet(hitloc, attacker.origin + '0 0 0.5' * attacker.maxs_z, reflect, 0, 0, 0, 0, 0, DEATH_HG_SHIELD);
            trailparticles(world, particleeffectnum("TE_TEI_G3YELLOW_HIT"), hitloc, trace_endpos);
            te_csqc_lightningarc(hitloc, trace_endpos, TRUE, COLOR_TEAM3);
        }
        
        damage = take;
    }
    
    if(self.health - damage <= 0) {
        float i;
        for(i = 0; i < 3; ++i) {
            entity e = spawn();
            e.hg_type = HG_NAPALM;
            e.think = HG_Grenade_Explode;
            e.nextthink = time + random() * 0.3;
            e.owner = attacker;
            e.team = e.owner.team;
            setorigin(e, hitloc);
            CSQCProjectile(e, TRUE, HG_TypeToCSQCProjType(e.hg_type), TRUE);
        }
        
        if(g_nadgets)
            HG_GiveBonus(attacker, HG_GG, 1, strcat("Defeated ", self.netname, "!"));
    }
    
    return damage;
}

void walker_postthink()
{
    self.angles_x *= -1;
    makevectors(self.angles);
    self.angles_x *= -1;

    verbstack_pop(self.walker_verbs_attack);
    verbstack_pop(self.walker_verbs_move);

    walker_animate();
}

void walker_attack()
{
    entity flash;
    
    //w_deathtypestring = "was miniguned";
    sound (self, CHAN_WEAPON, "weapons/uzi_fire.wav", VOL_BASE, ATTN_NORM);
    fireBallisticBullet (self.tur_shotorg, self.tur_shotdir_updated,self.shot_spread, self.shot_speed, 5, self.shot_dmg, 0, self.shot_force, DEATH_TURRET, 0, 1, cvar("g_balance_uzi_bulletconstant"));
    endFireBallisticBullet();
    if (self.uzi_bulletcounter == 2)
    {

        flash = spawn();

        setmodel(flash, "models/uziflash.md3");
        setattachment(flash, self.tur_head, "tag_fire");

        flash.scale     = 3;
        flash.think     = W_Uzi_Flash_Go;
        flash.nextthink = time + 0.02;
        flash.frame     = 2;
        flash.angles_z  = flash.v_angle_z + random() * 180;
        flash.alpha     = 1;
        flash.effects   = EF_ADDITIVE | EF_FULLBRIGHT | EF_LOWPRECISION;

        self.uzi_bulletcounter = self.uzi_bulletcounter = 0;
    }

    self.uzi_bulletcounter = self.uzi_bulletcounter + 1;
    self.tur_head.frame    = self.tur_head.frame + 1;
}


void walker_respawnhook()
{
    vector vtmp;
    entity e;
    
    if(self.isboss) {
        remove(self);
        return;
    }
    
    self.origin = self.wkr_spawn.origin;

    self.angles = self.wkr_spawn.angles;
    vtmp = self.wkr_spawn.origin;
    vtmp_z += self.wkr_spawn.maxs_z;
    setorigin(self,vtmp);

    if (self.target != "")
    {
        e = find(world,targetname,self.target);
        if (!e)
        {
            dprint("Warning! initital waypoint for Walker does NOT exsist!\n");
            self.target = "";
        }

        if (e.classname != "turret_checkpoint")
            dprint("Warning: not a turrret path\n");
        else
        {
            self.pathcurrent = WALKER_PATH(self.origin,e.origin);
            self.pathgoal = e;
        }
    }
}

void walker_diehook()
{
    turret_trowgib2(self.origin,self.velocity + v_up * 200,'-0.6 -0.2 -02',self,time + random() * 1);
    turret_trowgib2(self.origin + '0 0 64',self.velocity + v_forward * 150 + v_up * 150,'-0.2 -0.2 -02',self.tur_head,time + random() * 2 + 3);

    if (self.pathcurrent)
        pathlib_deletepath(self.pathcurrent.owner);

    self.pathcurrent = world;

    if (self.damage_flags & TFL_DMG_DEATH_NORESPAWN)
    {
        if(self.wkr_spawn)
            remove(self.wkr_spawn);

        verbstack_flush(self.walker_verbs_move);
        verbstack_flush(self.walker_verbs_attack);
        verbstack_flush(self.walker_verbs_idle);

        remove(self.walker_verbs_move);
        remove(self.walker_verbs_attack);
        remove(self.walker_verbs_idle);
        
    }
    
    if(self.bosswaypoint)
        WaypointSprite_Disown(self.bosswaypoint, 1);
}

void turret_walker_dinit()
{

    entity e;
    
    if(self.netname == "")
        self.netname = "Walker Turret";
    
    if(!self.isboss)
        self.wkr_spawn = spawn();

    self.ammo_flags = TFL_AMMO_BULLETS | TFL_AMMO_RECHARGE | TFL_AMMO_RECIVE;
    self.turrcaps_flags = TFL_TURRCAPS_PLAYERKILL | TFL_TURRCAPS_MOVE | TFL_TURRCAPS_HEADATTACHED;
    self.aim_flags = TFL_AIM_LEAD;

    if (cvar("g_antilag_bullets"))
        self.turrcaps_flags |= TFL_TURRCAPS_HITSCAN;
    else
        self.aim_flags      |= TFL_AIM_SHOTTIMECOMPENSATE;


    self.turret_respawnhook = walker_respawnhook;
    self.turret_diehook = walker_diehook;

    self.ticrate = 0.05;
    if (turret_stdproc_init("walker_std",FALSE,"models/turrets/walker_body.md3","models/turrets/walker_head_minigun.md3") == 0)
    {
        remove(self);
        return;
    }
    setsize(self.tur_head,'0 0 0','0 0 0');

    self.walker_verbs_move   = spawn();
    self.walker_verbs_attack = spawn();
    self.walker_verbs_idle   = spawn();

    verbstack_push(self.walker_verbs_move, walker_moveverb_idle,   WVM_IDLE,  0, self);
    verbstack_push(self.walker_verbs_move, walker_moveverb_enemy,  WVM_ENEMY, 0, self);
    verbstack_push(self.walker_verbs_move, walker_moveverb_path,   WVM_PATH,  0, self);

    verbstack_push(self.walker_verbs_attack, walker_attackverb_meele,   WVA_MEELE,  0, self);
    verbstack_push(self.walker_verbs_attack, walker_attackverb_rockets, WVA_ROCKET, 0, self);
    
    if(self.isboss) {
        verbstack_push(self.walker_verbs_attack, walker_boss_attackverb_shield, WVA_SHIELD, 0, self);
        verbstack_push(self.walker_verbs_attack, walker_boss_attackverb_laser, WVA_LASER, 0, self);
        
        self.boss_shield_next = time + 50 + 20 * random();
        self.boss_laser_next = time + 20 + 5 * random();
    }

    self.damage_flags |= TFL_DMG_DEATH_NOGIBS;

    self.target_select_flags   = TFL_TARGETSELECT_PLAYERS | TFL_TARGETSELECT_RANGELIMTS | TFL_TARGETSELECT_TEAMCHECK | TFL_TARGETSELECT_LOS;
    self.target_validate_flags = TFL_TARGETSELECT_PLAYERS | TFL_TARGETSELECT_RANGELIMTS | TFL_TARGETSELECT_TEAMCHECK | TFL_TARGETSELECT_LOS;

    self.iscreature = TRUE;
    self.movetype   = MOVETYPE_WALK;
    self.solid      = SOLID_SLIDEBOX;
    self.takedamage = DAMAGE_AIM;

    setattachment(self.tur_head,self,"tag_head");

    if(self.wkr_spawn) {
        setmodel(self.wkr_spawn,"models/turrets/walker_spawn.md3");
        self.wkr_spawn.angles   = self.angles;
        self.wkr_spawn.solid    = SOLID_NOT;
    }

    traceline(self.origin + '0 0 16', self.origin - '0 0 10000', MOVE_WORLDONLY, self);
    setorigin(self.wkr_spawn,trace_endpos + '0 0 4');
    setorigin(self,self.wkr_spawn.origin);

    setsize(self,WALKER_MIN,WALKER_MAX);

    self.idle_aim = '0 0 0';
    self.turret_firecheckfunc = walker_firecheck;
    self.turret_firefunc      = walker_attack;
    self.turret_postthink     = walker_postthink;

    if (self.target != "")
    {
        e = find(world,targetname,self.target);
        if (!e)
        {
            dprint("Initital waypoint for walker does NOT exsist, fix your map!\n");
            self.target = "";
        }

        if (e.classname != "turret_checkpoint")
            dprint("Warning: not a turrret path\n");
        else
        {
            self.pathcurrent = WALKER_PATH(self.origin,e.origin);
            self.pathgoal = e;
        }
    }
    
    if(self.isboss) {
        WaypointSprite_Spawn(self.netname, 0, 0, self, '0 0 1.3' * self.maxs_z, world, 0, self, bosswaypoint, TRUE);
        WaypointSprite_UpdateTextColors(self.bosswaypoint, '1 0.7 0', '0 0 0', '0 0 0');
        WaypointSprite_UpdateTeamRadar(self.bosswaypoint, RADARICON_WAYPOINT, '1 0.7 0');
        WaypointSprite_UpdateMaxHealth(self.bosswaypoint, self.health);
        
        self.turret_damagehook = walker_boss_damagehook;
        self.damage_flags |= TFL_DMG_DEATH_NORESPAWN;
    }
}


void spawnfunc_turret_walker()
{
    g_turrets_common_precash();

    precache_model ("models/turrets/walker_head_minigun.md3");
    precache_model ("models/turrets/walker_body.md3");
    precache_model ("models/turrets/walker_props.md3");
    precache_model ("models/turrets/walker_spawn.md3");
    precache_model ( "models/turrets/rocket.md3");
    precache_sound ( "weapons/rocket_impact.wav" );

    self.think = turret_walker_dinit;
    self.nextthink = time + 0.5;
}

void boss_spawner_spawn(void) {
    entity oself = self;
    self = spawn();
    self.isboss = TRUE;
    self.netname = oself.netname;
    spawnfunc_turret_walker();
    self = oself;
    
    entity e; FOR_EACH_PLAYER(e)
        bigprint_spec(e, strcat("^3", self.netname, "^3 has come!"), "", 5);
    bprint("^3", self.netname, "^3 has come!\n");
    play2all("kh/alarm.wav");
}

void boss_spawner_think(void) {
    if(roundstate == ROUNDSTATE_GAME && !self.isboss) {
        self.isboss = TRUE;
        if(random() <= self.cnt)
            defer(5, boss_spawner_spawn);
    }
    
    self.nextthink = time;
    return;
}

void boss_spawner_reset(void) {
    self.isboss = FALSE;
}

void spawnfunc_boss_spawner(void) {
    self.reset = boss_spawner_reset;
    self.think = boss_spawner_think;
    self.nextthink = time;
}
