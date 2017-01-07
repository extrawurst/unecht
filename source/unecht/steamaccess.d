module unecht.steamaccess;

version(EnableSteam):

import derelict.steamworks.steamworks;

import unecht.core.logger;

import std.conv:to;

///
final class SteamAccess
{
    this()
    {
        setup();
    }

    void setup()
    {
        DerelictSteamworks.load();

        if(!SteamAPI_Init())
            return log.warning("[Steam] client not running");

        client = SteamClient();
            
        if(!client)
            return log.warning("[Steam] could not create client");
            
        clientPipe = SteamAPI_ISteamClient_CreateSteamPipe(client);
            
        if(!clientPipe)
            return log.warning("[Steam] could not create clientPipe");
            
        userPipe = SteamAPI_ISteamClient_ConnectToGlobalUser(client, clientPipe);
            
        if(!userPipe)
            return log.warning("[Steam] could not create userPipe");
            
        utils = SteamAPI_ISteamClient_GetISteamUtils(client, clientPipe, STEAMUTILS_INTERFACE_VERSION);
            
        if(!utils)
            return log.warning("[Steam] could not create utils");

        SteamAPI_ISteamUtils_SetWarningMessageHook(utils, &warnCallback);
            
        screenshots = SteamAPI_ISteamClient_GetISteamScreenshots(client, userPipe, clientPipe, STEAMSCREENSHOTS_INTERFACE_VERSION);
            
        if(!screenshots)
            return log.warning("[Steam] could not create screenshots");

        //TODO is that correct?
        //SteamAPI_ISteamScreenshots_HookScreenshots(screenshots,true);
            
        friends = SteamAPI_ISteamClient_GetISteamFriends(client, userPipe, clientPipe, STEAMFRIENDS_INTERFACE_VERSION);
            
        if(!friends)
            return log.warning("[Steam] could not create friends");

        userName = to!string(SteamAPI_ISteamFriends_GetPersonaName(friends));

        initialized = true;
        log.infof("[Steam] up and running: '%s'",userName);
    }

    void openOverlay(/+string overlay = "Friends"+/)
    {
        if(!initialized) return;

        SteamAPI_ISteamFriends_ActivateGameOverlay(friends, null);
    }

    void triggerScreenshot()
    {
        if(!initialized) return;

        SteamAPI_ISteamScreenshots_TriggerScreenshot(screenshots);
    }

    void update()
    {
        if(!initialized) return;

        SteamAPI_ISteamUtils_RunFrame(utils);
    }

    private static nothrow extern(C) void warnCallback(int severity, const char * str)
    {
        // make nothrow
        try log.warningf("[Steam] Warn: %s (%s)", str, severity);
        catch(Throwable){}
    }

private:
    ISteamFriends* friends;
    ISteamUtils* utils;
    ISteamScreenshots* screenshots;
    ISteamClient* client;
    HSteamPipe clientPipe;
    HSteamPipe userPipe;
    
    bool initialized = false;

    string userName;
}