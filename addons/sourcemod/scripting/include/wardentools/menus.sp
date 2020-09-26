void Menu_TakeWarden(bool disabled = false) {
	Menu menu = new Menu(Menu_TakeWardenCallback);
	menu.SetTitle("Take Warden?");
	menu.AddItem("", "Yes", disabled ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);

	for (int i = 1; i <= MaxClients; i++) {
		if (!CanBeWarden(i)) continue;
		menu.Display(i, disabled ? 1 : 0);
	}
}

int Menu_TakeWardenCallback(Menu menu, MenuAction action, int param1, int param2) {
	if (action == MenuAction_End) delete menu;

	if (action == MenuAction_Select) {
		if (g_Warden.Id) {
			char[] buffer = new char[512];
			FormatEx(buffer, 512, "%s%T", PLUGIN_PREFIX, "announce_already_taken", param1);
		} else {
			Menu_TakeWarden(true);
			SetWarden(param1, true);
		}
	}
}

void Menu_WardenTools() {
	char[] buffer = new char[512];
	Menu menu = new Menu(Menu_WardenToolsCallback);

	FormatEx(buffer, 512, "%T (%s)\n ", "warden_tools", g_Warden.Id, PLUGIN_VERSION);
	menu.SetTitle(buffer);

	FormatEx(buffer, 512, "Priority Speaker: %s", g_Warden.PrioritySpeaker ? "ON" : "OFF");
	menu.AddItem("", buffer);

	FormatEx(buffer, 512, "%T", "miscellaneous", g_Warden.Id);
	menu.AddItem("", buffer);

	FormatEx(buffer, 512, "%T", "minigames", g_Warden.Id);
	menu.AddItem("", buffer);

	FormatEx(buffer, 512, "%T", "specialdays", g_Warden.Id);
	menu.AddItem("", buffer, g_RoundsRemaining == 0 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

	menu.Display(g_Warden.Id, 0);
}

int Menu_WardenToolsCallback(Menu menu, MenuAction action, int param1, int param2) {
	if (param1 != g_Warden.Id) return;
	if (action == MenuAction_End) delete menu; g_Warden.Tool = WardenTool_None;

	if (action == MenuAction_Select) {
		switch (param2) {
			case 0: PrioritySpeakerChange();
			case 1: Menu_Miscellaneous();
			case 2: Menu_Minigames();
			case 3: Menu_Special();
		}

		if (param2 == 0) Menu_WardenTools();
	}
}

void Menu_Miscellaneous() {
	char[] buffer = new char[512];
	Menu menu = new Menu(Menu_MiscellaneousCallback);
	menu.ExitBackButton = true;

	FormatEx(buffer, 512, "%T - %T\n ", "warden_tools", g_Warden.Id, "miscellaneous", g_Warden.Id);
	menu.SetTitle(buffer);

	FormatEx(buffer, 512, "Mic Check");
	menu.AddItem("", buffer);

	FormatEx(buffer, 512, "%T", "team_picker", g_Warden.Id);
	menu.AddItem("", buffer);

	FormatEx(buffer, 512, "%T", "beacon", g_Warden.Id);
	menu.AddItem("", buffer);

	FormatEx(buffer, 512, "%T", "laser", g_Warden.Id);
	menu.AddItem("", buffer);

	FormatEx(buffer, 512, "%T", "heal_t", g_Warden.Id);
	menu.AddItem("", buffer);

	FormatEx(buffer, 512, "%T", "give_ta_grenade", g_Warden.Id);
	menu.AddItem("", buffer, !g_Warden.Grenade ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

	menu.Display(g_Warden.Id, 0);
}

int Menu_MiscellaneousCallback(Menu menu, MenuAction action, int param1, int param2) {
	if (param1 != g_Warden.Id) return;
	if (action == MenuAction_End) delete menu; g_Warden.Tool = WardenTool_None;

	if (action == MenuAction_Cancel) {
		if (param2 == MenuCancel_ExitBack) Menu_WardenTools();
	}

	if (action == MenuAction_Select) {
		switch (param2) {
			case 0: MicCheck();
			case 1: Menu_TeamPicker();
			case 2: Menu_Beacon();
			case 3: Menu_Laser();
			case 4: HealT();
			case 5: GiveAwarenessGrenade();
			
		}

		if (param2 > 2) Menu_Miscellaneous();
	}
}

void MicCheck() {
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsValidPlayer(i)) continue;
		if (GetClientTeam(i) != 3) continue;
		if (!IsPlayerAlive(i)) CS_RespawnPlayer(i);
		ChangeComm(i, false);
		g_MicCheck[i] = true;

		PrintToChat(i, "%s\x07MIC CHECK MIC CHECK, USE YOUR MICROPHONE TO NOT GET SWAPPED", PLUGIN_PREFIX);
	}

	CreateTimer(7.0, Timer_MicCheck);
}

