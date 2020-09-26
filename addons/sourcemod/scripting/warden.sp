#pragma semicolon 1
#define PLUGIN_VERSION "1.00"
#define PLUGIN_PREFIX "[\x0BWarden\x01] "
#define CHAT_HIGHLIGHT "\x10"
#define PARTICLE_PATH "particles/s_aussie_pack.pcf"

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <warden>
#include <basecomm>
#include <clientprefs>
#include <cstrike>

#undef REQUIRE_PLUGIN
#include <sourcecomms>

Warden g_Warden;
Player g_Players[MAXPLAYERS + 1];
ArrayList g_Entities;
ArrayList g_Lasers;
int g_FriendlyFire;
int g_Render;

SpecialDay g_Spec;

Models g_Models;
ArrayList g_Beacons;
ArrayList g_AllowedPickup;
bool g_SourceCommsEnabled;
Cookie g_BeaconCookie;
ConVar g_cFriendlyFire;
ConVar g_cIgnoreRoundWin;
UserMsg g_FadeUserMsgId;

int m_flNextSecondaryAttack = -1;
int g_roundStartedTime = -1;
int g_offsCollisionGroup;
int g_RoundsRemaining = 0;
Handle g_HudSync;
char g_FreezeSound[PLATFORM_MAX_PATH] = "physics/glass/glass_impact_bullet4.wav";
char g_BeepSound[PLATFORM_MAX_PATH] = "buttons/button17.wav";

char g_ZombieModel[PLATFORM_MAX_PATH] = "models/player/custom_player/kodua/frozen_nazi/frozen_nazi.mdl";
char g_ZombieArms[PLATFORM_MAX_PATH] = "models/player/custom_player/kodua/frozen_nazi/arms.mdl";

int g_MicCheck[MAXPLAYERS + 1];

public Plugin myinfo = {
	name = "Warden",
	author = "Oscar",
	description = "Warden with Warden Tools",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/id/oswo"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	CreateNative("Warden_IsWarden", Native_IsWarden);
	CreateNative("Warden_WardenId", Native_WardenId);
	return APLRes_Success;
}

public void OnAllPluginsLoaded() {
	g_SourceCommsEnabled = LibraryExists("sourcecomms");
}

public void OnLibraryAdded(const char[] name) {
	if (StrEqual(name, "sourcecomms")) g_SourceCommsEnabled = true;
}

public void OnLibraryRemoved(const char[] name) {
	if (StrEqual(name, "sourcecomms")) g_SourceCommsEnabled = false;
}

