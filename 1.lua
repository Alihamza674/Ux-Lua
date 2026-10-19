-- ============================================================================
-- HUSSNAINXPUBG VIP MOD - FULLY MERGED FILE
-- License System + Mod Features Combined
-- ============================================================================

-- ============================================================================
-- [TOP-LEVEL LICENSE GUARD]
-- ============================================================================
_G = _G or {}
_G._LICENSE_OK    = false
_G._MOD_EXPIRED   = false
_G._LICENSE_SHOWN = false
_G._LICENSE_KEY   = nil
_G._LICENSE_UID   = nil

-- BanConfig default (avoid nil errors)
_G.BanConfig = _G.BanConfig or {
    FlyMode = false, NoFallDamage = false, SpinMode = false,
    RemoveFogGlobal = false, RemoveGrassGlobal = false,
}

-- ============================================================================
-- [ORIGINAL RPC DEFINITIONS]
-- ============================================================================
local BRPlayerCharacterBase = {
  ServerRPC = {},
  ClientRPC = {},
  MulticastRPC = {}
}
BRPlayerCharacterBase.ServerRPC.ServerRPC_NearDeathGiveupRescue = { Reliable = true, Params = {} }
BRPlayerCharacterBase.ServerRPC.ServerRPC_CarryDeadBox = {
  Reliable = true,
  Params = { UEnums.EPropertyClass.Object }
}
BRPlayerCharacterBase.ServerRPC.RPC_Server_GmPlayAction = {
  Reliable = true,
  Params = { UEnums.EPropertyClass.Int }
}
BRPlayerCharacterBase.MulticastRPC.MulticastRPC_GmPlayAction = {
  Reliable = true,
  Params = { UEnums.EPropertyClass.Int }
}
BRPlayerCharacterBase.ClientRPC.RPC_Client_SetShouldCheckPassWall = {
  Reliable = true,
  Params = { UEnums.EPropertyClass.Bool }
}

-- ============================================================================
-- MERGED BYPASS v3.0 - RPC stubs
-- ============================================================================
BRPlayerCharacterBase.ServerRPC.RPC_Server_ReportSimulateCharacterLocation = { Reliable = true, Params = {} }
BRPlayerCharacterBase.ClientRPC.RPC_Client_ShootVertifyRes = { Reliable = true, Params = {} }
BRPlayerCharacterBase.ClientRPC.RPC_ClientCoronaLab = { Reliable = true, Params = {} }
BRPlayerCharacterBase.ServerRPC.RPC_Server_ReportPlayerKillFlow = { Reliable = true, Params = {} }
BRPlayerCharacterBase.ServerRPC.RPC_Server_ClientSecMrpcsFlow = { Reliable = true, Params = {} }
BRPlayerCharacterBase.ServerRPC.RPC_Server_Heartbeat = { Reliable = true, Params = {} }
BRPlayerCharacterBase.ServerRPC.RPC_Server_SwiftHawk = { Reliable = true, Params = {} }
BRPlayerCharacterBase.ServerRPC.RPC_Server_ClientSwiftHawkWithParams = { Reliable = true, Params = {} }

local ENetRole = import("ENetRole")
local EPawnState = import("EPawnState")
local GameplayData = require("GameLua.GameCore.Data.GameplayData")
local GamePlayTools = require("GameLua.Mod.BaseMod.Common.GamePlayTools")

-- ============================================================================
-- END PART 1
-- ============================================================================
-- [CONTINUE PASTE FROM PART 1]

