#include <amxmodx>
#include <jailbreak>
#include <fun>

#define TASK_PRZYSLOWIA 333

new const g_szPrzyslowia[][][] = {
	{ "Szklana ...", "pulapka" },
	{ "Gdzie ... szesc, tam nie ma co jesc", "kucharek" },
	{ "Najlepsza obrona jest ...", "atak" },
	{ "Bez pracy nie ma ...", "kolaczy" },
	{ "Biednemu zawsze ... w oczy", "wiatr" },
	{ "... uswieca srodki", "Cel" },
	{ "Co dwie ... to nie jedna", "dwie" },
	{ "Co ma wisiec nie ...", "utonie" },
	{ "Dla ... nic trudnego", "chcacego" },
	{ "Dzieci i ... glosu nie maja", "ryby" },
	{ "Gdzie dwoch sie ..., tam trzeci korzysta", "bije" },
	{ "Dycha do dychy i brzecza ...", "kielichy" },
	{ "Komu w ... temu czas", "droge" },
	{ "Kto ..., nie bladzi", "pyta" },
	{ "Klamstwo ma ... nogi", "krotkie" },
	{ "Nadzieja umiera ...", "ostatnia" },
	{ "Strach ma wielkie ...", "oczy" },
	{ "Trafila ... na kamien", "kosa" },
	{ "Zadna praca nie ...", "hanbi" }
};

new g_iHud, bool:g_bZabawaPrzyslowia;

new g_szPrzyslowie[256];
new g_szOdpowiedz[64];

public plugin_init() {
	register_plugin("Przyslowia", "1.0", "");
	
	register_logevent("ev_KoniecRundy", 2, "1=Round_End")
	register_clcmd("say /przyslowia", "cmd_Przyslowia");
	register_clcmd("say /psw", "cmd_Przyslowia");
	
	register_clcmd("przyslowia_Przyslowie", "cmd_WpisalPrzyslowie");
	register_clcmd("przyslowia_Odpowiedz", "cmd_WpisalOdpowiedz");
	
	register_clcmd("say", "cmd_Czat");
	
	g_iHud = CreateHudSyncObj();
}

public plugin_natives()
{
	register_native("jail_menu_przyslowia", "cmd_Przyslowia", 1);	
}


public ev_KoniecRundy() {
	ClearSyncHud(0, g_iHud);
	remove_task(TASK_PRZYSLOWIA);
	g_bZabawaPrzyslowia = false;
}
	

public cmd_Przyslowia(id) {
	if(get_user_team(id) != 2 || !is_user_alive(id)) {
		return PLUGIN_HANDLED;
	}
	
	if(jail_get_play_game_id() >= 6) {
		PokazWiadomosc(id, "Przysłowia są niedostępne podczas zabaw!");
		return PLUGIN_HANDLED;
	}
	
	if(jail_get_prowadzacy() != id) {
		PokazWiadomosc(id, "Przysłowia są dostępne tylko dla prowadzących!");
		return PLUGIN_HANDLED;
	}
	
	if(task_exists(TASK_PRZYSLOWIA)) {
		PokazWiadomosc(id, "Trwa odliczanie...");
		return PLUGIN_HANDLED;
	}
	
	if(g_bZabawaPrzyslowia) {
		new iMenu = menu_create(fmt("\d%s | Menu^n\r[MENU]\w Aktualnie zabawa juz trwa.^nChcesz ja zakonczyc?", forum), "ZakonczZabawe_Handler");	
		
		menu_additem(iMenu, "\rTak");
		menu_additem(iMenu, "Nie");
		
		menu_setprop(iMenu, MPROP_EXIT, MEXIT_NEVER);
		
		menu_display(id, iMenu);
		return PLUGIN_HANDLED;
	}	
	
	copy(g_szPrzyslowie, 255, "");
	copy(g_szOdpowiedz, 63, "");
	
	new iMenu = menu_create(fmt("\d%s | Menu^n\r[MENU]\w Wybierz przyslowie:", forum), "Przyslowia_Handler"), szItem[128];	
	
	menu_additem(iMenu, "\rWlasna propozycja");
	
	for(new i = 0; i < sizeof g_szPrzyslowia; i++) {
		copy(szItem, 127, g_szPrzyslowia[i][0]);
		replace(szItem, 127, "...", g_szPrzyslowia[i][1]);
		
		menu_additem(iMenu, szItem);
	}
	menu_setprop(iMenu, MPROP_EXITNAME, "\d×\w Wyjdz");	
	menu_display(id, iMenu);
	
	return PLUGIN_HANDLED;
}

public Przyslowia_Handler(id, iMenu, iItem) {
	if(iItem < 0) {
		if(iItem == MENU_EXIT) {
			menu_destroy(iMenu);
		}
		
		return PLUGIN_CONTINUE;
	}
	
	if(iItem == 0) {
		client_cmd(id, "messagemode przyslowia_Przyslowie");
		
		PokazWiadomosc(id, "Wpisz^3 przyslowie.");
		PokazWiadomosc(id, "W miejsce do zgadniecia wpisz 3 kropki, w ten sposob:^3 ...");
	} else {
		new iIdPanstwa = iItem - 1;
		
		copy(g_szPrzyslowie, 63, g_szPrzyslowia[iIdPanstwa][0]);
		copy(g_szOdpowiedz, 63, g_szPrzyslowia[iIdPanstwa][1]);
		
		ZacznijZabawe(id);
	}
	
	menu_destroy(iMenu);
	return PLUGIN_CONTINUE;
}

