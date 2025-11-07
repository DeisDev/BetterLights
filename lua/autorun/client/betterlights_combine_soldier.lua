-- BetterLights: Combine Soldier Face Glow
-- Adds glow to Combine soldier face visors (color varies by type and skin)

if CLIENT then
    BetterLights = BetterLights or {}
    local BL = BetterLights
    
    -- ConVars
    local cvars = BL.CreateConVarSet("bl_combine_soldier", {
        enable = 1,
        size = 40,
        brightness = 0.5,
        decay = 1500,
        r = 80, g = 120, b = 255  -- Default blue (unused, color determined by variant)
    })
    
    -- Track Combine soldiers
    BL.TrackClass("npc_combine_s")
    
    -- Define color variants by model and skin
    local variants = {
        { model = "combine_super_soldier", default = {255, 60, 60} },  -- Elite: red
        { model = "police", skinMap = {[0] = {255, 220, 60}, [1] = {255, 60, 60}} },  -- Prison: yellow/red
        { model = "combine_soldier", skinMap = {[0] = {80, 120, 255}, [1] = {255, 140, 40}} }  -- Standard: blue/orange
    }
    
    -- Main lighting logic
    BL.AddThink("BetterLights_CombineSoldier", function()
        if not cvars.enable:GetBool() then return end
        
        -- Cache settings once per frame
        local size = math.max(0, cvars.size:GetFloat())
        local brightness = math.max(0, cvars.brightness:GetFloat())
        local decay = math.max(0, cvars.decay:GetFloat())
        
        BL.ForEach("npc_combine_s", function(ent)
            -- Detect variant and get color
            local color = BL.DetectModelVariant(ent, variants) or {80, 120, 255}
            
            -- Create light from eyes attachment
            BL.CreateLightFromAttachment(ent, {"eyes"}, 
                color[1], color[2], color[3], brightness, decay, size, false)
        end)
    end)
end
