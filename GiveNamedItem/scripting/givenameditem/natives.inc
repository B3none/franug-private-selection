#if defined _givenameditem_natives_included
  #endinput
#endif
#define _givenameditem_natives_included

stock CreateNatives()
{
	CreateNative("GiveNamedItem_SetClassname", Native_GiveNamedItem_SetClassname);
	CreateNative("GiveNamedItem_GetDefinitionIndex", Native_GiveNamedItem_GetDefinitionIndex);
	CreateNative("GiveNamedItem_SetDefinitionIndex", Native_GiveNamedItem_SetDefinitionIndex);
	CreateNative("GiveNamedItem_GetInUse", Native_GiveNamedItem_GetInUse);
	CreateNative("GiveNamedItem_GetPaintkit", Native_GiveNamedItem_GetPaintkit);
	CreateNative("GiveNamedItem_SetPaintkit", Native_GiveNamedItem_SetPaintkit);
	CreateNative("GiveNamedItem_GetSeed", Native_GiveNamedItem_GetSeed);
	CreateNative("GiveNamedItem_SetSeed", Native_GiveNamedItem_SetSeed);
	CreateNative("GiveNamedItem_GetWear", Native_GiveNamedItem_GetWear);
	CreateNative("GiveNamedItem_SetWear", Native_GiveNamedItem_SetWear);
	CreateNative("GiveNamedItem_GetKills", Native_GiveNamedItem_GetKills);
	CreateNative("GiveNamedItem_SetKills", Native_GiveNamedItem_SetKills);
	CreateNative("GiveNamedItem_GetEntityQuality", Native_GiveNamedItem_GetEntityQuality);
	CreateNative("GiveNamedItem_SetEntityQuality", Native_GiveNamedItem_SetEntityQuality);
	CreateNative("GiveNamedItem_GetTeamSwitch", Native_GiveNamedItem_GetTeamSwitch);
	CreateNative("GiveNamedItem_SetTeamSwitch", Native_GiveNamedItem_SetTeamSwitch);
	CreateNative("GiveNamedItem_GetAccountID", Native_GiveNamedItem_GetAccountID);
	CreateNative("GiveNamedItem_SetAccountID", Native_GiveNamedItem_SetAccountID);
	
	CreateNative("GiveNamedItem_GetItemDefinitionByClassname", Native_GiveNamedItem_GetItemDefinitionByClassname);
	CreateNative("GiveNamedItem_GetClassnameByItemDefinition", Native_GiveNamedItem_GetClassnameByItemDefinition);
	CreateNative("GiveNamedItem_IsItemDefinitionKnife", Native_GiveNamedItem_IsItemDefinitionKnife);
	CreateNative("GiveNamedItem_IsClassnameKnife", Native_GiveNamedItem_IsClassnameKnife);
	CreateNative("GetNamedItem_GetWeaponTeamByItemDefinition", Native_GetNamedItem_GetWeaponTeamByItemDefinition);
	
	CreateNative("GiveNamedItem_GiveKnife", Native_GiveNamedItem_GiveKnife);
}

public Native_GiveNamedItem_SetClassname(Handle:plugin, params)
{
	char classname[64];
	GetNativeString(1, classname, sizeof(classname));
	g_hServerHook.SetClassname(classname);
}

public Native_GiveNamedItem_GetDefinitionIndex(Handle:plugin, params)
{
	return g_hServerHook.ItemDefinition;
}

public Native_GiveNamedItem_SetDefinitionIndex(Handle:plugin, params)
{
	g_hServerHook.ItemDefinition = GetNativeCell(1);
}

public Native_GiveNamedItem_GetInUse(Handle:plugin, params)
{
	return g_hServerHook.InUse;
}

public Native_GiveNamedItem_GetPaintkit(Handle:plugin, params)
{
	return g_hServerHook.Paintkit;
}

public Native_GiveNamedItem_SetPaintkit(Handle:plugin, params)
{
	g_hServerHook.Paintkit = GetNativeCell(1);
}

public Native_GiveNamedItem_GetSeed(Handle:plugin, params)
{
	return g_hServerHook.Seed;
}