public void OnPluginStart() {
	HookEvent("round_start", Hook_RoundStart);
	HookEvent("round_end", Hook_RoundEnd);
	HookEvent("player_death", Hook_PlayerDeath, EventHookMode_Post);
	HookEvent("player_spawn", Hook_PlayerSpawn);

	RegConsoleCmd("+beacon", Command_Beacon);
	RegConsoleCmd("-beacon", Command_None);

	RegConsoleCmd("sm_w", Command_Warden, "Takes Warden if available CT, displays current Warden as T");
	RegConsoleCmd("sm_uw", Command_UnWarden, "Gives up the Warden if you're currently the Warden");
	RegConsoleCmd("sm_wt", Command_WardenTools, "Shows the Warden Tools menu");

	RegAdminCmd("sm_rw", Command_ResetWarden, ADMFLAG_GENERIC, "Reset the Warden");
	RegAdminCmd("sm_fw", Command_ForceWarden, ADMFLAG_GENERIC, "Forces a Player to be the Warden");

	LoadTranslations("common.phrases");
	LoadTranslations("warden.phrases");
	CreateTimer(0.1, Timer_Main, _, TIMER_REPEAT);
	CreateTimer(1.0, Timer_Second, _, TIMER_REPEAT);

	ClearTeams();

	g_Beacons = new ArrayList(sizeof(Beacon));
	g_Entities = new ArrayList(sizeof(Entity));
	g_Lasers = new ArrayList(sizeof(Laser));
	g_AllowedPickup = new ArrayList();
	g_BeaconCookie = new Cookie("warden_beacon", "Saves	 the preference for beacon", CookieAccess_Protected);
	g_FadeUserMsgId = GetUserMessageId("Fade");
	g_cFriendlyFire = FindConVar("mp_friendlyfire");
	g_cIgnoreRoundWin = FindConVar("mp_ignore_round_win_conditions");
	g_cFriendlyFire.SetBool(true, false, false);
	g_cFriendlyFire.AddChangeHook(Hook_ConVar);
	m_flNextSecondaryAttack = FindSendPropInfo("CBaseCombatWeapon", "m_flNextSecondaryAttack");
	g_offsCollisionGroup = FindSendPropInfo("CBaseEntity", "m_CollisionGroup");
	g_HudSync = CreateHudSynchronizer();

	for (int i = 1; i <= MaxClients; i++) {
		if (!IsValidPlayer(i)) continue;
		char[] cookie = new char[4];

		g_BeaconCookie.Get(i, cookie, 4);
		g_Players[i].BeaconPref = StringToInt(cookie);
		SDKHook(i, SDKHook_OnTakeDamageAlive, Hook_OnTakeDamage);
		SDKHook(i, SDKHook_WeaponCanUse, Hook_WeaponCanUse);
		SDKHook(i, SDKHook_SetTransmit, Hook_SetTransmit);
		SDKHook(i, SDKHook_PreThink, Hook_PreThink);
		SDKHook(i, SDKHook_WeaponDrop, Hook_WeaponDrop);
	}

	ServerCommand("mp_restartgame 1");

	RegConsoleCmd("sm_test", command_test);
}

public Action command_test(int client, int args) {
	int throwable = GivePlayerItem(client, "weapon_flashbang");
	EquipPlayerWeapon(client, throwable);
}

public Action Hook_PlayerSpawn(Event event, const char[] name, bool bDontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	SetEntData(client, g_offsCollisionGroup, 2, 4, true);
}

void Hook_ConVar(ConVar convar, const char[] oldValue, const char[] newValue) {
	convar.SetBool(true, false, false);
}

public void OnMapStart() {
	char[] buffer = new char[512];
	char[] path = new char[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, PLATFORM_MAX_PATH, "configs/warden/materials.txt");

	if (!FileExists(path)) SetFailState("Cannot find materials.txt");
	File materials = OpenFile(path, "r");

	while (!materials.EndOfFile()) {
		materials.ReadLine(buffer, 512);
		TrimString(buffer);
		PrecacheMaterial(buffer);
	}

	BuildPath(Path_SM, path, PLATFORM_MAX_PATH, "configs/warden/beacons.cfg");

	if (FileExists(path)) {
		KeyValues beacons = new KeyValues("beacons");
		beacons.ImportFromFile(path);

		beacons.JumpToKey("Beacons");
		beacons.GotoFirstSubKey();

		do {
			if (view_as<bool>(beacons.GetNum("active"))) {
				Beacon newBeacon;
				beacons.GetString("name", newBeacon.Name, PLATFORM_MAX_PATH);
				beacons.GetString("desc", newBeacon.Desc, PLATFORM_MAX_PATH);
				g_Beacons.PushArray(newBeacon);
			}
		} while (beacons.GotoNextKey());
	}
	
	g_Models.Laser = PrecacheModel("materials/sprites/laserbeam.vmt");
	g_Models.Glow = PrecacheModel("materials/sprites/glow01.vmt");

	AddFileToDownloadsTable(PARTICLE_PATH);
	PrecacheGeneric(PARTICLE_PATH, true);
	PrecacheParticleEffect(PARTICLE_PATH);
	PrecacheEffect();
	
	PrecacheSound(g_FreezeSound, true);
	PrecacheSound(g_BeepSound, true);
	PrecacheModel(g_ZombieModel);
	PrecacheModel(g_ZombieArms);
}

