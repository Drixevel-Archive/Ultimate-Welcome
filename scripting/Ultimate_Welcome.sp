#pragma semicolon 1

//Required Includes
#include <sourcemod>
#include <sdktools>
#include <morecolors>
#include <autoexecconfig>

#define PLUGIN_NAME     "[ANY] Ultimate Welcome"
#define PLUGIN_AUTHOR   "Keith Warren(Jack of Designs)"
#define PLUGIN_VERSION  "1.0.1"
#define PLUGIN_DESCRIPTION	"Allows server operators to welcome guests with a variety of methods."
#define PLUGIN_CONTACT  "http://www.jackofdesigns.com/"

new Handle:ConVars[7] = {INVALID_HANDLE, ...};

new bool:cv_Enabled = true, bool:cv_Load = false, String:cv_Tag[32], String:cv_Welcome[32], String:cv_Sound[PLATFORM_MAX_PATH], cv_Timer = 5;

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_CONTACT
};

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("ultimate_welcome.phrases");
	
	AutoExecConfig_SetFile("Ultimate_Welcome");

	ConVars[0] = AutoExecConfig_CreateConVar("Ultimate_Welcome_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_DONTRECORD);
	ConVars[1] = AutoExecConfig_CreateConVar("sm_ultimatewelcome_status", "1", "Status of the plugin: (1 = on, 0 = off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	ConVars[2] = AutoExecConfig_CreateConVar("sm_ultimatewelcome_load", "0", "Type of message loading: (1 = 'message' ConVar, 0 = Translations)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	ConVars[3] = AutoExecConfig_CreateConVar("sm_ultimatewelcome_tag", "[SM]", "Tag to Use: (Blank = No Tag, max 32 characters)", FCVAR_PLUGIN);
	ConVars[4] = AutoExecConfig_CreateConVar("sm_ultimatewelcome_message", "Welcome to our server %N!", "If load is set to 1, use this instead. (%N is replaced with clients name)", FCVAR_PLUGIN);
	ConVars[5] = AutoExecConfig_CreateConVar("sm_ultimatewelcome_sound", "", "Play a Sound on connect: (blank = disabled, relative to sound folder - 'folder/play.wav')", FCVAR_PLUGIN);
	ConVars[6] = AutoExecConfig_CreateConVar("sm_ultimatewelcome_timer", "5", "Time after a client is put into the server to show messages: (0 = Instant)", FCVAR_PLUGIN, true, 0.0);
	
	AutoExecConfig_ExecuteFile();

	for (new i = 0; i < sizeof(ConVars); i++)
	{
		HookConVarChange(ConVars[i], HandleCvars);
	}
	
	AutoExecConfig_CleanFile();
}

public OnConfigsExecuted()
{
	cv_Enabled = GetConVarBool(ConVars[1]);
	cv_Load = GetConVarBool(ConVars[2]);
	GetConVarString(ConVars[3], cv_Tag, sizeof(cv_Tag));
	GetConVarString(ConVars[4], cv_Welcome, sizeof(cv_Welcome));
	GetConVarString(ConVars[5], cv_Sound, sizeof(cv_Sound));
	cv_Timer = GetConVarInt(ConVars[6]);
}

public OnMapStart()
{
	decl String:sBuffer[PLATFORM_MAX_PATH];
	GetConVarString(ConVars[5], cv_Sound, sizeof(cv_Sound));
	Format(sBuffer, sizeof(sBuffer), "sound/%s", cv_Sound);
	
	if (!StrEqual(cv_Sound, ""))
	{
		PrecacheSound(cv_Sound);
		AddFileToDownloadsTable(sBuffer);
	}
}

public HandleCvars (Handle:cvar, const String:oldValue[], const String:newValue[])
{
	if (StrEqual(oldValue, newValue, true)) return;

	new iNewValue = StringToInt(newValue);

	if (cvar == ConVars[0])
	{
		SetConVarString(ConVars[0], PLUGIN_VERSION);
	}
	else if (cvar == ConVars[1])
	{
		cv_Enabled = bool:iNewValue;
	}
	else if (cvar == ConVars[2])
	{
		cv_Load = bool:iNewValue;
	}
	else if (cvar == ConVars[3])
	{
		GetConVarString(ConVars[3], cv_Tag, sizeof(cv_Tag));
	}
	else if (cvar == ConVars[4])
	{
		GetConVarString(ConVars[4], cv_Welcome, sizeof(cv_Welcome));
	}
	else if (cvar == ConVars[5])
	{
		GetConVarString(ConVars[5], cv_Sound, sizeof(cv_Sound));
	}
	else if (cvar == ConVars[6])
	{
		cv_Timer = iNewValue;
	}
}

public OnClientPutInServer(client)
{
	if (!cv_Enabled || !IsClientInGame(client) || IsFakeClient(client)) return;
	
	if (cv_Timer != 0)
	{
		new Float:timer = float(cv_Timer);
		CreateTimer(timer, Welcome, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		return;
	}
	
	WelcomeClient(client);
}

public Action:Welcome(Handle:hTimer, any:data)
{
	new client = GetClientOfUserId(data);
	
	if (IsClientInGame(client))
	{
		WelcomeClient(client);
	}
}

stock WelcomeClient(client)
{
	if (cv_Load)
	{
		decl String:name[MAX_NAME_LENGTH];
		GetClientName(client, name, sizeof(name));
		ReplaceString(cv_Welcome, sizeof(cv_Welcome), "%N", name);
		CPrintToChat(client, "%s %t", cv_Tag, cv_Welcome);
	}
	else
	{
		CPrintToChat(client, "%s %t", cv_Tag, "Welcome", client);
	}
	
	if (!StrEqual(cv_Sound, ""))
	{
		EmitSoundToClient(client, cv_Sound, _, _, _, _, 1.0, _, _, _, _, _, _);
	}
}