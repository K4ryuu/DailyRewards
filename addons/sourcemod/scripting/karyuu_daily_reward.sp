/* <----> Includes <----> */
#include <karyuu>
#include <DateTime>

#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
#include <store>
#include <shop>

/* <----> Pragma <----> */
#pragma tabsize 3;
#pragma semicolon 1;
#pragma newdecls required;

/* <----> Globals <----> */
int				  g_iStoreSupport;
int				  g_iClientPlaytime[MAXPLAYERS + 1] = { 0, ... };
bool				  g_bClientCanClaim[MAXPLAYERS + 1] = { false, ... };

Cookie			  g_hDailyDate,
	g_hDailyTime,
	g_hLastSeen;

ConVar g_hConVarPlayTime,
	g_hConVarCommads,
	g_hConVarCredit;

/* <----> Plugin Info <----> */
public Plugin myinfo =
{
	name			= "Daily Rewards",
	author		= "KitsuneLab | Karyuu",
	description = "Daily credit rewards for players, base on the playtime.",
	version		= "1.0",
	url			= "https://kitsune-lab.dev/"
};

/* <----> Code <----> */
public void OnPluginStart()
{
	// --> Check if the used library exists
	if (!DirExists("cfg/sourcemod/Kitsune"))
	{
		// --> Create the directory, if not exists
		if (!CreateDirectory("cfg/sourcemod/Kitsune", 511))
		{
			// --> Error, can't create the directory
			SetFailState("Unable to create a directory at 'cfg/sourcemod/Kitsune'");
		}
	}

	// --> Register client cookies
	g_hDailyDate		= new Cookie("Karyuu_DailyDate", "Stores the last date when the client has claimed the rewards.", CookieAccess_Protected);
	g_hDailyTime		= new Cookie("Karyuu_DailyTime", "Stores how many minutes did the client has played today.", CookieAccess_Protected);
	g_hLastSeen			= new Cookie("Karyuu_LastSeen", "Stores the last time the client has been seen.", CookieAccess_Protected);

	// --> Register convars
	g_hConVarCommads	= CreateConVar("kit_daily_commands", "sm_daily;sm_reward;sm_claim", "Commands to claim the daily reward (Separated with ';' (max 31), if already exists the command wont be registered (skipped))");
	g_hConVarPlayTime = CreateConVar("kit_daily_time", "60", "How many minutes the player needs to play to claim the daily reward.");
	g_hConVarCredit	= CreateConVar("kit_daily_credit", "500", "How much credits the player will receive when claiming the daily reward.");

	AutoExecConfig(true, "plugin.DailyRewards", "sourcemod/Kitsune");

	// --> Build a full path to the translation file
	char sTranslationPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, STRING(sTranslationPath), "translations/karyuu_daily_reward.phrases.txt");

	// --> Check if the translation file exists
	if (FileExists(sTranslationPath))
	{
		// --> Load the translation file
		LoadTranslations("karyuu_daily_reward.phrases");
	}
	else
		SetFailState("Missing translation file: %s", sTranslationPath);

	// --> Create a timer to add to the playtime
	CreateTimer(60.0, Timer_CheckDaily, _, TIMER_REPEAT);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	// --> Mark the store natives as optional
	MarkNativeAsOptional("Store_SetClientCredits");
	MarkNativeAsOptional("Store_GetClientCredits");
	MarkNativeAsOptional("Shop_GiveClientCredits");
	return APLRes_Success;
}

public void OnAllPluginsLoaded()
{
	// --> Check if any stores are loaded
	if (LibraryExists("store_zephyrus"))
	{
		g_iStoreSupport = 0;
	}
	else if (LibraryExists("shop"))
	{
		g_iStoreSupport = 1;
	}
	else
		SetFailState("No supported store plugin found, please install 'Store Zephyrus' or 'Shop-Core'.");
}

public void OnConfigsExecuted()
{
	// --> Retrieve the command aliases
	char sBuffer[512];
	g_hConVarCommads.GetString(STRING(sBuffer));

	// --> Register the commands
	Karyuu_RegMultipleCommand(sBuffer, Command_ClaimRewards, "Claims the daily rewards.");
}

