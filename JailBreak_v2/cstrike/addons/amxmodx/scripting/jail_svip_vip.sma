#include <amxmodx>
#include <engine>
#include <cstrike>
#include <amxmisc>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <jailbreak>

#define FLAGA_VIP ADMIN_LEVEL_H
#define FLAGA_SVIP ADMIN_LEVEL_G

#define ABH_CZAS

#if defined ABH_CZAS
	#define TASK_BH 1327
	new bool:autobh[2][33];
#endif

public plugin_init() 
{
	register_plugin("JB: VIP & SVIP", "1.0", "donaciak.pl");
	
	register_message(get_user_msgid("SayText"),"handleSayText");
	register_message(get_user_msgid("ScoreAttrib"), "msg_ScoreAttrib");
	
	register_clcmd("say /vip", "cmd_OpisVIP");
	register_clcmd("say /svip", "cmd_OpisSVIP");
	#if defined ABH_CZAS
	register_clcmd("say /bh", "cmd_abh");
	register_event("ResetHUD", "ev_ResetHUD", "b");	
	#endif	
	
	register_clcmd("say /vips", "MenuListaVips");
	register_clcmd("say /svips", "MenuListaVips")
	register_clcmd("say /vipy", "MenuListaVips")

	RegisterHam(Ham_Spawn, "player", "fw_Odrodzenie_Post", 1);
	
	RegisterHam(Ham_TakeDamage, "player", "fw_Obrazenia");
	
	register_forward(FM_CmdStart, "fw_CmdStart");
	//register_forward(FM_PlayerPreThink, "fw_PreThink");
}

public plugin_natives() {
	register_native("jail_opis_vip", "cmd_OpisVIP", 1);
	register_native("jail_opis_svip", "cmd_OpisSVIP", 1);
}

public client_putinserver(id) {
	if(is_user_connected(id) && get_user_vip(id) == 2) {
		new szNick[32]; get_user_name(id, szNick, 31);
		set_hudmessage(24, 190, 220, 0.25, 0.2, 2, 6.0, 5.0, 0.1, 1.5); 
		show_hudmessage(0, "SVIP %s wbil na serwer!", szNick);
	}
}
#if defined ABH_CZAS
public ev_ResetHUD(id) autobh[1][id] = false;
#endif

public cmd_OpisVIP(id){
	show_motd(id, "addons/amxmodx/configs/opisy/vip.txt", "VIP"); 
	return PLUGIN_HANDLED;
}

public cmd_OpisSVIP(id){
	show_motd(id, "addons/amxmodx/configs/opisy/svip.txt", "SVIP"); 
	return PLUGIN_HANDLED;
}
		
public MenuListaVips(id)
{
	new menu = menu_create(fmt("\d%s | Menu^n\r[MENU]\w Lista VIP & SVIP:", forum), "Lista_Handler"), szName[32], szId[4];
	
	for(new i = 1; i <= get_maxplayers(); i++)
	{	
		if(!is_user_connected(i) || is_user_hltv(i) || !get_user_vip(i)) {
			continue;
		}	
		
		get_user_name(i, szName, 31);
		num_to_str(i, szId, 3);
		
		menu_additem(menu, fmt("\w%s %s", szName, get_user_vip(i)==2 ? "SVIP" : "VIP"), szId);
	}
	
	menu_setprop(menu, MPROP_BACKNAME, "\d×\w Wroc");
	menu_setprop(menu, MPROP_NEXTNAME, "\d×\w Dalej");
	menu_setprop(menu, MPROP_EXITNAME, "\d×\w Wyjdz");	
	menu_display(id,menu);
	return PLUGIN_HANDLED;
}
public Lista_Handler(id, menu, item)
{
	if(item==MENU_EXIT)
	{
		menu_destroy(menu)
		return;
	}
	menu_display(id, menu)
}
#if defined ABH_CZAS
public cmd_abh(id)
{
	if(!is_user_alive(id) || !(get_user_flags(id) & FLAGA_SVIP) || autobh[0][id] || autobh[1][id]) {
		PokazWiadomosc(id, "Nie mozesz skorzystac z abh poniewaz^3 %s", !is_user_alive(id) ? "nie zyjesz" : !(get_user_flags(id) & FLAGA_SVIP) ? "nie masz dostepu" : autobh[0][id] ? "uzyles juz" : "skonczyl sie"); 
		return PLUGIN_HANDLED;
	}
	new iCzas = (15);
	set_time(id, iCzas);
	set_task(float(iCzas), "task_KoniecBh", id + TASK_BH);
	autobh[1][id] = true; 
	autobh[0][id] = true;
	PokazWiadomosc(id, "Aktywowales AutoBH na^4 %i^1 sekund.", iCzas);
	return PLUGIN_HANDLED;
}
#endif
#if defined ABH_CZAS
public task_KoniecBh(id) {

	id -= TASK_BH;
	
	if(is_user_connected(id)) {
		autobh[0][id] = false;
		PokazWiadomosc(id, "Koniec^4 AutoBH!");
	}
}
#endif

