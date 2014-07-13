var float(string text, float handleColors) stringwidth;

entity players;
entity teams;

void restartAnnouncer_Think() {
	float countdown_rounded, countdown;
	countdown = getstatf(STAT_GAMESTARTTIME) - time;
	countdown_rounded = floor(0.5 + countdown);
	if(countdown <= 0) {
		//if (!spectatee_status) //do cprint only for players
		//	centerprint("\x01^1Begin!");
		
		//gamestart_status = -1;
		//gamestart_fadetime = time + 1;
		
		bigprint("^xFB0Begin!", "It's time to kick some ass!", 1);

		sound(self, CHAN_VOICE, "announcer/robotic/begin.wav", VOL_BASEVOICE, ATTN_NONE);
		//reset maptime announcers now as well
		announcer_5min = announcer_1min = FALSE;

		remove(self);
		return;
	}
	else {
		//if (!spectatee_status) //do cprint only for players
		//{
		//	//centerprint(strcat("\x01^1Game starts in ", ftos(countdown_rounded), " seconds"));
		//	gamestart_status = countdown_rounded;
		//}

		//gamestart_status = countdown_rounded;
		//gamestart_fadetime = time + 0.5;
		//bigprint(strcat("Game starts in ", ftos(countdown_rounded)), "", 0.5);
		bigprint(" ", "", 1);
		bigprint(strcat(strcat(gametype_ID_to_LongName(gametype)), " starts in: ", ftos(countdown_rounded)), "", 1);

		if(countdown_rounded <= 3 && countdown_rounded >= 1) {
			sound(self, CHAN_VOICE, strcat("announcer/robotic/", ftos(countdown_rounded), ".wav"), VOL_BASEVOICE, ATTN_NONE);
		}

		self.nextthink = getstatf(STAT_GAMESTARTTIME) - (countdown - 1);
	}
}

/**
 * Plays the 1minute or 5 minutes (of maptime) remaining sound, if client wants it
 */
void maptimeAnnouncer() {
    float timelimit;
    timelimit = getstatf(STAT_TIMELIMIT);
    float timeleft;
    timeleft = max(0, timelimit * 60 + getstatf(STAT_GAMESTARTTIME) - time);

    //5 minute check
    if (cvar("cl_sound_maptime_warning") >= 2) {
        //make sure that after connect (and e.g. 4 minutes left) we will not get a wrong sound
        if(announcer_5min)
        {
			if(timeleft > 300)
				announcer_5min = FALSE;
        }
        else if (timelimit > 0 && timeleft < 300 && timeleft > 299) {
			announcer_5min = TRUE;
			//dprint("i will play the sound, I promise!\n");
			sound(self, CHAN_VOICE, "announcer/robotic/5minutesremain.wav", VOL_BASEVOICE, ATTN_NONE);
		}
    }

    //1 minute check
    if (cvar("cl_sound_maptime_warning") == 1 || cvar("cl_sound_maptime_warning") == 3) {
    	if (announcer_1min)
    	{
			if(timeleft > 60)
				announcer_1min = FALSE;
    	}
    	else if (timelimit > 0 && timeleft < 60) {
			announcer_1min = TRUE;
			sound(self, CHAN_VOICE, "announcer/robotic/1minuteremains.wav", VOL_BASEVOICE, ATTN_NONE);
    	}
	}
}

/**
 * Add all future announcer sounds precaches here.
 * TODO: make all announcer sound() calls client-side in the end, to allow queues etc.
 */
void Announcer_Precache () {
    precache_sound ("announcer/robotic/1minuteremains.wav");
	precache_sound ("announcer/robotic/5minutesremain.wav");
}

void AuditLists()
{
	entity e;
	entity prev;

	prev = players;
	for(e = prev.sort_next; e; prev = e, e = e.sort_next)
	{
		if(prev != e.sort_prev)
			error(strcat("sort list chain error\nplease submit the output of 'prvm_edicts client' to the developers"));
	}

	prev = teams;
	for(e = prev.sort_next; e; prev = e, e = e.sort_next)
	{
		if(prev != e.sort_prev)
			error(strcat("sort list chain error\nplease submit the output of 'prvm_edicts client' to the developers"));
	}
}


