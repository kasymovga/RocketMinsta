
.float vd_damage;
.float vd_armordamage;
.float vd_type;
.float vd_flag;
.vector vd_projected;
.string vd_str;
.string vd_str2;
.float vd_width;
.float vd_width2;
.float vd_fullwidth;
.float vd_culled;

entity vd_head;
entity vd_tail;
.entity  vd_next;
float vd_cnt;

float rm_visualdamage_fontsize;

#define VDMG_FONTSIZE rm_visualdamage_fontsize
#define VDMG_ALPHAOFFSET '0 -50 0'
#define VDMG_ALPHA 0.8

void VisualDamage_FixPositions(void) {
    entity e, p;
    
    for(e = vd_head; e; e = e.vd_next) if(!e.vd_culled) {
        for(p = e.vd_next; p; p = p.vd_next) if(!p.vd_culled) {
            if    (e.vd_type & VDMG_TYPE_TOSELF)
            if not(p.vd_type & VDMG_TYPE_TOSELF)
                continue;
                
            if    (p.vd_type & VDMG_TYPE_TOSELF)
            if not(e.vd_type & VDMG_TYPE_TOSELF)
                continue;
            
            float dst = p.vd_projected_y - e.vd_projected_y;
            if(dst > -VDMG_FONTSIZE && dst < VDMG_FONTSIZE) {
                float x1 = e.vd_projected_x - 0.5 * e.vd_fullwidth;
                float o1 = x1 + e.vd_fullwidth;
                float x2 = p.vd_projected_x - 0.5 * p.vd_fullwidth;
                float o2 = x2 + p.vd_fullwidth;
                
                if((x1 >= x2 && x1 <= o2) || (x2 >= x1 && x2 <= o1)) {
                    p.vd_projected_y = e.vd_projected_y - VDMG_FONTSIZE - 1;
                }
            }
        }
    }
}

void VisualDamage_PreDraw(void) {
    entity e;
    string s, s2;
    vector o;
    
    drawfont = sbar_bigfont;
    rm_visualdamage_fontsize = cvar("rm_visualdamage_fontsize");
    for(e = vd_head; e; e = e.vd_next) {
        if(!(e.vd_type & VDMG_TYPE_TOSELF)) {
            o = e.vd_projected = project_3d_to_2d(e.origin);
            
            if(o_z < 0 || o_x < 0 || o_y < 0 || o_x > vid_conwidth || o_y > vid_conheight) {
                e.vd_culled = TRUE;
                continue;
            }
        }
        
        s = "";
        s2 = "";
        
        if(!e.vd_damage && !e.vd_armordamage)
            s2 = "Immune";
        else {
            if(e.vd_damage)
                s = ftos(e.vd_damage);
            if(e.vd_armordamage)
                s2 = strcat((e.vd_damage? "  [" : "["), ftos(e.vd_armordamage), "]");
        }
        
        e.vd_str = s;
        if(e.vd_str) e.vd_width = stringwidth(s, FALSE);
        e.vd_str2 = s2;
        if(e.vd_str2) e.vd_width2 = stringwidth(s2, FALSE);
        e.vd_fullwidth = (e.vd_width + e.vd_width2) * VDMG_FONTSIZE;
        e.vd_culled = FALSE;
        
        if(e.vd_type & VDMG_TYPE_TOSELF)
            e.vd_projected = vdmg_dmgtakenorigin - '0 10 0';
    }
    
    VisualDamage_FixPositions();
    drawfont = sbar_font;
}

void VisualDamage_Draw(void) {
    float a = ipol_swingInOut(self.alpha), sw, sw2, smod;
    vector o, clr;
    vector offs = VDMG_ALPHAOFFSET * (1 - self.alpha);
    
    if(self.vd_type & VDMG_TYPE_CRIT)
        smod = 2;
    else if(self.vd_type & VDMG_TYPE_TOSELF && self.vd_type & VDMG_TYPE_HIT)
        smod = 1.3;
    else
        smod = 1;
    
    if(self.vd_type & VDMG_TYPE_NOTPLAYERTARGET)
        smod = smod * 0.8;
    
    float fs = VDMG_FONTSIZE * max(1, a * smod);
    
    o = self.vd_projected + offs - '0 0.5 0' * fs;
    
    if not(self.vd_culled) {
        o_z = 0;
        drawfont = GetBigfont();
        
        if(self.vd_type & VDMG_TYPE_HEAL)
            clr = '0.0 1.0 0.0';
        else if(self.vd_type & VDMG_TYPE_TEAMHIT || self.vd_type & VDMG_TYPE_TOSELF)
            clr = '1.0 0.2 0.2';
        else if(self.vd_type & VDMG_TYPE_NOTPLAYERTARGET)
            clr = '1.0 1.0 1.0';
        else if(self.vd_type & VDMG_TYPE_CRIT)
            clr = '1.0 0.3 0.0';
        else
            clr = '1.0 0.7 0.0';
        
        if(self.vd_type & VDMG_TYPE_NOTPLAYERTARGET)
            clr = clr * 0.9;
        
        sw = self.vd_width * fs;
        sw2 = self.vd_width2 * fs;
        
        if(self.vd_str)
            drawstring(o - (sw+sw2) * '0.5 0 0', self.vd_str, fs * '1 1 0', clr, VDMG_ALPHA * a, DRAWFLAG_NORMAL);
        if(self.vd_str2)
            drawstring(o - (sw2-sw) * '0.5 0 0', self.vd_str2, fs * '1 1 0', '1 1 1' * 0.5 + clr * 0.2, VDMG_ALPHA * a, DRAWFLAG_NORMAL);
        
        drawfont = sbar_font;
    }
    
    self.alpha = approach(self.alpha, 0, frametime);
    
    if(self.alpha <= 0 && !wasfreed(self)) {
        if(self == vd_head) {
            vd_head = vd_tail = vd_head.vd_next;
        } else {
            entity e; for(e = vd_head; e; e = e.vd_next)
                if(e.vd_next == self) {
                    e.vd_next = self.vd_next;
                    if(self == vd_tail)
                        vd_tail = e;
                    break;
                }
        }
        --vd_cnt;
        remove(self);
    }
}

void VisualDamage_Spawn(float dmg, float admg, float type, vector org) {
    if(!rm_showdamage)
        return;
    
    entity p, e = spawn();
    e.vd_damage = dmg;
    e.vd_armordamage = admg;
    e.vd_type = type;
    e.alpha = 1;
    e.draw2d = VisualDamage_Draw;
    e.vd_flag = TRUE;
    setorigin(e, org);
    
    e.vd_next = vd_head;
    vd_head = e;
    
    if(!e.vd_next)
        vd_tail = e;
    
    ++vd_cnt;
    
    if(vd_cnt > cvar("rm_visualdamage_limit")) {
        entity oldtail = vd_tail;
        for(p = vd_head; p; p = p.vd_next) {
            if(p.vd_next == vd_tail) {
                p.vd_next = world;
                vd_tail = p;
            }
        }
        remove(oldtail);
        --vd_cnt;
    }
}

void Net_VisualDamage(void) {
    vector org;
    float dmg = ReadShort();
    float admg = ReadShort();
    float type = ReadByte();
    
    if(!(type & VDMG_TYPE_TOSELF)) {
        org_x = ReadCoord();
        org_y = ReadCoord();
        org_z = ReadCoord();
    }
    
    VisualDamage_Spawn(dmg, admg, type, org);
}
