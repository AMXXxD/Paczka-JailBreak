#include <amxmodx>
#include <amxmisc>
#include <nvault>
#include <jailbreak>

#define ILOSC_GRACZY 4

new g_szNickGracza[33][32];
new g_iSzlugiGracza[33];
new g_iCelGracza[33];
new g_iHud;

new bool:g_bCzyTrwaZwyklyDzien, g_bCzyKoniecProwadzenia, g_bZyczenie[33];

public plugin_init()
{
	register_plugin("System Szlugow", "1.0", "Bodzio");
	
	register_concmd("jail_ustawszlugi", "cmd_UstawSzlugi", ADMIN_IMMUNITY, "<nick> <ile>");
	register_concmd("jail_dodajszlugi", "cmd_DodajSzlugi", ADMIN_IMMUNITY, "<nick> <ile>");
	
	register_clcmd("jail_Ileszlugow", "cmd_IleSzlugow");
	register_clcmd("jail_IloscSzlugow", "cmd_WpisalIloscSzlugow");	
	register_clcmd("say /dajszlugi", "cmd_DajSzlugaski");

	register_event("DeathMsg", "EnemyKilled", "a");
	register_event("TextMsg", "ev_PoczatekGry", "a", "2&#Game_C");
	register_event("ResetHUD", "ev_ResetHUD", "b");
	
	g_iHud = CreateHudSyncObj();
}
public plugin_natives() {
	register_native("jail_set_szlugi", "SetSzlugi", 1);
	register_native("jail_get_szlugi", "GetSzlugi", 1);
	register_native("jail_menu_szlugi", "cmd_menuszlugi", 1);
	register_native("jail_dajszlugi", "cmd_DajSzlugaski", 1);	
}

public client_authorized(id) {
	get_user_name(id, g_szNickGracza[id], 31);
	LoadSzlugi(id);
}

public ev_PoczatekGry() {
	g_bCzyTrwaZwyklyDzien = false;
}

public ev_ResetHUD(id) {
	g_bZyczenie[id] = false;
	StatusSzlugow(id);
}

public cmd_menuszlugi(id)
{
	new menu = menu_create(fmt("\d%s | Menu^n\r[MENU]\w Menu Szlugow:", forum), "Handel_Szlugi"), szId[4], iPlayers;

	for(new i = 1; i <= get_maxplayers(); i++) {
		if(!is_user_connected(i) || is_user_hltv(i)) continue;
		
		num_to_str(i, szId, 3);
		menu_additem(menu, fmt("%s", g_szNickGracza[i]), szId);
		iPlayers++;
	}
	if(!iPlayers)
	{
		PokazWiadomosc(id, "Nie ma nikogo na^3 serwerze");
		return PLUGIN_HANDLED;
	}

	menu_setprop(menu, MPROP_BACKNAME, "\d×\w Wroc");
	menu_setprop(menu, MPROP_NEXTNAME, "\d×\w Dalej");
	menu_setprop(menu, MPROP_EXITNAME, "\d×\w Wyjdz");
	menu_display(id, menu);	
	return PLUGIN_HANDLED;	
}

public Handel_Szlugi(id, menu, item) {
	if(item < 0) {
		if(item == MENU_EXIT) {
			menu_destroy(menu);
		}
		return PLUGIN_CONTINUE;
	}
	
	new iAccess, szId[4], callback, iTarget;
	menu_item_getinfo(menu, item, iAccess, szId, 3, _, _, callback);
	iTarget = str_to_num(szId);
	
	g_iCelGracza[id] = iTarget;
	
	client_cmd(id, "messagemode jail_Ileszlugow");
		
	menu_destroy(menu);
	return PLUGIN_CONTINUE;
}

public cmd_IleSzlugow(id) {
	new iTarget = g_iCelGracza[id];
	
	if(!is_user_connected(iTarget)) {
		PokazWiadomosc(id, "Nie znaleziono^3 gracza.");
		return PLUGIN_HANDLED;
	}
	
	new szIlosc[32], iIlosc;
	
	read_argv(1, szIlosc, 31);
	iIlosc = str_to_num(szIlosc);
	
	if(iIlosc <= 0) {
		PokazWiadomosc(id, "Podana liczba jest^3 niepoprawna!");
		return PLUGIN_HANDLED;
	}
	
	SetSzlugi(iTarget, g_iSzlugiGracza[iTarget] + iIlosc);
	
	PokazWiadomosc(id, "Przekazales^4 %d^1 szlugow graczowi^3 %s", iIlosc, g_szNickGracza[iTarget]);
	PokazWiadomosc(iTarget, "Dostales^4 %d^1 szlugow od^3 %s", iIlosc, g_szNickGracza[id]);
	
	return PLUGIN_HANDLED;
}

