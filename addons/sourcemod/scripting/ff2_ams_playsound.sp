#include <ff2_ams2>

/* In new vsh2_ff2 cfg. use "ability_serverwide" under "sound" section. In old ff2 cfg, use "sound_ability_serverwide". This plugin is meant to be used for AMS2 bosses. */

public Plugin myinfo =
{
	name		= "[FF2_AMS2] AMS Boss ServerWide Sound",
	author		= "HotoCocoa",
	version 	= "1.0",
};

public void FF2AMS_OnAbility(int client, const StringMap data)
{
    FF2Player player = FF2Player(client);

    FF2SoundIdentity buffer;
    if ( player.RandomSound("ability_serverwide", buffer) ) {
        player.PlayVoiceClip(buffer.path, VSH2_VOICE_RAGE);
    }
}