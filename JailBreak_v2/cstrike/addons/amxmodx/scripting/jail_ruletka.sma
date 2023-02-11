#include <amxmodx>
#include <fun>
#include <engine>
#include <cstrike>
#include <hamsandwich>
#include <fakemeta_util>
#include <nvault>
#include <jailbreak>

native jail_set_szlugi(id, ile);
native jail_get_szlugi(id);

#define message_begin_fl(%1,%2,%3,%4) engfunc(EngFunc_MessageBegin, %1, %2, %3, %4)
#define write_coord_fl(%1) engfunc(EngFunc_WriteCoord, %1)

new Float:kb_weapon_power[] = 
{
	-1.0,	// ---
	2.4,	// P228
	-1.0,	// ---
	6.5,	// SCOUT
	-1.0,	// ---
	8.0,	// XM1014
	-1.0,	// ---
	2.3,	// MAC10
	5.0,	// AUG
	-1.0,	// ---
	2.4,	// ELITE
	2.0,	// FIVESEVEN
	2.4,	// UMP45
	5.3,	// SG550
	5.5,	// GALIL
	5.5,	// FAMAS
	2.2,	// USP
	2.0,	// GLOCK18
	10.0,	// AWP
	2.5,	// MP5NAVY
	5.2,	// M249
	8.0,	// M3
	5.0,	// M4A1
	2.4,	// TMP
	6.5,	// G3SG1
	-1.0,	// ---
	5.3,	// DEAGLE
	5.0,	// SG552
	6.0,	// AK47
	-1.0,	// ---
	2.0		// P90
}

#define TASK_ZATRUCIE 333
#define TASK_ZACMIENIE 444
#define TASK_DUSZEK 555
#define TASK_NACPANIE1 666
#define TASK_NACPANIE2 777
#define TASK_BOMBA 888
#define TASK_ZAMROZENIE 1222
#define TASK_SLAPOWANIE 1333
#define TASK_KAMUFLAZ 1444
#define TASK_AUTOBH 1555

new g_pCvarCzasRuletki;
new g_iMsgFov;
new g_iIloscSlotow;

#define	FL_WATERJUMP	(1<<11)	// popping out of the water
#define	FL_ONGROUND	(1<<9)	// not moving on the ground

new g_iSpriteBlast;

new g_iIloscTrutek[33];
new g_iDodatkoweSkoki[33];
new bool:g_bAutoBH[33];
new bool:g_bWscieklePiesciWeza[33];
new bool:g_bRekawiceZlodzieja[33];
new Float:g_fBetonoweCialo[33];
new g_iCzasBomby[33];
new bool:g_bBezlikAmmo[33];
new bool:g_bNoRecoil[33];
new Float:g_fBonusoweObrazenia[33];
new Float:g_fNiesmiertelnosc[33];
new g_iSzansaNaZatrucie[33];
new bool:g_bNabojeOdpychajace[33];
new Float:g_fNastepneUzycie[33];
new bool:RuletkaZajeta;

public plugin_init() {
	register_plugin("Ruletka", "1.0", "d0naciak.pl")
	
	g_pCvarCzasRuletki = register_cvar("jb_ruletka_czas", "250.0");
	register_clcmd("say /ruletka", "cmd_Ruletka");
	register_clcmd("say /los", "cmd_Ruletka");
	
	register_forward(FM_CmdStart, "fw_CmdStart");
	register_forward(FM_PlayerPreThink, "fw_Prethink");
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1);
	
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage");
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack_Post", 1)
	
	register_event("CurWeapon", "ev_CurWeapon", "be", "1=1");
	register_event("ResetHUD", "ev_ResetHUD", "b");
	register_event("HLTV", "ev_NowaRunda", "a", "1=0", "2=0");
	
	g_iIloscSlotow = get_maxplayers();
	g_iMsgFov = get_user_msgid("SetFOV");
	
	new iVault = nvault_open("Ruletka");
	nvault_prune(iVault, 0, get_systime() + 99999);
	nvault_close(iVault);
}

public plugin_natives() {
	register_native("jail_ruletka", "cmd_Ruletka", 1);
}

public plugin_precache() {
	
	g_iSpriteBlast = precache_model("sprites/dexplo.spr");
	
	precache_sound("weapons/de_clipin.wav");
	precache_sound("JailBreak_Izolatka/odliczanie.wav");
	precache_sound("debris/glass1.wav");
}

public client_connect(id) {
	g_iDodatkoweSkoki[id] = 0;
	g_bAutoBH[id] = false;
	g_bWscieklePiesciWeza[id] = false;
	g_bRekawiceZlodzieja[id] = false
	g_fBetonoweCialo[id] = 0.0;	
	g_bBezlikAmmo[id] = false;
	g_bNoRecoil[id] = false;
	g_fBonusoweObrazenia[id] = 0.0;
	g_fNiesmiertelnosc[id] = 0.0;
	g_iSzansaNaZatrucie[id] = 0;
	g_bNabojeOdpychajace[id] = false;
	
	remove_task(id + TASK_ZATRUCIE);
	remove_task(id + TASK_DUSZEK);	
	remove_task(id + TASK_NACPANIE1);
	remove_task(id + TASK_NACPANIE2);
	remove_task(id + TASK_BOMBA);
	remove_task(id + TASK_SLAPOWANIE);
	remove_task(id + TASK_AUTOBH);
}

public client_authorized(id) {
	new iVault = nvault_open("Ruletka");
	new szNick[32], szDane[32];
	get_user_name(id, szNick, 31);
	
	if(nvault_get(iVault, szNick, szDane, 31)) {
		g_fNastepneUzycie[id] = str_to_float(szDane);
	} else {
		g_fNastepneUzycie[id] = 0.0;
	}
	
	nvault_close(iVault);
}

