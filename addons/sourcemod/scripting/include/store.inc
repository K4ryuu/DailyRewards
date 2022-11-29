#if defined _store_included
	#endinput
#endif
#define _store_included

//int g_cvarChatTag = -1;

#define ITEM_NAME_LENGTH 64
#define STORE_MAX_ITEMS 2048
#define STORE_MAX_HANDLERS 64
#define STORE_MAX_PLANS 8
#define STORE_MAX_SLOTS 4

public Extension __ext_store_sm =
{
	name = "Store - The Resurrection",
	file = "store_sm.ext",
#if defined AUTOLOAD_EXTENSIONS
	autoload = 1,
#else
	autoload = 0,
#endif

#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

/*
enum eTags
{
	NameTag,
	TagColor,
	NameColor,
	MessageColor
}

enum Item_Plan
{
	String:szName[ITEM_NAME_LENGTH],
	iPrice,
	iTime
}

enum Store_Item
{
	String:szName[ITEM_NAME_LENGTH],
	String:szUniqueId[PLATFORM_MAX_PATH],
	String:szShortcut[64],
	iId,
	iPrice,
	iParent,
	iHandler,
	iFlagBits,
	iData,
	iPlans,
	bool:bPreview;
	bool:bBuyable,
	bool:bIgnoreVIP,
	Handle:hAttributes
}

enum Type_Handler
{
	String:szType[64],
	String:szUniqueKey[32],
	bool:bEquipable,
	bool:bRaw,
	Handle:hPlugin,
	Function:fnMapStart,
	Function:fnReset,
	Function:fnConfig,
	Function:fnUse,
	Function:fnRemove
}

enum Client_Item
{
	iId,
	iUniqueId,
	bool:bSynced,
	bool:bDeleted,
	iDateOfPurchase,
	iDateOfExpiration,
	iPriceOfPurchase,
}

enum SkinData_t
{
    String:m_Name[ITEM_NAME_LENGTH],
    String:m_UId[32],
    String:m_Skin[128],
    String:m_Arms[128]
}


enum struct eTags
{
	int NameTag;
	int TagColor;
	int NameColor;
	int MessageColor;
}
*/

enum struct Item_Plan
{
	char szName[ITEM_NAME_LENGTH];
	int iPrice;
	int iTime;
}

enum struct Store_Item
{
	char szName[ITEM_NAME_LENGTH];
	char szUniqueId[PLATFORM_MAX_PATH];
	char szShortcut[64];
	int iId;
	int iPrice;
	int iParent;
	int iHandler;
	int iFlagBits;
	int iData;
	int iPlans;
	bool bPreview;
	bool bBuyable;
	bool bIgnoreVIP;
	Handle hAttributes;
}

enum struct Type_Handler
{
	char szType[64];
	char szUniqueKey[32];
	bool bEquipable;
	bool bRaw;
	Handle hPlugin;
	Function fnMapStart;
	Function fnReset;
	Function fnConfig;
	Function fnUse;
	Function fnRemove;
}

enum struct Client_Item
{
	int iId;
	int iUniqueId;
	bool bSynced;
	bool bDeleted;
	int iDateOfPurchase;
	int iDateOfExpiration;
	int iPriceOfPurchase;
}

enum struct SkinData_t
{
	char m_Name[ITEM_NAME_LENGTH];
	char m_UId[32];
	char m_Skin[128];
    char m_Arms[128];
}

native int Store_RegisterHandler(char[] type, char[] uniquekey, Function mapstart, Function reset, Function config, Function use, Function remove, bool equipable = true, bool raw = false);
native int Store_RegisterMenuHandler(char[] identifier, Function menu, Function handler);
native void Store_SetDataIndex(int itemid, int index);
native int Store_GetDataIndex(itemid);
native int Store_GetEquippedItem(int client, char[] type, int slot=0);
native bool Store_IsClientLoaded(int client);
native void Store_DisplayPreviousMenu(int client);
native void Store_SetClientMenu(int client, int num);
native int Store_GetClientCredits(int client);
native int Store_SetClientCredits(int client, int credits);
native int Store_AddClientCredits(int client, int credits);
native bool Store_IsClientVIP(int client);
native bool Store_IsItemInBoughtPackage(int client, int itemid, int uid=-1);
native void Store_DisplayConfirmMenu(int client, char[] title, Function callback, any data);
native bool Store_ShouldConfirm();
native void Store_GetItem(int itemid, any output[sizeof(Store_Item)]);
native void Store_GetHandler(int index, any output[sizeof(Type_Handler)]);
native void Store_GiveItem(int client, int itemid, int purchase=0, int expiration=0, int price=0);
native void Store_RemoveItem(client, itemid);
native int Store_GetClientItem(int client, int itemid, any output[sizeof(Client_Item)]);
native int Store_GetClientTarget(int client);
native int Store_GiveClientItem(int client, int recipient, int itemid);
native bool Store_HasClientItem(int client, int itemid);
native int Store_IterateEquippedItems(int client, int &start, bool attributes=false);
//native int Store_GetClientTag(int client, any TagType[sizeof(eTags)], char[] buffer, intmaxlength);
native bool Store_HasPlayerSkin(int client);
native bool Store_GetPlayerSkin(int client, char[] model, int size);
native bool Store_GetClientPlayerSkins(int client, ArrayList array);

forward void Store_OnClientModelChanged(int client, char[] model);