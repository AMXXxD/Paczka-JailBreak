#include <amxmodx>
#include <amxmisc>
#include <nvault>
#include <cstrike>
#include <jailbreak>

#define PLUGIN "Jail CzasGry"
#define VERSION "1.0.6"
#define AUTHOR "Cypis"

new valut;
new pCvarSteam, pCvarTiem, pCvarCtToTT;
new CzasGry[MAX+1];
new dane_gracza[MAX+1];
new nazwa_gracza[MAX+1][64];
new bool:wczytane[MAX+1];

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_clcmd("jail_menuban", "MenuBan");
	register_clcmd("say /czasgry", "PokazCzasGry");
	
	pCvarTiem = register_cvar("jail_ct_time", "60");
	pCvarCtToTT = register_cvar("jail_tt_to_ct", "5");
	pCvarSteam = register_cvar("jail_ct_steam", "0");
	
	pCvarCtToTT = max(get_pcvar_num(pCvarCtToTT), 1);
	pCvarTiem = get_pcvar_num(pCvarTiem)*60;
	pCvarSteam = get_pcvar_num(pCvarSteam);
	
	valut = nvault_open("JB_BanCT");
}

public client_authorized(id)
{
	get_user_name(id, nazwa_gracza[id], 63);
}

public client_infochanged(id) 
{
	get_user_info(id, "name", nazwa_gracza[id], 63);
}

public OnJoinTeam(id, team, tt, ct)
{
	if(team == 2)
	{
		if(!is_user_steam(id) && pCvarSteam)
		{
			PokazWiadomosc(id, "NonSteam nie moze grac w CT!");
			return JAIL_FORCE_TT;
		}
			
		if((ct && (ct*pCvarCtToTT >= tt)) && !(get_user_flags(id) & FLAGA_ADM))
		{
			PokazWiadomosc(id, "Druzyna CT pelna! Dolaczyles do wiezniow!");
			return JAIL_FORCE_TT;
		}
		
		if(dane_gracza[id] == 2)
		{
			PokazWiadomosc(id, "Masz zakaz dolaczania do CT!");
			return JAIL_FORCE_TT;
		}
	
		if(!dane_gracza[id] && ((get_user_time(id,1)+CzasGry[id]) < pCvarTiem) && !(get_user_flags(id) & FLAGA_ADM))
		{
			PokazWiadomosc(id, "Masz za malo czasu przegrane na serwerze by grac w CT! Potrzebujesz %d minut.", pCvarTiem/60);
			return JAIL_FORCE_TT;
		}
	}
	return JAIL_CONTINUE;
}

public MenuBan(id)
{
	if(!(get_user_flags(id) & FLAGA_ADM)){
		PokazWiadomosc(id, "Nie masz^3 dostepu!");
	}
	
	new menu = menu_create(fmt("\d%s | Menu^n\r[BAN]\w Menu ban na CT:", forum), "Ban_Handled"), szId[4], szNick[32];
	
	for(new i = 1; i <= MAX; i++) {
		if(!is_user_connected(i) || is_user_hltv(i)) {
			continue;
		}
		
		num_to_str(i, szId, 3);
		get_user_name(id, szNick, 31);
		menu_additem(menu, fmt("%s %s", nazwa_gracza[i], (dane_gracza[i] != 2) ? "" : "\rZbanowany"), szId);
	}
	
	menu_setprop(menu, MPROP_BACKNAME, "\d×\w Wroc");
	menu_setprop(menu, MPROP_NEXTNAME, "\d×\w Dalej");
	menu_setprop(menu, MPROP_EXITNAME, "\d×\w Wyjdz");
	menu_display(id, menu);
	return PLUGIN_HANDLED;
}

public Ban_Handled(id, menu, item)
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
	
	if(dane_gracza[id2] != 2)
	{
		CzasGry[id2] = 0;
		dane_gracza[id2] = 2;
		nvault_set(valut, nazwa_gracza[id2], "2");
		
		if(cs_get_user_team(id2) == CS_TEAM_CT)
		{
			if(is_user_alive(id2))
				user_kill(id2);
			cs_set_user_team(id2, CS_TEAM_T);
		}	
		log_amx("Admin <%s> zbanowal gracza <%s>", nazwa_gracza[id], nazwa_gracza[id2]); 
		PokazWiadomosc(id, "Gracz ^3%s^1 zostal zbanowany na gre w CT", nazwa_gracza[id2]);
	}else{
		log_amx("Admin <%s> odbanowal gracza <%s>", nazwa_gracza[id], nazwa_gracza[id2]);
		PokazWiadomosc(id, "Gracz ^3%s^1 zostal odbanowany na CT! ", nazwa_gracza[id2]);		
		nvault_set(valut, nazwa_gracza[id2], "1");
	}
	return PLUGIN_CONTINUE;
}

public client_putinserver(id)
{
	dane_gracza[id] = 0;
	CzasGry[id] = 0;
	wczytane[id] = false;
	if(pCvarSteam)
	{
		if(is_user_steam(id))
		{
			get_user_authid(id, nazwa_gracza[id], 63);
			CzasGry[id] = WczytajCzas(id);
		}
		return;
	}
	if(is_user_steam(id))
		get_user_authid(id, nazwa_gracza[id], 63);
	else
		get_user_name(id, nazwa_gracza[id], 63);
			
	CzasGry[id] = WczytajCzas(id);
}

public WczytajCzas(id)
{
	new vaultdata[256];
	wczytane[id] = true;
	
	if(nvault_get(valut, nazwa_gracza[id], vaultdata, 255))
	{
		if(vaultdata[1] == '#')
		{
			new left[10];
			strtok(vaultdata, left, 9, vaultdata, 255, '#', 1);
			return str_to_num(vaultdata);
		}
		else
			dane_gracza[id] = (vaultdata[0]-'0');
	}
	return 0;
}

public client_disconnected(id)
{
	if(pCvarSteam)
	{
		if(is_user_steam(id))
		{
			ZapiszCzas(id);
		}
		return;
	}
	ZapiszCzas(id);
}

public ZapiszCzas(id)
{
	if(!dane_gracza[id] && wczytane[id])
	{
		new czas = CzasGry[id]+get_user_time(id,1);
		if(czas <= pCvarTiem)
		{
			new vaultdata[256];
			formatex(vaultdata, 255, "0#%i", czas);
			nvault_set(valut, nazwa_gracza[id], vaultdata);
		}
		else
			nvault_set(valut, nazwa_gracza[id], "1");
	}
}

public PokazCzasGry(id)
{
	new times = get_user_time(id,1);
	if((times+CzasGry[id]) < pCvarTiem && !dane_gracza[id])
		PokazWiadomosc(id, "Spedziles na serwerze^3 %d^1 min.", (times+CzasGry[id])/60);
	else
		PokazWiadomosc(id, "Przegrales ponad %d minut na serwerze", pCvarTiem/60);
	return PLUGIN_HANDLED;
}    

stock bool:is_user_steam(id)
{
	new authid[32]; 
	get_user_authid(id, authid, 31);
	return contain(authid , ":") != -1? true: false;
}