public client_disconnected(id) {
	new iVault = nvault_open("Ruletka");
	new szNick[32], szDane[32];
	get_user_name(id, szNick, 31);
	float_to_str(g_fNastepneUzycie[id], szDane, 31);
	nvault_set(iVault, szNick, szDane);
	nvault_close(iVault);
	
	client_connect(id);
}

public cmd_Ruletka(id) {
	if(!is_user_alive(id)) {
		PokazWiadomosc(id, "Nie mozesz z niej korzystac bedac^3 martwym!");
		return PLUGIN_HANDLED;
	}
	
	if(!(1 <= jail_get_play_game_id() <= 5))
	{
		PokazWiadomosc(id, "Ruletka jest niedostepna podczas^3 zabaw!");
		return PLUGIN_HANDLED;
	}	
	
	new Float:fGameTime = get_gametime();
	if(g_fNastepneUzycie[id] > fGameTime) {
		PokazWiadomosc(id, "Ruletka bedzie dostepna za^3 %d^1 sekund(y)!", floatround(g_fNastepneUzycie[id] - fGameTime));
		return PLUGIN_HANDLED;
	}

	if(RuletkaZajeta) {
		PokazWiadomosc(id, "Ruletka^3 zajeta^1, sprobuj ponownie pozniej.");
		return PLUGIN_HANDLED;
	}

	g_fNastepneUzycie[id] = fGameTime + get_pcvar_float(g_pCvarCzasRuletki);

	get_user_team(id) == 1 ? LosujDlaTerro(id) : LosujDlaCT(id);
	
	RuletkaZajeta = true;
	set_task(4.0, "Ruletka_ON");	

	return PLUGIN_HANDLED;
}

public Ruletka_ON() RuletkaZajeta = false;

