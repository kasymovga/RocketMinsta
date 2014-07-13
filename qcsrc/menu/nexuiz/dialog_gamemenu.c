#ifdef INTERFACE
CLASS(NexuizGameMenuDialog) EXTENDS(NexuizRootDialog)
	METHOD(NexuizGameMenuDialog, fill, void(entity)) // to be overridden by user to fill the dialog with controls
	ATTRIB(NexuizGameMenuDialog, title, string, "Game Menu")
	ATTRIB(NexuizGameMenuDialog, color, vector, SKINCOLOR_DIALOG_TEAMSELECT)
	ATTRIB(NexuizGameMenuDialog, intendedWidth, float, 0.25)
	ATTRIB(NexuizGameMenuDialog, rows, float, 13)
	ATTRIB(NexuizGameMenuDialog, columns, float, 10)
	ATTRIB(NexuizGameMenuDialog, name, string, "GameMenu")
ENDCLASS(NexuizGameMenuDialog)
#endif

#ifdef IMPLEMENTATION

void m_activate_window(entity);
void m_display();
void GotoMainMenu(entity button, entity me)
{
	m_activate_window(main.mainNexposee);
	m_display();
}

void fillNexuizGameMenuDialog(entity me)
{
	entity e;
	me.TR(me);
		me.TD(me, 1, me.columns, e = makeNexuizButton("Main menu", '0 0 0'));
			e.onClick = GotoMainMenu;
			e.onClickEntity = me;
	me.TR(me);
		me.TD(me, 1, me.columns, e = makeNexuizCommandButton("RM options", '0 0 0', "menu_cmd directmenu RMConfig;", COMMANDBUTTON_CLOSE));
		setDependent(e, "_rm_server", 1, 1);
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, me.columns, e = makeNexuizCommandButton("Join", '0 0 0', "cmd join;", COMMANDBUTTON_CLOSE));
	me.TR(me);
		me.TD(me, 1, me.columns, e = makeNexuizCommandButton("Switch team", '0 0 0', "menu_cmd directmenu TeamSelect;", COMMANDBUTTON_CLOSE));
		setDependent(e, "_teams_available", 1, 1337);
	me.TR(me);
		me.TD(me, 1, me.columns, e = makeNexuizCommandButton("Switch nadget", '0 0 0', "menu_cmd directmenu NadeMenu;", COMMANDBUTTON_CLOSE));
		setDependent(e, "_g_nadgets_select_available", 1, 1337);
	me.TR(me);
		me.TD(me, 1, me.columns, e = makeNexuizCommandButton("Spectate", '0 0 0', "cmd spectate;", COMMANDBUTTON_CLOSE));
	me.TR(me);
		me.TD(me, 1, me.columns, e = makeNexuizCommandButton("Call a vote", '0 0 0', "menu_cmd directmenu VcallMenu;", COMMANDBUTTON_CLOSE));
		setDependent(e, "_voting_allowed", 1, 1);
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, me.columns, e = makeNexuizCommandButton("Disconnect", '0 0 0', "disconnect;", COMMANDBUTTON_CLOSE));
	me.TR(me);
		me.TD(me, 1, me.columns, e = makeNexuizCommandButton("Reconnect", '0 0 0', "disconnect; reconnect;", COMMANDBUTTON_CLOSE));
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, me.columns, e = makeNexuizButton("Return to game", '0 0 0'));
			e.onClick = Dialog_Close;
			e.onClickEntity = me;
}
#endif

/* Click. The c-word is here so you can grep for it :-) */
