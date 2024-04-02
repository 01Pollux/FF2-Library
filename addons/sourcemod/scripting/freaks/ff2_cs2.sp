#define FF2_USING_AUTO_PLUGIN

#define ABILITY_NAME "ff2_cs2_summon"

#include <freak_fortress_2>
#include <tf2attributes>
#include <sdkhooks>
#include <tf2utils>

public Plugin myinfo=
{
    name="Freak Fortress 2 : CS2",
    author="HotoCocoaco",
    description="FF2-VSH2 Only",
    version="1.0",
};

#define DEAGLE_MODEL "models/freak_fortress_2/cs2/weapons/c_deagle.mdl"
#define DEAGLE_MATERIAL "materials/freak_fortress_2/cs2/weapons/c_deagle"

#define SHIELD_MODEL "models/freak_fortress_2/cs2/weapons/c_targe.mdl"
#define SHIELD_MATERIAL_PATH "materials/freak_fortress_2/cs2/weapons/c_police_shield_"

FF2GameMode ff2_gm;
bool bNeedShield[MAXPLAYERS+1];

void OnPluginStart2()
{
	if (!FF2GameMode.GetPropAny("bTF2Attribs"))
	{
		LogError("TF2Attribute is not installed. Freak Fortress 2 : CS2 will not work.");
		return;
	}
	VSH2_Hook(OnMinionInitialized, CS2_OnMinionInitialized);
	VSH2_Hook(OnPlayerKilled, CS2_OnPlayerKilled);

	for(int i = 0; i <= MaxClients; i++)
	{
		bNeedShield[i] = false;
	}
}

public void OnPluginEnd()
{
	VSH2_Unhook(OnMinionInitialized, CS2_OnMinionInitialized);
	VSH2_Unhook(OnPlayerKilled, CS2_OnPlayerKilled);
}

public void OnMapStart()
{
	{	
		PrepareModel(DEAGLE_MODEL);
		PrepareMaterial(DEAGLE_MATERIAL);
		AddFileToDownloadsTable("materials/freak_fortress_2/cs2/weapons/c_deagle_rimmask.vtf")
	}

	{
		PrepareModel(SHIELD_MODEL);
		char s[PLATFORM_MAX_PATH];
		Format(s, sizeof(s), "%s%s", SHIELD_MATERIAL_PATH, "red");
		PrepareMaterial(s);
		Format(s, sizeof(s), "%s%s", SHIELD_MATERIAL_PATH, "blue");
		PrepareMaterial(s);
		Format(s, sizeof(s), "%s%s", SHIELD_MATERIAL_PATH, "glass");
		PrepareMaterial(s);
	}
}

void FF2_OnAbility2(const FF2Player boss, const char[] plugin_name, const char[] ability_name, FF2CallType_t calltype)
{
	if (ff2_gm.RoundState != StateRunning)
		return;
	// 首先，我们要知道是否是触发本插件的能力。
	if (!strcmp(ability_name, ABILITY_NAME))
	{
		// 是触发本插件的能力 ff2_cs2_summon
		// 不必检查插件名是否一致，因为我没有别的插件使用同样的能力名称。
		CS2_Summon(boss, plugin_name, ability_name);
	}
}

void CS2_Summon(const FF2Player boss, const char[] plugin_name, const char[] ability_name)
{
	// 首先，我们要知道这一次触发能力要召唤多少人。
	int number_to_summon = boss.GetArgI(plugin_name, ability_name, "number");
	int deads = GetDeadGuys();
	if (deads < number_to_summon)
		number_to_summon = deads;

	// 开始把死人变成小弟
	for(int i = 0; i <= number_to_summon; i++)
	{
		int target = GetRandomDeadPlayer();
		if (target != -1)
		{
			FF2Player player = FF2Player(target);
			player.ConvertToMinion(0.5);
			player.hOwnerBoss = boss;
		}
	}
}

