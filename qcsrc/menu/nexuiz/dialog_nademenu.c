#ifdef INTERFACE
CLASS(NexuizNadeMenuDialog) EXTENDS(NexuizRootDialog)
    METHOD(NexuizNadeMenuDialog, fill, void(entity)) // to be overridden by user to fill the dialog with controls
    ATTRIB(NexuizNadeMenuDialog, title, string, "Nadget Selection")
    ATTRIB(NexuizNadeMenuDialog, color, vector, SKINCOLOR_DIALOG_TEAMSELECT)
    ATTRIB(NexuizNadeMenuDialog, intendedWidth, float, 0.27)
    ATTRIB(NexuizNadeMenuDialog, rows, float, 8)
    ATTRIB(NexuizNadeMenuDialog, columns, float, 1)
    ATTRIB(NexuizNadeMenuDialog, name, string, "NadeMenu")
    ATTRIB(NexuizNadeMenuDialog, nadelist, entity, NULL)
ENDCLASS(NexuizNadeMenuDialog)
#endif

#ifdef IMPLEMENTATION

void NadeMenu_Close(entity button, entity me)
{
    localcmd("cmd hg_alwaysask ", ftos(cvar("_rm_hg_alwaysask")), "; cmd hg_optout ", ftos(cvar("_rm_hg_optout")), "\n");
    me.nadelist.applyChanges(me.nadelist);
    me.close(me);
}

void NadeMenu_RegisterCvars() {
    registercvar("_rm_hg_alwaysask", "0", CVAR_SAVE);
    registercvar("_rm_hg_optout", "0", CVAR_SAVE);
}

void fillNexuizNadeMenuDialog(entity me)
{
    entity e;
    NadeMenu_RegisterCvars();
    
    me.TR(me);
        me.TD(me, me.rows - 2, me.columns, me.nadelist = e = makeRMNadeList());
    me.gotoRC(me, me.rows - 3, 0);
    me.TR(me);
        me.TD(me, 1, me.columns, e = makeNexuizCheckBox(0, "_rm_hg_alwaysask", "Ask at each round"));
    //me.TR(me);
    //    me.TD(me, 1, me.columns, e = makeNexuizCheckBox(0, "_rm_hg_optout", "Opt out of bonuses"));
    me.TR(me);
        me.TD(me, 1, me.columns, e = makeNexuizButton("Accept", '0 0 0'));
            e.onClick = NadeMenu_Close;
            e.onClickEntity = me;
}
#endif

/* Click. The c-word is here so you can grep for it :-) */
