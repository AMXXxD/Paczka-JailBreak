#include <amxmodx>
#include <amxmisc>
#include <fun>
#include <cstrike>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <jailbreak>

native jail_get_szlugi(id);
native jail_set_szlugi(id, wartosc);

#define PLUGIN "Jail Zyczenia"
#define VERSION "1.0.14b"
#define AUTHOR "Cypis"

#define TASK_KONIECPOJEDYNKU 867

/////////// Pojedynek ///////////
new bronie_pojedynek, pojedynek[2], kandydaci_pojedynek[2], obstawki[2], kogo_obstawia[33], ile_obstawia[33], czas_do_pojedynku, czas_do_konca_pojedynku, kosy=false;
new HamHook:fHamKill, HamHook:fHamDamage, HamHook:fHamTrace, HamHook:fHamWeapon[31], fDropGranade, fDotykKnife, fTraceLine;
/////////// Pojedynek ///////////
new const maxAmmo[31] = {0,52,0,90,1,31,1,100,90,1,120,100,100,90,90,90,100,120,30,120,200,31,90,120,90,2,35,90,90,0,100};
new id_wlasne, id_bezruch, id_freeday, id_duszek, id_rambomod, id_pojedynek, id_szlugi;
new blood, blood2;
new bool:celownik, typ_pojedynku;
new g_iHud;
public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_forward(FM_CmdStart,"CmdStart");
	
	id_wlasne = jail_register_wish("Wlasne zyczenie");
	id_bezruch = jail_register_wish("Bezruch");
	id_freeday = jail_register_wish("FreeDay");
	id_duszek = jail_register_wish("Duszek");
	id_rambomod = jail_register_wish("RamboMod");
	id_pojedynek  = jail_register_wish("Pojedynek");
	id_szlugi = jail_register_wish("+15 Szlugow");
	
	register_clcmd("zaklad_IleObstawic", "cmd_WpisalIleObstawic");
	
	g_iHud = CreateHudSyncObj();
}
public plugin_precache()
{
	blood = precache_model("sprites/blood.spr");
	blood2 = precache_model("sprites/bloodspray.spr");
	
	precache_model("models/w_throw.mdl");
	
	precache_sound("JailBreak_Izolatka/rambomode.wav");
	precache_sound("JailBreak_Izolatka/pojedynek.wav");
	
}
public OnRemoveData(day)
{
	set_task(0.1, "task_RemoveData", 666);
}