public LosujDlaTerro(id) {
	switch(random_num(1, 138)) 
	{
		case 1..8: {
			new iHp = random(100)+1;
			set_user_health(id, get_user_health(id) + iHp);
			PokazNagrode(id, "+%d Zdrowia", iHp);
			PokazNagrodeHud(id, "dostal +%d Zdrowia", iHp);
		}
		case 9..16: {
			new iLosoweSzlugi = random(10)+1;
			new iSzlugi = jail_get_szlugi(id) + iLosoweSzlugi;
			jail_set_szlugi(id, iSzlugi);
			PokazNagrode(id, "+%d^1 Szlugow", iLosoweSzlugi);
			PokazNagrodeHud(id, "dostal %d Szlugow", iLosoweSzlugi);
		}
		case 25..32: {
			new Float:fGrawitacja = random_float(0.2, 0.6);
			set_user_gravity(id, fGrawitacja);
			PokazNagrode(id, "zmniejszona grawitacje");
			PokazNagrodeHud(id, "ma nizsza grawitacje");
		}
		case 33..40: {
			set_user_footsteps(id, 1);
			PokazNagrode(id, "ciche buty");
			PokazNagrodeHud(id, "ma ciche BUTY");
		}
		
		case 41..43: {
			PokazNagrode(id, "granat odlamkowy");
			give_item(id, "weapon_hegrenade");
			PokazNagrodeHud(id, "otrzymal HEJDZA");
			
			if(!random(8)) {
				cs_set_user_bpammo(id, CSW_HEGRENADE, 2);
				PokazWiadomosc(id, "Tak na prawde dostales 2 granaty, ale ciii...");
			}
		}
		case 46..48: {	
			PokazNagrode(id, "granat oslepiajacy");
			give_item(id, "weapon_flashbang");
			PokazNagrodeHud(id, "otrzymal FLASHA");
			
			if(!random(8)) {
				cs_set_user_bpammo(id, CSW_FLASHBANG, 2);
				PokazWiadomosc(id, "Tak na prawde dostales 2 granaty, ale ciii...");
			}	
		}
		case 52: {
			PokazNagrode(id, "M3 z jednym nabojem");
			PokazNagrodeHud(id, "otrzymal M3");
			
			new iEnt = give_item(id, "weapon_m3");
			
			if(iEnt > 0) {
				cs_set_weapon_ammo(iEnt, 1);
			}
			
			if(!random(10)) {
				cs_set_user_bpammo(iEnt, CSW_M3, 1);
				PokazWiadomosc(id, "W prezencie dodajemy jeszcze 1 ammo w magazynku, w razie gdyby :D");
			}
		}
		
		case 53: {
			PokazNagrode(id, "Scouta z jednym nabojem");
			PokazNagrodeHud(id, "otrzymal Scouta");
			
			new iEnt = give_item(id, "weapon_scout");
			
			if(iEnt > 0) {
				cs_set_weapon_ammo(iEnt, 1);
			}
			
			if(!random(10)) {
				cs_set_user_bpammo(id, CSW_SCOUT, 2);
				PokazWiadomosc(id, "W prezencie dodajemy jeszcze 2 ammo w magazynku, w razie gdyby :D");
			}
		}
		
		case 54: {
			PokazNagrode(id, "Deagla z jednym nabojem");
			PokazNagrodeHud(id, "otrzymal Deagla");
			
			new iEnt = give_item(id, "weapon_deagle");
			
			if(iEnt > 0) {
				cs_set_weapon_ammo(iEnt, 1);
			}
			
			if(!random(10)) {
				cs_set_user_bpammo(id, CSW_DEAGLE, 1);
				PokazWiadomosc(id, "W prezencie dodajemy jeszcze 1 ammo w magazynku, w razie gdyby :D");
			}
		}
		
		case 55: {
			PokazNagrode(id, "AWP z jednym nabojem");
			PokazNagrodeHud(id, "otrzymal AWP");
			
			new iEnt = give_item(id, "weapon_awp");
			
			if(iEnt > 0) {
				cs_set_weapon_ammo(iEnt, 1);
			}
			
			if(!random(30)) {
				cs_set_user_bpammo(id, CSW_AWP, 1);
				PokazWiadomosc(id, "W prezencie dodajemy jeszcze 1 ammo w magazynku, w razie gdyby :D");
			}
		}

		case 56: {
			give_item(id, "weapon_shield");
			PokazNagrode(id, "tarcze");
			PokazNagrodeHud(id, "otrzymal TARCZE");
		}
		
		case 57..60: {
			new iCzas = random_num(2, 7);
			set_user_rendering(id,kRenderFxNone, 0, 0, 0, kRenderTransAlpha, 5);
			set_bartime(id, iCzas);
			set_task(float(iCzas), "task_KoniecKamuflaza", id + TASK_KAMUFLAZ);
			PokazNagrode(id, "kamuflaz ninja");
			PokazNagrodeHud(id, "jest NIEWIDZIALNY");
		}
		
		case 61..64: {
			new iFlagi = get_user_flags(id);
			new iIloscSkokow = 1;
			
			if(!random(10)) {
				iIloscSkokow = 99;
			}
			
			if((iFlagi & ADMIN_LEVEL_H || iFlagi & ADMIN_LEVEL_G) && iIloscSkokow == 1) {
				LosujDlaTerro(id);
				return;
			}
			
			g_iDodatkoweSkoki[id] = iIloscSkokow;
			
			PokazNagrode(id, "%d^1 dodatkowych skokow", iIloscSkokow);
			PokazNagrodeHud(id, "wygral DODATKOWE SKOKI");
		}
		
		case 65..70: {
			new iFlagi = get_user_flags(id);
			
			if(iFlagi & ADMIN_LEVEL_H || iFlagi & ADMIN_LEVEL_G) {
				LosujDlaTerro(id);
				return;
			}
			
			g_bAutoBH[id] = true;
			PokazNagrode(id, "AutoBH");
			PokazNagrodeHud(id, "wygral AUTO BHOPA");
		}
		
		case 71..76: {
			g_bWscieklePiesciWeza[id] = true;
			PokazNagrode(id, "Wsciekle Piesci Weza");
			PokazNagrodeHud(id, "wygral Wsciekle Piesci Weza");
		}
		
		case 77..82: {
			g_bRekawiceZlodzieja[id] = true;
			PokazNagrode(id, "rekawice zlodzieja");
			PokazNagrodeHud(id, "wygral REKAWICE ZLODZIEJA");
			PokazWiadomosc(id, "Podejdz do klawisza i nacisnij^4 E^1, a okradniesz go z^3 amunicji.");
		}
		
		case 83..85: {
			new iCzas = random(6) + 3;
			g_fBetonoweCialo[id] = get_gametime() + float(iCzas);
			set_bartime(id, iCzas);
			
			PokazNagrode(id, "betonowe cialo");
			PokazNagrodeHud(id, "wygral BETONOWE CIALO");
			PokazWiadomosc(id, "Zginiesz tylko, kiedy dostaniesz^4 HeadShota.");
		}
		
		case 86..88: {
			new iCzas = random(3) + 3;
			
			set_user_noclip(id, 1);
			
			set_task(float(iCzas), "task_Duszek", id + TASK_DUSZEK);
			set_bartime(id, iCzas);
			
			PokazNagrode(id, "NoClipa");
			PokazNagrodeHud(id, "wygral NOCLIPA");
			PokazWiadomosc(id, "Mozesz teraz przenikac przez^4 sciany!");
		}
		
		case 89..95: {
			PokazNagrode(id, "pusty los");
			PokazNagrodeHud(id, "wygral NIC");
		}
		
		case 96..98: {
			new iHp = random(100)+1;
			set_user_health(id, get_user_health(id) - iHp);
			PokazNagrode(id, "-%d^1 Zdrowia", iHp);
			PokazNagrodeHud(id, "dostal +%d Zdrowia", iHp);
		}
		
		case 99..101: {
			set_user_health(id, 1);
			PokazNagrode(id, "1^1 punkcik zdrowia");
			PokazNagrodeHud(id, "ma 1 HP");
		}
		case 109..113: {
			remove_task(id + TASK_NACPANIE1);
			remove_task(id + TASK_NACPANIE2);
			
			message_begin(MSG_ONE, g_iMsgFov, {0,0,0}, id);
			write_byte(170); 
			message_end();
			
			set_task(2.0, "task_Chodzenie", id + TASK_NACPANIE1, _, _, "b");
			set_task(6.5, "task_KoniecNacpania", id + TASK_NACPANIE2);
			
			PokazNagrode(id, "niezly towar...");
			PokazNagrodeHud(id, "ma NIEZLY TOWAR");
		}
		
		case 114..119: {
			new iCzas = g_iCzasBomby[id] = random(6) + 4;
			
			set_task(1.0, "task_OdliczanieEksplozja", id + TASK_BOMBA, _, _, "b");
			set_bartime(id, iCzas);
			
			PokazNagrode(id, "bombe na plecach XD");
			PokazNagrodeHud(id, "ma BOMBE");
		}
		case 125..132: {
			user_slap(id, 0, 1);
			PokazNagrode(id, "pstryka w ucho");
			PokazNagrodeHud(id, "dostal pstryka w ucho");
		}
		
		case 133..138: {
			set_task(0.2, "task_Slapuj", id + TASK_SLAPOWANIE, _, _, "a", 8);
			PokazNagrode(id, "serie ciosow od^4 Jackie Chan'a");
			PokazNagrodeHud(id, "dostal serie ciosow od Jackie Chan'a");
		}
	}
}

