void Menu_Special() {
	char[] buffer = new char[512];
	Menu menu = new Menu(Menu_SpecialCallback);
	menu.ExitBackButton = true;

	FormatEx(buffer, 512, "%T - %T\n ", "warden_tools", g_Warden.Id, "specialdays", g_Warden.Id);
	menu.SetTitle(buffer);

	menu.AddItem("", "Hunger Games");
	menu.AddItem("", "One in the Chamber");
	menu.AddItem("", "Team DeathMatch");
	menu.AddItem("", "ESP FFA");
	menu.AddItem("", "Gravity Scout FFA");
	menu.AddItem("", "War Day");
	menu.AddItem("", "Hide n Seek");
	menu.AddItem("", "Flashbang FFA");
	menu.AddItem("", "Grenade Toss FFA");
	menu.AddItem("", "Zombie Day");
	menu.AddItem("", "Custom");

	menu.Display(g_Warden.Id, 0);
}

int Menu_SpecialCallback(Menu menu, MenuAction action, int param1, int param2) {
	if (param1 != g_Warden.Id) return;
	if (action == MenuAction_End) delete menu; g_Warden.Tool = WardenTool_None;

	if (action == MenuAction_Cancel) {
		if (param2 == MenuCancel_ExitBack) Menu_WardenTools();
	}

	if (action == MenuAction_Select) Days_PreStart(param2 + 1);	
}

void SetSpawn() {
	Menu menu = new Menu(Menu_SetSpawn);
	menu.SetTitle("Warden Tools - Special Day\n ");

	menu.AddItem("", "Set Spawn", g_Spec.Type != SpecialDay_Custom ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	menu.AddItem("", "", ITEMDRAW_SPACER);
	menu.AddItem("", "Start", g_Spec.Pos[0] != 0.0 && g_Spec.Type != SpecialDay_Custom ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

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

				GetClientAbsOrigin(g_Warden.Id, g_Spec.Pos);
				g_Spec.Entity = SpawnParticle(g_Spec.Pos, "thunder_cloud_s");
			}
			case 2: Days_Start();
		}

		if (param2 == 0) SetSpawn();
	}
}

void Days_PreStart(int dayType) {
	g_Spec.Type = dayType;
	g_RoundsRemaining = 4;
	SetSpawn();

	switch (g_Spec.Type) {
		case SpecialDay_HungerGames: PrintToChatAll("[Hunger Games] Hunger Games has been selected!");
		case SpecialDay_Chamber: PrintToChatAll("[OITC] One in the Chamber has been selected!");
		case SpecialDay_TDM: PrintToChatAll("[TDM Day] Team Death Match has been selected!");
		case SpecialDay_FFA: PrintToChatAll("[ESP FFA] ESP Free-For-All has been selected!");
		case SpecialDay_Scout: PrintToChatAll("[Scout FFA] Scout Free-For-All has been selected!");
		case SpecialDay_War: PrintToChatAll("[War Day] War day has been selected!");
		case SpecialDay_Hide: PrintToChatAll("[Hide N Seek] Hide N Seek has been selected!");
		case SpecialDay_Flash: PrintToChatAll("[Flashbang FFA] Flashbang FFA has been selected!");
		case SpecialDay_Grenade: PrintToChatAll("[Grenade Toss FFA] Grenade Toss FFA has been selected!");
		case SpecialDay_Zombie: PrintToChatAll("[Zombie] Zombie Day has been selected!");
		case SpecialDay_Custom: PrintToChatAll("[Custom Special Day] The Custom Special Day has been selected!");
	}
}