public task_RemoveData() {
	/////////// Pojedynek ///////////						
	if(pojedynek[0] || pojedynek[1])
	{
		pojedynek[0] = 0;
		pojedynek[1] = 0;
	}
	remove_task()
	remove_task(333);
	remove_task(TASK_KONIECPOJEDYNKU);
	bronie_pojedynek = 0;
	kosy=false;
	celownik=false;
	typ_pojedynku = 0;
	kandydaci_pojedynek[0] = 0;
	kandydaci_pojedynek[1] = 0;
	obstawki[0] = 0;
	obstawki[1] = 0;
	RegisterHams(false);
	/////////// Pojedynek ///////////
}
public OnLastPrisonerShowWish(id)
{
	PokazWiadomosc(0, "Wiezien ma^3 30 sekund^1 na wybranie zyczenia!")
	client_print(0, print_center, "Ostatni wiezien ma zyczenie!")
}
public OnLastPrisonerTakeWish(id, zyczenie)
{
	if(zyczenie == id_wlasne)
	{
		client_cmd(0, "spk buttons/bell1.wav")	
	}
	else if(zyczenie == id_bezruch)
	{
		strip_user_weapons(id);
		give_item(id, "weapon_knife");
		give_item(id, "weapon_deagle")
		cs_set_user_bpammo(id, CSW_DEAGLE, maxAmmo[CSW_DEAGLE]);
		
		jail_set_ct_hit_tt(true);
		
		for(new i=1; i<=32; i++)
		{
			if(!is_user_alive(i) || !is_user_connected(i) || cs_get_user_team(i) != CS_TEAM_CT)
				continue;
		
			strip_user_weapons(i);
			give_item(i, "weapon_knife");
			jail_set_user_speed(i, 0.1);
		}
		set_task(40.0, "KoniecCzasu")
	}
	else if(zyczenie == id_freeday)
	{
		if(jail_get_days() == PIATEK ||  jail_get_days() == SOBOTA) //w tych dniach nie mozna wziac fd
			return JAIL_HANDLED;
		
		user_kill(id);
		jail_set_prisoner_free(id);	
	}
	else if(zyczenie == id_duszek)
	{
		if(jail_get_days() == PIATEK || jail_get_days() == SOBOTA) //w tych dniach nie mozna wziac duszka
			return JAIL_HANDLED;
			
		user_kill(id);
		jail_set_prisoner_ghost(id);
	}
	else if(zyczenie == id_rambomod)
	{
		client_cmd(0, "spk JailBreak_Izolatka/rambomode.wav");
		set_hudmessage(255, 0, 0, -1.0, -1.0, 0, 6.0, 4.0);
		show_hudmessage(0, "RamboMod aktywny!");
		
		set_user_health(id, 1500);
		
		strip_user_weapons(id);
		give_item(id, "weapon_knife");
		give_item(id, "weapon_awp");
		give_item(id, "weapon_m249");
		cs_set_user_bpammo(id, CSW_M249, maxAmmo[CSW_M249]);
	}
	else if(zyczenie == id_pojedynek)
	{
		pojedynek[0]= id;
		WybierzPojedynekMenu(id)
	} else if(zyczenie == id_szlugi) {
		user_kill(id);
		jail_set_szlugi(id, jail_get_szlugi(id) + 15);
	}
	return JAIL_CONTINUE;
}
public WybierzPojedynekMenu(id)
{
	new menu = menu_create(fmt("\d%s | Menu^n\r[POJEDYNEK]\w Pojedynek na:", forum), "Menu1_Handler");
	menu_additem(menu, "Pistolety");
	menu_additem(menu, "Reszta broni");
	menu_additem(menu, "Granaty odlamkowe");
	menu_additem(menu, "Piesci");
	menu_additem(menu, "Noze");	
	menu_setprop(menu, MPROP_BACKNAME, "\d×\w Wroc");
	menu_setprop(menu, MPROP_NEXTNAME, "\d×\w Dalej");
	menu_setprop(menu, MPROP_EXITNAME, "\d×\w Wyjdz");
	menu_display(id, menu);
}
public Menu1_Handler(id, menu, item)
{
	new name[33]
	get_user_name(id, name, 32)
	switch(item)
	{
		case 0:
		{
			new menu = menu_create(fmt("\d%s | Menu^n\r[POJEDYNEK]\w Pistolety:", forum), "Menu1_Handler_Pistolety");
			menu_additem(menu, "Glock");
			menu_additem(menu, "Usp");
			menu_additem(menu, "P228");
			menu_additem(menu, "Fiveseven");
			menu_additem(menu, "Elite");
			menu_additem(menu, "Deagle");
			menu_setprop(menu, MPROP_BACKNAME, "\d×\w Wroc");
			menu_setprop(menu, MPROP_NEXTNAME, "\d×\w Dalej");
			menu_setprop(menu, MPROP_EXITNAME, "\d×\w Wyjdz");
			menu_display(id, menu);
		}
		case 1:
		{
			new menu = menu_create(fmt("\d%s | Menu^n\r[POJEDYNEK]\w Reszta broni:", forum), "Menu_Handler_ResztaBroni");
			menu_additem(menu, "M3");
			menu_additem(menu, "XM1014");
			menu_additem(menu, "MP5-Navy");
			menu_additem(menu, "TMP");
			menu_additem(menu, "P90");
			menu_additem(menu, "MAC10");
			menu_additem(menu, "UMP");
			menu_additem(menu, "Galil");
			menu_additem(menu, "Famas");
			menu_additem(menu, "AK47");
			menu_additem(menu, "M4A1");
			menu_additem(menu, "SG552");
			menu_additem(menu, "AUG");
			menu_additem(menu, "Scout");
			menu_additem(menu, "AWP");
			menu_setprop(menu, MPROP_BACKNAME, "\d×\w Wroc");
			menu_setprop(menu, MPROP_NEXTNAME, "\d×\w Dalej");
			menu_setprop(menu, MPROP_EXITNAME, "\d×\w Wyjdz");
			menu_display(id, menu);
		}
		case 2:
		{
			kandydaci_pojedynek[0] = id;
			bronie_pojedynek = CSW_HEGRENADE;
			PokazWiadomosc(0, "^3 %s^1 wybral pojedynek na^3 Granaty odlamkowe", name)
			MenuPojedynek(id);	
		}
		case 3:
		{
			kandydaci_pojedynek[0] = id;
			bronie_pojedynek = CSW_KNIFE;
			kosy=true;	
			PokazWiadomosc(0, "^3 %s^1 wybral pojedynek na^3 Piesci", name)
			MenuTypPojedynku(id);
		}
		case 4:
		{
			kandydaci_pojedynek[0] = id;
			bronie_pojedynek = CSW_KNIFE;
			PokazWiadomosc(0, "^3 %s^1 wybral pojedynek na^3 Noze", name)
			MenuPojedynek(id);
		}
	}
	
}

