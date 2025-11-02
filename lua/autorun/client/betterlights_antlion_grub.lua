-- BetterLights: Antlion Grub green abdomen glow
-- Subtle dynamic light placed near the grub's abdomen.

if CLIENT then
    local cvar_enable = CreateClientConVar("betterlights_antlion_grub_enable", "1", true, false, "Enable green glow on Antlion Grubs")
    local cvar_size = CreateClientConVar("betterlights_antlion_grub_size", "70", true, false, "Grub light radius")
    local cvar_brightness = CreateClientConVar("betterlights_antlion_grub_brightness", "0.35", true, false, "Grub light brightness")
    local cvar_decay = CreateClientConVar("betterlights_antlion_grub_decay", "2000", true, false, "Grub light decay")

    local GREEN = { r = 120, g = 255, b = 120 }

    local function getAbdomenPos(ent)
        if not IsValid(ent) then return end
        -- Try common attachment names first
        local names = { "glow", "glow1", "abdomen", "light", "lum" }
        for _, name in ipairs(names) do
            local idx = ent:LookupAttachment(name)
            if idx and idx > 0 then
                local att = ent:GetAttachment(idx)
                if att and att.Pos then return att.Pos end
            end
        end
        -- Fallback to OBB center slightly offset forward
        local center = ent:LocalToWorld(ent:OBBCenter())
        local fwd = ent.GetForward and ent:GetForward() or Vector(1, 0, 0)
        return center + fwd * 2
    end

    hook.Add("Think", "BetterLights_AntlionGrub", function()
        if not cvar_enable:GetBool() then return end

        for _, ent in ipairs(ents.FindByClass("npc_antlion_grub")) do
            if not IsValid(ent) then goto cont end
            if ent.GetNoDraw and ent:GetNoDraw() then goto cont end

            local pos = getAbdomenPos(ent)
            if not pos then goto cont end

            local dl = DynamicLight(ent:EntIndex() + 23000)
            if dl then
                dl.pos = pos
                dl.r = GREEN.r
                dl.g = GREEN.g
                dl.b = GREEN.b
                dl.brightness = math.max(0, cvar_brightness:GetFloat())
                dl.decay = math.max(0, cvar_decay:GetFloat())
                dl.size = math.max(0, cvar_size:GetFloat())
                dl.dietime = CurTime() + 0.05
            end

            ::cont::
        end
    end)
end
