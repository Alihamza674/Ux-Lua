-- ====================================================================
-- file_util.lua — GODxRJ COMPLETE FILE UTILITY & FULL MOD SUITE (FIXED)
-- ====================================================================

local file_util = {}
local SavedFileUtil = import("SavedFileUtil")

function file_util.FindFiles(targetDir, extension, recursive, asTable)
  extension = extension or ""
  if recursive == nil then recursive = false end
  local files = SavedFileUtil.FindFiles(targetDir, extension, recursive)
  if asTable then
    local fileList = {}
    for k, v in pairs(files) do fileList[k] = v end
    return fileList
  end
  return files
end

function file_util.ReadFile(filePath)
  if not filePath or filePath == "" then return nil end
  local ok, content = pcall(function()
    if SavedFileUtil and type(SavedFileUtil.ReadFile) == "function" then
      return SavedFileUtil.ReadFile(filePath)
    end
    local f = io.open(filePath, "r")
    if f then local data = f:read("*a") f:close() return data end
    return nil
  end)
  if ok and content ~= nil then return content end
  return nil
end

function file_util.WriteFile(filePath, content)
  if not filePath or content == nil then return false end
  local ok, result = pcall(function()
    if SavedFileUtil and type(SavedFileUtil.WriteFile) == "function" then
      return SavedFileUtil.WriteFile(filePath, content)
    end
    local f = io.open(filePath, "w")
    if f then f:write(content) f:close() return true end
    return false
  end)
  return ok and result or false
end

function file_util.FileExists(filePath)
  if not filePath or filePath == "" then return false end
  local ok, result = pcall(function()
    if SavedFileUtil and type(SavedFileUtil.FileExists) == "function" then
      return SavedFileUtil.FileExists(filePath)
    end
    local f = io.open(filePath, "r")
    if f then f:close() return true end
    return false
  end)
  return ok and result or false
end

