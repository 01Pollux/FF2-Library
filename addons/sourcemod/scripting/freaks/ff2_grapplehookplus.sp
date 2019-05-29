#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <tf2>
#include <tf2items>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

#define PLUGIN_VERSION "1.0.3"

#define IN_ATTACK		(1 << 0)
#define IN_JUMP			(1 << 1)
#define IN_DUCK			(1 << 2)
#define IN_FORWARD		(1 << 3)
#define IN_BACK			(1 << 4)
#define IN_USE			(1 << 5)
#define IN_CANCEL		(1 << 6)
#define IN_LEFT			(1 << 7)
#define IN_RIGHT		(1 << 8)
#define IN_MOVELEFT		(1 << 9)
#define IN_MOVERIGHT		(1 << 10)
#define IN_ATTACK2		(1 << 11)
#define IN_RUN			(1 << 12)
#define IN_RELOAD		(1 << 13)
#define IN_ALT1			(1 << 14)
#define IN_ALT2			(1 << 15)
#define IN_SCORE		(1 << 16)   	/**< Used by client.dll for when scoreboard is held down */
#define IN_SPEED		(1 << 17)	/**< Player is holding the speed key */
#define IN_WALK			(1 << 18)	/**< Player holding walk key */
#define IN_ZOOM			(1 << 19)	/**< Zoom key for HUD zoom */
#define IN_WEAPON1		(1 << 20)	/**< weapon defines these bits */
#define IN_WEAPON2		(1 << 21)	/**< weapon defines these bits */
#define IN_BULLRUSH		(1 << 22)
#define IN_GRENADE1		(1 << 23)	/**< grenade 1 */
#define IN_GRENADE2		(1 << 24)	/**< grenade 2 */
#define IN_ATTACK3		(1 << 25)
#define MAX_BUTTONS 26

new Handle:OnHaleRage=INVALID_HANDLE;

new HookRef[MAXPLAYERS+1];
new Float:HookDelaySwing[MAXPLAYERS+1];
new bool:WasUsingHook[MAXPLAYERS+1];
new bool:HookAbilityActive[MAXPLAYERS+1];
new Float:GrappleTimer[MAXPLAYERS+1];
new Float:CoolTimer[MAXPLAYERS+1];
new Float:CoolMarker[MAXPLAYERS+1];

new bool:ActiveRound=false;

new Handle:AbilityHUD;

public Plugin:myinfo=
{
	name="Freak Fortress 2: Grapple Hook Plus",
	author="kking117",
	description="Just some stuff to help balance grapple hook bosses.",
	version=PLUGIN_VERSION,
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	OnHaleRage=CreateGlobalForward("VSH_OnDoRage", ET_Hook, Param_FloatByRef);
	return APLRes_Success;
}

public OnPluginStart2()
{
	HookEvent("arena_round_start", OnRoundStart, EventHookMode_PostNoCopy);
	HookEvent("arena_win_panel", OnRoundEnd, EventHookMode_PostNoCopy);
	AbilityHUD=CreateHudSynchronizer();
	for(new client=1; client<=MaxClients; client++)
	{
	    if(IsValidClient(client))
		{
		    SDKUnhook(client, SDKHook_WeaponCanSwitchTo, Hook_WeaponCanSwitch); 
			SDKHook(client, SDKHook_WeaponCanSwitchTo, Hook_WeaponCanSwitch); 
			SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
			SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		}
	}
}

