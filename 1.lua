local SlateBlueprintLibrary = nil
local WidgetLayoutLibrary = nil
local FVector2D = nil
local FVector = nil
local FLinearColor = nil
local FSlateColor = nil

pcall(function()
    SlateBlueprintLibrary = import("SlateBlueprintLibrary") or import("/Script/UMG.SlateBlueprintLibrary")
    WidgetLayoutLibrary = import("WidgetLayoutLibrary") or import("/Script/UMG.WidgetLayoutLibrary")
    FVector2D = import("Vector2D")
    FVector = import("Vector")
    FLinearColor = import("LinearColor")
    FSlateColor = import("SlateColor") or import("/Script/SlateCore.SlateColor")
end)

local function IsValid(obj)
    if not obj then return false end
    if slua and slua.isValid then
        return slua.isValid(obj)
    end
    return true
end

local TempProjVec2D = FVector2D and FVector2D(0, 0) or nil
local ColorWhite = FLinearColor and FLinearColor(1.0, 1.0, 1.0, 1.0) or nil
local ColorRed = FLinearColor and FLinearColor(1.0, 0.15, 0.15, 1.0) or nil
local ColorGreen = FLinearColor and FLinearColor(0.0, 1.0, 0.05, 1.0) or nil
local ColorYellow = FLinearColor and FLinearColor(1.0, 0.95, 0.0, 1.0) or nil
local ColorBlue = FLinearColor and FLinearColor(0.18, 0.62, 1.0, 1.0) or nil

local SlateColorRed = (FSlateColor and ColorRed) and FSlateColor(ColorRed) or ColorRed
local SlateColorGreen = (FSlateColor and ColorGreen) and FSlateColor(ColorGreen) or ColorGreen

-- ========== Enemy Counter Image Loader ==========
local ENEMY_COUNTER_PLAYER_URLS = {
}
local ENEMY_COUNTER_BOT_URLS = {
}
local EnemyCounterTextureCache = {}
local BADGE_WIDTH = 48
local BADGE_HEIGHT = 22

local function FileExists(path)
    if not path or path == "" then return false end
    local f = io.open(path, "r")
    if f then f:close() return true end
    return false
end

local function GetPossibleLocalPaths(filename)
    return {
        "/storage/emulated/0/Android/data/com.tencent.ig/files/" .. filename,
        "/storage/emulated/0/Android/data/com.pubg.krmobile/files/" .. filename,
        "/storage/emulated/0/Android/data/com.vng.pubgmobile/files/" .. filename,
        "/storage/emulated/0/Android/data/com.rekoo.pubgm/files/" .. filename,
        "/storage/emulated/0/Android/data/com.tencent.tmgp.pubgmhd/files/" .. filename,
        filename
    }
end

local function LoadBadgeTexture(imgWidget, urls, filename, typeKey, counterData)
    if not imgWidget or not IsValid(imgWidget) then return end

    if EnemyCounterTextureCache[typeKey] and IsValid(EnemyCounterTextureCache[typeKey]) then
        pcall(function()
            imgWidget:SetBrushFromTexture(EnemyCounterTextureCache[typeKey], false)
            imgWidget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        end)
        if counterData then
            if typeKey == "Player" then counterData.PlayerLoaded = true end
            if typeKey == "Bot" then counterData.BotLoaded = true end
        end
        return
    end

    local function applyTex(tex)
        if tex and IsValid(tex) and IsValid(imgWidget) then
            EnemyCounterTextureCache[typeKey] = tex
            if counterData then
                if typeKey == "Player" then counterData.PlayerLoaded = true end
                if typeKey == "Bot" then counterData.BotLoaded = true end
            end
            pcall(function()
                imgWidget:SetBrushFromTexture(tex, false)
                imgWidget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
            end)
            return true
        end
        return false
    end

    local localPaths = GetPossibleLocalPaths(filename)
    for _, localPath in ipairs(localPaths) do
        if FileExists(localPath) then
            local tex = nil
            pcall(function()
                local asset_util = package.loaded["common.asset_util"] or require("common.asset_util")
                if asset_util and asset_util.GetAssetSync then tex = asset_util.GetAssetSync(localPath) end
            end)
            if not tex then
                pcall(function() if CGame and CGame.LoadObject then tex = CGame:LoadObject(localPath) end end)
            end
            if tex and applyTex(tex) then return end
        end
    end

    local function tryDownloadUrl(urlIndex)
        if urlIndex > #urls then return end
        local url = urls[urlIndex]
        local bDownloaded = false

        pcall(function()
            local AsyncTaskDownloadImage = import("AsyncTaskDownloadImage") or import("/Script/UMG.AsyncTaskDownloadImage")
            if AsyncTaskDownloadImage and AsyncTaskDownloadImage.DownloadImage then
                local task = AsyncTaskDownloadImage.DownloadImage(url)
                if task and task.OnSuccess then
                    task.OnSuccess:Add(function(tex)
                        if not bDownloaded and tex then
                            bDownloaded = true
                            applyTex(tex)
                        end
                    end)
                    if task.OnFail then
                        task.OnFail:Add(function()
                            if not bDownloaded then tryDownloadUrl(urlIndex + 1) end
                        end)
                    end
                end
            end
        end)

        if not bDownloaded then
            pcall(function()
                local mm = _G.ModuleManager or package.loaded["GameLua.GameCore.Module.ModuleManager"]
                if not mm then pcall(function() mm = require("GameLua.GameCore.Module.ModuleManager") end) end
                local imgMgr = nil
                if mm and mm.GetModule and mm.CommonModuleConfig then
                    imgMgr = mm.GetModule(mm.CommonModuleConfig.image_download_mgr)
                end
                if not imgMgr then pcall(function() imgMgr = require("client.slua.logic.image_download.image_download_mgr") end) end
                if imgMgr and imgMgr.DownloadImageByHttpWrapper then
                    imgMgr:DownloadImageByHttpWrapper(url, function(tex)
                        if not bDownloaded and tex then bDownloaded = true; applyTex(tex) end
                    end, function()
                        if not bDownloaded then tryDownloadUrl(urlIndex + 1) end
                    end)
                end
            end)
        end

        if not bDownloaded then
            pcall(function()
                local util = package.loaded["client.slua_ui_framework.util"]
                if not util then pcall(function() util = require("client.slua_ui_framework.util") end) end
                if util and util.SetTexture then
                    util.SetTexture(imgWidget, url, {
                        sync = false,
                        onDownloadSuccess = function(tex)
                            if not bDownloaded and tex then bDownloaded = true; applyTex(tex) end
                        end
                    })
                end
            end)
        end
    end

    tryDownloadUrl(1)
end

-- ========== BoxESP Master Table ==========
local BoxESP = {
    bActive = true,
    bShowLines = false,
    bShowCounter = true,
    ESPCanvas = nil,
    BoxWidgets = {},
    LineWidgets = {},

    CounterData = {
        ImgPlayer = nil,
        SlotPlayer = nil,
        ImgBot = nil,
        SlotBot = nil,
        TxtPlayer = nil,
        SlotTxtPlayer = nil,
        TxtBot = nil,
        SlotTxtBot = nil,
        LastPlayerCount = -1,
        LastBotCount = -1,
        PlayerLoaded = false,
        BotLoaded = false,
        LastDownloadRetry = 0,
        bCreated = false
    },

    HealthColor = { R = 0.0, G = 1.0, B = 0.0, A = 1.0 },
    HealthBgColor = { R = 0.0, G = 0.0, B = 0.0, A = 0.85 },
    HealthBarWidth = 2.0,
    CornerColor = { R = 1.0, G = 1.0, B = 1.0, A = 1.0 },
    CornerThickness = 1.0,
    CornerLengthRatio = 0.28,
    SnapLineThickness = 1.0,
    SnapLineOriginY = 72,

    _CanvasScaleX = 1.0,
    _CanvasScaleY = 1.0,
    _CanvasOffsetX = 0.0,
    _CanvasOffsetY = 0.0,
    _LastCanvas = nil,
    _LastTransformTime = 0,
    _LastHeavyUpdateTime = 0,
    _LastVisCheckTime = 0,
    _VisCheckCache = {}
}

function BoxESP.GetMainCanvas()
    if BoxESP.ESPCanvas and IsValid(BoxESP.ESPCanvas) then
        return BoxESP.ESPCanvas
    end

    local InGameUITools = package.loaded["GameLua.Mod.BaseMod.Common.UI.InGameUITools"]
    if not InGameUITools then
        pcall(function() InGameUITools = require("GameLua.Mod.BaseMod.Common.UI.InGameUITools") end)
    end
    if not InGameUITools then return nil end

    local MainUI = nil
    if InGameUITools.GetMainControlBaseUI then
        MainUI = InGameUITools.GetMainControlBaseUI()
    end
    if not IsValid(MainUI) then return nil end

    local ParentCanvas = nil
    if MainUI.CanvasPanel_0 and IsValid(MainUI.CanvasPanel_0) then
        ParentCanvas = MainUI.CanvasPanel_0
    elseif MainUI.CanvasPanel_42 and IsValid(MainUI.CanvasPanel_42) then
        ParentCanvas = MainUI.CanvasPanel_42
    end

    if ParentCanvas then
        BoxESP.ESPCanvas = ParentCanvas
        BoxESP._LastCanvas = ParentCanvas
    end
    return ParentCanvas
