#include <amxmodx> 
#include <amxmisc> 
#include <cstrike>
#include <fun>
#include <fakemeta_util>
#include <hamsandwich>
#include <engine>
#include <fakemeta>
#include <jailbreak>

native jail_menu_zabaw(id);
native jail_menu_przyslowia(id);
native jail_menu_stolice(id);
native jail_ruletka(id);
native jail_menu_szlugi(id);
native jail_opis_vip(id);
native jail_opis_svip(id);
native jail_menuozyw(id);
native jail_startvote(id);
native jail_dajszlugi(id);

#define PLUGIN "Jail Menu"
#define VERSION "1.0.6"
#define AUTHOR "Cypis"

new w_trakcie[33];

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_event("Damage", "Damage", "b", "2!=0");
	register_event("ResetHUD", "SpawnPlayer", "be")
	
	register_clcmd("+revision", "wlacz_rewizje");
	register_clcmd("-revision", "wylacz_rewizje");
	register_clcmd("say /menu", "MenuGraczy");
	register_clcmd("say /a", "MenuAdmina");	
}

public plugin_precache()
{
	precache_sound("weapons/c4_disarm.wav");
	precache_sound("weapons/c4_disarmed.wav");
}

public SpawnPlayer(id)
{
	w_trakcie[id] = 0;
	remove_task(5000+id);
}

public MenuGraczy(id)
{
	if(!is_user_alive(id))
	{
		MenuGraczaNieZywego(id);
		return PLUGIN_HANDLED;
	}
	
	switch(get_user_team(id))
	{
		case 1: MenuGraczaTT(id);
		case 2: MenuGraczaCT(id);
	}
	return PLUGIN_HANDLED;
}

public MenuGraczaTT(id)
{
	new menu = menu_create(fmt("\d%s | Menu^n\r[MENU]\w Menu Wieznia:", forum), "Handel_Menu");
		
	menu_additem(menu, "\d×\w Daj Szlugi", 		"0");		
	menu_additem(menu, "\d×\w Czapki", 		"1");
	menu_additem(menu, "\d×\w Kradziez Broni", 	"2");
	menu_additem(menu, "\d×\w Sklep", 	"3");
	menu_additem(menu, "\d×\w Ruletka", 	"4");
	menu_additem(menu, "\d×\w Wylacz Muzyke", 	"5");
	menu_additem(menu, "\d×\w Opis VIP'a", 	"6");
	menu_additem(menu, "\d×\w Opis SVIP'a", 	"7");
	
	menu_setprop(menu, MPROP_BACKNAME, "\d×\w Wroc");
	menu_setprop(menu, MPROP_NEXTNAME, "\d×\w Dalej");
	menu_setprop(menu, MPROP_EXITNAME, "\d×\w Wyjdz");
	menu_display(id, menu);
}

public MenuGraczaCT(id)
{
	new menu = menu_create(fmt("\d%s | Menu^n\r[MENU]\w Menu Straznik:", forum), "Handel_Menu");
	new cb = menu_makecallback("Menu_Callback");
	
	menu_additem(menu, "\d×\w Prowadz", 			"8", 1, cb);
	menu_additem(menu, "\d×\r Przeszukaj\w Wieznia", 	"9");
	menu_additem(menu, "\d×\w Otworz Cele", 		"10", 2, cb);
	menu_additem(menu, "\d×\w Tryb Walki", 			"11", 3, cb);
	menu_additem(menu, "\d×\w Mikro TT", 			"12", 3, cb);
	menu_additem(menu, "\d×\w Zabawy", 				"13", 3, cb);
	menu_additem(menu, "\d×\w FreeDay & Duszek",	"14", 3, cb);
	menu_additem(menu, "\d×\w Menu muzyk", 			"15");
	menu_additem(menu, "\d×\w Ozyw Gracza", 		"30");	
	menu_additem(menu, "\d×\w Czapki", 				"1");
	menu_additem(menu, "\d×\w Ruletka",	 			"4");
	menu_additem(menu, "\d×\w Opis VIP'a", 			"6");
	menu_additem(menu, "\d×\w Opis SVIP'a", 		"7");
	
	menu_setprop(menu, MPROP_BACKNAME, "\d×\w Wroc");
	menu_setprop(menu, MPROP_NEXTNAME, "\d×\w Dalej");
	menu_setprop(menu, MPROP_EXITNAME, "\d×\w Wyjdz");
	menu_display(id, menu);
}

