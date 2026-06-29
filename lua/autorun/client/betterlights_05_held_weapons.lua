if CLIENT then

    local BL = BetterLights

    function BL.GetHeldWeaponModelLightPos(ply, wep, attachNames, fallbackDistance)
        if IsValid(ply) and ply == LocalPlayer() then
            local vm = ply:GetViewModel()
            if IsValid(vm) then
                local pos = BL.GetAttachmentPos(vm, attachNames)
                if pos then return pos end
            end
        end

        if IsValid(wep) then
            local pos = BL.GetAttachmentPos(wep, attachNames)
            if pos then return pos end
            if wep.WorldSpaceCenter then return wep:WorldSpaceCenter() end
        end

        if IsValid(ply) and ply.EyePos then
            return ply:EyePos() + (ply.EyeAngles and ply:EyeAngles():Forward() * (fallbackDistance or 16) or Vector(fallbackDistance or 16, 0, 0))
        end

        return IsValid(wep) and wep:GetPos() or Vector(0, 0, 0)
    end

    function BL.GetHeldWeaponTraceLightPos(ply, wep, key, distance, fallbackDistance)
        if not IsValid(ply) then return nil end

        local eye = ply:EyePos()
        local fwd = ply.GetAimVector and ply:GetAimVector() or ply:EyeAngles():Forward()
        local tr = BL.TraceLineReuse(key, {
            start = eye,
            endpos = eye + fwd * (distance or 48),
            filter = { ply, wep }
        })

        return tr.Hit and (tr.HitPos + tr.HitNormal * 6) or (eye + fwd * (fallbackDistance or 24))
    end

    function BL.GetHeldWeaponLightPositions(ply, wep, attachNames, traceKey, traceDistance, traceFallbackDistance, modelFallbackDistance)
        local pos_model = BL.GetHeldWeaponModelLightPos(ply, wep, attachNames, modelFallbackDistance)
        local pos_world = BL.GetHeldWeaponTraceLightPos(ply, wep, traceKey, traceDistance, traceFallbackDistance)

        return pos_world, pos_model or pos_world
    end
end
