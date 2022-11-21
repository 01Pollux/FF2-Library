#define FF2_USING_AUTO_PLUGIN

#include <ff2_ams2>

bool Ability_IsAMS[MAXPLAYERS + 1];
FF2GameMode ff2_gm;

methodmap MyAMSPlayer < FF2Player {
	public MyAMSPlayer(const int index, bool userid = false)	{
		return view_as<MyAMSPlayer>(FF2Player(index, userid));
	}

	public static MyAMSPlayer FromPlayer(any player)	{
		return view_as<MyAMSPlayer>(player);
	}
}

public Plugin myinfo = {
    name = "[FF2] AMS2 : Smite",
    author = "HotoCocoaco",
    version = "1.0",
};

#define ABILITY_SMITE		"rage_smite"	// ability name
#define ABILITY_PREFIX	"SMITE"	// abbreviation of ability name

//Ability args.
#define SMITE_SOUND "ambient_mp3/halloween/thunder_04.mp3"
int Smite_Number;	//how many victims should we have.
float Smite_Radius;	//pick victims in this range.

public void OnPluginStart2()
{
	HookEvent("arena_round_start", Post_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("arena_win_panel", Post_RoundEnd, EventHookMode_PostNoCopy);
}

public Action FF2_OnAbility2(FF2Player boss, const char[] ability, FF2CallType_t ct)
{
	if (ff2_gm.RoundState != StateRunning)
		return Plugin_Continue;

	if (!strcmp(ability, ABILITY_SMITE))	{
		int client = boss.index;
		if (!Ability_IsAMS[client])	{
			SMITE_Invoke(client, null);	// Activate RAGE normally.
		}
	}

	return Plugin_Continue;
}

public void Post_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if (ff2_gm.RoundState != StateRunning)
		return;

	Prep_StartAbilities();
}

public void FF2AMS_PreRoundStart(int client)
{
	MyAMSPlayer player = MyAMSPlayer(client);
	if (player.HasAbility(this_plugin_name, ABILITY_SMITE))	{
		Ability_IsAMS[client] = FF2AMS_PushToAMS(client, this_plugin_name, ABILITY_SAMPLE, ABILITY_PREFIX);	// return true if pusing ams2 was successful
	}
}

void Prep_StartAbilities()
{
	for(int client = 1; client <= MaxClients; client++)
	{
	  if (!IsClientInGame(client))
			continue;


	}
	//Prepare Value?
}

public void Post_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	for(int client = 1; client <= MaxClients; client++)
	{
	  if (IsClientInGame(client))	{
			Ability_IsAMS[client] = false;	//cleanup
		}
	}
}

public AMSResult SMITE_CanInvoke(int client, StringMap hMap)
{
	return AMS_Accept;
}

public void SMITE_Invoke(int client, StringMap hMap)
{
	// Rage code.
	MyAMSPlayer player = MyAMSPlayer(client);


}