public Menu1_Handler_Pistolety(id, menu, item)
{
	if(item==MENU_EXIT)
	{
		menu_destroy(menu)
		WybierzPojedynekMenu(id)
		return;
	}
	new name[33]
	get_user_name(id, name, 32)
	switch(item)
	{
		case 0:
		{
			kandydaci_pojedynek[0]=id
			bronie_pojedynek = CSW_GLOCK18
			PokazWiadomosc(0, "^3 %s^x01 wybral pojedynek na^x03 GLOCK18", name)
			MenuTypPojedynku(id);
			
		}
		case 1:
		{
			kandydaci_pojedynek[0]=id
			bronie_pojedynek = CSW_USP
			PokazWiadomosc(0, "^3 %s^1 wybral pojedynek na^3 USP", name)
			MenuTypPojedynku(id);
			
		}
		case 2:
		{
			kandydaci_pojedynek[0]=id
			bronie_pojedynek = CSW_P228
			PokazWiadomosc(0, "^3 %s^1 wybral pojedynek na^3 P228", name)
			MenuTypPojedynku(id);
			
		}
		case 3:
		{
			kandydaci_pojedynek[0]=id
			bronie_pojedynek = CSW_FIVESEVEN
			PokazWiadomosc(0, "^3 %s^1 wybral pojedynek na^3 Fiveseven", name)
			MenuTypPojedynku(id);
			
		}
		case 4:
		{
			kandydaci_pojedynek[0]=id
			bronie_pojedynek = CSW_ELITE
			PokazWiadomosc(0, "^3 %s^1 wybral pojedynek na^3 Elite", name)
			MenuTypPojedynku(id);
			
		}
		case 5:
		{
			kandydaci_pojedynek[0]=id
			bronie_pojedynek = CSW_DEAGLE
			PokazWiadomosc(0, "^3 %s^1 wybral pojedynek na^3 Deagle", name)
			MenuTypPojedynku(id);
			
		}
	}
}
public Menu_Handler_ResztaBroni(id, menu, item)
{
	if(item==MENU_EXIT)
	{
		menu_destroy(menu)
		WybierzPojedynekMenu(id)
		return;
	}
	new name[33]
	get_user_name(id, name, 32)
	switch(item)
	{
		case 0:
		{
			kandydaci_pojedynek[0]=id
			bronie_pojedynek = CSW_M3
			PokazWiadomosc(0, "^3 %s^1 wybral pojedynek na^3 M3", name)
			MenuTypPojedynku(id);
			
		}
		case 1:
		{
			kandydaci_pojedynek[0]=id
			bronie_pojedynek = CSW_XM1014
			PokazWiadomosc(0, "^3 %s^1 wybral pojedynek na^3 XM1014", name)
			MenuTypPojedynku(id);
			
		}
		case 2:
		{
			kandydaci_pojedynek[0]=id
			bronie_pojedynek = CSW_MP5NAVY
			PokazWiadomosc(0, "^3 %s^1 wybral pojedynek na^3 Mp3Navy", name)
			MenuTypPojedynku(id);
			
		}
		case 3:
		{
			kandydaci_pojedynek[0]=id
			bronie_pojedynek = CSW_TMP
			PokazWiadomosc(0, "^3 %s^1 wybral pojedynek na^3 Tmp", name)
			MenuTypPojedynku(id);
			
		}
		case 4:
		{
			kandydaci_pojedynek[0]=id
			bronie_pojedynek = CSW_P90
			PokazWiadomosc(0, "^3 %s^1 wybral pojedynek na^3 P90", name)
			MenuTypPojedynku(id);
			
		}
		case 5:
		{
			kandydaci_pojedynek[0]=id
			bronie_pojedynek = CSW_MAC10
			PokazWiadomosc(0, "^3 %s^1 wybral pojedynek na^3 Mac-10", name)
			MenuTypPojedynku(id);
			
		}
		case 6:
		{
			kandydaci_pojedynek[0]=id
			bronie_pojedynek = CSW_UMP45
			PokazWiadomosc(0, "^3 %s^1 wybral pojedynek na^3 Ump 45", name)
			MenuTypPojedynku(id);
			
		}
		case 7:
		{
			kandydaci_pojedynek[0]=id
			bronie_pojedynek = CSW_GALIL
			PokazWiadomosc(0, "%s^3 %s^1 wybral pojedynek na^3 Galil", name)
			MenuTypPojedynku(id);
			
		}
		case 8:
		{
			kandydaci_pojedynek[0]=id
			bronie_pojedynek = CSW_FAMAS
			PokazWiadomosc(0, "^3 %s^x01 wybral pojedynek na^3 Famas", name)
			MenuTypPojedynku(id);
			
		}
		case 9:
		{
			kandydaci_pojedynek[0]=id
			bronie_pojedynek = CSW_AK47
			PokazWiadomosc(0, "^3 %s^1 wybral pojedynek na^3 Ak47", name)
			MenuTypPojedynku(id);
			
		}
		case 10:
		{
			kandydaci_pojedynek[0]=id
			bronie_pojedynek = CSW_M4A1
			PokazWiadomosc(0, "^3 %s^1 wybral pojedynek na^3 M4a1", name)
			MenuTypPojedynku(id);
			
		}
		case 11:
		{
			kandydaci_pojedynek[0]=id
			bronie_pojedynek = CSW_SG552
			PokazWiadomosc(0, "^3 %s^1 wybral pojedynek na^3 SG552", name)
			MenuTypPojedynku(id);
			
		}
		case 12:
		{
			kandydaci_pojedynek[0]=id
			bronie_pojedynek = CSW_AUG
			PokazWiadomosc(0, "^3 %s^1 wybral pojedynek na^3 AUG", name)
			MenuTypPojedynku(id);
			
		}
		case 13:
		{
			kandydaci_pojedynek[0]=id
			bronie_pojedynek = CSW_SCOUT
			PokazWiadomosc(0, "^3 %s^1 wybral pojedynek na^3 Scout", name)
			ZoomZapytanie(id);
			
		}
		case 14:
		{
			kandydaci_pojedynek[0]=id
			bronie_pojedynek = CSW_AWP
			PokazWiadomosc(0, "^3 %s^1 wybral pojedynek na^3 AWP", name)
			ZoomZapytanie(id);
			
		}
	
	}
}
public ZoomZapytanie(id)
{
	new menu = menu_create(fmt("\d%s | Menu^n\r[POJEDYNEK]\w Opcje:", forum), "Zoom_Handler");
	menu_additem(menu, "Bez celownika")
	menu_additem(menu, "Z celownikiem")
	menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER);
	menu_display(id, menu)
}

