-- BetterLights: Bullet impact flashes via server-driven net event
-- Client-only receiver; server gathers hits and broadcasts them.

if CLIENT then
    -- Client config
    local cvar_enable = CreateClientConVar("betterlights_bullet_impact_enable", "1", true, false, "Enable subtle dynamic light on bullet impacts")
    local cvar_size = CreateClientConVar("betterlights_bullet_impact_size", "60", true, false, "Dynamic light radius for generic bullet impacts")
    local cvar_brightness = CreateClientConVar("betterlights_bullet_impact_brightness", "0.25", true, false, "Dynamic light brightness for generic bullet impacts")
    local cvar_decay = CreateClientConVar("betterlights_bullet_impact_decay", "1800", true, false, "Dynamic light decay for bullet impacts")

    local cvar_ar2_enable = CreateClientConVar("betterlights_bullet_impact_ar2_enable", "1", true, false, "Enable special color for AR2 bullet impacts")
    local cvar_ar2_size = CreateClientConVar("betterlights_bullet_impact_ar2_size", "70", true, false, "Dynamic light radius for AR2 bullet impacts")
    local cvar_ar2_brightness = CreateClientConVar("betterlights_bullet_impact_ar2_brightness", "0.3", true, false, "Dynamic light brightness for AR2 bullet impacts")

    local ORANGE = { r = 255, g = 160, b = 60 }
    local BLUE = { r = 110, g = 190, b = 255 }

    -- Ensure each impact gets a unique DynamicLight ID so multiple pellets don't overwrite each other.
    local __bl_dl_counter = 0
    local function spawnFlashAt(pos, col, size, bright, decay)
        __bl_dl_counter = (__bl_dl_counter + 1) % 4096
        local id = 60000 + __bl_dl_counter
        local dl = DynamicLight(id)
        if not dl then return end
        dl.pos = pos
        dl.r = col.r
        dl.g = col.g
        dl.b = col.b
        dl.brightness = math.max(0, bright)
        dl.Decay = math.max(0, decay)
        dl.size = math.max(0, size)
        dl.die = CurTime() + 0.14
    end

    net.Receive("BetterLights_BulletImpact", function()
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