end

function BoxESP.CreateESPWidget(ParentCanvas)
    if not FLinearColor or not FVector2D then return nil end

    -- Box, health bar, and snap-line rendering are intentionally disabled.
    -- Text/flag widgets are kept because they are the requested information.
    local CornerContainer, CornerMainSlot, CornerLines = nil, nil, nil
    local BgImage, BgSlot = nil, nil
    local HealthImage, HealthSlot = nil, nil

    local function CreateStyledTextBlock(defaultColor, fontSize, alignment)
        local txt = CGame:NewObjectFromPath("/Script/UMG.TextBlock", ParentCanvas)
        local slot = nil
        if txt and IsValid(txt) then
            txt:SetText("")
            local intSize = math.floor(fontSize or 10)
            if txt.Font then
                local newFont = txt.Font
                newFont.Size = intSize
                if newFont.OutlineSettings then
                    newFont.OutlineSettings.OutlineSize = 1
                    newFont.OutlineSettings.OutlineColor = FLinearColor(0.0, 0.0, 0.0, 1.0)
                end
                if txt.SetFont then txt:SetFont(newFont) else txt.Font = newFont end
            end

            if txt.SetFontSize then txt:SetFontSize(intSize) end
            txt:SetJustification(1)
            if txt.SetHorizontalAlignment then txt:SetHorizontalAlignment(1) end
            if txt.SetVerticalAlignment then txt:SetVerticalAlignment(1) end
            if txt.SetAutoWrapText then txt:SetAutoWrapText(false) end

            if FSlateColor then
                txt:SetColorAndOpacity(FSlateColor(defaultColor))
            else
                txt:SetColorAndOpacity(defaultColor)
            end

            if txt.SetShadowOffset then txt:SetShadowOffset(FVector2D(0.0, 0.0)) end
            if txt.SetShadowColorAndOpacity then txt:SetShadowColorAndOpacity(FLinearColor(0.0, 0.0, 0.0, 0.0)) end
            txt:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)

            slot = ParentCanvas:AddChildToCanvas(txt)
            if slot then
                slot:SetAutoSize(true)
                slot:SetZOrder(1000)
                slot:SetAlignment(alignment or FVector2D(0.5, 0.0))
            end
        end
        return txt, slot
    end

    local WeaponWidget, WeaponSlot = CreateStyledTextBlock(ColorYellow, 10, FVector2D(0.5, 1.0))
    local NameWidget, NameSlot = CreateStyledTextBlock(ColorBlue, 10, FVector2D(0.5, 0.0))
    local DistWidget, DistSlot = CreateStyledTextBlock(ColorWhite, 10, FVector2D(0.5, 0.0))
    local StateWidget, StateSlot = CreateStyledTextBlock(ColorGreen, 10, FVector2D(0.5, 0.0))

    local FlagImage = CGame:NewObjectFromPath("/Script/UMG.Image", ParentCanvas)
    local FlagSlot = nil
    if FlagImage and IsValid(FlagImage) then
        FlagImage:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        FlagSlot = ParentCanvas:AddChildToCanvas(FlagImage)
        if FlagSlot then
            FlagSlot:SetAutoSize(false)
            FlagSlot:SetSize(FVector2D(14, 16))
            FlagSlot:SetZOrder(1000)
            FlagSlot:SetAlignment(FVector2D(0.5, 1.0))
        end
    end

    return {
        CornerContainer = CornerContainer,
        CornerSlot = CornerMainSlot,
        Corners = CornerLines,
        BgWidget = BgImage,
        BgSlot = BgSlot,
        HealthWidget = HealthImage,
        HealthSlot = HealthSlot,
        WeaponWidget = WeaponWidget,
        WeaponSlot = WeaponSlot,
        FlagWidget = FlagImage,
        FlagSlot = FlagSlot,
        NameWidget = NameWidget,
        NameSlot = NameSlot,
        DistWidget = DistWidget,
        DistSlot = DistSlot,
        StateWidget = StateWidget,
        StateSlot = StateSlot,
        _cachedWeapon = "",
        _cachedNation = nil,
        _cachedName = "",
        _cachedDist = "",
        _cachedState = "",
        _cachedIsCover = false,
        _cachedIsKnocked = false,
        _lastScanTime = 0,
        lastW = 0,
        lastH = 0,
        bVisible = true
    }
end

function BoxESP.UpdateCornerDimensions(boxData, width, height)
    if boxData.lastW and boxData.lastH then
        if math.abs(width - boxData.lastW) < 1.5 and math.abs(height - boxData.lastH) < 1.5 then
            return
        end
    end
    boxData.lastW = width
    boxData.lastH = height

    local t = BoxESP.CornerThickness
    local cLen = math.max(7, math.min(width, height) * BoxESP.CornerLengthRatio)
    local C = boxData.Corners

    boxData.CornerSlot:SetSize(FVector2D(width, height))

    if C.TopLeft_H and C.TopLeft_H.slot then
        C.TopLeft_H.slot:SetPosition(FVector2D(0, 0))
        C.TopLeft_H.slot:SetSize(FVector2D(cLen, t))
    end
    if C.TopLeft_V and C.TopLeft_V.slot then
        C.TopLeft_V.slot:SetPosition(FVector2D(0, 0))
        C.TopLeft_V.slot:SetSize(FVector2D(t, cLen))
    end

    if C.TopRight_H and C.TopRight_H.slot then
        C.TopRight_H.slot:SetPosition(FVector2D(width - cLen, 0))
        C.TopRight_H.slot:SetSize(FVector2D(cLen, t))
    end
    if C.TopRight_V and C.TopRight_V.slot then
        C.TopRight_V.slot:SetPosition(FVector2D(width - t, 0))
        C.TopRight_V.slot:SetSize(FVector2D(t, cLen))
    end

    if C.BottomLeft_H and C.BottomLeft_H.slot then
        C.BottomLeft_H.slot:SetPosition(FVector2D(0, height - t))
        C.BottomLeft_H.slot:SetSize(FVector2D(cLen, t))
    end
    if C.BottomLeft_V and C.BottomLeft_V.slot then
        C.BottomLeft_V.slot:SetPosition(FVector2D(0, height - cLen))
        C.BottomLeft_V.slot:SetSize(FVector2D(t, cLen))
    end

    if C.BottomRight_H and C.BottomRight_H.slot then
        C.BottomRight_H.slot:SetPosition(FVector2D(width - cLen, height - t))
        C.BottomRight_H.slot:SetSize(FVector2D(cLen, t))
    end
    if C.BottomRight_V and C.BottomRight_V.slot then
        C.BottomRight_V.slot:SetPosition(FVector2D(width - t, height - cLen))
        C.BottomRight_V.slot:SetSize(FVector2D(t, cLen))
    end
end

function BoxESP.UpdateCanvasTransform(PC)
    if not BoxESP.ESPCanvas or not IsValid(BoxESP.ESPCanvas) then return end

    local success = false
    if SlateBlueprintLibrary and SlateBlueprintLibrary.AbsoluteToLocal then
        local cg = BoxESP.ESPCanvas:GetCachedGeometry()
        if cg then
            local pt0 = SlateBlueprintLibrary.AbsoluteToLocal(cg, FVector2D(0, 0))
            local pt1 = SlateBlueprintLibrary.AbsoluteToLocal(cg, FVector2D(100, 100))
            if pt0 and pt1 then
                BoxESP._CanvasScaleX = (pt1.X - pt0.X) / 100
                BoxESP._CanvasScaleY = (pt1.Y - pt0.Y) / 100
                BoxESP._CanvasOffsetX = pt0.X
                BoxESP._CanvasOffsetY = pt0.Y
                success = true
            end
        end
    end

    if not success and WidgetLayoutLibrary and WidgetLayoutLibrary.GetViewportScale then
        local scale = WidgetLayoutLibrary.GetViewportScale(PC) or 1.0
        BoxESP._CanvasScaleX = 1.0 / scale
        BoxESP._CanvasScaleY = 1.0 / scale
        BoxESP._CanvasOffsetX = 0
        BoxESP._CanvasOffsetY = 0
    end
end

function BoxESP.ProjectWorldToCanvasLocal(PC, WorldLoc)
    if not IsValid(PC) or not WorldLoc or not TempProjVec2D then return false, 0, 0 end

    local res = PC:ProjectWorldLocationToScreen(WorldLoc, TempProjVec2D, true)
    if (res == true or res == 1) and (TempProjVec2D.X ~= 0 or TempProjVec2D.Y ~= 0) then
        local finalX = TempProjVec2D.X * BoxESP._CanvasScaleX + BoxESP._CanvasOffsetX
        local finalY = TempProjVec2D.Y * BoxESP._CanvasScaleY + BoxESP._CanvasOffsetY
        return true, finalX, finalY
    end
    return false, 0, 0
end

