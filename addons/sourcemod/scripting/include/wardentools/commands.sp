public Action Command_Warden(int client, int args) {
	char[] buffer = new char[512];
	int clientTeam = GetClientTeam(client);
	
	if (clientTeam != 3) {
		if (g_Warden.Id != 0) {
			FormatEx(buffer, 512, "%s%N", CHAT_HIGHLIGHT, g_Warden.Id);
			PrintToChat(client, "%s%t", PLUGIN_PREFIX, "announce_current_warden", buffer);
		} else {
			PrintToChat(client, "%s%t", PLUGIN_PREFIX, "announce_no_warden");
		}
		return Plugin_Handled;
	}

	if (g_Warden.Id != 0) {
		if (g_Warden.Id != client) {
			FormatEx(buffer, 512, "%s%N", CHAT_HIGHLIGHT, g_Warden.Id);
			PrintToChat(client, "%s%t", PLUGIN_PREFIX, "announce_current_warden", buffer);
		} else {
			PrintToChat(client, "%s%t", PLUGIN_PREFIX, "announce_currently_warden");
		}

		return Plugin_Handled;
	}

	if (!CanBeWarden(client)) {
		PrintToChat(client, "%s%t", PLUGIN_PREFIX, "announce_unable_to_take");
	}

	SetWarden(client, true);
	return Plugin_Handled;
}

public Action Command_UnWarden(int client, int args) {
	if (!CanBeWarden(client)) return Plugin_Handled;

	if (g_Warden.Id != client) {
		PrintToChat(client, "%s%t", PLUGIN_PREFIX, "announce_currently_not_warden");
		return Plugin_Handled;
	}

	UnsetWarden(true);
	return Plugin_Handled;
}

public Action Command_ResetWarden(int client, int args) {
	if (g_Warden.Id == 0) {
		PrintToChat(client, "%s%t", PLUGIN_PREFIX, "announce_no_warden");
		return Plugin_Handled;
	}

	char[] buffer = new char[512];
	FormatEx(buffer, 512, "%s%N", CHAT_HIGHLIGHT, g_Warden.Id);
	ShowActivity2(client, PLUGIN_PREFIX, "%t", "announce_fired", buffer);
	
	UnsetWarden();
	return Plugin_Handled;
}

public Action Command_ForceWarden(int client, int args) {
	char[] arg = new char[256];
	GetCmdArg(1, arg, 256);
	int target = FindTarget(client, arg);

	if (target == -1) return Plugin_Handled;

	if (!CanBeWarden(target)) {
		PrintToChat(client, "%s%t", PLUGIN_PREFIX, "announce_unable_to_take_target");
		return Plugin_Handled;
	}

	char[] buffer = new char[512];
	FormatEx(buffer, 512, "%s%N", CHAT_HIGHLIGHT, target);
	ShowActivity2(client, PLUGIN_PREFIX, "%t", "announce_set_warden", buffer);

	UnsetWarden();
	SetWarden(target);
	return Plugin_Handled;
}

public Action Command_WardenTools(int client, int args) {
	if (!CanBeWarden(client)) return Plugin_Handled;

	if (g_Warden.Id != client) {
		PrintToChat(client, "%s%t", PLUGIN_PREFIX, "announce_currently_not_warden");
		return Plugin_Handled;
	}

	Menu_WardenTools();
	return Plugin_Handled;
}

public Action Command_Beacon(int client, int args) {
	if (!CanBeWarden(client)) return Plugin_Handled;

	if (g_Warden.Id != client) {
		PrintToChat(client, "%s%t", PLUGIN_PREFIX, "announce_currently_not_warden");
		return Plugin_Handled;
	}

	float gameTime = GetGameTime();

	if (g_Warden.BeaconLastPlaced + 1.0 > gameTime) return Plugin_Handled;
	g_Warden.BeaconLastPlaced = gameTime;

	float pos[3];
	RayTrace(client, pos);

	pos[2] += 5.0;

	if (g_Players[client].BeaconPref < sizeof(g_Colors)) {
		TE_SetupBeamRingPoint(pos, 100.0, 100.1, g_Models.Laser, g_Models.Glow, 0, 30, g_BeaconTimes[g_Warden.BeaconEndOption], 5.0, 1.0, g_Colors[g_Players[client].BeaconPref], 0, 0);
		TE_SendToAll();
	} else {
		Beacon beacon; g_Beacons.GetArray(g_Players[client].BeaconPref - sizeof(g_Colors), beacon);

		Entity entity;
		entity.Index = SpawnParticle(pos, beacon.Name);
		entity.End = gameTime + g_BeaconTimes[g_Warden.BeaconEndOption];
		g_Entities.PushArray(entity);
	}

	return Plugin_Handled;
}