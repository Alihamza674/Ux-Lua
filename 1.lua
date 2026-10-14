-- ==============================================================================
-- ACE Interceptor - All PUBG Mobile Versions (No China)
-- Global: com.tencent.ig | Korea: com.pubg.krmobile | Vietnam: com.vng.pubgmobile
-- Taiwan: com.rekoo.pubgm | BGMI (India): com.pubg.imobile
-- ==============================================================================

local blockHosts = {
    "anti-cheat.tencent.com", "game-security.qq.com", "tmgp-anti.com",
    "check.tencent.com", "down.anticheatexpert.com", "anticheatexpert.com",
    "tmgp.qq.com", "pubgmobile.com", "tencentgames.com", "qcloud.com",
    "myqcloud.com", "tencentcloudapi.com"
}

local function isBlocked(host)
    if not host then return false end
    local h = host:lower()
    for _, v in ipairs(blockHosts) do
        if h:find(v) then return true end
    end
    return false
end

function filterRequest(req)
    if not req or not req.host then return req end
    if isBlocked(req.host) then return {code = 200, body = ""} end
    return req
end

print("[ACE] Interceptor loaded - All PUBG versions (Global/KR/VN/TW/BGMI)")

-- ==========================================
-- 🔥 AK_Features — SABSE PEHLE
-- ==========================================
_G.AK_Features = {
    { id="ESP_HP", val=0 }, { id="ESP_NAME", val=0 }, { id="ESP_DISTANCE", val=0 },
    { id="ESP_ANTENNA", val=0 }, { id="ESP_RADAR", val=0 },
    { id="COUNT_ENEMY", val=0 }, { id="WALL_HACK", val=0 }, { id="ENEMY_WEAPON", val=0 },
    { id="WALL_COLOR_VISIBLE", val=1 },
    { id="WALL_COLOR_BEHIND",  val=2 },
    { id="OUTLINE_ESP", val=0 }, { id="OUTLINE_COLOR", val=4 }, { id="OUTLINE_THICK", val=5 },
    { id="ITEMS_MASTER", val=0 },
    { id="ITEM_AR", val=0 }, { id="ITEM_SMG", val=0 }, { id="ITEM_SNIPER", val=0 },
    { id="ITEM_SHOTGUN", val=0 }, { id="ITEM_LMG", val=0 }, { id="ITEM_PISTOL", val=0 },
    { id="ITEM_MELEE", val=0 }, { id="ITEM_SPECIAL", val=0 }, { id="ITEM_SCOPE", val=0 },
    { id="ITEM_GRENADE", val=0 }, { id="ITEM_MED", val=0 },
    { id="VEH_MASTER", val=0 },
    { id="VEH_DACIA", val=0 }, { id="VEH_UAZ", val=0 }, { id="VEH_BUGGY", val=0 },
    { id="VEH_COUPE", val=0 }, { id="VEH_MIRADO", val=0 }, { id="VEH_MOTOR", val=0 },
    { id="VEH_BRDM", val=0 }, { id="VEH_BOAT", val=0 }, { id="VEH_OTHER", val=0 },
    { id="WALL_VEHICLE", val=0 },
    { id="AIMBOT", val=0 }, { id="AIMBOT_MODE", val=3 },
    { id="AIMBOT_FOV", val=25 }, { id="AIMBOT_SPEED", val=50 },
    { id="AIMBOT_BONE", val=1 }, { id="AIMBOT_DIST", val=250 },
    { id="RECOIL_COMP", val=0 }, { id="RECOIL_VAL", val=5 },
    { id="AIM_CIRCLE", val=0 },
    { id="AIM_CIRCLE_X", val=0 },                        -- 👈 NEW
    { id="AIM_CIRCLE_Y", val=0 },                        -- 👈 NEW
    { id="ESP_LOAI9", val=0 }, { id="ESP9_COUNT", val=0 }, { id="ESP9_NAME", val=0 },
    { id="ESP9_HP", val=0 }, { id="ESP9_TEAM", val=0 }, { id="ESP9_WEAPON", val=0 },
    { id="ESP9_DISTANCE", val=0 }, { id="ESP9_LINE", val=0 }, { id="ESP9_SKELETON", val=0 },
    { id="CROSSHAIR", val=0 }, { id="BLACK_SKY", val=0 },
    { id="REMOVE_GRASS", val=0 }, { id="REMOVE_TREES", val=0 }, { id="REMOVE_FOG", val=0 },
    { id="IPAD_VIEW", val=0 }, { id="IPAD_FOV", val=120 },
}

function _G.AK_GetVal(id)
    if not _G.AK_Features then return 0 end
    for _, f in ipairs(_G.AK_Features) do
        if f.id == id then return f.val end
    end
    return 0
end

_G.GetConfigPath = function()
    local packages = { 
        "com.tencent.ig", 
        "com.pubg.krmobile", 
        "com.vng.pubgmobile", 
        "com.rekoo.pubgm", 
        "com.pubg.imobile",
        "com.tencent.igfit"
    }
    
    -- ✅ Priority 1: Jis folder me reload.flag hai, wahi selected package hai
    for _, pkg in ipairs(packages) do
        local flagPath = "/storage/emulated/0/Android/data/" .. pkg .. "/files/reload.flag"
        local ff = io.open(flagPath, "r")
        if ff then
            ff:close()
            local path = "/storage/emulated/0/Android/data/" .. pkg .. "/files/SKIN_OP_MENU.ini"
            local f = io.open(path, "r")
            if f then f:close(); return path end
        end
    end
    
    -- Priority 2: Normal loop
    for _, pkg in ipairs(packages) do
        local path = "/storage/emulated/0/Android/data/" .. pkg .. "/files/SKIN_OP_MENU.ini"
        local f = io.open(path, "r")
        if f then f:close(); return path end
    end
    
    return '/storage/emulated/0/Android/data/com.tencent.ig/files/SKIN_OP_MENU.ini'
end
_G.ConfigFilePath = _G.GetConfigPath()

_G.g_rayansyed = _G.g_rayansyed or "@rayansyed"
_G.g_rayansyed_MasterShotESP = _G.g_rayansyed_MasterShotESP or {
    Enabled = false, ShowCounter = false, ShowName = false, ShowDistance = false, ShowLine = false,
    MaxRangeMeters = 400.0, ScanInterval = 0.60, UpdateInterval = 0.033, TransformInterval = 0.50,
    MaxRendered = 12, CounterY = 36.0, CounterWidth = 188.0, CounterHeight = 26.0,
    CounterDiamondSize = 20.0, TracerThickness = 1.80,
    NameGap = 2.0, NameFontSize = 10, DistanceFontSize = 8, DistanceBelowFeet = 8.0,
}
_G.MasterShotESP = _G.g_rayansyed_MasterShotESP
_G.LexusConfig = _G.LexusConfig or {}

function _G.SyncLexusConfig()
    if not _G.g_rayansyed_MasterShotESP then return end
    _G.g_rayansyed_MasterShotESP.Enabled      = (_G.AK_GetVal("ESP_LOAI9") == 1)
    _G.g_rayansyed_MasterShotESP.ShowCounter  = (_G.AK_GetVal("ESP9_COUNT") == 1)
    _G.g_rayansyed_MasterShotESP.ShowName     = (_G.AK_GetVal("ESP9_NAME") == 1)
    _G.g_rayansyed_MasterShotESP.ShowDistance = (_G.AK_GetVal("ESP9_DISTANCE") == 1)
    _G.g_rayansyed_MasterShotESP.ShowLine     = (_G.AK_GetVal("ESP9_LINE") == 1)
    local forceOldEspOff = _G.g_rayansyed_MasterShotESP.Enabled
    _G.LexusConfig.OutlineEsp   = (_G.AK_GetVal("OUTLINE_ESP") == 1)
    _G.LexusConfig.OutlineColor = _G.AK_GetVal("OUTLINE_COLOR")
    _G.LexusConfig.OutlineThick = _G.AK_GetVal("OUTLINE_THICK")
    _G.LexusConfig.EnemyWeapon  = (_G.AK_GetVal("ENEMY_WEAPON") == 1)
    if forceOldEspOff then _G.LexusConfig.EnemyWeapon = false end
    _G.LexusConfig.ItemsMaster = (_G.AK_GetVal("ITEMS_MASTER") == 1)
    _G.LexusConfig.ItemAR      = (_G.AK_GetVal("ITEM_AR") == 1)
    _G.LexusConfig.ItemSMG     = (_G.AK_GetVal("ITEM_SMG") == 1)
    _G.LexusConfig.ItemSniper  = (_G.AK_GetVal("ITEM_SNIPER") == 1)
    _G.LexusConfig.ItemShotgun = (_G.AK_GetVal("ITEM_SHOTGUN") == 1)
    _G.LexusConfig.ItemLMG     = (_G.AK_GetVal("ITEM_LMG") == 1)
    _G.LexusConfig.ItemPistol  = (_G.AK_GetVal("ITEM_PISTOL") == 1)
    _G.LexusConfig.ItemMelee   = (_G.AK_GetVal("ITEM_MELEE") == 1)
    _G.LexusConfig.ItemSpecial = (_G.AK_GetVal("ITEM_SPECIAL") == 1)
    _G.LexusConfig.ItemScope   = (_G.AK_GetVal("ITEM_SCOPE") == 1)
    _G.LexusConfig.ItemGrenade = (_G.AK_GetVal("ITEM_GRENADE") == 1)
    _G.LexusConfig.ItemMed     = (_G.AK_GetVal("ITEM_MED") == 1)
    _G.LexusConfig.VehMaster   = (_G.AK_GetVal("VEH_MASTER") == 1)
    _G.LexusConfig.VehDacia    = (_G.AK_GetVal("VEH_DACIA") == 1)
    _G.LexusConfig.VehUAZ      = (_G.AK_GetVal("VEH_UAZ") == 1)
    _G.LexusConfig.VehBuggy    = (_G.AK_GetVal("VEH_BUGGY") == 1)
    _G.LexusConfig.VehCoupe    = (_G.AK_GetVal("VEH_COUPE") == 1)
    _G.LexusConfig.VehMirado   = (_G.AK_GetVal("VEH_MIRADO") == 1)
    _G.LexusConfig.VehMotor    = (_G.AK_GetVal("VEH_MOTOR") == 1)
    _G.LexusConfig.VehBRDM     = (_G.AK_GetVal("VEH_BRDM") == 1)
    _G.LexusConfig.VehBoat     = (_G.AK_GetVal("VEH_BOAT") == 1)
    _G.LexusConfig.VehOther    = (_G.AK_GetVal("VEH_OTHER") == 1)
    _G.LexusConfig.WallVehicle = (_G.AK_GetVal("WALL_VEHICLE") == 1)
    _G.LexusConfig.RemoveGrass = (_G.AK_GetVal("REMOVE_GRASS") == 1)
    _G.LexusConfig.RemoveTrees = (_G.AK_GetVal("REMOVE_TREES") == 1)
    _G.LexusConfig.RemoveFog   = (_G.AK_GetVal("REMOVE_FOG") == 1)
end

_G._AK_LastMTime = 0
_G._AK_LastCheck = 0

local function GetFileMTime(path)
    local f = io.open(path, "r")
    if not f then return 0 end
    local ok, mtime = pcall(function()
        local lfs = package.loaded["lfs"] or require("lfs")
        if lfs then return lfs.attributes(path, "modification") or 0 end
        return 0
    end)
    f:close()
    if ok and mtime and mtime > 0 then return mtime end
    local f2 = io.open(path, "r")
    if f2 then
        local content = f2:read("*a")
        f2:close()
        return #(content or "")
    end
    return 0
end

function _G.AK_LoadINI(force)
    local configPath = _G.GetConfigPath()
    local file = io.open(configPath, "r")
    if not file then return false end
    local changed = false
    for line in file:lines() do
        local key, value = line:match('^([%w_]+)%s*=%s*(%d+)$')
        if key and value then
            local val = tonumber(value)
            if val ~= nil then
                for _, f in ipairs(_G.AK_Features) do
                    if f.id == key then
                        if f.val ~= val or force then
                            f.val = val
                            changed = true
                        end
                        break
                    end
                end
            end
        end
    end
    file:close()
    if changed or force then
        if _G.SyncLexusConfig then pcall(_G.SyncLexusConfig) end
        -- 🎨 Force wall color refresh on config change (turant color badle)
        if _G.KASHMIRYState and _G.KASHMIRYState.EnemyMarks then
            for _, md in pairs(_G.KASHMIRYState.EnemyMarks) do
                md.LastColorHash = ""
                md.LastHiddenState = nil
                md.LastColorIdx = nil  -- 👈 ADD THIS
                md.DepthTestApplied = false
            end
        end
    end
    return changed
end

function _G.AK_CheckINIReload()
    local now = os.clock()
    if now - _G._AK_LastCheck < 0.5 then return end
    _G._AK_LastCheck = now
    local configPath = _G.GetConfigPath()
    local gameDir = configPath:match("^(.*)/files/")
    if not gameDir then return end
    local reloadFlagPath = gameDir .. "/files/reload.flag"
    local rf = io.open(reloadFlagPath, "r")
    if rf then
        rf:close()
        _G.AK_LoadINI(true)
        pcall(function()
            local df = io.open(reloadFlagPath, "w")
            if df then df:write("0"); df:close() end
        end)
        pcall(function() os.remove(reloadFlagPath) end)
        return
    end
    local mtime = GetFileMTime(configPath)
    if mtime ~= _G._AK_LastMTime and _G._AK_LastMTime ~= 0 then
        _G.AK_LoadINI(true)
    end
    _G._AK_LastMTime = mtime
end

-- ==========================================
-- BRPlayerCharacterBase (RPC definitions + imports)
-- ==========================================
local ENetRole = import("ENetRole")
local EPawnState = import("EPawnState")
local ESpecialMovementType = import("ESpecialMovementType")
local ESpiderSwingMoveState = import("ESpiderSwingMoveState")
local ESurviveWeaponPropSlot = import("ESurviveWeaponPropSlot")
local EParachuteState = import("EParachuteState")
local EMovementMode = import("EMovementMode")
local EStateType = import("EStateType")
local ESTEPoseState = import("ESTEPoseState")
local EGameModeType = import("EGameModeType")
local STExtraGameStateBase = import("STExtraGameStateBase")
local UKismetSystemLibrary = import("KismetSystemLibrary")
local USTExtraBlueprintFunctionLibrary = import("STExtraBlueprintFunctionLibrary")
local GameplayData = require("GameLua.GameCore.Data.GameplayData")
local GamePlayTools = require("GameLua.Mod.BaseMod.Common.GamePlayTools")
local MatchModeIds = require("GameLua.Mod.BaseMod.GamePlay.Config.MatchModeIdsConfig")

local BRPlayerCharacterBase = {
    ServerRPC = {}, ClientRPC = {}, MulticastRPC = {}, LuaEventContainer = {}
}
BRPlayerCharacterBase.ServerRPC.ServerRPC_NearDeathGiveupRescue = { Reliable = true, Params = {} }
BRPlayerCharacterBase.ServerRPC.ServerRPC_CarryDeadBox = { Reliable = true, Params = { UEnums.EPropertyClass.Object } }
BRPlayerCharacterBase.ServerRPC.RPC_Server_GmPlayAction = { Reliable = true, Params = { UEnums.EPropertyClass.Int } }
BRPlayerCharacterBase.MulticastRPC.MulticastRPC_GmPlayAction = { Reliable = true, Params = { UEnums.EPropertyClass.Int } }
BRPlayerCharacterBase.ClientRPC.RPC_Client_SetShouldCheckPassWall = { Reliable = true, Params = { UEnums.EPropertyClass.Bool } }
BRPlayerCharacterBase.ClientRPC.ClientRPC_TriggerHighlightMoment = { Reliable = true, Params = { UEnums.EPropertyClass.UInt32, UEnums.EPropertyClass.UInt32 } }

function BRPlayerCharacterBase:ctor() end
function BRPlayerCharacterBase:_PostConstruct()
    BRPlayerCharacterBase.__super._PostConstruct(self)
    self:InitAddSpecialMoveInfo()
    self.bCanNearDeathGiveup = true
end
function BRPlayerCharacterBase:ReceiveBeginPlay()
    BRPlayerCharacterBase.__super.ReceiveBeginPlay(self)
    self:AddControlEvent(self, "MovementModeChangedDelegate", self.HandleOnMovementModeChangedNew, self)
    if self:HasAuthority() and self:CheckAddCheckFallingDistanceComponent() then
        local CheckFallingDistanceComponent_C = import("CheckFallingDistanceComponent")
        if slua.isValid(CheckFallingDistanceComponent_C) and not slua.isValid(self:GetComponentByClass(CheckFallingDistanceComponent_C)) then
            Game:AddComponent(CheckFallingDistanceComponent_C, self, "CheckFallingDistanceComponent")
        end
    end
    if slua.isValid(self.STCharacterMovement) then self.STCharacterMovement.bPositiveBlowUp = true end
    if self.Role == ENetRole.ROLE_AutonomousProxy then
        self:AddControlEvent(self, "OnPawnStateDisabled", self.OnPawnStateChange, self)
        self:AddControlEvent(self, "OnPawnStateEnabled", self.OnPawnStateChange, self)
        self:AddControlEventConditionOnly(self, "OnAttrChangeEventDelegate", { AttrName = { "bCanSelfRescue" } }, self.CharacterAttrChangeEvent, self)
    end
    if Client then
        GameplayData.AddCharacter(self.Object)
        self:AddControlEvent(self, "OnAttachedToVehicle", self.HandleOnAttachedToVehicle, self)
        self:AddControlEvent(self, "OnDetachedFromVehicle", self.HandleOnDetachedFromVehicle, self)
    else
        self:AddCommonEventWithConditions(EVENTTYPE_INGAME_NORMAL, EVENTID_GAME_MODE_STATE_CHANGE, { [1] = "FinishedState" }, self.HandleFinishedState, self)
    end
end
function BRPlayerCharacterBase:HandleOnAttachedToVehicle(uVehicle)
    if not slua.isValid(uVehicle) then return end
    if self.Role == ENetRole.ROLE_SimulatedProxy then
        self:ClearAttachToVehicleTimer()
        self.nUpdatePlayerAttachToVehicleCount = 0
        self.nUpdatePlayerAttachToVehicleTimer = self:AddGameTimer(5, true, function()
            if slua.isValid(self.Object) and slua.isValid(uVehicle) then self:UpdatePlayerAttachToVehicle(uVehicle) end
        end)
    end
end
function BRPlayerCharacterBase:HandleOnDetachedFromVehicle(uLastVehicle)
    if not slua.isValid(uLastVehicle) then return end
    if self.Role == ENetRole.ROLE_SimulatedProxy then
        self:ClearAttachToVehicleTimer()
        self.nUpdatePlayerAttachToVehicleCount = 0
    end
end
function BRPlayerCharacterBase:UpdatePlayerAttachToVehicle(uVehicle) end
function BRPlayerCharacterBase:FixMeshContainerOffsetIfNeeded(uVehicle) end
function BRPlayerCharacterBase:ClearAttachToVehicleTimer()
    if self.nUpdatePlayerAttachToVehicleTimer then
        self:RemoveGameTimer(self.nUpdatePlayerAttachToVehicleTimer)
        self.nUpdatePlayerAttachToVehicleTimer = nil
    end
    if self.nFixMeshContainerTimer then
        self:RemoveGameTimer(self.nFixMeshContainerTimer)
        self.nFixMeshContainerTimer = nil
    end
end
function BRPlayerCharacterBase:CharacterAttrChangeEvent(uPawn, AttrName, AttrVal)
    BRPlayerCharacterBase.__super.CharacterAttrChangeEvent(self, uPawn, AttrName, AttrVal)
    if self.Object ~= uPawn then return end
    if self.Role == ENetRole.ROLE_AutonomousProxy and AttrName == "bCanSelfRescue" then
        local uPlayerController = self:GetPlayerControllerSafety()
        if slua.isValid(uPlayerController) then
            uPlayerController:BroadcastUIMessage("UIMsg_CanSelfRescue", 0, "", "")
        end
    end
end
function BRPlayerCharacterBase:OnPawnStateChange(PawnState)
    if PawnState == EPawnState.SwitchPP then
        local uPlayerController = self:GetPlayerControllerSafety()
        if slua.isValid(uPlayerController) then
            uPlayerController:BroadcastUIMessage("UIMsg_FPPModeChange", 0, "", "")
        end
    end
