bool g_bInUse = false;
int g_iClient = -1;
int g_iItemDefinition = 0;
int g_iPaintkit = -1;
int g_iSeed = 100;
float g_fWear = 0.001;
int g_iKills = -1;
bool g_bClassnameReset = false;
int g_iEntity = -1;
bool g_bWeaponEquiped = false;
char g_sNewClassname[64];
int g_iEntityQuality = -1;
bool g_bSwitchTeam = false;
int g_iAccountID = false;

methodmap GiveNamedItem_ServerHook
{
	public GiveNamedItem_ServerHook()
	{
		return view_as<GiveNamedItem_ServerHook>(1);
	}
	
	property int Client
	{
		public get() { return g_iClient; }
		public set(int value) { g_iClient = value; }
	}
	
	property int ItemDefinition
	{
		public get() { return g_iItemDefinition; }
		public set(int value) { g_iItemDefinition = value; }
	}
	
	property int Paintkit
	{
		public get() { return g_iPaintkit; }
		public set(int value) { g_iPaintkit = value; }
	}
	
	property int Seed
	{
		public get() { return g_iSeed; }
		public set(int value) { g_iSeed = value; }
	}
	
	property float Wear
	{
		public get() { return g_fWear; }
		public set(float value) { g_fWear = value; }
	}
	
	property int Kills
	{
		public get() { return g_iKills; }
		public set(int value) { g_iKills = value; }
	}
	
	property bool ClassnameReset
	{
		public get() { return g_bClassnameReset; }
		public set(bool value) { g_bClassnameReset = value; }
	}
	
	property bool InUse
	{
		public get() { return g_bInUse; }
		public set(bool value) { g_bInUse = value; }
	}
	
	property bool HasEquiped
	{
		public get() { return g_bWeaponEquiped; }
		public set(bool value) { g_bWeaponEquiped = value; }
	}
	
	property int Entity
	{
		public get() { return g_iEntity; }
		public set(int value) { g_iEntity = value; }
	}
	
	property int EntityQuality
	{
		public get() { return g_iEntityQuality; }
		public set(int value) { g_iEntityQuality = value; }
	}
	
	property bool TeamSwitch
	{
		public get() { return g_bSwitchTeam; }
		public set(bool value) { g_bSwitchTeam = value; }
	}
	
	property int AccountID
	{
		public get() { return g_iAccountID; }
		public set(int value) { g_iAccountID = value; }
	}
	
	public void Reset(int client)
	{
		if (cvar_print_debugmsgs)
			PrintToConsole(client, "-=> HOOK RESET.");
		g_iClient = -1;
		g_iItemDefinition = -1;
		g_iPaintkit = INVALID_PAINTKIT;
		g_iSeed = 100;
		g_fWear = 0.001;
		g_iKills = -1;
		g_bClassnameReset = false;
		g_iEntity = -1;
		g_bInUse = false;
		g_bWeaponEquiped = false;
		g_iEntityQuality = -1;
		g_bSwitchTeam = false;
		g_iAccountID = 0;
	}
	
	public void SetClassname(const char[] classname)
	{
		strcopy(g_sNewClassname, sizeof(g_sNewClassname), classname);
		g_bClassnameReset = true;
	}
	
	public void GetClassname(char[] classname, int length)
	{
		strcopy(classname, length, g_sNewClassname);
	}
	
	public int GetItemDefinitionByClassname(const char[] classname)
	{
		if (StrEqual(classname, "weapon_knife"))
			return 42;
		if (StrEqual(classname, "weapon_knife_t"))
			return 59;
		
		int count = GetArraySize(g_hWeaponItemDefinition);
		char buffer[64];
		for (int i = 0; i < count; i++)
		{
			GetArrayString(g_hWeaponClassname, i, buffer, sizeof(buffer));
			if (StrEqual(classname, buffer))
			{
				return GetArrayCell(g_hWeaponItemDefinition, i);
			}
		}
		return -1;
	}
	
	public bool GetClassnameByItemDefinition(int itemdefinition, char[] buffer, int length)
	{
		if (itemdefinition == 42)
		{
			Format(buffer, length,"weapon_knife");
			return true;
		}
		if (itemdefinition == 59)
		{
			Format(buffer, length, "weapon_knife_t");
			return true;
		}
		
		int count = GetArraySize(g_hWeaponItemDefinition);
		for (int i = 0; i < count; i++)
		{
			if (GetArrayCell(g_hWeaponItemDefinition, i) == itemdefinition)
			{
				GetArrayString(g_hWeaponClassname, i, buffer, length);
				return true;
			}
		}
		return false;
	}
	
	public bool IsItemDefinitionKnife(int itemdefinition)
	{
		if (itemdefinition == 42 || itemdefinition == 59)
			return true;
	
		int count = GetArraySize(g_hWeaponItemDefinition);
		for (int i = 0; i < count; i++)
		{
			if (GetArrayCell(g_hWeaponItemDefinition, i) == itemdefinition)
			{
				if (GetArrayCell(g_hWeaponIsKnife, i))
					return true;
				else
					return false;
			}
		}
		return false;
	}
	
	public bool IsClassnameKnife(const char[] classname)
	{
		if (StrEqual(classname, "weapon_knife") || StrEqual(classname, "weapon_knife_t"))
			return true;
		
		int count = GetArraySize(g_hWeaponClassname);
		char buffer[64];
		for (int i = 0; i < count; i++)
		{
			GetArrayString(g_hWeaponClassname, i, buffer, sizeof(buffer));
			if (StrEqual(classname, buffer))
			{
				if (GetArrayCell(g_hWeaponIsKnife, i))
					return true;
				else
					return false;
			}
		}
		return false;
	}
	
	public int GetWeaponTeamByItemDefinition(int itemdefinition)
	{
		// weapon_knife
		if (itemdefinition == 42)
			return CS_TEAM_CT;
		
		// weapon_knife_t
		if (itemdefinition == 59)
			return CS_TEAM_T;
		
		int count = GetArraySize(g_hWeaponTeam);
		for (int i = 0; i < count; i++)
		{
			if (GetArrayCell(g_hWeaponItemDefinition, i) == itemdefinition)
				return GetArrayCell(g_hWeaponTeam, i);
		}
		return CS_TEAM_NONE;
	}
}

GiveNamedItem_ServerHook g_hServerHook = view_as<GiveNamedItem_ServerHook>(1);