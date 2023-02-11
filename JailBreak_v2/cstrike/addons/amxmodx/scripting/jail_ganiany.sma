#include <amxmodx>
#include <amxmisc>
#include <fun>
#include <jailbreak>

#define PLUGIN "[Jail] Ganiany"
#define VERSION "1.0.6"
#define AUTHOR "Cypis"

new id_ganiany;
new bool:usun;

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	id_ganiany = jail_register_game("Ganiany");
}

public OnDayStartPre(day, szInfo[256], szInfo2[512], setting[10], gTimeRound)
{	
	static szTime[12];
	if(day == id_ganiany)
	{
		format_time(szTime, 11, "%M:%S", gTimeRound-30);
		formatex(szInfo2, 511, "Zasady:^n%s - Straznicy zaczynaja ganiac wiezniow^nOstatni wiezien ma zyczenie", szTime);
		formatex(szInfo, charsmax(szInfo), "× Dzisiaj jest Ganiany^n^n× Zasady:^n%s - Straznicy zaczynaja ganiac wiezniow^nOstatni wiezien ma zyczenie", szTime);
			
		for(new i=1; i<=MAX; i++)
		{
			if(!is_user_connected(i) || !is_user_alive(i) || get_user_team(i) != 2)
				continue;
			
			strip_user_weapons(i);
			give_item(i, "weapon_knife");
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
	if(day == id_ganiany)
	{
		jail_set_all_speed(0.1, 2) //blokowanie chodzenia ct
		
		jail_open_cele();
		jail_set_game_hud(30, "Rozpoczecie zabawy za");
	}
}

public OnGameHudEnd(day)
{
	if(day == id_ganiany)
	{
		if(!usun)
		{
			jail_set_ct_hit_tt(false);
			jail_set_all_speed(300.0, 2) //ustawienie chodzenia ct
			
			jail_set_game_hud(300, "Zakonczenie zabawy za");
		}
		else
		{
			jail_set_play_game(USUWANIE_DANYCH, true);
		}
		usun = !usun;
	}
}

public OnRemoveData(day)
{
	usun = false;
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