public OnClientPutInServer(client) 
{ 
    SDKHook(client, SDKHook_WeaponCanSwitchTo, Hook_WeaponCanSwitch);
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:ClientTimer(Handle:timer)
{
    if(!ActiveRound)
	{
	    return Plugin_Stop;
	}
	else
	{
		for(new client=1; client<=MaxClients; client++)
		{
			if(IsValidClient(client))
			{
				if(IsPlayerAlive(client))
				{
				    if(FF2_GetBossIndex(client)>-1)
					{
					    new boss = FF2_GetBossIndex(client);
						if(FF2_HasAbility(boss, this_plugin_name, "hook_ability"))
						{
						    new Float:vert = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "hook_ability", 11, 0.0);
							new Float:cooltime = CoolTimer[client]+0.1;
							new String:HudMsg[255];
							if(FF2_GetAbilityArgument(boss, this_plugin_name, "hook_ability", 10, 0) == 1)
							{
							    cooltime = ((GetGameTime()-CoolMarker[client])/(cooltime-CoolMarker[client]))*100.0;
							}
							else
							{
							    cooltime -= GetGameTime();
							}
							if(TF2_IsPlayerInCondition(client, TFCond_GrapplingHook) || TF2_IsPlayerInCondition(client, TFCond_GrapplingHookLatched))
							{
								if(!HasEquipmentByClassName(client, "tf_weapon_grapplinghook"))
								{
								    UnloadHook(client);
								}
							}
							if(CoolTimer[client]<=GetGameTime() && CoolTimer[client]>=0.0)
							{
							    FF2_GetAbilityArgumentString(boss, this_plugin_name, "hook_ability", 13, HudMsg, 255);
								ReplaceString(HudMsg, 255, "\\n", "\n");
								SetHudTextParams(-1.0, vert, 0.35, 255, 64, 64, 255, 0, 0.2, 0.0, 0.1);
								ShowSyncHudText(client, AbilityHUD, HudMsg);
							}
							else
							{
							    FF2_GetAbilityArgumentString(boss, this_plugin_name, "hook_ability", 12, HudMsg, 255);
								ReplaceString(HudMsg, 255, "\\n", "\n");
								if(CoolTimer[client]==-1.0)
								{
									SetHudTextParams(-1.0, vert, 0.35, 255, 255, 255, 255, 0, 0.2, 0.0, 0.1);
									ShowSyncHudText(client, AbilityHUD, HudMsg, 0.0);
								}
								else
								{
									SetHudTextParams(-1.0, vert, 0.35, 255, 255, 255, 255, 0, 0.2, 0.0, 0.1);
									ShowSyncHudText(client, AbilityHUD, HudMsg, cooltime);
								}
							}
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action:OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    for(new client=1; client<=MaxClients; client++)
	{
	    if(IsValidClient(client))
		{
		    HookDelaySwing[client]=0.0;
			WasUsingHook[client]=false;
		    UnloadHook(client);
			if(FF2_GetBossIndex(client)>-1)
			{
			    new boss = FF2_GetBossIndex(client);
			    if(FF2_HasAbility(boss, this_plugin_name, "hook_ability"))
				{
					CoolTimer[client]=GetGameTime()+FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "hook_ability", 2, 1.0);
					CoolMarker[client]=GetGameTime();
				}
			}
		}
	}
    ActiveRound=true;
	CreateTimer(0.2, ClientTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action:OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
    ActiveRound=false;
	for(new client=1; client<=MaxClients; client++)
	{
	    if(IsValidClient(client))
		{
		    UnloadHook(client);
		}
	}
}

public Action:FF2_OnAbility2(boss, const String:plugin_name[], const String:ability_name[], status)
{
	new slot=FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, 0);
	new client=GetClientOfUserId(FF2_GetBossUserId(boss));
	if(!strcmp(ability_name, "hookstyle"))
	{
	}
}

public OnEntityCreated(entity, const String:classname[])
{
    if(FF2_IsFF2Enabled())
	{
		if(StrEqual("tf_projectile_grapplinghook", classname))
		{
			CreateTimer(0.1, CheckProjectile, EntIndexToEntRef(entity));
			SDKHook(entity, SDKHook_StartTouch, OnStartTouchHooks);
		}
	}
}

public Action:OnTakeDamage(client, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	if(IsValidClient(attacker) && attacker!=client && FF2_GetBossIndex(attacker)>-1)
	{
	    if(IsValidEntity(weapon))
		{
			new String:WeaponName[64];
			GetEntityClassname(weapon, WeaponName, sizeof(WeaponName)); 
			if(StrEqual("tf_weapon_grapplinghook", WeaponName))
			{
				new boss = FF2_GetBossIndex(attacker);
				if(FF2_HasAbility(boss, this_plugin_name, "hookstyle"))
				{
					if(FF2_GetAbilityArgument(boss, this_plugin_name, "hookstyle", 2, 0) == 0) //we don't need to unhook if it doesn't even latch onto the player
					{
						new Float:killhooktime = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "hookstyle", 7, 0.0);
						if(killhooktime>0.0)
						{
							CreateTimer(killhooktime, KillHook, HookRef[attacker]);
						}
					}
					if(FF2_GetAbilityArgument(boss, this_plugin_name, "hookstyle", 1, 0) == 1)
					{
						CreateTimer(0.12, CheckHook, attacker);
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action:CheckProjectile(Handle:timer, any:entity1)
{
    new entity = EntRefToEntIndex(entity1);
	if(IsValidEntity(entity))
	{
	    new bool:DoneHere = false;
		new howner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
		new curlauncher = GetEntPropEnt(entity, Prop_Send, "m_hLauncher");
		new hownerclient;
		new curlauncherclient;
		if(IsValidEntity(howner) && !IsValidClient(howner))
		{
			hownerclient = GetEntPropEnt(howner, Prop_Send, "m_hOwnerEntity");
			if(IsValidClient(hownerclient))
			{
				DoneHere=true;
				HookRef[hownerclient]=entity1;
			}
		}
		if(!DoneHere && IsValidEntity(curlauncher) && !IsValidClient(curlauncher))
		{
			curlauncherclient = GetEntPropEnt(curlauncher, Prop_Send, "m_hOwnerEntity");
			if(IsValidClient(curlauncherclient))
			{
				HookRef[curlauncherclient]=entity1;
			}
		}
	}
}

public Action:OnStartTouchHooks(entity, other)
{
    if(IsValidEntity(entity))
	{
		new projowner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
		if(IsValidEntity(projowner) && !IsValidClient(projowner)) //is actually the launcher or some other entity
		{
			projowner = GetEntPropEnt(projowner, Prop_Send, "m_hOwnerEntity"); //the actual owner
		}
		new attacker = projowner;
		if(IsValidClient(attacker) && FF2_GetBossIndex(attacker)>-1)
		{
		    new boss = FF2_GetBossIndex(attacker);
			if(FF2_HasAbility(boss, this_plugin_name, "hookstyle"))
			{
				if(IsValidClient(other) && GetClientTeam(other)!=GetEntProp(entity, Prop_Send, "m_iTeamNum"))
				{
					if(FF2_GetAbilityArgument(boss, this_plugin_name, "hookstyle", 2, 0) != 1)
					{
						new Float:killhooktime = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "hookstyle", 7, 0.0);
						if(killhooktime>0.0)
						{
							CreateTimer(killhooktime, KillHook, HookRef[attacker]);
						}
					}
					else
					{
						new client = other;
						new dmgtype;
						dmgtype = DMG_SLASH;
						if(GetEntProp(entity, Prop_Send, "m_bCritical")==1)
						{
							dmgtype |= DMG_ACID;
						}
						new Float:dmg = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "hookstyle", 4, 0.0);
						if(dmg<=160.0 && FF2_GetAbilityArgument(boss, this_plugin_name, "hookstyle", 8, 0) != 0)
						{
							dmg=dmg/3.0;
						}
						DamageEntity(client, attacker, dmg, dmgtype, "");
						SDKHook(entity, SDKHook_Touch, OnTouch);
					}
				}
				else if(IsValidEntity(other))
				{
				    CreateTimer(0.12, CheckHook, attacker);
					if(FF2_GetAbilityArgument(boss, this_plugin_name, "hookstyle", 3, 0) == 1)
					{
						new String:classname[32];
						//buildings
						GetEdictClassname(other, classname, sizeof(classname));
						new bool:HurtableEnt=false;
						if(StrContains(classname, "obj_", false) != -1)
						{
							HurtableEnt=true;
						}
						else if(StrContains(classname, "_boss", false) != -1)
						{
							HurtableEnt=true;
						}
						else if(StrEqual(classname, "merasmus", false))
						{
							HurtableEnt=true;
						}
						else if(StrEqual(classname, "headless_hatman", false))
						{
							HurtableEnt=true;
						}
						if(HurtableEnt)
						{
							new dmgtype;
							dmgtype = DMG_SLASH;
							if(GetEntProp(entity, Prop_Send, "m_bCritical")==1)
							{
								dmgtype |= DMG_ACID;
							}
							new Float:dmg = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "hookstyle", 5, 0.0);
							DamageEntity(other, attacker, dmg, dmgtype, "");
							SDKHook(entity, SDKHook_Touch, OnTouch);
						}
					}
				}
			}
		}
	}
}

public Action:OnTouch(entity, other)
{
	SDKUnhook(entity, SDKHook_Touch, OnTouch);
	AcceptEntityInput(entity, "Kill");
	return Plugin_Handled;
}

public Action:KillHook(Handle:Timer, entityref)
{
	new entity = EntRefToEntIndex(entityref);
	if(IsValidEntity(entity))
	{
	    new String:classname[64];
		GetEntityClassname(entity, classname, sizeof(classname));
		if(StrEqual(classname, "tf_projectile_grapplinghook", false))
		{
			RemoveEdict(entity);
		}
	}
	return Plugin_Continue;
}

public Action:CheckHook(Handle:Timer, client)
{
	if(IsValidClient(client))
	{
	    if(TF2_IsPlayerInCondition(client, TFCond_GrapplingHook) || TF2_IsPlayerInCondition(client, TFCond_GrapplingHookLatched))
		{
			new activewep = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
			new String:entname[50];
			GetEntityClassname(activewep, entname, sizeof(entname));
			if(!StrEqual(entname, "tf_weapon_grapplinghook", false))
			{
			    UnloadHook(client);
			}
		}
	}
	return Plugin_Continue;
}

public Action:Hook_WeaponCanSwitch(client, weapon) 
{
    if(IsValidEntity(weapon))
	{
	    if(FF2_GetBossIndex(client)>-1)
		{
		    new boss = FF2_GetBossIndex(client);
			new String:WeaponName[64];
			GetEntityClassname(weapon, WeaponName, sizeof(WeaponName));
			if(!StrEqual("tf_weapon_grapplinghook", WeaponName))
			{
				if(FF2_HasAbility(boss, this_plugin_name, "hook_ability") && HookAbilityActive[client])
				{
				    if(FF2_GetAbilityArgument(boss, this_plugin_name, "hook_ability", 5, 0) != 1)
					{
					    return Plugin_Stop;
					}
				}
				if(FF2_HasAbility(boss, this_plugin_name, "hookstyle"))
				{
				    if(TF2_IsPlayerInCondition(client, TFCond_GrapplingHook) || TF2_IsPlayerInCondition(client, TFCond_GrapplingHookLatched))
					{
						new Float:delaytime = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "hookstyle", 6, 0.0);
						if(delaytime>0.0)
						{
							HookDelaySwing[client] = GetGameTime()+delaytime;
							
						}
						else
						{
							HookDelaySwing[client] = 0.0;
						}
						if(FF2_GetAbilityArgument(boss, this_plugin_name, "hookstyle", 1, 0)==1)
						{
						    UnloadHook(client);
						}
					}
					if(HookDelaySwing[client]>GetGameTime())
					{
						SetEntPropFloat(weapon, Prop_Data, "m_flNextPrimaryAttack", HookDelaySwing[client]);
					}
				}
			}
			else
			{
				if(FF2_HasAbility(boss, this_plugin_name, "hook_ability") && HookAbilityActive[client])
				{
					if(GrappleTimer[client]-0.25<=GetGameTime())
					{
					    return Plugin_Stop;
					}
				}
			}
		}
	}
    return Plugin_Continue;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
    if(IsValidClient(client))
	{
		if(IsPlayerAlive(client))
		{
		    new weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
		    if(FF2_GetBossIndex(client)>-1)
			{
			    new boss = FF2_GetBossIndex(client);
				if(FF2_HasAbility(boss, this_plugin_name, "hookstyle"))
				{
					if(TF2_IsPlayerInCondition(client, TFCond_GrapplingHook) || TF2_IsPlayerInCondition(client, TFCond_GrapplingHookLatched))
					{
						WasUsingHook[client]=true;
					}
					else if(!TF2_IsPlayerInCondition(client, TFCond_GrapplingHook) && !TF2_IsPlayerInCondition(client, TFCond_GrapplingHookLatched))
					{
						if(WasUsingHook[client])
						{
							new Float:delaytime = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "hookstyle", 6, 0.0);
							if(delaytime>0.0)
							{
								HookDelaySwing[client] = GetGameTime()+delaytime;
							}
							else
							{
								HookDelaySwing[client] = 0.0;
							}
						}
						WasUsingHook[client]=false;
					}
				}
				if(ActiveRound)
				{
					if(FF2_HasAbility(boss, this_plugin_name, "hook_ability"))
					{
						if(!HookAbilityActive[client] && CoolTimer[client]<=GetGameTime())
						{
							if(FF2_GetAbilityArgument(boss, this_plugin_name, "hook_ability", 1, 0) == 0 && (buttons & IN_ATTACK2))
							{
								InitiateHookAbility(client);
							}
							else if(FF2_GetAbilityArgument(boss, this_plugin_name, "hook_ability", 1, 0) == 1 && (buttons & IN_ATTACK3))
							{
								InitiateHookAbility(client);
							}
							else if(FF2_GetAbilityArgument(boss, this_plugin_name, "hook_ability", 1, 0) == 2 && (buttons & IN_RELOAD))
							{
								InitiateHookAbility(client);
							}
						}
						else if(HookAbilityActive[client])
						{
						    new bool:keepattacking = true;
						    if(GrappleTimer[client]-0.25<=GetGameTime())
							{
								if(FF2_GetAbilityArgument(boss, this_plugin_name, "hook_ability", 4, 0)==1 && TF2_IsPlayerInCondition(client, TFCond_GrapplingHook) && TF2_IsPlayerInCondition(client, TFCond_GrapplingHookLatched))
								{
								}
								else
								{
								    keepattacking=false;
									EndHookAbility1(client);
								}
							}
							if(IsValidEntity(weapon) && keepattacking)
							{
							    if(FF2_GetAbilityArgument(boss, this_plugin_name, "hook_ability", 8, 0) == 1)
								{
									new String:classname[64];
									GetEntityClassname(weapon, classname, sizeof(classname));
									if(StrEqual(classname, "tf_weapon_grapplinghook", false))
									{
										buttons |= IN_ATTACK;
									}
								}
							}
						}
					}
				}
			}
		}
	}
	return Plugin_Changed;
}

InitiateHookAbility(client)
{
    if(IsValidClient(client))
	{
	    if(FF2_GetBossIndex(client)>-1)
		{
			new boss = FF2_GetBossIndex(client);
			new String:attribs[255];
			FF2_GetAbilityArgumentString(boss, this_plugin_name, "hook_ability", 7, attribs, 255);
			SpawnWeapon(client, "tf_weapon_grapplinghook", 1152, 1, 6, attribs);
			HookAbilityActive[client]=true;
			GrappleTimer[client] = GetGameTime()+FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "hook_ability", 3, 1.0)+0.25;
			SetEntPropEnt(client, Prop_Data, "m_hActiveWeapon", GetPlayerWeaponSlot(client, 5));
			if(FF2_GetAbilityArgument(boss, this_plugin_name, "hook_ability", 6, 1)!=1)
			{
				CoolTimer[client]=GetGameTime()+FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "hook_ability", 2, 1.0);
				CoolMarker[client]=GetGameTime();
			}
			else
			{
				CoolTimer[client]=-1.0;
				CoolMarker[client]=-1.0;
			}
		}
	}
}

EndHookAbility1(client)
{
    if(IsValidClient(client))
	{
	    if(FF2_GetBossIndex(client)>-1)
		{
		    new boss = FF2_GetBossIndex(client);
		    new activewep = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
			if(IsValidEntity(activewep))
			{
				new String:entname[50];
				GetEntityClassname(activewep, entname, sizeof(entname));
				if(StrEqual(entname, "tf_weapon_grapplinghook", false))
				{
					if(FF2_HasAbility(boss, this_plugin_name, "hookstyle"))
					{
						new Float:delaytime = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "hookstyle", 6, 0.0);
						if(delaytime>0.0)
						{
							HookDelaySwing[client] = GetGameTime()+delaytime;
						}
						else
						{
							HookDelaySwing[client] = 0.0;
						}
					}
					if(IsValidEntity(GetPlayerWeaponSlot(client, 2)))
					{
						SetEntPropEnt(client, Prop_Data, "m_hActiveWeapon", GetPlayerWeaponSlot(client, 2));
						if(FF2_HasAbility(boss, this_plugin_name, "hookstyle") && FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "hookstyle", 6, 0.0)>0.0)
						{
							SetEntPropFloat(GetPlayerWeaponSlot(client, 2), Prop_Data, "m_flNextPrimaryAttack", HookDelaySwing[client]);
						}
					}
					else if(IsValidEntity(GetPlayerWeaponSlot(client, 0)))
					{
						SetEntPropEnt(client, Prop_Data, "m_hActiveWeapon", GetPlayerWeaponSlot(client, 0));
						if(FF2_HasAbility(boss, this_plugin_name, "hookstyle") && FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "hookstyle", 6, 0.0)>0.0)
						{
							SetEntPropFloat(GetPlayerWeaponSlot(client, 0), Prop_Data, "m_flNextPrimaryAttack", HookDelaySwing[client]);
						}
					}
					else if(IsValidEntity(GetPlayerWeaponSlot(client, 1)))
					{
						SetEntPropEnt(client, Prop_Data, "m_hActiveWeapon", GetPlayerWeaponSlot(client, 1));
						if(FF2_HasAbility(boss, this_plugin_name, "hookstyle") && FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "hookstyle", 6, 0.0)>0.0)
						{
							SetEntPropFloat(GetPlayerWeaponSlot(client, 1), Prop_Data, "m_flNextPrimaryAttack", HookDelaySwing[client]);
						}
					}
				}
			}
			else
			{
				if(FF2_HasAbility(boss, this_plugin_name, "hookstyle"))
				{
					new Float:delaytime = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "hookstyle", 6, 0.0);
					if(delaytime>0.0)
					{
						HookDelaySwing[client] = GetGameTime()+delaytime;
					}
					else
					{
						HookDelaySwing[client] = 0.0;
					}
				}
				if(IsValidEntity(GetPlayerWeaponSlot(client, 2)))
				{
					SetEntPropEnt(client, Prop_Data, "m_hActiveWeapon", GetPlayerWeaponSlot(client, 2));
					if(FF2_HasAbility(boss, this_plugin_name, "hookstyle") && FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "hookstyle", 6, 0.0)>0.0)
					{
						SetEntPropFloat(GetPlayerWeaponSlot(client, 2), Prop_Data, "m_flNextPrimaryAttack", HookDelaySwing[client]);
					}
				}
				else if(IsValidEntity(GetPlayerWeaponSlot(client, 0)))
				{
					SetEntPropEnt(client, Prop_Data, "m_hActiveWeapon", GetPlayerWeaponSlot(client, 0));
					if(FF2_HasAbility(boss, this_plugin_name, "hookstyle") && FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "hookstyle", 6, 0.0)>0.0)
					{
						SetEntPropFloat(GetPlayerWeaponSlot(client, 0), Prop_Data, "m_flNextPrimaryAttack", HookDelaySwing[client]);
					}
				}
				else if(IsValidEntity(GetPlayerWeaponSlot(client, 1)))
				{
					SetEntPropEnt(client, Prop_Data, "m_hActiveWeapon", GetPlayerWeaponSlot(client, 1));
					if(FF2_HasAbility(boss, this_plugin_name, "hookstyle") && FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "hookstyle", 6, 0.0)>0.0)
					{
						SetEntPropFloat(GetPlayerWeaponSlot(client, 1), Prop_Data, "m_flNextPrimaryAttack", HookDelaySwing[client]);
					}
				}
			}
		    UnloadHook(client);
			if(FF2_GetAbilityArgument(boss, this_plugin_name, "hook_ability", 6, 0)==1)
			{
				CoolTimer[client]=GetGameTime()+FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "hook_ability", 2, 1.0);
				CoolMarker[client]=GetGameTime();
			}
			HookAbilityActive[client]=false;
			CreateTimer(0.25, EndHookAbility2, client);
		}
	}
}

