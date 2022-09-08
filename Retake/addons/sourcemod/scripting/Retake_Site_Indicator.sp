#include <sourcemod>
#include <sdktools>
#include <multicolors>
#include "retakes"

#define MAX_FILE_LEN 128

#pragma semicolon 1
#pragma newdecls required

ConVar g_THud;
ConVar g_THud2;
ConVar g_enable_chat;
ConVar g_enable_hint_before;
ConVar g_enable_hint_after;
ConVar g_enable_sound;

bool g_benable_chat = false;
bool g_benable_hint_before = false;
bool g_benable_hint_after = false;
bool g_benable_sound = false;

char g_BombSite[16];

Handle g_hHud = null;
Handle g_hHud2 = null;
float g_fHud;
float g_fHud2;
char soundName[MAX_FILE_LEN];
char soundName2[MAX_FILE_LEN];

Handle PickUpSoundName = INVALID_HANDLE;
Handle PickUpSoundName2 = INVALID_HANDLE;

public Plugin myinfo = 
{
	name = "Retake Site Indicator",
	author = "Gold_KingZ",
	description = "Show Retake Site Chat , Alert , Sound",
	version = "1.0.0",
	url = "https://github.com/oqyh"
}

public void OnPluginStart()
{
	LoadTranslations( "Retake_Site_Indicator.phrases" );
	
	g_enable_chat = CreateConVar("sm_retake_chat_site"		  	 , "1", "Enable chat  site indicator || 1= Yes || 0= No", _, true, 0.0, true, 1.0);
	
	g_enable_hint_before = CreateConVar("sm_retake_hint_before"		  	 , "1", "Enable hint site indicator BEFORE PLANT || 1= Yes || 0= No", _, true, 0.0, true, 1.0);
	g_THud2 = CreateConVar("sm_retake_hud_before", "5", "How long hint bomb site HUD should be displayed BEFORE PLANT", _, true, 1.0);
	
	g_enable_hint_after = CreateConVar("sm_retake_hint_after"		  	 , "1", "Enable hint  site indicator AFTER PLANT || 1= Yes || 0= No", _, true, 0.0, true, 1.0);
	g_THud = CreateConVar("sm_retake_hud_after", "5", "How long hint bomb site HUD should be displayed AFTER PLANT", _, true, 1.0);

	g_enable_sound = CreateConVar("sm_retake_sound_site"		  	 , "1", "Enable sound  site indicator || 1= Yes || 0= No", _, true, 0.0, true, 1.0);
	PickUpSoundName = CreateConVar("sm_retake_sound_sitea", "gold_kingz/sitea/RetakeOnAsite.mp3", "Path Sound For Site A");
	PickUpSoundName2 = CreateConVar("sm_retake_sound_siteb", "gold_kingz/siteb/RetakeOnBsite.mp3", "Path Sound For Site B");

	HookEvent("round_start", Event_RoundStart, EventHookMode_Pre);
	HookEvent("bomb_planted", Event_BombPlanted, EventHookMode_Post);
	
	HookConVarChange(g_enable_chat, OnSettingsChanged);
	HookConVarChange(g_enable_hint_before, OnSettingsChanged);
	HookConVarChange(g_enable_hint_after, OnSettingsChanged);
	HookConVarChange(g_enable_sound, OnSettingsChanged);
	
	AutoExecConfig(true, "Retake_Site_Indicator");
}

public int OnSettingsChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	if(convar == g_enable_chat)
	{
		g_benable_chat = g_enable_chat.BoolValue;
	}else if(convar == g_enable_hint_before)
	{
		g_benable_hint_before = g_enable_hint_before.BoolValue;
	}else if(convar == g_enable_sound)
	{
		g_benable_sound = g_enable_sound.BoolValue;
	}else if(convar == g_enable_hint_after)
	{
		g_benable_hint_after = g_enable_hint_after.BoolValue;
	}
	return 0;
}
public void OnConfigsExecuted()
{
	g_benable_chat = GetConVarBool(g_enable_chat);
	g_benable_hint_before = GetConVarBool(g_enable_hint_before);
	g_benable_hint_after = GetConVarBool(g_enable_hint_after);
	g_benable_sound = GetConVarBool(g_enable_sound);
	
	if (!g_benable_sound)
		return;
	GetConVarString(PickUpSoundName, soundName, MAX_FILE_LEN);
	GetConVarString(PickUpSoundName2, soundName2, MAX_FILE_LEN);
	char buffer[MAX_FILE_LEN];
	char buffer2[MAX_FILE_LEN];
	PrecacheSound(soundName, true);
	Format(buffer, sizeof(buffer), "sound/%s", soundName);
	PrecacheSound(soundName2, true);
	Format(buffer2, sizeof(buffer2), "sound/%s", soundName2);
	AddFileToDownloadsTable(buffer);
	AddFileToDownloadsTable(buffer2);
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if (!Retakes_Live())
		return;
	
	IsRetake();
	
	g_fHud2 = GetGameTime();
	
	if(g_hHud2 != null)
		delete g_hHud2;
	
	g_hHud2 = CreateTimer(1.0, Timer_DisplayHUD2, _, TIMER_REPEAT);
	
}

void IsRetakes(int client)
{
	if (!IsValidClientEx(client, true, false))
		return;

	if (!Retakes_Live())
		return;
}

void IsRetake()
{
	ShowInfo();
	ShowInfo2();
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClientEx(i, true, false))
			continue;

		IsRetakes(i);
	}
}

