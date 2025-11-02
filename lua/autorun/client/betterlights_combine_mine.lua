-- BetterLights: Combine Mine (hopper mine) proximity light
-- Client-side only

if CLIENT then
    local cvar_enable = CreateClientConVar("betterlights_combine_mine_enable", "1", true, false, "Enable dynamic light for Combine Mines when the player is nearby")
    local cvar_range = CreateClientConVar("betterlights_combine_mine_range", "260", true, false, "Distance at which the mine starts glowing (units)")
    local cvar_size_alert = CreateClientConVar("betterlights_combine_mine_size", "140", true, false, "Dynamic light radius for alert mines")
    local cvar_brightness_alert = CreateClientConVar("betterlights_combine_mine_brightness", "1.2", true, false, "Dynamic light brightness for alert mines")
    local cvar_decay = CreateClientConVar("betterlights_combine_mine_decay", "2000", true, false, "Dynamic light decay for Combine Mines")

    local cvar_idle_enable = CreateClientConVar("betterlights_combine_mine_idle_enable", "1", true, false, "Also emit a very dim idle glow when out of range")
    local cvar_size_idle = CreateClientConVar("betterlights_combine_mine_idle_size", "80", true, false, "Dynamic light radius for idle mines")
    local cvar_brightness_idle = CreateClientConVar("betterlights_combine_mine_idle_brightness", "0.25", true, false, "Dynamic light brightness for idle mines")

    local cvar_models_elight = CreateClientConVar("betterlights_combine_mine_models_elight", "1", true, false, "Also add an entity light (elight) to light the mine model directly")
    local cvar_models_elight_size_mult = CreateClientConVar("betterlights_combine_mine_models_elight_size_mult", "1.0", true, false, "Multiplier for mine elight radius")

    local cvar_pulse_enable = CreateClientConVar("betterlights_combine_mine_pulse_enable", "1", true, false, "Enable a subtle pulse on alert mines")
    local cvar_pulse_amount = CreateClientConVar("betterlights_combine_mine_pulse_amount", "0.15", true, false, "Pulse intensity as a fraction of brightness")
    local cvar_pulse_speed = CreateClientConVar("betterlights_combine_mine_pulse_speed", "6.0", true, false, "Pulse speed for alert mines")

    local COLOR_IDLE = { r = 90, g = 180, b = 255 } -- subtle cyan/blue
    local COLOR_ALERT = { r = 255, g = 60, b = 60 } -- warning red

    hook.Add("Think", "BetterLights_CombineMine_DLight", function()
        if not cvar_enable:GetBool() then return end

        local mines = ents.FindByClass("combine_mine")
        if not mines or #mines == 0 then return end

        local lp = LocalPlayer()
        if not IsValid(lp) then return end
        local eye = lp:EyePos()

        local range = math.max(0, cvar_range:GetFloat())
        local decay = math.max(0, cvar_decay:GetFloat())

        for _, mine in ipairs(mines) do
            if IsValid(mine) then
                local pos
                if mine.OBBCenter and mine.LocalToWorld then
                    pos = mine:LocalToWorld(mine:OBBCenter())
                elseif mine.WorldSpaceCenter then
                    pos = mine:WorldSpaceCenter()
                else
                    pos = mine:GetPos()
                end

                local dist = eye:DistToSqr(pos)
                local inRange = dist <= (range * range)

                -- Choose params per state
                local size = inRange and math.max(0, cvar_size_alert:GetFloat()) or math.max(0, cvar_size_idle:GetFloat())
                local brightness = inRange and math.max(0, cvar_brightness_alert:GetFloat()) or math.max(0, cvar_brightness_idle:GetFloat())
                local col = inRange and COLOR_ALERT or COLOR_IDLE

                -- Optional pulse on alert
                if inRange and cvar_pulse_enable:GetBool() then
                    local t = CurTime()
                    local amt = math.max(0, cvar_pulse_amount:GetFloat())
                    local spd = cvar_pulse_speed:GetFloat()
                    local osc = 0.5 + 0.5 * math.sin(t * spd + mine:EntIndex())
                    brightness = math.max(0, brightness * (1 - amt + amt * (0.6 + 0.4 * osc)))
                end

                -- World light (dlight)
                local d = DynamicLight(mine:EntIndex())
                if d then
                    d.pos = pos
                    d.r = col.r
                    d.g = col.g
                    d.b = col.b
                    d.brightness = brightness
                    d.decay = decay
                    d.size = size
                    d.minlight = 0
                    d.noworld = false
                    d.nomodel = false
                    d.dietime = CurTime() + 0.1
                end

                -- Model light (elight)
                if cvar_models_elight:GetBool() then
                    local el = DynamicLight(mine:EntIndex(), true)
                    if el then
                        el.pos = pos
                        el.r = col.r
                        el.g = col.g
                        el.b = col.b
                        el.brightness = brightness
                        el.decay = decay
                        el.size = size * math.max(0, cvar_models_elight_size_mult:GetFloat())
                        el.minlight = 0
                        el.dietime = CurTime() + 0.1
                    end
                end
            end
        end
    end)
end
