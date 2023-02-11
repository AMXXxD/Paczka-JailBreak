#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <cstrike>
#include <nvault>
#include <jailbreak>

native cs_set_player_model(id, model[]);
native jail_get_szlugi(id);
native jail_set_szlugi(id, ile);

#define MAX_ILOSC_SKINOW 8
enum { NOZ = 0, TT, CT };
enum { SZLUGI = 0, FLAGI };
#define NAZWA_RODZAJU(%1) (%1==0)?"noza":((%1==1)?"wieznia":"klawisza")

new g_szNazwaSkina[3][MAX_ILOSC_SKINOW+1][32];
new g_szSciezkaSkina[3][MAX_ILOSC_SKINOW+1][256];
new g_szSciezkaSkina2[3][MAX_ILOSC_SKINOW+1][256];
new g_iRodzajWymogowSkina[3][MAX_ILOSC_SKINOW+1];
new g_iWymogiSkina[3][MAX_ILOSC_SKINOW+1];
new g_iRodzajNoza[MAX_ILOSC_SKINOW+1];
new g_iIloscSkinow[3];

new g_iVault;

new g_iSkinGracza[33][3];
new g_iWyborRodzajuGracza[33];

public plugin_init() {
	register_plugin("Jail: Skiny", "1.0", "d0naciak.pl");
	
	register_clcmd("say /skiny", "cmd_Skiny");
	register_clcmd("say /modele", "cmd_Skiny");
	
	RegisterHam(Ham_Item_Deploy, "weapon_knife", "fw_WybralNoz_Post", 1);
	RegisterHam(Ham_Item_AddToPlayer, "weapon_knife", "fw_DostalNoz_Post", 1);
		
	RegisterHam(Ham_Spawn, "player", "fw_Odrodzenie_Post", 1);
	
	register_forward(FM_EmitSound, "fw_EmitSound");
	
	g_iVault = nvault_open("Skiny_JB");
}

public plugin_natives() {
	register_native("jail_show_skins_menu", "cmd_Skiny", 1);
}

public plugin_precache() {
	WczytajSkiny();
	
	precache_sound("weapons/prawy_przycisk.wav");
	precache_sound("weapons/uderzenie_mur.wav");
	precache_sound("weapons/hit1.wav");
	precache_sound("weapons/hit2.wav");
	precache_sound("weapons/machanie.wav");
}

public plugin_end() {
	nvault_close(g_iVault);
}

public client_authorized(id) {
	set_task(2.0, "task_WczytajSkinyGracza", id);
}

public client_disconnected(id) {
	remove_task(id);
}

public cmd_Skiny(id) {
	new iMenu = menu_create(fmt("\d%s | Menu^n\r[SKINY]\w Menu skinow:", forum), "Skiny_Handler");	
	
	menu_additem(iMenu, "Skiny noza");
	menu_additem(iMenu, "Skiny wieznia");
	menu_additem(iMenu, "Skiny klawisza");
	
	menu_setprop(iMenu, MPROP_EXITNAME, "\d×\w Wyjdz");	
	menu_display(id, iMenu);
	return PLUGIN_HANDLED;
}

public Skiny_Handler(id, iMenu, iItem) {
	if(iItem == MENU_EXIT) {
		menu_destroy(iMenu);
		return PLUGIN_CONTINUE;
	}
	
	g_iWyborRodzajuGracza[id] = iItem;
	ListaSkinow(id);
	
	menu_destroy(iMenu);
	return PLUGIN_CONTINUE;
}

public ListaSkinow(id) {
	new iRodzaj = g_iWyborRodzajuGracza[id];
	
	if(!g_iIloscSkinow[iRodzaj]) {
		PokazWiadomosc(id, "Nie znaleziono skinow dla^3 %s.", NAZWA_RODZAJU(iRodzaj));
		return;
	}
	
	new szItem[128], szKluczVault[128], szNick[32], iMenu;
	
	formatex(szItem, 127, "\d%s | Menu^n\r[SKINY]\w Lista skinow \w%s", forum, NAZWA_RODZAJU(iRodzaj));
	iMenu = menu_create(szItem, "ListaSkinow_Handler");
	
	get_user_name(id, szNick, 31);
	for(new i = 1; i <= g_iIloscSkinow[iRodzaj]; i++) {
		formatex(szKluczVault, 127, "%s-skin-%d-%d", szNick, iRodzaj, i);
		
		if(nvault_get(g_iVault, szKluczVault) || (g_iRodzajWymogowSkina[iRodzaj][i] == FLAGI && get_user_flags(id) & g_iWymogiSkina[iRodzaj][i])) {
			formatex(szItem, 127, "\y%s", g_szNazwaSkina[iRodzaj][i]);
			menu_additem(iMenu, szItem, "1");
		} else {
			formatex(szItem, 127, "%s", g_szNazwaSkina[iRodzaj][i]);
			menu_additem(iMenu, szItem, "0");
		}
	}
	
	menu_setprop(iMenu, MPROP_BACKNAME, "\d×\w Wroc");
	menu_setprop(iMenu, MPROP_NEXTNAME, "\d×\w Dalej");
	menu_setprop(iMenu, MPROP_EXITNAME, "\d×\w Wyjdz");
	menu_display(id, iMenu);
}