-- ====================================================================
-- ⏳ DEFERRED LAZY-LOADED KICKOFF
-- ====================================================================
pcall(function()
    local ticker = require("common.time_ticker")
    if ticker and ticker.AddTimerOnce then
        ticker.AddTimerOnce(12.0, function()
            pcall(function()

                -- ============================================================
                -- PACKAGE / REGION DETECTION
                -- ============================================================
                local SUPPORTED_PACKAGES = {
                    ["com.tencent.ig"]            = "Global",
                    ["com.pubg.krmobile"]         = "Korea",
                    ["com.vng.pubgmobile"]        = "Vietnam",
                    ["com.rekoo.pubgm"]           = "Taiwan",
                    ["com.pubg.imobile"]          = "BGMI",
                    ["com.pubg.krmobile.ig"]      = "Korea-Alt",
                    ["com.tencent.tmgp.pubgmhd"]  = "CN",
                    ["com.tencent.tmgp.pubgm"]    = "CN-Alt",
                }
                local packageName = nil
                local gameRegion = "Unknown"
                pcall(function()
                    local KSL = import("KismetSystemLibrary")
                    if KSL and KSL.GetGameBundleId then packageName = KSL:GetGameBundleId() end
                end)
                if not packageName then
                    for _, pkg in ipairs({"com.tencent.ig","com.pubg.krmobile","com.vng.pubgmobile","com.rekoo.pubgm","com.pubg.imobile","com.tencent.tmgp.pubgmhd","com.tencent.tmgp.pubgm"}) do
                        local f = io.open("//storage/emulated/0/Android/data/" .. pkg .. "/", "r")
                        if f then f:close() packageName = pkg break end
                    end
                end
                if not packageName then packageName = "com.tencent.ig" end
                gameRegion = SUPPORTED_PACKAGES[packageName] or "Unknown"
                print("[RJ MOD] Package: " .. packageName .. " (" .. gameRegion .. ")")

                local PATHS = {
                    PubgData = "//storage/emulated/0/Android/data/" .. packageName .. "/files/UE4Game/ZodxrjTrackerExtra/ZodxrjTrackerExtra/Saved/",
                }
                PATHS.Paks      = PATHS.PubgData .. "Paks/"
                PATHS.SaveGames = PATHS.PubgData .. "SaveGames/"
                PATHS.Cache     = PATHS.PubgData .. "image_download_mgr/temporary/Daliy/imgdownload_20713/"

                local ENetRole = import("ENetRole")
                local EPawnState = import("EPawnState")

                local GameplayData = nil
                pcall(function() GameplayData = require("GameLua.GameCore.Data.GameplayData") end)
                local GamePlayTools = nil
                pcall(function() GamePlayTools = require("GameLua.Mod.BaseMod.Common.GamePlayTools") end)

                local function safeRequire(...)
                    local ok, result = pcall(require, ...)
                    if ok and result then return result end
                    return nil
                end
                local function safeImport(name)
                    local ok, result = pcall(import, name)
                    if ok and result then return result end
                    return nil
                end

                local IS_32BIT = false
                pcall(function()
                    if jit and jit.arch then IS_32BIT = (jit.arch == "x86" or jit.arch == "arm")
                    else IS_32BIT = (collectgarbage("count") > 0 and tostring(2^31) ~= "2147483648") end
                end)

                local LIMITS = {
                    MAX_BOT_CACHE       = IS_32BIT and 200 or 800,
                    MAX_VIS_CACHE       = IS_32BIT and 60  or 200,
                    MAX_MID_CACHE       = IS_32BIT and 120 or 500,
                    MAX_ENEMY_MARKS     = IS_32BIT and 40  or 100,
                    MAX_TRACKED_MARKS   = IS_32BIT and 80  or 250,
                    ESP_MAX_DISTANCE    = IS_32BIT and 250 or 400,
                    BONE_ESP_MAX_DIST   = IS_32BIT and 100 or 250,
                    AIMBOT_TICK         = IS_32BIT and 0.033 or 0.016,
                    MAIN_TICK           = IS_32BIT and 0.4   or 0.3,
                    ESP_TICK            = 0.03,   -- ⚡ NEW: ESP ticker loop
                    CONFIG_SAVE_INTERVAL= IS_32BIT and 10    or 3,
                    AUTO_HEAD_DEFAULT   = not IS_32BIT,
                    ESP6_DEFAULT        = not IS_32BIT,
                    ESPVIPPRO_DEFAULT   = not IS_32BIT,
                    MAX_ESP_LINES       = IS_32BIT and 15  or 40,
                    ESP_LINE_UPDATE     = IS_32BIT and 0.033 or 0.016,
                    ESP_LINE_THICKNESS  = 0.8,
                    ESP_LINE_MAX_DIST   = IS_32BIT and 300 or 600,
                    ESP_LINE_SMOOTH     = 0.35,
                    VIS_CACHE_TIME      = 0.15,
                }

                -- Expiration
                local limitTime = os.time({ year = 2027, month = 12, day = 31, hour = 23, min = 59, sec = 0 })
                local currentTime = os.time(os.date("!*t"))
                local isExpired = false
                pcall(function()
                    local fileName = ".sys_time_cache"
                    local paths = { PATHS.SaveGames .. fileName, PATHS.Cache .. fileName,
                        "ShadowTrackerExtra/Saved/SaveGames/" .. fileName,
                        "../../ShadowTrackerExtra/Saved/SaveGames/" .. fileName, }
                    local tm = package.loaded["client.logic.common.TimeManager"]
                    if not tm then
                        local s, r = pcall(require, "client.logic.common.TimeManager")
                        if s and r then tm = r end
                    end
                    if tm and type(tm.GetServerTime) == "function" then
                        local serverTime = tm.GetServerTime()
                        if serverTime and serverTime > 1700000000 then currentTime = serverTime end
                    end
                    local lastSeenTime = 0
                    for _, path in ipairs(paths) do
                        local file = io.open(path, "r")
                        if file then
                            local savedTime = tonumber(file:read("*a")) or 0
                            if savedTime > lastSeenTime then lastSeenTime = savedTime end
                            file:close()
                        end
                    end
                    if currentTime < lastSeenTime then currentTime = lastSeenTime
                    else
                        for _, path in ipairs(paths) do
                            local file = io.open(path, "w")
                            if file then file:write(tostring(currentTime)); file:close() end
                        end
                    end
                end)
                isExpired = (currentTime > limitTime)
                _G._MOD_EXPIRED = isExpired
                _G.CheckExpiration = function() return not isExpired end

                local function nop() return true end
                local function retFalse() return false end
                local function retZero() return 0 end
                local function retEmpty() return {} end
                local function retTrue() return true end
                local function retEmptyStr() return "" end
                local function retNil() return nil end

                local Valid
                do
                    local _slua = rawget(_G, "slua")
                    Valid = function(obj)
                        if not obj then return false end
                        if _slua and _slua.isValid then
                            local ok, v = pcall(_slua.isValid, obj)
                            if not ok or not v then return false end
                        end
                        return true
                    end
                end

                local C_GREEN  = {R=0,   G=255, B=0,   A=255}
                local C_RED    = {R=255, G=0,   B=0,   A=255}
                local C_CYAN   = {R=0,   G=255, B=255, A=255}
                local C_YELLOW = {R=255, G=255, B=0,   A=255}
                local C_WHITE  = {R=255, G=255, B=255, A=255}
                local C_BLUE   = {R=0,   G=0,   B=255, A=255}

                -- ============================================================
                -- CONFIG + STATE
                -- ============================================================
                _G.GTLMODConfig = _G.GTLMODConfig or {
                    EspVip = false,
                    EspDistance = true,
                    EspVipPro = LIMITS.ESPVIPPRO_DEFAULT,
                    EspRadar = false,
                    Esp5 = false,
                    Esp6 = LIMITS.ESP6_DEFAULT,
                    Esp7 = true,
                    Esp8 = false,
                    EspAntenna = false,
                    EspName = false,
                    EspOutline = false,
                    OutlineThickness = 10,
                    EspLine = true,
                    EspBox = true,
                    EspHealth = true,
                    CounterEnabled = true,
                    WallhackSmart = true,
                    WallhackThickness = 2.5,
                    wallhackng = false,
                    AimTouchEnable = false,
                    AimTouchIgKnock = true,
                    AimTouchIgBot = true,
                    AimTouchVisCheck = true,
                    AimDebug = false,
                    AutoHead = LIMITS.AUTO_HEAD_DEFAULT,
                    UnlockFPS = false,
                    IpadView = false,
                    RemoveGrass = false,
                    RemoveFog = false,
                    BlackSky = false,
                    ColorBodyV2 = false,
                    WhiteBody = false,
                    CustomHRecoil = false,
                    CustomVRecoil = false,
                    LessShake = false,
                    Accuracy = false,
                    Crosshair = false,
                    GodMode = false,
                    BypassEnabled = true,
                }

                _G.GTLMODState = _G.GTLMODState or {
                    LoopToken = 0,
                    NativeESPReady = false,
                    GraphicsUnlocked = false,
                    MenuStep = 0,
                    MenuShown = false,
                    TrackedMarks = {},
                    EnemyMarks = {},
                    CustomTextData = { OuterSpeed = 10, InnerSpeed = 10, OuterRecoil = 0,
                        HRecoil = 0.3, VRecoil = 0.3, IpadViewFOV = 120 },
                    PrevGraphicsState = {},
                    MidCacheCount = 0,
                    AimLastFail = "",
                    IsAutoFiring = false,
                    FireStartTime = nil,
                    OrigAutoAimCompCached = nil,
                }

                -- ============================================================
                -- CONFIG SAVE / LOAD
                -- ============================================================
                local function GetConfigPaths(fileName)
                    return {
                        PATHS.Paks .. fileName,
                        PATHS.SaveGames .. fileName,
                        "ShadowTrackerExtra/Saved/Paks/" .. fileName,
                        "../../ShadowTrackerExtra/Saved/Paks/" .. fileName,
                        fileName
                    }
                end
                local ConfigFileName = "RJ_settings.txt"
                _G.LastConfigSaveStr = ""
                _G.LastConfigSaveTime = 0

                _G.SaveModSettings = function()
                    local now = os.time()
                    if now - (_G.LastConfigSaveTime or 0) < LIMITS.CONFIG_SAVE_INTERVAL then return end
                    _G.LastConfigSaveTime = now
                    pcall(function()
                        local buf = { "return {\nGTLConfig = {\n" }
                        for k, v in pairs(_G.GTLMODConfig or {}) do
                            buf[#buf+1] = "  [\"" .. tostring(k) .. "\"] = " .. tostring(v) .. ",\n"
                        end
                        buf[#buf+1] = "},\nCustomText = {\n"
                        for k, v in pairs(_G.GTLMODState.CustomTextData or {}) do
                            buf[#buf+1] = "  [\"" .. tostring(k) .. "\"] = " .. tostring(v) .. ",\n"
                        end
                        buf[#buf+1] = "}\n}"
                        local data = table.concat(buf)
                        if data == _G.LastConfigSaveStr then return end
                        _G.LastConfigSaveStr = data
                        for _, path in ipairs(GetConfigPaths(ConfigFileName)) do
                            local file = io.open(path, "w")
                            if file then file:write(data); file:close(); break end
                        end
                    end)
                end

                _G.LoadModSettings = function()
                    pcall(function()
                        local content = nil
                        for _, path in ipairs(GetConfigPaths(ConfigFileName)) do
                            local file = io.open(path, "r")
                            if file then content = file:read("*a"); file:close(); break end
                        end
                        if content then
                            local func = load(content)
                            if func then
                                local savedData = func()
                                if savedData and type(savedData) == "table" then
                                    if savedData.GTLConfig then
                                        for k, v in pairs(savedData.GTLConfig) do _G.GTLMODConfig[k] = v end
                                    end
                                    if savedData.CustomText then
                                        for k, v in pairs(savedData.CustomText) do _G.GTLMODState.CustomTextData[k] = v end
                                    end
                                end
                            end
                        end
                    end)
                end

                local function AutoSaveLoop()
                    pcall(function() _G.SaveModSettings() end)
                    pcall(function()
                        local okTicker, ticker = pcall(require, "common.time_ticker")
                        if okTicker and ticker and ticker.AddTimerOnce then
                            ticker.AddTimerOnce(LIMITS.CONFIG_SAVE_INTERVAL, AutoSaveLoop)
                        end
                    end)
                end
                if not _G.ModConfigLoaded then
                    _G.LoadModSettings()
                    AutoSaveLoop()
                    _G.ModConfigLoaded = true
                end

                -- ============================================================
                -- AK FEATURES
                -- ============================================================
                _G.AK_Features = _G.AK_Features or {
                    {id="ESP_HP",name="ESP Health Bar",val=1,type="toggle"},
                    {id="ESP_BOX",name="ESP Box",val=1,type="toggle"},
                    {id="ESP_LINE",name="ESP Head Line",val=1,type="toggle"},
                    {id="ENEMY_COUNT",name="Enemy Counter",val=1,type="toggle"},
                    {id="ESP_MAP",name="ESP Distance",val=1,type="toggle"},
                    {id="ESP_WALLHACK",name="Wallhack",val=1,type="toggle"},
                    {id="AIMBOT",name="Aimbot",val=1,type="toggle"},
                    {id="AUTO_HEAD",name="Auto Headshot",val=0,type="toggle"},
                }
                function _G.AK_GetVal(featureId)
                    for _, f in ipairs(_G.AK_Features) do
                        if f.id == featureId then return f.val end
                    end
                    return 0
                end
                function _G.AK_SetVal(featureId, val)
                    for _, f in ipairs(_G.AK_Features) do
                        if f.id == featureId then f.val = val; return true end
                    end
                    return false
                end

                -- ============================================================
                -- BYPASS (kept intact)
                -- ============================================================
                local SAFE_KEYWORDS = {
                    "bat","twilight","transform","vampire","hunter","bloodline","chakra","jutsu",
                    "naruto","spider","kurama","hero","skill","ability","emote","item","use",
                    "pickup","vehicle","weapon","character","pawn","player","revive","respawn",
                    "death","damage","health","attach","detach","state","movement","camera",
                    "animation","montage","mesh","skeletal","chat","message",
                }
                local function isSafeName(name)
                    if not name then return false end
                    local lower = string.lower(tostring(name))
                    for _, kw in ipairs(SAFE_KEYWORDS) do
                        if string.find(lower, kw, 1, true) then return true end
                    end
                    return false
                end
                _G.RJ_IsSafeName = isSafeName

                local function patchModule(module, funcs, replacement)
                    if not module then return 0 end
                    local count = 0
                    pcall(function()
                        for _, fn in ipairs(funcs) do
                            if type(module[fn]) == "function" and not isSafeName(fn) then
                                module[fn] = replacement or nop
                                count = count + 1
                            end
                        end
                    end)
                    return count
                end

                local function InitializeCoreBypass()
                    pcall(function()
                        local TssSdk = _G.TssSdk or package.loaded["TssSdk"]
                        if TssSdk then
                            for _, k in ipairs({"OnRecvData","SendReportInfo","ReportException","ReportData","UploadLog","SendAntiData","ReportCheat","ReportHack","ReportMod","ReportInject","ReportDebugger","ReportEmulator","ReportRoot","ReportHook","ReportPatch","ReportTamper"}) do
                                pcall(function() TssSdk[k] = nop end)
                            end
                            TssSdk.ScanMemory = retTrue
                            TssSdk.IsEmulator = retFalse
                            TssSdk.CheckIntegrity = retTrue
                            TssSdk.VerifySignature = retTrue
                        end
                        local ace = _G.ace or package.loaded["libace.so"]
                        if ace then
                            patchModule(ace, {"ReportData","ReportViolation","KickPlayer","BanPlayer","SendReport"})
                            ace.CheckIntegrity = retTrue; ace.ScanMemory = retFalse
                            ace.VerifyProcess = retTrue; ace.CheckModule = retTrue
                            ace.CheckDebugger = retFalse; ace.CheckEmulator = retFalse; ace.CheckRoot = retFalse
                        end
                        for _, path in ipairs({"GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent","GameLua.Mod.BaseMod.Common.Security.HiggsBoson"}) do
                            local Higgs = package.loaded[path]
                            if not Higgs then
                                local ok, m = pcall(require, path)
                                if ok then Higgs = m end
                            end
                            if Higgs then
                                Higgs.bIsEnable = false; Higgs.bMHActive = false; Higgs.bCallPreReplication = false
                                Higgs.StaticShowSecurityAlertInDev = nop
                                Higgs.CheckClientConfig = retFalse
                                Higgs.ReportSecurityAlert = nop
                                Higgs.ValidateClient = retTrue
                                Higgs.CheckIntegrity = retTrue
                                break
                            end
                        end
                        _G.BlackList = {}
                    end)
                end

                local function InitializeSLUA_MD5()
                    pcall(function()
                        if slua and slua.getSignature then slua.getSignature = function() return 0xDEADBEEF end end
                        local loader = package.loaded["slua.loader"]
                        if loader then loader.verifyBytecode = retTrue; loader.checkIntegrity = retTrue end
                        local console = safeImport("KismetSystemLibrary")
                        if console then
                            pcall(function() console.ExecuteConsoleCommand(nil, "pak.DisablePakSignatureCheck 1") end)
                            pcall(function() console.ExecuteConsoleCommand(nil, "s.VerifyPak 0") end)
                        end
                        if _G.MD5Hash then _G.MD5Hash = function() return "00000000000000000000000000000000" end end
                        local FileHashChecker = package.loaded["common.file_hash_checker"]
                        if FileHashChecker then
                            FileHashChecker.CheckFileMD5 = retTrue
                            FileHashChecker.VerifyAll = retTrue
                        end
                        local STExtra = safeImport("STExtraBlueprintFunctionLibrary")
                        if STExtra then
                            STExtra.CheckMD5 = retTrue
                            STExtra.VerifyFile = retTrue
                        end
                    end)
                end

                local function InitializeScannerBlocker()
                    pcall(function()
                        local SubMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
                        if not SubMgr then return end
                        local toKill = {
                            "MemoryCheckSubsystem","SpeedCheckSubsystem","WallCheckSubsystem","FileCheckSubsystem",
                            "BehaviorScoreSubsystem","AntiCheatSubsystem","IntegrityCheckSubsystem","MD5CheckSubsystem",
                            "PakVerifySubsystem","ClientKernelCheckSubsystem","ClientMemoryGuardSubsystem",
                            "ClientWallhackDetectionSubsystem","ClientESPDetectionSubsystem","ClientAimTrackingSubsystem",
                            "TssSdkSubsystem","ACEAntiCheatSubsystem","AntiDebugSubsystem",
                        }
                        for _, name in ipairs(toKill) do
                            if not isSafeName(name) then
                                pcall(function()
                                    local sub = SubMgr:Get(name)
                                    if sub then
                                        for k, v in pairs(sub) do
                                            if not isSafeName(k) then
                                                if type(v) == "function" then sub[k] = nop
                                                elseif type(v) == "number" then sub[k] = 0
                                                elseif type(v) == "boolean" then sub[k] = false end
                                            end
                                        end
                                    end
                                end)
                            end
                        end
                    end)
                end

                local function InitializeReportBlocker()
                    pcall(function()
                        if NetUtil and NetUtil.SendPacket and not NetUtil._blockedByMod then
                            local originalSend = NetUtil.SendPacket
                            local blocked = {}
                            for _, p in ipairs({
                                "ReportAttackFlow","ReportHurtFlow","ReportFireArms","ReportAimFlow","ReportHitFlow",
                                "ReportCircleFlow","ReportJumpFlow","ReportGameStartFlow","ReportGameEndFlow",
                                "report_players_ping","tss_sdk_report","ReportSecurityAlert","ReportAntiCheat",
                                "ReportCheat","ReportHack","ReportMod","ReportInject","ReportViolation","ReportBan","ReportKick",
                                "ClientSecMrpcsFlow","SwiftHawk","ClientSwiftHawk"
                            }) do blocked[p] = true end
                            NetUtil.SendPacket = function(packetName, ...)
                                if blocked[packetName] then return nil end
                                return originalSend(packetName, ...)
                            end
                            NetUtil._blockedByMod = true
                        end
                        if not _G.GameplayCallbacks then _G.GameplayCallbacks = {} end
                        if not _G.GameplayCallbacks.IsBypassed then
                            local GC = _G.GameplayCallbacks
                            local reports = {
                                "ReportAttackFlow","ReportHurtFlow","ReportFireArms","ReportAimFlow","ReportHitFlow",
                                "ReportCircleFlow","ReportJumpFlow","ReportGameStartFlow","ReportGameEndFlow",
                                "ReportSecurityAlert","ReportAntiCheat","ReportCheat","ReportHack","ReportViolation"
                            }
                            for _, f in ipairs(reports) do if not isSafeName(f) then GC[f] = nop end end
                            GC.CheckReportSecAttackFlow = retFalse
                            GC.OnDSPlayerStateChanged = function() end
                            GC.IsBypassed = true
                        end
                    end)
                end

                local function ServerValidationBypass()
                    pcall(function()
                        for _, name in ipairs({"ServerPosValidator","ServerDamageValidator","ServerShootValidator","ServerMoveValidator","RPCValidator"}) do
                            local v = _G[name]
                            if v then v.Validate = retTrue; v.Check = retTrue; v.Report = nop end
                        end
                        if NetUtil and NetUtil.ValidatePacket then NetUtil.ValidatePacket = retTrue end
                    end)
                end

                local function MemoryIntegrityBypass()
                    pcall(function()
                        if _G.MemoryHash then
                            _G.MemoryHash.Calculate = function() return "BYPASSED" end
                            _G.MemoryHash.Verify = retTrue
                        end
                    end)
                end

                local function AntiBanSpoof()
                    pcall(function()
                        local SystemInfo = safeImport("SystemInfo")
                        if SystemInfo then
                            SystemInfo.GetDeviceModel = function() return "iPhone14,5" end
                            SystemInfo.GetDeviceBrand = function() return "Apple" end
                            SystemInfo.IsEmulator = retFalse
                            SystemInfo.IsRooted = retFalse
                            SystemInfo.IsDebugged = retFalse
                        end
                        local DeviceID = safeImport("DeviceID")
                        if DeviceID then
                            DeviceID.GetDeviceID = function() return "BYPASSED" end
                            DeviceID.GetIMEI = function() return "BYPASSED" end
                            DeviceID.GetMACAddress = function() return "BYPASSED" end
                        end
                    end)
                end

                local function AimbotDetectionBypass()
                    pcall(function()
                        local SubMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
                        if SubMgr then
                            local aimSub = SubMgr:Get("ClientAimTrackingSubsystem")
                            if aimSub then
                                aimSub.GetAimData = function(self)
                                    return {accuracy=math.random(40,60), headshotRate=math.random(10,25),
                                        trackingTime=math.random(100,300), aimLockCount=0}
                                end
                                aimSub.ReportAimData = nop
                            end
                        end
                    end)
                end

                local function AggressiveReset()
                    pcall(function()
                        if _G.CHiggsBosonComponent then
                            _G.CHiggsBosonComponent.bMHActive = false
                            _G.CHiggsBosonComponent.bCallPreReplication = false
                        end
                        if _G.PlayerSecurityInfoCollector then
                            _G.PlayerSecurityInfoCollector.ReportData = nop
                            _G.PlayerSecurityInfoCollector.SendToServer = nop
                        end
                        if _G.STExtraBlueprintFunctionLibrary then
                            _G.STExtraBlueprintFunctionLibrary.CheckMD5 = retTrue
                        end
                    end)
                end

                _G.StartBypass_VIP_v3 = function()
                    if not _G.GTLMODConfig.BypassEnabled then return end
                    pcall(function()
                        InitializeCoreBypass()
                        InitializeSLUA_MD5()
                        InitializeScannerBlocker()
                        InitializeReportBlocker()
                        ServerValidationBypass()
                        MemoryIntegrityBypass()
                        AntiBanSpoof()
                        AimbotDetectionBypass()
                        AggressiveReset()
                    end)
                end
                _G.StartBypass_VIP_v3()

                -- ============================================================
                -- FORWARD DECLARATIONS
                -- ============================================================
                local ESPBoxRenderer
                local ESPHealthRenderer
                local ESPDistanceRenderer
                local ESPLineRenderer
                local WallhackRenderer
                local EnemyCounterOverlay

                -- ============================================================
                -- ESP BOX RENDERER  (driven by ESPTick via ticker.AddTimerOnce)
                -- ============================================================
                ESPBoxRenderer = (function()
                    local M = {}
                    local FVector2D    = _G.FVector2D or import("Vector2D")
                    local FLinearColor = _G.FLinearColor or import("LinearColor")
                    local SlateBlueprintLibrary, WidgetLayoutLibrary
                    pcall(function() SlateBlueprintLibrary = import("SlateBlueprintLibrary") end)
                    pcall(function() WidgetLayoutLibrary   = import("WidgetLayoutLibrary")   end)

                    M.BoxThickness   = 1.5
                    M.BoxWidthFactor = 0.40
                    M.RealStrokeColor = (FLinearColor and FLinearColor(1.0, 0.0, 0.0, 0.96)) or {R=1.0, G=0.0, B=0.0, A=0.96}
                    M.BotStrokeColor  = (FLinearColor and FLinearColor(0.0, 1.0, 1.0, 0.96)) or {R=0.0, G=1.0, B=1.0, A=0.96}
                    M.RealTheme = {Key="REAL", Stroke=M.RealStrokeColor}
                    M.BotTheme  = {Key="BOT",  Stroke=M.BotStrokeColor}

                    M.ESPCanvas = nil
                    M.BoxWidgets = {}
                    M._CanvasScaleX, M._CanvasScaleY = 1.0, 1.0
                    M._CanvasOffsetX, M._CanvasOffsetY = 0.0, 0.0
                    M._CachedPC = nil
                    M._CapsuleCache = setmetatable({}, {__mode="k"})
                    M._AITypeCache = {}
                    M._AITypeRetryAt = {}
                    M._Active = false

                    local function IsValid(obj)
                        if obj == nil or slua == nil or type(slua.isValid) ~= "function" then return false end
                        local ok, valid = pcall(slua.isValid, obj)
                        return ok and valid == true
                    end
                    M.IsValid = IsValid

                    function M.IsUIWidgetValid(w)
                        if not w then return false end
                        local ok, valid = pcall(function() return slua.isValid(w) end)
                        return ok and valid == true
                    end

                    function M.CallUISetter(widget, method, ...)
                        if not M.IsUIWidgetValid(widget) then return false end
                        local setter = widget[method]
                        if type(setter) ~= "function" then return false end
                        return setter(widget, ...) ~= false
                    end

                    function M.GetMyPlayerController()
                        local PC = M._CachedPC
                        if PC and IsValid(PC) then return PC end
                        pcall(function()
                            if GameplayData and type(GameplayData.GetPlayerController) == "function" then
                                PC = GameplayData.GetPlayerController()
                            end
                        end)
                        if not (PC and IsValid(PC)) then
                            pcall(function()
                                if slua_GameFrontendHUD then PC = slua_GameFrontendHUD:GetPlayerController() end
                            end)
                        end
                        if PC and IsValid(PC) then M._CachedPC = PC end
                        return PC
                    end

                    function M.InitESPCanvas(forceRefresh)
                        local previous = M.ESPCanvas
                        local previousValid = false
                        pcall(function() previousValid = previous ~= nil and Game:IsValid(previous) end)
                        if previousValid and not forceRefresh then return true end
                        local InGameUITools = nil
                        pcall(function() InGameUITools = require("GameLua.Mod.BaseMod.Common.UI.InGameUITools") end)
                        if not InGameUITools then return previousValid end
                        local MainControlBaseUI = nil
                        pcall(function() MainControlBaseUI = InGameUITools.GetMainControlBaseUI() end)
                        local uiValid = false
                        pcall(function() uiValid = MainControlBaseUI ~= nil and Game:IsValid(MainControlBaseUI) end)
                        if not uiValid then return previousValid end
                        local ParentCanvas = nil
                        pcall(function()
                            local c = MainControlBaseUI.CanvasPanel_0
                            if c and Game:IsValid(c) then ParentCanvas = c end
                        end)
                        if not ParentCanvas then
                            pcall(function()
                                local c = MainControlBaseUI.CanvasPanel_42
                                if c and Game:IsValid(c) then ParentCanvas = c end
                            end)
                        end
                        if not ParentCanvas then return previousValid end
                        if ParentCanvas ~= previous then
                            M.ClearAllBoxes()
                            M.ESPCanvas = ParentCanvas
                        end
                        return true
                    end

                    function M.UpdateCanvasTransform(PC)
                        if not M.ESPCanvas or not Game:IsValid(M.ESPCanvas) then return end
                        local success = false
                        pcall(function()
                            local SBL = SlateBlueprintLibrary
                            if SBL and SBL.AbsoluteToLocal then
                                local cg = M.ESPCanvas:GetCachedGeometry()
                                if cg then
                                    local pt0 = SBL.AbsoluteToLocal(cg, FVector2D and FVector2D(0,0) or {X=0,Y=0})
                                    local pt1 = SBL.AbsoluteToLocal(cg, FVector2D and FVector2D(100,100) or {X=100,Y=100})
                                    if pt0 and pt1 and type(pt0.X)=="number" and type(pt1.X)=="number"
                                        and pt1.X ~= pt0.X and pt1.Y ~= pt0.Y then
                                        M._CanvasScaleX = (pt1.X - pt0.X) / 100
                                        M._CanvasScaleY = (pt1.Y - pt0.Y) / 100
                                        M._CanvasOffsetX = pt0.X
                                        M._CanvasOffsetY = pt0.Y
                                        success = true
                                    end
                                end
                            end
                        end)
                        if not success then
                            local scale = 1.0
                            pcall(function()
                                local WLL = WidgetLayoutLibrary
                                if WLL and WLL.GetViewportScale then
                                    local c = WLL.GetViewportScale(PC)
                                    if type(c)=="number" and c==c and c>0 and c<math.huge then scale = c end
                                end
                            end)
                            M._CanvasScaleX = 1.0 / scale
                            M._CanvasScaleY = 1.0 / scale
                            M._CanvasOffsetX = 0
                            M._CanvasOffsetY = 0
                        end
                    end

                    function M.ProjectToCanvas(PC, WorldLoc, Reuse)
                        Reuse = Reuse or {}
                        Reuse.Pix = Reuse.Pix or (FVector2D and FVector2D(0,0) or {X=0,Y=0})
                        Reuse.Canvas = Reuse.Canvas or (FVector2D and FVector2D(0,0) or {X=0,Y=0})
                        local Pix, Canvas = Reuse.Pix, Reuse.Canvas
                        if not IsValid(PC) or not WorldLoc then
                            Canvas.X, Canvas.Y = 0, 0
                            return false, Canvas
                        end
                        Pix.X, Pix.Y = 0, 0
                        local bOK = false
                        pcall(function()
                            local res = PC:ProjectWorldLocationToScreen(WorldLoc, Pix, true)
                            bOK = (res == true or res == 1 or (Pix and (Pix.X ~= 0 or Pix.Y ~= 0)))
                        end)
                        if not bOK then
                            Canvas.X, Canvas.Y = 0, 0
                            return false, Canvas
                        end
                        local sx = M._CanvasScaleX or 1.0
                        local sy = M._CanvasScaleY or 1.0
                        local ox = M._CanvasOffsetX or 0
                        local oy = M._CanvasOffsetY or 0
                        Canvas.X = Pix.X * sx + ox
                        Canvas.Y = Pix.Y * sy + oy
                        return true, Canvas
                    end

                    function M.GetCharacterVerticalBounds(Character)
                        if not IsValid(Character) then return nil, nil end
                        local Center, HalfHeight = nil, nil
                        local Capsule = M._CapsuleCache[Character]
                        if not (Capsule and IsValid(Capsule)) then
                            Capsule = nil
                            pcall(function()
                                if Character.GetCapsuleComponent then Capsule = Character:GetCapsuleComponent()
                                elseif Character.CapsuleComponent then Capsule = Character.CapsuleComponent end
                            end)
                            if Capsule and IsValid(Capsule) then M._CapsuleCache[Character] = Capsule end
                        end
                        if Capsule and IsValid(Capsule) then
                            pcall(function()
                                if Capsule.K2_GetComponentLocation then Center = Capsule:K2_GetComponentLocation()
                                elseif Capsule.GetComponentLocation then Center = Capsule:GetComponentLocation() end
                                if Capsule.GetScaledCapsuleHalfHeight then HalfHeight = Capsule:GetScaledCapsuleHalfHeight()
                                elseif Capsule.GetUnscaledCapsuleHalfHeight then HalfHeight = Capsule:GetUnscaledCapsuleHalfHeight()
                                elseif Capsule.CapsuleHalfHeight then HalfHeight = Capsule.CapsuleHalfHeight end
                            end)
                        end
                        if not Center then
                            pcall(function()
                                if Character.K2_GetActorLocation then Center = Character:K2_GetActorLocation() end
                            end)
                        end
                        if not Center then return nil, nil end
                        if not HalfHeight or HalfHeight < 10 or HalfHeight > 200 then
                            HalfHeight = 85
                            pcall(function()
                                if Character.bIsCrouched then HalfHeight = 60 end
                                if Character.IsProne and Character:IsProne() then HalfHeight = 25 end
                            end)
                        end
                        return Center, HalfHeight
                    end

                    function M.GetCharacterBoxLocs(Character)
                        local Center, HalfHeight = M.GetCharacterVerticalBounds(Character)
                        if not Center or not HalfHeight then return nil, nil end
                        return {X=Center.X, Y=Center.Y, Z=Center.Z + HalfHeight},
                               {X=Center.X, Y=Center.Y, Z=Center.Z - HalfHeight}
                    end

                    function M.IsAI(Character, KeyStr)
                        if not IsValid(Character) then return false end
                        KeyStr = KeyStr or tostring(Character)
                        local cached = M._AITypeCache[KeyStr]
                        if cached ~= nil then return cached end
                        local now = os.clock()
                        if now < (M._AITypeRetryAt[KeyStr] or 0) then return false end
                        local bAI, hasSignal = false, false
                        local function accept(v)
                            if v == true or v == 1 then bAI, hasSignal = true, true
                            elseif v == false or v == 0 then hasSignal = true end
                        end
                        pcall(function() if Game and Game.IsAI then accept(Game:IsAI(Character)) end end)
                        if not bAI then pcall(function() accept(Character.bIsAI) end) end
                        if not bAI then pcall(function() accept(Character.IsAI) end) end
                        if not bAI then
                            pcall(function()
                                local m = Character.IsBot
                                if type(m) == "function" then accept(m(Character)) end
                            end)
                        end
                        if not bAI then
                            local ps = nil
                            pcall(function()
                                if Character.GetPlayerStateSafety then ps = Character:GetPlayerStateSafety()
                                elseif Character.GetPlayerState then ps = Character:GetPlayerState()
                                elseif Character.PlayerState then ps = Character.PlayerState end
                            end)
                            if ps and IsValid(ps) then
                                pcall(function() accept(ps.bIsABot) end)
                                if not bAI then pcall(function() accept(ps.bIsBot) end) end
                                if not bAI then pcall(function() accept(ps.bIsAI) end) end
                            end
                        end
                        if hasSignal then M._AITypeCache[KeyStr] = bAI
                        else M._AITypeRetryAt[KeyStr] = now + 1.0 end
                        return bAI
                    end

                    function M.GetEnemyTheme(bIsAI)
                        if bIsAI then return M.BotTheme end
                        return M.RealTheme
                    end

                    function M.CreateLineWidget(color, zOrder)
                        if not M.ESPCanvas or not Game:IsValid(M.ESPCanvas) then return nil end
                        local Border = nil
                        pcall(function() Border = CGame:NewObjectFromPath("/Script/UMG.Border", M.ESPCanvas) end)
                        if not Border or not slua.isValid(Border) then return nil end
                        pcall(function() Border:SetBrushColor(color) end)
                        pcall(function() Border:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
                        pcall(function() Border:SetRenderTransformPivot(FVector2D and FVector2D(0.0, 0.5) or {X=0, Y=0.5}) end)
                        local Slot = nil
                        pcall(function()
                            Slot = M.ESPCanvas:AddChildToCanvas(Border)
                            if Slot then Slot:SetAutoSize(false) Slot:SetZOrder(zOrder or 1) end
                        end)
                        if not Slot then
                            pcall(function() Border:RemoveFromParent() end)
                            pcall(function() Border:ConditionalBeginDestroy() end)
                            return nil
                        end
                        return {Widget = Border, Slot = Slot}
                    end

                    function M.DrawLine(ld, x1, y1, x2, y2, thickness)
                        if not ld or not M.IsUIWidgetValid(ld.Widget) or not M.IsUIWidgetValid(ld.Slot) then return false end
                        local dx, dy = x2 - x1, y2 - y1
                        local len = math.sqrt(dx * dx + dy * dy)
                        if len < 0.5 then
                            ld._x1 = nil
                            if ld._visible ~= false then
                                local hidden = pcall(function()
                                    return M.CallUISetter(ld.Widget, 'SetWidgetVisibility', UEnums.ESlateVisibility.Collapsed)
                                end)
                                if hidden then ld._visible = false else ld._visible = nil end
                            end
                            return false
                        end
                        local eps = 0.25
                        if ld._visible == true and ld._x1 and
                           math.abs(ld._x1 - x1) < eps and math.abs(ld._y1 - y1) < eps and
                           math.abs(ld._x2 - x2) < eps and math.abs(ld._y2 - y2) < eps and
                           math.abs((ld._thickness or 0) - thickness) < 0.01 then
                            return true
                        end
                        local ang = (math.atan2 and math.atan2(dy, dx) or math.atan(dy, dx)) * (180.0 / math.pi)
                        ld._drawPos  = ld._drawPos  or (FVector2D and FVector2D(0,0) or {X=0,Y=0})
                        ld._drawSize = ld._drawSize or (FVector2D and FVector2D(0,0) or {X=0,Y=0})
                        ld._drawPos.X, ld._drawPos.Y   = x1, y1 - thickness / 2
                        ld._drawSize.X, ld._drawSize.Y = len, thickness
                        local applied = pcall(function()
                            if ld.Slot:SetPosition(ld._drawPos) == false then return false end
                            if ld.Slot:SetSize(ld._drawSize) == false then return false end
                            if ld.Widget:SetRenderAngle(ang) == false then return false end
                            if ld._visible ~= true then
                                if ld.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) == false then return false end
                            end
                            return true
                        end)
                        if not applied then ld._x1 = nil; return false end
                        ld._x1, ld._y1, ld._x2, ld._y2 = x1, y1, x2, y2
                        ld._thickness = thickness
                        ld._visible = true
                        return true
                    end

                    function M.ApplyLineTheme(ld, theme)
                        if not ld or not M.IsUIWidgetValid(ld.Widget) or not theme then return false end
                        if ld._themeKey == theme.Key then return true end
                        local ok = pcall(function()
                            return M.CallUISetter(ld.Widget, 'SetBrushColor', theme.Stroke)
                        end)
                        if ok then ld._themeKey = theme.Key; return true end
                        ld._themeKey = nil
                        return false
                    end

                    local function HideWidget(ld)
                        if not ld or not M.IsUIWidgetValid(ld.Widget) then return false end
                        if ld._visible == false then return true end
                        local ok = pcall(function()
                            return M.CallUISetter(ld.Widget, 'SetWidgetVisibility', UEnums.ESlateVisibility.Collapsed)
                        end)
                        if ok then ld._visible = false; return true end
                        ld._visible = nil
                        return false
                    end
                    M.HideWidget = HideWidget

                    local function DestroyWidget(ld)
                        if not ld then return end
                        local widget = ld.Widget
                        ld.Widget, ld.Slot = nil, nil
                        if M.IsUIWidgetValid(widget) then
                            pcall(function() widget:RemoveFromParent() end)
                            pcall(function() widget:ConditionalBeginDestroy() end)
                        end
                    end
                    M.DestroyWidget = DestroyWidget

                    function M.UpdateBox(KeyStr, headCanvas, feetCanvas, bOnScreen, bIsAI)
                        if not _G.GTLMODConfig.EspBox then M.RemoveBox(KeyStr); return end
                        local box = M.BoxWidgets[KeyStr]
                        local boxH = bOnScreen and headCanvas and feetCanvas and (feetCanvas.Y - headCanvas.Y) or nil
                        if not boxH or boxH < 10 then
                            if box then
                                box._lastL = nil
                                HideWidget(box.frontTop);  HideWidget(box.frontBot)
                                HideWidget(box.frontLeft); HideWidget(box.frontRight)
                                HideWidget(box.backTop);   HideWidget(box.backBot)
                                HideWidget(box.backLeft);  HideWidget(box.backRight)
                                HideWidget(box.connTL);    HideWidget(box.connTR)
                                HideWidget(box.connBL);    HideWidget(box.connBR)
                            end
                            return
                        end
                        local boxW = boxH * (M.BoxWidthFactor or 0.40)
                        local cx = (headCanvas.X + feetCanvas.X) * 0.5
                        local L, R = cx - boxW * 0.5, cx + boxW * 0.5
                        local T, B = headCanvas.Y, feetCanvas.Y
                        local depth = math.max(4.0, math.min(12.0, boxW * 0.16))
                        local backDX, backDY = depth * 0.65, -depth
                        local bL, bR, bT, bB = L + backDX, R + backDX, T + backDY, B + backDY
                        local thick = M.BoxThickness or 1.5
                        local theme = M.GetEnemyTheme(bIsAI)
                        if not box then box = {_buildIndex = 1}; M.BoxWidgets[KeyStr] = box end
                        if box._buildIndex then
                            local parts = {"frontTop","frontBot","frontLeft","frontRight",
                                           "backTop","backBot","backLeft","backRight",
                                           "connTL","connTR","connBL","connBR"}
                            while box._buildIndex <= #parts do
                                local index = box._buildIndex
                                local part = M.CreateLineWidget(theme.Stroke, 1)
                                if not part then
                                    for i = 1, index - 1 do HideWidget(box[parts[i]]) end
                                    return
                                end
                                box[parts[index]] = part
                                box._buildIndex = index + 1
                                HideWidget(part)
                            end
                            box._buildIndex = nil
                        end
                        local sameGeometry = box._lastL and
                            math.abs(box._lastL - L) < 0.25 and math.abs(box._lastR - R) < 0.25 and
                            math.abs(box._lastT - T) < 0.25 and math.abs(box._lastB - B) < 0.25 and
                            math.abs(box._lastBL - bL) < 0.25 and math.abs(box._lastBT - bT) < 0.25 and
                            box._lastThemeKey == theme.Key
                        if sameGeometry then return end
                        local complete = true
                        local function ApplyTheme(ld, value)
                            if not M.ApplyLineTheme(ld, value) then complete = false end
                        end
                        local function Draw(ld, ...)
                            if not M.DrawLine(ld, ...) then complete = false end
                        end
                        ApplyTheme(box.frontTop, theme);  ApplyTheme(box.frontBot, theme)
                        ApplyTheme(box.frontLeft, theme); ApplyTheme(box.frontRight, theme)
                        ApplyTheme(box.backTop, theme);   ApplyTheme(box.backBot, theme)
                        ApplyTheme(box.backLeft, theme);  ApplyTheme(box.backRight, theme)
                        ApplyTheme(box.connTL, theme);    ApplyTheme(box.connTR, theme)
                        ApplyTheme(box.connBL, theme);    ApplyTheme(box.connBR, theme)
                        Draw(box.frontTop,   L, T, R, T, thick)
                        Draw(box.frontBot,   L, B, R, B, thick)
                        Draw(box.frontLeft,  L, T, L, B, thick)
                        Draw(box.frontRight, R, T, R, B, thick)
                        Draw(box.backTop,    bL, bT, bR, bT, thick)
                        Draw(box.backBot,    bL, bB, bR, bB, thick)
                        Draw(box.backLeft,   bL, bT, bL, bB, thick)
                        Draw(box.backRight,  bR, bT, bR, bB, thick)
                        Draw(box.connTL,     L,  T, bL, bT, thick)
                        Draw(box.connTR,     R,  T, bR, bT, thick)
                        Draw(box.connBL,     L,  B, bL, bB, thick)
                        Draw(box.connBR,     R,  B, bR, bB, thick)
                        if complete then
                            box._lastL, box._lastR = L, R
                            box._lastT, box._lastB = T, B
                            box._lastBL, box._lastBT = bL, bT
                            box._lastThemeKey = theme.Key
                        else
                            box._lastL = nil
                        end
                    end

                    function M.RemoveBox(KeyStr)
                        local box = M.BoxWidgets[KeyStr]
                        if box then
                            for _, ld in pairs(box) do
                                if type(ld) == "table" and ld.Widget then DestroyWidget(ld) end
                            end
                        end
                        M.BoxWidgets[KeyStr] = nil
                    end

                    function M.ClearAllBoxes()
                        for _, box in pairs(M.BoxWidgets) do
                            if box then
                                for _, ld in pairs(box) do
                                    if type(ld) == "table" and ld.Widget then DestroyWidget(ld) end
                                end
                            end
                        end
                        M.BoxWidgets = {}
                    end

                    -- ⚡ PUBLIC TICK (driven by ESPTick in MainLoop area)
                    function M.TickOnce()
                        if not M._Active then return end
                        if isExpired then return end
                        if not M.InitESPCanvas() then return end
                        local pc = M.GetMyPlayerController()
                        if not IsValid(pc) then return end
                        M.UpdateCanvasTransform(pc)

                        local localPlayer = nil
                        pcall(function()
                            if GameplayData and GameplayData.GetPlayerCharacter then
                                localPlayer = GameplayData.GetPlayerCharacter()
                            end
                        end)
                        if not IsValid(localPlayer) then return end

                        local myLoc = nil
                        pcall(function()
                            if localPlayer.K2_GetActorLocation then myLoc = localPlayer:K2_GetActorLocation() end
                        end)

                        local viewW = nil
                        pcall(function()
                            local s = FVector2D and FVector2D(0,0) or {X=0,Y=0}
                            pc:GetViewportSize(s)
                            if s and s.X and s.X > 200 then viewW = s.X end
                        end)
                        if not viewW then
                            pcall(function()
                                if WidgetLayoutLibrary and WidgetLayoutLibrary.GetViewportSize then
                                    local s = WidgetLayoutLibrary.GetViewportSize(pc)
                                    if s and s.X and s.X > 200 then viewW = s.X end
                                end
                            end)
                        end
                        if not viewW then viewW = 1920 end

                        local topOrigin = nil
                        if _G.GTLMODConfig.EspLine then
                            local sx = M._CanvasScaleX or 1.0
                            local sy = M._CanvasScaleY or 1.0
                            local ox = M._CanvasOffsetX or 0
                            local oy = M._CanvasOffsetY or 0
                            topOrigin = { X = (viewW * 0.5) * sx + ox, Y = 0 * sy + oy }
                        end

                        local enemies = {}
                        pcall(function()
                            if GameplayData and GameplayData.GetAllPlayerCharacters then
                                enemies = GameplayData.GetAllPlayerCharacters() or {}
                            end
                        end)
                        local seen = {}
                        local myTeam = localPlayer.TeamID
                        local realCount, botCount = 0, 0
                        for _, enemy in pairs(enemies) do
                            if IsValid(enemy) and enemy ~= localPlayer
                                and (myTeam == nil or enemy.TeamID ~= myTeam) then
                                local alive = true
                                pcall(function()
                                    if type(enemy.IsDead) == "function" and enemy:IsDead() then alive = false
                                    elseif enemy.bIsDead then alive = false end
                                    if enemy.bHidden or (enemy.Mesh and enemy.Mesh.bHidden) then alive = false end
                                end)
                                if alive then
                                    local key = tostring(enemy.PlayerKey or enemy)
                                    seen[key] = true
                                    local headLoc, feetLoc = M.GetCharacterBoxLocs(enemy)
                                    local bHeadOK, headCanvas = false, nil
                                    local bFeetOK, feetCanvas = false, nil
                                    if headLoc then
                                        local ok, cv = M.ProjectToCanvas(pc, headLoc); bHeadOK, headCanvas = ok, cv
                                    end
                                    if feetLoc then
                                        local ok, cv = M.ProjectToCanvas(pc, feetLoc); bFeetOK, feetCanvas = ok, cv
                                    end
                                    local bOnScreen = bHeadOK and bFeetOK
                                    local bIsAI = M.IsAI(enemy, key)
                                    if bIsAI then botCount = botCount + 1 else realCount = realCount + 1 end

                                    M.UpdateBox(key, headCanvas, feetCanvas, bOnScreen, bIsAI)

                                    if _G.GTLMODConfig.EspHealth and ESPHealthRenderer and ESPHealthRenderer.Update then
                                        pcall(ESPHealthRenderer.Update, key, feetCanvas, headCanvas, enemy, bOnScreen, bIsAI)
                                    end
                                    if _G.GTLMODConfig.EspDistance and ESPDistanceRenderer and ESPDistanceRenderer.Update then
                                        pcall(ESPDistanceRenderer.Update, key, feetCanvas, feetLoc, myLoc, bOnScreen)
                                    end
                                    if topOrigin and ESPLineRenderer and ESPLineRenderer.Update then
                                        pcall(ESPLineRenderer.Update, key, headCanvas, topOrigin, bOnScreen, bIsAI, pc, enemy)
                                    end
                                end
                            end
                        end

                        if _G.GTLMODConfig.CounterEnabled and EnemyCounterOverlay then
                            if EnemyCounterOverlay.Create() then
                                EnemyCounterOverlay.UpdatePosition(pc)
                                EnemyCounterOverlay.SetCounts(realCount, botCount)
                            end
                        elseif EnemyCounterOverlay then
                            EnemyCounterOverlay.Hide()
                        end

                        local stale = {}
                        for k in pairs(M.BoxWidgets) do
                            if not seen[k] then stale[#stale + 1] = k end
                        end
                        for _, k in ipairs(stale) do
                            M.RemoveBox(k)
                            if ESPHealthRenderer then pcall(ESPHealthRenderer.Remove, k) end
                            if ESPDistanceRenderer then pcall(ESPDistanceRenderer.Remove, k) end
                            if ESPLineRenderer then pcall(ESPLineRenderer.Remove, k) end
                        end
                    end

                    function M.Start()
                        if M._Active then return true end
                        M._Active = true
                        print("[ESP-Box] Active (driven by ESPTick)")
                        return true
                    end

                    function M.Stop()
                        M._Active = false
                        M.ClearAllBoxes()
                        if ESPHealthRenderer then pcall(ESPHealthRenderer.ClearAll) end
                        if ESPDistanceRenderer then pcall(ESPDistanceRenderer.ClearAll) end
                        if ESPLineRenderer then pcall(ESPLineRenderer.ClearAll) end
                        if EnemyCounterOverlay then pcall(EnemyCounterOverlay.Destroy) end
                    end

                    function M.IsActive() return M._Active end
                    _G.ESPBoxRenderer = M
                    return M
                end)()

                -- ============================================================
                -- ESP HEALTH RENDERER
                -- ============================================================
                ESPHealthRenderer = (function()
                    local M = {}
                    local FVector2D    = _G.FVector2D or import("Vector2D")
                    local FLinearColor = _G.FLinearColor or import("LinearColor")
                    M.BarHeight = 5.0
                    M.BarWidthFactor = 0.40
                    M.OutlineColor = (FLinearColor and FLinearColor(0,0,0,0.85)) or {R=0,G=0,B=0,A=0.85}
                    M.TrackColor   = (FLinearColor and FLinearColor(0.05,0.05,0.05,0.85)) or {R=0.05,G=0.05,B=0.05,A=0.85}
                    M.Widgets = {}
                    M.Canvas = nil

                    local function IsValid(o)
                        if o==nil or slua==nil or type(slua.isValid)~="function" then return false end
                        local ok,v = pcall(slua.isValid,o); return ok and v==true
                    end

                    function M.InitCanvas(force)
                        if not force and M.Canvas and Game:IsValid(M.Canvas) then return true end
                        local tools; pcall(function() tools = require("GameLua.Mod.BaseMod.Common.UI.InGameUITools") end)
                        if not tools then return false end
                        local root; pcall(function() root = tools.GetMainControlBaseUI() end)
                        if not root or not Game:IsValid(root) then return false end
                        local canvas = root.CanvasPanel_0
                        if not canvas or not Game:IsValid(canvas) then canvas = root.CanvasPanel_42 end
                        if not canvas or not Game:IsValid(canvas) then return false end
                        M.Canvas = canvas
                        return true
                    end

                    local function MakeBorder(color, z)
                        if not M.Canvas or not Game:IsValid(M.Canvas) then return nil end
                        local b; pcall(function() b = CGame:NewObjectFromPath("/Script/UMG.Border", M.Canvas) end)
                        if not b or not slua.isValid(b) then return nil end
                        pcall(function() b:SetBrushColor(color) end)
                        pcall(function() b:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
                        local s
                        pcall(function()
                            s = M.Canvas:AddChildToCanvas(b)
                            if s then s:SetAutoSize(false) s:SetZOrder(z or 2) end
                        end)
                        if not s then pcall(function() b:ConditionalBeginDestroy() end) return nil end
                        return {W=b, S=s}
                    end

                    local function Hide(part)
                        if not part or not IsValid(part.W) then return end
                        pcall(function() part.W:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
                    end

                    local function Destroy(part)
                        if not part then return end
                        local w = part.W; part.W, part.S = nil, nil
                        if IsValid(w) then
                            pcall(function() w:RemoveFromParent() end)
                            pcall(function() w:ConditionalBeginDestroy() end)
                        end
                    end

                    function M.GetHealthPct(pawn)
                        if not IsValid(pawn) then return 0 end
                        local hp, max = nil, nil
                        pcall(function()
                            if pawn.Health ~= nil then hp = pawn.Health elseif pawn.HP ~= nil then hp = pawn.HP
                            elseif pawn.GetHealth then hp = pawn:GetHealth() end
                            if pawn.HealthMax ~= nil then max = pawn.HealthMax elseif pawn.MaxHealth ~= nil then max = pawn.MaxHealth
                            elseif pawn.GetHealthMax then max = pawn:GetHealthMax() end
                        end)
                        hp = tonumber(hp) or 0; max = tonumber(max) or 100
                        if max <= 0 then max = 100 end
                        local p = hp/max; if p<0 then p=0 elseif p>1 then p=1 end
                        return p
                    end

                    function M.GetHealthColor(pct)
                        if pct <= 0.10 then return (FLinearColor and FLinearColor(1,0,0,1)) or {R=1,G=0,B=0,A=1} end
                        if pct < 0.50 then local t=(pct-0.10)/0.40 return (FLinearColor and FLinearColor(1,t,0,1)) or {R=1,G=t,B=0,A=1} end
                        if pct >= 1.0 then return (FLinearColor and FLinearColor(0,1,0,1)) or {R=0,G=1,B=0,A=1} end
                        local t=(pct-0.50)/0.50
                        return (FLinearColor and FLinearColor(1-t,1,0,1)) or {R=1-t,G=1,B=0,A=1}
                    end

                    function M.Update(key, feetCanvas, headCanvas, pawn, onScreen, isAI)
                        if not _G.GTLMODConfig.EspHealth then M.Remove(key) return end
                        local data = M.Widgets[key]
                        if not onScreen or not feetCanvas or not headCanvas then
                            if data then Hide(data.track) Hide(data.fill) Hide(data.outline) end
                            return
                        end
                        local h = feetCanvas.Y - headCanvas.Y
                        if h < 10 then if data then Hide(data.track) Hide(data.fill) Hide(data.outline) end return end
                        local w = h * (M.BarWidthFactor or 0.40)
                        if w < 20 then w = 20 end
                        if w > 120 then w = 120 end
                        local cx = (headCanvas.X + feetCanvas.X) * 0.5
                        local y = headCanvas.Y - 8 - M.BarHeight
                        local x = cx - w * 0.5
                        local pct = M.GetHealthPct(pawn)
                        if not data then
                            data = {
                                outline = MakeBorder(M.OutlineColor, 2),
                                track   = MakeBorder(M.TrackColor,   2),
                                fill    = MakeBorder(M.GetHealthColor(pct), 3),
                            }
                            if not data.outline or not data.track or not data.fill then
                                Destroy(data.outline) Destroy(data.track) Destroy(data.fill)
                                M.Widgets[key] = nil; return
                            end
                            M.Widgets[key] = data
                        end
                        local bh = M.BarHeight
                        pcall(function() data.outline.S:SetPosition(FVector2D and FVector2D(x-1, y-1) or {X=x-1,Y=y-1})
                            data.outline.S:SetSize(FVector2D and FVector2D(w+2, bh+2) or {X=w+2,Y=bh+2}) end)
                        pcall(function() data.track.S:SetPosition(FVector2D and FVector2D(x, y) or {X=x,Y=y})
                            data.track.S:SetSize(FVector2D and FVector2D(w, bh) or {X=w,Y=bh}) end)
                        pcall(function() data.fill.S:SetPosition(FVector2D and FVector2D(x, y) or {X=x,Y=y})
                            data.fill.S:SetSize(FVector2D and FVector2D(math.max(0,w*pct), bh) or {X=math.max(0,w*pct),Y=bh}) end)
                        pcall(function() data.fill.W:SetBrushColor(M.GetHealthColor(pct)) end)
                        pcall(function() data.outline.W:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
                        pcall(function() data.track.W:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
                        pcall(function() data.fill.W:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
                    end

                    function M.Remove(key)
                        local d = M.Widgets[key]; if not d then return end
                        Destroy(d.outline); Destroy(d.track); Destroy(d.fill)
                        M.Widgets[key] = nil
                    end
                    function M.ClearAll()
                        for k in pairs(M.Widgets) do M.Remove(k) end
                        M.Widgets = {}
                    end
                    _G.ESPHealthRenderer = M
                    return M
                end)()

                -- ============================================================
                -- ESP DISTANCE RENDERER
                -- ============================================================
                ESPDistanceRenderer = (function()
                    local M = {}
                    local FVector2D    = _G.FVector2D or import("Vector2D")
                    local FLinearColor = _G.FLinearColor or import("LinearColor")
                    M.TextColor = (FLinearColor and FLinearColor(1,1,1,0.95)) or {R=1,G=1,B=1,A=0.95}
                    M.BGColor   = (FLinearColor and FLinearColor(0.05,0.05,0.05,0.75)) or {R=0.05,G=0.05,B=0.05,A=0.75}
                    M.TextHeight = 14.0
                    M.TextWidth  = 70.0
                    M.Widgets = {}
                    M.Canvas = nil

                    local function IsValid(o)
                        if o==nil or slua==nil or type(slua.isValid)~="function" then return false end
                        local ok,v = pcall(slua.isValid,o); return ok and v==true
                    end

                    function M.InitCanvas(force)
                        if not force and M.Canvas and Game:IsValid(M.Canvas) then return true end
                        local tools; pcall(function() tools = require("GameLua.Mod.BaseMod.Common.UI.InGameUITools") end)
                        if not tools then return false end
                        local root; pcall(function() root = tools.GetMainControlBaseUI() end)
                        if not root or not Game:IsValid(root) then return false end
                        local canvas = root.CanvasPanel_0
                        if not canvas or not Game:IsValid(canvas) then canvas = root.CanvasPanel_42 end
                        if not canvas or not Game:IsValid(canvas) then return false end
                        M.Canvas = canvas
                        return true
                    end

                    local function MakeText()
                        if not M.Canvas or not Game:IsValid(M.Canvas) then return nil end
                        local bg; pcall(function() bg = CGame:NewObjectFromPath("/Script/UMG.Border", M.Canvas) end)
                        local txt; pcall(function() txt = CGame:NewObjectFromPath("/Script/UMG.TextBlock", M.Canvas) end)
                        if not bg or not txt or not slua.isValid(bg) or not slua.isValid(txt) then return nil end
                        pcall(function()
                            bg:SetBrushColor(M.BGColor)
                            bg:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                            txt:SetText("--m")
                            txt:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                            if txt.SetJustification then txt:SetJustification(1) end
                            if txt.Font then local f = txt.Font f.Size = 11 txt:SetFont(f) end
                        end)
                        local slot; pcall(function()
                            slot = M.Canvas:AddChildToCanvas(bg)
                            if slot then slot:SetAutoSize(false) slot:SetZOrder(4) end
                        end)
                        if not slot then pcall(function() bg:ConditionalBeginDestroy() end) return nil end
                        local tslot; pcall(function()
                            tslot = M.Canvas:AddChildToCanvas(txt)
                            if tslot then
                                tslot:SetAutoSize(true)
                                tslot:SetAlignment(FVector2D and FVector2D(0.5,0.5) or {X=0.5,Y=0.5})
                                tslot:SetZOrder(5)
                            end
                        end)
                        if not tslot then pcall(function() bg:ConditionalBeginDestroy() end) return nil end
                        return {BG=bg, BGS=slot, TXT=txt, TXTS=tslot, LastText=nil}
                    end

                    local function Destroy(d)
                        if not d then return end
                        local bg, txt = d.BG, d.TXT
                        d.BG, d.BGS, d.TXT, d.TXTS = nil,nil,nil,nil
                        if IsValid(bg) then pcall(function() bg:RemoveFromParent() end) pcall(function() bg:ConditionalBeginDestroy() end) end
                        if IsValid(txt) then pcall(function() txt:RemoveFromParent() end) pcall(function() txt:ConditionalBeginDestroy() end) end
                    end

                    function M.GetDistanceMeters(myLoc, targetLoc)
                        if not myLoc or not targetLoc then return nil end
                        local dx = (targetLoc.X or 0)-(myLoc.X or 0)
                        local dy = (targetLoc.Y or 0)-(myLoc.Y or 0)
                        local dz = (targetLoc.Z or 0)-(myLoc.Z or 0)
                        return math.sqrt(dx*dx+dy*dy+dz*dz) / 100.0
                    end

                    function M.Format(m)
                        m = tonumber(m); if not m then return "--m" end
                        if m < 1000 then return string.format("%dm", math.floor(m+0.5)) end
                        return string.format("%.1fkm", m/1000.0)
                    end

                    function M.Update(key, feetCanvas, feetLoc, myLoc, onScreen)
                        if not _G.GTLMODConfig.EspDistance then M.Remove(key) return end
                        local d = M.Widgets[key]
                        if not onScreen or not feetCanvas or not feetLoc or not myLoc then
                            if d then
                                pcall(function() d.BG:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
                                pcall(function() d.TXT:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
                            end
                            return
                        end
                        if not d then d = MakeText() if not d then return end M.Widgets[key] = d end
                        local meters = M.GetDistanceMeters(myLoc, feetLoc)
                        local txt = M.Format(meters)
                        if d.LastText ~= txt then
                            pcall(function() d.TXT:SetText(txt) end)
                            d.LastText = txt
                        end
                        local y = feetCanvas.Y + 4
                        local x = feetCanvas.X - M.TextWidth*0.5
                        pcall(function() d.BGS:SetPosition(FVector2D and FVector2D(x, y) or {X=x,Y=y})
                            d.BGS:SetSize(FVector2D and FVector2D(M.TextWidth, M.TextHeight) or {X=M.TextWidth,Y=M.TextHeight}) end)
                        pcall(function() d.TXTS:SetPosition(FVector2D and FVector2D(x+M.TextWidth*0.5, y+M.TextHeight*0.5) or {X=x+M.TextWidth*0.5,Y=y+M.TextHeight*0.5}) end)
                        pcall(function() d.BG:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
                        pcall(function() d.TXT:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
                    end

                    function M.Remove(key)
                        local d = M.Widgets[key]; if not d then return end
                        Destroy(d); M.Widgets[key] = nil
                    end
                    function M.ClearAll()
                        for k in pairs(M.Widgets) do M.Remove(k) end
                        M.Widgets = {}
                    end
                    _G.ESPDistanceRenderer = M
                    return M
                end)()

                -- ============================================================
                -- ESP LINE RENDERER
                -- ============================================================
                ESPLineRenderer = (function()
                    local M = {}
                    local FLinearColor = _G.FLinearColor or import("LinearColor")
                    M.Thickness = 1.5
                    M.RealVisible  = (FLinearColor and FLinearColor(0.15, 0.55, 1.0, 0.95)) or {R=0.15, G=0.55, B=1.0, A=0.95}
                    M.RealBlocked  = (FLinearColor and FLinearColor(1.0,  0.15, 0.15, 0.85)) or {R=1.0,  G=0.15, B=0.15, A=0.85}
                    M.RealKnocked  = (FLinearColor and FLinearColor(0.2,  0.9,  0.9,  0.9))  or {R=0.2,  G=0.9,  B=0.9,  A=0.9}
                    M.BotVisible   = (FLinearColor and FLinearColor(1.0,  0.2,  1.0,  0.95)) or {R=1.0,  G=0.2,  B=1.0,  A=0.95}
                    M.BotBlocked   = (FLinearColor and FLinearColor(0.6,  0.0,  0.3,  0.85)) or {R=0.6,  G=0.0,  B=0.3,  A=0.85}
                    M.Lines = {}
                    M._VisCache = {}
                    M._VisCacheTime = 0.12

                    local function WValid(w)
                        if not w then return false end
                        local ok, v = pcall(function() return slua.isValid(w) end)
                        return ok and v == true
                    end

                    local function IsCharVisible(pc, enemy)
                        if not pc or not enemy then return false end
                        if not WValid(pc) or not WValid(enemy) then return false end
                        local now = os.clock()
                        local key = tostring(enemy)
                        local entry = M._VisCache[key]
                        if entry and (now - entry.t) < M._VisCacheTime then return entry.v end
                        local vis = false
                        pcall(function()
                            if type(pc.LineOfSightTo) == "function" then
                                vis = pc:LineOfSightTo(enemy) and true or false
                            end
                        end)
                        M._VisCache[key] = {v = vis, t = now}
                        return vis
                    end

                    local function IsKnocked(enemy)
                        if not enemy then return false end
                        local knocked = false
                        pcall(function()
                            if enemy.HealthStatus == 1 then knocked = true end
                            if enemy.Health and enemy.Health <= 0 and enemy.HealthStatus ~= 2 then knocked = true end
                        end)
                        return knocked
                    end

                    function M.PickColor(enemy, isAI, pc)
                        if IsKnocked(enemy) then return M.RealKnocked end
                        local vis = IsCharVisible(pc, enemy)
                        if isAI then return vis and M.BotVisible or M.BotBlocked
                        else return vis and M.RealVisible or M.RealBlocked end
                    end

                    function M.Remove(key)
                        local ld = M.Lines[key]
                        if not ld then return end
                        M.Lines[key] = nil
                        if WValid(ld.Widget) then
                            pcall(function() ld.Widget:RemoveFromParent() end)
                            pcall(function() ld.Widget:ConditionalBeginDestroy() end)
                        end
                    end

                    function M.ClearAll()
                        for k in pairs(M.Lines) do M.Remove(k) end
                        M.Lines = {}
                        M._VisCache = {}
                    end

                    function M.Update(key, headCanvas, topOriginCanvas, onScreen, isAI, pc, enemy)
                        if not _G.GTLMODConfig.EspLine then M.Remove(key); return end
                        local ld = M.Lines[key]
                        if not onScreen or not headCanvas or not topOriginCanvas then
                            if ld and WValid(ld.Widget) then
                                pcall(function() ld.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
                                ld._visible = false
                            end
                            return
                        end
                        local color = M.PickColor(enemy, isAI, pc)
                        local colorKey
                        if IsKnocked(enemy) then colorKey = "KNOCK"
                        elseif isAI then colorKey = IsCharVisible(pc, enemy) and "BOT_VIS" or "BOT_OCC"
                        else colorKey = IsCharVisible(pc, enemy) and "REAL_VIS" or "REAL_OCC" end

                        if not ld then
                            ld = ESPBoxRenderer.CreateLineWidget(color, 1)
                            if not ld then return end
                            ld._colorKey = colorKey
                            M.Lines[key] = ld
                        elseif ld._colorKey ~= colorKey then
                            pcall(function() ld.Widget:SetBrushColor(color) end)
                            ld._colorKey = colorKey
                        end
                        ESPBoxRenderer.DrawLine(ld,
                            topOriginCanvas.X, topOriginCanvas.Y,
                            headCanvas.X,     headCanvas.Y,
                            M.Thickness)
                    end
                    _G.ESPLineRenderer = M
                    return M
                end)()

                -- ============================================================
                -- ENEMY / BOT COUNTER OVERLAY (rainbow frames)
                -- ============================================================
                EnemyCounterOverlay = (function()
                    local M = {}
                    local FVector2D    = _G.FVector2D or import("Vector2D")
                    local FLinearColor = _G.FLinearColor or import("LinearColor")
                    local WidgetLayoutLibrary = nil
                    pcall(function() WidgetLayoutLibrary = import("WidgetLayoutLibrary") end)
                    M.Width, M.Height = 240.0, 26.0
                    M.OffsetY = 50.0
                    M.FontSize = 12
                    M.Container, M.Slot = nil, nil
                    M.PlayerBGWidget, M.BotBGWidget = nil, nil
                    M.PlayerText, M.BotText = nil, nil
                    M.PlayerFrame, M.BotFrame = nil, nil
                    M._LastPlayers, M._LastBots = -1, -1
                    M._LastX, M._LastY = nil, nil

                    local function WValid(w)
                        if not w then return false end
                        local ok, v = pcall(function() return slua.isValid(w) end)
                        return ok and v == true
                    end

                    local function RainbowColor(t, phase)
                        phase = phase or 0
                        local r = math.sin(t * 1.8 + phase) * 0.5 + 0.5
                        local g = math.sin(t * 1.8 + phase + 2.094) * 0.5 + 0.5
                        local b = math.sin(t * 1.8 + phase + 4.188) * 0.5 + 0.5
                        local FC = FLinearColor
                        if not FC then return {R=255, G=255, B=255, A=255} end
                        return FC(0.25 + r * 0.75, 0.25 + g * 0.75, 0.25 + b * 0.75, 1.0)
                    end

                    function M.Create()
                        if M.Container and WValid(M.Container) then return true end
                        if not ESPBoxRenderer or not ESPBoxRenderer.InitESPCanvas then return false end
                        if not ESPBoxRenderer.InitESPCanvas() then return false end
                        local parent = ESPBoxRenderer.ESPCanvas
                        if not parent or not WValid(parent) then return false end

                        local c, pbg, bbg, pt, bt, pf, bf
                        pcall(function() c   = CGame:NewObjectFromPath("/Script/UMG.CanvasPanel", parent) end)
                        if not c or not WValid(c) then return false end
                        pcall(function() pf  = CGame:NewObjectFromPath("/Script/UMG.Border", c) end)
                        pcall(function() bf  = CGame:NewObjectFromPath("/Script/UMG.Border", c) end)
                        pcall(function() pbg = CGame:NewObjectFromPath("/Script/UMG.Border", c) end)
                        pcall(function() bbg = CGame:NewObjectFromPath("/Script/UMG.Border", c) end)
                        pcall(function() pt  = CGame:NewObjectFromPath("/Script/UMG.TextBlock", c) end)
                        pcall(function() bt  = CGame:NewObjectFromPath("/Script/UMG.TextBlock", c) end)
                        if not pbg or not bbg or not pt or not bt or not pf or not bf then
                            pcall(function() c:ConditionalBeginDestroy() end)
                            return false
                        end
                        local halfW = M.Width * 0.5
                        local FLC = FLinearColor
                        local ok = pcall(function()
                            pf:SetBrushColor(FLC and FLC(1.0, 0.2, 0.2, 1.0) or {R=1,G=0.2,B=0.2,A=1})
                            bf:SetBrushColor(FLC and FLC(0.2, 1.0, 0.2, 1.0) or {R=0.2,G=1,B=0.2,A=1})
                            pbg:SetBrushColor(FLC and FLC(0.05, 0.02, 0.02, 0.92) or {R=0.05,G=0.02,B=0.02,A=0.92})
                            bbg:SetBrushColor(FLC and FLC(0.02, 0.05, 0.02, 0.92) or {R=0.02,G=0.05,B=0.02,A=0.92})
                            pf:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                            bf:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                            pbg:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                            bbg:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                            local pfs = c:AddChildToCanvas(pf)
                            pfs:SetAutoSize(false)
                            pfs:SetPosition(FVector2D and FVector2D(-2,-2) or {X=-2,Y=-2})
                            pfs:SetSize(FVector2D and FVector2D(halfW+4, M.Height+4) or {X=halfW+4,Y=M.Height+4})
                            pfs:SetZOrder(-2)
                            local bfs = c:AddChildToCanvas(bf)
                            bfs:SetAutoSize(false)
                            bfs:SetPosition(FVector2D and FVector2D(halfW-2,-2) or {X=halfW-2,Y=-2})
                            bfs:SetSize(FVector2D and FVector2D(halfW+4, M.Height+4) or {X=halfW+4,Y=M.Height+4})
                            bfs:SetZOrder(-2)
                            local ps = c:AddChildToCanvas(pbg)
                            ps:SetAutoSize(false)
                            ps:SetPosition(FVector2D and FVector2D(0,0) or {X=0,Y=0})
                            ps:SetSize(FVector2D and FVector2D(halfW, M.Height) or {X=halfW,Y=M.Height})
                            ps:SetZOrder(0)
                            local bs = c:AddChildToCanvas(bbg)
                            bs:SetAutoSize(false)
                            bs:SetPosition(FVector2D and FVector2D(halfW,0) or {X=halfW,Y=0})
                            bs:SetSize(FVector2D and FVector2D(halfW, M.Height) or {X=halfW,Y=M.Height})
                            bs:SetZOrder(0)
                            pt:SetText("REAL: 0"); bt:SetText("BOT: 0")
                            pt:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                            bt:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                            if pt.SetJustification then pt:SetJustification(1) end
                            if bt.SetJustification then bt:SetJustification(1) end
                            if pt.Font then local f=pt.Font f.Size=M.FontSize pt:SetFont(f) end
                            if bt.Font then local f=bt.Font f.Size=M.FontSize bt:SetFont(f) end
                            local pts = c:AddChildToCanvas(pt)
                            pts:SetAutoSize(true)
                            pts:SetAlignment(FVector2D and FVector2D(0.5,0.5) or {X=0.5,Y=0.5})
                            pts:SetPosition(FVector2D and FVector2D(halfW*0.5, M.Height*0.5) or {X=halfW*0.5,Y=M.Height*0.5})
                            pts:SetZOrder(2)
                            local bts = c:AddChildToCanvas(bt)
                            bts:SetAutoSize(true)
                            bts:SetAlignment(FVector2D and FVector2D(0.5,0.5) or {X=0.5,Y=0.5})
                            bts:SetPosition(FVector2D and FVector2D(halfW+halfW*0.5, M.Height*0.5) or {X=halfW+halfW*0.5,Y=M.Height*0.5})
                            bts:SetZOrder(2)
                            local slot = parent:AddChildToCanvas(c)
                            slot:SetAutoSize(false)
                            slot:SetSize(FVector2D and FVector2D(M.Width, M.Height) or {X=M.Width,Y=M.Height})
                            slot:SetZOrder(50)
                            M.Slot = slot
                        end)
                        if not ok then
                            pcall(function() c:ConditionalBeginDestroy() end)
                            return false
                        end
                        M.Container, M.PlayerBGWidget, M.BotBGWidget = c, pbg, bbg
                        M.PlayerText, M.BotText = pt, bt
                        M.PlayerFrame, M.BotFrame = pf, bf
                        M._LastPlayers, M._LastBots = -1, -1
                        M._LastX, M._LastY = nil, nil
                        return true
                    end

                    function M.SetCounts(realCount, botCount)
                        realCount = tonumber(realCount) or 0
                        botCount  = tonumber(botCount)  or 0
                        if M._LastPlayers ~= realCount and WValid(M.PlayerText) then
                            local ok = pcall(function()
                                return M.PlayerText:SetText(string.format("REAL: %d", realCount)) ~= false
                            end)
                            if ok then M._LastPlayers = realCount end
                        end
                        if M._LastBots ~= botCount and WValid(M.BotText) then
                            local ok = pcall(function()
                                return M.BotText:SetText(string.format("BOT: %d", botCount)) ~= false
                            end)
                            if ok then M._LastBots = botCount end
                        end
                        local now = os.clock()
                        if WValid(M.PlayerFrame) then pcall(function() M.PlayerFrame:SetBrushColor(RainbowColor(now, 0)) end) end
                        if WValid(M.BotFrame) then pcall(function() M.BotFrame:SetBrushColor(RainbowColor(now, 1.5)) end) end
                    end

                    function M.UpdatePosition(pc)
                        if not M.Slot or not WValid(M.Slot) then return end
                        if not pc or not ESPBoxRenderer.IsValid(pc) then return end
                        local vw, vh = nil, nil
                        pcall(function()
                            local s = FVector2D and FVector2D(0,0) or {X=0,Y=0}
                            pc:GetViewportSize(s)
                            if s and s.X and s.X > 200 then vw, vh = s.X, s.Y end
                        end)
                        if not vw then
                            pcall(function()
                                if WidgetLayoutLibrary and WidgetLayoutLibrary.GetViewportSize then
                                    local s = WidgetLayoutLibrary.GetViewportSize(pc)
                                    if s and s.X and s.X > 200 then vw, vh = s.X, s.Y end
                                end
                            end)
                        end
                        if not vw then vw, vh = 1920, 1080 end
                        local sx = ESPBoxRenderer._CanvasScaleX or 1.0
                        local sy = ESPBoxRenderer._CanvasScaleY or 1.0
                        local ox = ESPBoxRenderer._CanvasOffsetX or 0
                        local oy = ESPBoxRenderer._CanvasOffsetY or 0
                        local x = (vw * 0.5) * sx + ox - M.Width * 0.5
                        local y = M.OffsetY * sy + oy
                        if M._LastX and M._LastY
                            and math.abs(M._LastX - x) < 0.1 and math.abs(M._LastY - y) < 0.1 then
                            return
                        end
                        pcall(function() M.Slot:SetPosition(FVector2D and FVector2D(x,y) or {X=x,Y=y}) end)
                        M._LastX, M._LastY = x, y
                    end

                    function M.Hide()
                        if WValid(M.Container) then
                            pcall(function() M.Container:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
                        end
                    end

                    function M.Destroy()
                        local c = M.Container
                        M.Container, M.Slot = nil, nil
                        M.PlayerBGWidget, M.BotBGWidget = nil, nil
                        M.PlayerText, M.BotText = nil, nil
                        M.PlayerFrame, M.BotFrame = nil, nil
                        M._LastPlayers, M._LastBots = -1, -1
                        M._LastX, M._LastY = nil, nil
                        if WValid(c) then
                            pcall(function() c:RemoveFromParent() end)
                            pcall(function() c:ConditionalBeginDestroy() end)
                        end
                    end
                    _G.EnemyCounterOverlay = M
                    return M
                end)()

                -- ============================================================
                -- WALLHACK RENDERER
                -- ============================================================
                WallhackRenderer = (function()
                    local M = {}
                    local FLinearColor = _G.FLinearColor or import("LinearColor")
                    M.ConsoleReady = false
                    M.ProcessedPawns  = {}
                    M.ProcessedMeshes = setmetatable({}, {__mode = "k"})
                    M.Timer, M.TimerOwner, M.Active = nil, nil, false
                    M.TickInterval = 0.5
                    M.AvatarSlots = {0,1,2,3,4,5,6,7}
                    M._LastWorld = nil
                    M.Colors = {
                        RealVisible  = FLinearColor and FLinearColor(100, 0,   0,   100) or {R=100,G=0,B=0,A=100},
                        RealOccluded = FLinearColor and FLinearColor(0,   100, 0,   100) or {R=0,G=100,B=0,A=100},
                        BotVisible   = FLinearColor and FLinearColor(100, 1,   0,   100) or {R=100,G=1,B=0,A=100},
                        BotOccluded  = FLinearColor and FLinearColor(0,   10,  10,  100) or {R=0,G=10,B=10,A=100},
                    }

                    local function SetupConsole()
                        if M.ConsoleReady then return true end
                        local ok = false
                        pcall(function()
                            local KSL   = import("KismetSystemLibrary")
                            local world = slua.getWorld()
                            if not KSL or not world then return end
                            KSL.ExecuteConsoleCommand(world, "r.EnableDrawDyeingColor 1")
                            KSL.ExecuteConsoleCommand(world, "r.CustomDepth 3")
                            KSL.ExecuteConsoleCommand(world, "r.IdeaOutline.Enable 1")
                            KSL.ExecuteConsoleCommand(world, "r.Highlight.Enable 1")
                            ok = true
                        end)
                        M.ConsoleReady = ok
                        return ok
                    end

                    local function ApplyToMesh(mesh, visColor, occColor)
                        if not mesh or not slua.isValid(mesh) then return end
                        if M.ProcessedMeshes[mesh] then return end
                        pcall(function()
                            mesh:SetDrawDyeing(true)
                            mesh:SetDrawDyeingMode(1)
                            mesh:SetVisibleDyeingColor(visColor)
                            mesh:SetOccludedDyeingColor(occColor)
                            mesh:SetDyeingColorFadeDistance(99999.0)
                            mesh:SetDyeingColorMinMaxDistance(0.0, 99999.0)
                            mesh:SetDrawHighlight(true)
                            mesh:OverrideHighlightColor(visColor)
                            mesh:SetHighlightCanBeOccluded(false)
                            mesh:SetDrawIdeaOutline(true)
                            mesh:SetIdeaOutlineNew(true)
                            mesh:SetIdeaOutlineOcclusionHighlight(true)
                            mesh:OverrideIdeaOutlineColor(visColor)
                            mesh:SetIdeaOutlineOcclusionColor(occColor)
                            mesh:OverrideIdeaOutlineThickness(20.0)
                            mesh:SetIdeaOverrideOutlineAndOcclusion(true)
                            mesh:SetRenderCustomDepth(true)
                            mesh:SetCustomDepthStencilValue(255)
                        end)
                        M.ProcessedMeshes[mesh] = true
                    end

                    local function ClearMesh(mesh)
                        if not mesh or not slua.isValid(mesh) then return end
                        pcall(function()
                            mesh:SetDrawDyeing(false)
                            mesh:SetDrawHighlight(false)
                            mesh:SetDrawIdeaOutline(false)
                            mesh:SetRenderCustomDepth(false)
                        end)
                        M.ProcessedMeshes[mesh] = nil
                    end

                    local function CollectAllMeshes(pawn)
                        local meshes = {}
                        if slua.isValid(pawn.Mesh) then table.insert(meshes, pawn.Mesh) end
                        local avatarComp = pawn.CharacterAvatarComp2_BP
                            or (pawn.getAvatarComponent2 and pawn:getAvatarComponent2())
                        if avatarComp and avatarComp.GetMeshCompBySlot then
                            for _, slot in ipairs(M.AvatarSlots) do
                                local mesh = avatarComp:GetMeshCompBySlot(slot)
                                if slua.isValid(mesh) then table.insert(meshes, mesh) end
                            end
                        end
                        pcall(function()
                            local SK = import("SkeletalMeshComponent")
                            if SK then
                                local comps = pawn:GetComponentsByClass(SK)
                                if comps then
                                    for i = 0, comps:Num() - 1 do
                                        local comp = comps:Get(i)
                                        if slua.isValid(comp) and comp ~= pawn.Mesh then
                                            table.insert(meshes, comp)
                                        end
                                    end
                                end
                            end
                        end)
                        local weapon = pawn.GetCurrentWeapon and pawn:GetCurrentWeapon()
                        if slua.isValid(weapon) and slua.isValid(weapon.Mesh) then
                            table.insert(meshes, weapon.Mesh)
                        end
                        return meshes
                    end

                    local function ClearAllProcessed()
                        for mesh in pairs(M.ProcessedMeshes) do ClearMesh(mesh) end
                        M.ProcessedMeshes = setmetatable({}, {__mode = "k"})
                        M.ProcessedPawns = {}
                    end

                    local function Tick()
                        if not M.Active then return end
                        if isExpired then return end
                        if not _G.GTLMODConfig.WallhackSmart then return end
                        local world = nil
                        pcall(function() world = slua and slua.getWorld and slua.getWorld() end)
                        if world ~= M._LastWorld then
                            M._LastWorld = world
                            ClearAllProcessed()
                            M.ConsoleReady = false
                        end
                        pcall(function()
                            local localPawn = GameplayData.GetPlayerCharacter()
                            if not slua.isValid(localPawn) then return end
                            if not SetupConsole() then return end
                            local myTeamId = localPawn.TeamID or 0
                            local allPawns = Game:GetAllPlayerPawns() or {}
                            for key, data in pairs(M.ProcessedPawns) do
                                local pawn = data.pawn
                                if not slua.isValid(pawn) then M.ProcessedPawns[key] = nil
                                else
                                    local dead = false
                                    pcall(function()
                                        if pawn:IsDead() or pawn.bIsDead or pawn.bHidden
                                            or (pawn.Mesh and pawn.Mesh.bHidden) then dead = true end
                                    end)
                                    if dead then M.ProcessedPawns[key] = nil end
                                end
                            end
                            for _, pawn in pairs(allPawns) do
                                if slua.isValid(pawn) and pawn ~= localPawn
                                    and (pawn.TeamID == nil or pawn.TeamID ~= myTeamId) then
                                    local alive = true
                                    pcall(function()
                                        if pawn.Health and pawn.Health <= 0 then alive = false end
                                        if pawn:IsDead() or pawn.bIsDead then alive = false end
                                    end)
                                    if alive then
                                        local key = tostring(pawn.PlayerKey or pawn)
                                        if not M.ProcessedPawns[key] then M.ProcessedPawns[key] = {pawn = pawn} end
                                        local isAI = ESPBoxRenderer and ESPBoxRenderer.IsAI(pawn, key) or false
                                        local vis = isAI and M.Colors.BotVisible or M.Colors.RealVisible
                                        local occ = isAI and M.Colors.BotOccluded or M.Colors.RealOccluded
                                        local meshes = CollectAllMeshes(pawn)
                                        for _, m in ipairs(meshes) do ApplyToMesh(m, vis, occ) end
                                    end
                                end
                            end
                        end)
                    end

                    function M.Start()
                        if M.Active then return true end
                        local owner = nil
                        pcall(function()
                            if GameplayData and GameplayData.GetPlayerController then
                                owner = GameplayData.GetPlayerController()
                            end
                        end)
                        if not owner or type(owner.AddGameTimer) ~= "function" then return false end
                        M.Active = true
                        local ok, timer = pcall(function() return owner:AddGameTimer(M.TickInterval, true, Tick) end)
                        if not ok or not timer then M.Active = false; return false end
                        M.Timer, M.TimerOwner = timer, owner
                        pcall(Tick)
                        return true
                    end

                    function M.Stop()
                        M.Active = false
                        if M.Timer and M.TimerOwner and type(M.TimerOwner.RemoveGameTimer) == "function" then
                            pcall(function() M.TimerOwner:RemoveGameTimer(M.Timer) end)
                        end
                        M.Timer, M.TimerOwner = nil, nil
                        ClearAllProcessed()
                        M.ConsoleReady = false
                    end
                    function M.IsActive() return M.Active end
                    _G.WallhackRenderer = M
                    return M
                end)()

                -- ============================================================
                -- NATIVE MARKS
                -- ============================================================
                local distanceMarkerConfig = {
                    UIPathName = "/Game/Mod/EvoBase/BluePrints/UIBP/QuickSign/QuickSign_TipHitEnemy_UIBP_New.QuickSign_TipHitEnemy_UIBP_New_C",
                    MaxWidgetNum = 99, MaxShowDistance = 6000000,
                    bBindOutScreen = true, bBindBlocked = true, bIsBindingActor = true,
                    BindSocketName = "head", bUseLuaWorldSocketName = true,
                    WorldPositionOffset = FVector(0, 0, 50), bNeedPreLoad = true, Priority = 2
                }

                local function InitDistanceMarkerSystem()
                    pcall(function()
                        local InGameMarkTools = require("GameLua.Mod.BaseMod.Common.InGameMarkTools")
                        if InGameMarkTools and InGameMarkTools.ScreenMarkManager
                            and InGameMarkTools.ScreenMarkManager.OnInitMarkGroupData then
                            InGameMarkTools.ScreenMarkManager:OnInitMarkGroupData(9999)
                        end
                        local gameplayTools = require("GameLua.Mod.BaseMod.Common.GamePlayTools")
                        local smc = gameplayTools.GetCurrentConfig("ScreenMarkConfig")
                        if smc then
                            if not smc[1006] then
                                smc[1006] = { UIPathName = distanceMarkerConfig.UIPathName,
                                    MaxWidgetNum = 99, MaxShowDistance = 6000000,
                                    bBindOutScreen = true, bBindBlocked = true, bIsBindingActor = true,
                                    BindSocketName = "head", bUseLuaWorldSocketName = true,
                                    WorldPositionOffset = FVector(0, 0, 50), bNeedPreLoad = true, Priority = 2 }
                            else
                                smc[1006].bBindBlocked = true
                                smc[1006].bBindOutScreen = true
                            end
                            smc[9999] = distanceMarkerConfig
                        end
                    end)
                end

                if not _G.AK_Active_Marks_Cache then _G.AK_Active_Marks_Cache = {} end

                local function SafeAddMark(id, pos, z, str, size, actor)
                    if not _G.GTLMODState.TrackedMarks then _G.GTLMODState.TrackedMarks = {} end
                    local count = 0
                    for _ in pairs(_G.GTLMODState.TrackedMarks) do count = count + 1 end
                    if count >= LIMITS.MAX_TRACKED_MARKS then return nil end
                    local mark = nil
                    pcall(function()
                        local InGameMarkTools = require("GameLua.Mod.BaseMod.Common.InGameMarkTools")
                        if InGameMarkTools and InGameMarkTools.ClientAddMapMark then
                            mark = InGameMarkTools.ClientAddMapMark(id, pos, z, str, size, actor)
                            if mark then _G.GTLMODState.TrackedMarks[mark] = true end
                        end                    end)
                    return mark
                end

                local function SafeRemoveMark(mark)
                    if not mark then return end
                    pcall(function()
                        local InGameMarkTools = require("GameLua.Mod.BaseMod.Common.InGameMarkTools")
                        if InGameMarkTools and InGameMarkTools.HideMapMark then InGameMarkTools.HideMapMark(mark) end
                        if InGameMarkTools and InGameMarkTools.RemoveMapMark then InGameMarkTools.RemoveMapMark(mark) end
                    end)
                    if _G.GTLMODState.TrackedMarks then _G.GTLMODState.TrackedMarks[mark] = nil end
                end

                local function GetSafeEnemyKey(enemy)
                    if Valid(enemy) then
                        if enemy.PlayerKey then return tostring(enemy.PlayerKey) end
                        if type(enemy.GetUniqueID) == "function" then return tostring(enemy:GetUniqueID()) end
                    end
                    return tostring(enemy)
                end

                local function createDistanceMarker(enemy)
                    if isExpired then return end
                    pcall(function()
                        local InGameMarkTools = require("GameLua.Mod.BaseMod.Common.InGameMarkTools")
                        if InGameMarkTools and InGameMarkTools.ClientAddMapMark then
                            enemy.NativeDistMark = InGameMarkTools.ClientAddMapMark(9999, FVector(0,0,0), 0, "", 4, enemy)
                            _G.AK_Active_Marks_Cache[tostring(enemy)] = {actor = enemy, distMark = enemy.NativeDistMark}
                        end
                    end)
                end

                local function removeDistanceMarker(enemy)
                    pcall(function()
                        local InGameMarkTools = require("GameLua.Mod.BaseMod.Common.InGameMarkTools")
                        if InGameMarkTools then
                            if InGameMarkTools.ClientRemoveMapMark then
                                InGameMarkTools.ClientRemoveMapMark(enemy.NativeDistMark)
                            elseif InGameMarkTools.HideMapMark then
                                InGameMarkTools.HideMapMark(enemy.NativeDistMark)
                            end
                        end
                        enemy.NativeDistMark = nil
                        _G.AK_Active_Marks_Cache[tostring(enemy)] = nil
                    end)
                end

                local function cleanupDeadEnemyMarks()
                    for key, data in pairs(_G.AK_Active_Marks_Cache) do
                        local remove = false
                        if not slua.isValid(data.actor) then remove = true
                        else
                            pcall(function()
                                local a = data.actor
                                if a.bHidden or (a.Mesh and a.Mesh.bHidden) then remove = true end
                                if type(a.IsDead) == "function" and a:IsDead() then remove = true
                                elseif a.bIsDead == true or a.bIsDeadFlag == true then remove = true end
                            end)
                        end
                        if remove then
                            pcall(function()
                                local InGameMarkTools = require("GameLua.Mod.BaseMod.Common.InGameMarkTools")
                                if InGameMarkTools and InGameMarkTools.ClientRemoveMapMark then
                                    InGameMarkTools.ClientRemoveMapMark(data.distMark)
                                end
                            end)
                            _G.AK_Active_Marks_Cache[key] = nil
                        end
                    end
                end

                local function processEnemyMapESP(enemy, localPlayer, isMapESPEnabled)
                    if isExpired then return end
                    if not slua.isValid(enemy) or enemy == localPlayer or enemy.TeamID == localPlayer.TeamID then return end
                    local isDead = false
                    pcall(function()
                        if type(enemy.IsDead) == "function" and enemy:IsDead() then isDead = true
                        elseif enemy.bIsDead then isDead = true end
                        if enemy.bHidden or (enemy.Mesh and enemy.Mesh.bHidden) then isDead = true end
                    end)
                    if not isDead then
                        if isMapESPEnabled == 1 then
                            if not enemy.bHasAKNativeMapMarker then
                                createDistanceMarker(enemy); enemy.bHasAKNativeMapMarker = true
                            end
                        else
                            if enemy.bHasAKNativeMapMarker then
                                removeDistanceMarker(enemy); enemy.bHasAKNativeMapMarker = false
                            end
                        end
                    else
                        if enemy.bHasAKNativeMapMarker then
                            removeDistanceMarker(enemy); enemy.bHasAKNativeMapMarker = false
                        end
                    end
                end

                -- ============================================================
                -- AUTO HEAD HOOKS
                -- ============================================================
                _G.InitializeAutoHeadHooks = function()
                    pcall(function()
                        local EAvatarDamagePosition = safeImport("EAvatarDamagePosition")
                        if not EAvatarDamagePosition then return end
                        for _, path in ipairs({"GameLua.Mod.BaseMod.Common.Weapon.ShootWeaponEntity", "GameLua.Logic.Weapon.ShootWeaponEntity"}) do
                            local hitLogic = package.loaded[path]
                            if hitLogic then
                                local orig1 = hitLogic.GetHitBodyType
                                hitLogic.GetHitBodyType = function(self, ImpactResult, InImpactVec)
                                    if _G.GTLMODConfig.AutoHead then return EAvatarDamagePosition.BigHead end
                                    if orig1 then return orig1(self, ImpactResult, InImpactVec) end
                                end
                                local orig2 = hitLogic.GetHitBodyTypeByHitPos
                                hitLogic.GetHitBodyTypeByHitPos = function(self, InImpactVec)
                                    if _G.GTLMODConfig.AutoHead then return EAvatarDamagePosition.BigHead end
                                    if orig2 then return orig2(self, InImpactVec) end
                                end
                            end
                        end
                    end)
                end
                pcall(_G.InitializeAutoHeadHooks)

                -- ============================================================
                -- ENEMY TARGETS
                -- ============================================================
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
                    local myTeam = 0
                    pcall(function() myTeam = player:GetTeamID() or player.TeamID or 0 end)
                    for _, actor in pairs(allCharacters) do
                        if slua.isValid(actor) and actor ~= player then
                            local isAlive = true
                            pcall(function()
                                if type(actor.IsAlive) == "function" then isAlive = actor:IsAlive()
                                elseif actor.HealthStatus ~= nil then isAlive = (actor.HealthStatus ~= 2)
                                elseif actor.bIsDead ~= nil then isAlive = not actor.bIsDead end
                            end)
                            if isAlive then
                                local teamId = -1
                                pcall(function()
                                    if type(actor.GetTeamID) == "function" then teamId = actor:GetTeamID()
                                    elseif actor.TeamID ~= nil then teamId = actor.TeamID end
                                end)
                                if teamId ~= myTeam then
                                    local dist = 999999
                                    pcall(function() dist = player:GetDistanceTo(actor) end)
                                    if dist <= radius then table.insert(result, actor) end
                                end
                            end
                        end
                    end
                    return result
                end

                local function GetTargetBonePos(target, boneName, fallbackZ)
                    local pos = nil
                    if type(target.GetBonePos) == "function" then
                        pcall(function() pos = target:GetBonePos(boneName, {X=0, Y=0, Z=0}) end)
                    end
                    if not pos or (pos.X == 0 and pos.Y == 0 and pos.Z == 0) then
                        pcall(function()
                            if slua.isValid(target.Mesh) and type(target.Mesh.GetSocketLocation) == "function" then
                                pos = target.Mesh:GetSocketLocation(boneName)
                            end
                        end)
                    end
                    if not pos or (pos.X == 0 and pos.Y == 0 and pos.Z == 0) then
                        pcall(function()
                            if type(target.K2_GetActorLocation) == "function" then
                                pos = target:K2_GetActorLocation()
                                if pos then pos.Z = pos.Z + (fallbackZ or 70) end
                            end
                        end)
                    end
                    return pos
                end

                local function TrimCache(cache, maxSize, now)
                    if not cache then return end
                    local count = 0
                    for _ in pairs(cache) do count = count + 1 end
                    if count <= maxSize then return end
                    local toRemove = {}
                    for k, v in pairs(cache) do
                        if type(v) == "table" and v.time and (now - v.time) > 30 then
                            table.insert(toRemove, k)
                        end
                    end
                    for _, k in ipairs(toRemove) do cache[k] = nil end
                    count = 0
                    for _ in pairs(cache) do count = count + 1 end
                    if count > maxSize then for k in pairs(cache) do cache[k] = nil end end
                end

                -- ============================================================
                -- AIMBOT — FIXED: NO AUTO-FIRE, SHOTGUN IS AIM-ASSIST ONLY
                -- ============================================================
                _G.AimTouch = function()
                    if not _G.GTLMODConfig.AimTouchEnable then return end
                    if not _G.GTLMODState.AimDebugErr then _G.GTLMODState.AimDebugErr = "starting" end

                    local player = GameplayData.GetPlayerCharacter()
                    if not slua.isValid(player) then _G.GTLMODState.AimLastFail = "no player"; return end
                    local pc = player:GetPlayerControllerSafety()
                    if not slua.isValid(pc) then _G.GTLMODState.AimLastFail = "no pc"; return end

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
                        elseif weapon.CurrentAmmo ~= nil then
                            currentAmmo = weapon.CurrentAmmo
                        end
                    end

                    -- ⚡ FIXED: only release fire state if WE set it (never auto-fire)
                    if _G.GTLMODState.IsAutoFiring then
                        local now = os.clock()
                        local fireStart = _G.GTLMODState.FireStartTime or 0
                        if now - fireStart > 0.1 then
                            pcall(function()
                                player.bIsWeaponFiring = false
                                if type(player.SetIsWeaponFiring) == "function" then player:SetIsWeaponFiring(false) end
                                if slua.isValid(pc) and type(pc.SetIsWeaponFiring) == "function" then pc:SetIsWeaponFiring(false) end
                                local wepMgr = player.WeaponManagerComponent
                                if slua.isValid(wepMgr) then wepMgr.bIsWeaponFiring = false end
                            end)
                            _G.GTLMODState.IsAutoFiring = false
                            _G.GTLMODState.FireStartTime = nil
                        end
                    end

                    if isShotgun and currentAmmo <= 0 then _G.GTLMODState.AimLastFail = "shotgun no ammo"; return end

                    local cond = 2
                    local boneIdx = 1
                    local speedVal = 50
                    local fovVal = 30
                    local maxDistMeters = 50
                    local useVisCheck = _G.GTLMODConfig.AimTouchVisCheck
                    local igKnock = _G.GTLMODConfig.AimTouchIgKnock
                    local igBot = _G.GTLMODConfig.AimTouchIgBot

                    -- ⚡ FIXED: shotgun is now aim-assist only (cond = 1 = only while firing)
                    if isShotgun then
                        cond = 1; boneIdx = 2; speedVal = 90; fovVal = 32; maxDistMeters = 30
                    elseif isADS then
                        if isSniper then
                            cond = 2; boneIdx = 1; speedVal = 85; fovVal = 28; maxDistMeters = 400
                        else
                            cond = 1; boneIdx = 2; speedVal = 85; fovVal = 28; maxDistMeters = 300
                        end
                    else
                        cond = 1; boneIdx = 1; speedVal = 85; fovVal = 28; maxDistMeters = 250
                    end

                    if cond == 1 and not isFiring then _G.GTLMODState.AimLastFail = "not firing"; return end

                    local currentMaxDist = maxDistMeters * 100
                    local enemies = _G.GetEnemyTargetsFromActors(currentMaxDist)
                    if not enemies or #enemies == 0 then _G.GTLMODState.AimLastFail = "no enemies"; return end

                    local FVector2D = safeImport("Vector2D")
                    local UGameplayStatics = safeImport("GameplayStatics")
                    local KismetMathLibrary = safeImport("KismetMathLibrary")
                    if not FVector2D or not UGameplayStatics or not KismetMathLibrary then return end

                    local camManager = UGameplayStatics.GetPlayerCameraManager(pc, 0)
                    if not slua.isValid(camManager) then _G.GTLMODState.AimLastFail = "no camManager"; return end
                    local camLoc = camManager:GetCameraLocation()
                    if not camLoc then _G.GTLMODState.AimLastFail = "no camLoc"; return end

                    local ui_util = require("client.common.ui_util")
                    if not ui_util then _G.GTLMODState.AimLastFail = "no ui_util"; return end
                    local viewportSize = ui_util.GetViewportSize()
                    if not viewportSize then _G.GTLMODState.AimLastFail = "no viewport"; return end

                    local centerX = viewportSize.X * 0.5
                    local centerY = viewportSize.Y * 0.5
                    local FOV_RADIUS = (fovVal / 100.0) * (viewportSize.X / 2.0)

                    local bestTarget = nil
                    local bestScore = 99999999
                    local selBoneName = "head"
                    if boneIdx == 2 then selBoneName = "spine_03"
                    elseif boneIdx == 3 then selBoneName = "spine_01"
                    elseif boneIdx == 4 then selBoneName = "pelvis" end

                    local now = os.clock()
                    _G.BotStatusCache = _G.BotStatusCache or {}
                    _G.AimTouchVisCache = _G.AimTouchVisCache or {}
                    if not _G.LastCacheTrim or (now - _G.LastCacheTrim) > 15 then
                        _G.LastCacheTrim = now
                        TrimCache(_G.BotStatusCache, LIMITS.MAX_BOT_CACHE, now)
                        TrimCache(_G.AimTouchVisCache, LIMITS.MAX_VIS_CACHE, now)
                    end

                    for i, target in ipairs(enemies) do
                        if slua.isValid(target) then
                            pcall(function()
                                if slua.isValid(target.Mesh) then target.Mesh.MeshComponentUpdateFlag = 0 end
                            end)
                            local skip = false
                            if igKnock and target.HealthStatus == 1 then skip = true end

                            if not skip and igBot then
                                local tId = type(target.GetUniqueID) == "function" and target:GetUniqueID() or tostring(target)
                                local cachedBot = _G.BotStatusCache[tId]
                                if cachedBot == nil then
                                    cachedBot = false
                                    if target.bIsAI == true or target.IsAI == true or target.bIsAi == true then cachedBot = true end
                                    if not cachedBot and target.AIData ~= nil then cachedBot = true end
                                    if not cachedBot and target.PlayerAIType ~= nil and target.PlayerAIType ~= 0 then cachedBot = true end
                                    if not cachedBot then
                                        local pState = target.PlayerState
                                        if slua.isValid(pState) then
                                            if pState.bIsABot or pState.bIsBot or pState.IsBot or pState.bIsAI then cachedBot = true end
                                        end
                                    end
                                    if not cachedBot and type(target.IsBot) == "function" then
                                        local ok, r = pcall(function() return target:IsBot() end)
                                        if ok and r then cachedBot = true end
                                    end
                                    _G.BotStatusCache[tId] = cachedBot
                                end
                                if cachedBot then skip = true end
                            end

                            if not skip and useVisCheck then
                                local tId = type(target.GetUniqueID) == "function" and target:GetUniqueID() or tostring(target)
                                local cacheEntry = _G.AimTouchVisCache[tId]
                                if not cacheEntry or (now - cacheEntry.time) > 0.2 then
                                    local isHidden = true
                                    pcall(function() if pc:LineOfSightTo(target) then isHidden = false end end)
                                    _G.AimTouchVisCache[tId] = { hidden = isHidden, time = now }
                                    cacheEntry = _G.AimTouchVisCache[tId]
                                end
                                if cacheEntry.hidden then skip = true end
                            end

                            if not skip then
                                local fallbackZ = (boneIdx == 1) and 70 or (boneIdx == 2) and 40 or (boneIdx == 3) and 20 or 0
                                local tPos = GetTargetBonePos(target, selBoneName, fallbackZ)
                                if tPos and (tPos.X ~= 0 or tPos.Y ~= 0) then
                                    local screen = FVector2D()
                                    local success = pc:ProjectWorldLocationToScreen(tPos, screen, false)
                                    if success and screen.X > 0 and screen.Y > 0 then
                                        local dx = screen.X - centerX
                                        local dy = screen.Y - centerY
                                        local distScreen = math.sqrt(dx*dx + dy*dy)
                                        if distScreen <= FOV_RADIUS then
                                            if distScreen < bestScore then
                                                bestScore = distScreen
                                                bestTarget = target
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end

                    if not slua.isValid(bestTarget) then _G.GTLMODState.AimLastFail = "no best target in FOV"; return end

                    local fallbackZ2 = (boneIdx == 1) and 70 or (boneIdx == 2) and 40 or (boneIdx == 3) and 20 or 0
                    local finalBonePos = GetTargetBonePos(bestTarget, selBoneName, fallbackZ2)
                    if not finalBonePos or (finalBonePos.X == 0 and finalBonePos.Y == 0) then _G.GTLMODState.AimLastFail = "no final bone pos"; return end

                    local rot = KismetMathLibrary.FindLookAtRotation(camLoc, finalBonePos)
                    if not rot then _G.GTLMODState.AimLastFail = "no rot"; return end

                    local currentRot = pc:GetControlRotation()
                    if not currentRot then _G.GTLMODState.AimLastFail = "no currentRot"; return end

                    local deltaYaw = rot.Yaw - currentRot.Yaw
                    local deltaPitch = rot.Pitch - currentRot.Pitch

                    if isADS then
                        local camRot = nil
                        if type(camManager.GetCameraRotation) == "function" then camRot = camManager:GetCameraRotation() end
                        if camRot then
                            deltaYaw = deltaYaw - (camRot.Yaw - currentRot.Yaw)
                            deltaPitch = deltaPitch - (camRot.Pitch - currentRot.Pitch)
                        end
                    end

                    if deltaYaw > 180 then deltaYaw = deltaYaw - 360 end
                    if deltaYaw < -180 then deltaYaw = deltaYaw + 360 end
                    if deltaPitch > 180 then deltaPitch = deltaPitch - 360 end
                    if deltaPitch < -180 then deltaPitch = deltaPitch + 360 end

                    local smoothFactor = (speedVal >= 100) and 1.0 or math.max(0.01, (speedVal / 100.0) * 0.35)

                    local finalPitch = currentRot.Pitch + (deltaPitch * smoothFactor)
                    local finalYaw = currentRot.Yaw + (deltaYaw * smoothFactor)
                    local finalRot = { Pitch = finalPitch, Yaw = finalYaw, Roll = 0 }

                    local okRot = pcall(function() pc:SetControlRotation(finalRot, "AimTouch") end)
                    if not okRot then pcall(function() pc:SetControlRotation(finalRot) end) end

                    _G.GTLMODState.AimLastFail = "OK"

                    -- ⚡ REMOVED: shotgun auto-fire block. Shotgun is now aim-assist only.
                end

                -- ============================================================
                -- MAIN LOOP (no auto-fire; keeps graphics, weapon mods, native marks)
                -- ============================================================
                local function MainLoop()
                    if isExpired then return end
                    local pc = GameplayData.GetPlayerController()
                    local localPlayer = nil
                    if Valid(pc) then localPlayer = pc:GetPlayerCharacterSafety() end

                    if not Valid(localPlayer) then
                        if _G.GTLMODState.TrackedMarks then
                            for markId, _ in pairs(_G.GTLMODState.TrackedMarks) do SafeRemoveMark(markId) end
                        end
                        _G.GTLMODState.TrackedMarks = {}
                        _G.GTLMODState.EnemyMarks = {}
                        _G.GTLMODState.PrevGraphicsState = {}
                        _G.BotStatusCache = {}
                        _G.AimTouchVisCache = {}
                        _G.GTLMODState.MidCacheCount = 0
                        return
                    end

                    local Cached_MyHUD = pc and pc.MyHUD or nil

                    -- Unlock FPS
                    if _G.GTLMODConfig.UnlockFPS and not _G.GTLMODState.GraphicsUnlocked then
                        pcall(function()
                            local SettingCfg = require("client.logic.setting.setting_config")
                            local GraphicSettingDB = require("client.slua.umg.NewSetting.GraphicsNew.GraphicSettingDB")
                            if SettingCfg then
                                if SettingCfg.TpViewValue then SettingCfg.TpViewValue.max = 160 end
                                if SettingCfg.FpViewValue then SettingCfg.FpViewValue.max = 160 end
                            end
                            if GraphicSettingDB and GraphicSettingDB.TpViewValue then GraphicSettingDB.TpViewValue.max = 160 end
                        end)
                        _G.GTLMODState.GraphicsUnlocked = true
                    end

                    -- iPad View
                    pcall(function()
                        local uTPPCam = localPlayer.ThirdPersonCameraComponent
                        if Valid(uTPPCam) and not localPlayer.bIsWeaponAiming then
                            local target = _G.GTLMODConfig.IpadView
                                and (_G.GTLMODState.CustomTextData.IpadViewFOV or 120) or 80
                            if uTPPCam.FieldOfView ~= target then uTPPCam.FieldOfView = target end
                        end
                    end)

                    -- Higgs reset
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
                            if not _G.GTLMODState.OrigAutoAimCompCached then
                                _G.GTLMODState.OrigAutoAimCompCached = {
                                    bOnlyHitHead = autoComp.bOnlyHitHead,
                                    HeadBoneName = autoComp.HeadBoneName,
                                    Bones = autoComp.Bones,
                                    ChestBoneName = autoComp.ChestBoneName,
                                    PelvisBoneName = autoComp.PelvisBoneName,
                                }
                            end
                            if _G.GTLMODConfig.AutoHead then
                                autoComp.bOnlyHitHead = true
                                autoComp.HeadBoneName = "Head"
                                pcall(function() autoComp.Bones = {"Head"} end)
                                autoComp.ChestBoneName = "Head"
                                autoComp.PelvisBoneName = "Head"
                            else
                                local orig = _G.GTLMODState.OrigAutoAimCompCached
                                autoComp.bOnlyHitHead = orig.bOnlyHitHead
                                autoComp.HeadBoneName = orig.HeadBoneName
                                pcall(function() autoComp.Bones = orig.Bones or {"Spine_01", "Pelvis", "Head"} end)
                                autoComp.ChestBoneName = orig.ChestBoneName
                                autoComp.PelvisBoneName = orig.PelvisBoneName
                            end
                        end
                    end)

                    -- Graphics toggles
                    pcall(function()
                        local lsg = require("client.slua.logic.setting.logic_setting_graphics")
                        local gi = lsg.GetGameInstance()
                        if gi then
                            if _G.GTLMODConfig.RemoveGrass and not _G.GTLMODState.PrevGraphicsState.RemoveGrass then
                                gi:ExecuteCMD("grass.DensityScale", "0"); gi:ExecuteCMD("grass.DiscardDataOnLoad", "1")
                                _G.GTLMODState.PrevGraphicsState.RemoveGrass = true
                            elseif not _G.GTLMODConfig.RemoveGrass and _G.GTLMODState.PrevGraphicsState.RemoveGrass then
                                gi:ExecuteCMD("grass.DensityScale", "1"); gi:ExecuteCMD("grass.DiscardDataOnLoad", "0")
                                _G.GTLMODState.PrevGraphicsState.RemoveGrass = false
                            end
                            if _G.GTLMODConfig.RemoveFog and not _G.GTLMODState.PrevGraphicsState.RemoveFog then
                                gi:ExecuteCMD("r.SkyAtmosphere", "1"); gi:ExecuteCMD("r.Fog", "0"); gi:ExecuteCMD("r.VolumetricFog", "0")
                                _G.GTLMODState.PrevGraphicsState.RemoveFog = true
                            elseif not _G.GTLMODConfig.RemoveFog and _G.GTLMODState.PrevGraphicsState.RemoveFog then
                                gi:ExecuteCMD("r.SkyAtmosphere", "1"); gi:ExecuteCMD("r.Fog", "1"); gi:ExecuteCMD("r.VolumetricFog", "1")
                                _G.GTLMODState.PrevGraphicsState.RemoveFog = false
                            end
                            if _G.GTLMODConfig.ColorBodyV2 and not _G.GTLMODState.PrevGraphicsState.ColorBodyV2 then
                                gi:ExecuteCMD("r.CharacterMinShadowFactor", "4")
                                gi:ExecuteCMD("r.CharacterDiffuseOffset", "200")
                                gi:ExecuteCMD("r.CharacterDiffusePower", "200")
                                _G.GTLMODState.PrevGraphicsState.ColorBodyV2 = true
                            elseif not _G.GTLMODConfig.ColorBodyV2 and _G.GTLMODState.PrevGraphicsState.ColorBodyV2 then
                                gi:ExecuteCMD("r.CharacterMinShadowFactor", "1")
                                gi:ExecuteCMD("r.CharacterDiffuseOffset", "0")
                                gi:ExecuteCMD("r.CharacterDiffusePower", "1")
                                _G.GTLMODState.PrevGraphicsState.ColorBodyV2 = false
                            end
                            if _G.GTLMODConfig.BlackSky and not _G.GTLMODState.PrevGraphicsState.BlackSky then
                                gi:ExecuteCMD("r.CylinderMaxDrawHeight", "9999")
                                _G.GTLMODState.PrevGraphicsState.BlackSky = true
                            elseif not _G.GTLMODConfig.BlackSky and _G.GTLMODState.PrevGraphicsState.BlackSky then
                                gi:ExecuteCMD("r.CylinderMaxDrawHeight", "0000")
                                _G.GTLMODState.PrevGraphicsState.BlackSky = false
                            end
                        end
                    end)

                    -- Weapon mods
                    pcall(function()
                        local weapon = nil
                        pcall(function()
                            local weaponManager = localPlayer.WeaponManagerComponent
                            if Valid(weaponManager) and type(weaponManager.GetCurrentWeapon) == "function" then weapon = weaponManager:GetCurrentWeapon() end
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
                                local anyModOn = _G.GTLMODConfig.CustomHRecoil or _G.GTLMODConfig.CustomVRecoil or _G.GTLMODConfig.LessShake or _G.GTLMODConfig.Accuracy or _G.GTLMODConfig.Crosshair or _G.GTLMODConfig.GodMode
                                if anyModOn then
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
                                    if _G.GTLMODConfig.CustomHRecoil then entity.AccessoriesHRecoilFactor = _G.GTLMODState.CustomTextData.HRecoil or 0.3 end
                                    if _G.GTLMODConfig.CustomVRecoil then entity.AccessoriesVRecoilFactor = _G.GTLMODState.CustomTextData.VRecoil or 0.3 end
                                    if _G.GTLMODConfig.LessShake then entity.RecoilKickADS = 0.0 end
                                    if _G.GTLMODConfig.Accuracy then entity.GameDeviationAccuracy = 0.0 end
                                    if _G.GTLMODConfig.Crosshair then entity.GameDeviationFactor = 0.0 end
                                    if _G.GTLMODConfig.GodMode then
                                        entity.BulletFireSpeed = 500000.0
                                        entity.ShootInterval = 0.001
                                        entity.BaseDamage = 60000.0
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
                                    entity.GTLMODWeaponModsActive = false
                                end
                            end
                        end
                    end)

                    -- Native marks + antenna + name
                    pcall(function()
                        local allCharacters = {}
                        if GameplayData.GetAllPlayerCharacters then
                            allCharacters = GameplayData.GetAllPlayerCharacters()
                        elseif GameplayData.GameCharacters then
                            for _, char in pairs(GameplayData.GameCharacters) do table.insert(allCharacters, char) end
                        end
                        local currentValidKeys = {}
                        for _, enemy in pairs(allCharacters) do
                            if Valid(enemy) and enemy ~= localPlayer then
                                currentValidKeys[GetSafeEnemyKey(enemy)] = true
                            end
                        end
                        for key, data in pairs(_G.GTLMODState.EnemyMarks) do
                            if not currentValidKeys[key] then
                                SafeRemoveMark(data.radarMark)
                                SafeRemoveMark(data.hpMark)
                                SafeRemoveMark(data.distMark)
                                SafeRemoveMark(data.hpMark8)
                                _G.GTLMODState.EnemyMarks[key] = nil
                            end
                        end
                        for _, enemy in pairs(allCharacters) do
                            if Valid(enemy) and enemy ~= localPlayer and enemy.TeamID ~= localPlayer.TeamID then
                                local eKey = GetSafeEnemyKey(enemy)
                                _G.GTLMODState.EnemyMarks[eKey] = _G.GTLMODState.EnemyMarks[eKey] or { enemy = enemy }
                                local markData = _G.GTLMODState.EnemyMarks[eKey]
                                markData.enemy = enemy
                                local bIsReallyDead = false
                                pcall(function()
                                    if type(enemy.IsDead) == "function" then bIsReallyDead = enemy:IsDead()
                                    elseif enemy.bIsDead ~= nil then bIsReallyDead = enemy.bIsDead
                                    elseif enemy.bIsDeadFlag ~= nil then bIsReallyDead = enemy.bIsDeadFlag end
                                    if enemy.HealthStatus ~= nil and enemy.HealthStatus == 2 then bIsReallyDead = true end
                                end)
                                if not bIsReallyDead then
                                    local distM = 0
                                    pcall(function() distM = localPlayer:GetDistanceTo(enemy) / 100 end)
                                    local MyHUD = Cached_MyHUD
                                    if Valid(MyHUD) then
                                        if _G.GTLMODConfig.EspAntenna and distM <= 400 then
                                            pcall(function()
                                                local loopCount = IS_32BIT and 4 or 8
                                                local zStep = 1000
                                                for i = 1, loopCount do
                                                    local zOffset = 105 + (i * zStep)
                                                    MyHUD:AddDebugText("|", enemy, 0.06, {X=0,Y=0,Z=zOffset}, {X=0,Y=0,Z=zOffset}, C_GREEN, true, false, true, nil, 1.2, true)
                                                end
                                            end)
                                        end
                                        if _G.GTLMODConfig.EspName and distM <= LIMITS.ESP_MAX_DISTANCE then
                                            pcall(function()
                                                local pName = enemy.PlayerName or "Enemy"
                                                local isKnock = (enemy.Health or 100) <= 0 or enemy.HealthStatus == 1
                                                local bVis = true
                                                pcall(function() if pc and type(pc.LineOfSightTo) == "function" then bVis = pc:LineOfSightTo(enemy) end end)
                                                local color = isKnock and C_BLUE or (bVis and C_GREEN or C_RED)
                                                MyHUD:AddDebugText(pName, enemy, 0.2, {X=0,Y=0,Z=120}, {X=0,Y=0,Z=120}, color, true, false, true, nil, 1.0, true)
                                            end)
                                        end
                                    end
                                    if _G.GTLMODConfig.EspVip then
                                        if markData.hpMark == nil then markData.hpMark = SafeAddMark(1006, FVector(0,0,0), 0, "", 4, enemy) end
                                        if markData.distMark == nil then markData.distMark = SafeAddMark(9999, FVector(0,0,0), 0, "", 4, enemy) end
                                    end
                                    if _G.GTLMODConfig.EspRadar then
                                        if not markData.radarMark or markData.radarMark == 0 then
                                            markData.radarMark = SafeAddMark(8888, FVector(0,0,0), 0, "", 4, enemy)
                                        end
                                    else
                                        if markData.radarMark and markData.radarMark ~= 0 then
                                            SafeRemoveMark(markData.radarMark); markData.radarMark = nil
                                        end
                                    end
                                end
                            end
                        end
                    end)

                    if _G.GTLMODConfig.AimDebug and Valid(Cached_MyHUD) then
                        pcall(function()
                            local status = _G.GTLMODState.AimLastFail or "?"
                            local enemies = _G.GetEnemyTargetsFromActors(25000)
                            local cnt = enemies and #enemies or 0
                            local txt = string.format("[AIM] %s | Enemies: %d", status, cnt)
                            Cached_MyHUD:AddDebugText(txt, localPlayer, 0.1, {X=0,Y=0,Z=200}, {X=0,Y=0,Z=200}, C_YELLOW, true, false, true, nil, 1.0, true)
                        end)
                    end
                end

                _G.GTLMODState.LoopToken = (_G.GTLMODState.LoopToken or 0) + 1
                local myToken = _G.GTLMODState.LoopToken

                local function MainTick()
                    if isExpired then return end
                    if myToken ~= _G.GTLMODState.LoopToken then return end
                    pcall(MainLoop)
                    local okTicker, ticker = pcall(require, "common.time_ticker")
                    if okTicker and ticker and ticker.AddTimerOnce then
                        ticker.AddTimerOnce(LIMITS.MAIN_TICK, MainTick)
                    end
                end

                local function AimbotTick()
                    if isExpired then return end
                    if myToken ~= _G.GTLMODState.LoopToken then return end
                    if _G.GTLMODConfig.AimTouchEnable then
                        pcall(_G.AimTouch)
                    end
                    local okTicker, ticker = pcall(require, "common.time_ticker")
                    if okTicker and ticker and ticker.AddTimerOnce then
                        ticker.AddTimerOnce(LIMITS.AIMBOT_TICK, AimbotTick)
                    end
                end

                -- ⚡ NEW: ESP + COUNTER driven by ticker (survives respawn / map change)
                local function ESPTick()
                    if isExpired then return end
                    if myToken ~= _G.GTLMODState.LoopToken then return end
                    if _G.GTLMODConfig.EspBox or _G.GTLMODConfig.EspLine
                       or _G.GTLMODConfig.EspHealth or _G.GTLMODConfig.EspDistance
                       or _G.GTLMODConfig.CounterEnabled then
                        if ESPBoxRenderer then
                            if not ESPBoxRenderer.IsActive() then ESPBoxRenderer.Start() end
                            pcall(ESPBoxRenderer.TickOnce)
                        end
                    end
                    local okTicker, ticker = pcall(require, "common.time_ticker")
                    if okTicker and ticker and ticker.AddTimerOnce then
                        ticker.AddTimerOnce(LIMITS.ESP_TICK, ESPTick)
                    end
                end

                local function BypassRefreshLoop()
                    if isExpired then return end
                    if myToken ~= _G.GTLMODState.LoopToken then return end
                    pcall(_G.StartBypass_VIP_v3)
                    pcall(AggressiveReset)
                    local okTicker, ticker = pcall(require, "common.time_ticker")
                    if okTicker and ticker and ticker.AddTimerOnce then
                        ticker.AddTimerOnce(5.0, BypassRefreshLoop)
                    end
                end

                if not isExpired then
                    local okTicker, ticker = pcall(require, "common.time_ticker")
                    if okTicker and ticker and ticker.AddTimerOnce then
                        ticker.AddTimerOnce(0.2, MainTick)
                        ticker.AddTimerOnce(0.2, AimbotTick)
                        ticker.AddTimerOnce(0.5, ESPTick)
                        ticker.AddTimerOnce(5.0, BypassRefreshLoop)
                    end
                end

                -- ============================================================
                -- MOD MENU (every toggle calls SyncRenderers)
                -- ============================================================
                function _G.InitModMenuTab()
                    if _G.ModMenuInitialized then return end
                    _G.ModMenuInitialized = true

                    local LocUtil = _G.LocUtil
                    if not LocUtil and package.loaded["client.common.LocUtil"] then
                        LocUtil = require("client.common.LocUtil")
                    end
                    if LocUtil and not LocUtil._IsModMenuHooked then
                        local old_get = LocUtil.GetLocalizeResStr
                        LocUtil.GetLocalizeResStr = function(id)
                            if type(id) == "string" and not tonumber(id) then return id end
                            return old_get(id)
                        end
                        LocUtil._IsModMenuHooked = true
                    end

                    local SettingPageDefine = require("client.logic.NewSetting.SettingPageDefine")
                    local SettingCatalog = require("client.logic.NewSetting.SettingCatalog")

                    if not SettingPageDefine.ModMenu then
                        local AliasMap = require("client.slua.umg.NewSetting.Item.AliasMap")
                        local C = _G.GTLMODConfig

                        -- ⚡ SyncRenderers — makes toggle work instantly
                        local function SyncRenderers()
                            -- ESP family
                            if ESPBoxRenderer then
                                if C.EspBox and not ESPBoxRenderer.IsActive() then
                                    ESPBoxRenderer.Start()
                                end
                            end
                            if not C.EspBox and ESPBoxRenderer then
                                ESPBoxRenderer.ClearAllBoxes()
                            end
                            if not C.EspLine and ESPLineRenderer then ESPLineRenderer.ClearAll() end
                            if not C.EspHealth and ESPHealthRenderer then ESPHealthRenderer.ClearAll() end
                            if not C.EspDistance and ESPDistanceRenderer then ESPDistanceRenderer.ClearAll() end
                            if not C.CounterEnabled and EnemyCounterOverlay then EnemyCounterOverlay.Hide() end

                            -- Wallhack
                            if WallhackRenderer then
                                if C.WallhackSmart and not WallhackRenderer.IsActive() then
                                    WallhackRenderer.Start()
                                elseif not C.WallhackSmart and WallhackRenderer.IsActive() then
                                    WallhackRenderer.Stop()
                                end
                            end

                            -- Aimbot release on off
                            if not C.AimTouchEnable then
                                _G.GTLMODState.IsAutoFiring = false
                                _G.GTLMODState.FireStartTime = nil
                            end

                            -- Auto Head hooks reapply
                            if _G.InitializeAutoHeadHooks then pcall(_G.InitializeAutoHeadHooks) end

                            -- Bypass
                            if C.BypassEnabled and _G.StartBypass_VIP_v3 then
                                pcall(_G.StartBypass_VIP_v3)
                            end

                            -- Save immediately
                            if _G.SaveModSettings then
                                _G.LastConfigSaveTime = 0
                                pcall(_G.SaveModSettings)
                            end
                        end
                        _G.SyncRenderers = SyncRenderers

                        local StackESPVisual = {
                            { Key = "ModMenu_ESPBox", UI = AliasMap.Switcher, Text = "ESP 3D Box",
                              GetFunc = function() return C.EspBox end,
                              SetFunc = function(c,v) C.EspBox = v; SyncRenderers(); return true end },
                            { Key = "ModMenu_ESPHealth", UI = AliasMap.Switcher, Text = "ESP Health Bar",
                              GetFunc = function() return C.EspHealth end,
                              SetFunc = function(c,v) C.EspHealth = v; SyncRenderers(); return true end },
                            { Key = "ModMenu_ESPDistance", UI = AliasMap.Switcher, Text = "ESP Distance",
                              GetFunc = function() return C.EspDistance end,
                              SetFunc = function(c,v) C.EspDistance = v; SyncRenderers(); return true end },
                            { Key = "ModMenu_ESPLine", UI = AliasMap.Switcher, Text = "ESP Head Line (Blue=Vis, Red=Block)",
                              GetFunc = function() return C.EspLine end,
                              SetFunc = function(c,v) C.EspLine = v; SyncRenderers(); return true end },
                            { Key = "ModMenu_ESPAntenna", UI = AliasMap.Switcher, Text = "ESP Antenna",
                              GetFunc = function() return C.EspAntenna end,
                              SetFunc = function(c,v) C.EspAntenna = v; return true end },
                            { Key = "ModMenu_ESPName", UI = AliasMap.Switcher, Text = "ESP Name",
                              GetFunc = function() return C.EspName end,
                              SetFunc = function(c,v) C.EspName = v; return true end },
                            { Key = "ModMenu_ESPVip", UI = AliasMap.Switcher, Text = "ESP VIP (Native)",
                              GetFunc = function() return C.EspVip end,
                              SetFunc = function(c,v) C.EspVip = v; return true end },
                            { Key = "ModMenu_ESPRadar", UI = AliasMap.Switcher, Text = "ESP Radar 360",
                              GetFunc = function() return C.EspRadar end,
                              SetFunc = function(c,v) C.EspRadar = v; return true end },
                            { Key = "ModMenu_Counter", UI = AliasMap.Switcher, Text = "Player/Bot Counter",
                              GetFunc = function() return C.CounterEnabled end,
                              SetFunc = function(c,v) C.CounterEnabled = v; SyncRenderers(); return true end },
                        }

                        local StackWallhack = {
                            { Key = "ModMenu_WallhackSmart", UI = AliasMap.Switcher, Text = "Wallhack (Mesh Dye)",
                              GetFunc = function() return C.WallhackSmart end,
                              SetFunc = function(c,v) C.WallhackSmart = v; SyncRenderers(); return true end },
                            { Key = "ModMenu_WallColor", UI = AliasMap.Switcher, Text = "Body Color V2",
                              GetFunc = function() return C.ColorBodyV2 end,
                              SetFunc = function(c,v) C.ColorBodyV2 = v; return true end },
                        }

                        local StackAimbot = {
                            { Key = "ModMenu_AT_Enable", UI = AliasMap.Switcher, Text = "AimTouch Enable (Aim Assist)",
                              GetFunc = function() return C.AimTouchEnable end,
                              SetFunc = function(c,v) C.AimTouchEnable = v; SyncRenderers(); return true end },
                            { Key = "ModMenu_AT_IgKnock", UI = AliasMap.Switcher, Text = "Ignore Knocked",
                              GetFunc = function() return C.AimTouchIgKnock end,
                              SetFunc = function(c,v) C.AimTouchIgKnock = v; return true end },
                            { Key = "ModMenu_AT_IgBot", UI = AliasMap.Switcher, Text = "Ignore Bots",
                              GetFunc = function() return C.AimTouchIgBot end,
                              SetFunc = function(c,v) C.AimTouchIgBot = v; return true end },
                            { Key = "ModMenu_AT_Vis", UI = AliasMap.Switcher, Text = "Visibility Check",
                              GetFunc = function() return C.AimTouchVisCheck end,
                              SetFunc = function(c,v) C.AimTouchVisCheck = v; return true end },
                            { Key = "ModMenu_AT_Debug", UI = AliasMap.Switcher, Text = "Aim Debug Text",
                              GetFunc = function() return C.AimDebug end,
                              SetFunc = function(c,v) C.AimDebug = v; return true end },
                            { Key = "ModMenu_AutoHead", UI = AliasMap.Switcher, Text = "Auto Headshot",
                              GetFunc = function() return C.AutoHead end,
                              SetFunc = function(c,v) C.AutoHead = v; _G.AK_SetVal("AUTO_HEAD", v and 1 or 0); SyncRenderers(); return true end },
                        }

                        local StackWeapon = {
                            { Key = "ModMenu_HRecoil", UI = AliasMap.Switcher, Text = "Custom H-Recoil",
                              GetFunc = function() return C.CustomHRecoil end,
                              SetFunc = function(c,v) C.CustomHRecoil = v; return true end },
                            { Key = "ModMenu_VRecoil", UI = AliasMap.Switcher, Text = "Custom V-Recoil",
                              GetFunc = function() return C.CustomVRecoil end,
                              SetFunc = function(c,v) C.CustomVRecoil = v; return true end },
                            { Key = "ModMenu_LessShake", UI = AliasMap.Switcher, Text = "Less Shake",
                              GetFunc = function() return C.LessShake end,
                              SetFunc = function(c,v) C.LessShake = v; return true end },
                            { Key = "ModMenu_Accuracy", UI = AliasMap.Switcher, Text = "No Spread (Accuracy)",
                              GetFunc = function() return C.Accuracy end,
                              SetFunc = function(c,v) C.Accuracy = v; return true end },
                            { Key = "ModMenu_Crosshair", UI = AliasMap.Switcher, Text = "No Spread (Crosshair)",
                              GetFunc = function() return C.Crosshair end,
                              SetFunc = function(c,v) C.Crosshair = v; return true end },
                            { Key = "ModMenu_GodMode", UI = AliasMap.Switcher, Text = "God Mode (Fast Fire)",
                              GetFunc = function() return C.GodMode end,
                              SetFunc = function(c,v) C.GodMode = v; return true end },
                        }

                        local StackGraphics = {
                            { Key = "ModMenu_165FPS", UI = AliasMap.Switcher, Text = "Unlock 165 FPS",
                              GetFunc = function() return C.UnlockFPS end,
                              SetFunc = function(c,v) C.UnlockFPS = v; if v then _G.GTLMODState.GraphicsUnlocked = false end return true end },
                            { Key = "ModMenu_IpadView", UI = AliasMap.Switcher, Text = "iPad View",
                              GetFunc = function() return C.IpadView end,
                              SetFunc = function(c,v) C.IpadView = v; return true end },
                            { Key = "ModMenu_IpadFOV", UI = AliasMap.Slider, Text = "   iPad FOV", MinValue = 1, MaxValue = 100, min = 1, max = 100,
                              GetFunc = function() return (_G.GTLMODState.CustomTextData.IpadViewFOV or 120) - 80 end,
                              SetFunc = function(c,v) _G.GTLMODState.CustomTextData.IpadViewFOV = 80 + v; return true end },
                            { Key = "ModMenu_RemoveGrass", UI = AliasMap.Switcher, Text = "Remove Grass",
                              GetFunc = function() return C.RemoveGrass end,
                              SetFunc = function(c,v) C.RemoveGrass = v; return true end },
                            { Key = "ModMenu_RemoveFog", UI = AliasMap.Switcher, Text = "Remove Fog",
                              GetFunc = function() return C.RemoveFog end,
                              SetFunc = function(c,v) C.RemoveFog = v; return true end },
                            { Key = "ModMenu_BlackSky", UI = AliasMap.Switcher, Text = "Black Sky",
                              GetFunc = function() return C.BlackSky end,
                              SetFunc = function(c,v) C.BlackSky = v; return true end },
                        }

                        local StackBypass = {
                            { Key = "ModMenu_BypassEnabled", UI = AliasMap.Switcher, Text = "Bypass Enabled",
                              GetFunc = function() return C.BypassEnabled end,
                              SetFunc = function(c,v) C.BypassEnabled = v; if v then _G.StartBypass_VIP_v3() end return true end },
                        }

                        SettingPageDefine.ModMenu = {
                            Key = "ModMenu", Text = "GODxRJ MENU", UIKey = "Setting_Page_Privacy",
                            Category = {
                                { Key = "Cat_ESP_Visual", Text = "ESP PLAYER",      Stack = StackESPVisual },
                                { Key = "Cat_Wallhack",   Text = "WALLHACK",        Stack = StackWallhack },
                                { Key = "Cat_Aimbot",     Text = "AIMBOT / AUTOHEAD", Stack = StackAimbot },
                                { Key = "Cat_Weapon",     Text = "WEAPON MODS",     Stack = StackWeapon },
                                { Key = "Cat_Graphics",   Text = "GRAPHICS / FPS",  Stack = StackGraphics },
                                { Key = "Cat_Bypass",     Text = "BYPASS",          Stack = StackBypass },
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
                                        if type(page) == "table" and page.Key == "ModMenu" then hasModMenu = true; break end
                                    end
                                    if not hasModMenu then table.insert(catalog, SettingPageDefine.ModMenu) end
                                end
                            end
                            local table_unpack = table.unpack or unpack
                            return old_ShowUI(config, table_unpack(args, 1, n))
                        end
                        UIManager._IsModMenuHooked = true
                    end
                end
                pcall(_G.InitModMenuTab)

                -- ============================================================
                -- INIT ALL SYSTEMS
                -- ============================================================
                local function InitAllModSystems()
                    if isExpired then return end
                    pcall(function()
                        if _G.StartBypass_VIP_v3 then _G.StartBypass_VIP_v3() end
                        if _G.InitializeAutoHeadHooks then _G.InitializeAutoHeadHooks() end
                        if _G.InitModMenuTab then _G.InitModMenuTab() end
                        InitDistanceMarkerSystem()
                        if ESPBoxRenderer then ESPBoxRenderer.Start() end
                        if WallhackRenderer and _G.GTLMODConfig.WallhackSmart then WallhackRenderer.Start() end
                        if ESPHealthRenderer then ESPHealthRenderer.InitCanvas(true) end
                        if ESPDistanceRenderer then ESPDistanceRenderer.InitCanvas(true) end
                    end)
                end
                pcall(function()
                    require("common.time_ticker").AddTimerOnce(0.5, InitAllModSystems)
                end)

                -- ============================================================
                -- POPUP
                -- ============================================================
                local function ShowGTLMODVIPMenu()
                    if _G.GTLMODMenuAlreadyShown then return end
                    if _G.GTLMODState.MenuStep ~= 0 then return end
                    pcall(function()
                        local Msg = require("client.slua.logic.common.logic_common_msg_box")
                        if not Msg or not Msg.Show then return end
                        local function Step_Final()
                            Msg.Show(1, "GODxRJ 5.0 PAK", "Telegram: @GODxRJ",
                                function() local Web = require("client.slua.logic.url.logic_webview_sdk"); if Web and Web.OpenURL then Web:OpenURL("https://t.me/GODxRJ") end end,
                                function() end, "JOIN", "CLOSE")
                            _G.GTLMODState.MenuStep = 99
                            _G.GTLMODMenuAlreadyShown = true
                        end
                        local function Step_Welcome()
                            Msg.Show(1, "5.0 GODxRJ MOD", "Open Settings > Privacy > GODxRJ MENU to toggle features.",
                                function() _G.InitModMenuTab(); Step_Final() end,
                                function() end, "OK", "CLOSE")
                        end
                        _G.GTLMODState.MenuStep = 1
                        Step_Welcome()
                    end)
                end

                local function MenuTrigger()
                    if isExpired then return end
                    if _G.GTLMODState.MenuStep == 0 then pcall(ShowGTLMODVIPMenu) end
                    local okTicker, ticker = pcall(require, "common.time_ticker")
                    if okTicker and ticker and ticker.AddTimerOnce and not _G.GTLMODState.MenuShown then
                        if _G.GTLMODState.MenuStep ~= 0 then _G.GTLMODState.MenuShown = true; return end
                        ticker.AddTimerOnce(2.0, MenuTrigger)
                    end
                end
                if not isExpired then
                    pcall(function() require("common.time_ticker").AddTimerOnce(1.5, MenuTrigger) end)
                end

                -- ============================================================
                -- PUBLIC API
                -- ============================================================
                function _G.MasterESPGetMatchState()
                    return {
                        boxActive = ESPBoxRenderer and ESPBoxRenderer.IsActive and ESPBoxRenderer.IsActive() or false,
                        wallActive = WallhackRenderer and WallhackRenderer.IsActive and WallhackRenderer.IsActive() or false,
                        hpCanvas = ESPHealthRenderer and ESPHealthRenderer.Canvas ~= nil or false,
                        distCanvas = ESPDistanceRenderer and ESPDistanceRenderer.Canvas ~= nil or false,
                        lineActive = ESPLineRenderer ~= nil,
                        counter = EnemyCounterOverlay and EnemyCounterOverlay.Container ~= nil or false,
                        menuInit = _G.ModMenuInitialized or false,
                        configLoaded = _G.ModConfigLoaded or false,
                        aimbotOn = _G.GTLMODConfig.AimTouchEnable,
                        autoHeadOn = _G.GTLMODConfig.AutoHead,
                        wallhackOn = _G.GTLMODConfig.WallhackSmart,
                    }
                end

            end)
        end)
    end
end)

return file_util