end
function BRPlayerCharacterBase:HandleFinishedState()
    if slua.isValid(self.STCharacterMovement) and self.STCharacterMovement.SetDynamicSimpleQueryConfigDisable then
        local EDynamicSimpleQueryConfigDisableMask = import("EDynamicSimpleQueryConfigDisableMask")
        self.STCharacterMovement:SetDynamicSimpleQueryConfigDisable(EDynamicSimpleQueryConfigDisableMask.Bit0, true)
    end
end
function BRPlayerCharacterBase:CheckAddCheckFallingDistanceComponent()
    if CGameMode and CGameMode.GameModeType and CGameState and CGameState.GameModeID then
        local GameModeType = CGameMode.GameModeType
        local GameModeID = tonumber(CGameState.GameModeID)
        local bModeTypeSatisfy = GameModeType == EGameModeType.ETypicalGameMode or GameModeType == EGameModeType.EFourInOneGameMode or GameModeType == EGameModeType.EHeavyWeaponGameMode
        local bModeIDSatisfy = not MatchModeIds[GameModeID]
        return bModeTypeSatisfy and bModeIDSatisfy
    end
    return false
end
function BRPlayerCharacterBase:LuaHandleParachuteStateChanged(LastParachuteState, NewParachuteState)
    BRPlayerCharacterBase.__super.LuaHandleParachuteStateChanged(self, LastParachuteState, NewParachuteState)
    if not Client then
        local uCurrentPlayerControl = self:GetPlayerControllerSafety()
        if slua.isValid(uCurrentPlayerControl) and uCurrentPlayerControl.CheckParachuteOpenFeature then
            if NewParachuteState == EParachuteState.PS_Opening then
                if uCurrentPlayerControl.CheckParachuteOpenFeature.SatrtCheckShowParachuteCloseUI then
                    uCurrentPlayerControl.CheckParachuteOpenFeature:SatrtCheckShowParachuteCloseUI()
                end
            elseif NewParachuteState == EParachuteState.PS_None then
                if uCurrentPlayerControl.CheckParachuteOpenFeature.RecoverParachuteOpenParam then
                    uCurrentPlayerControl.CheckParachuteOpenFeature:RecoverParachuteOpenParam()
                end
                if uCurrentPlayerControl.CheckParachuteOpenFeature.ClearTimerAndState then
                    uCurrentPlayerControl.CheckParachuteOpenFeature:ClearTimerAndState()
                end
            end
        end
    end
end
function BRPlayerCharacterBase:OnLanded()
    if self.HandleOnLanded then self:HandleOnLanded(-1) end
    if not Client then
        local uCurrentPlayerControl = self:GetPlayerControllerSafety()
        if slua.isValid(uCurrentPlayerControl) and uCurrentPlayerControl.CheckParachuteOpenFeature then
            if uCurrentPlayerControl.CheckParachuteOpenFeature.ClearTimerAndState then
                uCurrentPlayerControl.CheckParachuteOpenFeature:ClearTimerAndState()
            end
            if uCurrentPlayerControl.CheckParachuteOpenFeature.ResetCheckShowUI then
                uCurrentPlayerControl.CheckParachuteOpenFeature:ResetCheckShowUI()
            end
        end
    end
end
function BRPlayerCharacterBase:ReceiveEndPlay(EndPlayReason)
    BRPlayerCharacterBase.__super.ReceiveEndPlay(self, EndPlayReason)
    if Client then GameplayData.RemoveCharacter(self.Object) end
end
function BRPlayerCharacterBase:IsWarGameMode()
    local uGameState = GameplayData:GetGameState()
    if slua.isValid(uGameState) and Game:IsClassOf(uGameState, STExtraGameStateBase) then
        return uGameState.GameModeType == EGameModeType.EWarGameMode
    end
    return false
end
function BRPlayerCharacterBase:BPOnRecycled() if Client then self:ResetMeshRelativeLocationAndRotation() end end
function BRPlayerCharacterBase:BPOnRespawned() if Client then self:ResetMeshRelativeLocationAndRotation() end end
function BRPlayerCharacterBase:ReceiveOnRecycle()
    if Client then
        self:ResetMeshRelativeLocationAndRotation()
        GameplayData.RemoveCharacter(self.Object)
    end
end
function BRPlayerCharacterBase:ReceiveOnSpawn()
    if Client then
        self:ResetMeshRelativeLocationAndRotation()
        GameplayData.AddCharacter(self.Object)
    end
end
function BRPlayerCharacterBase:ResetMeshRelativeLocationAndRotation()
    if Game:IsValid(self.Object) and Game:IsValid(self.Mesh) then
        local uDefaultMeshRot = FRotator(0, -90, 0)
        local uDefaultMeshRelativeLoc = FVector(0, 0, 0)
        if self.Mesh.K2_SetRelativeRotation then
            self.Mesh:K2_SetRelativeRotation(uDefaultMeshRot, false, nil, false)
        end
        self:CacheInitialMeshOffset(uDefaultMeshRelativeLoc, uDefaultMeshRot)
    end
end
function BRPlayerCharacterBase:HandleOnMovementModeChangedNew()
    if Game:IsValid(self.STCharacterMovement) and self.STCharacterMovement.MovementMode == EMovementMode.MOVE_Swimming and self:CheckBaseIsMoveable() then
        self.CharacterMovement:SetBase(nil, "", true)
    end
    if self.Role == ENetRole.ROLE_AutonomousProxy and Game:IsValid(self.STCharacterMovement) and self.STCharacterMovement.MovementMode == EMovementMode.MOVE_Walking and UIManager.UI_Config_InGame.ParachuteOpenUI then
        UIManager.CloseUI(UIManager.UI_Config_InGame.ParachuteOpenUI)
    end
end
function BRPlayerCharacterBase:BPOnMissPlayerDamageRecord() end
function BRPlayerCharacterBase:PreAttachedToVehicle()
    local IsDS = UKismetSystemLibrary.IsDedicatedServer(self)
    if not IsDS then return end
    local MainPlayerController = self:GetPlayerControllerSafety()
    if not slua.isValid(MainPlayerController) then return end
    local CharacterAvatarComp2_BP = self.CharacterAvatarComp2_BP
    if not slua.isValid(CharacterAvatarComp2_BP) then return end
    local CommerAvatarDataUtil = require("GameLua.Activity.Commercialize.GamePlay.CommerAvatarDataUtil")
    local changedVehicleId = CommerAvatarDataUtil:ChangeVehicleSkinByClothes(MainPlayerController, CharacterAvatarComp2_BP)
    local ESTExtraVehicleShapeType = import("ESTExtraVehicleShapeType")
    if changedVehicleId then
        local UAvatarUtils = import("AvatarUtils")
        if UAvatarUtils.GetVehicleShapeBySkinID(changedVehicleId) == ESTExtraVehicleShapeType.VST_Horse then
            local uCurPlayerState = self:GetPlayerStateSafety()
            if slua.isValid(uCurPlayerState) then uCurPlayerState:AddGeneralCount(468, 1, false) end
        end
    end
end
function BRPlayerCharacterBase:ParachuteJump()
    local uPlayerController = self:GetControllerSafety()
    if slua.isValid(uPlayerController) then
        if not self:GetEnsure() then
            if uPlayerController:GetCurrentStateType() ~= EStateType.State_ParachuteJump and uPlayerController:GetCurrentStateType() ~= EStateType.State_ParachuteOpen then
                self:SwitchPoseState(ESTEPoseState.Stand, true, true, true, false)
                uPlayerController:ReInitParachuteItem()
                uPlayerController:ServerChangeStatePC(EStateType.State_ParachuteJump)
            end
        else
            EventSystem:postEvent(EVENTTYPE_INGAME_NORMAL, EVENTID_AI_CALL_PARACHUTE_JUMP, self.Object)
        end
    end
end
function BRPlayerCharacterBase:OnMovementBaseChangedEvent(uCharacter, uNewMovementBase, uOldMovementBase)
    if uCharacter ~= self.Object then return end
    local MedievalCrane = self:GetMedievalCraneFromBase(uNewMovementBase)
    if MedievalCrane and MedievalCrane.AddCharacter then
        MedievalCrane:AddCharacter(self.Object)
    else
        MedievalCrane = self:GetMedievalCraneFromBase(uOldMovementBase)
        if MedievalCrane and MedievalCrane.RemoveCharacter then
            MedievalCrane:RemoveCharacter(self.Object)
        end
    end
end
function BRPlayerCharacterBase:GetMedievalCraneFromBase(Base)
    if not slua.isValid(Base) or not Base.GetOwner then return end
    local Lifter = Base:GetOwner()
    if not slua.isValid(Lifter) then return end
    if not Lifter.AddCharacter then return end
    return Lifter
end
function BRPlayerCharacterBase:CheckForbidFlaregun()
    local uPlayerState = self:GetPlayerStateSafety()
    if not slua.isValid(uPlayerState) then return false end
    if uPlayerState.CanUseFlaregun == false and self:IsLocallyControlled() then
        local uPlayerController = self:GetPlayerControllerSafety()
        if slua.isValid(uPlayerController) then uPlayerController:DisplayGameTipWithMsgID(48532) end
    end
    return not uPlayerState.CanUseFlaregun
end
function BRPlayerCharacterBase:ServerRPC_NearDeathGiveupRescue() self:HandleNearDeathGiveupRescue() end
function BRPlayerCharacterBase:HandleNearDeathGiveupRescue()
    local uNearDeathComp = self.NearDeatchComponent
    if self:IsNearDeath() and slua.isValid(uNearDeathComp) and self.bCanNearDeathGiveup == true then
        local uPlayerState = self:GetPlayerStateSafety()
        if slua.isValid(uPlayerState) then uPlayerState:AddGeneralCount(1613, 1, false) end
        uNearDeathComp:TriggerGotoDieExplictly(self.Object)
    end
end
function BRPlayerCharacterBase:RPC_Server_GmPlayAction(actionId)
    if USTExtraBlueprintFunctionLibrary.IsDevelopment() then self:MulticastRPC_GmPlayAction(actionId) end
end
function BRPlayerCharacterBase:MulticastRPC_GmPlayAction(actionId)
    if not Client then return end
    local uPlayEmoteComp = self:GetPlayEmoteComponent()
    if not slua.isValid(uPlayEmoteComp) then return end
    local animCfg = CDataTable.GetTableData("EmoteBPTable", actionId)
    if not animCfg then return end
    local EmoteHandleAsset = slua.loadObject(animCfg.Path)
    local assetsArray = slua.Array(UEnums.EPropertyClass.Struct, import("/Script/CoreUObject.SoftObjectPath"))
    local handle = EmoteHandleAsset()
    uPlayEmoteComp:OnLoadEmoteAssetBegin(handle, actionId, assetsArray, "")
    local tb = FuncUtil.LuaArrayToTable(assetsArray)
    local asset_util = require("common.asset_util")
    local loadLater = function() uPlayEmoteComp:OnLoadEmoteAssetEnd(handle, actionId, 0) end
    asset_util.GetAssetsArrayAsyncParallel(tb, loadLater)
end
function BRPlayerCharacterBase:RPC_Client_SetShouldCheckPassWall(bServerSyncShouldCheckPassWall)
    if slua.isValid(self.ParachuteComponent) then
        self.ParachuteComponent.bServerSyncShouldCheckPassWall = bServerSyncShouldCheckPassWall
    end
end
function BRPlayerCharacterBase:OnPlayerEnterCarryBoxState()
    self.Super:OnPlayerEnterCarryBoxState()
    if self.CarryDeadBoxFeature then self.CarryDeadBoxFeature:OnPlayerEnterCarryBoxState() end
end
function BRPlayerCharacterBase:OnPlayerLeaveCarryBoxState(bInIsInterrupt)
    self.Super:OnPlayerLeaveCarryBoxState(bInIsInterrupt)
    if self.CarryDeadBoxFeature then self.CarryDeadBoxFeature:OnPlayerLeaveCarryBoxState(bInIsInterrupt) end
end
function BRPlayerCharacterBase:ServerRPC_CarryDeadBox(uInDeadBox)
    if slua.isValid(uInDeadBox) and Game:IsClassOf(uInDeadBox, import("/Script/ShadowTrackerExtra.PlayerTombBox")) and self.CarryDeadBoxFeature then
        self.CarryDeadBoxFeature:CarryDeadBox(uInDeadBox)
    end
end
function BRPlayerCharacterBase:SetAreaID(AreaID) self:SetAttrValue("AreaID", AreaID, -1) end
function BRPlayerCharacterBase:GetAreaID() return math.floor(self:GetAttrValue("AreaID") + 0.5) end
function BRPlayerCharacterBase:CannotChangeIntoPetSpectator() return self.bCannotChangeIntoPetSpectator end
function BRPlayerCharacterBase:DoModChangeToBT()
    if self:HasState(EPawnState.SpecialSuit) then self:TriggerEntrySkillWithID(4301101, true) end
end
function BRPlayerCharacterBase:SwitchCameraToParachuteOpening()
    self.Super:SwitchCameraToParachuteOpening()
    if self.ParachuteFormation and self.ParachuteFormation.ShouldApplyFormationCamera and self.ParachuteFormation:ShouldApplyFormationCamera() then
        self.ParachuteFormation:OverlayFormationCameraParams()
    end
end
function BRPlayerCharacterBase:SwitchCameraToParachuteFalling()
    self.Super:SwitchCameraToParachuteFalling()
    if self.ParachuteFormation and self.ParachuteFormation.ShouldApplyFormationCamera and self.ParachuteFormation:ShouldApplyFormationCamera() then
        self.ParachuteFormation:OverlayFormationCameraParams()
    end
end
function BRPlayerCharacterBase:SwitchCameraToNormal()
    self.Super:SwitchCameraToNormal()
    if self.ParachuteFormation and self.ParachuteFormation.OnLandingClearFormationCamera then
        self.ParachuteFormation:OnLandingClearFormationCamera()
    end
end
function BRPlayerCharacterBase:SwitchWeaponCheck(Slot, IgnoreState)
    if self:HasState(EPawnState.AttachToOther) then
        local Weapon = self:GetWeaponBySlot(Slot)
        if slua.isValid(Weapon) then
            local WeaponID = Weapon:GetWeaponID()
            local AttachToOtherConfig = GamePlayTools.GetCurrentConfig("AttachToOtherConfig")
            if AttachToOtherConfig and AttachToOtherConfig.CheckIsWeaponInBlackList and AttachToOtherConfig.CheckIsWeaponInBlackList(WeaponID) then
                local uPlayerController = self:GetPlayerControllerSafety()
                if Client and slua.isValid(uPlayerController) and uPlayerController.Role == ENetRole.ROLE_AutonomousProxy then
                    uPlayerController:DisplayGameTipWithMsgID(47306)
                end
                return false
            end
        end
    end
    if self:HasState(EPawnState.WebSwing) and Slot ~= ESurviveWeaponPropSlot.SWPS_None and slua.isValid(self.STCharacterMovement) then
        local SpiderSwingObj = self.STCharacterMovement:GetSpecialMoveObjBySpecialMoveType(ESpecialMovementType.SPECIAL_MOVE_SpiderSwing)
        if slua.isValid(SpiderSwingObj) then
            local nCurState = SpiderSwingObj:GetCurMoveState()
            if nCurState == ESpiderSwingMoveState.Launching or nCurState == ESpiderSwingMoveState.Swinging then
                return false
            end
        end
    end
    return self.Super:SwitchWeaponCheck(Slot, IgnoreState)
end

-- ==========================================
-- HELPERS
-- ==========================================
local function Valid(obj)
    if not obj then return false end
    if slua and slua.isValid then
        local ok, v = pcall(slua.isValid, obj)
        if not ok or not v then return false end
    end
    return true
end

local function GetHealthColor(hpPercent)
    if hpPercent > 60 then return {R=0, G=255, B=0, A=255}
    elseif hpPercent > 30 then return {R=255, G=255, B=0, A=255}
    else return {R=255, G=0, B=0, A=255} end
end

local function GetSafeEnemyKey(enemy)
    if Valid(enemy) then
        if enemy.PlayerKey then return tostring(enemy.PlayerKey) end
        if type(enemy.GetUniqueID) == "function" then return tostring(enemy:GetUniqueID()) end
    end
    return tostring(enemy)
end

-- ==========================================
-- OUTLINE COLORS
-- ==========================================
local OUTLINE_COLORS = {
    [1] = { R=255, G=0,   B=0,   A=255, fR=1.0, fG=0.0, fB=0.0 },
    [2] = { R=0,   G=255, B=0,   A=255, fR=0.0, fG=1.0, fB=0.0 },
    [3] = { R=0,   G=100, B=255, A=255, fR=0.0, fG=0.4, fB=1.0 },
    [4] = { R=255, G=255, B=0,   A=255, fR=1.0, fG=1.0, fB=0.0 },
    [5] = { R=255, G=0,   B=255, A=255, fR=1.0, fG=0.0, fB=1.0 },
    [6] = { R=255, G=255, B=255, A=255, fR=1.0, fG=1.0, fB=1.0 },
}

local function GetOutlineColor()
    local idx = _G.AK_GetVal("OUTLINE_COLOR")
    if idx < 1 then idx = 1 end
    if idx > 6 then idx = 6 end
    return OUTLINE_COLORS[idx], idx
end

-- ==========================================
-- WALL COLOR PALETTE (matches Java floating 10 colors)
-- ==========================================
local WALL_COLOR_TABLE = {
    [1]  = { R=255, G=26,  B=36,  A=255 },  -- Red
    [2]  = { R=0,   G=229, B=255, A=255 },  -- Cyan
    [3]  = { R=26,  G=229, B=64,  A=255 },  -- Green
    [4]  = { R=255, G=229, B=13,  A=255 },  -- Yellow
    [5]  = { R=255, G=115, B=13,  A=255 },  -- Orange
    [6]  = { R=158, G=64,  B=255, A=255 },  -- Purple
    [7]  = { R=255, G=64,  B=166, A=255 },  -- Pink
    [8]  = { R=255, G=255, B=255, A=255 },  -- White
    [9]  = { R=26,  G=89,  B=255, A=255 },  -- Blue
    [10] = { R=153, G=255, B=13,  A=255 },  -- Lime
}

local function GetWallColorByIndex(idx)
    if not idx or idx < 1 or idx > 10 then idx = 1 end
    return WALL_COLOR_TABLE[idx]
end


-- ==========================================
-- 🔥 FIXED: NATIVE WALL DYEING (Full Body Visible)
-- Head-only issue solved + HDR bright colors
-- ==========================================

-- HDR Boosted colors (linear space me bright dikhe)
local DYE_COLORS = {
    [1]  = { r=2.8,  g=0.15, b=0.20 },  -- Red (HDR boost)
    [2]  = { r=0.10, g=2.5,  b=2.8  },  -- Cyan
    [3]  = { r=0.15, g=2.8,  b=0.35 },  -- Green
    [4]  = { r=2.8,  g=2.5,  b=0.10 },  -- Yellow
    [5]  = { r=2.8,  g=1.2,  b=0.10 },  -- Orange
    [6]  = { r=1.8,  g=0.60, b=2.8  },  -- Purple
    [7]  = { r=2.8,  g=0.55, b=1.8  },  -- Pink
    [8]  = { r=2.8,  g=2.8,  b=2.8  },  -- White
    [9]  = { r=0.15, g=0.85, b=2.8  },  -- Blue
    [10] = { r=1.6,  g=2.8,  b=0.15 },  -- Lime
}

local _wallOwned = {}
local _wallOwnedOrder = {}
local _wallVisibleNative = nil
local _wallOccludedNative = nil
local _wallVisibleIdx = 1
local _wallOccludedIdx = 2
local _wallRevision = 1
local _wallConsoleReady = false
local _wallConsoleWorld = nil
local _wallLastUpdate = 0
local WALL_UPDATE_INTERVAL = 0.20  -- ⚡ Faster response

local function _makeLinearColor(c)
    local FLinearColor = import("LinearColor")
    if FLinearColor then
        local ok, v = pcall(FLinearColor, c.r, c.g, c.b, 1)
        if ok and v then return v end
    end
    return { R = c.r, G = c.g, B = c.b, A = 1 }
end

local function _ensureConsoleGate(world)
    if _wallConsoleReady and _wallConsoleWorld == world then return true end
    if not world then return false end
    local KSL = import("KismetSystemLibrary")
    if not KSL then return false end
    local ok = pcall(function()
        KSL.ExecuteConsoleCommand(world, "r.EnableDrawDyeingColor 1")
        KSL.ExecuteConsoleCommand(world, "r.CustomDepth 3")
        KSL.ExecuteConsoleCommand(world, "r.CustomDepthTemporalAAJitter 0")
    end)
    if ok then
        _wallConsoleReady = true
        _wallConsoleWorld = world
    end
    return ok
