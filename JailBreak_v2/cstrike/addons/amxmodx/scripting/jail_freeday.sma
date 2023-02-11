#include <amxmodx>
#include <amxmisc>
#include <jailbreak>

#define PLUGIN "[Jail] FreeDay"
#define VERSION "1.0.6"
#define AUTHOR "Cypis"

new id_freeday;

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	id_freeday = jail_register_game("FreeDay dla Wszystkich");
}

public plugin_precache()
{
	precache_sound("jb_cypis/freeday.wav");
}

public OnLastPrisonerShowWish(id)
{
	jail_remove_game_hud();
}

public OnRemoveData(day)
{
	jail_remove_game_hud();
}

/*
setting[0] - zyczenie, jak ustawimy na 1 to ostatni wieznien bedzie mial zyczenie, jak na 2 to nie bedzie mial zyczenia
setting[1] - prowadzacy, jak na 1 ustawimy to nie bedzie mozna prowadzacego
setting[2] - poszukiwany, jak na 1 ustawimy to nie bedzie poszukiwanych

//setting[3] - nie u¿ywane od wersji 1.0.4!!!

setting[4] - jak na 1 ustawiomy to tt nie beda mogli podnosic broni i dropowac broni, blokuje automaty z broniami zeby nie bylo mozna znich broni brac, jak na 2 to ct nie beda mogli ..., jak na 3 to oba teamy nie beda mogli ...

//setting[5] - nie u¿ywane od wersji 1.0.6!!!

setting[6] - antykamper, jak na 1 to po 15s zaczyna gracz tracic HP za kampienie
setting[7] - nieskonczone bpammo 1 - tylko tt, 2 - tylko ct, 3 - oba teamy
*/

public OnDayStartPre(day, szInfo[256], szInfo2[512], setting[10], gTimeRound)
{	
	if(day == NIEDZIELA || day == id_freeday)
	{
		jail_set_prowadzacy(0);
		jail_set_prisoners_micro(true, true);
			
		setting[0] = 2;
		setting[1] = 1;
		setting[2] = 1;
	}
	else if(day == USUWANIE_DANYCH) //narazie jest to nie uzywane ale moze sie przydac do usuwania danych :) 
	{
		szInfo = "";
		szInfo2 = "";
		
		jail_set_god_tt(false);
		jail_set_god_ct(false);
		jail_set_ct_hit_tt(false);
		jail_set_tt_hit_ct(false);
		
		setting[0] = 0;
		setting[1] = 0;
		setting[2] = 0;
		setting[3] = 0;
		setting[4] = 0;
		setting[5] = 0;
		setting[6] = 0;
		setting[7] = 0;
	}
}

public OnDayStartPost(day)
{
	if(day == NIEDZIELA || day == id_freeday)
	{
		client_cmd(0, "spk JailBreak_Izolatka/freeday.wav");
			
		jail_open_cele();
		jail_set_game_hud(240, "^n^n^n^n^nDzisiaj jest FreeDay", 0, 255, 0, 0.01, 0.2);
	}
}

public OnGameHudEnd(day)
{
	if(day == NIEDZIELA || day == id_freeday)
	{
		for(new i=1; i<=MAX; i++)
		{
			if(is_user_alive(i) && is_user_connected(i))
				user_kill(i);
		}
	}
}