-- ========== Snap Line Functionality ==========
function BoxESP.GetSnapLineStartPos(PC, ParentCanvas)
    local screenPixelW, screenPixelH = 0, 0
    local scale = 1.0

    pcall(function()
        if PC and PC.GetViewportSize then
            local vs = FVector2D(0, 0)
            PC:GetViewportSize(vs)
            if vs and vs.X and vs.X > 200 then
                screenPixelW = vs.X
                screenPixelH = vs.Y
            end
        end
    end)

    if screenPixelW <= 200 then
        pcall(function()
            if WidgetLayoutLibrary and WidgetLayoutLibrary.GetViewportSize then
                local vs = WidgetLayoutLibrary.GetViewportSize(PC)
                if vs and vs.X and vs.X > 200 then
                    screenPixelW = vs.X
                    screenPixelH = vs.Y
                end
            end
        end)
    end

    pcall(function()
        if WidgetLayoutLibrary and WidgetLayoutLibrary.GetViewportScale then
            local s = WidgetLayoutLibrary.GetViewportScale(PC)
            if s and type(s) == "number" and s > 0 then scale = s end
        end
    end)

    if screenPixelW <= 200 then
        screenPixelW = 1920 * scale
        screenPixelH = 1080 * scale
    end

    local centerPixelX = screenPixelW / 2.0
    local centerPixelY = BoxESP.SnapLineOriginY * scale

    local fromX = centerPixelX * BoxESP._CanvasScaleX + BoxESP._CanvasOffsetX
    local fromY = centerPixelY * BoxESP._CanvasScaleY + BoxESP._CanvasOffsetY
    return fromX, fromY
end

function BoxESP.CreateSnapLine(ParentCanvas)
    if not IsValid(ParentCanvas) then return nil end
    local border = CGame:NewObjectFromPath("/Script/UMG.Border", ParentCanvas)
    if not IsValid(border) then return nil end

    border:SetBrushColor(ColorWhite)
    border:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
    border.RenderTransformPivot = FVector2D(0.0, 0.5)
    border:SetRenderTransformPivot(FVector2D(0.0, 0.5))

    local slot = ParentCanvas:AddChildToCanvas(border)
    if slot then
        slot:SetAutoSize(false)
        slot:SetZOrder(990)
    end
    return { Widget = border, Slot = slot, bVisible = true }
end

function BoxESP.UpdateSnapLine(KeyStr, toX, toY, fromX, fromY, CustomColor, ParentCanvas)
    local lineData = BoxESP.LineWidgets[KeyStr]
    if not lineData or not IsValid(lineData.Widget) then
        lineData = BoxESP.CreateSnapLine(ParentCanvas)
        if not lineData or not lineData.Widget or not lineData.Slot then return end
        BoxESP.LineWidgets[KeyStr] = lineData
    end

    if not lineData.bVisible then
        lineData.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        lineData.bVisible = true
    end

    if CustomColor then
        pcall(function() lineData.Widget:SetBrushColor(CustomColor) end)
    end

    local dx = toX - fromX
    local dy = toY - fromY
    local length = math.sqrt(dx * dx + dy * dy)
    local angle = (math.atan2 and math.atan2(dy, dx) or math.atan(dy, dx)) * (180.0 / math.pi)
    local t = BoxESP.SnapLineThickness or 1.0

    if not lineData._CachedPosVec then
        lineData._CachedPosVec = FVector2D(fromX, fromY - t * 0.5)
        lineData._CachedSizeVec = FVector2D(length, t)
    else
        lineData._CachedPosVec.X = fromX
        lineData._CachedPosVec.Y = fromY - t * 0.5
        lineData._CachedSizeVec.X = length
        lineData._CachedSizeVec.Y = t
    end

    pcall(function()
        lineData.Slot:SetPosition(lineData._CachedPosVec)
        lineData.Slot:SetSize(lineData._CachedSizeVec)
        lineData.Widget:SetRenderAngle(angle)
    end)
end

function BoxESP.HideSnapLine(KeyStr)
    local lineData = BoxESP.LineWidgets[KeyStr]
    if lineData and lineData.Widget and IsValid(lineData.Widget) and lineData.bVisible then
        lineData.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
        lineData.bVisible = false
    end
end

-- ========== Enemy Counter with Images ==========
function BoxESP.CreateEnemyCounter(ParentCanvas, centerX, topY)
    local CD = BoxESP.CounterData
    if CD.ImgPlayer and IsValid(CD.ImgPlayer) and CD.ImgBot and IsValid(CD.ImgBot) then
        return true
    end

    local imgPlayer = CGame:NewObjectFromPath("/Script/UMG.Image", ParentCanvas)
    local slotPlayer = nil
    if imgPlayer and IsValid(imgPlayer) then
        imgPlayer:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        slotPlayer = ParentCanvas:AddChildToCanvas(imgPlayer)
        if slotPlayer then
            slotPlayer:SetAutoSize(false)
            slotPlayer:SetSize(FVector2D(BADGE_WIDTH, BADGE_HEIGHT))
            slotPlayer:SetPosition(FVector2D(centerX - BADGE_WIDTH, topY))
            slotPlayer:SetZOrder(1005)
        end
    end

    local imgBot = CGame:NewObjectFromPath("/Script/UMG.Image", ParentCanvas)
    local slotBot = nil
    if imgBot and IsValid(imgBot) then
        imgBot:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        slotBot = ParentCanvas:AddChildToCanvas(imgBot)
        if slotBot then
            slotBot:SetAutoSize(false)
            slotBot:SetSize(FVector2D(BADGE_WIDTH, BADGE_HEIGHT))
            slotBot:SetPosition(FVector2D(centerX, topY))
            slotBot:SetZOrder(1005)
        end
    end

    local function MakeCounterText(posX, posY)
        local txt = CGame:NewObjectFromPath("/Script/UMG.TextBlock", ParentCanvas)
        local sl = nil
        if txt and IsValid(txt) then
            txt:SetText("0")
            if txt.Font then
                local font = txt.Font
                font.Size = 10
                if font.OutlineSettings then
                    font.OutlineSettings.OutlineSize = 0.0
                    font.OutlineSettings.OutlineColor = FLinearColor(0, 0, 0, 0)
                end
                txt.Font = font
            end
            if txt.SetFontSize then txt:SetFontSize(10) end
            txt:SetJustification(1)
            pcall(function() txt:SetAutoWrapText(false) end)
            if FSlateColor then
                txt:SetColorAndOpacity(FSlateColor(ColorWhite))
            else
                txt:SetColorAndOpacity(ColorWhite)
            end
            txt:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
            sl = ParentCanvas:AddChildToCanvas(txt)
            if sl then
                sl:SetAutoSize(true)
                sl:SetAlignment(FVector2D(0.5, 0.5))
                sl:SetPosition(FVector2D(posX, posY))
                sl:SetZOrder(1010)
            end
        end
        return txt, sl
    end

    local txtPlayer, slotTxtPlayer = MakeCounterText(centerX - (BADGE_WIDTH * 0.25), topY + (BADGE_HEIGHT * 0.5))
    local txtBot, slotTxtBot = MakeCounterText(centerX + (BADGE_WIDTH * 0.65), topY + (BADGE_HEIGHT * 0.5))

    LoadBadgeTexture(imgPlayer, ENEMY_COUNTER_PLAYER_URLS, "ic_danger_enemy.png", "Player", CD)
    LoadBadgeTexture(imgBot, ENEMY_COUNTER_BOT_URLS, "ic_clear_boot.png", "Bot", CD)

    CD.ImgPlayer = imgPlayer
    CD.SlotPlayer = slotPlayer
    CD.ImgBot = imgBot
    CD.SlotBot = slotBot
    CD.TxtPlayer = txtPlayer
    CD.SlotTxtPlayer = slotTxtPlayer
    CD.TxtBot = txtBot
    CD.SlotTxtBot = slotTxtBot
    CD.bCreated = true
    return true
end

