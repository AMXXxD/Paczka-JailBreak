#include <amxmodx>
#include <amxmisc>
#include <fakemeta_util>
#include <hamsandwich>
#include <fun>
#include <cstrike>
#include <jailbreak>
#include <engine>

#define PLUGIN "Jail Mod"
#define VERSION "1.0.6a"
#define AUTHOR "Cypis"

#define MAX 32

#define strip_user_weapons2(%0) strip_user_weapons(%0), set_pdata_int(%0, 116, 0)

native cs_set_player_model(id, newmodel[]); //wymaga cs_player_models_api.amxx
native jail_set_szlugi(id, wartosc);
native jail_get_szlugi(id);

new static powody_siedzenia[][] = { 
	
	"Bycie debilem",
	"Brak konta na forum",
	"Ogladanie disa",
	"Granie na cheatach",
	"Kradziez naklejek gangu swiezakow",
	"Kopanie dzieci w przedszkolu",
	"Slaby bunt",
	"Przycinanie dillera",
	"Napad na sklep z babcia",
	"Molestowanie kolegi z celi",
	"Sex z 13 latka"
}

enum
{
	ID_DZWIEK_POSZ = 7000,
	ID_LOS_PROWADZACY,
	ID_CZAS,
	ID_FREZZ,
	ID_SPEED_FZ,
}

#define WSZYSCY 0
#define ZYWI 1

#define TASK_HUD 1906363

new ilosc_graczy[2];
new array_graczy[2][MAX+1];

new const maxAmmo[31] = {0,52,0,90,1,31,1,100,90,1,120,100,100,90,90,90,100,120,30,120,200,31,90,120,90,2,35,90,90,0,100};
new const dni_tygodnia[][] = {"Niedziela", "Poniedzialek", "Wtorek", "Sroda", "Czwartek", "Piatek", "Sobota"};

new SyncHudObj1, SyncHudObj3, SyncHudObj4, SyncHudObj5, jail_day;//SyncHudObj2
new bool:usuwanie_ustawien, bool:end_usun, bool:pokaz_raz, bool:czas_bronie, bool:pojedynek[MAX+1], bool:free_day[MAX+1];
new bool:obsluga_dala, bool:ustaw_freeday[MAX+1], bool:ustaw_duszka[MAX+1];
new AdminVoice, prowadzacy, ostatni_wiezien;
new szPoszukiwani[512], nazwa_gracza[MAX+1][64], gTeam[MAX+1];
new g_msgid[MAX+1];

new bool:user_duszek[MAX+1], bool:g_Muted[MAX+1][MAX+1];

new szInfo[257], szInfoPosz[513], dane_dnia[11], gTimeStart, id_zabawa;
new fLastPrisonerShowWish, fLastPrisonerTakeWish, fRemoveData, fDayStartPre, fDayStartPost, fJoinTeam;
new ProwadzacyMenu;

new pCvarMikro;

new Float:user_speed[MAX+1];
new user_powod_siedzenia[MAX+1];

new g_RoundTime, g_FreezeTime;

new g_Buttons[10];

new bool:jb_hud[33];
new bool:g_iAnim = false;

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	RegisterHam(Ham_Spawn, "player", "Odrodzenie", 1);
	RegisterHam(Ham_TakeDamage, "player", "TakeDamage");
	RegisterHam(Ham_TraceAttack, "player", "TraceAttack");
	RegisterHam(Ham_Killed, "player", "SmiercGraczaPost", 1);
	
	RegisterHam(Ham_Item_Deploy, "weapon_knife", "WeaponKnife", 1);
	RegisterHam(Ham_TraceAttack, "func_button", "ButtonTraceAttack");
	
	RegisterHam(Ham_Touch, "armoury_entity", "DotykBroni");
	RegisterHam(Ham_Touch, "weapon_shield", "DotykBroni");
	RegisterHam(Ham_Touch, "weaponbox", "DotykBroni");
	RegisterHam(Ham_Use, "game_player_equip", "BlokowanieUse");
	RegisterHam(Ham_Use, "player_weaponstrip", "BlokowanieUse");
	RegisterHam(Ham_Use, "func_healthcharger", "BlokowanieLeczenie");
	
	RegisterHam(Ham_Item_AddToPlayer, "weapon_knife", "OnAddToPlayerKnife", 1);
	
	register_forward(FM_EmitSound, "EmitSound");
	register_forward(FM_Voice_SetClientListening, "Voice_SetClientListening");
	
	register_event("StatusValue", "StatusShow", "be", "1=2", "2!0");
	register_event("StatusValue", "StatusHide", "be", "1=1", "2=0");
	register_event("TextMsg", "RoundRestart", "a", "2&#Game_w");
	register_event("HLTV", "PreRoundStart", "a", "1=0", "2=0");
	register_event("CurWeapon", "CurWeapon", "be", "1=1");
	
	register_logevent("RoundEnd", 2, "1=Round_End");
	register_logevent("RoundRestart", 2, "0=World triggered", "1=Game_Commencing");
	register_logevent("PostRoundStart", 2, "0=World triggered", "1=Round_Start");
	
	set_msg_block(106, BLOCK_SET); //block info player
	set_msg_block(145, BLOCK_SET); //block dhud
	set_msg_block(122, BLOCK_SET); //block clcorpse
	set_msg_block(get_user_msgid("MOTD"), BLOCK_SET);
	
	register_clcmd("radio1", "BlokujKomende");
	register_clcmd("radio2", "BlokujKomende");
	register_clcmd("radio3", "BlokujKomende");
	register_clcmd("drop", "BlockDrop");
	
	register_clcmd("weapon_piesci", "ClientCommand_SelectKnife");
	register_clcmd("weapon_palka", "ClientCommand_SelectKnife"); 
	
	register_clcmd("chooseteam", "cmdChooseTeam");
	register_clcmd("jail_cele", "MenuUstwianiaCel");
	
	register_clcmd("+adminvoice", "AdminVoiceOn");
	register_clcmd("-adminvoice", "AdminVoiceOff");
	register_clcmd("say /oddaj", "OddajProwadzenie");
	register_clcmd("say /obsluga", "ObslugaZyczen");
	register_clcmd("say /guns", "MenuBroni");
	register_clcmd("say /lr", "MenuZyczen");
	register_clcmd("say /hud", "cmd_on_off_hud");
	register_clcmd("say /zabawy", "MenuZabaw");	
	
	register_clcmd("say /mute", "MenuMutowania"); 	     
	
	register_message(77 ,"msg_TextMsg");
	register_message(96, "msg_show_menu");
	register_impulse(100, "msg_FlashLight");
	register_message(107, "msg_StatusIcon");
	register_message(114, "msg_vgui_menu");
	
	register_menucmd(register_menuid("mainmenu"), 0x223, "_menu_chooseteam");
	
	pCvarMikro = register_cvar("jail_tt_mikro", "0");
	
	g_FreezeTime = get_pcvar_num(get_cvar_pointer("mp_freezetime"));
	g_RoundTime = floatround(get_cvar_float("mp_roundtime")*60.0);
	
	SyncHudObj1 = CreateHudSyncObj();
	//SyncHudObj2 = CreateHudSyncObj();
	SyncHudObj3 = CreateHudSyncObj();
	SyncHudObj4 = CreateHudSyncObj();
	SyncHudObj5 = CreateHudSyncObj();
	
	fJoinTeam = CreateMultiForward("OnJoinTeam", ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL, FP_CELL);
	fDayStartPre = CreateMultiForward("OnDayStartPre", ET_CONTINUE, FP_CELL, FP_ARRAY, FP_ARRAY, FP_ARRAY, FP_CELL);
	fDayStartPost = CreateMultiForward("OnDayStartPost", ET_CONTINUE, FP_CELL);
	fLastPrisonerShowWish = CreateMultiForward("OnLastPrisonerShowWish", ET_CONTINUE, FP_CELL);
	fLastPrisonerTakeWish = CreateMultiForward("OnLastPrisonerTakeWish", ET_CONTINUE, FP_CELL, FP_CELL);
	fRemoveData = CreateMultiForward("OnRemoveData", ET_CONTINUE, FP_CELL);
	
	ProwadzacyMenu = menu_create(fmt("\d%s | Menu^n\r[MENU]\w Pozwol wiezniowi wybrac zyczenie:", forum), "Handel_Obsluga_Zyczen");
	menu_additem(ProwadzacyMenu, "\d×\w Tak");
	menu_additem(ProwadzacyMenu, "\d×\w Nie");
	
	WczytajCele();
	set_task(1.0, "task_server", _, _, _, "b");
	set_task(5.0, "task_cfg");
	
	log_amx("+================================+");
	log_amx("Jailbreak by Bodzio");
	log_amx("Edycja JB");
	log_amx("Pozdro bede dalej rozwijal go :P");	
	log_amx("+================================+");	
}

public task_cfg()
{
	server_cmd("exec addons/amxmodx/configs/jailbreak.cfg");
}

public client_putinserver(id)
{		
	jb_hud[id] = false;
	set_task(1.0, "cmd_hud", id + TASK_HUD, .flags = "b");
}