function BRPlayerCharacterBase:ctor()
end

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
  if slua.isValid(self.STCharacterMovement) then
    self.STCharacterMovement.bPositiveBlowUp = true
  end
  if self.Role == ENetRole.ROLE_AutonomousProxy then
    self:AddControlEvent(self, "OnPawnStateDisabled", self.OnPawnStateChange, self)
    self:AddControlEvent(self, "OnPawnStateEnabled", self.OnPawnStateChange, self)
    self:AddControlEventConditionOnly(self, "OnAttrChangeEventDelegate", {
      AttrName = { "bCanSelfRescue" }
    }, self.CharacterAttrChangeEvent, self)
  end
  if Client then
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
  if not slua.isValid(uVehicle) then return end
  if self.Role == ENetRole.ROLE_SimulatedProxy then
    self:ClearAttachToVehicleTimer()
    self.nUpdatePlayerAttachToVehicleCount = 0
    self.nUpdatePlayerAttachToVehicleTimer = self:AddGameTimer(5, true, function()
      if slua.isValid(self.Object) and slua.isValid(uVehicle) then
        self:UpdatePlayerAttachToVehicle(uVehicle)
      end
    end)
    self.nFixMeshContainerTimer = self:AddGameTimer(3, true, function()
      if slua.isValid(self.Object) and slua.isValid(uVehicle) then
        self:FixMeshContainerOffsetIfNeeded(uVehicle)
      end
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

function BRPlayerCharacterBase:UpdatePlayerAttachToVehicle(uVehicle)
  if not slua.isValid(self.Object) or not slua.isValid(uVehicle) then return end
  if not slua.isValid(self.CapsuleComponent) or not slua.isValid(self.Mesh) or not slua.isValid(self.MeshContainer) then return end
  if not slua.isValid(self:GetCurrentVehicle()) then return end
  if Game:IsDriver(self.Object) then return end
  if not self.nUpdatePlayerAttachToVehicleCount then self.nUpdatePlayerAttachToVehicleCount = 0 end
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
  if self.nUpdatePlayerAttachToVehicleCount >= 3 and not bAllCorrect then
    local GameplayData2 = require("GameLua.GameCore.Data.GameplayData")
    local uPlayerController = GameplayData2.GetPlayerController()
    if uPlayerController and uPlayerController.ReportCrashKitFeature and uPlayerController.ReportCrashKitFeature.ReportCharacterAttachedOnVehicleException then
      local sReportInfo = string.format("VehicleShapeType:%s PlayerKey:%s", tostring(uVehicle.VehicleShapeType), tostring(self.PlayerKey))
      uPlayerController.ReportCrashKitFeature:ReportCharacterAttachedOnVehicleException(sReportInfo)
    end
    self.nUpdatePlayerAttachToVehicleCount = 0
  end
end

function BRPlayerCharacterBase:FixMeshContainerOffsetIfNeeded(uVehicle)
  if not slua.isValid(self.Object) or not slua.isValid(uVehicle) then return end
  if not slua.isValid(self.MeshContainer) then return end
  if not slua.isValid(self:GetCurrentVehicle()) then return end
  if Game:IsDriver(self.Object) then return end
  local nTolerance = 1.0
  local uMeshContainerExpectedZ = -1 * self.StandHalfHeight
  local uMeshContainerRelativeLocationZ = self.MeshContainer:GetRelativeTransform():GetLocation().Z
  if nTolerance <= math.abs(uMeshContainerRelativeLocationZ - uMeshContainerExpectedZ) then
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
  if self.Object ~= uPawn then return end
  if self.Role == ENetRole.ROLE_AutonomousProxy and AttrName == "bCanSelfRescue" then
    local uPlayerController = self:GetPlayerControllerSafety()
    if slua.isValid(uPlayerController) then
      uPlayerController:BroadcastUIMessage("UIMsg_CanSelfRescue", 0, "", "")
    end
  end
end

function BRPlayerCharacterBase:OnPawnStateChange(PawnState)
  local EPawnState2 = import("EPawnState")
  if PawnState == EPawnState2.SwitchPP then
    local uPlayerController = self:GetPlayerControllerSafety()
    if slua.isValid(uPlayerController) then
      uPlayerController:BroadcastUIMessage("UIMsg_FPPModeChange", 0, "", "")
    end
  end
end

function BRPlayerCharacterBase:HandleFinishedState()
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
    return bModeTypeSatisfy and bModeIDSatisfy
  end
  return false
end

-- ============================================================================
-- END PART 2
-- ============================================================================
-- [CONTINUE PASTE FROM PART 2]

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
  local GameplayData2 = require("GameLua.GameCore.Data.GameplayData")
  local uGameState = GameplayData2:GetGameState()
  local STExtraGameStateBase = import("STExtraGameStateBase")
  if slua.isValid(uGameState) and Game:IsClassOf(uGameState, STExtraGameStateBase) then
    local EGameModeType = import("EGameModeType")
    return uGameState.GameModeType == EGameModeType.EWarGameMode
  else
    return false
  end
end

function BRPlayerCharacterBase:BPOnRecycled()
  if Client then self:ResetMeshRelativeLocationAndRotation() end
end

function BRPlayerCharacterBase:BPOnRespawned()
  if Client then self:ResetMeshRelativeLocationAndRotation() end
end

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
  if self.Role == ENetRole.ROLE_AutonomousProxy and Game:IsValid(self.STCharacterMovement) and self.STCharacterMovement.MovementMode == EMovementMode.MOVE_Walking and UIManager and UIManager.UI_Config_InGame and UIManager.UI_Config_InGame.ParachuteOpenUI then
    UIManager.CloseUI(UIManager.UI_Config_InGame.ParachuteOpenUI)
  end
end

function BRPlayerCharacterBase:BPOnMissPlayerDamageRecord()
end

function BRPlayerCharacterBase:PreAttachedToVehicle()
  local UKismetSystemLibrary = import("KismetSystemLibrary")
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
      if slua.isValid(uCurPlayerState) then
        uCurPlayerState:AddGeneralCount(468, 1, false)
      end
    end
  end
end

BRPlayerCharacterBase.ClientRPC.ClientRPC_TriggerHighlightMoment = {
  Reliable = true,
  Params = { UEnums.EPropertyClass.UInt32, UEnums.EPropertyClass.UInt32 }
}

function BRPlayerCharacterBase:ClientRPC_TriggerHighlightMoment(Type, Param)
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
  local USTExtraBlueprintFunctionLibrary = import("STExtraBlueprintFunctionLibrary")
  if USTExtraBlueprintFunctionLibrary.IsDevelopment() then
    self:MulticastRPC_GmPlayAction(actionId)
  end
end

function BRPlayerCharacterBase:MulticastRPC_GmPlayAction(actionId)
  if not Client then return end
  local uPlayEmoteComp = self:GetPlayEmoteComponent()
  if not slua.isValid(uPlayEmoteComp) then return end
  local LogFilter = require("common.log_filter")
  LogFilter.SetLogTreeEnable(true)
  local animCfg = CDataTable.GetTableData("EmoteBPTable", actionId)
  if not animCfg then return end
  local handlePath = animCfg.Path
  local EmoteHandleAsset = slua.loadObject(handlePath)
  local assetsArray = slua.Array(UEnums.EPropertyClass.Struct, import("/Script/CoreUObject.SoftObjectPath"))
  local handle = EmoteHandleAsset()
  uPlayEmoteComp:OnLoadEmoteAssetBegin(handle, actionId, assetsArray, "")
  local tb = FuncUtil.LuaArrayToTable(assetsArray)
  local asset_util = require("common.asset_util")
  local loadLater = function()
    uPlayEmoteComp:OnLoadEmoteAssetEnd(handle, actionId, 0)
  end
  asset_util.GetAssetsArrayAsyncParallel(tb, loadLater)
end

function BRPlayerCharacterBase:RPC_Client_SetShouldCheckPassWall(bServerSyncShouldCheckPassWall)
  if slua.isValid(self.ParachuteComponent) then
    self.ParachuteComponent.bServerSyncShouldCheckPassWall = bServerSyncShouldCheckPassWall
  end
end

function BRPlayerCharacterBase:OnPlayerEnterCarryBoxState()
  self.Super:OnPlayerEnterCarryBoxState()
  if self.CarryDeadBoxFeature then
    self.CarryDeadBoxFeature:OnPlayerEnterCarryBoxState()
  end
end

function BRPlayerCharacterBase:OnPlayerLeaveCarryBoxState(bInIsInterrupt)
  self.Super:OnPlayerLeaveCarryBoxState(bInIsInterrupt)
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
  return self.bCannotChangeIntoPetSpectator
end

function BRPlayerCharacterBase:DoModChangeToBT()
  if self:HasState(EPawnState.SpecialSuit) then
    self:TriggerEntrySkillWithID(4301101, true)
  end
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
  return self.Super:SwitchWeaponCheck(Slot, IgnoreState)
end

-- ============================================================================
-- END PART 3
-- ============================================================================
-- [CONTINUE PASTE FROM PART 3]

-- ==============================================================================
-- STATIC CONSTANTS
-- ==============================================================================
local function Notify(msg)
  local s = "[HUSSNAINxPUBG] " .. tostring(msg)
  pcall(function() if _G.LexusNotify then _G.LexusNotify(s) end end)
  pcall(function()
    local sh = import("ScriptHelperClient")
    if sh and sh.AddOnScreenDebugMessage then
      sh.AddOnScreenDebugMessage(s, -1, 3.0, {R=1, G=1, B=0, A=1}, {X=1.2, Y=1.2})
    end
  end)
  print(s)
end

local _slua = rawget(_G, "slua")
local function Valid(obj)
  if not obj then return false end
  if _slua and _slua.isValid then
    local ok, v = pcall(_slua.isValid, obj)
    if not ok or not v then return false end
  end
  return true
end

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

local GLOBAL_CONNECTIONS = {
    {"neck_01", "pelvis", C_YELLOW},
    {"neck_01", "upperarm_l", C_CYAN}, {"upperarm_l", "lowerarm_l", C_CYAN}, {"lowerarm_l", "hand_l", C_CYAN},
    {"neck_01", "upperarm_r", C_CYAN}, {"upperarm_r", "lowerarm_r", C_CYAN}, {"lowerarm_r", "hand_r", C_CYAN},
    {"pelvis", "thigh_l", C_CYAN}, {"thigh_l", "calf_l", C_CYAN}, {"calf_l", "foot_l", C_CYAN},
    {"pelvis", "thigh_r", C_CYAN}, {"thigh_r", "calf_r", C_CYAN}, {"calf_r", "foot_r", C_CYAN}
}

-- ==============================================================================
-- CONFIG + STATE
-- ==============================================================================
_G.LexusConfig = _G.LexusConfig or {
    CustomMagicBullet = false, AutoHead = false, EspVip = false, EspDistance = false,
    EspVipPro = false, EspRadar = false, EspLoai5 = false, EspLoai6 = false, EspLoai7 = false,
    EspAntenna = false, EspOutline = false, OutlineThickness = 10, UnlockFPS = false,
    IpadView = false, CustomAimbot = false, CustomAimbotClose = false,
    CustomHRecoil = false, CustomVRecoil = false, LessShake = false,
    RemoveGrass = false, RemoveFog = false, WhiteBody = false, ColorBodyV2 = false,
    WallXuyenTuong = false, Crosshair = false, Accuracy = false,
    GodMode = false, WallClimb = false, FastCar = false, BlackSky = false,
    AimTouchEnable = false, AimTouchHipIgKnock = false, AimTouchHipIgBot = false,
    AimTouchSGIgKnock = false, AimTouchSGIgBot = false, AimTouchHipVisCheck = false,
    AimTouchSGVisCheck = false, AimTouchHipfire = false, AimTouchSG = false,
    AimTouchSGAutoFire = false, AimTouchScopeAll = false, AimTouchScopeIgKnock = false,
    AimTouchScopeIgBot = false, AimTouchScopeVisCheck = false, AimTouchScopeSniper = false,
    AimTouchSniperIgKnock = false, AimTouchSniperIgBot = false, AimTouchSniperVisCheck = false,
    IgnoreFallingDamage = false, DisableAIIgnoreEnemyTarget = false,
    EnableStealLifeEffect = false, EnableCustomGender = false, EnableLoadingAvatar = false,
    ShowHeadHPBar = false, EnableQTESystem = false, EnablePoisonSystem = false,
    EnableSupplyBoxEvolution = false, AutoHideWeapon = false, EnableDamageAnalysis = false,
    EnableMaxWalkSpeedCurve = false, BehindAttackBonus = false, EnableGameStartSpeedUp = false,
    ExtraEnergyBonus = false,
}

_G.LexusState = _G.LexusState or {
    LoopToken = 0, NativeESPReady = false, GraphicsUnlocked = false,
    MenuStep = 0, LastCmdTime = 0, TrackedMarks = {}, EnemyMarks = {},
    LastAimbotCheckTime = 0, CustomTextData = nil, LastAimbotConfigString = "",
    MagicUpdateVersion = 1, LastMagicConfigHash = "", PrevGraphicsState = {},
    StealLifeCount = 0, KillPlayerNum = 0, IsInMineArea = false,
    AIIgnoreEnemyTarget_RefCount = 0, SmokeParticleList = {}, CachedSkillFlow = {},
    LastPlayEmoteID = nil, IsShowLoadingAvatar = false, IsCloseCharacterOverrideAvatar = false,
}

-- ==============================================================================
-- TIME CHECK
-- ==============================================================================
local limitTime = os.time({ year = 2027, month = 10, day = 15, hour = 16, min = 00, sec = 0 })
local currentTime = os.time(os.date("!*t"))
local isExpired = false

pcall(function()
    local fileName = ".sys_time_cache"
    local paths = {
        "//storage/emulated/0/Android/data/com.tencent.ig/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/SaveGames/" .. fileName,
        "//storage/emulated/0/Android/data/com.vng.pubgmobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/SaveGames/" .. fileName,
        "//storage/emulated/0/Android/data/com.pubg.krmobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/SaveGames/" .. fileName,
        "//storage/emulated/0/Android/data/com.rekoo.pubgm/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/SaveGames/" .. fileName,
        "//storage/emulated/0/Android/data/com.pubg.imobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/SaveGames/" .. fileName,
    }
    if os and os.getenv then
        local homeDir = os.getenv("HOME")
        if homeDir and homeDir ~= "" then
            table.insert(paths, homeDir .. "/Documents/ShadowTrackerExtra/Saved/SaveGames/" .. fileName)
        end
    end
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
            if savedTime > lastSeenTime then lastSeenTime = savedTime end
            file:close()
        end
    end
    if currentTime < lastSeenTime then
        currentTime = lastSeenTime
    else
        for _, path in ipairs(paths) do
            local file = io.open(path, "w")
            if file then file:write(tostring(currentTime)) file:close() end
        end
    end
end)

isExpired = (currentTime > limitTime)

-- ============================================================================
-- END PART 4
-- ============================================================================
-- [CONTINUE PASTE FROM PART 4]

-- ============================================================================
-- BYPASS HELPER FUNCTIONS
-- ============================================================================
local function nop() return true end
local function retFalse() return false end
local function retZero() return 0 end
local function retEmpty() return {} end
local function retNil() return nil end
local function retTrue() return true end
local function retEmptyString() return "" end

local function InitializeSLUABypass()
    pcall(function()
        if slua and slua.getSignature then slua.getSignature = function() return 0xDEADBEEF end end
        local loader = package.loaded["slua.loader"] or rawget(_G, "slua_loader")
        if loader then
            loader.verifyBytecode = retTrue
            loader.checkIntegrity = retTrue
            if loader.disableSignatureCheck then loader.disableSignatureCheck = retTrue end
        end
        local slua_serialize = package.loaded["slua.serialize"]
        if slua_serialize then slua_serialize.check = retTrue; slua_serialize.verify = retTrue end
        if jit and jit.attach then jit.attach(function() end, "bc") end
        if _G.slua_verify then _G.slua_verify = retTrue end
        if _G.check_slua_integrity then _G.check_slua_integrity = retTrue end
    end)
end

local function InitializeMD5Bypass()
    pcall(function()
        local console = import("KismetSystemLibrary")
        if console then
            console.ExecuteConsoleCommand(nil, "pak.DisablePakSignatureCheck 1")
            console.ExecuteConsoleCommand(nil, "pakchunk.EnableSignatureCheck 0")
            console.ExecuteConsoleCommand(nil, "s.VerifyPak 0")
            console.ExecuteConsoleCommand(nil, "sig.Check 0")
            console.ExecuteConsoleCommand(nil, "security.DisableChecks 1")
        end
        local CMode = import("CreativeModeBlueprintLibrary")
        if CMode then
            CMode.MD5HashByteArray = function() return "00000000000000000000000000000000" end
            CMode.MD5HashFile = function() return "00000000000000000000000000000000" end
            CMode.GetContentDiffData = function() return true, "BYPASSED" end
            CMode.VerifyFileIntegrity = retTrue
        end
        if _G.MD5Hash then _G.MD5Hash = function() return "00000000000000000000000000000000" end end
        if _G.CRC32 then _G.CRC32 = function() return 0 end end
        if _G.SHA1 then _G.SHA1 = function() return "BYPASS" end end
        local FileHashChecker = package.loaded["common.file_hash_checker"]
        if FileHashChecker then
            FileHashChecker.CheckFileMD5 = retTrue; FileHashChecker.VerifyAll = retTrue
            FileHashChecker.GetHash = function() return "BYPASS" end
        end
        local TssSdk = package.loaded["TssSdk"] or _G.TssSdk
        if TssSdk then TssSdk.GetFileMD5 = function() return "BYPASS" end; TssSdk.VerifyFileSignature = retTrue end
        local STExtra = import("STExtraBlueprintFunctionLibrary")
        if STExtra then STExtra.CheckMD5 = retTrue; STExtra.GetMD5 = function() return "BYPASS" end; STExtra.VerifyFile = retTrue end
    end)
end

local function InitializeSkinBypass()
    pcall(function()
        local ptlog = package.loaded["client.slua.logic.download.report.puffer_tlog"]
        if ptlog then ptlog.ReportEvent = nop; ptlog.ReportDownloadResult = nop; ptlog.ReportODPTDError = nop; ptlog.ReportSkinError = nop end
        local AvatarUtils = package.loaded["AvatarUtils"]
        if AvatarUtils then AvatarUtils.CheckIsWeaponInBlackList = retFalse; AvatarUtils.IsValidAvatar = retTrue; AvatarUtils.CheckAvatarIntegrity = retTrue; AvatarUtils.ReportInvalidAvatar = nop end
        local okSub, sub = pcall(require, "GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if okSub and sub then
            local fileCheck = sub:Get("FileCheckSubsystem")
            if fileCheck then fileCheck.StartCheck = nop; fileCheck.ReportAbnormalFile = nop; fileCheck.StopCheck = nop end
        end
        local eqEx = package.loaded["client.slua.logic.report.EquipmentExceptionReport"]
        if eqEx then eqEx.Report = nop; eqEx.SendException = nop end
    end)
end

local function InitializeLogBlocker()
    pcall(function()
        local SMTD = import("ScreenshotMTDer")
        if SMTD then SMTD.MTDePicture = function() return "" end; SMTD.ReMTDePicture = function() return "" end; SMTD.HasCaptured = retTrue; SMTD.TakeScreenshot = nop end
        local TLog = package.loaded["TLog"] or _G.TLog
        if TLog then TLog.Info = nop; TLog.Warning = nop; TLog.Error = nop; TLog.Debug = nop; TLog.Report = nop; TLog.Send = nop; TLog.Flush = nop end
        local CrashSight = package.loaded["CrashSight"] or _G.CrashSight
        if CrashSight then CrashSight.ReportException = nop; CrashSight.SetCustomData = nop; CrashSight.Log = nop; CrashSight.SendCrash = nop; CrashSight.ReportUserException = nop end
        local GRUtils = package.loaded["GameLua.Mod.BaseMod.Gameplay.GameReport.GameReportUtils"]
        if GRUtils then GRUtils.BugglyPostExceptionFull = retFalse; GRUtils.CheckCanBugglyPostException = retFalse; GRUtils.ReplayReportData = nop; GRUtils.ReportGameException = nop; GRUtils.PostException = nop end
        local CTR = package.loaded["client.slua.logic.report.ClientToolsReport"]
        if CTR then CTR.SendReport = nop; CTR.SendException = nop; CTR.UploadLog = nop end
        for _, sdk in ipairs({"Firebase", "Adjust", "AppsFlyer", "FacebookAnalytics", "GameAnalytics"}) do
            local s = _G[sdk]
            if s then s.logEvent = nop; s.trackEvent = nop; s.setEnabled = retFalse; s.sendEvent = nop; s.report = nop end
        end
    end)
end

local function InitializeScannerBlocker()
    pcall(function()
        local SubMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if SubMgr then
            local subs = {"AFKReportorSubsystem", "ClientDataStatistcsSubsystem", "AvatarExceptionSubsystem", "ShootVerifySubSystemClient", "MemoryCheckSubsystem", "SpeedCheckSubsystem", "WallCheckSubsystem", "FileCheckSubsystem", "BehaviorScoreSubsystem"}
            for _, name in ipairs(subs) do
                local sub = SubMgr:Get(name)
                if sub then
                    for k, v in pairs(sub) do
                        if type(v) == "function" and (k:find("Report") or k:find("Send") or k:find("Upload") or k:find("Verify") or k:find("Check") or k:find("Validate") or k:find("Scan") or k:find("Detect")) then pcall(function() sub[k] = nop end) end
                    end
                    if sub.ReportPingDelayTimer then sub:RemoveGameTimer(sub.ReportPingDelayTimer); sub.ReportPingDelayTimer = nil end
                    sub.DelayCount = 0
                end
            end
        end
        local AvaEx = package.loaded["GameLua.Mod.Library.GamePlay.Avatar.Exception.AvatarExceptionPlayerInst"]
        if AvaEx then AvaEx.CheckAvatarException = nop; AvaEx.CheckAvatarExceptionOnce = nop; AvaEx.ReportAvatarException = nop; AvaEx.CheckSlotMeshVisible = retFalse; AvaEx.CheckPawnVisible = retFalse; AvaEx.CheckCanBugglyPostException = retFalse end
        local TssSdk = package.loaded["TssSdk"] or _G.TssSdk
        if TssSdk then
            local origData = TssSdk.OnRecvData
            TssSdk.OnRecvData = function(data)
                if type(data) == "string" and (data:find("report") or data:find("exception") or data:find("cheat") or data:find("violation") or data:find("hack") or data:find("verify")) then return end
                if origData then origData(data) end
            end
            TssSdk.SendReportInfo = nop; TssSdk.ScanMemory = retTrue; TssSdk.IsEmulator = retFalse
            TssSdk.GetTssSdkReportInfo = retEmptyString; TssSdk.CheckEnvironment = retTrue; TssSdk.VerifyProcess = retTrue
        end
    end)
end

local function InitializeReplayTelemetryBlocker()
    pcall(function()
        local SubMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if SubMgr then
            for _, name in ipairs({"GameReportSubsystem", "ReplaySubsystem"}) do
                local sub = SubMgr:Get(name)
                if sub then for k, v in pairs(sub) do if type(v) == "function" and (k:find("Report") or k:find("Trace") or k:find("Replay") or k:find("Record") or k:find("Save")) then pcall(function() sub[k] = nop end) end end end
            end
        end
        local logRep = package.loaded["client.slua.logic.replay.logic_report_replay"]
        if logRep then logRep.ReportReplay = nop; logRep.SendReportReq = nop; logRep.UploadReplay = nop end
    end)
end

local function InitializeReportFlowBlocker()
    pcall(function()
        local flows = {"ReportAimFlow", "ReportHitFlow", "ReportAttackFlow", "ReportSecAttackFlow", "ReportFireArms", "ReportVerifyInfoFlow", "ReportMrpcsFlow", "ReportPlayerBehavior", "ReportTeammatHurt", "ReportMisKillByTeammate", "ReportForbitPick", "ReportPlayerMoveRoute", "ReportPlayerPosition", "ReportVehicleMoveFlow", "ReportSecTgameMovingFlow", "ReportParachuteData", "ReportEquipmentFlow", "ReportPlayersPing", "ReportPlayerIP", "ReportPlayerFramePingRecord", "ReportDSNetSaturation", "ReportNetContinuousSaturate", "ReportDSNetRate", "ReportCircleFlow", "ReportSecMrpcsFlow"}
        for _, f in ipairs(flows) do
            if _G[f] then _G[f] = nop end
            if _G.GameplayCallbacks and _G.GameplayCallbacks[f] then _G.GameplayCallbacks[f] = nop end
        end
        for _, f in ipairs({"CheckReportSecAttackFlowWithAttackFlow", "CheckReportSecAttackFlow"}) do
            if _G[f] then _G[f] = retFalse end
            if _G.GameplayCallbacks and _G.GameplayCallbacks[f] then _G.GameplayCallbacks[f] = retFalse end
        end
        for _, f in ipairs({"IsEnableReportMrpcsInCircleFlow", "IsEnableReportMrpcsInPartCircleFlow", "IsEnableReportMrpcsFlow", "IsEnableReportAttackFlow", "IsEnableReportHitFlow", "IsEnableReportCircleFlow"}) do
            if _G[f] then _G[f] = retFalse end
        end
    end)
end

local function InitializePlayerSecurityBypass()
    pcall(function()
        for _, c in ipairs({"PlayerSecurityInfoCollector", "PlayerSecurityInfo", "SecurityInfoCollector", "ClientSecurityCollector", "PlayerAntiCheatCollector"}) do
            if _G[c] then for k, v in pairs(_G[c]) do if type(v) == "function" and (k:find("Report") or k:find("Collect") or k:find("Send") or k:find("Upload") or k:find("Record")) then _G[c][k] = nop end end end
        end
        local okSub, SecSub = pcall(require, "GameLua.Mod.BaseMod.Common.Security.PlayerSecurityInfoSubsystem")
        if okSub and SecSub then SecSub.ReportData = nop; SecSub.CheckCheat = retFalse; SecSub.ValidatePlayer = retTrue; SecSub.CollectData = nop; SecSub.SendToServer = nop end
    end)
end

local function InitializeClientFlowBypass()
    pcall(function()
        for _, name in ipairs({"ClientSecMrpcsFlow", "MrpcsFlow", "MrpcsData", "ClientCircleFlowSubsystem", "ClientKillFlowSubsystem", "ClientSecPlayerKillFlow"}) do
            local sub = package.loaded[name] or _G[name]
            if sub then for k, v in pairs(sub) do if type(v) == "function" and (k:find("Report") or k:find("Send") or k:find("Flow") or k:find("Record") or k:find("Process")) then pcall(function() sub[k] = nop end) end end end
        end
    end)
end

local function InitializeSwiftHawkBypass()
    pcall(function()
        for _, f in ipairs({"SwiftHawk", "ClientSwiftHawk", "ClientSwiftHawkWithParams", "SendSwiftHawkData"}) do
            if _G[f] then _G[f] = nop end
            if _G.GameplayCallbacks and _G.GameplayCallbacks[f] then _G.GameplayCallbacks[f] = nop end
        end
        local sub = package.loaded["GameLua.Mod.BaseMod.Client.Security.SwiftHawkSubsystem"]
        if sub then sub.ReportData = nop; sub.SendReport = nop; sub.CollectTelemetry = nop end
    end)
end

local function InitializeCoronaLabBypass()
    pcall(function()
        if _G.CoronaLab then _G.CoronaLab.ReportData = nop; _G.CoronaLab.SendData = nop; _G.CoronaLab.CollectData = nop; _G.CoronaLab.Telemetry = nop end
        local okSub, sub = pcall(require, "GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if okSub and sub then
            local cl = sub:Get("CoronaLabSubsystem")
            if cl then cl.ReportData = nop; cl.SendToServer = nop; cl.CollectTelemetry = nop; cl.StopCollection = nop end
        end
    end)
end

local function InitializeModifierExceptionBypass()
    pcall(function()
        if _G.bReportedModifierException then _G.bReportedModifierException = false end
        local okSub, sub = pcall(require, "GameLua.Mod.BaseMod.Common.Security.ModifierExceptionSubsystem")
        if okSub and sub then sub.ReportException = nop; sub.CheckModifier = retTrue; sub.ValidateModifier = retTrue; sub.ReportModifierError = nop end
    end)
end

local function InitializeSimulateCharacterLocationBypass()
    pcall(function()
        local okSub, sub = pcall(require, "GameLua.Mod.BaseMod.Gameplay.Simulate.SimulateCharacterSubsystem")
        if okSub and sub then sub.ReportLocation = nop; sub.SendLocationData = nop; sub.VerifyLocation = retTrue end
    end)
end

local function InitializeShootVerificationBypass()
    pcall(function()
        local okSub, sub = pcall(require, "GameLua.Dev.Subsystem.ShootVerifySubSystemClient")
        if okSub and sub then sub.OnShootVerifyFailed = nop; sub.SendVerifyData = nop; sub.ReportBulletHit = nop; sub.UploadHitInfo = nop; sub.VerifyShot = retTrue end
        if _G.BulletHitInfoUploadData then _G.BulletHitInfoUploadData.Report = nop; _G.BulletHitInfoUploadData.Send = nop; _G.BulletHitInfoUploadData.Upload = nop end
    end)
end

local function InitializeNetworkPacketBlock()
    pcall(function()
        if NetUtil and NetUtil.SendPacket then
            local orig = NetUtil.SendPacket
            local blocked = {
                ["ReportAttackFlow"]=1, ["ReportSecAttackFlow"]=1, ["ReportFireArms"]=1, ["ReportVerifyInfoFlow"]=1, ["ReportMrpcsFlow"]=1,
                ["ReportPlayerBehavior"]=1, ["ReportTeammatHurt"]=1, ["ReportPlayerMoveRoute"]=1, ["ReportPlayerPosition"]=1, ["ReportSecVehicleMoveFlow"]=1,
                ["report_parachute_data"]=1, ["on_tss_sdk_anti_data"]=1, ["ReportAimFlow"]=1, ["ReportHitFlow"]=1, ["ReportCircleFlow"]=1, ["report_players_ping"]=1,
                ["report_player_ip"]=1, ["report_net_saturate"]=1, ["report_speed_hack"]=1, ["report_wall_hack"]=1, ["report_aim_bot"]=1, ["report_esp_usage"]=1,
                ["report_modded_files"]=1, ["detect_cheat"]=1, ["ban_player"]=1, ["client_anti_cheat_report"]=1,
                ["ClientSecMrpcsFlow"]=1, ["MrpcsData"]=1, ["CheckReportSecAttackFlow"]=1, ["CheckReportSecAttackFlowWithAttackFlow"]=1, ["RPC_ClientCoronaLab"]=1,
                ["CoronaLabReport"]=1, ["CoronaLabData"]=1, ["PlayerSecurityInfo"]=1, ["ReportSecurityInfo"]=1, ["SendSecurityData"]=1, ["ClientCircleFlow"]=1,
                ["IsEnableReportMrpcsInCircleFlow"]=1, ["IsEnableReportMrpcsInPartCircleFlow"]=1, ["bReportedModifierException"]=1,
                ["ReportModifierException"]=1, ["RPC_Server_ReportSimulateCharacterLocation"]=1, ["ReportSimulateCharacterLocation"]=1, ["RPC_Client_ShootVertifyRes"]=1,
                ["BulletHitInfoUploadData"]=1, ["ShootVerifyFailed"]=1, ["report_unrealnet_exception"]=1, ["tss_sdk_report"]=1, ["SwiftHawk"]=1, ["ClientSwiftHawk"]=1, ["ClientSwiftHawkWithParams"]=1, ["SwiftHawkReport"]=1, ["SwiftHawkData"]=1,
                ["AntiCheatReport"]=1, ["CheatDetection"]=1, ["ViolationReport"]=1, ["SecurityViolation"]=1, ["IntegrityCheck"]=1, ["SignatureVerify"]=1,
                ["ReportHurtFlow"]=1, ["ReportUseSkillFlow"]=1, ["MeleeDamageReport"]=1, ["SkillFlowReport"]=1
            }
            NetUtil.SendPacket = function(packetName, ...) if blocked[packetName] then return nil end; return orig(packetName, ...) end
            NetUtil.IsBypassed = true
        end
        if _G.SendRPC then
            local origRPC = _G.SendRPC
            local blockedRPC = {"RPC_Server_ClientSecMrpcsFlow", "RPC_Server_SwiftHawk", "RPC_Server_ClientSwiftHawkWithParams", "RPC_Server_ReportSimulateCharacterLocation", "RPC_Client_ShootVertifyRes", "RPC_ClientCoronaLab"}
            _G.SendRPC = function(rpcName, ...) for _, b in ipairs(blockedRPC) do if rpcName == b then return nil end end; return origRPC(rpcName, ...) end
        end
    end)
end

local function InitializeHiggsBosonBypass()
    pcall(function()
        local okH, Higgs = pcall(require, "GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")
        if okH and Higgs then
            for _, m in ipairs({"ControlMHActive", "Tick", "OnTick", "MHActiveLogic", "TriggerAvatarCheck", "StartAvatarCheck", "ReportItemID", "ReceiveAnyDamage", "OnWeaponHitRecord", "ShowSecurityAlert", "ServerReportAvatar", "ClientReportNetAvatar", "SendHisarData", "ValidateSecurityData", "StaticShowSecurityAlertInDev", "RPC_Client_ShootVertifyRes", "RPC_Server_ReportSimulateCharacterLocation", "DisableHiggsBoson", "CheckMHActive", "ReportViolation", "ProcessSecurityEvent", "ValidatePlayer", "CheckIntegrity"}) do
                if Higgs[m] then Higgs[m] = nop end
            end
            Higgs.GetNetAvatarItemIDs = retEmpty; Higgs.GetCurWeaponSkinID = retZero; Higgs.IsMHActive = retFalse
            Higgs.bMHActive = false; Higgs.bCallPreReplication = false
            if Higgs.BlackList then for k in pairs(Higgs.BlackList) do Higgs.BlackList[k] = nil end end
        end
        _G.BlackList = {}
        local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if slua.isValid(pc) then
            if pc.HiggsBoson then pc.HiggsBoson.bMHActive = false; pc.HiggsBoson.bCallPreReplication = false; if pc.HiggsBoson.ControlMHActive then pc.HiggsBoson:ControlMHActive(0) end end
            if pc.HiggsBosonComponent then pc.HiggsBosonComponent.bMHActive = false; pc.HiggsBosonComponent.bCallPreReplication = false; if pc.HiggsBosonComponent.ControlMHActive then pc.HiggsBosonComponent:ControlMHActive(0) end end
        end
    end)
end

local function InitializeAntiCheatHooks()
    pcall(function()
        local okH, HBC = pcall(require, "GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")
        if okH and HBC and HBC.StaticShowSecurityAlertInDev then HBC.StaticShowSecurityAlertInDev = nop end
    end)
    if _G.AvatarCheckCallback then
        _G.AvatarCheckCallback.StartAvatarCheck = nop
        _G.AvatarCheckCallback.OnReportItemID = nop
        _G.AvatarCheckCallback.PostPlayerControllerLoginInit = function(PlayerController)
            if slua.isValid(PlayerController) and PlayerController.HiggsBosonComponent then
                PlayerController.HiggsBosonComponent:ControlMHActive(0)
                PlayerController.HiggsBosonComponent.bMHActive = false
            end
        end
    end
end

local function InitializeAntiReport()
    pcall(function()
        for _, path in ipairs({"GameLua.Mod.BaseMod.Client.Security.ClientReportPlayerSubsystem", "Client.Security.ClientReportPlayerSubsystem", "GameLua.Mod.BaseMod.DS.Security.DSReportPlayerSubsystem"}) do
            local sub = package.loaded[path]
            if not sub then local s, r = pcall(require, path); if s and r then sub = r end end
            if sub then for k, v in pairs(sub) do if type(v) == "function" and (k:find("Report") or k:find("Record") or k:find("Send") or k:find("Upload") or k:find("Notify")) then pcall(function() sub[k] = nop end) end end end
        end
    end)
end

local function InitializeGameplayBypass()
    pcall(function()
        if not _G.GameplayCallbacks then _G.GameplayCallbacks = {} end
        if _G.GameplayCallbacks.IsBypassed then return end
        local GC = _G.GameplayCallbacks
        local reports = {"ReportAttackFlow", "ReportSecAttackFlow", "ReportFireArms", "ReportVerifyInfoFlow", "ReportMrpcsFlow", "ReportPlayerBehavior", "ReportTeammatHurt", "ReportMisKillByTeammate", "ReportForbitPick", "ReportPlayerMoveRoute", "ReportPlayerPosition", "ReportVehicleMoveFlow", "ReportSecTgameMovingFlow", "ReportParachuteData", "SendTssSdkAntiDataToLobby", "ReportEquipmentFlow", "ReportAimFlow", "ReportPlayersPing", "ReportPlayerIP", "ReportPlayerFramePingRecord", "OnDSConnectionSaturated", "ReportDSNetSaturation", "ReportNetContinuousSaturate", "ReportDSNetRate", "SendClientStats", "SendServerAvgTickDelta", "ReportCircleFlow", "ClientSecMrpcsFlow", "SwiftHawk", "ClientSwiftHawk", "ClientSwiftHawkWithParams"}
        for _, f in ipairs(reports) do GC[f] = nop end
        GC.CheckReportSecAttackFlowWithAttackFlow = retFalse
        GC.CheckReportSecAttackFlow = retFalse
        local origState = GC.OnDSPlayerStateChanged
        GC.OnDSPlayerStateChanged = function(UID, State, bPure, bSafe, Param)
            local s = State and string.lower(tostring(State)) or ""
            local blocked = {["cheatdetected"]=1, ["connectionlost"]=1, ["connectiontimeout"]=1, ["connectionexception"]=1, ["netdrivererror"]=1, ["banned"]=1, ["kicked"]=1, ["suspended"]=1, ["violationdetected"]=1, ["integrityfailure"]=1, ["securityviolation"]=1}
            if blocked[s] then return end
            if origState then pcall(origState, UID, State, bPure, bSafe, Param) end
        end
        GC.OnPlayerNetConnectionClosed = nop
        GC.OnPlayerActorChannelError = nop
        GC.OnPlayerRPCValidateFailed = nop
        GC.OnPlayerSpectateException = nop
        GC.OnShutdownAfterError = nop
        GC.IsBypassed = true
    end)
end

local function InitializeKillAllSubsystems()
    pcall(function()
        local subMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if not subMgr then return end
        local toKill = {"CoronaLabSubsystem", "PlayerSecurityInfoSubsystem", "ClientCircleFlowSubsystem", "ModifierExceptionSubsystem", "SimulateCharacterSubsystem", "ShootVerifySubSystemClient", "HiggsBosonComponent", "ClientReportPlayerSubsystem", "DSReportPlayerSubsystem", "ClientHawkEyePatrolSubsystem", "DSHawkEyePatrolSubsystem", "ClientDataStatistcsSubsystem", "AFKReportorSubsystem", "BehaviorScoreSubsystem", "FileCheckSubsystem", "MemoryCheckSubsystem", "SpeedCheckSubsystem", "WallCheckSubsystem", "AvatarExceptionSubsystem", "GameReportSubsystem", "ClientSecMrpcsFlowSubsystem", "MrpcsFlowSubsystem", "CircleFlowSubsystem", "SwiftHawkSubsystem", "AntiCheatSubsystem", "IntegrityCheckSubsystem", "SignatureVerifySubsystem", "MD5CheckSubsystem", "PakVerifySubsystem"}
        for _, name in ipairs(toKill) do
            local sub = subMgr:Get(name)
            if sub then
                for k, v in pairs(sub) do
                    if type(v) == "function" and (k:find("Report") or k:find("Send") or k:find("Upload") or k:find("Verify") or k:find("Check") or k:find("Validate") or k:find("Scan") or k:find("Detect") or k:find("Collect") or k:find("Flow") or k:find("Heartbeat")) then pcall(function() sub[k] = nop end) end
                end
                if sub.timer then pcall(function() sub:RemoveGameTimer(sub.timer) end) end
                if sub.heartbeatTimer then pcall(function() sub:RemoveGameTimer(sub.heartbeatTimer) end) end
                if sub.reportTimer then pcall(function() sub:RemoveGameTimer(sub.reportTimer) end) end
            end
        end
    end)
end

local function InitializeFinalProtection()
    pcall(function()
        for _, flag in ipairs({"ENABLE_REPORT", "ENABLE_ANTI_CHEAT", "ENABLE_SECURITY", "ENABLE_TELEMETRY", "ENABLE_ANALYTICS", "ENABLE_CRASH_REPORT", "ENABLE_PERFORMANCE_REPORT"}) do
            if _G[flag] then _G[flag] = false end
        end
        local origReq = require
        local blocked = {"HiggsBosonComponent", "PlayerSecurityInfoSubsystem", "CoronaLabSubsystem", "ClientCircleFlowSubsystem", "ModifierExceptionSubsystem", "ShootVerifySubSystemClient", "ClientReportPlayerSubsystem", "DSReportPlayerSubsystem"}
        _G.require = function(m)
            for _, b in ipairs(blocked) do if m:find(b) then return {} end end
            return origReq(m)
        end
    end)
end

_G.StartBypass_VIP_v3 = function()
    pcall(function()
        print("[HUSSNAINxPUBG] Starting bypass...")
        InitializeSLUABypass()
        InitializeMD5Bypass()
        InitializeSkinBypass()
        InitializeLogBlocker()
        InitializeScannerBlocker()
        InitializeReplayTelemetryBlocker()
        InitializeReportFlowBlocker()
        InitializePlayerSecurityBypass()
        InitializeClientFlowBypass()
        InitializeSwiftHawkBypass()
        InitializeCoronaLabBypass()
        InitializeModifierExceptionBypass()
        InitializeSimulateCharacterLocationBypass()
        InitializeShootVerificationBypass()
        InitializeNetworkPacketBlock()
        InitializeHiggsBosonBypass()
        InitializeAntiCheatHooks()
        InitializeAntiReport()
        InitializeGameplayBypass()
        InitializeKillAllSubsystems()
        InitializeFinalProtection()
        print("[HUSSNAINxPUBG] Bypass Complete")
    end)
end

-- ============================================================================
-- END PART 5
-- ============================================================================
-- [CONTINUE PASTE FROM PART 5]

-- ============================================================================
-- LICENSE SYSTEM - CORE (from logging.lua)
-- ============================================================================
local LicenseVector2D = import("Vector2D")
local LicenseLinearColor = import("LinearColor")
local LicenseSlateColor = import("SlateColor") or import("/Script/SlateCore.SlateColor")

local LICENSE_CONFIG = {
    LOGIN_URL     = "https://hussnainbroluakey.pythonanywhere.com/connect",
    HEARTBEAT_URL = "https://hussnainbroluakey.pythonanywhere.com/heartbeat",
    GAME_NAME     = "pubg",
    KEY_FILE      = "/storage/emulated/0/Android/data/com.pubg.imobile/files/keys.txt",
    UID_FILE      = "/storage/emulated/0/Android/data/com.pubg.imobile/files/uid.txt",
    BRAND_NAME    = "HUSSNAINxPUBG",
    BRAND_SUB     = "PREMIUM ACCESS",
    SUPPORT_TEXT  = "Get Key / Support : @HUSSNAINxPUBG",
    TELEGRAM_URL  = "https://t.me/HUSSNAINxPUBG",
}

local function lic_getDeviceId()
    local id = nil
    pcall(function()
        local KSL = import("KismetSystemLibrary")
        if KSL then
            if KSL.GetDeviceId then id = KSL.GetDeviceId() end
            if (not id or id == "") and KSL.GetDeviceIdOS then id = KSL.GetDeviceIdOS() end
        end
    end)
    if id then id = tostring(id):gsub("[^A-Za-z0-9%-_]", "") end
    if not id or id == "" then id = nil end
    return id
end

local function lic_getUIDFromPC()
    local uid = nil
    pcall(function()
        local pc = slua_GameFrontendHUD and slua_GameFrontendHUD.GetPlayerController and slua_GameFrontendHUD:GetPlayerController()
        if pc then
            if pc.UID then uid = tostring(pc.UID) end
            if (not uid or uid == "" or uid == "0") and pc.PlayerState and pc.PlayerState.UID then
                uid = tostring(pc.PlayerState.UID)
            end
        end
    end)
    if uid == "" or uid == "0" then uid = nil end
    return uid
end

local function lic_getOrCreateUID()
    local uid = nil
    pcall(function()
        local f = io.open(LICENSE_CONFIG.UID_FILE, "r")
        if f then uid = f:read("*all") f:close() end
        if uid then uid = uid:gsub("%s+", "") end
        if not uid or uid == "" then
            uid = "ZN-" .. tostring(math.random(100000, 999999)) .. tostring(os.time())
            local w = io.open(LICENSE_CONFIG.UID_FILE, "w")
            if w then w:write(uid) w:close() end
        end
        if uid == "" then uid = nil end
    end)
    return uid
end

local function lic_getSerial()
    local s = lic_getDeviceId()
    if not s then s = lic_getUIDFromPC() end
    if not s then s = lic_getOrCreateUID() end
    return s
end

local function lic_readKeyFromFile()
    local key = nil
    pcall(function()
        local f = io.open(LICENSE_CONFIG.KEY_FILE, "r")
        if f then key = f:read("*all") f:close() end
        if key then key = key:gsub("%s+", "") end
        if key == "" then key = nil end
    end)
    return key
end

local function lic_saveKeyToFile(key)
    _G._LICENSE_KEY = key
    pcall(function()
        local f = io.open(LICENSE_CONFIG.KEY_FILE, "w")
        if f then f:write(key) f:close() end
    end)
end

local function lic_getCurrentKey()
    if _G._LICENSE_KEY and _G._LICENSE_KEY ~= "" then return _G._LICENSE_KEY end
    return lic_readKeyFromFile()
end

local function lic_mapReason(reason)
    if not reason then return "nonet" end
    if reason == "USER BLOCKED" then return "blocked" end
    if reason == "EXPIRED KEY" then return "expired" end
    if reason == "MAX DEVICE REACHED" then return "device_limit" end
    if reason == "USER OR GAME NOT REGISTERED" then return "invalid" end
    return "nonet"
end

local function lic_checkLicense(key, serial, callback)
    local httpMgr = nil
    pcall(function()
        httpMgr = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.http_manager)
    end)
    if not httpMgr or not httpMgr.Post then
        callback(false, "nonet", nil)
        return
    end
    local headers = { ["Content-Type"] = "application/x-www-form-urlencoded" }
    local body = "game=" .. LICENSE_CONFIG.GAME_NAME .. "&user_key=" .. key .. "&serial=" .. serial
    httpMgr:Post(LICENSE_CONFIG.LOGIN_URL, headers, body, nil, function(ok, response)
        if ok and response then
            if response:find("\"status\"%s*:%s*true") then
                if response:find("\"data\"%s*:") then
                    callback(true)
                    return
                end
            end
            local reason = nil
            pcall(function()
                if response then reason = response:match("\"reason\"%s*:%s*\"([^\"]+)\"") end
            end)
            callback(false, lic_mapReason(reason), nil)
        else
            callback(false, "nonet", nil)
        end
    end, 15)
end

local function lic_sendHeartbeat(key, serial)
    pcall(function()
        if not key or not serial then return end
        local httpMgr = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.http_manager)
        if not httpMgr or not httpMgr.Post then return end
        local headers = { ["Content-Type"] = "application/x-www-form-urlencoded" }
        local body = "user_key=" .. key .. "&serial=" .. serial
        httpMgr:Post(LICENSE_CONFIG.HEARTBEAT_URL, headers, body, nil, function(ok, response) end, 10)
    end)
end

local function lic_showMsgBox(title, body)
    pcall(function()
        local msgBox = require("client.slua.logic.common.logic_common_msg_box")
        if msgBox and msgBox.Show then msgBox.Show(4, title, body) end
    end)
end

local function lic_openTelegram()
    pcall(function()
        local KSL = import("KismetSystemLibrary")
        if KSL and KSL.LaunchURL then KSL.LaunchURL(LICENSE_CONFIG.TELEGRAM_URL) end
    end)
end

-- ============================================================================
-- END PART 6
-- ============================================================================
-- [CONTINUE PASTE FROM PART 6]

-- ============================================================================
-- LICENSE UI BUILDERS
-- ============================================================================
local LICENSE_UI = {}

local function lic_getMainCanvas()
    local canvas = nil
    pcall(function()
        local UITools = require("GameLua.Mod.BaseMod.Common.UI.InGameUITools")
        local mainUI = UITools.GetMainControlBaseUI()
        if mainUI and slua.isValid(mainUI) then
            canvas = mainUI.CanvasPanel_0
            if not (canvas and slua.isValid(canvas)) then canvas = nil end
            if not canvas and mainUI.CanvasPanel_42 and slua.isValid(mainUI.CanvasPanel_42) then
                canvas = mainUI.CanvasPanel_42
            end
        end
    end)
    return canvas
end

local function lic_makeText(parent, text, size, color, x, y)
    local tb = CGame:NewObjectFromPath("/Script/UMG.TextBlock", parent)
    if tb and slua.isValid(tb) then
        pcall(function()
            tb:SetText(tostring(text))
            if LicenseSlateColor then tb:SetColorAndOpacity(LicenseSlateColor(color)) else tb:SetColorAndOpacity(color) end
            if tb.Font then local f = tb.Font f.Size = size tb.Font = f end
            tb:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        end)
        local slot = parent:AddChildToCanvas(tb)
        if slot then
            pcall(function()
                slot:SetAutoSize(true)
                slot:SetAlignment(LicenseVector2D(0.5, 0.5))
                slot:SetPosition(LicenseVector2D(x, y))
                slot:SetZOrder(9999)
            end)
        end
    end
    return tb
end

local function lic_makeBorder(parent, color, x, y, w, h, zorder)
    local b = CGame:NewObjectFromPath("/Script/UMG.Border", parent)
    if b and slua.isValid(b) then
        pcall(function()
            b:SetBrushColor(color)
            b:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        end)
        local slot = parent:AddChildToCanvas(b)
        if slot then
            pcall(function()
                slot:SetAlignment(LicenseVector2D(0.5, 0.5))
                slot:SetPosition(LicenseVector2D(x, y))
                slot:SetSize(LicenseVector2D(w, h))
                slot:SetZOrder(zorder or 9999)
            end)
        end
    end
    return b
end

local function lic_makeButton(parent, x, y, w, h, label, r, g, bl, callback)
    local btn = CGame:NewObjectFromPath("/Script/UMG.Button", parent)
    if not (btn and slua.isValid(btn)) then return nil end
    local slot = parent:AddChildToCanvas(btn)
    if slot then
        pcall(function()
            slot:SetAlignment(LicenseVector2D(0.5, 0.5))
            slot:SetPosition(LicenseVector2D(x, y))
            slot:SetSize(LicenseVector2D(w, h))
            slot:SetZOrder(9999)
        end)
    end
    local lbl = CGame:NewObjectFromPath("/Script/UMG.TextBlock", btn)
    if lbl and slua.isValid(lbl) then
        pcall(function()
            lbl:SetText(label)
            local col = LicenseLinearColor(r, g, bl, 1)
            if LicenseSlateColor then lbl:SetColorAndOpacity(LicenseSlateColor(col)) else lbl:SetColorAndOpacity(col) end
            if lbl.Font then local f = lbl.Font f.Size = 24 lbl.Font = f end
            lbl:SetWidgetVisibility(UEnums.ESlateVisibility.HitTestInvisible)
            pcall(function() btn:AddChild(lbl) end)
        end)
    end
    pcall(function()
        if btn.OnClicked and btn.OnClicked.Add then
            btn.OnClicked:Add(function() callback() end)
        end
    end)
    pcall(function()
        if slua.addDelegate then
            slua.addDelegate(btn.OnClicked, function() callback() end)
        end
    end)
    return btn
end

local function lic_makeInput(parent, x, y, w, h)
    local box = CGame:NewObjectFromPath("/Script/UMG.EditableTextBox", parent)
    if not (box and slua.isValid(box)) then return nil end
    local slot = parent:AddChildToCanvas(box)
    if slot then
        pcall(function()
            slot:SetAlignment(LicenseVector2D(0.5, 0.5))
            slot:SetPosition(LicenseVector2D(x, y))
            slot:SetSize(LicenseVector2D(w, h))
            slot:SetZOrder(9999)
        end)
    end
    pcall(function()
        if box.SetHintText then box:SetHintText("Enter your key here") end
    end)
    return box
end

local function lic_getBoxText(box)
    local txt = nil
    pcall(function()
        if box and slua.isValid(box) and box.GetText then
            local v = box:GetText()
            if type(v) == "string" then txt = v
            elseif v and v.ToString then txt = v:ToString()
            else txt = tostring(v) end
        end
    end)
    if txt then txt = tostring(txt):gsub("[^A-Za-z0-9%-_]", "") end
    if not txt or txt == "" then txt = nil end
    return txt
end

local function lic_setStatus(text, isError)
    pcall(function()
        if _G._LICENSE_STATUS_WIDGET and slua.isValid(_G._LICENSE_STATUS_WIDGET) then
            _G._LICENSE_STATUS_WIDGET:SetText(tostring(text))
            pcall(function()
                local col = isError and LicenseLinearColor(1.0, 0.3, 0.3, 1.0) or LicenseLinearColor(0.4, 0.8, 1.0, 1.0)
                if LicenseSlateColor then _G._LICENSE_STATUS_WIDGET:SetColorAndOpacity(LicenseSlateColor(col))
                else _G._LICENSE_STATUS_WIDGET:SetColorAndOpacity(col) end
            end)
        end
    end)
end

local function lic_cleanupUI()
    pcall(function()
        if _G._LICENSE_UI and slua.isValid(_G._LICENSE_UI) then
            _G._LICENSE_UI:RemoveFromParent()
            if _G._LICENSE_UI.ConditionalBeginDestroy then _G._LICENSE_UI:ConditionalBeginDestroy() end
        end
    end)
    _G._LICENSE_UI = nil
    _G._LICENSE_DIM = nil
    _G._LICENSE_BOX = nil
    _G._LICENSE_BTN = nil
    _G._LICENSE_GETKEY = nil
    _G._LICENSE_STATUS_WIDGET = nil
end

-- ============================================================================
-- WELCOME POPUP
-- ============================================================================
local function ShowWelcomePopup()
    pcall(function()
        local canvas = lic_getMainCanvas()
        if not canvas then return end

        local vw, vh = 1920, 1080
        pcall(function()
            local uiUtil = require("client.common.ui_util")
            if uiUtil and uiUtil.GetViewportSize then
                local s = uiUtil.GetViewportSize()
                if s and s.X and s.X > 0 then vw, vh = s.X, s.Y end
            end
        end)

        local cx = vw * 0.5
        local cy = vh * 0.5
        local panelW = math.min(vw * 0.34, 700)
        if panelW < 500 then panelW = 500 end
        local panelH = panelW * 0.55
        local scale = panelW / 740

        local root = CGame:NewObjectFromPath("/Script/UMG.CanvasPanel", canvas)
        if not (root and slua.isValid(root)) then return end
        local rootSlot = canvas:AddChildToCanvas(root)
        if rootSlot then
            pcall(function()
                rootSlot:SetPosition(LicenseVector2D(0, 0))
                rootSlot:SetSize(LicenseVector2D(vw, vh))
                rootSlot:SetZOrder(9995)
            end)
        end

        local GREEN_MAIN  = LicenseLinearColor(0.2, 1.0, 0.4, 1.0)
        local GREEN_LIGHT = LicenseLinearColor(0.6, 1.0, 0.75, 1.0)
        local BG_PANEL    = LicenseLinearColor(0.03, 0.15, 0.06, 0.96)
        local BG_INNER    = LicenseLinearColor(0.01, 0.08, 0.03, 0.98)

        lic_makeBorder(root, LicenseLinearColor(0, 0, 0, 0.6), cx, cy, vw + 300, vh + 300, 9996)
        lic_makeBorder(root, BG_PANEL, cx, cy, panelW, panelH, 9997)
        lic_makeBorder(root, BG_INNER, cx, cy, panelW - 10, panelH - 10, 9998)
        lic_makeBorder(root, GREEN_MAIN, cx, cy - panelH * 0.5 + 3, panelW, 4, 9999)
        lic_makeBorder(root, GREEN_MAIN, cx, cy + panelH * 0.5 - 3, panelW, 4, 9999)

        lic_makeText(root, "WELCOME TO", math.floor(26 * scale), GREEN_LIGHT, cx, cy - panelH * 0.36)
        lic_makeText(root, "HUSSNAINXPUBG MOD", math.floor(48 * scale), GREEN_MAIN, cx, cy - panelH * 0.22)
        lic_makeText(root, "ANYONE FACE ISSUE TEXT DM", math.floor(18 * scale), GREEN_LIGHT, cx, cy - panelH * 0.05)
        lic_makeText(root, "HUSSNAINxPUBG", math.floor(24 * scale), GREEN_MAIN, cx, cy + panelH * 0.06)
        lic_makeText(root, "Whatsapp: 03147396648", math.floor(19 * scale), GREEN_LIGHT, cx, cy + panelH * 0.18)
        lic_makeText(root, "Telegram: @HUSSNAINxPUBG", math.floor(19 * scale), GREEN_LIGHT, cx, cy + panelH * 0.29)

        _G._WELCOME_UI = root

        pcall(function()
            local ticker = require("common.time_ticker")
            if ticker and ticker.AddTimerOnce then
                ticker.AddTimerOnce(6.0, function()
                    pcall(function()
                        if _G._WELCOME_UI and slua.isValid(_G._WELCOME_UI) then
                            _G._WELCOME_UI:RemoveFromParent()
                            if _G._WELCOME_UI.ConditionalBeginDestroy then _G._WELCOME_UI:ConditionalBeginDestroy() end
                        end
                    end)
                    _G._WELCOME_UI = nil
                end)
            end
        end)
    end)
end

-- ============================================================================
-- BUILD LOGIN UI
-- ============================================================================
function LICENSE_UI.Build(character, errorText, onSuccess)
    lic_cleanupUI()

    local ok = false
    pcall(function()
        local canvas = lic_getMainCanvas()
        if not canvas then return end

        local vw, vh = 1920, 1080
        pcall(function()
            local uiUtil = require("client.common.ui_util")
            if uiUtil and uiUtil.GetViewportSize then
                local s = uiUtil.GetViewportSize()
                if s and s.X and s.X > 0 then vw, vh = s.X, s.Y end
            end
        end)

        local cx = vw * 0.5
        local cy = vh * 0.5
        local panelW = math.min(vw * 0.28, 550)
        if panelW < 420 then panelW = 420 end
        local panelH = panelW * 0.7027027027027027
        local scale = panelW / 740

        local root = CGame:NewObjectFromPath("/Script/UMG.CanvasPanel", canvas)
        if not (root and slua.isValid(root)) then return end
        local rootSlot = canvas:AddChildToCanvas(root)
        if rootSlot then
            pcall(function()
                rootSlot:SetPosition(LicenseVector2D(0, 0))
                rootSlot:SetSize(LicenseVector2D(vw, vh))
                rootSlot:SetZOrder(9989)
            end)
        end

        local BLUE_MAIN  = LicenseLinearColor(0.2, 0.6, 1.0, 1.0)
        local BLUE_LIGHT = LicenseLinearColor(0.4, 0.8, 1.0, 1.0)
        local BLUE_PANEL = LicenseLinearColor(0.03, 0.06, 0.15, 0.96)
        local BLUE_INNER = LicenseLinearColor(0.01, 0.03, 0.08, 0.98)

        local dim = lic_makeBorder(root, LicenseLinearColor(0, 0, 0, 0.65), cx, cy, vw + 300, vh + 300, 9990)
        lic_makeBorder(root, BLUE_PANEL, cx, cy, panelW, panelH, 9991)
        lic_makeBorder(root, BLUE_INNER, cx, cy, panelW - 10, panelH - 10, 9992)
        lic_makeBorder(root, BLUE_MAIN, cx, cy - panelH * 0.5 + 3, panelW, 4, 9993)
        lic_makeBorder(root, BLUE_MAIN, cx, cy + panelH * 0.5 - 3, panelW, 4, 9993)
        lic_makeBorder(root, BLUE_MAIN, cx - panelW * 0.5 + 2, cy, 4, panelH, 9993)
        lic_makeBorder(root, BLUE_MAIN, cx + panelW * 0.5 - 2, cy, 4, panelH, 9993)

        lic_makeText(root, LICENSE_CONFIG.BRAND_NAME, math.floor(46 * scale), BLUE_MAIN, cx, cy - panelH * 0.356)
        lic_makeText(root, LICENSE_CONFIG.BRAND_SUB, math.floor(15 * scale), LicenseLinearColor(0.6, 0.75, 0.9, 1.0), cx, cy - panelH * 0.275)

        local box = lic_makeInput(root, cx, cy - panelH * 0.119, panelW * 0.865, 54 * scale)
        _G._LICENSE_BOX = box

        local statusText = errorText or "Type key, then press LOGIN"
        local statusCol = errorText and LicenseLinearColor(1.0, 0.3, 0.3, 1.0) or BLUE_LIGHT
        _G._LICENSE_STATUS_WIDGET = lic_makeText(root, statusText, math.floor(19 * scale), statusCol, cx, cy - panelH * 0.015)

        local btnW = panelW * 0.36
        local btnH = 60 * scale
        local gap = panelW * 0.05
        local totalBtnW = (btnW * 2) + gap
        local startX = cx - (totalBtnW / 2) + (btnW / 2)

        _G._LICENSE_GETKEY = lic_makeButton(root, startX, cy + panelH * 0.1, btnW, btnH,
            "GET KEY", 1.0, 0.75, 0.2, function()
                lic_setStatus("Opening Telegram...", false)
                lic_openTelegram()
            end)

        _G._LICENSE_BTN = lic_makeButton(root, startX + btnW + gap, cy + panelH * 0.1, btnW, btnH,
            "LOGIN", 0.2, 0.9, 0.4, function()
                local key = lic_getBoxText(_G._LICENSE_BOX)
                if not key or #key < 4 then
                    lic_setStatus("Pehle key likho", true)
                    return
                end
                if _G._LOGIN_TRYING then return end
                _G._LOGIN_TRYING = true
                lic_setStatus("Checking...", false)

                local serial = lic_getSerial()
                lic_checkLicense(key, serial, function(success, reason, expiry)
                    _G._LOGIN_TRYING = false
                    if success then
                        lic_saveKeyToFile(key)
                        _G._LICENSE_OK = true
                        _G._LICENSE_UID = serial
                        _G._MOD_EXPIRED = false
                        lic_setStatus("Activated! All Features ON", false)

                        -- Cleanup login UI
                        lic_cleanupUI()

                        -- Show welcome popup
                        ShowWelcomePopup()

                        -- START MOD FEATURES NOW
                        pcall(function()
                            if _G.StartBypass_VIP_v3 then _G.StartBypass_VIP_v3() end
                        end)
                        pcall(function()
                            if _G.InitializeAutoHeadHooks then _G.InitializeAutoHeadHooks() end
                        end)
                        pcall(function()
                            if _G.InitModMenuTab then _G.InitModMenuTab() end
                        end)

                        -- Periodic server check (every 3 min)
                        if character and character.AddGameTimer then
                            pcall(function()
                                _G._PERIODIC_TIMER = character:AddGameTimer(180, true, function()
                                    if not slua.isValid(character.Object) then return end
                                    if not _G._LICENSE_OK then return end
                                    local curKey = lic_getCurrentKey()
                                    local curSer = _G._LICENSE_UID or lic_getSerial()
                                    if not curKey or not curSer then return end
                                    lic_checkLicense(curKey, curSer, function(ok2, reason2)
                                        if not ok2 and reason2 ~= "nonet" then
                                            _G._LICENSE_OK = false
                                            _G._MOD_EXPIRED = true
                                            if reason2 == "expired" then
                                                lic_showMsgBox("LICENSE EXPIRED", "Aapki key expire ho gayi hai.")
                                            elseif reason2 == "blocked" then
                                                lic_showMsgBox("LICENSE BLOCKED", "Aapki key admin ne block kar di hai.")
                                            elseif reason2 == "device_limit" then
                                                lic_showMsgBox("DEVICE LIMIT", "Aapki key dusre device par use ho rahi hai.")
                                            else
                                                lic_showMsgBox("LICENSE REVOKED", "License valid nahi hai.")
                                            end
                                        end
                                    end)
                                end)
                            end)
                            pcall(function()
                                _G._HEARTBEAT_TIMER = character:AddGameTimer(5, true, function()
                                    if not slua.isValid(character.Object) then return end
                                    if not _G._LICENSE_OK then return end
                                    local curKey = lic_getCurrentKey()
                                    local curSer = _G._LICENSE_UID or lic_getSerial()
                                    lic_sendHeartbeat(curKey, curSer)
                                end)
                            end)
                        end

                        if onSuccess then onSuccess() end
                    else
                        if reason == "invalid" then lic_setStatus("Galat key - dobara likho", true)
                        elseif reason == "blocked" then lic_setStatus("Key blocked hai", true)
                        elseif reason == "expired" then lic_setStatus("Key expire ho gayi", true)
                        elseif reason == "device_limit" then lic_setStatus("Dusre device par lock hai", true)
                        else lic_setStatus("Net error - fir se try karo", true) end
                    end
                end)
            end)

        lic_makeText(root, LICENSE_CONFIG.SUPPORT_TEXT, math.floor(14 * scale), BLUE_LIGHT, cx, cy + panelH * 0.323)

        _G._LICENSE_UI = root
        _G._LICENSE_DIM = dim
        ok = true
    end)

    return ok
end

function LICENSE_UI.Start(character, onSuccess)
    if _G._LICENSE_OK then
        if onSuccess then onSuccess() end
        return
    end

    local function openLoginDirectly()
        if _G._LICENSE_OK then return end
        local built = LICENSE_UI.Build(character, nil, onSuccess)
        if not built then
            if character and character.AddGameTimer then
                _G._LICENSE_CHAR = character
                _G._LICENSE_TIMER = character:AddGameTimer(1.0, false, openLoginDirectly)
            end
        end
    end

    openLoginDirectly()
end

_G.LicenseSystem = {
    Start = LICENSE_UI.Start,
    Build = LICENSE_UI.Build,
    CheckLicense = lic_checkLicense,
    GetSerial = lic_getSerial,
    GetCurrentKey = lic_getCurrentKey,
    SaveKey = lic_saveKeyToFile,
    Config = LICENSE_CONFIG,
    ShowWelcome = ShowWelcomePopup,
}

print("[HUSSNAINxPUBG] LicenseSystem Ready")

-- ============================================================================
-- END PART 7
-- ============================================================================
-- [CONTINUE PASTE FROM PART 7]

-- ============================================================================
-- SAFE MARK HELPERS
-- ============================================================================
local function SafeAddMark(id, pos, z, str, size, actor)
    local mark = nil
    pcall(function()
        local InGameMarkTools = require("GameLua.Mod.BaseMod.Common.InGameMarkTools")
        if InGameMarkTools and InGameMarkTools.ClientAddMapMark then
            mark = InGameMarkTools.ClientAddMapMark(id, pos, z, str, size, actor)
            if mark then _G.LexusState.TrackedMarks[mark] = true end
        end
    end)
    return mark
end

local function SafeRemoveMark(mark)
    if not mark then return end
    pcall(function()
        local InGameMarkTools = require("GameLua.Mod.BaseMod.Common.InGameMarkTools")
        if InGameMarkTools and InGameMarkTools.HideMapMark then InGameMarkTools.HideMapMark(mark) end
        if InGameMarkTools and InGameMarkTools.RemoveMapMark then InGameMarkTools.RemoveMapMark(mark) end
    end)
    _G.LexusState.TrackedMarks[mark] = nil
end

local function GetSafeEnemyKey(enemy)
    if Valid(enemy) then
        if enemy.PlayerKey then return tostring(enemy.PlayerKey) end
        if type(enemy.GetUniqueID) == "function" then return tostring(enemy:GetUniqueID()) end
    end
    return tostring(enemy)
end

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

-- ============================================================================
-- AUTO HEAD HOOK
-- ============================================================================
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
                    if _G.LexusConfig.AutoHead then return EAvatarDamagePosition.BigHead end
                    if original_GetHitBodyType then return original_GetHitBodyType(self, ImpactResult, InImpactVec) end
                end
                local original_GetHitBodyTypeByHitPos = hitLogic.GetHitBodyTypeByHitPos
                hitLogic.GetHitBodyTypeByHitPos = function(self, InImpactVec)
                    if _G.LexusConfig.AutoHead then return EAvatarDamagePosition.BigHead end
                    if original_GetHitBodyTypeByHitPos then return original_GetHitBodyTypeByHitPos(self, InImpactVec) end
                end
            end
        end
    end)