public Zoom_Handler(id, menu, item)
{
	if(item==0)
	{
		celownik=true;
		PokazWiadomosc(0, "Opcja:^3 Bez celownika")
		MenuTypPojedynku(id)
	}
	else
	{
		PokazWiadomosc(0, "Opcja:^3 Z celownikiem")
		celownik=false;
		MenuTypPojedynku(id)
	}
}

public MenuTypPojedynku(id) {
	new iMenu = menu_create(fmt("\d%s | Menu^n\r[POJEDYNEK]\w Wybierz rodzaj pojedynku:", forum), "TypPojedynku_Handler");	
	
	menu_additem(iMenu, "Zwykly pojedynek");
	menu_additem(iMenu, "Only HeadShoty");
	menu_additem(iMenu, "1shot1kill");
	
	menu_setprop(iMenu, MPROP_EXIT, MEXIT_NEVER);
	menu_display(id, iMenu);
}

public TypPojedynku_Handler(id, iMenu, iItem) {
	new iTyp;
	
	if(iItem == MENU_EXIT) {
		iTyp = 0;
	} else {
		iTyp = iItem;
	}
	
	switch(iTyp) {
		case 0: PokazWiadomosc(0, "Rodzaj pojedynku:^3 Zwykly");
		case 1: PokazWiadomosc(0, "Rodzaj pojedynku:^3 Only HeadShoty");
		case 2: PokazWiadomosc(0, "Rodzaj pojedynku:^3 1shot1kill");
	}
	
	typ_pojedynku = iTyp;
	MenuPojedynek(id);
	
	menu_destroy(iMenu);
}
	
public KoniecCzasu() PokazWiadomosc(0, "^3 40^1 sekund minelo, CT moze wpisac killa!")
/////////// Pojedynek ///////////
public MenuPojedynek(id)
{
	new menu = menu_create(fmt("\d%s | Menu^n\r[POJEDYNEK]\w Pojedynek Z:", forum), "Handel_Pojedynek");	
	for(new i=1; i<=32; i++)
	{
		if(!is_user_alive(i) || !is_user_connected(i) || cs_get_user_team(i) != CS_TEAM_CT)
			continue;
		new name[64];
		get_user_name(i, name, 63);
		menu_additem(menu, name);
	}
	menu_setprop(menu, MPROP_BACKNAME, "\d×\w Wroc");
	menu_setprop(menu, MPROP_NEXTNAME, "\d×\w Dalej");
	menu_setprop(menu, MPROP_EXITNAME, "\d×\w Wyjdz");
	menu_display(id, menu);
}

public Handel_Pojedynek(id, menu, item)
{
	if(kandydaci_pojedynek[0] != id || kandydaci_pojedynek[1] || !is_user_alive(id))
		return;
	
	if(item == MENU_EXIT)
	{
		menu_display(id, menu);
		return;
	}
	
	new acces, callback, data[3], szName2[64];
	menu_item_getinfo(menu, item, acces, data, 2, szName2, 63, callback);
	
	new kandydat = get_user_index(szName2);
	if(!is_user_alive(kandydat)) {
		MenuPojedynek(id);
		return;
	}
	
	kandydaci_pojedynek[1] = kandydat;
	RegisterHams(true);
	
	ZacznijObstawianie();
}

ZacznijObstawianie() {
	new iMenu, szName[2][32];
	
	get_user_name(kandydaci_pojedynek[0], szName[0], 31);
	get_user_name(kandydaci_pojedynek[1], szName[1], 31);
	
	show_menu(kandydaci_pojedynek[0], 1023, " ", 1);
	show_menu(kandydaci_pojedynek[1], 1023, " ", 1);
	
	obstawki[0] = obstawki[1] = 0;
	
	iMenu = menu_create(fmt("\d%s | Menu^n\r[MENU]\w Kogo chcesz obstawic:", forum), "Obstawianie_Handler");	
	
	menu_additem(iMenu, szName[0]);
	menu_additem(iMenu, szName[1]);
	
	menu_setprop(iMenu, MPROP_EXITNAME, "\d×\w Wyjdz");
	
	for(new i = 1; i < 33; i++) {
		kogo_obstawia[i] = -1;
		ile_obstawia[i] = 0;
		
		if(!is_user_connected(i) || is_user_hltv(i) || kandydaci_pojedynek[0] == i || kandydaci_pojedynek[1] == i) {
			continue;
		}
		
		menu_display(i, iMenu);
		PokazWiadomosc(i, "Posiadasz^4 %d szlug(i/ow)", jail_get_szlugi(i));
		PokazWiadomosc(i, "Posiadasz^4 %d szlug(i/ow)", jail_get_szlugi(i));
	}
	
	czas_do_pojedynku = 12;
	set_task(1.0, "OdliczajObstawianie", 333, _, _, "b");
}