public void OnClientCookiesCached(int client) {
	char[] cookie = new char[4];

	g_BeaconCookie.Get(client, cookie, 4);
	g_Players[client].BeaconPref = StringToInt(cookie);
}

public void OnClientPostAdminCheck(int client) {
	SDKHook(client, SDKHook_OnTakeDamageAlive, Hook_OnTakeDamage);
	SDKHook(client, SDKHook_WeaponCanUse, Hook_WeaponCanUse);
	SDKHook(client, SDKHook_SetTransmit, Hook_SetTransmit);
	SDKHook(client, SDKHook_PreThink, Hook_PreThink);
	SDKHook(client, SDKHook_WeaponDrop, Hook_WeaponDrop);
}

public void OnClientDisconnect(int client) {
	SDKUnhook(client, SDKHook_OnTakeDamageAlive, Hook_OnTakeDamage);
	SDKUnhook(client, SDKHook_WeaponCanUse, Hook_WeaponCanUse);
	SDKUnhook(client, SDKHook_SetTransmit, Hook_SetTransmit);
	SDKUnhook(client, SDKHook_PreThink, Hook_PreThink);
	SDKUnhook(client, SDKHook_WeaponDrop, Hook_WeaponDrop);
}

public Action Hook_WeaponCanUse(int client, int weapon) {
	switch (g_Spec.Type) {
		case SpecialDay_Scout, SpecialDay_Chamber, SpecialDay_Flash, SpecialDay_Grenade: return Plugin_Handled;
		case SpecialDay_HungerGames: {
			if (g_AllowedPickup.FindValue(weapon) == -1) return Plugin_Handled;
		} case SpecialDay_Zombie: {
			if (g_Players[client].Zombie) return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}

public Action Hook_WeaponDrop(int client, int weapon) {
	switch (g_Spec.Type) {
		case SpecialDay_Scout, SpecialDay_Chamber: return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action Hook_OnTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype) {
	if (attacker == 0) return Plugin_Continue;
	if (g_Spec.Type != SpecialDay_None && g_Spec.Invulnerability) return Plugin_Handled;

	int victimTeam = GetClientTeam(victim);
	int attackerTeam = GetClientTeam(attacker);

	if (g_Spec.Type != SpecialDay_None) {
		switch (g_Spec.Type) {
			case SpecialDay_Chamber: {
				damage = 1337.0;
				return Plugin_Changed;
			} case SpecialDay_TDM: {
				if (g_Players[victim].Team == g_Players[attacker].Team) return Plugin_Handled;
			} case SpecialDay_War, SpecialDay_Hide: {
				if (victimTeam == attackerTeam) return Plugin_Handled;
			} case SpecialDay_Zombie: {
				if (g_Players[victim].Zombie == g_Players[attacker].Zombie) return Plugin_Handled;
				if (g_Players[attacker].Zombie) {
					bool forceEndRound = true;
					SetZombie(victim);

					for (int i = 1; i <= MaxClients; i++) {
						if (!IsValidPlayer(i) || !IsPlayerAlive(i)) continue;
						if (!g_Players[i].Zombie) forceEndRound = false;
					}

					if (forceEndRound) {
						g_cIgnoreRoundWin.SetInt(0);

						Event end = CreateEvent("round_end", true);
						end.Fire(true);
					}

					return Plugin_Changed;
				}
			}
		}
	} else {
		switch (g_FriendlyFire) {
			case FriendlyFire_Off: {
				if (victimTeam == attackerTeam) return Plugin_Handled;
			} case FriendlyFire_Team: {
				if (g_Players[victim].Team == g_Players[attacker].Team) return Plugin_Handled;
			} case FriendlyFire_All: {
				if (victimTeam == 3 && attackerTeam == 3) return Plugin_Handled;
			}
		}

		if (g_Warden.Minigame == Minigame_Shark) {
			if (victim == g_Warden.Shark) return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}

public Action Hook_SetTransmit(int entity, int client) {
	if (g_Spec.Invisibility && entity != client) return Plugin_Handled;
	return Plugin_Continue;
}

public Action Hook_PreThink(int client) {
	if (g_Spec.Type == SpecialDay_Scout) {
		int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if (!IsValidEdict(weapon)) return Plugin_Continue;

		char classname[MAX_NAME_LENGTH];
		GetEdictClassname(weapon, classname, sizeof(classname));

		if (StrEqual(classname[7], "ssg08")) SetEntDataFloat(weapon, m_flNextSecondaryAttack, GetGameTime() + 2.0);
	}

	return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2]) {
	if (client != g_Warden.Id) return;

	if (g_Warden.Tool == WardenTool_TeamPicker) {
		if (buttons & IN_USE) {
			int target = GetClientAimTarget(client, true);
			if (target < 0) return;

			if (g_Players[target].Team == g_Warden.TeamPicked + 1) return;
			SetClientTeam(target, g_Warden.TeamPicked);
		}
	} else if (g_Warden.Tool == WardenTool_Laser) {
		if (buttons & IN_USE) g_Warden.InUse = true;
		else {
			g_Warden.InUse = false;

			if (g_Lasers.Length > 0) {
				Laser lastLaser; g_Lasers.GetArray(g_Lasers.Length - 1, lastLaser);

				if (!lastLaser.Stop) {
					lastLaser.Stop = true;
					g_Lasers.PushArray(lastLaser);
				}
			}
		}
	}
}

public Action Hook_RoundStart(Event event, const char[] name, bool dontBroadcast) {
	UnsetWarden();

	g_FriendlyFire = 0;
	g_Entities.Clear();
	g_Lasers.Clear();
	g_AllowedPickup.Clear();
	ClearTeams();

	SpecialDay newSpecialDay;
	g_Spec = newSpecialDay;

	for (int i = 1; i <= MaxClients; i++) {
		g_Players[i].Kills = 0;
	}

	g_roundStartedTime = GetTime();
}

public Action Hook_RoundEnd(Event event, const char[] name, bool dontBroadcast) {
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsValidPlayer(i)) continue;
		ChangeComm(i, false);

		if (!IsPlayerAlive(i)) continue;
		SetEntityGravity(i, 1.0);
	}

	if (g_RoundsRemaining > 0) g_RoundsRemaining--;
	g_Warden.CurrentTime = 0;
	g_Warden.EndTime = 0;
	g_Warden.Minigame = Minigame_None;
	g_cIgnoreRoundWin.SetInt(0);
}

public Action Hook_PlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (g_Warden.Id == client) UnsetWarden(true);

	if (g_Spec.Type != SpecialDay_None) {
		int attacker = GetClientOfUserId(event.GetInt("attacker"));
		if (!IsValidPlayer(attacker)) return;
		g_Players[attacker].Kills++;

		if (g_Spec.Type == SpecialDay_Chamber) {
			int weapon = GetPlayerWeaponSlot(attacker, 1);
			if (weapon != -1) SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", GetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount") + 1);
		}

		bool forceEndRound = true;
		int playersAlive;
		for (int i = 1; i <= MaxClients; i++) {
			if (!IsValidPlayer(i) || !IsPlayerAlive(i)) continue;
			playersAlive++;
		}

		if (playersAlive > 1) forceEndRound = false;
		if (forceEndRound) {
			g_cIgnoreRoundWin.SetInt(0);

			Event end = CreateEvent("round_end", true);
			end.Fire(true);
		}
	}
}

