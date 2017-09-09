/*
	Weapon Paints

	Copyright (C) 2017 Francisco 'Franc1sco' García

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.
	
	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>
#include <multicolors>
#include <givenameditem>

#define IDAYS 26

#undef REQUIRE_PLUGIN
#include <lastrequest>
#include <sm_franugknife>

new Handle:db;

new clientlang[MAXPLAYERS+1];

//bool checked[MAXPLAYERS + 1];

#define MAX_PAINTS 800
#define MAX_LANGUAGES 40
#define MAX_TYPES 80

enum Listados
{
	String:Nombre[64],
	index,
	Float:wear,
	stattrak,
	quality,
	pattern,
	String:flag[8],
	String:type[64]
}

Handle g_hTypesArray[MAX_LANGUAGES] = INVALID_HANDLE;
Handle g_hTypesMenu[MAX_LANGUAGES][MAX_TYPES];

new Handle:menuw[MAX_LANGUAGES] = INVALID_HANDLE;
new g_paints[MAX_LANGUAGES][MAX_PAINTS][Listados];
new g_paintCount[MAX_LANGUAGES];
new String:path_paints[PLATFORM_MAX_PATH];

new bool:g_hosties = false;

new bool:g_c4;
new Handle:cvar_c4;

new Handle:arbol[MAXPLAYERS+1] = INVALID_HANDLE;
new Handle:menu1[MAXPLAYERS+1] = INVALID_HANDLE;

new Handle:saytimer;
new Handle:cvar_saytimer;
new g_saytimer;

new Handle:rtimer;
new Handle:cvar_rtimer;
new g_rtimer;

new Handle:cvar_rmenu;
new bool:g_rmenu;

new Handle:cvar_onlyadmin;
new bool:onlyadmin;

new String:s_arma[MAXPLAYERS+1][64];
new s_sele[MAXPLAYERS+1];

new ismysql;

new Handle:array_paints[MAX_LANGUAGES];
new Handle:array_armas;

#define DATA "6.4.1 private version"

//new String:base[64] = "weaponpaints";

new bool:uselocal = false;

new bool:comprobado41[MAXPLAYERS+1];

bool chooset[MAXPLAYERS + 1];


public Plugin:myinfo =
{
	name = "SM CS:GO Weapon Paints",
	author = "Franc1sco franug",
	description = "",
	version = DATA,
	url = "http://steamcommunity.com/id/franug"
};

new String:g_sCmdLogPath[256];

public OnPluginStart()
{
 	for(new i=0;;i++)
	{
		BuildPath(Path_SM, g_sCmdLogPath, sizeof(g_sCmdLogPath), "logs/weaponpaints_%d.log", i);
		if ( !FileExists(g_sCmdLogPath) )
			break;
	}
	
	LoadTranslations ("franug_weaponpaints.phrases");
	
	CreateConVar("sm_wpaints_version", DATA, "", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_CHEAT|FCVAR_DONTRECORD);
	
	HookEvent("round_start", roundStart);
	//HookEvent("player_team", EventPlayerTeam);
	//HookEvent("player_spawn", Event_Player_Spawn, EventHookMode_Pre);
	AddCommandListener(OnJoinTeam, "joingame");
	AddCommandListener(OnJoinTeam, "jointeam");
	
	//RegConsoleCmd("buyammo1", GetSkins);
	RegConsoleCmd("sm_ws", GetSkins);
	RegConsoleCmd("sm_wskins", GetSkins);
	RegConsoleCmd("sm_paints", GetSkins);
	
	RegAdminCmd("sm_reloadwskins", ReloadSkins, ADMFLAG_ROOT);
	RegAdminCmd("sm_wsremove", RemoveSkins, ADMFLAG_ROOT);
	
	cvar_c4 = CreateConVar("sm_weaponpaints_c4", "1", "Enable or disable that people can apply paints to the C4. 1 = enabled, 0 = disabled");
	cvar_saytimer = CreateConVar("sm_weaponpaints_saytimer", "10", "Time in seconds for block that show the plugin commands in chat when someone type a command. -1.0 = never show the commands in chat");
	cvar_rtimer = CreateConVar("sm_weaponpaints_roundtimer", "-1.0", "Time in seconds roundstart for can use the commands for change the paints. -1.0 = always can use the command");
	cvar_rmenu = CreateConVar("sm_weaponpaints_rmenu", "1", "Re-open the menu when you select a option. 1 = enabled, 0 = disabled.");
	cvar_onlyadmin = CreateConVar("sm_weaponpaints_onlyadmin", "0", "This feature is only for admins. 1 = enabled, 0 = disabled.");
	
	g_c4 = GetConVarBool(cvar_c4);
	g_saytimer = GetConVarInt(cvar_saytimer);
	g_rtimer = GetConVarInt(cvar_rtimer);
	g_rmenu = GetConVarBool(cvar_rmenu);
	onlyadmin = GetConVarBool(cvar_onlyadmin);
	
	HookConVarChange(cvar_c4, OnConVarChanged);
	HookConVarChange(cvar_saytimer, OnConVarChanged);
	HookConVarChange(cvar_rtimer, OnConVarChanged);
	HookConVarChange(cvar_rmenu, OnConVarChanged);
	HookConVarChange(cvar_onlyadmin, OnConVarChanged);
	
	int count = GetLanguageCount();
	for (new i=0; i<count; i++)
		ReadPaints(i);
	
	new String:Items[64];
	
	if(array_armas != INVALID_HANDLE) CloseHandle(array_armas);
	
	array_armas = CreateArray(128);
	
	Format(Items, 64, "negev");
	//Format(Items[desc], 64, "Negev");
	PushArrayString(array_armas, Items);
	
	Format(Items, 64, "m249");
	//Format(Items[desc], 64, "M249");
	PushArrayString(array_armas, Items);
	
	Format(Items, 64, "bizon");
	//Format(Items[desc], 64, "PP-Bizon");
	PushArrayString(array_armas, Items);
	
	Format(Items, 64, "p90");
	//Format(Items[desc], 64, "P90");
	PushArrayString(array_armas, Items);
	
	Format(Items, 64, "scar20");
	//Format(Items[desc], 64, "SCAR-20");
	PushArrayString(array_armas, Items);
	
	Format(Items, 64, "g3sg1");
	//Format(Items[desc], 64, "G3SG1");
	PushArrayString(array_armas, Items);
	
	Format(Items, 64, "m4a1");
	//Format(Items[desc], 64, "M4A1");
	PushArrayString(array_armas, Items);
	
	Format(Items, 64, "m4a1_silencer");
	//Format(Items[desc], 64, "M4A1-S");
	PushArrayString(array_armas, Items);
	
	Format(Items, 64, "ak47");
	//Format(Items[desc], 64, "AK-47");
	PushArrayString(array_armas, Items);
	
	Format(Items, 64, "aug");
	//Format(Items[desc], 64, "AUG");
	PushArrayString(array_armas, Items);
	
	Format(Items, 64, "galilar");
	//Format(Items[desc], 64, "Galil AR");
	PushArrayString(array_armas, Items);
	
	Format(Items, 64, "awp");
	//Format(Items[desc], 64, "AWP");
	PushArrayString(array_armas, Items);
	
	Format(Items, 64, "sg556");
	//Format(Items[desc], 64, "SG 553");
	PushArrayString(array_armas, Items);
	
	Format(Items, 64, "ump45");
	//Format(Items[desc], 64, "UMP-45");
	PushArrayString(array_armas, Items);
	
	Format(Items, 64, "mp7");
	//Format(Items[desc], 64, "MP7");
	PushArrayString(array_armas, Items);

	Format(Items, 64, "famas");
	//Format(Items[desc], 64, "FAMAS");
	PushArrayString(array_armas, Items);
	
	Format(Items, 64, "mp9");
	//Format(Items[desc], 64, "MP9");
	PushArrayString(array_armas, Items);

	Format(Items, 64, "mac10");
	//Format(Items[desc], 64, "MAC-10");
	PushArrayString(array_armas, Items);
	
	Format(Items, 64, "ssg08");
	//Format(Items[desc], 64, "SSG 08");
	PushArrayString(array_armas, Items);
	
	Format(Items, 64, "nova");
	//Format(Items[desc], 64, "Nova");
	PushArrayString(array_armas, Items);
	
	Format(Items, 64, "xm1014");
	//Format(Items[desc], 64, "XM1014");
	PushArrayString(array_armas, Items);
	
	Format(Items, 64, "sawedoff");
	//Format(Items[desc], 64, "Sawed-Off");
	PushArrayString(array_armas, Items);
	
	Format(Items, 64, "mag7");
	//Format(Items[desc], 64, "MAG-7");
	PushArrayString(array_armas, Items);
	

	
	// Secondary weapons
	Format(Items, 64, "elite");
	//Format(Items[desc], 64, "Dual Berettas");
	PushArrayString(array_armas, Items);

	Format(Items, 64, "deagle");
	//Format(Items[desc], 64, "Desert Eagle");
	PushArrayString(array_armas, Items);

	Format(Items, 64, "tec9"); // 26
	//Format(Items[desc], 64, "Tec-9");
	PushArrayString(array_armas, Items);
	
	Format(Items, 64, "fiveseven");
	//Format(Items[desc], 64, "Five-SeveN");
	PushArrayString(array_armas, Items);

	Format(Items, 64, "cz75a");
	//Format(Items[desc], 64, "CZ75-Auto");
	PushArrayString(array_armas, Items);
	
	Format(Items, 64, "glock");
	PushArrayString(array_armas, Items);
	
	Format(Items, 64, "usp_silencer");
	//Format(Items[desc], 64, "USP-S");
	PushArrayString(array_armas, Items);
	
	Format(Items, 64, "p250");
	//Format(Items[desc], 64, "P250");
	PushArrayString(array_armas, Items);
	
	Format(Items, 64, "hkp2000");
	//Format(Items[desc], 64, "P2000");
	PushArrayString(array_armas, Items);
	
	Format(Items, 64, "bayonet");
	PushArrayString(array_armas, Items);
	
	Format(Items, 64, "knife_gut");
	PushArrayString(array_armas, Items);
	
	Format(Items, 64, "knife_flip");
	PushArrayString(array_armas, Items);
	
	Format(Items, 64, "knife_m9_bayonet");
	PushArrayString(array_armas, Items);
	
	Format(Items, 64, "knife_karambit");
	PushArrayString(array_armas, Items);
	
	Format(Items, 64, "knife_tactical");
	PushArrayString(array_armas, Items);
	
	Format(Items, 64, "knife_butterfly");
	PushArrayString(array_armas, Items);
	
	Format(Items, 64, "c4");
	PushArrayString(array_armas, Items);
	
	Format(Items, 64, "knife_falchion");
	PushArrayString(array_armas, Items);
	
	Format(Items, 64, "knife_push");
	PushArrayString(array_armas, Items);
	
	Format(Items, 64, "revolver");
	PushArrayString(array_armas, Items);
	
	Format(Items, 64, "knife_survival_bowie");
	PushArrayString(array_armas, Items);
	
	ComprobarDB(true, "weaponpaints");
}

public OnPluginEnd()
{
	for (new client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
			
		OnClientDisconnect(client);
	}
}

/*
public OnClientPostAdminCheck(client)
{
	QueryClientConVar(client, "cl_language", ConVarQueryFinished:CallBack);
}

public CallBack(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[])
{
	langindex = GetLanguageByName(cvarValue);
    if(langindex == -1)
    {
		CreateTimer(0.1, Timer_ClientLanguage, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);
		return;
    }
    
    clientlang[client] = langindex ;
	CheckSteamID(client);
	
	chooset[client] = true;
}
*/