function BoxESP.UpdateEnemyCounterDisplay(realCount, botCount, ParentCanvas, centerX, topY)
    local CD = BoxESP.CounterData
    if not BoxESP.bShowCounter then
        local col = UEnums.ESlateVisibility.Collapsed
        if CD.ImgPlayer and IsValid(CD.ImgPlayer) then CD.ImgPlayer:SetWidgetVisibility(col) end
        if CD.ImgBot and IsValid(CD.ImgBot) then CD.ImgBot:SetWidgetVisibility(col) end
        if CD.TxtPlayer and IsValid(CD.TxtPlayer) then CD.TxtPlayer:SetWidgetVisibility(col) end
        if CD.TxtBot and IsValid(CD.TxtBot) then CD.TxtBot:SetWidgetVisibility(col) end
        return
    end

    if not BoxESP.CreateEnemyCounter(ParentCanvas, centerX, topY) then return end

    local now = os.clock()
    if (not CD.PlayerLoaded or not CD.BotLoaded) and (now - CD.LastDownloadRetry > 2.0) then
        CD.LastDownloadRetry = now
        if not CD.PlayerLoaded and CD.ImgPlayer then LoadBadgeTexture(CD.ImgPlayer, ENEMY_COUNTER_PLAYER_URLS, "ic_danger_enemy.png", "Player", CD) end
        if not CD.BotLoaded and CD.ImgBot then LoadBadgeTexture(CD.ImgBot, ENEMY_COUNTER_BOT_URLS, "ic_clear_boot.png", "Bot", CD) end
    end

    pcall(function()
        if CD.SlotPlayer then
            CD.SlotPlayer:SetSize(FVector2D(BADGE_WIDTH, BADGE_HEIGHT))
            CD.SlotPlayer:SetPosition(FVector2D(centerX - BADGE_WIDTH, topY))
        end
        if CD.SlotBot then
            CD.SlotBot:SetSize(FVector2D(BADGE_WIDTH, BADGE_HEIGHT))
            CD.SlotBot:SetPosition(FVector2D(centerX, topY))
        end
        if CD.SlotTxtPlayer then
            CD.SlotTxtPlayer:SetPosition(FVector2D(centerX - (BADGE_WIDTH * 0.25), topY + (BADGE_HEIGHT * 0.5)))
        end
        if CD.SlotTxtBot then
            CD.SlotTxtBot:SetPosition(FVector2D(centerX + (BADGE_WIDTH * 0.65), topY + (BADGE_HEIGHT * 0.5)))
        end

        if CD.LastPlayerCount ~= realCount then
            if CD.TxtPlayer and IsValid(CD.TxtPlayer) then CD.TxtPlayer:SetText(tostring(realCount)) end
            CD.LastPlayerCount = realCount
        end

        if CD.LastBotCount ~= botCount then
            if CD.TxtBot and IsValid(CD.TxtBot) then CD.TxtBot:SetText(tostring(botCount)) end
            CD.LastBotCount = botCount
        end

        local vis = UEnums.ESlateVisibility.SelfHitTestInvisible
        if CD.ImgPlayer and IsValid(CD.ImgPlayer) then CD.ImgPlayer:SetWidgetVisibility(vis) end
        if CD.ImgBot and IsValid(CD.ImgBot) then CD.ImgBot:SetWidgetVisibility(vis) end
        if CD.TxtPlayer and IsValid(CD.TxtPlayer) then CD.TxtPlayer:SetWidgetVisibility(vis) end
        if CD.TxtBot and IsValid(CD.TxtBot) then CD.TxtBot:SetWidgetVisibility(vis) end
    end)
end

function BoxESP.HideWidget(boxData)
    if not boxData or not boxData.bVisible then return end
    boxData.bVisible = false
    local collapsed = UEnums.ESlateVisibility.Collapsed
    if boxData.CornerContainer then boxData.CornerContainer:SetWidgetVisibility(collapsed) end
    if boxData.BgWidget then boxData.BgWidget:SetWidgetVisibility(collapsed) end
    if boxData.HealthWidget then boxData.HealthWidget:SetWidgetVisibility(collapsed) end
    if boxData.WeaponWidget then boxData.WeaponWidget:SetWidgetVisibility(collapsed) end
    if boxData.FlagWidget then boxData.FlagWidget:SetWidgetVisibility(collapsed) end
    if boxData.NameWidget then boxData.NameWidget:SetWidgetVisibility(collapsed) end
    if boxData.DistWidget then boxData.DistWidget:SetWidgetVisibility(collapsed) end
    if boxData.StateWidget then boxData.StateWidget:SetWidgetVisibility(collapsed) end
end

function BoxESP.ShowWidget(boxData)
    if not boxData or boxData.bVisible then return end
    boxData.bVisible = true
    local visible = UEnums.ESlateVisibility.SelfHitTestInvisible
    if boxData.CornerContainer then boxData.CornerContainer:SetWidgetVisibility(visible) end
    if boxData.BgWidget then boxData.BgWidget:SetWidgetVisibility(visible) end
    if boxData.HealthWidget then boxData.HealthWidget:SetWidgetVisibility(visible) end
    if boxData.WeaponWidget then boxData.WeaponWidget:SetWidgetVisibility(visible) end
    if boxData.FlagWidget then boxData.FlagWidget:SetWidgetVisibility(visible) end
    if boxData.NameWidget then boxData.NameWidget:SetWidgetVisibility(visible) end
    if boxData.DistWidget then boxData.DistWidget:SetWidgetVisibility(visible) end
    if boxData.StateWidget then boxData.StateWidget:SetWidgetVisibility(visible) end
end