LosujDlaCT(id) {
	switch(random_num(0, 67)) 
	{
		case 0..8: {
			g_bBezlikAmmo[id] = true;
			PokazNagrode(id, "bezlik ammo");
			PokazNagrodeHud(id, "ma BEZLIK AMMO");
		}

		case 9..16: {
			g_bNoRecoil[id] = true;
			PokazNagrode(id, "brak rozrzutu");
			PokazNagrodeHud(id, "ma BRAK ROZRZUTU");			
		}

		case 25..32: {
			new iHp = random(150)+1;
			set_user_health(id, get_user_health(id) + iHp);
			PokazNagrode(id, "+%d^1 Zdrowia", iHp);
			PokazNagrodeHud(id, "dostal +%d Zdrowia", iHp);
		}

		case 33..36: {
			new iObrazenia = random(20) + 10;
			g_fBonusoweObrazenia[id] = float(iObrazenia);
			PokazNagrode(id, "+%d^1 obrazen", iObrazenia);
			PokazNagrodeHud(id, "ma +%d obrazen", iObrazenia);
		}

		case 37..44: {
			new iFlagi = get_user_flags(id);
			if(iFlagi & ADMIN_LEVEL_H || iFlagi & ADMIN_LEVEL_G) {
				LosujDlaCT(id);
				return;
			}
			
			g_bAutoBH[id] = true;
			set_task(15.0, "task_KoniecAutoBH", id + TASK_AUTOBH);
			set_bartime(id, 15);

			PokazNagrode(id, "AutoBH^1 na^4 15^1 sek.");
			PokazNagrodeHud(id, "wygral AUTO BHOPA na 15 sek");
		}

		case 45: {
			new iCzas = random(5) + 10;
			g_fBetonoweCialo[id] = get_gametime() + float(iCzas);
			set_bartime(id, iCzas);
			
			PokazNagrode(id, "betonowe cialo");
			PokazWiadomosc(id, "Zginiesz tylko, kiedy dostaniesz^4 HeadShota.");
			PokazNagrodeHud(id, "wygral BETONOWE CIALO");
		}

		case 46: {
			new iCzas = random(5) + 10;
			g_fNiesmiertelnosc[id] = get_gametime() + float(iCzas);
			set_bartime(id, iCzas);

			PokazNagrode(id, "niesmiertelnosc");
			PokazNagrodeHud(id, "ma NIESMIERTELNOSC");
		}

		case 47..50: {
			new iSzansa = random(7) + 9;
			g_iSzansaNaZatrucie[id] = iSzansa;

			PokazNagrode(id, "1/%d^1 szansy na otrucie", iSzansa);
			PokazNagrodeHud(id, "ma 1/%d^1 szansy na otrucie", iSzansa);
		}

		case 51..54: {
			g_bNabojeOdpychajace[id] = true;
			PokazNagrode(id, "odpychajace naboje");
			PokazNagrodeHud(id, "wygral ODPYCHAJACE NABOJE");
		}

		case 55..63: {
			PokazNagrode(id, "pusty los");
			PokazNagrodeHud(id, "wygral AUTO BHOPA");
		}
		
		case 71..76: {
			g_bWscieklePiesciWeza[id] = true;
			PokazNagrode(id, "Wsciekle Piesci Weza");
			PokazNagrodeHud(id, "wygral Wsciekle Piesci Weza");
		}
		
		case 77..82: {
			g_bRekawiceZlodzieja[id] = true;
			PokazNagrode(id, "rekawice zlodzieja");
			PokazNagrodeHud(id, "wygral REKAWICE ZLODZIEJA");
			PokazWiadomosc(id, "Podejdz do klawisza i nacisnij^4 E^1, a okradniesz go z^3 amunicji.");
		}
		
		case 83..85: {
			new iCzas = random(6) + 3;
			g_fBetonoweCialo[id] = get_gametime() + float(iCzas);
			set_bartime(id, iCzas);
			
			PokazNagrode(id, "betonowe cialo");
			PokazNagrodeHud(id, "wygral BETONOWE CIALO");
			PokazWiadomosc(id, "Zginiesz tylko, kiedy dostaniesz^4 HeadShota.");
		}
		
		case 86..88: {
			new iCzas = random(3) + 3;
			
			set_user_noclip(id, 1);
			
			set_task(float(iCzas), "task_Duszek", id + TASK_DUSZEK);
			set_bartime(id, iCzas);
			
			PokazNagrode(id, "NoClipa");
			PokazNagrodeHud(id, "wygral NOCLIPA");
			PokazWiadomosc(id, "Mozesz teraz przenikac przez^4 sciany!");
		}
		
		case 89..95: {
			PokazNagrode(id, "pusty los");
			PokazNagrodeHud(id, "wygral NIC");
		}

		case 64: {
			new weapon = get_user_weapon(id);
			if(CSW_ALL_GUNS & (1<<weapon)) {
				set_user_clip(id, 0);
				PokazNagrode(id, "oproznienie amunicji");
				PokazNagrodeHud(id, "wygral OPROZNIENIE AMUNICJI");
			} else {
				PokazNagrode(id, "pusty los");
				PokazNagrodeHud(id, "wygral NIC");
			}
		}

		case 65: {
			new iBronie[32], iIlosc;
			get_user_weapons(id, iBronie, iIlosc);
			
			for(new j = 0; j < iIlosc; j++)
				set_pdata_float(fm_get_user_weapon_entity(id, iBronie[j]), 46, 999.0, 4);
			
			jail_set_user_speed(id, 0.1);
		
			show_icon(id, 1, "dmg_cold", 0, 153, 153);
			Display_Fade(id, (1<<12) * 4, (1<<12) * 4, 0x0000, 0, 153, 153, 153);
			emit_sound(id, CHAN_ITEM, "debris/glass1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_LOW);
			
			remove_task(id + TASK_ZAMROZENIE);
			set_task(4.0, "task_OdmrozGracza", id + TASK_ZAMROZENIE);
			
			PokazNagrode(id, "zamrozenie");
			PokazNagrodeHud(id, "jest ZAMROZONY");
		}

		case 66: {
			Display_Fade(id, (1<<12) * 2, (1<<12) * 4, 0x0000, 0, 0, 0, 0);
			PokazNagrode(id, "zacmienie ekranu");
			PokazNagrodeHud(id, "wygral ZACMIENIE EKRANU");
		}

		case 67: {
			set_task(0.2, "task_Slapuj", id + TASK_SLAPOWANIE, _, _, "a", 8);
			PokazNagrode(id, "serie ciosow od^3 Jackie Chan'a");
			PokazNagrodeHud(id, "wygral Wylosowales/as serie ciosow od Jackie Chan'a");
		}
	}
}

public fw_CmdStart(id, uc_handle)
{
	if(!is_user_alive(id))
		return FMRES_IGNORED;
	
	new iButtons = get_uc(uc_handle, UC_Buttons), iOldButtons = pev(id, pev_oldbuttons);
	
	if(g_iDodatkoweSkoki[id]) {
		new flags = pev(id, pev_flags);
		static skoki[33];
		
		if((iButtons & IN_JUMP) && !(flags & FL_ONGROUND) && !(iOldButtons & IN_JUMP) && skoki[id])
		{
			skoki[id]--;
			new Float:velocity[3];
			pev(id, pev_velocity,velocity);
			velocity[2] = random_float(265.0,285.0);
			set_pev(id, pev_velocity,velocity);
		}
		else if(flags & FL_ONGROUND)
			skoki[id] = g_iDodatkoweSkoki[id];
	}
	
	if(iButtons & IN_USE && !(iOldButtons & IN_USE) && g_bRekawiceZlodzieja[id]) {
		new iTarget, iBody, Float:fOdleglosc = get_user_aiming(id, iTarget, iBody);
		
		if(iTarget && get_user_team(iTarget) == 2) {
			if(fOdleglosc > 250.0) {
				client_print(id, print_center, "Twoj cel jest za daleko!");
			} else {
				new iBron = get_user_weapon(iTarget);
				
				switch(iBron) {
					case 0, CSW_KNIFE, CSW_SMOKEGRENADE, CSW_HEGRENADE, CSW_FLASHBANG: {
						client_print(id, print_center, "Bron, ktora trzyma klawisz, nie posiada amunicji.");
					}
					
					default: {
						new szBron[32]; get_weaponname(iBron, szBron, 31);
						new iEnt = find_ent_by_owner(0, szBron, iTarget);
						
						if(iEnt > 0) {
							cs_set_weapon_ammo(iEnt, 0);
						}
						
						cs_set_user_bpammo(iTarget, iBron, 0);
						g_bRekawiceZlodzieja[id] = false;
						
						emit_sound(id, CHAN_BODY, "weapons/de_clipin.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
					}
				}
			}
		}
	}
	
	return FMRES_IGNORED;
}

public fw_Prethink(id)
{
	if(!is_user_alive(id))
		return FMRES_IGNORED;
		
	if(g_bAutoBH[id]) {
		if (pev(id, pev_button) & IN_JUMP) {
			new flags = pev(id, pev_flags)
	
			if (flags & FL_WATERJUMP)
				return FMRES_IGNORED;
			if ( pev(id, pev_waterlevel) >= 2 )
				return FMRES_IGNORED;
			if ( !(flags & FL_ONGROUND) )
				return FMRES_IGNORED;
	
			new Float:velocity[3];
			pev(id, pev_velocity, velocity);
			velocity[2] += 250.0;
			set_pev(id, pev_velocity, velocity);
	
			set_pev(id, pev_gaitsequence, 6);
	
		}
	}
	
	if(task_exists(id + TASK_ZAMROZENIE)) {		
		set_pev(id,pev_velocity,Float:{0.0,0.0,0.0});
		
		if((pev(id,pev_button) & IN_JUMP) && !(pev(id,pev_oldbuttons) & IN_JUMP) && (pev(id,pev_flags) & FL_ONGROUND))
			set_pev(id,pev_gravity,999999999.9);
		else 
			set_pev(id,pev_gravity,0.000000001);
	}

	if(g_bNoRecoil[id]) {
		set_pev(id, pev_punchangle, Float:{0.0, 0.0, 0.0});
	}

	return FMRES_IGNORED;
}

public fw_UpdateClientData_Post(id, iSW, iCdHandle) {
	if(!is_user_alive(id)) {
		return FMRES_IGNORED;
	}

	if(g_bNoRecoil[id]) {
		set_cd(iCdHandle, CD_PunchAngle, Float:{0.0, 0.0, 0.0});
	}

	return FMRES_IGNORED;
}

public fw_TakeDamage(id, iEnt, iAtt, Float:fDmg, iDmgBits) {
	if(!is_user_connected(iAtt)) {
		return HAM_IGNORED;
	}

	if(iDmgBits & (1<<1) && g_fNiesmiertelnosc[id] > get_gametime()) {
		SetHamParamEntity(1, 0);
		SetHamParamFloat(4, 0.0);
		SetHamParamInteger(5, 0);
		return HAM_HANDLED;
	}
	
	if(iDmgBits & (1<<1) && g_fBetonoweCialo[id] > get_gametime() && get_pdata_int(id, 75, 5)  != HIT_HEAD) {
		SetHamParamEntity(1, 0);
		SetHamParamFloat(4, 0.0);
		SetHamParamInteger(5, 0);
		return HAM_HANDLED;
	}

	if(g_bWscieklePiesciWeza[iAtt] && iDmgBits & (1<<1) && get_user_weapon(iAtt) == CSW_KNIFE && get_pdata_int(id, 75, 5)  != HIT_HEAD) {
		new iButtons = pev(iAtt, pev_button);
		new Float:fVelocity[3], Float:fPunchAngle[3] ,Float:fAngles[3], Float:fObrazenia;
		
		pev(iAtt, pev_v_angle, fAngles);
		
		if(iButtons & IN_ATTACK) {
			fVelocity[0] = (floatcos(fAngles[1], degrees) * 200.0);
			fVelocity[1] = (floatsin(fAngles[1], degrees) * 200.0);
			fVelocity[2] = 300.0;
			
			fPunchAngle[1] = random_float(30.0, 45.0) * ((random(2)) ? -1.0 : 1.0);
			
			fObrazenia = 32.0
		}
			
		else {
			fVelocity[0] = (floatcos(fAngles[1], degrees) * 600.0);
			fVelocity[1] = (floatsin(fAngles[1], degrees) * 600.0);
			fVelocity[2] = 400.0;
			
			fPunchAngle[0] = random_float(4.0, 32.0) * ((random(2)) ? -1.0 : 1.0);
			fPunchAngle[1] = random_float(45.0, 70.0) * ((random(2)) ? -1.0 : 1.0);
			
			fObrazenia = 96.0;
		}
		
		set_pev(id, pev_velocity, fVelocity);
		set_pev(id, pev_punchangle, fPunchAngle);
		SetHamParamFloat(4, fObrazenia);
		return HAM_HANDLED;
	}

	if(g_fBonusoweObrazenia[iAtt] > 0.0 && iDmgBits & (1<<1)) {
		SetHamParamFloat(4, fDmg + g_fBonusoweObrazenia[iAtt]);
		return HAM_HANDLED;
	}

	if(g_iSzansaNaZatrucie[iAtt] && !random(g_iSzansaNaZatrucie[iAtt])) {
		g_iIloscTrutek[id] = 8;
		
		if(!task_exists(id)) {
			new iDane[2];
			iDane[0] = iAtt;
			iDane[1] = id;
			
			set_task(0.8, "task_ZatrucieGracza", TASK_ZATRUCIE + id, iDane, 2, "b");
			client_cmd(id, "spk scientist/cough.wav");
		}
	}
	
	return HAM_IGNORED;
}

public fw_TraceAttack_Post(victim, attacker, Float:damage, Float:direction[3], tracehandle, damage_type) {
	if (!g_bNabojeOdpychajace[attacker] || victim == attacker || !is_user_alive(attacker) || !(damage_type & (1<<1))) {
		return HAM_IGNORED;
	}

	
	if (damage <= 0.0 || GetHamReturnStatus() == HAM_SUPERCEDE || get_tr2(tracehandle, TR_pHit) != victim) {
		return HAM_IGNORED;
	}

	new ducking = pev(victim, pev_flags) & (FL_DUCKING | FL_ONGROUND) == (FL_DUCKING | FL_ONGROUND)
	
	static origin1[3], origin2[3]
	get_user_origin(victim, origin1)
	get_user_origin(attacker, origin2)
	
	if (get_distance(origin1, origin2) > 500.0) {
		return HAM_IGNORED;
	}
	
	static Float:velocity[3]
	pev(victim, pev_velocity, velocity)
	
	xs_vec_mul_scalar(direction, damage, direction)
	
	new attacker_weapon = get_user_weapon(attacker)
	if (kb_weapon_power[attacker_weapon] > 0.0) {
		xs_vec_mul_scalar(direction, kb_weapon_power[attacker_weapon], direction)
	}
	
	if (ducking)
		xs_vec_mul_scalar(direction, 0.25, direction)
	
	xs_vec_add(velocity, direction, direction)
	direction[2] = velocity[2]
	
	set_pev(victim, pev_velocity, direction)
	return HAM_IGNORED;
}

public task_KoniecZacmienia() {
	set_lights("#OFF");
}

public task_Duszek(id) {
	id -= TASK_DUSZEK;
	
	if(is_user_alive(id)) {
		set_user_noclip(id, 0);
	}
}


public task_KoniecKamuflaza(id) {
	id -= TASK_KAMUFLAZ;
	
	if(is_user_alive(id)) {
		set_user_rendering(id);
	}
}

public task_Chodzenie(iTaskId)
{
	new id = iTaskId - TASK_NACPANIE1;
	
	if(!is_user_connected(id)) {
		remove_task(iTaskId);
		remove_task(id + TASK_NACPANIE2);
		
		return PLUGIN_CONTINUE;
	}
	
	new Float:fAngles[3];
	
	static const szKomenda[][] =  { "+moveleft","+moveright" };
	
	client_cmd(id, "-moveleft; -moveright");
	client_cmd(id, szKomenda[random(2)]);
	
	fAngles[0] = random_float(-180.0, 180.0);
	fAngles[1] = random_float(-180.0, 180.0);
	
	set_pev(id, pev_punchangle, fAngles);
	
	return PLUGIN_CONTINUE
}

public task_KoniecNacpania(iTaskId)
{
	new id = iTaskId - TASK_NACPANIE2;
	
	if(is_user_connected(id))
	{
		message_begin(MSG_ONE, g_iMsgFov, {0,0,0}, id);
		write_byte(90); 
		message_end();
		
		remove_task(id + TASK_NACPANIE1);
		
		client_cmd(id, "-moveleft; -moveright");
	}
}

public task_OdliczanieEksplozja(iTaskId) {
	new id = iTaskId - TASK_BOMBA;
	
	if(!is_user_connected(id)) {
		remove_task(iTaskId);
		
		return PLUGIN_CONTINUE;
	}
	
	new iCzas = --g_iCzasBomby[id];
	
	if(iCzas <= 0) {
		new iOrigin[3];
		
		get_user_origin(id, iOrigin);
		
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY, iOrigin);
		write_byte(TE_EXPLOSION);
		write_coord(iOrigin[0]);
		write_coord(iOrigin[1]);
		write_coord(iOrigin[2]);
		write_short(g_iSpriteBlast);
		write_byte(32); 
		write_byte(20); 
		write_byte(0);
		message_end();
		
		user_kill(id);
		
		remove_task(iTaskId);
		return PLUGIN_CONTINUE;
	}
	
	new szDzwiek[64];
	
	copy(szDzwiek, 63, "JailBreak_Izolatka/odliczanie.wav");
	emit_sound(id, CHAN_BODY, szDzwiek, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	
	return PLUGIN_CONTINUE;
}

public task_ZatrucieZeSmoke(iEnt) {
	if(!is_valid_ent(iEnt)) {
		remove_task(iEnt);
		return PLUGIN_CONTINUE;
	}
	
	new id = entity_get_int(iEnt, EV_ENT_owner);
	
	if(!is_user_connected(id)) {
		remove_task(iEnt);
		return PLUGIN_CONTINUE;
	}
	
	new iEntList[32], iTarget, iTeam = get_user_team(id), iDane[2];
	new iIlosc = find_sphere_class(iEnt, "player", 150.0, iEntList, 31);
	
	for(new i = 0; i < iIlosc; i++) {
		iTarget = iEntList[i];
		
		if(!is_user_alive(iTarget) || iTeam == get_user_team(iTarget) || get_user_godmode(iTarget)) {
			continue;
		}
		
		g_iIloscTrutek[iTarget] = 12;
		
		if(!task_exists(iTarget)) {
			iDane[0] = id;
			iDane[1] = iTarget;
			
			set_task(0.8, "task_ZatrucieGracza", TASK_ZATRUCIE + iTarget, iDane, 2, "b");
			client_cmd(iTarget, "spk scientist/cough.wav");
		}
	}
	
	return PLUGIN_CONTINUE;
}

public task_ZatrucieGracza(iDane[2], iTaskId) {
	new iAtt = iDane[0], id = iDane[1];
	
	if(!is_user_connected(iAtt) || !is_user_alive(id) || !g_iIloscTrutek[id] || get_user_godmode(id)) {
		remove_task(id);
		return PLUGIN_CONTINUE;
	}
	
	ExecuteHamB(Ham_TakeDamage, id, iAtt, iAtt, random_float(1.0, 6.0), (1<<16));
	g_iIloscTrutek[id] --;
	return PLUGIN_CONTINUE;
}

public task_OdmrozGracza(iTaskId)
{
	new id = iTaskId - TASK_ZAMROZENIE;
	
	if(!is_user_connected(id))
		return PLUGIN_CONTINUE;
	
	new iBronie[32], iIlosc;
	get_user_weapons(id, iBronie, iIlosc);
	for(new j = 0; j < iIlosc; j++)
		set_pdata_float(fm_get_user_weapon_entity(id, iBronie[j]), 46, 0.0, 4);
	
	set_user_rendering(id);
	jail_set_user_speed(id, 250.0);
	set_pev(id, pev_gravity, 1.0);
	
	show_icon(id, 0, "dmg_cold");
	emit_sound(id, CHAN_ITEM, "weapons/debris3.wav", VOL_NORM, ATTN_NORM, 0, PITCH_LOW);
	client_print(id, print_center, "Zostales odmrozony!");
	
	return PLUGIN_HANDLED;
}

public task_Slapuj(iTaskId) {
	new id = iTaskId - TASK_SLAPOWANIE;
	
	if(is_user_alive(id)) {
		user_slap(id, 1, 1);
	}
}

public task_KoniecAutoBH(iTaskId) {
	new id = iTaskId - TASK_AUTOBH;
	if(is_user_alive(id)) {
		g_bAutoBH[id] = false;
	}
}

public ev_CurWeapon(id) {
	if(!is_user_alive(id)) {
		return PLUGIN_CONTINUE;
	}

	if(g_bBezlikAmmo[id]) {
		set_user_clip(id, 70);
	}
	
	return PLUGIN_CONTINUE;
}

public ev_ResetHUD(id) {
	set_user_gravity(id, 1.0);
	set_user_footsteps(id, 0);
	set_user_health(id, 100);
	
	OnLastPrisonerTakeWish(id, 0);
}

public OnLastPrisonerTakeWish(id, iZyczenie) {
	for(new i = 1; i <= g_iIloscSlotow; i++) {
		if(!is_user_alive(i)) {
			continue;
		}

		set_user_noclip(i, 0);
		set_user_rendering(i, kRenderFxNone, 0, 0, 0, kRenderTransAlpha, 255);
		client_cmd(i, "-moveleft; -moveright");
		
		g_iDodatkoweSkoki[i] = 0;
		g_bAutoBH[i] = false;
		g_bWscieklePiesciWeza[i] = false;
		g_bRekawiceZlodzieja[i] = false
		g_fBetonoweCialo[i] = 0.0;	
		g_bBezlikAmmo[i] = false;
		g_bNoRecoil[i] = false;
		g_fBonusoweObrazenia[i] = 0.0;
		g_fNiesmiertelnosc[i] = 0.0;
		g_iSzansaNaZatrucie[i] = 0;
		g_bNabojeOdpychajace[i] = false;
		
		remove_task(i + TASK_ZATRUCIE);
		remove_task(i + TASK_DUSZEK);	
		remove_task(i + TASK_NACPANIE1);
		remove_task(i + TASK_NACPANIE2);
		remove_task(i + TASK_BOMBA);
		remove_task(i + TASK_SLAPOWANIE);
		remove_task(i + TASK_ZAMROZENIE);
		remove_task(i + TASK_KAMUFLAZ);
		remove_task(i + TASK_AUTOBH);
	}
}

public ev_NowaRunda() {
	fm_remove_entity_name("iceblock");
}

public OnDayStartPost(iDzien) {
	if(!(1 <= iDzien <= 5)) {
		for(new i = 1; i <= g_iIloscSlotow; i++) {
			if(is_user_alive(i)) {
				OnLastPrisonerTakeWish(i, 0);
			}
		}
	}
}

stock PokazNagrodeHud(id, jakaNagroda[], ...) {
	new szMsg[512], szNick[32];
	get_user_name(id, szNick, 31);	
	vformat(szMsg, 511, jakaNagroda, 3);
	set_hudmessage(0, 130, 255, 0.02, 0.35, 2, 0.02, 5.0, 0.01, 0.1, 1);
	show_hudmessage(0, "[Ruletka] %s %s!", szNick, szMsg);
}

stock PokazNagrode(id, jakaNagroda[], ...) {
	new szMsg[512];
	vformat(szMsg, 511, jakaNagroda, 3);
	PokazWiadomosc(id, "Wylosowales(-as)^3 %s.", szMsg);
}

stock set_bartime(id, iTime, startprogress = 0){
	static barTime2;
	
	if(!barTime2)	barTime2	=	get_user_msgid("BarTime2");
	
	message_begin( id ? MSG_ONE : MSG_ALL, barTime2, _, id)
	write_short( iTime );
	write_short( startprogress );
	message_end(); 
	
}


stock czyDuzoMiejsca(const Float:vfPunkt[3], Float:odleglosc, const id=0) //ulepsz to chlopaku
{
	//new Float:vfPunkt[3]; pev(id, pev_origin, vfPunkt);
	new Float:vfStart[3], Float:vfEnd[3], Float:odleglosc_skosna = odleglosc / floatsqroot(2.0);
	
	vfStart[0] = vfEnd[0] = vfPunkt[0];
	vfStart[1] = vfEnd[1] = vfPunkt[1];
	vfStart[2] = vfEnd[2] = vfPunkt[2];
	
	//pion
	vfStart[0] += odleglosc;
	vfEnd[0] -= odleglosc;
	
	if(is_wall_between_points(vfStart, vfEnd, id))
		return 0;
	
	//poziom
	vfStart[0] -= odleglosc;
	vfEnd[0] += odleglosc;
	vfStart[1] += odleglosc;
	vfEnd[1] -= odleglosc;
	
	if(is_wall_between_points(vfStart, vfEnd, id))
		return 0;
		
	//skos 1
	vfStart[1] -= odleglosc;
	vfEnd[1] += odleglosc;
	vfStart[0] += odleglosc_skosna;
	vfStart[1] += odleglosc_skosna;
	vfEnd[0] -= odleglosc_skosna;
	vfEnd[1] -= odleglosc_skosna;
		
	if(is_wall_between_points(vfStart, vfEnd, id))
		return 0;
	
	//skos 2
	vfStart[0] -= odleglosc_skosna * 2.0;
	vfEnd[0] += odleglosc_skosna * 2.0;
	
	if(is_wall_between_points(vfStart, vfEnd, id))
		return 0;
		
	return 1;
}

stock is_wall_between_points(Float:start[3], Float:end[3], ignore_ent)
{
	//new ptr = create_tr2()
 
	engfunc(EngFunc_TraceLine, start, end, IGNORE_GLASS, ignore_ent, 0)
 
	new Float:fraction
	get_tr2(0, TR_flFraction, fraction)
	//free_tr2(ptr)
 
	if(fraction != 1.0)
		return 1;
	return 0;
}

stock show_icon(id, status, const name[] = "", r=0, g=255, b=0)
{
	static msgStatusIcon;
	
	if( !msgStatusIcon ) msgStatusIcon = get_user_msgid("StatusIcon")
	
	message_begin(id ? MSG_ONE : MSG_ALL,msgStatusIcon,_,id);
	write_byte(status); // status (0=hide, 1=show, 2=flash)
	write_string(name); // sprite name ""dmg_cold"
	write_byte(r); // red
	write_byte(g); // green
	write_byte(b); // blue
	message_end();
}

stock Display_Fade(id,duration,holdtime,fadetype,red,green,blue,alpha)
{
	static msgScreenFade;
	
	if( !msgScreenFade ) msgScreenFade = get_user_msgid("ScreenFade")
	
	message_begin( !id ? MSG_ALL : MSG_ONE, msgScreenFade,{0,0,0},id );
	write_short( duration );  // Duration of fadeout
	write_short( holdtime );  // Hold time of color
	write_short( fadetype );    // Fade type
	write_byte ( red );         // Red
	write_byte ( green );       // Green
	write_byte ( blue );        // Blue
	write_byte ( alpha );       // Alpha
	message_end();
}

stock set_user_clip(id, ammo)
{
	new weaponname[32], weaponid = -1, weapon = get_user_weapon(id, _, _);
	get_weaponname(weapon, weaponname, 31);
	while ((weaponid = engfunc(EngFunc_FindEntityByString, weaponid, "classname", weaponname)) != 0)
		if (pev(weaponid, pev_owner) == id) {
		set_pdata_int(weaponid, 51, ammo, 4);
		return weaponid;
	}
	return 0;
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1045\\ f0\\ fs16 \n\\ par }
*/