public CurWeapon(id)
{	
	if(!is_user_alive(id))
		return;
		
	if(!end_usun)
		set_user_maxspeed(id, user_speed[id]? user_speed[id]: 250.0);

	if(user_duszek[id])
	{
		new weapon = read_data(2);
		if(weapon != CSW_KNIFE && weapon != CSW_FLASHBANG && weapon != CSW_SMOKEGRENADE)
		{
			user_duszek[id] = false;
			set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderTransAlpha, 255);
		
			AddArray(id, WSZYSCY);
			AddArray(id, ZYWI);
		}
	}
	if(dane_dnia[7])
	{
		if(dane_dnia[7] != 3)
		{
			if(gTeam[id] != dane_dnia[7])
				return;
		}
		new weapon = read_data(2);
		if(weapon == CSW_KNIFE || weapon == CSW_HEGRENADE || weapon == CSW_FLASHBANG || weapon == CSW_SMOKEGRENADE)
			return;
	
		cs_set_user_bpammo(id, weapon, maxAmmo[weapon]);
	}
}
	
enum
{
	MIKRO = 0,
	WALKA,
	FF_TT,
	TT_GOD,
	CT_GOD,
	CT_NIE_MOZE_TT,
	TT_NIE_MOZE_CT
}

new bool:mode_gracza[7];

enum
{
	V_PALKA = 0,
	P_PALKA,
	V_PIESCI,
	P_PIESCI,
	V_REKAWICE,
	P_REKAWICE
}
new SzModels[6][128];

public plugin_precache()
{
	SzModels[V_PALKA] = "models/JailBreak_Izolatka/v_baton.mdl";
	SzModels[P_PALKA] = "models/JailBreak_Izolatka/p_palka.mdl";
	SzModels[V_PIESCI] = "models/JailBreak_Izolatka/v_hand.mdl";
	SzModels[P_PIESCI] = "models/JailBreak_Izolatka/p_piesci.mdl";
	SzModels[V_REKAWICE] = "models/JailBreak_Izolatka/v_boxing.mdl";
	SzModels[P_REKAWICE] = "models/JailBreak_Izolatka/p_boxing.mdl";
	
	precache_model(SzModels[V_PALKA]);
	precache_model(SzModels[P_PALKA]);
	precache_model(SzModels[V_PIESCI]);
	precache_model(SzModels[P_PIESCI]);
	precache_model(SzModels[V_REKAWICE]);
	precache_model(SzModels[P_REKAWICE]);	
	
	precache_model("models/player/jail_wiezien_pro/jail_wiezien_pro.mdl");
	precache_model("models/player/jail_straznik_pro/jail_straznik_pro.mdl");
	precache_model("models/player/jail_prowadzacy_pro/jail_prowadzacy_pro.mdl");	
	
	precache_sound("weapons/prawy_przycisk.wav");
	precache_sound("weapons/uderzenie_mur.wav");
	precache_sound("weapons/hit1.wav");
	precache_sound("weapons/hit2.wav");
	precache_sound("weapons/machanie.wav");
	
	precache_sound("JailBreak_Izolatka/uciekinier.wav");
	
	precache_generic("sprites/weapon_piesci.txt");  
	precache_generic("sprites/weapon_palka.txt");  
	precache_generic("sprites/640hud41.spr"); 

	engfunc(EngFunc_PrecacheModel, "models/JailBreak_Izolatka/v_round_sound.mdl");
}

/********** - Native - ************/

new Array:gZabawyName;
new Array:gZyczeniaName;
public plugin_natives()
{
	gZabawyName = ArrayCreate(32);
	gZyczeniaName = ArrayCreate(32);
	
	register_native("jail_register_game", "ZarejstrujZabawe", 1);
	register_native("jail_register_wish", "ZarejstrujZyczenie", 1);
	
	register_native("jail_get_prisoners_micro", "PobierzMikrofon", 1);
	register_native("jail_get_prisoners_fight", "PobierzWalke", 1);
	register_native("jail_get_prisoner_free", "PobierzFreeday", 1);
	register_native("jail_get_prisoner_ghost", "PobierzDuszka", 1);
	register_native("jail_get_prisoner_last", "PobierzOstatniego", 1);
	register_native("jail_get_prowadzacy", "PobierProwadzacego", 1);
	register_native("jail_get_poszukiwany", "PobierzPoszukiwany", 1);
	register_native("jail_get_user_block", "PobierzPojedynek", 1);
	register_native("jail_get_play_game_id", "PobierzIdZabawy", 1);
	register_native("jail_get_days", "PobierzDni", 1);
	
	register_native("jail_set_prisoners_micro", "UstawMikrofon", 1);
	register_native("jail_set_prisoners_fight", "UstawWalke", 1);
	register_native("jail_set_prisoner_free", "UstawFreeday", 1);
	register_native("jail_set_prisoner_ghost", "UstawDuszka", 1);
	register_native("jail_set_prowadzacy", "UstawProwadzacego", 1);
	register_native("jail_set_god_tt", "UstawTTGod", 1);
	register_native("jail_set_god_ct", "UstawCTGod", 1);
	register_native("jail_set_ct_hit_tt", "UstawCTHitTT", 1);
	register_native("jail_set_tt_hit_ct", "UstawTTHitCT", 1);
	register_native("jail_set_user_block", "UstawBlokade", 1);
	register_native("jail_set_play_game", "UstawZabawe", 1);
	register_native("jail_set_user_menuweapons", "UstawMenuWeapon", 1);
	register_native("jail_set_user_speed", "UstawPredkosc", 1);
	register_native("jail_get_user_speed", "PobierzPredkosc", 1);	
	
	register_native("jail_open_cele", "OtworzCele", 1);
	
	register_native("jail_menu_zabaw", "MenuZabaw", 1);
	register_native("PokazWiadomosc", "_jb_print_chat", 1);
}

public ZarejstrujZyczenie(nazwa_zyczenia[])
{
	param_convert(1);
	ArrayPushString(gZyczeniaName, nazwa_zyczenia);
	static ilosc; ilosc++;
	return ilosc;
}

new bool:zyczenie_wybrane;
public OnLastPrisonerShowWish(id)
{
	MenuZyczen(id);
}

public MenuZyczen(id)
{
	if(gTeam[id] != 1 || ostatni_wiezien != id || zyczenie_wybrane || !obsluga_dala)
		return PLUGIN_HANDLED;
		
	if(!ArraySize(gZyczeniaName))
	{
		jb_chat_print(id, "Nie ma zadnych zyczen na serwerze!");
		return PLUGIN_HANDLED;
	}
	
	new szZyczenia[32], szID[32], menu = menu_create(fmt("\d%s | Menu^n\r[MENU]\w Wybierz Zyczenie:", forum), "Handel_Zyczenie");	
	for(new i=0; i<ArraySize(gZyczeniaName); i++)
	{
		ArrayGetString(gZyczeniaName, i, szZyczenia, 31);
		num_to_str(i+1, szID, 31);
		menu_additem(menu, szZyczenia, szID);
	}	
	
	menu_setprop(menu, MPROP_BACKNAME, "\d×\w Wroc");
	menu_setprop(menu, MPROP_NEXTNAME, "\d×\w Dalej");
	menu_setprop(menu, MPROP_EXITNAME, "\d×\w Wyjdz");
	menu_display(id, menu);
	return PLUGIN_HANDLED;
}

public Handel_Zyczenie(id, menu, item)
{
	if(item == MENU_EXIT || !is_user_alive(id) || ostatni_wiezien != id)
		return;
	
	new acces, szZyczenie[32], szID[32];
	menu_item_getinfo(menu, item, acces, szID, 31, szZyczenie, 31, acces);
	
	new iRet;
	ExecuteForward(fLastPrisonerTakeWish, iRet, id, str_to_num(szID))
	if(iRet == -1)
	{
		menu_display(id, menu);
		jb_chat_print(id, "Nie mozesz wybrac tego zyczenia!");
		return;
	}
	
	jb_chat_print(0, "%s ^x01wybral^x03 %s", nazwa_gracza[id], szZyczenie);
	zyczenie_wybrane = true;
}

public cmd_on_off_hud(id) {
	jb_hud[id] = !jb_hud[id]
	jb_chat_print(id, "Hud zostal:^3 %s", jb_hud[id] ? "Wylaczony" : "Wlaczony");
}	
////////////////////

public ZarejstrujZabawe(nazwa_zabawy[])
{
	param_convert(1);
	ArrayPushString(gZabawyName, nazwa_zabawy);
	
	static ilosc = 8; ilosc++;
	return ilosc;
}

new bool:zabawa_wybrana;
public MenuZabaw(id)
{
	if(gTeam[id] != 2 || prowadzacy != id || !(get_user_flags(id) & FLAGA_OPA))
		return PLUGIN_CONTINUE;
	
	if(!ArraySize(gZabawyName))
	{
		jb_chat_print(id, "Nie ma zadnych zabaw na serwerze!");
		return PLUGIN_CONTINUE;
	}
	
	if(zabawa_wybrana)
	{
		jb_chat_print(id, "Juz wybrales dzisiaj zabawe");
		return PLUGIN_CONTINUE;
	}
	
	new szZabawa[32], szID[32], menu = menu_create(fmt("\d%s | Menu^n\r[MENU]\w Menu Zabaw:", forum), "Handel_Menu_Zabaw");
	for(new i=0; i<ArraySize(gZabawyName); i++)
	{
		ArrayGetString(gZabawyName, i, szZabawa, 31);
		num_to_str(i+9, szID, 31);
		menu_additem(menu, szZabawa, szID);
	}
	
	menu_setprop(menu, MPROP_BACKNAME, "\d×\w Wroc");
	menu_setprop(menu, MPROP_NEXTNAME, "\d×\w Dalej");
	menu_setprop(menu, MPROP_EXITNAME, "\d×\w Wyjdz");
	menu_display(id, menu);
	return PLUGIN_HANDLED;
}