function BoxESP.UpdateESP()
    if not BoxESP.bActive then return end

    local ParentCanvas = BoxESP.GetMainCanvas()
    if not ParentCanvas then return end

    local GameplayData = package.loaded["GameLua.GameCore.Data.GameplayData"] or _G.GameplayData
    if not GameplayData then return end

    local LocalPlayer = GameplayData.GetPlayerCharacter and GameplayData.GetPlayerCharacter()
    if not IsValid(LocalPlayer) then return end

    local PC = GameplayData.GetPlayerController and GameplayData.GetPlayerController()
    if not IsValid(PC) then return end

    local curTime = os.clock and os.clock() or 0
    if BoxESP._LastCanvas ~= ParentCanvas or (curTime - BoxESP._LastTransformTime > 1.0) then
        BoxESP.UpdateCanvasTransform(PC)
        BoxESP._LastCanvas = ParentCanvas
        BoxESP._LastTransformTime = curTime
    end

    local bRunHeavyTasks = (curTime - BoxESP._LastHeavyUpdateTime > 0.15)
    if bRunHeavyTasks then
        BoxESP._LastHeavyUpdateTime = curTime
    end

    local bUpdateVisCheck = (curTime - BoxESP._LastVisCheckTime > 0.12)
    if bUpdateVisCheck then
        BoxESP._LastVisCheckTime = curTime
    end

    local fromX, fromY = BoxESP.GetSnapLineStartPos(PC, ParentCanvas)

    local TeamID = LocalPlayer.TeamID or (LocalPlayer.GetTeamID and LocalPlayer:GetTeamID()) or 0
    local AllPawns = (Game and Game.GetAllPlayerPawns and Game:GetAllPlayerPawns()) or {}
    local SeenKeys = {}
    local RealPlayerCount = 0
    local BotCount = 0

    for Key, Pawn in pairs(AllPawns) do
        if IsValid(Pawn) and Pawn ~= LocalPlayer then
            local pawnTeam = Pawn.TeamID or (Pawn.GetTeamID and Pawn:GetTeamID()) or -1
            local isAlive = (Pawn.Health and Pawn.Health > 0) or (Pawn.IsAlive and Pawn:IsAlive())

            if isAlive and pawnTeam ~= TeamID then
                local KeyStr = tostring(Key)
                SeenKeys[KeyStr] = true

                local ping = (Pawn.PlayerState and Pawn.PlayerState.Ping) or Pawn.Ping or (Pawn.GetPing and Pawn:GetPing()) or -1
                ping = tonumber(ping) or -1
                local isBot = (ping >= 0 and ping <= 3) or Pawn.bIsAI or Pawn.bIsAIBot or Pawn.bIsABot or (Game and Game.IsAI and Game:IsAI(Pawn))

                if isBot then
                    BotCount = BotCount + 1
                else
                    RealPlayerCount = RealPlayerCount + 1
                end

                local Loc = Pawn.K2_GetActorLocation and Pawn:K2_GetActorLocation()
                if not Loc and Pawn.RootComponent then
                    Loc = Pawn.RootComponent:K2_GetComponentLocation()
                end

                if Loc then
                    local topWorldPos = nil
                    local bottomWorldPos = nil

                    local mesh = Pawn.Mesh or (Pawn.GetMesh and Pawn:GetMesh()) or Pawn.CharacterMesh0
                    if mesh and mesh.GetSocketLocation then
                        local hLoc = mesh:GetSocketLocation("Head") or mesh:GetSocketLocation("head")
                        if hLoc and (hLoc.X ~= 0 or hLoc.Y ~= 0 or hLoc.Z ~= 0) then
                            topWorldPos = FVector(hLoc.X, hLoc.Y, hLoc.Z + 15)
                        end
                        local rLoc = mesh:GetSocketLocation("root") or mesh:GetSocketLocation("Root")
                        if rLoc and (rLoc.X ~= 0 or rLoc.Y ~= 0 or rLoc.Z ~= 0) then
                            bottomWorldPos = rLoc
                        end
                    end

                    local isProne = false
                    local isCrouch = false
                    if Pawn.bIsProning or Pawn.bIsProne or (Pawn.IsProne and Pawn:IsProne()) or Pawn.PoseState == 2 or Pawn.PoseState == "Prone" then
                        isProne = true
                    elseif Pawn.bIsCrouched or (Pawn.IsCrouched and Pawn:IsCrouched()) or Pawn.PoseState == 1 or Pawn.PoseState == "Crouch" then
                        isCrouch = true
                    end

                    if not topWorldPos or not bottomWorldPos then
                        local topOffset = isProne and 18 or (isCrouch and 50 or 88)
                        local bottomOffset = isProne and -22 or (isCrouch and -68 or -90)
                        topWorldPos = topWorldPos or FVector(Loc.X, Loc.Y, Loc.Z + topOffset)
                        bottomWorldPos = bottomWorldPos or FVector(Loc.X, Loc.Y, Loc.Z + bottomOffset)
                    end

                    local bTopOk, topX, topY = BoxESP.ProjectWorldToCanvasLocal(PC, topWorldPos)
                    local bBottomOk, bottomX, bottomY = BoxESP.ProjectWorldToCanvasLocal(PC, bottomWorldPos)

                    local boxData = BoxESP.BoxWidgets[KeyStr]
                    if not boxData then
                        boxData = BoxESP.CreateESPWidget(ParentCanvas)
                        if boxData then BoxESP.BoxWidgets[KeyStr] = boxData end
                    end

                    if boxData then
                        if bTopOk and bBottomOk then
                            local boxHeight = math.max(28, math.abs(bottomY - topY))
                            local boxWidth = math.max(15, boxHeight * (isProne and 1.1 or (isCrouch and 0.7 or 0.55)))

                            local centerX = (topX + bottomX) * 0.5
                            local centerY = (topY + bottomY) * 0.5
                            local boxTopY = centerY - (boxHeight * 0.5)
                            local boxBottomY = centerY + (boxHeight * 0.5)

                            -- No box/corner rendering. Keep the projected dimensions only for text placement.
                            BoxESP.ShowWidget(boxData)

                            if bRunHeavyTasks or boxData._cachedWeapon == "" then
                                local wep = (Pawn.GetCurrentWeapon and Pawn:GetCurrentWeapon())
                                    or (Pawn.GetCurrentShootWeapon and Pawn:GetCurrentShootWeapon())
                                    or (Pawn.WeaponManagerComponent and Pawn.WeaponManagerComponent.CurrentWeaponReplicated)
                                local weaponName = "Fist"
                                if wep and IsValid(wep) then
                                    local wn = (type(wep.GetWeaponName) == "function" and wep:GetWeaponName()) or wep.WeaponName
                                    if wn and wn ~= "" then
                                        weaponName = tostring(wn):gsub("^BP_", ""):gsub("_C$", ""):gsub("_Wrapper$", "")
                                    end
                                end
                                if boxData._cachedWeapon ~= weaponName then
                                    boxData.WeaponWidget:SetText(weaponName)
                                    boxData._cachedWeapon = weaponName
                                end
                            end
                            boxData.WeaponSlot:SetPosition(FVector2D(centerX, boxTopY - 3.5))

                            if bRunHeavyTasks or not boxData._cachedNation then
                                local playerNation = (Pawn.PlayerState and Pawn.PlayerState.Nation) or Pawn.Nation or ""
                                playerNation = tostring(playerNation or "")
                                if playerNation == "" or playerNation == "nil" or playerNation == "0" then
                                    playerNation = "G1"
                                end

                                if boxData._cachedNation ~= playerNation then
                                    local cfg = (CDataTable and CDataTable.GetTableData) and CDataTable.GetTableData("RegionConfig", playerNation)
                                    if not cfg or not cfg.res_path or cfg.res_path == "" then
                                        cfg = (CDataTable and CDataTable.GetTableData) and CDataTable.GetTableData("RegionConfig", "G1")
                                    end
                                    local flagPath = (cfg and cfg.res_path) or "/Game/UMG/Texture/Atlas/NationalflagUI/Frames/T_icon_flag_iland_png.T_icon_flag_iland_png"

                                    if boxData.FlagWidget and IsValid(boxData.FlagWidget) then
                                        local bSet = false
                                        if boxData.FlagWidget.SetBrushResourceFromPathSync then
                                            boxData.FlagWidget:SetBrushResourceFromPathSync(flagPath, false)
                                            bSet = true
                                        end
                                        if not bSet and boxData.FlagWidget.SetBrushFromPathAsync then
                                            boxData.FlagWidget:SetBrushFromPathAsync(flagPath, false)
                                            bSet = true
                                        end
                                        if not bSet then
                                            local util = package.loaded["client.slua_ui_framework.util"]
                                            if not util then pcall(function() util = require("client.slua_ui_framework.util") end) end
                                            if util and util.SetTexture then
                                                util.SetTexture(boxData.FlagWidget, flagPath, { sync = true })
                                                bSet = true
                                            end
                                        end
                                        if not bSet then
                                            local asset_util = package.loaded["common.asset_util"]
                                            if not asset_util then pcall(function() asset_util = require("common.asset_util") end) end
                                            local flagTex = (asset_util and asset_util.GetAssetSync and asset_util.GetAssetSync(flagPath))
                                                         or (CGame and CGame.LoadObject and CGame:LoadObject(flagPath))
                                            if flagTex and boxData.FlagWidget.SetBrushFromTexture then
                                                boxData.FlagWidget:SetBrushFromTexture(flagTex, false)
                                                bSet = true
                                            end
                                        end
                                        boxData.FlagWidget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                                    end
                                    boxData._cachedNation = playerNation
                                end
                            end
                            if boxData.FlagSlot then
                                boxData.FlagSlot:SetPosition(FVector2D(centerX, boxTopY - 22.0))
                            end

                            if bRunHeavyTasks or boxData._cachedName == "" then
                                local playerName = isBot and "Bot" or (Pawn.PlayerName or Pawn.PlayerNamePublic or (Pawn.GetPlayerName and Pawn:GetPlayerName()) or "Player")
                                playerName = tostring(playerName)
                                if boxData._cachedName ~= playerName then
                                    boxData.NameWidget:SetText(playerName)
                                    boxData._cachedName = playerName
                                end
                            end
                            boxData.NameSlot:SetPosition(FVector2D(centerX, boxBottomY + 4.0))

                            local distVal = math.floor(LocalPlayer:GetDistanceTo(Pawn) / 100.0)
                            local distStr = tostring(distVal) .. "m"
                            if boxData._cachedDist ~= distStr then
                                boxData.DistWidget:SetText(distStr)
                                boxData._cachedDist = distStr
                            end
                            boxData.DistSlot:SetPosition(FVector2D(centerX, boxBottomY + 20.5))

                            if bUpdateVisCheck or BoxESP._VisCheckCache[KeyStr] == nil then
                                BoxESP._VisCheckCache[KeyStr] = (PC and PC.LineOfSightTo and PC:LineOfSightTo(Pawn)) or false
                            end
                            local isVisible = BoxESP._VisCheckCache[KeyStr]

                            if bRunHeavyTasks or boxData._cachedState == "" then
                                local isKnocked = (Pawn.HealthStatus == 1 or Pawn.bIsKnocked or (Pawn.IsKnocked and Pawn:IsKnocked()))
                                local stateStr = "Open"
                                local slateCol = SlateColorGreen
                                if isKnocked then
                                    stateStr = "Knocked"
                                    slateCol = SlateColorRed
                                elseif not isVisible then
                                    stateStr = "Cover"
                                    slateCol = SlateColorRed
                                end

                                if boxData._cachedState ~= stateStr then
                                    boxData.StateWidget:SetText(stateStr)
                                    boxData.StateWidget:SetColorAndOpacity(slateCol)
                                    boxData._cachedState = stateStr
                                end
                            end
                            boxData.StateSlot:SetPosition(FVector2D(centerX, boxBottomY + 37.0))

                            if BoxESP.bShowLines then
                                local lineColor = isVisible and ColorGreen or ColorRed
                                BoxESP.UpdateSnapLine(KeyStr, centerX, boxTopY, fromX, fromY, lineColor, ParentCanvas)
                            else
                                BoxESP.HideSnapLine(KeyStr)
                            end
                        else
                            BoxESP.HideWidget(boxData)
                            BoxESP.HideSnapLine(KeyStr)
                        end
                    end
                end
            end
        end
    end

    for KeyStr, boxData in pairs(BoxESP.BoxWidgets) do
        if not SeenKeys[KeyStr] then
            BoxESP.HideWidget(boxData)
        end
    end
    for KeyStr, _ in pairs(BoxESP.LineWidgets) do
        if not SeenKeys[KeyStr] then
            BoxESP.HideSnapLine(KeyStr)
            BoxESP._VisCheckCache[KeyStr] = nil
        end
    end

    local counterTopY = fromY - BADGE_HEIGHT - 2
    if counterTopY < 10 then counterTopY = 48 end
    BoxESP.UpdateEnemyCounterDisplay(RealPlayerCount, BotCount, ParentCanvas, fromX, counterTopY)
end

pcall(function()
    local PC = nil
    if slua_GameFrontendHUD and slua_GameFrontendHUD.GetPlayerController then
        PC = slua_GameFrontendHUD:GetPlayerController()
    end
    if IsValid(PC) and PC.AddGameTimer then
        PC:AddGameTimer(0.02, true, BoxESP.UpdateESP)
    end
end)

pcall(function()
    local Ticker = package.loaded["common.time_ticker"] or require("common.time_ticker")
    if Ticker and Ticker.AddTimerLoop then
        Ticker.AddTimerLoop(function()
            BoxESP.UpdateESP()
            return true
        end, 0.02)
    end
end)

_G.BoxESP = BoxESP


-- ============================================================================
-- AIM TOUCH / CUSTOM AIM INTEGRATION
-- Merged from BRPlayerCharacterBase_AimTouch_Fresh.lua.
-- Anti-cheat / integrity-bypass / license code intentionally excluded.
-- ============================================================================
local GameplayData = package.loaded["GameLua.GameCore.Data.GameplayData"]
    or require("GameLua.GameCore.Data.GameplayData")