/*
public Action:EventPlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(client > 0 && client <= MaxClients)
	{
		if(IsFakeClient(client))
		{
			return Plugin_Continue;
		}
	}
		
	// refresh client channel after a delay to fix invalid memory access bug
	CreateTimer(0.1, Timer_ClientLanguage, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}*/

public Action:Timer_ClientLanguage(Handle:timer, any:serial)
{
	new client = GetClientFromSerial(serial);
	
	if (client)
	{
		//if(!checked[client])
		//{
			clientlang[client] = GetClientLanguage(client);
			CheckSteamID(client);
			//checked[client] = true;
		//}
	}

	return Plugin_Stop;
}

public Action OnJoinTeam(int client, const char[] command, int args)
{
	if (chooset[client])return;
	
	clientlang[client] = GetClientLanguage(client);
	CheckSteamID(client);
	
	chooset[client] = true;
}

public OnConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == cvar_c4)
	{
		g_c4 = bool:StringToInt(newValue);
	}
	else if (convar == cvar_saytimer)
	{
		g_saytimer = StringToInt(newValue);
	}
	else if (convar == cvar_rtimer)
	{
		g_rtimer = StringToInt(newValue);
	}
	else if (convar == cvar_rmenu)
	{
		g_rmenu = bool:StringToInt(newValue);
	}
	else if (convar == cvar_onlyadmin)
	{
		onlyadmin = bool:StringToInt(newValue);
	}
}

public void OnMapStart() {
	
	CreateTimer(3.0, valveserver, _, TIMER_FLAG_NO_MAPCHANGE);
} 

public Action valveserver(Handle timer)
{
	GameRules_SetProp("m_bIsValveDS", 1);
	GameRules_SetProp("m_bIsQuestEligible", 1);
}

ComprobarDB(bool:reconnect = false,String:basedatos[64] = "weaponpaints")
{
	if(uselocal) basedatos = "clientprefs";
	if(reconnect)
	{
		if (db != INVALID_HANDLE)
		{
			//LogMessage("Reconnecting DB connection");
			CloseHandle(db);
			db = INVALID_HANDLE;
		}
	}
	else if (db != INVALID_HANDLE)
	{
		return;
	}

	if (!SQL_CheckConfig( basedatos ))
	{
		if(StrEqual(basedatos, "clientprefs")) SetFailState("Databases not found");
		else 
		{
			//base = "clientprefs";
			ComprobarDB(true,"clientprefs");
			uselocal = true;
		}
		
		return;
	}
	SQL_TConnect(OnSqlConnect, basedatos);
}