public MenuGraczaNieZywego(id)
{
	new menu = menu_create(fmt("\d%s | Menu^n\r[MENU]\w Menu Martwego:", forum), "Handel_Menu");

	menu_additem(menu, "\d×\w TOP 15", 			"16");
	menu_additem(menu, "\d×\w Bindy", 			"17");
	menu_additem(menu, "\d×\w Opis VIP'a", 		"6");
	menu_additem(menu, "\d×\w Opis SVIP'a", 	"7");
	menu_additem(menu, "\d×\w Regulamin", 		"18");

	menu_setprop(menu, MPROP_BACKNAME, "\d×\w Wroc");
	menu_setprop(menu, MPROP_NEXTNAME, "\d×\w Dalej");
	menu_setprop(menu, MPROP_EXITNAME, "\d×\w Wyjdz");
	menu_display(id, menu);
}

public cmd_zabawy(id)
{
	new menu = menu_create(fmt("\d%s | Menu^n\r[MENU]\w Menu Gier:", forum), "Handel_Menu");

	menu_additem(menu, "\d×\w Zabawy^n", 		"19");
	menu_additem(menu, "\d×\w Stolice", 		"20");
	menu_additem(menu, "\d×\w Przyslowia", 		"21");

	menu_setprop(menu, MPROP_BACKNAME, "\d×\w Wroc");
	menu_setprop(menu, MPROP_NEXTNAME, "\d×\w Dalej");
	menu_setprop(menu, MPROP_EXITNAME, "\d×\w Wyjdz");
	menu_display(id, menu);
}

public MenuAdmina(id)
{
	if(!(get_user_flags(id) & FLAGA_ADM)){
		PokazWiadomosc(id, "Nie masz^3 dostepu!");
	}	

	new menu = menu_create(fmt("\d%s | Menu^n\r[MENU]\w Menu Admina:", forum), "Handel_Menu");
	new cb = menu_makecallback("Menu_Callback");

	menu_additem(menu, "\d×\w Otworz Cele", 		"22");
	menu_additem(menu, "\d×\w Przenies Gracza", 	"23");
	menu_additem(menu, fmt("\d×\w Mikro: %s", jail_get_prisoners_micro() ? "\rON" : "\dOFF"), "24");
	menu_additem(menu, fmt("\d×\w Walka: %s", jail_get_prisoners_fight() ? "\rON" : "\dOFF"), "25");
	menu_additem(menu, "\d×\w Ban na \rCT", 		"26");
	menu_additem(menu, "\d×\w Ozyw Gracza", 		"30");
	menu_additem(menu, "\d×\w Glosowanie na mape", 		"31");	
	menu_additem(menu, "\d×\w Menu Opiekuna", 		"27", 4, cb);	

	menu_setprop(menu, MPROP_BACKNAME, "\d×\w Wroc");
	menu_setprop(menu, MPROP_NEXTNAME, "\d×\w Dalej");
	menu_setprop(menu, MPROP_EXITNAME, "\d×\w Wyjdz");
	menu_display(id, menu);
}

public MenuOpiekuna(id)
{
	new menu = menu_create(fmt("\d%s | Menu^n\r[MENU]\w Menu Opiekuna:", forum), "Handel_Menu");

	menu_additem(menu, "\d×\w Dodanie Cel", 		"28");
	menu_additem(menu, "\d×\w Menu \rSzlugow", 		"29");	

	menu_setprop(menu, MPROP_BACKNAME, "\d×\w Wroc");
	menu_setprop(menu, MPROP_NEXTNAME, "\d×\w Dalej");
	menu_setprop(menu, MPROP_EXITNAME, "\d×\w Wyjdz");
	menu_display(id, menu);
}

