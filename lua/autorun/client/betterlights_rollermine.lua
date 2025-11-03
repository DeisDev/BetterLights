-- BetterLights: Rollermine (npc_rollermine) glow
-- Client-side only

if CLIENT then
    -- Signal to any legacy scripts that rollermine handling is unified here
    BL_ROLLERMINE_UNIFIED = true
    local cvar_enable = CreateClientConVar("betterlights_rollermine_enable", "1", true, false, "Enable dynamic light for Rollermines (npc_rollermine)")
    local cvar_size = CreateClientConVar("betterlights_rollermine_size", "110", true, false, "Dynamic light radius for Rollermines")
    local cvar_brightness = CreateClientConVar("betterlights_rollermine_brightness", "0.6", true, false, "Dynamic light brightness for Rollermines")
    local cvar_decay = CreateClientConVar("betterlights_rollermine_decay", "2000", true, false, "Dynamic light decay for Rollermines")
    local cvar_models_elight = CreateClientConVar("betterlights_rollermine_models_elight", "1", true, false, "Also add an entity light (elight) to light the rollermine model directly")
    local cvar_models_elight_size_mult = CreateClientConVar("betterlights_rollermine_models_elight_size_mult", "1.0", true, false, "Multiplier for rollermine elight radius")

    -- Hacked rollermine convars
    local cvar_h_enable = CreateClientConVar("betterlights_rollermine_hacked_enable", "1", true, false, "Enable dynamic light for Hacked Rollermines (ally)")
    local cvar_h_size = CreateClientConVar("betterlights_rollermine_hacked_size", "110", true, false, "Dynamic light radius for Hacked Rollermines")
    local cvar_h_brightness = CreateClientConVar("betterlights_rollermine_hacked_brightness", "0.6", true, false, "Dynamic light brightness for Hacked Rollermines")
    local cvar_h_decay = CreateClientConVar("betterlights_rollermine_hacked_decay", "2000", true, false, "Dynamic light decay for Hacked Rollermines")
    local cvar_h_models_elight = CreateClientConVar("betterlights_rollermine_hacked_models_elight", "1", true, false, "Also add an entity light (elight) to light the hacked rollermine model directly")
    local cvar_h_models_elight_mult = CreateClientConVar("betterlights_rollermine_hacked_models_elight_size_mult", "1.0", true, false, "Multiplier for hacked rollermine elight radius")
    local cvar_debug = CreateClientConVar("betterlights_rollermine_debug", "0", true, false, "Debug hacked rollermine detection (prints to console)")

    -- Color mapping by skin:
    -- 0 = blue (default), 1 = yellow, 2 = red
    local function BL_GetRollermineColor(ent)
        local skin = 0
        if ent.GetSkin then
            local ok, s = pcall(ent.GetSkin, ent)
            if ok and type(s) == "number" then skin = s end
        end
        if skin == 1 then
            return { r = 255, g = 220, b = 60 } -- yellow
        elseif skin == 2 then
            return { r = 255, g = 80, b = 80 } -- red
        else
            return { r = 110, g = 190, b = 255 } -- blue (default)
        end
    end

    -- Detect hacked state on an npc_rollermine so we can skip those here
    local function BL_IsRollermineHacked(ent)
        if not IsValid(ent) then return false end
        -- 1) Common NWBools
        if ent.GetNWBool then
            if ent:GetNWBool("m_bHacked", false) or ent:GetNWBool("hacked", false) or ent:GetNWBool("isHacked", false)
                or ent:GetNWBool("friendly", false) or ent:GetNWBool("is_friendly", false) or ent:GetNWBool("IsFriendly", false) then
                return true
            end
        end
        -- 2) Save table flags
        if ent.GetSaveTable then
            local ok, st = pcall(ent.GetSaveTable, ent)
            if ok and st then
                if st.m_bHacked == true or st.m_bIsHacked == true or st.hacked == true then
                    return true
                end
            end
        end
        -- 3) Relationship check
        local lp = LocalPlayer and LocalPlayer() or nil
        if IsValid(lp) and ent.Disposition then
            local ok, disp = pcall(function() return ent:Disposition(lp) end)
            if ok and disp == D_LI then return true end
        end
        return false
    end

    hook.Add("Think", "BetterLights_Rollermine_DLight", function()
        if not cvar_enable:GetBool() and not cvar_h_enable:GetBool() then return end

        local entsList = ents.FindByClass("npc_rollermine")
        if not entsList or #entsList == 0 then return end

        

        for _, ent in ipairs(entsList) do
            if IsValid(ent) then
                local hacked = BL_IsRollermineHacked(ent)
                if hacked and not cvar_h_enable:GetBool() then goto CONTINUE end
                if (not hacked) and not cvar_enable:GetBool() then goto CONTINUE end
                local idx = ent:EntIndex()
                local pos
                if ent.OBBCenter and ent.LocalToWorld then
                    pos = ent:LocalToWorld(ent:OBBCenter())
                elseif ent.WorldSpaceCenter then
                    pos = ent:WorldSpaceCenter()
                else
                    pos = ent:GetPos()
                end

                if cvar_debug:GetBool() and hacked then
                    ent._bl_lastHackDbg = ent._bl_lastHackDbg or 0
                    local now = CurTime()
                    if now - (ent._bl_lastHackDbg or 0) > 1 then
                        ent._bl_lastHackDbg = now
                        print(string.format("[BetterLights] Rollermine #%d hacked=true skin=%s", ent:EntIndex(), tostring(ent.GetSkin and ent:GetSkin())))
                    end
                end

                local col
                local size
                local brightness
                local decay
                local use_elight
                local el_mult
                if hacked then
                    col = { r = 255, g = 160, b = 60 } -- orange for hacked
                    size = math.max(0, cvar_h_size:GetFloat())
                    brightness = math.max(0, cvar_h_brightness:GetFloat())
                    decay = math.max(0, cvar_h_decay:GetFloat())
                    use_elight = cvar_h_models_elight:GetBool()
                    el_mult = math.max(0, cvar_h_models_elight_mult:GetFloat())
                else
                    col = BL_GetRollermineColor(ent)
                    size = math.max(0, cvar_size:GetFloat())
                    brightness = math.max(0, cvar_brightness:GetFloat())
                    decay = math.max(0, cvar_decay:GetFloat())
                    use_elight = cvar_models_elight:GetBool()
                    el_mult = math.max(0, cvar_models_elight_size_mult:GetFloat())
                end
                local d = DynamicLight(idx)
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

                if use_elight then
                    local el = DynamicLight(idx, true)
                    if el then
                        el.pos = pos
                        el.r = col.r
                        el.g = col.g
                        el.b = col.b
                        el.brightness = brightness
                        el.decay = decay
                        el.size = size * el_mult
                        el.minlight = 0
                        el.dietime = CurTime() + 0.1
                    end
                end
                ::CONTINUE::
            end
        end
    end)
end