void Days_Start() {
	g_Spec.Seconds = gI_DayTimes[g_Spec.Type - 1] + 3;

	switch (g_Spec.Type) {
		case SpecialDay_Custom: PrintToChatAll("[Custom Special Day] The Custom Special Day has officially started!");
		case SpecialDay_HungerGames: { BlindFreeze(); ClearPlayerWeapons(false); }
		case SpecialDay_Chamber: { BlindFreeze(); ClearPlayerWeapons(false); }
		case SpecialDay_TDM: BlindFreeze();
		case SpecialDay_FFA: { BlindFreeze(); RandomizeTeams(4, true, true); }
		case SpecialDay_Scout: { BlindFreeze(); ClearPlayerWeapons(true); }
		case SpecialDay_War: BlindFreeze(2);
		case SpecialDay_Hide: { BlindFreeze(); ClearPlayerWeapons(true); }
		case SpecialDay_Flash: { BlindFreeze(); ClearPlayerWeapons(true); }
		case SpecialDay_Zombie: { BlindFreeze(); }
		case SpecialDay_Grenade: { BlindFreeze(); ClearPlayerWeapons(true); }
	}

	if (g_Spec.Type != SpecialDay_Custom) {
		g_Spec.Invisibility = true;
		g_Spec.Invulnerability = true;

		if (g_Spec.Type == SpecialDay_HungerGames || g_Spec.Type == SpecialDay_Zombie) g_Spec.Invisibility = false;
	}
}

void BlindFreeze(int team = 0) {
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsValidPlayer(i) || !IsPlayerAlive(i)) continue;
		if (team != 0 && GetClientTeam(i) != team) continue;

		PerformBlind(i, 255);
		SetEntityMoveType(i, MOVETYPE_NONE);
	}

	CreateTimer(3.0, Timer_BlindFreeze, team);
}

public Action Timer_BlindFreeze(Handle timer, int team) {
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsValidPlayer(i) || !IsPlayerAlive(i)) continue;
		if (team != 0 && GetClientTeam(i) != team) continue;

		TeleportEntity(i, g_Spec.Pos, NULL_VECTOR, NULL_VECTOR);
	}
}

void Unfreeze(int team = 0) {
	float pos[3];

	for (int i = 1; i <= MaxClients; i++) {
		if (!IsValidPlayer(i) || !IsPlayerAlive(i)) continue;
		if (team != 0 && GetClientTeam(i) != team) continue;

		PerformBlind(i, 0);

		if (GetEntityMoveType(i) == MOVETYPE_NONE) {
			GetClientEyePosition(i, pos);
			SetEntityMoveType(i, MOVETYPE_WALK);
			EmitAmbientSound(g_FreezeSound, pos, i, SNDLEVEL_RAIDSIREN);
		}
	}
}

public Action Timer_Second(Handle timer, any data) {
	if (g_Spec.Seconds != 0) {
		g_Spec.Seconds--;

		switch (g_Spec.Type) {
			case SpecialDay_HungerGames: Day_HungerGame();
			case SpecialDay_Chamber: Day_Chamber();
			case SpecialDay_TDM: Day_TDM();
			case SpecialDay_FFA: Day_FFA();
			case SpecialDay_Scout: Day_Scout();
			case SpecialDay_War: Day_War();
			case SpecialDay_Hide: Day_Hide();
			case SpecialDay_Flash: Day_Flash();
			case SpecialDay_Grenade: Day_Grenade();
			case SpecialDay_Zombie: Day_Zombie();
		}

		if (g_Spec.Seconds == 0) {
			g_Spec.Invisibility = false;
			g_Spec.Invulnerability = false;
		}
	}
}

void Day_Zombie() {
	switch (g_Spec.Seconds) {
		case 10: PrintToChatAll("[Zombie] Zombie will be picked in 10 Seconds!");
		case 5: PrintToChatAll("[Zombie] Zombie will be picked in 5 Seconds!");
		case 0: PrintToChatAll("[Zombie] Zombie has been picked, good luck!");
	}

	if (g_Spec.Seconds == (gI_DayTimes[g_Spec.Type - 1] - 3)) Unfreeze();

	if (g_Spec.Seconds == 0) {
		int zombie = GetRandomAlivePerson();

		if (zombie != -1) SetZombie(zombie, false);
		PrintToChatAll("[Zombie] %N is now the zombie", zombie);
	}
}

