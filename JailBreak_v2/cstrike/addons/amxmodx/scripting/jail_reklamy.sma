#include <amxmodx>
#include <amxmisc>


#define PLUGIN "Autoresponder/Advertiser"
#define VERSION "1.3"
#define AUTHOR "MaximusBrood & Sebul"

/* ****************** DEFINES ****************** */
#define COND_TKN '%'
#define SAY_TKN '@'
#define DEVIDE_TKN '~'

#define MAXLINE 189
/* **************** END DEFINES **************** */
/* ******************* CONST ******************* */
new const TAG_YOU[] = "[you]";
new const TAG_NORMAL[] = "[normal]";
new const TAG_TEAM[] = "[team]";
new const TAG_GREEN[] = "[green]";

new const FILE_NAME[] = "jail_reklamy.ini";
/* ***************** END CONST ***************** */
/* ******************* ENUM ******************* */
enum _:eAdType {
	NORM_AD = 0,
	SAY_AD
}

enum _:eCvary {
	CReactAll = 0,
	CRandMin,
	CRandMax
}

enum _:data_adver {
	a_type,
	a_cond_player,
	a_cond_time[2],
	a_cond_type[3],
	a_cond_map[32],
	a_cond_prefix[10],
	a_said[32],
	a_text[MAXLINE+1]
}
/* ***************** END ENUM ***************** */

new Array:data_holder,
	array_size,
	adCount[eAdType],
	gmsgSayText,
	g_MaxPlayer,
	currAd = -1;

new g_Cvary[eCvary],
	g_WartCvarow[eCvary],
	adver_data[data_adver];

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);

	register_cvar("admanager_version", VERSION, FCVAR_SERVER|FCVAR_SPONLY|FCVAR_UNLOGGED);
	g_Cvary[CReactAll] = register_cvar("ad_react_all", "1");
	g_Cvary[CRandMin] = register_cvar("ad_rand_min", "40");
	g_Cvary[CRandMax] = register_cvar("ad_rand_max", "60");

	gmsgSayText = get_user_msgid("SayText");

	register_clcmd("say", "eventSay");
	register_clcmd("say_team", "eventSay");

	set_task(11.0, "load");
}