end

-- ============================================================================
-- LOST TOMB FUNCTIONS
-- ============================================================================
_G.LostTomb_IgnoreFallingDamageMarkMap = {}

function _G.LostTomb_MarkIgnoreFallingDamage(Reason, bRemove, Duration)
    if not _G.LexusConfig.IgnoreFallingDamage then return end
    local localPlayer = GameplayData.GetPlayerCharacter()
    if not Valid(localPlayer) then return end
    if bRemove then
        _G.LostTomb_IgnoreFallingDamageMarkMap[Reason] = nil
    else
        local CurTime = os.time()
        _G.LostTomb_IgnoreFallingDamageMarkMap[Reason] = CurTime + Duration
    end
    local CurTime = os.time()
    for k, v in pairs(_G.LostTomb_IgnoreFallingDamageMarkMap) do
        if CurTime > v then _G.LostTomb_IgnoreFallingDamageMarkMap[k] = nil end
    end
    pcall(function()
        if type(localPlayer.CheckIgnoreFallingDamage) == "function" then
            local bIgnore = false
            for _, v in pairs(_G.LostTomb_IgnoreFallingDamageMarkMap) do
                if v >= CurTime then bIgnore = true break end
            end
            if bIgnore then
                localPlayer:SetAttrValue("LandDamageReduce", 1, -1)
            else
                localPlayer:SetAttrValue("LandDamageReduce", 0, -1)
            end
        end
    end)