public handleSayText(msgId,msgDest,msgEnt){	
	new id = get_msg_arg_int(1);
	
	if(!is_user_connected(id))      return PLUGIN_CONTINUE;
	
	new szTmp[192], szTmp2[192];
	get_msg_arg_string(2, szTmp, charsmax(szTmp));
	
	new iVip = get_user_vip(id), szPrefix[32];
	
	switch(iVip)
	{
		case 1: copy(szPrefix, 31, "^x04[VIP]");
		case 2: copy(szPrefix, 31, "^x04[SVIP]");
		default: return PLUGIN_CONTINUE;
	}
	
	if(!equal(szTmp,"#Cstrike_Chat_All")){
		add(szTmp2, charsmax(szTmp2), "^x01");
		add(szTmp2, charsmax(szTmp2), szPrefix);
		add(szTmp2, charsmax(szTmp2), " ");
		add(szTmp2, charsmax(szTmp2), szTmp);
	}
	else{
		new szPlayerName[64];
		get_user_name(id, szPlayerName, charsmax(szPlayerName));
		
		get_msg_arg_string(4, szTmp, charsmax(szTmp));
		set_msg_arg_string(4, "");
		
		add(szTmp2, charsmax(szTmp2), "^x01");
		add(szTmp2, charsmax(szTmp2), szPrefix);
		add(szTmp2, charsmax(szTmp2), "^x03 ");
		add(szTmp2, charsmax(szTmp2), szPlayerName);
		add(szTmp2, charsmax(szTmp2), "^x01 :  ");
		add(szTmp2, charsmax(szTmp2), szTmp)
	}
	
	set_msg_arg_string(2, szTmp2);
	
	return PLUGIN_CONTINUE;
}

public msg_ScoreAttrib(){
	new id=get_msg_arg_int(1);
	if(is_user_alive(id) && get_user_vip(id)){
		set_msg_arg_int(2, ARG_BYTE, get_msg_arg_int(2)|4);
	}
}

public fw_Odrodzenie_Post(id)
{
	if(!is_user_alive(id))
		return;
	
	new iVip = get_user_vip(id); 
	
	if(!iVip)
		return;
	
	switch(get_user_team(id))
	{
		case 1: {
			fm_set_user_health(id, (iVip == 1) ? 130 : 170);
			fm_set_user_armor(id, 100);
		}
		case 2: {
			fm_set_user_health(id, (iVip == 1) ? 180 : 200);
			fm_set_user_armor(id, 150);
		}
	}
}