public Menu_Callback(id, menu, item)
{
	static num[10], acces, callback;
	menu_item_getinfo(menu, item, acces, num, 9, _, _, callback);
 
	switch(acces)
	{
		case 1:{
			if(jail_get_prowadzacy() || !jail_get_days()) {
				return ITEM_DISABLED;
			}
		}
		case 2:{
			if(id != jail_get_prowadzacy() && jail_get_days()) {
				return ITEM_DISABLED;
			}
		}
		case 3:{
			if(id != jail_get_prowadzacy()) {
				return ITEM_DISABLED;
			}
		}
		case 4:{
			if(!(get_user_flags(id) & FLAGA_OPA)) {
				return ITEM_DISABLED;
			}
		}	
	}
	return ITEM_ENABLED;
}

public Handel_Menu(id, menu, item)
{
	if(item == MENU_EXIT)
		return;

	new num[10], acces, callback;
	menu_item_getinfo(menu, item, acces, num, 9, _, _, callback);
	switch(str_to_num(num))
	{
		case 0: jail_dajszlugi(id);
		case 1: client_cmd(id, "say /czapki");
		case 2: cmd_kradnij(id);
		case 3: client_cmd(id, "say /sklep");
		case 4: jail_ruletka(id);
		case 5: client_cmd(id, "say /off");
		case 6: jail_opis_vip(id);
		case 7: jail_opis_svip(id);
		case 8: cmd_prowadz(id);
		case 9: w_trakcie[id] ? wylacz_rewizje(id) : wlacz_rewizje(id);
		case 10: jail_open_cele();
		case 11: cmd_Walka(id);
		case 12: cmd_Mikro(id);
		case 13: cmd_zabawy(id);	
		case 14: MenuFreeday(id);		
		case 15: client_cmd(id, "say /muzyka");	
		case 16: client_cmd(id, "say /top15");
		case 17: client_cmd(id, "say /bindy");			
		case 18: show_motd(id, "regulamin.txt", "Regulamin Serwera");
		case 19: jail_menu_zabaw(id);
		case 20: jail_menu_stolice(id);
		case 21: jail_menu_przyslowia(id);
		case 22: jail_open_cele(), MenuAdmina(id);
		case 23: client_cmd(id, "amx_teammenu");
		case 24: cmd_Mikro(id), MenuAdmina(id);	
		case 25: cmd_Walka(id), MenuAdmina(id);	
		case 26: client_cmd(id, "jail_menuban");
		case 27: MenuOpiekuna(id);	
		case 28: client_cmd(id, "jail_cele");
		case 29: jail_menu_szlugi(id);
		case 30: jail_menuozyw(id);
		case 31: jail_startvote(id);	
	}
}

public cmd_Mikro(id) {
	if(jail_get_prowadzacy() != id && !(get_user_flags(id) & ADMIN_KICK))  {
		PokazWiadomosc(id, "Ta opcja jest dostepna tylko dla prowadzacego^4 straznika!");
		return PLUGIN_HANDLED;
	}
	if(jail_get_play_game_id() >= 6) {
		PokazWiadomosc(id, "Ta opcja jest niedostepna podczas^4 zabaw!");
		return PLUGIN_HANDLED;
	}
	
	jail_set_prisoners_micro(!jail_get_prisoners_micro());
	return PLUGIN_HANDLED;
}

public cmd_Walka(id) {
	if(jail_get_prowadzacy() != id && !(get_user_flags(id) & ADMIN_KICK))  {
		PokazWiadomosc(id, "Ta opcja jest dostepna tylko dla prowadzacego^4 straznika!");
		return PLUGIN_HANDLED;
	}
	if(jail_get_play_game_id() >= 6) {
		PokazWiadomosc(id, "Ta opcja jest niedostepna podczas^4 zabaw!");
		return PLUGIN_HANDLED;
	}
	
	new bool:bWalka = !jail_get_prisoners_fight();
	jail_set_prisoners_fight(bWalka, bWalka, true);	
	return PLUGIN_HANDLED;
}

