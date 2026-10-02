local UltimateEngine = "UltimateEngine"

local _sq = math.sqrt
local _a2 = math.atan2 or math.atan
local _cs = math.cos
local _sn = math.sin
local _ab = math.abs
local _rd = math.rad
local PI = math.pi
local PI2 = PI * 2
local R2D = 180 / PI

local GD = require("GameLua.GameCore.Data.GameplayData")
local _sl = slua
local _iv = _sl and _sl.isValid

local function IV(o)
    return o ~= nil and _iv ~= nil and _iv(o)
end

local function IPA(p)
    if not p or not IV(p) then return false end
    local a = true
    pcall(function()
        if p.HealthStatus ~= nil then
            a = p.HealthStatus < 3
        elseif type(p.IsAlive) == "function" then
            a = p:IsAlive()
        elseif p.Health ~= nil then
            a = p.Health > 0
        elseif p.HP ~= nil then
            a = p.HP > 0
        end
    end)
    return a
end

local function GTI(ch)
    if not IV(ch) then return nil end
    local t = nil
    pcall(function()
        if ch.GetTeamID then t = ch:GetTeamID() end
        if not t then
            local ps = ch.PlayerState
            if not ps and type(ch.GetPlayerStateSafety) == "function" then
                ps = ch:GetPlayerStateSafety()
            end
            if IV(ps) then
                t = (ps.GetTeamID and ps:GetTeamID()) or ps.TeamID
            end
        end
        if not t then t = ch.TeamID end
    end)
    return t
end

local function GMK()
    local pc = nil
    pcall(function() pc = GD.GetPlayerController and GD.GetPlayerController() end)
    if not IV(pc) then return nil end
    local k = nil
    pcall(function()
        if pc.GetPlayerKey then
            k = pc:GetPlayerKey()
        elseif pc.PlayerState and pc.PlayerState.PlayerKey then
            k = pc.PlayerState.PlayerKey
        end
    end)
    return k
end

local function IM(ch, pk, mk)
    local me = false
    pcall(function()
        local mc = GD.GetLocalCharacter and GD.GetLocalCharacter()
        if mc and ch == mc then me = true; return end
        local pc = GD.GetPlayerController and GD.GetPlayerController()
        if IV(pc) and pc.GetPawn then
            local pw = pc:GetPawn()
            if pw and ch == pw then me = true end
        end
    end)
    if not me and mk ~= nil and pk ~= nil then
        me = tostring(pk) == tostring(mk)
    end
    return me
end

local function XVL()
    local cl, cc = {}, 0
    pcall(function()
        local pw = Game:GetAllPlayerPawns()
        if not pw then return end
        local n = pw.Num and pw:Num() or nil
        local function ap(p)
            if not (p and IV(p)) then return end
            local k = nil
            if p.GetPlayerKey then
                k = p:GetPlayerKey()
            elseif p.PlayerKey then
                k = p.PlayerKey
            elseif p.PlayerState and p.PlayerState.PlayerKey then
                k = p.PlayerState.PlayerKey
            end
            if k then
                cc = cc + 1
                cl[cc] = { key = k, pawn = p }
            end
        end
        if n then
            for i = 1, n do
                local p = nil
                pcall(function() p = pw:Get(i - 1) end)
                ap(p)
            end
        else
            for _, p in pairs(pw) do ap(p) end
        end
    end)
    return cl, cc
end

local function CC(ch)
    if not IV(ch) then return nil end
    local l = nil
    pcall(function()
        if ch.K2_GetActorLocation then l = ch:K2_GetActorLocation() end
    end)
    return l
end

local function HH(ch)
    if ch.IsProne and ch:IsProne() then return 30 end
    if ch.bIsCrouched then return 60 end
    return 85
end

local function HL(ch)
    local c = CC(ch)
    if not c then return nil end
    local h = 85
    pcall(function() h = HH(ch) end)
    return { X = c.X, Y = c.Y, Z = c.Z + h }
end