public Action:EndHookAbility2(Handle:Timer, client)
{
    if(IsValidClient(client))
	{
	    new boss = FF2_GetBossIndex(client);
	    new activewep = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
		if(IsValidEntity(activewep))
		{
			new String:entname[50];
			GetEntityClassname(activewep, entname, sizeof(entname));
			if(StrEqual(entname, "tf_weapon_grapplinghook", false))
			{
				if(FF2_HasAbility(boss, this_plugin_name, "hookstyle"))
				{
					new Float:delaytime = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "hookstyle", 6, 0.0);
					if(delaytime>0.0)
					{
						HookDelaySwing[client] = GetGameTime()+delaytime;
					}
					else
					{
						HookDelaySwing[client] = 0.0;
					}
				}
				if(IsValidEntity(GetPlayerWeaponSlot(client, 2)))
				{
					SetEntPropEnt(client, Prop_Data, "m_hActiveWeapon", GetPlayerWeaponSlot(client, 2));
					if(FF2_HasAbility(boss, this_plugin_name, "hookstyle") && FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "hookstyle", 6, 0.0)>0.0)
					{
						SetEntPropFloat(GetPlayerWeaponSlot(client, 2), Prop_Data, "m_flNextPrimaryAttack", HookDelaySwing[client]);
					}
				}
				else if(IsValidEntity(GetPlayerWeaponSlot(client, 0)))
				{
					SetEntPropEnt(client, Prop_Data, "m_hActiveWeapon", GetPlayerWeaponSlot(client, 0));
					if(FF2_HasAbility(boss, this_plugin_name, "hookstyle") && FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "hookstyle", 6, 0.0)>0.0)
					{
						SetEntPropFloat(GetPlayerWeaponSlot(client, 0), Prop_Data, "m_flNextPrimaryAttack", HookDelaySwing[client]);
					}
				}
				else if(IsValidEntity(GetPlayerWeaponSlot(client, 1)))
				{
					SetEntPropEnt(client, Prop_Data, "m_hActiveWeapon", GetPlayerWeaponSlot(client, 1));
					if(FF2_HasAbility(boss, this_plugin_name, "hookstyle") && FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "hookstyle", 6, 0.0)>0.0)
					{
						SetEntPropFloat(GetPlayerWeaponSlot(client, 1), Prop_Data, "m_flNextPrimaryAttack", HookDelaySwing[client]);
					}
				}
			}
		}
		else
		{
			if(FF2_HasAbility(boss, this_plugin_name, "hookstyle"))
			{
				new Float:delaytime = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "hookstyle", 6, 0.0);
				if(delaytime>0.0)
				{
					HookDelaySwing[client] = GetGameTime()+delaytime;
				}
				else
				{
					HookDelaySwing[client] = 0.0;
				}
			}
			if(IsValidEntity(GetPlayerWeaponSlot(client, 2)))
			{
				SetEntPropEnt(client, Prop_Data, "m_hActiveWeapon", GetPlayerWeaponSlot(client, 2));
				if(FF2_HasAbility(boss, this_plugin_name, "hookstyle") && FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "hookstyle", 6, 0.0)>0.0)
				{
					SetEntPropFloat(GetPlayerWeaponSlot(client, 2), Prop_Data, "m_flNextPrimaryAttack", HookDelaySwing[client]);
				}
			}
			else if(IsValidEntity(GetPlayerWeaponSlot(client, 0)))
			{
				SetEntPropEnt(client, Prop_Data, "m_hActiveWeapon", GetPlayerWeaponSlot(client, 0));
				if(FF2_HasAbility(boss, this_plugin_name, "hookstyle") && FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "hookstyle", 6, 0.0)>0.0)
				{
					SetEntPropFloat(GetPlayerWeaponSlot(client, 0), Prop_Data, "m_flNextPrimaryAttack", HookDelaySwing[client]);
				}
			}
			else if(IsValidEntity(GetPlayerWeaponSlot(client, 1)))
			{
				SetEntPropEnt(client, Prop_Data, "m_hActiveWeapon", GetPlayerWeaponSlot(client, 1));
				if(FF2_HasAbility(boss, this_plugin_name, "hookstyle") && FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "hookstyle", 6, 0.0)>0.0)
				{
					SetEntPropFloat(GetPlayerWeaponSlot(client, 1), Prop_Data, "m_flNextPrimaryAttack", HookDelaySwing[client]);
				}
			}
		}
	    RemoveEquipmentByClassName(client, "tf_weapon_grapplinghook");
	    UnloadHook(client);
	}
}

