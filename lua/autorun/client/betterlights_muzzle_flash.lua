-- BetterLights: Muzzle Flash (client)
-- Spawns a brief DynamicLight at the muzzle when a weapon fires.

if CLIENT then
    local cvar_enable = CreateClientConVar("betterlights_muzzle_enable", "1", true, false, "Enable muzzle flash light on firing")
    local cvar_size = CreateClientConVar("betterlights_muzzle_size", "250", true, false, "Muzzle flash radius")
    local cvar_brightness = CreateClientConVar("betterlights_muzzle_brightness", "2.00", true, false, "Muzzle flash brightness")
    local cvar_decay = CreateClientConVar("betterlights_muzzle_decay", "1600", true, false, "Muzzle flash decay")

    local cvar_ar2_enable = CreateClientConVar("betterlights_muzzle_ar2_enable", "1", true, false, "Use blue tint for AR2 muzzle flashes")
    local cvar_ar2_size = CreateClientConVar("betterlights_muzzle_ar2_size", "250", true, false, "AR2 muzzle flash radius")
    local cvar_ar2_brightness = CreateClientConVar("betterlights_muzzle_ar2_brightness", "2.0", true, false, "AR2 muzzle flash brightness")

    -- Color configuration
    local cvar_col_r = CreateClientConVar("betterlights_muzzle_color_r", "255", true, false, "Generic muzzle flash color - red (0-255)")
    local cvar_col_g = CreateClientConVar("betterlights_muzzle_color_g", "170", true, false, "Generic muzzle flash color - green (0-255)")
    local cvar_col_b = CreateClientConVar("betterlights_muzzle_color_b", "90", true, false, "Generic muzzle flash color - blue (0-255)")
    local cvar_ar2_col_r = CreateClientConVar("betterlights_muzzle_ar2_color_r", "110", true, false, "AR2 muzzle flash color - red (0-255)")
    local cvar_ar2_col_g = CreateClientConVar("betterlights_muzzle_ar2_color_g", "190", true, false, "AR2 muzzle flash color - green (0-255)")
    local cvar_ar2_col_b = CreateClientConVar("betterlights_muzzle_ar2_color_b", "255", true, false, "AR2 muzzle flash color - blue (0-255)")

    local function getGenericColor()
        return math.Clamp(math.floor(cvar_col_r:GetFloat() + 0.5), 0, 255),
               math.Clamp(math.floor(cvar_col_g:GetFloat() + 0.5), 0, 255),
               math.Clamp(math.floor(cvar_col_b:GetFloat() + 0.5), 0, 255)
    end
    local function getAR2Color()
        return math.Clamp(math.floor(cvar_ar2_col_r:GetFloat() + 0.5), 0, 255),
               math.Clamp(math.floor(cvar_ar2_col_g:GetFloat() + 0.5), 0, 255),
               math.Clamp(math.floor(cvar_ar2_col_b:GetFloat() + 0.5), 0, 255)
    end

    local __bl_muzzle_counter = 0
    local function spawnFlashAt(pos, col, size, bright, decay)
        __bl_muzzle_counter = (__bl_muzzle_counter + 1) % 4096
        local id = 61000 + __bl_muzzle_counter
        local dl = DynamicLight(id)
        if not dl then return end
        dl.pos = pos
        dl.r = col.r
        dl.g = col.g
        dl.b = col.b
        dl.brightness = math.max(0, bright)
        dl.decay = math.max(0, decay)
        dl.size = math.max(0, size)
        dl.dietime = CurTime() + 0.08
    end

    net.Receive("BetterLights_MuzzleFlash", function()
        if not cvar_enable:GetBool() then return end
        local pos = net.ReadVector()
        local isAR2 = net.ReadBool()

        -- Culling disabled per user request; always spawn the flash light

        if isAR2 and cvar_ar2_enable:GetBool() then
            local r, g, b = getAR2Color()
            spawnFlashAt(pos, { r = r, g = g, b = b }, cvar_ar2_size:GetFloat(), cvar_ar2_brightness:GetFloat(), cvar_decay:GetFloat())
        else
            local r, g, b = getGenericColor()
            spawnFlashAt(pos, { r = r, g = g, b = b }, cvar_size:GetFloat(), cvar_brightness:GetFloat(), cvar_decay:GetFloat())
        end
    end)
end