public OnSqlConnect(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogToFileEx(g_sCmdLogPath, "Database failure: %s", error);
		
		SetFailState("Databases dont work");
	}
	else
	{
		db = hndl;
		decl String:buffer[3096];
		
		SQL_GetDriverIdent(SQL_ReadDriver(db), buffer, sizeof(buffer));
		ismysql = StrEqual(buffer,"mysql", false) ? 1 : 0;
	
		new String:temp[64][44];
		for(new i=0;i<GetArraySize(array_armas);++i)
		{
			GetArrayString(array_armas, i, temp[i], 64);
		}
		if (ismysql == 1)
		{
			Format(buffer, sizeof(buffer), "CREATE TABLE IF NOT EXISTS `weaponpaints` (`playername` varchar(128) NOT NULL, `steamid` varchar(32) NOT NULL, `last_accountuse` int(64) NOT NULL, `%s` varchar(64) NOT NULL DEFAULT 'none', `%s` varchar(64) NOT NULL DEFAULT 'none', `%s` varchar(64) NOT NULL DEFAULT 'none', `%s` varchar(64) NOT NULL DEFAULT 'none', `%s` varchar(64) NOT NULL DEFAULT 'none', `%s` varchar(64) NOT NULL DEFAULT 'none',`%s` varchar(64) NOT NULL DEFAULT 'none',`%s` varchar(64) NOT NULL DEFAULT 'none',`%s` varchar(64) NOT NULL DEFAULT 'none',`%s` varchar(64) NOT NULL DEFAULT 'none',`%s` varchar(64) NOT NULL DEFAULT 'none',`%s` varchar(64) NOT NULL DEFAULT 'none',`%s` varchar(64) NOT NULL DEFAULT 'none',`%s` varchar(64) NOT NULL DEFAULT 'none',`%s` varchar(64) NOT NULL DEFAULT 'none',`%s` varchar(64) NOT NULL DEFAULT 'none',`%s` varchar(64) NOT NULL DEFAULT 'none',`%s` varchar(64) NOT NULL DEFAULT 'none',`%s` varchar(64) NOT NULL DEFAULT 'none',`%s` varchar(64) NOT NULL DEFAULT 'none',`%s` varchar(64) NOT NULL DEFAULT 'none',`%s` varchar(64) NOT NULL DEFAULT 'none',`%s` varchar(64) NOT NULL DEFAULT 'none',`%s` varchar(64) NOT NULL DEFAULT 'none',`%s` varchar(64) NOT NULL DEFAULT 'none',`%s` varchar(64) NOT NULL DEFAULT 'none',`%s` varchar(64) NOT NULL DEFAULT 'none',`%s` varchar(64) NOT NULL DEFAULT 'none',`%s` varchar(64) NOT NULL DEFAULT 'none',`%s` varchar(64) NOT NULL DEFAULT 'none',`%s` varchar(64) NOT NULL DEFAULT 'none',`%s` varchar(64) NOT NULL DEFAULT 'none',`%s` varchar(64) NOT NULL DEFAULT 'none',`%s` varchar(64) NOT NULL DEFAULT 'none',`%s` varchar(64) NOT NULL DEFAULT 'none',`%s` varchar(64) NOT NULL DEFAULT 'none',`%s` varchar(64) NOT NULL DEFAULT 'none',`%s` varchar(64) NOT NULL DEFAULT 'none',`%s` varchar(64) NOT NULL DEFAULT 'none',`%s` varchar(64) NOT NULL DEFAULT 'none',`%s` varchar(64) NOT NULL DEFAULT 'none',`%s` varchar(64) NOT NULL DEFAULT 'none',`%s` varchar(64) NOT NULL DEFAULT 'none',`%s` varchar(64) NOT NULL DEFAULT 'none',`favorite1` varchar(64) NOT NULL DEFAULT 'none',`favorite2` varchar(64) NOT NULL DEFAULT 'none',`favorite3` varchar(64) NOT NULL DEFAULT 'none',`favorite4` varchar(64) NOT NULL DEFAULT 'none',`favorite5` varchar(64) NOT NULL DEFAULT 'none',`favorite6` varchar(64) NOT NULL DEFAULT 'none',`favorite7` varchar(64) NOT NULL DEFAULT 'none',PRIMARY KEY  (`steamid`))",temp[0],temp[1],temp[2],temp[3],temp[4],temp[5],temp[6],temp[7],temp[8],temp[9],temp[10],temp[11],temp[12],temp[13],temp[14],temp[15],temp[16],temp[17],temp[18],temp[19],temp[20],temp[21],temp[22],temp[23],temp[24],temp[25],temp[26],temp[27],temp[28],temp[29],temp[30],temp[31],temp[32],temp[33],temp[34],temp[35],temp[36],temp[37],temp[38],temp[39],temp[40], temp[41], temp[42], temp[43]);

			LogToFileEx(g_sCmdLogPath, "Query %s", buffer);
			SQL_TQuery(db, tbasicoC, buffer);

		}
		else
		{
			Format(buffer, sizeof(buffer), "CREATE TABLE IF NOT EXISTS weaponpaints (playername varchar(128) NOT NULL, steamid varchar(32) NOT NULL, last_accountuse int(64) NOT NULL, %s varchar(64) NOT NULL DEFAULT 'none', %s varchar(64) NOT NULL DEFAULT 'none', %s varchar(64) NOT NULL DEFAULT 'none', %s varchar(64) NOT NULL DEFAULT 'none', %s varchar(64) NOT NULL DEFAULT 'none', %s varchar(64) NOT NULL DEFAULT 'none',%s varchar(64) NOT NULL DEFAULT 'none',%s varchar(64) NOT NULL DEFAULT 'none',%s varchar(64) NOT NULL DEFAULT 'none',%s varchar(64) NOT NULL DEFAULT 'none',%s varchar(64) NOT NULL DEFAULT 'none',%s varchar(64) NOT NULL DEFAULT 'none',%s varchar(64) NOT NULL DEFAULT 'none',%s varchar(64) NOT NULL DEFAULT 'none',%s varchar(64) NOT NULL DEFAULT 'none',%s varchar(64) NOT NULL DEFAULT 'none',%s varchar(64) NOT NULL DEFAULT 'none',%s varchar(64) NOT NULL DEFAULT 'none',%s varchar(64) NOT NULL DEFAULT 'none',%s varchar(64) NOT NULL DEFAULT 'none',%s varchar(64) NOT NULL DEFAULT 'none',%s varchar(64) NOT NULL DEFAULT 'none',%s varchar(64) NOT NULL DEFAULT 'none',%s varchar(64) NOT NULL DEFAULT 'none',%s varchar(64) NOT NULL DEFAULT 'none',%s varchar(64) NOT NULL DEFAULT 'none',%s varchar(64) NOT NULL DEFAULT 'none',%s varchar(64) NOT NULL DEFAULT 'none',%s varchar(64) NOT NULL DEFAULT 'none',%s varchar(64) NOT NULL DEFAULT 'none',%s varchar(64) NOT NULL DEFAULT 'none',%s varchar(64) NOT NULL DEFAULT 'none',%s varchar(64) NOT NULL DEFAULT 'none',%s varchar(64) NOT NULL DEFAULT 'none',%s varchar(64) NOT NULL DEFAULT 'none',%s varchar(64) NOT NULL DEFAULT 'none',%s varchar(64) NOT NULL DEFAULT 'none',%s varchar(64) NOT NULL DEFAULT 'none',%s varchar(64) NOT NULL DEFAULT 'none',%s varchar(64) NOT NULL DEFAULT 'none',%s varchar(64) NOT NULL DEFAULT 'none',%s varchar(64) NOT NULL DEFAULT 'none',%s varchar(64) NOT NULL DEFAULT 'none',%s varchar(64) NOT NULL DEFAULT 'none',favorite1 varchar(64) NOT NULL DEFAULT 'none',favorite2 varchar(64) NOT NULL DEFAULT 'none',favorite3 varchar(64) NOT NULL DEFAULT 'none',favorite4 varchar(64) NOT NULL DEFAULT 'none',favorite5 varchar(64) NOT NULL DEFAULT 'none',favorite6 varchar(64) NOT NULL DEFAULT 'none',favorite7 varchar(64) NOT NULL DEFAULT 'none',PRIMARY KEY  (steamid))",temp[0],temp[1],temp[2],temp[3],temp[4],temp[5],temp[6],temp[7],temp[8],temp[9],temp[10],temp[11],temp[12],temp[13],temp[14],temp[15],temp[16],temp[17],temp[18],temp[19],temp[20],temp[21],temp[22],temp[23],temp[24],temp[25],temp[26],temp[27],temp[28],temp[29],temp[30],temp[31],temp[32],temp[33],temp[34],temp[35],temp[36],temp[37],temp[38],temp[39],temp[40],temp[41], temp[42], temp[43]);
		
			LogToFileEx(g_sCmdLogPath, "Query %s", buffer);
			SQL_TQuery(db, tbasicoC, buffer);
		}
	}
}

