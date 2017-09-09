/*
	GiveNamedItem Hook Franug Edition

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
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#define _givenameditem_server
#include <givenameditem>
#include "givenameditem/convars.inc"
//#include "givenameditem/hook.inc"
#include "givenameditem/items.inc"
#include "givenameditem/mm_server.inc"
#include "givenameditem/natives.inc"
#include "givenameditem/commands.inc"
#pragma semicolon 1

Handle g_hOnGiveNamedItemFoward = null;

#define DATA "4.0.4 private version"


char gC_Knives[][][] = {
	{"42", "Default CT", "models/weapons/v_knife_default_ct.mdl", "models/weapons/w_knife_default_ct.mdl"},
	{"59", "Default T", "models/weapons/v_knife_default_t.mdl", "models/weapons/w_knife_default_t.mdl"},
	{"500", "Bayonet Knife", "models/weapons/v_knife_bayonet.mdl", "models/weapons/w_knife_bayonet.mdl"},
	{"505", "Flip Knife", "models/weapons/v_knife_flip.mdl", "models/weapons/w_knife_flip.mdl"},
	{"506", "Gut Knife", "models/weapons/v_knife_gut.mdl", "models/weapons/w_knife_gut.mdl"},
	{"507", "Karambit Knife", "models/weapons/v_knife_karam.mdl", "models/weapons/w_knife_karam.mdl"},
	{"508", "M9 Bayonet Knife", "models/weapons/v_knife_m9_bay.mdl", "models/weapons/w_knife_m9_bay.mdl"},
	{"509", "Huntsman Knife", "models/weapons/v_knife_tactical.mdl", "models/weapons/w_knife_tactical.mdl"},
	{"512", "Falchion Knife", "models/weapons/v_knife_falchion_advanced.mdl", "models/weapons/w_knife_falchion_advanced.mdl"},
	{"514", "Bowie Knife", "models/weapons/v_knife_survival_bowie.mdl", "models/weapons/w_knife_survival_bowie.mdl"},
	{"515", "Butterfly Knife", "models/weapons/v_knife_butterfly.mdl", "models/weapons/w_knife_butterfly.mdl"},
	{"516", "Shaddow Daggers", "models/weapons/v_knife_push.mdl", "models/weapons/w_knife_push.mdl"},
};

int gI_KnifeIndexes[12][2];

public Plugin myinfo =
{
    name = "CS:GO GiveNamedItem Hook Franug Edition",
    author = "Franc1sco franug and Neuro Toxin",
    description = "Hook for GiveNamedItem to allow other plugins to force classnames and paintkits",
    version = DATA
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("givenameditem");
	CreateNatives();
	return APLRes_Success;
}

public void OnPluginStart()
{
	RegisterCommands();
	BuildItems();
	RegisterConvars();
	g_hOnGiveNamedItemFoward = CreateGlobalForward("OnGiveNamedItemEx", ET_Ignore, Param_Cell, Param_String);
}

public void OnMapStart() {
	for (int i = 0; i < sizeof(gC_Knives); i++) {
		for (int x = 0; x < 2; x++) {
			gI_KnifeIndexes[i][x] = PrecacheModel(gC_Knives[i][2+x]);
		}
	}
}

public void OnClientPutInServer(int client)
{	
	HookPlayer(client);
}

public void OnConfigsExecuted()
{
	for (int client = 1; client < MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		OnClientPutInServer(client);
	}
}

stock void HookPlayer(int client)
{
	SDKHook(client, SDKHook_WeaponEquip, OnWeaponEquip);
}

stock void UnhookPlayer(int client)
{
	SDKUnHook(client, SDKHook_WeaponEquip, OnWeaponEquip);
}

public Action AddItemTimer(Handle timer, any ph)
{  
	int client, item, definitionindex;
	
	ResetPack(ph);
	
	client = EntRefToEntIndex(ReadPackCell(ph));
	item = EntRefToEntIndex(ReadPackCell(ph));
	definitionindex = ReadPackCell(ph);
	
	if (client != INVALID_ENT_REFERENCE && item != INVALID_ENT_REFERENCE)
	{
		GiveNamedItem_GiveKnife(client, definitionindex);
	}
}

public Action OnWeaponEquip(int client, int entity)
{
	
	if(entity < 1 || !IsValidEdict(entity) || !IsValidEntity(entity)) return;
	
	if (GetEntProp(entity, Prop_Send, "m_hPrevOwner") > 0)
		return;
		
	new itemdefinition = GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex");
	char classname[64];
	if(!g_hServerHook.GetClassnameByItemDefinition(itemdefinition, classname, sizeof(classname))) return;
	
	// Call GiveNamedItemEx forward
	Call_StartForward(g_hOnGiveNamedItemFoward);
	Call_PushCell(client);
	Call_PushString(classname);
	
	// Do nothing if the forward fails
	if (Call_Finish() != SP_ERROR_NONE)
	{
		g_hServerHook.Reset(client);
		return;
	}
	
	if(!g_hServerHook.InUse && g_hServerHook.IsItemDefinitionKnife(itemdefinition))
	{
		if(g_hServerHook.ItemDefinition < 1)
		{
			g_hServerHook.Reset(client);
			return;
		}
		
		SetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex", g_hServerHook.ItemDefinition);
		RequestFrame(Request_Knife, EntIndexToEntRef(entity));
	}
	
	if (cvar_print_debugmsgs)
	{
		PrintToConsole(client, "----====> OnGiveNamedItemPost(entity=%d, classname=%s)", entity, classname);
	}
	
	if(g_hServerHook.Paintkit == INVALID_PAINTKIT)
	{
		g_hServerHook.Reset(client);
		return;
	}
	
	// This is the magic peice
	SetEntProp(entity, Prop_Send, "m_iItemIDLow", -1);
	SetEntProp(entity, Prop_Send, "m_iAccountID", GetEntProp(entity, Prop_Send, "m_OriginalOwnerXuidLow"));
	
	// Some more special attention around vanilla paintkits
	if (g_hServerHook.Paintkit == PAINTKIT_VANILLA)
	{
		//if (!g_hServerHook.TeamSwitch)
		//	SetEntProp(entity, Prop_Send, "m_nFallbackPaintKit", g_hServerHook.Paintkit);
			
		/*if (g_hServerHook.EntityQuality == -1)
			g_hServerHook.EntityQuality = 1;*/
	}
	
	// Set fallback paintkit if the paintkit isnt vanilla
	else{
		//PrintToChat(client, "hecho pintura numero %i ", g_hServerHook.Paintkit);
		SetEntProp(entity, Prop_Send, "m_nFallbackPaintKit", g_hServerHook.Paintkit);
	}
	// Set wear and seed if required
	if (g_hServerHook.Paintkit != PAINTKIT_PLAYERS)
	{
		SetEntProp(entity, Prop_Send, "m_nFallbackSeed", g_hServerHook.Seed);
		SetEntPropFloat(entity, Prop_Send, "m_flFallbackWear", g_hServerHook.Wear);
	}
	
	// Special treatment for stattrak items
	if (g_hServerHook.Kills > -1)
	{
		SetEntProp(entity, Prop_Send, "m_nFallbackStatTrak", g_hServerHook.Kills);
		
		if (g_hServerHook.EntityQuality == -1)
			g_hServerHook.EntityQuality = 1;
			
		if (g_hServerHook.AccountID == 0)
			g_hServerHook.AccountID = GetSteamAccountID(g_hServerHook.Client);
	}
	
	// The last few things
	if (g_hServerHook.EntityQuality > -1)
		SetEntProp(entity, Prop_Send, "m_iEntityQuality", g_hServerHook.EntityQuality);
		
	if (g_hServerHook.AccountID > 0)
		SetEntProp(entity, Prop_Send, "m_iAccountID", g_hServerHook.AccountID);
	
	if (cvar_print_debugmsgs)
	{
		PrintToConsole(client, "-----=====> SETPAINTKIT(Paintkit=%d, Seed=%d, Wear=%f, Kills=%d, EntityQuality=%d)",
								g_hServerHook.Paintkit, g_hServerHook.Seed, g_hServerHook.Wear, g_hServerHook.Kills, g_hServerHook.EntityQuality);
	}
	
	
	g_hServerHook.Reset(client);
	
}