public Native_GiveNamedItem_SetSeed(Handle:plugin, params)
{
	g_hServerHook.Seed = GetNativeCell(1);
}

public Native_GiveNamedItem_GetWear(Handle:plugin, params)
{
	return view_as<any>(g_hServerHook.Wear);
}

public Native_GiveNamedItem_SetWear(Handle:plugin, params)
{
	g_hServerHook.Wear = GetNativeCell(1);
}

public Native_GiveNamedItem_GetKills(Handle:plugin, params)
{
	return g_hServerHook.Kills;
}

public Native_GiveNamedItem_SetKills(Handle:plugin, params)
{
	g_hServerHook.Kills = GetNativeCell(1);
}

public Native_GiveNamedItem_GetEntityQuality(Handle:plugin, params)
{
	return g_hServerHook.EntityQuality;
}

public Native_GiveNamedItem_SetEntityQuality(Handle:plugin, params)
{
	g_hServerHook.EntityQuality = GetNativeCell(1);
}

public Native_GiveNamedItem_GetTeamSwitch(Handle:plugin, params)
{
	return g_hServerHook.TeamSwitch;
}

public Native_GiveNamedItem_SetTeamSwitch(Handle:plugin, params)
{
	g_hServerHook.TeamSwitch = GetNativeCell(1);
}

public Native_GiveNamedItem_GetAccountID(Handle:plugin, params)
{
	return g_hServerHook.AccountID;
}

public Native_GiveNamedItem_SetAccountID(Handle:plugin, params)
{
	g_hServerHook.AccountID = GetNativeCell(1);
}

public Native_GiveNamedItem_GetItemDefinitionByClassname(Handle:plugin, params)
{
	char classname[64];
	GetNativeString(1, classname, sizeof(classname));
	
	return g_hServerHook.GetItemDefinitionByClassname(classname);
}

public Native_GiveNamedItem_GetClassnameByItemDefinition(Handle:plugin, params)
{
	int itemdefinition = GetNativeCell(1);
	char classname[64];
	
	if (g_hServerHook.GetClassnameByItemDefinition(itemdefinition, classname, sizeof(classname)))
	{
		int length = GetNativeCell(3);
		SetNativeString(2, classname, length);
		return true;
	}
	return false;
}

public Native_GiveNamedItem_GiveKnife(Handle:plugin, params)
{
	int client = GetNativeCell(1);
	int itemdefinition = GetNativeCell(2);
	
	if(itemdefinition == -1)
	{
		g_hServerHook.InUse = true;
		
		SafeKnife(client);
			
		g_hServerHook.InUse = false;
		return;
	}
	
	char classname[64];
	
	if (g_hServerHook.GetClassnameByItemDefinition(itemdefinition, classname, sizeof(classname)))
	{
		SafeKnife(client);
	}
}

stock SafeKnife(client)
{
	bool zeus = false;
	int knife2 = GetPlayerWeaponSlot(client, 2);
	if(knife2 != -1) 
	{
		RemovePlayerItem(client, knife2);
		AcceptEntityInput(knife2, "Kill");
	}
		
	knife2 = GetPlayerWeaponSlot(client, 2);
	if(knife2 != -1) 
	{
		RemovePlayerItem(client, knife2);
		AcceptEntityInput(knife2, "Kill");
		zeus = true;
	}
	
	GivePlayerItem(client, "weapon_knife");
	
	if(zeus) GivePlayerItem(client, "weapon_taser");
}

public Native_GiveNamedItem_IsItemDefinitionKnife(Handle:plugin, params)
{
	return g_hServerHook.IsItemDefinitionKnife(GetNativeCell(1));
}

public Native_GiveNamedItem_IsClassnameKnife(Handle:plugin, params)
{
	char classname[64];
	GetNativeString(1, classname, sizeof(classname));
	return g_hServerHook.IsClassnameKnife(classname);
}

public Native_GetNamedItem_GetWeaponTeamByItemDefinition(Handle:plugin, params)
{
	return g_hServerHook.GetWeaponTeamByItemDefinition(GetNativeCell(1));
}