void CS2_OnMinionInitialized(const VSH2Player minion, const VSH2Player owner)
{
	FF2Player boss = ToFF2Player(owner);
	if (boss.HasAbility(this_plugin_name, ABILITY_NAME))
	{
		int type = GetRandomInt(1, 3);
		// 小弟分为3种，1为沙鹰+防爆盾；2为smg；3为霰弹。
		switch(type)
		{
			case 1:
			{
				TF2_SetPlayerClass(minion.index, TFClass_DemoMan, _, false);
				minion.RemoveAllItems();

				// 生成饰品
				TF2_CreateAndEquipWeapon(minion.index, 306, "tf_wearable");
				TF2_CreateAndEquipWeapon(minion.index, 522, "tf_wearable");
				TF2_CreateAndEquipWeapon(minion.index, 30945, "tf_wearable");

				// 给沙鹰
				int deagle = TF2_CreateAndEquipWeapon(minion.index, 61, "tf_weapon_pistol", _, _, "51 ; 1; 4 ; 1.5; 5 ; 1.5; 112 ; 1.0");
				if (IsValidEdict(deagle))
				{
					TF2Attrib_SetFromStringValue(deagle, "set weapon model", DEAGLE_MODEL);
					TF2Attrib_SetFromStringValue(deagle, "set viewmodel arms", "models/weapons/c_models/c_engineer_arms.mdl");
					TF2Attrib_SetFromStringValue(deagle, "set viewmodel bonemerged arms", "models/weapons/c_models/c_demo_arms.mdl");
				}
				
				// 盾牌
				int shield = TF2_CreateAndEquipWeapon(minion.index, 131, "tf_wearable");
				if (IsValidEdict(shield))
				{
					TF2Attrib_SetFromStringValue(shield, "set weapon model", SHIELD_MODEL);
				}

				// 给近战
				int melee = minion.SpawnWeapon("tf_weapon_sword", 482, 2, 1, "1 ; 0.1");
				SetActiveWep(minion.index, melee);
				bNeedShield[minion.index] = true;
				SDKHook(minion.index, SDKHook_OnTakeDamageAlive, CS2_ShieldOnTakeDamageAlive);
				PrintCenterText(minion.index, "切换为近战武器可以举起防爆盾减伤");
				PrintToChat(minion.index, "切换为近战武器可以举起防爆盾减伤");
			}
			case 2:
			{
				TF2_SetPlayerClass(minion.index, TFClass_Sniper, _, false);
				minion.RemoveAllItems();

				// 饰品
				TF2_CreateAndEquipWeapon(minion.index, 31363, "tf_wearable");
				TF2_CreateAndEquipWeapon(minion.index, 981, "tf_wearable");

				// 给SMG
				minion.SpawnWeapon("tf_weapon_smg", 16, 2, 1, "112 ; 1.0; 868 ; 1; 51 ; 1");

				// 近战
				int melee = minion.SpawnWeapon("tf_weapon_club", 3, 2, 1, "");
				SetActiveWep(minion.index, melee);
			}
			case 3:
			{
				TF2_SetPlayerClass(minion.index, TFClass_Soldier, _, false);
				minion.RemoveAllItems();

				// 饰品
				TF2_CreateAndEquipWeapon(minion.index, 31113, "tf_wearable");
				TF2_CreateAndEquipWeapon(minion.index, 30522, "tf_wearable");
				TF2_CreateAndEquipWeapon(minion.index, 30339, "tf_wearable");

				// 给霰弹
				minion.SpawnWeapon("tf_weapon_shotgun", 10, 2, 1, "4 ; 1.33; 5 ; 0.66; 112 ; 1.0");

				// 给近战
				int melee = minion.SpawnWeapon("tf_weapon_shovel", 6, 2, 1, "");
				SetActiveWep(minion.index, melee);
			}
		}
	}
}

Action CS2_ShieldOnTakeDamageAlive(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (bNeedShield[victim] && IsClientInGame(attacker) && IsWeaponSlotActive(victim, TFWeaponSlot_Melee))
	{
		// 抄袭了
		// need position of either the inflictor or the attacker
		int posEntity = IsValidEntity(inflictor) ? inflictor : attacker;
		static float actualDamagePos[3];
		static float victimPos[3];
		static float angle[3];
		static float eyeAngles[3];
		GetEntPropVector(victim, Prop_Send, "m_vecOrigin", victimPos);
		GetEntPropVector(posEntity, Prop_Send, "m_vecOrigin", actualDamagePos);
		GetVectorAnglesTwoPoints(victimPos, actualDamagePos, angle);
		GetClientEyeAngles(victim, eyeAngles);

		// need the yaw offset from the player's POV, and set it up to be between (-180.0..180.0]
		float yawOffset = fixAngle(angle[1]) - fixAngle(eyeAngles[1]);
		if (yawOffset <= -180.0)
			yawOffset += 360.0;
		else if (yawOffset > 180.0)
			yawOffset -= 360.0;

		// now it's a simple check
		if (yawOffset >= -60.0 && yawOffset <= 90.0)
		{
			damage *= 0.6; // intentionally not doing partial damage cutting. entire big hits can be lost even if the shield only has 5HP.
			return Plugin_Changed;
		}
	}

	return Plugin_Continue;
}