local function DS3(a, b)
    if not a or not b then return 1e18 end
    local dx = a.X - b.X
    local dy = a.Y - b.Y
    local dz = a.Z - b.Z
    return dx * dx + dy * dy + dz * dz
end

local function LocalPlayer()
    local lp = nil
    pcall(function() lp = GD.GetLocalCharacter and GD.GetLocalCharacter() end)
    if not IV(lp) then
        pcall(function()
            local pc = GD.GetPlayerController and GD.GetPlayerController()
            if IV(pc) and pc.GetPawn then lp = pc:GetPawn() end
        end)
    end
    return lp
end

local function LocalPC()
    local pc = nil
    pcall(function()
        pc = GD.GetPlayerController and GD.GetPlayerController()
        if not IV(pc) and slua_GameFrontendHUD then
            pc = slua_GameFrontendHUD:GetPlayerController()
        end
    end)
    return pc
end

local ULT_HitScl = 200
local ULT_HBones = { "head", "skull", "neck_01", "b_head", "c_head", "head_01" }

local function NR()
    pcall(function()
        local p = LocalPlayer()
        if not IV(p) then return end
        local w = p:GetCurrentWeapon()
        if not IV(w) then return end
        local s = w.ShootWeaponEntity or w.ShootWeaponEntity_GEN_VARIABLE
        if IV(s) then
            s.GameDeviationFactor = 0
            s.ExtraHitPerformScale = ULT_HitScl
            pcall(function()
                if s.ExtraHitBoneList ~= nil then s.ExtraHitBoneList = ULT_HBones end
            end)
            pcall(function()
                if s.ScopeAimShootSpreadRot ~= nil then s.ScopeAimShootSpreadRot = 0 end
                if s.ScopeAimShootSpreadDir ~= nil then s.ScopeAimShootSpreadDir = 0 end
                if s.ScopeAimShootSpreadDirValMax ~= nil then s.ScopeAimShootSpreadDirValMax = 0 end
                if s.ScopeAimShootSpreadRotValMax ~= nil then s.ScopeAimShootSpreadRotValMax = 0 end
            end)
        end
        pcall(function()
            local aac = w.AutoAimingConfig
            if aac ~= nil then
                if aac.bEnabled ~= nil then aac.bEnabled = true end
                if aac.AimStrength ~= nil then aac.AimStrength = 1.0 end
                if aac.TargetBone ~= nil then aac.TargetBone = "head" end
                if aac.AimBone ~= nil then aac.AimBone = "head" end
            end
            local arc = w.AutoAimingRangeConfig
            if arc ~= nil then
                if arc.MaxRange ~= nil then arc.MaxRange = 999999 end
                if arc.MinRange ~= nil then arc.MinRange = 0 end
            end
        end)
    end)
end

local HS_Scale = 12.0
local HS_HRatio = 0.95
local _HS_Done = {}

local function HS_Enemy(ch)
    local uid = tostring(ch)
    if _HS_Done[uid] then return end
    pcall(function()
        local sc = HS_Scale
        local function xB(v)
            if v then
                return {
                    X = (v.X or 8) * sc,
                    Y = (v.Y or 8) * sc,
                    Z = (v.Z or 8) * sc
                }
            end
        end
        if ch.HeadBoundBoxExtent ~= nil then
            ch.HeadBoundBoxExtent = xB(ch.HeadBoundBoxExtent)
        end
        if ch.CrouchStillHeadBoundBoxExtent ~= nil then
            ch.CrouchStillHeadBoundBoxExtent = xB(ch.CrouchStillHeadBoundBoxExtent)
        end
        if ch.StandStillHeadBoundBoxExtent ~= nil then
            ch.StandStillHeadBoundBoxExtent = xB(ch.StandStillHeadBoundBoxExtent)
        end
        if ch.HeadRatio ~= nil then ch.HeadRatio = HS_HRatio end
        if ch.ModesIgnoreHitHead ~= nil then ch.ModesIgnoreHitHead = false end
        local fh = ch.CharacterFakeHeadMesh_Lod
        if IV(fh) then
            pcall(function() fh:SetWorldScale3D({ X = sc, Y = sc, Z = sc }) end)
        end
    end)
    _HS_Done[uid] = true
