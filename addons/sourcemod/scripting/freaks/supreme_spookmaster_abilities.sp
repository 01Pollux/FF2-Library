#define FF2_USING_AUTO_PLUGIN__OLD

#define DEBUG

#define PLUGIN_NAME           "supreme_spookmaster_abilities"
#define SPOOKMASTER			  "supreme_spookmaster_abilities"
#define PLUGIN_AUTHOR         "Spookmaster, with (some) code borrowed from various sources. edited for VSH2 by HotoCocoaco"
#define PLUGIN_DESCRIPTION    "Manages Supreme Spookmaster Bones' abilities."
#define PLUGIN_VERSION        "1.0"
#define PLUGIN_URL            ""

#define MORTIS_PARTICLE		  "utaunt_souls_green_parent"
#define RIP_PARTICLE		  "utaunt_snowring_space_parent"
#define REPO_PARTICLE		  "utaunt_souls_purple_parent"
#define SUMMONER_PARTICLE	  "hammer_souls_rising"
#define SUMMONER_PARTICLE2	  "eyeboss_doorway_vortex"
#define SUMMONER_PARTICLE3	  "utaunt_hellpit_parent"
#define CHAOS_PARTICLE		  "utaunt_arcane_green_parent"
#define NECRO_PARTICLE		  "utaunt_arcane_purple_parent"
#define EXPLOSION_EFFECT	  "hammer_bones_kickup"
#define EXPLOSION_EFFECT2	  "hammer_bell_ring_shockwave"

#define MAX_HEALTH_ATTRIB 26
#define MAX_HEALTH_PENALITY_ATTRIB 125


#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <freak_fortress_2>
#include <tf2_stocks>
//#include <var_strings>
#include <tf2attributes>

#pragma semicolon 1
#pragma tabsize 0


public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};


//Below is yet another disaster of public variables. Sorry.

int spookmaster = 0;
int spookPower = 0;
int skill = 0;
int skillCost[6]={0, ...};
int passiveRegen = 0;
int smashCount[MAXPLAYERS+1]={0, ...};
int BonerMaxHealth[MAXPLAYERS+1]={0, ...};

float skillCD[6]={0.0, ...};
float x = 0.0;
float y = 0.0;
float stanceTracker = 0.0;
float chaosTracker = 0.0;
float necroTracker = 0.0;

bool mortisActive[MAXPLAYERS+1]={false, ...};
bool isBoner[MAXPLAYERS+1]={false, ...};
bool isAlreadyHit[MAXPLAYERS+1]={false, ...};
bool KeyDown[MAXPLAYERS+1]={false, ...};
bool KeyDown2[MAXPLAYERS+1]={false, ...};
bool KeyDown3[MAXPLAYERS+1]={false, ...};
bool letItRIP = false;
bool repossession = false;
bool necroLord = false;
bool chaos = false;
bool recentDeath = false;
bool spellReady = false;
bool chaosUsed = false;
bool necroUsed = false;
bool stanceActive = false;

//char HUD_Info[512];

new playerParticle[MAXPLAYERS+1];
new stanceParticleA;
new stanceParticleB;
new stanceParticleC;

public void OnPluginStart2()
{
	HookEvent("arena_round_start", bonerStart);
}
public OnMapStart()
{
	PrecacheSound("freak_fortress_2/new_spookmaster/mortis_masher_activation.mp3", true);
	PrecacheSound("freak_fortress_2/new_spookmaster/mortis_masher_kill.mp3", true);
	PrecacheSound("freak_fortress_2/new_spookmaster/mortis_masher_freezekill.mp3", true);
	PrecacheSound("freak_fortress_2/new_spookmaster/mortis_masher_scout.mp3", true);
	PrecacheSound("freak_fortress_2/new_spookmaster/mortis_masher_demo.mp3", true);
	PrecacheSound("freak_fortress_2/new_spookmaster/mortis_masher_heavy.mp3", true);
	PrecacheSound("freak_fortress_2/new_spookmaster/mortis_masher_spy.mp3", true);
	PrecacheSound("freak_fortress_2/new_spookmaster/new_spookmaster_bonerwhirl.mp3", true);
	PrecacheSound("freak_fortress_2/new_spookmaster/repossession_start.mp3", true);
	PrecacheSound("freak_fortress_2/new_spookmaster/repossession_scream.mp3", true);
	PrecacheSound("freak_fortress_2/new_spookmaster/repossession_gibsummon.mp3", true);
	PrecacheSound("freak_fortress_2/new_spookmaster/boner_ragemode.mp3", true);
	PrecacheSound("freak_fortress_2/new_spookmaster/boner_ragemode2.mp3", true);
	PrecacheSound("freak_fortress_2/new_spookmaster/stance_intro1.mp3", true);
	PrecacheSound("freak_fortress_2/new_spookmaster/stance_intro2.mp3", true);
	PrecacheSound("freak_fortress_2/new_spookmaster/stance_summon1.mp3", true);
	PrecacheSound("freak_fortress_2/new_spookmaster/stance_summon2.mp3", true);
	PrecacheSound("freak_fortress_2/new_spookmaster/stance_summon3.mp3", true);
	PrecacheSound("freak_fortress_2/new_spookmaster/spookmaster_bgm_original.mp3", true);
	//AddFileToDownloadsTable("models/freak_fortress_2/new_spookmaster/bone_tornado.mdl");
	PrecacheModel("freak_fortress_2/new_spookmaster/bone_tornado.mdl", true);
	//AddFileToDownloadsTable("models/freak_fortress_2/new_spookmaster/boner_minion.mdl");
	PrecacheModel("freak_fortress_2/new_spookmaster/boner_minion.mdl", true);
	PrecacheModel("freak_fortress_2/new_spookmaster/jones_stance.mdl", true);
	PrecacheSound("items/cart_explode_trigger.wav", true);
	PrecacheSound("replay/record_fail.wav", true);
	PrecacheSound("items/halloween/banshee02.wav", true);
	PrecacheSound("mvm/mvm_used_powerup.wav", true);
}