public OnClientDisconnect(client)
{	
	//checked[client] = false;
	chooset[client] = false;
	if(comprobado41[client] && !IsFakeClient(client)) SaveCookies(client);
	comprobado41[client] = false;
	if(arbol[client] != INVALID_HANDLE)
	{
		ClearTrie(arbol[client]);
		CloseHandle(arbol[client]);
		arbol[client] = INVALID_HANDLE;
	}
	if(menu1[client] != INVALID_HANDLE)
	{
		CloseHandle(menu1[client]);
		menu1[client] = INVALID_HANDLE;
	}
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	MarkNativeAsOptional("IsClientInLastRequest");
	MarkNativeAsOptional("Franug_GetKnife");

	return APLRes_Success;
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "hosties"))
	{
		g_hosties = true;
	}
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "hosties"))
	{
		g_hosties = false;
	}
	
	
}

public Action:RemoveSkins(client, args)
{	
	decl String:buffer[1024];
	char steamid[64];
	GetCmdArg(1, steamid, 64);
	if (ismysql == 1)
		Format(buffer, sizeof(buffer), "DELETE FROM `weaponpaints` WHERE `steamid` = '%s';", steamid);
	else
		Format(buffer, sizeof(buffer), "DELETE FROM weaponpaints WHERE steamid = '%s';", steamid);

	LogToFileEx(g_sCmdLogPath, "Query %s", buffer);
	SQL_TQuery(db, tbasicoPRemoved, buffer, GetClientUserId(client));
	
	
	return Plugin_Handled;
}


public Action:ReloadSkins(client, args)
{	
	int count = GetLanguageCount();
	for (new i=0; i<count; i++)
		ReadPaints(i);
		
	
	ReplyToCommand(client, " \x04[WP]\x01 %T","Weapon paints reloaded", client);
	
	return Plugin_Handled;
}

ShowMenu(client, item)
{
	if (item == 0 && GetArraySize(g_hTypesArray[clientlang[client]]) > 0)
	{
		Handle hMenu = CreateMenu(SkinCategoryHandler);
		
		SetMenuTitle(hMenu, "%T", "Paints category menu title", client);
		
		char display[32];
		Format(display, sizeof(display), "%T", "All category", client);
		AddMenuItem(hMenu, "", display);
		
		for (int i; i < GetArraySize(g_hTypesArray[clientlang[client]]); i++)
		{
			char szType[32];
			GetArrayString(g_hTypesArray[clientlang[client]], i, szType, sizeof(szType));
			AddMenuItem(hMenu, "", szType);
		}
		
		DisplayMenu(hMenu, client, 0);
	}
	else
	{
		if (item == -3) // Hack to fix skipping first item
			item = 0;

		SetMenuTitle(menuw[clientlang[client]], "%T","Menu title 1", client);
		
		//RemoveMenuItem(menuw, 2);
		RemoveMenuItem(menuw[clientlang[client]], 1);
		RemoveMenuItem(menuw[clientlang[client]], 0);
		decl String:tdisplay[64];
		//Format(tdisplay, sizeof(tdisplay), "%T", "Choose from your favorite paints", client);
		//InsertMenuItem(menuw, 0, "-2", tdisplay);
		Format(tdisplay, sizeof(tdisplay), "%T", "Random paint", client);
		InsertMenuItem(menuw[clientlang[client]], 0, "0", tdisplay);
		Format(tdisplay, sizeof(tdisplay), "%T", "Default paint", client);
		InsertMenuItem(menuw[clientlang[client]], 1, "-1", tdisplay);
		
		DisplayMenuAtItem(menuw[clientlang[client]], client, item, 0);
	}
}

ShowMenuM(client)
{
	if(onlyadmin && GetUserAdmin(client) == INVALID_ADMIN_ID) return;
	
	new Handle:menu2 = CreateMenu(DIDMenuHandler_2);
	SetMenuTitle(menu2, "%T by Franc1sco franug","Menu title 2", client, DATA);
	
	decl String:tdisplay[64];
	Format(tdisplay, sizeof(tdisplay), "%T", "Select paint for the current weapon", client);
	AddMenuItem(menu2, "1", tdisplay);
	Format(tdisplay, sizeof(tdisplay), "%T", "Select paint for each weapon", client);
	AddMenuItem(menu2, "2", tdisplay);
	//Format(tdisplay, sizeof(tdisplay), "%T", "Favorite paints", client);
	//AddMenuItem(menu2, "3", tdisplay);
	
	DisplayMenu(menu2, client, 0);
}

public Action:GetSkins(client, args)
{	
	Format(s_arma[client], 64, "none");
	ShowMenuM(client);
	
	return Plugin_Handled;
}

public Action:OnClientSayCommand(client, const String:command[], const String:sArgs[])
{
    if(StrEqual(sArgs, "!wskins", false) || StrEqual(sArgs, "!ws", false) || StrEqual(sArgs, "!paints", false))
	{
		Format(s_arma[client], 64, "none");
		//ShowMenuM(client);
		
		if(saytimer != INVALID_HANDLE || g_saytimer == -1) return Plugin_Handled;
		saytimer = CreateTimer(1.0*g_saytimer, Tsaytimer);
		return Plugin_Continue;
		
	}
	else if(StrEqual(sArgs, "!ss", false) || StrEqual(sArgs, "!showskin", false))
	{
		ShowSkin(client);
		
		if(saytimer != INVALID_HANDLE || g_saytimer == -1) return Plugin_Handled;
		saytimer = CreateTimer(1.0*g_saytimer, Tsaytimer);
		return Plugin_Continue;
	}
    
    return Plugin_Continue;
}

ShowSkin(client)
{
	new weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(weapon < 1 || !IsValidEdict(weapon) || !IsValidEntity(weapon))
	{
		CPrintToChat(client, " {green}[WP]{default} %T", "Paint not found", client);
		return;
	}
	
	new buscar = GetEntProp(weapon,Prop_Send,"m_nFallbackPaintKit");
	for(new i=1; i<g_paintCount[clientlang[client]];i++)
	{
		if(buscar == g_paints[clientlang[client]][i][index])
		{
			CPrintToChat(client, " {green}[WP]{default} %T", "Paint found", client, g_paints[clientlang[client]][i][Nombre]);
			return;
		}
	}
	
	CPrintToChat(client, " {green}[WP]{default} %T", "Paint not found", client);
}

public Action:Tsaytimer(Handle:timer)
{
	saytimer = INVALID_HANDLE;
}

public Action:roundStart(Handle:event, const String:name[], bool:dontBroadcast) 
{
	if(g_rtimer == -1) return;
	
	if(rtimer != INVALID_HANDLE)
	{
		KillTimer(rtimer);
		rtimer = INVALID_HANDLE;
	}
	
	rtimer = CreateTimer(1.0*g_rtimer, Rtimer);
}

public Action:Rtimer(Handle:timer)
{
	rtimer = INVALID_HANDLE;
}

