-- BetterLights: Bullet impact server dispatcher
-- Captures bullet impacts via the bullet callback and broadcasts to clients in PVS.

if SERVER then
    util.AddNetworkString("BetterLights_BulletImpact")

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

            net.Start("BetterLights_BulletImpact")
                net.WriteVector(pos)
                net.WriteBool(isAR2Shot(att, bullet))
            net.SendPVS(pos)
        end
    end)
end
