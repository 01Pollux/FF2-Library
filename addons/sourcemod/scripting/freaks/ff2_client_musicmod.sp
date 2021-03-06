#pragma semicolon 1
#define FF2_USING_AUTO_PLUGIN

#include <tf2items>
#include <tf2_stocks>
#include <freak_fortress_2>

#pragma newdecls required

#define ABILITY_INFO this_plugin_name, "special_changebgm_onclientmatch"

//	"steam ids"		"... ; ... ; ..."
//	"redirect"		"sound_bgm_..."

enum struct Music_Info_t 
{
	FF2Player player;
	char redirect[64];
}

methodmap MusicList < ArrayList {
	public MusicList()
	{
		return view_as<MusicList>(new ArrayList(ByteCountToCells(sizeof(Music_Info_t))));
	}
	
	public void InsertPlayer(const FF2Player player, const char[] redirect)
	{
		Music_Info_t infos;
		infos.player = player;
		strcopy(infos.redirect, sizeof(Music_Info_t::redirect), redirect);
		this.PushArray(infos, sizeof(Music_Info_t));
	}
	
	public void GetMusic(const int index, Music_Info_t infos)
	{
		this.GetArray(index, infos, sizeof(Music_Info_t));
	}
	
	public bool FindPlayer(const FF2Player player, Music_Info_t infos)
	{
		for(int i; i < this.Length; i++)
		{
			this.GetMusic(i, infos);
			if(player == infos.player)
				return true;
		}
		return false;
	}
}

MusicList music_list;

public Plugin myinfo = {
    name = "Freak Fortress 2: Boss Client Music Modifier",
    author = "Koishi (SHADoW NiNE TR3S), Remodified by 01Pollux",
    version = "1.0",
};

public void OnLibraryAdded(const char[] name)
{
	if(!strcmp(name, "VSH2")) {
		VSH2_Hook(OnRoundStart, _OnRoundStart);
		HookEvent("arena_win_panel", _OnRoundEnd);
	}
}

public void OnLibraryRemoved(const char[] name)
{
	if(!strcmp(name, "VSH2")) {
		VSH2_Unhook(OnRoundStart, _OnRoundStart);
		UnhookEvent("arena_win_panel", _OnRoundEnd);
	}
}

public void OnPluginStart2()
{
	
}

public void FF2_OnAbility2(FF2Player player, const char[] ability_name, FF2CallType_t action) 
{
    // nothing to see here
}

public void _OnRoundStart(const VSH2Player[] bosses, const int boss_count, const VSH2Player[] red_players, const int red_count)
{
	static char steamID[64], wantedIDs[1024];
	FF2Player player;
	for(int i; i < boss_count; i++)
	{
		player = ToFF2Player(bosses[i]);
		if(player.HasAbility(ABILITY_INFO))
		{
			if(!player.GetArgS(ABILITY_INFO, "steam ids", wantedIDs, sizeof(wantedIDs)))
				continue;
			
			if(!music_list) {
				music_list = new MusicList();
			}
			
			if(!GetClientAuthId(player.index, AuthId_Steam2, steamID, sizeof(steamID), true))
				continue;
			
			char[][] steamIDPool = new char[16][64];
			int count = ExplodeString(wantedIDs, " ; ", steamIDPool, 16, 64);
			for(int j; j < count; j++)
			{
				if(!strcmp(steamIDPool[j], steamID))
				{
					player.GetArgS(ABILITY_INFO, "redirect", wantedIDs, sizeof(wantedIDs));
					music_list.InsertPlayer(player, wantedIDs);
					break;
				}
			}
		}
	}
}

public void _OnRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	delete music_list;
}

public Action FF2_OnMusic(const FF2Player player, char[] upcoming_song, float &time)
{
	if(!music_list)
		return Plugin_Continue;
	
	static Music_Info_t infos;
	if(!music_list.FindPlayer(player, infos))
		return Plugin_Continue;
	
	StringMap cache = player.SoundCache;
	ArrayList sound_list;
	if(cache && cache.GetValue(infos.redirect, sound_list) && sound_list)
	{
		int size = sound_list.Length;
		if(!size)
			return Plugin_Continue;
			
		FF2SoundIdentity id;
			
		int pos = GetRandomInt(0, size - 1);
		sound_list.GetArray(pos, id, sizeof(FF2SoundIdentity));
			
		strcopy(upcoming_song, sizeof(FF2SoundIdentity::path), id.path);
		time = id.time;
		
		FPrintToChatAll("Now Playing: {blue}%s{default} - {orange}%s{default}", 
						!id.name ? "Unknown Song":id.name, 
						!id.artist ? "Unknown Artist":id.artist);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
