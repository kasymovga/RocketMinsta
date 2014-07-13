
void Term_Init(void) {
    g_terminals = cvar("g_terminals");
    
    if(!g_terminals)
        return;
    
    precache_model("models/it/pc.md3");
    precache_model("models/it/lcd.md3");
    precache_model("models/it/keyboard.md3");
    addstat(STAT_TERM_AUTH, AS_FLOAT, term_auth);
}

void Term_Remove(entity t) {
    entity e;
    for(e = findchainentity(owner, t); e; e = e.chain)
        remove(e);
    remove(t);
}

void Term_Setup(void) {
    entity term;
    vector o;
    
    self.angles_x = 0;
    self.angles_z = 0;
    makevectors(self.angles);
    self.angles_y += 90;
    
    term = self;
    self.classname = "misc_terminal";
    self.scale = 1.5;
    setmodel(self, "models/it/pc.md3");
    self.mins_x = self.mins_y;
    self.maxs_x = self.maxs_y;
    setsize(self, self.mins * self.scale, self.maxs * self.scale);
    self.solid = SOLID_BBOX;
    move_out_of_solid(self);
    DropToFloor_Handler();
    
    self = spawn();
    self.owner = term;
    self.angles = term.angles;
    setmodel(self, "models/it/lcd.md3");
    self.mins_y = self.mins_x;
    self.maxs_y = self.maxs_x;
    self.scale = 1.1;
    setsize(self, self.mins * self.scale, self.maxs * self.scale);
    setorigin(self, term.origin + v_up * term.maxs_z);
    o = self.origin;
    self.solid = SOLID_BBOX;
    self.skin = 1;
    //self.glow_size = 150;
    //self.glow_color = 0x7C;
    
    self = spawn();
    setorigin(self, o + v_forward * 40 + v_up * 30);
    self.light_lev = 128;
    self.color = '0.6 0.7 0.7';
    self.pflags = PFLAGS_FULLDYNAMIC;
    //setmodel(self, "models/runematch/rune.mdl");
    
    self = spawn();
    self.owner = term;
    self.angles = term.angles;
    setorigin(self, term.origin + v_forward * 30 + v_up * term.maxs_z);
    setmodel(self, "models/it/keyboard.md3");
    self.mins_y = self.mins_x;
    self.maxs_y = self.maxs_x;
    self.scale = 1.1;
    setsize(self, self.mins * self.scale, self.maxs * self.scale);
    self.solid = SOLID_BBOX;
    
    if(!term_first)
        term_first = term;
    
    if(term_last)
        term_last.term_next = term;
    
    term_last = term;
}

void spawnfunc_misc_terminal(void) {
    if(!g_terminals) {
        remove(self);
        return;
    }
    
    Term_Setup();
}

void Term_Hook_PlayerPreThink(void) {
    entity e;
    float found;
    
    if(!g_terminals)
        return;
    
    if((roundstate == ROUNDSTATE_OVER) || !self.iscreature || self.frozen || self.jb_isprisoned || self.deadflag != DEAD_NO || time - self.lastdamage < cvar("g_terminals_auth_damage_delay") || self.hg_stealth) {
        self.term_auth = self.term_authed = 0;
        return;
    }
    
    FOR_EACH_TERMINAL(e) if(vlen(self.origin - e.origin) < cvar("g_terminals_auth_range")) {
        makevectors(e.angles);
        if(normalize(e.origin - self.origin + self.view_ofs) * v_right> 0)
            continue;
        
        found = TRUE;
        break;
    }
    
    if not(found)
        self.term_auth = self.term_authed = self.term_used = 0;
    else if not(self.term_authed) {
        if(time < self.term_nextuse) {
            centerprint_spec(self, strcat("You must wait ", ftos(ceil(self.term_nextuse - time)), " seconds before authenticating again"));
            self.term_authed = TRUE;
            self.term_used = TRUE;
            return;
        }
        
        self.term_auth = approach(self.term_auth, 1, frametime / cvar("g_terminals_auth_time"));
        
        if(self.term_auth == 1) {
            self.term_auth = 0;
            self.term_authed = TRUE;
            self.buffs = 0;
            self.buff_cdoverride = -1;
            sound(self, CHAN_TRIGGER, "weapons/rocket_mode.wav", VOL_BASE, ATTN_NORM);
            HG_ShowMenu(TRUE);
        }
    }
}