public ListaSkinow_Handler(id, iMenu, iItem) {
	new iRodzaj = g_iWyborRodzajuGracza[id];
	
	if(iItem < 0) {
		if(iItem == MENU_EXIT) {
			UstawSkina(id, iRodzaj, 0); //dodaj pod 0 domyslne skiny
			cmd_Skiny(id);
			
			menu_destroy(iMenu);
		}
		
		return PLUGIN_CONTINUE;
	}
	
	new iAccess, iCb, szMaDostep[4], iIdSkina = iItem + 1;
	menu_item_getinfo(iMenu, iItem, iAccess, szMaDostep, 3, _, _, iCb);
	
	menu_destroy(iMenu);
	
	if(str_to_num(szMaDostep) == 1) {
		UstawSkina(id, iRodzaj, iIdSkina);
		cmd_Skiny(id);
	} else {
		new szItem[128], szIdSkina[4];
		
		formatex(szItem, 127, "\d%s | Menu^n\r[SKINY]\w Info o skinie %s: \w%s", forum, NAZWA_RODZAJU(iRodzaj), g_szNazwaSkina[iRodzaj][iIdSkina]);
		new iNoweMenu = menu_create(szItem, "Skin_Handler");
		
		num_to_str(iIdSkina, szIdSkina, 3);
		
		menu_additem(iNoweMenu, "Podglad skina", szIdSkina);
		
		if(g_iRodzajWymogowSkina[iRodzaj][iIdSkina] == SZLUGI) {
			formatex(szItem, 127, "Kup za \y%d szlug(i/ow)", g_iWymogiSkina[iRodzaj][iIdSkina]);
		} else {
			copy(szItem, 127, "Kup skina");
		}
		
		menu_additem(iNoweMenu, szItem, szIdSkina);
		
		menu_setprop(iNoweMenu, MPROP_EXITNAME, "\d×\w Powrot");	
		menu_display(id, iNoweMenu);
	}
	return PLUGIN_CONTINUE;
}

public Skin_Handler(id, iMenu, iItem) {
	if(iItem < 0) {
		if(iItem == MENU_EXIT) {
			ListaSkinow(id);
			menu_destroy(iMenu);
		}
		
		return PLUGIN_CONTINUE;
	}
	
	new iAccess, iCb, szIdSkina[4],iRodzaj = g_iWyborRodzajuGracza[id], iIdSkina;
	menu_item_getinfo(iMenu, iItem, iAccess, szIdSkina, 3, _, _, iCb);
	iIdSkina = str_to_num(szIdSkina);
	
	if(!iItem) {
		PodgladSkinaMotd(id, iRodzaj, iIdSkina);
		menu_display(id, iMenu);
	} else {
		if(g_iRodzajWymogowSkina[iRodzaj][iIdSkina] == SZLUGI) {
			new iCena = g_iWymogiSkina[iRodzaj][iIdSkina], iIloscSzlugow = jail_get_szlugi(id);
		
			if(iIloscSzlugow >= iCena) {
				new szNick[32], szKluczVault[128];
				
				get_user_name(id, szNick, 31);
				formatex(szKluczVault, 127, "%s-skin-%d-%d", szNick, iRodzaj, iIdSkina);
				
				nvault_set(g_iVault, szKluczVault, "1");
				jail_set_szlugi(id, iIloscSzlugow - iCena);
				
				PokazWiadomosc(id, "Kupiles skina %s^x03 '%s'", NAZWA_RODZAJU(iRodzaj), g_szNazwaSkina[iRodzaj][iIdSkina]);
				menu_destroy(iMenu);
				
				ListaSkinow(id);
			} else {
				PokazWiadomosc(id, "Brakuje Ci szlugow na tego skina!");
				menu_display(id, iMenu);
			}
		} else {
			PokazWiadomosc(id, "Nie masz dostepu do tego skina!");
			PokazWiadomosc(id, "Aby go zdobyc, uzyj komendy^3 /sklepsms");
			
			menu_display(id, iMenu);
		}
	}
	
	return PLUGIN_CONTINUE;
}

public fw_DostalNoz_Post(iEnt, id) {
	if(!pev_valid(iEnt) || !is_user_alive(id)) {
		return HAM_IGNORED;
	}
	
	if(cs_get_weapon_id(iEnt) == CSW_KNIFE) {
		set_task(0.1, "task_DostalNoz", id);
	}
	
	return HAM_IGNORED;
}