public Action Hook_GlowTransmit(int entity, int client) {
	char[] buffer = new char[512];
	char[] emitter = new char[2];

	GetEntPropString(entity, Prop_Data, "m_iName", buffer, 512);
	SplitString(buffer, ":", emitter, 2);

	if (g_Players[StringToInt(emitter)].Team != g_Players[client].Team) return Plugin_Handled;
	if (g_Spec.Invisibility) return Plugin_Handled;
	return Plugin_Continue;
}

Action Timer_Main(Handle timer, any data) {
	float gameTime = GetGameTime();

	for (int i = 0; i < g_Entities.Length; i++) {
		Entity entity; g_Entities.GetArray(i, entity);
		if (gameTime < entity.End) continue;

		AcceptEntityInput(entity.Index, "Kill");
		g_Entities.Erase(i);
	}

	if (g_Warden.InUse) {
		Laser laser;
		RayTrace(g_Warden.Id, laser.yPos);

		for (int i = 0; i < 3; i++) laser.xPos[i] = laser.yPos[i];

		if (g_Lasers.Length > 0) {
			Laser lastLaser; g_Lasers.GetArray(g_Lasers.Length - 1, lastLaser);

			if (!lastLaser.Stop) {
				for (int i = 0; i < 3; i++) laser.xPos[i] = lastLaser.yPos[i];
			}
		}

		if (g_LaserTimes[g_Warden.LaserEndOption] != 0.0) {
			laser.End = gameTime + g_LaserTimes[g_Warden.LaserEndOption];
		}
		
		laser.Color = g_Warden.LaserColor;
		g_Lasers.PushArray(laser);
	}

	for (int i = 0; i < 256 && g_Render < g_Lasers.Length; i++) {
		Laser laser; g_Lasers.GetArray(g_Render, laser);

		if (laser.End != 0.0 && gameTime > laser.End) g_Lasers.Erase(g_Render);
		else {
			float display = 0.1 + (g_Lasers.Length / 256) * 0.1;

			TE_SetupBeamPoints(laser.xPos, laser.yPos, g_Models.Laser, g_Models.Glow, 0, 30, display, 1.0, 1.0, 2, 1.0, g_Colors[laser.Color], 0);
			TE_SendToAll();
			g_Render++;
		}
	}

	if (g_Render >= g_Lasers.Length) g_Render = 0;
	if (g_Warden.Minigame != Minigame_None) {
		g_Warden.CurrentTime++;

		if (g_Warden.Minigame == Minigame_FreezeJump) {
			if (g_Warden.CurrentTime == 0) {
				for (int i = 1; i <= MaxClients; i++) {
					if (!IsValidPlayer(i)) continue;
					if (!IsPlayerAlive(i)) continue;
					if (GetClientTeam(i) != 2) continue;
					SetEntityMoveType(i, MOVETYPE_WALK);

					float pos[3];
					GetClientEyePosition(i, pos);
					EmitAmbientSound(g_FreezeSound, pos, i, SNDLEVEL_RAIDSIREN);
				}

				if (g_Warden.Tool == WardenTool_FreezeJump) Menu_FreezeJump();
				g_Warden.EndTime = 0;
				g_Warden.Minigame = Minigame_None;
			}
		}

		if (g_Warden.CurrentTime == g_Warden.EndTime) {
			if (g_Warden.Minigame != Minigame_FreezeJump) StopMinigame();
			else {
				g_Warden.CurrentTime = -30;

				int highIndex, lowIndex;
				float highDistance, lowDistance;

				for (int i = 1; i <= MaxClients; i++) {
					if (!IsValidPlayer(i)) continue;
					if (!IsPlayerAlive(i)) continue;
					if (GetClientTeam(i) != 2) continue;

					float pos[3];
					GetClientEyePosition(i, pos);
					EmitAmbientSound(g_FreezeSound, pos, i, SNDLEVEL_RAIDSIREN);

					SetEntityMoveType(i, MOVETYPE_NONE);

					float distance = GetClientDistanceToGround(i);
					PrintToConsoleAll("%N %f", i, distance);

					if (distance == 0.0) continue;

					if (highDistance == 0.0 || distance > highDistance) {
						highIndex = i;
						highDistance = distance;
					}

					if (lowDistance == 0.0 || distance < lowDistance) {
						lowIndex = i;
						lowDistance = distance;
					}
				}

				PrintToChatAll("%s\x06Highest: \x10%N \x01%.3fu \x07Lowest: \x10%N \x01%.3fu", PLUGIN_PREFIX, highIndex, highDistance, lowIndex, lowDistance);
			}
		}

		int timeRemaining = g_Warden.EndTime - g_Warden.CurrentTime;
		switch (timeRemaining) {
			case 10, 20, 30, 40, 50, 150, 300: {
				PrintToChatAll("%s%t", PLUGIN_PREFIX, "time_remaining", timeRemaining / 10);

				if (g_Warden.Minigame == Minigame_FreezeJump) {
					for (int i = 1; i <= MaxClients; i++) {
						if (!IsValidPlayer(i)) continue;
						if (!IsPlayerAlive(i)) continue;
						if (GetClientTeam(i) != 2) continue;

						float pos[3];
						GetClientEyePosition(i, pos);
						EmitAmbientSound(g_BeepSound, pos, i, SNDLEVEL_RAIDSIREN);
					}
				}
			}
		}
	}

	for (int i = 1; i <= MaxClients; i++) {
		if (!IsValidPlayer(i)) continue;
		if (!IsPlayerAlive(i)) continue;
		if (g_Players[i].SlapsRemaining == 0) continue;
		g_Players[i].SlapsRemaining--;
		SlapPlayer(i, 0);
	}

	if (g_Spec.Type == SpecialDay_Flash) {
		for (int i = 1; i <= MaxClients; i++) {
			if (!IsValidPlayer(i)) continue;
			if (!IsPlayerAlive(i)) continue;

			SetEntProp(i, Prop_Send, "m_iHealth", 1);
		}
	} else if (g_Spec.Type == SpecialDay_Grenade) {
		for (int i = 1; i <= MaxClients; i++) {
			if (!IsValidPlayer(i)) continue;
			if (!IsPlayerAlive(i)) continue;

			if (GetEntProp(i, Prop_Send, "m_iHealth") > 20) SetEntProp(i, Prop_Send, "m_iHealth", 20);
		}
	}
}