public Handel_Menu_Zabaw(id, menu, item)
{
	if(item == MENU_EXIT || zabawa_wybrana || prowadzacy != id)
		return;

	new acces, szZabawa[32], szID[32];
	menu_item_getinfo(menu, item, acces, szID, 31, szZabawa, 31, acces);
	jb_chat_print(id, "%s%s", UstawZabawe(str_to_num(szID), false)? "wlaczyles ": "juz jest za pozno, aby wlaczyc ", szZabawa);
	
	zabawa_wybrana = true;
}

public UstawPredkosc(id, Float:speed)
{
	user_speed[id] = speed;
	if(end_usun)
	{
		new data[1];
		data[0] = id;
		set_task(g_FreezeTime-(get_systime()-gTimeStart)+0.1, "taskUstawPredkosc", ID_SPEED_FZ, data, 1);
	}
	else
		set_user_maxspeed(id, speed);
}

public Float:PobierzPredkosc(id) {
	return user_speed[id];
}

public taskUstawPredkosc(data[1])
{
	set_user_maxspeed(data[0], user_speed[data[0]]);
}

public PobierzIdZabawy()
{
	return id_zabawa;
}

public bool:PobierzPojedynek(id)
{
	return pojedynek[id];
}

public bool:PobierzPoszukiwany(id)
{
	return (contain(szPoszukiwani, nazwa_gracza[id]) != -1)? true: false;
}

public bool:PobierzMikrofon()
{
	return bool:mode_gracza[MIKRO];
}

public bool:PobierzWalke()
{
	return bool:mode_gracza[WALKA];
}

public bool:PobierzFreeday(id)
{
	return free_day[id];
}

public bool:PobierzDuszka(id)
{
	return user_duszek[id];
}

public PobierzOstatniego()
{
	return ostatni_wiezien;
}

public PobierProwadzacego()
{
	return prowadzacy;
}

public PobierzDni()
{
	return jail_day%7;
}

public UstawMikrofon(bool:wartosc, bool:info)
{
	if(ostatni_wiezien || dane_dnia[1])
		return;
	
	mode_gracza[MIKRO] = wartosc;
	
	if(info)
		jb_chat_print(0, "Status mikro dla wiezniow:^3 %s!", mode_gracza[MIKRO]? "wlaczone": "wylaczone");
}

public UstawWalke(bool:wartosc, bool:modele, bool:info)
{
	if(ostatni_wiezien || (dane_dnia[1] && modele))
		return;
	
	mode_gracza[WALKA] = modele;
	mode_gracza[FF_TT] = wartosc;
	
	for(new i=1; i<=MAX; i++)
	{
		if(!is_user_alive(i) || !is_user_connected(i) || gTeam[i] != 1 || get_user_weapon(i) != CSW_KNIFE || free_day[i] || user_duszek[i])
			continue;
	
		set_user_health(i, 100);
		set_pev(i, pev_viewmodel2, modele? SzModels[V_REKAWICE]: SzModels[V_PIESCI]);
		set_pev(i, pev_weaponmodel2, modele? SzModels[P_REKAWICE]: SzModels[P_PIESCI]);
	}
	if(info)
		jb_chat_print(0, "Walka dla wiezniow:^3 %s!", mode_gracza[WALKA]? "wlaczona": "wylaczona");
}

public UstawFreeday(id, bool:wartosc, bool:nextround)
{
	if(!id || (dane_dnia[1] && !nextround))
		return 0;
	
	if(!nextround && wartosc)
	{
		new podlicz = 0;
		for(new i=1; i<=MAX; i++)
		{
			if(is_user_alive(i) && is_user_connected(i) && gTeam[i] == 1 && !free_day[i] && !user_duszek[i])
				podlicz++;
		}
		if(podlicz == 1)
			return 0;
	}
	
	if(wartosc)
	{
		DelArray(id, WSZYSCY);
		DelArray(id, ZYWI);
	}
	
	free_day[id] = wartosc;
	ustaw_freeday[id] = nextround;
	
	if(!wartosc)
	{
		AddArray(id, WSZYSCY);
		AddArray(id, ZYWI);
	}
	cs_set_player_model(id,"jail_wiezien_pro");
	set_pev(id, pev_skin, wartosc? 9: random(8));
	set_user_rendering(id, kRenderFxGlowShell, 0, wartosc? 255:0, 0, kRenderNormal, 15);	
	return 1;
}

public UstawDuszka(id, bool:wartosc, bool:nextround)
{
	if(!id || (dane_dnia[1] && !nextround))
		return 0;
	
	new bool:ma=user_duszek[id]
	
	if(!nextround && wartosc)
	{
		new podlicz = 0;
		for(new i=1; i<=MAX; i++)
		{
			if(is_user_alive(i) && is_user_connected(i) && gTeam[i] == 1 && !free_day[i] && !user_duszek[i])
				podlicz++;
		}
		if(podlicz == 1)
			return 0;
	}
	
	if(wartosc)
	{
		DelArray(id, WSZYSCY);
		DelArray(id, ZYWI);
	}
	
	user_duszek[id] = wartosc;
	ustaw_duszka[id] = nextround;
	
	if(!wartosc)
	{
		AddArray(id, WSZYSCY);
		AddArray(id, ZYWI);
	}
	
	if(ma || wartosc)
		set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderTransAlpha, wartosc? 0: 255);
	return 1;
}

public UstawTTGod(bool:wartosc)
{
	mode_gracza[TT_GOD] = wartosc;
}

public UstawCTGod(bool:wartosc)
{
	mode_gracza[CT_GOD] = wartosc;
}

public UstawCTHitTT(bool:wartosc)
{
	mode_gracza[CT_NIE_MOZE_TT] = wartosc;
}

public UstawTTHitCT(bool:wartosc)
{
	mode_gracza[TT_NIE_MOZE_CT] = wartosc;
}

public UstawBlokade(id, bool:wartosc)
{
	pojedynek[id] = wartosc;
}

public UstawProwadzacego(id)
{
	if(!dane_dnia[1])
	{
		if(prowadzacy != id && prowadzacy)
			set_pev(prowadzacy, pev_body, 0);
			
		prowadzacy = id;
		if(id)
		{
			if(task_exists(ID_LOS_PROWADZACY))
				remove_task(ID_LOS_PROWADZACY);
				
			cs_set_player_model(id, "jail_prowadzacy_pro");
			set_user_rendering(prowadzacy, kRenderFxGlowShell, 0, 0, 255, kRenderNormal, 15);
		}
	}
}

public UstawZabawe(zabawa, bool:fast)
{
	if(!fast)
	{
		if(czas_bronie || ilosc_graczy[WSZYSCY] != ilosc_graczy[ZYWI])
			return 0;
		
		if(mode_gracza[WALKA] || mode_gracza[FF_TT])
			UstawWalke(false, false, false);
	}
	ForwardDayStartPre(zabawa);
	return 1;
}

public MenuBroni(id)
{
	if(!is_user_alive(id) || gTeam[id] != 2 || czas_bronie)
		return PLUGIN_HANDLED;
		
	UstawMenuWeapon(id, true, true, 0, 0);
	return PLUGIN_HANDLED;
}

new bool:bronie_menu[MAX+1][2];
new bronie_bitsum[MAX+1][2];
new bronie_gracza[MAX+1][2];
public UstawMenuWeapon(id, bool:bronie, bool:pistolety, bitsum_bronie, bitsum_pistolety)
{
	if(!bronie && !pistolety)
		return;
	
	bronie_menu[id][0] = bronie;
	bronie_menu[id][1] = pistolety;
	
	bronie_bitsum[id][0] = bitsum_bronie;
	bronie_bitsum[id][1] = bitsum_pistolety;
	
	MenuBronie(id);
}

public MenuBronie(id)
{
	if(!bronie_menu[id][0] && bronie_menu[id][1])
	{
		MenuPistolety(id);
		return;
	}
	if(!bronie_menu[id][0])
		return;

	new menu = menu_create(fmt("\d%s | Menu^n\r[MENU]\w Wybierz Bronie:", forum), "Handel_Bronie");	
	if(!(bronie_bitsum[id][0] & (1<<CSW_M4A1)))
		menu_additem(menu, "M4A1", "22");
	if(!(bronie_bitsum[id][0] & (1<<CSW_AK47)))
		menu_additem(menu, "AK47", "28");
	if(!(bronie_bitsum[id][0] & (1<<CSW_AWP)))
		menu_additem(menu, "AWP", "18");
	if(!(bronie_bitsum[id][0] & (1<<CSW_SCOUT)))
		menu_additem(menu, "Scout", "3");
	if(!(bronie_bitsum[id][0] & (1<<CSW_AUG)))
		menu_additem(menu, "AUG", "8");
	if(!(bronie_bitsum[id][0] & (1<<CSW_SG550)))
		menu_additem(menu, "Krieg 550", "13");
	if(!(bronie_bitsum[id][0] & (1<<CSW_M249)))
		menu_additem(menu, "M249", "20");
	if(!(bronie_bitsum[id][0] & (1<<CSW_MP5NAVY)))
		menu_additem(menu, "MP5", "19");
	if(!(bronie_bitsum[id][0] & (1<<CSW_UMP45)))
		menu_additem(menu, "UMP45", "12");
	if(!(bronie_bitsum[id][0] & (1<<CSW_FAMAS)))
		menu_additem(menu, "Famas", "15");
	if(!(bronie_bitsum[id][0] & (1<<CSW_GALIL)))
		menu_additem(menu, "Galil", "14");
	if(!(bronie_bitsum[id][0] & (1<<CSW_M3)))
		menu_additem(menu, "M3", "21");
	if(!(bronie_bitsum[id][0] & (1<<CSW_XM1014)))
		menu_additem(menu, "XM1014", "5");
	if(!(bronie_bitsum[id][0] & (1<<CSW_MAC10)))
		menu_additem(menu, "Mac10", "7");
	if(!(bronie_bitsum[id][0] & (1<<CSW_TMP)))
		menu_additem(menu, "TMP", "23");
	if(!(bronie_bitsum[id][0] & (1<<CSW_P90)))
		menu_additem(menu, "P90", "30");
	if(!(bronie_bitsum[id][0] & (1<<CSW_G3SG1)))
		menu_additem(menu, "G3SG1 (autokampa)", "24");
	if(!(bronie_bitsum[id][0] & (1<<CSW_SG552)))
		menu_additem(menu, "Krieg 552 (autokampa)", "27");
		
	menu_setprop(menu, MPROP_BACKNAME, "\d×\w Wroc");
	menu_setprop(menu, MPROP_NEXTNAME, "\d×\w Dalej");
	menu_setprop(menu, MPROP_EXITNAME, "\d×\w Wyjdz");
	menu_display(id, menu);
}

