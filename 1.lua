--@Masterpiece2025

-- ============================================================================
-- 0. CORE IMPORTS
-- ============================================================================
local EPawnState   = import("EPawnState")
local GameplayData = require("GameLua.GameCore.Data.GameplayData")
local InGameMarkTools = require("GameLua.Mod.BaseMod.Common.InGameMarkTools")

-- =======================

-- ============================================================================
-- ============================================================================
_G.LexusConfig = _G.LexusConfig or {
    IpadView = false,
}
_G.LexusState = _G.LexusState or {}
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
-- 0.5. INSTANCE GUARD
-- ============================================================================
local INSTANCE_BUILD = "small-map-ready-v8"
local previousInstance = rawget(_G, "__SMALL_MAP_FIXED_INSTANCE")
if type(previousInstance) == "table" and previousInstance.build == INSTANCE_BUILD
    and previousInstance.characterClass ~= nil then
    if type(previousInstance.ResumeMaintenance) == "function" then
        pcall(previousInstance.ResumeMaintenance)
    end
    return previousInstance.characterClass
end
local CombinedInstance = {build = INSTANCE_BUILD}
_G.__SMALL_MAP_FIXED_INSTANCE = CombinedInstance

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
-- 2. LOGIN UI  (unchanged)
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
                title:SetText("OWNER @UX_Official  Online Login")
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
-- 3. WELCOME UI  (unchanged)
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
-- 4. LICENSE RUNTIME  (unchanged)
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
local EXPIRY_TIMESTAMP = os.time({year = 2026, month = 8, day = 20, hour = 0, min = 0, sec = 0})
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
-- 6. AK FEATURES
-- ============================================================================
_G.AK_Features = {
    {id = "ESP_HP",       name = "ESP Health Bar", val = 1, type = "toggle"},
    {id = "ESP_BOX",      name = "ESP Box",        val = 0, type = "toggle"},
    {id = "ESP_LINE",     name = "ESP Head Line",  val = 1, type = "toggle"},
    {id = "ENEMY_COUNT",  name = "Enemy Counter",  val = 1, type = "toggle"},
    {id = "ESP_MAP",      name = "Mini Map ESP",   val = 1, type = "toggle"},
    {id = "ESP_WALLHACK", name = "Wallhack",       val = 1, type = "toggle"},
}
function _G.AK_GetVal(featureId)
    for _, feature in ipairs(_G.AK_Features) do
        if feature.id == featureId then return feature.val end
    end
    return 0
end