public Obstawianie_Handler(id, iMenu, iItem) {
	if(0 <= iItem <= 1) {
		kogo_obstawia[id] = iItem;
		ile_obstawia[id] = 0;
		
		new szNick[32]; get_user_name(kandydaci_pojedynek[iItem], szNick, 31);
		
		PokazWiadomosc(id, "Wybrales gracza^3 %s", szNick);
		PokazWiadomosc(id, "Wpisz teraz, ile^3 szlugow^1 zamierzasz postawic");
		
		client_cmd(id, "messagemode zaklad_IleObstawic");
	}
}

public cmd_WpisalIleObstawic(id) {
	new szIleObstawia[32], iIleObstawia, iTarget = kogo_obstawia[id];
	
	read_argv(1, szIleObstawia, 31);
	iIleObstawia = str_to_num(szIleObstawia);
	
	if(iTarget == -1 || czas_do_pojedynku <= 0) {
		PokazWiadomosc(id, "Nie^3 zdazyles!");
	}  else {
		new iIloscSzlugow = jail_get_szlugi(id);
		
		if(iIloscSzlugow <= 0) {
			PokazWiadomosc(id, "Nie posiadasz zadnych^3 szlugow!");
		} else {
			if(iIleObstawia <= 0) {
				PokazWiadomosc(id, "Niepoprawna^3 ilosc!");
				client_cmd(id, "messagemode zaklad_IleObstawic");
			} else {
				new szNick[2][32];
				
				if(iIloscSzlugow < iIleObstawia) {
					iIleObstawia = iIloscSzlugow;
				}
				
				if(iIleObstawia > 300) {
					iIleObstawia = 300;
				}
				
				obstawki[iTarget] += iIleObstawia;
				ile_obstawia[id] = iIleObstawia;
				
				get_user_name(id, szNick[0], 31);
				get_user_name(kandydaci_pojedynek[iTarget], szNick[1], 31);
				
				PokazWiadomosc(0, "Gracz^3 %s^1 postawil na gracza^3 %s^4 %d^1 szlug(i/ow)!", szNick[0], szNick[1], iIleObstawia);
			}
		}
	}
	
	return PLUGIN_HANDLED;
}	
		
public OdliczajObstawianie() {
	if(czas_do_pojedynku <= 0) {
		ClearSyncHud(0, g_iHud);
		PojedynekStart();
		remove_task(333);
		return PLUGIN_CONTINUE;
	}
	new szLiczba[8], szName[2][32];
	
	get_user_name(kandydaci_pojedynek[0], szName[0], 31);
	get_user_name(kandydaci_pojedynek[1], szName[1], 31);
	
	set_hudmessage(255, 0, 0, -1.0, 0.15, 2, 0.02, 1.0, 0.01, 0.2, 2);
	ShowSyncHudMsg(0, g_iHud, "%s (%d szlugow) vs %s (%d szlugow)^nKoniec obstawiania za %d!", szName[0], obstawki[0], szName[1], obstawki[1], czas_do_pojedynku);
	
	if(czas_do_pojedynku <= 10) {
		num_to_word(czas_do_pojedynku , szLiczba, 7);
		client_cmd(0, "spk ^"vox/%s^"", szLiczba);
	}
	
	czas_do_pojedynku --;
	
	return PLUGIN_CONTINUE;
}

RozdajObstawioneSzlugi(iZwyciezca) {
	new iTarget ,Float:fSuma = float(obstawki[0]+obstawki[1]), iNagroda;
	for(new i = 1; i < 33; i++) {
		if(!is_user_connected(i) || is_user_hltv(i) || kandydaci_pojedynek[0] == i || kandydaci_pojedynek[1] == i) {
			continue;
		}
		
		iTarget = kogo_obstawia[i];
		
		if(iTarget == iZwyciezca && ile_obstawia[i] > 0) {
			iNagroda = floatround(fSuma * (float(ile_obstawia[i]) / float(obstawki[iTarget])));
			
			PokazWiadomosc(i, "%s BRAWO! Udalo Ci sie wygrac^4 %d^1 szlug(i/ow)", iNagroda);
			jail_set_szlugi(i, jail_get_szlugi(i) + iNagroda);
		}
	}
	
	iNagroda = floatround(0.05 * fSuma);
	PokazWiadomosc(pojedynek[iZwyciezca], "BRAWO! Za wygrana dostajesz^4 %d^1 szlug(i/ow)!", iNagroda);
	jail_set_szlugi(pojedynek[iZwyciezca], jail_get_szlugi(pojedynek[iZwyciezca]) + iNagroda);
}
	