public Action Timer_MicCheck(Handle timer, any data) {
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsValidPlayer(i)) continue;
		if (GetClientTeam(i) != 3) continue;
		if (!g_MicCheck[i]) continue;

		CS_SwitchTeam(i, 2);
		PrintToChat(i, "%s\x07YOU HAVE BEEN SWAPPED FOR NO MIC", PLUGIN_PREFIX);
	}
}

public void OnClientSpeaking(int client) {
	if (g_MicCheck[client]) {
		PrintToChat(client, "%s\x06ALL GOOD!", PLUGIN_PREFIX);
		g_MicCheck[client] = false;
	}
}

void Menu_Minigames() {
	char[] buffer = new char[512];
	Menu menu = new Menu(Menu_MinigamesCallback);
	menu.ExitBackButton = true;

	FormatEx(buffer, 512, "%T - %T\n ", "warden_tools", g_Warden.Id, "minigames", g_Warden.Id);
	menu.SetTitle(buffer);

	FormatEx(buffer, 512, "%T", "shark", g_Warden.Id);
	menu.AddItem("", buffer);

	FormatEx(buffer, 512, "%T", "blind", g_Warden.Id);
	menu.AddItem("", buffer);

	FormatEx(buffer, 512, "%T", "slap", g_Warden.Id);
	menu.AddItem("", buffer);

	FormatEx(buffer, 512, "%T", "freezejump", g_Warden.Id);
	menu.AddItem("", buffer);

	menu.Display(g_Warden.Id, 0);
}

int Menu_MinigamesCallback(Menu menu, MenuAction action, int param1, int param2) {
	if (param1 != g_Warden.Id) return;
	if (action == MenuAction_End) delete menu; g_Warden.Tool = WardenTool_None;

	if (action == MenuAction_Cancel) {
		if (param2 == MenuCancel_ExitBack) Menu_WardenTools();
	}

	if (action == MenuAction_Select) {
		switch (param2) {
			case 0: {
				g_Warden.Shark = g_Warden.Id; 
				Menu_Shark();
			}
			case 1: Menu_Blind();
			case 2: Menu_Slap();
			case 3: Menu_FreezeJump();
		}
	}
}

void Menu_TeamPicker() {
	char[] buff = new char[64];
	char[] buffer = new char[512];
	Menu menu = new Menu(Menu_TeamPickerCallback);
	
	FormatEx(buffer, 512, "%T - %T\n%T\n ", "warden_tools", g_Warden.Id, "team_picker", g_Warden.Id, "use_e", g_Warden.Id);
	menu.SetTitle(buffer);

	FormatEx(buff, 64, "%T", g_ColorNames[g_Warden.TeamPicked], g_Warden.Id);
	FormatEx(buffer, 512, "%T", "current_color", g_Warden.Id, buff);
	menu.AddItem("", buffer);

	FormatEx(buffer, 512, "%T", "randomize", g_Warden.Id);
	menu.AddItem("", buffer);

	menu.AddItem("", "", ITEMDRAW_SPACER);

	FormatEx(buffer, 512, "%T", "clear", g_Warden.Id);
	menu.AddItem("", buffer);

	menu.AddItem("", "", ITEMDRAW_SPACER);

	FormatEx(buff, 64, "%T", g_FriendlyFireNames[g_FriendlyFire], g_Warden.Id);
	FormatEx(buffer, 512, "%T", "friendly_fire", g_Warden.Id, buff);
	menu.AddItem("", buffer);

	menu.Display(g_Warden.Id, 0);
	g_Warden.Tool = WardenTool_TeamPicker;
}