public Handel_Bronie(id, menu, item)
{
	if(item == MENU_EXIT || !is_user_alive(id) || !bronie_menu[id][0])
		return;

	new weaponname[24], data[3], weapon, callback;
	menu_item_getinfo(menu, item, weapon, data, 2, _, _, callback);
	
	if((callback = Jaki_Pistolet(id)) > 0)
		ham_strip_weapon(id, callback);
	
	weapon = str_to_num(data);
	get_weaponname(weapon, weaponname, 23);
	
	give_item(id, weaponname);
	cs_set_user_bpammo(id, weapon, maxAmmo[weapon]);
	bronie_gracza[id][0] = weapon;
	
	if(bronie_menu[id][1])
		MenuPistolety(id);
}

public MenuPistolety(id)
{
	if(!bronie_menu[id][1])
		return;

	new menu = menu_create(fmt("\d%s | Menu^n\r[MENU]\w Wybierz Pistolet:", forum), "Handel_Pistolety");	
	if(!(bronie_bitsum[id][1] & (1<<CSW_USP)))
		menu_additem(menu, "USP",	"16");
	if(!(bronie_bitsum[id][1] & (1<<CSW_GLOCK18)))
		menu_additem(menu, "Glock", 	"17");
	if(!(bronie_bitsum[id][1] & (1<<CSW_DEAGLE)))
		menu_additem(menu, "Deagle", 	"26");
	if(!(bronie_bitsum[id][1] & (1<<CSW_P228)))
		menu_additem(menu, "P228",	"1");
	if(!(bronie_bitsum[id][1] & (1<<CSW_FIVESEVEN)))
		menu_additem(menu, "FiveSeven", "11");
	if(!(bronie_bitsum[id][1] & (1<<CSW_ELITE)))
		menu_additem(menu, "Dual", 	"10");
	
	menu_setprop(menu, MPROP_BACKNAME, "\d×\w Wroc");
	menu_setprop(menu, MPROP_NEXTNAME, "\d×\w Dalej");
	menu_setprop(menu, MPROP_EXITNAME, "\d×\w Wyjdz");
	menu_display(id, menu);
}

public Handel_Pistolety(id, menu, item)
{
	if(item == MENU_EXIT || !is_user_alive(id) || !bronie_menu[id][1])
		return;

	new weaponname[24], data[3], weapon, callback;
	menu_item_getinfo(menu, item, weapon, data, 2, _, _, callback);
	
	weapon = str_to_num(data);
	get_weaponname(weapon, weaponname, 23);
	give_item(id, weaponname);
	cs_set_user_bpammo(id, weapon, maxAmmo[weapon]);
		
	bronie_gracza[id][1] = weapon;
}

/********** - Koniec Native - ************/

public ButtonTraceAttack(ent, id, Float:damage, Float:direction[3], tracehandle, damagebits)
{
	if(pev_valid(ent) && prowadzacy == id)
	{
		ExecuteHam(Ham_Use, ent, id, 0, 2, 1.0);
		set_pev(ent, pev_frame, 0.0);
	}
	return HAM_IGNORED;
}

public TakeDamage(id, ent, attacker, Float:damage, damagebits)
	return vAttackDamagePlayer(id, attacker, damage, damagebits, true);

public TraceAttack(id, attacker, Float:damage, Float:direction[3], tracehandle, damagebits)
	return vAttackDamagePlayer(id, attacker);

vAttackDamagePlayer(id, attacker, Float:damage=0.0, damagebits=0, bool:dmg=false)
{
	if(!is_user_connected(id))
		return HAM_IGNORED;
	
	if(gTeam[id] == 1 && mode_gracza[TT_GOD])
		return HAM_SUPERCEDE;
	
	if(gTeam[id] == 2 && mode_gracza[CT_GOD])
		return HAM_SUPERCEDE;
	
	if(is_user_connected(attacker))
	{
		if(gTeam[id] == 1 && gTeam[attacker] == 1 && !mode_gracza[FF_TT])
			return HAM_SUPERCEDE;
		
		if(gTeam[id] == 2 && gTeam[attacker] == 2)
			return HAM_SUPERCEDE;
			
		if(gTeam[id] == 1 && gTeam[attacker] == 2 && mode_gracza[CT_NIE_MOZE_TT])
			return HAM_SUPERCEDE;
	
		if(gTeam[id] == 2 && gTeam[attacker] == 1 && mode_gracza[TT_NIE_MOZE_CT])
			return HAM_SUPERCEDE;
		
		if(free_day[attacker] || gTeam[attacker] == 1 && free_day[id])
			return HAM_SUPERCEDE;
			
		if(user_duszek[id] && gTeam[attacker] == 1)
			return HAM_SUPERCEDE;

		if(user_duszek[attacker] && gTeam[id] == 2)
		{
			user_duszek[attacker] = false;
			set_user_rendering(attacker, kRenderFxNone, 0, 0, 0, kRenderTransAlpha, 255);
			
			AddArray(attacker, WSZYSCY);
			AddArray(attacker, ZYWI);
			return HAM_IGNORED;
		}

		if(dmg)
		{
			if(get_user_weapon(attacker) == CSW_KNIFE && damagebits & DMG_BULLET)
				SetHamParamFloat(4, damage*0.4);
		}
	}
	return HAM_IGNORED;
}

public Odrodzenie(id)
{
	if(!is_user_alive(id) || !is_user_connected(id))
		return;
	
	set_user_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderNormal, 0);
	strip_user_weapons2(id);
	
	switch(cs_get_user_team(id))
	{
		case CS_TEAM_T:
		{
			gTeam[id] = 1;
			
			cs_set_player_model(id, "jail_wiezien_pro");
			set_pev(id, pev_skin, random_num(0,7))
			
			AddArray(id, WSZYSCY);
			AddArray(id, ZYWI);
		}
		case CS_TEAM_CT:
		{
			gTeam[id] = 2;
			
			cs_set_player_model(id, "jail_straznik_pro");
				
			if(dane_dnia[4] < 2)
			{
				if(bronie_gracza[id][0] && bronie_gracza[id][1])
				{
					for(new i=0; i<2; i++)
					{
						new weaponname[24];
						get_weaponname(bronie_gracza[id][i], weaponname, 23);
						give_item(id, weaponname);
						cs_set_user_bpammo(id, bronie_gracza[id][i], maxAmmo[bronie_gracza[id][i]]);
					}
				}
				else if(!czas_bronie) {
					UstawMenuWeapon(id, true, true, 0, 0);
				}
			}
		}
	}
	give_item(id, "weapon_knife");
	
	if(free_day[id]) {
		cs_set_player_model(id, "jail_wiezien_pro");
		set_pev(id, pev_skin, 8);
		set_user_rendering(id, kRenderFxGlowShell, 0, 255, 0, kRenderNormal, 15);
	}		
	
	if(user_duszek[id])
		set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderTransAlpha, 0);
}

public OddajProwadzenie(id)
{
	if(prowadzacy != id)
		return PLUGIN_HANDLED;
	
	new menu = menu_create(fmt("\d%s | Menu^n\r[MENU]\w Oddaj Prowadzenie:", forum), "Handel_Oddaj"), szId[4];	
	
	for(new i = 1; i <= MAX; i++) {
		if(!is_user_connected(i) || !is_user_alive(i) || gTeam[i] != 2 || prowadzacy == i) {
			continue;
		}
		
		num_to_str(i, szId, 3);
		menu_additem(menu, fmt("%s", nazwa_gracza[i]), szId);
	}	
	
	menu_setprop(menu, MPROP_BACKNAME, "\d×\w Wroc");
	menu_setprop(menu, MPROP_NEXTNAME, "\d×\w Dalej");
	menu_setprop(menu, MPROP_EXITNAME, "\d×\w Wyjdz");
	menu_display(id, menu);	
	return PLUGIN_HANDLED;
}

public Handel_Oddaj(id, menu, item)
{	
	if(item < 0) {
		if(item == MENU_EXIT || !is_user_alive(id) || prowadzacy != id) {
			menu_destroy(menu);
		}
		return PLUGIN_CONTINUE;
	}		

	new iAccess, szId[4], callback;
	menu_item_getinfo(menu, item, iAccess, szId, 3, _, _, callback);
	prowadzacy = str_to_num(szId);
	
	jb_chat_print(0, "^4 UWAGA!!^1 Zmienil sie^3 Prowadzacy");

	set_user_rendering(prowadzacy, kRenderFxGlowShell, 0, 0, 255, kRenderNormal, 15);
	set_user_rendering(id)
	
	cs_set_player_model(id, "jail_straznik_pro");
	cs_set_player_model(prowadzacy, "jail_prowadzacy_pro");	
	return PLUGIN_HANDLED;	
}