public load() {
	new filepath[64];
	get_configsdir(filepath, 63);
	formatex(filepath, 63, "%s/%s", filepath, FILE_NAME);

	new fHandle = fopen(filepath, "rt");

	if(fHandle) {
		g_MaxPlayer = get_maxplayers();

		g_WartCvarow[CReactAll] = get_pcvar_num(g_Cvary[CReactAll]);
		g_WartCvarow[CRandMin] = get_pcvar_num(g_Cvary[CRandMin]);
		g_WartCvarow[CRandMax] = get_pcvar_num(g_Cvary[CRandMax]);

		if(g_WartCvarow[CRandMin] < 10) {
			g_WartCvarow[CRandMin] = 10;
			set_pcvar_num(g_Cvary[CRandMin], g_WartCvarow[CRandMin]);
		}
		if(g_WartCvarow[CRandMax] < 15) {
			g_WartCvarow[CRandMax] = 15;
			set_pcvar_num(g_Cvary[CRandMax], g_WartCvarow[CRandMax]);
		}
		if(g_WartCvarow[CRandMin] > g_WartCvarow[CRandMax]) {
			g_WartCvarow[CRandMin] = g_WartCvarow[CRandMax];
			set_pcvar_num(g_Cvary[CRandMin], g_WartCvarow[CRandMin]);
		}

		if(data_holder) ArrayDestroy(data_holder);
		data_holder = ArrayCreate(data_adver);

		new output[512], a;
		new type, p_cond_player, p_cond_time[2], p_cond_type[3], p_cond_map[32], p_cond_prefix[10], p_said[32], p_text[MAXLINE*2+1];
		new conditions[128], temp[64], sort[16], cond[32], s_from[3], s_to[3];

		while(!feof(fHandle)) {
			fgets(fHandle, output, 511);

			trim(output);

			if(!output[0] || output[0] == ';')
				continue;

			type = 0;
			p_cond_player = 0;
			p_cond_time[0] = 0;
			p_cond_time[1] = 0;
			for(a=0; a<3; ++a) p_cond_type[a] = 0;
			p_cond_map[0] = 0;
			p_cond_prefix[0] = 0;
			p_said[0] = 0;
			p_text[0] = 0;

			if(output[0] == COND_TKN) {
				strtok(output, conditions, 127, output, 511, DEVIDE_TKN);

				for(a=0; a<3; ++a) {
					conditions[0] = ' ';
					trim(conditions);

					strtok(conditions, temp, 63, conditions, 127, COND_TKN);
					strtok(temp, sort, 15, cond, 31, ' ');

					if(equali(sort, "map")) {
						p_cond_type[a] = 1;
						copy(p_cond_map, 31, cond);
					}
					else if(equali(sort, "prefix")) {
						p_cond_type[a] = 2;
						copy(p_cond_prefix, 9, cond);
					}
					else if(equali(sort, "min_players")) {
						p_cond_type[a] = 3;
						p_cond_player = str_to_num(cond);
					}
					else if(equali(sort, "max_players")) {
						p_cond_type[a] = 4;
						p_cond_player = str_to_num(cond);
					}
					else if(equali(sort, "time")) {
						strtok(cond, s_from, 2, s_to, 2, '-');

						p_cond_type[a] = 5;
						p_cond_time[0] = str_to_num(s_from);
						p_cond_time[1] = str_to_num(s_to);
					}

					if(!conditions[0])
						break;
				}
			}

			type = (output[0] == SAY_TKN) ? SAY_AD : NORM_AD;
			
			if(type == SAY_AD) {
				output[0] = ' ';
				trim(output);

				strtok(output, p_said, 31, p_text, MAXLINE*2, DEVIDE_TKN);
			}
			else
				copy(p_text, MAXLINE*2, output);

			setColor(p_text, MAXLINE*2);

			adver_data[a_type] = type;
			adver_data[a_cond_player] = p_cond_player;
			adver_data[a_cond_time][0] = p_cond_time[0];
			adver_data[a_cond_time][1] = p_cond_time[1];
			for(a=0; a<3; ++a) adver_data[a_cond_type][a] = p_cond_type[a];
			adver_data[a_cond_map] = p_cond_map;
			adver_data[a_cond_prefix] = p_cond_prefix;
			adver_data[a_said] = p_said;
			copy(adver_data[a_text], MAXLINE, p_text);
			ArrayPushArray(data_holder, adver_data);

			++adCount[type];
		}

		fclose(fHandle);

		array_size = ArraySize(data_holder);

		if(adCount[NORM_AD])
			set_task(float(random_num(g_WartCvarow[CRandMin], g_WartCvarow[CRandMax])), "eventTask");
	}
	else {
		new szFail[128];
		formatex(szFail, 127, "Brak '%s' na serwerze", filepath);
		set_fail_state(szFail);
	}
}

public eventTask() {
	for(new a=0; a<array_size; ++a) {
		if(++currAd >= array_size) {
			g_WartCvarow[CReactAll] = get_pcvar_num(g_Cvary[CReactAll]);
			g_WartCvarow[CRandMin] = get_pcvar_num(g_Cvary[CRandMin]);
			g_WartCvarow[CRandMax] = get_pcvar_num(g_Cvary[CRandMax]);

			if(g_WartCvarow[CRandMin] < 10) {
				g_WartCvarow[CRandMin] = 10;
				set_pcvar_num(g_Cvary[CRandMin], g_WartCvarow[CRandMin]);
			}
			if(g_WartCvarow[CRandMax] < 15) {
				g_WartCvarow[CRandMax] = 15;
				set_pcvar_num(g_Cvary[CRandMax], g_WartCvarow[CRandMax]);
			}
			if(g_WartCvarow[CRandMin] > g_WartCvarow[CRandMax]) {
				g_WartCvarow[CRandMin] = g_WartCvarow[CRandMax];
				set_pcvar_num(g_Cvary[CRandMin], g_WartCvarow[CRandMin]);
			}

			currAd = 0;
		}

		if(checkConditions(currAd, NORM_AD)) {
			new data[2];
			data[0] = currAd;
			data[1] = 0;

			displayAd(data);

			break;
		}
	}

	set_task(float(random_num(g_WartCvarow[CRandMin], g_WartCvarow[CRandMax])), "eventTask");
}