public cmd_DajSzlugaski(id)
{
	new iMenu = menu_create(fmt("\d%s | Menu^n\r[MENU]\w Oddaj Szlugi:", forum), "OddajSzlugi_Handler"), szId[4], iPlayers;
	
	for(new i = 1; i <= get_maxplayers(); i++) {
		if(!is_user_connected(i) || is_user_hltv(i) || id == i) continue;
		
		num_to_str(i, szId, 3);
		menu_additem(iMenu, fmt("%s", g_szNickGracza[i]), szId);
		iPlayers++;
	}
	if(!iPlayers)
	{
		PokazWiadomosc(id, "Nie ma nikogo na^3 serwerze");
		return PLUGIN_HANDLED;
	}

	menu_setprop(iMenu, MPROP_BACKNAME, "\d×\w Wroc");
	menu_setprop(iMenu, MPROP_NEXTNAME, "\d×\w Dalej");
	menu_setprop(iMenu, MPROP_EXITNAME, "\d×\w Wyjdz");
	menu_display(id, iMenu);	
	return PLUGIN_HANDLED;
}

public OddajSzlugi_Handler(id, iMenu, iItem) {
	if(iItem < 0) {
		if(iItem == MENU_EXIT) {
			menu_destroy(iMenu);
		}
		return PLUGIN_CONTINUE;
	}
	
	new iAccess, szId[4], callback, iTarget;
	menu_item_getinfo(iMenu, iItem, iAccess, szId, 3, _, _, callback);
	iTarget = str_to_num(szId);
	
	g_iCelGracza[id] = iTarget;
	
	client_cmd(id, "messagemode jail_IloscSzlugow");
	
	PokazWiadomosc(id, "Wpisz ilosc^3 szlugow^1, jaka chcesz przekazac.");
		
	menu_destroy(iMenu);
	return PLUGIN_CONTINUE;
}

public cmd_WpisalIloscSzlugow(id) {
	new iTarget = g_iCelGracza[id];
	
	if(!is_user_connected(iTarget)) {
		PokazWiadomosc(id, "Nie znaleziono^3 gracza.");
		return PLUGIN_HANDLED;
	}
	
	new szIlosc[32], iIlosc;
	
	read_argv(1, szIlosc, 31);
	iIlosc = str_to_num(szIlosc);
	
	
	new iIloscSzlugowGracza = g_iSzlugiGracza[id];
	
	if(iIlosc > iIloscSzlugowGracza) {
		iIlosc = iIloscSzlugowGracza;
	}
	
	if(iIlosc <= 0) {
		PokazWiadomosc(id, "Podana liczba jest^3 niepoprawna!");
		return PLUGIN_HANDLED;
	}
	
	SetSzlugi(id, iIloscSzlugowGracza - iIlosc);
	SetSzlugi(iTarget, g_iSzlugiGracza[iTarget] + iIlosc);
	
	PokazWiadomosc(id, "Przekazales^3 %d^1 szlugow graczowi^3 %s", iIlosc, g_szNickGracza[iTarget]);
	PokazWiadomosc(iTarget, "Dostales^3 %d^1 szlugow od^3 %s", iIlosc, g_szNickGracza[id]);
	
	return PLUGIN_HANDLED;
}	

public cmd_UstawSzlugi(id, iLevel, iCid)
{
	if(!cmd_access(id, iLevel, iCid, 2))
		return PLUGIN_HANDLED;
	
	new szNick[32], szIle[8];
	
	read_argv(1, szNick, 31);
	read_argv(2, szIle, 8);
	
	new iTarget = find_player("bhl", szNick);
	
	if(!iTarget)
	{
		client_print(id, print_console, "Nie znaleziono gracza!");
		return PLUGIN_HANDLED;
	}
	
	g_iSzlugiGracza[iTarget] = str_to_num(szIle);
	StatusSzlugow(iTarget);
	
	get_user_name(iTarget, szNick, 31);
	client_print(id, print_console, "Ustawiono %s szlugow graczowi %s", szIle, szNick);
	
	return PLUGIN_HANDLED;
}