public void bonerStart(Event hEvent, const char[] sEvName, bool bDontBroadcast)
{
	for(int client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client))
		{
			if (FF2_GetBossIndex(client) != -1)
			{
				if (FF2_HasAbility(FF2_GetBossIndex(client), PLUGIN_NAME, SPOOKMASTER))
				{
					spookmaster = client;
					//bossIDX = FF2_GetBossIndex(spookmaster);
					spookPower = FF2_GetArgNamedI(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg112", 0);
					
					skillCost[0] = FF2_GetArgNamedI(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg7", 0);
					skillCost[1] = FF2_GetArgNamedI(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg9", 0);
					skillCost[2] = FF2_GetArgNamedI(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg19", 0);
					skillCost[3] = FF2_GetArgNamedI(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg47", 0);
					skillCost[4] = FF2_GetArgNamedI(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg42", 0);
					skillCost[5] = FF2_GetArgNamedI(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg43", 0);
					
					passiveRegen = FF2_GetArgNamedI(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg99", 0);
					
					float waitTime = FF2_GetArgNamedF(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg102", 15.0);
					if (waitTime >= 0.0)
					{
						for (int i = 0; i < 6; i++)
						{
							skillCD[i] = waitTime;
						}
					}
					
					x = FF2_GetArgNamedF(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg103", 0.0);
					y = FF2_GetArgNamedF(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg104", 0.0);
					
					CreateTimer(0.1, spookHUD, _, TIMER_FLAG_NO_MAPCHANGE || TIMER_REPEAT);
					
					SDKHook(spookmaster, SDKHook_PreThink, spooky_preThink);
					
					HookEvent("player_death", player_killed);
					HookEvent("teamplay_round_win", bonerEnd);
					
					KeyDown[client] = (GetClientButtons(client) & IN_ATTACK3) != 0;
					KeyDown2[client] = (GetClientButtons(client) & IN_ATTACK) != 0;
					KeyDown3[client] = (GetClientButtons(client) & IN_RELOAD) != 0;
				}
			}
			SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
			SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		}
	}
}
public Action OnPlayerRunCmd(int client, int &buttons)
{
	new bool:keyDown = (buttons & IN_ATTACK3) != 0;
	new bool:keyDown2 = (buttons & IN_ATTACK) != 0;
	new bool:keyDown3 = (buttons & IN_RELOAD) != 0;
	
	if (IsValidClient(spookmaster) && IsValidClient(client))
	{
		int spookBoss = FF2_GetBossIndex(spookmaster);
		if (keyDown3 && !KeyDown3[spookmaster] && client == spookmaster && FF2_GetRoundState() == 1 && !necroLord && !chaos && !stanceActive && spookBoss != -1)
		{
			skill++;
			if (FF2_GetBossLives(spookBoss) == 1)
			{
				if (skill == 4 && chaosUsed)
				{
					skill = 5;
				}
				if (skill == 5 && necroUsed && FF2_GetArgNamedF(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg401", 0.0) == 0.0)
				{
					skill = 0;
				}
			}
			else
			{
				if (skill > 3)
				{
					skill = 0;
				}
			}
			if (skill > 5)
			{
				skill = 0;
			}
			if (skill < 0)
			{
				skill = 0;
			}
			EmitSoundToClient(spookmaster, "items/cart_explode_trigger.wav", _, _, _, _, _, SNDPITCH_LOW);
		}
		if (keyDown && !KeyDown[spookmaster] && client == spookmaster && FF2_GetRoundState() == 1 && spookBoss != -1)
		{
			if (necroLord || chaos || spookPower < skillCost[skill] || skillCD[skill] >= 0.1 || (skill == 3 && GetDeadGuys() <= 0))
			{
				EmitSoundToClient(spookmaster, "replay/record_fail.wav");
			}
			else
			{
				switch(skill)
				{
					case 0:
					{
						if (FF2_GetArgNamedF(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg201", 0.0) > 0.0)
						{
							CreateTimer(FF2_GetArgNamedF(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg201", 0.0), mortisWarning, _, TIMER_FLAG_NO_MAPCHANGE);
							EmitSoundToAll("items/halloween/banshee02.wav");
							//EmitSoundToAll("mvm/mvm_used_powerup.wav", _, _, _, _, _, SNDPITCH_LOW);
							EmitSoundToAll("freak_fortress_2/new_spookmaster/mortis_masher_activation.mp3", _, _, _, _, _, SNDPITCH_LOW);
							for (int clientB = 1; clientB <= MaxClients; clientB++)
							{
								if (IsValidClient(clientB))
								{
									if (IsPlayerAlive(clientB) && TF2_GetClientTeam(clientB) != TF2_GetClientTeam(spookmaster))
									{
										SetHudTextParams(-1.0, 0.80, FF2_GetArgNamedF(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg201", 0.0), 255, 0, 0, 255);
										ShowHudText(clientB, -1, "警告：亡魂粉碎击即将杀到！小心你的骨头被震得咯咯作响！");
									}
								}
							}
						}
						else
						{
							activateMortis();
						}
						attachParticle(spookmaster, MORTIS_PARTICLE, "root");
						skillCD[0] = FF2_GetArgNamedF(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg6", 0.0);
					}
					case 1:
					{
						activateRIP();
						skillCD[1] = FF2_GetArgNamedF(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg10", 0.0);
					}
					case 2:
					{
						repossession = true;
						attachParticle(spookmaster, REPO_PARTICLE, "root");
						EmitSoundToAll("freak_fortress_2/new_spookmaster/repossession_start.mp3", _, _, SNDLEVEL_TRAIN);
						//TF2_AddCondition(spookmaster, TFCond_CritHype, FF2_GetArgF(spookmaster, PLUGIN_NAME, SPOOKMASTER, "arg14", 14, 8.0));
						CreateTimer(FF2_GetArgNamedF(spookmaster, PLUGIN_NAME, SPOOKMASTER, "arg14", 8.0), endPossession, _, TIMER_FLAG_NO_MAPCHANGE);
						skillCD[2] = FF2_GetArgNamedF(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg18", 0.0);
					}
					case 3:
					{
						if (!stanceActive)
						{
							startStance();
						}
						else if (stanceActive)
						{
							endStance();
						}
					}
					case 4:
					{
						activateChaos();
						if (FF2_GetArgNamedF(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg501", 0.0) == 0.0)
						{
							chaosUsed = true;
							skill = 0;
						}
						else
						{
							skillCD[4] = FF2_GetArgNamedF(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg501", 0.0);
						}
					}
					case 5:
					{
						activateNecro();
						if (FF2_GetArgNamedF(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg401", 0.0) == 0.0)
						{
							necroUsed = true;
							skill = 0;
						}
						else
						{
							skillCD[5] = FF2_GetArgNamedF(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg401", 0.0);
						}
					}
				}
				//EmitSoundToClient(spookmaster, "freak_fortress_2/new_spookmaster/mortis_masher_activation.mp3");
				spookPower += -skillCost[skill];
				for (int g = 0; g < 6; g++)
				{
					if (g != skill)
						skillCD[g] += FF2_GetArgNamedF(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg101", 0.0);
				}
			}
		}
		if (keyDown2 && !KeyDown2[spookmaster] && client == spookmaster && FF2_GetRoundState() == 1 && !TF2_IsPlayerInCondition(spookmaster, TFCond_Dazed) && spookBoss != -1)
		{
			if (necroLord && spellReady && FF2_GetArgNamedI(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg36", 1) == 1)
			{
				ShootProjectile();
				spellReady = false;
				CreateTimer(FF2_GetArgNamedF(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg37", 0.5), spellCool, TIMER_FLAG_NO_MAPCHANGE);
				buttons &= ~IN_ATTACK;
				return Plugin_Changed;
			}
			else if (chaos && spellReady && FF2_GetArgNamedI(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg24", 1) == 1 && !TF2_IsPlayerInCondition(spookmaster, TFCond_Dazed))
			{
				ShootProjectile();
				spellReady = false;
				CreateTimer(FF2_GetArgNamedF(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg25", 0.2), spellCool, TIMER_FLAG_NO_MAPCHANGE);
				buttons &= ~IN_ATTACK;
				return Plugin_Changed;
			}
		}
		KeyDown[client] = keyDown;
		KeyDown2[client] = keyDown2;
		KeyDown3[client] = keyDown3;
	}
	return Plugin_Continue;
}
public Action spellCool(Handle spelltimer)
{
	spellReady = true;
	return Plugin_Stop;
}
public void activateChaos()
{
	if (IsValidClient(spookmaster))
	{
		for(int clientY = 1; clientY <= MaxClients; clientY++)
		{
			if (IsValidClient(clientY))
			{
				StopSound(clientY, SNDCHAN_AUTO, "freak_fortress_2/new_spookmaster/spookmaster_bgm_original.mp3");
				StopSound(clientY, SNDCHAN_AUTO, "freak_fortress_2/new_spookmaster/spookmaster_bgm_original2.mp3");
				FF2_StopMusic(clientY);
			}
		}
		switch(GetRandomInt(1, 2))
		{
			case 1:
			{
				EmitSoundToAll("freak_fortress_2/new_spookmaster/boner_ragemode.mp3", _, _, SNDLEVEL_GUNFIRE); //Doubled because I'm too lazy to open Audacity and apply a proper amplification
				//EmitSoundToAll("freak_fortress_2/new_spookmaster/boner_ragemode.mp3");
			}
			case 2:
			{
				EmitSoundToAll("freak_fortress_2/new_spookmaster/boner_ragemode2.mp3", _, _, SNDLEVEL_GUNFIRE);
				//EmitSoundToAll("freak_fortress_2/new_spookmaster/boner_ragemode2.mp3");
			}
		}
		attachParticle(spookmaster, CHAOS_PARTICLE, "root");
		TF2_StunPlayer(spookmaster, 4.0, 1.0, TF_STUNFLAG_BONKSTUCK);
		chaos = true;
		spellReady = true;
		CreateTimer(FF2_GetArgNamedF(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg35", 30.0), endSpamState, TIMER_FLAG_NO_MAPCHANGE);
	}
}
public void activateNecro()
{
	if (IsValidClient(spookmaster))
	{
		for(int clientZ = 1; clientZ <= MaxClients; clientZ++)
		{
			if (IsValidClient(clientZ))
			{
				StopSound(clientZ, SNDCHAN_AUTO, "freak_fortress_2/new_spookmaster/spookmaster_bgm_original.mp3");
				StopSound(clientZ, SNDCHAN_AUTO, "freak_fortress_2/new_spookmaster/spookmaster_bgm_original2.mp3");
				FF2_StopMusic(clientZ);
			}
		}
		switch(GetRandomInt(1, 2))
		{
			case 1:
			{
				EmitSoundToAll("freak_fortress_2/new_spookmaster/boner_ragemode.mp3", _, _, SNDLEVEL_GUNFIRE);
			}
			case 2:
			{
				EmitSoundToAll("freak_fortress_2/new_spookmaster/boner_ragemode2.mp3", _, _, SNDLEVEL_GUNFIRE);
			}
		}
		attachParticle(spookmaster, NECRO_PARTICLE, "root");
		TF2_StunPlayer(spookmaster, 4.0, 1.0, TF_STUNFLAG_BONKSTUCK);
		necroLord = true;
		spellReady = true;
		CreateTimer(FF2_GetArgNamedF(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg41", 30.0), endSpamState, TIMER_FLAG_NO_MAPCHANGE);
	}
}
public Action endSpamState(Handle spamStop)
{
	if (chaos)
	{
		chaosTracker = 0.0;
		chaos = false;
		EmitSoundToAll("freak_fortress_2/new_spookmaster/spookmaster_bgm_original.mp3");
	}
	else if (necroLord)
	{
		necroTracker = 0.0;
		necroLord = false;
		EmitSoundToAll("freak_fortress_2/new_spookmaster/spookmaster_bgm_original.mp3");
	}
	if (IsValidClient(spookmaster))
	{
		DeleteParticle(spookmaster);
	}

	return Plugin_Stop;
}
public void startStance()
{
	if (IsValidClient(spookmaster))
	{
		stanceActive = true;
		switch(GetRandomInt(1, 2))
		{
			case 1:
			{
				EmitSoundToAll("freak_fortress_2/new_spookmaster/stance_intro1.mp3");
				EmitSoundToAll("freak_fortress_2/new_spookmaster/stance_intro1.mp3");
			}
			case 2:
			{
				EmitSoundToAll("freak_fortress_2/new_spookmaster/stance_intro2.mp3");
				EmitSoundToAll("freak_fortress_2/new_spookmaster/stance_intro2.mp3");
			}
		}
		TF2_AddCondition(spookmaster, TFCond_MegaHeal);
		SetVariantString("models/freak_fortress_2/new_spookmaster/jones_stance.mdl");
		AcceptEntityInput(spookmaster, "SetCustomModel");
		SetEntProp(spookmaster, Prop_Send, "m_bUseClassAnimations", 0);
		float loc[3];
		GetClientAbsOrigin(spookmaster, loc);
		
		stanceParticleA = CreateEntityByName("info_particle_system");
		if (IsValidEdict(stanceParticleA))
        {
        	TeleportEntity(stanceParticleA, loc, NULL_VECTOR, NULL_VECTOR);
        	DispatchKeyValue(stanceParticleA, "effect_name", SUMMONER_PARTICLE);
        	SetVariantString("!activator");
       		DispatchKeyValue(stanceParticleA, "targetname", "present");
        	DispatchSpawn(stanceParticleA);
        	ActivateEntity(stanceParticleA);
        	AcceptEntityInput(stanceParticleA, "Start");
        }
        
		stanceParticleB = CreateEntityByName("info_particle_system");
        	
        if (IsValidEdict(stanceParticleB))
        {
        	TeleportEntity(stanceParticleB, loc, NULL_VECTOR, NULL_VECTOR);
        	DispatchKeyValue(stanceParticleB, "effect_name", SUMMONER_PARTICLE2);
 			SetVariantString("!activator");
       		DispatchKeyValue(stanceParticleB, "targetname", "present");
        	DispatchSpawn(stanceParticleB);
        	ActivateEntity(stanceParticleB);
        	AcceptEntityInput(stanceParticleB, "Start");
        }
        
        stanceParticleC = CreateEntityByName("info_particle_system");
        	
        if (IsValidEdict(stanceParticleC))
        {
        	TeleportEntity(stanceParticleC, loc, NULL_VECTOR, NULL_VECTOR);
        	DispatchKeyValue(stanceParticleC, "effect_name", SUMMONER_PARTICLE3);
 			SetVariantString("!activator");
       		DispatchKeyValue(stanceParticleC, "targetname", "present");
        	DispatchSpawn(stanceParticleC);
        	ActivateEntity(stanceParticleC);
        	AcceptEntityInput(stanceParticleC, "Start");
        }
	}
}
public Action ShootProjectile() //Code borrowed from Mitchell, then heavily modified for Spell Spam.
{
	if (IsValidClient(spookmaster))
	{
		new Float:vAngles[3]; // original
		new Float:vPosition[3]; // original
		GetClientEyeAngles(spookmaster, vAngles);
		GetClientEyePosition(spookmaster, vPosition);
		new String:strEntname[45] = "";
		
		if (necroLord)
		{
			strEntname = "tf_projectile_spellspawnzombie";
		}
		else if (chaos)
		{
			if (FF2_GetArgNamedI(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg33", 2) == 2 && recentDeath)
			{
				strEntname = "tf_projectile_spellspawnboss";
				recentDeath = false;
			}
			else
			{
				bool spellSelected = false;
				while (!spellSelected)
				{
					switch(GetRandomInt(1, 8))
					{
						case 1:
						{
							if (FF2_GetArgNamedI(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg26", 1) == 1)
							{
								strEntname = "tf_projectile_spellfireball";
								spellSelected = true;
							}
						}
						case 2:
						{
							if (FF2_GetArgNamedI(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg27", 1) == 1)
							{
								strEntname = "tf_projectile_lightningorb";
								spellSelected = true;
							}
						}
						case 3:
						{
							if (FF2_GetArgNamedI(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg28", 0) == 1)
							{
								strEntname = "tf_projectile_spellmirv";
								spellSelected = true;
							}
						}
						case 4:
						{
							if (FF2_GetArgNamedI(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg29", 0) == 1)
							{
								strEntname = "tf_projectile_spellpumpkin";
								spellSelected = true;
							}
						}
						case 5:
						{
							if (FF2_GetArgNamedI(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg30", 1) == 1)
							{
								strEntname = "tf_projectile_spellbats";
								spellSelected = true;
							}
						}
						case 6:
						{
							if (FF2_GetArgNamedI(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg31", 1) == 1)
							{
								strEntname = "tf_projectile_spellmeteorshower";
								spellSelected = true;
							}
						}
						case 7:
						{
							if (FF2_GetArgNamedI(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg32", 1) == 1)
							{
								strEntname = "tf_projectile_spelltransposeteleport";
								spellSelected = true;
							}
						}
						case 8:
						{
							if (FF2_GetArgNamedI(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg33", 2) == 1)
							{
								strEntname = "tf_projectile_spellspawnboss";
								spellSelected = true;
							}
						}
					}
				}
			}
		}
		else
		{
			PrintToChatAll("错误：尝试释放法术，但并未处于法术狂潮状态。");
			return Plugin_Continue;
		}
	
		new iTeam = GetClientTeam(spookmaster);
		new iSpell = CreateEntityByName(strEntname);
		
		if(!IsValidEntity(iSpell))
			return Plugin_Continue;
	
		decl Float:vVelocity[3];
		decl Float:vBuffer[3];
		
		GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
		
		vVelocity[0] = vBuffer[0]*1100.0; //Speed of a tf2 rocket.
		vVelocity[1] = vBuffer[1]*1100.0;
		vVelocity[2] = vBuffer[2]*1100.0;
		
		SetEntPropEnt(iSpell, Prop_Send, "m_hOwnerEntity", spookmaster);
		SetEntProp(iSpell,    Prop_Send, "m_bCritical", (GetRandomInt(0, 100) <= 5)? 1 : 0, 1);
		SetEntProp(iSpell,    Prop_Send, "m_iTeamNum",     iTeam, 1);
		SetEntProp(iSpell,    Prop_Send, "m_nSkin", (iTeam-2));
		
		TeleportEntity(iSpell, vPosition, vAngles, NULL_VECTOR);
		SetVariantInt(iTeam);
		AcceptEntityInput(iSpell, "TeamNum", -1, -1, 0);
		SetVariantInt(iTeam);
		AcceptEntityInput(iSpell, "SetTeam", -1, -1, 0); 
		
		DispatchSpawn(iSpell);
		TeleportEntity(iSpell, NULL_VECTOR, NULL_VECTOR, vVelocity);
		
		if (FF2_GetArgNamedF(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg34", 0.0) > 0.0 && chaos)
		{
			SDKHooks_TakeDamage(spookmaster, spookmaster, spookmaster, FF2_GetArgNamedF(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg34", 0.0));
		}
		else if (FF2_GetArgNamedF(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg38", 0.0) > 0.0 && necroLord)
		{
			SDKHooks_TakeDamage(spookmaster, spookmaster, spookmaster, FF2_GetArgNamedF(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg38", 0.0));
		}
		
		//return iSpell;
	}
	return Plugin_Continue;
}
public void GiveRandomMannpower(int client, float duration)
{
	if (IsValidClient(client))
	{
		switch(GetRandomInt(1, 9))
		{
			case 1:
			{
				TF2_AddCondition(client, TFCond_RuneStrength, duration);
			}
			case 2:
			{
				TF2_AddCondition(client, TFCond_RuneHaste, duration);
			}
			case 3:
			{
				TF2_AddCondition(client, TFCond_RuneRegen, duration);
			}
			case 4:
			{
				TF2_AddCondition(client, TFCond_RuneResist, duration);
			}
			case 5:
			{
				TF2_AddCondition(client, TFCond_RuneVampire, duration);
			}
			case 6:
			{
				GiveRandomMannpower(client, duration);
			}
			case 7:
			{
				TF2_AddCondition(client, TFCond_RunePrecision, duration);
			}
			case 8:
			{
				TF2_AddCondition(client, TFCond_RuneAgility, duration);
			}
			case 9:
			{
				TF2_AddCondition(client, TFCond_RuneKnockout, duration);
			}
		}
	}
}
public void endStance()
{
	TF2_RemoveCondition(spookmaster, TFCond_MegaHeal);
	/*if (FF2_GetBossLives(FF2_GetBossIndex(spookmaster)) == 1)
	{
		SetVariantString("models/freak_fortress_2/new_spookmaster/spookmaster_bones_life2.mdl");
	}*/
	//else
	//{
	SetVariantString("models/freak_fortress_2/new_spookmaster/skeleton_sniper.mdl");
	//}
	AcceptEntityInput(spookmaster, "SetCustomModel");
	SetEntProp(spookmaster, Prop_Send, "m_bUseClassAnimations", 1);
	stanceActive = false;
	stanceTracker = 0.0;
	skillCD[3] = FF2_GetArgNamedF(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg601", 0.0);
	if (IsValidEdict(stanceParticleA))
    {
        char classname[64];

        GetEdictClassname(stanceParticleA, classname, sizeof(classname));

        if (StrEqual(classname, "info_particle_system", false))
        {
			AcceptEntityInput(stanceParticleA, "Stop");
			AcceptEntityInput(stanceParticleA, "Kill");
		}
    }
    if (IsValidEdict(stanceParticleB))
    {
        char classname[64];

        GetEdictClassname(stanceParticleB, classname, sizeof(classname));

        if (StrEqual(classname, "info_particle_system", false))
        {
			AcceptEntityInput(stanceParticleB, "Stop");
			AcceptEntityInput(stanceParticleB, "Kill");
		}
    }
    if (IsValidEdict(stanceParticleC))
    {
        char classname[64];

        GetEdictClassname(stanceParticleC, classname, sizeof(classname));

        if (StrEqual(classname, "info_particle_system", false))
        {
			AcceptEntityInput(stanceParticleC, "Stop");
			AcceptEntityInput(stanceParticleC, "Kill");
		}
    }
}
public Action endPossession(Handle endPos) //Ends 钙质归心击
{
	if (IsValidClient(spookmaster))
	{
		if (FF2_GetRoundState() == 1 && FF2_GetBossIndex(spookmaster) != -1)
		{
			repossession = false;
			DeleteParticle(spookmaster);
		}
		for (int client = 1; client <= MaxClients; client++)
		{
			isAlreadyHit[client] = false;
		}
	}

	return Plugin_Stop;
}

public void activateMortis()
{
	EmitSoundToAll("freak_fortress_2/new_spookmaster/mortis_masher_activation.mp3");
	CreateTimer(FF2_GetArgNamedF(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg5", 0.0) * FF2_GetArgNamedI(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg4", 0), removeMortisParticle, _, TIMER_FLAG_NO_MAPCHANGE);
	if (FF2_GetArgNamedI(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg1", 0) != 3)
	{
		int liveReds = 0;
		for (int client = 1; client <= MaxClients; client++)
		{
			if (IsValidClient(client))
			{
				if (TF2_GetClientTeam(client) == TFTeam_Red && IsPlayerAlive(client))
				{
					liveReds = liveReds + 1;
				}
			}
		}
		int selfMortis = FF2_GetArgNamedI(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg2", 0);
		float mortisPercent = FF2_GetArgNamedF(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg3", 0.25);
		int maxMortis = RoundFloat(mortisPercent*liveReds);
		if (maxMortis < 1)
			maxMortis = 1;
		int smashTarget = GetRandomInt(1, MaxClients);
		for(int numSmashed = 0; numSmashed <= maxMortis; smashTarget = GetRandomInt(1, MaxClients))
		{
			if (IsValidClient(smashTarget))
			{
				if (IsPlayerAlive(smashTarget))
				{
					if (FF2_GetArgNamedI(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg1", 2) == 1)
					{
						if (selfMortis == 0)
						{
							while (TF2_GetClientTeam(smashTarget) == TFTeam_Blue)
							{
								smashTarget = GetRandomInt(1, MaxClients);
							}
						}
						TF2_StunPlayer(smashTarget, 5.0, 1.0, TF_STUNFLAG_BONKSTUCK|TF_STUNFLAG_THIRDPERSON, spookmaster);
						NecroMash_SmashClient(smashTarget);
					}
					else if (FF2_GetArgNamedI(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg1", 2) == 2)
					{
						if (selfMortis == 0)
						{
							if (IsValidClient(smashTarget))
							{
								while (TF2_GetClientTeam(smashTarget) == TFTeam_Blue)
								{
									smashTarget = GetRandomInt(1, MaxClients);
									while (!IsValidClient(smashTarget))
									{
										smashTarget = GetRandomInt(1, MaxClients);
									}	
								}
							}
						}
						mortisActive[smashTarget] = true;
						//EmitSoundToAll("freak_fortress_2/new_spookmaster/mortis_masher_activation.mp3");
						CreateTimer(FF2_GetArgNamedF(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg5", 0.25), smashTimer, smashTarget, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
					}
					switch(TF2_GetPlayerClass(smashTarget))
					{
						case TFClass_Scout:
						{
							EmitSoundToAll("freak_fortress_2/new_spookmaster/mortis_masher_scout.mp3", smashTarget);
						}
						case TFClass_Soldier:
						{
							//CPrintToChatAll("{orange}To-do: make a masher sound for the soldier.");
						}
						case TFClass_Pyro:
						{
							//CPrintToChatAll("{orange}To-do: make a masher sound for the pyro.");
						}
						case TFClass_DemoMan:
						{
							EmitSoundToAll("freak_fortress_2/new_spookmaster/mortis_masher_demo.mp3", smashTarget);
						}
						case TFClass_Heavy:
						{
							EmitSoundToAll("freak_fortress_2/new_spookmaster/mortis_masher_heavy.mp3", smashTarget);
						}
						case TFClass_Engineer:
						{
							//CPrintToChatAll("{orange}To-do: make a masher sound for the engineer.");
						}
						case TFClass_Medic:
						{
							//CPrintToChatAll("{orange}To-do: make a masher sound for the medic.");
						}
						case TFClass_Sniper:
						{
							//CPrintToChatAll("{orange}To-do: make a masher sound for the sniper.");
						}
						case TFClass_Spy:
						{
							EmitSoundToAll("freak_fortress_2/new_spookmaster/mortis_masher_heavy.mp3", smashTarget);
						}
					}	
					numSmashed++;
				}
			}
		}
		if (FF2_GetArgNamedI(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg1", 0) == 1)
		{
			EmitSoundToAll("freak_fortress_2/new_spookmaster/mortis_masher_freezekill.mp3", _, _, SNDLEVEL_CAR);
		}
	}
	else
	{
		CreateTimer(FF2_GetArgNamedF(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg5", 0.0), mortis_Method2, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}
public Action removeMortisParticle(Handle removeMortisParticle)
{
	DeleteParticle(spookmaster);
	return Plugin_Stop;
}
public void activateRIP()
{
	SetVariantString("models/freak_fortress_2/new_spookmaster/bone_tornado.mdl");
	AcceptEntityInput(spookmaster, "SetCustomModel");
	SetEntProp(spookmaster, Prop_Send, "m_bUseClassAnimations", 0);
	letItRIP = true;
	float ripTime = FF2_GetArgNamedF(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg8", 10.0);
	SDKHook(spookmaster, SDKHook_StartTouch, spookRIP);
	TF2_AddCondition(spookmaster, TFCond_MegaHeal, ripTime);
	TF2_AddCondition(spookmaster, TFCond_SpeedBuffAlly, ripTime);
	TF2_StunPlayer(spookmaster, ripTime, 0.0, TF_STUNFLAG_THIRDPERSON);
	CreateTimer(ripTime, endRIP, spookmaster, TIMER_FLAG_NO_MAPCHANGE);
	SetEntProp(spookmaster, Prop_Send, "m_CollisionGroup", 2);
	EmitSoundToAll("freak_fortress_2/new_spookmaster/new_spookmaster_bonerwhirl.mp3", spookmaster, _, SNDLEVEL_TRAIN);
	attachParticle(spookmaster, RIP_PARTICLE, "root");
}
stock Handle attachParticle(int client, char type[256], char point[256])
{
	if (IsValidClient(client))
	{
		playerParticle[client] = CreateEntityByName("info_particle_system");
    
   		if (IsValidEdict(playerParticle[client]))
    	{
        	decl Float:pos[3];
        	GetClientAbsOrigin(client, pos);
        	TeleportEntity(playerParticle[client], pos, NULL_VECTOR, NULL_VECTOR);
        	DispatchKeyValue(playerParticle[client], "effect_name", type);
 			SetVariantString("!activator");
            AcceptEntityInput(playerParticle[client], "SetParent", client, playerParticle[client], 0);
            SetVariantString(point);
            AcceptEntityInput(playerParticle[client], "SetParentAttachmentMaintainOffset", playerParticle[client], playerParticle[client], 0);
       		DispatchKeyValue(playerParticle[client], "targetname", "present");
        	DispatchSpawn(playerParticle[client]);
        	ActivateEntity(playerParticle[client]);
        	AcceptEntityInput(playerParticle[client], "Start");
    	}
    	else
    	{
        	LogError("(CreateParticle): Could not create info_particle_system");
    	}
    }
    return INVALID_HANDLE;
}
public Action spookRIP(int Boss, int iEntity)
{
	static float origin[3], angles[3], targetpos[3];
	if(IsValidClient(iEntity) && IsPlayerAlive(iEntity) /*&& GetClientTeam(iEntity)!=BossTeam*/)
	{
		GetClientEyeAngles(Boss, angles);
		GetClientEyePosition(Boss, origin);
		GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", targetpos);
		GetAngleVectors(angles, angles, NULL_VECTOR, NULL_VECTOR);
		NormalizeVector(angles, angles);
		SubtractVectors(targetpos, origin, origin);

		if(GetVectorDotProduct(origin, angles) > 0.0)
		{
			if (FF2_GetArgNamedI(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg12", 0) == 0 && IsInvuln(iEntity))
			{
				return Plugin_Continue;
			}
			else
			{
				SDKHooks_TakeDamage(iEntity, Boss, Boss, 15.0, DMG_CRUSH|DMG_PREVENT_PHYSICS_FORCE|DMG_ALWAYSGIB);	// Make boss get credit for the kill
				FakeClientCommandEx(iEntity, "explode");
			}
		}		
	}
	return Plugin_Continue;
}
public Action endRIP(Handle spookripper, int spooky) //Resets Spookmaster's model when Let It R.I.P. ends
{	
	if (IsValidClient(spooky))
	{
		/*if (FF2_GetBossLives(FF2_GetBossIndex(spooky)) == 1)
		{
			SetVariantString("models/freak_fortress_2/new_spookmaster/spookmaster_bones_life2.mdl");
		}*/
		//else
		//{
		SetVariantString("models/freak_fortress_2/new_spookmaster/skeleton_sniper.mdl");
		//}
		AcceptEntityInput(spooky, "SetCustomModel");
		SetEntProp(spooky, Prop_Send, "m_bUseClassAnimations", 1);
		SDKUnhook(spooky, SDKHook_StartTouch, spookRIP);
		SetEntProp(spooky, Prop_Send, "m_CollisionGroup", 5);
		DeleteParticle(spookmaster);
	}
	letItRIP = false;

	return Plugin_Stop;
}
public Action DeleteParticle(int client)
{
    if (IsValidEdict(playerParticle[client]))
    {
        char classname[64];

        GetEdictClassname(playerParticle[client], classname, sizeof(classname));

        if (StrEqual(classname, "info_particle_system", false))
        {
			AcceptEntityInput(playerParticle[client], "Stop");
			AcceptEntityInput(playerParticle[client], "Kill");
		}
    }
	
	return Plugin_Stop;
}
public Action smashTimer(Handle smashing, int target)
{
	if (IsValidClient(target))
	{
		if (IsPlayerAlive(target) && FF2_GetRoundState() == 1)
		{
			NecroMash_SmashClient(target);
			smashCount[target]++;
			if (smashCount[target] >= FF2_GetArgNamedI(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg4", 10))
			{
				smashCount[target] = 0;
				mortisActive[target] = false;
				return Plugin_Stop;
			}
		}
		else
		{
			mortisActive[target] = false;
			return Plugin_Stop;
		}
	}
	else
	{
		return Plugin_Stop;
	}

	return Plugin_Continue;
}
public Action mortis_Method2(Handle mortis_Method2)
{
	if (IsValidClient(spookmaster))
	{
		if (FF2_GetBossIndex(spookmaster) != -1 && IsPlayerAlive(spookmaster))
		{
			NecroMash_SmashClient(spookmaster);
			smashCount[spookmaster]++;
			if (smashCount[spookmaster] >= FF2_GetArgNamedI(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg4", 0))
			{
				smashCount[spookmaster] = 0;
				return Plugin_Stop;
			}
		}
		else
		{
			return Plugin_Stop;
		}
	}
	else
	{
		return Plugin_Stop;
	}

	return Plugin_Continue;
}
//Below is taken from RTD, credit goes to the original authors. All I did was modify it a bit to do prevent ear-rape and add some mild customization.
void NecroMash_SmashClient(int client){
	float flPos[3], flPpos[3], flAngles[3];
	if (FF2_GetArgNamedI(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg1", 0) == 3)
	{
		GetClientEyePosition(spookmaster, flPos);
		GetClientEyeAngles(spookmaster, flAngles);
		Handle trace = TR_TraceRayFilterEx(flPos, flAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
		if (TR_DidHit(trace))
		{
			TR_GetEndPosition(flPos, trace);
			TR_GetEndPosition(flPpos, trace);
			CloseHandle(trace);
		}
	}
	else
	{
		GetClientAbsOrigin(client, flPos);
		GetClientAbsOrigin(client, flPpos);
		GetClientEyeAngles(client, flAngles);
	}
	flAngles[0] = 0.0;

	float vForward[3];
	GetAngleVectors(flAngles, vForward, NULL_VECTOR, NULL_VECTOR);
	flPos[0] -= (vForward[0] * 750);
	flPos[1] -= (vForward[1] * 750);
	flPos[2] -= (vForward[2] * 750);

	flPos[2] += 350.0;

	int gears = CreateEntityByName("prop_dynamic");
	if(IsValidEntity(gears)){
		DispatchKeyValueVector(gears, "origin", flPos);
		DispatchKeyValueVector(gears, "angles", flAngles);
		DispatchKeyValue(gears, "model", "models/props_halloween/hammer_gears_mechanism.mdl");
		DispatchSpawn(gears);
	}

	int hammer = CreateEntityByName("prop_dynamic");
	if(IsValidEntity(hammer)){
		DispatchKeyValueVector(hammer, "origin", flPos);
		DispatchKeyValueVector(hammer, "angles", flAngles);
		DispatchKeyValue(hammer, "model", "models/props_halloween/hammer_mechanism.mdl");
		DispatchSpawn(hammer);
	}

	int button = CreateEntityByName("prop_dynamic");
	if(IsValidEntity(button)){
		flPos[0] += (vForward[0] * 600);
		flPos[1] += (vForward[1] * 600);
		flPos[2] += (vForward[2] * 600);

		flPos[2] -= 100.0;
		flAngles[1] += 180.0;

		DispatchKeyValueVector(button, "origin", flPos);
		DispatchKeyValueVector(button, "angles", flAngles);
		DispatchKeyValue(button, "model", "models/props_halloween/bell_button.mdl");
		DispatchSpawn(button);

		Handle pack;
		CreateDataTimer(1.3, Timer_NecroMash_Hit, pack);
		WritePackFloat(pack, flPpos[0]); //Position of effects
		WritePackFloat(pack, flPpos[1]); //Position of effects
		WritePackFloat(pack, flPpos[2]); //Position of effects

		Handle pack2;
		CreateDataTimer(1.0, Timer_NecroMash_Whoosh, pack2);
		WritePackFloat(pack2, flPpos[0]); //Position of effects
		WritePackFloat(pack2, flPpos[1]); //Position of effects
		WritePackFloat(pack2, flPpos[2]); //Position of effects

		EmitSoundToAll("misc/halloween/strongman_fast_swing_01.wav", _, _, _, _, 0.25, _, _, flPpos);
	}

	SetVariantString("OnUser2 !self:SetAnimation:smash:0:1");
	AcceptEntityInput(gears, "AddOutput");
	AcceptEntityInput(gears, "FireUser2");

	SetVariantString("OnUser2 !self:SetAnimation:smash:0:1");
	AcceptEntityInput(hammer, "AddOutput");
	AcceptEntityInput(hammer, "FireUser2");

	SetVariantString("OnUser2 !self:SetAnimation:hit:1.3:1");
	AcceptEntityInput(button, "AddOutput");
	AcceptEntityInput(button, "FireUser2");

	CreateTimer(3.0, removeMasher, gears, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(3.0, removeMasher, hammer, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(3.0, removeMasher, button, TIMER_FLAG_NO_MAPCHANGE);
	/*KILL_ENT_IN(gears,5.0)
	KILL_ENT_IN(hammer,5.0)
	KILL_ENT_IN(button,5.0)*/
}

public Action Timer_NecroMash_Hit(Handle timer, any pack){
	ResetPack(pack);

	float pos[3];
	pos[0] = ReadPackFloat(pack);
	pos[1] = ReadPackFloat(pack);
	pos[2] = ReadPackFloat(pack);

	int shaker = CreateEntityByName("env_shake");
	if(shaker != -1){
		DispatchKeyValue(shaker, "amplitude", "10");
		DispatchKeyValue(shaker, "radius", "1500");
		DispatchKeyValue(shaker, "duration", "1");
		DispatchKeyValue(shaker, "frequency", "2.5");
		DispatchKeyValue(shaker, "spawnflags", "4");
		DispatchKeyValueVector(shaker, "origin", pos);

		DispatchSpawn(shaker);
		AcceptEntityInput(shaker, "StartShake");

		CreateTimer(1.0, removeMasher, shaker, TIMER_FLAG_NO_MAPCHANGE);
	}
	EmitSoundToAll("ambient/explosions/explode_1.wav", _, _, _, _, 0.20, _, _, pos);
	EmitSoundToAll("misc/halloween/strongman_fast_impact_01.wav", _, _, _, _, 0.20, _, _, pos);

	float pos2[3], Vec[3], AngBuff[3];
	for(int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			if(IsClientInGame(i) && IsPlayerAlive(i))
			{
				if (TF2_GetClientTeam(i) != TF2_GetClientTeam(spookmaster) || (TF2_GetClientTeam(i) == TF2_GetClientTeam(spookmaster) && FF2_GetArgNamedI(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg2", 0) == 1))
				{
					GetClientAbsOrigin(i, pos2);
					if(GetVectorDistance(pos, pos2) <= 500.0)
					{
						MakeVectorFromPoints(pos, pos2, Vec);
						GetVectorAngles(Vec, AngBuff);
						AngBuff[0] -= 30.0;
						GetAngleVectors(AngBuff, Vec, NULL_VECTOR, NULL_VECTOR);
						NormalizeVector(Vec, Vec);
						ScaleVector(Vec, 500.0);
						Vec[2] += 250.0;
						TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, Vec);
						if(GetVectorDistance(pos, pos2) <= FF2_GetArgNamedF(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg200", 0.0))
						{
							SDKHooks_TakeDamage(i, i, spookmaster, FF2_GetArgNamedF(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg13", 999999.0), DMG_CLUB|DMG_BLAST|DMG_ALWAYSGIB);
						}
					}
				}
			}
		}
	}

	pos[2] += 10.0;
	NecroMash_CreateParticle("hammer_impact_button", pos);
	NecroMash_CreateParticle("hammer_bones_kickup", pos);

	return Plugin_Stop;
}

public Action Timer_NecroMash_Whoosh(Handle timer, any pack){
	ResetPack(pack);

	float pos[3];
	pos[0] = ReadPackFloat(pack);
	pos[1] = ReadPackFloat(pack);
	pos[2] = ReadPackFloat(pack);

	EmitSoundToAll("misc/halloween/strongman_fast_whoosh_01.wav", _, _, _, _, 0.25, _, _, pos);

	return Plugin_Stop;
}

stock void NecroMash_CreateParticle(char[] particle, float pos[3]){
	int tblidx = FindStringTable("ParticleEffectNames");
	char tmp[256];
	int count = GetStringTableNumStrings(tblidx);
	int stridx = INVALID_STRING_INDEX;

	for(int i = 0; i < count; i++){
		ReadStringTable(tblidx, i, tmp, sizeof(tmp));
		if(StrEqual(tmp, particle, false)){
			stridx = i;
			break;
		}
	}

	for(int i = 1; i <= MaxClients; i++){
		if(!IsValidEntity(i)) continue;
		if(!IsClientInGame(i)) continue;
		TE_Start("TFParticleEffect");
		TE_WriteFloat("m_vecOrigin[0]", pos[0]);
		TE_WriteFloat("m_vecOrigin[1]", pos[1]);
		TE_WriteFloat("m_vecOrigin[2]", pos[2]);
		TE_WriteNum("m_iParticleSystemIndex", stridx);
		TE_WriteNum("entindex", -1);
		TE_WriteNum("m_iAttachType", 2);
		TE_SendToClient(i, 0.0);
	}
}
//Above is taken from RTD; credit goes to the original authors.

public Action removeMasher(Handle remover, int removeTarget) //Remove necro-smashers
{
	RemoveEntity(removeTarget);
	return Plugin_Stop;
}

public bool:TraceEntityFilterPlayer(entity, contentsMask) //Borrowed from Apocalips
{
    return entity > MaxClients;
}

public Action mortisWarning(Handle mortisWarning)
{
	if (IsValidClient(spookmaster))
	{
		if (FF2_GetBossIndex(spookmaster) != -1 && FF2_GetRoundState() == 1 && IsPlayerAlive(spookmaster))
		{
			activateMortis();
		}
	}
	return Plugin_Stop;
}

public Action spookHUD(Handle spookHUD) //Used primarily to refresh SSB's hud.
{
	if (IsValidClient(spookmaster))
	{
		int bossIDX = FF2_GetBossIndex(spookmaster);
		int r = 0;
		int g = 0;
		int b = 0;
		if (bossIDX != -1 && FF2_GetRoundState() == 1 && IsPlayerAlive(spookmaster))
		{
			for (int i = 0; i < 6; i++)
			{
				if (skillCD[i] > 0.1)
				{
					skillCD[i] += -0.1;
					if (skillCD[i] <= 0.1)
					{
						skillCD[i] = 0.0;
					}
				}
			}
			spookPower += passiveRegen;
			if (!stanceActive && !chaos && !necroLord)
			{
				if (skillCD[skill] >= 0.1 || spookPower < skillCost[skill] || (skill == 3 && GetDeadGuys() <= 0))
				{
					//FF2_GetArgS(bossIDX, PLUGIN_NAME, SPOOKMASTER, "arg105", 105, HUD_Info, sizeof(HUD_Info));
					r = 255;
					g = 0;
					b = 0;
				}
				SetHudTextParams(x, y, 0.1, r, g, b, 255);
				switch(skill)
				{
					case 0:
					{
						if (skillCD[0] >= 0.1)
						{
							ShowHudText(spookmaster, -1, "惊魂魂片: %i\n[%i 灵魂] 亡魂粉碎击 (冷却: %i秒, 按R键切换)", spookPower, skillCost[0], RoundFloat(skillCD[0]));
						}
						else
						{
							if (spookPower >= skillCost[0])
							{
								//FF2_GetArgS(bossIDX, PLUGIN_NAME, SPOOKMASTER, "arg106", 106, HUD_Info, sizeof(HUD_Info));
								r = 0;
								g = 0;
								b = 255;
								SetHudTextParams(x, y, 0.1, r, g, b, 255);
							}
							ShowHudText(spookmaster, -1, "惊魂魂片: %i\n[%i 灵魂] 亡魂粉碎击 (按R键切换, 中键激活)", spookPower, skillCost[0]);
						}
					}
					case 1:
					{
						if (skillCD[1] >= 0.1)
						{
							ShowHudText(spookmaster, -1, "惊魂魂片: %i\n[%i 灵魂] 狂暴无羁破 (冷却: %i秒, 按R键切换)", spookPower, skillCost[1], RoundFloat(skillCD[1]));
						}
						else
						{
							if (spookPower >= skillCost[1])
							{
								//FF2_GetArgS(bossIDX, PLUGIN_NAME, SPOOKMASTER, "arg106", 106, HUD_Info, sizeof(HUD_Info));
								r = 0;
								g = 0;
								b = 255;
								SetHudTextParams(x, y, 0.1, r, g, b, 255);
							}
							ShowHudText(spookmaster, -1, "惊魂魂片: %i\n[%i 灵魂] 狂暴无羁破 (按R键切换, 中键激活)", spookPower, skillCost[1]);
						}
					}
					case 2:
					{
						if (skillCD[2] >= 0.1)
						{
							ShowHudText(spookmaster, -1, "惊魂魂片: %i\n[%i 灵魂] 钙质归心击 (冷却: %i秒, 按R键切换)", spookPower, skillCost[2], RoundFloat(skillCD[2]));
						}
						else
						{
							if (spookPower >= skillCost[2])
							{
								//FF2_GetArgS(bossIDX, PLUGIN_NAME, SPOOKMASTER, "arg106", 106, HUD_Info, sizeof(HUD_Info));
								r = 0;
								g = 0;
								b = 255;
								SetHudTextParams(x, y, 0.1, r, g, b, 255);
							}
							ShowHudText(spookmaster, -1, "惊魂魂片: %i\n[%i 灵魂] 钙质归心击 (按R键切换, 中键激活)", spookPower, skillCost[2]);
						}
					}
					case 3:
					{
						if (skillCD[3] >= 0.1)
						{
							ShowHudText(spookmaster, -1, "惊魂魂片: %i\n[%i 每次召唤消耗] 唤魂归位术 (冷却: %i秒, 按R键切换)\n目前你可以招募到军队中的亡者: %i", spookPower, skillCost[3], RoundFloat(skillCD[3]), GetDeadGuys());
						}
						else
						{
							if (spookPower >= skillCost[3])
							{
								//FF2_GetArgS(bossIDX, PLUGIN_NAME, SPOOKMASTER, "arg106", 106, HUD_Info, sizeof(HUD_Info));
								r = 0;
								g = 0;
								b = 255;
								SetHudTextParams(x, y, 0.1, r, g, b, 255);
							}
							ShowHudText(spookmaster, -1, "惊魂魂片: %i\n[%i 每次召唤消耗] 唤魂归位术 (按R键切换, 中键激活)\n目前你可以招募到军队中的亡者: %i", spookPower, skillCost[3], GetDeadGuys());
						}
					}
					case 4:
					{
						if (skillCD[4] >= 0.1)
						{
							ShowHudText(spookmaster, -1, "惊魂魂片: %i\n[%i 灵魂] -={法术狂潮：纯粹混沌}=- (冷却: %i秒, 按R键切换)", spookPower, skillCost[4], RoundFloat(skillCD[4]));
						}
						else
						{
							if (spookPower >= skillCost[4])
							{
								if (FF2_GetArgNamedI(bossIDX, PLUGIN_NAME, SPOOKMASTER, "arg110", 0) == 1)
								{
									r = GetRandomInt(0, 255);
									g = GetRandomInt(0, 255);
									b = GetRandomInt(0, 255);
									SetHudTextParams(x, y, 0.1, r, g, b, 255);
								}
								else
								{
									//FF2_GetArgS(bossIDX, PLUGIN_NAME, SPOOKMASTER, "arg106", 106, HUD_Info, sizeof(HUD_Info));
									r = 0;
									g = 0;
									b = 255;
									SetHudTextParams(x, y, 0.1, r, g, b, 255);
								}
								ShowHudText(spookmaster, -1, "惊魂魂片: %i\n[%i 灵魂] -={法术狂潮：纯粹混沌}=- (按R键切换, 中键激活)", spookPower, skillCost[4]);
							}
						}
					}
					case 5:
					{
						if (skillCD[5] >= 0.1)
						{
							ShowHudText(spookmaster, -1, "惊魂魂片: %i\n[%i 灵魂] -={法术狂潮：骨之领域}=- (冷却: %i秒, 按R键切换)", spookPower, skillCost[5], RoundFloat(skillCD[5]));
						}
						else
						{
							if (spookPower >= skillCost[5])
							{
								if (FF2_GetArgNamedI(bossIDX, PLUGIN_NAME, SPOOKMASTER, "arg110", 0) == 1)
								{
									r = GetRandomInt(0, 255);
									g = GetRandomInt(0, 255);
									b = GetRandomInt(0, 255);
									SetHudTextParams(x, y, 0.1, r, g, b, 255);
								}
								else
								{
									//FF2_GetArgS(bossIDX, PLUGIN_NAME, SPOOKMASTER, "arg106", 106, HUD_Info, sizeof(HUD_Info));
									r = 0;
									g = 0;
									b = 255;
									SetHudTextParams(x, y, 0.1, r, g, b, 255);
								}
								ShowHudText(spookmaster, -1, "惊魂魂片: %i\n[%i 灵魂] -={法术狂潮：骨之领域}=- (按R键切换, 中键激活)", spookPower, skillCost[5]);
							}
						}
					}
				}
			}
			else if (stanceActive)
			{
				float dmgVuln = FF2_GetArgNamedF(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg52", 1.5);
				if (dmgVuln > 1.0)
				{
					for (int client = 1; client <= MaxClients; client++)
					{
						if (IsValidClient(client))
						{
							if (IsPlayerAlive(client) && TF2_GetClientTeam(client) != TF2_GetClientTeam(spookmaster))
							{
								SetHudTextParams(-1.0, 0.80, 0.1, 0, 255, 0, 255);
								ShowHudText(client, -1, "你的机会来了！骨骸幽影霸主无法防御！\n他忙于准备粉碎击！现在去攻击\n可造成 %i-百分点额外伤害！", RoundFloat(10.0 * (dmgVuln - 1.0)));
							}
						}
					}
				}
				if (GetDeadGuys() <= 0)
				{
					endStance();
				}
				if (spookPower < skillCost[3])
				{
					endStance();
				}
				else
				{
					SetHudTextParams(x, y, 0.1, 0, 0, 255, 255);
					ShowHudText(spookmaster, -1, "唤魂归位术已激活！使用你的特殊攻击键来关闭。\n目前你可以招募到军队中的亡者: %i", GetDeadGuys());
					stanceTracker += 0.1;
					if (stanceTracker >= FF2_GetArgNamedF(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg48", 4.0))
					{
						stanceTracker = 0.0;
						float spookLoc[3];
						GetClientAbsOrigin(spookmaster, spookLoc);
						int hp = FF2_GetArgNamedI(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg49", 0);
						float span = FF2_GetArgNamedF(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg50", 0.0);
						float invTime = FF2_GetArgNamedF(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg51", 0.0);
						char stats[256];
						FF2_GetArgNamedS(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg602", stats, sizeof(stats));
						int target = GetRandomDeadPlayer();
						createBoner(target, hp, span, spookLoc, invTime, stats);
						switch(GetRandomInt(1, 3))
						{
							case 1:
							{
								EmitSoundToAll("freak_fortress_2/new_spookmaster/stance_summon1.mp3", target);
								EmitSoundToAll("freak_fortress_2/new_spookmaster/stance_summon1.mp3", target);
								EmitSoundToAll("freak_fortress_2/new_spookmaster/stance_summon1.mp3", target);
							}
							case 2:
							{
								EmitSoundToAll("freak_fortress_2/new_spookmaster/stance_summon2.mp3", target);
								EmitSoundToAll("freak_fortress_2/new_spookmaster/stance_summon2.mp3", target);
								EmitSoundToAll("freak_fortress_2/new_spookmaster/stance_summon2.mp3", target);
							}
							case 3:
							{
								EmitSoundToAll("freak_fortress_2/new_spookmaster/stance_summon3.mp3", target);
								EmitSoundToAll("freak_fortress_2/new_spookmaster/stance_summon3.mp3", target);
								EmitSoundToAll("freak_fortress_2/new_spookmaster/stance_summon3.mp3", target);
							}
						}
						spookPower += -skillCost[3];
					}
				}
			}
			else if (chaos)
			{
				if (FF2_GetArgNamedI(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg24", 0) == 0)
				{
					if (!TF2_IsPlayerInCondition(spookmaster, TFCond_Dazed))
					{
						chaosTracker += 0.1;
						if (chaosTracker >= FF2_GetArgNamedF(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg25", 0.0))
						{
							ShootProjectile();
						}
					}
				}
				else
				{
					if (FF2_GetArgNamedI(bossIDX, PLUGIN_NAME, SPOOKMASTER, "arg110", 0) == 1)
					{
						r = GetRandomInt(0, 255);
						g = GetRandomInt(0, 255);
						b = GetRandomInt(0, 255);
						SetHudTextParams(x, y, 0.1, r, g, b, 255);
					}
					else
					{
						//FF2_GetArgS(bossIDX, PLUGIN_NAME, SPOOKMASTER, "arg106", 106, HUD_Info, sizeof(HUD_Info));
						r = 0;
						g = 0;
						b = 255;
						SetHudTextParams(x, y, 0.1, r, g, b, 255);
					}
					ShowHudText(spookmaster, -1, "你已释放纯粹混沌！使用你的主武器开火，连续不断地狂放法术！");
				}
			}
			else if (necroLord)
			{
				if (FF2_GetArgNamedI(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg36", 0) == 0)
				{
					if (!TF2_IsPlayerInCondition(spookmaster, TFCond_Dazed))
					{
						necroTracker += 0.1;
						if (necroTracker >= FF2_GetArgNamedF(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg37", 0.0))
						{
							ShootProjectile();
						}
					}
				}
				else
				{
					if (FF2_GetArgNamedI(bossIDX, PLUGIN_NAME, SPOOKMASTER, "arg110", 0) == 1)
					{
						r = GetRandomInt(0, 255);
						g = GetRandomInt(0, 255);
						b = GetRandomInt(0, 255);
						SetHudTextParams(x, y, 0.1, r, g, b, 255);
					}
					else
					{
						//FF2_GetArgS(bossIDX, PLUGIN_NAME, SPOOKMASTER, "arg106", 106, HUD_Info, sizeof(HUD_Info));
						r = 0;
						g = 0;
						b = 255;
						SetHudTextParams(x, y, 0.1, r, g, b, 255);
					}
					ShowHudText(spookmaster, -1, "你已踏入骨之领域！狂按你的主要攻击键，让骷髅大军遍布整个地图！");
				}
			}
			//SetHudTextParams(x2, y2, 0.1, 0, 0, 0, 255);
			//ShowHudText(spookmaster, -1, "Spooky Scary Souls: %i | RAGE: %i%", spookPower, RoundFloat(FF2_GetBossCharge(FF2_GetBossIndex(spookmaster), 0)));
		}
		else if (bossIDX == -1)
		{
			return Plugin_Stop;
		}
		else if (FF2_GetRoundState() == 2)
		{
			return Plugin_Stop;
		}
		else if (!IsPlayerAlive(spookmaster))
		{
			return Plugin_Stop;
		}
	}
	else
	{
		return Plugin_Stop;
	}

	return Plugin_Continue;
}
public int GetDeadGuys()
{
	int deadGuys = 0;
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client))
		{
			if (!IsPlayerAlive(client))
			{
				deadGuys++;
			}
		}
	}
	return deadGuys;
}
public Action:spooky_preThink(spookyBrain) //Controls Spookmaster Bones' speed
{		
	if (IsValidClient(spookmaster))
	{
		if (stanceActive)
		{
			SetEntPropFloat(spookmaster, Prop_Send, "m_flMaxspeed", 1.0);
		}
		else if (letItRIP)
		{
			SetEntPropFloat(spookmaster, Prop_Send, "m_flMaxspeed", FF2_GetArgNamedF(0, PLUGIN_NAME, SPOOKMASTER, "arg11", 520.0));
		}
	}
}
public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon,
        Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	if (IsValidClient(victim) && IsValidClient(attacker) && IsValidClient(spookmaster))
	{
		if (victim == spookmaster)
		{
			spookPower += RoundFloat(FF2_GetArgNamedI(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg113", 0) * damage);
			if (stanceActive)
			{
				damage = damage*(FF2_GetArgNamedF(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg52", 1.5));
				return Plugin_Changed;
			}
		}
		else if (TF2_GetClientTeam(victim) != TF2_GetClientTeam(spookmaster) && attacker == spookmaster)
		{
			if (repossession)
			{
				if ((FF2_GetArgNamedI(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg20", 0) == 0 && IsInvuln(victim)) || isAlreadyHit[victim])
				{
					return Plugin_Continue;
				}
				else
				{
					isAlreadyHit[victim] = true;
					TF2_StunPlayer(victim, FF2_GetArgNamedF(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg23", 3.5), 1.00, TF_STUNFLAG_SLOWDOWN|TF_STUNFLAG_THIRDPERSON|TF_STUNFLAG_GHOSTEFFECT, spookmaster);
					EmitSoundToAll("freak_fortress_2/new_spookmaster/repossession_scream.mp3", victim, _, SNDLEVEL_TRAIN);
					EmitSoundToAll("freak_fortress_2/new_spookmaster/repossession_scream.mp3", victim, _, SNDLEVEL_TRAIN);
					CreateTimer(FF2_GetArgNamedF(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg23", 3.5), bonerBomb, victim, TIMER_FLAG_NO_MAPCHANGE);
					damage = 0.0;
					return Plugin_Changed;
				}
			}
		}
	}
	return Plugin_Continue;
}
public Action bonerBomb(Handle repoSummon, int target)
{
	if (IsValidClient(target))
	{
		float vecLoc[3];
		GetClientAbsOrigin(target, vecLoc);
		
		new bigBoom = CreateEntityByName("info_particle_system");
        	
        if (IsValidEdict(bigBoom))
        {
        	TeleportEntity(bigBoom, vecLoc, NULL_VECTOR, NULL_VECTOR);
        	DispatchKeyValue(bigBoom, "effect_name", EXPLOSION_EFFECT);
 			SetVariantString("!activator");
       		DispatchKeyValue(bigBoom, "targetname", "present");
        	DispatchSpawn(bigBoom);
        	ActivateEntity(bigBoom);
        	AcceptEntityInput(bigBoom, "Start");
        }
        
        new bigBoom2 = CreateEntityByName("info_particle_system");
        	
        if (IsValidEdict(bigBoom2))
        {
        	TeleportEntity(bigBoom2, vecLoc, NULL_VECTOR, NULL_VECTOR);
        	DispatchKeyValue(bigBoom2, "effect_name", EXPLOSION_EFFECT2);
 			SetVariantString("!activator");
       		DispatchKeyValue(bigBoom2, "targetname", "present");
        	DispatchSpawn(bigBoom2);
        	ActivateEntity(bigBoom2);
        	AcceptEntityInput(bigBoom2, "Start");
        }
        
		SDKHooks_TakeDamage(target, spookmaster, spookmaster, 99999.0, DMG_CRUSH|DMG_ALWAYSGIB|DMG_BLAST);
		char stats[256];
		FF2_GetArgNamedS(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg701", stats, sizeof(stats));
		createBoner(target, FF2_GetArgNamedI(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg15", 500), FF2_GetArgNamedF(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg16", 0.0), vecLoc, FF2_GetArgNamedF(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg17", 2.0), stats);
		EmitSoundToAll("freak_fortress_2/new_spookmaster/repossession_gibsummon.mp3", target, _, SNDLEVEL_TRAIN);
		EmitSoundToAll("freak_fortress_2/new_spookmaster/repossession_gibsummon.mp3", target, _, SNDLEVEL_TRAIN);
		for (int client = 1; client <= MaxClients; client++)
		{
			if (IsValidClient(client) && FF2_GetRoundState() == 1)
			{
				if (TF2_GetClientTeam(client) != TF2_GetClientTeam(spookmaster))
				{
					float targLoc[3];
					GetClientAbsOrigin(client, targLoc);
					float distance = GetVectorDistance(vecLoc, targLoc);
					float radius = FF2_GetArgNamedF(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg21", 0.0);
					if (distance <= radius)
					{
						float damage = FF2_GetArgNamedF(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg22", 100.0);
						float falloff = FF2_GetArgNamedF(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg700", 0.0);
						if (FF2_GetArgNamedI(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg20", 0) == 0 && !IsInvuln(client))
						{
							if (falloff != 0.0)
							{
								damage = ((distance/radius) * damage)/falloff;
							}
							SDKHooks_TakeDamage(client, spookmaster, spookmaster, damage);
						}
						else if (FF2_GetArgNamedI(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg20", 0) == 1)
						{
							if (falloff != 0.0)
							{
								damage = ((distance/radius) * damage)/falloff;
							}
							SDKHooks_TakeDamage(client, spookmaster, spookmaster, damage);
							if (RoundFloat(damage) >= GetClientHealth(client) && IsInvuln(client))
							{
								FakeClientCommand(client, "explode");
							}
						}
					}
				}
			}
		}
		isAlreadyHit[target] = false;
	}

	return Plugin_Stop;
}

void createBoner(int bonerMan, int bonerHealth, float bonerLifeSpan, float vecOrigin[3], float invulnTime, char stats[256])
{
	if (IsValidClient(bonerMan))
	{
		if (!IsPlayerAlive(bonerMan))
		{
			if(FF2_GetRoundState() == 1)
			{
				if (FF2_HasAbility(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER))
				{
					FF2_SetFF2flags(bonerMan,FF2_GetFF2flags(bonerMan)|FF2FLAG_ALLOWSPAWNINBOSSTEAM);
					TF2_ChangeClientTeam(bonerMan, TFTeam_Blue);
					TF2_RespawnPlayer(bonerMan);
					TF2_AddCondition(bonerMan, TFCond_Ubercharged, invulnTime);
					
					TF2_SetPlayerClass(bonerMan, TFClass_Sniper, _, true);
					RemoveAttachable(bonerMan, "tf_wear*");
					RemoveAttachable(bonerMan, "tf_powerup_bottle");
					
					TF2_RemoveAllWeapons(bonerMan);
					FF2_SpawnWeapon(bonerMan, "tf_weapon_club", 939, 69, 3, stats, false);
					
					//SetEntProp(bonerMan, Prop_Data, "m_iMaxHealth", bonerHealth);
					//SetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", bonerHealth, _, bonerMan);
					
					SetVariantString("models/freak_fortress_2/new_spookmaster/boner_minion.mdl");
					AcceptEntityInput(bonerMan, "SetCustomModel");
					SetEntProp(bonerMan, Prop_Send, "m_bUseClassAnimations", 1);
					
					//TF2Attrib_RemoveByDefIndex(bonerMan, MAX_HEALTH_ATTRIB);
					//TF2Attrib_SetByDefIndex(bonerMan, MAX_HEALTH_ATTRIB, float(bonerHealth));
					
					/*SetEntProp(bonerMan, Prop_Data, "m_iMaxHealth", bonerHealth);
					SetEntProp(bonerMan, Prop_Data, "m_iHealth", bonerHealth);
					SetEntProp(bonerMan, Prop_Send, "m_iHealth", bonerHealth);*/
					
					BonerMaxHealth[bonerMan] = bonerHealth;
					SDKHook(bonerMan, SDKHook_GetMaxHealth, OnGetMaxHealth);
					SetEntityHealth(bonerMan, bonerHealth);
					
					TeleportEntity(bonerMan, vecOrigin, NULL_VECTOR, NULL_VECTOR);
					
					isBoner[bonerMan] = true;
					if (bonerLifeSpan > 0.0)
					{
						CreateTimer(bonerLifeSpan, bonerKill, bonerMan, TIMER_FLAG_NO_MAPCHANGE);
					}
					//SetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", bonerHealth, _, bonerMan);
				}
			}
		}
	}
}

public Action OnGetMaxHealth(int client, int &maxHealth)
{
	maxHealth = BonerMaxHealth[client];
	return Plugin_Changed;
}

public Action bonerKill(Handle bonerDeath, int boner)
{
	if (IsValidClient(boner))
	{
		if (isBoner[boner] && FF2_GetRoundState() == 1)
		{
			isBoner[boner] = false;
			SDKHooks_TakeDamage(boner, boner, boner, 999999.0);
		}
	}

	return Plugin_Stop;
}

public Action player_killed(Event hEvent, const char[] sEvName, bool bDontBroadcast) //Controls what happens when a player dies. 
{
	int victim = GetClientOfUserId(hEvent.GetInt("userid"));
	if (IsValidClient(victim) && IsValidClient(spookmaster))
	{
		isBoner[victim] = false;
		SDKUnhook(victim,  SDKHook_GetMaxHealth, OnGetMaxHealth);
		//TF2Attrib_RemoveByDefIndex(victim, MAX_HEALTH_ATTRIB);

		if (TF2_GetClientTeam(victim) != TF2_GetClientTeam(spookmaster))
		{
			spookPower += FF2_GetArgNamedI(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg100", 250);
			if (chaos)
			{
				recentDeath = true;
			}
			if (necroLord)
			{
				if (FF2_GetArgNamedI(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg40", 0) == 1)
				{
					CreateTimer(0.1, necroSummon, victim, TIMER_FLAG_NO_MAPCHANGE);
				}
				if (FF2_GetArgNamedF(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg39", 10.0) > 0.0)
				{
					float perkDur = FF2_GetArgNamedF(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg39", 10.0);
					for (int client = 1; client <= MaxClients; client++)
					{
						if (IsValidClient(client))
						{
							if (TF2_GetClientTeam(client) == TF2_GetClientTeam(spookmaster) && IsPlayerAlive(client))
							{
								GiveRandomMannpower(client, perkDur);
							}
						}
					}
				}
			}
		}
	}

	return Plugin_Continue;
}
public Action necroSummon(Handle necroSummon, int client)
{
	if (IsValidClient(client))
	{
		int necroHP = FF2_GetArgNamedI(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg44", 750);
		float necroSpan = FF2_GetArgNamedF(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg45", 0.0);
		float necroInvuln = FF2_GetArgNamedF(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg46", 2.0);
		float necroLoc[3];
		GetClientAbsOrigin(client, necroLoc);
		char stats[256];
		FF2_GetArgNamedS(FF2_GetBossIndex(spookmaster), PLUGIN_NAME, SPOOKMASTER, "arg402", stats, sizeof(stats));
		createBoner(client, necroHP, necroSpan, necroLoc, necroInvuln, stats);
	}

	return Plugin_Stop;
}
public void bonerEnd(Event hEvent, const char[] sEvName, bool bDontBroadcast)
{
	if (IsValidClient(spookmaster))
	{
		letItRIP = false;
		repossession = false;
		chaosUsed = false;
		necroUsed = false;
		chaos = false;
		necroLord = false;
		spellReady = false;
		stanceActive = false;
		recentDeath = false;
		
		spookPower = 0;
		skill = 0;
		passiveRegen = 0;
		spookmaster = 0;
		
		x = 0.0;
		y = 0.0;
		stanceTracker = 0.0;
		chaosTracker = 0.0;
		necroTracker = 0.0;
		
		if (stanceActive)
		{
			endStance();
		}
		
		for (int i = 0; i < 6; i++)
		{
			skillCD[i] = 0.0;
			skillCost[i] = 0;
		}
		
		for(int client = 1; client <= MaxClients; client++)
		{
			if (IsValidClient(client))
			{
				SDKUnhook(client, SDKHook_PreThink, spooky_preThink);
				SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
				SDKUnhook(client,  SDKHook_GetMaxHealth, OnGetMaxHealth);
				
				//TF2Attrib_RemoveByDefIndex(client, MAX_HEALTH_ATTRIB);
				
				StopSound(client, SNDCHAN_AUTO, "freak_fortress_2/new_spookmaster/boner_ragemode.mp3");
				StopSound(client, SNDCHAN_AUTO, "freak_fortress_2/new_spookmaster/boner_ragemode.mp3");
				StopSound(client, SNDCHAN_AUTO, "freak_fortress_2/new_spookmaster/boner_ragemode2.mp3");
				StopSound(client, SNDCHAN_AUTO, "freak_fortress_2/new_spookmaster/boner_ragemode2.mp3");
				StopSound(client, SNDCHAN_AUTO, "freak_fortress_2/new_spookmaster/spookmaster_bgm_original.mp3");
				StopSound(client, SNDCHAN_AUTO, "freak_fortress_2/new_spookmaster/spookmaster_bgm_original2.mp3");
				
				KeyDown[client] = false;
				KeyDown2[client] = false;
				KeyDown3[client] = false;
				mortisActive[client] = false;
				isBoner[client] = false;
				isAlreadyHit[client] = false;
				
				smashCount[client] = 0;
				BonerMaxHealth[client] = 0;
			}
		}
	}
	UnhookEvent("teamplay_round_win", bonerEnd);
	UnhookEvent("player_death", player_killed);
}
stock int GetRandomDeadPlayer()
{
	int clients[MAXPLAYERS];
	int clientCount;
	
	for(int i = 1 ; i <= MaxClients; i++)
	{
		if(IsValidClient(i) && !IsPlayerAlive(i) && FF2_GetBossIndex(i) == -1 && (TF2_GetClientTeam(i) == TFTeam_Red || TF2_GetClientTeam(i) == TFTeam_Blue))
		{
			clients[clientCount++] = i;
		}
	}
	return (clientCount == 0) ? -1 : clients[GetRandomInt(0, clientCount-1)];
}
stock bool IsValidClient(int client, bool replaycheck=true, bool onlyrealclients=true) //Function borrowed from Nolo001, credit goes to him.
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
	//if(onlyrealclients)                    Commented out for testing purposes
	//{
	//	if(IsFakeClient(client))
	//		return false;
	//}
	
	return true;
}

stock bool IsInvuln(int client) //Borrowed from Batfoxkid
{
	if(!IsValidClient(client))
		return true;

	return (TF2_IsPlayerInCondition(client, TFCond_Ubercharged) ||
		TF2_IsPlayerInCondition(client, TFCond_UberchargedCanteen) ||
		TF2_IsPlayerInCondition(client, TFCond_UberchargedHidden) ||
		TF2_IsPlayerInCondition(client, TFCond_UberchargedOnTakeDamage) ||
		TF2_IsPlayerInCondition(client, TFCond_Bonked) ||
		TF2_IsPlayerInCondition(client, TFCond_HalloweenGhostMode) ||
		//TF2_IsPlayerInCondition(client, TFCond_MegaHeal) ||
		!GetEntProp(client, Prop_Data, "m_takedamage"));
}
stock void RemoveAttachable(int client, char[] itemName)
{
	int entity;
	while((entity=FindEntityByClassname(entity, itemName))!=-1)
	{
		if(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")==client)
		{
			TF2_RemoveWearable(client, entity);
		}
	}
}

public Action FF2_OnAbility2(int boss, const char[] Plugin_Name, const char[] Ability_Name, int status)
{
	if (FF2_GetRoundState() != StateRunning)
		return Plugin_Continue;

	return Plugin_Continue;
}