UnloadHook(client)
{
    if(IsValidClient(client))
	{
	    new entity = EntRefToEntIndex(HookRef[client]);
		if(IsValidEntity(entity))
		{
		    new String:classname[64];
		    GetEntityClassname(entity, classname, sizeof(classname));
			if(StrEqual(classname, "tf_projectile_grapplinghook", false))
			{
				RemoveEdict(entity);
			}
		}
		TF2_RemoveCondition(client, TFCond_GrapplingHookLatched);
		TF2_RemoveCondition(client, TFCond_GrapplingHook);
		HookRef[client]=0;
	}
}

DamageEntity(client, attacker = 0, Float:dmg, dmg_type = DMG_GENERIC, String:weapon[]="")
{
	if(IsValidClient(client) || IsValidEntity(client))
	{
	    if(IsValidClient(client) && !IsFakeClient(client))
		{
		    Format(weapon, 1, ""); //point hurt will crash the server if you specify the classname against live players
		}
		new damage = RoundToNearest(dmg);
		new String:dmg_str[16];
		IntToString(damage,dmg_str,16);
		new String:dmg_type_str[32];
		IntToString(dmg_type,dmg_type_str,32);
		new pointHurt=CreateEntityByName("point_hurt");
		if(pointHurt)
		{
			DispatchKeyValue(client,"targetname","targetsname");
			DispatchKeyValue(pointHurt,"DamageTarget","targetsname");
			DispatchKeyValue(pointHurt,"Damage",dmg_str);
			DispatchKeyValue(pointHurt,"DamageType",dmg_type_str);
			if(!StrEqual(weapon,""))
			{
				DispatchKeyValue(pointHurt,"classname",weapon);
			}
			DispatchSpawn(pointHurt);
			if(IsValidEntity(attacker))
			{
			    new Float:AttackLocation[3];
		        GetEntPropVector(attacker, Prop_Send, "m_vecOrigin", AttackLocation);
				TeleportEntity(pointHurt, AttackLocation, NULL_VECTOR, NULL_VECTOR);
			}
			AcceptEntityInput(pointHurt,"Hurt",(attacker>0)?attacker:-1);
			DispatchKeyValue(pointHurt,"classname","point_hurt");
			DispatchKeyValue(client,"targetname","war3_donthurtme");
			RemoveEdict(pointHurt);
		}
	}
}

