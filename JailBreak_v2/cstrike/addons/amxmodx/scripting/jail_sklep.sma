#include <amxmodx> 
#include <amxmisc> 
#include <cstrike>
#include <fun>
#include <fakemeta_util>
#include <hamsandwich>
#include <engine>
#include <fakemeta>
#include <jailbreak>

#define PLUGIN "Sklep JailBreak" 
#define VERSION "1.0" 
#define AUTHOR "Bodzio" 

native jail_set_szlugi(id, wartosc);
native jail_get_szlugi(id);

new bool:g_bBetonoweCialo[33];

public plugin_init() { 
	register_plugin(PLUGIN, VERSION, AUTHOR); 
	
	RegisterHam(Ham_TakeDamage, "player", "fw_Obrazenia", 1);
	register_event("ResetHUD", "ev_ResetHUD", "b");	
	
	register_clcmd("say /sklep", "sklep_jb");
	register_clcmd("say /szlugi", "sklep_jb");
} 
public sklep_jb(id)
{ 
	if(!is_user_alive(id)) {
		PokazWiadomosc(id, "Sklep jest dostepny tylko dla^3 zywych!");
		return PLUGIN_HANDLED;
	}
	
	if(!(1 <= jail_get_play_game_id() <= 5)) {
		PokazWiadomosc(id, "Sklep jest niedostepny podczas^3 zabaw!");
		return PLUGIN_HANDLED;
	}

	new menu = menu_create(fmt("\d%s | Menu^n\r[SKLEP]\w Sklep:", forum), "Handel_Sklep");
	
	menu_additem(menu,"\wGranat dymny \r[\y30\d szlugow\r]"); 
	menu_additem(menu,"\wGranat odlamkowy \r[\y150\d szlugow\r]"); 
	menu_additem(menu,"\wGranat oslepiajacy \r[\y40\d szlugow\r]"); 
	menu_additem(menu,"\wKevlar \r[\y80\d szlugow\r]"); 
	menu_additem(menu,"\wApteczka +20 HP \r[\y30\d szlugow\r]"); 
	menu_additem(menu,"\wBonus +100 HP \r[\y30\d szlugow\r]"); 
	menu_additem(menu,"\wButy astronauty \r[\y30\d szlugow\r]"); 
	menu_additem(menu,"\wMiekkie kapcie \r[\y40\d szlugow\r]"); 
	menu_additem(menu,"\wLapy krolika \r[\y90\d szlugow\r]");
	menu_additem(menu,"\wDeagle z 1 ammo \r[\y500\d szlugow\r]");
	menu_additem(menu,"\wScout z 1 ammo \r[\y600\d szlugow\r]");	
	menu_additem(menu,"\wAWP z 1 ammo \r[\y800\d szlugow\r]");
	menu_additem(menu,"\wBetonowe cialo \r[\y800\d szlugow\r]");
	menu_additem(menu,"\wRozpierdol cele \r[\y1200\d szlugow\r]");	
		
	menu_setprop(menu, MPROP_BACKNAME, "\d×\w Wroc");
	menu_setprop(menu, MPROP_NEXTNAME, "\d×\w Dalej");
	menu_setprop(menu, MPROP_EXITNAME, "\d×\w Wyjdz");
	menu_display(id, menu);
	return PLUGIN_HANDLED;
}
public Handel_Sklep(id, menu, item){ 
	if(item==MENU_EXIT) 
	{ 
		menu_destroy(menu) 
		return PLUGIN_HANDLED; 
	} 
	new iIloscSzlugow = jail_get_szlugi(id);
	
	switch(item) 
	{ 
		case 0:{
			if(iIloscSzlugow >= 30) { 
				if(pev(id, pev_weapons) & (1<<CSW_SMOKEGRENADE)) {
					PokazWiadomosc(id, "Nie mozesz miec wiecej granatow^4 dymnych!");	
				} else {	
					jail_set_szlugi(id, iIloscSzlugow - 30);
					give_item(id, "weapon_smokegrenade");
					PokazWiadomosc(id, "Kupiles granat^4 dymny!");
				}	
			} else {
				PokazWiadomosc(id, "Nie masz wystarczajaco^3 szlugow!"); 
			}	
		}
		case 1:{
			if(iIloscSzlugow >= 150) { 
				if(pev(id, pev_weapons) & (1<<CSW_HEGRENADE)) {
					PokazWiadomosc(id, "Nie mozesz miec wiecej granatow^4 odlamkowych!");	
				} else {	
					jail_set_szlugi(id, iIloscSzlugow - 150);
					give_item(id, "weapon_hegrenade");
					PokazWiadomosc(id, "Kupiles granat^4 odlamkowy!")
				}	
			} else {
				PokazWiadomosc(id, "Nie masz wystarczajaco^3 szlugow!"); 
			}	
		}
		case 2:{
			if(iIloscSzlugow >= 40) { 
				if(cs_get_user_bpammo(id, CSW_FLASHBANG) >= 2) {
					PokazWiadomosc(id, "Nie mozesz miec wiecej granatow^4 oslepiajacych!");	
				} else {	
					jail_set_szlugi(id, iIloscSzlugow - 40);
					give_item(id, "weapon_flashbang");
					PokazWiadomosc(id, "Kupiles granat^4 oslepiajacy!")
				}	
			} else {
				PokazWiadomosc(id, "Nie masz wystarczajaco^3 szlugow!"); 
			}	
		}
		case 3:{
			if(iIloscSzlugow >= 80) { 
				new CsArmorType:iTypKamizelki, iIloscAP = cs_get_user_armor(id, iTypKamizelki);
				if(iIloscAP >= 100) {
					PokazWiadomosc(id, "Posiadasz juz^4 kevlar!");
				} else {
					if(iTypKamizelki == CS_ARMOR_NONE) {
						iTypKamizelki = CS_ARMOR_KEVLAR;
					}	
					jail_set_szlugi(id, iIloscSzlugow - 80);
					cs_set_user_armor(id, 100, iTypKamizelki);					
					PokazWiadomosc(id, "Kupiles^4 kevlar!")	
				}			
			} else {
				PokazWiadomosc(id, "Nie masz wystarczajaco^3 szlugow!"); 
			}	
		}
		case 4:{
			if(iIloscSzlugow >= 30) { 	
				jail_set_szlugi(id, iIloscSzlugow - 30);
				set_user_health(id, get_user_health(id) + 20);
				PokazWiadomosc(id, "Kupiles^4 apteczke +20 HP!")	
			} else {
				PokazWiadomosc(id, "Nie masz wystarczajaco^3 szlugow!"); 
			}	
		}
		case 5:{
			if(iIloscSzlugow >= 30) { 	
				jail_set_szlugi(id, iIloscSzlugow - 30);
				set_user_health(id, get_user_health(id) + 100);
				PokazWiadomosc(id, "Kupiles^4 bonus +100 HP!")	
			} else {
				PokazWiadomosc(id, "Nie masz wystarczajaco^3 szlugow!"); 
			}	
		}
		case 6:{
			if(iIloscSzlugow >= 30) { 	
				jail_set_szlugi(id, iIloscSzlugow - 30);
				set_user_gravity(id, 0.4);
				PokazWiadomosc(id, "Kupiles^4 buty astronauty!")	
			} else {
				PokazWiadomosc(id, "Nie masz wystarczajaco^3 szlugow!"); 
			}	
		}
		case 7:{
			if(iIloscSzlugow >= 40) { 	
				jail_set_szlugi(id, iIloscSzlugow - 40);
				set_user_footsteps(id, 1);
				PokazWiadomosc(id, "Kupiles^4 miekkie kapcie!")	
			} else {
				PokazWiadomosc(id, "Nie masz wystarczajaco^3 szlugow!"); 
			}	
		}
		case 8:{
			if(iIloscSzlugow >= 90) { 	
				jail_set_szlugi(id, iIloscSzlugow - 90);
				set_user_gravity(id, 0.2);
				PokazWiadomosc(id, "Kupiles^4 lapy krolika!")	
			} else {
				PokazWiadomosc(id, "Nie masz wystarczajaco^3 szlugow!"); 
			}	
		}
		case 9:{
			if(iIloscSzlugow >= 500) { 
				if(has_weapon_on_slot(id, 2)) {
					PokazWiadomosc(id, "Posiadasz juz^4 Deagle'a!^1 Pozbadz sie go, aby kupic kolejny.");
				} else {
					new iEnt = give_item(id, "weapon_deagle");
					
					if(iEnt > 0) {
						cs_set_weapon_ammo(iEnt, 1);
					}			
					jail_set_szlugi(id, iIloscSzlugow - 500);
					PokazWiadomosc(id, "Kupiles^4 deagl'a z 1 ammo!")	
				}
			} else {
				PokazWiadomosc(id, "Nie masz wystarczajaco^3 szlugow!"); 
			}
		}	
		case 10:{
			if(iIloscSzlugow >= 600) { 
				if(has_weapon_on_slot(id, 1)) {
					PokazWiadomosc(id, "Posiadasz juz^4 Scouta!^1 Pozbadz sie go, aby kupic kolejny.");
				} else {
					new iEnt = give_item(id, "weapon_scout");
					
					if(iEnt > 0) {
						cs_set_weapon_ammo(iEnt, 1);
					}			
					jail_set_szlugi(id, iIloscSzlugow - 600);
					PokazWiadomosc(id, "Kupiles^4 scouta z 1 ammo!")	
				}
			} else {
				PokazWiadomosc(id, "Nie masz wystarczajaco^3 szlugow!"); 
			}
		}
		case 11:{
			if(iIloscSzlugow >= 800) { 
				if(has_weapon_on_slot(id, 1)) {
					PokazWiadomosc(id, "Posiadasz juz^4 AWP!^1 Pozbadz sie jej, aby kupic kolejny.");
				} else {
					new iEnt = give_item(id, "weapon_awp");
					
					if(iEnt > 0) {
						cs_set_weapon_ammo(iEnt, 1);
					}			
					jail_set_szlugi(id, iIloscSzlugow - 800);
					PokazWiadomosc(id, "Kupiles^4 awp z 1 ammo!")
				}
			} else {
				PokazWiadomosc(id, "Nie masz wystarczajaco^3 szlugow!"); 
			}
		}	
		case 12:{
			if(iIloscSzlugow >= 800) { 			
				jail_set_szlugi(id, iIloscSzlugow - 800);
				g_bBetonoweCialo[id] = true;
				PokazWiadomosc(id, "Kupiles^4 betonowe cialo!")	
			} else {
				PokazWiadomosc(id, "Nie masz wystarczajaco^3 szlugow!"); 
			}	
		}
		case 13:{
			if(iIloscSzlugow >= 1200) { 			
				jail_set_szlugi(id, iIloscSzlugow - 1200);
				jail_open_cele();
				PokazWiadomosc(id, "Rozpierdoliles^4 cele!")	
			} else {
				PokazWiadomosc(id, "Nie masz wystarczajaco^3 szlugow!"); 
			}	
		}		
	}	
	menu_destroy(menu);
	sklep_jb(id);
	return PLUGIN_HANDLED; 
}

public fw_Obrazenia(id, iEnt, iAtt, Float:fDmg, iDmgBits) {
	if(!is_user_connected(iAtt)) {
		return HAM_IGNORED;
	}
	
	if(iDmgBits & (1<<1)) {
		if(g_bBetonoweCialo[id]) {
			return HAM_SUPERCEDE;
		}
	}
	return HAM_IGNORED;
}

public client_authorized(id) {
	ev_ResetHUD(id);
}

public OnLastPrisonerTakeWish(id, iZyczenie) {
	ev_ResetHUD(id);
}

public ev_ResetHUD(id) {
	g_bBetonoweCialo[id] = false;
}

stock bool:has_weapon_on_slot(id, iSlot) {
	if ( !( 1 <= iSlot <= 5 ) )
		return false;
	
	const m_rgpPlayerItems_Slot0 = 367;
	const XO_PLAYER = 5;
		
	return ( get_pdata_cbase( id , m_rgpPlayerItems_Slot0 + iSlot , XO_PLAYER ) > 0 );
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1045\\ f0\\ fs16 \n\\ par }
*/