public DIDMenuHandler_2(Handle:menu, MenuAction:action, client, itemNum) 
{
	if ( action == MenuAction_Select ) 
	{

		
		decl String:info[4];
		
		GetMenuItem(menu, itemNum, info, sizeof(info));
		new theindex = StringToInt(info);
		if(theindex == 1) ShowMenu(client, 0);
		else if(theindex == 2 && comprobado41[client]) ShowMenuArmas(client, 0);
		//else if(theindex == 3) ShowMenuFav(client);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public int SkinCategoryHandler(Handle menu, MenuAction action, int client, int itemNum) 
{
	if ( action == MenuAction_Select ) 
	{
		if (itemNum == 0)
		{
			ShowMenu(client, -3);
			return;
		}
		
		char szType[32];
		GetArrayString(g_hTypesArray[clientlang[client]], itemNum-1, szType, sizeof(szType));		
		SetMenuTitle(g_hTypesMenu[clientlang[client]][itemNum-1], "%T", "Choose a paint from a category menu title", client, szType);
		DisplayMenu(g_hTypesMenu[clientlang[client]][itemNum-1], client, 0);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

ShowMenuArmas(client, item)
{	
	if(menu1[client] == INVALID_HANDLE) CrearMenu1(client);
	DisplayMenuAtItem(menu1[client], client, item, 0);
}

public DIDMenuHandler(Handle:menu, MenuAction:action, client, itemNum) 
{
	if ( action == MenuAction_Select ) 
	{
		if(!comprobado41[client])
		{
			if(g_rmenu) ShowMenu(client, GetMenuSelectionPosition());
			return;
		}
		
		decl String:Classname[64];
		decl String:info[4];
		
		GetMenuItem(menu, itemNum, info, sizeof(info));
		new theindex = StringToInt(info);
		
		if(StrEqual(s_arma[client], "none"))
		{
			if(GetUserAdmin(client) == INVALID_ADMIN_ID && rtimer == INVALID_HANDLE && g_rtimer != -1)
			{
				CPrintToChat(client, " {green}[WP]{default} %T", "You can use this command only the first seconds", client, g_rtimer);
				if(g_rmenu) ShowMenu(client, GetMenuSelectionPosition());
				return;
			}
			if(!IsPlayerAlive(client))
			{
				CPrintToChat(client, " {green}[WP]{default} %T", "You cant use this when you are dead", client);
				if(g_rmenu) ShowMenu(client, GetMenuSelectionPosition());
				return;
			}
			if(g_hosties && IsClientInLastRequest(client))
			{
				CPrintToChat(client, " {green}[WP]{default} %T", "You cant use this when you are in a lastrequest", client);
				if(g_rmenu) ShowMenu(client, GetMenuSelectionPosition());
				return;
			}

			if(theindex != -1 && !StrEqual(g_paints[clientlang[client]][theindex][flag], "0"))
			{
				if(!CheckCommandAccess(client, "weaponpaints_override", ReadFlagString(g_paints[clientlang[client]][theindex][flag]), true))
				{
					CPrintToChat(client, " {green}[WP]{default} %T", "You dont have access to this paint", client);
					if(g_rmenu) ShowMenu(client, GetMenuSelectionPosition());
					return;
				}
			}
			
		
			new windex = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if(windex < 1)
			{
				CPrintToChat(client, " {green}[WP]{default} %T", "You cant use a paint in this weapon", client);
				if(g_rmenu) ShowMenu(client, GetMenuSelectionPosition());
				return;
			}
		
		
			if(!GetEdictClassname(windex, Classname, 64) || StrEqual(Classname, "weapon_taser") || (!g_c4 && StrEqual(Classname, "weapon_c4")))
			{
				CPrintToChat(client, " {green}[WP]{default} %T", "You cant use a paint in this weapon", client);
				if(g_rmenu) ShowMenu(client, GetMenuSelectionPosition());
				return;
			}
			ReplaceString(Classname, 64, "weapon_", "");
			new weaponindex = GetEntProp(windex, Prop_Send, "m_iItemDefinitionIndex");
			if(weaponindex == 42 || weaponindex == 59)
			{
				CPrintToChat(client, " {green}[WP]{default} %T", "You cant use a paint in this weapon", client);
				if(g_rmenu) ShowMenu(client, GetMenuSelectionPosition());
				return;
			}
			if(GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) == windex || GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY) == windex || GetPlayerWeaponSlot(client, CS_SLOT_KNIFE) == windex || (g_c4 && GetPlayerWeaponSlot(client, CS_SLOT_C4) == windex))
			{
				switch (weaponindex)
				{
					case 60: strcopy(Classname, 64, "m4a1_silencer");
					case 61: strcopy(Classname, 64, "usp_silencer");
					case 63: strcopy(Classname, 64, "cz75a");
					case 500: strcopy(Classname, 64, "bayonet");
					case 506: strcopy(Classname, 64, "knife_gut");
					case 505: strcopy(Classname, 64, "knife_flip");
					case 508: strcopy(Classname, 64, "knife_m9_bayonet");
					case 507: strcopy(Classname, 64, "knife_karambit");
					case 509: strcopy(Classname, 64, "knife_tactical");
					case 515: strcopy(Classname, 64, "knife_butterfly");
					case 512: strcopy(Classname, 64, "knife_falchion");
					case 516: strcopy(Classname, 64, "knife_push");
					case 64: strcopy(Classname, 64, "revolver");
					case 514: strcopy(Classname, 64, "knife_survival_bowie");
				}
				
				if(arbol[client] == INVALID_HANDLE)
				{
					//checked[client] = false;
					CreateTimer(0.0, Timer_ClientLanguage, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);
					return;
				}
				else 
				{
					new valor = 0;
					if(!GetTrieValue(arbol[client], Classname, valor))
					{
						CPrintToChat(client, " {green}[WP]{default} %T", "You cant use a paint in this weapon", client);
						if(g_rmenu) ShowMenu(client, GetMenuSelectionPosition());
						return;
					}
					
					decl String:buffer[1024], String:nombres[64];
					if(theindex == -1) Format(nombres, sizeof(nombres), "default");
					else Format(nombres, sizeof(nombres), g_paints[clientlang[client]][theindex][Nombre]);
					decl String:steamid[32];
					GetClientAuthId(client, AuthId_Steam2,  steamid, sizeof(steamid) );
					Format(buffer, sizeof(buffer), "UPDATE weaponpaints SET %s = '%s' WHERE steamid = '%s';", Classname,nombres,steamid);
					LogToFileEx(g_sCmdLogPath, "Query %s", buffer);
					SQL_TQuery(db, tbasico, buffer, GetClientUserId(client));
					SetTrieValue(arbol[client], Classname, theindex);
				}
				
				//ChangePaint(client, windex, Classname, weaponindex, true);
				decl String:Classname2[64];
				Format(Classname2, 64, "weapon_%s", Classname);
				Restore(client, windex, Classname2);
				FakeClientCommand(client, "use %s", Classname2);
				if(theindex == -1) CPrintToChat(client, " {green}[WP]{default} %T","You have choose your default paint for your",client, Classname);
				else if(theindex == 0) CPrintToChat(client, " {green}[WP]{default} %T","You have choose a random paint for your",client, Classname);
				else CPrintToChat(client, " {green}[WP]{default} %T", "You have choose a weapon",client, g_paints[clientlang[client]][theindex][Nombre], Classname);
				
				decl String:temp[128], String:temp1[64];
				if(theindex == -1) Format(temp, 128, "%s", Classname);
				else if (theindex == 0)
				{
				
					Format(temp1, sizeof(temp1), "%T", "Random paint", client);
					Format(temp, 128, "%s - %s", Classname, temp1);
				}
				else Format(temp, 128, "%s - %s", Classname, g_paints[clientlang[client]][theindex][Nombre]);
				if(menu1[client] == INVALID_HANDLE) CrearMenu1(client);
				new imenu = FindStringInArray(array_armas, Classname);
				InsertMenuItem(menu1[client], imenu, Classname, temp);
				FindStringInArray(array_armas, Classname);
				RemoveMenuItem(menu1[client], imenu+1);
			}
			else CPrintToChat(client, " {green}[WP]{default} %T", "You cant use a paint in this weapon",client);
			
			
		}
		else
		{
			Format(Classname, 64, s_arma[client]);
			
			if(arbol[client] == INVALID_HANDLE)
			{
				//checked[client] = false;
				CreateTimer(0.0, Timer_ClientLanguage, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);
				return;
			}
			else 
			{
				decl String:buffer[1024], String:nombres[64];
				if(theindex == -1) Format(nombres, sizeof(nombres), "default");
				else Format(nombres, sizeof(nombres), g_paints[clientlang[client]][theindex][Nombre]);
				decl String:steamid[32];
				GetClientAuthId(client, AuthId_Steam2,  steamid, sizeof(steamid) );
				Format(buffer, sizeof(buffer), "UPDATE weaponpaints SET %s = '%s' WHERE steamid = '%s';", Classname,nombres,steamid);
				LogToFileEx(g_sCmdLogPath, "Query %s", buffer);
				SQL_TQuery(db, tbasico, buffer, GetClientUserId(client));
				SetTrieValue(arbol[client], Classname, theindex);
			}
			
			if(theindex == -1) CPrintToChat(client, " {green}[WP]{default} %T","You have choose your default paint for your",client, Classname);
			else if(theindex == 0) CPrintToChat(client, " {green}[WP]{default} %T","You have choose a random paint for your",client, Classname);
			else CPrintToChat(client, " {green}[WP]{default} %T", "You have choose a weapon",client, g_paints[clientlang[client]][theindex][Nombre], Classname);
			
			decl String:temp[128], String:temp1[64];
			if(theindex == -1) Format(temp, 128, "%s", Classname);
			else if (theindex == 0)
			{
				
				Format(temp1, sizeof(temp1), "%T", "Random paint", client);
				Format(temp, 128, "%s - %s", Classname, temp1);
			}
			else Format(temp, 128, "%s - %s", Classname, g_paints[clientlang[client]][theindex][Nombre]);
			new imenu = FindStringInArray(array_armas, Classname);
			InsertMenuItem(menu1[client], imenu, Classname, temp);
			FindStringInArray(array_armas, Classname);
			RemoveMenuItem(menu1[client], imenu+1);
			Format(s_arma[client], 64, "none");
			ShowMenuArmas(client, s_sele[client]);
			return;
		}

		if(g_rmenu) 
		{
			bool found = false;
			
			for (int i; i < GetMenuItemCount(menu); i++)
			{
				GetMenuItem(menu, i, info, sizeof(info));
				
				if (StrEqual(info, "cat"))
					found = true;
			}

			if (found)
				DisplayMenu(menu, client, 0);
			else
				ShowMenu(client, GetMenuSelectionPosition());
		}
	}
}

/* public Action:RestoreItemID(Handle:timer, Handle:pack)
{
    new entity;
    new m_iItemIDHigh;
    new m_iItemIDLow;
    
    ResetPack(pack);
    entity = EntRefToEntIndex(ReadPackCell(pack));
    m_iItemIDHigh = ReadPackCell(pack);
    m_iItemIDLow = ReadPackCell(pack);
    
    if(entity != INVALID_ENT_REFERENCE)
	{
		SetEntProp(entity,Prop_Send,"m_iItemIDHigh",m_iItemIDHigh);
		SetEntProp(entity,Prop_Send,"m_iItemIDLow",m_iItemIDLow);
	}
} */

ReadPaints(index_new)
{
	g_hTypesArray[index_new] = CreateArray(32);
	array_paints[index_new] = CreateArray(128);
	char code[64], language[128];
	GetLanguageInfo(index_new, code, 64, language, 128);
	
	BuildPath(Path_SM, path_paints, sizeof(path_paints), "configs/franug_weaponpaints/csgo_wpaints_%s.cfg", language);
	
	if(!FileExists(path_paints)) BuildPath(Path_SM, path_paints, sizeof(path_paints), "configs/franug_weaponpaints/csgo_wpaints_english.cfg");
	
	decl Handle:kv;
	g_paintCount[index_new] = 1;
	ClearArray(array_paints[index_new]);
	PushArrayString(array_paints[index_new], "random");
	Format(g_paints[index_new][0][Nombre], 64, "random")

	kv = CreateKeyValues("Paints");
	FileToKeyValues(kv, path_paints);

	if (!KvGotoFirstSubKey(kv)) {

		SetFailState("CFG File not found: %s", path_paints);
		CloseHandle(kv);
	}
	do {

		KvGetSectionName(kv, g_paints[index_new][g_paintCount[index_new]][Nombre], 64);
		g_paints[index_new][g_paintCount[index_new]][index] = KvGetNum(kv, "paint", 0);
		g_paints[index_new][g_paintCount[index_new]][wear] = KvGetFloat(kv, "wear", 0.01);
		g_paints[index_new][g_paintCount[index_new]][stattrak] = KvGetNum(kv, "stattrak", -2);
		g_paints[index_new][g_paintCount[index_new]][quality] = KvGetNum(kv, "quality", 3);
		g_paints[index_new][g_paintCount[index_new]][pattern] = KvGetNum(kv, "pattern", 0);
		KvGetString(kv, "flag", g_paints[index_new][g_paintCount[index_new]][flag], 8, "0");
		KvGetString(kv, "type", g_paints[index_new][g_paintCount[index_new]][type], 11, "None");
		
		if (FindStringInArray(g_hTypesArray[index_new], g_paints[index_new][g_paintCount[index_new]][type]) == -1)
			PushArrayString(g_hTypesArray[index_new], g_paints[index_new][g_paintCount[index_new]][type]);

		PushArrayString(array_paints[index_new], g_paints[index_new][g_paintCount[index_new]][Nombre]);
		g_paintCount[index_new]++;
	} while (KvGotoNextKey(kv));
	CloseHandle(kv);
	
	SortADTArray(g_hTypesArray[index_new], Sort_Ascending, Sort_String);
	
	if(menuw[index_new] != INVALID_HANDLE) CloseHandle(menuw[index_new]);
	menuw[index_new] = INVALID_HANDLE;
	
	menuw[index_new] = CreateMenu(DIDMenuHandler);
	
	// TROLLING
	SetMenuTitle(menuw[index_new], "( ͡° ͜ʖ ͡°)");
	decl String:item[4];
	AddMenuItem(menuw[index_new], "0", "Random paint");
	AddMenuItem(menuw[index_new], "-1", "Default paint"); 
	// FORGET THIS
	
	for (new i=g_paintCount[index_new]; i<MAX_PAINTS; ++i) {
	
		g_paints[index_new][i][index] = 0;
	}
	//decl String:menuitem[192];
	for (new i=1; i<g_paintCount[index_new]; ++i) {
		Format(item, 4, "%i", i);
		AddMenuItem(menuw[index_new], item, g_paints[index_new][i][Nombre]);
		
/* 		if(StrEqual(g_paints[g_paintCount][flag], "public", false))
		{
			AddMenuItem(menuw, item, g_paints[i][Nombre]);
		}
		else 
		{
			Format(menuitem, 192, "%s (flag %s)", g_paints[i][Nombre],g_paints[i][flag]);
			AddMenuItem(menuw, item, menuitem);
		} */
	}
	
	SetMenuExitButton(menuw[index_new], true);
	
	for (int i; i < GetArraySize(g_hTypesArray[index_new]); i++)
	{
		char szType[32];
		GetArrayString(g_hTypesArray[index_new], i, szType, sizeof(szType));
		
		g_hTypesMenu[index_new][i] = INVALID_HANDLE;
		g_hTypesMenu[index_new][i] = CreateMenu(DIDMenuHandler);
		SetMenuExitButton(g_hTypesMenu[index_new][i], true);
		
		AddMenuItem(g_hTypesMenu[index_new][i], "cat", "", ITEMDRAW_IGNORE);
		
		for (int j = 1; j < g_paintCount[index_new]; ++j)
		{
			Format(item, 4, "%i", j);
			if (StrEqual(g_paints[index_new][j][type], szType))
				AddMenuItem(g_hTypesMenu[index_new][i], item, g_paints[index_new][j][Nombre]);
		}
	}	
}

/* stock GetReserveAmmo(client, weapon)
{
    new ammotype = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
    if(ammotype == -1) return -1;
    
    return GetEntProp(client, Prop_Send, "m_iAmmo", _, ammotype);
}

stock SetReserveAmmo(client, weapon, ammo)
{
    new ammotype = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
    if(ammotype == -1) return;
    
    SetEntProp(client, Prop_Send, "m_iAmmo", ammo, _, ammotype);
}  */

stock GetReserveAmmo(weapon)
{
	new ammotype = GetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount");
	if(ammotype == -1) return -1;
    
	return ammotype;
}

stock SetReserveAmmo(weapon, ammo)
{
	SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", ammo);
	//PrintToChatAll("fijar es %i", ammo);
} 

Restore(client, windex, String:Classname[64])
{
	new bool:knife = false;
	if(StrContains(Classname, "weapon_knife", false) == 0 || StrContains(Classname, "weapon_bayonet", false) == 0) 
	{
		knife = true;
	}
	
	if(knife)
	{
		if(GetFeatureStatus(FeatureType_Native, "Franug_GetKnife") == FeatureStatus_Available) 
			GiveNamedItem_GiveKnife(client, Franug_GetKnife(client));
		else
		{
			RemovePlayerItem(client, windex);
			AcceptEntityInput(windex, "Kill");
	
			GivePlayerItem(client, "weapon_knife");
		}
		return;
	}
	
	//PrintToChat(client, "weapon %s", Classname);
	new ammo, clip;
	ammo = GetReserveAmmo(windex);
	clip = GetEntProp(windex, Prop_Send, "m_iClip1");
	
	RemovePlayerItem(client, windex);
	AcceptEntityInput(windex, "Kill");
	
	new entity = GivePlayerItem(client, Classname);

	SetReserveAmmo(entity, ammo);
	SetEntProp(entity, Prop_Send, "m_iClip1", clip);
}

public OnGiveNamedItemEx(int client, const char[] Classname)
{
	if (StrContains(Classname, "weapon_") != 0)
		return;

	if (IsFakeClient(client))
		return;
		
	int itemdefinition = GiveNamedItemEx.GetItemDefinitionByClassname(Classname);
	
	if (itemdefinition == -1)
		return;
		
	if(onlyadmin && GetUserAdmin(client) == INVALID_ADMIN_ID) return;
		
	
	if(StrEqual(Classname, "weapon_taser") || (!g_c4 && StrEqual(Classname, "weapon_c4")))
	{
		return;
	}
	if(GiveNamedItemEx.IsClassnameKnife(Classname))
	{
		if(GetFeatureStatus(FeatureType_Native, "Franug_GetKnife") == FeatureStatus_Available) 
		{
			itemdefinition = Franug_GetKnife(client);
			if(itemdefinition < 2)
				return;
		}
	
		if(itemdefinition == 42 || itemdefinition == 59)
		{
			return;
		}
	}
	
	char classnamet[64];
	//Format(classnamet, 64, Classname);
	GiveNamedItemEx.GetClassnameByItemDefinition(itemdefinition, classnamet, 64);
	ReplaceString(classnamet, 64, "weapon_", "");

	if(arbol[client] == INVALID_HANDLE) return;
	new valor = 0;
	if(!GetTrieValue(arbol[client], classnamet, valor)) return;
	if(valor == -1 || (valor != 0 && g_paints[clientlang[client]][valor][index] == 0)) return;
	
	if(valor == 0)
	{
		valor = GetRandomInt(1, g_paintCount[clientlang[client]]-1);
	}
	else if(valor == -1) return;
	
/* 	new m_iItemIDHigh = GetEntProp(entity, Prop_Send, "m_iItemIDHigh");
	new m_iItemIDLow = GetEntProp(entity, Prop_Send, "m_iItemIDLow"); */
	GiveNamedItemEx.Paintkit = g_paints[clientlang[client]][valor][index];
	
	if(g_paints[clientlang[client]][valor][wear] >= 0.0) GiveNamedItemEx.Wear = g_paints[clientlang[client]][valor][wear];
	if(g_paints[clientlang[client]][valor][pattern] >= 0) GiveNamedItemEx.Seed = g_paints[clientlang[client]][valor][pattern];
	if(g_paints[clientlang[client]][valor][stattrak] != -2) GiveNamedItemEx.Kills = g_paints[clientlang[client]][valor][stattrak];
	if(g_paints[clientlang[client]][valor][quality] != -2) GiveNamedItemEx.EntityQuality = g_paints[clientlang[client]][valor][quality];
}

SaveCookies(client)
{
	decl String:steamid[32];
	GetClientAuthId(client, AuthId_Steam2,  steamid, sizeof(steamid) );
	new String:Name[MAX_NAME_LENGTH+1];
	new String:SafeName[(sizeof(Name)*2)+1];
	if (!GetClientName(client, Name, sizeof(Name)))
		Format(SafeName, sizeof(SafeName), "<noname>");
	else
	{
		TrimString(Name);
		SQL_EscapeString(db, Name, SafeName, sizeof(SafeName));
	}	

	decl String:buffer[3096];
	Format(buffer, sizeof(buffer), "UPDATE weaponpaints SET last_accountuse = %d, playername = '%s' WHERE steamid = '%s';",GetTime(), SafeName,steamid);
	LogToFileEx(g_sCmdLogPath, "Query %s", buffer);
	SQL_TQuery(db, tbasico2, buffer);
}

CrearMenu1(client)
{
	
	menu1[client] = CreateMenu(DIDMenuHandler_armas);
	SetMenuTitle(menu1[client], "%T","Menu title 1", client);
	
	new String:Items[64];
	
	decl String:temp[128], String:temp1[64];
	new valor;
	for(new i=0;i<GetArraySize(array_armas);++i)
	{
		GetArrayString(array_armas, i, Items, 64);
		if(GetTrieValue(arbol[client], Items, valor))
		{
			if(valor == -1) Format(temp, 128, "%s", Items);
			else if (valor == 0)
			{
				Format(temp1, sizeof(temp1), "%T", "Random paint", client);
				Format(temp, 128, "%s - %s", Items, temp1);
			}
			else Format(temp, 128, "%s - %s", Items, g_paints[clientlang[client]][valor][Nombre]);
		}
		else Format(temp, 128, "%s", Items);
		AddMenuItem(menu1[client], Items, temp);
	}
}

public DIDMenuHandler_armas(Handle:menu, MenuAction:action, client, itemNum) 
{
	if ( action == MenuAction_Select ) 
	{
		decl String:info[64];
		
		GetMenuItem(menu, itemNum, info, sizeof(info));

		Format(s_arma[client], 64, info);
		s_sele[client] = GetMenuSelectionPosition();
		ShowMenu(client, 0);
	}
}

CheckSteamID(client)
{
	decl String:query[255], String:steamid[32];
	GetClientAuthId(client, AuthId_Steam2,  steamid, sizeof(steamid) );
	
	Format(query, sizeof(query), "SELECT * FROM weaponpaints WHERE steamid = '%s'", steamid);
	LogToFileEx(g_sCmdLogPath, "Query %s", query);
	SQL_TQuery(db, T_CheckSteamID, query, GetClientUserId(client));
}
 
public T_CheckSteamID(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client;
 
	/* Make sure the client didn't disconnect while the thread was running */
	if ((client = GetClientOfUserId(data)) == 0)
	{
		return;
	}
	if (hndl == INVALID_HANDLE)
	{
		ComprobarDB();
		return;
	}
	//PrintToChatAll("comprobado41");
	if (!SQL_GetRowCount(hndl) || !SQL_FetchRow(hndl)) 
	{
		Nuevo(client);
		return;
	}
	
	arbol[client] = CreateTrie();

	new String:Items[64];
	
	new String:temp[64];
	new contar = 3;
	//PrintToChat(client, "pasado");
	for(new i=0;i<GetArraySize(array_armas);++i)
	{
		GetArrayString(array_armas, i, Items, 64);
		SQL_FetchString(hndl, contar, temp, 64);
		SetTrieValue(arbol[client], Items, FindStringInArray(array_paints[clientlang[client]], temp));
		
		//PrintToChat(client, "Sacado %i del arma %s", FindStringInArray(array_paints[clientlang[client]], temp),Items);
		
		contar++;
	}

/*   	SQL_FetchString(hndl, contar, temp, 64);
	SetTrieValue(arbol[client], "favorite1", FindStringInArray(array_paints, temp));
	contar++;
	
	SQL_FetchString(hndl, contar, temp, 64);
	SetTrieValue(arbol[client], "favorite2", FindStringInArray(array_paints, temp));
	contar++;
	
	SQL_FetchString(hndl, contar, temp, 64);
	SetTrieValue(arbol[client], "favorite3", FindStringInArray(array_paints, temp));
	contar++;
	
	SQL_FetchString(hndl, contar, temp, 64);
	SetTrieValue(arbol[client], "favorite4", FindStringInArray(array_paints, temp));
	contar++;
	
	SQL_FetchString(hndl, contar, temp, 64);
	SetTrieValue(arbol[client], "favorite5", FindStringInArray(array_paints, temp));
	contar++;
	
	SQL_FetchString(hndl, contar, temp, 64);
	SetTrieValue(arbol[client], "favorite6", FindStringInArray(array_paints, temp));
	contar++;
	
	SQL_FetchString(hndl, contar, temp, 64);
	SetTrieValue(arbol[client], "favorite7", FindStringInArray(array_paints, temp));
	contar++; */
	
	
	comprobado41[client] = true;
/* 	new String:equipo[64];
	SQL_FetchString( hndl, 0, equipo, 64);
	PrintToChatAll(equipo);
	
	SQL_FetchString( hndl, 1, equipo, 64);
	PrintToChatAll(equipo);
	
	SQL_FetchString( hndl, 2, equipo, 64);
	PrintToChatAll(equipo);
	
	SQL_FetchString( hndl, 3, equipo, 64); // este
	PrintToChatAll(equipo); */
	
	//PrintToChatAll("pasado");
	
/* 	new String:equipo[4];
	SQL_FetchString( hndl, 0, equipo, 4);
	
	if(StrEqual(equipo, "CT", false))
	{
		ft[client] = CS_TEAM_CT;
	}
	else if(StrEqual(equipo, "T", false))
	{
		ft[client] = CS_TEAM_T;
	} */
	Renovar(client);

}

public tbasicoPRemoved(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client;
 
	/* Make sure the client didn't disconnect while the thread was running */
	if ((client = GetClientOfUserId(data)) == 0)
	{
		return;
	}
	if (hndl == INVALID_HANDLE)
	{
		ComprobarDB();
		return;
	}
	
	PrintToChat(client, "Client deleted");
}

Renovar(client)
{
	if(IsPlayerAlive(client))
	{
		char classname[64];
		int weaponIndex;
		for (new i = 0; i <= 3; i++)
		{
			if(i == CS_SLOT_GRENADE) continue;
			
			if ((weaponIndex = GetPlayerWeaponSlot(client, i)) != -1)
			{
				GetEdictClassname(weaponIndex, classname, 64);
				
				Restore(client, weaponIndex, classname);
			}
		}
	}
}

Nuevo(client)
{
	//PrintToChatAll("metido");
	decl String:query[255], String:steamid[32];
	GetClientAuthId(client, AuthId_Steam2,  steamid, sizeof(steamid) );
	new userid = GetClientUserId(client);
	
	new String:Name[MAX_NAME_LENGTH+1];
	new String:SafeName[(sizeof(Name)*2)+1];
	if (!GetClientName(client, Name, sizeof(Name)))
		Format(SafeName, sizeof(SafeName), "<noname>");
	else
	{
		TrimString(Name);
		SQL_EscapeString(db, Name, SafeName, sizeof(SafeName));
	}
		
	Format(query, sizeof(query), "INSERT INTO weaponpaints(playername, steamid, last_accountuse) VALUES('%s', '%s', '%d');", SafeName, steamid, GetTime());
	LogToFileEx(g_sCmdLogPath, "Query %s", query);
	SQL_TQuery(db, tbasico3, query, userid);
}


public PruneDatabase()
{
	if (db == INVALID_HANDLE)
	{
		LogToFileEx(g_sCmdLogPath, "Prune Database: No connection");
		ComprobarDB();
		return;
	}

	new maxlastaccuse;
	maxlastaccuse = GetTime() - (IDAYS * 86400);

	decl String:buffer[1024];

	if (ismysql == 1)
		Format(buffer, sizeof(buffer), "DELETE FROM `weaponpaints` WHERE `last_accountuse`<'%d' AND `last_accountuse`>'0';", maxlastaccuse);
	else
		Format(buffer, sizeof(buffer), "DELETE FROM weaponpaints WHERE last_accountuse<'%d' AND last_accountuse>'0';", maxlastaccuse);

	LogToFileEx(g_sCmdLogPath, "Query %s", buffer);
	SQL_TQuery(db, tbasicoP, buffer);
}

public tbasico(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogToFileEx(g_sCmdLogPath, "Query failure: %s", error);
	}
	new client;
 
	/* Make sure the client didn't disconnect while the thread was running */
	if ((client = GetClientOfUserId(data)) == 0)
	{
		return;
	}
	comprobado41[client] = true;
	
}

public tbasico2(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogToFileEx(g_sCmdLogPath, "Query failure: %s", error);
		ComprobarDB();
	}
}