public void OnClientCookiesCached(int iClient)
{
	// --> Check if the client is a bot
	if (!IsFakeClient(iClient))
	{
		// --> Get the playtime for the client for this day
		g_iClientPlaytime[iClient] = Karyuu_GetCookieInt(g_hDailyTime, iClient);

		// --> Get the last claim date for the client
		char sDate[32];
		g_hDailyDate.Get(iClient, STRING(sDate));

		// --> Set a starting date for the cookies, if it's empty
		if (Karyuu_IsStringEmpty(sDate))
			FormatEx(STRING(sDate), "2010-01-01");

		// --> Check if the last claim date is older than today
		DateTime dtParsed, dtNow = new DateTime(DateTime_Now);
		g_bClientCanClaim[iClient] = DateTime.TryParse(sDate, dtParsed) && (RoundToFloor(dtParsed.TotalDays) < RoundToFloor(dtNow.TotalDays));

		// --> Gets when the client has been last seen on server
		g_hLastSeen.Get(iClient, STRING(sDate));

		// --> Try to parse the date
		if (DateTime.TryParse(sDate, dtParsed))
		{
			// --> Checks if the client has playtime in the cookies
			if (g_iClientPlaytime[iClient] > 0)
			{
				// --> Checks if the playtime is bound with last day
				if (RoundToFloor(dtParsed.TotalDays) < RoundToFloor(dtNow.TotalDays))
				{
					// --> Reset the playtime for the client
					g_iClientPlaytime[iClient] = 0;
					Karyuu_SetCookieInt(g_hDailyTime, iClient, 0);
				}
			}
		}

		// --> Update the last seen date
		dtNow.ToString(STRING(sDate), "%Y-%m-%d");
		Karyuu_SetCookieString(g_hLastSeen, iClient, sDate);
	}
}

public void OnClientDisconnect(int iClient)
{
	// --> Save the client playtime
	Karyuu_SetCookieInt(g_hDailyTime, iClient, g_iClientPlaytime[iClient]);

	// --> Reset the variables
	g_iClientPlaytime[iClient] = 0;
	g_bClientCanClaim[iClient] = false;
}

public Action Command_ClaimRewards(int iClient, int iArgs)
{
	// --> Check if the client is connected (no console)
	if (!IsClientConnected(iClient))
		return Plugin_Handled;

	// --> Check if the client can claim the rewards today
	if (!g_bClientCanClaim[iClient])
	{
		CReplyToCommand(iClient, "{default}「{lightred}KIT-Daily{default}」{lime}%T", "Error_AlreadyClaimed", iClient);
		return Plugin_Handled;
	}

	// --> Check if the client has enough playtime
	if (g_iClientPlaytime[iClient] < g_hConVarPlayTime.IntValue)
	{
		CReplyToCommand(iClient, "{default}「{lightred}KIT-Daily{default}」{lime}%T", "Error_NotEnoughTime", iClient, g_hConVarPlayTime.IntValue - g_iClientPlaytime[iClient]);
		return Plugin_Handled;
	}

	// --> Block duplicate claims
	g_bClientCanClaim[iClient] = false;

	// --> Get the current date
	DateTime dtNow					= new DateTime(DateTime_Now);

	// --> Parse the date into a string
	char		sDate[32];
	dtNow.ToString(STRING(sDate), "%Y-%m-%d");

	// --> Update he client cookies
	Karyuu_SetCookieString(g_hDailyDate, iClient, sDate);
	Karyuu_SetCookieInt(g_hDailyTime, iClient, 0);

	// --> Select the correct method to give the rewards depending on the store
	switch (g_iStoreSupport)
	{
		case 0:
		{
			Store_SetClientCredits(iClient, (Store_GetClientCredits(iClient) + g_hConVarCredit.IntValue));
		}
		case 1:
		{
			Shop_GiveClientCredits(iClient, g_hConVarCredit.IntValue);
		}
	}

	CReplyToCommand(iClient, "{default}「{lightred}KIT-Daily{default}」{lime}%T", "Success", iClient, g_hConVarCredit.IntValue);
	return Plugin_Handled;
}

public Action Timer_CheckDaily(Handle hTimer, any data)
{
	// --> Loop through all clients
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		// --> Check if the client valid and plays
		if (IsClientInGame(iClient) && !IsFakeClient(iClient) && g_bClientCanClaim[iClient] && Karyuu_IsClientInTeam(iClient))
		{
			// --> Increment the playtime for the client
			g_iClientPlaytime[iClient]++;
		}
	}
	return Plugin_Continue;
}