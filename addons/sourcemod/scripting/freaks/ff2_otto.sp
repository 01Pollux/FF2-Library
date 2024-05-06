#define FF2_USING_AUTO_PLUGIN

#include <freak_fortress_2>
#include <tf2_stocks>

public Plugin myinfo = {
	name = "FF2: OTTO",
	author = "Hoto Cocoa",
	version = "1.0"
}

#define OTTO_ABILITY "special_pickup"

public void OnPluginStart2()
{
	if (!VSH2_HookEx(OnBossPickUpItem, OTTO_OnBossPickUpItem))
	{
		LogError("OTTO failed to vsh2_hook OnBossPickUpItem");
		return;
	}
}

public void OnPluginEnd()
{
	if (!VSH2_UnhookEx(OnBossPickUpItem, OTTO_OnBossPickUpItem))
	{
		LogError("OTTO failed to vsh2_unhook OnBossPickUpItem");
		return;
	}
}

void OTTO_OnBossPickUpItem(const VSH2Player player, const char item[64])
{
	// 虽然写的是OnBossPickUpItem，但是这个player不一定是boss，这个命名上有错误的。
	// 虽然我们可以做点什么，但是必须确保红队捡起弹药箱或者血包的时候，他们对抗的BOSS之一有这个能力。
	bool boss_has_ability;

	FF2Player[] bosses = new FF2Player[MaxClients];
	FF2Player the_boss;
	int num = FF2GameMode.GetBosses(bosses, true);
	if (num)
	{
		for(int i = 0; i <= num; i++)
		{
			if (bosses[i].HasAbility(this_plugin_name, OTTO_ABILITY))
			{
				boss_has_ability = true;
				the_boss = bosses[i];
				break;
			}
		}
	}

	if (boss_has_ability)
	{
		// 已确认当前BOSS之一，有这个插件的这个能力。
		// 我们要验证是否为血包。
		if (StrContains(item, "medkit") != -1)
		{
			// 玩家是捡起了血包。
			// 概率吃史。
			int chance = the_boss.GetArgI(this_plugin_name, OTTO_ABILITY, "chance", 100);
			if (GetRandomInt(1, 100) <= chance)
			{
				float duration = the_boss.GetArgF(this_plugin_name, OTTO_ABILITY, "duration", 5.0);
				TF2_MakeBleed(player.index, the_boss.index, duration);
			}
		}
	}
}

public void FF2_OnAbility2(const FF2Player player, const char[] abilityName, FF2CallType_t calltype)
{
	return;
}