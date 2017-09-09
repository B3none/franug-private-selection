Handle g_hGiveNamedItem = null;
Handle g_hGiveNamedItemPost = null;

stock void HookPlayer(int client)
{
	DHookEntity(g_hGiveNamedItem, false, client);
	DHookEntity(g_hGiveNamedItemPost, true, client);
	SDKHook(client, SDKHook_WeaponEquip, OnWeaponEquip);
}

stock void UnhookPlayer(int client)
{
	SDKUnHook(client, SDKHook_WeaponEquip, OnWeaponEquip);
}

public bool HookOnGiveNamedItem()
{
	Handle config = LoadGameConfigFile("sdktools.games");
	if(config == null)
	{
		LogError("Unable to load game config file: sdktools.games");
		return false;
	}
	
	int offset = GameConfGetOffset(config, "GiveNamedItem");
	if (offset == -1)
	{
		CloseHandle(config);
		LogError("Unable to find offset 'GiveNamedItem' in game data 'sdktools.games'");
		return false;
	}
	
	/* POST HOOK */
	g_hGiveNamedItemPost = DHookCreate(offset, HookType_Entity, ReturnType_CBaseEntity, ThisPointer_CBaseEntity, OnGiveNamedItemPost);
	
	if (g_hGiveNamedItemPost == INVALID_HANDLE)
	{
		CloseHandle(config);
		LogError("Unable to post hook 'int CCSPlayer::GiveNamedItem(char const*, int, CEconItemView*, bool)'");
		return false;
	}
	
	DHookAddParam(g_hGiveNamedItemPost, HookParamType_CharPtr, -1, DHookPass_ByVal);
	DHookAddParam(g_hGiveNamedItemPost, HookParamType_Int, -1, DHookPass_ByVal);
	DHookAddParam(g_hGiveNamedItemPost, HookParamType_Int, -1, DHookPass_ByVal);
	DHookAddParam(g_hGiveNamedItemPost, HookParamType_Bool, -1, DHookPass_ByVal);
	
	/* PRE HOOK */
	g_hGiveNamedItem = DHookCreate(offset, HookType_Entity, ReturnType_CBaseEntity, ThisPointer_CBaseEntity, OnGiveNamedItemPre);
	CloseHandle(config);
	
	if (g_hGiveNamedItem == INVALID_HANDLE)
	{
		LogError("Unable to hook 'int CCSPlayer::GiveNamedItem(char const*, int, CEconItemView*, bool)'");
		return false;
	}
	
	DHookAddParam(g_hGiveNamedItem, HookParamType_CharPtr, -1, DHookPass_ByVal);
	DHookAddParam(g_hGiveNamedItem, HookParamType_Int, -1, DHookPass_ByVal);
	DHookAddParam(g_hGiveNamedItem, HookParamType_Int, -1, DHookPass_ByVal);
	DHookAddParam(g_hGiveNamedItem, HookParamType_Bool, -1, DHookPass_ByVal);
	return true;
}