end

function _G.LostTomb_ShowHeadHPBar()
    if not _G.LexusConfig.ShowHeadHPBar then return end
    local localPlayer = GameplayData.GetPlayerCharacter()
    if not Valid(localPlayer) then return end
    if Valid(localPlayer.HeadHPBar) and type(localPlayer.HeadHPBar.CreateSceneMark) == "function" then
        localPlayer.HeadHPBar:CreateSceneMark()
    end
end

function _G.LostTomb_GetCustomGender()
    if not _G.LexusConfig.EnableCustomGender then return end
    local localPlayer = GameplayData.GetPlayerCharacter()
    if not Valid(localPlayer) then return end
    if type(localPlayer.GetCustomGender) == "function" then return localPlayer:GetCustomGender() end
    return 0
end

function _G.LostTomb_SetCloseCharacterOverrideAvatar(bClose)
    if not _G.LexusConfig.EnableLoadingAvatar then return end
    local localPlayer = GameplayData.GetPlayerCharacter()
    if not Valid(localPlayer) then return end
    if type(localPlayer.SetCloseCharacterOverrideAvatar) == "function" then
        localPlayer:SetCloseCharacterOverrideAvatar(bClose)
        _G.LexusState.IsCloseCharacterOverrideAvatar = bClose
    end
