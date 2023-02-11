#include <amxmodx>
#include <fakemeta>
#include <fakemeta_util>
#include <jailbreak>

new const g_szSciezkiCzapek[][] = {
	"models/JailBreak_Izolatka/czapki_jb/czapki_1.mdl",
	"models/JailBreak_Izolatka/czapki_jb/czapki_2.mdl",
	"models/JailBreak_Izolatka/czapki_jb/czapki_3.mdl"
}

//Wzor: "Nazwa", submodel, "flagi", ktora sciezka
new const g_szListaCzapek[][][] = {
	{ "Afro", 24, "", 1 },
	{ "Aniol", 17, "", 2 },
	{ "Awesome", 2, "", 0 },
	{ "Balwan", 29, "", 0 },
	{ "Batman", 27, "", 1 },
	{ "Bomba", 7, "", 0 },
	{ "Cheetos", 28, "", 1 },
	{ "Czarny smok [VIP]", 6, "t", 0 },
	{ "Daffy [SVIP]", 29, "s", 1 },
	{ "Diabelek", 14, "", 0 },
	{ "Doniczka", 0, "", 1 },
	{ "Duch", 23, "", 0 },
	{ "Elf", 17, "", 0 },
	{ "Gaara [VIP]", 31, "t", 0 },
	{ "Genki", 30, "", 1 },
	{ "Globus", 16, "", 0 },
	{ "Hello Kitty!", 22, "", 0 },
	{ "Hokejowa", 27, "", 0 },
	{ "Jack Jack", 18, "", 2 },
	{ "Kask futbolisty", 19, "", 0 },
	{ "Kapelusz", 9, "", 1 },
	{ "Kapelusz czarodzieja", 7, "", 1 },
	{ "Klon Star Wars [SVIP]", 10, "s", 0 },
	{ "Kogut", 0, "", 2 },
	{ "Komandosa", 9, "", 0 },
	{ "Kosmonautka", 8, "", 1 },
	{ "Kowbojka", 12, "", 0 },
	{ "Krolik Bugs [VIP]", 14, "t", 1 },
	{ "Krowa (dobra)", 11, "", 0 },
	{ "Krowa (zla)", 26, "", 1 },
	{ "Krzyk", 3, "", 1 },
	{ "Krzyz", 13, "", 0 },
	{ "Kucharska", 1, "", 1 },
	{ "Kufel", 4, "", 0 },
	{ "Kura", 10, "", 2 },
	{ "Leonardo", 1, "", 2 },
	{ "Marynarska z fajka", 2, "", 1 },
	{ "Maska starszego mnicha [SVIP]", 15, "s", 0 },
	{ "Mikolajka", 2, "", 2 },
	{ "Mleko", 19, "", 2 },
	{ "Mocherowa", 5, "", 0 },
	{ "Muchomor", 13, "", 2 },
	{ "Panda", 3, "", 2 },
	{ "Pikachu", 4, "", 2 },
	{ "Piracka", 25, "", 0 },
	{ "Pony Rainbow Dash ", 21, "", 2 },
	{ "Pony Trixie", 22, "", 2 },
	{ "Prezent [VIP]", 21, "t", 0 },
	{ "Rastaman", 30, "", 0 },
	{ "Rekin", 14, "", 2 },
	{ "Renifer", 10, "", 1 },
	{ "Rozowa pantera", 5, "", 2 },
	{ "Ryba", 11, "", 2 },
	{ "Ser", 20, "", 2 },
	{ "Siusiak", 6, "", 2 },
	{ "Smutny misio", 12, "", 2 },
	{ "Sombrero", 6, "", 1 },
	{ "Son Goku", 7, "", 2 },
	{ "Sonic", 8, "", 0 },
	{ "Spodniczka", 18, "", 1 },
	{ "Steam", 15, "", 2 },
	{ "TV", 16, "", 2 },
	{ "Tygrys", 8, "", 2 },
	{ "Urodzinowa", 24, "", 0 },
	{ "Uszy królika", 19, "", 1 },
	{ "Whoop", 5, "", 1 },
	{ "Wiadro", 9, "", 2 },
	{ "Wilk", 23, "", 2 },
	{ "Wojskowa", 4, "", 1 },
	{ "Worek na glowe", 3, "", 0 },
	{ "Zabka [SVIP]", 31, "s", 1 },
	{ "Z daszkiem FS [VIP]", 20, "t", 0 },
	{ "Zelazny helm Wikinga [SVIP]", 28, "s", 0 },
	{ "Ziemniak", 11, "", 1 },
	{ "Zla Dynia", 18, "", 0 },
	{ "Zimowa 228 [VIP]", 0, "t", 0 }
}

new g_iCzapkaGracza[33];
public plugin_init() {
	register_plugin("Czapki", "0.1", "SgtBane, K!113r & d0naciak");
	register_clcmd("say /czapki", "cmd_Czapki");
	register_clcmd("say /hats", "cmd_Czapki");
}