public ZakonczZabawe_Handler(id, iMenu, iItem) {
	if(iItem == 0) {
		g_bZabawaPrzyslowia = false;
		
		ClearSyncHud(0, g_iHud);
		PokazWiadomosc(0, "Prowadzący zakonczyl zabawe w^3 przyslowia.");
		PokazWiadomosc(0, "Prawidlowa odpowiedz:^3 %s", g_szOdpowiedz);
	}
	
	menu_destroy(iMenu);
}

public cmd_WpisalPrzyslowie(id) {
	read_argv(1, g_szPrzyslowie, 63);
	
	for(new i = 0; i < 3; i++) {
		PokazWiadomosc(id, "Wpisane przyslowie:^3 %s", g_szPrzyslowie);
	}
	
	client_cmd(id, "messagemode przyslowia_Odpowiedz");
	
	PokazWiadomosc(id, "Wpisz^3 odpowiedz^1, czyli slowo ktore powinno sie znalezc na miejscu kropek.");
	return PLUGIN_HANDLED;
}

public cmd_WpisalOdpowiedz(id) {
	read_argv(1, g_szOdpowiedz, 63);
	
	for(new i = 0; i < 3; i++) {
		PokazWiadomosc(id, "Podana odpowiedz:^3 %s", g_szOdpowiedz);
	}
	
	ZacznijZabawe(id);
	
	return PLUGIN_HANDLED;
}

ZacznijZabawe(id) {
	if(jail_get_play_game_id() >= 6 || jail_get_prowadzacy() != id || task_exists(TASK_PRZYSLOWIA) || g_bZabawaPrzyslowia) {
		PokazWiadomosc(id, "Wystąpił błąd.");
		return;
	}
	
	new iDane[1];
	
	iDane[0] = 8;
	task_Odliczanie(iDane, TASK_PRZYSLOWIA);
	
	PokazWiadomosc(0, "Zaczynamy zabawe w przyslowia!");
	PokazWiadomosc(0, "Na srodku ekranu pojawi się przyslowie, jednak będzie w nim czegos brakowalo, pytanie czego?");
	PokazWiadomosc(0, "Odpowiedz podajemy na czacie.");
}

public task_Odliczanie(iDane[1], iTaskId) {
	if(iDane[0] <= 0) {
		g_bZabawaPrzyslowia = true;
		
		set_hudmessage(85, 170, 255, -1.0, 0.15, 0, 10.0, 10.0, 0.1, 0.1, 2);
		ShowSyncHudMsg(0, g_iHud, "%s^nOdpowiedź wpisz na czacie!", g_szPrzyslowie);
		
		PokazWiadomosc(0, "Przyslowie:^3 %s", g_szPrzyslowie);
		PokazWiadomosc(0, "Odpowiedz wpisz na czacie!");
		
		client_cmd(0, "spk ^"buttons/bell1^"");
		
		return PLUGIN_CONTINUE;
	}
	
	new szLiczba[8];
	
	set_hudmessage(85, 170, 255, -1.0, 0.15, 0, 1.0, 1.2, 0.1, 0.1, 2);
	ShowSyncHudMsg(0, g_iHud, "Podaję przysłowie za %d!", iDane[0]);
	
	num_to_word(iDane[0], szLiczba, 7);
	client_cmd(0, "spk ^"%s^"", szLiczba);
	
	iDane[0] --;
	set_task(1.0, "task_Odliczanie", TASK_PRZYSLOWIA, iDane, 1);
	
	return PLUGIN_CONTINUE;
}

public cmd_Czat(id) {
	if(!g_bZabawaPrzyslowia || get_user_team(id) != 1 || !is_user_alive(id)) {
		return PLUGIN_CONTINUE;
	}
	
	new szWiadomosc[192];
	
	read_argv(1, szWiadomosc, 191);
	trim(szWiadomosc);
	
	if(equali(szWiadomosc, g_szOdpowiedz)) {
		new szNick[32];
		
		get_user_name(id, szNick, 31);
		
		ClearSyncHud(0, g_iHud);
		
		set_user_rendering(id, kRenderFxGlowShell, 0, 170, 255, kRenderNormal, 16);
		PokazWiadomosc(0, "Przyslowie zgadl^3 %s", szNick);
		PokazWiadomosc(0, "Prawidlowa odpowiedz:^3 %s", g_szOdpowiedz);
		
		client_cmd(0, "spk ^"events/task_complete^"");
		
		set_task(5.0, "task_UsunKolor", id);
		
		g_bZabawaPrzyslowia = false;
	}
	
	return PLUGIN_CONTINUE;
}

public task_UsunKolor(id) {
	if(is_user_alive(id)) {
		set_user_rendering(id);
	}
}

	
		
