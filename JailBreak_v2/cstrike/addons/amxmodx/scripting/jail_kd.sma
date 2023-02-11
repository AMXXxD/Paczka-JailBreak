#include <amxmodx>
#include <amxmisc>
#include <fun>
#include <cstrike>
#include <jailbreak>

#define PLUGIN "[Jail] KillDay"
#define VERSION "1.0.6"
#define AUTHOR "Cypis"

new const maxAmmo[31] = {0,52,0,90,1,31,1,100,90,1,120,100,100,90,90,90,100,120,30,120,200,31,90,120,90,2,35,90,90,0,100};
new const idWeapons[] = {3,5,7,8,12,13,14,15,18,19,20,21,22,23,27,28,30};

new id_killday;

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	id_killday = jail_register_game("KillDay");
}

public OnDayStartPre(day, szInfo[256], szInfo2[512], setting[10], gTimeRound)
{	
	static szTime[12];
	if(day == PIATEK || day == id_killday)
	{
		static szTimes[12];
		format_time(szTime, 11, "%M:%S", gTimeRound-30);
		format_time(szTimes, 11, "%M:%S", gTimeRound-60);
		formatex(szInfo, charsmax(szInfo), "× Dzisiaj jest KillDay^n^n× Zasady:^n%s - wiezniowie dostaja bron^n%s - walka wiezniow miedzy soba^nGrupy moga byc maksymalnie 2 osobowe!^nZakaza leczenia sie^nOstatni wiezien ma zyczenie", szTime, szTimes);
					
		jail_set_prisoners_micro(true, true);
		jail_set_ct_hit_tt(true);
		jail_set_god_ct(true);
			
		setting[0] = 1;
		setting[1] = 1;
		setting[2] = 1;
		setting[4] = 1;
		setting[6] = 1;
		setting[7] = 1;
	}
}

public OnDayStartPost(day)
{
	if(day == PIATEK || day == id_killday)
	{
		jail_open_cele();
		jail_set_game_hud(60, "Rozpoczecie zabawy za");
	}
}

public OnGameHudTick(day, count)
{
	if(count != 30)
		return;
		
	if(day != PIATEK && day != id_killday)
		return;
	
	new nameweapon[24], wid = idWeapons[random(charsmax(idWeapons))];
	get_weaponname(wid, nameweapon, 23);
	
	for(new i=1; i<=MAX; i++)
	{
		if(!is_user_alive(i) || !is_user_connected(i) || cs_get_user_team(i) != CS_TEAM_T)
			continue;
		
		strip_user_weapons(i);
		give_item(i, "weapon_knife");
		give_item(i, "weapon_glock18");
		give_item(i, nameweapon);
		
		cs_set_user_bpammo(i, wid, maxAmmo[wid]);
		cs_set_user_bpammo(i, CSW_GLOCK18, maxAmmo[CSW_GLOCK18]);
	}
}

public OnGameHudEnd(day)
{
	if(day == PIATEK || day == id_killday)
	{
		set_hudmessage(255, 0, 0, -1.0, -1.0, 0, 6.0, 5.0);
		show_hudmessage(0, "== Wiezniowie vs Wiezniowie ==");
			
		jail_set_prisoners_fight(true, false, false);
	}
}
