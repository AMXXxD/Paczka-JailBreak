#include <amxmodx>
#include <jailbreak>
#include <hamsandwich>
#include <sqlx>

new g_iZyczeniaGracza[33];
new g_iBuntyGracza[33];

new bool:g_bDaneWczytane[33];

new Handle:g_hSqlTuple;
new bool:g_bLiczBunty;

public plugin_init() 
{
	register_plugin("Jail: Ranking", "1.0", "donaciak.pl");
 
	RegisterHam(Ham_Killed, "player", "fw_Smierc_Post", 1);
	
	register_clcmd("say /top15", "cmd_Top15");
	register_clcmd("say /topg", "cmd_Top15");
	
	PrzygotujSQL();
}

public plugin_natives() {
	register_native("jail_menutopki", "cmd_Top15", 1);
	register_native("jail_get_user_bunty", "nat_PobierzBuntyGracza", 1);
	register_native("jail_get_user_zyczenia", "nat_PobierzZyczeniaGracza", 1);
}

public client_authorized(id) {
	g_iBuntyGracza[id] = 0;
	g_iZyczeniaGracza[id] = 0;
	g_bDaneWczytane[id] = false;
	
	WczytajDaneGracza(id);
}

public client_disconnected(id) {
	ZapiszDaneGracza(id);
}

public OnLastPrisonerTakeWish(id, iZyczenie) {
	g_bLiczBunty = false;
	g_iZyczeniaGracza[id] ++;
}

public OnDayStartPost(iDzien) {
	if(1 <= iDzien <= 5) {
		g_bLiczBunty = true;
	} else {
		g_bLiczBunty = false;
	}
}

public fw_Smierc_Post(id, iAtt, iShGb) {
	if(!is_user_connected(iAtt) || !g_bLiczBunty) {
		return HAM_IGNORED;
	}
	
	if(get_user_team(iAtt) == 1 && get_user_team(id) == 2) {
		g_iBuntyGracza[iAtt] ++;
	}
	
	return HAM_IGNORED;
}

public cmd_Top15(id) {
	new iMenu = menu_create(fmt("\d%s | Menu^n\r[TOPKA]\w Top 15:", forum), "Top15_Handler");
	
	menu_additem(iMenu, "Top 15 zyczen");
	menu_additem(iMenu, "Top 15 buntow");
	
	menu_setprop(iMenu, MPROP_EXITNAME, "\d×\w Wyjdz");
	menu_display(id, iMenu);
	return PLUGIN_HANDLED;
}

public Top15_Handler(id, iMenu, iItem) {
	switch(iItem) {
		case MENU_EXIT: {
			menu_destroy(iMenu);
			return PLUGIN_CONTINUE;
		}
		
		case 0: {
			Top15Zyczen(id);
		}
		case 1: {
			Top15Buntow(id);
		}
	}
	
	menu_display(id, iMenu);
	return PLUGIN_CONTINUE;
}

public Top15Zyczen(id) {
	new szPytanie[256], iDane[2];
	
	iDane[0] = id;
	iDane[1] = get_user_userid(id);
	formatex(szPytanie, 255, "SELECT nick, zyczenia FROM ranking ORDER BY zyczenia DESC LIMIT 15;");
	
	SQL_ThreadQuery(g_hSqlTuple, "Top15Zyczen_Handler", szPytanie, iDane, 2);
}

