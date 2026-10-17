-- Remove obfuscation: watermark check and dummy loop are removed.
-- All meaningful logic is kept.

local class = require("class")
local CharacterBase = require("GameLua.GameCore.Framework.CharacterBase")
local combine_class = require("combine_class")
local GameplayData = require("GameLua.GameCore.Data.GameplayData")

-- ========== RPC Definitions ==========
local ServerRPCs = {
    ServerRPC_NearDeathGiveupRescue = { Reliable = true, Params = {} },
    ServerRPC_CarryDeadBox = { Reliable = true, Params = { UEnums.EPropertyClass.Object } },
    RPC_Server_GmPlayAction = { Reliable = true, Params = { UEnums.EPropertyClass.Int } }
}

local ClientRPCs = {
    RPC_Client_SetShouldCheckPassWall = { Reliable = true, Params = { UEnums.EPropertyClass.Bool } }
}

local MulticastRPCs = {
    MulticastRPC_GmPlayAction = { Reliable = true, Params = { UEnums.EPropertyClass.Int } }
}

-- Expose RPCs globally
_G.ServerRPC = ServerRPCs
_G.ClientRPC = ClientRPCs
_G.MulticastRPC = MulticastRPCs

-- ========== Path Finder ==========
function GetBasePath()
    local possiblePackages = {
        "com.tencent.ig",
        "com.pubg.krmobile",
        "com.pubg.krmobile",
        "com.vng.pubgmobile",
        "com.pubg.imobile"
    }
    for _, pkg in ipairs(possiblePackages) do
        local path = "/storage/emulated/0/Android/data/" .. pkg .. "/files/config.ini"
        local file = io.open(path, "r")
        if file then
            file:close()
            return "/storage/emulated/0/Android/data/" .. pkg .. "/files/"
        end
    end
    return "/storage/emulated/0/Android/data/com.tencent.ig/files/"
end

local BasePath = GetBasePath() .. "mods/"

-- ========== Feature Loader ==========
function _G.LoadAllFeatures()
    if _G._FeaturesLoaded then return end

    -- Check for disable file
    local offFile = io.open(BasePath .. ".off", "r")
    if offFile then
        offFile:close()
        _G.ModsEnabled = false
        _G._FeaturesLoaded = true
        return
    end

    _G.ModsEnabled = true

    -- Load numbered Lua files (1.lua, 2.lua, ...)
    for i = 1, 100 do
        local filename = BasePath .. i .. ".lua"
        local file = io.open(filename, "r")
        if not file then break end
        local content = file:read("*all")
        file:close()
        local chunk, err = load(content, filename)
        if chunk then
            pcall(chunk)
        else
            print("Error loading " .. filename .. ": " .. tostring(err))
        end
    end
    _G._FeaturesLoaded = true
end

-- ========== Player Character Class Extension ==========
local BRPlayerCharacterBase = class(CharacterBase, nil, {
    ServerRPC = ServerRPCs,
    ClientRPC = ClientRPCs,
    MulticastRPC = MulticastRPCs,

    ctor = function(self)
        -- constructor body (empty)
    end,

    _PostConstruct = function(self)
        CharacterBase._PostConstruct(self)
        self:InitAddSpecialMoveInfo()
        self.bCanNearDeathGiveup = true
    end,

    ReceiveBeginPlay = function(self)
        CharacterBase.ReceiveBeginPlay(self)

        if slua.isValid(self.STCharacterMovement) then
            self.STCharacterMovement.bPositiveBlowUp = true
        end

        if Client then
            GameplayData.AddCharacter(self.Object)

            -- Load features after a short delay
            self:AddGameTimer(1.0, false, function()
                _G.LoadAllFeatures()
            end)
            _G._FeaturesLoaded = nil
        end
    end,

    ReceiveEndPlay = function(self, EndPlayReason)
        CharacterBase.ReceiveEndPlay(self, EndPlayReason)
        if Client and GameplayData.RemoveCharacter then
            GameplayData.RemoveCharacter(self.Object)
        end
    end,

    OnPlayerEnterCarryBoxState = function(self)
        self.Super:OnPlayerEnterCarryBoxState()
        if self.CarryDeadBoxFeature then
            self.CarryDeadBoxFeature:OnPlayerEnterCarryBoxState()
        end
    end,

    OnPlayerLeaveCarryBoxState = function(self, bForce)
        self.Super:OnPlayerLeaveCarryBoxState(bForce)
        if self.CarryDeadBoxFeature then
            self.CarryDeadBoxFeature:OnPlayerLeaveCarryBoxState(bForce)
        end
    end,

    ServerRPC_CarryDeadBox = function(self, DeadBox)
        if slua.isValid(DeadBox) and Game.IsClassOf(DeadBox, import("/Script/ShadowTrackerExtra.PlayerTombBox")) then
            if self.CarryDeadBoxFeature then
                self.CarryDeadBoxFeature:CarryDeadBox(DeadBox)
            end
        end
    end,

    ServerRPC_NearDeathGiveupRescue = function(self)
        local nearDeathComp = self.NearDeatchComponent
        if self:IsNearDeath() and slua.isValid(nearDeathComp) and self.bCanNearDeathGiveup then
            nearDeathComp:TriggerGotoDieExplictly(self.Object)
        end
    end,

    SwitchWeaponCheck = function(self, WeaponID, IsClearUp)
        return self.Super:SwitchWeaponCheck(WeaponID, IsClearUp)
    end,

    HandleOnAttachedToVehicle = function(self, Vehicle)
        -- empty
    end,

    HandleOnDetachedFromVehicle = function(self, Vehicle)
        -- empty
    end,

    ClearAttachToVehicleTimer = function(self)
        -- empty
    end
})

-- Declare features for this class
combine_class.DeclareFeature(BRPlayerCharacterBase, {
    SkyTransition = "GameLua.Mod.BaseMod.Gameplay.Feature.SkyControl.PlayerCharacterSkyTransitionFeature",
    CarryDeadBoxFeature = "GameLua.Mod.Library.GamePlay.Feature.CarryDeadBoxFeature",
    SpecialSuitFeature = "GameLua.Mod.Library.GamePlay.Feature.SpecialSuitFeature",
    TeleportPawnFeature = "GameLua.Mod.Library.GamePlay.Feature.TeleportPawnFeature",
    LifterControl = "GameLua.Mod.BaseMod.Gameplay.Feature.Player.CharacterLifterControlFeature",
    FinalKillEffect = "GameLua.Mod.BaseMod.Gameplay.Feature.Player.PlayerCharacterFinalKillEffectFeature",
    CampFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.Camp.PlayerCharacterCampFeature",
    BuildSkateFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.PlayerCharacterBuildVehicleFeature",
    CommonBornlandTransformFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.HeroPropFeature.CommonBornlandTransformFeature",
    ParachuteFormation = "GameLua.Mod.BaseMod.GamePlay.Feature.ParachuteFormationFeature"
}, "BRPlayerCharacterBase")

return BRPlayerCharacterBase