end

function _G.LostTomb_ShowSupplyBoxEvolution(EvolutionShowParam)
    if not _G.LexusConfig.EnableSupplyBoxEvolution then return end
    local localPlayer = GameplayData.GetPlayerCharacter()
    if not Valid(localPlayer) then return end
    if type(localPlayer.SetSupplyBoxEvolutionShow) == "function" then
        localPlayer:SetSupplyBoxEvolutionShow(EvolutionShowParam)
    end
end

function _G.LostTomb_AddMaxWalkSpeedCurve(Curve)
    if not _G.LexusConfig.EnableMaxWalkSpeedCurve then return end
    local localPlayer = GameplayData.GetPlayerCharacter()
    if not Valid(localPlayer) then return end
    if type(localPlayer.AddMaxWalkSpeedCurve) == "function" then
        localPlayer:AddMaxWalkSpeedCurve(Curve)
    end
end

function _G.LostTomb_RemoveMaxWalkSpeedCurve(Curve)
    if not _G.LexusConfig.EnableMaxWalkSpeedCurve then return end
    local localPlayer = GameplayData.GetPlayerCharacter()
    if not Valid(localPlayer) then return end
    if type(localPlayer.RemoveMaxWalkSpeedCurve) == "function" then
        localPlayer:RemoveMaxWalkSpeedCurve(Curve)
    end
end

function _G.LostTomb_UpdateStealLifeCount(count)
    if not _G.LexusConfig.EnableStealLifeEffect then return end
    _G.LexusState.StealLifeCount = (_G.LexusState.StealLifeCount or 0) + count
    local localPlayer = GameplayData.GetPlayerCharacter()
    if Valid(localPlayer) then
        if localPlayer.StealLifeCount ~= nil then
            localPlayer.StealLifeCount = _G.LexusState.StealLifeCount
            if type(localPlayer.OnRep_StealLifeCount) == "function" then
                localPlayer:OnRep_StealLifeCount()
            end
        end
    end
end

-- ============================================================================
-- END PART 8
-- ============================================================================
-- [CONTINUE PASTE FROM PART 9]
-- [CONTINUE PASTE FROM PART 8]

-- ============================================================================
-- FAKE TEXT MAP
-- ============================================================================
local FakeTextMap = {
    [999000] = "HUSSNAIN MOD MENU @HUSSNAINxPUBG",
    [999001] = "CUSTOM ESP MENU",
    [999002] = "CUSTOM AIMBOT MENU",
    [999003] = "EXTRA FEATURES",
    [999100] = "ESP SKELETON BOX",
    [999101] = "ESP ENEMY DISTANCE",
    [999102] = "ESP HEALTH BAR",
    [999103] = "ESP HIT MARK",
    [999104] = "ESP BOX",
    [999105] = "ESP SKELETON ONLY",
    [999106] = "ESP REAL ENEMY/BOT",
    [999107] = "ESP GREEN ANTENNA",
    [999108] = "ESP ENEMY (RED AURA)",
    [999109] = "COLOR SIZE",
    [999200] = "LONG RANGE AIMBOT",
    [999201] = "AIMBOT SPEED",
    [999202] = "AIMBOT RECOIL ADS",
    [999203] = "CLOSE RANGE AIMBOT",
    [999204] = "AIMBOT CLOSE SPEED",
    [999214] = "SMALL CROSSHERE",
    [999215] = "FAST WEAPON CHANGE",
    [999216] = "X EFFECT",
    [999217] = "AUTO AIMBOT HEAD",
    [999219] = "AIM TOUCH ENABLE",
    [999220] = "HIPFIRE ENABLE",
    [999221] = "SHOTGUN ENABLE",
    [999222] = "SCOPE ALL ENABLE",
    [999223] = "SNIPER ENABLE",
    [999300] = "CUSTOM IPAD VIEW",
    [999301] = "IPAD FOV",
    [999302] = "165 REAL FPS",
    [999303] = "WALLHACK REAL",
    [999304] = "WHITE BODY",
    [999305] = "BLACK SKY",
    [999306] = "REMOVE FOG",
    [999307] = "REMOVE GRASS",
    [999308] = "WALL CLIMB",
    [999309] = "FAST CAR SPEED",
}

local function HookLocUtil()
    local LocUtil = _G.LocUtil
    if not LocUtil and package.loaded["client.common.LocUtil"] then
        LocUtil = require("client.common.LocUtil")
    end
    if LocUtil and not LocUtil._IsModMenuHooked then
        local old = LocUtil.GetLocalizeResStr
        LocUtil.GetLocalizeResStr = function(id)
            if type(id) == "string" and not tonumber(id) then return id end
            if FakeTextMap[id] then return FakeTextMap[id] end
            return old(id)
        end
        LocUtil._IsModMenuHooked = true
    end
end

-- ============================================================================
-- CONFIG SAVE/LOAD
-- ============================================================================
local ConfigFileName = "rpad_settings.txt"
_G.LastConfigSaveStr = ""

local function GetConfigPaths(fileName)
    local paths = {
        "//storage/emulated/0/Android/data/com.tencent.ig/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. fileName,
        "//storage/emulated/0/Android/data/com.vng.pubgmobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. fileName,
        "//storage/emulated/0/Android/data/com.pubg.krmobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. fileName,
        "//storage/emulated/0/Android/data/com.rekoo.pubgm/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. fileName,
        "//storage/emulated/0/Android/data/com.pubg.imobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. fileName,
        "ShadowTrackerExtra/Saved/Paks/" .. fileName,
        fileName
    }
    pcall(function()
        if os and os.getenv then
            local homeDir = os.getenv("HOME")
            if homeDir and homeDir ~= "" then
                table.insert(paths, 1, homeDir .. "/Documents/ShadowTrackerExtra/Saved/Paks/" .. fileName)
            end
        end
    end)
    return paths
end

_G.SaveModSettings = function()
    pcall(function()
        local data = "return {\nLexusConfig = {\n"
        for k, v in pairs(_G.LexusConfig or {}) do
            data = data .. "  [\"" .. tostring(k) .. "\"] = " .. tostring(v) .. ",\n"
        end
        data = data .. "},\nCustomTextData = {\n"
        if _G.LexusState and _G.LexusState.CustomTextData then
            for k, v in pairs(_G.LexusState.CustomTextData) do
                data = data .. "  [\"" .. tostring(k) .. "\"] = " .. tostring(v) .. ",\n"
            end
        end
        data = data .. "}\n}"
        if data == _G.LastConfigSaveStr then return end
        _G.LastConfigSaveStr = data
        local paths = GetConfigPaths(ConfigFileName)
        for _, path in ipairs(paths) do
            local file = io.open(path, "w")
            if file then file:write(data) file:close() break end
        end
    end)
end

_G.LoadModSettings = function()
    pcall(function()
        local paths = GetConfigPaths(ConfigFileName)
        local content = nil
        for _, path in ipairs(paths) do
            local file = io.open(path, "r")
            if file then content = file:read("*a") file:close() break end
        end
        if content then
            local func = load(content)
            if func then
                local savedData = func()
                if savedData and type(savedData) == "table" then
                    if savedData.LexusConfig then
                        for k, v in pairs(savedData.LexusConfig) do _G.LexusConfig[k] = v end
                    end
                    if savedData.CustomTextData then
                        _G.LexusState.CustomTextData = _G.LexusState.CustomTextData or {}
                        for k, v in pairs(savedData.CustomTextData) do _G.LexusState.CustomTextData[k] = v end
                    end
                end
            end
        end
    end)
end

local function AutoSaveLoop()
    pcall(function() if _G.SaveModSettings then _G.SaveModSettings() end end)
    pcall(function()
        local okTicker, ticker = pcall(require, "common.time_ticker")
        if okTicker and ticker and ticker.AddTimerOnce then
            ticker.AddTimerOnce(3.0, AutoSaveLoop)
        end
    end)
end

if not _G.ModConfigLoaded then
    _G.LoadModSettings()
    AutoSaveLoop()
    _G.ModConfigLoaded = true
end

-- ============================================================================
-- MENU REGISTER (guarded by license)
-- ============================================================================
_G.InitModMenuTab = function()
    if not _G._LICENSE_OK then return end
    HookLocUtil()

    local SettingPageDefine = require("client.logic.NewSetting.SettingPageDefine")
    local SettingCatalog = require("client.logic.NewSetting.SettingCatalog")
    local AliasMap = require("client.slua.umg.NewSetting.Item.AliasMap")

    local StackESP = {
        { UI = AliasMap.Title, Text = 999001 },
        { Key = "ModMenu_ESP1", UI = AliasMap.Switcher, Text = 999100,
          GetFunc = function() return _G.LexusConfig.EspVip end,
          SetFunc = function(_, v) _G.LexusConfig.EspVip = v; return true end },
        { Key = "ModMenu_ESP2", UI = AliasMap.Switcher, Text = 999101,
          GetFunc = function() return _G.LexusConfig.EspDistance end,
          SetFunc = function(_, v) _G.LexusConfig.EspDistance = v; return true end },
        { Key = "ModMenu_ESP3", UI = AliasMap.Switcher, Text = 999102,
          GetFunc = function() return _G.LexusConfig.EspVipPro end,
          SetFunc = function(_, v) _G.LexusConfig.EspVipPro = v; return true end },
        { Key = "ModMenu_ESP4", UI = AliasMap.Switcher, Text = 999103,
          GetFunc = function() return _G.LexusConfig.EspRadar end,
          SetFunc = function(_, v) _G.LexusConfig.EspRadar = v; return true end },
        { Key = "ModMenu_ESP5", UI = AliasMap.Switcher, Text = 999104,
          GetFunc = function() return _G.LexusConfig.EspLoai5 end,
          SetFunc = function(_, v) _G.LexusConfig.EspLoai5 = v; return true end },
        { Key = "ModMenu_ESP6", UI = AliasMap.Switcher, Text = 999105,
          GetFunc = function() return _G.LexusConfig.EspLoai6 end,
          SetFunc = function(_, v) _G.LexusConfig.EspLoai6 = v; return true end },
        { Key = "ModMenu_ESP7", UI = AliasMap.Switcher, Text = 999106,
          GetFunc = function() return _G.LexusConfig.EspLoai7 end,
          SetFunc = function(_, v) _G.LexusConfig.EspLoai7 = v; return true end },
        { Key = "ModMenu_ESPAntenna", UI = AliasMap.Switcher, Text = 999107,
          GetFunc = function() return _G.LexusConfig.EspAntenna end,
          SetFunc = function(_, v) _G.LexusConfig.EspAntenna = v; return true end },
        { Key = "ModMenu_ESPOutline_Ex", UI = AliasMap.TitleSwitcher, Text = 999108, ExpandIndex = 0,
          GetFunc = function() return _G.LexusConfig.EspOutline end,
          SetFunc = function(_, v) _G.LexusConfig.EspOutline = v; return true end },
        { Key = "ModMenu_ESPOutline_Thickness", UI = AliasMap.Slider, Text = 999109,
          ExpandHandle = "ModMenu_ESPOutline_Ex", MinValue = 1, MaxValue = 20, min = 1, max = 20,
          GetFunc = function() return _G.LexusConfig.OutlineThickness or 10 end,
          SetFunc = function(_, v) _G.LexusConfig.OutlineThickness = v; return true end },
    }

    local StackAimbot = {
        { UI = AliasMap.Title, Text = 999002 },
        { Key = "ModMenu_Aimbot_Ex", UI = AliasMap.TitleSwitcher, Text = 999200, ExpandIndex = 0,
          GetFunc = function() return _G.LexusConfig.CustomAimbot end,
          SetFunc = function(_, v) _G.LexusConfig.CustomAimbot = v; return true end },
        { Key = "ModMenu_Aimbot_Speed", UI = AliasMap.Slider, Text = 999201,
          ExpandHandle = "ModMenu_Aimbot_Ex", MinValue = 1, MaxValue = 100, min = 1, max = 100,
          GetFunc = function() return _G.LexusState.CustomTextData and _G.LexusState.CustomTextData.OuterSpeed or 10 end,
          SetFunc = function(_, v) _G.LexusState.CustomTextData.OuterSpeed = v; return true end },
        { Key = "ModMenu_Aimbot_Recoil", UI = AliasMap.Slider, Text = 999202,
          ExpandHandle = "ModMenu_Aimbot_Ex", MinValue = 1, MaxValue = 50, min = 1, max = 50,
          GetFunc = function() return _G.LexusState.CustomTextData and _G.LexusState.CustomTextData.OuterRecoil or 0.1 end,
          SetFunc = function(_, v) _G.LexusState.CustomTextData.OuterRecoil = v; return true end },
        { Key = "ModMenu_AimbotClose_Ex", UI = AliasMap.TitleSwitcher, Text = 999203, ExpandIndex = 0,
          GetFunc = function() return _G.LexusConfig.CustomAimbotClose end,
          SetFunc = function(_, v) _G.LexusConfig.CustomAimbotClose = v; return true end },
        { Key = "ModMenu_AimbotClose_Speed", UI = AliasMap.Slider, Text = 999204,
          ExpandHandle = "ModMenu_AimbotClose_Ex", MinValue = 1, MaxValue = 100, min = 1, max = 100,
          GetFunc = function() return _G.LexusState.CustomTextData and _G.LexusState.CustomTextData.InnerSpeed or 10 end,
          SetFunc = function(_, v) _G.LexusState.CustomTextData.InnerSpeed = v; return true end },
        { Key = "ModMenu_Crosshair", UI = AliasMap.Switcher, Text = 999214,
          GetFunc = function() return _G.LexusConfig.Crosshair end,
          SetFunc = function(_, v) _G.LexusConfig.Crosshair = v; return true end },
        { Key = "ModMenu_AutoHead", UI = AliasMap.Switcher, Text = 999217,
          GetFunc = function() return _G.LexusConfig.AutoHead end,
          SetFunc = function(_, v) _G.LexusConfig.AutoHead = v; return true end },
        { Key = "ModMenu_AT_Ex", UI = AliasMap.TitleSwitcher, Text = 999219, ExpandIndex = 0,
          GetFunc = function() return _G.LexusConfig.AimTouchEnable end,
          SetFunc = function(_, v) _G.LexusConfig.AimTouchEnable = v; return true end },
        { Key = "ModMenu_AT_Hip_Ex", UI = AliasMap.TitleSwitcher, Text = 999220,
          ExpandHandle = "ModMenu_AT_Ex", ExpandIndex = 0,
          GetFunc = function() return _G.LexusConfig.AimTouchHipfire end,
          SetFunc = function(_, v) _G.LexusConfig.AimTouchHipfire = v; return true end },
        { Key = "ModMenu_AT_SG_Ex", UI = AliasMap.TitleSwitcher, Text = 999221,
          ExpandHandle = "ModMenu_AT_Ex", ExpandIndex = 0,
          GetFunc = function() return _G.LexusConfig.AimTouchSG end,
          SetFunc = function(_, v) _G.LexusConfig.AimTouchSG = v; return true end },
        { Key = "ModMenu_AT_ScopeAll_Ex", UI = AliasMap.TitleSwitcher, Text = 999222,
          ExpandHandle = "ModMenu_AT_Ex", ExpandIndex = 0,
          GetFunc = function() return _G.LexusConfig.AimTouchScopeAll end,
          SetFunc = function(_, v) _G.LexusConfig.AimTouchScopeAll = v; return true end },
        { Key = "ModMenu_AT_Sniper_Ex", UI = AliasMap.TitleSwitcher, Text = 999223,
          ExpandHandle = "ModMenu_AT_Ex", ExpandIndex = 0,
          GetFunc = function() return _G.LexusConfig.AimTouchScopeSniper end,
          SetFunc = function(_, v) _G.LexusConfig.AimTouchScopeSniper = v; return true end },
    }

    local StackCombat = {
        { UI = AliasMap.Title, Text = 999003 },
        { Key = "ModMenu_Ipad_Ex", UI = AliasMap.TitleSwitcher, Text = 999300, ExpandIndex = 0,
          GetFunc = function() return _G.LexusConfig.IpadView end,
          SetFunc = function(_, v) _G.LexusConfig.IpadView = v; return true end },
        { Key = "ModMenu_Ipad_FOV", UI = AliasMap.Slider, Text = 999301,
          ExpandHandle = "ModMenu_Ipad_Ex", MinValue = 1, MaxValue = 100, min = 1, max = 100,
          GetFunc = function() return (_G.LexusState.CustomTextData and _G.LexusState.CustomTextData.IpadViewFOV or 120) - 90 end,
          SetFunc = function(_, v) _G.LexusState.CustomTextData.IpadViewFOV = 90 + v; return true end },
        { Key = "ModMenu_165FPS", UI = AliasMap.Switcher, Text = 999302,
          GetFunc = function() return _G.LexusConfig.UnlockFPS end,
          SetFunc = function(_, v) _G.LexusConfig.UnlockFPS = v; return true end },
        { Key = "ModMenu_WallColor", UI = AliasMap.Switcher, Text = 999303,
          GetFunc = function() return _G.LexusConfig.WallXuyenTuong end,
          SetFunc = function(_, v) _G.LexusConfig.WallXuyenTuong = v; _G.LexusConfig.ColorBodyV2 = v; return true end },
        { Key = "ModMenu_WhiteBody", UI = AliasMap.Switcher, Text = 999304,
          GetFunc = function() return _G.LexusConfig.WhiteBody end,
          SetFunc = function(_, v) _G.LexusConfig.WhiteBody = v; return true end },
        { Key = "ModMenu_BlackSky", UI = AliasMap.Switcher, Text = 999305,
          GetFunc = function() return _G.LexusConfig.BlackSky end,
          SetFunc = function(_, v) _G.LexusConfig.BlackSky = v; return true end },
        { Key = "ModMenu_RemoveFog", UI = AliasMap.Switcher, Text = 999306,
          GetFunc = function() return _G.LexusConfig.RemoveFog end,
          SetFunc = function(_, v) _G.LexusConfig.RemoveFog = v; return true end },
        { Key = "ModMenu_RemoveGrass", UI = AliasMap.Switcher, Text = 999307,
          GetFunc = function() return _G.LexusConfig.RemoveGrass end,
          SetFunc = function(_, v) _G.LexusConfig.RemoveGrass = v; return true end },
    }

    if not SettingPageDefine.MyModMenu then
        SettingPageDefine.MyModMenu = {
            Key = "MyModMenu", Text = 999000,
            UIKey = "Setting_Page_Privacy",
            Category = {
                { Key = "Cat_ESP", Text = 999001, Stack = StackESP },
                { Key = "Cat_Aimbot", Text = 999002, Stack = StackAimbot },
                { Key = "Cat_Combat", Text = 999003, Stack = StackCombat },
            }
        }
        table.insert(SettingCatalog, SettingPageDefine.MyModMenu)
    end

    local UIManager = _G.UIManager
    if UIManager and not UIManager._IsModMenuHooked then
        local old = UIManager.ShowUI
        UIManager.ShowUI = function(config, ...)
            local args = {...}
            local n = select('#', ...)
            if config and config.keyName and string.find(string.lower(config.keyName), "setting_main") then
                local catalog = args[1]
                if type(catalog) == "table" then
                    local has = false
                    for _, page in ipairs(catalog) do
                        if type(page) == "table" and page.Key == "MyModMenu" then
                            has = true; break
                        end
                    end
                    if not has and SettingPageDefine.MyModMenu then
                        table.insert(catalog, 1, SettingPageDefine.MyModMenu)
                    end
                end
            end
            local table_unpack = table.unpack or unpack
            return old(config, table_unpack(args, 1, n))
        end
        UIManager._IsModMenuHooked = true
    end
