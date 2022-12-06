#define FF2_USING_AUTO_PLUGIN

#include <ff2_ams2>
#include <sdkhooks>

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
int SpriteAndHaloMdlIdx[2];

#define KILL_ENT_IN(%1,%2) \
	SetVariantString("OnUser1 !self:Kill::" ... #%2 ... ":1"); \
	AcceptEntityInput(%1, "AddOutput"); \
	AcceptEntityInput(%1, "FireUser1");

public void OnPluginStart2()
{
	HookEvent("arena_round_start", Post_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("arena_win_panel", Post_RoundEnd, EventHookMode_PostNoCopy);
}

public void OnMapStart()
{
	SpriteAndHaloMdlIdx[0] = PrecacheModel("sprites/laser.vmt");
	SpriteAndHaloMdlIdx[1] = PrecacheModel("sprites/halo01.vmt");
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

	// how many victims. prepare value
	int numofvictims = player.GetArgI(this_plugin_name, ABILITY_SMITE, "numbers", 3);
	float radius = player.GetArgF(this_plugin_name, ABILITY_SMITE, "radius", 300.0);
	float warningtime = player.GetArgF(this_plugin_name, ABILITY_SMITE, "warningtime", 2.0);


	int[] victims = new int[numofvictims];
	// Get random victim indies.
	for(int i = 0; i < numofvictims; i++)
	{
		if (i == 0)
		{
			victims[i] = GetRandomClient(true, VSH2Team_Red);
			continue;
		}
		
		victims[i] = GetRandomClient(true, VSH2Team_Red);
		// loop until we get a different alive victim.
		while(victims[i] == victims[i-1])
		{
			victims[i] = GetRandomClient(true, VSH2Team_Red);
		}
	}

	Smite_Start(client, victims, radius, warningtime);
}

void Smite_Start(const int boss_clientindex, const int clients[], float radius, float warningtime)
{
	int clients_size = GetArraySize(clients);
	float vec[clients_size][3];
	for(int i = 0; i < clients_size; i++)
	{
		// show warning becaon.
		GetClientAbsOrigin(clients[i], vec[i]);
		TE_SetupBeamRingPoint(
			vec,
			10.0,
			radius,
			SpriteAndHaloMdlIdx[0],
			SpriteAndHaloMdlIdx[1],
			0,
			15,
			warningtime,
			5.0,
			0.1,
			{25, 25, 112, 255},
			10,
			0
		);
		TE_SendToAll();
	}

	DataPack pack;
	CreateDataTimer(warningtime, Timer_DoSmite, pack);
	pack.WriteCellArray(clients, clients_size);
	pack.WriteCell(clients_size);
	pack.WriteFloatArray(vec, sizeof(vec));
	pack.WriteFloat(radius);
	pack.WriteCell(boss_clientindex);
}

Action Timer_DoSmite(Handle timer, DataPack pack);
{
	pack.Reset();
	int clients_size = pack.ReadCell();
	int boss_clientindex = pack.ReadCell();
	float radius = pack.ReadFloat();

	int clients[clients_size];	pack.ReadCellArray(clients, clients_size);
	float vec[clients_size][3];	pack.ReadFloatArray(vec, clients_size);
	delete pack;

	for(int i = 0; i < clients_size; i++)
	{
		float origin[3];
		GetClientAbsOrigin(clients[i], origin);
		// check if player is still in radius.
		float cal[3];
		cal[0] = origin[0] - vec[i][0];
		cal[2] = origin[2] - vec[i][2];

		bool shouldbesmite;
		if ( (-radius > cal[0] > radius) && (-radius > cal[2] > radius) )
			shouldbesmite = true;

		if (shouldbesmite)
		{
			// you are still in the radius after the countdown!
			SmiteYou(boss_clientindex, client[i]);
		}
	}
}

void SmiteYou(const int client, const int victim)
{
	SDKHooks_TakeDamage(
		victim, 
		client,
		client,
		999.0,
		DMG_GENERIC,
		GetPlayerWeaponSlot(client, TFWeaponSlot_Melee)
	);
	RequestFrame(Smite_Post, GetClientUserId(client));

	int strike[2];
	strike[0] = CreateEntityByName("info_target");
	if (strike[0] <= MaxClients)
		return;

	KILL_ENT_IN(strike[0], 0.25)

	strike[1] = CreateEntityByName("info_target");
	if (strike[1] <= MaxClients)
		return;

	KILL_ENT_IN(strike[1], 0.25)

	float pos[3];
	GetClientAbsOrigin(victim, pos);
	pos[2] += 32.0;
	TeleportEntity(strike[0], pos, NULL_VECTOR, NULL_VECTOR);
	pos[2] += 1024.0;
	TeleportEntity(strike[1], pos, NULL_VECTOR, NULL_VECTOR);

	int beam = ConnectWithBeam(strike[1], strike[0]);
	KILL_ENT_IN(beam, 0.5)
}

void Smite_Post(int uid)
{
	int client = GetClientOfUserId(uid);
	if (!client)	return;

	int ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if (ragdoll <= MaxClients)
		return;

	int disssolver = CreateEntityByName("env_entity_dissolver");
	if (disssolver <= MaxClients)
		return;

	DispatchKeyValue(disssolver, "dissolvetype", "0");
	DispatchKeyValue(disssolver, "magnitude", "1");
	DispatchKeyValue(disssolver, "target", "!activator");
	AcceptEntityInput(disssolver, "Disssolve", ragdoll);
	AcceptEntityInput(disssolver, "Kill");
}

// yoink
stock int ConnectWithBeam(int iEnt, int iEnt2, int iRed=255, int iGreen=255, int iBlue=255, float fStartWidth=1.0, float fEndWidth=1.0, float fAmp=1.35){
	int iBeam = CreateEntityByName("env_beam");
	if(iBeam <= MaxClients)
		return -1;

	if(!IsValidEntity(iBeam))
		return -1;

	SetEntityModel(iBeam, LASERBEAM);
	char sColor[16];
	Format(sColor, sizeof(sColor), "%d %d %d", iRed, iGreen, iBlue);

	DispatchKeyValue(iBeam, "rendercolor", sColor);
	DispatchKeyValue(iBeam, "life", "0");

	DispatchSpawn(iBeam);

	SetEntPropEnt(iBeam, Prop_Send, "m_hAttachEntity", EntIndexToEntRef(iEnt));
	SetEntPropEnt(iBeam, Prop_Send, "m_hAttachEntity", EntIndexToEntRef(iEnt2), 1);

	SetEntProp(iBeam, Prop_Send, "m_nNumBeamEnts", 2);
	SetEntProp(iBeam, Prop_Send, "m_nBeamType", 2);

	SetEntPropFloat(iBeam, Prop_Data, "m_fWidth", fStartWidth);
	SetEntPropFloat(iBeam, Prop_Data, "m_fEndWidth", fEndWidth);

	SetEntPropFloat(iBeam, Prop_Data, "m_fAmplitude", fAmp);

	SetVariantFloat(32.0);
	AcceptEntityInput(iBeam, "Amplitude");
	AcceptEntityInput(iBeam, "TurnOn");
	return iBeam;
}