public MenuFreeday(id)
{
	new menu2 = menu_create(fmt("\d%s | Menu^n\r[MENU]\w Manager FD i Duszek:", forum), "Handel_ManagerFreeday");
	
	menu_additem(menu2, "\d×\w Daj Freeday");
	menu_additem(menu2, "\d×\w Daj Duszka^n");
			
	menu_setprop(menu2, MPROP_EXITNAME, "\d×\w Wyjdz");
	menu_display(id, menu2);
}

public Handel_ManagerFreeday(id, menu, item)
{
	if(item == MENU_EXIT)
		return;

	new acces, callback, data[3], iname[32];
	menu_item_getinfo(menu, item, acces, data, 2, iname, 31, callback);
	replace(iname, 31, "^n", "");

	new menu2 = menu_create(iname, (!item || item == 2)? "Handel_Menu_Freeday": "Handel_Menu_Duszek");
	for(new i=1; i<=32; i++)
	{
		if(!is_user_alive(i) || cs_get_user_team(i) != CS_TEAM_T)
			continue;

		switch(item)
		{
			case 0,1:{
				if(jail_get_prisoner_free(i) || jail_get_prisoner_ghost(i))
					continue;
			}
			case 2:{
				if(!jail_get_prisoner_free(i))
					continue;
			}
			case 3:{
				if(!jail_get_prisoner_ghost(i))
					continue;
			}
		}
		new name[32];
		get_user_name(i, name, 31);
		menu_additem(menu2, name, (!item || item == 1)? "1": "0");
	}
	menu_setprop(menu2, MPROP_EXITNAME, "\d×\w Wyjdz");
	menu_display(id, menu2);
}

public Handel_Menu_Freeday(id, menu, item)
{
	if(item == MENU_EXIT)
		return;

	new id2, callback, data[3], name[32];
	menu_item_getinfo(menu, item, id2, data, 2, name, 31, callback);
	callback = data[0]-'0';

	id2 = get_user_index(name);
	jail_set_prisoner_free(id2, bool:callback, false);
	
	new szName[2][32];
	get_user_name(id, szName[0], 31);
	get_user_name(id2, szName[1], 31);
	PokazWiadomosc(0, "^3 %s ^x01%s freedaya ^x03%s", szName[0], callback? "dal": "zabral",szName[1]);
}

public Handel_Menu_Duszek(id, menu, item)
{
	if(item == MENU_EXIT)
		return;
		
	new id2, callback, data[3], name[32];
	menu_item_getinfo(menu, item, id2, data, 2, name, 31, callback);
	callback = data[0]-'0';
	
	id2 = get_user_index(name);
	jail_set_prisoner_ghost(id2, bool:callback, false);
	
	new szName[2][32];
	get_user_name(id, szName[0], 31);
	get_user_name(id2, szName[1], 31);
	PokazWiadomosc(0,"^3 %s ^x01%s duszka ^x03%s", szName[0], callback? "dal": "zabral",szName[1]);
}