void CS2_OnPlayerKilled(const VSH2Player player, const VSH2Player victim, Event event)
{
	if (bNeedShield[victim.index])
		bNeedShield[victim.index] = false;
}

stock int GetDeadGuys()
{
	int deadGuys = 0;
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client))
		{
			if (!IsPlayerAlive(client))
			{
				deadGuys++;
			}
		}
	}
	return deadGuys;
}

stock int GetRandomDeadPlayer()
{
	int clients[MAXPLAYERS];
	int clientCount;
	
	for(int i = 1 ; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsPlayerAlive(i) && FF2_GetBossIndex(i) == -1 && (TF2_GetClientTeam(i) == TFTeam_Red || TF2_GetClientTeam(i) == TFTeam_Blue))
		{
			clients[clientCount++] = i;
		}
	}
	return (clientCount == 0) ? -1 : clients[GetRandomInt(0, clientCount-1)];
}

stock int GetModelIndex(const char[] sModel)
{
	int iTable = FindStringTable("modelprecache");
	return FindStringIndex(iTable, sModel);
}

stock float GetVectorAnglesTwoPoints(const float startPos[3], const float endPos[3], float angles[3])
{
	static float tmpVec[3];
	MakeVectorFromPoints(startPos, endPos, tmpVec);
	GetVectorAngles(tmpVec, angles);
	return 0.0;
}

stock float fixAngle(float angle)
{
	int sanity = 0;
	while (angle < -180.0 && (sanity++) <= 10)
		angle = angle + 360.0;
	while (angle > 180.0 && (sanity++) <= 10)
		angle = angle - 360.0;

	return angle;
}

stock bool IsWeaponSlotActive(int iClient, int iSlot)
{
    int hActive = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
    int hWeapon = GetPlayerWeaponSlot(iClient, iSlot);
    return (hWeapon == hActive);
}

stock int TF2_CreateAndEquipWeapon(int iClient, int iIndex, char[] sClassnameTemp, int iLevel = 0, int iQuality = 0, char[] sAttrib = NULL_STRING, bool bAttrib = false)
{
	char sClassname[256];
	strcopy(sClassname, sizeof(sClassname), sClassnameTemp);
	
	int iWeapon = CreateEntityByName(sClassname);
	
	if (IsValidEntity(iWeapon))
	{
		SetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex", iIndex);
		SetEntProp(iWeapon, Prop_Send, "m_bInitialized", 1);
		SetEntProp(iWeapon, Prop_Send, "m_bOnlyIterateItemViewAttributes", !bAttrib);	//Whenever if weapon should have default attribs or not
		
		//Allow quality / level override by updating through the offset.
		char sNetClass[64];
		GetEntityNetClass(iWeapon, sNetClass, sizeof(sNetClass));
		SetEntData(iWeapon, FindSendPropInfo(sNetClass, "m_iEntityQuality"), iQuality);
		SetEntData(iWeapon, FindSendPropInfo(sNetClass, "m_iEntityLevel"), iLevel);
		
		SetEntProp(iWeapon, Prop_Send, "m_iEntityQuality", iQuality);
		SetEntProp(iWeapon, Prop_Send, "m_iEntityLevel", iLevel);
		
		DispatchSpawn(iWeapon);
		SetEntProp(iWeapon, Prop_Send, "m_bValidatedAttachedEntity", true);
		
		if (StrContains(sClassname, "tf_wearable") == 0)
		{
			TF2Util_EquipPlayerWearable(iClient, iWeapon);
		}
		else
		{
			EquipPlayerWeapon(iClient, iWeapon);
			
			//Make sure max ammo is set correctly
			int iAmmoType = GetEntProp(iWeapon, Prop_Send, "m_iPrimaryAmmoType");
			if (iAmmoType > -1)
			{
				TF2_SetAmmo(iClient, iAmmoType, 0);
				GivePlayerAmmo(iClient, 9999, iAmmoType, true);
			}
		}
		
		char atts[32][32];
		int count = ExplodeString(sAttrib, " ; ", atts, 32, 32);
		if (count > 1)
		{
			for (int j = 0; j < count; j+= 2)
				TF2Attrib_SetByDefIndex(iWeapon, StringToInt(atts[j]), StringToFloat(atts[j+1]));

			TF2Attrib_ClearCache(iWeapon);
		}
	}
	
	return iWeapon;
}

stock void TF2_SetAmmo(int iClient, int iAmmoType, int iAmmo)
{
	SetEntProp(iClient, Prop_Send, "m_iAmmo", iAmmo, _, iAmmoType);
}

stock void SetActiveWep(const int client, const int wep)
{
	if( wep > MaxClients && IsValidEntity(wep) )
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", wep);
}