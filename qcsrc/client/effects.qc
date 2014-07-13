
void LightingArc_Draw(void) {
    string tex;
    if(rm_teamlasers) switch(self.team) {
        case COLOR_TEAM1: tex = "particles/hook_red";       break;
        case COLOR_TEAM2: tex = "particles/hook_blue";      break;
        case COLOR_TEAM3: tex = "particles/hook_yellow";    break;
        case COLOR_TEAM4: tex = "particles/hook_pink";      break;
        default         : tex = "particles/hook_green";     break;
    }   else              tex = (self.team? "particles/hook_blue" : "particles/hook_green");
    
    float i; for(i = 0; i < 5; ++i)
        Draw_CylindricLine(self.origin + randomvec() * 10 * self.alpha, self.velocity + randomvec() * 10 * self.alpha, 25 * self.alpha, tex, 0.02, random(), '1 1 1', self.alpha, DRAWFLAG_ADDITIVE);
    
    self.alpha = self.alpha - frametime * 3;
    if(self.alpha < 0)
        remove(self);
}

void LightingArc_Segment(vector start, vector end, float ateam) {
    entity e = spawn();
    e.alpha = 1;
    e.origin = start;
    e.velocity = end;
    e.draw = LightingArc_Draw;
    e.team = ateam;
}

void LightingArc_Full(vector from, vector to, float seglength, float drifts, float drifte, float branchfactor, float branchfactor_add, float ateam)
{
    vector direction,dirnew, pos, pos_l;
    float length, steps, steplength, i,drift;

    length     = vlen(from - to);
    if(length < 1)
        return;

    steps      = floor(length / seglength);
    if(steps < 1)
    {
        LightingArc_Segment(from, to, ateam);
        return;
    }

    steplength = length / steps;
    direction  = normalize(to - from);
    pos_l = from;
    if(length > seglength)
    {
        for(i = 1; i < steps; i += 1)
        {
            drift = drifts * (1 - (i / steps)) + drifte * (i / steps);
            dirnew = normalize(direction * (1 - drift) + randomvec() * drift);
            pos = pos_l +  dirnew * steplength;
            LightingArc_Segment(pos_l, pos, ateam);
            if(random() < branchfactor)
                LightingArc_Full(pos, pos + (dirnew * length * 0.25),seglength,drifts,drifte,min(branchfactor + branchfactor_add,1),branchfactor_add, ateam);

            pos_l = pos;
        }
        LightingArc_Segment(pos_l, to, ateam);

    }
    else
        LightingArc_Segment(from, to, ateam);

}

void LightingArc_Default(vector from, vector to, float ateam) {
    if(cvar("cl_effects_lightningarc_simple")) {
        LightingArc_Segment(from, to, ateam);
    } else {
        float seglength, drifts, drifte, branchfactor, branchfactor_add, lcount;

        seglength    = cvar("cl_effects_lightningarc_segmentlength");
        drifts       = cvar("cl_effects_lightningarc_drift_start");
        drifte       = cvar("cl_effects_lightningarc_drift_end");
        branchfactor = cvar("cl_effects_lightningarc_branchfactor_start");
        branchfactor = cvar("cl_effects_lightningarc_branchfactor_add");
        lcount       = cvar("cl_effects_lightningarc_count");
        
        for(; lcount; --lcount)
            LightingArc_Full(from, to, seglength, drifts, drifte, branchfactor, branchfactor_add, ateam);
    }
}

void Net_ReadLightningarc(void)
{
    float flash, ateam;
    vector from, to;
    
    flash  = ReadByte();
    ateam  = ReadByte();
    from_x = ReadCoord(); from_y = ReadCoord(); from_z = ReadCoord();
    to_x   = ReadCoord(); to_y   = ReadCoord(); to_z   = ReadCoord();

    if(flash)
        pointparticles(rm_particleeffectnum_team("RM_HG_PLASMA_SHARD_EXPLODE", ateam, 2), to, '0 0 0', 1);
    
    LightingArc_Default(from, to, ateam);
}

void Net_ReadBlast(void) {
    vector loc;
    loc_x = ReadCoord(); loc_y = ReadCoord(); loc_z = ReadCoord();
    pointparticles(particleeffectnum("TE_TEI_BIGEXPLOSION"), loc, '0 0 0', 1);
    entity e = spawn();
    setorigin(e, loc);
    sound(e, CHAN_PROJECTILE, "weapons/rocket_impact.wav", VOL_BASE, ATTN_NORM);
    remove(e);
}
