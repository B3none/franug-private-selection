Handle g_hWeaponClassname = null;
Handle g_hWeaponItemDefinition = null;
Handle g_hWeaponIsKnife = null;
Handle g_hWeaponTeam = null;

stock bool BuildItems()
{
	Handle kv = CreateKeyValues("items_game");
	if (!FileToKeyValues(kv, "scripts/items/items_game.txt"))
	{
		LogError("Unable to open/read file at 'scripts/items/items_game.txt'.");
		return false;
	}
	
	if (!KvJumpToKey(kv, "prefabs"))
		return false;
	
	if (!KvGotoFirstSubKey(kv, false))
		return false;
	
	g_hWeaponClassname = CreateArray(128);
	g_hWeaponItemDefinition = CreateArray();
	g_hWeaponIsKnife = CreateArray();
	g_hWeaponTeam = CreateArray();
	
	// Loop through all prefabs
	char buffer[128];
	char classname[128];
	int len;
	do
	{
		// Get prefab value and check for weapon_base
		KvGetString(kv, "prefab", buffer, sizeof(buffer));
		if (StrEqual(buffer, "weapon_base") || StrEqual(buffer, "primary") || StrEqual(buffer, "melee"))
		{
			// Get weapon type data
			/*KvGetSectionName(kv, weapontypename, sizeof(weapontypename));
			
			// Reset description for melee_unusual
			if (StrEqual(weapontypename, "melee_unusual"))
				weapontypedescription = "#CSGO_Type_Knife";
			else
				KvGetString(kv, "item_type_name", weapontypedescription, sizeof(weapontypedescription));
			GetCsgoPhrase(weapontypedescription, weapontypedescription, sizeof(weapontypedescription));
			
			// Store weapon type data
			PushArrayString(g_hWeaponTypeNames, weapontypename);
			PushArrayString(g_hWeaponTypeDescriptions, weapontypedescription);*/
		}
		else
		{
			// Get the section name and check if its a weapon
			KvGetSectionName(kv, buffer, sizeof(buffer));
			if (StrContains(buffer, "weapon_") == 0)
			{
				// Remove _prefab to get the classname
				len = StrContains(buffer, "_prefab");
				if (len == -1) continue;
				strcopy(classname, len+1, buffer);
				
				// Get weapon data
				/*KvGetString(kv, "item_name", weapondescription, sizeof(weapondescription));
				GetCsgoPhrase(weapondescription, weapondescription, sizeof(weapondescription));*/

				// Check if the prefab links to a previous base type
				/*KvGetString(kv, "prefab", weapontypename, sizeof(weapontypename));
				if (!GetWeaponTypeDescriptionByTypename(weapontypename, weapontypedescription, sizeof(weapontypedescription)))
				{
					len = StrContains(buffer, "_prefab");
					if (len > -1)
						strcopy(buffer, len+1, weapontypename);
					
					if (GetWeaponTypeByClassname(buffer, buffer, sizeof(buffer)))
					{
						strcopy(weapontypename, sizeof(weapontypename), buffer);
					}
				}*/
				
				// Store data
				PushArrayString(g_hWeaponClassname, classname);
				PushArrayCell(g_hWeaponItemDefinition, -1);
				PushArrayCell(g_hWeaponIsKnife, 0);
				
				if (!KvJumpToKey(kv, "used_by_classes"))
				{
					PushArrayCell(g_hWeaponTeam, CS_TEAM_NONE);
					continue;
				}
				
				int team_ct = KvGetNum(kv, "counter-terrorists");
				int team_t = KvGetNum(kv, "terrorists");
				
				if (team_ct)
				{
					if (team_t)
						PushArrayCell(g_hWeaponTeam, CS_TEAM_NONE);
					else
						PushArrayCell(g_hWeaponTeam, CS_TEAM_CT);
				}
				else if (team_t)
					PushArrayCell(g_hWeaponTeam, CS_TEAM_T);
				else
					PushArrayCell(g_hWeaponTeam, CS_TEAM_NONE);
					
				KvGoBack(kv);
			}
		}
	} while (KvGotoNextKey(kv));
	
	KvGoBack(kv);
	KvGoBack(kv);
	
	if (!KvJumpToKey(kv, "items"))
		return false;
	
	if (!KvGotoFirstSubKey(kv, false))
		return false;

	char weapondefinition[12]; char weaponclassname[128]; char weaponprefab[128];
	do
	{
		KvGetString(kv, "name", weaponclassname, sizeof(weaponclassname));
		int index = GetWeaponIndexOfClassname(weaponclassname);
		
		// This item was not listed in the prefabs
		if (index == -1)
		{
			KvGetString(kv, "prefab", weaponprefab, sizeof(weaponprefab));
			
			if (!StrEqual(weaponprefab, "melee") && !StrEqual(weaponprefab, "melee_unusual"))
				continue;
			
			// Get weapon data
			KvGetSectionName(kv, weapondefinition, sizeof(weapondefinition));
			/*KvGetString(kv, "item_name", weapondescription, sizeof(weapondescription));
			GetCsgoPhrase(weapondescription, weapondescription, sizeof(weapondescription));*/
			
			// Store weapon data
			PushArrayString(g_hWeaponClassname, weaponclassname);
			PushArrayCell(g_hWeaponItemDefinition, StringToInt(weapondefinition));
			PushArrayCell(g_hWeaponIsKnife, 1);
			PushArrayCell(g_hWeaponTeam, CS_TEAM_NONE);
		}
		
		// This item was found in prefabs. We just need to store the weapon index
		else
		{
			// Get weapon data
			KvGetSectionName(kv, weapondefinition, sizeof(weapondefinition));
			
			// Set weapon data
			SetArrayCell(g_hWeaponItemDefinition, index, StringToInt(weapondefinition));
		}
	
	} while (KvGotoNextKey(kv));

	return true;
}

// Returns the array index for position in g_hWeaponClassnames
stock int GetWeaponIndexOfClassname(const char[] classname)
{
	int count = GetArraySize(g_hWeaponClassname);
	char buffer[128];
	for (int i = 0; i < count; i++)
	{
		GetArrayString(g_hWeaponClassname, i, buffer, sizeof(buffer));
		if (StrEqual(buffer, classname))
			return i;
	}
	return -1;
}