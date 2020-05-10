#define EF_BONEMERGE (1 << 0)
#define EF_NOSHADOW (1 << 4)
#define EF_NORECEIVESHADOW (1 << 6)

enum {
	WardenTool_None = 0,
	WardenTool_TeamPicker,
	WardenTool_Laser,
	WardenTool_Shark,
	WardenTool_Blind,
	WardenTool_FreezeJump
}

enum {
	SpecialDay_None = 0,
	SpecialDay_HungerGames,
	SpecialDay_Chamber,
	SpecialDay_TDM,
	SpecialDay_AWP,
	SpecialDay_War,
	SpecialDay_Hide,
	SpecialDay_Custom
}

enum {
	Minigame_None = 0,
	Minigame_Shark,
	Minigame_Blind,
	Minigame_FreezeJump
}

enum {
	FriendlyFire_Off = 0,
	FriendlyFire_Team,
	FriendlyFire_All,
	FriendlyFire_TrueAll
}

enum struct Models {
	int Laser;
	int Glow;
}

enum struct Player {
	int Team;
	int Glow;
	int SlapsRemaining;

	int BeaconPref;
}

enum struct Warden {
	int Id;
	int Tool;
	bool InUse;
	bool Grenade;
	bool PrioritySpeaker;
	int SpecialDay;

	int TeamPicked;
	int TeamRandomize;
	bool TeamRandomizeRandom;

	float BeaconLastPlaced;
	int BeaconEndOption;

	int LaserColor;
	int LaserEndOption;

	int Shark;
	int Blind;
	int Slap;
	int Duration;
	bool No;

	int EndTime;
	int CurrentTime;
	int Minigame;
}

enum struct Beacon {
	char Name[PLATFORM_MAX_PATH];
	char Desc[PLATFORM_MAX_PATH];
}

enum struct Entity {
	int Type;
	int Index;
	float End;
}

enum struct Laser {
	float xPos[3];
	float yPos[3];
	float End;
	bool Stop;
	int Color;
}

char gC_Weapons[][][] = {
	{"weapon_knife", "Knife", "2", "0"},
	{"weapon_ak47", "AK-47", "0", "7"},
	{"weapon_aug", "AUG", "0", "8"},
	{"weapon_awp", "AWP", "0", "9"},
	{"weapon_bizon", "PP-Bizon", "0", "26"},
	{"weapon_cz75a", "CZ-75 Auto", "1", "63"},
	{"weapon_deagle", "Desert Eagle", "1", "1"},
	{"weapon_elite", "Dual Berettas", "1", "2"},
	{"weapon_famas", "FAMAS", "0", "10"},
	{"weapon_fiveseven", "Five-SeveN", "1", "3"},
	{"weapon_g3sg1", "G3SG1", "0", "11"},
	{"weapon_galilar", "Galil AR", "0", "13"},
	{"weapon_glock", "Glock-18", "1", "4"},
	{"weapon_hkp2000", "P2000", "1", "32"},
	{"weapon_m249", "M249", "0", "14"},
	{"weapon_m4a1", "M4A4", "0", "16"},
	{"weapon_m4a1_silencer", "M4A1-S", "0", "60"},
	{"weapon_mac10", "MAC-10", "0", "17"},
	{"weapon_mag7", "MAG-7", "0", "27"},
	{"weapon_mp7", "MP7", "0", "33"},
	{"weapon_mp9", "MP9", "0", "34"},
	{"weapon_negev", "Negev", "0", "28"},
	{"weapon_nova", "Nova", "0", "35"},
	{"weapon_p250", "P250", "1", "36"},
	{"weapon_p90", "P90", "0", "19"},
	{"weapon_sawedoff", "Sawed-Off", "0", "29"},
	{"weapon_scar20", "SCAR-20", "0", "38"},
	{"weapon_sg556", "SG 553", "0", "39"},
	{"weapon_ssg08", "SSG 08", "0", "40"},
	{"weapon_tec9", "Tec-9", "1", "30"},
	{"weapon_ump45", "UMP-45", "0", "24"},
	{"weapon_usp_silencer", "USP-S", "1", "61"},
	{"weapon_xm1014", "XM1014", "0", "25"},
	{"weapon_revolver", "R8 Revolver", "1", "64"},
};

int g_Colors[][4] = {
	{255, 0, 0, 255},
	{0, 255, 0, 255},
	{0, 0, 255, 255},
	{128, 0, 128, 255},
	{255, 192, 203, 255},
	{255, 255, 255, 255},
	{128, 128, 128, 255},
	{255, 165, 0, 255},
	{255, 255, 0, 255}
};

float g_BeaconTimes[] = {
	5.0,
	10.0,
	15.0,
	20.0,
	25.0
};

char g_BeaconTimeNames[][] = {
	"5sec",
	"10sec",
	"15sec",
	"20sec",
	"25sec"
};

int g_LaserTimes[] = {
	50,
	150,
	600,
	0
};

char g_LaserTimeNames[][] = {
	"5sec",
	"15sec",
	"60sec",
	"infinite"
};

int g_Times[] = {
	150,
	300,
	600,
	0
};

