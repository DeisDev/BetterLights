-- BetterLights: Antlion Guardian green glow
-- Applies a green glow to Antlion Guardian variant of npc_antlionguard using client-available heuristics.

if CLIENT then
    local cvar_enable = CreateClientConVar("betterlights_antlion_guardian_enable", "1", true, false, "Enable green glow on Antlion Guardian")
    local cvar_size = CreateClientConVar("betterlights_antlion_guardian_size", "180", true, false, "Guardian light radius")
    local cvar_brightness = CreateClientConVar("betterlights_antlion_guardian_brightness", "0.6", true, false, "Guardian light brightness")
    local cvar_decay = CreateClientConVar("betterlights_antlion_guardian_decay", "2000", true, false, "Guardian light decay")

    local cvar_debug = CreateClientConVar("betterlights_antlion_guardian_debug", "0", false, false, "Debug guardian detection prints")

    local GREEN = { r = 120, g = 255, b = 140 }

    local lastDebug = 0
    local function dbg(fmt, ...)
        if not cvar_debug:GetBool() then return end
        local now = CurTime()
        if now - lastDebug < 0.25 then return end
        lastDebug = now
        MsgC(Color(80, 200, 120), "[BetterLights][Guardian] ", color_white, string.format(fmt .. "\n", ...))
    end

    local function looksLikeGuardian(ent)
        if not IsValid(ent) then return false end
        -- Attempt to read SaveTable flags similarly to hacked rollermine heuristics
        local ok, st = pcall(function() return ent:GetSaveTable() end)
        if ok and type(st) == "table" then
            for k, v in pairs(st) do
                local lk = tostring(k):lower()
                if lk:find("guardian", 1, true) then
                    if v == true or v == 1 or v == "1" then
                        dbg("SaveTable guardian flag %s=%s", lk, tostring(v))
                        return true
                    end
                end
            end
        end

        -- Check NWBools that mods might set
        local nwNames = { "guardian", "isguardian", "antlionguardian", "is_guardian" }
        for _, n in ipairs(nwNames) do
            if ent.GetNWBool and ent:GetNWBool(n, false) then
                dbg("NWBool %s=true", n)
                return true
            end
        end

        -- Skin heuristic: guardians often use an alternate glowing skin
        local skin = ent:GetSkin() or 0
        if skin and skin > 0 then
            dbg("Skin heuristic matched (skin=%s)", tostring(skin))
            return true
        end

        -- Name heuristic (targetname); guard for missing GetName on some clients/entities
        local nm = ""
        if ent.GetName then
            local ok, name = pcall(ent.GetName, ent)
            if ok and isstring(name) then nm = string.lower(name) end
        end
        if nm ~= "" and string.find(nm, "guardian", 1, true) then
            dbg("Targetname heuristic matched (%s)", nm)
            return true
        end

        -- Fallback: try disposition to antlion faction? Not reliable clientside; skip.
        return false
    end

    local function getCorePos(ent)
        -- Try a central body attachment if present
        local names = { "chest", "body", "abdomen", "glow" }
        for _, name in ipairs(names) do
            local idx = ent:LookupAttachment(name)
            if idx and idx > 0 then
                local att = ent:GetAttachment(idx)
                if att and att.Pos then return att.Pos end
            end
        end
        return ent:LocalToWorld(ent:OBBCenter())
    end

    hook.Add("Think", "BetterLights_AntlionGuardian", function()
        if not cvar_enable:GetBool() then return end

        for _, ent in ipairs(ents.FindByClass("npc_antlionguard")) do
            if not IsValid(ent) then goto cont end
            if ent.GetNoDraw and ent:GetNoDraw() then goto cont end
            if not looksLikeGuardian(ent) then goto cont end

            local pos = getCorePos(ent)
            local dl = DynamicLight(ent:EntIndex() + 23100)
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