void RemoveEquipmentByClassName(client, String:classname[255])
{
    if(IsValidClient(client))
	{
	    if(StrEqual(classname, "tf_wearable_weapon", false))
		{
		    new i = -1; 
            while ((i = FindEntityByClassname(i, "tf_wearabl*")) != -1)
            { 
                if(client == GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity"))
			    {
				    if(IsValidEntity(i))
				    {
					    new index=GetEntProp(i, Prop_Send, "m_iItemDefinitionIndex");
				        switch(index)
				        {
				            case 131, 406, 1099, 1144, 133, 444, 642, 231, 57, 405, 608: //every wearable weapon
					        {
					            AcceptEntityInput(i, "Kill"); 
					        }
				        }
				    }
			    }
            }
		}
	    else
		{
		    new i = -1; 
            while ((i = FindEntityByClassname(i, classname)) != -1)
            { 
                if(client == GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity"))
			    {
				    if(IsValidEntity(i))
				    {
					    AcceptEntityInput(i, "Kill");
				    }
			    }
            }
		}
	}
}

stock bool:HasEquipmentByClassName(client, String:classname[255])
{
    if(IsValidClient(client))
	{
	    if(StrEqual(classname, "tf_wearable_weapon", false))
		{
		    new i = -1; 
            while ((i = FindEntityByClassname(i, "tf_wearabl*")) != -1)
            { 
                if(client == GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity"))
			    {
				    if(IsValidEntity(i))
				    {
					    new index=GetEntProp(i, Prop_Send, "m_iItemDefinitionIndex");
				        switch(index)
				        {
				            case 131, 406, 1099, 1144, 133, 444, 642, 231, 57, 405, 608: //every wearable weapon
					        {
					            return true;
					        }
				        }
				    }
			    }
            }
		}
	    else
		{
		    new i = -1; 
            while ((i = FindEntityByClassname(i, classname)) != -1)
            { 
                if(client == GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity"))
			    {
				    if(IsValidEntity(i))
				    {
					    return true;
				    }
			    }
            }
		}
	}
	return false;
}

stock SpawnWeapon(client, String:name[], index, level, qual, String:att[])
{
	new Handle:hWeapon=TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
	if(hWeapon==INVALID_HANDLE)
	{
		return -1;
	}

	TF2Items_SetClassname(hWeapon, name);
	TF2Items_SetItemIndex(hWeapon, index);
	TF2Items_SetLevel(hWeapon, level);
	TF2Items_SetQuality(hWeapon, qual);
	new String:atts[32][32];
	new count=ExplodeString(att, ";", atts, 32, 32);

	if(count % 2)
	{
		--count;
	}

	if(count>0)
	{
		TF2Items_SetNumAttributes(hWeapon, count/2);
		new i2;
		for(new i; i<count; i+=2)
		{
			new attrib=StringToInt(atts[i]);
			if(!attrib)
			{
				LogError("Bad weapon attribute passed: %s ; %s", atts[i], atts[i+1]);
				CloseHandle(hWeapon);
				return -1;
			}

			TF2Items_SetAttribute(hWeapon, i2, attrib, StringToFloat(atts[i+1]));
			i2++;
		}
	}
	else
	{
		TF2Items_SetNumAttributes(hWeapon, 0);
	}

	new entity=TF2Items_GiveNamedItem(client, hWeapon);
	CloseHandle(hWeapon);
	EquipPlayerWeapon(client, entity);
	return entity;
}

stock bool:IsValidClient(client, bool:replaycheck=true)
{
	if(client<=0 || client>MaxClients)
	{
		return false;
	}

	if(!IsClientInGame(client))
	{
		return false;
	}

	if(GetEntProp(client, Prop_Send, "m_bIsCoaching"))
	{
		return false;
	}

	if(replaycheck)
	{
		if(IsClientSourceTV(client) || IsClientReplay(client))
		{
			return false;
		}
	}
	return true;
}