void drawstringright(vector, string, vector, vector, float, float);
void drawstringcenter(vector, string, vector, vector, float, float);
void drawcolorcodedstringcenter(vector, string, vector, float, float);

float weapon_hits[WEP_COUNT];
float weapon_fired[WEP_COUNT];
float weapon_number;

float last_weapon;
float weapontime;

#define SECWIDTH_NORMAL 103
#define SECWIDTH_WIDE 206
#define SECWIDTH_HEALTH 217

float sbar_alpha_fg;
float sbar_alpha_bg;
float sbar_color_bg_team;
float sbar_border_thickness;
float sbar_scoreboard_alpha_bg;
float sbar_scoreboard_alpha_fg;
float sbar_scoreboard_highlight;
float sbar_scoreboard_highlight_alpha;
float sbar_scoreboard_highlight_alpha_self;
float sbar_hudselector;
float sbar_hud_accuracy;
float sbar_scoreboard_alpha_name;
float sbar_scoreboard_alpha_name_self;
float sbar_info_pos;

float ps_primary, ps_secondary;
float ts_primary, ts_secondary;

vector color;
float SCOREBOARD_OFFSET = 50;

float Sbar_WouldDrawScoreboard();

void CSQC_kh_hudreset();
void CSQC_kh_hud(vector);
void CSQC_ctf_hudreset();
void CSQC_ctf_hud(vector);
void CSQC_ft_hud(vector);
void CSQC_dom_hud(vector);
void CSQC_vip_hud(vector);
void CSQC_nb_hud();
void MapVote_Draw();
void Sbar_FinaleOverlay()
{
	/*vector pos;
	pos_x = (vid_conwidth - 1)/2;
	pos_y = 16;
	pos_z = 0;*/

	//drawpic(pos, "gfx/finale", '0 0 0', '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);

	//drawstring(pos, "END", sbar_fontsize, '1 1 1', 1, DRAWFLAG_NORMAL);
	MapVote_Draw();
}

