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

    local ORANGE = { r = 255, g = 170, b = 90 }
    local BLUE = { r = 110, g = 190, b = 255 }

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
        dl.Decay = math.max(0, decay)
        dl.size = math.max(0, size)
        dl.die = CurTime() + 0.08
    end

    net.Receive("BetterLights_MuzzleFlash", function()
        if not cvar_enable:GetBool() then return end
        local pos = net.ReadVector()
        local isAR2 = net.ReadBool()

        if isAR2 and cvar_ar2_enable:GetBool() then
            spawnFlashAt(pos, BLUE, cvar_ar2_size:GetFloat(), cvar_ar2_brightness:GetFloat(), cvar_decay:GetFloat())
        else
            spawnFlashAt(pos, ORANGE, cvar_size:GetFloat(), cvar_brightness:GetFloat(), cvar_decay:GetFloat())
        end
    end)
end