float RegisterPlayer(entity player)
{
	entity pl;
	AuditLists();
	for(pl = players.sort_next; pl; pl = pl.sort_next)
		if(pl == player)
			error("Player already registered!");
	player.sort_next = players.sort_next;
	player.sort_prev = players;
	if(players.sort_next)
		players.sort_next.sort_prev = player;
	players.sort_next = player;
	AuditLists();
	return true;
}

void RemovePlayer(entity player)
{
	entity pl, parent;
	AuditLists();
	parent = players;
	for(pl = players.sort_next; pl && pl != player; pl = pl.sort_next)
		parent = pl;

	if(!pl)
	{
		error("Trying to remove a player which is not in the playerlist!");
		return;
	}
	parent.sort_next = player.sort_next;
	if(player.sort_next)
		player.sort_next.sort_prev = parent;
	AuditLists();
}

void MoveToLast(entity e)
{
	AuditLists();
	other = e.sort_next;
	while(other)
	{
		SORT_SWAP(other, e);
		other = e.sort_next;
	}
	AuditLists();
}

float RegisterTeam(entity Team)
{
	entity tm;
	AuditLists();
	for(tm = teams.sort_next; tm; tm = tm.sort_next)
		if(tm == Team)
			error("Team already registered!");
	Team.sort_next = teams.sort_next;
	Team.sort_prev = teams;
	if(teams.sort_next)
		teams.sort_next.sort_prev = Team;
	teams.sort_next = Team;
	AuditLists();
	return true;
}

void RemoveTeam(entity Team)
{
	entity tm, parent;
	AuditLists();
	parent = teams;
	for(tm = teams.sort_next; tm && tm != Team; tm = tm.sort_next)
		parent = tm;

	if(!tm)
	{
		print("Trying to remove a team which is not in the teamlist!");
		return;
	}
	parent.sort_next = Team.sort_next;
	if(Team.sort_next)
		Team.sort_next.sort_prev = parent;
	AuditLists();
}

entity GetTeam(float Team, float add)
{
	float num;
	entity tm;
	num = (Team == COLOR_SPECTATOR) ? 16 : Team;
	if(teamslots[num])
		return teamslots[num];
	if not(add)
		return NULL;
	tm = spawn();
	tm.team = Team;
	teamslots[num] = tm;
	RegisterTeam(tm);
	return tm;
}

void CSQC_CheckEngine()
{
	sbar_font = FONT_USER+1;
	sbar_bigfont = FONT_USER+2;
	sbar_rmbigfont = FONT_USER+4;
	
	#ifdef RM_SUPPORT_MADOKA
	sbar_madokafont = FONT_USER+3;
	#else
	sbar_madokafont = FONT_USER+2;
	#endif
}

vector Sbar_GetFontsize(string cvarname)
{
	vector v;
	v = stov(cvar_string(cvarname));
	if(v_x == 0)
		v = '8 8 0';
	if(v_y == 0)
		v_y = v_x;
	v_z = 0;
	return v;
}

float Sbar_GetWidth(float teamcolumnwidth)
{
	#ifdef WE_DONT_NEED_TO_GO_WIDER
	float f;
	f = cvar("sbar_width");
	if(f == 0)
		f = 640;
	if(f < 320)
		f = 320;
	if(f > vid_conwidth - 2 * teamcolumnwidth)
		f = vid_conwidth - 2 * teamcolumnwidth;
	return f;
	#else
	return vid_conwidth - 2 * teamcolumnwidth;
	#endif
}

float PreviewExists(string name)
{
	float f;
	string file;

	if(cvar("cl_readpicture_force"))
		return false;

	file = strcat(name, ".tga");
	f = fopen(file, FILE_READ);
	if(f >= 0)
	{
		fclose(f);
		return true;
	}
	file = strcat(name, ".png");
	f = fopen(file, FILE_READ);
	if(f >= 0)
	{
		fclose(f);
		return true;
	}
	file = strcat(name, ".jpg");
	f = fopen(file, FILE_READ);
	if(f >= 0)
	{
		fclose(f);
		return true;
	}
	file = strcat(name, ".pcx");
	f = fopen(file, FILE_READ);
	if(f >= 0)
	{
		fclose(f);
		return true;
	}
	return false;
}

