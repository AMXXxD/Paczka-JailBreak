#include <amxmodx>
#include <hamsandwich>
#include <jailbreak>

public plugin_init() {
	register_plugin("JB:Ozywianie", "1.0", "Bodzio");
	register_clcmd("say /ozyw", "cmd_Ozyw");
}

public plugin_natives() {
	register_native("jail_menuozyw", "cmd_Ozyw", 1);
}

public cmd_Ozyw(id) 
{
	new bool:bCzyAdmin = bool:(get_user_flags(id) & FLAGA_ADM);
	if(jail_get_prowadzacy() != id && !bCzyAdmin)  {
		PokazWiadomosc(id, "Ta opcja jest dostepna tylko dla prowadzacego^3 straznika!");
		return PLUGIN_HANDLED;
	}
	
	new iMenu = menu_create(fmt("\d%s | Menu^n\r[OZYW]\w Menu Ozywiania:", forum), "OzywWieznia_Handler"), szNick[32], szId[4], iTeam;
	
	for(new i = 1; i <= MAX; i++) {
		if(!is_user_connected(i) || is_user_alive(i)) continue;
		
		iTeam = get_user_team(i);
		if(iTeam == 1 || (bCzyAdmin && 1 <= iTeam <= 2)) {
			get_user_name(i, szNick, 31);
			num_to_str(i, szId, 3);
			menu_additem(iMenu, fmt("%s", szNick), szId);
		}
	}	
	
	menu_setprop(iMenu, MPROP_BACKNAME, "\d×\w Wroc");
	menu_setprop(iMenu, MPROP_NEXTNAME, "\d×\w Dalej");
	menu_setprop(iMenu, MPROP_EXITNAME, "\d×\w Wyjdz");	
	menu_display(id, iMenu);
	return PLUGIN_HANDLED;
}

public OzywWieznia_Handler(id, iMenu, iItem)
{
	if(iItem < 0) {
		if(iItem == MENU_EXIT || jail_get_prowadzacy() != id && !(get_user_flags(id) & FLAGA_ADM)) {
			menu_destroy(iMenu);
		}
		return PLUGIN_CONTINUE;
	}
	
	new iAccess, iCb, szId[4], iTarget;
	menu_item_getinfo(iMenu, iItem, iAccess, szId, 3, _, _, iCb);
	iTarget = str_to_num(szId);
	
	if(!is_user_connected(iTarget) || is_user_alive(iTarget)) {
		PokazWiadomosc(id, "Nie znaleziono gracza, mozliwe ze zostal juz^3 ozywiony.");
	} else {
		new szNick[2][32]; 
		
		get_user_name(id, szNick[0], 31);
		get_user_name(iTarget, szNick[1], 31);
		
		ExecuteHamB(Ham_CS_RoundRespawn, iTarget);
		PokazWiadomosc(0, "Gracz^3 %s^1 zostal ozywiony przez^3 %s", szNick[1], szNick[0]);
	}
	menu_destroy(iMenu);
	cmd_Ozyw(id);
	return PLUGIN_CONTINUE;
}