public WeaponKnife(ent)
{
	new id = get_pdata_cbase(ent, 41, 4);
	
	if(!is_user_alive(id))
		return;
	
	if(cs_get_user_shield(id))
		return;
	
	if(gTeam[id] == 1 && !mode_gracza[WALKA])
	{
		set_pev(id, pev_viewmodel2, SzModels[V_PIESCI]);
		set_pev(id, pev_weaponmodel2, SzModels[P_PIESCI]);
	}
	else if(gTeam[id] == 1 && mode_gracza[WALKA])
	{
		set_pev(id, pev_viewmodel2, SzModels[V_REKAWICE]);
		set_pev(id, pev_weaponmodel2, SzModels[P_REKAWICE]);
	}
	else if(gTeam[id] == 2)
	{
		set_pev(id, pev_viewmodel2, SzModels[V_PALKA]);
		set_pev(id, pev_weaponmodel2, SzModels[P_PALKA]);
	}
}

public EmitSound(id, channel, sample[])
{	
	if(!is_user_alive(id) || !is_user_connected(id)) 
		return FMRES_IGNORED;

	if(equal(sample, "weapons/knife_", 14))
	{
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
	if(equal(sample, "common/wpn_denyselect.wav"))
		return FMRES_SUPERCEDE;
	return FMRES_IGNORED;
}

public AdminVoiceOn(id)
{
	if(!(get_user_flags(id) & ADMIN_BAN))
		return PLUGIN_HANDLED;

	if(AdminVoice)
		return PLUGIN_HANDLED;

	AdminVoice = id;

	jb_chat_print(0, "Cisza! ^3%s ^1przemawia.", nazwa_gracza[id]);
	client_cmd(id, "+voicerecord");
	return PLUGIN_HANDLED;
}

public AdminVoiceOff(id)
{
	if(!(get_user_flags(id) & ADMIN_BAN))
		return PLUGIN_HANDLED;

	if(AdminVoice != id)
	{
		client_cmd(id, "-voicerecord");
		return PLUGIN_HANDLED;
	}
	client_cmd(id, "-voicerecord");
	AdminVoice = 0;
	return PLUGIN_HANDLED;
}

public MenuMutowania(id)
{
	new menu = menu_create(fmt("\d%s | Menu^n\r[MENU]\w Menu mutowania:", forum), "Handel_Mute"), szId[4];
	
	for(new i = 1; i <= MAX; i++) {
		if(!is_user_connected(i) || is_user_hltv(i) || get_user_flags(i) & ADMIN_KICK) {
			continue;
		}
		
		num_to_str(i, szId, 3);
		menu_additem(menu, fmt("%s %s", nazwa_gracza[i], g_Muted[id][i] ? "\w[\rOdmutuj\w]" : ""), szId);
	}
	
	menu_setprop(menu, MPROP_BACKNAME, "\d×\w Wroc");
	menu_setprop(menu, MPROP_NEXTNAME, "\d×\w Dalej");
	menu_setprop(menu, MPROP_EXITNAME, "\d×\w Wyjdz");
	menu_display(id, menu);	
}

public Handel_Mute(id, menu, item)
{
	if(item < 0) {
		if(item == MENU_EXIT) {
			menu_destroy(menu);
		}
		return PLUGIN_CONTINUE;
	}
	
	new iAccess, id2, szId[4];
	menu_item_getinfo(menu, item, iAccess, szId, 3, _, _, id2);
	id2 = str_to_num(szId);
	
	if(!is_user_connected(id2)) {
		jb_chat_print(id, "Gracz wyszedl z^4 serwera!");
	} else {
		g_Muted[id][id2] = !g_Muted[id][id2];
		jb_chat_print(id, "%s gracza^4 %s", g_Muted[id][id2] ? "Zmutowales" : "Odmutowales", nazwa_gracza[id2]);
	}
	menu_destroy(menu);
	MenuMutowania(id);
	return PLUGIN_HANDLED;	
}

public Voice_SetClientListening(odbiorca, nadawca, listen) 
{
	if(odbiorca == nadawca)
		return FMRES_IGNORED;
	
	if(g_Muted[odbiorca][nadawca])
	{
		engfunc(EngFunc_SetClientListening, odbiorca, nadawca, false);
		return FMRES_SUPERCEDE;
	}
	if(AdminVoice)
	{
		if(AdminVoice == nadawca)
		{
			engfunc(EngFunc_SetClientListening, odbiorca, nadawca, true);
			return FMRES_SUPERCEDE;
		}
		else if(gTeam[nadawca] == 1)
		{
			engfunc(EngFunc_SetClientListening, odbiorca, nadawca, false);
			return FMRES_SUPERCEDE;
		}
	}
	
	if(gTeam[nadawca] == 1 && !mode_gracza[MIKRO])
	{
		engfunc(EngFunc_SetClientListening, odbiorca, nadawca, false);
		return FMRES_SUPERCEDE;
	}
	
	if(is_user_alive(odbiorca))
	{
		if(is_user_alive(nadawca))
		{
			engfunc(EngFunc_SetClientListening, odbiorca, nadawca, true);
			return FMRES_SUPERCEDE;
		}
		engfunc(EngFunc_SetClientListening, odbiorca, nadawca, false);
		return FMRES_SUPERCEDE;
	}
	return FMRES_IGNORED;
}

public BlokowanieUse(ent, id, activator, iType, Float:fValue)
{
	if(!is_user_connected(id) || id == activator)
		return HAM_IGNORED;

	if(dane_dnia[4] == 3 || dane_dnia[4] == gTeam[id] || pojedynek[id] || free_day[id])
		return HAM_SUPERCEDE;
		
	return HAM_IGNORED;
}

public BlokowanieLeczenie(ent, id, activator, iType, Float:fValue)
{
	if(!is_user_connected(id))
		return HAM_IGNORED;
		
	if(dane_dnia[4] == 3 || dane_dnia[4] == gTeam[id] || pojedynek[id])
		return HAM_SUPERCEDE;
		
	return HAM_IGNORED;
}

public DotykBroni(weapon, id)
{
	if(!is_user_connected(id))
		return HAM_IGNORED;
		
	if(free_day[id] || dane_dnia[4] == 3 || dane_dnia[4] == gTeam[id] || pojedynek[id])
		return HAM_SUPERCEDE;

	return HAM_IGNORED;
}

public BlockDrop(id)
{
	if(dane_dnia[4] == 3 || dane_dnia[4] == gTeam[id] || pojedynek[id])
		return PLUGIN_HANDLED;
	return PLUGIN_CONTINUE;
}

public SmiercGraczaPost(id, attacker, shouldgib)
{	
	if(!is_user_connected(id))
		return HAM_IGNORED;
		
	if(gTeam[id] == 1)
	{
		if(is_user_connected(attacker) && gTeam[attacker] == 1)
			set_user_frags(attacker, get_user_frags(attacker)+2);

		if(ostatni_wiezien == id)
		{
			for(new i=1; i<=MAX; i++)
			{
				if(is_user_alive(i) && is_user_connected(i) && (free_day[i] || user_duszek[i]))
				{	
					user_kill(i);
					free_day[i] = false;
					user_duszek[i] = false;
				}
			}
		}
		DelPoszukiwany(id);
		DelArray(id, ZYWI);
	}
	else if(gTeam[id] == 2)
	{	
		if(is_user_connected(attacker) && gTeam[attacker] == 1 && !obsluga_dala && !dane_dnia[2])
		{
			AddPoszukiwany(attacker);
		}
		if(prowadzacy == id)
		{
			prowadzacy = 0;
			if(!obsluga_dala && !dane_dnia[2])
				set_task(1.0, "LosujProwadzacego", ID_LOS_PROWADZACY);
		}
	}
	return HAM_IGNORED;
}

public StatusShow(id)
{
	new pid = read_data(2), team = gTeam[pid]; 
	set_hudmessage(team == 1 ? 255 : 0, 50, team == 1 ? 0 : 255, -1.0, 0.9, 0, 0.01, 6.0);
	ShowSyncHudMsg(id, SyncHudObj1, "%s: %s [%i]", team == 1? "Wiezien": "Straznik", nazwa_gracza[pid], get_user_health(pid));
}

public StatusHide(id)
	ClearSyncHud(id, SyncHudObj1);
	
public msg_FlashLight(id)
{
	if(gTeam[id] == 1)
		return PLUGIN_HANDLED;	
	return PLUGIN_CONTINUE;
}

public msg_TextMsg()
{	
	new message[32];
	get_msg_arg_string(2, message, 31);
	
	if(equal(message, "#Game_teammate_attack") || equal(message, "#Killed_Teammate"))
		return PLUGIN_HANDLED;

	if(equal(message, "#Terrorists_Win"))
	{
		set_msg_arg_string(2, "Wiezniowie wygrali!");
		return PLUGIN_CONTINUE;
	}
	else if(equal(message, "#CTs_Win"))
	{
		set_msg_arg_string(2, "Klawisze wygrali!");
		return PLUGIN_CONTINUE;
	}
	else if(equal(message, "#Round_Draw"))
	{
		set_msg_arg_string(2, "Runda remisowa!")
		return PLUGIN_CONTINUE;
	}
	else if(equal(message, "#Only_1_Team_Change"))
	{
		set_msg_arg_string(2, "Dozwolona tylko 1 zmiana druzyny!")
		return PLUGIN_CONTINUE;
	}
	else if(equal(message, "#Switch_To_SemiAuto"))
	{
		set_msg_arg_string(2, "Zmieniono na tryb pol-automatyczny")
		return PLUGIN_CONTINUE;
	}
	else if(equal(message, "#Switch_To_BurstFire"))
	{
		set_msg_arg_string(2, "Zmieniono na tryb serii")
		return PLUGIN_CONTINUE;
	}
	else if(equal(message, "#Switch_To_FullAuto"))
	{
		set_msg_arg_string(2, "Zmieniono na tryb automatyczny")
		return PLUGIN_CONTINUE;
	}
	else if(equal(message, "#Game_Commencing"))
	{
		set_msg_arg_string(2, "Rozpoczecie Gry!");
		return PLUGIN_CONTINUE;
	}
	else if(equal(message, "#Cannot_Be_Spectator"))
	{
		set_msg_arg_string(2, "Nie mozesz byc obserwatorem");
		return PLUGIN_CONTINUE;
	}
	return PLUGIN_HANDLED;
}	

public msg_StatusIcon(msgid, dest, id)
{
	new szIcon[8];
	get_msg_arg_string(2, szIcon, 7);
	 
	if(equal(szIcon, "buyzone") && get_msg_arg_int(1))
	{
		set_pdata_int(id, 235, get_pdata_int(id, 235) & ~(1<<0));
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}

public client_authorized(id)
{
	set_user_info(id, "_vgui_menus", "0");
	get_user_name(id, nazwa_gracza[id], 63);
}

public client_disconnected(id)
{
	if(AdminVoice == id)
		AdminVoice = 0;
		
	if(prowadzacy == id)
	{
		prowadzacy = 0;
		set_task(1.0, "LosujProwadzacego", ID_LOS_PROWADZACY);
	}
	
	if(ostatni_wiezien == id)
		ostatni_wiezien = 0;
		
	user_speed[id] = 0.0;
	bronie_gracza[id][0] = 0;
	bronie_gracza[id][1] = 0;
	pojedynek[id] = false;
	free_day[id] = false;
	user_duszek[id] = false;
	ustaw_freeday[id] = false;
	ustaw_duszka[id] = false;
	
	for(new i=1; i<=MAX; i++)
		g_Muted[i][id] = false;
	
	DelPoszukiwany(id);
	if(gTeam[id] == 1)
	{
		DelArray(id, WSZYSCY);
		DelArray(id, ZYWI);
	}
	gTeam[id] = 0;
}

public client_infochanged(id) 
{
	get_user_info(id, "name", nazwa_gracza[id], 63);
}

public RoundRestart()
{
	usuwanie_ustawien = true;
}

public RoundEnd()
{
	end_usun = true;
	czas_bronie = false;
	if(!task_exists(1)) set_task(0.1, "LogEvent_RoundEndTask", 1);
}

public PreRoundStart()
{	
	UsuwanieWydarzen();
	if(usuwanie_ustawien)
	{
		jail_day = 0;
		usuwanie_ustawien = false;
	}
	else
		jail_day++;

	
	if(jail_day)
	{
		gTimeStart = get_systime();
		ForwardDayStartPre(jail_day%7);
	}
}

UsuwanieWydarzen()
{
	//end_usun = true;
	szInfo = "";
	szInfoPosz = "";
	szPoszukiwani = "";
	ostatni_wiezien = 0;
	prowadzacy = 0;
	
	obsluga_dala = false;
	pokaz_raz = false;
	czas_bronie = false;
	zabawa_wybrana = false;
	zyczenie_wybrane = false
		
	mode_gracza[WALKA] = false;

	mode_gracza[MIKRO] = (get_pcvar_num(pCvarMikro) == 1? true: false);
	
	mode_gracza[FF_TT] = false;
	mode_gracza[TT_GOD] = false;
	mode_gracza[CT_GOD] = false;
	mode_gracza[CT_NIE_MOZE_TT] = false;
	mode_gracza[TT_NIE_MOZE_CT] = false
	
	if(task_exists(ID_DZWIEK_POSZ))
		remove_task(ID_DZWIEK_POSZ);
	
	if(task_exists(ID_LOS_PROWADZACY))
		remove_task(ID_LOS_PROWADZACY);
		
	if(task_exists(ID_CZAS))
		remove_task(ID_CZAS);
	
	if(task_exists(ID_FREZZ))
		remove_task(ID_FREZZ);
	
	if(task_exists(ID_SPEED_FZ))
		remove_task(ID_SPEED_FZ);
	
	for(new i=0; i<sizeof dane_dnia; i++)
		dane_dnia[i] = 0;
	
	for(new i=1; i<=MAX; i++)
	{
		user_powod_siedzenia[i] = random(sizeof powody_siedzenia);
		array_graczy[WSZYSCY][i] = 0;
		array_graczy[ZYWI][i] = 0;
		
		user_speed[i] = 0.0;
		pojedynek[i] = false;
		
		bronie_menu[i][0] = false;
		bronie_menu[i][1] = false;
		
		if(ustaw_freeday[i])
		{
			ustaw_freeday[i] = false;
			free_day[i] = true;
		}
		else
			free_day[i] = false;
			
		if(ustaw_duszka[i])
		{
			ustaw_duszka[i] = false;
			user_duszek[i] = true;
		}
		else
			user_duszek[i] = false;
	}
	
	ilosc_graczy[WSZYSCY] = 0;
	ilosc_graczy[ZYWI] = 0;
	
	new iRet;
	ExecuteForward(fRemoveData, iRet, id_zabawa);
}

public PostRoundStart()
{
	end_usun = false;
	set_task(60.0, "koniec_czasu", ID_CZAS);
	
	if(!jail_day)
	{
		gTimeStart = get_systime()-g_FreezeTime;
		ForwardDayStartPre(jail_day%7);
	}
	if(!prowadzacy && !dane_dnia[1])
		set_task(15.0, "LosujProwadzacego", ID_LOS_PROWADZACY);
}

ForwardDayStartPre(zabawa)
{
	new iRet, is_frezz = g_FreezeTime-(get_systime()-gTimeStart);
	ExecuteForward(fDayStartPre, iRet, zabawa, PrepareArray(szInfo, 256, 1), PrepareArray(szInfoPosz, 512, 1), PrepareArray(dane_dnia, 10, 1), g_RoundTime+min(is_frezz, 0));
	id_zabawa = zabawa;
	
	new dane[1]
	dane[0] = zabawa;
	if(is_frezz)
		set_task(is_frezz+0.1, "ForwardDayStartPost", ID_FREZZ, dane, 1);
	else
		ForwardDayStartPost(dane);	
}

public ForwardDayStartPost(zabawa[1])
{
	new iRet;
	ExecuteForward(fDayStartPost, iRet, zabawa[0]);
}

public koniec_czasu()
{
	czas_bronie = true;
}

public LosujProwadzacego()
{
	if(!prowadzacy)
	{
		if(((prowadzacy = RandomCT()) > 0))
		{
			cs_set_player_model(prowadzacy, "jail_prowadzacy_pro");
			set_user_rendering(prowadzacy, kRenderFxGlowShell, 0, 0, 255, kRenderNormal, 15);		
		}
	}
}

stock RandomCT()
{
	new CT_Player[MAX+2], ile=0;
	for(new i=1; i<=MAX; i++)
	{
		if(!is_user_connected(i) || !is_user_alive(i) || gTeam[i] != 2)
			continue;
		
		CT_Player[++ile] = i;
	}
	return CT_Player[(ile? random_num(1, ile): 0)];
}

public Event_CurWeapon(id)
{
	if(g_iAnim == true)
	{
		static iszViewModel = 0;
		if(iszViewModel || (iszViewModel = engfunc(EngFunc_AllocString, "models/JailBreak_Izolatka/v_round_sound.mdl"))) set_pev_string(id, pev_viewmodel2, iszViewModel);
	}
}

public LogEvent_RoundEndTask()
{
	for(new i=1; i<=MAX; i++)
	{
		if(!is_user_connected(i) || !is_user_alive(i)) continue;
		static iszViewModel = 0;
		if(iszViewModel || (iszViewModel = engfunc(EngFunc_AllocString, "models/JailBreak_Izolatka/v_round_sound.mdl"))) set_pev_string(i, pev_viewmodel2, iszViewModel);
		set_pdata_float(i, 83, 5.0);
		set_task(5.1, "FalseAnim", i);
		WeaponAnimation(i, 0);
		g_iAnim = true;
	}
}

public FalseAnim(id)
{
	g_iAnim = false;
	engclient_cmd(id, "weapon_knife");
}

stock WeaponAnimation(pPlayer, iAnimation)
{
	set_pev(pPlayer, pev_weaponanim, iAnimation);
	engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0.0, 0.0, 0.0}, pPlayer);
	write_byte(iAnimation);
	write_byte(0);
	message_end();
}