PojedynekStart() {
	pojedynek[0] = kandydaci_pojedynek[0];
	pojedynek[1] = kandydaci_pojedynek[1];
	
	new szName[2][32];
	get_user_name(pojedynek[0], szName[0], 31);
	get_user_name(pojedynek[1], szName[1], 31);
	
	czas_do_konca_pojedynku = 120
	remove_task(TASK_KONIECPOJEDYNKU);
	set_task(1.0, "task_OdliczajKoniecPojedynku", TASK_KONIECPOJEDYNKU, _, _, "b");
	
	new iTarget, iIloscSzlugow, iIleObstawia, Float:fSuma = float(obstawki[0]+obstawki[1]);
	for(new i = 1; i < 33; i++) {
		if(!is_user_connected(i) || is_user_hltv(i) || kandydaci_pojedynek[0] == i || kandydaci_pojedynek[1] == i || ile_obstawia[i] <= 0) {
			continue;
		}
		
		iTarget = kogo_obstawia[i];
		
		if(iTarget != -1) {
			iIloscSzlugow = jail_get_szlugi(i);
			iIleObstawia = ile_obstawia[i];
			
			if(iIloscSzlugow < iIleObstawia) {
				iIleObstawia = ile_obstawia[i] = iIloscSzlugow;
				
				PokazWiadomosc(i, "Braklo Ci troche^3 szlugow61, postawiono wiec ostatecznie^4 %d^1 szlug(i/ow)", iIleObstawia);
			}
			
			jail_set_szlugi(i, iIloscSzlugow - iIleObstawia);
			PokazWiadomosc(i, "Jezeli wygra^3 %s^1, zgarniesz^4 %d^1 szlug(i/ow)", szName[iTarget], floatround(fSuma * (float(iIleObstawia) / float(obstawki[iTarget]))));
		}
		
	}
	
	PokazWiadomosc(0, "Gracz^3 %s^1 walczy z graczem^3 %s", szName[0], szName[1]);
	client_print(0, print_center, "%s vs %s", szName[0], szName[1]);
	
	PokazWiadomosc(pojedynek[0], "Jezeli wygrasz, zgarniesz^4 %d^1 szlug(i/ow)", floatround(0.05 * float(obstawki[0]+obstawki[1])));
	PokazWiadomosc(pojedynek[1], "Jezeli wygrasz, zgarniesz^4 %d^1 szlug(i/ow)", floatround(0.05 * float(obstawki[0]+obstawki[1])));
	
	new iEnt;
	
	while((iEnt = fm_find_ent_by_class(iEnt, "grenade"))) {
		if(pev_valid(iEnt)) {
			fm_remove_entity(iEnt);
		}
	}
	
	client_cmd(0, "spk sound/JailBreak_Izolatka/pojedynek.wav");
	
	set_user_rendering(pojedynek[0], kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 10);
	set_user_rendering(pojedynek[1], kRenderFxGlowShell, 0, 0, 255, kRenderNormal, 10);
	
	jail_set_user_block(pojedynek[0], true)
	jail_set_user_block(pojedynek[1], true);
	
	set_user_health(pojedynek[0], 100);
	set_user_health(pojedynek[1], 100);
	
	strip_user_weapons(pojedynek[0]);
	strip_user_weapons(pojedynek[1]);
	
	new weapon_name[24];

	get_weaponname(bronie_pojedynek, weapon_name, 23);
	
	new ent = give_item(pojedynek[0], weapon_name);
	new ent2 = give_item(pojedynek[1], weapon_name);
	
	if(bronie_pojedynek == CSW_KNIFE)
	{
		if(kosy)
		{
			set_pev(pojedynek[0], pev_viewmodel2, "models/v_knife.mdl");
			set_pev(pojedynek[0], pev_weaponmodel2, "models/p_knife.mdl");
			
			set_pev(pojedynek[1], pev_viewmodel2, "models/v_knife.mdl");
			set_pev(pojedynek[1], pev_weaponmodel2, "models/p_knife.mdl");
			cs_set_user_armor(pojedynek[0], 0, CS_ARMOR_NONE)
			cs_set_user_armor(pojedynek[1], 0, CS_ARMOR_NONE)
			return;	
		}
			
	}
	
	if(bronie_pojedynek != CSW_HEGRENADE)
	{
		cs_set_weapon_ammo(ent, 1);
		cs_set_weapon_ammo(ent2, 1);
	}
}

public task_OdliczajKoniecPojedynku(iTaskId) {
	if(!is_user_alive(pojedynek[0]) || !is_user_alive(pojedynek[1])) {
		remove_task(TASK_KONIECPOJEDYNKU);
		return PLUGIN_CONTINUE;
	}

	czas_do_konca_pojedynku --;

	switch(czas_do_konca_pojedynku) {
		case 0: {
			for(new i = 1; i < 33; i++) {
				if(!is_user_connected(i) || is_user_hltv(i) || pojedynek[0] == i || pojedynek[1] == i || ile_obstawia[i] <= 0) {
					continue;
				}
				
				jail_set_szlugi(i, jail_get_szlugi(i) + ile_obstawia[i]);
				ile_obstawia[i] = 0;
				kogo_obstawia[i] = -1;

			}

			user_silentkill(pojedynek[0]);
			user_silentkill(pojedynek[1]);

			PokazWiadomosc(0, "Czas minal! Wszystkie^3 szlugi^1 z zakladow zostaly^4 zwrocone.");
		}

		case 1..10: {
			new szLiczba[8];

			num_to_word(czas_do_konca_pojedynku , szLiczba, 7);
			client_cmd(0, "spk ^"vox/%s^"", szLiczba);
		}
	}
	
	set_hudmessage(0, 255, 0, -1.0, 0.15, 2, 0.02, 1.0, 0.01, 0.2, 2);
	ShowSyncHudMsg(0, g_iHud, "× Trwa pojedynek: %s^n× Zakonczenie za [%d]!", (typ_pojedynku == 0) ? "Zwykly" : (typ_pojedynku == 1) ? "Only HS" : "1shot1kill", czas_do_konca_pojedynku);

	return PLUGIN_CONTINUE;
}