float PI      = 3.14159265359;
float DEG2RAD = 0.01745329252;
vector rotate(vector v, float a)
{
	vector w;
	// FTEQCC SUCKS AGAIN
	w_x =      v_x * cos(a) + v_y * sin(a);
	w_y = -1 * v_x * sin(a) + v_y * cos(a);
	return w;
}

float ColorTranslateMode;

string ColorTranslateRGB(string s)
{
	if(ColorTranslateMode & 1)
		return strdecolorize(s);
	else
		return s;
}

float cvar_or(string cv, float v)
{
	string s;
	s = cvar_string(cv);
	if(s == "")
		return v;
	else
		return stof(s);
}

vector project_3d_to_2d(vector vec)
{
	vec = cs_project(vec);
	if(cs_project_is_b0rked > 0)
	{
		vec_x *= vid_conwidth / vid_width;
		vec_y *= vid_conheight / vid_height;
	}
	return vec;
}

void dummyfunction(float a1, float a2, float a3, float a4, float a5, float a6, float a7, float a8)
{
}

float expandingbox_sizefactor_from_fadelerp(float fadelerp)
{
	return 1.2 / (1.2 - fadelerp);
}

vector expandingbox_resize_centered_box_offset(float sz, vector boxsize, float boxxsizefactor)
{
	boxsize_x *= boxxsizefactor; // easier interface for text
	return boxsize * (0.5 * (1 - sz));
}

void drawborderlines(float thickness, vector pos, vector dim, vector color, float alpha, float drawflag)
{
	vector line_dim;

	// left and right lines
	pos_x -= thickness;
	line_dim_x = thickness;
	line_dim_y = dim_y;
	drawfill(pos, line_dim, color, alpha, drawflag);
	drawfill(pos + (dim_x + thickness) * '1 0 0', line_dim, color, alpha, drawflag);

	// upper and lower lines
	pos_y -= thickness;
	line_dim_x = dim_x + thickness * 2; // make upper and lower lines longer
	line_dim_y = thickness;
	drawfill(pos, line_dim, color, alpha, drawflag);
	drawfill(pos + (dim_y + thickness) * '0 1 0', line_dim, color, alpha, drawflag);
}

void drawpic_tiled(vector pos, string pic, vector sz, vector area, vector color, float alpha, float drawflag, vector src_pos)
{
	vector current_pos, end_pos, new_size, ratio;
	end_pos = pos + area;

	current_pos_y = pos_y;
	while (current_pos_y < end_pos_y)
	{
		current_pos_x = pos_x;
		while (current_pos_x < end_pos_x)
		{
			new_size_x = min(sz_x, end_pos_x - current_pos_x);
			new_size_y = min(sz_y, end_pos_y - current_pos_y);
			ratio_x = new_size_x / sz_x;
			ratio_y = new_size_y / sz_y;
			drawsubpic(current_pos, new_size, pic, src_pos, ratio,
			           color, alpha, drawflag);
			current_pos_x += sz_x;
		}
		current_pos_y += sz_y;
	}
}

void drawpic_expanding(vector position, string pic, vector scale, vector rgb, float alpha, float flag, float fadelerp)
{
	float sz;
	sz = expandingbox_sizefactor_from_fadelerp(fadelerp);

	drawpic(position + expandingbox_resize_centered_box_offset(sz, scale, 1), pic, scale * sz, rgb, alpha * (1 - fadelerp), flag);
}

void drawpic_expanding_two(vector position, string pic, vector scale, vector rgb, float alpha, float flag, float fadelerp)
{
	drawpic_expanding(position, pic, scale, rgb, alpha, flag, fadelerp);
	drawpic(position, pic, scale, rgb, alpha * fadelerp, flag);
}

void drawstring_expanding(vector position, string text, vector scale, vector rgb, float alpha, float flag, float fadelerp)
{
	float sz;
	sz = expandingbox_sizefactor_from_fadelerp(fadelerp);

	dummyfunction(0, 0, 0, 0, 0, 0, 0, 0);
	drawstring(position + expandingbox_resize_centered_box_offset(sz, scale, stringwidth(text, FALSE)), text, scale * sz, rgb, alpha * (1 - fadelerp), flag);
}