new TimeAfk[MAX+1], LastPosition[MAX+1][3];
public task_server()
{
	if(end_usun)
		return;
		
	for(new id=1; id<=MAX; id++)
	{
		if(!is_user_alive(id) || !is_user_connected(id))
			continue;
	
		if(gTeam[id] == 1)
		{
			if(dane_dnia[6])
			{
				new PlayerPos[3];
				get_user_origin(id, PlayerPos);
				if(PlayerPos[0] == LastPosition[id][0] && PlayerPos[1] == LastPosition[id][1]) 
				{
					TimeAfk[id]++;	
					if(TimeAfk[id] == 15) 
					{
						jb_chat_print(id, "Przestan Kampic!");
						ExecuteHam(Ham_TakeDamage, id, 0, 0, 5.0, (1<<14));
					} 
					else if(TimeAfk[id] == 18) 
					{
						jb_chat_print(id, "Przestan Kampic!");
						ExecuteHam(Ham_TakeDamage, id, 0, 0, 10.0, (1<<14));
					}
					else if(TimeAfk[id] >= 20)
					{
						jb_chat_print(id, "Przestan Kampic!");
						ExecuteHam(Ham_TakeDamage, id, 0, 0, 20.0, (1<<14));
					}
				}
				else 
					TimeAfk[id] = 0;
	
				LastPosition[id][0] = PlayerPos[0];
				LastPosition[id][1] = PlayerPos[1];
			}
			
			if(czas_bronie && dane_dnia[0] == 1 && ostatni_wiezien == id && !pokaz_raz)
			{
				new iRet;
				usun_ustawienia_dzien();
				
				ExecuteForward(fLastPrisonerShowWish, iRet, id);
				
				obsluga_dala = true;
				pokaz_raz = true;
			}
		}
		else if(gTeam[id] == 2)
		{
			PokazStatusText(id, "Wiezniowie: %i zywi | %i Wszyscy", ilosc_graczy[ZYWI], ilosc_graczy[WSZYSCY]);
			if(czas_bronie && !dane_dnia[0] && ostatni_wiezien && prowadzacy == id && !pokaz_raz)
			{
				menu_display(id, ProwadzacyMenu);
				
				usun_ustawienia_dzien();
				pokaz_raz = true;
			}
		}
	}
}

