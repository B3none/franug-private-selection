/*
	Franug Knives

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
#include <sdkhooks>
#include <cstrike>
#include <clientprefs>
#include <weapons>
#include <givenameditem>

#pragma semicolon 1

#define MAX_KNIVES 50 //Not sure how many knives will eventually be in the game until its death.

#define DATA "3.0.5 private version"

enum KnifeList{
	String:Name[64],
	KnifeID,
	String:flag[24]
};

ArrayList KnivesArray;
char path_knives[PLATFORM_MAX_PATH];
knives[MAX_KNIVES][KnifeList];
int knifeCount = 0;


public Plugin myinfo = {
	name = "SM CS:GO Franug Knives",
	author = "Franc1sco franug",
	description = "",
	version = DATA,
	url = "http://steamcommunity.com/id/franug"
};

int knife[MAXPLAYERS+1];

Handle c_knife;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("Franug_GetKnife", Native_GetKnife);
	return APLRes_Success;
}

public Native_GetKnife(Handle:plugin, params)
{
	int client = GetNativeCell(1);
	if (knife[client] < 0 || knife[client] > (MAX_KNIVES - 1))return -1;
	
	return knives[knife[client]][KnifeID];
}

public void OnPluginStart() {
	c_knife = RegClientCookie("hknife3", "", CookieAccess_Private);
	
	RegConsoleCmd("sm_knife", DID);
	
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && !IsFakeClient(i) && AreClientCookiesCached(i)) {
			OnClientCookiesCached(i);
		}
	}
	KnivesArray = new ArrayList(64);
	loadKnives();
}

public Action DID(int clientId, int args) {
	loadKnifeMenu(clientId, -1);
	return Plugin_Handled;
}

public void loadKnifeMenu(int clientId, int menuPosition) {
	Menu menu = CreateMenu(DIDMenuHandler_h);
	menu.SetTitle("Franug Knife %s\nChoose you knife.", DATA);
	
	char item[4], item2[124];
	for (int i = 0; i < knifeCount; ++i) {
		Format(item, 4, "%i", i);
		if(knife[clientId] == i)
		{
			Format(item2, 124, "%s (Current knife)", knives[i][Name]);
			menu.AddItem(item, item2, ITEMDRAW_DISABLED);
		}
		else if(!HasFlag(clientId,knives[i][flag]))
		{
			Format(item2, 124, "%s (Vip knife)", knives[i][Name]);
			menu.AddItem(item, item2, ITEMDRAW_DISABLED);
		}
		else
			menu.AddItem(item, knives[i][Name], ITEMDRAW_DEFAULT);
	}
	
	SetMenuExitButton(menu, true);
	
	if(menuPosition == -1){
		menu.Display(clientId, 0);
	} else menu.DisplayAt(clientId, menuPosition, 0);
	
}

public int DIDMenuHandler_h(Menu menu, MenuAction action, int client, int itemNum) {
	switch(action){
		case MenuAction_Select:{
			char info[32];
		
			menu.GetItem(itemNum, info, sizeof(info));

			knife[client] = StringToInt(info);
		
			char cookie[8];
			IntToString(knife[client], cookie, 8);
			SetClientCookie(client, c_knife, cookie);
		
			if (knife[client] < 0 || knife[client] > (MAX_KNIVES - 1))knife[client] = 0;
			if(knives[knife[client]][KnifeID] > -1)
			{
				if(IsPlayerAlive(client)) GiveNamedItem_GiveKnife(client, knives[knife[client]][KnifeID]);
				
			}
			else DarKnife(client);
		
			loadKnifeMenu(client, GetMenuSelectionPosition());
		}
		case MenuAction_End: delete menu;
	}
}

public OnGiveNamedItemEx(int client, const char[] Classname)
{
	
	if(GiveNamedItemEx.IsClassnameKnife(Classname))
	{
		if (knife[client] < 0 || knife[client] > (MAX_KNIVES - 1))return;
		
		if(knives[knife[client]][KnifeID] > -1) GiveNamedItemEx.ItemDefinition = knives[knife[client]][KnifeID];
	}
}

public void OnClientCookiesCached(int client) {
	char value[16];
	GetClientCookie(client, c_knife, value, sizeof(value));
	if(strlen(value) > 0) knife[client] = StringToInt(value);
	else knife[client] = 0;
}

public void DarKnife(int client) {
	if(!IsPlayerAlive(client)) return;
	
	int iWeapon = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE);
	if (iWeapon != -1) {
		RemovePlayerItem(client, iWeapon);
		AcceptEntityInput(iWeapon, "Kill");
		
		GivePlayerItem(client, "weapon_knife");
	}
}

public void loadKnives() {
	BuildPath(Path_SM, path_knives, sizeof(path_knives), "configs/csgo_knives.cfg");
	KeyValues kv = new KeyValues("Knives");
	knifeCount = 0;
	ClearArray(KnivesArray);
	
	kv.ImportFromFile(path_knives);
	
	if (!kv.GotoFirstSubKey()){
		SetFailState("Knives Config not found: %s. Please install the cfg file in the addons/sourcemod/configs", path_knives);
		delete kv;
	}
	do {
		kv.GetSectionName(knives[knifeCount][Name], 64);
		knives[knifeCount][KnifeID] = kv.GetNum("KnifeID", 0);
		KvGetString(kv, "flag", knives[knifeCount][flag], 24, "public");
		PushArrayString(KnivesArray, knives[knifeCount][Name]);
		knifeCount++;
	} while (kv.GotoNextKey());
	
	delete kv;
	for (int i=knifeCount; i<MAX_KNIVES; ++i) {
		knives[i][KnifeID] = -1;
	}
}


bool:HasFlag(client, String:flags[])
{
	if(StrEqual(flags, "public")) return true;
	
	if (GetUserFlagBits(client) & ADMFLAG_ROOT)
	{
		return true;
	}

	new iFlags = ReadFlagString(flags);

	if ((GetUserFlagBits(client) & iFlags) == iFlags)
	{
		return true;
	}

	return false;
}  