void SetClientTeam(int client, int team, bool announce = true) {
	char[] buffer = new char[512];
	char[] model = new char[PLATFORM_MAX_PATH];
	g_Players[client].Team = team + 1;
	SetEntityRenderColor(client, g_Colors[team][0], g_Colors[team][1], g_Colors[team][2], g_Colors[team][3]);

	if (g_Players[client].Glow > 0) {
		if (IsValidEntity(g_Players[client].Glow)) AcceptEntityInput(g_Players[client].Glow, "Kill");
	}

	GetClientModel(client, model, PLATFORM_MAX_PATH);
	g_Players[client].Glow = CreatePlayerModelProp(client, model);

	if (SDKHookEx(g_Players[client].Glow, SDKHook_SetTransmit, Hook_GlowTransmit)) {
		static int offset = -1;
		offset = GetEntSendPropOffs(g_Players[client].Glow, "m_clrGlow");

		SetEntProp(g_Players[client].Glow, Prop_Send, "m_bShouldGlow", true, true);
		SetEntProp(g_Players[client].Glow, Prop_Send, "m_nGlowStyle", 0);
		SetEntPropFloat(g_Players[client].Glow, Prop_Send, "m_flGlowMaxDist", 10000.0);

		for (int i = 0; i < 3; i++) {
			SetEntData(g_Players[client].Glow, offset + i, g_Colors[team][i], _, true);
		}
	}

	if (announce) {
		FormatEx(buffer, 512, "%s%t", CHAT_HIGHLIGHT, g_ColorNames[team]);
		PrintToChat(client, "%s%t", PLUGIN_PREFIX, "announce_team", buffer);
	}
}

