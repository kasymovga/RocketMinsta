// self.isactive = player is in range and coordinates/status (health and armor) are up to date
// self.origin = player origin TODO: should maybe move this so it's the origin of the shownames tag already in SSQC for culling?
// self.healthvalue
// self.armorvalue
// self.sameteam = player is on same team as local client
//

.float health_v;

void Draw_ShowNames()
{
    if(!autocvar_hud_shownames)
        return;

    float oldfont;
    oldfont = drawfont;
    
    if(self.sameteam || (!self.sameteam && !rm_shownames_teamonly))
    {
        //InterpolateOrigin_Do();
        
        if(self.iorigin == '0 0 0')
            self.iorigin = self.origin;
        else
            self.iorigin = self.iorigin + (self.origin - self.iorigin) * frametime * 15;
        

        if(!self.sameteam)
        {
            traceline(self.iorigin, view_origin, 1, self);
            if(trace_endpos != view_origin) // fade out
            {
                self.alpha = max(0, self.alpha - 4 * frametime);
                if(!self.alpha)
                    return;
            }
            else // fade in
                self.alpha = min(1, self.alpha + 4 * frametime);


            /* WIP, why does trace_ent != self not work as intended here?
            if(autocvar_hud_shownames_enemies != 2) // player has to point at enemy if so
            {
                traceline(view_origin, view_origin + view_forward * MAX_SHOT_DISTANCE, MOVETYPE_FLY, world);
                print("trace_endpos: ", vtos(trace_endpos), " view_origin: ", vtos(view_origin), "\n");
                if(trace_ent != self)
                    return;
            }*/
        }

        // otherwise, increase alpha until 1

        float dist;
        dist = vlen(self.iorigin - view_origin);

        float a;
        a = autocvar_hud_shownames_alpha;
        if(self.alpha)
            a *= self.alpha;
        //if(autocvar_hud_shownames_maxdistance)
        {
            if(dist >= autocvar_hud_shownames_maxdistance)
                return;
            a *= ((autocvar_hud_shownames_maxdistance - autocvar_hud_shownames_mindistance) - max(0, dist - autocvar_hud_shownames_mindistance)) / (autocvar_hud_shownames_maxdistance - autocvar_hud_shownames_mindistance);
        }

        float resize;
        resize = 1;
        //if(autocvar_hud_shownames_resize) // limit resize so its never smaller than 0.5... gets unreadable
        //    resize = 0.5 + 0.5 * ((autocvar_hud_shownames_maxdistance - autocvar_hud_shownames_mindistance) - max(0, dist - autocvar_hud_shownames_mindistance)) / (autocvar_hud_shownames_maxdistance - autocvar_hud_shownames_mindistance);

        // draw the sprite image
        vector o;
        o = project_3d_to_2d(self.iorigin);

        if not(o_z < 0 || o_x < 0 || o_y < 0 || o_x > vid_conwidth || o_y > vid_conheight)
        {
            o_z = 0;

            vector myPos, mySize;
            mySize = (eX * autocvar_hud_shownames_aspect + eY) * autocvar_hud_shownames_height;
            myPos = o - '0.5 0 0' * mySize_x - '0 1 0' * mySize_y;

            // size scaling
            mySize_x *= resize;
            mySize_y *= resize;

            myPos_x += 0.5 * (mySize_x / resize - mySize_x);
            myPos_y += (mySize_y / resize - mySize_y);

            vector iconpos, iconsize; // these determine icon position/size, if any
            iconsize = '0 0 0'; /// fteqcc sucks
            vector namepos; // this is where the origin of the string
            float namesize; // total area where we can draw the string

            iconpos = myPos;

            #if 0
            if(autocvar_hud_shownames_status)
            {
                if(self.sameteam)
                {
                    iconsize = eX * 2 * mySize_y + eY * mySize_y;
                    // "ghost" backgrounds
                    drawpic_aspect_skin(iconpos, "health", '1 1 0' * iconsize_y, '0 0 0', a * 0.5, DRAWFLAG_NORMAL);
                    drawpic_aspect_skin(iconpos + '0.5 0 0' * iconsize_x, "armor", '1 1 0' * iconsize_y, '0 0 0', a * 0.5, DRAWFLAG_NORMAL);

                    if(self.healthvalue > 0)
                    {
                        drawsetcliparea(0, myPos_y + iconsize_y - iconsize_y * min(1, self.healthvalue/autocvar_hud_panel_healtharmor_maxhealth), vid_conwidth, myPos_y + iconsize_y);
                        drawpic_aspect_skin(iconpos, "health", '1 1 0' * iconsize_y, '1 1 1', a, DRAWFLAG_NORMAL);
                    }

                    if(self.armorvalue > 0)
                    {
                        drawsetcliparea(0, myPos_y + iconsize_y - iconsize_y * min(1, self.armorvalue/autocvar_hud_panel_healtharmor_maxarmor), vid_conwidth, myPos_y + iconsize_y);
                        drawpic_aspect_skin(iconpos + '0.5 0 0' * iconsize_x, "armor", '1 1 0' * iconsize_y, '1 1 1', a, DRAWFLAG_NORMAL);
                    }
                    drawresetcliparea();
                }
                else if(autocvar_hud_shownames_status == 2 && teamplay)
                {
                    iconsize = eX * 2 * mySize_y + eY * mySize_y;
                    drawpic_aspect_skin(iconpos, "health_unknown", '1 1 0' * iconsize_y, '0 0 0', a, DRAWFLAG_NORMAL);
                    drawpic_aspect_skin(iconpos + '0.5 0 0' * iconsize_x, "armor_unknown", '1 1 0' * iconsize_y, '0 0 0', a, DRAWFLAG_NORMAL);
                }
            }
            #endif

            namepos = myPos + eX * 2 * iconsize_y + eY * 0.5 * resize * (autocvar_hud_shownames_height - autocvar_hud_shownames_fontsize);
            namesize = mySize_x - 2 * iconsize_y;

            string s, s2;
            s = GetPlayerName(self.the_entnum-1);
            vector textsz = '1 1 0' * autocvar_hud_shownames_fontsize * resize;
            float hsz = 2;
            
            if(teamplay) {
                s = strdecolorize(s);
                s = textShortenToWidth_svn(s, namesize, textsz, stringwidth_nocolors_svn);
            } else s = textShortenToWidth_svn(s, namesize, textsz, stringwidth_colors_svn);

            float width;
            width = stringwidth_svn(s, TRUE, textsz);

            if (width != namesize)
                namepos_x += (namesize - width) / 2;
            
            float nade;
            if(g_nadgets)
                nade = playerslots[self.the_entnum-1].(scores[SP_NADEMODE]);
            
            if(self.sameteam) {
                float mx = 200;
                vector dmg = healtharmor_maxdamage(self.healthvalue, self.armorvalue, armorblockpercent);
                dmg_x = max(0, ceil(dmg_x + 1));
                
                if(dmg_x) {
                    self.health_v = bound(0, self.health_v + (min(dmg_x, mx) - self.health_v) * frametime * 10, mx);
                    drawfont = GetBigfont();
                    vector clr;
                    if(playerslots[self.the_entnum-1].(scores[SP_FROZENSTATUS])) {
                        s2 = "Frozen!";
                        clr = '0.2 1 1';
                    } else {
                        s2 = ftos(dmg_x); // strcat(ftos(self.healthvalue), " / ", ftos(self.armorvalue));
                        clr = healthcolor(dmg_x);
                    }
                    drawstring(namepos - hsz * '0 1 0' * textsz_y + '0.5 0 0' * (width - stringwidth_svn(s2, TRUE, textsz * hsz)), s2, textsz * hsz, clr, a * 0.7, DRAWFLAG_NORMAL);
                    drawfont = sbar_font;
                }
            }            
            
            if(nade) {
                drawpic(namepos - '0.5 0 0' * textsz_x - '2 0 0', HG_TypeToIcon(nade, FALSE, FALSE), textsz, HG_TypeToColor(nade), a * 0.7, DRAWFLAG_NORMAL);
                namepos = '0.5 0 0' * textsz_x + '2 0 0' + namepos;
            }
            
            if(teamplay)
                drawstring(namepos, s, textsz, GetTeamRGB(GetPlayerColorForce(self.the_entnum - 1)) + '0.2 0.2 0.2', a, DRAWFLAG_NORMAL);
            else
                drawcolorcodedstring(namepos, s, textsz, a, DRAWFLAG_NORMAL);
            
            drawresetcliparea();
            
            drawfont = oldfont;
            //drawfontscale = '1 1 0';
            
            playerslots[self.the_entnum-1].sn_lastdraw = time;
        }
    }
}
