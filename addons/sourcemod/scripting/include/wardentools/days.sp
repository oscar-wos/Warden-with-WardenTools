void Menu_Special() {
	char[] buffer = new char[512];
	Menu menu = new Menu(Menu_SpecialCallback);
	menu.ExitBackButton = true;

	FormatEx(buffer, 512, "%T - %T\n ", "warden_tools", g_Warden.Id, "specialdays", g_Warden.Id);
	menu.SetTitle(buffer);

	if (g_Spec.Type != SpecialDay_None) {
		menu.AddItem("", "Stop!");
	} else {
		menu.AddItem("", "Hunger Games");
		menu.AddItem("", "One in the Chamber");
		menu.AddItem("", "Team DeathMatch");
		menu.AddItem("", "ESP FFA");
		menu.AddItem("", "CT AWP NoScope");
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
		if (g_Spec.Type != SpecialDay_None) {
			SpecialDay newSpecialDay;
			g_Spec = newSpecialDay;

			for (int i = 1; i <= MaxClients; i++) {
				if (!IsValidPlayer(i)) continue;
				if (!IsPlayerAlive(i)) continue;
				
				PerformBlind(i, 0);
				SetEntityMoveType(i, MOVETYPE_WALK);
				g_Players[i].Team = 0;
				
				if (IsValidEntity(g_Players[i].Glow) && IsValidEdict(g_Players[i].Glow)) AcceptEntityInput(g_Players[i].Glow, "Kill");
				g_Players[i].Glow = 0;

				if (IsValidEntity(g_Spec.Entity) && IsValidEdict(g_Spec.Entity)) AcceptEntityInput(g_Spec.Entity, "Kill");
				g_Spec.Entity = 0;
			}

			PrintToChatAll("%sSpecial Day has been forcefully stopped", PLUGIN_PREFIX);
		} else {
			switch (param2) {
				case 0: StartHungerGames();
				case 1: StartOneInTheChamber();
				case 2: StartTDM();
				case 3: StartFFA();
				case 4: StartAWP();
				case 5: StartWar();
				case 6: StartHide();
				case 7: StartCustom();
			}
		}
	}
}

void StartHungerGames() {
	SetSpawn();
	ClearPlayerWeapons(true);

	for (int i = 1; i <= MaxClients; i++) {
		if (!IsValidPlayer(i)) continue;
		if (!IsPlayerAlive(i)) continue;

		SetEntityMoveType(i, MOVETYPE_NONE);
		if (i != g_Warden.Id) PerformBlind(i, 255);
	}

	g_Spec.Type = SpecialDay_HungerGames;
	g_Spec.Invisibility = true;
	g_Spec.Invulnerability = true;
}

void StartOneInTheChamber() {
	SetSpawn();
	ClearPlayerWeapons(false);

	for (int i = 1; i <= MaxClients; i++) {
		if (!IsValidPlayer(i)) continue;
		if (!IsPlayerAlive(i)) continue;

		SetEntityMoveType(i, MOVETYPE_NONE);
		if (i != g_Warden.Id) PerformBlind(i, 255);
	}

	g_Spec.Type = SpecialDay_Chamber;
	g_Spec.Invisibility = true;
	g_Spec.Invulnerability = true;
}

void StartTDM() {
	SetSpawn();

	for (int i = 1; i <= MaxClients; i++) {
		if (!IsValidPlayer(i)) continue;
		if (!IsPlayerAlive(i)) continue;

		SetEntityMoveType(i, MOVETYPE_NONE);
		if (i != g_Warden.Id) PerformBlind(i, 255);
	}

	g_Spec.Type = SpecialDay_TDM;
	g_Spec.Invisibility = true;
	g_Spec.Invulnerability = true;
}

void StartFFA() {
	SetSpawn();

	for (int i = 1; i <= MaxClients; i++) {
		if (!IsValidPlayer(i)) continue;
		if (!IsPlayerAlive(i)) continue;

		SetEntityMoveType(i, MOVETYPE_NONE);
		if (i != g_Warden.Id) PerformBlind(i, 255);
	}

	g_Spec.Type = SpecialDay_FFA;
	g_Spec.Invisibility = true;
	g_Spec.Invulnerability = true;
}

void StartAWP() {
	SetSpawn();
	ClearPlayerWeapons(false);

	for (int i = 1; i <= MaxClients; i++) {
		if (!IsValidPlayer(i)) continue;
		if (!IsPlayerAlive(i)) continue;

		SetEntityMoveType(i, MOVETYPE_NONE);
		if (i != g_Warden.Id) PerformBlind(i, 255);
	}

	g_Spec.Type = SpecialDay_AWP;
	g_Spec.Invisibility = true;
	g_Spec.Invulnerability = true;
}

void StartWar() {
	SetSpawn();

	for (int i = 1; i <= MaxClients; i++) {
		if (!IsValidPlayer(i)) continue;
		if (!IsPlayerAlive(i)) continue;
		if (GetClientTeam(i) == 3) continue;

		SetEntityMoveType(i, MOVETYPE_NONE);
		if (i != g_Warden.Id) PerformBlind(i, 255);
	}

	g_Spec.Type = SpecialDay_War;
	g_Spec.Invisibility = true;
	g_Spec.Invulnerability = true;
}

