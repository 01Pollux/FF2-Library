#define FF2_USING_AUTO_PLUGIN__OLD

#include <sdkhooks>
#include <tf2_stocks>
#include <morecolors>
#include <freak_fortress_2>
#include <dhooks>

#pragma newdecls required

public Plugin myinfo=
{
    name="Freak Fortress 2 : CSGO",
    author="Nopied, HotoCocoaco",
    description="FF2",
    version="1.1",
};

bool IsCSGO=false;
//bool PlayerRecoiled[MAXPLAYERS+1];

DynamicHook g_hFireBullet;

public void OnPluginStart2()
{
    HookEvent("arena_round_start", _OnRoundStart);
    // HookEvent("player_spawn", OnPlayerSpawn);

    Handle hConf = LoadGameConfigFile("ff2_csgo");
    if ( !hConf )	{
		SetFailState("ff2_csgo.txt gamedata failed.");
	}

    g_hFireBullet = DynamicHook.FromConf(hConf, "CTFWeaponBaseGun::FireBullet");
    if (g_hFireBullet == null)	SetFailState("Failed to create DHook for CTFWeaponBaseGun::FireBullet offset!");
}

public Action FF2_OnAbility2(int boss, const char[] plugin_name, const char[] ability_name, int status)
{
    return Plugin_Continue;
}

public Action _OnRoundStart(Handle event, const char[] name, bool dont)
{
    CheckAbility();
    return Plugin_Continue;
}

public void OnEntityCreated(int entity, const char[] classname)
{
    if ( (!StrContains(classname, "tf_weapon_smg") || !StrContains(classname, "tf_weapon_pistol") || !StrContains(classname, "tf_weapon_shotgun"))  && g_hFireBullet)
    {
        g_hFireBullet.HookEntity(Hook_Post, entity, CTFWeaponBaseGun_FireBullet);
    }
}

MRESReturn CTFWeaponBaseGun_FireBullet(int pThis)
{
    int client = GethOwnerEntity(pThis);
    if (client < 1 || client > MaxClients)
        return MRES_Ignored;

    if(IsCSGO && FF2_GetRoundState() == 1 && IsClientInGame(client) && IsPlayerAlive(client) && !IsWeaponSlotActive(client, TFWeaponSlot_Melee))
    {
        // int weapon2 = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
        FF2Player player = FF2Player(client);
        bool client_has_recoil = false;
        if (player.bIsBoss && player.HasAbility(this_plugin_name, "ff2_csgo"))
            client_has_recoil = true;

        if (player.bIsMinion)
        {
            FF2Player boss = ToFF2Player(player.hOwnerBoss);
            if (boss.Valid && boss.HasAbility(this_plugin_name, "ff2_csgo"))
                client_has_recoil = true;
        }

        if(client_has_recoil)
        {
            //PlayerRecoiled[client]=true;
            float punchAng[3];
            GetEntPropVector(client, Prop_Send, "m_vecPunchAngle", punchAng);

            //punchAng[1]+=GetRandomFloat(1.0, 5.0);
            //punchAng[2]+=GetRandomFloat(1.0, 5.0);
            //punchAng[0]+=GetRandomFloat(1.0, 3.0);
            punchAng[0]+=GetRandomFloat(-4.0, -1.0);

            SetEntPropVector(client, Prop_Send, "m_vecPunchAngle", punchAng);
        }
    }

    return MRES_Ignored;
}

void CheckAbility()
{
    IsCSGO=false;
    int client, boss;
    for(client=1; client<=MaxClients; client++)
    {
        if((boss = FF2_GetBossIndex(client)) != -1 && FF2_HasAbility(boss, this_plugin_name, "ff2_csgo"))
        {
            IsCSGO=true;
        }
    }
}

stock bool IsWeaponSlotActive(int iClient, int iSlot)
{
    int hActive = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
    int hWeapon = GetPlayerWeaponSlot(iClient, iSlot);
    return (hWeapon == hActive);
}

stock int GethOwnerEntity(int entity)
{
	return GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
}