int GetRandomAlivePerson() {
	int[] validPlayers = new int[MaxClients];
	int totalPlayers;

	for (int i = 1; i <= MaxClients; i++) {
		if (!IsValidPlayer(i) || !IsPlayerAlive(i)) continue;
		validPlayers[totalPlayers] = i;
		totalPlayers++;
	}
	
	if (totalPlayers > 0) return validPlayers[GetRandomInt(0, totalPlayers - 1)];
	else return -1;
}

void SetZombie(int client, bool announce = true) {
	g_Players[client].Zombie = true;
	RequestFrame(Frame_SetZombie, client);

	if (announce) PrintToChat(client, "[Zombie] You are now a Zombie!");
}

void Frame_SetZombie(int client) {
	SetEntityModel(client, g_ZombieModel);
	SetEntPropString(client, Prop_Send, "m_szArmsModel", g_ZombieArms);
	SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 1.2);
	SetEntProp(client, Prop_Send, "m_iHealth", 25000);

	ClearPlayerWeapon(client, false);
}

void Day_HungerGame() {
	switch (g_Spec.Seconds) {
		case 20: PrintToChatAll("[Hunger Games] Hunger Games will officially start in 20 Seconds!");
		case 15: PrintToChatAll("[Hunger Games] 15 Seconds of safety left!");
		case 10: PrintToChatAll("[Hunger Games] 10 Seconds of safety left!");
		case 5: PrintToChatAll("[Hunger Games] 5 Seconds of safety left!");
		case 0: PrintToChatAll("[Hunger Games] Hunger Games Day has officially started, goodluck!");
	}

	if (g_Spec.Seconds == (gI_DayTimes[g_Spec.Type - 1] - 3)) Unfreeze();

	if (g_Spec.Seconds == 0) {
		g_cIgnoreRoundWin.SetInt(1);
		for (int i = 1; i <= MaxClients; i++) {
			if (!IsValidPlayer(i)) continue;
			if (!IsPlayerAlive(i)) continue;

			int primary = GivePlayerItem(i, gC_Primary[GetRandomInt(0, sizeof(gC_Primary) - 1)]);
			EquipPlayerWeapon(i, primary);
			g_AllowedPickup.Push(primary);

			int secondary = GivePlayerItem(i, gC_Secondary[GetRandomInt(0, sizeof(gC_Secondary) - 1)]);
			EquipPlayerWeapon(i, secondary);
			g_AllowedPickup.Push(secondary);

			GivePlayerItem(i, "weapon_healthshot");
			SetEntProp(i, Prop_Send, "m_iHealth", GetRandomInt(100, 132));
		}
	}
}

void Day_Chamber() {
	switch (g_Spec.Seconds) {
		case 15: PrintToChatAll("[OITC] One in the Chamber will officially start in 15 Seconds:");
		case 10: PrintToChatAll("[OITC] 10 Seconds of safety left!");
		case 5: PrintToChatAll("[OITC] 5 Seconds of safety left!");
		case 0: PrintToChatAll("[OITC] OITC Day has officially started, goodluck!");
	}

	if (g_Spec.Seconds == (gI_DayTimes[g_Spec.Type - 1] - 3)) Unfreeze();

	if (g_Spec.Seconds == 0) {
		g_cIgnoreRoundWin.SetInt(1);
		for (int i = 1; i <= MaxClients; i++) {
			if (!IsValidPlayer(i)) continue;
			if (!IsPlayerAlive(i)) continue;

			int weapon = GivePlayerItem(i, "weapon_deagle");
			SetEntProp(weapon, Prop_Data, "m_iClip1", 1);
			SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", 0);
			EquipPlayerWeapon(i, weapon);
		}
	}
}

void Day_TDM() {
	switch (g_Spec.Seconds) {
		case 20: PrintToChatAll("[TDM Day] You have 20 Seconds till the day starts!");
		case 10: PrintToChatAll("[TDM Day] You have 10 Seconds left till the day starts!");
		case 0: PrintToChatAll("[TDM Day] TDM Day has officially started, goodluck!");
	}

	if (g_Spec.Seconds == (gI_DayTimes[g_Spec.Type - 1] - 3)) Unfreeze();
}

