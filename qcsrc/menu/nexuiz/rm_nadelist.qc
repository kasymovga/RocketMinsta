#ifdef INTERFACE
CLASS(RMNadeList) EXTENDS(NexuizListBox)
    METHOD(RMNadeList, configureRMNadeList, void(entity))
    ATTRIB(RMNadeList, fontSize, float, SKINFONTSIZE_NORMAL)
    ATTRIB(RMNadeList, scrollbarWidth, float, SKINWIDTH_SCROLLBAR)
    ATTRIB(RMNadeList, src, string, SKINGFX_SCROLLBAR)
    ATTRIB(RMNadeList, tolerance, vector, SKINTOLERANCE_SLIDER)
    ATTRIB(RMNadeList, rowsPerItem, float, 1)
    METHOD(RMNadeList, resizeNotify, void(entity, vector, vector, vector, vector))
    METHOD(RMNadeList, drawListBoxItem, void(entity, float, vector, float))
    METHOD(RMNadeList, setSelected, void(entity, float))
    METHOD(RMNadeList, keyDown, float(entity, float, float, float))
    METHOD(RMNadeList, mouseDrag, float(entity, vector))
    METHOD(RMNadeList, updateNadeList, void(entity))
    METHOD(RMNadeList, RMUpdate, void(entity))
    METHOD(RMNadeList, applyChanges, void(entity))
    ATTRIB(RMNadeList, RMUpdatable, float, TRUE)
    ATTRIB(RMNadeList, color, vector, SKINCOLOR_SCROLLBAR_N)
    ATTRIB(RMNadeList, colorF, vector, SKINCOLOR_SCROLLBAR_F)
    ATTRIB(RMNadeList, color2, vector, SKINCOLOR_SCROLLBAR_S)
    ATTRIB(RMNadeList, colorC, vector, SKINCOLOR_SCROLLBAR_C)
    ATTRIB(RMNadeList, isUpdating, float, FALSE)
    ATTRIB(RMNadeList, nadelist_buf, float, -1)
ENDCLASS(RMNadeList)
entity makeRMNadeList();
#endif

#ifdef IMPLEMENTATION
entity makeRMNadeList()
{
    entity me;
    me = spawnRMNadeList();
    me.configureRMNadeList(me);
    return me;
}

void RMUpdateRMNadeList(entity me)
{
    me.updateNadeList(me);
}

void applyChangesRMNadeList(entity me) {
    localcmd("cmd picknade ", bufstr_get(me.nadelist_buf, me.selectedItem), "; cmd join\n");
}

void setSelectedRMNadeList(entity me, float i)
{
    if(!me.disabled)
    {
        setSelectedListBox(me, i);
        
        //if(!me.isUpdating)
        //	localcmd("cmd picknade ", bufstr_get(me.nadelist_buf, me.selectedItem), "\n");
    }
}

float keyDownRMNadeList(entity me, float key, float ascii, float shift)
{
    if(!me.disabled)
        return keyDownListBox(me, key, ascii, shift);
    return 0;
}

float mouseDragRMNadeList(entity me, vector pos)
{
    if(!me.disabled)
        return mouseDragListBox(me, pos);
    return 0;
}

void updateNadeListRMNadeList(entity me)
{
    float i, argc;
    if(me.nadelist_buf > -1)
        buf_del(me.nadelist_buf);
    
    me.isUpdating = TRUE;
    me.nadelist_buf = buf_create();
    
    argc = tokenizebyseparator(cvar_string("_nade_options"), " ");
    
    for(i = 0; i < argc; ++i) {
        bufstr_set(me.nadelist_buf, i, argv(i));
    }
    
    me.nItems = argc;
    
    me.isUpdating = FALSE;
}

void configureRMNadeListRMNadeList(entity me)
{
    me.configureNexuizListBox(me);
    me.updateNadeList(me);
}

void resizeNotifyRMNadeList(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize)
{
    resizeNotifyNexuizListBox(me, relOrigin, relSize, absOrigin, absSize);

    me.realFontSize_y = me.fontSize / (absSize_y * me.itemHeight);
    me.realFontSize_x = me.fontSize / (absSize_x * (1 - me.controlWidth));
    me.realUpperMargin = 0.5 * (1 - me.realFontSize_y);
}

//void draw_Picture_Unskinned(vector theOrigin, string pic, vector theSize, vector theColor, float theAlpha)

void setDependent_Check(entity);
void drawListBoxItemRMNadeList(entity me, float i, vector absSize, float isSelected)
{
    local string s;
    local float amod;
    amod = (me.disabled? 0.2:1);
    
    if(isSelected)
        draw_Fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_SELECTED, SKINALPHA_LISTBOX_SELECTED * amod);
    
    vector o = me.realUpperMargin2 * eY + (me.columnNameOrigin + 0.00 * (me.columnNameSize - draw_TextWidth(s, 1) * me.realFontSize_x)) * eX;
    
    s = bufstr_get(me.nadelist_buf, i);
    
    draw_Picture_Unskinned(o, HG_NameToIcon(s, FALSE, FALSE), me.realFontSize, HG_TypeToColor(HG_NameToType(s)), 1);
    draw_Text(me.realFontSize_x * '1.2 0 0' + o, HG_NameToExpandedName(s), me.realFontSize, '1 1 1', 1 * amod, 1);
}
#endif