public void Request_Knife(int I_Weaponref) {
	
	int I_Weapon = EntRefToEntIndex(I_Weaponref);
	
	if (I_Weapon == INVALID_ENT_REFERENCE)return;
	if (!IsValidEntity(I_Weapon))return;
	
	
	int I_KnifeIndex, I_WorldIndex, I_ItemDefinition;

	I_ItemDefinition = GetEntProp(I_Weapon, Prop_Send, "m_iItemDefinitionIndex");
	I_WorldIndex = GetEntPropEnt(I_Weapon, Prop_Send, "m_hWeaponWorldModel");

	for (int i = 0; i < sizeof(gC_Knives); i++) {
		if (I_ItemDefinition == StringToInt(gC_Knives[i][0])) {
			I_KnifeIndex = i;
			break;
		}
	}

	if (IsValidEdict(I_WorldIndex)) {
		
		SetEntProp(I_WorldIndex, Prop_Send, "m_nModelIndex", gI_KnifeIndexes[I_KnifeIndex][1]);
	}
}

/*
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

Restore(client, weapon)
{
	char Classname[64];
	GetEdictClassname(weapon, Classname, 64);
	
	new weaponindex = GetEntProp(windex, Prop_Send, "m_iItemDefinitionIndex");
	switch (weaponindex)
	{
					case 60: strcopy(Classname, 64, "weapon_m4a1_silencer");
					case 61: strcopy(Classname, 64, "weapon_usp_silencer");
					case 63: strcopy(Classname, 64, "weapon_cz75a");
					case 500: strcopy(Classname, 64, "weapon_bayonet");
					case 506: strcopy(Classname, 64, "weapon_knife_gut");
					case 505: strcopy(Classname, 64, "weapon_knife_flip");
					case 508: strcopy(Classname, 64, "weapon_knife_m9_bayonet");
					case 507: strcopy(Classname, 64, "weapon_knife_karambit");
					case 509: strcopy(Classname, 64, "weapon_knife_tactical");
					case 515: strcopy(Classname, 64, "weapon_knife_butterfly");
					case 512: strcopy(Classname, 64, "weapon_knife_falchion");
					case 516: strcopy(Classname, 64, "weapon_knife_push");
					case 64: strcopy(Classname, 64, "weapon_revolver");
					case 514: strcopy(Classname, 64, "weapon_knife_survival_bowie");
	}
	
	new bool:knife = false;
	if(StrContains(Classname, "weapon_knife", false) == 0 || StrContains(Classname, "weapon_bayonet", false) == 0) 
	{
		knife = true;
	}
	
	
	//PrintToChat(client, "weapon %s", Classname);
	new ammo, clip;
	if(!knife)
	{
		ammo = GetReserveAmmo(windex);
		clip = GetEntProp(windex, Prop_Send, "m_iClip1");
	}
	RemovePlayerItem(client, windex);
	AcceptEntityInput(windex, "Kill");
	
	new entity;
	if(knife && !StrEqual(g_knife[client][classname], "none")) entity = GivePlayerItem(g_iFakeClient, g_knife[client][classname]);
	else GivePlayerItem(client, "weapon_knife");
	
	
	
	if(knife && !StrEqual(g_knife[client][classname], "none"))
	{
		EquipPlayerWeapon(client, entity);
	}
	else
	{
		SetReserveAmmo(entity, ammo);
		SetEntProp(entity, Prop_Send, "m_iClip1", clip);
	}
}*/