void RandomizeTeams(int totalTeams, bool teamRandom, bool includeCT = false) {
	ArrayList suitablePlayers = new ArrayList();
	ArrayList suitableTeams = new ArrayList();
	int currentTeam;

	for (int i = 1; i <= MaxClients; i++) {
		if (!IsValidPlayer(i)) continue;
		if (!IsPlayerAlive(i)) continue;

		int team = GetClientTeam(i);
		if (team == 2 || (includeCT && team == 3)) suitablePlayers.Push(i);
	}

	for (int i = 0; i < sizeof(g_Colors); i++) {
		suitableTeams.Push(i);
	}

	ShuffleArray(suitablePlayers);
	if (teamRandom) ShuffleArray(suitableTeams);

	for (int i = 0; i < suitablePlayers.Length; i++) {
		SetClientTeam(suitablePlayers.Get(i), suitableTeams.Get(currentTeam));

		currentTeam++;
		if (currentTeam == totalTeams) currentTeam = 0;
	}

	delete suitablePlayers;
	delete suitableTeams;
}

void ClearTeams() {
	for (int i = 1; i <= MaxClients; i++) {
		g_Players[i].Team = 0;
		g_Players[i].Glow = 0;

		if (!IsValidPlayer(i)) continue;
		if (!IsPlayerAlive(i)) continue;
		SetEntityRenderColor(i, 255, 255, 255, 255);
	}

	ClearGlows();
}