_G.LexusState.CustomTextData = _G.LexusState.CustomTextData or {
    OuterSpeed = 10, InnerSpeed = 10, OuterRecoil = 0, HRecoil = 0.3, VRecoil = 0.3,
    IpadViewFOV = 120,
    MagicHead = 1.0, MagicBody = 1.0, MagicLegs = 1.0, 
}
--=====================================================
-- ============================================================================
-- AIM TOUCH / CUSTOM AIM CONFIG (fresh integration)
-- ============================================================================
do
    local C = _G.LexusConfig
    C.AimTouchEnable = C.AimTouchEnable or false
    C.AimTouchHipIgKnock = C.AimTouchHipIgKnock or false
    C.AimTouchHipIgBot = C.AimTouchHipIgBot or false
    C.AimTouchSGIgKnock = C.AimTouchSGIgKnock or false
    C.AimTouchSGIgBot = C.AimTouchSGIgBot or false
    C.AimTouchHipVisCheck = C.AimTouchHipVisCheck or false
    C.AimTouchSGVisCheck = C.AimTouchSGVisCheck or false
    C.AimTouchHipfire = C.AimTouchHipfire or false
    C.AimTouchSG = C.AimTouchSG or false
    C.AimTouchSGAutoFire = C.AimTouchSGAutoFire or false
    C.AimTouchScopeAll = C.AimTouchScopeAll or false
    C.AimTouchScopeIgKnock = C.AimTouchScopeIgKnock or false
    C.AimTouchScopeIgBot = C.AimTouchScopeIgBot or false
    C.AimTouchScopeVisCheck = C.AimTouchScopeVisCheck or false
    C.AimTouchScopeSniper = C.AimTouchScopeSniper or false
    C.AimTouchSniperIgKnock = C.AimTouchSniperIgKnock or false
    C.AimTouchSniperIgBot = C.AimTouchSniperIgBot or false
    C.AimTouchSniperVisCheck = C.AimTouchSniperVisCheck or false
    C.AimTouchMortar = C.AimTouchMortar or false
end

do
    local D = _G.LexusState.CustomTextData
    D.AimTouchHipPrio = D.AimTouchHipPrio or 1
    D.AimTouchHipBone = D.AimTouchHipBone or 1
    D.AimTouchHipCond = D.AimTouchHipCond or 1
    D.AimTouchHipSpeed = D.AimTouchHipSpeed or 50
    D.AimTouchHipFOV = D.AimTouchHipFOV or 30
    D.AimTouchHipDist = D.AimTouchHipDist or 250

    D.AimTouchSGPrio = D.AimTouchSGPrio or 1
    D.AimTouchSGBone = D.AimTouchSGBone or 2
    D.AimTouchSGCond = D.AimTouchSGCond or 1
    D.AimTouchSGSpeed = D.AimTouchSGSpeed or 80
    D.AimTouchSGFOV = D.AimTouchSGFOV or 40
    D.AimTouchSGDist = D.AimTouchSGDist or 30

    D.AimTouchScopePrio = D.AimTouchScopePrio or 1
    D.AimTouchScopeBone = D.AimTouchScopeBone or 2
    D.AimTouchScopeCond = D.AimTouchScopeCond or 1
    D.AimTouchScopeSpeed = D.AimTouchScopeSpeed or 40
    D.AimTouchScopeFOV = D.AimTouchScopeFOV or 20
    D.AimTouchScopeDist = D.AimTouchScopeDist or 300
    D.AimTouchScopePred = D.AimTouchScopePred or 0
    D.AimTouchScopeRecoil = D.AimTouchScopeRecoil or 0

    D.AimTouchSniperPrio = D.AimTouchSniperPrio or 1
    D.AimTouchSniperBone = D.AimTouchSniperBone or 1
    D.AimTouchSniperCond = D.AimTouchSniperCond or 2
    D.AimTouchSniperSpeed = D.AimTouchSniperSpeed or 30
    D.AimTouchSniperFOV = D.AimTouchSniperFOV or 20
    D.AimTouchSniperDist = D.AimTouchSniperDist or 400
    D.AimTouchSniperPred = D.AimTouchSniperPred or 0

    D.AimTouchMortarPred = D.AimTouchMortarPred or 0
    D.AimTouchMortarFOV = D.AimTouchMortarFOV or 360
end

-- ============================================================================
-- ============================================================================
-- ============================================================================
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
        if not _G.LexusConfig.AimTouchEnable then return end
        
        local player = GameplayData.GetPlayerCharacter()
        if not slua.isValid(player) then return end
        
        local pc = player:GetPlayerControllerSafety()
        if not slua.isValid(pc) then return end
        
        local isFiring = player.bIsWeaponFiring
        local isADS = player.bIsGunADS
        
        -- CHECK WEAPON & AMMO
        local weapon = player.WeaponManagerComponent and player.WeaponManagerComponent.CurrentWeaponReplicated
        if not weapon and type(player.GetCurrentShootWeapon) == "function" then
            weapon = player:GetCurrentShootWeapon()
        end
        
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

        -- LOGIC NHẢ CÒ SÚNG NẾU MẤT MỤC TIÊU / ĐỊCH CHẾT HOẶC SHOTGUN HẾT ĐẠN
        if _G.LexusState.IsAutoFiring then
            pcall(function()
                player.bIsWeaponFiring = false
                if type(player.SetIsWeaponFiring) == "function" then player:SetIsWeaponFiring(false) end
                if slua.isValid(pc) and type(pc.SetIsWeaponFiring) == "function" then pc:SetIsWeaponFiring(false) end
                local wepMgr = player.WeaponManagerComponent
                if slua.isValid(wepMgr) then wepMgr.bIsWeaponFiring = false end
            end)
            _G.LexusState.IsAutoFiring = false
        end

        -- SHOTGUN HẾT ĐẠN NGƯNG AIM ĐỂ GAME NẠP ĐẠN
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
        
        -- Logic thêm vào: Dự đoán và Bù giật
        local predVal = 0 
        local recoilCompVal = 0 

        -- PHÂN LOẠI CẤU HÌNH THEO TRẠNG THÁI HIỆN TẠI
        if isMortar and _G.LexusConfig.AimTouchMortar then
            local isPlaced = false
            pcall(function()
                if weapon and weapon.MortarState == 2 then isPlaced = true end
            end)
            if not isPlaced then return end

            cond = 2 
            prioMode = 1  
            boneIdx = 4 
            speedVal = 100 
            fovVal = _G.LexusState.CustomTextData.AimTouchMortarFOV or 360 
            maxDistMeters = 2000 
            useVisCheck = false 
            igKnock = false
            igBot = false
            predVal = _G.LexusState.CustomTextData.AimTouchMortarPred or 0 
            
        elseif isShotgun and _G.LexusConfig.AimTouchSG then
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
                predVal = _G.LexusState.CustomTextData.AimTouchSniperPred or 0 -- Lấy giá trị dự đoán Sniper
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
                predVal = _G.LexusState.CustomTextData.AimTouchScopePred or 0 -- Lấy giá trị dự đoán Súng thường
                recoilCompVal = _G.LexusState.CustomTextData.AimTouchScopeRecoil or 0 -- Lấy giá trị bù giật
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
                if slua.isValid(target.Mesh) then
                    target.Mesh.MeshComponentUpdateFlag = 0
                end
            end)
            
            if igKnock and target.HealthStatus == 1 then goto continue end
            
            if igBot then
                local tIsBot = false
                if target.bIsAI == true or target.IsAI == true then tIsBot = true end
                local pState = target.PlayerState
                if slua.isValid(pState) and (pState.bIsABot or pState.bIsBot) then tIsBot = true end
                if tIsBot then goto continue end
            end
            
            -- [FIX TỤT FPS]: Khóa tia Raycast check tường, chỉ quét 0.2s một lần (Đủ mượt mà không cháy CPU)
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
        
        local tVelocity = nil
        pcall(function()
            if type(bestTarget.GetVelocity) == "function" then
                tVelocity = bestTarget:GetVelocity()
            end
        end)

        -- LOGIC ĐOÁN HƯỚNG SÚNG CỐI
        if isMortar and _G.LexusConfig.AimTouchMortar and predVal > 0 then
            pcall(function()
                if tVelocity and (tVelocity.X ~= 0 or tVelocity.Y ~= 0) then
                    local approxDist = player:GetDistanceTo(bestTarget) / 100.0
                    local approxToF = approxDist / 100.0 
                    local predScale = predVal / 50.0
                    finalBonePos.X = finalBonePos.X + (tVelocity.X * approxToF * predScale)
                    finalBonePos.Y = finalBonePos.Y + (tVelocity.Y * approxToF * predScale)
                end
            end)
        end

        -- LOGIC 1: PREDICTION (SÚNG THƯỜNG)
        if not isMortar and predVal > 0 then
            pcall(function()
                -- Nếu địch đang di chuyển
                if tVelocity and (tVelocity.X ~= 0 or tVelocity.Y ~= 0) then
                    local distToEnemy = player:GetDistanceTo(bestTarget) / 100.0 -- Khoảng cách mét
                    
                    -- Tính toán thời gian đạn bay (Time-Of-Flight) tỉ lệ thuận với khoảng cách và biến truyền vào
                    -- Hệ số 800.0 đại diện cho tốc độ đạn rơi giả lập, 50.0 là mức trung bình slider
                    local ToF = (distToEnemy / 800.0) * (predVal / 50.0) 
                    
                    -- Dịch chuyển toạ độ Aim lên trước hướng chạy
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
        
        -- [BẮT ĐẦU FIX] Bù trừ chênh lệch Camera khi mở ống ngắm (ADS) để không bị lệch tâm
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
        -- [KẾT THÚC FIX]

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
        
        -- LOGIC 2: RECOIL COMPENSATION (ÉP TÂM / BÙ GIẬT TRÁNH BẮN QUÁ ĐẦU)
        if recoilCompVal > 0 and isFiring then
            local pullDownForce = (recoilCompVal / 50.0) * 1.5 
            finalPitch = finalPitch - pullDownForce
        end
        
        -- LOGIC TÍNH TOÁN GÓC BẮN THẬT SỰ CHO SÚNG CỐI
        if isMortar and _G.LexusConfig.AimTouchMortar then
            local targetPos = { X = finalBonePos.X, Y = finalBonePos.Y, Z = finalBonePos.Z }
            local launchPos = camLoc
            pcall(function()
                if player.K2_GetActorLocation then
                    local pLoc = player:K2_GetActorLocation()
                    if pLoc then 
                        launchPos = { X = pLoc.X, Y = pLoc.Y, Z = pLoc.Z + 50 } 
                    end
                end
            end)

            local function CalcMortarTrajectory(V, G, tX, tY, tZ)
                local mDx = math.sqrt((tX - launchPos.X)^2 + (tY - launchPos.Y)^2) - 80 
                if mDx < 500 then mDx = 500 end 
                local mDy = tZ - launchPos.Z
                
                local minVSq = G * (mDy + math.sqrt(mDx*mDx + mDy*mDy))
                if (V * V) < minVSq then
                    V = math.sqrt(minVSq) + 100 
                end

                local v2 = V * V
                local root = v2*v2 - G*(G*mDx*mDx + 2*mDy*v2)
                
                if root >= 0 then
                    local angleRad = math.atan((v2 + math.sqrt(root)) / (G * mDx))
                    local deg = math.deg(angleRad)
                    if deg >= 35 and deg <= 89.5 then 
                        return true, deg, mDx / (V * math.cos(angleRad)), mDx
                    end
                end
                return false, 45, 0, mDx
            end

            local vNear, gNear = 9070, 980 * 2.8   
            local vFar, gFar = 12520, 980 * 4.0    
            local vUltra, gUltra = 16800, 980 * 4.5 
            
            local isValid, physAngle, ToF, finalDx = false, 45, 0, 0
            
            local okNear, angNear, tofNear, dxN = CalcMortarTrajectory(vNear, gNear, targetPos.X, targetPos.Y, targetPos.Z)
            local okFar, angFar, tofFar, dxF = CalcMortarTrajectory(vFar, gFar, targetPos.X, targetPos.Y, targetPos.Z)
            local okUltra, angUltra, tofUltra, dxU = CalcMortarTrajectory(vUltra, gUltra, targetPos.X, targetPos.Y, targetPos.Z)

            if okNear and dxN <= 25000 then
                isValid, physAngle, ToF, finalDx = okNear, angNear, tofNear, dxN
            elseif okFar and dxF <= 40000 then
                isValid, physAngle, ToF, finalDx = okFar, angFar, tofFar, dxF
            elseif okUltra then
                isValid, physAngle, ToF, finalDx = okUltra, angUltra, tofUltra, dxU
            elseif okNear then
                isValid, physAngle, ToF, finalDx = okNear, angNear, tofNear, dxN
            end

            local targetCameraPitch = ((physAngle - 45) / 43.0) * 90.0 - 60.0
            local targetCameraYaw = rot.Yaw

            local deltaPitchMortar = targetCameraPitch - currentRot.Pitch
            local deltaYawMortar = targetCameraYaw - currentRot.Yaw

            if deltaPitchMortar > 180 then deltaPitchMortar = deltaPitchMortar - 360 end
            if deltaPitchMortar < -180 then deltaPitchMortar = deltaPitchMortar + 360 end
            if deltaYawMortar > 180 then deltaYawMortar = deltaYawMortar - 360 end
            if deltaYawMortar < -180 then deltaYawMortar = deltaYawMortar + 360 end
            
            finalPitch = currentRot.Pitch + (deltaPitchMortar * smoothFactor)
            finalYaw = currentRot.Yaw + (deltaYawMortar * smoothFactor)
        end

        local finalRot = { Pitch = finalPitch, Yaw = finalYaw, Roll = 0 }
        pc:SetControlRotation(finalRot, "AimTouch")
        pc:SetControlRotation(finalRot, "AimTouch")

        if isShotgun and _G.LexusConfig.AimTouchSGAutoFire then
            pcall(function()
                local distToTarget = player:GetDistanceTo(bestTarget) / 100
                if distToTarget <= maxDistMeters then
                    player.bIsWeaponFiring = true
                    if type(player.SetIsWeaponFiring) == "function" then
                        player:SetIsWeaponFiring(true)
                    end
                    if slua.isValid(pc) and type(pc.SetIsWeaponFiring) == "function" then
                        pc:SetIsWeaponFiring(true)
                    end
                    local wepMgr = player.WeaponManagerComponent
                    if slua.isValid(wepMgr) then
                        wepMgr.bIsWeaponFiring = true
                    end
                    local currentWep = player:GetCurrentWeapon()
                    if slua.isValid(currentWep) and type(currentWep.StartFire) == "function" then
                        currentWep:StartFire()
                    end
                    _G.LexusState.IsAutoFiring = true
                end
            end)
        end
    end)