void StartHide() {
	SetSpawn();
	ClearPlayerWeapons(true);

	for (int i = 1; i <= MaxClients; i++) {
		if (!IsValidPlayer(i)) continue;
		if (!IsPlayerAlive(i)) continue;
		if (GetClientTeam(i) == 3) continue;

		SetEntityMoveType(i, MOVETYPE_NONE);
		if (i != g_Warden.Id) PerformBlind(i, 255);
	}

	g_Spec.Type = SpecialDay_Hide;
	g_Spec.Invisibility = true;
	g_Spec.Invulnerability = true;
}

void StartCustom() {
	PrintToChatAll("%sCustom Day has Started!", PLUGIN_PREFIX);
}

void StartSpecialDay() {
	CreateTimer(25.0, Timer_25);

	switch (g_Spec.Type) {
		case SpecialDay_HungerGames: {
			for (int i = 1; i <= MaxClients; i++) {
				if (!IsValidPlayer(i)) continue;
				if (!IsPlayerAlive(i)) continue;

				PerformBlind(i, 0);
				SetEntityMoveType(i, MOVETYPE_WALK);
				TeleportEntity(i, g_Spec.Pos, NULL_VECTOR, NULL_VECTOR);
				PrintToChatAll("%sHunger Games has Started!", PLUGIN_PREFIX);
			}
		} case SpecialDay_Chamber: {
			for (int i = 1; i <= MaxClients; i++) {
				if (!IsValidPlayer(i)) continue;
				if (!IsPlayerAlive(i)) continue;

				PerformBlind(i, 0);
				SetEntityMoveType(i, MOVETYPE_WALK);
				TeleportEntity(i, g_Spec.Pos, NULL_VECTOR, NULL_VECTOR);
				PrintToChatAll("%sOne in the Chamber has Started!", PLUGIN_PREFIX);
			}
		} case SpecialDay_TDM: {
			RandomizeTeams(4, true, true);

			for (int i = 1; i <= MaxClients; i++) {
				if (!IsValidPlayer(i)) continue;
				if (!IsPlayerAlive(i)) continue;

				PerformBlind(i, 0);
				SetEntityMoveType(i, MOVETYPE_WALK);
				TeleportEntity(i, g_Spec.Pos, NULL_VECTOR, NULL_VECTOR);
				PrintToChatAll("%sTeam Deathmatch has Started!", PLUGIN_PREFIX);
			}
		} case SpecialDay_FFA: {
			for (int i = 1; i <= MaxClients; i++) {
				if (!IsValidPlayer(i)) continue;
				if (!IsPlayerAlive(i)) continue;

				PerformBlind(i, 0);
				SetEntityMoveType(i, MOVETYPE_WALK);
				TeleportEntity(i, g_Spec.Pos, NULL_VECTOR, NULL_VECTOR);

				SetClientTeam(i, 5, false);
				PrintToChatAll("%sESP FFA has Started!", PLUGIN_PREFIX);
			}
		} case SpecialDay_AWP: {
			for (int i = 1; i <= MaxClients; i++) {
				if (!IsValidPlayer(i)) continue;
				if (!IsPlayerAlive(i)) continue;
				if (GetClientTeam(i) == 3) SetEntProp(i, Prop_Send, "m_iHealth", 10000);

				PerformBlind(i, 0);
				SetEntityMoveType(i, MOVETYPE_WALK);
				TeleportEntity(i, g_Spec.Pos, NULL_VECTOR, NULL_VECTOR);
				PrintToChatAll("%sCT Awp Noscope has Started!", PLUGIN_PREFIX);
			}
		} case SpecialDay_Hide: {
			for (int i = 1; i <= MaxClients; i++) {
				if (!IsValidPlayer(i)) continue;
				if (!IsPlayerAlive(i)) continue;
				
				int clientTeam = GetClientTeam(i);
				TeleportEntity(i, g_Spec.Pos, NULL_VECTOR, NULL_VECTOR);

				if (clientTeam == 2) {
					PerformBlind(i, 0);
					SetEntityMoveType(i, MOVETYPE_WALK);
				} else {
					int weapon = GivePlayerItem(i, "weapon_knife");
					EquipPlayerWeapon(i, weapon);

					SetEntProp(i, Prop_Send, "m_iHealth", 10000);
				}
				
				PrintToChatAll("%sHide n Seek has Started!", PLUGIN_PREFIX);
			}
		}
	}
}