void ClearGlows() {
	char[] buffer = new char[512];

	for (int i = 0; i <= GetMaxEntities(); i++) {
		if (!IsValidEdict(i)) continue;
		if (!IsValidEntity(i)) continue;

		if (GetEntPropString(i, Prop_Data, "m_iName", buffer, 512)) {
			if (StrContains(buffer, ": glow") == -1) continue;
			AcceptEntityInput(i, "Kill");
		}
	}
}

void ChangeComm(int client, bool mute) {
	if (!g_SourceCommsEnabled) BaseComm_SetClientMute(client, mute);
	else {
		bType muteType = SourceComms_GetClientMuteType(client);

		if (muteType == bNot || muteType == bSess) {
			SourceComms_SetClientMute(client, mute);
		}
	}
}

void SetWarden(int client, bool broadcast = false) {
	if (broadcast) {
		char[] buffer = new char[512];

		FormatEx(buffer, 512, "%s%N", CHAT_HIGHLIGHT, client);
		PrintToChatAll("%s%t", PLUGIN_PREFIX, "announce_take_warden", buffer);
	}

	g_Warden.Id = client;
}

void UnsetWarden(bool broadcast = false) {
	if (broadcast) {
		char[] buffer = new char[512];

		FormatEx(buffer, 512, "%s%N", CHAT_HIGHLIGHT, g_Warden.Id);
		PrintToChatAll("%s%t", PLUGIN_PREFIX, "announce_untake_warden", buffer);
		Menu_TakeWarden();
	}

	Warden newWarden;
	g_Warden = newWarden;
}

void SetPlayerBeaconPref(int client, int beacon) {
	char[] value = new char[4];

	FormatEx(value, 4, "%i", beacon);
	g_BeaconCookie.Set(client, value);
	g_Players[client].BeaconPref = beacon;
}

void PerformBlind(int target, int amount) {
	int targets[2];
	targets[0] = target;

	int duration = 1536;
	int holdtime = 1536;
	int flags;

	if (amount == 0) flags = (0x0001 | 0x0010);
	else flags = (0x0002 | 0x0008);

	int color[4] = { 0, 0, 0, 0 };
	color[3] = amount;

	Handle message = StartMessageEx(g_FadeUserMsgId, targets, 1);

	Protobuf pb = UserMessageToProtobuf(message);
	pb.SetInt("duration", duration);
	pb.SetInt("hold_time", holdtime);
	pb.SetInt("flags", flags);
	pb.SetColor("clr", color);

	EndMessage();
}

void StartShark() {
	g_Warden.CurrentTime = 1;
	g_Warden.EndTime = g_Times[g_Warden.Duration];
	g_Warden.Minigame = Minigame_Shark;
	if (!g_Warden.No) PerformBlind(g_Warden.Shark, 255);

	char[] buffer = new char[64];
	FormatEx(buffer, 64, "%s%t", CHAT_HIGHLIGHT, g_TimeNames[g_Warden.Duration]);
	PrintToChatAll("%s%t", PLUGIN_PREFIX, "announce_shark", buffer);
}