end

local _FRT = nil
pcall(function() _FRT = _G.FRotator or import("Rotator") end)

local function MkRot(p, y)
    if _FRT then
        local ok, r = pcall(function() return _FRT(p, y, 0) end)
        if ok and r then return r end
    end
    return { Pitch = p, Yaw = y, Roll = 0 }
end

local function CHS_LookAt(from, to)
    local dx = to.X - from.X
    local dy = to.Y - from.Y
    local dz = to.Z - from.Z
    local d2 = _sq(dx * dx + dy * dy)
    return MkRot(-_a2(dz, d2) * R2D, _a2(dy, dx) * R2D)
end

local function CHS_HP(ch)
    local p = nil
    pcall(function()
        local m = ch.Mesh
        if IV(m) and m.GetSocketLocation then
            pcall(function()
                p = m:GetSocketLocation("head")
                if p and p.X == 0 and p.Y == 0 then p = nil end
            end)
            if not p then
                pcall(function() p = m:GetSocketLocation("neck_01") end)
            end
        end
    end)
    if p and (p.X ~= 0 or p.Y ~= 0 or p.Z ~= 0) then return p end
    return HL(ch)
end

local function CHS_Firing(pw)
    local f = false
    pcall(function()
        local w = nil
        pcall(function() w = pw:GetCurrentWeapon() end)
        if not IV(w) then
            pcall(function() w = pw:GetCurrentShootWeapon() end)
        end
        if IV(w) then
            local se = w.ShootWeaponEntity or w.ShootWeaponEntity_GEN_VARIABLE
            if IV(se) then
                if se.bFiring == true then f = true; return end
                pcall(function()
                    if se:IsFiring() == true then f = true end
                end)
            end
        end
        if not f then f = (pw.bFiring == true) end
    end)
    return f
end

local _ULT_AAC = nil
local _ULT_BCLASSES = {
    "NormalProjectile",
    "BP_PlayerRifleBullet_C",
    "BP_PlayerBullet_C"
}

local function ULT_SetAutoAimTarget(lp, targetCh)
    pcall(function()
        if not IV(_ULT_AAC) then
            _ULT_AAC = lp.BP_AutoAimingComponent_GEN_VARIABLE
                or lp.AutoAimingComponent
                or lp.AutoAimComp
        end
        if not IV(_ULT_AAC) then return end
        local m = targetCh.Mesh
        pcall(function()
            if _ULT_AAC.SetTarget then _ULT_AAC:SetTarget(targetCh) end
        end)
        pcall(function()
            if _ULT_AAC.SetTargetComponent then _ULT_AAC:SetTargetComponent(m) end
        end)
        pcall(function()
            if _ULT_AAC.SetTargetBone then _ULT_AAC:SetTargetBone("head") end
        end)
        pcall(function()
            if _ULT_AAC.TargetActor ~= nil then _ULT_AAC.TargetActor = targetCh end
        end)
        pcall(function()
            if _ULT_AAC.TargetComponent ~= nil then _ULT_AAC.TargetComponent = m end
        end)
        pcall(function()
            if _ULT_AAC.TargetBone ~= nil then _ULT_AAC.TargetBone = "head" end
        end)
        pcall(function()
            if _ULT_AAC.AimTargetActor ~= nil then _ULT_AAC.AimTargetActor = targetCh end
        end)
        pcall(function()
            if _ULT_AAC.bActive ~= nil then _ULT_AAC.bActive = true end
        end)
        pcall(function()
            if _ULT_AAC.bEnabled ~= nil then _ULT_AAC.bEnabled = true end
        end)
        pcall(function()
            if _ULT_AAC.AimStrength ~= nil then _ULT_AAC.AimStrength = 1.0 end
        end)
    end)
end

