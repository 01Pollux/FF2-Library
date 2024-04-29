#define FF2_USING_AUTO_PLUGIN

#include <tf2_stocks>
#include <freak_fortress_2>
#include <sdkhooks>

static FF2GameMode ff2_gm;


#define CHARGESALMON "charge_salmon"

public Plugin myinfo = {
	name = "FF2: Aqua",
	author = "Hoto Cocoa",
	version = "1.0"
}

public void OnPluginStart2()
{
	VSH2_Hook(OnRoundStart, _OnRoundStart);

	if(ff2_gm.RoundState == StateRunning) {
		FF2Player[] bosses = new FF2Player[MaxClients + 1];
		FF2Player[] mercs = new FF2Player[MaxClients + 1];
		int b_count = FF2GameMode.GetBosses(bosses, false);
		int m_count = FF2GameMode.GetBosses(mercs, false);

		_OnRoundStart(bosses, b_count, mercs, m_count);
	}
}

public void OnPluginEnd()
{
	VSH2_Unhook(OnRoundStart, _OnRoundStart);
	VSH2_Unhook(OnBossThink, ChargeSalmon_Think);
	VSH2_Unhook(OnMinionInitialized, ChargeSalmon_OnMinionInitialized);
}

void ChargeSalmon_Think(const VSH2Player player)
{
	if (ff2_gm.RoundState != StateRunning || !player.bIsBoss)
		return;

	FF2Player boss = ToFF2Player(player);

	if (boss.SuperJumpThink(2.5, 25.0))
	{
		DoSalmon(boss);
		boss.SetPropFloat("flCharge", -1000.0);
	}

	/* int client = boss.index;
	Handle chargehud = CreateHudSynchronizer();
	SetHudTextParams(-1.0, 0.88, 0.15, 255, 255, 255, 255);
	ShowSyncHudText(client, chargehud, "召唤：%i%%", RoundFloat(charge) * 4); */
}

void DoSalmon(FF2Player player)
{
	int client = player.index;

	float ratio = player.GetArgF(this_plugin_name, CHARGESALMON, "ratio");

	int alive;
	ArrayList list = new ArrayList();
	FF2Player cur_target;

	for( int i = 1; i <= MaxClients; i++ ) {
		if( IsClientInGame(i) ) {
			cur_target = FF2Player(i);

			TFTeam team = TF2_GetClientTeam(i);
			if( team != TF2_GetClientTeam(client) ) {
				if( IsPlayerAlive(i) )
					alive++;
				else if( !cur_target.GetPropInt("bIsBoss") )  //Don't let dead bosses become clones
				{
					list.Push(cur_target);
				}
			}
		}
	}

	int totalMinions = (ratio ? RoundToCeil(alive * ratio) : MaxClients);  //If ratio is 0, use MaxClients instead

	FF2Player minion;

	list.Sort(Sort_Random, Sort_Integer);

	while( list.Length > 0 && totalMinions > 0 ) {
		minion = ToFF2Player(list.Get(0));
		list.Erase(0);
		totalMinions--;

		minion.hOwnerBoss = player;
		minion.ConvertToMinion(0.1);
	}

	delete list;

	int entity, owner;
	while( (entity = FindEntityByClassname(entity, "tf_wearable")) != -1 )
		if( (owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")) <= MaxClients && owner > 0 && GetClientTeam(owner) == GetClientTeam(client) )
			TF2_RemoveWearable(owner, entity);

	while( (entity = FindEntityByClassname(entity, "tf_wearable_razorback")) != -1 )
		if( (owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")) <= MaxClients && owner > 0 && GetClientTeam(owner) == GetClientTeam(client) )
			TF2_RemoveWearable(owner, entity);

	while( (entity = FindEntityByClassname(entity, "tf_wearable_demoshield")) != -1 )
		if( (owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")) <= MaxClients && owner > 0 && GetClientTeam(owner) == GetClientTeam(client) )
			TF2_RemoveWearable(owner, entity);

	while( (entity = FindEntityByClassname(entity, "tf_powerup_bottle")) != -1 )
		if( (owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")) <= MaxClients && owner > 0 && GetClientTeam(owner) == GetClientTeam(client) )
			TF2_RemoveWearable(owner, entity);
}

public void _OnRoundStart(const VSH2Player[] bosses, const int boss_count, const VSH2Player[] red_players, const int red_count)
{
	FF2Player player;
	for(int i = 0; i < boss_count; i++) {
		player = ToFF2Player(bosses[i]);

		if (player.HasAbility(this_plugin_name, CHARGESALMON))	{

			VSH2_Hook(OnBossThink, ChargeSalmon_Think);
			VSH2_Hook(OnMinionInitialized, ChargeSalmon_OnMinionInitialized);
		}
	}
}

public void ChargeSalmon_OnMinionInitialized(const VSH2Player minion, const VSH2Player vsh2_owner)
{
	FF2Player owner = ToFF2Player(vsh2_owner);
	if (!FF2GameMode.Validate(vsh2_owner) && !vsh2_owner.HasAbility(this_plugin_name, CHARGESALMON))
		return;

	int health = 125;

	int client = minion.index;

	int class = GetEntProp(client, Prop_Send, "m_iDesiredPlayerClass");

	TF2_SetPlayerClass(client, view_as<TFClassType>(class), .persistent = false);

	minion.RemoveAllItems();
	int weapon = minion.SpawnWeapon( "tf_weapon_bat", 0, 100, 5, "" );
	SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
	SetEntProp(weapon, Prop_Send, "m_iWorldModelIndex", -1);

	SetEntProp(client, Prop_Data, "m_iMaxHealth", health);
	SetEntityHealth(client, health);

	{
		static float position[3], velocity[3];
		GetEntPropVector(owner.index, Prop_Data, "m_vecOrigin", position);

		velocity[0] = GetRandomFloat(300.0, 500.0) * (GetRandomInt(0, 1) ? 1:-1);
		velocity[1] = GetRandomFloat(300.0, 500.0) * (GetRandomInt(0, 1) ? 1:-1);
		velocity[2] = GetRandomFloat(300.0, 500.0);

		TeleportEntity(client, position, NULL_VECTOR, velocity);
		TF2_AddCondition(client, TFCond_Ubercharged, 2.0);
	}

	SetEntProp(client, Prop_Send, "m_nBody", 0);
	TF2_RegeneratePlayer(client);	//Give them normal weapons and hats.
}

void FF2_OnAbility2(const FF2Player player, const char[] abilityName, FF2CallType_t calltype)
{
	return;
}