public wlacz_rewizje(id)
{
	if(get_user_team(id) != 2 || !is_user_alive(id))
		return PLUGIN_HANDLED;
		
	new body, target;
	get_user_aiming(id, target, body, 50);
						
	if(target && get_user_team(target) == 2)
	{
		PokazWiadomosc(id, "Nie nacelowales na ^3wieznia");
		return PLUGIN_HANDLED;
	}
	if(!is_user_alive(target))
		return PLUGIN_HANDLED;
		
	if(jail_get_user_block(target))
		return PLUGIN_HANDLED;
	
	jail_set_user_speed(id, 0.1);
	set_bartime(id, 5);
	
	set_bartime(target, 5);
	jail_set_user_speed(target, 0.1);
	
	w_trakcie[id] = target;
	w_trakcie[target] = id;
	set_task(5.0, "wylacz_rewizje", 5000+id);
	emit_sound(id, CHAN_WEAPON, "weapons/c4_disarm.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);
	return PLUGIN_HANDLED;
}

public wylacz_rewizje(taskid)
{
	new id = taskid;
	if(taskid > 32)
		id -= 5000;
		
	if(get_user_team(id) != 2 || !w_trakcie[id])
		return PLUGIN_HANDLED;
	
	remove_task(id+5000);
	jail_set_user_speed(id, 250.0);
	set_bartime(id, 0);
	
	if(is_user_alive(w_trakcie[id]))
	{
		jail_set_user_speed(w_trakcie[id], 250.0);
		set_bartime(w_trakcie[id], 0);
	}
	if(taskid > 32)
		Pokaz_bronie(id);
	
	w_trakcie[w_trakcie[id]] = 0;
	w_trakcie[id] = 0;
	return PLUGIN_HANDLED;
}

public Pokaz_bronie(id)
{
	if(!is_user_alive(id) || !is_user_alive(w_trakcie[id]))
		return;
	
	new weapons[32], numweapons, weaponname[32];
	get_user_weapons(w_trakcie[id], weapons, numweapons);
	PokazWiadomosc(id, "Znalazles:");
	for(new i=0; i<numweapons; i++)
	{
		get_weaponname(weapons[i], weaponname, 31);
		replace(weaponname, 32, "weapon_", "");
		replace(weaponname, 32, "knife", "piesci");
		PokazWiadomosc(id, weaponname);
	}
	emit_sound(id, CHAN_WEAPON, "weapons/c4_disarmed.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);
}

public Damage(id)
{
	if(is_user_alive(id) && w_trakcie[id])
	{
		wylacz_rewizje(id);
	}
}

public cmd_kradnij(id) {
	if(jail_get_prisoner_free(id) || jail_get_user_block(id))
		return;
			
	new body, target;
	get_user_aiming(id, target, body, 50);
						
	if(target && get_user_team(target) == 1)
	{
		PokazWiadomosc(id, "Nie nacelowales na^3 straznika");
		return;
	}
	if(!is_user_alive(target))
		return;
						
	new weapons = Jaki_Pistolet(target);
	if(!weapons)
	{
		PokazWiadomosc(id, "Straznik nie ma broni^3 krotkiej");
		return;
	}
						
	new weaponname[24];
	get_weaponname(weapons, weaponname, 23);
							
	ham_strip_weapon(target, weapons, weaponname);
	give_item(id, weaponname);
					
	PokazWiadomosc(id, "Gratulacje -^3 Ukradles bron");		
}	

public cmd_prowadz(id) {
	if(!is_user_alive(id)) {
		PokazWiadomosc(id, "Tylko zywi klawisze moga^3 prowadzic!");
		return PLUGIN_HANDLED;
	}
	
	if(get_user_team(id) != 2) {
		PokazWiadomosc(id, "Tylko klawisze moga^3 prowadzic!");
		return PLUGIN_HANDLED;
	}
	if(jail_get_prowadzacy()) {
		PokazWiadomosc(id, "Jest juz prowadzacy!");
	} else {
		jail_set_prowadzacy(id);
	}
	
	return PLUGIN_HANDLED;
}	

stock Jaki_Pistolet(id)
{
	if(!is_user_connected(id))
		return 0;
	
	new weapons[32], numweapons;
	get_user_weapons(id, weapons, numweapons);
	
	for(new i=0; i<numweapons; i++)
		if((1<<weapons[i]) & 0x4030402)
			return weapons[i];

	return 0;
}

stock ham_strip_weapon(id, wid, szname[])
{
	if(!wid) 
		return 0;
	
	new ent;
	while((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", szname)) && pev(ent, pev_owner) != id) {}
	if(!ent)
		return 0;
	
	if(get_user_weapon(id) == wid) 
		ExecuteHam(Ham_Weapon_RetireWeapon, ent);
	
	if(ExecuteHam(Ham_RemovePlayerItem, id, ent)) 
	{
		ExecuteHam(Ham_Item_Kill, ent);
		set_pev(id, pev_weapons, pev(id, pev_weapons) & ~(1<<wid));
	}
	return 1;
}

stock set_bartime(id, czas)
{
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("BarTime"), _, id);
	write_short(czas);
	message_end();
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1045\\ f0\\ fs16 \n\\ par }
*/