end

-- ============================================================================
-- END PART 9
-- ============================================================================
-- [CONTINUE PASTE FROM PART 9]

-- ============================================================================
-- NATIVE ESP INIT
-- ============================================================================
local function InitializeNativeESP()
    if _G.LexusState.NativeESPReady then return end
    pcall(function()
        local GamePlayTools2 = require("GameLua.Mod.BaseMod.Common.GamePlayTools")
        local currentMarkCfg = GamePlayTools2.GetCurrentConfig("ScreenMarkConfig")
        local function ApplyCfg(cfg)
            if not cfg then return end
            if cfg[1006] then
                cfg[1006].bBindBlocked = true; cfg[1006].bBindOutScreen = true
                cfg[1006].MaxWidgetNum = 99; cfg[1006].MaxShowDistance = 6000000
                cfg[1006].bScaleByDistance = false; cfg[1006].BindSocketName = "root"
                cfg[1006].bUseLuaWorldSocketName = true
                cfg[1006].WorldPositionOffset = FVector(0, 0, -30)
            end
            if cfg[1003] then
                cfg[1003].bBindBlocked = true; cfg[1003].bBindOutScreen = true
                cfg[1003].MaxWidgetNum = 99; cfg[1003].MaxShowDistance = 6000000
                cfg[1003].bScaleByDistance = false; cfg[1003].BindSocketName = "head"
                cfg[1003].bUseLuaWorldSocketName = true
            end
            cfg[9999] = {
                UIPathName = "/Game/Mod/EvoBase/BluePrints/UIBP/QuickSign/QuickSign_TipHitEnemy_UIBP_New.QuickSign_TipHitEnemy_UIBP_New_C",
                MaxWidgetNum = 99, MaxShowDistance = 6000000,
                bBindOutScreen = true, bBindBlocked = true, bIsBindingActor = true,
                BindSocketName = "head", bUseLuaWorldSocketName = true,
                WorldPositionOffset = FVector(0, 0, 50), bNeedPreLoad = true, Priority = 2
            }
        end
        ApplyCfg(currentMarkCfg)
        for k, cfg in pairs(package.loaded) do
            if type(k) == "string" and string.find(k, "ScreenMarkConfig") and type(cfg) == "table" then
                ApplyCfg(cfg)
            end
        end
    end)
    _G.LexusState.NativeESPReady = true
end

-- ============================================================================
-- CORE MESH FUNCTIONS
-- ============================================================================
local function GetAllSkeletalMeshes(enemy, markData)
    local curTime = os.clock()
    if markData and markData.CachedMeshes and markData.CachedMeshTime and (curTime - markData.CachedMeshTime < 3.0) then
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
                    if Valid(comp) and comp ~= enemy.Mesh then table.insert(meshes, comp) end
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

local function UndoWallXuyenTuong(enemy, markData)
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

