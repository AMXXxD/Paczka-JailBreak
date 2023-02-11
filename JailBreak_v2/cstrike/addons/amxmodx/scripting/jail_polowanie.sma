#include <amxmodx>
#include <amxmisc>
#include <fun>
#include <cstrike>
#include <jailbreak>

#define PLUGIN "[Jail] Polowanie"
#define VERSION "1.0.6"
#define AUTHOR "Cypis"

new id_polowanie;

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)

	id_polowanie = jail_register_game("Polowanie");
}

public OnDayStartPre(day, szInfo[256], szInfo2[512], setting[10], gTimeRound)
{	
	static szTime[12];
	if(day == id_polowanie)
	{
		format_time(szTime, 11, "%M:%S", gTimeRound-30);
		formatex(szInfo2, 511, "Zasady TT:^nTT ucieka przed CT i moga kampic^nOstatni wiezien ma zyczenie^n^nZasady CT:^nCT zabija TT tylko z AWP i SCOUT^nCT czeka do %s w GunRoomie", szTime);
		formatex(szInfo, charsmax(szInfo), "× Dzisiaj jest Polowanie^n^n× Zasady TT:^nTT ucieka przed CT i moga kampic^nOstatni wiezien ma zyczenie^n^nZasady CT:^nCT zabija TT tylko z AWP i SCOUT^nCT czeka do %s w GunRoomie", szTime);
		
		for(new i=1; i<=MAX; i++)
		{
			if(!is_user_connected(i) || !is_user_alive(i) || cs_get_user_team(i) != CS_TEAM_CT)
				continue;
			
			strip_user_weapons(i);
			give_item(i, "weapon_awp");
			give_item(i, "weapon_scout");
			cs_set_user_bpammo(i, CSW_AWP, 100);
		}
		jail_set_prisoners_micro(true, true);
		jail_set_ct_hit_tt(true);
		jail_set_god_ct(true);
		
		setting[0] = 1;
		setting[1] = 1;
		setting[2] = 1;
		setting[4] = 3;
	}
}

public OnDayStartPost(day)
{
	if(day == id_polowanie)
	{
		jail_set_all_speed(0.1, 2) //blokowanie chodzenia ct
		
		jail_open_cele();
		jail_set_game_hud(30, "Rozpoczecie zabawy za");
	}
}

public OnGameHudEnd(day)
{
	if(day == id_polowanie)
	{
		jail_set_ct_hit_tt(false);
		jail_set_all_speed(250.0, 2) //ustawienie chodzenia ct
	}
}

//stock
stock jail_set_all_speed(Float:speed, team)
{
	for(new i=1; i<=MAX; i++)
	{
		if(!is_user_alive(i) || !is_user_connected(i) || get_user_team(i) != team)
			continue;
			
		jail_set_user_speed(i, speed);
	}
}

