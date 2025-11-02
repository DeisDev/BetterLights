-- BetterLights: Muzzle Flash (server)
-- Captures bullet fires and broadcasts a muzzle flash position to clients.

if SERVER then
    util.AddNetworkString("BetterLights_MuzzleFlash")

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

    hook.Add("EntityFireBullets", "BetterLights_MuzzleFlash_Server", function(ent, bullet)
        if not IsValid(ent) then return end
        if not bullet then return end

        local src = bullet.Src or (IsValid(ent) and ent.GetShootPos and ent:GetShootPos()) or ent:GetPos()
        if not src then return end

        net.Start("BetterLights_MuzzleFlash")
            net.WriteVector(src)
            net.WriteBool(isAR2Shot(ent, bullet))
        net.SendPVS(src)
    end)
end