public task_DostalNoz(id) {
	if(!is_user_alive(id)) {
		return PLUGIN_CONTINUE;
	}
	
	if(get_user_weapon(id) == CSW_KNIFE) {
		new iIdSkina = g_iSkinGracza[id][NOZ];

		if(iIdSkina) {
			set_pev(id, pev_viewmodel2, g_szSciezkaSkina[NOZ][iIdSkina]);
			
			if(g_szSciezkaSkina2[NOZ][iIdSkina][0]) {
				set_pev(id, pev_weaponmodel2, g_szSciezkaSkina2[NOZ][iIdSkina]);
			}
		}
	}
	
	return PLUGIN_CONTINUE;
}

public fw_WybralNoz_Post(iEnt) {
	if(!pev_valid(iEnt)) {
		return HAM_IGNORED;
	}
	
	new id = pev(iEnt, pev_owner);
	
	if(!is_user_alive(id)) {
		return HAM_IGNORED;
	}
	
	new iIdSkina = g_iSkinGracza[id][NOZ];
	
	if(iIdSkina) {
		set_pev(id, pev_viewmodel2, g_szSciezkaSkina[NOZ][iIdSkina]);
		if(g_szSciezkaSkina2[NOZ][iIdSkina][0]) {
			set_pev(id, pev_weaponmodel2, g_szSciezkaSkina2[NOZ][iIdSkina]);
		}
	}
	
	return HAM_IGNORED;
}

public fw_Odrodzenie_Post(id) {
	if(!is_user_alive(id)) {
		return HAM_IGNORED;
	}
	
	new iTeam = get_user_team(id);
	
	if(!(1 <= iTeam <= 2)) {
		return HAM_IGNORED;
	}
	new iIdSkina = g_iSkinGracza[id][iTeam];
	cs_set_player_model(id, g_szSciezkaSkina[iTeam][iIdSkina]);
	
	return HAM_IGNORED;
}