end

local function _restoreWall(actor)
    local entry = _wallOwned[actor]
    if not entry then return true end
    if entry.mesh and slua.isValid(entry.mesh) then
        pcall(function() entry.mesh:SetDrawDyeing(false) end)
    end
    _wallOwned[actor] = nil
    for i = #_wallOwnedOrder, 1, -1 do
        if _wallOwnedOrder[i] == entry then
            table.remove(_wallOwnedOrder, i)
            break
        end
    end
    return true
end

local function _clearAllWall()
    for i = #_wallOwnedOrder, 1, -1 do
        local entry = _wallOwnedOrder[i]
        if entry.mesh and slua.isValid(entry.mesh) then
            pcall(function() entry.mesh:SetDrawDyeing(false) end)
        end
        _wallOwned[entry.actor] = nil
        _wallOwnedOrder[i] = nil
    end
    _wallOwned = {}
    _wallOwnedOrder = {}
end

-- 🔥 FIXED: Sab skeletal meshes pe apply karo, sirf head nahi
local function _getAllBodyMeshes(actor)
    local meshes = {}
    if not slua.isValid(actor) then return meshes end
    -- Main mesh
    if slua.isValid(actor.Mesh) then table.insert(meshes, actor.Mesh) end
    -- Baaki skeletal meshes (body parts, arms, legs)
    pcall(function()
        local SkeletalMeshClass = import("SkeletalMeshComponent")
        if SkeletalMeshClass and type(actor.GetComponentsByClass) == "function" then
            local comps = actor:GetComponentsByClass(SkeletalMeshClass)
            if comps then
                local count = type(comps.Num) == "function" and comps:Num() or #comps
                for i = 1, count do
                    local c = type(comps.Get) == "function" and comps:Get(i-1) or comps[i]
                    if slua.isValid(c) and c ~= actor.Mesh then
                        table.insert(meshes, c)
                    end
                end
            end
        end
    end)
    return meshes
end