local function ULT_RedirProjectiles(nearestHead)
    if not nearestHead then return end
    for _, cn in ipairs(_ULT_BCLASSES) do
        pcall(function()
            local bc = nil
            pcall(function() bc = import(cn) end)
            if not IV(bc) then return end
            local bullets = Game:GetAllActorsOfClass(bc)
            if not bullets then return end
            for i = 0, bullets:Num() - 1 do
                local b = bullets:Get(i)
                if IV(b) then
                    local bloc = nil
                    pcall(function() bloc = b:K2_GetActorLocation() end)
                    if bloc then
                        local dx = nearestHead.X - bloc.X
                        local dy = nearestHead.Y - bloc.Y
                        local dz = nearestHead.Z - bloc.Z
                        local d = _sq(dx * dx + dy * dy + dz * dz)
                        if d > 1 then
                            local mc = b.BulletMovementComponent
                                or b.DelayFlyProjMovementComponent
                            if IV(mc) then
                                local spd = mc.MaxSpeed or mc.InitialSpeed or 40000
                                local nx, ny, nz = dx / d, dy / d, dz / d
                                pcall(function()
                                    mc.Velocity = {
                                        X = nx * spd,
                                        Y = ny * spd,
                                        Z = nz * spd
                                    }
                                end)
                                pcall(function()
                                    if mc.LaunchVelocity ~= nil then
                                        mc.LaunchVelocity = {
                                            X = nx * spd,
                                            Y = ny * spd,
                                            Z = nz * spd
                                        }
                                    end
                                end)
                            end
                        end
                    end
                end
            end
        end)
    end
end

local function MainTick()
    local pc = LocalPC()
    if not IV(pc) then return end
    local lp = LocalPlayer()
    if not IV(lp) then return end
    local mk = GMK()
    local mt = GTI(lp)

    NR()

    local camLoc = nil
    pcall(function()
        local cm = pc:GetPlayerCameraManager()
        if IV(cm) then camLoc = cm:GetCameraLocation() end
    end)
    if not camLoc then
        pcall(function() camLoc = lp:K2_GetActorLocation() end)
    end
    if not camLoc then return end

    local nearestHead, nearestCh, nearestD = nil, nil, math.huge
    pcall(function()
        local cl, cnt = XVL()
        for i = 1, cnt do
            local e = cl[i]
            if not e then break end
            local ch = e.pawn
            if IV(ch) and ch ~= lp and not IM(ch, e.key, mk) and IPA(ch)
                and (mt == nil or GTI(ch) ~= mt) then
                HS_Enemy(ch)
                local hp = CHS_HP(ch)
                if hp then
                    local d = DS3(camLoc, hp)
                    if d < nearestD then
                        nearestD = d
                        nearestHead = hp
                        nearestCh = ch
                    end
                end
            end
        end
    end)

    if not nearestCh then return end

    ULT_SetAutoAimTarget(lp, nearestCh)
    ULT_RedirProjectiles(nearestHead)

    if CHS_Firing(lp) then
        local rot = CHS_LookAt(camLoc, nearestHead)
        pcall(function() pc:SetControlRotation(rot) end)
        pcall(function() pc:ClientSetRotation(rot, true) end)
        pcall(function()
            local ctrl = lp:GetController()
            if IV(ctrl) then ctrl:SetControlRotation(rot) end
        end)
    end
end

local _attached = false

local function Attach()
    if _attached then return end
    local pc = LocalPC()
    if not IV(pc) then
        pcall(function()
            require("timer").SetGameTimer(1, false, Attach)
        end)
        return
    end
    _attached = true
    pc:AddGameTimer(1 / 60, true, function() pcall(MainTick) end)
    pcall(function()
        local lastPC = pc
        pc:AddGameTimer(1, true, function()
            local cur = LocalPC()
            if IV(cur) and cur ~= lastPC then
                lastPC = cur
                _attached = false
                pcall(function()
                    cur:AddGameTimer(1 / 60, true, function() pcall(MainTick) end)
                end)
                _attached = true
            end
        end)
    end)
end

pcall(Attach)
pcall(function()
    require("timer").SetGameTimer(1, false, function() pcall(Attach) end)
end)