int Menu_TeamPickerCallback(Menu menu, MenuAction action, int param1, int param2) {
	if (param1 != g_Warden.Id) return;
	if (action == MenuAction_End) delete menu; g_Warden.Tool = WardenTool_None;

	if (action == MenuAction_Select) {
		switch (param2) {
			case 0: Menu_TeamPickerChangeTeam();
			case 1: Menu_TeamPickerRandomize();
			case 3: ClearTeams();
			case 5: {
				char[] buffer = new char[64];
				g_FriendlyFire = (g_FriendlyFire + 1) % sizeof(g_FriendlyFireNames);

				FormatEx(buffer, 64, "%s%t", CHAT_HIGHLIGHT, g_FriendlyFireNames[g_FriendlyFire]);
				PrintToChatAll("%s%t", PLUGIN_PREFIX, "announce_friendly_fire", buffer);
			}
		}

		if (param2 > 2) Menu_TeamPicker();
	}
}

void Menu_TeamPickerChangeTeam(int startIndex = 0) {
	char[] buffer = new char[512];
	Menu menu = new Menu(Menu_TeamPickerChangeTeamCallback);
	menu.ExitBackButton = true;

	FormatEx(buffer, 512, "%T - %T - %T\n%T\n ", "warden_tools", g_Warden.Id, "team_picker", g_Warden.Id, "change_team", g_Warden.Id, "use_e", g_Warden.Id);
	menu.SetTitle(buffer);

	for (int i = 0; i < sizeof(g_ColorNames); i++) {
		FormatEx(buffer, 512, "%T", g_ColorNames[i], g_Warden.Id);
		menu.AddItem("", buffer, i != g_Warden.TeamPicked ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	}

	menu.DisplayAt(g_Warden.Id, RoundToFloor(startIndex / 6.0) * 6, 0);
	g_Warden.Tool = WardenTool_TeamPicker;
}

int Menu_TeamPickerChangeTeamCallback(Menu menu, MenuAction action, int param1, int param2) {
	if (param1 != g_Warden.Id) return;
	if (action == MenuAction_End) delete menu; g_Warden.Tool = WardenTool_None;

	if (action == MenuAction_Cancel) {
		if (param2 == MenuCancel_ExitBack) Menu_TeamPicker();
	}

	if (action == MenuAction_Select) {
		g_Warden.TeamPicked = param2;
		Menu_TeamPickerChangeTeam(param2);
	}
}

void Menu_TeamPickerRandomize() {
	char[] color = new char[64];
	char[] buffer = new char[512];
	Menu menu = new Menu(Menu_TeamPickerRandomizeCallback);
	menu.ExitBackButton = true;

	FormatEx(buffer, 512, "%T - %T - %T\n ", "warden_tools", g_Warden.Id, "team_picker", g_Warden.Id, "randomize", g_Warden.Id);
	menu.SetTitle(buffer);

	FormatEx(buffer, 512, "%T", "randomize_teams", g_Warden.Id, 2 + g_Warden.TeamRandomize);
	menu.AddItem("", buffer);

	FormatEx(color, 64, "%T", g_Warden.TeamRandomizeRandom ? "random" : "static", g_Warden.Id);
	FormatEx(buffer, 512, "%T", "randomize_pattern", g_Warden.Id, color);
	menu.AddItem("", buffer);

	menu.AddItem("", "", ITEMDRAW_SPACER);

	FormatEx(buffer, 512, "%T", "randomize", g_Warden.Id);
	menu.AddItem("", buffer);

	menu.Display(g_Warden.Id, 0);
	g_Warden.Tool = WardenTool_None;
}

int Menu_TeamPickerRandomizeCallback(Menu menu, MenuAction action, int param1, int param2) {
	if (param1 != g_Warden.Id) return;
	if (action == MenuAction_End) delete menu; g_Warden.Tool = WardenTool_None;

	if (action == MenuAction_Cancel) {
		if (param2 == MenuCancel_ExitBack) Menu_TeamPicker();
	}

	if (action == MenuAction_Select) {
		switch (param2) {
			case 0: g_Warden.TeamRandomize++;
			case 1: g_Warden.TeamRandomizeRandom = !g_Warden.TeamRandomizeRandom;
			case 3: RandomizeTeams(2 + g_Warden.TeamRandomize, g_Warden.TeamRandomizeRandom);
		}

		if (2 + g_Warden.TeamRandomize > sizeof(g_Colors)) g_Warden.TeamRandomize = 0;

		if (param2 != 3) Menu_TeamPickerRandomize();
		else Menu_TeamPicker();
	}
}

void Menu_Beacon() {
	char[] fade = new char[64];
	char[] buffer = new char[512];
	Menu menu = new Menu(Menu_BeaconCallback);

	FormatEx(buffer, 512, "%T - %T\n%T\n ", "warden_tools", g_Warden.Id, "beacon", g_Warden.Id, "beacon_use", g_Warden.Id);
	menu.SetTitle(buffer);

	FormatEx(buffer, 512, "%T", "static", g_Warden.Id);
	menu.AddItem("", buffer);

	FormatEx(buffer, 512, "%T", "animated", g_Warden.Id);
	menu.AddItem("", buffer, CheckCommandAccess(g_Warden.Id, "", ADMFLAG_CUSTOM1) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

	menu.AddItem("", "", ITEMDRAW_SPACER);

	FormatEx(fade, 64, "%T", g_BeaconTimeNames[g_Warden.BeaconEndOption], g_Warden.Id);
	FormatEx(buffer, 512, "%T", "fade", g_Warden.Id, fade);
	menu.AddItem("", buffer);

	menu.Display(g_Warden.Id, 0);
}

int Menu_BeaconCallback(Menu menu, MenuAction action, int param1, int param2) {
	if (param1 != g_Warden.Id) return;
	if (action == MenuAction_End) delete menu; g_Warden.Tool = WardenTool_None;

	if (action == MenuAction_Select) {
		switch (param2) {
			case 0: Menu_BeaconStatic();
			case 1: Menu_BeaconAnimated();
			case 3: g_Warden.BeaconEndOption = (g_Warden.BeaconEndOption + 1) % sizeof(g_BeaconTimes);
		}

		if (param2 == 3) Menu_Beacon();
	}
}

void Menu_BeaconStatic(int startIndex = 0) {
	char[] buffer = new char[512];
	Menu menu = new Menu(Menu_BeaconStaticCallback);
	menu.ExitBackButton = true;

	FormatEx(buffer, 512, "%T - %T - %T\n%T\n ", "warden_tools", g_Warden.Id, "beacon", g_Warden.Id, "static", g_Warden.Id, "beacon_use", g_Warden.Id);
	menu.SetTitle(buffer);

	for (int i = 0; i < sizeof(g_Colors); i++) {
		FormatEx(buffer, 512, "%T", g_ColorNames[i], g_Warden.Id);
		menu.AddItem("", buffer, i != g_Players[g_Warden.Id].BeaconPref ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	}

	menu.DisplayAt(g_Warden.Id, RoundToFloor(startIndex / 6.0) * 6, 0);
}

int Menu_BeaconStaticCallback(Menu menu, MenuAction action, int param1, int param2) {
	if (param1 != g_Warden.Id) return;
	if (action == MenuAction_End) delete menu; g_Warden.Tool = WardenTool_None;

	if (action == MenuAction_Cancel) {
		if (param2 == MenuCancel_ExitBack) Menu_Beacon();
	}

	if (action == MenuAction_Select) {
		SetPlayerBeaconPref(param1, param2);
		Menu_BeaconStatic(param2);
	}
}

void Menu_BeaconAnimated(int startIndex = 0) {
	char[] buffer = new char[512];
	Menu menu = new Menu(Menu_BeaconAnimatedCallback);
	menu.ExitBackButton = true;

	FormatEx(buffer, 512, "%T - %T - %T\n%T\n ", "warden_tools", g_Warden.Id, "beacon", g_Warden.Id, "animated", g_Warden.Id, "beacon_use", g_Warden.Id);
	menu.SetTitle(buffer);

	for (int i = 0; i < g_Beacons.Length; i++) {
		Beacon beacon; g_Beacons.GetArray(i, beacon);
		menu.AddItem("", beacon.Desc, i + sizeof(g_Colors) != g_Players[g_Warden.Id].BeaconPref ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	}

	menu.DisplayAt(g_Warden.Id, RoundToFloor(startIndex / 6.0) * 6, 0);
}

int Menu_BeaconAnimatedCallback(Menu menu, MenuAction action, int param1, int param2) {
	if (param1 != g_Warden.Id) return;
	if (action == MenuAction_End) delete menu; g_Warden.Tool = WardenTool_None;

	if (action == MenuAction_Cancel) {
		if (param2 == MenuCancel_ExitBack) Menu_Beacon();
	}

	if (action == MenuAction_Select) {
		SetPlayerBeaconPref(param1, param2 + sizeof(g_Colors));
		Menu_BeaconAnimated(param2);
	}
}

void Menu_Laser() {
	char[] fade = new char[64];
	char[] color = new char[64];
	char[] buffer = new char[512];
	Menu menu = new Menu(Menu_LaserCallback);

	FormatEx(buffer, 512, "%T - %T\n%T\n ", "warden_tools", g_Warden.Id, "laser", g_Warden.Id, "use_e", g_Warden.Id);
	menu.SetTitle(buffer);

	FormatEx(color, 64, "%T", g_ColorNames[g_Warden.LaserColor], g_Warden.Id);
	FormatEx(buffer, 512, "%T", "current_color", g_Warden.Id, color);
	menu.AddItem("", buffer);

	FormatEx(fade, 64, "%T", g_LaserTimeNames[g_Warden.LaserEndOption], g_Warden.Id);
	FormatEx(buffer, 512, "%T", "fade", g_Warden.Id, fade);
	menu.AddItem("", buffer);

	menu.AddItem("", "", ITEMDRAW_SPACER);

	FormatEx(buffer, 512, "%T", "clear", g_Warden.Id);
	menu.AddItem("", buffer);

	menu.Display(g_Warden.Id, 0);
	g_Warden.Tool = WardenTool_Laser;
}

int Menu_LaserCallback(Menu menu, MenuAction action, int param1, int param2) {
	if (param1 != g_Warden.Id) return;
	if (action == MenuAction_End) delete menu; g_Warden.Tool = WardenTool_None;

	if (action == MenuAction_Select) {
		switch (param2) {
			case 0: Menu_LaserChangeColor();
			case 1: g_Warden.LaserEndOption = (g_Warden.LaserEndOption + 1) % sizeof(g_LaserTimes);
			case 3: g_Lasers.Clear();
		}

		if (param2 != 0) Menu_Laser();
	}
}

void Menu_LaserChangeColor(int startIndex = 0) {
	char[] buffer = new char[512];
	Menu menu = new Menu(Menu_LaserChangeColorCallback);
	menu.ExitBackButton = true;

	FormatEx(buffer, 512, "%T - %T\n%T\n ", "warden_tools", g_Warden.Id, "laser", g_Warden.Id, "use_e", g_Warden.Id);
	menu.SetTitle(buffer);

	for (int i = 0; i < sizeof(g_ColorNames); i++) {
		FormatEx(buffer, 512, "%T", g_ColorNames[i], g_Warden.Id);
		menu.AddItem("", buffer, i != g_Warden.LaserColor ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	}

	menu.DisplayAt(g_Warden.Id, RoundToFloor(startIndex / 6.0) * 6, 0);
	g_Warden.Tool = WardenTool_Laser;
}

int Menu_LaserChangeColorCallback(Menu menu, MenuAction action, int param1, int param2) {
	if (param1 != g_Warden.Id) return;
	if (action == MenuAction_End) delete menu; g_Warden.Tool = WardenTool_None;

	if (action == MenuAction_Cancel) {
		if (param2 == MenuCancel_ExitBack) Menu_Laser();
	}

	if (action == MenuAction_Select) {
		g_Warden.LaserColor = param2;
		Menu_LaserChangeColor(param2);
	}
}

void Menu_Shark() {
	char[] shark = new char[64];
	char[] duration = new char[64];
	char[] yes = new char[64];
	char[] buffer = new char[512];
	Menu menu = new Menu(Menu_SharkCallback);

	FormatEx(buffer, 512, "%T - %T\n ", "warden_tools", g_Warden.Id, "shark", g_Warden.Id);
	menu.SetTitle(buffer);

	FormatEx(shark, 64, "%N", g_Warden.Shark);
	FormatEx(buffer, 512, "%T", "current_target", g_Warden.Id, shark);
	menu.AddItem("", buffer);

	FormatEx(duration, 64, "%T", g_TimeNames[g_Warden.Duration], g_Warden.Id);
	FormatEx(buffer, 512, "%T", "current_duration", g_Warden.Id, duration);
	menu.AddItem("", buffer);

	FormatEx(yes, 64, "%T", g_YesNo[view_as<int>(g_Warden.No)], g_Warden.Id);
	FormatEx(buffer, 512, "%T", "blind_ct", g_Warden.Id, yes);
	menu.AddItem("", buffer);

	menu.AddItem("", "", ITEMDRAW_SPACER);

	FormatEx(buffer, 512, "%T", "start", g_Warden.Id);
	menu.AddItem("", buffer, g_Warden.CurrentTime == 0 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

	FormatEx(buffer, 512, "%T", "stop", g_Warden.Id);
	menu.AddItem("", buffer, g_Warden.CurrentTime != 0 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

	menu.Display(g_Warden.Id, 0);
	g_Warden.Tool = WardenTool_Shark;
}

int Menu_SharkCallback(Menu menu, MenuAction action, int param1, int param2) {
	if (param1 != g_Warden.Id) return;
	if (action == MenuAction_End) delete menu; g_Warden.Tool = WardenTool_None;

	if (action == MenuAction_Select) {
		switch (param2) {
			case 0: Menu_SharkChange();
			case 1: g_Warden.Duration = (g_Warden.Duration + 1) % sizeof(g_Times);
			case 2: g_Warden.No = !g_Warden.No;
			case 4: StartShark();
			case 5: StopMinigame(true);
		}

		if (param2 != 0) Menu_Shark();
	}
}

void Menu_SharkChange(int startIndex = 0) {
	char[] buffer = new char[512];
	Menu menu = new Menu(Menu_SharkChangeCallback);
	menu.ExitBackButton = true;

	FormatEx(buffer, 512, "%T - %T - %T\n ", "warden_tools", g_Warden.Id, "shark", g_Warden.Id, "change_shark", g_Warden.Id);
	menu.SetTitle(buffer);

	char[] index = new char[4];

	for (int i = 1; i <= MaxClients; i++) {
		if (!CanBeWarden(i)) continue;

		FormatEx(index, 4, "%i", i);
		FormatEx(buffer, 512, "%N", i);
		menu.AddItem(index, buffer, i != g_Warden.Shark ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	}

	menu.DisplayAt(g_Warden.Id, RoundToFloor(startIndex / 6.0) * 6, 0);
	g_Warden.Tool = WardenTool_Shark;
}

int Menu_SharkChangeCallback(Menu menu, MenuAction action, int param1, int param2) { 
	if (param1 != g_Warden.Id) return;
	if (action == MenuAction_End) delete menu; g_Warden.Tool = WardenTool_None;

	if (action == MenuAction_Cancel) {
		if (param2 == MenuCancel_ExitBack) Menu_Shark();
	}

	if (action == MenuAction_Select) {
		char[] index = new char[4];
		menu.GetItem(param2, index, 4);

		g_Warden.Shark = StringToInt(index);
		Menu_SharkChange(param2);
	}
}

void Menu_Blind() {
	char[] blind = new char[64];
	char[] duration = new char[64];
	char[] buffer = new char[512];
	Menu menu = new Menu(Menu_BlindCallback);

	FormatEx(buffer, 512, "%T - %T\n ", "warden_tools", g_Warden.Id, "blind", g_Warden.Id);
	menu.SetTitle(buffer);

	if (g_Warden.Blind == 0) FormatEx(blind, 64, "%T", "all_t", g_Warden.Id);
	else FormatEx(blind, 64, "%N", g_Warden.Blind);
	
	FormatEx(buffer, 512, "%T", "current_target", g_Warden.Id, blind);
	menu.AddItem("", buffer);

	FormatEx(duration, 64, "%T", g_TimeNames[g_Warden.Duration], g_Warden.Id);
	FormatEx(buffer, 512, "%T", "current_duration", g_Warden.Id, duration);
	menu.AddItem("", buffer);

	menu.AddItem("", "", ITEMDRAW_SPACER);

	FormatEx(buffer, 512, "%T", "start", g_Warden.Id);
	menu.AddItem("", buffer, g_Warden.CurrentTime == 0 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

	FormatEx(buffer, 512, "%T", "stop", g_Warden.Id);
	menu.AddItem("", buffer, g_Warden.CurrentTime != 0 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

	menu.Display(g_Warden.Id, 0);
	g_Warden.Tool = WardenTool_Blind;
}

int Menu_BlindCallback(Menu menu, MenuAction action, int param1, int param2) {
	if (param1 != g_Warden.Id) return;
	if (action == MenuAction_End) delete menu; g_Warden.Tool = WardenTool_None;

	if (action == MenuAction_Select) {
		switch (param2) {
			case 0: Menu_BlindChange();
			case 1: g_Warden.Duration = (g_Warden.Duration + 1) % sizeof(g_Times);
			case 3: StartBlind();
			case 4: StopMinigame(true);
		}

		if (param2 != 0) Menu_Blind();
	}
}

void Menu_BlindChange(int startIndex = 0) {
	char[] buffer = new char[512];
	Menu menu = new Menu(Menu_BlindChangeCallback);
	menu.ExitBackButton = true;

	FormatEx(buffer, 512, "%T - %T - %T\n ", "warden_tools", g_Warden.Id, "blind", g_Warden.Id, "change_target", g_Warden.Id);
	menu.SetTitle(buffer);

	char[] index = new char[4];

	for (int i = 0; i <= MaxClients; i++) {
		if (i != 0) {
			if (!IsValidPlayer(i)) continue;
			if (!IsPlayerAlive(i)) continue;
			if (GetClientTeam(i) != 2) continue;
		}

		FormatEx(index, 4, "%i", i);
		if (i == 0) FormatEx(buffer, 512, "%T", "all_t", g_Warden.Id);
		else FormatEx(buffer, 512, "%N", i);
		
		menu.AddItem(index, buffer, i != g_Warden.Blind ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	}

	menu.DisplayAt(g_Warden.Id, RoundToFloor(startIndex / 6.0) * 6, 0);
	g_Warden.Tool = WardenTool_Blind;
}

int Menu_BlindChangeCallback(Menu menu, MenuAction action, int param1, int param2) { 
	if (param1 != g_Warden.Id) return;
	if (action == MenuAction_End) delete menu; g_Warden.Tool = WardenTool_None;

	if (action == MenuAction_Cancel) {
		if (param2 == MenuCancel_ExitBack) Menu_Blind();
	}

	if (action == MenuAction_Select) {
		char[] index = new char[4];
		menu.GetItem(param2, index, 4);

		g_Warden.Blind = StringToInt(index);
		Menu_BlindChange(param2);
	}
}


void Menu_Slap() {
	char[] slap = new char[64];
	char[] buffer = new char[512];
	Menu menu = new Menu(Menu_SlapCallback);

	FormatEx(buffer, 512, "%T - %T\n ", "warden_tools", g_Warden.Id, "slap", g_Warden.Id);
	menu.SetTitle(buffer);

	if (g_Warden.Slap == 0) FormatEx(slap, 64, "%T", "all_t", g_Warden.Id);
	else FormatEx(slap, 64, "%N", g_Warden.Slap);
	
	FormatEx(buffer, 512, "%T", "current_target", g_Warden.Id, slap);
	menu.AddItem("", buffer);

	menu.AddItem("", "", ITEMDRAW_SPACER);

	FormatEx(buffer, 512, "%T", "slap", g_Warden.Id);
	menu.AddItem("", buffer);

	FormatEx(buffer, 512, "%T", "slap_5", g_Warden.Id);
	menu.AddItem("", buffer);

	FormatEx(buffer, 512, "%T", "slap_10", g_Warden.Id);
	menu.AddItem("", buffer);

	menu.Display(g_Warden.Id, 0);
}

int Menu_SlapCallback(Menu menu, MenuAction action, int param1, int param2) {
	if (param1 != g_Warden.Id) return;
	if (action == MenuAction_End) delete menu; g_Warden.Tool = WardenTool_None;

	if (action == MenuAction_Select) {
		switch (param2) {
			case 0: Menu_SlapChange();
			case 3: AddSlaps(2);
			case 4: AddSlaps(9);
		}

		if (param2 != 0) {
			if (g_Warden.Slap != 0) SlapPlayer(g_Warden.Slap, 0);
			else {
				for (int i = 1; i <= MaxClients; i++) {
					if (!IsValidPlayer(i)) continue;
					if (!IsPlayerAlive(i)) continue;
					if (GetClientTeam(i) != 2) continue;
					SlapPlayer(i, 0);
				}
			}

			Menu_Slap();
		}
	}
}

void Menu_SlapChange(int startIndex = 0) {
	char[] buffer = new char[512];
	Menu menu = new Menu(Menu_SlapChangeCallback);
	menu.ExitBackButton = true;

	FormatEx(buffer, 512, "%T - %T - %T\n ", "warden_tools", g_Warden.Id, "slap", g_Warden.Id, "change_target", g_Warden.Id);
	menu.SetTitle(buffer);

	char[] index = new char[4];

	for (int i = 0; i <= MaxClients; i++) {
		if (i != 0) {
			if (!IsValidPlayer(i)) continue;
			if (!IsPlayerAlive(i)) continue;
			if (GetClientTeam(i) != 2) continue;
		}

		FormatEx(index, 4, "%i", i);
		if (i == 0) FormatEx(buffer, 512, "%T", "all_t", g_Warden.Id);
		else FormatEx(buffer, 512, "%N", i);
		
		menu.AddItem(index, buffer, i != g_Warden.Slap ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	}

	menu.DisplayAt(g_Warden.Id, RoundToFloor(startIndex / 6.0) * 6, 0);
}

int Menu_SlapChangeCallback(Menu menu, MenuAction action, int param1, int param2) { 
	if (param1 != g_Warden.Id) return;
	if (action == MenuAction_End) delete menu; g_Warden.Tool = WardenTool_None;

	if (action == MenuAction_Cancel) {
		if (param2 == MenuCancel_ExitBack) Menu_Slap();
	}

	if (action == MenuAction_Select) {
		char[] index = new char[4];
		menu.GetItem(param2, index, 4);

		g_Warden.Slap = StringToInt(index);
		Menu_SlapChange(param2);
	}
}

void Menu_FreezeJump() {
	char[] buffer = new char[512];
	Menu menu = new Menu(Menu_FreezeJumpCallback);

	FormatEx(buffer, 512, "%T - %T\n ", "warden_tools", g_Warden.Id, "freezejump", g_Warden.Id);
	menu.SetTitle(buffer);

	FormatEx(buffer, 512, "%T", "start", g_Warden.Id);
	menu.AddItem("", buffer, g_Warden.CurrentTime == 0 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

	FormatEx(buffer, 512, "%T", "stop", g_Warden.Id);
	menu.AddItem("", buffer, g_Warden.CurrentTime != 0 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

	menu.Display(g_Warden.Id, 0);
	g_Warden.Tool = WardenTool_FreezeJump;
}

int Menu_FreezeJumpCallback(Menu menu, MenuAction action, int param1, int param2) {
	if (param1 != g_Warden.Id) return;
	if (action == MenuAction_End) delete menu; g_Warden.Tool = WardenTool_None;

	if (action == MenuAction_Select) {
		switch (param2) {
			case 0: StartFreezeJump();
			case 1: StopMinigame(true);
		}

		Menu_FreezeJump();
	}
}