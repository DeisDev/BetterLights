-- BetterLights: Rollermine (Hacked) glow
-- Client-side only

if CLIENT then
    local cvar_enable = CreateClientConVar("betterlights_rollermine_hacked_enable", "1", true, false, "Enable dynamic light for Hacked Rollermines (npc_rollermine with hacked flag)")
    local cvar_debug = CreateClientConVar("betterlights_rollermine_debug", "0", true, false, "Debug hacked rollermine detection (prints to console)")
    local cvar_size = CreateClientConVar("betterlights_rollermine_hacked_size", "110", true, false, "Dynamic light radius for Hacked Rollermines")
    local cvar_brightness = CreateClientConVar("betterlights_rollermine_hacked_brightness", "0.6", true, false, "Dynamic light brightness for Hacked Rollermines")
    local cvar_decay = CreateClientConVar("betterlights_rollermine_hacked_decay", "2000", true, false, "Dynamic light decay for Hacked Rollermines")
    local cvar_models_elight = CreateClientConVar("betterlights_rollermine_hacked_models_elight", "1", true, false, "Also add an entity light (elight) to light the hacked rollermine model directly")
    local cvar_models_elight_size_mult = CreateClientConVar("betterlights_rollermine_hacked_models_elight_size_mult", "1.0", true, false, "Multiplier for hacked rollermine elight radius")

    -- Orange hue (hacked rollermine request)
    local ORANGE = { r = 255, g = 160, b = 60 }

    -- Detect hacked state on an npc_rollermine
    local function BL_IsRollermineHacked(ent)
        if not IsValid(ent) then return false end
        -- 1) Skin heuristic: Friendly rollermine typically uses an alternate (orange) skin
        if ent.GetSkin and ent:GetSkin() and ent:GetSkin() > 0 then
            return true
        end
        -- 2) Common NWBools used by gamemodes/addons
        if ent.GetNWBool then
            if ent:GetNWBool("m_bHacked", false) or ent:GetNWBool("hacked", false) or ent:GetNWBool("isHacked", false)
                or ent:GetNWBool("friendly", false) or ent:GetNWBool("is_friendly", false) or ent:GetNWBool("IsFriendly", false) then
                return true
            end
        end
        -- 3) Save table flags (may only exist serverside, but try anyway)
        if ent.GetSaveTable then
            local ok, st = pcall(ent.GetSaveTable, ent)
            if ok and st then
                if st.m_bHacked == true or st.m_bIsHacked == true or st.hacked == true then
                    return true
                end
            end
        end
        -- 4) Relationship check to the local player (LIKE implies hacked/ally)
        local lp = LocalPlayer and LocalPlayer() or nil
        if IsValid(lp) and ent.Disposition then
            local ok, disp = pcall(function() return ent:Disposition(lp) end)
            if ok and disp == D_LI then return true end
        end
        return false
    end

    hook.Add("Think", "BetterLights_Rollermine_Hacked_DLight", function()
        if not cvar_enable:GetBool() then return end

        -- Hacked rollermines are the same class (npc_rollermine) with a hacked flag/relationship
        local entsList = ents.FindByClass("npc_rollermine")
        if not entsList or #entsList == 0 then return end

        local size = math.max(0, cvar_size:GetFloat())
        local brightness = math.max(0, cvar_brightness:GetFloat())
        local decay = math.max(0, cvar_decay:GetFloat())

        for _, ent in ipairs(entsList) do
            if IsValid(ent) then
                local hacked = BL_IsRollermineHacked(ent)
                if cvar_debug:GetBool() then
                    -- Throttle prints: only once per second per entity
                    ent._bl_lastHackDbg = ent._bl_lastHackDbg or 0
                    local now = CurTime()
                    if now - (ent._bl_lastHackDbg or 0) > 1 then
                        ent._bl_lastHackDbg = now
                        print(string.format("[BetterLights] Rollermine #%d hacked=%s skin=%s", ent:EntIndex(), tostring(hacked), tostring(ent.GetSkin and ent:GetSkin())))
                    end
                end
                if not hacked then goto CONTINUE end
                local idx = ent:EntIndex()
                local pos
                if ent.OBBCenter and ent.LocalToWorld then
                    pos = ent:LocalToWorld(ent:OBBCenter())
                elseif ent.WorldSpaceCenter then
                    pos = ent:WorldSpaceCenter()
                else
                    pos = ent:GetPos()
                end

                local d = DynamicLight(idx)
                if d then
                    d.pos = pos
                    d.r = ORANGE.r
                    d.g = ORANGE.g
                    d.b = ORANGE.b
                    d.brightness = brightness
                    d.decay = decay
                    d.size = size
                    d.minlight = 0
                    d.noworld = false
                    d.nomodel = false
                    d.dietime = CurTime() + 0.1
                end

                if cvar_models_elight:GetBool() then
                    local el = DynamicLight(idx, true)
                    if el then
                        el.pos = pos
                        el.r = ORANGE.r
                        el.g = ORANGE.g
                        el.b = ORANGE.b
                        el.brightness = brightness
                        el.decay = decay
                        el.size = size * math.max(0, cvar_models_elight_size_mult:GetFloat())
                        el.minlight = 0
                        el.dietime = CurTime() + 0.1
                    end
                end
                ::CONTINUE::
            end
        end
    end)
end
