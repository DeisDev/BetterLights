if CLIENT then
    local BL = BetterLights
    local CurTime = CurTime
    local FrameNumber = FrameNumber
    local IsValid = IsValid
    local math_Clamp = math.Clamp
    local math_max = math.max
    local math_Rand = math.Rand
    local math_sqrt = math.sqrt
    local string_sub = string.sub
    local FIRE_LIGHT_ID_OFFSET = 70000
    local MODEL_LIGHT_WRAPPER_VERSION = 2
    local MODEL_LIGHT_REFERENCE_BRIGHTNESS = 5.2
    local MODEL_LIGHT_STRENGTH = 0.24
    local MODEL_LIGHT_MAX_STRENGTH = 0.75
    local FIRE_SOURCE_CLASSES = {
        "entityflame",
        -- Map-authored env_fire entities create this child only while burning.
        "_firesmoke"
    }
    local flickerStates = setmetatable({}, { __mode = "k" })
    local modelLightTargets = BL._fireFullbrightTargets or BL._fireModelLightTargets or setmetatable({}, { __mode = "k" })
    BL._fireFullbrightTargets = nil
    BL._fireModelLightTargets = modelLightTargets
    -- Note: DynamicLight is NOT localized to ensure compatibility with wrappers like GShader Library
    local cvar_enable = BL.CreateClientConVar("betterlights_fire_enable", "1", true, false, "Enable dynamic light for entities that are on fire")
    local cvar_size = BL.CreateClientConVar("betterlights_fire_size", "160", true, false, "Dynamic light radius for burning entities")
    local cvar_brightness = BL.CreateClientConVar("betterlights_fire_brightness", "5.2", true, false, "Dynamic light brightness for burning entities")
    local cvar_decay = BL.CreateClientConVar("betterlights_fire_decay", "2000", true, false, "Dynamic light decay for burning entities")
    local cvar_models_light = BL.CreateClientConVar("betterlights_fire_models_elight", "1", true, false, "Add local fire lighting while drawing burning models")
    local cvar_models_light_intensity = BL.CreateClientConVar("betterlights_fire_models_elight_size_mult", "1.0", true, false, "Multiplier for direct fire model-light intensity")
    local cvar_flicker_enable = BL.CreateClientConVar("betterlights_fire_flicker_enable", "1", true, false, "Enable flicker effect for burning entity lights")
    local cvar_flicker_amount = BL.CreateClientConVar("betterlights_fire_flicker_amount", "0.35", true, false, "Flicker intensity (as a fraction of brightness)")
    local cvar_flicker_size_amount = BL.CreateClientConVar("betterlights_fire_flicker_size_amount", "0.12", true, false, "Flicker intensity applied to light radius")
    local cvar_flicker_speed = BL.CreateClientConVar("betterlights_fire_flicker_speed", "11.5", true, false, "Flicker speed (higher = faster flicker)")

    local cvar_col_r = BL.CreateClientConVar("betterlights_fire_color_r", "255", true, false, "Burning entities color - red (0-255)")
    local cvar_col_g = BL.CreateClientConVar("betterlights_fire_color_g", "170", true, false, "Burning entities color - green (0-255)")
    local cvar_col_b = BL.CreateClientConVar("betterlights_fire_color_b", "60", true, false, "Burning entities color - blue (0-255)")

    local function sampleNoiseBand(band, time, frequency)
        if time >= band.finish then
            band.from = band.to
            band.to = math_Rand(-1, 1)
            band.start = time
            band.finish = time + math_Rand(0.75, 1.25) / frequency
        end

        local fraction = math_Clamp((time - band.start) / (band.finish - band.start), 0, 1)
        local smoothed = fraction * fraction * (3 - 2 * fraction)
        return band.from + (band.to - band.from) * smoothed
    end

    local function getFlickerSignals(source, time, speed)
        if speed <= 0 then return 0, 0 end

        local state = flickerStates[source]
        if not state then
            local slowValue = math_Rand(-1, 1)
            local fastValue = math_Rand(-1, 1)
            state = {
                slow = { from = slowValue, to = slowValue, start = time, finish = time },
                fast = { from = fastValue, to = fastValue, start = time, finish = time }
            }
            flickerStates[source] = state
        end

        local slow = sampleNoiseBand(state.slow, time, math_max(0.05, speed * 0.22))
        local fast = sampleNoiseBand(state.fast, time, math_max(0.05, speed * 0.9))
        local burst = math_max(0, fast - 0.55) * 0.7
        local brightnessSignal = math_Clamp(slow * 0.62 + fast * 0.28 + burst, -1, 1)
        local sizeSignal = math_Clamp(slow * 0.72 + fast * 0.18, -1, 1)
        return brightnessSignal, sizeSignal
    end

    local function drawModel(record, target, flags)
        if record.downstream then
            return record.downstream(target, flags)
        end

        return target:DrawModel(flags)
    end

    local function createLocalLights()
        local lights = {}
        for i = 1, 4 do
            lights[i] = {
                type = MATERIAL_LIGHT_POINT,
                color = Vector(0, 0, 0),
                pos = Vector(0, 0, 0),
                range = 0,
                fiftyPercentDistance = 1,
                zeroPercentDistance = 2
            }
        end

        return lights
    end

    local function updateLocalLight(light, x, y, z, r, g, b, halfDistance, zeroDistance)
        light.pos.x = x
        light.pos.y = y
        light.pos.z = z
        light.color.x = r
        light.color.y = g
        light.color.z = b
        light.fiftyPercentDistance = halfDistance
        light.zeroPercentDistance = zeroDistance
    end

    local function updateModelLights(record, target, brightness, intensityMultiplier, cr, cg, cb)
        local mins, maxs = target:WorldSpaceAABB()
        local width = math_max(1, maxs.x - mins.x)
        local depth = math_max(1, maxs.y - mins.y)
        local height = math_max(1, maxs.z - mins.z)
        local centerX = (mins.x + maxs.x) * 0.5
        local centerY = (mins.y + maxs.y) * 0.5
        local lightZ = maxs.z + math_Clamp(height * 0.12, 4, 24)
        local offsetX = math_max(12, width * 0.65)
        local offsetY = math_max(12, depth * 0.65)
        local largestExtent = math_max(width, depth, height)
        local halfDistance = math_max(32, largestExtent * 0.9)
        local zeroDistance = math_max(halfDistance + 16, largestExtent * 2.2)

        local relativeBrightness = math_sqrt(math_max(0, brightness) / MODEL_LIGHT_REFERENCE_BRIGHTNESS)
        local strength = math_Clamp(
            relativeBrightness * intensityMultiplier * MODEL_LIGHT_STRENGTH,
            0,
            MODEL_LIGHT_MAX_STRENGTH
        )
        local r = cr / 255 * strength
        local g = cg / 255 * strength
        local b = cb / 255 * strength
        local lights = record.lights

        updateLocalLight(lights[1], centerX + offsetX, centerY, lightZ, r, g, b, halfDistance, zeroDistance)
        updateLocalLight(lights[2], centerX - offsetX, centerY, lightZ, r, g, b, halfDistance, zeroDistance)
        updateLocalLight(lights[3], centerX, centerY + offsetY, lightZ, r, g, b, halfDistance, zeroDistance)
        updateLocalLight(lights[4], centerX, centerY - offsetY, lightZ, r, g, b, halfDistance, zeroDistance)
    end

    local function removeModelLightTarget(target, record)
        record = record or modelLightTargets[target]
        if not record then return end

        record.active = false
        if IsValid(target) and target.RenderOverride == record.wrapper then
            target.RenderOverride = record.downstream
        end

        modelLightTargets[target] = nil
    end

    local function clearModelLightTargets()
        for target, record in pairs(modelLightTargets) do
            removeModelLightTarget(target, record)
        end
    end

    local function markModelLightTarget(target, frame, brightness, intensityMultiplier, cr, cg, cb)
        if target:IsPlayer() or target:GetNoDraw() then return end

        local model = target:GetModel()
        if not model or model == "" or string_sub(model, 1, 1) == "*" then return end

        local record = modelLightTargets[target]
        if record and record.version == MODEL_LIGHT_WRAPPER_VERSION and target.RenderOverride == record.wrapper then
            record.active = true
            record.lastSeen = frame
            updateModelLights(record, target, brightness, intensityMultiplier, cr, cg, cb)
            return
        end

        local current = target.RenderOverride
        local original = current
        if record then
            record.active = false
            original = record.original
            if current == record.wrapper then
                current = record.downstream
            end
        end

        record = {
            active = true,
            downstream = current,
            lastSeen = frame,
            lights = createLocalLights(),
            original = original,
            version = MODEL_LIGHT_WRAPPER_VERSION
        }

        record.wrapper = function(self, flags)
            if not record.active then
                return drawModel(record, self, flags)
            end

            render.SetLocalModelLights(record.lights)
            local succeeded, result = pcall(drawModel, record, self, flags)
            render.SetLocalModelLights()

            if not succeeded then
                error(result, 0)
            end

            return result
        end

        target.RenderOverride = record.wrapper
        modelLightTargets[target] = record
        updateModelLights(record, target, brightness, intensityMultiplier, cr, cg, cb)
    end

    local function pruneModelLightTargets(frame)
        for target, record in pairs(modelLightTargets) do
            if not IsValid(target) or record.lastSeen ~= frame then
                removeModelLightTarget(target, record)
            end
        end
    end

    -- Auto refresh may leave the previous wrapper installed on live entities.
    clearModelLightTargets()
    hook.Remove("BetterLights_EffectiveEnabledChanged", "BetterLights_FireFullbrightCleanup")

    for i = 1, #FIRE_SOURCE_CLASSES do
        BL.TrackClass(FIRE_SOURCE_CLASSES[i])
    end

    BL.AddThink("BetterLights_Fire_DLight", function()
        if not cvar_enable:GetBool() then
            clearModelLightTargets()
            return
        end


        local size = math_max(0, cvar_size:GetFloat())
        local brightness = math_max(0, cvar_brightness:GetFloat())
        local decay = math_max(0, cvar_decay:GetFloat())
        local doModelLight = cvar_models_light:GetBool()
        local modelLightIntensity = math_max(0, cvar_models_light_intensity:GetFloat())
        local doFlicker = cvar_flicker_enable:GetBool()
        local flickerSpeed = cvar_flicker_speed:GetFloat()
        local flickerAmt = math_max(0, cvar_flicker_amount:GetFloat())
        local flickerSizeAmt = math_max(0, cvar_flicker_size_amount:GetFloat())
        local now = CurTime()
        local frame = FrameNumber()

        if not doModelLight then
            clearModelLightTargets()
        end

        local seenTargets = {}

        local cr, cg, cb = BL.GetColorFromCvars(cvar_col_r, cvar_col_g, cvar_col_b)

        local function handleFlame(flame)
            if IsValid(flame) then
                local target = flame:GetParent()
                if not IsValid(target) then
                    target = flame:GetOwner()
                end

                local pos
                local lightIndex
                local flickerSource
                if IsValid(target) then
                    local obbCenter = target.OBBCenter and target:OBBCenter() or Vector(0, 0, 0)
                    pos = target.LocalToWorld and target:LocalToWorld(obbCenter) or (target.WorldSpaceCenter and target:WorldSpaceCenter()) or target:GetPos()
                    lightIndex = target:EntIndex()
                    flickerSource = target
                    if seenTargets[lightIndex] then return end
                    seenTargets[lightIndex] = true
                else
                    pos = flame:GetPos()
                    lightIndex = flame:EntIndex()
                    flickerSource = flame
                end

                local b_eff, s_eff = brightness, size
                if doFlicker then
                    local brightnessSignal, sizeSignal = getFlickerSignals(flickerSource, now, flickerSpeed)
                    b_eff = math_max(0, brightness * (1 + flickerAmt * brightnessSignal))
                    s_eff = math_max(0, size * (1 + flickerSizeAmt * sizeSignal))
                end

                local lightId = FIRE_LIGHT_ID_OFFSET + lightIndex
                BL.CreateDLight(lightId, pos, cr, cg, cb, b_eff, decay, s_eff, false, { dietime = 0.16 })

                if doModelLight and IsValid(target) then
                    markModelLightTarget(target, frame, b_eff, modelLightIntensity, cr, cg, cb)
                end
            end
        end

        for i = 1, #FIRE_SOURCE_CLASSES do
            BL.ForEach(FIRE_SOURCE_CLASSES[i], handleFlame)
        end

        if doModelLight then
            pruneModelLightTargets(frame)
        end
    end)

    hook.Add("BetterLights_EffectiveEnabledChanged", "BetterLights_FireModelLightCleanup", function(enabled)
        if not enabled then
            clearModelLightTargets()
        end
    end)
end