public TakeDamage(id, ent, attacker, Float:damage, damagebits)
	return vTracerAttack(id, attacker, ent);

public TraceAttack(id, attacker, Float:damage, Float:direction[3], tracehandle, damagebits)
	return vTracerAttack(id, attacker, -1);

vTracerAttack(id, attacker, ent)
{
	if(!pojedynek[0] || !is_user_connected(id) || id == attacker)
		return HAM_IGNORED;
	
	if((kandydaci_pojedynek[0] == id || kandydaci_pojedynek[1] == id) && czas_do_pojedynku > 0) {
		return HAM_SUPERCEDE;
	}
	
	if(pojedynek[0] == id && pojedynek[1] != attacker)
		return HAM_SUPERCEDE;
		
	if(pojedynek[0] == attacker && pojedynek[1] != id)
		return HAM_SUPERCEDE;	

	if(is_user_connected(attacker)) {/*
		if(typ_pojedynku == 1 && get_pdata_int(id, 75, 5) != HIT_HEAD) {
			return HAM_SUPERCEDE;
		}
		*/
		if(typ_pojedynku == 2) {
			SetHamParamFloat(4, 999.0);
			return HAM_HANDLED;
		}
		
		if(bronie_pojedynek == CSW_KNIFE && ent != -1 && !kosy)
		{
			if(ent == attacker)
				return HAM_SUPERCEDE;
	
			new Float:ViewAngle[3], iOrigin[3];
			for(new i=0; i<3; i++) 
				ViewAngle[i] = random_float(-50.0, 50.0);
	
			get_user_origin(id, iOrigin);
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
			write_byte(TE_BLOODSPRITE);
			write_coord(iOrigin[0]);
			write_coord(iOrigin[1]);
			write_coord(iOrigin[2]);
			write_short(blood2);
			write_short(blood);
			write_byte(229);
			write_byte(25);
			message_end();
				
			set_pev(id, pev_punchangle, ViewAngle);
			SetHamParamEntity(2, attacker);
			return HAM_IGNORED;
		}
	}
	
	return HAM_IGNORED;
}


public TraceLine(Float:StartPos[3],Float:EndPos[3], SkipMonsters, id, Trace)
{
	if(!is_user_alive(id))
		return FMRES_IGNORED;

	if(typ_pojedynku != 1)
		return FMRES_IGNORED;

	new Hited = get_tr2(Trace, TR_pHit);
	new HitGroup = (1 << get_tr2(Trace, TR_iHitgroup));
 
	if(!is_user_alive(Hited))
		return FMRES_IGNORED;
 
	if(!(HitGroup & (1 << 1)))
	{
		set_tr2(Trace, TR_flFraction, 1.0);
		return FMRES_SUPERCEDE;
	}
	return FMRES_IGNORED;
}

public SmiercGraczaPost(id, attacker, shouldgib)
{	
	if(!is_user_connected(id))
		return HAM_IGNORED;
	
	if(id == pojedynek[1]) {
		
		jail_set_user_block(id, false);
		
		client_print(0, print_center, "Losowanie przeciwnika...")
		set_task(2.0, "SzukajPrzeciwnika")
		
		RozdajObstawioneSzlugi(0);
	}
	
	if(id == pojedynek[0]) {
		RozdajObstawioneSzlugi(1);
	}
		
	
	if(kandydaci_pojedynek[1] == id) {
		client_print(0, print_center, "Losowanie przeciwnika...")
		set_task(2.0, "SzukajPrzeciwnika");
	}

	return HAM_IGNORED;
}

public WeaponAttack(ent)
{
	new id = get_pdata_cbase(ent, 41, 4);
	if(pojedynek[0] == id || pojedynek[1] == id)
	{
		if(bronie_pojedynek == CSW_KNIFE && !kosy)
			StworzKnife(id);
		else if(bronie_pojedynek != CSW_KNIFE)
			cs_set_user_bpammo(id, bronie_pojedynek, 1);
	}
}		

public client_disconnected(id)
{
	if(pojedynek[1] == id && czas_do_pojedynku <= 0) {
		RozdajObstawioneSzlugi(0);
		
		client_print(0, print_center, "Losowanie przeciwnika...");
		set_task(2.0, "SzukajPrzeciwnika");
	}
	
	if(pojedynek[0] == id && czas_do_pojedynku <= 0) {
		RozdajObstawioneSzlugi(1);
	}
	
	
	if(kandydaci_pojedynek[1] == id && czas_do_pojedynku > 0) {
		client_print(0, print_center, "Losowanie przeciwnika...");
		set_task(2.0, "SzukajPrzeciwnika");
	}
		
}

public SzukajPrzeciwnika()
{
	kandydaci_pojedynek[1] = RandomPlayer(2);
	if(!kandydaci_pojedynek[1])
		return;
	
	remove_task(333);
	remove_task(TASK_KONIECPOJEDYNKU);
	ZacznijObstawianie();
}