public tbasico3(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogToFileEx(g_sCmdLogPath, "Query failure: %s", error);
		ComprobarDB();
	}
	new client;
 
	/* Make sure the client didn't disconnect while the thread was running */
	if ((client = GetClientOfUserId(data)) == 0)
	{
		return;
	}
	
	arbol[client] = CreateTrie();

	new String:Items[64];
	
	for(new i=0;i<GetArraySize(array_armas);++i)
	{
		GetArrayString(array_armas, i, Items, 64);
		SetTrieValue(arbol[client], Items, -1);
	}
	
	SetTrieValue(arbol[client], "favorite1", -1);
	SetTrieValue(arbol[client], "favorite2", -1);
	SetTrieValue(arbol[client], "favorite3", -1);
	SetTrieValue(arbol[client], "favorite4", -1);
	SetTrieValue(arbol[client], "favorite5", -1);
	SetTrieValue(arbol[client], "favorite6", -1);
	SetTrieValue(arbol[client], "favorite7", -1);
	
	comprobado41[client] = true;
}

public tbasicoC(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogToFileEx(g_sCmdLogPath, "Query failure: %s", error);
	}
	//LogMessage("Database connection successful");
	
	for(new client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			//checked[client] = false;
			CreateTimer(0.0, Timer_ClientLanguage, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public tbasicoP(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogToFileEx(g_sCmdLogPath, "Query failure: %s", error);
		ComprobarDB();
	}
	//LogMessage("Prune Database successful");
}