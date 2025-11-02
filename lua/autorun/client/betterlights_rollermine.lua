-- BetterLights: Rollermine (npc_rollermine) glow
-- Client-side only

if CLIENT then
    local cvar_enable = CreateClientConVar("betterlights_rollermine_enable", "1", true, false, "Enable dynamic light for Rollermines (npc_rollermine)")
    local cvar_size = CreateClientConVar("betterlights_rollermine_size", "110", true, false, "Dynamic light radius for Rollermines")
    local cvar_brightness = CreateClientConVar("betterlights_rollermine_brightness", "0.6", true, false, "Dynamic light brightness for Rollermines")
    local cvar_decay = CreateClientConVar("betterlights_rollermine_decay", "2000", true, false, "Dynamic light decay for Rollermines")
    local cvar_models_elight = CreateClientConVar("betterlights_rollermine_models_elight", "1", true, false, "Also add an entity light (elight) to light the rollermine model directly")
    local cvar_models_elight_size_mult = CreateClientConVar("betterlights_rollermine_models_elight_size_mult", "1.0", true, false, "Multiplier for rollermine elight radius")

    -- Neutral blue hue
    local BLUE = { r = 110, g = 190, b = 255 }

    -- Detect hacked state on an npc_rollermine so we can skip those here
    local function BL_IsRollermineHacked(ent)
        if not IsValid(ent) then return false end
        -- 1) Skin heuristic
        if ent.GetSkin and ent:GetSkin() and ent:GetSkin() > 0 then
            return true
        end
        -- 2) Common NWBools
        if ent.GetNWBool then
            if ent:GetNWBool("m_bHacked", false) or ent:GetNWBool("hacked", false) or ent:GetNWBool("isHacked", false)
                or ent:GetNWBool("friendly", false) or ent:GetNWBool("is_friendly", false) or ent:GetNWBool("IsFriendly", false) then
                return true
            end
        end
        -- 3) Save table flags
        if ent.GetSaveTable then
            local ok, st = pcall(ent.GetSaveTable, ent)
            if ok and st then
                if st.m_bHacked == true or st.m_bIsHacked == true or st.hacked == true then
                    return true
                end
            end
        end
        -- 4) Relationship check
        local lp = LocalPlayer and LocalPlayer() or nil
        if IsValid(lp) and ent.Disposition then
            local ok, disp = pcall(function() return ent:Disposition(lp) end)
            if ok and disp == D_LI then return true end
        end
        return false
    end

    hook.Add("Think", "BetterLights_Rollermine_DLight", function()
        if not cvar_enable:GetBool() then return end

        local entsList = ents.FindByClass("npc_rollermine")
        if not entsList or #entsList == 0 then return end

        local size = math.max(0, cvar_size:GetFloat())
        local brightness = math.max(0, cvar_brightness:GetFloat())
        local decay = math.max(0, cvar_decay:GetFloat())

        for _, ent in ipairs(entsList) do
            if IsValid(ent) then
                -- Skip hacked ones here; they'll be handled by the hacked script
                if BL_IsRollermineHacked(ent) then goto CONTINUE end
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
                    d.r = BLUE.r
                    d.g = BLUE.g
                    d.b = BLUE.b
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
                        el.r = BLUE.r
                        el.g = BLUE.g
                        el.b = BLUE.b
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
