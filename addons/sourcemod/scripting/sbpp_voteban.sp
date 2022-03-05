#include <sourcemod>
#include <sourcebanspp>

#pragma semicolon 1
#pragma newdecls required

int g_voteTarget, g_voteAdmin;
ConVar g_voteTime = null;

public Plugin myinfo = 
{
	name = "Sourcebans++ - Voteban", 
	author = "ByDexter", 
	description = "", 
	version = "1.0", 
	url = "https://steamcommunity.com/id/ByDexterTR - ByDexter#5494"
};

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("basevotes.phrases");
	LoadTranslations("plugin.basecommands");
	LoadTranslations("basebans.phrases");
	
	RegAdminCmd("sm_vban", Command_Voteban, ADMFLAG_VOTE | ADMFLAG_BAN, "sm_vban <player>");
	RegAdminCmd("sm_voteban", Command_Voteban, ADMFLAG_VOTE | ADMFLAG_BAN, "sm_voteban <player>");
	
	g_voteTime = CreateConVar("sm_voteban_sbpp_bantime", "60", "Oyuncu yasaklanmasında evet çıkarsa kaç dakika yasaklansın?\nDakika cinsinden yazınız.", 0, true, 1.0, false);
	AutoExecConfig(true, "sbpp_voteban", "ByDexter");
}

public Action Command_Voteban(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_vban <player>");
		return Plugin_Handled;
	}
	
	if (IsVoteInProgress())
	{
		ReplyToCommand(client, "[SM] %t", "Vote in Progress");
		return Plugin_Handled;
	}
	
	char text[256];
	GetCmdArgString(text, sizeof(text));
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	
	if ((target_count = ProcessTargetString(
				text, 
				client, 
				target_list, 
				MAXPLAYERS, 
				COMMAND_FILTER_NO_MULTI | COMMAND_FILTER_NO_BOTS, 
				target_name, 
				sizeof(target_name), 
				tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	DisplayVoteBanMenu(client, target_list[0]);
	
	return Plugin_Handled;
}

void DisplayVoteBanMenu(int client, int target)
{
	g_voteTarget = GetClientUserId(target);
	g_voteAdmin = GetClientUserId(client);
	char name[128];
	GetClientName(target, name, 128);
	Menu menu = new Menu(VoteMenu_callback);
	menu.SetTitle("%s - Yasaklansın mı?\n ", name);
	menu.AddItem("0", "Evet");
	menu.AddItem("1", "Hayır");
	menu.ExitBackButton = false;
	menu.ExitButton = false;
	menu.DisplayVoteToAll(20);
}

public int VoteMenu_callback(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	else if (action == MenuAction_VoteEnd)
	{
		float percent;
		int votes, totalVotes;
		
		GetMenuVoteInfo(param2, votes, totalVotes);
		percent = GetVotePercent(votes, totalVotes);
		
		if (RoundToNearest(100.0 * percent) == 50.0)
		{
			PrintToChatAll("[SM] Oylama sonucu eşit olduğu için %N yasaklanmadı.", GetClientOfUserId(g_voteTarget));
		}
		else
		{
			if (param1 == 0)
			{
				PrintToChatAll("[SM] Oylama sonucu evet çıktığı için %N yasaklanıyor...", GetClientOfUserId(g_voteTarget));
				SBPP_BanPlayer(GetClientOfUserId(g_voteAdmin), GetClientOfUserId(g_voteTarget), g_voteTime.IntValue, "Oylama kararıyla yasaklandı.");
			}
			else if (param1 == 1)
			{
				PrintToChatAll("[SM] Oylama sonucu hayır çıktığı için %N yasaklanmadı.", GetClientOfUserId(g_voteTarget));
			}
		}
	}
}

float GetVotePercent(int votes, int totalVotes)
{
	return float(votes) / float(totalVotes);
} 