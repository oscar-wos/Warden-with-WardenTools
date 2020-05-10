void Menu_Special() {
	char[] buffer = new char[512];
	Menu menu = new Menu(Menu_SpecialCallback);
	menu.ExitBackButton = true;

	FormatEx(buffer, 512, "%T - %T\n ", "warden_tools", g_Warden.Id, "specialdays", g_Warden.Id);
	menu.SetTitle(buffer);

	if (g_SpecialDay != SpecialDay_None) {
		menu.AddItem("", "Stop!");
	} else {
		menu.AddItem("", "Hunger Games");
		menu.AddItem("", "One in the Chamber");
		menu.AddItem("", "Team Deathmatch");
		menu.AddItem("", "AWP Noscope");
		menu.AddItem("", "War Day");
		menu.AddItem("", "Hide n Seek");
		menu.AddItem("", "Custom");
	}

	menu.Display(g_Warden.Id, 0);
}

int Menu_SpecialCallback(Menu menu, MenuAction action, int param1, int param2) {
	if (param1 != g_Warden.Id) return;
	if (action == MenuAction_End) delete menu; g_Warden.Tool = WardenTool_None;

	if (action == MenuAction_Cancel) {
		if (param2 == MenuCancel_ExitBack) Menu_WardenTools();
	}

	if (action == MenuAction_Select) {
		if (g_SpecialDay != SpecialDay_None) {
			g_SpecialDay = SpecialDay_None;
			g_Invulnerability = false;

			PrintToChatAll("%sSpecial Day has been forcefully stopped", PLUGIN_PREFIX);
		} else {
			switch (param2) {
				case 0: StartHungerGames();
				case 1: StartChamber();
				case 2: StartTDM();
				case 3: StartAWP();
				case 4: StartWarDay();
				case 5: StartHide();
				case 6: StartCustom();
			}
		}
	}
}

void StartHungerGames() {
	ClearWeapons();

	float wardenPos[3];
	GetClientAbsOrigin(g_Warden.Id, wardenPos);
	g_Invulnerability = true;

	for (int i = 1; i <= MaxClients; i++) {
		if (!IsValidPlayer(i)) continue;
		if (!IsPlayerAlive(i)) continue;

		SetEntProp(i, Prop_Send, "m_iHealth", GetRandomInt(100, 135));
		if (i != g_Warden.Id) TeleportEntity(i, wardenPos, NULL_VECTOR, NULL_VECTOR);
	}	
	
	PrintToChatAll("%sHunger Games has started! You have 15 seconds of immunity and invulnerability", PLUGIN_PREFIX);
	CreateTimer(15.0, Start_HungerGames);
	g_SpecialDay = SpecialDay_HungerGames;
}

Action Start_HungerGames(Handle timer, any data) {
	g_SpecialDay = SpecialDay_None;
	g_Invulnerability = false;
	
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsValidPlayer(i)) continue;
		if (!IsPlayerAlive(i)) continue;

		int random = GetRandomInt(0, sizeof(gC_Weapons));
		int weapon = GivePlayerItem(i, gC_Weapons[random][0]);
		EquipPlayerWeapon(i, weapon);

		GivePlayerItem(i, "weapon_healthshot");
		PrintToChat(i, "%sYou've been given an %s", PLUGIN_PREFIX, gC_Weapons[random][1]);
	}

	g_SpecialDay = SpecialDay_HungerGames;
}

void StartChamber() {
	ClearWeapons();

	for (int i = 1; i <= MaxClients; i++) {
		if (!IsValidPlayer(i)) continue;
		if (!IsPlayerAlive(i)) continue;

		int weapon = GivePlayerItem(i, "weapon_deagle");
		SetEntProp(weapon, Prop_Data, "m_iClip1", 1);
		SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", 0);
	}

	g_FriendlyFire = FriendlyFire_TrueAll;
	PrintToChatAll("%sOne in the Chamber has started!", PLUGIN_PREFIX);
	g_SpecialDay = SpecialDay_Chamber;
}

void StartTDM() {
	g_FriendlyFire = FriendlyFire_Team;
	RandomizeTeams(4, true, true);

	PrintToChatAll("%sTDM has started!", PLUGIN_PREFIX);
	g_SpecialDay = SpecialDay_TDM;
}

void StartAWP() {
	ClearWeapons();

	for (int i = 1; i <= MaxClients; i++) {
		if (!IsValidPlayer(i)) continue;
		if (!IsPlayerAlive(i)) continue;
		if (GetClientTeam(i) != 3) continue;

		int awp = GivePlayerItem(i, "weapon_awp");
		EquipPlayerWeapon(i, awp);
	}

	PrintToChatAll("%sAWP noscope has started!", PLUGIN_PREFIX);
	g_SpecialDay = SpecialDay_AWP;
}

void StartWarDay() {
	float pos[3];
	DataPack pack = new DataPack();
	GetClientAbsOrigin(g_Warden.Id, pos);

	pack.WriteFloat(pos[0]);
	pack.WriteFloat(pos[1]);
	pack.WriteFloat(pos[2]);
	CreateTimer(15.0, Start_Warday, pack);

	PrintToChatAll("%sWarDay has started! T's will be teleported to the Warden's current position in 15 seconds", PLUGIN_PREFIX);
	g_SpecialDay = SpecialDay_War;
}

Action Start_Warday(Handle timer, DataPack pack) {
	float pos[3];
	pack.Reset();

	pos[0] = pack.ReadFloat();
	pos[1] = pack.ReadFloat();
	pos[2] = pack.ReadFloat();

	for (int i = 1; i <= MaxClients; i++) {
		if (!IsValidPlayer(i)) continue;
		if (!IsPlayerAlive(i)) continue;
		if (GetClientTeam(i) != 2) continue;

		TeleportEntity(i, pos, NULL_VECTOR, NULL_VECTOR);
	}

	CloseHandle(pack);
}

void StartHide() {
	g_Invulnerability = true;
	CreateTimer(15.0, Start_Hide);

	PrintToChatAll("%sHide n Seek has started! Invisibility & Invulnerability ends in 15 seconds", PLUGIN_PREFIX);
	g_SpecialDay = SpecialDay_Hide;
}

Action Start_Hide(Handle timer, any data) {
	g_Invulnerability = false;
	PrintToChatAll("%sInvisibility & Invulnerability has ended!", PLUGIN_PREFIX);
}

void ClearWeapons() {
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsValidPlayer(i)) continue;
		if (!IsPlayerAlive(i)) continue;

		for (int x = 0; x < 6; x++) {
			int weaponEntity = GetPlayerWeaponSlot(i, x);

			if (weaponEntity == -1) continue;
			AcceptEntityInput(weaponEntity, "Kill");
		}

		int knife = GivePlayerItem(i, "weapon_knife");
		EquipPlayerWeapon(i, knife);
	}
}

void StartCustom() {
	PrintToChatAll("%sCustom Special Day started! Listen to the Warden for more information!", PLUGIN_PREFIX);
	g_SpecialDay = SpecialDay_Custom;
}