public Top15Zyczen_Handler(iFailState, Handle:hPytanie, szBlad, iKodBledu, iDane[], iDaneLen)
{
	new id = iDane[0];
	
	if(!is_user_connected(id) || get_user_userid(id) != iDane[1])
		return PLUGIN_CONTINUE;
		
	if(iKodBledu)
		log_amx("Blad: %s (Top15Zyczen_Handler).", szBlad);
	
	if(iFailState == TQUERY_CONNECT_FAILED)
	{
		log_amx("Nie mozna podlaczyc sie do bazy danych.");
		return PLUGIN_CONTINUE;
	}
	else if(iFailState == TQUERY_QUERY_FAILED)
	{
		log_amx("Zapytanie anulowane (Top15Zyczen_Handler).");
		return PLUGIN_CONTINUE;
	}
	
	new szNick[32], szMotd[1024], iLen, i;
	
	iLen = formatex(szMotd, 1023, "<head><style>table{border-collapse:collapse;background-color:#3D5450}td{border:0.2em solid #2F413E;text-align:center;height:1.2em;font-size: 0.8em}body{background-image:url(http://206.1s1k.pl/FD/srv40280/cstrike/models/zasady_jb/tlo.png);background-size:auto;color:#DADADA;}</style></head><body><br><br><center><table width=80%%><tr style=^"background-color:#2F413E;^"><td>#. Gracz<td>Zyczenia");
	
	if(SQL_NumRows(hPytanie)) {
		while(SQL_MoreResults(hPytanie)) {
			i ++;
			SQL_ReadResult(hPytanie, 0, szNick, 31);
			replace_all(szNick, 31, "<", "&lt;");
			replace_all(szNick, 31, ">", "&rt;");
			
			switch(i) {
				case 1: {
					iLen += formatex(szMotd[iLen], 1023 - iLen, "<tr style=^"color: #D9D919;^"><td>%d. %s<td>%d", i, szNick, SQL_ReadResult(hPytanie, 1));
				}
				
				case 2: {
					iLen += formatex(szMotd[iLen], 1023 - iLen, "<tr style=^"color: #8A8A8A;^"><td>%d. %s<td>%d", i, szNick, SQL_ReadResult(hPytanie, 1));
				}
				
				case 3: {
					iLen += formatex(szMotd[iLen], 1023 - iLen, "<tr style=^"color: #BC8362;^"><td>%d. %s<td>%d", i, szNick, SQL_ReadResult(hPytanie, 1));
				}
				
				default: {
					iLen += formatex(szMotd[iLen], 1023 - iLen, "<tr><td>%d. %s<td>%d", i, szNick, SQL_ReadResult(hPytanie, 1));
				}
			}
			
			SQL_NextRow(hPytanie);
		}
		
	}
	
	show_motd(id, szMotd, "Top 15 zyczen");
	return PLUGIN_CONTINUE;
}

public Top15Buntow(id) {
	new szPytanie[256], iDane[2];
	
	iDane[0] = id;
	iDane[1] = get_user_userid(id);
	formatex(szPytanie, 255, "SELECT nick, bunty FROM ranking ORDER BY bunty DESC LIMIT 15;");
	
	SQL_ThreadQuery(g_hSqlTuple, "Top15Buntow_Handler", szPytanie, iDane, 2);
}

public Top15Buntow_Handler(iFailState, Handle:hPytanie, szBlad, iKodBledu, iDane[], iDaneLen)
{
	new id = iDane[0];
	
	if(!is_user_connected(id) || get_user_userid(id) != iDane[1])
		return PLUGIN_CONTINUE;
		
	if(iKodBledu)
		log_amx("Blad: %s (Top15Buntow_Handler).", szBlad);
	
	if(iFailState == TQUERY_CONNECT_FAILED)
	{
		log_amx("Nie mozna podlaczyc sie do bazy danych.");
		return PLUGIN_CONTINUE;
	}
	else if(iFailState == TQUERY_QUERY_FAILED)
	{
		log_amx("Zapytanie anulowane (Top15Buntow_Handler).");
		return PLUGIN_CONTINUE;
	}
	
	new szNick[32], szMotd[2048], iLen, i;
	
	iLen = formatex(szMotd, 2047, "<head><style>table{border-collapse:collapse;background-color:#3D5450}td{border:0.2em solid #2F413E;text-align:center;height:1.2em;font-size: 0.8em}body{background-image:url(http://206.1s1k.pl/FD/srv40280/cstrike/models/zasady_jb/tlo.png);background-size:auto;color:#DADADA;}</style></head><body><br><br><center><table width=80%%><tr style=^"background-color:#2F413E;^"><td>#. Gracz<td>Bunty");
	
	if(SQL_NumRows(hPytanie)) {
		while(SQL_MoreResults(hPytanie)) {
			i ++;
			SQL_ReadResult(hPytanie, 0, szNick, 31);
			replace_all(szNick, 31, "<", "&lt;");
			replace_all(szNick, 31, ">", "&rt;");
			
			switch(i) {
				case 1: {
					iLen += formatex(szMotd[iLen], 1023 - iLen, "<tr style=^"color: #D9D919;^"><td>%d. %s<td>%d", i, szNick, SQL_ReadResult(hPytanie, 1));
				}
				
				case 2: {
					iLen += formatex(szMotd[iLen], 1023 - iLen, "<tr style=^"color: #8A8A8A;^"><td>%d. %s<td>%d", i, szNick, SQL_ReadResult(hPytanie, 1));
				}
				
				case 3: {
					iLen += formatex(szMotd[iLen], 1023 - iLen, "<tr style=^"color: #BC8362;^"><td>%d. %s<td>%d", i, szNick, SQL_ReadResult(hPytanie, 1));
				}
				
				default: {
					iLen += formatex(szMotd[iLen], 1023 - iLen, "<tr><td>%d. %s<td>%d", i, szNick, SQL_ReadResult(hPytanie, 1));
				}
			}
			
			SQL_NextRow(hPytanie);
		}
		
	}
	
	show_motd(id, szMotd, "Top 15 buntow");
	return PLUGIN_CONTINUE;
}

public WczytajDaneGracza(id) {/*
	if(!is_user_connected(id) && !is_user_connecting(id)) {
		return;
	}*/
	
	if(!g_hSqlTuple) {
		set_task(1.0, "WczytajDaneGracza", id);
	} else {
		new szNick[32], szPytanie[256], iDane[2];
		
		iDane[0] = id;
		iDane[1] = get_user_userid(id);
		get_user_name_to_sql(id, szNick, 31);
		formatex(szPytanie, 255, "SELECT zyczenia, bunty FROM ranking WHERE nick='%s';", szNick);
		
		SQL_ThreadQuery(g_hSqlTuple, "WczytajDaneGracza_Handler", szPytanie, iDane, 2);
	}
}

public WczytajDaneGracza_Handler(iFailState, Handle:hPytanie, szBlad, iKodBledu, iDane[], iDaneLen)
{
	new id = iDane[0];
	
	if((!is_user_connected(id) && !is_user_connecting(id)) || get_user_userid(id) != iDane[1])
		return PLUGIN_CONTINUE;
		
	if(iKodBledu)
		log_amx("Blad: %s (WczytajDaneGracza_Handler).", szBlad);
	
	if(iFailState == TQUERY_CONNECT_FAILED)
	{
		log_amx("Nie mozna podlaczyc sie do bazy danych.");
		return PLUGIN_CONTINUE;
	}
	else if(iFailState == TQUERY_QUERY_FAILED)
	{
		log_amx("Zapytanie anulowane (WczytajDaneGracza_Handler).");
		return PLUGIN_CONTINUE;
	}
	
	if(SQL_NumRows(hPytanie)) {
		g_iZyczeniaGracza[id] = SQL_ReadResult(hPytanie, 0);
		g_iBuntyGracza[id] = SQL_ReadResult(hPytanie, 1);
		
		g_bDaneWczytane[id] = true;
	} else {
		new szNick[32], szPytanie[256];
		
		get_user_name_to_sql(id, szNick, 31);
		formatex(szPytanie, 255, "INSERT INTO ranking (nick) VALUES ('%s');", szNick);
		
		SQL_ThreadQuery(g_hSqlTuple, "WpiszDaneGracza_Handler", szPytanie, iDane, 2);
	}
	
	return PLUGIN_CONTINUE;
}


public WpiszDaneGracza_Handler(iFailState, Handle:hPytanie, szBlad, iKodBledu, iDane[], iDaneLen)
{
	new id = iDane[0];
	
	if((!is_user_connected(id) && !is_user_connecting(id)) || get_user_userid(id) != iDane[1])
		return PLUGIN_CONTINUE;
		
	if(iKodBledu)
		log_amx("Blad: %s (WpiszDaneGracza_Handler).", szBlad);
	
	if(iFailState == TQUERY_CONNECT_FAILED)
	{
		log_amx("Nie mozna podlaczyc sie do bazy danych.");
		return PLUGIN_CONTINUE;
	}
	else if(iFailState == TQUERY_QUERY_FAILED)
	{
		log_amx("Zapytanie anulowane (WpiszDaneGracza_Handler).");
		return PLUGIN_CONTINUE;
	}
	
	g_bDaneWczytane[id] = true;
	return PLUGIN_CONTINUE;
}


ZapiszDaneGracza(id) {
	if(!g_bDaneWczytane[id]) {
		return;
	}
	
	new szNick[32], szPytanie[256];
	
	get_user_name_to_sql(id, szNick, 31);
	formatex(szPytanie, 255, "UPDATE ranking SET zyczenia=%d, bunty=%d WHERE nick='%s';", g_iZyczeniaGracza[id], g_iBuntyGracza[id], szNick);
	
	SQL_ThreadQuery(g_hSqlTuple, "ZapiszDaneGracza_Handler", szPytanie);
}

public ZapiszDaneGracza_Handler(iFailState, Handle:hPytanie, szBlad, iKodBledu, iDane[], iDaneLen)
{
	if(iKodBledu)
		log_amx("Blad: %s (ZapiszDaneGracza_Handler).", szBlad);
	
	if(iFailState == TQUERY_CONNECT_FAILED)
	{
		log_amx("Nie mozna podlaczyc sie do bazy danych.");
		return PLUGIN_CONTINUE;
	}
	else if(iFailState == TQUERY_QUERY_FAILED)
	{
		log_amx("Zapytanie anulowane (ZapiszDaneGracza_Handler).");
		return PLUGIN_CONTINUE;
	}
	
	return PLUGIN_CONTINUE;
}


public PrzygotujSQL()
{
	new pCvarHost = register_cvar("jailrank_sql_host", "127.0.0.1");
	new pCvarUzytkownik = register_cvar("jailrank_sql_user", "admin");
	new pCvarHaslo = register_cvar("jailrank_sql_password", "admin");
	new pCvarBaza = register_cvar("jailrank_sql_db", "dbname");
	new szHost[32], szUzytkownik[32], szHaslo[32], szBaza[32];
		
	get_pcvar_string(pCvarHost, szHost, 31);
	get_pcvar_string(pCvarUzytkownik, szUzytkownik, 31);
	get_pcvar_string(pCvarHaslo, szHaslo, 31);
	get_pcvar_string(pCvarBaza, szBaza, 31);
		
	g_hSqlTuple = SQL_MakeDbTuple(szHost, szUzytkownik, szHaslo, szBaza);
	
	new szPytanie[1028];
	formatex(szPytanie, 1027, "CREATE TABLE IF NOT EXISTS ranking\
					( \
					nick varchar(32) NOT NULL, \
					zyczenia int UNSIGNED DEFAULT 0, \
					bunty int UNSIGNED DEFAULT 0  \
					)");
	
	SQL_ThreadQuery(g_hSqlTuple, "StworzBaze_Handler", szPytanie);
}

public StworzBaze_Handler(iFailState, Handle:hPytanie, szBlad[], iKodBledu, iDane[], iDaneLen)
{
	if(iKodBledu)
		log_amx("Blad: %s (StworzBaze_Handler)", szBlad);
	
	if(iFailState == TQUERY_CONNECT_FAILED)
	{
		log_amx("Nie mozna podlaczyc sie do bazy danych.");
		return PLUGIN_CONTINUE;
	}
	else if(iFailState == TQUERY_QUERY_FAILED)
	{
		log_amx("Zapytanie anulowane (StworzBaze_Handler).");
		return PLUGIN_CONTINUE;
	}
	
	return PLUGIN_CONTINUE
}

public nat_PobierzBuntyGracza(id) {
	return g_iBuntyGracza[id];
}


public nat_PobierzZyczeniaGracza(id) {
	return g_iZyczeniaGracza[id];
}

stock get_user_name_to_sql(id, szNick[], iLen) {
	get_user_name(id, szNick, iLen);

	replace_all(szNick, iLen, "'", "\'");
	replace_all(szNick, iLen, "`", "\`");
}