void ShowInfo()
{
	Bombsite site = Retakes_GetCurrrentBombsite();
	
	if (site == BombsiteA)
		Format(g_BombSite, sizeof(g_BombSite), "%t", "BombPlantA");
	else if (site == BombsiteB)
		Format(g_BombSite, sizeof(g_BombSite), "%t", "BombPlantB");
		
	CreateTimer (0.7, Timer_ShowInfo);
}


public void Event_BombPlanted(Event event, const char[] name, bool dontBroadcast)
{
	g_fHud = GetGameTime();
	
	if(g_hHud != null)
		delete g_hHud;
	
	g_hHud = CreateTimer(1.0, Timer_DisplayHUD, _, TIMER_REPEAT);
}

public Action Timer_DisplayHUD(Handle timer, any data)
{
	if(g_fHud + g_THud.FloatValue < GetGameTime())
	{
		g_hHud = null;
		return Plugin_Stop;
	}
	if( g_benable_hint_after )
	{
	PrintCenterTextAll("<font face='Arial' size='20'> %t </font>\n\t<span class='fontSize-xxxl'><font face='Arial' color='#00FF00'><b>%s</b></font></font>", "BombPlant", g_BombSite);
	}
	return Plugin_Continue;
}


public Action Timer_DisplayHUD2(Handle timer, any data)
{
	if(g_fHud2 + g_THud2.FloatValue < GetGameTime())
	{
		g_hHud2 = null;
		return Plugin_Stop;
	}

	Bombsite site = Retakes_GetCurrrentBombsite();
	
	if (site == BombsiteA && g_benable_hint_before)
	{
	PrintCenterTextAll("<font face='Arial' size='20'> %t </font>\n\t<span class='fontSize-xxxl'><font face='Arial' color='#00FF00'><b>%t</b></font></font>", "RetakeOn", "BombPlantA");
	}else if (site == BombsiteB && g_benable_hint_before)
	{
	PrintCenterTextAll("<font face='Arial' size='20'> %t </font>\n\t<span class='fontSize-xxxl'><font face='Arial' color='#00FF00'><b>%t</b></font></font>", "RetakeOn", "BombPlantB");
	}
	return Plugin_Continue;
}

void ShowInfo2()
{
	Bombsite site = Retakes_GetCurrrentBombsite();
	if( g_benable_chat )
	{
	if (site == BombsiteA)
	{
	CPrintToChatAll("{lightblue}‎‏‏‎‎‏‏‎ ‎‏‏‎ ‎‏‏‎ ‎‏‏‎ ‎‏‏‎回︎回︎回︎回︎"),
	CPrintToChatAll("{lightblue}回︎回︎‎‏‏‎ ‎‏‏‎ ‎‏‏‎ ‎‏‏‎ ‎‏‏‎ ‎‎‏‏‎ ‎‏‏‎ ‎‏‏‎ ‎‏‏‎回︎回︎"),
	CPrintToChatAll("{lightblue}回︎回︎‎‏‏‎ ‎‏‏‎ ‎‏‏‎ ‎‏‏‎ ‎‏‏‎ ‎‎‏‏‎ ‎‏‏‎ ‎‏‏‎ 回︎回︎"),
	CPrintToChatAll("{lightblue}回︎回︎回︎回︎回︎回︎"),
	CPrintToChatAll("{lightblue}回︎回︎‎‏‏‎ ‎‏‏‎ ‎‏‏‎ ‎‏‏‎ ‎‏‏‎ ‎‎‏‏‎ ‎‏‏‎ ‎‏‏‎ 回︎回︎"),
	CPrintToChatAll("{lightblue}回︎回︎‎‏‏‎ ‎‏‏‎ ‎‏‏‎ ‎‏‏‎ ‎‏‏‎ ‎‎‏‏‎ ‎‏‏‎ ‎‏‏‎ 回︎回︎");
	}
	else if (site == BombsiteB)
	{
	CPrintToChatAll("{lightblue}回︎回︎回︎回︎"),
	CPrintToChatAll("{lightblue}回︎回︎‎‏‏‎ ‎‏‏‎ ‎‏‏‎ ‎‏‏‎ ‎‏‏‎ ‎‎‏‏‎ ‎‏‏‎ ‎‏‏‎回︎"),
	CPrintToChatAll("{lightblue}回︎回︎回︎回︎"),
	CPrintToChatAll("{lightblue}回︎回︎‎‏‏‎ ‎‏‏‎ ‎‏‏‎ ‎‏‏‎ ‎‏‏‎ ‎‎‏‏‎ ‎‏‏‎ 回︎"),
	CPrintToChatAll("{lightblue}回︎回︎‎‏‏‎ ‎‏‏‎ ‎‏‏‎ ‎‏‏‎ ‎‏‏‎ ‎‎‏‏‎ ‎‏‏‎  回︎"),
	CPrintToChatAll("{lightblue}回︎回︎回︎回︎");
	}
	}
}

public Action Timer_ShowInfo(Handle timer)
{
	Bombsite site = Retakes_GetCurrrentBombsite();
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClientEx(i))
			continue;
			
		if (site == BombsiteA && g_benable_sound)
		{
		EmitSoundToClient(i, soundName);
		}else if (site == BombsiteB && g_benable_sound)
		{
		EmitSoundToClient(i, soundName2);
		}
	}
	return Plugin_Continue;
}

bool IsValidClientEx(int client, bool bots = true, bool dead = true)
{
	if (client <= 0)
		return false;

	if (client > MaxClients)
		return false;

	if (!IsClientInGame(client))
		return false;

	if (IsFakeClient(client) && !bots)
		return false;

	if (IsClientSourceTV(client))
		return false;

	if (IsClientReplay(client))
		return false;

	if (!IsPlayerAlive(client) && !dead)
		return false;

	return true;
}