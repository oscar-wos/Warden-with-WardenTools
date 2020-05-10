public int Native_IsWarden(Handle plugin, int numParams) {
	int client = GetNativeCell(1);
	return client == g_Warden.Id;
}

public int Native_WardenId(Handle plugin, int numParams) {
	return g_Warden.Id;
}