end


-- AimTouch tick: kept separate from the existing ESP/maintenance timer.
pcall(function()
    local PC = GameplayData.GetPlayerController and GameplayData.GetPlayerController()
    if PC and PC.AddGameTimer then
        PC:AddGameTimer(0.05, true, function()
            pcall(_G.AimTouch)
        end)
    else
        local Ticker = package.loaded["common.time_ticker"] or require("common.time_ticker")
        if Ticker and Ticker.AddTimerLoop then
            Ticker.AddTimerLoop(function()
                pcall(_G.AimTouch)
                return true
            end, 0.05)
        end
    end
end)


    local okAM, AM = pcall(require, "client.slua.umg.NewSetting.Item.AliasMap")
    if okAM and AM then
        local function sw(key, text, getf, setf)
            return {
                Key = key, UI = AM.Switcher, Text = text,
                GetFunc = getf, SetFunc = setf
            }
        end

        local function slider(key, text, minv, maxv, getf, setf)
            return {
                Key = key, UI = AM.Slider, Text = text,
                MinValue = minv, MaxValue = maxv,
                min = minv, max = maxv,
                GetFunc = getf, SetFunc = setf
            }
        end

        -- This is the complete page shown after selecting AIMBOT V2.
        _G.LexusAimTouchMenu = {
            {Key="AT_Enable", UI=AM.Switcher, Text="Aimbot V2 (MASTER)",
                GetFunc=function() return _G.LexusConfig.AimTouchEnable end,
                SetFunc=function(_,v) _G.LexusConfig.AimTouchEnable=v return true end},

            {Key="AT_Hip", UI=AM.Switcher, Text="Hipfire Aimbot",
                GetFunc=function() return _G.LexusConfig.AimTouchHipfire end,
                SetFunc=function(_,v) _G.LexusConfig.AimTouchHipfire=v return true end},
            sw("AT_Hip_Knock","Ignore Knocked",
                function() return _G.LexusConfig.AimTouchHipIgKnock end,
                function(_,v) _G.LexusConfig.AimTouchHipIgKnock=v return true end),
            sw("AT_Hip_Bot","Ignore Bots",
                function() return _G.LexusConfig.AimTouchHipIgBot end,
                function(_,v) _G.LexusConfig.AimTouchHipIgBot=v return true end),
            sw("AT_Hip_Vis","Visibility Check",
                function() return _G.LexusConfig.AimTouchHipVisCheck end,
                function(_,v) _G.LexusConfig.AimTouchHipVisCheck=v return true end),
            slider("AT_Hip_Bone","Bone (1-4)",1,4,
                function() return _G.LexusState.CustomTextData.AimTouchHipBone end,
                function(_,v) _G.LexusState.CustomTextData.AimTouchHipBone=math.floor(v+0.5) return true end),
            slider("AT_Hip_Spd","Smoothness (1-100)",1,100,
                function() return _G.LexusState.CustomTextData.AimTouchHipSpeed end,
                function(_,v) _G.LexusState.CustomTextData.AimTouchHipSpeed=v return true end),
            slider("AT_Hip_FOV","FOV (1-100)",1,100,
                function() return _G.LexusState.CustomTextData.AimTouchHipFOV end,
                function(_,v) _G.LexusState.CustomTextData.AimTouchHipFOV=v return true end),
            slider("AT_Hip_Dist","Distance (5-500m)",1,100,
                function() return math.floor((_G.LexusState.CustomTextData.AimTouchHipDist or 250)/5) end,
                function(_,v) _G.LexusState.CustomTextData.AimTouchHipDist=v*5 return true end),

            {Key="AT_SG", UI=AM.Switcher, Text="Shotgun Aimbot",
                GetFunc=function() return _G.LexusConfig.AimTouchSG end,
                SetFunc=function(_,v) _G.LexusConfig.AimTouchSG=v return true end},
            sw("AT_SG_Fire","Auto Fire",
                function() return _G.LexusConfig.AimTouchSGAutoFire end,
                function(_,v) _G.LexusConfig.AimTouchSGAutoFire=v return true end),
            sw("AT_SG_Knock","Ignore Knocked",
                function() return _G.LexusConfig.AimTouchSGIgKnock end,
                function(_,v) _G.LexusConfig.AimTouchSGIgKnock=v return true end),
            sw("AT_SG_Bot","Ignore Bots",
                function() return _G.LexusConfig.AimTouchSGIgBot end,
                function(_,v) _G.LexusConfig.AimTouchSGIgBot=v return true end),
            sw("AT_SG_Vis","Visibility Check",
                function() return _G.LexusConfig.AimTouchSGVisCheck end,
                function(_,v) _G.LexusConfig.AimTouchSGVisCheck=v return true end),
            slider("AT_SG_Bone","Bone (1-4)",1,4,
                function() return _G.LexusState.CustomTextData.AimTouchSGBone end,
                function(_,v) _G.LexusState.CustomTextData.AimTouchSGBone=math.floor(v+0.5) return true end),
            slider("AT_SG_Spd","Smoothness (1-100)",1,100,
                function() return _G.LexusState.CustomTextData.AimTouchSGSpeed end,
                function(_,v) _G.LexusState.CustomTextData.AimTouchSGSpeed=v return true end),
            slider("AT_SG_FOV","FOV (1-100)",1,100,
                function() return _G.LexusState.CustomTextData.AimTouchSGFOV end,
                function(_,v) _G.LexusState.CustomTextData.AimTouchSGFOV=v return true end),
            slider("AT_SG_Dist","Distance (1-100m)",1,100,
                function() return _G.LexusState.CustomTextData.AimTouchSGDist end,
                function(_,v) _G.LexusState.CustomTextData.AimTouchSGDist=v return true end),

            {Key="AT_Scope", UI=AM.Switcher, Text="Scope Aimbot",
                GetFunc=function() return _G.LexusConfig.AimTouchScopeAll end,
                SetFunc=function(_,v) _G.LexusConfig.AimTouchScopeAll=v return true end},
            sw("AT_Scope_Knock","Ignore Knocked",
                function() return _G.LexusConfig.AimTouchScopeIgKnock end,
                function(_,v) _G.LexusConfig.AimTouchScopeIgKnock=v return true end),
            sw("AT_Scope_Bot","Ignore Bots",
                function() return _G.LexusConfig.AimTouchScopeIgBot end,
                function(_,v) _G.LexusConfig.AimTouchScopeIgBot=v return true end),
            sw("AT_Scope_Vis","Visibility Check",
                function() return _G.LexusConfig.AimTouchScopeVisCheck end,
                function(_,v) _G.LexusConfig.AimTouchScopeVisCheck=v return true end),
            slider("AT_Scope_Bone","Bone (1-4)",1,4,
                function() return _G.LexusState.CustomTextData.AimTouchScopeBone end,
                function(_,v) _G.LexusState.CustomTextData.AimTouchScopeBone=math.floor(v+0.5) return true end),
            slider("AT_Scope_Spd","Smoothness (1-100)",1,100,
                function() return _G.LexusState.CustomTextData.AimTouchScopeSpeed end,
                function(_,v) _G.LexusState.CustomTextData.AimTouchScopeSpeed=v return true end),
            slider("AT_Scope_FOV","FOV (1-100)",1,100,
                function() return _G.LexusState.CustomTextData.AimTouchScopeFOV end,
                function(_,v) _G.LexusState.CustomTextData.AimTouchScopeFOV=v return true end),
            slider("AT_Scope_Dist","Distance (5-500m)",1,100,
                function() return math.floor((_G.LexusState.CustomTextData.AimTouchScopeDist or 300)/5) end,
                function(_,v) _G.LexusState.CustomTextData.AimTouchScopeDist=v*5 return true end),
            slider("AT_Scope_Pred","Prediction (0-100)",0,100,
                function() return _G.LexusState.CustomTextData.AimTouchScopePred end,
                function(_,v) _G.LexusState.CustomTextData.AimTouchScopePred=v return true end),
            slider("AT_Scope_Recoil","Recoil Comp (0-50)",0,50,
                function() return _G.LexusState.CustomTextData.AimTouchScopeRecoil end,
                function(_,v) _G.LexusState.CustomTextData.AimTouchScopeRecoil=v return true end),

            {Key="AT_Sniper", UI=AM.Switcher, Text="Sniper Aimbot",
                GetFunc=function() return _G.LexusConfig.AimTouchScopeSniper end,
                SetFunc=function(_,v) _G.LexusConfig.AimTouchScopeSniper=v return true end},
            sw("AT_Sniper_Knock","Ignore Knocked",
                function() return _G.LexusConfig.AimTouchSniperIgKnock end,
                function(_,v) _G.LexusConfig.AimTouchSniperIgKnock=v return true end),
            sw("AT_Sniper_Bot","Ignore Bots",
                function() return _G.LexusConfig.AimTouchSniperIgBot end,
                function(_,v) _G.LexusConfig.AimTouchSniperIgBot=v return true end),
            sw("AT_Sniper_Vis","Visibility Check",
                function() return _G.LexusConfig.AimTouchSniperVisCheck end,
                function(_,v) _G.LexusConfig.AimTouchSniperVisCheck=v return true end),
            slider("AT_Sniper_Bone","Bone (1-4)",1,4,
                function() return _G.LexusState.CustomTextData.AimTouchSniperBone end,
                function(_,v) _G.LexusState.CustomTextData.AimTouchSniperBone=math.floor(v+0.5) return true end),
            slider("AT_Sniper_Spd","Smoothness (1-100)",1,100,
                function() return _G.LexusState.CustomTextData.AimTouchSniperSpeed end,
                function(_,v) _G.LexusState.CustomTextData.AimTouchSniperSpeed=v return true end),
            slider("AT_Sniper_FOV","FOV (1-100)",1,100,
                function() return _G.LexusState.CustomTextData.AimTouchSniperFOV end,
                function(_,v) _G.LexusState.CustomTextData.AimTouchSniperFOV=v return true end),
            slider("AT_Sniper_Dist","Distance (5-500m)",1,100,
                function() return math.floor((_G.LexusState.CustomTextData.AimTouchSniperDist or 400)/5) end,
                function(_,v) _G.LexusState.CustomTextData.AimTouchSniperDist=v*5 return true end),
            slider("AT_Sniper_Pred","Prediction (0-100)",0,100,
                function() return _G.LexusState.CustomTextData.AimTouchSniperPred end,
                function(_,v) _G.LexusState.CustomTextData.AimTouchSniperPred=v return true end),

            {Key="AT_Mortar", UI=AM.Switcher, Text="Mortar Aimbot",
                GetFunc=function() return _G.LexusConfig.AimTouchMortar end,
                SetFunc=function(_,v) _G.LexusConfig.AimTouchMortar=v return true end},
            slider("AT_Mortar_FOV","FOV (1-360)",1,360,
                function() return _G.LexusState.CustomTextData.AimTouchMortarFOV end,
                function(_,v) _G.LexusState.CustomTextData.AimTouchMortarFOV=v return true end),
            slider("AT_Mortar_Pred","Prediction (0-100)",0,100,
                function() return _G.LexusState.CustomTextData.AimTouchMortarPred end,
                function(_,v) _G.LexusState.CustomTextData.AimTouchMortarPred=v return true end),
        }

        -- Category descriptor.  The Settings UI hook below inserts this as a
        -- selectable "AIMBOT V2" page rather than leaving the controls orphaned.
        _G.LexusAimTouchSettingsCategory = {
            Key = "Cat_AimbotV2",
            Text = "AIMBOT V2",
            Stack = _G.LexusAimTouchMenu,
        }

        -- Keep the page registration isolated so failure of the UI API does
        -- not stop the rest of the class from loading.
        pcall(function()
            if type(_G.UIManager) ~= "table" or type(_G.UIManager.ShowUI) ~= "function" then return end
            if _G.__LexusAimTouchSettingsHooked then return end
            local oldShow = _G.UIManager.ShowUI
            _G.UIManager.ShowUI = function(cfg, ...)
                local args = {...}
                local n = select('#', ...)
                if cfg and cfg.keyName and string.find(string.lower(tostring(cfg.keyName)), "setting_main", 1, true) then
                    local categories = args[1]
                    if type(categories) == "table" then
                        local exists = false
                        for _, item in ipairs(categories) do
                            if type(item) == "table" and item.Key == "Cat_AimbotV2" then
                                exists = true
                                break
                            end
                        end
                        if not exists then
                            table.insert(categories, 1, _G.LexusAimTouchSettingsCategory)
                        end
                    end
                end
                local unpackFn = table.unpack or unpack
                return oldShow(cfg, unpackFn(args, 1, n))
            end
            _G.__LexusAimTouchSettingsHooked = true
        end)

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
  { CommonBornlandTransformFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.HeroPropFeature.CommonBornlandTransformFeature" },
  { ParachuteFormation = "GameLua.Mod.BaseMod.GamePlay.Feature.ParachuteFormationFeature" },
  { SpiderSenseFootprintFeature = "GameLua.Mod.Library.GamePlay.Feature.SpiderSenseFootprintFeature" },
  { GeneralShowSpotFeature = "GameLua.Mod.BRMod.Gameplay.Feature.PlayerCharacterGeneralShowSpotFeature" }
}, "BRPlayerCharacterBase")
