-- BetterLights: Spawnmenu integration
-- Adds a "Better Lights" tab with Client and Server categories and per-feature panels.

if CLIENT then
    local function addResetButton(panel, defaults)
        local btn = panel:Button("Reset to Defaults")
        btn.DoClick = function()
            for cvar, def in pairs(defaults) do
                RunConsoleCommand(cvar, tostring(def))
            end
        end
    end

    local function addClientPanels()
        -- Combine AR2 orb
        spawnmenu.AddToolMenuOption("Better Lights", "Client", "BL_CombineBall", "Combine AR2 Orb", "", "", function(panel)
            panel:ClearControls()
            panel:Help("Blue/cyan light for prop_combine_ball")
            panel:CheckBox("Enable", "betterlights_combineball_enable")
            panel:NumSlider("Radius", "betterlights_combineball_size", 0, 800, 0)
            panel:NumSlider("Brightness", "betterlights_combineball_brightness", 0, 10, 2)
            panel:NumSlider("Decay", "betterlights_combineball_decay", 0, 5000, 0)
            addResetButton(panel, {
                betterlights_combineball_enable = 1,
                betterlights_combineball_size = 320,
                betterlights_combineball_brightness = 2.5,
                betterlights_combineball_decay = 2000,
            })
        end)

        -- Bullet Impacts
        spawnmenu.AddToolMenuOption("Better Lights", "Client", "BL_BulletImpacts", "Bullet Impacts", "", "", function(panel)
            panel:ClearControls()
            panel:Help("Subtle flashes when bullets hit surfaces. AR2 impacts use a blue tint; others use warm orange.")
            panel:CheckBox("Enable", "betterlights_bullet_impact_enable")
            panel:NumSlider("Generic radius", "betterlights_bullet_impact_size", 0, 300, 0)
            panel:NumSlider("Generic brightness", "betterlights_bullet_impact_brightness", 0, 2, 2)
            panel:NumSlider("Decay", "betterlights_bullet_impact_decay", 0, 5000, 0)
            panel:Help("AR2 (Combine Rifle) overrides")
            panel:CheckBox("Enable AR2 tint", "betterlights_bullet_impact_ar2_enable")
            panel:NumSlider("AR2 radius", "betterlights_bullet_impact_ar2_size", 0, 300, 0)
            panel:NumSlider("AR2 brightness", "betterlights_bullet_impact_ar2_brightness", 0, 2, 2)
            addResetButton(panel, {
                betterlights_bullet_impact_enable = 1,
                betterlights_bullet_impact_size = 60,
                betterlights_bullet_impact_brightness = 0.25,
                betterlights_bullet_impact_decay = 1800,
                betterlights_bullet_impact_ar2_enable = 1,
                betterlights_bullet_impact_ar2_size = 70,
                betterlights_bullet_impact_ar2_brightness = 0.3,
            })
        end)

        -- Muzzle Flash
        spawnmenu.AddToolMenuOption("Better Lights", "Client", "BL_MuzzleFlash", "Muzzle Flash", "", "", function(panel)
            panel:ClearControls()
            panel:Help("Brief flash at the muzzle when a weapon fires. AR2 uses a blue tint.")
            panel:CheckBox("Enable", "betterlights_muzzle_enable")
            panel:NumSlider("Generic radius", "betterlights_muzzle_size", 0, 300, 0)
            panel:NumSlider("Generic brightness", "betterlights_muzzle_brightness", 0, 2, 2)
            panel:NumSlider("Decay", "betterlights_muzzle_decay", 0, 5000, 0)
            panel:Help("AR2 (Combine Rifle) overrides")
            panel:CheckBox("Enable AR2 tint", "betterlights_muzzle_ar2_enable")
            panel:NumSlider("AR2 radius", "betterlights_muzzle_ar2_size", 0, 300, 0)
            panel:NumSlider("AR2 brightness", "betterlights_muzzle_ar2_brightness", 0, 2, 2)
            addResetButton(panel, {
                betterlights_muzzle_enable = 1,
                betterlights_muzzle_size = 250,
                betterlights_muzzle_brightness = 2.0,
                betterlights_muzzle_decay = 1600,
                betterlights_muzzle_ar2_enable = 1,
                betterlights_muzzle_ar2_size = 250,
                betterlights_muzzle_ar2_brightness = 2.0,
            })
        end)

        -- Crossbow bolt
        spawnmenu.AddToolMenuOption("Better Lights", "Client", "BL_Bolt", "Crossbow Bolt", "", "", function(panel)
            panel:ClearControls()
            panel:Help("Warm orange light for crossbow bolts")
            panel:CheckBox("Enable", "betterlights_bolt_enable")
            panel:NumSlider("Radius", "betterlights_bolt_size", 0, 800, 0)
            panel:NumSlider("Brightness", "betterlights_bolt_brightness", 0, 10, 2)
            panel:NumSlider("Decay", "betterlights_bolt_decay", 0, 5000, 0)
            addResetButton(panel, {
                betterlights_bolt_enable = 1,
                betterlights_bolt_size = 220,
                betterlights_bolt_brightness = 0.96,
                betterlights_bolt_decay = 2000,
            })
        end)

        -- Crossbow (held)
        spawnmenu.AddToolMenuOption("Better Lights", "Client", "BL_CrossbowHeld", "Crossbow (Held)", "", "", function(panel)
            panel:ClearControls()
            panel:Help("Subtle orange light while holding the Crossbow")
            panel:CheckBox("Enable", "betterlights_crossbow_hold_enable")
            panel:CheckBox("Only when bolt loaded", "betterlights_crossbow_hold_require_loaded")
            panel:NumSlider("Radius", "betterlights_crossbow_hold_size", 0, 300, 0)
            panel:NumSlider("Brightness", "betterlights_crossbow_hold_brightness", 0, 5, 2)
            panel:NumSlider("Decay", "betterlights_crossbow_hold_decay", 0, 5000, 0)
            addResetButton(panel, {
                betterlights_crossbow_hold_enable = 1,
                betterlights_crossbow_hold_require_loaded = 1,
                betterlights_crossbow_hold_size = 30,
                betterlights_crossbow_hold_brightness = 0.32,
                betterlights_crossbow_hold_decay = 2000,
            })
        end)

        -- RPG rocket
        spawnmenu.AddToolMenuOption("Better Lights", "Client", "BL_RPG", "RPG Rocket", "", "", function(panel)
            panel:ClearControls()
            panel:Help("Warm flame light for RPG rockets in flight")
            panel:CheckBox("Enable", "betterlights_rpg_enable")
            panel:NumSlider("Radius", "betterlights_rpg_size", 0, 800, 0)
            panel:NumSlider("Brightness", "betterlights_rpg_brightness", 0, 10, 2)
            panel:NumSlider("Decay", "betterlights_rpg_decay", 0, 5000, 0)
            addResetButton(panel, {
                betterlights_rpg_enable = 1,
                betterlights_rpg_size = 280,
                betterlights_rpg_brightness = 2.2,
                betterlights_rpg_decay = 2000,
            })
        end)

        -- Burning entities
        spawnmenu.AddToolMenuOption("Better Lights", "Client", "BL_Fire", "Burning Entities", "", "", function(panel)
            panel:ClearControls()
            panel:Help("Light for entities on fire, with optional flicker and model-only elight")
            panel:CheckBox("Enable", "betterlights_fire_enable")
            panel:NumSlider("Radius", "betterlights_fire_size", 0, 800, 0)
            panel:NumSlider("Brightness", "betterlights_fire_brightness", 0, 10, 2)
            panel:NumSlider("Decay", "betterlights_fire_decay", 0, 5000, 0)
            panel:CheckBox("Add model elight", "betterlights_fire_models_elight")
            panel:NumSlider("Model elight radius x", "betterlights_fire_models_elight_size_mult", 0, 3, 2)
            panel:CheckBox("Flicker", "betterlights_fire_flicker_enable")
            panel:NumSlider("Flicker amount", "betterlights_fire_flicker_amount", 0, 1, 2)
            panel:NumSlider("Flicker size amt", "betterlights_fire_flicker_size_amount", 0, 1, 2)
            panel:NumSlider("Flicker speed", "betterlights_fire_flicker_speed", 0, 30, 1)
            addResetButton(panel, {
                betterlights_fire_enable = 1,
                betterlights_fire_size = 160,
                betterlights_fire_brightness = 5.2,
                betterlights_fire_decay = 2000,
                betterlights_fire_models_elight = 1,
                betterlights_fire_models_elight_size_mult = 1.0,
                betterlights_fire_flicker_enable = 1,
                betterlights_fire_flicker_amount = 0.35,
                betterlights_fire_flicker_size_amount = 0.12,
                betterlights_fire_flicker_speed = 11.5,
            })
        end)

        -- Frag grenade
        spawnmenu.AddToolMenuOption("Better Lights", "Client", "BL_Grenade", "Frag Grenade", "", "", function(panel)
            panel:ClearControls()
            panel:Help("Dim red light for thrown frag grenades")
            panel:CheckBox("Enable", "betterlights_grenade_enable")
            panel:NumSlider("Radius", "betterlights_grenade_size", 0, 400, 0)
            panel:NumSlider("Brightness", "betterlights_grenade_brightness", 0, 5, 2)
            panel:NumSlider("Decay", "betterlights_grenade_decay", 0, 5000, 0)
            panel:CheckBox("Add model elight", "betterlights_grenade_models_elight")
            panel:NumSlider("Model elight radius x", "betterlights_grenade_models_elight_size_mult", 0, 3, 2)
            addResetButton(panel, {
                betterlights_grenade_enable = 1,
                betterlights_grenade_size = 80,
                betterlights_grenade_brightness = 0.9,
                betterlights_grenade_decay = 1800,
                betterlights_grenade_models_elight = 1,
                betterlights_grenade_models_elight_size_mult = 1.0,
            })
        end)

        -- Combine Mine (hopper mine)
        spawnmenu.AddToolMenuOption("Better Lights", "Client", "BL_CombineMine", "Combine Mine", "", "", function(panel)
            panel:ClearControls()
            panel:Help("Idle blue glow; red alert glow when you're within range")
            panel:CheckBox("Enable", "betterlights_combine_mine_enable")
            panel:NumSlider("Alert radius (units)", "betterlights_combine_mine_range", 0, 1024, 0)
            panel:NumSlider("Alert radius size", "betterlights_combine_mine_size", 0, 400, 0)
            panel:NumSlider("Alert brightness", "betterlights_combine_mine_brightness", 0, 5, 2)
            panel:NumSlider("Decay", "betterlights_combine_mine_decay", 0, 5000, 0)
            panel:CheckBox("Idle glow", "betterlights_combine_mine_idle_enable")
            panel:NumSlider("Idle radius size", "betterlights_combine_mine_idle_size", 0, 400, 0)
            panel:NumSlider("Idle brightness", "betterlights_combine_mine_idle_brightness", 0, 2, 2)
            panel:CheckBox("Pulse on alert", "betterlights_combine_mine_pulse_enable")
            panel:NumSlider("Pulse amount", "betterlights_combine_mine_pulse_amount", 0, 1, 2)
            panel:NumSlider("Pulse speed", "betterlights_combine_mine_pulse_speed", 0, 30, 1)
            panel:CheckBox("Add model elight", "betterlights_combine_mine_models_elight")
            panel:NumSlider("Model elight radius x", "betterlights_combine_mine_models_elight_size_mult", 0, 3, 2)
            addResetButton(panel, {
                betterlights_combine_mine_enable = 1,
                betterlights_combine_mine_range = 260,
                betterlights_combine_mine_size = 140,
                betterlights_combine_mine_brightness = 1.2,
                betterlights_combine_mine_decay = 2000,
                betterlights_combine_mine_idle_enable = 1,
                betterlights_combine_mine_idle_size = 80,
                betterlights_combine_mine_idle_brightness = 0.25,
                betterlights_combine_mine_pulse_enable = 1,
                betterlights_combine_mine_pulse_amount = 0.15,
                betterlights_combine_mine_pulse_speed = 6.0,
                betterlights_combine_mine_models_elight = 1,
                betterlights_combine_mine_models_elight_size_mult = 1.0,
            })
        end)

        -- Physgun
        spawnmenu.AddToolMenuOption("Better Lights", "Client", "BL_Physgun", "Physics Gun", "", "", function(panel)
            panel:ClearControls()
            panel:Help("Light that matches your Weapon Color; wall-safe world placement")
            panel:CheckBox("Enable", "betterlights_physgun_enable")
            panel:NumSlider("Radius", "betterlights_physgun_size", 0, 300, 0)
            panel:NumSlider("Brightness", "betterlights_physgun_brightness", 0, 5, 2)
            panel:NumSlider("Decay", "betterlights_physgun_decay", 0, 5000, 0)
            panel:CheckBox("Add model elight", "betterlights_physgun_models_elight")
            panel:NumSlider("Model elight radius x", "betterlights_physgun_models_elight_size_mult", 0, 3, 2)
            addResetButton(panel, {
                betterlights_physgun_enable = 1,
                betterlights_physgun_size = 33,
                betterlights_physgun_brightness = 0.3,
                betterlights_physgun_decay = 2000,
                betterlights_physgun_models_elight = 1,
                betterlights_physgun_models_elight_size_mult = 1.0,
            })
        end)

        -- Gravity Gun
        spawnmenu.AddToolMenuOption("Better Lights", "Client", "BL_GravityGun", "Gravity Gun", "", "", function(panel)
            panel:ClearControls()
            panel:Help("Warm orange light from the physcannon; wall-safe world placement")
            panel:CheckBox("Enable", "betterlights_gravitygun_enable")
            panel:NumSlider("Radius", "betterlights_gravitygun_size", 0, 300, 0)
            panel:NumSlider("Brightness", "betterlights_gravitygun_brightness", 0, 5, 2)
            panel:NumSlider("Decay", "betterlights_gravitygun_decay", 0, 5000, 0)
            panel:CheckBox("Add model elight", "betterlights_gravitygun_models_elight")
            panel:NumSlider("Model elight radius x", "betterlights_gravitygun_models_elight_size_mult", 0, 3, 2)
            addResetButton(panel, {
                betterlights_gravitygun_enable = 1,
                betterlights_gravitygun_size = 36,
                betterlights_gravitygun_brightness = 0.35,
                betterlights_gravitygun_decay = 2000,
                betterlights_gravitygun_models_elight = 1,
                betterlights_gravitygun_models_elight_size_mult = 1.0,
            })
        end)

        -- Tool Gun
        spawnmenu.AddToolMenuOption("Better Lights", "Client", "BL_ToolGun", "Tool Gun", "", "", function(panel)
            panel:ClearControls()
            panel:Help("Small white light at the tip; wall-safe world placement")
            panel:CheckBox("Enable", "betterlights_toolgun_enable")
            panel:NumSlider("Radius", "betterlights_toolgun_size", 0, 300, 0)
            panel:NumSlider("Brightness", "betterlights_toolgun_brightness", 0, 5, 2)
            panel:NumSlider("Decay", "betterlights_toolgun_decay", 0, 5000, 0)
            panel:CheckBox("Add model elight", "betterlights_toolgun_models_elight")
            panel:NumSlider("Model elight radius x", "betterlights_toolgun_models_elight_size_mult", 0, 3, 2)
            addResetButton(panel, {
                betterlights_toolgun_enable = 1,
                betterlights_toolgun_size = 28,
                betterlights_toolgun_brightness = 0.225,
                betterlights_toolgun_decay = 2000,
                betterlights_toolgun_models_elight = 1,
                betterlights_toolgun_models_elight_size_mult = 1.0,
            })
        end)

        -- Helicopter Bombs
        spawnmenu.AddToolMenuOption("Better Lights", "Client", "BL_HeliBomb", "Helicopter Bomb", "", "", function(panel)
            panel:ClearControls()
            panel:Help("Red glow on helicopter bombs and a brief flash on explosion")
            panel:CheckBox("Enable", "betterlights_heli_bomb_enable")
            panel:NumSlider("Radius", "betterlights_heli_bomb_size", 0, 400, 0)
            panel:NumSlider("Brightness", "betterlights_heli_bomb_brightness", 0, 5, 2)
            panel:NumSlider("Decay", "betterlights_heli_bomb_decay", 0, 5000, 0)
            panel:CheckBox("Add model elight", "betterlights_heli_bomb_models_elight")
            panel:NumSlider("Model elight radius x", "betterlights_heli_bomb_models_elight_size_mult", 0, 3, 2)
            panel:Help("Explosion Flash")
            panel:CheckBox("Flash on explosion", "betterlights_heli_bomb_flash_enable")
            panel:NumSlider("Flash radius", "betterlights_heli_bomb_flash_size", 0, 800, 0)
            panel:NumSlider("Flash brightness", "betterlights_heli_bomb_flash_brightness", 0, 10, 2)
            panel:NumSlider("Flash time (s)", "betterlights_heli_bomb_flash_time", 0, 1, 2)
            addResetButton(panel, {
                betterlights_heli_bomb_enable = 1,
                betterlights_heli_bomb_size = 140,
                betterlights_heli_bomb_brightness = 1.4,
                betterlights_heli_bomb_decay = 2000,
                betterlights_heli_bomb_models_elight = 1,
                betterlights_heli_bomb_models_elight_size_mult = 1.0,
                betterlights_heli_bomb_flash_enable = 1,
                betterlights_heli_bomb_flash_size = 320,
                betterlights_heli_bomb_flash_brightness = 5.0,
                betterlights_heli_bomb_flash_time = 0.18,
            })
        end)

        -- Magnusson Device (Strider Buster)
        spawnmenu.AddToolMenuOption("Better Lights", "Client", "BL_Magnusson", "Magnusson Device", "", "", function(panel)
            panel:ClearControls()
            panel:Help("Light blue glow on Magnusson devices and a brief flash on explosion")
            panel:CheckBox("Enable", "betterlights_magnusson_enable")
            panel:NumSlider("Radius", "betterlights_magnusson_size", 0, 400, 0)
            panel:NumSlider("Brightness", "betterlights_magnusson_brightness", 0, 5, 2)
            panel:NumSlider("Decay", "betterlights_magnusson_decay", 0, 5000, 0)
            panel:CheckBox("Add model elight", "betterlights_magnusson_models_elight")
            panel:NumSlider("Model elight radius x", "betterlights_magnusson_models_elight_size_mult", 0, 3, 2)
            panel:Help("Explosion Flash")
            panel:CheckBox("Flash on explosion", "betterlights_magnusson_flash_enable")
            panel:NumSlider("Flash radius", "betterlights_magnusson_flash_size", 0, 800, 0)
            panel:NumSlider("Flash brightness", "betterlights_magnusson_flash_brightness", 0, 10, 2)
            panel:NumSlider("Flash time (s)", "betterlights_magnusson_flash_time", 0, 1, 2)
            addResetButton(panel, {
                betterlights_magnusson_enable = 1,
                betterlights_magnusson_size = 130,
                betterlights_magnusson_brightness = 0.48,
                betterlights_magnusson_decay = 2000,
                betterlights_magnusson_models_elight = 1,
                betterlights_magnusson_models_elight_size_mult = 1.0,
                betterlights_magnusson_flash_enable = 1,
                betterlights_magnusson_flash_size = 360,
                betterlights_magnusson_flash_brightness = 2.2,
                betterlights_magnusson_flash_time = 0.14,
            })
        end)

        -- Manhack
        spawnmenu.AddToolMenuOption("Better Lights", "Client", "BL_Manhack", "Manhack", "", "", function(panel)
            panel:ClearControls()
            panel:Help("Red glow for Combine Manhacks")
            panel:CheckBox("Enable", "betterlights_manhack_enable")
            panel:NumSlider("Radius", "betterlights_manhack_size", 0, 400, 0)
            panel:NumSlider("Brightness", "betterlights_manhack_brightness", 0, 5, 2)
            panel:NumSlider("Decay", "betterlights_manhack_decay", 0, 5000, 0)
            panel:CheckBox("Add model elight", "betterlights_manhack_models_elight")
            panel:NumSlider("Model elight radius x", "betterlights_manhack_models_elight_size_mult", 0, 3, 2)
            addResetButton(panel, {
                betterlights_manhack_enable = 1,
                betterlights_manhack_size = 70,
                betterlights_manhack_brightness = 0.6,
                betterlights_manhack_decay = 2000,
                betterlights_manhack_models_elight = 1,
                betterlights_manhack_models_elight_size_mult = 1.0,
            })
        end)

        -- Rollermine
        spawnmenu.AddToolMenuOption("Better Lights", "Client", "BL_Rollermine", "Rollermine", "", "", function(panel)
            panel:ClearControls()
            panel:Help("Neutral blue glow for rollermines")
            panel:CheckBox("Enable", "betterlights_rollermine_enable")
            panel:NumSlider("Radius", "betterlights_rollermine_size", 0, 400, 0)
            panel:NumSlider("Brightness", "betterlights_rollermine_brightness", 0, 5, 2)
            panel:NumSlider("Decay", "betterlights_rollermine_decay", 0, 5000, 0)
            panel:CheckBox("Add model elight", "betterlights_rollermine_models_elight")
            panel:NumSlider("Model elight radius x", "betterlights_rollermine_models_elight_size_mult", 0, 3, 2)
            addResetButton(panel, {
                betterlights_rollermine_enable = 1,
                betterlights_rollermine_size = 110,
                betterlights_rollermine_brightness = 0.6,
                betterlights_rollermine_decay = 2000,
                betterlights_rollermine_models_elight = 1,
                betterlights_rollermine_models_elight_size_mult = 1.0,
            })
        end)

        -- Rollermine (Hacked)
        spawnmenu.AddToolMenuOption("Better Lights", "Client", "BL_RollermineHacked", "Rollermine (Hacked)", "", "", function(panel)
            panel:ClearControls()
            panel:Help("Orange glow for hacked rollermines")
            panel:CheckBox("Enable", "betterlights_rollermine_hacked_enable")
            panel:NumSlider("Radius", "betterlights_rollermine_hacked_size", 0, 400, 0)
            panel:NumSlider("Brightness", "betterlights_rollermine_hacked_brightness", 0, 5, 2)
            panel:NumSlider("Decay", "betterlights_rollermine_hacked_decay", 0, 5000, 0)
            panel:CheckBox("Add model elight", "betterlights_rollermine_hacked_models_elight")
            panel:NumSlider("Model elight radius x", "betterlights_rollermine_hacked_models_elight_size_mult", 0, 3, 2)
            addResetButton(panel, {
                betterlights_rollermine_hacked_enable = 1,
                betterlights_rollermine_hacked_size = 110,
                betterlights_rollermine_hacked_brightness = 0.6,
                betterlights_rollermine_hacked_decay = 2000,
                betterlights_rollermine_hacked_models_elight = 1,
                betterlights_rollermine_hacked_models_elight_size_mult = 1.0,
            })
        end)

        -- Combine Scanner
        spawnmenu.AddToolMenuOption("Better Lights", "Client", "BL_CScanner", "Combine Scanner", "", "", function(panel)
            panel:ClearControls()
            panel:Help("Cool white/blue glow for Combine Scanners")
            panel:CheckBox("Enable", "betterlights_cscanner_enable")
            panel:NumSlider("Radius", "betterlights_cscanner_size", 0, 600, 0)
            panel:NumSlider("Brightness", "betterlights_cscanner_brightness", 0, 5, 2)
            panel:NumSlider("Decay", "betterlights_cscanner_decay", 0, 5000, 0)
            panel:CheckBox("Add model elight", "betterlights_cscanner_models_elight")
            panel:NumSlider("Model elight radius x", "betterlights_cscanner_models_elight_size_mult", 0, 3, 2)
            panel:Help("Searchlight (shadow-casting)")
            panel:CheckBox("Enable searchlight", "betterlights_cscanner_searchlight_enable")
            panel:CheckBox("Include npc_clawscanner", "betterlights_scanner_searchlight_include_clawscanner")
            panel:CheckBox("Cast shadows (expensive)", "betterlights_cscanner_searchlight_shadows")
            panel:NumSlider("Searchlight FOV", "betterlights_cscanner_searchlight_fov", 1, 175, 0)
            panel:NumSlider("Searchlight distance", "betterlights_cscanner_searchlight_distance", 0, 3000, 0)
            panel:NumSlider("Searchlight near Z", "betterlights_cscanner_searchlight_near", 0, 128, 0)
            panel:NumSlider("Searchlight brightness", "betterlights_cscanner_searchlight_brightness", 0, 2, 2)
            addResetButton(panel, {
                betterlights_cscanner_enable = 1,
                betterlights_cscanner_size = 120,
                betterlights_cscanner_brightness = 0.7,
                betterlights_cscanner_decay = 2000,
                betterlights_cscanner_models_elight = 1,
                betterlights_cscanner_models_elight_size_mult = 1.0,
                betterlights_cscanner_searchlight_enable = 1,
                betterlights_scanner_searchlight_include_clawscanner = 1,
                betterlights_cscanner_searchlight_shadows = 1,
                betterlights_cscanner_searchlight_fov = 38,
                betterlights_cscanner_searchlight_distance = 900,
                betterlights_cscanner_searchlight_near = 8,
                betterlights_cscanner_searchlight_brightness = 0.7,
            })
        end)

        -- Pickups (AR2 alt, Battery, Health Vial, Health Kit)
        spawnmenu.AddToolMenuOption("Better Lights", "Client", "BL_Pickups", "Pickups", "", "", function(panel)
            panel:ClearControls()
            panel:Help("Subtle glows for common pickups")
            -- AR2 alt-fire ammo
            panel:CheckBox("AR2 alt-fire ammo", "betterlights_item_ar2alt_enable")
            panel:NumSlider("AR2 alt Radius", "betterlights_item_ar2alt_size", 0, 300, 0)
            panel:NumSlider("AR2 alt Brightness", "betterlights_item_ar2alt_brightness", 0, 2, 2)
            panel:NumSlider("AR2 alt Decay", "betterlights_item_ar2alt_decay", 0, 5000, 0)
            panel:CheckBox("AR2 alt model elight", "betterlights_item_ar2alt_models_elight")
            panel:NumSlider("AR2 alt elight radius x", "betterlights_item_ar2alt_models_elight_size_mult", 0, 3, 2)

            -- Battery
            panel:CheckBox("Battery", "betterlights_item_battery_enable")
            panel:NumSlider("Battery Radius", "betterlights_item_battery_size", 0, 300, 0)
            panel:NumSlider("Battery Brightness", "betterlights_item_battery_brightness", 0, 2, 2)
            panel:NumSlider("Battery Decay", "betterlights_item_battery_decay", 0, 5000, 0)
            panel:CheckBox("Battery model elight", "betterlights_item_battery_models_elight")
            panel:NumSlider("Battery elight radius x", "betterlights_item_battery_models_elight_size_mult", 0, 3, 2)

            -- Health Vial
            panel:CheckBox("Health Vial", "betterlights_item_healthvial_enable")
            panel:NumSlider("Vial Radius", "betterlights_item_healthvial_size", 0, 300, 0)
            panel:NumSlider("Vial Brightness", "betterlights_item_healthvial_brightness", 0, 2, 2)
            panel:NumSlider("Vial Decay", "betterlights_item_healthvial_decay", 0, 5000, 0)
            panel:CheckBox("Vial model elight", "betterlights_item_healthvial_models_elight")
            panel:NumSlider("Vial elight radius x", "betterlights_item_healthvial_models_elight_size_mult", 0, 3, 2)

            -- Health Kit
            panel:CheckBox("Health Kit", "betterlights_item_healthkit_enable")
            panel:NumSlider("Kit Radius", "betterlights_item_healthkit_size", 0, 300, 0)
            panel:NumSlider("Kit Brightness", "betterlights_item_healthkit_brightness", 0, 2, 2)
            panel:NumSlider("Kit Decay", "betterlights_item_healthkit_decay", 0, 5000, 0)
            panel:CheckBox("Kit model elight", "betterlights_item_healthkit_models_elight")
            panel:NumSlider("Kit elight radius x", "betterlights_item_healthkit_models_elight_size_mult", 0, 3, 2)

            addResetButton(panel, {
                betterlights_item_ar2alt_enable = 1,
                betterlights_item_ar2alt_size = 60,
                betterlights_item_ar2alt_brightness = 0.25,
                betterlights_item_ar2alt_decay = 1800,
                betterlights_item_ar2alt_models_elight = 1,
                betterlights_item_ar2alt_models_elight_size_mult = 1.0,
                betterlights_item_battery_enable = 1,
                betterlights_item_battery_size = 55,
                betterlights_item_battery_brightness = 0.2,
                betterlights_item_battery_decay = 1800,
                betterlights_item_battery_models_elight = 1,
                betterlights_item_battery_models_elight_size_mult = 1.0,
                betterlights_item_healthvial_enable = 1,
                betterlights_item_healthvial_size = 45,
                betterlights_item_healthvial_brightness = 0.18,
                betterlights_item_healthvial_decay = 1800,
                betterlights_item_healthvial_models_elight = 1,
                betterlights_item_healthvial_models_elight_size_mult = 1.0,
                betterlights_item_healthkit_enable = 1,
                betterlights_item_healthkit_size = 55,
                betterlights_item_healthkit_brightness = 0.2,
                betterlights_item_healthkit_decay = 1800,
                betterlights_item_healthkit_models_elight = 1,
                betterlights_item_healthkit_models_elight_size_mult = 1.0,
            })
        end)


    end

    local function addServerPanels()
        -- Placeholder for future server settings
        spawnmenu.AddToolMenuOption("Better Lights", "Server", "BL_ServerInfo", "(Server Settings)", "", "", function(panel)
            panel:ClearControls()
            panel:Help("No server-side settings yet. All BetterLights options are clientside.")
        end)
    end

    hook.Add("AddToolMenuTabs", "BetterLights_AddTab", function()
        spawnmenu.AddToolTab("Better Lights", "Better Lights", "icon16/lightbulb.png")
    end)

    hook.Add("PopulateToolMenu", "BetterLights_Populate", function()
        spawnmenu.AddToolCategory("Better Lights", "Client", "Client")
        spawnmenu.AddToolCategory("Better Lights", "Server", "Server")
        addClientPanels()
        addServerPanels()
    end)
end