char g_TimeNames[][] = {
	"15sec",
	"30sec",
	"60sec",
	"infinite"
};

char g_ColorNames[][] = {
	"red",
	"green",
	"blue",
	"purple",
	"pink",
	"white",
	"grey",
	"orange",
	"yellow"
};

char g_FriendlyFireNames[][] = {
	"off",
	"team",
	"all"
};

char g_YesNo[][] = {
	"yes",
	"no"
};

/**
 * Returns weather the client is currently the Warden
 *
 * @param client   Client index
 * @return         Boolean if client is Warden or not.
 */
native bool Warden_IsWarden(int client);

/**
 * Returns the current Warden index
 *
 * @return         Client index, 0 if no warden.
 */
native int Warden_WardenId();

stock bool IsValidPlayer(int client) {
	if (!IsClientConnected(client)) return false;
	if (!IsClientAuthorized(client)) return false;
	if (!IsClientInGame(client)) return false;
	return true;
}

stock bool CanBeWarden(int client) {
	if (!IsValidPlayer(client)) return false;
	if (!IsPlayerAlive(client)) return false;
	if (GetClientTeam(client) != 3) return false;
	return true;
}

stock void ShuffleArray(ArrayList list) {
	int ctr = list.Length, temp, index;

	while (ctr > 0) {
		index = RoundToFloor(GetRandomInt(0, 9) / 10.0 * ctr);
		ctr--;

		temp = list.Get(ctr);
		list.Set(ctr, list.Get(index));
		list.Set(index, temp);
	}
}

// Credit to Mitchell <Advanced Admin ESP>
stock int CreatePlayerModelProp(int client, const char[] model) {
	char[] buffer = new char[512];
	int skin = CreateEntityByName("prop_dynamic_override");

	FormatEx(buffer, 512, "%i: glow", client);
	DispatchKeyValue(skin, "targetname", buffer);

	DispatchKeyValue(skin, "model", model);
	DispatchKeyValue(skin, "disablereceiveshadows", "1");
	DispatchKeyValue(skin, "disableshadows", "1");
	DispatchKeyValue(skin, "solid", "0");
	DispatchKeyValue(skin, "spawnflags", "256");
	SetEntProp(skin, Prop_Send, "m_CollisionGroup", 0);
	DispatchSpawn(skin);

	SetEntityRenderMode(skin, RENDER_TRANSALPHA);
	SetEntityRenderColor(skin, 0, 0, 0, 0);
	SetEntProp(skin, Prop_Send, "m_fEffects", EF_BONEMERGE|EF_NOSHADOW|EF_NORECEIVESHADOW);
	SetVariantString("!activator");
	AcceptEntityInput(skin, "SetParent", client, skin);
	SetVariantString("primary");
	AcceptEntityInput(skin, "SetParentAttachment", skin, skin, 0);
	return skin;
}

stock void PrecacheMaterial(char[] fileName) {
	static char materialEndings[][] = {
		".vmt",
		".vtf"
	};

	char[] buffer = new char[512];

	for (int i = 0; i < sizeof(materialEndings); i++) {
		FormatEx(buffer, 512, "%s%s", fileName, materialEndings[i]);
		AddFileToDownloadsTable(buffer);
		PrecacheGeneric(buffer);
	}
}

stock void PrecacheParticleEffect(const char[] effectName) {
	static int table = INVALID_STRING_TABLE;
	if (table == INVALID_STRING_TABLE) table = FindStringTable("ParticleEffectNames");

	bool save = LockStringTables(false);
	AddToStringTable(table, effectName);
	LockStringTables(save);
}

stock void PrecacheEffect() {
	static int table = INVALID_STRING_TABLE;
	if (table == INVALID_STRING_TABLE) table = FindStringTable("EffectDispatch");

	bool save = LockStringTables(false);
	AddToStringTable(table, "ParticleEffect");
	LockStringTables(save);
}

stock void RayTrace(int client, float pos[3]) {
	float eye[3], angle[3];
	GetClientEyePosition(client, eye);
	GetClientEyeAngles(client, angle);

	TR_TraceRayFilter(eye, angle, MASK_SOLID, RayType_Infinite, Filter_HitSelf, client);
	if (TR_DidHit()) TR_GetEndPosition(pos);
}

stock int SpawnParticle(float pos[3], const char[] effect) {
	int particle = CreateEntityByName("info_particle_system");
	TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
	DispatchKeyValue(particle, "effect_name", effect);
	DispatchSpawn(particle);
	ActivateEntity(particle);
	AcceptEntityInput(particle, "Start");
	return particle;
}

stock float GetClientDistanceToGround(int client) {
	float origin[3], ground[3];
	GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", origin);
	TR_TraceRayFilter(origin, view_as<float>({90.0, 0.0, 0.0}), MASK_PLAYERSOLID, RayType_Infinite, Filter_HitSelf, client);

	if (TR_DidHit()) {
		TR_GetEndPosition(ground);
		return origin[2] - ground[2];
	}

	return 0.0;
}

bool Filter_HitSelf(int entity, int mask, any data) {
	if (entity == data || (entity >= 1 && entity <= MaxClients)) return false;
	return true;
}