void Day_FFA() {
	switch (g_Spec.Seconds) {
		case 15: PrintToChatAll("[ESP FFA] You have 15 Seconds till the day starts!");
		case 5: PrintToChatAll("[ESP FFA] 5 Seconds till the day starts!");
		case 0: PrintToChatAll("[ESP FFA] ESP FFA day has officially started, goodluck!");
	}

	if (g_Spec.Seconds == (gI_DayTimes[g_Spec.Type - 1] - 3)) Unfreeze();

	if (g_Spec.Seconds == 0) {
		g_cIgnoreRoundWin.SetInt(1);
		for (int i = 1; i <= MaxClients; i++) {
			if (!IsValidPlayer(i)) continue;
			if (!IsPlayerAlive(i)) continue;

			SetClientTeam(i, 0, false);
		}
	}
}

void Day_Scout() {
	switch (g_Spec.Seconds) {
		case 20: PrintToChatAll("[Scout FFA] You have 20 seconds till the day starts!");
		case 10: PrintToChatAll("[Scout FFA] You have 10 seconds till the day starts!");
		case 0: PrintToChatAll("[Scout FFA] Scout FFA day has officially started, goodluck!");
	}

	if (g_Spec.Seconds == (gI_DayTimes[g_Spec.Type - 1] - 3)) Unfreeze();

	if (g_Spec.Seconds == 0) {
		g_cIgnoreRoundWin.SetInt(1);
		for (int i = 1; i <= MaxClients; i++) {
			if (!IsValidPlayer(i)) continue;
			if (!IsPlayerAlive(i)) continue;

			int weapon = GivePlayerItem(i, "weapon_ssg08");
			EquipPlayerWeapon(i, weapon);

			int knife = GivePlayerItem(i, "weapon_knife");
			EquipPlayerWeapon(i, knife);

			SetEntityGravity(i, 0.3);
		}
	}
}

void Day_War() {
	switch (g_Spec.Seconds) {
		case 10: PrintToChatAll("[War Day] T's have been frozen for 10 Seconds!");
		case 5: PrintToChatAll("[War Day] T's will be unfrozen in 5 Seconds!");
		case 0: PrintToChatAll("[War Day] War day has officially started, goodluck!");
	}

	if (g_Spec.Seconds == 0) Unfreeze();
}

void Day_Hide() {
	switch (g_Spec.Seconds) {
		case 30: PrintToChatAll("[Hide N Seek] CT's will be blinded & frozen for the next 30 seconds");
		case 20: PrintToChatAll("[Hide N Seek] CT's will be able to hunt the T's in 20 Seconds!");
		case 10: PrintToChatAll("[Hide N Seek] CT's will be able to hunt the T's in 10 Seconds!");
		case 0: PrintToChatAll("[Hide N Seek] Hide N Seek day has officially started, CT's are out to HUNT, goodluck!");
	}

	if (g_Spec.Seconds == 0) {
		Unfreeze();
		for (int i = 1; i <= MaxClients; i++) {
			if (!IsValidPlayer(i)) continue;
			if (!IsPlayerAlive(i)) continue;
			if (GetClientTeam(i) != 3) continue;

			int knife = GivePlayerItem(i, "weapon_knife");
			EquipPlayerWeapon(i, knife);
		}
	}

	if (g_Spec.Seconds > 0) {
		SetHudTextParams(-1.0, -1.0, 1.0, 255, 255, 255, 255, 1, 1.0, 1.0, 1.0);

		for (int i = 1; i <= MaxClients; i++) {
			if (!IsValidPlayer(i)) continue;
			if (!IsPlayerAlive(i)) continue;
			if (GetClientTeam(i) != 3) continue;
			ShowSyncHudText(i, g_HudSync, "%i", g_Spec.Seconds);
		}
	}
}