void drawcolorcodedstring_expanding(vector position, string text, vector scale, float alpha, float flag, float fadelerp)
{
	float sz;
	sz = expandingbox_sizefactor_from_fadelerp(fadelerp);

	dummyfunction(0, 0, 0, 0, 0, 0, 0, 0);
	drawcolorcodedstring(position + expandingbox_resize_centered_box_offset(sz, scale, stringwidth(text, TRUE)), text, scale * sz, alpha * (1 - fadelerp), flag);
}

void drawrotpic(vector org, float rot, string pic, vector sz, vector hotspot, vector rgb, float a, float f);       

void drawpic_rotated(vector position, string pic, vector sz, vector rgb, float angle, float alpha, float flag) {
	drawrotpic(position + sz * 0.5, angle, pic, sz, sz * 0.5, rgb, alpha, flag);
}

void drawpic_rotated_ex(vector position, string pic, vector sz, vector rgb, float angle, vector hotspot, float alpha, float flag) {
	drawrotpic(position + hotspot, angle, pic, sz, hotspot, rgb, alpha, flag);
}

void loadfont(string slot, string font)
{
	/*if(cvar("rm_dontmesswithfonts"))
	{
		print("Warning: attempted a font change [", slot, " -> ", font, "], denied\n");
		return;
	}*/
	
	localcmd("loadfont ", slot, " gfx/", font, "\n");
}

void URI_Get_Callback(float id, float status, string data)
{
	if(id == URI_GET_IP2C)
	{
		IP2C_URI_Get_Callback(id, status, data);
		return;
	}
}

float stringwidth_svn(string text, float handleColors, vector fontSize);
#define SET_POS_AND_SZ_Y_ASPECT(allow_colors) float textaspect, oldsz; textaspect = stringwidth_svn(text, allow_colors, '1 1 1' * sz_y) / sz_y;	if(sz_x/sz_y > textaspect) { oldsz = sz_x; sz_x = sz_y * textaspect; pos_x += (oldsz - sz_x) * 0.5; } else { oldsz = sz_y; sz_y = sz_x / textaspect; pos_y += (oldsz - sz_y) * 0.5; }

// drawstring wrapper to draw a string as large as possible with preserved aspect ratio into a box
void drawstring_aspect(vector pos, string text, vector sz, vector color, float alpha, float drawflag) {
	SET_POS_AND_SZ_Y_ASPECT(FALSE)
	drawstring(pos, text, '1 1 0' * sz_y, color, alpha, drawflag);
}

// drawstring wrapper to draw a colorcodedstring as large as possible with preserved aspect ratio into a box
void drawcolorcodedstring_aspect(vector pos, string text, vector sz, float alpha, float drawflag) {
	SET_POS_AND_SZ_Y_ASPECT(TRUE)
	drawcolorcodedstring(pos, text, '1 1 0' * sz_y, alpha, drawflag);
}

vector healthcolor(float x) {
    vector c;
    c_z = 0;
    
    x = 200 * (x / sv_nicehealth);
    
    if(x > 600) {
        c_x = 0;
        c_y = 1;
        c_z = 1;
    } else if(x > 200) {
        c_x = 0;
        c_y = 1;
        c_z = (x-200)*0.0025;
    } else if(x > 150) {
        c_x = 0.4 - (x-150)*0.02 * 0.4;
        c_y = 0.9 + (x-150)*0.02 * 0.1;
    } else if(x > 100) {
        c_x = 1 - (x-100)*0.02 * 0.6;
        c_y = 1 - (x-100)*0.02 * 0.1;
        c_z = 1 - (x-100)*0.02;
    } else if(x > 50) {
        c_x = 1;
        c_y = 1;
        c_z = 0.2 + (x-50)*0.02 * 0.8;  
    } else if(x > 20) {
        c_x = 1;
        c_y = (x-20)*90/27/100;
        c_z = (x-20)*90/27/100 * 0.2;
    } else {
        c_x = 1;
        c_y = 0;
    }
    
    return c;
}
