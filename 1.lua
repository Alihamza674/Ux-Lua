-- ====================================================================
-- BRPlayerCharacterBase.lua V6100 (RJ Universal FIX) - VERSION 3500
-- UNIVERSAL: Works on Global / KR / VN / TW / BGMI / any version
-- FIXED: Bat/Transformation revert works (exclusion list applied)
-- ====================================================================

-- ====================================================================
-- UNIVERSAL PACKAGE DETECTION
-- ====================================================================
local SUPPORTED_PACKAGES = {
    ["com.tencent.ig"]        = "Global",
    ["com.pubg.krmobile"]     = "Korea",
    ["com.vng.pubgmobile"]    = "Vietnam",
    ["com.rekoo.pubgm"]       = "Taiwan",
    ["com.pubg.imobile"]      = "BGMI",
    ["com.pubg.krmobile.ig"]  = "Korea-Alt",
    ["com.tencent.tmgp.pubgmhd"] = "CN",
    ["com.tencent.tmgp.pubgm"] = "CN-Alt",
}

local packageName = nil
local gameRegion = "Unknown"

pcall(function()
    local KSL = import("KismetSystemLibrary")
    if KSL and KSL.GetGameBundleId then
        packageName = KSL:GetGameBundleId()
    end
end)

if not packageName then
    local probes = {
        "com.tencent.ig", "com.pubg.krmobile", "com.vng.pubgmobile",
        "com.rekoo.pubgm", "com.pubg.imobile", "com.tencent.tmgp.pubgmhd",
        "com.tencent.tmgp.pubgm"
    }
    for _, pkg in ipairs(probes) do
        local f = io.open("//storage/emulated/0/Android/data/" .. pkg .. "/", "r")
        if f then f:close() packageName = pkg break end
    end
end

if not packageName then
    packageName = "com.tencent.ig"
end

gameRegion = SUPPORTED_PACKAGES[packageName] or "Unknown"
print("[UX MOD] Package: " .. packageName .. " (" .. gameRegion .. ")")

-- ====================================================================
-- UNIVERSAL PATHS
-- ====================================================================
local PATHS = {
    PubgData     = "//storage/emulated/0/Android/data/" .. packageName .. "/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/",
    Paks         = nil,
    SaveGames    = nil,
    Cache        = nil,
}
PATHS.Paks      = PATHS.PubgData .. "Paks/"
PATHS.SaveGames = PATHS.PubgData .. "SaveGames/"
PATHS.Cache     = PATHS.PubgData .. "image_download_mgr/temporary/Daliy/imgdownload_20713/"

-- ====================================================================
-- BRPlayerCharacterBase declaration
-- ====================================================================
local BRPlayerCharacterBase = { ServerRPC = {}, ClientRPC = {}, MulticastRPC = {} }
BRPlayerCharacterBase.ServerRPC.ServerRPC_NearDeathGiveupRescue = { Reliable = true, Params = {} }
BRPlayerCharacterBase.ServerRPC.ServerRPC_CarryDeadBox = { Reliable = true, Params = { UEnums.EPropertyClass.Object } }
BRPlayerCharacterBase.ServerRPC.RPC_Server_GmPlayAction = { Reliable = true, Params = { UEnums.EPropertyClass.Int } }
BRPlayerCharacterBase.MulticastRPC.MulticastRPC_GmPlayAction = { Reliable = true, Params = { UEnums.EPropertyClass.Int } }
BRPlayerCharacterBase.ClientRPC.RPC_Client_SetShouldCheckPassWall = { Reliable = true, Params = { UEnums.EPropertyClass.Bool } }
BRPlayerCharacterBase.ClientRPC.ClientRPC_TriggerHighlightMoment = { Reliable = true, Params = { UEnums.EPropertyClass.UInt32, UEnums.EPropertyClass.UInt32 } }
-- ====================================================================

_G.AK_GetVal = function(featureId)
  -- Nothing exposed through the feature API can run before online verification.
  if LicenseLocked() then return 0 end
  for _, feature in ipairs(_G.AK_Features) do
    if feature.id == featureId then return feature.val end
  end
  return 0
end
local ENetRole = import("ENetRole")
local EPawnState = import("EPawnState")

local GameplayData = nil
pcall(function() GameplayData = require("GameLua.GameCore.Data.GameplayData") end)
if not GameplayData then
    pcall(function() GameplayData = require("GameLua.GameCore.Data.GameplayData") end)
end

local GamePlayTools = nil
pcall(function() GamePlayTools = require("GameLua.Mod.BaseMod.Common.GamePlayTools") end)
if not GamePlayTools then
    pcall(function() GamePlayTools = require("GameLua.Mod.BaseMod.Common.GamePlayTools") end)
end

-- ============================================================================
-- 1. LICENSE CONFIG + CORE
-- ============================================================================
local MasterLicenseConfig = (function()
    return {
        url = 'https://key.authapi.xyz/server', game = 'BGMI',
        timeout = 10, clockSkew = 120, expiryPath = nil,
        manualExpiry = "2026-12-31 23:59:59", tamperTolerance = 5,
        secret = 'Vm8Lk7Uj2JmsjCPVPVjrLa7zgfx3uz5E',
    }
end)()

