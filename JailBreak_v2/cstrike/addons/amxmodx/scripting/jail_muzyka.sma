#include <amxmodx>
#include <amxmisc>
#include <fun>
#include <cstrike>
#include <jailbreak>

#define PLUGIN "menu muzyk"
#define VERSION "1.0"
#define AUTHOR "Mrufka"

new const g_szMuzyka[][][] = {
	{ "We Gonna Live Forever", "JailBreak_Izolatka/muzyka_v1/rs_1.mp3" },
	{ "Beautiful World", "JailBreak_Izolatka/muzyka_v1/rs_2.mp3" },
	{ "Sub Pielea Mea", "JailBreak_Izolatka/muzyka_v1/rs_3.mp3" },
	{ "Za oknem deszcz", "JailBreak_Izolatka/muzyka_v1/rs_4.mp3" },
	{ "5 Hours", "JailBreak_Izolatka/muzyka_v1/rs_5.mp3" },
	{ "I'm So Hot", "JailBreak_Izolatka/muzyka_v1/rs_6.mp3" },
	{ "House Party", "JailBreak_Izolatka/muzyka_v1/rs_7.mp3" },
	{ "TARANTELLA 2021", "JailBreak_Izolatka/muzyka_v1/rs_8.mp3" },
	{ "Ce Soir ", "JailBreak_Izolatka/muzyka_v1/rs_9.mp3" },
	{ "Freed From Desire", "JailBreak_Izolatka/muzyka_v1/rs_10.mp3" },
	{ "In The End ", "JailBreak_Izolatka/muzyka_v1/rs_11.mp3" },
	{ "Kocham Cie", "JailBreak_Izolatka/muzyka_v1/rs_12.mp3" },
	{ "Harry Potter Style", "JailBreak_Izolatka/muzyka_v1/rs_13.mp3" },
	{ "Sexualna", "JailBreak_Izolatka/muzyka_v1/rs_14.mp3" },
	{ "Brother Louie", "JailBreak_Izolatka/muzyka_v1/rs_15.mp3" },
	{ "Like I Love You", "JailBreak_Izolatka/muzyka_v1/rs_16.mp3" },
	{ "Superhero", "JailBreak_Izolatka/muzyka_v1/rs_17.mp3" },
	{ "Clarity ", "JailBreak_Izolatka/muzyka_v1/rs_18.mp3" }
}

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_clcmd("say /muzyka", "Muzyka");
	register_clcmd("say /off", "Muzyka_OFF");	
	
	register_logevent("koniec_rundy", 2, "1=Round_End");	
}

public plugin_natives() {
	register_native("jail_menumuzyki", "Muzyka", 1);
	register_native("jail_muzyka_play", "GrajMuzyke", 1);
}

public koniec_rundy() {	
	new item = random(18);
	
	client_cmd(0, "mp3 play sound/%s", g_szMuzyka[item][1]);
	PokazWiadomosc(0, "Aktualnie grana muzyka to:^3 %s", g_szMuzyka[item][0]);
}	

public GrajMuzyke() {
	new item = random(18);
	
	client_cmd(0, "mp3 play sound/%s", g_szMuzyka[item][1]);
	PokazWiadomosc(0, "Aktualnie grana muzyka to:^3 %s", g_szMuzyka[item][0]);
	PokazWiadomosc(0, "Uzyj komendy^3 /off^1 aby wylaczyc muzyke");
}
	
public plugin_precache()
{
	for(new i = 0; i < sizeof g_szMuzyka; i++) {
		precache_sound(g_szMuzyka[i][1]);
	}
}

public Muzyka(id)
{
	if(jail_get_prowadzacy() != id && !(get_user_flags(id) & ADMIN_BAN))  {
		PokazWiadomosc(id, "Ta opcja jest dostepna tylko dla prowadzacego straznika!");
		return PLUGIN_HANDLED;
	}
	
	if(jail_get_play_game_id() >= 6) {
		PokazWiadomosc(id, "Ta opcja jest niedostepna podczas zabaw!");
		return PLUGIN_HANDLED;
	}
	
	new menu = menu_create(fmt("\d%s | Menu^n\r[MUZYKA]\w Menu muzyki:", forum), "MenuMuzyka");
	
	for(new i = 0; i < sizeof g_szMuzyka; i++) {
		menu_additem(menu, g_szMuzyka[i][0]);
	}
	
	menu_additem(menu, "\rZatrzymaj muzyke");
	
	menu_setprop(menu, MPROP_BACKNAME, "\d×\w Wroc");
	menu_setprop(menu, MPROP_NEXTNAME, "\d×\w Dalej");
	menu_setprop(menu, MPROP_EXITNAME, "\d×\w Wyjdz");
	menu_display(id, menu);
	return PLUGIN_HANDLED;
}

public MenuMuzyka(id, menu, item)
{
	if (!is_user_alive(id) || (jail_get_prowadzacy() != id && !(get_user_flags(id) & ADMIN_BAN)) || item == MENU_EXIT) {
		menu_destroy(menu);
		return PLUGIN_CONTINUE;
	}
	
	if(item >= 0) {
		if(item < sizeof g_szMuzyka) {
			client_cmd(0, "mp3 play sound/%s", g_szMuzyka[item][1]);
			PokazWiadomosc(id, "Odpaliles:^3 %s", g_szMuzyka[item][0]);			
			PokazWiadomosc(0, "Prowadzacy wlaczyl:^3 %s", g_szMuzyka[item][0]);
		} else {
			client_cmd(0, "mp3 stop");
			PokazWiadomosc(0, "Muzyka zostala^3 zatrzymana!");
		}
		
		menu_display(id, menu);
	}
	
	return PLUGIN_CONTINUE;
}  

public Muzyka_OFF(id) client_cmd(id, "mp3 stop");             
