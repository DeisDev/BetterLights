if SERVER then
    local BL = BetterLights

    util.AddNetworkString(BL.NET_EVENT_MESSAGE)

    local STRIDER_CLASS = "npc_strider"
    local HUNTER_CHOPPER_CLASS = "npc_helicopter"
    local STUNSTICK_CLASS = "weapon_stunstick"
    local STUNSTICK_TRACE_DISTANCE = 96
    local STUNSTICK_TRACE_MINS = Vector(-8, -8, -8)
    local STUNSTICK_TRACE_MAXS = Vector(8, 8, 8)
    local MUZZLE_DEFINITIONS_BY_CLASS = {}
    local recentStunstickImpacts = {}

    local function clampColorChannel(value)
        value = tonumber(value)
        if not value then return nil end

        return math.Clamp(math.floor(value + 0.5), 0, 255)
    end

    local function readColorOption(options)
        if not options then return nil end

        local color = options.color
        local r = options.r
        local g = options.g
        local b = options.b

        if type(color) == "table" then
            r = color.r or color[1] or r
            g = color.g or color[2] or g
            b = color.b or color[3] or b
        end

        r = clampColorChannel(r)
        g = clampColorChannel(g)
        b = clampColorChannel(b)
        if not (r and g and b) then return nil end

        return { r = r, g = g, b = b }
    end

    function BL.RegisterMuzzleFlashAttachment(className, attachmentNames, options)
        if type(className) ~= "string" or className == "" then return end

        if type(attachmentNames) == "string" then
            attachmentNames = { attachmentNames }
        end

        if type(attachmentNames) ~= "table" or #attachmentNames == 0 then return end

        MUZZLE_DEFINITIONS_BY_CLASS[className] = {
            attachments = attachmentNames,
            ar2 = options and (options.ar2 == true or options.style == "ar2") or false,
            color = readColorOption(options),
            muzzleMessage = options and options.muzzleMessage or nil,
            impactMessage = options and options.impactMessage or nil
        }
    end

    BL.RegisterMuzzleFlashAttachment(STRIDER_CLASS, "MiniGun", {
        muzzleMessage = BL.NET_STRIDER_MUZZLE_FLASH,
        impactMessage = BL.NET_STRIDER_BULLET_IMPACT
    })
    BL.RegisterMuzzleFlashAttachment(HUNTER_CHOPPER_CLASS, "Muzzle", {
        muzzleMessage = BL.NET_HUNTER_CHOPPER_MUZZLE_FLASH,
        impactMessage = BL.NET_HUNTER_CHOPPER_BULLET_IMPACT
    })
    BL.RegisterMuzzleFlashAttachment("weapon_ar2", "muzzle", { ar2 = true })

    local function isBetterLightsEnabled()
        local cvar = GetConVar("betterlights_enable")
        return not cvar or cvar:GetBool()
    end

    local function isAR2Shot(shooter, bullet)
        if IsValid(shooter) and shooter.GetClass then
            local cls = string.lower(shooter:GetClass() or "")
            if cls == "npc_turret_floor" or cls == "npc_turret_ceiling" then
                return true
            end
            local def = MUZZLE_DEFINITIONS_BY_CLASS[shooter:GetClass()]
            if def and def.ar2 then return true end
        end
        if bullet and type(bullet.TracerName) == "string" and bullet.TracerName ~= "" then
            local tn = string.lower(bullet.TracerName)
            if string.find(tn, "ar2", 1, true) then return true end
        end
        if IsValid(shooter) then
            local wep = shooter.GetActiveWeapon and shooter:GetActiveWeapon() or nil
            if IsValid(wep) then
                local cls = string.lower(wep:GetClass() or "")
                local def = MUZZLE_DEFINITIONS_BY_CLASS[wep:GetClass()]
                if def and def.ar2 then return true end
                if cls == "weapon_ar2" then return true end
                local wn = wep.TracerName
                if type(wn) == "string" and wn ~= "" then
                    wn = string.lower(wn)
                    if string.find(wn, "ar2", 1, true) then return true end
                end
            end
        end
        return false
    end

    local function getAttachmentPos(ent, attachmentNames)
        if not (IsValid(ent) and ent.LookupAttachment and ent.GetAttachment) then return nil end
        if not attachmentNames then return nil end

        for i = 1, #attachmentNames do
            local attachmentId = ent:LookupAttachment(attachmentNames[i])
            if attachmentId and attachmentId > 0 then
                local attachment = ent:GetAttachment(attachmentId)
                if attachment and attachment.Pos then return attachment.Pos end
            end
        end

        return nil
    end

    local function getMuzzleDefinition(ent)
        if not (IsValid(ent) and ent.GetClass) then return nil end
        return MUZZLE_DEFINITIONS_BY_CLASS[ent:GetClass()]
    end

    local function isUsableVector(pos)
        return pos and pos ~= vector_origin
    end

    local function getMuzzleSendOrigin(ent, bullet)
        if bullet and isUsableVector(bullet.Src) then return bullet.Src end
        if IsValid(ent) and ent.GetShootPos then return ent:GetShootPos() end
        if IsValid(ent) and ent.GetPos then return ent:GetPos() end
        return nil
    end

    local function getSpecialImpactMessage(ent)
        local def = getMuzzleDefinition(ent)
        return def and def.impactMessage or nil
    end

    local function isStunstickDamage(attacker, inflictor)
        if IsValid(inflictor) and inflictor.GetClass and inflictor:GetClass() == STUNSTICK_CLASS then
            return true
        end

        if not IsValid(attacker) then return false end
        local weapon = attacker.GetActiveWeapon and attacker:GetActiveWeapon() or nil
        return IsValid(weapon) and weapon.GetClass and weapon:GetClass() == STUNSTICK_CLASS
    end

    local function getActiveStunstick(ply)
        if not IsValid(ply) then return nil end

        local weapon = ply.GetActiveWeapon and ply:GetActiveWeapon() or nil
        if not (IsValid(weapon) and weapon.GetClass and weapon:GetClass() == STUNSTICK_CLASS) then return nil end
        return weapon
    end

    local function getDamagePosition(dmginfo)
        if not (dmginfo and dmginfo.GetDamagePosition) then return nil end

        local pos = dmginfo:GetDamagePosition()
        if not pos or pos == vector_origin then return nil end
        return pos
    end

    local function getStunstickTrace(attacker)
        if not IsValid(attacker) then return nil end
        if not (attacker.GetShootPos and attacker.GetAimVector) then return nil end

        local start = attacker:GetShootPos()
        local endpos = start + attacker:GetAimVector() * STUNSTICK_TRACE_DISTANCE
        return util.TraceHull({
            start = start,
            endpos = endpos,
            mins = STUNSTICK_TRACE_MINS,
            maxs = STUNSTICK_TRACE_MAXS,
            filter = attacker,
            mask = MASK_SHOT_HULL or MASK_SHOT
        })
    end

    local function getTraceImpactPosition(attacker)
        local tr = getStunstickTrace(attacker)
        if not (tr and tr.Hit and tr.HitPos) then return nil end

        local pos = tr.HitPos
        if tr.HitNormal then
            pos = pos + tr.HitNormal * 2
        end

        return pos, tr.Entity
    end

    local function resolveStunstickImpactPosition(dmginfo, attacker)
        local pos = getDamagePosition(dmginfo)
        if pos then return pos end

        return getTraceImpactPosition(attacker)
    end

    local function shouldSendStunstickImpact(attacker)
        local now = CurTime()
        local attackerIndex = IsValid(attacker) and attacker:EntIndex() or 0
        local key = tostring(attackerIndex)
        if recentStunstickImpacts[key] and recentStunstickImpacts[key] > now then return false end

        recentStunstickImpacts[key] = now + 0.12
        return true
    end

    local function sendStunstickImpact(pos)
        net.Start(BL.NET_EVENT_MESSAGE)
            net.WriteUInt(BL.NET_STUNSTICK_IMPACT, 4)
            net.WriteVector(pos)
        net.SendPVS(pos)
    end

    local function sendStunstickTraceImpact(attacker)
        local pos = getTraceImpactPosition(attacker)
        if not pos then return end
        if not shouldSendStunstickImpact(attacker) then return end

        sendStunstickImpact(pos)
    end

    hook.Add("EntityFireBullets", "BetterLights_MuzzleFlash_Server", function(ent, bullet)
        if not isBetterLightsEnabled() then return end
        if not IsValid(ent) then return end
        if not bullet then return end

        local muzzleDef = getMuzzleDefinition(ent)
        if muzzleDef and muzzleDef.muzzleMessage then
            local src = getAttachmentPos(ent, muzzleDef.attachments)
            if not src then return end

            net.Start(BL.NET_EVENT_MESSAGE)
                net.WriteUInt(muzzleDef.muzzleMessage, 4)
                net.WriteVector(src)
            net.SendPVS(src)
            return
        end

        local src = getMuzzleSendOrigin(ent, bullet)
        if not src then return end

        -- TODO: We do not like using the bullet source for player muzzle flashes, but attachment-based placement kept breaking reliability and we do not have a better solution yet.
        net.Start(BL.NET_EVENT_MESSAGE)
            net.WriteUInt(BL.NET_MUZZLE_FLASH, 4)
            net.WriteVector(src)
            net.WriteBool(isAR2Shot(ent, bullet))
        net.SendPVS(src)
    end)

    hook.Add("EntityFireBullets", "BetterLights_BulletImpact_Server", function(ent, bullet)
        if not isBetterLightsEnabled() then return end
        if not IsValid(ent) then return end
        if not bullet then return end

        local prev = bullet.Callback
        bullet.Callback = function(att, tr, dmginfo)
            local ret
            if isfunction(prev) then ret = prev(att, tr, dmginfo) end
            if not isBetterLightsEnabled() then return ret end
            if not tr or not tr.Hit or not tr.HitPos then return ret end

            local pos = tr.HitPos
            if tr.HitNormal then
                pos = pos + tr.HitNormal * 2
            end

            net.Start(BL.NET_EVENT_MESSAGE)
                local specialMessage = getSpecialImpactMessage(ent)
                net.WriteUInt(specialMessage or BL.NET_BULLET_IMPACT, 4)
                net.WriteVector(pos)
                if not specialMessage then
                    net.WriteBool(isAR2Shot(att, bullet))
                end
            net.SendPVS(pos)

            return ret
        end
    end)

    hook.Add("EntityTakeDamage", "BetterLights_StunstickImpact_Server", function(target, dmginfo)
        if not isBetterLightsEnabled() then return end
        if not IsValid(target) then return end
        if not dmginfo then return end

        local attacker = dmginfo.GetAttacker and dmginfo:GetAttacker() or nil
        local inflictor = dmginfo.GetInflictor and dmginfo:GetInflictor() or nil
        if not isStunstickDamage(attacker, inflictor) then return end
        if not shouldSendStunstickImpact(attacker) then return end

        local pos = resolveStunstickImpactPosition(dmginfo, attacker)
        if not pos then return end

        sendStunstickImpact(pos)
    end)

    hook.Add("KeyPress", "BetterLights_StunstickImpact_KeyPress", function(ply, key)
        if key ~= IN_ATTACK then return end
        if not isBetterLightsEnabled() then return end

        local weapon = getActiveStunstick(ply)
        if not weapon then return end

        timer.Simple(0, function()
            if not isBetterLightsEnabled() then return end
            if not IsValid(ply) then return end
            if getActiveStunstick(ply) ~= weapon then return end

            sendStunstickTraceImpact(ply)
        end)
    end)
end