public plugin_natives() {
	register_native("hats_menu", "cmd_Czapki", 1);
	register_native("set_user_hat", "nat_UstawCzapke", 1);
}

public nat_UstawCzapke(id, iModel, iSubModel) {
	new iEnt = fm_find_ent_by_owner(0, "hat_jb", id), bool:bMial = true;
		
	if(iEnt <= 0) {
		iEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));
		bMial = false;
	}
		
	if(iEnt > 0) {
		if(!bMial) {
			set_pev(iEnt, pev_classname, "hat_jb");
			set_pev(iEnt, pev_movetype, MOVETYPE_FOLLOW);
			set_pev(iEnt, pev_solid, SOLID_NOT);
			set_pev(iEnt, pev_aiment, id);
			set_pev(iEnt, pev_owner, id);
			set_pev(iEnt, pev_rendermode, kRenderNormal);
		}
			
		engfunc(EngFunc_SetModel, iEnt, g_szSciezkiCzapek[iModel]);
		set_pev(iEnt, pev_body, iSubModel);
	}
}

public plugin_precache() {
	for(new i = 0; i < sizeof g_szSciezkiCzapek; i++) {
		precache_model(g_szSciezkiCzapek[i]);
	}
}

public client_disconnected(id) {
	Set_Hat(id, 0, false);
}
public cmd_Czapki(id)
{  
	if(!is_user_alive(id)){
		return PLUGIN_HANDLED;
	}
	new szItem[128], iMenu;
	
	if(!g_iCzapkaGracza[id]) {
		formatex(szItem, 127, "\d%s | Menu^n\r[CZAPKI]\w Twoja czapka:\d Brak\w", forum);
	} else {
		formatex(szItem, 127, "\d%s | Menu^n\r[CZAPKI]\w Twoja czapka:\r %s\w", forum, g_szListaCzapek[g_iCzapkaGracza[id]][0]);
	}
	
	iMenu = menu_create(szItem, "Czapki_Handler");
	
	menu_additem(iMenu, "\rZdejmij czapke");
	
	for(new i = 0; i < sizeof g_szListaCzapek; i++) {
		menu_additem(iMenu, g_szListaCzapek[i][0]);	
	}
	
	menu_setprop(iMenu, MPROP_BACKNAME, "\d×\w Wroc");
	menu_setprop(iMenu, MPROP_NEXTNAME, "\d×\w Dalej");
	menu_setprop(iMenu, MPROP_EXITNAME, "\d×\w Wyjdz");
	menu_display(id, iMenu);
	
	return PLUGIN_HANDLED;
}
public Czapki_Handler(id, iMenu, iItem) {
	switch(iItem) {
		case MENU_EXIT: {
			menu_destroy(iMenu);
		}
		
		case 0..99: {
			if(!Set_Hat(id, iItem)) {
				PokazWiadomosc(id, "Nie masz dostepu do tej^4 czapki!");
				PokazWiadomosc(id, "Aby ja zdobyc, uzyj komendy^4 /sklepsms");
				
				menu_display(id, iMenu);
			}
		}
	}
}

Set_Hat(id, iCzapka, const bool:bCzyPolaczony = true) {
	if(iCzapka) {
		iCzapka --;
		
		if(g_szListaCzapek[iCzapka][2][0] && !(get_user_flags(id) & read_flags(g_szListaCzapek[iCzapka][2]))) {
			return 0;
		}
		
		new iEnt = fm_find_ent_by_owner(0, "hat_jb", id), bool:bMial = true;
		
		if(iEnt <= 0) {
			iEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));
			bMial = false;
		}
		
		if(iEnt > 0) {
			if(!bMial) {
				set_pev(iEnt, pev_classname, "hat_jb");
				set_pev(iEnt, pev_movetype, MOVETYPE_FOLLOW);
				set_pev(iEnt, pev_solid, SOLID_NOT);
				set_pev(iEnt, pev_aiment, id);
				set_pev(iEnt, pev_owner, id);
				set_pev(iEnt, pev_rendermode, kRenderNormal);
			}
			
			engfunc(EngFunc_SetModel, iEnt, g_szSciezkiCzapek[g_szListaCzapek[iCzapka][3][0]]);
			set_pev(iEnt, pev_body, g_szListaCzapek[iCzapka][1][0]);
		}
		
		new szNazwaCzapki[32];

		copy(szNazwaCzapki, 31, g_szListaCzapek[iCzapka][0]);
		replace(szNazwaCzapki, 31, "\r", "");
		replace(szNazwaCzapki, 31, "\y", "");
		PokazWiadomosc(id, "Zalozyles czapke:^4 %s", g_szListaCzapek[iCzapka][0]);
	} else {
		new iEnt = fm_find_ent_by_owner(0, "hat_jb", id);
		
		if(iEnt > 0) {
			fm_remove_entity(iEnt);
		}
		
		if(bCzyPolaczony) {
			PokazWiadomosc(id, "Zdjales ^4czapke.");
		}
	}
	
	g_iCzapkaGracza[id] = iCzapka;
	return 1;
}