void Day_Flash() {
	switch (g_Spec.Seconds) {
		case 10: PrintToChatAll("[Flashbang FFA] You have 10 seconds till the day starts!");
		case 5: PrintToChatAll("[Flashbang FFA] You have 5 seconds till the day starts!");
		case 0: PrintToChatAll("[Flashbang FFA] Flashbang FFA day has officially started, goodluck!");
	}

	if (g_Spec.Seconds == (gI_DayTimes[g_Spec.Type - 1] - 3)) Unfreeze();

	if (g_Spec.Seconds == 0) {
		g_cIgnoreRoundWin.SetInt(1);

		for (int i = 1; i <= MaxClients; i++) {
			if (!IsValidPlayer(i)) continue;
			if (!IsPlayerAlive(i)) continue;

			int flashbang = GivePlayerItem(i, "weapon_flashbang");
			EquipPlayerWeapon(i, flashbang);

			SetEntProp(i, Prop_Send, "m_iHealth", 1);
			SetEntData(i, g_offsCollisionGroup, 5, 4, true);
		}
	}
}

void Day_Grenade() {
	switch (g_Spec.Seconds) {
		case 10: PrintToChatAll("[Grenade Toss FFA] You have 10 seconds till the day starts!");
		case 5: PrintToChatAll("[Grenade Toss FFA] You have 5 seconds till the day starts!");
		case 0: PrintToChatAll("[Grenade Toss FFA] Grenade Toss FFA day has officially started, goodluck!");
	}

	if (g_Spec.Seconds == (gI_DayTimes[g_Spec.Type - 1] - 3)) Unfreeze();

	if (g_Spec.Seconds == 0) {
		g_cIgnoreRoundWin.SetInt(1);

		for (int i = 1; i <= MaxClients; i++) {
			if (!IsValidPlayer(i)) continue;
			if (!IsPlayerAlive(i)) continue;

			int grenade = GivePlayerItem(i, "weapon_hegrenade");
			EquipPlayerWeapon(i, grenade);

			SetEntProp(i, Prop_Send, "m_iHealth", 20);
		}
	}
}

void ClearPlayerWeapon(int client, bool removeKnife = true) {
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
	}
}

void ClearPlayerWeapons(bool removeKnife = true) {
	for (int i = 1; i<= MaxClients; i++) {
		if (!IsValidPlayer(i)) continue;
		if (!IsPlayerAlive(i)) continue;
		ClearPlayerWeapon(i, removeKnife);
	}
}

public OnEntityCreated(int entity, const char[] classname) {
	if (g_Spec.Type == SpecialDay_Grenade && StrEqual(classname, "hegrenade_projectile")) SDKHook(entity, SDKHook_SpawnPost, Hook_Grenade);
	if (g_Spec.Type == SpecialDay_Flash && StrEqual(classname, "flashbang_projectile")) SDKHook(entity, SDKHook_SpawnPost, Hook_Flashbang);
}

public void Hook_Flashbang(int entity) {
	int thrower = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	SetEntProp(entity, Prop_Data, "m_nNextThinkTick", -1);

	if (!IsValidPlayer(thrower)) return;
	GiveThrowable(thrower, false);
}

public void Hook_Grenade(int entity) {
	int thrower = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");

	if (!IsValidPlayer(thrower)) return;
	GiveThrowable(thrower, true);
}

void GiveThrowable(int client, bool grenade) {
	DataPack pack = new DataPack();
	pack.WriteCell(client);
	pack.WriteCell(view_as<int>(grenade));

	CreateTimer(1.0, Timer_Throwable, pack);
}

public Action Timer_Throwable(Handle timer, DataPack pack) {
	pack.Reset();

	int client = pack.ReadCell();
	bool grenade = view_as<bool>(pack.ReadCell());

	int throwable;

	if (grenade) throwable = GivePlayerItem(client, "weapon_hegrenade");
	else throwable = GivePlayerItem(client, "weapon_flashbang");

	if (throwable) EquipPlayerWeapon(client, throwable);
}