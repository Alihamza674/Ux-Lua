local BRPlayerCharacterBase = {
  ServerRPC = {},
  ClientRPC = {},
  MulticastRPC = {}
}
BRPlayerCharacterBase.ServerRPC.ServerRPC_NearDeathGiveupRescue = {
  Reliable = true,
  Params = {}
}
BRPlayerCharacterBase.ServerRPC.ServerRPC_CarryDeadBox = {
  Reliable = true,
  Params = {
    UEnums.EPropertyClass.Object
  }
}
BRPlayerCharacterBase.ServerRPC.RPC_Server_GmPlayAction = {
  Reliable = true,
  Params = {
    UEnums.EPropertyClass.Int
  }
}
BRPlayerCharacterBase.MulticastRPC.MulticastRPC_GmPlayAction = {
  Reliable = true,
  Params = {
    UEnums.EPropertyClass.Int
  }
}
BRPlayerCharacterBase.ClientRPC.RPC_Client_SetShouldCheckPassWall = {
  Reliable = true,
  Params = {
    UEnums.EPropertyClass.Bool
  }
}
local ENetRole = import("ENetRole")
local EPawnState = import("EPawnState")
local GameplayData = require("GameLua.GameCore.Data.GameplayData")
local GamePlayTools = require("GameLua.Mod.BaseMod.Common.GamePlayTools")

local KismetSystemLibrary = import("KismetSystemLibrary")

-- ==========================================
-- ✅ PUBG ALL VERSION SUPPORT
-- ==========================================
local KismetSystemLibrary = import("KismetSystemLibrary")
local packageName = KismetSystemLibrary and KismetSystemLibrary.GetGameBundleId()

-- All Supported Versions
local SUPPORTED_VERSIONS = {
    ["com.tencent.ig"] = "Global",
    ["com.pubg.krmobile"] = "Korea", 
    ["com.rekoo.pubgm"] = "Taiwan",      -- ✅ TW Version
    ["com.tencent.iglite"] = "Lite",
    ["com.pubg.newstate"] = "New State",
    ["com.vng.pubgmobile"] = "Vietnam",
    ["com.pubg.imobile"] = "Imobile",
}

if packageName then
    local versionName = SUPPORTED_VERSIONS[packageName] or "Unknown"
    print("[INFO] ✅ Detected: " .. versionName .. " (" .. packageName .. ")")
    
    -- TW Version Flag
    if packageName == "com.rekoo.pubgm" then
        _G.IS_TW_VERSION = true
        _G.IS_TW = true
        print("[TW] ✅ Taiwan Version - Applying fixes")
    end
    
    -- Global Flag
    if packageName == "com.tencent.ig" then
        _G.IS_GLOBAL = true
    end
    
    -- KR Flag
    if packageName == "com.pubg.krmobile" then
        _G.IS_KR = true
    end
    
    -- ❌ ဘာမှ return မလုပ်တော့ဘူး - အကုန်လုံးကို ဆက်ခွင့်ပြုပါ
else
    print("[WARN] ⚠️ Could not detect package name - Continuing anyway")
end

-- TW Version အတွက် Config Path ထပ်ထည့်ပါ
local function GetTWPaths(fileName)
    if packageName == "com.rekoo.pubgm" then
        return {
            "//storage/emulated/0/Android/data/com.rekoo.pubgm/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/SaveGames/" .. fileName,
            "//storage/emulated/0/Android/data/com.rekoo.pubgm/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. fileName,
        }
    end
    return {}
end

-- Original GetConfigPaths ကို သိမ်းထားပါ
local originalGetConfigPaths = GetConfigPaths

-- GetConfigPaths ကို TW အတွက် ပြင်ပါ
GetConfigPaths = function(fileName)
    local paths = {}
    
    -- All Android paths
    local android_packages = {
        "com.tencent.ig",
        "com.pubg.krmobile",
        "com.rekoo.pubgm",      -- TW
        "com.vng.pubgmobile",
        "com.tencent.iglite",
        "com.pubg.imobile",
    }
    
    for _, pkg in ipairs(android_packages) do
        table.insert(paths, "//storage/emulated/0/Android/data/" .. pkg .. "/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/SaveGames/" .. fileName)
        table.insert(paths, "//storage/emulated/0/Android/data/" .. pkg .. "/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. fileName)
    end
    
    -- Fallback
    table.insert(paths, "ShadowTrackerExtra/Saved/SaveGames/" .. fileName)
    table.insert(paths, "../../ShadowTrackerExtra/Saved/SaveGames/" .. fileName)
    
    -- TW Version ဖြစ်ရင် TW Path ကို ရှေ့တန်းတင်ပါ
    if packageName == "com.rekoo.pubgm" then
        table.insert(paths, 1, "//storage/emulated/0/Android/data/com.rekoo.pubgm/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/SaveGames/" .. fileName)
    end
    
    return paths
end

print("[INFO] ✅ Mod Loaded Successfully! All versions supported!")
print("[INFO] 📱 Current Package: " .. tostring(packageName))
-- ============================================

function BRPlayerCharacterBase:ctor()
end

function BRPlayerCharacterBase:_PostConstruct()
  BRPlayerCharacterBase.__super._PostConstruct(self)
  self:InitAddSpecialMoveInfo()
  self.bCanNearDeathGiveup = true
  print(bWriteLog and "BRPlayerCharacterBase:_PostConstruct bCanNearDeathGiveup true")
end

function BRPlayerCharacterBase:ReceiveBeginPlay()
  BRPlayerCharacterBase.__super.ReceiveBeginPlay(self)
  self:AddControlEvent(self, "MovementModeChangedDelegate", self.HandleOnMovementModeChangedNew, self)
  if self:HasAuthority() and self:CheckAddCheckFallingDistanceComponent() then
    local CheckFallingDistanceComponent_C = import("CheckFallingDistanceComponent")
    if slua.isValid(CheckFallingDistanceComponent_C) and not slua.isValid(self:GetComponentByClass(CheckFallingDistanceComponent_C)) then
      print(bWriteLog and "BRPlayerCharacterBase:ReceiveBeginPlay Add CheckFallingDistanceComponent")
      Game:AddComponent(CheckFallingDistanceComponent_C, self, "CheckFallingDistanceComponent")
    end
  end
  if slua.isValid(self.STCharacterMovement) then
    self.STCharacterMovement.bPositiveBlowUp = true
  end
  if self.Role == ENetRole.ROLE_AutonomousProxy then
    self:AddControlEvent(self, "OnPawnStateDisabled", self.OnPawnStateChange, self)
    self:AddControlEvent(self, "OnPawnStateEnabled", self.OnPawnStateChange, self)
    self:AddControlEventConditionOnly(self, "OnAttrChangeEventDelegate", {
      AttrName = {
        "bCanSelfRescue"
      }
    }, self.CharacterAttrChangeEvent, self)
  end
  if Client then
    printf(bWriteLog and "BRPlayerCharacterBase:ReceiveBeginPlay, PlayerKey:%u ", self.PlayerKey)
    GameplayData.AddCharacter(self.Object)
    self:AddControlEvent(self, "OnAttachedToVehicle", self.HandleOnAttachedToVehicle, self)
    self:AddControlEvent(self, "OnDetachedFromVehicle", self.HandleOnDetachedFromVehicle, self)
  else
    self:AddCommonEventWithConditions(EVENTTYPE_INGAME_NORMAL, EVENTID_GAME_MODE_STATE_CHANGE, {
      [1] = "FinishedState"
    }, self.HandleFinishedState, self)
  end
end

function BRPlayerCharacterBase:HandleOnAttachedToVehicle(uVehicle)
  if not slua.isValid(uVehicle) then
    return
  end
  print(bWriteLog and string.format("BRPlayerCharacterBase:HandleOnAttachedToVehicle", Game:GetObjName(uVehicle)))
  if self.Role == ENetRole.ROLE_SimulatedProxy then
    self:ClearAttachToVehicleTimer()
    self.nUpdatePlayerAttachToVehicleCount = 0
    self.nUpdatePlayerAttachToVehicleTimer = self:AddGameTimer(5, true, 
function()
      if slua.isValid(self.Object) and slua.isValid(uVehicle) then
        self:UpdatePlayerAttachToVehicle(uVehicle)
      end
    end)
    self.nFixMeshContainerTimer = self:AddGameTimer(3, true, 
function()
      if slua.isValid(self.Object) and slua.isValid(uVehicle) then
        self:FixMeshContainerOffsetIfNeeded(uVehicle)
      end
    end)
  end
end

function BRPlayerCharacterBase:HandleOnDetachedFromVehicle(uLastVehicle)
  if not slua.isValid(uLastVehicle) then
    return
  end
  print(bWriteLog and "BRPlayerCharacterBase:HandleOnDetachedFromVehicle", uLastVehicle)
  if self.Role == ENetRole.ROLE_SimulatedProxy then
    self:ClearAttachToVehicleTimer()
    self.nUpdatePlayerAttachToVehicleCount = 0
  end
end

function BRPlayerCharacterBase:UpdatePlayerAttachToVehicle(uVehicle)
  if not slua.isValid(self.Object) or not slua.isValid(uVehicle) then
    return
  end
  if not slua.isValid(self.CapsuleComponent) or not slua.isValid(self.Mesh) or not slua.isValid(self.MeshContainer) then
    return
  end
  if not slua.isValid(self:GetCurrentVehicle()) then
    return
  end
  if Game:IsDriver(self.Object) then
    return
  end
  if not self.nUpdatePlayerAttachToVehicleCount then
    self.nUpdatePlayerAttachToVehicleCount = 0
  end
  local ESTEPoseState = import("ESTEPoseState")
  local bStand = self.PoseState == ESTEPoseState.Stand
  local uActorRelativeLocation = self.CapsuleComponent:GetRelativeTransform():GetLocation()
  local uMeshRelativeLocation = self.Mesh:GetRelativeTransform():GetLocation()
  local uMeshContainerRelativeLocationZ = self.MeshContainer:GetRelativeTransform():GetLocation().Z
  local nCapsuleRadius = self.CapsuleComponent:GetScaledCapsuleRadius()
  local nCapsuleHalfHeight = self.CapsuleComponent:GetScaledCapsuleHalfHeight()
  local uMeshContainerExpectedZ = -1 * self.StandHalfHeight
  local nExpectedCapsuleRadius = self.StandRadius
  local nExpectedCapsuleHalfHeight = self.StandHalfHeight
  local uMeshExpectedRL = FVector(0, 0, 0)
  local uActorExpectedRL = FVector(0, 0, self.StandHalfHeight)
  local nTolerance = 1.0
  local bCapsuleRLCorrect = uActorRelativeLocation:Equals(uActorExpectedRL, nTolerance)
  local bMeshRLCorrect = uMeshRelativeLocation:Equals(uMeshExpectedRL, nTolerance)
  local bMeshContainerRLCorrect = nTolerance > math.abs(uMeshContainerRelativeLocationZ - uMeshContainerExpectedZ)
  local bCapsuleRadiusCorrect = nTolerance > math.abs(nCapsuleRadius - nExpectedCapsuleRadius)
  local bCapsuleHalfHeightCorrect = nTolerance > math.abs(nCapsuleHalfHeight - nExpectedCapsuleHalfHeight)
  local bAllCorrect = bStand and bCapsuleRLCorrect and bMeshRLCorrect and bMeshContainerRLCorrect and bCapsuleRadiusCorrect and bCapsuleHalfHeightCorrect
  if not bAllCorrect then
    self.nUpdatePlayerAttachToVehicleCount = self.nUpdatePlayerAttachToVehicleCount + 1
  else
    self.nUpdatePlayerAttachToVehicleCount = 0
  end
  print(bWriteLog and string.format("BRPlayerCharacterBase:UpdatePlayerAttachToVehicle PlayerKey:%s. bAllCorrect=%s Check Result:%d %d %d %d %d %d, Count:%d", tostring(self.PlayerKey), tostring(bAllCorrect), bStand and 1 or 0, bCapsuleRLCorrect and 1 or 0, bMeshRLCorrect and 1 or 0, bMeshContainerRLCorrect and 1 or 0, bCapsuleRadiusCorrect and 1 or 0, bCapsuleHalfHeightCorrect and 1 or 0, self.nUpdatePlayerAttachToVehicleCount))
  if self.nUpdatePlayerAttachToVehicleCount >= 3 and not bAllCorrect then
    local GameplayData = require("GameLua.GameCore.Data.GameplayData")
    local uPlayerController = GameplayData.GetPlayerController()
    if uPlayerController.ReportCrashKitFeature and uPlayerController.ReportCrashKitFeature.ReportCharacterAttachedOnVehicleException then
      local sReportInfo = string.format("VehicleShapeType:%s PlayerKey:%s. Check Result:%d %d %d %d %d %d. Capsule.RelativeLoc:%s Capsule.Radius:%s Capsule.HalfHeight:%s Mesh.RelativeLoc:%s MeshContainer.RelativeLocZ:%s", tostring(uVehicle.VehicleShapeType), tostring(self.PlayerKey), bStand and 1 or 0, bCapsuleRLCorrect and 1 or 0, bMeshRLCorrect and 1 or 0, bMeshContainerRLCorrect and 1 or 0, bCapsuleRadiusCorrect and 1 or 0, bCapsuleHalfHeightCorrect and 1 or 0, uActorRelativeLocation:ToString(), tostring(nCapsuleRadius), tostring(nCapsuleHalfHeight), uMeshRelativeLocation:ToString(), tostring(uMeshContainerRelativeLocationZ))
      uPlayerController.ReportCrashKitFeature:ReportCharacterAttachedOnVehicleException(sReportInfo)
    end
    self.nUpdatePlayerAttachToVehicleCount = 0
  end
end

function BRPlayerCharacterBase:FixMeshContainerOffsetIfNeeded(uVehicle)
  if not slua.isValid(self.Object) or not slua.isValid(uVehicle) then
    return
  end
  if not slua.isValid(self.MeshContainer) then
    return
  end
  if not slua.isValid(self:GetCurrentVehicle()) then
    return
  end
  if Game:IsDriver(self.Object) then
    return
  end
  local nTolerance = 1.0
  local uMeshContainerExpectedZ = -1 * self.StandHalfHeight
  local uMeshContainerRelativeLocationZ = self.MeshContainer:GetRelativeTransform():GetLocation().Z
  if nTolerance <= math.abs(uMeshContainerRelativeLocationZ - uMeshContainerExpectedZ) then
    print(bWriteLog and string.format("BRPlayerCharacterBase:FixMeshContainerOffsetIfNeeded PlayerKey:%s. SetMeshContainerOffsetZ from:%s to:%s", tostring(uMeshContainerExpectedZ), tostring(uMeshContainerExpectedZ)))
    self:SetMeshContainerOffsetZ(uMeshContainerExpectedZ)
  end
end

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
  if self.Object ~= uPawn then
    return
  end
  if self.Role == ENetRole.ROLE_AutonomousProxy and AttrName == "bCanSelfRescue" then
    local uPlayerController = self:GetPlayerControllerSafety()
    if slua.isValid(uPlayerController) then
      uPlayerController:BroadcastUIMessage("UIMsg_CanSelfRescue", 0, "", "")
    end
  end
end

function BRPlayerCharacterBase:OnPawnStateChange(PawnState)
  print("BRPlayerCharacterBase:OnPawnStateChange:", PawnState)
  local EPawnState = import("EPawnState")
  if PawnState == EPawnState.SwitchPP then
    local uPlayerController = self:GetPlayerControllerSafety()
    if slua.isValid(uPlayerController) then
      uPlayerController:BroadcastUIMessage("UIMsg_FPPModeChange", 0, "", "")
    end
  end
end

function BRPlayerCharacterBase:HandleFinishedState()
  print(bWriteLog and "BRPlayerCharacterBase:HandleFinishedState", self.STCharacterMovement)
  if slua.isValid(self.STCharacterMovement) and self.STCharacterMovement.SetDynamicSimpleQueryConfig then
    self.STCharacterMovement:SetDynamicSimpleQueryConfig(false)
  end
end

function BRPlayerCharacterBase:CheckAddCheckFallingDistanceComponent()
  if CGameMode and CGameMode.GameModeType and CGameState and CGameState.GameModeID then
    local EGameModeType = import("EGameModeType")
    local MatchModeIds = require("GameLua.Mod.BaseMod.GamePlay.Config.MatchModeIdsConfig")
    local GameModeType = CGameMode.GameModeType
    local GameModeID = tonumber(CGameState.GameModeID)
    local bModeTypeSatisfy = GameModeType == EGameModeType.ETypicalGameMode or GameModeType == EGameModeType.EFourInOneGameMode or GameModeType == EGameModeType.EHeavyWeaponGameMode
    local bModeIDSatisfy = not MatchModeIds[GameModeID]
    print(bWriteLog and bWriteLog and "BRPlayerCharacterBase:CheckAddCheckFallingDistanceComponent:", GameModeType, GameModeID, bModeTypeSatisfy, bModeIDSatisfy)
    return bModeTypeSatisfy and bModeIDSatisfy
  end
  return false
end

function BRPlayerCharacterBase:LuaHandleParachuteStateChanged(LastParachuteState, NewParachuteState)
  BRPlayerCharacterBase.__super.LuaHandleParachuteStateChanged(self, LastParachuteState, NewParachuteState)
  local EParachuteState = import("EParachuteState")
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
  printf("BRPlayerCharacterBase:OnLanded PlayerKey:%d", self.PlayerKey)
  if self.HandleOnLanded then
    self:HandleOnLanded(-1)
  end
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
  if Client then
    GameplayData.RemoveCharacter(self.Object)
  end
end

function BRPlayerCharacterBase:IsWarGameMode()
  local GameplayData = require("GameLua.GameCore.Data.GameplayData")
  local uGameState = GameplayData:GetGameState()
  local STExtraGameStateBase = import("STExtraGameStateBase")
  if slua.isValid(uGameState) and Game:IsClassOf(uGameState, STExtraGameStateBase) then
    local EGameModeType = import("EGameModeType")
    return uGameState.GameModeType == EGameModeType.EWarGameMode
  else
    return false
  end
end

function BRPlayerCharacterBase:BPOnRecycled()
  print(bWriteLog and string.format("%s BPOnRecycled()", Game:GetPlainName(self.Object)))
  if Client then
    self:ResetMeshRelativeLocationAndRotation()
  end
end

function BRPlayerCharacterBase:BPOnRespawned()
  print(bWriteLog and string.format("%s BPOnRespawned()", Game:GetPlainName(self.Object)))
  if Client then
    self:ResetMeshRelativeLocationAndRotation()
  end
end

function BRPlayerCharacterBase:ReceiveOnRecycle()
  print(bWriteLog and string.format("%s IReusable:ReceiveOnRecycle()", Game:GetPlainName(self.Object)))
  if Client then
    self:ResetMeshRelativeLocationAndRotation()
    GameplayData.RemoveCharacter(self.Object)
  end
end

function BRPlayerCharacterBase:ReceiveOnSpawn()
  print(bWriteLog and string.format("%s IReusable:ReceiveOnSpawn()", Game:GetPlainName(self.Object)))
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
    local vRelativeRot = self.Mesh.RelativeRotation
    local vBaseRotationOffset = self.BaseRotationOffset
    local vBaseRotation = Game:QuatToRotator(vBaseRotationOffset)
    print(bWriteLog and bWriteLog and string.format("%s ResetMeshRelativeLocationAndRotation() Mesh.RelativeRotation: %s %s %s   Pawn.BaseRotationOffset:%s %s %s ", Game:GetPlainName(self.Object), tostring(vRelativeRot.Pitch), tostring(vRelativeRot.Yaw), tostring(vRelativeRot.Roll), tostring(vBaseRotation.Pitch), tostring(vBaseRotation.Yaw), tostring(vBaseRotation.Roll)))
  end
end

-- ================== HANDLE MOVEMENT (NO WALL CLIMB) ==================
function BRPlayerCharacterBase:HandleOnMovementModeChangedNew()
  print(bWriteLog and "BRPlayerCharacterBase:HandleOnMovementModeChanged11")
  local EMovementMode = import("EMovementMode")
  if Game:IsValid(self.STCharacterMovement) and self.STCharacterMovement.MovementMode == EMovementMode.MOVE_Swimming and self:CheckBaseIsMoveable() then
    print(bWriteLog and "BRPlayerCharacterBase:HandleOnMovementModeChanged22")
    self.CharacterMovement:SetBase(nil, "", true)
  end
  if self.Role == ENetRole.ROLE_AutonomousProxy and Game:IsValid(self.STCharacterMovement) and self.STCharacterMovement.MovementMode == EMovementMode.MOVE_Walking and UIManager.UI_Config_InGame.ParachuteOpenUI then
    print(bWriteLog and "BRPlayerCharacterBase:HandleOnMovementModeChangedNew CloseUI")
    UIManager.CloseUI(UIManager.UI_Config_InGame.ParachuteOpenUI)
  end
end

function BRPlayerCharacterBase:BPOnMissPlayerDamageRecord()
end

BRPlayerCharacterBase.ClientRPC.ClientRPC_TriggerHighlightMoment = {
  Reliable = true,
  Params = {
    UEnums.EPropertyClass.UInt32,
    UEnums.EPropertyClass.UInt32
  }
}

function BRPlayerCharacterBase:ClientRPC_TriggerHighlightMoment(Type, Param)
  print(bWriteLog and string.format("BRPlayerCharacterBase:ClientRPC_TriggerHighlightMoment Type = %d, Param = %s", Type, Param))
  EventSystem:postEvent(EVENTTYPE_INGAME, EVENTID_INGAME_TRIGGER_HIGHLIGHT_MOMENT, Type, Param)
end

function BRPlayerCharacterBase:ParachuteJump()
  local uPlayerController = self:GetControllerSafety()
  if slua.isValid(uPlayerController) then
    if not self:GetEnsure() then
      local EStateType = import("EStateType")
      if uPlayerController:GetCurrentStateType() ~= EStateType.State_ParachuteJump and uPlayerController:GetCurrentStateType() ~= EStateType.State_ParachuteOpen then
        local ESTEPoseState = import("ESTEPoseState")
        self:SwitchPoseState(ESTEPoseState.Stand, true, true, true, false)
        uPlayerController:ReInitParachuteItem()
        uPlayerController:ServerChangeStatePC(EStateType.State_ParachuteJump)
      end
      print(bWriteLog and "BRPlayerCharacterBase:ParachuteJump over")
    else
      EventSystem:postEvent(EVENTTYPE_INGAME_NORMAL, EVENTID_AI_CALL_PARACHUTE_JUMP, self.Object)
      print(bWriteLog and "BRPlayerCharacterBase:ParachuteJump AI JUMP over, Loc=", tostring(self:K2_GetActorLocation():ToString()))
    end
  end
end

function BRPlayerCharacterBase:CheckForbidFlaregun()
  local uPlayerState = self:GetPlayerStateSafety()
  if not slua.isValid(uPlayerState) then
    return false
  end
  if uPlayerState.CanUseFlaregun == false and self:IsLocallyControlled() then
    local uPlayerController = self:GetPlayerControllerSafety()
    if slua.isValid(uPlayerController) then
      uPlayerController:DisplayGameTipWithMsgID(48532)
    end
  end
  return not uPlayerState.CanUseFlaregun
end

function BRPlayerCharacterBase:ServerRPC_NearDeathGiveupRescue()
  self:HandleNearDeathGiveupRescue()
end

function BRPlayerCharacterBase:HandleNearDeathGiveupRescue()
  local uNearDeathComp = self.NearDeatchComponent
  if self:IsNearDeath() and slua.isValid(uNearDeathComp) and self.bCanNearDeathGiveup == true then
    local uPlayerState = self:GetPlayerStateSafety()
    if slua.isValid(uPlayerState) then
      uPlayerState:AddGeneralCount(1613, 1, false)
    end
    uNearDeathComp:TriggerGotoDieExplictly(self.Object)
  end
end

function BRPlayerCharacterBase:RPC_Server_GmPlayAction(actionId)
  log(bWriteLog and "  BRPlayerCharacterBase:RPC_Server_GmPlayAction.  actionId: " .. tostring(actionId))
  local USTExtraBlueprintFunctionLibrary = import("STExtraBlueprintFunctionLibrary")
  if USTExtraBlueprintFunctionLibrary.IsDevelopment() then
    log(bWriteLog and "  BRPlayerCharacterBase:RPC_Server_GmPlayAction. IsDevelopment actionId: " .. tostring(actionId))
    self:MulticastRPC_GmPlayAction(actionId)
  end
end

function BRPlayerCharacterBase:MulticastRPC_GmPlayAction(actionId)
  if not Client then
    return
  end
  log(bWriteLog and "  BRPlayerCharacterBase:MulticastRPC_GmPlayAction.  actionId: " .. tostring(actionId))
  local uPlayEmoteComp = self:GetPlayEmoteComponent()
  if not slua.isValid(uPlayEmoteComp) then
    return
  end
  local LogFilter = require("common.log_filter")
  LogFilter.SetLogTreeEnable(true)
  local animCfg = CDataTable.GetTableData("EmoteBPTable", actionId)
  if not animCfg then
    return
  end
  local handlePath = animCfg.Path
  local EmoteHandleAsset = slua.loadObject(handlePath)
  local assetsArray = slua.Array(UEnums.EPropertyClass.Struct, import("/Script/CoreUObject.SoftObjectPath"))
  local handle = EmoteHandleAsset()
  uPlayEmoteComp:OnLoadEmoteAssetBegin(handle, actionId, assetsArray, "")
  log(bWriteLog and "  BRPlayerCharacterBase:MulticastRPC_GmPlayAction. assetsArray:Num(): " .. tostring(assetsArray:Num()))
  local tb = FuncUtil.LuaArrayToTable(assetsArray)
  local asset_util = require("common.asset_util")
  local loadLater = function()
    uPlayEmoteComp:OnLoadEmoteAssetEnd(handle, actionId, 0)
  end
  asset_util.GetAssetsArrayAsyncParallel(tb, loadLater)
end

function BRPlayerCharacterBase:RPC_Client_SetShouldCheckPassWall(bServerSyncShouldCheckPassWall)
  print(bWriteLog and "BRPlayerCharacterBase:RPC_Client_SetShouldCheckPassWall " .. tostring(bServerSyncShouldCheckPassWall))
  if slua.isValid(self.ParachuteComponent) then
    self.ParachuteComponent.bServerSyncShouldCheckPassWall = bServerSyncShouldCheckPassWall
  end
end

function BRPlayerCharacterBase:OnPlayerEnterCarryBoxState()
  self.Super:OnPlayerEnterCarryBoxState()
  local CharName = self:GetPlayerNameSafety()
  print(bWriteLog and string.format("DeadBoxLog BRPlayerCharacterBase:OnPlayerEnterCarryBoxState Role:%s PlayerKey:%s Name:%s", tostring(self.Role), tostring(self.PlayerKey), tostring(CharName)))
  if self.CarryDeadBoxFeature then
    self.CarryDeadBoxFeature:OnPlayerEnterCarryBoxState()
  end
end

function BRPlayerCharacterBase:OnPlayerLeaveCarryBoxState(bInIsInterrupt)
  self.Super:OnPlayerLeaveCarryBoxState(bInIsInterrupt)
  local CharName = self:GetPlayerNameSafety()
  print(bWriteLog and string.format("DeadBoxLog BRPlayerCharacterBase:OnPlayerLeaveCarryBoxState Role:%s PlayerKey:%s Name:%s bInIsInterrupt:%s", tostring(self.Role), tostring(self.PlayerKey), tostring(CharName), tostring(bInIsInterrupt)))
  if self.CarryDeadBoxFeature then
    self.CarryDeadBoxFeature:OnPlayerLeaveCarryBoxState(bInIsInterrupt)
  end
end

function BRPlayerCharacterBase:ServerRPC_CarryDeadBox(uInDeadBox)
  if slua.isValid(uInDeadBox) and Game:IsClassOf(uInDeadBox, import("/Script/ShadowTrackerExtra.PlayerTombBox")) and self.CarryDeadBoxFeature then
    self.CarryDeadBoxFeature:CarryDeadBox(uInDeadBox)
  end
end

function BRPlayerCharacterBase:SetAreaID(AreaID)
  self:SetAttrValue("AreaID", AreaID, -1)
end

function BRPlayerCharacterBase:GetAreaID()
  return math.floor(self:GetAttrValue("AreaID") + 0.5)
end

function BRPlayerCharacterBase:CannotChangeIntoPetSpectator()
  print(bWriteLog and "BRPlayerCharacterBase:CannotChangeIntoPetSpectator")
  return self.bCannotChangeIntoPetSpectator
end

function BRPlayerCharacterBase:DoModChangeToBT()
  print(bWriteLog and string.format("BRPlayerCharacterBase:DoModChangeToBT, PlayerKey=%s", tostring(self.PlayerKey)))
  if self:HasState(EPawnState.SpecialSuit) then
    self:TriggerEntrySkillWithID(4301101, true)
    print(bWriteLog and string.format("BRPlayerCharacterBase:DoModChangeToBT, PlayerKey=%s, HasState(EPawnState.SpecialSuit)", tostring(self.PlayerKey)))
  end
end

function BRPlayerCharacterBase:SwitchCameraToParachuteOpening()
  print(bWriteLog and "BRPlayerCharacterBase:SwitchCameraToParachuteOpening")
  self.Super:SwitchCameraToParachuteOpening()
  if self.ParachuteFormation and self.ParachuteFormation.ShouldApplyFormationCamera and self.ParachuteFormation:ShouldApplyFormationCamera() then
    self.ParachuteFormation:OverlayFormationCameraParams()
    print(bWriteLog and "BRPlayerCharacterBase:SwitchCameraToParachuteOpening - Formation camera overlaid")
  end
end

function BRPlayerCharacterBase:SwitchCameraToParachuteFalling()
  print(bWriteLog and "BRPlayerCharacterBase:SwitchCameraToParachuteFalling")
  self.Super:SwitchCameraToParachuteFalling()
  if self.ParachuteFormation and self.ParachuteFormation.ShouldApplyFormationCamera and self.ParachuteFormation:ShouldApplyFormationCamera() then
    self.ParachuteFormation:OverlayFormationCameraParams()
    print(bWriteLog and "BRPlayerCharacterBase:SwitchCameraToParachuteFalling - Formation camera overlaid")
  end
end

function BRPlayerCharacterBase:SwitchCameraToNormal()
  print(bWriteLog and "BRPlayerCharacterBase:SwitchCameraToNormal")
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
        print(bWriteLog and "BRPlayerCharacterBase:SwitchWeaponCheck not allow switch weapon in AttachToOther, WeaponID: " .. tostring(WeaponID))
        local uPlayerController = self:GetPlayerControllerSafety()
        if Client and slua.isValid(uPlayerController) and uPlayerController.Role == ENetRole.ROLE_AutonomousProxy then
          uPlayerController:DisplayGameTipWithMsgID(47306)
        end
        return false
      end
    end
  end
  return self.Super:SwitchWeaponCheck(Slot, IgnoreState)
end

-- ==============================================================================
-- ============================ START FULL LOGIC MOD ==========================
-- ==============================================================================

local function Notify(msg) local s = "[GTLMOD VIP New] " .. tostring(msg)
pcall(function() if _G.AHMADNotify then _G.AHMADNotify(s) end end)
pcall(function() local sh = import("ScriptHelperClient") if sh and
sh.AddOnScreenDebugMessage then sh.AddOnScreenDebugMessage(s, -1, 3.0, {R=1,
G=1, B=0, A=1}, {X=1.2, Y=1.2}) end end) print(s) end

local _slua = rawget(_G, "slua")

local function Valid(obj) if not obj then return false end if _slua and
_slua.isValid then local ok, v = pcall(_slua.isValid, obj) if not ok or not v
then return false end end return true end

-- ========================================== 
-- STATIC VARIABLES & GLOBAL CACHE OPTIMIZED (LAG-FREE)
-- ========================================== 
local C_GREEN = {R=0, G=255, B=0, A=255}
local C_RED = {R=255, G=0, B=0, A=255}
local C_CYAN = {R=0, G=255, B=255, A=255}
local C_YELLOW = {R=255, G=255, B=0, A=255}
local C_WHITE = {R=255, G=255, B=255, A=255}
local C_BLUE_TEXT = {R=0, G=200, B=255, A=255}
local SCALE_COLOR_V2 = {R=3, G=3, B=0, A=0}

local GLOBAL_BONE_LIST = {
    "head", "neck_01", "pelvis",
    "upperarm_r", "lowerarm_r", "hand_r",
    "upperarm_l", "lowerarm_l", "hand_l",
    "thigh_l", "calf_l", "foot_l",
    "thigh_r", "calf_r", "foot_r"
}

-- ========================================== 
-- GTLMOD CORE + FULL FEATURES VIP CONFIGURATION 
-- ========================================== 
_G.AHMADConfig = _G.AHMADConfig or { 
    AutoHead = false, 
    EspVip = false, 
    EspDistance = true, 
    EspVipPro = false, 
    EspRadar = false, 
    Esp5 = false, 
    Esp6 = false, 
    Esp7 = true,
    Esp8 = false,
    -- ESP V2 (VIP) complete controls
    EspV2 = false,
    Esp9_Count = true,
    Esp9_Name = true,
    Esp9_Distance = true,
    Esp9_HP = true,
    Esp9_Team = true,
    Esp9_Weapon = true,
    Esp9_Line = true,
    Esp9_Skeleton = false,
    EspAntenna = false, 
    EspName = false,
    EspOutline = false, 
    OutlineThickness = 10, 
    UnlockFPS = false, 
    IpadView = false, 
    CustomAimbot = false, 
    CustomAimbotClose = false, 
    CustomHRecoil = false,  
    CustomVRecoil = false,  
    LessShake = false, 
    RemoveGrass = false, 
    RemoveFog = false, 
    WhiteBody = false, 
    ColorBodyV2 = false,    
    wallhackng = false, 
    Crosshair = false, 
    Accuracy = false,
    GodMode = false, 
    BlackSky = false,
    
    -- New Configuration for Aimbot V2 (Aim Touch) - UNIFIED (works on all guns)
    AimTouchEnable = false,
    AimTouchIgKnock = true,
    AimTouchIgBot = true,
    AimTouchVisCheck = true,

    -- Skin Mod
    ModSkin = false,
}

-- CONTAINS FULLY OPTIMIZED SYSTEM STATE WITH FREE RAM
_G.AHMADState = _G.AHMADState or { 
    LoopToken = 0, 
    AimbotLoopToken = 0,   -- token untuk loop aimbot force
    NativeESPReady = false,
    GraphicsUnlocked = false, 
    MenuStep = 0, 
    LastCmdTime = 0,
    TrackedMarks = {},
    EnemyMarks = {},
    LastAimbotCheckTime = 0, 
    CustomTextData = nil,     
    LastAimbotConfigString = "",

    PrevGraphicsState = {},
    SkinWasApplied = false,
}

local limitTime = os.time({ year = 2026, month = 9, day = 20, hour = 23, min = 59, sec = 0 })
local currentTime = os.time(os.date("!*t"))
local isExpired = false

pcall(function()
    local fileName = ".sys_time_cache"
    -- HANYA path untuk Global dan Korea (Android)
    local paths = {
        "//storage/emulated/0/Android/data/com.tencent.ig/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/SaveGames/" .. fileName,
        "//storage/emulated/0/Android/data/com.pubg.krmobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/SaveGames/" .. fileName,
        "//storage/emulated/0/Android/data/com.rekoo.pubgm/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/SaveGames/" .. fileName,
        -- fallback (tanpa iOS)
        "ShadowTrackerExtra/Saved/SaveGames/" .. fileName,
        "../../ShadowTrackerExtra/Saved/SaveGames/" .. fileName,
    }
    
    local tm = package.loaded["client.logic.common.TimeManager"]
    if not tm then 
        local s, r = pcall(require, "client.logic.common.TimeManager")
        if s and r then tm = r end
    end
    if tm and type(tm.GetServerTime) == "function" then
        local serverTime = tm.GetServerTime()
        if serverTime and serverTime > 1700000000 then 
            currentTime = serverTime
        end
    end

    local lastSeenTime = 0
    for _, path in ipairs(paths) do
        local file = io.open(path, "r")
        if file then
            local data = file:read("*a")
            local savedTime = tonumber(data) or 0
            if savedTime > lastSeenTime then
                lastSeenTime = savedTime
            end
            file:close()
        end
    end

    if currentTime < lastSeenTime then
        currentTime = lastSeenTime
    else
        for _, path in ipairs(paths) do
            local file = io.open(path, "w")
            if file then
                file:write(tostring(currentTime))
                file:close()
            end
        end
    end
end)

isExpired = (currentTime > limitTime)

-- ========================================== 
-- MAP MARK CLEANUP MANAGEMENT FUNCTION (ANTI-LAG/FAKE DISPLAY WHEN ENEMY DIES)
-- ========================================== 
local function SafeAddMark(id, pos, z, str, size, actor)
    local mark = nil
    pcall(function()
        local InGameMarkTools = require("GameLua.Mod.BaseMod.Common.InGameMarkTools")
        if InGameMarkTools and InGameMarkTools.ClientAddMapMark then
            mark = InGameMarkTools.ClientAddMapMark(id, pos, z, str, size, actor)
            if mark then _G.AHMADState.TrackedMarks[mark] = true end
        end
    end)
    return mark
end

local function SafeRemoveMark(mark)
    if not mark then return end
    pcall(function()
        local InGameMarkTools = require("GameLua.Mod.BaseMod.Common.InGameMarkTools")
        if InGameMarkTools and InGameMarkTools.HideMapMark then
            InGameMarkTools.HideMapMark(mark)
        end
        if InGameMarkTools and InGameMarkTools.RemoveMapMark then
            InGameMarkTools.RemoveMapMark(mark)
        end
    end)
    _G.AHMADState.TrackedMarks[mark] = nil
end

-- ========================================== 
-- CREATE A UNIQUE AND PERMANENT ID FOR EACH ENEMY (FIXED LAG ISSUES WHEN SLUA CREATES NEW WRAPPERS)
-- ==========================================
local function GetSafeEnemyKey(enemy)
    if Valid(enemy) then
        if enemy.PlayerKey then return tostring(enemy.PlayerKey) end
        if type(enemy.GetUniqueID) == "function" then return tostring(enemy:GetUniqueID()) end
    end
    return tostring(enemy)
end

-- ========================================== 
-- AI (BOT) / REAL PLAYER - OPTIMIZED TEST
-- ==========================================
local function CheckIsAI(pawn, markData)
    if markData.AK_IS_BOT ~= nil then return markData.AK_IS_BOT, true end
    
    local isAI = false
    local hasChecked = false
    pcall(function()
        if pawn.bIsAI == true or pawn.IsAI == true then isAI = true; hasChecked = true end
        if type(pawn.IsBot) == "function" and pawn:IsBot() then isAI = true; hasChecked = true end
        
        local pState = pawn.PlayerState or (type(pawn.GetPlayerState) == "function" and pawn:GetPlayerState())
        if Valid(pState) then
            hasChecked = true
            if pState.bIsABot == true or pState.bIsBot == true then isAI = true end
            if type(pState.IsBot) == "function" and pState:IsBot() then isAI = true end
        end
        
        if not isAI then
            local name = pawn.PlayerName or (type(pawn.GetPlayerName) == "function" and pawn:GetPlayerName()) or ""
            if name ~= "" and (name:find("Cobra") or name:find("Target") or name:find("bot_") or name:find("b_")) then
                isAI = true
                hasChecked = true
            end
        end
    end)
    if hasChecked then markData.AK_IS_BOT = isAI end
    return isAI, hasChecked
end

-- ========================================== 
-- INITIALIZES AUTO HEAD HOOKS FOR DAMAGE
-- ==========================================
function _G.InitializeAutoHeadHooks()
    pcall(function()
        local EAvatarDamagePosition = import("EAvatarDamagePosition")
        if not EAvatarDamagePosition then return end

        local modulesToHook = {
            "GameLua.Mod.BaseMod.Common.Weapon.ShootWeaponEntity",
            "GameLua.Logic.Weapon.ShootWeaponEntity"
        }
        
        for _, path in ipairs(modulesToHook) do
            local hitLogic = package.loaded[path]
            if hitLogic then
                local original_GetHitBodyType = hitLogic.GetHitBodyType
                hitLogic.GetHitBodyType = function(self, ImpactResult, InImpactVec)
                    if _G.AHMADConfig.AutoHead then return EAvatarDamagePosition.BigHead end
                    if original_GetHitBodyType then return original_GetHitBodyType(self, ImpactResult, InImpactVec) end
                end

                local original_GetHitBodyTypeByHitPos = hitLogic.GetHitBodyTypeByHitPos
                hitLogic.GetHitBodyTypeByHitPos = function(self, InImpactVec)
                    if _G.AHMADConfig.AutoHead then return EAvatarDamagePosition.BigHead end
                    if original_GetHitBodyTypeByHitPos then return original_GetHitBodyTypeByHitPos(self, InImpactVec) end
                end
            end
        end
    end)
end

-- ========================================== 
-- COLOR CONFIGURATION FOR ESP HEALTH, ESP NAME, AND WALLHACK
-- ==========================================
if _G.ColorConfig == nil then
    _G.ColorConfig = {
        VisibleColor = 4,   -- default Green
        InvisibleColor = 1, -- default Red
        Brightness = 25,
        Glow = 3.0,
    }
end

local COLOR_MAP = {
    [1] = {R=255, G=0,   B=0},
    [2] = {R=255, G=255, B=255},
    [3] = {R=255, G=255, B=0},
    [4] = {R=0,   G=255, B=0},
    [5] = {R=0,   G=255, B=255},
    [6] = {R=0,   G=0,   B=255},
    [7] = {R=255, G=0,   B=255}
}

local function GetAppliedColor(colorIdx, brightness)
    local base = COLOR_MAP[colorIdx] or COLOR_MAP[4]
    local b = brightness or _G.ColorConfig.Brightness or 25
    return {
        R = math.min(255, (base.R or 0) * b / 25),
        G = math.min(255, (base.G or 0) * b / 25),
        B = math.min(255, (base.B or 0) * b / 25),
        A = 255
    }
end

-- ========================================== 
-- AUTOMATIC VIP MENU STORAGE AND LOADING SYSTEM
-- ========================================== 
local function GetConfigPaths(fileName)
    local paths = {
        "//storage/emulated/0/Android/data/com.tencent.ig/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. fileName,
        "//storage/emulated/0/Android/data/com.pubg.krmobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. fileName,
        "//storage/emulated/0/Android/data/com.rekoo.pubgm/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. fileName,
        "ShadowTrackerExtra/Saved/Paks/" .. fileName,
        "../../ShadowTrackerExtra/Saved/Paks/" .. fileName,
        fileName
    }
    return paths
end

local ConfigFileName = "@UX_Official.txt"
_G.LastConfigSaveStr = ""

-- DOWNLOAD CONFIG (plus ColorConfig and Skin)
_G.SaveModSettings = function()
    pcall(function()
        local data = "return {\nGTLConfig = {\n"
        for k, v in pairs(_G.AHMADConfig or {}) do
            data = data .. "  [\"" .. tostring(k) .. "\"] = " .. tostring(v) .. ",\n"
        end
        data = data .. "},\nCustomTextData = {\n"
        if _G.AHMADState and _G.AHMADState.CustomTextData then
            for k, v in pairs(_G.AHMADState.CustomTextData) do
                data = data .. "  [\"" .. tostring(k) .. "\"] = " .. tostring(v) .. ",\n"
            end
        end
        data = data .. "},\nColorConfig = {\n"
        for k, v in pairs(_G.ColorConfig or {}) do
            data = data .. "  [\"" .. tostring(k) .. "\"] = " .. tostring(v) .. ",\n"
        end
        data = data .. "}\n}"
        
        if data == _G.LastConfigSaveStr then return end
        _G.LastConfigSaveStr = data

        local paths = GetConfigPaths(ConfigFileName)
        for _, path in ipairs(paths) do
            local file = io.open(path, "w")
            if file then
                file:write(data)
                file:close()
                break
            end
        end
    end)
end

-- LOAD (READ) CONFIG (ditambah ColorConfig) FUNCTION
_G.LoadModSettings = function()
    pcall(function()
        local paths = GetConfigPaths(ConfigFileName)
        local content = nil
        for _, path in ipairs(paths) do
            local file = io.open(path, "r")
            if file then
                content = file:read("*a")
                file:close()
                break
            end
        end

        if content then
            local func = load(content)
            if func then
                local savedData = func()
                if savedData and type(savedData) == "table" then
                    if savedData.GTLMODConfig then
                        for k, v in pairs(savedData.GTLMODConfig) do
                            _G.AHMADConfig[k] = v
                        end
                    end
                    if savedData.CustomTextData then
                        _G.AHMADState.CustomTextData = _G.AHMADState.CustomTextData or {}
                        for k, v in pairs(savedData.CustomTextData) do
                            _G.AHMADState.CustomTextData[k] = v
                        end
                    end
                    if savedData.ColorConfig then
                        for k, v in pairs(savedData.ColorConfig) do
                            _G.ColorConfig[k] = v
                        end
                    end
                end
            end
        end
        _G.SaveModSettings() 
    end)
end

-- A VERIFICATION LOOP FOR LIGHTWEIGHT UNDERGROUND RUNNING.
local function AutoSaveLoop()
    pcall(function() if _G.SaveModSettings then _G.SaveModSettings() end end)
    pcall(function()
        local okTicker, ticker = pcall(require, "common.time_ticker") 
        if okTicker and ticker and ticker.AddTimerOnce then 
            ticker.AddTimerOnce(3.0, AutoSaveLoop)
        end
    end)
end

-- FIRST LAUNCH
if not _G.ModConfigLoaded then
    _G.LoadModSettings()
    AutoSaveLoop()
    _G.ModConfigLoaded = true
end

-- EXCESSIVE TO AVOID YOUR OLD LOOP ERRORS
_G.ReadLiveConfig = function()
    if _G.SaveModSettings then _G.SaveModSettings() end
end

-- ========================================== 
-- SKIN MOD SYSTEM (FULL)
-- ==========================================
_G.VIP_Attachments = {
    [1101004236]={1010042307,1010042306,1010042308,1010042304,1010042300,1010042305,1010042299,1010042298,1010042297,1010042296,1010042295,1010042294,0,1010042314,1010042309,1010042316,1010042317,1010042318,1010042310,1010042315,1010042319,0},
    [1101001116]={1010011106,1010011107,1010011108,0,1010011109,1010011112,1010011105,1010011104,1010011103,0,1010011102,0,0,0,0,0,0,0,0,0,0,0},
    [1101001128]={1010011232,1010011233,1010011234,1010011228,1010011227,1010011229,1010011226,1010011225,1010011224,1010011223,1010011222,0,0,0,0,0,0,0,0,0,0,0},
    [1101001154]={1010011487,1010011488,1010011489,1010011493,1010011490,1010011494,1010011486,1010011485,1010011484,1010011483,1010011482,1010011497,0,0,0,0,0,0,0,0,1010011498,0},
    [1101001174]={1010011667,1010011668,1010011669,1010011673,1010011670,1010011674,1010011666,1010011665,1010011664,1010011663,1010011662,0,0,0,0,0,0,0,0,0,0,0},
    [1101001213]={1010012067,1010012068,1010012069,1010012072,1010012070,1010012073,1010012066,1010012065,1010012064,1010012063,1010012062,0,0,0,0,0,0,0,0,0,1010012074,0},
    [1101001231]={1010012267,1010012268,1010012269,1010012273,1010012272,1010012274,1010012266,1010012265,1010012264,1010012263,1010012262,1010012075,0,0,0,0,0,0,0,0,1010012275,0},
    [1101001242]={1010012357,1010012358,1010012359,1010012363,1010012362,1010012364,1010012356,1010012355,1010012354,1010012353,1010012352,1010012276,0,0,0,0,0,0,0,0,1010012365,0},
    [1101001249]={1010012437,1010012438,1010012439,1010012443,1010012442,1010012444,1010012436,1010012435,1010012434,1010012433,1010012432,1010012366,0,0,0,0,0,0,0,0,1010012445,0},
    [1101001256]={1010012588,1010012589,1010012590,1010012593,1010012592,1010012594,1010012587,1010012586,1010012585,1010012584,1010012583,1010012582,0,0,0,0,0,0,0,0,1010012595,0},
    [1101001265]={1010012698,1010012699,1010012700,1010012703,1010012702,1010012704,1010012697,1010012696,1010012695,1010012694,1010012693,1010012692,0,0,0,0,0,0,0,0,1010012705,0},
    [1101001276]={1010012698,1010012699,1010012700,1010012703,1010012702,1010012704,1010012697,1010012696,1010012695,1010012694,1010012693,1010012692,0,0,0,0,0,0,0,0,1010012705,0},
    [1101002029]={1010020249,1010020250,1010020255,1010020247,1010020246,1010020248,1010020240,1010020239,1010020238,1010020237,1010020236,1010020235,0,0,0,0,0,0,0,1010020257,1010020256,1010020258},
    [1101002056]={1010020519,0,0,1010020517,1010020516,1010020518,1010020500,1010020509,1010020508,1010020507,1010020506,1010020505,0,0,0,0,0,0,0,0,0,0},
    [1101002081]={1010020768,1010020769,1010020770,1010020766,1010020760,1010020767,1010020759,1010020758,1010020757,1010020756,1010020755,1010020776,0,0,0,0,0,0,0,1010020775,1010020777,1010020778},
    [1101003070]={1010030654,1010030653,1010030655,1010030649,1010030648,1010030650,1010030647,1010030646,1010030645,1010030644,1010030643,1010030642,0,1010030658,1010030656,1010030660,1010030662,1010030659,1010030657,0,1010030663,0},
    [1101003080]={1010030754,1010030753,1010030755,1010030749,1010030748,1010030750,1010030747,1010030746,1010030745,1010030744,1010030743,1010030742,0,1010030758,1010030756,1010030760,1010030762,1010030759,1010030757,0,1010030763,0},
    [1101003099]={1010030943,1010030944,1010030945,1010030939,1010030938,1010030942,1010030937,1010030936,1010030935,1010030934,1010030933,1010030932,0,1010030947,1010030946,1010030948,1010030949,1010030953,1010030952,0,1010030955,0},
    [1101003119]={1010031139,1010031140,1010031142,1010031138,1010031137,1010031146,1010031136,1010031135,1010031134,1010031133,1010031132,0,0,1010031144,1010031143,0,0,0,1010031145,0,0,0},
    [1101003146]={1010031229,1010031230,1010031237,1010031228,1010031227,1010031242,1010031226,1010031225,1010031224,1010031223,1010031222,0,0,1010031239,1010031238,0,0,0,1010031240,0,0,0},
    [1101003167]={1010031609,1010031610,1010031613,1010031608,1010031607,1010031617,1010031606,1010031605,1010031604,1010031603,1010031602,1010031618,0,1010031615,1010031614,1010031620,1010031622,1010031619,1010031616,0,1010031623,0},
    [1101003181]={1010031765,1010031764,1010031766,1010031759,1010031758,1010031763,1010031757,1010031756,1010031755,1010031754,1010031753,1010031752,0,1010031769,1010031767,1010031773,1010031774,1010031772,1010031768,0,1010031775,0},
    [1101003195]={1010031912,1010031911,1010031913,1010031908,1010031907,1010031909,1010031906,1010031905,1010031904,1010031903,1010031902,1010031901,0,1010031916,1010031914,1010031918,1010031919,1010031917,1010031915,0,1010031921,0},
    [1101003208]={1010032034,1010032033,1010032045,1010032029,1010032028,1010032032,1010032027,1010032026,1010032025,1010032024,1010032023,1010032022,0,1010032038,1010032036,1010032042,1010032043,1010032039,1010032037,0,1010032044,0},
    [1101004046]={1010040474,1010040475,1010040476,1010040472,1010040471,1010040473,1010040470,1010040469,1010040468,1010040467,1010040466,1010040481,0,1010040479,1010040477,1010040482,1010040483,1010040484,1010040478,1010040480,1010040485,0},
    [1101004062]={1010040578,1010040577,1010040579,1010040575,1010040570,1010040576,1010040569,1010040568,1010040567,1010040566,1010040565,1010040564,0,1010040585,1010040580,1010040587,1010040588,1010040589,1010040584,1010040586,1010040590,1010040594},
    [1101004098]={1010040924,1010040926,1010040925,0,1010040937,1010040938,1010040935,1010040934,1010040929,1010040928,1010040927,0,0,1010040939,1010040945,0,0,0,1010040944,1010040936,0,0},
    [1101004138]={1010041136,1010041137,1010041138,1010041134,1010041129,1010041135,1010041128,1010041127,1010041126,1010041125,1010041124,0,0,1010041145,1010041139,0,0,0,1010041144,1010041146,0,0},
    [1101004163]={1010041570,1010041574,1010041575,1010041568,1010041567,1010041569,1010041566,1010041565,1010041564,1010041560,1010041554,0,0,1010041578,1010041576,0,0,0,1010041577,1010041579,0,0},
    [1101004201]={1010041956,1010041957,1010041958,1010041950,1010041949,1010041955,1010041948,1010041947,1010041946,1010041945,1010041944,1010041967,0,1010041965,1010041959,0,0,0,1010041960,1010041966,0,0},
    [1101004209]={1010042038,1010042037,1010042039,1010042035,1010042034,1010042036,1010042029,1010042028,1010042027,1010042026,1010042025,1010042024,0,1010042046,1010042044,1010042048,1010042049,1010042054,1010042045,1010042047,1010042055,0},
    [1101004218]={1010042128,1010042127,1010042129,1010042125,1010042124,1010042126,1010042119,1010042118,1010042117,1010042116,1010042115,1010042114,0,1010042136,1010042134,1010042138,1010042139,1010042144,1010042135,1010042137,1010042145,0},
    [1101004226]={1010042238,1010042237,1010042239,1010042235,1010042234,1010042236,1010042233,1010042232,1010042231,1010042219,1010042218,1010042217,0,1010042243,1010042241,1010042245,1010042246,1010042247,1010042242,1010042244,1010042248,0},
    [1101004246]={1010042406,1010042407,1010042408,1010042404,1010042400,1010042405,1010042399,1010042398,1010042397,1010042396,1010042395,1010042394,0,1010042414,1010042409,1010042416,1010042417,1010042418,1010042410,1010042415,1010042419,1010042420},
    [1101005038]={0,0,1010050327,1010050329,1010050328,1010050330,1010050326,1010050325,1010050324,1010050323,1010050322,1010050334,0,0,0,0,0,0,0,0,0,0},
    [1101005052]={0,0,1010050467,1010050469,1010050468,1010050470,1010050466,1010050465,1010050464,1010050463,1010050462,1010050473,0,0,0,0,0,0,0,0,0,0},
    [1101005098]={0,0,1010050928,1010050930,1010050929,1010050932,1010050927,1010050926,1010050925,1010050924,1010050923,1010050922,0,0,0,0,0,0,0,0,0,0},
    [1101006062]={1010060573,1010060572,1010060574,1010060564,1010060563,1010060571,1010060562,1010060561,1010060554,1010060553,1010060552,1010060551,0,1010060583,1010060581,1010060591,1010060592,1010060584,1010060582,0,1010060593,0},
    [1101006075]={1010060702,1010060701,1010060703,1010060698,1010060697,1010060699,1010060696,1010060695,1010060694,1010060693,1010060692,1010060691,0,1010060706,1010060704,1010060708,1010060709,1010060707,1010060705,0,1010060711,0},
    [1101006085]={1010060796,1010060795,1010060797,1010060793,1010060789,1010060794,1010060788,1010060787,1010060786,1010060785,1010060784,1010060783,0,1010060800,1010060798,1010060804,1010060805,1010060803,1010060799,0,1010060806,0},
    [1101007046]={1010070410,1010070413,1010070414,1010070408,1010070407,1010070409,1010070406,1010070405,1010070404,1010070403,1010070402,1010070418,0,1010070417,1010070415,1010070420,1010070422,1010070419,1010070416,0,1010070423,0},
    [1101007062]={1010070579,1010070578,1010070581,1010070576,1010070575,1010070577,1010070574,1010070573,1010070572,1010070571,1010070569,1010070568,0,1010070584,1010070582,1010070585,1010070586,1010070587,1010070583,0,1010070588,0},
    [1101007071]={1010070663,1010070662,1010070664,1010070659,1010070658,1010070660,1010070657,1010070656,1010070655,1010070654,1010070653,1010070652,0,1010070667,1010070665,1010070668,1010070669,1010070670,1010070666,0,1010070672,0},
    [1101008051]={1010080463,1010080464,1010080465,1010080459,1010080458,1010080462,1010080457,1010080456,1010080455,1010080454,1010080453,1010080452,0,1010080467,1010080466,1010080468,1010080469,1010080473,1010080472,0,1010080475,0},
    [1101008061]={1010080563,1010080564,1010080565,1010080559,1010080558,1010080562,1010080557,1010080556,1010080555,1010080554,1010080553,0,0,1010080567,1010080566,0,0,0,1010080572,0,0,0},
    [1101008070]={1010080609,1010080612,1010080613,1010080608,1010080607,1010080617,1010080606,1010080605,1010080604,1010080603,1010080602,0,0,1010080615,1010080614,0,0,0,1010080616,0,0,0},
    [1101008081]={1010080740,1010080743,1010080745,1010080738,1010080737,1010080739,1010080736,1010080735,1010080734,1010080733,1010080732,1010080748,0,1010080747,1010080746,1010080750,1010080752,1010080749,1010080744,0,1010080753,0},
    [1101008104]={1010080980,1010080982,1010080984,1010080978,1010080977,1010080979,1010080976,1010080975,1010080974,1010080973,1010080972,1010080992,0,1010080986,1010080985,1010080989,1010080987,1010080993,1010080983,0,1010080988,0},
    [1101008116]={1010081110,1010081112,1010081114,1010081108,1010081107,1010081109,1010081106,1010081105,1010081104,1010081103,1010081102,0,0,1010081116,1010081115,0,0,0,1010081113,0,0,0},
    [1101008126]={1010081210,1010081225,1010081226,1010081208,1010081207,1010081209,1010081206,1010081205,1010081204,1010081203,1010081202,1010081218,0,1010081217,1010081216,1010081219,1010081220,1010081222,1010081214,1010081228,1010081227,1010081229},
    [1101008136]={1010081314,1010081315,1010081316,1010081312,1010081308,1010081313,1010081307,1010081306,1010081305,1010081304,1010081303,1010081302,0,1010081318,1010081317,1010081322,1010081323,1010081325,1010081324,0,1010081326,0},
    [1101008146]={1010081401,1010081402,1010081403,1010081398,1010081397,1010081399,1010081396,1010081395,1010081394,1010081393,1010081392,1010081391,0,1010081405,1010081404,1010081406,1010081407,1010081409,1010081408,0,1010081411,0},
    [1101008154]={1010081531,1010081532,1010081533,1010081528,1010081527,1010081529,1010081526,1010081525,1010081524,1010081523,1010081522,1010081521,0,1010081541,1010081534,1010081542,1010081543,1010081545,1010081544,0,1010081546,0},
    [1101008163]={1010081582,1010081583,1010081584,1010081579,1010081578,1010081580,1010081577,1010081576,1010081575,1010081574,1010081573,1010081572,0,1010081586,1010081585,1010081587,1010081588,1010081590,1010081589,0,1010081592,0},
    [1101012033]={1010120284,1010120285,1010120286,1010120280,1010120279,1010120283,1010120278,1010120277,1010120276,1010120275,1010120274,1010120273,0,0,0,0,0,0,0,0,1010120287,0},
    [1101100012]={1011000066,1011000067,1011000068,0,0,0,1011000058,1011000057,1011000056,1011000055,1011000054,1011000053,0,0,0,0,0,0,0,0,1011000073,0},
    [1101102007]={1011010025,1011010024,1011010026,1011010020,1011010019,1011010023,1011010018,1011010017,1011010016,1011010015,1011010014,1011010013,0,0,0,0,0,0,0,0,1011010027,0},
    [1101102017]={1011020027,1011020028,1011020029,1011020025,1011020024,1011020026,1011020019,1011020018,1011020017,1011020016,1011020015,1011020014,0,1011020036,1011020034,1011020038,1011020039,1011020044,1011020035,1011020037,1011020045,1011020047},
    [1101102025]={1011020127,1011020128,1011020129,1011020125,1011020124,1011020126,1011020119,1011020118,1011020117,1011020116,1011020115,1011020114,0,1011020136,1011020134,1011020138,1011020139,1011020144,1011020135,1011020137,1011020145,0},
    [1101102041]={1011020214,1011020215,1011020216,1011020212,1011020211,1011020213,1011020209,1011020208,1011020207,1011020206,1011020205,1011020204,0,1011020219,1011020217,1011020222,1011020223,1011020224,1011020218,1011020221,1011020225,1011020229},
    [1101102049]={1011020356,1011020357,1011020358,1011020354,1011020350,1011020355,1011020349,1011020348,1011020347,1011020346,1011020345,1011020344,0,1011020364,1011020359,1011020366,1011020367,1011020368,1011020360,1011020365,1011020369,1011020370},
    [1101101007]={1011020436,1011020437,1011020438,1011020434,1011020430,1011020435,1011020429,1011020428,1011020427,1011020426,1011020425,1011020424,0,1011020444,1011020439,1011020446,1011020447,1011020448,1011020440,1011020445,1011020449,1011020450},
    [1102001120]={1020011137,1020011138,1020011139,1020011135,1020011134,1020011136,1020011133,1020011132,0,0,0,0,0,0,0,0,0,0,0,1020011142,0,0},
    [1102001130]={1020011247,1020011248,1020011249,1020011245,1020011244,1020011246,1020011243,1020011242,0,0,0,0,0,0,0,0,0,0,0,1020011250,0,0},
    [1102002043]={1020020372,1020020374,1020020373,1020020383,1020020380,1020020384,1020020379,1020020378,1020020377,1020020376,1020020375,1020020388,0,1020020385,1020020387,0,0,0,1020020386,0,0,0},
    [1102002061]={1020020552,1020020554,1020020553,1020020563,1020020562,1020020564,1020020559,1020020558,1020020557,1020020556,1020020555,1020020578,0,1020020565,1020020567,1020020573,1020020574,1020020572,1020020566,0,1020020569,0},
    [1102002136]={1020021314,1020021313,1020021315,1020021309,1020021308,1020021312,1020021307,1020021306,1020021305,1020021304,1020021303,1020021302,0,1020021318,1020021316,1020021323,1020021324,1020021322,1020021317,0,1020021325,0},
    [1102002424]={1020024193,1020024192,1020024194,1020024189,1020024188,1020024190,1020024187,1020024186,1020024185,1020024184,1020024183,1020024182,0,1020024197,1020024195,1020024199,1020024200,1020024198,1020024196,0,1020024202,0},
    [1102003080]={1020030755,1020030756,1020030758,0,1020030749,1020030754,1020030748,1020030747,1020030746,1020030745,1020030744,1020030764,0,1020030760,0,1020030759,1020030757,0,0,1020030765,0,0},
    [1102003100]={1020030956,1020030957,1020030958,1020030954,1020030950,1020030955,1020030949,1020030948,1020030947,1020030946,1020030945,1020030944,0,1020030964,0,1020030960,1020030959,1020030965,0,1020030967,1020030966,1020030968},
    [1102005064]={1020050588,1020050589,1020050590,0,0,0,1020050587,1020050586,1020050585,1020050584,1020050583,1020050582,0,0,0,0,0,0,0,0,1020050592,0},
    [1103001101]={1030010954,1030010955,1030010956,0,0,0,0,0,0,0,1030010953,1030010952,1030010951,0,0,0,0,0,0,1030010957,0,1030010958},
    [1103001146]={1030011344,1030011345,1030011346,0,0,0,0,0,0,0,1030011343,1030011342,1030011341,0,0,0,0,0,0,1030011347,0,1030011348},
    [1103001154]={1030011484,1030011485,1030011486,0,0,0,0,0,0,0,1030011483,1030011482,1030011481,0,0,0,0,0,0,1030011487,0,1030011488},
    [1103001179]={1030011738,1030011739,1030011741,0,0,0,1030011737,1030011736,1030011735,1030011734,1030011733,1030011732,1030011731,0,0,0,0,0,0,1030011742,1030011743,1030011744},
    [1103001191]={1030011858,1030011859,1030011861,0,0,0,1030011857,1030011856,1030011855,1030011854,1030011853,1030011852,1030011851,0,0,0,0,0,0,1030011862,1030011863,1030011864},
    [1103001202]={1030011948,1030011949,1030011950,0,0,0,1030011947,1030011946,1030011945,1030011944,1030011943,1030011942,1030011941,0,0,0,0,0,0,1030011951,1030011952,1030011953},
    [1103002030]={1030020245,1030020246,1030020247,1030020252,1030020249,1030020253,1030020258,1030020257,1030020256,1030020255,1030020244,1030020243,1030020242,0,0,0,0,0,0,1030020248,0,0},
    [1103002059]={1030020544,1030020545,1030020546,1030020542,1030020539,1030020543,1030020538,1030020537,1030020536,1030020535,1030020534,1030020533,1030020532,0,0,0,0,0,0,1030020547,1030020548,0},
    [1103002087]={1030020824,1030020825,1030020826,0,0,0,1030020818,1030020817,1030020816,1030020815,1030020814,1030020813,1030020812,0,0,0,0,0,0,1030020827,1030020828,0},
    [1103002106]={1030021009,1030021010,1030021012,1030021015,1030021014,1030021016,1030021008,1030021007,1030021006,1030021005,1030021004,1030021003,1030021002,0,0,0,0,0,0,1030021013,1030021017,0},
    [1103002113]={1030021079,1030021080,1030021082,1030021085,1030021084,1030021086,1030021078,1030021077,1030021076,1030021075,1030021074,1030021073,1030021072,0,0,0,0,0,0,1030021083,1030021087,0},
    [1103003022]={1030030165,1030030166,1030030167,1030030172,1030030169,1030030173,0,0,0,0,1030030164,1030030163,1030030162,0,0,0,0,0,0,0,0,0},
    [1103003030]={1030030256,1030030257,1030030258,1030030254,1030030253,1030030255,1030030248,1030030247,1030030246,1030030245,1030030244,1030030243,1030030242,0,0,0,0,0,0,1030030259,1030030249,0},
    [1103003042]={1030030374,1030030375,1030030376,1030030372,1030030369,1030030373,0,0,0,0,1030030364,1030030363,1030030362,0,0,0,0,0,0,1030030377,0,0},
    [1103003051]={1030030458,1030030459,1030030460,1030030456,1030030455,1030030457,0,0,0,0,1030030454,1030030453,1030030452,0,0,0,0,0,0,1030030463,0,0},
    [1103003062]={1030030568,1030030569,1030030570,1030030566,1030030565,1030030567,0,0,0,0,1030030564,1030030563,1030030562,0,0,0,0,0,0,1030030572,0,0},
    [1103003079]={1030030744,1030030745,1030030746,1030030742,1030030740,1030030743,1030030738,1030030737,1030030736,1030030735,1030030734,1030030733,1030030732,0,0,0,0,0,0,1030030747,1030030739,0},
    [1103003087]={1030030825,1030030826,1030030827,1030030823,1030030824,1030030824,1030030818,1030030817,1030030816,1030030815,1030030814,1030030813,1030030812,0,0,0,0,0,0,1030030828,1030030819,0},
    [1103004037]={1030040315,1030040316,1030040317,1030040325,1030040324,1030040323,0,0,0,0,1030040314,1030040313,1030040312,1030040327,1030040326,0,0,0,1030040328,1030040329,0,0},
    [1103006030]={1030060245,1030060246,1030060247,0,1030060253,1030060252,0,0,0,0,1030060244,1030060243,1030060242,0,0,0,0,0,0,0,0,0},
    [1103007028]={1030070233,1030070234,1030070235,1030070226,1030070225,1030070227,1030070218,1030070217,1030070216,1030070215,1030070214,1030070213,1030070212,0,0,0,0,0,0,1030070236,1030070219,0},
    [1103012010]={0,0,0,0,0,0,1030120038,1030120037,1030120036,1030120035,1030120034,1030120033,1030120032,0,0,0,0,0,0,0,0,0},
    [1103012019]={0,0,0,0,0,0,1030120138,1030120137,1030120136,1030120135,1030120134,1030120133,1030120132,0,0,0,0,0,0,0,0,0},
    [1103012031]={0,0,0,0,0,0,1030120258,1030120257,1030120256,1030120255,1030120254,1030120253,1030120252,0,0,0,0,0,0,0,0,0},
    [1103012039]={0,0,0,0,0,0,1030120339,1030120338,1030120337,1030120336,1030120335,1030120334,1030120333,0,0,0,0,0,0,0,0,0},
    [1103102007]={1031020026,1031020027,1031020028,1031020024,1031020023,1031020025,1031020019,1031020018,1031020017,1031020016,1031020015,1031020014,1031020013,0,0,0,0,0,0,1031020029,0,0},
    [1105001034]={0,0,0,0,1050010287,1050010289,1050010286,1050010285,1050010284,1050010283,1050010282,0,0,0,0,0,0,0,0,1050010292,0,0},
    [1105001048]={0,0,0,1050010429,1050010428,1050010434,1050010427,1050010426,1050010425,1050010424,1050010423,0,0,0,0,0,0,0,0,1050010435,0,1050010436},
    [1105001069]={0,0,0,1050010639,1050010638,1050010640,1050010637,1050010636,1050010635,1050010634,1050010633,1050010645,0,0,0,0,0,0,0,1050010643,1050010646,1050010644},
    [1105002091]={0,0,0,0,0,0,1050020847,1050020846,1050020845,1050020844,1050020843,1050020842,0,0,0,0,0,0,0,0,0,1050020848},
    [1105010019]={0,0,0,0,0,0,1050100144,1050100143,1050100142,1050100141,1050100139,1050100138,0,0,0,0,0,0,0,0,0,0}
}

_G.BaseAttachToIndex = {
    [201010]=1, [201005]=1, [201004]=1, [201009]=2, [201003]=2, [201002]=2, 
    [201011]=3, [201007]=3, [201006]=3, [204012]=4, [204005]=4, [204008]=4, 
    [204011]=5, [204004]=5, [204007]=5, [204013]=6, [204006]=6, [204009]=6, 
    [203001]=7, [203002]=8, [203003]=9, [203014]=10, [203004]=11, [203015]=12, [203005]=13, 
    [202002]=14, [202001]=15, [202004]=16, [202005]=17, [202007]=18, [202006]=19, 
    [205002]=20, [205003]=20, [205001]=20, [203018]=21, [204014]=22 
}

_G.VipAttachToIndex = {}
for skinId, attachList in pairs(_G.VIP_Attachments) do
    for index, attachId in ipairs(attachList) do
        if attachId > 0 then
            _G.VipAttachToIndex[attachId] = index
        end
    end
end

_G.WeaponSkinMap = _G.WeaponSkinMap or {}
_G.VehicleSkinMap = _G.VehicleSkinMap or {}
_G.OutfitMap = _G.OutfitMap or {}
_G.skinIdCache = _G.skinIdCache or {}
_G.skinIdCache2 = _G.skinIdCache2 or {}

_G.OutfitSkins = {
    Suit = {1405628,1407895,1407140,1407141,1407142,1407550,1406872,1406971,1407103,1407219,1407366,1407512,1407625,1407856,1407906,1407994,1407993,403003,1407906,1407921,1406388,1406387,1406386,1407142,1407550,1406638,1406872,1406971,1407103,1407512,1407391,1407285,1407330,1407329,1407286,1407285,1407277,1407276,1407275,1407225,1407224,1407259,1407161,1407160,1407107,1407106,1407079,1407048,1406977,1406976,1406898,1400569,1404000,1404049,1400119,1400117,1406060,1406891,1400687,1405160,1405145,1405436,1405435,1405434,1405064,1405207,1406398,1407812,1405132,1407856,1405121,1406889,1407278,1407279,1407381,1407380,1407916,1406469,1405870,1407140,1407141,1406385,1406140,1400782,1407392,1407318,1407317,1407404,1407402,1407401,1407387,1404434,1404437,1404440,1404448,1400324,1400708,1404043,1404048,1405953,1400101,1404153,1407440,1407441,1407522},
    Bag = {
        {501001, 501002, 501003}, {1501001174, 1501002174, 1501003174}, {1501001220, 1501002220, 1501003220},
        {1501001051, 1501002051, 1501003051}, {1501001443, 1501002443, 1501003443}, {1501001265, 1501002265, 1501003265},
        {1501001321, 1501002321, 1501003321}, {1501001277, 1501002277, 1501003277}, {1501001550, 1501002550, 1501003550},
        {1501001592, 1501002592, 1501003592}, {1501001608, 1501002608, 1501003608}, {1501001024, 1501002024, 1501003024},
        {1501001019, 1501002019, 1501003019}, {1501001179, 1501002179, 1501003179}, {1501001194, 1501002194, 1501003194},
        {1501001346, 1501002346, 1501003346}, {1501001057, 1501002057, 1501003057}
    },
    Helmet = {
        {502001, 502002, 502003}, {1502001014, 1502002014, 1502003014}, {1502001349, 1502002349, 1502003349},
        {1502001012, 1502002012, 1502003012}, {1502001009, 1502002009, 1502003009}, {1502001397, 1502002397, 1502003397},
        {1502001390, 1502002390, 1502003390}, {1502001381, 1502002381, 1502003381}, {1502001358, 1502002358, 1502003358},
        {1502001350, 1502002350, 1502003350}, {1502001342, 1502002342, 1502003342},
 {1502001058, 1502002058, 1502003058}
        
    },
    Pet = {50000,50001,50002,50003,50004,50005,50006,50021,50022,50038,50039,50040}
}

_G.skinIdMappings = {
    [101004]={101004, 1101004246,1101004226,1101004236,1101004062,1101004078,1101004086,1101004201,1101004218,1101004046},
    [101001]={101001,1101001276,1101001265,1101001213,1101001172,1101001127,1101001230,1101001241},                    
    [101003]={101003,1101003227,1103003208,1101003195,1101003187,1101003098,1101003166,1101003218},                                             
    [101008]={101008,1101008146,1101008154,1101008079,1101008126,1101008104,1101008146,1101008061,1101008116},                    
    [101006]={101006,1101006106,1101006085,1101006061,1101006074,1101006043,1101006032,1101006084},
    [101012]={101012,1101012033},
    [101007]={101007,1101007062,1101007071},
    [102002]={102002,1102002136,1102002043,1102002061,1102002424,1102002438},      
    [101101]={101101, 1101101007},
    [101102]={101102, 1101102041},
    [102001]={102001, 1102001120},
    [102003]={102003, 1102003100},
    [101005]={101005, 1101005098},
    [103001]={103001, 1103001202,1103001191},
    [103002]={103002, 1103002106},
    [103003]={103003, 1103003042,1103003062,1103003099},
    [103012]={103012, 1103012039,1103012010},
    [104003]={104003, 1104003037},
    [104004]={104004, 1104004035, 1104004041}
}

_G.VehicleSkins = { 
    [1961001] = { 1961007, 1961149, 1961069, 1961013, 1961014, 1961015, 1961016, 1961017, 1961018, 1961020, 1961021, 1961024, 1961025, 1961029, 1961030, 1961031, 1961032, 1961033, 1961034, 1961035, 1961036, 1961037, 1961038, 1961039, 1961040, 1961041, 1961042, 1961043, 1961044, 1961045, 1961046, 1961047, 1961048, 1961049, 1961050, 1961051, 1961052, 1961053, 1961054, 1961055, 1961056, 1961057, 1961058, 1961059, 1961060, 1961061, 1961062, 1961063, 1961064, 1961065, 1961066, 1961067, 1961068,1961136, 1961137, 1961138, 1961139, 1961140, 1961141, 1961142, 1961143, 1961144, 1961145, 1961147, 1961148, 1961010, 1961150, 1961151, 1961152, 1961153 },
    [1903001] = { 1903005, 1903006, 1903007, 1903008, 1903011, 1903012, 1903013, 1903014, 1903015, 1903016, 1903017, 1903018, 1903019, 1903020, 1903021, 1903022, 1903023, 1903024, 1903029, 1903030, 1903031, 1903032, 1903033, 1903034, 1903035, 1903036, 1903037, 1903039, 1903040, 1903041, 1903042, 1903043, 1903044, 1903045, 1903046, 1903051, 1903052, 1903053, 1903054, 1903055, 1903056, 1903057, 1903058, 1903059, 1903060, 1903061, 1903062, 1903063, 1903066, 1903067, 1903068, 1903069, 1903070, 1903071, 1903072, 1903073, 1903074, 1903075, 1903076, 1903079, 1903080, 1903081, 1903082, 1903084, 1903085, 1903086, 1903087, 1903088, 1903089, 1903090, 1903189, 1903190, 1903191, 1903192, 1903193, 1903194, 1903195, 1903196, 1903197, 1903198, 1903199, 1903200, 1903201, 1903202, 1903203, 1903204, 1903205, 1903206, 1903207, 1903208, 1903209, 1903210, 1903211, 1903212, 1903213, 1903214, 1903215, 1903216, 1903217, 1903218, 1903219, 1903220, 1903221, 1903222, 1903223, 1903225, 1903226, 1903227, 1903228 }, 
    [1915001] = { 1915002, 1915003, 1915007, 1915005, 1915006, 1915008, 1915009, 1915010, 1915011, 1915012, 1915013, 1915014, 1915015, 1915016, 1915017, 1915018, 1915019, 1915020, 1915021, 1915022, 1915023, 1915024, 1915025, 1915026, 1915027, 1915099 },          
    [1908001] = { 1908002, 1908003, 1908094, 1908006, 1908007, 1908008, 1908009, 1908010, 1908011, 1908012, 1908013, 1908015, 1908016, 1908017, 1908018, 1908019, 1908021, 1908023, 1908030, 1908031, 1908032, 1908033, 1908034, 1908035, 1908036, 1908037, 1908039, 1908040, 1908041, 1908043, 1908047, 1908049, 1908050, 1908051, 1908052, 1908053, 1908054, 1908055, 1908056, 1908057, 1908059, 1908060, 1908061, 1908062, 1908063, 1908064, 1908066, 1908067, 1908068, 1908069, 1908070, 1908075, 1908076, 1908077, 1908078, 1908080, 1908081, 1908082, 1908083, 1908084, 1908085, 1908086, 1908087, 1908088, 1908089, 1908091, 1908095, 1908096, 1908097, 1908098, 1908099, 1908100, 1908101, 1908102, 1908104, 1908105, 1908106, 1908107, 1908108, 1908109, 1908110, 1908111, 1908112, 1908188, 1908189 },   
    [1907001] = { 1907007, 1907008, 1907010, 1907011, 1907012, 1907013, 1907014, 1907016, 1907018, 1907019, 1907021, 1907022, 1907023, 1907025, 1907026, 1907027, 1907028, 1907029, 1907030, 1907032, 1907033, 1907034, 1907035, 1907036, 1907037, 1907038, 1907040, 1907041, 1907043, 1907044, 1907045, 1907046, 1907047, 1907048, 1907049, 1907050, 1907051, 1907052, 1907053, 1907054, 1907055, 1907056, 1907058, 1907059, 1907060, 1907061, 1907062, 1907063, 1907064, 1907065, 1907066, 1907067, 1907068, 1907069, 1907070, 1907071, 1907072, 1907073, 1907074 }
}
_G.CustSlotType = { ClothesEquipemtSlot=5, BackpackEquipemtSlot=8, HelmetEquipemtSlot=9, ParachuteEquipemtSlot=11, GlideEquipemtSlot=15 }

local function DownloadGameItem(id)
    local puffer_manager = require('client.slua.logic.download.puffer.puffer_manager')
    local puffer_const = require('client.slua.logic.download.puffer_const')
    if puffer_manager and puffer_const and puffer_manager.GetState(puffer_const.ENUM_DownloadType.ODPTD, {id}) ~= puffer_const.ENUM_DownloadState.Done then
        puffer_manager.Download(puffer_const.ENUM_DownloadType.ODPTD, {id})
    end
end
_G.download_item = DownloadGameItem

_G.get_skin_id = function(weaponID)
    if not weaponID then return nil end
    local targetSkinId = _G.WeaponSkinMap and _G.WeaponSkinMap[weaponID]
    if targetSkinId and targetSkinId > 0 then
        if not _G.skinIdCache2[targetSkinId] then
            if _G.download_item then pcall(_G.download_item, targetSkinId) end
            _G.skinIdCache2[targetSkinId] = true
        end
        return targetSkinId
    end
    return weaponID
end

_G.equip_character_avatar = function(Character)
    if not Character or not slua.isValid(Character) or not Character.AvatarComponent2 then return end
    local BackpackUtils = import("BackpackUtils")
    local SlotSyncData = Character.AvatarComponent2.NetAvatarData and Character.AvatarComponent2.NetAvatarData.SlotSyncData
    if not SlotSyncData or not slua.isValid(SlotSyncData) or not BackpackUtils then return end
    
    local function EquipAvatar(ApplyDataIdx, mappedSkin, ApplyEquipSlot, isLevelDependent, levelFunc)
        if not mappedSkin or mappedSkin == 0 then return end
        local slotData = SlotSyncData:Get(ApplyDataIdx)
        if slotData and slotData.SlotID == ApplyEquipSlot then
            local applyItemId = mappedSkin
            if isLevelDependent and type(mappedSkin) == "table" then
                local level = levelFunc(slotData.AdditionalItemID) or 1
                if level < 1 then level = 1 end
                if level > 3 then level = 3 end
                applyItemId = mappedSkin[level] or mappedSkin[1]
            end
            if not applyItemId or applyItemId == 0 or slotData.ItemId == applyItemId then return end
            if not _G.skinIdCache[applyItemId] then
                if _G.download_item then pcall(_G.download_item, applyItemId) end
                _G.skinIdCache[applyItemId] = true
            end
            slotData.ItemId = applyItemId
            SlotSyncData:Set(ApplyDataIdx, slotData)
            Character.AvatarComponent2:OnRep_BodySlotStateChanged()
        end
    end

    local hasGliderSlot = false
    for i = 0, SlotSyncData:Num() - 1 do
        local slotData = SlotSyncData:Get(i)
        if slotData and slotData.SlotID == _G.CustSlotType.GlideEquipemtSlot then 
            hasGliderSlot = true
            break 
        end
    end
    if not hasGliderSlot then SlotSyncData:Add({ SlotID = _G.CustSlotType.GlideEquipemtSlot, ItemId = 0 }) end

    for i = 0, SlotSyncData:Num() - 1 do
        EquipAvatar(i, _G.OutfitMap.Suit or 0, _G.CustSlotType.ClothesEquipemtSlot, false)
        EquipAvatar(i, _G.OutfitMap.Bag, _G.CustSlotType.BackpackEquipemtSlot, true, BackpackUtils.GetEquipmentBagLevel)
        EquipAvatar(i, _G.OutfitMap.Helmet, _G.CustSlotType.HelmetEquipemtSlot, true, BackpackUtils.GetEquipmentHelmetLevel)
        EquipAvatar(i, _G.OutfitMap.Parachute or 0, _G.CustSlotType.ParachuteEquipemtSlot, false)
    end
end

_G.ApplyWeaponSkins = function(PlayerCharacter)
    pcall(function()
        local WeaponManager = PlayerCharacter:GetWeaponManager()
        if not slua.isValid(WeaponManager) then return end
        
        for slot = 1, 3 do
            local Weapon = WeaponManager:GetInventoryWeaponByPropSlot(slot)
            if slua.isValid(Weapon) and slua.isValid(Weapon.synData) then
                local WeaponID = Weapon:GetWeaponID()
                local SkinID = _G.get_skin_id(WeaponID) or WeaponID
                local isModified = false
                
                local SkinData = Weapon.synData:Get(7) 
                if SkinData and SkinData.defineID and SkinData.defineID.TypeSpecificID ~= SkinID then
                    SkinData.defineID.TypeSpecificID = SkinID
                    Weapon.synData:Set(7, SkinData)
                    if Weapon.SetWeaponAvatarID then pcall(function() Weapon:SetWeaponAvatarID(SkinID) end) end
                    if not _G.skinIdCache[SkinID] then 
                        _G.download_item(SkinID)
                        _G.skinIdCache[SkinID] = true 
                    end
                    isModified = true
                end
                
                if SkinID >= 10000000 and _G.VIP_Attachments and _G.VIP_Attachments[SkinID] then
                    for AttachIdx = 0, 5 do 
                        local attachData = Weapon.synData:Get(AttachIdx)
                        if attachData then
                            local defineIDRef = slua.IndexReference(attachData, "defineID")
                            if defineIDRef then
                                local attachmentId = defineIDRef.TypeSpecificID
                                if attachmentId and attachmentId > 0 then
                                    local mapIndex = _G.BaseAttachToIndex[attachmentId] or _G.VipAttachToIndex[attachmentId]
                                    if mapIndex and _G.VIP_Attachments[SkinID][mapIndex] and _G.VIP_Attachments[SkinID][mapIndex] > 0 then
                                        local targetAttachId = _G.VIP_Attachments[SkinID][mapIndex]
                                        if targetAttachId ~= attachmentId then
                                            attachData.defineID.TypeSpecificID = targetAttachId
                                            Weapon.synData:Set(AttachIdx, attachData)
                                            if not _G.skinIdCache2[targetAttachId] then 
                                                if _G.download_item then pcall(_G.download_item, targetAttachId) end
                                                _G.skinIdCache2[targetAttachId] = true 
                                            end
                                            isModified = true
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
                
                if isModified then
                    if Weapon.DelayHandleAvatarMeshChanged then pcall(function() Weapon:DelayHandleAvatarMeshChanged() end) end
                    if Weapon.OnRep_synData then pcall(function() Weapon:OnRep_synData() end) end
                end
            end
        end
    end)
end

_G.ApplyVehicleSkins = function(PlayerCharacter)
    pcall(function()
        local Vehicle = PlayerCharacter:GetCurrentVehicle()
        if not slua.isValid(Vehicle) then 
            _G.LastVehicleEntity = nil
            return 
        end
        
        if _G.LastVehicleEntity == Vehicle and _G.CurrentEquipVehicleID ~= nil then
            return
        end

        local VehicleAvatar = Vehicle.VehicleAvatar or Vehicle.VehicleAvatarComponent_BP or Vehicle:GetAvatarComponent()
        if not slua.isValid(VehicleAvatar) then return end

        local defId = tostring(VehicleAvatar:GetDefaultAvatarID() or Vehicle.VehicleID or "")
        local currentId = tostring(Vehicle:GetAvatarId() or "")
        local applySkinId = 0
        
        for baseMapId, targetSkin in pairs(_G.VehicleSkinMap) do
            if defId:find(tostring(baseMapId)) or currentId:find(tostring(baseMapId)) then 
                applySkinId = targetSkin
                break 
            end
        end

        if applySkinId and applySkinId > 0 then
            _G.skinIdCache = _G.skinIdCache or {}
            if not _G.skinIdCache[applySkinId] then 
                if _G.download_item then pcall(_G.download_item, applySkinId) end
                _G.skinIdCache[applySkinId] = true 
            end

            VehicleAvatar.curSwitchEffectId = 7303001
            if VehicleAvatar.ChangeItemAvatar then VehicleAvatar:ChangeItemAvatar(applySkinId, true) end
            
            _G.CurrentEquipVehicleID = applySkinId
            _G.LastVehicleEntity = Vehicle
        end
    end)
end

_G.HandlePetLogic = function()
    pcall(function()
        local petSkin = _G.OutfitMap.Pet
        if not petSkin or petSkin == 0 or petSkin == 50000 or petSkin == _G.LastAppliedPet then return end
        
        _G.skinIdCache = _G.skinIdCache or {}
        if not _G.skinIdCache[petSkin] then 
            if _G.download_item then pcall(_G.download_item, petSkin) end
            _G.skinIdCache[petSkin] = true 
        end
        
        local ModuleManager = require("client.module_framework.ModuleManager")
        if ModuleManager then
            local logic_pet = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.logic_pet)
            if logic_pet then
                if logic_pet.SetCurPetID then logic_pet:SetCurPetID(petSkin) end
                if logic_pet.EquipPet then logic_pet:EquipPet(petSkin) end
            end
        end
        _G.LastAppliedPet = petSkin
    end)
end

_G.ForceRefreshSkinMaps = function()
    pcall(function()
        if not _G.AHMADState or not _G.AHMADState.CustomTextData then return end
        local cData = _G.AHMADState.CustomTextData

        if _G.OutfitSkins then
            if cData.SkinSuit and _G.OutfitSkins.Suit[cData.SkinSuit] then _G.OutfitMap.Suit = _G.OutfitSkins.Suit[cData.SkinSuit] end
            if cData.SkinBag and _G.OutfitSkins.Bag[cData.SkinBag] then _G.OutfitMap.Bag = _G.OutfitSkins.Bag[cData.SkinBag] end
            if cData.SkinHelmet and _G.OutfitSkins.Helmet[cData.SkinHelmet] then _G.OutfitMap.Helmet = _G.OutfitSkins.Helmet[cData.SkinHelmet] end
        end

        if _G.skinIdMappings then
            if cData.SkinM416 and _G.skinIdMappings[101004] and _G.skinIdMappings[101004][cData.SkinM416] then _G.WeaponSkinMap[101004] = _G.skinIdMappings[101004][cData.SkinM416] end
            if cData.SkinAKM and _G.skinIdMappings[101001] and _G.skinIdMappings[101001][cData.SkinAKM] then _G.WeaponSkinMap[101001] = _G.skinIdMappings[101001][cData.SkinAKM] end
            if cData.SkinSCAR and _G.skinIdMappings[101003] and _G.skinIdMappings[101003][cData.SkinSCAR] then _G.WeaponSkinMap[101003] = _G.skinIdMappings[101003][cData.SkinSCAR] end
            if cData.SkinM762 and _G.skinIdMappings[101008] and _G.skinIdMappings[101008][cData.SkinM762] then _G.WeaponSkinMap[101008] = _G.skinIdMappings[101008][cData.SkinM762] end
            if cData.SkinAUG and _G.skinIdMappings[101006] and _G.skinIdMappings[101006][cData.SkinAUG] then _G.WeaponSkinMap[101006] = _G.skinIdMappings[101006][cData.SkinAUG] end
            if cData.SkinHoney and _G.skinIdMappings[101012] and _G.skinIdMappings[101012][cData.SkinHoney] then _G.WeaponSkinMap[101012] = _G.skinIdMappings[101012][cData.SkinHoney] end
            if cData.SkinQBZ and _G.skinIdMappings[101007] and _G.skinIdMappings[101007][cData.SkinQBZ] then _G.WeaponSkinMap[101007] = _G.skinIdMappings[101007][cData.SkinQBZ] end
            if cData.SkinASM and _G.skinIdMappings[101101] and _G.skinIdMappings[101101][cData.SkinASM] then _G.WeaponSkinMap[101101] = _G.skinIdMappings[101101][cData.SkinASM] end
            if cData.SkinACE32 and _G.skinIdMappings[101102] and _G.skinIdMappings[101102][cData.SkinACE32] then _G.WeaponSkinMap[101102] = _G.skinIdMappings[101102][cData.SkinACE32] end
            if cData.SkinUMP and _G.skinIdMappings[102002] and _G.skinIdMappings[102002][cData.SkinUMP] then _G.WeaponSkinMap[102002] = _G.skinIdMappings[102002][cData.SkinUMP] end
            if cData.SkinUZI and _G.skinIdMappings[102001] and _G.skinIdMappings[102001][cData.SkinUZI] then _G.WeaponSkinMap[102001] = _G.skinIdMappings[102001][cData.SkinUZI] end
            if cData.SkinVector and _G.skinIdMappings[102003] and _G.skinIdMappings[102003][cData.SkinVector] then _G.WeaponSkinMap[102003] = _G.skinIdMappings[102003][cData.SkinVector] end
            if cData.SkinGroza and _G.skinIdMappings[101005] and _G.skinIdMappings[101005][cData.SkinGroza] then _G.WeaponSkinMap[101005] = _G.skinIdMappings[101005][cData.SkinGroza] end
            if cData.SkinKar98K and _G.skinIdMappings[103001] and _G.skinIdMappings[103001][cData.SkinKar98K] then _G.WeaponSkinMap[103001] = _G.skinIdMappings[103001][cData.SkinKar98K] end
            if cData.SkinM24 and _G.skinIdMappings[103002] and _G.skinIdMappings[103002][cData.SkinM24] then _G.WeaponSkinMap[103002] = _G.skinIdMappings[103002][cData.SkinM24] end
            if cData.SkinAWM and _G.skinIdMappings[103003] and _G.skinIdMappings[103003][cData.SkinAWM] then _G.WeaponSkinMap[103003] = _G.skinIdMappings[103003][cData.SkinAWM] end
            if cData.SkinAMR and _G.skinIdMappings[103012] and _G.skinIdMappings[103012][cData.SkinAMR] then _G.WeaponSkinMap[103012] = _G.skinIdMappings[103012][cData.SkinAMR] end
            if cData.SkinS12K and _G.skinIdMappings[104003] and _G.skinIdMappings[104003][cData.SkinS12K] then _G.WeaponSkinMap[104003] = _G.skinIdMappings[104003][cData.SkinS12K] end
            if cData.SkinDBS and _G.skinIdMappings[104004] and _G.skinIdMappings[104004][cData.SkinDBS] then _G.WeaponSkinMap[104004] = _G.skinIdMappings[104004][cData.SkinDBS] end
        end

        if _G.VehicleSkins then
            if cData.SkinDacia and _G.VehicleSkins[1903001] and _G.VehicleSkins[1903001][cData.SkinDacia] then _G.VehicleSkinMap[1903001] = _G.VehicleSkins[1903001][cData.SkinDacia] end
            if cData.SkinUAZ and _G.VehicleSkins[1908001] and _G.VehicleSkins[1908001][cData.SkinUAZ] then _G.VehicleSkinMap[1908001] = _G.VehicleSkins[1908001][cData.SkinUAZ] end
            if cData.SkinCoupe and _G.VehicleSkins[1961001] and _G.VehicleSkins[1961001][cData.SkinCoupe] then _G.VehicleSkinMap[1961001] = _G.VehicleSkins[1961001][cData.SkinCoupe] end
            if cData.SkinBuggy and _G.VehicleSkins[1907001] and _G.VehicleSkins[1907001][cData.SkinBuggy] then _G.VehicleSkinMap[1907001] = _G.VehicleSkins[1907001][cData.SkinBuggy] end
            if cData.SkinMirado and _G.VehicleSkins[1915001] and _G.VehicleSkins[1915001][cData.SkinMirado] then _G.VehicleSkinMap[1915001] = _G.VehicleSkins[1915001][cData.SkinMirado] end
        end
    end)
end

_G.InitializeSkinModSystem = function()
    pcall(function()
        local LobbyAvatar = package.loaded["client.logic.avatar.LobbyAvatar"] or require("client.logic.avatar.LobbyAvatar")
        if LobbyAvatar and not _G.LobbyBypassHacked then
            local originalPutonEquipment = LobbyAvatar.PutonEquipment
            LobbyAvatar.PutonEquipment = function(self, itemID, tAvatarCustom, tExtraData)
                local attachIndex = _G.BaseAttachToIndex and _G.BaseAttachToIndex[itemID]
                if attachIndex then
                    local holdingWeaponSkinID = self.GetCurHoldingWeaponSkinID and self:GetCurHoldingWeaponSkinID()
                    if holdingWeaponSkinID and holdingWeaponSkinID >= 10000000 and _G.VIP_Attachments and _G.VIP_Attachments[holdingWeaponSkinID] then
                        local vipAttachID = _G.VIP_Attachments[holdingWeaponSkinID][attachIndex]
                        if vipAttachID and vipAttachID > 0 then
                            if self.HandleDownload then self:HandleDownload(vipAttachID, nil, nil, false) end
                            itemID = vipAttachID
                        end
                    end
                end
                if originalPutonEquipment then return originalPutonEquipment(self, itemID, tAvatarCustom, tExtraData) end
            end

            local originalCharEquipWeaponByResId = LobbyAvatar.CharEquipWeaponByResId
            LobbyAvatar.CharEquipWeaponByResId = function(self, resID, isUse, isAsync, SocketName)
                local retValue = originalCharEquipWeaponByResId and originalCharEquipWeaponByResId(self, resID, isUse, isAsync, SocketName) or nil
                if isUse and self.GetEquipments then
                    local equipments = self:GetEquipments()
                    for _, equip in ipairs(equipments) do
                        if _G.BaseAttachToIndex and _G.BaseAttachToIndex[equip.itemID] then
                            self:PutonEquipment(equip.itemID, equip.CustomInfo, {bIsUse = false})
                        end
                    end
                end
                return retValue
            end
            _G.LobbyBypassHacked = true
        end
    end)
    
    pcall(function()
        local Common_Items_UIBP = package.loaded["client.slua.component.item.ItemChildren.Common_Items_UIBP"] or require("client.slua.component.item.ItemChildren.Common_Items_UIBP")
        if Common_Items_UIBP and not _G.IconBaloHacked then
        local originalInitView = Common_Items_UIBP.InitView
            Common_Items_UIBP.InitView = function(self, nItemId, nCount, nValidTime, tExtraData)
                tExtraData = tExtraData or {}
                local displayResId = nil
                
                if _G.get_skin_id then
                    local skinID = _G.get_skin_id(nItemId)
                    if skinID and skinID ~= nItemId then displayResId = skinID end
                end
                
                local attachIndex = _G.BaseAttachToIndex and _G.BaseAttachToIndex[nItemId]
                if not displayResId and attachIndex then
                    local GameplayData = require("GameLua.GameCore.Data.GameplayData")
                    local LocalPlayer = GameplayData and GameplayData.GetPlayerCharacter()
                    if slua.isValid(LocalPlayer) then
                        local currentWeapon = LocalPlayer:GetCurrentWeapon()
                        if slua.isValid(currentWeapon) then
                            local weaponID = currentWeapon:GetWeaponID()
                            local finalSkinID = _G.get_skin_id(weaponID) or weaponID
                            if finalSkinID >= 10000000 and _G.VIP_Attachments and _G.VIP_Attachments[finalSkinID] then
                                local vipAttachID = _G.VIP_Attachments[finalSkinID][attachIndex]
                                if vipAttachID and vipAttachID > 0 then displayResId = vipAttachID end
                            end
                        end
                    end
                end
                
                if displayResId then
                    tExtraData.displayResId = displayResId
                    if not _G.skinIdCache2[displayResId] then
                        if _G.download_item then pcall(_G.download_item, displayResId) end
                        _G.skinIdCache2[displayResId] = true
                    end
                end
                if originalInitView then return originalInitView(self, nItemId, nCount, nValidTime, tExtraData) end
            end
            _G.IconBaloHacked = true
        end
    end)
end

-- ========================================== 
-- KILL COUNTER & KILL MESSAGE EFFECT + DEADBOX SKIN
-- ==========================================
_G.TDFTDeKillCounts = _G.TDFTDeKillCounts or {}
local CACHED_LinearColor = import("LinearColor")
local CACHED_GoldColor = CACHED_LinearColor and CACHED_LinearColor(1.0, 0.8, 0.0, 1.0) or nil
local CACHED_UI_Manager = nil
_G.NeedCheckDeadBoxTimer = 0
_G.LastCheckDeadBoxTime = 0

_G.ForceEnableKillCounterUI = function()
    pcall(function()
        local KillCounterUISubsystem = package.loaded["GameLua.Mod.BaseMod.Client.KillCounter.KillCounterUISubsystem"] or require("GameLua.Mod.BaseMod.Client.KillCounter.KillCounterUISubsystem")
        if KillCounterUISubsystem and KillCounterUISubsystem.__inner_impl and not _G.KCUISystemHacked2 then
            local kcImpl = KillCounterUISubsystem.__inner_impl
            kcImpl.CheckSupportKCUI = function() return true end
            kcImpl.CheckNeedMainKillCounterUI = function(self, PlayerWeapon, PlayerID)
                if slua.isValid(PlayerWeapon) then
                    local WeaponID = PlayerWeapon:GetWeaponID()
                    self:UpdateMainKillCounterUI(true, WeaponID, _G.get_skin_id(WeaponID) or WeaponID)
                else self:UpdateMainKillCounterUI(false) end
            end
            local originalUpdateMainKillCounterUI = kcImpl.UpdateMainKillCounterUI
            kcImpl.UpdateMainKillCounterUI = function(self, bShow, WeaponID, AvatarID)
                if bShow then AvatarID = _G.get_skin_id(WeaponID) or AvatarID end
                if originalUpdateMainKillCounterUI then originalUpdateMainKillCounterUI(self, bShow, WeaponID, AvatarID) end
            end
            _G.KCUISystemHacked2 = true
        end

        local ModuleManager = require("client.module_framework.ModuleManager")
        if ModuleManager and not _G.KCLogicHacked2 then
            local LogicKillCounter = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.LogicKillCounter)
            if LogicKillCounter then
                LogicKillCounter.CheckSupportKC = function() return true end
                LogicKillCounter.CheckSupportKillCounterAvatar = function() return true end
                LogicKillCounter.CheckHasWeaponKillCounter = function() return true end
                LogicKillCounter.GetBaseKillCounterIdByWeaponId = function() return 2100004 end
                LogicKillCounter.GetEquipedKillCounterId = function() return 2100004 end
                LogicKillCounter.GetMyEquipedKillCounterId = function() return 2100004 end
                LogicKillCounter.GetOneWeaponKillCountInBattle = function(self, uid, weaponId) return _G.TDFTDeKillCounts[weaponId] or 0 end
                LogicKillCounter.GetWeaponKillCountByUid = function(self, uid, weaponId) return _G.TDFTDeKillCounts[weaponId] or 0 end
                _G.KCLogicHacked2 = true
            end
        end

        local killInfoPath = "GameLua.Mod.BaseMod.Client.KillInfoTips.KillInfo"
        local KillInfo = package.loaded[killInfoPath] or require(killInfoPath)
        
        if KillInfo and KillInfo.__inner_impl and not _G.KillInfoCounterHacked then
            local originalFileItem = KillInfo.__inner_impl.FileItem
            KillInfo.__inner_impl.FileItem = function(self, DamageRecordData)
                pcall(function()
                    local LocalPlayer = require("GameLua.GameCore.Data.GameplayData").GetPlayerCharacter()
                    if slua.isValid(LocalPlayer) and DamageRecordData.Causer == LocalPlayer:GetPlayerNameSafety() then 
                        local currentWeapon = LocalPlayer:GetCurrentWeapon()
                        if slua.isValid(currentWeapon) then
                            local weaponID = currentWeapon:GetWeaponID()
                            local skinID = _G.get_skin_id(weaponID)
                            if skinID then DamageRecordData.CauserWeaponAvatarID = skinID end
                            if _G.OutfitMap.Suit and _G.OutfitMap.Suit ~= 0 then DamageRecordData.CauserClothAvatarID = _G.OutfitMap.Suit end
                            
                            if CACHED_GoldColor then
                                DamageRecordData.IsUseColor, DamageRecordData.UseColor = true, CACHED_GoldColor
                            end
                            
                            if DamageRecordData.ResultHealthStatus == 2 then
                                _G.TDFTDeKillCounts[weaponID] = (_G.TDFTDeKillCounts[weaponID] or 0) + 1
                                _G.NeedCheckDeadBoxTimer = 50 
                                
                                if not CACHED_UI_Manager then CACHED_UI_Manager = require("client.slua_ui_framework.manager") end
                                local uiMainKillCounter = CACHED_UI_Manager.GetUI(CACHED_UI_Manager.UI_Config_InGame.MainKillCounter)
                                
                                if uiMainKillCounter and uiMainKillCounter.UpdateWeaponID then
                                    local mainAvatarID = skinID or currentWeapon:GetWeaponMainAvatarID()
                                    uiMainKillCounter:UpdateWeaponID(weaponID, mainAvatarID)
                                    local kcModule = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.LogicKillCounter)
                                    local kcItemID = kcModule:GetEquipedKillCounterId(0, mainAvatarID)
                                    uiMainKillCounter:SetKillCounterItemShowWithNum(kcItemID, _G.TDFTDeKillCounts[weaponID], mainAvatarID)
                                end
                            end
                        end
                    end
                end)
                if originalFileItem then return originalFileItem(self, DamageRecordData) end
            end
            _G.KillInfoCounterHacked = true
        end

        local SwitchWeaponSlotMode2 = package.loaded["GameLua.Mod.BaseMod.Client.MainControlUI.SwitchWeaponSlotMode2"] or require("GameLua.Mod.BaseMod.Client.MainControlUI.SwitchWeaponSlotMode2")
        if SwitchWeaponSlotMode2 and SwitchWeaponSlotMode2.__inner_impl and not _G.SlotBaseHacked then
            SwitchWeaponSlotMode2.__inner_impl.CheckShowKCIcon = function(self)
                if slua.isValid(self.KillCounterImg) then 
                    self.KillCounterImg:SetVisibility(import("ESlateVisibility").SelfHitTestInvisible) 
                end
            end
            _G.SlotBaseHacked = true
        end
    end)
end

-- ========================================== 
-- DEADBOX SKIN (temper request)
-- ==========================================
local cached_GameplayStatics = nil
local cached_PlayerTombBox = nil
local cached_ActorClass = nil
_G.DeadBox_TemperRequest = function(PlayerController)
    if _G.NeedCheckDeadBoxTimer <= 0 then return end
    
    local curTime = os.clock()
    if _G.LastCheckDeadBoxTime and (curTime - _G.LastCheckDeadBoxTime) < 2.0 then return end
    _G.LastCheckDeadBoxTime = curTime
    
    _G.NeedCheckDeadBoxTimer = _G.NeedCheckDeadBoxTimer - 1

    local PlayerCharacter = PlayerController:GetPlayerCharacterSafety()
    if not slua.isValid(PlayerCharacter) then return end
    
    if not cached_GameplayStatics then
        cached_GameplayStatics = import("GameplayStatics")
        cached_ActorClass = import("Actor")
        cached_PlayerTombBox = import("PlayerTombBox")
    end
    
    if not _G.CachedActorArray then
        _G.CachedActorArray = slua.Array(UEnums.EPropertyClass.Object, cached_ActorClass)
    end
    
    local UI_Util = require("client.common.ui_util")
    local GameInstance = UI_Util and UI_Util.GetGameInstance()
    if not GameInstance or not cached_GameplayStatics then return end

    local deadBoxes = cached_GameplayStatics.GetAllActorsOfClass(GameInstance, cached_PlayerTombBox, _G.CachedActorArray)
    
    for _, deadBoxActor in pairs(deadBoxes) do
        if slua.isValid(deadBoxActor) and not deadBoxActor.bIsTDSkinApplied then
            local damageCauser = deadBoxActor.DamageCauser
            if damageCauser and damageCauser.PlayerKey == PlayerController.PlayerKey then
                local DeadBoxAvatarComponent = deadBoxActor.DeadBoxAvatarComponent_BP
                if slua.isValid(DeadBoxAvatarComponent) then
                    local currentBoxSkinId = 0
                    if PlayerCharacter.CurrentVehicle and _G.CurrentEquipVehicleID and _G.CurrentEquipVehicleID ~= 0 then
                        currentBoxSkinId = tonumber(tostring(_G.CurrentEquipVehicleID) .. "1") or 0
                    else
                        local currentWeapon = PlayerCharacter:GetCurrentWeapon()
                        if slua.isValid(currentWeapon) and currentWeapon.synData then
                            local weaponSkinData = currentWeapon.synData:Get(7)
                            if weaponSkinData and weaponSkinData.defineID then
                                currentBoxSkinId = weaponSkinData.defineID.TypeSpecificID
                            end
                        end
                    end
                    
                    if currentBoxSkinId ~= 0 then
                        pcall(function()
                            DeadBoxAvatarComponent:ResetItemAvatar()
                            DeadBoxAvatarComponent:PreChangeItemAvatar(currentBoxSkinId)
                            DeadBoxAvatarComponent:SyncChangeItemAvatar(currentBoxSkinId)
                        end)
                    end
                    deadBoxActor.bIsTDSkinApplied = true
                end
            end
        end
    end
end

-- ========================================== 
-- VIP NATIVE MENU SYSTEM (RUNS DIRECTLY FROM GAME SETTINGS)
-- ========================================== 

function _G.InitModMenuTab()
    if _G.ModMenuInitialized then return end
    _G.ModMenuInitialized = true

    _G.AHMADState.CustomTextData = _G.AHMADState.CustomTextData or {
        OuterSpeed = 5.6, InnerSpeed = 5.6, OuterRecoil = 0, HRecoil = 0.3, VRecoil = 0.3, IpadViewFOV = 120,
        -- Skin
        SkinSuit = 0, SkinBag = 0, SkinHelmet = 0,
        SkinM416 = 0, SkinAKM = 0, SkinSCAR = 0, SkinM762 = 0, SkinAUG = 0, SkinHoney =0, SkinQBZ = 0, SkinASM = 2, SkinACE32 = 0, SkinUMP = 6,
        SkinUZI = 0, SkinVector = 0, SkinGroza = 0, SkinKar98K = 0, SkinAWM = 2, SkinAMR = 0, SkinS12K = 0, SkinDBS = 0,
        SkinDacia = 0, SkinUAZ = 0, SkinCoupe = 0, SkinBuggy = 0, SkinMirado = 0,
    }

    local LocUtil = _G.LocUtil
    if not LocUtil and package.loaded["client.common.LocUtil"] then
        LocUtil = require("client.common.LocUtil")
    end
    
    if LocUtil and not LocUtil._IsModMenuHooked then
        local old_get = LocUtil.GetLocalizeResStr
        LocUtil.GetLocalizeResStr = function(id)
            if type(id) == "string" and not tonumber(id) then
                return id
            end
            return old_get(id)
        end
        LocUtil._IsModMenuHooked = true
    end

    local SettingPageDefine = require("client.logic.NewSetting.SettingPageDefine")
    local SettingCatalog = require("client.logic.NewSetting.SettingCatalog")
    
    if not SettingPageDefine.ModMenu then
        local AliasMap = require("client.slua.umg.NewSetting.Item.AliasMap")
        
        -- ==================== ESP VISUAL ====================
        local StackESPVisual = {
            { Key = "ModMenu_ESP1", UI = AliasMap.Switcher, Text = "ESP (AUTO SETUP)", GetFunc = function() return _G.AHMADConfig.EspVip end, SetFunc = function(c,v) _G.AHMADConfig.EspVip = v return true end },
            { Key = "ModMenu_ESP7", UI = AliasMap.Switcher, Text = "ESP WARNING & COUNT", GetFunc = function() return _G.AHMADConfig.Esp7 end, SetFunc = function(c,v) _G.AHMADConfig.Esp7 = v return true end },
            { Key = "ModMenu_ESP2", UI = AliasMap.Switcher, Text = "ESP RANGE", GetFunc = function() return _G.AHMADConfig.EspDistance end, SetFunc = function(c,v) _G.AHMADConfig.EspDistance = v return true end },
            { Key = "ModMenu_ESP4", UI = AliasMap.Switcher, Text = "ESP MARK - 360 Radar", GetFunc = function() return _G.AHMADConfig.EspRadar end, SetFunc = function(c,v) _G.AHMADConfig.EspRadar = v return true end },
            { Key = "ModMenu_ESP5", UI = AliasMap.Switcher, Text = "ESP BOX FRAME", GetFunc = function() return _G.AHMADConfig.Esp5 end, SetFunc = function(c,v) _G.AHMADConfig.Esp5 = v return true end },
            { Key = "ModMenu_ESPAntenna", UI = AliasMap.Switcher, Text = "ESP LINE ANTENA", GetFunc = function() return _G.AHMADConfig.EspAntenna end, SetFunc = function(c,v) _G.AHMADConfig.EspAntenna = v return true end },
            { Key = "ModMenu_ESPName", UI = AliasMap.Switcher, Text = "ESP NAME TEST(VISIBLE)", GetFunc = function() return _G.AHMADConfig.EspName end, SetFunc = function(c,v) _G.AHMADConfig.EspName = v return true end },
            { Key = "ModMenu_ESPOutline_Ex", UI = AliasMap.TitleSwitcher, Text = "▶ ESP OUTLINE", ExpandIndex = 0, GetFunc = function() return _G.AHMADConfig.EspOutline end, SetFunc = function(c,v) _G.AHMADConfig.EspOutline = v return true end },
            { Key = "ModMenu_ESPOutline_Thickness", UI = AliasMap.Slider, Text = "   Outline Thickness (1% is perfect)", ExpandHandle = "ModMenu_ESPOutline_Ex", MinValue = 1, MaxValue = 20, min = 1, max = 20, GetFunc = function() return _G.AHMADConfig.OutlineThickness end, SetFunc = function(c,v) _G.AHMADConfig.OutlineThickness = v return true end }
        }

        -- ==================== AIMBOT ORIGINAL (Legacy, tanpa GodMode) ====================
        -- ==================== ESP V2 (VIP) ====================
        local StackESPV2 = {
            { Key = "ModMenu_ESP9_Ex", UI = AliasMap.TitleSwitcher, Text = "▶ ESP VIP (RedBox & Marker)", ExpandIndex = 0, GetFunc = function() return _G.AHMADConfig.EspV2 end, SetFunc = function(c,v) _G.AHMADConfig.EspV2 = v return true end },
            { Key = "ModMenu_ESP9_Count", UI = AliasMap.Switcher, Text = "   Show Player Count", ExpandHandle = "ModMenu_ESP9_Ex", GetFunc = function() return _G.AHMADConfig.Esp9_Count end, SetFunc = function(c,v) _G.AHMADConfig.Esp9_Count = v return true end },
            { Key = "ModMenu_ESP9_Name", UI = AliasMap.Switcher, Text = "   Show Player Name", ExpandHandle = "ModMenu_ESP9_Ex", GetFunc = function() return _G.AHMADConfig.Esp9_Name end, SetFunc = function(c,v) _G.AHMADConfig.Esp9_Name = v return true end },
            { Key = "ModMenu_ESP9_Dist", UI = AliasMap.Switcher, Text = "   Show Distance", ExpandHandle = "ModMenu_ESP9_Ex", GetFunc = function() return _G.AHMADConfig.Esp9_Distance end, SetFunc = function(c,v) _G.AHMADConfig.Esp9_Distance = v return true end },
            { Key = "ModMenu_ESP9_HP", UI = AliasMap.Switcher, Text = "   Show Health Bar", ExpandHandle = "ModMenu_ESP9_Ex", GetFunc = function() return _G.AHMADConfig.Esp9_HP end, SetFunc = function(c,v) _G.AHMADConfig.Esp9_HP = v return true end },
            { Key = "ModMenu_ESP9_Team", UI = AliasMap.Switcher, Text = "   Show Team Color Box", ExpandHandle = "ModMenu_ESP9_Ex", GetFunc = function() return _G.AHMADConfig.Esp9_Team end, SetFunc = function(c,v) _G.AHMADConfig.Esp9_Team = v return true end },
            { Key = "ModMenu_ESP9_Weapon", UI = AliasMap.Switcher, Text = "   Show Weapon Icon", ExpandHandle = "ModMenu_ESP9_Ex", GetFunc = function() return _G.AHMADConfig.Esp9_Weapon end, SetFunc = function(c,v) _G.AHMADConfig.Esp9_Weapon = v return true end },
            { Key = "ModMenu_ESP9_Line", UI = AliasMap.Switcher, Text = "   Show Snapline", ExpandHandle = "ModMenu_ESP9_Ex", GetFunc = function() return _G.AHMADConfig.Esp9_Line end, SetFunc = function(c,v) _G.AHMADConfig.Esp9_Line = v return true end },
            { Key = "ModMenu_ESP9_Skeleton", UI = AliasMap.Switcher, Text = "   Show Skeleton (may cause lag)", ExpandHandle = "ModMenu_ESP9_Ex", GetFunc = function() return _G.AHMADConfig.Esp9_Skeleton end, SetFunc = function(c,v) _G.AHMADConfig.Esp9_Skeleton = v return true end }
        }

        local StackAimbotOriginal = {
        }

        -- ==================== AIMBOT FORCE - CLEAN 4 BUTTON LAYOUT ====================
        -- 4 flat buttons jaise ESP: Aimbot / Ignore Knocked / Ignore Bots / Visibility Check
        -- Ek hi setting saari guns pe kaam karti hai (Hipfire + Scope + Shotgun + Sniper)
        local StackAimbotForce = {
            { Key = "ModMenu_AT_Enable", UI = AliasMap.Switcher, Text = "Aimbot", GetFunc = function() return _G.AHMADConfig.AimTouchEnable end, SetFunc = function(c,v) _G.AHMADConfig.AimTouchEnable = v return true end },
            { Key = "ModMenu_AT_IgKnock", UI = AliasMap.Switcher, Text = "Ignore Knocked", GetFunc = function() return _G.AHMADConfig.AimTouchIgKnock end, SetFunc = function(c,v) _G.AHMADConfig.AimTouchIgKnock = v return true end },
            { Key = "ModMenu_AT_IgBot", UI = AliasMap.Switcher, Text = "Ignore Bots", GetFunc = function() return _G.AHMADConfig.AimTouchIgBot end, SetFunc = function(c,v) _G.AHMADConfig.AimTouchIgBot = v return true end },
            { Key = "ModMenu_AT_Vis", UI = AliasMap.Switcher, Text = "Visibility Check", GetFunc = function() return _G.AHMADConfig.AimTouchVisCheck end, SetFunc = function(c,v) _G.AHMADConfig.AimTouchVisCheck = v return true end }
        }

        -- ==================== MAGIC BULLET - REMOVED ====================
        -- Magic Bullet system has been completely removed from this version
        local StackMagicBullet = {}

        -- ==================== COMBAT GRAPHIC (hanya God Mode dan graphics) ====================
        local StackCombatGraphic = {
            { Key = "ModMenu_Ipad_Ex", UI = AliasMap.TitleSwitcher, Text = "▶ iPad View (Tampilan iPad)", ExpandIndex = 0, GetFunc = function() return _G.AHMADConfig.IpadView end, SetFunc = function(c,v) _G.AHMADConfig.IpadView = v return true end },
            { Key = "ModMenu_Ipad_FOV", UI = AliasMap.Slider, Text = "   FOV Angle (Sudut Pandang)", ExpandHandle = "ModMenu_Ipad_Ex", MinValue = 1, MaxValue = 100, min = 1, max = 100, GetFunc = function() return (_G.AHMADState.CustomTextData.IpadViewFOV or 120) - 80 end, SetFunc = function(c,v) _G.AHMADState.CustomTextData.IpadViewFOV = 80 + v return true end },
            { Key = "ModMenu_165FPS", UI = AliasMap.Switcher, Text = "Unlock 165 FPS (If turning off, will take effect next match)", GetFunc = function() return _G.AHMADConfig.UnlockFPS end, SetFunc = function(c,v) _G.AHMADConfig.UnlockFPS = v; if v then _G.AHMADState.GraphicsUnlocked = false end return true end },
            { Key = "ModMenu_WallColor", UI = AliasMap.Switcher, Text = "Wallhack & Color (Green & Red)", GetFunc = function() return _G.AHMADConfig.wallhackng end, SetFunc = function(c,v) _G.AHMADConfig.wallhackng = v; _G.AHMADConfig.ColorBodyV2 = v return true end },
            { Key = "ModMenu_BlackSky", UI = AliasMap.Switcher, Text = "Black Sky (Langit Hitam)", GetFunc = function() return _G.AHMADConfig.BlackSky end, SetFunc = function(c,v) _G.AHMADConfig.BlackSky = v return true end },
            { Key = "ModMenu_RemoveFog", UI = AliasMap.Switcher, Text = "Remove Fog (Hilangkan Kabut - If turning off, will take effect next match)", GetFunc = function() return _G.AHMADConfig.RemoveFog end, SetFunc = function(c,v) _G.AHMADConfig.RemoveFog = v return true end },
        }

        -- ==================== SKIN MOD (BARU) ====================
        local StackSkinMod = {
            { Key = "ModMenu_Skin_Ex", UI = AliasMap.TitleSwitcher, Text = "▶ SKIN MOD MENU", ExpandIndex = 0, GetFunc = function() return _G.AHMADConfig.ModSkin end, SetFunc = function(c,v) _G.AHMADConfig.ModSkin = v return true end },
            { Key = "ModMenu_Skin_Suit", UI = AliasMap.Slider, Text = "   Outfit (1 to 87 custom)", ExpandHandle = "ModMenu_Skin_Ex", MinValue = 1, MaxValue = 80, GetFunc = function() return _G.AHMADState.CustomTextData.SkinSuit or 1 end, SetFunc = function(c,v) _G.AHMADState.CustomTextData.SkinSuit = v; if _G.OutfitSkins and _G.OutfitSkins.Suit[v] then _G.OutfitMap.Suit = _G.OutfitSkins.Suit[v] end return true end },
            { Key = "ModMenu_Skin_Bag", UI = AliasMap.Slider, Text = "   Bag (Backpack)", ExpandHandle = "ModMenu_Skin_Ex", MinValue = 1, MaxValue = 16, GetFunc = function() return _G.AHMADState.CustomTextData.SkinBag or 1 end, SetFunc = function(c,v) _G.AHMADState.CustomTextData.SkinBag = v; if _G.OutfitSkins and _G.OutfitSkins.Bag[v] then _G.OutfitMap.Bag = _G.OutfitSkins.Bag[v] end return true end },
            { Key = "ModMenu_Skin_Helmet", UI = AliasMap.Slider, Text = "   Helmet", ExpandHandle = "ModMenu_Skin_Ex", MinValue = 1, MaxValue = 12, GetFunc = function() return _G.AHMADState.CustomTextData.SkinHelmet or 1 end, SetFunc = function(c,v) _G.AHMADState.CustomTextData.SkinHelmet = v; if _G.OutfitSkins and _G.OutfitSkins.Helmet[v] then _G.OutfitMap.Helmet = _G.OutfitSkins.Helmet[v] end return true end },
            { Key = "ModMenu_Skin_M416", UI = AliasMap.Slider, Text = "   M416 Skin (1 to 10 custom)", ExpandHandle = "ModMenu_Skin_Ex", MinValue = 1, MaxValue = 9, GetFunc = function() return _G.AHMADState.CustomTextData.SkinM416 or 1 end, SetFunc = function(c,v) _G.AHMADState.CustomTextData.SkinM416 = v; if _G.skinIdMappings[101004] and _G.skinIdMappings[101004][v] then _G.WeaponSkinMap[101004] = _G.skinIdMappings[101004][v] end return true end },
            { Key = "ModMenu_Skin_AKM", UI = AliasMap.Slider, Text = "   AKM Skin (1 to 8 custom)", ExpandHandle = "ModMenu_Skin_Ex", MinValue = 1, MaxValue = 8, GetFunc = function() return _G.AHMADState.CustomTextData.SkinAKM or 1 end, SetFunc = function(c,v) _G.AHMADState.CustomTextData.SkinAKM = v; if _G.skinIdMappings[101001] and _G.skinIdMappings[101001][v] then _G.WeaponSkinMap[101001] = _G.skinIdMappings[101001][v] end return true end },
            { Key = "ModMenu_Skin_SCAR", UI = AliasMap.Slider, Text = "   SCAR-L Skin (1 to 8 custom)", ExpandHandle = "ModMenu_Skin_Ex", MinValue = 1, MaxValue = 8, GetFunc = function() return _G.AHMADState.CustomTextData.SkinSCAR or 1 end, SetFunc = function(c,v) _G.AHMADState.CustomTextData.SkinSCAR = v; if _G.skinIdMappings[101003] and _G.skinIdMappings[101003][v] then _G.WeaponSkinMap[101003] = _G.skinIdMappings[101003][v] end return true end },
            { Key = "ModMenu_Skin_M762", UI = AliasMap.Slider, Text = "   Beryl M762 Skin (1 to 9 custom)", ExpandHandle = "ModMenu_Skin_Ex", MinValue = 1, MaxValue = 8, GetFunc = function() return _G.AHMADState.CustomTextData.SkinM762 or 1 end, SetFunc = function(c,v) _G.AHMADState.CustomTextData.SkinM762 = v; if _G.skinIdMappings[101008] and _G.skinIdMappings[101008][v] then _G.WeaponSkinMap[101008] = _G.skinIdMappings[101008][v] end return true end },
            { Key = "ModMenu_Skin_AUG", UI = AliasMap.Slider, Text = "   AUG Skin", ExpandHandle = "ModMenu_Skin_Ex", MinValue = 1, MaxValue = 7, GetFunc = function() return _G.AHMADState.CustomTextData.SkinAUG or 1 end, SetFunc = function(c,v) _G.AHMADState.CustomTextData.SkinAUG = v; if _G.skinIdMappings[101006] and _G.skinIdMappings[101006][v] then _G.WeaponSkinMap[101006] = _G.skinIdMappings[101006][v] end return true end },
            { Key = "ModMenu_Skin_Honey", UI = AliasMap.Slider, Text = "   Honey Badger Skin", ExpandHandle = "ModMenu_Skin_Ex", MinValue = 1, MaxValue = 2, GetFunc = function() return _G.AHMADState.CustomTextData.SkinHoney or 1 end, SetFunc = function(c,v) _G.AHMADState.CustomTextData.SkinHoney = v; if _G.skinIdMappings[101012] and _G.skinIdMappings[101012][v] then _G.WeaponSkinMap[101012] = _G.skinIdMappings[101012][v] end return true end },
            { Key = "ModMenu_Skin_QBZ", UI = AliasMap.Slider, Text = "   QBZ Skin ( 1 to 3)", ExpandHandle = "ModMenu_Skin_Ex", MinValue = 1, MaxValue = 3, GetFunc = function() return _G.AHMADState.CustomTextData.SkinQBZ or 1 end, SetFunc = function(c,v) _G.AHMADState.CustomTextData.SkinQBZ = v; if _G.skinIdMappings[101007] and _G.skinIdMappings[101007][v] then _G.WeaponSkinMap[101007] = _G.skinIdMappings[101007][v] end return true end },
            { Key = "ModMenu_Skin_ASM", UI = AliasMap.Slider, Text = "   ASM Abakan Skin ( 1 to 2)", ExpandHandle = "ModMenu_Skin_Ex", MinValue = 1, MaxValue = 2, GetFunc = function() return _G.AHMADState.CustomTextData.SkinASM or 1 end, SetFunc = function(c,v) _G.AHMADState.CustomTextData.SkinASM = v; if _G.skinIdMappings[101101] and _G.skinIdMappings[101101][v] then _G.WeaponSkinMap[101101] = _G.skinIdMappings[101101][v] end return true end },
            { Key = "ModMenu_Skin_ACE32", UI = AliasMap.Slider, Text = "   ACE32 Skin ( 1 to 2)", ExpandHandle = "ModMenu_Skin_Ex", MinValue = 1, MaxValue = 2, GetFunc = function() return _G.AHMADState.CustomTextData.SkinACE32 or 1 end, SetFunc = function(c,v) _G.AHMADState.CustomTextData.SkinACE32 = v; if _G.skinIdMappings[101102] and _G.skinIdMappings[101102][v] then _G.WeaponSkinMap[101102] = _G.skinIdMappings[101102][v] end return true end },
            { Key = "ModMenu_Skin_UMP", UI = AliasMap.Slider, Text = "   UMP45 Skin (1 to 6 custom)", ExpandHandle = "ModMenu_Skin_Ex", MinValue = 1, MaxValue = 6, GetFunc = function() return _G.AHMADState.CustomTextData.SkinUMP or 1 end, SetFunc = function(c,v) _G.AHMADState.CustomTextData.SkinUMP = v; if _G.skinIdMappings[102002] and _G.skinIdMappings[102002][v] then _G.WeaponSkinMap[102002] = _G.skinIdMappings[102002][v] end return true end },
            { Key = "ModMenu_Skin_UZI", UI = AliasMap.Slider, Text = "   UZI Skin (1 to 2 custom)", ExpandHandle = "ModMenu_Skin_Ex", MinValue = 1, MaxValue = 2, GetFunc = function() return _G.AHMADState.CustomTextData.SkinUZI or 1 end, SetFunc = function(c,v) _G.AHMADState.CustomTextData.SkinUZI = v; if _G.skinIdMappings[102001] and _G.skinIdMappings[102001][v] then _G.WeaponSkinMap[102001] = _G.skinIdMappings[102001][v] end return true end },
            { Key = "ModMenu_Skin_Vector", UI = AliasMap.Slider, Text = "   Vector Skin (1 to 2 custom)", ExpandHandle = "ModMenu_Skin_Ex", MinValue = 1, MaxValue = 2, GetFunc = function() return _G.AHMADState.CustomTextData.SkinVector or 1 end, SetFunc = function(c,v) _G.AHMADState.CustomTextData.SkinVector = v; if _G.skinIdMappings[102003] and _G.skinIdMappings[102003][v] then _G.WeaponSkinMap[102003] = _G.skinIdMappings[102003][v] end return true end },
            { Key = "ModMenu_Skin_Groza", UI = AliasMap.Slider, Text = "   Groza Skin (1 to 2 custom)", ExpandHandle = "ModMenu_Skin_Ex", MinValue = 1, MaxValue = 2, GetFunc = function() return _G.AHMADState.CustomTextData.SkinGroza or 1 end, SetFunc = function(c,v) _G.AHMADState.CustomTextData.SkinGroza = v; if _G.skinIdMappings[101005] and _G.skinIdMappings[101005][v] then _G.WeaponSkinMap[101005] = _G.skinIdMappings[101005][v] end return true end },
            { Key = "ModMenu_Skin_Kar98K", UI = AliasMap.Slider, Text = "   Kar98K Skin (1 to 3 custom)", ExpandHandle = "ModMenu_Skin_Ex", MinValue = 1, MaxValue = 3, GetFunc = function() return _G.AHMADState.CustomTextData.SkinKar98K or 1 end, SetFunc = function(c,v) _G.AHMADState.CustomTextData.SkinKar98K = v; if _G.skinIdMappings[103001] and _G.skinIdMappings[103001][v] then _G.WeaponSkinMap[103001] = _G.skinIdMappings[103001][v] end return true end },
            { Key = "ModMenu_Skin_M24", UI = AliasMap.Slider, Text = "   M24 Skin (1 to 2 custom)", ExpandHandle = "ModMenu_Skin_Ex", MinValue = 1, MaxValue = 2, GetFunc = function() return _G.AHMADState.CustomTextData.SkinM24 or 1 end, SetFunc = function(c,v) _G.AHMADState.CustomTextData.SkinM24 = v; if _G.skinIdMappings[103002] and _G.skinIdMappings[103002][v] then _G.WeaponSkinMap[103002] = _G.skinIdMappings[103002][v] end return true end },
            { Key = "ModMenu_Skin_AWM", UI = AliasMap.Slider, Text = "   AWM Skin (1 to 4 custom)", ExpandHandle = "ModMenu_Skin_Ex", MinValue = 1, MaxValue = 4, GetFunc = function() return _G.AHMADState.CustomTextData.SkinAWM or 1 end, SetFunc = function(c,v) _G.AHMADState.CustomTextData.SkinAWM = v; if _G.skinIdMappings[103003] and _G.skinIdMappings[103003][v] then _G.WeaponSkinMap[103003] = _G.skinIdMappings[103003][v] end return true end },
            { Key = "ModMenu_Skin_AMR", UI = AliasMap.Slider, Text = "   AMR Skin (1 to 3 custom)", ExpandHandle = "ModMenu_Skin_Ex", MinValue = 1, MaxValue = 3, GetFunc = function() return _G.AHMADState.CustomTextData.SkinAMR or 1 end, SetFunc = function(c,v) _G.AHMADState.CustomTextData.SkinAMR = v; if _G.skinIdMappings[103012] and _G.skinIdMappings[103012][v] then _G.WeaponSkinMap[103012] = _G.skinIdMappings[103012][v] end return true end },
            { Key = "ModMenu_Skin_S12K", UI = AliasMap.Slider, Text = "   S12K Skin (1 to 2 custom)", ExpandHandle = "ModMenu_Skin_Ex", MinValue = 1, MaxValue = 2, GetFunc = function() return _G.AHMADState.CustomTextData.SkinS12K or 1 end, SetFunc = function(c,v) _G.AHMADState.CustomTextData.SkinS12K = v; if _G.skinIdMappings[104003] and _G.skinIdMappings[104003][v] then _G.WeaponSkinMap[104003] = _G.skinIdMappings[104003][v] end return true end },
            { Key = "ModMenu_Skin_DBS", UI = AliasMap.Slider, Text = "   DBS Skin (1 to 3 custom)", ExpandHandle = "ModMenu_Skin_Ex", MinValue = 1, MaxValue = 3, GetFunc = function() return _G.AHMADState.CustomTextData.SkinDBS or 1 end, SetFunc = function(c,v) _G.AHMADState.CustomTextData.SkinDBS = v; if _G.skinIdMappings[104004] and _G.skinIdMappings[104004][v] then _G.WeaponSkinMap[104004] = _G.skinIdMappings[104004][v] end return true end },
            { Key = "ModMenu_Skin_Dacia", UI = AliasMap.Slider, Text = "   Dacia (Car) Skin", ExpandHandle = "ModMenu_Skin_Ex", MinValue = 1, MaxValue = 90, GetFunc = function() return _G.AHMADState.CustomTextData.SkinDacia or 1 end, SetFunc = function(c,v) _G.AHMADState.CustomTextData.SkinDacia = v; if _G.VehicleSkins[1903001] and _G.VehicleSkins[1903001][v] then _G.VehicleSkinMap[1903001] = _G.VehicleSkins[1903001][v] end return true end },
            { Key = "ModMenu_Skin_UAZ", UI = AliasMap.Slider, Text = "   UAZ (Jeep) Skin", ExpandHandle = "ModMenu_Skin_Ex", MinValue = 1, MaxValue = 90, GetFunc = function() return _G.AHMADState.CustomTextData.SkinUAZ or 1 end, SetFunc = function(c,v) _G.AHMADState.CustomTextData.SkinUAZ = v; if _G.VehicleSkins[1908001] and _G.VehicleSkins[1908001][v] then _G.VehicleSkinMap[1908001] = _G.VehicleSkins[1908001][v] end return true end },
            { Key = "ModMenu_Skin_Coupe", UI = AliasMap.Slider, Text = "   Coupe RB (Sports) Skin", ExpandHandle = "ModMenu_Skin_Ex", MinValue = 1, MaxValue = 70, GetFunc = function() return _G.AHMADState.CustomTextData.SkinCoupe or 1 end, SetFunc = function(c,v) _G.AHMADState.CustomTextData.SkinCoupe = v; if _G.VehicleSkins[1961001] and _G.VehicleSkins[1961001][v] then _G.VehicleSkinMap[1961001] = _G.VehicleSkins[1961001][v] end return true end },
            { Key = "ModMenu_Skin_Buggy", UI = AliasMap.Slider, Text = "   Buggy Skin", ExpandHandle = "ModMenu_Skin_Ex", MinValue = 1, MaxValue = 50, GetFunc = function() return _G.AHMADState.CustomTextData.SkinBuggy or 1 end, SetFunc = function(c,v) _G.AHMADState.CustomTextData.SkinBuggy = v; if _G.VehicleSkins[1907001] and _G.VehicleSkins[1907001][v] then _G.VehicleSkinMap[1907001] = _G.VehicleSkins[1907001][v] end return true end },
            { Key = "ModMenu_Skin_Mirado", UI = AliasMap.Slider, Text = "   Mirado (Convertible) Skin", ExpandHandle = "ModMenu_Skin_Ex", MinValue = 1, MaxValue = 27, GetFunc = function() return _G.AHMADState.CustomTextData.SkinMirado or 1 end, SetFunc = function(c,v) _G.AHMADState.CustomTextData.SkinMirado = v; if _G.VehicleSkins[1915001] and _G.VehicleSkins[1915001][v] then _G.VehicleSkinMap[1915001] = _G.VehicleSkins[1915001][v] end return true end }
        }

        -- ==================== COLOR MOD (Warna untuk ESP dan Wallhack) ====================
        local StackColorMod = {
            { Key = "COLOR_Visible", UI = AliasMap.Switcher, Text = "Visible Color (ESP & WH)",
              SwitcherText = {"Red","White","Yellow","Green","Cyan","Blue","Purple"},
              SwitcherValue = {1,2,3,4,5,6,7},
              GetFunc = function() return _G.ColorConfig.VisibleColor end,
              SetFunc = function(_, v) _G.ColorConfig.VisibleColor = v; _G.SaveModSettings(); return true end },
            { Key = "COLOR_Invisible", UI = AliasMap.Switcher, Text = "Invisible Color (ESP & WH)",
              SwitcherText = {"Red","White","Yellow","Green","Cyan","Blue","Purple"},
              SwitcherValue = {1,2,3,4,5,6,7},
              GetFunc = function() return _G.ColorConfig.InvisibleColor end,
              SetFunc = function(_, v) _G.ColorConfig.InvisibleColor = v; _G.SaveModSettings(); return true end },
            { Key = "COLOR_Brightness", UI = AliasMap.Slider, Text = "Brightness (1-50)", Min = 1, Max = 50, Step = 1,
              GetFunc = function() return _G.ColorConfig.Brightness end,
              SetFunc = function(_, v) _G.ColorConfig.Brightness = v; _G.SaveModSettings(); return true end },
            { Key = "COLOR_Glow", UI = AliasMap.Slider, Text = "Glow Intensity (0-10) (WH)", Min = 0, Max = 10, Step = 0.5,
              GetFunc = function() return _G.ColorConfig.Glow end,
              SetFunc = function(_, v) _G.ColorConfig.Glow = v; _G.SaveModSettings(); return true end }
        }

        -- ==================== DEFINE MENU PAGE | UX_Official HIDDEN MENU ====================
        SettingPageDefine.ModMenu = {
            Key = "ModMenu",
            Text= "",
            UIKey = "Setting_Page_Privacy", 
            Category = {
                { Key = "Cat_SkinMod", Text= "SKIN CUSTOM", Stack = StackSkinMod },
                { Key = "Cat_Aimbot_Force", Text= "UR/ROOM-TOUCH AIM", Stack = StackAimbotForce },
                { Key = "Cat_ESP_Visual", Text= "ESP PLAYER", Stack = StackESPVisual },
                { Key = "Cat_ESP_V2", Text= "ESP V2 (VIP)", Stack = StackESPV2 },
                { Key = "Cat_Combat_Graphic", Text= "WALLHACK/FPS", Stack = StackCombatGraphic },
                { Key = "Cat_ColorMod", Text= "COLOR CUSTOM", Stack = StackColorMod }
            }
        }
        
        table.insert(SettingCatalog, SettingPageDefine.ModMenu)
    end

    local UIManager = _G.UIManager
    if UIManager and not UIManager._IsModMenuHooked then
        local old_ShowUI = UIManager.ShowUI
        UIManager.ShowUI = function(config, ...)
            local args = {...}
            local n = select('#', ...) 
            
            if config and config.keyName and (string.find(string.lower(config.keyName), "setting_main") or string.find(string.lower(config.keyName), "setting")) then
                local catalog = args[1]
                if type(catalog) == "table" then
                    local hasModMenu = false
                    for _, page in ipairs(catalog) do
                        if type(page) == "table" and page.Key == "ModMenu" then
                            hasModMenu = true
                            break
                        end
                    end
                    if not hasModMenu then
                        table.insert(catalog, SettingPageDefine.ModMenu)
                    end
                end
            end
            local table_unpack = table.unpack or unpack
            return old_ShowUI(config, table_unpack(args, 1, n))
        end
        UIManager._IsModMenuHooked = true
    end
end

local function ShowGTLMODVIPMenu() 
    if _G.AHMADMenuAlreadyShown then return end
    if _G.AHMADState.MenuStep ~= 0 then return end

    pcall(function()
        local Msg = require("client.slua.logic.common.logic_common_msg_box")
        if not Msg or not Msg.Show then return end

        local function Step_ScamAlert()
            Msg.Show(1, "UX_Official PAK", "DON'T PLAY LIKE A CHEATER \nAVOID FROM REPORT!!\n\nSEND FEEDBACK WhatsApp - +923709241014", function() local Web = require("client.slua.logic.url.logic_webview_sdk"); if Web and Web.OpenURL then Web:OpenURL("https://wa.me/923709241014") end end, function() end, "JOIN", "CLOSE")
            _G.AHMADState.MenuStep = 99
            _G.AHMADMenuAlreadyShown = true
        end

        local function Step_Welcome()
            Msg.Show(1, "UX_Official PAK", "ACTIVATION SUCCESSFUL!\n\nIF YOU WANT TO PLAY BETTER EXPERIENCE CHEAT THEN DM USERNAME.\nTHE REAL OWNER IS TELEGRAM @UX_Official",
            function() 
                _G.InitModMenuTab()
                Notify("VIP MOD MENU BY UX_Official to toggle features!")
                Step_ScamAlert()
            end, 
            function() end, "OK", "CLOSE")
        end

        _G.AHMADState.MenuStep = 1
        Step_Welcome() 
    end)
end

-- ========================================== 
-- LOGIC 165 FPS IPAD VIEW 
-- ========================================== 
local function InitializeGraphicsUnlock() 
    if isExpired then return end
    if _G.AHMADState.GraphicsUnlocked or currentTime > limitTime then return end

    pcall(function()
        local SettingCfg = require("client.logic.setting.setting_config")
        local GraphicSettingDB = require("client.slua.umg.NewSetting.GraphicsNew.GraphicSettingDB")
        if SettingCfg then
            if SettingCfg.TpViewValue then SettingCfg.TpViewValue.max = 160 end
            if SettingCfg.FpViewValue then SettingCfg.FpViewValue.max = 160 end
        end
        if GraphicSettingDB then
            if GraphicSettingDB.TpViewValue then GraphicSettingDB.TpViewValue.max = 160 end
        end
    end)

    pcall(function()
        local logic_setting_graphics = require("client.slua.logic.setting.logic_setting_graphics")
        local GSC_FPS = require("client.slua.umg.NewSetting.GraphicsNew.Comps.GSC_FPS")
        local GSC_FPSFT = require("client.slua.umg.NewSetting.GraphicsNew.Comps.GSC_FPSFT")
        local GraphicSettingDB = require("client.slua.umg.NewSetting.GraphicsNew.GraphicSettingDB")
        
        local KismetMathLibrary = import("KismetMathLibrary") or _G.KismetMathLibrary
        local FLinearColor = import("LinearColor") or _G.FLinearColor

        if logic_setting_graphics then
            local old_SetFPS = logic_setting_graphics.SetFPS
            function logic_setting_graphics.SetFPS(gameInstance, FPSLevel)
                if old_SetFPS then old_SetFPS(gameInstance, FPSLevel) end
                if FPSLevel == 8 then 
                    gameInstance:ExecuteCMD("t.MaxFPS", "165")
                    gameInstance:ExecuteCMD("r.FrameRateLimit", "165")
                end
            end
        end

        if GSC_FPS and GSC_FPS.__inner_impl then
            local fps_impl = GSC_FPS.__inner_impl
            function fps_impl:GetMaxFPSLevel() return 8, 8 end
            function fps_impl:InitRealSupportFPS()
                local RealSupportFPS = {}
                for i = 1, 8 do RealSupportFPS[i] = {true, true} end
                if GraphicSettingDB then GraphicSettingDB:UpdateUIData(GraphicSettingDB.RealSupportFPS, RealSupportFPS, false) end
                return RealSupportFPS
            end
            function fps_impl:UpdateSelectedFPSState(selectedLevel)
                if not slua.isValid(self.UIRoot) then return end
                for level = 2, 8 do
                    local name = "NodeFps" .. (({[2]=20,[3]=25,[4]=30,[5]=40,[6]=60,[7]=90,[8]=120})[level] or 120)
                    local widget = self.UIRoot[name]
                    if slua.isValid(widget) then
                        widget:SetIsEnabled(true) 
                        pcall(function() widget:SetRenderOpacity(1.0) end)
                        local switcher = self.UIRoot["WidgetSwitcher_" .. level]
                        if slua.isValid(switcher) then 
                            switcher:SetActiveWidgetIndex(level == selectedLevel and 0 or 1) 
                        end
                    end
                end
            end
        end

        if GSC_FPSFT and GSC_FPSFT.__inner_impl then
            local ft_impl = GSC_FPSFT.__inner_impl
            local NMinFPS, NStep = 90, 5
            local function clamp(value, min, max)
                if value < min then return min end
                if max < value then return max end
                return value
            end
            local function lerp(a, b, t) return a + (b - a) * t end
            local function _getColorByPercent(start, finish, percent)
                if not FLinearColor then return nil end
                return FLinearColor(lerp(start.R, finish.R, percent), lerp(start.G, finish.G, percent), lerp(start.B, finish.B, percent), lerp(start.A, finish.A, percent))
            end
            
            ft_impl.ShowOrHide = function(self)
                self:SelfHitTestInvisible()
                if self.InitFPSFTSwitch then self:InitFPSFTSwitch() end
            end

            ft_impl.InitFPSFTSwitch = function(self)
                local FPSFineTuneSwitch = GraphicSettingDB:GetUIData(GraphicSettingDB.FPSFineTuneSwitch)
                if self.UIRoot.Setting_Switch then self.UIRoot.Setting_Switch:SetSwitcherEnable2(FPSFineTuneSwitch, true) end
                if self.UIRoot.CanvasPanel_8 then self:SetWidgetVisible(self.UIRoot.CanvasPanel_8, FPSFineTuneSwitch) end
                if self.UIRoot.WidgetSwitcher_0 then self.UIRoot.WidgetSwitcher_0:SetActiveWidgetIndex(2) end
                if self.InitFPSFTValue165 then self:InitFPSFTValue165() end
            end

            ft_impl.InitFPSFTValue165 = function(self)
                local itemRoot = self.UIRoot
                local FPSFineTuneSwitch = GraphicSettingDB:GetUIData(GraphicSettingDB.FPSFineTuneSwitch)
                local FPSFineTuneNum = 165
                if FPSFineTuneSwitch then
                    FPSFineTuneNum = GraphicSettingDB:GetUIData(GraphicSettingDB.FPSFineTuneNum) or 165
                    itemRoot.Slider_screen3:SetLocked(false)
                    if FLinearColor then
                        itemRoot.ProgressBar_screen3:SetFillColorAndOpacity(FLinearColor(1.0, 1.0, 1.0, 1.0))
                        itemRoot.Slider_screen3:SetSliderHandleColor(FLinearColor(1.0, 1.0, 1.0, 1.0))
                    end
                else
                    itemRoot.Slider_screen3:SetLocked(true)
                    if FLinearColor then
                        itemRoot.ProgressBar_screen3:SetFillColorAndOpacity(FLinearColor(1.0, 0.625, 0.6, 1))
                        itemRoot.Slider_screen3:SetSliderHandleColor(FLinearColor(1.0, 0.625, 0.6, 1.0))
                    end
                end
                local FPSFineTunePer = (FPSFineTuneNum - NMinFPS) / (165 - NMinFPS)
                
                itemRoot.Veihclescreen3:SetText(tostring(FPSFineTuneNum))
                itemRoot.Slider_screen3:SetValue(FPSFineTunePer)
                itemRoot.ProgressBar_screen3:SetPercent(FPSFineTunePer)
                
                if FLinearColor then
                    local startColor = FLinearColor(1.0, 1.0, 1.0, 1.0)
                    local midColor = FLinearColor(1.0, 0.54, 0.11, 1.0)
                    local endColor = FLinearColor(1.0, 0.23, 0.15, 1.0)
                    local sliderColor = FPSFineTunePer < 0.4 and startColor or _getColorByPercent(midColor, endColor, (FPSFineTunePer - 0.4) / 0.6)
                    itemRoot.Slider_screen3:SetSliderHandleColor(sliderColor)
                end
            end

            ft_impl.OnFPSFTValueChange3 = function(self, FPSFineTuneNum)
                GraphicSettingDB:UpdateUIData(GraphicSettingDB.FPSFineTuneNum, FPSFineTuneNum)
                if self.InitFPSFTValue165 then self:InitFPSFTValue165() end
                if self:GetParentUI() then self:GetParentUI():SetDirty(true) end
                local gameInstance = GraphicSettingDB.GetGameInstance and GraphicSettingDB.GetGameInstance()
                if gameInstance then
                    gameInstance:ExecuteCMD("t.MaxFPS", tostring(FPSFineTuneNum))
                    gameInstance:ExecuteCMD("r.FrameRateLimit", tostring(FPSFineTuneNum))
                end
            end

            ft_impl.OnFPSFTSliderValueChange3 = function(self, value)
                if GraphicSettingDB:GetUIData(GraphicSettingDB.FPSFineTuneSwitch) and KismetMathLibrary then
                    local FPSFineTuneNum = KismetMathLibrary.FCeil(value * (165 - NMinFPS) / NStep) * NStep + NMinFPS
                    self:OnFPSFTValueChange3(clamp(FPSFineTuneNum, NMinFPS, 165))
                end
            end
            
            ft_impl.OnFPSFTAdd = ft_impl.OnFPSFTAdd3
            ft_impl.OnFPSFTMinus = ft_impl.OnFPSFTMinus3
            ft_impl.OnFPSFTAdd2 = ft_impl.OnFPSFTAdd3
            ft_impl.OnFPSFTMinus2 = ft_impl.OnFPSFTMinus3
            ft_impl.OnFPSFTSliderValueChange = ft_impl.OnFPSFTSliderValueChange3
            ft_impl.OnFPSFTSliderValueChange2 = ft_impl.OnFPSFTSliderValueChange3
        end
    end)
    _G.AHMADState.GraphicsUnlocked = true
    Notify("Graphics & FPS 165Hz Unlocked (Upgraded Version)")
end

-- ========================================== 
-- INITIALIZE THE ESP SYSTEM (BASED)
-- ========================================== 
local function InitializeNativeESP() 
    if _G.AHMADState.NativeESPReady then return end
    pcall(function() 
        local GamePlayTools = require("GameLua.Mod.BaseMod.Common.GamePlayTools") 
        local currentMarkCfg = GamePlayTools.GetCurrentConfig("ScreenMarkConfig") 
        local function ApplyCfg(cfg)
            if not cfg then return end 
            if cfg[1006] then 
                cfg[1006].bBindBlocked = true;
                cfg[1006].bBindOutScreen = true; 
                cfg[1006].MaxWidgetNum = 99
                cfg[1006].MaxShowDistance = 6000000; 
                cfg[1006].bScaleByDistance = false
                cfg[1006].BindSocketName = "root"; 
                cfg[1006].bUseLuaWorldSocketName = true
                cfg[1006].WorldPositionOffset = FVector(0, 0, -30) 
            end 
            cfg[8888] = { 
                UIPathName = "/Game/Mod/EvoBase/BluePrints/UIBP/QuickSign/QuickSign_TipHitEnemy_UIBP_New.QuickSign_TipHitEnemy_UIBP_New_C",
                MaxWidgetNum = 99, 
                MaxShowDistance = 6000000, 
                bBindOutScreen = true,
                bBindBlocked = true, 
                bIsBindingActor = true,
                BindSocketName = "head",
                bUseLuaWorldSocketName = true, 
                WorldPositionOffset = FVector(0, 0, 30),
                bNeedPreLoad = true,
                Priority = 2 
            } 
            cfg[9999] = { 
                UIPathName = "/Game/Mod/EvoBase/BluePrints/UIBP/QuickSign/QuickSign_TipHitEnemy_UIBP_New.QuickSign_TipHitEnemy_UIBP_New_C",
                MaxWidgetNum = 99, 
                MaxShowDistance = 6000000, 
                bBindOutScreen = true,
                bBindBlocked = true, 
                bIsBindingActor = true, 
                BindSocketName = "head",
                bUseLuaWorldSocketName = true, 
                WorldPositionOffset = FVector(0, 0, 50),
                bNeedPreLoad = true, 
                Priority = 2 
            } 
        end 
        ApplyCfg(currentMarkCfg) 
        for k, cfg in pairs(package.loaded) do 
            if type(k) == "string" and string.find(k, "ScreenMarkConfig") and type(cfg) == "table" then 
                ApplyCfg(cfg) 
            end 
        end 
    end)
    _G.AHMADState.NativeESPReady = true 
    Notify("Native ESP System Initialized") 
end

-- ========================================== 
-- LOCAL FUNCTIONS CHO LOGIC NEW ESP - OPTIMIZED
-- ========================================== 
local function GetAllSkeletalMeshes(enemy, markData)
    local curTime = os.clock()
    if markData and markData.CachedMeshes and markData.CachedMeshTime and (curTime - markData.CachedMeshTime) < 3.0 then
        local validMeshes = {}
        for _, cachedMesh in ipairs(markData.CachedMeshes) do
            if Valid(cachedMesh) then table.insert(validMeshes, cachedMesh) end
        end
        markData.CachedMeshes = validMeshes
        return validMeshes
    end

    local meshes = {}
    if Valid(enemy.Mesh) then table.insert(meshes, enemy.Mesh) end
    pcall(function()
        local SkeletalMeshClass = import("SkeletalMeshComponent")
        if SkeletalMeshClass and type(enemy.GetComponentsByClass) == "function" then
            local childs = enemy:GetComponentsByClass(SkeletalMeshClass)
            if childs then
                local count = type(childs.Num) == "function" and childs:Num() or #childs
                for i = 1, count do
                    local comp = type(childs.Get) == "function" and childs:Get(i-1) or childs[i]
                    if Valid(comp) and comp ~= enemy.Mesh then
                        table.insert(meshes, comp)
                    end
                end
            end
        end
    end)
    if markData then
        markData.CachedMeshes = meshes
        markData.CachedMeshTime = curTime
    end
    return meshes
end

-- ========================================== 
-- WALL-BOUND FUNCTION & ROOT RESTORE (menggunakan ColorConfig)
-- ==========================================
local function Undowallhackng(enemy, markData)
    pcall(function()
        if markData.WallhackApplied then
            local meshes = GetAllSkeletalMeshes(enemy, markData)
            for _, mesh in ipairs(meshes) do
                if Valid(mesh) then
                    pcall(function() if type(mesh.SetRenderCustomDepth) == "function" then mesh:SetRenderCustomDepth(false) end end)
                    for i = 0, 10 do 
                        local matInterface = mesh:GetMaterial(i)
                        if Valid(matInterface) then
                            local baseMat = matInterface:GetBaseMaterial()
                            if Valid(baseMat) then baseMat.bDisableDepthTest = false end
                        end
                    end
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
            if Valid(mesh) then 
                pcall(function()
                    if type(mesh.SetRenderCustomDepth) == "function" then
                        mesh:SetRenderCustomDepth(true)
                    end
                    if type(mesh.SetCustomDepthStencilValue) == "function" then
                        mesh:SetCustomDepthStencilValue(252) 
                    end
                end)
                for i = 0, 10 do 
                    local matInterface = mesh:GetMaterial(i)
                    if not Valid(matInterface) then break end
                    local baseMat = matInterface:GetBaseMaterial()
                    if Valid(baseMat) then
                        baseMat.bDisableDepthTest = true
                        baseMat.BlendMode = 2 
                    end
                end
            end
        end
    end)
end

-- ========================================== 
-- WALLHACK WITH COLOR FROM COLORCONFIG
-- ==========================================
local function ApplyColorBodyV2(enemy, pc, markData)
    pcall(function()
        local meshes = GetAllSkeletalMeshes(enemy, markData)
        if #meshes == 0 then return end
        
        local curTime = os.clock()
        if markData.LastVisCheckTime == nil or (curTime - markData.LastVisCheckTime) > 0.3 then
            markData.LastVisCheckTime = curTime
            local isHidden = true
            pcall(function()
                if Valid(pc) and type(pc.LineOfSightTo) == "function" then
                    if pc:LineOfSightTo(enemy) then isHidden = false else isHidden = true end
                end
            end)
            markData.CachedHiddenState = isHidden
        end
        
        local hidden = markData.CachedHiddenState
        if hidden == nil then hidden = true end
        
        -- Ambil warna dari ColorConfig
        local visibleColor = GetAppliedColor(_G.ColorConfig.VisibleColor or 4, _G.ColorConfig.Brightness)
        local invisibleColor = GetAppliedColor(_G.ColorConfig.InvisibleColor or 1, _G.ColorConfig.Brightness)
        local finalColor = hidden and invisibleColor or visibleColor
        
        local colorHash = string.format("%d_%d_%d_%d", finalColor.R, finalColor.G, finalColor.B, finalColor.A)
        local currentMeshCount = #meshes
        local isMeshChanged = (markData.LastMeshCount ~= currentMeshCount)
        
        if not isMeshChanged and markData.LastHiddenState == hidden and markData.LastColorHash == colorHash then return end
        
        if isMeshChanged and markData.MIDs then
            markData.MIDs = {}
        end

        markData.LastHiddenState = hidden
        markData.LastMeshCount = currentMeshCount
        markData.LastColorHash = colorHash
        markData.ColorApplied = true
        
        for meshIndex, mesh in ipairs(meshes) do
            if Valid(mesh) then
                pcall(function()
                    mesh.LDMaxDrawDistance = -99999
                    mesh.MaxDrawDistanceOffset = -99999
                    mesh.CachedMaxDrawDistance = -99999
                    mesh.UseScopeDistanceCulling = true
                    mesh.PrimitiveShadingStrategy = 1
                    mesh.ShadingRate = 6
                end)
                for i = 0, 10 do
                    local matInterface = mesh:GetMaterial(i)
                    if not Valid(matInterface) then break end
                    local baseMat = matInterface:GetBaseMaterial()
                    if Valid(baseMat) then
                        local matName = tostring(baseMat)
                        if string.find(matName, "Master_Mask", 1, true) then
                            if not markData.MIDs then markData.MIDs = {} end
                            
                            local meshKey = "Mesh_" .. tostring(meshIndex)
                            
                            if not markData.MIDs[meshKey] then markData.MIDs[meshKey] = {} end
                            local mid = markData.MIDs[meshKey][i]
                            if not Valid(mid) then
                                mid = mesh:CreateAndSetMaterialInstanceDynamic(i)
                                markData.MIDs[meshKey][i] = mid
                            end
                            if Valid(mid) then
                                mid:SetVectorParameterValue("颜色", finalColor)
                                mid:SetVectorParameterValue("Extra Light Color", finalColor)
                                mid:SetVectorParameterValue("Para_Color", finalColor)
                                mid:SetVectorParameterValue("Para_ColorTint", finalColor)
                                mid:SetVectorParameterValue("Para_Color_1", finalColor)
                                mid:SetVectorParameterValue("Tint", finalColor)
                                mid:SetVectorParameterValue("Color", finalColor)
                                mid:SetVectorParameterValue("BaseColor", finalColor)
                                mid:SetVectorParameterValue("BodyColor", finalColor)
                                mid:SetVectorParameterValue("MainColor", finalColor)
                                mid:SetVectorParameterValue("DiffuseColor", finalColor)
                                mid:SetVectorParameterValue("EmissiveColor", finalColor)
                                mid:SetVectorParameterValue("ParaScaleOffset", SCALE_COLOR_V2)
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
                if Valid(mesh) then
                    pcall(function()
                        mesh.PrimitiveShadingStrategy = 0
                        mesh.ShadingRate = 1
                    end)
                    local meshKey = "Mesh_" .. tostring(meshIndex)
                    if markData.MIDs and markData.MIDs[meshKey] then
                        for i, mid in pairs(markData.MIDs[meshKey]) do
                            if Valid(mid) then
                                local defC = {R=1, G=1, B=1, A=1}
                                mid:SetVectorParameterValue("颜色", defC)
                                mid:SetVectorParameterValue("Extra Light Color", defC)
                                mid:SetVectorParameterValue("Para_Color", defC)
                                mid:SetVectorParameterValue("Para_ColorTint", defC)
                                mid:SetVectorParameterValue("Para_Color_1", defC)
                                mid:SetVectorParameterValue("Tint", defC)
                                mid:SetVectorParameterValue("Color", defC)
                                mid:SetVectorParameterValue("BaseColor", defC)
                                mid:SetVectorParameterValue("BodyColor", defC)
                                mid:SetVectorParameterValue("MainColor", defC)
                                mid:SetVectorParameterValue("DiffuseColor", defC)
                                mid:SetVectorParameterValue("EmissiveColor", defC)
                            end
                        end
                    end
                end
            end
            markData.ColorApplied = false
            markData.LastColorHash = ""
            markData.LastHiddenState = nil
        end
    end)
end

-- ========================================== 
-- AIMBOT V2 SYSTEM WITH NEW INTEGRATED TECHNOLOGY (KISSMET SMOOTH UPDATE)
-- ========================================== 
_G.GetEnemyTargetsFromActors = function(radius)
    local result = {}
    local player = GameplayData.GetPlayerCharacter()

    if not slua.isValid(player) then
        return result
    end

    local allCharacters = {}
    if GameplayData.GetAllPlayerCharacters then
        allCharacters = GameplayData.GetAllPlayerCharacters()
    elseif GameplayData.GameCharacters then
        for _, char in pairs(GameplayData.GameCharacters) do table.insert(allCharacters, char) end
    end

    local myTeam = player:GetTeamID()

    for _, actor in pairs(allCharacters) do
        if slua.isValid(actor) and actor ~= player and actor.GetTeamID and actor:IsAlive() then
            if actor:GetTeamID() ~= myTeam then
                local dist = player:GetDistanceTo(actor)
                if dist <= radius then
                    table.insert(result, actor)
                end
            end
        end
    end
    return result
end

_G.AimTouch = function()
    pcall(function()
        if not _G.AHMADConfig.AimTouchEnable then return end
        
        local player = GameplayData.GetPlayerCharacter()
        if not slua.isValid(player) then return end
        
        local pc = player:GetPlayerControllerSafety()
        if not slua.isValid(pc) then return end
        
        local isFiring = player.bIsWeaponFiring
        local isADS = player.bIsGunADS
        
        local weapon = player.WeaponManagerComponent and player.WeaponManagerComponent.CurrentWeaponReplicated
        if not weapon and type(player.GetCurrentShootWeapon) == "function" then
            weapon = player:GetCurrentShootWeapon()
        end
        
        local isShotgun = false
        local isSniper = false
        local currentAmmo = 1
        
        if slua.isValid(weapon) then
            local wID = type(weapon.GetWeaponID) == "function" and weapon:GetWeaponID() or 0
            local wName = type(weapon.GetWeaponName) == "function" and weapon:GetWeaponName() or ""
            
            if (wID >= 1030000 and wID < 1040000) or wName:find("S686") or wName:find("S1897") or wName:find("S12") or wName:find("DBS") or wName:find("M1014") then 
                isShotgun = true 
            end
            
            if wName:find("Kar98") or wName:find("M24") or wName:find("AWM") or wName:find("Mosin") or wName:find("Win94") or wName:find("AMR") or wName:find("SKS") or wName:find("SLR") or wName:find("Mini") or wName:find("Mk14") or wName:find("QBU") or wName:find("Mk12") or wName:find("VSS") then
                isSniper = true
            end
            
            if type(weapon.GetCurrentAmmo) == "function" then
                currentAmmo = weapon:GetCurrentAmmo()
            elseif weapon.ShootWeaponComponent and type(weapon.ShootWeaponComponent.GetCurrentAmmo) == "function" then
                currentAmmo = weapon.ShootWeaponComponent:GetCurrentAmmo()
            elseif weapon.CurrentAmmo ~= nil then
                currentAmmo = weapon.CurrentAmmo
            end
        end

        if _G.AHMADState.IsAutoFiring then
            pcall(function()
                player.bIsWeaponFiring = false
                if type(player.SetIsWeaponFiring) == "function" then player:SetIsWeaponFiring(false) end
                if slua.isValid(pc) and type(pc.SetIsWeaponFiring) == "function" then pc:SetIsWeaponFiring(false) end
                local wepMgr = player.WeaponManagerComponent
                if slua.isValid(wepMgr) then wepMgr.bIsWeaponFiring = false end
            end)
            _G.AHMADState.IsAutoFiring = false
        end

        if isShotgun and currentAmmo <= 0 then
            return
        end

        local cond = 2
        local prioMode = 1
        local boneIdx = 1
        local speedVal = 50
        local fovVal = 30
        local maxDistMeters = 50
        local useVisCheck = false
        local igKnock = false
        local igBot = false
        
        local predVal = 0 
        local recoilCompVal = 0 

        -- ==================== UNIFIED AIMBOT LOGIC - WORKS ON ALL GUNS ====================
        -- Ek hi setting saari guns pe (Hipfire + Scope + Shotgun + Sniper)
        -- 4 flat buttons se control: Aimbot / Ignore Knocked / Ignore Bots / Visibility Check
        -- Baaki values (bone, speed, fov, dist) safe-mode presets se auto set hoti hain per gun type

        -- Shared toggles (saari guns ke liye same)
        useVisCheck = _G.AHMADConfig.AimTouchVisCheck
        igKnock = _G.AHMADConfig.AimTouchIgKnock
        igBot = _G.AHMADConfig.AimTouchIgBot

        if isShotgun then
            cond = 2                 -- shotgun auto-fire condition
            prioMode = 1
            boneIdx = 2              -- spine (body shot)
            speedVal = 90            -- medium-plus (level 3-4, balanced)
            fovVal = 32
            maxDistMeters = 30
        elseif isADS then
            if isSniper then
                cond = 2
                if cond == 1 and not isFiring then return end
                prioMode = 1
                boneIdx = 1          -- head
                speedVal = 85        -- medium-plus (level 3-4, balanced)
                fovVal = 28
                maxDistMeters = 400
                predVal = 0
            else
                cond = 1
                if cond == 1 and not isFiring then return end
                prioMode = 1
                boneIdx = 2          -- spine
                speedVal = 85        -- medium-plus (level 3-4, balanced)
                fovVal = 28
                maxDistMeters = 300
                predVal = 0
                recoilCompVal = 0
            end
        else
            cond = 1
            if cond == 1 and not isFiring then return end
            prioMode = 1
            boneIdx = 1              -- head
            speedVal = 85            -- medium-plus (level 3-4, balanced)
            fovVal = 28
            maxDistMeters = 250
        end

        local currentMaxDist = maxDistMeters * 100 

        local enemies = _G.GetEnemyTargetsFromActors(currentMaxDist)
        if not enemies or #enemies == 0 then return end
        
        local FVector2D = import("Vector2D")
        local UGameplayStatics = import("GameplayStatics")
        local KismetMathLibrary = import("KismetMathLibrary")
        
        local camManager = UGameplayStatics.GetPlayerCameraManager(pc, 0)
        if not slua.isValid(camManager) then return end
        
        local camLoc = camManager:GetCameraLocation()
        if not camLoc then return end
        
        local ui_util = require("client.common.ui_util")
        if not ui_util then return end
        
        local viewportSize = ui_util.GetViewportSize()
        if not viewportSize then return end
        
        local centerX = viewportSize.X * 0.5
        local centerY = viewportSize.Y * 0.5
        
        local FOV_RADIUS = (fovVal / 100.0) * (viewportSize.X / 2.0)
        
        local bestTarget = nil
        local bestScore = 99999999 
        
        local selBoneName = "head"
        if boneIdx == 1 then selBoneName = "head"
        elseif boneIdx == 2 then selBoneName = "spine_03"
        elseif boneIdx == 3 then selBoneName = "spine_01"
        elseif boneIdx == 4 then selBoneName = "pelvis" end

        for i, target in ipairs(enemies) do
            if not slua.isValid(target) then goto continue end
            
            pcall(function()
                if slua.isValid(target.Mesh) then
                    target.Mesh.MeshComponentUpdateFlag = 0
                end
            end)
            
            if igKnock and target.HealthStatus == 1 then goto continue end
            
            if igBot then
                -- Shared bot cache use karo (counter jaisa) - fast + consistent
                local tId = type(target.GetUniqueID) == "function" and target:GetUniqueID() or tostring(target)
                _G.BotStatusCache = _G.BotStatusCache or {}
                local cachedBot = _G.BotStatusCache[tId]
                if cachedBot == nil then
                    cachedBot = false
                    -- Method 1: direct AI flags
                    if target.bIsAI == true or target.IsAI == true or target.bIsAi == true then cachedBot = true end
                    -- Method 2: PUBGM AIData / AIController component (sabse reliable)
                    if not cachedBot then
                        if target.AIData ~= nil or target.AIController ~= nil or target.bIsAIActor == true then cachedBot = true end
                        if not cachedBot and target.PlayerAIType ~= nil and target.PlayerAIType ~= 0 then cachedBot = true end
                        if not cachedBot and type(target.IsAICharacter) == "function" then
                            local ok, r = pcall(function() return target:IsAICharacter() end)
                            if ok and r then cachedBot = true end
                        end
                        if not cachedBot and type(target.GetIsAI) == "function" then
                            local ok, r = pcall(function() return target:GetIsAI() end)
                            if ok and r then cachedBot = true end
                        end
                    end
                    -- Method 3: PlayerState flags + missing UID
                    if not cachedBot then
                        local pState = target.PlayerState
                        if slua.isValid(pState) then
                            if pState.bIsABot or pState.bIsBot or pState.IsBot or pState.bIsAI or pState.bIsRobot or pState.bIsAiPlayer then cachedBot = true end
                            if not cachedBot and pState.PlayerAIType ~= nil and pState.PlayerAIType ~= 0 then cachedBot = true end
                            if not cachedBot and type(pState.IsABot) == "function" then
                                local ok, r = pcall(function() return pState:IsABot() end)
                                if ok and r then cachedBot = true end
                            end
                            if not cachedBot then
                                local uid = pState.Uid or pState.UID or pState.PlayerId or pState.PlayerID
                                if uid ~= nil and (uid == 0 or uid == "0") then cachedBot = true end
                            end
                        end
                    end
                    -- Method 4: function checks
                    if not cachedBot and type(target.IsBot) == "function" then
                        local ok, r = pcall(function() return target:IsBot() end)
                        if ok and r then cachedBot = true end
                    end
                    -- Method 5: AI controller check
                    if not cachedBot and type(target.GetController) == "function" then
                        local ok, ctrl = pcall(function() return target:GetController() end)
                        if ok and slua.isValid(ctrl) and (ctrl.bIsAI == true or ctrl.IsAI == true or ctrl.AIData ~= nil) then cachedBot = true end
                    end
                    _G.BotStatusCache[tId] = cachedBot
                end
                if cachedBot then goto continue end
            end
            
            if useVisCheck then
                local curTime = os.clock()
                local tId = type(target.GetUniqueID) == "function" and target:GetUniqueID() or tostring(target)
                _G.AimTouchVisCache = _G.AimTouchVisCache or {}
                if not _G.AimTouchVisCache[tId] or (curTime - _G.AimTouchVisCache[tId].time) > 0.2 then
                    local isHidden = true
                    pcall(function() if pc:LineOfSightTo(target) then isHidden = false end end)
                    _G.AimTouchVisCache[tId] = { hidden = isHidden, time = curTime }
                end
                if _G.AimTouchVisCache[tId].hidden then goto continue end
            end
            
            local tPos = target:GetBonePos(selBoneName, {X=0, Y=0, Z=0})
            if not tPos or (tPos.X == 0 and tPos.Y == 0 and tPos.Z == 0) then
                if type(target.GetSocketLocation) == "function" then
                    tPos = target:GetSocketLocation(selBoneName)
                end
            end
            if not tPos or (tPos.X == 0 and tPos.Y == 0 and tPos.Z == 0) then
                if type(target.K2_GetActorLocation) == "function" then
                    tPos = target:K2_GetActorLocation()
                    if tPos then
                        if boneIdx == 1 then tPos.Z = tPos.Z + 70
                        elseif boneIdx == 2 then tPos.Z = tPos.Z + 40
                        elseif boneIdx == 3 then tPos.Z = tPos.Z + 20 end
                    end
                end
            end
            if not tPos or (tPos.X == 0 and tPos.Y == 0 and tPos.Z == 0) then goto continue end
            
            local screen = FVector2D()
            local success = pc:ProjectWorldLocationToScreen(tPos, screen, false)
            if not success or screen.X <= 0 or screen.Y <= 0 then goto continue end
            
            local dx = screen.X - centerX
            local dy = screen.Y - centerY
            local distScreen = math.sqrt(dx*dx + dy*dy)
            
            if distScreen > FOV_RADIUS then goto continue end
            
            local currentScore = distScreen
            if prioMode == 2 then currentScore = player:GetDistanceTo(target)
            elseif prioMode == 3 then currentScore = target.Health or 100
            elseif prioMode == 4 then 
                local hp = target.Health or 100
                local maxhp = target.HealthMax or 100
                if maxhp <= 0 then maxhp = 100 end
                currentScore = hp / maxhp
            end
            
            if currentScore < bestScore then
                bestScore = currentScore
                bestTarget = target
            end
            
            ::continue::
        end
        
        if not slua.isValid(bestTarget) then return end
        
        local finalBonePos = bestTarget:GetBonePos(selBoneName, {X=0, Y=0, Z=0})
        if not finalBonePos or (finalBonePos.X == 0 and finalBonePos.Y == 0 and finalBonePos.Z == 0) then
            if type(bestTarget.GetSocketLocation) == "function" then
                finalBonePos = bestTarget:GetSocketLocation(selBoneName)
            end
        end
        if not finalBonePos or (finalBonePos.X == 0 and finalBonePos.Y == 0 and finalBonePos.Z == 0) then
            if type(bestTarget.K2_GetActorLocation) == "function" then
                finalBonePos = bestTarget:K2_GetActorLocation()
                if finalBonePos then
                    if boneIdx == 1 then finalBonePos.Z = finalBonePos.Z + 70
                    elseif boneIdx == 2 then finalBonePos.Z = finalBonePos.Z + 40
                    elseif boneIdx == 3 then finalBonePos.Z = finalBonePos.Z + 20 end
                end
            end
        end
        if not finalBonePos or (finalBonePos.X == 0 and finalBonePos.Y == 0 and finalBonePos.Z == 0) then return end
        
        if predVal > 0 then
            pcall(function()
                local tVelocity = nil
                if type(bestTarget.GetVelocity) == "function" then
                    tVelocity = bestTarget:GetVelocity()
                end
                
                if tVelocity and (tVelocity.X ~= 0 or tVelocity.Y ~= 0) then
                    local distToEnemy = player:GetDistanceTo(bestTarget) / 100.0
                    local ToF = (distToEnemy / 800.0) * (predVal / 50.0) 
                    finalBonePos.X = finalBonePos.X + (tVelocity.X * ToF)
                    finalBonePos.Y = finalBonePos.Y + (tVelocity.Y * ToF)
                end
            end)
        end

        local rot = KismetMathLibrary.FindLookAtRotation(camLoc, finalBonePos)
        if not rot then return end
        
        local currentRot = pc:GetControlRotation()
        if not currentRot then return end
        
        local deltaYaw = rot.Yaw - currentRot.Yaw
        local deltaPitch = rot.Pitch - currentRot.Pitch
        
        if isADS then
            local camRot = nil
            if type(camManager.GetCameraRotation) == "function" then
                camRot = camManager:GetCameraRotation()
            end
            if camRot then
                deltaYaw = deltaYaw - (camRot.Yaw - currentRot.Yaw)
                deltaPitch = deltaPitch - (camRot.Pitch - currentRot.Pitch)
            end
        end

        if deltaYaw > 180 then deltaYaw = deltaYaw - 360 end
        if deltaYaw < -180 then deltaYaw = deltaYaw + 360 end
        if deltaPitch > 180 then deltaPitch = deltaPitch - 360 end
        if deltaPitch < -180 then deltaPitch = deltaPitch + 360 end
        
        local smoothFactor = 0.0
        if speedVal >= 100 then
            smoothFactor = 1.0
        else
            smoothFactor = (speedVal / 100.0) * 0.3
            if smoothFactor < 0.01 then smoothFactor = 0.01 end
        end
        
        local finalPitch = currentRot.Pitch + (deltaPitch * smoothFactor)
        local finalYaw = currentRot.Yaw + (deltaYaw * smoothFactor)
        
        if recoilCompVal > 0 and isFiring then
            local pullDownForce = (recoilCompVal / 50.0) * 1.5
            finalPitch = finalPitch - pullDownForce
        end

        local finalRot = { Pitch = finalPitch, Yaw = finalYaw, Roll = 0 }
        pc:SetControlRotation(finalRot, "AimTouch")
        
        if isShotgun then
            pcall(function()
                local distToTarget = player:GetDistanceTo(bestTarget) / 100
                if distToTarget <= maxDistMeters then
                    player.bIsWeaponFiring = true
                    if type(player.SetIsWeaponFiring) == "function" then player:SetIsWeaponFiring(true) end
                    if slua.isValid(pc) and type(pc.SetIsWeaponFiring) == "function" then pc:SetIsWeaponFiring(true) end
                    local wepMgr = player.WeaponManagerComponent
                    if slua.isValid(wepMgr) then wepMgr.bIsWeaponFiring = true end
                    
                    local currentWep = player:GetCurrentWeapon()
                    if slua.isValid(currentWep) and type(currentWep.StartFire) == "function" then 
                        currentWep:StartFire() 
                    end
                    _G.AHMADState.IsAutoFiring = true
                end
            end)
        end

    end)
end

-- ========================================== 
-- MAIN LOOP: EXTREMELY POWERFUL OPTIMIZED
-- ========================================== 

-- ============================================================
-- ESP V2 CORE (ported from s.lua)
-- ============================================================
-- BẮT ĐẦU: LÕI ESP LOẠI 9 (TỪ CODE MẪU GỐC FULL LOGIC)
-- ============================================================
local PlayerMapMarker = {}

local RedBoxOverlay = {
    bActive = false,
    MainContainer = nil,
    WidgetSlot = nil,
    TextBlockPlayer = nil, -- Đã tách chữ
    TextBlockBot = nil,    -- Đã tách chữ
    Width = 260,           -- [ĐÃ LÀM TO HƠN] (Cũ 210 - Gốc 300)
    Height = 25,           -- [ĐÃ LÀM TO HƠN] (Cũ 20 - Gốc 28)
    OffsetY = 10,
    PlayerCount = 0,
    BotCount = 0,
    FontSize = 14,         -- [CHỮ TO HƠN] (Cũ 11 - Gốc 16)
    TextScaleValue = 1.0,  -- [TĂNG ĐỘ NÉT] (Cũ 0.8 - Gốc 1.1)
    NumLayers = 50,
    Red = 0.7,      -- Màu nền Tím Nhạt
    Green = 0.3,    -- Màu nền Tím Nhạt
    Blue = 1.0,     -- Màu nền Tím Nhạt
    LayerAlpha = 0.06, -- Tăng độ đậm nền một chút cho đẹp
    _CachedTextPlayer = "",
    _CachedTextBot = "",
    _CachedPosVec = nil
}

function RedBoxOverlay.Create()
    if RedBoxOverlay.MainContainer and slua.isValid(RedBoxOverlay.MainContainer) then return true end

    local ParentCanvas = PlayerMapMarker.ESPCanvas
    if not ParentCanvas or not slua.isValid(ParentCanvas) then 
        if not PlayerMapMarker.InitESPCanvas() then return false end
        ParentCanvas = PlayerMapMarker.ESPCanvas
    end

    if not ParentCanvas or not slua.isValid(ParentCanvas) then return false end

    local Container = nil
    pcall(function() Container = CGame:NewObjectFromPath("/Script/UMG.CanvasPanel", ParentCanvas) end)
    if not Container or not slua.isValid(Container) then return false end

    local FLinearColor = import("LinearColor") or FLinearColor
    local FVector2D = import("Vector2D") or FVector2D
    local color = FLinearColor(RedBoxOverlay.Red, RedBoxOverlay.Green, RedBoxOverlay.Blue, RedBoxOverlay.LayerAlpha)

    local numLayers = RedBoxOverlay.NumLayers
    local totalWidth = RedBoxOverlay.Width

    for i = 1, numLayers do
        local progress = (i / numLayers) ^ 1.15
        local layerWidth = progress * totalWidth
        local layerX = (totalWidth - layerWidth) / 2.0

        local border = nil
        pcall(function() border = CGame:NewObjectFromPath("/Script/UMG.Border", Container) end)

        if border and slua.isValid(border) then
            pcall(function()
                border:SetBrushColor(color)
                border:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
            end)

            local slot = Container:AddChildToCanvas(border)
            if slot then
                slot:SetPosition(FVector2D(layerX, 0))
                slot:SetSize(FVector2D(layerWidth, RedBoxOverlay.Height))
            end
        end
    end

    local FSlateColor = import("SlateColor") or import("/Script/SlateCore.SlateColor")
    
    -- Chữ Player (Màu Đỏ)
    local txtPlayer = nil
    pcall(function() txtPlayer = CGame:NewObjectFromPath("/Script/UMG.TextBlock", Container) end)
    if txtPlayer and slua.isValid(txtPlayer) then
        pcall(function()
            local strText = string.format("Player: %d", RedBoxOverlay.PlayerCount)
            txtPlayer:SetText(strText)
            RedBoxOverlay._CachedTextPlayer = strText

            local redLinear = FLinearColor(1.0, 0.0, 0.0, 1.0) -- ĐỎ
            if FSlateColor then txtPlayer:SetColorAndOpacity(FSlateColor(redLinear)) else txtPlayer:SetColorAndOpacity(redLinear) end

            if txtPlayer.Font then
                local font = txtPlayer.Font
                font.Size = RedBoxOverlay.FontSize
                txtPlayer.Font = font
            end
            txtPlayer:SetRenderScale(FVector2D(RedBoxOverlay.TextScaleValue, RedBoxOverlay.TextScaleValue))
            txtPlayer:SetRenderTransformPivot(FVector2D(0.5, 0.5))
            txtPlayer:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        end)
        local txtSlot1 = Container:AddChildToCanvas(txtPlayer)
        if txtSlot1 then
            pcall(function()
                txtSlot1:SetAutoSize(true)
                txtSlot1:SetAlignment(FVector2D(0.5, 0.5))
                txtSlot1:SetPosition(FVector2D(totalWidth * 0.35, RedBoxOverlay.Height * 0.5))
                txtSlot1:SetZOrder(1000)
            end)
        end
        RedBoxOverlay.TextBlockPlayer = txtPlayer
    end

    -- Chữ Bot (Màu Xanh Lá Cây)
    local txtBot = nil
    pcall(function() txtBot = CGame:NewObjectFromPath("/Script/UMG.TextBlock", Container) end)
    if txtBot and slua.isValid(txtBot) then
        pcall(function()
            local strText = string.format("Bot: %d", RedBoxOverlay.BotCount)
            txtBot:SetText(strText)
            RedBoxOverlay._CachedTextBot = strText

            local greenLinear = FLinearColor(0.0, 1.0, 0.0, 1.0) -- XANH LÁ CÂY
            if FSlateColor then txtBot:SetColorAndOpacity(FSlateColor(greenLinear)) else txtBot:SetColorAndOpacity(greenLinear) end

            if txtBot.Font then
                local font = txtBot.Font
                font.Size = RedBoxOverlay.FontSize
                txtBot.Font = font
            end
            txtBot:SetRenderScale(FVector2D(RedBoxOverlay.TextScaleValue, RedBoxOverlay.TextScaleValue))
            txtBot:SetRenderTransformPivot(FVector2D(0.5, 0.5))
            txtBot:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        end)
        local txtSlot2 = Container:AddChildToCanvas(txtBot)
        if txtSlot2 then
            pcall(function()
                txtSlot2:SetAutoSize(true)
                txtSlot2:SetAlignment(FVector2D(0.5, 0.5))
                txtSlot2:SetPosition(FVector2D(totalWidth * 0.65, RedBoxOverlay.Height * 0.5))
                txtSlot2:SetZOrder(1000)
            end)
        end
        RedBoxOverlay.TextBlockBot = txtBot
    end

    local MainSlot = nil
    pcall(function() MainSlot = ParentCanvas:AddChildToCanvas(Container) end)
    if not MainSlot then return false end

    RedBoxOverlay.MainContainer = Container
    RedBoxOverlay.WidgetSlot = MainSlot
    
    pcall(function()
        MainSlot:SetAutoSize(false)
        MainSlot:SetZOrder(999)
        MainSlot:SetAlignment(FVector2D(0.5, 0.0))
        MainSlot:SetSize(FVector2D(RedBoxOverlay.Width, RedBoxOverlay.Height))
    end)

    RedBoxOverlay.UpdatePosition()
    return true
end

function RedBoxOverlay.SetCounts(players, bots)
    if RedBoxOverlay.PlayerCount == players and RedBoxOverlay.BotCount == bots then return end
    RedBoxOverlay.PlayerCount = players or 0
    RedBoxOverlay.BotCount = bots or 0
    
    if RedBoxOverlay.TextBlockPlayer and slua.isValid(RedBoxOverlay.TextBlockPlayer) then
        pcall(function()
            local strP = string.format("Player: %d", RedBoxOverlay.PlayerCount)
            if RedBoxOverlay._CachedTextPlayer ~= strP then
                RedBoxOverlay.TextBlockPlayer:SetText(strP)
                RedBoxOverlay._CachedTextPlayer = strP
            end
        end)
    end
    if RedBoxOverlay.TextBlockBot and slua.isValid(RedBoxOverlay.TextBlockBot) then
        pcall(function()
            local strB = string.format("Bot: %d", RedBoxOverlay.BotCount)
            if RedBoxOverlay._CachedTextBot ~= strB then
                RedBoxOverlay.TextBlockBot:SetText(strB)
                RedBoxOverlay._CachedTextBot = strB
            end
        end)
    end
end

function RedBoxOverlay.UpdatePosition()
    local Slot = RedBoxOverlay.WidgetSlot
    if not Slot or not slua.isValid(Slot) then return end
    local PC = PlayerMapMarker.GetMyPlayerController()
    if not slua.isValid(PC) then return end

    local fromX, fromY = PlayerMapMarker.GetSnapLineStartPos(PC)
    local FVector2D = import("Vector2D") or FVector2D
    pcall(function()
        if not RedBoxOverlay._CachedPosVec then
            RedBoxOverlay._CachedPosVec = FVector2D(fromX, fromY)
        else
            RedBoxOverlay._CachedPosVec.X = fromX
            RedBoxOverlay._CachedPosVec.Y = fromY
        end
        Slot:SetPosition(RedBoxOverlay._CachedPosVec)
    end)
end

function RedBoxOverlay.Start()
    if RedBoxOverlay.bActive and RedBoxOverlay.MainContainer and slua.isValid(RedBoxOverlay.MainContainer) then return end
    if RedBoxOverlay.Create() then
        RedBoxOverlay.bActive = true
        pcall(function() RedBoxOverlay.MainContainer:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
    end
end

function RedBoxOverlay.Stop()
    RedBoxOverlay.bActive = false
    if RedBoxOverlay.MainContainer and slua.isValid(RedBoxOverlay.MainContainer) then
        pcall(function()
            RedBoxOverlay.MainContainer:RemoveFromParent()
            RedBoxOverlay.MainContainer:ConditionalBeginDestroy()
        end)
    end
    RedBoxOverlay.MainContainer = nil
    RedBoxOverlay.WidgetSlot = nil
    RedBoxOverlay.TextBlockPlayer = nil
    RedBoxOverlay.TextBlockBot = nil
    RedBoxOverlay._CachedPosVec = nil
end

function RedBoxOverlay.UpdatePosition()
    local Slot = RedBoxOverlay.WidgetSlot
    if not Slot or not slua.isValid(Slot) then return end
    local PC = PlayerMapMarker.GetMyPlayerController()
    if not slua.isValid(PC) then return end

    local fromX, fromY = PlayerMapMarker.GetSnapLineStartPos(PC)
    local FVector2D = import("Vector2D") or FVector2D
    pcall(function()
        if not RedBoxOverlay._CachedPosVec then
            RedBoxOverlay._CachedPosVec = FVector2D(fromX, fromY)
        else
            RedBoxOverlay._CachedPosVec.X = fromX
            RedBoxOverlay._CachedPosVec.Y = fromY
        end
        Slot:SetPosition(RedBoxOverlay._CachedPosVec)
    end)
end

function RedBoxOverlay.Start()
    if RedBoxOverlay.bActive and RedBoxOverlay.MainContainer and slua.isValid(RedBoxOverlay.MainContainer) then return end
    if RedBoxOverlay.Create() then
        RedBoxOverlay.bActive = true
        pcall(function() RedBoxOverlay.MainContainer:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
    end
end

function RedBoxOverlay.Stop()
    RedBoxOverlay.bActive = false
    if RedBoxOverlay.MainContainer and slua.isValid(RedBoxOverlay.MainContainer) then
        pcall(function()
            RedBoxOverlay.MainContainer:RemoveFromParent()
            RedBoxOverlay.MainContainer:ConditionalBeginDestroy()
        end)
    end
    RedBoxOverlay.MainContainer = nil
    RedBoxOverlay.WidgetSlot = nil
    RedBoxOverlay.TextBlock = nil
    RedBoxOverlay._CachedPosVec = nil
end

_G.RedBoxOverlay = RedBoxOverlay

local InGameMarkTools = nil
pcall(function() InGameMarkTools = require("GameLua.Mod.BaseMod.Common.InGameMarkTools") end)

local SlateBlueprintLibrary = nil
local WidgetLayoutLibrary = nil
local KismetMathLibrary = nil
local KismetSystemLibrary = nil

pcall(function() SlateBlueprintLibrary = import("SlateBlueprintLibrary") or import("/Script/UMG.SlateBlueprintLibrary") end)
pcall(function() WidgetLayoutLibrary = import("WidgetLayoutLibrary") or import("/Script/UMG.WidgetLayoutLibrary") end)
pcall(function() KismetMathLibrary = import("KismetMathLibrary") end)
pcall(function() KismetSystemLibrary = import("KismetSystemLibrary") end)

local FVector2D = _G.FVector2D or import("Vector2D")
local FLinearColor = _G.FLinearColor or import("LinearColor")
local FVector = _G.FVector or import("Vector")

PlayerMapMarker.MarkTypeID = 1007
PlayerMapMarker.bUseScreenESP = true
PlayerMapMarker.bUseScreenMark = false
PlayerMapMarker.bUseQuickSign = false
PlayerMapMarker.bUseNavigator = false
PlayerMapMarker.bUseWidgetComponent = false
PlayerMapMarker.QuickSignConfigKey = "C_MarkPos"

PlayerMapMarker.WidgetCompUIPath = "/Game/BluePrints/ControlInput/NewbieItem/NewbieTips_ConsumeTips.NewbieTips_ConsumeTips"
PlayerMapMarker.WidgetCompBoneName = "head"
PlayerMapMarker.WidgetCompOffset = FVector and FVector(0, 0, 80) or {X=0, Y=0, Z=80}
PlayerMapMarker.WidgetCompDrawSize = FVector2D and FVector2D(210, 35) or {X=210, Y=35} -- [SIZE 70%]

PlayerMapMarker.ESPBoneName = "head"
PlayerMapMarker.ESPWorldOffsetZ = 0
PlayerMapMarker.ESPScreenOffsetY = 0
PlayerMapMarker.ESPAnchorOffsetX = 35 -- [SIZE 70%]
PlayerMapMarker.ESPAnchorOffsetY = 0
PlayerMapMarker.ESPTextOffsetX = 0
PlayerMapMarker.ESPTextOffsetY = 0

PlayerMapMarker.ESPWidgetAlignment = FVector2D and FVector2D(0.5, 1.0) or {X=0.5, Y=1.0}
PlayerMapMarker.ESPWidgetSize = FVector2D and FVector2D(70, 21) or {X=70, Y=21} -- [SIZE 70%]
PlayerMapMarker.ESPWidgetAutoSize = true
PlayerMapMarker.ESPWidgetZOrder = 2

PlayerMapMarker.bShowDistance = true
PlayerMapMarker.DistanceUnit = "m"
PlayerMapMarker.WeaponIconBrushW = 96 -- [SIZE 70%] Gốc 138
PlayerMapMarker.WeaponIconBrushH = 48 -- [SIZE 70%] Gốc 69
PlayerMapMarker.HPWidgetSwitcherTypeIndex = 0
PlayerMapMarker.HPWidgetSwitcherType2Index = 0
PlayerMapMarker.bForceSwitcherIndexEveryUpdate = true

PlayerMapMarker.bUseSnapLines = true
PlayerMapMarker.SnapLineThickness = 1.0 -- [SIZE 70%] Gốc 1.5
PlayerMapMarker.SnapLineOriginY = 50
PlayerMapMarker.SnapLineOriginOffsetX = 0
PlayerMapMarker.SnapLineHeadOffsetX = 0
PlayerMapMarker.SnapLineHeadOffsetY = -14 -- [SIZE 70%] Gốc -20
PlayerMapMarker.SnapLineColor = FLinearColor and FLinearColor(0.6, 0.0, 0.0, 1.0) or {R=150, G=0, B=0, A=255} -- Đỏ Đậm
PlayerMapMarker.SnapLineOpacity = 0.7

-- ====== BẮT ĐẦU: CẤU HÌNH SKELETON (TỪ CODE MẪU) ======
PlayerMapMarker.bUseSkeleton = true                      -- Tùy chọn bật Skeleton
PlayerMapMarker.SkeletonThickness = 0.8                  -- [SIZE 70%] Gốc 1.2                  
PlayerMapMarker.SkeletonColor = nil                      
PlayerMapMarker.SkeletonOpacity = 0.8                    
PlayerMapMarker.SkeletonMaxDistance = 100000             
PlayerMapMarker.bUseVisibilityColor = true              
PlayerMapMarker.SkeletonVisibleColor = FLinearColor and FLinearColor(0.0, 1.0, 0.0, 0.8) or {R=0,G=255,B=0,A=200}
PlayerMapMarker.SkeletonCoverColor = FLinearColor and FLinearColor(0.9, 0.0, 0.0, 0.6) or {R=230,G=0,B=0,A=150}

PlayerMapMarker.SkeletonWidgets = {}
PlayerMapMarker._StaticBoneLocCache = {}

PlayerMapMarker.SkeletonChains = {
    {"neck_01", "lowerarm_r", "hand_r"},
    {"neck_01", "lowerarm_l", "hand_l"},
    {"head", "neck_01", "pelvis"},
    {"pelvis", "calf_r", "foot_r"},
    {"pelvis", "calf_l", "foot_l"}
}

PlayerMapMarker.BoneNameFallbacks = {
    ["head"] = {"head", "Head", "head_socket"},
    ["neck_01"] = {"neck_01", "Neck_01", "neck", "Neck"},
    ["clavicle_r"] = {"clavicle_r", "Clavicle_R", "clavicle_R"},
    ["upperarm_r"] = {"upperarm_r", "UpperArm_R", "arm_r", "arm_r_01"},
    ["lowerarm_r"] = {"lowerarm_r", "LowerArm_R", "forearm_r"},
    ["hand_r"] = {"hand_r", "Hand_R", "hand_r_socket"},
    ["clavicle_l"] = {"clavicle_l", "Clavicle_L", "clavicle_L"},
    ["upperarm_l"] = {"upperarm_l", "UpperArm_L", "arm_l", "arm_l_01"},
    ["lowerarm_l"] = {"lowerarm_l", "LowerArm_L", "forearm_l"},
    ["hand_l"] = {"hand_l", "Hand_L", "hand_l_socket"},
    ["spine_03"] = {"spine_03", "Spine_03", "spine_02", "spine"},
    ["spine_02"] = {"spine_02", "Spine_02", "spine_01"},
    ["pelvis"] = {"pelvis", "Pelvis", "hip"},
    ["thigh_r"] = {"thigh_r", "Thigh_R", "leg_r"},
    ["calf_r"] = {"calf_r", "Calf_R", "shin_r"},
    ["foot_r"] = {"foot_r", "Foot_R", "foot_r_socket"},
    ["thigh_l"] = {"thigh_l", "Thigh_L", "leg_l"},
    ["calf_l"] = {"calf_l", "Calf_L", "shin_l"},
    ["foot_l"] = {"foot_l", "Foot_L", "foot_l_socket"},
}
-- ====== KẾT THÚC: CẤU HÌNH SKELETON ======

PlayerMapMarker.MapAddedFlag = 4
PlayerMapMarker.nUpdateInterval = 1.00
PlayerMapMarker.bUseFrameTick = false
PlayerMapMarker.nHeavyScanFrameInterval = 30
PlayerMapMarker.nDistanceUpdateFrameInterval = 10
PlayerMapMarker.bIncludeMe = false
PlayerMapMarker.bIncludeAI = true
PlayerMapMarker.bUseServerMarks = false

PlayerMapMarker.bActive = false
PlayerMapMarker.MarkMap = {}
PlayerMapMarker.PlayerInfo = {}
PlayerMapMarker.ESPCanvas = nil
PlayerMapMarker.ESPWidgets = {}
PlayerMapMarker.ESPWidgetPtrs = {}
PlayerMapMarker.SnapLineWidgets = {}

PlayerMapMarker._cachedViewportW = 1920
PlayerMapMarker._cachedViewportH = 1080
PlayerMapMarker._FrameCount = 0
PlayerMapMarker._bTickRegistered = false
PlayerMapMarker._CachedAllChars = nil
PlayerMapMarker._CachedMyLoc = nil
PlayerMapMarker._CachedMyKey = nil
PlayerMapMarker.WidgetComps = {}
PlayerMapMarker._bAllPathsFailed = false
PlayerMapMarker._bLightUpdateScheduled = false
PlayerMapMarker._LightUpdateInterval = 0.08
PlayerMapMarker._bDistanceUpdateScheduled = false
PlayerMapMarker._DistanceUpdateInterval = 0.40
PlayerMapMarker._bScreenMarkConfigSetup = false

local function IsValid(obj)
    if obj == nil then return false end
    if slua and slua.isValid then return slua.isValid(obj) end
    return obj ~= nil
end

function PlayerMapMarker.SetupScreenMarkConfig()
    if PlayerMapMarker._bScreenMarkConfigSetup then return true end
    local bOK = false
    pcall(function()
        local GamePlayTools = require("GameLua.Mod.BaseMod.Common.GamePlayTools")
        local ScreenMarkConfig = GamePlayTools.GetCurrentConfig("ScreenMarkConfig")
        if ScreenMarkConfig then
            ScreenMarkConfig[1007] = {
                UIPathName = "/Game/BluePrints/UI/OBUI/Item/OB_PlayerHeadHPItem_UIBP.OB_PlayerHeadHPItem_UIBP_C",
                MaxWidgetNum = 100,
                MaxShowDistance = 6000000,
                bBindOutScreen = false,
                bBindBlocked = true,
                bNeedPreLoad = true,
                bIsBindingActor = true,
                BindSocketName = "HelmetSocket",
                WorldPositionOffset = FVector and FVector(0, 0, 80) or {X=0,Y=0,Z=80}
            }
            PlayerMapMarker._bScreenMarkConfigSetup = true
            bOK = true
        end
    end)
    return bOK
end

function PlayerMapMarker.GetGameplayData()
    if PlayerMapMarker._CachedGameplayData then return PlayerMapMarker._CachedGameplayData end
    local ok, GDP = pcall(function() return require("GameLua.GameCore.Data.GameplayData") end)
    if ok and GDP then PlayerMapMarker._CachedGameplayData = GDP return GDP end
    return nil
end

function PlayerMapMarker.GetMyPlayerController()
    local PC = PlayerMapMarker._CachedPC
    if PC and IsValid(PC) then return PC end
    local GDP = PlayerMapMarker.GetGameplayData()
    if not GDP then return nil end
    pcall(function() PC = GDP.GetPlayerController and GDP.GetPlayerController() end)
    if PC and IsValid(PC) then PlayerMapMarker._CachedPC = PC return PC end
    return nil
end

function PlayerMapMarker.GetCGameState()
    if CGameState and IsValid(CGameState) then return CGameState end
    if PlayerMapMarker._CachedCGameState and IsValid(PlayerMapMarker._CachedCGameState) then return PlayerMapMarker._CachedCGameState end
    local ok, GS = pcall(function() return require("GameLua.GameCore.Data.CGameState") end)
    if ok and GS then PlayerMapMarker._CachedCGameState = GS return GS end
    return nil
end

function PlayerMapMarker.GetAllCharacters()
    local AllChars = {}
    pcall(function()
        local Pawns = Game:GetAllPlayerPawns()
        if Pawns then
            for _, Pawn in pairs(Pawns) do
                if Pawn and slua.isValid(Pawn) then
                    local pKey = nil
                    if Pawn.GetPlayerKey then pKey = Pawn:GetPlayerKey() end
                    if not pKey and Pawn.PlayerKey then pKey = Pawn.PlayerKey end
                    if not pKey and Pawn.PlayerState and Pawn.PlayerState.PlayerKey then pKey = Pawn.PlayerState.PlayerKey end
                    if pKey then AllChars[pKey] = Pawn end
                end
            end
        end
    end)
    if not next(AllChars) then
        local GS = PlayerMapMarker.GetCGameState()
        if GS and GS.GetAllCharacters then pcall(function() AllChars = GS:GetAllCharacters() end) end
    end
    return AllChars
end

function PlayerMapMarker.GetMyPlayerKey()
    local PC = PlayerMapMarker.GetMyPlayerController()
    if not IsValid(PC) then return nil end
    local MyKey = nil
    pcall(function()
        if PC.GetPlayerKey then MyKey = PC:GetPlayerKey()
        elseif PC.PlayerState and PC.PlayerState.PlayerKey then MyKey = PC.PlayerState.PlayerKey end
    end)
    return MyKey
end

function PlayerMapMarker.IsMe(Character, PlayerKey, MyKey)
    local bIsMe = false
    pcall(function()
        local GDP = PlayerMapMarker.GetGameplayData()
        if GDP and GDP.GetLocalCharacter then
            local MyChar = GDP.GetLocalCharacter()
            if MyChar and Character == MyChar then bIsMe = true return end
        end
        local PC = PlayerMapMarker.GetMyPlayerController()
        if PC and PC.GetPawn then
            local Pawn = PC:GetPawn()
            if Pawn and Character == Pawn then bIsMe = true return end
        end
    end)
    if not bIsMe and MyKey ~= nil and PlayerKey ~= nil then bIsMe = (tostring(PlayerKey) == tostring(MyKey)) end
    return bIsMe
end

function PlayerMapMarker.GetCharacterLocation(Character)
    if not IsValid(Character) then return nil end
    local Loc = nil
    pcall(function() if Character.K2_GetActorLocation then Loc = Character:K2_GetActorLocation() end end)
    if not Loc then pcall(function() if Game and Game.GetActorLocation then Loc = Game:GetActorLocation(Character) end end) end
    return Loc
end

function PlayerMapMarker.CalcDistance(Loc1, Loc2)
    if not Loc1 or not Loc2 then return nil end
    local Dist = nil
    pcall(function() if FVector and FVector.Dist2D then Dist = FVector.Dist2D(Loc1, Loc2) end end)
    if not Dist then
        pcall(function()
            local DX = (Loc1.X or 0) - (Loc2.X or 0)
            local DY = (Loc1.Y or 0) - (Loc2.Y or 0)
            Dist = math.sqrt(DX * DX + DY * DY)
        end)
    end
    return Dist
end

function PlayerMapMarker.GetDistanceString(MyLoc, TargetLoc)
    if not PlayerMapMarker.bShowDistance then return "" end
    if not MyLoc or not TargetLoc then return "" end
    local Dist = PlayerMapMarker.CalcDistance(MyLoc, TargetLoc)
    if not Dist then return "" end
    local Meters = Dist / 100
    if Meters < 1000 then return string.format("%dm", math.floor(Meters))
    else return string.format("%.1fkm", Meters / 1000) end
end

function PlayerMapMarker.GetMyLocation()
    local GDP = PlayerMapMarker.GetGameplayData()
    if not GDP then return nil end
    local MyChar = nil
    pcall(function() MyChar = GDP.GetLocalCharacter and GDP.GetLocalCharacter() end)
    if not IsValid(MyChar) then
        local PC = PlayerMapMarker.GetMyPlayerController()
        if IsValid(PC) then
            pcall(function()
                if PC.GetPawn then
                    local Pawn = PC:GetPawn()
                    if IsValid(Pawn) and Pawn.K2_GetActorLocation then return Pawn:K2_GetActorLocation() end
                end
            end)
        end
        return nil
    end
    return PlayerMapMarker.GetCharacterLocation(MyChar)
end

function PlayerMapMarker.GetPlayerName(Character)
    if not IsValid(Character) then return "Unknown" end
    local Name = nil
    pcall(function() if Character.GetPlayerNameSafety then Name = Character:GetPlayerNameSafety() end end)
    if not Name then
        pcall(function()
            local PS = nil
            if Character.GetPlayerStateSafety then PS = Character:GetPlayerStateSafety()
            elseif Character.GetPlayerState then PS = Character:GetPlayerState() end
            if IsValid(PS) and PS.GetPlayerName then Name = PS:GetPlayerName() end
        end)
    end
    return Name or "Unknown"
end

function PlayerMapMarker.IsAI(Character)
    local bAI = false
    pcall(function() if Game and Game.IsAI then bAI = Game:IsAI(Character) end end)
    return bAI
end

function PlayerMapMarker.IsAlive(Character)
    local bAlive = true
    pcall(function() if Character.IsAlive then bAlive = Character:IsAlive() end end)
    return bAlive
end

function PlayerMapMarker.IsOurESPWidget(w)
    if not w or not slua.isValid(w) then return false end
    local bIsOurs = false
    pcall(function()
        local wstr = tostring(w)
        for KeyStr, ESPData in pairs(PlayerMapMarker.ESPWidgets) do
            if ESPData and ESPData.Widget and ESPData.Widget.Container then
                local cstr = tostring(ESPData.Widget.Container)
                if cstr == wstr then bIsOurs = true return end
            end
        end
    end)
    if bIsOurs then return true end
    pcall(function()
        if w.GetChildrenCount then
            local n = w:GetChildrenCount()
            for i = 0, n - 1 do
                local child = w:GetChildAt(i)
                if child and slua.isValid(child) then
                    local cstr = tostring(child)
                    if string.find(cstr, "Border") then bIsOurs = true break end
                end
            end
        end
    end)
    if not bIsOurs then
        pcall(function()
            local slot = w.Slot
            if slot and slot.GetPosition then
                local pos = slot:GetPosition()
                if pos and (math.abs(pos.X or 0) > 1 or math.abs(pos.Y or 0) > 1) then bIsOurs = true end
            end
        end)
    end
    return bIsOurs
end

function PlayerMapMarker.ApplyAnchorBasedPosition(Slot, ScreenPos, Canvas)
    if not Slot or not ScreenPos then return false end
    local sx = ScreenPos.X or 0
    local sy = ScreenPos.Y or 0
    local sz = PlayerMapMarker.ESPWidgetSize or (FVector2D and FVector2D(100, 30) or {X=100, Y=30})
    local align = PlayerMapMarker.ESPWidgetAlignment or (FVector2D and FVector2D(0.5, 1.0) or {X=0.5, Y=1.0})

    local canvasW, canvasH = 0, 0
    if PlayerMapMarker._cachedViewportW and PlayerMapMarker._cachedViewportW > 200 then
        canvasW = PlayerMapMarker._cachedViewportW
        canvasH = PlayerMapMarker._cachedViewportH
    end

    if canvasW < 200 then
        pcall(function()
            local PC = PlayerMapMarker.GetMyPlayerController()
            if IsValid(PC) and PC.GetViewportSize then
                local VS = FVector2D and FVector2D(0, 0) or {X=0, Y=0}
                PC:GetViewportSize(VS)
                if VS and VS.X and VS.X > 200 then
                    canvasW = VS.X ; canvasH = VS.Y
                    PlayerMapMarker._cachedViewportW = canvasW ; PlayerMapMarker._cachedViewportH = canvasH
                end
            end
        end)
    end

    if canvasW > 200 and canvasH > 200 then
        local anchorX = (sx + (PlayerMapMarker.ESPAnchorOffsetX or 0)) / canvasW
        local anchorY = (sy + (PlayerMapMarker.ESPAnchorOffsetY or 0)) / canvasH
        anchorX = math.max(0, math.min(1, anchorX))
        anchorY = math.max(0, math.min(1, anchorY))

        local bSuccess = false
        pcall(function()
            local FAnchors = import("Anchors") or import("/Script/SlateCore.Anchors")
            if Slot.SetAnchors and FAnchors then
                local anchors = FAnchors(anchorX, anchorY, anchorX, anchorY)
                if anchors then Slot:SetAnchors(anchors) Slot:SetPosition(FVector2D and FVector2D(0, 0) or {X=0, Y=0}) bSuccess = true end
            end
        end)
        if not bSuccess then
            pcall(function()
                if Slot.SetAnchors then Slot:SetAnchors(anchorX, anchorY, anchorX, anchorY) Slot:SetPosition(FVector2D and FVector2D(0, 0) or {X=0, Y=0}) bSuccess = true end
            end)
        end
        if bSuccess then
            pcall(function() if Slot.SetOffsets and import("Margin") then Slot:SetOffsets(import("Margin")(0, 0, sz.X, sz.Y)) end end)
            pcall(function() Slot:SetSize(sz) end)
            pcall(function() Slot:SetAlignment(align) end)
            pcall(function() if Slot.SetAutoSize then Slot:SetAutoSize(PlayerMapMarker.ESPWidgetAutoSize or true) end end)
            pcall(function() if Slot.SetZOrder then Slot:SetZOrder(PlayerMapMarker.ESPWidgetZOrder or 2) end end)
            return true
        end
    end

    pcall(function()
        Slot:SetPosition(FVector2D and FVector2D(sx, sy) or {X=sx, Y=sy})
        pcall(function() Slot:SetSize(sz) end)
        pcall(function() Slot:SetAlignment(align) end)
        pcall(function() if Slot.SetAutoSize then Slot:SetAutoSize(PlayerMapMarker.ESPWidgetAutoSize or true) end end)
        pcall(function() if Slot.SetZOrder then Slot:SetZOrder(PlayerMapMarker.ESPWidgetZOrder or 2) end end)
    end)
    return false
end

function PlayerMapMarker.InitESPCanvas()
    if PlayerMapMarker.ESPCanvas and Game:IsValid(PlayerMapMarker.ESPCanvas) then return true end
    local InGameUITools = nil
    pcall(function() InGameUITools = require("GameLua.Mod.BaseMod.Common.UI.InGameUITools") end)
    if not InGameUITools then return false end
    local MainControlBaseUI = nil
    pcall(function() MainControlBaseUI = InGameUITools.GetMainControlBaseUI() end)
    if not MainControlBaseUI or not Game:IsValid(MainControlBaseUI) then return false end

    local ParentCanvas = nil
    pcall(function()
        if MainControlBaseUI.CanvasPanel_0 and Game:IsValid(MainControlBaseUI.CanvasPanel_0) then ParentCanvas = MainControlBaseUI.CanvasPanel_0
        elseif MainControlBaseUI.CanvasPanel_42 and Game:IsValid(MainControlBaseUI.CanvasPanel_42) then ParentCanvas = MainControlBaseUI.CanvasPanel_42 end
    end)

    if not ParentCanvas then return false end
    PlayerMapMarker.ESPCanvas = ParentCanvas

    pcall(function()
        local nChildren = ParentCanvas:GetChildrenCount()
        for i = nChildren - 1, 0, -1 do
            local child = ParentCanvas:GetChildAt(i)
            if child and slua.isValid(child) then
                if PlayerMapMarker.IsOurESPWidget(child) then pcall(function() ParentCanvas:RemoveChild(child) end) end
            end
        end
    end)
    return true
end

function PlayerMapMarker.FindProgressBarInWidget(WidgetObj, Depth, MaxDepth)
    if not WidgetObj or not slua.isValid(WidgetObj) then return nil end
    Depth = Depth or 0 ; MaxDepth = MaxDepth or 5
    if Depth > MaxDepth then return nil end

    local bIsPB = false
    pcall(function() if WidgetObj.SetPercent and WidgetObj.SetFillColorAndOpacity then bIsPB = true end end)
    if bIsPB then return WidgetObj end

    local nChildren = 0
    pcall(function() if WidgetObj.GetChildrenCount then nChildren = WidgetObj:GetChildrenCount() end end)

    for i = 0, math.max(nChildren - 1, 0) do
        local child = nil
        pcall(function() child = WidgetObj:GetChildAt(i) end)
        if child and slua.isValid(child) then
            local result = PlayerMapMarker.FindProgressBarInWidget(child, Depth + 1, MaxDepth)
            if result then return result end
        end
    end
    return nil
end

function PlayerMapMarker.GetTeamID(Character)
    if not IsValid(Character) then return nil end
    local TeamID = nil
    pcall(function() if Character.GetTeamID then TeamID = Character:GetTeamID() end end)
    if not TeamID then
        pcall(function()
            local PS = nil
            if Character.GetPlayerStateSafety then PS = Character:GetPlayerStateSafety()
            elseif Character.GetPlayerState then PS = Character:GetPlayerState() end
            if IsValid(PS) and PS.GetTeamID then TeamID = PS:GetTeamID()
            elseif IsValid(PS) and PS.TeamID then TeamID = PS.TeamID end
        end)
    end
    if not TeamID then pcall(function() if Character.TeamID then TeamID = Character.TeamID end end) end
    return TeamID
end

function PlayerMapMarker.GetTeamColor(TeamID)
    if TeamID == nil or TeamID == 0 then 
        return FLinearColor and FLinearColor(0.2, 0.4, 1.0, 1.0) or {R=50,G=100,B=255,A=255} 
    end
    
    -- Khởi tạo bảng 15 màu sắc rực rỡ và dễ phân biệt
    local TeamColors = {
        [1]  = {R=255, G=50,  B=50,  A=255, fR=1.0, fG=0.2, fB=0.2}, -- Đỏ
        [2]  = {R=50,  G=255, B=50,  A=255, fR=0.2, fG=1.0, fB=0.2}, -- Lục (Xanh lá)
        [3]  = {R=50,  G=100, B=255, A=255, fR=0.2, fG=0.4, fB=1.0}, -- Lam (Xanh dương)
        [4]  = {R=255, G=255, B=50,  A=255, fR=1.0, fG=1.0, fB=0.2}, -- Vàng
        [5]  = {R=255, G=50,  B=255, A=255, fR=1.0, fG=0.2, fB=1.0}, -- Tím / Hồng Đậm
        [6]  = {R=50,  G=255, B=255, A=255, fR=0.2, fG=1.0, fB=1.0}, -- Xanh Ngọc Bích (Cyan)
        [7]  = {R=255, G=150, B=50,  A=255, fR=1.0, fG=0.6, fB=0.2}, -- Cam
        [8]  = {R=150, G=50,  B=255, A=255, fR=0.6, fG=0.2, fB=1.0}, -- Tím Đậm
        [9]  = {R=200, G=255, B=50,  A=255, fR=0.8, fG=1.0, fB=0.2}, -- Vàng Chanh
        [10] = {R=50,  G=150, B=255, A=255, fR=0.2, fG=0.6, fB=1.0}, -- Xanh Nước Biển
        [11] = {R=255, G=100, B=150, A=255, fR=1.0, fG=0.4, fB=0.6}, -- Hồng Nhạt
        [12] = {R=100, G=255, B=150, A=255, fR=0.4, fG=1.0, fB=0.6}, -- Xanh Trà
        [13] = {R=150, G=150, B=50,  A=255, fR=0.6, fG=0.6, fB=0.2}, -- Màu Olive
        [14] = {R=50,  G=200, B=150, A=255, fR=0.2, fG=0.8, fB=0.6}, -- Xanh Rêu
        [15] = {R=255, G=200, B=50,  A=255, fR=1.0, fG=0.8, fB=0.2}  -- Vàng Kim
    }
    
    -- Dùng thuật toán Modulo để xoay vòng màu. 
    -- Ví dụ: Team 16 chia 15 dư 1 sẽ dùng lại màu số 1.
    -- Đảm bảo 100 người (25 team) trong trận đều được tự động gắn màu, chung team = chung màu.
    local colorIndex = (TeamID % 15)
    if colorIndex == 0 then colorIndex = 15 end 
    
    local c = TeamColors[colorIndex]
    return FLinearColor and FLinearColor(c.fR, c.fG, c.fB, 1.0) or {R=c.R, G=c.G, B=c.B, A=c.A}
end

local _WhiteTexture = nil
local _bWhiteTextureFailed = false
local function GetWhiteTexture()
    if _WhiteTexture then return _WhiteTexture end
    if _bWhiteTextureFailed then return nil end
    pcall(function()
        local paths = { "/Game/BluePrints/UI/Textures/White.White", "/Game/BluePrints/UI/Textures/Common/White.White", "/Engine/EngineResources/WhiteSquareTexture.WhiteSquareTexture" }
        for _, path in ipairs(paths) do
            pcall(function() local tex = import(path); if tex and slua.isValid(tex) then _WhiteTexture = tex return end end)
            if _WhiteTexture then break end
        end
    end)
    if not _WhiteTexture then _bWhiteTextureFailed = true end
    return _WhiteTexture
end

local function SetImageColor(Image, color)
    if not Image or not slua.isValid(Image) then return false end
    local bOK = false
    pcall(function() if Image.SetBrushTintColor then Image:SetBrushTintColor(color); bOK = true end end)
    pcall(function() if Image.SetColorAndOpacity then Image:SetColorAndOpacity(color); bOK = true end end)
    pcall(function()
        if Image.SetBrushFromTexture then
            local whiteTex = GetWhiteTexture()
            if whiteTex then
                Image:SetBrushFromTexture(whiteTex, false)
                if Image.SetColorAndOpacity then Image:SetColorAndOpacity(color) end
                bOK = true
            end
        end
    end)
    pcall(function() Image:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible); Image:SetRenderOpacity(1.0) end)
    return bOK
end

function PlayerMapMarker._GetWidgetRoot(WidgetObj)
    if not WidgetObj or not slua.isValid(WidgetObj) then return nil end
    local Root = nil
    pcall(function() if WidgetObj.GetRootWidget then Root = WidgetObj:GetRootWidget() end end)
    if Root and slua.isValid(Root) then return Root end
    pcall(function() if WidgetObj.WidgetTree and WidgetObj.WidgetTree.RootWidget then Root = WidgetObj.WidgetTree.RootWidget end end)
    if Root and slua.isValid(Root) then return Root end
    pcall(function() if WidgetObj.RootWidget and slua.isValid(WidgetObj.RootWidget) then Root = WidgetObj.RootWidget end end)
    return Root
end

function PlayerMapMarker._FindNamedWidgetInTree(WidgetObj, TargetName, MaxDepth)
    if not WidgetObj or not slua.isValid(WidgetObj) then return nil end
    MaxDepth = MaxDepth or 8
    local wname = nil
    pcall(function() if WidgetObj.GetName then wname = WidgetObj:GetName() end end)
    if wname and wname == TargetName then return WidgetObj end

    local wstr = tostring(WidgetObj)
    if wstr and string.find(wstr, TargetName, 1, true) then
        if wname and wname == TargetName then return WidgetObj
        elseif not wname or wname == "" then
            local _, endPos = string.find(wstr, TargetName, 1, true)
            if endPos then
                local nextChar = string.sub(wstr, endPos + 1, endPos + 1)
                if nextChar ~= "_" and nextChar ~= "" then return WidgetObj end
            end
        end
    end

    local nChildren = 0
    pcall(function() if WidgetObj.GetChildrenCount then nChildren = WidgetObj:GetChildrenCount() end end)

    if nChildren > 0 then
        for i = 0, nChildren - 1 do
            local child = nil
            pcall(function() child = WidgetObj:GetChildAt(i) end)
            if child and slua.isValid(child) then
                local found = PlayerMapMarker._FindNamedWidgetInTree(child, TargetName, MaxDepth - 1)
                if found then return found end
            end
        end
    else
        local Root = PlayerMapMarker._GetWidgetRoot(WidgetObj)
        if Root and slua.isValid(Root) and Root ~= WidgetObj then
            local found = PlayerMapMarker._FindNamedWidgetInTree(Root, TargetName, MaxDepth - 1)
            if found then return found end
        end
    end
    return nil
end

function PlayerMapMarker.ApplyTeamColor(Widget, TeamID)
    if not Widget or not Widget.Container then return end
    
    -- [THÊM MỚI] Check công tắc tắt Ô màu team
    if not _G.AHMADConfig.Esp9_Team then
        pcall(function()
            local W = Widget.Container
            if W and slua.isValid(W) then
                local img1 = PlayerMapMarker._FindNamedWidgetInTree(W, "Image_TeamBG", 8)
                if img1 and slua.isValid(img1) then img1:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end
                local img2 = PlayerMapMarker._FindNamedWidgetInTree(W, "Image_TeamLogoBG", 8)
                if img2 and slua.isValid(img2) then img2:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end
                if Widget.TeamBgBorder and slua.isValid(Widget.TeamBgBorder) then Widget.TeamBgBorder:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end
            end
        end)
        return
    end

    local color = PlayerMapMarker.GetTeamColor(TeamID)
    if not color then return end

    pcall(function()
        local W = Widget.Container
        if not W or not slua.isValid(W) then return end

        local bBG = false
        local Image_TeamBG = PlayerMapMarker._FindNamedWidgetInTree(W, "Image_TeamBG", 8)
        if Image_TeamBG and slua.isValid(Image_TeamBG) then bBG = SetImageColor(Image_TeamBG, color) end

        local Image_TeamLogoBG = PlayerMapMarker._FindNamedWidgetInTree(W, "Image_TeamLogoBG", 8)
        if Image_TeamLogoBG and slua.isValid(Image_TeamLogoBG) then SetImageColor(Image_TeamLogoBG, color) end

        if W.SetTeamColor then pcall(function() W:SetTeamColor(TeamID) end) end
        
        if not Widget.TeamBgBorder or not slua.isValid(Widget.TeamBgBorder) then
            pcall(function()
                local Border = CGame:NewObjectFromPath("/Script/UMG.Border", W)
                if Border and slua.isValid(Border) then
                    pcall(function() Border:SetBrushColor(color) end)
                    pcall(function() Border:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
                    pcall(function() Border:SetRenderOpacity(0.7) end)
                    pcall(function() Border:SetDesiredSizeOverride(FVector2D and FVector2D(120, 20) or {X=120, Y=20}) end)
                    pcall(function() if W.AddChild then W:AddChild(Border) end end)
                    pcall(function() if Border.SetZOrder then Border:SetZOrder(-1) end end)
                    Widget.TeamBgBorder = Border
                end
            end)
        else
            pcall(function()
                Widget.TeamBgBorder:SetBrushColor(color)
                Widget.TeamBgBorder:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                Widget.TeamBgBorder:SetRenderOpacity(0.7)
            end)
        end
    end)
end

function PlayerMapMarker.GetCharacterMesh(Character)
    if not IsValid(Character) then return nil end
    local Mesh = nil
    pcall(function() if Character.Mesh and Game:IsValid(Character.Mesh) then Mesh = Character.Mesh end end)
    if not Mesh then pcall(function() local SkeletalMeshCompClass = import("/Script/Engine.SkeletalMeshComponent") Mesh = Character:GetComponentByClass(SkeletalMeshCompClass) end) end
    return Mesh
end

function PlayerMapMarker.GetESPLocation(Character)
    if not IsValid(Character) then return nil end
    local BoneLoc = PlayerMapMarker.GetCharacterLocation(Character)
    if BoneLoc then
        local heightOffset = 85
        pcall(function()
            if Character.bIsCrouched then heightOffset = 60 end
            if Character.IsProne and Character:IsProne() then heightOffset = 30 end
        end)
        pcall(function() BoneLoc.Z = BoneLoc.Z + heightOffset + (PlayerMapMarker.ESPWorldOffsetZ or 0) end)
    end
    return BoneLoc
end

function PlayerMapMarker.GetCharacterWeaponInfo(Character)
    if not IsValid(Character) then return nil end
    local WeaponID, WeaponName, WeaponIconPath, WeaponIconTexture, CurrentWeapon = nil, nil, nil, nil, nil

    pcall(function() if Character.GetCurrentWeapon then CurrentWeapon = Character:GetCurrentWeapon() end end)
    if not CurrentWeapon then pcall(function() CurrentWeapon = Character.CurrentWeapon end) end
    if not CurrentWeapon then pcall(function() if Character.GetWeaponManager then local WM = Character:GetWeaponManager() if WM and WM.GetCurrentWeapon then CurrentWeapon = WM:GetCurrentWeapon() end end end) end

    if CurrentWeapon and IsValid(CurrentWeapon) then
        pcall(function() if CurrentWeapon.GetWeaponID then WeaponID = CurrentWeapon:GetWeaponID() end end)
        if not WeaponID then pcall(function() WeaponID = CurrentWeapon.WeaponID end) end
        if not WeaponID then pcall(function() if CurrentWeapon.GetItemID then WeaponID = CurrentWeapon:GetItemID() end end) end
        pcall(function() if CurrentWeapon.GetWeaponName then WeaponName = CurrentWeapon:GetWeaponName() end end)
        pcall(function() if CurrentWeapon.GetWeaponIconPath then WeaponIconPath = CurrentWeapon:GetWeaponIconPath() end end)
        pcall(function() if CurrentWeapon.GetWeaponIcon then WeaponIconTexture = CurrentWeapon:GetWeaponIcon() end end)
    end

    if not WeaponID then
        pcall(function()
            local PS = nil
            if Character.GetPlayerStateSafety then PS = Character:GetPlayerStateSafety() elseif Character.GetPlayerState then PS = Character:GetPlayerState() end
            if PS and IsValid(PS) then
                if PS.GetCurrentWeaponID then WeaponID = PS:GetCurrentWeaponID() end
                if not WeaponID and PS.CurWeaponID then WeaponID = PS.CurWeaponID end
            end
        end)
    end
    return { WeaponID = WeaponID, WeaponName = WeaponName, WeaponIconPath = WeaponIconPath, WeaponIconTexture = WeaponIconTexture, CurrentWeapon = CurrentWeapon }
end

function PlayerMapMarker.FindWeaponIconInWidget(WidgetObj, Depth, MaxDepth)
    if not WidgetObj or not slua.isValid(WidgetObj) then return nil end
    Depth = Depth or 0 ; MaxDepth = MaxDepth or 8
    local propNames = { "Image_Weapon", "Image_WeaponIcon", "Image_Gun", "Image_Icon", "WeaponIcon", "WeaponImage", "Image_Equip" }
    for _, pname in ipairs(propNames) do
        pcall(function()
            local prop = WidgetObj[pname]
            if prop and slua.isValid(prop) then
                local hasBrush = false
                pcall(function() if prop.Brush then hasBrush = true end end)
                if hasBrush then return prop end
            end
        end)
    end
    if Depth >= MaxDepth then return nil end
    local nChildren = 0
    pcall(function() if WidgetObj.GetChildrenCount then nChildren = WidgetObj:GetChildrenCount() end end)
    for i = 0, math.max(nChildren - 1, 0) do
        local child = nil
        pcall(function() child = WidgetObj:GetChildAt(i) end)
        if child and slua.isValid(child) then
            local result = PlayerMapMarker.FindWeaponIconInWidget(child, Depth + 1, MaxDepth)
            if result then return result end
        end
    end
    if nChildren == 0 then
        local Root = PlayerMapMarker._GetWidgetRoot(WidgetObj)
        if Root and slua.isValid(Root) and Root ~= WidgetObj then
            local result = PlayerMapMarker.FindWeaponIconInWidget(Root, Depth + 1, MaxDepth)
            if result then return result end
        end
    end
    return nil
end

function PlayerMapMarker.FixWeaponIconBrushSize(ImageWidget, DefaultW, DefaultH)
    if not ImageWidget or not slua.isValid(ImageWidget) then return end
    DefaultW = DefaultW or 138 ; DefaultH = DefaultH or 69
    pcall(function()
        local brush = ImageWidget.Brush
        if brush then
            brush.ImageSize = FVector2D and FVector2D(DefaultW, DefaultH) or {X=DefaultW, Y=DefaultH}
            brush.DrawAs = 3
            brush.TintColor = FLinearColor and FLinearColor(1.0, 1.0, 1.0, 1.0) or {R=1,G=1,B=1,A=1}
            if ImageWidget.SetBrush then ImageWidget:SetBrush(brush) end
        end
        if ImageWidget.SetDesiredSizeOverride then ImageWidget:SetDesiredSizeOverride(FVector2D and FVector2D(DefaultW, DefaultH) or {X=DefaultW, Y=DefaultH}) end
        local slot = ImageWidget.Slot
        if slot and slot.SetSize then slot:SetSize(FVector2D and FVector2D(DefaultW, DefaultH) or {X=DefaultW, Y=DefaultH}) end
        ImageWidget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        ImageWidget:SetRenderOpacity(1.0)
        ImageWidget:SetColorAndOpacity(FLinearColor and FLinearColor(1.0, 1.0, 1.0, 1.0) or {R=1,G=1,B=1,A=1})
    end)
end

function PlayerMapMarker.ApplyWeaponIconFullOpacity(Container, ourWeaponIcon)
    local fullIcon = FLinearColor and FLinearColor(1.0, 1.0, 1.0, 1.0) or {R=1,G=1,B=1,A=1}
    if not ourWeaponIcon or not slua.isValid(ourWeaponIcon) then return end
    pcall(function() if ourWeaponIcon.SetRenderOpacity then ourWeaponIcon:SetRenderOpacity(1.0) end end)
    pcall(function() if ourWeaponIcon.SetColorAndOpacity then ourWeaponIcon:SetColorAndOpacity(fullIcon) end end)
    pcall(function()
        local brush = ourWeaponIcon.Brush
        if brush then pcall(function() brush.TintColor = fullIcon end) if ourWeaponIcon.SetBrush then ourWeaponIcon:SetBrush(brush) end end
    end)
    local chainNames = {"Border_WeaponColor", "Border_Weapon", "Border_WeaponIcon", "SizeBox_Weapon", "ScaleBox_Weapon", "Switcher_WeaponIcon"}
    for _, pname in ipairs(chainNames) do
        pcall(function()
            local node = Container and Container[pname]
            if node and slua.isValid(node) and node.SetRenderOpacity then node:SetRenderOpacity(1.0) end
            if node and slua.isValid(node) and node.SetColorAndOpacity then node:SetColorAndOpacity(fullIcon) end
        end)
    end
end

function PlayerMapMarker.ApplyWeaponIconToImage(ImageWidget, winfo)
    if not ImageWidget or not slua.isValid(ImageWidget) then return false, "no_widget" end
    if not winfo or not winfo.WeaponID then return false, "no_weapon_id" end

    local iconPath = nil
    local method = "none"
    local bHasAddKnownMissing = false
    local defaultW = 138
    local defaultH = 69

    pcall(function()
        local itemRecord = CDataTable.GetTableData("Item", winfo.WeaponID)
        if itemRecord and itemRecord.KillWhiteIcon and itemRecord.KillWhiteIcon ~= "" then iconPath = itemRecord.KillWhiteIcon method = "KillWhiteIcon" end
        if (not iconPath or iconPath == "") and winfo.WeaponIconPath and winfo.WeaponIconPath ~= "" then iconPath = winfo.WeaponIconPath method = "WeaponIconPath" end
        if (not iconPath or iconPath == "") and winfo.WeaponIconTexture and slua.isValid(winfo.WeaponIconTexture) then
            if ImageWidget.SetBrushFromTexture then ImageWidget:SetBrushFromTexture(winfo.WeaponIconTexture, true) method = "WeaponIconTexture" return end
        end
        if not iconPath or iconPath == "" then
            local UIUtil = require("client.common.ui_util")
            iconPath, bHasAddKnownMissing = UIUtil.GetItemBigIcon(winfo.WeaponID, ImageWidget)
            if iconPath and iconPath ~= "" then method = "GetItemBigIcon" end
        end
        if not iconPath or iconPath == "" then
            local UIUtil = require("client.common.ui_util")
            iconPath = UIUtil.GetItemSmallIcon(winfo.WeaponID, ImageWidget, bHasAddKnownMissing)
            if iconPath and iconPath ~= "" then method = "GetItemSmallIcon" end
        end
    end)

    if method == "WeaponIconTexture" then PlayerMapMarker.FixWeaponIconBrushSize(ImageWidget, defaultW, defaultH) return true, method end
    if not iconPath or iconPath == "" then return false, "no_path" end

    local bOK = false
    pcall(function()
        if ImageWidget.SetBrushResourceFromPathSync then ImageWidget:SetBrushResourceFromPathSync(iconPath, true) bOK = true end
        if not bOK then
            local util = require("client.slua_ui_framework.util")
            local result = util.SetTexture(ImageWidget, iconPath, { sync = true, bMatchSize = true, bIsInCombatState = true, bHasAddKnownMissing = bHasAddKnownMissing })
            bOK = result ~= nil
        end
        if not bOK then
            local tex = import(iconPath)
            if tex and slua.isValid(tex) and ImageWidget.SetBrushFromTexture then ImageWidget:SetBrushFromTexture(tex, true) bOK = true end
        end
        if not bOK then
            local LoadObject = import("LoadObject")
            if LoadObject then
                local tex = LoadObject(iconPath)
                if tex and slua.isValid(tex) and ImageWidget.SetBrushFromTexture then ImageWidget:SetBrushFromTexture(tex, true) bOK = true end
            end
        end
    end)

    if bOK then PlayerMapMarker.FixWeaponIconBrushSize(ImageWidget, defaultW, defaultH) end
    return bOK, method .. ":" .. tostring(iconPath)
end

function PlayerMapMarker.CopyWeaponIconBrushFromNative(ourWeaponIcon, nativeWeaponIcon)
    if not ourWeaponIcon or not slua.isValid(ourWeaponIcon) then return false end
    if not nativeWeaponIcon or not slua.isValid(nativeWeaponIcon) then return false end

    local bCopied = false
    pcall(function()
        local nBrush = nativeWeaponIcon.Brush
        if nBrush then
            local resObj = nil
            pcall(function() resObj = nBrush.ResourceObject end)
            if resObj and slua.isValid(resObj) and ourWeaponIcon.SetBrushFromTexture then
                ourWeaponIcon:SetBrushFromTexture(resObj, true)
                bCopied = true
            end
            if bCopied then
                local imgSize = nil
                pcall(function() imgSize = nBrush.ImageSize end)
                if imgSize then
                    local oBrush = ourWeaponIcon.Brush
                    if oBrush then oBrush.ImageSize = imgSize if ourWeaponIcon.SetBrush then ourWeaponIcon:SetBrush(oBrush) end end
                end
            end
        end
    end)
    return bCopied
end

function PlayerMapMarker.AddWeaponIconToESP(WidgetData, Character)
    if not WidgetData or not WidgetData.Container then return end
    local Container = WidgetData.Container
    if not slua.isValid(Container) then return end

    -- [THÊM MỚI] Check công tắc Tắt Icon Súng
    if not _G.AHMADConfig.Esp9_Weapon then
        pcall(function()
            local chainNames = {"Border_WeaponColor", "Border_Weapon", "Border_WeaponIcon", "SizeBox_Weapon", "ScaleBox_Weapon", "Switcher_WeaponIcon"}
            for _, pname in ipairs(chainNames) do
                local node = Container[pname]
                if node and slua.isValid(node) and node.SetWidgetVisibility then node:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end
            end
            local ourWeaponIcon = Container.WeaponIcon or PlayerMapMarker.FindWeaponIconInWidget(Container, 0, 8)
            if ourWeaponIcon and slua.isValid(ourWeaponIcon) then ourWeaponIcon:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end
        end)
        WidgetData._LastWeaponID = 0
        WidgetData._WeaponIconApplied = false
        return
    end

    pcall(function()
        local ourWeaponIcon = Container.WeaponIcon
        if not ourWeaponIcon or not slua.isValid(ourWeaponIcon) then ourWeaponIcon = PlayerMapMarker.FindWeaponIconInWidget(Container, 0, 8) end
        if not ourWeaponIcon or not slua.isValid(ourWeaponIcon) then return end

        local winfo = Character and PlayerMapMarker.GetCharacterWeaponInfo(Character) or nil

        if not winfo or not winfo.WeaponID or winfo.WeaponID == 0 then
            pcall(function() ourWeaponIcon:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
            local chainNames = {"Border_WeaponColor", "Border_Weapon", "Border_WeaponIcon", "SizeBox_Weapon", "ScaleBox_Weapon", "Switcher_WeaponIcon"}
            for _, pname in ipairs(chainNames) do
                pcall(function()
                    local node = Container and Container[pname]
                    if node and slua.isValid(node) and node.SetWidgetVisibility then node:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end
                end)
            end
            WidgetData._LastWeaponID = 0
            WidgetData._WeaponIconApplied = false
            return
        end

        if WidgetData._LastWeaponID == winfo.WeaponID and WidgetData._WeaponIconApplied then
            pcall(function() ourWeaponIcon:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
            pcall(function() ourWeaponIcon:SetRenderOpacity(1.0) end)
            local chainNames = {"Border_WeaponColor", "Border_Weapon", "Border_WeaponIcon", "SizeBox_Weapon", "ScaleBox_Weapon", "Switcher_WeaponIcon"}
            for _, pname in ipairs(chainNames) do
                pcall(function()
                    local node = Container and Container[pname]
                    if node and slua.isValid(node) and node.SetWidgetVisibility then
                        node:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                        pcall(function() if node.SetRenderOpacity then node:SetRenderOpacity(1.0) end end)
                    end
                end)
            end
            if WidgetData._CachedSwitcherIndexes then
                for sName, idx in pairs(WidgetData._CachedSwitcherIndexes) do
                    pcall(function()
                        local ws = Container[sName]
                        if ws and slua.isValid(ws) and ws.SetActiveWidgetIndex then ws:SetActiveWidgetIndex(idx) end
                    end)
                end
            end
            if WidgetData._CachedParentSwitchers then
                for _, data in pairs(WidgetData._CachedParentSwitchers) do
                    pcall(function() if data.w and slua.isValid(data.w) and data.w.SetActiveWidgetIndex then data.w:SetActiveWidgetIndex(data.idx) end end)
                end
            end
            return
        end

        local chainNames = {"Border_WeaponColor", "Border_Weapon", "Border_WeaponIcon", "SizeBox_Weapon", "ScaleBox_Weapon", "Switcher_WeaponIcon"}
        for _, pname in ipairs(chainNames) do
            pcall(function()
                local node = Container and Container[pname]
                if node and slua.isValid(node) and node.SetWidgetVisibility then node:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end
            end)
        end

        local bCopied = false
        if winfo and winfo.WeaponID then
            local ok, method = PlayerMapMarker.ApplyWeaponIconToImage(ourWeaponIcon, winfo)
            if ok then bCopied = true end
        end

        local bWeaponIconSet = false
        if Character and winfo then
            if winfo and winfo.WeaponID then
                pcall(function() if Container.SetWeaponIcon then Container:SetWeaponIcon(winfo.WeaponID) bWeaponIconSet = true end end)
                if not bWeaponIconSet then pcall(function() if Container.SetWeaponIconByID then Container:SetWeaponIconByID(winfo.WeaponID) bWeaponIconSet = true end end) end
                if not bWeaponIconSet then pcall(function() if Container.UpdateWeaponIcon then Container:UpdateWeaponIcon(winfo.WeaponID) bWeaponIconSet = true end end) end
                if not bWeaponIconSet then pcall(function() if Container.SetWeaponID then Container:SetWeaponID(winfo.WeaponID) bWeaponIconSet = true end end) end
                pcall(function() if Container.SetData then Container:SetData(Character) end end)
                pcall(function() if Container.SetPlayerInfo then Container:SetPlayerInfo(Character) end end)
                if winfo.CurrentWeapon then pcall(function() if Container.SetCurrentWeapon then Container:SetCurrentWeapon(winfo.CurrentWeapon) end end) end
            end
        end

        if bWeaponIconSet then
            pcall(function()
                local innerIcon = Container.Image_Icon
                if not innerIcon or not slua.isValid(innerIcon) then if Container.CanvasPanel_Type1 then innerIcon = Container.CanvasPanel_Type1.Image_Icon end end
                if not innerIcon or not slua.isValid(innerIcon) then
                    local function findImageIcon(w, depth)
                        if not w or not slua.isValid(w) or depth > 8 then return nil end
                        local prop = w.Image_Icon
                        if prop and slua.isValid(prop) then return prop end
                        local n = 0
                        pcall(function() if w.GetChildrenCount then n = w:GetChildrenCount() end end)
                        for i = 0, math.max(n - 1, 0) do
                            local c = nil
                            pcall(function() c = w:GetChildAt(i) end)
                            if c then local r = findImageIcon(c, depth + 1) if r then return r end end
                        end
                        return nil
                    end
                    innerIcon = findImageIcon(Container, 0)
                end
                if innerIcon and slua.isValid(innerIcon) and innerIcon ~= ourWeaponIcon then
                    pcall(function()
                        local ibrush = innerIcon.Brush
                        if ibrush then
                            local iresObj = nil
                            pcall(function() iresObj = ibrush.ResourceObject end)
                            if iresObj and slua.isValid(iresObj) then
                                if ourWeaponIcon.SetBrushFromAsset then ourWeaponIcon:SetBrushFromAsset(iresObj) bCopied = true end
                                if not bCopied and ourWeaponIcon.SetBrushFromTexture then ourWeaponIcon:SetBrushFromTexture(iresObj) bCopied = true end
                            end
                        end
                    end)
                    if not bCopied then
                        pcall(function()
                            local brush = innerIcon.Brush
                            if brush then
                                local iresObj = nil
                                pcall(function() iresObj = brush.ResourceObject end)
                                if iresObj and slua.isValid(iresObj) and ourWeaponIcon.SetBrushFromTexture then
                                    ourWeaponIcon:SetBrushFromTexture(iresObj, false)
                                    PlayerMapMarker.FixWeaponIconBrushSize(ourWeaponIcon)
                                    bCopied = true
                                end
                            end
                        end)
                    end
                end
            end)
        end

        if not bCopied then
            local nativeWeaponIcon = nil
            if PlayerMapMarker.ESPCanvas and Game:IsValid(PlayerMapMarker.ESPCanvas) then
                local nChildren = 0
                pcall(function() nChildren = PlayerMapMarker.ESPCanvas:GetChildrenCount() end)
                for i = 0, math.max(nChildren - 1, 0) do
                    local child = nil
                    pcall(function() child = PlayerMapMarker.ESPCanvas:GetChildAt(i) end)
                    if child and slua.isValid(child) then
                        local cstr = tostring(child)
                        if string.find(cstr, "OB_PlayerHeadHPItem") then
                            if not PlayerMapMarker.IsOurESPWidget(child) then
                                local nativeIcon = child.WeaponIcon
                                if nativeIcon and slua.isValid(nativeIcon) then nativeWeaponIcon = nativeIcon break end
                            end
                        end
                    end
                end
            end

            if nativeWeaponIcon and slua.isValid(nativeWeaponIcon) then
                local okNative, nativeMethod = PlayerMapMarker.CopyWeaponIconBrushFromNative(ourWeaponIcon, nativeWeaponIcon)
                if okNative then bCopied = true end
            end
        end

        if not bCopied then
            pcall(function()
                local brush = ourWeaponIcon.Brush
                if brush then
                    local resObj = nil
                    pcall(function() resObj = brush.ResourceObject end)
                    if resObj and slua.isValid(resObj) and ourWeaponIcon.SetBrushFromTexture then
                        ourWeaponIcon:SetBrushFromTexture(resObj)
                        bCopied = true
                    end
                end
            end)
        end

        if not bCopied then
            pcall(function()
                local brush = ourWeaponIcon.Brush
                if brush then
                    local imgSize = nil
                    pcall(function() imgSize = brush.ImageSize end)
                    local bZeroSize = false
                    if imgSize then
                        local sx, sy = nil, nil
                        pcall(function() sx = imgSize.X end)
                        pcall(function() sy = imgSize.Y end)
                        if (not sx or sx == 0) and (not sy or sy == 0) then bZeroSize = true end
                    end
                    if bZeroSize then
                        pcall(function() brush.ImageSize = FVector2D and FVector2D(PlayerMapMarker.WeaponIconBrushW or 138, PlayerMapMarker.WeaponIconBrushH or 69) or {X=138, Y=69} end)
                    end
                    pcall(function() brush.DrawAs = 3 end)
                    if ourWeaponIcon.SetBrush then ourWeaponIcon:SetBrush(brush) end
                end
            end)
        end

        pcall(function() ourWeaponIcon:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
        PlayerMapMarker.ApplyWeaponIconFullOpacity(Container, ourWeaponIcon)
        PlayerMapMarker.FixWeaponIconBrushSize(ourWeaponIcon)

        pcall(function()
            local function findWidgetInSwitcher(switcher, targetWidget)
                if not switcher or not slua.isValid(switcher) then return nil end
                if not switcher.GetChildrenCount or not switcher.GetChildAt then return nil end
                local nChildren = switcher:GetChildrenCount()
                for i = 0, math.max(nChildren - 1, 0) do
                    local child = switcher:GetChildAt(i)
                    if child and slua.isValid(child) then
                        if child == targetWidget then return i end
                        local function searchDescendant(w, target, depth)
                            if depth > 5 then return false end
                            if w == target then return true end
                            if not w.GetChildrenCount or not w.GetChildAt then return false end
                            local nc = w:GetChildrenCount()
                            for j = 0, math.max(nc - 1, 0) do
                                local c = w:GetChildAt(j)
                                if c and slua.isValid(c) and searchDescendant(c, target, depth + 1) then return true end
                            end
                            return false
                        end
                        if searchDescendant(child, targetWidget, 0) then return i end
                    end
                end
                return nil
            end

            for _, switcherName in ipairs({"Switcher_WeaponIcon", "WidgetSwitcher_Type", "WidgetSwitcher_Type2"}) do
                local ws = Container[switcherName]
                if ws and slua.isValid(ws) and ws.GetChildrenCount and ws.GetChildAt then
                    local foundIdx = findWidgetInSwitcher(ws, ourWeaponIcon)
                    if foundIdx then
                        if ws.SetActiveWidgetIndex then
                            ws:SetActiveWidgetIndex(foundIdx)
                            WidgetData._CachedSwitcherIndexes = WidgetData._CachedSwitcherIndexes or {}
                            WidgetData._CachedSwitcherIndexes[switcherName] = foundIdx
                        end
                    end
                end
            end
        end)

        pcall(function()
            local parent = ourWeaponIcon
            for depth = 0, 8 do
                if not parent or not slua.isValid(parent) then break end
                if parent.GetParent then
                    local p = parent:GetParent()
                    if p and slua.isValid(p) then
                        local pStr = tostring(p)
                        if string.find(pStr, "WidgetSwitcher") then
                            if p.GetChildrenCount and p.GetChildAt then
                                local nCh = p:GetChildrenCount()
                                for i = 0, math.max(nCh - 1, 0) do
                                    local child = p:GetChildAt(i)
                                    if child and slua.isValid(child) then
                                        local function isDescendant(w, target, d)
                                            if d > 5 then return false end
                                            if w == target then return true end
                                            if not w.GetChildrenCount or not w.GetChildAt then return false end
                                            local nc = w:GetChildrenCount()
                                            for j = 0, math.max(nc - 1, 0) do
                                                local c = w:GetChildAt(j)
                                                if c and slua.isValid(c) and isDescendant(c, target, d + 1) then return true end
                                            end
                                            return false
                                        end
                                        if isDescendant(child, ourWeaponIcon, 0) then
                                            if p.SetActiveWidgetIndex then
                                                p:SetActiveWidgetIndex(i)
                                                WidgetData._CachedParentSwitchers = WidgetData._CachedParentSwitchers or {}
                                                WidgetData._CachedParentSwitchers[tostring(p)] = {w = p, idx = i}
                                            end
                                            break
                                        end
                                    end
                                end
                            end
                        end
                        parent = p
                    else
                        break
                    end
                else
                    break
                end
            end
        end)

        pcall(function()
            local parent = ourWeaponIcon
            for depth = 0, 8 do
                pcall(function()
                    if parent.GetParent then
                        local p = parent:GetParent()
                        if p and slua.isValid(p) then
                            if p.SetWidgetVisibility then p:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end
                            pcall(function() if p.SetRenderOpacity then p:SetRenderOpacity(1.0) end end)
                            pcall(function() if p.SetContentColorAndOpacity then p:SetContentColorAndOpacity(FLinearColor and FLinearColor(1.0, 1.0, 1.0, 1.0) or {R=1,G=1,B=1,A=1}) end end)
                            pcall(function() if p.SetColorAndOpacity then p:SetColorAndOpacity(FLinearColor and FLinearColor(1.0, 1.0, 1.0, 1.0) or {R=1,G=1,B=1,A=1}) end end)
                            pcall(function() if p.SetBrushTintColor then p:SetBrushTintColor(FLinearColor and FLinearColor(1.0, 1.0, 1.0, 1.0) or {R=1,G=1,B=1,A=1}) end end)
                            pcall(function()
                                local pBrush = p.Brush
                                if pBrush and pBrush.TintColor then
                                    pBrush.TintColor = FLinearColor and FLinearColor(1.0, 1.0, 1.0, 1.0) or {R=1,G=1,B=1,A=1}
                                    if p.SetBrush then p:SetBrush(pBrush) end
                                end
                            end)
                            pcall(function() if p.InvalidateLayout then p:InvalidateLayout() end end)
                            parent = p
                        end
                    end
                end)
            end
        end)
        pcall(function() if ourWeaponIcon.InvalidateLayout then ourWeaponIcon:InvalidateLayout() end end)

        pcall(function() if Container.UpdateWeapon then Container:UpdateWeapon() end end)
        pcall(function() if Container.RefreshWeapon then Container:RefreshWeapon() end end)
        
        WidgetData._LastWeaponID = winfo.WeaponID
        WidgetData._WeaponIconApplied = true
    end)
end

PlayerMapMarker._OBHeadWidgetClass = nil
PlayerMapMarker._OBHeadWidgetLoadFailed = false
PlayerMapMarker._bDumpedWidgetChildren = false

function PlayerMapMarker.CreateESPWidget()
    if not PlayerMapMarker.ESPCanvas or not Game:IsValid(PlayerMapMarker.ESPCanvas) then return nil end
    if PlayerMapMarker._OBHeadWidgetLoadFailed then return nil end

    if not PlayerMapMarker._OBHeadWidgetClass then
        pcall(function()
            local Path = "/Game/BluePrints/UI/OBUI/Item/OB_PlayerHeadHPItem_UIBP.OB_PlayerHeadHPItem_UIBP"
            local uClass = slua.loadClass(Path)
            if uClass then PlayerMapMarker._OBHeadWidgetClass = uClass end
        end)
        if not PlayerMapMarker._OBHeadWidgetClass then
            PlayerMapMarker._OBHeadWidgetLoadFailed = true
            return nil
        end
    else
        local bValid = false
        pcall(function() bValid = slua.isValid(PlayerMapMarker._OBHeadWidgetClass) end)
        if not bValid then
            PlayerMapMarker._OBHeadWidgetLoadFailed = true
            PlayerMapMarker._OBHeadWidgetClass = nil
            return nil
        end
    end

    local Widget = nil
    pcall(function()
        local STExtraBlueprintFunctionLibrary = import("STExtraBlueprintFunctionLibrary")
        local PC = PlayerMapMarker.GetMyPlayerController()
        local OuterObj = IsValid(PC) and PC.Object or PlayerMapMarker.ESPCanvas
        Widget = STExtraBlueprintFunctionLibrary.CreateWidgetByClass(PlayerMapMarker._OBHeadWidgetClass, OuterObj)
    end)

    if not Widget then return nil end

    pcall(function() Widget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
    pcall(function() Widget:SetRenderOpacity(1.0) end)

    local NameText = nil
    local HealthFill = nil
    local bIsOriginalProgressBar = false

    pcall(function()
        NameText = Widget.TextBlock_TeamName
        if NameText and slua.isValid(NameText) then pcall(function() NameText:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end) end
        if Widget.TextBlock_PlayerName and slua.isValid(Widget.TextBlock_PlayerName) then pcall(function() Widget.TextBlock_PlayerName:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end) end

        local WS_Type = Widget.WidgetSwitcher_Type
        local WS_Type2 = Widget.WidgetSwitcher_Type2
        if WS_Type and slua.isValid(WS_Type) then pcall(function() if WS_Type.SetActiveWidgetIndex then WS_Type:SetActiveWidgetIndex(PlayerMapMarker.HPWidgetSwitcherTypeIndex) end end) end
        if WS_Type2 and slua.isValid(WS_Type2) then pcall(function() if WS_Type2.SetActiveWidgetIndex then WS_Type2:SetActiveWidgetIndex(PlayerMapMarker.HPWidgetSwitcherType2Index) end end) end

        local SizeBox_HP = Widget.SizeBox_HP
        if SizeBox_HP and slua.isValid(SizeBox_HP) then
            pcall(function() SizeBox_HP:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
            pcall(function() SizeBox_HP:SetHeightOverride(6) end)
            pcall(function() SizeBox_HP:SetWidthOverride(100) end)

            local ExistingChild = nil
            pcall(function() if SizeBox_HP.GetContent then ExistingChild = SizeBox_HP:GetContent() end end)
            if not ExistingChild then pcall(function() if SizeBox_HP.GetChildAt then ExistingChild = SizeBox_HP:GetChildAt(0) end end) end

            if ExistingChild and slua.isValid(ExistingChild) then
                pcall(function() ExistingChild:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
                pcall(function() ExistingChild:SetRenderOpacity(1.0) end)

                local FoundPB = PlayerMapMarker.FindProgressBarInWidget(ExistingChild, 0, 5)
                if FoundPB and slua.isValid(FoundPB) then
                    HealthFill = FoundPB
                    bIsOriginalProgressBar = true
                    pcall(function() FoundPB:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
                    pcall(function() FoundPB:SetRenderOpacity(1.0) end)
                else
                    local PB = CGame:NewObjectFromPath("/Script/UMG.ProgressBar", ExistingChild)
                    if PB then
                        pcall(function() PB:SetFillColorAndOpacity(FLinearColor and FLinearColor(0, 1, 0, 1) or {R=0,G=1,B=0,A=1}) end)
                        pcall(function() PB:SetPercent(1.0) end)
                        pcall(function() PB:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
                        pcall(function() PB:SetRenderOpacity(1.0) end)
                        pcall(function() PB:SetDesiredSizeOverride(FVector2D and FVector2D(100, 6) or {X=100, Y=6}) end)
                        pcall(function() ExistingChild:AddChild(PB) end)
                        HealthFill = PB
                    end
                end
            else
                local PB = CGame:NewObjectFromPath("/Script/UMG.ProgressBar", SizeBox_HP)
                if PB then
                    pcall(function() PB:SetFillColorAndOpacity(FLinearColor and FLinearColor(0, 1, 0, 1) or {R=0,G=1,B=0,A=1}) end)
                    pcall(function() PB:SetPercent(1.0) end)
                    pcall(function() PB:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
                    pcall(function() PB:SetRenderOpacity(1.0) end)
                    pcall(function() PB:SetDesiredSizeOverride(FVector2D and FVector2D(100, 6) or {X=100, Y=6}) end)

                    local bUsedSetContent = false
                    pcall(function() if SizeBox_HP.SetContent then SizeBox_HP:SetContent(PB) bUsedSetContent = true end end)
                    if not bUsedSetContent then pcall(function() SizeBox_HP:AddChild(PB) end) end
                    HealthFill = PB
                end
            end
        end
    end)

    local WidgetData = {
        Container = Widget,
        NameText = NameText,
        HealthFill = HealthFill,
        IsGameWidget = true,
        IsOriginalProgressBar = bIsOriginalProgressBar,
        HasChildren = (NameText ~= nil)
    }
    return WidgetData
end

PlayerMapMarker._CanvasScaleX = 1.0
PlayerMapMarker._CanvasScaleY = 1.0
PlayerMapMarker._CanvasOffsetX = 0.0
PlayerMapMarker._CanvasOffsetY = 0.0

function PlayerMapMarker.UpdateCanvasTransform(PC)
    if not PlayerMapMarker.ESPCanvas or not Game:IsValid(PlayerMapMarker.ESPCanvas) then return end
    local success = false
    pcall(function()
        local SBL = SlateBlueprintLibrary
        if SBL and SBL.AbsoluteToLocal then
            local cg = PlayerMapMarker.ESPCanvas:GetCachedGeometry()
            if cg then
                local pt0 = SBL.AbsoluteToLocal(cg, FVector2D and FVector2D(0, 0) or {X=0, Y=0})
                local pt1 = SBL.AbsoluteToLocal(cg, FVector2D and FVector2D(100, 100) or {X=100, Y=100})
                if pt0 and pt1 then
                    PlayerMapMarker._CanvasScaleX = (pt1.X - pt0.X) / 100
                    PlayerMapMarker._CanvasScaleY = (pt1.Y - pt0.Y) / 100
                    PlayerMapMarker._CanvasOffsetX = pt0.X
                    PlayerMapMarker._CanvasOffsetY = pt0.Y
                    success = true
                end
            end
        end
    end)

    if not success then
        pcall(function()
            local WLL = WidgetLayoutLibrary
            if WLL and WLL.ScreenToWidgetLocal then
                local cg = PlayerMapMarker.ESPCanvas:GetCachedGeometry()
                if cg then
                    local pt0 = FVector2D and FVector2D(0, 0) or {X=0, Y=0}
                    local pt1 = FVector2D and FVector2D(0, 0) or {X=0, Y=0}
                    WLL.ScreenToWidgetLocal(PC, cg, FVector2D and FVector2D(0, 0) or {X=0, Y=0}, pt0)
                    WLL.ScreenToWidgetLocal(PC, cg, FVector2D and FVector2D(100, 100) or {X=100, Y=100}, pt1)
                    PlayerMapMarker._CanvasScaleX = (pt1.X - pt0.X) / 100
                    PlayerMapMarker._CanvasScaleY = (pt1.Y - pt0.Y) / 100
                    PlayerMapMarker._CanvasOffsetX = pt0.X
                    PlayerMapMarker._CanvasOffsetY = pt0.Y
                    success = true
                end
            end
        end)
    end

    if not success then
        local scale = 1.0
        local WLL = WidgetLayoutLibrary
        if WLL and WLL.GetViewportScale then scale = WLL.GetViewportScale(PC) or 1.0 end
        PlayerMapMarker._CanvasScaleX = 1.0 / scale
        PlayerMapMarker._CanvasScaleY = 1.0 / scale
        PlayerMapMarker._CanvasOffsetX = 0
        PlayerMapMarker._CanvasOffsetY = 0
    end
end

function PlayerMapMarker.ScreenPixelToCanvasLocal(PC, ScreenPixelPos)
    if not ScreenPixelPos then return FVector2D and FVector2D(0, 0) or {X=0, Y=0} end
    local scaleX = PlayerMapMarker._CanvasScaleX or 1.0
    local scaleY = PlayerMapMarker._CanvasScaleY or 1.0
    local offsetX = PlayerMapMarker._CanvasOffsetX or 0
    local offsetY = PlayerMapMarker._CanvasOffsetY or 0
    return (FVector2D and FVector2D(ScreenPixelPos.X * scaleX + offsetX, ScreenPixelPos.Y * scaleY + offsetY)) or {X = ScreenPixelPos.X * scaleX + offsetX, Y = ScreenPixelPos.Y * scaleY + offsetY}
end

function PlayerMapMarker.ProjectWorldToCanvasLocal(PC, WorldLoc)
    if not IsValid(PC) or not WorldLoc then return false, (FVector2D and FVector2D(0, 0) or {X=0, Y=0}) end
    local ScreenPixelPos = FVector2D and FVector2D(0, 0) or {X=0, Y=0}
    local bOK = false
    pcall(function()
        local res = PC:ProjectWorldLocationToScreen(WorldLoc, ScreenPixelPos, true)
        if res == true or res == 1 or (ScreenPixelPos and (ScreenPixelPos.X ~= 0 or ScreenPixelPos.Y ~= 0)) then bOK = true end
    end)
    if not bOK or not ScreenPixelPos or (ScreenPixelPos.X == 0 and ScreenPixelPos.Y == 0) then return false, (FVector2D and FVector2D(0, 0) or {X=0, Y=0}) end
    local CanvasLocalPos = PlayerMapMarker.ScreenPixelToCanvasLocal(PC, ScreenPixelPos)
    return true, CanvasLocalPos
end

function PlayerMapMarker.GetDynamicViewportSize(PC)
    local width, height = 0, 0
    if PlayerMapMarker.ESPCanvas and Game:IsValid(PlayerMapMarker.ESPCanvas) then
        pcall(function()
            local cg = PlayerMapMarker.ESPCanvas:GetCachedGeometry()
            if cg and cg.GetLocalSize then
                local sz = cg:GetLocalSize()
                if sz and sz.X and sz.X > 200 then width = sz.X height = sz.Y end
            end
        end)
    end
    if width > 200 then return width, height end
    pcall(function()
        local WLL = WidgetLayoutLibrary
        if WLL and WLL.GetViewportSize then
            local sz = WLL.GetViewportSize(PC or PlayerMapMarker.GetMyPlayerController())
            if sz and sz.X and sz.X > 200 then width = sz.X height = sz.Y end
        end
    end)
    if width > 200 then
        pcall(function()
            local WLL = WidgetLayoutLibrary
            if WLL and WLL.GetViewportScale then
                local scale = WLL.GetViewportScale(PC or PlayerMapMarker.GetMyPlayerController())
                if scale and type(scale) == "number" and scale > 0 and scale ~= 1.0 then width = width / scale height = height / scale end
            end
        end)
        return width, height
    end
    return PlayerMapMarker._cachedViewportW or 1920, PlayerMapMarker._cachedViewportH or 1080
end

function PlayerMapMarker.UpdateESPPositionWithPC(Widget, WorldLoc, PC, CanvasPos)
    if not Widget or not IsValid(PC) then return false end
    local Container = Widget.Container or Widget
    local bOnScreen = true
    if not CanvasPos then
        if not WorldLoc then return false end
        bOnScreen, CanvasPos = PlayerMapMarker.ProjectWorldToCanvasLocal(PC, WorldLoc)
    end

    if not bOnScreen then pcall(function() Container:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end) return false end

    pcall(function()
        if PlayerMapMarker.ESPCanvas and Game:IsValid(PlayerMapMarker.ESPCanvas) then
            local ptr = tostring(Container)
            local Slot = PlayerMapMarker.ESPWidgetPtrs[ptr]

            if not Slot or not slua.isValid(Slot) or type(Slot) == "boolean" then
                local addedSlot = PlayerMapMarker.ESPCanvas:AddChildToCanvas(Container)
                if addedSlot and slua.isValid(addedSlot) then
                    Slot = addedSlot
                    PlayerMapMarker.ESPWidgetPtrs[ptr] = addedSlot
                    if type(Widget) == "table" then Widget.Slot = addedSlot end
                    pcall(function() Slot:SetAutoSize(true) end)
                    pcall(function() Slot.bAutoSize = true end)
                    local align = FVector2D and FVector2D(0.5, 1.0) or {X=0.5, Y=1.0}
                    pcall(function() Slot.Alignment = align end)
                    pcall(function() Slot:SetAlignment(align) end)
                    pcall(function() Slot:SetAlignment(0.5, 1.0) end)
                    pcall(function() Slot:SetZOrder(PlayerMapMarker.ESPWidgetZOrder or 20) end)
                end
            end

            -- [FIX VIP] Xóa vệt đen trên đầu khi tắt hết UI
            local bShowAnyUI = _G.AHMADConfig.Esp9_Name or _G.AHMADConfig.Esp9_Distance or _G.AHMADConfig.Esp9_HP or _G.AHMADConfig.Esp9_Team or _G.AHMADConfig.Esp9_Weapon
            if bShowAnyUI then
                Container:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
            else
                Container:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
            end
            
            if not Widget._OffsetResetDone then
                pcall(function() Container:SetRenderTranslation(FVector2D and FVector2D(0.0, 0.0) or {X=0, Y=0}) end)
                
                -- [SIZE 85% UI UE4] Tăng size to hơn một chút cho dễ nhìn (Gốc là 1.0, cũ là 0.7)
                pcall(function() Container:SetRenderScale(FVector2D and FVector2D(0.90, 0.90) or {X=0.90, Y=0.90}) end)
                
                if Widget and type(Widget) == "table" then
                    if Widget.NameText and slua.isValid(Widget.NameText) then pcall(function() Widget.NameText:SetRenderTranslation(FVector2D and FVector2D(0.0, 0.0) or {X=0, Y=0}) end) end
                    if Widget.HealthFill and slua.isValid(Widget.HealthFill) then pcall(function() Widget.HealthFill:SetRenderTranslation(FVector2D and FVector2D(0.0, 0.0) or {X=0, Y=0}) end) end
                end
                pcall(function() Container.RenderTransformPivot = FVector2D and FVector2D(0.5, 1.0) or {X=0.5, Y=1.0} end)
                pcall(function() Container:SetRenderTransformPivot(FVector2D and FVector2D(0.5, 1.0) or {X=0.5, Y=1.0}) end)
                Widget._OffsetResetDone = true
            end

            if not Slot or not slua.isValid(Slot) or Slot == PlayerMapMarker.ESPCanvas then
                if Widget and type(Widget) == "table" and Widget.Slot and slua.isValid(Widget.Slot) then Slot = Widget.Slot
                elseif Container.Slot and slua.isValid(Container.Slot) then Slot = Container.Slot end
            end

            if Slot and slua.isValid(Slot) and Slot ~= PlayerMapMarker.ESPCanvas then
                local finalX = CanvasPos.X + (PlayerMapMarker.ESPAnchorOffsetX or 0)
                local finalY = CanvasPos.Y + (PlayerMapMarker.ESPAnchorOffsetY or 0)
                if Widget and type(Widget) == "table" then
                    if not Widget._CachedPosVec then Widget._CachedPosVec = FVector2D and FVector2D(finalX, finalY) or {X=finalX, Y=finalY}
                    else Widget._CachedPosVec.X = finalX Widget._CachedPosVec.Y = finalY end
                    pcall(function() Slot:SetPosition(Widget._CachedPosVec) end)
                else
                    pcall(function() Slot:SetPosition(FVector2D and FVector2D(finalX, finalY) or {X=finalX, Y=finalY}) end)
                end
            end
        end
    end)
    return true
end

function PlayerMapMarker.UpdateESPText(Widget, Text)
    if not Widget then return end
    if Widget._LastESPText == Text then return end
    Widget._LastESPText = Text

    local function applyTextAndCenter(w, txt)
        if not w or not slua.isValid(w) then return end
        
        -- Nếu chữ rỗng (do người chơi đã tắt Tên & Khoảng cách) thì ẨN Widget đi
        if txt == "" then
            pcall(function() w:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
            return
        else
            pcall(function() w:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
        end

        pcall(function() w:SetText(txt) end)
        -- ÉP MÀU CAM CHO CHỮ & SỐ MÉT 
        pcall(function()
            local FSlateColor = import("SlateColor") or import("/Script/SlateCore.SlateColor")
            local orangeColor = FLinearColor and FLinearColor(1.0, 1.0, 1.0, 1.0) or {R=255, G=255, B=255, A=255}
            if w.SetColorAndOpacity then
                if FSlateColor then w:SetColorAndOpacity(FSlateColor(orangeColor)) else w:SetColorAndOpacity(orangeColor) end
            end
        end)
        pcall(function() if w.SetJustification then w:SetJustification(1) end end)
        pcall(function() local slot = w.Slot if slot and slot.SetHorizontalAlignment then slot:SetHorizontalAlignment(1) end end)
        pcall(function() w:SetRenderTranslation(FVector2D and FVector2D(PlayerMapMarker.ESPTextOffsetX or 0, PlayerMapMarker.ESPTextOffsetY or 0) or {X=PlayerMapMarker.ESPTextOffsetX or 0, Y=PlayerMapMarker.ESPTextOffsetY or 0}) end)
    end

    if Widget.NameText and slua.isValid(Widget.NameText) then applyTextAndCenter(Widget.NameText, Text) end
    if Widget.IsGameWidget and Widget.Container then
        pcall(function()
            local W = Widget.Container
            if W and slua.isValid(W) then
                if W.SetPlayerName then
                    local Name = Text
                    local idx = string.find(Text, " %[")
                    if idx then Name = string.sub(Text, 1, idx - 1) end
                    W:SetPlayerName(Name)
                end
                applyTextAndCenter(W.TextBlock_TeamName, Text)
                applyTextAndCenter(W.TextBlock_PlayerName, Text)

                pcall(function()
                    if not Widget._CachedVBChildren then
                        local list = {}
                        local VB = PlayerMapMarker._FindNamedWidgetInTree(W, "VerticalBox_0", 8)
                        if VB and slua.isValid(VB) and VB.GetChildrenCount then
                            local nChildren = VB:GetChildrenCount()
                            for i = 0, nChildren - 1 do
                                local child = VB:GetChildAt(i)
                                if child and slua.isValid(child) and child.SetText then table.insert(list, child) end
                            end
                        end
                        Widget._CachedVBChildren = list
                    end
                    for _, child in ipairs(Widget._CachedVBChildren) do applyTextAndCenter(child, Text) end
                end)

                pcall(function()
                    if not Widget._CachedHBChildren then
                        local list = {}
                        local HB = PlayerMapMarker._FindNamedWidgetInTree(W, "HorizontalBox_TeamName", 8)
                        if HB and slua.isValid(HB) and HB.GetChildrenCount then
                            local nChildren = HB:GetChildrenCount()
                            for i = 0, nChildren - 1 do
                                local child = HB:GetChildAt(i)
                                if child and slua.isValid(child) and child.SetText then table.insert(list, child) end
                            end
                        end
                        Widget._CachedHBChildren = list
                    end
                    for _, child in ipairs(Widget._CachedHBChildren) do applyTextAndCenter(child, Text) end
                end)
            end
        end)
    end
end

function PlayerMapMarker.UpdateESPHealth(Widget, pct)
    if not Widget then return end
    -- Xóa dòng Cache LastPct để nó ép update liên tục khi bạn gạt công tắc
    Widget.LastPct = pct

    local bShowHP = _G.AHMADConfig.Esp9_HP

    if PlayerMapMarker.bForceSwitcherIndexEveryUpdate and Widget.Container then
        pcall(function()
            local W = Widget.Container
            if W and slua.isValid(W) then
                if W.WidgetSwitcher_Type and slua.isValid(W.WidgetSwitcher_Type) then pcall(function() if W.WidgetSwitcher_Type.SetActiveWidgetIndex then W.WidgetSwitcher_Type:SetActiveWidgetIndex(PlayerMapMarker.HPWidgetSwitcherTypeIndex) end end) end
                if W.WidgetSwitcher_Type2 and slua.isValid(W.WidgetSwitcher_Type2) then pcall(function() if W.WidgetSwitcher_Type2.SetActiveWidgetIndex then W.WidgetSwitcher_Type2:SetActiveWidgetIndex(PlayerMapMarker.HPWidgetSwitcherType2Index) end end) end
                
                -- Cập nhật ẩn/hiện Box chứa thanh máu
                if W.SizeBox_HP and slua.isValid(W.SizeBox_HP) then 
                    if bShowHP then
                        W.SizeBox_HP:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                    else
                        W.SizeBox_HP:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
                    end
                end
            end
        end)
    end

    -- Chặn đoạn code cập nhật màu bên dưới nếu công tắc tắt
    if not bShowHP then return end

    if Widget.HealthFill then
        local bValid = false
        pcall(function() bValid = slua.isValid(Widget.HealthFill) end)
        if bValid then
            local bHasSetPercent = false
            pcall(function() bHasSetPercent = (Widget.HealthFill.SetPercent ~= nil) end)
            if not bHasSetPercent then
                local PB = PlayerMapMarker.FindProgressBarInWidget(Widget.HealthFill, 0, 5)
                if PB and slua.isValid(PB) then Widget.HealthFill = PB else return end
            end

            pcall(function()
                if Widget.HealthFill.SetWidgetVisibility then Widget.HealthFill:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end
                if Widget.HealthFill.SetRenderOpacity then Widget.HealthFill:SetRenderOpacity(1.0) end
                if Widget.HealthFill.SetPercent then
                    Widget.HealthFill:SetPercent(pct)
                    
                    -- [FIX VIP] Xóa bỏ rào cản IsOriginalProgressBar để ÉP MÀU mọi lúc
                    local color
                    if pct > 0.5 then 
                        -- Máu nhiều: Xanh Lá Cây
                        color = FLinearColor and FLinearColor(0.0, 1.0, 0.0, 1.0) or {R=0,G=255,B=0,A=255}
                    elseif pct > 0.25 then 
                        -- Nửa máu: Cam/Vàng
                        color = FLinearColor and FLinearColor(1.0, 0.5, 0.0, 1.0) or {R=255,G=128,B=0,A=255}
                    else 
                        -- Yếu máu: Đỏ
                        color = FLinearColor and FLinearColor(1.0, 0.0, 0.0, 1.0) or {R=255,G=0,B=0,A=255} 
                    end
                    
                    -- 1. Ép màu bằng hàm chuẩn
                    if Widget.HealthFill.SetFillColorAndOpacity then 
                        Widget.HealthFill:SetFillColorAndOpacity(color) 
                    end
                    
                    -- 2. Ép màu sâu vào Style (Khắc phục triệt để lỗi màu trắng xám của UI gốc UE4)
                    pcall(function()
                        if Widget.IsOriginalProgressBar then
                            local style = Widget.HealthFill.WidgetStyle
                            if style and style.FillImage then
                                style.FillImage.TintColor = color
                                Widget.HealthFill:SetWidgetStyle(style)
                            end
                        end
                    end)
                end
            end)
        end
        return
    end
end

function PlayerMapMarker.RemoveESPWidget(Widget, KeyStr)
    if not Widget then return end
    local Container = Widget.Container or Widget
    pcall(function()
        local ptr = tostring(Container)
        PlayerMapMarker.ESPWidgetPtrs[ptr] = nil
        Container:RemoveFromParent()
        Container:ConditionalBeginDestroy()
    end)
    if KeyStr then
        PlayerMapMarker.RemoveSnapLine(KeyStr)
        if PlayerMapMarker.RemoveSkeletonLines then
            PlayerMapMarker.RemoveSkeletonLines(KeyStr)
        end
    end
end

function PlayerMapMarker.CreateSnapLine()
    if not PlayerMapMarker.ESPCanvas or not Game:IsValid(PlayerMapMarker.ESPCanvas) then return nil end
    local Border = nil
    pcall(function() Border = CGame:NewObjectFromPath("/Script/UMG.Border", PlayerMapMarker.ESPCanvas) end)
    if not Border or not slua.isValid(Border) then return nil end

    local color = PlayerMapMarker.SnapLineColor or (FLinearColor and FLinearColor(1.0, 1.0, 1.0, PlayerMapMarker.SnapLineOpacity or 0.7) or {R=1,G=1,B=1,A=PlayerMapMarker.SnapLineOpacity or 0.7})
    pcall(function() Border:SetBrushColor(color) end)
    pcall(function() Border:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
    pcall(function() Border.RenderTransformPivot = FVector2D and FVector2D(0.0, 0.5) or {X=0,Y=0.5} end)
    pcall(function() Border:SetRenderTransformPivot(FVector2D and FVector2D(0.0, 0.5) or {X=0,Y=0.5}) end)

    local Slot = nil
    pcall(function()
        Slot = PlayerMapMarker.ESPCanvas:AddChildToCanvas(Border)
        if Slot then Slot:SetAutoSize(false) Slot:SetZOrder(1) end
    end)
    return { Widget = Border, Slot = Slot }
end

function PlayerMapMarker.GetSnapLineStartPos(PC)
    local screenPixelW, screenPixelH = 0, 0
    local scale = 1.0

    pcall(function()
        if PC and PC.GetViewportSize then
            local vs = FVector2D and FVector2D(0, 0) or {X=0,Y=0}
            PC:GetViewportSize(vs)
            if vs and vs.X and vs.X > 200 then screenPixelW = vs.X screenPixelH = vs.Y end
        end
    end)
    if screenPixelW <= 200 then
        pcall(function()
            local WLL = WidgetLayoutLibrary
            if WLL and WLL.GetViewportSize then
                local vs = WLL.GetViewportSize(PC)
                if vs and vs.X and vs.X > 200 then screenPixelW = vs.X screenPixelH = vs.Y end
            end
        end)
    end
    pcall(function()
        local WLL = WidgetLayoutLibrary
        if WLL and WLL.GetViewportScale then
            local s = WLL.GetViewportScale(PC)
            if s and type(s) == "number" and s > 0 then scale = s end
        end
    end)
    if screenPixelW <= 200 then
        screenPixelW = (PlayerMapMarker._cachedViewportW or 1920) * scale
        screenPixelH = (PlayerMapMarker._cachedViewportH or 1080) * scale
    end

    if not PlayerMapMarker._CachedTopCenterPixel then PlayerMapMarker._CachedTopCenterPixel = FVector2D and FVector2D(0, 0) or {X=0,Y=0} end
    PlayerMapMarker._CachedTopCenterPixel.X = screenPixelW / 2.0
    PlayerMapMarker._CachedTopCenterPixel.Y = (PlayerMapMarker.SnapLineOriginY or 50) * scale

    local fromCanvasPos = PlayerMapMarker.ScreenPixelToCanvasLocal(PC, PlayerMapMarker._CachedTopCenterPixel)
    local fromX = fromCanvasPos.X + (PlayerMapMarker.SnapLineOriginOffsetX or 0)
    local fromY = fromCanvasPos.Y

    return fromX, fromY
end

function PlayerMapMarker.UpdateSnapLine(KeyStr, CanvasPos, bOnScreen, fromX, fromY)
    if not PlayerMapMarker.bUseSnapLines then return end
    if not PlayerMapMarker.ESPCanvas or not Game:IsValid(PlayerMapMarker.ESPCanvas) then return end

    local LineData = PlayerMapMarker.SnapLineWidgets[KeyStr]

    if not bOnScreen or not CanvasPos then
        if LineData and LineData.Widget and slua.isValid(LineData.Widget) then
            pcall(function() LineData.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
        end
        return
    end

    local bIsNew = false
    if not LineData then
        LineData = PlayerMapMarker.CreateSnapLine()
        if not LineData or not LineData.Widget or not LineData.Slot then return end
        PlayerMapMarker.SnapLineWidgets[KeyStr] = LineData
        bIsNew = true
    end

    local Widget = LineData.Widget
    local Slot = LineData.Slot

    pcall(function() Widget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
    
    if not LineData._PivotSet then
        pcall(function() Widget.RenderTransformPivot = FVector2D and FVector2D(0.0, 0.5) or {X=0,Y=0.5} end)
        pcall(function() Widget:SetRenderTransformPivot(FVector2D and FVector2D(0.0, 0.5) or {X=0,Y=0.5}) end)
        LineData._PivotSet = true
    end

    local toX = CanvasPos.X + (PlayerMapMarker.SnapLineHeadOffsetX or 0)
    local toY = CanvasPos.Y + (PlayerMapMarker.SnapLineHeadOffsetY or 0)
    local dx = toX - fromX
    local dy = toY - fromY
    local length = math.sqrt(dx * dx + dy * dy)
    local thickness = PlayerMapMarker.SnapLineThickness or 1.5

    local angle_rad = 0
    if math.atan2 then angle_rad = math.atan2(dy, dx) else angle_rad = math.atan(dy, dx) end
    local angle = angle_rad * (180.0 / math.pi)

    if not LineData._CachedPosVec then
        LineData._CachedPosVec = FVector2D and FVector2D(fromX, fromY - thickness / 2.0) or {X=fromX, Y=fromY - thickness / 2.0}
        LineData._CachedSizeVec = FVector2D and FVector2D(length, thickness) or {X=length, Y=thickness}
    else
        LineData._CachedPosVec.X = fromX ; LineData._CachedPosVec.Y = fromY - thickness / 2.0
        LineData._CachedSizeVec.X = length ; LineData._CachedSizeVec.Y = thickness
    end

    pcall(function() 
        Slot:SetPosition(LineData._CachedPosVec) 
        Slot:SetSize(LineData._CachedSizeVec)
        if bIsNew then Slot:SetZOrder(1) end
    end)
    pcall(function() Widget:SetRenderAngle(angle) end)
end

function PlayerMapMarker.RemoveSnapLine(KeyStr)
    local LineData = PlayerMapMarker.SnapLineWidgets[KeyStr]
    if LineData and LineData.Widget and slua.isValid(LineData.Widget) then
        pcall(function() LineData.Widget:RemoveFromParent() LineData.Widget:ConditionalBeginDestroy() end)
        PlayerMapMarker.SnapLineWidgets[KeyStr] = nil
    end
end

function PlayerMapMarker.ClearAllSnapLines()
    for KeyStr, LineData in pairs(PlayerMapMarker.SnapLineWidgets) do
        if LineData and LineData.Widget and slua.isValid(LineData.Widget) then
            pcall(function() LineData.Widget:RemoveFromParent() LineData.Widget:ConditionalBeginDestroy() end)
        end
    end
    PlayerMapMarker.SnapLineWidgets = {}
end

-- ====== BẮT ĐẦU: LOGIC SKELETON TỪ CODE MẪU ======
function PlayerMapMarker.ScreenPixelToCanvasLocalRaw(PC, screenX, screenY)
    local scaleX = PlayerMapMarker._CanvasScaleX or 1.0
    local scaleY = PlayerMapMarker._CanvasScaleY or 1.0
    local offsetX = PlayerMapMarker._CanvasOffsetX or 0
    local offsetY = PlayerMapMarker._CanvasOffsetY or 0
    return screenX * scaleX + offsetX, screenY * scaleY + offsetY
end

function PlayerMapMarker.ProjectWorldToCanvasLocalRaw(PC, WorldLoc)
    if not IsValid(PC) or not WorldLoc then return false, 0, 0 end
    if not PlayerMapMarker._tempScreenPixelPos then
        PlayerMapMarker._tempScreenPixelPos = FVector2D and FVector2D(0, 0) or {X=0, Y=0}
    end
    local tempPos = PlayerMapMarker._tempScreenPixelPos
    local bOK = false
    pcall(function()
        local res = PC:ProjectWorldLocationToScreen(WorldLoc, tempPos, true)
        if res == true or res == 1 then bOK = true end
    end)
    if not bOK or (tempPos.X == 0 and tempPos.Y == 0) then return false, 0, 0 end
    local canvasX, canvasY = PlayerMapMarker.ScreenPixelToCanvasLocalRaw(PC, tempPos.X, tempPos.Y)
    return true, canvasX, canvasY
end

function PlayerMapMarker.GetBoneLocationWithFallback(Character, PrimaryBoneName)
    if not IsValid(Character) or not PrimaryBoneName then return nil end
    if Character._cachedBoneNames and Character._cachedBoneNames[PrimaryBoneName] then
        local cachedName = Character._cachedBoneNames[PrimaryBoneName]
        local loc = nil
        pcall(function()
            local Mesh = PlayerMapMarker.GetCharacterMesh(Character)
            if Mesh and Game:IsValid(Mesh) then
                if Mesh.GetSocketLocation then loc = Mesh:GetSocketLocation(cachedName)
                elseif Mesh.GetBoneLocation then loc = Mesh:GetBoneLocation(cachedName) end
            end
        end)
        if loc then return loc end
    end
    local fallbacks = PlayerMapMarker.BoneNameFallbacks[PrimaryBoneName] or {PrimaryBoneName}
    for _, bname in ipairs(fallbacks) do
        local loc = nil
        pcall(function()
            local Mesh = PlayerMapMarker.GetCharacterMesh(Character)
            if Mesh and Game:IsValid(Mesh) then
                if Mesh.GetSocketLocation then loc = Mesh:GetSocketLocation(bname)
                elseif Mesh.GetBoneLocation then loc = Mesh:GetBoneLocation(bname) end
            end
        end)
        if loc then
            if not Character._cachedBoneNames then Character._cachedBoneNames = {} end
            Character._cachedBoneNames[PrimaryBoneName] = bname
            return loc
        end
    end
    return nil
end

function PlayerMapMarker.IsPlayerVisible(PC, Character)
    if not IsValid(PC) or not IsValid(Character) then return false end
    local now = os.clock()
    if Character._lastVisTime and (now - Character._lastVisTime) < 0.25 then
        return Character._cachedIsVisible or false
    end
    Character._lastVisTime = now
    local bVis = false
    pcall(function()
        if PC.LineOfSightTo then
            if not PlayerMapMarker._ZeroVector then
                local VT = FVector or import("/Script/CoreUObject.Vector")
                if VT then PlayerMapMarker._ZeroVector = VT(0, 0, 0) end
            end
            bVis = PC:LineOfSightTo(Character, PlayerMapMarker._ZeroVector, false)
        end
    end)
    if not bVis then
        local KismetSystemLibrary = import("KismetSystemLibrary")
        if KismetSystemLibrary and KismetSystemLibrary.LineTraceSingle then
            pcall(function()
                local camMgr = nil
                local GameplayStatics = import("GameplayStatics")
                if GameplayStatics and GameplayStatics.GetPlayerCameraManager then
                    camMgr = GameplayStatics.GetPlayerCameraManager(PC, 0)
                end
                local startLoc = camMgr and camMgr:GetCameraLocation() or PlayerMapMarker.GetMyLocation()
                local headLoc = PlayerMapMarker.GetBoneLocationWithFallback(Character, "head")
                if startLoc and headLoc then
                    if not PlayerMapMarker._CachedHitResult then
                        local HitResultClass = import("HitResult") or import("/Script/Engine.HitResult")
                        PlayerMapMarker._CachedHitResult = HitResultClass and HitResultClass() or {}
                    end
                    local bHit = KismetSystemLibrary.LineTraceSingle(PC, startLoc, headLoc, 0, false, nil, 0, PlayerMapMarker._CachedHitResult, true)
                    if bHit then
                        local hitActor = nil
                        if type(PlayerMapMarker._CachedHitResult.GetActor) == "function" then hitActor = PlayerMapMarker._CachedHitResult:GetActor()
                        elseif PlayerMapMarker._CachedHitResult.Actor then hitActor = PlayerMapMarker._CachedHitResult.Actor end
                        if hitActor and (hitActor == Character or (type(hitActor.IsChildOf) == "function" and hitActor:IsChildOf(Character))) then
                            bVis = true
                        end
                    else
                        bVis = true
                    end
                end
            end)
        end
    end
    Character._cachedIsVisible = bVis
    return bVis
end

function PlayerMapMarker.CreateSkeletonLineWidget()
    if not PlayerMapMarker.ESPCanvas or not Game:IsValid(PlayerMapMarker.ESPCanvas) then return nil end
    local Border = nil
    pcall(function() Border = CGame:NewObjectFromPath("/Script/UMG.Border", PlayerMapMarker.ESPCanvas) end)
    if not Border or not slua.isValid(Border) then return nil end
    pcall(function() Border.RenderTransformPivot = FVector2D and FVector2D(0.0, 0.5) or {X=0, Y=0.5} end)
    pcall(function() Border:SetRenderTransformPivot(FVector2D and FVector2D(0.0, 0.5) or {X=0, Y=0.5}) end)
    local Slot = nil
    pcall(function()
        Slot = PlayerMapMarker.ESPCanvas:AddChildToCanvas(Border)
        if Slot then Slot:SetAutoSize(false) Slot:SetZOrder(5) end
    end)
    return { 
        Widget = Border, Slot = Slot,
        posVec = FVector2D and FVector2D(0, 0) or {X=0, Y=0},
        sizeVec = FVector2D and FVector2D(0, 0) or {X=0, Y=0},
        lastFromX = -99999, lastFromY = -99999,
        lastToX = -99999, lastToY = -99999
    }
end

function PlayerMapMarker.UpdateSkeletonLines(KeyStr, Character, PC, bVisible, TeamColor, bPlayerOnScreen, charLoc)
    if not PlayerMapMarker.bUseSkeleton then return end
    if not PlayerMapMarker.ESPCanvas or not Game:IsValid(PlayerMapMarker.ESPCanvas) then return end
    local PlayerBones = PlayerMapMarker.SkeletonWidgets[KeyStr]
    if not bVisible or not IsValid(Character) or not IsValid(PC) then
        if PlayerBones then
            for _, LineData in ipairs(PlayerBones) do
                if LineData and LineData.Widget and slua.isValid(LineData.Widget) then
                    LineData.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
                    LineData.Widget._isSelfHitTestVisible = false
                end
            end
        end
        return
    end

    if not charLoc then charLoc = PlayerMapMarker.GetESPLocation(Character) end
    if not charLoc then return end

    if bPlayerOnScreen == nil then
        local bOnScreen, _, _ = PlayerMapMarker.ProjectWorldToCanvasLocalRaw(PC, charLoc)
        bPlayerOnScreen = bOnScreen
    end
    if not bPlayerOnScreen then
        if PlayerBones then
            for _, LineData in ipairs(PlayerBones) do
                if LineData and LineData.Widget and slua.isValid(LineData.Widget) then
                    LineData.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
                    LineData.Widget._isSelfHitTestVisible = false
                end
            end
        end
        return
    end

    local dist = 0
    local myLoc = PlayerMapMarker._CachedMyLoc or PlayerMapMarker.GetMyLocation()
    if myLoc and charLoc then
        local dx = (charLoc.X or 0) - (myLoc.X or 0)
        local dy = (charLoc.Y or 0) - (myLoc.Y or 0)
        local dz = (charLoc.Z or 0) - (myLoc.Z or 0)
        dist = math.sqrt(dx * dx + dy * dy + dz * dz)
    end

    if PlayerMapMarker.SkeletonMaxDistance and PlayerMapMarker.SkeletonMaxDistance > 0 then
        if dist > PlayerMapMarker.SkeletonMaxDistance then
            if PlayerBones then
                for _, LineData in ipairs(PlayerBones) do
                    if LineData and LineData.Widget and slua.isValid(LineData.Widget) then
                        LineData.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
                        LineData.Widget._isSelfHitTestVisible = false
                    end
                end
            end
            return
        end
    end

    if not PlayerBones then
        PlayerBones = {}
        PlayerMapMarker.SkeletonWidgets[KeyStr] = PlayerBones
    end

    local lineColor = nil
    if PlayerMapMarker.bUseVisibilityColor then
        local bTargetVisible = PlayerMapMarker.IsPlayerVisible(PC, Character)
        if bTargetVisible then lineColor = PlayerMapMarker.SkeletonVisibleColor or FLinearColor(0.0, 1.0, 0.0, 0.8)
        else lineColor = PlayerMapMarker.SkeletonCoverColor or FLinearColor(0.9, 0.0, 0.0, 0.6) end
    else
        lineColor = PlayerMapMarker.SkeletonColor or TeamColor or FLinearColor(1.0, 1.0, 1.0, PlayerMapMarker.SkeletonOpacity or 0.8)
    end

    local cache = PlayerMapMarker._StaticBoneLocCache
    for k in pairs(cache) do cache[k] = nil end
    local lineIndex = 0
    local thickness = PlayerMapMarker.SkeletonThickness or 1.2
    if not Character._cachedBones3D then Character._cachedBones3D = {} end

    for _, chain in ipairs(PlayerMapMarker.SkeletonChains) do
        local lastCanvasX, lastCanvasY = nil, nil
        for _, boneName in ipairs(chain) do
            local boneWorldLoc = cache[boneName]
            if boneWorldLoc == nil then
                boneWorldLoc = PlayerMapMarker.GetBoneLocationWithFallback(Character, boneName) or false
                cache[boneName] = boneWorldLoc
            end
            if boneWorldLoc == false then boneWorldLoc = nil end

            local currentCanvasX, currentCanvasY = nil, nil
            if boneWorldLoc then
                local bOnScreen, cX, cY = PlayerMapMarker.ProjectWorldToCanvasLocalRaw(PC, boneWorldLoc)
                if bOnScreen then
                    currentCanvasX = cX
                    currentCanvasY = cY
                end
            end

            if lastCanvasX and currentCanvasX then
                lineIndex = lineIndex + 1
                local LineData = PlayerBones[lineIndex]
                if not LineData or not LineData.Widget or not slua.isValid(LineData.Widget) then
                    LineData = PlayerMapMarker.CreateSkeletonLineWidget()
                    if LineData then PlayerBones[lineIndex] = LineData end
                end

                if LineData and LineData.Widget and LineData.Slot then
                    local Widget = LineData.Widget
                    local Slot = LineData.Slot

                    if Widget._cachedColor ~= lineColor then
                        Widget:SetBrushColor(lineColor)
                        Widget._cachedColor = lineColor
                    end
                    if not Widget._isSelfHitTestVisible then
                        Widget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                        Widget._isSelfHitTestVisible = true
                    end

                    local fromX = lastCanvasX
                    local fromY = lastCanvasY
                    local toX = currentCanvasX
                    local toY = currentCanvasY

                    local threshold = 0.15
                    if dist > 8000 then threshold = 0.8 elseif dist > 4000 then threshold = 0.4 end

                    if math.abs(fromX - LineData.lastFromX) > threshold or
                       math.abs(fromY - LineData.lastFromY) > threshold or
                       math.abs(toX - LineData.lastToX) > threshold or
                       math.abs(toY - LineData.lastToY) > threshold then

                        LineData.lastFromX = fromX
                        LineData.lastFromY = fromY
                        LineData.lastToX = toX
                        LineData.lastToY = toY

                        local dx = toX - fromX
                        local dy = toY - fromY
                        local length = math.sqrt(dx * dx + dy * dy)
                        local angle_rad = (math.atan2 and math.atan2(dy, dx)) or math.atan(dy, dx)
                        local angle = angle_rad * 57.29577951308232

                        local pVec = LineData.posVec
                        pVec.X = fromX ; pVec.Y = fromY - thickness / 2.0
                        Slot:SetPosition(pVec)

                        local sVec = LineData.sizeVec
                        sVec.X = length ; sVec.Y = thickness
                        Slot:SetSize(sVec)
                        Widget:SetRenderAngle(angle)
                    end
                end
            end
            lastCanvasX = currentCanvasX
            lastCanvasY = currentCanvasY
        end
    end

    for i = lineIndex + 1, #PlayerBones do
        local LineData = PlayerBones[i]
        if LineData and LineData.Widget and slua.isValid(LineData.Widget) then
            LineData.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
            LineData.Widget._isSelfHitTestVisible = false
        end
    end
end

function PlayerMapMarker.RemoveSkeletonLines(KeyStr)
    local PlayerBones = PlayerMapMarker.SkeletonWidgets[KeyStr]
    if PlayerBones then
        for _, LineData in ipairs(PlayerBones) do
            if LineData and LineData.Widget and slua.isValid(LineData.Widget) then
                pcall(function()
                    LineData.Widget:RemoveFromParent()
                    LineData.Widget:ConditionalBeginDestroy()
                end)
            end
        end
        PlayerMapMarker.SkeletonWidgets[KeyStr] = nil
    end
end

function PlayerMapMarker.ClearAllSkeletonLines()
    for KeyStr, PlayerBones in pairs(PlayerMapMarker.SkeletonWidgets) do
        for _, LineData in ipairs(PlayerBones) do
            if LineData and LineData.Widget and slua.isValid(LineData.Widget) then
                pcall(function()
                    LineData.Widget:RemoveFromParent()
                    LineData.Widget:ConditionalBeginDestroy()
                end)
            end
        end
    end
    PlayerMapMarker.SkeletonWidgets = {}
end
-- ====== KẾT THÚC: LOGIC SKELETON ======

function PlayerMapMarker.ClearAllESP()
    RedBoxOverlay.Stop()
    for KeyStr, Data in pairs(PlayerMapMarker.ESPWidgets) do
        PlayerMapMarker.RemoveESPWidget(Data.Widget, KeyStr)
    end
    PlayerMapMarker.ESPWidgets = {}
    PlayerMapMarker.ESPWidgetPtrs = {}
    PlayerMapMarker.ClearAllSnapLines()
    PlayerMapMarker.ClearAllSkeletonLines()
    if PlayerMapMarker.ESPCanvas and Game:IsValid(PlayerMapMarker.ESPCanvas) then
        pcall(function()
            local n = PlayerMapMarker.ESPCanvas:GetChildrenCount()
            for i = n - 1, 0, -1 do
                local child = PlayerMapMarker.ESPCanvas:GetChildAt(i)
                if child and slua.isValid(child) then
                    if PlayerMapMarker.IsOurESPWidget(child) then PlayerMapMarker.ESPCanvas:RemoveChild(child) end
                end
            end
        end)
    end
    PlayerMapMarker.ESPCanvas = nil
    PlayerMapMarker._OBHeadWidgetClass = nil
    PlayerMapMarker._OBHeadWidgetLoadFailed = false
    PlayerMapMarker._bDumpedWidgetChildren = false
    PlayerMapMarker._cachedViewportW = 1920
    PlayerMapMarker._cachedViewportH = 1080
end

function PlayerMapMarker.UpdateESP(AllPlayers, MyLoc)
    if not PlayerMapMarker.bUseScreenESP then return end
    
    -- Đồng bộ Config Dây và Xương
    PlayerMapMarker.bUseSnapLines = _G.AHMADConfig.Esp9_Line
    PlayerMapMarker.bUseSkeleton = _G.AHMADConfig.Esp9_Skeleton

    if not PlayerMapMarker.InitESPCanvas() then
        return
    end

    if PlayerMapMarker._OBHeadWidgetLoadFailed then return end

    local PC = PlayerMapMarker.GetMyPlayerController()
    if IsValid(PC) then
        PlayerMapMarker.UpdateCanvasTransform(PC)
    end

    local fromX, fromY = 0, 0
    if PlayerMapMarker.bUseSnapLines and IsValid(PC) then
        fromX, fromY = PlayerMapMarker.GetSnapLineStartPos(PC)
    end

    local MyKey = PlayerMapMarker.GetMyPlayerKey()
    local SeenKeys = {}
    
    local MyChar = nil
    pcall(function()
        local GDP = PlayerMapMarker.GetGameplayData()
        if GDP and GDP.GetLocalCharacter then
            MyChar = GDP.GetLocalCharacter()
        else
            if PC and PC.GetPawn then MyChar = PC:GetPawn() end
        end
    end)
    local MyTeamID = PlayerMapMarker.GetTeamID(MyChar)

    for PlayerKey, Character in pairs(AllPlayers) do
        if IsValid(Character) then
            local bIsMe = PlayerMapMarker.IsMe(Character, PlayerKey, MyKey)
            local bIsAI = PlayerMapMarker.IsAI(Character)
            local KeyStr = tostring(PlayerKey)
            local Name = PlayerMapMarker.GetPlayerName(Character)

            local Loc = PlayerMapMarker.GetESPLocation(Character)

            local DistStr = ""
            if MyLoc and Loc then
                DistStr = PlayerMapMarker.GetDistanceString(MyLoc, Loc)
            end

            local bSkip = false
            if bIsMe and not PlayerMapMarker.bIncludeMe then bSkip = true end
            if bIsAI and not PlayerMapMarker.bIncludeAI then bSkip = true end
            
            local TeamID = PlayerMapMarker.GetTeamID(Character)
            if MyTeamID ~= nil and TeamID == MyTeamID and not bIsMe then
                bSkip = true
            end

            local bIsAlive = PlayerMapMarker.IsAlive(Character)

            if not bSkip and Loc then
                SeenKeys[KeyStr] = true
                local ESPData = PlayerMapMarker.ESPWidgets[KeyStr]

                -- [THÊM MỚI] Check Bật Tắt Tên và Khoảng Cách
                local Text = ""
                if _G.AHMADConfig.Esp9_Name then Text = Name end
                if _G.AHMADConfig.Esp9_Distance and DistStr and DistStr ~= "" then
                    if Text ~= "" then Text = string.format("%s [%s]", Text, DistStr) else Text = string.format("[%s]", DistStr) end
                end

                local bOnScreen, CanvasPos = PlayerMapMarker.ProjectWorldToCanvasLocal(PC, Loc)

                if not ESPData then
                    local Widget = PlayerMapMarker.CreateESPWidget()
                    if Widget then
                        PlayerMapMarker.ESPWidgets[KeyStr] = {
                            Widget = Widget,
                            Character = Character,
                            Name = Name,
                            LastDistStr = DistStr,
                            TeamID = TeamID,
                        }
                        PlayerMapMarker.UpdateESPText(Widget, Text)
                        if bIsAlive then
                            PlayerMapMarker.UpdateESPPositionWithPC(Widget, Loc, PC, CanvasPos)
                            PlayerMapMarker.ApplyTeamColor(Widget, TeamID)
                            local HP = Character.Health or 0
                            local MaxHP = Character.MaxHealth or 120
                            local pct = 0
                            if HP > 0 and MaxHP > 0 then
                                pct = HP / MaxHP
                                if pct > 1 then pct = 1 end
                                if pct < 0 then pct = 0 end
                            end
                            PlayerMapMarker.UpdateESPHealth(Widget, pct)
                            PlayerMapMarker.AddWeaponIconToESP(Widget, Character)
                            
                            if PlayerMapMarker.bUseSnapLines then
                                PlayerMapMarker.UpdateSnapLine(KeyStr, CanvasPos, bOnScreen, fromX, fromY)
                            else
                                PlayerMapMarker.RemoveSnapLine(KeyStr)
                            end

                            if PlayerMapMarker.bUseSkeleton then
                                PlayerMapMarker.UpdateSkeletonLines(KeyStr, Character, PC, true, PlayerMapMarker.GetTeamColor(TeamID), bOnScreen, Loc)
                            else
                                PlayerMapMarker.RemoveSkeletonLines(KeyStr)
                            end
                        else
                            local Container = Widget.Container or Widget
                            pcall(function() Container:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
                            PlayerMapMarker.UpdateESPHealth(Widget, 0)
                            PlayerMapMarker.RemoveSnapLine(KeyStr)
                            PlayerMapMarker.RemoveSkeletonLines(KeyStr)
                        end
                    end
                else
                    ESPData.Character = Character
                    ESPData.Name = Name
                    ESPData.LastDistStr = DistStr
                    if bIsAlive then
                        if ESPData.TeamID ~= TeamID then
                            ESPData.TeamID = TeamID
                            PlayerMapMarker.ApplyTeamColor(ESPData.Widget, TeamID)
                        end
                        
                        -- Keep the text cache; only update UMG when the text actually changes.
                        PlayerMapMarker.UpdateESPText(ESPData.Widget, Text)
                        PlayerMapMarker.UpdateESPPositionWithPC(ESPData.Widget, Loc, PC, CanvasPos)
                        local HP = Character.Health or 0
                        local MaxHP = Character.MaxHealth or 120
                        local pct = 0
                        if HP > 0 and MaxHP > 0 then
                            pct = HP / MaxHP
                            if pct > 1 then pct = 1 end
                            if pct < 0 then pct = 0 end
                        end
                        PlayerMapMarker.UpdateESPHealth(ESPData.Widget, pct)
                        PlayerMapMarker.AddWeaponIconToESP(ESPData.Widget, Character)
                        
                        if PlayerMapMarker.bUseSnapLines then
                            PlayerMapMarker.UpdateSnapLine(KeyStr, CanvasPos, bOnScreen, fromX, fromY)
                        else
                            PlayerMapMarker.RemoveSnapLine(KeyStr)
                        end

                        if PlayerMapMarker.bUseSkeleton then
                            PlayerMapMarker.UpdateSkeletonLines(KeyStr, Character, PC, true, PlayerMapMarker.GetTeamColor(TeamID), bOnScreen, Loc)
                        else
                            PlayerMapMarker.RemoveSkeletonLines(KeyStr)
                        end
                    else
                        local Container = ESPData.Widget.Container or ESPData.Widget
                        pcall(function() Container:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
                        PlayerMapMarker.UpdateESPHealth(ESPData.Widget, 0)
                        PlayerMapMarker.RemoveSnapLine(KeyStr)
                        PlayerMapMarker.RemoveSkeletonLines(KeyStr)
                    end
                end
            end
        end
    end

    for KeyStr, Data in pairs(PlayerMapMarker.ESPWidgets) do
        if not SeenKeys[KeyStr] then
            PlayerMapMarker.RemoveESPWidget(Data.Widget, KeyStr)
            PlayerMapMarker.ESPWidgets[KeyStr] = nil
        end
    end
end

function PlayerMapMarker.UpdateESPLight()
    if RedBoxOverlay and RedBoxOverlay.bActive then RedBoxOverlay.UpdatePosition() end
    if not PlayerMapMarker.bUseScreenESP then return end
    
    -- Đồng bộ Config Dây và Xương
    PlayerMapMarker.bUseSnapLines = _G.AHMADConfig.Esp9_Line
    PlayerMapMarker.bUseSkeleton = _G.AHMADConfig.Esp9_Skeleton
    if not PlayerMapMarker.ESPCanvas or not Game:IsValid(PlayerMapMarker.ESPCanvas) then return end
    local PC = PlayerMapMarker.GetMyPlayerController()
    if not IsValid(PC) then return end

    PlayerMapMarker.UpdateCanvasTransform(PC)

    local fromX, fromY = 0, 0
    if PlayerMapMarker.bUseSnapLines then fromX, fromY = PlayerMapMarker.GetSnapLineStartPos(PC) end

    for KeyStr, ESPData in pairs(PlayerMapMarker.ESPWidgets) do
        local Widget = ESPData.Widget
        local Character = ESPData.Character
        local Container = Widget and (Widget.Container or Widget)
        local bWidgetValid = false
        pcall(function() bWidgetValid = Container and slua.isValid(Container) end)

        if Widget and bWidgetValid and Character and IsValid(Character) then
            local bIsAlive = PlayerMapMarker.IsAlive(Character)
            if not bIsAlive then
                pcall(function() Container:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
                PlayerMapMarker.RemoveSnapLine(KeyStr)
                PlayerMapMarker.RemoveSkeletonLines(KeyStr)
            else
                -- [FIX VIP] Xóa vệt đen trên vòng lặp Light
                local bShowAnyUI = _G.AHMADConfig.Esp9_Name or _G.AHMADConfig.Esp9_Distance or _G.AHMADConfig.Esp9_HP or _G.AHMADConfig.Esp9_Team or _G.AHMADConfig.Esp9_Weapon
                if bShowAnyUI then
                    pcall(function() Container:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
                else
                    pcall(function() Container:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
                end
                pcall(function() Container:SetRenderOpacity(1.0) end)

                local Loc = PlayerMapMarker.GetESPLocation(Character)
                if Loc then
                    local bOnScreen, CanvasPos = PlayerMapMarker.ProjectWorldToCanvasLocal(PC, Loc)
                    PlayerMapMarker.UpdateESPPositionWithPC(Widget, Loc, PC, CanvasPos)
                    if PlayerMapMarker.bUseSnapLines then PlayerMapMarker.UpdateSnapLine(KeyStr, CanvasPos, bOnScreen, fromX, fromY)
                    else PlayerMapMarker.RemoveSnapLine(KeyStr) end

                    if PlayerMapMarker.bUseSkeleton then
                        PlayerMapMarker.UpdateSkeletonLines(KeyStr, Character, PC, true, PlayerMapMarker.GetTeamColor(ESPData.TeamID), bOnScreen, Loc)
                    else
                        PlayerMapMarker.RemoveSkeletonLines(KeyStr)
                    end
                else 
                    PlayerMapMarker.RemoveSnapLine(KeyStr)
                    PlayerMapMarker.RemoveSkeletonLines(KeyStr)
                end
            end
        end
    end
end

function PlayerMapMarker.UpdateESPDistances()
    if not PlayerMapMarker.bUseScreenESP then return end
    local MyLoc = PlayerMapMarker.GetMyLocation()
    if not MyLoc then return end
    local PC = PlayerMapMarker.GetMyPlayerController()
    if not IsValid(PC) then return end
    PlayerMapMarker.UpdateCanvasTransform(PC)

    for KeyStr, ESPData in pairs(PlayerMapMarker.ESPWidgets) do
        local Character = ESPData.Character
        local Widget = ESPData.Widget
        local Container = Widget and (Widget.Container or Widget)
        local bWidgetValid = false
        pcall(function() bWidgetValid = Container and slua.isValid(Container) end)
        if Character and IsValid(Character) and Widget and bWidgetValid then
            local Loc = PlayerMapMarker.GetESPLocation(Character)
            if Loc then
                local Dist = PlayerMapMarker.CalcDistance(MyLoc, Loc)
                ESPData.LastDistance = Dist

                if PlayerMapMarker.bShowDistance then
                    local DistStr = ""
                    local Meters = 0
                    if Dist then
                        Meters = Dist / 100
                        if Meters < 1000 then DistStr = string.format("%dm", math.floor(Meters))
                        else DistStr = string.format("%.1fkm", Meters / 1000) end
                    end

                    local Name = ESPData.Name or "Unknown"
                    local Text = ""
                    
                    -- Đồng bộ với công tắc ESP 9
                    if _G.AHMADConfig.Esp9_Name then Text = Name end
                    if _G.AHMADConfig.Esp9_Distance and DistStr and DistStr ~= "" then
                        if Text ~= "" then Text = string.format("%s [%s]", Text, DistStr) else Text = string.format("[%s]", DistStr) end
                    end
                    
                    ESPData.LastDistStr = DistStr
                    -- Keep the text cache; avoid unnecessary UMG SetText/layout work.
                    PlayerMapMarker.UpdateESPText(Widget, Text)
                end
            end
        end
    end
end

function PlayerMapMarker.ScanAndUpdate()
    local AllChars = PlayerMapMarker.GetAllCharacters()
    if not AllChars then RedBoxOverlay.SetCounts(0, 0) return 0 end

    local MyKey = PlayerMapMarker.GetMyPlayerKey()
    local MyLoc = PlayerMapMarker.GetMyLocation()

    local MyChar = nil
    pcall(function()
        local GDP = PlayerMapMarker.GetGameplayData()
        if GDP and GDP.GetLocalCharacter then MyChar = GDP.GetLocalCharacter()
        else local PC = PlayerMapMarker.GetMyPlayerController() if PC and PC.GetPawn then MyChar = PC:GetPawn() end end
    end)
    local MyTeamID = PlayerMapMarker.GetTeamID(MyChar)

    local realPlayers = 0
    local botPlayers = 0

    for PlayerKey, Character in pairs(AllChars) do
        if IsValid(Character) then
            local bIsMe = PlayerMapMarker.IsMe(Character, PlayerKey, MyKey)
            local bIsAI = PlayerMapMarker.IsAI(Character)
            local bIsAlive = PlayerMapMarker.IsAlive(Character)

            if bIsAlive and not bIsMe then
                local bIsMyTeam = false
                if MyTeamID ~= nil then
                    local targetTeamID = PlayerMapMarker.GetTeamID(Character)
                    if targetTeamID == MyTeamID then bIsMyTeam = true end
                end
                
                if not bIsMyTeam then
                    if bIsAI then botPlayers = botPlayers + 1
                    else realPlayers = realPlayers + 1 end
                end
            end
        end
    end

    -- [THÊM MỚI] Bật Tắt Bảng Đếm Người
    if _G.AHMADConfig.Esp9_Count then
        if RedBoxOverlay.bActive then RedBoxOverlay.SetCounts(realPlayers, botPlayers)
        else RedBoxOverlay.Start() end
    else
        if RedBoxOverlay.bActive then RedBoxOverlay.Stop() end
    end

    if PlayerMapMarker.bUseScreenESP then
        PlayerMapMarker.UpdateESP(AllChars, MyLoc)
        return 0
    end
    return 0
end

function PlayerMapMarker.AttachTimers()
    pcall(function()
        local pc = PlayerMapMarker.GetMyPlayerController()
        if not slua.isValid(pc) or not pc.AddGameTimer then
            local now = os.time()
            if PlayerMapMarker._AttachPending then if PlayerMapMarker._AttachPendingTime and (now - PlayerMapMarker._AttachPendingTime) < 2 then return end end
            PlayerMapMarker._AttachPending = true ; PlayerMapMarker._AttachPendingTime = now
            pcall(function() require("timer").SetGameTimer(1.0, false, function() PlayerMapMarker._AttachPending = nil ; PlayerMapMarker._AttachPendingTime = nil ; PlayerMapMarker.AttachTimers() end) end)
            return
        end

        PlayerMapMarker._AttachPending = nil ; PlayerMapMarker._AttachPendingTime = nil
        local now = os.time()
        local lastPC = PlayerMapMarker._ActiveTimerPC
        local lastTick = PlayerMapMarker._ActiveTimerTick
        if lastPC and slua.isValid(lastPC) and lastPC == pc then if lastTick and (now - lastTick) < 5 then return end end

        PlayerMapMarker._ActiveTimerPC = pc ; PlayerMapMarker._ActiveTimerTick = now

        pcall(function() pc:AddGameTimer(PlayerMapMarker.nUpdateInterval or 0.5, true, function() PlayerMapMarker._ActiveTimerTick = os.time() if PlayerMapMarker.bActive then pcall(function() PlayerMapMarker.ScanAndUpdate() end) end end) end)
        pcall(function() pc:AddGameTimer(PlayerMapMarker._LightUpdateInterval or 0.02, true, function() PlayerMapMarker._ActiveTimerTick = os.time() if PlayerMapMarker.bActive then pcall(function() PlayerMapMarker.UpdateESPLight() end) end end) end)
        pcall(function() pc:AddGameTimer(PlayerMapMarker._DistanceUpdateInterval or 0.1, true, function() PlayerMapMarker._ActiveTimerTick = os.time() if PlayerMapMarker.bActive and PlayerMapMarker.bUseScreenESP and PlayerMapMarker.bShowDistance then pcall(function() PlayerMapMarker.UpdateESPDistances() end) end end) end)
        pcall(function() require("timer").SetGameTimer(5.0, false, PlayerMapMarker.AttachTimers) end)
    end)
end

function PlayerMapMarker.Start()
    if PlayerMapMarker.bActive then return end
    PlayerMapMarker.bActive = true
    PlayerMapMarker._FrameCount = 0
    PlayerMapMarker.ScanAndUpdate()
    PlayerMapMarker.AttachTimers()
end

function PlayerMapMarker.Stop()
    PlayerMapMarker.bActive = false
    PlayerMapMarker._FrameCount = 0
    PlayerMapMarker.ClearAllESP()
end

_G.PlayerMapMarker = PlayerMapMarker
-- ============================================================
-- KẾT THÚC: LÕI ESP LOẠI 9 (TỪ CODE MẪU GỐC FULL LOGIC)

-- 2. LOGIN CONFIGURATION
-- Editable source: src/license_config.lua
-- ========================================================================

local MasterLicenseConfig = (function()
-- Existing user-supplied protocol configuration. Do not log or export its values.
local MASTER_AHSAN_EXPIRY_BD = "2026-12-31 23:59:59"
local Config = {
    url = 'https://key.authapi.xyz/server', game = 'BGMI',
    timeout = 10, clockSkew = 120, expiryPath = nil,
    manualExpiry = MASTER_AHSAN_EXPIRY_BD, tamperTolerance = 5,
    secret = 'Vm8Lk7Uj2JmsjCPVPVjrLa7zgfx3uz5E',
}
return Config
end)()

-- ========================================================================
-- 3. LOGIN, EXPIRY AND TOKEN VALIDATION
-- Editable source: src/license_core.lua
-- ========================================================================

local MasterLicenseCore = (function()
-- Isolated source login protocol; no HTTP or game hooks execute at module load.
-- Source: CharacterBase (3)(1).lua lines 3284-3408 and 3688-3990.
local Primitives = (function()

local floor, abs, max = math.floor, math.abs, math.max
local byte, char, format = string.byte, string.char, string.format
local U32 = 4294967296

local AND, XOR = {}, {}
for a = 0, 15 do
    for b = 0, 15 do
        local av, bv, both, different, place = a, b, 0, 0, 1
        for _ = 1, 4 do
            local x, y = av % 2, bv % 2
            if x == 1 and y == 1 then both = both + place end
            if x ~= y then different = different + place end
            av, bv, place = floor(av / 2), floor(bv / 2), place * 2
        end
        AND[a * 16 + b], XOR[a * 16 + b] = both, different
    end
end
-- bitop: Combines two numbers through a four-bit lookup table. By @Masterpiece2026
local function bitop(a, b, lookup)
    local value, place = 0, 1
    for _ = 1, 8 do
        value = value + lookup[(a % 16) * 16 + b % 16] * place
        a, b, place = floor(a / 16), floor(b / 16), place * 16
    end
    return value
end
-- band: Computes a 32-bit bitwise AND using lookup tables. By @Masterpiece2026
local function band(a, b) return bitop(a, b, AND) end
-- bxor: Computes a 32-bit bitwise XOR using lookup tables. By @Masterpiece2026
local function bxor(a, b) return bitop(a, b, XOR) end
-- rol: Rotates a 32-bit value left by the requested amount. By @Masterpiece2026
local function rol(value, amount)
    local divisor = 2 ^ (32 - amount)
    return (value % divisor) * 2 ^ amount + floor(value / divisor)
end
-- little32: Encodes a number as four little-endian bytes. By @Masterpiece2026
local function little32(value)
    return char(value % 256, floor(value / 256) % 256,
        floor(value / 65536) % 256, floor(value / 16777216) % 256)
end
local K = {
    0xd76aa478,0xe8c7b756,0x242070db,0xc1bdceee,0xf57c0faf,0x4787c62a,0xa8304613,0xfd469501,
    0x698098d8,0x8b44f7af,0xffff5bb1,0x895cd7be,0x6b901122,0xfd987193,0xa679438e,0x49b40821,
    0xf61e2562,0xc040b340,0x265e5a51,0xe9b6c7aa,0xd62f105d,0x02441453,0xd8a1e681,0xe7d3fbc8,
    0x21e1cde6,0xc33707d6,0xf4d50d87,0x455a14ed,0xa9e3e905,0xfcefa3f8,0x676f02d9,0x8d2a4c8a,
    0xfffa3942,0x8771f681,0x6d9d6122,0xfde5380c,0xa4beea44,0x4bdecfa9,0xf6bb4b60,0xbebfbc70,
    0x289b7ec6,0xeaa127fa,0xd4ef3085,0x04881d05,0xd9d4d039,0xe6db99e5,0x1fa27cf8,0xc4ac5665,
    0xf4292244,0x432aff97,0xab9423a7,0xfc93a039,0x655b59c3,0x8f0ccc92,0xffeff47d,0x85845dd1,
    0x6fa87e4f,0xfe2ce6e0,0xa3014314,0x4e0811a1,0xf7537e82,0xbd3af235,0x2ad7d2bb,0xeb86d391
}
local SHIFT = {7,12,17,22,5,9,14,20,4,11,16,23,6,10,15,21}
-- md5_raw: Computes the raw MD5 digest required by the login protocol. By @Masterpiece2026
local function md5_raw(input)
    assert(type(input) == "string", "MD5 input must be a string")
    local size = #input
    local message = input .. char(128) .. string.rep(char(0), (55 - size) % 64)
        .. little32((size * 8) % U32) .. little32(floor(size / 536870912))
    local h0, h1, h2, h3 = 0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476
    local words = {}
    for offset = 1, #message, 64 do
        for j = 0, 15 do
            local a, b, c, d = byte(message, offset + j * 4, offset + j * 4 + 3)
            words[j] = a + b * 256 + c * 65536 + d * 16777216
        end
        local a, b, c, d = h0, h1, h2, h3
        for i = 0, 63 do
            local f, g, shiftBase
            if i < 16 then
                f, g, shiftBase = band(b, c) + band(U32 - 1 - b, d), i, 0
            elseif i < 32 then
                f, g, shiftBase = band(d, b) + band(U32 - 1 - d, c), (5 * i + 1) % 16, 4
            elseif i < 48 then
                f, g, shiftBase = bxor(bxor(b, c), d), (3 * i + 5) % 16, 8
            else
                local bOrNotD = U32 - 1 - band(U32 - 1 - b, d)
                f, g, shiftBase = bxor(c, bOrNotD), (7 * i) % 16, 12
            end
            local nextB = (b + rol((a + f + K[i + 1] + words[g]) % U32,
                SHIFT[shiftBase + i % 4 + 1])) % U32
            a, b, c, d = d, nextB, b, c
        end
        h0, h1, h2, h3 = (h0+a)%U32, (h1+b)%U32, (h2+c)%U32, (h3+d)%U32
    end
    return little32(h0) .. little32(h1) .. little32(h2) .. little32(h3)
end
-- hex: Converts binary bytes into lowercase hexadecimal text. By @Masterpiece2026
local function hex(input)
    return (input:gsub(".", function(c) return format("%02x", byte(c)) end))
end
-- md5: Returns the hexadecimal MD5 digest of an input string. By @Masterpiece2026
local function md5(input) return hex(md5_raw(input)) end
-- form_encode: Encodes a string for URL-encoded form submission. By @Masterpiece2026
local function form_encode(input)
    assert(type(input) == "string", "Form value must be a string")
    return (input:gsub("[^A-Za-z0-9%-%._~ ]", function(c)
        return format("%%%02X", byte(c))
    end):gsub(" ", "+"))
end
-- constant_time_equal: Compares strings without returning early based on differing contents. By @Masterpiece2026
local function constant_time_equal(a, b)
    if type(a) ~= "string" or type(b) ~= "string" then return false end
    local difference = abs(#a - #b)
    for i = 1, max(#a, #b) do
        difference = difference + abs((byte(a, i) or 0) - (byte(b, i) or 0))
    end
    return difference == 0
end
-- name_uuid: Builds a Java-compatible name UUID from input bytes. By @Masterpiece2026
local function name_uuid(input)
    local digest = md5_raw(input)
    local h = hex(digest:sub(1, 6) .. char(byte(digest, 7) % 16 + 48)
        .. digest:sub(8, 8) .. char(byte(digest, 9) % 64 + 128) .. digest:sub(10))
    return h:sub(1,8) .. "-" .. h:sub(9,12) .. "-" .. h:sub(13,16)
        .. "-" .. h:sub(17,20) .. "-" .. h:sub(21,32)
end
return {
    md5 = md5, md5_raw = md5_raw, form_encode = form_encode,
    constant_time_equal = constant_time_equal, name_uuid = name_uuid
}

end)()
local CreateLocalExpiry = (function()

return function(cfg, wallReader)
    local E = {}
    local expiredText = 'Mod expired. DM @Masterpiece2025 for the renewal.'
    local tamperText = "Don't be over smart"
    local blockedMessage, blockedPhase
    -- finite: Checks whether a value is a finite number. By @Masterpiece2026
    local function finite(n)
        return type(n)=='number' and n==n and n~=math.huge and n~=-math.huge
    end
    -- parse: Parses a strict Bangladesh timestamp into Unix epoch seconds. By @Masterpiece2026
    local function parse(text)
        if type(text)~='string' then return nil end
        local y,m,d,h,n,s=text:match('^(%d%d%d%d)%-(%d%d)%-(%d%d) (%d%d):(%d%d):(%d%d)$')
        y,m,d,h,n,s=tonumber(y),tonumber(m),tonumber(d),tonumber(h),tonumber(n),tonumber(s)
        if not y or y<1970 or y>9999 or m<1 or m>12 or h>23 or n>59 or s>59 then return nil end
        local leap=y%4==0 and (y%100~=0 or y%400==0)
        local months={31,leap and 29 or 28,31,30,31,30,31,31,30,31,30,31}
        if d<1 or d>months[m] then return nil end
        local prior=y-1
        local days=365*(y-1970)+math.floor(prior/4)-math.floor(1969/4)
            -math.floor(prior/100)+math.floor(1969/100)+math.floor(prior/400)-math.floor(1969/400)
        for i=1,m-1 do days=days+months[i] end
        return (days+d-1)*86400+h*3600+n*60+s-6*3600
    end
    local configured=type(cfg.manualExpiry)=='string' and cfg.manualExpiry:match('^%s*(.-)%s*$') or cfg.manualExpiry
    local expiry=parse(configured)
    local skew=cfg.clockSkew or 120
    if configured~=nil and configured~='' and not expiry then
        blockedMessage,blockedPhase='Invalid local expiry date. Use YYYY-MM-DD HH:MM:SS.','error'
    end
    -- block: Latches the first login-time expiry failure and returns its status. By @Masterpiece2026
    local function block(message,phase)
        if not blockedMessage then blockedMessage,blockedPhase=message,phase end
        return false,blockedMessage,blockedPhase
    end
    -- E.Status: Returns whether initial local expiry validation remains available. By @Masterpiece2026
    function E.Status()
        return not blockedMessage,blockedMessage,blockedPhase
    end
    -- E.MarkTampered: Blocks authentication after an explicitly detected clock failure. By @Masterpiece2026
    function E.MarkTampered() return block(tamperText,'tampered') end
    -- E.GetExpiry: Returns the optional configured timestamp for login-time validation. By @Masterpiece2026
    function E.GetExpiry() return expiry end
    -- E.Accept: Validates server timing and optional local expiry only when signing in. By @Masterpiece2026
    function E.Accept(server,now,world,phone,rtt)
        if blockedMessage then return E.Status() end
        if not finite(server) or not finite(now) or now<0 or world==nil
            or not finite(rtt) or rtt<0 or not finite(phone) then
            return block('Clock verification unavailable.','error')
        end
        if math.abs(phone-server)>skew+rtt then return E.MarkTampered() end
        if expiry and server+rtt>=expiry then return block(expiredText,'expired') end
        return true
    end
    return E
end

end)()

local CreateAuth = (function()

return function(P, cfg, deps)
    local A = {}
    local phase, message = 'locked', 'Enter your key to sign in.'
    local allowed, pending, generation = false, nil, 0
    local expiresAt
    local lastRequestLatencyMs, lastResponseTime, lastResponseWorld
    local startFn, stopFn, payloadStarted, restartRequired
    local localExpiry=deps.localExpiry
    if localExpiry then
        local ok,text,state=localExpiry.Status()
        if not ok then message,phase=text,state end
    end
    -- finite: Checks whether a value is a finite number. By @Masterpiece2026
    local function finite(n)
        return type(n)=='number' and n==n and n~=math.huge and n~=-math.huge
    end
    -- readClock: Reads a valid nonnegative game clock and its world. By @Masterpiece2026
    local function readClock()
        local ok,n,w=pcall(deps.clock)
        if ok and finite(n) and n>=0 and w~=nil then return n,w end
    end
    -- notify: Updates authentication status and safely notifies the host. By @Masterpiece2026
    local function notify(text, state)
        message,phase=text,state
        if type(deps.status)=='function' then pcall(deps.status,text,state) end
    end
    -- stopPayload: Stops the active payload and flags cleanup failures requiring restart. By @Masterpiece2026
    local function stopPayload()
        if payloadStarted then
            payloadStarted=false
            local ok,accepted=pcall(stopFn)
            if not ok or accepted==false then restartRequired=true end
        end
    end
    -- revoke: Revokes authorization, clears request state, and stops the payload. By @Masterpiece2026
    local function revoke(text,state)
        generation=generation+1
        allowed,pending,expiresAt=false,nil,nil
        lastRequestLatencyMs,lastResponseTime,lastResponseWorld=nil,nil,nil
        stopPayload()
        local localDenied=false
        if localExpiry then
            local ok,localText,localPhase=localExpiry.Status()
            if not ok then text,state,localDenied=localText,localPhase,true end
        end
        notify(restartRequired and not localDenied and 'Restart required: payload cleanup failed.' or text,state or 'error')
    end
    -- startPayload: Starts the bound payload and revokes access if startup fails. By @Masterpiece2026
    local function startPayload()
        if payloadStarted or not startFn then return true end
        payloadStarted=true
        local before=generation
        local ok,accepted=pcall(startFn)
        if not ok or accepted==false then
            restartRequired=true
            revoke('Restart required: offline script startup failed.','error')
            return false
        end
        return generation==before and allowed
    end
    -- denyReason: Normalizes server denial messages and redacts pending credential values. By @Masterpiece2026
    local function denyReason(reason)
        if type(reason)~='string' then return 'Expired' end
        local lower=reason:sub(1,120):lower():gsub('[_%s%-]+',' ')
        if lower=='max devices' or lower=='maximum devices' or lower=='max devices reached' then
            return 'Max Devices'
        end
        local clean=reason
        for _,field in ipairs({'key','serial'}) do
            if pending and type(pending[field])=='string' and #pending[field]>0 then
                local needle=pending[field]:gsub('([^%w])','%%%1')
                clean=clean:gsub(needle,'['..field..']')
            end
        end
        if type(cfg.secret)=='string' and #cfg.secret>0 then
            clean=clean:gsub(cfg.secret:gsub('([^%w])','%%%1'),'[credential]')
        end
        clean=clean:gsub('[%c]',' '):sub(1,120)
        return clean=='' and 'Expired' or ('Expired: '..clean)
    end
    -- configuredExpiry: Reads and validates an explicitly configured server expiry field. By @Masterpiece2026
    local function configuredExpiry(result)
        if cfg.expiryPath==nil then return nil,true end
        if type(cfg.expiryPath)~='table' or #cfg.expiryPath==0 then return nil,false end
        local v=result
        for _,name in ipairs(cfg.expiryPath) do
            if type(v)~='table' then return nil,false end
            v=rawget(v,name)
        end
        return v,finite(v) and v>0 and v%1==0
    end
    -- begin: Validates login prerequisites and starts an online authentication request. By @Masterpiece2026
    local function begin(key)
        if restartRequired or pending then return false end
        if localExpiry then
            local ok,text,state=localExpiry.Status()
            if not ok then revoke(text,state); return false end
        end
        if type(key)~='string' then key='' end
        key=key:match('^%s*(.-)%s*$')
        if #key==0 or #key>512 then
            revoke('Expired: enter a valid key.','denied'); return false
        end
        local now,world=readClock()
        if not now then revoke('Game clock unavailable. Try again in a match.','error'); return false end
        local okSerial,serial=pcall(deps.serial,key)
        if not okSerial or type(serial)~='string' or #serial==0 or #serial>512 then
            revoke('Device identifier unavailable.','error'); return false
        end
        generation=generation+1
        local requestId=generation
        pending={id=requestId,key=key,serial=serial,started=now,world=world,deadline=now+cfg.timeout}
        notify('Signing in...','pending')
        if not pending or pending.id~=requestId or generation~=requestId then return false end
        local body='game='..P.form_encode(cfg.game)..'&user_key='..P.form_encode(key)..'&serial='..P.form_encode(serial)
        -- received: Validates the first online response before granting this running session. By @Masterpiece2026
        local function received(success,raw)
            if not pending or pending.id~=requestId or generation~=requestId then return end
            local current,worldNow=readClock()
            if not current or worldNow~=pending.world or current<pending.started or current>=pending.deadline then
                revoke('Request expired. Please sign in again.','error'); return
            end
            if success~=true or type(raw)~='string' or #raw==0 or #raw>32768 then
                revoke('Connection failed. Please try again.','error'); return
            end
            local ok,result=pcall(deps.decode,raw)
            if not ok or type(result)~='table' then revoke('Invalid server response.','error'); return end
            if result.status~=true then revoke(denyReason(result.reason),'denied'); return end
            local data=result.data
            if type(data)~='table' or type(data.token)~='string' or #data.token~=32
                or not data.token:match('^[%x]+$') or not finite(data.rng) or data.rng%1~=0 then
                revoke('Incomplete server response.','error'); return
            end
            local expected=P.md5(cfg.game..'-'..key..'-'..serial..'-'..cfg.secret)
            if not P.constant_time_equal(data.token:lower(),expected) then
                revoke('Server token verification failed.','denied'); return
            end
            local okWall,wall=pcall(deps.wall)
            if not okWall or not finite(wall) then
                revoke('Phone clock unavailable.','error'); return
            end
            if localExpiry then
                local accepted,text,state=localExpiry.Accept(data.rng,current,worldNow,wall,current-pending.started)
                if not accepted then revoke(text,state); return end
            elseif math.abs(wall-data.rng)>cfg.clockSkew then
                revoke('Phone/server clock mismatch. Check automatic time.','error'); return
            end
            local expiry,validExpiry=configuredExpiry(result)
            if not validExpiry then revoke('Configured server expiry field is missing or invalid.','error'); return end
            if expiry and expiry-data.rng-(current-pending.started)<=0 then
                revoke('Expired','denied'); return
            end
            local fixedExpiry=localExpiry and localExpiry.GetExpiry()
            if fixedExpiry then expiry=math.min(expiry or fixedExpiry,fixedExpiry) end
            lastRequestLatencyMs=(current-pending.started)*1000
            lastResponseTime,lastResponseWorld=current,worldNow
            pending=nil
            allowed,expiresAt=true,expiry
            if not startPayload() then return end
            notify('Login successful.','active')
        end
        local ok,accepted=pcall(deps.post,cfg.url,{['Content-Type']='application/x-www-form-urlencoded'},body,received,cfg.timeout)
        if not ok or accepted==false then
            revoke('HTTP request could not start.','error'); return false
        end
        return true
    end
    -- A.Login: Starts a login attempt when access is currently unauthorized. By @Masterpiece2026
    function A.Login(key)
        if allowed then return false end
        return begin(key)
    end
    -- A.Tick: Times out incomplete login requests without rechecking accepted sessions. By @Masterpiece2026
    function A.Tick()
        if not pending then return end
        local now,world=readClock()
        if not now or world~=pending.world or now<pending.started then
            revoke('Login interrupted by map loading. Please try again when ready.','locked')
            return
        end
        if now>=pending.deadline then revoke('Request timed out. Please try again.','error') end
    end
    -- A.IsAuthorized: Reads session authorization independently of match worlds and their clocks. By @Masterpiece2026
    function A.IsAuthorized()
        return allowed and not restartRequired
    end
    -- A.Logout: Revokes access and marks authentication as signed out. By @Masterpiece2026
    function A.Logout()
        revoke('Expired: signed out.','locked')
    end
    -- A.FailClosed: Revokes access and optionally latches a fatal cleanup failure. By @Masterpiece2026
    function A.FailClosed(text,requiresRestart)
        if requiresRestart==true then restartRequired=true end
        revoke(text or 'Online access unavailable.','error')
    end
    -- A.ReportClockTampering: Latches local clock tampering and revokes authentication access. By @Masterpiece2026
    function A.ReportClockTampering()
        if localExpiry then localExpiry.MarkTampered() end
        revoke("Don't be over smart",'tampered')
    end
    -- A.Bind: Registers payload lifecycle callbacks and starts them if already authorized. By @Masterpiece2026
    function A.Bind(onStart,onStop)
        if type(onStart)~='function' or type(onStop)~='function' then return false,'START_AND_STOP_REQUIRED' end
        if startFn and (startFn~=onStart or stopFn~=onStop) then return false,'ALREADY_BOUND' end
        startFn,stopFn=onStart,onStop
        if A.IsAuthorized() then return startPayload() end
        return true
    end
    -- A.Unbind: Revokes access and removes bound payload lifecycle callbacks. By @Masterpiece2026
    function A.Unbind()
        revoke('Offline script disconnected.','locked')
        startFn,stopFn=nil,nil
    end
    -- A.GetRemainingSeconds: Session access has no timed lease or periodic expiry countdown. By @Masterpiece2026
    function A.GetRemainingSeconds() return nil end
    -- A.GetState: Returns authentication status, authorization, expiry, and payload linkage details. By @Masterpiece2026
    function A.GetState()
        local authorized=A.IsAuthorized()
        local sample,age
        if authorized and lastRequestLatencyMs~=nil then
            local now,world=readClock()
            if now and world==lastResponseWorld and now>=lastResponseTime then
                sample,age=lastRequestLatencyMs,now-lastResponseTime
            end
        end
        return {phase=phase,message=message,authorized=authorized,sessionAuthorized=authorized,expiresAt=expiresAt,
                accessPolicy="game_session",expiryCheckPolicy="login_only",periodicRecheck=false,
                pending=pending~=nil,linked=startFn~=nil,restartRequired=restartRequired==true,
                lastRequestLatencyMs=sample,lastRequestLatencyAgeSeconds=age,
                latencyScope="license_http_round_trip"}
    end
    return A
end

end)()

local Core={Primitives=Primitives,createExpiry=CreateLocalExpiry}
function Core.new(config,dependencies)
    assert(type(config)=='table' and type(dependencies)=='table','License configuration and dependencies required')
    local deps={}
    for key,value in pairs(dependencies)do deps[key]=value end
    if deps.localExpiry==nil then deps.localExpiry=CreateLocalExpiry(config,deps.wall) end
    return CreateAuth(Primitives,config,deps)
end
return Core
end)()

-- ========================================================================
-- 4. KEY LOGIN PANEL
-- Editable source: src/login_ui.lua
-- ========================================================================

local MasterLoginUI = (function()
-- Source UMG key panel, independent from any other overlay.
local Module={}
function Module.new(env)
    env=env or _G
    local require=env.require or require
    local function global(name)
        local ok,value=pcall(function()return env[name]end)
        if ok then return value end
    end
local UI = { _status = "Enter your key", _busy = false, _data = nil }

-- member: Reads an object member without propagating access errors. By @Masterpiece2026
local function member(object, name)
    if object == nil then return nil end
    local ok, value = pcall(function() return object[name] end)
    if ok then return value end
end

-- valid: Validates objects through the available Lua engine binding safely. By @Masterpiece2026
local function valid(object)
    local check = member(global( "slua"), "isValid")
    if object==nil then return false end
    if type(check)=='function' then
        local ok,result=pcall(check,object)
        if ok and result==true then return true end
    end
    local game=global('Game')
    local fallback=member(game,'IsValid')
    if type(fallback)=='function' then
        local ok,result=pcall(fallback,game,object)
        return ok and result==true
    end
    return false
end

-- imported: Imports an engine class while suppressing loader failures. By @Masterpiece2026
local function imported(name)
    local loader = global( "import")
    if type(loader) ~= "function" then return nil end
    local ok, result = pcall(loader, name)
    if ok then return result end
end

-- construct: Constructs a class instance without propagating construction errors. By @Masterpiece2026
local function construct(class, ...)
    if class == nil then return nil end
    local ok, result = pcall(class, ...)
    if ok then return result end
end

-- vector: Creates a two-dimensional vector with a table fallback. By @Masterpiece2026
local function vector(x, y)
    return construct(global( "FVector2D") or imported("Vector2D"), x, y)
        or { X = x, Y = y }
end

-- color: Creates a linear color with a table fallback. By @Masterpiece2026
local function color(r, g, b, a)
    return construct(global( "FLinearColor") or imported("LinearColor"), r, g, b, a)
        or { R = r, G = g, B = b, A = a }
end

-- visibility: Sets widget visibility through an available visibility setter. By @Masterpiece2026
local function visibility(widget, value)
    local setter = member(widget, "SetWidgetVisibility") or member(widget, "SetVisibility")
    assert(type(setter) == "function", "UI_VISIBILITY_UNAVAILABLE")
    setter(widget, value)
end

-- setTextStyle: Applies font size and text color when supported. By @Masterpiece2026
local function setTextStyle(widget, size, textColor)
    pcall(function()
        local font = widget.Font
        if font then
            font.Size=math.max(1,math.floor(size*(UI._scale or 1)+0.5))
            local assigned=pcall(function()widget.Font=font end)
            if not assigned then widget:SetFont(font) end
        end
    end)
    pcall(function()widget:SetAutoWrapText(true)end)
    pcall(function()
        local slate = construct(imported("SlateColor"), textColor)
        if slate then widget:SetColorAndOpacity(slate) end
    end)
end

-- detach: Disconnects login events and removes the associated UI container. By @Masterpiece2026
local function detach(data)
    if not data then return end
    data.visible = false
    pcall(function() if valid(data.input) then data.input:SetText("") end end)
    if data.event and data.eventHandle ~= nil then
        pcall(function() data.event:Remove(data.eventHandle) end)
    end
    if valid(data.container) then
        pcall(function() data.container:RemoveFromParent() end)
    end
    data.onSubmit = nil
end

-- UI.Destroy: Clears stored login UI state and detaches existing widgets. By @Masterpiece2026
function UI.Destroy()
    local previous = UI._data
    UI._data = nil
    detach(previous)
end

-- UI.Hide: Hides the login panel and clears entered key text. By @Masterpiece2026
function UI.Hide()
    local data = UI._data
    if not data or data.hiddenApplied then return true end
    data.visible = false
    local ok = pcall(function()
        if valid(data.input) then data.input:SetText("") end
        if valid(data.container) then visibility(data.container, data.hidden) end
    end)
    if ok then data.hiddenApplied = true end
    return ok
end

-- UI.SetStatus: Stores bounded status text and updates its widget when available. By @Masterpiece2026
function UI.SetStatus(message)
    UI._status = type(message) == "string" and message:sub(1, 160) or "Login unavailable"
    local data = UI._data
    if data and data.deliveredStatus == UI._status then return true end
    if data and valid(data.status) then
        local ok = pcall(function() data.status:SetText(UI._status) end)
        if ok then data.deliveredStatus = UI._status end
        return ok
    end
    return false
end

-- UI.SetBusy: Updates login controls to reflect whether authentication is busy. By @Masterpiece2026
function UI.SetBusy(busy)
    UI._busy = busy == true
    local data = UI._data
    if data then
        if data.deliveredBusy == UI._busy then return true end
        local buttonOK = pcall(function() data.button:SetIsEnabled(not UI._busy) end)
        local inputOK = pcall(function() data.input:SetIsEnabled(not UI._busy) end)
        if buttonOK and inputOK then
            data.deliveredBusy = UI._busy
            return true
        end
    end
    return false
end

-- UI.Show: Builds the key-entry panel with one centered LOGIN button. By @Masterpiece2026
local function fitScale(parent)
    local result=1
    pcall(function()
        local size=parent:GetCachedGeometry():GetLocalSize()
        local width,height=size.X,size.Y
        if type(width)=='number' and type(height)=='number' and width>24 and height>24 then
            result=math.min(1,(width-24)/500,(height-24)/248)
        end
    end)
    return result
end
function UI.Show(onSubmit)
    if type(onSubmit) ~= "function" then return false, "UI_SUBMIT_REQUIRED" end
    local data = UI._data
    if data and valid(data.parent) and math.abs(fitScale(data.parent)-(data.scale or 1))>0.001 then
        UI.Destroy();data=nil
    end
    if data and valid(data.container) and valid(data.parent) then
        local ok = data.visible or pcall(function() visibility(data.container, data.visibleEnum) end)
        if ok then
            data.onSubmit, data.visible, data.hiddenApplied = onSubmit, true, false
            UI.SetStatus(UI._status)
            UI.SetBusy(UI._busy)
            return true
        end
    end
    UI.Destroy()

    local okTools, uiTools = pcall(require, "GameLua.Mod.BaseMod.Common.UI.InGameUITools")
    local getRoot = okTools and member(uiTools, "GetMainControlBaseUI")
    if type(getRoot) ~= "function" then return false, "UI_NOT_READY" end
    local okRoot, root = pcall(getRoot)
    if not okRoot or not valid(root) then return false, "UI_NOT_READY" end
    local parent = member(root, "CanvasPanel_0")
    if not valid(parent) then parent = member(root, "CanvasPanel_42") end
    if not valid(parent) then return false, "UI_NOT_READY" end
    local game = global( "CGame")
    if type(member(game, "NewObjectFromPath")) ~= "function" then
        return false, "UI_FACTORY_UNAVAILABLE"
    end
    local enums = member(global( "UEnums"), "ESlateVisibility")
    local visibleEnum, hidden = member(enums, "Visible"), member(enums, "Collapsed")
    local passive = member(enums, "SelfHitTestInvisible")
    if visibleEnum == nil or hidden == nil or passive == nil then
        return false, "UI_ENUM_UNAVAILABLE"
    end

    UI._scale=fitScale(parent)
    data = { parent = parent, visible = false, onSubmit = onSubmit,
        visibleEnum = visibleEnum, hidden = hidden, scale=UI._scale }
    local okBuild = pcall(function()
        -- make: Creates a UMG widget and verifies its validity. By @Masterpiece2026
        local function make(class, outer)
            local widget = game:NewObjectFromPath("/Script/UMG." .. class, outer)
            assert(valid(widget), "UI_WIDGET_UNAVAILABLE")
            local clip=member(member(global('UEnums'),'EWidgetClipping'),'ClipToBounds')
            if clip~=nil then pcall(function()widget:SetClipping(clip)end) end
            return widget
        end
        data.container = make("CanvasPanel", parent)
        -- add: Adds a widget to the login canvas with layout settings. By @Masterpiece2026
        local function add(widget, x, y, width, height, z)
            local slot = data.container:AddChildToCanvas(widget)
            assert(valid(slot), "UI_SLOT_UNAVAILABLE")
            slot:SetAutoSize(false)
            slot:SetPosition(vector(x * UI._scale, y * UI._scale))
            slot:SetSize(vector(width * UI._scale, height * UI._scale))
            slot:SetZOrder(z)
            return slot
        end
        local background = make("Border", data.container)
        background:SetBrushColor(color(0.025, 0.035, 0.05, 0.98))
        visibility(background, visibleEnum)
        add(background, 0, 0, 500, 248, 0)
        local title = make("TextBlock", data.container)
        title:SetText("OWNER @UX_Official  Online Login")
        setTextStyle(title, 19, color(0.1, 0.9, 1, 1))
        visibility(title, passive)
        add(title, 22, 15, 456, 30, 1)

        data.input = make("EditableTextBox", data.container)
        assert(type(member(data.input, "GetText")) == "function", "UI_INPUT_UNAVAILABLE")
        data.input:SetText("")
        setTextStyle(data.input, 17, color(0.92, 0.94, 0.96, 1))
        pcall(function() data.input:SetHintText("Enter your key") end)
        pcall(function() data.input:SetIsPassword(false) end)
        pcall(function() data.input:SetIsReadOnly(false) end)
        pcall(function() data.input.AllowContextMenu = true end)
        local enumRoot=global("UEnums")
        local keyboard=member(member(enumRoot,"EVirtualKeyboardType"),"Default")
        local trigger=member(member(enumRoot,"EVirtualKeyboardTrigger"),"OnAllFocusEvents")
        if keyboard~=nil then pcall(function() data.input.KeyboardType=keyboard end) end
        if trigger~=nil then pcall(function() data.input.VirtualKeyboardTrigger=trigger end) end
        visibility(data.input, visibleEnum)
        add(data.input, 22, 58, 456, 44, 2)

        local hint = make("TextBlock", data.container)
        hint:SetText("Enter your key, then tap LOGIN.")
        setTextStyle(hint, 12, color(0.72, 0.78, 0.83, 1))
        visibility(hint, passive)
        add(hint, 22, 106, 456, 20, 2)

        data.status = make("TextBlock", data.container)
        data.status:SetText(UI._status)
        data.deliveredStatus = UI._status
        setTextStyle(data.status, 13, color(0.92, 0.94, 0.96, 1))
        visibility(data.status, passive)
        pcall(function() data.status:SetAutoWrapText(true) end)
        add(data.status, 22, 129, 456, 54, 2)

        data.button = make("Button", data.container)
        visibility(data.button, visibleEnum)
        local label = make("TextBlock", data.button)
        label:SetText("LOGIN")
        setTextStyle(label, 17, color(0.05, 0.08, 0.12, 1))
        visibility(label, passive)
        data.button:AddChild(label)
        add(data.button, 150, 190, 200, 40, 2)
        data.event = data.button.OnClicked
        assert(type(member(data.event, "Add")) == "function", "UI_BUTTON_UNAVAILABLE")
        data.eventHandle = data.event:Add(function()
            if UI._data ~= data or not data.visible or UI._busy then return end
            local readOK, key = pcall(function() return data.input:GetText() end)
            if not readOK or type(key) ~= "string" then
                UI.SetStatus("Unable to read the key")
                return
            end
            key = key:match("^%s*(.-)%s*$")
            if key == "" or #key > 512 then
                UI.SetStatus("Enter a valid key")
                return
            end
            local submitOK = pcall(data.onSubmit, key)
            if not submitOK then
                UI.SetBusy(false)
                UI.SetStatus("Login could not start")
            end
        end)

        local slot = parent:AddChildToCanvas(data.container)
        assert(valid(slot), "UI_SLOT_UNAVAILABLE")
        slot:SetAutoSize(false)
        slot:SetSize(vector(500 * UI._scale, 248 * UI._scale))
        slot:SetZOrder(9000)
        local anchors = slot:GetAnchors()
        anchors.Minimum, anchors.Maximum = vector(0.5, 0.5), vector(0.5, 0.5)
        slot:SetAnchors(anchors)
        slot:SetAlignment(vector(0.5, 0.5))
        slot:SetPosition(vector(0, 0))
        visibility(data.container, passive)
    end)
    if not okBuild then
        detach(data)
        return false, "UI_BUILD_UNAVAILABLE"
    end
    data.visible = true
    UI._data = data
    UI.SetBusy(UI._busy)
    return true
end

-- Keep a failed licence visible without allowing another submit action.
-- Reuse the existing panel and event guard instead of creating another overlay.
function UI.ShowNotice(message)
    local shown,reason=UI.Show(function()return false end)
    if not shown then return false,reason end
    UI.SetStatus(message)
    UI.SetBusy(true)
    return true
end

return UI

end
return Module
end)()

-- ========================================================================
-- 5. LOGIN HOST AND SESSION
-- Editable source: src/license_runtime.lua
-- ========================================================================

local MasterLicenseRuntime = (function()
-- Native licensing host. The owner calls update at approximately 1 Hz.
-- No feature timers, HTTP requests or credential reads run at module load.
local Runtime={}
Runtime.__index=Runtime
local function finite(n)return type(n)=='number' and n==n and n>=0 and n<math.huge end
local function read(o,k)
    if o==nil then return nil end
    local ok,v=pcall(function()return o[k]end)
    if ok then return v end
end
local function static(o,k,...)
    local fn=read(o,k)
    if type(fn)~='function' then return nil end
    local ok,v=pcall(fn,...)
    if ok then return v end
end
local function call(o,k,...)
    local fn=read(o,k)
    if type(fn)~='function' then return nil end
    local ok,v=pcall(fn,o,...)
    if ok then return v end
end
local function validConfig(c)
    return type(c)=='table' and type(c.url)=='string' and c.url:match('^https://')~=nil
        and type(c.game)=='string' and #c.game>0 and type(c.secret)=='string' and #c.secret>0
        and finite(c.timeout) and c.timeout>0 and finite(c.clockSkew)
end
function Runtime.new(env,config,Core,LoginUI)
    local self=setmetatable({env=env or _G,reason='login_required',active=false,
        ready=false,disposed=false,uiRetryAt=0,uiFailures=0},Runtime)
    if not validConfig(config) or type(Core)~='table' or type(Core.new)~='function'
        or type(Core.Primitives)~='table' then
        self.reason='license_dependencies_unavailable';return self
    end
    -- Retain protocol values privately. Public status never returns this table.
    local cfg={}
    for k,v in pairs(config)do cfg[k]=v end
    self.timeout=cfg.timeout
    if type(LoginUI)=='table' and type(LoginUI.new)=='function' then
        local ok,ui=pcall(LoginUI.new,self.env)
        if ok and type(ui)=='table' then self.ui=ui end
    end
    self.submit=function(key)return self:login(key)end
    local ok,auth=pcall(Core.new,cfg,{
        clock=function()return self:_clock()end,
        wall=function()
            local value=static(read(self.env,'os'),'time')
            if finite(value) and value>0 then return value end
        end,
        serial=function(key)
            local client=read(self.env,'Client')
            local value=static(client,'GetPhoneDeviceID')
            assert(type(value)=='string' and #value>0 and #value<=512,'DEVICE_ID_UNAVAILABLE')
            return Core.Primitives.name_uuid('MASTER-LUA-V1\0'..key..'\0'..value)
        end,
        decode=function(raw)
            local json=self:_module('json',nil,'common.json_util','decode')
            assert(json,'JSON_UNAVAILABLE')
            return json.decode(raw)
        end,
        post=function(url,headers,body,callback,timeout)
            local manager=read(self.env,'ModuleManager')
            local config=read(manager,'CommonModuleConfig')
            local getter=read(manager,'GetModule')
            assert(type(getter)=='function' and config,'HTTP_MANAGER_UNAVAILABLE')
            local http=getter(read(config,'http_manager'))
            local post=read(http,'Post')
            assert(type(post)=='function','HTTP_POST_UNAVAILABLE')
            return post(http,url,headers,body,nil,callback,timeout)
        end,
        status=function(message,phase)
            -- A login callback may arrive between maintenance updates.
            self.active=false
            self.reason=phase=='active' and 'waiting_maintenance' or 'login_required'
            self:_ui('SetStatus',message)
            self:_ui('SetBusy',phase=='pending')
            if phase=='active' then self:_ui('Hide') end
        end,
    })
    if ok and type(auth)=='table' then self.auth=auth
    else self.reason='license_initialization_unavailable' end
    return self
end
function Runtime:_module(cache,globalName,path,method)
    local found=globalName and read(self.env,globalName)
    if type(read(found,method))=='function' then return found end
    found=self[cache]
    if type(read(found,method))=='function' then return found end
    local loader=read(self.env,'require')
    if type(loader)=='function' then
        local ok,value=pcall(loader,path)
        if ok and type(read(value,method))=='function' then self[cache]=value;return value end
    end
end
function Runtime:_valid(object)
    if object==nil then return false end
    if static(read(self.env,'slua'),'isValid',object)==true then return true end
    return call(read(self.env,'Game'),'IsValid',object)==true
end
function Runtime:_clock()
    local world=static(read(self.env,'slua'),'getWorld')
    if world==nil then return nil end
    local statics=read(self.env,'GameplayStatics') or self.statics
    if type(read(statics,'GetRealTimeSeconds'))~='function' then
        local loader=read(self.env,'import')
        if type(loader)=='function' then
            local ok,value=pcall(loader,'GameplayStatics')
            if ok then statics=value end
        end
    end
    if type(read(statics,'GetRealTimeSeconds'))~='function' then return nil end
    self.statics=statics
    local now=static(statics,'GetRealTimeSeconds',world)
    if finite(now) then return now,world end
end
function Runtime:_readGameplay(world)
    -- A valid GameplayData module can expose only pawn getters while the
    -- frontend HUD supplies its controller. Do not discard that partial API.
    local data=read(self.env,'GameplayData') or self.gameplayData
    if data==nil then
        local loader=read(self.env,'require')
        if type(loader)=='function' then
            local ok,value=pcall(loader,'GameLua.GameCore.Data.GameplayData')
            if ok and value~=nil then self.gameplayData=value;data=value end
        end
    end
    local pc=static(data,'GetPlayerController')
    if not self:_valid(pc) and not self:_valid(read(pc,'Object')) then
        pc=call(read(self.env,'slua_GameFrontendHUD'),'GetPlayerController')
    end
    if not self:_valid(pc) and not self:_valid(read(pc,'Object')) then return nil,'waiting_controller' end
    local pawn=static(data,'GetPlayerCharacter')
    if not self:_valid(pawn) then pawn=static(data,'GetLocalCharacter') end
    for _,method in ipairs({'GetPlayerCharacterSafety','GetCurPawn','GetPawn'})do
        if not self:_valid(pawn) then pawn=call(pc,method) end
        if not self:_valid(pawn) then pawn=call(read(pc,'Object'),method) end
    end
    if not self:_valid(pawn) then return nil,'waiting_pawn' end
    local tools=self:_module('tools',nil,'GameLua.Mod.BaseMod.Common.UI.InGameUITools','GetMainControlBaseUI')
    local root=static(tools,'GetMainControlBaseUI')
    if not self:_valid(root) then return nil,'waiting_control_ui' end
    local status=self:_module('gameStatus','GameStatus','client.common.game_status','IsInFightingStatus')
    local loading=self:_module('loading',nil,'client.slua.logic.loading.logic_loading','IsShowing')
    if not status or not loading then return nil,'readiness_services_unavailable' end
    if static(status,'IsInFightingStatus')~=true then return nil,'waiting_gameplay' end
    if static(loading,'IsShowing')~=false then return nil,'waiting_loading' end
    return {world=world,controller=pc,pawn=pawn,root=root}
end
local function same(a,b)
    return a and b and a.world==b.world and a.controller==b.controller and a.pawn==b.pawn and a.root==b.root
end
function Runtime:_ui(method,...)
    local fn=read(self.ui,method)
    if type(fn)~='function' then return false,'UI_UNAVAILABLE' end
    local ok,value,reason=pcall(fn,...)
    if not ok then return false,'UI_TEMPORARILY_UNAVAILABLE' end
    return value,reason
end
function Runtime:_clearReadiness(reason)
    self.active,self.ready=false,false
    self.identity,self.readySince,self.maintenanceAt,self.maintenanceWorld=nil,nil,nil,nil
    self.reason=reason
    self:_ui('Hide')
end
function Runtime:_showPanel(now,state,blocked)
    if now<self.uiRetryAt then return false end
    local shown,uiReason
    if blocked then shown,uiReason=self:_ui('ShowNotice',state.message)
    else shown,uiReason=self:_ui('Show',self.submit) end
    if shown then
        self.uiFailures,self.uiError=0,nil
        self:_ui('SetStatus',state.message)
        self:_ui('SetBusy',blocked or state.pending)
    else
        self.uiFailures=self.uiFailures+1
        self.uiRetryAt=now+(self.uiFailures>=10 and 5 or 1)
        -- Only fixed native UI error codes are exposed, never thrown errors.
        self.uiError=type(uiReason)=='string' and uiReason:match('^UI_[A-Z_]+$') or 'UI_UNAVAILABLE'
    end
    return shown==true
end
function Runtime:earlyShow()
    if self.disposed or not self.auth then return false end
    local shown, reason = self:_ui('Show', self.submit)
    if shown then
        local state = self.auth.GetState()
        self:_ui('SetStatus', state and state.message or 'Enter your key')
        self:_ui('SetBusy', state and state.pending == true or false)
        return true
    end
    return false, reason
end

function Runtime:update()
    if self.disposed then self.reason='disposed';return false end
    if not self.auth then return false end
    local tickOK=pcall(self.auth.Tick)
    if not tickOK then
        self.auth.FailClosed('License maintenance unavailable.')
        self:_clearReadiness('license_maintenance_unavailable');return false
    end
    local now,world=self:_clock()
    if not now then self:_clearReadiness('clock_unavailable');return false end
    local ready,reason=self:_readGameplay(world)
    if not ready then self:_clearReadiness(reason);return false end
    if not same(self.identity,ready) or not self.readySince or now<self.readySince then
        self.identity,self.readySince=ready,now
        self.uiRetryAt,self.uiFailures,self.uiError=0,0,nil
        self:_ui('Destroy')
    end
    self.ready=now-self.readySince>=3
    self.maintenanceAt,self.maintenanceWorld=now,world
    self.active=self.ready and self.auth.IsAuthorized()
    if not self.ready then self.reason='waiting_stable_gameplay';self:_ui('Hide');return false end
    local state=self.auth.GetState()
    if self.active then
        self.reason='active';self:_ui('Hide');return true
    end
    self.reason='login_required'
    if state.restartRequired or state.phase=='expired' or state.phase=='tampered' then
        self.reason=state.restartRequired and 'restart_required' or state.phase
        self:_showPanel(now,state,true);return false
    end
    if not self:_showPanel(now,state,false) and self.uiError then self.reason='login_ui_unavailable' end
    return false
end
function Runtime:isActive()
    if self.disposed or not self.auth or not self.active or not self.ready then return false end
    if not self.auth.IsAuthorized() then self.active=false;return false end
    local now,world=self:_clock()
    if not now or world~=self.maintenanceWorld or not self.maintenanceAt
        or now<self.maintenanceAt or now-self.maintenanceAt>=3 then
        self.active=false;self.reason='maintenance_stale';return false
    end
    return true
end
function Runtime:login(key)
    if self.disposed or not self.auth then return false end
    if self.auth.IsAuthorized() then return true end
    local now,world=self:_clock()
    if not self.ready or not now or world~=self.maintenanceWorld or not self.maintenanceAt
        or now<self.maintenanceAt or now-self.maintenanceAt>=3 then return false end
    local identity=self:_readGameplay(world)
    if not same(identity,self.identity) then
        self:_clearReadiness('waiting_stable_gameplay');return false
    end
    local ok,accepted=pcall(self.auth.Login,key)
    if not ok then self.auth.FailClosed('Login could not start.');return false end
    return accepted==true
end
function Runtime:getStatus()
    local active=self:isActive()
    local state=self.auth and self.auth.GetState() or {}
    return {authorized=active,sessionAuthorized=state.authorized==true,
        phase=state.phase or 'locked',message=state.message or 'License dependencies unavailable.',
        reason=self.reason,pending=state.pending==true,gameplayReady=self.ready,
        expiresAt=state.expiresAt,accessPolicy='game_session',expiryCheckPolicy='login_only',
        clockProtection='login_only',periodicRecheck=false,loginDelaySeconds=3,
        restartRequired=state.restartRequired==true,uiError=self.uiError,
        lastRequestLatencyMs=state.lastRequestLatencyMs,latencyScope='license_http_round_trip',
        disposed=self.disposed}
end
function Runtime:logout()
    self.active=false
    if self.auth then self.auth.Logout()end
    self.reason='login_required'
    return true
end
function Runtime:dispose()
    if self.disposed then return true end
    self:logout();self.disposed=true;self.ready=false
    self:_ui('Destroy');self.reason='disposed'
    self.submit=nil
    return true
end
return Runtime
end)()

-- ========================================================================

-- ========================================================================
-- 6. EARLY LOGIN GATE / TICK
-- ========================================================================
local masterLicenseInstance, masterLicenseError
local function masterLicenseEnsureRuntime()
    if masterLicenseInstance then return masterLicenseInstance end
    local host = setmetatable({GameplayData=GameplayData}, {__index=_ENV})
    local ok, instance = pcall(MasterLicenseRuntime.new, host, MasterLicenseConfig, MasterLicenseCore, MasterLoginUI)
    if not ok or type(instance) ~= 'table' then
        masterLicenseError = tostring(ok and 'login runtime constructor returned non-table' or instance):sub(1, 240)
        return nil
    end
    masterLicenseInstance = instance
    return instance
end
local function masterLicenseTick()
    local instance = masterLicenseEnsureRuntime()
    if not instance then return false end
    pcall(instance.earlyShow, instance)
    local ok, result = pcall(instance.update, instance)
    if not ok then masterLicenseError=tostring(result):sub(1,240); return false end
    return result == true
end
local function masterLicenseAllowed()
    local instance=masterLicenseEnsureRuntime()
    if not instance then return false end
    local ok,active=pcall(instance.isActive,instance)
    return ok and active==true
end
_G.__UX_LOGIN_STATUS=function()
    local instance=masterLicenseEnsureRuntime()
    if not instance then return {authorized=false,reason='license_unavailable',error=masterLicenseError} end
    local ok,status=pcall(instance.getStatus,instance)
    if ok and type(status)=='table' then status.error=masterLicenseError;return status end
    return {authorized=false,reason='status_unavailable',error=masterLicenseError}
end
pcall(masterLicenseEnsureRuntime)


local function MainLoop() 
    if isExpired then return end
    if not masterLicenseAllowed() then return end

    if _G.AHMADState.CustomTextData == nil then 
        -- Sirf actually-used fields (aimbot ab unified logic mein hardcoded presets use karta hai)
        _G.AHMADState.CustomTextData = {OuterSpeed = 10, InnerSpeed = 10, HRecoil = 0.3, VRecoil = 0.3, IpadViewFOV = 120}
    end

    local okData, GameplayData = pcall(require, "GameLua.GameCore.Data.GameplayData") 
    if not okData or not GameplayData then return end 
    local pc = GameplayData.GetPlayerController() 
    local localPlayer = nil
    if Valid(pc) then localPlayer = pc:GetPlayerCharacterSafety() end 

    if not Valid(localPlayer) then 
        if _G.PlayerMapMarker and type(_G.PlayerMapMarker.Stop) == "function" then
            _G.PlayerMapMarker.Stop()
        end
        if _G.RedBoxOverlay and type(_G.RedBoxOverlay.Stop) == "function" then
            _G.RedBoxOverlay.Stop()
        end
        if _G.AHMADState.TrackedMarks then
            for markId, _ in pairs(_G.AHMADState.TrackedMarks) do
                SafeRemoveMark(markId)
            end
        end
        _G.AHMADState.TrackedMarks = {} 
        
        for key, data in pairs(_G.AHMADState.EnemyMarks) do
            if data and data.MIDs then
                for meshStr, midTable in pairs(data.MIDs) do
                    for k, _ in pairs(midTable) do midTable[k] = nil end
                end
                data.MIDs = nil
            end
        end
        
        _G.AHMADState.EnemyMarks = {}
        _G.AK_OrigHitboxes = {}
        _G.AK_ModdedPhysAssets = {}
        _G.AHMADState.PrevGraphicsState = {}
        return 
    end

    local Cached_PPM = nil
    pcall(function() Cached_PPM = import("PostProcessManager").GetInstance() end)
    local Cached_SecurityCommonUtils = nil
    pcall(function() Cached_SecurityCommonUtils = require("GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils") end)
    local Cached_MyHUD = pc and pc.MyHUD or nil

    if _G.AHMADConfig.UnlockFPS then InitializeGraphicsUnlock() end
    InitializeNativeESP()
    ShowGTLMODVIPMenu()

    -- ESP V2 lifecycle
    if _G.AHMADConfig.EspV2 then
        if _G.PlayerMapMarker and not _G.PlayerMapMarker.bActive then
            _G.PlayerMapMarker.Start()
        end
    else
        if _G.PlayerMapMarker and _G.PlayerMapMarker.bActive then
            _G.PlayerMapMarker.Stop()
        end
    end
    
    if _G.AHMADConfig.IpadView and _G.AHMADState.CustomTextData then
        pcall(function()
            local targetTPP = _G.AHMADState.CustomTextData.IpadViewFOV or 120
            local uTPPCam = localPlayer.ThirdPersonCameraComponent
            if Valid(uTPPCam) and not localPlayer.bIsWeaponAiming then
                if uTPPCam.FieldOfView ~= targetTPP then uTPPCam.FieldOfView = targetTPP end
            end
        end)
    else
        pcall(function()
            local uTPPCam = localPlayer.ThirdPersonCameraComponent
            if Valid(uTPPCam) and not localPlayer.bIsWeaponAiming then
                if uTPPCam.FieldOfView ~= 80 then uTPPCam.FieldOfView = 80 end
            end
        end)
    end

    -- ========================================== 
    -- SKIN MOD LOOP + KILL COUNTER + DEADBOX
    -- ========================================== 
    if _G.AHMADConfig.ModSkin then
        if not _G.TDSkinLoopStarted then
            if _G.InitializeSkinModSystem then _G.InitializeSkinModSystem() end
            if _G.ForceRefreshSkinMaps then _G.ForceRefreshSkinMaps() end
            _G.TDSkinLoopStarted = true
            -- Aktifkan Kill Counter & Effect
            if not _G.KillInfoCounterHacked and _G.ForceEnableKillCounterUI then _G.ForceEnableKillCounterUI() end
        end
        
        _G.AHMADState.SkinWasApplied = true
        local curTime = os.clock()
        if not _G.LastSkinUpdateTime or (curTime - _G.LastSkinUpdateTime) > 1.5 then
            _G.LastSkinUpdateTime = curTime
            pcall(function()
                local isAlive = type(localPlayer.IsAlive) == "function" and localPlayer:IsAlive() or true
                if isAlive then
                    if _G.ReadLiveConfig then _G.ReadLiveConfig() end
                    if _G.equip_character_avatar then _G.equip_character_avatar(localPlayer) end
                    if _G.ApplyWeaponSkins then _G.ApplyWeaponSkins(localPlayer) end
                    if _G.ApplyVehicleSkins then _G.ApplyVehicleSkins(localPlayer) end
                    if _G.HandlePetLogic then _G.HandlePetLogic() end
                    -- DeadBox skin
                    if _G.DeadBox_TemperRequest and _G.NeedCheckDeadBoxTimer > 0 then _G.DeadBox_TemperRequest(pc) end
                end
            end)
        end
    else
        if _G.AHMADState.SkinWasApplied then
            _G.OutfitMap = {}
            _G.WeaponSkinMap = {}
            _G.VehicleSkinMap = {}
            pcall(function()
                local WeaponManager = localPlayer:GetWeaponManager()
                if Valid(WeaponManager) then
                    for slot = 1, 3 do
                        local Weapon = WeaponManager:GetInventoryWeaponByPropSlot(slot)
                        if Valid(Weapon) and Valid(Weapon.synData) then
                            local WeaponID = Weapon:GetWeaponID()
                            local SkinData = Weapon.synData:Get(7)
                            if SkinData and SkinData.defineID then
                                SkinData.defineID.TypeSpecificID = WeaponID
                                Weapon.synData:Set(7, SkinData)
                                if Weapon.SetWeaponAvatarID then pcall(function() Weapon:SetWeaponAvatarID(WeaponID) end) end
                                if Weapon.DelayHandleAvatarMeshChanged then pcall(function() Weapon:DelayHandleAvatarMeshChanged() end) end
                            end
                        end
                    end
                end
                local Vehicle = localPlayer:GetCurrentVehicle()
                if Valid(Vehicle) then
                    local VehicleAvatar = Vehicle.VehicleAvatar or Vehicle.VehicleAvatarComponent_BP or Vehicle:GetAvatarComponent()
                    if Valid(VehicleAvatar) and type(VehicleAvatar.GetDefaultAvatarID) == "function" then
                        local defId = VehicleAvatar:GetDefaultAvatarID()
                        if VehicleAvatar.ChangeItemAvatar then VehicleAvatar:ChangeItemAvatar(defId, true) end
                    end
                end
                if localPlayer.AvatarComponent2 and type(localPlayer.AvatarComponent2.OnRep_BodySlotStateChanged) == "function" then
                    localPlayer.AvatarComponent2:OnRep_BodySlotStateChanged()
                end
            end)
            _G.AHMADState.SkinWasApplied = false
        end
        _G.TDSkinLoopStarted = false
    end

    -- ========================================== 
    -- Aimbot Force dipindahkan ke loop terpisah
    -- ========================================== 

    pcall(function()
        if _G.AHMADConfig.CustomAimbot and localPlayer.bIsWeaponFiring and localPlayer.bIsGunADS then
            local outerRecoilVal = _G.AHMADState.CustomTextData.OuterRecoil or 0
            if outerRecoilVal > 0 then
                local curTime = os.clock()
                
                if not _G.RecoilTargetCacheTime or (curTime - _G.RecoilTargetCacheTime) > 0.2 then
                    _G.RecoilTargetCacheTime = curTime
                    _G.HasRecoilTargetCached = false
                    
                    local ui_util = require("client.common.ui_util")
                    if ui_util then
                        local viewportSize = ui_util.GetViewportSize()
                        if viewportSize then
                            local centerX = viewportSize.X * 0.5
                            local centerY = viewportSize.Y * 0.5
                            local FOV_RADIUS = (6 / 100.0) * (viewportSize.X / 2.0) 
                            
                            local enemies = _G.GetEnemyTargetsFromActors(40000) 
                            if enemies and #enemies > 0 then
                                local FVector2D = import("Vector2D")
                                for _, target in ipairs(enemies) do
                                    if slua.isValid(target) and target.HealthStatus ~= 1 then 
                                        local tPos = type(target.K2_GetActorLocation) == "function" and target:K2_GetActorLocation() or nil
                                        if tPos then
                                            local screen = FVector2D()
                                            if pc:ProjectWorldLocationToScreen(tPos, screen, false) and screen.X > 0 and screen.Y > 0 then
                                                local dx = screen.X - centerX
                                                local dy = screen.Y - centerY
                                                if math.sqrt(dx*dx + dy*dy) <= FOV_RADIUS then
                                                    _G.HasRecoilTargetCached = true
                                                    break 
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end

                if _G.HasRecoilTargetCached then
                    local currentRot = pc:GetControlRotation()
                    if currentRot then
                        local pullDownForce = (outerRecoilVal / 50.0) * 1.5
                        currentRot.Pitch = currentRot.Pitch - pullDownForce
                        pc:SetControlRotation(currentRot, "CustomAimbotRecoil")
                    end
                end
            end
        else
            _G.HasRecoilTargetCached = false
        end
    end)

    pcall(function()
        if Valid(pc) then
            if pc.HiggsBoson then pc.HiggsBoson.bMHActive = false; pc.HiggsBoson.bCallPreReplication = false end
            if pc.HiggsBosonComponent then pc.HiggsBosonComponent.bMHActive = false; pc.HiggsBosonComponent.bCallPreReplication = false end
        end
    end)

    pcall(function()
        local autoComp = localPlayer.AutoAimComp
        if Valid(autoComp) then
            if not _G.AHMADState.OrigAutoAimCompCached then
                _G.AHMADState.OrigAutoAimCompCached = {
                    bOnlyHitHead = autoComp.bOnlyHitHead,
                    HeadBoneName = autoComp.HeadBoneName,
                    Bones = autoComp.Bones,
                    ChestBoneName = autoComp.ChestBoneName,
                    PelvisBoneName = autoComp.PelvisBoneName,
                    HeadPriority = autoComp.AimAssistConfig and autoComp.AimAssistConfig.HeadPriority,
                    ChestPriority = autoComp.AimAssistConfig and autoComp.AimAssistConfig.ChestPriority,
                    PelvisPriority = autoComp.AimAssistConfig and autoComp.AimAssistConfig.PelvisPriority
                }
            end
            
            if _G.AHMADConfig.AutoHead then
                autoComp.bOnlyHitHead = true
                autoComp.HeadBoneName = "Head"
                pcall(function() autoComp.Bones = {"Head"} end)
                autoComp.ChestBoneName = "Head"
                autoComp.PelvisBoneName = "Head"
                if autoComp.AimAssistConfig then
                    autoComp.AimAssistConfig.HeadPriority = 100
                    autoComp.AimAssistConfig.ChestPriority = 100
                    autoComp.AimAssistConfig.PelvisPriority = 100
                end
            else
                local orig = _G.AHMADState.OrigAutoAimCompCached
                autoComp.bOnlyHitHead = orig.bOnlyHitHead
                autoComp.HeadBoneName = orig.HeadBoneName
                pcall(function() autoComp.Bones = orig.Bones or {"Spine_01", "Pelvis", "Head"} end)
                autoComp.ChestBoneName = orig.ChestBoneName
                autoComp.PelvisBoneName = orig.PelvisBoneName
                if autoComp.AimAssistConfig then
                    autoComp.AimAssistConfig.HeadPriority = orig.HeadPriority or 1
                    autoComp.AimAssistConfig.ChestPriority = orig.ChestPriority or 1
                    autoComp.AimAssistConfig.PelvisPriority = orig.PelvisPriority or 1
                end
            end
        end
    end)

    -- ========================================== 
    -- REMOVED WALL CLIMB AND FAST CAR LOGIC 
    -- ==========================================

    local now = os.clock()
    pcall(function()
        local lsg = require("client.slua.logic.setting.logic_setting_graphics")
        local gi = lsg.GetGameInstance()
        if gi then
            if _G.AHMADConfig.RemoveGrass and not _G.AHMADState.PrevGraphicsState.RemoveGrass then
                gi:ExecuteCMD("grass.DensityScale", "0")
                gi:ExecuteCMD("grass.DiscardDataOnLoad", "1")
                _G.AHMADState.PrevGraphicsState.RemoveGrass = true
            elseif not _G.AHMADConfig.RemoveGrass and _G.AHMADState.PrevGraphicsState.RemoveGrass then
                gi:ExecuteCMD("grass.DensityScale", "1")
                gi:ExecuteCMD("grass.DiscardDataOnLoad", "0")
                _G.AHMADState.PrevGraphicsState.RemoveGrass = false
            end
            
            if _G.AHMADConfig.RemoveFog and not _G.AHMADState.PrevGraphicsState.RemoveFog then
                gi:ExecuteCMD("r.SkyAtmosphere", "1") 
                gi:ExecuteCMD("r.Fog", "0")           
                gi:ExecuteCMD("r.VolumetricFog", "0") 
                _G.AHMADState.PrevGraphicsState.RemoveFog = true
            elseif not _G.AHMADConfig.RemoveFog and _G.AHMADState.PrevGraphicsState.RemoveFog then
                gi:ExecuteCMD("r.SkyAtmosphere", "1") 
                gi:ExecuteCMD("r.Fog", "1")           
                gi:ExecuteCMD("r.VolumetricFog", "1") 
                _G.AHMADState.PrevGraphicsState.RemoveFog = false
            end
            
            if _G.AHMADConfig.WhiteBody and not _G.AHMADState.PrevGraphicsState.WhiteBody then
                gi:ExecuteCMD("r.CharacterDiffuseOffset", "2")
                gi:ExecuteCMD("r.CharacterDiffusePower", "5")
                gi:ExecuteCMD("r.CharacterMinShadowFactor", "100")
                _G.AHMADState.PrevGraphicsState.WhiteBody = true
            elseif not _G.AHMADConfig.WhiteBody and _G.AHMADState.PrevGraphicsState.WhiteBody then
                gi:ExecuteCMD("r.CharacterDiffuseOffset", "0")
                gi:ExecuteCMD("r.CharacterDiffusePower", "1")
                gi:ExecuteCMD("r.CharacterMinShadowFactor", "1")
                _G.AHMADState.PrevGraphicsState.WhiteBody = false
            end
            
            if _G.AHMADConfig.ColorBodyV2 and not _G.AHMADState.PrevGraphicsState.ColorBodyV2 then
                gi:ExecuteCMD("r.CharacterMinShadowFactor", "4")
                gi:ExecuteCMD("r.CharacterDiffuseOffset", "200")
                gi:ExecuteCMD("r.CharacterDiffusePower", "200")
                _G.AHMADState.PrevGraphicsState.ColorBodyV2 = true
            elseif not _G.AHMADConfig.ColorBodyV2 and _G.AHMADState.PrevGraphicsState.ColorBodyV2 then
                gi:ExecuteCMD("r.CharacterMinShadowFactor", "1")
                gi:ExecuteCMD("r.CharacterDiffuseOffset", "0")
                gi:ExecuteCMD("r.CharacterDiffusePower", "1")
                _G.AHMADState.PrevGraphicsState.ColorBodyV2 = false
            end
            
            if _G.AHMADConfig.BlackSky and not _G.AHMADState.PrevGraphicsState.BlackSky then
                gi:ExecuteCMD("r.CylinderMaxDrawHeight", "9999")
                _G.AHMADState.PrevGraphicsState.BlackSky = true
            elseif not _G.AHMADConfig.BlackSky and _G.AHMADState.PrevGraphicsState.BlackSky then
                gi:ExecuteCMD("r.CylinderMaxDrawHeight", "0000")
                _G.AHMADState.PrevGraphicsState.BlackSky = false
            end
        end
    end)

    pcall(function()
        local weapon = nil
        pcall(function()
            local weaponManager = localPlayer.WeaponManagerComponent
            if Valid(weaponManager) and type(weaponManager.GetCurrentWeapon) == "function" then
                weapon = weaponManager:GetCurrentWeapon()
            end
        end)
        if not Valid(weapon) then
            if type(localPlayer.GetCurrentShootWeapon) == "function" then weapon = localPlayer:GetCurrentShootWeapon()
            elseif type(localPlayer.GetCurrentWeapon) == "function" then weapon = localPlayer:GetCurrentWeapon() end
        end

        if Valid(weapon) then
            local entities = {}
            if Valid(weapon.ShootWeaponEntity_GEN_VARIABLE) then table.insert(entities, weapon.ShootWeaponEntity_GEN_VARIABLE) end
            if Valid(weapon.ShootWeaponEntity) then table.insert(entities, weapon.ShootWeaponEntity) end
            if Valid(weapon.ShootWeaponComponent) and Valid(weapon.ShootWeaponComponent.ShootWeaponEntityComponent) then 
                table.insert(entities, weapon.ShootWeaponComponent.ShootWeaponEntityComponent) 
            end

            for _, entity in ipairs(entities) do
                local anyWeaponModOn = _G.AHMADConfig.CustomHRecoil or _G.AHMADConfig.CustomVRecoil or _G.AHMADConfig.LessShake or _G.AHMADConfig.Accuracy or _G.AHMADConfig.Crosshair or _G.AHMADConfig.GodMode or _G.AHMADConfig.AutoHead or _G.AHMADConfig.CustomAimbot or _G.AHMADConfig.CustomAimbotClose

                if anyWeaponModOn then
                    if not entity.OriginalStatsCached then
                        entity.OriginalStatsCached = {
                            GameDeviationFactor = entity.GameDeviationFactor,
                            GameDeviationAccuracy = entity.GameDeviationAccuracy,
                            BulletFireSpeed = entity.BulletFireSpeed,
                            ShootInterval = entity.ShootInterval,
                            BaseDamage = entity.BaseDamage,
                            AccessoriesHRecoilFactor = entity.AccessoriesHRecoilFactor,
                            AccessoriesVRecoilFactor = entity.AccessoriesVRecoilFactor,
                            RecoilKick = entity.RecoilKick,
                            RecoilKickADS = entity.RecoilKickADS,
                            AnimationKick = entity.AnimationKick
                        }
                    end
                    
                    if _G.AHMADConfig.CustomHRecoil then entity.AccessoriesHRecoilFactor = _G.AHMADState.CustomTextData.HRecoil or 0.3 
                    elseif _G.AHMADConfig.LessRecoil then entity.AccessoriesHRecoilFactor = 0.3 end
                    
                    if _G.AHMADConfig.CustomVRecoil then entity.AccessoriesVRecoilFactor = _G.AHMADState.CustomTextData.VRecoil or 0.3
                    elseif _G.AHMADConfig.VerticalRecoil then entity.AccessoriesVRecoilFactor = 0.3 end
                    
                    if _G.AHMADConfig.LessShake then entity.RecoilKickADS = 0.0; entity.RecoilKickADS = 0.0; entity.RecoilKickADS = 0.0 end
                    if _G.AHMADConfig.Accuracy then entity.GameDeviationAccuracy = 0.0 end
                    if _G.AHMADConfig.Crosshair then entity.GameDeviationFactor = 0.0 end
                    if _G.AHMADConfig.GodMode then entity.BulletFireSpeed = 500000.0; entity.ShootInterval = 0.001; entity.BaseDamage = 60000.0 end
                    
                    if entity.AutoAimingConfig then
                        if not entity.OriginalAutoAimCached then
                            entity.OriginalAutoAimCached = {
                                OuterSpeed = entity.AutoAimingConfig.OuterRange and entity.AutoAimingConfig.OuterRange.Speed,
                                InnerSpeed = entity.AutoAimingConfig.InnerRange and entity.AutoAimingConfig.InnerRange.Speed
                            }
                        end
                        
                        if _G.AHMADConfig.AutoHead then
                            pcall(function() entity.AutoAimingConfig.Bones = { "Head", "Head", "Head" } end)
                        end
                        
                        if _G.AHMADConfig.CustomAimbot then
                            local speed = _G.AHMADState.CustomTextData.OuterSpeed or 10
                            if entity.AutoAimingConfig.OuterRange then
                                entity.AutoAimingConfig.OuterRange.Speed = speed
                                entity.AutoAimingConfig.OuterRange.RangeRate = 1.7
                                entity.AutoAimingConfig.OuterRange.SpeedRate = 1.3
                                entity.AutoAimingConfig.OuterRange.RangeRateSight = 1.8
                                entity.AutoAimingConfig.OuterRange.SpeedRateSight = 2.2
                                entity.AutoAimingConfig.OuterRange.CrouchRate = 1.1
                                entity.AutoAimingConfig.OuterRange.ProneRate = 1.0
                                entity.AutoAimingConfig.OuterRange.DyingRate = 0.0
                            end
                            if entity.AutoAimingConfig.InnerRange then
                                entity.AutoAimingConfig.InnerRange.Speed = speed
                                entity.AutoAimingConfig.InnerRange.RangeRate = 1.7
                                entity.AutoAimingConfig.InnerRange.SpeedRate = 1.3
                                entity.AutoAimingConfig.InnerRange.RangeRateSight = 1.8
                                entity.AutoAimingConfig.InnerRange.SpeedRateSight = 2.2
                                entity.AutoAimingConfig.InnerRange.CrouchRate = 1.1
                                entity.AutoAimingConfig.InnerRange.ProneRate = 1.0
                                entity.AutoAimingConfig.InnerRange.DyingRate = 0.0
                            end
                        elseif _G.AHMADConfig.CustomAimbotClose then
                            local speed = _G.AHMADState.CustomTextData.InnerSpeed or 10
                            if entity.AutoAimingConfig.OuterRange then
                                entity.AutoAimingConfig.OuterRange.Speed = speed
                                entity.AutoAimingConfig.OuterRange.DyingRate = 0.0
                            end
                            if entity.AutoAimingConfig.InnerRange then
                                entity.AutoAimingConfig.InnerRange.Speed = speed
                                entity.AutoAimingConfig.InnerRange.DyingRate = 0.0
                            end
                        end
                    end
                    
                    entity.GTLMODWeaponModsActive = true

                elseif entity.GTLMODWeaponModsActive then
                    if entity.OriginalStatsCached then
                        local orig = entity.OriginalStatsCached
                        entity.GameDeviationFactor = orig.GameDeviationFactor
                        entity.GameDeviationAccuracy = orig.GameDeviationAccuracy
                        entity.BulletFireSpeed = orig.BulletFireSpeed
                        entity.ShootInterval = orig.ShootInterval
                        entity.BaseDamage = orig.BaseDamage
                        entity.AccessoriesHRecoilFactor = orig.AccessoriesHRecoilFactor
                        entity.AccessoriesVRecoilFactor = orig.AccessoriesVRecoilFactor
                        entity.RecoilKick = orig.RecoilKick
                        entity.RecoilKickADS = orig.RecoilKickADS
                        entity.AnimationKick = orig.AnimationKick
                    end
                    if entity.AutoAimingConfig and entity.OriginalAutoAimCached then
                        pcall(function() entity.AutoAimingConfig.Bones = { "Spine_01", "Pelvis", "Head" } end)
                        if entity.AutoAimingConfig.OuterRange and entity.OriginalAutoAimCached.OuterSpeed then
                            entity.AutoAimingConfig.OuterRange.Speed = entity.OriginalAutoAimCached.OuterSpeed
                        end
                        if entity.AutoAimingConfig.InnerRange and entity.OriginalAutoAimCached.InnerSpeed then
                            entity.AutoAimingConfig.InnerRange.Speed = entity.OriginalAutoAimCached.InnerSpeed
                        end
                    end
                    entity.GTLMODWeaponModsActive = false
                end
            end
        end
    end)

    -- Magic Bullet logic has been removed from this version
    -- All global magic bullet variables disabled

    pcall(function()
        local allCharacters = {}
        if GameplayData.GetAllPlayerCharacters then allCharacters = GameplayData.GetAllPlayerCharacters()
        elseif GameplayData.GameCharacters then for _, char in pairs(GameplayData.GameCharacters) do table.insert(allCharacters, char) end end
        
        local currentValidKeys = {}
        for _, enemy in pairs(allCharacters) do
            if Valid(enemy) and enemy ~= localPlayer then
                currentValidKeys[GetSafeEnemyKey(enemy)] = true
            end
        end
        
        for key, data in pairs(_G.AHMADState.EnemyMarks) do
            if not currentValidKeys[key] then
                SafeRemoveMark(data.radarMark)
                SafeRemoveMark(data.hpMark)
                SafeRemoveMark(data.distMark)
                
                if _G.AimTouchVisCache and _G.AimTouchVisCache[key] then
                    _G.AimTouchVisCache[key] = nil
                end
                
                if _G.BotStatusCache and _G.BotStatusCache[key] then
                    _G.BotStatusCache[key] = nil
                end
                
                if data.MIDs then
                    for meshStr, midTable in pairs(data.MIDs) do
                        for k, _ in pairs(midTable) do
                            midTable[k] = nil
                        end
                    end
                    data.MIDs = nil
                end
                
                data.enemy = nil
                data.CachedMeshes = nil
                _G.AHMADState.EnemyMarks[key] = nil
            end
        end

        local realCount = 0
        local aiCount = 0

        local function GetFirstElemSafe(elemArray)
            if elemArray and type(elemArray.Num) == "function" and elemArray:Num() > 0 then
                if type(elemArray.Get) == "function" then return elemArray:Get(0) end
            elseif elemArray and type(elemArray) == "table" and #elemArray > 0 then
                return elemArray[1]
            end
            return nil
        end

        local BoneScaleMap = {
            ["head"] = mHead_Global, ["neck_01"] = mHead_Global,
            ["pelvis"] = mBody_Global, ["spine_01"] = mBody_Global, ["spine_02"] = mBody_Global, ["spine_03"] = mBody_Global,
            ["thigh_l"] = mLegs_Global, ["thigh_r"] = mLegs_Global, 
            ["calf_l"] = mLegs_Global, ["calf_r"] = mLegs_Global,   
            ["foot_l"] = mLegs_Global, ["foot_r"] = mLegs_Global    
        }
        
        local mLoc = nil
        pcall(function() if type(localPlayer.K2_GetActorLocation) == "function" then mLoc = localPlayer:K2_GetActorLocation() end end)

        for _, enemy in pairs(allCharacters) do
            if Valid(enemy) and enemy ~= localPlayer and enemy.TeamID ~= localPlayer.TeamID then
                local bIsReallyDead = false
                pcall(function()
                    if type(enemy.IsDead) == "function" then bIsReallyDead = enemy:IsDead()
                    elseif enemy.bIsDead ~= nil then bIsReallyDead = enemy.bIsDead
                    elseif enemy.bIsDeadFlag ~= nil then bIsReallyDead = enemy.bIsDeadFlag end
                    if enemy.HealthStatus ~= nil and enemy.HealthStatus == 2 then bIsReallyDead = true end
                end)

                local eKey = GetSafeEnemyKey(enemy)
                _G.AHMADState.EnemyMarks[eKey] = _G.AHMADState.EnemyMarks[eKey] or { enemy = enemy }
                local markData = _G.AHMADState.EnemyMarks[eKey]
                markData.enemy = enemy 

                if not bIsReallyDead then
                    if markData.lastEnemyActor ~= enemy then
                        if markData.hpMark then SafeRemoveMark(markData.hpMark); markData.hpMark = nil end
                        if markData.hpMark8 then SafeRemoveMark(markData.hpMark8); markData.hpMark8 = nil end
                        if markData.distMark then SafeRemoveMark(markData.distMark); markData.distMark = nil end
                        if markData.radarMark then SafeRemoveMark(markData.radarMark); markData.radarMark = nil end
                        
                        markData.lastEnemyActor = enemy
                        markData.LastUIComp = nil
                        markData.LastFrameUIState = nil
                    end
                    
                    local eMesh = nil
                    pcall(function() eMesh = enemy.Mesh or (type(enemy.getAvatarComponent2) == "function" and enemy:getAvatarComponent2() or nil) end)
                    local aLoc = nil
                    pcall(function() if type(enemy.K2_GetActorLocation) == "function" then aLoc = enemy:K2_GetActorLocation() end end)
                    
                    local isBotResult, isStateLoaded = CheckIsAI(enemy, markData)
                    local isBot = markData.AK_IS_BOT or false

                    local currentMeshCount = 0
                    if Valid(eMesh) then
                        local tempMeshes = GetAllSkeletalMeshes(enemy, markData)
                        currentMeshCount = #tempMeshes
                    end
                    local isMeshChanged = (markData.LastMeshCountWall ~= currentMeshCount)

                    if _G.AHMADConfig.wallhackng then
                        if isMeshChanged or not markData.WallhackApplied then
                            Applywallhackng(enemy, markData)
                            markData.WallhackApplied = true
                            markData.LastMeshCountWall = currentMeshCount
                        end
                    else
                        Undowallhackng(enemy, markData)
                    end

                    if _G.AHMADConfig.ColorBodyV2 then 
                        ApplyColorBodyV2(enemy, pc, markData) 
                    else
                        UndoColorBodyV2(enemy, markData)
                    end

                    -- Magic Bullet hitbox modification removed from this version
                    -- Physics asset override functionality disabled

                    local distM = 0
                    pcall(function() distM = localPlayer:GetDistanceTo(enemy) / 100 end)

                    local currentHp, maxHp = 100, 100
                    local showFrameUI = _G.AHMADConfig.Esp5 or _G.AHMADConfig.EspVipPro or _G.AHMADConfig.EspVip
                    
                    if showFrameUI then
                        pcall(function()
                            if enemy.Health then currentHp = enemy.Health elseif type(enemy.GetHealth) == "function" then currentHp = enemy:GetHealth() end
                            if enemy.HealthMax then maxHp = enemy.HealthMax elseif type(enemy.GetHealthMax) == "function" then maxHp = enemy:GetHealthMax() end
                        end)
                        if maxHp <= 0 then maxHp = 100 end
                    end
                    local hpRatio = currentHp / maxHp

                    if _G.AHMADConfig.EspAntenna then
                        pcall(function()
                            local MyHUD = Cached_MyHUD
                            if Valid(MyHUD) and distM <= 400 then
                                local loopCount = 8  
                                local zStep = 1000     
                                local baseZ = 105     
                                local topZ = baseZ + (loopCount * zStep)
                                for i = 1, loopCount do
                                    local zOffset = baseZ + (i * zStep)
                                    MyHUD:AddDebugText("|", enemy, 0.06,
                                        {X=0, Y=0, Z=zOffset}, {X=0, Y=0, Z=zOffset},
                                        C_GREEN, true, false, true, nil, 1.2, true)
                                end
                                MyHUD:AddDebugText("I", enemy, 0.06,
                                        {X=0, Y=0, Z=topZ + 60}, {X=0, Y=0, Z=topZ + 60},
                                        C_GREEN, true, false, true, nil, 1.5, true)
                            end
                        end)
                    end

                    if _G.AHMADConfig.Esp6 then
                        pcall(function()
                            local curTime = os.clock()
                            if markData.LastEsp6Time == nil or (curTime - markData.LastEsp6Time) >= 0.05 then
                                markData.LastEsp6Time = curTime
                                
                                local MyHUD = Cached_MyHUD
                                if Valid(MyHUD) and Valid(eMesh) and aLoc then
                                    if distM <= 250 then
                                        if type(eMesh.GetSocketLocation) == "function" then
                                            for _, bName in ipairs(GLOBAL_BONE_LIST) do
                                                
                                                if distM > 50 and (bName ~= "head" and bName ~= "pelvis" and bName ~= "neck_01") then
                                                    -- Skip
                                                else
                                                    local wLoc = eMesh:GetSocketLocation(bName)
                                                    if wLoc then
                                                        local offset = {X = wLoc.X - aLoc.X, Y = wLoc.Y - aLoc.Y, Z = wLoc.Z - aLoc.Z}
                                                        
                                                        local mark = "▪"
                                                        local fixedSize = 0.25 
                                                        local color = C_CYAN
                                                        
                                                        if bName == "head" then 
                                                            mark = "●"
                                                            fixedSize = 0.45
                                                            color = C_RED
                                                        elseif bName == "pelvis" or bName == "neck_01" then 
                                                            mark = "▪"
                                                            fixedSize = 0.35
                                                            color = C_YELLOW 
                                                        end
                                                        
                                                        MyHUD:AddDebugText(mark, enemy, 0.06, offset, offset, color, true, false, true, nil, fixedSize, true)
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end)
                    end

-- ========================================== 
-- ESP COUNTER (ENEMY P: X | B: X)
-- ========================================== 
if _G.AHMADConfig.Esp7 then
    pcall(function()
        local MyHUD = Cached_MyHUD
        if not Valid(MyHUD) then return end

        local myTeamId = localPlayer.TeamID or localPlayer:GetTeamID() or 0
        local myPos = localPlayer:K2_GetActorLocation()
        local maxDist = 35000
        local maxDistSq = maxDist * maxDist   -- compare squared (no sqrt = faster)
        local realCount = 0
        local aiCount = 0

        -- Bot status cache: ek baar detect, phir yaad rakho (bot kabhi real nahi banta)
        _G.BotStatusCache = _G.BotStatusCache or {}
        local botCache = _G.BotStatusCache

        for _, tPawn in pairs(allCharacters) do
            if slua.isValid(tPawn) and tPawn ~= localPlayer then
                local targetTeamId = tPawn.TeamID or tPawn:GetTeamID() or 0
                if targetTeamId ~= myTeamId then
                    local enemyPos = tPawn:K2_GetActorLocation()
                    if enemyPos then
                        local dx = enemyPos.X - myPos.X
                        local dy = enemyPos.Y - myPos.Y
                        local dz = enemyPos.Z - myPos.Z
                        local distSq = dx*dx + dy*dy + dz*dz
                        if distSq <= maxDistSq then
                            -- Unique ID nikalo caching ke liye
                            local pid = nil
                            if type(tPawn.GetUniqueID) == "function" then
                                local ok, r = pcall(function() return tPawn:GetUniqueID() end)
                                if ok then pid = r end
                            end
                            if not pid then pid = tostring(tPawn) end

                            local isAI = botCache[pid]
                            if isAI == nil then
                                -- Pehli baar: heavy detection chalao (sirf ek baar per pawn)
                                isAI = false
                                -- Method 1: direct actor AI flags
                                if tPawn.bIsAI == true or tPawn.IsAI == true or tPawn.bIsAi == true then
                                    isAI = true
                                end
                                -- Method 2: PUBGM AIData / AIController component (sabse reliable)
                                if not isAI then
                                    if tPawn.AIData ~= nil or tPawn.AIController ~= nil or tPawn.bIsAIActor == true then
                                        isAI = true
                                    end
                                    if not isAI and tPawn.PlayerAIType ~= nil and tPawn.PlayerAIType ~= 0 then
                                        isAI = true
                                    end
                                    if not isAI and type(tPawn.IsAICharacter) == "function" then
                                        local ok, r = pcall(function() return tPawn:IsAICharacter() end)
                                        if ok and r then isAI = true end
                                    end
                                    if not isAI and type(tPawn.GetIsAI) == "function" then
                                        local ok, r = pcall(function() return tPawn:GetIsAI() end)
                                        if ok and r then isAI = true end
                                    end
                                end
                                -- Method 3: PlayerState bot flags + missing UID (bots ke paas asli account UID nahi hota)
                                if not isAI then
                                    local pState = tPawn.PlayerState or (type(tPawn.GetPlayerState) == "function" and tPawn:GetPlayerState())
                                    if slua.isValid(pState) then
                                        if pState.bIsABot == true or pState.bIsBot == true or pState.IsBot == true or pState.bIsAI == true or pState.bIsRobot == true or pState.bIsAiPlayer == true then
                                            isAI = true
                                        end
                                        if not isAI and pState.PlayerAIType ~= nil and pState.PlayerAIType ~= 0 then
                                            isAI = true
                                        end
                                        if not isAI and type(pState.IsABot) == "function" then
                                            local ok, r = pcall(function() return pState:IsABot() end)
                                            if ok and r then isAI = true end
                                        end
                                        -- Bots ka Uid/PlayerId 0 ya nil hota hai (real players ka valid hota hai)
                                        if not isAI then
                                            local uid = pState.Uid or pState.UID or pState.PlayerId or pState.PlayerID
                                            if uid ~= nil and (uid == 0 or uid == "0") then
                                                isAI = true
                                            end
                                        end
                                    end
                                end
                                -- Method 4: function-based checks on pawn
                                if not isAI and type(tPawn.IsBot) == "function" then
                                    local ok, r = pcall(function() return tPawn:IsBot() end)
                                    if ok and r then isAI = true end
                                end
                                if not isAI and type(tPawn.IsAIPlayer) == "function" then
                                    local ok, r = pcall(function() return tPawn:IsAIPlayer() end)
                                    if ok and r then isAI = true end
                                end
                                -- Method 5: AI controller check
                                if not isAI and type(tPawn.GetController) == "function" then
                                    local ok, ctrl = pcall(function() return tPawn:GetController() end)
                                    if ok and slua.isValid(ctrl) then
                                        if ctrl.bIsAI == true or ctrl.IsAI == true or ctrl.AIData ~= nil then isAI = true end
                                        -- AIController class ka naam check
                                        if not isAI and type(ctrl.GetClass) == "function" then
                                            local ok2, cls = pcall(function() return ctrl:GetClass() end)
                                            if ok2 and slua.isValid(cls) and type(cls.GetName) == "function" then
                                                local ok3, cname = pcall(function() return cls:GetName() end)
                                                if ok3 and type(cname) == "string" and (cname:find("AI") or cname:find("Bot")) then
                                                    isAI = true
                                                end
                                            end
                                        end
                                    end
                                end
                                -- Result cache karo (agli baar heavy check nahi chalega)
                                botCache[pid] = isAI
                            end

                            if isAI then
                                aiCount = aiCount + 1
                            else
                                realCount = realCount + 1
                            end
                        end
                    end
                end
            end
        end

        local totalEnemy = realCount + aiCount
        if totalEnemy > 0 then
            local text = string.format("ENEMY : %d | BOT : %d", realCount, aiCount)
            -- ESP Counter: RED color
            MyHUD:AddDebugText(text, localPlayer, 1.2, {X=0, Y=0, Z=150}, {X=0, Y=0, Z=150}, {R=255, G=255, B=0, A=255}, true, false, true, nil, 1.0, true)
            -- Telegram Channel text below counter: YELLOW (highlight)
            MyHUD:AddDebugText("✦ OWNER @UX_Official ✦", localPlayer, 1.2, {X=0, Y=0, Z=140}, {X=0, Y=0, Z=140}, {R=255, G=255, B=0, A=255}, true, false, true, nil, 0.9, true)
        else
            -- ESP Counter clear message: RED color
            MyHUD:AddDebugText("[ CLEAR AREA ]", localPlayer, 1.2, {X=0, Y=0, Z=150}, {X=0, Y=0, Z=150}, {R=255, G=0, B=0, A=255}, true, false, true, nil, 1.0, true)
            -- Telegram Channel text below: YELLOW (highlight)
            MyHUD:AddDebugText("✦ WhatsApp +92 [ 03709241014 ]✦", localPlayer, 1.2, {X=0, Y=0, Z=140}, {X=0, Y=0, Z=140}, {R=255, G=255, B=0, A=255}, true, false, true, nil, 0.9, true)
        end
    end)
end
                    if showFrameUI then
                        pcall(function()
                            local SecurityCommonUtils = Cached_SecurityCommonUtils
                            local show = true
                            if enemy.HealthStatus and SecurityCommonUtils and SecurityCommonUtils.IsHealthStatusAlive then 
                                if not SecurityCommonUtils.IsHealthStatusAlive(enemy.HealthStatus) then show = false end
                            end
                            if show and mLoc then
                                if aLoc and SecurityCommonUtils and SecurityCommonUtils.IsVector then
                                    if SecurityCommonUtils.IsVector(aLoc) and SecurityCommonUtils.IsVector(mLoc) then
                                        if aLoc.Z >= 150000 or FVector.Dist2D(mLoc, aLoc) > 50000 then show = false end
                                    end
                                end
                            end
                            if show then
                                if enemy.Replay_IsEnemyFrameUIExisted and not enemy:Replay_IsEnemyFrameUIExisted() then enemy:Replay_CreateEnemyFrameUI(true, true) end
                                if enemy.Replay_SetVisiableOfFrameUI then enemy:Replay_SetVisiableOfFrameUI(true) end
                                if enemy.Replay_UpdateEnemyFrameUI then enemy:Replay_UpdateEnemyFrameUI(hpRatio) end
                                
                                local uiComp = enemy.EnemyFrameUI or (type(enemy.GetEnemyFrameUI) == "function" and enemy:GetEnemyFrameUI())
                                if Valid(uiComp) then
                                    if markData.LastFrameUIState ~= "VISIBLE" then
                                        if type(uiComp.SetVisibility) == "function" then uiComp:SetVisibility(0) end
                                        if type(uiComp.SetHiddenInGame) == "function" then uiComp:SetHiddenInGame(false) end
                                        markData.LastFrameUIState = "VISIBLE"
                                    end
                                end
                            end
                        end)
                    else
                        pcall(function()
                            if enemy.Replay_SetVisiableOfFrameUI then enemy:Replay_SetVisiableOfFrameUI(false) end
                            local uiComp = enemy.EnemyFrameUI or (type(enemy.GetEnemyFrameUI) == "function" and enemy:GetEnemyFrameUI())
                            if Valid(uiComp) then
                                if markData.LastFrameUIState ~= "HIDDEN" then
                                    if type(uiComp.SetVisibility) == "function" then uiComp:SetVisibility(2) end
                                    if type(uiComp.SetHiddenInGame) == "function" then uiComp:SetHiddenInGame(true) end
                                    markData.LastFrameUIState = "HIDDEN"
                                end
                            end
                        end)
                    end

                    -- =================== ESP HEALTH V1 (Warna berdasarkan ColorConfig) ===================
                    if _G.AHMADConfig.EspVipPro then
                        pcall(function()
                            local hud = Cached_MyHUD
                            if not (Valid(hud) and hud.AddDebugText) then return end
                            if distM > 400 then return end

                            local hp = enemy.Health or 100
                            local maxHp = enemy.HealthMax or 100
                            local isKnock = (hp <= 0 or enemy.HealthStatus == 1)
                            local hpPercent = isKnock and 0 or (hp / maxHp)
                            local pctValue = math.floor(hpPercent * 100 + 0.5)

                            local pName = ""
                            if _G.AHMADConfig.EspName then
                                pName = enemy.PlayerName or enemy.PlayerNamePublic or "Enemy"
                            end

                            -- Refresh visibility check setiap frame
                            local bIsVisible = false
                            if pc and type(pc.LineOfSightTo) == "function" then
                                bIsVisible = pc:LineOfSightTo(enemy)
                            end

                            -- Ambil warna dari ColorConfig
                            local visibleCol = GetAppliedColor(_G.ColorConfig.VisibleColor or 4, _G.ColorConfig.Brightness)
                            local invisibleCol = GetAppliedColor(_G.ColorConfig.InvisibleColor or 1, _G.ColorConfig.Brightness)
                            
                            local textColor = {R=255, G=255, B=255, A=255}
                            if isKnock then
                                textColor = {R=0, G=0, B=255, A=255}      -- Biru
                            else
                                textColor = bIsVisible and visibleCol or invisibleCol
                            end

                            local prefix = bIsVisible and "▶" or "▶"
                            local label = ""
                            if isKnock then
                                label = (pName ~= "" and string.format("%s [♿]", pName) or "♿")
                            else
                                if pName ~= "" then
                                    label = string.format("%s %s %.0f%%", pName, prefix, pctValue)
                                else
                                    label = string.format("%s %.0f%%", prefix, pctValue)
                                end
                            end

                            hud:AddDebugText(label, enemy, 0.2, {X=0, Y=0, Z=120}, {X=0, Y=0, Z=120},
                                             textColor, true, false, true, nil, 1.0, true)
                        end)
                    end

                    -- =================== ESP RANGE V1 (Jarak dalam meter) ===================
                    if _G.AHMADConfig.EspDistance then
                        pcall(function()
                            local hud = Cached_MyHUD
                            if not (Valid(hud) and hud.AddDebugText) then return end
                            if distM > 400 then return end

                            local distMeters = math.floor(distM + 0.5)
                            local rangeColor = {R=255, G=255, B=255, A=255} -- putih

                            hud:AddDebugText(string.format("%.0fm", distMeters), enemy, 0.3,
                                             {X=15, Y=15, Z=-15}, {X=15, Y=15, Z=-15},
                                             rangeColor, true, false, true, nil, 0.9, true)
                        end)
                    end

-- =================== ESP NAME V1 (Nama dengan warna dari ColorConfig) ===================
if _G.AHMADConfig.EspName and not _G.AHMADConfig.EspVipPro then
    pcall(function()
        local hud = Cached_MyHUD
        if not (Valid(hud) and hud.AddDebugText) then return end
        if distM > 400 then return end

        local pName = enemy.PlayerName or enemy.PlayerNamePublic or "Enemy"
        if pName == "" then return end

        local isKnock = (enemy.Health or 100) <= 0 or enemy.HealthStatus == 1
        local bIsVisible = true
        pcall(function()
            if pc and type(pc.LineOfSightTo) == "function" then
                bIsVisible = pc:LineOfSightTo(enemy)
            end
        end)

        local visibleCol = GetAppliedColor(_G.ColorConfig.VisibleColor or 4, _G.ColorConfig.Brightness)
        local invisibleCol = GetAppliedColor(_G.ColorConfig.InvisibleColor or 1, _G.ColorConfig.Brightness)
        
        local nameColor = {R=255, G=255, B=255, A=255}
        if isKnock then
            nameColor = {R=0, G=0, B=255, A=255}
        else
            nameColor = bIsVisible and visibleCol or invisibleCol
        end

        hud:AddDebugText(pName, enemy, 0.2, {X=0, Y=0, Z=120}, {X=0, Y=0, Z=120},
                         nameColor, true, false, true, nil, 1.0, true)
    end)
end

                    if _G.AHMADConfig.EspVip then
                        if markData.hpMark == nil then markData.hpMark = SafeAddMark(1006, FVector(0,0,0), 0, "", 4, enemy) end
                        if markData.distMark == nil then markData.distMark = SafeAddMark(9999, FVector(0,0,0), 0, "", 4, enemy) end
                    else
                        if markData.hpMark then SafeRemoveMark(markData.hpMark); markData.hpMark = nil end
                        if markData.distMark then SafeRemoveMark(markData.distMark); markData.distMark = nil end
                    end

                    if _G.AHMADConfig.Esp8 then
                        if markData.hpMark8 == nil then markData.hpMark8 = SafeAddMark(1006, FVector(0,0,0), 0, "", 4, enemy) end
                    else
                        if markData.hpMark8 then SafeRemoveMark(markData.hpMark8); markData.hpMark8 = nil end
                    end
                    
                    if _G.AHMADConfig.EspRadar then
                        if not markData.radarMark or markData.radarMark == 0 then 
                            markData.radarMark = SafeAddMark(8888, FVector(0,0,0), 0, "", 4, enemy) 
                        end
                    else
                        if markData.radarMark and markData.radarMark ~= 0 then
                            SafeRemoveMark(markData.radarMark)
                            markData.radarMark = nil
                        end
                    end
                    
                    if _G.AHMADConfig.EspOutline then
                        pcall(function()
                            local outlineHash = tostring(_G.AHMADConfig.OutlineThickness)
                            if markData.OutlineState ~= outlineHash then
                                local PPM = Cached_PPM
                                local avatarComp = (type(enemy.getAvatarComponent2) == "function") and enemy:getAvatarComponent2() or nil
                                if Valid(avatarComp) and Valid(PPM) then
                                    PPM.OutlineThickness = _G.AHMADConfig.OutlineThickness
                                    if PPM.OutlineColor then PPM.OutlineColor = {r = 1, g = 0, b = 0, a = 1} end
                                    PPM:EnableAvatarOutline(avatarComp, true)
                                    markData.OutlineState = outlineHash
                                end
                            end
                        end)
                    else
                        pcall(function()
                            if markData.OutlineState ~= "OFF" then
                                local PPM = Cached_PPM
                                local avatarComp = (type(enemy.getAvatarComponent2) == "function") and enemy:getAvatarComponent2() or nil
                                if Valid(avatarComp) and Valid(PPM) then PPM:EnableAvatarOutline(avatarComp, false) end
                                markData.OutlineState = "OFF"
                            end
                        end)
                    end

                else
                    if not markData.IsCleanedUp then
                        SafeRemoveMark(markData.radarMark)
                        markData.radarMark = nil
                        SafeRemoveMark(markData.hpMark)
                        markData.hpMark = nil
                        SafeRemoveMark(markData.hpMark8)
                        markData.hpMark8 = nil
                        SafeRemoveMark(markData.distMark)
                        markData.distMark = nil
                        
                        if markData.MIDs then
                            for meshStr, midTable in pairs(markData.MIDs) do
                                for k, _ in pairs(midTable) do midTable[k] = nil end
                            end
                            markData.MIDs = nil
                        end
                        
                        pcall(function()
                            local eObj = markData.enemy
                            if Valid(eObj) then 
                                if eObj.Replay_SetVisiableOfFrameUI then eObj:Replay_SetVisiableOfFrameUI(false) end
                                local uiComp = eObj.EnemyFrameUI or (type(eObj.GetEnemyFrameUI) == "function" and eObj:GetEnemyFrameUI())
                                if Valid(uiComp) then
                                    if type(uiComp.SetVisibility) == "function" then uiComp:SetVisibility(2) end 
                                    if type(uiComp.SetHiddenInGame) == "function" then uiComp:SetHiddenInGame(true) end
                                end
                            end
                            
                            local PPM = Cached_PPM
                            local avatarComp = Valid(eObj) and (type(eObj.getAvatarComponent2) == "function") and eObj:getAvatarComponent2() or nil
                            if Valid(avatarComp) and Valid(PPM) then PPM:EnableAvatarOutline(avatarComp, false) end
                        end)

                        markData.IsCleanedUp = true
                    end
                end
            end
        end

        -- ========================================== 
        -- ESP TYPE 7: ENEMY COUNTER FORMAT BARU "P: X B: X"
        -- ========================================== 
        if _G.AHMADConfig.Esp7 then
            pcall(function()
                local MyHUD = Cached_MyHUD
                if Valid(MyHUD) then
                    local text = "[ TELEGRAM @UX_Official ]"
                    MyHUD:AddDebugText(text, localPlayer, 0.06, {X=0, Y=0, Z=0}, {X=0, Y=0, Z=0}, {R=255, G=255, B=0, A=255}, true, false, true, nil, 0.8, true)
                end
            end)
        end
    end)
end

_G.AHMADState.LoopToken = (_G.AHMADState.LoopToken or 0) + 1 
local myToken = _G.AHMADState.LoopToken

-- ========================================== 
-- LOOP UTAMA (ESP & FITUR LAIN) DENGAN 0.2 DETIK
-- ========================================== 
local function FastTick() 
    if isExpired then 
        if not _G.AHMADNotifiedExpire then
            Notify("MOD HAS EXPIRED! PLEASE CONTACT ADMIN TO RENEW!\nTelegram @UX_Official")
            _G.AHMADNotifiedExpire = true
            ExpiredTick() 
        end
        return 
    end

    local loginActive = masterLicenseTick()
    if not loginActive then
        local okTicker, ticker = pcall(require, "common.time_ticker")
        if okTicker and ticker and ticker.AddTimerOnce then ticker.AddTimerOnce(0.4, FastTick) end
        return
    end

    if myToken ~= _G.AHMADState.LoopToken then return end
    pcall(MainLoop) 
    local okTicker, ticker = pcall(require, "common.time_ticker") 
    if okTicker and ticker and ticker.AddTimerOnce then 
        ticker.AddTimerOnce(0.4, FastTick) 
    end 
end

-- ========================================== 
-- LOOP KHUSUS AIMBOT FORCE DENGAN 0.016 DETIK (~60 FPS)
-- ========================================== 
local aimbotToken = 0
local function FastAimbotTick()
    if isExpired then 
        return 
    end

    if aimbotToken ~= _G.AHMADState.AimbotLoopToken then 
        return 
    end
    if not masterLicenseAllowed() then return end

    pcall(function()
        if _G.AHMADConfig.AimTouchEnable then
            _G.AimTouch()
        end
    end)

    local okTicker, ticker = pcall(require, "common.time_ticker")
    if okTicker and ticker and ticker.AddTimerOnce then
        ticker.AddTimerOnce(0.016, FastAimbotTick)
    end
end

-- ========================================== 
-- IGNITE BOTH LOOPS
-- ========================================== 
if not isExpired then
    FastTick() 
    _G.AHMADState.AimbotLoopToken = (_G.AHMADState.AimbotLoopToken or 0) + 1
    aimbotToken = _G.AHMADState.AimbotLoopToken
    local okTicker, ticker = pcall(require, "common.time_ticker")
    if okTicker and ticker and ticker.AddTimerOnce then
        ticker.AddTimerOnce(0.1, FastAimbotTick) -- mulai dengan jeda kecil
    end
    Notify("You are using VIP Mod v4. If you don't have a key, inbox Telegram : @UX_Official")
else
    FastTick() 
end

local class = require("class")
local CCharacterBase = require("GameLua.GameCore.Framework.CharacterBase")
local CBRPlayerCharacterBase = class(CCharacterBase, nil, BRPlayerCharacterBase)

return require("combine_class").DeclareFeature(CBRPlayerCharacterBase, {
  {
    SkyTransition = "GameLua.Mod.BaseMod.Gameplay.Feature.SkyControl.PlayerCharacterSkyTransitionFeature"
  },
  {
    CarryDeadBoxFeature = "GameLua.Mod.Library.GamePlay.Feature.CarryDeadBoxFeature"
  },
  {
    SpecialSuitFeature = "GameLua.Mod.Library.GamePlay.Feature.SpecialSuitFeature"
  },
  {
    TeleportPawnFeature = "GameLua.Mod.Library.GamePlay.Feature.TeleportPawnFeature"
  },
  {
    LifterControl = "GameLua.Mod.BaseMod.Gameplay.Feature.Player.CharacterLifterControlFeature"
  },
  {
    FinalKillEffect = "GameLua.Mod.BaseMod.Gameplay.Feature.Player.PlayerCharacterFinalKillEffectFeature"
  },
  {
    CampFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.Camp.PlayerCharacterCampFeature"
  },
  {
    BuildSkateFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.PlayerCharacterBuildVehicleFeature"
  },
  {
    CommonBornlandTransformFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.HeroPropFeature.CommonBornlandTransformFeature"
  },
  {
    ParachuteFormation = "GameLua.Mod.BaseMod.GamePlay.Feature.ParachuteFormationFeature"
  }
}, "BRPlayerCharacterBase")
