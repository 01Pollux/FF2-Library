/*
rage_new_weapon:	arg0 - slot (def.0)
					arg1 - weapon's classname
					arg2 - weapon's index
					arg3 - weapon's attributes
					arg4 - weapon's slot (0 - primary. 1 - secondary. 2 - melee. 3 - pda. 4 - spy's watches)
					arg5 - weapon's ammo (set to 1 for clipless weapons, then set the actual ammo using clip)
					arg6 - force switch to this weapon
					arg7 - weapon's clip
*/

#define FF2_USING_AUTO_PLUGIN

#include <tf2items>
#include <tf2_stocks>
#include <freak_fortress_2>

#pragma newdecls required

#define PLUGIN_VERSION "1.10.8"

public Plugin myinfo=
{
	name="Freak Fortress 2: special_noanims V",
	author="RainBolt Dash, Wliu, HotoCocoaco",
	description="FF2: New Weapon and No Animations abilities",
	version=PLUGIN_VERSION
};

public void OnPluginStart2()
{
	
}

void FF2_OnAbility2(FF2Player player, const char[] ability_name, FF2CallType_t calltype)
{
	if(!StrContains(ability_name, "rage_new_weapon"))
	{
		Rage_New_Weapon(player, ability_name);
	}
}

void Rage_New_Weapon(FF2Player player, const char[] ability_name)
{
	int client = player.index;
	if(!client || !IsClientInGame(client) || !IsPlayerAlive(client))
	{
		return;
	}

	char classname[64], attributes[256];
	player.GetArgS(this_plugin_name, ability_name, "classname", classname, sizeof(classname));
	player.GetArgS(this_plugin_name, ability_name, "attributes", attributes, sizeof(attributes));

	int slot = player.GetArgI(this_plugin_name, ability_name, "weapon slot", 0);
	TF2_RemoveWeaponSlot(client, slot);

	int index = player.GetArgI(this_plugin_name, ability_name, "index", 0);
	int weapon = player.SpawnWeapon(classname, index, 101, 5, attributes);
	if(StrEqual(classname, "tf_weapon_builder") && index!=735)  //PDA, normal sapper
	{
		SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 0);
		SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 1);
		SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 2);
		SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 3);
	}
	else if(StrEqual(classname, "tf_weapon_sapper") || index==735)  //Sappers, normal sapper
	{
		SetEntProp(weapon, Prop_Send, "m_iObjectType", 3);
		SetEntProp(weapon, Prop_Data, "m_iSubType", 3);
		SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 0);
		SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 1);
		SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 2);
		SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 3);
	}

	if(player.GetArgI(this_plugin_name, ability_name, "force switch", 0))
	{
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
	}

	int ammo=player.GetArgI(this_plugin_name, ability_name, "ammo", 0);
	int clip=player.GetArgI(this_plugin_name, ability_name, "clip", 0);
	if(ammo || clip)
	{
		FF2_SetAmmo(client, weapon, ammo, clip);
	}
}