public RegisterHams(bool:wartosc)
{
	if(wartosc)
	{
		if(fHamKill)
			EnableHamForward(fHamKill);
		else
			fHamKill = RegisterHam(Ham_Killed, "player", "SmiercGraczaPost", 1);
		
		if(fHamDamage)
			EnableHamForward(fHamDamage);
		else
			fHamDamage = RegisterHam(Ham_TakeDamage, "player", "TakeDamage");
			
		if(fHamTrace)
			EnableHamForward(fHamTrace);
		else
			fHamTrace = RegisterHam(Ham_TraceAttack, "player", "TraceAttack");
			

		if(!fTraceLine) {
			fTraceLine = register_forward(FM_TraceLine, "TraceLine");
		}
		
		if(bronie_pojedynek != CSW_HEGRENADE)
		{
			if(fHamWeapon[bronie_pojedynek])
				EnableHamForward(fHamWeapon[bronie_pojedynek]);
			else
			{
				new WeaponName[24];
				get_weaponname(bronie_pojedynek, WeaponName, 23);
				fHamWeapon[bronie_pojedynek] = RegisterHam(Ham_Weapon_PrimaryAttack, WeaponName, "WeaponAttack", 1);
			}
		}
		
		if(bronie_pojedynek == CSW_HEGRENADE && !fDropGranade)
			fDropGranade = register_forward(FM_SetModel, "SetModel", 1);
		
		if(bronie_pojedynek == CSW_KNIFE && !fDotykKnife)
			fDotykKnife = register_forward(FM_Touch, "TouchKnife");
	}
	else
	{
		if(fHamKill)
			DisableHamForward(fHamKill);
			
		if(fHamDamage)
			DisableHamForward(fHamDamage);
			
		if(fHamTrace)
			DisableHamForward(fHamTrace);	
			
		
		if(fTraceLine) {
			unregister_forward(FM_Touch, fTraceLine);
		}
		
		if(fHamWeapon[bronie_pojedynek])
			DisableHamForward(fHamWeapon[bronie_pojedynek]);
			
		if(fDropGranade)
		{
			unregister_forward(FM_SetModel, fDropGranade, 1);
			fDropGranade = 0;
		}
			
		if(fDotykKnife)
		{
			unregister_forward(FM_Touch, fDotykKnife);
			fDotykKnife = 0;
		}
		
	}
}
/////////// Pojedynek ///////////
public CmdStart(id, uc_handle, seed) {
	if(!is_user_connected(id) || !is_user_alive(id))
	return PLUGIN_CONTINUE;

	if(celownik)
	set_uc(uc_handle, UC_Buttons, get_uc(uc_handle, UC_Buttons) & ~IN_ATTACK2);
	return PLUGIN_CONTINUE;
}

public SetModel(ent, model[])
{

	if(!pev_valid(ent)) 
		return FMRES_IGNORED;

	if(!equali(model, "models/w_hegrenade.mdl")) 
		return FMRES_IGNORED;

	new id = pev(ent, pev_owner);
	if(pojedynek[0] == id || pojedynek[1] == id)
		cs_set_user_bpammo(id, CSW_HEGRENADE, 2);
		
	return FMRES_IGNORED;
}

public TouchKnife(ent, id)
{
	if(!pev_valid(ent))
		return FMRES_IGNORED
	
	new class[32];
	pev(ent, pev_classname, class, 31);

	if(!equal(class, "throw_knife"))
		return FMRES_IGNORED;
		
	if((0 < id <= MAX) && is_user_alive(id))
	{
		new attacker = pev(ent, pev_owner);
		ExecuteHamB(Ham_TakeDamage, id, ent, attacker, 30.0, DMG_BULLET);
	}
	engfunc(EngFunc_RemoveEntity, ent);
	return FMRES_IGNORED;
}

public StworzKnife(id)
{
	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));
	new Float:vAngles[3], Float:nVelocity[3], Float:vOriginf[3], vOrigin[3];
		
	set_pev(ent, pev_owner, id);
	set_pev(ent, pev_classname, "throw_knife");
	engfunc(EngFunc_SetModel, ent, "models/w_throw.mdl");
	set_pev(ent, pev_gravity, 0.25);	
	
	get_user_origin(id, vOrigin, 1);
	IVecFVec(vOrigin, vOriginf);
	set_pev(ent, pev_origin,vOriginf);
	
	static Float:player_angles[3];
	pev(id, pev_angles, player_angles);
	player_angles[2] = 0.0;
	set_pev(ent, pev_angles, player_angles);
	
	pev(id, pev_v_angle, vAngles);
	set_pev(ent, pev_v_angle, vAngles);
	
	pev(id, pev_view_ofs, vAngles);
	set_pev(ent, pev_view_ofs, vAngles);

	set_pev(ent, pev_movetype, MOVETYPE_TOSS);
	set_pev(ent, pev_solid, 2);
	
	velocity_by_aim(id, 700, nVelocity);	
	set_pev(ent, pev_velocity, nVelocity);
	
	set_pev(ent, pev_effects, pev(ent, pev_effects) & ~EF_NODRAW);
	set_pev(ent, pev_sequence, 0);
	set_pev(ent, pev_framerate, 1.0);
}