float weaponspace[10];
float weapon_first, weapon_last;
void Sbar_DrawWeapon_Clear()
{
	float idx;
	weapon_first = -2;
	weapon_last = -1;
	for(idx = 0; idx < 10; ++idx)
		weaponspace[idx] = 0;
	for(idx = 0; idx <= 23; ++idx)
	{
		if(weaponimpulse[idx] >= 0)
		{
			if(weapon_first < 0)
				weapon_first = idx;
			weapon_last = idx;
		}
	}
}
void Sbar_DrawWeapon(float nr, float fade, float active, float wc)
{
	vector pos, vsize, fill_colour;
	float value, idx, imp, sp, weapon_hit, weapon_damage, weapon_stats;

	imp = weaponimpulse[nr];
	weapon_hit = weapon_hits[wc];
 	weapon_damage = weapon_fired[wc];
	if(imp == 0)
		idx = 9;
	else
		idx = imp - 1;

	value = (active) ? 1 : 0.6;
	color_x = color_y = color_z = value;

	// width = 300, height = 100
	const float w_width = 24, w_height = 12, w_space = 2, font_size = 8;

	sp = weaponspace[idx] + 1;
	weaponspace[idx] = sp;

	pos_x = (vid_conwidth + 6 - w_width * 9) * 0.5 + w_width * idx;
	pos_y = (vid_conheight - w_height * sp) - 38 - (rm_oldhud? 0 : 3); // move 38 pixels up
	pos_z = 0;
	vsize_x = w_width;
	vsize_y = w_height;
	vsize_z = 0;
	if (active)
		drawpic(pos, "gfx/hud/sb_ammobg", vsize, color, value * fade * sbar_alpha_fg, DRAWFLAG_NORMAL);
	drawpic(pos, strcat("gfx/hud/inv_weapon", ftos(nr)), vsize, color, value * fade * sbar_alpha_fg, DRAWFLAG_NORMAL);
	pos_x += w_space;
	pos_y += w_space;
	vsize_x = font_size;
	vsize_y = font_size;
	vsize_z = 0;
	drawstring(pos, ftos(imp), vsize, '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);

	// draw the weapon accuracy on the HUD
	if(sbar_hud_accuracy)
 	{
 		weapon_stats = rint(100*weapon_hit/weapon_damage);
 		fill_colour_x = 1 - 0.015 * weapon_stats;
 		fill_colour_y = 1 - 0.015 * (100 - weapon_stats);
 		drawstringright(pos + '22 0 0', strcat(ftos(weapon_stats),"%"), '6 6 0', fill_colour, sbar_alpha_fg, 0);
 	}
}

void Sbar_DrawXNum (vector pos, float num, float digits, float showminusplus, float lettersize, vector rgb, float highlighted, float stroke, float alpha, float dflags)
{
	float l, i;
	string str, tmp, l_length;
	float minus, plus;
	vector vsize, num_color;

	vsize_x = vsize_y = lettersize;
	vsize_z = 0;

	// showminusplus 1: always prefix with minus sign (useful in race distribution display)
	// showminusplus 2: always prefix with plus sign (useful in race distribution display)
	// showminusplus 3: prefix with minus sign if negative, plus sign if positive (useful in score distribution display)

	if((showminusplus == 2 && num >= 0) || (num > 0 && showminusplus == 3))
	{
		plus = true;
		pos_x -= lettersize;
	} else
		plus = false;

	if(num < 0 || (num < 0 && showminusplus == 3) || (showminusplus == 1 && num <= 0))
	{
		minus = true;
		num = -num;
		pos_x -= lettersize;
	} else
		minus = false;

	if(digits < 0)
	{
		tmp = ftos(num);
		digits = -digits;
		str = strcat(substring("0000000000", 0, digits - strlen(tmp)), tmp);
	} else
		str = ftos(num);

	l = strlen(str);
	l_length = ftos(l);

	if(l > digits)
	{
		str = substring(str, l-digits, 999);
		l = strlen(str);
	} else if(l < digits)
		pos_x += (digits-l) * lettersize;

	if (highlighted == 1) {
		vector hl_size;
		hl_size_x = vsize_x * l + vsize_x * 0.2;
		hl_size_y = vsize_y * 1.1;
		hl_size_z = 0;
		if(minus)
			hl_size_x = hl_size_x + vsize_x;

		vector hl_pos;
		hl_pos_x = pos_x - lettersize/10;
		hl_pos_y = pos_y - lettersize/20;
		hl_pos_z = 0;

		drawpic(hl_pos, strcat("gfx/hud/sb_highlight_", l_length), hl_size, '1 1 1', alpha, dflags);
	}

	if (stroke == 1)
		num_color = '1 1 1';
	else
		num_color = rgb;

	if(minus)
	{
		if (stroke == 1)
			drawpic(pos, "gfx/hud/num_minus_stroke", vsize, rgb, alpha, dflags);
		drawpic(pos, "gfx/hud/num_minus", vsize, num_color, alpha, dflags);
		pos_x += lettersize;
	} else if(plus)
	{
		if (stroke == 1)
			drawpic(pos, "gfx/hud/num_plus_stroke", vsize, rgb, alpha, dflags);
		drawpic(pos, "gfx/hud/num_plus", vsize, num_color, alpha, dflags);
		pos_x += lettersize;
	}

	for(i = 0; i < l; ++i)
	{
		tmp = substring(str, i, 1);
		if (stroke == 1)
			drawpic(pos, strcat("gfx/hud/num_", tmp, "_stroke"), vsize, rgb, alpha, dflags);
		drawpic(pos, strcat("gfx/hud/num_", tmp), vsize, num_color, alpha, dflags);
		pos_x += lettersize;
	}
}

void Sbar_DrawXNum_Colored (vector pos, float x, float lettersize, float alpha)
{
	Sbar_DrawXNum(pos, x, 3, 0, lettersize, healthcolor(x), 0, 0, alpha, DRAWFLAG_NORMAL);
}

void Cmd_Sbar_SetFields(float argc);
void Sbar_InitScores()
{
	float i, f;

	ps_primary = ps_secondary = ts_primary = ts_secondary = -1;
	for(i = 0; i < MAX_SCORE; ++i)
	{
		f = (scores_flags[i] & SFL_SORT_PRIO_MASK);
		if(f == SFL_SORT_PRIO_PRIMARY)
			ps_primary = i;
		if(f == SFL_SORT_PRIO_SECONDARY)
			ps_secondary = i;
	}
	if(ps_secondary == -1)
		ps_secondary = ps_primary;

	for(i = 0; i < MAX_TEAMSCORE; ++i)
	{
		f = (teamscores_flags[i] & SFL_SORT_PRIO_MASK);
		if(f == SFL_SORT_PRIO_PRIMARY)
			ts_primary = i;
		if(f == SFL_SORT_PRIO_SECONDARY)
			ts_secondary = i;
	}
	if(ts_secondary == -1)
		ts_secondary = ts_primary;

	Cmd_Sbar_SetFields(0);
}

void Sbar_UpdatePlayerPos(entity pl);
float SetTeam(entity pl, float Team);
//float lastpnum;
void Sbar_UpdatePlayerTeams()
{
	float Team;
	entity pl, tmp;
	float num;

	num = 0;
	for(pl = players.sort_next; pl; pl = pl.sort_next)
	{
		num += 1;
		Team = GetPlayerColor(pl.sv_entnum);
		if(SetTeam(pl, Team))
		{
			tmp = pl.sort_prev;
			Sbar_UpdatePlayerPos(pl);
			if(tmp)
				pl = tmp;
			else
				pl = players.sort_next;
		}
	}
	/*
	if(num != lastpnum)
		print(strcat("PNUM: ", ftos(num), "\n"));
	lastpnum = num;
	*/
}

float Sbar_ComparePlayerScores(entity left, entity right)
{
	float vl, vr;
	vl = GetPlayerColor(left.sv_entnum);
	vr = GetPlayerColor(right.sv_entnum);

	if(!left.gotscores)
		vl = COLOR_SPECTATOR;
	else if(cvar("g_inf"))
		vl = COLOR_TEAM1;
	if(!right.gotscores)
		vr = COLOR_SPECTATOR;
	else if(cvar("g_inf"))
		vr = COLOR_TEAM1;

	if(vl > vr)
		return true;
	if(vl < vr)
		return false;
	
	if(vl == COLOR_SPECTATOR)
	{
		// FIRST queued, THEN the one with scores (spectators), THEN the ones without (downloaders)
		// no other sorting
        
        if(!left.gotscores && right.gotscores)
            return true;
        
        vl = left.(scores[SP_QUEUE]);
        vr = right.(scores[SP_QUEUE]);
        
        if(vl > vr && vl)
            return true;
        
        return false;
	}

	vl = left.scores[ps_primary];
	vr = right.scores[ps_primary];
	if(scores_flags[ps_primary] & SFL_ZERO_IS_WORST)
	{
		if(vl == 0 && vr != 0)
			return 1;
		if(vl != 0 && vr == 0)
			return 0;
	}
	if(vl > vr)
		return IS_INCREASING(scores_flags[ps_primary]);
	if(vl < vr)
		return IS_DECREASING(scores_flags[ps_primary]);

	vl = left.scores[ps_secondary];
	vr = right.scores[ps_secondary];
	if(scores_flags[ps_secondary] & SFL_ZERO_IS_WORST)
	{
		if(vl == 0 && vr != 0)
			return 1;
		if(vl != 0 && vr == 0)
			return 0;
	}
	if(vl > vr)
		return IS_INCREASING(scores_flags[ps_secondary]);
	if(vl < vr)
		return IS_DECREASING(scores_flags[ps_secondary]);

	return false;
}

void Sbar_UpdatePlayerPos(entity player)
{
	for(other = player.sort_next; other && Sbar_ComparePlayerScores(player, other); other = player.sort_next)
	{
		SORT_SWAP(player, other);
	}
	for(other = player.sort_prev; other != players && Sbar_ComparePlayerScores(other, player); other = player.sort_prev)
	{
		SORT_SWAP(other, player);
	}
}

float Sbar_CompareTeamScores(entity left, entity right)
{
	float vl, vr;

	if(left.team == COLOR_SPECTATOR)
		return 1;
	if(right.team == COLOR_SPECTATOR)
		return 0;

	vl = left.teamscores[ts_primary];
	vr = right.teamscores[ts_primary];
	if(vl > vr)
		return IS_INCREASING(teamscores_flags[ts_primary]);
	if(vl < vr)
		return IS_DECREASING(teamscores_flags[ts_primary]);

	vl = left.teamscores[ts_secondary];
	vr = right.teamscores[ts_secondary];
	if(vl > vr)
		return IS_INCREASING(teamscores_flags[ts_secondary]);
	if(vl < vr)
		return IS_DECREASING(teamscores_flags[ts_secondary]);

	return false;
}

void Sbar_UpdateTeamPos(entity Team)
{
	for(other = Team.sort_next; other && Sbar_CompareTeamScores(Team, other); other = Team.sort_next)
	{
		SORT_SWAP(Team, other);
	}
	for(other = Team.sort_prev; other != teams && Sbar_CompareTeamScores(other, Team); other = Team.sort_prev)
	{
		SORT_SWAP(other, Team);
	}
}

void Cmd_Sbar_Help(float argc)
{
	print("You can modify the scoreboard using the ^2sbar_columns_set command.\n");
	print("^3|---------------------------------------------------------------|\n");
	print("Usage:\n");
	print("^2sbar_columns_set default\n");
	print("^2sbar_columns_set ^7filed1 field2 ...\n");
	print("The following field names are recognized (case insensitive):\n");
	print("You can use a ^3|^7 to start the right-aligned fields.\n\n");

	print("^3name^7 or ^3nick^7         Name of a player\n");
	print("^3ping^7                     Ping time\n");
	print("^3pl^7                       Packet loss\n");
	print("^3kills^7                    Number of kills\n");
	print("^3deaths^7                   Number of deaths\n");
	print("^3suicides^7                 Number of suicides\n");
	print("^3frags^7                    kills - suicides\n");
	print("^3kd^7                       The kill-death ratio\n");
	print("^3caps^7                     How often a flag (CTF) or a key (KeyHunt) was captured\n");
	print("^3pickups^7                  How often a flag (CTF) or a key (KeyHunt) was picked up\n");
	print("^3fckills^7                  Number of flag carrier kills\n");
	print("^3returns^7                  Number of flag returns\n");
	print("^3drops^7                    Number of flag drops\n");
	print("^3lives^7                    Number of lives (LMS)\n");
	print("^3rank^7                     Player rank\n");
	print("^3pushes^7                   Number of players pushed into void\n");
	print("^3destroyed^7                Number of keys destroyed by pushing them into void\n");
	print("^3kckills^7                  Number of keys carrier kills\n");
	print("^3losses^7                   Number of times a key was lost\n");
	print("^3laps^7                     Number of laps finished (race/cts)\n");
	print("^3time^7                     Total time raced (race/cts)\n");
	print("^3fastest^7                  Time of fastest lap (race/cts)\n");
	print("^3ticks^7                    Number of ticks (DOM)\n");
	print("^3takes^7                    Number of domination points taken (DOM)\n");
	print("^3hfrags^7                   Number of hookfrags\n\n");
	print("^3score^7                    Total score\n\n");

	print("Before a field you can put a + or - sign, then a comma separated list\n");
	print("of game types, then a slash, to make the field show up only in these\n");
	print("or in all but these game types. You can also specify 'all' as a\n");
	print("field to show all fields available for the current game mode.\n\n");

	print("The special game type names 'teams' and 'noteams' can be used to\n");
	print("include/exclude ALL teams/noteams game modes.\n\n");

	print("Example: sbar_columns_set name ping pl | +ctf/field3 -dm/field4\n");
	print("will display name, ping and pl aligned to the left, and the fields\n");
	print("right of the vertical bar aligned to the right.\n");
	print("'field3' will only be shown in CTF, and 'field4' will be shown in all\n");
	print("other gamemodes except DM.\n");
}

string Sbar_DefaultColumnLayout()
{
	return strcat( // fteqcc sucks
		strcat("ping pl", (sv_showfps? " fps" : ""), (cvar("rm_notimer")? "" : " time"), " cn +ctf/fc name | kdr", strcat(
        (sv_showacc? " acc" : ""), (g_minstagib? (cvar("_g_rocketminsta")? " hfs" : "") : " dmg"), (sv_scoreboard_heal_column? " heal" : ""), (g_nadgets? " nfs" : "")),
		" +ft,jb,vip/kills +ft,vip,jb/dths "),
		"-teams,race,lms/kills -teams,lms/dths -teams,lms,race/scds -race,dm,tdm,ft,jb,vip,prec,ca/frgs +ca/kills +ca/dths +ca/scds ", // tdm already has this in "score"
		"+ctf/caps +ctf/pckps +ctf/fcks +ctf/rtrns ",
		"+lms/lives +lms/rank +vip/vks +vip/surv +jb/def +jb/jbs +jb/freed +prec/pckps +prec/rcks ",
		"+kh/caps +kh/pckps +kh/kcks ",
		"?+race/laps ?+race/time ?+race/fastest ",
		"+as/objectives +nexball/faults +nexball/goals ",
		strcat("+tdm/dths +tdm/scds ", (g_freeze? "revs " : ""), "+dom,totaldom/takes -lms,race,nexball/score"));
}

void Cmd_Sbar_SetFields(float argc)
{
	float i, j, slash;
	string str, pattern;
	float digit;
	float have_name, have_primary, have_secondary, have_separator;
	float missing;

	// TODO: re enable with gametype dependant cvars?
	if(argc < 2) // no arguments provided
		argc = tokenizebyseparator(strcat("x ", cvar_string("sbar_columns")), " ");

	if(argc < 2)
		argc = tokenizebyseparator(strcat("x ", Sbar_DefaultColumnLayout()), " ");

	if(argc == 2)
	{
		if(argv(1) == "default")
			argc = tokenizebyseparator(strcat("x ", Sbar_DefaultColumnLayout()), " ");
		else if(argv(1) == "all")
		{
			string s;
			s = "ping pl color name |";
			for(i = 0; i < MAX_SCORE; ++i)
			{
				if(i != ps_primary)
				if(i != ps_secondary)
				if(scores_label[i] != "")
					s = strcat(s, " ", scores_label[i]);
			}
			if(ps_secondary != ps_primary)
				s = strcat(s, " ", scores_label[ps_secondary]);
			s = strcat(s, " ", scores_label[ps_primary]);
			argc = tokenizebyseparator(strcat("x ", s), " ");
		}
	}


	sbar_num_fields = 0;

	drawfont = sbar_font;
	digit = stringwidth("0123456789", FALSE) / 10;

	for(i = 0; i < argc - 1; ++i)
	{
		float nocomplain;
		str = argv(i+1);

		nocomplain = FALSE;
		if(substring(str, 0, 1) == "?")
		{
			nocomplain = TRUE;
			str = substring(str, 1, strlen(str) - 1);
		}

		slash = strstrofs(str, "/", 0);
		if(slash >= 0)
		{
			pattern = substring(str, 0, slash);
			str = substring(str, slash + 1, strlen(str) - (slash + 1));

			if not(isGametypeInFilter(gametype, teamplay, pattern))
				continue;
		}

		strunzone(sbar_title[sbar_num_fields]);
		sbar_title[sbar_num_fields] = strzone(str);
		sbar_size[sbar_num_fields] = stringwidth(str, FALSE);
		str = strtolower(str);

        if(str == "lag") {
            sbar_field[sbar_num_fields] = SP_LAG;
        } else if(str == "ping") {
			sbar_field[sbar_num_fields] = SP_PING;
		} else if(str == "pl") {
			sbar_field[sbar_num_fields] = SP_PL;
        } else if(str == "nade") {
            sbar_field[sbar_num_fields] = SP_NADEMODE;
		} else if(str == "fps") {
			sbar_field[sbar_num_fields] = SP_FPS;
		} else if(str == "kd" || str == "kdr" || str == "kdratio" || str == "k/d") {
			sbar_field[sbar_num_fields] = SP_KDRATIO;
		} else if(str == "name" || str == "nick") {
			sbar_field[sbar_num_fields] = SP_NAME;
			have_name = 1;
		} else if(str == "|") {
			sbar_field[sbar_num_fields] = SP_SEPARATOR;
			have_separator = 1;
		} else if(str == "cn") {
			sbar_field[sbar_num_fields] = SP_COUNTRY;
		} else if(str == "time") {
			sbar_field[sbar_num_fields] = SP_PLAYTIME;
        } else if(str == "dths") {
            sbar_field[sbar_num_fields] = SP_DEATHS;
        } else if(str == "scds") {
            sbar_field[sbar_num_fields] = SP_SUICIDES;
        } else if(str == "hfs") {
            sbar_field[sbar_num_fields] = SP_HOOKFRAGS;
        } else if(str == "nfs") {
            sbar_field[sbar_num_fields] = SP_NADEFRAGS;
        } else if(str == "dmg") {
            sbar_field[sbar_num_fields] = SP_DAMAGE;
        } else if(str == "heal") {
            sbar_field[sbar_num_fields] = SP_HEALING;
        } else if(str == "acc") {
            sbar_field[sbar_num_fields] = SP_ACCURACY;
        } else {
			for(j = 0; j < MAX_SCORE; ++j)
				if(str == strtolower(scores_label[j]))
					goto found; // sorry, but otherwise fteqcc -O3 miscompiles this and warns about "unreachable code"
:notfound
			if(str == "frags" || str == "frgs")
			{
				j = SP_FRAGS;
			}
			else
			{
				if not(nocomplain)
					print(strcat("^1Error:^7 Unknown score field: '", str, "'\n"));
				continue;
			}
:found
			sbar_field[sbar_num_fields] = j;
			if(j == ps_primary)
				have_primary = 1;
			if(j == ps_secondary)
				have_secondary = 1;
		}
		++sbar_num_fields;
		if(sbar_num_fields >= MAX_SBAR_FIELDS)
			break;
	}

	if(scores_flags[ps_primary] & SFL_ALLOW_HIDE)
		have_primary = 1;
	if(scores_flags[ps_secondary] & SFL_ALLOW_HIDE)
		have_secondary = 1;
	if(ps_primary == ps_secondary)
		have_secondary = 1;
	missing = (!have_primary) + (!have_secondary) + (!have_separator) + (!have_name);

	if(sbar_num_fields+missing < MAX_SBAR_FIELDS)
	{
		if(!have_name)
		{
			strunzone(sbar_title[sbar_num_fields]);
			for(i = sbar_num_fields; i > 0; --i)
			{
				sbar_title[i] = sbar_title[i-1];
				sbar_size[i] = sbar_size[i-1];
				sbar_field[i] = sbar_field[i-1];
			}
			sbar_title[0] = strzone("name");
			sbar_field[0] = SP_NAME;
			++sbar_num_fields;
			print("fixed missing field 'name'\n");

			if(!have_separator)
			{
				strunzone(sbar_title[sbar_num_fields]);
				for(i = sbar_num_fields; i > 1; --i)
				{
					sbar_title[i] = sbar_title[i-1];
					sbar_size[i] = sbar_size[i-1];
					sbar_field[i] = sbar_field[i-1];
				}
				sbar_title[1] = strzone("|");
				sbar_field[1] = SP_SEPARATOR;
				sbar_size[1] = stringwidth("|", FALSE);
				++sbar_num_fields;
				print("fixed missing field '|'\n");
			}
		}
		else if(!have_separator)
		{
			strunzone(sbar_title[sbar_num_fields]);
			sbar_title[sbar_num_fields] = strzone("|");
			sbar_size[sbar_num_fields] = stringwidth("|", FALSE);
			sbar_field[sbar_num_fields] = SP_SEPARATOR;
			++sbar_num_fields;
			print("fixed missing field '|'\n");
		}
		if(!have_secondary)
		{
			strunzone(sbar_title[sbar_num_fields]);
			sbar_title[sbar_num_fields] = strzone(scores_label[ps_secondary]);
			sbar_size[sbar_num_fields] = stringwidth(sbar_title[sbar_num_fields], FALSE);
			sbar_field[sbar_num_fields] = ps_secondary;
			++sbar_num_fields;
			print("fixed missing field '", scores_label[ps_secondary], "'\n");
		}
		if(!have_primary)
		{
			strunzone(sbar_title[sbar_num_fields]);
			sbar_title[sbar_num_fields] = strzone(scores_label[ps_primary]);
			sbar_size[sbar_num_fields] = stringwidth(sbar_title[sbar_num_fields], FALSE);
			sbar_field[sbar_num_fields] = ps_primary;
			++sbar_num_fields;
			print("fixed missing field '", scores_label[ps_primary], "'\n");
		}
	}

	sbar_field[sbar_num_fields] = SP_END;
}

// MOVEUP::
vector sbar_field_rgb;
string sbar_field_icon0;
string sbar_field_icon1;
string sbar_field_icon2;
vector sbar_field_icon0_rgb;
vector sbar_field_icon1_rgb;
vector sbar_field_icon2_rgb;
float sbar_field_icon0_alpha;
float sbar_field_icon1_alpha;
float sbar_field_icon2_alpha;
string Sbar_GetField(entity pl, float field)
{
	float tmp, num, denom, f;
	string str, str2;
    vector v;
	sbar_field_rgb = '1 1 1';
	sbar_field_icon0 = "";
	sbar_field_icon1 = "";
	sbar_field_icon2 = "";
	sbar_field_icon0_rgb = '1 1 1';
	sbar_field_icon1_rgb = '1 1 1';
	sbar_field_icon2_rgb = '1 1 1';
	sbar_field_icon0_alpha = 1;
	sbar_field_icon1_alpha = 1;
	sbar_field_icon2_alpha = 1;
	switch(field)
	{
		case SP_CARRYING:
			local string strToDraw;
			strToDraw = "";
			local float stuff = pl.(scores [SP_CARRYING]);
			if (stuff & 1) strToDraw = strcat (strToDraw, "^1", chr2str (139)); // red
			if (stuff & 2) strToDraw = strcat (strToDraw, "^4", chr2str (139)); // blue
// CTF doesn't use these, but leave them here if someone decides to make this work with KH
//			if (stuff & 4) strToDraw = strcat (strToDraw, "^3", chr2str (139)); // yellow
//			if (stuff & 8) strToDraw = strcat (strToDraw, "^6", chr2str (139)); // pink
			return strToDraw;
		case SP_COUNTRY:
            float char0 = pl.(scores[SP_COUNTRY]) & 0xff;
            float char1 = floor(pl.(scores[SP_COUNTRY]) / 256) & 0xff;

            if(!char0 || !char1)
                return "";

            return strcat(chr2str(char0), chr2str(char1));
        case SP_PLAYTIME:
            if(pl.(scores[SP_AWAYSTATUS]))
                return "AFK";
            if(GetPlayerColor(pl.sv_entnum) == COLOR_SPECTATOR)
                return "";
            // return mmss(pl.(scores[field]) * 10);
            return strcat(ftos(floor(pl.(scores[field]) / 60)), "m");

		case SP_PING:
			if not(pl.gotscores)
				return "\x8D\x8D\x8D"; // >>> sign
			str = getplayerkey(pl.sv_entnum, "ping");
			tmp = max(0, min(220, stof(str)-80)) / 220;
			sbar_field_rgb = '1 1 1' - '0 1 1'*tmp;
			return str;

		case SP_PL:
			if not(pl.gotscores)
				return "";
                
			str = getplayerkey(pl.sv_entnum, "pl");
			if(str == "0")
				return "";
                
			tmp = bound(0, stof(str), 20) / 20; // 20% is REALLY BAD pl
			sbar_field_rgb = '1 0.5 0.5' - '0 0.5 0.5'*tmp;
			return str;

        case SP_LAG:
            str = Sbar_GetField(pl, SP_PING);
            v = sbar_field_rgb;
            str2 = Sbar_GetField(pl, SP_PL);
            
            if(str2 != "") {
                str = strcat(str, " (", str2, ")");
                if(sbar_field_rgb_y < v_y)
                    v = sbar_field_rgb;
            }
            
            sbar_field_rgb = v;
            return str;

		case SP_FPS:
			if not(pl.gotscores)
				return "N/A";
			
			tmp = pl.(scores[field]);
			sbar_field_rgb = '1 0 0' + '0 1 1' * (bound(0, tmp, 60) / 60);
			return ftos(tmp);

		case SP_NAME:
			if(ready_waiting && pl.ready)
			{
				sbar_field_icon0 = "gfx/sb_player_ready";
			}
            /*
			else if(!teamplay)
			{
				f = stof(getplayerkey(pl.sv_entnum, "colors"));
				{
					sbar_field_icon0 = "gfx/sb_playercolor_base";
					sbar_field_icon1 = "gfx/sb_playercolor_shirt";
					sbar_field_icon1_rgb = colormapPaletteColor(floor(f / 16), 0);
					sbar_field_icon2 = "gfx/sb_playercolor_pants";
					sbar_field_icon2_rgb = colormapPaletteColor(mod(f, 16), 1);
				}
			}
            */
            else if(g_nadgets && cvar("_g_nadgets_select_available")) {
                if(GetPlayerColor(pl.sv_entnum) != COLOR_SPECTATOR) {
                    float hgt = pl.(scores[SP_NADEMODE]);
                    sbar_field_icon0 = HG_TypeToIcon(hgt, FALSE, FALSE);
                    sbar_field_icon0_rgb = HG_TypeToColor(hgt);
                }
            }
			return GetPlayerName(pl.sv_entnum);

		case SP_FRAGS:
			f = pl.(scores[SP_KILLS]);
			f -= pl.(scores[SP_SUICIDES]);
			return ftos(f);
        
        case SP_DAMAGE: case SP_HEALING:
            return FormatDamage(pl.(scores[field]));
            
		case SP_KDRATIO:
			num = pl.(scores[SP_KILLS]);
			denom = pl.(scores[SP_DEATHS]);

			if(denom == 0) {
                if(num == 0) {
                    sbar_field_rgb = '0.5 0.5 0.5';
                    str = "n/a";
                } else {
                    sbar_field_rgb = '0 1 1';
                    str = "inf";
                }
			} else {
				float ratio = max(0, num/denom);
				
				if(ratio < 1)
					sbar_field_rgb = '1 0 0' + '0 1 0' * (ratio * ratio);
				else if(ratio < 3)
					sbar_field_rgb = '1 1 0' - '1 0 0' * (ratio - 1);
				else
					sbar_field_rgb = '0 1 0' + '0 0 1' * ((ratio - 2) * 0.125);
				
				str = strcat(ftos(rint(ratio * 100)), "%");
                
                if(substring(str, 0, 1) == "-")
                    str = substring(str, 1, strlen(str)-1);
			}
			
			return str;
        
        case SP_NADEMODE:
            float m = pl.(scores[SP_NADEMODE]);
            sbar_field_rgb = HG_TypeToColor(m);
            return "";
        
        case SP_ACCURACY:
            float acc = pl.scores[SP_ACCURACY];
            
            if(acc < 0) {
                sbar_field_rgb = '0.5 0.5 0.5';
                return "n/a";
            }
            
            if(acc < 40)
                sbar_field_rgb = '1 0 0' + '0 1 0' * pow(acc / 40, 2);
            else if(acc < 70)
                sbar_field_rgb = '1 1 0' - '1 0 0' * ((acc - 40) / 30);
            else
                sbar_field_rgb = '0 1 0' + '0 0 1' * ((acc - 70) / 30);
            
            return strcat(ftos(acc), "%");
        
		default:
			tmp = pl.(scores[field]);
			f = scores_flags[field];
			if(field == ps_primary)
				sbar_field_rgb = '1 1 0';
			else if(field == ps_secondary)
				sbar_field_rgb = '0 1 1';
			else
				sbar_field_rgb = '1 1 1';
			return ScoreString(f, tmp);
	}
	//return "error";
}

float xmin, xmax, ymin, ymax, sbwidth;
float sbar_fixscoreboardcolumnwidth_len;
float sbar_fixscoreboardcolumnwidth_iconlen;
float sbar_fixscoreboardcolumnwidth_marginlen;

float stringwidth_colors(string s)
{
	return stringwidth(s, TRUE);
}

float stringwidth_nocolors(string s)
{
	return stringwidth(s, FALSE);
}

string Sbar_FixScoreboardColumnWidth(float i, string str)
{
	float field, f;
	vector sz;
	field = sbar_field[i];

	sbar_fixscoreboardcolumnwidth_iconlen = 0;

	if(sbar_field_icon0 != "")
	{
		sz = drawgetimagesize(sbar_field_icon0);
		f = sz_x / sz_y;
		if(sbar_fixscoreboardcolumnwidth_iconlen < f)
			sbar_fixscoreboardcolumnwidth_iconlen = f;
	}

	if(sbar_field_icon1 != "")
	{
		sz = drawgetimagesize(sbar_field_icon1);
		f = sz_x / sz_y;
		if(sbar_fixscoreboardcolumnwidth_iconlen < f)
			sbar_fixscoreboardcolumnwidth_iconlen = f;
	}

	if(sbar_field_icon2 != "")
	{
		sz = drawgetimagesize(sbar_field_icon2);
		f = sz_x / sz_y;
		if(sbar_fixscoreboardcolumnwidth_iconlen < f)
			sbar_fixscoreboardcolumnwidth_iconlen = f;
	}

	sbar_fixscoreboardcolumnwidth_iconlen *= sbar_fontsize_y / sbar_fontsize_x; // fix icon aspect

	if(sbar_fixscoreboardcolumnwidth_iconlen != 0)
		sbar_fixscoreboardcolumnwidth_marginlen = stringwidth(" ", FALSE);
	else
		sbar_fixscoreboardcolumnwidth_marginlen = 0;

	if(field == SP_NAME) // name gets all remaining space
	{
		float namesize, j;
		namesize = sbwidth / sbar_fontsize_x;
		for(j = 0; j < sbar_num_fields; ++j)
			if(j != i)
				if (sbar_field[i] != SP_SEPARATOR)
					namesize -= sbar_size[j] + 1;
		namesize += 1;
		sbar_size[i] = namesize;

		if (sbar_fixscoreboardcolumnwidth_iconlen != 0)
			namesize -= sbar_fixscoreboardcolumnwidth_marginlen + sbar_fixscoreboardcolumnwidth_iconlen;
		str = textShortenToWidth(str, namesize, stringwidth_colors);
		sbar_fixscoreboardcolumnwidth_len = stringwidth(str, TRUE);
	}
	else if(field == SP_COUNTRY)
		sbar_fixscoreboardcolumnwidth_len = stringwidth("XX", FALSE);
	else
		sbar_fixscoreboardcolumnwidth_len = stringwidth(str, FALSE);

	f = sbar_fixscoreboardcolumnwidth_len + sbar_fixscoreboardcolumnwidth_marginlen + sbar_fixscoreboardcolumnwidth_iconlen;
	if(sbar_size[i] < f)
		sbar_size[i] = f;

	return str;
}

void Sbar_PrintScoreboardItem(vector pos, entity pl, float is_self, float pl_number)
{
	vector tmp, rgb;
	rgb = GetTeamRGB(pl.team);
	string str;
	float i, field;
	float is_spec;
	is_spec = (GetPlayerColor(pl.sv_entnum) == COLOR_SPECTATOR);

	if((rgb == '1 1 1') && (!is_spec)) {
		rgb_x = cvar("sbar_color_bg_r") + 0.5;
		rgb_y = cvar("sbar_color_bg_g") + 0.5;
		rgb_z = cvar("sbar_color_bg_b") + 0.5; }

	// Layout:
	tmp_x = sbwidth;
	tmp_y = sbar_fontsize_y * 1.25;
	tmp_z = 0;

	local float a;
	a = (is_self? sbar_scoreboard_alpha_name_self : sbar_scoreboard_alpha_name);

	// alternated rows highlighting
	/*
	if (is_self)
		drawfill(pos - '1 1 0', tmp + '2 0 0', '1 1 1', 0.25, DRAWFLAG_NORMAL);
	else
	{
		if (sbar_scoreboard_highlight)
			if(!mod(pl_number,2))
				drawfill(pos - '1 1 0', tmp + '2 0 0', '1 1 1', 0.09, DRAWFLAG_NORMAL);
	}
	*/
	
	if(is_self)
		drawfill(pos - '1 1 0', tmp + '2 0 0', rgb, sbar_scoreboard_highlight_alpha_self, DRAWFLAG_NORMAL);
	else if((sbar_scoreboard_highlight) && (!mod(pl_number,2)))
		drawfill(pos - '1 1 0', tmp + '2 0 0', rgb, sbar_scoreboard_highlight_alpha, DRAWFLAG_NORMAL);

	tmp_y = 0;

	for(i = 0; i < sbar_num_fields; ++i)
	{
		field = sbar_field[i];
		if(field == SP_SEPARATOR)
			break;

		if(is_spec && field != SP_NAME && field != SP_PING && field != SP_PL && field != SP_LAG && field != SP_PLAYTIME && field != SP_COUNTRY) {
			pos_x += sbar_fontsize_x*sbar_size[i] + sbar_fontsize_x;
			continue;
		}
		str = Sbar_GetField(pl, field);
		str = Sbar_FixScoreboardColumnWidth(i, str);

		pos_x += sbar_fontsize_x*sbar_size[i] + sbar_fontsize_x;

		if(field == SP_NAME) {
			tmp_x = sbar_fontsize_x*(sbar_size[i] - sbar_fixscoreboardcolumnwidth_iconlen - sbar_fixscoreboardcolumnwidth_marginlen) + sbar_fontsize_x;

			#ifdef RM_SUPPORT_MADOKA
			local float tmp_font;
			tmp_font = drawfont;

			if(pl.(scores[SP_MADOKASTATUS]))
				drawfont = sbar_madokafont;
			#endif

/*
			if(gametype != GAME_FREEZETAG && gametype != GAME_JAILBREAK)
				drawcolorcodedstring(pos - tmp, str, sbar_fontsize, a, DRAWFLAG_NORMAL);
			else
*/
			{
				if(pl.(scores[SP_FROZENSTATUS]))
					drawcolorcodedstring(pos - tmp, str, sbar_fontsize, a * 0.3, DRAWFLAG_NORMAL);
				else
					drawcolorcodedstring(pos - tmp, str, sbar_fontsize, a, DRAWFLAG_NORMAL);
			}

			#ifdef RM_SUPPORT_MADOKA
			drawfont = tmp_font;
			#endif
		} else if(field == SP_COUNTRY && !rm_noflags) {
			tmp_x = sbar_fixscoreboardcolumnwidth_len*sbar_fontsize_x + sbar_fontsize_x;

			local float scale = sbar_fontsize_x / 11;

			if(str != "")
				drawpic(pos - tmp, strcat("gfx/flags/", str), '16 11 0' * scale, '1 1 1', sbar_scoreboard_alpha_fg, DRAWFLAG_NORMAL);
		} else if (field == SP_CARRYING) {
			tmp_x = sbar_fixscoreboardcolumnwidth_len * sbar_fontsize_x + sbar_fontsize_x;
			drawcolorcodedstring (pos - tmp, str, sbar_fontsize, a, DRAWFLAG_NORMAL);
		} else {
			tmp_x = sbar_fixscoreboardcolumnwidth_len*sbar_fontsize_x + sbar_fontsize_x;
			drawstring(pos - tmp, str, sbar_fontsize, sbar_field_rgb, sbar_scoreboard_alpha_fg, DRAWFLAG_NORMAL);
		}

		tmp_x = sbar_fontsize_x*sbar_size[i] + sbar_fontsize_x;
		if(sbar_field_icon0 != "") {
            float fa = 1 - (pl.(scores[SP_FROZENSTATUS]) * 0.7);
			drawpic(pos - tmp, sbar_field_icon0, '0 1 0' * sbar_fontsize_y + '1 0 0' * sbar_fontsize_x * sbar_fixscoreboardcolumnwidth_iconlen, sbar_field_icon0_rgb, sbar_field_icon0_alpha*a*fa, DRAWFLAG_NORMAL);
        }
		if(sbar_field_icon1 != "")
			drawpic(pos - tmp, sbar_field_icon1, '0 1 0' * sbar_fontsize_y + '1 0 0' * sbar_fontsize_x * sbar_fixscoreboardcolumnwidth_iconlen, sbar_field_icon1_rgb, sbar_field_icon1_alpha*a, DRAWFLAG_NORMAL);
		if(sbar_field_icon2 != "")
			drawpic(pos - tmp, sbar_field_icon2, '0 1 0' * sbar_fontsize_y + '1 0 0' * sbar_fontsize_x * sbar_fixscoreboardcolumnwidth_iconlen, sbar_field_icon2_rgb, sbar_field_icon2_alpha*a, DRAWFLAG_NORMAL);
	}

	if(sbar_field[i] == SP_SEPARATOR)
	{
		pos_x = xmax;
		for(i = sbar_num_fields-1; i > 0; --i)
		{
			field = sbar_field[i];
			if(field == SP_SEPARATOR)
				break;

			if(is_spec && field != SP_NAME && field != SP_PING) {
				pos_x -= sbar_fontsize_x*sbar_size[i] + sbar_fontsize_x;
				continue;
			}

			str = Sbar_GetField(pl, field);
			str = Sbar_FixScoreboardColumnWidth(i, str);

			if(field == SP_NAME) {
				tmp_x = sbar_fontsize_x*sbar_fixscoreboardcolumnwidth_len; // left or right aligned? let's put it right...
				drawcolorcodedstring(pos - tmp, str, sbar_fontsize, a, DRAWFLAG_NORMAL);
            } else if(field == SP_NADEMODE) {
				tmp_x = (1+sbar_size[i])*sbar_fontsize_x*0.5 + sbar_fontsize_x * 0.25;
                drawpic(pos - tmp, HG_TypeToIcon(pl.(scores[SP_NADEMODE]), FALSE, FALSE), sbar_fontsize, sbar_field_rgb, 1, DRAWFLAG_NORMAL);
			} else {
				tmp_x = sbar_fontsize_x*sbar_fixscoreboardcolumnwidth_len;
                if(pl.(hasbestscore[field]) && field != SP_KDRATIO)
                    sbar_field_rgb = '0.3 1 0.3';
				drawstring(pos - tmp, str, sbar_fontsize, sbar_field_rgb, a, DRAWFLAG_NORMAL);
			}

			tmp_x = sbar_fontsize_x*sbar_size[i];
			if(sbar_field_icon0 != "")
				drawpic(pos - tmp, sbar_field_icon0, '0 1 0' * sbar_fontsize_y + '1 0 0' * sbar_fontsize_x * sbar_fixscoreboardcolumnwidth_iconlen, sbar_field_icon1_rgb, sbar_field_icon0_alpha*a, DRAWFLAG_NORMAL);
			if(sbar_field_icon1 != "")
				drawpic(pos - tmp, sbar_field_icon1, '0 1 0' * sbar_fontsize_y + '1 0 0' * sbar_fontsize_x * sbar_fixscoreboardcolumnwidth_iconlen, sbar_field_icon1_rgb, sbar_field_icon1_alpha*a, DRAWFLAG_NORMAL);
			if(sbar_field_icon2 != "")
				drawpic(pos - tmp, sbar_field_icon2, '0 1 0' * sbar_fontsize_y + '1 0 0' * sbar_fontsize_x * sbar_fixscoreboardcolumnwidth_iconlen, sbar_field_icon2_rgb, sbar_field_icon2_alpha*a, DRAWFLAG_NORMAL);

			pos_x -= sbar_fontsize_x*sbar_size[i] + sbar_fontsize_x;
		}
	}
}

/*
 * Sbar_Scoreboard_MakeTable
 *
 * Makes a table for a team (for all playing players in DM) and fills it
 */

vector Sbar_Scoreboard_MakeTable(vector pos, entity tm, vector rgb,
								 vector bg_size, entity tm2)
{
	float body_table_height, i;
	vector tmp, column_dim;
	entity pl;

	if(tm == tm2)
		body_table_height = 1.25 * sbar_fontsize_y * max(1, tm.team_size); // no player? show 1 empty line
	else
		body_table_height += 1.25 * sbar_fontsize_y * max(1, (tm2.team_size + tm.team_size));

	pos -= '1 1 0';

	tmp_x = sbwidth + 2;
	tmp_y = 1.25 * sbar_fontsize_y;

	// rounded header
	drawpic(pos, "gfx/hud/sb_scoreboard_tableheader", tmp, '0.5 0.5 0.5', sbar_scoreboard_alpha_bg, DRAWFLAG_NORMAL);

	// table border
	tmp_y += sbar_border_thickness;
	tmp_y += body_table_height;
	drawborderlines(sbar_border_thickness, pos, tmp, '0 0 0', sbar_scoreboard_alpha_bg, DRAWFLAG_NORMAL); // more transparency for the scoreboard

	// separator header/table
	pos_y += 1.25 * sbar_fontsize_y;
	tmp_y = sbar_border_thickness;
	drawfill(pos, tmp, '0 0 0', sbar_scoreboard_alpha_bg, DRAWFLAG_NORMAL);

	pos_y += sbar_border_thickness;

	if(tm == tm2)
	{
		// table background
		tmp_y = body_table_height;
		drawpic_tiled(pos, "gfx/hud/sb_scoreboard_bg", bg_size, tmp, rgb * sbar_color_bg_team, sbar_scoreboard_alpha_bg, DRAWFLAG_NORMAL, '0 0 0');
	}
	else // specifically for Infection mode (hacky, ik)
	{
		local vector lpos, ltmp, l_src_pos;
		lpos = pos;
		ltmp_x = tmp_x;
		ltmp_y = 1.25 * sbar_fontsize_y;
		l_src_pos = '0 0 0';
		for(pl = players.sort_next; pl; pl = pl.sort_next)
		{
			if(pl.team != tm.team && pl.team != tm2.team)
				continue;
			drawpic_tiled(lpos, "gfx/hud/sb_scoreboard_bg", bg_size, ltmp,
			              GetTeamRGB(pl.team) * sbar_color_bg_team,
			              sbar_scoreboard_alpha_bg, DRAWFLAG_NORMAL, l_src_pos);
			lpos_y += 1.25 * sbar_fontsize_y;
			l_src_pos_y += (1.25 * sbar_fontsize_y) / bg_size_y;
			while(l_src_pos_y >= 1)
				l_src_pos_y -= 1;
		}
	}

	// anyway, apply some color
	//drawfill(pos, tmp + '2 0 0', rgb, 0.1, DRAWFLAG_NORMAL);

	// go back to the top to make alternated columns highlighting and to print the strings
	pos_y -= 1.25 * sbar_fontsize_y;
	pos_y -= sbar_border_thickness;

	pos += '1 1 0';

	if (sbar_scoreboard_highlight)
	{
		column_dim_y = 1.25 * sbar_fontsize_y; // header
		column_dim_y += sbar_border_thickness;
		column_dim_y += body_table_height;
	}

	// print the strings of the columns headers and draw the columns
	for(i = 0; i < sbar_num_fields; ++i)
	{
		if(sbar_field[i] == SP_SEPARATOR)
			break;
		column_dim_x = sbar_fontsize_x*sbar_size[i] + sbar_fontsize_x;
		if (sbar_scoreboard_highlight)
		{
			if (mod(i,2))
				drawfill(pos - '0 1 0' - sbar_fontsize_x / 2 * '1 0 0', column_dim, '0 0 0', sbar_scoreboard_alpha_bg * 0.2, DRAWFLAG_NORMAL);
		}
		drawstring(pos, sbar_title[i], sbar_fontsize, rgb, sbar_scoreboard_alpha_fg, DRAWFLAG_NORMAL);
		pos_x += column_dim_x;
	}
	if(sbar_field[i] == SP_SEPARATOR)
	{
		pos_x = xmax;
		tmp_y = 0;
		for(i = sbar_num_fields-1; i > 0; --i)
		{
			if(sbar_field[i] == SP_SEPARATOR)
				break;

			pos_x -= sbar_size[i]*sbar_fontsize_x;

			if (sbar_scoreboard_highlight)
			{
				if (!mod(i,2))
				{
					if (i == sbar_num_fields-1)
						column_dim_x = sbar_fontsize_x*sbar_size[i] + sbar_fontsize_x / 2 + 1;
					else
						column_dim_x = sbar_fontsize_x*sbar_size[i] + sbar_fontsize_x;
					drawfill(pos - '0 1 0' - sbar_fontsize_x / 2 * '1 0 0', column_dim, '0 0 0', sbar_scoreboard_alpha_bg * 0.2, DRAWFLAG_NORMAL);
				}
			}

			tmp_x = stringwidth(sbar_title[i], FALSE);
			tmp_x = (sbar_size[i] - tmp_x) * sbar_fontsize_x;
			drawstring(pos + tmp, sbar_title[i], sbar_fontsize, rgb, sbar_scoreboard_alpha_fg, DRAWFLAG_NORMAL);
			pos_x -= sbar_fontsize_x;
		}
	}

	pos_x = xmin;
	pos_y += 1.25 * sbar_fontsize_y; // skip the header
	pos_y += sbar_border_thickness;

	// fill the table and draw the rows
	i = 0;
	if (teamplay) {
		float plrs;
		float countping = !tm.avg_ping;
		
		for(pl = players.sort_next; pl; pl = pl.sort_next)
		{
			if(pl.team != tm.team && pl.team != tm2.team)
				continue;
				
			Sbar_PrintScoreboardItem(pos, pl, (pl.sv_entnum == player_localentnum - 1), i);
			
			if(countping) {
				float theping = stof(getplayerkey(pl.sv_entnum, "ping"));
				
				if(theping) {			// bots don't count
					tm.avg_ping += theping;
					++plrs;
				}
			}
			
			pos_y += 1.25 * sbar_fontsize_y;
			++i;
		}
		
		if(countping) {
			tm.avg_ping = rint(tm.avg_ping / plrs);
			tm.avg_ping_next = time + 1;
		}
	}
	else
		for(pl = players.sort_next; pl; pl = pl.sort_next)
		{
			if(pl.team == COLOR_SPECTATOR)
				continue;
			Sbar_PrintScoreboardItem(pos, pl, (pl.sv_entnum == player_localentnum - 1), i);
			pos_y += 1.25 * sbar_fontsize_y;
			++i;
		}

	if (i == 0)
		pos_y += 1.25 * sbar_fontsize_y; // move to the end of the table
	pos_y += 1.25 * sbar_fontsize_y; // move empty row (out of the table)

	return pos;
}

float lastpingstime;
float scoreboard_bottom;

float scoreboard_bottom;
float sbar_scoreboard_fade_alpha;
float sbar_woulddrawscoreboard_prev;
float sbar_woulddrawscoreboard_change; // "time" at which Sbar_WouldDrawScoreboard() changed

void Sbar_DrawScoreboard()
{
	vector rgb, pos, tmp;
	entity pl, tm;

	float sbar_woulddrawscoreboard; 
	sbar_woulddrawscoreboard = Sbar_WouldDrawScoreboard();
	if(sbar_woulddrawscoreboard != sbar_woulddrawscoreboard_prev) {
		sbar_woulddrawscoreboard_change = time;
		sbar_woulddrawscoreboard_prev = sbar_woulddrawscoreboard;
	}

	float scoreboard_fadeinspeed = 15;
	float scoreboard_fadeoutspeed = 5;
	if(sbar_woulddrawscoreboard) {
		if not(sv_oldfag)
			sbar_scoreboard_fade_alpha = bound (0, (time - sbar_woulddrawscoreboard_change) * scoreboard_fadeinspeed, 1);
		else
			sbar_scoreboard_fade_alpha = 1;
	}
	else
		if not(sv_oldfag)
			sbar_scoreboard_fade_alpha = bound (0, (1/scoreboard_fadeoutspeed - (time - sbar_woulddrawscoreboard_change)) * scoreboard_fadeoutspeed, 1);
		else
			sbar_scoreboard_fade_alpha = 0;

	if not(sbar_scoreboard_fade_alpha)
		return;
	
	vector sbar_fontsize_old = sbar_fontsize;
    /*
    if(sbar_fontsize_x > 10)
        sbar_fontsize_x = 10;
    if(sbar_fontsize_y > 10)
        sbar_fontsize_y = 10;
    */
	sbar_fontsize = sbar_fontsize * (sbar_woulddrawscoreboard? ipol_linear : ipol_swingOut)(sbar_scoreboard_fade_alpha);
	
	sbar_scoreboard_alpha_bg = cvar("sbar_scoreboard_alpha_bg") * sbar_scoreboard_fade_alpha;
	sbar_scoreboard_alpha_fg = 1.0 * sbar_scoreboard_fade_alpha;
	sbar_scoreboard_highlight = cvar("sbar_scoreboard_highlight");
	sbar_scoreboard_highlight_alpha = 0.10 * sbar_scoreboard_alpha_fg;
	sbar_scoreboard_highlight_alpha_self = 0.25 * sbar_scoreboard_alpha_fg;
	sbar_scoreboard_alpha_name = 0.9 * sbar_scoreboard_alpha_fg;
	sbar_scoreboard_alpha_name_self = 1 * sbar_scoreboard_alpha_fg;
	
	if(time > lastpingstime + 10)
	{
		localcmd("pings\n");
		lastpingstime = time;
	}

	sbwidth = Sbar_GetWidth(6.5 * sbar_fontsize_y);

	xmin = 0.5 * (vid_conwidth - sbwidth);
	ymin = SCOREBOARD_OFFSET;

	xmax = vid_conwidth - xmin;
	ymax = vid_conheight - 0.2*vid_conheight;

	// Initializes position
	pos_x = xmin;
	pos_y = ymin;
	pos_z = 0;

	// Heading
	drawfont = sbar_bigfont;
	//drawstringcenter('0 1 0' * ymin, "Scoreboard", '24 24 0', '1 1 1', 1, DRAWFLAG_NORMAL);

	pos_y += 24 + 4;
	pos_y += sbar_fontsize_y;

	drawfont = sbar_font;

	// Draw the scoreboard
	vector bg_size;
	bg_size = drawgetimagesize("gfx/hud/sb_scoreboard_bg");

	if(cvar("g_inf"))
	{
		rgb_x = cvar("sbar_color_bg_r");
		rgb_y = cvar("sbar_color_bg_g");
		rgb_z = cvar("sbar_color_bg_b");
		local entity tm1, tm2;
		for(tm = teams.sort_next; tm; tm = tm.sort_next)
			if(tm.team == COLOR_TEAM1)
				tm1 = tm;
			else if(tm.team == COLOR_TEAM2)
				tm2 = tm;
		pos = Sbar_Scoreboard_MakeTable(pos, tm1, rgb, bg_size, tm2);
	}
	else if(teamplay)
	{
		for(tm = teams.sort_next; tm; tm = tm.sort_next)
		{
			if(tm.team == COLOR_SPECTATOR)
				continue;

			rgb = GetTeamRGB(tm.team);
			
			Sbar_DrawXNum(pos - '6.5 0 0' * sbar_fontsize_y + '0 1 0' * sbar_fontsize_y, tm.(teamscores[ts_primary]), 4, 0, sbar_fontsize_y * 1.5, rgb, 0, 1, sbar_scoreboard_alpha_fg, DRAWFLAG_NORMAL);
			
			if(ts_primary != ts_secondary)
				Sbar_DrawXNum(pos - '4.5 0 0' * sbar_fontsize_y + '0 2.5 0' * sbar_fontsize_y, tm.(teamscores[ts_secondary]), 4, 0, sbar_fontsize_y * 1, rgb, 0, 1, sbar_scoreboard_alpha_fg, DRAWFLAG_NORMAL);
			
			if(tm.avg_ping) {
				drawstringright(pos - '1 0 0' * sbar_fontsize_x, ftos(tm.avg_ping), sbar_fontsize,
								'1 1 1' - '0 1 1' * (max(0, min(220, tm.avg_ping - 80)) / 220),
				1, DRAWFLAG_NORMAL);
				
				if(tm.avg_ping_next < time)
					tm.avg_ping = 0;
			}
				
			pos = Sbar_Scoreboard_MakeTable(pos, tm, rgb, bg_size, tm);
		}
	}
	else
	{
		rgb_x = cvar("sbar_color_bg_r");
		rgb_y = cvar("sbar_color_bg_g");
		rgb_z = cvar("sbar_color_bg_b");

		for(tm = teams.sort_next; tm; tm = tm.sort_next)
		{
			if(tm.team == COLOR_SPECTATOR)
				continue;

			pos = Sbar_Scoreboard_MakeTable(pos, tm, rgb, bg_size, tm);
		}
	}

	float specs;
	specs = 0;
    
    tmp = pos + '0 1.5 0' * sbar_fontsize_y;
	pos_y += 3 * sbar_fontsize_y;

	// List queued
	for(pl = players.sort_next; pl; pl = pl.sort_next)
	{
		if(pl.team != COLOR_SPECTATOR || !pl.(scores[SP_QUEUE]))
			continue;
		Sbar_PrintScoreboardItem(pos, pl, (pl.sv_entnum == player_localentnum - 1), specs);
		pos_y += 1.25 * sbar_fontsize_y;
		++specs;
	}

	if(specs)
		drawstring(tmp, "Queued", sbar_fontsize, '1 1 1', sbar_scoreboard_alpha_fg, DRAWFLAG_NORMAL);
    
	tmp = pos + '0 1.5 0' * sbar_fontsize_y;
	pos_y += 3 * sbar_fontsize_y;
    specs = 0;

	// List spectators
	for(pl = players.sort_next; pl; pl = pl.sort_next)
	{
		if(pl.team != COLOR_SPECTATOR || pl.(scores[SP_QUEUE]))
			continue;
		Sbar_PrintScoreboardItem(pos, pl, (pl.sv_entnum == player_localentnum - 1), specs);
		pos_y += 1.25 * sbar_fontsize_y;
		++specs;
	}

	if(specs)
		drawstring(tmp, "Spectators", sbar_fontsize, '1 1 1', sbar_scoreboard_alpha_fg, DRAWFLAG_NORMAL);

	// Print info string
	string str;
	float tl, fl, ll;
	//str = strcat("playing on ^2", shortmapname, "^7");

	str = strcat("playing ^5", gametype_ID_to_LongName(gametype), "^7 on ^2", shortmapname, "^7");

	tl = getstatf(STAT_TIMELIMIT);
	fl = getstatf(STAT_FRAGLIMIT);
	ll = getstatf(STAT_LEADLIMIT);
	if(gametype == GAME_LMS)
	{
		if(tl > 0)
			str = strcat(str, " for up to ^1", ftos(tl), " minutes^7");
	}
	else
	{
		if(tl > 0)
			str = strcat(str, " up to ^1", ftos(tl), " minutes^7");
		if(fl > 0)
		{
			if(tl > 0)
				str = strcat(str, " or");
			if(teamplay)
			{
				str = strcat(str, " until ^3", ScoreString(teamscores_flags[ts_primary], fl));
				if(teamscores_label[ts_primary] == "score")
					str = strcat(str, " points^7");
				else if(teamscores_label[ts_primary] == "fastest")
					str = strcat(str, " is beaten^7");
				else
					str = strcat(str, " ", teamscores_label[ts_primary]);
			}
			else
			{
				str = strcat(str, " until ^3", ScoreString(scores_flags[ps_primary], fl));
				if(scores_label[ps_primary] == "score")
					str = strcat(str, " points^7");
				else if(scores_label[ps_primary] == "fastest")
					str = strcat(str, " is beaten^7");
				else
					str = strcat(str, " ", scores_label[ps_primary]);
			}
		}
		if(ll > 0)
		{
			if(tl > 0 || fl > 0)
				str = strcat(str, " or");
			if(teamplay)
			{
				str = strcat(str, " until a lead of ^3", ScoreString(teamscores_flags[ts_primary], ll));
				if(teamscores_label[ts_primary] == "score")
					str = strcat(str, " points^7");
				else if(teamscores_label[ts_primary] == "fastest")
					str = strcat(str, " is beaten^7");
				else
					str = strcat(str, " ", teamscores_label[ts_primary]);
			}
			else
			{
				str = strcat(str, " until a lead of ^3", ScoreString(scores_flags[ps_primary], ll));
				if(scores_label[ps_primary] == "score")
					str = strcat(str, " points^7");
				else if(scores_label[ps_primary] == "fastest")
					str = strcat(str, " is beaten^7");
				else
					str = strcat(str, " ", scores_label[ps_primary]);
			}
		}
	}


	pos_y += 1.2 * sbar_fontsize_y;
	drawcolorcodedstring(pos + '0.5 0 0' * (sbwidth - sbar_fontsize_x * stringwidth(str, TRUE)), str, sbar_fontsize, sbar_scoreboard_alpha_fg * 0.8, DRAWFLAG_NORMAL);

	scoreboard_bottom = pos_y + 2 * sbar_fontsize_y;
	sbar_fontsize = sbar_fontsize_old;
}

string MakeRaceString(float cp, float mytime, float histime, float lapdelta, string hisname)
{
	string col;
	string timestr;
	string cpname;
	string lapstr;
	lapstr = "";

	if(histime == 0) // goal hit
	{
		if(mytime > 0)
		{
			timestr = strcat("+", ftos_decimals(+mytime, TIME_DECIMALS));
			col = "^1";
		}
		else if(mytime == 0)
		{
			timestr = "+0.0";
			col = "^3";
		}
		else
		{
			timestr = strcat("-", ftos_decimals(-mytime, TIME_DECIMALS));
			col = "^2";
		}

		if(lapdelta > 0)
		{
			lapstr = strcat(" (-", ftos(lapdelta), "L)");
			col = "^2";
		}
		else if(lapdelta < 0)
		{
			lapstr = strcat(" (+", ftos(-lapdelta), "L)");
			col = "^1";
		}
	}
	else if(histime > 0) // anticipation
	{
		if(mytime >= histime)
			timestr = strcat("+", ftos_decimals(mytime - histime, TIME_DECIMALS));
		else
			timestr = TIME_ENCODED_TOSTRING(TIME_ENCODE(histime));
		col = "^3";
	}
	else
		col = "^7";

	if(cp == 254)
		cpname = "Start line";
	else if(cp == 255)
		cpname = "Finish line";
	else if(cp)
		cpname = strcat("Intermediate ", ftos(cp));
	else
		cpname = "Finish line";

	if(histime < 0)
		return strcat(col, cpname);
	else if(hisname == "")
		return strcat(col, cpname, " (", timestr, ")");
	else
		return strcat(col, cpname, " (", timestr, " ", strcat(hisname, col, lapstr), ")");
}

void Sbar_DrawScore_Rankings(vector, vector, entity);
void Sbar_Score()
{
	float score, distribution, leader;
	vector score_pos, secondary_score_pos, distribution_color;
	entity tm, pl, me;
	me = (spectatee_status > 0) ? playerslots[spectatee_status - 1] : playerslots[player_localentnum - 1];

 	vector bottomright;
 	bottomright_x = vid_conwidth;
 	bottomright_y = vid_conheight;
 	bottomright_z = 0;

	if(rm_oldhud)
	{
		score_pos = bottomright - '196 42 0';
		secondary_score_pos = score_pos + '132 -6 0';
	}
	else
	{
		score_pos = bottomright - '178 38 0';
		secondary_score_pos = score_pos + '72 0 0';
	}

	vector rpos, rsize = '100 100 0';
	rpos = bottomright;
	rpos_y -= 150;
	rpos_x -= 105;

	if((scores_flags[ps_primary] & SFL_TIME) && !teamplay) { // race/cts record display on HUD
		pl = players.sort_next;
		if(pl == me)
			pl = pl.sort_next;
		if(scores_flags[ps_primary] & SFL_ZERO_IS_WORST)
			if(pl.scores[ps_primary] == 0)
				pl = world;

		score = me.(scores[ps_primary]);

		float racemin, racesec, racemsec;
		float distsec, distmsec, minusplus;

		racemin = floor(score/(60 * TIME_FACTOR));
		racesec = floor((score - racemin*(60 * TIME_FACTOR))/TIME_FACTOR);
		racemsec = score - racemin*60*TIME_FACTOR - racesec*TIME_FACTOR;

		if (pl && ((!(scores_flags[ps_primary] & SFL_ZERO_IS_WORST)) || score)) {
			// distribution display
			distribution = me.(scores[ps_primary]) - pl.(scores[ps_primary]);

			if (distribution < TIME_FACTOR && distribution > -TIME_FACTOR)
				distmsec = fabs(distribution);
			else {
				distsec = floor(fabs(distribution)/TIME_FACTOR);
				distmsec = fabs(distribution) - distsec*TIME_FACTOR;
				if (distribution < 0)
					distsec = -distsec;
			}

			if (distribution <= 0) {
				distribution_color = '0 1 0';
				minusplus = 1; // minusplus 1: always prefix with minus sign
			}
			else {
				distribution_color = '1 0 0';
				minusplus = 2; // minusplus 1: always prefix with plus sign
			}
			Sbar_DrawXNum(bottomright - '0 48 0' - '16 0 0' * TIME_DECIMALS, distmsec, -TIME_DECIMALS, 0, 16, distribution_color, 0, 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
			Sbar_DrawXNum(bottomright - '68 48 0' - '16 0 0' * TIME_DECIMALS, distsec, 4, minusplus, 16, distribution_color, 0, 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
			drawpic(bottomright - '10 48 0' - '16 0 0' * TIME_DECIMALS, "gfx/hud/num_dot", '16 16 0', distribution_color, sbar_alpha_fg, DRAWFLAG_ADDITIVE);
		}
		// race record display
		if (distribution <= 0 || distribution == score) // draw the highlight background behind the timer if we have the lead
			drawpic(bottomright - '0 32 0' - '32 0 0' * (4 + TIME_DECIMALS), "gfx/hud/sb_highlight_4", '0 28 0' + '32 0 0' * (4 + TIME_DECIMALS), '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);

		Sbar_DrawXNum(bottomright - '0 32 0' - TIME_DECIMALS * '30 0 0', racemsec, -TIME_DECIMALS, 0, 30, '1 1 1', 0, 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
		Sbar_DrawXNum(bottomright - '0 32 0' - TIME_DECIMALS * '30 0 0'  - '66 0 0', racesec, -2, 0, 30, '1 1 1', 0, 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
		drawpic(bottomright - '0 32 0' - TIME_DECIMALS * '30 0 0' - '18 0 0', "gfx/hud/num_dot", '30 30 0', '1 1 1', sbar_alpha_fg, DRAWFLAG_ADDITIVE);

		Sbar_DrawXNum(bottomright - '0 32 0' - TIME_DECIMALS * '30 0 0' - '132 0 0', racemin, -2, 0, 30, '1 1 1', 0, 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
		drawpic(bottomright - '0 32 0' - TIME_DECIMALS * '30 0 0' - '84 0 0', "gfx/hud/num_colon", '30 30 0', '1 1 1', sbar_alpha_fg, DRAWFLAG_ADDITIVE);

	} else if (!teamplay) { // non-teamgames, except race/cts
		// me vector := [team/connected frags id]
		
		Sbar_DrawScore_Rankings(rpos, rsize, me);
		
		pl = players.sort_next;
		if(pl == me)
			pl = pl.sort_next;

		if(pl)
			distribution = me.(scores[ps_primary]) - pl.(scores[ps_primary]);
		else
			distribution = 0;

		score = me.(scores[ps_primary]);

		if(distribution >= 5) {
			distribution_color = '0 1 0';
			leader = 1;
		} else if(distribution >= 0) {
			distribution_color = '1 1 1';
			leader = 1;
		} else if(distribution >= -5)
			distribution_color = '1 1 0';
		else
			distribution_color = '1 0 0';

		if(rm_oldhud)
		{
			Sbar_DrawXNum(secondary_score_pos, distribution, 4, 3, 16, distribution_color, 0, 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
			Sbar_DrawXNum(score_pos, score, 4, 0, 34, distribution_color, leader, 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
		}
		else
		{
			score_pos = score_pos + ((score > 9)? '24 0 0' : '0 0 0');
			secondary_score_pos = score_pos + '24 0 0' * 2.7 + '16 0 0' * (distribution > 9);
			
			Sbar_DrawXNum(score_pos, score, 4, 0, 24, GetTeamRGB(tm.team) * ((!leader)? 1 : 0.8) + ((!leader)? '0.2 0.2 0.2' : '0 0 0'), 0, leader, sbar_alpha_fg, DRAWFLAG_NORMAL);
			Sbar_DrawXNum(secondary_score_pos, distribution, 4, 3, 16, distribution_color, 0, 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
		}
	} else { // teamgames
		float max_fragcount;
		max_fragcount = -999;

		for(tm = teams.sort_next; tm; tm = tm.sort_next) {
			if(tm.team == COLOR_SPECTATOR || !tm.team_size) // no players? don't display
				continue;
			score = tm.(teamscores[ts_primary]);
			leader = 0;

			if (score > max_fragcount)
				max_fragcount = score;

			if(tm.team == myteam) {
				if (max_fragcount == score)
					leader = 1;

				if(rm_oldhud)
					Sbar_DrawXNum(score_pos, score, 4, 0, 34, GetTeamRGB(tm.team) * 0.8, leader, 1, sbar_alpha_fg, DRAWFLAG_NORMAL);
				else
					Sbar_DrawXNum(score_pos + ((score > 9)? '24 0 0' : '0 0 0'), score, 4, 0, 24, GetTeamRGB(tm.team) * ((!leader)? 1 : 0.8) + ((!leader)? '0.2 0.2 0.2' : '0 0 0'), 0, leader, sbar_alpha_fg, DRAWFLAG_NORMAL);
			} else {
				if (max_fragcount == score)
					leader = 1;

				if(rm_oldhud)
				{
					Sbar_DrawXNum(secondary_score_pos, score, 4, 0, 16, GetTeamRGB(tm.team) * 0.8, leader, 1, sbar_alpha_fg, DRAWFLAG_NORMAL);
					secondary_score_pos = secondary_score_pos + '0 16 0';
				}
				else
				{
					Sbar_DrawXNum(secondary_score_pos, score, 4, 0, 16, GetTeamRGB(tm.team) * ((!leader)? 1 : 0.8) + ((!leader)? '0.2 0.2 0.2' : '0 0 0'), 0, leader, sbar_alpha_fg, DRAWFLAG_NORMAL);
					secondary_score_pos = secondary_score_pos + '18 0 0';
				}
			}
		}
		
		Sbar_DrawScore_Rankings(rpos, rsize, me);
	}

	if(gametype == GAME_RACE || gametype == GAME_CTS)
	{
		drawfont = sbar_bigfont;
		float a, t;
		vector m;
		string s, forcetime;

		m = '0.5 0 0' * vid_conwidth + '0 0.25 0' * vid_conheight;

		if(race_checkpointtime)
		{
			a = bound(0, 2 - (time - race_checkpointtime), 1);
			s = "";
			forcetime = "";
			if(a > 0) // just hit a checkpoint?
			{
				if(race_checkpoint != 254)
				{
					if(race_time && race_previousbesttime)
						s = MakeRaceString(race_checkpoint, TIME_DECODE(race_time) - TIME_DECODE(race_previousbesttime), 0, 0, race_previousbestname);
					else
						s = MakeRaceString(race_checkpoint, 0, -1, 0, race_previousbestname);
					if(race_time)
						forcetime = TIME_ENCODED_TOSTRING(race_time);
				}
			}
			else
			{
				if(race_laptime && race_nextbesttime && race_nextcheckpoint != 254)
				{
					a = bound(0, 2 - ((race_laptime + TIME_DECODE(race_nextbesttime)) - (time + TIME_DECODE(race_penaltyaccumulator))), 1);
					if(a > 0) // next one?
					{
						s = MakeRaceString(race_nextcheckpoint, (time + TIME_DECODE(race_penaltyaccumulator)) - race_laptime, TIME_DECODE(race_nextbesttime), 0, race_nextbestname);
					}
				}
			}

			if(s != "" && a > 0)
			{
				dummyfunction(0, 0, 0, 0, 0, 0, 0, 0); // work around DP bug (set OFS_PARAM5 to 0)
				drawcolorcodedstring(m - '0 16 0' - '8 0 0' * stringwidth(s, TRUE), s, '16 16 0', sbar_alpha_fg * a, DRAWFLAG_NORMAL);
			}

			if(race_penaltytime)
			{
				a = bound(0, 2 - (time - race_penaltyeventtime), 1);
				if(a > 0)
				{
					s = strcat("^1PENALTY: ", ftos_decimals(race_penaltytime * 0.1, 1), " (", race_penaltyreason, ")");
					dummyfunction(0, 0, 0, 0, 0, 0, 0, 0); // work around DP bug (set OFS_PARAM5 to 0)
					drawcolorcodedstring(m - '0 32 0' - '8 0 0' * stringwidth(s, TRUE), s, '16 16 0', sbar_alpha_fg * a, DRAWFLAG_NORMAL);
				}
			}

			if(forcetime != "")
			{
				a = bound(0, (time - race_checkpointtime) / 0.5, 1);
				drawstring_expanding(m - '16 0 0' * stringwidth(forcetime, FALSE), forcetime, '32 32 0', '1 1 1', sbar_alpha_fg, 0, a);
			}
			else
				a = 1;

			if(race_laptime && race_checkpoint != 255)
			{
				s = TIME_ENCODED_TOSTRING(TIME_ENCODE(time + TIME_DECODE(race_penaltyaccumulator) - race_laptime));
				drawstring(m - '16 0 0' * stringwidth(s, FALSE), s, '32 32 0', '1 1 1', sbar_alpha_fg * a, DRAWFLAG_NORMAL);
			}
		}
		else
		{
			if(race_mycheckpointtime)
			{
				a = bound(0, 2 - (time - race_mycheckpointtime), 1);
				s = MakeRaceString(race_mycheckpoint, TIME_DECODE(race_mycheckpointdelta), -!race_mycheckpointenemy, race_mycheckpointlapsdelta, race_mycheckpointenemy);
				dummyfunction(0, 0, 0, 0, 0, 0, 0, 0); // work around DP bug (set OFS_PARAM5 to 0)
				drawcolorcodedstring(m - '0 16 0' - '8 0 0' * stringwidth(s, TRUE), s, '16 16 0', sbar_alpha_fg * a, DRAWFLAG_NORMAL);
			}
			if(race_othercheckpointtime && race_othercheckpointenemy != "")
			{
				a = bound(0, 2 - (time - race_othercheckpointtime), 1);
				s = MakeRaceString(race_othercheckpoint, -TIME_DECODE(race_othercheckpointdelta), -!race_othercheckpointenemy, race_othercheckpointlapsdelta, race_othercheckpointenemy);
				dummyfunction(0, 0, 0, 0, 0, 0, 0, 0); // work around DP bug (set OFS_PARAM5 to 0)
				drawcolorcodedstring(m - '0 0 0' - '8 0 0' * stringwidth(s, TRUE), s, '16 16 0', sbar_alpha_fg * a, DRAWFLAG_NORMAL);
			}

			if(race_penaltytime && !race_penaltyaccumulator)
			{
				t = race_penaltytime * 0.1 + race_penaltyeventtime;
				a = bound(0, (1 + t - time), 1);
				if(a > 0)
				{
					if(time < t)
						s = strcat("^1PENALTY: ", ftos_decimals(t - time, 1), " (", race_penaltyreason, ")");
					else
						s = strcat("^2PENALTY: 0.0 (", race_penaltyreason, ")");
					dummyfunction(0, 0, 0, 0, 0, 0, 0, 0); // work around DP bug (set OFS_PARAM5 to 0)
					drawcolorcodedstring(m - '0 32 0' - '8 0 0' * stringwidth(s, TRUE), s, '16 16 0', sbar_alpha_fg * a, DRAWFLAG_NORMAL);
				}
			}
		}

		drawfont = sbar_font;
	}
}

float timer_alpha;
void Sbar_Timer()
{
	float timelimit, elapsedTime, minutes, seconds, timeleft, minutesLeft, secondsLeft;
	vector bgpos, timer_color;
	bgpos = '0 0 0';

	vector topright;
	topright = '0 0 0';
	topright_x = vid_conwidth;

	//if(!rm_oldhud)
	//	topright_y = vid_conheight - 60;

	timelimit = getstatf(STAT_TIMELIMIT);

	timeleft = max(0, timelimit * 60 + getstatf(STAT_GAMESTARTTIME) - time);
	timeleft = ceil(timeleft);
	minutesLeft = floor(timeleft / 60);
	secondsLeft = timeleft - minutesLeft*60;

	if(minutesLeft >= 5 || warmup_stage || timelimit == 0) //don't use red or yellow in warmup or when there is no timelimit
		timer_color = '1 1 1'; //white
	else if(minutesLeft >= 1)
		timer_color = '1 1 0'; //yellow
	else
		timer_color = '1 0 0'; //red
    
    float a;
    
    if(rm_showtimer)
        a = 1;
    else {
        if(timer_color == '1 1 1')
            timer_alpha = approach(timer_alpha, 0, frametime * 5);
        else
            timer_alpha = approach(timer_alpha, 1, frametime * 5);

        a = max(timer_alpha, sbar_scoreboard_fade_alpha);
        
        if(!a)
            return;
    }
    
    topright_x += 100 * (1 - a);
    topright_y -= 18 * (1 - a);
    
	if (cvar("sbar_increment_maptime") || timelimit == 0 || warmup_stage) {
		if (time < getstatf(STAT_GAMESTARTTIME)) {
			//while restart is still active, show 00:00
			minutes = seconds = 0;
		} else {
			elapsedTime = floor(time - getstatf(STAT_GAMESTARTTIME)); //127
			minutes = floor(elapsedTime / 60);
			seconds = elapsedTime - minutes*60;
		}
		if (minutes < 10)
			bgpos_x = topright_x - 54 - 17 - 12;
		else if (minutes < 100)	// nudge the timer background left if more digits are drawn
			bgpos_x = topright_x - 72 - 17 - 12;
		else
			bgpos_x = topright_x - 90 - 17 - 12;
		bgpos_y = topright_y;
		bgpos_z = 0;
	} else {
		minutes = minutesLeft;
		seconds = secondsLeft;
		if (minutes == 0)
		bgpos_x = topright_x - 36 - 7 - 12;
		else if (minutes < 10) // nudge the timer background left if more digits are drawn
			bgpos_x = topright_x - 54 - 17 - 12;
		else if (minutes < 100)
			bgpos_x = topright_x - 72 - 17 - 12;
		else
			bgpos_x = topright_x - 90 - 17 - 12;
		bgpos_y = topright_y;
		bgpos_z = 0;
	}

	if(rm_oldhud)
	{
		if (cvar("viewsize") <= 100) { // draw timer background when viewsize <= 100
			if (teamplay)
				drawpic(bgpos, "gfx/hud/sb_timerbg", '120 30 0', GetTeamRGB(myteam) * sbar_color_bg_team, sbar_alpha_bg * a, DRAWFLAG_NORMAL); // timer bg color = myteam color
			else {
				color_x = cvar("sbar_color_bg_r");
				color_y = cvar("sbar_color_bg_g");
				color_z = cvar("sbar_color_bg_b");

				drawpic(bgpos, "gfx/hud/sb_timerbg", '120 30 0', color, sbar_alpha_bg * a, DRAWFLAG_NORMAL);
			}
		}
	}

	if(minutesLeft >= 1 || cvar("sbar_increment_maptime") || timelimit == 0 || warmup_stage) {
		Sbar_DrawXNum(topright - '1 0 0'*SECWIDTH_NORMAL + '0 2 0', minutes, 3, 0, 18, timer_color, 0, 0, sbar_alpha_fg * a, DRAWFLAG_NORMAL);
		drawpic(topright - '53 0 0' + '0 1 0', "gfx/hud/num_colon", '18 18 0', timer_color, sbar_alpha_fg * a, DRAWFLAG_NORMAL);
	}
	Sbar_DrawXNum(topright - '36 0 0' - '3 0 0' + '0 2 0', seconds, -2, 0, 18, timer_color, 0, 0, sbar_alpha_fg * a, DRAWFLAG_NORMAL);
}

float Sbar_WouldDrawScoreboard() {
    if (sb_showaccuracy)
        return 0;
	if (is_tmpmadoka)
		return 0;
	else if (sb_showscores)
		return 1;
	else if (intermission == 1)
		return 1;
	else if (intermission == 2)
		return 1;
	else if (spectatee_status == -1)
		return 0;
	else if (getstati(STAT_HEALTH) <= 0 && cvar("cl_deathscoreboard"))
		return 1;
	else if(sb_showscores_force)
		return 1;
	return 0;
}

float pwhud_enabled;

void CSQC_Strength_Timer(vector sectorpos) {
	vector pos, numpos;
	vector bottom;

	bottom_x = vid_conwidth/2;
	bottom_y = vid_conheight;
	bottom_z = 0;

	float stat_items, dt;
	stat_items = getstati(STAT_ITEMS);
	/*
	if not(stat_items & IT_STRENGTH)
		if not(stat_items & IT_INVINCIBLE)
			return;
	*/

	pwhud_enabled = FALSE;

	if (getstati(STAT_HEALTH) <= 0)
		return;

	vector picsize;
	float strength_time, invincibility_time, countdown_fontsize;

	picsize = '22 22 0';
	
	if(rm_oldhud)
	{
		if (vid_conwidth >= 800)
			pos = bottom + '192 -46 0';
		else
			pos = bottom + '192 -94 0';
		numpos = pos - '40 -2 0';
		countdown_fontsize = 18;
	}
	else
	{
		pos = sectorpos;
		pos_y -= 1;
		numpos = pos + '8 10 0';
		countdown_fontsize = 14;
	}

	//strength
	strength_time = getstatf(STAT_STRENGTH_FINISHED);
	invincibility_time = getstatf(STAT_INVINCIBLE_FINISHED);

	if (strength_time)
	{
		dt = strength_time - time;
		if(dt > 0)
		{
			if(dt < 5)
			{
				drawpic_expanding_two(pos, "gfx/hud/sb_str", picsize, '1 1 1', sbar_alpha_fg, DRAWFLAG_ADDITIVE,
					bound(0, (ceil(dt) - dt) / 0.5, 1));
			}
			else
			{
				drawpic(pos, "gfx/hud/sb_str", picsize, '1 1 1', sbar_alpha_fg, DRAWFLAG_ADDITIVE);
			}
			
			if(!rm_oldhud)
			if(ceil(dt) < 10)
				numpos_x -= countdown_fontsize;
			
			Sbar_DrawXNum(numpos, ceil(dt), 2, 0, countdown_fontsize, '1 1 1', 0, 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
			pwhud_enabled = TRUE;
		}
		else if(dt > -1)
		{
			drawpic_expanding(pos, "gfx/hud/sb_str", picsize, '1 1 1', sbar_alpha_fg, DRAWFLAG_ADDITIVE,
				bound(0, -dt / 0.5, 1));
		}
	}

	if(rm_oldhud)
	{
		pos_y += 22;
		numpos = pos - '40 -2 0';
	}
	else
	{
		pos_x += 80;
		numpos = pos - '16 -10 0';
	}

	//invincibility
	if (invincibility_time) {
		dt = invincibility_time - time;
		if(dt > 0)
		{
			if(dt < 5)
			{
				drawpic_expanding_two(pos, "gfx/hud/sb_invinc", picsize, '1 1 1', sbar_alpha_fg, DRAWFLAG_ADDITIVE,
					bound(0, (ceil(dt) - dt) / 0.5, 1));
			}
			else
			{
				drawpic(pos, "gfx/hud/sb_invinc", picsize, '1 1 1', sbar_alpha_fg, DRAWFLAG_ADDITIVE);
			}
			Sbar_DrawXNum(numpos, ceil(dt), 2, 0, countdown_fontsize, '1 1 1', 0, 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
			pwhud_enabled = TRUE;
		}
		else if(dt > -1)
		{
			drawpic_expanding(pos, "gfx/hud/sb_invinc", picsize, '1 1 1', sbar_alpha_fg, DRAWFLAG_ADDITIVE,
				bound(0, -dt / 0.5, 1));
		}
	}
}

#define CENTERPRINT_MAX_LINES 30
string centerprint_messages[CENTERPRINT_MAX_LINES];
float centerprint_width[CENTERPRINT_MAX_LINES];
float centerprint_expires[CENTERPRINT_MAX_LINES];
vector centerprint_start;
float centerprint_expire;
float centerprint_num;
float centerprint_offset_hint;
vector centerprint_fontsize;

#define CENTERPRINT_MAX_MSGS 4
string centerprint_msgs[CENTERPRINT_MAX_MSGS];
float centerprint_msgexpires[CENTERPRINT_MAX_MSGS];
float centerprint_msgnum;

void centerprint(string strRealMessage)
{
	if(!centerprint_init)
	{
		centerprint_init = 1;
		return;
	}

	float i, j, n, hcount, k, k2, exptime;
	string s, strMessage;
	float scrtime = cvar("scr_centertime");

	centerprint_fontsize = Sbar_GetFontsize("scr_centersize");

	centerprint_expire = min(centerprint_expire, time); // if any of the returns happens, this message will fade out

	if(scrtime <= 0)
		return;

	if(strRealMessage == "")
		return;

	if(substring(strRealMessage, 0, 2) == "\x01\x02") //Damage indicator
	{
		if(!rm_showdamage)
			return;

		strRealMessage = substring(strRealMessage, 2, strlen(strRealMessage) - 2);
	} else if(substring(strRealMessage, 0, 1) == "\x01") {	// player name spam
		if(rm_shownames)
			return;
		
		strRealMessage = substring(strRealMessage, 1, strlen(strRealMessage));
		
		for(i = 0; i < centerprint_msgnum; ++i)
			if(centerprint_msgs[i])
				strunzone(centerprint_msgs[i]);
			
		centerprint_msgnum = 0;
	}
	
	if(centerprint_msgnum >= CENTERPRINT_MAX_MSGS)
	{

		for(k2 = 0; k2 < CENTERPRINT_MAX_MSGS-1; ++k2)
		{
			if(centerprint_msgs[k2]) strunzone(centerprint_msgs[k2]);
			centerprint_msgs[k2] = strzone(centerprint_msgs[k2+1]);
			centerprint_msgexpires[k2] = centerprint_msgexpires[k2+1];
		}

		strunzone(centerprint_msgs[k2]);
		centerprint_msgnum--;
	}

	centerprint_msgs[centerprint_msgnum] = strzone(strRealMessage);
	centerprint_msgexpires[centerprint_msgnum] = time + scrtime;
	centerprint_msgnum++;

	i = hcount = 0;

	for(k = centerprint_msgnum - 1; k != -1; --k)
	{
		strMessage = centerprint_msgs[k];
		exptime = centerprint_msgexpires[k];

		if(exptime <= time)
			continue;

		// strip trailing newlines
		j = strlen(strMessage) - 1;
		while(substring(strMessage, j, 1) == "\n" && j >= 0)
			j = j - 1;
		strMessage = substring(strMessage, 0, j + 1);

		// strip leading newlines and remember them, they are a hint that the message should be lower on the screen
		j = 0;
		while(substring(strMessage, j, 1) == "\n" && j < strlen(strMessage))
			j = j + 1;
		strMessage = substring(strMessage, j, strlen(strMessage) - j);
		centerprint_offset_hint = j;

		if(strMessage == "")
			break;

		n = tokenizebyseparator(strMessage, "\n");

		for(j = 0; j < n; ++j)
		{
:forloop
			getWrappedLine_remaining = argv(j);
			while(getWrappedLine_remaining)
			{
				s = getWrappedLine(vid_conwidth * 0.75 / centerprint_fontsize_x, stringwidth_colors);
				if(centerprint_messages[i])
						strunzone(centerprint_messages[i]);

				centerprint_messages[i] = strzone(s);
				centerprint_expires[i] = exptime; //((k == centerprint_msgnum - 1)? exptime : exptime - scrtime/2);
				centerprint_width[i] = stringwidth(s, TRUE);
				++i;

				// half height for empty lines looks better
				if(s == "")
					hcount += 0.5;
				else
					hcount += 1;

				if(i >= CENTERPRINT_MAX_LINES)
					break;
			}
		}
	}

	float h, havail;
	h = centerprint_fontsize_y*hcount;

	havail = vid_conheight;
	if(cvar("con_chatpos") < 0)
		havail -= (-cvar("con_chatpos") + cvar("con_chat")) * cvar("con_chatsize"); // avoid overlapping chat
	if(havail > vid_conheight - 70)
		havail = vid_conheight - 70; // avoid overlapping HUD

	centerprint_start_x = 0;

#if 0
	float forbiddenmin, forbiddenmax, allowedmin, allowedmax, preferred;

	// here, the centerprint would cover the crosshair. REALLY BAD.
	forbiddenmin = vid_conheight * 0.5 - h - 16;
	forbiddenmax = vid_conheight * 0.5 + 16;

	allowedmin = scoreboard_bottom;
	allowedmax = havail - h;
	preferred = (havail - h)/2;


	// possible orderings (total: 4! / 4 = 6)
	//  allowedmin allowedmax forbiddenmin forbiddenmax
	//  forbiddenmin forbiddenmax allowedmin allowedmax
	if(allowedmax < forbiddenmin || allowedmin > forbiddenmax)
	{
		// forbidden doesn't matter in this case
		centerprint_start_y = bound(allowedmin, preferred, allowedmax);
	}
	//  allowedmin forbiddenmin allowedmax forbiddenmax
	else if(allowedmin < forbiddenmin && allowedmax < forbiddenmax)
	{
		centerprint_start_y = bound(allowedmin, preferred, forbiddenmin);
	}
	//  allowedmin forbiddenmin forbiddenmax allowedmax
	else if(allowedmin < forbiddenmin)
	{
		// make sure the forbidden zone is not covered
		if(preferred > (forbiddenmin + forbiddenmax) * 0.5)
			centerprint_start_y = bound(allowedmin, preferred, forbiddenmin);
		else
			centerprint_start_y = bound(forbiddenmax, preferred, allowedmin);
	}
	//  forbiddenmin allowedmin allowedmax forbiddenmax
	else if(allowedmax < forbiddenmax)
	{
		// it's better to leave the allowed zone (overlap with scoreboard) than
		// to cover the forbidden zone (crosshair)
		if(preferred > (forbiddenmin + forbiddenmax) * 0.5)
			centerprint_start_y = forbiddenmax;
		else
			centerprint_start_y = forbiddenmin;
	}
	//  forbiddenmin allowedmin forbiddenmax allowedmax
	else
	{
		centerprint_start_y = bound(forbiddenmax, preferred, allowedmax);
	}
#else

	//Yeah whatever!
	/*centerprint_start_y =
		min(
			max(
				max(scoreboard_bottom, vid_conheight * 0.5 + 16),
				(havail - h)/2
			),
			havail - h + vid_conheight
		);

	centerprint_start_y += 2 * cvar("scr_centersize");*/

	centerprint_start_y = vid_conheight * 0.5 + vid_conheight/4;
#endif

	if(i < CENTERPRINT_MAX_LINES)
		centerprint_num = i;
}

void Sbar_DrawCenterPrint (void)
{
	float i;
	vector pos;
	string ts;
	float a;
	float exptime;

	pos = centerprint_start;

	if(is_tmpmadoka)
		return;

	if(vote_active)
	if(!rm_legacyvote)
	if(!vote_highlighted)
	if(!oldengine)
		return;

	for (i = 0; i<centerprint_num; i = i + 1)
	{
		exptime = centerprint_expires[i];
		a = bound(0, 1 - 4 * (time - exptime), 1);

		if(a <= 0)
			continue;

		pos_x = (vid_conwidth - centerprint_fontsize_x * centerprint_width[i] * (rm_simpleeffects? 1 : a)) * 0.5;
		ts = centerprint_messages[i];

		if (ts != "")
		{
			dummyfunction(0, 0, 0, 0, 0, 0, 0, 0); // work around DP bug (set OFS_PARAM5 to 0)
			if(rm_simpleeffects)
				drawcolorcodedstring(pos, ts, centerprint_fontsize, a, DRAWFLAG_NORMAL);
			else {
				vector sz = centerprint_fontsize * a;
				float postedat = exptime - cvar("scr_centertime");
				float a2 = 1 - bound(0, 3 * (time - postedat), 1);
				
				float oldy = pos_y;
				pos_y += 3 * (centerprint_fontsize_y * ipol_swingInOut(1 - a2) - centerprint_fontsize_y);
				drawcolorcodedstring(pos, ts, sz, a * ipol_pow2In(1 - a2), DRAWFLAG_NORMAL);
				
				float a3 = 1 + ipol_pow2In(1.0 - a2); 
				sz = sz * a3;
				pos_x = (vid_conwidth - centerprint_fontsize_x * centerprint_width[i] * (a3)) * 0.5;
				drawcolorcodedstring(pos - centerprint_fontsize_y * '0 0.5 0' * (a3 - 1), ts, sz, a * a2, DRAWFLAG_NORMAL);
				pos_y = oldy;
			}
			//  - '0 0.5 0' * (sz - 1) * centerprint_fontsize_x - '0.5 0 0' * (sz - 1) * centerprint_width[i] * centerprint_fontsize_y, centerprint_fontsize * sz
			pos_y = pos_y + centerprint_fontsize_y * (rm_simpleeffects? 1 : a);
		}
		else
			// half height for empty lines looks better
			pos_y = pos_y + centerprint_fontsize_y * 0.5;
	}
}

vector Sbar_DrawNoteLine(vector offset, string s)
{
	dummyfunction(0, 0, 0, 0, 0, 0, 0, 0); // work around DP bug (set OFS_PARAM5 to 0)
	drawcolorcodedstring(
		offset - sbar_fontsize_x * '1 0 0' * stringwidth(s, TRUE),
		s,
		sbar_fontsize,
		sbar_alpha_fg,
		0
	);
	return offset + sbar_fontsize_y * '0 1 0';
}

vector Sbar_DrawNoteLineA(vector offset, string s, float alpha)
{
	dummyfunction(0, 0, 0, 0, 0, 0, 0, 0); // work around DP bug (set OFS_PARAM5 to 0)
	drawcolorcodedstring(
		offset - sbar_fontsize_x * '1 0 0' * stringwidth(s, TRUE),
		s,
		sbar_fontsize,
		alpha,
		0
	);
	return offset + sbar_fontsize_y * '0 1 0';
}

vector Sbar_DrawCenterNoteLine(vector offset, string s)
{
	dummyfunction(0, 0, 0, 0, 0, 0, 0, 0); // work around DP bug (set OFS_PARAM5 to 0)
	drawcolorcodedstring(
		offset - sbar_fontsize_x * '1 0 0' * (stringwidth(s, TRUE) * 0.5),
		s,
		sbar_fontsize,
		sbar_alpha_fg,
		0
	);
	return offset + sbar_fontsize_y * '0 1 0';
}

vector Sbar_DrawCenterNoteLineA(vector offset, string s, float alpha)
{
	dummyfunction(0, 0, 0, 0, 0, 0, 0, 0); // work around DP bug (set OFS_PARAM5 to 0)
	drawcolorcodedstring(
		offset - sbar_fontsize_x * 1.5 * '1 0 0' * (stringwidth(s, TRUE) * 0.5),
		s,
		sbar_fontsize * 1.5,
		alpha,
		0
	);
	return offset + sbar_fontsize_y * 1.5 * '0 1 0';
}

void Sbar_DrawPressedKeys(void)
{
	vector pos, bgsize;
	float pressedkeys;

	pos = stov(cvar_string("cl_showpressedkeys_position"));

	bgsize = '126 75 0';

	pos = '1 0 0' * (vid_conwidth - bgsize_x) * pos_x
	    + '0 1 0' * (vid_conheight - bgsize_y) * pos_y;
	pos -= '-15 -6 0'; // adjust to the origin of these numbers

	pressedkeys = getstatf(STAT_PRESSED_KEYS);
	drawpic(pos + '-15   -6   0', "gfx/hud/keys/key_bg.tga",           bgsize, '1 1 1', 0.1 * sbar_alpha_fg, DRAWFLAG_NORMAL);
	drawpic(pos + ' 83.5  9   0', ((pressedkeys & KEY_CROUCH) ? "gfx/hud/keys/key_crouch_inv.tga" : "gfx/hud/keys/key_crouch.tga"), ' 24 24 0', '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
	drawpic(pos + ' 32   -1.5 0', ((pressedkeys & KEY_FORWARD) ? "gfx/hud/keys/key_forward_inv.tga" : "gfx/hud/keys/key_forward.tga"),  ' 32 32 0', '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
	drawpic(pos + '-11.5  9   0', ((pressedkeys & KEY_JUMP) ? "gfx/hud/keys/key_jump_inv.tga" : "gfx/hud/keys/key_jump.tga"),     ' 24 24 0', '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
	drawpic(pos + ' -1   32   0', ((pressedkeys & KEY_LEFT) ? "gfx/hud/keys/key_left_inv.tga" : "gfx/hud/keys/key_left.tga"),     ' 32 32 0', '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
	drawpic(pos + ' 32   32   0', ((pressedkeys & KEY_BACKWARD) ? "gfx/hud/keys/key_backward_inv.tga" : "gfx/hud/keys/key_backward.tga"), ' 32 32 0', '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
	drawpic(pos + ' 65   32   0', ((pressedkeys & KEY_RIGHT) ? "gfx/hud/keys/key_right_inv.tga" : "gfx/hud/keys/key_right.tga"),    ' 32 32 0', '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
}

void Sbar_ShowSpeed(void)
{
	vector numsize;
	float pos, conversion_factor;
	string speed, unit;

	switch(cvar("cl_showspeed_unit"))
	{
		default:
		case 0:
			unit = "";
			conversion_factor = 1.0;
			break;
		case 1:
			unit = " qu/s";
			conversion_factor = 1.0;
			break;
		case 2:
			unit = " m/s";
			conversion_factor = 0.0254;
			break;
		case 3:
			unit = " km/h";
			conversion_factor = 0.0254 * 3.6;
			break;
		case 4:
			unit = " mph";
			conversion_factor = 0.0254 * 3.6 * 0.6213711922;
			break;
		case 5:
			unit = " knots";
			conversion_factor = 0.0254 * 1.943844492; // 1 m/s = 1.943844492 knots, because 1 knot = 1.852 km/h
			break;
	}

	if (cvar("cl_showspeed_z") == 1)
		speed = strcat(ftos(floor( vlen(pmove_vel) * conversion_factor + 0.5 )), unit);
	else
		speed = strcat(ftos(floor( vlen(pmove_vel - pmove_vel_z * '0 0 1') * conversion_factor + 0.5 )), unit);

	numsize_x = numsize_y = cvar("cl_showspeed_size");
	pos = (vid_conheight - numsize_y) * cvar("cl_showspeed_position");

	drawfont = sbar_bigfont;
	drawstringcenter('1 0 0' + pos * '0 1 0', speed, numsize, '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
	drawfont = sbar_font;
}

vector acc_prevspeed;
float acc_prevtime;
float acc_avg;

void Sbar_ShowAcceleration(void)
{
	float acceleration, sz, scale, alpha, f;
	vector pos, top, rgb;
	top_x = vid_conwidth/2;
	top_y = 0;

	f = time - acc_prevtime;
	if(cvar("cl_showacceleration_z"))
		acceleration = (vlen(pmove_vel) - vlen(acc_prevspeed)) * (1 / f);
	else
		acceleration = (vlen(pmove_vel - '0 0 1' * pmove_vel_z) - vlen(acc_prevspeed - '0 0 1' * acc_prevspeed_z)) * (1 / f);
	acc_prevspeed = pmove_vel;
	acc_prevtime = time;

	f = bound(0, f * 10, 1);
	acc_avg = acc_avg * (1 - f) + acceleration * f;
	acceleration = acc_avg / getstatf(STAT_MOVEVARS_MAXSPEED);

	pos = top - sz/2 * '0 1 0' + (cvar("cl_showacceleration_position") * vid_conheight) * '0 1 0';

	sz = cvar("cl_showacceleration_size");
	scale = cvar("cl_showacceleration_scale");
	alpha = cvar("cl_showacceleration_alpha");
	if (cvar("cl_showacceleration_color_custom"))
		rgb = stov(cvar_string("cl_showacceleration_color"));
	else {
		rgb = '1 1 1';
		if (acceleration < 0) {
			rgb = '1 .5 .5' - '0 .5 .5' * bound(0, -acceleration * 0.2, 1);
		} else if (acceleration > 0) {
			rgb = '.5 1 .5' - '.5 0 .5' * bound(0, +acceleration * 0.2, 1);
		}
	}

	if (acceleration > 0)
		drawpic(pos, "gfx/hud/accelerometer_gradient", acceleration * scale * '40 0 0' + sz * '0 1 0', rgb, alpha * sbar_alpha_fg, DRAWFLAG_NORMAL);
	else if (acceleration < 0)
		drawpic(pos + acceleration * scale * '40 0 0', "gfx/hud/accelerometer_gradient", -acceleration * scale * '40 0 0' + sz * '0 1 0', rgb, alpha * sbar_alpha_fg, DRAWFLAG_NORMAL);
}

vector Sbar_DamageStats_Color(float i) {
    vector clr;
    float darken = floor(i / 8) * 0.2;
    i = mod(i, 8);
    
    switch(i) {
        case 0:     clr = '1.0   0.0   0.0'; break;
        case 1:     clr = '0.0   1.0   0.0'; break;
        case 2:     clr = '0.0   0.0   1.0'; break;
        case 3:     clr = '1.0   1.0   0.0'; break;
        case 4:     clr = '0.0   1.0   1.0'; break;
        case 5:     clr = '1.0   0.0   1.0'; break;
        case 6:     clr = '1.0   0.5   0.0'; break;
        case 7:     clr = '0.0   1.0   0.5'; break;
    }
    
    return clr * (1 - darken);
}

.float cnt;
vector Sbar_DrawDamageStats(entity k, string head, vector pos, vector sz) {
    string str;
    vector tsize = sbar_fontsize * 1.5;
    vector o, e;
    float i, l, a = 1;
    float header = (tsize_y + sbar_fontsize_y * 0.5);
    vector opos = pos;
    
    sz_y = header + min(floor((sz_y - header) / sbar_fontsize_y) * sbar_fontsize_y, 
                                                           k.cnt * sbar_fontsize_y);
    
    drawfill(pos, sz, '0 0 0', 0.5 * sbar_alpha_bg, DRAWFLAG_NORMAL);
    drawborderlines(2, pos, sz, '0 0 0', sbar_alpha_bg, DRAWFLAG_NORMAL);
    drawborderlines(2, pos, '1 0 0' * sz_x + '0 1 0' * (header - 2), '0 0 0', sbar_alpha_bg, DRAWFLAG_NORMAL);
    
    o   = '0 1 0' * header;
    pos = pos + o;
    sz  = sz - o;
    
    tsize = sbar_fontsize;
    
    k.cnt = 0;
    FOR_DTRACK_ENTRIES(k, i) {
        k.cnt += 1;
        l = sz_x * (k.(dtrack_damage[i]) / k.dtrack_totaldamage);
        
        if(l > 0) {
            drawfill(opos + e, '0 1 0' * (header - 2) + '1 0 0' * l, Sbar_DamageStats_Color(i), 0.3, DRAWFLAG_NORMAL);
            e += l * '1 0 0';
        }
        
        if(sz_y < tsize_y)
            continue;
        
        a = max(0.2, a - 0.025);
        drawfill(pos, '0 1 0' * tsize_y + '1 0 0' * sz_x * (k.(dtrack_damage[i]) / k.dtrack_highestdamage), Sbar_DamageStats_Color(i), 0.3, DRAWFLAG_NORMAL);
            
        str = ftos((k.(dtrack_damage[i]) / k.dtrack_totaldamage) * 100);
        l = strstrofs(str, ".", 0);
        if(l >= 0)
            str = substring(str, 0, l + 2);
        str = strcat(", ", str, "%");
        l = stringwidth_svn(str, FALSE, tsize);
        drawstring(pos + '1 0 0' * (sz_x - l), str, tsize, '1 1 1', sbar_alpha_fg * a, DRAWFLAG_NORMAL);
        
        str = FormatDamage(k.(dtrack_damage[i]));
        l += stringwidth_svn(str, FALSE, tsize);
        drawstring(pos + '1 0 0' * (sz_x - l), str, tsize, '1 1 0', sbar_alpha_fg * a, DRAWFLAG_NORMAL);
        
        str = strcat(ftos(i+1), ". ", DamageTracker_DamageSourceName(k.(dtrack_type[i]), TRUE));
        str = textShortenToWidth_svn(str, sz_x - l, tsize, stringwidth_colors_svn);
        drawstring(pos, str, tsize, '1 1 1', sbar_alpha_fg * a, DRAWFLAG_NORMAL);
        
        o   = '0 1 0' * tsize_y;
        pos = pos + o;
        sz  = sz - o;
    }
    
    tsize = sbar_fontsize * 1.5;
    opos_y += header * 0.5 - tsize_y * 0.55;
    drawfont = sbar_bigfont;
    drawstring(opos + tsize_x * '0.25 0 0', head, tsize, '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
    str = FormatDamage(k.dtrack_totaldamage);
    drawstring(opos - (tsize_x * 0.25 + stringwidth_svn(str, FALSE, tsize) - sz_x) * '1 0 0', str, tsize, '1 1 0', sbar_alpha_fg, DRAWFLAG_NORMAL);
    drawfont = sbar_font;
    
    return pos;
}

void Sbar_DrawAccuracyStats_Description_Hitscan(vector position)
{
	drawstring(position + '0 3 0' * sbar_fontsize_y, "Shots fired:", sbar_fontsize, '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
	drawstring(position + '0 5 0' * sbar_fontsize_y, "Shots hit:", sbar_fontsize, '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
	drawstring(position + '0 7 0' * sbar_fontsize_y, "Accuracy:", sbar_fontsize, '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
	drawstring(position + '0 9 0' * sbar_fontsize_y, "Shots missed:", sbar_fontsize, '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
}

void Sbar_DrawAccuracyStats_Description_Splash(vector position)
{
	drawstring(position + '0 3 0' * sbar_fontsize_y, "Maximum damage:", sbar_fontsize, '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
	drawstring(position + '0 5 0' * sbar_fontsize_y, "Actual damage:", sbar_fontsize, '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
	drawstring(position + '0 7 0' * sbar_fontsize_y, "Accuracy:", sbar_fontsize, '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
	drawstring(position + '0 9 0' * sbar_fontsize_y, "Damage wasted:", sbar_fontsize, '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
}

void Sbar_DrawAccuracyStats()
{
	float i, count_hitscan, count_splash, row;  // count is the number of 'colums'
	float weapon_hit, weapon_damage, weapon_stats;
	float left_border;  // position where the weapons start, the description is in the border
	vector fill_colour, fill_size;
	vector pos;

	float col_margin = 20;  // pixels between the columns
	float row_margin = 20;  // pixels between the rows

	fill_size_x = 5 * sbar_fontsize_x;  // width of the background
	fill_size_y = 10 * sbar_fontsize_y;  // height of the background
    
	drawfont = sbar_bigfont;
	pos_x = 0;
	pos_y = SCOREBOARD_OFFSET;
	pos_z = 0;
	drawstringcenter(pos, "Weapon Accuracy", 2 * sbar_fontsize, '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);

	left_border = col_margin + 11 * sbar_fontsize_x;

	drawfont = sbar_font;

	if(warmup_stage)
	{
		pos_y += 40;
		if(mod(time, 1) >= 0.4)
			drawstringcenter(pos, "Stats are not tracked during warmup stage", sbar_fontsize, '1 1 0', sbar_alpha_fg, DRAWFLAG_NORMAL);

		return;
	}
    
	float top_border_hitscan = SCOREBOARD_OFFSET + 55;  // position where the hitscan row starts: pixels down the screen
	Sbar_DrawAccuracyStats_Description_Hitscan('1 0 0' * col_margin + '0 1 0' * top_border_hitscan);

	float top_border_splash = SCOREBOARD_OFFSET + 175;  // position where the splash row starts: pixels down the screen
	Sbar_DrawAccuracyStats_Description_Splash('1 0 0' * col_margin + '0 1 0' * top_border_splash);

    if(sv_damagestats) {
        //vector dsize = '0.2 0 0' * vid_conwidth + '0 0.3 0' * vid_conheight;
        vector dsize = '0.25 0 0' * vid_conwidth + '0 0.25 0' * vid_conheight;
        vector dpos = '1 0 0' * (vid_conwidth - dsize_x - 10) + '0 1 0' * top_border_hitscan;
        dpos = Sbar_DrawDamageStats(((spectatee_status > 0)? dtrack_total_spec : dtrack_total), "Damage done", dpos, dsize) + '0 1 0' * sbar_fontsize_y;
        Sbar_DrawDamageStats(((spectatee_status > 0)? dtrack_taken_spec : dtrack_taken), "Damage taken", dpos, dsize);
    }
    
	for(i = WEP_FIRST; i <= WEP_LAST; ++i)
	{
		weapon_hit = weapon_hits[i];
		weapon_damage = weapon_fired[i];
		self = get_weaponinfo(i);

		//if ((weapon_number != 42))  // print them all :)
		if (weapon_damage) {
			if (self.weapon_type == WEP_TYPE_SPLASH) {
				weapon_stats = bound(0, rint(100 * weapon_hit / weapon_damage), 100);

				fill_colour_x = 1 - 0.015 * weapon_stats;
				fill_colour_y = 1 - 0.015 * (100 - weapon_stats);

				// how the background colour is calculated
				// %	red		green	red_2			green_2
				// 0	1		0		1 - % * 0.015	1 - (100 - %) * 0.015
				// 10	0.85	0		1 - % * 0.015	1 - (100 - %) * 0.015
				// 20	0.70	0		1 - % * 0.015	1 - (100 - %) * 0.015
				// 30	0.55	0		1 - % * 0.015	1 - (100 - %) * 0.015
				// 40	0.40	0.10	1 - % * 0.015	1 - (100 - %) * 0.015
				// 50	0.25	0.25	1 - % * 0.015	1 - (100 - %) * 0.015
				// 60	0.10	0.40	1 - % * 0.015	1 - (100 - %) * 0.015
				// 70	0		0.55	1 - % * 0.015	1 - (100 - %) * 0.015
				// 80	0		0.70	1 - % * 0.015	1 - (100 - %) * 0.015
				// 90	0		0.85	1 - % * 0.015	1 - (100 - %) * 0.015
				// 100	0		1		1 - % * 0.015	1 - (100 - %) * 0.015

				if ((left_border + count_splash * (fill_size_x + col_margin) + fill_size_x) >= vid_conwidth)
				{
					count_splash = 0;
					++row;
					Sbar_DrawAccuracyStats_Description_Splash('1 0 0' * col_margin + '0 1 0' * (top_border_splash + row * (fill_size_y + row_margin)));
				}

				pos_x = left_border + count_splash * (fill_size_x + col_margin);
				pos_y = top_border_splash + row * (fill_size_y + row_margin);

				// background
				drawpic(pos, "gfx/hud/sb_accuracy", fill_size , fill_colour, sbar_alpha_bg, DRAWFLAG_NORMAL);
				drawborderlines(sbar_border_thickness, pos, fill_size, '0 0 0', sbar_alpha_bg, DRAWFLAG_NORMAL);

				// the weapon
				drawpic(pos, strcat("gfx/hud/inv_weapon", ftos(i-1)), '1 0.5 0' * fill_size_x , '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);

				// the amount of shots fired or max damage
				drawstringright(pos + '4.5 0 0' * sbar_fontsize_x + '0 3 0' * sbar_fontsize_y, ftos(weapon_damage), sbar_fontsize, '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);

				// the amount of hits or actual damage
				drawstringright(pos + '4.5 0 0' * sbar_fontsize_x + '0 5 0' * sbar_fontsize_y, ftos(weapon_hit), sbar_fontsize, '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);

				// the accuracy
				drawstringright(pos + '4.5 0 0' * sbar_fontsize_x + '0 7 0' * sbar_fontsize_y, strcat(ftos(weapon_stats),"%"), sbar_fontsize, '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);

				// the amount of shots missed or damage wasted
				drawstringright(pos + '4.5 0 0' * sbar_fontsize_x + '0 9 0' * sbar_fontsize_y, ftos(max(0, weapon_damage - weapon_hit)), sbar_fontsize, '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);

				++count_splash;
			} else if ((self.weapon_type == WEP_TYPE_HITSCAN) && (weapon_damage)) {
				weapon_stats = bound(0, rint(100 * weapon_hit / weapon_damage), 100);

				fill_colour_x = 1 - 0.015 * weapon_stats;
				fill_colour_y = 1 - 0.015 * (100 - weapon_stats);

				// how the background colour is calculated
				// %	red		green	red_2			green_2
				// 0	1		0		1 - % * 0.015	1 - (100 - %) * 0.015
				// 10	0.850	0		1 - % * 0.015	1 - (100 - %) * 0.015
				// 20	0.70	0		1 - % * 0.015	1 - (100 - %) * 0.015
				// 30	0.55	0		1 - % * 0.015	1 - (100 - %) * 0.015
				// 40	0.40	0.10	1 - % * 0.015	1 - (100 - %) * 0.015
				// 50	0.25	0.25	1 - % * 0.015	1 - (100 - %) * 0.015
				// 60	0.10	0.40	1 - % * 0.015	1 - (100 - %) * 0.015
				// 70	0		0.55	1 - % * 0.015	1 - (100 - %) * 0.015
				// 80	0		0.70	1 - % * 0.015	1 - (100 - %) * 0.015
				// 90	0		0.85	1 - % * 0.015	1 - (100 - %) * 0.015
				// 100	0		1		1 - % * 0.015	1 - (100 - %) * 0.015

				if ((left_border + count_hitscan * (fill_size_x + col_margin) + fill_size_x + cvar("stats_right_margin")) >= vid_conwidth)
				{
					count_hitscan = 0;
					++row;
					Sbar_DrawAccuracyStats_Description_Hitscan('1 0 0' * col_margin + '0 1 0' * (top_border_hitscan + row * (fill_size_y + row_margin)));
				}

				pos_x = left_border + count_hitscan * (fill_size_x + col_margin);
				pos_y = top_border_hitscan + row * (fill_size_y + row_margin);

				// background
				drawpic(pos, "gfx/hud/sb_accuracy", fill_size , fill_colour, sbar_alpha_bg, DRAWFLAG_NORMAL);
				drawborderlines(sbar_border_thickness, pos, fill_size, '0 0 0', sbar_alpha_bg, DRAWFLAG_NORMAL);

				// the weapon
				drawpic(pos, strcat("gfx/hud/inv_weapon", ftos(i-1)), '1 0.5 0' * fill_size_x , '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);

				// the amount of shots fired or max damage
				drawstringright(pos + '4.5 0 0' * sbar_fontsize_x + '0 3 0' * sbar_fontsize_y, ftos(weapon_damage), sbar_fontsize, '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);

				// the amount of hits or actual damage
				drawstringright(pos + '4.5 0 0' * sbar_fontsize_x + '0 5 0' * sbar_fontsize_y, ftos(weapon_hit), sbar_fontsize, '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);

				// the accuracy
				drawstringright(pos + '4.5 0 0' * sbar_fontsize_x + '0 7 0' * sbar_fontsize_y, strcat(ftos(weapon_stats),"%"), sbar_fontsize, '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);

				// the amount of shots missed or damage wasted
				drawstringright(pos + '4.5 0 0' * sbar_fontsize_x + '0 9 0' * sbar_fontsize_y, ftos(max(0, weapon_damage - weapon_hit)), sbar_fontsize, '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);

				++count_hitscan;
			}
		}
	}
}

void drawstringright(vector position, string text, vector scale, vector rgb, float alpha, float flag)
{
	position_x -= 2 / 3 * strlen(text) * scale_x;
	drawstring(position, text, scale, rgb, alpha, flag);
}

void drawstringcenter(vector position, string text, vector scale, vector rgb, float alpha, float flag)
{
	//position_x = 0.5 * (vid_conwidth - 0.6025 * strlen(text) * scale_x);
	
	position_x = 0.5 * (vid_conwidth - stringwidth(text, FALSE) * scale_x);
	drawstring(position, text, scale, rgb, alpha, flag);
}

void drawcolorcodedstringcenter(vector position, string text, vector scale, float alpha, float flag)
{
	//position_x = 0.5 * (vid_conwidth - 0.6025 * strlennocol(text) * scale_x);
	
	position_x = 0.5 * (vid_conwidth - stringwidth(text, TRUE) * scale_x);
	drawcolorcodedstring(position, text, scale, alpha, flag);
}

void drawstringcenter_offset(vector position, string text, vector scale, vector rgb, float alpha, float flag, float offs)
{
	//position_x = 0.5 * (vid_conwidth - 0.6025 * strlen(text) * scale_x) - offs;
	
	position_x = 0.5 * (vid_conwidth - stringwidth(text, FALSE) * scale_x) - offs;
	drawstring(position, text, scale, rgb, alpha, flag);
}

void drawcolorcodedstringcenter_offset(vector position, string text, vector scale, float alpha, float flag, float offs)
{
	//position_x = 0.5 * (vid_conwidth - 0.6025 * strlennocol(text) * scale_x) - offs;
	
	position_x = 0.5 * (vid_conwidth - stringwidth(text, TRUE) * scale_x) - offs;
	drawcolorcodedstring(position, text, scale, alpha, flag);
}

float GetAmmoStat(float i)
{
	switch(i)
	{
		case 0: return STAT_SHELLS;
		case 1: return STAT_NAILS;
		case 2: return STAT_ROCKETS;
		case 3: return STAT_CELLS;
		case 4: return STAT_FUEL;
		default: return -1;
	}
}

float GetAmmoItemCode(float i)
{
	switch(i)
	{
		case 0: return IT_SHELLS;
		case 1: return IT_NAILS;
		case 2: return IT_ROCKETS;
		case 3: return IT_CELLS;
		case 4: return IT_FUEL;
		default: return -1;
	}
}

string GetAmmoPicture(float i)
{
	switch(i)
	{
		case 0: return "gfx/hud/sb_shells";
		case 1: return "gfx/hud/sb_bullets";
		case 2: return "gfx/hud/sb_rocket";
		case 3: return "gfx/hud/sb_cells";
		case 4: return "gfx/hud/sb_fuel";
		default: return "";
	}
}

void Sbar_Reset (void)
{
	// reset gametype specific icons
	if(gametype == GAME_KEYHUNT)
		CSQC_kh_hudreset();
	else if(gametype == GAME_CTF)
		CSQC_ctf_hudreset();
}

void Sbar_MorningRescue(void)
{
	// vectors for top right, bottom right, bottom and bottom left corners

	vector topright;
	vector bottom;
	vector bottomright;
	vector bottomleft;

	topright_x = vid_conwidth;
	topright_y = 0;
	topright_z = 0;

	bottom_x = vid_conwidth/2;
	bottom_y = vid_conheight;
	bottom_z = 0;

	bottomright_x = vid_conwidth;
	bottomright_y = vid_conheight;
	bottomright_z = 0;

	bottomleft_x = 0;
	bottomleft_y = vid_conheight;
	bottomleft_z = 0;

	local vector mrpos;
	local float mralpha;
	mrpos = bottomleft;
	local vector offset;

	mralpha = 1 - bound(0, 1 - 2 * (time - mr_appeartime), 1);
	if(mralpha >= 1)
		mralpha = bound(0, 1 - 2 * (time - (mr_fadetime - 1)), 1);

	local vector mrcolor;
	mrcolor_x = 1;
	mrcolor_y = random();
	drawfill('0 0 0', bottomright, mrcolor, mralpha * random(), DRAWFLAG_ADDITIVE);

	mrpos_y -= 200 * mralpha;
	drawpic (mrpos, "gfx/morningrescue", '57 200 0', '1 1 1', mralpha, DRAWFLAG_NORMAL);

	mrpos = topright;
	mrpos_y -= 500 * 0.5 * (1 - mralpha);
	offset_y = 3 * cos(mrpos_y + 5 * time) - 5;
	mrpos_x -= 513 * 0.5;
	offset_x = 3 * cos(mrpos_x + 5 * time) + 5;
	drawpic (mrpos + offset, "gfx/morningrescue2", '513 500 0' * 0.5, '1 1 1', mralpha, DRAWFLAG_NORMAL);

	local string mycolor;
	local string mychar;
	local float j;
	local string mrstring = "^xFB0MMorning ^7Rescue";

	local float k;

	for(k = 0; k < 2; ++k)
	{
		drawfont = (k? sbar_madokafont : sbar_bigfont_real);
		mrpos_y = vid_conheight / 2 - 12;
		mrpos_x = 0.5 * (vid_conwidth - 0.6025 * strlennocol(mrstring) * 24);
		for(j = 0; j < strlen(mrstring); ++j)
		{
			mychar = substring(mrstring, j, 1);

			if(mychar == "^")
			{
				if(substring(mrstring, j+1, 1) == "x")
				{
					mycolor = substring(mrstring, j, 5);
					j += 5;
				}
				else
				{
					mycolor = substring(mrstring, j, 2);
					++j;
				}
				continue;
			}

			offset_y = 10 * ((k*10)+1) * cos(mrpos_x + 3 * time) * (mod(j, 2)? 1 : -1) * (k? 1 : -1);
			offset_x = offset_y * (mod(j, 2)? -1 : 1);
			local string resultstr = strcat(mycolor, mychar);

			dummyfunction(0, 0, 0, 0, 0, 0, 0, 0); // work around DP bug (set OFS_PARAM5 to 0)
			mrpos_x += stringwidth(resultstr, TRUE) * 24;
			drawcolorcodedstring(mrpos + offset, resultstr, '24 24 0', mralpha * 0.8, DRAWFLAG_ADDITIVE);
		}
	}
}

float movealpha;

void Sbar_ServerInfo() {
	if(spectatee_status != -1)
		return;
	
	if(pmove_vel_x || pmove_vel_y || pmove_vel_z)
		movealpha = approach(movealpha, 1, 3 * drawframetime);
	else
		movealpha = approach(movealpha, 0, 3 * drawframetime);
	
	vector pos = '0 0.6 0' * vid_conheight;
	float a = 0.5 * (1 - sbar_scoreboard_fade_alpha - movealpha);
	
	if(a <= 0)
		return;
	
	vector sz_big  = sbar_fontsize_spec * a * 2;
	vector sz_norm = sbar_fontsize * a * 2;
	
	drawfont = sbar_bigfont;
	drawcolorcodedstringcenter(pos, sv_hostname, sz_big, a, DRAWFLAG_NORMAL);
	pos_y += sz_big_y + sz_norm_y * 0.5;
	drawfont = sbar_font;
	
	drawstringcenter(pos, strcat(sv_rm_build, " (", sv_rm_version, ", ", sv_rm_commit, ")"), sz_norm, '1 0.6 0', a, DRAWFLAG_NORMAL);
	pos_y += sz_norm_y;
	drawstringcenter(pos, sv_rm_date, sz_norm, '1 1 1', a, DRAWFLAG_NORMAL);
	pos_y += sz_norm_y * 1.5;
	drawcolorcodedstringcenter(pos, strcat("Playing ^5", gametype_ID_to_LongName(gametype), " ^7on ^2", shortmapname), sz_norm, a, DRAWFLAG_NORMAL);
	
	if(sv_motd == "")
		return;
	
	pos_y += sz_big_y * 1.5;
	drawfont = sbar_bigfont;
	drawcolorcodedstringcenter(pos, "Message of The Day", sz_big, a, DRAWFLAG_NORMAL);
	pos_y += sz_big_y + sz_norm_y * 0.5;
	drawfont = sbar_font;
	
	float n = tokenizebyseparator(sv_motd, "\n");
	float i;
	
	for(i = 0; i < n; ++i) {
		drawcolorcodedstringcenter(pos, argv(i), sz_norm, a, DRAWFLAG_NORMAL);
		pos_y += sz_norm_y;
	}
	
	drawfont = sbar_font;
}

float vote_active; // is there an active vote?

float vote_prev; // previous state of vote_active to check for a change
float vote_alpha;
float vote_change; // "time" when vote_active changed


string vote_statstring;

float revalpha;
float revfadetime;
float revsaved;

vector hudflash_resultcolor;
float hudflash_resultalpha;

float teamhud_enabled;

void HudFlash_Apply(vector basecolor, float basealpha, float additive, float imod, float amod)
{
	local float a, i;
	local vector c;

	imod *= hudskin_flash_intmod;
	amod *= hudskin_flash_alphamod;

	hudflash_resultalpha = basealpha;
	hudflash_resultcolor = basecolor;

	if(!hudflash_enabled)
		return;

	if(time < hudflash_appeartime)
		return;	//weird

	if(time < hudflash_fadetime)
		a = 1 - bound(0, 1 - 11 * (time - hudflash_appeartime), 1);
	else
		a = 1; // cause fade

	if(a >= 1)
		a = bound(0, 1 - 11 * (time - (hudflash_fadetime - 1)), 1);

	if(!a)
	{
		hudflash_enabled = FALSE;
		return;
	}

	i = hudflash_intensivity * a;
	i *= imod;

	a *= hudflash_alpha;
	a *= amod;
	a = min(a, 1.0);

	if(additive)
		c = basecolor + hudflash_color * i;
	else
	{
		c_x = max(basecolor_x * (1 - min(i, 1.0)), hudflash_color_x * i);
		c_y = max(basecolor_y * (1 - min(i, 1.0)), hudflash_color_y * i);
		c_z = max(basecolor_z * (1 - min(i, 1.0)), hudflash_color_z * i);
	}

	hudflash_resultalpha = max(basealpha, a);
	hudflash_resultcolor = c;
}

float th_state;
float th_finalstate;
float th_appeartime;
float th_fadetime;
float th_alpha;
float teamhud_wide;

float pw_state;
float pw_finalstate;
float pw_appeartime;
float pw_fadetime;
float pw_alpha;

float ammo_last;

#define HUDLINE_SLICE(code) code if(!hudskin_line_full || !linedrawn) { DrawHUDLineSlice(hudline_pos, hudline, slice_basecolor, slice_basealpha); linedrawn = 1; }
#define HUDLINE_SECTOR(code,bg,bbg,a,ba) code DrawHUDLineSector(hud_sector_pos, hud_sector + sector_mod, a*sector_alphamod, bg, hud_sector_drawflag); DrawHUDLineSectorBorder(hud_sector_pos, hud_sector + sector_mod, ba*sector_alphamod, bbg);
#define BG_SECTOR ((hudskin_sector_teamcolor == TC_ALWAYS)? sector_teamcolor : sector_basecolor)
#define BG_SECTOR_TEAM ((hudskin_sector_teamcolor != TC_NEVER)? sector_teamcolor : sector_basecolor)
#define BG_SECTOR_PROGRESS (hudskin_progress_sector_colormode? ((hudskin_progress_sector_colormode == 1)? sector_teamcolor + hudskin_progress_sector_teamcolor_mod : hudskin_progress_sector_color) : BG_SECTOR)
#define BG_BORDER ((hudskin_border_teamcolor == TC_ALWAYS)? border_teamcolor : border_basecolor)
#define BG_BORDER_TEAM ((hudskin_border_teamcolor != TC_NEVER)? border_teamcolor : border_basecolor)
#define BG_BORDER_PROGRESS (hudskin_progress_border_colormode? ((hudskin_progress_border_colormode == 1)? border_teamcolor + hudskin_progress_border_teamcolor_mod : hudskin_progress_border_color) : BG_BORDER)
#define A_SECTOR ((hudskin_sector_teamcolor == TC_ALWAYS)? sector_teamalpha : sector_basealpha)
#define A_SECTOR_TEAM ((hudskin_sector_teamcolor != TC_NEVER)? sector_teamalpha : sector_basealpha)
#define A_SECTOR_PROGRESS (hudskin_progress_sector_colormode? ((hudskin_progress_sector_colormode == 1)? max(A_SECTOR_TEAM, hudskin_progress_sector_teamcolor_minalpha) : hudskin_progress_sector_alpha) : A_SECTOR)
#define A_BORDER ((hudskin_border_teamcolor == TC_ALWAYS)? border_teamalpha : border_basealpha)
#define A_BORDER_TEAM ((hudskin_border_teamcolor != TC_NEVER)? border_teamalpha : border_basealpha)
#define A_BORDER_PROGRESS (hudskin_progress_border_colormode? ((hudskin_progress_border_colormode == 1)? max(A_BORDER_TEAM, hudskin_progress_border_teamcolor_minalpha) : hudskin_progress_border_alpha) : A_BORDER)

void DrawHUDLineSlice(vector slicepos, vector slicesize, vector slicecolor, float slicealpha)
{
	vector drawsize;
	float factor;
	
	slicepos_y  += hudskin_line_padding_x;
	slicesize_y -= hudskin_line_padding_x;
	slicesize_y -= hudskin_line_padding_y;
	
	switch(hudskin_line_fill)
	{
		case FILL_COLOR:
			drawfill(slicepos, slicesize, slicecolor, slicealpha, DRAWFLAG_NORMAL);
			return;
		
		case FILL_TILE:
			drawsize = slicesize;
			if(drawsize_y > hudskin_size_line_fill_y)
			{
				// autoscaling
				factor = hudskin_size_line_fill_y / drawsize_y;
				drawsize = drawsize * factor;
			}
			
			if(hudskin_image_line_fill)
				drawpic_tiled(slicepos, hudskin_image_line_fill, drawsize, slicesize, slicecolor, slicealpha, DRAWFLAG_NORMAL, '0 0 0');
			return;
		
		case FILL_STRETCH:
			if(hudskin_image_line_fill)
				drawpic_tiled(slicepos, hudskin_image_line_fill, slicesize, slicesize, slicecolor, slicealpha, DRAWFLAG_NORMAL, '0 0 0');
			return;
	}
}

vector sector_clip_pos;
vector sector_clip_size;

vector sector_border_left_pos;
vector sector_border_left_size;
vector sector_border_right_pos;
vector sector_border_right_size;

void GetSectorBorderValues(vector sectorpos, vector sectorsize) {
    vector pos_left, pos_right, size_left, size_right;
    float offset_right, offset_left;
    
    size_left = hudskin_size_border_left * hudskin_scale_border_left;
    offset_left = (sectorsize_y - size_left_y) / 2;
    pos_left = sectorpos;
    pos_left_y += offset_left;
    pos_left = pos_left + hudskin_offset_border_left;
    
    size_right = hudskin_size_border_right * hudskin_scale_border_right;
    offset_right = (sectorsize_y - size_right_y) / 2;
    pos_right = sectorpos + '1 0 0' * sectorsize_x;
    pos_right_x -= size_right_x;
    pos_right_y += offset_right;
    pos_right = pos_right + hudskin_offset_border_right;
    
    sector_border_left_pos   = pos_left;
    sector_border_left_size  = size_left;
    sector_border_right_pos  = pos_right;
    sector_border_right_size = size_right;
}

void GetSectorClipArea(vector sectorpos, vector sectorsize) {
    sector_clip_pos = sectorpos;
	sector_clip_size = sectorsize;
    
	sector_clip_pos_x += hudskin_sector_padding_left - 1;
	sector_clip_size_x -= hudskin_sector_padding_left - 1;
	sector_clip_size_x -= hudskin_sector_padding_right;
	sector_clip_pos_y += hudskin_sector_padding_top;
	sector_clip_size_y -= hudskin_sector_padding_top;
	sector_clip_size_y -= hudskin_sector_padding_bottom;
}

void GetSectorBorderClipArea(vector sectorpos, vector sectorsize) {
    sector_clip_pos = sectorpos;
	sector_clip_size = sectorsize;
    
    if(hudskin_border_simple) {
        sector_clip_pos_x  -= hudskin_border_simple;
        sector_clip_size_x += hudskin_border_simple*2;
        sector_clip_pos_y  -= hudskin_border_simple;
        sector_clip_size_y += hudskin_border_simple*2;
    } else {
        GetSectorBorderValues(sectorpos, sectorsize);
        
        float ol = sector_border_left_pos_y;
        float or = sector_border_right_pos_y;
        float al = ol + sector_border_left_size_y;
        float ar = or + sector_border_right_size_y;
        float h  = max(abs(ol - ar), abs(or - al));
        float hd = h - sector_clip_size_y;
        
        sector_clip_pos_x  = sector_border_left_pos_x - 1;
        sector_clip_size_x = sector_border_right_pos_x - sector_clip_pos_x + sector_border_right_size_x + 1;
        sector_clip_pos_y -= hd/2;
        sector_clip_size_y = h;
    }
}

void GetSectorFullClipArea(vector sectorpos, vector sectorsize) {
    vector p, s;
    vector p1, s1, p2, s2;
    
    GetSectorClipArea(sectorpos, sectorsize);
    p1 = sector_clip_pos; s1 = sector_clip_size;
    GetSectorBorderClipArea(sectorpos, sectorsize);
    p2 = sector_clip_pos; s2 = sector_clip_size;
    
    s = '1 0 0' * abs((min(p1_x, p2_x) - max(p1_x + s1_x, p2_x + s2_x))) +
        '0 1 0' * abs((min(p1_y, p2_y) - max(p1_y + s1_y, p2_y + s2_y)));
    
    p = '1 0 0' * min(p1_x, p2_x) + '0 1 0' * min(p1_y, p2_y);
    
    sector_clip_size = s;
    sector_clip_pos  = p;
}

void DrawHUDLineSectorBorder(vector sectorpos, vector sectorsize, float borderalpha, vector bordercolor) {
	if(hudskin_border_simple)
		drawborderlines(hudskin_border_simple, sectorpos, sectorsize, bordercolor, borderalpha, hudskin_border_drawflag);
	else
	{
        GetSectorBorderValues(sectorpos, sectorsize);
        
		if(hudskin_image_border_left)
			drawpic(sector_border_left_pos, hudskin_image_border_left, sector_border_left_size, bordercolor, borderalpha, hudskin_border_drawflag);
		
		if(hudskin_image_border_right)
			drawpic(sector_border_right_pos, hudskin_image_border_right, sector_border_right_size, bordercolor, borderalpha, hudskin_border_drawflag);
	}
}

void DrawDebug(vector p, vector s) {
    vector clr = '1 0 0' * (0.5 + 0.5 * sin(p_x * p_y + s_x * s_y)) +
                 '0 1 0' * (0.5 + 0.5 * cos(0.4*p_x * p_y + 0.7*s_x * s_y)) +
                 '0 0 1' * (0.5 + 0.5 * sin(0.6*p_x * p_y + 0.3*s_x * s_y));
    drawfill(p, s, clr, 0.1, DRAWFLAG_NORMAL);
}

void DrawHUDLineSector(vector sectorpos, vector sectorsize, float basealpha, vector sectorcolor, float drawflag)
{
	//sectorpos_x -= 2;
	//sectorsize_x += 4;
	
	vector fillsize, fillpos;
	fillpos = sectorpos;
	fillsize = sectorsize;
	fillpos_x += hudskin_sector_padding_left;
	fillsize_x -= hudskin_sector_padding_left;
	fillsize_x -= hudskin_sector_padding_right;
	fillpos_y += hudskin_sector_padding_top;
	fillsize_y -= hudskin_sector_padding_top;
	fillsize_y -= hudskin_sector_padding_bottom;
	
	local vector size_left, size_center, size_right;
	local float factor;
	switch(hudskin_sector_fill)
	{
		case FILL_COLOR:
			drawfill(fillpos, fillsize, sectorcolor, basealpha, DRAWFLAG_NORMAL);
			break;
		
		case FILL_TILE: case FILL_STRETCH:
			size_left = hudskin_size_sector_fill_left;
			size_right = hudskin_size_sector_fill_right;
			size_center = hudskin_size_sector_fill_center;
			
            if(hudskin_sector_fill == FILL_STRETCH)
            if(size_left == '0 0 0') if(size_right == '0 0 0') {
                drawpic(fillpos, hudskin_image_sector_fill_center, fillsize, sectorcolor, basealpha, drawflag);
                break;
            }
            
			// Autoscaling based on the center area
			if(size_center_y > fillsize_y)
			{
				factor = fillsize_y / size_center_y;
				size_center = size_center * factor;
				size_left = size_left * factor;
				size_right = size_right * factor;
			}
			
			local vector part_left, part_center, part_right;
			part_left = size_left;
			part_right = size_right;
			part_center = size_center;
			part_center_x = fillsize_x;
			
			local vector origin_left, origin_center, origin_right;
			origin_left = origin_center = origin_right = fillpos;
			
			origin_center_x = origin_left_x + part_left_x;
			part_center_x -= part_left_x;
			
			origin_right_x = origin_right_x + fillsize_x - part_right_x;
			part_center_x -= part_right_x;
            
			if(hudskin_image_sector_fill_left)
				drawpic(origin_left, hudskin_image_sector_fill_left, size_left, sectorcolor, basealpha, drawflag);
			if(hudskin_image_sector_fill_center) {
                if(hudskin_sector_fill == FILL_STRETCH)
                    drawpic(origin_center, hudskin_image_sector_fill_center, part_center, sectorcolor, basealpha, drawflag);
                else
                    drawpic_tiled(origin_center, hudskin_image_sector_fill_center, size_center, part_center, sectorcolor, basealpha, drawflag, '0 0 0');
            }
			if(hudskin_image_sector_fill_right)
				drawpic(origin_right, hudskin_image_sector_fill_right, size_right, sectorcolor, basealpha, drawflag);
            
			break;
	}
}

void DrawProgressBarSector(float prog, vector hud_sector_pos, vector hud_sector, vector c_sector, vector c_border, float a_sector, float a_border, vector c_sector_p, vector c_border_p, float a_sector_p, float a_border_p, float sector_alphamod, float hud_sector_drawflag) {
    float invert;
    if(prog < 0) {
        prog *= -1;
        invert = 1;
    }
    
    if(prog <= 0.01)
        prog = 0;
    
    switch(hudskin_progress_mode) {
        case 0: { // Use the whole sector as both the background and the bar
            DrawHUDLineSector(hud_sector_pos, hud_sector, a_sector*sector_alphamod*hudskin_progress_bgalpha, c_sector, hud_sector_drawflag);
            DrawHUDLineSectorBorder(hud_sector_pos, hud_sector, a_border*sector_alphamod*hudskin_progress_bgalpha, c_border);
            GetSectorFullClipArea(hud_sector_pos, hud_sector);
            drawsetcliparea(sector_clip_pos_x + sector_clip_size_x * (1-prog) * invert, sector_clip_pos_y, sector_clip_size_x * prog, sector_clip_size_y);
            DrawHUDLineSector(hud_sector_pos, hud_sector, a_sector_p*sector_alphamod, c_sector_p, hud_sector_drawflag);
            DrawHUDLineSectorBorder(hud_sector_pos, hud_sector, a_border_p*sector_alphamod, c_border_p);
            drawresetcliparea();
            break;
        }
        
        case 1: { // Use the border for progressbar, rest as background
            DrawHUDLineSector(hud_sector_pos, hud_sector, a_sector*sector_alphamod, c_sector, hud_sector_drawflag);
            DrawHUDLineSectorBorder(hud_sector_pos, hud_sector, a_border*sector_alphamod*hudskin_progress_bgalpha, c_border);
            GetSectorBorderClipArea(hud_sector_pos, hud_sector);
            drawsetcliparea(sector_clip_pos_x + sector_clip_size_x * (1-prog) * invert, sector_clip_pos_y, sector_clip_size_x * prog, sector_clip_size_y);
            DrawHUDLineSectorBorder(hud_sector_pos, hud_sector, a_border_p*sector_alphamod, c_border_p);
            drawresetcliparea();
            break;
        }
        
        case 2: { // Draw border with full opacity, use the rest as progressbar
            DrawHUDLineSector(hud_sector_pos, hud_sector, a_sector*sector_alphamod*hudskin_progress_bgalpha, c_sector, hud_sector_drawflag);
            DrawHUDLineSectorBorder(hud_sector_pos, hud_sector, a_border*sector_alphamod, c_border);
            GetSectorClipArea(hud_sector_pos, hud_sector);
            drawsetcliparea(sector_clip_pos_x + sector_clip_size_x * (1-prog) * invert, sector_clip_pos_y, sector_clip_size_x * prog, sector_clip_size_y);
            DrawHUDLineSector(hud_sector_pos, hud_sector, a_sector_p*sector_alphamod, c_sector_p, hud_sector_drawflag);
            drawresetcliparea();
        }
    }
    
    if(!hudskin_image_progress_head || !hudskin_progress_head_alpha)
        return;
    
    // TODO: more customization options here
    
    vector hpos;
    vector hsize = hudskin_size_progress_head;
    hsize_y = sector_clip_size_y;
    hsize_x *= 0.5;
    hpos_y = sector_clip_pos_y;
    hpos_x = sector_clip_pos_x + sector_clip_size_x*(invert? 1-prog : prog) - hsize_x * 0.5;
    
    float a = hudskin_progress_head_alpha;
    if(prog > 0.90)
        a *= (1 - prog) / 0.10;
    else if(prog < 0.10)
        a *= 1 - (0.10 - prog) / 0.10;
    
    if(a) drawpic(hpos, hudskin_image_progress_head, hsize, hudskin_progress_head_color, a, DRAWFLAG_NORMAL);
}

float ammonotifytime;

void Sbar_DrawScore_Rankings(vector pos, vector mySize, entity me)
{
	if(oldengine)
		return;
	
	if(!rm_showrankings)
		return;
	
	pos_y -= sbar_info_pos;
	
	entity pl, tm;
#define SCOREPANEL_MAX_ENTRIES 6
#define SCOREPANEL_ASPECTRATIO 2
	float entries = bound(1, floor(SCOREPANEL_MAX_ENTRIES * mySize_y/mySize_x * SCOREPANEL_ASPECTRATIO), SCOREPANEL_MAX_ENTRIES);
	
	if(teamplay)
		entries = entries / 2;
	
	const vector fontsize = '8 8 0'; //'1 1 0' * (mySize_y/entries);

	vector score_color;
	score_color = '1 1 1';

	float name_size = mySize_x*0.75;
	float spacing_size = mySize_x*0.04;
	const float highlight_alpha = 0.2;
	string s;

	float j, i;
	j = 0;

	for (tm = teams.sort_next; tm && j < 2; tm = tm.sort_next)
	{
		if(tm.team == COLOR_SPECTATOR)
			continue;
		
		i = 0;
		for (pl = players.sort_next; pl && i<entries; pl = pl.sort_next)
		{
			if(pl.team != tm.team)
				continue;

			if (pl == me)
				drawfill(pos, eX * mySize_x + eY * fontsize_y, '1 1 1', highlight_alpha * sbar_alpha_fg, DRAWFLAG_NORMAL);
				
			if (teamplay)
				score_color = GetTeamRGB(pl.team) * 0.8;
			
			s = textShortenToWidth_svn(GetPlayerName(pl.sv_entnum), name_size, fontsize, stringwidth_colors_svn);
			drawcolorcodedstring(pos + eX * (name_size - stringwidth_svn(s, TRUE, fontsize)), s, fontsize, sbar_alpha_fg, DRAWFLAG_NORMAL);
			drawstring(pos + eX * (name_size + spacing_size), ftos(pl.(scores[ps_primary])), fontsize, score_color, sbar_alpha_fg, DRAWFLAG_NORMAL);
			pos_y += fontsize_y;
			++i;
		}
		
		pos_y += 3;
		++j;
	}
}

void DrawProgress (vector cpos, vector l_size, float progress, float alpha, vector l_color)
{
	vector pos;
	pos_x = cpos_x - l_size_x / 2;
	pos_y = cpos_y - l_size_y / 2;
	
	vector fill = l_size;
	fill_x *= progress;
	
	drawborderlines(1, pos, l_size, l_color, alpha, DRAWFLAG_NORMAL);
	drawfill(pos, fill, l_color, alpha * 0.7, DRAWFLAG_NORMAL);
}

float rev_visual;
float rev_alpha;
float rev_old;

float hg_visual;
float hg_alpha;

float hgregen;

float ammo_useprogress;
float vhealth;
float vshield;

float revmode;

void Sbar_DrawHGShield(void) {
    float st = getstati(STAT_STEALTH);
    float s = st || getstatf(STAT_HGSHIELD);
    
    if(s)
        vshield = approach(vshield, 1, frametime * 3);
    else
        vshield = approach(vshield, 0, frametime * 3);
    
    if(vshield)
        drawfill('0 0 0', vid_conwidth * '1 0 0' + vid_conheight * '0 1 0', (st? '1 1 1' : ('0.2 0.2 1' + '0.8 0.8 -1' * getstatf(STAT_HGSHIELDPOWER))), 0.1 * vshield, DRAWFLAG_ADDITIVE);
}

float hg_bonusalpha;
float hg_lastbonus;
void Sbar_DrawHGBonus(void) {
    float num, hgtype, a, sw, spacing = 4;
    vector fs, o;
    string s;
    
    num = getstati(STAT_HGBONUS);
    hg_bonusalpha = approach(hg_bonusalpha, (num > 0), frametime * 2);
    
    if(!hg_bonusalpha)
        return;
    
    if(num > 0)
        hgtype = hg_lastbonus = getstati(STAT_HGBONUSTYPE);
    else
        hgtype = hg_lastbonus;
    
    a = sbar_alpha_fg * ipol_swingInOut(hg_bonusalpha) * (0.9 + 0.1 * sin(time * 5));
    fs = '32 32 0' * a;
    o = '0.5 0 0' * vid_conwidth + '0 1 0' * (vid_conheight - 85);
    
    drawfont = sbar_bigfont;
    s = strcat(HG_TypeToExpandedName(hgtype), "!", ((num > 1)? strcat(" x", ftos(num)) : ""));
    sw = stringwidth(s, FALSE) + 1;
    o_x -= (spacing + fs_x * sw) * 0.5;
    
    drawpic(o, HG_TypeToIcon(hgtype, TRUE, FALSE), fs, '1 1 1', a, DRAWFLAG_NORMAL);
    o_x += fs_x + spacing;
    drawstring(o, s, fs, '0.2 0.2 0.2' + HG_TypeToColor(hgtype), a, DRAWFLAG_NORMAL);
    drawfont = sbar_font;
    
}

void Sbar_DrawBuffs(void) {
    vector pos;
    float buffs = getstati(STAT_BUFFS), sw, b;
    string s;
    
    if(!buffs)
        return;
    
    for(b = BUFF_FIRST; b <= BUFF_LAST; b *= 2) if(buffs & b) {
        string o = strcat(rgb_to_hexcolor(Buffs_TypeToColor(b)), Buffs_TypeToExpandedName(b));
        if(s == "")
            s = o;
        else
            s = strcat(s, " ", o);
    }
    
    sw = stringwidth(s, TRUE);
    pos_y = vid_conheight - vid_conheight/7 - sbar_fontsize_y;
    pos_x = (vid_conwidth - sw * sbar_fontsize_x) * 0.5;
    drawcolorcodedstring(pos, s, sbar_fontsize, 0.3, DRAWFLAG_NORMAL);
}

string jb_str;
float jb_str_alpha;
float hg_maxcd;

#define RMODE_CAP 0
#define RMODE_REV 1
#define RMODE_AUTH 2

void Sbar_DrawPlayerName(string s) {
    vector pos;
    
    drawfont = sbar_bigfont;
    
    pos_y = vid_conheight - 50 - sbar_fontsize_spec_y;
    s = textShortenToWidth(s, vid_conwidth/2.5/sbar_fontsize_spec_x, stringwidth_colors);
    drawcolorcodedstring(pos, s, sbar_fontsize_spec, sbar_alpha_fg, DRAWFLAG_NORMAL);
    
    drawfont = sbar_font;
}

void Sbar_Draw(void)
{
	// vectors for top right, bottom right, bottom and bottom left corners

	vector topright;
	vector bottom;
	vector bottomright;
	vector bottomleft;

	topright_x = vid_conwidth;
	topright_y = 0;
	topright_z = 0;

	bottom_x = vid_conwidth/2;
	bottom_y = vid_conheight;
	bottom_z = 0;

	bottomright_x = vid_conwidth;
	bottomright_y = vid_conheight;
	bottomright_z = 0;

	bottomleft_x = 0;
	bottomleft_y = vid_conheight;
	bottomleft_z = 0;

	sbar_alpha_bg = cvar("sbar_alpha_bg") /* * (1 - cvar("_menu_alpha"))*/;
	sbar_border_thickness = bound(0, cvar("sbar_border_thickness"), 5);
	sbar_color_bg_team = cvar("sbar_color_bg_team");
	sbar_scoreboard_alpha_bg = cvar("sbar_scoreboard_alpha_bg");
	sbar_scoreboard_highlight = cvar("sbar_scoreboard_highlight");
	sbar_info_pos = max(0, cvar("sbar_info_pos"));
	
	if(sv_oldfag) {
		rm_oldhud = TRUE;
		rm_showrankings = FALSE;
		rm_visualscore = FALSE;
		rm_hidewatermark = TRUE;
		rm_simpleeffects = TRUE;
		rm_nobigtext = TRUE;
	}
	
	float i;
	float weapon_stats;
	float x, fade;
	float stat_items, stat_weapons;
    vector c;

    Sbar_DrawHGShield();

	weapon_stats = getstati(STAT_DAMAGE_HITS);
 	weapon_number = weapon_stats & 63;
 	weapon_hits[weapon_number] = rint(weapon_stats / 64);

 	weapon_stats = getstati(STAT_DAMAGE_FIRED);
 	weapon_number = weapon_stats & 63;
 	weapon_fired[weapon_number] = rint(weapon_stats / 64);

	vector o; o = '1 0 0' * vid_conwidth;
	vector o2; o2 = '0.5 0 0' * vid_conwidth;
	o2_y = vid_conheight / 4;
	o_y = 28; // move spectator text slightly down to prevent overlapping the timer

    if(!rm_showtimer)
        o_y *= max(timer_alpha, sbar_scoreboard_fade_alpha);

	string s;
	vector pos;
	pos = '0 0 0';
    
	sbar_fontsize = Sbar_GetFontsize("sbar_fontsize");
	sbar_fontsize_spec = Sbar_GetFontsize("sbar_fontsize_spec");

	o2_y += sbar_fontsize_y * 1.5;

	g_minstagib = getstati(STAT_MINSTA);
	if(g_minstagib) if(!minstasbar_fixed)
	{
		localcmd("cl_cmd sbar_columns_set default\n");
		minstasbar_fixed = TRUE;
	}

	if(spectatee_status == -1 || !spectatee_status)
	{
		//release madoka and HUD locks. Perhaps should be done elsewhere?

		#ifdef RM_SUPPORT_MADOKA
		if(madoka_locked)
		{
			//print("releasing madoka\n");
			madoka_locked = 0;
			//loadfont("user2", (cvar("rm_madoka") ? "madoka-rune" : "vera-sans-big"));
			SetMadokaFont(MDKF_AUTO);
		}
		#endif

		if(hudlocked)
		{
			hudlocked = 0;
			rm_althud = rm_althud_option;
			rm_oldhud = rm_oldhud_option;
			
			if(hudskin_name != cvar_string("rm_hudskin"))
				HUDSkin_Load(cvar_string("rm_hudskin"));
		}

		if(fovlock >= 0)
			fovlock = -1;
	}

	float rev;
    // we may have both CAPTURE_PROGRESS and REVIVE_PROGRESS at once, but CAPTURE_PROGRESS is more important.
	rev = getstatf(STAT_CAPTURE_PROGRESS);
    if(!rev) {
        rev = getstatf(STAT_REVIVE_PROGRESS);
        if(!rev) {
            rev = getstatf(STAT_TERM_AUTH);
            if(rev) revmode = RMODE_AUTH;
        } else revmode = RMODE_REV;
    } else revmode = RMODE_CAP;
	
	if(rev) {
        rev_visual += (rev - rev_visual) * drawframetime * 10;
		rev_alpha = approach(rev_alpha, 1, drawframetime * 5);
	} else {
		rev_alpha = approach(rev_alpha, 0, drawframetime * 5);
		if(!rev_alpha)
			rev_visual = 0;
		if(rev_old > 0.9)
			rev_visual = 1;	// This is _most likely_ a completed revival, so let's display it as such
	}
	
	rev_old = rev;
	rev = rev_visual;
	
	if(getstati(STAT_FROZEN))
	{
		revfadetime = 0;
		revsaved = rev;
		revalpha = 0.6;
	}
	else
	{
		if(!revfadetime)
			revfadetime = time;
	}

	if(revalpha > 0)
	{
		local vector fcolor;
		fcolor_x = revsaved;
		fcolor_y = 1 - revsaved * 0.9;
		fcolor_z = 1 - revsaved;

		revalpha = (revfadetime? bound(0, 1 - 4 * (time - revfadetime), 0.6) : 0.6);
		drawfill('0 0 0', bottomright, fcolor, revalpha, DRAWFLAG_ADDITIVE);
	}

	#ifdef RM_SUPPORT_MORNINGRESCUE
	if(morningrescue)
	if(time <= mr_fadetime)
	{
		Sbar_MorningRescue();
		return;
	}
	else
	{
		morningrescue = 0;
		drawfont = sbar_font;
	}
	#endif
    
    float jailspec = FALSE;
    if(gametype == GAME_JAILBREAK) if(playerslots[player_localentnum-1].(scores[SP_FROZENSTATUS])) {
        o = Sbar_DrawNoteLine(o, "^1You are imprisoned");
        if(!spectatee_status)
            o = Sbar_DrawNoteLine(o, strcat("^1Press ^3", getcommandkey("hook / nadget key", "+hook"), "^1 to spectate your team"));
        else
            jailspec = TRUE;
    }
    
	if(spectatee_status && !intermission)
	{
        if(spectatee_status == -1)
            s = "^1Observing";
        else
            s = GetPlayerName(spectatee_status - 1);
        Sbar_DrawPlayerName(s);
        
		// spectator text in the upper right corner
		if(spectatee_status == -1)
			s = strcat("^1Press ^3", getcommandkey("primary fire", "+attack"), "^1 to spectate");
		else
			s = strcat("^1Press ^3", getcommandkey("primary fire", "+attack"), "^1 for another player");
		o = Sbar_DrawNoteLine(o, s);
        
        if(!jailspec) {
            if(spectatee_status == -1)
                s = strcat("^1Use ^3", getcommandkey("next weapon", "weapnext"), "^1 or ^3", getcommandkey("previous weapon", "weapprev"), "^1 to change the speed");
            else
                s = strcat("^1Press ^3", getcommandkey("secondary fire", "+attack2"), "^1 to observe");
            o = Sbar_DrawNoteLine(o, s);
        }
        
		if(gametype == GAME_ARENA)
			s = "^1Wait for your turn to join";
		else if(gametype == GAME_LMS)
		{
			entity sk;
			sk = playerslots[player_localentnum - 1];
			if(sk.(scores[ps_primary]) >= 666)
				s = "^1Match has already begun";
			else if(sk.(scores[ps_primary]) > 0)
				s = "^1You have no more lives left";
			else
				s = strcat("^1Press ^3", getcommandkey("jump", "+jump"), "^1 to join");
		}
		else
			s = strcat("^1Press ^3", getcommandkey("jump", "+jump"), (jailspec? "^1 to leave spectator mode" : "^1 to join"));
		o = Sbar_DrawNoteLine(o, s);

		//show restart countdown:
		if (time < getstatf(STAT_GAMESTARTTIME)) {
			float countdown;
			//we need to ceil, otherwise the countdown would be off by .5 when using round()
			countdown = ceil(getstatf(STAT_GAMESTARTTIME) - time);
			s = strcat("^1Game starts in ^3", ftos(countdown), "^1 seconds");
			o = Sbar_DrawNoteLine(o, s);
		}
	} else {
        float spn = cvar("rm_showplayername");
        if((spn > 1) || (spn && isdemo()))
            Sbar_DrawPlayerName(GetPlayerName(player_localentnum - 1));
    }
    
	if(warmup_stage && !intermission)
	{
		s = "^2Currently in ^1warmup^2 stage!";
		o2 = Sbar_DrawCenterNoteLine(o2, s);
	}
    
    if(rev)
    {
        vector revpos;
        revpos_y = vid_conheight / 2 + sbar_fontsize_y * 2;

        drawfont = sbar_font;

		string s2;
        if(revmode == RMODE_REV)
			s = "Revival progress: ";
        else if(revmode == RMODE_AUTH)
            s = "Authenticating: ";
		else if(gametype == GAME_JAILBREAK)
			s = "Unlocking the jail: ";
		else
			s = "Capture progress: ";
        
		//drawcolorcodedstringcenter(revpos, strcat(s, ftos(floor(rev * 100)), "%"), sbar_fontsize, rev_alpha, DRAWFLAG_NORMAL);
		s2 = strcat(ftos(floor(rev * 100)), "%");
		
		if(rev <= 0.5)
			c = '0 1 1' + '2 0 0' * rev;
		else
			c = '1 1 1' - '0 1.5 3' * (rev - 0.5);
			
		drawstringcenter_offset(revpos, s, sbar_fontsize, '1 1 1', rev_alpha, DRAWFLAG_NORMAL, stringwidth_svn(s2, FALSE, sbar_fontsize) * 0.5);
		drawstringcenter_offset(revpos, s2, sbar_fontsize, c, rev_alpha, DRAWFLAG_NORMAL, -stringwidth_svn(s, FALSE, sbar_fontsize) * 0.5);
		
		revpos_y += sbar_fontsize_y + 5;
		revpos_x = vid_conwidth/2;
		
		DrawProgress(revpos, '15 0 0' * sbar_fontsize_x + '0 5 0', rev, 0.7 * rev_alpha, c);
    }
    
    float havemsg = TRUE;
    switch(getstati(STAT_JBMSG)) {
        case JBMSG_CAPPINGNEUTRAL   :   jb_str  =  "Your team is capturing a Neutral Control Point";    break;
        case JBMSG_ALLALIVE         :   jb_str  =  "Your team is already free";                         break;
        case JBMSG_NOTREADY         :   jb_str  =  "This Control Point is not ready yet";               break;
        case JBMSG_WRONGTEAM        :   jb_str  =  "You can't capture your team's control points";      break;
        case JBMSG_TOOLATE          :   jb_str  =  "Someone is already capturing this";                 break;
        default                     :   havemsg =  FALSE;                                               break;
    }
    
    if(havemsg)
        jb_str_alpha = approach(jb_str_alpha, 1, frametime);
    else
        jb_str_alpha = approach(jb_str_alpha, 0, frametime * 3);
    
    if(jb_str) if(jb_str_alpha) {
        drawstringcenter('0 1 0' * (vid_conheight / 2 + sbar_fontsize_y * 4), jb_str, sbar_fontsize, '1 1 1', jb_str_alpha * 0.8, DRAWFLAG_NORMAL);
    }
    
    
	// handgrenade force meter
	float hgstat = getstatf(STAT_HGFORCE);
    float hgls = getstatf(STAT_HGLAUNCH);
	
	if(hgstat) {
		hg_alpha = approach(hg_alpha, 1, 5 * drawframetime);
	} else {
		hg_alpha = approach(hg_alpha, 0, 5 * drawframetime);
	}
    
	hg_visual = approach(hg_visual, hgstat, drawframetime * hgls);
	hgstat = hg_visual;
	
	if(hg_alpha)
	{
		vector hgpos;
		hgpos_x = vid_conwidth/2;
		hgpos_y = vid_conheight - vid_conheight/4;
		DrawProgress(hgpos, '120 5 0', hgstat, 0.7 * hg_alpha, '1 0 0' + '0 1 0' * (1 - hgstat));
	}
    
	local vector sv_pos;
	sv_pos = bottomright;
	sv_pos_y -= 200;
    sv_pos_x -= 15;
	
	if(!rm_showrankings)
		sv_pos_y += 40;

	float sv_offset;

	if(rm_visualscore)
	for(i = score_strings_num - 1; i >= 0; --i)
	{
		local float a;
		a = bound(0, 1 - 4 * (time - score_strings_fadeout[i]), 1);
		if(!a)
		{
			//++sv_offset;
			continue;
		}

		a *= score_strings_alphamod[i];

		s = score_strings[i];
		c = score_strings_color[i];

		local vector mypos;
		mypos = sv_pos;
		mypos_y -= 24 * (score_strings_num - i - sv_offset);

		local float j;
		for(j = 0; j < 2; ++j)
		{
			if(rm_simpleeffects) if(j)
				break;

			local float a2 = (j? bound(0, 1 - 4 * (time - score_strings_appear[i]), 1) : a);

			drawfont = sbar_bigfont_real; // bypass madoka, as many numeric characters are missing
			drawstringright(mypos, s, '30 30 0' * (j? (1.0 + (1.0 - a2)) : 1), c, a2, DRAWFLAG_NORMAL);
			drawfont = sbar_font;
		}
	}

	float bp_alpha, bp_ypos;
	vector bp_pos;
    bp_ypos = (vid_conheight / 5) * (1 - sbar_scoreboard_fade_alpha)
            + (SCOREBOARD_OFFSET) * (    sbar_scoreboard_fade_alpha);

	if(obp_draw)
	if(bigprint_oldstring)
	{
		bp_alpha = bound(0, 1 - 4 * (time - bigprint_oldfadetime), 1);

		if(bp_alpha > 0)
		{
            bp_pos = '0 1 0' * bp_ypos;
			bp_pos_y -= 24 * (rm_simpleeffects? 1 : ipol_swingInOut(1 - bound(0, 1 - 4 * (time - bigprint_oldappeartime), 1)));
			drawfont = sbar_bigfont;

			if(rm_simpleeffects)
				drawcolorcodedstringcenter(bp_pos, bigprint_oldstring, '24 24 0', bp_alpha, DRAWFLAG_NORMAL);
			else
				drawcolorcodedstringcenter(bp_pos, bigprint_oldstring, '24 24 0' * (1.0 + (1.0 - bp_alpha)), bp_alpha, DRAWFLAG_NORMAL);

			drawfont = sbar_font;
			//comment for oldbigprint is not displayed
		}
		else
			obp_draw = 0;
	}

	bp_pos = '0 1 0' * bp_ypos;
	if(bp_draw)
	if(bigprint_string)
	{
		for(i = 0; i < 2; ++i)
		{
			if(rm_simpleeffects) if(i)
				break;

			bp_alpha = bound(0, 1 - 4 * (time - (i? bigprint_appeartime : bigprint_fadetime)), 1);

			if(bp_alpha > 0)
			{
				drawfont = sbar_bigfont;

				if(rm_simpleeffects)
					drawcolorcodedstringcenter(bp_pos, bigprint_string, '24 24 0', bp_alpha, DRAWFLAG_NORMAL);
				else
				{
					if(tmpmadoka_fadetime >= time)
					{
						local string mycolor;
						local string mychar;
						local vector offset;
						local float j;

						bp_pos_x = 0.5 * (vid_conwidth - 0.6025 * strlennocol(bigprint_string) * 24);
						for(j = 0; j < strlen(bigprint_string); ++j)
						{
							mychar = substring(bigprint_string, j, 1);

							if(mychar == "^")
							{
								if(substring(bigprint_string, j+1, 1) == "x")
								{
									mycolor = substring(bigprint_string, j, 5);
									j += 5;
								}
								else
								{
									mycolor = substring(bigprint_string, j, 2);
									++j;
								}
								continue;
							}

							offset_y = 3 * cos(bp_pos_x + 5 * time) * (mod(j, 2)? 1 : -1);
							offset_x = offset_y * (mod(j, 2)? -1 : 1);
							local string resultstr = strcat(mycolor, mychar);

							dummyfunction(0, 0, 0, 0, 0, 0, 0, 0); // work around DP bug (set OFS_PARAM5 to 0)
							//drawcolorcodedstringcenter(bp_pos + offset, resultstr, '24 24 0' * (1.0 + (1.0 - bp_alpha)), bp_alpha, DRAWFLAG_NORMAL);
							//bp_pos_x += stringwidth(resultstr, TRUE) * 24 * (1.0 + (1.0 - bp_alpha));

							bp_pos_x += stringwidth(resultstr, TRUE) * 24 * (1.0 + (1.0 - bp_alpha));
							drawcolorcodedstring(bp_pos + offset, resultstr, '24 24 0' * (1.0 + (1.0 - bp_alpha)), bp_alpha, DRAWFLAG_NORMAL);
						}
					}
					else {
						vector sz = '24 24 0' * (1.0 + ipol_powIn(3, 1.0 - bp_alpha));
						drawcolorcodedstringcenter(bp_pos - sz * 0.25 * (1 - bp_alpha), bigprint_string, sz, bp_alpha, DRAWFLAG_NORMAL);
					}
				}

				drawfont = sbar_font;
			}
			else if(!i)
				bp_draw = 0;
		}
	}

	if(bpc_draw)
	if(bigprint_comment)
	if(!rm_hidebigcomments)
	{
		bp_pos_y += 24;

		for(i = 0; i < (rm_simpleeffects? 1 : 2); ++i)
		{
			if(bigprint_nofadein) if(i)
				continue;

			if(rm_simpleeffects) if(i)
				break;

			bp_alpha = bound(0, 1 - 4 * (time - (i? bigprint_commentappeartime : bigprint_commentfadetime)), 1);

			if(bp_alpha)
			{
				if(rm_simpleeffects)
					drawcolorcodedstringcenter(bp_pos, bigprint_comment, sbar_fontsize, bp_alpha, DRAWFLAG_NORMAL);
				else
					drawcolorcodedstringcenter(bp_pos, bigprint_comment, sbar_fontsize * (1.0 + (1.0 - bp_alpha)), bp_alpha, DRAWFLAG_NORMAL);
			}
			else if(!i)
				bpc_draw = 0;
		}
	}

	if(rm_showspec)
	if(spectatee_status != -1)
	if(num_spectators)
	{
		local float limit;
		if(spectatee_status)
		{
			o = Sbar_DrawNoteLine(o, "");
			o = Sbar_DrawNoteLineA(o, "^2Spectating this player: ", 0.5);
		}
		else
			o = Sbar_DrawNoteLineA(o, "^2Spectating you: ", 0.5);
		o = Sbar_DrawNoteLineA(o, "^9type ^7showspec 0^9 to hide", 0.5);
		o = Sbar_DrawNoteLineA(o, "", 0.5);

		limit = min(num_spectators, MAX_SPECTATORS);
		for(i = 0; i < limit; ++i)
		{
			float slot = spectatorlist[i];

			#ifdef RM_SUPPORT_MADOKA
			local entity pl;
			pl = playerslots[slot];

			if(pl.(scores[SP_MADOKASTATUS]))
				drawfont = sbar_madokafont;
			#endif

			o = Sbar_DrawNoteLineA(o, GetPlayerName(slot), 0.5);

			#ifdef RM_SUPPORT_MADOKA
			drawfont = sbar_font;
			#endif
		}

		if(i != num_spectators)
			o = Sbar_DrawNoteLineA(o, strcat("^9(", ftos(num_spectators - MAX_SPECTATORS), " more)"), 0.5);
	}

	// move more important stuff more to the middle so its more visible
	o_y = vid_conheight * 0.66;

	string blinkcolor;
	if(mod(time, 1) >= 0.5)
		blinkcolor = "^1";
	else
		blinkcolor = "^3";

	if(ready_waiting && !intermission && !spectatee_status)
	{
		if(ready_waiting_for_me)
		{
			if(warmup_stage)
				s = strcat(blinkcolor, "Press ^3", getcommandkey("ready", "ready"), blinkcolor, " to end warmup");
			else
				s = strcat(blinkcolor, "Press ^3", getcommandkey("ready", "ready"), blinkcolor, " once you are ready");
		}
		else
		{
			//if(warmup_stage)
			//	s = strcat("^2Waiting for others to ready up to end warmup...");
			//else
			//	s = strcat("^2Waiting for others to ready up...");

			s = "Waiting for others";
		}
		o2 = Sbar_DrawCenterNoteLine(o2, s);
	}
	else if(warmup_stage && !intermission && !spectatee_status)
	{
		s = strcat("^2Press ^3", getcommandkey("ready", "ready"), "^2 to end warmup");
		o2 = Sbar_DrawCenterNoteLine(o2, s);
	}

#if 0
	if(time < rm_helptime)
	{
		local float halpha = bound(0, 1 - 4 * (time - (rm_helptime - 1)), 1);

		if(halpha > 0)
		{
			o2 = Sbar_DrawCenterNoteLineA(o2, "", halpha);
			o2 = Sbar_DrawCenterNoteLineA(o2, "It looks like you are playing RocketMinsta for the first time", halpha);
			o2 = Sbar_DrawCenterNoteLineA(o2, "Type ^2rmhelp^7 in the console to see possible configuration options", halpha);
			o2 = Sbar_DrawCenterNoteLineA(o2, strcat("This message will disappear in ", ftos(-floor(time - rm_helptime)), " seconds"), halpha);
		}
	}
#endif

	if(teamplay && !intermission && !spectatee_status && !cvar("g_inf"))
	{
		entity tm;
		float ts_min, ts_max;
		tm = teams.sort_next;
		if (tm)
		{
			for(; tm.sort_next; tm = tm.sort_next)
			{
				if(!tm.team_size || tm.team == COLOR_SPECTATOR)
					continue;
				if(!ts_min) ts_min = tm.team_size;
				else ts_min = min(ts_min, tm.team_size);
				if(!ts_max) ts_max = tm.team_size;
				else ts_max = max(ts_max, tm.team_size);
			}
			if ((ts_max - ts_min) > 1)
			{
				tm = GetTeam(myteam, false);
				if (tm)
				if (tm.team != COLOR_SPECTATOR)
				{
					if (tm.team_size == ts_max)
					{
						local vector centeroffs;
						centeroffs_y = 3 * cos(o2_y + 3 * time);

						s = strcat(blinkcolor, "Teamnumbers are unbalanced!");
						o2 = Sbar_DrawCenterNoteLine(o2 + centeroffs, s);

						s = strcat(blinkcolor, "Press ^3", getcommandkey("team menu", "menu_showteamselect"), blinkcolor, " to adjust");
						o2 = Sbar_DrawCenterNoteLine(o2 + centeroffs, s);
					}
					else
					{
						s = strcat(blinkcolor, "Teamnumbers are unbalanced!");
						o = Sbar_DrawNoteLine(o, s);
					}
				}
			}
		}
	}

	Sbar_UpdatePlayerTeams();
	//'0.2 0.2 0.2'

	float sector_alphamod;
	sector_alphamod = 1;

	vector slice_basecolor; slice_basecolor = hudskin_line_color;
	float slice_basealpha; slice_basealpha = hudskin_line_alpha;
	float border_basealpha; border_basealpha = hudskin_border_alpha;
	
	vector sector_basecolor; sector_basecolor = hudskin_sector_color;
	vector border_basecolor; border_basecolor = hudskin_border_color;
	float sector_basealpha; sector_basealpha = hudskin_sector_alpha;
	float sector_teamalpha = sector_basealpha;
	float border_teamalpha = border_basealpha;
	
	vector base_teamcolor;
	
	if(teamplay)
		base_teamcolor = GetTeamRGB(myteam);
	else
	{
		base_teamcolor_x = cvar("sbar_color_bg_r");
		base_teamcolor_y = cvar("sbar_color_bg_g");
		base_teamcolor_z = cvar("sbar_color_bg_b");
	}
	
	vector sector_teamcolor = (base_teamcolor + hudskin_sector_teamcolor_mod + HUDSkin_GetTeamColorMod_Sector(myteam)) * hudskin_sector_teamcolor_brightness;
	vector border_teamcolor = (base_teamcolor + hudskin_border_teamcolor_mod + HUDSkin_GetTeamColorMod_Border(myteam)) * hudskin_border_teamcolor_brightness;

	float bw_left, bw_right;
	bw_left = HUDSkin_GetBorderWidth(BORDER_LEFT);
	bw_right = HUDSkin_GetBorderWidth(BORDER_RIGHT);

	float linedrawn;

	// hudflash slices
	HudFlash_Apply(slice_basecolor, slice_basealpha, TRUE, hudskin_flash_line_imod, hudskin_flash_line_amod);
		slice_basecolor = hudflash_resultcolor;
		slice_basealpha = hudflash_resultalpha;

	// hudflash sectors
	#if 0
	HudFlash_Apply(sector_basealpha, sector_basecolor, FALSE, 1, 1);
		sector_basealpha = hudflash_resultalpha;
		sector_basecolor = hudflash_resultcolor;
	#endif

	// hudflash teamcolored sectors
	HudFlash_Apply(sector_teamcolor, sector_teamalpha, TRUE, hudskin_flash_sector_imod, hudskin_flash_sector_amod);
		sector_teamcolor = hudflash_resultcolor;
		sector_teamalpha = hudflash_resultalpha;

	HudFlash_Apply(border_teamcolor, border_teamalpha, TRUE, hudskin_flash_border_imod, hudskin_flash_border_amod);
		border_teamcolor = hudflash_resultcolor;
		border_teamalpha = hudflash_resultalpha;

	vector hudline, hudline_pos, hud_sector, hud_sector_pos, sector_mod;
	float ammosector_pos, nadesector_pos, next_sector, hud_sector_drawflag;
	vector powerup_pos, teamhud_pos;
    hud_sector_drawflag = DRAWFLAG_NORMAL;

	if (intermission == 2) // map voting screen
	{
        float drawoverlay = TRUE;
        
        if(sb_showaccuracy) {
            Sbar_DrawAccuracyStats();
            drawoverlay = FALSE;
        }
        
        if(sb_showscores) {
            Sbar_DrawScoreboard();
            drawoverlay = FALSE;
        }
        
        if(drawoverlay)
            Sbar_FinaleOverlay();
        else
            Sbar_Timer();

		Sbar_Reset();
	}
	else if (sb_showscores_force || getstati(STAT_HEALTH) <= 0 || intermission == 1)
	{
        Sbar_DrawScoreboard();
  		if(sb_showaccuracy)
  			Sbar_DrawAccuracyStats();

		if(!rm_oldhud)
		{
			bottom_y -= 10;
			bottomleft_y -= 10;
			bottomright_y -= 10;

			hudline_y = 15;
			hudline_pos_y = bottom_y - 24;
			hud_sector_y = 21;
			hud_sector_pos_y = bottom_y - 27;

			next_sector = bottomright_x - SECWIDTH_NORMAL - 6;
			
			if(hudskin_line_full)
			{
				HUDLINE_SLICE({
					hudline_pos_x = 0;
					hudline_x = topright_x;
				})
			}
			
			HUDLINE_SLICE({
				hudline_pos_x = 0;
				hudline_x = topright_x - hudline_pos_x - (bottomright_x - next_sector) - bw_left;
			})

			HUDLINE_SECTOR({
				hud_sector_x = SECWIDTH_NORMAL;
				hud_sector_pos_x = hudline_pos_x + hudline_x + bw_left;
				sector_mod = '0 0 0';
			}, BG_SECTOR, BG_BORDER, A_SECTOR, A_BORDER)

			HUDLINE_SLICE({
				hudline_pos_x = hud_sector_pos_x + hud_sector_x + bw_right;
				hudline_x = topright_x;
			})
		}

		Sbar_Score();
		Sbar_Timer();

		Sbar_Reset();
  	}
	else
	{
        Sbar_DrawScoreboard();
		if(sb_showaccuracy)
			Sbar_DrawAccuracyStats();

		// lol
		if(!rm_oldhud)
		{
			bottom_y -= 10;
			bottomleft_y -= 10;
			bottomright_y -= 10;
		}

		float armor, health;
		armor = getstati(STAT_ARMOR);
		health = getstati(STAT_HEALTH);

		stat_items = getstati(STAT_ITEMS);
		stat_weapons = getstati(STAT_WEAPONS);

		fade = 3.2 - 2 * (time - weapontime);
		fade = bound(0.7, fade, 1);

		vector bg_size; // hud background size
		bg_size = '1600 58 0';
		
		vector s_health;
		
		if(rm_oldhud)
		{
			if (cvar("viewsize") <= 100 && vid_conwidth <= 1600) {
				if (teamplay)
					color =  GetTeamRGB(myteam) * sbar_color_bg_team; // hud color = myteam color
				else {
					// allow for custom HUD colors in non-teamgames
					color_x = cvar("sbar_color_bg_r");
					color_y = cvar("sbar_color_bg_g");
					color_z = cvar("sbar_color_bg_b");
				}

				HudFlash_Apply(color, sbar_alpha_bg, TRUE, 2, 1);
				drawpic(bottom - '800 58 0', "gfx/hud/sbar", bg_size, hudflash_resultcolor, hudflash_resultalpha, DRAWFLAG_NORMAL);
			}
		}
		else
		{
			hudline_y = 15;
			hudline_pos_y = bottom_y - 24;
			hud_sector_y = 21;
			hud_sector_pos_y = bottom_y - 27;

			if(teamhud_enabled != th_state)
			{
				if(teamhud_enabled)
					th_appeartime = time;
				else
					th_fadetime = time;

				th_state = teamhud_enabled;
			}

			if(th_state != th_finalstate)
			{
				if(th_state)
				{
					th_alpha = 1 - bound(0, 1 - 4 * (time - th_appeartime), 1);

					if(th_alpha >= 1)
						th_finalstate = th_state;
				}
				else
				{
					th_alpha = bound(0, 1 - 4 * (time - th_fadetime), 1);

					if(!th_alpha)
						th_finalstate = th_state;
				}
			}

			// same as above, but for powerups HUD
			if(pwhud_enabled != pw_state)
			{
				if(pwhud_enabled)
					pw_appeartime = time;
				else
					pw_fadetime = time;

				pw_state = pwhud_enabled;
			}

			if(pw_state != pw_finalstate)
			{
				if(pw_state)
				{
					pw_alpha = 1 - bound(0, 1 - 4 * (time - pw_appeartime), 1);

					if(pw_alpha >= 1)
						pw_finalstate = pw_state;
				}
				else
				{
					pw_alpha = bound(0, 1 - 4 * (time - pw_fadetime), 1);

					if(!pw_alpha)
						pw_finalstate = pw_state;
				}
			}

            vector mxdmg = healtharmor_maxdamage(getstati(STAT_HEALTH), getstati(STAT_ARMOR), armorblockpercent);
            vhealth += (min(mxdmg_x + 1, sv_nicehealth) - vhealth) * frametime * 10;

			if(rm_althud)	/// RM hud layout
			{
				if(hudskin_line_full)
				{
					HUDLINE_SLICE({
						hudline_pos_x = 0;
						hudline_x = topright_x;
					})
				}
				
				// we_need_to_go_wider.jpg
				teamhud_wide = 0;
				if(gametype == GAME_VIP) if(vid_conwidth >= 800)
					teamhud_wide = 1;

				// pre-healtharmor
				HUDLINE_SLICE({
					hudline_x = 7 - bw_left;
				})

				// healtharmor
				//HUDLINE_SECTOR({
                {
					hud_sector_x = SECWIDTH_HEALTH;
					hud_sector_pos_x = 7;
					sector_mod = '0 0 0'; //'-1 0 0';

					s_health = hud_sector_pos;
				}//, BG_SECTOR_TEAM, BG_BORDER_TEAM, A_SECTOR_TEAM, A_BORDER_TEAM)
                
                vdmg_dmgtakenorigin = '1 0 0' * (hud_sector_pos_x + 0.5 * hud_sector_x) + '0 1 0' * hud_sector_pos_y;
                DrawProgressBarSector(bound(0.01, vhealth/sv_nicehealth, 1), hud_sector_pos, hud_sector,
                                            BG_SECTOR_TEAM, BG_BORDER_TEAM, A_SECTOR_TEAM, A_BORDER_TEAM,
                                            BG_SECTOR_PROGRESS, BG_BORDER_PROGRESS, A_SECTOR_PROGRESS, A_BORDER_PROGRESS,
                                            sector_alphamod, hud_sector_drawflag);

				// healtharmor | ammo
				HUDLINE_SLICE({
					hudline_x = 10 - bw_right - bw_left;
					hudline_pos_x = hud_sector_pos_x + hud_sector_x + bw_right;
				})

				// ammo
                ammosector_pos = hud_sector_pos_x = hudline_pos_x - bw_right + 10;
                hud_sector_x = SECWIDTH_NORMAL;
                sector_mod = '0 0 0';
                
                if(ammo_useprogress)
                    DrawProgressBarSector(bound(0.01, (1 - getstati(STAT_BULLETS_LOADED)/getstati(STAT_BULLETS_MAX)), 1), hud_sector_pos, hud_sector,
                                            BG_SECTOR, BG_BORDER, A_SECTOR, A_BORDER,
                                            BG_SECTOR_PROGRESS, BG_BORDER_PROGRESS, A_SECTOR_PROGRESS, A_BORDER_PROGRESS,
                                            sector_alphamod, hud_sector_drawflag);
				else { HUDLINE_SECTOR({}, BG_SECTOR, BG_BORDER, A_SECTOR, A_BORDER) }
				
                if(g_nadgets && vid_conwidth >= 678) {
                    // ammo | nades
                    HUDLINE_SLICE({
                        hudline_x = 10 - bw_right - bw_left;
                        hudline_pos_x = hud_sector_pos_x + hud_sector_x + bw_right;
                    })
                    
                    // nades
                    nadesector_pos = hud_sector_pos_x = hudline_pos_x - bw_right + 10;
                    hud_sector_x = SECWIDTH_NORMAL;
                    sector_mod = '0 0 0';
                    sector_alphamod = 1;
                    
                    DrawProgressBarSector(1-hgregen, hud_sector_pos, hud_sector,
                                            BG_SECTOR, BG_BORDER, A_SECTOR, A_BORDER,
                                            BG_SECTOR_PROGRESS, BG_BORDER_PROGRESS, A_SECTOR_PROGRESS, A_BORDER_PROGRESS,
                                            sector_alphamod, hud_sector_drawflag);
                }
                
				// separator slice:
				//		ammo/nades | teamhud

				if(vid_conwidth < 800 || g_nadgets && vid_conwidth <= 1024)
					next_sector = bottomright_x - SECWIDTH_WIDE - 13;
				else if(teamhud_wide)
				{
					if(vid_conwidth <= 900)
						next_sector = hud_sector_pos_x + hud_sector_x + 10;
					else
						next_sector = bottom_x - SECWIDTH_WIDE/2;
				}
				else
					next_sector = bottom_x - SECWIDTH_NORMAL/2;

				HUDLINE_SLICE({
					hudline_pos_x = hud_sector_pos_x + hud_sector_x + bw_right;
					hudline_x = topright_x - hudline_pos_x - (bottomright_x - next_sector) - bw_left;
				})

				// teamhud
				if(th_alpha)
				{
					HUDLINE_SECTOR({
						if(teamhud_wide)
							hud_sector_x = SECWIDTH_WIDE;
						else
							hud_sector_x = SECWIDTH_NORMAL;
						hud_sector_pos_x = next_sector;
						sector_mod = '0 0 0';
						sector_alphamod = th_alpha;
					}, BG_SECTOR, BG_BORDER, A_SECTOR, A_BORDER)
				}
				sector_alphamod = 1;

				if(!teamhud_enabled || teamhud_enabled != th_finalstate)
				{
					hud_sector_pos_x = next_sector;
					hud_sector_x = -bw_right - bw_left;
				}

				teamhud_pos = hud_sector_pos;
				
				if(vid_conwidth >= 800)
				{
					// teamhud | powerups
					next_sector = bottomright_x - SECWIDTH_WIDE - 13; //bottomright_x - 103 - 6;
					HUDLINE_SLICE({
						hudline_pos_x = hud_sector_pos_x + hud_sector_x + bw_right;
						hudline_x = topright_x - hudline_pos_x - (bottomright_x - 
							((!pwhud_enabled || pwhud_enabled != pw_finalstate)? (bottomright_x - SECWIDTH_NORMAL - 6) : next_sector)) - bw_left;
					})

					// powerups
					if(pw_alpha)
					{
						HUDLINE_SECTOR({
							hud_sector_x = SECWIDTH_NORMAL;
							hud_sector_pos_x = next_sector - 2;
							powerup_pos = hud_sector_pos;
							sector_mod = '0 0 0';
							sector_alphamod = pw_alpha;
						}, BG_SECTOR, BG_BORDER, A_SECTOR, A_BORDER)
					}
					sector_alphamod = 1;
					
					// powerups | scores
					if not(!pwhud_enabled || pwhud_enabled != pw_finalstate)
					{
						HUDLINE_SLICE({
							hudline_pos_x = hud_sector_pos_x + hud_sector_x + bw_right;
							hudline_x = 10 - bw_right - bw_left;
						})
					}
					
					// scores
					HUDLINE_SECTOR({
						hud_sector_x = SECWIDTH_NORMAL;
						hud_sector_pos_x = next_sector + SECWIDTH_NORMAL + 7;
						sector_mod = '0 0 0';
					}, BG_SECTOR, BG_BORDER, A_SECTOR, A_BORDER)
				}
				else // If we don't have enough space, display powerups above the scores sector
				{
					// teamhud | scores
					next_sector = bottomright_x - SECWIDTH_NORMAL - 6;
					HUDLINE_SLICE({
						hudline_pos_x = hud_sector_pos_x + hud_sector_x + bw_right;
						hudline_x = topright_x - hudline_pos_x - (bottomright_x - next_sector) - bw_left;
					})

					// scores
					HUDLINE_SECTOR({
						hud_sector_x = SECWIDTH_NORMAL;
						hud_sector_pos_x = next_sector;
						sector_mod = '0 0 0';
					}, BG_SECTOR, BG_BORDER, A_SECTOR, A_BORDER)
					
					if(pw_alpha)
					{
						// powerups (drawn above scores)
						HUDLINE_SECTOR({
							hud_sector_pos_y = hud_sector_pos_y - hud_sector_y - 12;
							powerup_pos = hud_sector_pos;
							sector_alphamod = pw_alpha;
						}, BG_SECTOR, BG_BORDER, A_SECTOR, A_BORDER)
						sector_alphamod = 1;
					}
				}
				
				// post-scores
				HUDLINE_SLICE({
					hudline_pos_x = hud_sector_pos_x + hud_sector_x + bw_right;
					hudline_x = topright_x;
				})
			}
			else  	/// emulate the nexuiz layout
			{
				float centersector;
				float low = vid_conwidth < 800;
				float low2 = vid_conwidth < 675;
				
				if(hudskin_line_full)
				{
					HUDLINE_SLICE({
						hudline_pos_x = 0;
						hudline_x = topright_x;
					})
				}
				
				// we_need_to_go_wider.jpg
				teamhud_wide = 0;
				if(gametype == GAME_VIP) if(vid_conwidth >= 890)
					teamhud_wide = 1;

				// pre-teamhud
				HUDLINE_SLICE({
					hudline_x = 7 - bw_left;
					next_sector = hudline_x + bw_left;
				})

				// teamhud

				if(th_alpha)
				{
					HUDLINE_SECTOR({
						if(teamhud_wide)
							hud_sector_x = SECWIDTH_WIDE;
						else
							hud_sector_x = SECWIDTH_NORMAL;
						hud_sector_pos_x = next_sector;
						sector_mod = '0 0 0';
						sector_alphamod = th_alpha;
					}, BG_SECTOR, BG_BORDER, A_SECTOR, A_BORDER)
				}
				sector_alphamod = 1;

				if(!teamhud_enabled || teamhud_enabled != th_finalstate)
				{
					hud_sector_x = -bw_left - bw_right;
					hud_sector_pos_x = next_sector;
				}

				teamhud_pos = hud_sector_pos;

				// separator slice:
				// 		teamhud | ammo

				if(low)
				{
					next_sector = hud_sector_pos_x + SECWIDTH_NORMAL + 10;
					centersector = next_sector + SECWIDTH_NORMAL + 10;
				}
				else
				{
					centersector = bottom_x - SECWIDTH_HEALTH/2;
					next_sector = centersector - SECWIDTH_NORMAL - 10;
				}

				HUDLINE_SLICE({
					hudline_pos_x = hud_sector_pos_x + hud_sector_x + bw_right;
					hudline_x = topright_x - hudline_pos_x - (bottomright_x - next_sector) - bw_left;
				})

				// ammo
                ammosector_pos = hud_sector_pos_x = next_sector;
                hud_sector_x = SECWIDTH_NORMAL;
                sector_mod = '0 0 0';
                
                if(ammo_useprogress)
                    DrawProgressBarSector(-bound(0.01, (1 - getstati(STAT_BULLETS_LOADED)/getstati(STAT_BULLETS_MAX)), 1), hud_sector_pos, hud_sector,
                                            BG_SECTOR, BG_BORDER, A_SECTOR, A_BORDER,
                                            BG_SECTOR_PROGRESS, BG_BORDER_PROGRESS, A_SECTOR_PROGRESS, A_BORDER_PROGRESS,
                                            sector_alphamod, hud_sector_drawflag);
				else { HUDLINE_SECTOR({}, BG_SECTOR, BG_BORDER, A_SECTOR, A_BORDER) }
                
				// ammo | health-armor
				HUDLINE_SLICE({
					hudline_x = 8 - bw_left - bw_right;
					hudline_pos_x = hud_sector_pos_x + hud_sector_x + bw_right;
				})

				// health-armor
				//HUDLINE_SECTOR({
                {
					hud_sector_x = SECWIDTH_HEALTH;
					//hud_sector_pos_x = centersector;
					hud_sector_pos_x = hudline_pos_x - bw_right + 8;
					sector_mod = '0 0 0';

					s_health = hud_sector_pos;
				}//, BG_SECTOR_TEAM, BG_BORDER_TEAM, A_SECTOR_TEAM, A_BORDER_TEAM)
				
                vdmg_dmgtakenorigin = '1 0 0' * (hud_sector_pos_x + 0.5 * hud_sector_x) + '0 1 0' * hud_sector_pos_y;
                DrawProgressBarSector(bound(0.01, vhealth/sv_nicehealth, 1), hud_sector_pos, hud_sector,
                                            BG_SECTOR_TEAM, BG_BORDER_TEAM, A_SECTOR_TEAM, A_BORDER_TEAM,
                                            BG_SECTOR_PROGRESS, BG_BORDER_PROGRESS, A_SECTOR_PROGRESS, A_BORDER_PROGRESS,
                                            sector_alphamod, hud_sector_drawflag);
                
				// health-armor | nades
				HUDLINE_SLICE({
					hudline_x = 8 - bw_left - bw_right;
					hudline_pos_x = hud_sector_pos_x + hud_sector_x + bw_right;
				})
				
				if(!low2)
				{
                    if(g_nadgets) {/*
                        HUDLINE_SECTOR({
                            hud_sector_x = SECWIDTH_NORMAL;
                            nadesector_pos = hud_sector_pos_x = hudline_pos_x - bw_right + 8;
                            powerup_pos = hud_sector_pos;
                            sector_mod = '0 0 0';
                            sector_alphamod = 1;
                        }, BG_SECTOR, BG_BORDER, A_SECTOR, A_BORDER)
                        */
                        
                        // nades
                        nadesector_pos = hud_sector_pos_x = hudline_pos_x - bw_right + 8;
                        hud_sector_x = SECWIDTH_NORMAL;
                        sector_mod = '0 0 0';
                        sector_alphamod = 1;
                        
                        DrawProgressBarSector(1-hgregen, hud_sector_pos, hud_sector,
                                                BG_SECTOR, BG_BORDER, A_SECTOR, A_BORDER,
                                                BG_SECTOR_PROGRESS, BG_BORDER_PROGRESS, A_SECTOR_PROGRESS, A_BORDER_PROGRESS,
                                                sector_alphamod, hud_sector_drawflag);
                    } else {
                        hud_sector_pos_x = hudline_pos_x - bw_right + 8;
                        hud_sector_x = -bw_right - bw_left;
                    }
				}
				else
				{
					hud_sector_pos_x = hudline_pos_x - bw_right + 8;
					hud_sector_x = -bw_right - bw_left;
				}
				
				// separator slice:
				// 		powerups/nades | scores
				next_sector = bottomright_x - SECWIDTH_NORMAL - 6;
				HUDLINE_SLICE({
					hudline_pos_x = hud_sector_pos_x + hud_sector_x + bw_right;
					//hudline_x = 10;
					hudline_x = topright_x - hudline_pos_x - (bottomright_x - next_sector) - bw_left;
				})

				// scores
				HUDLINE_SECTOR({
					hud_sector_x = SECWIDTH_NORMAL;
					//hud_sector_pos_x = hudline_pos_x + hudline_x;
					hud_sector_pos_x = next_sector;
					sector_mod = '0 0 0';
				}, BG_SECTOR, BG_BORDER, A_SECTOR, A_BORDER)
                
                if(pw_alpha) {
                    // powerups (drawn above scores)
                    HUDLINE_SECTOR({
                        hud_sector_pos_y = hud_sector_pos_y - hud_sector_y - 12;
                        powerup_pos = hud_sector_pos;
                        sector_alphamod = pw_alpha;
                    }, BG_SECTOR, BG_BORDER, A_SECTOR, A_BORDER)
                    sector_alphamod = 1;
                }
                
				if(low2)
				{
					if(pw_alpha)
					{
						// powerups (drawn above scores)
						HUDLINE_SECTOR({
							hud_sector_pos_y = hud_sector_pos_y - hud_sector_y - 12;
							powerup_pos = hud_sector_pos;
							sector_alphamod = pw_alpha;
						}, BG_SECTOR, BG_BORDER, A_SECTOR, A_BORDER)
						sector_alphamod = 1;
					}
				}

				// post-scores
				HUDLINE_SLICE({
					hudline_pos_x = hud_sector_pos_x + hud_sector_x + bw_right;
					hudline_x = topright_x;
				})
			}
		}

		if(rm_oldhud && sbar_hudselector == 2) // combined health and armor display
		{
			vector v;
			v = healtharmor_maxdamage(health, armor, armorblockpercent);

			vector num_pos;
			num_pos = bottom - '96 28 0';

			x = floor(v_x + 1);

			if(v_z) // fully armored
			{
				// here, armorideal > armor
				drawpic(num_pos + '78 -4.5 0', "gfx/hud/sb_health", '32 32 0', '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
				drawpic(num_pos + '108 -4.5 0', "gfx/hud/sb_armor", '20 20 0', '1 1 1', sbar_alpha_fg * armor / v_y, DRAWFLAG_NORMAL);
			}
			else
			{
				drawpic(num_pos + '108 -4.5 0', "gfx/hud/sb_health", '20 20 0', '1 1 1', sbar_alpha_fg * v_y / armor, DRAWFLAG_NORMAL);
				drawpic(num_pos + '78 -4.5 0', "gfx/hud/sb_armor", '32 32 0', '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
			}
			Sbar_DrawXNum_Colored(num_pos, x, 24, sbar_alpha_fg); // draw the combined health and armor
		}
		else
		{
			vector health_pos, armor_pos;

			if(rm_oldhud)
			{
                vdmg_dmgtakenorigin = bottom - '0 30 0';
				if (sbar_hudselector == 0) { // old style layout with armor left of health
					armor_pos = bottom - '96 28 0';
					health_pos = bottom - '-14 28 0';
				}
				else {
					health_pos = bottom - '96 28 0';
					armor_pos = bottom - '-14 28 0';
				}
			}
			else
			{
				//health_pos = bottomleft - '-10 28 0';
				//armor_pos = bottomleft - '-122 28 0';

				health_pos = s_health + '2 -1 0';
				armor_pos = health_pos + '112 0 0';
			}

			// armor
			x = armor;
			if (x > 0)
			{
				if (x > 45) {
					if(rm_oldhud)
					{
						drawpic(armor_pos + '78 -4.5 0', "gfx/hud/sb_armor", '32 32 0', '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
						Sbar_DrawXNum_Colored(armor_pos, x, 24, sbar_alpha_fg);
					}
					else
					{
						drawpic(armor_pos + '-7 -4.5 0', "gfx/hud/sb_armor", '32 32 0', '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
						Sbar_DrawXNum_Colored(armor_pos + '24 0 0', x, 24, sbar_alpha_fg);
					}
				}
				else {
					if(rm_oldhud)
					{
						drawpic(armor_pos + '78 -4.5 0', "gfx/hud/sb_armor", '32 32 0', '1 1 1', (x+10)/55 * sbar_alpha_fg, DRAWFLAG_NORMAL);
						Sbar_DrawXNum_Colored(armor_pos, x, 24, (x+10)/55 * sbar_alpha_fg);
					}
					else
					{
						drawpic(armor_pos + '-7 -4.5 0', "gfx/hud/sb_armor", '32 32 0', '1 1 1', (x+10)/55 * sbar_alpha_fg, DRAWFLAG_NORMAL);
						Sbar_DrawXNum_Colored(armor_pos + '26 0 0', x, 24, (x+10)/55 * sbar_alpha_fg);
					}
				}
			}

			// health
			x = health;

			if(rm_oldhud)
			{
				drawpic(health_pos + '78 -4.5 0', "gfx/hud/sb_health", '32 32 0', '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
				Sbar_DrawXNum_Colored(health_pos, x, 24, sbar_alpha_fg);
			}
			else
			{
				drawpic(health_pos + '0 -4.5 0', "gfx/hud/sb_health", '32 32 0', '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
				Sbar_DrawXNum_Colored(health_pos + '26 0 0', x, 24, sbar_alpha_fg);
			}
		}

		// weapon icons
		
		if(!g_minstagib)
		{
            float wepcnt;
            
			x = 1.0;
			for(i = 1; i <= 24; ++i) {
                if(weaponimpulse[i-1] >= 0) if(stat_weapons & x) {
                    wepcnt += 1;
                    if(wepcnt >= 2)
                        break;
                }
				x *= 2;
            }
            
            if(wepcnt >= 2) {
                x = 1.0;
                Sbar_DrawWeapon_Clear();
                for(i = 1; i <= 24; ++i)
                {
                    if(weaponimpulse[i-1] >= 0)
                    if(stat_weapons & x)
                    {
                        Sbar_DrawWeapon(i-1, fade, (i == activeweapon), i);
                    }
                    x *= 2;
                }
            }
		}

		// ammo
		//float a; // i will be the ammo type (already declared), a will contain how much ammo there is of type i

		float a_offset;
		float a_unused;
		
		for (i = 0; i < 4; ++i)
		{
			float a = getstati(GetAmmoStat(i));
			if(stat_items & GetAmmoItemCode(i) || a <= 0)
				++a_unused;
		}
		
		a_unused = 4 - a_unused;
		
		for (i = 0; i < 4; ++i) {
			float a = getstati(GetAmmoStat(i)); // how much ammo do we have of type i?
            float isrifle;
            
            if(activeweapon == WEP_CAMPINGRIFLE && a == 999) {
                a = getstati(STAT_BULLETS_LOADED);
                isrifle = TRUE;
                ammo_useprogress = TRUE;
            } else if(GetAmmoItemCode(i) == IT_NAILS) ammo_useprogress = FALSE;
            
            if(a < 0 || (!a && !(stat_items & GetAmmoItemCode(i))))
                continue;
            
			if(g_minstagib || sbar_currentammo || vid_conwidth < (800 + 100 * !rm_oldhud)) {
				if (stat_items & GetAmmoItemCode(i)) {
					if(!a)
					{
						if(ammonotifytime < time)
							ammonotifytime = time + 1;
					}
					else ammonotifytime = 0;

					if(rm_oldhud)
					{
						pos_x = 206;
						pos_y = 33;
						pos = bottom - pos;

						if(vid_conwidth >= 800)
							drawpic(pos + '0 1.5 0', "gfx/hud/sb_ammobg", '107 29 0', '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);

						drawpic(pos + '76 3 0', GetAmmoPicture(i), '24 24 0', '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
						if(!a)
							drawpic_expanding(pos + '76 3 0', GetAmmoPicture(i), '24 24 0', '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL, 1 - bound(0, (ammonotifytime - time)*2, 1));
						
						if(a < (1 + 9 * !isrifle))
							Sbar_DrawXNum(pos + '5 5 0', a, 3, 0, 24, '0.7 0 0', 0, 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
						else
							Sbar_DrawXNum(pos + '5 5 0', a, 3, 0, 24, '1 1 1', 0, 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
					}
					else
					{
						pos_y = 33;
						pos = bottom - pos;
						pos_x = ammosector_pos;

						drawpic(pos + '0 5 0', GetAmmoPicture(i), '24 24 0', '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
						if(!a)
							drawpic_expanding(pos + '0 5 0', GetAmmoPicture(i), '24 24 0', '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL, 1 - bound(0, (ammonotifytime - time)*2, 1));
						if(a < 10 && !isrifle)
							Sbar_DrawXNum(pos + '26 5 0', a, 3, 0, 24, '0.7 0 0', 0, 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
						else
							Sbar_DrawXNum(pos + '26 5 0', a, 3, 0, 24, '1 1 1', 0, 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
					}
				}
			} else {
                if(rm_oldhud)
                    {
                    switch (i) {
                        case 0: pos_x = 286; pos_y = 48; break; // shells
                        case 1: pos_x = 286; pos_y = 26; break; // bullets
                        case 2: pos_x = 200; pos_y = 48; break; // rockets
                        case 3: pos_x = 200; pos_y = 26; break; // cells
                    }

                    pos = bottom - pos;
                    
                    if (stat_items & GetAmmoItemCode(i))
                        drawpic(pos + '0 1.5 0', "gfx/hud/sb_ammobg", '80 22 0', '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
                    drawpic(pos + '56 3 0', GetAmmoPicture(i), '18 18 0', '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
                    
                    if (a < 10) {
                        if(stat_items & GetAmmoItemCode(i))
                            Sbar_DrawXNum(pos + '6 4.5 0', a, 3, 0, 16, '0.7 0 0', 0, 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
                        else
                            Sbar_DrawXNum(pos + '6 4.5 0', a, 3, 0, 16, '0.7 0 0', 0, 0, sbar_alpha_fg * 0.7, DRAWFLAG_NORMAL);
                    } else {
                        if(stat_items & GetAmmoItemCode(i))
                            Sbar_DrawXNum(pos + '6 4.5 0', a, 3, 0, 16, '1 1 1', 0, 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
                        else
                            Sbar_DrawXNum(pos + '6 4.5 0', a, 3, 0, 16, '0.7 0.7 0.7', 0, 0, sbar_alpha_fg * 0.7, DRAWFLAG_NORMAL);
                    }
                }
                else
                {
                    pos_y = 33;
                    pos = bottom - pos;
                    pos_x = ammosector_pos;
                    
                    if(stat_items & GetAmmoItemCode(i) || ((!rm_althud || vid_conwidth < 950) && a_unused == 4 && i == ammo_last))
                    {
                        ammo_last = i;
                        
                        drawpic(pos + '0 5 0', GetAmmoPicture(i), '24 24 0', '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);

                        if(a < (1 + 9 * !isrifle))
                            Sbar_DrawXNum(pos + '26 5 0', a, 3, 0, 24, '0.7 0 0', 0, 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
                        else
                            Sbar_DrawXNum(pos + '26 5 0', a, 3, 0, 24, '1 1 1', 0, 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
                    }
                    else
                    {
                        pos_y -= 10;
                        pos_x = ammosector_pos - bw_left + ((SECWIDTH_NORMAL + bw_right)/2) + a_offset - (42/2) * min(a_unused, ((rm_althud && vid_conwidth >= 950)? 4 : 3));
                        
                        drawpic(pos, GetAmmoPicture(i), '10 10 0', '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
                        Sbar_DrawXNum(pos + '9 1 0', a, 3, 0, 10, '0.7 0.7 0.7', 0, 0, sbar_alpha_fg * 0.7, DRAWFLAG_NORMAL);
                        a_offset += 42;
                    }
                }
			}
		}
		
        // nades
        vector hgapos;
        hgapos_y = vid_conheight - vid_conheight/7;
        
        float hgtype = getstati(STAT_HGTYPE);
        float hgammo = getstati(STAT_HGAMMO);
        float hgdetons = getstati(STAT_HGDETONABLES);
        float hgcd = getstatf(STAT_HGREFIRE) - servertime;
        float adept = getstati(STAT_BUFFS) & BUFF_ADEPT;
        
        if(hgcd > 0) {
            if(hgcd > hg_maxcd) hg_maxcd = hgcd;
        } else hg_maxcd = 0;
        
        if(getstati(STAT_STEALTH)) {
            drawcolorcodedstringcenter(hgapos - sbar_fontsize_y * ('0 2 0' + '0 1 0' * !!adept), strcat(
                                        "^3Shoot or press ^1", strtoupper(getcommandkey("drop weapon", "dropweapon")),
                                        " ^3to ", (adept? "suspend" : "cancel"), " stealth (^1", ftos(getstati(STAT_STEALTH)), " ^3seconds remaining)"),
                                        sbar_fontsize, 0.6, DRAWFLAG_NORMAL);
            if(adept) drawcolorcodedstringcenter(hgapos - sbar_fontsize_y * '0 2 0', strcat(
                                        "^3Press ^1", strtoupper(getcommandkey("drop flag", "+use")),
                                        " ^3to cancel stealth completely"),
                                        sbar_fontsize, 0.6, DRAWFLAG_NORMAL);
        } else if(getstati(STAT_STEALTH_SAVED)) {
            drawcolorcodedstringcenter(hgapos - sbar_fontsize_y * '0 2 0', strcat(
                                        "^3Press ^1", strtoupper(getcommandkey("drop weapon", "dropweapon")),
                                        " ^3to re-enter stealth (^1", ftos(getstati(STAT_STEALTH_SAVED)), " ^3seconds remaining)"),
                                        sbar_fontsize, 0.6, DRAWFLAG_NORMAL);
        } else if(getstatf(STAT_HGSHIELD)) {
            string smsg;
            
            if(getstati(STAT_HGSHIELDSTORE)) {
                float a = getstatf(STAT_HGSHIELD);
                DrawProgress('0.5 0 0' * vid_conwidth + hgapos - sbar_fontsize_y * '0 2.5 0', '15 0 0' * sbar_fontsize_x + '0 5 0',
                             getstati(STAT_HGSHIELDSTORE) / getstati(STAT_HGSHIELDSTOREMAX), min(0.7, a), '1 1 0' - a * '0 0.7 0');
                smsg = strcat("^3Press ^1", strtoupper(getcommandkey("drop weapon", "dropweapon")),
                              " ^3to discharge your ", HG_TypeToExpandedName(hgtype),
                              " for ^1", ftos(getstati(STAT_HGSHIELDSTORE)), " ^3damage");
            } else {
                smsg = strcat("^3Press ^1", strtoupper(getcommandkey("drop weapon", "dropweapon")),
                              " ^3to cancel your ", HG_TypeToExpandedName(hgtype));
            }
            
            drawcolorcodedstringcenter(hgapos - sbar_fontsize_y * '0 2 0', smsg, sbar_fontsize, 0.6, DRAWFLAG_NORMAL);
        } else if(hgdetons)
            drawcolorcodedstringcenter(hgapos - sbar_fontsize_y * '0 2 0', strcat(
                                        "^3Press ^1", strtoupper(getcommandkey("drop weapon", "dropweapon")),
                                        " ^3to trigger your ", HG_TypeToExpandedName(hgtype),
                                        ((hgdetons > 1)? strcat("s (^2", ftos(hgdetons), "^3)") : "")),
                                        sbar_fontsize, 0.6, DRAWFLAG_NORMAL);
        else if(hgtype == HG_GG && hgammo)
            drawcolorcodedstringcenter(hgapos - sbar_fontsize_y * '0 2 0', strcat("^3Press ^1", strtoupper(getcommandkey("hook / nadget key", "+hook")), " ^3to win!"), sbar_fontsize, 0.6, DRAWFLAG_NORMAL);
            
        
        if(nadesector_pos) {
            pos_y = 33;
            pos = bottom - pos;
            pos_x = nadesector_pos;
            
            string hgicon = HG_TypeToIcon(hgtype, TRUE, (getstati(STAT_BUFFS) & BUFF_ADEPT));
            vector hgcolor = '1 1 1' - '0.3 0.8 0.8' * getstati(STAT_HGREGENPAUSED);
            vector hgsize = '32 32 0';
            
            if(hgcd > 0) {
                float cdh = hgsize_y * (hgcd / hg_maxcd);
                drawsetcliparea(pos_x, pos_y, hgsize_x, cdh);
                drawpic(pos, hgicon, hgsize, hgcolor, sbar_alpha_fg * 0.3, DRAWFLAG_NORMAL);
                drawsetcliparea(pos_x, pos_y + cdh, hgsize_x, hgsize_y);
                drawpic(pos, hgicon, hgsize, hgcolor, sbar_alpha_fg, DRAWFLAG_NORMAL);
                drawresetcliparea();
            } else
                drawpic(pos, hgicon, hgsize, hgcolor, sbar_alpha_fg, DRAWFLAG_NORMAL);
            
            Sbar_DrawXNum(pos + '26 5 0', hgammo, 3, 0, 24, '1 1 1' - '0 1 1' * (!hgammo), 0, 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
            
            if(rm_shownadgetregen)
            if(getstatf(STAT_HGREGENRATE)) {
                drawfont = sbar_bigfont;
                float rtime = getstatf(STAT_HGREGEN) / getstatf(STAT_HGREGENRATE);
                string hgtxt = ftos(rtime);
                
                float dotpos = strstrofs(hgtxt, ".", 0);
                if(dotpos >= 0)
                    hgtxt = substring(hgtxt, 0, dotpos + 2);
                else
                    hgtxt = strcat(hgtxt, ".0");
                
                float tsize = hgsize_x / stringwidth(hgtxt, FALSE);
                drawstring(pos + '0.5 0 0' * (SECWIDTH_NORMAL - hgsize_x) + '0 0.5 0' * (hgsize_y - tsize), hgtxt, '1 1 0' * tsize, '1 0 0' + '0 1 0' * (rtime >= 5) + '0 0 1' * (rtime >= 10), 1, DRAWFLAG_NORMAL);
                
                drawfont = sbar_font;
            }
        } else {
            // HUD doesn't support the nade sector - fallback to the old display method
            
            if(hgammo) {
                drawcolorcodedstringcenter(hgapos, strcat(HG_TypeToExpandedName(hgtype), "s: ^3", ftos(hgammo)), sbar_fontsize, 0.6, DRAWFLAG_NORMAL);
            }
            
            if(hgregen && hgregen != 1) {
                vector hgrsize = '70 3 0';
                hgapos_y += 10;
                hgapos_x = (vid_conwidth - hgrsize_x) * 0.5;
                hgrsize_x *= hgregen;
                drawfill(hgapos, hgrsize, '1 1 1' - '0 0.5 0.5' * getstati(STAT_HGREGENPAUSED), 0.5, DRAWFLAG_NORMAL);
            }
        }
        
		// fuel ammo
		if(rm_oldhud)
		{
			float a = getstati(GetAmmoStat(4)); // how much fuel do we have?

			if (a > 0) { // if we have fuel, draw the amount
				float invincibility_time, dt;
				invincibility_time = getstatf(STAT_INVINCIBLE_FINISHED);
				dt = invincibility_time - time;
				if (vid_conwidth >= 800) {
					if (dt > 0) { // if the invincibility timer is active, draw fuel ammo elsewhere
						pos_x = bottom_x + 140;
						pos_y = bottom_y - 72;
					}
					else { // if the invincibility timer is inactive, draw the fuel ammo there (it's rare to have invincibility + fuel anyway)
						pos_x = bottom_x + 140;
						pos_y = bottom_y - 20;
					}
				}
				else { // draw fuel on top of ammo if vid_conwidth < 800
					pos_x = bottom_x - 200;
					pos_y = bottom_y - 45;
				}
				drawpic(pos - '0 2 0' + '52 0 0', GetAmmoPicture(4), '20 20 0', '1 1 1', sbar_alpha_fg, DRAWFLAG_NORMAL);
				if (a > 10)
					Sbar_DrawXNum(pos, a, 3, 0, 16, '1 1 1', 0, 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
				else
					Sbar_DrawXNum(pos, a, 3, 0, 16, '0.7 0 0', 0, 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
			}
		}


		// draw scores and timer
		Sbar_Score();
		Sbar_Timer();

		// draw strength/invincibility icon and timer
		//if(rm_oldhud)
			CSQC_Strength_Timer(powerup_pos);

		// draw gametype specific icons

		if(gametype != GAME_DEATHMATCH && gametype != GAME_TEAM_DEATHMATCH)
			teamhud_enabled = 1;
		else
			teamhud_enabled = 0;

		if(gametype == GAME_KEYHUNT)
			CSQC_kh_hud(teamhud_pos);
		else if(gametype == GAME_CTF)
			CSQC_ctf_hud(teamhud_pos);
		else if(gametype == GAME_FREEZETAG || gametype == GAME_JAILBREAK || gametype == GAME_CLANARENA)
			CSQC_ft_hud(teamhud_pos);
        else if(gametype == GAME_DOMINATION)
            CSQC_dom_hud(teamhud_pos);
        else if(gametype == GAME_TOTAL_DOMINATION)
            CSQC_dom_hud(teamhud_pos);
        // fuck this hud, not supported anyway
		//else if(gametype == GAME_NEXBALL)
		//	CSQC_nb_hud();
		else if(gametype == GAME_VIP)
			CSQC_vip_hud(teamhud_pos);
	}
    
    if(g_nadgets)
        Sbar_DrawHGBonus();
    Sbar_DrawBuffs();

	#ifdef RM_SUPPORT_VOTEGFX
	if(rm_legacyvote || oldengine)
	{
	#endif
		if(vote_waiting)
		{
			//s = strcat("^2A vote has been called for ^1", vote_called_vote);
			//o = Sbar_DrawNoteLine(o, s);

			if(vote_waiting_for_me)
			{
				o2 = Sbar_DrawCenterNoteLine(o2, "");

				s = strcat("^2Vote now! ^1", vote_called_vote);
				o2 = Sbar_DrawCenterNoteLine(o2, s);

				/*s = strcat(blinkcolor, "Press ^3", getcommandkey("vote yes", "vyes"), blinkcolor, " to accept");
				o = Sbar_DrawNoteLine(o, s);

				s = strcat(blinkcolor, "Press ^3", getcommandkey("vote no", "vno"), blinkcolor, " to reject");
				o = Sbar_DrawNoteLine(o, s);

				s = strcat(blinkcolor, "Press ^3", getcommandkey("vote abstain", "vabstain"), blinkcolor, " to abstain");
				o = Sbar_DrawNoteLine(o, s);*/

				s = strcat("^3", getcommandkey("vote yes", "vyes"), "^2 to accept, ^3", getcommandkey("vote no", "vno"), "^2 to reject");
				o2 = Sbar_DrawCenterNoteLine(o2, s);

				s = vote_statstring;
				o2 = Sbar_DrawCenterNoteLine(o2, s);
			}
			else
			{
				s = strcat("^2Vote: ^1", vote_called_vote);
				o = Sbar_DrawNoteLine(o, s);

				s = vote_statstring;
				o = Sbar_DrawNoteLine(o, s);
			}
		}
	#ifdef RM_SUPPORT_VOTEGFX
	}
	else
	{
		if(vote_active != vote_prev) {
			//print("vote_active != vote_prev\n");
			vote_change = time;
			vote_prev = bound(0, vote_active, 1);
		}

		if(vote_active)
		{
			//print("vote_active\n");
			vote_alpha = bound(0, (time - vote_change) * 2, 1);
		}
		else
		{
			//print("!vote_active\n");
			vote_alpha = bound(0, 1 - (time - vote_change) * 2, 1);
		}

		if(vote_alpha) {
			//print("DRAWING VOTE, alpha = ", ftos(vote_alpha), "\n");

			float a = vote_alpha * bound(0.75, 1 - vote_highlighted, 1);

			/*
			if (teamplay)
				color =  GetTeamRGB(myteam) * sbar_color_bg_team;
			else {
				color_x = 1;
				color_y = 1;
				color_z = 0;
			}*/

			color = colormapPaletteColor(15, 0);

			vector voteorigin; // = bottomright - '290 135 0';

			if(vote_highlighted)
			{
				s = strcat(ftos(vote_needed), " votes required");
				voteorigin = bottomright - '290 135 0';
			}
			else
			{
				s = strcat("Vote now! ", getcommandkey("vote yes", "vyes"), " to accept, ", getcommandkey("vote no", "vno"), " to reject");
				voteorigin_x = vid_conwidth / 2 - 145;
				voteorigin_y = vid_conheight * 0.5 + vid_conheight/4 - 37;
			}

			vector votesize = '290 70 0';
			drawpic(voteorigin, "gfx/hud/voteprogress_back", votesize, color, (vote_highlighted? 0 : a * sbar_alpha_bg), DRAWFLAG_NORMAL);


			drawstring_svn(voteorigin + '0.5 0 0' * votesize_x + '0 0.1 0' * votesize_y - '1 0 0' * stringwidth_svn(s, FALSE, '6 0 0'), s, '12 12 0', '1 1 1', a * sbar_alpha_fg, DRAWFLAG_NORMAL);
			s = textShortenToWidth_svn(vote_called_vote, votesize_x * 0.96, '10 0 0', stringwidth_colors_svn);
			drawcolorcodedstring(voteorigin + '0.52 0 0' * votesize_x + '0 0.3 0' * votesize_y - '1 0 0' * stringwidth_svn(s, TRUE, '5 0 0'), s, '10 10 0', a * sbar_alpha_fg, DRAWFLAG_NORMAL);

			// print the yes/no counts
			s = strcat("Yes: ", ftos(vote_yescount));
			drawstring_svn(voteorigin + '0 0.6 0' * votesize_y + '0.02 0 0' * votesize_x, s, '12 12 0', '0 1 0', a * sbar_alpha_fg, DRAWFLAG_NORMAL);
			s = strcat("No: ", ftos(vote_nocount));
			drawstring_svn(voteorigin + '0 0.6 0' * votesize_y + '0.98 0 0' * votesize_x - '1 0 0' * stringwidth_svn(s, FALSE, '12 0 0'), s, '12 12 0', '1 0 0', a * sbar_alpha_fg, DRAWFLAG_NORMAL);

			// draw the progress bars
			drawsetcliparea(voteorigin_x, voteorigin_y, votesize_x * 0.5 * (vote_yescount/vote_needed), votesize_y);
			drawpic(voteorigin, "gfx/hud/voteprogress_prog", votesize, '0 1 0', a * sbar_alpha_fg, DRAWFLAG_NORMAL);

			drawsetcliparea(voteorigin_x + votesize_x - votesize_x * 0.5 * (vote_nocount/vote_needed), voteorigin_y, votesize_x * 0.5, votesize_y);
			drawpic(voteorigin, "gfx/hud/voteprogress_prog", votesize, '1 0 0', a * sbar_alpha_fg, DRAWFLAG_NORMAL);

			// draw the highlights
			if(vote_highlighted == 1) {
				drawsetcliparea(voteorigin_x, voteorigin_y, votesize_x * 0.5, votesize_y);
				drawpic(voteorigin, "gfx/hud/voteprogress_voted", votesize, '0 1 0', a * sbar_alpha_fg, DRAWFLAG_NORMAL);
			}
			else if(vote_highlighted == 2) {
				drawsetcliparea(voteorigin_x + 0.5 * votesize_x, voteorigin_y, votesize_x * 0.5, votesize_y);
				drawpic(voteorigin, "gfx/hud/voteprogress_voted", votesize, '1 0 0', a * sbar_alpha_fg, DRAWFLAG_NORMAL);
			}

			drawresetcliparea();
		}
		else if(!vote_active) {
			vote_highlighted = 0;
		}
	}
	#endif
    
    if(getstati(STAT_QUEUE) && !intermission) {
        s = strcat("^1Maximum player limit exceeded, you are ^3", ScoreString(SFL_RANK, getstati(STAT_QUEUE)), " ^1in the queue");
        o = Sbar_DrawNoteLine(o, s);
        s = "^1You will automatically join the game when there's a free slot";
        o = Sbar_DrawNoteLine(o, s);
        s = strcat("^1Press ^3", getcommandkey("spectate", "spec"), " ^1to leave the queue");
        o = Sbar_DrawNoteLine(o, s);
    }
    
	Sbar_ServerInfo();

	if(!rm_hidewatermark)
	{
		vector position;
		position = '0 0 0';
		position_y = vid_conheight - 8;

		dummyfunction(0, 0, 0, 0, 0, 0, 0, 0);
		drawstring(position, rm_watermark, '8 8 0', '1 1 1', 0.2, DRAWFLAG_NORMAL);
	}

/*
	if(tmpmadoka_fadetime >= time)
	{
		position_x = vid_conwidth;
		position_y = vid_conheight;
		drawfill('0 0 0', position, '1 0 0', bound(0, 1 - 4 * (time - (tmpmadoka_fadetime- 1)), 0.5), DRAWFLAG_ADDITIVE);
	}
*/

	if(gui_reloading)
	{
		drawfill('0 0 0', '1 0 0' * vid_conwidth + '0 1 0' * vid_conheight, '0 0 0', 1, DRAWFLAG_NORMAL);
		
		vector lpic;
		lpic = drawgetimagesize("gfx/loading.tga");
		vector lpos;
		lpos_x = (vid_conwidth  - lpic_x) * 0.5;
		lpos_y = (vid_conheight - lpic_y) * 0.5;
		drawpic(lpos, "gfx/loading.tga", lpic, '1 1 1', 1, DRAWFLAG_NORMAL);
	}
	
    hgregen += (getstatf(STAT_HGREGEN) / getstatf(STAT_HGREGENMAX) - hgregen) * drawframetime * 3;
}

// CTF HUD
//float redflag_prevframe, blueflag_prevframe; // status during previous frame
float redflag_prevstatus, blueflag_prevstatus; // last remembered status
float redflag_statuschange_time, blueflag_statuschange_time; // time when the status changed

void CSQC_ctf_hudreset(void)
{
	redflag_prevstatus = blueflag_prevstatus = redflag_statuschange_time = blueflag_statuschange_time = 0;
	//redflag_prevframe = blueflag_prevframe = 0;
}

void CSQC_ctf_hud(vector hudpos)
{
	vector bottomleft, redflag_pos, blueflag_pos, sz;
	float f; // every function should have that
	bottomleft_x = 0;
	if(rm_oldhud)
		bottomleft_y = vid_conheight;
	else
		bottomleft_y = vid_conheight - 10;
	bottomleft_z = 0;

	float redflag, blueflag; // current status
	float redflag_statuschange_elapsedtime, blueflag_statuschange_elapsedtime; // time since the status changed
	float stat_items;

	stat_items = getstati(STAT_ITEMS);
	redflag = (stat_items/IT_RED_FLAG_TAKEN) & 3;
	blueflag = (stat_items/IT_BLUE_FLAG_TAKEN) & 3;

/*
	// when status CHANGES, set old status into prevstatus and current status into status
	if (redflag != redflag_prevframe)
	{
		redflag_statuschange_time = time;
		redflag_prevstatus = redflag_prevframe;
		redflag_prevframe = redflag;
	}

	if (blueflag != blueflag_prevframe)
	{
		blueflag_statuschange_time = time;
		blueflag_prevstatus = blueflag_prevframe;
		blueflag_prevframe = blueflag;
	}
*/

	redflag_statuschange_elapsedtime = time - redflag_statuschange_time;
	blueflag_statuschange_elapsedtime = time - blueflag_statuschange_time;

	float BLINK_FACTOR = 0.15;
	float BLINK_BASE = 0.85;
	// note:
	//   RMS = sqrt(BLINK_BASE^2 + 0.5 * BLINK_FACTOR^2)
	// thus
	//   BLINK_BASE = sqrt(RMS^2 - 0.5 * BLINK_FACTOR^2)
	// ensure RMS == 1
	float BLINK_FREQ = 5; // circle frequency, = 2*pi*frequency in hertz

	rm_oldflags = rm_oldhud;

	string red_icon, red_icon_prevstatus;
	float red_alpha, red_alpha_prevstatus;
	red_alpha = red_alpha_prevstatus = 1;
	switch(redflag) {
		case 1: red_icon = (rm_oldflags? "gfx/hud/sb_flag_red_taken" : "gfx/hud/rm_flag_red_taken"); break;
		case 2: red_icon = (rm_oldflags? "gfx/hud/sb_flag_red_lost" : "gfx/hud/rm_flag_red_lost"); break;
		case 3: red_icon = (rm_oldflags? "gfx/hud/sb_flag_red_carrying" : "gfx/hud/rm_flag_red_carrying"); red_alpha = BLINK_BASE + BLINK_FACTOR * cos(time * BLINK_FREQ); break;
		default:
			if((stat_items & IT_CTF_SHIELDED) && (myteam == COLOR_TEAM2))
				red_icon = "gfx/hud/sb_flag_red_shielded";
			else
				red_icon = string_null;
			break;
	}
	switch(redflag_prevstatus) {
		case 1: red_icon_prevstatus = (rm_oldflags? "gfx/hud/sb_flag_red_taken" : "gfx/hud/rm_flag_red_taken"); break;
		case 2: red_icon_prevstatus = (rm_oldflags? "gfx/hud/sb_flag_red_lost" : "gfx/hud/rm_flag_red_lost"); break;
		case 3: red_icon_prevstatus = (rm_oldflags? "gfx/hud/sb_flag_red_carrying" : "gfx/hud/rm_flag_red_carrying"); red_alpha_prevstatus = BLINK_BASE + BLINK_FACTOR * cos(time * BLINK_FREQ); break;
		default:
			if(redflag == 3)
				red_icon_prevstatus = (rm_oldflags? "gfx/hud/sb_flag_red_carrying" : "gfx/hud/rm_flag_red_carrying"); // make it more visible
			else if((stat_items & IT_CTF_SHIELDED) && (myteam == COLOR_TEAM2))
				red_icon_prevstatus = "gfx/hud/sb_flag_red_shielded";
			else
				red_icon_prevstatus = string_null;
			break;
	}

	string blue_icon, blue_icon_prevstatus;
	float blue_alpha, blue_alpha_prevstatus;
	blue_alpha = blue_alpha_prevstatus = 1;
	switch(blueflag) {
		case 1: blue_icon = (rm_oldflags? "gfx/hud/sb_flag_blue_taken" : "gfx/hud/rm_flag_blue_taken"); break;
		case 2: blue_icon = (rm_oldflags? "gfx/hud/sb_flag_blue_lost" : "gfx/hud/rm_flag_blue_lost"); break;
		case 3: blue_icon = (rm_oldflags? "gfx/hud/sb_flag_blue_carrying" : "gfx/hud/rm_flag_blue_carrying"); blue_alpha = BLINK_BASE + BLINK_FACTOR * cos(time * BLINK_FREQ); break;
		default:
			if((stat_items & IT_CTF_SHIELDED) && (myteam == COLOR_TEAM1))
				blue_icon = "gfx/hud/sb_flag_blue_shielded";
			else
				blue_icon = string_null;
			break;
	}
	switch(blueflag_prevstatus) {
		case 1: blue_icon_prevstatus = (rm_oldflags? "gfx/hud/sb_flag_blue_taken" : "gfx/hud/rm_flag_blue_taken"); break;
		case 2: blue_icon_prevstatus = (rm_oldflags? "gfx/hud/sb_flag_blue_lost" : "gfx/hud/rm_flag_blue_lost"); break;
		case 3: blue_icon_prevstatus = (rm_oldflags? "gfx/hud/sb_flag_blue_carrying" : "gfx/hud/rm_flag_blue_carrying"); blue_alpha_prevstatus = BLINK_BASE + BLINK_FACTOR * cos(time * BLINK_FREQ); break;
		default:
			if(blueflag == 3)
				blue_icon_prevstatus = (rm_oldflags? "gfx/hud/sb_flag_blue_carrying" : "gfx/hud/rm_flag_blue_carrying"); // make it more visible
			else if((stat_items & IT_CTF_SHIELDED) && (myteam == COLOR_TEAM1))
				blue_icon_prevstatus = "gfx/hud/sb_flag_blue_shielded";
			else
				blue_icon_prevstatus = string_null;
			break;
	}

	hudpos_x += 55;
	hudpos_y -= 17;

	if (myteam == COLOR_TEAM1) { // always draw own flag on left
		if(rm_oldhud)
		{
			redflag_pos = bottomleft - '-4 50 0';
			blueflag_pos = bottomleft - '-62 50 0';
		}
		else
		{
			if(rm_althud)
			{
				redflag_pos = hudpos;
				blueflag_pos = redflag_pos - '60 0 0';
			}
			else
			{
				blueflag_pos = hudpos;
				redflag_pos = blueflag_pos - '60 0 0';
			}
		}
	} else {
		if(rm_oldhud)
		{
			blueflag_pos = bottomleft - '-4 50 0';
			redflag_pos = bottomleft - '-62 50 0';
		}
		else
		{
			if(rm_althud)
			{
				blueflag_pos = hudpos;
				redflag_pos = blueflag_pos - '60 0 0';
			}
			else
			{
				redflag_pos = hudpos;
				blueflag_pos = redflag_pos - '60 0 0';
			}
		}
	}

	sz = '52 52 0';

	teamhud_enabled = 0;

	f = bound(0, redflag_statuschange_elapsedtime*2, 1);
	if(red_icon_prevstatus && f < 1)
	{
		drawpic_expanding(redflag_pos, red_icon_prevstatus, sz, '1 1 1', sbar_alpha_fg * red_alpha_prevstatus, DRAWFLAG_NORMAL, f);
		teamhud_enabled = 1;
	}
	if(red_icon)
	{
		drawpic(redflag_pos, red_icon, sz, '1 1 1', sbar_alpha_fg * red_alpha * f, DRAWFLAG_NORMAL);
		teamhud_enabled = 1;
	}

	f = bound(0, blueflag_statuschange_elapsedtime*2, 1);
	if(blue_icon_prevstatus && f < 1)
	{
		drawpic_expanding(blueflag_pos, blue_icon_prevstatus, sz, '1 1 1', sbar_alpha_fg * blue_alpha_prevstatus, DRAWFLAG_NORMAL, f);
		teamhud_enabled = 1;
	}
	if(blue_icon)
	{
		drawpic(blueflag_pos, blue_icon, sz, '1 1 1', sbar_alpha_fg * blue_alpha * f, DRAWFLAG_NORMAL);
		teamhud_enabled = 1;
	}
}

// Keyhunt HUD
float kh_runheretime;

void CSQC_kh_hudreset(void)
{
	kh_runheretime = 0;
}

void CSQC_kh_hud(vector hudpos)
{
	float kh_keys;
	float keyteam;
	float a, aa;
	vector p, pa, kh_size, kh_asize;

	vector bottomleft;
	bottomleft_x = 0;
	bottomleft_y = vid_conheight;
	bottomleft_z = 0;

	p_x = 6;
	p_y = vid_conheight - 34 - 3;
	p_z = 0;

	//hudpos_x += 52;

	local entity tm;
	local float numteams;

	kh_keys = getstati(STAT_KH_KEYS);

	if(rm_oldhud)
	{
		p_x = 6;
		p_y = vid_conheight - 34 - 3;
		p_z = 0;

		kh_size = '19 34 0';
		kh_asize = '19 10 0';
		pa = p + '0 -10 0';
	}
	else
	{
		for(tm = teams.sort_next; tm; tm = tm.sort_next)
			if(tm.team != COLOR_SPECTATOR)
				if(tm.team_size)
					numteams += 1;

		hudpos_x += 51;
		hudpos_y -= 3;

		kh_size = '19 34 0';
		kh_asize = '19 10 0';

		hudpos_x += 5;
		hudpos_x -= 12 * numteams;

		p = hudpos;
		pa = p + '0 -10 0';
	}

	float i, key;

	float keycount;
	keycount = 0;
	for(i = 0; i < 4; ++i)
	{
		key = floor(kh_keys / pow(32, i)) & 31;
		keyteam = key - 1;
		if(keyteam == 30 && keycount <= 4)
			keycount += 4;
		if(keyteam == myteam || keyteam == -1 || keyteam == 30)
			keycount += 1;
	}
	// this yields 8 exactly if "RUN HERE" shows

	if(keycount == 8)
	{
		if(!kh_runheretime)
			kh_runheretime = time;
		pa_y -= fabs(sin((time - kh_runheretime) * 3.5)) * 6; // make the arrows jump in case of RUN HERE
	}
	else
		kh_runheretime = 0;

	teamhud_enabled = 0;
	for(i = 0; i < 4; ++i)
	{
		key = floor(kh_keys / pow(32, i)) & 31;
		keyteam = key - 1;
		switch(keyteam)
		{
			case 30: // my key
				keyteam = myteam;
				a = 1;
				aa = 1;
				break;
			case -1: // no key
				a = 0;
				aa = 0;
				break;
			default: // owned or dropped
				a = 0.2;
				aa = 0.5;
				break;
		}
		if(a > 0)
		{
			switch(keyteam)
			{
				case COLOR_TEAM1:
					drawpic (pa, "gfx/hud/sb_kh_redarrow", kh_asize, '1 1 1', aa, DRAWFLAG_NORMAL);  // show 30% alpha key
					break;
				case COLOR_TEAM2:
					drawpic (pa, "gfx/hud/sb_kh_bluearrow", kh_asize, '1 1 1', aa, DRAWFLAG_NORMAL);  // show 30% alpha key
					break;
				case COLOR_TEAM3:
					drawpic (pa, "gfx/hud/sb_kh_yellowarrow", kh_asize, '1 1 1', aa, DRAWFLAG_NORMAL);  // show 30% alpha key
					break;
				case COLOR_TEAM4:
					drawpic (pa, "gfx/hud/sb_kh_pinkarrow", kh_asize, '1 1 1', aa, DRAWFLAG_NORMAL);  // show 30% alpha key
					break;
				default:
					break;
			}
			switch(i) // YAY! switch(i) inside a for loop for i. DailyWTF, here we come!
			{
				case 0:
					drawpic (p, "gfx/hud/sb_kh_red", kh_size, '1 1 1', a, DRAWFLAG_NORMAL);  // show 30% alpha key
					break;
				case 1:
					drawpic (p, "gfx/hud/sb_kh_blue", kh_size, '1 1 1', a, DRAWFLAG_NORMAL);  // show 30% alpha key
					break;
				case 2:
					drawpic (p, "gfx/hud/sb_kh_yellow", kh_size, '1 1 1', a, DRAWFLAG_NORMAL);  // show 30% alpha key
					break;
				case 3:
					drawpic (p, "gfx/hud/sb_kh_pink", kh_size, '1 1 1', a, DRAWFLAG_NORMAL);  // show 30% alpha key
					break;
			}

			teamhud_enabled = 1;
		}
		p_x += 24;
		pa_x += 24;
	}
}

//Nexball HUD
#define NBPB_SIZE '96 38 0'
#define NBPB_BT 2                   //thickness
#define NBPB_BRGB '1 1 1'
#define NBPB_BALPH 1                //alpha
#define NBPB_BFLAG DRAWFLAG_NORMAL
#define NBPB_IALPH 0.4
#define NBPB_IFLAG DRAWFLAG_NORMAL
#define NBPB_IRGB '0.7 0.1 0'

void CSQC_nb_hud(void)
{
	float stat_items, nb_pb_starttime, dt, p;
	vector pos;

	stat_items = getstati(STAT_ITEMS);
	nb_pb_starttime = getstatf(STAT_NB_METERSTART);

	pos_x = 4;
	pos_y = vid_conheight - 42;
	pos_z = 0;

	//Manage the progress bar if any
	if (nb_pb_starttime > 0)
	{
		vector s;
		dt = mod(time - nb_pb_starttime, nb_pb_period);
		// one period of positive triangle
		p = 2 * dt / nb_pb_period;
		if (p > 1)
			p = 2 - p;

		s = NBPB_SIZE;
		//Draw the filling
		drawfill(pos, p * s_x * '1 0 0' + s_y * '0 1 0', NBPB_IRGB, NBPB_IALPH, NBPB_IFLAG);

		//Draw the box
		s = NBPB_SIZE;
		drawline(NBPB_BT, pos    , pos + '1 0 0' * s_x, NBPB_BRGB, NBPB_BALPH, NBPB_BFLAG);
		drawline(NBPB_BT, pos    , pos + '0 1 0' * s_y, NBPB_BRGB, NBPB_BALPH, NBPB_BFLAG);
		drawline(NBPB_BT, pos + s, pos + '1 0 0' * s_x, NBPB_BRGB, NBPB_BALPH, NBPB_BFLAG);
		drawline(NBPB_BT, pos + s, pos + '0 1 0' * s_y, NBPB_BRGB, NBPB_BALPH, NBPB_BFLAG);
	}

	pos_x += 12; //horizontal margin to the picture
	pos_y += 2; //vertical margin to the picture

	if (stat_items & IT_KEY1)
		drawpic(pos, "gfx/hud/sb_nexball_carrying", '80 34 0', '1 1 1', 1, DRAWFLAG_NORMAL);
}

#define CSQC_hud_RedBlueStatCommon(v,r,b) CSQC_hud_TeamStatCommon(v,r,b,-1,-1)
void CSQC_hud_TeamStatCommon(vector hudpos, float redstat, float bluestat, float yellowstat, float pinkstat)
{
	hudpos_x -= 70;
	hudpos_y -= 1;

	vector position;
	position = hudpos;

	if(yellowstat < 0)
	{
		if(redstat > 9)
			position_x += 24;

		Sbar_DrawXNum(position, redstat, 4, 0, 24, GetTeamRGB(COLOR_TEAM1) * 0.8 + '0.2 0.2 0.2', 0, 0, sbar_alpha_fg, DRAWFLAG_NORMAL);

		position = hudpos;
		position_x += SECWIDTH_NORMAL - 29;

		Sbar_DrawXNum(position, bluestat, 4, 0, 24, GetTeamRGB(COLOR_TEAM2) * 0.8 + '0.2 0.2 0.2', 0, 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
		return;
	}
	
	local float i, colour, stat;
	local vector offs;
	for(i = 0; i < 4; ++i)
	{
		position = hudpos;
		
		switch(i)	// haha
		{
			case 0:
				colour = COLOR_TEAM1;
				stat = redstat;
				break;
			
			case 1:
				colour = COLOR_TEAM2;
				stat = bluestat;
				break;
			
			case 2:
				colour = COLOR_TEAM3;
				stat = yellowstat;
				break;
			
			case 3:
				if(pinkstat < 0)
					continue;
				
				colour = COLOR_TEAM4;
				stat = pinkstat;
				break;
		}
		
		//print("Color = ", ftos(colour), "; stat = ", ftos(stat), "\n");
		
		if(colour == myteam)
		{
			position = hudpos;
			
			if(stat > 9)
				position_x += 24;
				
			Sbar_DrawXNum(position, stat, 4, 0, 24, GetTeamRGB(colour) * 0.8 + '0.2 0.2 0.2', 0, 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
			continue;
		}
		
		position = hudpos;
		position_x += 125;
		Sbar_DrawXNum(position+offs, stat, 4, 0, 12, GetTeamRGB(colour) * 0.8 + '0.2 0.2 0.2', 0, 0, sbar_alpha_fg, DRAWFLAG_NORMAL);
		offs_y += 12;
		
		if(offs_y >= 24)
		{
			offs_x -= 24;
			offs_y -= 12;
		}
	}
}

//Freezetag HUD

void CSQC_ft_hud(vector hudpos)
{
	float redalive, bluealive, yellowalive, pinkalive;

	redalive = getstati(STAT_REDALIVE);
	bluealive = getstati(STAT_BLUEALIVE);
	
	if(gametype == GAME_JAILBREAK)
		yellowalive = pinkalive = -1;
	else {
		yellowalive = getstati(STAT_YELLOWALIVE);
		pinkalive = getstati(STAT_PINKALIVE);
	}

	teamhud_enabled = 1;

	if(rm_oldhud)
	{
		vector position;
		position = '0 0 0';
		
		position_y = vid_conheight - sbar_fontsize_y * (3 + ((yellowalive > -1) + (pinkalive > -1)));

		dummyfunction(0, 0, 0, 0, 0, 0, 0, 0);
		drawcolorcodedstring(position, strcat("^1Red alive^7: ", ftos(redalive)), sbar_fontsize, 1, DRAWFLAG_NORMAL);

		position_y += sbar_fontsize_y;
		dummyfunction(0, 0, 0, 0, 0, 0, 0, 0);
		drawcolorcodedstring(position, strcat("^4Blue alive^7: ", ftos(bluealive)), sbar_fontsize, 1, DRAWFLAG_NORMAL);
		
		if(yellowalive < 0)
			return;
		
		position_y += sbar_fontsize_y;
		dummyfunction(0, 0, 0, 0, 0, 0, 0, 0);
		drawcolorcodedstring(position, strcat("^3Yellow alive^7: ", ftos(yellowalive)), sbar_fontsize, 1, DRAWFLAG_NORMAL);
		
		if(pinkalive < 0)
			return;
		
		position_y += sbar_fontsize_y;
		dummyfunction(0, 0, 0, 0, 0, 0, 0, 0);
		drawcolorcodedstring(position, strcat("^6Pink alive^7: ", ftos(pinkalive)), sbar_fontsize, 1, DRAWFLAG_NORMAL);
	}
	else
		CSQC_hud_TeamStatCommon(hudpos, redalive, bluealive, yellowalive, pinkalive);
}

//Domination / Total Domination HUD

void CSQC_dom_hud(vector hudpos)
{
	float redpoints, bluepoints, totalpoints; //Currently supports only red and blue teams

	redpoints = getstati(STAT_REDPOINTS);
	bluepoints = getstati(STAT_BLUEPOINTS);
    totalpoints = getstati(STAT_TOTALPOINTS);

	teamhud_enabled = 1;

	if(rm_oldhud)
	{
		vector position;
		position = '0 0 0';

		position_y = vid_conheight - sbar_fontsize_y*2;
		dummyfunction(0, 0, 0, 0, 0, 0, 0, 0);
		drawcolorcodedstring(position, strcat("^4Blue points^7: ", ftos(bluepoints), "/", ftos(totalpoints)), sbar_fontsize, 1, DRAWFLAG_NORMAL);

		position_y -= sbar_fontsize_y;
		dummyfunction(0, 0, 0, 0, 0, 0, 0, 0);
		drawcolorcodedstring(position, strcat("^1Red points^7: ", ftos(redpoints), "/", ftos(totalpoints)), sbar_fontsize, 1, DRAWFLAG_NORMAL);
	}
	else
		CSQC_hud_RedBlueStatCommon(hudpos, redpoints, bluepoints);
}

//VIP HUD

void CSQC_vip_hud(vector hudpos)
{
	if(rm_oldhud)
	{
		if(vid_conwidth < 560)
		{
			teamhud_enabled = 0;
			return;
		}

		hudpos = '0 0 0';
		hudpos_y = vid_conheight - 21 - sbar_fontsize_y;
		teamhud_wide = vid_conwidth >= 820;
	}

	if(vip_red_health <= 0 || vip_blue_health <= 0)
	{
		teamhud_enabled = 0;
		return;
	}
	teamhud_enabled = 1;

	float hudwidth = (teamhud_wide? SECWIDTH_WIDE : SECWIDTH_NORMAL);
	float textwidth = (teamhud_wide? 11.5 : 5);
	float hudstart, hudend;
	float healthpercent;
	hudstart = hudpos_x;
	hudend = hudstart + hudwidth;

	vector fs, pb, pbsize, pbfill;
	fs = '9 9 0';

	hudpos_y += 1;
	pb = hudpos;
	pb_x += hudwidth / 2;
	pbsize_y = fs_y - 1;
	pbsize_x = hudwidth / 2 - 2;
	pbfill = pbsize - '2 2 0';

	// red vip
	healthpercent = min(vip_red_health / vip_red_maxhealth, 1);
	drawstring(hudpos + '1 0 0', textShortenToWidth(vip_red_name, textwidth, stringwidth_nocolors), fs, GetTeamRGB(COLOR_TEAM1), 1, DRAWFLAG_NORMAL);
	//drawborderlines(0.7, pb, pbsize, '0 0 0', 1, DRAWFLAG_NORMAL);
	drawfill(pb, pbsize, '0 0 0', 0.5, DRAWFLAG_NORMAL);
	pbfill_x *= healthpercent;
	drawfill(pb + '1 1 0', pbfill, (GetTeamRGB(COLOR_TEAM1) + '0.2 0.2 0.2') * 0.7, 0.7, DRAWFLAG_ADDITIVE);

	hudpos_y += fs_x + 1;
	pb_y = hudpos_y;

	// blue vip
	healthpercent = min(vip_blue_health / vip_blue_maxhealth, 1);
	drawstring(hudpos + '1 0 0', textShortenToWidth(vip_blue_name, textwidth, stringwidth_nocolors), fs, GetTeamRGB(COLOR_TEAM2), 1, DRAWFLAG_NORMAL);
	//drawborderlines(0.7, pb, pbsize, '0 0 0', 1, DRAWFLAG_NORMAL);
	drawfill(pb, pbsize, '0 0 0', 0.5, DRAWFLAG_NORMAL);
	pbfill = pbsize - '2 2 0';
	pbfill_x *= healthpercent;
	drawfill(pb + '1 1 0', pbfill, (GetTeamRGB(COLOR_TEAM2) + '0.2 0.2 0.2') * 0.7, 0.7, DRAWFLAG_ADDITIVE);
}