local function ApplyWallXuyenTuong(enemy, markData)
    pcall(function()
        local meshes = GetAllSkeletalMeshes(enemy, markData)
        for _, mesh in ipairs(meshes) do
            if Valid(mesh) then
                pcall(function()
                    if type(mesh.SetRenderCustomDepth) == "function" then mesh:SetRenderCustomDepth(true) end
                    if type(mesh.SetCustomDepthStencilValue) == "function" then mesh:SetCustomDepthStencilValue(252) end
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

local function ApplyColorBodyV2(enemy, pc, markData)
    pcall(function()
        local meshes = GetAllSkeletalMeshes(enemy, markData)
        if #meshes == 0 then return end
        local hidden = true
        pcall(function()
            if Valid(pc) and type(pc.LineOfSightTo) == "function" then
                if pc:LineOfSightTo(enemy) then hidden = false else hidden = true end
            end
        end)
        local cData = _G.LexusState.CustomTextData or {}
        local hiddenColor = {R = cData.HiddenR or 150, G = cData.HiddenG or 0, B = cData.HiddenB or 0, A = cData.HiddenA or 25}
        local visibleColor = {R = cData.VisibleR or 0, G = cData.VisibleG or 150, B = cData.VisibleB or 0, A = cData.VisibleA or 25}
        local finalColor = hidden and hiddenColor or visibleColor
        local colorHash = string.format("%d_%d_%d_%d", finalColor.R, finalColor.G, finalColor.B, finalColor.A)
        local currentMeshCount = #meshes
        local isMeshChanged = (markData.LastMeshCount ~= currentMeshCount)
        if not isMeshChanged and markData.LastHiddenState == hidden and markData.LastColorHash == colorHash then return end
        markData.LastHiddenState = hidden
        markData.LastMeshCount = currentMeshCount
        markData.LastColorHash = colorHash
        markData.ColorApplied = true
        for _, mesh in ipairs(meshes) do
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
                            local meshStr = tostring(mesh)
                            if not markData.MIDs[meshStr] then markData.MIDs[meshStr] = {} end
                            local mid = markData.MIDs[meshStr][i]
                            if not Valid(mid) then
                                mid = mesh:CreateAndSetMaterialInstanceDynamic(i)
                                markData.MIDs[meshStr][i] = mid
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
            for _, mesh in ipairs(meshes) do
                if Valid(mesh) then
                    pcall(function()
                        mesh.PrimitiveShadingStrategy = 0
                        mesh.ShadingRate = 1
                    end)
                    if markData.MIDs and markData.MIDs[tostring(mesh)] then
                        for i, mid in pairs(markData.MIDs[tostring(mesh)]) do
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
        end
    end)
end

-- ============================================================================
-- AIMBOT V2
-- ============================================================================
_G.GetEnemyTargetsFromActors = function(radius)
    local result = {}
    local player = GameplayData.GetPlayerCharacter()
    if not slua.isValid(player) then return result end
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
                if dist <= radius then table.insert(result, actor) end
            end
        end
    end
    return result
end

_G.AimTouch = function()
    pcall(function()
        if not _G.LexusConfig.AimTouchEnable then return end
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
        if slua.isValid(weapon) then
            local wID = type(weapon.GetWeaponID) == "function" and weapon:GetWeaponID() or 0
            local wName = type(weapon.GetWeaponName) == "function" and weapon:GetWeaponName() or ""
            if (wID >= 1030000 and wID < 1040000) or wName:find("S686") or wName:find("S1897") or wName:find("S12") or wName:find("DBS") or wName:find("M1014") then
                isShotgun = true
            end
            if wName:find("Kar98") or wName:find("M24") or wName:find("AWM") or wName:find("Mosin") or wName:find("Win94") or wName:find("AMR") or wName:find("SKS") or wName:find("SLR") or wName:find("Mini") or wName:find("Mk14") or wName:find("QBU") or wName:find("Mk12") or wName:find("VSS") then
                isSniper = true
            end
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
        if isShotgun and _G.LexusConfig.AimTouchSG then
            cond = _G.LexusState.CustomTextData.AimTouchSGCond or 1
            if _G.LexusConfig.AimTouchSGAutoFire then cond = 2 end
            if cond == 1 and not isFiring then return end
            prioMode = _G.LexusState.CustomTextData.AimTouchSGPrio or 1
            boneIdx = _G.LexusState.CustomTextData.AimTouchSGBone or 2
            speedVal = _G.LexusState.CustomTextData.AimTouchSGSpeed or 80
            fovVal = _G.LexusState.CustomTextData.AimTouchSGFOV or 40
            maxDistMeters = _G.LexusState.CustomTextData.AimTouchSGDist or 30
            useVisCheck = _G.LexusConfig.AimTouchSGVisCheck
            igKnock = _G.LexusConfig.AimTouchSGIgKnock
            igBot = _G.LexusConfig.AimTouchSGIgBot
        elseif isADS then
            if isSniper and _G.LexusConfig.AimTouchScopeSniper then
                cond = _G.LexusState.CustomTextData.AimTouchSniperCond or 2
                if cond == 1 and not isFiring then return end
                prioMode = _G.LexusState.CustomTextData.AimTouchSniperPrio or 1
                boneIdx = _G.LexusState.CustomTextData.AimTouchSniperBone or 1
                speedVal = _G.LexusState.CustomTextData.AimTouchSniperSpeed or 30
                fovVal = _G.LexusState.CustomTextData.AimTouchSniperFOV or 20
                maxDistMeters = _G.LexusState.CustomTextData.AimTouchSniperDist or 400
                useVisCheck = _G.LexusConfig.AimTouchSniperVisCheck
                igKnock = _G.LexusConfig.AimTouchSniperIgKnock
                igBot = _G.LexusConfig.AimTouchSniperIgBot
            elseif _G.LexusConfig.AimTouchScopeAll then
                cond = _G.LexusState.CustomTextData.AimTouchScopeCond or 1
                if cond == 1 and not isFiring then return end
                prioMode = _G.LexusState.CustomTextData.AimTouchScopePrio or 1
                boneIdx = _G.LexusState.CustomTextData.AimTouchScopeBone or 2
                speedVal = _G.LexusState.CustomTextData.AimTouchScopeSpeed or 40
                fovVal = _G.LexusState.CustomTextData.AimTouchScopeFOV or 20
                maxDistMeters = _G.LexusState.CustomTextData.AimTouchScopeDist or 300
                useVisCheck = _G.LexusConfig.AimTouchScopeVisCheck
                igKnock = _G.LexusConfig.AimTouchScopeIgKnock
                igBot = _G.LexusConfig.AimTouchScopeIgBot
            else
                return
            end
        else
            if not _G.LexusConfig.AimTouchHipfire then return end
            cond = _G.LexusState.CustomTextData.AimTouchHipCond or 1
            if cond == 1 and not isFiring then return end
            prioMode = _G.LexusState.CustomTextData.AimTouchHipPrio or 1
            boneIdx = _G.LexusState.CustomTextData.AimTouchHipBone or 1
            speedVal = _G.LexusState.CustomTextData.AimTouchHipSpeed or 50
            fovVal = _G.LexusState.CustomTextData.AimTouchHipFOV or 30
            maxDistMeters = _G.LexusState.CustomTextData.AimTouchHipDist or 250
            useVisCheck = _G.LexusConfig.AimTouchHipVisCheck
            igKnock = _G.LexusConfig.AimTouchHipIgKnock
            igBot = _G.LexusConfig.AimTouchHipIgBot
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
                if slua.isValid(target.Mesh) then target.Mesh.MeshComponentUpdateFlag = 0 end
            end)
            if igKnock and target.HealthStatus == 1 then goto continue end
            if igBot then
                local tIsBot = false
                if target.bIsAI == true or target.IsAI == true then tIsBot = true end
                local pState = target.PlayerState
                if slua.isValid(pState) and (pState.bIsABot or pState.bIsBot) then tIsBot = true end
                if tIsBot then goto continue end
            end
            if useVisCheck then
                local hidden = true
                pcall(function() if pc:LineOfSightTo(target) then hidden = false end end)
                if hidden then goto continue end
            end
            local tPos = target:GetBonePos(selBoneName, {X=0, Y=0, Z=0})
            if not tPos or (tPos.X == 0 and tPos.Y == 0 and tPos.Z == 0) then
                if type(target.GetSocketLocation) == "function" then tPos = target:GetSocketLocation(selBoneName) end
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
            if type(bestTarget.GetSocketLocation) == "function" then finalBonePos = bestTarget:GetSocketLocation(selBoneName) end
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
        local rot = KismetMathLibrary.FindLookAtRotation(camLoc, finalBonePos)
        if not rot then return end
        local currentRot = pc:GetControlRotation()
        if not currentRot then return end
        local deltaYaw = rot.Yaw - currentRot.Yaw
        local deltaPitch = rot.Pitch - currentRot.Pitch
        if deltaYaw > 180 then deltaYaw = deltaYaw - 360 end
        if deltaYaw < -180 then deltaYaw = deltaYaw + 360 end
        if deltaPitch > 180 then deltaPitch = deltaPitch - 360 end
        if deltaPitch < -180 then deltaPitch = deltaPitch + 360 end
        local smoothFactor = 0.0
        if speedVal >= 100 then smoothFactor = 1.0
        else
            smoothFactor = (speedVal / 100.0) * 0.3
            if smoothFactor < 0.01 then smoothFactor = 0.01 end
        end
        local finalPitch = currentRot.Pitch + (deltaPitch * smoothFactor)
        local finalYaw = currentRot.Yaw + (deltaYaw * smoothFactor)
        local finalRot = { Pitch = finalPitch, Yaw = finalYaw, Roll = 0 }
        pc:SetControlRotation(finalRot, "AimTouch")
        if isShotgun and _G.LexusConfig.AimTouchSGAutoFire then
            pcall(function()
                local distToTarget = player:GetDistanceTo(bestTarget) / 100
                if distToTarget <= maxDistMeters then
                    player.bIsWeaponFiring = true
                    if type(player.SetIsWeaponFiring) == "function" then player:SetIsWeaponFiring(true) end
                    if slua.isValid(pc) and type(pc.SetIsWeaponFiring) == "function" then pc:SetIsWeaponFiring(true) end
                    local wepMgr = player.WeaponManagerComponent
                    if slua.isValid(wepMgr) then wepMgr.bIsWeaponFiring = true end
                    local currentWep = player:GetCurrentWeapon()
                    if slua.isValid(currentWep) and type(currentWep.StartFire) == "function" then currentWep:StartFire() end
                    _G.LexusState.IsAutoFiring = true
                end
            end)
        end
    end)
end

-- ============================================================================
-- END PART 10
-- ============================================================================
-- [CONTINUE PASTE FROM PART 10]

-- ============================================================================
-- LOST TOMB LOOP
-- ============================================================================
local function LostTombFeaturesLoop()
    pcall(function()
        local localPlayer = GameplayData.GetPlayerCharacter()
        if not Valid(localPlayer) then return end
        if _G.LexusConfig.IgnoreFallingDamage then
            _G.LostTomb_MarkIgnoreFallingDamage("ModFeature", false, 999999)
        end
        if _G.LexusConfig.ShowHeadHPBar then
            _G.LostTomb_ShowHeadHPBar()
        end
        if _G.LexusConfig.EnableCustomGender then
            local gender = _G.LostTomb_GetCustomGender()
            if gender then
                localPlayer.LTAvatarGender = gender
                if type(localPlayer.OnRep_LTAvatarGender) == "function" then
                    localPlayer:OnRep_LTAvatarGender()
                end
            end
        end
        if _G.LexusConfig.EnableLoadingAvatar then
            if not _G.LexusState.IsCloseCharacterOverrideAvatar then
                _G.LostTomb_SetCloseCharacterOverrideAvatar(true)
            end
        elseif _G.LexusState.IsCloseCharacterOverrideAvatar then
            _G.LostTomb_SetCloseCharacterOverrideAvatar(false)
        end
        if _G.LexusConfig.EnableDamageAnalysis then
            if not _G.LexusState.DamageAnalysisEnabled then
                localPlayer.bEnableDamageAnalysis = true
                _G.LexusState.DamageAnalysisEnabled = true
            end
        else
            if _G.LexusState.DamageAnalysisEnabled then
                localPlayer.bEnableDamageAnalysis = false
                _G.LexusState.DamageAnalysisEnabled = false
            end
        end
        if _G.LexusConfig.EnableSupplyBoxEvolution then
            local evolutionParam = { bIsValid = true, BoxType = 1, EvolutionLevel = 1 }
            _G.LostTomb_ShowSupplyBoxEvolution(evolutionParam)
        end
        if _G.LexusConfig.EnableMaxWalkSpeedCurve then
            if not _G.LexusState.MaxWalkSpeedCurveApplied then
                local curve = LoadObject("CurveFloat'/Game/Mod/LostTombCommon/Blueprints/Core/Curves/LT_DefaultMaxWalkSpeedCurve.LT_DefaultMaxWalkSpeedCurve'")
                if curve then
                    _G.LostTomb_AddMaxWalkSpeedCurve(curve)
                    _G.LexusState.MaxWalkSpeedCurveApplied = true
                end
            end
        end
        if _G.LexusConfig.EnableStealLifeEffect then
            if _G.LexusState.StealLifeCount > 0 then
                _G.LostTomb_UpdateStealLifeCount(0)
            end
        end
    end)
end

-- ============================================================================
-- MAIN LOOP
-- ============================================================================
local function MainLoop()
    if not _G._LICENSE_OK then return end
    if _G._MOD_EXPIRED then return end
    if isExpired then return end

    if _G.LexusState.CustomTextData == nil then
        _G.LexusState.CustomTextData = {
            OuterSpeed = 10, InnerSpeed = 10, HRecoil = 0.3, VRecoil = 0.3,
            MagicHead = 0, MagicBody = 0.5, MagicLegs = 0, IpadViewFOV = 120,
            AimTouchHipPrio = 1, AimTouchHipBone = 1, AimTouchHipCond = 1,
            AimTouchHipSpeed = 50, AimTouchHipFOV = 30, AimTouchHipDist = 250,
            AimTouchSGPrio = 1, AimTouchSGBone = 2, AimTouchSGCond = 1,
            AimTouchSGSpeed = 80, AimTouchSGFOV = 40, AimTouchSGDist = 30,
            AimTouchScopePrio = 1, AimTouchScopeBone = 2, AimTouchScopeCond = 1,
            AimTouchScopeSpeed = 40, AimTouchScopeFOV = 20, AimTouchScopeDist = 300,
            AimTouchSniperPrio = 1, AimTouchSniperBone = 1, AimTouchSniperCond = 2,
            AimTouchSniperSpeed = 30, AimTouchSniperFOV = 20, AimTouchSniperDist = 400
        }
    end

    local okData, GameplayData2 = pcall(require, "GameLua.GameCore.Data.GameplayData")
    if not okData or not GameplayData2 then return end
    local pc = GameplayData2.GetPlayerController()
    local localPlayer = nil
    if Valid(pc) then localPlayer = pc:GetPlayerCharacterSafety() end

    if not Valid(localPlayer) then
        if _G.LexusState.TrackedMarks then
            for markId, _ in pairs(_G.LexusState.TrackedMarks) do SafeRemoveMark(markId) end
        end
        _G.LexusState.TrackedMarks = {}
        for key, data in pairs(_G.LexusState.EnemyMarks) do
            if data and data.MIDs then
                for meshStr, midTable in pairs(data.MIDs) do
                    for k, _ in pairs(midTable) do midTable[k] = nil end
                end
                data.MIDs = nil
            end
        end
        _G.LexusState.EnemyMarks = {}
        _G.AK_OrigHitboxes = {}
        _G.AK_ModdedPhysAssets = {}
        _G.LexusState.PrevGraphicsState = {}
        return
    end

    local Cached_PPM = nil
    pcall(function() Cached_PPM = import("PostProcessManager").GetInstance() end)
    local Cached_SecurityCommonUtils = nil
    pcall(function() Cached_SecurityCommonUtils = require("GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils") end)
    local Cached_MyHUD = pc and pc.MyHUD or nil

    -- Unlock FPS
    if _G.LexusConfig.UnlockFPS then
        pcall(function()
            local gi = require("client.slua.logic.setting.logic_setting_graphics").GetGameInstance()
            if gi then gi:ExecuteCMD("t.MaxFPS", "165"); gi:ExecuteCMD("r.FrameRateLimit", "165") end
        end)
    end

    InitializeNativeESP()

    -- IPAD View
    if _G.LexusConfig.IpadView and _G.LexusState.CustomTextData then
        pcall(function()
            local targetTPP = _G.LexusState.CustomTextData.IpadViewFOV or 120
            local uTPPCam = localPlayer.ThirdPersonCameraComponent
            if Valid(uTPPCam) and not localPlayer.bIsWeaponAiming then
                if uTPPCam.FieldOfView ~= targetTPP then uTPPCam.FieldOfView = targetTPP end
            end
        end)
    else
        pcall(function()
            local uTPPCam = localPlayer.ThirdPersonCameraComponent
            if Valid(uTPPCam) and not localPlayer.bIsWeaponAiming then
                if uTPPCam.FieldOfView ~= 90 then uTPPCam.FieldOfView = 90 end
            end
        end)
    end

    -- Aimbot V2
    if _G.LexusConfig.AimTouchEnable then
        _G.AimTouch()
    end

    -- HiggsBoson Block
    pcall(function()
        if Valid(pc) then
            if pc.HiggsBoson then pc.HiggsBoson.bMHActive = false; pc.HiggsBoson.bCallPreReplication = false end
            if pc.HiggsBosonComponent then pc.HiggsBosonComponent.bMHActive = false; pc.HiggsBosonComponent.bCallPreReplication = false end
        end
    end)

    -- Auto Head
    pcall(function()
        local autoComp = localPlayer.AutoAimComp
        if Valid(autoComp) then
            if not _G.LexusState.OrigAutoAimCompCached then
                _G.LexusState.OrigAutoAimCompCached = {
                    bOnlyHitHead = autoComp.bOnlyHitHead,
                    HeadBoneName = autoComp.HeadBoneName,
                    Bones = autoComp.Bones,
                    ChestBoneName = autoComp.ChestBoneName,
                    PelvisBoneName = autoComp.PelvisBoneName,
                }
            end
            if _G.LexusConfig.AutoHead then
                autoComp.bOnlyHitHead = true
                autoComp.HeadBoneName = "Head"
                pcall(function() autoComp.Bones = {"Head"} end)
                autoComp.ChestBoneName = "Head"
                autoComp.PelvisBoneName = "Head"
            else
                local orig = _G.LexusState.OrigAutoAimCompCached
                autoComp.bOnlyHitHead = orig.bOnlyHitHead
                autoComp.HeadBoneName = orig.HeadBoneName
                pcall(function() autoComp.Bones = orig.Bones or {"Head", "Head", "Head"} end)
                autoComp.ChestBoneName = orig.ChestBoneName
                autoComp.PelvisBoneName = orig.PelvisBoneName
            end
        end
    end)

    -- Graphics Settings
    pcall(function()
        local lsg = require("client.slua.logic.setting.logic_setting_graphics")
        local gi = lsg.GetGameInstance()
        if gi then
            if _G.LexusConfig.RemoveGrass and not _G.LexusState.PrevGraphicsState.RemoveGrass then
                gi:ExecuteCMD("grass.DensityScale", "0")
                gi:ExecuteCMD("grass.DiscardDataOnLoad", "1")
                _G.LexusState.PrevGraphicsState.RemoveGrass = true
            elseif not _G.LexusConfig.RemoveGrass and _G.LexusState.PrevGraphicsState.RemoveGrass then
                gi:ExecuteCMD("grass.DensityScale", "1")
                gi:ExecuteCMD("grass.DiscardDataOnLoad", "0")
                _G.LexusState.PrevGraphicsState.RemoveGrass = false
            end
            if _G.LexusConfig.RemoveFog and not _G.LexusState.PrevGraphicsState.RemoveFog then
                gi:ExecuteCMD("r.Fog", "0")
                gi:ExecuteCMD("r.VolumetricFog", "0")
                _G.LexusState.PrevGraphicsState.RemoveFog = true
            elseif not _G.LexusConfig.RemoveFog and _G.LexusState.PrevGraphicsState.RemoveFog then
                gi:ExecuteCMD("r.Fog", "1")
                gi:ExecuteCMD("r.VolumetricFog", "1")
                _G.LexusState.PrevGraphicsState.RemoveFog = false
            end
            if _G.LexusConfig.WhiteBody and not _G.LexusState.PrevGraphicsState.WhiteBody then
                gi:ExecuteCMD("r.CharacterDiffuseOffset", "2")
                gi:ExecuteCMD("r.CharacterDiffusePower", "5")
                gi:ExecuteCMD("r.CharacterMinShadowFactor", "100")
                _G.LexusState.PrevGraphicsState.WhiteBody = true
            elseif not _G.LexusConfig.WhiteBody and _G.LexusState.PrevGraphicsState.WhiteBody then
                gi:ExecuteCMD("r.CharacterDiffuseOffset", "0")
                gi:ExecuteCMD("r.CharacterDiffusePower", "1")
                gi:ExecuteCMD("r.CharacterMinShadowFactor", "1")
                _G.LexusState.PrevGraphicsState.WhiteBody = false
            end
            if _G.LexusConfig.ColorBodyV2 and not _G.LexusState.PrevGraphicsState.ColorBodyV2 then
                gi:ExecuteCMD("r.CharacterMinShadowFactor", "4")
                gi:ExecuteCMD("r.CharacterDiffuseOffset", "200")
                gi:ExecuteCMD("r.CharacterDiffusePower", "200")
                _G.LexusState.PrevGraphicsState.ColorBodyV2 = true
            elseif not _G.LexusConfig.ColorBodyV2 and _G.LexusState.PrevGraphicsState.ColorBodyV2 then
                gi:ExecuteCMD("r.CharacterMinShadowFactor", "1")
                gi:ExecuteCMD("r.CharacterDiffuseOffset", "0")
                gi:ExecuteCMD("r.CharacterDiffusePower", "1")
                _G.LexusState.PrevGraphicsState.ColorBodyV2 = false
            end
            if _G.LexusConfig.BlackSky and not _G.LexusState.PrevGraphicsState.BlackSky then
                gi:ExecuteCMD("r.CylinderMaxDrawHeight", "9999")
                _G.LexusState.PrevGraphicsState.BlackSky = true
            elseif not _G.LexusConfig.BlackSky and _G.LexusState.PrevGraphicsState.BlackSky then
                gi:ExecuteCMD("r.CylinderMaxDrawHeight", "0000")
                _G.LexusState.PrevGraphicsState.BlackSky = false
            end
        end
    end)

    -- Weapon Mods
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
            for _, entity in ipairs(entities) do
                local anyWeaponModOn = _G.LexusConfig.CustomHRecoil or _G.LexusConfig.CustomVRecoil or _G.LexusConfig.LessShake or _G.LexusConfig.Accuracy or _G.LexusConfig.Crosshair or _G.LexusConfig.AutoHead or _G.LexusConfig.CustomAimbot or _G.LexusConfig.CustomAimbotClose
                if anyWeaponModOn then
                    if not entity.OriginalStatsCached then
                        entity.OriginalStatsCached = {
                            GameDeviationFactor = entity.GameDeviationFactor,
                            GameDeviationAccuracy = entity.GameDeviationAccuracy,
                            AccessoriesHRecoilFactor = entity.AccessoriesHRecoilFactor,
                            AccessoriesVRecoilFactor = entity.AccessoriesVRecoilFactor,
                            RecoilKick = entity.RecoilKick,
                            RecoilKickADS = entity.RecoilKickADS,
                            AnimationKick = entity.AnimationKick
                        }
                    end
                    if _G.LexusConfig.CustomHRecoil then entity.AccessoriesHRecoilFactor = _G.LexusState.CustomTextData.HRecoil or 0.3 end
                    if _G.LexusConfig.CustomVRecoil then entity.AccessoriesVRecoilFactor = _G.LexusState.CustomTextData.VRecoil or 0.3 end
                    if _G.LexusConfig.LessShake then entity.RecoilKick = 0.5; entity.RecoilKickADS = 0.0; entity.AnimationKick = 0.5 end
                    if _G.LexusConfig.Accuracy then entity.GameDeviationAccuracy = 0.0 end
                    if _G.LexusConfig.Crosshair then entity.GameDeviationFactor = 0.1 end
                    entity.LexusWeaponModsActive = true
                elseif entity.LexusWeaponModsActive then
                    if entity.OriginalStatsCached then
                        local orig = entity.OriginalStatsCached
                        entity.GameDeviationFactor = orig.GameDeviationFactor
                        entity.GameDeviationAccuracy = orig.GameDeviationAccuracy
                        entity.AccessoriesHRecoilFactor = orig.AccessoriesHRecoilFactor
                        entity.AccessoriesVRecoilFactor = orig.AccessoriesVRecoilFactor
                        entity.RecoilKick = orig.RecoilKick
                        entity.RecoilKickADS = orig.RecoilKickADS
                        entity.AnimationKick = orig.AnimationKick
                    end
                    entity.LexusWeaponModsActive = false
                end
            end
        end
    end)

    -- Enemy Loop
    pcall(function()
        local allCharacters = {}
        if GameplayData2.GetAllPlayerCharacters then allCharacters = GameplayData2.GetAllPlayerCharacters()
        elseif GameplayData2.GameCharacters then for _, char in pairs(GameplayData2.GameCharacters) do table.insert(allCharacters, char) end end

        local currentValidKeys = {}
        for _, enemy in pairs(allCharacters) do
            if Valid(enemy) and enemy ~= localPlayer then
                currentValidKeys[GetSafeEnemyKey(enemy)] = true
            end
        end

        for key, data in pairs(_G.LexusState.EnemyMarks) do
            if not currentValidKeys[key] then
                SafeRemoveMark(data.radarMark)
                SafeRemoveMark(data.hpMark)
                SafeRemoveMark(data.distMark)
                if data.MIDs then
                    for meshStr, midTable in pairs(data.MIDs) do
                        for k, _ in pairs(midTable) do midTable[k] = nil end
                    end
                    data.MIDs = nil
                end
                data.enemy = nil
                data.CachedMeshes = nil
                _G.LexusState.EnemyMarks[key] = nil
            end
        end

        local realCount = 0
        local aiCount = 0

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
                _G.LexusState.EnemyMarks[eKey] = _G.LexusState.EnemyMarks[eKey] or { enemy = enemy }
                local markData = _G.LexusState.EnemyMarks[eKey]
                markData.enemy = enemy

                if not bIsReallyDead then
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

                    if _G.LexusConfig.WallXuyenTuong then
                        if isMeshChanged or not markData.WallhackApplied then
                            ApplyWallXuyenTuong(enemy, markData)
                            markData.WallhackApplied = true
                            markData.LastMeshCountWall = currentMeshCount
                        end
                    else
                        UndoWallXuyenTuong(enemy, markData)
                    end

                    if _G.LexusConfig.ColorBodyV2 then
                        ApplyColorBodyV2(enemy, pc, markData)
                    else
                        UndoColorBodyV2(enemy, markData)
                    end

                    local distM = 0
                    pcall(function() distM = localPlayer:GetDistanceTo(enemy) / 100 end)

                    local currentHp, maxHp = 100, 100
                    local showFrameUI = _G.LexusConfig.EspLoai5 or _G.LexusConfig.EspVipPro or _G.LexusConfig.EspVip
                    if showFrameUI then
                        pcall(function()
                            if enemy.Health then currentHp = enemy.Health elseif type(enemy.GetHealth) == "function" then currentHp = enemy:GetHealth() end
                            if enemy.HealthMax then maxHp = enemy.HealthMax elseif type(enemy.GetHealthMax) == "function" then maxHp = enemy:GetHealthMax() end
                        end)
                        if maxHp <= 0 then maxHp = 100 end
                    end
                    local hpRatio = currentHp / maxHp

                    if _G.LexusConfig.EspAntenna then
                        pcall(function()
                            local MyHUD = Cached_MyHUD
                            if Valid(MyHUD) and distM <= 400 then
                                local loopCount = 8
                                local zStep = 1000
                                local baseZ = 105
                                local topZ = baseZ + (loopCount * zStep)
                                for i = 1, loopCount do
                                    local zOffset = baseZ + (i * zStep)
                                    MyHUD:AddDebugText("|", enemy, 0.06, {X=0, Y=0, Z=zOffset}, {X=0, Y=0, Z=zOffset}, C_GREEN, true, false, true, nil, 1.2, true)
                                end
                                MyHUD:AddDebugText("I", enemy, 0.06, {X=0, Y=0, Z=topZ + 60}, {X=0, Y=0, Z=topZ + 60}, C_GREEN, true, false, true, nil, 1.5, true)
                            end
                        end)
                    end

                    if _G.LexusConfig.EspLoai6 then
                        pcall(function()
                            local MyHUD = Cached_MyHUD
                            if Valid(MyHUD) and Valid(eMesh) and type(eMesh.GetSocketLocation) == "function" and distM <= 400 and aLoc then
                                local boneLocs = {}
                                for _, bName in ipairs(GLOBAL_BONE_LIST) do
                                    local shouldDraw = true
                                    if distM > 150 and (bName ~= "head" and bName ~= "pelvis" and bName ~= "neck_01") then shouldDraw = false end
                                    if shouldDraw then
                                        local wLoc = nil
                                        if type(eMesh.GetSocketLocation) == "function" then wLoc = eMesh:GetSocketLocation(bName) end
                                        if wLoc then
                                            local ox = wLoc.X - aLoc.X
                                            local oy = wLoc.Y - aLoc.Y
                                            local oz = wLoc.Z - aLoc.Z
                                            boneLocs[bName] = {X=ox, Y=oy, Z=oz}
                                            local mark = "▪"
                                            local fixedSize = 0.25
                                            local color = C_CYAN
                                            if bName == "head" then mark = "●"; fixedSize = 0.45; color = C_RED
                                            elseif bName == "pelvis" or bName == "neck_01" then mark = "▪"; fixedSize = 0.35; color = C_YELLOW end
                                            MyHUD:AddDebugText(mark, enemy, 0.06, boneLocs[bName], boneLocs[bName], color, true, false, true, nil, fixedSize, true)
                                        end
                                    end
                                end
                                if distM <= 100 then
                                    for _, pair in ipairs(GLOBAL_CONNECTIONS) do
                                        local p1 = boneLocs[pair[1]]
                                        local p2 = boneLocs[pair[2]]
                                        if p1 and p2 then
                                            local col = pair[3]
                                            local dx = p2.X - p1.X
                                            local dy = p2.Y - p1.Y
                                            local dz = p2.Z - p1.Z
                                            local length = math.sqrt(dx*dx + dy*dy + dz*dz)
                                            local segments = math.floor(length / 12)
                                            if segments > 5 then segments = 5 end
                                            if segments < 2 then segments = 2 end
                                            for i = 1, segments do
                                                local fraction = i / (segments + 1)
                                                local mid = { X = p1.X + dx * fraction, Y = p1.Y + dy * fraction, Z = p1.Z + dz * fraction }
                                                MyHUD:AddDebugText("•", enemy, 0.06, mid, mid, col, true, false, true, nil, 0.35, true)
                                            end
                                        end
                                    end
                                end
                            end
                        end)
                    end

                    if _G.LexusConfig.EspLoai7 then
                        pcall(function()
                            local MyHUD = Cached_MyHUD
                            if Valid(MyHUD) then
                                if distM <= 600 then if isBot then aiCount = aiCount + 1 else realCount = realCount + 1 end end
                                if distM <= 400 then
                                    local stateText = ""
                                    local pose = nil
                                    if enemy.PoseState then pose = enemy.PoseState
                                    elseif type(enemy.GetPoseState) == "function" then pose = enemy:GetPoseState() end
                                    if pose == 0 or pose == "Stand" then stateText = "Standing"
                                    elseif pose == 1 or pose == "Crouch" then stateText = "Crouching"
                                    elseif pose == 2 or pose == "Prone" then stateText = "Prone"
                                    else stateText = "Standing" end
                                    local curTime = os.clock()
                                    if markData.AK_LAST_WEP_TIME == nil or curTime > markData.AK_LAST_WEP_TIME + 1.5 then
                                        local eWeapon = nil
                                        if enemy.CurrentWeapon then eWeapon = enemy.CurrentWeapon
                                        elseif type(enemy.GetCurrentWeapon) == "function" then eWeapon = enemy:GetCurrentWeapon()
                                        elseif enemy.WeaponManagerComponent then eWeapon = enemy.WeaponManagerComponent.CurrentWeaponReplicated end
                                        local weaponName = "No Weapon"
                                        if Valid(eWeapon) then
                                            if type(eWeapon.GetWeaponName) == "function" then weaponName = eWeapon:GetWeaponName() end
                                        else weaponName = "Unarmed" end
                                        markData.AK_CACHED_WEP_NAME = tostring(weaponName)
                                        markData.AK_LAST_WEP_TIME = curTime
                                    end
                                    stateText = stateText .. " - " .. (markData.AK_CACHED_WEP_NAME or "Unarmed")
                                    local textColor = isBot and C_CYAN or C_YELLOW
                                    local dynamicScale = math.max(0.5, 0.8 - (distM / 400))
                                    MyHUD:AddDebugText(stateText, enemy, 0.06, {X=0, Y=0, Z=100}, {X=0, Y=0, Z=100}, textColor, true, false, true, nil, dynamicScale, true)
                                end
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
                            if show then
                                if enemy.Replay_IsEnemyFrameUIExisted and not enemy:Replay_IsEnemyFrameUIExisted() then enemy:Replay_CreateEnemyFrameUI(true, true) end
                                if enemy.Replay_SetVisiableOfFrameUI then enemy:Replay_SetVisiableOfFrameUI(true) end
                                if enemy.Replay_UpdateEnemyFrameUI then enemy:Replay_UpdateEnemyFrameUI(hpRatio) end
                            end
                        end)
                    else
                        pcall(function()
                            if enemy.Replay_SetVisiableOfFrameUI then enemy:Replay_SetVisiableOfFrameUI(false) end
                        end)
                    end

                    if _G.LexusConfig.EspVipPro then
                        pcall(function()
                            local hud = Cached_MyHUD
                            if Valid(hud) and hud.AddDebugText and distM <= 400 then
                                local dynamicScale = math.max(0.55, 0.95 - (distM / 400))
                                local hpPercent = hpRatio
                                local isKnock = (currentHp <= 0 and enemy.HealthStatus == 1)
                                local enemyName = "Enemy"
                                pcall(function() if enemy.PlayerName then enemyName = enemy.PlayerName elseif type(enemy.GetPlayerName) == "function" then enemyName = enemy:GetPlayerName() end end)
                                if enemyName == "" then enemyName = "Enemy" end
                                if isKnock then enemyName = "KNOCK: " .. enemyName end
                                local hpColor = C_GREEN
                                if hpPercent < 0.3 then hpColor = C_RED
                                elseif hpPercent < 0.7 then hpColor = C_YELLOW end
                                if isKnock then hpColor = C_RED end
                                hud:AddDebugText(enemyName, enemy, 0.06, {X=0, Y=0, Z=-370}, {X=0, Y=0, Z=-370}, C_WHITE, true, false, true, nil, dynamicScale * 1.1, true)
                                if not isKnock then
                                    local segments = 6
                                    local filled = math.floor(hpPercent * segments)
                                    local startZ = 20
                                    local spacing = 10.0 * dynamicScale
                                    for j = 1, segments do
                                        local color = (j <= filled) and hpColor or {R=30,G=30,B=30,A=180}
                                        hud:AddDebugText("█", enemy, 0.06, {X=0, Y=-115, Z=startZ + (j * spacing)}, {X=0, Y=-115, Z=startZ + (j * spacing)}, color, true, false, true, nil, dynamicScale * 1.2, true)
                                    end
                                    hud:AddDebugText(string.format("%d%%", math.floor(hpPercent * 100)), enemy, 0.06, {X=0, Y=-60, Z=startZ - 12}, {X=0, Y=-60, Z=startZ - 12}, hpColor, true, false, true, nil, dynamicScale * 0.8, true)
                                else
                                    hud:AddDebugText("DOWN", enemy, 0.06, {X=0, Y=-115, Z=50}, {X=0, Y=-115, Z=50}, C_RED, true, false, true, nil, dynamicScale * 1.0, true)
                                end
                            end
                        end)
                    end

                    if _G.LexusConfig.EspDistance then
                        pcall(function()
                            local hud = Cached_MyHUD
                            if Valid(hud) and hud.AddDebugText and distM <= 400 then
                                local dynamicScale = math.max(0.55, 0.95 - (distM / 400))
                                hud:AddDebugText(string.format("[%dm]", math.floor(distM)), enemy, 0.06, {X=0, Y=115, Z=20}, {X=0, Y=115, Z=20}, C_BLUE_TEXT, true, false, true, nil, dynamicScale * 1.5, true)
                            end
                        end)
                    end

                    if _G.LexusConfig.EspVip then
                        if markData.hpMark == nil then markData.hpMark = SafeAddMark(1006, FVector(0,0,0), 0, "", 4, enemy) end
                        if markData.distMark == nil then markData.distMark = SafeAddMark(9999, FVector(0,0,0), 0, "", 4, enemy) end
                    else
                        if markData.hpMark then SafeRemoveMark(markData.hpMark); markData.hpMark = nil end
                        if markData.distMark then SafeRemoveMark(markData.distMark); markData.distMark = nil end
                    end

                    if _G.LexusConfig.EspRadar then
                        pcall(function()
                            local UGameplayStatics = import("GameplayStatics")
                            local CGameWorld = slua_GameFrontendHUD and slua_GameFrontendHUD:GetWorld()
                            local curTime = (UGameplayStatics and CGameWorld) and UGameplayStatics.GetTimeSeconds(CGameWorld) or os.clock()
                            markData.LastRadarUpdate = markData.LastRadarUpdate or 0
                            if curTime > markData.LastRadarUpdate + 0.5 then
                                local headLoc = nil
                                if type(enemy.GetHeadLocation) == "function" then headLoc = enemy:GetHeadLocation(false) end
                                if headLoc then
                                    local InGameMarkTools = require("GameLua.Mod.BaseMod.Common.InGameMarkTools")
                                    if markData.radarMark and InGameMarkTools and InGameMarkTools.HideMapMark then InGameMarkTools.HideMapMark(markData.radarMark) end
                                    if InGameMarkTools and InGameMarkTools.ClientAddMapMark then
                                        markData.radarMark = InGameMarkTools.ClientAddMapMark(1003, headLoc, 0, "", 4, nil)
                                    end
                                    markData.LastRadarUpdate = curTime
                                end
                            end
                        end)
                    else
                        if markData.radarMark then
                            SafeRemoveMark(markData.radarMark)
                            markData.radarMark = nil
                        end
                    end

                    if _G.LexusConfig.EspOutline then
                        pcall(function()
                            local PPM = Cached_PPM
                            local avatarComp = (type(enemy.getAvatarComponent2) == "function") and enemy:getAvatarComponent2() or nil
                            if Valid(avatarComp) and Valid(PPM) then
                                PPM.OutlineThickness = _G.LexusConfig.OutlineThickness
                                if PPM.OutlineColor then PPM.OutlineColor = {r = 1, g = 0, b = 0, a = 1} end
                                PPM:EnableAvatarOutline(avatarComp, true)
                            end
                        end)
                    else
                        pcall(function()
                            local PPM = Cached_PPM
                            local avatarComp = (type(enemy.getAvatarComponent2) == "function") and enemy:getAvatarComponent2() or nil
                            if Valid(avatarComp) and Valid(PPM) then PPM:EnableAvatarOutline(avatarComp, false) end
                        end)
                    end
                else
                    if not markData.IsCleanedUp then
                        SafeRemoveMark(markData.radarMark); markData.radarMark = nil
                        SafeRemoveMark(markData.hpMark); markData.hpMark = nil
                        SafeRemoveMark(markData.distMark); markData.distMark = nil
                        if markData.MIDs then
                            for meshStr, midTable in pairs(markData.MIDs) do
                                for k, _ in pairs(midTable) do midTable[k] = nil end
                            end
                            markData.MIDs = nil
                        end
                        markData.IsCleanedUp = true
                    end
                end
            end
        end

        if _G.LexusConfig.EspLoai7 then
            pcall(function()
                local MyHUD = Cached_MyHUD
                if Valid(MyHUD) then
                    local totalEnemies = realCount + aiCount
                    local text = string.format("Total Enemies: %d", totalEnemies)
                    MyHUD:AddDebugText(text, localPlayer, 0.06, {X=0, Y=0, Z=0}, {X=0, Y=0, Z=0}, C_RED, true, false, true, nil, 0.8, true)
                end
            end)
        end
    end)

    LostTombFeaturesLoop()