public fw_EmitSound(id, channel, sample[])
{	
	if(!is_user_alive(id)) 
		return FMRES_IGNORED;
	
	if(equal(sample, "weapons/knife_", 14))
	{
		new iSkin = g_iSkinGracza[id][NOZ];
		
		if(g_iRodzajNoza[iSkin]) {
			switch(sample[17])
			{
				case ('b'): emit_sound(id, CHAN_WEAPON, "weapons/prawy_przycisk.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);
				case ('w'): emit_sound(id, CHAN_WEAPON, "weapons/uderzenie_mur.wav", 1.0, ATTN_NORM, 0, PITCH_LOW);
				case ('s'): emit_sound(id, CHAN_WEAPON, "weapons/machanie.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);
				case ('1'): emit_sound(id, CHAN_WEAPON, "weapons/hit1.wav", random_float(0.5, 1.0), ATTN_NORM, 0, PITCH_NORM);
				case ('2'): emit_sound(id, CHAN_WEAPON, "weapons/hit2.wav", random_float(0.5, 1.0), ATTN_NORM, 0, PITCH_NORM);
			}
			
			return FMRES_SUPERCEDE;
		}
	}
	if(equal(sample, "common/wpn_denyselect.wav"))
		return FMRES_SUPERCEDE;
	return FMRES_IGNORED;
}

UstawSkina(id, iRodzaj, iIdSkina) {
	new szNick[32], szKluczVault[128], szIdSkina[4];
	
	g_iSkinGracza[id][iRodzaj] = iIdSkina;
	
	get_user_name(id, szNick, 31);
	formatex(szKluczVault, 127, "%s-domyslny-%d", szNick, iRodzaj);
	num_to_str(iIdSkina, szIdSkina, 3);
	nvault_set(g_iVault, szKluczVault, szIdSkina);
		
	if(iRodzaj == NOZ && get_user_weapon(id) == CSW_KNIFE/* && get_user_team(id) == 1*/) {
		set_pev(id, pev_viewmodel2, g_szSciezkaSkina[iRodzaj][iIdSkina]);
		
		if(g_szSciezkaSkina2[iRodzaj][iIdSkina][0]) {
			set_pev(id, pev_weaponmodel2, g_szSciezkaSkina2[iRodzaj][iIdSkina]);
		}
	}
		
	PokazWiadomosc(id, "%s Jako skin^3 %s^1 ustawiono^4 %s", NAZWA_RODZAJU(iRodzaj), g_szNazwaSkina[iRodzaj][iIdSkina]);
}

PodgladSkinaMotd(id, iRodzaj, iIdSkina) {
	new szSciezka[256], szMOTD[512];
	static szFD[128];
	
	if(!szFD[0]) {
		get_cvar_string("sv_downloadurl", szFD, 127);
	}
	
	if(iRodzaj == NOZ) {
		copy(szSciezka, 255, g_szSciezkaSkina[NOZ][iIdSkina]);
		replace(szSciezka, 255, ".mdl", ".png");
	} else {
		formatex(szSciezka, 255, "models/player/%s/%s.png", g_szSciezkaSkina[iRodzaj][iIdSkina], g_szSciezkaSkina[iRodzaj][iIdSkina]);
	}
	
	
	formatex(szMOTD, 511, "<html><body style=^"padding: 0; margin: 0;^"><img style=^"width: 100%%; height: 100%%;^" src=^"%s/%s^">", szFD, szSciezka);
	show_motd(id, szMOTD, "Podglad skina");
}

public task_WczytajSkinyGracza(id) {
	new szNick[32], szKluczVault[128], iIdSkina;
	
	get_user_name(id, szNick, 31);
	
	for(new i = 0; i < 3; i++) {
		formatex(szKluczVault, 127, "%s-domyslny-%d", szNick, i);
		
		iIdSkina = g_iSkinGracza[id][i] = nvault_get(g_iVault, szKluczVault);
		
		if(g_iRodzajWymogowSkina[i][iIdSkina] == FLAGI && !(get_user_flags(id) & g_iWymogiSkina[i][iIdSkina])) {
			g_iSkinGracza[id][i] = 0;
			nvault_remove(g_iVault, szKluczVault);
		}
	}
}

WczytajSkiny() { //sprawdz caly public
	new iPlik = fopen("addons/amxmodx/configs/skiny.ini", "r");
	
	if(!iPlik) {
		return 0;
	}
	
	//DODAJ TO W CVARACH MOZE EJJ
	copy(g_szNazwaSkina[NOZ][0], 31, "Domyslny");
	copy(g_szNazwaSkina[TT][0], 31, "Domyslny");
	copy(g_szNazwaSkina[CT][0], 31, "Domyslny");
	copy(g_szSciezkaSkina[NOZ][0], 255, "models/JailBreak_Izolatka/v_hand.mdl");
	copy(g_szSciezkaSkina2[NOZ][0], 255, "models/JailBreak_Izolatka/p_piesci.mdl");
	copy(g_szSciezkaSkina[TT][0], 255, "jail_wiezien_pro");
	copy(g_szSciezkaSkina[CT][0], 255, "jail_straznik_pro");
	g_iRodzajNoza[0] = 1;
	
	while(!feof(iPlik)) {
		// "nazwa" "rodzaj" "cena" "sciezka1" "sciezka2"
		new szLinia[512], szNazwa[32], szRodzaj[4], szRodzajNoza[4], szWymogi[8], szSciezka[2][256], iRodzaj, iIdSkina;
		
		fgets(iPlik, szLinia, 511);
		trim(szLinia);
		
		if(szLinia[0] == ';' || !szLinia[0]) 
			continue;
		
		parse(szLinia, szNazwa, 31, szRodzaj, 3, szWymogi, 7, szSciezka[0], 255, szSciezka[1], 255, szRodzajNoza, 3);
		iRodzaj = str_to_num(szRodzaj);
		
		if(g_iIloscSkinow[iRodzaj] >= MAX_ILOSC_SKINOW) {
			server_print("[JAIL:SKINY] Za duzo skinow rodzaju %d. Pominieto wczytanie skina %s", iRodzaj, szNazwa);
			continue;
		}
		
		iIdSkina = ++g_iIloscSkinow[iRodzaj];
		
		precache_model(szSciezka[0]);
		if(szSciezka[1][0]) {
			precache_model(szSciezka[1]);
		}
		
		if(iRodzaj != NOZ) {
			copy(szSciezka[0], 255, szSciezka[0][14]);
			copy(szSciezka[0], 255, szSciezka[0][contain(szSciezka[0], "/")+1]);
			copy(szSciezka[0][strlen(szSciezka[0])-4], 251, "");
		} else {
			if(szSciezka[1][0]) {
				copy(g_szSciezkaSkina2[iRodzaj][iIdSkina], 255, szSciezka[1]);
			}
			
			g_iRodzajNoza[iIdSkina] = str_to_num(szRodzajNoza);
		}
		
		copy(g_szNazwaSkina[iRodzaj][iIdSkina], 31, szNazwa);
		copy(g_szSciezkaSkina[iRodzaj][iIdSkina], 255, szSciezka[0]);
		
		if(isdigit(szWymogi[0])) {
			g_iWymogiSkina[iRodzaj][iIdSkina] = str_to_num(szWymogi);
			g_iRodzajWymogowSkina[iRodzaj][iIdSkina] = SZLUGI;
		} else {
			g_iWymogiSkina[iRodzaj][iIdSkina] = read_flags(szWymogi);
			g_iRodzajWymogowSkina[iRodzaj][iIdSkina] = FLAGI;
		}
	}
	return 1;
}