void StartFreezeJump() {
	g_Warden.CurrentTime = 1;
	g_Warden.EndTime = 70;
	g_Warden.Minigame = Minigame_FreezeJump;

	char[] buffer = new char[64];
	FormatEx(buffer, 64, "%s%t", CHAT_HIGHLIGHT, g_TimeNames[g_Warden.Duration]);
	PrintToChatAll("%s%t", PLUGIN_PREFIX, "announce_freezejump", buffer);
}

void StartBlind() {
	g_Warden.CurrentTime = 1;
	g_Warden.EndTime = g_Times[g_Warden.Duration];
	g_Warden.Minigame = Minigame_Blind;

	if (g_Warden.Blind != 0) PerformBlind(g_Warden.Blind, 255);
	else {
		for (int i = 1; i <= MaxClients; i++) {
			if (!IsValidPlayer(i)) continue;
			if (!IsPlayerAlive(i)) continue;
			if (GetClientTeam(i) != 2) continue;
			PerformBlind(i, 255);
		}
	}

	char[] buffer = new char[64];
	FormatEx(buffer, 64, "%s%t", CHAT_HIGHLIGHT, g_TimeNames[g_Warden.Duration]);
	PrintToChatAll("%s%t", PLUGIN_PREFIX, "announce_blind", buffer);
}

void StopMinigame(bool force = false) {
	g_Warden.CurrentTime = 0;
	g_Warden.EndTime = 0;
	g_Warden.Minigame = Minigame_None;

	for (int i = 1; i <= MaxClients; i++) {
		if (!IsValidPlayer(i)) continue;
		PerformBlind(i, 0);
	}

	if (force) PrintToChatAll("%s%t", PLUGIN_PREFIX, "announce_force_stop");
	else PrintToChatAll("%s%t", PLUGIN_PREFIX, "announce_stop");

	switch (g_Warden.Tool) {
		case WardenTool_Shark: Menu_Shark();
		case WardenTool_Blind: Menu_Blind();
	}
}

void HealT() {
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsValidPlayer(i)) continue;
		if (!IsPlayerAlive(i)) continue;
		if (GetClientTeam(i) != 2) continue;
		SetEntProp(i, Prop_Data, "m_iHealth", 100);
	}

	PrintToChatAll("%s%t", PLUGIN_PREFIX, "announce_heal_t");
}

void GiveAwarenessGrenade() {
	g_Warden.Grenade = true;
	GivePlayerItem(g_Warden.Id, "weapon_tagrenade");

	PrintToChat(g_Warden.Id, "%s%t", PLUGIN_PREFIX, "announce_ta_grenade");
}

void AddSlaps(int amount) {
	if (g_Warden.Slap != 0) g_Players[g_Warden.Slap].SlapsRemaining = amount;
	else {
		for (int i = 1; i <= MaxClients; i++) {
			if (!IsValidPlayer(i)) continue;
			if (!IsPlayerAlive(i)) continue;
			if (GetClientTeam(i) != 2) continue;
			g_Players[i].SlapsRemaining = amount;
		}
	}
}

void PrioritySpeakerChange() {
	g_Warden.PrioritySpeaker = !g_Warden.PrioritySpeaker;
	PrintToChatAll("%sPriority Speaker has now been turned %s", PLUGIN_PREFIX, g_Warden.PrioritySpeaker ? "\x07ON" : "\x06OFF");

	for (int i = 1; i <= MaxClients; i++) {
		if (!IsValidPlayer(i)) continue;
		if (!IsPlayerAlive(i)) continue;
		if (GetClientTeam(i) != 2) continue;
		ChangeComm(i, g_Warden.PrioritySpeaker);
	}
}

void PrecacheMaterial(char[] fileName) {
	AddFileToDownloadsTable(fileName);
	PrecacheGeneric(fileName);
}

#include "wardentools/commands.sp"
#include "wardentools/days.sp"
#include "wardentools/menus.sp"
#include "wardentools/natives.sp"