end

-- ============================================================================
-- END PART 11
-- ============================================================================
-- [CONTINUE PASTE FROM PART 11]

-- ============================================================================
-- EXPIRED TICK
-- ============================================================================
_G.LexusState.LoopToken = (_G.LexusState.LoopToken or 0) + 1
local myToken = _G.LexusState.LoopToken

local function ExpiredTick()
    if not _G.LexusNotifiedPopup then
        pcall(function()
            local Msg = require("client.slua.logic.common.logic_common_msg_box")
            if Msg and Msg.Show then
                Msg.Show(1, "MOD EXPIRED", "YOUR MOD VERSION HAS EXPIRED!\nPLEASE CONTACT ADMIN TO RENEW.\nTelegram @HUSSNAINxPUBG",
                function()
                    local Web = require("client.slua.logic.url.logic_webview_sdk")
                    if Web and Web.OpenURL then Web:OpenURL("t.me/HUSSNAINxPUBG") end
                end,
                function() end, "CONTACT ADMIN", "CLOSE")
                _G.LexusNotifiedPopup = true
            end
        end)
        if not _G.LexusNotifiedPopup then
            local okTicker, ticker = pcall(require, "common.time_ticker")
            if okTicker and ticker and ticker.AddTimerOnce then
                ticker.AddTimerOnce(2.0, ExpiredTick)
            end
        end
    end
end

-- ============================================================================
-- FAStTICK - LICENSE CHECK FIRST
-- ============================================================================
local function FastTick()
    -- LICENSE CHECK FIRST
    if not _G._LICENSE_OK then
        if not _G._LICENSE_SHOWN then
            pcall(function()
                local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
                if slua.isValid(pc) then
                    local character = pc:GetPlayerCharacterSafety()
                    if slua.isValid(character) then
                        _G._LICENSE_SHOWN = true
                        _G.LicenseSystem.Start(character, function()
                            _G._LICENSE_OK = true
                            _G._MOD_EXPIRED = false
                            print("[HUSSNAINxPUBG] License Granted!")
                        end)
                    end
                end
            end)
        end
        -- Retry ticker
        local okTicker, ticker = pcall(require, "common.time_ticker")
        if okTicker and ticker and ticker.AddTimerOnce then
            ticker.AddTimerOnce(0.5, FastTick)
        end
        return
    end

    if _G._MOD_EXPIRED then
        local okTicker, ticker = pcall(require, "common.time_ticker")
        if okTicker and ticker and ticker.AddTimerOnce then
            ticker.AddTimerOnce(1.0, FastTick)
        end
        return
    end

    -- Time-based expiry
    if isExpired then
        if not _G.LexusNotifiedExpire then
            Notify("MOD EXPIRED! CONTACT ADMIN TO RENEW!\nTelegram @HUSSNAINxPUBG")
            _G.LexusNotifiedExpire = true
            ExpiredTick()
        end
        return
    end

    if myToken ~= _G.LexusState.LoopToken then return end
    pcall(MainLoop)
    local okTicker, ticker = pcall(require, "common.time_ticker")
    if okTicker and ticker and ticker.AddTimerOnce then
        ticker.AddTimerOnce(0.01, FastTick)
    end
end

-- Start FastTick with slight delay
pcall(function()
    local ticker = require("common.time_ticker")
    if ticker and ticker.AddTimerOnce then
        ticker.AddTimerOnce(1.0, FastTick)
    end
end)

-- ============================================================================
-- BAN SECTION FEATURES LOOP
-- ============================================================================
local function BanFeaturesLoop()
    pcall(function()
        if not _G._LICENSE_OK then return end
        local uCon = slua_GameFrontendHUD:GetPlayerController()
        if not Valid(uCon) then return end
        local pawn = uCon:GetPlayerCharacterSafety()
        if not Valid(pawn) then return end

        if _G.BanConfig.FlyMode then
            if pawn.CharacterMovement then
                pawn.CharacterMovement.GravityScale = -0.45
                pawn.CharacterMovement.MaxWalkSpeed = 1350
                pawn.CharacterMovement.JumpZVelocity = 1350
            end
        end
        if _G.BanConfig.NoFallDamage then
            if pawn.CharacterMovement then
                pawn.CharacterMovement.bEnableLandDamage = false
                pawn.CharacterMovement.FallingLandedDamageEnabled = false
            end
            pawn:SetAttrValue("LandDamageReduce", 1, -1)
        end
        if _G.BanConfig.SpinMode and Valid(pawn.Mesh) then
            local spinAngle = (_G.spinAngle or 0) + 20
            if spinAngle > 360 then spinAngle = 0 end
            _G.spinAngle = spinAngle
            pawn.Mesh:K2_SetRelativeRotation(FRotator(0, spinAngle, 0), false, nil, false)
        end
        if _G.BanConfig.RemoveFogGlobal then
            local UKismetSystemLibrary = import("KismetSystemLibrary")
            UKismetSystemLibrary.ExecuteConsoleCommand(nil, "r.Fog 0")
            UKismetSystemLibrary.ExecuteConsoleCommand(nil, "r.VolumetricFog 0")
        end
        if _G.BanConfig.RemoveGrassGlobal then
            local UKismetSystemLibrary = import("KismetSystemLibrary")
            UKismetSystemLibrary.ExecuteConsoleCommand(nil, "foliage.DensityScale 0")
            UKismetSystemLibrary.ExecuteConsoleCommand(nil, "grass.DensityScale 0")
        end
    end)
end

pcall(function()
    local uCon = slua_GameFrontendHUD:GetPlayerController()
    if Valid(uCon) then
        uCon:AddGameTimer(0.05, true, BanFeaturesLoop)
    end
end)

-- ============================================================================
-- WATERMARK (License guard ke saath)
-- ============================================================================
local function GetRainbowLinearColor()
    local time = os.clock()
    local r = math.sin(time * 0.8) * 0.5 + 0.5
    local g = math.sin(time * 0.8 + 2.094) * 0.5 + 0.5
    local b = math.sin(time * 0.8 + 4.188) * 0.5 + 0.5
    return FLinearColor(r, g, b, 1.0)
end

pcall(function()
    local IPS = require("GameLua.Mod.Library.Client.UI.IngamePhoneStateUI")
    if IPS and IPS.__inner_impl then
        IPS.__inner_impl.UpdateArtQualityUI = function(self, _, _)
            if not _G._LICENSE_OK then return end
            if self.UIRoot and self.UIRoot.TextBlock_quality then
                self.UIRoot.TextBlock_quality:SetText("@HUSSNAINxPUBG")
                local color = GetRainbowLinearColor()
                self.UIRoot.TextBlock_quality:SetColorAndOpacity(FSlateColor(color))
            end
        end
    end
end)

pcall(function()
    local IngamePhoneStateUI = require("GameLua.Mod.Library.Client.UI.IngamePhoneStateUI")
    if IngamePhoneStateUI and IngamePhoneStateUI.__inner_impl then
        IngamePhoneStateUI.__inner_impl.SetPingText = function(self, ping, bLostNet)
            if not _G._LICENSE_OK then return end
            if self.UIRoot and self.UIRoot.TextBlock_Ping then
                self.UIRoot.TextBlock_Ping:SetText("HUSSNAIN")
                self.UIRoot.TextBlock_Ping:SetColorAndOpacity(FSlateColor(FLinearColor(1, 0, 0, 1)))
            end
        end
    end
end)

-- ============================================================================
-- FINAL INITIALIZATION (auto-run on file load)
-- ============================================================================
-- AutoSave loop already started earlier
-- FastTick already started earlier (with delay)

-- Print status
print("[HUSSNAINxPUBG] VIP MOD LOADED - Waiting for license...")
print("[CREDIT] @HUSSNAINxPUBG | WhatsApp: 03147396648 | Telegram: @HUSSNAINxPUBG")

-- ============================================================================
-- CLASS REGISTRATION (MUST BE LAST)
-- ============================================================================
local class = require("class")
local CCharacterBase = require("GameLua.GameCore.Framework.CharacterBase")
local CBRPlayerCharacterBase = class(CCharacterBase, nil, BRPlayerCharacterBase)
return require("combine_class").DeclareFeature(CBRPlayerCharacterBase, {
  { SkyTransition = "GameLua.Mod.BaseMod.Gameplay.Feature.SkyControl.PlayerCharacterSkyTransitionFeature" },
  { CarryDeadBoxFeature = "GameLua.Mod.Library.GamePlay.Feature.CarryDeadBoxFeature" },
  { SpecialSuitFeature = "GameLua.Mod.Library.GamePlay.Feature.SpecialSuitFeature" },
  { TeleportPawnFeature = "GameLua.Mod.Library.GamePlay.Feature.TeleportPawnFeature" },
  { LifterControl = "GameLua.Mod.BaseMod.Gameplay.Feature.Player.CharacterLifterControlFeature" },
  { FinalKillEffect = "GameLua.Mod.BaseMod.Gameplay.Feature.Player.PlayerCharacterFinalKillEffectFeature" },
  { CampFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.Camp.PlayerCharacterCampFeature" },
  { BuildSkateFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.PlayerCharacterBuildVehicleFeature" },
  { CommonBornlandTransformFeature = "GameLua.Mod.BaseMod.Gameplay.Feature.HeroPropFeature.CommonBornlandTransformFeature" },
  { ParachuteFormation = "GameLua.Mod.BaseMod.GamePlay.Feature.ParachuteFormationFeature" }
}, "BRPlayerCharacterBase")

-- ============================================================================
-- END OF FILE
-- ============================================================================