local function _applyWallToActor(actor)
    if not slua.isValid(actor) then
        _restoreWall(actor)
        return
    end

    local meshes = _getAllBodyMeshes(actor)
    if #meshes == 0 then return end

    local entry = _wallOwned[actor]
    if entry and entry.applied and entry.revision == _wallRevision then return end

    -- 🎯 Native Dyeing (full body) + MID fallback (for hidden parts)
    for meshIdx, mesh in ipairs(meshes) do
        if not slua.isValid(mesh) then goto continue end

        -- 1️⃣ Native dyeing (full body visibility through walls)
        if type(mesh.SetDrawDyeing) == "function"
            and type(mesh.SetDrawDyeingMode) == "function"
            and type(mesh.SetVisibleDyeingColor) == "function"
            and type(mesh.SetOccludedDyeingColor) == "function" then
            pcall(function()
                mesh:SetDrawDyeingMode(1)          -- Full body mode
                mesh:SetVisibleDyeingColor(_wallVisibleNative)
                mesh:SetOccludedDyeingColor(_wallOccludedNative)
                mesh:SetDrawDyeing(true)
            end)
        end

        -- 2️⃣ RenderCustomDepth (depth bypass — wall ke peeche bhi render)
        pcall(function()
            if type(mesh.SetRenderCustomDepth) == "function" then
                mesh:SetRenderCustomDepth(true)
            end
            if type(mesh.SetCustomDepthStencilValue) == "function" then
                mesh:SetCustomDepthStencilValue(252)
            end
            if mesh.bRenderCustomDepth ~= nil then mesh.bRenderCustomDepth = true end
            if mesh.CustomDepthStencilValue ~= nil then mesh.CustomDepthStencilValue = 252 end
        end)

        -- 3️⃣ MID color apply (body pe bright color)
        pcall(function()
            for i = 0, 12 do
                local matInterface = mesh:GetMaterial(i)
                if not (matInterface and slua.isValid(matInterface)) then break end
                local baseMat = matInterface:GetBaseMaterial()
                if baseMat and slua.isValid(baseMat) then
                    local matName = tostring(baseMat)
                    if string.find(matName, "Master_Mask", 1, true)
                        or string.find(matName, "Master", 1, true)
                        or string.find(matName, "Character", 1, true) then
                        pcall(function()
                            baseMat.bDisableDepthTest = true
                            baseMat.BlendMode = 2
                        end)
                        if not entry then
                            entry = { actor = actor, applied = false, revision = 0, MIDs = {} }
                            _wallOwned[actor] = entry
                            _wallOwnedOrder[#_wallOwnedOrder + 1] = entry
                        end
                        entry.MIDs = entry.MIDs or {}
                        local key = tostring(meshIdx) .. "_" .. tostring(i)
                        local mid = entry.MIDs[key]
                        if not (mid and slua.isValid(mid)) then
                            mid = mesh:CreateAndSetMaterialInstanceDynamic(i)
                            entry.MIDs[key] = mid
                        end
                        if mid and slua.isValid(mid) then
                            local c = DYE_COLORS[_wallVisibleIdx] or DYE_COLORS[1]
                            local colorParam = { R = c.r, G = c.g, B = c.b, A = 1 }
                            pcall(function()
                                mid.bDisableDepthTest = true
                                mid.BlendMode = 2
                            end)
                            mid:SetVectorParameterValue("颜色", colorParam)
                            mid:SetVectorParameterValue("Para_Color", colorParam)
                            mid:SetVectorParameterValue("Tint", colorParam)
                            mid:SetVectorParameterValue("Color", colorParam)
                            mid:SetVectorParameterValue("BaseColor", colorParam)
                            mid:SetVectorParameterValue("DiffuseColor", colorParam)
                            mid:SetVectorParameterValue("EmissiveColor", colorParam)
                            mid:SetVectorParameterValue("MainColor", colorParam)
                            mid:SetVectorParameterValue("BodyColor", colorParam)
                            pcall(function()
                                mid:SetVectorParameterValue("ParaScaleOffset", { R=3, G=3, B=0, A=0 })
                            end)
                            -- 🔥 HDR emissive boost
                            pcall(function() mid:SetScalarParameterValue("EmissiveStrength", 15.0) end)
                            pcall(function() mid:SetScalarParameterValue("LightPower", 20.0) end)
                            pcall(function() mid:SetScalarParameterValue("GlowPower", 12.0) end)
                            pcall(function() mid:SetScalarParameterValue("EmissiveIntensity", 15.0) end)
                        end
                    end
                end
            end
        end)

        ::continue::
    end

    if not entry then
        entry = { actor = actor, applied = false, revision = 0 }
        _wallOwned[actor] = entry
        _wallOwnedOrder[#_wallOwnedOrder + 1] = entry
    end
    entry.applied = true
    entry.revision = _wallRevision
end

function _G.RunNativeWallDyeing(enemy)
    if _G.AK_GetVal("WALL_HACK") ~= 1 then
        if _wallOwned[enemy] then _restoreWall(enemy) end
        return
    end

    local visIdx = _G.AK_GetVal("WALL_COLOR_VISIBLE")
    local behIdx = _G.AK_GetVal("WALL_COLOR_BEHIND")
    if not visIdx or visIdx < 1 or visIdx > 10 then visIdx = 1 end
    if not behIdx or behIdx < 1 or behIdx > 10 then behIdx = 2 end

    if visIdx ~= _wallVisibleIdx or behIdx ~= _wallOccludedIdx or not _wallVisibleNative then
        _wallVisibleIdx, _wallOccludedIdx = visIdx, behIdx
        _wallVisibleNative = _makeLinearColor(DYE_COLORS[visIdx])
        _wallOccludedNative = _makeLinearColor(DYE_COLORS[behIdx])
        _wallRevision = _wallRevision + 1
        -- Force reapply on color change
        for _, e in ipairs(_wallOwnedOrder) do e.applied = false end
    end

    local world = slua.getWorld()
    if not _ensureConsoleGate(world) then return end

    local now = os.clock()
    if now - _wallLastUpdate < WALL_UPDATE_INTERVAL then return end
    _applyWallToActor(enemy)
end

function _G.ResetNativeWallDyeing()
    _clearAllWall()
    _wallConsoleReady = false
    _wallConsoleWorld = nil
end
-- ==========================================
-- WALL_HACK
-- ==========================================
local SCALE_COLOR_V2 = {R=3, G=3, B=0, A=0}

local function GetAllSkeletalMeshes(enemy, markData)
    -- ⚡ Match ke liye cache time chhota (1.5s) aur validity check
    if markData.MeshCache and markData.MeshCacheTime 
       and (os.clock() - markData.MeshCacheTime) < 1.5 then
        -- 🔥 Cache validity check — agar koi mesh invalid ho gaya to re-scan
        local allValid = true
        for _, m in ipairs(markData.MeshCache) do
            if not (m and slua.isValid(m)) then
                allValid = false
                break
            end
        end
        if allValid then
            return markData.MeshCache
        end
    end
    
    local meshes = {}
    local seen = {}
    
    -- 1️⃣ Main mesh (usually body)
    if enemy.Mesh and slua.isValid(enemy.Mesh) then 
        table.insert(meshes, enemy.Mesh)
        seen[enemy.Mesh] = true
    end
    
    -- 2️⃣ Saare SkeletalMesh components (body parts, arms, legs, head)
    pcall(function()
        local SkeletalMeshClass = import("SkeletalMeshComponent")
        if SkeletalMeshClass and type(enemy.GetComponentsByClass) == "function" then
            local childs = enemy:GetComponentsByClass(SkeletalMeshClass)
            if childs then
                local count = type(childs.Num) == "function" and childs:Num() or #childs
                for i = 1, count do
                    local comp = type(childs.Get) == "function" and childs:Get(i-1) or childs[i]
                    if comp and slua.isValid(comp) and not seen[comp] then
                        table.insert(meshes, comp)
                        seen[comp] = true
                    end
                end
            end
        end
    end)
    
    -- 3️⃣ MeshContainer / MeshCosmetic (PUBG me alag components)
    pcall(function()
        local extraNames = {
            "MeshCosmetic", "MeshContainer", "AvatarMesh", 
            "Mesh_LOD0", "BodyMesh", "HeadMesh",
            "SkeletalMesh", "Mesh3P", "Mesh1P"
        }
        for _, name in ipairs(extraNames) do
            local comp = enemy[name]
            if comp and slua.isValid(comp) and not seen[comp] then
                table.insert(meshes, comp)
                seen[comp] = true
            end
        end
    end)
    
    markData.MeshCache = meshes
    markData.MeshCacheTime = os.clock()
    return meshes
end

local function Undowallhackng(enemy, markData)
    pcall(function()
        if markData.WallhackApplied then
            local meshes = GetAllSkeletalMeshes(enemy, markData)
            for _, mesh in ipairs(meshes) do
                if mesh and slua.isValid(mesh) then
                    pcall(function()
                        if type(mesh.SetRenderCustomDepth) == "function" then mesh:SetRenderCustomDepth(false) end
                    end)
                end
            end
            markData.WallhackApplied = false
        end
    end)
end

local function Applywallhackng(enemy, markData)
    pcall(function()
        local meshes = GetAllSkeletalMeshes(enemy, markData)
        for _, mesh in ipairs(meshes) do
            if mesh and slua.isValid(mesh) then
                pcall(function()
                    if type(mesh.SetRenderCustomDepth) == "function" then mesh:SetRenderCustomDepth(true) end
                    if type(mesh.SetCustomDepthStencilValue) == "function" then mesh:SetCustomDepthStencilValue(252) end
                    if mesh.bRenderCustomDepth ~= nil then mesh.bRenderCustomDepth = true end
                    if mesh.CustomDepthStencilValue ~= nil then mesh.CustomDepthStencilValue = 252 end
                end)
            end
        end
        markData.WallhackApplied = true
    end)
end

local function ApplyColorBodyV2(enemy, pc, markData)
    pcall(function()
        if _G.AK_GetVal("WALL_HACK") ~= 1 then return end
        local meshes = GetAllSkeletalMeshes(enemy, markData)
        if #meshes == 0 then return end

        -- 🎨 INI se color index lo
        local visIdx = _G.AK_GetVal("WALL_COLOR_VISIBLE")
        local behIdx = _G.AK_GetVal("WALL_COLOR_BEHIND")
        if not visIdx or visIdx < 1 or visIdx > 10 then visIdx = 1 end
        if not behIdx or behIdx < 1 or behIdx > 10 then behIdx = 2 end

        -- 🎨 Visibility check (0.5s cache)
        local curTime = os.clock()
        if markData.LastVisCheckTime == nil or (curTime - markData.LastVisCheckTime) > 0.5 then
            markData.LastVisCheckTime = curTime
            local isHidden = true
            pcall(function()
                if pc and slua.isValid(pc) and type(pc.LineOfSightTo) == "function" then
                    isHidden = not pc:LineOfSightTo(enemy)
                end
            end)
            markData.CachedHiddenState = isHidden
        end
        local hidden = markData.CachedHiddenState
        if hidden == nil then hidden = true end

        -- 🎯 Color = INI se (hidden = BEHIND, visible = VISIBLE)
        local colorIdx = hidden and behIdx or visIdx
        local dyeColor = DYE_COLORS[colorIdx] or DYE_COLORS[1]
        local finalColor = { R = dyeColor.r, G = dyeColor.g, B = dyeColor.b, A = 1.0 }

        local colorHash = string.format("%d_%d", colorIdx, hidden and 1 or 0)
        local needApply = (markData.LastHiddenState ~= hidden)
            or (markData.LastColorHash ~= colorHash)
            or (markData.DepthTestApplied ~= true)

        -- 🎨 Color index change hone pe bhi force re-apply
        if markData.LastColorIdx ~= colorIdx then
            needApply = true
            markData.LastColorIdx = colorIdx
        end

        if not needApply then return end

        markData.LastHiddenState = hidden
        markData.LastColorHash = colorHash
        markData.ColorApplied = true
        markData.DepthTestApplied = true

        for meshIndex, mesh in ipairs(meshes) do
            if mesh and slua.isValid(mesh) then
                pcall(function()
                    if type(mesh.SetRenderCustomDepth) == "function" then mesh:SetRenderCustomDepth(true) end
                    if type(mesh.SetCustomDepthStencilValue) == "function" then mesh:SetCustomDepthStencilValue(252) end
                    if mesh.bRenderCustomDepth ~= nil then mesh.bRenderCustomDepth = true end
                    if mesh.CustomDepthStencilValue ~= nil then mesh.CustomDepthStencilValue = 252 end
                end)
                for i = 0, 15 do
                    local matInterface = mesh:GetMaterial(i)
                    if not (matInterface and slua.isValid(matInterface)) then break end
                    local baseMat = matInterface:GetBaseMaterial()
                    if baseMat and slua.isValid(baseMat) then
                        local matName = tostring(baseMat)
                        if string.find(matName, "Master_Mask", 1, true)
                            or string.find(matName, "Master", 1, true)
                            or string.find(matName, "Character", 1, true)
                            or string.find(matName, "MI_", 1, true) then
                            pcall(function()
                                baseMat.bDisableDepthTest = true
                                baseMat.BlendMode = 2
                                baseMat.bCanMask = true
                                baseMat.bUseTranslucencyForLights = true
                            end)
                            if not markData.MIDs then markData.MIDs = {} end
                            local meshKey = "Mesh_" .. tostring(meshIndex)
                            if not markData.MIDs[meshKey] then markData.MIDs[meshKey] = {} end
                            local mid = markData.MIDs[meshKey][i]
                            if not (mid and slua.isValid(mid)) then
                                mid = mesh:CreateAndSetMaterialInstanceDynamic(i)
                                markData.MIDs[meshKey][i] = mid
                            end
                            if mid and slua.isValid(mid) then
                                pcall(function()
                                    mid.bDisableDepthTest = true
                                    mid.BlendMode = 2
                                end)
                                mid:SetVectorParameterValue("颜色", finalColor)
                                mid:SetVectorParameterValue("Para_Color", finalColor)
                                mid:SetVectorParameterValue("Tint", finalColor)
                                mid:SetVectorParameterValue("Color", finalColor)
                                mid:SetVectorParameterValue("BaseColor", finalColor)
                                mid:SetVectorParameterValue("DiffuseColor", finalColor)
                                mid:SetVectorParameterValue("EmissiveColor", finalColor)
                                mid:SetVectorParameterValue("MainColor", finalColor)
                                mid:SetVectorParameterValue("BodyColor", finalColor)
                                mid:SetVectorParameterValue("ParaScaleOffset", SCALE_COLOR_V2)
                                pcall(function() mid:SetScalarParameterValue("EmissiveStrength", 5.0) end)
                                pcall(function() mid:SetScalarParameterValue("LightPower", 8.0) end)
                                pcall(function() mid:SetScalarParameterValue("GlowPower", 5.0) end)
                            end
                        end
                    end
                end
            end
        end
    end)
end

local function UndoColorBodyV2(enemy, markData)
    pcall(function()
        if markData.ColorApplied then
            local meshes = GetAllSkeletalMeshes(enemy, markData)
            for meshIndex, mesh in ipairs(meshes) do
                if mesh and slua.isValid(mesh) then
                    local meshKey = "Mesh_" .. tostring(meshIndex)
                    if markData.MIDs and markData.MIDs[meshKey] then
                        for i, mid in pairs(markData.MIDs[meshKey]) do
                            if mid and slua.isValid(mid) then
                                local defC = {R=1, G=1, B=1, A=1}
                                mid:SetVectorParameterValue("颜色", defC)
                                mid:SetVectorParameterValue("Para_Color", defC)
                                mid:SetVectorParameterValue("Tint", defC)
                                mid:SetVectorParameterValue("Color", defC)
                                mid:SetVectorParameterValue("BaseColor", defC)
                                mid:SetVectorParameterValue("DiffuseColor", defC)
                                mid:SetVectorParameterValue("EmissiveColor", defC)
                                mid:SetVectorParameterValue("MainColor", defC)
                                mid:SetVectorParameterValue("BodyColor", defC)
                            end
                        end
                    end
                end
            end
            markData.ColorApplied = false
            markData.LastColorHash = ""
            markData.LastHiddenState = nil
            markData.DepthTestApplied = false
        end
    end)
end

-- ==========================================
-- OUTLINE ESP
-- ==========================================
local function ApplyOutlineESP(enemy, markData)
    pcall(function()
        local meshes = GetAllSkeletalMeshes(enemy, markData)
        if #meshes == 0 then return end
        local colorData, colorIdx = GetOutlineColor()
        local thick = _G.AK_GetVal("OUTLINE_THICK") or 5
        if thick < 1 then thick = 1 end
        if thick > 20 then thick = 20 end
        local outlineHash = string.format("%d_%d_%d", colorIdx, thick, #meshes)
        if markData.OutlineHash == outlineHash and markData.OutlineApplied then return end
        markData.OutlineHash = outlineHash
        local LinearColorClass = import("LinearColor") or _G.FLinearColor
        local glowIntensity = 80.0
        local glowColor = LinearColorClass and LinearColorClass(
            colorData.fR * glowIntensity,
            colorData.fG * glowIntensity,
            colorData.fB * glowIntensity,
            1.0
        ) or { R = colorData.R * glowIntensity, G = colorData.G * glowIntensity, B = colorData.B * glowIntensity, A = 255 }
        for _, comp in ipairs(meshes) do
            if Valid(comp) then
                pcall(function()
                    comp.UseScopeDistanceCulling = false
                    comp.PrimitiveShadingStrategy = 1
                    comp.ShadingRate = 6
                end)
                if comp.SetDrawIdeaOutline then
                    comp:SetDrawIdeaOutline(true)
                    if comp.OverrideIdeaOutlineColor then comp:OverrideIdeaOutlineColor(true, glowColor) end
                    if comp.OverrideIdeaOutlineThickness then comp:OverrideIdeaOutlineThickness(true, thick) end
                end
            end
        end
        markData.OutlineApplied = true
    end)
end

local function UndoOutlineESP(enemy, markData)
    pcall(function()
        if markData.OutlineApplied then
            local meshes = GetAllSkeletalMeshes(enemy, markData)
            for _, comp in ipairs(meshes) do
                if Valid(comp) then
                    pcall(function()
                        comp.PrimitiveShadingStrategy = 0
                        comp.ShadingRate = 1
                    end)
                    if comp.SetDrawIdeaOutline then comp:SetDrawIdeaOutline(false) end
                end
            end
            markData.OutlineApplied = false
            markData.OutlineHash = nil
        end
    end)
end

-- ==========================================
-- ENEMY WEAPON NAME
-- ==========================================
local function GetEnemyWeaponName(enemy)
    local weaponName = "Fist"
    pcall(function()
        local weapon = nil
        if enemy.CurrentWeapon then weapon = enemy.CurrentWeapon
        elseif type(enemy.GetCurrentWeapon) == "function" then weapon = enemy:GetCurrentWeapon()
        elseif enemy.WeaponManagerComponent then weapon = enemy.WeaponManagerComponent.CurrentWeaponReplicated end
        if Valid(weapon) then
            if type(weapon.GetWeaponName) == "function" then
                weaponName = weapon:GetWeaponName()
            elseif type(weapon.GetItemDefineID) == "function" then
                local d = weapon:GetItemDefineID()
                if Valid(d) then
                    local cfg = CDataTable.GetTableData("Item", d.TypeSpecificID)
                    if cfg and cfg.Name then weaponName = cfg.Name end
                end
            end
        end
    end)
    return weaponName
end

-- ==========================================
-- NAYA ESP (MasterShotESP)
-- ==========================================
local g_rayansyed_ShotESP = {
    Canvas = nil, Counter = nil, Enemies = {}, Lines = {}, Names = {},
    LastScanClock = -999.0, LastTransformClock = -999.0, LastWorld = nil, TracerOrigin = nil,
    CanvasScaleX = 1.0, CanvasScaleY = 1.0, CanvasOffsetX = 0.0, CanvasOffsetY = 0.0,
}

local V2 = _G.FVector2D
if not V2 then pcall(function() V2 = import("Vector2D") end) end
local LinearColor = _G.FLinearColor
if not LinearColor then pcall(function() LinearColor = import("LinearColor") end) end
local SlateBlueprintLibrary = nil
pcall(function() SlateBlueprintLibrary = import("SlateBlueprintLibrary") end)
local WidgetLayoutLibrary = nil
pcall(function() WidgetLayoutLibrary = import("WidgetLayoutLibrary") end)
local SlateColor = nil
pcall(function() SlateColor = import("SlateColor") or import("/Script/SlateCore.SlateColor") end)
local GameplayStaticsESP = nil
pcall(function() GameplayStaticsESP = import("GameplayStatics") end)

local function g_rayansyed_ESPV2(x, y)
    if V2 then return V2(x, y) end
    return {X = x, Y = y}
end

local function g_rayansyed_ESPColor(r, g, b, a)
    if LinearColor then return LinearColor(r, g, b, a or 1.0) end
    return {R=r, G=g, B=b, A=a or 1.0}
end

local ESP_REAL = g_rayansyed_ESPColor(0.90, 0.14, 0.14, 0.98)
local ESP_BOT  = g_rayansyed_ESPColor(0.18, 0.86, 0.36, 0.98)
local ESP_WHITE = g_rayansyed_ESPColor(1.0, 1.0, 1.0, 1.0)
local ESP_BLACK = g_rayansyed_ESPColor(0.0, 0.0, 0.0, 1.0)

local function g_rayansyed_ESPScaleColor(color, factor, alphaMul)
    if not color then return g_rayansyed_ESPColor(1, 1, 1, 1) end
    local r = math.max(0.0, math.min(1.0, (tonumber(color.R) or 1.0) * (factor or 1.0)))
    local g = math.max(0.0, math.min(1.0, (tonumber(color.G) or 1.0) * (factor or 1.0)))
    local b = math.max(0.0, math.min(1.0, (tonumber(color.B) or 1.0) * (factor or 1.0)))
    local a = math.max(0.0, math.min(1.0, (tonumber(color.A) or 1.0) * (alphaMul or 1.0)))
    return g_rayansyed_ESPColor(r, g, b, a)
end

local ESP_REAL_DARK  = g_rayansyed_ESPScaleColor(ESP_REAL, 0.68, 1.0)
local ESP_REAL_LIGHT = g_rayansyed_ESPScaleColor(ESP_REAL, 1.12, 0.82)
local ESP_BOT_DARK   = g_rayansyed_ESPScaleColor(ESP_BOT, 0.68, 1.0)
local ESP_BOT_LIGHT  = g_rayansyed_ESPScaleColor(ESP_BOT, 1.10, 0.82)
local ESP_WHITE_SOFT = g_rayansyed_ESPColor(0.94, 0.94, 0.94, 0.98)
local ESP_WHITE_GLOSS = g_rayansyed_ESPColor(1.0, 1.0, 1.0, 0.34)

local function g_rayansyed_ESPValid(obj)
    if not obj then return false end
    local ok, valid = pcall(function() return slua.isValid(obj) end)
    return ok and valid == true
end

local function g_rayansyed_ESPNow()
    local t = nil
    pcall(function()
        local w = (slua and slua.getWorld and slua.getWorld()) or nil
        if GameplayStaticsESP and w and GameplayStaticsESP.GetRealTimeSeconds then
            t = GameplayStaticsESP.GetRealTimeSeconds(w)
        end
    end)
    if tonumber(t) then return tonumber(t) end
    pcall(function() if os and os.clock then t = os.clock() end end)
    return tonumber(t) or 0.0
end

local function g_rayansyed_ESPWorld()
    local w = nil
    pcall(function() if slua and slua.getWorld then w = slua.getWorld() end end)
    return w
end

local function g_rayansyed_ESPGetController()
    local pc = nil
    pcall(function()
        local GDP = require("GameLua.GameCore.Data.GameplayData")
        if GDP and GDP.GetPlayerController then pc = GDP.GetPlayerController() end
    end)
    if not g_rayansyed_ESPValid(pc) then
        pcall(function()
            if slua_GameFrontendHUD then pc = slua_GameFrontendHUD:GetPlayerController() end
        end)
    end
    return g_rayansyed_ESPValid(pc) and pc or nil
end

local function g_rayansyed_ESPGetLocalCharacter()
    local c = nil
    pcall(function()
        local GDP = require("GameLua.GameCore.Data.GameplayData")
        if GDP then
            if GDP.GetPlayerCharacter then c = GDP.GetPlayerCharacter() end
            if not g_rayansyed_ESPValid(c) and GDP.GetLocalCharacter then c = GDP.GetLocalCharacter() end
        end
    end)
    if not g_rayansyed_ESPValid(c) then
        local pc = g_rayansyed_ESPGetController()
        pcall(function() if pc and pc.GetPawn then c = pc:GetPawn() end end)
    end
    return g_rayansyed_ESPValid(c) and c or nil
end

local function g_rayansyed_ESPGetPlayerState(character)
    if not g_rayansyed_ESPValid(character) then return nil end
    local ps = nil
    pcall(function()
        if character.GetPlayerStateSafety then ps = character:GetPlayerStateSafety() end
    end)
    if not g_rayansyed_ESPValid(ps) then
        pcall(function() if character.GetPlayerState then ps = character:GetPlayerState() end end)
    end
    if not g_rayansyed_ESPValid(ps) then
        pcall(function() ps = character.PlayerState end)
    end
    return g_rayansyed_ESPValid(ps) and ps or nil
end

local function g_rayansyed_ESPNormalizeName(value)
    if value == nil or value == false then return nil end
    local ok, text = pcall(tostring, value)
    if not ok or not text then return nil end
    text = text:gsub("^%s+", ""):gsub("%s+$", "")
    if text == "" or text == "nil" or text == "None" or text == "NULL" then return nil end
    return text
end

local function g_rayansyed_ESPResolvePlayerName(character)
    if not g_rayansyed_ESPValid(character) then return nil end
    local name = nil
    local function take(value)
        if not name then name = g_rayansyed_ESPNormalizeName(value) end
    end
    pcall(function() if character.GetPlayerNameSafety then take(character:GetPlayerNameSafety()) end end)
    pcall(function() if not name and character.GetPlayerName then take(character:GetPlayerName()) end end)
    pcall(function() if not name then take(character.PlayerName) end end)
    pcall(function() if not name then take(character.NickName) end end)
    if not name then
        local ps = g_rayansyed_ESPGetPlayerState(character)
        if ps then
            pcall(function() if ps.GetPlayerName then take(ps:GetPlayerName()) end end)
            pcall(function() if not name then take(ps.PlayerName) end end)
            pcall(function() if not name then take(ps.PlayerNamePrivate) end end)
            pcall(function() if not name then take(ps.NickName) end end)
        end
    end
    return name
end

local function g_rayansyed_ESPGetPlayerKey(character)
    local key = nil
    pcall(function() if character.GetPlayerKey then key = character:GetPlayerKey() end end)
    if key == nil then pcall(function() key = character.PlayerKey end) end
    if key == nil then
        local ps = g_rayansyed_ESPGetPlayerState(character)
        if ps then pcall(function() key = ps.PlayerKey end) end
    end
    return tostring(key or character)
end

local function g_rayansyed_ESPGetTeamID(character)
    if not g_rayansyed_ESPValid(character) then return nil end
    local id = nil
    pcall(function() if character.GetTeamID then id = character:GetTeamID() end end)
    if id == nil then pcall(function() id = character.TeamID end) end
    if id == nil then
        local ps = g_rayansyed_ESPGetPlayerState(character)
        if ps then
            pcall(function() if ps.GetTeamID then id = ps:GetTeamID() end end)
            if id == nil then pcall(function() id = ps.TeamID end) end
        end
    end
    return id
end

local function g_rayansyed_ESPIsAlive(character)
    if not g_rayansyed_ESPValid(character) then return false end
    local alive = nil
    pcall(function() if character.IsAlive then alive = character:IsAlive() end end)
    if type(alive) == "boolean" then return alive end
    local hp = nil
    pcall(function() hp = character.Health end)
    if type(hp) ~= "number" then pcall(function() hp = character.HP end) end
    if type(hp) == "number" then return hp > 0 end
    return true
end

local function g_rayansyed_ESPIsBot(character)
    if not g_rayansyed_ESPValid(character) then return false end
    local result = nil
    local function take(v)
        if result == nil and (v == true or v == false or v == 1 or v == 0) then result = (v == true or v == 1) end
    end
    pcall(function() if Game and Game.IsAI then take(Game:IsAI(character)) end end)
    pcall(function() take(character.bIsAI) end)
    pcall(function() if character.IsBot then take(character:IsBot()) end end)
    local ps = g_rayansyed_ESPGetPlayerState(character)
    if ps then
        pcall(function() take(ps.bIsABot) end)
        pcall(function() take(ps.bIsBot) end)
        pcall(function() take(ps.bIsAI) end)
        pcall(function() if ps.IsBot then take(ps:IsBot()) end end)
    end
    return result == true
end

local function g_rayansyed_ESPActorLocation(character)
    local loc = nil
    if not g_rayansyed_ESPValid(character) then return nil end
    pcall(function()
        if character.K2_GetActorLocation then loc = character:K2_GetActorLocation()
        elseif Game and Game.GetActorLocation then loc = Game:GetActorLocation(character) end
    end)
    return loc
end

local function g_rayansyed_ESPDistanceMeters(a, b)
    if not a or not b then return math.huge end
    local dx, dy, dz = a.X-b.X, a.Y-b.Y, a.Z-b.Z
    return math.sqrt(dx*dx + dy*dy + dz*dz) / 100.0
end

local function g_rayansyed_ESPGetCharacterVerticalBounds(character)
    if not g_rayansyed_ESPValid(character) then return nil, nil end
    local center, halfHeight = nil, nil
    local capsule = nil
    pcall(function()
        if character.GetCapsuleComponent then
            capsule = character:GetCapsuleComponent()
        elseif character.CapsuleComponent then
            capsule = character.CapsuleComponent
        end
    end)
    if capsule and g_rayansyed_ESPValid(capsule) then
        pcall(function()
            if capsule.K2_GetComponentLocation then
                center = capsule:K2_GetComponentLocation()
            elseif capsule.GetComponentLocation then
                center = capsule:GetComponentLocation()
            end
            if capsule.GetScaledCapsuleHalfHeight then
                halfHeight = capsule:GetScaledCapsuleHalfHeight()
            elseif capsule.GetUnscaledCapsuleHalfHeight then
                halfHeight = capsule:GetUnscaledCapsuleHalfHeight()
            elseif capsule.CapsuleHalfHeight then
                halfHeight = capsule.CapsuleHalfHeight
            end
        end)
    end
    if not center then
        pcall(function()
            if character.K2_GetActorLocation then center = character:K2_GetActorLocation() end
        end)
    end
    if not center then
        pcall(function()
            if Game and Game.GetActorLocation then center = Game:GetActorLocation(character) end
        end)
    end
    if not center then return nil, nil end
    if not halfHeight or halfHeight < 10 or halfHeight > 200 then
        halfHeight = 85
        pcall(function()
            if character.bIsCrouched then halfHeight = 60 end
            if character.IsProne and character:IsProne() then halfHeight = 25 end
        end)
    end
    return center, halfHeight
end

local function g_rayansyed_ESPGetCharacterBoxLocs(character)
    local center, halfHeight = g_rayansyed_ESPGetCharacterVerticalBounds(character)
    if not center or not halfHeight then return nil, nil end
    local headLoc = { X = center.X, Y = center.Y, Z = center.Z + halfHeight }
    local feetLoc = { X = center.X, Y = center.Y, Z = center.Z - halfHeight }
    return headLoc, feetLoc
end

local function g_rayansyed_ESPHeadLocation(character)
    return g_rayansyed_ESPGetCharacterBoxLocs(character)
end

local function g_rayansyed_ESPFootLocation(character)
    local _, feetLoc = g_rayansyed_ESPGetCharacterBoxLocs(character)
    return feetLoc
end

local function g_rayansyed_ESPDestroyWidgetData(data)
    if not data then return end
    local widget = data.Widget or data.Container
    if g_rayansyed_ESPValid(widget) then
        pcall(function() widget:RemoveFromParent() end)
        pcall(function() widget:ConditionalBeginDestroy() end)
    end
end

local function g_rayansyed_ESPResetWidgets()
    for _, data in pairs(g_rayansyed_ShotESP.Lines) do g_rayansyed_ESPDestroyWidgetData(data) end
    for _, data in pairs(g_rayansyed_ShotESP.Names) do g_rayansyed_ESPDestroyWidgetData(data) end
    g_rayansyed_ShotESP.Lines = {}
    g_rayansyed_ShotESP.Names = {}
    if g_rayansyed_ShotESP.Counter then g_rayansyed_ESPDestroyWidgetData(g_rayansyed_ShotESP.Counter) end
    g_rayansyed_ShotESP.Counter = nil
    g_rayansyed_ShotESP.Canvas = nil
    g_rayansyed_ShotESP.Enemies = {}
end

local function g_rayansyed_ESPGetCanvas()
    if g_rayansyed_ESPValid(g_rayansyed_ShotESP.Canvas) then return g_rayansyed_ShotESP.Canvas end
    local root = nil
    pcall(function()
        local InGameUITools = require("GameLua.Mod.BaseMod.Common.UI.InGameUITools")
        if InGameUITools and InGameUITools.GetMainControlBaseUI then root = InGameUITools.GetMainControlBaseUI() end
    end)
    if not g_rayansyed_ESPValid(root) then return nil end
    local canvas = nil
    pcall(function()
        if g_rayansyed_ESPValid(root.CanvasPanel_0) then canvas = root.CanvasPanel_0
        elseif g_rayansyed_ESPValid(root.CanvasPanel_42) then canvas = root.CanvasPanel_42 end
    end)
    if g_rayansyed_ESPValid(canvas) then g_rayansyed_ShotESP.Canvas = canvas return canvas end
    return nil
end

local function g_rayansyed_ESPViewport(pc)
    local w, h = 1920.0, 1080.0
    pcall(function()
        if pc and pc.GetViewportSize then
            local v = g_rayansyed_ESPV2(0,0)
            pc:GetViewportSize(v)
            if v and tonumber(v.X) and v.X > 200 then w, h = v.X, v.Y end
        end
    end)
    return w, h
end

local function g_rayansyed_ESPGetCanvasLocalSize()
    local canvas = g_rayansyed_ESPGetCanvas()
    if not g_rayansyed_ESPValid(canvas) then return nil, nil end
    local cw, ch = nil, nil
    pcall(function()
        local geo = canvas:GetCachedGeometry()
        if not geo then return end
        local size = nil
        if geo.GetLocalSize then
            size = geo:GetLocalSize()
        elseif SlateBlueprintLibrary and SlateBlueprintLibrary.GetLocalSize then
            size = SlateBlueprintLibrary.GetLocalSize(geo)
        end
        if size and tonumber(size.X) and tonumber(size.Y) and size.X > 1 and size.Y > 1 then
            cw, ch = tonumber(size.X), tonumber(size.Y)
        end
    end)
    return cw, ch
end

local function g_rayansyed_ESPUpdateCanvasTransform(pc)
    local canvas = g_rayansyed_ESPGetCanvas()
    if not g_rayansyed_ESPValid(canvas) then return false end
    local calibrated = false
    pcall(function()
        if SlateBlueprintLibrary and SlateBlueprintLibrary.AbsoluteToLocal then
            local geo = canvas:GetCachedGeometry()
            if geo then
                local p0 = SlateBlueprintLibrary.AbsoluteToLocal(geo, g_rayansyed_ESPV2(0, 0))
                local p1 = SlateBlueprintLibrary.AbsoluteToLocal(geo, g_rayansyed_ESPV2(100, 100))
                if p0 and p1
                    and tonumber(p0.X) and tonumber(p0.Y)
                    and tonumber(p1.X) and tonumber(p1.Y)
                    and p1.X ~= p0.X and p1.Y ~= p0.Y then
                    g_rayansyed_ShotESP.CanvasScaleX = (p1.X - p0.X) / 100.0
                    g_rayansyed_ShotESP.CanvasScaleY = (p1.Y - p0.Y) / 100.0
                    g_rayansyed_ShotESP.CanvasOffsetX = p0.X
                    g_rayansyed_ShotESP.CanvasOffsetY = p0.Y
                    calibrated = true
                end
            end
        end
    end)
    if not calibrated then
        local scale = 1.0
        pcall(function()
            if WidgetLayoutLibrary and WidgetLayoutLibrary.GetViewportScale then
                local s = WidgetLayoutLibrary.GetViewportScale(pc)
                if tonumber(s) and s > 0 then scale = s end
            end
        end)
        g_rayansyed_ShotESP.CanvasScaleX = 1.0 / scale
        g_rayansyed_ShotESP.CanvasScaleY = 1.0 / scale
        g_rayansyed_ShotESP.CanvasOffsetX = 0.0
        g_rayansyed_ShotESP.CanvasOffsetY = 0.0
    end
    return true
end

local function g_rayansyed_ESPProject(pc, worldLoc)
    if not pc or not worldLoc then return nil end
    local pix = g_rayansyed_ESPV2(0, 0)
    local ok = false
    pcall(function()
        local res = pc:ProjectWorldLocationToScreen(worldLoc, pix, true)
        ok = (res == true or res == 1 or (pix and (pix.X ~= 0 or pix.Y ~= 0)))
    end)
    if not ok then return nil end
    local sx = g_rayansyed_ShotESP.CanvasScaleX or 1.0
    local sy = g_rayansyed_ShotESP.CanvasScaleY or 1.0
    local ox = g_rayansyed_ShotESP.CanvasOffsetX or 0.0
    local oy = g_rayansyed_ShotESP.CanvasOffsetY or 0.0
    return g_rayansyed_ESPV2(pix.X * sx + ox, pix.Y * sy + oy)
end

local function g_rayansyed_ESPSetFont(textWidget, size, outlineSize)
    if not g_rayansyed_ESPValid(textWidget) then return end
    pcall(function()
        local f = textWidget.Font
        if f then
            f.Size = size
            if outlineSize and outlineSize > 0 and f.OutlineSettings then
                pcall(function() f.OutlineSettings.OutlineSize = outlineSize end)
                pcall(function() f.OutlineSettings.OutlineColor = ESP_BLACK end)
            end
            textWidget:SetFont(f)
        end
        if outlineSize and outlineSize > 0 then
            if textWidget.SetShadowOffset then textWidget:SetShadowOffset(g_rayansyed_ESPV2(1.0, 1.0)) end
            if textWidget.SetShadowColorAndOpacity then textWidget:SetShadowColorAndOpacity(ESP_BLACK) end
        end
    end)
end

local function g_rayansyed_ESPSetTextColor(textWidget, color)
    if not g_rayansyed_ESPValid(textWidget) then return end
    pcall(function()
        if SlateColor then textWidget:SetColorAndOpacity(SlateColor(color))
        else textWidget:SetColorAndOpacity(color) end
    end)
end

local function g_rayansyed_ESPCreateLine(color)
    local canvas = g_rayansyed_ESPGetCanvas()
    if not g_rayansyed_ESPValid(canvas) then return nil end
    local border = nil
    pcall(function() border = CGame:NewObjectFromPath("/Script/UMG.Border", canvas) end)
    if not g_rayansyed_ESPValid(border) then return nil end
    pcall(function()
        border:SetBrushColor(color)
        border:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        border:SetRenderTransformPivot(g_rayansyed_ESPV2(0.0, 0.5))
    end)
    local slot = nil
    pcall(function() slot = canvas:AddChildToCanvas(border) end)
    if not slot then g_rayansyed_ESPDestroyWidgetData({Widget=border}) return nil end
    pcall(function() slot:SetAutoSize(false) slot:SetZOrder(30) end)
    return {Widget=border, Slot=slot}
end

local function g_rayansyed_ESPDrawLine(data, x1, y1, x2, y2, thickness)
    if not data or not g_rayansyed_ESPValid(data.Widget) or not data.Slot then return false end
    local dx, dy = x2-x1, y2-y1
    local len = math.sqrt(dx*dx + dy*dy)
    if len < 1 then return false end
    local angle = ((math.atan2 and math.atan2(dy, dx)) or math.atan(dy, dx)) * 180.0 / math.pi
    pcall(function()
        data.Slot:SetPosition(g_rayansyed_ESPV2(x1, y1 - thickness*0.5))
        data.Slot:SetSize(g_rayansyed_ESPV2(len, thickness))
        data.Widget:SetRenderAngle(angle)
        data.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
    end)
    return true
end

local function g_rayansyed_ESPHideLine(data)
    if data and g_rayansyed_ESPValid(data.Widget) then
        pcall(function() data.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
    end
end

local function g_rayansyed_ESPCreateNameTag(isBot)
    local canvas = g_rayansyed_ESPGetCanvas()
    if not g_rayansyed_ESPValid(canvas) then return nil end
    local container, nameText, distanceText = nil, nil, nil
    pcall(function() container = CGame:NewObjectFromPath("/Script/UMG.CanvasPanel", canvas) end)
    if not g_rayansyed_ESPValid(container) then return nil end
    pcall(function() nameText = CGame:NewObjectFromPath("/Script/UMG.TextBlock", container) end)
    pcall(function() distanceText = CGame:NewObjectFromPath("/Script/UMG.TextBlock", container) end)
    if not g_rayansyed_ESPValid(nameText) or not g_rayansyed_ESPValid(distanceText) then
        g_rayansyed_ESPDestroyWidgetData({Widget=container})
        return nil
    end
    pcall(function()
        nameText:SetText("")
        distanceText:SetText("")
        nameText:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        distanceText:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        if nameText.SetJustification then nameText:SetJustification(1) end
        if distanceText.SetJustification then distanceText:SetJustification(1) end
    end)
    g_rayansyed_ESPSetTextColor(nameText, ESP_WHITE)
    g_rayansyed_ESPSetTextColor(distanceText, ESP_WHITE)
    g_rayansyed_ESPSetFont(nameText, tonumber(_G.g_rayansyed_MasterShotESP.NameFontSize) or 10, 1)
    g_rayansyed_ESPSetFont(distanceText, tonumber(_G.g_rayansyed_MasterShotESP.DistanceFontSize) or 8, 1)
    local nameSlot, distanceSlot, mainSlot = nil, nil, nil
    pcall(function() nameSlot = container:AddChildToCanvas(nameText) end)
    pcall(function() distanceSlot = container:AddChildToCanvas(distanceText) end)
    pcall(function() mainSlot = canvas:AddChildToCanvas(container) end)
    if not nameSlot or not distanceSlot or not mainSlot then
        g_rayansyed_ESPDestroyWidgetData({Widget=container})
        return nil
    end
    pcall(function()
        nameSlot:SetAutoSize(true)
        nameSlot:SetAlignment(g_rayansyed_ESPV2(0.5, 0.5))
        nameSlot:SetZOrder(2)
        distanceSlot:SetAutoSize(true)
        distanceSlot:SetAlignment(g_rayansyed_ESPV2(0.5, 0.5))
        distanceSlot:SetZOrder(2)
        mainSlot:SetAutoSize(false)
        mainSlot:SetZOrder(35)
    end)
    return {
        Widget = container, Text = nameText, DistanceText = distanceText,
        TextSlot = nameSlot, DistanceSlot = distanceSlot, Slot = mainSlot, IsBot = isBot
    }
end

local function g_rayansyed_ESPUpdateNameTag(key, character, headScreen, footScreen, isBot, distance)
    local data = g_rayansyed_ShotESP.Names[key]
    if not _G.g_rayansyed_MasterShotESP.ShowName and not _G.g_rayansyed_MasterShotESP.ShowDistance then
        if data and g_rayansyed_ESPValid(data.Widget) then
            pcall(function() data.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
        end
        return
    end
    local name = data and data.CachedName or nil
    if not name then
        name = g_rayansyed_ESPResolvePlayerName(character)
        if data and name then data.CachedName = name end
    end
    if not headScreen then
        if data and g_rayansyed_ESPValid(data.Widget) then
            pcall(function() data.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
        end
        return
    end
    if not data or not g_rayansyed_ESPValid(data.Widget) then
        g_rayansyed_ESPDestroyWidgetData(data)
        data = g_rayansyed_ESPCreateNameTag(isBot)
        g_rayansyed_ShotESP.Names[key] = data
        if data then data.CachedName = name end
    end
    if not data then return end
    local dist = math.max(0, math.floor((tonumber(distance) or 0) + 0.5))
    local distanceLabel = string.format("[%d m]", dist)
    local nameStr = name or ""
    local chars = math.max(#nameStr, #distanceLabel)
    local width = math.max(78.0, math.min(220.0, 18.0 + chars * 6.0))
    local nameHeight = 18.0
    local gap = tonumber(_G.g_rayansyed_MasterShotESP.NameGap) or 2.0
    local x = headScreen.X - width * 0.5
    local y = headScreen.Y - nameHeight - gap
    local distanceY = nameHeight + 4.0
    if footScreen and tonumber(footScreen.X) and tonumber(footScreen.Y) then
        distanceY = (footScreen.Y - y) + (tonumber(_G.g_rayansyed_MasterShotESP.DistanceBelowFeet) or 8.0)
    end
    local totalHeight = math.max(34.0, distanceY + 12.0)
    pcall(function()
        if _G.g_rayansyed_MasterShotESP.ShowName and nameStr ~= "" then
            if data.LastName ~= nameStr then
                data.Text:SetText(nameStr)
                data.LastName = nameStr
            end
            data.Text:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        else
            data.Text:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
        end
        if _G.g_rayansyed_MasterShotESP.ShowDistance then
            if data.LastDistance ~= distanceLabel then
                data.DistanceText:SetText(distanceLabel)
                data.LastDistance = distanceLabel
            end
            data.DistanceText:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        else
            data.DistanceText:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
        end
        data.Slot:SetPosition(g_rayansyed_ESPV2(x, y))
        data.Slot:SetSize(g_rayansyed_ESPV2(width, totalHeight))
        data.TextSlot:SetPosition(g_rayansyed_ESPV2(width * 0.5, nameHeight * 0.5))
        local distX = width * 0.5
        if footScreen and tonumber(footScreen.X) then distX = footScreen.X - x end
        data.DistanceSlot:SetPosition(g_rayansyed_ESPV2(distX, distanceY))
        data.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
    end)
end

local function g_rayansyed_ESPCreateCounter()
    local canvas = g_rayansyed_ESPGetCanvas()
    if not g_rayansyed_ESPValid(canvas) then return nil end
    local container = nil
    pcall(function() container = CGame:NewObjectFromPath("/Script/UMG.CanvasPanel", canvas) end)
    if not g_rayansyed_ESPValid(container) then return nil end
    local function newBorder()
        local w = nil
        pcall(function() w = CGame:NewObjectFromPath("/Script/UMG.Border", container) end)
        return w
    end
    local function newText()
        local w = nil
        pcall(function() w = CGame:NewObjectFromPath("/Script/UMG.TextBlock", container) end)
        return w
    end
    local realOuter, realInner, realGloss = newBorder(), newBorder(), newBorder()
    local botOuter, botInner, botGloss = newBorder(), newBorder(), newBorder()
    local leftTipOuter, leftTipInner, leftTipGloss = newBorder(), newBorder(), newBorder()
    local rightTipOuter, rightTipInner, rightTipGloss = newBorder(), newBorder(), newBorder()
    local diamondOuter, diamondInner, diamondGloss = newBorder(), newBorder(), newBorder()
    local realText, botText = newText(), newText()
    for _, w in ipairs({realOuter, realInner, realGloss, botOuter, botInner, botGloss,
        leftTipOuter, leftTipInner, leftTipGloss, rightTipOuter, rightTipInner, rightTipGloss,
        diamondOuter, diamondInner, diamondGloss, realText, botText}) do
        if not g_rayansyed_ESPValid(w) then
            g_rayansyed_ESPDestroyWidgetData({Widget=container})
            return nil
        end
    end
    pcall(function()
        realOuter:SetBrushColor(ESP_REAL_DARK)
        realInner:SetBrushColor(ESP_REAL)
        realGloss:SetBrushColor(ESP_REAL_LIGHT)
        botOuter:SetBrushColor(ESP_BOT_DARK)
        botInner:SetBrushColor(ESP_BOT)
        botGloss:SetBrushColor(ESP_BOT_LIGHT)
        leftTipOuter:SetBrushColor(ESP_REAL_DARK)
        leftTipInner:SetBrushColor(ESP_REAL)
        leftTipGloss:SetBrushColor(ESP_REAL_LIGHT)
        rightTipOuter:SetBrushColor(ESP_BOT_DARK)
        rightTipInner:SetBrushColor(ESP_BOT)
        rightTipGloss:SetBrushColor(ESP_BOT_LIGHT)
        diamondOuter:SetBrushColor(g_rayansyed_ESPScaleColor(ESP_WHITE_SOFT, 0.68, 1.0))
        diamondInner:SetBrushColor(ESP_WHITE_SOFT)
        diamondGloss:SetBrushColor(ESP_WHITE_GLOSS)
        for _, w in ipairs({realOuter, realInner, realGloss, botOuter, botInner, botGloss,
            leftTipOuter, leftTipInner, leftTipGloss, rightTipOuter, rightTipInner, rightTipGloss,
            diamondOuter, diamondInner, diamondGloss, realText, botText}) do
            w:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        end
        realText:SetText("REAL 0")
        botText:SetText("BOT 0")
        if realText.SetJustification then realText:SetJustification(1) end
        if botText.SetJustification then botText:SetJustification(1) end
        for _, w in ipairs({
            leftTipOuter, leftTipInner, leftTipGloss,
            rightTipOuter, rightTipInner, rightTipGloss,
            diamondOuter, diamondInner, diamondGloss
        }) do
            if w.SetRenderAngle then w:SetRenderAngle(45.0) end
            if w.SetRenderTransformPivot then w:SetRenderTransformPivot(g_rayansyed_ESPV2(0.5, 0.5)) end
        end
    end)
    g_rayansyed_ESPSetTextColor(realText, ESP_WHITE)
    g_rayansyed_ESPSetTextColor(botText, ESP_WHITE)
    g_rayansyed_ESPSetFont(realText, 12, 1)
    g_rayansyed_ESPSetFont(botText, 12, 1)
    local slots = {}
    local function add(name, widget)
        local s = nil
        pcall(function() s = container:AddChildToCanvas(widget) end)
        slots[name] = s
        return s
    end
    add("realOuter", realOuter); add("realInner", realInner); add("realGloss", realGloss)
    add("botOuter", botOuter); add("botInner", botInner); add("botGloss", botGloss)
    add("leftTipOuter", leftTipOuter); add("leftTipInner", leftTipInner); add("leftTipGloss", leftTipGloss)
    add("rightTipOuter", rightTipOuter); add("rightTipInner", rightTipInner); add("rightTipGloss", rightTipGloss)
    add("diamondOuter", diamondOuter); add("diamondInner", diamondInner); add("diamondGloss", diamondGloss)
    add("realText", realText); add("botText", botText)
    local mainSlot = nil
    pcall(function() mainSlot = canvas:AddChildToCanvas(container) end)
    if not mainSlot then
        g_rayansyed_ESPDestroyWidgetData({Widget=container})
        return nil
    end
    local width = tonumber(_G.g_rayansyed_MasterShotESP.CounterWidth) or 188.0
    local height = tonumber(_G.g_rayansyed_MasterShotESP.CounterHeight) or 26.0
    local diamond = tonumber(_G.g_rayansyed_MasterShotESP.CounterDiamondSize) or 20.0
    local half = width * 0.5
    local tip = math.floor(height * 0.72 + 0.5)
    local bodyW = half - (diamond * 0.50) - (tip * 0.55)
    local glossH = math.max(5.0, height * 0.38)
    pcall(function()
        local function setBox(slot, x, y, w, h, z)
            if slot then
                slot:SetAutoSize(false)
                slot:SetPosition(g_rayansyed_ESPV2(x, y))
                slot:SetSize(g_rayansyed_ESPV2(w, h))
                if z then slot:SetZOrder(z) end
            end
        end
        local leftBodyX = tip * 0.35
        local rightBodyX = half + diamond * 0.50
        setBox(slots.realOuter, leftBodyX, 0, bodyW, height, 1)
        setBox(slots.realInner, leftBodyX + 1, 1, bodyW - 2, height - 2, 2)
        setBox(slots.realGloss, leftBodyX + 4, 2, bodyW - 10, glossH, 3)
        setBox(slots.botOuter, rightBodyX, 0, bodyW, height, 1)
        setBox(slots.botInner, rightBodyX + 1, 1, bodyW - 2, height - 2, 2)
        setBox(slots.botGloss, rightBodyX + 4, 2, bodyW - 10, glossH, 3)
        local tipY = (height - tip) * 0.5
        setBox(slots.leftTipOuter, 0, tipY, tip, tip, 4)
        setBox(slots.leftTipInner, 1.5, tipY + 1.5, tip - 3, tip - 3, 5)
        setBox(slots.leftTipGloss, 4.0, tipY + 2.0, tip * 0.38, tip * 0.38, 6)
        local rightTipX = width - tip
        setBox(slots.rightTipOuter, rightTipX, tipY, tip, tip, 4)
        setBox(slots.rightTipInner, rightTipX + 1.5, tipY + 1.5, tip - 3, tip - 3, 5)
        setBox(slots.rightTipGloss, rightTipX + tip * 0.34, tipY + 2.0, tip * 0.38, tip * 0.38, 6)
        local dx = half - diamond * 0.5
        local dy = (height - diamond) * 0.5
        setBox(slots.diamondOuter, dx, dy, diamond, diamond, 8)
        setBox(slots.diamondInner, dx + 1.5, dy + 1.5, diamond - 3, diamond - 3, 9)
        setBox(slots.diamondGloss, dx + 3.0, dy + 2.0, diamond * 0.44, diamond * 0.44, 10)
        slots.realText:SetAutoSize(true)
        slots.botText:SetAutoSize(true)
        slots.realText:SetAlignment(g_rayansyed_ESPV2(0.5, 0.5))
        slots.botText:SetAlignment(g_rayansyed_ESPV2(0.5, 0.5))
        slots.realText:SetPosition(g_rayansyed_ESPV2(leftBodyX + (bodyW * 0.52), height * 0.50))
        slots.botText:SetPosition(g_rayansyed_ESPV2(rightBodyX + (bodyW * 0.48), height * 0.50))
        slots.realText:SetZOrder(12)
        slots.botText:SetZOrder(12)
        mainSlot:SetAutoSize(false)
        mainSlot:SetSize(g_rayansyed_ESPV2(width, height))
        mainSlot:SetZOrder(60)
    end)
    return {
        Widget=container, Slot=mainSlot,
        RealText=realText, BotText=botText,
        Width=width, Height=height, DiamondSize=diamond,
        Slots=slots
    }
end

local function g_rayansyed_ESPUpdateCounter(realCount, botCount, pc)
    local data = g_rayansyed_ShotESP.Counter
    if not data or not g_rayansyed_ESPValid(data.Widget) then
        data = g_rayansyed_ESPCreateCounter()
        g_rayansyed_ShotESP.Counter = data
    end
    if not data then return nil end
    local cw = g_rayansyed_ESPGetCanvasLocalSize()
    local centerX = nil
    if tonumber(cw) and cw > 1 then
        centerX = cw * 0.5
    else
        local vw = g_rayansyed_ESPViewport(pc)
        centerX = (vw * 0.5) * (g_rayansyed_ShotESP.CanvasScaleX or 1.0) + (g_rayansyed_ShotESP.CanvasOffsetX or 0.0)
    end
    if not centerX then return nil end
    local counterY = tonumber(_G.g_rayansyed_MasterShotESP.CounterY) or 36.0
    if data.LastReal ~= realCount then
        pcall(function() data.RealText:SetText(string.format("REAL %d", realCount or 0)) end)
        data.LastReal = realCount
    end
    if data.LastBot ~= botCount then
        pcall(function() data.BotText:SetText(string.format("BOT %d", botCount or 0)) end)
        data.LastBot = botCount
    end
    pcall(function()
        data.Slot:SetPosition(g_rayansyed_ESPV2(centerX - data.Width * 0.5, counterY))
        data.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
    end)
    local diamondSize = tonumber(data.DiamondSize) or 20.0
    local anchorX = centerX
    local anchorY = counterY + (data.Height * 0.5) + (diamondSize / math.sqrt(2.0))
    data.AnchorX = anchorX
    data.AnchorY = anchorY
    g_rayansyed_ShotESP.TracerOrigin = g_rayansyed_ESPV2(anchorX, anchorY)
    return g_rayansyed_ShotESP.TracerOrigin
end

local function g_rayansyed_ESPScanEnemies()
    local pc = g_rayansyed_ESPGetController()
    local me = g_rayansyed_ESPGetLocalCharacter()
    if not pc or not me then g_rayansyed_ShotESP.Enemies = {} return nil, 0, 0 end
    local myLoc = g_rayansyed_ESPActorLocation(me)
    if not myLoc then g_rayansyed_ShotESP.Enemies = {} return pc, 0, 0 end
    local myTeam = g_rayansyed_ESPGetTeamID(me)
    local list = {}
    local realCount, botCount = 0, 0
    local pawns = nil
    pcall(function() if Game and Game.GetAllPlayerPawns then pawns = Game:GetAllPlayerPawns() end end)
    if pawns then
        for _, character in pairs(pawns) do
            if g_rayansyed_ESPValid(character) and character ~= me and g_rayansyed_ESPIsAlive(character) then
                local team = g_rayansyed_ESPGetTeamID(character)
                if myTeam == nil or team == nil or tostring(team) ~= tostring(myTeam) then
                    local loc = g_rayansyed_ESPActorLocation(character)
                    local dist = g_rayansyed_ESPDistanceMeters(myLoc, loc)
                    if dist <= (tonumber(_G.g_rayansyed_MasterShotESP.MaxRangeMeters) or 400.0) then
                        local isBot = g_rayansyed_ESPIsBot(character)
                        if isBot then botCount = botCount + 1 else realCount = realCount + 1 end
                        list[#list+1] = {Character=character, Key=g_rayansyed_ESPGetPlayerKey(character), IsBot=isBot, Distance=dist}
                    end
                end
            end
        end
    end
    table.sort(list, function(a,b) return (a.Distance or 99999) < (b.Distance or 99999) end)
    g_rayansyed_ShotESP.Enemies = list
    return pc, realCount, botCount
end

local function g_rayansyed_ESPPrune(active)
    for key, data in pairs(g_rayansyed_ShotESP.Lines) do
        if not active[key] then g_rayansyed_ESPDestroyWidgetData(data) g_rayansyed_ShotESP.Lines[key] = nil end
    end
    for key, data in pairs(g_rayansyed_ShotESP.Names) do
        if not active[key] then g_rayansyed_ESPDestroyWidgetData(data) g_rayansyed_ShotESP.Names[key] = nil end
    end
end

-- ==========================================
-- 🎯 AIM CIRCLE VISUAL INDICATOR
-- FOV ke hisab se bara/chota hota hai
-- ==========================================
local _aimCircleWidgets = {}
local _aimCircleCanvas = nil
local _aimCircleLastCanvas = nil
local _aimCircleLastFov = -1
local AIM_CIRCLE_SEGMENTS = 32

local function _aimCircleGetCanvas()
    local fresh = g_rayansyed_ESPGetCanvas()
    if fresh and g_rayansyed_ESPValid(fresh) then
        _aimCircleCanvas = fresh
        return fresh
    end
    return _aimCircleCanvas
end

local function _aimCircleCreate(canvas, index)
    local border = CGame:NewObjectFromPath("/Script/UMG.Border", canvas)
    if not (border and g_rayansyed_ESPValid(border)) then return nil end
    local slot = canvas:AddChildToCanvas(border)
    if not slot then
        pcall(function() border:ConditionalBeginDestroy() end)
        return nil
    end
    pcall(function()
        border:SetBrushColor(g_rayansyed_ESPColor(1.0, 0.28, 0.28, 0.92))
        border:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        border:SetRenderTransformPivot(g_rayansyed_ESPV2(0, 0.5))
        slot:SetAutoSize(false)
        slot:SetZOrder(28)
    end)
    return { Widget = border, Slot = slot }
end

local function _aimCircleDraw(centerX, centerY, radius, r, g, b)
    local canvas = _aimCircleGetCanvas()
    if not canvas then return end
    if not (g_rayansyed_ESPValid(canvas)) then return end

    -- Naya canvas mile to purane widgets delete karo
    if _aimCircleLastCanvas ~= canvas then
        for _, w in pairs(_aimCircleWidgets) do
            if w and w.Widget and g_rayansyed_ESPValid(w.Widget) then
                pcall(function() w.Widget:RemoveFromParent() end)
                pcall(function() w.Widget:ConditionalBeginDestroy() end)
            end
        end
        _aimCircleWidgets = {}
        _aimCircleLastCanvas = canvas
    end

    local thick = math.max(1.5, radius * 0.008)
    local twoPi = math.pi * 2

    for i = 1, AIM_CIRCLE_SEGMENTS do
        local a1 = ((i - 1) / AIM_CIRCLE_SEGMENTS) * twoPi
        local a2 = (i / AIM_CIRCLE_SEGMENTS) * twoPi
        local x1 = centerX + math.cos(a1) * radius
        local y1 = centerY + math.sin(a1) * radius
        local x2 = centerX + math.cos(a2) * radius
        local y2 = centerY + math.sin(a2) * radius

        local w = _aimCircleWidgets[i]
        if not w or not g_rayansyed_ESPValid(w.Widget) then
            w = _aimCircleCreate(canvas, i)
            _aimCircleWidgets[i] = w
        end

        if w and w.Widget and g_rayansyed_ESPValid(w.Widget) and w.Slot then
            local dx, dy = x2 - x1, y2 - y1
            local len = math.sqrt(dx * dx + dy * dy)
            if len < 0.5 then len = 0.5 end
            local angle = math.atan(dy, dx) * 180 / math.pi

            pcall(function()
                w.Slot:SetPosition(g_rayansyed_ESPV2(x1, y1 - thick * 0.5))
                w.Slot:SetSize(g_rayansyed_ESPV2(len + 0.5, thick))
                w.Widget:SetRenderAngle(angle)
                w.Widget:SetBrushColor(g_rayansyed_ESPColor(r, g, b, 0.92))
                w.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
            end)
        end
    end
end

local function _aimCircleHide()
    for _, w in pairs(_aimCircleWidgets) do
        if w and w.Widget and g_rayansyed_ESPValid(w.Widget) then
            pcall(function() w.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
        end
    end
end

local function _aimCircleUpdate(pc)
    -- Setting check
    if _G.AK_GetVal("AIM_CIRCLE") ~= 1 then
        _aimCircleHide()
        return
    end
    if not pc then
        _aimCircleHide()
        return
    end

    -- FOV index (5-25) → circle radius
    local fovVal = _G.AK_GetVal("AIMBOT_FOV")
    if not fovVal or fovVal < 5 then fovVal = 25 end
    if fovVal > 25 then fovVal = 25 end

    -- Viewport size
    local vw, vh = g_rayansyed_ESPViewport(pc)
    if not vw or not vh or vw <= 0 then
        _aimCircleHide()
        return
    end

    -- 🎯 Radius = FOV ke hisaab se (chhota rakhna hai)
    -- FOV 5  → chhota circle
    -- FOV 25 → bada circle
    -- Max radius = 20% of viewport width (chhota rakha)
    local maxRadius = vw * 0.20
    local minRadius = vw * 0.04
    local t = (fovVal - 5) / (25 - 5)   -- 0..1
    local radius = minRadius + (maxRadius - minRadius) * t

    -- 🎯 X/Y offset from INI
    local offsetX = tonumber(_G.AK_GetVal("AIM_CIRCLE_X")) or 0
    local offsetY = tonumber(_G.AK_GetVal("AIM_CIRCLE_Y")) or 0
    -- Clamp
    if offsetX < -200 then offsetX = -200 end
    if offsetX >  200 then offsetX =  200 end
    if offsetY < -200 then offsetY = -200 end
    if offsetY >  200 then offsetY =  200 end

    -- 🎯 Screen center → canvas coordinates
    local centerX, centerY
    local cw, ch = g_rayansyed_ESPGetCanvasLocalSize()
    if cw and ch and cw > 1 and ch > 1 then
        -- Canvas local space me direct center (accurate)
        centerX = cw * 0.5
        centerY = ch * 0.5
        local scaleFactor = cw / vw
        radius = radius * scaleFactor
    else
        -- Fallback
        centerX = vw * 0.5
        centerY = vh * 0.5
        if g_rayansyed_ShotESP and g_rayansyed_ShotESP.CanvasScaleX then
            centerX = centerX * (g_rayansyed_ShotESP.CanvasScaleX or 1.0) + (g_rayansyed_ShotESP.CanvasOffsetX or 0.0)
            centerY = centerY * (g_rayansyed_ShotESP.CanvasScaleY or 1.0) + (g_rayansyed_ShotESP.CanvasOffsetY or 0.0)
            radius = radius * (g_rayansyed_ShotESP.CanvasScaleX or 1.0)
        end
    end

    -- 🎯 Apply X/Y offset (canvas space me)
    centerX = centerX + offsetX
    centerY = centerY + offsetY

    -- Color pulse
    local now = g_rayansyed_ESPNow() or 0
    local pulse = 0.5 + 0.5 * math.sin(now * 3.0)
    local r = 1.0
    local g = 0.20 + 0.15 * pulse
    local b = 0.20 + 0.15 * pulse

    _aimCircleDraw(centerX, centerY, radius, r, g, b)
    _aimCircleLastFov = fovVal
end


local function g_rayansyed_ESPUpdate()
    if not _G.g_rayansyed_MasterShotESP.Enabled then
        g_rayansyed_ESPResetWidgets()
        return
    end
    local world = g_rayansyed_ESPWorld()
    if world ~= g_rayansyed_ShotESP.LastWorld then
        g_rayansyed_ESPResetWidgets()
        g_rayansyed_ShotESP.LastWorld = world
        g_rayansyed_ShotESP.LastScanClock = -999.0
        g_rayansyed_ShotESP.LastTransformClock = -999.0
        g_rayansyed_ShotESP.TracerOrigin = nil
    end
    local canvas = g_rayansyed_ESPGetCanvas()
    if not canvas then return end
    local now = g_rayansyed_ESPNow()
    local pc = g_rayansyed_ESPGetController()
    local realCount, botCount = nil, nil
    if (now - g_rayansyed_ShotESP.LastScanClock) >= (tonumber(_G.g_rayansyed_MasterShotESP.ScanInterval) or 0.30) then
        pc, realCount, botCount = g_rayansyed_ESPScanEnemies()
        g_rayansyed_ShotESP.LastScanClock = now
        g_rayansyed_ShotESP.RealCount, g_rayansyed_ShotESP.BotCount = realCount, botCount
    end
    pc = pc or g_rayansyed_ESPGetController()
    if not pc then return end
    if (now - (g_rayansyed_ShotESP.LastTransformClock or -999.0))
        >= (tonumber(_G.g_rayansyed_MasterShotESP.TransformInterval) or 0.50) then
        g_rayansyed_ESPUpdateCanvasTransform(pc)
        g_rayansyed_ShotESP.LastTransformClock = now
    end
    local originCenter = nil
    if _G.g_rayansyed_MasterShotESP.ShowCounter then
        originCenter = g_rayansyed_ESPUpdateCounter(
            g_rayansyed_ShotESP.RealCount or 0,
            g_rayansyed_ShotESP.BotCount or 0,
            pc
        )
    else
        local counterData = g_rayansyed_ShotESP.Counter
        if counterData and g_rayansyed_ESPValid(counterData.Widget) then
            pcall(function() counterData.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
        end
    end
    local active = {}
    local maxRendered = math.max(1, math.floor(tonumber(_G.g_rayansyed_MasterShotESP.MaxRendered) or 24))
    for i, item in ipairs(g_rayansyed_ShotESP.Enemies) do
        if i > maxRendered then break end
        local c = item.Character
        local key = item.Key
        if g_rayansyed_ESPValid(c) and g_rayansyed_ESPIsAlive(c) then
            local head = g_rayansyed_ESPHeadLocation(c)
            local feet = g_rayansyed_ESPFootLocation(c)
            local headScreen = g_rayansyed_ESPProject(pc, head)
            local footScreen = g_rayansyed_ESPProject(pc, feet)
            if headScreen then
                active[key] = true
                local color = item.IsBot and ESP_BOT or ESP_REAL
                local line = g_rayansyed_ShotESP.Lines[key]
                local colorKey = item.IsBot and "BOT" or "REAL"
                if not line or not g_rayansyed_ESPValid(line.Widget) then
                    g_rayansyed_ESPDestroyWidgetData(line)
                    line = g_rayansyed_ESPCreateLine(color)
                    if line then line.ColorKey = colorKey end
                    g_rayansyed_ShotESP.Lines[key] = line
                elseif line.ColorKey ~= colorKey then
                    pcall(function() line.Widget:SetBrushColor(color) end)
                    line.ColorKey = colorKey
                end
                if line then
                    if _G.g_rayansyed_MasterShotESP.ShowLine and originCenter then
                        g_rayansyed_ESPDrawLine(line, originCenter.X, originCenter.Y, headScreen.X, headScreen.Y,
                            tonumber(_G.g_rayansyed_MasterShotESP.TracerThickness) or 1.80)
                    else
                        g_rayansyed_ESPHideLine(line)
                    end
                end
                g_rayansyed_ESPUpdateNameTag(key, c, headScreen, footScreen, item.IsBot, item.Distance)
            end
        end
    end
            g_rayansyed_ESPPrune(active)
end

local function g_rayansyed_ESPTick()
    pcall(g_rayansyed_ESPUpdate)
    -- 🎯 AIM CIRCLE — ESP se independent chalao
    pcall(function()
        local pc = g_rayansyed_ESPGetController()
        if not pc then return end
        local canvas = g_rayansyed_ESPGetCanvas()
        if not canvas then return end
        -- Transform fresh karo taaki circle center/radius sahi ho
        local now = g_rayansyed_ESPNow()
        if (now - (g_rayansyed_ShotESP.LastTransformClock or -999.0)) >= 0.5 then
            g_rayansyed_ESPUpdateCanvasTransform(pc)
            g_rayansyed_ShotESP.LastTransformClock = now
        end
        _aimCircleUpdate(pc)
    end)
    local okTicker, ticker = pcall(require, "common.time_ticker")
    if okTicker and ticker and ticker.AddTimerOnce then
        ticker.AddTimerOnce(tonumber(_G.g_rayansyed_MasterShotESP.UpdateInterval) or 0.03, g_rayansyed_ESPTick)
    end
end

_G.g_rayansyed_MasterShotESPForceRefresh = function()
    g_rayansyed_ShotESP.LastScanClock = -999.0
    pcall(g_rayansyed_ESPUpdate)
end

g_rayansyed_ESPTick()

-- ==========================================
-- CUSTOM AIMBOT (AR Only)
-- ==========================================
local AR_WEAPON_IDS = {
    [101001]=true, [101004]=true, [101008]=true,
    [101005]=true, [101006]=true, [101003]=true,
    [101002]=true, [101007]=true, [101009]=true, [101010]=true,
}

local function IsARWeapon(weapon)
    if not Valid(weapon) then return false end
    local wID = 0
    pcall(function()
        if type(weapon.GetWeaponID) == "function" then wID = weapon:GetWeaponID()
        elseif type(weapon.GetItemDefineID) == "function" then
            local d = weapon:GetItemDefineID()
            if Valid(d) then wID = d.TypeSpecificID end
        end
    end)
    return wID > 0 and AR_WEAPON_IDS[wID] == true
end

local function GetBoneName(boneIdx)
    if boneIdx == 1 then return "head", 70
    elseif boneIdx == 2 then return "spine_03", 40
    elseif boneIdx == 3 then return "spine_01", 20
    elseif boneIdx == 4 then return "pelvis", 0
    end
    return "head", 70
end

local function GetAimTarget(pc, localPlayer, maxDist, fovVal)
    local FVector2D = import("Vector2D")
    local ui_util = require("client.common.ui_util")
    local vp = ui_util.GetViewportSize()
    if not vp then return nil end

    local vpX, vpY = vp.X, vp.Y

    -- 🎯 Circle ka center (X/Y offset ke saath)
    local offsetX = tonumber(_G.AK_GetVal("AIM_CIRCLE_X")) or 0
    local offsetY = tonumber(_G.AK_GetVal("AIM_CIRCLE_Y")) or 0
    if offsetX < -200 then offsetX = -200 end
    if offsetX >  200 then offsetX =  200 end
    if offsetY < -200 then offsetY = -200 end
    if offsetY >  200 then offsetY =  200 end

    local centerX = vpX * 0.5 + offsetX
    local centerY = vpY * 0.5 + offsetY

    -- 🎯 Radius = circle ke radius ke barabar
    local maxRadius = vpX * 0.20
    local minRadius = vpX * 0.04
    local t = (fovVal - 5) / (25 - 5)
    if t < 0 then t = 0 end
    if t > 1 then t = 1 end
    local FOV_RADIUS = minRadius + (maxRadius - minRadius) * t

    local allChars = {}
    local GDP = require("GameLua.GameCore.Data.GameplayData")
    if GDP.GetAllPlayerCharacters then allChars = GDP.GetAllPlayerCharacters()
    elseif GDP.GameCharacters then for _, c in pairs(GDP.GameCharacters) do table.insert(allChars, c) end end
    local bestTarget, bestScore = nil, 99999999
    local myTeam = localPlayer:GetTeamID()
    for _, enemy in pairs(allChars) do
        if Valid(enemy) and enemy ~= localPlayer then
            local eTeam = 0
            pcall(function() if enemy.GetTeamID then eTeam = enemy:GetTeamID() end end)
            if eTeam ~= myTeam then
                local isDead = false
                pcall(function()
                    if type(enemy.IsDead) == "function" then isDead = enemy:IsDead()
                    elseif enemy.bIsDead ~= nil then isDead = enemy.bIsDead end
                    if enemy.HealthStatus == 2 then isDead = true end
                end)
                if not isDead then
                    local dist = localPlayer:GetDistanceTo(enemy)
                    if dist <= maxDist then
                        local tPos = nil
                        pcall(function()
                            if type(enemy.GetBonePos) == "function" then
                                tPos = enemy:GetBonePos("head", {X=0, Y=0, Z=0})
                            end
                        end)
                        if not tPos and type(enemy.K2_GetActorLocation) == "function" then
                            tPos = enemy:K2_GetActorLocation()
                            if tPos then tPos.Z = tPos.Z + 70 end
                        end
                        if tPos then
                            local screen = FVector2D()
                            local ok = pc:ProjectWorldLocationToScreen(tPos, screen, false)
                            if ok and screen.X > 0 and screen.Y > 0 then
                                -- 🎯 Circle ke center se distance
                                local dx = screen.X - centerX
                                local dy = screen.Y - centerY
                                local sDist = math.sqrt(dx*dx + dy*dy)
                                if sDist <= FOV_RADIUS and sDist < bestScore then
                                    bestScore = sDist
                                    bestTarget = enemy
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return bestTarget
end

local function ApplyAimbot()
    pcall(function()
        if _G.AK_GetVal("AIMBOT") ~= 1 then return end
        local player = GameplayData.GetPlayerCharacter()
        if not Valid(player) then return end
        local pc = player:GetPlayerControllerSafety()
        if not Valid(pc) then return end
        local weapon = nil
        if player.WeaponManagerComponent then weapon = player.WeaponManagerComponent.CurrentWeaponReplicated end
        if not Valid(weapon) and type(player.GetCurrentWeapon) == "function" then weapon = player:GetCurrentWeapon() end
        if not IsARWeapon(weapon) then return end
        local isADS = player.bIsGunADS
        local mode = _G.AK_GetVal("AIMBOT_MODE")
        if mode == 1 and isADS then return end
        if mode == 2 and not isADS then return end
        local fovVal = math.max(5, math.min(25, _G.AK_GetVal("AIMBOT_FOV") or 25))
        local speedVal = math.max(1, math.min(100, _G.AK_GetVal("AIMBOT_SPEED") or 50))
        if speedVal > 80 then speedVal = 80 end
        local maxDist = math.max(5000, math.min(25000, (_G.AK_GetVal("AIMBOT_DIST") or 250) * 100))
        local boneIdx = _G.AK_GetVal("AIMBOT_BONE") or 1
        local boneName, fallbackZ = GetBoneName(boneIdx)
        local target = GetAimTarget(pc, player, maxDist, fovVal)
        if not Valid(target) then return end
        local tPos = nil
        pcall(function()
            if type(target.GetBonePos) == "function" then tPos = target:GetBonePos(boneName, {X=0, Y=0, Z=0}) end
        end)
        if not tPos or (tPos.X == 0 and tPos.Y == 0 and tPos.Z == 0) then
            tPos = target:K2_GetActorLocation()
            if tPos then tPos.Z = tPos.Z + fallbackZ end
        end
        if not tPos then return end
        local UGameplayStatics = import("GameplayStatics")
        local KismetMathLibrary = import("KismetMathLibrary")
        local camManager = UGameplayStatics.GetPlayerCameraManager(pc, 0)
        if not Valid(camManager) then return end
        local camLoc = camManager:GetCameraLocation()
        if not camLoc then return end
        local rot = KismetMathLibrary.FindLookAtRotation(camLoc, tPos)
        if not rot then return end
        local currentRot = pc:GetControlRotation()
        if not currentRot then return end
        local dYaw = rot.Yaw - currentRot.Yaw
        local dPitch = rot.Pitch - currentRot.Pitch
        if isADS then
            local camRot = nil
            if type(camManager.GetCameraRotation) == "function" then camRot = camManager:GetCameraRotation() end
            if camRot then
                dYaw = dYaw - (camRot.Yaw - currentRot.Yaw)
                dPitch = dPitch - (camRot.Pitch - currentRot.Pitch)
            end
        end
        if dYaw > 180 then dYaw = dYaw - 360 end
        if dYaw < -180 then dYaw = dYaw + 360 end
        if dPitch > 180 then dPitch = dPitch - 360 end
        if dPitch < -180 then dPitch = dPitch + 360 end
        local smooth = 1.0
        if speedVal < 100 then
            smooth = (speedVal / 100.0) * 0.5
            if smooth < 0.02 then smooth = 0.02 end
        end
        local newPitch = currentRot.Pitch + (dPitch * smooth)
        local newYaw = currentRot.Yaw + (dYaw * smooth)
        if _G.AK_GetVal("RECOIL_COMP") == 1 and player.bIsWeaponFiring then
            local recoilVal = _G.AK_GetVal("RECOIL_VAL") or 6
            if recoilVal > 6 then recoilVal = 6 end
            if recoilVal < 0 then recoilVal = 0 end
            newPitch = newPitch - (recoilVal * 0.15)
        end
        pc:SetControlRotation({ Pitch = newPitch, Yaw = newYaw, Roll = 0 }, "CustomAim")
    end)
end

-- ==========================================
-- ITEM DATABASE
-- ==========================================
local ItemDB = {
    [101001] = { name = "AKM", cat = "AR" }, [101002] = { name = "M16A4", cat = "AR" },
    [101003] = { name = "SCAR-L", cat = "AR" }, [101004] = { name = "M416", cat = "AR" },
    [101005] = { name = "Groza", cat = "AR" }, [101006] = { name = "AUG", cat = "AR" },
    [101007] = { name = "QBZ", cat = "AR" }, [101008] = { name = "M762", cat = "AR" },
    [101009] = { name = "Mk47", cat = "AR" }, [101010] = { name = "G36C", cat = "AR" },
    [101011] = { name = "AC-VAL", cat = "AR" }, [101012] = { name = "Honey Badger", cat = "AR" },
    [101100] = { name = "FAMAS", cat = "AR" }, [101101] = { name = "ASM Abakan", cat = "AR" },
    [101102] = { name = "ACE32", cat = "AR" },
    [102001] = { name = "UZI", cat = "SMG" }, [102002] = { name = "UMP45", cat = "SMG" },
    [102003] = { name = "Vector", cat = "SMG" }, [102004] = { name = "Thompson", cat = "SMG" },
    [102005] = { name = "Bizon", cat = "SMG" }, [102007] = { name = "MP5K", cat = "SMG" },
    [102008] = { name = "JS9", cat = "SMG" }, [102105] = { name = "P90", cat = "SMG" },
    [103001] = { name = "Kar98K", cat = "SNIPER" }, [103002] = { name = "M24", cat = "SNIPER" },
    [103003] = { name = "AWM", cat = "SNIPER" }, [103004] = { name = "SKS", cat = "SNIPER" },
    [103005] = { name = "VSS", cat = "SNIPER" }, [103006] = { name = "Mini14", cat = "SNIPER" },
    [103007] = { name = "Mk14", cat = "SNIPER" }, [103008] = { name = "Win94", cat = "SNIPER" },
    [103009] = { name = "SLR", cat = "SNIPER" }, [103010] = { name = "QBU", cat = "SNIPER" },
    [103011] = { name = "Mosin", cat = "SNIPER" }, [103012] = { name = "AMR", cat = "SNIPER" },
    [103100] = { name = "Mk12", cat = "SNIPER" }, [103102] = { name = "DSR", cat = "SNIPER" },
    [104001] = { name = "S686", cat = "SHOTGUN" }, [104002] = { name = "S1897", cat = "SHOTGUN" },
    [104003] = { name = "S12K", cat = "SHOTGUN" }, [104004] = { name = "DBS", cat = "SHOTGUN" },
    [104100] = { name = "SPAS-12", cat = "SHOTGUN" }, [104101] = { name = "M1014", cat = "SHOTGUN" },
    [104102] = { name = "NS2000", cat = "SHOTGUN" },
    [105001] = { name = "M249", cat = "LMG" }, [105002] = { name = "DP-28", cat = "LMG" },
    [105003] = { name = "M134", cat = "LMG" }, [105010] = { name = "MG3", cat = "LMG" },
    [106001] = { name = "P92", cat = "PISTOL" }, [106002] = { name = "P1911", cat = "PISTOL" },
    [106003] = { name = "R1895", cat = "PISTOL" }, [106004] = { name = "P18C", cat = "PISTOL" },
    [106005] = { name = "R45", cat = "PISTOL" }, [106006] = { name = "Sawed-off", cat = "PISTOL" },
    [106007] = { name = "Flare Gun", cat = "PISTOL" }, [106008] = { name = "Skorpion", cat = "PISTOL" },
    [106010] = { name = "Desert Eagle", cat = "PISTOL" }, [106011] = { name = "Dual MP7", cat = "PISTOL" },
    [108001] = { name = "Machete", cat = "MELEE" }, [108002] = { name = "Crowbar", cat = "MELEE" },
    [108003] = { name = "Sickle", cat = "MELEE" }, [108004] = { name = "Pan", cat = "MELEE" },
    [108005] = { name = "Dagger", cat = "MELEE" },
    [107001] = { name = "Crossbow", cat = "SPECIAL" }, [107002] = { name = "RPG-7", cat = "SPECIAL" },
    [107003] = { name = "Riot Shield", cat = "SPECIAL" }, [107004] = { name = "Combat Drone", cat = "SPECIAL" },
    [107005] = { name = "Panzerfaust", cat = "SPECIAL" },
    [203001] = { name = "Red Dot", cat = "SCOPE" }, [203002] = { name = "Holo", cat = "SCOPE" },
    [203003] = { name = "2x Scope", cat = "SCOPE" }, [203004] = { name = "4x Scope", cat = "SCOPE" },
    [203005] = { name = "8x Scope", cat = "SCOPE" }, [203014] = { name = "3x Scope", cat = "SCOPE" },
    [203015] = { name = "6x Scope", cat = "SCOPE" },
    [602001] = { name = "Stun", cat = "GRENADE" }, [602002] = { name = "Smoke", cat = "GRENADE" },
    [602003] = { name = "Molotov", cat = "GRENADE" }, [602004] = { name = "Frag", cat = "GRENADE" },
    [601001] = { name = "Energy Drink", cat = "MED" }, [601002] = { name = "Adrenaline", cat = "MED" },
    [601003] = { name = "Painkiller", cat = "MED" }, [601004] = { name = "Bandage", cat = "MED" },
    [601005] = { name = "First Aid", cat = "MED" }, [601006] = { name = "Medkit", cat = "MED" },
    [601009] = { name = "Fast Bandage", cat = "MED" }, [601010] = { name = "Fast First Aid", cat = "MED" },
}

local ITEM_COLORS = {
    ["AR"]      = {R=255, G=255, B=0,   A=255},
    ["SMG"]     = {R=0,   G=255, B=255, A=255},
    ["SNIPER"]  = {R=255, G=0,   B=0,   A=255},
    ["SHOTGUN"] = {R=0,   G=255, B=0,   A=255},
    ["LMG"]     = {R=255, G=255, B=255, A=255},
    ["PISTOL"]  = {R=200, G=200, B=200, A=255},
    ["MELEE"]   = {R=150, G=150, B=150, A=255},
    ["SPECIAL"] = {R=255, G=0,   B=255, A=255},
    ["SCOPE"]   = {R=0,   G=100, B=255, A=255},
    ["GRENADE"] = {R=255, G=165, B=0,   A=255},
    ["MED"]     = {R=50,  G=255, B=50,  A=255},
}

local function IsCategoryEnabled(cat)
    if not _G.LexusConfig.ItemsMaster then return false end
    if cat == "AR"      then return _G.LexusConfig.ItemAR      end
    if cat == "SMG"     then return _G.LexusConfig.ItemSMG     end
    if cat == "SNIPER"  then return _G.LexusConfig.ItemSniper  end
    if cat == "SHOTGUN" then return _G.LexusConfig.ItemShotgun end
    if cat == "LMG"     then return _G.LexusConfig.ItemLMG     end
    if cat == "PISTOL"  then return _G.LexusConfig.ItemPistol  end
    if cat == "MELEE"   then return _G.LexusConfig.ItemMelee   end
    if cat == "SPECIAL" then return _G.LexusConfig.ItemSpecial end
    if cat == "SCOPE"   then return _G.LexusConfig.ItemScope   end
    if cat == "GRENADE" then return _G.LexusConfig.ItemGrenade end
    if cat == "MED"     then return _G.LexusConfig.ItemMed     end
    return false
end

-- ==========================================
-- ITEMS ESP
-- ==========================================
local _CachedItemActors = {}
local _LastItemScanTime = 0
local _CachedGI = nil

local function GetGameInstance()
    if _CachedGI and slua.isValid(_CachedGI) then return _CachedGI end
    pcall(function()
        if slua_GameFrontendHUD then _CachedGI = slua_GameFrontendHUD:GetGameInstance() end
        if not slua.isValid(_CachedGI) and UE4 and UE4.UGameplayStatics then
            _CachedGI = UE4.UGameplayStatics.GetGameInstance(slua_GameFrontendHUD)
        end
    end)
    return _CachedGI
end

_G.RunItemsESP = function(pc, localPlayer)
    if not _G.LexusConfig.ItemsMaster then return end
    if not Valid(pc) or not Valid(localPlayer) then return end
    local MyHUD = pc and pc.MyHUD or nil
    if not Valid(MyHUD) then return end
    local now = os.clock()
    if now - _LastItemScanTime > 1.5 then
        _LastItemScanTime = now
        _CachedItemActors = {}
        pcall(function()
            local myPos = localPlayer:K2_GetActorLocation()
            if not myPos then return end
            local GameplayStatics = import("GameplayStatics")
            local ActorClass = import("Actor")
            local PickupClass = nil
            for _, cn in ipairs({"STPickUpWrapperActor","PickUpWrapperActor","PickupWrapperActor","BattleItemPickUpWrapperActor"}) do
                local ok, cls = pcall(import, cn)
                if ok and cls then PickupClass = cls break end
            end
            if not PickupClass then return end
            local GI = GetGameInstance()
            if not GI or not slua.isValid(GI) then return end
            local ActorArray = slua.Array(UEnums.EPropertyClass.Object, ActorClass)
            local items = GameplayStatics.GetAllActorsOfClass(GI, PickupClass, ActorArray)
            if not items then return end
            local count = type(items.Num) == "function" and items:Num() or #items
            for i = 0, count - 1 do
                local item = type(items.Get) == "function" and items:Get(i) or items[i+1]
                if Valid(item) and not item.bHidden then
                    local itemPos = item:K2_GetActorLocation()
                    if itemPos then
                        local dx = itemPos.X - myPos.X
                        local dy = itemPos.Y - myPos.Y
                        local dz = itemPos.Z - myPos.Z
                        local dist = math.sqrt(dx*dx + dy*dy + dz*dz)
                        if dist <= 10000 then
                            local itemId = nil
                            pcall(function()
                                if item.DefineID then itemId = item.DefineID.TypeSpecificID
                                elseif item.DefineId then itemId = item.DefineId end
                                if not itemId and type(item.GetItemDefineID) == "function" then
                                    local d = item:GetItemDefineID()
                                    if Valid(d) then itemId = d.TypeSpecificID end
                                end
                                if not itemId and item.ItemID then itemId = item.ItemID end
                                if not itemId and item.PickUpID then itemId = item.PickUpID end
                            end)
                            if itemId and ItemDB[itemId] then
                                local cat = ItemDB[itemId].cat
                                if IsCategoryEnabled(cat) then
                                    table.insert(_CachedItemActors, {
                                        actor = item, itemId = itemId,
                                        name = ItemDB[itemId].name, cat = cat, dist = dist / 100,
                                    })
                                end
                            end
                        end
                    end
                end
            end
        end)
    end
    for _, entry in ipairs(_CachedItemActors) do
        if Valid(entry.actor) then
            local col = ITEM_COLORS[entry.cat] or {R=255, G=255, B=255, A=255}
            local text = string.format("%s [%.0fm]", entry.name, entry.dist)
            pcall(function()
                MyHUD:AddDebugText(text, entry.actor, 0.5, {X=0, Y=0, Z=30}, {X=0, Y=0, Z=30},
                    col, true, false, true, nil, 0.8, true)
            end)
        end
    end
end

-- ==========================================
-- VEHICLE DATABASE
-- ==========================================
local VehicleDB = {
    ["dacia"]       = { name = "Dacia",     flag = "VEH_DACIA" },
    ["uaz"]         = { name = "UAZ",       flag = "VEH_UAZ" },
    ["jeep"]        = { name = "UAZ",       flag = "VEH_UAZ" },
    ["buggy"]       = { name = "Buggy",     flag = "VEH_BUGGY" },
    ["coupe"]       = { name = "Coupe RB",  flag = "VEH_COUPE" },
    ["coupe rb"]    = { name = "Coupe RB",  flag = "VEH_COUPE" },
    ["mirado"]      = { name = "Mirado",    flag = "VEH_MIRADO" },
    ["bike"]        = { name = "Motor",     flag = "VEH_MOTOR" },
    ["motor"]       = { name = "Motor",     flag = "VEH_MOTOR" },
    ["moto"]        = { name = "Motor",     flag = "VEH_MOTOR" },
    ["scooter"]     = { name = "Scooter",   flag = "VEH_MOTOR" },
    ["brdm"]        = { name = "BRDM",      flag = "VEH_BRDM" },
    ["boat"]        = { name = "Boat",      flag = "VEH_BOAT" },
    ["aquarail"]    = { name = "Aquarail",  flag = "VEH_BOAT" },
    ["glider"]      = { name = "Glider",    flag = "VEH_OTHER" },
    ["lada"]        = { name = "Lada",      flag = "VEH_OTHER" },
    ["rondo"]       = { name = "Rondo",     flag = "VEH_OTHER" },
    ["zima"]        = { name = "Zima",      flag = "VEH_OTHER" },
    ["snowmobile"]  = { name = "Snowmobile",flag = "VEH_OTHER" },
    ["tuk"]         = { name = "Tuk Tuk",   flag = "VEH_OTHER" },
    ["mountainbike"]= { name = "Bicycle",   flag = "VEH_OTHER" },
    ["bicycle"]     = { name = "Bicycle",   flag = "VEH_OTHER" },
    ["tank"]        = { name = "Tank",      flag = "VEH_OTHER" },
    ["helicopter"]  = { name = "Helicopter",flag = "VEH_OTHER" },
    ["plane"]       = { name = "Plane",     flag = "VEH_OTHER" },
    ["aircraft"]    = { name = "Plane",     flag = "VEH_OTHER" },
    ["jetski"]      = { name = "Jet Ski",   flag = "VEH_BOAT" },
    ["lada_niva"]   = { name = "Niva",      flag = "VEH_OTHER" },
}

-- ==========================================
-- VEHICLES ESP
-- ==========================================
local _CachedVehicleActors = {}
local _LastVehicleScanTime = 0

_G.RunVehiclesESP = function(pc, localPlayer)
    if not _G.LexusConfig.VehMaster then return end
    if not Valid(pc) or not Valid(localPlayer) then return end
    local MyHUD = pc and pc.MyHUD or nil
    if not Valid(MyHUD) then return end
    local now = os.clock()
    if now - _LastVehicleScanTime > 2.0 then
        _LastVehicleScanTime = now
        _CachedVehicleActors = {}
        pcall(function()
            local myPos = localPlayer:K2_GetActorLocation()
            if not myPos then return end
            local GameplayStatics = import("GameplayStatics")
            local ActorClass = import("Actor")
            local VehicleClass = nil
            for _, cn in ipairs({"STExtraVehicleBase","VehicleBase","STExtraVehicle","Vehicle"}) do
                local ok, cls = pcall(import, cn)
                if ok and cls then VehicleClass = cls break end
            end
            if not VehicleClass then return end
            local GI = GetGameInstance()
            if not GI or not slua.isValid(GI) then return end
            local ActorArray = slua.Array(UEnums.EPropertyClass.Object, ActorClass)
            local vehicles = GameplayStatics.GetAllActorsOfClass(GI, VehicleClass, ActorArray)
            if not vehicles then return end
            local count = type(vehicles.Num) == "function" and vehicles:Num() or #vehicles
            for i = 0, count - 1 do
                local veh = type(vehicles.Get) == "function" and vehicles:Get(i) or vehicles[i+1]
                if Valid(veh) then
                    local vehPos = veh:K2_GetActorLocation()
                    if vehPos then
                        local dx = vehPos.X - myPos.X
                        local dy = vehPos.Y - myPos.Y
                        local dz = vehPos.Z - myPos.Z
                        local dist = math.sqrt(dx*dx + dy*dy + dz*dz)
                        if dist <= 35000 then
                            local vehName = nil
                            pcall(function()
                                if type(veh.GetVehicleName) == "function" then vehName = veh:GetVehicleName()
                                elseif veh.VehicleName then vehName = veh.VehicleName end
                            end)
                            local clsName = string.lower(tostring(veh))
                            local lookupKey = nil
                            if vehName then
                                local lower = string.lower(tostring(vehName))
                                for key, _ in pairs(VehicleDB) do
                                    if string.find(lower, key, 1, true) then lookupKey = key break end
                                end
                            end
                            if not lookupKey then
                                for key, _ in pairs(VehicleDB) do
                                    if string.find(clsName, key, 1, true) then lookupKey = key break end
                                end
                            end
                            if not lookupKey then lookupKey = "lada" end
                            if lookupKey then
                                local vdata = VehicleDB[lookupKey]
                                local flagVal = _G.AK_GetVal(vdata.flag)
                                if flagVal == 1 then
                                    local hasDriver = false
                                    pcall(function()
                                        local driver = type(veh.GetDriver) == "function" and veh:GetDriver() or nil
                                        if Valid(driver) then hasDriver = true end
                                    end)
                                    table.insert(_CachedVehicleActors, {
                                        actor = veh, name = vdata.name,
                                        dist = dist / 100, occupied = hasDriver,
                                    })
                                end
                            end
                        end
                    end
                end
            end
        end)
    end
    for _, entry in ipairs(_CachedVehicleActors) do
        if Valid(entry.actor) then
            local col = entry.occupied and {R=255, G=50, B=50, A=255} or {R=0, G=255, B=150, A=255}
            local text = string.format("%s [%.0fm]", entry.name, entry.dist)
            pcall(function()
                MyHUD:AddDebugText(text, entry.actor, 0.5, {X=0, Y=0, Z=50}, {X=0, Y=0, Z=50},
                    col, true, false, true, nil, 0.9, true)
            end)
        end
    end
end

-- ==========================================
-- MAIN LOOP
-- ==========================================
local function MainLoop()
    if _G.MOD_STOPPED then return end
    pcall(_G.AK_CheckINIReload)
    
    -- 🧹 Cleanup dead enemies every 10 sec
_G._LastCleanupTime = _G._LastCleanupTime or 0
if os.clock() - _G._LastCleanupTime > 10 then
    _G._LastCleanupTime = os.clock()
    if _G.KASHMIRYState and _G.KASHMIRYState.EnemyMarks then
        for key, md in pairs(_G.KASHMIRYState.EnemyMarks) do
            if not md.enemy or not Valid(md.enemy) then
                -- Undo color pehle
                pcall(function() UndoColorBodyV2(md.enemy, md) end)
                pcall(function() Undowallhackng(md.enemy, md) end)
                _G.KASHMIRYState.EnemyMarks[key] = nil
            end
        end
    end
end

    local okData, GDP = pcall(require, "GameLua.GameCore.Data.GameplayData")
    if not okData or not GDP then return end
    local pc = GDP.GetPlayerController()
    local localPlayer = nil
    if Valid(pc) then localPlayer = pc:GetPlayerCharacterSafety() end
    if not Valid(localPlayer) then
        _G.KASHMIRYState = _G.KASHMIRYState or {}
        _G.KASHMIRYState.EnemyMarks = {}
        return
    end
    local MyHUD = pc and pc.MyHUD or nil
    local newEspOn = _G.g_rayansyed_MasterShotESP and _G.g_rayansyed_MasterShotESP.Enabled

  -- 🎯 SMALL CROSS
    pcall(function()
        if not Valid(localPlayer) then return end
        local weapon = nil
        if localPlayer.WeaponManagerComponent then
            weapon = localPlayer.WeaponManagerComponent.CurrentWeaponReplicated
        end
        if not Valid(weapon) and type(localPlayer.GetCurrentWeapon) == "function" then
            weapon = localPlayer:GetCurrentWeapon()
        end
        if Valid(weapon) and _G.AK_GetVal("CROSSHAIR") == 1 then
            weapon.GameDeviationFactor = 0.0
            if weapon.GameDeviationAccuracy ~= nil then weapon.GameDeviationAccuracy = 0.0 end
            if weapon.RecoilKickADS ~= nil then weapon.RecoilKickADS = 0.0 end
            local entity = weapon.ShootWeaponEntityComp
            if Valid(entity) then
                entity.GameDeviationFactor = 0.0
                if entity.GameDeviationAccuracy ~= nil then entity.GameDeviationAccuracy = 0.0 end
                if entity.RecoilKickADS ~= nil then entity.RecoilKickADS = 0.0 end
            end
        end
    end)

    -- 📱 IPAD VIEW
    pcall(function()
        if not Valid(localPlayer) then return end
        local uTPPCam = localPlayer.ThirdPersonCameraComponent
        if Valid(uTPPCam) and not localPlayer.bIsWeaponAiming then
            if _G.AK_GetVal("IPAD_VIEW") == 1 then
                local targetFOV = tonumber(_G.AK_GetVal("IPAD_FOV")) or 120
                if targetFOV < 80 then targetFOV = 80 end
                if targetFOV > 140 then targetFOV = 140 end
                if uTPPCam.FieldOfView ~= targetFOV then
                    uTPPCam.FieldOfView = targetFOV
                end
            else
                if uTPPCam.FieldOfView ~= 80 then
                    uTPPCam.FieldOfView = 80
                end
            end
        end
    end)


    pcall(function()
        local lsg = require("client.slua.logic.setting.logic_setting_graphics")
        local gi = lsg and lsg.GetGameInstance and lsg.GetGameInstance()
        if gi then
            local skyOn = _G.AK_GetVal("BLACK_SKY") == 1
            if skyOn and not _G._BlackSkyOn then
                pcall(function() gi:ExecuteCMD("r.SkyAtmosphere", "0") end)
                pcall(function() gi:ExecuteCMD("r.SkyLUT", "0") end)
                pcall(function() gi:ExecuteCMD("r.Atmosphere", "0") end)
                pcall(function() gi:ExecuteCMD("r.SkyLight", "0") end)
                pcall(function() gi:ExecuteCMD("r.VolumetricFog", "0") end)
                _G._BlackSkyOn = true
            elseif not skyOn and _G._BlackSkyOn then
                pcall(function() gi:ExecuteCMD("r.SkyAtmosphere", "1") end)
                pcall(function() gi:ExecuteCMD("r.SkyLUT", "1") end)
                pcall(function() gi:ExecuteCMD("r.Atmosphere", "1") end)
                pcall(function() gi:ExecuteCMD("r.SkyLight", "1") end)
                pcall(function() gi:ExecuteCMD("r.VolumetricFog", "1") end)
                _G._BlackSkyOn = false
            end
        end
    end)

    pcall(function()
        local lsg = require("client.slua.logic.setting.logic_setting_graphics")
        local gi = lsg and lsg.GetGameInstance and lsg.GetGameInstance()
        if gi then
            local grassOn = _G.AK_GetVal("REMOVE_GRASS") == 1
            if grassOn and not _G._RemoveGrassOn then
                pcall(function() gi:ExecuteCMD("grass.DensityScale", "0") end)
                pcall(function() gi:ExecuteCMD("grass.DiscardDataOnLoad", "1") end)
                _G._RemoveGrassOn = true
            elseif not grassOn and _G._RemoveGrassOn then
                pcall(function() gi:ExecuteCMD("grass.DensityScale", "1") end)
                pcall(function() gi:ExecuteCMD("grass.DiscardDataOnLoad", "0") end)
                _G._RemoveGrassOn = false
            end
        end
    end)

    pcall(function()
        local lsg = require("client.slua.logic.setting.logic_setting_graphics")
        local gi = lsg and lsg.GetGameInstance and lsg.GetGameInstance()
        if gi then
            local treesOn = _G.AK_GetVal("REMOVE_TREES") == 1
            if treesOn and not _G._RemoveTreesOn then
                pcall(function() gi:ExecuteCMD("foliage.DensityScale", "0") end)
                pcall(function() gi:ExecuteCMD("r.Foliage.DensityScale", "0") end)
                pcall(function() gi:ExecuteCMD("foliage.MinimumScreenSize", "10000") end)
                _G._RemoveTreesOn = true
            elseif not treesOn and _G._RemoveTreesOn then
                pcall(function() gi:ExecuteCMD("foliage.DensityScale", "1") end)
                pcall(function() gi:ExecuteCMD("r.Foliage.DensityScale", "1") end)
                pcall(function() gi:ExecuteCMD("foliage.MinimumScreenSize", "0.0001") end)
                _G._RemoveTreesOn = false
            end
        end
    end)

    pcall(function()
        local lsg = require("client.slua.logic.setting.logic_setting_graphics")
        local gi = lsg and lsg.GetGameInstance and lsg.GetGameInstance()
        if gi then
            local fogOn = _G.AK_GetVal("REMOVE_FOG") == 1
            if fogOn and not _G._RemoveFogOn then
                pcall(function() gi:ExecuteCMD("r.Fog", "0") end)
                pcall(function() gi:ExecuteCMD("r.VolumetricFog", "0") end)
                _G._RemoveFogOn = true
            elseif not fogOn and _G._RemoveFogOn then
                pcall(function() gi:ExecuteCMD("r.Fog", "1") end)
                pcall(function() gi:ExecuteCMD("r.VolumetricFog", "1") end)
                _G._RemoveFogOn = false
            end
        end
    end)

    pcall(function()
        if _G.RunItemsESP then _G.RunItemsESP(pc, localPlayer) end
        if _G.RunVehiclesESP then _G.RunVehiclesESP(pc, localPlayer) end
    end)

    local allChars = {}
    if GDP.GetAllPlayerCharacters then allChars = GDP.GetAllPlayerCharacters()
    elseif GDP.GameCharacters then for _, c in pairs(GDP.GameCharacters) do table.insert(allChars, c) end end
    local myPos = nil
    pcall(function() myPos = localPlayer:K2_GetActorLocation() end)
    if not myPos then return end

    for _, enemy in pairs(allChars) do
        if Valid(enemy) and enemy ~= localPlayer then
            local eTeam = 0
            pcall(function() if enemy.GetTeamID then eTeam = enemy:GetTeamID() end end)
            local myTeam = 0
            pcall(function() if localPlayer.GetTeamID then myTeam = localPlayer:GetTeamID() end end)
            if eTeam ~= myTeam then
                local bDead, hp, mx, knock = false, 100, 100, false
                pcall(function()
                    if type(enemy.IsDead) == "function" then bDead = enemy:IsDead()
                    elseif enemy.bIsDead then bDead = enemy.bIsDead end
                    if enemy.HealthStatus == 2 then bDead = true end
                    if enemy.HealthStatus == 1 then knock = true end
                    if type(enemy.GetHealth) == "function" then hp = enemy:GetHealth()
                    elseif enemy.Health then hp = enemy.Health end
                    if type(enemy.GetHealthMax) == "function" then mx = enemy:GetHealthMax()
                    elseif enemy.HealthMax then mx = enemy.HealthMax end
                    if mx <= 0 then mx = 100 end
                end)
                if not bDead then
                    local ePos = enemy:K2_GetActorLocation()
                    local distM = 0
                    if ePos and myPos then
                        local dx = ePos.X - myPos.X
                        local dy = ePos.Y - myPos.Y
                        local dz = ePos.Z - myPos.Z
                        distM = math.sqrt(dx*dx + dy*dy + dz*dz) / 100
                    end
                    local isVis = false
                    pcall(function() if type(pc.LineOfSightTo) == "function" then isVis = pc:LineOfSightTo(enemy) end end)
                    local vColor = isVis and {R=0,G=255,B=0,A=255} or {R=255,G=0,B=0,A=255}

                    if not newEspOn then
                        if _G.AK_GetVal("ESP_NAME") == 1 and Valid(MyHUD) then
                            local nm = enemy.PlayerName or enemy.PlayerNamePublic or "Enemy"
                            MyHUD:AddDebugText(nm, enemy, 1.0, {X=0, Y=0, Z=340}, {X=0, Y=0, Z=340},
                                {R=255,G=255,B=255,A=255}, true, false, true, nil, 0.9, false)
                        end
                        if _G.AK_GetVal("ESP_HP") == 1 and Valid(MyHUD) then
                            local pct = (hp / mx) * 100
                            if knock then pct = 0 end
                            local col = GetHealthColor(pct)
                            local txt = knock and "DOWN" or string.format("%.0f%%", pct)
                            MyHUD:AddDebugText(txt, enemy, 1.0, {X=0, Y=0, Z=190}, {X=0, Y=0, Z=190},
                                col, true, false, true, nil, 0.7, false)
                        end
                        if _G.AK_GetVal("ESP_DISTANCE") == 1 and Valid(MyHUD) then
                            MyHUD:AddDebugText(string.format("%.0fm", distM), enemy, 1.0, {X=0, Y=0, Z=3}, {X=0, Y=0, Z=3},
                                {R=255,G=255,B=0,A=255}, true, false, true, nil, 0.8, false)
                        end
                        if _G.AK_GetVal("ESP_ANTENNA") == 1 and Valid(MyHUD) then
                            local ac = knock and {R=0,G=0,B=255,A=255} or vColor
                            for h = 130, 300, 10 do
                                MyHUD:AddDebugText("|", enemy, 1.0, {X=0,Y=0,Z=h}, {X=0,Y=0,Z=h},
                                    ac, true, false, true, nil, 0.8, false)
                            end
                        end
                        if _G.AK_GetVal("ENEMY_WEAPON") == 1 and Valid(MyHUD) then
                            local wpn = GetEnemyWeaponName(enemy)
                            MyHUD:AddDebugText(wpn, enemy, 1.0, {X=0, Y=0, Z=260}, {X=0, Y=0, Z=260},
                                {R=0,G=255,B=255,A=255}, true, false, true, nil, 0.75, false)
                        end
                    end

                    local eKeyWH = GetSafeEnemyKey(enemy)
                    _G.KASHMIRYState = _G.KASHMIRYState or {}
                    _G.KASHMIRYState.EnemyMarks = _G.KASHMIRYState.EnemyMarks or {}
                    local markDataWH = _G.KASHMIRYState.EnemyMarks[eKeyWH]
                    if not markDataWH then
                        markDataWH = { enemy = enemy }
                        _G.KASHMIRYState.EnemyMarks[eKeyWH] = markDataWH
                    end
                    markDataWH.enemy = enemy

-- MainLoop me wall hack section ke andar:
if _G.AK_GetVal("WALL_HACK") == 1 then
    Applywallhackng(enemy, markDataWH)
    ApplyColorBodyV2(enemy, pc, markDataWH)
else
    Undowallhackng(enemy, markDataWH)
    UndoColorBodyV2(enemy, markDataWH)
end
                    if _G.AK_GetVal("OUTLINE_ESP") == 1 then
                        ApplyOutlineESP(enemy, markDataWH)
                    else
                        UndoOutlineESP(enemy, markDataWH)
                    end
                end
            end
        end
    end
end

-- ==========================================
-- AIMBOT TICK
-- ==========================================
local function FastAimbotTick()
    if _G.MOD_STOPPED then return end
    if _G.AK_GetVal("AIMBOT") == 1 then
        local player = GameplayData.GetPlayerCharacter()
        if Valid(player) then
            local isFiring = player.bIsWeaponFiring
            if isFiring then pcall(ApplyAimbot) end
        end
    end
    local ok, t = pcall(require, "common.time_ticker")
    if ok and t and t.AddTimerOnce then t.AddTimerOnce(0.033, FastAimbotTick) end
end

_G.KASHMIRYState = _G.KASHMIRYState or {}
_G.KASHMIRYState.LoopToken = (_G.KASHMIRYState.LoopToken or 0) + 1
local myToken = _G.KASHMIRYState.LoopToken

local function FastTick()
    if myToken ~= _G.KASHMIRYState.LoopToken then return end
    pcall(MainLoop)
    local ok, t = pcall(require, "common.time_ticker")
    if ok and t and t.AddTimerOnce then t.AddTimerOnce(0.35, FastTick) end
end

-- ==========================================
-- START MOD
-- ==========================================
local function StartMod()
    pcall(function()
        if _G.AK_LoadINI then _G.AK_LoadINI(true) end
        if _G.SyncLexusConfig then _G.SyncLexusConfig() end
    end)
    pcall(function() Notify("MOD ACTIVATED!") end)
    FastTick()
    local ok, t = pcall(require, "common.time_ticker")
    if ok and t and t.AddTimerOnce then
        t.AddTimerOnce(0.1, FastAimbotTick)
    end
end

-- ==========================================
-- BRPlayerCharacterBase Class + DeclareFeature
-- ==========================================
function BRPlayerCharacterBase:ctor() end
function BRPlayerCharacterBase:_PostConstruct()
    BRPlayerCharacterBase.__super._PostConstruct(self)
    self:InitAddSpecialMoveInfo()
    self.bCanNearDeathGiveup = true
end
function BRPlayerCharacterBase:ReceiveBeginPlay()
    BRPlayerCharacterBase.__super.ReceiveBeginPlay(self)
    self:AddControlEvent(self, "MovementModeChangedDelegate", self.HandleOnMovementModeChangedNew, self)
    if self:HasAuthority() and self:CheckAddCheckFallingDistanceComponent() then
        local CheckFallingDistanceComponent_C = import("CheckFallingDistanceComponent")
        if slua.isValid(CheckFallingDistanceComponent_C) and not slua.isValid(self:GetComponentByClass(CheckFallingDistanceComponent_C)) then
            Game:AddComponent(CheckFallingDistanceComponent_C, self, "CheckFallingDistanceComponent")
        end
    end
    if slua.isValid(self.STCharacterMovement) then self.STCharacterMovement.bPositiveBlowUp = true end
    if self.Role == ENetRole.ROLE_AutonomousProxy then
        self:AddControlEvent(self, "OnPawnStateDisabled", self.OnPawnStateChange, self)
        self:AddControlEvent(self, "OnPawnStateEnabled", self.OnPawnStateChange, self)
        self:AddControlEventConditionOnly(self, "OnAttrChangeEventDelegate", { AttrName = { "bCanSelfRescue" } }, self.CharacterAttrChangeEvent, self)
    end
    if Client then
        GameplayData.AddCharacter(self.Object)
        self:AddControlEvent(self, "OnAttachedToVehicle", self.HandleOnAttachedToVehicle, self)
        self:AddControlEvent(self, "OnDetachedFromVehicle", self.HandleOnDetachedFromVehicle, self)
    else
        self:AddCommonEventWithConditions(EVENTTYPE_INGAME_NORMAL, EVENTID_GAME_MODE_STATE_CHANGE, { [1] = "FinishedState" }, self.HandleFinishedState, self)
    end
end
function BRPlayerCharacterBase:HandleOnAttachedToVehicle(uVehicle)
    if not slua.isValid(uVehicle) then return end
    if self.Role == ENetRole.ROLE_SimulatedProxy then
        self:ClearAttachToVehicleTimer()
        self.nUpdatePlayerAttachToVehicleCount = 0
        self.nUpdatePlayerAttachToVehicleTimer = self:AddGameTimer(5, true, function()
            if slua.isValid(self.Object) and slua.isValid(uVehicle) then self:UpdatePlayerAttachToVehicle(uVehicle) end
        end)
    end
end
function BRPlayerCharacterBase:HandleOnDetachedFromVehicle(uLastVehicle)
    if not slua.isValid(uLastVehicle) then return end
    if self.Role == ENetRole.ROLE_SimulatedProxy then
        self:ClearAttachToVehicleTimer()
        self.nUpdatePlayerAttachToVehicleCount = 0
    end
end
function BRPlayerCharacterBase:UpdatePlayerAttachToVehicle(uVehicle) end
function BRPlayerCharacterBase:FixMeshContainerOffsetIfNeeded(uVehicle) end
function BRPlayerCharacterBase:ClearAttachToVehicleTimer()
    if self.nUpdatePlayerAttachToVehicleTimer then
        self:RemoveGameTimer(self.nUpdatePlayerAttachToVehicleTimer)
        self.nUpdatePlayerAttachToVehicleTimer = nil
    end
    if self.nFixMeshContainerTimer then
        self:RemoveGameTimer(self.nFixMeshContainerTimer)
        self.nFixMeshContainerTimer = nil
    end
end
function BRPlayerCharacterBase:OnPawnStateChange(PawnState) end
function BRPlayerCharacterBase:HandleFinishedState()
    if slua.isValid(self.STCharacterMovement) and self.STCharacterMovement.SetDynamicSimpleQueryConfig then
        self.STCharacterMovement:SetDynamicSimpleQueryConfig(false)
    end
end
function BRPlayerCharacterBase:CheckAddCheckFallingDistanceComponent() return false end
function BRPlayerCharacterBase:LuaHandleParachuteStateChanged(LastParachuteState, NewParachuteState) end
function BRPlayerCharacterBase:OnLanded() end
function BRPlayerCharacterBase:ReceiveEndPlay(EndPlayReason)
    BRPlayerCharacterBase.__super.ReceiveEndPlay(self, EndPlayReason)
    if Client then GameplayData.RemoveCharacter(self.Object) end
end
function BRPlayerCharacterBase:IsWarGameMode() return false end
function BRPlayerCharacterBase:BPOnRecycled() if Client then self:ResetMeshRelativeLocationAndRotation() end end
function BRPlayerCharacterBase:BPOnRespawned() if Client then self:ResetMeshRelativeLocationAndRotation() end end
function BRPlayerCharacterBase:ReceiveOnRecycle()
    if Client then
        self:ResetMeshRelativeLocationAndRotation()
        GameplayData.RemoveCharacter(self.Object)
    end
end
function BRPlayerCharacterBase:ReceiveOnSpawn()
    if Client then
        self:ResetMeshRelativeLocationAndRotation()
        GameplayData.AddCharacter(self.Object)
    end
end
function BRPlayerCharacterBase:ResetMeshRelativeLocationAndRotation()
    if Game:IsValid(self.Object) and Game:IsValid(self.Mesh) then
        local uDefaultMeshRot = FRotator(0, -90, 0)
        local uDefaultMeshRelativeLoc = FVector(0, 0, 0)
        if self.Mesh.K2_SetRelativeRotation then
            self.Mesh:K2_SetRelativeRotation(uDefaultMeshRot, false, nil, false)
        end
        self:CacheInitialMeshOffset(uDefaultMeshRelativeLoc, uDefaultMeshRot)
    end
end
function BRPlayerCharacterBase:HandleOnMovementModeChangedNew()
    local EMovementMode = import("EMovementMode")
    if Game:IsValid(self.STCharacterMovement) and self.STCharacterMovement.MovementMode == EMovementMode.MOVE_Swimming and self:CheckBaseIsMoveable() then
        self.CharacterMovement:SetBase(nil, "", true)
    end
    if self.Role == ENetRole.ROLE_AutonomousProxy and Game:IsValid(self.STCharacterMovement) and self.STCharacterMovement.MovementMode == EMovementMode.MOVE_Walking and UIManager.UI_Config_InGame.ParachuteOpenUI then
        UIManager.CloseUI(UIManager.UI_Config_InGame.ParachuteOpenUI)
    end
end
function BRPlayerCharacterBase:BPOnMissPlayerDamageRecord() end

local class = require("class")
local CCharacterBase = require("GameLua.GameCore.Framework.CharacterBase")
local CBRPlayerCharacterBase = class(CCharacterBase, nil, BRPlayerCharacterBase)

-- ==========================================
-- 🚀 FINAL START (sab kuch load hone ke baad)
-- ==========================================
pcall(function()
    print("[ACE] Loading INI from: " .. tostring(_G.ConfigFilePath))
    local _testFile = io.open(_G.ConfigFilePath, "r")
    if _testFile then
        print("[ACE] INI file FOUND")
        _testFile:close()
    else
        print("[ACE] INI file NOT FOUND!")
    end
    if _G.AK_LoadINI then
        local ok, changed = pcall(_G.AK_LoadINI, true)
        print("[ACE] AK_LoadINI ok=" .. tostring(ok) .. " changed=" .. tostring(changed))
    end
    if _G.SyncLexusConfig then pcall(_G.SyncLexusConfig) end
    print("[ACE] ESP_LOAI9 = " .. tostring(_G.AK_GetVal("ESP_LOAI9")))
    print("[ACE] MasterShotESP.Enabled = " .. tostring(_G.g_rayansyed_MasterShotESP.Enabled))
end)

pcall(function() StartMod() end)

return require("combine_class").DeclareFeature(CBRPlayerCharacterBase, {
    { SkyTransition = "GameLua.Mod.BaseMod.Gameplay.Feature.SkyControl.PlayerCharacterSkyTransitionFeature" },
    { CarryDeadBoxFeature = "GameLua.Mod.Library.GamePlay.Feature.CarryDeadBoxFeature" },
    { SpecialSuitFeature = "GameLua.Mod.Library.GamePlay.Feature.SpecialSuitFeature" },
    { TeleportPawnFeature = "GameLua.Mod.Library.GamePlay.Feature.TeleportPawnFeature" },
    { LifterControl = "GameLua.Mod.BaseMod.Gameplay.Feature.Player.CharacterLifterControlFeature" },
    { FinalKillEffect = "GameLua.Mod.BaseMod.Gameplay.Feature.Player.PlayerCharacterFinalKillEffectFeature" },
    { CampFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.Camp.PlayerCharacterCampFeature" },
    { BuildSkateFeature = "GameLua.Mod.BaseMod.Gameplay.Feature.PlayerCharacterBuildVehicleFeature" },
    { CommonBornlandTransformFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.HeroFeature.CommonBornlandTransformFeature" },
    { ParachuteFormation = "GameLua.Mod.BaseMod.Gameplay.Feature.ParachuteFormationFeature" },
    { SpiderSenseFootprintFeature = "GameLua.Mod.Library.GamePlay.Feature.SpiderSenseFootprintFeature" },
    { GeneralShowSpotFeature = "GameLua.Mod.BRMod.Gameplay.Feature.PlayerCharacterGeneralShowSpotFeature" }
}, "BRPlayerCharacterBase")
