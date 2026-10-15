-- Original class and feature registration execute first, without an addon condition.
local originalExport=(function()
local BRPlayerCharacterBase = {
  ServerRPC = {},
  ClientRPC = {},
  MulticastRPC = {},
  LuaEventContainer = {}
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
local ECharacterHideMovementAcive = import("ECharacterHideMovementAcive")
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
  else
    self:AddCommonEventWithConditions(EVENTTYPE_INGAME_NORMAL, EVENTID_GAME_MODE_STATE_CHANGE, {
      [1] = "FinishedState"
    }, self.HandleFinishedState, self)
    self:AddControlEvent(self, "OnPawnRespawnDelegate", self.OnRespawnRehideCheck, self)
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
  if PawnState == EPawnState.SwitchPP then
    local uPlayerController = self:GetPlayerControllerSafety()
    if slua.isValid(uPlayerController) then
      uPlayerController:BroadcastUIMessage("UIMsg_FPPModeChange", 0, "", "")
    end
  end
end

function BRPlayerCharacterBase:HandleFinishedState()
  print(bWriteLog and "BRPlayerCharacterBase:HandleFinishedState", self.STCharacterMovement)
  if slua.isValid(self.STCharacterMovement) and self.STCharacterMovement.SetDynamicSimpleQueryConfigDisable then
    local EDynamicSimpleQueryConfigDisableMask = import("EDynamicSimpleQueryConfigDisableMask")
    self.STCharacterMovement:SetDynamicSimpleQueryConfigDisable(EDynamicSimpleQueryConfigDisableMask.Bit0, true)
  end
end

function BRPlayerCharacterBase:OnRespawnRehideCheck()
  if not self:GetEnsure() then
    return
  end
  self:AddGameTimer(0.5, false, function()
    if not slua.isValid(self.Object) then
      return
    end
    if self:HasState(EPawnState.InPlane) then
      self:SetCharacterHideInGame(true, true, true, 1, ECharacterHideMovementAcive.Normal)
      print(bWriteLog and "BRPlayerCharacterBase:OnRespawnRehideCheck re-hide AI on plane, PlayerKey:", self.PlayerKey)
    end
  end)
end

function BRPlayerCharacterBase:CheckAddCheckFallingDistanceComponent()
  if CGameMode and CGameMode.GameModeType and CGameState and CGameState.GameModeID then
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
  local uGameState = GameplayData:GetGameState()
  if slua.isValid(uGameState) and Game:IsClassOf(uGameState, STExtraGameStateBase) then
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

function BRPlayerCharacterBase:HandleOnMovementModeChangedNew()
  print(bWriteLog and "BRPlayerCharacterBase:HandleOnMovementModeChanged11")
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

function BRPlayerCharacterBase:PreAttachedToVehicle()
  local IsDS = UKismetSystemLibrary.IsDedicatedServer(self)
  if not IsDS then
    return
  end
  local MainPlayerController = self:GetPlayerControllerSafety()
  if not slua.isValid(MainPlayerController) then
    return
  end
  local CharacterAvatarComp2_BP = self.CharacterAvatarComp2_BP
  if not slua.isValid(CharacterAvatarComp2_BP) then
    return
  end
  local CommerAvatarDataUtil = require("GameLua.Activity.Commercialize.GamePlay.CommerAvatarDataUtil")
  local changedVehicleId = CommerAvatarDataUtil:ChangeVehicleSkinByClothes(MainPlayerController, CharacterAvatarComp2_BP)
  local ESTExtraVehicleShapeType = import("ESTExtraVehicleShapeType")
  if changedVehicleId then
    local UAvatarUtils = import("AvatarUtils")
    if UAvatarUtils.GetVehicleShapeBySkinID(changedVehicleId) == ESTExtraVehicleShapeType.VST_Horse then
      local uCurPlayerState = self:GetPlayerStateSafety()
      if slua.isValid(uCurPlayerState) then
        print(bWriteLog and "  BRPlayerCharacterBase:PreAttachedToVehicle. changedVehicleId: " .. tostring(changedVehicleId))
        uCurPlayerState:AddGeneralCount(468, 1, false)
      end
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
      print(bWriteLog and "BRPlayerCharacterBase:ParachuteJump over")
    else
      EventSystem:postEvent(EVENTTYPE_INGAME_NORMAL, EVENTID_AI_CALL_PARACHUTE_JUMP, self.Object)
      print(bWriteLog and "BRPlayerCharacterBase:ParachuteJump AI JUMP over, Loc=", tostring(self:K2_GetActorLocation():ToString()))
    end
  end
end

function BRPlayerCharacterBase:OnMovementBaseChangedEvent(uCharacter, uNewMovementBase, uOldMovementBase)
  if uCharacter ~= self.Object then
    return
  end
  print(bWriteLog and string.format("BRPlayerCharacterBase:OnMovementBaseChangedEvent %s, Base: %s -> %s", uCharacter, uOldMovementBase, uNewMovementBase))
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
  if not slua.isValid(Base) or not Base.GetOwner then
    return
  end
  local Lifter = Base:GetOwner()
  if not slua.isValid(Lifter) then
    return
  end
  if not Lifter.AddCharacter then
    return
  end
  return Lifter
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

  local function loadLater()
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
  if self:HasState(EPawnState.WebSwing) and Slot ~= ESurviveWeaponPropSlot.SWPS_None and slua.isValid(self.STCharacterMovement) then
    local SpiderSwingObj = self.STCharacterMovement:GetSpecialMoveObjBySpecialMoveType(ESpecialMovementType.SPECIAL_MOVE_SpiderSwing)
    if slua.isValid(SpiderSwingObj) then
      local nCurState = SpiderSwingObj:GetCurMoveState()
      if nCurState == ESpiderSwingMoveState.Launching or nCurState == ESpiderSwingMoveState.Swinging then
        print(bWriteLog and "BRPlayerCharacterBase:SwitchWeaponCheck blocked by SpiderSwing state: " .. tostring(nCurState))
        return false
      end
    end
  end
  return self.Super:SwitchWeaponCheck(Slot, IgnoreState)
end

local VICTORY_DANCE_FX_MAP = {
  [12219601] = 22010089
}
local PublishRegionMacros = require("client.slua.config.ClientMacros.PublishRegionMacros")
local isFitVersion = PublishRegionMacros.IsFITVersion()

local function ResolveEmoteResID(ItemID)
  local FxID = VICTORY_DANCE_FX_MAP[ItemID]
  if not FxID or FxID == ItemID then
    return ItemID
  end
  local model_util = require("client.common.model_util")
  local FxBPID = model_util.GetBPID(FxID)
  local ResID = ItemID
  if FxBPID and 0 < FxBPID and model_util.IsBattleItemHandleExist("Emote", FxBPID, false, false) then
    ResID = FxID
  end
  print(bWriteLog and string.format("BRPlayerCharacterBase 11 ResolveEmoteResID ItemID:%s, FxID:%s, FxBPID:%s, ResID:%s", tostring(ItemID), tostring(FxID), tostring(FxBPID), tostring(ResID)))
  if isFitVersion and ResID == 12219601 then
    print(bWriteLog and "BRPlayerCharacterBase ResolveEmoteResID 12219601 to 12222069")
    return 12222069
  end
  return ResID
end

function BRPlayerCharacterBase:GetEmoteHandlePath(ItemID)
  local ResID = ResolveEmoteResID(ItemID)
  if self.Super then
    return self.Super:GetEmoteHandlePath(ResID)
  end
  local model_util = require("client.common.model_util")
  local BPID = model_util.GetBPID(ResID)
  if not BPID or BPID <= 0 then
    return ""
  end
  return model_util.GetPath("Emote", BPID, false, false) or ""
end

function BRPlayerCharacterBase:GetEmoteHandle(ItemID)
  local ResID = ResolveEmoteResID(ItemID)
  if self.Super then
    return self.Super:GetEmoteHandle(ResID)
  end
  local model_util = require("client.common.model_util")
  local BPID = model_util.GetBPID(ResID)
  if not BPID or BPID <= 0 then
    return nil
  end
  local HandleClass = model_util.GetClass("Emote", BPID, false, false)
  if not HandleClass then
    return nil
  end
  local Handle = HandleClass()
  if not slua.isValid(Handle) then
    return nil
  end
  return Handle
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
    BuildAircraftVehicleFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.PlayerCharacterBuildVehicleFeature"
  },
  {
    UnifiedBuildVehicleFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.UnifiedBuildVehicleFeature"
  },
  {
    CommonBornlandTransformFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.HeroPropFeature.CommonBornlandTransformFeature"
  },
  {
    ParachuteFormation = "GameLua.Mod.BaseMod.GamePlay.Feature.ParachuteFormationFeature"
  },
  {
    ParachuteSprint = "GameLua.Mod.BaseMod.GamePlay.Feature.Parachute.ParachuteSprintFeature"
  },
  {
    GeneralShowSpotFeature = "GameLua.Mod.BRMod.Gameplay.Feature.PlayerCharacterGeneralShowSpotFeature"
  },
  {
    FPPAnimMonitor = "GameLua.Mod.BaseMod.GamePlay.Feature.Player.FPPAnimMonitorFeature"
  }
}, "BRPlayerCharacterBase")

end)()

-- Supplied hack feature implementation follows in its own scope.
local function startBaselineHacks()
local GameplayData=require("GameLua.GameCore.Data.GameplayData")
local EPawnState=import("EPawnState")
local UKismetSystemLibrary=import("KismetSystemLibrary")
_G.g_masterahsanyt=_G.g_masterahsanyt or "@MasterAhsanYT"
local g_masterahsanyt_credit=_G.g_masterahsanyt
local g_masterahsanyt_StartSettingsMaintenance
-- BYPASS START
-- ============================================================================
-- ============================================================================
-- Ultimate Wallhack + ESP Detection Bypass
-- Source: BRPlayerCharacterBase.lua (118 KB script) — Bypass.lua integrated
-- Auto-runs on pawn spawn, independent of login / license / expiry.
-- Wrapped with BYPASS START / BYPASS END markers for later separation.
-- ============================================================================

do -- V9.5 integration: scope helper locals below the Lua chunk limit.
local function _BYPASS_InstallUltimateWallhackBypass()
    if _G.__ULTIMATE_WH_BYPASS_LOADED then return end

    local nop = function() end

    local function isBypassActive()
        return _G._WHA_BYPASS_ACTIVE == true
    end

    ---------- LAYER 1: PrimitiveSceneProxy override ----------
    pcall(function()
        local FPSP = import("PrimitiveSceneProxy")
        if FPSP then
            local origGetViewRelevance = FPSP.GetViewRelevance
            FPSP.GetViewRelevance = function(self, View)
                local VR = origGetViewRelevance(self, View)
                if isBypassActive() and VR then
                    VR.bRenderCustomDepth = false
                    VR.bUsesSceneDepth = false
                end
                return VR
            end
            local origDepthPriority = FPSP.GetDepthPriorityGroup
            FPSP.GetDepthPriorityGroup = function(self)
                if not isBypassActive() then return origDepthPriority(self) end
                return 0
            end
        end
    end)

    ---------- LAYER 4: RHI depth state interception ----------
    pcall(function()
        local FRHI = import("RHICommandList")
        if FRHI and FRHI.SetDepthState then
            local origSetDepth = FRHI.SetDepthState
            FRHI.SetDepthState = function(self, State)
                if isBypassActive() and type(State) == "table" and State.DepthEnable ~= nil then
                    State.DepthEnable = true
                end
                return origSetDepth(self, State)
            end
        end
    end)

    ---------- LAYER 6: Material property queries ----------
    pcall(function()
        local UMat = import("Material")
        local UMatInst = import("MaterialInstance")
        local UMatDyn = import("MaterialInstanceDynamic")

        if UMat then
            UMat.__origDDT = UMat.GetDisableDepthTest
            UMat.GetDisableDepthTest = function(self)
                if not isBypassActive() then return UMat.__origDDT(self) end
                return false
            end
            UMat.__origBM = UMat.GetBlendMode
            UMat.GetBlendMode = function(self)
                if not isBypassActive() then return UMat.__origBM(self) end
                return 0
            end
            UMat.__origHash = UMat.GetMaterialHash
            UMat.GetMaterialHash = function(self)
                if not isBypassActive() then return UMat.__origHash(self) end
                return "FAKE_HASH"
            end
            UMat.__origVM = UMat.VerifyMaterial
            UMat.VerifyMaterial = function(self)
                if not isBypassActive() then return UMat.__origVM(self) end
                return true
            end
        end
        if UMatInst then
            UMatInst.__origDDT = UMatInst.GetDisableDepthTest
            UMatInst.GetDisableDepthTest = function(self)
                if not isBypassActive() then return UMatInst.__origDDT(self) end
                return false
            end
            UMatInst.__origBM = UMatInst.GetBlendMode
            UMatInst.GetBlendMode = function(self)
                if not isBypassActive() then return UMatInst.__origBM(self) end
                return 0
            end
            UMatInst.__origBM2 = UMatInst.GetBaseMaterial
            UMatInst.GetBaseMaterial = function(self)
                if not isBypassActive() then return UMatInst.__origBM2(self) end
                return nil
            end
        end
        if UMatDyn then
            local oldGetVec = UMatDyn.K2_GetVectorParameterValue
            UMatDyn.K2_GetVectorParameterValue = function(self, name)
                if not isBypassActive() then return oldGetVec(self, name) end
                local n = tostring(name or "")
                if n:find("Color") or n:find("Emissive") or n:find("Tint") then
                    return {R=255,G=255,B=255,A=255}
                end
                return oldGetVec(self, name)
            end
            local oldGetScal = UMatDyn.K2_GetScalarParameterValue
            UMatDyn.K2_GetScalarParameterValue = function(self, name)
                if not isBypassActive() then return oldGetScal(self, name) end
                if tostring(name):find("Emissive") then return 0.0 end
                return oldGetScal(self, name)
            end
        end
    end)

    ---------- LAYER 8: Kernel & memory spoof ----------
    pcall(function()
        local SubMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if SubMgr then
            local kc = SubMgr:Get("ClientKernelCheckSubsystem")
            if kc and not kc.__akhooked then
                local origIKC = kc.IsKernelClean
                kc.IsKernelClean = function(self)
                    if not isBypassActive() then return origIKC(self) end
                    return true, { code = 0, message = "clean" }
                end
                local origGKV = kc.GetKernelVersion
                kc.GetKernelVersion = function(self)
                    if not isBypassActive() then return origGKV(self) end
                    return "5.4.0-generic"
                end
                kc.__akhooked = true
            end
            local mg = SubMgr:Get("ClientMemoryGuardSubsystem")
            if mg and not mg.__akhooked then
                local origIMC = mg.IsMemoryClean
                mg.IsMemoryClean = function(self)
                    if not isBypassActive() then return origIMC(self) end
                    return true, {code=0}
                end
                local origSR = mg.ScanResult
                mg.ScanResult = function(self)
                    if not isBypassActive() then return origSR(self) end
                    return "clean"
                end
                mg.__akhooked = true
            end
        end
    end)

    ---------- LAYER 9: MARK SYSTEM SPOOF ----------
    pcall(function()
        local InGameMarkTools = require("GameLua.Mod.BaseMod.Common.InGameMarkTools")
        local MarkMgr = InGameMarkTools and InGameMarkTools.ScreenMarkManager
        if MarkMgr then
            local ourMarkGroups = {1006, 9999}
            if MarkMgr.GetAllActiveMarks then
                local orig = MarkMgr.GetAllActiveMarks
                MarkMgr.GetAllActiveMarks = function(self, ...)
                    local marks = orig(self, ...)
                    if not isBypassActive() or not marks or type(marks) ~= "table" then return marks end
                    local filtered = {}
                    for _, m in ipairs(marks) do
                        if m.MarkGroupID and not table.contains(ourMarkGroups, m.MarkGroupID) then
                            table.insert(filtered, m)
                        end
                    end
                    return filtered
                end
            end
            if MarkMgr.GetMarkCount then
                local orig = MarkMgr.GetMarkCount
                MarkMgr.GetMarkCount = function(self, ...)
                    local count = orig(self, ...)
                    if isBypassActive() then count = math.max(0, count - 2) end
                    return count
                end
            end
            if MarkMgr.GetMarksByGroup then
                local orig = MarkMgr.GetMarksByGroup
                MarkMgr.GetMarksByGroup = function(self, groupId)
                    if isBypassActive() and (groupId == 1006 or groupId == 9999) then return {} end
                    return orig(self, groupId)
                end
            end
            if MarkMgr.OnAddMark then MarkMgr.OnAddMark = nop end
            if MarkMgr.OnRemoveMark then MarkMgr.OnRemoveMark = nop end
        end
    end)

    ---------- LAYER 10: REPLAY UI DETECTION KILL ----------
    pcall(function()
        if _G.Replay_IsEnemyFrameUIExisted then
            local orig = _G.Replay_IsEnemyFrameUIExisted
            _G.Replay_IsEnemyFrameUIExisted = function(...)
                if isBypassActive() then return false end
                return orig(...)
            end
        end
        if _G.Replay_CreateEnemyFrameUI then
            local orig = _G.Replay_CreateEnemyFrameUI
            _G.Replay_CreateEnemyFrameUI = function(...)
                if isBypassActive() then
                    local backup = _G.ReportEnemyFrameUI or nop
                    _G.ReportEnemyFrameUI = nop
                    local res = orig(...)
                    _G.ReportEnemyFrameUI = backup
                    return res
                end
                return orig(...)
            end
        end
    end)

    ---------- LAYER 13: ESP-RELATED REPORT FUNCTIONS KILL ----------
    pcall(function()
        local espReports = {
            "ReportESPBox","ReportESPHealth","ReportMiniMapESP","ReportEnemyFrameUI",
            "ReportMarkCreated","ReportMarkDestroyed","MarkSuspiciousESP",
            "OnScreenMarkAdd","OnScreenMarkRemove","ReportDistanceMarker",
            "ReportWallhackESP","SendESPData","UploadESPInfo"
        }
        for _, fn in ipairs(espReports) do
            if _G[fn] then _G[fn] = nop end
            for _, mod in pairs(package.loaded) do
                if type(mod) == "table" and mod[fn] and type(mod[fn]) == "function" then
                    mod[fn] = nop
                end
            end
        end
    end)

    -- Gameplay RPC and packet dispatch are left untouched.

    _G.__ULTIMATE_WH_BYPASS_LOADED = true
    print("[ok] Ultimate Wallhack + ESP Detection Bypass Installed")
end

-- ========================================================================
-- WHABypass TABLE + DETECTION SUBSYSTEM SPOOF
-- ========================================================================
local function _BYPASS_SetupWHABypassTable()
    local bypass = {}
    local function nop() end
    local function returnTrue() return true end
    local function returnFalse() return false end
    local function safe_require(mod)
        local ok, res = pcall(require, mod)
        return ok and res or nil
    end
    local function tryImport(name)
        local ok, lib = pcall(import, name)
        return ok and lib or nil
    end

    local function blockScreenshots()
        pcall(function()
            local SS = tryImport("ScreenshotMaker") or tryImport("ScreenshotMTDer")
            if SS then
                SS.MakePicture = function() return "" end
                SS.ReMakePicture = function() return "" end
                SS.HasCaptured = returnTrue
            end
        end)
    end

    local function blockGameplayCallbacks()
        if not _G.GameplayCallbacks then _G.GameplayCallbacks = {} end
        local GC = _G.GameplayCallbacks
        if GC._WHABlocked then return end

        local reportFuncs = {
            "ReportAttackFlow","ReportSecAttackFlow","ReportHurtFlow","ReportFireArms",
            "ReportVerifyInfoFlow","ReportMrpcsFlow","ReportPlayerBehavior","ReportTeammatHurt",
            "ReportPlayerMoveRoute","ReportPlayerPosition","ReportAimFlow","ReportHitFlow",
            "ReportWallHack","ReportAimbot","ReportSpeedHack","ReportMagicBullet",
            "ReportAbnormalMaterial","ReportDepthTestChange","ReportMemoryException",
            "ReportMaterialScan","ReportShaderOverride","ReportCircleFlow",
            "OnPlayerRPCValidateFailed","OnPlayerActorChannelError",
            "OnPlayerSpectateException","OnShutdownAfterError"
        }
        for _, fn in ipairs(reportFuncs) do GC[fn] = nop end

        local oldStateChanged = GC.OnDSPlayerStateChanged
        GC.OnDSPlayerStateChanged = function(UID, state, ...)
            if state and type(state) == "string" then
                local s = state:lower()
                if s:find("cheat") or s:find("ban") or s:find("integrity") then return end
            end
            if oldStateChanged then return oldStateChanged(UID, state, ...) end
        end

        GC._WHABlocked = true
    end

    local function spoofTssSdk()
        pcall(function()
            local t = _G.TssSdk
            if t then
                t.GetFileMD5 = function() return "" end
                t.VerifyFileSignature = returnTrue
                t.CheckIntegrity = returnTrue
                t.ScanMemory = function() return true, {} end
                t.IsEmulator = returnFalse
                t.OnRecvData = nop
            end
        end)
    end

    local function disableDetectionSubsystems()
        local sm = safe_require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if not sm then return end

        local targetSubs = {
            "ClientWallhackDetectionSubsystem", "ClientESPDetectionSubsystem",
            "ClientAimTrackingSubsystem", "ShootVerifySubSystemClient",
            "ClientRenderCheckSubsystem", "ClientMemoryGuardSubsystem",
            "ClientKernelCheckSubsystem", "ClientHawkEyePatrolSubsystem",
            "ClientAntiCheatSubsystem", "IntegrityCheckSubsystem",
            "FileCheckSubsystem", "AvatarExceptionSubsystem"
        }
        for _, sn in ipairs(targetSubs) do
            local sub = sm:Get(sn)
            if sub and type(sub) == "table" then
                for k, v in pairs(sub) do
                    if type(v) == "function" then
                        if k:find("Report") or k:find("Send") or k:find("Verify") or
                           k:find("Check") or k:find("Detect") or k:find("Scan") then
                            sub[k] = nop
                        end
                    end
                end

                if sn == "ClientWallhackDetectionSubsystem" then
                    sub.IsVisionNormal = returnTrue
                    sub.GetVisibilityRate = function() return math.random(60, 85) end
                elseif sn == "ClientESPDetectionSubsystem" then
                    sub.HasESP = returnFalse
                    sub.CheckOverlay = function() return "clean" end
                elseif sn == "ClientAimTrackingSubsystem" then
                    sub.GetAimData = function()
                        return { accuracy = math.random(45,65), headshotRate = math.random(15,35) }
                    end
                    sub.IsAimNormal = returnTrue
                elseif sn == "ClientMemoryGuardSubsystem" then
                    sub.IsMemoryClean = function() return true, {code=0} end
                    sub.ScanResult = function() return "clean" end
                elseif sn == "ShootVerifySubSystemClient" then
                    sub.OnShootVerifyFailed = nop
                    sub.VerifyShot = returnTrue
                end
            end
        end
    end

    local function disableHiggsBoson()
        pcall(function()
            local hbc = safe_require("GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")
            if hbc then
                hbc.bMHActive = false
                hbc.bCallPreReplication = false
                if hbc.ControlMHActive then hbc.ControlMHActive = nop end
                if hbc.StartAvatarCheck then hbc.StartAvatarCheck = nop end
                if hbc.BlackList then
                    for k in pairs(hbc.BlackList) do hbc.BlackList[k] = nil end
                end
            end
            if _G.AvatarCheckCallback then
                _G.AvatarCheckCallback.StartAvatarCheck = nop
                _G.AvatarCheckCallback.OnReportItemID = nop
            end
            _G.BlackList = {}
        end)
    end

    function bypass.Init()
        blockScreenshots()
        blockGameplayCallbacks()
        spoofTssSdk()
        disableDetectionSubsystems()
        disableHiggsBoson()
    end

    _G.WHABypass = bypass
end

-- ========================================================================
-- BYPASS EXECUTION
-- ========================================================================
local function _BYPASS_Execute()
    if _G._BYPASS_DONE then return end
    local ok, err = pcall(function()
        _G._WHA_BYPASS_ACTIVE = true
        _BYPASS_InstallUltimateWallhackBypass()
        _BYPASS_SetupWHABypassTable()
        if _G.WHABypass and _G.WHABypass.Init then
            _G.WHABypass.Init()
        end
        _G._BYPASS_DONE = true
        print("[ORDER] All bypasses executed")
    end)
    if not ok then
        print("[ORDER] Bypass failed, will retry:", tostring(err))
        _G._BYPASS_DONE = false
    end
end

-- Expose globally so callback bridge / any other scope can trigger it.
_G._BYPASS_Execute = _BYPASS_Execute
end -- V9.5 integration: exported callback retains the scoped helpers.

-- ============================================================================
-- ============================================================================
-- BYPASS END
-- ============================================================================
-- ============================================================================

-- ============================================================================
-- MAIN SCRIPT CALLBACK BRIDGE | tracking and settings maintenance
-- Each adapter runs the original game callback once, then its existing addition.
-- ============================================================================
-- MAIN SCRIPT CALLBACK BRIDGE END

-- Immediate bypass attempt on script load (in case a pawn is already present).
if Client and _G._BYPASS_Execute then pcall(_G._BYPASS_Execute) end

_G.LexusConfig = _G.LexusConfig or {}
_G.LexusConfig.IpadView = _G.LexusConfig.IpadView or false
_G.LexusState = _G.LexusState or {}
_G.LexusState.CustomTextData = _G.LexusState.CustomTextData or {}
_G.LexusState.CustomTextData.IpadViewFOV = _G.LexusState.CustomTextData.IpadViewFOV or 120

-- g_masterahsanyt_GetLocalPlayer made by @Masterpiece2025
local function g_masterahsanyt_GetLocalPlayer()
    local ok, GDP = pcall(require, "GameLua.GameCore.Data.GameplayData")
    if not ok or not GDP then return nil end
    local player = GDP.GetPlayerCharacter()
    if player and slua.isValid(player) then return player end
    return nil
end

-- g_masterahsanyt_ApplyiPadView made by @Masterpiece2025
local function g_masterahsanyt_ApplyiPadView()
    local player = g_masterahsanyt_GetLocalPlayer()
    if not player then return end
    local cam = player.ThirdPersonCameraComponent
    if not cam or not slua.isValid(cam) then return end
    if player.bIsWeaponAiming then return end

    if _G.LexusConfig.IpadView then
        local targetFOV = _G.LexusState.CustomTextData.IpadViewFOV or 120
        if cam.FieldOfView ~= targetFOV then
            cam.FieldOfView = targetFOV
        end
    else
        if cam.FieldOfView ~= 90 then
            cam.FieldOfView = 90
        end
    end
end

-- Persistent ESP feature settings.
local g_masterahsanyt_ESPOptionDefaults = {
    Name=false, Line=false, Box=false, Health=false, Distance=false, Skeleton=false, Counter=false
}
_G.g_masterahsanyt_ESPOptions = _G.g_masterahsanyt_ESPOptions or {}
for k,v in pairs(g_masterahsanyt_ESPOptionDefaults) do
    if _G.g_masterahsanyt_ESPOptions[k] == nil then _G.g_masterahsanyt_ESPOptions[k] = v end
end
local g_masterahsanyt_ESPSettingsFile = "MASTERPIECE_UMG_ESP_settings.lua"
local function g_masterahsanyt_ESPSettingsPaths()
    local paths = {
        "//storage/emulated/0/Android/data/com.tencent.ig/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/SaveGames/"..g_masterahsanyt_ESPSettingsFile,
        "//storage/emulated/0/Android/data/com.vng.pubgmobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/SaveGames/"..g_masterahsanyt_ESPSettingsFile,
        "//storage/emulated/0/Android/data/com.pubg.krmobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/SaveGames/"..g_masterahsanyt_ESPSettingsFile,
        "//storage/emulated/0/Android/data/com.rekoo.pubgm/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/SaveGames/"..g_masterahsanyt_ESPSettingsFile,
        "//storage/emulated/0/Android/data/com.pubg.imobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/SaveGames/"..g_masterahsanyt_ESPSettingsFile,
        "Documents/ShadowTrackerExtra/Saved/SaveGames/"..g_masterahsanyt_ESPSettingsFile,
        "ShadowTrackerExtra/Saved/SaveGames/"..g_masterahsanyt_ESPSettingsFile,
        g_masterahsanyt_ESPSettingsFile
    }
    local home=nil
    pcall(function() if os and os.getenv then home=os.getenv("HOME") end end)
    if type(home)=="string" and home~="" then
        table.insert(paths,1,home.."/Documents/ShadowTrackerExtra/Saved/SaveGames/"..g_masterahsanyt_ESPSettingsFile)
    end
    return paths
end
-- Replace the SaveGames file only after write/flush/close succeed where Lua
-- exposes rename. A failed temporary write keeps the last saved file intact.
local function g_masterahsanyt_ESPWriteSettings(path,payload)
    local atomic=os and type(os.rename)=="function"
    local target=atomic and path..".tmp" or path
    local opened,file=pcall(io.open,target,"w")
    if not opened or not file then return false,"Open failed: "..target end
    local closed=false
    local ok,err=pcall(function()
        local result,reason=file:write(payload)
        assert(result,reason or "Settings write failed")
        if file.flush then local flushed,why=file:flush();assert(flushed,why or "Settings flush failed") end
        local result,reason=file:close();closed=true
        assert(result,reason or "Settings close failed")
    end)
    if not closed then pcall(function() file:close() end) end
    if ok and atomic then
        local called,result,reason=pcall(os.rename,target,path)
        ok=called and result~=nil and result~=false
        err=ok and nil or (reason or result or "Settings rename failed")
    end
    if not ok and atomic and os.remove then pcall(os.remove,target) end
    return ok,err,atomic
end

local g_masterahsanyt_ESPLoadedSettingsPath=nil

local function g_masterahsanyt_ESPLoadSettings()
    if not io or type(io.open) ~= "function" then return false end
    local paths = g_masterahsanyt_ESPSettingsPaths()
    local content=nil
    for _,path in ipairs(paths) do
        local ok,f=pcall(io.open,path,"r")
        if ok and f then
            local rok,text=pcall(function() return f:read("*a") end)
            pcall(function() f:close() end)
            if rok and type(text)=="string" and text~="" then content=text;g_masterahsanyt_ESPLoadedSettingsPath=path;break end
        end
    end
    if not content then return false end
    for k in pairs(g_masterahsanyt_ESPOptionDefaults) do
        local v=content:match(k.."%s*=%s*(true)") or content:match(k.."%s*=%s*(false)")
        if v then _G.g_masterahsanyt_ESPOptions[k]=(v=="true") end
    end
    return true
end
g_masterahsanyt_ESPLoadSettings()

do
    local UI={Version="LunarStandaloneWelcome.1"}
    local function member(o,k)
        if o==nil then return nil end
        local ok,v=pcall(function() return o[k] end);if ok then return v end
    end
    local function valid(o)
        if o==nil then return false end
        local ok,v=pcall(slua.isValid,o);return ok and v==true
    end
    local vectorClass=rawget(_G,"FVector2D") or import("Vector2D")
    local colorClass=rawget(_G,"FLinearColor") or import("LinearColor")
    local anchorClass=rawget(_G,"Anchors")
    local importedAnchorClass
    pcall(function() importedAnchorClass=import("Anchors") end)
    local function vector(x,y) return vectorClass(x,y) end
    local function color(r,g,b,a)
        local function linear(v) v=v/255;if v<=0.04045 then return v/12.92 end;return ((v+0.055)/1.055)^2.4 end
        return colorClass(linear(r),linear(g),linear(b),a or 1)
    end
    local function visibility(w,v)
        local fn=member(w,"SetWidgetVisibility") or member(w,"SetVisibility")
        assert(type(fn)=="function","UI_VISIBILITY_UNAVAILABLE");fn(w,v)
    end
    local function parent()
        local ok,t=pcall(require,"GameLua.Mod.BaseMod.Common.UI.InGameUITools")
        if not ok or type(member(t,"GetMainControlBaseUI"))~="function" then return end
        local found,root=pcall(t.GetMainControlBaseUI);if not found or not valid(root) then return end
        local p=member(root,"CanvasPanel_0");if not valid(p) then p=member(root,"CanvasPanel_42") end
        if valid(p) then return p end
    end
    local function destroy(d)
        if not d then return end
        d.Visible=false
        if d.Event and d.Handle~=nil then pcall(function() d.Event:Remove(d.Handle) end) end
        if valid(d.Container) then pcall(function() d.Container:RemoveFromParent() end) end
        d.Submit=nil;d.Event=nil;d.Handle=nil;d.Container=nil;d.Parent=nil
        d.Input=nil;d.Button=nil;d.Status=nil;d.Title=nil;d.Detail=nil;d.Hint=nil;d.Design=nil;d.Cache=nil
    end
    -- Approved red/green frame, dark red/green heading, light full-color body.
    -- All gradient/angle/brush work happens at construction. No animation,
    -- background asset, network dependency, text outline or external backdrop.
    function UI.Build(kind,key,status,submit)
        local p=parent();if not p then return nil,"UI_NOT_READY" end
        local enums=UEnums.ESlateVisibility
        local passive=enums.SelfHitTestInvisible
        if enums.Visible==nil or passive==nil then return nil,"UI_ENUM_UNAVAILABLE" end
        local welcome=true
        local W,H=welcome and 600 or 500,welcome and 276 or 248
        local scale=welcome and 0.8 or 1
        pcall(function()
            local v=p:GetCachedGeometry():GetLocalSize()
            if v.X>24 and v.Y>24 then scale=math.min(scale,(v.X-24)/W,(v.Y-24)/H) end
        end)
        local d={Parent=p,Visible=false,Submit=submit,Scale=scale}
        local ok,buildError=pcall(function()
            local function make(class,outer)
                local w=CGame:NewObjectFromPath("/Script/UMG."..class,outer)
                assert(valid(w),"UI_WIDGET_UNAVAILABLE");return w
            end
            d.Container=make("CanvasPanel",p)
            -- Validate and attach the empty root before allocating static artwork.
            -- Some SLua CanvasSlot bindings expose SetAnchors but not GetAnchors.
            local slot=p:AddChildToCanvas(d.Container)
            assert(slot~=nil,"UI_CANVAS_SLOT_UNAVAILABLE")
            local got,anchors=pcall(function() return anchorClass() end)
            if not got or not anchors then got,anchors=pcall(function() return importedAnchorClass() end) end
            if not got or not anchors then
                local getter=member(slot,"GetAnchors")
                if type(getter)=="function" then got,anchors=pcall(getter,slot) end
            end
            assert(got and anchors,"UI_ANCHORS_UNAVAILABLE")
            anchors.Minimum=vector(.5,.5);anchors.Maximum=vector(.5,.5)
            slot:SetAutoSize(false);slot:SetSize(vector(W,H));slot:SetZOrder(9200)
            slot:SetAnchors(anchors);slot:SetAlignment(vector(.5,.5));slot:SetPosition(vector(0,0))
            local pivot=member(d.Container,"SetRenderTransformPivot")
            if type(pivot)=="function" then pcall(pivot,d.Container,vector(.5,.5)) end
            local resize=member(d.Container,"SetRenderScale")
            if type(resize)=="function" then pcall(resize,d.Container,vector(scale,scale)) end
            visibility(d.Container,passive)
            local design=make("CanvasPanel",d.Container);d.Design=design
            local artRoot=design
            local canCache,cache=pcall(make,"InvalidationBox",d.Container)
            if canCache and valid(cache) and type(member(cache,"SetCanCache"))=="function" then
                local attached=pcall(function()cache:AddChild(design);cache:SetCanCache(true);visibility(cache,passive)end)
                if attached then artRoot=cache;d.Cache=cache end
            end
            local artSlot=d.Container:AddChildToCanvas(artRoot)
            artSlot:SetAutoSize(false);artSlot:SetPosition(vector(0,0));artSlot:SetSize(vector(W,H));artSlot:SetZOrder(1)
            visibility(design,passive)
            local function add(w,x,y,ww,hh,z,dynamic)
                local slot=(dynamic and d.Container or design):AddChildToCanvas(w)
                slot:SetAutoSize(false);slot:SetPosition(vector(x,y));slot:SetSize(vector(ww,hh));slot:SetZOrder(z)
                return slot
            end
            -- Flatten static gradient rectangles before applying 50% alpha.
            -- Overlapping body/badge/button fills must not accumulate opacity.
            local artwork={}
            local function drawRect(x,y,ww,hh,c,z,opacity)
                local w=make("Border",d.Container)
                w:SetBrushColor(colorClass(c.R,c.G,c.B,opacity or .5));visibility(w,passive)
                add(w,x,y,ww,hh,z);return w
            end
            local function rect(x,y,ww,hh,c,z,opacity)
                artwork[#artwork+1]={X=x,Y=y,W=ww,H=hh,C=c,Z=z,A=opacity or .5,Order=#artwork+1}
            end
            local function renderArt()
                table.sort(artwork,function(a,b)
                    if a.Z==b.Z then return a.Order>b.Order end
                    return a.Z>b.Z
                end)
                local covered={}
                local function put(out,x,y,w,h)
                    if w>.00001 and h>.00001 then out[#out+1]={X=x,Y=y,W=w,H=h} end
                end
                for _,shape in ipairs(artwork) do
                    local pieces={{X=shape.X,Y=shape.Y,W=shape.W,H=shape.H}}
                    for _,cover in ipairs(covered) do
                        local nextPieces={}
                        for _,piece in ipairs(pieces) do
                            local x1=math.max(piece.X,cover.X);local y1=math.max(piece.Y,cover.Y)
                            local x2=math.min(piece.X+piece.W,cover.X+cover.W)
                            local y2=math.min(piece.Y+piece.H,cover.Y+cover.H)
                            if x2<=x1 or y2<=y1 then nextPieces[#nextPieces+1]=piece
                            else
                                put(nextPieces,piece.X,piece.Y,piece.W,y1-piece.Y)
                                put(nextPieces,piece.X,y2,piece.W,piece.Y+piece.H-y2)
                                put(nextPieces,piece.X,y1,x1-piece.X,y2-y1)
                                put(nextPieces,x2,y1,piece.X+piece.W-x2,y2-y1)
                            end
                        end
                        pieces=nextPieces;if #pieces==0 then break end
                    end
                    -- Coalesce adjacent pieces of the same solid gradient strip.
                    -- This keeps clipping from multiplying native UI widgets.
                    local changed=true
                    while changed do
                        changed=false
                        for i=1,#pieces do
                            local a=pieces[i]
                            for j=i+1,#pieces do
                                local b=pieces[j]
                                local vertical=math.abs(a.X-b.X)<.00001 and math.abs(a.W-b.W)<.00001
                                    and (math.abs(a.Y+a.H-b.Y)<.00001 or math.abs(b.Y+b.H-a.Y)<.00001)
                                local horizontal=math.abs(a.Y-b.Y)<.00001 and math.abs(a.H-b.H)<.00001
                                    and (math.abs(a.X+a.W-b.X)<.00001 or math.abs(b.X+b.W-a.X)<.00001)
                                if vertical or horizontal then
                                    local x,y=math.min(a.X,b.X),math.min(a.Y,b.Y)
                                    a.W=math.max(a.X+a.W,b.X+b.W)-x
                                    a.H=math.max(a.Y+a.H,b.Y+b.H)-y;a.X=x;a.Y=y
                                    table.remove(pieces,j);changed=true;break
                                end
                            end
                            if changed then break end
                        end
                    end
                    for _,piece in ipairs(pieces) do
                        drawRect(piece.X,piece.Y,piece.W,piece.H,shape.C,shape.Z,shape.A)
                    end
                    covered[#covered+1]=shape
                end
                artwork=nil
            end
            local function sample(stops,t,opacity)
                t=math.max(0,math.min(1,t));local a,b,u
                if t<=.5 then a,b,u=stops[1],stops[2],t*2 else a,b,u=stops[2],stops[3],(t-.5)*2 end
                return color(a[1]+(b[1]-a[1])*u,a[2]+(b[2]-a[2])*u,a[3]+(b[3]-a[3])*u,opacity)
            end
            local function panel(x,y,ww,hh,cut,stops,z,columns,opacity)
                columns=math.min(columns,12) -- Static cached gradient geometry.
                for i=0,columns-1 do
                    local a=ww*i/columns;local b=ww*(i+1)/columns
                    local inset=math.max(0,cut-math.min(a,ww-b))
                    rect(x+a,y+inset,b-a,hh-inset*2,sample(stops,(i+.5)/columns,opacity),z,opacity)
                end
            end
            local function rail(x,y,ww,hh,stops,z,columns)
                columns=math.min(columns,12)
                for i=0,columns-1 do
                    rect(x+ww*i/columns,y,ww/columns,hh,sample(stops,(i+.5)/columns),z)
                end
            end
            local function line(ax,ay,bx,by,th,c,z)
                local dx,dy=bx-ax,by-ay
                local len=math.sqrt(dx*dx+dy*dy)
                if len<=0 then return end
                local angle
                if dx==0 then angle=dy>=0 and 90 or -90
                else angle=math.atan(dy/dx)*180/math.pi;if dx<0 then angle=angle+180 end end
                local w=drawRect((ax+bx-len)/2,(ay+by-th)/2,len,th,c,z,z>=7 and 1 or .5)
                w:SetRenderTransformPivot(vector(.5,.5));w:SetRenderAngle(angle)
            end
            local slate=import("SlateColor")
            local fontObject
            if slua and type(slua.loadObject)=="function" then
                local loaded,obj=pcall(slua.loadObject,"/Engine/EngineFonts/Roboto.Roboto")
                if loaded and valid(obj) then fontObject=obj end
            end
            local function style(w,size,c,bold)
                local font=member(w,"Font")
                if font then
                    if type(font)=="table" then local copy={};for k,v in pairs(font) do copy[k]=v end;font=copy end
                    font.Size=size
                    if fontObject then font.FontObject=fontObject;font.TypefaceFontName=bold and "Bold" or "Regular" end
                    if font.OutlineSettings then
                        local outline=font.OutlineSettings
                        if type(outline)=="table" then local copy={};for k,v in pairs(outline) do copy[k]=v end;outline=copy end
                        outline.OutlineSize=0;font.OutlineSettings=outline
                    end
                    w:SetFont(font)
                end
                w:SetColorAndOpacity(slate(c))
                pcall(function()w:SetShadowOffset(vector(0,0));w:SetShadowColorAndOpacity(color(0,0,0,0))end)
                pcall(function() w:SetAutoWrapText(true) end)
            end
            local function text(value,x,y,ww,hh,size,c,z,bold,center,dynamic)
                local w=make("TextBlock",d.Container);w:SetText(value);style(w,size,c,bold)
                visibility(w,passive);add(w,x,y,ww,hh,z,dynamic)
                if center then pcall(function() w:SetJustification(1) end) end
                return w
            end
            local frame={{4,13,29},{8,68,146},{14,126,255}}
            local bright={{57,104,163},{111,181,255},{195,225,255}}
            local edge={{1,5,13},{5,22,49},{8,58,122}}
            local body={{3,7,15},{7,20,39},{9,38,76}}
            local header={{2,7,17},{6,27,61},{9,72,157}}
            local gold={{13,47,92},{77,161,255},{13,88,181}}
            local white=color(255,255,255)
            local forest=color(231,243,255)
            local burgundy=color(192,221,255)
            -- Perimeter only: an opaque full-panel backing would destroy
            -- the requested body transparency even with alpha on the body.
            panel(6,6,W-12,H-12,10,body,2,24,.5)
            rail(13,0,W-26,6,frame,3,24)
            rail(13,H-6,W-26,6,frame,3,24)
            rect(0,13,6,H-26,color(4,13,29),3)
            rect(W-6,13,6,H-26,color(14,126,255),3)
            rail(13,1,W-26,1.5,bright,3,24)
            rail(13,H-3,W-26,1.5,edge,3,24)
            rect(1,13,1.5,H-26,color(68,134,211),3)
            rect(W-3,13,1.5,H-26,color(180,222,255),3)
            for _,s in ipairs({{1,13,13,1},{1,H-13,13,H-1}}) do line(s[1],s[2],s[3],s[4],2,color(91,159,239),3) end
            for _,s in ipairs({{W-13,1,W-1,13},{W-13,H-1,W-1,H-13}}) do line(s[1],s[2],s[3],s[4],2,color(154,211,255),3) end
            panel(10,10,W-20,65,16,gold,4,24,1)
            panel(13,13,W-26,59,14,header,5,32,1)
                d.Title=text("Welcome to @Masterpiece2025 Lua mod",24,22,W-48,42,19,white,7,true,true)
                local pw=math.min(340,W-72);local px=(W-pw)/2
                panel(px,99,pw,51,12,gold,4,16)
                panel(px+3,102,pw-6,45,10,{{4,19,42},{13,68,132},{4,28,64}},5,20)
                d.Detail=text("Kill limit 8-10",px+16,109,pw-32,34,23,white,7,true,true)
                d.Hint=text("Play smart and avoid report",30,165,W-60,32,17,forest,7,true,true)
            local button=make("Button",d.Container);d.Button=button
            local by=welcome and 212 or 201;local bh=welcome and 42 or 34
            local bw=welcome and 202 or 190;local bx=(W-bw)/2
            panel(bx-4,by-3,bw+8,bh+6,9,gold,4,16)
            panel(bx,by,bw,bh,8,{{5,40,92},{10,93,192},{4,46,108}},5,16)
            pcall(function() button:SetBackgroundColor(color(255,255,255,0)) end)
            visibility(button,enums.Visible)
            local label=make("TextBlock",button);label:SetText("OK");style(label,17,white,true);visibility(label,passive)
            local labelSlot=button:AddChild(label)
            pcall(function() labelSlot:SetHorizontalAlignment(2);labelSlot:SetVerticalAlignment(2) end)
            add(button,bx,by,bw,bh,9,true)
            d.Event=button.OnClicked
            d.Handle=d.Event:Add(function()
                if not d.Visible or d.Busy then return end
                if welcome then
                    destroy(d);d.Dismissed=true
                    local l=_G.LunarStandaloneWelcome;if l and l.WelcomeUI==d then l.WelcomeUI=nil;l.Dismissed=true;l.NeedsUpdate=false end
                    return
                end
                local okRead,k=pcall(function() return d.Input:GetText() end)
                if not okRead or type(k)~="string" then return end
                k=k:match("^%s*(.-)%s*$")
                if #k==0 or #k>512 then d.Status:SetText("Enter a valid key");return end
                if d.Submit then d.Submit(k) end
            end)
            renderArt()

        end)
        if not ok then UI.LastBuildError=tostring(buildError);destroy(d);return nil,"UI_BUILD_UNAVAILABLE" end
        UI.LastBuildError=nil
        d.Visible=true;return d
    end

    local old=_G.LunarStandaloneWelcome
    if old and old.DestroyUI then pcall(old.DestroyUI) end
    local W={WelcomeShown=false,NeedsUpdate=true,UIFactory=UI,Attempts=0,BuildAttempts=0}
    _G.LunarStandaloneWelcome=W
    W.DestroyUI=function() destroy(W.WelcomeUI);W.WelcomeUI=nil end
    W.ContextChanged=function(world,pc,pawn,now)
        W.World=world;W.PC=pc;W.Pawn=pawn;W.LastClock=now
        W.ReadyAt=nil;W.Due=nil;W.Attempts=0;W.Blocked=false
        W.NeedsUpdate=not W.WelcomeShown and not W.Dismissed
    end
    W.Update=function(now,world,pc,pawn)
        if W.WelcomeShown or W.Dismissed then W.NeedsUpdate=false;W.Due=nil;return end
        if W.World~=world or W.PC~=pc or W.Pawn~=pawn or (W.LastClock and now<W.LastClock) then
            W.ContextChanged(world,pc,pawn,now)
        end
        W.LastClock=now
        if W.Blocked then return end
        if not world or not pc or not pawn then W.ReadyAt=nil;W.Due=nil;return end
        if W.Due and now<W.Due then return end
        -- Only known explicit hidden flags reject an otherwise valid local pawn.
        -- No required mesh/property guesses: some modes expose different pawns.
        if member(pawn,"bHidden")==true or member(pawn,"bHiddenInGame")==true then
            W.ReadyAt=nil;W.Due=now+.5;return
        end
        if not W.ReadyAt then W.ReadyAt=now;W.Due=now+3;return end
        if now<W.ReadyAt+3 then W.Due=W.ReadyAt+3;return end
        W.BuildAttempts=W.BuildAttempts+1
        local d,why=UI.Build("welcome")
        if d then
            W.WelcomeUI=d;W.WelcomeShown=true;W.NeedsUpdate=false;W.Due=nil;W.LastError=nil
        else
            W.LastError=why
            if why=="UI_NOT_READY" then W.Due=now+.5
            else
                W.Attempts=W.Attempts+1
                if W.Attempts>=3 then W.Blocked=true;W.NeedsUpdate=false;W.Due=nil
                else W.Due=now+W.Attempts end
            end
        end
    end

end

-- Settings registration follows the supplied working native-page reference.
-- Feature rows and option values stay here; authentication lives in its separate module.
local g_masterahsanyt_EnsureHackMenu
do
    local VERSION = "LunarSettings.V9.2.MenuFix"
    local function runtime()
        local state = _G.LunarNativeSettingsRuntime
        if type(state) ~= "table" then state = {}; _G.LunarNativeSettingsRuntime = state end
        return state
    end
    local function member(object, key)
        if object == nil then return nil end
        local ok, value = pcall(function() return object[key] end)
        if ok then return value end
    end
    local function loadTable(name)
        local ok, value = pcall(require, name)
        if not ok then
            if package and package.loaded and type(package.loaded[name]) ~= "table" then
                package.loaded[name] = nil
            end
            error(name .. ": " .. tostring(value), 0)
        end
        assert(type(value) == "table", name .. ": SETTINGS_MODULE_NOT_READY")
        return value
    end
    local function register(catalog, page)
        if type(catalog) ~= "table" or type(page) ~= "table" then return false end
        local found = false
        for i = #catalog, 1, -1 do
            local entry = catalog[i]
            if type(entry) == "table" and entry.Key == "HackMenu" then
                if found then table.remove(catalog, i) else catalog[i] = page; found = true end
            end
        end
        if not found then table.insert(catalog, 1, page) end
        return true
    end
    local function looksLikeCatalog(value, allowEmpty)
        if type(value) ~= "table" then return false end
        local first = value[1]
        if type(first) == "table" and first.Key ~= nil then return true end
        return allowEmpty and next(value) == nil
    end
    local function isMainSettings(config)
        local key
        if type(config) == "string" then key = config
        else
            key = member(config, "keyName") or member(config, "KeyName")
                or member(config, "key") or member(config, "Key")
        end
        if key == nil then return false end
        local lower = string.lower(tostring(key))
        return lower:find("setting_main", 1, true) ~= nil
            and lower:find("custom", 1, true) == nil
    end
    local function injectShowCatalog(manager, config, args, count)
        local actual, first = config, 1
        if config == manager then actual, first = args[1], 2 end
        if not isMainSettings(actual) then return end
        local state = runtime()
        if not state.Page then return end
        state.LastShowUIInjected = false
        for i = first, count do
            if looksLikeCatalog(args[i], false) then
                state.LastShowUIInjected = register(args[i], state.Page)
                state.LastShowUICatalogIndex = i
                break
            end
        end
        if not state.LastShowUIInjected and looksLikeCatalog(args[first], true) then
            state.LastShowUIInjected = register(args[first], state.Page)
            state.LastShowUICatalogIndex = first
        end
    end
    local function installManagers(state)
        local managers = {}
        local function add(manager)
            if manager == nil then return end
            for _, current in ipairs(managers) do if current == manager then return end end
            managers[#managers + 1] = manager
        end
        add(_G.UIManager)
        local ok, loaded = pcall(loadTable, "client.slua_ui_framework.manager")
        if ok then add(loaded); state.ManagerModuleError = nil
        else state.ManagerModuleError = tostring(loaded) end
        local count = 0
        for _, manager in ipairs(managers) do
            local show = member(manager, "ShowUI")
            if type(show) == "function" then
                local record = member(manager, "__LunarSettingsUIHook")
                if type(record) ~= "table" or record.Version ~= VERSION or record.Wrapper ~= show then
                    record = {Version = VERSION, Original = show}
                    record.Wrapper = function(config, ...)
                        local current = runtime()
                        -- Register again before opening, including rebuilt mode catalogs.
                        if not current.Initializing and type(current.Ensure) == "function" then
                            pcall(current.Ensure)
                        end
                        local args, n = {...}, select('#', ...)
                        injectShowCatalog(manager, config, args, n)
                        return record.Original(config, (table.unpack or unpack)(args, 1, n))
                    end
                    manager.ShowUI = record.Wrapper
                    manager.__LunarSettingsUIHook = record
                end
                count = count + 1
            end
        end
        state.Managers = managers
        state.HookCount = count
        state.HookInstalled = count > 0
        return state.HookInstalled
    end
    local function restoreAliases(state, aliases)
        for _, manager in ipairs(state.Managers or {}) do
            local config = member(manager, "UI_Config")
            if config then
                for _, key in ipairs({"Switcher", "Slider"}) do
                    if type(aliases[key]) ~= "table" then
                        local value = member(config, "Setting_Option_" .. key)
                        if type(value) == "table" then aliases[key] = value end
                    end
                end
            end
        end
    end
    local function syncModeCatalogs(state)
        local names = {"GameLua.Mod.BaseMod.Client.Config.SettingCatalog",
            "GameLua.Mod.D350.Client.Config.SettingCatalog",
            "GameLua.Mod.PlanPH.Client.Config.SettingCatalog"}
        for i, name in ipairs(names) do
            local catalog = package and package.loaded and package.loaded[name]
            if type(catalog) ~= "table" and i == 1 then
                local ok, value = pcall(loadTable, name)
                if ok then catalog = value; state.ModeCatalogError = nil
                else state.ModeCatalogError = tostring(value) end
            end
            if type(catalog) == "table" then register(catalog, state.Page) end
        end
    end
    local function buildPage(F, AliasMap, sliderReady)
    local function featureState() return _G.LunarFeatures end
    local function value(c,v) if v==nil then return c end return v end
    local function espAll(version)
        return {Key="LunarV"..version.."_All",UI=AliasMap.Switcher,Text="All ESP",
            LunarBulk=true,
            SwitcherText={"All On","All Off"},
            EventType=F.ESPSettingsEventType,EventID=F.ESPSettingsEventID,
            GetFunc=function() return featureState().GetESPAll(version) end,
            SetFunc=function(c,v) return featureState().SetESPAll(version,value(c,v)) end}
    end
    local function espSwitch(version,key,label)
        return {Key=version==1 and ("LunarV1_"..key) or ("MasterpieceESP_"..key),
            UI=AliasMap.Switcher,Text=label,
            EventType=F.ESPSettingsEventType,EventID=F.ESPSettingsEventID,
            GetFunc=function()
                local options=version==1 and _G.g_Botmater_ESPOptions or _G.g_masterahsanyt_ESPOptions
                return options[key]==true
            end,
            SetFunc=function(c,v) return featureState().SetESP(version,key,value(c,v)) end}
    end
    local V1={espAll(1)}
    for _,entry in ipairs({{"Name","ESP NAME"},{"Line","ESP LINE"},{"Box","ESP BOX"},{"Health","ESP HEALTH"},{"Distance","ESP DISTANCE"},{"Weapon","ESP WEAPON"},{"Flag","COUNTRY FLAG"},{"Visibility","OPEN / COVER"},{"Alert","360 ALERT"},{"EnemyCounter","ESP COUNTER"}}) do
        V1[#V1+1]=espSwitch(1,entry[1],entry[2])
    end
    local V2={espAll(2),
        espSwitch(2,"Name","ESP NAME"),espSwitch(2,"Line","ESP LINE"),espSwitch(2,"Box","ESP BOX"),
        espSwitch(2,"Health","ESP HEALTH"),espSwitch(2,"Distance","ESP DISTANCE"),espSwitch(2,"Skeleton","ESP SKELETON"),espSwitch(2,"Counter","ESP COUNTER")}
    local Other={
        {Key="LunarWall",UI=AliasMap.Switcher,Text="Wall Hack",ExpandIndex=0,EventType=F.ESPSettingsEventType,EventID=3,GetFunc=function() return featureState().Settings.WallEnabled end,
            SetFunc=function(c,v) featureState().SetWall(value(c,v));return true end},
        {Key="LunarIpad",UI=AliasMap.Switcher,Text="iPad View",ExpandIndex=0,GetFunc=function() return _G.LexusConfig.IpadView end,
            SetFunc=function(c,v) featureState().SetIpad(value(c,v));return true end},
        {Key="LunarAim",UI=AliasMap.Switcher,Text="Aimbot V1",ExpandIndex=0,
            EventType=F.AimSettingsEventType,EventID=F.AimSettingsEventID,
            GetFunc=function() return featureState().Settings.AimEnabled end,
            SetFunc=function(c,v) featureState().SetAim(value(c,v));return true end}
    }
    -- Verified native settings item contract: absolute Min/Max values, native
    -- key/value callbacks, and expansion events owned by the game's page.
    local function rangeItem(key,label,lo,hi,parent,get,set)
        return {Key=key,UI=AliasMap.Slider,Text=label,Min=lo,Max=hi,ExpandHandle=parent,
            GetFunc=function() return get() end,
            SetFunc=function(c,v)
                featureState()[set](value(c,v))
                if set~="SetAimCircle" and set~="SetAimSpeed" then featureState().Save(true) end
                return true
            end}
    end
    if sliderReady then
        table.insert(Other,3,rangeItem("LunarIpadFOV","iPad FOV",90,120,"LunarIpad",
            function() return featureState().Settings.IpadFOV end,"SetIpadFOV"))
    end
    if sliderReady then
        Other[#Other+1]=rangeItem("LunarAimSpeed","Aim speed",120,150,nil,
            function() return featureState().Settings.AimSpeed end,"SetAimSpeed")
    end
    Other[#Other+1]={Key="LunarAimTarget",UI=AliasMap.Switcher,Text="Aim target",ExpandHandle="LunarAim",
        SwitcherText={"Head","Body","Leg"},SwitcherValue={1,2,3},
        GetFunc=function() return featureState().Settings.AimTarget end,
        SetFunc=function(c,v) featureState().SetAimTarget(value(c,v));return true end}
    if sliderReady then
        Other[#Other+1]=rangeItem("LunarAimCircle","Aim circle / distance",120,240,nil,
            function() return featureState().Settings.AimCircle end,"SetAimCircle")
    end
    Other[#Other+1]={Key="LunarAim2",UI=AliasMap.Switcher,Text="Aimbot V2",
        EventType=F.AimSettingsEventType,EventID=F.AimSettingsEventID,
        GetFunc=function() return featureState().Settings.Aim2Enabled end,
        SetFunc=function(c,v) featureState().SetAim2(value(c,v));return true end}
    Other[#Other+1]={Key="LunarMortarAim",UI=AliasMap.Switcher,Text="Mortar aim",
        GetFunc=function() return featureState().Settings.MortarEnabled end,
        SetFunc=function(c,v) featureState().SetMortar(value(c,v));return true end}
    local names={"Pink","White","Cyan","Green","Yellow","Saffron","Red"}
    for i,entry in ipairs({{"WallVisible","Visible color"},{"WallOccluded","Behind-wall color"}}) do
        local key,label=entry[1],entry[2]
        table.insert(Other,1+i,{Key="Lunar"..key,UI=AliasMap.CompactSwitcher or AliasMap.Switcher,Text=label,
            EventType=F.ESPSettingsEventType,EventID=3,
            ExpandHandle="LunarWall",SwitcherText=names,SwitcherValue={1,2,3,4,5,6,7},
            GetFunc=function() return featureState().Settings[key] end,
            SetFunc=function(c,v) return featureState().SetWallColor(key,value(c,v)) end})
    end
    local page={Key="HackMenu",Text="Hack menu",UIKey="Setting_Page_Privacy",Category={
        {Key="Lunar_ESP_V1",Text="ESP V1",Stack=V1},
        {Key="Lunar_ESP_V2",Text="ESP V2",Stack=V2},
        {Key="Lunar_Other",Text="Other Features",Stack=Other}
    }}

        return page
    end
    local function initialize(state)
        local F = _G.LunarFeatures
        assert(type(F) == "table", "FEATURE_RUNTIME_NOT_READY")
        local pages = loadTable("client.logic.NewSetting.SettingPageDefine")
        local catalog = loadTable("client.logic.NewSetting.SettingCatalog")
        local aliases = loadTable("client.slua.umg.NewSetting.Item.AliasMap")
        restoreAliases(state, aliases)
        assert(type(aliases.Switcher) == "table", "AliasMap.Switcher_not_ready")

        -- Missing optional sliders must not hide the entire settings tab.
        -- Rebuild with both original slider rows as soon as their UI is available.
        local sliderReady = type(aliases.Slider) == "table"
        local compact = aliases.CompactSwitcher or aliases.Switcher
        local rebuild = state.Version ~= VERSION or not state.Page
            or state.Features ~= F or state.Alias ~= aliases
            or state.Switcher ~= aliases.Switcher or state.Slider ~= aliases.Slider
            or state.CompactSwitcher ~= compact
        if rebuild then
            state.Page = buildPage(F, aliases, sliderReady)
            state.PageBuilds = (state.PageBuilds or 0) + 1
        end
        state.Version, state.Features, state.PageDefine, state.Catalog = VERSION, F, pages, catalog
        state.Alias, state.Switcher, state.Slider = aliases, aliases.Switcher, aliases.Slider
        state.CompactSwitcher = compact
        state.SliderReady = sliderReady
        state.DeferredSliderRows = sliderReady and 0 or 3
        pages.HackMenu = state.Page
        state.Registered = register(catalog, state.Page)
        syncModeCatalogs(state)

        local okSlider,sliderClass=pcall(loadTable,"client.slua.umg.NewSetting.Item.Setting_Option_Slider")
        if okSlider and type(F.InstallNativeLiveSlider)=="function" then
            local ok,result=pcall(F.InstallNativeLiveSlider,sliderClass)
            state.LiveRangeReady=ok and result==true
        end
        -- Bulk selector enhancement is optional; its failure cannot block the page.
        local okClass, switchClass = pcall(loadTable, "client.slua.umg.NewSetting.Item.Setting_Option_Switcher")
        if okClass and type(F.InstallNativeBulkSwitch) == "function" then
            local okBulk, result = pcall(F.InstallNativeBulkSwitch, switchClass)
            state.BulkSwitchReady = okBulk and result == true
            state.BulkSwitchError = not okBulk and tostring(result) or nil
        else
            state.BulkSwitchReady = false
            state.BulkSwitchError = not okClass and tostring(switchClass) or "BULK_SWITCH_HELPER_UNAVAILABLE"
        end
        state.Ready = state.Registered and state.HookInstalled == true
        if state.Ready then
            state.LastError = nil
            _G.HackMenuInitialized = "MASTERAHSAN_NATIVE_SETTINGS_V9_2"
        else state.LastError = "SETTINGS_UI_MANAGER_NOT_READY" end
        return state.Ready
    end
    g_masterahsanyt_EnsureHackMenu = function()
        local state = runtime()
        state.Ensure = g_masterahsanyt_EnsureHackMenu
        if state.Initializing then return false end
        state.Initializing = true
        state.Attempts = (state.Attempts or 0) + 1
        -- Install early even when page/alias modules are still loading.
        local okHook, hookError = pcall(installManagers, state)
        if not okHook then state.HookInstalled = false; state.HookError = tostring(hookError)
        else state.HookError = nil end
        local ok, result = pcall(initialize, state)
        state.Initializing = false
        if not ok then state.Ready = false; state.LastError = tostring(result) end
        return ok and result == true
    end
    _G.LunarSettingsDiagnostics = function()
        local state = runtime()
        local timer = _G.__MasterShotFastRunner
        return {version = state.Version, ready = state.Ready == true,
            registered = state.Registered == true, attempts = state.Attempts or 0,
            lastError = state.LastError, hookInstalled = state.HookInstalled == true,
            hookCount = state.HookCount or 0, hookError = state.HookError,
            managerModuleError = state.ManagerModuleError,
            pageBuilt = state.Page ~= nil, pageBuilds = state.PageBuilds or 0,
            pageUIKey = state.Page and state.Page.UIKey or nil,
            sliderReady = state.SliderReady == true, deferredSliderRows = state.DeferredSliderRows,
            lastShowUIInjected = state.LastShowUIInjected,
            lastShowUICatalogIndex = state.LastShowUICatalogIndex,
            maintenanceProvider = type(timer) == "table" and timer.Provider or nil,
            maintenanceError = type(timer) == "table" and timer.LastError or nil}
    end
end

-- ESP configuration made by @Masterpiece2025
_G.g_masterahsanyt_MasterShotESP = _G.g_masterahsanyt_MasterShotESP or {

    Enabled = true,
    MaxRangeMeters = 450.0,

    -- Target 60 updates/sec when the engine timer permits. No skeleton decimation.
    -- Discovery is separate from rendering; every rendered pose uses fresh projections.
    ScanInterval = 0.35,
    UpdateInterval = 1.0 / 60.0,
    WidgetBuildBudget = 96, -- New line widgets per update; existing widgets stay live.
    Profile = false,       -- Optional CPU timing in _G.g_masterahsanyt_ESPDiagnostics.
    TransformInterval = 0.60,
    MaxRendered = 8,

    CounterY = 36.0,
    CounterWidth = 218.4,
    CounterHeight = 33.6,
    CounterDiamondSize = 0.0,

    TracerThickness = 1.80,
    NameGap = 2.0,
    NameFontSize = 14,
    DistanceFontSize = 20,
    DistanceBelowFeet = 8.0,
}
if (tonumber(_G.g_masterahsanyt_MasterShotESP.MaxRendered) or 0) < 1 then
    _G.g_masterahsanyt_MasterShotESP.MaxRendered = 8
end
if (tonumber(_G.g_masterahsanyt_MasterShotESP.MaxRangeMeters) or 0) < 400.0 then
    _G.g_masterahsanyt_MasterShotESP.MaxRangeMeters = 450.0
end
-- Upgrade a table retained by an earlier hot-reload to the new readable marker size.
if (tonumber(_G.g_masterahsanyt_MasterShotESP.DistanceFontSize) or 0) < 20 then
    _G.g_masterahsanyt_MasterShotESP.DistanceFontSize = 20
end
-- Counters are 20% larger than the previous 182x28 revision.
_G.g_masterahsanyt_MasterShotESP.CounterWidth=218.4
_G.g_masterahsanyt_MasterShotESP.CounterHeight=33.6
_G.g_masterahsanyt_MasterShotESP.CounterDiamondSize=0.0

-- Upgrade only the shipped 30 Hz default on the first performance revision.
if not _G.g_masterahsanyt_MasterShotESP.PerformanceRevision then
    if _G.g_masterahsanyt_MasterShotESP.UpdateInterval == 0.033 then
        _G.g_masterahsanyt_MasterShotESP.UpdateInterval = 1.0 / 60.0
    end
    _G.g_masterahsanyt_MasterShotESP.PerformanceRevision = 1
end
_G.MasterShotESP = _G.g_masterahsanyt_MasterShotESP

-- ESP runtime state made by @Masterpiece2025
local g_masterahsanyt_ShotESP = {
    Canvas = nil,
    RootUI = nil,
    Counter = nil,
    Enemies = {},
    Lines = {},
    Names = {},
    Boxes = {},
    HealthBars = {},
    Skeletons = {},
    Headers = {},
    Footers = {},
    BuildStage = {},
    BoneNameCache = {},
    Decorations = {},
    TemplateFont = nil,
    TemplateFontObject = nil,
    TemplateTypeface = nil,
    TemplateColorAndOpacity = nil,
    LastScanClock = -999.0,
    LastTransformClock = -999.0,
    LastWorld = nil,
    TracerOrigin = nil,

    CanvasScaleX = 1.0,
    CanvasScaleY = 1.0,
    CanvasOffsetX = 0.0,
    CanvasOffsetY = 0.0,
    ViewportW = nil,
    ViewportH = nil,
    RawViewportW = nil,
    RawViewportH = nil,
    HeaderRoots = {},
    Active = {},
    Alive = {},
    BoneMeshes = {},
    BonePoints = {},
    TimerClock = 0.0,
    Now = 0.0,
    Disabled = false,
    -- Bot detection result cache (avoids repeated IsAI calls every frame)
    _BotCache = {},
    RealCount = 0,
    BotCount = 0,
}

local V2 = _G.FVector2D
if not V2 then pcall(function() V2 = import("Vector2D") end) end
local V3 = _G.FVector
if not V3 then pcall(function() V3 = import("Vector") end) end
local LinearColor = _G.FLinearColor
if not LinearColor then pcall(function() LinearColor = import("LinearColor") end) end
local Anchors = _G.FAnchors
if not Anchors then pcall(function() Anchors = import("Anchors") or import("/Script/Slate.Anchors") end) end
local SlateBlueprintLibrary = nil
pcall(function() SlateBlueprintLibrary = import("SlateBlueprintLibrary") end)
local WidgetLayoutLibrary = nil
pcall(function() WidgetLayoutLibrary = import("WidgetLayoutLibrary") end)
local SlateColor = nil
pcall(function() SlateColor = import("SlateColor") or import("/Script/SlateCore.SlateColor") end)
local KismetTextLibrary = nil
pcall(function() KismetTextLibrary = import("KismetTextLibrary") or import("/Script/Engine.KismetTextLibrary") end)
local GameplayStaticsESP = nil
pcall(function() GameplayStaticsESP = import("GameplayStatics") end)
local ESPGameplayData=nil
pcall(function() ESPGameplayData=require("GameLua.GameCore.Data.GameplayData") end)

-- g_masterahsanyt_ESPV2 made by @Masterpiece2025
local function g_masterahsanyt_ESPV2(x, y)
    if V2 then return V2(x, y) end
    return {X = x, Y = y}
end

local function g_masterahsanyt_ESPV3(x, y, z)
    if V3 then
        local ok, v = pcall(V3, x, y, z)
        if ok and v then return v end
    end
    return {X = x, Y = y, Z = z}
end

-- ESP color made by @Masterpiece2025
local function g_masterahsanyt_ESPColor(r, g, b, a)
    if LinearColor then return LinearColor(r, g, b, a or 1.0) end
    return {R=r, G=g, B=b, A=a or 1.0}
end

-- ESP color theme made by @Masterpiece2025
local ESP_REAL = g_masterahsanyt_ESPColor(0.90, 0.14, 0.14, 0.98)
local ESP_BOT  = g_masterahsanyt_ESPColor(0.18, 0.86, 0.36, 0.98)
local ESP_WHITE = g_masterahsanyt_ESPColor(1.0, 1.0, 1.0, 1.0)
local ESP_BLACK = g_masterahsanyt_ESPColor(0.0, 0.0, 0.0, 1.0)
local ESP_TEXT_CLEAR = g_masterahsanyt_ESPColor(0.0,0.0,0.0,0.0)
local ESP_HEADER_BG = g_masterahsanyt_ESPColor(0.0, 0.0, 0.0, 0.78)
local ESP_COUNTER_RED = g_masterahsanyt_ESPColor(1.0, 0.055, 0.105, 1.0)
local ESP_COUNTER_RED_DARK = g_masterahsanyt_ESPColor(0.12, 0.008, 0.012, 1.0)
local ESP_COUNTER_BLUE = g_masterahsanyt_ESPColor(0.18, 0.86, 0.36, 1.0)
local ESP_COUNTER_BLUE_DARK = g_masterahsanyt_ESPColor(0.012, 0.06, 0.025, 1.0)
local ESP_COUNTER_CENTER = g_masterahsanyt_ESPColor(0.075, 0.080, 0.095, 1.0)

-- ESP gradient color made by @Masterpiece2025
local function g_masterahsanyt_ESPScaleColor(color, factor, alphaMul)
    if not color then return g_masterahsanyt_ESPColor(1, 1, 1, 1) end
    local r = math.max(0.0, math.min(1.0, (tonumber(color.R) or 1.0) * (factor or 1.0)))
    local g = math.max(0.0, math.min(1.0, (tonumber(color.G) or 1.0) * (factor or 1.0)))
    local b = math.max(0.0, math.min(1.0, (tonumber(color.B) or 1.0) * (factor or 1.0)))
    local a = math.max(0.0, math.min(1.0, (tonumber(color.A) or 1.0) * (alphaMul or 1.0)))
    return g_masterahsanyt_ESPColor(r, g, b, a)
end

local ESP_REAL_DARK  = g_masterahsanyt_ESPScaleColor(ESP_REAL, 0.68, 1.0)
local ESP_REAL_LIGHT = g_masterahsanyt_ESPScaleColor(ESP_REAL, 1.12, 0.82)
local ESP_BOT_DARK   = g_masterahsanyt_ESPScaleColor(ESP_BOT, 0.68, 1.0)
local ESP_BOT_LIGHT  = g_masterahsanyt_ESPScaleColor(ESP_BOT, 1.10, 0.82)
local ESP_WHITE_SOFT = g_masterahsanyt_ESPColor(0.94, 0.94, 0.94, 0.98)
local ESP_WHITE_GLOSS = g_masterahsanyt_ESPColor(1.0, 1.0, 1.0, 0.34)

local g_masterahsanyt_ESPTheme
do
local ESP_REAL_THEME = {Key="REAL",Main=ESP_REAL,Light=ESP_REAL_LIGHT,
    Text=g_masterahsanyt_ESPColor(1.0,0.86,0.84,1.0),
    Background=g_masterahsanyt_ESPColor(0.05,0.005,0.005,0.97),
    Empty=g_masterahsanyt_ESPColor(0.055,0.008,0.008,1.0)}
local ESP_BOT_THEME = {Key="BOT",Main=ESP_BOT,Light=ESP_BOT_LIGHT,
    Text=g_masterahsanyt_ESPColor(0.82,1.0,0.87,1.0),
    Background=g_masterahsanyt_ESPColor(0.005,0.05,0.015,0.97),
    Empty=g_masterahsanyt_ESPColor(0.008,0.055,0.018,1.0)}
g_masterahsanyt_ESPTheme=function(isBot)
    return isBot and ESP_BOT_THEME or ESP_REAL_THEME
end
end
-- ESP object validation made by @Masterpiece2025
local function g_masterahsanyt_ESPValid(obj)
    if not obj then return false end
    if not slua or not slua.isValid then return false end
    local ok, valid = pcall(slua.isValid, obj)
    return ok and valid == true
end

local ESPShared={}
function ESPShared.Finite(n)
    return type(n)=="number" and n==n and n>-math.huge and n<math.huge
end
function ESPShared.SafeNumber(value,fallback,lo,hi)
    local n=tonumber(value)
    if not ESPShared.Finite(n) then n=fallback end
    return math.max(lo,math.min(hi,n))
end
function ESPShared.VectorComponents(v) return tonumber(v.X),tonumber(v.Y),tonumber(v.Z) end
function ESPShared.VectorValues(v)
    if v==nil then return nil end
    local ok,x,y,z=pcall(ESPShared.VectorComponents,v)
    if ok and ESPShared.Finite(x) and ESPShared.Finite(y) and ESPShared.Finite(z)
        and math.abs(x)<1e12 and math.abs(y)<1e12 and math.abs(z)<1e12 then return x,y,z end
end

-- ESP timing made by @Masterpiece2025
local function g_masterahsanyt_ESPNow()
    local t = nil
    pcall(function()
        local w = (slua and slua.getWorld and slua.getWorld()) or nil
        if GameplayStaticsESP and w and GameplayStaticsESP.GetRealTimeSeconds then
            t = GameplayStaticsESP.GetRealTimeSeconds(w)
        end
    end)
    t=tonumber(t)
    if ESPShared.Finite(t) and t>=0 then return t end
    -- os.clock measures CPU time on some platforms, not elapsed frame time.
    -- If the engine clock is unavailable, advance by executed timer delays.
    return ESPShared.SafeNumber(g_masterahsanyt_ShotESP.TimerClock,0.0,0.0,1e12)
end

-- ESP world access made by @Masterpiece2025
local function g_masterahsanyt_ESPWorld()
    local w = nil
    pcall(function() if slua and slua.getWorld then w = slua.getWorld() end end)
    return w
end

-- ESP player controller made by @Masterpiece2025
local function g_masterahsanyt_ESPGetController()
    local pc = nil
    pcall(function()
        local GDP = ESPGameplayData
        if GDP and GDP.GetPlayerController then pc = GDP.GetPlayerController() end
    end)
    if not g_masterahsanyt_ESPValid(pc) then
        pcall(function()
            if slua_GameFrontendHUD then pc = slua_GameFrontendHUD:GetPlayerController() end
        end)
    end
    return g_masterahsanyt_ESPValid(pc) and pc or nil
end

-- ESP local player made by @Masterpiece2025
local function g_masterahsanyt_ESPGetLocalCharacter()
    local c = nil
    pcall(function()
        local GDP = ESPGameplayData
        if GDP then
            if GDP.GetPlayerCharacter then c = GDP.GetPlayerCharacter() end
            if not g_masterahsanyt_ESPValid(c) and GDP.GetLocalCharacter then c = GDP.GetLocalCharacter() end
        end
    end)
    if not g_masterahsanyt_ESPValid(c) then
        local pc = g_masterahsanyt_ESPGetController()
        pcall(function() if pc and pc.GetPawn then c = pc:GetPawn() end end)
    end
    return g_masterahsanyt_ESPValid(c) and c or nil
end

-- g_masterahsanyt_ESPGetPlayerState made by @Masterpiece2025
local function g_masterahsanyt_ESPGetPlayerState(character)
    if not g_masterahsanyt_ESPValid(character) then return nil end
    local ps = nil
    pcall(function()
        if character.GetPlayerStateSafety then ps = character:GetPlayerStateSafety() end
    end)
    if not g_masterahsanyt_ESPValid(ps) then
        pcall(function() if character.GetPlayerState then ps = character:GetPlayerState() end end)
    end
    if not g_masterahsanyt_ESPValid(ps) then
        pcall(function() ps = character.PlayerState end)
    end
    return g_masterahsanyt_ESPValid(ps) and ps or nil
end

-- g_masterahsanyt_ESPNormalizeName made by @Masterpiece2025
local function g_masterahsanyt_ESPNormalizeName(value)
    if value == nil or value == false then return nil end
    local ok, text = pcall(tostring, value)
    if not ok or not text then return nil end
    text = text:gsub("^%s+", ""):gsub("%s+$", "")
    if text == "" or text == "nil" or text == "None" or text == "NULL" or text == "UNKNOWN" then return nil end
    if text:find("^userdata:") or text:find("^table:") then return nil end
    return text
end

-- ESP player name made by @Masterpiece2025
local function g_masterahsanyt_ESPResolvePlayerName(character)
    if not g_masterahsanyt_ESPValid(character) then return nil end
    local name = nil

-- take made by @Masterpiece2025
    local function take(value)
        if not name then name = g_masterahsanyt_ESPNormalizeName(value) end
    end

    pcall(function() if character.GetPlayerNameSafety then take(character:GetPlayerNameSafety()) end end)
    pcall(function() if not name and character.GetPlayerName then take(character:GetPlayerName()) end end)
    pcall(function() if not name then take(character.PlayerName) end end)
    pcall(function() if not name then take(character.NickName) end end)
    pcall(function() if not name then take(character.AIPlayerName) end end)
    pcall(function() if not name then take(character.BotName) end end)

    if not name then
        local ps = g_masterahsanyt_ESPGetPlayerState(character)
        if ps then
            pcall(function() if ps.GetPlayerName then take(ps:GetPlayerName()) end end)
            pcall(function() if not name then take(ps.PlayerName) end end)
            pcall(function() if not name then take(ps.PlayerNamePrivate) end end)
            pcall(function() if not name then take(ps.NickName) end end)
            pcall(function() if not name then take(ps.AccountName) end end)
            pcall(function() if not name then take(ps.AIPlayerName) end end)
        end
    end
    return name
end

-- g_masterahsanyt_ESPGetPlayerKey made by @Masterpiece2025
local function g_masterahsanyt_ESPGetPlayerKey(character)
    local key = nil
    pcall(function() if character.GetPlayerKey then key = character:GetPlayerKey() end end)
    if key == nil then pcall(function() key = character.PlayerKey end) end
    if key == nil then
        local ps = g_masterahsanyt_ESPGetPlayerState(character)
        if ps then pcall(function() key = ps.PlayerKey end) end
    end
    if key == nil or tostring(key) == "" or tostring(key) == "0" or tostring(key) == "-1" then
        return tostring(character)
    end
    return tostring(key) .. "_" .. tostring(character)
end

-- ESP team detection made by @Masterpiece2025
local function g_masterahsanyt_ESPGetTeamID(character)
    if not g_masterahsanyt_ESPValid(character) then return nil end
    local id = nil
    pcall(function() if character.GetTeamID then id = character:GetTeamID() end end)
    if id == nil then pcall(function() id = character.TeamID end) end
    if id == nil then
        local ps = g_masterahsanyt_ESPGetPlayerState(character)
        if ps then
            pcall(function() if ps.GetTeamID then id = ps:GetTeamID() end end)
            if id == nil then pcall(function() id = ps.TeamID end) end
        end
    end
    return id
end

-- ESP alive detection made by @Masterpiece2025
local ESPFinishedLastBreath,ESPDeadPawnState
pcall(function() ESPFinishedLastBreath=import("ECharacterHealthStatus").FinishedLastBreath end)
pcall(function() ESPDeadPawnState=EPawnState and EPawnState.Dead end)
local function ESPActorField(actor,key) return actor[key] end
local function ESPReadActorField(actor,key)
    local ok,value=pcall(ESPActorField,actor,key)
    if ok then return value end
end
local function ESPReadActorMethod(actor,key,...)
    local method=ESPReadActorField(actor,key)
    if type(method)=="function" then
        local ok,value=pcall(method,actor,...)
        if ok then return value end
    end
end
local function ESPActorDeadFlag(actor,key)
    local value=ESPReadActorField(actor,key)
    return value==true or value==1
end
local function g_masterahsanyt_ESPIsAlive(character)
    if not g_masterahsanyt_ESPValid(character) then return false,"invalid" end
    if ESPActorDeadFlag(character,"bDead") or ESPActorDeadFlag(character,"bIsDead")
        or ESPActorDeadFlag(character,"bIsDeadFlag") then return false,"dead" end
    if ESPFinishedLastBreath~=nil
        and ESPReadActorField(character,"HealthStatus")==ESPFinishedLastBreath then return false,"dead" end
    if ESPDeadPawnState~=nil then
        local state=ESPReadActorMethod(character,"HasPawnState",ESPDeadPawnState)
        if state==true or state==1 then return false,"dead" end
        state=ESPReadActorMethod(character,"HasState",ESPDeadPawnState)
        if state==true or state==1 then return false,"dead" end
    end
    local dead=ESPReadActorMethod(character,"IsDead")
    if dead==true or dead==1 then return false,"dead" end
    -- Knocked characters remain eligible even when their normal HP is zero.
    -- Terminal flags above always take precedence over the rescue state.
    local alive=ESPReadActorMethod(character,"IsAlive")
    if alive==true or alive==1 then return true,"alive" end
    local knocked=ESPReadActorMethod(character,"IsNearDeath")
    if knocked==true or knocked==1 then return true,"knocked" end
    if alive==false or alive==0 then return false,"dead" end
    local hp=ESPReadActorField(character,"Health")
    if not ESPShared.Finite(hp) then hp=ESPReadActorField(character,"HP") end
    if not ESPShared.Finite(hp) then hp=ESPReadActorMethod(character,"GetHealth") end
    if ESPShared.Finite(hp) then return hp>0,hp>0 and "alive" or "unknown" end
    -- Missing/failed replication is not positive evidence of life.
    return false,"unknown"
end

-- Event-driven V1/V2 visibility. The original shared life evaluator and Wall
-- renderer are deliberately untouched. 1=knocked, 2=confirmed dead, 3=exit pending.
ESPShared.Events={Records=setmetatable({}, {__mode="k"}),Clearers={}}
_G.LunarESPEvents=ESPShared.Events
do
    local E=ESPShared.Events
    function E.WorldChanged(world)
        if world==nil then return end
        if E.World~=nil and E.World~=world then
            if E.UnbindAll then E.UnbindAll() end
            E.Records=setmetatable({}, {__mode="k"})
        end
        E.World=world
    end

    local function eventActor(self)
        if not Client then return nil end
        -- Only queried on a native event, never by a new poll or timer. This
        -- prevents a first HUD update from discarding a new-world death event.
        E.WorldChanged(g_masterahsanyt_ESPWorld())
        return self and self.Object
    end

    function E.Clear(actor)
        for _,clear in ipairs(E.Clearers) do pcall(clear,actor) end
    end

    function E.Spawn(self)
        local actor=eventActor(self)
        if actor~=nil then E.Records[actor]=nil end
    end

    function E.Death(self)
        local actor=eventActor(self)
        if actor==nil then return end
        if E.Records[actor]~=2 then
            E.Records[actor]=2
            E.Clear(actor)
        end
    end

    function E.NearDeath(self,isNearDeath)
        local actor=eventActor(self)
        if actor==nil or E.Records[actor]==2 then return end
        local status=ESPReadActorField(actor,"HealthStatus")
        if ESPFinishedLastBreath~=nil and status==ESPFinishedLastBreath then
            E.Records[actor]=2
            E.Clear(actor)
        elseif isNearDeath==true or isNearDeath==1 then
            if E.Records[actor]~=1 then
                E.Records[actor]=1
                E.Clear(actor)
            end
        elseif isNearDeath==false or isNearDeath==0 then
            -- False can also accompany death. Do not equate it with rescue;
            -- require the original life result in the existing ESP pass too.
            if E.Records[actor]==1 then
                E.Records[actor]=3
                E.Clear(actor)
            end
        end
    end

    function E.Counted(actor)
        -- Keep the original counter's knocked-player behavior; only confirmed
        -- death adds an exclusion. Never change Frame.Entries[actor].Alive.
        return E.Records[actor]~=2
    end

    function E.Visible(actor,snapshot)
        local state=E.Records[actor]
        if state==2 or state==1 then return false end
        if state==3 then
            if not snapshot or not snapshot.Alive or snapshot.LifeState=="knocked" then return false end
            -- Preserve the original map-specific IsAlive/GetHealth priority.
            -- A stale zero HP field must not permanently hide a rescued pawn.
            -- Only a confirmed death event/status can set state 2.
            E.Records[actor]=nil
        end
        return snapshot and snapshot.Alive and snapshot.LifeState~="knocked"
    end

    function E.Project(pc,actor,state)
        local snapshot=ESPShared.GetFrameRecord(actor)
        if not E.Visible(actor,snapshot) then return nil,nil,false,"life" end
        local head,feet,onScreen,reason=ESPShared.ProjectActor(pc,actor,state)
        -- A native call can dispatch a lifecycle event during projection.
        if not E.Visible(actor,snapshot) then return nil,nil,false,"life" end
        return head,feet,onScreen,reason
    end

    function E.ClearIn(state,prune,actor)
        -- Reuse the existing pooled-widget cleanup. All keys except this
        -- actor's are kept, including actors beyond the display budget.
        for _,item in ipairs(state.Enemies) do
            if item.Character==actor then
                local key=item.Key
                local keep=setmetatable({[key]=false},{__index=function() return true end})
                state.Active[key]=nil
                state.Alive[key]=nil
                if state.LastProjected then state.LastProjected[key]=nil end
                prune(keep,keep)
            end
        end
    end

    -- Independent SLua multicast listeners. No CharacterBase method is changed.
    -- Add(function) returns an integer handle; Remove(handle) removes that
    -- listener only. See Tencent/sluaunreal LuaDelegate.cpp, LuaMultiDelegate.
    -- Insert this chunk inside the existing ESPShared.Events do/end block,
    -- replacing only the three BRPlayerCharacterBase handler overrides.
    local oldObserver=_G.__LunarESPEventObserver
    if oldObserver and oldObserver~=E and type(oldObserver.UnbindAll)=="function" then
        pcall(oldObserver.UnbindAll)
    end
    _G.__LunarESPEventObserver=E
    E.Bindings={}
    E.BindingCount=0
    E.BindingLimit=512
    E.ObserverDiagnostics={Bound=0,Unsupported=0,AddErrors=0,RemoveErrors=0}
    local observerGeneration=1
    local dispatchDepth=0
    local pendingAll=false
    local pendingActors={}

    local function observerMember(object,key)
        if object==nil then return nil end
        local ok,value=pcall(function() return object[key] end)
        if ok then return value end
    end
    local function observerValid(actor)
        if actor==nil then return false end
        if not slua or type(slua.isValid)~="function" then return false end
        local ok,yes=pcall(slua.isValid,actor)
        return ok and yes==true
    end
    local function removeBinding(actor,row)
        if E.Bindings[actor]~=row then return end
        E.Bindings[actor]=nil
        E.BindingCount=math.max(0,E.BindingCount-1)
        row.Active=false
        local tracked=_G.g_masterahsanyt_TrackedCharacters
        local key=tostring(actor)
        if tracked and tracked[key]==actor then tracked[key]=nil end
        row.Actor[1]=nil
        for _,owned in ipairs(row.Handles) do
            local remove=observerMember(owned.Delegate,"Remove")
            if type(remove)=="function" then
                local ok=pcall(remove,owned.Delegate,owned.Handle)
                if not ok then E.ObserverDiagnostics.RemoveErrors=E.ObserverDiagnostics.RemoveErrors+1 end
            end
        end
        row.Handles={}
    end
    local function flushObserverCleanup()
        if dispatchDepth~=0 then return end
        if pendingAll then
            pendingAll=false
            for actor,row in pairs(E.Bindings) do removeBinding(actor,row) end
            pendingActors={}
        else
            for actor in pairs(pendingActors) do
                pendingActors[actor]=nil
                local row=E.Bindings[actor]
                if row then removeBinding(actor,row) end
            end
        end
    end
    function E.UnbindAll()
        -- Removing a Lua delegate during its native multicast dispatch is
        -- unsafe in SLua. Invalidate now; flush on the next existing ESP pass.
        observerGeneration=observerGeneration+1
        pendingAll=true
        for _,row in pairs(E.Bindings) do row.Active=false end
        flushObserverCleanup()
    end
    function E.Unobserve(actor)
        local row=E.Bindings[actor]
        if not row then return end
        row.Active=false
        if dispatchDepth~=0 then pendingActors[actor]=true
        else removeBinding(actor,row) end
    end
    local eventSpecs={
        {Name="IsEnterNearDeathDelegate",Handler="NearDeath"},
        {Name="OnDeathDelegate",Handler="Death"},
        {Name="OnPawnRespawnDelegate",Handler="Spawn"}
    }
    function E.Observe(actor)
        if not Client or actor==nil then return false end
        if pendingAll or next(pendingActors)~=nil then flushObserverCleanup() end
        local row=E.Bindings[actor]
        if row then return row.Bound end
        if not observerValid(actor) then return false end
        -- A hard bound limits listener retention even if enumeration fails.
        -- Unsupported actors still use the original live-state fallback.
        if E.BindingCount>=E.BindingLimit then return false end
        row={Active=true,Generation=observerGeneration,
            Actor=setmetatable({actor},{__mode="v"}),Handles={},Bound=false}
        E.Bindings[actor]=row
        E.BindingCount=E.BindingCount+1
        -- Native class lifecycle stays untouched. Existing pawn discovery
        -- supplies tracking/maintenance, and native respawn delegates clear ESP.
        _G.g_masterahsanyt_TrackedCharacters=_G.g_masterahsanyt_TrackedCharacters or {}
        _G.g_masterahsanyt_TrackedCharacters[tostring(actor)]=actor
        if g_masterahsanyt_StartSettingsMaintenance then
            pcall(g_masterahsanyt_StartSettingsMaintenance,actor)
        end
        if not _G._BYPASS_DONE and type(_G._BYPASS_Execute)=="function" then
            pcall(_G._BYPASS_Execute)
        end
        for _,spec in ipairs(eventSpecs) do
            local delegate=observerMember(actor,spec.Name)
            local add=observerMember(delegate,"Add")
            local remove=observerMember(delegate,"Remove")
            if type(add)=="function" and type(remove)=="function" then
                local handler=spec.Handler
                local function observed(...)
                    local current=row.Actor[1]
                    if not row.Active or row.Generation~=observerGeneration
                        or _G.LunarESPEvents~=E or not observerValid(current) then return end
                    dispatchDepth=dispatchDepth+1
                    -- The existing state machine accepts self.Object. This
                    -- transient wrapper is never installed on a native class.
                    pcall(E[handler],{Object=current},...)
                    dispatchDepth=dispatchDepth-1
                    -- Cleanup is intentionally deferred until Observe/Sync.
                end
                local ok,handle=pcall(add,delegate,observed)
                if ok and type(handle)=="number" and handle>0 then
                    row.Handles[#row.Handles+1]={Delegate=delegate,Handle=handle}
                    row.Bound=true
                    E.ObserverDiagnostics.Bound=E.ObserverDiagnostics.Bound+1
                else
                    E.ObserverDiagnostics.AddErrors=E.ObserverDiagnostics.AddErrors+1
                end
            else
                E.ObserverDiagnostics.Unsupported=E.ObserverDiagnostics.Unsupported+1
            end
        end
        return row.Bound
    end
    function E.SyncObservedPawns(pawns)
        -- Called with the already-enumerated GetAllPlayerPawns result, never
        -- obtains a second actor list and never schedules another timer.
        flushObserverCleanup()
        for actor,row in pairs(E.Bindings) do
            -- Enumeration can temporarily omit a still-valid pawn. Keep its
            -- existing lifecycle listeners and death record so stale HP on
            -- return cannot resurrect ESP, and a real respawn while omitted
            -- can still release the record. Native invalidation/world reset
            -- removes these bounded listeners; no new poll or timer is added.
            if not observerValid(actor) then
                E.Unobserve(actor)
                E.Records[actor]=nil
            end
        end
        -- Native arrays are also observed by the existing GetFrameRecord
        -- pass. Even an unavailable/non-table list must release invalid rows.
        if type(pawns)~="table" then return end
        for _,actor in pairs(pawns) do
            if actor~=nil then E.Observe(actor) end
        end
    end

end

-- Hidden knock/death entries do not consume another enemy's display slot.
-- The counter keeps the original list. Selection reuses its already-read
-- frame records and never asks for extra projection or visibility queries.
function ESPShared.Events.SelectVisible(enemies,limit,reuse)
    local selected=reuse or {};local count=0
    for _,item in ipairs(enemies) do
        if count>=limit then break end
        if ESPShared.Events.Visible(item.Character,ESPShared.GetFrameRecord(item.Character)) then
            count=count+1;selected[count]=item
        end
    end
    for i=#selected,count+1,-1 do selected[i]=nil end
    return selected,count
end
function ESPShared.Events.ReleaseSelected(selected)
    if selected then for i=#selected,1,-1 do selected[i]=nil end end
end

-- Bot cache uses the same actor/player key as pruning, with replication retries.
local function g_masterahsanyt_ESPIsBot(character, key, providedCache, providedNow)
    if not g_masterahsanyt_ESPValid(character) then return false end
    key = key or g_masterahsanyt_ESPGetPlayerKey(character)
    local cache = providedCache or g_masterahsanyt_ShotESP._BotCache
    local now = providedNow or g_masterahsanyt_ShotESP.Now
    local entry = cache[key]
    if entry and now >= entry.Clock and now - entry.Clock < 2.0 then return entry.Value end
    local result = nil
    local function take(v)
        if result == nil and (v == true or v == false or v == 1 or v == 0) then
            result = (v == true or v == 1)
        end
    end
    pcall(function() if Game and Game.IsAI then take(Game:IsAI(character)) end end)
    if result == nil then pcall(function() take(character.bIsAI) end) end
    if result == nil then pcall(function() if character.IsBot then take(character:IsBot()) end end) end
    if result == nil then
        local ps = g_masterahsanyt_ESPGetPlayerState(character)
        if ps then
            pcall(function() take(ps.bIsABot) end)
            pcall(function() take(ps.bIsBot) end)
            pcall(function() take(ps.bIsAI) end)
            if result == nil then pcall(function() if ps.IsBot then take(ps:IsBot()) end end) end
        end
    end
    -- Unresolved replication data is never cached as a permanent false.
    cache[key] = result ~= nil and {Value=result, Clock=now} or nil
    return result == true
end

-- ESP actor position made by @Masterpiece2025
local function g_masterahsanyt_ESPActorLocation(character)
    local loc = nil
    if not g_masterahsanyt_ESPValid(character) then return nil end
    pcall(function()
        if character.K2_GetActorLocation then loc = character:K2_GetActorLocation()
        elseif Game and Game.GetActorLocation then loc = Game:GetActorLocation(character) end
    end)
    return loc
end

-- ESP distance calculation made by @Masterpiece2025
local function g_masterahsanyt_ESPDistanceMeters(a,b)
    local ax,ay,az=ESPShared.VectorValues(a)
    local bx,by,bz=ESPShared.VectorValues(b)
    if not ax or not bx then return math.huge end
    local dx,dy,dz=ax-bx,ay-by,az-bz
    return math.sqrt(dx*dx+dy*dy+dz*dz)/100.0
end


-- A memo lives for one scheduler callback only.
-- Callback-local values never retain actors, controllers or native locations
-- after Finish. The bounded pool keeps only reusable vector buffers.
ESPShared.Frame={Active=false,Entries={},Pool={},PoolLimit=256,Now=0,ViewAt=-999,Controllers={},Transforms={},TransformPool={}}
function ESPShared.Frame.Finish()
    local frame=ESPShared.Frame
    for actor,entry in pairs(frame.Entries) do
        frame.Entries[actor]=nil
        entry.Location=nil;entry.LocationX=nil;entry.LocationY=nil;entry.LocationZ=nil
        entry.DistanceOrigin=nil;entry.DistanceSquared=nil;entry.DistanceMeters=nil
        entry.Alive=false;entry.Projected=false;entry.OnScreen=false
        entry.HasHead=false;entry.HasFeet=false;entry.PC=nil
        if #frame.Pool<frame.PoolLimit then frame.Pool[#frame.Pool+1]=entry end
    end
    for pc in pairs(frame.Controllers) do frame.Controllers[pc]=nil end
    for state,value in pairs(frame.Transforms) do
        frame.Transforms[state]=nil
        if #frame.TransformPool<4 then frame.TransformPool[#frame.TransformPool+1]=value end
    end
    frame.DistanceOrigin=nil;frame.OriginX=nil;frame.OriginY=nil;frame.OriginZ=nil
    frame.Pawns=nil;frame.Active=false;frame.V1CanvasChecked=false
end
function ESPShared.Frame.Begin(now)
    ESPShared.Frame.Finish()
    ESPShared.Frame.Now=now;ESPShared.Frame.Active=true
end
function ESPShared.GetFrameRecord(actor)
    local frame=ESPShared.Frame
    local entry=frame.Active and frame.Entries[actor]
    if entry then return entry end
    if ESPShared.Events.Observe then ESPShared.Events.Observe(actor) end
    entry=frame.Active and table.remove(frame.Pool) or nil
    if not entry then entry={} end
    entry.Alive,entry.LifeState=g_masterahsanyt_ESPIsAlive(actor)
    entry.Projected=false;entry.OnScreen=false;entry.HasHead=false;entry.HasFeet=false
    entry.Location=entry.Alive and g_masterahsanyt_ESPActorLocation(actor) or nil
    entry.LocationX,entry.LocationY,entry.LocationZ=ESPShared.VectorValues(entry.Location)
    if not entry.LocationX then entry.Location=nil end
    if frame.Active and actor~=nil then frame.Entries[actor]=entry end
    return entry
end
function ESPShared.GetFramePawns()
    if ESPShared.Frame.Active and ESPShared.Frame.Pawns then return ESPShared.Frame.Pawns end
    local pawns
    pcall(function() if Game and Game.GetAllPlayerPawns then pawns=Game:GetAllPlayerPawns() end end)
    -- The native CharacterBase already maintains this public registry.
    -- Read it only when the engine pawn getter is unavailable; no native
    -- AddCharacter/RemoveCharacter or lifecycle method is replaced.
    if not pawns and GameplayData then
        if type(GameplayData.GetAllPlayerCharacters)=="function" then
            pcall(function()pawns=GameplayData.GetAllPlayerCharacters()end)
        end
        if not pawns and type(GameplayData.GetAllCharacters)=="function" then
            pcall(function()pawns=GameplayData.GetAllCharacters()end)
        end
    end
    if ESPShared.Frame.Active then ESPShared.Frame.Pawns=pawns end
    local E=ESPShared.Events
    local now=ESPShared.Frame.Active and ESPShared.Frame.Now or g_masterahsanyt_ESPNow()
    if E.SyncObservedPawns and (not E.SyncDue or now>=E.SyncDue or now<(E.SyncClock or now)) then
        E.SyncObservedPawns(pawns);E.SyncDue=now+1;E.SyncClock=now
    end
    return pawns
end
function ESPShared.DistanceSquaredFrom(entry,origin)
    if not entry or not entry.LocationX then return math.huge end
    local frame=ESPShared.Frame
    if frame.Active and entry.DistanceOrigin==origin and entry.DistanceSquared~=nil then return entry.DistanceSquared end
    local x,y,z
    if frame.Active and frame.DistanceOrigin==origin then
        x,y,z=frame.OriginX,frame.OriginY,frame.OriginZ
    else
        x,y,z=ESPShared.VectorValues(origin)
        if frame.Active then frame.DistanceOrigin=origin;frame.OriginX=x;frame.OriginY=y;frame.OriginZ=z end
    end
    if not x then
        if frame.Active then entry.DistanceOrigin=origin;entry.DistanceSquared=math.huge;entry.DistanceMeters=nil end
        return math.huge
    end
    local dx,dy,dz=x-entry.LocationX,y-entry.LocationY,z-entry.LocationZ
    local squared=dx*dx+dy*dy+dz*dz
    if frame.Active then entry.DistanceOrigin=origin;entry.DistanceSquared=squared;entry.DistanceMeters=nil end
    return squared
end
function ESPShared.DistanceMetersFrom(entry,origin)
    local squared=ESPShared.DistanceSquaredFrom(entry,origin)
    if ESPShared.Frame.Active and entry.DistanceMeters~=nil then return entry.DistanceMeters end
    local distance=math.sqrt(squared)/100.0
    if ESPShared.Frame.Active then entry.DistanceMeters=distance end
    return distance
end
function ESPShared.InRange(entry,origin,maxRange)
    if not ESPShared.Finite(maxRange) or maxRange<=0 then return ESPShared.DistanceMetersFrom(entry,origin)<=maxRange end
    local squared=ESPShared.DistanceSquaredFrom(entry,origin)
    if squared==math.huge then return false end
    local limit=maxRange*100.0;limit=limit*limit
    -- Preserve the original sqrt/division decision at floating-point boundaries.
    if math.abs(squared-limit)<=math.max(1,limit)*1e-12 then
        return ESPShared.DistanceMetersFrom(entry,origin)<=maxRange
    end
    return squared<limit
end
function ESPShared.ProjectionControllerValid(pc)
    if pc==nil then return false end
    local frame=ESPShared.Frame
    if frame.Active then
        local cached=frame.Controllers[pc]
        if cached~=nil then return cached end
        local valid=g_masterahsanyt_ESPValid(pc);frame.Controllers[pc]=valid;return valid
    end
    return g_masterahsanyt_ESPValid(pc)
end
function ESPShared.CanvasTransform(state)
    local frame=ESPShared.Frame
    local value=frame.Active and frame.Transforms[state]
    local rx,ry,rox,roy=state.CanvasScaleX,state.CanvasScaleY,state.CanvasOffsetX,state.CanvasOffsetY
    if not value or value.RX~=rx or value.RY~=ry or value.ROX~=rox or value.ROY~=roy then
        value=value or (frame.Active and table.remove(frame.TransformPool)) or {}
        value.RX=rx;value.RY=ry;value.ROX=rox;value.ROY=roy
        value.SX=ESPShared.SafeNumber(rx,1,0.00001,100)
        value.SY=ESPShared.SafeNumber(ry,1,0.00001,100)
        value.OX=ESPShared.SafeNumber(rox,0,-1e7,1e7)
        value.OY=ESPShared.SafeNumber(roy,0,-1e7,1e7)
        if frame.Active then frame.Transforms[state]=value end
    end
    return value.SX,value.SY,value.OX,value.OY
end
function ESPShared.AssignProbeVector(vector,x,y,z)
    vector.X=x;vector.Y=y;vector.Z=z
end
function ESPShared.UpdateProbeVector(vector,x,y,z)
    if vector and pcall(ESPShared.AssignProbeVector,vector,x,y,z) then return vector end
    return g_masterahsanyt_ESPV3(x,y,z)
end

-- Validate all cached candidates before display caps. Reuse the list and alive
-- map, so dead/out-of-range actors are pruned on the next scheduled HUD update.
local function g_masterahsanyt_ESPFilterEnemies(list, myLocation, maxRange, alive)
    for key in pairs(alive) do alive[key]=nil end
    local count,kept,realCount,botCount=#list,0,0,0
    maxRange=tonumber(maxRange) or 450.0
    if maxRange~=maxRange or maxRange<=0 or maxRange==math.huge then maxRange=450.0 end
    for i=1,count do
        local item=list[i]
        local character=item and item.Character
        local snapshot=item and item.Key and ESPShared.GetFrameRecord(character)
        if snapshot and snapshot.Alive and ESPShared.Events.Counted(character) then
            local location=snapshot.Location
            local distance=ESPShared.DistanceMetersFrom(snapshot,myLocation)
            if distance<=maxRange then
                item.Distance=distance
                kept=kept+1;list[kept]=item;alive[item.Key]=true
                if item.IsBot then botCount=botCount+1 else realCount=realCount+1 end
            end
        end
    end
    for i=kept+1,count do list[i]=nil end
    return realCount,botCount
end

-- ESP character vertical bounds made by @Masterpiece2025
local function g_masterahsanyt_ESPGetCharacterVerticalBounds(character,cachedLocation)
    if not g_masterahsanyt_ESPValid(character) then return nil, nil end

    local center, halfHeight = nil, nil
    local capsule = nil

    pcall(function()
        if character.GetCapsuleComponent then
            capsule = character:GetCapsuleComponent()
        elseif character.CapsuleComponent then
            capsule = character.CapsuleComponent
        end
    end)

    if capsule and g_masterahsanyt_ESPValid(capsule) then
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

    local cx,cy,cz=ESPShared.VectorValues(center)
    if center and not cx then center=nil end
    if not center then center=cachedLocation end
    if not center then
        pcall(function()
            if character.K2_GetActorLocation then
                center = character:K2_GetActorLocation()
            end
        end)
    end

    if not center then
        pcall(function()
            if Game and Game.GetActorLocation then
                center = Game:GetActorLocation(character)
            end
        end)
    end

    if not cx then cx,cy,cz=ESPShared.VectorValues(center) end
    if not cx then return nil,nil end

    halfHeight=tonumber(halfHeight)
    if not ESPShared.Finite(halfHeight) or halfHeight<10 or halfHeight>200 then
        halfHeight = 85
        pcall(function()
            if character.bIsCrouched then halfHeight = 60 end
            if character.IsProne and character:IsProne() then halfHeight = 25 end
        end)
    end

    return center, halfHeight, cx, cy, cz
end

-- ESP head and feet position made by @Masterpiece2025
local function g_masterahsanyt_ESPGetCharacterBoxLocs(character,cachedLocation)
    local center, halfHeight, x, y, z = g_masterahsanyt_ESPGetCharacterVerticalBounds(character,cachedLocation)
    if not x or not halfHeight then return nil,nil end

    local headLoc = g_masterahsanyt_ESPV3(
        x,
        y,
        z + halfHeight
    )

    local feetLoc = g_masterahsanyt_ESPV3(
        x,
        y,
        z - halfHeight
    )

    return headLoc, feetLoc, center
end

-- ESP head position made by @Masterpiece2025

-- ESP feet position made by @Masterpiece2025

-- Bounded inactive HUD widgets. Records retain native widget/slot structure,
-- never an enemy key, actor, name, delegate, bone mesh or controller. Collapsed
-- widgets stay under the same canvas so reuse does not allocate CanvasSlots.
local ESPWidgetPool={}
do
local shapes={
    Line={Fields={"Widget","Slot","PosVec","SizeVec","VectorReuseDisabled"},Check={"Widget","Slot"},Limit=256},
    NameV2={Fields={"Widget","Text","DistanceText","TextSlot","DistanceSlot","Slot"},
        Check={"Widget","Text","DistanceText","TextSlot","DistanceSlot","Slot"},Limit=16},
    CardV1={Fields={"Widget","Slot","Nodes"},Check={"Widget","Slot"},Limit=64},

    Decor={Fields={"Widget","Slot","Groups"},Check={"Widget","Slot"},Limit=8},
    Header={Fields={"Widget","Slot","Groups"},Check={"Widget","Slot"},Limit=8},
}
local function remove(widget,pool)
    if pool and pool.Remove then pool.Remove(widget)
    elseif widget then pcall(function() widget:RemoveFromParent() end) end
end
local function weight(data)
    local count=1
    if data.Nodes then
        for _ in pairs(data.Nodes) do count=count+1 end
    elseif data.Groups then
        for _,group in pairs(data.Groups) do count=count+#group end
    elseif data.Text then count=data.BottomLine and 6 or 3 end
    return count
end
local function resetGroups(groups)
    if not groups then return end
    for _,group in pairs(groups) do
        for field in pairs(group) do if type(field)~="number" then group[field]=nil end end
        for _,piece in ipairs(group) do
            local w,s,pv,sv,disabled=piece.Widget,piece.Slot,piece.PosVec,piece.SizeVec,piece.VectorReuseDisabled
            for field in pairs(piece) do piece[field]=nil end
            piece.Widget,piece.Slot,piece.PosVec,piece.SizeVec,piece.VectorReuseDisabled=w,s,pv,sv,disabled
            piece.Visible=false
        end
    end
end
function ESPWidgetPool.New(capacity)
    return {Bins={},Canvas=nil,Enabled=true,Weight=0,Capacity=capacity,
        Reused=0,Released=0,Created=0,Discarded=0}
end
ESPWidgetPool.V2=ESPWidgetPool.New(1024)
ESPWidgetPool.V1=ESPWidgetPool.New(1536)
function ESPWidgetPool.Flush(pool)
    for kind,bin in pairs(pool.Bins) do
        for i=#bin,1,-1 do
            local item=bin[i];bin[i]=nil;remove(item.Widget,pool)
            for key in pairs(item) do item[key]=nil end
        end
        pool.Bins[kind]=nil
    end
    pool.Canvas=nil;pool.Weight=0
end
function ESPWidgetPool.Tag(pool,kind,canvas,data)
    if pool.Canvas~=canvas then ESPWidgetPool.Flush(pool);pool.Canvas=canvas end
    data.PoolOwner=pool;data.PoolKind=kind;data.PoolCanvas=canvas
    pool.Created=pool.Created+1
    return data
end
function ESPWidgetPool.Release(data)
    if data.PoolReleased then return true end
    local pool,kind,canvas=data.PoolOwner,data.PoolKind,data.PoolCanvas
    if not pool or not pool.Enabled or pool.Canvas~=canvas or data.Broken
        or not g_masterahsanyt_ESPValid(data.Widget) then return false end
    local shape=shapes[kind]
    if not shape then return false end
    local bin=pool.Bins[kind]
    if not bin then bin={};pool.Bins[kind]=bin end
    local cost=weight(data)
    if #bin>=shape.Limit or pool.Weight+cost>pool.Capacity then return false end
    local ok=pcall(function()
        data.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
        if data.Nodes then
            for _,node in pairs(data.Nodes) do
                if node.Broken then error("POOL_BROKEN_CARD") end
                if node.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)==false then error("POOL_HIDE_FAILED") end
                if node.Kind=="TextBlock" and node.Widget:SetText("")==false then error("POOL_TEXT_FAILED") end
            end
        end
        if data.Text then data.Text:SetText("") end
        if data.DistanceText then data.DistanceText:SetText("") end
        if data.Groups then
            for _,group in pairs(data.Groups) do
                for _,piece in ipairs(group) do
                    if piece.Broken then error("POOL_BROKEN_PIECE") end
                    if piece.Visible~=false then
                        piece.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
                    end
                end
            end
        end
    end)
    if not ok then return false end
    resetGroups(data.Groups)
    if data.Nodes and data.Nodes.FlagImage and data.Nodes.FlagImage.AsyncPath then
        local flag=data.Nodes.FlagImage.Widget
        remove(flag,pool)
        local ok,parent=pcall(function() return flag:GetParent() end)
        if not ok or parent~=nil then return false end
        data.Nodes.FlagImage=nil
        cost=weight(data)
    end
    if data.Nodes then
        for _,node in pairs(data.Nodes) do
            local widget,slot,kind,pv,sv,disabled=node.Widget,node.Slot,node.Kind,node.PosVec,node.SizeVec,node.VectorReuseDisabled
            for field in pairs(node) do node[field]=nil end
            node.Widget,node.Slot,node.Kind,node.PosVec,node.SizeVec,node.VectorReuseDisabled=widget,slot,kind,pv,sv,disabled
            node.Visible=false
        end
    end
    local item={Weight=cost}
    for _,field in ipairs(shape.Fields) do item[field]=data[field] end
    -- Clear even caller-added fields so a reference never follows another enemy.
    for field in pairs(data) do data[field]=nil end
    data.PoolReleased=true
    bin[#bin+1]=item;pool.Weight=pool.Weight+cost;pool.Released=pool.Released+1
    return true
end
function ESPWidgetPool.Take(pool,kind,canvas)
    if pool.Canvas~=canvas then ESPWidgetPool.Flush(pool);pool.Canvas=canvas end
    if not pool.Enabled then return nil end
    local shape,bin=shapes[kind],pool.Bins[kind]
    if not shape or not bin then return nil end
    while #bin>0 do
        local item=bin[#bin];bin[#bin]=nil;pool.Weight=pool.Weight-item.Weight
        local valid=true
        for _,field in ipairs(shape.Check) do
            if not g_masterahsanyt_ESPValid(item[field]) then valid=false;break end
        end
        if valid and item.Nodes then
            for _,node in pairs(item.Nodes) do
                if not g_masterahsanyt_ESPValid(node.Widget) or not g_masterahsanyt_ESPValid(node.Slot) then valid=false;break end
            end
        end
        if valid and item.Groups then
            for _,group in pairs(item.Groups) do
                for _,piece in ipairs(group) do
                    if not g_masterahsanyt_ESPValid(piece.Widget) or not g_masterahsanyt_ESPValid(piece.Slot) then
                        valid=false;break
                    end
                end
                if not valid then break end
            end
        end
        -- Missing bindings or externally detached/reparented widgets fall back
        -- to normal construction, rather than assuming their CanvasSlot works.
        if valid then
            local ok,parent=pcall(function() return item.Widget:GetParent() end)
            valid=ok and parent==canvas
        end
        if valid then
            local data={PoolOwner=pool,PoolKind=kind,PoolCanvas=canvas}
            for _,field in ipairs(shape.Fields) do data[field]=item[field] end
            resetGroups(data.Groups)
            pool.Reused=pool.Reused+1
            return data
        end
        remove(item.Widget,pool);pool.Discarded=pool.Discarded+1
        for key in pairs(item) do item[key]=nil end
    end
    return nil
end
end

-- ESP widget destroy made by @Masterpiece2025
local function g_masterahsanyt_ESPDestroyWidgetData(data)
    if not data then return end
    if ESPWidgetPool.Release(data) then return end
    for _, field in ipairs({"Widget", "Container", "Text", "DistanceText"}) do
        local widget=data[field]
        if g_masterahsanyt_ESPValid(widget) then
            pcall(function() widget:RemoveFromParent() end)
        end
    end
end

-- ESP widget cleanup made by @Masterpiece2025
local function g_masterahsanyt_ESPResetWidgets()
    ESPWidgetPool.V2.Enabled=false
    for _, data in pairs(g_masterahsanyt_ShotESP.Lines) do g_masterahsanyt_ESPDestroyWidgetData(data) end
    for _, data in pairs(g_masterahsanyt_ShotESP.Names) do g_masterahsanyt_ESPDestroyWidgetData(data) end
    for _, group in pairs(g_masterahsanyt_ShotESP.Boxes) do for _,data in ipairs(group) do g_masterahsanyt_ESPDestroyWidgetData(data) end end
    for _, group in pairs(g_masterahsanyt_ShotESP.HealthBars) do for _,data in ipairs(group) do g_masterahsanyt_ESPDestroyWidgetData(data) end end
    for _, group in pairs(g_masterahsanyt_ShotESP.Skeletons) do for _,data in ipairs(group) do g_masterahsanyt_ESPDestroyWidgetData(data) end end
    for _, group in pairs(g_masterahsanyt_ShotESP.Headers) do for _,data in ipairs(group) do g_masterahsanyt_ESPDestroyWidgetData(data) end end
    for _, group in pairs(g_masterahsanyt_ShotESP.Footers) do for _,data in ipairs(group) do g_masterahsanyt_ESPDestroyWidgetData(data) end end
    g_masterahsanyt_ShotESP.Lines = {}
    g_masterahsanyt_ShotESP.Names = {}
    g_masterahsanyt_ShotESP.Boxes = {}
    g_masterahsanyt_ShotESP.HealthBars = {}
    g_masterahsanyt_ShotESP.Skeletons = {}
    for _, data in pairs(g_masterahsanyt_ShotESP.HeaderRoots) do g_masterahsanyt_ESPDestroyWidgetData(data) end
    g_masterahsanyt_ShotESP.HeaderRoots = {}
    g_masterahsanyt_ShotESP.Headers = {}
    g_masterahsanyt_ShotESP.Footers = {}
    g_masterahsanyt_ShotESP.BuildStage = {}
    g_masterahsanyt_ShotESP.BoneNameCache = {}
    for _,data in pairs(g_masterahsanyt_ShotESP.Decorations) do g_masterahsanyt_ESPDestroyWidgetData(data) end
    g_masterahsanyt_ShotESP.Decorations = {}
    if g_masterahsanyt_ShotESP.Counter then g_masterahsanyt_ESPDestroyWidgetData(g_masterahsanyt_ShotESP.Counter) end
    g_masterahsanyt_ShotESP.Counter = nil
    g_masterahsanyt_ShotESP.Canvas = nil
    g_masterahsanyt_ShotESP.RootUI = nil
    g_masterahsanyt_ShotESP.Enemies = {}
    g_masterahsanyt_ShotESP.Active = {}
    g_masterahsanyt_ShotESP.Alive = {}
    g_masterahsanyt_ShotESP.BoneMeshes = {}
    g_masterahsanyt_ShotESP.BonePoints = {}
    g_masterahsanyt_ShotESP.TemplateFont = nil
    g_masterahsanyt_ShotESP.TemplateFontObject = nil
    g_masterahsanyt_ShotESP.TemplateTypeface = nil
    g_masterahsanyt_ShotESP.TemplateColorAndOpacity = nil
    g_masterahsanyt_ShotESP.ViewportW, g_masterahsanyt_ShotESP.ViewportH = nil, nil
    g_masterahsanyt_ShotESP.RawViewportW, g_masterahsanyt_ShotESP.RawViewportH = nil, nil
    g_masterahsanyt_ShotESP.TracerOrigin = nil
    g_masterahsanyt_ShotESP.LastScanClock = -999.0
    g_masterahsanyt_ShotESP.LastTransformClock = -999.0
    g_masterahsanyt_ShotESP.LastController = nil
    g_masterahsanyt_ShotESP.LastPawn = nil
    g_masterahsanyt_ShotESP._BotCache = {}
    g_masterahsanyt_ShotESP.RealCount = 0
    g_masterahsanyt_ShotESP.BotCount = 0
    ESPWidgetPool.Flush(ESPWidgetPool.V2)
    ESPWidgetPool.V2.Enabled=true
end

-- ESP HUD canvas made by @Masterpiece2025
local function g_masterahsanyt_ESPGetCanvas()
    if g_masterahsanyt_ESPValid(g_masterahsanyt_ShotESP.Canvas) then return g_masterahsanyt_ShotESP.Canvas end
    local root = nil
    pcall(function()
        local InGameUITools = require("GameLua.Mod.BaseMod.Common.UI.InGameUITools")
        if InGameUITools and InGameUITools.GetMainControlBaseUI then root = InGameUITools.GetMainControlBaseUI() end
    end)
    if not g_masterahsanyt_ESPValid(root) then return nil end
    g_masterahsanyt_ShotESP.RootUI = root
    local canvas = nil
    pcall(function()
        if g_masterahsanyt_ESPValid(root.CanvasPanel_0) then canvas = root.CanvasPanel_0
        elseif g_masterahsanyt_ESPValid(root.CanvasPanel_42) then canvas = root.CanvasPanel_42 end
    end)
    if g_masterahsanyt_ESPValid(canvas) then g_masterahsanyt_ShotESP.Canvas = canvas return canvas end
    return nil
end

-- Discover a valid FontObject from existing HUD TextBlocks so dynamic TextBlocks always render glyphs
local function g_masterahsanyt_ESPGetTemplateTextStyle()
    if g_masterahsanyt_ESPValid(g_masterahsanyt_ShotESP.TemplateFontObject) then
        return g_masterahsanyt_ShotESP.TemplateFont
    end

    local visited = 0
    local function scanWidget(w, depth)
        if not w or depth > 6 or visited > 250 then return false end
        if not g_masterahsanyt_ESPValid(w) then return false end
        visited = visited + 1

        local found = false
        pcall(function()
            if w.SetText and w.SetFont and w.Font then
                local f = w.Font
                if f and g_masterahsanyt_ESPValid(f.FontObject) then
                    g_masterahsanyt_ShotESP.TemplateFont = f
                    g_masterahsanyt_ShotESP.TemplateFontObject = f.FontObject
                    pcall(function() g_masterahsanyt_ShotESP.TemplateTypeface = f.TypefaceFontName end)
                    pcall(function() g_masterahsanyt_ShotESP.TemplateColorAndOpacity = w.ColorAndOpacity end)
                    found = true
                end
            end
        end)
        if found then return true end

        local childCount = 0
        pcall(function() if w.GetChildrenCount then childCount = tonumber(w:GetChildrenCount()) or 0 end end)
        for i = 0, childCount - 1 do
            local child = nil
            pcall(function() child = w:GetChildAt(i) end)
            if child and scanWidget(child, depth + 1) then return true end
        end

        local treeRoot = nil
        pcall(function() if w.WidgetTree and w.WidgetTree.RootWidget then treeRoot = w.WidgetTree.RootWidget end end)
        if treeRoot and treeRoot ~= w and scanWidget(treeRoot, depth + 1) then return true end

        return false
    end

    local canvas = g_masterahsanyt_ESPGetCanvas()
    if canvas then scanWidget(canvas, 0) end
    if not g_masterahsanyt_ESPValid(g_masterahsanyt_ShotESP.TemplateFontObject) and g_masterahsanyt_ESPValid(g_masterahsanyt_ShotESP.RootUI) then
        scanWidget(g_masterahsanyt_ShotESP.RootUI, 0)
    end

    if not g_masterahsanyt_ESPValid(g_masterahsanyt_ShotESP.TemplateFontObject) and slua and slua.loadObject then
        for _, path in ipairs({
            "/Engine/EngineFonts/Roboto.Roboto",
            "/Engine/EngineFonts/Roboto",
            "/Engine/EngineFonts/DroidSansFallback.DroidSansFallback"
        }) do
            local ok, obj = pcall(slua.loadObject, path)
            if ok and g_masterahsanyt_ESPValid(obj) then
                g_masterahsanyt_ShotESP.TemplateFontObject = obj
                break
            end
        end
    end

    return g_masterahsanyt_ShotESP.TemplateFont
end

-- ESP viewport size made by @Masterpiece2025
local function g_masterahsanyt_ESPViewport(pc)
    local w,h
    local function take(x,y)
        x,y=tonumber(x),tonumber(y)
        if ESPShared.Finite(x) and ESPShared.Finite(y) and x>200 and y>200 and x<1e6 and y<1e6 then w,h=x,y;return true end
    end
    pcall(function()
        if WidgetLayoutLibrary and WidgetLayoutLibrary.GetViewportSize then
            local v=WidgetLayoutLibrary.GetViewportSize(pc);if v then take(v.X,v.Y) end
        end
    end)
    if not w then pcall(function() local x,y=pc:GetViewportSize();take(x,y) end) end
    if not w then pcall(function() local v=g_masterahsanyt_ESPV2(0,0);pc:GetViewportSize(v);take(v.X,v.Y) end) end
    if not w then pcall(function() local x,y=pc:GetViewportSize(0,0);take(x,y) end) end
    return w or 2400.0,h or 1080.0
end

-- ESP HUD canvas made by @Masterpiece2025
local function g_masterahsanyt_ESPGetCanvasLocalSize()
    local canvas = g_masterahsanyt_ESPGetCanvas()
    if not g_masterahsanyt_ESPValid(canvas) then return nil, nil end

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

        if size and ESPShared.Finite(size.X) and ESPShared.Finite(size.Y) and size.X > 100 and size.Y > 100 then
            cw, ch = tonumber(size.X), tonumber(size.Y)
        end
    end)

    return cw, ch
end

-- ESP canvas transform made by @Masterpiece2025
local function g_masterahsanyt_ESPUpdateCanvasTransform(pc)
    local canvas = g_masterahsanyt_ESPGetCanvas()
    if not g_masterahsanyt_ESPValid(canvas) then return false end

    local calibrated = false

    pcall(function()
        if SlateBlueprintLibrary and SlateBlueprintLibrary.AbsoluteToLocal then
            local geo = canvas:GetCachedGeometry()
            if geo then
                local p0 = SlateBlueprintLibrary.AbsoluteToLocal(
                    geo,
                    g_masterahsanyt_ESPV2(0, 0)
                )
                local p1 = SlateBlueprintLibrary.AbsoluteToLocal(
                    geo,
                    g_masterahsanyt_ESPV2(100, 100)
                )

                if p0 and p1
                    and ESPShared.Finite(p0.X) and ESPShared.Finite(p0.Y)
                    and ESPShared.Finite(p1.X) and ESPShared.Finite(p1.Y)
                    and math.abs(p0.X)<1e7 and math.abs(p0.Y)<1e7
                    and p1.X>p0.X and p1.Y>p0.Y
                    and p1.X-p0.X<10000 and p1.Y-p0.Y<10000 then

                    g_masterahsanyt_ShotESP.CanvasScaleX = (p1.X - p0.X) / 100.0
                    g_masterahsanyt_ShotESP.CanvasScaleY = (p1.Y - p0.Y) / 100.0
                    g_masterahsanyt_ShotESP.CanvasOffsetX = p0.X
                    g_masterahsanyt_ShotESP.CanvasOffsetY = p0.Y
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
                if ESPShared.Finite(s) and s>=0.01 and s<=100 then
                    scale = s
                end
            end
        end)

        g_masterahsanyt_ShotESP.CanvasScaleX = 1.0 / scale
        g_masterahsanyt_ShotESP.CanvasScaleY = 1.0 / scale
        g_masterahsanyt_ShotESP.CanvasOffsetX = 0.0
        g_masterahsanyt_ShotESP.CanvasOffsetY = 0.0
    end

    return true
end

-- ESP world to HUD projection made by @Masterpiece2025
local function g_masterahsanyt_ESPProject(pc,worldLoc)
    local frame=ESPShared.Frame
    -- Skeleton results own their output; only the immediate raw scratch is shared.
    if not frame.RawPixel then frame.RawPixel=g_masterahsanyt_ESPV2(0,0) end
    local pix=ESPShared.ProjectRaw(pc,worldLoc,frame.Active and frame.RawPixel or nil)
    if not pix then return nil end
    local sx,sy,ox,oy=ESPShared.CanvasTransform(g_masterahsanyt_ShotESP)
    return g_masterahsanyt_ESPV2(pix.X*sx+ox,pix.Y*sy+oy)
end

-- Fresh projections deliberately avoid screen-space lerp: it adds camera lag
-- and desynchronizes the capsule outline from the independently projected bones.

local function g_masterahsanyt_ESPActorOnScreen(head,feet,minX,minY,maxX,maxY)
    local function usable(p)
        return p and ESPShared.Finite(p.X) and ESPShared.Finite(p.Y)
    end
    head=usable(head) and head or nil;feet=usable(feet) and feet or nil
    if not head and not feet then return false end
    head=head or feet;feet=feet or head
    return math.max(head.X,feet.X)>=minX and math.min(head.X,feet.X)<=maxX
        and math.max(head.Y,feet.Y)>=minY and math.min(head.Y,feet.Y)<=maxY
end

function ESPShared.ViewSize(pc)
    local now=ESPShared.Frame.Active and ESPShared.Frame.Now or g_masterahsanyt_ESPNow()
    if not ESPShared.Frame.Active or ESPShared.Frame.ViewPC~=pc or now<ESPShared.Frame.ViewAt or now-ESPShared.Frame.ViewAt>=0.25 then
        ESPShared.Frame.ViewW,ESPShared.Frame.ViewH=g_masterahsanyt_ESPViewport(pc)
        ESPShared.Frame.ViewPC=pc;ESPShared.Frame.ViewAt=now
    end
    return ESPShared.Frame.ViewW,ESPShared.Frame.ViewH
end
function ESPShared.NativeProject(pc,location,pix)
    return pc:ProjectWorldLocationToScreen(location,pix,true)
end
function ESPShared.ActorProbeLocations(actor,entry)
    local center,height,x,y,z=g_masterahsanyt_ESPGetCharacterVerticalBounds(actor,entry.Location)
    if not x or not height then return nil,nil end
    entry.WorldHead=ESPShared.UpdateProbeVector(entry.WorldHead,x,y,z+height)
    entry.WorldFeet=ESPShared.UpdateProbeVector(entry.WorldFeet,x,y,z-height)
    return entry.WorldHead,entry.WorldFeet
end
function ESPShared.ProjectRaw(pc,location,pix)
    if not ESPShared.VectorValues(location) or not ESPShared.ProjectionControllerValid(pc) then return nil end
    pix=pix or g_masterahsanyt_ESPV2(0,0);pix.X=0;pix.Y=0
    local ok,result,out=pcall(ESPShared.NativeProject,pc,location,pix)
    if out then pix=out end
    local good,x,y=pcall(function() return tonumber(pix.X),tonumber(pix.Y) end)
    if not ok or not good or not ESPShared.Finite(x) or not ESPShared.Finite(y) or math.abs(x)>=1e7 or math.abs(y)>=1e7 then return nil,"unavailable" end
    if result==false or result==0 then return nil,"offscreen" end
    if result~=true and result~=1 and not (result==nil and (x~=0 or y~=0)) then return nil,"unavailable" end
    return pix,"visible"
end
function ESPShared.ProbeActor(pc,actor)
    local entry=ESPShared.GetFrameRecord(actor)
    if entry.Projected and entry.PC==pc then return entry end
    entry.Projected=true;entry.PC=pc;entry.OnScreen=false;entry.ProjectionReason="unavailable"
    if not entry.Alive or not entry.Location then return entry end
    local ok,head,feet=pcall(ESPShared.ActorProbeLocations,actor,entry)
    if not ok then return entry end
    entry.RawHead=entry.RawHead or g_masterahsanyt_ESPV2(0,0)
    entry.RawFeet=entry.RawFeet or g_masterahsanyt_ESPV2(0,0)
    local hp,hr=ESPShared.ProjectRaw(pc,head,entry.RawHead)
    local fp,fr=ESPShared.ProjectRaw(pc,feet,entry.RawFeet)
    if hp then entry.RawHead=hp end;if fp then entry.RawFeet=fp end
    entry.HasHead=hp~=nil;entry.HasFeet=fp~=nil
    local width,height=ESPShared.ViewSize(pc)
    entry.OnScreen=g_masterahsanyt_ESPActorOnScreen(hp,fp,0,0,width,height)
    if entry.OnScreen then entry.ProjectionReason="visible"
    elseif hp or fp or hr=="offscreen" or fr=="offscreen" then entry.ProjectionReason="offscreen" end
    return entry
end
function ESPShared.CanvasBounds(pc,state)
    local width,height=ESPShared.ViewSize(pc)
    local sx,sy,ox,oy=ESPShared.CanvasTransform(state)
    local maxX,maxY=ox+width*sx,oy+height*sy
    if ESPShared.Finite(state.ViewportW) and state.ViewportW>1 then maxX=math.min(maxX,ox+state.ViewportW) end
    if ESPShared.Finite(state.ViewportH) and state.ViewportH>1 then maxY=math.min(maxY,oy+state.ViewportH) end
    return ox,oy,maxX,maxY
end
function ESPShared.ProjectActor(pc,actor,state)
    local entry=ESPShared.ProbeActor(pc,actor)
    if not entry.OnScreen then return nil,nil,false,entry.ProjectionReason end
    local sx,sy,ox,oy=ESPShared.CanvasTransform(state)
    local prefix=state==g_masterahsanyt_ShotESP and "V2" or "V1"
    local function convert(raw,field)
        local p=entry[field] or g_masterahsanyt_ESPV2(0,0);entry[field]=p
        p.X=raw.X*sx+ox;p.Y=raw.Y*sy+oy;return p
    end
    local head=entry.HasHead and convert(entry.RawHead,prefix.."Head") or nil
    local feet=entry.HasFeet and convert(entry.RawFeet,prefix.."Feet") or nil
    local minX,minY,maxX,maxY=ESPShared.CanvasBounds(pc,state)
    local visible=g_masterahsanyt_ESPActorOnScreen(head,feet,minX,minY,maxX,maxY)
    return head,feet,visible,visible and "visible" or "offscreen"
end


-- ESP text setter with FText conversion fallback

-- ESP font style made by @Masterpiece2025
local function g_masterahsanyt_ESPSetFont(textWidget, size)
    if not g_masterahsanyt_ESPValid(textWidget) then return end
    g_masterahsanyt_ESPGetTemplateTextStyle()
    pcall(function()
        local f = textWidget.Font or g_masterahsanyt_ShotESP.TemplateFont
        if f then
            if g_masterahsanyt_ESPValid(g_masterahsanyt_ShotESP.TemplateFontObject) then
                pcall(function() f.FontObject = g_masterahsanyt_ShotESP.TemplateFontObject end)
            end
            if g_masterahsanyt_ShotESP.TemplateTypeface then
                pcall(function() f.TypefaceFontName = g_masterahsanyt_ShotESP.TemplateTypeface end)
            end
            pcall(function() f.Size = size end)
            if f.OutlineSettings then
                pcall(function()
                    local os = f.OutlineSettings
                    os.OutlineSize = 0
                    os.OutlineColor = ESP_TEXT_CLEAR
                    f.OutlineSettings = os
                end)
            end
            pcall(function() textWidget:SetFont(f) end)
            pcall(function() textWidget.Font = f end)
        end
        if textWidget.SetShadowOffset then
            pcall(function() textWidget:SetShadowOffset(g_masterahsanyt_ESPV2(0.0,0.0)) end)
        end
        if textWidget.SetShadowColorAndOpacity then
            pcall(function() textWidget:SetShadowColorAndOpacity(ESP_TEXT_CLEAR) end)
        end
    end)
end

-- ESP text color made by @Masterpiece2025
local function g_masterahsanyt_ESPSetTextColor(textWidget, color)
    if not g_masterahsanyt_ESPValid(textWidget) or not color then return end
    local applied = false
    pcall(function()
        local sc = textWidget.ColorAndOpacity or g_masterahsanyt_ShotESP.TemplateColorAndOpacity or (SlateColor and SlateColor())
        if sc then
            sc.SpecifiedColor = color
            pcall(function() sc.ColorUseRule = 0 end)
            local check = sc.SpecifiedColor
            if check and tonumber(check.A) and tonumber(check.A) > 0 then
                textWidget:SetColorAndOpacity(sc)
                pcall(function() textWidget.ColorAndOpacity = sc end)
                applied = true
            end
        end
    end)
    if not applied then
        pcall(function() textWidget:SetColorAndOpacity(color) end)
    end
    pcall(function() if textWidget.SetOpacity then textWidget:SetOpacity(1.0) end end)
    pcall(function() if textWidget.SetRenderOpacity then textWidget:SetRenderOpacity(1.0) end end)
end

-- ESP line widget made by @Masterpiece2025
local function g_masterahsanyt_ESPCreateLine(color,parent)
    local canvas = parent or g_masterahsanyt_ESPGetCanvas()
    if not g_masterahsanyt_ESPValid(canvas) then return nil end
    local budget = g_masterahsanyt_ShotESP.BuildRemaining
    if budget ~= nil then
        if budget <= 0 then return nil end
        g_masterahsanyt_ShotESP.BuildRemaining = budget - 1
    end
    local pooled=canvas==g_masterahsanyt_ShotESP.Canvas and ESPWidgetPool.Take(ESPWidgetPool.V2,"Line",canvas)
    if pooled then
        local ok=pcall(function() pooled.Widget:SetBrushColor(color) end)
        if ok then pooled.Visible=false;return pooled end
        pcall(function() pooled.Widget:RemoveFromParent() end)
    end
    local border = nil
    pcall(function() border = CGame:NewObjectFromPath("/Script/UMG.Border", canvas) end)
    if not g_masterahsanyt_ESPValid(border) then return nil end
    pcall(function()
        border:SetBrushColor(color)
        border:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        border:SetRenderTransformPivot(g_masterahsanyt_ESPV2(0.0, 0.5))
    end)
    local slot = nil
    pcall(function() slot = canvas:AddChildToCanvas(border) end)
    if not slot then g_masterahsanyt_ESPDestroyWidgetData({Widget=border}) return nil end
    pcall(function() slot:SetAutoSize(false) slot:SetZOrder(30) end)
    local data={Widget=border, Slot=slot}
    if canvas==g_masterahsanyt_ShotESP.Canvas then ESPWidgetPool.Tag(ESPWidgetPool.V2,"Line",canvas,data) end
    return data
end

-- ESP line made by @Masterpiece2025
local function g_masterahsanyt_ESPDrawLine(data, x1, y1, x2, y2, thickness)
    if not data or not data.Widget or not data.Slot then return false end
    local dx, dy = x2-x1, y2-y1
    local len = math.sqrt(dx*dx + dy*dy)
    if len < 1 then
        if data.Visible ~= false then
            pcall(function() data.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
            data.Visible = false
        end
        return false
    end
    local angle = ((math.atan2 and math.atan2(dy, dx)) or math.atan(dy, dx)) * 180.0 / math.pi
    local unchanged=data.Visible==true and data.X1 and
        math.abs(data.X1-x1)<0.25 and math.abs(data.Y1-y1)<0.25 and
        math.abs(data.X2-x2)<0.25 and math.abs(data.Y2-y2)<0.25 and
        math.abs((data.Thickness or 0)-thickness)<0.05
    if unchanged then return true end
    -- Reuse native transform values after the first draw. Older bindings
    -- that reject mutable structs fall back once to the original setter path.
    local setterOK=pcall(function()
        if data.VectorReuseDisabled then
            data.Slot:SetPosition(g_masterahsanyt_ESPV2(x1, y1 - thickness*0.5))
            data.Slot:SetSize(g_masterahsanyt_ESPV2(len, thickness))
        else
            data.PosVec=data.PosVec or g_masterahsanyt_ESPV2(x1, y1 - thickness*0.5)
            data.SizeVec=data.SizeVec or g_masterahsanyt_ESPV2(len, thickness)
            data.PosVec.X=x1;data.PosVec.Y=y1-thickness*0.5
            data.SizeVec.X=len;data.SizeVec.Y=thickness
            data.Slot:SetPosition(data.PosVec)
            data.Slot:SetSize(data.SizeVec)
        end
        data.Widget:SetRenderAngle(angle)
        if not data.Visible then data.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end
    end)
    if not setterOK and not data.VectorReuseDisabled then
        data.VectorReuseDisabled=true;data.PosVec=nil;data.SizeVec=nil
        setterOK=pcall(function()
            data.Slot:SetPosition(g_masterahsanyt_ESPV2(x1, y1 - thickness*0.5))
            data.Slot:SetSize(g_masterahsanyt_ESPV2(len, thickness))
            data.Widget:SetRenderAngle(angle)
            if not data.Visible then data.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end
        end)
    end
    if not setterOK then data.Broken=true return false end
    data.Broken=false
    data.X1,data.Y1,data.X2,data.Y2,data.Thickness=x1,y1,x2,y2,thickness
    data.Visible=true
    return true
end

-- ESP widget hide made by @Masterpiece2025
local function g_masterahsanyt_ESPHide(data)
    if data and data.Visible~=false and data.Widget then
        local ok=pcall(function() data.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
        if not ok then data.Broken=true end
        data.Visible=false
    end
end

local function g_masterahsanyt_ESPDestroyGroup(group)
    if not group then return end
    for _, data in ipairs(group) do g_masterahsanyt_ESPDestroyWidgetData(data) end
end

-- Check native widget validity at discovery cadence; failed setters mark a
-- piece broken immediately. This avoids an IsValid bridge call per piece/frame.
local function g_masterahsanyt_ESPGroupHealthy(group)
    if not group then return false end
    local now = g_masterahsanyt_ShotESP.Now
    local validate = not group.ValidatedAt or now < group.ValidatedAt or now-group.ValidatedAt >= 0.35
    for _, data in ipairs(group) do
        if data.Broken or (validate and not g_masterahsanyt_ESPValid(data.Widget)) then return false end
    end
    if validate then group.ValidatedAt = now end
    return true
end

-- Keep partial groups across ticks; budgeted creation prevents first-visibility spikes.
local function g_masterahsanyt_ESPLineGroup(registry, key, count, color, parent)
    local group = registry[key]
    if group and not g_masterahsanyt_ESPGroupHealthy(group) then
        g_masterahsanyt_ESPDestroyGroup(group)
        group = nil
    end
    if not group or #group > count then
        g_masterahsanyt_ESPDestroyGroup(group)
        group = {}
        registry[key] = group
    end
    while #group < count do
        local data = g_masterahsanyt_ESPCreateLine(color, parent)
        if not data then return nil end
        group[#group + 1] = data
        g_masterahsanyt_ESPHide(data)
    end
    return group
end

-- Existing geometry and widgets are reused. Stable identity performs no native
-- color setters; failed brush assignments remain eligible for retry.
local function g_masterahsanyt_ESPApplyGroupTheme(group,theme,kind)
    if not group or group.ThemeKey==theme.Key then return end
    local ok=pcall(function()
        for i,piece in ipairs(group) do
            local color=theme.Main
            if kind=="Header" then
                if i>=23 then color=theme.Background
                elseif i>=9 and i<=12 then color=theme.Light end
            elseif kind=="Arcs" then
                if i>=11 and i<=20 then color=theme.Light end
            elseif kind=="Footer" then
                if i<=4 then color=theme.Light end
            elseif kind=="Health" then
                if i==1 then color=theme.Background
                elseif i>=10 then color=theme.Light
                else color=theme.Empty end
            end
            piece.Widget:SetBrushColor(color)
        end
    end)
    if ok then group.ThemeKey=theme.Key end
end

local function g_masterahsanyt_ESPHideGroup(group)
    if not group then return end
    for _, data in ipairs(group) do g_masterahsanyt_ESPHide(data) end
end

local function g_masterahsanyt_ESPHideDetailedEnemy(key)
    g_masterahsanyt_ESPHide(g_masterahsanyt_ShotESP.Lines[key])
    g_masterahsanyt_ESPHideGroup(g_masterahsanyt_ShotESP.Boxes[key])
    g_masterahsanyt_ESPHideGroup(g_masterahsanyt_ShotESP.HealthBars[key])
    g_masterahsanyt_ESPHideGroup(g_masterahsanyt_ShotESP.Skeletons[key])
    g_masterahsanyt_ESPHideGroup(g_masterahsanyt_ShotESP.Headers[key])
    local decor=g_masterahsanyt_ShotESP.Decorations[key]
    if decor and decor.Visible~=false then pcall(function() decor.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end) decor.Visible=false end
end

local g_masterahsanyt_ESPHealthRatio

local function g_masterahsanyt_ESPSetGroupVisible(group,visible)
    if not group or group.GroupVisible==visible then return end
    for _,data in ipairs(group) do
        if visible then
            pcall(function() data.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
            data.Visible=true
        else g_masterahsanyt_ESPHide(data) end
    end
    group.GroupVisible=visible
end

local function g_masterahsanyt_ESPCreateDecorationRoot(poolKind)
    local canvas=g_masterahsanyt_ESPGetCanvas()
    if not g_masterahsanyt_ESPValid(canvas) then return nil end
    poolKind=poolKind or "Decor"
    local pooled=ESPWidgetPool.Take(ESPWidgetPool.V2,poolKind,canvas)
    if pooled then
        local ok=pcall(function()
            pooled.Slot:SetZOrder(poolKind=="Header" and 30 or 29)
            pooled.Widget:SetRenderScale(g_masterahsanyt_ESPV2(1.0,1.0))
            pooled.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        end)
        if ok then pooled.Visible=true;return pooled end
        pcall(function() pooled.Widget:RemoveFromParent() end)
    end
    local root=nil
    pcall(function() root=CGame:NewObjectFromPath("/Script/UMG.CanvasPanel",canvas) end)
    if not g_masterahsanyt_ESPValid(root) then return nil end
    local slot=nil
    pcall(function() slot=canvas:AddChildToCanvas(root) end)
    if not slot then g_masterahsanyt_ESPDestroyWidgetData({Widget=root}) return nil end
    pcall(function()
        slot:SetAutoSize(false)
        slot:SetSize(g_masterahsanyt_ESPV2(1000.0,1400.0))
        slot:SetZOrder(29)
        root:SetRenderTransformPivot(g_masterahsanyt_ESPV2(0.0,0.0))
        root:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
    end)
    return ESPWidgetPool.Tag(ESPWidgetPool.V2,poolKind,canvas,{Widget=root,Slot=slot,Groups={},Visible=true})
end

local function g_masterahsanyt_ESPDecorGroup(data,name,count,color)
    return g_masterahsanyt_ESPLineGroup(data.Groups,name,count,color,data.Widget)
end


local function g_masterahsanyt_ESPBuildArcs(data)
    local group=g_masterahsanyt_ESPDecorGroup(data,"Arcs",26,ESP_REAL)
    if not group then return nil end
    if group.Built then return group end
    local cx,cy,half,ry=500.0,385.0,268.0,180.0
    -- Progressive stroke curve: 2x at both corners, 5x at the center.
    -- Red base thickness is 3.0; white base thickness is 1.5.
    local redThickness={6.0,10.5,15.0,10.5,6.0}
    local whiteThickness={3.0,5.25,7.5,5.25,3.0}
    local index=1
    for _,side in ipairs({-1,1}) do
        local previous=nil
        for step=0,5 do
            local angle=(-70+step*28)*math.pi/180
            local p={X=cx+side*half*math.cos(angle),Y=cy+ry*math.sin(angle)}
            if previous then
                g_masterahsanyt_ESPDrawLine(group[index],previous.X,previous.Y,p.X,p.Y,redThickness[step])
                index=index+1
            end
            previous=p
        end
    end
    local tickIndex=21
    for _,side in ipairs({-1,1}) do
        local x=cx+side*half*1.02
        for _,oy in ipairs({-24.0,0.0,24.0}) do
            g_masterahsanyt_ESPDrawLine(group[tickIndex],x-side*5.0,cy+oy,x+side*2.0,cy+oy,2.2)
            tickIndex=tickIndex+1
        end
    end
    local ih,ir=half*.82,ry*.76
    for _,side in ipairs({-1,1}) do
        local previous=nil
        for step=0,5 do
            local angle=(-54+step*(108/5))*math.pi/180
            local p={X=cx+side*ih*math.cos(angle),Y=cy+ir*math.sin(angle)}
            if previous then
                pcall(function() group[index].Widget:SetBrushColor(ESP_WHITE) end)
                g_masterahsanyt_ESPDrawLine(group[index],previous.X,previous.Y,p.X,p.Y,whiteThickness[step])
                index=index+1
            end
            previous=p
        end
    end
    group.Built=true group.GroupVisible=true
    return group
end

local function g_masterahsanyt_ESPBuildHealth(data)
    local group=g_masterahsanyt_ESPDecorGroup(data,"Health",11,ESP_REAL)
    if not group then return nil end
    if group.Built then return group end
    -- Twice the original footprint so distant health remains readable.
    local x,barBottom,barTop,barW=700.0,1120.0,564.0,60.0
    pcall(function()
        for i=1,11 do group[i].Widget:SetBrushColor(ESP_REAL) end
    end)
    g_masterahsanyt_ESPDrawLine(group[1],x,barTop,x,barBottom,barW)
    local sh=(barBottom-barTop)/8
    for i=1,8 do
        local y1=barBottom-(i-1)*sh-2
        local y2=barBottom-i*sh+2
        g_masterahsanyt_ESPDrawLine(group[i+1],x,y1,x,y2,barW*.64)
    end
    g_masterahsanyt_ESPDrawLine(group[10],x-barW*.5,barTop,x+barW*.5,barTop,2.0)
    g_masterahsanyt_ESPDrawLine(group[11],x-barW*.5,barBottom,x+barW*.5,barBottom,2.0)
    group.Built=true group.GroupVisible=true group.Filled=-1
    return group
end

local function g_masterahsanyt_ESPBuildFooter(data)
    local group=g_masterahsanyt_ESPDecorGroup(data,"Footer",6,ESP_WHITE)
    if not group then return nil end
    if group.Built then return group end
    local cx,y,w=500.0,1243.0,394.0
    local s={{cx-w*.5,y,cx-w*.29,y},{cx-w*.5,y,cx-w*.58,y-7},{cx+w*.29,y,cx+w*.5,y},{cx+w*.5,y,cx+w*.58,y-7},{cx-w*.23,y,cx-w*.19,y},{cx+w*.19,y,cx+w*.23,y}}
    for i,v in ipairs(s) do pcall(function() group[i].Widget:SetBrushColor(i>=5 and ESP_REAL or ESP_WHITE) end) g_masterahsanyt_ESPDrawLine(group[i],v[1],v[2],v[3],v[4],i>=5 and 2.2 or 1.6) end
    group.Built=true group.GroupVisible=true
    return group
end

local function g_masterahsanyt_ESPUpdateDecoration(key,character,head,feet,opt,stage,isBot)
    local enabled=opt.Name or opt.Box or opt.Health or opt.Distance
    local data=g_masterahsanyt_ShotESP.Decorations[key]
    if not enabled or not head or not feet then
        if data and data.Visible~=false then pcall(function() data.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end) data.Visible=false end
        return
    end
    if not data or not g_masterahsanyt_ESPValid(data.Widget) then
        g_masterahsanyt_ESPDestroyWidgetData(data)
        data=g_masterahsanyt_ESPCreateDecorationRoot()
        g_masterahsanyt_ShotESP.Decorations[key]=data
    end
    if not data then return end
    local h=math.abs(feet.Y-head.Y)
    if h<8 then return end
    local scale=h/1000.0
    local x,y=head.X-500.0*scale,head.Y-200.0*scale
    local moved=not data.X or math.abs(data.X-x)>=.25 or math.abs(data.Y-y)>=.25
    local scaled=not data.Scale or math.abs(data.Scale-scale)>=.001
    if moved then
        local ok=pcall(function() data.Slot:SetPosition(g_masterahsanyt_ESPV2(x,y)) end)
        if ok then data.X,data.Y=x,y end
    end
    if scaled then
        local ok=pcall(function() data.Widget:SetRenderScale(g_masterahsanyt_ESPV2(scale,scale)) end)
        if ok then data.Scale=scale else data.Scale=nil end
    end
    if data.Visible~=true then
        local ok=pcall(function() data.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
        if ok then data.Visible=true end
    end
    -- Header: handled by ESPUpdateHeaderFrame (screen-space, dynamic width) — hide DecorationRoot version
    if data.Groups.Header then g_masterahsanyt_ESPSetGroupVisible(data.Groups.Header, false) end
    local theme=g_masterahsanyt_ESPTheme(isBot)
    local arcs=data.Groups.Arcs
    if opt.Box then arcs=g_masterahsanyt_ESPBuildArcs(data) end
    if arcs then g_masterahsanyt_ESPApplyGroupTheme(arcs,theme,"Arcs") end
    g_masterahsanyt_ESPSetGroupVisible(arcs,opt.Box==true)
    local health=data.Groups.Health
    if opt.Health then health=g_masterahsanyt_ESPBuildHealth(data) end
    local healthTypeChanged=health and health.ThemeKey~=theme.Key
    if health then g_masterahsanyt_ESPApplyGroupTheme(health,theme,"Health") end
    g_masterahsanyt_ESPSetGroupVisible(health,opt.Health==true)
    if health and opt.Health then
        local filled=math.ceil(g_masterahsanyt_ESPHealthRatio(character)*8-.001)
        if health.Filled~=filled or healthTypeChanged then
            local ok=pcall(function() for i=1,8 do health[i+1].Widget:SetBrushColor(i<=filled and theme.Main or theme.Empty) end end)
            if ok then health.Filled=filled end
        end
    end
    local footer=data.Groups.Footer
    if opt.Distance then footer=g_masterahsanyt_ESPBuildFooter(data) end
    if footer then g_masterahsanyt_ESPApplyGroupTheme(footer,theme,"Footer") end
    g_masterahsanyt_ESPSetGroupVisible(footer,opt.Distance==true)
end

local function g_masterahsanyt_ESPUpdateHeaderFrame(key,head,feet,enabled,isBot)
    local group=g_masterahsanyt_ShotESP.Headers[key]
    if not enabled or not head or not feet then g_masterahsanyt_ESPHideGroup(group) return end
    local h=math.abs(feet.Y-head.Y)
    -- Compact distance scaling.  The bottom edge stays above the head and all
    -- height growth happens upward, so zooming never pushes the plate onto the body.
    local w=math.max(68.0,math.min(232.0,h*0.315))
    local cached=g_masterahsanyt_ShotESP.Names[key] and g_masterahsanyt_ShotESP.Names[key].CachedName or ""
    w=math.max(w,math.min(232.0,28.0+#tostring(cached)*6.0))
    local hh=math.max(18.0,math.min(48.0,h*0.070))
    local headGap=math.max(4.0,math.min(10.0,h*0.025))
    local cx=head.X
    local b=head.Y-headGap
    local t=b-hh
    local cy=(t+b)*0.5
    local l,r=cx-w*0.5,cx+w*0.5
    local cut=hh*0.28
    -- 25 frame/background widgets + 8 horizontal fill bands per corner.
    -- The bands approximate true triangles without using rotated rectangles,
    -- which were the source of the original black corner leakage.
    local root = g_masterahsanyt_ShotESP.HeaderRoots[key]
    if not root or not g_masterahsanyt_ESPValid(root.Widget) then
        g_masterahsanyt_ESPDestroyGroup(group)
        g_masterahsanyt_ShotESP.Headers[key] = nil
        group = nil
        g_masterahsanyt_ESPDestroyWidgetData(root)
        root = g_masterahsanyt_ESPCreateDecorationRoot("Header")
        g_masterahsanyt_ShotESP.HeaderRoots[key] = root
        if not root then return end
        group=root.Groups.__Header
        root.Groups.__Header=nil
        g_masterahsanyt_ShotESP.Headers[key]=group
        pcall(function() root.Slot:SetZOrder(30) end)
    end
    -- Move 57 header pieces with one parent slot. Width/height changes still
    -- rebuild the exact original geometry with constant stroke thickness.
    local rootY = b
    local moved = not root.X or math.abs(root.X-cx) >= 0.25 or math.abs(root.Y-rootY) >= 0.25
    if moved then
        local ok = pcall(function() root.Slot:SetPosition(g_masterahsanyt_ESPV2(cx,rootY)) end)
        if ok then root.X,root.Y = cx,rootY end
    end
    local theme=g_masterahsanyt_ESPTheme(isBot)
    local ready = group and #group == 57
    if ready then g_masterahsanyt_ESPApplyGroupTheme(group,theme,"Header") end
    if ready and group.Width and math.abs(group.Width-w) < 0.25 and math.abs(group.Height-hh) < 0.25 then
        local healthy = g_masterahsanyt_ESPGroupHealthy(group)
        if healthy then
            for _, piece in ipairs(group) do
                if piece.Drawn then
                    if piece.Visible ~= true then
                        local ok = pcall(function() piece.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
                        if ok then piece.Visible = true end
                    end
                else g_masterahsanyt_ESPHide(piece) end
            end
            return
        end
    end
    group=g_masterahsanyt_ESPLineGroup(g_masterahsanyt_ShotESP.Headers,key,57,ESP_REAL,root.Widget)
    if not group then return end
    cx, b, t, cy = 0.0, 0.0, -hh, -hh*0.5
    l, r = -w*0.5, w*0.5
    local seg={{l+cut,t,r-cut,t},{r-cut,t,r,t+cut},{r,t+cut,r,b-cut},{r,b-cut,r-cut,b},{r-cut,b,l+cut,b},{l+cut,b,l,b-cut},{l,b-cut,l,t+cut},{l,t+cut,l+cut,t}}
    if not group.HeaderStyled then
        local ok=pcall(function() for i=23,57 do group[i].Slot:SetZOrder(0) end end)
        if ok then group.HeaderStyled=true end
    end
    g_masterahsanyt_ESPApplyGroupTheme(group,theme,"Header")
    -- octagon border
    for i,s in ipairs(seg) do g_masterahsanyt_ESPDrawLine(group[i],s[1],s[2],s[3],s[4],2.0) end
    -- white inner accent lines on top/bottom edges
    g_masterahsanyt_ESPDrawLine(group[9],l+cut*1.05,t,l+w*0.16,t,1.25)
    g_masterahsanyt_ESPDrawLine(group[10],r-w*0.16,t,r-cut*1.05,t,1.25)
    g_masterahsanyt_ESPDrawLine(group[11],l+cut*1.05,b,l+w*0.16,b,1.25)
    g_masterahsanyt_ESPDrawLine(group[12],r-w*0.16,b,r-cut*1.05,b,1.25)
    -- bottom spike
    g_masterahsanyt_ESPDrawLine(group[13],cx-cut*0.7,b,cx,b+cut,2.0)
    g_masterahsanyt_ESPDrawLine(group[14],cx,b+cut,cx+cut*0.7,b,2.0)
    -- chevrons (side arrows)
    local co=cut*0.70
    g_masterahsanyt_ESPDrawLine(group[15],l-co*1.9,cy,l-co*1.25,cy-co,2.2)
    g_masterahsanyt_ESPDrawLine(group[16],l-co*1.9,cy,l-co*1.25,cy+co,2.2)
    g_masterahsanyt_ESPDrawLine(group[17],r+co*1.9,cy,r+co*1.25,cy-co,2.2)
    g_masterahsanyt_ESPDrawLine(group[18],r+co*1.9,cy,r+co*1.25,cy+co,2.2)
    g_masterahsanyt_ESPDrawLine(group[19],l-co*2.8,cy,l-co*2.15,cy-co,2.2)
    g_masterahsanyt_ESPDrawLine(group[20],l-co*2.8,cy,l-co*2.15,cy+co,2.2)
    g_masterahsanyt_ESPDrawLine(group[21],r+co*2.8,cy,r+co*2.15,cy-co,2.2)
    g_masterahsanyt_ESPDrawLine(group[22],r+co*2.8,cy,r+co*2.15,cy+co,2.2)
    -- background: center + left strip + right strip (3-part fill of octagon interior)
    g_masterahsanyt_ESPDrawLine(group[23],l+cut,cy,r-cut,cy,hh)
    g_masterahsanyt_ESPDrawLine(group[24],l,cy,l+cut,cy,hh-2*cut)
    g_masterahsanyt_ESPDrawLine(group[25],r-cut,cy,r,cy,hh-2*cut)
    -- Fill each missing corner triangle with horizontal stepped bands.  Every
    -- band starts inside the diagonal, so black cannot cross the red border.
    local cornerSteps=8
    local bandH=cut/cornerSteps
    for i=1,cornerSteps do
        local inset=(i-1)*bandH
        local topY=t+(i-0.5)*bandH
        local bottomY=b-(i-0.5)*bandH
        local leftStart=l+cut-inset
        local rightEnd=r-cut+inset

        if inset>0.5 then
            g_masterahsanyt_ESPDrawLine(group[25+i],leftStart,topY,l+cut+0.5,topY,bandH)
            g_masterahsanyt_ESPDrawLine(group[33+i],r-cut-0.5,topY,rightEnd,topY,bandH)
            g_masterahsanyt_ESPDrawLine(group[41+i],leftStart,bottomY,l+cut+0.5,bottomY,bandH)
            g_masterahsanyt_ESPDrawLine(group[49+i],r-cut-0.5,bottomY,rightEnd,bottomY,bandH)
        else
            g_masterahsanyt_ESPHide(group[25+i])
            g_masterahsanyt_ESPHide(group[33+i])
            g_masterahsanyt_ESPHide(group[41+i])
            g_masterahsanyt_ESPHide(group[49+i])
        end
    end
    group.Width, group.Height = w, hh
    for _, piece in ipairs(group) do piece.Drawn = piece.Visible == true end
end



g_masterahsanyt_ESPHealthRatio = function(character)
    local hp, maxHp = nil, nil
    pcall(function()
        hp = character.Health or character.HP or character.CurrentHealth
        maxHp = character.HealthMax or character.MaxHealth or character.MaxHP
        if not tonumber(hp) and character.GetHealth then hp=character:GetHealth() end
        if not tonumber(maxHp) and character.GetMaxHealth then maxHp=character:GetMaxHealth() end
    end)
    hp, maxHp = tonumber(hp), tonumber(maxHp)
    if not hp or not maxHp or maxHp <= 0 then return 1.0 end
    return math.max(0.0,math.min(1.0,hp/maxHp))
end




local g_masterahsanyt_ESPBones = {
    head={"Head","head","head_01"}, neck={"neck_01","Neck","neck"}, pelvis={"pelvis","Pelvis"},
    ls={"upperarm_l","UpperArm_L","clavicle_l"}, le={"lowerarm_l","LowerArm_L"}, lw={"hand_l","Hand_L"},
    rs={"upperarm_r","UpperArm_R","clavicle_r"}, re={"lowerarm_r","LowerArm_R"}, rw={"hand_r","Hand_R"},
    lh={"thigh_l","Thigh_L","hip_l"}, lk={"calf_l","Calf_L","knee_l"}, la={"foot_l","Foot_L"},
    rh={"thigh_r","Thigh_R","hip_r"}, rk={"calf_r","Calf_R","knee_r"}, ra={"foot_r","Foot_R"}
}
local g_masterahsanyt_ESPBoneLinks={{"head","neck"},{"neck","ls"},{"ls","le"},{"le","lw"},{"neck","rs"},{"rs","re"},{"re","rw"},{"neck","pelvis"},{"pelvis","lh"},{"lh","lk"},{"lk","la"},{"pelvis","rh"},{"rh","rk"},{"rk","ra"}}

-- Cache only the bone-name lookup; world positions and camera projections remain fresh.
local function g_masterahsanyt_ESPBoneScreen(pc, mesh, id, names, cache)
    local cached = cache[id]
    if cached then
        local ok, loc = pcall(function()
            if mesh.GetSocketLocation then return mesh:GetSocketLocation(cached)
            elseif mesh.GetBoneLocation then return mesh:GetBoneLocation(cached) end
        end)
        if ok and loc and tonumber(loc.X) then return g_masterahsanyt_ESPProject(pc,loc) end
        cache[id] = nil
    end
    for _, name in ipairs(names) do
        local ok, loc = pcall(function()
            local exists = nil
            if mesh.DoesSocketExist then exists = mesh:DoesSocketExist(name)
            elseif mesh.GetBoneIndex then exists = (tonumber(mesh:GetBoneIndex(name)) or -1) >= 0 end
            if exists ~= false then
                if mesh.GetSocketLocation then return mesh:GetSocketLocation(name)
                elseif mesh.GetBoneLocation then return mesh:GetBoneLocation(name) end
            end
        end)
        if ok and loc and tonumber(loc.X) then
            cache[id] = name
            return g_masterahsanyt_ESPProject(pc,loc)
        end
    end
    return nil
end

local function g_masterahsanyt_ESPUpdateSkeleton(key, character, pc, enabled, isBot)
    local group = g_masterahsanyt_ShotESP.Skeletons[key]
    if not enabled then g_masterahsanyt_ESPHideGroup(group) return end
    local mesh = nil
    pcall(function() mesh=character.Mesh or (character.GetMesh and character:GetMesh()) end)
    if not g_masterahsanyt_ESPValid(mesh) then g_masterahsanyt_ESPHideGroup(group) return end
    if g_masterahsanyt_ShotESP.BoneMeshes[key] ~= mesh then
        g_masterahsanyt_ShotESP.BoneMeshes[key] = mesh
        g_masterahsanyt_ShotESP.BoneNameCache[key] = {}
        g_masterahsanyt_ShotESP.BonePoints[key] = {}
    end
    local points = g_masterahsanyt_ShotESP.BonePoints[key]
    local cache = g_masterahsanyt_ShotESP.BoneNameCache[key]
    local theme=g_masterahsanyt_ESPTheme(isBot)
    group = g_masterahsanyt_ESPLineGroup(g_masterahsanyt_ShotESP.Skeletons,key,#g_masterahsanyt_ESPBoneLinks,theme.Main)
    if not group then return end
    g_masterahsanyt_ESPApplyGroupTheme(group,theme,"Skeleton")
    for id, names in pairs(g_masterahsanyt_ESPBones) do
        points[id] = g_masterahsanyt_ESPBoneScreen(pc,mesh,id,names,cache)
    end
    local ankle = points.la or points.ra
    local skeletonH = (points.head and ankle) and math.abs(ankle.Y-points.head.Y) or 360.0
    local thickness = math.max(1.0,math.min(2.8,skeletonH*0.0028))
    for i, link in ipairs(g_masterahsanyt_ESPBoneLinks) do
        local a, b = points[link[1]], points[link[2]]
        if a and b then g_masterahsanyt_ESPDrawLine(group[i],a.X,a.Y,b.X,b.Y,thickness)
        else g_masterahsanyt_ESPHide(group[i]) end
    end
end

-- ESP enemy name widget made by @Masterpiece2025
local function g_masterahsanyt_ESPCreateNameTag(isBot)
    local canvas = g_masterahsanyt_ESPGetCanvas()
    if not g_masterahsanyt_ESPValid(canvas) then return nil end
    local pooled=ESPWidgetPool.Take(ESPWidgetPool.V2,"NameV2",canvas)
    if pooled then
        local theme=g_masterahsanyt_ESPTheme(isBot)
        g_masterahsanyt_ESPSetTextColor(pooled.Text,theme.Text)
        g_masterahsanyt_ESPSetTextColor(pooled.DistanceText,theme.Text)
        g_masterahsanyt_ESPSetFont(pooled.Text,tonumber(_G.g_masterahsanyt_MasterShotESP.NameFontSize) or 16,0)
        g_masterahsanyt_ESPSetFont(pooled.DistanceText,tonumber(_G.g_masterahsanyt_MasterShotESP.DistanceFontSize) or 20,0)
        pooled.IsBot=isBot;pooled.ContainerVisible=false
        if pooled then return pooled end
    end

    local container, nameText, distanceText = nil, nil, nil
    pcall(function() container = CGame:NewObjectFromPath("/Script/UMG.CanvasPanel", canvas) end)
    if not g_masterahsanyt_ESPValid(container) then return nil end
    pcall(function() nameText = CGame:NewObjectFromPath("/Script/UMG.TextBlock", container) end)
    pcall(function() distanceText = CGame:NewObjectFromPath("/Script/UMG.TextBlock", container) end)
    if not g_masterahsanyt_ESPValid(nameText) or not g_masterahsanyt_ESPValid(distanceText) then
        pcall(function() container:RemoveFromParent() end)
        return nil
    end

    pcall(function()
        nameText:SetText("")
        distanceText:SetText("")
        nameText:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        distanceText:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        if nameText.SetJustification then nameText:SetJustification(1) end
        if nameText.SetRenderTransformPivot then nameText:SetRenderTransformPivot(g_masterahsanyt_ESPV2(.5,.5)) end
        if distanceText.SetJustification then distanceText:SetJustification(1) end
        if distanceText.SetRenderTransformPivot then distanceText:SetRenderTransformPivot(g_masterahsanyt_ESPV2(.5,.5)) end
    end)

    local theme=g_masterahsanyt_ESPTheme(isBot)
    g_masterahsanyt_ESPSetTextColor(nameText, theme.Text)
    g_masterahsanyt_ESPSetTextColor(distanceText, theme.Text)
    g_masterahsanyt_ESPSetFont(nameText, tonumber(_G.g_masterahsanyt_MasterShotESP.NameFontSize) or 16, 0)
    -- Distance labels are intentionally borderless; the larger glyphs provide clarity.
    g_masterahsanyt_ESPSetFont(distanceText, tonumber(_G.g_masterahsanyt_MasterShotESP.DistanceFontSize) or 20, 0)
    local nameSlot, distanceSlot, mainSlot = nil, nil, nil
    pcall(function() nameSlot = container:AddChildToCanvas(nameText) end)
    pcall(function() distanceSlot = container:AddChildToCanvas(distanceText) end)
    if not nameSlot or not distanceSlot then
        pcall(function() container:RemoveFromParent() end)
        return nil
    end
    pcall(function() mainSlot = canvas:AddChildToCanvas(container) end)
    if not mainSlot then
        pcall(function() container:RemoveFromParent() end)
        return nil
    end

    pcall(function()
        mainSlot:SetAutoSize(false)
        mainSlot:SetAlignment(g_masterahsanyt_ESPV2(0.0, 0.0))
        mainSlot:SetZOrder(65)
        nameSlot:SetAutoSize(true)
        nameSlot:SetAlignment(g_masterahsanyt_ESPV2(0.5, 0.5))
        nameSlot:SetZOrder(1)
        distanceSlot:SetAutoSize(true)
        distanceSlot:SetAlignment(g_masterahsanyt_ESPV2(0.5, 0.5))
        distanceSlot:SetZOrder(1)
    end)

    local data={
        Widget = container,
        Text = nameText,
        DistanceText = distanceText,
        TextSlot = nameSlot,
        DistanceSlot = distanceSlot,
        Slot = mainSlot,
        IsBot = isBot
    }
    return ESPWidgetPool.Tag(ESPWidgetPool.V2,"NameV2",canvas,data)
end

-- ESP enemy name and distance made by @Masterpiece2025
local function g_masterahsanyt_ESPUpdateNameTag(key, character, headScreen, footScreen, isBot, distance, forceName, forceDistance)
    local showName = _G.g_masterahsanyt_ESPOptions.Name == true
    local showDistance = _G.g_masterahsanyt_ESPOptions.Distance == true
    if forceName~=nil then showName=forceName==true end
    if forceDistance~=nil then showDistance=forceDistance==true end
    local data = g_masterahsanyt_ShotESP.Names[key]
    if not showName and not showDistance then
        if data and data.ContainerVisible~=false and g_masterahsanyt_ESPValid(data.Widget) then pcall(function() data.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end) data.ContainerVisible=false end
        return
    end
    -- Fix: only cache non-empty resolved names; "" is truthy in Lua so never cache it
    local name = nil
    if showName then
        local cached = data and data.CachedName
        if type(cached) == "string" and #cached > 0 then
            name = cached
        else
            name = g_masterahsanyt_ESPResolvePlayerName(character)
            if data and type(name) == "string" and #name > 0 then
                data.CachedName = name
            end
        end
        -- Fallback label for display only (not cached, so future frames retry)
        if not (type(name) == "string" and #name > 0) then
            name = isBot and "BOT" or "PLAYER"
        end
    else
        name = ""
    end
    if not headScreen then
        if data and g_masterahsanyt_ESPValid(data.Widget) then
            pcall(function() data.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
            data.ContainerVisible=false
        end
        return
    end

    if not data or not g_masterahsanyt_ESPValid(data.Widget) then
        g_masterahsanyt_ESPDestroyWidgetData(data)
        data = g_masterahsanyt_ESPCreateNameTag(isBot)
        g_masterahsanyt_ShotESP.Names[key] = data
        -- Only cache real resolved names on creation, not fallback labels
        if data and type(name)=="string" and #name>0 and name~="BOT" and name~="PLAYER" then
            data.CachedName = name
        end
    end
    if not data then return end
    if data.IsBot~=isBot then
        local theme=g_masterahsanyt_ESPTheme(isBot)
        g_masterahsanyt_ESPSetTextColor(data.Text,theme.Text)
        g_masterahsanyt_ESPSetTextColor(data.DistanceText,theme.Text)
        data.IsBot=isBot
    end

    local dist = math.max(0, math.floor((tonumber(distance) or 0) + 0.5))
    local distanceLabel = string.format("%dm", dist)

    local bodyH=(footScreen and math.abs(footScreen.Y-headScreen.Y)) or 120.0
    local charCount=#name
    pcall(function() if utf8 and utf8.len then charCount=utf8.len(name) or charCount end end)
    -- Same compact, bottom-anchored geometry as ESPUpdateHeaderFrame.
    local w=math.max(68.0,math.min(232.0,bodyH*0.315))
    w=math.max(w,math.min(232.0,28.0+charCount*6.0))
    local hh=math.max(18.0,math.min(48.0,bodyH*0.070))
    local nameScale=math.max(0.80,math.min(1.18,math.min(bodyH/330.0,(w*0.80)/math.max(1.0,charCount*8.4))))
    local distanceScale=math.max(0.60,math.min(1.30,bodyH/200.0))
    local offscreenDistance = forceDistance==true and forceName==false
    if offscreenDistance then distanceScale=math.max(distanceScale,1.10) end

    -- Anchor the lower edge above the head; only the upper edge expands with scale.
    local cx = headScreen.X
    local headGap=math.max(4.0,math.min(10.0,bodyH*0.025))
    local bottomY=headScreen.Y-headGap
    local x = cx - w*0.5
    local y = bottomY-hh

    -- Distance text: at FEET position (CanvasPanel doesn't clip children outside bounds)
    local footY = footScreen and footScreen.Y or (headScreen.Y + bodyH)
    local distY = (footY - y) + bodyH*0.020   -- relative to container top-left, at feet level
    local distX = footScreen and (footScreen.X - x) or (w*0.5)

    local nameVisibilityChanged=data.ShowName~=showName
    local distanceVisibilityChanged=data.ShowDistance~=showDistance
    local layoutChanged=not data.LayoutX or math.abs(data.LayoutX-x)>=0.25 or math.abs(data.LayoutY-y)>=0.25 or
        math.abs((data.LayoutW or 0)-w)>=0.25 or math.abs((data.LayoutH or 0)-hh)>=0.25

    local applied = pcall(function()
        local shownName = showName and name or ""
        local shownDistance = showDistance and distanceLabel or ""
        if data.LastName ~= shownName then
            data.Text:SetText(shownName)
            data.LastName = shownName
        end
        if data.NameScale~=nameScale then data.Text:SetRenderScale(g_masterahsanyt_ESPV2(nameScale,nameScale)) end
        if data.DistanceScale~=distanceScale then data.DistanceText:SetRenderScale(g_masterahsanyt_ESPV2(distanceScale,distanceScale)) end
        if data.LastDistance ~= shownDistance then
            data.DistanceText:SetText(shownDistance)
            data.LastDistance = shownDistance
        end
        if nameVisibilityChanged then
            data.Text:SetWidgetVisibility(showName and UEnums.ESlateVisibility.SelfHitTestInvisible or UEnums.ESlateVisibility.Collapsed)
        end
        if distanceVisibilityChanged then
            data.DistanceText:SetWidgetVisibility(showDistance and UEnums.ESlateVisibility.SelfHitTestInvisible or UEnums.ESlateVisibility.Collapsed)
        end

        -- Move the container to match the header octagon exactly
        if layoutChanged then
            data.Slot:SetPosition(g_masterahsanyt_ESPV2(x, y))
            data.Slot:SetSize(g_masterahsanyt_ESPV2(w, hh))
        end

        -- Name text centered inside container (matches header box center)
        if data.LayoutW~=w or data.LayoutH~=hh then
            data.TextSlot:SetPosition(g_masterahsanyt_ESPV2(w*0.5, hh*0.5))
        end

        -- Distance text below the header box
        local distChanged = not data.DistX or math.abs(data.DistX-distX)>=0.25 or math.abs((data.DistY or 0)-distY)>=0.25
        if distChanged then
            data.DistanceSlot:SetPosition(g_masterahsanyt_ESPV2(distX, distY))
        end

        if data.ContainerVisible~=true then
            data.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        end
    end)
    if not applied then return end
    data.ShowName,data.ShowDistance=showName,showDistance
    data.NameScale=nameScale
    data.DistanceScale=distanceScale
    data.LayoutX,data.LayoutY,data.LayoutW,data.LayoutH=x,y,w,hh
    data.DistX,data.DistY=distX,distY
    data.ContainerVisible=true
end

-- ESP enemy and bot counter HUD made by @Masterpiece2025
local function g_masterahsanyt_ESPCreateCounter()
    local canvas=g_masterahsanyt_ESPGetCanvas()
    if not g_masterahsanyt_ESPValid(canvas) then return nil end
    local container=CGame:NewObjectFromPath("/Script/UMG.CanvasPanel",canvas)
    if not g_masterahsanyt_ESPValid(container) then return nil end
    local W,H=308,48
    local pieces={}
    local function rect(x,y,w,h,color,z)
        local widget=CGame:NewObjectFromPath("/Script/UMG.Border",container)
        widget:SetBrushColor(color);widget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        local slot=container:AddChildToCanvas(widget)
        slot:SetAutoSize(false);slot:SetPosition(g_masterahsanyt_ESPV2(x,y));slot:SetSize(g_masterahsanyt_ESPV2(w,h));slot:SetZOrder(z or 1)
        pieces[#pieces+1]={Widget=widget,Slot=slot}
    end
    local function text(value,x,y,w,size,color)
        local widget=CGame:NewObjectFromPath("/Script/UMG.TextBlock",container)
        widget:SetText(value);widget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        g_masterahsanyt_ESPSetFont(widget,size,0);g_masterahsanyt_ESPSetTextColor(widget,color)
        local slot=container:AddChildToCanvas(widget)
        slot:SetAutoSize(false);slot:SetPosition(g_masterahsanyt_ESPV2(x,y));slot:SetSize(g_masterahsanyt_ESPV2(w,size+8));slot:SetZOrder(8)
        return widget
    end
    -- Red PLAYER / cyan-blue BOT pills, constructed once from static borders.
    -- Rounded bands and icon geometry are precomputed: no textures or extra timers.
    -- Count updates touch only RealText and BotText; labels and pieces stay unchanged.
    local geometry={
        {174.8464,0.0000,116.3071,2.2618,0.1000,0.8500,1.0000,1.0000,1},
        {169.9012,2.1818,126.1975,2.2618,0.0955,0.8314,0.9967,1.0000,1},
        {166.7663,4.3636,132.4674,2.2618,0.0910,0.8129,0.9933,1.0000,1},
        {164.4435,6.5455,137.1130,2.2618,0.0864,0.7943,0.9900,1.0000,1},
        {162.6383,8.7273,140.7234,2.2618,0.0819,0.7757,0.9867,1.0000,1},
        {161.2154,10.9091,143.5692,2.2618,0.0774,0.7571,0.9833,1.0000,1},
        {160.1002,13.0909,145.7997,2.2618,0.0729,0.7386,0.9800,1.0000,1},
        {159.2473,15.2727,147.5054,2.2618,0.0683,0.7200,0.9767,1.0000,1},
        {158.6281,17.4545,148.7439,2.2618,0.0638,0.7014,0.9733,1.0000,1},
        {158.2242,19.6364,149.5516,2.2618,0.0593,0.6829,0.9700,1.0000,1},
        {158.0248,21.8182,149.9504,2.2618,0.0548,0.6643,0.9667,1.0000,1},
        {158.0248,24.0000,149.9504,2.2618,0.0502,0.6457,0.9633,1.0000,1},
        {158.2242,26.1818,149.5516,2.2618,0.0457,0.6271,0.9600,1.0000,1},
        {158.6281,28.3636,148.7439,2.2618,0.0412,0.6086,0.9567,1.0000,1},
        {159.2473,30.5455,147.5054,2.2618,0.0367,0.5900,0.9533,1.0000,1},
        {160.1002,32.7273,145.7997,2.2618,0.0321,0.5714,0.9500,1.0000,1},
        {161.2154,34.9091,143.5692,2.2618,0.0276,0.5529,0.9467,1.0000,1},
        {162.6383,37.0909,140.7234,2.2618,0.0231,0.5343,0.9433,1.0000,1},
        {164.4435,39.2727,137.1130,2.2618,0.0186,0.5157,0.9400,1.0000,1},
        {166.7663,41.4545,132.4674,2.2618,0.0140,0.4971,0.9367,1.0000,1},
        {169.9012,43.6364,126.1975,2.2618,0.0095,0.4786,0.9333,1.0000,1},
        {174.8464,45.8182,116.3071,2.2618,0.0050,0.4600,0.9300,1.0000,1},
        {16.8464,0.0000,132.3071,2.2618,1.0000,0.3600,0.4400,1.0000,2},
        {11.9012,2.1818,142.1975,2.2618,0.9971,0.3460,0.4290,1.0000,2},
        {8.7663,4.3636,148.4674,2.2618,0.9943,0.3319,0.4181,1.0000,2},
        {6.4435,6.5455,153.1130,2.2618,0.9914,0.3179,0.4071,1.0000,2},
        {4.6383,8.7273,156.7234,2.2618,0.9886,0.3038,0.3962,1.0000,2},
        {3.2154,10.9091,159.5692,2.2618,0.9857,0.2898,0.3852,1.0000,2},
        {2.1002,13.0909,161.7997,2.2618,0.9829,0.2757,0.3743,1.0000,2},
        {1.2473,15.2727,163.5054,2.2618,0.9800,0.2617,0.3633,1.0000,2},
        {0.6281,17.4545,164.7439,2.2618,0.9771,0.2476,0.3524,1.0000,2},
        {0.2242,19.6364,165.5516,2.2618,0.9743,0.2336,0.3414,1.0000,2},
        {0.0248,21.8182,165.9504,2.2618,0.9714,0.2195,0.3305,1.0000,2},
        {0.0248,24.0000,165.9504,2.2618,0.9686,0.2055,0.3195,1.0000,2},
        {0.2242,26.1818,165.5516,2.2618,0.9657,0.1914,0.3086,1.0000,2},
        {0.6281,28.3636,164.7439,2.2618,0.9629,0.1774,0.2976,1.0000,2},
        {1.2473,30.5455,163.5054,2.2618,0.9600,0.1633,0.2867,1.0000,2},
        {2.1002,32.7273,161.7997,2.2618,0.9571,0.1493,0.2757,1.0000,2},
        {3.2154,34.9091,159.5692,2.2618,0.9543,0.1352,0.2648,1.0000,2},
        {4.6383,37.0909,156.7234,2.2618,0.9514,0.1212,0.2538,1.0000,2},
        {6.4435,39.2727,153.1130,2.2618,0.9486,0.1071,0.2429,1.0000,2},
        {8.7663,41.4545,148.4674,2.2618,0.9457,0.0931,0.2319,1.0000,2},
        {11.9012,43.6364,142.1975,2.2618,0.9429,0.0790,0.2210,1.0000,2},
        {16.8464,45.8182,132.3071,2.2618,0.9400,0.0650,0.2100,1.0000,2},
        {18.2801,3.5000,130.4398,0.8133,1.0000,0.6900,0.7300,1.0000,3},
        {18.0000,4.2333,131.0000,0.8133,1.0000,0.6900,0.7300,1.0000,3},
        {18.2801,4.9667,130.4398,0.8133,1.0000,0.6900,0.7300,1.0000,3},
        {177.2801,3.5000,109.4398,0.8133,0.5900,0.9600,1.0000,1.0000,3},
        {177.0000,4.2333,110.0000,0.8133,0.5900,0.9600,1.0000,1.0000,3},
        {177.2801,4.9667,109.4398,0.8133,0.5900,0.9600,1.0000,1.0000,3},
        {16.2738,9.0000,15.4524,4.3657,0.8400,0.0700,0.1700,1.0000,4},
        {11.6902,13.2857,24.6196,4.3657,0.8017,0.0625,0.1650,1.0000,4},
        {9.6253,17.5714,28.7494,4.3657,0.7633,0.0550,0.1600,1.0000,4},
        {9.0000,21.8571,30.0000,4.3657,0.7250,0.0475,0.1550,1.0000,4},
        {9.6253,26.1429,28.7494,4.3657,0.6867,0.0400,0.1500,1.0000,4},
        {11.6902,30.4286,24.6196,4.3657,0.6483,0.0325,0.1450,1.0000,4},
        {16.2738,34.7143,15.4524,4.3657,0.6100,0.0250,0.1400,1.0000,4},
        {178.2738,9.0000,15.4524,4.3657,0.0100,0.5900,0.8900,1.0000,4},
        {173.6902,13.2857,24.6196,4.3657,0.0108,0.5367,0.8633,1.0000,4},
        {171.6253,17.5714,28.7494,4.3657,0.0117,0.4833,0.8367,1.0000,4},
        {171.0000,21.8571,30.0000,4.3657,0.0125,0.4300,0.8100,1.0000,4},
        {171.6253,26.1429,28.7494,4.3657,0.0133,0.3767,0.7833,1.0000,4},
        {173.6902,30.4286,24.6196,4.3657,0.0142,0.3233,0.7567,1.0000,4},
        {178.2738,34.7143,15.4524,4.3657,0.0150,0.2700,0.7300,1.0000,4},
        {21.0000,15.0000,6.0000,2.0800,1.0000,1.0000,1.0000,1.0000,5},
        {19.4174,17.0000,9.1652,2.0800,1.0000,1.0000,1.0000,1.0000,5},
        {19.0000,19.0000,10.0000,2.0800,1.0000,1.0000,1.0000,1.0000,5},
        {19.4174,21.0000,9.1652,2.0800,1.0000,1.0000,1.0000,1.0000,5},
        {21.0000,23.0000,6.0000,2.0800,1.0000,1.0000,1.0000,1.0000,5},
        {17.2000,26.0000,13.6000,2.2800,1.0000,1.0000,1.0000,1.0000,5},
        {15.4592,28.2000,17.0817,2.2800,1.0000,1.0000,1.0000,1.0000,5},
        {15.0000,30.4000,18.0000,2.2800,1.0000,1.0000,1.0000,1.0000,5},
        {15.4592,32.6000,17.0817,2.2800,1.0000,1.0000,1.0000,1.0000,5},
        {17.2000,34.8000,13.6000,2.2800,1.0000,1.0000,1.0000,1.0000,5},
        {177.0314,21.0000,17.9373,3.0800,1.0000,1.0000,1.0000,1.0000,5},
        {175.1905,24.0000,21.6190,3.0800,1.0000,1.0000,1.0000,1.0000,5},
        {175.0000,27.0000,22.0000,3.0800,1.0000,1.0000,1.0000,1.0000,5},
        {175.1905,30.0000,21.6190,3.0800,1.0000,1.0000,1.0000,1.0000,5},
        {177.0314,33.0000,17.9373,3.0800,1.0000,1.0000,1.0000,1.0000,5},
        {178.5056,25.0000,14.9889,2.7467,0.0400,0.1800,0.3600,1.0000,6},
        {178.0000,27.6667,16.0000,2.7467,0.0400,0.1800,0.3600,1.0000,6},
        {178.5056,30.3333,14.9889,2.7467,0.0400,0.1800,0.3600,1.0000,6},
        {173.0000,26.0000,2.0000,5.0000,1.0000,1.0000,1.0000,1.0000,5},
        {197.0000,26.0000,2.0000,5.0000,1.0000,1.0000,1.0000,1.0000,5},
        {185.0000,17.0000,2.0000,4.0000,1.0000,1.0000,1.0000,1.0000,5},
        {184.0000,14.0000,4.0000,4.0000,1.0000,1.0000,1.0000,1.0000,5},
        {181.0000,27.0000,3.0000,3.0000,0.1000,0.9100,1.0000,1.0000,7},
        {188.0000,27.0000,3.0000,3.0000,0.1000,0.9100,1.0000,1.0000,7},
    }
    for i=1,#geometry do
        local p=geometry[i]
        rect(p[1],p[2],p[3],p[4],LinearColor(p[5],p[6],p[7],p[8]),p[9])
    end
    local white=LinearColor(1,1,1,1)
    local yellow=LinearColor(1,.85,.10,1)
    text("PLAYER:",47,15.5,70,13,white)
    text("BOT:",207,15.5,42,13,white)
    local real=text("0",119,8.5,42,23,yellow)
    local bot=text("0",247,8.5,53,23,yellow)
    local slot=canvas:AddChildToCanvas(container)
    slot:SetAutoSize(false);slot:SetSize(g_masterahsanyt_ESPV2(W,H));slot:SetZOrder(60)
    local anchored=false
    pcall(function()
        local a=Anchors();a.Minimum=g_masterahsanyt_ESPV2(.5,0);a.Maximum=g_masterahsanyt_ESPV2(.5,0)
        slot:SetAnchors(a);slot:SetAlignment(g_masterahsanyt_ESPV2(.5,0));anchored=true
    end)
    return {Widget=container,Slot=slot,RealText=real,BotText=bot,
        Width=W,Height=H,DiamondSize=0,Pieces=pieces,ViewportAnchored=anchored,Design="GlossyPills.1"}
end

-- ESP counter position and tracer origin made by @Masterpiece2025
local function g_masterahsanyt_ESPUpdateCounter(realCount, botCount, pc)

    local data = g_masterahsanyt_ShotESP.Counter
    if not data or not g_masterahsanyt_ESPValid(data.Widget) then
        -- The static counter is built atomically; the budget applies to enemy
        -- line groups that would otherwise all spawn together.
        local budget = g_masterahsanyt_ShotESP.BuildRemaining
        g_masterahsanyt_ShotESP.BuildRemaining = nil
        data = g_masterahsanyt_ESPCreateCounter()
        g_masterahsanyt_ShotESP.BuildRemaining = budget
        g_masterahsanyt_ShotESP.Counter = data
    end
    if not data then return nil end

    local cw = g_masterahsanyt_ShotESP.ViewportW
    local centerX = nil

    if tonumber(cw) and cw > 1 then
        centerX = cw * 0.5
    else

        local vw = g_masterahsanyt_ESPViewport(pc)
        centerX =
            (vw * 0.5) * (g_masterahsanyt_ShotESP.CanvasScaleX or 1.0)
            + (g_masterahsanyt_ShotESP.CanvasOffsetX or 0.0)
    end

    if not centerX then return nil end

    local counterY = tonumber(_G.g_masterahsanyt_MasterShotESP.CounterY) or 36.0

    if data.LastReal ~= realCount then
        local ok=pcall(function() data.RealText:SetText(tostring(realCount or 0)) end)
        if ok then data.LastReal = realCount end
    end
    if data.LastBot ~= botCount then
        local ok=pcall(function() data.BotText:SetText(tostring(botCount or 0)) end)
        if ok then data.LastBot = botCount end
    end

    local positionChanged = data.CenterX ~= centerX or data.CounterY ~= counterY
    local visibleChanged = data.Visible ~= true
    local applied = pcall(function()
        if positionChanged and data.ViewportAnchored then
            data.Slot:SetPosition(g_masterahsanyt_ESPV2(0.0,counterY))
        elseif positionChanged then
            data.Slot:SetAlignment(g_masterahsanyt_ESPV2(0.0,0.0))
            data.Slot:SetPosition(g_masterahsanyt_ESPV2(centerX-data.Width*0.5,counterY))
        end
        if visibleChanged then data.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end
    end)
    if applied then data.CenterX,data.CounterY,data.Visible = centerX,counterY,true end

    local diamondSize = tonumber(data.DiamondSize) or 20.0
    local anchorX = centerX
    local anchorY = counterY + (data.Height * 0.5) + (diamondSize / math.sqrt(2.0))

    data.AnchorX = anchorX
    data.AnchorY = anchorY

    g_masterahsanyt_ShotESP.TracerOrigin = g_masterahsanyt_ESPV2(anchorX, anchorY)
    return g_masterahsanyt_ShotESP.TracerOrigin
end

-- ESP enemy scan made by @Masterpiece2025
local function g_masterahsanyt_ESPScanEnemies()
    local pc = g_masterahsanyt_ESPGetController()
    local me = g_masterahsanyt_ESPGetLocalCharacter()
    if not pc or not me then g_masterahsanyt_ShotESP.Enemies = {} return nil, 0, 0 end
    local myLoc = ESPShared.GetFrameRecord(me).Location
    if not myLoc then g_masterahsanyt_ShotESP.Enemies = {} return pc, 0, 0 end
    local myTeam = g_masterahsanyt_ESPGetTeamID(me)

    local list = {}
    local realCount, botCount = 0, 0
    local pawns=ESPShared.GetFramePawns()
    pawns = pawns or _G.g_masterahsanyt_TrackedCharacters
    if pawns then
        for _, character in pairs(pawns) do
            if character~=me and ESPShared.GetFrameRecord(character).Alive and ESPShared.Events.Counted(character) then
                local team = g_masterahsanyt_ESPGetTeamID(character)
                -- Fix: only skip as same-team when both IDs are non-zero and equal
                local sameTeam = false
                if myTeam ~= nil and team ~= nil then
                    local tNum, mNum = tonumber(team), tonumber(myTeam)
                    sameTeam = tNum and mNum and tNum > 0 and mNum > 0 and tNum == mNum
                end
                if not sameTeam then
                    local loc = ESPShared.GetFrameRecord(character).Location
                    local dist = ESPShared.DistanceMetersFrom(ESPShared.GetFrameRecord(character),myLoc)
                    if dist <= (tonumber(_G.g_masterahsanyt_MasterShotESP.MaxRangeMeters) or 400.0) then
                        local key = g_masterahsanyt_ESPGetPlayerKey(character)
                        local isBot = g_masterahsanyt_ESPIsBot(character,key)
                        if isBot then botCount = botCount + 1 else realCount = realCount + 1 end
                        list[#list+1] = {Character=character, Key=key, IsBot=isBot, Distance=dist}
                    end
                end
            end
        end
    end
    table.sort(list, function(a,b)
        if a.Distance == b.Distance then return a.Key < b.Key end
        return (a.Distance or 99999) < (b.Distance or 99999)
    end)
    g_masterahsanyt_ShotESP.Enemies = list
    return pc, realCount, botCount
end

-- ESP stale widget cleanup made by @Masterpiece2025
local function g_masterahsanyt_ESPPrune(active,alive)
    -- Visual caches follow the displayed set. Counting metadata follows alive.
    -- Move header children into their actor-free parent bundle before pruning
    -- either registry; no detached child can follow a different enemy.
    for key,root in pairs(g_masterahsanyt_ShotESP.HeaderRoots) do
        if not active[key] and root.PoolOwner and root.Groups then
            root.Groups.__Header=g_masterahsanyt_ShotESP.Headers[key]
            g_masterahsanyt_ShotESP.Headers[key]=nil
        end
    end
    for _,registry in ipairs({g_masterahsanyt_ShotESP.Lines,g_masterahsanyt_ShotESP.Names,
        g_masterahsanyt_ShotESP.Decorations,g_masterahsanyt_ShotESP.HeaderRoots}) do
        for key,data in pairs(registry) do
            if not active[key] then g_masterahsanyt_ESPDestroyWidgetData(data);registry[key]=nil end
        end
    end
    for _,registry in ipairs({g_masterahsanyt_ShotESP.Boxes,g_masterahsanyt_ShotESP.HealthBars,
        g_masterahsanyt_ShotESP.Skeletons,g_masterahsanyt_ShotESP.Headers,g_masterahsanyt_ShotESP.Footers}) do
        for key,group in pairs(registry) do
            if not active[key] then g_masterahsanyt_ESPDestroyGroup(group);registry[key]=nil end
        end
    end
    for _,registry in ipairs({g_masterahsanyt_ShotESP.BuildStage,g_masterahsanyt_ShotESP.BoneNameCache,
        g_masterahsanyt_ShotESP.BoneMeshes,g_masterahsanyt_ShotESP.BonePoints}) do
        for key in pairs(registry) do if not active[key] then registry[key]=nil end end
    end
    for key in pairs(g_masterahsanyt_ShotESP._BotCache) do if not alive[key] then g_masterahsanyt_ShotESP._BotCache[key]=nil end end
end

ESPShared.Events.Clearers[#ESPShared.Events.Clearers+1]=function(actor)
    ESPShared.Events.ClearIn(g_masterahsanyt_ShotESP,g_masterahsanyt_ESPPrune,actor)
end

-- ESP main HUD update made by @Masterpiece2025
local function g_masterahsanyt_ESPUpdate()
    local opt = _G.g_masterahsanyt_ESPOptions
    local anyEnabled = opt and (opt.Name or opt.Line or opt.Box or opt.Health or opt.Distance or opt.Skeleton or opt.Counter)
    if not _G.g_masterahsanyt_MasterShotESP.Enabled or not anyEnabled then
        if not g_masterahsanyt_ShotESP.Disabled then g_masterahsanyt_ESPResetWidgets() end
        g_masterahsanyt_ShotESP.Disabled = true
        return
    end
    g_masterahsanyt_ShotESP.Disabled = false
    local buildBudget = tonumber(_G.g_masterahsanyt_MasterShotESP.WidgetBuildBudget) or 96
    if buildBudget ~= buildBudget or buildBudget == math.huge then buildBudget = 96 end
    g_masterahsanyt_ShotESP.BuildRemaining = math.max(1, math.floor(buildBudget))

    local world = g_masterahsanyt_ESPWorld()
    ESPShared.Events.WorldChanged(world)
    if world ~= g_masterahsanyt_ShotESP.LastWorld then
        g_masterahsanyt_ESPResetWidgets()
        g_masterahsanyt_ShotESP.LastWorld = world
        g_masterahsanyt_ShotESP.LastScanClock = -999.0
        g_masterahsanyt_ShotESP.LastTransformClock = -999.0
        g_masterahsanyt_ShotESP.TracerOrigin = nil
    end

    if g_masterahsanyt_ShotESP.Canvas and not g_masterahsanyt_ESPValid(g_masterahsanyt_ShotESP.Canvas) then
        g_masterahsanyt_ESPResetWidgets()
    end
    local canvas = g_masterahsanyt_ESPGetCanvas()
    if not canvas then return end
    local now = g_masterahsanyt_ESPNow()
    g_masterahsanyt_ShotESP.Now = now
    if now < g_masterahsanyt_ShotESP.LastScanClock then
        g_masterahsanyt_ShotESP.LastScanClock = -999.0
        g_masterahsanyt_ShotESP.LastTransformClock = -999.0
    end
    local pc = g_masterahsanyt_ESPGetController()
    local me = g_masterahsanyt_ESPGetLocalCharacter()
    if pc ~= g_masterahsanyt_ShotESP.LastController or me ~= g_masterahsanyt_ShotESP.LastPawn then
        g_masterahsanyt_ESPResetWidgets()
        g_masterahsanyt_ShotESP.LastController, g_masterahsanyt_ShotESP.LastPawn = pc,me
        canvas = g_masterahsanyt_ESPGetCanvas()
        if not canvas then return end
    end
    if not pc or not me then return end
    local myLoc = ESPShared.GetFrameRecord(me).Location
    local realCount, botCount = nil, nil
    if (now - g_masterahsanyt_ShotESP.LastScanClock) >= (tonumber(_G.g_masterahsanyt_MasterShotESP.ScanInterval) or 0.30) then
        pc, realCount, botCount = g_masterahsanyt_ESPScanEnemies()
        g_masterahsanyt_ShotESP.LastScanClock = now
        g_masterahsanyt_ShotESP.RealCount, g_masterahsanyt_ShotESP.BotCount = realCount, botCount
    end
    pc = pc or g_masterahsanyt_ESPGetController()
    if not pc then return end

    if (now - (g_masterahsanyt_ShotESP.LastTransformClock or -999.0))
        >= (tonumber(_G.g_masterahsanyt_MasterShotESP.TransformInterval) or 0.50) then
        g_masterahsanyt_ESPUpdateCanvasTransform(pc)
        local cw,ch=g_masterahsanyt_ESPGetCanvasLocalSize()
        if cw and ch then g_masterahsanyt_ShotESP.ViewportW,g_masterahsanyt_ShotESP.ViewportH=cw,ch end
        local rw,rh=g_masterahsanyt_ESPViewport(pc)
        g_masterahsanyt_ShotESP.RawViewportW,g_masterahsanyt_ShotESP.RawViewportH=rw,rh
        g_masterahsanyt_ShotESP.LastTransformClock = now
    end

    local rawW,rawH=ESPShared.ViewSize(pc)
    -- The tracer uses the physical viewport midpoint in canvas coordinates.
    local canvasScaleX=ESPShared.SafeNumber(g_masterahsanyt_ShotESP.CanvasScaleX,1.0,0.00001,100)
    local canvasScaleY=ESPShared.SafeNumber(g_masterahsanyt_ShotESP.CanvasScaleY,1.0,0.00001,100)
    local canvasOffsetX=ESPShared.SafeNumber(g_masterahsanyt_ShotESP.CanvasOffsetX,0.0,-1e7,1e7)
    local canvasOffsetY=ESPShared.SafeNumber(g_masterahsanyt_ShotESP.CanvasOffsetY,0.0,-1e7,1e7)
    local originCenter = g_masterahsanyt_ESPV2(
        (rawW*0.5)*canvasScaleX+canvasOffsetX,
        4.0*canvasScaleY+canvasOffsetY
    )
    local active,alive=g_masterahsanyt_ShotESP.Active,g_masterahsanyt_ShotESP.Alive
    g_masterahsanyt_ShotESP.RealCount,g_masterahsanyt_ShotESP.BotCount=g_masterahsanyt_ESPFilterEnemies(
        g_masterahsanyt_ShotESP.Enemies,myLoc,_G.g_masterahsanyt_MasterShotESP.MaxRangeMeters,alive)
    if opt.Counter then
        g_masterahsanyt_ESPUpdateCounter(
            g_masterahsanyt_ShotESP.RealCount or 0,
            g_masterahsanyt_ShotESP.BotCount or 0,
            pc
        )
    elseif g_masterahsanyt_ShotESP.Counter then
        g_masterahsanyt_ESPHide(g_masterahsanyt_ShotESP.Counter)
    end

    -- Counter-only mode stops here after validating cached scan candidates, avoiding
    -- projection, skeleton, box and per-enemy widget work entirely.
    local detailedEnabled=opt.Name or opt.Line or opt.Box or opt.Health or opt.Distance or opt.Skeleton
    if not detailedEnabled then
        for key in pairs(active) do active[key]=nil end
        g_masterahsanyt_ESPPrune(active,alive)
        return
    end

    for key in pairs(active) do active[key]=nil end
    local configuredMax=math.floor(ESPShared.SafeNumber(_G.g_masterahsanyt_MasterShotESP.MaxRendered,8,1,64))
    local maxRendered = configuredMax
    local renderedCount=0
    -- Preserve sorted order while hidden life states consume no display slot.
    local selected=ESPShared.Events.SelectVisible(g_masterahsanyt_ShotESP.Enemies,maxRendered,
        g_masterahsanyt_ShotESP.RenderCandidates)
    g_masterahsanyt_ShotESP.RenderCandidates=selected
    for index,item in ipairs(selected) do
        if index>maxRendered then break end
        local c,key=item.Character,item.Key
        local headScreen,footScreen,onScreen=ESPShared.Events.Project(pc,c,g_masterahsanyt_ShotESP)
        if onScreen then
            if renderedCount<maxRendered then
                renderedCount=renderedCount+1
                active[key] = true
                local buildStage=g_masterahsanyt_ShotESP.BuildStage[key] or 1
                local color = item.IsBot and ESP_BOT or ESP_REAL
                local line = g_masterahsanyt_ShotESP.Lines[key]

                local colorKey = item.IsBot and "BOT" or "REAL"
                if opt.Line and (not line or not g_masterahsanyt_ESPValid(line.Widget)) then
                    g_masterahsanyt_ESPDestroyWidgetData(line)
                    line = g_masterahsanyt_ESPCreateLine(color)
                    if line then line.ColorKey = colorKey end
                    g_masterahsanyt_ShotESP.Lines[key] = line
                elseif opt.Line and line and line.ColorKey ~= colorKey then
                    pcall(function() line.Widget:SetBrushColor(color) end)
                    line.ColorKey = colorKey
                end

                if opt.Line and line then
                    local tracerTarget = headScreen or footScreen
                    if tracerTarget then
                        g_masterahsanyt_ESPDrawLine(
                            line,
                            originCenter.X, originCenter.Y,
                            tracerTarget.X, tracerTarget.Y,
                            tonumber(_G.g_masterahsanyt_MasterShotESP.TracerThickness) or 1.80
                        )
                    end
                elseif line then g_masterahsanyt_ESPHide(line) end

                g_masterahsanyt_ESPUpdateDecoration(key,c,headScreen,footScreen,opt,buildStage,item.IsBot)
                g_masterahsanyt_ESPUpdateNameTag(key,c,headScreen,footScreen,item.IsBot,item.Distance)
                -- Header frame: dynamic per-frame update (fills, corner fills, scale with name)
                g_masterahsanyt_ESPUpdateHeaderFrame(key,headScreen,footScreen,opt.Name==true,item.IsBot)

                -- All visible skeletons refresh with the current camera; no round-robin delay.
                g_masterahsanyt_ESPUpdateSkeleton(key, c, pc, opt.Skeleton == true, item.IsBot)
                g_masterahsanyt_ShotESP.BuildStage[key]=math.min(5,buildStage+1)

            end
        end
    end
    g_masterahsanyt_ESPPrune(active,alive)
end

-- One pending render chain. Menu refreshes invalidate/wake it rather than
-- drawing synchronously multiple times in the same frame.
local g_masterahsanyt_ESPRunnerToken={}
if type(_G.__MasterShotESPCleanup) == "function" then pcall(_G.__MasterShotESPCleanup) end
_G.__MasterShotESPRunner=g_masterahsanyt_ESPRunnerToken
_G.__MasterShotESPCleanup=g_masterahsanyt_ESPResetWidgets
local g_masterahsanyt_ESPDiagnostics={Updates=0,Errors=0,LastError=nil}
_G.g_masterahsanyt_ESPDiagnostics=g_masterahsanyt_ESPDiagnostics
local g_masterahsanyt_ESPTicker=nil
pcall(function() g_masterahsanyt_ESPTicker=require("common.time_ticker") end)
local g_masterahsanyt_ESPTick
local function g_masterahsanyt_ESPSchedule(delay)
    delay=ESPShared.SafeNumber(delay,0.50,0.001,0.50)
    if _G.__MasterShotESPRunner~=g_masterahsanyt_ESPRunnerToken then return end
    if not g_masterahsanyt_ESPTicker or not g_masterahsanyt_ESPTicker.AddTimerOnce then
        g_masterahsanyt_ESPDiagnostics.LastError="common.time_ticker.AddTimerOnce unavailable"
        return
    end
    local serial=(g_masterahsanyt_ESPRunnerToken.Serial or 0)+1
    g_masterahsanyt_ESPRunnerToken.Serial=serial
    g_masterahsanyt_ESPRunnerToken.Due=g_masterahsanyt_ESPNow()+delay
    local ok, err=pcall(g_masterahsanyt_ESPTicker.AddTimerOnce,delay,function()
        if _G.__MasterShotESPRunner~=g_masterahsanyt_ESPRunnerToken
            or g_masterahsanyt_ESPRunnerToken.Serial~=serial then return end
        g_masterahsanyt_ESPRunnerToken.Due=nil
        g_masterahsanyt_ShotESP.TimerClock=g_masterahsanyt_ShotESP.TimerClock+delay
        g_masterahsanyt_ESPTick()
    end)
    if not ok or err==false then
        g_masterahsanyt_ESPRunnerToken.Due=nil
        g_masterahsanyt_ESPDiagnostics.Errors=g_masterahsanyt_ESPDiagnostics.Errors+1
        g_masterahsanyt_ESPDiagnostics.LastError=tostring(err)
    end
end
g_masterahsanyt_ESPTick=function()
    local token=g_masterahsanyt_ESPRunnerToken
    if _G.__MasterShotESPRunner~=token then return end
    local now=g_masterahsanyt_ESPNow()
    local profiling=_G.g_masterahsanyt_MasterShotESP.Profile and os and type(os.clock)=="function"
    local callbackStarted=profiling and os.clock() or nil
    ESPShared.Frame.Begin(now)
    local F=_G.LunarFeatures
    if F then F.TimerClock=g_masterahsanyt_ShotESP.TimerClock end
    if not token.RenderDue or now>=token.RenderDue-0.000001 or (token.LastRenderClock and now<token.LastRenderClock) then
        local previous=g_masterahsanyt_ESPDiagnostics.LastTickSeconds
        if previous and now>previous then g_masterahsanyt_ESPDiagnostics.UpdateHz=1/(now-previous) end
        g_masterahsanyt_ESPDiagnostics.LastTickSeconds=now
        local started=profiling and os.clock() or nil
        local ok,err=pcall(g_masterahsanyt_ESPUpdate)
        ESPShared.Events.ReleaseSelected(g_masterahsanyt_ShotESP.RenderCandidates)
        g_masterahsanyt_ESPDiagnostics.LastUpdateOK=ok
        g_masterahsanyt_ESPDiagnostics.Updates=g_masterahsanyt_ESPDiagnostics.Updates+1
        if not ok then
            g_masterahsanyt_ESPDiagnostics.Errors=g_masterahsanyt_ESPDiagnostics.Errors+1
            g_masterahsanyt_ESPDiagnostics.LastError=tostring(err)
        end
        if started then
            local elapsed=os.clock()-started
            g_masterahsanyt_ESPDiagnostics.LastUpdateCPUSeconds=elapsed
            g_masterahsanyt_ESPDiagnostics.MaxUpdateCPUSeconds=math.max(elapsed,g_masterahsanyt_ESPDiagnostics.MaxUpdateCPUSeconds or 0)
        end
        local o=_G.g_masterahsanyt_ESPOptions or {}
        local enabled=_G.g_masterahsanyt_MasterShotESP.Enabled
        local detailed=enabled and (o.Name or o.Line or o.Box or o.Health or o.Distance or o.Skeleton)
        local interval=tonumber(_G.g_masterahsanyt_MasterShotESP.UpdateInterval) or 1/60
        if not detailed then interval=enabled and o.Counter and math.max(0.05,tonumber(_G.g_masterahsanyt_MasterShotESP.ScanInterval) or 0.35) or 0.50 end
        if interval~=interval or math.abs(interval)==math.huge or interval<=0 then interval=1/60 end
        token.LastRenderClock=now
        token.RenderDue=now+math.max(0.001,interval)
    end
    if profiling then g_masterahsanyt_ESPDiagnostics.LastPumpCPUSeconds=0 end
    if F and F.Pump and not F.Token.Stopped then
        local pumpStarted=profiling and os.clock() or nil
        local ok,err=pcall(F.Pump,now)
        if not ok then F.Error("Scheduler",err) end
        if pumpStarted then
            local elapsed=os.clock()-pumpStarted
            g_masterahsanyt_ESPDiagnostics.LastPumpCPUSeconds=elapsed
            g_masterahsanyt_ESPDiagnostics.MaxPumpCPUSeconds=math.max(elapsed,g_masterahsanyt_ESPDiagnostics.MaxPumpCPUSeconds or 0)
        end
    end
    ESPShared.Frame.Finish()
    local after=g_masterahsanyt_ESPNow()
    local interval=math.max(0.001,token.RenderDue-after)
    if F and F.NextInterval and not F.Token.Stopped then interval=math.min(interval,F.NextInterval(after)) end
    g_masterahsanyt_ESPSchedule(interval)
    if callbackStarted then
        local elapsed=os.clock()-callbackStarted
        g_masterahsanyt_ESPDiagnostics.LastCallbackCPUSeconds=elapsed
        g_masterahsanyt_ESPDiagnostics.MaxCallbackCPUSeconds=math.max(elapsed,g_masterahsanyt_ESPDiagnostics.MaxCallbackCPUSeconds or 0)
        g_masterahsanyt_ESPDiagnostics.TotalCallbackCPUSeconds=(g_masterahsanyt_ESPDiagnostics.TotalCallbackCPUSeconds or 0)+elapsed
        g_masterahsanyt_ESPDiagnostics.CallbackSamples=(g_masterahsanyt_ESPDiagnostics.CallbackSamples or 0)+1
    end
end


_G.g_masterahsanyt_MasterShotESPForceRefresh = function()
    if _G.__MasterShotESPRunner~=g_masterahsanyt_ESPRunnerToken then return end
    g_masterahsanyt_ESPRunnerToken.RenderDue=nil
    g_masterahsanyt_ShotESP.LastScanClock = -999.0
    g_masterahsanyt_ShotESP.LastTransformClock = -999.0
    local due=g_masterahsanyt_ESPRunnerToken.Due
    if not due or due-g_masterahsanyt_ESPNow()>0.002 then g_masterahsanyt_ESPSchedule(0.001) end
end

-- Retained circle: native work only on setting/mode/context changes.
do
    local previous=_G.LunarAimCircleHUD
    if previous and previous.Destroy then pcall(previous.Destroy) end
    local C={Segments=40,BaseDiameter=120,BuildAttempts=0}
    _G.LunarAimCircleHUD=C
    local tools,anchorClass
    pcall(function()tools=require("GameLua.Mod.BaseMod.Common.UI.InGameUITools")end)
    pcall(function()anchorClass=import("Anchors")end)
    function C.Destroy()
        if C.Widget then pcall(function() C.Widget:RemoveFromParent() end) end
        C.Widget=nil;C.Parent=nil;C.Value=nil;C.Visible=false;C.Lines=nil;C.Slot=nil
        C.Due=nil;C.NextApply=nil;C.Blocked=false;C.BuildAttempts=0;C.ScaleMode=nil
    end
    local function parent()
        if not tools then pcall(function()tools=require("GameLua.Mod.BaseMod.Common.UI.InGameUITools")end) end
        if not tools then return end
        local ok,root=pcall(tools.GetMainControlBaseUI)
        if not ok or not g_masterahsanyt_ESPValid(root) then return end
        local p=root.CanvasPanel_0 or root.CanvasPanel_42
        if g_masterahsanyt_ESPValid(p) then return p end
    end
    local function layout(value)
        local radius=value*.5
        C.Slot:SetSize(g_masterahsanyt_ESPV2(value,value))
        for _,r in ipairs(C.Lines) do
            r.Slot:SetPosition(g_masterahsanyt_ESPV2(radius+radius*r.X,radius+radius*r.Y-.75))
            r.Slot:SetSize(g_masterahsanyt_ESPV2(radius*r.Length+.25,1.5))
        end
    end
    function C.Update(now)
        local F=_G.LunarFeatures
        if not F then return end
        now=now or F.Now();C.Due=nil
        if C.LastClock and now<C.LastClock then C.NextApply=nil end
        C.LastClock=now
        if not (F.Settings.AimEnabled or F.Settings.Aim2Enabled) then
            if C.Widget and C.Visible then pcall(function()C.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)end) end
            C.Visible=false;return
        end
        if C.Blocked then return end
        if C.NextApply and now<C.NextApply then C.Due=C.NextApply;return end
        if not C.Widget or not g_masterahsanyt_ESPValid(C.Widget) then
            local p=parent()
            if not p then C.Due=now+1;return end
            local widget,slot,lines
            local ok,why=pcall(function()
                widget=CGame:NewObjectFromPath("/Script/UMG.CanvasPanel",p)
                slot=p:AddChildToCanvas(widget)
                local aOK,anchors=pcall(function()return Anchors()end)
                if not aOK or not anchors then aOK,anchors=pcall(function()return anchorClass()end)end
                if not aOK or not anchors then aOK,anchors=pcall(function()return slot:GetAnchors()end)end
                assert(aOK and anchors,"CIRCLE_ANCHORS_UNAVAILABLE")
                anchors.Minimum=g_masterahsanyt_ESPV2(.5,.5);anchors.Maximum=g_masterahsanyt_ESPV2(.5,.5)
                slot:SetAnchors(anchors);slot:SetAlignment(g_masterahsanyt_ESPV2(.5,.5));slot:SetPosition(g_masterahsanyt_ESPV2(0,0))
                slot:SetAutoSize(false);slot:SetSize(g_masterahsanyt_ESPV2(C.BaseDiameter,C.BaseDiameter));slot:SetZOrder(65)
                widget:SetRenderTransformPivot(g_masterahsanyt_ESPV2(.5,.5))
                local color=LinearColor(.1,.72,1,.92)
                local radius=C.BaseDiameter*.5;lines={}
                for i=0,C.Segments-1 do
                    local a=i*math.pi*2/C.Segments;local b=(i+1)*math.pi*2/C.Segments
                    local x,y=math.cos(a),math.sin(a)
                    local dx,dy=math.cos(b)-x,math.sin(b)-y
                    local line=CGame:NewObjectFromPath("/Script/UMG.Border",widget)
                    line:SetBrushColor(color);line:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                    line:SetRenderTransformPivot(g_masterahsanyt_ESPV2(0,.5));line:SetRenderAngle((a+math.pi/C.Segments+math.pi*.5)*180/math.pi)
                    local ls=widget:AddChildToCanvas(line)
                    ls:SetAutoSize(false);ls:SetPosition(g_masterahsanyt_ESPV2(radius+radius*x,radius+radius*y-.75))
                    local length=math.sqrt(dx*dx+dy*dy)
                    ls:SetSize(g_masterahsanyt_ESPV2(radius*length+.25,1.5))
                    lines[#lines+1]={Slot=ls,X=x,Y=y,Length=length}
                end
            end)
            if not ok then
                if widget then pcall(function()widget:RemoveFromParent()end)end
                C.BuildAttempts=C.BuildAttempts+1;F.Error("AimCircle.Build",why)
                if C.BuildAttempts>=3 then C.Blocked=true else C.Due=now+C.BuildAttempts end
                return
            end
            C.Widget=widget;C.Slot=slot;C.Parent=p;C.Lines=lines;C.Value=nil;C.ScaleMode=nil
        end
        local value=F.Settings.AimCircle
        if C.Value~=value then
            local ok=false
            if C.ScaleMode~="layout" then
                ok=pcall(function()C.Widget:SetRenderScale(g_masterahsanyt_ESPV2(value/C.BaseDiameter,value/C.BaseDiameter))end)
                C.ScaleMode=ok and "scale" or "layout"
            end
            if not ok then ok=pcall(layout,value) end
            if ok then C.Value=value;C.NextApply=now+.1
            else C.Blocked=true;F.Error("AimCircle.Size","native size update failed");return end
        end
        if not C.Visible then
            local ok=pcall(function()C.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)end)
            if ok then C.Visible=true end
        end
    end
    function C.Request()
        local F=_G.LunarFeatures
        if F then C.Update(F.Now()) end
    end
end

-- Managed feature state. Source settings are data, never loaded as executable Lua.
do
    if type(_G.__LunarFeaturesCleanup) == "function" then pcall(_G.__LunarFeaturesCleanup) end
    local F = {Token={}, Diagnostics={Errors=0}, TimerClock=0, LastWorld=nil}
    _G.LunarFeatures=F
    local settings = _G.LunarFeatureSettings or {}
    _G.LunarFeatureSettings=settings
    F.Settings=settings
    local function number(value,lo,hi,fallback)
        local v=tonumber(value)
        if not v or v~=v or v==math.huge or v==-math.huge then v=fallback end
        return math.floor(math.max(lo,math.min(hi,v))+0.5)
    end
    F.Clamp=number
    settings.IpadFOV=number(settings.IpadFOV or _G.LexusState.CustomTextData.IpadViewFOV,90,120,120)
    settings.AimSpeed=number(settings.AimSpeed,120,150,120)
    settings.AimCircle=number(settings.AimCircle,120,240,120)
    settings.AimTarget=number(settings.AimTarget,1,3,1)
    settings.AimEnabled=settings.AimEnabled==true
    settings.WallEnabled=settings.WallEnabled==true
    settings.WallVisible=number(settings.WallVisible,1,7,1)
    settings.WallOccluded=number(settings.WallOccluded,1,7,2)
    settings.Aim2Enabled=settings.Aim2Enabled==true
    settings.MortarEnabled=settings.MortarEnabled==true
    _G.g_Botmater_ESPOptions=_G.g_Botmater_ESPOptions or {}
    for _,key in ipairs({"Name","Line","Box","Health","Distance","Weapon","Flag","Visibility","Alert","EnemyCounter"}) do
        if _G.g_Botmater_ESPOptions[key]==nil then _G.g_Botmater_ESPOptions[key]=false end
    end
    local paths=g_masterahsanyt_ESPSettingsPaths()
    for i,path in ipairs(paths) do paths[i]=path:gsub("MASTERPIECE_UMG_ESP_settings.lua$","MASTERAHSAN_FEATURES_V3_settings.lua") end
    if io and io.open then
        for _,path in ipairs(paths) do
            local ok,file=pcall(io.open,path,"r")
            if ok and file then
                local readOK,payload=pcall(function() return file:read("*a") end)
                pcall(function() file:close() end)
                if readOK and type(payload)=="string" then
                    F.SettingsReadPath=path
                    for _,key in ipairs({"AimEnabled","WallEnabled","IpadEnabled","Aim2Enabled","MortarEnabled"}) do
                        local val=payload:match("%f[%w_]"..key.."%s*=%s*(%a+)")
                        if val=="true" or val=="false" then
                            if key=="IpadEnabled" then _G.LexusConfig.IpadView=val=="true" else settings[key]=val=="true" end
                        end
                    end
                    for _,key in ipairs({"IpadFOV","AimSpeed","AimCircle","AimTarget"}) do
                        local val=payload:match("%f[%w_]"..key.."%s*=%s*([%d%.%-]+)")
                        if val then settings[key]=number(val,key=="IpadFOV" and 90 or ((key=="AimSpeed" or key=="AimCircle") and 120 or 1),key=="AimTarget" and 3 or (key=="AimCircle" and 240 or (key=="AimSpeed" and 150 or 120)),settings[key]) end
                    end
                    for _,key in ipairs({"WallVisible","WallOccluded"}) do
                        local val=payload:match("%f[%w_]"..key.."%s*=%s*([%d%.%-]+)")
                        if val then settings[key]=number(val,1,7,settings[key]) end
                    end
                    for _,key in ipairs({"Name","Line","Box","Health","Distance","Weapon","Flag","Visibility","Alert","EnemyCounter"}) do
                        local val=payload:match("%f[%w_]V1_"..key.."%s*=%s*(%a+)")
                        if val=="true" or val=="false" then _G.g_Botmater_ESPOptions[key]=val=="true" end
                    end
                    for _,key in ipairs({"Name","Line","Box","Health","Distance","Skeleton","Counter"}) do
                        local val=payload:match("%f[%w_]V2_"..key.."%s*=%s*(%a+)")
                        if val=="true" or val=="false" then _G.g_masterahsanyt_ESPOptions[key]=val=="true" end
                    end
                    break
                end
            end
        end
    end
    if not F.SettingsReadPath and g_masterahsanyt_ESPLoadedSettingsPath then
        F.SettingsReadPath=g_masterahsanyt_ESPLoadedSettingsPath:gsub("MASTERPIECE_UMG_ESP_settings%.lua$","MASTERAHSAN_FEATURES_V3_settings.lua")
    end
    if settings.Aim2Enabled then settings.AimEnabled=false end
    _G.LexusState.CustomTextData.IpadViewFOV=settings.IpadFOV
    F.Now=function()
        local now=nil
        pcall(function()
            local world=g_masterahsanyt_ESPWorld()
            if world and GameplayStaticsESP and GameplayStaticsESP.GetRealTimeSeconds then now=GameplayStaticsESP.GetRealTimeSeconds(world) end
        end)
        return tonumber(now) or F.TimerClock
    end
    F.Save=function(force)
        if not F.Dirty or not io or not io.open then return end
        local lines={"return {", "  IpadEnabled = "..tostring(_G.LexusConfig.IpadView==true)..","}
        for _,key in ipairs({"AimEnabled","WallEnabled","Aim2Enabled","MortarEnabled","IpadFOV","AimSpeed","AimCircle","AimTarget","WallVisible","WallOccluded"}) do lines[#lines+1]="  "..key.." = "..tostring(settings[key]).."," end
        for _,key in ipairs({"Name","Line","Box","Health","Distance","Weapon","Flag","Visibility","Alert","EnemyCounter"}) do lines[#lines+1]="  V1_"..key.." = "..tostring(_G.g_Botmater_ESPOptions[key]==true).."," end
        for _,key in ipairs({"Name","Line","Box","Health","Distance","Skeleton","Counter"}) do lines[#lines+1]="  V2_"..key.." = "..tostring(_G.g_masterahsanyt_ESPOptions[key]==true).."," end
        lines[#lines+1]="}"
        local payload=table.concat(lines,"\n")
        local savePaths=F.SettingsReadPath and {F.SettingsReadPath} or paths
        for _,path in ipairs(savePaths) do
            local wrote,reason,atomic=g_masterahsanyt_ESPWriteSettings(path,payload)
            if wrote then
                F.SettingsReadPath=path;F.Dirty=false;F.Diagnostics.LastSaveOK=true;F.Diagnostics.LastSavePath=path;F.Diagnostics.AtomicSave=atomic
                return true
            end
            F.Diagnostics.LastSaveError=reason
        end
        F.Diagnostics.LastSaveOK=false
        return false
    end
    F.MarkDirty=function(immediate) F.Dirty=true;if immediate then F.Save(true) end end
    F.SetIpad=function(enabled)
        _G.LexusConfig.IpadView=enabled==true or enabled==1
        _G.LexusState.CustomTextData.IpadViewFOV=settings.IpadFOV
        pcall(g_masterahsanyt_ApplyiPadView)
        F.MarkDirty(true)
    end
    F.SetIpadFOV=function(value)
        settings.IpadFOV=number(value,90,120,120)
        _G.LexusState.CustomTextData.IpadViewFOV=settings.IpadFOV
        pcall(g_masterahsanyt_ApplyiPadView)
        F.MarkDirty()
    end
    F.SetAimSpeed=function(value)
        local nextValue=number(value,120,150,120)
        if nextValue==settings.AimSpeed then return end
        settings.AimSpeed=nextValue
        if _G.XthrlenState and _G.XthrlenState.CustomTextData then
            local data=_G.XthrlenState.CustomTextData
            data.AimTouchHipSpeed=nextValue;data.AimTouchScopeSpeed=nextValue
        end
        F.MarkDirty();F.SaveDue=F.Now()+0.3
    end
    F.AimRadiusUI=function() return settings.AimCircle*.5 end
    F.SetAimCircle=function(value)
        local nextValue=number(value,120,240,120)
        if nextValue==settings.AimCircle then return end
        settings.AimCircle=nextValue
        if _G.XthrlenState and _G.XthrlenState.CustomTextData then
            _G.XthrlenState.CustomTextData.AimTouchHipDist=settings.AimCircle
            _G.XthrlenState.CustomTextData.AimTouchScopeDist=settings.AimCircle
        end
        F.MarkDirty();F.SaveDue=F.Now()+0.3
        if _G.LunarAimCircleHUD then _G.LunarAimCircleHUD.Request() end
    end
    F.SetAimTarget=function(value) settings.AimTarget=number(value,1,3,1);F.MarkDirty(true) end
    -- ItemBase supports caller-owned event keys. Both native switches subscribe
    -- through its normal lifecycle; there are no saved widget references.
    F.AimSettingsEventType=-14050701
    F.AimSettingsEventID=1
    F.SetAimMode=function(value)
        local mode=F.Clamp(value,0,2,0)
        local changed=settings.AimEnabled~=(mode==1) or settings.Aim2Enabled~=(mode==2)
        settings.AimEnabled=mode==1
        settings.Aim2Enabled=mode==2
        _G.XthrlenConfig.AimTouchEnable=settings.AimEnabled
        if not settings.AimEnabled then
            _G.XthrlenState.offPitch=0;_G.XthrlenState.offYaw=0;F.AimLastClock=nil
        end
        if not settings.Aim2Enabled and F.Aim2 then F.Aim2.Stop() end
        if F.Aim2 then F.Aim2.Due=0 end
        F.MarkDirty(true)
        if _G.LunarAimCircleHUD then _G.LunarAimCircleHUD.Request() end
        if F.Wake then F.Wake() end
        if changed and EventSystem and type(EventSystem.postEvent)=="function" then
            local ok,err=pcall(EventSystem.postEvent,EventSystem,F.AimSettingsEventType,F.AimSettingsEventID)
            if not ok then F.Error("Aim.SettingsRefresh",err) end
        end
    end
    F.SetAim=function(enabled)
        local on=enabled==true or enabled==1
        F.SetAimMode(on and 1 or (settings.Aim2Enabled and 2 or 0))
    end
    F.SetAim2=function(enabled)
        local on=enabled==true or enabled==1
        F.SetAimMode(on and 2 or (settings.AimEnabled and 1 or 0))
    end
    F.SetMortar=function(enabled)
        settings.MortarEnabled=enabled==true or enabled==1
        if not settings.MortarEnabled and F.Mortar then F.Mortar.Stop() end
        if F.Mortar then F.Mortar.Due=0 end
        F.MarkDirty(true)
        if F.Wake then F.Wake() end
    end

    F.RefreshWallSettings=function()
        if EventSystem and type(EventSystem.postEvent)=="function" then
            local ok,err=pcall(EventSystem.postEvent,EventSystem,-14050701,3)
            if not ok then F.Error("Wall.SettingsRefresh",err) end
        end
    end
    F.SetWall=function(enabled)
        local changed=settings.WallEnabled~=(enabled==true or enabled==1)
        settings.WallEnabled=enabled==true or enabled==1
        if not settings.WallEnabled and F.Wall then F.Wall.Stop() end
        F.MarkDirty(true)
        if changed then F.RefreshWallSettings() end
        if F.Wake then F.Wake() end
    end
    F.SetWallColor=function(key,value)
        if key~="WallVisible" and key~="WallOccluded" then return false end
        local v=number(value,1,7,settings[key])
        if settings[key]==v then return true end
        settings[key]=v
        if F.Wall then F.Wall.UpdateColors() end
        F.MarkDirty(true)
        F.RefreshWallSettings()
        if settings.WallEnabled and F.Wake then F.Wake() end
        return true
    end
    -- Feature correspondence is resolved at setting changes only, never per frame.
    local v1Keys={"Name","Line","Box","Health","Distance","Weapon","Flag","Visibility","Alert","EnemyCounter"}
    local v2Keys={"Name","Line","Box","Health","Distance","Skeleton","Counter"}
    local v1Valid={};for _,key in ipairs(v1Keys) do v1Valid[key]=true end
    local v1ToV2={Name="Name",Line="Line",Box="Box",Health="Health",Distance="Distance",EnemyCounter="Counter"}
    local v2ToV1={Name="Name",Line="Line",Box="Box",Health="Health",Distance="Distance",Counter="EnemyCounter"}
    local v2Valid={Name=true,Line=true,Box=true,Health=true,Distance=true,Skeleton=true,Counter=true}
    F.ESPSettingsEventType=-14050701
    F.ESPSettingsEventID=2
    local function applyESP(version,key,on)
        local first,second=false,false
        local own=version==1 and _G.g_Botmater_ESPOptions or _G.g_masterahsanyt_ESPOptions
        local other=version==1 and _G.g_masterahsanyt_ESPOptions or _G.g_Botmater_ESPOptions
        local mapped=(version==1 and v1ToV2 or v2ToV1)[key]
        if (own[key]==true)~=on then own[key]=on;first=true end
        if on and mapped and other[mapped]==true then other[mapped]=false;second=true end
        if version==1 then return first,second end
        return second,first
    end
    local function commitESP(changedV1,changedV2)
        if not changedV1 and not changedV2 then
            if F.Dirty then return F.Save(true) end
            return true
        end
        if changedV1 and F.V1 then F.V1.Refresh();F.V1Due=0 end
        F.MarkDirty(true)
        if changedV2 then
            _G.g_masterahsanyt_MasterShotESPForceRefresh()
        else
            local due=g_masterahsanyt_ESPRunnerToken.Due
            if not due or due-g_masterahsanyt_ESPNow()>0.002 then g_masterahsanyt_ESPSchedule(0.001) end
        end
        if EventSystem and type(EventSystem.postEvent)=="function" then
            local ok,err=pcall(EventSystem.postEvent,EventSystem,F.ESPSettingsEventType,F.ESPSettingsEventID)
            if not ok then F.Error("ESP.SettingsRefresh",err) end
        end
        return true
    end
    F.SetESP=function(version,key,value)
        if version~=1 and version~=2 then return false end
        if (version==1 and not v1Valid[key]) or (version==2 and not v2Valid[key]) then return false end
        local changedV1,changedV2=applyESP(version,key,value==true or value==1)
        return commitESP(changedV1,changedV2)
    end
    F.GetESPAll=function(version)
        if version~=1 and version~=2 then return false end
        local own=version==1 and _G.g_Botmater_ESPOptions or _G.g_masterahsanyt_ESPOptions
        for _,key in ipairs(version==1 and v1Keys or v2Keys) do if own[key]~=true then return false end end
        return true
    end
    F.SetESPAll=function(version,value)
        if version~=1 and version~=2 then return false end
        local changedV1,changedV2=false,false
        for _,key in ipairs(version==1 and v1Keys or v2Keys) do
            local a,b=applyESP(version,key,value==true or value==1)
            changedV1,changedV2=changedV1 or a,changedV2 or b
        end
        return commitESP(changedV1,changedV2)
    end
    -- Native OnSelected skips SetFunc when the same index is selected again.
    -- Bulk command rows must still apply to partial ESP state. Only these marked
    -- rows receive the additional click callback; every other native row is untouched.
    F.InstallNativeBulkSwitch=function(class)
        if type(class)~="table" or type(class.OnSelected)~="function" then return false end
        if class.__LunarBulkSwitchV7 then return true end
        local original=class.OnSelected
        class.OnSelected=function(self,index)
            local data=self.Data
            local repeatBulk=data and data.LunarBulk and self.UIRoot.Selector:GetSelectedIndex()==index
            local result=original(self,index)
            if repeatBulk then return data.SetFunc(data.Key,self:_IndexToValue(index)) end
            return result
        end
        class.__LunarBulkSwitchV7=true
        return true
    end
    F.SetV1=function(key,value) return F.SetESP(1,key,value) end
    F.SetV2=function(key,value) return F.SetESP(2,key,value) end
    -- Old versions allowed both copies on. Resolve old conflicts once at load,
    -- giving V1 priority; persist the merged state through the existing save pump.
    for key,mapped in pairs(v1ToV2) do
        if _G.g_Botmater_ESPOptions[key]==true and _G.g_masterahsanyt_ESPOptions[mapped]==true then
            _G.g_masterahsanyt_ESPOptions[mapped]=false
            F.MarkDirty()
        end
    end
    F.Error=function(area,err)
        F.Diagnostics.Errors=F.Diagnostics.Errors+1
        F.Diagnostics.LastError=area..": "..tostring(err)
    end
    _G.__LunarFeaturesCleanup=function()
        if _G.LunarAimCircleHUD then _G.LunarAimCircleHUD.Destroy() end
        F.Token.Stopped=true
        if ESPShared.Events.UnbindAll then ESPShared.Events.UnbindAll() end
        if F.V1 then F.V1.Reset() end
        if F.Wall then F.Wall.Stop() end
        if F.Aim2 then F.Aim2.Stop() end
        if F.Mortar then F.Mortar.Stop() end
    end
end

do
local AimV2,AimGameplayStatics,AimMath,AimUI,AimLayout
pcall(function() AimV2=import("Vector2D") end)
pcall(function() AimGameplayStatics=import("GameplayStatics") end)
pcall(function() AimMath=import("KismetMathLibrary") end)
pcall(function() AimUI=require("client.common.ui_util") end)
pcall(function() AimLayout=import("WidgetLayoutLibrary") end)
_G.XthrlenConfig = _G.XthrlenConfig or {}
_G.XthrlenState = _G.XthrlenState or {}
_G.XthrlenState.CustomTextData = _G.XthrlenState.CustomTextData or {}

_G.XthrlenConfig.AimTouchEnable        = _G.LunarFeatures.Settings.AimEnabled
_G.XthrlenConfig.AimTouchHipfire       = true
_G.XthrlenConfig.AimTouchScopeAll      = true
_G.XthrlenConfig.AimTouchHipVisCheck   = true
_G.XthrlenConfig.AimTouchScopeVisCheck = true
_G.XthrlenConfig.AimTouchHipIgKnock    = true
_G.XthrlenConfig.AimTouchScopeIgKnock  = true

_G.XthrlenConfig.AimTouchHipIgBot      = false
_G.XthrlenConfig.AimTouchScopeIgBot    = false
_G.XthrlenConfig.AimTouchSG            = false
_G.XthrlenConfig.AimTouchSGAutoFire    = false
_G.XthrlenConfig.AimTouchScopeSniper   = false
_G.XthrlenConfig.AimTouchMortar        = false
_G.XthrlenConfig.EspFovCircle          = false

_G.XthrlenState.CustomTextData.AimTouchHipPrio    = 1
_G.XthrlenState.CustomTextData.AimTouchHipBone    = 1
_G.XthrlenState.CustomTextData.AimTouchHipCond    = 1
_G.XthrlenState.CustomTextData.AimTouchHipSpeed   = _G.LunarFeatures.Settings.AimSpeed
_G.XthrlenState.CustomTextData.AimTouchHipDist    = _G.LunarFeatures.Settings.AimCircle
_G.XthrlenState.CustomTextData.AimTouchHipFOV     = 30

_G.XthrlenState.CustomTextData.AimTouchScopePrio   = 1
_G.XthrlenState.CustomTextData.AimTouchScopeBone   = 1
_G.XthrlenState.CustomTextData.AimTouchScopeCond   = 1
_G.XthrlenState.CustomTextData.AimTouchScopeSpeed  = _G.LunarFeatures.Settings.AimSpeed
_G.XthrlenState.CustomTextData.AimTouchScopeDist   = _G.LunarFeatures.Settings.AimCircle
_G.XthrlenState.CustomTextData.AimTouchScopeFOV    = 30
_G.XthrlenState.CustomTextData.AimTouchScopePred   = 0

_G.XthrlenState.offPitch = _G.XthrlenState.offPitch or 0
_G.XthrlenState.offYaw   = _G.XthrlenState.offYaw   or 0

local function clampAngles(angles)
    if angles.Pitch > 180 then angles.Pitch = angles.Pitch - 360 end
    if angles.Pitch < -180 then angles.Pitch = angles.Pitch + 360 end

    if angles.Pitch < -75 then
        angles.Pitch = -75
    elseif angles.Pitch > 75 then
        angles.Pitch = 75
    end

    while angles.Yaw < -180 do angles.Yaw = angles.Yaw + 360 end
    while angles.Yaw > 180  do angles.Yaw = angles.Yaw - 360 end

    return angles
end

_G.GetEnemyTargetsFromActors = function(radius)
    local result = {}
    local player = GameplayData.GetPlayerCharacter()
    if not (slua and slua.isValid and slua.isValid(player)) then return result end

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
    local ok,err=pcall(function()
        if not _G.XthrlenConfig.AimTouchEnable then return end
        
        local player = GameplayData.GetPlayerCharacter()
        if not (slua and slua.isValid and slua.isValid(player)) then return end
        
        local pc = player:GetPlayerControllerSafety()
        if not (slua and slua.isValid and slua.isValid(pc)) then return end
        
        local isFiring = player.bIsWeaponFiring
        local isADS = player.bIsGunADS
        -- Both supplied hip/scope modes require firing. Return before scanning,
        -- weapon classification, visibility checks or imports during idle play.
        if not isFiring then return end
        
        local weapon = player.WeaponManagerComponent and player.WeaponManagerComponent.CurrentWeaponReplicated
        if not weapon and type(player.GetCurrentShootWeapon) == "function" then
            weapon = player:GetCurrentShootWeapon()
        end
        
        if _G.LunarFeatures.Settings.MortarEnabled and weapon and weapon.MortarState==2 then return end
        local isShotgun = false
        local isSniper = false
        local isMortar = false
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
            if wName:lower():find("mortar") or wName:lower():find("cối") then
                isMortar = true
            end
            
            if type(weapon.GetCurrentAmmo) == "function" then
                currentAmmo = weapon:GetCurrentAmmo()
            elseif weapon.ShootWeaponComponent and type(weapon.ShootWeaponComponent.GetCurrentAmmo) == "function" then
                currentAmmo = weapon.ShootWeaponComponent:GetCurrentAmmo()
            elseif weapon.CurrentAmmo ~= nil then
                currentAmmo = weapon.CurrentAmmo
            end
        end

        if _G.XthrlenState.IsAutoFiring then
            pcall(function()
                player.bIsWeaponFiring = false
                if type(player.SetIsWeaponFiring) == "function" then player:SetIsWeaponFiring(false) end
                if slua.isValid(pc) and type(pc.SetIsWeaponFiring) == "function" then pc:SetIsWeaponFiring(false) end
                local wepMgr = player.WeaponManagerComponent
                if slua.isValid(wepMgr) then wepMgr.bIsWeaponFiring = false end
            end)
            _G.XthrlenState.IsAutoFiring = false
        end

        if isShotgun and currentAmmo <= 0 then return end

        local cond = 2
        local prioMode = 1
        local boneIdx = 1
        local speedVal = 100
        local fovVal = 30
        local maxDistMeters = 100
        local useVisCheck = false
        local igKnock = false
        local igBot = false
        local predVal = 0 

        if isMortar and _G.XthrlenConfig.AimTouchMortar then
            local isPlaced = false
            pcall(function()
                if weapon and weapon.MortarState == 2 then isPlaced = true end
            end)
            if not isPlaced then return end

            cond = 2 
            prioMode = 1  
            boneIdx = 4 
            speedVal = 100 
            fovVal = _G.XthrlenState.CustomTextData.AimTouchMortarFOV or 360 
            maxDistMeters = 2000 
            useVisCheck = false 
            igKnock = false
            igBot = false
            predVal = _G.XthrlenState.CustomTextData.AimTouchMortarPred or 0 
            
        elseif isShotgun and _G.XthrlenConfig.AimTouchSG then
            cond = _G.XthrlenState.CustomTextData.AimTouchSGCond or 1
            if _G.XthrlenConfig.AimTouchSGAutoFire then cond = 2 end
            if cond == 1 and not isFiring then return end
            prioMode = _G.XthrlenState.CustomTextData.AimTouchSGPrio or 1
            boneIdx = _G.XthrlenState.CustomTextData.AimTouchSGBone or 2
            speedVal = _G.XthrlenState.CustomTextData.AimTouchSGSpeed or 80
            fovVal = _G.XthrlenState.CustomTextData.AimTouchSGFOV or 40
            maxDistMeters = _G.XthrlenState.CustomTextData.AimTouchSGDist or 30
            useVisCheck = _G.XthrlenConfig.AimTouchSGVisCheck
            igKnock = _G.XthrlenConfig.AimTouchSGIgKnock
            igBot = _G.XthrlenConfig.AimTouchSGIgBot
            
        elseif isADS then
            if isSniper and _G.XthrlenConfig.AimTouchScopeSniper then
                cond = _G.XthrlenState.CustomTextData.AimTouchSniperCond or 2
                if cond == 1 and not isFiring then return end
                prioMode = _G.XthrlenState.CustomTextData.AimTouchSniperPrio or 1
                boneIdx = _G.XthrlenState.CustomTextData.AimTouchSniperBone or 1
                speedVal = _G.XthrlenState.CustomTextData.AimTouchSniperSpeed or 30
                fovVal = _G.XthrlenState.CustomTextData.AimTouchSniperFOV or 20
                maxDistMeters = _G.XthrlenState.CustomTextData.AimTouchSniperDist or 400
                useVisCheck = _G.XthrlenConfig.AimTouchSniperVisCheck
                igKnock = _G.XthrlenConfig.AimTouchSniperIgKnock
                igBot = _G.XthrlenConfig.AimTouchSniperIgBot
                predVal = _G.XthrlenState.CustomTextData.AimTouchSniperPred or 0
            elseif _G.XthrlenConfig.AimTouchScopeAll then
                cond = _G.XthrlenState.CustomTextData.AimTouchScopeCond or 1
                if cond == 1 and not isFiring then return end
                prioMode = _G.XthrlenState.CustomTextData.AimTouchScopePrio or 1
                boneIdx = 1
                speedVal = _G.XthrlenState.CustomTextData.AimTouchScopeSpeed or 100
                fovVal = _G.XthrlenState.CustomTextData.AimTouchScopeFOV or 30
                maxDistMeters = _G.XthrlenState.CustomTextData.AimTouchScopeDist or 100
                useVisCheck = _G.XthrlenConfig.AimTouchScopeVisCheck
                igKnock = _G.XthrlenConfig.AimTouchScopeIgKnock
                igBot = _G.XthrlenConfig.AimTouchScopeIgBot
                predVal = _G.XthrlenState.CustomTextData.AimTouchScopePred or 0
            else
                return
            end
        else
            if not _G.XthrlenConfig.AimTouchHipfire then return end
            cond = _G.XthrlenState.CustomTextData.AimTouchHipCond or 1
            if cond == 1 and not isFiring then return end 
            prioMode = _G.XthrlenState.CustomTextData.AimTouchHipPrio or 1
            boneIdx = 1
            speedVal = _G.XthrlenState.CustomTextData.AimTouchHipSpeed or 100
            fovVal = _G.XthrlenState.CustomTextData.AimTouchHipFOV or 30
            maxDistMeters = _G.XthrlenState.CustomTextData.AimTouchHipDist or 100
            useVisCheck = _G.XthrlenConfig.AimTouchHipVisCheck
            igKnock = _G.XthrlenConfig.AimTouchHipIgKnock
            igBot = _G.XthrlenConfig.AimTouchHipIgBot
        end

        local currentMaxDist = maxDistMeters * 100 
        local enemies = _G.GetEnemyTargetsFromActors(currentMaxDist)
        if not enemies or #enemies == 0 then return end
        
        local FVector2D = AimV2
        local UGameplayStatics = AimGameplayStatics
        local KismetMathLibrary = AimMath
        if not FVector2D or not UGameplayStatics or not KismetMathLibrary then return end
        
        local camManager = UGameplayStatics.GetPlayerCameraManager(pc, 0)
        if not slua.isValid(camManager) then return end
        
        local camLoc = camManager:GetCameraLocation()
        if not camLoc then return end
        
        local ui_util = AimUI
        if not ui_util then return end
        
        local viewportSize = ui_util.GetViewportSize()
        if not viewportSize then return end
        
        local centerX = viewportSize.X * 0.5
        local centerY = viewportSize.Y * 0.5
        local dpiScale=1
        pcall(function() local v=AimLayout.GetViewportScale(pc);if tonumber(v) and v>0 then dpiScale=v end end)
        local FOV_RADIUS = _G.LunarFeatures.AimRadiusUI()*dpiScale
        
        local bestTarget = nil
        local bestScore = 99999999 
        
        local selected=_G.LunarFeatures.Settings.AimTarget
        boneIdx=selected==2 and 2 or (selected==3 and 5 or 1)
        local selBoneName=selected==2 and "spine_03" or (selected==3 and "calf_l" or "head")

        for i, target in ipairs(enemies) do
            repeat
            if not slua.isValid(target) then break end
            
            pcall(function()
                if slua.isValid(target.Mesh) then
                    target.Mesh.MeshComponentUpdateFlag = 0
                end
            end)
            
            if igKnock and target.HealthStatus == 1 then break end
            
            if igBot then
                local tIsBot = false
                if target.bIsAI == true or target.IsAI == true then tIsBot = true end
                local pState = target.PlayerState
                if slua.isValid(pState) and (pState.bIsABot or pState.bIsBot) then tIsBot = true end
                if tIsBot then break end
            end
            
            if useVisCheck then
                local curTime = _G.LunarFeatures.Now()
                local tId = type(target.GetUniqueID) == "function" and target:GetUniqueID() or tostring(target)
                _G.AimTouchVisCache = _G.AimTouchVisCache or {}
                if not _G.AimTouchVisCache[tId] or curTime < _G.AimTouchVisCache[tId].time or (curTime - _G.AimTouchVisCache[tId].time) > 0.2 then
                    local isHidden = true
                    pcall(function() if pc:LineOfSightTo(target) then isHidden = false end end)
                    _G.AimTouchVisCache[tId] = { hidden = isHidden, time = curTime }
                end
                if _G.AimTouchVisCache[tId].hidden then break end
            end
            
            local tPos = target.GetBonePos and target:GetBonePos(selBoneName, {X=0, Y=0, Z=0})
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
                        elseif boneIdx == 3 then tPos.Z = tPos.Z + 20
                        elseif boneIdx == 5 then tPos.Z = tPos.Z - 60 end
                    end
                end
            end
            if not tPos or (tPos.X == 0 and tPos.Y == 0 and tPos.Z == 0) then break end
            
            local screen = FVector2D()
            local success,outScreen = pc:ProjectWorldLocationToScreen(tPos, screen, false)
            if outScreen then screen=outScreen end
            if not success or screen.X <= 0 or screen.Y <= 0 then break end
            
            local dx = screen.X - centerX
            local dy = screen.Y - centerY
            local distScreen = math.sqrt(dx*dx + dy*dy)
            
            if distScreen > FOV_RADIUS then break end
            
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
            
            until true
        end
        
        local cache=_G.AimTouchVisCache
        local clock=_G.LunarFeatures.Now()
        if cache and (not _G.LunarFeatures.AimPruneDue or clock>=_G.LunarFeatures.AimPruneDue) then
            for key,entry in pairs(cache) do if clock<entry.time or clock-entry.time>1 then cache[key]=nil end end
            _G.LunarFeatures.AimPruneDue=clock+0.5
        end
        if not slua.isValid(bestTarget) then return end
        
        local finalBonePos = bestTarget.GetBonePos and bestTarget:GetBonePos(selBoneName, {X=0, Y=0, Z=0})
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
                    elseif boneIdx == 3 then finalBonePos.Z = finalBonePos.Z + 20
                    elseif boneIdx == 5 then finalBonePos.Z = finalBonePos.Z - 60 end
                end
            end
        end
        if not finalBonePos or (finalBonePos.X == 0 and finalBonePos.Y == 0 and finalBonePos.Z == 0) then return end
        
        local tVelocity = nil
        pcall(function()
            if type(bestTarget.GetVelocity) == "function" then
                tVelocity = bestTarget:GetVelocity()
            end
        end)

        if not isMortar and predVal > 0 then
            pcall(function()
                if tVelocity and (tVelocity.X ~= 0 or tVelocity.Y ~= 0) then
                    local distToEnemy = player:GetDistanceTo(bestTarget) / 100.0
                    local ToF = (distToEnemy / 800.0) * (predVal / 50.0) 
                    finalBonePos.X = finalBonePos.X + (tVelocity.X * ToF)
                    finalBonePos.Y = finalBonePos.Y + (tVelocity.Y * ToF)
                end
            end)
        end

        if isADS and isFiring then
            local dist = player:GetDistanceTo(bestTarget) / 100.0
            finalBonePos.Z = finalBonePos.Z - (dist * 1.1)
        end

        local rot = KismetMathLibrary.FindLookAtRotation(camLoc, finalBonePos)
        if not rot then return end
        
        local currentRot = pc:GetControlRotation()
        if not currentRot then return end

        if not isADS then
            _G.XthrlenState.offPitch = 0
            _G.XthrlenState.offYaw   = 0
        end

        local dPitch = rot.Pitch - currentRot.Pitch
        local dYaw   = rot.Yaw   - currentRot.Yaw

        if isADS then
            local camRot = nil
            if type(camManager.GetCameraRotation) == "function" then
                camRot = camManager:GetCameraRotation()
            end
            if camRot then
                dYaw   = dYaw   - (camRot.Yaw   - currentRot.Yaw)
                dPitch = dPitch - (camRot.Pitch - currentRot.Pitch)
            end
        end

        if dPitch~=dPitch or dYaw~=dYaw or math.abs(dPitch)==math.huge or math.abs(dYaw)==math.huge then return end
        dPitch=(dPitch+180)%360-180
        dYaw=(dYaw+180)%360-180

        -- Displayed settings are 120..150. The requested maximum applies
        -- at most half the previous full correction; low settings are gentler.
        local now=_G.LunarFeatures.Now()
        local previous=_G.LunarFeatures.AimLastClock
        local dt=previous and math.max(0.001,math.min(0.05,now-previous)) or 0.011
        _G.LunarFeatures.AimLastClock=now
        local normalized=(_G.LunarFeatures.Clamp(speedVal,120,150,120)-120)/30.0
        local strength=0.02+0.48*normalized*normalized
        local alpha=math.min(0.5,1.0-(1.0-strength)^(dt/0.011))
        local maxTurnRate=10.0+35.0*normalized

        -- Camera-relative ADS error already accounts for view/controller offset.
        -- Repeatedly accumulating target error causes windup and unwanted swipes.
        _G.XthrlenState.offPitch=0;_G.XthrlenState.offYaw=0
        local apply={Pitch=currentRot.Pitch+dPitch,Yaw=currentRot.Yaw+dYaw,Roll=0}

        local pitchDelta=(apply.Pitch-currentRot.Pitch+180)%360-180
        local yawDelta=(apply.Yaw-currentRot.Yaw+180)%360-180
        local pitchStep,yawStep=pitchDelta*alpha,yawDelta*alpha
        local stepLength=math.sqrt(pitchStep*pitchStep+yawStep*yawStep)
        local stepLimit=maxTurnRate*dt
        if stepLength>stepLimit then
            local scale=stepLimit/stepLength
            pitchStep=pitchStep*scale;yawStep=yawStep*scale
        end
        local out={Pitch=currentRot.Pitch+pitchStep,Yaw=currentRot.Yaw+yawStep,Roll=0}

        out = clampAngles(out)
        pc:SetControlRotation(out, "AimTouch")
    end)
    if not ok then _G.LunarFeatures.Error("Aim",err) end
end



_G.LunarFeatures.Aim={Tick=_G.AimTouch}
end

-- Preserve the reference's DrawDyeing/Highlight/IdeaOutline settings and cadence.
-- Deduplicate mesh identities; do not assume the game leaves material flags alone.
do
    local F=_G.LunarFeatures
    local valid=g_masterahsanyt_ESPValid
    local classes={}
    for _,name in ipairs({"SkeletalMeshComponent","StaticMeshComponent"}) do
        local ok,value=pcall(import,name)
        if ok and value then classes[#classes+1]=value end
    end
    local W={Meshes={},Pawns={},LastTick=-999,LastCleanup=-999,CleanupInterval=1/60,ConsoleWorld=nil,Applied=0}
    F.Wall=W
    local properties={
        {"SetDrawDyeing","bDrawDyeing"},{"SetDrawHighlight","bDrawHighlight"},
        {"SetDrawIdeaOutline","bDrawIdeaOutline"},{"SetRenderCustomDepth","bRenderCustomDepth"}
    }
    local function calls(vis,occ)
        return {
            {"SetDrawDyeing",true},{"SetDrawDyeingMode",1},{"SetVisibleDyeingColor",vis},{"SetOccludedDyeingColor",occ},
            {"SetDyeingColorFadeDistance",99999.0},{"SetDyeingColorMinMaxDistance",0.0,99999.0},
            {"SetDrawHighlight",true},{"OverrideHighlightColor",vis},{"SetHighlightCanBeOccluded",false},
            {"SetDrawIdeaOutline",true},{"SetIdeaOutlineNew",true},{"SetIdeaOutlineOcclusionHighlight",true},
            {"OverrideIdeaOutlineColor",vis},{"SetIdeaOutlineOcclusionColor",occ},{"OverrideIdeaOutlineThickness",20.0},
            {"SetIdeaOverrideOutlineAndOcclusion",true},{"SetRenderCustomDepth",true},{"SetCustomDepthStencilValue",255}
        }
    end
    -- Wall shader colors retain the working intensity 100 and alpha 100.
    -- Slot 6 uses the supplied saffron RGB (100,1,0); slot 7 is red.
    local palette={{100,0,35},{100,100,100},{0,100,100},{0,100,0},
        {100,100,0},{100,1,0},{100,0,0}}
    W.Palette=palette
    local colorCalls
    W.UpdateColors=function()
        local a=palette[F.Settings.WallVisible] or palette[1]
        local b=palette[F.Settings.WallOccluded] or palette[2]
        local vis=g_masterahsanyt_ESPColor(a[1],a[2],a[3],100)
        local occ=g_masterahsanyt_ESPColor(b[1],b[2],b[3],100)
        colorCalls=calls(vis,occ)
        W.LastTick=-999
    end
    W.UpdateColors()
    local function invoke(mesh,call)
        local method=mesh[call[1]]
        if not method then return end
        if call[3]~=nil then method(mesh,call[2],call[3]) else method(mesh,call[2]) end
    end
    local function restore(mesh,state)
        if not valid(mesh) then return end
        for _,pair in ipairs(properties) do
            pcall(function() if mesh[pair[1]] then mesh[pair[1]](mesh,state[pair[2]]==true) end end)
        end
    end
    W.Stop=function()
        for mesh,state in pairs(W.Meshes) do restore(mesh,state) end
        W.Meshes={};W.Pawns={}
        W.LastTick=-999;W.LastCleanup=-999
    end
    local function relevant(pawn,myLocation,maxRange,pc)
        local entry=ESPShared.GetFrameRecord(pawn)
        return entry.Alive and ESPShared.InRange(entry,myLocation,maxRange)
            and pc and ESPShared.ProbeActor(pc,pawn).OnScreen
    end
    W.Cleanup=function(myLocation,maxRange,pc)
        for pawn,meshes in pairs(W.Pawns) do
            if not relevant(pawn,myLocation,maxRange,pc) then
                for mesh in pairs(meshes) do
                    local state=W.Meshes[mesh]
                    if state then restore(mesh,state);W.Meshes[mesh]=nil end
                end
                W.Pawns[pawn]=nil
            end
        end
    end
    local function apply(mesh,pawn,seen)
        if not valid(mesh) or seen[mesh] then return end
        seen[mesh]=true
        local original=W.Meshes[mesh]
        if not original then
            original={}
            for _,pair in ipairs(properties) do pcall(function() original[pair[2]]=mesh[pair[2]]==true end) end
            W.Meshes[mesh]=original
        end
        if original.Pawn and original.Pawn~=pawn then
            local old=W.Pawns[original.Pawn]
            if old then old[mesh]=nil;if next(old)==nil then W.Pawns[original.Pawn]=nil end end
        end
        original.Pawn=pawn
        local owned=W.Pawns[pawn]
        if not owned then owned={};W.Pawns[pawn]=owned end
        owned[mesh]=true
        -- Each protected setter is attempted independently. An unavailable optional
        -- extension does not prevent other reference rendering modes from applying.
        for _,call in ipairs(colorCalls) do
            local ok,err=pcall(invoke,mesh,call)
            if not ok then F.Error("Wall."..call[1],err) end
        end
        W.Applied=W.Applied+1
    end
    W.Tick=function(now,me,pc)
        if not F.Settings.WallEnabled then return end
        now=now or F.Now()
        me=me or g_masterahsanyt_ESPGetLocalCharacter()
        pc=pc or g_masterahsanyt_ESPGetController()
        if not valid(me) or not valid(pc) then W.Stop() return end
        local maxRange=tonumber(_G.g_masterahsanyt_MasterShotESP.MaxRangeMeters) or 450.0
        if maxRange~=maxRange or maxRange<=0 or maxRange==math.huge then maxRange=450.0 end
        local myLocation=ESPShared.GetFrameRecord(me).Location
        if now<W.LastCleanup or now-W.LastCleanup>=W.CleanupInterval-0.000001 then
            W.Cleanup(myLocation,maxRange,pc);W.LastCleanup=now
        end
        if now>=W.LastTick and now-W.LastTick<0.30-0.000001 then return end
        W.LastTick=now
        local world=g_masterahsanyt_ESPWorld()
        if world~=W.ConsoleWorld then
            local ok=pcall(function()
                if not world or not UKismetSystemLibrary.ExecuteConsoleCommand then return end
                for _,command in ipairs({"r.EnableDrawDyeingColor 1","r.CustomDepth 3","r.IdeaOutline.Enable 1","r.Highlight.Enable 1"}) do
                    UKismetSystemLibrary.ExecuteConsoleCommand(world,command)
                end
            end)
            if ok and world then W.ConsoleWorld=world end
        end
        local pawns=ESPShared.GetFramePawns()
        if not pawns then return end
        local seen={}
        local myTeam=me.TeamID or 0
        for _,pawn in pairs(pawns) do
            if valid(pawn) and pawn~=me and pawn.TeamID~=myTeam and relevant(pawn,myLocation,maxRange,pc) then
                pcall(function() apply(pawn.Mesh,pawn,seen) end)
                local avatar=nil
                pcall(function()
                    avatar=pawn.CharacterAvatarComp2_BP
                    if not avatar and pawn.getAvatarComponent2 then avatar=pawn:getAvatarComponent2() end
                end)
                if avatar and avatar.GetMeshCompBySlot then
                    for slot=0,7 do pcall(function() apply(avatar:GetMeshCompBySlot(slot),pawn,seen) end) end
                end
                for _,class in ipairs(classes) do
                    pcall(function()
                        if not pawn.GetComponentsByClass then return end
                        local components=pawn:GetComponentsByClass(class)
                        if components then for i=0,components:Num()-1 do apply(components:Get(i),pawn,seen) end end
                    end)
                end
                pcall(function()
                    local weapon=pawn.GetCurrentWeapon and pawn:GetCurrentWeapon()
                    if valid(weapon) then apply(weapon.Mesh,pawn,seen) end
                end)
            end
        end
        for mesh,state in pairs(W.Meshes) do
            if not seen[mesh] then
                restore(mesh,state);W.Meshes[mesh]=nil
                local owned=W.Pawns[state.Pawn]
                if owned then owned[mesh]=nil;if next(owned)==nil then W.Pawns[state.Pawn]=nil end end
            end
        end
    end
    _G.StartWallhack=function() F.SetWall(true) end
    _G.StopWallhack=function() F.SetWall(false) end
end

do
_G.g_Botmater_ESPOptions = _G.g_Botmater_ESPOptions or {
    Name = false,
    Box = false,
    Weapon = false,
    Flag = false,
    Visibility = false,
    Alert = false,
    Line = false,
    Health = false,
    Distance = false,
    EnemyCounter = false,
}

_G.g_Botmater_MasterShotESP = _G.g_Botmater_MasterShotESP or {
    Enabled = true,
    MaxRangeMeters = 350.0,
    ScanInterval = 0.15,
    UpdateInterval = 1/60,
    TransformInterval = 0.033,
    MaxRendered = 20,
    TracerThickness = 2.0,
    NameGap = 2.0,
    NameFontSize = 9,
    DistanceFontSize = 10,
    DistanceBelowFeet = 14,
}
-- ESP V1 settings remain independent from _G.MasterShotESP (ESP V2).

local g_Botmater_ShotESP = {
    Canvas = nil,
    Enemies = {},
    Lines = {},
    Names = {},
    LastScanClock = -999.0,
    LastTransformClock = -999.0,
    LastWorld = nil,
    CanvasScaleX = 1.0,
    CanvasScaleY = 1.0,
    CanvasOffsetX = 0.0,
    CanvasOffsetY = 0.0,
    LastPawn=nil,
    LastController=nil,
    Active={},
    Alive={},
    LastProjected={},
    Metadata={},BuildDue={},
    Diagnostics={MetadataReads=0,CountryReads=0,SightChecks=0},
    RealCount = 0,
    BotCount = 0,
}

local V2 = _G.FVector2D
if not V2 then pcall(function() V2 = import("Vector2D") end) end
local LinearColor = _G.FLinearColor
if not LinearColor then pcall(function() LinearColor = import("LinearColor") end) end
local SlateBlueprintLibrary = nil
pcall(function() SlateBlueprintLibrary = import("SlateBlueprintLibrary") end)
local WidgetLayoutLibrary = nil
pcall(function() WidgetLayoutLibrary = import("WidgetLayoutLibrary") end)

local function g_Botmater_ESPV2(x, y)
    if V2 then return V2(x, y) end
    return {X = x, Y = y}
end

local function g_Botmater_ESPColor(r, g, b, a)
    if LinearColor then return LinearColor(r, g, b, a or 1.0) end
    return {R=r, G=g, B=b, A=a or 1.0}
end

local COLOR_REAL_BLUE=g_Botmater_ESPColor(.035,.48,1,1)
local COLOR_BOT_WHITE=g_Botmater_ESPColor(1,1,1,1)
local CACHE_COUNTER_PLAYER_BG=g_Botmater_ESPColor(.025,.28,.72,1)
local CACHE_COUNTER_BOT_BG=g_Botmater_ESPColor(.008,.012,.021,1)
local CACHE_COUNTER_PLAYER_TEXT=COLOR_BOT_WHITE
local CACHE_COUNTER_BOT_TEXT=COLOR_BOT_WHITE
local function g_Botmater_ESPGetColors(isBot)
    return isBot and COLOR_BOT_WHITE or COLOR_REAL_BLUE,COLOR_BOT_WHITE
end

local function g_Botmater_ESPValid(obj)
    if not obj then return false end
    local ok, valid = pcall(function() return slua.isValid(obj) end)
    return ok and valid == true
end

local function g_Botmater_ESPNow() return _G.LunarFeatures.Now() end

local function g_Botmater_ESPWorld()
    local w = nil
    pcall(function() if slua and slua.getWorld then w = slua.getWorld() end end)
    return w
end

local function g_Botmater_ESPGetController() return g_masterahsanyt_ESPGetController() end
local function g_Botmater_ESPGetLocalCharacter() return g_masterahsanyt_ESPGetLocalCharacter() end

local function g_Botmater_ESPGetPlayerState(character)
    if not g_Botmater_ESPValid(character) then return nil end
    local ps = nil
    pcall(function()
        if character.GetPlayerStateSafety then ps = character:GetPlayerStateSafety() end
    end)
    if not g_Botmater_ESPValid(ps) then
        pcall(function() if character.GetPlayerState then ps = character:GetPlayerState() end end)
    end
    if not g_Botmater_ESPValid(ps) then
        pcall(function() ps = character.PlayerState end)
    end
    return g_Botmater_ESPValid(ps) and ps or nil
end

local function g_Botmater_ESPNormalizeName(value)
    if value == nil or value == false then return nil end
    local ok, text = pcall(tostring, value)
    if not ok or not text then return nil end
    text = text:gsub("^%s+", ""):gsub("%s+$", "")
    if text == "" or text == "nil" or text == "None" or text == "NULL" then return nil end
    return text
end

local function g_Botmater_ESPResolvePlayerName(character)
    if not g_Botmater_ESPValid(character) then return nil end
    local name = nil
    local function take(value)
        if not name then name = g_Botmater_ESPNormalizeName(value) end
    end
    pcall(function() if character.GetPlayerNameSafety then take(character:GetPlayerNameSafety()) end end)
    pcall(function() if not name and character.GetPlayerName then take(character:GetPlayerName()) end end)
    pcall(function() if not name then take(character.PlayerName) end end)
    pcall(function() if not name then take(character.NickName) end end)
    if not name then
        local ps = g_Botmater_ESPGetPlayerState(character)
        if ps then
            pcall(function() if ps.GetPlayerName then take(ps:GetPlayerName()) end end)
            pcall(function() if not name then take(ps.PlayerName) end end)
            pcall(function() if not name then take(ps.PlayerNamePrivate) end end)
            pcall(function() if not name then take(ps.NickName) end end)
        end
    end
    return name
end

local function g_Botmater_ESPGetPlayerKey(c) return g_masterahsanyt_ESPGetPlayerKey(c) end

local function g_Botmater_ESPGetTeamID(character)
    if not g_Botmater_ESPValid(character) then return nil end
    local id = nil
    pcall(function() if character.GetTeamID then id = character:GetTeamID() end end)
    if id == nil then pcall(function() id = character.TeamID end) end
    if id == nil then
        local ps = g_Botmater_ESPGetPlayerState(character)
        if ps then
            pcall(function() if ps.GetTeamID then id = ps:GetTeamID() end end)
            if id == nil then pcall(function() id = ps.TeamID end) end
        end
    end
    return id
end



local function g_Botmater_ESPIsBot(c)
    g_Botmater_ShotESP._BotCache=g_Botmater_ShotESP._BotCache or {}
    return g_masterahsanyt_ESPIsBot(c,g_masterahsanyt_ESPGetPlayerKey(c),g_Botmater_ShotESP._BotCache,_G.LunarFeatures.Now())
end

-- Deferred cleanup owns widgets only, never an actor, key or player name.
-- Admission is stopped well below the hard limit while native cleanup fails.
local V1Cleanup={Items={},Members={},Count=0,Cursor=1,Due=0,Limit=512,AdmissionLimit=128}
function V1Cleanup.Try(widget)
    if not g_Botmater_ESPValid(widget) then return true end
    local hidden,accepted=pcall(function() return widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
    if not hidden or accepted==false then pcall(function() widget:SetRenderOpacity(0) end) end
    local ok,result=pcall(function() return widget:RemoveFromParent() end)
    if not ok or result==false then return false end
    local checked,parent=pcall(function() return widget:GetParent() end)
    return not checked or parent==nil
end
function V1Cleanup.Retire(widget)
    if not widget then return true end
    if V1Cleanup.Members[widget] then return true end
    if V1Cleanup.Try(widget) then return true end
    if V1Cleanup.Count>=V1Cleanup.Limit then return false end
    V1Cleanup.Count=V1Cleanup.Count+1
    V1Cleanup.Items[V1Cleanup.Count]=widget
    V1Cleanup.Members[widget]=true
    return true
end
function V1Cleanup.Pump(now)
    if V1Cleanup.Count==0 then return end
    if now>=V1Cleanup.Due-0.05 and now<V1Cleanup.Due then return end
    V1Cleanup.Due=now+0.05
    local budget=math.min(8,V1Cleanup.Count)
    while budget>0 and V1Cleanup.Count>0 do
        budget=budget-1
        local i=V1Cleanup.Cursor
        if i>V1Cleanup.Count then i=1 end
        local widget=V1Cleanup.Items[i]
        if V1Cleanup.Try(widget) then
            V1Cleanup.Members[widget]=nil
            V1Cleanup.Items[i]=V1Cleanup.Items[V1Cleanup.Count]
            V1Cleanup.Items[V1Cleanup.Count]=nil
            V1Cleanup.Count=V1Cleanup.Count-1
            V1Cleanup.Cursor=i
        else
            V1Cleanup.Cursor=i+1
        end
    end
end
ESPWidgetPool.V1.Remove=V1Cleanup.Retire

local function g_Botmater_ESPDestroyWidgetData(data)
    if not data then return true end
    if ESPWidgetPool.Release(data) then return true end
    return V1Cleanup.Retire(data.Widget or data.Container)
end

local function g_Botmater_ESPResetWidgets()
    g_Botmater_ShotESP.EdgePlacements=nil;g_Botmater_ShotESP.AlertLayoutCache=nil
    g_Botmater_ShotESP.AlertScratchRecords=nil;g_Botmater_ShotESP.AlertScratchPool=nil;g_Botmater_ShotESP.AlertScratchPlacements=nil
    ESPShared.Frame.V1CanvasChecked=false
    ESPWidgetPool.V1.Enabled=false
    for _,registry in ipairs({g_Botmater_ShotESP.Lines,g_Botmater_ShotESP.Names}) do
        for key,data in pairs(registry) do
            if g_Botmater_ESPDestroyWidgetData(data) then registry[key]=nil end
        end
    end
    g_Botmater_ShotESP.Canvas=nil
    g_Botmater_ShotESP.RootUI=nil
    g_Botmater_ShotESP.Enemies={}
    g_Botmater_ShotESP._BotCache={}
    g_Botmater_ShotESP.Active={}
    g_Botmater_ShotESP.Alive={}
    g_Botmater_ShotESP.LastProjected={}
    g_Botmater_ShotESP.Metadata={};g_Botmater_ShotESP.BuildDue={};g_Botmater_ShotESP.RenderCursor=0
    g_Botmater_ShotESP.RealCount=0;g_Botmater_ShotESP.BotCount=0
    g_Botmater_ShotESP.LastScanClock=-999
    g_Botmater_ShotESP.LastTransformClock=-999
    g_Botmater_ShotESP.LastPawn=nil;g_Botmater_ShotESP.LastController=nil
    g_Botmater_ShotESP.CanvasScaleX=1;g_Botmater_ShotESP.CanvasScaleY=1
    g_Botmater_ShotESP.CanvasOffsetX=0;g_Botmater_ShotESP.CanvasOffsetY=0
    g_Botmater_ShotESP.TransformReady=false
    g_Botmater_ShotESP.TransformW=nil;g_Botmater_ShotESP.TransformH=nil
    ESPWidgetPool.Flush(ESPWidgetPool.V1)
    ESPWidgetPool.V1.Enabled=true
end

local function g_Botmater_ESPGetCanvas()
    -- Compare the current HUD identity; native validity alone does not mean
    -- that a retained canvas still belongs to the visible HUD.
    local frame=ESPShared.Frame
    if frame.Active and frame.V1CanvasChecked then
        return g_Botmater_ESPValid(g_Botmater_ShotESP.Canvas) and g_Botmater_ShotESP.Canvas or nil
    end
    local root
    pcall(function()
        local ui=require("GameLua.Mod.BaseMod.Common.UI.InGameUITools")
        if ui and ui.GetMainControlBaseUI then root=ui.GetMainControlBaseUI() end
    end)
    if not g_Botmater_ESPValid(root) then
        if g_Botmater_ShotESP.Canvas then g_Botmater_ESPResetWidgets() end
        return nil
    end
    local canvas
    pcall(function()
        if g_Botmater_ESPValid(root.CanvasPanel_0) then canvas=root.CanvasPanel_0
        elseif g_Botmater_ESPValid(root.CanvasPanel_42) then canvas=root.CanvasPanel_42 end
    end)
    if not g_Botmater_ESPValid(canvas) then
        if g_Botmater_ShotESP.Canvas then g_Botmater_ESPResetWidgets() end
        return nil
    end
    if g_Botmater_ShotESP.Canvas~=canvas or g_Botmater_ShotESP.RootUI~=root then
        g_Botmater_ESPResetWidgets()
        g_Botmater_ShotESP.Canvas=canvas;g_Botmater_ShotESP.RootUI=root
    end
    if frame.Active then frame.V1CanvasChecked=true end
    return canvas
end

local function g_Botmater_ESPViewport(pc) return g_masterahsanyt_ESPViewport(pc) end

local function g_Botmater_ESPGetCanvasLocalSize()
    local canvas = g_Botmater_ESPGetCanvas()
    if not g_Botmater_ESPValid(canvas) then return nil, nil end
    local cw, ch = nil, nil
    pcall(function()
        local geo = canvas:GetCachedGeometry()
        if not geo then return end
        local size = nil
        if geo.GetLocalSize then size = geo:GetLocalSize()
        elseif SlateBlueprintLibrary and SlateBlueprintLibrary.GetLocalSize then size = SlateBlueprintLibrary.GetLocalSize(geo) end
        if size and ESPShared.Finite(size.X) and ESPShared.Finite(size.Y) and size.X > 1 and size.Y > 1 then
            cw, ch = tonumber(size.X), tonumber(size.Y)
        end
    end)
    return cw, ch
end

local function g_Botmater_ESPUpdateCanvasTransform(pc)
    local state=g_Botmater_ShotESP
    local canvas=g_Botmater_ESPGetCanvas()
    if not g_Botmater_ESPValid(canvas) then return false end
    local width,height=ESPShared.ViewSize(pc)
    local sameViewport=state.TransformW==width and state.TransformH==height
    local calibrated=false
    pcall(function()
        local geo=canvas:GetCachedGeometry()
        if SlateBlueprintLibrary and SlateBlueprintLibrary.AbsoluteToLocal and geo then
            local p0=SlateBlueprintLibrary.AbsoluteToLocal(geo,g_Botmater_ESPV2(0,0))
            local p1=SlateBlueprintLibrary.AbsoluteToLocal(geo,g_Botmater_ESPV2(100,100))
            if p0 and p1 and ESPShared.Finite(p0.X) and ESPShared.Finite(p0.Y)
                and ESPShared.Finite(p1.X) and ESPShared.Finite(p1.Y)
                and math.abs(p0.X)<1e7 and math.abs(p0.Y)<1e7
                and p1.X>p0.X and p1.Y>p0.Y
                and p1.X-p0.X<10000 and p1.Y-p0.Y<10000 then
                state.CanvasScaleX=(p1.X-p0.X)/100
                state.CanvasScaleY=(p1.Y-p0.Y)/100
                state.CanvasOffsetX=p0.X;state.CanvasOffsetY=p0.Y
                calibrated=true
            end
        end
    end)
    -- A transient missing geometry sample must not toggle coordinate systems.
    if not calibrated and state.TransformReady and sameViewport then return true end
    if not calibrated then
        local scale=1
        pcall(function()
            if WidgetLayoutLibrary and WidgetLayoutLibrary.GetViewportScale then
                local s=WidgetLayoutLibrary.GetViewportScale(pc)
                if ESPShared.Finite(s) and s>=0.01 and s<=100 then scale=s end
            end
        end)
        state.CanvasScaleX=1/scale;state.CanvasScaleY=1/scale
        state.CanvasOffsetX=0;state.CanvasOffsetY=0
    end
    state.TransformReady=true;state.TransformW=width;state.TransformH=height
    return true
end

local function g_Botmater_ESPSetFont(widget,size) g_masterahsanyt_ESPSetFont(widget,size,0) end
local function g_Botmater_ESPSetTextColor(widget,color) g_masterahsanyt_ESPSetTextColor(widget,color) end

local function g_Botmater_ESPCreateLine(color)
    if V1Cleanup.Count>=V1Cleanup.AdmissionLimit then return nil end
    local canvas = g_Botmater_ESPGetCanvas()
    if not g_Botmater_ESPValid(canvas) then return nil end
    local pooled=true and ESPWidgetPool.Take(ESPWidgetPool.V1,"Line",canvas)
    if pooled then
        local ok=pcall(function() pooled.Widget:SetBrushColor(color) end)
        if ok then pooled.Visible=false;return pooled end
        V1Cleanup.Retire(pooled.Widget)
    end
    local border = nil
    pcall(function() border = CGame:NewObjectFromPath("/Script/UMG.Border", canvas) end)
    if not g_Botmater_ESPValid(border) then return nil end
    pcall(function()
        border:SetBrushColor(color)
        border:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        border:SetRenderTransformPivot(g_Botmater_ESPV2(0.0, 0.5))
    end)
    local slot = nil
    pcall(function() slot = canvas:AddChildToCanvas(border) end)
    if not slot then g_Botmater_ESPDestroyWidgetData({Widget=border}) return nil end
    pcall(function() slot:SetAutoSize(false) slot:SetZOrder(30) end)
    local data={Widget=border, Slot=slot, Visible=true}
    if true then ESPWidgetPool.Tag(ESPWidgetPool.V1,"Line",canvas,data) end
    return data
end

local function g_Botmater_ESPDrawLine(...) return g_masterahsanyt_ESPDrawLine(...) end

local function g_Botmater_ESPHide(data)
    if data and g_Botmater_ESPValid(data.Widget) then
        if data.Visible ~= false then
            pcall(function() data.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
            data.Visible = false
        end
    end
end

-- Only read enemy metadata. No native CharacterBase registration or hooks from
-- the reference file are installed. Weapon access follows its R20 lookup chain.
local V1Info={WeaponRows={},WeaponCount=0,Regions={},RegionCount=0,Provider=nil,Loc=nil,LocDue=0}
do
function V1Info.Read(object,key)
    if object==nil then return nil end
    local ok,value=pcall(function() return object[key] end)
    if ok then return value end
end
function V1Info.Call(object,key,...)
    local fn=V1Info.Read(object,key)
    if type(fn)~="function" then return nil end
    local ok,value=pcall(fn,object,...)
    if ok then return value end
end
function V1Info.TextValue(value)
    if type(value)=="string" then return value end
    if type(value)~="userdata" and type(value)~="table" then return nil end
    local text=V1Info.Call(value,"ToString") or V1Info.Call(value,"GetString")
    if type(text)=="string" then return text end
    local ok,s=pcall(tostring,value)
    if ok and type(s)=="string" and not s:match("^table:") and not s:match("^userdata:") then return s end
end
function V1Info.Clean(value,limit)
    value=V1Info.TextValue(value)
    if not value then return nil end
    value=value:gsub("[%c]"," "):match("^%s*(.-)%s*$")
    if value=="" or value=="nil" or value=="None" or value=="NULL" then return nil end
    if #value>(limit or 96) then
        local n=limit or 96
        while n>0 and (value:byte(n+1) or 0)>=128 and (value:byte(n+1) or 0)<192 do n=n-1 end
        value=value:sub(1,n).."..."
    end
    return value
end
function V1Info.ProviderNow()
    local provider=rawget(_G,"CDataTable")
    if provider~=V1Info.Provider then
        V1Info.WeaponRows={};V1Info.WeaponCount=0;V1Info.Provider=provider
        V1Info.Regions={};V1Info.RegionCount=0
    end
    return provider
end
function V1Info.WeaponLabel(value)
    local name=V1Info.Clean(value,64)
    if name then
        name=name:gsub("^BP_",""):gsub("_C$",""):gsub("_Wrapper$","")
        if name=="" or name=="0" then return nil end
    end
    return name
end
function V1Info.WeaponID(id)
    if type(id)=="number" then return ESPShared.Finite(id) and id>0 and id or nil end
    if type(id)=="string" and id~="" and id~="0" then return tonumber(id) or id end
end
function V1Info.Weapon(actor,now)
    local r,c=V1Info.Read,V1Info.Call
    local id,name,hasWeapon,empty=false,nil,false,false
    local seen={}
    local function inspect(weapon)
        if not g_Botmater_ESPValid(weapon) or seen[weapon] then return end
        seen[weapon]=true;hasWeapon=true
        id=id or V1Info.WeaponID(c(weapon,"GetWeaponID")) or V1Info.WeaponID(r(weapon,"WeaponID")) or V1Info.WeaponID(c(weapon,"GetItemID"))
        name=name or V1Info.WeaponLabel(c(weapon,"GetWeaponName")) or V1Info.WeaponLabel(r(weapon,"WeaponName"))
    end
    for _,method in ipairs({"GetCurrentWeapon","GetCurrentShootWeapon"}) do
        local fn=r(actor,method)
        if type(fn)=="function" then
            local ok,weapon=pcall(fn,actor)
            if ok then if weapon==nil or weapon==false then empty=true else inspect(weapon) end end
        end
        if name then return name,id or nil end
    end
    inspect(r(actor,"CurrentWeapon"))
    if name then return name,id or nil end
    local managers={c(actor,"GetWeaponManager") or false,r(actor,"WeaponManagerComponent") or false}
    for _,manager in ipairs(managers) do
        if manager then
            inspect(c(manager,"GetCurrentWeapon"));inspect(r(manager,"CurrentWeaponReplicated"));inspect(r(manager,"CurrentWeapon"))
            if name then return name,id or nil end
        end
    end
    local ps=g_Botmater_ESPGetPlayerState(actor)
    id=id or V1Info.WeaponID(c(ps,"GetCurrentWeaponID")) or V1Info.WeaponID(r(ps,"CurWeaponID"))
    local provider=V1Info.ProviderNow()
    if id then
        local cached=V1Info.WeaponRows[id]
        if cached and now>=cached.At and now<cached.Due then name=cached.Name
        else
            local reader=r(provider,"GetTableData")
            if type(reader)=="function" then
                local ok,row=pcall(reader,"Item",id)
                if ok and row then
                    for _,field in ipairs({"ItemName","DisplayName","WeaponName","Name","ItemNameID"}) do
                        local value=r(row,field)
                        if type(value)=="number" or V1Info.Clean(value,64) then name=value;break end
                    end
                    if type(name)=="number" then
                        if now>=V1Info.LocDue or now<V1Info.LocDue-2 then
                            V1Info.Loc=rawget(_G,"LocUtil")
                            if not V1Info.Loc then local loaded,v=pcall(require,"client.common.LocUtil");if loaded then V1Info.Loc=v end end
                            V1Info.LocDue=now+2
                        end
                        local loc=r(V1Info.Loc,"GetLocalizeResStr") or r(V1Info.Loc,"GetText") or r(V1Info.Loc,"GetLocalizeStr")
                        if type(loc)=="function" then local good,text=pcall(loc,name);name=good and text or nil else name=nil end
                    end
                    name=V1Info.WeaponLabel(name)
                end
            end
            if V1Info.WeaponCount>=128 then V1Info.WeaponRows={};V1Info.WeaponCount=0 end
            if not V1Info.WeaponRows[id] then V1Info.WeaponCount=V1Info.WeaponCount+1 end
            V1Info.WeaponRows[id]={Name=name,At=now,Due=now+(name and 30 or 2)}
        end
    end
    if name then return name,id end
    -- Fist requires an observed empty weapon getter, not a missing binding.
    if not hasWeapon and not id and empty then return "Fist",nil end
    return "Unknown",id or nil
end
local ISO_CODES={}
for code in ("AD AE AF AG AI AL AM AO AQ AR AS AT AU AW AX AZ BA BB BD BE BF BG BH BI BJ BL BM BN BO BQ BR BS BT BV BW BY BZ CA CC CD CF CG CH CI CK CL CM CN CO CR CU CV CW CX CY CZ DE DJ DK DM DO DZ EC EE EG EH ER ES ET FI FJ FK FM FO FR GA GB GD GE GF GG GH GI GL GM GN GP GQ GR GS GT GU GW GY HK HM HN HR HT HU ID IE IL IM IN IO IQ IR IS IT JE JM JO JP KE KG KH KI KM KN KP KR KW KY KZ LA LB LC LI LK LR LS LT LU LV LY MA MC MD ME MF MG MH MK ML MM MN MO MP MQ MR MS MT MU MV MW MX MY MZ NA NC NE NF NG NI NL NO NP NR NU NZ OM PA PE PF PG PH PK PL PM PN PR PS PT PW PY QA RE RO RS RU RW SA SB SC SD SE SG SH SI SJ SK SL SM SN SO SR SS ST SV SX SY SZ TC TD TF TG TH TJ TK TL TM TN TO TR TT TV TW TZ UA UG UM US UY UZ VA VC VE VG VI VN VU WF WS YE YT ZA ZM ZW"):gmatch("%S+") do ISO_CODES[code]=true end
local COUNTRY_ALIAS={BANGLADESH="BD",PAKISTAN="PK",INDIA="IN",BGD="BD",PAK="PK",IND="IN",UK="GB",USA="US"}
function V1Info.CountryCode(value)
    if type(value)~="string" then return nil end
    local text=value:match("^%s*(.-)%s*$"):upper()
    local code=COUNTRY_ALIAS[text] or text
    if ISO_CODES[code] then return code end
end
local FLAG_DEFAULT="/Game/UMG/Texture/Atlas/NationalflagUI/Frames/T_icon_flag_iland_png.T_icon_flag_iland_png"
function V1Info.Region(nation,now)
    local provider=V1Info.ProviderNow()
    local cached=V1Info.Regions[nation]
    if cached and now>=cached.At and now<cached.Due then return cached.Path end
    local reader=V1Info.Read(provider,"GetTableData");local path
    if type(reader)=="function" then
        local ok,row=pcall(reader,"RegionConfig",nation)
        if ok and row then path=V1Info.Clean(V1Info.Read(row,"res_path"),512) end
    end
    -- The supplied source uses local native assets, never downloaded flags.
    if path then path=path:match("^[%w_]+['\"](/Game/.-)['\"]$") or path end
    if path and not path:match("^/Game/") and not path:match("^/Engine/") then path=nil end
    if V1Info.RegionCount>=128 then V1Info.Regions={};V1Info.RegionCount=0 end
    if not V1Info.Regions[nation] then V1Info.RegionCount=V1Info.RegionCount+1 end
    V1Info.Regions[nation]={Path=path or FLAG_DEFAULT,At=now,Due=now+(path and 60 or 2)}
    return path or FLAG_DEFAULT
end
function V1Info.Country(actor,now)
    local r,c=V1Info.Read,V1Info.Call
    local ps=g_Botmater_ESPGetPlayerState(actor)
    local objects={actor,ps or false,r(ps,"PlayerInfo") or false,r(actor,"PlayerInfo") or false}
    -- Exact source chain: PlayerState.Nation -> pawn.Nation -> G1.
    local nation=r(ps,"Nation") or r(actor,"Nation")
    if type(nation)=="number" and ESPShared.Finite(nation) then nation=tostring(nation) else nation=V1Info.Clean(nation,32) end
    if nation=="0" then nation=nil end
    local code,texture
    for _,object in ipairs(objects) do
        if object then
            if not code then
                for _,field in ipairs({"CountryCode","NationCode","Country","Nation","Nationality"}) do
                    code=V1Info.CountryCode(r(object,field));if code then break end
                end
                if not code then
                    for _,method in ipairs({"GetCountryCode","GetNationCode","GetCountry","GetNation"}) do
                        code=V1Info.CountryCode(c(object,method));if code then break end
                    end
                end
            end
            if not texture then
                local t=r(object,"CountryFlagTexture") or r(object,"NationFlagTexture") or c(object,"GetCountryFlagTexture")
                if g_Botmater_ESPValid(t) then texture=t end
            end
        end
    end
    if nation then code=V1Info.CountryCode(nation) end
    nation=nation or code or "G1"
    return code,texture,V1Info.Region(nation,now or g_Botmater_ESPNow()),nation
end
function V1Info.Get(item,pc,now,opt)
    local state=g_Botmater_ShotESP
    local data=state.Metadata[item.Key]
    if not data then data={};state.Metadata[item.Key]=data end
    if state.MetaBudget>0 and (not data.Due or now>=data.Due or now<data.Due-0.5) then
        state.MetaBudget=state.MetaBudget-1
        if opt.Name then data.Name=g_Botmater_ESPResolvePlayerName(item.Character) end
        if opt.Weapon then data.Weapon,data.WeaponID=V1Info.Weapon(item.Character,now) end
        if opt.Flag and (not data.CountryDue or now>=data.CountryDue or now<data.CountryDue-10) then
            data.Country,data.FlagTexture,data.FlagPath,data.Nation=V1Info.Country(item.Character,now)
            data.CountryDue=now+2
            state.Diagnostics.CountryReads=state.Diagnostics.CountryReads+1
        end
        data.Due=now+.5
        state.Diagnostics.MetadataReads=state.Diagnostics.MetadataReads+1
    end
    local sightReady=not state.NextSight or now>=state.NextSight-0.000001 or now<state.NextSight-.05
    if opt.Visibility and state.SightBudget>0 and sightReady and (not data.SightDue or now>=data.SightDue or now<data.SightDue-.4) then
        local age=data.SightAt or -math.huge
        if not state.SightData or age<state.SightAt then
            state.SightData=data;state.SightActor=item.Character;state.SightAt=age
        end
    end
    return data
end
function V1Info.FlushSight(pc,now)
    local state=g_Botmater_ShotESP;local data,actor=state.SightData,state.SightActor
    state.SightData=nil;state.SightActor=nil;state.SightAt=nil
    if not data or not ESPShared.Events.Visible(actor,ESPShared.GetFrameRecord(actor)) then return end
    state.SightBudget=state.SightBudget-1;state.NextSight=now+.05
    local seen=V1Info.Call(pc,"LineOfSightTo",actor)
    data.Cover=seen==true and "Open" or (seen==false and "Cover" or "Unknown")
    data.SightAt=now;data.SightDue=now+.4
    state.Diagnostics.SightChecks=state.Diagnostics.SightChecks+1
end
end

-- Country assets come from zn_knox.lua's RegionConfig/res_path binding.
-- Prefer native async Image loading. Late requests stay on their original Image.
local V1Flags={Assets={},Count=0,NextRequest=0,NextSync=0,NextPathSync=0,Requests=0,AsyncRequests=0,SyncLoads=0}
function V1Flags.Load(path,now)
    local cached=V1Flags.Assets[path]
    if cached then
        if cached.Texture and g_Botmater_ESPValid(cached.Texture) then return cached.Texture end
        if now>=cached.At and now<cached.Due then return nil end
    end
    if now>=V1Flags.NextSync-.2 and now<V1Flags.NextSync then return nil end
    V1Flags.NextSync=now+.2;V1Flags.SyncLoads=V1Flags.SyncLoads+1
    local loaded=V1Info.Read(package,"loaded")
    local util=V1Info.Read(loaded,"common.asset_util")
    local fn=V1Info.Read(util,"GetAssetSync");local texture
    if type(fn)=="function" then local ok,v=pcall(fn,path);if ok and g_Botmater_ESPValid(v) then texture=v end end
    if not texture then texture=V1Info.Call(CGame,"LoadObject",path) end
    if not g_Botmater_ESPValid(texture) then
        texture=nil;fn=V1Info.Read(slua,"loadObject")
        if type(fn)=="function" then local ok,v=pcall(fn,path);if ok and g_Botmater_ESPValid(v) then texture=v end end
    end
    if V1Flags.Count>=128 then V1Flags.Assets={};V1Flags.Count=0 end
    if not V1Flags.Assets[path] then V1Flags.Count=V1Flags.Count+1 end
    V1Flags.Assets[path]={Texture=texture,At=now,Due=now+2}
    return texture
end
function V1Flags.Apply(data,info,now)
    local texture=info.FlagTexture
    if texture and (not data.FlagValidatedAt or now>=data.FlagValidatedAt or now<data.FlagValidatedAt-1) then
        data.FlagValidatedAt=now+1
        if not g_Botmater_ESPValid(texture) then texture=nil end
    end
    local path=info.FlagPath
    if not texture and not path then return nil,false end
    local key=texture or path
    local node=data.Nodes.FlagImage
    if node and (node.Broken or (node.RequestKey and node.RequestKey~=key)) then
        V1Cleanup.Retire(node.Widget);data.Nodes.FlagImage=nil;node=nil
    end
    if not node then
        if g_Botmater_ShotESP.BuildBudget<1 or V1Cleanup.Count>=V1Cleanup.AdmissionLimit then return nil,false end
        g_Botmater_ShotESP.BuildBudget=g_Botmater_ShotESP.BuildBudget-1
        local image,slot
        local ok=pcall(function()
            image=CGame:NewObjectFromPath("/Script/UMG.Image",data.Widget);assert(g_Botmater_ESPValid(image))
            image:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
            slot=data.Widget:AddChildToCanvas(image);assert(slot)
            slot:SetAutoSize(false);slot:SetAlignment(g_Botmater_ESPV2(0,0));slot:SetZOrder(5)
        end)
        if not ok then V1Cleanup.Retire(image);return nil,false end
        node={Widget=image,Slot=slot,Kind="Image",Visible=false};data.Nodes.FlagImage=node
    end
    if node.RequestKey==key and node.Applied then return node,true end
    if node.RetryDue and now>=node.RetryDue-2 and now<node.RetryDue then return node,false end
    if g_Botmater_ShotESP.FlagBudget<1 or (now>=V1Flags.NextRequest-.04 and now<V1Flags.NextRequest) then return node,false end
    g_Botmater_ShotESP.FlagBudget=g_Botmater_ShotESP.FlagBudget-1
    V1Flags.NextRequest=now+.04;V1Flags.Requests=V1Flags.Requests+1;node.RequestKey=key
    local function attempt(method,...)
        local fn=V1Info.Read(node.Widget,method)
        if type(fn)~="function" then return false end
        local ok,value=pcall(fn,node.Widget,...)
        return ok and value~=false
    end
    local applied=false
    if texture then applied=attempt("SetBrushFromTexture",texture,false)
    elseif path then
        if attempt("SetBrushFromPathAsync",path,false) then
            node.AsyncPath=path;applied=true;V1Flags.AsyncRequests=V1Flags.AsyncRequests+1
        else
            local cached=V1Flags.Load(path,now)
            if cached then applied=attempt("SetBrushFromTexture",cached,false) end
            if not applied and not node.SyncTried and (now>=V1Flags.NextPathSync or now<V1Flags.NextPathSync-.2) then
                -- Compatibility with builds exposing only the source's path setter.
                node.SyncTried=true;V1Flags.NextPathSync=now+.2;applied=attempt("SetBrushResourceFromPathSync",path,false)
            end
        end
    end
    node.Applied=applied;node.RetryDue=not applied and now+2 or nil
    return node,applied
end

local V1Draw={}
do
local CARD_WHITE=g_Botmater_ESPColor(1,1,1,1)
local CARD_BLUE=g_Botmater_ESPColor(.035,.48,1,1)
local CARD_TRACK=g_Botmater_ESPColor(.55,.65,.8,.35)
local CARD_AMBER=g_Botmater_ESPColor(1,.65,.06,1)
local CARD_CYAN=g_Botmater_ESPColor(.02,.85,1,1)
local CARD_RED=g_Botmater_ESPColor(1,.12,.16,1)
local CARD_OUTLINE=g_Botmater_ESPColor(0,0,0,.9)
local HP_COLORS={}
for i=0,32 do
    local p=i/32;local a,b,t
    if p<.5 then a,b,t=CARD_RED,CARD_AMBER,p*2
    elseif p<.75 then a,b,t=CARD_AMBER,CARD_CYAN,(p-.5)*4
    else a,b,t=CARD_CYAN,CARD_BLUE,(p-.75)*4 end
    HP_COLORS[i]=g_Botmater_ESPColor(a.R+(b.R-a.R)*t,a.G+(b.G-a.G)*t,a.B+(b.B-a.B)*t,1)
end
function V1Draw.Style(widget,size)
    -- A regular font avoids inheriting the compressed game counter typeface.
    if not V1Draw.FontTried then
        V1Draw.FontTried=true
        local fn=V1Info.Read(slua,"loadObject")
        if type(fn)=="function" then
            local ok,font=pcall(fn,"/Engine/EngineFonts/Roboto.Roboto")
            if ok and g_Botmater_ESPValid(font) then V1Draw.FontObject=font end
        end
    end
    pcall(function()
        local f=widget.Font
        if f then
            if type(f)=="table" then local copy={};for k,v in pairs(f) do copy[k]=v end;f=copy end
            f.Size=size
            if V1Draw.FontObject then f.FontObject=V1Draw.FontObject;f.TypefaceFontName="Regular" end
            local outline=f.OutlineSettings
            if outline then
                if type(outline)=="table" then local copy={};for k,v in pairs(outline) do copy[k]=v end;outline=copy end
                outline.OutlineSize=1;outline.OutlineColor=CARD_OUTLINE;f.OutlineSettings=outline
            end
            widget:SetFont(f)
        end
        if widget.SetFontSize then widget:SetFontSize(size) end
        widget:SetRenderTransformPivot(g_Botmater_ESPV2(0,0))
        widget:SetShadowOffset(g_Botmater_ESPV2(0,.5));widget:SetShadowColorAndOpacity(CARD_OUTLINE)
        widget:SetAutoWrapText(false)
    end)
    g_Botmater_ESPSetTextColor(widget,CARD_WHITE)
end
function V1Draw.TextScale(node,scale)
    -- Scale only text, after distance scaling; geometry and flag size stay unchanged.
    scale=scale*.90
    if node.TextScale and math.abs(node.TextScale-scale)<.01 then return end
    V1Draw.Apply(node,function() return node.Widget:SetRenderScale(g_Botmater_ESPV2(scale,scale)) end)
    node.TextScale=scale
end
function V1Draw.InfoSize(data,distance,height,now)
    -- Text has a readable floor independent of the actor's projected height.
    -- Near -> medium -> far changes by only 15%, never by multiple times.
    local target=1.05-.15*math.min(1,math.max(0,distance-15)/185)
    local previous=data.InfoScale
    if not previous or not data.ScaleAt or now<data.ScaleAt then previous=target end
    local dt=math.min(.1,math.max(0,now-(data.ScaleAt or now)))
    local scale=previous+(target-previous)*math.min(1,dt*12)
    data.InfoScale=scale;data.ScaleAt=now
    return math.floor(scale*32+.5)/32
end
function V1Draw.Apply(node,fn)
    local ok,result=pcall(fn)
    if not ok or result==false then node.Broken=true;error("V1_WIDGET_UPDATE_FAILED",0) end
end
function V1Draw.Show(node,on)
    if node.Visible==on then return end
    V1Draw.Apply(node,function() return node.Widget:SetWidgetVisibility(on and UEnums.ESlateVisibility.SelfHitTestInvisible or UEnums.ESlateVisibility.Collapsed) end)
    node.Visible=on
end
function V1Draw.Text(node,value)
    if node.Value==value then return end
    V1Draw.Apply(node,function() return node.Widget:SetText(value) end);node.Value=value
end
function V1Draw.Color(node,color)
    if node.Color==color then return end
    V1Draw.Apply(node,function() return node.Widget:SetBrushColor(color) end);node.Color=color
end
function V1Draw.Ink(node,color)
    if node.InkColor==color then return end
    local ok,result=pcall(function()
        local sc=node.Widget.ColorAndOpacity
        if type(sc)=="table" then local copy={};for k,v in pairs(sc) do copy[k]=v end;sc=copy end
        sc.SpecifiedColor=color;sc.ColorUseRule=0
        return node.Widget:SetColorAndOpacity(sc)
    end)
    if not ok or result==false then
        ok,result=pcall(function() return node.Widget:SetColorAndOpacity(color) end)
    end
    if ok and result~=false then node.InkColor=color end
end
function V1Draw.Place(node,x,y,w,h)
    local function set(field,method,a,b)
        local ok,result=pcall(function()
            local v
            if node.VectorReuseDisabled then v=g_Botmater_ESPV2(a,b)
            else v=node[field] or g_Botmater_ESPV2(a,b);node[field]=v;v.X=a;v.Y=b end
            return node.Slot[method](node.Slot,v)
        end)
        if (not ok or result==false) and not node.VectorReuseDisabled then
            node.VectorReuseDisabled=true;node.PosVec=nil;node.SizeVec=nil
            ok,result=pcall(function() return node.Slot[method](node.Slot,g_Botmater_ESPV2(a,b)) end)
        end
        if not ok or result==false then node.Broken=true;error("V1_LAYOUT_UPDATE_FAILED",0) end
    end
    if node.X==nil or math.abs(node.X-x)>.1 or math.abs(node.Y-y)>.1 then
        set("PosVec","SetPosition",x,y);node.X=x;node.Y=y
    end
    if w and (node.W==nil or math.abs(node.W-w)>.1 or math.abs(node.H-h)>.1) then
        set("SizeVec","SetSize",w,h);node.W=w;node.H=h
    end
end
function V1Draw.Healthy(data,now)
    if not data or data.Broken then return false end
    if not data.RootValidatedAt or now>=data.RootValidatedAt or now<data.RootValidatedAt-.35 then
        if not g_Botmater_ESPValid(data.Widget) or not g_Botmater_ESPValid(data.Slot) then return false end
        data.RootValidatedAt=now+.35
    end
    if not data.ValidateAt or now>=data.ValidateAt or now<data.ValidateAt-1 then
        for _,node in pairs(data.Nodes) do
            if node.Broken or not g_Botmater_ESPValid(node.Widget) or not g_Botmater_ESPValid(node.Slot) then return false end
        end
        data.ValidateAt=now+1
    end
    return true
end
function V1Draw.Create()
    if V1Cleanup.Count>=V1Cleanup.AdmissionLimit then return nil end
    local canvas=g_Botmater_ESPGetCanvas();if not canvas then return nil end
    local pooled=ESPWidgetPool.Take(ESPWidgetPool.V1,"CardV1",canvas)
    if pooled then return pooled end
    if g_Botmater_ShotESP.BuildBudget<16 or g_Botmater_ShotESP.CardBudget<1 then return nil,"budget" end
    g_Botmater_ShotESP.BuildBudget=g_Botmater_ShotESP.BuildBudget-16
    g_Botmater_ShotESP.CardBudget=g_Botmater_ShotESP.CardBudget-1
    local data={Nodes={}}
    local ok=pcall(function()
        local root=CGame:NewObjectFromPath("/Script/UMG.CanvasPanel",canvas)
        assert(g_Botmater_ESPValid(root));data.Widget=root
        data.Slot=canvas:AddChildToCanvas(root);data.Slot:SetAutoSize(false)
        data.Slot:SetAlignment(g_Botmater_ESPV2(0,0));data.Slot:SetZOrder(20)
        local function node(key,kind,size,z)
            local w=CGame:NewObjectFromPath("/Script/UMG."..kind,root);assert(g_Botmater_ESPValid(w))
            local slot=root:AddChildToCanvas(w);assert(slot)
            slot:SetAutoSize(false);slot:SetAlignment(g_Botmater_ESPV2(0,0));slot:SetZOrder(z)
            w:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
            data.Nodes[key]={Widget=w,Slot=slot,Kind=kind,Visible=false}
            if kind=="TextBlock" then
                V1Draw.Style(w,size)
            elseif kind=="Border" then w:SetRenderTransformPivot(g_Botmater_ESPV2(0,.5)) end
        end
        node("Text","TextBlock",18,5);node("HealthValue","TextBlock",12,5)
        node("DistanceText","TextBlock",16,5);node("WeaponText","TextBlock",15,5)
        node("CoverText","TextBlock",15,5);node("FlagText","TextBlock",15,5)
        pcall(function() data.Nodes.Text.Widget:SetJustification(1) end)
        for _,name in ipairs({"HealthBg","HealthFill","BoxTop","BoxBottom","BoxLeft","BoxRight","ArrowA","ArrowB","ArrowC"}) do
            node(name,"Border",0,name=="HealthFill" and 3 or 1)
        end
    end)
    if not ok then V1Cleanup.Retire(data.Widget);return nil end
    ESPWidgetPool.Tag(ESPWidgetPool.V1,"CardV1",canvas,data)
    return data
end
function V1Draw.Get(key,now)
    local state=g_Botmater_ShotESP;local data=state.Names[key]
    if not V1Draw.Healthy(data,now) then
        if data then data.Broken=true end
        if not g_Botmater_ESPDestroyWidgetData(data) then return nil end
        state.Names[key]=nil
        local due=state.BuildDue[key]
        if due and now<due and now>=due-.15 then return nil end
        local reason
        data,reason=V1Draw.Create();state.Names[key]=data
        state.BuildDue[key]=not data and reason~="budget" and now+.15 or nil
    end
    return data
end
local HP_MAX_FIELDS={"HealthMax","MaxHealth","MaxHP"}
local HP_MAX_METHODS={"GetHealthMax","GetMaxHealth"}
function V1Draw.Health(actor)
    local hp=V1Info.Read(actor,"Health")
    if not ESPShared.Finite(hp) then hp=V1Info.Read(actor,"HP") end
    if not ESPShared.Finite(hp) then hp=V1Info.Call(actor,"GetHealth") end
    local max
    for _,field in ipairs(HP_MAX_FIELDS) do
        local value=V1Info.Read(actor,field)
        if ESPShared.Finite(value) and value>0 then max=value;break end
    end
    if not max then
        for _,method in ipairs(HP_MAX_METHODS) do
            local value=V1Info.Call(actor,method)
            if ESPShared.Finite(value) and value>0 then max=value;break end
        end
    end
    if not max then max=100 end
    local knocked=ESPShared.GetFrameRecord(actor).LifeState=="knocked"
    if not ESPShared.Finite(hp) then return 0,"--" end
    local pct=math.max(0,math.min(1,hp/max))
    return pct,knocked and "KO" or (tostring(math.floor(pct*100+.5)).."%")
end
function V1Draw.Line(node,x1,y1,x2,y2,color,width)
    V1Draw.Color(node,color)
    V1Draw.Stroke(node,x1,y1,x2,y2,width or 1.6)
    if node.Broken then error("V1_LINE_UPDATE_FAILED",0) end
end
function V1Draw.LineHealthy(data,now)
    if not data or data.Broken then return false end
    if not data.ValidatedAt or now>=data.ValidatedAt or now<data.ValidatedAt-.35 then
        if not g_Botmater_ESPValid(data.Widget) or not g_Botmater_ESPValid(data.Slot) then return false end
        data.ValidatedAt=now+.35
    end
    return true
end
function V1Draw.Stroke(node,x1,y1,x2,y2,thickness)
    local dx,dy=x2-x1,y2-y1
    local length=math.sqrt(dx*dx+dy*dy)
    if length<1 then V1Draw.Show(node,false);return false end
    local angle=((math.atan2 and math.atan2(dy,dx)) or math.atan(dy,dx))*180/math.pi
    V1Draw.Place(node,x1,y1-thickness*.5,length,thickness)
    if not node.Angle or math.abs(node.Angle-angle)>.02 then
        V1Draw.Apply(node,function()return node.Widget:SetRenderAngle(angle)end);node.Angle=angle
    end
    V1Draw.Show(node,true)
    node.X1,node.Y1,node.X2,node.Y2,node.Thickness=x1,y1,x2,y2,thickness
    return true
end
function V1Draw.Card(item,pc,head,feet,now,opt)
    local needed=opt.Name or opt.Health or opt.Distance or opt.Box or opt.Weapon or opt.Flag or opt.Visibility
    if not needed then
        local old=g_Botmater_ShotESP.Names[item.Key]
        if old then V1Draw.Show(old,false) end
        return
    end
    local data=V1Draw.Get(item.Key,now);if not data then return end
    local n=data.Nodes;local anchor=head or feet;if not anchor then return end
    local info=V1Info.Get(item,pc,now,opt)
    local minX,minY,maxX,maxY=ESPShared.CanvasBounds(pc,g_Botmater_ShotESP)
    local top=math.min(head and head.Y or anchor.Y,feet and feet.Y or anchor.Y)
    local bottom=math.max(head and head.Y or anchor.Y,feet and feet.Y or anchor.Y)
    local height=math.max(2,math.min((maxY-minY)*1.5,bottom-top))
    local width=math.max(2,math.min(140,height*.46))
    local scale=V1Draw.InfoSize(data,item.Distance,height,now)
    local center=((head and head.X or anchor.X)+(feet and feet.X or anchor.X))*.5
    local headCenter=head and head.X or center
    local left=center-width*.5;local rootY=math.max(minY+2,top-35*scale)
    local boxY=top-rootY;local side=width+8*scale
    if left+side+170*scale>maxX-2 then side=-178*scale end
    local color=item.IsBot and CARD_WHITE or CARD_BLUE
    if data.Mode~="card" then
        for _,node in pairs(n) do V1Draw.Show(node,false) end
        data.Mode="card"
    end
    V1Draw.Place(data,left,rootY,width+180*scale,math.max(116*scale,height+35*scale));V1Draw.Show(data,true)
    local headerCenter=headCenter-left
    if opt.Name then
        V1Draw.TextScale(n.Text,scale)
        V1Draw.Text(n.Text,info.Name or (item.IsBot and "BOT" or "PLAYER"))
        local nameWidth=180*n.Text.TextScale
        local headerX=math.max(minX+2-left,math.min(headerCenter-nameWidth*.5,maxX-nameWidth-left-2))
        V1Draw.Place(n.Text,headerX,0,180,26)
    end
    V1Draw.Show(n.Text,opt.Name==true)
    if opt.Health then
        local pct,label=V1Draw.Health(item.Character)
        local barWidth=84*scale
        V1Draw.Color(n.HealthBg,CARD_TRACK);V1Draw.Place(n.HealthBg,headerCenter-barWidth*.5,27*scale,barWidth,4*scale)
        V1Draw.Color(n.HealthFill,HP_COLORS[math.floor(pct*32+.5)])
        V1Draw.Place(n.HealthFill,headerCenter-barWidth*pct*.5,27*scale,barWidth*pct,4*scale)
        V1Draw.TextScale(n.HealthValue,scale)
        V1Draw.Text(n.HealthValue,label);V1Draw.Place(n.HealthValue,headerCenter+46*scale,21*scale,45,18)
        V1Draw.Show(n.HealthBg,true);V1Draw.Show(n.HealthFill,pct>0);V1Draw.Show(n.HealthValue,true)
    else
        V1Draw.Show(n.HealthBg,false);V1Draw.Show(n.HealthFill,false);V1Draw.Show(n.HealthValue,false)
    end
    local box=opt.Box and head~=nil and feet~=nil
    if box then
        V1Draw.Line(n.BoxTop,0,boxY,width,boxY,color)
        V1Draw.Line(n.BoxBottom,0,boxY+height,width,boxY+height,color)
        V1Draw.Line(n.BoxLeft,0,boxY,0,boxY+height,color)
        V1Draw.Line(n.BoxRight,width,boxY,width,boxY+height,color)
    else for _,key in ipairs({"BoxTop","BoxBottom","BoxLeft","BoxRight"}) do V1Draw.Show(n[key],false) end end
    local count=(opt.Distance and 1 or 0)+(opt.Weapon and 1 or 0)+(opt.Visibility and 1 or 0)+(opt.Flag and 1 or 0)
    local rowHeight=22*scale
    local shoulder=boxY+height*.18
    local span=math.max(0,height*.82-rowHeight,(count-1)*rowHeight)
    local y=math.max(minY-rootY+2,math.min(shoulder,maxY-rootY-span-rowHeight-2))
    local step=count>1 and span/(count-1) or 0
    local function row(node,show,value,size)
        if show then
            V1Draw.TextScale(node,scale)
            V1Draw.Text(node,value);V1Draw.Place(node,side,y,170,22);V1Draw.Show(node,true);y=y+step
        else V1Draw.Show(node,false) end
    end
    row(n.DistanceText,opt.Distance,string.format("%dm",math.floor(item.Distance+.5)),16)
    row(n.WeaponText,opt.Weapon,info.Weapon or "Unknown",14)
    if opt.Visibility then V1Draw.Ink(n.CoverText,info.Cover=="Open" and CARD_RED or CARD_WHITE) end
    row(n.CoverText,opt.Visibility,info.Cover or "Unknown",13)
    -- Reserve the whole label slot before the image, including a visible gap.
    -- Center both widgets on the same row; the flag never inherits text scaling.
    if opt.Flag then
        V1Draw.TextScale(n.FlagText,scale)
        V1Draw.Text(n.FlagText,info.Country and ("Flag: "..info.Country) or "Flag:")
        local labelWidth=info.Country and 92 or 52
        local textScale=n.FlagText.TextScale
        local rowCenter=y+rowHeight*.5
        V1Draw.Place(n.FlagText,side,rowCenter-11*textScale,labelWidth,22)
        V1Draw.Show(n.FlagText,true)
        local flag,shown=V1Flags.Apply(data,info,now)
        if flag then
            V1Draw.Place(flag,side+labelWidth*textScale+5*scale,rowCenter-7.5*scale,22*scale,15*scale)
            V1Draw.Show(flag,shown==true)
        end
    else
        V1Draw.Show(n.FlagText,false)
        if n.FlagImage then V1Draw.Show(n.FlagImage,false) end
    end
    data.LineEndX=center;data.LineEndY=feet and feet.Y or anchor.Y
end
function V1Draw.Edge(item,pc)
    local record=ESPShared.GetFrameRecord(item.Character);if not record.Location then return nil end
    local state=g_Botmater_ShotESP
    if state.EdgeCamera==nil then
        state.EdgeCamera=false
        local camera=V1Info.Call(pc,"GetPlayerCameraManager") or V1Info.Read(pc,"PlayerCameraManager")
        local loc=V1Info.Call(camera,"GetCameraLocation") or V1Info.Call(pc,"GetCameraLocation")
            or ESPShared.GetFrameRecord(g_Botmater_ESPGetLocalCharacter()).Location
        local rot=V1Info.Call(camera,"GetCameraRotation") or V1Info.Call(pc,"GetControlRotation")
        local x,y,z=ESPShared.VectorValues(loc)
        local yaw=V1Info.Read(rot,"Yaw");local pitch=V1Info.Read(rot,"Pitch") or 0
        if x and ESPShared.Finite(yaw) and ESPShared.Finite(pitch) then
            state.EdgeCamera={X=x,Y=y,Z=z,Yaw=yaw*math.pi/180,Pitch=pitch*math.pi/180}
        end
    end
    local camera=state.EdgeCamera;if not camera then return nil end
    local dx,dy,dz=record.Location.X-camera.X,record.Location.Y-camera.Y,record.Location.Z-camera.Z
    local yaw,pitch=camera.Yaw,camera.Pitch
    local right=-math.sin(yaw)*dx+math.cos(yaw)*dy
    local forward=math.cos(pitch)*(math.cos(yaw)*dx+math.sin(yaw)*dy)+math.sin(pitch)*dz
    local minX,minY,maxX,maxY=ESPShared.CanvasBounds(pc,g_Botmater_ShotESP)
    local cx,cy=(minX+maxX)*.5,(minY+maxY)*.5
    local sx,sy=right,-forward
    if forward>0 and record.HasHead and record.RawHead then
        local tx,ty,ox,oy=ESPShared.CanvasTransform(g_Botmater_ShotESP)
        sx=record.RawHead.X*tx+ox-cx;sy=record.RawHead.Y*ty+oy-cy
    end
    local length=math.sqrt(sx*sx+sy*sy)
    if length<.001 then sx,sy,length=0,(forward<0 and 1 or -1),1 end
    sx,sy=sx/length,sy/length
    local hw=math.max(1,(maxX-minX)*.5-58);local hh=math.max(1,(maxY-minY)*.5-60)
    local t=math.min(math.abs(sx)>.00001 and hw/math.abs(sx) or math.huge,
        math.abs(sy)>.00001 and hh/math.abs(sy) or math.huge)
    return cx+sx*t,cy+sy*t,sx,sy
end
-- Numeric-only layout cache. Camera direction remains current on every render.
function V1Draw.AlertLayout(pc)
    local state=g_Botmater_ShotESP
    if state.EdgePlacements then return state.EdgePlacements end
    local records=state.AlertScratchRecords or {};state.AlertScratchRecords=records
    local pool=state.AlertScratchPool or {};state.AlertScratchPool=pool
    local recordCount=0
    local enemies=state.RenderEnemies or state.Enemies
    local count=math.min(#enemies,math.floor(ESPShared.SafeNumber(_G.g_Botmater_MasterShotESP.MaxRendered,20,1,64)))
    local minX,minY,maxX,maxY=ESPShared.CanvasBounds(pc,state)
    for i=1,count do
        local item=enemies[i]
        local _,_,onScreen,reason=ESPShared.Events.Project(pc,item.Character,state)
        if not onScreen and reason=="offscreen" then
            local x,y,dx,dy=V1Draw.Edge(item,pc)
            if x then
                local horizontal=math.min(math.abs(y-minY-60),math.abs(y-maxY+60))
                local vertical=math.min(math.abs(x-minX-58),math.abs(x-maxX+58))
                local side
                if horizontal<=vertical then side=y<(minY+maxY)*.5 and "top" or "bottom"
                else side=x<(minX+maxX)*.5 and "left" or "right" end
                recordCount=recordCount+1
                local e=pool[recordCount] or {};pool[recordCount]=e
                e.Key=item.Key;e.X=x;e.Y=y;e.DX=dx;e.DY=dy;e.Side=side
                records[recordCount]=e
            end
        end
    end
    for i=#records,recordCount+1,-1 do records[i]=nil end
    table.sort(records,function(a,b)return a.Key<b.Key end)
    local placements=state.AlertScratchPlacements or {};state.AlertScratchPlacements=placements
    for key in pairs(placements)do placements[key]=nil end
    state.EdgePlacements=placements
    if #records==1 then
        local e=records[1];placements[e.Key]=e;return placements
    end
    local previous=state.AlertLayoutCache
    local same=previous and previous.MinX==minX and previous.MinY==minY and previous.MaxX==maxX and previous.MaxY==maxY and #previous.Records==#records
    if same then
        for i,e in ipairs(records) do
            local p=previous.Records[i]
            if p.Key~=e.Key or p.Side~=e.Side or math.abs(p.AnchorX-e.X)>24 or math.abs(p.AnchorY-e.Y)>24 then same=false;break end
        end
    end
    if same then
        for i,e in ipairs(records) do
            local p=previous.Records[i]
            if p.X then e.X=p.X;e.Y=p.Y;placements[e.Key]=e end
        end
        return placements
    end
    -- Each cell covers the entire arrow and distance label. Along an edge,
    -- fill adjacent cells first, then a parallel inner row/column.
    local x0,x1=minX+70,maxX-70
    local y0,y1=minY+60,maxY-60
    if x1<x0 or y1<y0 then return placements end
    local cols=math.max(1,math.floor((x1-x0)/132)+1)
    local rows=math.max(1,math.floor((y1-y0)/60)+1)
    local stepX=cols>1 and (x1-x0)/(cols-1) or 0
    local stepY=rows>1 and (y1-y0)/(rows-1) or 0
    local used={};local cached={}
    for _,e in ipairs(records) do
        local best,bestScore,bx,by
        for row=0,rows-1 do
            for col=0,cols-1 do
                local seat=row*cols+col+1
                if not used[seat] then
                    local x=cols==1 and (x0+x1)*.5 or x0+col*stepX
                    local y=rows==1 and (y0+y1)*.5 or y0+row*stepY
                    local depth,lateral
                    if e.Side=="bottom" then depth,lateral=rows-1-row,math.abs(x-e.X)
                    elseif e.Side=="top" then depth,lateral=row,math.abs(x-e.X)
                    elseif e.Side=="right" then depth,lateral=cols-1-col,math.abs(y-e.Y)
                    else depth,lateral=col,math.abs(y-e.Y) end
                    local score=depth*1e6+lateral
                    if not bestScore or score<bestScore then best,bestScore,bx,by=seat,score,x,y end
                end
            end
        end
        local entry={Key=e.Key,Side=e.Side,AnchorX=e.X,AnchorY=e.Y,X=bx,Y=by}
        cached[#cached+1]=entry
        if best then used[best]=true;e.X=bx;e.Y=by;placements[e.Key]=e end
    end
    state.AlertLayoutCache={MinX=minX,MinY=minY,MaxX=maxX,MaxY=maxY,Records=cached}
    state.Diagnostics.AlertLayoutBuilds=(state.Diagnostics.AlertLayoutBuilds or 0)+1
    return placements
end

function V1Draw.Alert(item,pc,now)
    local placement=V1Draw.AlertLayout(pc)[item.Key];if not placement then return false end
    if not ESPShared.Events.Visible(item.Character,ESPShared.GetFrameRecord(item.Character)) then return false end
    local x,y,dx,dy=placement.X,placement.Y,placement.DX,placement.DY
    local data=V1Draw.Get(item.Key,now);if not data then return false end
    local n=data.Nodes
    if data.Mode~="alert" then for _,node in pairs(n) do V1Draw.Show(node,false) end;data.Mode="alert" end
    V1Draw.Place(data,x,y,110,40);V1Draw.Show(data,true)
    V1Draw.TextScale(n.DistanceText,.95)
    local color=item.IsBot and CARD_WHITE or CARD_BLUE
    local px,py=-dy,dx
    V1Draw.Line(n.ArrowA,dx*13,dy*13,-dx*5+px*7,-dy*5+py*7,color,2.5)
    V1Draw.Line(n.ArrowB,dx*13,dy*13,-dx*5-px*7,-dy*5-py*7,color,2.5)
    V1Draw.Line(n.ArrowC,-dx*5+px*7,-dy*5+py*7,-dx*5-px*7,-dy*5-py*7,color,2.5)
    V1Draw.Text(n.DistanceText,(item.IsBot and "BOT " or "REAL ")..math.floor(item.Distance+.5).."m")
    V1Draw.Place(n.DistanceText,-65,18,136,24);V1Draw.Show(n.DistanceText,true)
    return true
end
end


local function g_Botmater_ESPScanEnemies()
    local pc = g_Botmater_ESPGetController()
    local me = g_Botmater_ESPGetLocalCharacter()
    if not pc or not me then
        g_Botmater_ShotESP.Enemies = {}
        g_Botmater_ShotESP.RealCount = 0
        g_Botmater_ShotESP.BotCount = 0
        return nil
    end
    local myLoc = ESPShared.GetFrameRecord(me).Location
    if not myLoc then
        g_Botmater_ShotESP.Enemies = {}
        g_Botmater_ShotESP.RealCount = 0
        g_Botmater_ShotESP.BotCount = 0
        return pc
    end
    local myTeam = g_Botmater_ESPGetTeamID(me)

    local list = {}
    local realCount = 0
    local botCount = 0
    local pawns=ESPShared.GetFramePawns()
    if not pawns then return pc end
    if pawns then
        for _, character in pairs(pawns) do
            if character~=me and ESPShared.GetFrameRecord(character).Alive and ESPShared.Events.Counted(character) then
                local team = g_Botmater_ESPGetTeamID(character)
                if myTeam == nil or team == nil or tostring(team) ~= tostring(myTeam) then
                    local loc = ESPShared.GetFrameRecord(character).Location
                    local dist = ESPShared.DistanceMetersFrom(ESPShared.GetFrameRecord(character),myLoc)
                    if dist <= (tonumber(_G.g_Botmater_MasterShotESP.MaxRangeMeters) or 350.0) then
                        local isBot = g_Botmater_ESPIsBot(character)
                        local k = g_Botmater_ESPGetPlayerKey(character)
                        if k then
                            list[#list+1] = {Character=character, Key=k, IsBot=isBot, Distance=dist}
                            if isBot then botCount = botCount + 1 else realCount = realCount + 1 end
                        end
                    end
                end
            end
        end
    end
    local maxRendered = math.floor(ESPShared.SafeNumber(_G.g_Botmater_MasterShotESP.MaxRendered,20,1,64))
    if #list > maxRendered then
        for _,item in ipairs(list) do
            item.RenderRank=item.Distance-(g_Botmater_ShotESP.Active[item.Key] and 2 or 0)
        end
        table.sort(list,function(a,b)
            if a.RenderRank==b.RenderRank then return a.Key<b.Key end
            return a.RenderRank<b.RenderRank
        end)
    end
    g_Botmater_ShotESP.Enemies = list
    g_Botmater_ShotESP.RealCount = realCount
    g_Botmater_ShotESP.BotCount = botCount
    return pc
end

local function g_Botmater_ESPPrune(active,alive)
    alive=alive or active
    for _,registry in ipairs({g_Botmater_ShotESP.Lines,g_Botmater_ShotESP.Names}) do
        for key,data in pairs(registry) do
            if not active[key] and g_Botmater_ESPDestroyWidgetData(data) then registry[key]=nil end
        end
    end
    for key in pairs(g_Botmater_ShotESP._BotCache or {}) do if not alive[key] then g_Botmater_ShotESP._BotCache[key]=nil end end
    for key in pairs(g_Botmater_ShotESP.LastProjected) do if not alive[key] then g_Botmater_ShotESP.LastProjected[key]=nil end end
    for _,registry in ipairs({g_Botmater_ShotESP.Metadata,g_Botmater_ShotESP.BuildDue}) do
        for key in pairs(registry) do if not active[key] then registry[key]=nil end end
    end
end

ESPShared.Events.Clearers[#ESPShared.Events.Clearers+1]=function(actor)
    local state=g_Botmater_ShotESP
    ESPShared.Events.ClearIn(state,g_Botmater_ESPPrune,actor)
    if state.SightActor==actor then state.SightActor=nil;state.SightData=nil;state.SightAt=nil end
    -- These caches contain only coordinates/keys. Rebuild spacing on the next
    -- existing draw pass so a removed marker cannot reserve an alert position.
    state.EdgePlacements=nil;state.AlertLayoutCache=nil
end

local g_Botmater_EnemyCounter = {
    Container = nil,
    Slot = nil,
    PlayerBG = nil,
    BotBG = nil,
    PlayerText = nil,
    BotText = nil,
    Width = 218.4,
    Height = 33.6,
    OffsetY = 22.5, -- If V2 counter is visible, shift V1 down to avoid overlap.
    FontSize = 13,
    FontScale = 1.2, -- Exact 20% glyph growth; native font Size is an integer.
    _LastPlayers = -1,
    _LastBots = -1,
    _PosVec = nil,
    _LastPosX = nil,
    _LastPosY = nil,
    CanvasCenterX = 0.0,
    CanvasCenterY = 0.0,
}

local function g_Botmater_CounterTextColor(widget,color)
    g_masterahsanyt_ESPSetTextColor(widget,color)
end

local function g_Botmater_CounterCreate()
    if V1Cleanup.Count>=V1Cleanup.AdmissionLimit then return false end
    if g_Botmater_EnemyCounter.Container and slua.isValid(g_Botmater_EnemyCounter.Container) then
        return true
    end
    local canvas = g_Botmater_ESPGetCanvas()
    if not canvas or not g_Botmater_ESPValid(canvas) then return false end

    local W, H = g_Botmater_EnemyCounter.Width, g_Botmater_EnemyCounter.Height
    local halfW = W * 0.5

    local Container, PlayerBG, BotBG, PlayerText, BotText = nil, nil, nil, nil, nil
    pcall(function() Container = CGame:NewObjectFromPath("/Script/UMG.CanvasPanel", canvas) end)
    if not Container or not slua.isValid(Container) then return false end
    pcall(function() PlayerBG = CGame:NewObjectFromPath("/Script/UMG.Border", Container) end)
    pcall(function() BotBG = CGame:NewObjectFromPath("/Script/UMG.Border", Container) end)
    pcall(function() PlayerText = CGame:NewObjectFromPath("/Script/UMG.TextBlock", Container) end)
    pcall(function() BotText = CGame:NewObjectFromPath("/Script/UMG.TextBlock", Container) end)

    if not PlayerBG or not BotBG or not PlayerText or not BotText
        or not slua.isValid(PlayerBG) or not slua.isValid(BotBG)
        or not slua.isValid(PlayerText) or not slua.isValid(BotText) then
        V1Cleanup.Retire(Container)
        return false
    end

    pcall(function()
        PlayerBG:SetBrushColor(CACHE_COUNTER_PLAYER_BG)
        PlayerBG:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        BotBG:SetBrushColor(CACHE_COUNTER_BOT_BG)
        BotBG:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
    end)

    local pbgSlot, bbgSlot = nil, nil
    pcall(function() pbgSlot = Container:AddChildToCanvas(PlayerBG) end)
    pcall(function() bbgSlot = Container:AddChildToCanvas(BotBG) end)
    if not pbgSlot or not bbgSlot then
        V1Cleanup.Retire(Container)
        return false
    end

    pcall(function()
        pbgSlot:SetAutoSize(false)
        pbgSlot:SetPosition(g_Botmater_ESPV2(0, 0))
        pbgSlot:SetSize(g_Botmater_ESPV2(halfW, H))
        pbgSlot:SetZOrder(0)
        bbgSlot:SetAutoSize(false)
        bbgSlot:SetPosition(g_Botmater_ESPV2(halfW, 0))
        bbgSlot:SetSize(g_Botmater_ESPV2(halfW, H))
        bbgSlot:SetZOrder(0)
    end)

    pcall(function()
        PlayerText:SetText("REAL: 0")
        BotText:SetText("BOT: 0")
        g_masterahsanyt_ESPSetFont(PlayerText,g_Botmater_EnemyCounter.FontSize,0)
        g_masterahsanyt_ESPSetFont(BotText,g_Botmater_EnemyCounter.FontSize,0)
        local scale=g_Botmater_EnemyCounter.FontScale
        PlayerText:SetRenderTransformPivot(g_Botmater_ESPV2(0.5,0.5))
        BotText:SetRenderTransformPivot(g_Botmater_ESPV2(0.5,0.5))
        PlayerText:SetRenderScale(g_Botmater_ESPV2(scale,scale))
        BotText:SetRenderScale(g_Botmater_ESPV2(scale,scale))
        PlayerText:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        BotText:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
    end)

    g_Botmater_CounterTextColor(PlayerText, CACHE_COUNTER_PLAYER_TEXT)
    g_Botmater_CounterTextColor(BotText, CACHE_COUNTER_BOT_TEXT)

    local ptSlot, btSlot = nil, nil
    pcall(function() ptSlot = Container:AddChildToCanvas(PlayerText) end)
    pcall(function() btSlot = Container:AddChildToCanvas(BotText) end)
    if ptSlot then
        pcall(function()
            ptSlot:SetAutoSize(true)
            ptSlot:SetAlignment(g_Botmater_ESPV2(0.5, 0.5))
            ptSlot:SetPosition(g_Botmater_ESPV2(halfW * 0.5, H * 0.5))
            ptSlot:SetZOrder(2)
        end)
    end
    if btSlot then
        pcall(function()
            btSlot:SetAutoSize(true)
            btSlot:SetAlignment(g_Botmater_ESPV2(0.5, 0.5))
            btSlot:SetPosition(g_Botmater_ESPV2(halfW + halfW * 0.5, H * 0.5))
            btSlot:SetZOrder(2)
        end)
    end

    local mainSlot = nil
    pcall(function() mainSlot = canvas:AddChildToCanvas(Container) end)
    if not mainSlot then
        V1Cleanup.Retire(Container)
        return false
    end
    pcall(function()
        mainSlot:SetAutoSize(false)
        mainSlot:SetSize(g_Botmater_ESPV2(W, H))
        mainSlot:SetZOrder(50)
    end)

    g_Botmater_EnemyCounter.Container = Container
    g_Botmater_EnemyCounter.Slot = mainSlot
    g_Botmater_EnemyCounter.PlayerBG = PlayerBG
    g_Botmater_EnemyCounter.BotBG = BotBG
    g_Botmater_EnemyCounter.PlayerText = PlayerText
    g_Botmater_EnemyCounter.BotText = BotText
    g_Botmater_EnemyCounter._LastPlayers = -1
    g_Botmater_EnemyCounter._LastBots = -1
    g_Botmater_EnemyCounter._PosVec = nil
    g_Botmater_EnemyCounter._LastPosX = nil
    g_Botmater_EnemyCounter._LastPosY = nil

    pcall(function() Container:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
    return true
end

local function g_Botmater_CounterUpdatePosition(pc)
    local slot = g_Botmater_EnemyCounter.Slot
    if not slot or not slua.isValid(slot) then return end
    if not pc or not g_Botmater_ESPValid(pc) then return end

    local canvasW, canvasH = g_Botmater_ESPGetCanvasLocalSize()
    if not canvasW or not canvasH then
        local vw, vh = g_Botmater_ESPViewport(pc)
        if not vw or vw <= 200 then return end
        local sx = g_Botmater_ShotESP.CanvasScaleX or 1.0
        local sy = g_Botmater_ShotESP.CanvasScaleY or 1.0
        local ox = g_Botmater_ShotESP.CanvasOffsetX or 0.0
        local oy = g_Botmater_ShotESP.CanvasOffsetY or 0.0
        canvasW = (vw * sx) - ox
        canvasH = (vh * sy) - oy
    end

    if not canvasW or not canvasH then return end

    local canvasCenterX = canvasW * 0.5
    local canvasCenterY = g_Botmater_EnemyCounter.OffsetY
    if _G.g_masterahsanyt_ESPOptions.Counter then canvasCenterY=106 end

    local x = canvasCenterX - g_Botmater_EnemyCounter.Width * 0.5
    local y = canvasCenterY

    g_Botmater_EnemyCounter.CanvasCenterX = canvasCenterX
    g_Botmater_EnemyCounter.CanvasCenterY = canvasCenterY + g_Botmater_EnemyCounter.Height * 0.5

    local lx, ly = g_Botmater_EnemyCounter._LastPosX, g_Botmater_EnemyCounter._LastPosY
    if lx ~= nil and ly ~= nil and math.abs(lx - x) < 0.1 and math.abs(ly - y) < 0.1 then return end
    g_Botmater_EnemyCounter._PosVec = g_Botmater_ESPV2(x, y)
    local ok = pcall(function() slot:SetPosition(g_Botmater_EnemyCounter._PosVec) end)
    if ok then
        g_Botmater_EnemyCounter._LastPosX = x
        g_Botmater_EnemyCounter._LastPosY = y
    end
end

local function g_Botmater_GetLineOrigin(pc)
    local width,height=ESPShared.ViewSize(pc)
    local sx,sy,ox,oy=ESPShared.CanvasTransform(g_Botmater_ShotESP)
    return g_Botmater_ESPV2(width*.5*sx+ox,(height-4)*sy+oy)
end

local function g_Botmater_CounterSetCounts(realCount, botCount)
    realCount = tonumber(realCount) or 0
    botCount = tonumber(botCount) or 0
    if g_Botmater_EnemyCounter._LastPlayers ~= realCount
        and g_Botmater_EnemyCounter.PlayerText and slua.isValid(g_Botmater_EnemyCounter.PlayerText) then
        local ok, applied = pcall(function()
            return g_Botmater_EnemyCounter.PlayerText:SetText(string.format("REAL: %d", realCount)) ~= false
        end)
        if ok and applied then g_Botmater_EnemyCounter._LastPlayers = realCount end
    end
    if g_Botmater_EnemyCounter._LastBots ~= botCount
        and g_Botmater_EnemyCounter.BotText and slua.isValid(g_Botmater_EnemyCounter.BotText) then
        local ok, applied = pcall(function()
            return g_Botmater_EnemyCounter.BotText:SetText(string.format("BOT: %d", botCount)) ~= false
        end)
        if ok and applied then g_Botmater_EnemyCounter._LastBots = botCount end
    end
end

local function g_Botmater_CounterStart(pc)
    if not g_Botmater_CounterCreate() then return end
    pcall(function()
        g_Botmater_EnemyCounter.Container:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
    end)
    g_Botmater_CounterUpdatePosition(pc)
end

local function g_Botmater_CounterStop()
    local container = g_Botmater_EnemyCounter.Container
    g_Botmater_EnemyCounter.Container = nil
    g_Botmater_EnemyCounter.Slot = nil
    g_Botmater_EnemyCounter.PlayerBG = nil
    g_Botmater_EnemyCounter.BotBG = nil
    g_Botmater_EnemyCounter.PlayerText = nil
    g_Botmater_EnemyCounter.BotText = nil
    g_Botmater_EnemyCounter._LastPlayers = -1
    g_Botmater_EnemyCounter._LastBots = -1
    g_Botmater_EnemyCounter._PosVec = nil
    g_Botmater_EnemyCounter._LastPosX = nil
    g_Botmater_EnemyCounter._LastPosY = nil
    g_Botmater_EnemyCounter.CanvasCenterX = 0.0
    g_Botmater_EnemyCounter.CanvasCenterY = 0.0
    if g_Botmater_ESPValid(container) then
        V1Cleanup.Retire(container)
    end
end

-- Each actor update is isolated. Death cleanup runs before projection/drawing.
local function g_Botmater_ESPRenderActor(item,pc,opt,origin,now)
    local state=g_Botmater_ShotESP
    local c,key,isBot=item.Character,item.Key,item.IsBot
    local head,feet,onScreen,reason=ESPShared.Events.Project(pc,c,state)
    if not onScreen then
        local last=state.LastProjected[key]
        if reason=="unavailable" and last and now>=last and now-last<=.08 then
            state.Active[key]=true
        else
            state.LastProjected[key]=nil
            if opt.Alert and reason=="offscreen" then
                if V1Draw.Alert(item,pc,now) then
                    if ESPShared.Events.Visible(c,ESPShared.GetFrameRecord(c)) then
                        state.Active[key]=true;state.LastProjected[key]=now
                    else
                        ESPShared.Events.Clear(c)
                    end
                end
            end
            local line=state.Lines[key]
            if line then g_Botmater_ESPHide(line) end
        end
        return
    end
    local anchor=head or feet;if not anchor then return end
    state.Active[key]=true;state.LastProjected[key]=now
    V1Draw.Card(item,pc,head,feet,now,opt)
    local line=state.Lines[key]
    local color=g_Botmater_ESPGetColors(isBot)
    if opt.Line and not V1Draw.LineHealthy(line,now) then
        if not g_Botmater_ESPDestroyWidgetData(line) then return end
        if state.BuildBudget>0 then
            state.BuildBudget=state.BuildBudget-1;line=g_Botmater_ESPCreateLine(color)
        else line=nil end
        state.Lines[key]=line
    end
    if opt.Line and line then
        local colorKey=isBot and "BOT" or "REAL"
        if line.ColorKey~=colorKey then
            local ok,result=pcall(function() return line.Widget:SetBrushColor(color) end)
            if ok and result~=false then line.ColorKey=colorKey end
        end
        local endpoint=feet or anchor
        V1Draw.Stroke(line,origin.X,origin.Y,endpoint.X,endpoint.Y,
            ESPShared.SafeNumber(_G.g_Botmater_MasterShotESP.TracerThickness,2,.5,6))
    elseif line then g_Botmater_ESPHide(line) end
end
local function g_Botmater_ESPDrawCandidates(pc,opt,now)
    local state=g_Botmater_ShotESP;local origin=g_Botmater_GetLineOrigin(pc)
    local limit=math.floor(ESPShared.SafeNumber(_G.g_Botmater_MasterShotESP.MaxRendered,20,1,64))
    local selected,count=ESPShared.Events.SelectVisible(state.Enemies,limit,state.RenderCandidates)
    state.RenderCandidates=selected;state.RenderEnemies=selected
    state.BuildBudget=32;state.CardBudget=1;state.MetaBudget=2;state.SightBudget=1;state.FlagBudget=1
    state.EdgeCamera=nil;state.EdgePlacements=nil
    state.SightData=nil;state.SightActor=nil;state.SightAt=nil
    if count==0 then return end
    state.RenderCursor=((state.RenderCursor or 0)%count)+1
    for offset=0,count-1 do
        local index=(state.RenderCursor+offset-1)%count+1
        local item=selected[index]
        local ok,err=pcall(g_Botmater_ESPRenderActor,item,pc,opt,origin,now)
        if not ok then
            state.Active[item.Key]=nil;state.LastProjected[item.Key]=nil
            if state.Names[item.Key] then state.Names[item.Key].Broken=true end
            local f=_G.LunarFeatures;if f and f.Error then f.Error("V1.Actor",err) end
        end
    end
    V1Info.FlushSight(pc,now)
    state.EdgePlacements=nil
end


local function g_Botmater_ESPUpdate()
    local state=g_Botmater_ShotESP
    local opt=_G.g_Botmater_ESPOptions
    local details=opt and (opt.Name or opt.Line or opt.Box or opt.Health or opt.Distance or opt.Weapon or opt.Flag or opt.Visibility or opt.Alert)
    local counter=opt and opt.EnemyCounter
    local now=g_Botmater_ESPNow()
    V1Cleanup.Pump(now)
    if not _G.g_Botmater_MasterShotESP.Enabled or (not details and not counter) then
        g_Botmater_ESPResetWidgets();g_Botmater_CounterStop();return
    end
    local world=g_Botmater_ESPWorld()
    ESPShared.Events.WorldChanged(world)
    if world~=state.LastWorld then
        g_Botmater_ESPResetWidgets();g_Botmater_CounterStop();state.LastWorld=world
    end
    local oldCanvas=state.Canvas
    local canvas=g_Botmater_ESPGetCanvas()
    if canvas~=oldCanvas then g_Botmater_CounterStop() end
    if not canvas then return end
    local pc=g_Botmater_ESPGetController()
    if now<state.LastScanClock or now-state.LastScanClock>=(tonumber(_G.g_Botmater_MasterShotESP.ScanInterval) or 0.05) then
        pc=g_Botmater_ESPScanEnemies() or pc;state.LastScanClock=now
    end
    pc=pc or g_Botmater_ESPGetController()
    if not pc then g_Botmater_ESPResetWidgets();g_Botmater_CounterStop();return end
    local location=ESPShared.GetFrameRecord(g_Botmater_ESPGetLocalCharacter()).Location
    local active,alive=state.Active,state.Alive
    state.RealCount,state.BotCount=g_masterahsanyt_ESPFilterEnemies(state.Enemies,location,
        _G.g_Botmater_MasterShotESP.MaxRangeMeters,alive)
    -- Prune confirmed excluded actors BEFORE any fallible drawing operation.
    g_Botmater_ESPPrune(alive,alive)
    for k in pairs(active) do active[k]=nil end
    if now<state.LastTransformClock or now-state.LastTransformClock>=(tonumber(_G.g_Botmater_MasterShotESP.TransformInterval) or 0.033) then
        g_Botmater_ESPUpdateCanvasTransform(pc);state.LastTransformClock=now
    end
    if counter then
        pcall(g_Botmater_CounterStart,pc)
        pcall(g_Botmater_CounterSetCounts,state.RealCount,state.BotCount)
    else g_Botmater_CounterStop() end
    local ok,err=true,nil
    if details then ok,err=pcall(g_Botmater_ESPDrawCandidates,pc,opt,now) end
    state.RenderEnemies=nil
    ESPShared.Events.ReleaseSelected(state.RenderCandidates)
    -- This path also executes after an origin/projection/vector error.
    g_Botmater_ESPPrune(active,alive)
    if not ok then
        local f=_G.LunarFeatures
        if f and f.Error then f.Error("V1.Draw",err) end
    end
end

local F=_G.LunarFeatures
F.V1={State=g_Botmater_ShotESP,Counter=g_Botmater_EnemyCounter,Tick=g_Botmater_ESPUpdate,
    Cleanup=V1Cleanup,Info=V1Info,Draw=V1Draw,Flags=V1Flags,
    Reset=function() g_Botmater_ESPResetWidgets();g_Botmater_CounterStop() end,
    Refresh=function() g_Botmater_ShotESP.LastScanClock=-999;g_Botmater_ShotESP.LastTransformClock=-999;g_Botmater_ShotESP.Metadata={} end}
end

-- Controls live entirely in the native game settings page.

-- Additional aim modes share the managed scheduler. No timer is created here.
do
    local F=_G.LunarFeatures
    local MathLib,Layout,HealthStates,PawnStates
    pcall(function() MathLib=import("KismetMathLibrary") end)
    pcall(function() Layout=import("WidgetLayoutLibrary") end)
    pcall(function() HealthStates=import("ECharacterHealthStatus") end)
    pcall(function() PawnStates=import("EPawnState") end)
    local function finite(v) return type(v)=="number" and v==v and v>-math.huge and v<math.huge end
    local function get(obj,key)
        if not obj then return nil end
        local ok,v=pcall(function() return obj[key] end)
        if ok then return v end
    end
    local function call(obj,key,...)
        local method=get(obj,key)
        if type(method)~="function" then return nil end
        local ok,v=pcall(method,obj,...)
        if ok then return v end
    end
    local function valid(obj) return obj and g_masterahsanyt_ESPValid(obj) end
    local function pos(v)
        if v and finite(v.X) and finite(v.Y) and finite(v.Z) then return {X=v.X,Y=v.Y,Z=v.Z} end
    end
    local function nativeVector(v) return g_masterahsanyt_ESPV3(v.X,v.Y,v.Z) end
    local function team(actor)
        local id=call(actor,"GetTeamID") or get(actor,"TeamID")
        if id==nil then
            local state=call(actor,"GetPlayerStateSafety")
            id=call(state,"GetTeamID") or get(state,"TeamID")
        end
        return id
    end
    local function dead(actor)
        if not valid(actor) then return true end
        local hp=call(actor,"GetHealth") or get(actor,"Health") or get(actor,"HP")
        if finite(hp) and hp<=0 then return true end
        if get(actor,"bIsDead")==true or get(actor,"bDead")==true or get(actor,"bIsDeadFlag")==true then return true end
        if HealthStates and HealthStates.FinishedLastBreath~=nil and get(actor,"HealthStatus")==HealthStates.FinishedLastBreath then return true end
        if PawnStates and PawnStates.Dead~=nil and call(actor,"HasPawnState",PawnStates.Dead)==true then return true end
        return false
    end
    local function weapon(player)
        local w=call(player,"GetCurrentWeapon") or get(player,"CurrentWeapon")
        if not valid(w) then
            local wm=get(player,"WeaponManagerComponent")
            w=get(wm,"CurrentWeaponReplicated") or get(wm,"CurrentWeapon")
        end
        return valid(w) and w or nil
    end
    local function kind(w)
        local name=call(w,"GetWeaponName")
        if type(name)~="string" or not name:find("%S") then return "unknown" end
        name=name:lower()
        if name:find("mortar",1,true) or name:find("cối",1,true) or name:find("cỐi",1,true) then return "mortar" end
        return "other"
    end
    local function context()
        local pc=g_masterahsanyt_ESPGetController()
        local player=g_masterahsanyt_ESPGetLocalCharacter()
        if valid(pc) and not dead(player) then return g_masterahsanyt_ESPWorld(),pc,player,weapon(player) end
    end
    local function pelvis(actor)
        local p=pos(call(actor,"GetBonePos","pelvis",{X=0,Y=0,Z=0}))
        if not p or (p.X==0 and p.Y==0 and p.Z==0) then p=pos(call(actor,"GetSocketLocation","pelvis")) end
        if not p or (p.X==0 and p.Y==0 and p.Z==0) then p=pos(call(actor,"K2_GetActorLocation")) end
        return p
    end
    local function allPlayers()
        local list
        pcall(function() if GameplayData.GetAllPlayerCharacters then list=GameplayData.GetAllPlayerCharacters() end end)
        return type(list)=="table" and list or {}
    end
    local function viewport(pc)
        local w,h=g_masterahsanyt_ESPViewport(pc)
        if not finite(w) or w<=0 or not finite(h) or h<=0 then return 1920,1080 end
        return w,h
    end
    local function project(pc,p)
        local screen=FVector2D(0,0)
        local ok,yes=pcall(function() return pc:ProjectWorldLocationToScreen(nativeVector(p),screen,false) end)
        if ok and (yes==true or yes==1) and finite(screen.X) and finite(screen.Y) then return screen.X,screen.Y end
    end
    local function camera(pc,player,fallback)
        local cm=call(pc,"GetPlayerCameraManager")
        if not valid(cm) then pcall(function() cm=GameplayStaticsESP.GetPlayerCameraManager(pc,0) end) end
        return pos(call(cm,"GetCameraLocation")) or fallback or pos(call(player,"K2_GetActorLocation"))
    end
    local function rotation(pc,target,source)
        if not target or not finite(target.Pitch) or not finite(target.Yaw) or not finite(target.Roll) then return false end
        local current=call(pc,"GetControlRotation")
        if current and finite(current.Pitch) and finite(current.Yaw) and finite(current.Roll or 0)
            and math.abs((target.Pitch-current.Pitch+180)%360-180)<0.00001
            and math.abs((target.Yaw-current.Yaw+180)%360-180)<0.00001
            and math.abs(target.Roll-(current.Roll or 0))<0.00001 then return true end
        local ok,accepted=pcall(function() return pc:SetControlRotation(target,source) end)
        if not ok then F.Error(source,accepted) end
        return ok and accepted~=false
    end
    -- A failed restore survives a script reload and remains eligible for retry.
    local pending=_G.__LunarAim2RestorePending or {}
    _G.__LunarAim2RestorePending=pending
    local A={Target=nil,Enabled=false,Due=0,LastTime=nil,Records=pending,RestoreErrors={}}
    F.Aim2=A
    local fields={"RecoilKickADS","GameDeviationFactor","GameDeviationAccuracy"}
    local function restore()
        for obj,record in pairs(A.Records) do
            if not valid(obj) then A.Records[obj]=nil;A.RestoreErrors[obj]=nil
            else
                for key,value in pairs(record) do
                    local ok,err=true,nil
                    if get(obj,key)~=value then ok,err=pcall(function() obj[key]=value end) end
                    if ok and get(obj,key)==value then record[key]=nil
                    elseif not A.RestoreErrors[obj] or not A.RestoreErrors[obj][key] then
                        A.RestoreErrors[obj]=A.RestoreErrors[obj] or {};A.RestoreErrors[obj][key]=true
                        F.Error("Aim2.Restore."..key,err or "native field did not accept restoration")
                    end
                end
                if next(record)==nil then A.Records[obj]=nil;A.RestoreErrors[obj]=nil end
            end
        end
    end
    function A.Stop()
        restore();A.Target=nil;A.Enabled=false;A.LastTime=nil;A.World=nil;A.PC=nil;A.Player=nil;A.Weapon=nil;A.Entity=nil;A.Due=0;A.Unsupported=nil;A.ApplyFailed=nil
    end
    function A.NextInterval(now)
        if not F.Settings.Aim2Enabled then return 0.5 end
        return math.max(0.001,A.Due-(finite(now) and now or F.Now()))
    end
    local function hard(entity)
        if not valid(entity) then return end
        local record=A.Records[entity]
        if not record then record={};A.Records[entity]=record end
        for _,key in ipairs(fields) do
            local current=get(entity,key)
            if finite(current) then
                if record[key]==nil then record[key]=current end
                if current~=0.01 then
                    local ok,err=pcall(function() entity[key]=0.01 end)
                    if not ok and (not A.ApplyFailed or not A.ApplyFailed[key]) then
                        A.ApplyFailed=A.ApplyFailed or {};A.ApplyFailed[key]=true;F.Error("Aim2.Apply."..key,err)
                    end
                end
            elseif not A.Unsupported or not A.Unsupported[key] then
                A.Unsupported=A.Unsupported or {};A.Unsupported[key]=true
                F.Error("Aim2.Unsupported",key.." is unreadable; left unchanged")
            end
        end
    end
    function A.Tick(now)
        now=finite(now) and now or F.Now()
        if not F.Settings.Aim2Enabled then if A.Player or next(A.Records) then A.Stop() end;return false end
        local world,pc,player,w=context()
        if not world or not w or kind(w)=="mortar" then A.Stop();A.Due=now+0.5;return false end
        local entity=get(w,"ShootWeaponEntityComp")
        if A.World~=world or A.PC~=pc or A.Player~=player or A.Weapon~=w or A.Entity~=entity then
            A.Stop();A.World=world;A.PC=pc;A.Player=player;A.Weapon=w;A.Entity=entity
        end
        if now<A.Due-0.000001 and (not A.LastTime or now>=A.LastTime) then return false end
        local dt=A.LastTime and now-A.LastTime or 0.5
        if not finite(dt) or dt<=0 then dt=0.5 end
        A.LastTime=now;A.Due=now+0.5;hard(entity)
        if get(player,"bIsWeaponAiming")~=true then A.Target=nil;A.Enabled=false;A.Due=now+0.2;return false end
        if not MathLib or not MathLib.FindLookAtRotation then return false end
        local myTeam=team(player)
        if myTeam==nil then return false end
        local width,height=viewport(pc)
        local scale=1
        pcall(function() if Layout and Layout.GetViewportScale then local s=Layout.GetViewportScale(pc);if finite(s) and s>0 then scale=s end end end)
        local rx,ry=F.AimRadiusUI()*scale,F.AimRadiusUI()*scale
        local rangeSquared=(F.Settings.AimCircle*100)^2
        local origin=pos(call(player,"K2_GetActorLocation"))
        local best,bestScore=nil,math.huge
        for _,enemy in pairs(allPlayers()) do
            if enemy~=player and not dead(enemy) then
                local enemyTeam=team(enemy)
                if enemyTeam~=nil and tostring(enemyTeam)~=tostring(myTeam) then
                    local p=pelvis(enemy)
                    if p and origin and ((p.X-origin.X)^2+(p.Y-origin.Y)^2+(p.Z-origin.Z)^2)<=rangeSquared then
                        local x,y=project(pc,p)
                        if x and x>=0 and y>=0 and x<=width and y<=height then
                            local dx,dy=(x-width/2)/rx,(y-height/2)/ry
                            local score=dx*dx+dy*dy
                            if finite(score) and score<=1 and score<bestScore then best,bestScore=enemy,score end
                        end
                    end
                end
            end
        end
        A.Target=best;A.Enabled=best~=nil
        if not best then return false end
        local loc,p=camera(pc,player),pelvis(best)
        if not loc or not p then return false end
        local desired=MathLib.FindLookAtRotation(nativeVector(loc),nativeVector(p))
        local current=call(pc,"GetControlRotation")
        if not desired or not current or not finite(desired.Pitch) or not finite(desired.Yaw) or not finite(current.Pitch) or not finite(current.Yaw) then return false end
        local dp,dy=(desired.Pitch-current.Pitch+180)%360-180,(desired.Yaw-current.Yaw+180)%360-180
        local dist=math.sqrt(dp*dp+dy*dy)
        -- Preserve the original tick cadence. A rate cap alone snaps small
        -- angles at every speed, so apply a speed-dependent response first.
        local speed=F.Settings.AimSpeed
        local elapsed=math.min(dt,0.5)
        local normalized=(speed-120)/30
        local response=0.25+0.4*normalized
        local fraction=1-(1-response)^(elapsed/0.5)
        local step=speed*elapsed
        if dist>0 then fraction=math.min(fraction,step/dist) end
        local final={Pitch=current.Pitch+dp*fraction,Yaw=current.Yaw+dy*fraction,Roll=current.Roll or 0}
        local w2,pc2,p2,wCurrent=context()
        if not F.Settings.Aim2Enabled or world~=w2 or pc~=pc2 or player~=p2 or w~=wCurrent or get(player,"bIsWeaponAiming")~=true or dead(best) then A.Stop();return false end
        return rotation(pc,final,"CircleAim")
    end
    local M={Target=nil,Candidates={},ScanDue=0,Due=0,LastTime=nil,Status="inactive",ActivePlaced=false}
    F.Mortar=M
    function M.Stop()
        M.Target=nil;M.Candidates={};M.ScanDue=0;M.Due=0;M.LastTime=nil;M.World=nil;M.PC=nil;M.Player=nil;M.Weapon=nil;M.ActivePlaced=false;M.Status="inactive"
    end
    local function distance(player,target)
        local d=call(player,"GetDistanceTo",target)
        if finite(d) and d>=0 then return d end
        local a,b=pos(call(player,"K2_GetActorLocation")),pos(call(target,"K2_GetActorLocation"))
        if a and b then local dx,dy,dz=a.X-b.X,a.Y-b.Y,a.Z-b.Z;d=math.sqrt(dx*dx+dy*dy+dz*dz);if finite(d) then return d end end
    end
    local function enemy(player,target)
        if target==player or dead(target) then return false end
        local mine,theirs=team(player),team(target)
        if mine~=nil and theirs~=nil and tostring(mine)==tostring(theirs) then return false end
        local d=distance(player,target)
        return finite(d) and d<=200000
    end
    local function trajectory(launch,V,G,target)
        if not pos(launch) or not pos(target) or not finite(V) or V<=0 or not finite(G) or G<=0 then return false,45,0,0 end
        local dx=math.max(500,math.sqrt((target.X-launch.X)^2+(target.Y-launch.Y)^2)-80)
        local dy=target.Z-launch.Z
        local minVSq=G*(dy+math.sqrt(dx*dx+dy*dy))
        if not finite(dx) or not finite(minVSq) then return false,45,0,0 end
        if V*V<minVSq then V=math.sqrt(math.max(0,minVSq))+100 end
        local v2=V*V
        local root=v2*v2-G*(G*dx*dx+2*dy*v2)
        if not finite(root) or root<0 then return false,45,0,dx end
        local rad=math.atan((v2+math.sqrt(root))/(G*dx))
        local deg,tof=math.deg(rad),dx/(V*math.cos(rad))
        if finite(deg) and finite(tof) and tof>0 and deg>=35 and deg<=89.5 then return true,deg,tof,dx end
        return false,45,0,dx
    end
    local function solve(launch,target)
        local okN,aN,tN,dN=trajectory(launch,9070,2744,target)
        local okF,aF,tF,dF=trajectory(launch,12520,3920,target)
        local okU,aU,tU,dU=trajectory(launch,16800,4410,target)
        if okN and dN<=25000 then return true,aN,tN,dN end
        if okF and dF<=40000 then return true,aF,tF,dF end
        if okU then return true,aU,tU,dU end
        if okN then return true,aN,tN,dN end
        return false,45,0,dN
    end
    M.SolveTrajectory=solve
    local function predict(target,base,launch)
        local velocity=call(target,"GetVelocity")
        if not velocity or not finite(velocity.X) or not finite(velocity.Y) or math.abs(velocity.X)+math.abs(velocity.Y)<0.01 then return base end
        local predicted={X=base.X,Y=base.Y,Z=base.Z}
        local fallback
        for _=1,2 do
            local ok,a,tof,d=solve(launch,predicted)
            if not ok then break end
            fallback={ok,a,tof,d}
            if tof<=0 or tof>15 then break end
            predicted.X=base.X+velocity.X*tof;predicted.Y=base.Y+velocity.Y*tof
            if not pos(predicted) then return base end
        end
        return predicted,fallback
    end
    function M.NextInterval(now)
        if not F.Settings.MortarEnabled then return 0.5 end
        return math.max(0.001,M.Due-(finite(now) and now or F.Now()))
    end
    function M.Tick(now)
        now=finite(now) and now or F.Now()
        if not F.Settings.MortarEnabled then if M.Player then M.Stop() end;return false end
        local world,pc,player,w=context()
        if not world or not w or kind(w)~="mortar" or get(w,"MortarState")~=2 then
            M.Stop();M.Status="not_placed_mortar";M.Due=now+0.5;return false
        end
        if M.World~=world or M.PC~=pc or M.Player~=player or M.Weapon~=w then
            M.Stop();M.World=world;M.PC=pc;M.Player=player;M.Weapon=w
        end
        if now<M.Due-0.000001 and (not M.LastTime or now>=M.LastTime) then return false end
        M.LastTime=now;M.Due=now+0.5;M.ActivePlaced=true;M.Status="targeting"
        if not enemy(player,M.Target) then
            M.Target=nil
            if now>=M.ScanDue then M.Candidates=allPlayers();M.ScanDue=now+0.25 end
            local width,height=viewport(pc)
            local best,score=nil,math.huge
            for _,target in pairs(M.Candidates) do
                if enemy(player,target) then
                    local p=pelvis(target)
                    if p then local x,y=project(pc,p)
                        if x and x>0 and y>0 then
                            local dx,dy=x-width/2,y-height/2
                            local d=dx*dx+dy*dy
                            if finite(d) and d<score and d<=(3.6*width/2)^2 then best,score=target,d end
                        end
                    end
                end
            end
            M.Target=best
        end
        local target=M.Target
        if not target then M.Status="no_target";return false end
        local base,launch=pelvis(target),pos(call(player,"K2_GetActorLocation"))
        if not base or not launch then M.Status="position_unavailable";return false end
        launch.Z=launch.Z+50
        local predicted,fallback=predict(target,base,launch)
        local ok,angle,tof=solve(launch,predicted)
        if not ok and fallback then ok,angle,tof=fallback[1],fallback[2],fallback[3] end
        if not ok or not finite(tof) or not finite(angle) then M.Status="unreachable";return false end
        if not MathLib or not MathLib.FindLookAtRotation then M.Status="math_unavailable";return false end
        local desired=MathLib.FindLookAtRotation(nativeVector(camera(pc,player,launch)),nativeVector(predicted))
        local current=call(pc,"GetControlRotation")
        if not desired or not current or not finite(desired.Yaw) or not finite(current.Pitch) or not finite(current.Yaw) then return false end
        local pitch=((angle-45)/43)*90-60
        local dp,dy=(pitch-current.Pitch+180)%360-180,(desired.Yaw-current.Yaw+180)%360-180
        local final={Pitch=current.Pitch+dp,Yaw=current.Yaw+dy,Roll=0}
        local world2,pc2,player2,w2=context()
        if not F.Settings.MortarEnabled or world2~=world or pc2~=pc or player2~=player or w2~=w or get(w,"MortarState")~=2 or not enemy(player,target) then M.Stop();return false end
        local accepted=rotation(pc,final,"MortarAim")
        M.Status=accepted and "rotation_call_accepted" or "rotation_failed"
        return accepted
    end
end

-- Live apply only our two range rows; other native sliders pass through.
do
    local F=_G.LunarFeatures
    function F.InstallNativeLiveSlider(class)
        if type(class)~="table" then return false end
        local original=class.OnSliderValueChanged
        if type(original)~="function" then return false end
        local current=class.__LunarLiveRange
        if current and current.Version==3 and current.Wrapper==original then return true end
        local record={Version=3,Original=original}
        local function capture(...)return {n=select('#',...),...}end
        local unpackValues=table.unpack or unpack
        record.Wrapper=function(self,...)
            local data=self and self.Data
            local key=data and data.Key
            if key~="LunarAimSpeed" and key~="LunarAimCircle" then return record.Original(self,...) end
            local runtime=_G.LunarFeatures
            if not runtime or runtime.Token.Stopped then return record.Original(self,...) end
            local max=key=="LunarAimSpeed" and 150 or 240
            if self.Min~=120 or self.Max~=max then
                pcall(function()self.UIRoot.Slider:SetStepSize(1/(max-120))end)
            end
            self.Min=120;self.Max=max
            local results=capture(record.Original(self,...))
            local v=tonumber(self.CurrentValue)
            if v and v==v and v>=120 and v<=max then
                local setter=key=="LunarAimSpeed" and runtime.SetAimSpeed or runtime.SetAimCircle
                local ok,why=pcall(setter,v)
                if ok then self.LastAppliedValue=v else runtime.Error("Settings.LiveRange",why) end
            end
            return unpackValues(results,1,results.n)
        end
        class.OnSliderValueChanged=record.Wrapper;class.__LunarLiveRange=record
        return true
    end
end

-- All features share the existing ESP render runner. No new repeating timer.
do
    local F=_G.LunarFeatures
    local function checked(fn,area,...)
        local ok,err=pcall(fn,...)
        if not ok then F.Error(area,err) end
    end
    F.V1Due=0;F.AimDue=0;F.IpadDue=0;F.SaveDue=0
    F.Pump=function(now)
        F.TimerClock=g_masterahsanyt_ShotESP.TimerClock
        now=now or F.Now()
        if F.V1 and F.V1.Cleanup then F.V1.Cleanup.Pump(now) end
        local welcome=_G.LunarStandaloneWelcome
        if F.Dirty and now>=F.SaveDue then checked(F.Save,"Settings.Save");F.SaveDue=now+0.5 end
        local world=g_masterahsanyt_ESPWorld()
        local pc=g_masterahsanyt_ESPGetController()
        local pawn=g_masterahsanyt_ESPGetLocalCharacter()
        if world~=F.LastWorld or pc~=F.LastPC or pawn~=F.LastPawn then
            if welcome then welcome.ContextChanged(world,pc,pawn,now) end
            if F.LastWorld~=nil and welcome and welcome.WelcomeUI then welcome.DestroyUI() end
            if _G.LunarAimCircleHUD then _G.LunarAimCircleHUD.Destroy() end
            if _G.LunarAimCircleHUD then _G.LunarAimCircleHUD.Due=now end
            checked(F.V1.Reset,"V1.Reset")
            checked(F.Wall.Stop,"Wall.Reset")
            checked(F.Aim2.Stop,"Aim2.Reset")
            checked(F.Mortar.Stop,"Mortar.Reset")
            F.Wall.ConsoleWorld=nil
            _G.AimTouchVisCache={}
            _G.XthrlenState.offPitch=0;_G.XthrlenState.offYaw=0
            F.AimLastClock=nil
            F.V1Due=0;F.AimDue=0;F.IpadDue=0
            F.LastWorld,F.LastPC,F.LastPawn=world,pc,pawn
        end
        if F.V1.State.Canvas and not g_masterahsanyt_ESPValid(F.V1.State.Canvas) then checked(F.V1.Reset,"V1.CanvasReset");F.V1Due=0 end
        if welcome and welcome.NeedsUpdate then checked(welcome.Update,"Welcome.Update",now,world,pc,pawn) end
        if not pc or not pawn then
            if F.Aim2.Player or next(F.Aim2.Records) then checked(F.Aim2.Stop,"Aim2.NoPlayer") end
            if F.Mortar.Player then checked(F.Mortar.Stop,"Mortar.NoPlayer") end
            if not F.V1Disabled then checked(F.V1.Reset,"V1.NoPlayer") end
            F.V1Disabled=true
            return
        end
        local circle=_G.LunarAimCircleHUD
        if circle and circle.Due and (now>=circle.Due or now<(circle.LastClock or now)) then
            checked(circle.Update,"AimCircle.Update",now)
        end
        local o=_G.g_Botmater_ESPOptions
        local detail=o.Name or o.Line or o.Box or o.Health or o.Distance or o.Weapon or o.Flag or o.Visibility or o.Alert
        local active=detail or o.EnemyCounter
        if not active then
            if not F.V1Disabled then checked(F.V1.Reset,"V1.Disable") end
            F.V1Disabled=true
        elseif now>=F.V1Due-0.000001 or (F.V1LastClock and now<F.V1LastClock) then
            F.V1Disabled=false
            checked(F.V1.Tick,"V1.Render")
            F.V1LastClock=now
            local interval=detail and (tonumber(_G.g_Botmater_MasterShotESP.UpdateInterval) or 1/60) or 0.05
            if interval~=interval or interval<=0 or math.abs(interval)==math.huge then interval=1/60 end
            F.V1Due=now+math.max(.001,interval)
            -- Equal render cadences share the V2 deadline, so adding V1 does
            -- not introduce a second phase of native render callbacks.
            local v2=_G.g_masterahsanyt_ESPOptions
            local detailedV2=_G.g_masterahsanyt_MasterShotESP.Enabled and (v2.Name or v2.Line or v2.Box or v2.Health or v2.Distance or v2.Skeleton)
            local shared=g_masterahsanyt_ESPRunnerToken.RenderDue
            if detail and detailedV2 and shared and shared>now and math.abs(interval-(tonumber(_G.g_masterahsanyt_MasterShotESP.UpdateInterval) or 1/60))<.000001 then F.V1Due=shared end
        end
        if F.Settings.Aim2Enabled and (now>=F.Aim2.Due-0.000001 or (F.Aim2.LastTime and now<F.Aim2.LastTime)) then
            checked(F.Aim2.Tick,"Aim2.Tick")
        elseif not F.Settings.Aim2Enabled and next(F.Aim2.Records) and now>=(F.Aim2RestoreDue or 0) then
            checked(F.Aim2.Stop,"Aim2.Restore")
            F.Aim2RestoreDue=now+0.5
        end
        if F.Settings.MortarEnabled and (now>=F.Mortar.Due-0.000001 or (F.Mortar.LastTime and now<F.Mortar.LastTime)) then checked(F.Mortar.Tick,"Mortar.Tick") end

        if F.Settings.AimEnabled then
            if now>=F.AimDue-0.000001 or (F.AimLastTick and now<F.AimLastTick) then
                checked(F.Aim.Tick,"Aim.Render")
                F.AimLastTick=now
                F.AimDue=now+((pawn and pawn.bIsWeaponFiring) and 0.011 or 0.05)
                if not (pawn and pawn.bIsWeaponFiring) then F.AimLastClock=nil end
            end
        end
        if F.Settings.WallEnabled then checked(F.Wall.Tick,"Wall.Tick",now,pawn,pc) end
        if _G.LexusConfig.IpadView and now>=F.IpadDue then
            checked(g_masterahsanyt_ApplyiPadView,"Ipad")
            F.IpadDue=now+0.5
        end
        if F.Dirty and now>=F.SaveDue then checked(F.Save,"Settings.Save");F.SaveDue=now+0.5 end
    end
    F.NextInterval=function(now)
        if not F.LastPC or not F.LastPawn then return 0.50 end
        local nextDelay=0.50
        local function due(deadline) nextDelay=math.min(nextDelay,math.max(0.001,(deadline or now)-now)) end
        local welcome=_G.LunarStandaloneWelcome
        if welcome and welcome.NeedsUpdate and welcome.Due then due(welcome.Due) end
        local circle=_G.LunarAimCircleHUD
        if circle and circle.Due then due(circle.Due) end
        local o=_G.g_Botmater_ESPOptions
        if o.Name or o.Line or o.Box or o.Health or o.Distance or o.Weapon or o.Flag or o.Visibility or o.Alert or o.EnemyCounter then due(F.V1Due) end
        if F.Settings.AimEnabled then due(F.AimDue) end
        if F.Settings.Aim2Enabled then nextDelay=math.min(nextDelay,F.Aim2.NextInterval(now))
        elseif next(F.Aim2.Records) then due(F.Aim2RestoreDue) end
        if F.Settings.MortarEnabled then nextDelay=math.min(nextDelay,F.Mortar.NextInterval(now)) end
        if F.Settings.WallEnabled then due(F.Wall.LastTick+0.30);due(F.Wall.LastCleanup+F.Wall.CleanupInterval) end
        if _G.LexusConfig.IpadView then due(F.IpadDue) end
        if F.Dirty then due(F.SaveDue) end
        return nextDelay
    end
    F.Wake=function()
        if F.Token.Stopped then return end
        F.V1Due=0;F.AimDue=0
        if F.Aim2 then F.Aim2.Due=0 end
        if F.Mortar then F.Mortar.Due=0 end
        F.Wall.LastTick=-999
        local due=g_masterahsanyt_ESPRunnerToken.Due
        if not due or due-g_masterahsanyt_ESPNow()>0.002 then g_masterahsanyt_ESPSchedule(0.001) end
    end
end


-- Settings maintenance uses the working reference's native timer fallbacks.
local g_masterahsanyt_FastRunnerToken = {}
local previousSettingsRunner = _G.__MasterShotFastRunner
if type(previousSettingsRunner) == "table" and previousSettingsRunner.Timer and previousSettingsRunner.Owner then
    pcall(function() previousSettingsRunner.Owner:RemoveGameTimer(previousSettingsRunner.Timer) end)
end
_G.__MasterShotFastRunner = g_masterahsanyt_FastRunnerToken
local function g_masterahsanyt_FastTick()
    if _G.__MasterShotFastRunner ~= g_masterahsanyt_FastRunnerToken then return end
    g_masterahsanyt_EnsureHackMenu()
    local render=_G.__MasterShotESPRunner
    if not render or not render.Due then pcall(g_masterahsanyt_ApplyiPadView) end
end
do
    local token = g_masterahsanyt_FastRunnerToken
    local function member(object, key)
        if object == nil then return nil end
        local ok, value = pcall(function() return object[key] end)
        if ok then return value end
    end
    local function valid(object)
        if object == nil then return false end
        if slua and type(slua.isValid) == "function" then
            local ok, value = pcall(slua.isValid, object)
            return ok and value == true
        end
        return false
    end
    local function timerOwnerReady(owner)
        return owner ~= nil and (owner == Game or valid(owner) or valid(member(owner, "Object")))
    end
    local function callback()
        if _G.__MasterShotFastRunner ~= token then
            if token.Timer and token.Owner then pcall(function() token.Owner:RemoveGameTimer(token.Timer) end) end
            token.Timer = nil
            return
        end
        g_masterahsanyt_FastTick()
        g_masterahsanyt_StartSettingsMaintenance()
    end
    g_masterahsanyt_StartSettingsMaintenance = function(owner)
        if _G.__MasterShotFastRunner ~= token then return false end
        if token.Pending then return true end
        if token.Timer and (token.Provider == "ticker" or timerOwnerReady(token.Owner)) then return true end
        if token.Timer and token.Owner then pcall(function() token.Owner:RemoveGameTimer(token.Timer) end) end
        token.Timer, token.Owner, token.Provider = nil, nil, nil

        local candidates = {}
        local function add(candidate, kind)
            if not timerOwnerReady(candidate) or type(member(candidate, "AddGameTimer")) ~= "function" then return end
            for _, entry in ipairs(candidates) do if entry.Object == candidate then return end end
            candidates[#candidates + 1] = {Object = candidate, Kind = kind}
        end
        local pc
        pcall(function() if GameplayData.GetPlayerController then pc = GameplayData.GetPlayerController() end end)
        if not valid(pc) then pcall(function() if slua_GameFrontendHUD then pc = slua_GameFrontendHUD:GetPlayerController() end end) end
        add(pc, "controller")
        add(owner, "character")
        add(Game, "game")
        for _, entry in ipairs(candidates) do
            local ok, timer = pcall(function() return entry.Object:AddGameTimer(1.0, true, callback) end)
            if ok and timer then
                token.Timer, token.Owner, token.Provider = timer, entry.Object, entry.Kind
                token.LastError = nil
                g_masterahsanyt_FastTick()
                return true
            end
        end
        local okTicker, ticker = pcall(require, "common.time_ticker")
        if okTicker and ticker then
            if type(ticker.AddTimer) == "function" then
                local ok, timer = pcall(ticker.AddTimer, 1.0, true, callback)
                if ok and timer then
                    token.Timer, token.Owner, token.Provider = timer, ticker, "ticker"
                    token.LastError = nil
                    return true
                end
            end
            if type(ticker.AddTimerOnce) == "function" then
                token.Pending, token.Provider = true, "ticker_once"
                local ok, accepted = pcall(ticker.AddTimerOnce, 1.0, function()
                    token.Pending = false
                    callback()
                end)
                if ok and accepted ~= false then token.LastError = nil; return true end
                token.Pending, token.Provider = false, nil
                token.LastError = tostring(accepted)
            else token.LastError = "SETTINGS_TIMER_API_UNAVAILABLE" end
        else
            if package and package.loaded and type(package.loaded["common.time_ticker"]) ~= "table" then
                package.loaded["common.time_ticker"] = nil
            end
            token.LastError = tostring(ticker)
        end
        return false
    end
end


g_masterahsanyt_EnsureHackMenu()
if _G.LunarStandaloneWelcome then _G.LunarStandaloneWelcome.NeedsUpdate=true end
g_masterahsanyt_FastTick()
g_masterahsanyt_StartSettingsMaintenance()
g_masterahsanyt_ShotESP.Running=true
g_masterahsanyt_ESPTick()
end
local ok,startError=pcall(startBaselineHacks)
if not ok then
    _G.LunarOptionalStartupError=tostring(startError)
    if _G.LunarFeatures and _G.LunarFeatures.Error then _G.LunarFeatures.Error("Startup",startError) end
end
return originalExport
