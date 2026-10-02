
-- https://t.me/ZERO_KALI_AR
local SOCIAL_HALL_CONFIG = {
    ROOM_SCENE_NAME     = "Lobby_Social_CH_Mesh",
    CAMERA_ID           = 10151,                
    DEFAULT_SKIN_ID     = 6680101,             
    DEFAULT_BG_WALL     = 6680200,              
    MONUMENT_ID         = 6680702,              
}


function _G.LoadCollectionHallScene()
    pcall(function()
        if LobbySceneManager and LobbySceneManager.LoadStreamLevel then

            LobbySceneManager.LoadStreamLevel(true, SOCIAL_HALL_CONFIG.ROOM_SCENE_NAME, SOCIAL_HALL_CONFIG.CAMERA_ID, "Lobby_Light")
        end
    end)
end


function _G.SetBehindPlayerBackground(bgItemId)
    pcall(function()
        bgItemId = bgItemId or SOCIAL_HALL_CONFIG.DEFAULT_BG_WALL
        local ModuleManager = require("client.module_framework.ModuleManager")
        if not ModuleManager or not ModuleManager.LobbyModuleConfig then return end
        
        local Logic_SocialLobbyModule = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.Logic_SocialLobbyModule)
        if Logic_SocialLobbyModule then
            local myUid = tonumber(DataMgr.roleData.uid)

            Logic_SocialLobbyModule:SetBGWallPicItemId(myUid, bgItemId)
            

            if EventSystem and EVENTTYPE_LOBBY_SOCIAL and EVENTID_SOCIAL_LOBBY_SLOT_DATA_UPDATE then
                EventSystem:postEvent(EVENTTYPE_LOBBY_SOCIAL, EVENTID_SOCIAL_LOBBY_SLOT_DATA_UPDATE)
            end
        end
    end)
end


function _G.UnlockAllCollectionPlatforms()
    pcall(function()
        local ModuleManager = require("client.module_framework.ModuleManager")
        if not ModuleManager or not ModuleManager.LobbyModuleConfig then return end
        
        local Logic_SocialLobbyModule = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.Logic_SocialLobbyModule)
        if Logic_SocialLobbyModule then

            Logic_SocialLobbyModule.GetSlotIsUnlockBySlotTypeAndIndex = function() return true end
            Logic_SocialLobbyModule.CheckSlotTypeIsUCUnlock = function() return true end
            Logic_SocialLobbyModule.GetSlotIsUnlockedByCollectHallLevel = function() return true end
            

            local Logic_SocialLobbyEditMgrModule = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.Logic_SocialLobbyEditMgrModule)
            if Logic_SocialLobbyEditMgrModule then
                Logic_SocialLobbyEditMgrModule.GetCurIsLatestData = function() return true end
            end
            

            if EventSystem and EVENTTYPE_LOBBY_SOCIAL and EVENTID_SOCIAL_LOBBY_SLOT_DATA_UPDATE then
                EventSystem:postEvent(EVENTTYPE_LOBBY_SOCIAL, EVENTID_SOCIAL_LOBBY_SLOT_DATA_UPDATE)
            end
        end
    end)
end


_G.LoadCollectionHallScene()        
_G.SetBehindPlayerBackground(6680200)
_G.UnlockAllCollectionPlatforms() 
-- https://t.me/ZERO_KALI_AR
