if SERVER then
    util.AddNetworkString("BetterLights_Event")

    local MSG_MUZZLE_FLASH = 1
    local MSG_BULLET_IMPACT = 2
    local MSG_STRIDER_MUZZLE_FLASH = 3
    local MSG_STRIDER_BULLET_IMPACT = 4
    local MSG_HUNTER_CHOPPER_MUZZLE_FLASH = 5
    local MSG_HUNTER_CHOPPER_BULLET_IMPACT = 6
    local STRIDER_CLASS = "npc_strider"
    local STRIDER_MUZZLE_ATTACHMENT = "MiniGun"
    local HUNTER_CHOPPER_CLASS = "npc_helicopter"
    local HUNTER_CHOPPER_MUZZLE_ATTACHMENT = "Muzzle"

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
        end
        if bullet and type(bullet.TracerName) == "string" and bullet.TracerName ~= "" then
            local tn = string.lower(bullet.TracerName)
            if string.find(tn, "ar2", 1, true) then return true end
        end
        if IsValid(shooter) then
            local wep = shooter.GetActiveWeapon and shooter:GetActiveWeapon() or nil
            if IsValid(wep) then
                local cls = string.lower(wep:GetClass() or "")
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

    local function getMuzzleFlashPos(ent, bullet)
        if IsValid(ent) and ent.GetClass and ent.LookupAttachment and ent.GetAttachment then
            local cls = ent:GetClass()
            local attachmentName
            if cls == STRIDER_CLASS then
                attachmentName = STRIDER_MUZZLE_ATTACHMENT
            elseif cls == HUNTER_CHOPPER_CLASS then
                attachmentName = HUNTER_CHOPPER_MUZZLE_ATTACHMENT
            end

            local attachmentId = attachmentName and ent:LookupAttachment(attachmentName)
            if attachmentId and attachmentId > 0 then
                local attachment = ent:GetAttachment(attachmentId)
                if attachment and attachment.Pos then return attachment.Pos end
            end
        end

        return bullet.Src or (IsValid(ent) and ent.GetShootPos and ent:GetShootPos()) or ent:GetPos()
    end

    local function getSpecialMuzzleMessage(ent)
        if not (IsValid(ent) and ent.GetClass) then return nil end

        local cls = ent:GetClass()
        if cls == STRIDER_CLASS then return MSG_STRIDER_MUZZLE_FLASH end
        if cls == HUNTER_CHOPPER_CLASS then return MSG_HUNTER_CHOPPER_MUZZLE_FLASH end
        return nil
    end

    local function getSpecialImpactMessage(ent)
        if not (IsValid(ent) and ent.GetClass) then return nil end

        local cls = ent:GetClass()
        if cls == STRIDER_CLASS then return MSG_STRIDER_BULLET_IMPACT end
        if cls == HUNTER_CHOPPER_CLASS then return MSG_HUNTER_CHOPPER_BULLET_IMPACT end
        return nil
    end

    hook.Add("EntityFireBullets", "BetterLights_MuzzleFlash_Server", function(ent, bullet)
        if not isBetterLightsEnabled() then return end
        if not IsValid(ent) then return end
        if not bullet then return end

        local src = getMuzzleFlashPos(ent, bullet)
        if not src then return end
        local specialMessage = getSpecialMuzzleMessage(ent)

        net.Start("BetterLights_Event")
            net.WriteUInt(specialMessage or MSG_MUZZLE_FLASH, 4)
            net.WriteVector(src)
            if not specialMessage then
                net.WriteBool(isAR2Shot(ent, bullet))
            end
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

            net.Start("BetterLights_Event")
                local specialMessage = getSpecialImpactMessage(ent)
                net.WriteUInt(specialMessage or MSG_BULLET_IMPACT, 4)
                net.WriteVector(pos)
                if not specialMessage then
                    net.WriteBool(isAR2Shot(att, bullet))
                end
            net.SendPVS(pos)

            return ret
        end
    end)
end