Action Timer_25(Handle timer, any data) {
	g_Spec.Invisibility = false;
	g_Spec.Invulnerability = false;

	switch (g_Spec.Type) {
		case SpecialDay_HungerGames: {
			for (int i = 1; i <= MaxClients; i++) {
				if (!IsValidPlayer(i)) continue;
				if (!IsPlayerAlive(i)) continue;

				int random = GetRandomInt(0, sizeof(gC_Weapons));
				int weapon = GivePlayerItem(i, gC_Weapons[random][0]);
				EquipPlayerWeapon(i, weapon);
				g_AllowedPickup.Push(weapon);

				GivePlayerItem(i, "weapon_healthshot");
			}
		} case SpecialDay_Chamber: {
			for (int i = 1; i <= MaxClients; i++) {
				if (!IsValidPlayer(i)) continue;
				if (!IsPlayerAlive(i)) continue;

				int weapon = GivePlayerItem(i, "weapon_deagle");
				SetEntProp(weapon, Prop_Data, "m_iClip1", 1);
				SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", 0);
				EquipPlayerWeapon(i, weapon);
			}
		} case SpecialDay_AWP: {
			for (int i = 1; i <= MaxClients; i++) {
				if (!IsValidPlayer(i)) continue;
				if (!IsPlayerAlive(i)) continue;
				if (GetClientTeam(i) != 3) continue;

				int weapon = GivePlayerItem(i, "weapon_awp");
				EquipPlayerWeapon(i, weapon);
			}
		} case SpecialDay_War: {
			for (int i = 1; i <= MaxClients; i++) {
				if (!IsValidPlayer(i)) continue;
				if (!IsPlayerAlive(i)) continue;
				if (GetClientTeam(i) == 3) continue;

				PerformBlind(i, 0);
				SetEntityMoveType(i, MOVETYPE_WALK);
				TeleportEntity(i, g_Spec.Pos, NULL_VECTOR, NULL_VECTOR);
			}
		} case SpecialDay_Hide: {
			for (int i = 1; i <= MaxClients; i++) {
				if (!IsValidPlayer(i)) continue;
				if (!IsPlayerAlive(i)) continue;

				PerformBlind(i, 0);
				SetEntityMoveType(i, MOVETYPE_WALK);
			}
		}
	}
}

void SetSpawn() {
	Menu menu = new Menu(Menu_SetSpawn);
	menu.ExitBackButton = true;

	menu.SetTitle("Warden Tools - Set Spawn\n ");

	menu.AddItem("", "Set Spawn");
	menu.AddItem("", "", ITEMDRAW_SPACER);
	menu.AddItem("", "Start", g_Spec.Pos[0] != 0.0  && (GetTime() - g_roundStartedTime < 60) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

	menu.Display(g_Warden.Id, 0);
}

int Menu_SetSpawn(Menu menu, MenuAction action, int param1, int param2) {
	if (param1 != g_Warden.Id) return;
	if (action == MenuAction_End) delete menu; g_Warden.Tool = WardenTool_SetSpawn;

	if (action == MenuAction_Select) {
		switch (param2) {
			case 0: {
				if (g_Spec.Entity != 0) {
					if (IsValidEntity(g_Spec.Entity) && IsValidEdict(g_Spec.Entity)) AcceptEntityInput(g_Spec.Entity, "Kill");
				}

				RayTrace(g_Warden.Id, g_Spec.Pos);
				g_Spec.Entity = SpawnParticle(g_Spec.Pos, "thunder_cloud_s");
			}
			case 2: StartSpecialDay();
		}

		if (param2 == 0) SetSpawn();
	}

	if (action == MenuAction_Cancel) {
		if (param2 == MenuCancel_ExitBack) Menu_Special();
	}
}

/*

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
	g_Spec.Type = SpecialDay_AWP;
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
	g_Spec.Type = SpecialDay_War;
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
	g_Spec.Type = SpecialDay_Hide;
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
	g_Spec.Type = SpecialDay_Custom;
}

void Menu_StartSpecialDay(int specialDay) {
	int teleportStyle; // 0 - None, 1 - Instant, 2 - Delay

	switch (specialDay) {
		case SpecialDay_AWP, SpecialDay_Chamber, SpecialDay_Hide: teleportStyle = 1;
		case SpecialDay_War: teleportStyle = 2;
	}

	if (teleportStyle == 1) {
		for (int i = 1; i <= MaxClients; i++) {
			if (!IsValidPlayer(i)) continue;
			if (!IsPlayerAlive(i)) continue;

		}
	} else if (teleportStyle == 2) {

	}

	g_Spec.Type = specialDay;
}
*/

void ClearPlayerWeapons(bool removeKnife = true) {
	for (int client = 1; client <= MaxClients; client++) {
		if (!IsValidPlayer(client)) continue;
		if (!IsPlayerAlive(client)) continue;

		int primary = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
		if (primary != -1) RemovePlayerItem(client, primary);

		int secondary = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
		if (secondary != -1) RemovePlayerItem(client, secondary);

		if (removeKnife) {
			int knife = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE);
			if (knife != -1) RemovePlayerItem(client, knife);
		}

		for (int i = 0; i < 4; i++) {
			int grenade = GetPlayerWeaponSlot(client, CS_SLOT_GRENADE);
			if (grenade != -1) RemovePlayerItem(client, grenade);

			int boost = GetPlayerWeaponSlot(client, CS_SLOT_BOOST);
			if (boost != -1) RemovePlayerItem(client, boost);

			int utility = GetPlayerWeaponSlot(client, CS_SLOT_UTILITY);
			if (utility != -1) RemovePlayerItem(client, utility);
		}
	}
}