public cmd_DodajSzlugi(id, iLevel, iCid) {
	if(!cmd_access(id, iLevel, iCid, 2))
		return PLUGIN_HANDLED;
	
	new szNick[32], szIle[8];
	
	read_argv(1, szNick, 31);
	read_argv(2, szIle, 8);
	
	new iTarget = find_player("bhl", szNick);
	
	if(!iTarget) {
		client_print(id, print_console, "Nie znaleziono gracza!");
		return PLUGIN_HANDLED;
	}
	
	g_iSzlugiGracza[iTarget] += str_to_num(szIle);
	StatusSzlugow(iTarget);
	
	get_user_name(iTarget, szNick, 31);
	client_print(id, print_console, "Dodano %s szlugow dla graczowi %s", szIle, szNick);
	
	return PLUGIN_HANDLED;
}

public EnemyKilled()
{
	if(get_playersnum() < ILOSC_GRACZY)
		return;

	new kid = read_data(1);
	new vid = read_data(2);
	new hs = read_data(3);
	
	if(kid == vid)
		return;
	
	if(get_user_team(kid) == get_user_team(vid))
		return;

	if(hs){
		g_iSzlugiGracza[kid] += 3;
		set_hudmessage(255, 255, 0, -1.0, 0.2, 1, 3.0, 3.0, 0.1, 0.15, -1);
		ShowSyncHudMsg(kid, g_iHud, "Otrzymales +%d szlugow^nza fraga z banki");
	}else{
		g_iSzlugiGracza[kid] += 4;
		set_hudmessage(255, 255, 0, -1.0, 0.2, 1, 3.0, 3.0, 0.1, 0.15, -1);
		ShowSyncHudMsg(kid, g_iHud, "Otrzymales +%d szlugow^nza fraga");
	}
}

public OnLastPrisonerShowWish(id)
{
	if(get_playersnum() < ILOSC_GRACZY || g_bZyczenie[id])
		return;
	
	g_bZyczenie[id] = true;
	g_iSzlugiGracza[id] += 10;
	
	set_hudmessage(255, 255, 0, -1.0, 0.2, 1, 3.0, 3.0, 0.1, 0.15, -1);
	ShowSyncHudMsg(id, g_iHud, "Otrzymales +%d szlugow^nza zyczenie");
	
	KoniecProwadzenia();
	g_bCzyTrwaZwyklyDzien = false;
	
	StatusSzlugow(id)
}

public OnDayStartPost(iDzien) {
	if(1 <= iDzien <= 5) {
		g_bCzyTrwaZwyklyDzien = true;
	} else {
		g_bCzyTrwaZwyklyDzien = false;
	}
	
}

public OnRemoveData(iDzien) {
	if(get_playersnum() >= ILOSC_GRACZY) {
		KoniecProwadzenia();
	}
}

KoniecProwadzenia() {
	if(g_bCzyKoniecProwadzenia || !g_bCzyTrwaZwyklyDzien) {
		return;
	}
	
	for(new i = 1; i <= get_maxplayers(); i++) {
		if(!is_user_alive(i) || get_user_team(i) != 2) {
			continue;
		}
		
		if(jail_get_prowadzacy() == i) {
			g_iSzlugiGracza[i] += 15;
			StatusSzlugow(i);
			
			set_hudmessage(255, 255, 0, -1.0, 0.2, 1, 3.0, 3.0, 0.1, 0.15, -1);
			ShowSyncHudMsg(i, g_iHud, "Otrzymales +15 szlugow^nza dotrwanie do konca");
		} else {
			g_iSzlugiGracza[i] += 25;
			StatusSzlugow(i);
			
			set_hudmessage(255, 255, 0, -1.0, 0.2, 1, 3.0, 3.0, 0.1, 0.15, -1);
			ShowSyncHudMsg(i, g_iHud, "Otrzymales +25 szlugow^nza dotrwanie do konca");	
		}
	}
	
	g_bCzyKoniecProwadzenia = true;
}

public StatusSzlugow(id) {
	if(g_iSzlugiGracza[id] > 100000) {
		g_iSzlugiGracza[id] = 100000;
	}
	
	if(g_iSzlugiGracza[id] < 0) {
		g_iSzlugiGracza[id] = 0;
	}
	new szSzlugi[16], iVault = nvault_open("Jail_Szlugi");
	num_to_str(g_iSzlugiGracza[id], szSzlugi, 15);
	nvault_set(iVault, g_szNickGracza[id], szSzlugi);
	nvault_close(iVault);	
}

public SetSzlugi(id, wartosc) {
	g_iSzlugiGracza[id] = wartosc;
	
	if(is_user_alive(id)) {
		StatusSzlugow(id);
	}
}
	
public GetSzlugi(id)
	return g_iSzlugiGracza[id];

public LoadSzlugi(id)
{
	new iVault = nvault_open("Jail_Szlugi");
	g_iSzlugiGracza[id] = nvault_get(iVault, g_szNickGracza[id]);
	nvault_close(iVault);
}
