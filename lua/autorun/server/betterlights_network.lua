-- BetterLights: Network Message Consolidation
-- Single network message system for all server-to-client communications

if SERVER then
    -- Single network string for all BetterLights messages
    util.AddNetworkString("BetterLights_Event")
    
    -- Message type constants
    local MSG_MUZZLE_FLASH = 1
    local MSG_BULLET_IMPACT = 2
    
    -- Shared AR2 detection function
    local function isAR2Shot(shooter, bullet)
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
    
    -- Muzzle Flash Handler
    hook.Add("EntityFireBullets", "BetterLights_MuzzleFlash_Server", function(ent, bullet)
        if not IsValid(ent) then return end
        if not bullet then return end

        local src = bullet.Src or (IsValid(ent) and ent.GetShootPos and ent:GetShootPos()) or ent:GetPos()
        if not src then return end

        net.Start("BetterLights_Event")
            net.WriteUInt(MSG_MUZZLE_FLASH, 4) -- 4 bits = up to 16 message types
            net.WriteVector(src)
            net.WriteBool(isAR2Shot(ent, bullet))
        net.SendPVS(src)
    end)
    
    -- Bullet Impact Handler
    hook.Add("EntityFireBullets", "BetterLights_BulletImpact_Server", function(ent, bullet)
        if not IsValid(ent) then return end
        if not bullet then return end

        local prev = bullet.Callback
        bullet.Callback = function(att, tr, dmginfo)
            if isfunction(prev) then prev(att, tr, dmginfo) end
            if not tr or not tr.Hit or not tr.HitPos then return end

            local pos = tr.HitPos
            if tr.HitNormal then
                pos = pos + tr.HitNormal * 2
            end

            net.Start("BetterLights_Event")
                net.WriteUInt(MSG_BULLET_IMPACT, 4)
                net.WriteVector(pos)
                net.WriteBool(isAR2Shot(att, bullet))
            net.SendPVS(pos)
        end
    end)
end