public cmd_hud(id)
{
	id -= TASK_HUD;
	new zegar[9];
	new iTarget = id;
	get_time("%H:%M:%S", zegar, 8);	

	if(!is_user_alive(iTarget)) {
		iTarget = pev(id, pev_iuser2);
	}

	if(jb_hud[id]){
		return
	}	

	static szDay[256];
	if(gTeam[id] == 1 && !(gTeam[iTarget] == 2))
	{
		formatex(szDay, 255, "× Godzina: %s^n× Siedzisz za: %s^n× Dzien: %i - %s^n", zegar, powody_siedzenia[user_powod_siedzenia[iTarget]], jail_day, dni_tygodnia[jail_day%7]);
		set_hudmessage(0, 255, 0, 0.01, 0.18, 0, 0.01, 1.0);
	} else {
		formatex(szDay, 255, "× Godzina: %s^n× Dzien: %i - %s^n", zegar, jail_day, dni_tygodnia[jail_day%7]);
		set_hudmessage(0, 255, 0, 0.01, 0.18, 0, 0.01, 1.0);
	}
	if(prowadzacy && !szInfo[0])
	{	
		set_hudmessage(0, 255, 0, 0.01, 0.18, 0, 0.01, 1.0);
		format(szDay, 255, "%s× Prowadzacy straznik: %s", szDay, nazwa_gracza[prowadzacy]);
	}
	else if(szInfo[0])
	{
		set_hudmessage(255, 0, 0, 0.01, 0.18, 0, 0.01, 1.0);
		format(szDay, 255, "%s%s^n^n^n×", szDay, szInfo);
	}
	ShowSyncHudMsg(id, SyncHudObj3, szDay);
	
	if(szPoszukiwani[0] && !szInfoPosz[0])
	{
		set_hudmessage(0, 255, 0, 0.01, 0.18, 0, 0.01, 1.0);
		ShowSyncHudMsg(id, SyncHudObj4, "× Poszukiwani:%s", szPoszukiwani);
	}
	else if(szInfoPosz[0])
	{
		set_hudmessage(0, 255, 0, 0.01, 0.18, 0, 0.01, 1.0);
		ShowSyncHudMsg(id, SyncHudObj4, szInfoPosz);
	}
	
	set_hudmessage(0, 255, 0, -1.0, 0.0, 0, 0.01, 1.0);
	ShowSyncHudMsg(id, SyncHudObj5, "JailBreak^n> %s × %s × %i Szlugow <", forum, nazwa_gracza[iTarget], jail_get_szlugi(iTarget));
}	

PokazStatusText(id, szText[], any:...)
{
	new szTemp[192];
	vformat(szTemp, 191, szText, 3);
	message_begin(MSG_ONE_UNRELIABLE, 106, {0,0,0}, id);
	write_byte(0);
	write_string(szTemp);
	message_end();
}

usun_ustawienia_dzien()
{
	if(mode_gracza[WALKA])
	{
		mode_gracza[WALKA] = false;
		if(get_user_weapon(ostatni_wiezien) == CSW_KNIFE)
		{
			set_pev(ostatni_wiezien, pev_viewmodel2, SzModels[V_PIESCI]);
			set_pev(ostatni_wiezien, pev_weaponmodel2, SzModels[P_PIESCI]);
		}
	}
	mode_gracza[MIKRO] = true;
	
	mode_gracza[FF_TT] = false;
	mode_gracza[TT_GOD] = false;
	mode_gracza[CT_GOD] = false;
	mode_gracza[CT_NIE_MOZE_TT] = false;
	mode_gracza[TT_NIE_MOZE_CT] = false;
	dane_dnia[4] = 0;
	dane_dnia[7] = 0;
}

public ObslugaZyczen(id)
{
	if(prowadzacy != id || obsluga_dala || !ostatni_wiezien || !czas_bronie)
		return PLUGIN_HANDLED;

	menu_setprop(ProwadzacyMenu, MPROP_EXITNAME, "\d×\w Wyjdz");	
	menu_display(id, ProwadzacyMenu);
	return PLUGIN_HANDLED;
}

public Handel_Obsluga_Zyczen(id, menu, item)
{
	if(prowadzacy != id || !ostatni_wiezien || !is_user_alive(id))
		return;
		
	if(item == MENU_EXIT)
		return;

	switch(item)
	{
		case 0:
		{
			jb_chat_print(0, "Obsluga wiezienia pozwolila wybrac zyczenie!");
			obsluga_dala = true;
			
			new iRet;
			ExecuteForward(fLastPrisonerShowWish, iRet, ostatni_wiezien);
		}
		case 1:
		{ 
			jb_chat_print(0, "Obsluga wiezienia zadecydowala ze wiezien nie ma zyczenia!");
		}
	}
}

public ClientCommand_SelectKnife(id)
{ 
	engclient_cmd(id, "weapon_knife"); 
} 

public OnAddToPlayerKnife(const item, const player)  
{  
	if(pev_valid(item) && is_user_alive(player)) 
	{  
		message_begin(MSG_ONE, 78, .player = player);//WeaponList = 78
		{
			write_string(cs_get_user_team(player) == CS_TEAM_T? "weapon_piesci": "weapon_palka");  // WeaponName  
			write_byte(-1);                   // PrimaryAmmoID  
			write_byte(-1);                   // PrimaryAmmoMaxAmount  
			write_byte(-1);                   // SecondaryAmmoID  
			write_byte(-1);                   // SecondaryAmmoMaxAmount  
			write_byte(2);                    // SlotID (0...N)  
			write_byte(1);                    // NumberInSlot (1...N)  
			write_byte(CSW_KNIFE);            // WeaponID  
			write_byte(0);                    // Flags  
		}
		message_end();  
	}  
} 

public cmdChooseTeam(id)
{
	menu_chooseteam(id)
	return PLUGIN_HANDLED;
}

public msg_vgui_menu(msgid, dest, id) 
{
	if(get_msg_arg_int(1) != 2)
		return PLUGIN_CONTINUE;
	
	g_msgid[id] = msgid;
	menu_chooseteam(id);
	return PLUGIN_HANDLED;
}

public msg_show_menu(msgid, dest, id) 
{
	static team_select[] = "#Team_Select";
	static menu_text_code[sizeof team_select];
	get_msg_arg_string(4, menu_text_code, charsmax(menu_text_code));
	
	if(!equal(menu_text_code, team_select))
		return PLUGIN_CONTINUE;
	
	g_msgid[id] = msgid;
	menu_chooseteam(id);
	return PLUGIN_HANDLED;
}

public menu_chooseteam(id)
{
	if(!is_user_connected(id))
		return PLUGIN_HANDLED;

	new text[512], len;
	len += format(text[len], 511 - len, "\rWybierz druzyne^n");
	len += format(text[len], 511 - len, "\r1. \wWiezniowie^n");
	len += format(text[len], 511 - len, "\r2. \wStraznicy^n^n");
	len += format(text[len], 511 - len, "\r6. \wWidzowie^n^n");
	
	if(gTeam[id])
		len += format(text[len], 511 - len, "^n\r0. \wWyjdz^n");
		
	show_menu(id, gTeam[id]? 0x223: 0x23, text, -1, "mainmenu");
	return PLUGIN_HANDLED;
}

public _menu_chooseteam(id, key)
{
	switch(key)
	{
		case 0, 1, 5: GdzieDojsc(id, key+1);
		case 9: return;
	}
}