local MasterLicenseCore = (function()
    local Primitives = (function()
        local floor, abs, max = math.floor, math.abs, math.max
        local byte, char, format = string.byte, string.char, string.format
        local U32 = 4294967296
        local AND, XOR = {}, {}
        for a = 0, 15 do for b = 0, 15 do
            local av, bv, both, different, place = a, b, 0, 0, 1
            for _ = 1, 4 do
                local x, y = av % 2, bv % 2
                if x == 1 and y == 1 then both = both + place end
                if x ~= y then different = different + place end
                av, bv, place = floor(av / 2), floor(bv / 2), place * 2
            end
            AND[a * 16 + b], XOR[a * 16 + b] = both, different
        end end
        local function bitop(a, b, lookup)
            local value, place = 0, 1
            for _ = 1, 8 do
                value = value + lookup[(a % 16) * 16 + b % 16] * place
                a, b, place = floor(a / 16), floor(b / 16), place * 16
            end
            return value
        end
        local function band(a, b) return bitop(a, b, AND) end
        local function bxor(a, b) return bitop(a, b, XOR) end
        local function rol(value, amount)
            local divisor = 2 ^ (32 - amount)
            return (value % divisor) * 2 ^ amount + floor(value / divisor)
        end
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
                h0, h1, h2, h3 = (h0 + a) % U32, (h1 + b) % U32, (h2 + c) % U32, (h3 + d) % U32
            end
            return little32(h0) .. little32(h1) .. little32(h2) .. little32(h3)
        end
        local function hex(input)
            return (input:gsub(".", function(c) return format("%02x", byte(c)) end))
        end
        local function md5(input) return hex(md5_raw(input)) end
        local function form_encode(input)
            assert(type(input) == "string", "Form value must be a string")
            return (input:gsub("[^A-Za-z0-9%-%._~ ]", function(c)
                return format("%%%02X", byte(c)) end):gsub(" ", "+"))
        end
        local function constant_time_equal(a, b)
            if type(a) ~= "string" or type(b) ~= "string" then return false end
            local difference = abs(#a - #b)
            for i = 1, max(#a, #b) do
                difference = difference + abs((byte(a, i) or 0) - (byte(b, i) or 0))
            end
            return difference == 0
        end
        local function name_uuid(input)
            local digest = md5_raw(input)
            local h = hex(digest:sub(1,6) .. char(byte(digest,7) % 16 + 48)
                .. digest:sub(8,8) .. char(byte(digest,9) % 64 + 128) .. digest:sub(10))
            return h:sub(1,8) .. "-" .. h:sub(9,12) .. "-" .. h:sub(13,16)
                .. "-" .. h:sub(17,20) .. "-" .. h:sub(21,32)
        end
        return {md5 = md5, md5_raw = md5_raw, form_encode = form_encode,
                constant_time_equal = constant_time_equal, name_uuid = name_uuid}
    end)()

    local SESSION_KEY = '__MasterLicenseSession_v1'
    local function loadSession()
        local g = rawget(_G, SESSION_KEY)
        if type(g) ~= 'table' or g.authorized ~= true then return nil end
        if type(g.expiresAt) == 'number' and g.expiresAt <= os.time() then
            _G[SESSION_KEY] = nil; return nil
        end
        return g
    end
    local function saveSession(expiresAt)
        pcall(function()
            _G[SESSION_KEY] = {authorized = true, expiresAt = expiresAt, issuedAt = os.time()}
        end)
    end
    local function clearSession() pcall(function() _G[SESSION_KEY] = nil end) end

    local CreateLocalExpiry = (function()
        return function(cfg, wallReader)
            local E = {}
            local expiredText = 'Mod expired. DM @UX_Official for renewal.'
            local tamperText  = "Don't be over smart"
            local blockedMessage, blockedPhase
            local function finite(n)
                return type(n) == 'number' and n == n and n ~= math.huge and n ~= -math.huge
            end
            local function parse(text)
                if type(text) ~= 'string' then return nil end
                local y,m,d,h,n,s = text:match('^(%d%d%d%d)%-(%d%d)%-(%d%d) (%d%d):(%d%d):(%d%d)$')
                y,m,d,h,n,s = tonumber(y),tonumber(m),tonumber(d),tonumber(h),tonumber(n),tonumber(s)
                if not y or y < 1970 or y > 9999 or m < 1 or m > 12 or h > 23 or n > 59 or s > 59 then return nil end
                local leap = y % 4 == 0 and (y % 100 ~= 0 or y % 400 == 0)
                local months = {31, leap and 29 or 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31}
                if d < 1 or d > months[m] then return nil end
                local prior = y - 1
                local days = 365 * (y - 1970) + math.floor(prior / 4) - math.floor(1969 / 4)
                    - math.floor(prior / 100) + math.floor(1969 / 100)
                    + math.floor(prior / 400) - math.floor(1969 / 400)
                for i = 1, m - 1 do days = days + months[i] end
                return (days + d - 1) * 86400 + h * 3600 + n * 60 + s - 6 * 3600
            end
            local configured = type(cfg.manualExpiry) == 'string'
                and cfg.manualExpiry:match('^%s*(.-)%s*$') or cfg.manualExpiry
            local expiry = parse(configured)
            local skew = cfg.clockSkew or 120
            if configured ~= nil and configured ~= '' and not expiry then
                blockedMessage, blockedPhase = 'Invalid local expiry date. Use YYYY-MM-DD HH:MM:SS.', 'error'
            end
            local function block(message, phase)
                if not blockedMessage then blockedMessage, blockedPhase = message, phase end
                return false, blockedMessage, blockedPhase
            end
            function E.Status() return not blockedMessage, blockedMessage, blockedPhase end
            function E.MarkTampered() return block(tamperText, 'tampered') end
            function E.GetExpiry() return expiry end
            function E.Accept(server, now, world, phone, rtt)
                if blockedMessage then return E.Status() end
                if not finite(server) or not finite(now) or now < 0 or world == nil
                    or not finite(rtt) or rtt < 0 or not finite(phone) then
                    return block('Clock verification unavailable.', 'error')
                end
                if math.abs(phone - server) > skew + rtt then return E.MarkTampered() end
                if expiry and server + rtt >= expiry then return block(expiredText, 'expired') end
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
            local localExpiry = deps.localExpiry
            do
                local stored = loadSession()
                if stored then
                    allowed = true; expiresAt = stored.expiresAt
                    phase, message = 'active', 'Session restored'
                end
            end
            if localExpiry then
                local ok, text, state = localExpiry.Status()
                if not ok then message, phase = text, state end
            end
            local function finite(n)
                return type(n) == 'number' and n == n and n ~= math.huge and n ~= -math.huge
            end
            local function readClock()
                local ok, n, w = pcall(deps.clock)
                if ok and finite(n) and n >= 0 and w ~= nil then return n, w end
            end
            local function notify(text, state)
                message, phase = text, state
                if type(deps.status) == 'function' then pcall(deps.status, text, state) end
            end
            local function stopPayload()
                if payloadStarted then
                    payloadStarted = false
                    local ok, accepted = pcall(stopFn)
                    if not ok or accepted == false then restartRequired = true end
                end
            end
            local function revoke(text, state)
                generation = generation + 1
                allowed, pending, expiresAt = false, nil, nil
                lastRequestLatencyMs, lastResponseTime, lastResponseWorld = nil, nil, nil
                stopPayload()
                local localDenied = false
                if localExpiry then
                    local ok, localText, localPhase = localExpiry.Status()
                    if not ok then text, state, localDenied = localText, localPhase, true end
                end
                notify(restartRequired and not localDenied
                    and 'Restart required: payload cleanup failed.' or text, state or 'error')
            end
            local function startPayload()
                if payloadStarted or not startFn then return true end
                payloadStarted = true
                local before = generation
                local ok, accepted = pcall(startFn)
                if not ok or accepted == false then
                    restartRequired = true
                    revoke('Restart required: offline script startup failed.', 'error')
                    return false
                end
                return generation == before and allowed
            end
            local function denyReason(reason)
                if type(reason) ~= 'string' then return 'Expired' end
                local lower = reason:sub(1, 120):lower():gsub('[_%s%-]+', ' ')
                if lower == 'max devices' or lower == 'maximum devices'
                    or lower == 'max devices reached' then
                    return 'Max Devices'
                end
                local clean = reason
                for _, field in ipairs({'key', 'serial'}) do
                    if pending and type(pending[field]) == 'string' and #pending[field] > 0 then
                        local needle = pending[field]:gsub('([^%w])', '%%%1')
                        clean = clean:gsub(needle, '[' .. field .. ']')
                    end
                end
                if type(cfg.secret) == 'string' and #cfg.secret > 0 then
                    clean = clean:gsub(cfg.secret:gsub('([^%w])', '%%%1'), '[credential]')
                end
                clean = clean:gsub('[%c]', ' '):sub(1, 120)
                return clean == '' and 'Expired' or ('Expired: ' .. clean)
            end
            local function configuredExpiry(result)
                if cfg.expiryPath == nil then return nil, true end
                if type(cfg.expiryPath) ~= 'table' or #cfg.expiryPath == 0 then return nil, false end
                local v = result
                for _, name in ipairs(cfg.expiryPath) do
                    if type(v) ~= 'table' then return nil, false end
                    v = rawget(v, name)
                end
                return v, finite(v) and v > 0 and v % 1 == 0
            end
            local function begin(key)
                if restartRequired or pending then return false end
                if localExpiry then
                    local ok, text, state = localExpiry.Status()
                    if not ok then revoke(text, state); return false end
                end
                if type(key) ~= 'string' then key = '' end
                key = key:match('^%s*(.-)%s*$')
                if #key == 0 or #key > 512 then
                    revoke('Expired: enter a valid key.', 'denied'); return false
                end
                local now, world = readClock()
                if not now then
                    revoke('Game clock unavailable. Try again in a match.', 'error'); return false
                end
                local okSerial, serial = pcall(deps.serial, key)
                if not okSerial or type(serial) ~= 'string' or #serial == 0 or #serial > 512 then
                    revoke('Device identifier unavailable.', 'error'); return false
                end
                generation = generation + 1
                local requestId = generation
                pending = {id = requestId, key = key, serial = serial,
                           started = now, world = world, deadline = now + cfg.timeout}
                notify('Signing in...', 'pending')
                if not pending or pending.id ~= requestId or generation ~= requestId then return false end
                local body = 'game=' .. P.form_encode(cfg.game)
                    .. '&user_key=' .. P.form_encode(key)
                    .. '&serial=' .. P.form_encode(serial)
                local function received(success, raw)
                    if not pending or pending.id ~= requestId or generation ~= requestId then return end
                    local current, worldNow = readClock()
                    if not current or worldNow ~= pending.world or current < pending.started
                        or current >= pending.deadline then
                        revoke('Request expired. Please sign in again.', 'error'); return
                    end
                    if success ~= true or type(raw) ~= 'string' or #raw == 0 or #raw > 32768 then
                        revoke('Connection failed. Please try again.', 'error'); return
                    end
                    local ok, result = pcall(deps.decode, raw)
                    if not ok or type(result) ~= 'table' then
                        revoke('Invalid server response.', 'error'); return
                    end
                    if result.status ~= true then revoke(denyReason(result.reason), 'denied'); return end
                    local data = result.data
                    if type(data) ~= 'table' or type(data.token) ~= 'string' or #data.token ~= 32
                        or not data.token:match('^[%x]+$') or not finite(data.rng) or data.rng % 1 ~= 0 then
                        revoke('Incomplete server response.', 'error'); return
                    end
                    local expected = P.md5(cfg.game .. '-' .. key .. '-' .. serial .. '-' .. cfg.secret)
                    if not P.constant_time_equal(data.token:lower(), expected) then
                        revoke('Server token verification failed.', 'denied'); return
                    end
                    local okWall, wall = pcall(deps.wall)
                    if not okWall or not finite(wall) then
                        revoke('Phone clock unavailable.', 'error'); return
                    end
                    if localExpiry then
                        local accepted, text, state = localExpiry.Accept(
                            data.rng, current, worldNow, wall, current - pending.started)
                        if not accepted then revoke(text, state); return end
                    elseif math.abs(wall - data.rng) > cfg.clockSkew then
                        revoke('Phone/server clock mismatch. Check automatic time.', 'error'); return
                    end
                    local expiry, validExpiry = configuredExpiry(result)
                    if not validExpiry then
                        revoke('Configured server expiry field is missing or invalid.', 'error'); return
                    end
                    if expiry and expiry - data.rng - (current - pending.started) <= 0 then
                        revoke('Expired', 'denied'); return
                    end
                    local fixedExpiry = localExpiry and localExpiry.GetExpiry()
                    if fixedExpiry then expiry = math.min(expiry or fixedExpiry, fixedExpiry) end
                    lastRequestLatencyMs = (current - pending.started) * 1000
                    lastResponseTime, lastResponseWorld = current, worldNow
                    pending = nil
                    allowed, expiresAt = true, expiry
                    saveSession(expiresAt)
                    if not startPayload() then return end
                    notify('Login successful.', 'active')
                end
                local ok, accepted = pcall(deps.post, cfg.url,
                    {['Content-Type'] = 'application/x-www-form-urlencoded'},
                    body, received, cfg.timeout)
                if not ok or accepted == false then
                    revoke('HTTP request could not start.', 'error'); return false
                end
                return true
            end
            function A.Login(key) if allowed then return false end; return begin(key) end
            function A.Tick()
                if not pending then return end
                local now, world = readClock()
                if not now or world ~= pending.world or now < pending.started then
                    revoke('Login interrupted by map loading. Please try again when ready.', 'locked'); return
                end
                if now >= pending.deadline then
                    revoke('Request timed out. Please try again.', 'error')
                end
            end
            function A.IsAuthorized()
                if allowed and not restartRequired then return true end
                local stored = loadSession()
                if stored and not restartRequired then
                    allowed = true; expiresAt = stored.expiresAt; return true
                end
                return false
            end
            function A.Logout() clearSession(); revoke('Expired: signed out.', 'locked') end
            function A.FailClosed(text, requiresRestart)
                if requiresRestart == true then restartRequired = true end
                revoke(text or 'Online access unavailable.', 'error')
            end
            function A.ReportClockTampering()
                if localExpiry then localExpiry.MarkTampered() end
                revoke("Don't be over smart", 'tampered')
            end
            function A.Bind(onStart, onStop)
                if type(onStart) ~= 'function' or type(onStop) ~= 'function' then
                    return false, 'START_AND_STOP_REQUIRED'
                end
                if startFn and (startFn ~= onStart or stopFn ~= onStop) then
                    return false, 'ALREADY_BOUND'
                end
                startFn, stopFn = onStart, onStop
                if A.IsAuthorized() then return startPayload() end
                return true
            end
            function A.Unbind()
                revoke('Offline script disconnected.', 'locked')
                startFn, stopFn = nil, nil
            end
            function A.GetRemainingSeconds() return nil end
            function A.GetState()
                local authorized = A.IsAuthorized()
                local sample, age
                if authorized and lastRequestLatencyMs ~= nil then
                    local now, world = readClock()
                    if now and world == lastResponseWorld and now >= lastResponseTime then
                        sample, age = lastRequestLatencyMs, now - lastResponseTime
                    end
                end
                return {
                    phase = phase, message = message, authorized = authorized,
                    sessionAuthorized = authorized, expiresAt = expiresAt,
                    accessPolicy = "game_session", expiryCheckPolicy = "login_only",
                    periodicRecheck = false, pending = pending ~= nil,
                    linked = startFn ~= nil, restartRequired = restartRequired == true,
                    lastRequestLatencyMs = sample, lastRequestLatencyAgeSeconds = age,
                    latencyScope = "license_http_round_trip"
                }
            end
            return A
        end
    end)()

    local Core = {Primitives = Primitives, createExpiry = CreateLocalExpiry}
    function Core.new(config, dependencies)
        assert(type(config) == 'table' and type(dependencies) == 'table',
            'License configuration and dependencies required')
        local deps = {}
        for key, value in pairs(dependencies) do deps[key] = value end
        if deps.localExpiry == nil then deps.localExpiry = CreateLocalExpiry(config, deps.wall) end
        return CreateAuth(Primitives, config, deps)
    end
    return Core
end)()

-- ============================================================================
-- 2. LOGIN UI
-- ============================================================================
local MasterLoginUI = (function()
    local Module = {}
    function Module.new(env)
        env = env or _G
        local require = env.require or require
        local function global(name)
            local ok, value = pcall(function() return env[name] end)
            if ok then return value end
        end
        local UI = {_status = "Enter your key", _busy = false, _data = nil}
        local function member(object, name)
            if object == nil then return nil end
            local ok, value = pcall(function() return object[name] end)
            if ok then return value end
        end
        local function valid(object)
            local check = member(global("slua"), "isValid")
            if object == nil then return false end
            if type(check) == 'function' then
                local ok, result = pcall(check, object)
                if ok and result == true then return true end
            end
            local game = global('Game')
            local fallback = member(game, 'IsValid')
            if type(fallback) == 'function' then
                local ok, result = pcall(fallback, game, object)
                return ok and result == true
            end
            return false
        end
        local function imported(name)
            local loader = global("import")
            if type(loader) ~= "function" then return nil end
            local ok, result = pcall(loader, name)
            if ok then return result end
        end
        local function construct(class, ...)
            if class == nil then return nil end
            local ok, result = pcall(class, ...)
            if ok then return result end
        end
        local function vector(x, y)
            return construct(global("FVector2D") or imported("Vector2D"), x, y)
                or {X = x, Y = y}
        end
        local function color(r, g, b, a)
            return construct(global("FLinearColor") or imported("LinearColor"), r, g, b, a)
                or {R = r, G = g, B = b, A = a}
        end
        local function visibility(widget, value)
            local setter = member(widget, "SetWidgetVisibility") or member(widget, "SetVisibility")
            assert(type(setter) == "function", "UI_VISIBILITY_UNAVAILABLE")
            setter(widget, value)
        end
        local function setTextStyle(widget, size, textColor)
            pcall(function()
                local font = widget.Font
                if font then
                    font.Size = math.max(1, math.floor(size * (UI._scale or 1) + 0.5))
                    local assigned = pcall(function() widget.Font = font end)
                    if not assigned then widget:SetFont(font) end
                end
            end)
            pcall(function() widget:SetAutoWrapText(true) end)
            pcall(function()
                local slate = construct(imported("SlateColor"), textColor)
                if slate then widget:SetColorAndOpacity(slate) end
            end)
        end
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
        function UI.Destroy()
            local previous = UI._data; UI._data = nil; detach(previous)
        end
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
        function UI.SetBusy(busy)
            UI._busy = busy == true
            local data = UI._data
            if data then
                if data.deliveredBusy == UI._busy then return true end
                local buttonOK = pcall(function() data.button:SetIsEnabled(not UI._busy) end)
                local inputOK  = pcall(function() data.input:SetIsEnabled(not UI._busy) end)
                if buttonOK and inputOK then data.deliveredBusy = UI._busy; return true end
            end
            return false
        end
        local function fitScale(parent)
            local result = 1
            pcall(function()
                local size = parent:GetCachedGeometry():GetLocalSize()
                local width, height = size.X, size.Y
                if type(width) == 'number' and type(height) == 'number'
                    and width > 24 and height > 24 then
                    result = math.min(1, (width - 24) / 500, (height - 24) / 248)
                end
            end)
            return result
        end
        function UI.Show(onSubmit)
            if type(onSubmit) ~= "function" then return false, "UI_SUBMIT_REQUIRED" end
            local data = UI._data
            if data and valid(data.parent)
                and math.abs(fitScale(data.parent) - (data.scale or 1)) > 0.001 then
                UI.Destroy(); data = nil
            end
            if data and valid(data.container) and valid(data.parent) then
                local ok = data.visible or pcall(function()
                    visibility(data.container, data.visibleEnum)
                end)
                if ok then
                    data.onSubmit, data.visible, data.hiddenApplied = onSubmit, true, false
                    UI.SetStatus(UI._status); UI.SetBusy(UI._busy); return true
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
            local game = global("CGame")
            if type(member(game, "NewObjectFromPath")) ~= "function" then
                return false, "UI_FACTORY_UNAVAILABLE"
            end
            local enums = member(global("UEnums"), "ESlateVisibility")
            local visibleEnum, hidden = member(enums, "Visible"), member(enums, "Collapsed")
            local passive = member(enums, "SelfHitTestInvisible")
            if visibleEnum == nil or hidden == nil or passive == nil then
                return false, "UI_ENUM_UNAVAILABLE"
            end
            UI._scale = fitScale(parent)
            data = {parent = parent, visible = false, onSubmit = onSubmit,
                    visibleEnum = visibleEnum, hidden = hidden, scale = UI._scale}
            local okBuild = pcall(function()
                local function make(class, outer)
                    local widget = game:NewObjectFromPath("/Script/UMG." .. class, outer)
                    assert(valid(widget), "UI_WIDGET_UNAVAILABLE")
                    return widget
                end
                data.container = make("CanvasPanel", parent)
                local function add(widget, x, y, width, height, z)
                    local slot = data.container:AddChildToCanvas(widget)
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
                title:SetText("UX_Official | KEY 🗝️ 03709241014 LOGIN")
                setTextStyle(title, 19, color(0.1, 0.9, 1, 1))
                visibility(title, passive); add(title, 22, 15, 456, 30, 1)
                data.input = make("EditableTextBox", data.container)
                data.input:SetText("")
                setTextStyle(data.input, 17, color(0.92, 0.94, 0.96, 1))
                pcall(function() data.input:SetHintText("Enter your key") end)
                visibility(data.input, visibleEnum); add(data.input, 22, 58, 456, 44, 2)
                local hint = make("TextBlock", data.container)
                hint:SetText("Enter your key, then tap LOGIN.")
                setTextStyle(hint, 12, color(0.72, 0.78, 0.83, 1))
                visibility(hint, passive); add(hint, 22, 106, 456, 20, 2)
                data.status = make("TextBlock", data.container)
                data.status:SetText(UI._status); data.deliveredStatus = UI._status
                setTextStyle(data.status, 13, color(0.92, 0.94, 0.96, 1))
                visibility(data.status, passive)
                pcall(function() data.status:SetAutoWrapText(true) end)
                add(data.status, 22, 129, 456, 54, 2)
                data.button = make("Button", data.container)
                visibility(data.button, visibleEnum)
                local label = make("TextBlock", data.button)
                label:SetText("LOGIN")
                setTextStyle(label, 17, color(0.05, 0.08, 0.12, 1))
                visibility(label, passive); data.button:AddChild(label)
                add(data.button, 150, 190, 200, 40, 2)
                data.event = data.button.OnClicked
                data.eventHandle = data.event:Add(function()
                    if UI._data ~= data or not data.visible or UI._busy then return end
                    local readOK, key = pcall(function() return data.input:GetText() end)
                    if not readOK or type(key) ~= "string" then
                        UI.SetStatus("Unable to read the key"); return
                    end
                    key = key:match("^%s*(.-)%s*$")
                    if key == "" or #key > 512 then UI.SetStatus("Enter a valid key"); return end
                    local submitOK = pcall(data.onSubmit, key)
                    if not submitOK then UI.SetBusy(false); UI.SetStatus("Login could not start") end
                end)
                local slot = parent:AddChildToCanvas(data.container)
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
                detach(data); return false, "UI_BUILD_UNAVAILABLE"
            end
            data.visible = true; UI._data = data; UI.SetBusy(UI._busy)
            return true
        end
        function UI.ShowNotice(message)
            local shown, reason = UI.Show(function() return false end)
            if not shown then return false, reason end
            UI.SetStatus(message); UI.SetBusy(true); return true
        end
        return UI
    end
    return Module
end)()

-- ============================================================================
-- 3. WELCOME UI
-- ============================================================================
local MasterWelcomeUI = (function()
    local Module = {}
    function Module.new(env)
        env = env or _G
        local require = env.require or require
        local function global(n)
            local ok, v = pcall(function() return env[n] end)
            if ok then return v end
        end
        local function member(o, k)
            if o == nil then return nil end
            local ok, v = pcall(function() return o[k] end)
            if ok then return v end
        end
        local function valid(o)
            local c = member(global("slua"), "isValid")
            if o == nil then return false end
            if type(c) == 'function' then
                local ok, v = pcall(c, o)
                if ok and v == true then return true end
            end
            local g = global('Game'); local f = member(g, 'IsValid')
            if type(f) == 'function' then
                local ok, v = pcall(f, g, o)
                return ok and v == true
            end
            return false
        end
        local function imported(n)
            local l = global("import")
            if type(l) ~= "function" then return nil end
            local ok, v = pcall(l, n); if ok then return v end
        end
        local function construct(c, ...)
            if c == nil then return nil end
            local ok, v = pcall(c, ...); if ok then return v end
        end
        local function vector(x, y)
            return construct(global("FVector2D") or imported("Vector2D"), x, y) or {X = x, Y = y}
        end
        local function linear(v)
            v = v / 255
            if v <= 0.04045 then return v / 12.92 end
            return ((v + 0.055) / 1.055) ^ 2.4
        end
        local function color(r, g, b, a)
            r, g, b, a = linear(r), linear(g), linear(b), a or 1
            return construct(global("FLinearColor") or imported("LinearColor"), r, g, b, a)
                or {R = r, G = g, B = b, A = a}
        end
        local function visibility(w, v)
            local s = member(w, "SetWidgetVisibility") or member(w, "SetVisibility")
            if type(s) == 'function' then s(w, v) end
        end
        local WelcomeUI = {Width = 600, Height = 276}
        local WelcomeText = {
            "Welcome to @UX_Official Lua mod",
            "Kill limit 8-10",
            "Play smart and avoid report",
        }
        local UI = {_shown = false, _data = nil}
        local function detach(data)
            if not data then return end
            data.Visible = false
            if data.Event and data.EventHandle ~= nil then
                pcall(function() data.Event:Remove(data.EventHandle) end)
            end
            if valid(data.Container) then
                pcall(function() visibility(data.Container, data.Hidden) end)
                pcall(function() data.Container:RemoveFromParent() end)
            end
        end
        function UI:Destroy()
            local p = UI._data; UI._data = nil; detach(p)
        end
        local function parent()
            local okT, tools = pcall(require, "GameLua.Mod.BaseMod.Common.UI.InGameUITools")
            if not okT then return nil end
            local getRoot = member(tools, "GetMainControlBaseUI")
            if type(getRoot) ~= "function" then return nil end
            local ok, root = pcall(getRoot)
            if not ok or not valid(root) then return nil end
            local canvas = member(root, "CanvasPanel_0")
            if not valid(canvas) then canvas = member(root, "CanvasPanel_42") end
            if valid(canvas) then return root, canvas end
        end
        function UI:Show()
            if UI._shown and UI._data and valid(UI._data.Container) then
                visibility(UI._data.Container, UI._data.Passive)
                UI._data.Visible = true
                return true
            end
            UI:Destroy()
            local root, par = parent()
            if not par then return false, "WELCOME_ROOT_UNAVAILABLE" end
            local game = global("CGame")
            if type(member(game, "NewObjectFromPath")) ~= "function" then
                return false, "WELCOME_FACTORY_UNAVAILABLE"
            end
            local enums = member(global("UEnums"), "ESlateVisibility")
            local visible, hidden, passive = member(enums, "Visible"),
                member(enums, "Collapsed"), member(enums, "SelfHitTestInvisible")
            if visible == nil or hidden == nil or passive == nil then
                return false, "WELCOME_ENUM_UNAVAILABLE"
            end
            local data = {Root = root, Parent = par, Visible = false,
                          Hidden = hidden, Passive = passive}
            local ok = pcall(function()
                local function make(class, outer)
                    local w = game:NewObjectFromPath("/Script/UMG." .. class, outer)
                    assert(valid(w), "WELCOME_WIDGET_UNAVAILABLE")
                    return w
                end
                data.Container = make("CanvasPanel", par)
                visibility(data.Container, hidden)
                local function add(w, x, y, ww, hh, z)
                    local s = data.Container:AddChildToCanvas(w)
                    s:SetAutoSize(false)
                    s:SetPosition(vector(x, y))
                    s:SetSize(vector(ww, hh))
                    s:SetZOrder(z)
                    return s
                end
                local function rect(x, y, ww, hh, c, z)
                    local w = make("Border", data.Container)
                    w:SetBrushColor(c)
                    visibility(w, passive)
                    add(w, x, y, ww, hh, z)
                    return w
                end
                local slateColor
                pcall(function() slateColor = imported("SlateColor") end)
                local function textStyle(w, size, c)
                    local font = member(w, "Font")
                    if font ~= nil then
                        if type(font) == 'table' then
                            local copy = {}
                            for k, v in pairs(font) do copy[k] = v end
                            font = copy
                        end
                        font.Size = size
                        pcall(function() w:SetFont(font) end)
                    end
                    pcall(function() w:SetColorAndOpacity(slateColor and slateColor(c) or c) end)
                    pcall(function() w:SetJustification(1) end)
                    visibility(w, passive)
                end
                local function text(value, x, y, ww, hh, size, c, z)
                    local w = make("TextBlock", data.Container)
                    w:SetText(value)
                    textStyle(w, size, c)
                    pcall(function() w:SetAutoWrapText(true) end)
                    add(w, x, y, ww, hh, z)
                    return w
                end
                local W, H = WelcomeUI.Width, WelcomeUI.Height
                rect(4, 6, W, H, color(18, 5, 10, 0.25), 0)
                rect(0, 0, W, H, color(186, 137, 74), 1)
                rect(2, 2, W - 4, H - 4, color(255, 244, 214), 2)
                local stops = {{116, 16, 46}, {169, 38, 47}, {194, 105, 35}}
                local segments = 64
                for i = 0, segments - 1 do
                    local t = i / (segments - 1)
                    local left, right, blend
                    if t <= 0.5 then left, right, blend = stops[1], stops[2], t * 2
                    else left, right, blend = stops[2], stops[3], (t - 0.5) * 2 end
                    local x0 = 2 + (W - 4) * i / segments
                    local x1 = 2 + (W - 4) * (i + 1) / segments
                    rect(x0, 2, math.min(W - 2, x1 + 0.3) - x0, 76,
                        color(left[1] + (right[1] - left[1]) * blend,
                              left[2] + (right[2] - left[2]) * blend,
                              left[3] + (right[3] - left[3]) * blend), 3)
                end
                rect(18, 3, W - 36, 1, color(255, 255, 255, 0.32), 4)
                rect(2, 78, W - 4, 3, color(238, 188, 93), 4)
                local title = text(WelcomeText[1], 24, 23, W - 48, 44, 19, color(255, 253, 247), 5)
                pcall(function() title:SetShadowOffset(vector(0, 1)) end)
                pcall(function() title:SetShadowColorAndOpacity(color(40, 3, 12, 0.45)) end)
                rect(30, 100, W - 60, 54, color(255, 226, 159), 3)
                rect(30, 100, 4, 54, color(160, 33, 49), 4)
                text(WelcomeText[2], 46, 110, W - 92, 38, 23, color(115, 25, 45), 5)
                text(WelcomeText[3], 30, 168, W - 60, 32, 17, color(130, 34, 47), 5)
                local button = make("Button", data.Container)
                pcall(function() button:SetBackgroundColor(color(131, 25, 47)) end)
                visibility(button, visible)
                local label = make("TextBlock", button)
                label:SetText("OK")
                textStyle(label, 17, color(255, 251, 238))
                local ls = button:AddChild(label)
                pcall(function() ls:SetHorizontalAlignment(2) end)
                pcall(function() ls:SetVerticalAlignment(2) end)
                add(button, (W - 164) / 2, 212, 164, 42, 6)
                data.Event = member(button, "OnClicked")
                data.EventHandle = data.Event:Add(function()
                    if UI._data == data and data.Visible then UI:Destroy() end
                end)
                local slot = par:AddChildToCanvas(data.Container)
                slot:SetAutoSize(false)
                slot:SetSize(vector(W, H))
                slot:SetZOrder(9200)
                local anchors = slot:GetAnchors()
                anchors.Minimum, anchors.Maximum = vector(0.5, 0.5), vector(0.5, 0.5)
                slot:SetAnchors(anchors)
                slot:SetAlignment(vector(0.5, 0.5))
                slot:SetPosition(vector(0, 0))
                visibility(data.Container, passive)
            end)
            if not ok then detach(data); return false, "WELCOME_BUILD_FAILED" end
            data.Visible = true
            UI._data = data
            UI._shown = true
            return true
        end
        function UI:Hide() if UI._data then detach(UI._data) end; UI._data = nil end
        function UI:IsShown() return UI._shown == true end
        return UI
    end
    return Module
end)()
_G.MasterWelcomeUI = MasterWelcomeUI

-- ============================================================================
-- 4. LICENSE RUNTIME
-- ============================================================================
local MasterLicenseRuntime = (function()
    local Runtime = {}
    Runtime.__index = Runtime
    local function finite(n)
        return type(n) == 'number' and n == n and n >= 0 and n < math.huge
    end
    local function read(o, k)
        if o == nil then return nil end
        local ok, v = pcall(function() return o[k] end)
        if ok then return v end
    end
    local function static(o, k, ...)
        local fn = read(o, k)
        if type(fn) ~= 'function' then return nil end
        local ok, v = pcall(fn, ...); if ok then return v end
    end
    local function call(o, k, ...)
        local fn = read(o, k)
        if type(fn) ~= 'function' then return nil end
        local ok, v = pcall(fn, o, ...); if ok then return v end
    end
    local function validConfig(c)
        return type(c) == 'table' and type(c.url) == 'string' and c.url:match('^https://') ~= nil
            and type(c.game) == 'string' and #c.game > 0
            and type(c.secret) == 'string' and #c.secret > 0
            and finite(c.timeout) and c.timeout > 0 and finite(c.clockSkew)
    end
    function Runtime.new(env, config, Core, LoginUI)
        local self = setmetatable({
            env = env or _G, reason = 'login_required', active = false,
            ready = false, disposed = false, uiRetryAt = 0, uiFailures = 0
        }, Runtime)
        if not validConfig(config) or type(Core) ~= 'table' or type(Core.new) ~= 'function'
            or type(Core.Primitives) ~= 'table' then
            self.reason = 'license_dependencies_unavailable'; return self
        end
        local cfg = {}
        for k, v in pairs(config) do cfg[k] = v end
        self.timeout = cfg.timeout
        if type(LoginUI) == 'table' and type(LoginUI.new) == 'function' then
            local ok, ui = pcall(LoginUI.new, self.env)
            if ok and type(ui) == 'table' then self.ui = ui end
        end
        if type(_G.MasterWelcomeUI) == 'table' and type(_G.MasterWelcomeUI.new) == 'function' then
            local okW, w = pcall(_G.MasterWelcomeUI.new, self.env)
            if okW and type(w) == 'table' then self.welcome = w end
        end
        self.welcomeShownThisSession = (_G.__MASTER_WELCOME_SHOWN_SESSION == true)
        self.welcomeScheduledAt = nil
        self.welcomeDelaySeconds = 3.0
        self.submit = function(key) return self:login(key) end
        local ok, auth = pcall(Core.new, cfg, {
            clock = function() return self:_clock() end,
            wall = function()
                local value = static(read(self.env, 'os'), 'time')
                if finite(value) and value > 0 then return value end
            end,
            serial = function(key)
                local client = read(self.env, 'Client')
                local value = static(client, 'GetPhoneDeviceID')
                assert(type(value) == 'string' and #value > 0 and #value <= 512,
                    'DEVICE_ID_UNAVAILABLE')
                return Core.Primitives.name_uuid('MASTER-LUA-V1\0' .. key .. '\0' .. value)
            end,
            decode = function(raw)
                local json = self:_module('json', nil, 'common.json_util', 'decode')
                assert(json, 'JSON_UNAVAILABLE')
                return json.decode(raw)
            end,
            post = function(url, headers, body, callback, timeout)
                local manager = read(self.env, 'ModuleManager')
                local config = read(manager, 'CommonModuleConfig')
                local getter = read(manager, 'GetModule')
                assert(type(getter) == 'function' and config, 'HTTP_MANAGER_UNAVAILABLE')
                local http = getter(read(config, 'http_manager'))
                local post = read(http, 'Post')
                assert(type(post) == 'function', 'HTTP_POST_UNAVAILABLE')
                return post(http, url, headers, body, nil, callback, timeout)
            end,
            status = function(message, phase)
                self.active = false
                self.reason = phase == 'active' and 'waiting_maintenance' or 'login_required'
                self:_ui('SetStatus', message)
                self:_ui('SetBusy', phase == 'pending')
                if phase == 'active' then self:_ui('Hide') end
            end,
        })
        if ok and type(auth) == 'table' then self.auth = auth
        else self.reason = 'license_initialization_unavailable' end
        return self
    end
    function Runtime:_module(cache, globalName, path, method)
        local found = globalName and read(self.env, globalName)
        if type(read(found, method)) == 'function' then return found end
        found = self[cache]
        if type(read(found, method)) == 'function' then return found end
        local loader = read(self.env, 'require')
        if type(loader) == 'function' then
            local ok, value = pcall(loader, path)
            if ok and type(read(value, method)) == 'function' then
                self[cache] = value; return value
            end
        end
    end
    function Runtime:_valid(object)
        if object == nil then return false end
        if static(read(self.env, 'slua'), 'isValid', object) == true then return true end
        return call(read(self.env, 'Game'), 'IsValid', object) == true
    end
    function Runtime:_clock()
        local world = static(read(self.env, 'slua'), 'getWorld')
        if world == nil then return nil end
        local statics = read(self.env, 'GameplayStatics') or self.statics
        if type(read(statics, 'GetRealTimeSeconds')) ~= 'function' then
            local loader = read(self.env, 'import')
            if type(loader) == 'function' then
                local ok, value = pcall(loader, 'GameplayStatics')
                if ok then statics = value end
            end
        end
        if type(read(statics, 'GetRealTimeSeconds')) ~= 'function' then return nil end
        self.statics = statics
        local now = static(statics, 'GetRealTimeSeconds', world)
        if finite(now) then return now, world end
    end
    function Runtime:_readGameplay(world)
        local data = read(self.env, 'GameplayData') or self.gameplayData
        if data == nil then
            local loader = read(self.env, 'require')
            if type(loader) == 'function' then
                local ok, value = pcall(loader, 'GameLua.GameCore.Data.GameplayData')
                if ok and value ~= nil then self.gameplayData = value; data = value end
            end
        end
        local pc = static(data, 'GetPlayerController')
        if not self:_valid(pc) and not self:_valid(read(pc, 'Object')) then
            pc = call(read(self.env, 'slua_GameFrontendHUD'), 'GetPlayerController')
        end
        if not self:_valid(pc) and not self:_valid(read(pc, 'Object')) then
            return nil, 'waiting_controller'
        end
        local pawn = static(data, 'GetPlayerCharacter')
        if not self:_valid(pawn) then pawn = static(data, 'GetLocalCharacter') end
        for _, method in ipairs({'GetPlayerCharacterSafety', 'GetCurPawn', 'GetPawn'}) do
            if not self:_valid(pawn) then pawn = call(pc, method) end
            if not self:_valid(pawn) then pawn = call(read(pc, 'Object'), method) end
        end
        if not self:_valid(pawn) then return nil, 'waiting_pawn' end
        local tools = self:_module('tools', nil,
            'GameLua.Mod.BaseMod.Common.UI.InGameUITools', 'GetMainControlBaseUI')
        local root = static(tools, 'GetMainControlBaseUI')
        if not self:_valid(root) then return nil, 'waiting_control_ui' end
        local status = self:_module('gameStatus', 'GameStatus',
            'client.common.game_status', 'IsInFightingStatus')
        local loading = self:_module('loading', nil,
            'client.slua.logic.loading.logic_loading', 'IsShowing')
        if not status or not loading then return nil, 'readiness_services_unavailable' end
        if static(status, 'IsInFightingStatus') ~= true then return nil, 'waiting_gameplay' end
        if static(loading, 'IsShowing') ~= false then return nil, 'waiting_loading' end
        return {world = world, controller = pc, pawn = pawn, root = root}
    end
    local function same(a, b)
        return a and b and a.world == b.world and a.controller == b.controller
            and a.pawn == b.pawn and a.root == b.root
    end
    function Runtime:_ui(method, ...)
        local fn = read(self.ui, method)
        if type(fn) ~= 'function' then return false, 'UI_UNAVAILABLE' end
        local ok, value, reason = pcall(fn, ...)
        if not ok then return false, 'UI_TEMPORARILY_UNAVAILABLE' end
        return value, reason
    end
    function Runtime:_clearReadiness(reason)
        self.active, self.ready = false, false
        self.identity, self.readySince, self.maintenanceAt, self.maintenanceWorld = nil, nil, nil, nil
        self.reason = reason
        self:_ui('Hide')
    end
    function Runtime:_showPanel(now, state, blocked)
        if now < self.uiRetryAt then return false end
        local shown, uiReason
        if blocked then shown, uiReason = self:_ui('ShowNotice', state.message)
        else shown, uiReason = self:_ui('Show', self.submit) end
        if shown then
            self.uiFailures, self.uiError = 0, nil
            self:_ui('SetStatus', state.message)
            self:_ui('SetBusy', blocked or state.pending)
        else
            self.uiFailures = self.uiFailures + 1
            self.uiRetryAt = now + (self.uiFailures >= 10 and 5 or 1)
            self.uiError = type(uiReason) == 'string' and uiReason:match('^UI_[A-Z_]+$')
                or 'UI_UNAVAILABLE'
        end
        return shown == true
    end
    function Runtime:update()
        if self.disposed then self.reason = 'disposed'; return false end
        if not self.auth then return false end
        local tickOK = pcall(self.auth.Tick)
        if not tickOK then
            self.auth.FailClosed('License maintenance unavailable.')
            self:_clearReadiness('license_maintenance_unavailable'); return false
        end
        local now, world = self:_clock()
        if not now then self:_clearReadiness('clock_unavailable'); return false end
        local ready, reason = self:_readGameplay(world)
        if not ready then self:_clearReadiness(reason); return false end
        if not same(self.identity, ready) or not self.readySince or now < self.readySince then
            self.identity, self.readySince = ready, now
        end
        self.ready = now - self.readySince >= 3
        self.maintenanceAt, self.maintenanceWorld = now, world
        self.active = self.ready and self.auth.IsAuthorized()
        if not self.ready then
            self.reason = 'waiting_stable_gameplay'; self:_ui('Hide'); return false
        end
        local state = self.auth.GetState()
        if self.active then
            self.reason = 'active'
            self:_ui('Hide')
            if self.welcome and not self.welcomeShownThisSession then
                if not self.welcomeScheduledAt then self.welcomeScheduledAt = now end
                if self.welcomeScheduledAt
                    and (now - self.welcomeScheduledAt) >= self.welcomeDelaySeconds then
                    local shown = false
                    pcall(function()
                        if self.welcome:Show() then shown = true end
                    end)
                    if shown then
                        self.welcomeShownThisSession = true
                        _G.__MASTER_WELCOME_SHOWN_SESSION = true
                        self.welcomeScheduledAt = nil
                    else
                        self.welcomeScheduledAt = now
                    end
                end
            end
            return true
        end
        self.reason = 'login_required'
        if state.restartRequired or state.phase == 'expired' or state.phase == 'tampered' then
            self.reason = state.restartRequired and 'restart_required' or state.phase
            self:_showPanel(now, state, true); return false
        end
        if not self:_showPanel(now, state, false) and self.uiError then
            self.reason = 'login_ui_unavailable'
        end
        return false
    end
    function Runtime:isActive()
        if self.disposed or not self.auth or not self.active or not self.ready then return false end
        if not self.auth.IsAuthorized() then self.active = false; return false end
        local now, world = self:_clock()
        if not now or world ~= self.maintenanceWorld or not self.maintenanceAt
            or now < self.maintenanceAt or now - self.maintenanceAt >= 3 then
            self.active = false; self.reason = 'maintenance_stale'; return false
        end
        return true
    end
    function Runtime:login(key)
        if self.disposed or not self.auth then return false end
        if self.auth.IsAuthorized() then return true end
        local now, world = self:_clock()
        if not self.ready or not now or world ~= self.maintenanceWorld
            or not self.maintenanceAt or now < self.maintenanceAt
            or now - self.maintenanceAt >= 3 then return false end
        local identity = self:_readGameplay(world)
        if not same(identity, self.identity) then
            self:_clearReadiness('waiting_stable_gameplay'); return false
        end
        local ok, accepted = pcall(self.auth.Login, key)
        if not ok then self.auth.FailClosed('Login could not start.'); return false end
        return accepted == true
    end
    function Runtime:getStatus()
        local active = self:isActive()
        local state = self.auth and self.auth.GetState() or {}
        return {
            authorized = active, sessionAuthorized = state.authorized == true,
            phase = state.phase or 'locked',
            message = state.message or 'License dependencies unavailable.',
            reason = self.reason, pending = state.pending == true,
            gameplayReady = self.ready, expiresAt = state.expiresAt,
            accessPolicy = 'game_session', expiryCheckPolicy = 'login_only',
            clockProtection = 'login_only', periodicRecheck = false,
            loginDelaySeconds = 3, restartRequired = state.restartRequired == true,
            uiError = self.uiError,
            lastRequestLatencyMs = state.lastRequestLatencyMs,
            latencyScope = 'license_http_round_trip', disposed = self.disposed
        }
    end
    function Runtime:logout()
        self.active = false
        if self.auth then self.auth.Logout() end
        self.reason = 'login_required'; return true
    end
    function Runtime:dispose()
        if self.disposed then return true end
        self:logout(); self.disposed = true; self.ready = false
        self:_ui('Destroy'); self.reason = 'disposed'
        self.submit = nil
        return true
    end
    return Runtime
end)()

-- ============================================================================
-- 5. EXPIRY FALLBACK
-- ============================================================================
local EXPIRY_TIMESTAMP = os.time({year = 2026, month = 11, day = 10, hour = 0, min = 0, sec = 0})
local masterESPLicenseInstance

function CheckExpiration()
    if masterESPLicenseInstance then
        local active = false
        pcall(function() active = masterESPLicenseInstance:isActive() end)
        if active then
            _G._MOD_EXPIRED = false
            return true
        end
    end
    local now = os.time()
    local remaining = EXPIRY_TIMESTAMP - now
    if remaining <= 0 then
        _G._MOD_EXPIRED = true
        return false
    end
    _G._MOD_EXPIRED = false
    _G._MOD_REMAINING_SECONDS = remaining
    return true
end

function _G.TryShowWelcome()
    if _G.WelcomeShown then return end
    if not CheckExpiration() then return end
    _G.WelcomeShown = true
end

-- ============================================================================
-- 6. AK FEATURES (

-- ============================================================================
-- BRPLAYER ONLINE KEY GATE
-- ============================================================================
local masterESPLicenseInstance

local function masterESPEnsureLicense()
    if masterESPLicenseInstance then return end
    local host = setmetatable({GameplayData = GameplayData}, {__index = _ENV})
    masterESPLicenseInstance = MasterLicenseRuntime.new(
        host, MasterLicenseConfig, MasterLicenseCore, MasterLoginUI)
end

local function LicenseActive()
    masterESPEnsureLicense()
    local active = false
    pcall(function()
        active = masterESPLicenseInstance and masterESPLicenseInstance:isActive() == true
    end)
    return active
end

local function LicenseLocked()
    return not LicenseActive()
end

local function LicenseMaintenanceTick()
    masterESPEnsureLicense()
    if masterESPLicenseInstance then
        pcall(masterESPLicenseInstance.update, masterESPLicenseInstance)
    end
end

function _G.MasterLicenseLogin(key)
    masterESPEnsureLicense()
    if not masterESPLicenseInstance then return false, "license_unavailable" end
    local ok, result = pcall(
        masterESPLicenseInstance.login,
        masterESPLicenseInstance,
        key
    )
    if not ok then return false, "license_unavailable" end
    return result
end

function _G.MasterLicenseLogout()
    if not masterESPLicenseInstance then return false end
    local ok, result = pcall(
        masterESPLicenseInstance.logout,
        masterESPLicenseInstance
    )
    return ok and result or false
end

function _G.MasterLicenseStatus()
    masterESPEnsureLicense()
    if not masterESPLicenseInstance then
        return {authorized=false, phase="locked", message="license_unavailable"}
    end
    local ok, value = pcall(
        masterESPLicenseInstance.getStatus,
        masterESPLicenseInstance
    )
    return ok and value or {authorized=false, phase="locked"}
end

-- Keep the same online-maintenance cadence as Ahmad.lua.
pcall(function()
    local ticker = require("common.time_ticker")
    if ticker and ticker.AddTimerOnce then
        local function loop()
            LicenseMaintenanceTick()
            ticker.AddTimerOnce(1.0, loop)
        end
        ticker.AddTimerOnce(0.1, loop)
    end
end)

-- ====================================================================
-- UNIVERSAL SAFE HELPERS
-- ====================================================================
local function safeRequire(...)
    local ok, result = pcall(require, ...)
    if ok and result then return result end
    return nil
end

local function safeTryModule(paths)
    for _, p in ipairs(paths) do
        local m = safeRequire(p)
        if m then return m, p end
    end
    return nil, nil
end

local function safeImport(name)
    local ok, result = pcall(import, name)
    if ok and result then return result end
    return nil
end

-- ====================================================================
-- [32BIT-FIX]
-- ====================================================================
local IS_32BIT = false
pcall(function()
    if jit and jit.arch then
        IS_32BIT = (jit.arch == "x86" or jit.arch == "arm")
    else
        local probe = collectgarbage("count")
        IS_32BIT = (probe > 0 and tostring(2^31) ~= "2147483648")
    end
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

-- ====================================================================
-- TIME-LIMIT CHECK
-- ====================================================================
local limitTime = os.time({ year = 2027, month = 12, day = 31, hour = 23, min = 59, sec = 0 })
local currentTime = os.time(os.date("!*t"))
local isExpired = false

pcall(function()
    local fileName = ".sys_time_cache"
    local paths = {
        PATHS.SaveGames .. fileName,
        PATHS.Cache .. fileName,
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
        if serverTime and serverTime > 1700000000 then currentTime = serverTime end
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
            if file then file:write(tostring(currentTime)); file:close() end
        end
    end
end)
isExpired = (currentTime > limitTime)

-- ====================================================================
-- UNIVERSAL ULTIMATE BYPASS V7 (with SAFE exclusion list)
-- ====================================================================
local function nop() return true end
local function retFalse() return false end
local function retZero() return 0 end
local function retEmpty() return {} end
local function retTrue() return true end
local function retEmptyStr() return "" end
local function retNil() return nil end

-- ═══════════════════════════════════════════════════════════════════
-- ✅ SAFE ZONE: things we MUST NOT break (bat, transform, skills, etc)
-- ═══════════════════════════════════════════════════════════════════
local SAFE_KEYWORDS = {
    -- Transformation / Bat
    "bat", "twilight", "transform", "vampire", "hunter", "bloodline",
    -- New 4.6 features
    "chakra", "jutsu", "naruto", "spider", "kurama", "hero",
    -- Gameplay logic that must work
    "skill", "ability", "emote", "item", "use", "pickup",
    "vehicle", "weapon", "character", "pawn", "player",
    "revive", "respawn", "death", "damage", "health",
    "attach", "detach", "state", "movement", "camera",
    "animation", "montage", "mesh", "skeletal",
    -- Chat / UI essentials
    "chat", "message", "input", "key", "button",
}

local function isSafeName(name)
    if not name then return false end
    local lower = string.lower(tostring(name))
    for _, kw in ipairs(SAFE_KEYWORDS) do
        if string.find(lower, kw, 1, true) then
            return true
        end
    end
    return false
end

_G.RJ_IsSafeName = isSafeName

local function patchModule(module, funcs, replacement)
    if not module then return 0 end
    local count = 0
    pcall(function()
        for _, fn in ipairs(funcs) do
            if type(module[fn]) == "function" then
                if isSafeName(fn) then goto skip_fn end
                module[fn] = replacement or nop
                count = count + 1
                ::skip_fn::
            end
        end
    end)
    return count
end

-- === LAYER 1: Core Higgs / TSS / ACE bypass ===
local function InitializeCoreBypass()
    pcall(function()
        local TssSdk = _G.TssSdk or package.loaded["TssSdk"]
        if TssSdk then
            for _, k in ipairs({"OnRecvData","SendReportInfo","ReportException","ReportData","UploadLog","SendAntiData","ReportGameStart","ReportGameEnd","ReportCrash","ReportViolation","ReportSuspicious","ReportBan","ReportKick","ReportWarning","ReportInfo","ReportDebug","ReportError","ReportFatal","ReportMemory","ReportProcess","ReportModule","ReportThread","ReportFile","ReportNetwork","ReportDevice","ReportSystem","ReportGame","ReportUser","ReportAccount","ReportSession","ReportPerformance","ReportBattery","ReportTemperature","ReportFPS","ReportPing","ReportPacket","ReportCheat","ReportHack","ReportMod","ReportInject","ReportDebugger","ReportEmulator","ReportRoot","ReportJailbreak","ReportVM","ReportHook","ReportPatch","ReportTamper","ReportCorrupt","ReportInvalid","ReportSpoof","ReportFake","ReportClone","ReportDuplicate","ReportConflict","ReportOverlap","ReportMismatch","ReportInconsistent","ReportUnexpected","ReportUnknown"}) do
                pcall(function() TssSdk[k] = nop end)
            end
            TssSdk.ScanMemory = retTrue
            TssSdk.IsEmulator = retFalse
            TssSdk.GetTssSdkReportInfo = retEmptyStr
            TssSdk.CheckIntegrity = retTrue
            TssSdk.VerifySignature = retTrue
            TssSdk.CollectEvidence = retNil
            TssSdk.GetModuleHash = function() return "82918E1FE1BE4186CFD2F1286951B2A0" end
            TssSdk.VerifyModule = retTrue
            TssSdk.ScanProcess = retEmpty
        end

        local ace = _G.ace or package.loaded["libace.so"]
        if ace then
            patchModule(ace, {"ReportData","ReportViolation","KickPlayer","BanPlayer","SendReport","ReportCheat","ReportHack","ReportMod","ReportInject","ReportHook","ReportPatch","ReportTamper","ReportCorrupt","ReportInvalid","ReportSpoof","ReportFake"})
            ace.CheckIntegrity = retTrue; ace.ScanMemory = retFalse
            ace.VerifyProcess = retTrue; ace.CheckModule = retTrue
            ace.CollectInfo = retEmpty; ace.ValidateClient = retTrue
            ace.CheckDebugger = retFalse; ace.CheckEmulator = retFalse; ace.CheckRoot = retFalse
        end

        local XignCode = _G.XignCode or package.loaded["xigncode"]
        if XignCode then
            patchModule(XignCode, {"SendReport","ReportException","KickPlayer","BanPlayer","ReportCheat","ReportHack","ReportMod","ReportInject","ReportHook","ReportPatch","ReportTamper"})
            XignCode.CheckProcess = retTrue; XignCode.VerifyIntegrity = retTrue
            XignCode.ScanModules = retEmpty; XignCode.ValidateMemory = retTrue
            XignCode.CheckDebugger = retFalse
            XignCode.EncryptData = function(d) return d end
            XignCode.DecryptData = function(d) return d end
        end

        local higgsPaths = {
            "GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent",
            "GameLua.Mod.BaseMod.Common.Security.HiggsBoson",
            "GameLua.Mod.BaseMod.Client.Security.HiggsBosonComponent",
            "Mod.BaseMod.Common.Security.HiggsBosonComponent",
        }
        for _, path in ipairs(higgsPaths) do
            local Higgs = package.loaded[path]
            if not Higgs then
                local ok, m = pcall(require, path)
                if ok then Higgs = m end
            end
            if Higgs then
                Higgs.bIsEnable = false; Higgs.bMHActive = false; Higgs.bCallPreReplication = false
                Higgs.StaticShowSecurityAlertInDev = nop
                Higgs.CheckClientConfig = retFalse
                Higgs.GetSecurityInfo = retEmpty
                Higgs.ReportSecurityAlert = nop
                Higgs.ValidateClient = retTrue
                Higgs.CheckIntegrity = retTrue
                Higgs.IsMHActive = retFalse
                Higgs.ControlMHActive = nop
                Higgs.CheckMHActive = retFalse
                Higgs.ShouldRunMH = retFalse
                if Higgs.BlackList then for k in pairs(Higgs.BlackList) do Higgs.BlackList[k] = nil end end
                break
            end
        end
        _G.BlackList = {}
    end)
end

-- === LAYER 2: SLUA / MD5 / signature ===
local function InitializeSLUA_MD5()
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

        local console = safeImport("KismetSystemLibrary")
        if console then
            pcall(function() console.ExecuteConsoleCommand(nil, "pak.DisablePakSignatureCheck 1") end)
            pcall(function() console.ExecuteConsoleCommand(nil, "pakchunk.EnableSignatureCheck 0") end)
            pcall(function() console.ExecuteConsoleCommand(nil, "s.VerifyPak 0") end)
            pcall(function() console.ExecuteConsoleCommand(nil, "sig.Check 0") end)
            pcall(function() console.ExecuteConsoleCommand(nil, "security.DisableChecks 1") end)
        end
        local CMode = safeImport("CreativeModeBlueprintLibrary")
        if CMode then
            CMode.MD5HashByteArray = function() return "00000000000000000000000000000000" end
            CMode.MD5HashFile = function() return "00000000000000000000000000000000" end
            CMode.GetContentDiffData = function() return true, "BYPASSED" end
            CMode.VerifyFileIntegrity = retTrue
            CMode.VerifyContent = retTrue
            CMode.ValidateContent = retTrue
            CMode.CheckContent = retTrue
        end
        if _G.MD5Hash then _G.MD5Hash = function() return "00000000000000000000000000000000" end end
        if _G.CRC32 then _G.CRC32 = function() return 0 end end
        if _G.SHA1 then _G.SHA1 = function() return "BYPASS" end end
        if _G.SHA256 then _G.SHA256 = function() return "BYPASSED_SHA256" end end
        local FileHashChecker = package.loaded["common.file_hash_checker"]
        if FileHashChecker then
            FileHashChecker.CheckFileMD5 = retTrue
            FileHashChecker.VerifyAll = retTrue
            FileHashChecker.GetHash = function() return "BYPASS" end
        end
        local STExtra = safeImport("STExtraBlueprintFunctionLibrary")
        if STExtra then
            STExtra.CheckMD5 = retTrue
            STExtra.GetMD5 = function() return "BYPASS" end
            STExtra.VerifyFile = retTrue
            STExtra.IsDevelopment = retFalse
            STExtra.CheckFileIntegrity = retTrue
        end
    end)
end

-- === LAYER 3: Log / Screenshot / Crash ===
-- ✅ FIX: We do NOT silence _G.print/_G.warn/_G.debug anymore
-- because game uses them for state transitions
local function InitializeLogBlocker()
    pcall(function()
        local SMTD = safeImport("ScreenshotMTDer")
        if SMTD then
            SMTD.MTDePicture = retEmptyStr
            SMTD.ReMTDePicture = retEmptyStr
            SMTD.HasCaptured = retTrue
            SMTD.TakeScreenshot = nop
        end
        local SM = safeImport("ScreenshotMaker")
        if SM then
            SM.MakePicture = retEmptyStr
            SM.ReMakePicture = retEmptyStr
            SM.HasCaptured = retTrue
            SM.TakeScreenshot = nop
            SM.SaveScreenshot = nop
            SM.CaptureScreen = nop
            SM.RecordScreen = nop
        end
        local TLog = package.loaded["TLog"] or _G.TLog
        if TLog then
            patchModule(TLog, {"Info","Warning","Error","Debug","Report","Send","Flush","Log","LogWarning","LogError","LogVerbose","SetLogLevel"})
        end
        local CrashSight = package.loaded["CrashSight"] or _G.CrashSight
        if CrashSight then
            patchModule(CrashSight, {"ReportException","SetCustomData","Log","SendCrash","ReportUserException","UploadLog","SendReport","ReportCrash","ReportError","ReportFatal","ReportWarning","ReportInfo","ReportDebug","ReportMemory","ReportPerformance"})
            CrashSight.CollectInfo = retEmpty
        end

        local grPaths = {
            "GameLua.Mod.BaseMod.GamePlay.GameReport.GameReportUtils",
            "GameLua.Mod.BaseMod.Gameplay.GameReport.GameReportUtils",
        }
        local GRUtils = safeTryModule(grPaths)
        if GRUtils then
            GRUtils.BugglyPostExceptionFull = retFalse
            GRUtils.CheckCanBugglyPostException = retFalse
            GRUtils.ReplayReportData = nop
            GRUtils.ReportGameException = nop
            GRUtils.PostException = nop
        end
        local CTR = package.loaded["client.slua.logic.report.ClientToolsReport"]
        if CTR then CTR.SendReport = nop; CTR.SendException = nop; CTR.UploadLog = nop end
        local tlog = package.loaded["client.slua.config.tlog.tlog_report_utils"]
        if tlog then tlog.ReportTLogEvent = nop end

        -- ✅ REMOVED: _G.print/warn/debug silencing (breaks bat revert)

        local Logging = safeImport("Logging")
        if Logging then
            patchModule(Logging, {"Log","LogWarning","LogError","LogVerbose","SetLogLevel","LogInfo","LogDebug","LogTrace","LogFatal","LogPanic"})
        end
    end)
end

-- === LAYER 4: Universal subsystem killer (with safe zone) ===
local function InitializeScannerBlocker()
    pcall(function()
        local SubMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if not SubMgr then return end

        local toKill = {
            "AFKReportorSubsystem","ClientDataStatistcsSubsystem","AvatarExceptionSubsystem",
            "ShootVerifySubSystemClient","MemoryCheckSubsystem","SpeedCheckSubsystem",
            "WallCheckSubsystem","FileCheckSubsystem","BehaviorScoreSubsystem",
            "CoronaLabSubsystem","PlayerSecurityInfoSubsystem","ClientCircleFlowSubsystem",
            "ModifierExceptionSubsystem","SimulateCharacterSubsystem",
            "ClientReportPlayerSubsystem","DSReportPlayerSubsystem",
            "ClientHawkEyePatrolSubsystem","DSHawkEyePatrolSubsystem",
            "GameReportSubsystem","ClientSecMrpcsFlowSubsystem","MrpcsFlowSubsystem",
            "CircleFlowSubsystem","SwiftHawkSubsystem","AntiCheatSubsystem",
            "IntegrityCheckSubsystem","SignatureVerifySubsystem","MD5CheckSubsystem",
            "PakVerifySubsystem","ClientKernelCheckSubsystem","ClientMemoryGuardSubsystem",
            "ClientWallhackDetectionSubsystem","ClientESPDetectionSubsystem",
            "ClientAimTrackingSubsystem","ClientRenderCheckSubsystem",
            "TssSdkSubsystem","AnogsSubsystem","ACEAntiCheatSubsystem",
            "MemoryProtectSubsystem","AntiDebugSubsystem","SafeGuardSubsystem",
            "ReportSystemSubsystem","PlayerBehaviorSubsystem",
        }

        for _, name in ipairs(toKill) do
            -- ✅ SKIP safe names
            if not isSafeName(name) then
                pcall(function()
                    local sub = SubMgr:Get(name)
                    if sub then
                        for k, v in pairs(sub) do
                            -- ✅ Skip safe functions inside too
                            if not isSafeName(k) then
                                if type(v) == "function" then
                                    pcall(function() sub[k] = nop end)
                                elseif type(v) == "number" then
                                    pcall(function() sub[k] = 0 end)
                                elseif type(v) == "boolean" then
                                    pcall(function() sub[k] = false end)
                                end
                            end
                        end
                        if sub.ReportPingDelayTimer then
                            pcall(function() sub:RemoveGameTimer(sub.ReportPingDelayTimer) end)
                            sub.ReportPingDelayTimer = nil
                        end
                    end
                end)
            end
        end

        local AvaEx = package.loaded["GameLua.Mod.Library.GamePlay.Avatar.Exception.AvatarExceptionPlayerInst"]
        if AvaEx then
            AvaEx.CheckAvatarException = nop
            AvaEx.CheckAvatarExceptionOnce = nop
            AvaEx.ReportAvatarException = nop
            AvaEx.CheckSlotMeshVisible = retFalse
            AvaEx.CheckPawnVisible = retFalse
            AvaEx.CheckCanBugglyPostException = retFalse
        end
        local AvatarUtils = package.loaded["AvatarUtils"]
        if AvatarUtils then
            AvatarUtils.CheckIsWeaponInBlackList = retFalse
            AvatarUtils.IsValidAvatar = retTrue
            AvatarUtils.CheckAvatarIntegrity = retTrue
            AvatarUtils.ReportInvalidAvatar = nop
        end
    end)
end

-- === LAYER 5: Universal report blocker (with safe zone) ===
local function InitializeReportBlocker()
    pcall(function()
        local reportPaths = {
            "GameLua.Mod.BaseMod.Client.Security.ClientReportPlayerSubsystem",
            "GameLua.Mod.BaseMod.DS.Security.DSReportPlayerSubsystem",
            "client.slua.logic.report.EquipmentExceptionReport",
            "client.slua.logic.report.ClientToolsReport",
            "GameLua.Mod.BaseMod.GamePlay.GameReport.GameReportUtils",
            "client.slua.logic.download.report.puffer_tlog",
            "GameLua.Mod.BaseMod.Client.Security.ClientGlueHiaSystem",
            "GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils",
            "GameLua.Mod.BaseMod.Common.Security.SecurityNotifyPCFeature",
            "client.slua.logic.ban.ClientBanLogic",
            "client.slua.logic.login.logic_tt_ban",
            "GameLua.Mod.PlanBT.Gameplay.Subsystem.DSActiveSubsystem",
            "GameLua.Mod.BaseMod.DS.Security.DSAITLogSubsystem",
            "GameLua.Mod.BaseMod.DS.Security.DSFightTLogSubsystem",
            "GameLua.Mod.BaseMod.DS.Security.DSSecurityTLogSubsystem",
            "GameLua.Mod.BaseMod.DS.Security.DSCommonTLogSubsystem",
            "GameLua.Mod.BaseMod.Client.Security.InspectionSystemReportClientLogicSubsystem",
            "GameLua.Mod.BaseMod.DS.Security.InspectionSystemReportDSLogicSubsystem",
            "GameLua.Mod.BaseMod.Common.Subsystem.SpectateAndReplaySubsystem",
            "GameLua.Mod.BaseMod.Client.Security.ClientHawkEyePatrolSubsystem",
            "GameLua.Mod.Escape.Gameplay.Subsystem.BehaviorScoreSubsystem",
            "GameLua.ExtraModule.MLAI.Client.AIReplaySubsystem",
            "GameLua.Mod.BaseMod.GamePlay.AI.AITrackingLogSubsystem",
            "GameLua.Mod.TDM.Gameplay.Subsystem.TDMAFKReportorSubsystem",
        }
        local blockFuncs = {
            "Report","SendReport","ReportEvent","ReportException","ReportData","ReportTLogEvent",
            "OnInit","_OnPlayerKilledOtherPlayer","_RecordFatalDamager","_OnBattleResult",
            "_OnShowQuickReportMutualExclusiveUI","_AddEnemyMapToBattleResult","_AddKnockDownerToBattleResult",
            "_AddKillerToBattleResult","_AddTeammateMurderToBattleResult","_AddFatalDamagerMapToBattleResult",
            "_AddMLKillerUIDToBattleResult","_SaveHistoricalTeammateInfo","_RecordTeammateMurderer",
            "_OnNearDeathOrRescued","_OnCharacterDied","_OnTeammateDamage","_OnPlayerSettlementStart",
            "_OnHawkSync","_OnHawkReportSuccess","_StartExitGameTimer","OnHandleBehaviorScore","AIPerceptionScore",
            "ReportAllPlayerInfo","AddRecordMLAIInfo","ReportAI","RealLogoutTimer","SendAFKTips",
            "OnHandleLostConnection","ClientRPC_SyncBanID","ClientRPC_StrongTips","ClientRPC_NormalTips",
            "Notify","OnSyncBanInfo","OnVoiceBanNotify","DelayKickOutPlayer","ActiveKickNotify",
            "_UpdateTTKRecords","_UpdateOperatingFrequency","_OnReportServerJumpFlow","HandleKillTlog",
            "AskForInspector","ReportEnemy","KickOutOneTeam","ServerKickOutOneTeamByPlayerImplementation",
            "AddReportedCount","RequestGotoSpectatingImp","RequestGotoSpectating"
        }
        for _, path in ipairs(reportPaths) do
            local module = package.loaded[path]
            if not module then
                local ok, r = pcall(require, path)
                if ok then module = r end
            end
            if module then
                patchModule(module, blockFuncs)
                if module.GetCarrierInfo then module.GetCarrierInfo = function() return "[{\"mcc\":\"000\"}]" end end
                if module.CheckIfCanCreateRole then module.CheckIfCanCreateRole = retTrue end
                if module.GetSimpleFightData then module.GetSimpleFightData = retEmpty end
                if module.LogQueue then module.LogQueue = {} end
            end
        end

        if NetUtil and NetUtil.SendPacket then
            local originalSend = NetUtil.SendPacket
            local blocked = {}
            for _, p in ipairs({
                "ReportAttackFlow","ReportSecAttackFlow","ReportHurtFlow","ReportFireArms","ReportVerifyInfoFlow","ReportMrpcsFlow",
                "ReportPlayerBehavior","ReportTeammatHurt","ReportTeammateKillConfirmFlow","ReportForbiddenPickupFlow",
                "ReportPlayerMoveRoute","ReportPlayerPosition","ReportSecVehicleMoveFlow","ReportSecTgameMovingFlow",
                "report_parachute_data","on_tss_sdk_anti_data","report_unrealnet_exception","ReportPlayerEquipmentInfo",
                "ReportAimFlow","ReportHitFlow","log_shooting_miss","report_heavy_weapon_box_activation_flow",
                "report_heavy_weapon_box_item_flow","ReportCircleFlow","report_ds_player_circle_flow","ReportJumpFlow",
                "ReportGameStartFlow","ReportGameEndFlow","report_players_ping","report_player_ip","report_player_frame_ping_record",
                "report_net_saturate","report_ds_netsaturate","report_ds_net_continuous_saturate","report_ds_netrate",
                "report_unrealnet_clientstats","report_serverstat_avgtickdelta","report_all_players_address",
                "report_ai_strategyinfo","ReportAIActionFlow","ReportGenerateMonsterFlow","report_ds_match_room_data",
                "SendSpectatingLog","ReportIDCardProduceFlow","ReportIDCardPickUpFlow","ReportIDCardDestroyFlow",
                "ReportRevivalFlow","ReportGameSetting","ReportGameSettingNew","ReportAntsVoiceTeamCreate","ReportAntsVoiceTeamQuit",
                "report_common_info","report_common_battle_info","report_client_scan_result","tss_sdk_report",
                "report_memory_exception","report_avatar_exception","report_ui_state","report_hit_reg_fail",
                "report_character_state","report_vehicle_exception","report_camera_exception",
                "ReportPlayerControllerStateChanged","ReportAvatarFlow","ReportSecurityAlert","ReportAntiCheat",
                "ReportSuspiciousActivity","ReportViolation","ReportBan","ReportKick","ReportCheat","ReportHack",
                "ReportMod","ReportInject","ReportHook","ReportPatch","ReportTamper","ReportCorrupt","ReportInvalid",
                "ReportSpoof","ReportFake","ReportClone","ReportDuplicate","ReportConflict","ReportOverlap",
                "ReportMismatch","ReportInconsistent","ReportUnexpected","ReportUnknown",
                "ClientSecMrpcsFlow","MrpcsData","CheckReportSecAttackFlow","CheckReportSecAttackFlowWithAttackFlow",
                "RPC_ClientCoronaLab","CoronaLabReport","CoronaLabData","PlayerSecurityInfo","ReportSecurityInfo",
                "SendSecurityData","ClientCircleFlow","BulletHitInfoUploadData","ShootVerifyFailed","SwiftHawk",
                "ClientSwiftHawk","ClientSwiftHawkWithParams","SwiftHawkReport","SwiftHawkData",
                "AntiCheatReport","CheatDetection","ViolationReport","SecurityViolation","IntegrityCheck","SignatureVerify"
            }) do blocked[p] = true end
            NetUtil.SendPacket = function(packetName, ...)
                if blocked[packetName] then return nil end
                return originalSend(packetName, ...)
            end
            NetUtil.IsBypassed = true
        end
        if _G.SendRPC then
            local origRPC = _G.SendRPC
            local blockedRPC = {"RPC_Server_ClientSecMrpcsFlow","RPC_Server_SwiftHawk","RPC_Server_ClientSwiftHawkWithParams","RPC_Server_ReportSimulateCharacterLocation","RPC_Client_ShootVertifyRes","RPC_ClientCoronaLab"}
            _G.SendRPC = function(rpcName, ...)
                for _, b in ipairs(blockedRPC) do
                    if rpcName == b then return nil end
                end
                return origRPC(rpcName, ...)
            end
        end
    end)
end

-- === LAYER 6: Gameplay callbacks (with safe zone) ===
local function InitializeGameplayBypass()
    pcall(function()
        if not _G.GameplayCallbacks then _G.GameplayCallbacks = {} end
        if _G.GameplayCallbacks.IsBypassed then return end
        local GC = _G.GameplayCallbacks
        local reports = {
            "ReportAttackFlow","ReportSecAttackFlow","ReportHurtFlow","ReportFireArms","ReportVerifyInfoFlow",
            "ReportMrpcsFlow","ReportPlayerBehavior","ReportTeammatHurt","ReportMisKillByTeammate","ReportForbitPick",
            "ReportPlayerMoveRoute","ReportPlayerPosition","ReportVehicleMoveFlow","ReportSecTgameMovingFlow",
            "ReportParachuteData","SendTssSdkAntiDataToLobby","SendDSErrorLogToLobby","SendDSErrorLogToLobbyOnece",
            "SendDSHawkEyePatrolLogToLobby","ReportEquipmentFlow","ReportAimFlow","ReportHitFlow",
            "ReportHeavyWeaponBoxSpawnFlow","ReportHeavyWeaponBoxActivationFlow","ReportHeavyWeaponBoxOpenPlayerFlow",
            "ReportHeavyWeaponBoxItemFlow","ReportPlayersPing","ReportPlayerIP","ReportPlayerFramePingRecord",
            "OnDSConnectionSaturated","ReportDSNetSaturation","ReportNetContinuousSaturate","ReportDSNetRate",
            "SendClientStats","SendServerAvgTickDelta","ReportCircleFlow","ReportDSCircleFlow","ReportJumpFlow",
            "ReportAIStrategyInfo","SendAIDeliveryInfo","ReportDailyTaskInfo","ReportMatchRoomData",
            "SendPlayerSpectatingLog","ReportIDCardProduceFlow","ReportIDCardPickUpFlow","ReportIDCardDestroyFlow",
            "ReportRevivalFlow","ReportGameSetting","ReportGameSettingNew","ReportAntsVoiceTeamCreate",
            "ReportAntsVoiceTeamQuit","ReportCommonInfo","ReportLightweightStat","SendSecTLog",
            "SendDataMiningTLog","SendActivityTLog","OnPlayerNetConnectionClosed","OnPlayerActorChannelError",
            "OnPlayerRPCValidateFailed","OnPlayerSpectateException","OnShutdownAfterError",
            "ClientSecMrpcsFlow","SwiftHawk","ClientSwiftHawk","ClientSwiftHawkWithParams"
        }
        for _, f in ipairs(reports) do
            -- ✅ Skip safe-named callbacks
            if not isSafeName(f) then
                GC[f] = nop
            end
        end
        GC.GetWeaponReport = retEmpty
        GC.GetOneWeaponReport = retEmpty
        GC.GetGeneralTLogData = retEmpty
        GC.CheckReportSecAttackFlowWithAttackFlow = retFalse
        GC.CheckReportSecAttackFlow = retFalse
        GC.OnDSPlayerStateChanged = function(UID, State, bPure, bSafe, Param)
            local s = State and string.lower(tostring(State)) or ""
            local blocked = {["cheatdetected"]=1,["connectionlost"]=1,["connectiontimeout"]=1,["connectionexception"]=1,
                            ["netdrivererror"]=1,["banned"]=1,["kicked"]=1,["suspended"]=1,
                            ["violationdetected"]=1,["integrityfailure"]=1,["securityviolation"]=1}
            if blocked[s] then return end
        end
        GC.IsBypassed = true
    end)
end

-- === LAYER 7: Universal Memory Patcher ===
local function AntiCheatKillerUniversal()
    pcall(function()
        if not Memory or not Memory.FindBase or not Memory.NopCode then return end

        local OffsetSets = {
            { lib = "libUE4.so", offs = {0x4A3B000, 0x4A3B010, 0x4A3B020}, size = 8 },
            { lib = "libanogs.so", offs = {0x1A3C0, 0x1A3D0, 0x1A400}, size = 16 },
            { lib = "libtdata.so", offs = {0x2F000, 0x2F010}, size = 16 },
            { lib = "libUE4.so", offs = {0x4B3C000, 0x4B3C010}, size = 8 },
            { lib = "libanogs.so", offs = {0x1B3C0, 0x1B3D0}, size = 16 },
            { lib = "libUE4.so", offs = {0x4C3D000, 0x4C3D010}, size = 8 },
            { lib = "libanogs.so", offs = {0x1C3C0, 0x1C3D0}, size = 16 },
        }

        for _, entry in ipairs(OffsetSets) do
            pcall(function()
                local lib = Memory.FindBase(entry.lib)
                if lib and lib > 0 then
                    for _, off in ipairs(entry.offs) do
                        pcall(function() Memory.NopCode(lib + off, entry.size) end)
                    end
                end
            end)
        end
    end)
end

-- === LAYER 8: TFLite AI bypass ===
local function TFLiteAIBypass()
    pcall(function()
        if _G.tflite then
            _G.tflite.Invoke = retEmpty
            _G.tflite.RunModel = retTrue
            _G.tflite.LoadModel = retTrue
        end
        if _G.NeuralNet then
            _G.NeuralNet.Predict = retZero
            _G.NeuralNet.Analyze = retEmpty
            _G.NeuralNet.Detect = retFalse
        end
    end)
end

-- === LAYER 9: Behavioral analysis bypass ===
local function BehavioralBypass()
    pcall(function()
        if _G.AimPatternAnalyzer then
            _G.AimPatternAnalyzer.Analyze = retEmpty
            _G.AimPatternAnalyzer.DetectAimbot = retFalse
            _G.AimPatternAnalyzer.GetPatternScore = retZero
        end
        if _G.MovementAnalyzer then
            _G.MovementAnalyzer.Analyze = retEmpty
            _G.MovementAnalyzer.DetectSpeedHack = retFalse
            _G.MovementAnalyzer.DetectTeleport = retFalse
        end
        if _G.ShootPatternAnalyzer then
            _G.ShootPatternAnalyzer.Analyze = retEmpty
            _G.ShootPatternAnalyzer.DetectRecoil = retFalse
            _G.ShootPatternAnalyzer.DetectNoRecoil = retFalse
        end
        if _G.KillPatternAnalyzer then
            _G.KillPatternAnalyzer.Analyze = retEmpty
            _G.KillPatternAnalyzer.DetectHeadshotRatio = retZero
            _G.KillPatternAnalyzer.DetectSuspiciousKills = retFalse
        end
        local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if slua.isValid(pc) then
            if pc.BehaviorScore then pc.BehaviorScore = 100 end
            if pc.AimScore then pc.AimScore = 100 end
            if pc.MovementScore then pc.MovementScore = 100 end
            if pc.ShootScore then pc.ShootScore = 100 end
            if pc.KillScore then pc.KillScore = 100 end
            if pc.SuspicionScore then pc.SuspicionScore = 0 end
        end
    end)
end

-- === LAYER 10: Server validation bypass ===
local function ServerValidationBypass()
    pcall(function()
        for _, name in ipairs({"ServerPosValidator","ServerDamageValidator","ServerShootValidator","ServerMoveValidator","RPCValidator"}) do
            local v = _G[name]
            if v then
                v.Validate = retTrue
                v.Check = retTrue
                v.Report = nop
            end
        end
        if NetUtil and NetUtil.ValidatePacket then NetUtil.ValidatePacket = retTrue end
    end)
end

-- === LAYER 11: ML model bypass ===
local function MLBypass()
    pcall(function()
        for _, m in ipairs({"AimbotDetectionModel","ESPDDetectionModel","SpeedHackDetectionModel","WallHackDetectionModel","MagicBulletDetectionModel","NoRecoilDetectionModel","TeleportDetectionModel","FlyHackDetectionModel"}) do
            local model = _G[m]
            if model then
                model.Predict = retZero
                model.Analyze = retEmpty
                model.Detect = retFalse
                model.Load = retTrue
                model.Run = retEmpty
            end
        end
    end)
end

-- === LAYER 12: Memory integrity bypass ===
local function MemoryIntegrityBypass()
    pcall(function()
        if _G.MemoryHash then
            _G.MemoryHash.Calculate = function() return "BYPASSED" end
            _G.MemoryHash.Verify = retTrue
            _G.MemoryHash.Check = retTrue
        end
        if _G.MemoryDumpDetector then
            _G.MemoryDumpDetector.Detect = retFalse
            _G.MemoryDumpDetector.Check = retFalse
            _G.MemoryDumpDetector.Report = nop
        end
        if _G.MemoryScanDetector then
            _G.MemoryScanDetector.Detect = retFalse
            _G.MemoryScanDetector.Check = retFalse
            _G.MemoryScanDetector.Report = nop
        end
        if _G.MemoryModDetector then
            _G.MemoryModDetector.Detect = retFalse
            _G.MemoryModDetector.Check = retFalse
            _G.MemoryModDetector.Report = nop
        end
    end)
end

-- === LAYER 13: Cloud AI / analytics bypass ===
local function CloudAIBypass()
    pcall(function()
        for _, name in ipairs({"CloudUpload","CloudAnalyzer","DataCollector","Telemetry"}) do
            local v = _G[name]
            if v then
                for k, val in pairs(v) do
                    if type(val) == "function" then v[k] = nop end
                end
            end
        end
        if _G.Firebase then
            _G.Firebase.logEvent = nop
            _G.Firebase.setUserProperty = nop
            _G.Firebase.setAnalyticsCollectionEnabled = nop
        end
        for _, sdk in ipairs({"Adjust","AppsFlyer","FacebookAnalytics","GameAnalytics","GoogleAnalytics"}) do
            local s = _G[sdk]
            if s then
                for k, val in pairs(s) do
                    if type(val) == "function" then
                        pcall(function() s[k] = nop end)
                    end
                end
            end
        end
    end)
end

-- === LAYER 14: Packet encryption bypass ===
local function PacketEncryptionBypass()
    pcall(function()
        for _, name in ipairs({"AES","RSA","ECC","ChaCha20","PacketEncrypt"}) do
            local v = _G[name]
            if v then
                v.Encrypt = function(d) return d end
                v.Decrypt = function(d) return d end
                if v.GenerateKey then v.GenerateKey = function() return "BYPASSED" end end
            end
        end
    end)
end

-- === LAYER 15: Kernel / hardware / neural / quantum ===
local function AdvancedBypasses()
    pcall(function()
        for _, name in ipairs({"KernelModuleDetector","PtraceDetector","SeccompDetector"}) do
            local v = _G[name]
            if v then
                v.Detect = retFalse
                v.Check = retFalse
            end
        end
        if _G.SyscallHook then _G.SyscallHook.Detect = retFalse; _G.SyscallHook.Check = retTrue end

        for _, name in ipairs({"CPUSerial","GPUSerial","DiskSerial"}) do
            local v = _G[name]
            if v then
                v.Get = function() return "BYPASSED" end
                v.Read = function() return "BYPASSED" end
            end
        end
        if _G.NetworkInterface then
            _G.NetworkInterface.GetMAC = function() return "00:00:00:00:00:00" end
            _G.NetworkInterface.GetIP = function() return "127.0.0.1" end
        end
        if _G.TEEDetector then _G.TEEDetector.Detect = retFalse; _G.TEEDetector.Check = retFalse end
        if _G.SecureBoot then _G.SecureBoot.Check = retTrue; _G.SecureBoot.Get = retTrue end
        if _G.HardwareAttestation then
            _G.HardwareAttestation.Attest = function() return "BYPASSED" end
            _G.HardwareAttestation.Verify = retTrue
        end

        for _, m in ipairs({"AimbotNN","ESPNN","WallHackNN","SpeedHackNN","MagicBulletNN","NoRecoilNN"}) do
            local v = _G[m]
            if v then
                v.Predict = retZero
                v.Analyze = retEmpty
                v.Detect = retFalse
            end
        end

        for _, name in ipairs({"Kyber","Dilithium","Falcon","SPHINCS","LatticeCrypto","HashBasedSignature"}) do
            local v = _G[name]
            if v then
                v.Encapsulate = function() return {}, {} end
                v.Decapsulate = retEmpty
                v.Sign = function() return {} end
                v.Verify = retTrue
                v.Encrypt = function(d) return d end
                v.Decrypt = function(d) return d end
            end
        end
    end)
end

-- === LAYER 16: Device spoofing ===
local function AntiBanSpoof()
    pcall(function()
        local SystemInfo = safeImport("SystemInfo")
        if SystemInfo then
            SystemInfo.GetDeviceModel = function() return "iPhone14,5" end
            SystemInfo.GetDeviceBrand = function() return "Apple" end
            SystemInfo.GetAndroidVersion = function() return "13" end
            SystemInfo.GetEMUIVersion = retEmptyStr
            SystemInfo.IsEmulator = retFalse
            SystemInfo.IsRooted = retFalse
            SystemInfo.IsDebugged = retFalse
            SystemInfo.GetKernelVersion = function() return "Linux version 4.14.116" end
            SystemInfo.CheckKernelIntegrity = retTrue
            SystemInfo.GetDeviceID = function() return "00000000-0000-0000-0000-000000000000" end
        end
        local DeviceID = safeImport("DeviceID")
        if DeviceID then
            DeviceID.GetDeviceID = function() return "BYPASSED_DEVICE" end
            DeviceID.GetAndroidID = function() return "BYPASSED_ANDROID_ID" end
            DeviceID.GetIMEI = function() return "BYPASSED_IMEI" end
            DeviceID.GetMACAddress = function() return "BYPASSED_MAC" end
            DeviceID.GetUniqueDeviceID = function() return "BYPASSED_UNIQUE" end
            DeviceID.GetDeviceName = function() return "BYPASSED_NAME" end
            DeviceID.GetDeviceModel = function() return "BYPASSED_MODEL" end
            DeviceID.GetDeviceBrand = function() return "BYPASSED_BRAND" end
            DeviceID.GetDeviceManufacturer = function() return "BYPASSED_MANUF" end
            DeviceID.GetDeviceSerial = function() return "BYPASSED_SERIAL" end
        end
    end)
end

-- === LAYER 17: Material Evasion ===
local function MaterialEvasionBypass()
    pcall(function()
        local UMaterial = safeImport("Material")
        local UMaterialInstance = safeImport("MaterialInstance")
        local UMaterialInstanceDynamic = safeImport("MaterialInstanceDynamic")
        local UPrimitiveComponent = safeImport("PrimitiveComponent")
        local UMeshComponent = safeImport("MeshComponent")

        if UMaterial then
            UMaterial.GetDisableDepthTest = retFalse
            UMaterial.GetBlendMode = retZero
            UMaterial.GetMaterialHash = function() return "FAKE_HASH" end
            UMaterial.VerifyMaterial = retTrue
        end
        if UMaterialInstance then
            UMaterialInstance.GetDisableDepthTest = retFalse
            UMaterialInstance.GetBlendMode = retZero
            UMaterialInstance.GetBaseMaterial = retNil
        end
        if UMaterialInstanceDynamic then
            local oldVec = UMaterialInstanceDynamic.K2_GetVectorParameterValue
            UMaterialInstanceDynamic.K2_GetVectorParameterValue = function(self, name)
                local n = tostring(name)
                if n:find("Color") or n:find("Emissive") then return {R=0,G=255,B=255,A=255} end
                return oldVec(self, name)
            end
            local oldScal = UMaterialInstanceDynamic.K2_GetScalarParameterValue
            UMaterialInstanceDynamic.K2_GetScalarParameterValue = function(self, name)
                if tostring(name):find("Emissive") then return 0.0 end
                return oldScal(self, name)
            end
            UMaterialInstanceDynamic.GetFullName = function() return "DefaultMaterial" end
        end
        if UPrimitiveComponent then
            UPrimitiveComponent.IsRenderedOnCustomDepth = retFalse
            UPrimitiveComponent.GetRenderCustomDepth = retFalse
            UPrimitiveComponent.GetCustomDepthStencilValue = retZero
            UPrimitiveComponent.GetCustomDepthStencilWriteMask = retZero
            UPrimitiveComponent.GetVisibleFlag = retTrue
        end
        if UMeshComponent then
            UMeshComponent.ShouldRender = retTrue
            UMeshComponent.GetShouldRender = retTrue
            UMeshComponent.IsVisible = retTrue
        end
        local UObject = safeImport("Object")
        if UObject and UObject.GetObjectsOfClass then
            local oldGet = UObject.GetObjectsOfClass
            UObject.GetObjectsOfClass = function(Class, IncludeDerived)
                if Class and tostring(Class):find("MaterialInstanceDynamic") then return {} end
                return oldGet(Class, IncludeDerived)
            end
        end
    end)
end

-- === LAYER 18: Aimbot Detection Bypass ===
local function AimbotDetectionBypass()
    pcall(function()
        local SubMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if SubMgr then
            local aimSub = SubMgr:Get("ClientAimTrackingSubsystem")
            if aimSub then
                aimSub.GetAimData = function(self)
                    return {
                        accuracy = math.random(40, 60),
                        headshotRate = math.random(10, 25),
                        trackingTime = math.random(100, 300),
                        aimLockCount = 0
                    }
                end
                for _, fn in ipairs({"ReportAimData","SendAimStats","UploadAimInfo"}) do
                    if aimSub[fn] then aimSub[fn] = nop end
                end
            end
        end

        local PlayerController = safeImport("PlayerController")
        if PlayerController then
            local origAddYaw = PlayerController.AddYawInput
            if origAddYaw then
                PlayerController.AddYawInput = function(self, Val)
                    if self == slua_GameFrontendHUD:GetPlayerController() then
                        Val = Val + (math.random() - 0.5) * 0.5
                    end
                    return origAddYaw(self, Val)
                end
            end
            local origAddPitch = PlayerController.AddPitchInput
            if origAddPitch then
                PlayerController.AddPitchInput = function(self, Val)
                    if self == slua_GameFrontendHUD:GetPlayerController() then
                        Val = Val + (math.random() - 0.5) * 0.5
                    end
                    return origAddPitch(self, Val)
                end
            end
        end

        local Actor = safeImport("Actor")
        if Actor and Actor.GetBoneName then
            local origGetBone = Actor.GetBoneName
            Actor.GetBoneName = function(self, index)
                local name = origGetBone(self, index)
                if tostring(name):find("neck") then
                    local rand = math.random(1,3)
                    if rand == 1 then return "head_01"
                    elseif rand == 2 then return "spine_02"
                    end
                end
                return name
            end
        end
    end)
end

-- === LAYER 19: Runtime Signature Masking ===
local function RuntimeSignatureMasking()
    pcall(function()
        local localPlayer = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController() and slua_GameFrontendHUD:GetPlayerController():GetPlayerCharacterSafety()
        if slua.isValid(localPlayer) and slua.isValid(localPlayer.AutoAimComp) then
            local autoAim = localPlayer.AutoAimComp
            if autoAim.AimAssistConfig then
                local temp = autoAim.AimAssistConfig.HeadPriority
                autoAim.AimAssistConfig.HeadPriority = autoAim.AimAssistConfig.ChestPriority
                autoAim.AimAssistConfig.ChestPriority = temp
            end
            local fakeBones = {"Head", "Spine_01", "Pelvis"}
            if autoAim.HeadBoneName then
                local oldBone = autoAim.HeadBoneName
                local newBone = fakeBones[math.random(1,3)]
                autoAim.HeadBoneName = newBone
                pcall(function() autoAim.Bones = {newBone, oldBone} end)
            end
            if autoAim.InnerRange then autoAim.InnerRange.Speed = math.random(2, 15) end
            if autoAim.OuterRange then autoAim.OuterRange.Speed = math.random(2, 15) end
        end
    end)
end

-- === LAYER 20: Aggressive Dynamic Reset (safe zone applied) ===
local function AggressiveReset()
    pcall(function()
        local CHiggs = _G.CHiggsBosonComponent
        if CHiggs then
            CHiggs.bMHActive = false
            CHiggs.bCallPreReplication = false
            CHiggs.bSkipAlertServer = true
            CHiggs._ProcessReportChatRobotQueue = nop
            CHiggs.RPC_Client_ShowSecurityAlertWindow = nop
            CHiggs.RPC_Server_TellServerName = nop
            if CHiggs.ControlMHActive then
                CHiggs.ControlMHActive = function(self) self.bMHActive = false end
            end
        end

        if _G.PlayerSecurityInfoCollector then
            _G.PlayerSecurityInfoCollector.ReportData = nop
            _G.PlayerSecurityInfoCollector.SendToServer = nop
            _G.PlayerSecurityInfoCollector.CollectData = nop
        end

        if _G.ClientHawkEyePatrolSubsystem then
            _G.ClientHawkEyePatrolSubsystem._bHasReported = true
            _G.ClientHawkEyePatrolSubsystem._bHasInitialized = true
            _G.ClientHawkEyePatrolSubsystem.ReportCheat = nop
            _G.ClientHawkEyePatrolSubsystem.RequestImprison = nop
            _G.ClientHawkEyePatrolSubsystem.IsDuringHawkEyePatrol = retFalse
        end

        if _G.ClientBanLogic then
            _G.ClientBanLogic.ReqBanInfo = nop
            _G.ClientBanLogic.IsVoiceReportEnable = retFalse
            _G.ClientBanLogic.bEnableVoiceReport = false
        end

        if _G.RealTimeBan then
            _G.RealTimeBan.tOnRankInspectorUIDSet = {}
            _G.RealTimeBan.tInspectorRankUIDSet = {}
            _G.RealTimeBan.tInspectorBroadcastCountUIDSet = {}
            _G.RealTimeBan.is_onrank_inspector = false
        end

        if _G.tlog_report_utils then
            _G.tlog_report_utils.ReportTLogEvent = nop
            _G.tlog_report_utils.SendTLogReportImmediate = nop
            _G.tlog_report_utils.IsCanReportLobbyEvent = retFalse
            _G.tlog_report_utils.IsBusinessReport = retFalse
        end

        if _G.STExtraBlueprintFunctionLibrary then
            _G.STExtraBlueprintFunctionLibrary.CheckMD5 = retTrue
            _G.STExtraBlueprintFunctionLibrary.VerifyFile = retTrue
        end

        if _G.CoronaLab then
            _G.CoronaLab.ReportData = nop
            _G.CoronaLab.SendData = nop
            _G.CoronaLab.CollectData = nop
            _G.CoronaLab.Telemetry = nop
        end

        if _G.GokubaLogic then
            _G.GokubaLogic.ForwardFeature = nop
            _G.GokubaLogic.InitGokubaLogic = nop
        end

        if _G.SwiftHawk then _G.SwiftHawk = nop end
        if _G.ClientSwiftHawk then _G.ClientSwiftHawk = nop end
        if _G.ClientSwiftHawkWithParams then _G.ClientSwiftHawkWithParams = nop end
    end)
end

-- === Master bypass runner ===
_G.StartBypass_VIP_v3 = function()
    pcall(function()
        InitializeCoreBypass()
        InitializeSLUA_MD5()
        InitializeLogBlocker()
        InitializeScannerBlocker()
        InitializeReportBlocker()
        InitializeGameplayBypass()
        AntiCheatKillerUniversal()
        TFLiteAIBypass()
        BehavioralBypass()
        ServerValidationBypass()
        MLBypass()
        MemoryIntegrityBypass()
        CloudAIBypass()
        PacketEncryptionBypass()
        AdvancedBypasses()
        AntiBanSpoof()
        MaterialEvasionBypass()
        AimbotDetectionBypass()
        AggressiveReset()
    end)
end

if LicenseActive() then _G.StartBypass_VIP_v3() end

 
if not isExpired then
    pcall(function()
        local ticker = require("common.time_ticker")
        if ticker and ticker.AddTimerOnce then
            ticker.AddTimerOnce(0.5, _G.StartBypass_VIP_v3)
            ticker.AddTimerOnce(2.0, _G.StartBypass_VIP_v3)
            ticker.AddTimerOnce(5.0, _G.StartBypass_VIP_v3)
        end
    end)
    pcall(function()
        local ticker = require("common.time_ticker")
        if ticker and ticker.AddTimerOnce then
            local function maskLoop()
                pcall(RuntimeSignatureMasking)
                ticker.AddTimerOnce(0.5, maskLoop)
            end
            ticker.AddTimerOnce(1.0, maskLoop)
        end
    end)
end

-- ====================================================================
-- UTILITIES
-- ====================================================================
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
local C_BLUE = {R=0, G=0, B=255, A=255}

-- ====================================================================
-- CONFIG
-- ====================================================================
_G.GTLMODConfig = _G.GTLMODConfig or {
    AutoHead = false,
    EspVip = false,
    EspDistance = false,
    EspVipPro = false,
    EspRadar = false,
    Esp5 = false,
    Esp6 = false,
    Esp7 = false,
    Esp8 = false,
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
    CounterEnabled = false,
    EspLine = false,
    AimDebug = false,
    WallhackSmart = false,
    WallhackThickness = 2.5,
-- Aimbot V2
AimTouchEnable = false,
AimTouchHipfire = false,
AimTouchHipIgKnock = false,
AimTouchHipIgBot = false,
AimTouchHipVisCheck = false,
AimTouchSG = false,
AimTouchSGAutoFire = false,
AimTouchSGIgKnock = false,
AimTouchSGIgBot = false,
AimTouchSGVisCheck = false,
AimTouchScopeAll = false,
AimTouchScopeIgKnock = false,
AimTouchScopeIgBot = false,
AimTouchScopeVisCheck = false,
AimTouchScopeSniper = false,
AimTouchSniperIgKnock = false,
AimTouchSniperIgBot = false,
AimTouchSniperVisCheck = false,
AimTouchMortar = false,
}

_G.GTLMODState = _G.GTLMODState or {
    LoopToken = 0,
    NativeESPReady = false,
    GraphicsUnlocked = false,
    MenuStep = 0,
    TrackedMarks = {},
    EnemyMarks = {},
    CustomTextData = nil,
    PrevGraphicsState = {},
    MidCacheCount = 0,
    AimLastFail = "",
}

-- ====================================================================
-- CONFIG SAVE/LOAD
-- ====================================================================
local function GetConfigPaths(fileName)
    return {
        PATHS.Paks .. fileName,
        PATHS.SaveGames .. fileName,
        "ShadowTrackerExtra/Saved/Paks/" .. fileName,
        "../../ShadowTrackerExtra/Saved/Paks/" .. fileName,
        fileName
    }
end
local ConfigFileName = "UX_settings.txt"
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
                end
            end
        end
        _G.SaveModSettings()
    end)
end

local function AutoSaveLoop()
    pcall(function() if _G.SaveModSettings then _G.SaveModSettings() end end)
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

-- ====================================================================
-- ESP LINE SYSTEM (visibility-aware)
-- ====================================================================
local ESPLine = {
    Active = false,
    Lines = {},
    Canvas = nil,
    LastUpdate = 0,
    EnemyCache = {},
    ViewportW = 1920,
    ViewportH = 1080,
    CanvasScaleX = 1.0,
    CanvasScaleY = 1.0,
    CanvasOffsetX = 0.0,
    CanvasOffsetY = 0.0,
    LineCount = 0,
    SmoothPositions = {},
    VisibilityCache = {},
    LastVisCheck = {},
    LastDrawTime = 0,
    ZeroVector = nil,
}

local C_LINE_VISIBLE = nil
local C_LINE_BLOCKED = nil
local C_LINE_KNOCK = nil

pcall(function()
    local LC = safeImport("LinearColor")
    if LC then
        C_LINE_VISIBLE = LC(0.0, 1.0, 0.0, 0.95)
        C_LINE_BLOCKED = LC(1.0, 0.0, 0.0, 0.85)
        C_LINE_KNOCK = LC(0.0, 0.5, 1.0, 0.9)
    end
end)

pcall(function()
    local VT = safeImport("Vector")
    if VT then ESPLine.ZeroVector = VT(0, 0, 0) end
end)

function ESPLine.GetGameplayData()
    if ESPLine._CachedGDP then return ESPLine._CachedGDP end
    local ok, GDP = pcall(function() return require("GameLua.GameCore.Data.GameplayData") end)
    if ok and GDP then ESPLine._CachedGDP = GDP; return GDP end
    return nil
end

function ESPLine.GetMyPlayerController()
    local PC = ESPLine._CachedPC
    if PC and Valid(PC) then return PC end
    local GDP = ESPLine.GetGameplayData()
    if GDP then
        pcall(function() PC = GDP.GetPlayerController and GDP.GetPlayerController() end)
    end
    if not (PC and Valid(PC)) then
        pcall(function()
            if slua_GameFrontendHUD then
                PC = slua_GameFrontendHUD:GetPlayerController()
            end
        end)
    end
    if PC and Valid(PC) then ESPLine._CachedPC = PC end
    return PC
end

function ESPLine.GetAllCharacters()
    local AllChars = {}
    pcall(function()
        local Pawns = Game:GetAllPlayerPawns()
        if Pawns then
            for _, Pawn in pairs(Pawns) do
                if Pawn and slua.isValid(Pawn) then
                    local pKey = nil
                    if Pawn.GetPlayerKey then pKey = Pawn:GetPlayerKey() end
                    if not pKey and Pawn.PlayerKey then pKey = Pawn.PlayerKey end
                    if pKey then AllChars[pKey] = Pawn end
                end
            end
        end
    end)
    if not next(AllChars) then
        local ok, GS = pcall(function() return require("GameLua.GameCore.Data.CGameState") end)
        if ok and GS and GS.GetAllCharacters then
            pcall(function() AllChars = GS:GetAllCharacters() end)
        end
    end
    return AllChars
end

function ESPLine.GetMyPlayerKey()
    local PC = ESPLine.GetMyPlayerController()
    if not Valid(PC) then return nil end
    local MyKey = nil
    pcall(function()
        if PC.GetPlayerKey then MyKey = PC:GetPlayerKey()
        elseif PC.PlayerState and PC.PlayerState.PlayerKey then MyKey = PC.PlayerState.PlayerKey end
    end)
    return MyKey
end

function ESPLine.IsMe(Character, PlayerKey, MyKey)
    local bIsMe = false
    pcall(function()
        local GDP = ESPLine.GetGameplayData()
        if GDP and GDP.GetLocalCharacter then
            local MyChar = GDP.GetLocalCharacter()
            if MyChar and Character == MyChar then bIsMe = true; return end
        end
        local PC = ESPLine.GetMyPlayerController()
        if PC and PC.GetPawn then
            local Pawn = PC:GetPawn()
            if Pawn and Character == Pawn then bIsMe = true; return end
        end
    end)
    if not bIsMe and MyKey ~= nil and PlayerKey ~= nil then
        bIsMe = (tostring(PlayerKey) == tostring(MyKey))
    end
    return bIsMe
end

function ESPLine.IsAlive(Character)
    local bAlive = true
    pcall(function()
        if Character.HealthStatus then
            bAlive = (Character.HealthStatus == 0 or Character.HealthStatus == 1)
        elseif Character.IsAlive then
            bAlive = Character:IsAlive()
        elseif Character.Health ~= nil then
            bAlive = Character.Health > 0
        elseif Character.HP ~= nil then
            bAlive = Character.HP > 0
        end
    end)
    return bAlive
end

function ESPLine.GetTeamID(Character)
    if not Valid(Character) then return nil end
    local TeamID = nil
    pcall(function()
        if Character.GetTeamID then TeamID = Character:GetTeamID() end
    end)
    if not TeamID then
        pcall(function()
            local PS = nil
            if Character.GetPlayerStateSafety then PS = Character:GetPlayerStateSafety()
            elseif Character.GetPlayerState then PS = Character:GetPlayerState() end
            if Valid(PS) then
                if PS.GetTeamID then TeamID = PS:GetTeamID()
                elseif PS.TeamID then TeamID = PS.TeamID end
            end
        end)
    end
    if not TeamID then
        pcall(function() if Character.TeamID then TeamID = Character.TeamID end end)
    end
    return TeamID
end

function ESPLine.GetCapsuleHalfHeight(Character)
    local halfH = 88
    pcall(function()
        local cap = Character.CapsuleComponent
        if not cap and Character.GetCapsuleComponent then cap = Character:GetCapsuleComponent() end
        if cap and cap.GetScaledCapsuleHalfHeight then
            local v = cap:GetScaledCapsuleHalfHeight()
            if v and v > 10 then halfH = v end
        end
    end)
    return halfH
end

function ESPLine.GetCharacterHeadLoc(Character)
    if not Valid(Character) then return nil end
    local Loc = nil
    pcall(function() if Character.K2_GetActorLocation then Loc = Character:K2_GetActorLocation() end end)
    if not Loc then return nil end
    local z = Loc.Z - ESPLine.GetCapsuleHalfHeight(Character) + 150
    return { X = Loc.X, Y = Loc.Y, Z = z }
end

function ESPLine.IsVisible(PC, Character)
    if not Valid(PC) or not Valid(Character) then return false end
    local now = os.clock()
    local charKey = tostring(Character)
    if ESPLine.LastVisCheck[charKey] and (now - ESPLine.LastVisCheck[charKey]) < LIMITS.VIS_CACHE_TIME then
        return ESPLine.VisibilityCache[charKey] or false
    end
    local bVis = false
    pcall(function()
        if PC.LineOfSightTo then
            if ESPLine.ZeroVector then
                bVis = PC:LineOfSightTo(Character, ESPLine.ZeroVector, false)
                if bVis == nil then bVis = PC:LineOfSightTo(Character) end
            else
                bVis = PC:LineOfSightTo(Character)
            end
        end
    end)
    ESPLine.VisibilityCache[charKey] = bVis and true or false
    ESPLine.LastVisCheck[charKey] = now
    return bVis and true or false
end

function ESPLine.InitCanvas()
    if ESPLine.Canvas and Game:IsValid(ESPLine.Canvas) then return true end
    local InGameUITools = nil
    pcall(function() InGameUITools = require("GameLua.Mod.BaseMod.Common.UI.InGameUITools") end)
    if not InGameUITools then return false end
    local MainControlBaseUI = nil
    pcall(function() MainControlBaseUI = InGameUITools.GetMainControlBaseUI() end)
    if not MainControlBaseUI or not Game:IsValid(MainControlBaseUI) then return false end
    local ParentCanvas = nil
    pcall(function()
        if MainControlBaseUI.CanvasPanel_0 and Game:IsValid(MainControlBaseUI.CanvasPanel_0) then
            ParentCanvas = MainControlBaseUI.CanvasPanel_0
        elseif MainControlBaseUI.CanvasPanel_42 and Game:IsValid(MainControlBaseUI.CanvasPanel_42) then
            ParentCanvas = MainControlBaseUI.CanvasPanel_42
        end
    end)
    if not ParentCanvas then return false end
    ESPLine.Canvas = ParentCanvas
    return true
end

function ESPLine.UpdateCanvasTransform(PC)
    if not ESPLine.Canvas or not Game:IsValid(ESPLine.Canvas) then return end
    local success = false
    pcall(function()
        local SlateBlueprintLibrary = safeImport("SlateBlueprintLibrary")
        if SlateBlueprintLibrary and SlateBlueprintLibrary.AbsoluteToLocal then
            local cg = ESPLine.Canvas:GetCachedGeometry()
            if cg then
                local FVector2D = _G.FVector2D or safeImport("Vector2D")
                local pt0 = SlateBlueprintLibrary.AbsoluteToLocal(cg, FVector2D and FVector2D(0,0) or {X=0,Y=0})
                local pt1 = SlateBlueprintLibrary.AbsoluteToLocal(cg, FVector2D and FVector2D(100,100) or {X=100,Y=100})
                if pt0 and pt1 then
                    ESPLine.CanvasScaleX = (pt1.X - pt0.X) / 100
                    ESPLine.CanvasScaleY = (pt1.Y - pt0.Y) / 100
                    ESPLine.CanvasOffsetX = pt0.X
                    ESPLine.CanvasOffsetY = pt0.Y
                    success = true
                end
            end
        end
    end)
    if not success then
        local scale = 1.0
        local WidgetLayoutLibrary = safeImport("WidgetLayoutLibrary")
        if WidgetLayoutLibrary and WidgetLayoutLibrary.GetViewportScale then
            scale = WidgetLayoutLibrary.GetViewportScale(PC) or 1.0
        end
        ESPLine.CanvasScaleX = 1.0 / scale
        ESPLine.CanvasScaleY = 1.0 / scale
        ESPLine.CanvasOffsetX = 0
        ESPLine.CanvasOffsetY = 0
    end
end

function ESPLine.ScreenPixelToCanvas(p)
    if not p then return {X=0,Y=0} end
    local sx = ESPLine.CanvasScaleX or 1.0
    local sy = ESPLine.CanvasScaleY or 1.0
    local ox = ESPLine.CanvasOffsetX or 0
    local oy = ESPLine.CanvasOffsetY or 0
    local FVector2D = _G.FVector2D or safeImport("Vector2D")
    return (FVector2D and FVector2D(p.X*sx+ox, p.Y*sy+oy)) or {X=p.X*sx+ox, Y=p.Y*sy+oy}
end

function ESPLine.ProjectToCanvas(PC, WorldLoc)
    if not Valid(PC) or not WorldLoc then return false, {X=0,Y=0} end
    local FVector2D = _G.FVector2D or safeImport("Vector2D")
    local Pix = FVector2D and FVector2D(0,0) or {X=0,Y=0}
    local bOK = false
    pcall(function()
        local res = PC:ProjectWorldLocationToScreen(WorldLoc, Pix, true)
        bOK = (res == true or res == 1 or (Pix and (Pix.X ~= 0 or Pix.Y ~= 0)))
    end)
    if not bOK then return false, {X=0,Y=0} end
    return true, ESPLine.ScreenPixelToCanvas(Pix)
end

function ESPLine.GetScreenCenter(PC)
    local W, H = 0, 0
    local FVector2D = _G.FVector2D or safeImport("Vector2D")
    pcall(function()
        if PC and PC.GetViewportSize then
            local vs = FVector2D and FVector2D(0,0) or {X=0,Y=0}
            PC:GetViewportSize(vs)
            if vs and vs.X and vs.X > 200 then W, H = vs.X, vs.Y end
        end
    end)
    if W <= 200 then
        pcall(function()
            local WidgetLayoutLibrary = safeImport("WidgetLayoutLibrary")
            if WidgetLayoutLibrary and WidgetLayoutLibrary.GetViewportSize then
                local vs = WidgetLayoutLibrary.GetViewportSize(PC)
                if vs and vs.X and vs.X > 200 then W, H = vs.X, vs.Y end
            end
        end)
    end
    if W <= 200 then
        W = ESPLine.ViewportW or 1920
        H = ESPLine.ViewportH or 1080
    end
    ESPLine.ViewportW = W
    ESPLine.ViewportH = H
    return ESPLine.ScreenPixelToCanvas(FVector2D and FVector2D(W/2, H/2) or {X=W/2,Y=H/2}), W, H
end

function ESPLine.CreateLineWidget(color, zOrder)
    if not ESPLine.Canvas or not Game:IsValid(ESPLine.Canvas) then return nil end
    local Border = nil
    pcall(function() Border = CGame:NewObjectFromPath("/Script/UMG.Border", ESPLine.Canvas) end)
    if not Border or not slua.isValid(Border) then return nil end
    local FVector2D = _G.FVector2D or safeImport("Vector2D")
    pcall(function()
        Border:SetBrushColor(color)
        Border:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        Border:SetRenderTransformPivot(FVector2D and FVector2D(0.0,0.5) or {X=0,Y=0.5})
    end)
    local Slot = nil
    pcall(function()
        Slot = ESPLine.Canvas:AddChildToCanvas(Border)
        if Slot then
            Slot:SetAutoSize(false)
            Slot:SetZOrder(zOrder or 1)
        end
    end)
    if not Slot then return nil end
    return { Widget = Border, Slot = Slot, SmoothX = 0, SmoothY = 0, Init = false }
end

function ESPLine.DrawLineSmooth(ld, x1, y1, x2, y2, thickness)
    if not ld or not ld.Widget or not ld.Slot then return end
    local smoothFactor = LIMITS.ESP_LINE_SMOOTH
    if not ld.Init then
        ld.SmoothX = x2
        ld.SmoothY = y2
        ld.Init = true
    else
        local dx = x2 - ld.SmoothX
        local dy = y2 - ld.SmoothY
        ld.SmoothX = ld.SmoothX + dx * smoothFactor
        ld.SmoothY = ld.SmoothY + dy * smoothFactor
    end
    local sx2 = ld.SmoothX
    local sy2 = ld.SmoothY
    local dx = sx2 - x1
    local dy = sy2 - y1
    local len = math.sqrt(dx*dx + dy*dy)
    if len < 0.5 then return end
    local ang = (math.atan2 and math.atan2(dy,dx) or math.atan(dy,dx)) * (180.0/math.pi)
    local FVector2D = _G.FVector2D or safeImport("Vector2D")
    pcall(function()
        ld.Slot:SetPosition(FVector2D and FVector2D(x1, y1-thickness/2) or {X=x1,Y=y1-thickness/2})
        ld.Slot:SetSize(FVector2D and FVector2D(len, thickness) or {X=len,Y=thickness})
        ld.Widget:SetRenderAngle(ang)
        ld.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
    end)
end

function ESPLine.HideWidget(ld)
    if ld and ld.Widget and slua.isValid(ld.Widget) then
        pcall(function() ld.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
    end
end

function ESPLine.DestroyWidget(ld)
    if ld and ld.Widget and slua.isValid(ld.Widget) then
        pcall(function()
            ld.Widget:RemoveFromParent()
            ld.Widget:ConditionalBeginDestroy()
        end)
    end
end

function ESPLine.UpdateLineWithVisibility(KeyStr, headCanvas, originCanvas, bOnScreen, Character, PC)
    local ld = ESPLine.Lines[KeyStr]
    if not bOnScreen then
        if ld then ESPLine.HideWidget(ld) end
        return
    end
    local lineColor = C_LINE_BLOCKED or safeImport("LinearColor")(1.0, 0.0, 0.0, 0.85)
    if Character and Valid(Character) then
        local isKnocked = false
        pcall(function()
            if Character.HealthStatus == 1 then isKnocked = true end
            if Character.Health and Character.Health <= 0 and Character.HealthStatus ~= 2 then isKnocked = true end
        end)
        if isKnocked then
            lineColor = C_LINE_KNOCK or safeImport("LinearColor")(0.0, 0.5, 1.0, 0.9)
        else
            local bVisible = ESPLine.IsVisible(PC, Character)
            if bVisible then
                lineColor = C_LINE_VISIBLE or safeImport("LinearColor")(0.0, 1.0, 0.0, 0.95)
            end
        end
    end
    if not ld then
        if ESPLine.LineCount >= LIMITS.MAX_ESP_LINES then return end
        ld = ESPLine.CreateLineWidget(lineColor, 1)
        if not ld then return end
        ESPLine.Lines[KeyStr] = ld
        ESPLine.LineCount = ESPLine.LineCount + 1
    else
        pcall(function() ld.Widget:SetBrushColor(lineColor) end)
    end
    ESPLine.DrawLineSmooth(ld, originCanvas.X, originCanvas.Y, headCanvas.X, headCanvas.Y, LIMITS.ESP_LINE_THICKNESS)
end

function ESPLine.RemoveLine(KeyStr)
    local ld = ESPLine.Lines[KeyStr]
    if ld then
        ESPLine.DestroyWidget(ld)
        ESPLine.Lines[KeyStr] = nil
        ESPLine.LineCount = math.max(0, ESPLine.LineCount - 1)
    end
    ESPLine.SmoothPositions[KeyStr] = nil
    ESPLine.VisibilityCache[tostring(KeyStr)] = nil
    ESPLine.LastVisCheck[tostring(KeyStr)] = nil
end

function ESPLine.ClearAllLines()
    for k, ld in pairs(ESPLine.Lines) do
        ESPLine.DestroyWidget(ld)
    end
    ESPLine.Lines = {}
    ESPLine.LineCount = 0
    ESPLine.SmoothPositions = {}
    ESPLine.VisibilityCache = {}
    ESPLine.LastVisCheck = {}
end

function ESPLine.ScanAndUpdate()
    if not _G.GTLMODConfig.EspLine then return end
    if not ESPLine.InitCanvas() then return end
    local PC = ESPLine.GetMyPlayerController()
    if not Valid(PC) then return end
    ESPLine.UpdateCanvasTransform(PC)
    local centerCanvas, viewW, viewH = ESPLine.GetScreenCenter(PC)
    local FVector2D = _G.FVector2D or safeImport("Vector2D")
    local originCanvas = ESPLine.ScreenPixelToCanvas(FVector2D and FVector2D(viewW/2, 0) or {X=viewW/2, Y=0})
    local AllChars = ESPLine.GetAllCharacters()
    if not AllChars then return end
    local MyKey = ESPLine.GetMyPlayerKey()
    local MyChar = nil
    pcall(function()
        local GDP = ESPLine.GetGameplayData()
        if GDP and GDP.GetLocalCharacter then MyChar = GDP.GetLocalCharacter()
        elseif PC and PC.GetPawn then MyChar = PC:GetPawn() end
    end)
    local MyTeamID = ESPLine.GetTeamID(MyChar)
    local SeenKeys = {}
    local count = 0
    for PlayerKey, Character in pairs(AllChars) do
        if count >= LIMITS.MAX_ESP_LINES then break end
        if Valid(Character) then
            local bIsMe = ESPLine.IsMe(Character, PlayerKey, MyKey)
            local KeyStr = tostring(PlayerKey)
            local bAlive = ESPLine.IsAlive(Character)
            local TeamID = ESPLine.GetTeamID(Character)
            local bSkip = bIsMe
            if MyTeamID ~= nil and TeamID == MyTeamID and not bIsMe then bSkip = true end
            if not bAlive then bSkip = true end
            if not bSkip then
                local dist = 999999
                pcall(function() dist = MyChar:GetDistanceTo(Character) / 100 end)
                if dist > LIMITS.ESP_LINE_MAX_DIST then bSkip = true end
            end
            if not bSkip then
                SeenKeys[KeyStr] = true
                ESPLine.EnemyCache[KeyStr] = Character
                local HeadLoc = ESPLine.GetCharacterHeadLoc(Character)
                local bHeadOK, headCanvas = ESPLine.ProjectToCanvas(PC, HeadLoc)
                ESPLine.UpdateLineWithVisibility(KeyStr, headCanvas, originCanvas, bHeadOK, Character, PC)
                count = count + 1
            end
        end
    end
    for KeyStr in pairs(ESPLine.Lines) do
        if not SeenKeys[KeyStr] then
            ESPLine.RemoveLine(KeyStr)
            ESPLine.EnemyCache[KeyStr] = nil
        end
    end
end

function ESPLine.Start()
    if ESPLine.Active then return end
    ESPLine.Active = true
    ESPLine.ScanAndUpdate()
end

function ESPLine.Stop()
    ESPLine.Active = false
    ESPLine.ClearAllLines()
    ESPLine.EnemyCache = {}
    ESPLine.Canvas = nil
end

function ESPLine.Toggle()
    if ESPLine.Active then ESPLine.Stop() else ESPLine.Start() end
    return ESPLine.Active
end

_G.ESPLine = ESPLine

-- ====================================================================
-- NEW WALLHACK
-- ====================================================================
local NewWallhack = {
    Active = false,
    WH_TIMER = nil,
    PROCESSED_PAWNS = {},
    TICK_COUNT = 0,
    CONSOLE_READY = false,
    TICK_INTERVAL = 0.3,
    MAX_PAWNS_PER_TICK = 20,
    RESET_PROCESSED_EVERY = 6,
    AVATAR_SLOTS = {0,1,2,3,4,5,6,7},
    colors = { vis = nil, occ = nil, bVis = nil, bOcc = nil }
}

pcall(function()
    local LC = safeImport("LinearColor")
    if LC then
        NewWallhack.colors.vis = LC(0.0, 1.0, 0.0, 0.4)
        NewWallhack.colors.occ = LC(1.0, 0.0, 0.0, 0.4)
        NewWallhack.colors.bVis = LC(0.0, 0.8, 0.0, 0.4)
        NewWallhack.colors.bOcc = LC(0.8, 0.0, 0.0, 0.4)
    end
end)

local function SetupConsole()
    if NewWallhack.CONSOLE_READY then return end
    pcall(function()
        local KSL = safeImport("KismetSystemLibrary")
        local world = slua.getWorld()
        if not KSL or not world then return end
        KSL.ExecuteConsoleCommand(world, "r.EnableDrawDyeingColor 1")
        KSL.ExecuteConsoleCommand(world, "r.CustomDepth 3")
        KSL.ExecuteConsoleCommand(world, "r.IdeaOutline.Enable 1")
        KSL.ExecuteConsoleCommand(world, "r.Highlight.Enable 1")
        NewWallhack.CONSOLE_READY = true
    end)
end

local function ApplyToMesh(mesh, visColor, occColor)
    if not mesh or not slua.isValid(mesh) then return end
    pcall(function()
        if mesh.SetDrawDyeing then mesh:SetDrawDyeing(true) end
        if mesh.SetDrawDyeingMode then mesh:SetDrawDyeingMode(1) end
        if mesh.SetVisibleDyeingColor then mesh:SetVisibleDyeingColor(visColor) end
        if mesh.SetOccludedDyeingColor then mesh:SetOccludedDyeingColor(occColor) end
        if mesh.SetDyeingColorFadeDistance then mesh:SetDyeingColorFadeDistance(99999.0) end
        if mesh.SetDyeingColorMinMaxDistance then mesh:SetDyeingColorMinMaxDistance(0.0, 99999.0) end
        if mesh.SetDrawHighlight then mesh:SetDrawHighlight(true) end
        if mesh.OverrideHighlightColor then mesh:OverrideHighlightColor(visColor) end
        if mesh.SetHighlightCanBeOccluded then mesh:SetHighlightCanBeOccluded(false) end
        if mesh.SetDrawIdeaOutline then mesh:SetDrawIdeaOutline(true) end
        if mesh.SetIdeaOutlineNew then mesh:SetIdeaOutlineNew(true) end
        if mesh.SetIdeaOutlineOcclusionHighlight then mesh:SetIdeaOutlineOcclusionHighlight(true) end
        if mesh.OverrideIdeaOutlineColor then mesh:OverrideIdeaOutlineColor(visColor) end
        if mesh.SetIdeaOutlineOcclusionColor then mesh:SetIdeaOutlineOcclusionColor(occColor) end
        if mesh.OverrideIdeaOutlineThickness then mesh:OverrideIdeaOutlineThickness(20.0) end
        if mesh.SetIdeaOverrideOutlineAndOcclusion then mesh:SetIdeaOverrideOutlineAndOcclusion(true) end
        if mesh.SetRenderCustomDepth then mesh:SetRenderCustomDepth(true) end
        if mesh.SetCustomDepthStencilValue then mesh:SetCustomDepthStencilValue(255) end
    end)
end

local function IsPawnAlive(pawn)
    if not slua.isValid(pawn) then return false end
    if pawn.Health and pawn.Health > 0 then return true end
    return false
end

local function NewWallhackTick()
    pcall(function()
        local localPawn = GameplayData and GameplayData.GetPlayerCharacter and GameplayData.GetPlayerCharacter()
        if not slua.isValid(localPawn) then return end
        SetupConsole()
        if not NewWallhack.colors.vis then return end
        NewWallhack.TICK_COUNT = NewWallhack.TICK_COUNT + 1
        if NewWallhack.TICK_COUNT % NewWallhack.RESET_PROCESSED_EVERY == 0 then
            NewWallhack.PROCESSED_PAWNS = {}
        end
        local myTeamId = localPawn.TeamID or 0
        local allPawns = Game:GetAllPlayerPawns() or {}
        local processedCount = 0
        for _, pawn in pairs(allPawns) do
            if processedCount >= NewWallhack.MAX_PAWNS_PER_TICK then break end
            if not slua.isValid(pawn) or pawn == localPawn then goto continue end
            if pawn.PlayerKey and NewWallhack.PROCESSED_PAWNS[pawn.PlayerKey] then goto continue end
            if IsPawnAlive(pawn) and pawn.TeamID and pawn.TeamID ~= myTeamId then
                local isAI = pcall(Game.IsAI, pawn) and true or false
                local vis = isAI and NewWallhack.colors.bVis or NewWallhack.colors.vis
                local occ = isAI and NewWallhack.colors.bOcc or NewWallhack.colors.occ
                pcall(function()
                    if slua.isValid(pawn.Mesh) then ApplyToMesh(pawn.Mesh, vis, occ) end
                    local avatarComp = pawn.CharacterAvatarComp2_BP or (pawn.getAvatarComponent2 and pawn:getAvatarComponent2())
                    if avatarComp and avatarComp.GetMeshCompBySlot then
                        for _, slot in ipairs(NewWallhack.AVATAR_SLOTS) do
                            local mesh = avatarComp:GetMeshCompBySlot(slot)
                            if slua.isValid(mesh) then ApplyToMesh(mesh, vis, occ) end
                        end
                    end
                    pcall(function()
                        local SkeletalMeshComponent = safeImport("SkeletalMeshComponent")
                        if SkeletalMeshComponent and pawn.GetComponentsByClass then
                            local skComps = pawn:GetComponentsByClass(SkeletalMeshComponent)
                            if skComps then
                                for i = 0, skComps:Num() - 1 do
                                    local comp = skComps:Get(i)
                                    if slua.isValid(comp) and comp ~= pawn.Mesh then
                                        ApplyToMesh(comp, vis, occ)
                                    end
                                end
                            end
                        end
                    end)
                    pcall(function()
                        local StaticMeshComponent = safeImport("StaticMeshComponent")
                        if StaticMeshComponent and pawn.GetComponentsByClass then
                            local stComps = pawn:GetComponentsByClass(StaticMeshComponent)
                            if stComps then
                                for i = 0, stComps:Num() - 1 do
                                    local comp = stComps:Get(i)
                                    if slua.isValid(comp) then ApplyToMesh(comp, vis, occ) end
                                end
                            end
                        end
                    end)
                    if pawn.GetCurrentWeapon then
                        local weapon = pawn:GetCurrentWeapon()
                        if slua.isValid(weapon) and slua.isValid(weapon.Mesh) then
                            ApplyToMesh(weapon.Mesh, vis, occ)
                        end
                    end
                end)
                if pawn.PlayerKey then NewWallhack.PROCESSED_PAWNS[pawn.PlayerKey] = true end
                processedCount = processedCount + 1
            end
            ::continue::
        end
    end)
end

function _G.StartNewWallhack()
    if NewWallhack.WH_TIMER then return end
    SetupConsole()
    if not NewWallhack.colors.vis then return false end
    if _G.Game and _G.Game.AddGameTimer then
        NewWallhack.WH_TIMER = _G.Game:AddGameTimer(NewWallhack.TICK_INTERVAL, true, NewWallhackTick)
        NewWallhack.Active = true
        return true
    end
    local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if slua.isValid(pc) and pc.AddGameTimer then
        NewWallhack.WH_TIMER = pc:AddGameTimer(NewWallhack.TICK_INTERVAL, true, NewWallhackTick)
        NewWallhack.Active = true
        return true
    end
    return false
end

function _G.StopNewWallhack()
    if NewWallhack.WH_TIMER then
        pcall(function()
            if _G.Game then _G.Game:RemoveGameTimer(NewWallhack.WH_TIMER) end
        end)
        NewWallhack.WH_TIMER = nil
    end
    NewWallhack.PROCESSED_PAWNS = {}
    NewWallhack.Active = false
end

pcall(function()
    local ticker = package.loaded["common.time_ticker"] or require("common.time_ticker")
    if ticker and ticker.AddTimerOnce then
        ticker.AddTimerOnce(4.0, function()
            if _G.StartNewWallhack then _G.StartNewWallhack() end
        end)
    end
end)

-- ====================================================================
-- MENU
-- ====================================================================
function _G.InitModMenuTab()
    if _G.ModMenuInitialized then return end
    _G.ModMenuInitialized = true

    _G.GTLMODState.CustomTextData = _G.GTLMODState.CustomTextData or {
        OuterSpeed = 10, InnerSpeed = 10, OuterRecoil = 0,
        HRecoil = 0.3, VRecoil = 0.3, IpadViewFOV = 120,
    }

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

        local StackESPVisual = {
            { Key = "ModMenu_ESP1", UI = AliasMap.Switcher, Text = "ESP (AUTO SETUP) TELEGRAM UX_Official", GetFunc = function() return _G.GTLMODConfig.EspVip end, SetFunc = function(c,v) _G.GTLMODConfig.EspVip = v return true end },
            { Key = "ModMenu_ESP7", UI = AliasMap.Switcher, Text = "ESP WARNING & COUNT", GetFunc = function() return _G.GTLMODConfig.Esp7 end, SetFunc = function(c,v) _G.GTLMODConfig.Esp7 = v return true end },
            { Key = "ModMenu_ESP2", UI = AliasMap.Switcher, Text = "ESP RANGE", GetFunc = function() return _G.GTLMODConfig.EspDistance end, SetFunc = function(c,v) _G.GTLMODConfig.EspDistance = v return true end },
            { Key = "ModMenu_ESP4", UI = AliasMap.Switcher, Text = "ESP MARK - 360 Radar", GetFunc = function() return _G.GTLMODConfig.EspRadar end, SetFunc = function(c,v) _G.GTLMODConfig.EspRadar = v return true end },
            { Key = "ModMenu_ESP5", UI = AliasMap.Switcher, Text = "ESP BOX FRAME", GetFunc = function() return _G.GTLMODConfig.Esp5 end, SetFunc = function(c,v) _G.GTLMODConfig.Esp5 = v return true end },
            { Key = "ModMenu_ESPAntenna", UI = AliasMap.Switcher, Text = "ESP LINE ANTENA", GetFunc = function() return _G.GTLMODConfig.EspAntenna end, SetFunc = function(c,v) _G.GTLMODConfig.EspAntenna = v return true end },
            { Key = "ModMenu_ESPName", UI = AliasMap.Switcher, Text = "ESP NAME (VISIBLE)", GetFunc = function() return _G.GTLMODConfig.EspName end, SetFunc = function(c,v) _G.GTLMODConfig.EspName = v return true end },
            { Key = "ModMenu_ESPLine", UI = AliasMap.Switcher, Text = "ESP LINE (SMOOTH VIS)", GetFunc = function() return _G.GTLMODConfig.EspLine end, SetFunc = function(c,v) _G.GTLMODConfig.EspLine = v; if _G.ESPLine then if v then _G.ESPLine.Start() else _G.ESPLine.Stop() end end return true end },
            { Key = "ModMenu_ESPOutline_Ex", UI = AliasMap.TitleSwitcher, Text = "▶ ESP OUTLINE", ExpandIndex = 0, GetFunc = function() return _G.GTLMODConfig.EspOutline end, SetFunc = function(c,v) _G.GTLMODConfig.EspOutline = v return true end },
            { Key = "ModMenu_ESPOutline_Thickness", UI = AliasMap.Slider, Text = "   Outline Thickness", ExpandHandle = "ModMenu_ESPOutline_Ex", MinValue = 1, MaxValue = 20, min = 1, max = 20, GetFunc = function() return _G.GTLMODConfig.OutlineThickness end, SetFunc = function(c,v) _G.GTLMODConfig.OutlineThickness = v return true end },
            { Key = "ModMenu_Counter", UI = AliasMap.Switcher, Text = "PLAYER/BOT COUNTER", GetFunc = function() return _G.GTLMODConfig.CounterEnabled end, SetFunc = function(c,v) _G.GTLMODConfig.CounterEnabled = v; if _G.RJCounter then _G.RJCounter.SetEnabled(v) end return true end },
        }

        local StackWallhack = {
            { Key = "ModMenu_NewWallhack", UI = AliasMap.Switcher, Text = "NEW WALLHACK (GREEN/RED)", GetFunc = function() return _G.GTLMODConfig.WallhackSmart end, SetFunc = function(c,v)
                _G.GTLMODConfig.WallhackSmart = v
                if v then
                    if _G.StartNewWallhack then _G.StartNewWallhack() end
                else
                    if _G.StopNewWallhack then _G.StopNewWallhack() end
                end
                return true
            end },
            { Key = "ModMenu_WallColor", UI = AliasMap.Switcher, Text = "Wallhack & Color (OLD)", GetFunc = function() return _G.GTLMODConfig.wallhackng end, SetFunc = function(c,v) _G.GTLMODConfig.wallhackng = v; _G.GTLMODConfig.ColorBodyV2 = v return true end },
        }

        local StackAimbotV2 = {
    { Key = "ModMenu_AT_Ex", UI = AliasMap.TitleSwitcher, Text = "▶ Enable Custom Aimbot V2", ExpandIndex = 0, GetFunc = function() return _G.GTLMODConfig.AimTouchEnable end, SetFunc = function(c,v) _G.GTLMODConfig.AimTouchEnable = v return true end },

    -- HIPFIRE
    { Key = "ModMenu_AT_Hip_Ex", UI = AliasMap.TitleSwitcher, Text = "   ▶ Hipfire Aimbot", ExpandHandle = "ModMenu_AT_Ex", ExpandIndex = 0, GetFunc = function() return _G.GTLMODConfig.AimTouchHipfire end, SetFunc = function(c,v) _G.GTLMODConfig.AimTouchHipfire = v return true end },
    { Key = "ModMenu_AT_Hip_IgKnock", UI = AliasMap.Switcher, Text = "      Ignore Knocked", ExpandHandle = "ModMenu_AT_Hip_Ex", GetFunc = function() return _G.GTLMODConfig.AimTouchHipIgKnock end, SetFunc = function(c,v) _G.GTLMODConfig.AimTouchHipIgKnock = v return true end },
    { Key = "ModMenu_AT_Hip_IgBot", UI = AliasMap.Switcher, Text = "      Ignore Bots", ExpandHandle = "ModMenu_AT_Hip_Ex", GetFunc = function() return _G.GTLMODConfig.AimTouchHipIgBot end, SetFunc = function(c,v) _G.GTLMODConfig.AimTouchHipIgBot = v return true end },
    { Key = "ModMenu_AT_Hip_Vis", UI = AliasMap.Switcher, Text = "      Visibility Check", ExpandHandle = "ModMenu_AT_Hip_Ex", GetFunc = function() return _G.GTLMODConfig.AimTouchHipVisCheck end, SetFunc = function(c,v) _G.GTLMODConfig.AimTouchHipVisCheck = v return true end },
    { Key = "ModMenu_AT_Hip_Prio", UI = AliasMap.Slider, Text = "      Priority (1:Cross 2:Dist 3:HP)", ExpandHandle = "ModMenu_AT_Hip_Ex", MinValue = 1, MaxValue = 4, min = 1, max = 4, GetFunc = function() return _G.GTLMODState.CustomTextData.AimTouchHipPrio or 1 end, SetFunc = function(c,v) local val = math.floor(v+0.5); if val < 1 then val = 1 end; if val > 4 then val = 4 end; _G.GTLMODState.CustomTextData.AimTouchHipPrio = val return true end },
    { Key = "ModMenu_AT_Hip_Bone", UI = AliasMap.Slider, Text = "      Bone (1:Head 2:Chest 3:Stomach 4:Pelvis)", ExpandHandle = "ModMenu_AT_Hip_Ex", MinValue = 1, MaxValue = 4, min = 1, max = 4, GetFunc = function() return _G.GTLMODState.CustomTextData.AimTouchHipBone or 1 end, SetFunc = function(c,v) local val = math.floor(v+0.5); if val < 1 then val = 1 end; if val > 4 then val = 4 end; _G.GTLMODState.CustomTextData.AimTouchHipBone = val return true end },
    { Key = "ModMenu_AT_Hip_Cond", UI = AliasMap.Slider, Text = "      Trigger (1:On Fire 2:Always)", ExpandHandle = "ModMenu_AT_Hip_Ex", MinValue = 1, MaxValue = 2, min = 1, max = 2, GetFunc = function() return _G.GTLMODState.CustomTextData.AimTouchHipCond or 1 end, SetFunc = function(c,v) local val = math.floor(v+0.5); if val < 1 then val = 1 end; if val > 2 then val = 2 end; _G.GTLMODState.CustomTextData.AimTouchHipCond = val return true end },
    { Key = "ModMenu_AT_Hip_Spd", UI = AliasMap.Slider, Text = "      Smoothness (1-100)", ExpandHandle = "ModMenu_AT_Hip_Ex", MinValue = 1, MaxValue = 100, min = 1, max = 100, GetFunc = function() return _G.GTLMODState.CustomTextData.AimTouchHipSpeed or 50 end, SetFunc = function(c,v) _G.GTLMODState.CustomTextData.AimTouchHipSpeed = v return true end },
    { Key = "ModMenu_AT_Hip_FOV", UI = AliasMap.Slider, Text = "      FOV Radius (1-100)", ExpandHandle = "ModMenu_AT_Hip_Ex", MinValue = 1, MaxValue = 100, min = 1, max = 100, GetFunc = function() return _G.GTLMODState.CustomTextData.AimTouchHipFOV or 30 end, SetFunc = function(c,v) _G.GTLMODState.CustomTextData.AimTouchHipFOV = v return true end },
    { Key = "ModMenu_AT_Hip_Dist", UI = AliasMap.Slider, Text = "      Distance (1-500m)", ExpandHandle = "ModMenu_AT_Hip_Ex", MinValue = 1, MaxValue = 100, min = 1, max = 100, GetFunc = function() return math.floor((_G.GTLMODState.CustomTextData.AimTouchHipDist or 250) / 5) end, SetFunc = function(c,v) _G.GTLMODState.CustomTextData.AimTouchHipDist = v * 5 return true end },

    -- SHOTGUN
    { Key = "ModMenu_AT_SG_Ex", UI = AliasMap.TitleSwitcher, Text = "   ▶ Shotgun Aimbot", ExpandHandle = "ModMenu_AT_Ex", ExpandIndex = 0, GetFunc = function() return _G.GTLMODConfig.AimTouchSG end, SetFunc = function(c,v) _G.GTLMODConfig.AimTouchSG = v return true end },
    { Key = "ModMenu_AT_SG_AutoFire", UI = AliasMap.Switcher, Text = "      Auto Fire", ExpandHandle = "ModMenu_AT_SG_Ex", GetFunc = function() return _G.GTLMODConfig.AimTouchSGAutoFire end, SetFunc = function(c,v) _G.GTLMODConfig.AimTouchSGAutoFire = v return true end },
    { Key = "ModMenu_AT_SG_IgKnock", UI = AliasMap.Switcher, Text = "      Ignore Knocked", ExpandHandle = "ModMenu_AT_SG_Ex", GetFunc = function() return _G.GTLMODConfig.AimTouchSGIgKnock end, SetFunc = function(c,v) _G.GTLMODConfig.AimTouchSGIgKnock = v return true end },
    { Key = "ModMenu_AT_SG_IgBot", UI = AliasMap.Switcher, Text = "      Ignore Bots", ExpandHandle = "ModMenu_AT_SG_Ex", GetFunc = function() return _G.GTLMODConfig.AimTouchSGIgBot end, SetFunc = function(c,v) _G.GTLMODConfig.AimTouchSGIgBot = v return true end },
    { Key = "ModMenu_AT_SG_Vis", UI = AliasMap.Switcher, Text = "      Visibility Check", ExpandHandle = "ModMenu_AT_SG_Ex", GetFunc = function() return _G.GTLMODConfig.AimTouchSGVisCheck end, SetFunc = function(c,v) _G.GTLMODConfig.AimTouchSGVisCheck = v return true end },
    { Key = "ModMenu_AT_SG_Bone", UI = AliasMap.Slider, Text = "      Bone (1:Head 2:Chest 3:Stomach 4:Pelvis)", ExpandHandle = "ModMenu_AT_SG_Ex", MinValue = 1, MaxValue = 4, min = 1, max = 4, GetFunc = function() return _G.GTLMODState.CustomTextData.AimTouchSGBone or 2 end, SetFunc = function(c,v) local val = math.floor(v+0.5); if val < 1 then val = 1 end; if val > 4 then val = 4 end; _G.GTLMODState.CustomTextData.AimTouchSGBone = val return true end },
    { Key = "ModMenu_AT_SG_Spd", UI = AliasMap.Slider, Text = "      Smoothness (1-100)", ExpandHandle = "ModMenu_AT_SG_Ex", MinValue = 1, MaxValue = 100, min = 1, max = 100, GetFunc = function() return _G.GTLMODState.CustomTextData.AimTouchSGSpeed or 80 end, SetFunc = function(c,v) _G.GTLMODState.CustomTextData.AimTouchSGSpeed = v return true end },
    { Key = "ModMenu_AT_SG_FOV", UI = AliasMap.Slider, Text = "      FOV Radius (1-100)", ExpandHandle = "ModMenu_AT_SG_Ex", MinValue = 1, MaxValue = 100, min = 1, max = 100, GetFunc = function() return _G.GTLMODState.CustomTextData.AimTouchSGFOV or 40 end, SetFunc = function(c,v) _G.GTLMODState.CustomTextData.AimTouchSGFOV = v return true end },
    { Key = "ModMenu_AT_SG_Dist", UI = AliasMap.Slider, Text = "      Distance (1-100m)", ExpandHandle = "ModMenu_AT_SG_Ex", MinValue = 1, MaxValue = 100, min = 1, max = 100, GetFunc = function() return _G.GTLMODState.CustomTextData.AimTouchSGDist or 30 end, SetFunc = function(c,v) _G.GTLMODState.CustomTextData.AimTouchSGDist = v return true end },

    -- SCOPE
    { Key = "ModMenu_AT_ScopeAll_Ex", UI = AliasMap.TitleSwitcher, Text = "   ▶ Scope Aimbot", ExpandHandle = "ModMenu_AT_Ex", ExpandIndex = 0, GetFunc = function() return _G.GTLMODConfig.AimTouchScopeAll end, SetFunc = function(c,v) _G.GTLMODConfig.AimTouchScopeAll = v return true end },
    { Key = "ModMenu_AT_ScopeAll_IgKnock", UI = AliasMap.Switcher, Text = "      Ignore Knocked", ExpandHandle = "ModMenu_AT_ScopeAll_Ex", GetFunc = function() return _G.GTLMODConfig.AimTouchScopeIgKnock end, SetFunc = function(c,v) _G.GTLMODConfig.AimTouchScopeIgKnock = v return true end },
    { Key = "ModMenu_AT_ScopeAll_IgBot", UI = AliasMap.Switcher, Text = "      Ignore Bots", ExpandHandle = "ModMenu_AT_ScopeAll_Ex", GetFunc = function() return _G.GTLMODConfig.AimTouchScopeIgBot end, SetFunc = function(c,v) _G.GTLMODConfig.AimTouchScopeIgBot = v return true end },
    { Key = "ModMenu_AT_ScopeAll_Vis", UI = AliasMap.Switcher, Text = "      Visibility Check", ExpandHandle = "ModMenu_AT_ScopeAll_Ex", GetFunc = function() return _G.GTLMODConfig.AimTouchScopeVisCheck end, SetFunc = function(c,v) _G.GTLMODConfig.AimTouchScopeVisCheck = v return true end },
    { Key = "ModMenu_AT_ScopeAll_Bone", UI = AliasMap.Slider, Text = "      Bone (1:Head 2:Chest 3:Stomach 4:Pelvis)", ExpandHandle = "ModMenu_AT_ScopeAll_Ex", MinValue = 1, MaxValue = 4, min = 1, max = 4, GetFunc = function() return _G.GTLMODState.CustomTextData.AimTouchScopeBone or 2 end, SetFunc = function(c,v) local val = math.floor(v+0.5); if val < 1 then val = 1 end; if val > 4 then val = 4 end; _G.GTLMODState.CustomTextData.AimTouchScopeBone = val return true end },
    { Key = "ModMenu_AT_ScopeAll_Spd", UI = AliasMap.Slider, Text = "      Smoothness (1-100)", ExpandHandle = "ModMenu_AT_ScopeAll_Ex", MinValue = 1, MaxValue = 100, min = 1, max = 100, GetFunc = function() return _G.GTLMODState.CustomTextData.AimTouchScopeSpeed or 40 end, SetFunc = function(c,v) _G.GTLMODState.CustomTextData.AimTouchScopeSpeed = v return true end },
    { Key = "ModMenu_AT_ScopeAll_FOV", UI = AliasMap.Slider, Text = "      FOV Radius (1-100)", ExpandHandle = "ModMenu_AT_ScopeAll_Ex", MinValue = 1, MaxValue = 100, min = 1, max = 100, GetFunc = function() return _G.GTLMODState.CustomTextData.AimTouchScopeFOV or 20 end, SetFunc = function(c,v) _G.GTLMODState.CustomTextData.AimTouchScopeFOV = v return true end },
    { Key = "ModMenu_AT_ScopeAll_Dist", UI = AliasMap.Slider, Text = "      Distance (1-500m)", ExpandHandle = "ModMenu_AT_ScopeAll_Ex", MinValue = 1, MaxValue = 100, min = 1, max = 100, GetFunc = function() return math.floor((_G.GTLMODState.CustomTextData.AimTouchScopeDist or 300) / 5) end, SetFunc = function(c,v) _G.GTLMODState.CustomTextData.AimTouchScopeDist = v * 5 return true end },
    { Key = "ModMenu_AT_ScopeAll_Pred", UI = AliasMap.Slider, Text = "      Prediction", ExpandHandle = "ModMenu_AT_ScopeAll_Ex", MinValue = 0, MaxValue = 100, min = 0, max = 100, GetFunc = function() return _G.GTLMODState.CustomTextData.AimTouchScopePred or 0 end, SetFunc = function(c,v) _G.GTLMODState.CustomTextData.AimTouchScopePred = v return true end },
    { Key = "ModMenu_AT_ScopeAll_Recoil", UI = AliasMap.Slider, Text = "      Recoil Comp", ExpandHandle = "ModMenu_AT_ScopeAll_Ex", MinValue = 0, MaxValue = 50, min = 0, max = 50, GetFunc = function() return _G.GTLMODState.CustomTextData.AimTouchScopeRecoil or 0 end, SetFunc = function(c,v) _G.GTLMODState.CustomTextData.AimTouchScopeRecoil = v return true end },

    -- SNIPER
    { Key = "ModMenu_AT_Sniper_Ex", UI = AliasMap.TitleSwitcher, Text = "   ▶ Sniper Aimbot", ExpandHandle = "ModMenu_AT_Ex", ExpandIndex = 0, GetFunc = function() return _G.GTLMODConfig.AimTouchScopeSniper end, SetFunc = function(c,v) _G.GTLMODConfig.AimTouchScopeSniper = v return true end },
    { Key = "ModMenu_AT_Sniper_IgKnock", UI = AliasMap.Switcher, Text = "      Ignore Knocked", ExpandHandle = "ModMenu_AT_Sniper_Ex", GetFunc = function() return _G.GTLMODConfig.AimTouchSniperIgKnock end, SetFunc = function(c,v) _G.GTLMODConfig.AimTouchSniperIgKnock = v return true end },
    { Key = "ModMenu_AT_Sniper_IgBot", UI = AliasMap.Switcher, Text = "      Ignore Bots", ExpandHandle = "ModMenu_AT_Sniper_Ex", GetFunc = function() return _G.GTLMODConfig.AimTouchSniperIgBot end, SetFunc = function(c,v) _G.GTLMODConfig.AimTouchSniperIgBot = v return true end },
    { Key = "ModMenu_AT_Sniper_Vis", UI = AliasMap.Switcher, Text = "      Visibility Check", ExpandHandle = "ModMenu_AT_Sniper_Ex", GetFunc = function() return _G.GTLMODConfig.AimTouchSniperVisCheck end, SetFunc = function(c,v) _G.GTLMODConfig.AimTouchSniperVisCheck = v return true end },
    { Key = "ModMenu_AT_Sniper_Bone", UI = AliasMap.Slider, Text = "      Bone (1:Head 2:Chest 3:Stomach 4:Pelvis)", ExpandHandle = "ModMenu_AT_Sniper_Ex", MinValue = 1, MaxValue = 4, min = 1, max = 4, GetFunc = function() return _G.GTLMODState.CustomTextData.AimTouchSniperBone or 1 end, SetFunc = function(c,v) local val = math.floor(v+0.5); if val < 1 then val = 1 end; if val > 4 then val = 4 end; _G.GTLMODState.CustomTextData.AimTouchSniperBone = val return true end },
    { Key = "ModMenu_AT_Sniper_Spd", UI = AliasMap.Slider, Text = "      Smoothness (1-100)", ExpandHandle = "ModMenu_AT_Sniper_Ex", MinValue = 1, MaxValue = 100, min = 1, max = 100, GetFunc = function() return _G.GTLMODState.CustomTextData.AimTouchSniperSpeed or 30 end, SetFunc = function(c,v) _G.GTLMODState.CustomTextData.AimTouchSniperSpeed = v return true end },
    { Key = "ModMenu_AT_Sniper_FOV", UI = AliasMap.Slider, Text = "      FOV Radius (1-100)", ExpandHandle = "ModMenu_AT_Sniper_Ex", MinValue = 1, MaxValue = 100, min = 1, max = 100, GetFunc = function() return _G.GTLMODState.CustomTextData.AimTouchSniperFOV or 20 end, SetFunc = function(c,v) _G.GTLMODState.CustomTextData.AimTouchSniperFOV = v return true end },
    { Key = "ModMenu_AT_Sniper_Dist", UI = AliasMap.Slider, Text = "      Distance (1-500m)", ExpandHandle = "ModMenu_AT_Sniper_Ex", MinValue = 1, MaxValue = 100, min = 1, max = 100, GetFunc = function() return math.floor((_G.GTLMODState.CustomTextData.AimTouchSniperDist or 400) / 5) end, SetFunc = function(c,v) _G.GTLMODState.CustomTextData.AimTouchSniperDist = v * 5 return true end },
    { Key = "ModMenu_AT_Sniper_Pred", UI = AliasMap.Slider, Text = "      Prediction", ExpandHandle = "ModMenu_AT_Sniper_Ex", MinValue = 0, MaxValue = 100, min = 0, max = 100, GetFunc = function() return _G.GTLMODState.CustomTextData.AimTouchSniperPred or 0 end, SetFunc = function(c,v) _G.GTLMODState.CustomTextData.AimTouchSniperPred = v return true end },

    -- MORTAR
    { Key = "ModMenu_AT_Mortar_Ex", UI = AliasMap.TitleSwitcher, Text = "   ▶ Mortar Aimbot", ExpandHandle = "ModMenu_AT_Ex", ExpandIndex = 0, GetFunc = function() return _G.GTLMODConfig.AimTouchMortar end, SetFunc = function(c,v) _G.GTLMODConfig.AimTouchMortar = v return true end },
    { Key = "ModMenu_AT_Mortar_FOV", UI = AliasMap.Slider, Text = "      FOV Radius (1-360)", ExpandHandle = "ModMenu_AT_Mortar_Ex", MinValue = 1, MaxValue = 360, min = 1, max = 360, GetFunc = function() return _G.GTLMODState.CustomTextData.AimTouchMortarFOV or 360 end, SetFunc = function(c,v) _G.GTLMODState.CustomTextData.AimTouchMortarFOV = v return true end },
    { Key = "ModMenu_AT_Mortar_Pred", UI = AliasMap.Slider, Text = "      Prediction", ExpandHandle = "ModMenu_AT_Mortar_Ex", MinValue = 0, MaxValue = 100, min = 0, max = 100, GetFunc = function() return _G.GTLMODState.CustomTextData.AimTouchMortarPred or 0 end, SetFunc = function(c,v) _G.GTLMODState.CustomTextData.AimTouchMortarPred = v return true end },
}
        local StackCombatGraphic = {
    { Key = "ModMenu_Ipad_Ex", UI = AliasMap.TitleSwitcher, Text = "▶ iPad View", ExpandIndex = 0, GetFunc = function() return _G.GTLMODConfig.IpadView end, SetFunc = function(c,v) _G.GTLMODConfig.IpadView = v return true end },
    { Key = "ModMenu_Ipad_FOV", UI = AliasMap.Slider, Text = "   FOV Angle", ExpandHandle = "ModMenu_Ipad_Ex", MinValue = 1, MaxValue = 100, min = 1, max = 100, GetFunc = function() return (_G.GTLMODState.CustomTextData.IpadViewFOV or 120) - 80 end, SetFunc = function(c,v) _G.GTLMODState.CustomTextData.IpadViewFOV = 80 + v return true end },
    { Key = "ModMenu_165FPS", UI = AliasMap.Switcher, Text = "Unlock 165 FPS", GetFunc = function() return _G.GTLMODConfig.UnlockFPS end, SetFunc = function(c,v) _G.GTLMODConfig.UnlockFPS = v; if v then _G.GTLMODState.GraphicsUnlocked = false end return true end },
    { Key = "ModMenu_BlackSky", UI = AliasMap.Switcher, Text = "Black Sky", GetFunc = function() return _G.GTLMODConfig.BlackSky end, SetFunc = function(c,v) _G.GTLMODConfig.BlackSky = v return true end },
    { Key = "ModMenu_RemoveFog", UI = AliasMap.Switcher, Text = "Remove Fog", GetFunc = function() return _G.GTLMODConfig.RemoveFog end, SetFunc = function(c,v) _G.GTLMODConfig.RemoveFog = v return true end },
}

-- AddOutfit skin buttons removed

SettingPageDefine.ModMenu = {
    Key = "ModMenu",
    Text = "UX_Official MENU",
    UIKey = "Setting_Page_Privacy",
    Category = {
        { Key = "Cat_Aimbot_Force", Text = "CUSTOM AIMBOT V2", Stack = StackAimbotV2 },
        { Key = "Cat_ESP_Visual", Text = "ESP PLAYER", Stack = StackESPVisual },
        { Key = "Cat_Wallhack", Text = "WALLHACK SETTINGS", Stack = StackWallhack },
        { Key = "Cat_Combat_Graphic", Text = "WALLHACK/FPS", Stack = StackCombatGraphic }
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

local function Notify(msg)
    local s = "[UX MOD] " .. tostring(msg)
    pcall(function()
        local sh = safeImport("ScriptHelperClient")
        if sh and sh.AddOnScreenDebugMessage then
            sh.AddOnScreenDebugMessage(s, -1, 3.0, {R=1,G=1,B=0,A=1}, {X=1.2, Y=1.2})
        end
    end)
end

-- ====================================================================
-- GRAPHICS UNLOCK
-- ====================================================================
local function InitializeGraphicsUnlock()
    if isExpired then return end
    if _G.GTLMODState.GraphicsUnlocked then return end
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

-- ====================================================================
-- NATIVE ESP
-- ====================================================================
local function InitializeNativeESP()
    if _G.GTLMODState.NativeESPReady then return end
    pcall(function()
        local currentMarkCfg = GamePlayTools and GamePlayTools.GetCurrentConfig and GamePlayTools.GetCurrentConfig("ScreenMarkConfig")
        local function ApplyCfg(cfg)
            if not cfg then return end
            if cfg[1006] then
                cfg[1006].bBindBlocked = true
                cfg[1006].bBindOutScreen = true
                cfg[1006].MaxWidgetNum = 99
                cfg[1006].MaxShowDistance = 6000000
                cfg[1006].bScaleByDistance = false
                cfg[1006].BindSocketName = "root"
                cfg[1006].bUseLuaWorldSocketName = true
                cfg[1006].WorldPositionOffset = FVector(0, 0, -30)
            end
            cfg[8888] = {
                UIPathName = "/Game/Mod/EvoBase/BluePrints/UIBP/QuickSign/QuickSign_TipHitEnemy_UIBP_New.QuickSign_TipHitEnemy_UIBP_New_C",
                MaxWidgetNum = 99, MaxShowDistance = 6000000,
                bBindOutScreen = true, bBindBlocked = true, bIsBindingActor = true,
                BindSocketName = "head", bUseLuaWorldSocketName = true,
                WorldPositionOffset = FVector(0, 0, 30), bNeedPreLoad = true, Priority = 2
            }
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
    _G.GTLMODState.NativeESPReady = true
end

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
    if _G.GTLMODState.TrackedMarks then _G.GTLMODState.TrackedMarks[mark] = nil end
end

local function GetSafeEnemyKey(enemy)
    if Valid(enemy) then
        if enemy.PlayerKey then return tostring(enemy.PlayerKey) end
        if type(enemy.GetUniqueID) == "function" then return tostring(enemy:GetUniqueID()) end
    end
    return tostring(enemy)
end

-- ====================================================================
-- COUNTER
-- ====================================================================
local RJCounter = {
    Canvas = nil, RealFrame = nil, RealBg = nil, RealDot = nil, RealLabel = nil, RealText = nil,
    BotFrame = nil, BotBg = nil, BotDot = nil, BotLabel = nil, BotText = nil,
    LastRealText = "", LastBotText = "", Created = false, BotCache = {}, Enabled = true,
}
_G.RJCounter = RJCounter

function RJCounter.SetEnabled(on)
    RJCounter.Enabled = on
    if not on and RJCounter.Created then
        local Items = { RJCounter.RealFrame, RJCounter.RealBg, RJCounter.RealDot, RJCounter.RealLabel, RJCounter.RealText,
                        RJCounter.BotFrame, RJCounter.BotBg, RJCounter.BotDot, RJCounter.BotLabel, RJCounter.BotText }
        for _, w in ipairs(Items) do
            if w and Valid(w) then pcall(function() w:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end) end
        end
    end
end

local function CounterRainbowColor(t, phase)
    phase = phase or 0
    local r = math.sin(t * 1.8 + phase) * 0.5 + 0.5
    local g = math.sin(t * 1.8 + phase + 2.094) * 0.5 + 0.5
    local b = math.sin(t * 1.8 + phase + 4.188) * 0.5 + 0.5
    local FC = safeImport("LinearColor")
    if not FC then return {R=255, G=255, B=255, A=255} end
    return FC(0.25 + r * 0.75, 0.25 + g * 0.75, 0.25 + b * 0.75, 1.0)
end

local function CounterGetCanvas()
    local canvas = nil
    pcall(function()
        local T = require("GameLua.Mod.BaseMod.Common.UI.InGameUITools")
        local M = T.GetMainControlBaseUI()
        if M then
            if M.CanvasPanel_0 and Game:IsValid(M.CanvasPanel_0) then canvas = M.CanvasPanel_0
            elseif M.CanvasPanel_42 and Game:IsValid(M.CanvasPanel_42) then canvas = M.CanvasPanel_42 end
        end
    end)
    return canvas
end

local function CounterDetectBot(Character)
    if not Valid(Character) then return nil end
    local CacheKey = nil
    pcall(function()
        if Character.PlayerKey then CacheKey = tostring(Character.PlayerKey)
        elseif type(Character.GetUniqueID) == "function" then CacheKey = tostring(Character:GetUniqueID()) end
    end)
    if not CacheKey then CacheKey = tostring(Character) end
    if RJCounter.BotCache[CacheKey] ~= nil then return RJCounter.BotCache[CacheKey] end

    local IsBot = false
    local Checked = false
    pcall(function()
        if Game and type(Game.IsAI) == "function" then
            local NativeAI = Game:IsAI(Character)
            if NativeAI ~= nil then Checked = true; if NativeAI == true then IsBot = true end end
        end
        if Character.bIsAI ~= nil then Checked = true; if Character.bIsAI == true then IsBot = true end end
        if Character.IsAI ~= nil then Checked = true; if Character.IsAI == true then IsBot = true end end
        if type(Character.IsBot) == "function" then
            Checked = true
            local Result = Character:IsBot()
            if Result == true then IsBot = true end
        end
        local PS = Character.PlayerState or (type(Character.GetPlayerState) == "function" and Character:GetPlayerState())
        if Valid(PS) then
            Checked = true
            if PS.bIsABot == true or PS.bIsBot == true then IsBot = true end
            if type(PS.IsBot) == "function" and PS:IsBot() then IsBot = true end
        end
        if not IsBot then
            local Name = Character.PlayerName or (type(Character.GetPlayerName) == "function" and Character:GetPlayerName()) or ""
            if Name ~= "" and (Name:find("Cobra") or Name:find("Target") or Name:find("bot_") or Name:find("b_")) then
                IsBot = true; Checked = true
            end
        end
    end)
    if IsBot then RJCounter.BotCache[CacheKey] = true; return true end
    if Checked then RJCounter.BotCache[CacheKey] = false; return false end
    return nil
end

local function CounterCreateUI()
    if RJCounter.RealText and Valid(RJCounter.RealText) then return true end
    local canvas = CounterGetCanvas()
    if not canvas or not Game:IsValid(canvas) then return false end
    RJCounter.Canvas = canvas

    local boxW, boxH, gap = 145, 36, 8
    local centerX, topY = 460, 60
    local framePad = 2
    local FLC = safeImport("LinearColor")
    local FSlate = safeImport("SlateColor") or safeImport("/Script/SlateCore.SlateColor")

    if not FLC then return false end

    pcall(function()
        RJCounter.RealFrame = CGame:NewObjectFromPath("/Script/UMG.Border", canvas)
        if Valid(RJCounter.RealFrame) then
            RJCounter.RealFrame:SetBrushColor(FLC(1.0, 0.2, 0.2, 1.0))
            local s = canvas:AddChildToCanvas(RJCounter.RealFrame)
            if s then s:SetAutoSize(false); s:SetPosition(FVector2D(centerX - framePad, topY - framePad)); s:SetSize(FVector2D(boxW + framePad*2, boxH + framePad*2)); s:SetAlignment(FVector2D(0,0)); s:SetZOrder(4999) end
        end
        RJCounter.RealBg = CGame:NewObjectFromPath("/Script/UMG.Border", canvas)
        if Valid(RJCounter.RealBg) then
            RJCounter.RealBg:SetBrushColor(FLC(0.05, 0.02, 0.02, 0.92))
            local s = canvas:AddChildToCanvas(RJCounter.RealBg)
            if s then s:SetAutoSize(false); s:SetPosition(FVector2D(centerX, topY)); s:SetSize(FVector2D(boxW, boxH)); s:SetAlignment(FVector2D(0,0)); s:SetZOrder(5000) end
        end
        RJCounter.RealDot = CGame:NewObjectFromPath("/Script/UMG.Border", canvas)
        if Valid(RJCounter.RealDot) then
            RJCounter.RealDot:SetBrushColor(FLC(1.0, 0.2, 0.2, 1.0))
            local s = canvas:AddChildToCanvas(RJCounter.RealDot)
            if s then s:SetAutoSize(false); s:SetPosition(FVector2D(centerX + 10, topY + 13)); s:SetSize(FVector2D(10, 10)); s:SetAlignment(FVector2D(0,0)); s:SetZOrder(5001) end
        end
        RJCounter.RealLabel = CGame:NewObjectFromPath("/Script/UMG.TextBlock", canvas)
        if Valid(RJCounter.RealLabel) then
            RJCounter.RealLabel:SetText("REAL")
            if FSlate then RJCounter.RealLabel:SetColorAndOpacity(FSlate(FLC(0.85, 0.85, 0.9, 1.0))) else RJCounter.RealLabel:SetColorAndOpacity(FLC(0.85, 0.85, 0.9, 1.0)) end
            local f = RJCounter.RealLabel.Font
            if f then f.Size = 13; RJCounter.RealLabel:SetFont(f) end
            RJCounter.RealLabel:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
            local s = canvas:AddChildToCanvas(RJCounter.RealLabel)
            if s then s:SetAutoSize(false); s:SetAlignment(FVector2D(0, 0.5)); s:SetPosition(FVector2D(centerX + 28, topY + boxH/2)); s:SetSize(FVector2D(60, boxH)); s:SetZOrder(5002) end
        end
        RJCounter.RealText = CGame:NewObjectFromPath("/Script/UMG.TextBlock", canvas)
        if Valid(RJCounter.RealText) then
            RJCounter.RealText:SetText("0")
            if FSlate then RJCounter.RealText:SetColorAndOpacity(FSlate(FLC(1,1,1,1))) else RJCounter.RealText:SetColorAndOpacity(FLC(1,1,1,1)) end
            local f = RJCounter.RealText.Font
            if f then f.Size = 20; RJCounter.RealText:SetFont(f) end
            RJCounter.RealText:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
            local s = canvas:AddChildToCanvas(RJCounter.RealText)
            if s then s:SetAutoSize(false); s:SetAlignment(FVector2D(1, 0.5)); s:SetPosition(FVector2D(centerX + boxW - 12, topY + boxH/2)); s:SetSize(FVector2D(60, boxH)); s:SetZOrder(5002) end
        end
        RJCounter.BotFrame = CGame:NewObjectFromPath("/Script/UMG.Border", canvas)
        if Valid(RJCounter.BotFrame) then
            RJCounter.BotFrame:SetBrushColor(FLC(0.2, 1.0, 0.2, 1.0))
            local s = canvas:AddChildToCanvas(RJCounter.BotFrame)
            if s then s:SetAutoSize(false); s:SetPosition(FVector2D(centerX + boxW + gap - framePad, topY - framePad)); s:SetSize(FVector2D(boxW + framePad*2, boxH + framePad*2)); s:SetAlignment(FVector2D(0,0)); s:SetZOrder(4999) end
        end
        RJCounter.BotBg = CGame:NewObjectFromPath("/Script/UMG.Border", canvas)
        if Valid(RJCounter.BotBg) then
            RJCounter.BotBg:SetBrushColor(FLC(0.02, 0.05, 0.02, 0.92))
            local s = canvas:AddChildToCanvas(RJCounter.BotBg)
            if s then s:SetAutoSize(false); s:SetPosition(FVector2D(centerX + boxW + gap, topY)); s:SetSize(FVector2D(boxW, boxH)); s:SetAlignment(FVector2D(0,0)); s:SetZOrder(5000) end
        end
        RJCounter.BotDot = CGame:NewObjectFromPath("/Script/UMG.Border", canvas)
        if Valid(RJCounter.BotDot) then
            RJCounter.BotDot:SetBrushColor(FLC(0.2, 1.0, 0.2, 1.0))
            local s = canvas:AddChildToCanvas(RJCounter.BotDot)
            if s then s:SetAutoSize(false); s:SetPosition(FVector2D(centerX + boxW + gap + 10, topY + 13)); s:SetSize(FVector2D(10, 10)); s:SetAlignment(FVector2D(0,0)); s:SetZOrder(5001) end
        end
        RJCounter.BotLabel = CGame:NewObjectFromPath("/Script/UMG.TextBlock", canvas)
        if Valid(RJCounter.BotLabel) then
            RJCounter.BotLabel:SetText("BOT")
            if FSlate then RJCounter.BotLabel:SetColorAndOpacity(FSlate(FLC(0.85, 0.85, 0.9, 1.0))) else RJCounter.BotLabel:SetColorAndOpacity(FLC(0.85, 0.85, 0.9, 1.0)) end
            local f = RJCounter.BotLabel.Font
            if f then f.Size = 13; RJCounter.BotLabel:SetFont(f) end
            RJCounter.BotLabel:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
            local s = canvas:AddChildToCanvas(RJCounter.BotLabel)
            if s then s:SetAutoSize(false); s:SetAlignment(FVector2D(0, 0.5)); s:SetPosition(FVector2D(centerX + boxW + gap + 28, topY + boxH/2)); s:SetSize(FVector2D(60, boxH)); s:SetZOrder(5002) end
        end
        RJCounter.BotText = CGame:NewObjectFromPath("/Script/UMG.TextBlock", canvas)
        if Valid(RJCounter.BotText) then
            RJCounter.BotText:SetText("0")
            if FSlate then RJCounter.BotText:SetColorAndOpacity(FSlate(FLC(1,1,1,1))) else RJCounter.BotText:SetColorAndOpacity(FLC(1,1,1,1)) end
            local f = RJCounter.BotText.Font
            if f then f.Size = 20; RJCounter.BotText:SetFont(f) end
            RJCounter.BotText:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
            local s = canvas:AddChildToCanvas(RJCounter.BotText)
            if s then s:SetAutoSize(false); s:SetAlignment(FVector2D(1, 0.5)); s:SetPosition(FVector2D(centerX + boxW + gap + boxW - 12, topY + boxH/2)); s:SetSize(FVector2D(60, boxH)); s:SetZOrder(5002) end
        end
    end)
    RJCounter.Created = true
    return RJCounter.RealText ~= nil
end

local function GetPlayerCharacterLocal()
    local p = nil
    pcall(function() p = GameplayData.GetPlayerCharacter() end)
    return p
end

local function RJCounterTick()
    pcall(function()
        if not _G.GTLMODConfig.CounterEnabled then return end
        if not CounterCreateUI() then return end
        local Now = os.clock()
        if Valid(RJCounter.RealFrame) then pcall(function() RJCounter.RealFrame:SetBrushColor(CounterRainbowColor(Now, 0)) end) end
        if Valid(RJCounter.BotFrame) then pcall(function() RJCounter.BotFrame:SetBrushColor(CounterRainbowColor(Now, 1.5)) end) end

        local localPlayer = GetPlayerCharacterLocal()
        if not slua.isValid(localPlayer) then return end
        local myTeam = 0
        pcall(function() myTeam = localPlayer.TeamID or localPlayer:GetTeamID() or 0 end)

        local allCharacters = {}
        if GameplayData.GetAllPlayerCharacters then
            allCharacters = GameplayData.GetAllPlayerCharacters()
        elseif GameplayData.GameCharacters then
            for _, c in pairs(GameplayData.GameCharacters) do table.insert(allCharacters, c) end
        end

        local RealCount = 0
        local BotCount = 0
        for _, c in pairs(allCharacters) do
            if Valid(c) and c ~= localPlayer then
                local alive = false
                pcall(function()
                    if c.Health and c.Health > 0 then alive = true
                    elseif type(c.IsAlive) == "function" and c:IsAlive() then alive = true end
                end)
                local tTeam = 0
                pcall(function() tTeam = c.TeamID or (type(c.GetTeamID) == "function" and c:GetTeamID()) or 0 end)
                if alive and tTeam ~= myTeam then
                    local isBot = CounterDetectBot(c)
                    if isBot == true then BotCount = BotCount + 1
                    elseif isBot == false then RealCount = RealCount + 1 end
                end
            end
        end
        local NewRealText = tostring(RealCount)
        local NewBotText = tostring(BotCount)
        if NewRealText ~= RJCounter.LastRealText then
            RJCounter.LastRealText = NewRealText
            if Valid(RJCounter.RealText) then RJCounter.RealText:SetText(NewRealText) end
        end
        if NewBotText ~= RJCounter.LastBotText then
            RJCounter.LastBotText = NewBotText
            if Valid(RJCounter.BotText) then RJCounter.BotText:SetText(NewBotText) end
        end
    end)
end

-- ====================================================================
-- AIMBOT
-- ====================================================================
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
                if type(actor.IsAlive) == "function" then
                    isAlive = actor:IsAlive()
                elseif actor.HealthStatus ~= nil then
                    isAlive = (actor.HealthStatus ~= 2)
                elseif actor.bIsDead ~= nil then
                    isAlive = not actor.bIsDead
                end
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

-- ====================================================================
-- NEW AIMBOT V2 (Hipfire / Shotgun / Scope / Sniper / Mortar)
-- ====================================================================
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
        if not _G.GTLMODConfig.AimTouchEnable then return end

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

        local isShotgun, isSniper, isMortar = false, false, false
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

        if _G.GTLMODState.IsAutoFiring then
            pcall(function()
                player.bIsWeaponFiring = false
                if type(player.SetIsWeaponFiring) == "function" then player:SetIsWeaponFiring(false) end
                if slua.isValid(pc) and type(pc.SetIsWeaponFiring) == "function" then pc:SetIsWeaponFiring(false) end
                local wepMgr = player.WeaponManagerComponent
                if slua.isValid(wepMgr) then wepMgr.bIsWeaponFiring = false end
            end)
            _G.GTLMODState.IsAutoFiring = false
        end

        if isShotgun and currentAmmo <= 0 then return end

        local cond = 2
        local prioMode = 1
        local boneIdx = 1
        local speedVal = 50
        local fovVal = 30
        local maxDistMeters = 50
        local useVisCheck, igKnock, igBot = false, false, false
        local predVal = 0
        local recoilCompVal = 0

        if isMortar and _G.GTLMODConfig.AimTouchMortar then
            local isPlaced = false
            pcall(function()
                if weapon and weapon.MortarState == 2 then isPlaced = true end
            end)
            if not isPlaced then return end

            cond = 2
            prioMode = 1
            boneIdx = 4
            speedVal = 100
            fovVal = _G.GTLMODState.CustomTextData.AimTouchMortarFOV or 360
            maxDistMeters = 2000
            useVisCheck = false
            igKnock = false
            igBot = false
            predVal = _G.GTLMODState.CustomTextData.AimTouchMortarPred or 0

        elseif isShotgun and _G.GTLMODConfig.AimTouchSG then
            cond = _G.GTLMODState.CustomTextData.AimTouchSGCond or 1
            if _G.GTLMODConfig.AimTouchSGAutoFire then cond = 2 end
            if cond == 1 and not isFiring then return end
            prioMode = _G.GTLMODState.CustomTextData.AimTouchSGPrio or 1
            boneIdx = _G.GTLMODState.CustomTextData.AimTouchSGBone or 2
            speedVal = _G.GTLMODState.CustomTextData.AimTouchSGSpeed or 80
            fovVal = _G.GTLMODState.CustomTextData.AimTouchSGFOV or 40
            maxDistMeters = _G.GTLMODState.CustomTextData.AimTouchSGDist or 30
            useVisCheck = _G.GTLMODConfig.AimTouchSGVisCheck
            igKnock = _G.GTLMODConfig.AimTouchSGIgKnock
            igBot = _G.GTLMODConfig.AimTouchSGIgBot

        elseif isADS then
            if isSniper and _G.GTLMODConfig.AimTouchScopeSniper then
                cond = _G.GTLMODState.CustomTextData.AimTouchSniperCond or 2
                if cond == 1 and not isFiring then return end
                prioMode = _G.GTLMODState.CustomTextData.AimTouchSniperPrio or 1
                boneIdx = _G.GTLMODState.CustomTextData.AimTouchSniperBone or 1
                speedVal = _G.GTLMODState.CustomTextData.AimTouchSniperSpeed or 30
                fovVal = _G.GTLMODState.CustomTextData.AimTouchSniperFOV or 20
                maxDistMeters = _G.GTLMODState.CustomTextData.AimTouchSniperDist or 400
                useVisCheck = _G.GTLMODConfig.AimTouchSniperVisCheck
                igKnock = _G.GTLMODConfig.AimTouchSniperIgKnock
                igBot = _G.GTLMODConfig.AimTouchSniperIgBot
                predVal = _G.GTLMODState.CustomTextData.AimTouchSniperPred or 0
            elseif _G.GTLMODConfig.AimTouchScopeAll then
                cond = _G.GTLMODState.CustomTextData.AimTouchScopeCond or 1
                if cond == 1 and not isFiring then return end
                prioMode = _G.GTLMODState.CustomTextData.AimTouchScopePrio or 1
                boneIdx = _G.GTLMODState.CustomTextData.AimTouchScopeBone or 2
                speedVal = _G.GTLMODState.CustomTextData.AimTouchScopeSpeed or 40
                fovVal = _G.GTLMODState.CustomTextData.AimTouchScopeFOV or 20
                maxDistMeters = _G.GTLMODState.CustomTextData.AimTouchScopeDist or 300
                useVisCheck = _G.GTLMODConfig.AimTouchScopeVisCheck
                igKnock = _G.GTLMODConfig.AimTouchScopeIgKnock
                igBot = _G.GTLMODConfig.AimTouchScopeIgBot
                predVal = _G.GTLMODState.CustomTextData.AimTouchScopePred or 0
                recoilCompVal = _G.GTLMODState.CustomTextData.AimTouchScopeRecoil or 0
            else
                return
            end
        else
            if not _G.GTLMODConfig.AimTouchHipfire then return end
            cond = _G.GTLMODState.CustomTextData.AimTouchHipCond or 1
            if cond == 1 and not isFiring then return end
            prioMode = _G.GTLMODState.CustomTextData.AimTouchHipPrio or 1
            boneIdx = _G.GTLMODState.CustomTextData.AimTouchHipBone or 1
            speedVal = _G.GTLMODState.CustomTextData.AimTouchHipSpeed or 50
            fovVal = _G.GTLMODState.CustomTextData.AimTouchHipFOV or 30
            maxDistMeters = _G.GTLMODState.CustomTextData.AimTouchHipDist or 250
            useVisCheck = _G.GTLMODConfig.AimTouchHipVisCheck
            igKnock = _G.GTLMODConfig.AimTouchHipIgKnock
            igBot = _G.GTLMODConfig.AimTouchHipIgBot
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

        if isMortar and _G.GTLMODConfig.AimTouchMortar and predVal > 0 then
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
        if speedVal >= 100 then smoothFactor = 1.0
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

        if isMortar and _G.GTLMODConfig.AimTouchMortar then
            local targetPos = { X = finalBonePos.X, Y = finalBonePos.Y, Z = finalBonePos.Z }
            local launchPos = camLoc
            pcall(function()
                if player.K2_GetActorLocation then
                    local pLoc = player:K2_GetActorLocation()
                    if pLoc then launchPos = { X = pLoc.X, Y = pLoc.Y, Z = pLoc.Z + 50 } end
                end
            end)

            local function CalcMortarTrajectory(V, G, tX, tY, tZ)
                local mDx = math.sqrt((tX - launchPos.X)^2 + (tY - launchPos.Y)^2) - 80
                if mDx < 500 then mDx = 500 end
                local mDy = tZ - launchPos.Z
                local minVSq = G * (mDy + math.sqrt(mDx*mDx + mDy*mDy))
                if (V * V) < minVSq then V = math.sqrt(minVSq) + 100 end
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

            local isValid, physAngle = false, 45
            local okNear, angNear = CalcMortarTrajectory(vNear, gNear, targetPos.X, targetPos.Y, targetPos.Z)
            local okFar, angFar = CalcMortarTrajectory(vFar, gFar, targetPos.X, targetPos.Y, targetPos.Z)
            local okUltra, angUltra = CalcMortarTrajectory(vUltra, gUltra, targetPos.X, targetPos.Y, targetPos.Z)

            if okNear then isValid, physAngle = okNear, angNear
            elseif okFar then isValid, physAngle = okFar, angFar
            elseif okUltra then isValid, physAngle = okUltra, angUltra end

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

        if isShotgun and _G.GTLMODConfig.AimTouchSGAutoFire then
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
                    _G.GTLMODState.IsAutoFiring = true
                end
            end)
        end
    end)
end
-- ====================================================================
-- MAIN LOOP
-- ====================================================================
local function MainLoop()
    if isExpired then return end

    if _G.GTLMODState.CustomTextData == nil then
    _G.GTLMODState.CustomTextData = {
        OuterSpeed = 10, InnerSpeed = 10, HRecoil = 0.3, VRecoil = 0.3, IpadViewFOV = 120,
        AimTouchHipPrio = 1, AimTouchHipBone = 1, AimTouchHipCond = 1, AimTouchHipSpeed = 50, AimTouchHipFOV = 30, AimTouchHipDist = 250,
        AimTouchSGPrio = 1, AimTouchSGBone = 2, AimTouchSGCond = 1, AimTouchSGSpeed = 80, AimTouchSGFOV = 40, AimTouchSGDist = 30,
        AimTouchScopePrio = 1, AimTouchScopeBone = 2, AimTouchScopeCond = 1, AimTouchScopeSpeed = 40, AimTouchScopeFOV = 20, AimTouchScopeDist = 300, AimTouchScopePred = 0, AimTouchScopeRecoil = 0,
        AimTouchSniperPrio = 1, AimTouchSniperBone = 1, AimTouchSniperCond = 2, AimTouchSniperSpeed = 30, AimTouchSniperFOV = 20, AimTouchSniperDist = 400, AimTouchSniperPred = 0,
        AimTouchMortarPred = 0, AimTouchMortarFOV = 360,
    }
end

    local pc = GameplayData.GetPlayerController()
    local localPlayer = nil
    if Valid(pc) then localPlayer = pc:GetPlayerCharacterSafety() end

    if not Valid(localPlayer) then
        if _G.GTLMODState.TrackedMarks then
            for markId, _ in pairs(_G.GTLMODState.TrackedMarks) do SafeRemoveMark(markId) end
        end
        _G.GTLMODState.TrackedMarks = {}
        for key, data in pairs(_G.GTLMODState.EnemyMarks) do
            if data and data.MIDs then
                for meshStr, midTable in pairs(data.MIDs) do
                    for k in pairs(midTable) do midTable[k] = nil end
                end
                data.MIDs = nil
            end
        end
        _G.GTLMODState.EnemyMarks = {}
        _G.GTLMODState.PrevGraphicsState = {}
        _G.BotStatusCache = {}
        _G.AimTouchVisCache = {}
        _G.GTLMODState.MidCacheCount = 0
        return
    end

    local Cached_MyHUD = pc and pc.MyHUD or nil

    if _G.GTLMODConfig.UnlockFPS then InitializeGraphicsUnlock() end
    InitializeNativeESP()

    if _G.GTLMODConfig.EspLine and ESPLine.Active then
        pcall(ESPLine.ScanAndUpdate)
    end

    if _G.GTLMODConfig.IpadView and _G.GTLMODState.CustomTextData then
        pcall(function()
            local targetTPP = _G.GTLMODState.CustomTextData.IpadViewFOV or 120
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

    pcall(function()
        if Valid(pc) then
            if pc.HiggsBoson then pc.HiggsBoson.bMHActive = false; pc.HiggsBoson.bCallPreReplication = false end
            if pc.HiggsBosonComponent then pc.HiggsBosonComponent.bMHActive = false; pc.HiggsBosonComponent.bCallPreReplication = false end
        end
    end)

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
                    HeadPriority = autoComp.AimAssistConfig and autoComp.AimAssistConfig.HeadPriority,
                    ChestPriority = autoComp.AimAssistConfig and autoComp.AimAssistConfig.ChestPriority,
                    PelvisPriority = autoComp.AimAssistConfig and autoComp.AimAssistConfig.PelvisPriority
                }
            end
            if _G.GTLMODConfig.AutoHead then
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
                local orig = _G.GTLMODState.OrigAutoAimCompCached
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
                if _G.AimTouchVisCache and _G.AimTouchVisCache[key] then _G.AimTouchVisCache[key] = nil end
                if _G.BotStatusCache and _G.BotStatusCache[key] then _G.BotStatusCache[key] = nil end
                if data.MIDs then
                    for meshStr, midTable in pairs(data.MIDs) do
                        for k in pairs(midTable) do midTable[k] = nil end
                    end
                    data.MIDs = nil
                end
                data.enemy = nil
                data.CachedMeshes = nil
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
                    local eMesh = nil
                    pcall(function() eMesh = enemy.Mesh end)
                    local aLoc = nil
                    pcall(function() if type(enemy.K2_GetActorLocation) == "function" then aLoc = enemy:K2_GetActorLocation() end end)
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
                        if _G.GTLMODConfig.EspDistance and distM <= LIMITS.ESP_MAX_DISTANCE then
                            pcall(function()
                                MyHUD:AddDebugText(string.format("%.0fm", math.floor(distM+0.5)), enemy, 0.3, {X=15,Y=15,Z=-15}, {X=15,Y=15,Z=-15}, C_WHITE, true, false, true, nil, 0.9, true)
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

-- ====================================================================
-- LOOPS
-- ====================================================================
_G.GTLMODState.LoopToken = (_G.GTLMODState.LoopToken or 0) + 1
local myToken = _G.GTLMODState.LoopToken

local function MainTick()
    if LicenseLocked() then
        local okTicker, ticker = pcall(require, "common.time_ticker")
        if okTicker and ticker and ticker.AddTimerOnce then
            ticker.AddTimerOnce(LIMITS.MAIN_TICK, MainTick)
        end
        return
    end
    if isExpired then
        if not _G.GTLMODNotifiedExpire then
            Notify("MOD HAS EXPIRED!")
            _G.GTLMODNotifiedExpire = true
        end
        return
    end
    if myToken ~= _G.GTLMODState.LoopToken then return end
    pcall(MainLoop)
    local okTicker, ticker = pcall(require, "common.time_ticker")
    if okTicker and ticker and ticker.AddTimerOnce then
        ticker.AddTimerOnce(LIMITS.MAIN_TICK, MainTick)
    end
end

local function AimbotTick()
    if LicenseLocked() then
        local okTicker, ticker = pcall(require, "common.time_ticker")
        if okTicker and ticker and ticker.AddTimerOnce then
            ticker.AddTimerOnce(LIMITS.AIMBOT_TICK, AimbotTick)
        end
        return
    end
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

local function CounterTickLoop()
    if LicenseLocked() then
        local okTicker, ticker = pcall(require, "common.time_ticker")
        if okTicker and ticker and ticker.AddTimerOnce then
            ticker.AddTimerOnce(1.0, CounterTickLoop)
        end
        return
    end
    if isExpired then return end
    if myToken ~= _G.GTLMODState.LoopToken then return end
    pcall(RJCounterTick)
    local okTicker, ticker = pcall(require, "common.time_ticker")
    if okTicker and ticker and ticker.AddTimerOnce then
        ticker.AddTimerOnce(1.0, CounterTickLoop)
    end
end

local function ESPLineTickLoop()
    if isExpired then return end
    if myToken ~= _G.GTLMODState.LoopToken then return end
    if _G.GTLMODConfig.EspLine and ESPLine.Active then
        pcall(ESPLine.ScanAndUpdate)
    end
    local okTicker, ticker = pcall(require, "common.time_ticker")
    if okTicker and ticker and ticker.AddTimerOnce then
        ticker.AddTimerOnce(LIMITS.ESP_LINE_UPDATE, ESPLineTickLoop)
    end
end

local function BypassRefreshLoop()
    if LicenseLocked() then
        local okTicker, ticker = pcall(require, "common.time_ticker")
        if okTicker and ticker and ticker.AddTimerOnce then
            ticker.AddTimerOnce(5.0, BypassRefreshLoop)
        end
        return
    end
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
        ticker.AddTimerOnce(1.0, CounterTickLoop)
        ticker.AddTimerOnce(LIMITS.ESP_LINE_UPDATE, ESPLineTickLoop)
        ticker.AddTimerOnce(5.0, BypassRefreshLoop)
    end
    Notify("RJ MOD v3500 loaded | " .. gameRegion .. " (" .. packageName .. ")")
else
    local okTicker, ticker = pcall(require, "common.time_ticker")
    if okTicker and ticker and ticker.AddTimerOnce then
        ticker.AddTimerOnce(0.2, MainTick)
    end
end

-- ====================================================================
-- AUTO-HEAD HOOKS
-- ====================================================================
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

-- ====================================================================
-- WELCOME MENU
-- ====================================================================
local function ShowGTLMODVIPMenu()
    if _G.GTLMODMenuAlreadyShown then return end
    if _G.GTLMODState.MenuStep ~= 0 then return end
    pcall(function()
        local Msg = require("client.slua.logic.common.logic_common_msg_box")
        if not Msg or not Msg.Show then return end
        local function Step_Final()
            Msg.Show(1, "UX_Official PAK", "Hello, my name is Cheater!!",
                function() local Web = require("client.slua.logic.url.logic_webview_sdk"); if Web and Web.OpenURL then Web:OpenURL("https://wa.me/923709241014") end end,
                function() end, "JOIN", "CLOSE")
            _G.GTLMODState.MenuStep = 99
            _G.GTLMODMenuAlreadyShown = true
        end
        local function Step_Welcome()
            Msg.Show(1, "5.0 UX_Official MOD", "  Look, unemployment has arrived, now kick the enemy's ass.Look, unemployment has arrived,.",
                function()
                    _G.InitModMenuTab()
                    Notify("VIP MOD MENU BY UX_Official")
                    Step_Final()
                end, function() end, "OK", "CLOSE")
        end
        _G.GTLMODState.MenuStep = 1
        Step_Welcome()
    end)
end

local function MenuTrigger()
    if isExpired then return end
    if _G.GTLMODState.MenuStep == 0 then
        pcall(ShowGTLMODVIPMenu)
    end
    local okTicker, ticker = pcall(require, "common.time_ticker")
    if okTicker and ticker and ticker.AddTimerOnce and not _G.GTLMODState.MenuShown then
        if _G.GTLMODState.MenuStep ~= 0 then _G.GTLMODState.MenuShown = true; return end
        ticker.AddTimerOnce(2.0, MenuTrigger)
    end
end
if not isExpired then
    pcall(function()
        require("common.time_ticker").AddTimerOnce(1.5, MenuTrigger)
    end)
end

-- ====================================================================
-- INIT ALL
-- ====================================================================
local function InitAllModSystems()
    if isExpired then return end
    pcall(function()
        if _G.StartBypass_VIP_v3 then _G.StartBypass_VIP_v3() end
        if _G.InitializeAutoHeadHooks then _G.InitializeAutoHeadHooks() end
        if _G.InitModMenuTab then _G.InitModMenuTab() end
        if _G.ESPLine and _G.GTLMODConfig.EspLine then _G.ESPLine.Start() end
        if _G.GTLMODConfig.WallhackSmart and _G.StartNewWallhack then _G.StartNewWallhack() end
    end)
end
if not isExpired then
    pcall(function()
        require("common.time_ticker").AddTimerOnce(0.5, InitAllModSystems)
    end)
end

-- ====================================================================
-- PUBLIC ESP API
-- ====================================================================
function BRPlayerCharacterBase:ESP_Start()
    if _G.ESPLine then _G.ESPLine.Start() end
end

function BRPlayerCharacterBase:ESP_Stop()
    if _G.ESPLine then _G.ESPLine.Stop() end
end

function BRPlayerCharacterBase:ESP_Toggle()
    if _G.ESPLine then return _G.ESPLine.Toggle() end
    return false
end

function BRPlayerCharacterBase:ESP_IsEnabled()
    return _G.GTLMODConfig.EspLine or false
end

function BRPlayerCharacterBase:ESP_IsRunning()
    return _G.ESPLine and _G.ESPLine.Active or false
end

-- ====================================================================
-- CLASS METHODS
-- ====================================================================
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
    local CheckFallingDistanceComponent_C = safeImport("CheckFallingDistanceComponent")
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

function BRPlayerCharacterBase:HandleOnAttachedToVehicle(uVehicle) if slua.isValid(uVehicle) then self:ClearAttachToVehicleTimer() end end
function BRPlayerCharacterBase:HandleOnDetachedFromVehicle(uLastVehicle) if slua.isValid(uLastVehicle) then self:ClearAttachToVehicleTimer() end end
function BRPlayerCharacterBase:UpdatePlayerAttachToVehicle() end
function BRPlayerCharacterBase:FixMeshContainerOffsetIfNeeded() end
function BRPlayerCharacterBase:ClearAttachToVehicleTimer()
  if self.nUpdatePlayerAttachToVehicleTimer then
    self:RemoveGameTimer(self.nUpdatePlayerAttachToVehicleTimer)
    self.nUpdatePlayerAttachToVehicleTimer = nil  end
  if self.nFixMeshContainerTimer then
    self:RemoveGameTimer(self.nFixMeshContainerTimer)
    self.nFixMeshContainerTimer = nil
  end
end

function BRPlayerCharacterBase:CharacterAttrChangeEvent(uPawn, AttrName, AttrVal)
  BRPlayerCharacterBase.__super.CharacterAttrChangeEvent(self, uPawn, AttrName, AttrVal)
  if self.Object ~= uPawn then return end
  if self.Role == ENetRole.ROLE_AutonomousProxy and AttrName == "bCanSelfRescue" then
    local pc = self:GetPlayerControllerSafety()
    if slua.isValid(pc) then pc:BroadcastUIMessage("UIMsg_CanSelfRescue", 0, "", "") end
  end
end

function BRPlayerCharacterBase:OnPawnStateChange(PawnState)
  local EPS = import("EPawnState")
  if PawnState == EPS.SwitchPP then
    local pc = self:GetPlayerControllerSafety()
    if slua.isValid(pc) then pc:BroadcastUIMessage("UIMsg_FPPModeChange", 0, "", "") end
  end
end

function BRPlayerCharacterBase:HandleFinishedState()
  if slua.isValid(self.STCharacterMovement) and self.STCharacterMovement.SetDynamicSimpleQueryConfig then
    self.STCharacterMovement:SetDynamicSimpleQueryConfig(false)
  end
end

function BRPlayerCharacterBase:CheckAddCheckFallingDistanceComponent() return false end
function BRPlayerCharacterBase:LuaHandleParachuteStateChanged(LastParachuteState, NewParachuteState)
  BRPlayerCharacterBase.__super.LuaHandleParachuteStateChanged(self, LastParachuteState, NewParachuteState)
end
function BRPlayerCharacterBase:OnLanded()
  if self.HandleOnLanded then self:HandleOnLanded(-1) end
end
function BRPlayerCharacterBase:ReceiveEndPlay(EndPlayReason)
  BRPlayerCharacterBase.__super.ReceiveEndPlay(self, EndPlayReason)
  if Client then GameplayData.RemoveCharacter(self.Object) end
end
function BRPlayerCharacterBase:IsWarGameMode() return false end
function BRPlayerCharacterBase:BPOnRecycled() if Client then self:ResetMeshRelativeLocationAndRotation() end end
function BRPlayerCharacterBase:BPOnRespawned() if Client then self:ResetMeshRelativeLocationAndRotation() end end
function BRPlayerCharacterBase:ReceiveOnRecycle() if Client then self:ResetMeshRelativeLocationAndRotation(); GameplayData.RemoveCharacter(self.Object) end end
function BRPlayerCharacterBase:ReceiveOnSpawn() if Client then self:ResetMeshRelativeLocationAndRotation(); GameplayData.AddCharacter(self.Object) end end
function BRPlayerCharacterBase:ResetMeshRelativeLocationAndRotation()
  if Game:IsValid(self.Object) and Game:IsValid(self.Mesh) then
    local rot = FRotator(0, -90, 0)
    if self.Mesh.K2_SetRelativeRotation then self.Mesh:K2_SetRelativeRotation(rot, false, nil, false) end
    self:CacheInitialMeshOffset(FVector(0, 0, 0), rot)
  end
end

function BRPlayerCharacterBase:HandleOnMovementModeChangedNew()
  local EMovementMode = import("EMovementMode")
  if Game:IsValid(self.STCharacterMovement) and self.STCharacterMovement.MovementMode == EMovementMode.MOVE_Swimming and self:CheckBaseIsMoveable() then
    self.CharacterMovement:SetBase(nil, "", true)
  end
end

function BRPlayerCharacterBase:BPOnMissPlayerDamageRecord() end
function BRPlayerCharacterBase:ClientRPC_TriggerHighlightMoment(Type, Param)
  EventSystem:postEvent(EVENTTYPE_INGAME, EVENTID_INGAME_TRIGGER_HIGHLIGHT_MOMENT, Type, Param)
end
function BRPlayerCharacterBase:ParachuteJump()
  local pc = self:GetControllerSafety()
  if slua.isValid(pc) and not self:GetEnsure() then
    local EStateType = import("EStateType")
    if pc:GetCurrentStateType() ~= EStateType.State_ParachuteJump and pc:GetCurrentStateType() ~= EStateType.State_ParachuteOpen then
      local EPS = import("ESTEPoseState")
      self:SwitchPoseState(EPS.Stand, true, true, true, false)
      pc:ReInitParachuteItem()
      pc:ServerChangeStatePC(EStateType.State_ParachuteJump)
    end
  end
end
function BRPlayerCharacterBase:CheckForbidFlaregun()
  local ps = self:GetPlayerStateSafety()
  if not slua.isValid(ps) then return false end
  return not ps.CanUseFlaregun
end
function BRPlayerCharacterBase:ServerRPC_NearDeathGiveupRescue() self:HandleNearDeathGiveupRescue() end
function BRPlayerCharacterBase:HandleNearDeathGiveupRescue() end
function BRPlayerCharacterBase:RPC_Server_GmPlayAction(actionId) end
function BRPlayerCharacterBase:MulticastRPC_GmPlayAction(actionId) end
function BRPlayerCharacterBase:RPC_Client_SetShouldCheckPassWall(b) if slua.isValid(self.ParachuteComponent) then self.ParachuteComponent.bServerSyncShouldCheckPassWall = b end end
function BRPlayerCharacterBase:OnPlayerEnterCarryBoxState() self.Super:OnPlayerEnterCarryBoxState(); if self.CarryDeadBoxFeature then self.CarryDeadBoxFeature:OnPlayerEnterCarryBoxState() end end
function BRPlayerCharacterBase:OnPlayerLeaveCarryBoxState(b) self.Super:OnPlayerLeaveCarryBoxState(b); if self.CarryDeadBoxFeature then self.CarryDeadBoxFeature:OnPlayerLeaveCarryBoxState(b) end end
function BRPlayerCharacterBase:ServerRPC_CarryDeadBox(u)
  if slua.isValid(u) and Game:IsClassOf(u, import("/Script/ShadowTrackerExtra.PlayerTombBox")) and self.CarryDeadBoxFeature then
    self.CarryDeadBoxFeature:CarryDeadBox(u)
  end
end
function BRPlayerCharacterBase:SetAreaID(a) self:SetAttrValue("AreaID", a, -1) end
function BRPlayerCharacterBase:GetAreaID() return math.floor(self:GetAttrValue("AreaID") + 0.5) end
function BRPlayerCharacterBase:CannotChangeIntoPetSpectator() return self.bCannotChangeIntoPetSpectator end
function BRPlayerCharacterBase:DoModChangeToBT() if self:HasState(EPawnState.SpecialSuit) then self:TriggerEntrySkillWithID(4301101, true) end end
function BRPlayerCharacterBase:SwitchCameraToParachuteOpening() self.Super:SwitchCameraToParachuteOpening() end
function BRPlayerCharacterBase:SwitchCameraToParachuteFalling() self.Super:SwitchCameraToParachuteFalling() end
function BRPlayerCharacterBase:SwitchCameraToNormal() self.Super:SwitchCameraToNormal() end
function BRPlayerCharacterBase:SwitchWeaponCheck(Slot, IgnoreState) return self.Super:SwitchWeaponCheck(Slot, IgnoreState) end

-- ====================================================================
-- RETURN SECTION
-- ====================================================================
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

  -- Keep the original BRPlayerCharacterBase feature chain intact.
  -- In particular, do not replace the original vehicle/formation/UI lifecycle features.
  { BuildAircraftVehicleFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.PlayerCharacterBuildVehicleFeature" },
  { UnifiedBuildVehicleFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.UnifiedBuildVehicleFeature" },

  -- Transformation feature: keep the original implementation available.
  { CommonBornlandTransformFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.HeroPropFeature.CommonBornlandTransformFeature" },

  { ParachuteFormation = "GameLua.Mod.BaseMod.GamePlay.Feature.ParachuteFormationFeature" },
  { ParachuteSprint = "GameLua.Mod.BaseMod.GamePlay.Feature.Parachute.ParachuteSprintFeature" },
  { GeneralShowSpotFeature = "GameLua.Mod.BRMod.Gameplay.Feature.PlayerCharacterGeneralShowSpotFeature" },
  { FPPAnimMonitor = "GameLua.Mod.BaseMod.GamePlay.Feature.Player.FPPAnimMonitorFeature" }
}, "BRPlayerCharacterBase")