-- ============================================================================
-- 6.5. BYPASS FEATURES (CharacterBase.lua থেকে সম্পূর্ণ অক্ষত)
--      Lua boolean exports bypass — CheckMD5, VerifyFileIntegrity, ইত্যাদি
--      এখন অটোমেটিক চালু হয়, কোনো মেনু টগল ছাড়াই।
-- ============================================================================
local MasterBypassFeatures = (function()
    local Bypass={}
    Bypass.__index=Bypass
    local INTERVAL=1
    local BOOLEAN_KEYS={'CheckMD5','CheckFileMD5','CheckFileIntegrity','VerifyFileIntegrity',
        'VerifyFile','VerifyAll','VerifyFileSignature','VerifySignature','slua_verify','check_slua_integrity'}
    local SUBSYSTEMS={'MD5CheckSubsystem','FileCheckSubsystem','AssetCheckSubsystem',
        'IntegrityCheckSubsystem','SignatureVerifySubsystem','PakCheckSubsystem','PakVerifySubsystem'}
    local GROUPS={
        {kind='loaded',name='common.file_hash_checker',fallback='FileHashChecker',keys={'CheckFileMD5','VerifyAll'}},
        {kind='imported',name='CreativeModeBlueprintLibrary',keys={'VerifyFileIntegrity'}},
        {kind='imported',name='STExtraBlueprintFunctionLibrary',fallback='STExtra',keys={'CheckMD5','VerifyFile'}},
        {kind='loaded',name='TssSdk',fallback='TssSdk',keys={'VerifyFileSignature','CheckIntegrity','CheckKernel','VerifyBoot'}},
        {kind='slua',name='loader',keys={'verifyBytecode','checkIntegrity'}},
        {kind='slua',name='serialize',keys={'check','verify'}},
    }
    for i=1,#SUBSYSTEMS do GROUPS[#GROUPS+1]={kind='subsystem',name=SUBSYSTEMS[i],keys=BOOLEAN_KEYS} end
    local function finite(value) return type(value)=='number' and value==value and value>-math.huge and value<math.huge end
    local function field(owner,key) return owner[key] end
    local function assign(owner,key,value) owner[key]=value end
    local function read(owner,key)
        if type(owner)~='table' then return nil end
        local ok,value=pcall(field,owner,key)
        if ok then return value end
    end
    local function exposed(value) if type(value)=='table' then return value end end
    function Bypass.new(env)
        local slots={}
        for group=1,#GROUPS do
            local keys=GROUPS[group].keys
            for i=1,#keys do slots[#slots+1]={group=group,key=keys[i]} end
        end
        return setmetatable({env=env or _G,slots=slots,settings={bypass=true},requested=true,
            enabled=false,active=false,disposed=false,nextCheck=0,lastTime=nil,
            bypassAvailable=nil,lastStatus='inactive',matchedSlots=0,
            reconcileCount=0,updating=false},Bypass)
    end
    function Bypass:_wanted() return not self.disposed end
    function Bypass:_owners()
        local result={}
        local loaded=read(read(self.env,'package'),'loaded')
        for i=1,#GROUPS do
            local group=GROUPS[i]; local owner
            if group.kind=='loaded' then owner=exposed(read(loaded,group.name)) or exposed(read(self.env,group.fallback))
            elseif group.kind=='slua' then owner=exposed(read(read(self.env,'slua'),group.name))
            elseif group.kind=='subsystem' then owner=exposed(read(self.env,group.name)) or exposed(read(loaded,group.name))
            else
                owner=exposed(read(self.env,group.name))
                if not owner then
                    local importer=read(self.env,'import')
                    if type(importer)=='function' then local ok,value=pcall(importer,group.name); if ok then owner=exposed(value) end end
                end
                if not owner and group.fallback then owner=exposed(read(self.env,group.fallback)) end
            end
            result[i]=owner
        end
        return result
    end
    function Bypass:_recordCount()
        local count=0
        for i=1,#self.slots do if self.slots[i].record then count=count+1 end end
        return count
    end
    function Bypass:_findRecord(owner,key)
        for i=1,#self.slots do
            local record=self.slots[i].record
            if record and record.owner==owner and record.key==key then return record end
        end
    end
    function Bypass:_blocked(owner,key)
        for i=1,#self.slots do
            local slot=self.slots[i]
            if slot.blockedOwner==owner and slot.key==key then return true end
        end
        return false
    end
    function Bypass:_stillBound(owners,owner,key)
        for i=1,#self.slots do
            local slot=self.slots[i]
            if slot.key==key and owners[slot.group]==owner then return true end
        end
        return false
    end
    function Bypass:_restoreSlot(slot)
        local record=slot.record
        if not record then return true end
        record.active=false
        local ok,current=pcall(field,record.owner,record.key)
        if not ok then return false end
        if current==record.wrapper then
            pcall(assign,record.owner,record.key,record.original)
            ok,current=pcall(field,record.owner,record.key)
            if not ok or current==record.wrapper then return false end
        end
        if current~=record.original then slot.blockedOwner,slot.blockReason=record.owner,'external_replacement' end
        slot.record=nil
        return true
    end
    function Bypass:_restoreAll()
        self.enabled,self.active=false,false
        for i=1,#self.slots do local record=self.slots[i].record; if record then record.active=false end end
        local restored=true
        for i=#self.slots,1,-1 do if not self:_restoreSlot(self.slots[i])then restored=false end end
        return restored
    end
    function Bypass:_stop(reason)
        local restored=self:_restoreAll()
        self.bypassAvailable=false
        self.lastStatus=restored and reason or 'restore_pending'
        return false
    end
    function Bypass:_reconcile()
        self.reconcileCount=self.reconcileCount+1
        self.enabled,self.active=false,false
        local owners=self:_owners()
        self.matchedSlots=0
        for i=1,#self.slots do
            local slot=self.slots[i]; local record=slot.record
            if record then
                local ok,current=pcall(field,record.owner,record.key)
                if not ok then return self:_stop('export_read_failed') end
                if current~=record.wrapper then
                    record.active=false; slot.record=nil
                    slot.blockedOwner,slot.blockReason=record.owner,'external_replacement'
                elseif owners[slot.group]~=record.owner then
                    if not self:_restoreSlot(slot)then return self:_stop('restore_pending') end
                end
            end
        end
        if not self:_wanted()then return self:_stop('inactive') end
        for i=1,#self.slots do
            local slot=self.slots[i]; local owner=owners[slot.group]
            if slot.blockedOwner and not self:_stillBound(owners,slot.blockedOwner,slot.key)then slot.blockedOwner,slot.blockReason=nil,nil end
            if owner and not self:_blocked(owner,slot.key)then
                local current=read(owner,slot.key)
                if type(current)=='function'then
                    self.matchedSlots=self.matchedSlots+1
                    if not self:_findRecord(owner,slot.key)then
                        local record={owner=owner,key=slot.key,original=current,active=false}
                        record.wrapper=function(...) if self.enabled and record.active and self:_wanted()then return true end; return record.original(...) end
                        slot.record=record
                        local ok=pcall(assign,owner,slot.key,record.wrapper)
                        local readOK,value=pcall(field,owner,slot.key)
                        if not ok or not readOK or value~=record.wrapper then
                            slot.blockedOwner,slot.blockReason=owner,'install_failed'
                            return self:_stop('install_failed')
                        end
                        if not self:_wanted()then return self:_stop('inactive') end
                    end
                end
            end
        end
        for i=1,#self.slots do
            local slot=self.slots[i]; local record=slot.record
            if record then
                local ok,current=pcall(field,record.owner,record.key)
                if not ok then return self:_stop('export_read_failed') end
                if current~=record.wrapper then
                    record.active=false; slot.record=nil
                    slot.blockedOwner,slot.blockReason=record.owner,'external_replacement'
                    return self:_stop('external_replacement')
                end
            end
        end
        if not self:_wanted()then return self:_stop('inactive') end
        local count=self:_recordCount()
        if count>0 then
            local currentOwners=self:_owners()
            for i=1,#self.slots do
                local slot=self.slots[i]; local record=slot.record
                if record and currentOwners[slot.group]~=record.owner then return self:_stop('binding_changed') end
            end
            if not self:_wanted()then return self:_stop('inactive') end
        end
        self.enabled=count>0
        self.active=self.enabled
        self.bypassAvailable=self.active
        for i=1,#self.slots do local record=self.slots[i].record; if record then record.active=self.enabled end end
        self.lastStatus=count==0 and 'no_lua_boolean_exports'
            or (self.matchedSlots<#self.slots and 'partial_lua_boolean_exports' or 'lua_boolean_exports_installed')
        return self.active
    end
    function Bypass:update(settings,now)
        if self.disposed or self.updating then return false end
        local previous=self.requested
        self.settings=type(settings)=='table'and settings or self.settings or {bypass=true}
        self.requested=self:_wanted()
        if not finite(now)then
            if self.enabled or not previous then return self:_stop('clock_unavailable') end
            self.lastStatus=self:_recordCount()>0 and 'restore_pending' or 'clock_unavailable'
            return false
        end
        if self.lastTime and now<self.lastTime then self.lastTime,self.nextCheck=now,now+INTERVAL; return self.active end
        self.lastTime=now
        if not previous then self.nextCheck=now end
        if now<self.nextCheck then return self.active end
        self.nextCheck=now+INTERVAL
        self.updating=true
        local ok,value=pcall(self._reconcile,self)
        self.updating=false
        if not ok then return self:_stop('reconcile_failed') end
        return value
    end
    function Bypass:dispose()
        self.disposed,self.requested,self.enabled=true,false,false
        self.settings=nil
        local restored=self:_restoreAll()
        self.bypassAvailable=false
        self.lastStatus=restored and 'disposed' or 'restore_pending'
        return restored
    end
    function Bypass:getStatus()
        local count=self:_recordCount()
        local conflicts=0
        for i=1,#self.slots do if self.slots[i].blockedOwner then conflicts=conflicts+1 end end
        local active=self.enabled and self:_wanted()and count>0
        return {enabled=self.requested,active=active,bypassAvailable=self.bypassAvailable,
            lastStatus=self.lastStatus,ownedHooks=count,installedCount=count,
            appliedHooks=active and count or 0,pendingCleanup=not active and count or 0,
            restorePending=not active and count>0,configuredSlots=#self.slots,
            matchedSlots=self.matchedSlots,blockedSlots=conflicts,reconcileCount=self.reconcileCount,
            coverage='lua_boolean_exports_only',sourceMigration='partial',
            nativeInterceptionVerified=false,serverVerification=false}
    end
    return Bypass
end)()

-- ============================================================================
-- 6.6. ANOGS BYPASS (CharacterBase.lua থেকে সম্পূর্ণ অক্ষত)
--      libanogs.so native patches + hooks
-- ============================================================================
local MasterAnogsBypass = (function()
    local SH=_G.ScriptHelperClient
    if not SH then return {ready=false,reason='ScriptHelperClient unavailable'} end
    local KNOWN_PKGS={
        ["com.tencent.ig"]="/data/app/~~2U5OPyLPSNrCp3Jhv6O4Xg==/com.tencent.ig-rxZaOzwfUVAPdioMsk4emQ==/lib/arm64/",
        ["com.pubg.krmobile"]="/data/app/~~uBLiktAOPJCRfbQA01C-3Q==/com.pubg.krmobile-nhvnm6_ClIAV0J93P86daw==/lib/arm64/",
        ["com.pubg.imobile"]="/data/app/~~p9qsLKUJYSx0V20AUx9EWg==/com.pubg.imobile-oEDhX_GaHiB7HYo8hWh0Hg==/lib/arm64/",
    }
    local function detectPackage()
        if SH.GetNativePackageTag then
            local ok,p=pcall(SH.GetNativePackageTag)
            if ok and type(p)=="string" and KNOWN_PKGS[p] then return p end
        end
        for p in pairs(KNOWN_PKGS) do return p end
        return "com.tencent.ig"
    end
    local PKG=detectPackage()
    local LIBDIR=KNOWN_PKGS[PKG] or ""
    local LIBFILE=LIBDIR.."libanogs.so"
    local APPLIED_PATCH={}
    local APPLIED_HOOK={}
    local BASE_CACHE={}
    local function kdup(lib,off) return string.format("%s@0x%X",lib,off) end
    local function getBase(lib)
        if BASE_CACHE[lib] then return BASE_CACHE[lib] end
        local b=0
        local ok,r=pcall(SH.GetPUBGModuleBaseAddr,lib)
        if ok and type(r)=="number" then b=r
        elseif ok and type(r)=="table" then b=r.base or r.addr or r[1] or 0 end
        if b==0 then
            local alt=lib:gsub("%.so$","")
            local ok2,r2=pcall(SH.GetPUBGModuleBaseAddr,alt)
            if ok2 and type(r2)=="number" then b=r2 end
        end
        BASE_CACHE[lib]=b; return b
    end
    local function hex2bin(h) return (h:gsub("%x%x",function(b)return string.char(tonumber(b,16))end)) end
    local function applyPatch(lib,off,hexbytes)
        local base=getBase(lib); local addr=base>0 and (base+off) or nil
        if SH.ProcessSoPatch and addr then
            local ok=pcall(SH.ProcessSoPatch,addr,hexbytes); if ok then return true,"P1" end
        end
        if SH.ProcessSoPatch and addr then
            local ok=pcall(SH.ProcessSoPatch,addr,hex2bin(hexbytes)); if ok then return true,"P2" end
        end
        if SH.ProcessSoPatch then
            local ok=pcall(SH.ProcessSoPatch,{{module=lib,offset=off,addr=addr,bytes=hexbytes,data=hex2bin(hexbytes)}})
            if ok then return true,"P3" end
        end
        if SH.WriteFileAtPath and SH.SetUpdatedSoPatchFile and SH.ProcessSoPatch then
            local data=string.format("%s|0x%X|%s",lib,off,hexbytes)
            local paths={"/storage/emulated/0/Android/data/"..PKG.."/files/anogs.bin",
                "/sdcard/Android/data/"..PKG.."/files/anogs.bin","/data/local/tmp/anogs.bin"}
            for _,path in ipairs(paths) do
                local okW=pcall(SH.WriteFileAtPath,path,data)
                if okW then
                    pcall(SH.SetUpdatedSoPatchFile,path)
                    local okP=pcall(SH.ProcessSoPatch)
                    if okP then return true,"P4" end
                end
            end
        end
        return false,"no-path"
    end
    local function installHook(lib,off,handler)
        local base=getBase(lib)
        if _G.__FRAMEWORK_HOOK_LIB_NO_ORIG then
            local ok=pcall(_G.__FRAMEWORK_HOOK_LIB_NO_ORIG,lib,off,handler); if ok then return true,"H1" end
        end
        if SH.InstallHook then local ok=pcall(SH.InstallHook,lib,off,handler); if ok then return true,"H2a" end end
        if SH.HookFunction then local ok=pcall(SH.HookFunction,lib,off,handler); if ok then return true,"H2b" end end
        if SH.AddHook then local ok=pcall(SH.AddHook,lib,off,handler); if ok then return true,"H2c" end end
        if SH.AllocVirMem and SH.ProcessSoPatch and base>0 then
            local slot=pcall(SH.AllocVirMem,16)
            if slot and type(slot)=="number" and slot>0 then return false,"H3-no-native-bridge" end
        end
        return false,"no-hook-api"
    end
    local function PATCH_LIB(lib,offStr,bytes)
        local off=tonumber(offStr); if not off then return end
        local k=kdup(lib,off); if APPLIED_PATCH[k] then return end
        local ok,how=applyPatch(lib,off,bytes)
        if ok then APPLIED_PATCH[k]=true
        else print(string.format("[ANOGS] patch %s @0x%X FAILED (%s)",lib,off,how)) end
    end
    local function HOOK_LIB_NO_ORIG(lib,offStr,handler)
        local off=tonumber(offStr); if not off then return end
        local k=kdup(lib,off); if APPLIED_HOOK[k] then return end
        local ok,how=installHook(lib,off,handler)
        if ok then APPLIED_HOOK[k]=true
        else print(string.format("[ANOGS] hook %s @0x%X FAILED (%s)",lib,off,how)) end
    end
    local function Master(...) return 0 end
    _G.Master=Master
    local function applyAll()
        PATCH_LIB("libanogs.so","0x2328F0","C0 03 5F D6")
        PATCH_LIB("libanogs.so","0x213360","C0 03 5F D6")
        PATCH_LIB("libanogs.so","0x2ECE70","C0 03 5F D6")
        PATCH_LIB("libanogs.so","0x4D5998","00 00 80 D2 C0 03 5F D6")
        PATCH_LIB("libanogs.so","0x4D59A4","00 00 80 D2 C0 03 5F D6")
        PATCH_LIB("libanogs.so","0x4D4DB4","00 00 80 D2 C0 03 5F D6")
        PATCH_LIB("libanogs.so","0x4D4DD0","00 00 80 D2 C0 03 5F D6")
        PATCH_LIB("libanogs.so","0x4D571C","00 00 80 D2 C0 03 5F D6")
        PATCH_LIB("libanogs.so","0x4D5748","00 00 80 D2 C0 03 5F D6")
        HOOK_LIB_NO_ORIG("libanogs.so","0x371418",Master)
        HOOK_LIB_NO_ORIG("libanogs.so","0x431800",Master)
        HOOK_LIB_NO_ORIG("libanogs.so","0x39F56C",Master)
        HOOK_LIB_NO_ORIG("libanogs.so","0x3A564C",Master)
    end
    applyAll()
    return {ready=true,pkg=PKG,libfile=LIBFILE,
        applied_patch=APPLIED_PATCH,applied_hook=APPLIED_HOOK,
        PATCH_LIB=PATCH_LIB,HOOK_LIB_NO_ORIG=HOOK_LIB_NO_ORIG}
end)()
_G.__MasterAnogsBypass = MasterAnogsBypass

-- ============================================================================
-- 6.7. ULTIMATE DETECTION BYPASS (CharacterBase.lua থেকে সম্পূর্ণ অক্ষত)
--      Scene proxy / mesh / material / subsystem / network / file  — সব bypass
-- ============================================================================
local function installUltimateDetectionBypass()
    if _G.__MASTER_ULTIMATE_BYPASS then return end
    local nop=function() end
    local retTrue=function() return true end
    local retFalse=function() return false end
    local function active() return _G._WHA_BYPASS_ACTIVE and not _G._MOD_EXPIRED end
    pcall(function()
        local P=import("PrimitiveSceneProxy")
        if P and P.GetViewRelevance then
            local orig=P.GetViewRelevance
            P.GetViewRelevance=function(s,V)
                local VR=orig(s,V)
                if active() and VR then
                    VR.bRenderCustomDepth=false
                    VR.bUsesSceneDepth=false
                end
                return VR
            end
        end
    end)
    pcall(function()
        local M=import("MeshComponent")
        if M then
            M.__grd=M.GetRenderCustomDepth
            M.GetRenderCustomDepth=function(s) if not active() then return M.__grd(s) end return false end
            M.__ircd=M.IsRenderedOnCustomDepth
            M.IsRenderedOnCustomDepth=function(s) if not active() then return M.__ircd(s) end return false end
            M.__gcdsv=M.GetCustomDepthStencilValue
            M.GetCustomDepthStencilValue=function(s) if not active() then return M.__gcdsv(s) end return 0 end
            M.__sr=M.ShouldRender
            M.ShouldRender=function(s) if not active() then return M.__sr(s) end return true end
        end
        local P=import("PrimitiveComponent")
        if P then
            for _,fn in ipairs({"IsRenderedOnCustomDepth","GetRenderCustomDepth",
                "GetCustomDepthStencilValue","GetCustomDepthStencilWriteMask",
                "GetVisibleFlag"}) do
                local orig=P[fn]
                P["__o_"..fn]=orig
                local vf=(fn=="GetVisibleFlag")
                local sf=(fn=="GetCustomDepthStencilValue")
                P[fn]=function(s,...)
                    if not active() then return orig(s,...) end
                    if vf then return true end
                    if sf then return 0 end
                    return false
                end
            end
        end
    end)
    pcall(function()
        local M=import("Material")
        local MI=import("MaterialInstance")
        local MD=import("MaterialInstanceDynamic")
        if M then
            M.__ddt=M.GetDisableDepthTest
            M.GetDisableDepthTest=function(s) if not active() then return M.__ddt(s) end return false end
            M.__bm=M.GetBlendMode
            M.GetBlendMode=function(s) if not active() then return M.__bm(s) end return 0 end
            M.__mh=M.GetMaterialHash
            M.GetMaterialHash=function(s) if not active() then return M.__mh(s) end return "FAKE_HASH" end
        end
        if MI then
            MI.__ddt=MI.GetDisableDepthTest
            MI.GetDisableDepthTest=function(s) if not active() then return MI.__ddt(s) end return false end
            MI.__bm=MI.GetBlendMode
            MI.GetBlendMode=function(s) if not active() then return MI.__bm(s) end return 0 end
        end
        if MD then
            local oV=MD.K2_GetVectorParameterValue
            MD.K2_GetVectorParameterValue=function(s,n)
                if not active() then return oV(s,n) end
                local k=tostring(n or "")
                if k:find("Color") or k:find("Emissive") or k:find("Tint") then
                    return {R=255,G=255,B=255,A=255}
                end
                return oV(s,n)
            end
        end
    end)
    pcall(function()
        local SM=require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if SM then
            local kc=SM:Get("ClientKernelCheckSubsystem")
            if kc and not kc.__master then
                kc.__okc=kc.IsKernelClean
                kc.IsKernelClean=function(s) if not active() then return kc.__okc(s) end return true,{code=0} end
                kc.__okv=kc.GetKernelVersion
                kc.GetKernelVersion=function(s) if not active() then return kc.__okv(s) end return "5.4.0-generic" end
                kc.__master=true
            end
            local mg=SM:Get("ClientMemoryGuardSubsystem")
            if mg and not mg.__master then
                mg.__omc=mg.IsMemoryClean
                mg.IsMemoryClean=function(s) if not active() then return mg.__omc(s) end return true,{code=0} end
                mg.__osr=mg.ScanResult
                mg.ScanResult=function(s) if not active() then return mg.__osr(s) end return "clean" end
                mg.__master=true
            end
        end
    end)
   
    pcall(function()
        if _G.TssSdk then
            _G.TssSdk.GetFileMD5=function() return "7b1c7b5608da3083097816106fc331f9" end
            _G.TssSdk.VerifyFileSignature=retTrue
            _G.TssSdk.CheckIntegrity=retTrue
            _G.TssSdk.ScanMemory=function() return true,{} end
            _G.TssSdk.IsEmulator=retFalse
        end
        if _G.IsDebuggerPresent then _G.IsDebuggerPresent=retFalse end
        local F=import("FFileHelper")
        if F and F.GetFileSize then
            local orig=F.GetFileSize
            F.GetFileSize=function(p)
                if active() and p and tostring(p):lower():match("%.pak") then return 2000000000 end
                return orig(p)
            end
        end
    end)
    pcall(function()
        if NetUtil and NetUtil.SendPacket and not NetUtil._masterBlocked then
            local orig=NetUtil.SendPacket
            NetUtil.SendPacket=function(pname,...)
                if active() and pname then
                    local l=tostring(pname):lower()
                    if l:match("report") or l:match("flow") or l:match("tlog")
                        or l:match("cheat") or l:match("security") or l:match("integrity")
                        or l:match("md5") or l:match("hash") or l:match("esp")
                        or l:match("heartbeat") or l:match("crash") then
                        return nil
                    end
                end
                return orig(pname,...)
            end
            NetUtil._masterBlocked=true
        end
    end)
    _G.__MASTER_ULTIMATE_BYPASS=true
    print("[RedCyan] Ultimate detection bypass installed")
end

installUltimateDetectionBypass()

-- ============================================================================
-- 7. ESP BOX RENDERER  (0.02s timer) — HP + Distance + Head Line + Counter
-- ============================================================================
local ESPBoxRenderer = (function()
    local M = {}
    local FVector2D    = _G.FVector2D or import("Vector2D")
    local FLinearColor = _G.FLinearColor or import("LinearColor")
    local SlateBlueprintLibrary = nil
    local WidgetLayoutLibrary   = nil
    pcall(function() SlateBlueprintLibrary = import("SlateBlueprintLibrary") end)
    pcall(function() WidgetLayoutLibrary   = import("WidgetLayoutLibrary")   end)

    M.BoxThickness   = 1.5
    M.BoxWidthFactor = 0.40
    M.RealStrokeColor = (FLinearColor and FLinearColor(1.0, 0.0, 0.0, 0.96)) or {R=1.0, G=0.0, B=0.0, A=0.96}
    M.BotStrokeColor  = (FLinearColor and FLinearColor(0.0, 1.0, 1.0, 0.96)) or {R=0.0, G=1.0, B=1.0, A=0.96}
    M.RealTheme = {Key = "REAL", Stroke = M.RealStrokeColor}
    M.BotTheme  = {Key = "BOT",  Stroke = M.BotStrokeColor}

    M.ESPCanvas = nil
    M.BoxWidgets = {}
    M._CanvasScaleX, M._CanvasScaleY = 1.0, 1.0
    M._CanvasOffsetX, M._CanvasOffsetY = 0.0, 0.0
    M._CachedPC = nil
    M._CapsuleCache = setmetatable({}, {__mode = "k"})
    M._AITypeCache = {}
    M._AITypeRetryAt = {}
    M._Timer, M._TimerOwner, M._Active = nil, nil, false
    M._TickInterval = 0.02
    M._LastWorld = nil

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
                if slua_GameFrontendHUD then
                    PC = slua_GameFrontendHUD:GetPlayerController()
                end
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
        pcall(function()
            InGameUITools = require("GameLua.Mod.BaseMod.Common.UI.InGameUITools")
        end)
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
                    if pt0 and pt1 and type(pt0.X) == "number" and type(pt1.X) == "number"
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
                    if type(c) == "number" and c == c and c > 0 and c < math.huge then
                        scale = c
                    end
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
        if not Center then
            pcall(function()
                if Game and Game.GetActorLocation then Center = Game:GetActorLocation(Character) end
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
        return {X = Center.X, Y = Center.Y, Z = Center.Z + HalfHeight},
               {X = Center.X, Y = Center.Y, Z = Center.Z - HalfHeight}
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
        local function readFlag(o, n) pcall(function() accept(o[n]) end) end
        local function callFlag(o, n)
            pcall(function()
                local m = o and o[n]
                if type(m) == "function" then accept(m(o)) end
            end)
        end
        pcall(function() if Game and Game.IsAI then accept(Game:IsAI(Character)) end end)
        if not bAI then readFlag(Character, "bIsAI") end
        if not bAI then readFlag(Character, "IsAI") end
        if not bAI then callFlag(Character, "IsBot") end
        if not bAI then
            local ps = nil
            pcall(function()
                if Character.GetPlayerStateSafety then ps = Character:GetPlayerStateSafety()
                elseif Character.GetPlayerState then ps = Character:GetPlayerState()
                elseif Character.PlayerState then ps = Character.PlayerState end
            end)
            if ps and IsValid(ps) then
                readFlag(ps, "bIsABot")
                if not bAI then readFlag(ps, "bIsBot") end
                if not bAI then readFlag(ps, "bIsAI") end
                if not bAI then callFlag(ps, "IsBot") end
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
        pcall(function()
            Border:SetRenderTransformPivot(FVector2D and FVector2D(0.0, 0.5) or {X=0, Y=0.5})
        end)
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
                    return M.CallUISetter(ld.Widget, 'SetWidgetVisibility',
                        UEnums.ESlateVisibility.Collapsed)
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
        if not _G.AK_GetVal or _G.AK_GetVal("ESP_BOX") ~= 1 then
            M.RemoveBox(KeyStr); return
        end
        local box = M.BoxWidgets[KeyStr]
        local boxH = bOnScreen and headCanvas and feetCanvas
            and (feetCanvas.Y - headCanvas.Y) or nil
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
        if not box then
            box = {_buildIndex = 1}
            M.BoxWidgets[KeyStr] = box
        end
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

    local function Tick()
        if not M._Active then return end
        if not CheckExpiration() then return end
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
-- Top-center origin for head lines (canvas space) — FIXED
-- ============================================================
local topOrigin = nil
if _G.AK_GetVal and _G.AK_GetVal("ESP_LINE") == 1 then
    local vpW = nil
    pcall(function()
        local s = FVector2D and FVector2D(0,0) or {X=0,Y=0}
        pc:GetViewportSize(s)
        if s and type(s.X) == "number" and s.X > 200 then vpW = s.X end
    end)
    if not vpW and WidgetLayoutLibrary and WidgetLayoutLibrary.GetViewportSize then
        pcall(function()
            local s = WidgetLayoutLibrary.GetViewportSize(pc)
            if s and type(s.X) == "number" and s.X > 200 then vpW = s.X end
        end)
    end
    if vpW then
        local sx = M._CanvasScaleX or 1.0
        local ox = M._CanvasOffsetX or 0
        local oy = M._CanvasOffsetY or 0
        local tx = (vpW * 0.5) * sx + ox
        local ty = 0 * (M._CanvasScaleY or 1.0) + oy
        if type(tx) == "number" and type(ty) == "number"
            and tx == tx and ty == ty
            and tx > -10000 and tx < 10000
            and ty > -10000 and ty < 10000 then
            topOrigin = { X = tx, Y = ty }
        end
    end
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

        -- ✅ STRONG ALIVE CHECK
        local alive = true
        pcall(function()
            if type(enemy.IsDead) == "function" and enemy:IsDead() then alive = false end
            if enemy.bIsDead or enemy.bIsDeadFlag or enemy.bDead then alive = false end
            if enemy.bHidden or (enemy.Mesh and enemy.Mesh.bHidden) then alive = false end
            if enemy.GetHealth and enemy:GetHealth() <= 0 then alive = false end
            if enemy.HasPawnState and EPawnState and EPawnState.Dead then
                local ok, dead = pcall(enemy.HasPawnState, enemy, EPawnState.Dead)
                if ok and dead then alive = false end
            end
            if enemy.bNearDeath then alive = false end
            local ps = (enemy.GetPlayerStateSafety and enemy:GetPlayerStateSafety())
                or enemy.PlayerState
            if ps and (ps.bIsDead or ps.bIsTombBox) then alive = false end
        end)

        -- ✅ Key hamesha banao (dead ho ya alive)
        local key = tostring(enemy.PlayerKey or enemy)

        if not alive then
            -- ✅ Dead enemy ke saare widgets turant hata do
            M.RemoveBox(key)
            if _G.ESPHealthRenderer then pcall(_G.ESPHealthRenderer.Remove, key) end
            if _G.ESPDistanceRenderer then pcall(_G.ESPDistanceRenderer.Remove, key) end
            if _G.ESPLineRenderer then pcall(_G.ESPLineRenderer.Remove, key) end
        else
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

            -- ✅ Strict validation: headCanvas valid numeric hona chahiye
            if bHeadOK and headCanvas then
                if type(headCanvas.X) ~= "number" or type(headCanvas.Y) ~= "number"
                    or headCanvas.X ~= headCanvas.X or headCanvas.Y ~= headCanvas.Y
                    or headCanvas.X < -5000 or headCanvas.X > 5000
                    or headCanvas.Y < -5000 or headCanvas.Y > 5000 then
                    bHeadOK = false
                    headCanvas = nil
                end
            end

            local bOnScreen = bHeadOK and bFeetOK
            local bIsAI = M.IsAI(enemy, key)
            if bIsAI then botCount = botCount + 1 else realCount = realCount + 1 end

            M.UpdateBox(key, headCanvas, feetCanvas, bOnScreen, bIsAI)

            if _G.AK_GetVal and _G.AK_GetVal("ESP_HP") == 1
                and _G.ESPHealthRenderer and _G.ESPHealthRenderer.Update then
                pcall(_G.ESPHealthRenderer.Update, key, feetCanvas, headCanvas, enemy, bOnScreen, bIsAI)
            end

            if _G.AK_GetVal and _G.AK_GetVal("ESP_MAP") == 1
                and _G.ESPDistanceRenderer and _G.ESPDistanceRenderer.Update then
                pcall(_G.ESPDistanceRenderer.Update, key, feetCanvas, feetLoc, myLoc, bOnScreen)
            end

            -- ✅ Strict check: line sirf tab draw karo jab sab valid ho
            if topOrigin and _G.ESPLineRenderer and _G.ESPLineRenderer.Update
                and bOnScreen and headCanvas and headCanvas.X and headCanvas.Y then
                pcall(_G.ESPLineRenderer.Update, key, headCanvas, topOrigin, bOnScreen, bIsAI, false)
            else
                if _G.ESPLineRenderer then pcall(_G.ESPLineRenderer.Remove, key) end
            end
        end
    end
end

        if _G.AK_GetVal and _G.AK_GetVal("ENEMY_COUNT") == 1
            and _G.EnemyCounterOverlay then
            if _G.EnemyCounterOverlay.Create() then
                _G.EnemyCounterOverlay.UpdatePosition(pc)
                _G.EnemyCounterOverlay.SetCounts(realCount, botCount)
            end
        elseif _G.EnemyCounterOverlay then
            _G.EnemyCounterOverlay.Hide()
        end

        local stale = {}
        for k in pairs(M.BoxWidgets) do
            if not seen[k] then stale[#stale + 1] = k end
        end
        for _, k in ipairs(stale) do
            M.RemoveBox(k)
            if _G.ESPHealthRenderer then pcall(_G.ESPHealthRenderer.Remove, k) end
            if _G.ESPDistanceRenderer then pcall(_G.ESPDistanceRenderer.Remove, k) end
            if _G.ESPLineRenderer then pcall(_G.ESPLineRenderer.Remove, k) end
        end
    end
    local function EnsureWorldCache()
        local world = nil
        pcall(function() world = slua and slua.getWorld and slua.getWorld() end)
        if world ~= M._LastWorld then
            M._LastWorld = world
            M.ClearAllBoxes()
            if _G.ESPHealthRenderer then pcall(_G.ESPHealthRenderer.ClearAll) end
            if _G.ESPDistanceRenderer then pcall(_G.ESPDistanceRenderer.ClearAll) end
            if _G.ESPLineRenderer then pcall(_G.ESPLineRenderer.ClearAll) end
            if _G.EnemyCounterOverlay then pcall(_G.EnemyCounterOverlay.Destroy) end
            M._CapsuleCache = setmetatable({}, {__mode = "k"})
            M._AITypeCache = {}
            M._AITypeRetryAt = {}
            M._CachedPC = nil
            M.ESPCanvas = nil
        end
    end

    function M.Start()
        if M._Active then return true end
        local owner = nil
        pcall(function()
            if GameplayData and GameplayData.GetPlayerController then
                owner = GameplayData.GetPlayerController()
            end
        end)
        if not IsValid(owner) then
            pcall(function()
                if slua_GameFrontendHUD then
                    owner = slua_GameFrontendHUD:GetPlayerController()
                end
            end)
        end
        if not IsValid(owner) or type(owner.AddGameTimer) ~= "function" then
            return false
        end
        EnsureWorldCache()
        M._Active = true
        local ok, timer = pcall(function()
            return owner:AddGameTimer(M._TickInterval, true, function()
                EnsureWorldCache()
                Tick()
            end)
        end)
        if not ok or not timer then M._Active = false; return false end
        M._Timer, M._TimerOwner = timer, owner
        print("[ESP-Box] Started at 0.02s")
        return true
    end

    function M.Stop()
        M._Active = false
        if M._Timer and M._TimerOwner
            and type(M._TimerOwner.RemoveGameTimer) == "function" then
            pcall(function() M._TimerOwner:RemoveGameTimer(M._Timer) end)
        end
        M._Timer, M._TimerOwner = nil, nil
        M.ClearAllBoxes()
        if _G.ESPHealthRenderer then pcall(_G.ESPHealthRenderer.ClearAll) end
        if _G.ESPDistanceRenderer then pcall(_G.ESPDistanceRenderer.ClearAll) end
        if _G.ESPLineRenderer then pcall(_G.ESPLineRenderer.ClearAll) end
        if _G.EnemyCounterOverlay then pcall(_G.EnemyCounterOverlay.Destroy) end
    end

    function M.IsActive() return M._Active end
    _G.ESPBoxRenderer = M
    return M
end)()

-- ============================================================================
-- 7A. HP BAR RENDERER (Canvas-based)
-- ============================================================================
local ESPHealthRenderer = (function()
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
        if not _G.AK_GetVal or _G.AK_GetVal("ESP_HP") ~= 1 then M.Remove(key) return end
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

-- ============================================================================
-- 7B. DISTANCE LABEL RENDERER (Canvas-based)
-- ============================================================================
local ESPDistanceRenderer = (function()
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
        if not _G.AK_GetVal or _G.AK_GetVal("ESP_MAP") ~= 1 then M.Remove(key) return end
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

-- ============================================================================
-- 7C. ESP HEAD LINE RENDERER (Canvas-based, top-center → enemy head)
-- ============================================================================
local ESPLineRenderer = (function()
    local M = {}
    local FLinearColor = _G.FLinearColor or import("LinearColor")

    M.Thickness = 1.5
    M.Lines = {}
    M.RealColor = (FLinearColor and FLinearColor(1.0, 0.15, 0.15, 0.92)) or {R=1.0, G=0.15, B=0.15, A=0.92}
    M.BotColor  = (FLinearColor and FLinearColor(0.0, 1.0, 1.0, 0.92)) or {R=0.0, G=1.0, B=1.0, A=0.92}

    local function WValid(w)
        if not w then return false end
        local ok, v = pcall(function() return slua.isValid(w) end)
        return ok and v == true
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
    end

            function M.Update(key, headCanvas, topOriginCanvas, onScreen, isAI, isDead)
        if not _G.AK_GetVal or _G.AK_GetVal("ESP_LINE") ~= 1 then
            M.Remove(key); return
        end
        if isDead == true then
            M.Remove(key); return
        end
        if not onScreen then M.Remove(key); return end
        if not headCanvas or not topOriginCanvas then M.Remove(key); return end

        local hx, hy = headCanvas.X, headCanvas.Y
        local ox, oy = topOriginCanvas.X, topOriginCanvas.Y

        if type(hx) ~= "number" or type(hy) ~= "number"
            or hx ~= hx or hy ~= hy
            or hx < -5000 or hx > 5000
            or hy < -5000 or hy > 5000 then
            M.Remove(key); return
        end
        if type(ox) ~= "number" or type(oy) ~= "number"
            or ox ~= ox or oy ~= oy
            or ox < -5000 or ox > 5000
            or oy < -5000 or oy > 5000 then
            M.Remove(key); return
        end

        local ddx, ddy = hx - ox, hy - oy
        if math.sqrt(ddx*ddx + ddy*ddy) < 5 then
            M.Remove(key); return
        end

        local ld = M.Lines[key]
        if not ld then
            ld = ESPBoxRenderer.CreateLineWidget(
                isAI and M.BotColor or M.RealColor, 1)
            if not ld then return end
            ld._colorKey = isAI and "BOT" or "REAL"
            M.Lines[key] = ld
        end
        local newKey = isAI and "BOT" or "REAL"
        if ld._colorKey ~= newKey then
            local c = isAI and M.BotColor or M.RealColor
            pcall(function() ld.Widget:SetBrushColor(c) end)
            ld._colorKey = newKey
        end
        ESPBoxRenderer.DrawLine(ld, ox, oy, hx, hy, M.Thickness)
    end

    _G.ESPLineRenderer = M
    return M
end)()

-- ============================================================================
-- 7D. ENEMY / BOT COUNTER OVERLAY (Canvas-based, top-center)
-- ============================================================================
local EnemyCounterOverlay = (function()
    local M = {}
    local FVector2D    = _G.FVector2D or import("Vector2D")
    local FLinearColor = _G.FLinearColor or import("LinearColor")
    local WidgetLayoutLibrary = nil
    pcall(function() WidgetLayoutLibrary = import("WidgetLayoutLibrary") end)

    M.Width, M.Height = 240.0, 26.0
    M.OffsetY = 50.0
    M.FontSize = 12
    M.PlayerBG = (FLinearColor and FLinearColor(0.85, 0.05, 0.05, 0.96)) or {R=0.85,G=0.05,B=0.05,A=0.96}
    M.BotBG    = (FLinearColor and FLinearColor(0.0, 1.0, 1.0, 0.96)) or {R=0.0,G=1.0,B=1.0,A=0.96}
    M.PlayerTextColor = (FLinearColor and FLinearColor(0.0, 1.0, 1.0, 1.0)) or {R=0.0,G=1.0,B=1.0,A=1.0}
    M.BotTextColor    = (FLinearColor and FLinearColor(0.0, 0.0, 0.0, 1.0)) or {R=0.0,G=0.0,B=0.0,A=1.0}
    M.Container, M.Slot = nil, nil
    M.PlayerBGWidget, M.BotBGWidget = nil, nil
    M.PlayerText, M.BotText = nil, nil
    M._LastPlayers, M._LastBots = -1, -1
    M._LastX, M._LastY = nil, nil

    local function WValid(w)
        if not w then return false end
        local ok, v = pcall(function() return slua.isValid(w) end)
        return ok and v == true
    end

    function M.Create()
        if M.Container and WValid(M.Container) then return true end
        if not ESPBoxRenderer or not ESPBoxRenderer.InitESPCanvas then return false end
        if not ESPBoxRenderer.InitESPCanvas() then return false end
        local parent = ESPBoxRenderer.ESPCanvas
        if not parent or not WValid(parent) then return false end

        local c, pbg, bbg, pt, bt
        pcall(function() c   = CGame:NewObjectFromPath("/Script/UMG.CanvasPanel", parent) end)
        if not c or not WValid(c) then return false end
        pcall(function() pbg = CGame:NewObjectFromPath("/Script/UMG.Border", c) end)
        pcall(function() bbg = CGame:NewObjectFromPath("/Script/UMG.Border", c) end)
        pcall(function() pt  = CGame:NewObjectFromPath("/Script/UMG.TextBlock", c) end)
        pcall(function() bt  = CGame:NewObjectFromPath("/Script/UMG.TextBlock", c) end)
        if not pbg or not bbg or not pt or not bt then
            pcall(function() c:ConditionalBeginDestroy() end)
            return false
        end

        local halfW = M.Width * 0.5
        local ok = pcall(function()
            pbg:SetBrushColor(M.PlayerBG)
            pbg:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
            bbg:SetBrushColor(M.BotBG)
            bbg:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)

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

            pt:SetText("PLAYER: 0")
            bt:SetText("BOT: 0")
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
        M._LastPlayers, M._LastBots = -1, -1
        M._LastX, M._LastY = nil, nil

        pcall(function()
            local SlateColor
            pcall(function() SlateColor = import("SlateColor") end)
            if SlateColor then
                pt:SetColorAndOpacity(SlateColor(M.PlayerTextColor))
                bt:SetColorAndOpacity(SlateColor(M.BotTextColor))
            else
                pt:SetColorAndOpacity(M.PlayerTextColor)
                bt:SetColorAndOpacity(M.BotTextColor)
            end
        end)
        return true
    end

    function M.SetCounts(realCount, botCount)
        realCount = tonumber(realCount) or 0
        botCount  = tonumber(botCount)  or 0
        if M._LastPlayers ~= realCount and WValid(M.PlayerText) then
            local ok = pcall(function()
                return M.PlayerText:SetText(string.format("PLAYER: %d", realCount)) ~= false
            end)
            if ok then M._LastPlayers = realCount end
        end
        if M._LastBots ~= botCount and WValid(M.BotText) then
            local ok = pcall(function()
                return M.BotText:SetText(string.format("BOT: %d", botCount)) ~= false
            end)
            if ok then M._LastBots = botCount end
        end
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
        pcall(function()
            M.Slot:SetPosition(FVector2D and FVector2D(x,y) or {X=x,Y=y})
        end)
        M._LastX, M._LastY = x, y
    end

    function M.Hide()
        if WValid(M.Container) then
            pcall(function()
                M.Container:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
            end)
        end
    end

    function M.Destroy()
        local c = M.Container
        M.Container, M.Slot = nil, nil
        M.PlayerBGWidget, M.BotBGWidget = nil, nil
        M.PlayerText, M.BotText = nil, nil
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

-- ============================================================================
-- 8. WALLHACK RENDERER  (0.5s timer)  (unchanged)
-- ============================================================================
local WallhackRenderer = (function()
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
        RealVisible  = FLinearColor and FLinearColor(0, 100, 0, 100) or {R=0, G=100, B=0, A=100},
        RealOccluded = FLinearColor and FLinearColor(100, 0, 0, 100) or {R=100, G=0, B=0, A=100},
        BotVisible = FLinearColor and FLinearColor(100, 100, 100, 100) or {R=100, G=100, B=100, A=100},
        BotOccluded = FLinearColor and FLinearColor(100, 100, 0, 100) or {R=100, G=100, B=0, A=100},
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
        pcall(function()
            local ST = import("StaticMeshComponent")
            if ST then
                local comps = pawn:GetComponentsByClass(ST)
                if comps then
                    for i = 0, comps:Num() - 1 do
                        local comp = comps:Get(i)
                        if slua.isValid(comp) then table.insert(meshes, comp) end
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
        if not CheckExpiration() then return end
        if not _G.AK_GetVal or _G.AK_GetVal("ESP_WALLHACK") ~= 1 then return end

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
                if not slua.isValid(pawn) then
                    M.ProcessedPawns[key] = nil
                else
                    local dead = false
                    pcall(function()
                        if pawn:IsDead() or pawn.bIsDead or pawn.bHidden
                            or (pawn.Mesh and pawn.Mesh.bHidden) then
                            dead = true
                        end
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
                        if not M.ProcessedPawns[key] then
                            M.ProcessedPawns[key] = {pawn = pawn}
                        end
                        local isAI = ESPBoxRenderer and ESPBoxRenderer.IsAI(pawn, key) or false
                        local vis = isAI and M.Colors.BotVisible or M.Colors.RealVisible
                        local occ = isAI and M.Colors.BotOccluded or M.Colors.RealOccluded
                        local meshes = CollectAllMeshes(pawn)
                        for _, m in ipairs(meshes) do
                            ApplyToMesh(m, vis, occ)
                        end
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
        local ok, timer = pcall(function()
            return owner:AddGameTimer(M.TickInterval, true, Tick)
        end)
        if not ok or not timer then M.Active = false; return false end
        M.Timer, M.TimerOwner = timer, owner
        pcall(Tick)
        print("[Wallhack] Started at 0.5s")
        return true
    end

    function M.Stop()
        M.Active = false
        if M.Timer and M.TimerOwner
            and type(M.TimerOwner.RemoveGameTimer) == "function" then
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

-- ============================================================================
-- 9. DISTANCE MARKER & MINI-MAP ESP (native — kept as secondary path)
-- ============================================================================
local distanceMarkerConfig = {
    UIPathName = "/Game/Mod/EvoBase/BluePrints/UIBP/QuickSign/QuickSign_TipHitEnemy_UIBP_New.QuickSign_TipHitEnemy_UIBP_New_C",
    MaxWidgetNum = 99, MaxShowDistance = 6000000,
    bBindOutScreen = true, bBindBlocked = true, bIsBindingActor = true,
    BindSocketName = "head", bUseLuaWorldSocketName = true,
    WorldPositionOffset = FVector(0, 0, 50), bNeedPreLoad = true, Priority = 2
}

local function InitDistanceMarkerSystem()
    pcall(function()
        if InGameMarkTools and InGameMarkTools.ScreenMarkManager
            and InGameMarkTools.ScreenMarkManager.OnInitMarkGroupData then
            InGameMarkTools.ScreenMarkManager:OnInitMarkGroupData(9999)
        end
        local gameplayTools = require("GameLua.Mod.BaseMod.Common.GamePlayTools")
        local smc = gameplayTools.GetCurrentConfig("ScreenMarkConfig")
        if smc then
            if not smc[1006] then
                smc[1006] = {
                    UIPathName = distanceMarkerConfig.UIPathName,
                    MaxWidgetNum = 99,
                    MaxShowDistance = 6000000,
                    bBindOutScreen = true,
                    bBindBlocked = true,
                    bIsBindingActor = true,
                    BindSocketName = "head",
                    bUseLuaWorldSocketName = true,
                    WorldPositionOffset = FVector(0, 0, 50),
                    bNeedPreLoad = true,
                    Priority = 2,
                }
            else
                smc[1006].bBindBlocked = true
                smc[1006].bBindOutScreen = true
                smc[1006].MaxWidgetNum = 99
                smc[1006].MaxShowDistance = 6000000
            end
            smc[9999] = distanceMarkerConfig
        end
        for name, data in pairs(package.loaded) do
            if type(name) == "string" and string.find(name, "ScreenMarkConfig")
                and type(data) == "table" then
                data[1006] = data[1006] or smc and smc[1006]
                data[9999] = distanceMarkerConfig
            end
        end
    end)
end

if not _G.AK_Active_Marks_Cache then _G.AK_Active_Marks_Cache = {} end

local function createDistanceMarker(enemy)
    if _G._MOD_EXPIRED then return end
    pcall(function()
        if InGameMarkTools and InGameMarkTools.ClientAddMapMark then
            enemy.NativeDistMark = InGameMarkTools.ClientAddMapMark(9999, FVector(0,0,0), 0, "", 4, enemy)
            _G.AK_Active_Marks_Cache[tostring(enemy)] = {actor = enemy, distMark = enemy.NativeDistMark}
        end
    end)
end

local function removeDistanceMarker(enemy)
    pcall(function()
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
        if not slua.isValid(data.actor) then
            remove = true
        else
            pcall(function()
                local a = data.actor
                if a.bHidden or (a.Mesh and a.Mesh.bHidden) then remove = true end
                if type(a.IsDead) == "function" and a:IsDead() then remove = true
                elseif a.bIsDead == true or a.bIsDeadFlag == true then remove = true end
                if not remove then
                    if a.GetHealth and a:GetHealth() <= 0 then remove = true
                    elseif a.HasPawnState and a:HasPawnState(EPawnState.Dead) then remove = true end
                end
            end)
        end
        if remove then
            pcall(function()
                if InGameMarkTools and InGameMarkTools.ClientRemoveMapMark then
                    InGameMarkTools.ClientRemoveMapMark(data.distMark)
                end
            end)
            _G.AK_Active_Marks_Cache[key] = nil
        end
    end
end

local function processEnemyMapESP(enemy, localPlayer, isMapESPEnabled)
    if _G._MOD_EXPIRED then return end
    if not slua.isValid(enemy) or enemy == localPlayer or enemy.TeamID == localPlayer.TeamID then return end
    local isDead = false
    pcall(function()
        if type(enemy.IsDead) == "function" and enemy:IsDead() then isDead = true
        elseif enemy.bIsDead then isDead = true end
        if enemy.bHidden or (enemy.Mesh and enemy.Mesh.bHidden) then isDead = true end
        if not isDead then
            if enemy.GetHealth and enemy:GetHealth() <= 0 then isDead = true
            elseif enemy.HasPawnState and enemy:HasPawnState(EPawnState.Dead) then isDead = true end
        end
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
                    if slua.isValid(currentWep) and type(currentWep.StartFire) == "function" then 
                        currentWep:StartFire() 
                    end
                    _G.LexusState.IsAutoFiring = true
                end
            end)
        end

    end)
end

local function g_rayansyed77_iPadViewTick()
    g_rayansyed77_ApplyiPadView()
    local okTicker, ticker = pcall(require, "common.time_ticker")
    if okTicker and ticker and ticker.AddTimerOnce then
        ticker.AddTimerOnce(5.0, g_rayansyed77_iPadViewTick)
    end
end
g_rayansyed77_iPadViewTick()
-- ============================================================================
-- 11. LICENSE BOOTSTRAP
-- ============================================================================
local function masterESPEnsureLicense()
    if masterESPLicenseInstance then return end
    local host = setmetatable({GameplayData = GameplayData}, {__index = _ENV})
    masterESPLicenseInstance = MasterLicenseRuntime.new(
        host, MasterLicenseConfig, MasterLicenseCore, MasterLoginUI)
end

-- ============================================================================
-- 12. READINESS SYSTEM
-- ============================================================================
local MatchState = {
    ready = false,
    readySince = nil,
    world = nil,
    lastError = nil,
    attempts = 0,
    renderersStarted = false,
}

local _GameplayStatics = nil
local function EngineTime()
    local world = nil
    pcall(function() world = slua and slua.getWorld and slua.getWorld() end)
    if not world then return nil, nil end
    if not _GameplayStatics then
        pcall(function() _GameplayStatics = import("GameplayStatics") end)
    end
    if not _GameplayStatics then return nil, world end
    local now = nil
    pcall(function()
        if _GameplayStatics.GetRealTimeSeconds then
            now = _GameplayStatics.GetRealTimeSeconds(world)
        end
    end)
    if type(now) == "number" and now == now and now >= 0 and now < math.huge then
        return now, world
    end
    return nil, world
end

local function StopAllRenderers()
    pcall(function() if ESPBoxRenderer then ESPBoxRenderer.Stop() end end)
    pcall(function() if WallhackRenderer then WallhackRenderer.Stop() end end)
    pcall(function() if ESPLineRenderer then ESPLineRenderer.ClearAll() end end)
    pcall(function() if EnemyCounterOverlay then EnemyCounterOverlay.Destroy() end end)
    MatchState.renderersStarted = false
end

local function StartAllRenderers()
    if MatchState.renderersStarted then return true end
    local anyOK = false

    local ok1 = pcall(function()
        if ESPBoxRenderer then
            if ESPBoxRenderer.Start() == true then anyOK = true end
        end
    end)

    local ok2 = pcall(function()
        if WallhackRenderer then
            if WallhackRenderer.Start() == true then anyOK = true end
        end
    end)

    pcall(function()
        if ESPHealthRenderer and ESPHealthRenderer.InitCanvas then
            ESPHealthRenderer.InitCanvas(true)
        end
    end)

    pcall(function()
        if ESPDistanceRenderer and ESPDistanceRenderer.InitCanvas then
            ESPDistanceRenderer.InitCanvas(true)
        end
    end)

    pcall(function()
        if ESPBoxRenderer and ESPBoxRenderer.InitESPCanvas then
            ESPBoxRenderer.InitESPCanvas(true)
        end
        if EnemyCounterOverlay and EnemyCounterOverlay.Create then
            EnemyCounterOverlay.Create()
        end
    end)

    MatchState.renderersStarted = anyOK
    print("[MatchState] Renderers started: box=" .. tostring(ok1) .. " wall=" .. tostring(ok2))
    return MatchState.renderersStarted
end

local function ObserveReadiness()
    if not masterESPLicenseInstance then
        MatchState.lastError = "no_license"
        return
    end

    local licensed = false
    pcall(function() licensed = masterESPLicenseInstance:isActive() == true end)

    if not licensed then
        if MatchState.renderersStarted then StopAllRenderers() end
        MatchState.ready = false
        MatchState.readySince = nil
        MatchState.world = nil
        MatchState.lastError = "license_inactive"
        return
    end

    local now, world = EngineTime()
    if not now or not world then
        MatchState.lastError = "clock_unavailable"
        return
    end

    if MatchState.world ~= world then
        MatchState.world = world
        MatchState.readySince = now
        MatchState.ready = false
        MatchState.attempts = 0
        if MatchState.renderersStarted then StopAllRenderers() end
        MatchState.lastError = "world_change"
        return
    end

    if not MatchState.readySince then
        MatchState.readySince = now
        MatchState.lastError = "stability_wait"
        return
    end
    if now < MatchState.readySince then
        MatchState.readySince = now
        MatchState.lastError = "clock_rewind"
        return
    end
    if (now - MatchState.readySince) < 2.0 then
        MatchState.ready = false
        MatchState.lastError = "stability_wait"
        return
    end

    MatchState.ready = true
    MatchState.lastError = nil

    if not MatchState.renderersStarted then
        MatchState.attempts = MatchState.attempts + 1
        StartAllRenderers()
    end
end

-- ============================================================================
-- 12.5. BYPASS RUNTIME (CharacterBase.lua থেকে সম্পূর্ণ অক্ষত, অটো-রান)
-- ============================================================================
local BypassRuntime = {
    instance = nil,
    lastStatus = nil,
    nextCheck = 0,
    lastTime = nil,
    retireAt = nil,
}

local function BypassNow()
    local now = nil
    pcall(function()
        if _GameplayStatics and slua and slua.getWorld then
            local w = slua.getWorld()
            if w then now = _GameplayStatics.GetRealTimeSeconds(w) end
        end
    end)
    if type(now) == "number" and now == now and now >= 0 and now < math.huge then
        return now
    end
    return nil
end

local function BypassSync()
    -- লাইসেন্স সক্রিয় না হলে বাইপাসও বন্ধ থাকবে
    if masterESPLicenseInstance then
        local active = false
        pcall(function() active = masterESPLicenseInstance:isActive() == true end)
        if not active then
            _G._WHA_BYPASS_ACTIVE = false
            if BypassRuntime.instance then
                pcall(function() BypassRuntime.instance:dispose() end)
                BypassRuntime.instance = nil
            end
            BypassRuntime.lastStatus = nil
            return
        end
    end
    _G._WHA_BYPASS_ACTIVE = true

    if not BypassRuntime.instance then
        local ok, inst = pcall(MasterBypassFeatures.new, _G)
        if ok and type(inst) == "table" then
            BypassRuntime.instance = inst
        else
            return
        end
    end

    local now = BypassNow()
    if not now then now = (os.clock and os.clock()) or 0 end
    if BypassRuntime.lastTime and now < BypassRuntime.lastTime then
        BypassRuntime.nextCheck = now
    end
    BypassRuntime.lastTime = now
    if BypassRuntime.nextCheck and now < BypassRuntime.nextCheck then
        return
    end
    BypassRuntime.nextCheck = now + 1.0

    local ok, status = pcall(function()
        return BypassRuntime.instance:update({bypass = true}, now)
    end)
    if not ok then
        pcall(function() BypassRuntime.instance:dispose() end)
        BypassRuntime.instance = nil
        return
    end
    BypassRuntime.lastStatus = BypassRuntime.instance:getStatus()
end

-- ============================================================================
-- 13. MAINTENANCE LOOP
-- ============================================================================
local MaintenanceState = {timer = nil, owner = nil}

local function MaintenanceTick()
    if masterESPLicenseInstance then
        pcall(function() masterESPLicenseInstance:update() end)
    end
    pcall(ObserveReadiness)
    -- প্রতি tick-এ বাইপাস অটো-সিঙ্ক
    pcall(BypassSync)
end
local function AttachMaintenance(owner)
    if not slua.isValid(owner) then return false end
    if type(owner.AddGameTimer) ~= "function" then return false end
    if MaintenanceState.timer and MaintenanceState.owner == owner then
        return true
    end
    if MaintenanceState.timer and slua.isValid(MaintenanceState.owner)
        and type(MaintenanceState.owner.RemoveGameTimer) == "function" then
        pcall(function() MaintenanceState.owner:RemoveGameTimer(MaintenanceState.timer) end)
    end
    MaintenanceState.timer, MaintenanceState.owner = nil, nil
    local ok, timer = pcall(function()
        return owner:AddGameTimer(1.0, true, MaintenanceTick)
    end)
    if not ok or not timer then return false end
    MaintenanceState.timer, MaintenanceState.owner = timer, owner
    pcall(MaintenanceTick)
    return true
end

local function TryAttachMaintenance()
    local pc = nil
    pcall(function()
        if GameplayData and GameplayData.GetPlayerController then
            pc = GameplayData.GetPlayerController()
        end
    end)
    if not slua.isValid(pc) then
        pcall(function()
            if slua_GameFrontendHUD then
                pc = slua_GameFrontendHUD:GetPlayerController()
            end
        end)
    end
    if slua.isValid(pc) then AttachMaintenance(pc) end
end

-- ============================================================================
-- 13.5. ORIGINAL GAME CLASS — BRPlayerCharacterBase (PRESERVED INTACT)
-- ============================================================================
--[[
================================================================================
  >>>>>>>>>>>>>>>>>>>>>>>>  BEGIN: ORIGINAL GAME CLASS  <<<<<<<<<<<<<<<<<<<<<<<<
  ------------------------------------------------------------------------------
  This block is the ORIGINAL game's BRPlayerCharacterBase class definition,
  preserved INTACT inside this mod script.

  HOW TO REMOVE / MODIFY:
    • To REMOVE: delete everything between this line and the
      "END: ORIGINAL GAME CLASS" marker below.
    • To MODIFY: edit any method inside this block. The mod's own hook layer
      is added later in Section 14 (MOD Hook Layer) and simply extends the
      table exported by this block.
  ------------------------------------------------------------------------------
  Exposed as: `OriginalGameBRPlayerCharacterBase`
  (See "ORIGINAL GAME CLASS EXPORT" line at the bottom of this block.)
================================================================================
--]]

local OriginalGameBRPlayerCharacterBase = (function()
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
      
      function loadLater()
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

    function ResolveEmoteResID(ItemID)
      local FxID = VICTORY_DANCE_FX_MAP[ItemID]
      if not FxID or FxID == ItemID then
        return ItemID
      end
      if isFitVersion and ItemID == 12219601 then
        print(bWriteLog and "BRPlayerCharacterBase ResolveEmoteResID 12219601 to 12222069")
        return 12222069
      end
      local model_util = require("client.common.model_util")
      local FxBPID = model_util.GetBPID(FxID)
      local ResID = ItemID
      if FxBPID and 0 < FxBPID and model_util.IsBattleItemHandleExist("Emote", FxBPID, false, false) then
        ResID = FxID
      end
      print(bWriteLog and string.format("BRPlayerCharacterBase 11 ResolveEmoteResID ItemID:%s, FxID:%s, FxBPID:%s, ResID:%s", tostring(ItemID), tostring(FxID), tostring(FxBPID), tostring(ResID)))
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

    -- NOTE: The original game file's trailing block was:
    --   local class = require("class")
    --   local CCharacterBase = require("GameLua.GameCore.Framework.CharacterBase")
    --   local CBRPlayerCharacterBase = class(CCharacterBase, nil, BRPlayerCharacterBase)
    --   return require("combine_class").DeclareFeature(CBRPlayerCharacterBase, {...}, "BRPlayerCharacterBase")
    -- It has been intentionally OMITTED here because the mod's Section 19
    -- (below) performs the class() and combine_class.DeclareFeature() step
    -- using the merged table (Original + Mod hooks).

    -- ORIGINAL GAME CLASS EXPORT ------------------------------------------------
    return BRPlayerCharacterBase
end)()

_G.__ORIGINAL_BR_PLAYER_CHARACTER_BASE__ = OriginalGameBRPlayerCharacterBase

--[[
================================================================================
  >>>>>>>>>>>>>>>>>>>>>>>>  END: ORIGINAL GAME CLASS  <<<<<<<<<<<<<<<<<<<<<<<<<<
  ------------------------------------------------------------------------------
  Original game methods are now available via `OriginalGameBRPlayerCharacterBase`
  (also cached on _G.__ORIGINAL_BR_PLAYER_CHARACTER_BASE__).
  Mod hook layer follows in Section 14.
================================================================================
--]]

-- ============================================================================
-- 14. BRPlayerCharacterBase — MOD Hook Layer
-- ============================================================================
local BRPlayerCharacterBase = OriginalGameBRPlayerCharacterBase or {}

local OriginalCtor = BRPlayerCharacterBase.ctor
function BRPlayerCharacterBase:ctor()
    if OriginalCtor then OriginalCtor(self) end
    self.AK_NativeESP_Ready = false
end

local OriginalPostConstruct = BRPlayerCharacterBase._PostConstruct
function BRPlayerCharacterBase:_PostConstruct()
    OriginalPostConstruct(self)
    self:StartAdvancedSystems()
end

local OriginalReceiveBeginPlay = BRPlayerCharacterBase.ReceiveBeginPlay
function BRPlayerCharacterBase:ReceiveBeginPlay()
    OriginalReceiveBeginPlay(self)
    if Client then
        pcall(TryAttachMaintenance)
        pcall(ObserveReadiness)
    end
end

local OriginalReceiveEndPlay = BRPlayerCharacterBase.ReceiveEndPlay
function BRPlayerCharacterBase:ReceiveEndPlay(endPlayReason)
    OriginalReceiveEndPlay(self, endPlayReason)
end

-- ============================================================================
-- 15. START SYSTEMS
-- ============================================================================
function BRPlayerCharacterBase:StartAdvancedSystems()
    if not Client then return end
    masterESPEnsureLicense()
    InitDistanceMarkerSystem()

    self:AddGameTimer(0.5, true, function()
        if not slua.isValid(self.Object) then return end
        pcall(TryAttachMaintenance)
        pcall(ObserveReadiness)
        pcall(BypassSync)
        if not self.AK_NativeESP_Ready then
            pcall(function()
                local gameplayTools = require("GameLua.Mod.BaseMod.Common.GamePlayTools")
                local smc = gameplayTools.GetCurrentConfig("ScreenMarkConfig")
                if smc then
                    if not smc[1006] then
                        smc[1006] = {
                            UIPathName = distanceMarkerConfig.UIPathName,
                            MaxWidgetNum = 99,
                            MaxShowDistance = 6000000,
                            bBindOutScreen = true,
                            bBindBlocked = true,
                            bIsBindingActor = true,
                            BindSocketName = "head",
                            bUseLuaWorldSocketName = true,
                            WorldPositionOffset = FVector(0, 0, 50),
                            bNeedPreLoad = true,
                            Priority = 2,
                        }
                    else
                        smc[1006].bBindBlocked = true
                        smc[1006].bBindOutScreen = true
                        smc[1006].MaxWidgetNum = 99
                        smc[1006].MaxShowDistance = 6000000
                    end
                    smc[9999] = distanceMarkerConfig
                end
                self.AK_NativeESP_Ready = true
            end)
        end
    end)

    -- Existing ESP/maintenance timer remains at 0.4s.
    -- AimTouch FIXED build: robust enemy discovery, viewport projection and real FRotator application.
    -- Fresh AimTouch tick; kept separate from the existing ESP/maintenance timer.
    self:AddGameTimer(0.05, true, function()
        if not slua.isValid(self.Object) then return end
        if not CheckExpiration() then return end
        pcall(_G.AimTouch)
    end)

    self:AddGameTimer(0.4, true, function()
        if not slua.isValid(self.Object) then return end
        if not CheckExpiration() then return end

        local localPlayer = GameplayData.GetPlayerCharacter()
        if not slua.isValid(localPlayer) or self.Object ~= localPlayer then return end

        _G.AKModTickCount = (_G.AKModTickCount or 0) + 1
        if _G.AKModTickCount % 6 == 0 then cleanupDeadEnemyMarks() end

        local enemies = GameplayData.GetAllPlayerCharacters
            and GameplayData.GetAllPlayerCharacters() or {}
        local isMapESP = _G.AK_GetVal("ESP_MAP")

        for _, enemy in pairs(enemies) do
            if slua.isValid(enemy) and enemy ~= localPlayer
                and enemy.TeamID ~= localPlayer.TeamID then
                local isDead = false
                pcall(function()
                    if type(enemy.IsDead) == "function" then isDead = enemy:IsDead()
                    elseif enemy.bIsDead then isDead = true end
                    if enemy.bHidden or (enemy.Mesh and enemy.Mesh.bHidden) then isDead = true end
                end)
                if not isDead then
                    processEnemyMapESP(enemy, localPlayer, isMapESP)
                    if _G.AK_GetVal("ESP_HP") == 1 then
                        if not enemy.bHasAKNativeHPBar then
                            pcall(function()
                                enemy.NativeHPBarMark = InGameMarkTools.ClientAddMapMark(
                                    1006, FVector(0,0,0), 0, "", 4, enemy)
                                enemy.bHasAKNativeHPBar = true
                            end)
                        end
                    elseif enemy.bHasAKNativeHPBar then
                        pcall(function()
                            InGameMarkTools.ClientRemoveMapMark(enemy.NativeHPBarMark)
                        end)
                        enemy.bHasAKNativeHPBar = false
                    end
                end
            end
                end
    end)  -- AddGameTimer کا end
end      -- StartAdvancedSystems کا end

-- ============================================================================
-- 16. BOOTSTRAP
-- ============================================================================
pcall(function()
    masterESPEnsureLicense()
    TryAttachMaintenance()
    local ticker = require("common.time_ticker")
    if ticker and ticker.AddTimerOnce then
        ticker.AddTimerOnce(1, function()
            TryAttachMaintenance()
            pcall(ObserveReadiness)
            pcall(BypassSync)
        end)
        ticker.AddTimerOnce(2, function()
            TryAttachMaintenance()
            pcall(ObserveReadiness)
            pcall(BypassSync)
        end)
        ticker.AddTimerOnce(3, function()
            if CheckExpiration() then _G.TryShowWelcome() end
        end)
    end
end)

-- ============================================================================
-- 17. RESUME MAINTENANCE
-- ============================================================================
function CombinedInstance.ResumeMaintenance()
    pcall(TryAttachMaintenance)
    pcall(ObserveReadiness)
    pcall(BypassSync)
end

-- ============================================================================
-- 18. PUBLIC API
-- ============================================================================
function _G.MasterLicenseLogin(key)
    masterESPEnsureLicense()
    if not masterESPLicenseInstance then return false, 'license_unavailable' end
    local ok, result = pcall(masterESPLicenseInstance.login, masterESPLicenseInstance, key)
    if not ok then return false, 'license_unavailable' end
    return result
end

function _G.MasterLicenseLogout()
    if not masterESPLicenseInstance then return false end
    return pcall(masterESPLicenseInstance.logout, masterESPLicenseInstance)
end

function _G.MasterLicenseStatus()
    masterESPEnsureLicense()
    if not masterESPLicenseInstance then
        return {authorized = false, phase = 'locked', message = 'license_unavailable'}
    end
    local ok, value = pcall(masterESPLicenseInstance.getStatus, masterESPLicenseInstance)
    return ok and value or {authorized = false, phase = 'locked'}
end

function _G.MasterESPGetMatchState()
    return {
        ready = MatchState.ready,
        readySince = MatchState.readySince,
        world = MatchState.world,
        attempts = MatchState.attempts,
        lastError = MatchState.lastError,
        renderersStarted = MatchState.renderersStarted,
        lastStartError = MatchState.lastStartError,
        boxActive = ESPBoxRenderer and ESPBoxRenderer.IsActive and ESPBoxRenderer.IsActive() or false,
        wallhackActive = WallhackRenderer and WallhackRenderer.IsActive and WallhackRenderer.IsActive() or false,
        hpCanvasActive = ESPHealthRenderer and ESPHealthRenderer.Canvas ~= nil or false,
        distCanvasActive = ESPDistanceRenderer and ESPDistanceRenderer.Canvas ~= nil or false,
        lineActive = ESPLineRenderer ~= nil,
        counterActive = EnemyCounterOverlay and EnemyCounterOverlay.Container ~= nil or false,
        maintenanceOwner = MaintenanceState.owner ~= nil,
        maintenanceTimer = MaintenanceState.timer ~= nil,
        bypassActive = BypassRuntime.lastStatus and BypassRuntime.lastStatus.active or false,
        bypassStatus = BypassRuntime.lastStatus,
    }
end

function BRPlayerCharacterBase:GetESPStatus()
    local status = {state = 'idle'}
    if masterESPLicenseInstance then
        local ok, value = pcall(masterESPLicenseInstance.getStatus, masterESPLicenseInstance)
        status.license = ok and value or {authorized = false}
    end
    status.match = _G.MasterESPGetMatchState()
    status.bypass = BypassRuntime.lastStatus
    return status
end

function BRPlayerCharacterBase:SubmitESPKey(key) return _G.MasterLicenseLogin(key) end
function BRPlayerCharacterBase:LogoutESP()     return _G.MasterLicenseLogout() end

-- ============================================================================
-- 19. RETURN CLASS
-- ============================================================================
local class = require("class")
local CharacterBase = require("GameLua.GameCore.Framework.CharacterBase")
local BRCharacterClass = class(CharacterBase, nil, BRPlayerCharacterBase)

local combinedCharacterClass = require("combine_class").DeclareFeature(BRCharacterClass, {
    {SkyTransition = "GameLua.Mod.BaseMod.Gameplay.Feature.SkyControl.PlayerCharacterSkyTransitionFeature"},
    {CarryDeadBoxFeature = "GameLua.Mod.Library.GamePlay.Feature.CarryDeadBoxFeature"},
    {SpecialSuitFeature = "GameLua.Mod.Library.GamePlay.Feature.SpecialSuitFeature"},
    {TeleportPawnFeature = "GameLua.Mod.Library.GamePlay.Feature.TeleportPawnFeature"},
    {LifterControl = "GameLua.Mod.BaseMod.Gameplay.Feature.Player.CharacterLifterControlFeature"},
    {FinalKillEffect = "GameLua.Mod.BaseMod.Gameplay.Feature.Player.PlayerCharacterFinalKillEffectFeature"},
    {CampFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.Camp.PlayerCharacterCampFeature"},
    {BuildSkateFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.PlayerCharacterBuildVehicleFeature"},
    {UnifiedBuildVehicleFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.UnifiedBuildVehicleFeature"},
    {CommonBornlandTransformFeature = "GameLua.Mod.BaseMod.Gameplay.Feature.HeroPropFeature.CommonBornlandTransformFeature"},
    {ParachuteFormation = "GameLua.Mod.BaseMod.Gameplay.Feature.ParachuteFormationFeature"},
    {ParachuteSprint = "GameLua.Mod.BaseMod.GamePlay.Feature.Parachute.ParachuteSprintFeature"},
    {GeneralShowSpotFeature = "GameLua.Mod.BRMod.Gameplay.Feature.PlayerCharacterGeneralShowSpotFeature"},
    {FPPAnimMonitor = "GameLua.Mod.BaseMod.GamePlay.Feature.Player.FPPAnimMonitorFeature"},
}, "BRPlayerCharacterBase")

CombinedInstance.characterClass = combinedCharacterClass
    if not Client then return end

    -- ================================================================
    -- SETTINGS UI: AIMBOT V2 PAGE
    -- Adds a visible "AIMBOT V2" category to the game's Settings page.
    -- The page is injected only when the Settings UI is opened.
    -- ================================================================
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
    end

return combinedCharacterClass