GdzieDojsc(id, team)
{
	set_pdata_int(id, 125, get_pdata_int(id, 125) & ~(1<<8));
	if(team == 6)
	{	
		if(!is_user_alive(id))
		{
			gTeam[id] = 0;
			engclient_cmd(id, "jointeam", "6");
		}
		else
			client_print(id, print_center, "Nie mozesz byc obserwatorem");
		return;
	}
	
	if(gTeam[id] == team)
		return;
	
	new ile_graczy[2];
	for(new i=1; i<=32; i++)
	{
		if(!is_user_connected(i))
			continue;
					
		switch(cs_get_user_team(i))
		{
			case 1: ile_graczy[0]++;
			case 2: ile_graczy[1]++;
		}
	}
	if(czas_bronie && jail_day%7 && !gTeam[id] && ((team == 1 && ile_graczy[0]) || (team == 2 && ile_graczy[1])))
	{
		jb_chat_print(id, "Mozesz dolaczyc dopiero jak sie skonczy runda!");
		GdzieDojsc(id, 6);
		return;
	}
	
	new iRet;
	ExecuteForward(fJoinTeam, iRet, id, team, ile_graczy[0], ile_graczy[1]);
	
	switch(iRet)
	{
		case -1: return;
		case 1,2: team = iRet;
	}	
	
	if(gTeam[id] == team)
		return;
	
	new msg_blocke = get_msg_block(g_msgid[id]);
	set_msg_block(g_msgid[id], BLOCK_SET);
	engclient_cmd(id, "jointeam", team==2? "2": "1");
	//set_msg_block(g_msgid[id], msg_blocke);
		
	//set_msg_block(g_msgid[id], BLOCK_SET);
	engclient_cmd(id, "joinclass", "1");
	set_msg_block(g_msgid[id], msg_blocke);
	gTeam[id] = team;
}

public BlokujKomende()
	return PLUGIN_HANDLED;

//cele menu
public WczytajCele()
{
	new szMap[32], szFile[128];
	get_mapname(szMap, 31);
	formatex(szFile, 127, "addons/amxmodx/data/cele/%s.ini", szMap);
	
	if(file_exists(szFile))
	{
		new dane_tablicy[4][32], tablica[256], txtlen;
		for(new i=0; i<file_size(szFile, 1); i++)
		{
			if(i > 1)
				break;
				
			read_file(szFile, i, tablica, 255, txtlen);
			parse(tablica, dane_tablicy[0], 31, dane_tablicy[1], 31, dane_tablicy[2], 31, dane_tablicy[3], 31);
			
			new Float:origin[3];
			origin[0] = str_to_float(dane_tablicy[0]);
			origin[1] = str_to_float(dane_tablicy[1]);
			origin[2] = str_to_float(dane_tablicy[2]);

			new Float:fDistance = 9999.0, Float:fDistance2, ent;
			while((ent = find_ent_by_class(ent, dane_tablicy[3])))
			{	
				new Float:gOrigin[3];
				get_brush_entity_origin(ent, gOrigin);
				
				fDistance2 = vector_distance(gOrigin, origin);
				if(fDistance2 < fDistance)
				{
					fDistance = fDistance2;
					g_Buttons[i] = ent;
				}
			}
		}
	}
	else
		setup_buttons();
}

public MenuUstwianiaCel(id)
{
	if(!(get_user_flags(id) & ADMIN_RCON))
		return PLUGIN_HANDLED;
		
	new menu = menu_create(fmt("\d%s | Menu^n\r[MENU]\w Menu Cel:", forum), "Handel_Cele");

	menu_additem(menu, "Przycisk 1");
	menu_additem(menu, "Przycisk 2 (jak sa 2 przyciski do cel)");
	menu_additem(menu, "Usun Przyciski");
	
	menu_setprop(menu, MPROP_EXITNAME, "\d×\w Wyjdz");
	menu_display(id, menu);
	return PLUGIN_HANDLED;
}

public Handel_Cele(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		return PLUGIN_CONTINUE;
	}
	switch(item)
	{
		case 0: ZapiszIdCel(id, 0);
		case 1: ZapiszIdCel(id, 1);
		case 2:{
			if(g_Buttons[0])
			{
				new szMap[32], szFile[128];
				get_mapname(szMap, 31);
				formatex(szFile, 127, "addons/amxmodx/data/cele/%s.ini", szMap);
				delete_file(szFile);
				g_Buttons[0] = 0;
				
				client_print(id, 3, "[Cele] Usunieto przyciski");
			}
			if(g_Buttons[1])
				g_Buttons[1] = 0;
		}
	}
	menu_display(id, menu);
	return PLUGIN_CONTINUE;
}

ZapiszIdCel(id, linia)
{
	new ent, body;
	get_user_aiming(id, ent, body);
	if(!pev_valid(ent)) 
		return;
		
	g_Buttons[linia] = ent;
	new Float:origin[3], name[32];
	get_brush_entity_origin(ent, origin);
	pev(ent, pev_classname, name, 31);
	
	new szMap[32], szFile[128], szTemp[128];
	get_mapname(szMap, 31);
	formatex(szTemp, 127, "%f %f %f %s", origin[0], origin[1], origin[2], name);
	formatex(szFile, 127, "addons/amxmodx/data/cele/%s.ini", szMap);
	
	write_file(szFile, szTemp, linia);
	client_print(id, 3, "[Cele] Dodano przycisk %i", linia+1);
}

//cele auto
public setup_buttons()
{
	new ent[3], class[32], i, Float:origin[3];
	while((i <= sizeof(g_Buttons)) && (ent[0] = engfunc(EngFunc_FindEntityByString, ent[0], "classname", "info_player_deathmatch")))
	{ 
		pev(ent[0], pev_origin, origin) 
		while((ent[1] = engfunc(EngFunc_FindEntityInSphere, ent[1], origin, 300.0)))
		{ 
			if(!pev_valid(ent[1])) 
				continue;

			pev(ent[1], pev_classname, class, 31);
			if(!equal(class, "func_door"))
				continue;

			pev(ent[1], pev_targetname, class, 31) 
			ent[2] = engfunc(EngFunc_FindEntityByString, 0, "target", class);
			if(pev_valid(ent[2]) && (in_array(ent[2], g_Buttons, sizeof(g_Buttons)) < 0)) 
			{
				g_Buttons[i++] = ent[2]; 
				ent[1] = 0;
				ent[2] = 0;
				break;
			} 
		} 
	} 
}

stock in_array(needle, data[], size)
{
	for(new i = 0; i < size; i++)
	{
		if(data[i] == needle)
			return i;
	}
	return -1;
}
	
public OtworzCele()
{
	for(new i=0; i<sizeof(g_Buttons); i++)
	{
		if(!pev_valid(g_Buttons[i]) || !g_Buttons[i])
			continue;
		ExecuteHam(Ham_Use, g_Buttons[i], 0, 0, 2, 1.0);
	}
}

AddArray(id, ktore)
{
	if(free_day[id] || user_duszek[id])
		return;
	
	if(array_graczy[ktore][id])
		return;
		
	ostatni_wiezien = (ilosc_graczy[ktore]? 0: id);
	
	array_graczy[ktore][id] = id;
	ilosc_graczy[ktore]++;
}

DelArray(id, ktore)
{
	if(free_day[id] || user_duszek[id])
		return;
	
	if(!array_graczy[ktore][id])
		return;
		
	array_graczy[ktore][id] = 0;
	ilosc_graczy[ktore]--;
	
	if(jail_day%7 && ktore == ZYWI)
	{
		switch(ilosc_graczy[ktore])
		{
			case 1:{ 
				for(new i=1; i<=MAX; i++)
				{
					if(array_graczy[ktore][i])
					{
						ostatni_wiezien = array_graczy[ktore][i];
						break;
					}
				}
			}
			default: ostatni_wiezien = 0;
		}
	}
}

AddPoszukiwany(attacker)
{
	if(contain(szPoszukiwani, nazwa_gracza[attacker]) == -1)
	{
		new szTemp[512];
		formatex(szTemp, charsmax(szTemp), "^n  %s%s", nazwa_gracza[attacker], szPoszukiwani);
		copy(szPoszukiwani, charsmax(szPoszukiwani), szTemp);
		
		cs_set_player_model(attacker, "jail_wiezien_pro");		
		set_pev(attacker, pev_skin, 9);
		set_user_rendering(attacker, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 25);
	}
	if(task_exists(ID_DZWIEK_POSZ))
		remove_task(ID_DZWIEK_POSZ);

	dzwiek_poszukiwany();
	set_task(1.0, "dzwiek_poszukiwany", ID_DZWIEK_POSZ, .flags="a", .repeat=9);	
}

public dzwiek_poszukiwany()
	client_cmd(0, "spk jb_cypis/uciekinier.wav");

DelPoszukiwany(id)
{
	if(contain(szPoszukiwani, nazwa_gracza[id]) != -1)
	{
		new szTemp[512];
		formatex(szTemp, charsmax(szTemp), "^n  %s", nazwa_gracza[id]);
		replace_all(szPoszukiwani, charsmax(szPoszukiwani), szTemp, "");
	}
}

stock ham_strip_weapon(id, wid)
{
	if(!wid) 
		return 0;
		
	new szName[24];
	get_weaponname(wid, szName, 23);
	
	new ent;
	while((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", szName)) && pev(ent, pev_owner) != id) {}
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

stock Jaki_Pistolet(id)
{
	if(!is_user_alive(id))
		return 0;
	
	new weapons[32], numweapons;
	get_user_weapons(id, weapons, numweapons);
	
	for(new i=0; i<numweapons; i++)
		if((1<<weapons[i]) & 0x50FCF1A8)
			return weapons[i];
	
	return 0;
}

public _jb_print_chat(id, const text[], any:...)
{
	static message[192];

	for (new i = 2; i <= numargs(); i++) param_convert(i);

	if (numargs() == 2) copy(message, charsmax(message), text);
	else vformat(message, charsmax(message), text, 3);

	jb_chat_print(id, message);
}

stock jb_chat_print(id, const text[], any:...)
{
	new message[192];

	if (numargs() == 2) copy(message, charsmax(message), text);
	else vformat(message, charsmax(message), text, 3);

	client_print_color(id, id, "^4[PrisonBreak]^1 %s", message);
}

/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1045\\ f0\\ fs16 \n\\ par }
*/