public fw_Obrazenia(id, iEnt, iAtt, Float:fObr, iDmgBits)
{
	if(!is_user_connected(iAtt) || get_user_team(id) == get_user_team(iAtt))
		return HAM_IGNORED;
		
	switch(get_user_vip(iAtt))
	{
		case 1:
		{
			if(get_user_weapon(iAtt) == CSW_KNIFE)
			{
				SetHamParamFloat(4, fObr * 1.4);
				return HAM_HANDLED;
			}	
		}
		case 2:
		{
			switch(get_user_weapon(iAtt))
			{
				case CSW_KNIFE:
				{
					SetHamParamFloat(4, fObr * 1.6);
					return HAM_HANDLED;
				}
				case CSW_AK47, CSW_DEAGLE, CSW_M4A1:
				{
					SetHamParamFloat(4, fObr * 1.3);
					return HAM_HANDLED;
				}
			}
		}
	}
	
	return HAM_IGNORED;
}

public fw_CmdStart(id, iUc)
{
	if(!is_user_alive(id))
		return FMRES_IGNORED;
	
	static iSkoki[33];
	new iFlags = pev(id, pev_flags);

	if((get_uc(iUc, UC_Buttons) & IN_JUMP) && !(iFlags & FL_ONGROUND) && !(pev(id, pev_oldbuttons) & IN_JUMP) && iSkoki[id])
	{
		iSkoki[id]--;

		new Float:fVelocity[3];
		pev(id, pev_velocity, fVelocity);
		fVelocity[2] = random_float(265.0,285.0);

		set_pev(id, pev_velocity, fVelocity);
	}
	else if(iFlags & FL_ONGROUND)
	{
		switch(get_user_vip(id))
		{	
			case 1: iSkoki[id] = 1;
			case 2: iSkoki[id] = 2;
		}
	}
	
	return FMRES_IGNORED;
}

public fw_PreThink(id)
{
	if (is_user_alive(id) && get_user_vip(id) == 2 && pev(id, pev_button) & IN_JUMP) 
	{
		new flags = pev(id, pev_flags)
		
		if (flags & FL_WATERJUMP)
			return FMRES_IGNORED;
		if ( pev(id, pev_waterlevel) >= 2 )
			return FMRES_IGNORED;
		if ( !(flags & FL_ONGROUND) )
			return FMRES_IGNORED;
		
		new Float:velocity[3];
		pev(id, pev_velocity, velocity);
		velocity[2] = velocity[2]+250.0<600.0?velocity[2]+250.0:600.0
		set_pev(id, pev_velocity, velocity);
		
		set_pev(id, pev_gaitsequence, 6);
	
	}
	return FMRES_IGNORED;
}
#if defined ABH_CZAS
public client_PreThink(id){
	if(autobh[0][id]) {
		entity_set_float(id, EV_FL_fuser2, 0.0);
	
		if(entity_get_int(id, EV_INT_button) & 2){
			new flags = entity_get_int(id, EV_INT_flags);
		
			if(flags & FL_WATERJUMP || entity_get_int(id, EV_INT_waterlevel) >= 2 || !(flags & FL_ONGROUND)){
				return PLUGIN_CONTINUE;
			}
			new Float:velocity[3];
			entity_get_vector(id, EV_VEC_velocity, velocity);
		
			velocity[2] += 250.0;
			entity_set_vector(id, EV_VEC_velocity, velocity);
			
			entity_set_int(id, EV_INT_gaitsequence, 6);
		}
	}
	return PLUGIN_CONTINUE;
}
#endif

stock get_user_vip(id)
{
	new iFlags = get_user_flags(id);
	
	if(iFlags & FLAGA_VIP)
		return 1;
	else if(iFlags & FLAGA_SVIP)
		return 2;
	
	return 0;
}

#if defined ABH_CZAS
stock set_time(id, iTime, startprogress = 0){
	static barTime2;
	
	if(!barTime2)	barTime2	=	get_user_msgid("BarTime2");
	
	message_begin( id ? MSG_ONE : MSG_ALL, barTime2, _, id)
	write_short( iTime );
	write_short( startprogress );
	message_end(); 
	
}
#endif