public eventSay(id) {
	if(!adCount[SAY_AD])
		return PLUGIN_CONTINUE;

	new talk[64], a;
	read_argv(1, talk, 63);

	for(a=0; a<array_size; ++a) {
		if(!checkConditions(a, SAY_AD))
			continue;

		ArrayGetArray(data_holder, a, adver_data);

		if(containi(talk, adver_data[a_said]) != -1) {
			new data[2];
			data[0] = a;
			data[1] = id;

			set_task(0.3, "displayAd", _, data, 2);

			break;
		}
	}

	return PLUGIN_CONTINUE;
}

public displayAd(params[]) {
	ArrayGetArray(data_holder, params[0], adver_data);

	new message[MAXLINE*2+1], name[32], bool:tag_you_on;

	if(contain(adver_data[a_text], TAG_YOU) != -1)
		tag_you_on = true;

	if(!g_WartCvarow[CReactAll] && is_user_connected(params[1])) {
		if(tag_you_on) {
			copy(message, MAXLINE, adver_data[a_text]);
			get_user_name(params[1], name, 31);
			replace_all(message, MAXLINE*2, TAG_YOU, name);
			message[190] = 0;
		}

		message_begin(MSG_ONE_UNRELIABLE, gmsgSayText, _, params[1]);
		write_byte(params[1]);
		tag_you_on ? write_string(message) : write_string(adver_data[a_text]);
		message_end();
	}
	else {
		for(new i=1; i<=g_MaxPlayer; ++i) {
			if(is_user_connected(i) && !is_user_bot(i) && !is_user_hltv(i)) {
				if(tag_you_on) {
					copy(message, MAXLINE, adver_data[a_text]);
					get_user_name(i, name, 31);
					replace_all(message, MAXLINE*2, TAG_YOU, name);
					message[190] = 0;
				}

				message_begin(MSG_ONE_UNRELIABLE, gmsgSayText, _, i);
				write_byte(i);
				tag_you_on ? write_string(message) : write_string(adver_data[a_text]);
				message_end();
			}
		}
	}
}

/* ****************** STOCKS ****************** */

stock bool:checkConditions(item, type) {
	ArrayGetArray(data_holder, item, adver_data);

	if(type != adver_data[a_type])
		return false;

	for(new a=0; a<3; ++a) {
		if(!adver_data[a_cond_type][a])
			continue;

		if(adver_data[a_cond_type][a] == 1) {
			new mapname[32];
			get_mapname(mapname, 31);

			if(!equali(mapname, adver_data[a_cond_map]))
				return false;
		}
		else if(adver_data[a_cond_type][a] == 2) {
			new mapprefix[10];
			get_prefix(mapprefix, 9);

			if(!equali(mapprefix, adver_data[a_cond_prefix]))
				return false;
		}
		else if(adver_data[a_cond_type][a] == 3) {
			if(get_playersnum() < adver_data[a_cond_player])
				return false;
		}
		else if(adver_data[a_cond_type][a] == 4) {
			if(get_playersnum() > adver_data[a_cond_player])
				return false;
		}
		else if(adver_data[a_cond_type][a] == 5) {
			new s_hour; time(s_hour);
			if(adver_data[a_cond_time][1] > adver_data[a_cond_time][0]) {
				if(s_hour < adver_data[a_cond_time][0] || s_hour >= adver_data[a_cond_time][1])
					return false;
			}
			else if(s_hour < adver_data[a_cond_time][0] && s_hour >= adver_data[a_cond_time][1]) {
				return false;
			}
		}
	}

	return true;
}

stock get_prefix(sMapType[], iLen) {
	new sMap[32]; get_mapname(sMap, 31);
	strtok(sMap, sMapType, iLen, sMap, 31, '_');
}

stock setColor(string[], len) {
	if(contain(string, TAG_NORMAL) != -1 || contain(string, TAG_TEAM) != -1 || contain(string, TAG_GREEN) != -1) {
		replace_all(string, len, TAG_NORMAL, "^1"); // ^x01
		replace_all(string, len, TAG_TEAM, "^3");
		replace_all(string, len, TAG_GREEN, "^4");

		format(string, len, "%s", string);
	}
}
