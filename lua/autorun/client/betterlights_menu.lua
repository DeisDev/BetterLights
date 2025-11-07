-- BetterLights: Spawnmenu integration
-- Adds a "Better Lights" tab with organized categories and per-feature panels.

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
        spawnmenu.AddToolMenuOption("Better Lights", "Projectiles", "BL_CombineBall", "Combine AR2 Orb", "", "", function(panel)
            panel:ClearControls()
            panel:Help("Blue/cyan light for prop_combine_ball")
            panel:CheckBox("Enable", "betterlights_combineball_enable")
            panel:NumSlider("Radius", "betterlights_combineball_size", 0, 800, 0)
            panel:NumSlider("Brightness", "betterlights_combineball_brightness", 0, 10, 2)
            panel:NumSlider("Decay", "betterlights_combineball_decay", 0, 5000, 0)
            panel:Help("Color (RGB)")
            panel:NumSlider("Red", "betterlights_combineball_color_r", 0, 255, 0)
            panel:NumSlider("Green", "betterlights_combineball_color_g", 0, 255, 0)
            panel:NumSlider("Blue", "betterlights_combineball_color_b", 0, 255, 0)
            addResetButton(panel, {
                betterlights_combineball_enable = 1,
                betterlights_combineball_size = 320,
                betterlights_combineball_brightness = 2.5,
                betterlights_combineball_decay = 2000,
                betterlights_combineball_color_r = 80,
                betterlights_combineball_color_g = 180,
                betterlights_combineball_color_b = 255,
            })
        end)

        -- Bullet Impacts
    spawnmenu.AddToolMenuOption("Better Lights", "Gunfire", "BL_BulletImpacts", "Bullet Impacts", "", "", function(panel)
            panel:ClearControls()
            panel:Help("Subtle flashes when bullets hit surfaces. AR2 impacts use a blue tint; others use warm orange.")
            panel:CheckBox("Enable", "betterlights_bullet_impact_enable")
            panel:NumSlider("Generic radius", "betterlights_bullet_impact_size", 0, 300, 0)
            panel:NumSlider("Generic brightness", "betterlights_bullet_impact_brightness", 0, 2, 2)
            panel:NumSlider("Decay", "betterlights_bullet_impact_decay", 0, 5000, 0)
            panel:Help("Generic Color (RGB)")
            panel:NumSlider("Red", "betterlights_bullet_impact_color_r", 0, 255, 0)
            panel:NumSlider("Green", "betterlights_bullet_impact_color_g", 0, 255, 0)
            panel:NumSlider("Blue", "betterlights_bullet_impact_color_b", 0, 255, 0)
            panel:Help("AR2 (Combine Rifle) overrides")
            panel:CheckBox("Enable AR2 tint", "betterlights_bullet_impact_ar2_enable")
            panel:NumSlider("AR2 radius", "betterlights_bullet_impact_ar2_size", 0, 300, 0)
            panel:NumSlider("AR2 brightness", "betterlights_bullet_impact_ar2_brightness", 0, 2, 2)
            panel:Help("AR2 Color (RGB)")
            panel:NumSlider("Red", "betterlights_bullet_impact_ar2_color_r", 0, 255, 0)
            panel:NumSlider("Green", "betterlights_bullet_impact_ar2_color_g", 0, 255, 0)
            panel:NumSlider("Blue", "betterlights_bullet_impact_ar2_color_b", 0, 255, 0)
            addResetButton(panel, {
                betterlights_bullet_impact_enable = 1,
                betterlights_bullet_impact_size = 60,
                betterlights_bullet_impact_brightness = 0.25,
                betterlights_bullet_impact_decay = 1800,
                betterlights_bullet_impact_ar2_enable = 1,
                betterlights_bullet_impact_ar2_size = 70,
                betterlights_bullet_impact_ar2_brightness = 0.3,
                betterlights_bullet_impact_color_r = 255,
                betterlights_bullet_impact_color_g = 160,
                betterlights_bullet_impact_color_b = 60,
                betterlights_bullet_impact_ar2_color_r = 110,
                betterlights_bullet_impact_ar2_color_g = 190,
                betterlights_bullet_impact_ar2_color_b = 255,
            })
        end)

        -- Muzzle Flash
    spawnmenu.AddToolMenuOption("Better Lights", "Gunfire", "BL_MuzzleFlash", "Muzzle Flash", "", "", function(panel)
            panel:ClearControls()
            panel:Help("Brief flash at the muzzle when a weapon fires. AR2 uses a blue tint.")
            panel:CheckBox("Enable", "betterlights_muzzle_enable")
            panel:NumSlider("Generic radius", "betterlights_muzzle_size", 0, 300, 0)
            panel:NumSlider("Generic brightness", "betterlights_muzzle_brightness", 0, 2, 2)
            panel:NumSlider("Decay", "betterlights_muzzle_decay", 0, 5000, 0)
            panel:Help("Generic Color (RGB)")
            panel:NumSlider("Red", "betterlights_muzzle_color_r", 0, 255, 0)
            panel:NumSlider("Green", "betterlights_muzzle_color_g", 0, 255, 0)
            panel:NumSlider("Blue", "betterlights_muzzle_color_b", 0, 255, 0)
            panel:Help("AR2 (Combine Rifle) overrides")
            panel:CheckBox("Enable AR2 tint", "betterlights_muzzle_ar2_enable")
            panel:NumSlider("AR2 radius", "betterlights_muzzle_ar2_size", 0, 300, 0)
            panel:NumSlider("AR2 brightness", "betterlights_muzzle_ar2_brightness", 0, 2, 2)
            panel:Help("AR2 Color (RGB)")
            panel:NumSlider("Red", "betterlights_muzzle_ar2_color_r", 0, 255, 0)
            panel:NumSlider("Green", "betterlights_muzzle_ar2_color_g", 0, 255, 0)
            panel:NumSlider("Blue", "betterlights_muzzle_ar2_color_b", 0, 255, 0)
            addResetButton(panel, {
                betterlights_muzzle_enable = 1,
                betterlights_muzzle_size = 250,
                betterlights_muzzle_brightness = 2.0,
                betterlights_muzzle_decay = 1600,
                betterlights_muzzle_ar2_enable = 1,
                betterlights_muzzle_ar2_size = 250,
                betterlights_muzzle_ar2_brightness = 2.0,
                betterlights_muzzle_color_r = 255,
                betterlights_muzzle_color_g = 170,
                betterlights_muzzle_color_b = 90,
                betterlights_muzzle_ar2_color_r = 110,
                betterlights_muzzle_ar2_color_g = 190,
                betterlights_muzzle_ar2_color_b = 255,
            })
        end)

        -- Crossbow bolt
    spawnmenu.AddToolMenuOption("Better Lights", "Projectiles", "BL_Bolt", "Crossbow Bolt", "", "", function(panel)
            panel:ClearControls()
            panel:Help("Warm orange light for crossbow bolts")
            panel:CheckBox("Enable", "betterlights_bolt_enable")
            panel:NumSlider("Radius", "betterlights_bolt_size", 0, 800, 0)
            panel:NumSlider("Brightness", "betterlights_bolt_brightness", 0, 10, 2)
            panel:NumSlider("Decay", "betterlights_bolt_decay", 0, 5000, 0)
            panel:Help("Color (RGB)")
            panel:NumSlider("Red", "betterlights_bolt_color_r", 0, 255, 0)
            panel:NumSlider("Green", "betterlights_bolt_color_g", 0, 255, 0)
            panel:NumSlider("Blue", "betterlights_bolt_color_b", 0, 255, 0)
            addResetButton(panel, {
                betterlights_bolt_enable = 1,
                betterlights_bolt_size = 220,
                betterlights_bolt_brightness = 0.96,
                betterlights_bolt_decay = 2000,
                betterlights_bolt_color_r = 255,
                betterlights_bolt_color_g = 140,
                betterlights_bolt_color_b = 40,
            })
        end)

        -- Crossbow (held)
    spawnmenu.AddToolMenuOption("Better Lights", "Weapons", "BL_CrossbowHeld", "Crossbow (Held)", "", "", function(panel)
            panel:ClearControls()
            panel:Help("Subtle orange light while holding the Crossbow")
            panel:CheckBox("Enable", "betterlights_crossbow_hold_enable")
            panel:NumSlider("Radius", "betterlights_crossbow_hold_size", 0, 300, 0)
            panel:NumSlider("Brightness", "betterlights_crossbow_hold_brightness", 0, 5, 2)
            panel:NumSlider("Decay", "betterlights_crossbow_hold_decay", 0, 5000, 0)
            panel:Help("Color (RGB)")
            panel:NumSlider("Red", "betterlights_crossbow_hold_color_r", 0, 255, 0)
            panel:NumSlider("Green", "betterlights_crossbow_hold_color_g", 0, 255, 0)
            panel:NumSlider("Blue", "betterlights_crossbow_hold_color_b", 0, 255, 0)
            addResetButton(panel, {
                betterlights_crossbow_hold_enable = 1,
                betterlights_crossbow_hold_size = 30,
                betterlights_crossbow_hold_brightness = 0.32,
                betterlights_crossbow_hold_decay = 2000,
                betterlights_crossbow_hold_color_r = 255,
                betterlights_crossbow_hold_color_g = 140,
                betterlights_crossbow_hold_color_b = 40,
            })
        end)

        -- RPG rocket
    spawnmenu.AddToolMenuOption("Better Lights", "Projectiles", "BL_RPG", "RPG Rocket", "", "", function(panel)
            panel:ClearControls()
            panel:Help("Warm flame light for RPG rockets in flight")
            panel:CheckBox("Enable", "betterlights_rpg_enable")
            panel:NumSlider("Radius", "betterlights_rpg_size", 0, 800, 0)
            panel:NumSlider("Brightness", "betterlights_rpg_brightness", 0, 10, 2)
            panel:NumSlider("Decay", "betterlights_rpg_decay", 0, 5000, 0)
            panel:Help("Color (RGB)")
            panel:NumSlider("Red", "betterlights_rpg_color_r", 0, 255, 0)
            panel:NumSlider("Green", "betterlights_rpg_color_g", 0, 255, 0)
            panel:NumSlider("Blue", "betterlights_rpg_color_b", 0, 255, 0)
            addResetButton(panel, {
                betterlights_rpg_enable = 1,
                betterlights_rpg_size = 280,
                betterlights_rpg_brightness = 2.2,
                betterlights_rpg_decay = 2000,
                betterlights_rpg_color_r = 255,
                betterlights_rpg_color_g = 170,
                betterlights_rpg_color_b = 60,
            })
        end)

        -- Antlion Spit
        spawnmenu.AddToolMenuOption("Better Lights", "Projectiles", "BL_AntlionSpit", "Antlion Spit", "", "", function(panel)
            panel:ClearControls()
            panel:Help("Acid-green glow on Antlion Worker spit (grenade_spit) and a small flash on impact")
            panel:CheckBox("Enable glow", "betterlights_antlion_spit_enable")
            panel:NumSlider("Glow radius", "betterlights_antlion_spit_size", 0, 400, 0)
            panel:NumSlider("Glow brightness", "betterlights_antlion_spit_brightness", 0, 5, 2)
            panel:NumSlider("Glow decay", "betterlights_antlion_spit_decay", 0, 5000, 0)
            panel:Help("Glow Color (RGB)")
            panel:NumSlider("Red", "betterlights_antlion_spit_color_r", 0, 255, 0)
            panel:NumSlider("Green", "betterlights_antlion_spit_color_g", 0, 255, 0)
            panel:NumSlider("Blue", "betterlights_antlion_spit_color_b", 0, 255, 0)
            panel:Help("Impact Flash")
            panel:CheckBox("Flash on impact", "betterlights_antlion_spit_flash_enable")
            panel:NumSlider("Flash radius", "betterlights_antlion_spit_flash_size", 0, 800, 0)
            panel:NumSlider("Flash brightness", "betterlights_antlion_spit_flash_brightness", 0, 10, 2)
            panel:NumSlider("Flash time (s)", "betterlights_antlion_spit_flash_time", 0, 1, 2)
            panel:Help("Flash Color (RGB)")
            panel:NumSlider("Red", "betterlights_antlion_spit_flash_color_r", 0, 255, 0)
            panel:NumSlider("Green", "betterlights_antlion_spit_flash_color_g", 0, 255, 0)
            panel:NumSlider("Blue", "betterlights_antlion_spit_flash_color_b", 0, 255, 0)
            addResetButton(panel, {
                betterlights_antlion_spit_enable = 1,
                betterlights_antlion_spit_size = 100,
                betterlights_antlion_spit_brightness = 1.0,
                betterlights_antlion_spit_decay = 1800,
                betterlights_antlion_spit_color_r = 120,
                betterlights_antlion_spit_color_g = 255,
                betterlights_antlion_spit_color_b = 140,
                betterlights_antlion_spit_flash_enable = 1,
                betterlights_antlion_spit_flash_size = 160,
                betterlights_antlion_spit_flash_brightness = 1.5,
                betterlights_antlion_spit_flash_time = 1.0,
                betterlights_antlion_spit_flash_color_r = 180,
                betterlights_antlion_spit_flash_color_g = 255,
                betterlights_antlion_spit_flash_color_b = 120,
            })
        end)

        -- Burning entities
    spawnmenu.AddToolMenuOption("Better Lights", "Environment", "BL_Fire", "Burning Entities", "", "", function(panel)
            panel:ClearControls()
            panel:Help("Light for entities on fire, with optional flicker and model-only elight")
            panel:CheckBox("Enable", "betterlights_fire_enable")
            panel:NumSlider("Radius", "betterlights_fire_size", 0, 800, 0)
            panel:NumSlider("Brightness", "betterlights_fire_brightness", 0, 10, 2)
            panel:NumSlider("Decay", "betterlights_fire_decay", 0, 5000, 0)
            panel:CheckBox("Add model elight", "betterlights_fire_models_elight")
            panel:NumSlider("Model elight radius x", "betterlights_fire_models_elight_size_mult", 0, 3, 2)
            panel:Help("Color (RGB)")
            panel:NumSlider("Red", "betterlights_fire_color_r", 0, 255, 0)
            panel:NumSlider("Green", "betterlights_fire_color_g", 0, 255, 0)
            panel:NumSlider("Blue", "betterlights_fire_color_b", 0, 255, 0)
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
                betterlights_fire_color_r = 255,
                betterlights_fire_color_g = 170,
                betterlights_fire_color_b = 60,
                betterlights_fire_flicker_enable = 1,
                betterlights_fire_flicker_amount = 0.35,
                betterlights_fire_flicker_size_amount = 0.12,
                betterlights_fire_flicker_speed = 11.5,
            })
        end)

            -- Generic Explosion Flash
        spawnmenu.AddToolMenuOption("Better Lights", "Environment", "BL_Explosions", "Explosion Flash (Generic)", "", "", function(panel)
                panel:ClearControls()
                panel:Help("Brief flash when generic explosions occur (env_explosion, explosive barrels)")
                panel:CheckBox("Enable", "betterlights_explosion_flash_enable")
                panel:NumSlider("Radius", "betterlights_explosion_flash_size", 0, 800, 0)
                panel:NumSlider("Brightness", "betterlights_explosion_flash_brightness", 0, 10, 2)
                panel:NumSlider("Duration (s)", "betterlights_explosion_flash_time", 0, 1, 2)
                panel:Help("Detection")
                panel:CheckBox("Detect env_* explosion entities", "betterlights_explosion_detect_env")
                panel:CheckBox("Detect explosive barrels", "betterlights_explosion_detect_barrels")
                panel:Help("Color (RGB)")
                panel:NumSlider("Red", "betterlights_explosion_flash_color_r", 0, 255, 0)
                panel:NumSlider("Green", "betterlights_explosion_flash_color_g", 0, 255, 0)
                panel:NumSlider("Blue", "betterlights_explosion_flash_color_b", 0, 255, 0)
                addResetButton(panel, {
                    betterlights_explosion_flash_enable = 1,
                    betterlights_explosion_flash_size = 320,
                    betterlights_explosion_flash_brightness = 3.0,
                    betterlights_explosion_flash_time = 0.18,
                    betterlights_explosion_detect_env = 1,
                    betterlights_explosion_detect_barrels = 1,
                    betterlights_explosion_flash_color_r = 255,
                    betterlights_explosion_flash_color_g = 210,
                    betterlights_explosion_flash_color_b = 120,
                })
            end)
        -- Frag grenade
    spawnmenu.AddToolMenuOption("Better Lights", "Projectiles", "BL_Grenade", "Frag Grenade", "", "", function(panel)
            panel:ClearControls()
            panel:Help("Dim red light for thrown frag grenades")
            panel:CheckBox("Enable", "betterlights_grenade_enable")
            panel:NumSlider("Radius", "betterlights_grenade_size", 0, 400, 0)
            panel:NumSlider("Brightness", "betterlights_grenade_brightness", 0, 5, 2)
            panel:NumSlider("Decay", "betterlights_grenade_decay", 0, 5000, 0)
            panel:CheckBox("Add model elight", "betterlights_grenade_models_elight")
            panel:NumSlider("Model elight radius x", "betterlights_grenade_models_elight_size_mult", 0, 3, 2)
            panel:Help("Color (RGB)")
            panel:NumSlider("Red", "betterlights_grenade_color_r", 0, 255, 0)
            panel:NumSlider("Green", "betterlights_grenade_color_g", 0, 255, 0)
            panel:NumSlider("Blue", "betterlights_grenade_color_b", 0, 255, 0)
            addResetButton(panel, {
                betterlights_grenade_enable = 1,
                betterlights_grenade_size = 80,
                betterlights_grenade_brightness = 0.9,
                betterlights_grenade_decay = 1800,
                betterlights_grenade_models_elight = 1,
                betterlights_grenade_models_elight_size_mult = 1.0,
                betterlights_grenade_color_r = 255,
                betterlights_grenade_color_g = 40,
                betterlights_grenade_color_b = 40,
            })
        end)

        -- Combine Mine (hopper mine)
    spawnmenu.AddToolMenuOption("Better Lights", "NPCs", "BL_CombineMine", "Combine Mine", "", "", function(panel)
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
            panel:Help("Colors (RGB)")
            panel:Help("Idle Color")
            panel:NumSlider("Idle Red", "betterlights_combine_mine_idle_color_r", 0, 255, 0)
            panel:NumSlider("Idle Green", "betterlights_combine_mine_idle_color_g", 0, 255, 0)
            panel:NumSlider("Idle Blue", "betterlights_combine_mine_idle_color_b", 0, 255, 0)
            panel:Help("Alert Color")
            panel:NumSlider("Alert Red", "betterlights_combine_mine_alert_color_r", 0, 255, 0)
            panel:NumSlider("Alert Green", "betterlights_combine_mine_alert_color_g", 0, 255, 0)
            panel:NumSlider("Alert Blue", "betterlights_combine_mine_alert_color_b", 0, 255, 0)
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
                betterlights_combine_mine_idle_color_r = 90,
                betterlights_combine_mine_idle_color_g = 180,
                betterlights_combine_mine_idle_color_b = 255,
                betterlights_combine_mine_alert_color_r = 255,
                betterlights_combine_mine_alert_color_g = 60,
                betterlights_combine_mine_alert_color_b = 60,
                betterlights_combine_mine_pulse_enable = 1,
                betterlights_combine_mine_pulse_amount = 0.15,
                betterlights_combine_mine_pulse_speed = 6.0,
                betterlights_combine_mine_models_elight = 1,
                betterlights_combine_mine_models_elight_size_mult = 1.0,
            })
        end)

        -- Resistance Mine (friendly)
    spawnmenu.AddToolMenuOption("Better Lights", "NPCs", "BL_CombineMineResistance", "Resistance Mine", "", "", function(panel)
            panel:ClearControls()
            panel:Help("Idle blue glow; green alert glow when you're within range")
            panel:CheckBox("Enable", "betterlights_combine_mine_resistance_enable")
            panel:Help("Alert Settings")
            panel:NumSlider("Alert radius size", "betterlights_combine_mine_resistance_size", 0, 400, 0)
            panel:NumSlider("Alert brightness", "betterlights_combine_mine_resistance_brightness", 0, 5, 2)
            panel:NumSlider("Decay", "betterlights_combine_mine_resistance_decay", 0, 5000, 0)
            panel:Help("Alert Color (RGB)")
            panel:NumSlider("Red", "betterlights_combine_mine_resistance_color_r", 0, 255, 0)
            panel:NumSlider("Green", "betterlights_combine_mine_resistance_color_g", 0, 255, 0)
            panel:NumSlider("Blue", "betterlights_combine_mine_resistance_color_b", 0, 255, 0)
            panel:Help("Note: Uses same detection range and idle settings as hostile Combine Mine")
            addResetButton(panel, {
                betterlights_combine_mine_resistance_enable = 1,
                betterlights_combine_mine_resistance_size = 140,
                betterlights_combine_mine_resistance_brightness = 1.0,
                betterlights_combine_mine_resistance_decay = 2000,
                betterlights_combine_mine_resistance_color_r = 60,
                betterlights_combine_mine_resistance_color_g = 255,
                betterlights_combine_mine_resistance_color_b = 100,
            })
        end)

        -- Physgun
    spawnmenu.AddToolMenuOption("Better Lights", "Weapons", "BL_Physgun", "Physics Gun", "", "", function(panel)
            panel:ClearControls()
            panel:Help("Light that matches your Weapon Color; wall-safe world placement")
            panel:CheckBox("Enable", "betterlights_physgun_enable")
            panel:NumSlider("Radius", "betterlights_physgun_size", 0, 300, 0)
            panel:NumSlider("Brightness", "betterlights_physgun_brightness", 0, 5, 2)
            panel:NumSlider("Decay", "betterlights_physgun_decay", 0, 5000, 0)
            panel:CheckBox("Add model elight", "betterlights_physgun_models_elight")
            panel:NumSlider("Model elight radius x", "betterlights_physgun_models_elight_size_mult", 0, 3, 2)
            panel:CheckBox("Override Weapon Color", "betterlights_physgun_color_override")
            panel:Help("Override Color (RGB)")
            panel:NumSlider("Red", "betterlights_physgun_color_r", 0, 255, 0)
            panel:NumSlider("Green", "betterlights_physgun_color_g", 0, 255, 0)
            panel:NumSlider("Blue", "betterlights_physgun_color_b", 0, 255, 0)
            addResetButton(panel, {
                betterlights_physgun_enable = 1,
                betterlights_physgun_size = 33,
                betterlights_physgun_brightness = 0.3,
                betterlights_physgun_decay = 2000,
                betterlights_physgun_models_elight = 1,
                betterlights_physgun_models_elight_size_mult = 1.0,
                betterlights_physgun_color_override = 0,
                betterlights_physgun_color_r = 70,
                betterlights_physgun_color_g = 130,
                betterlights_physgun_color_b = 255,
            })
        end)

        -- Gravity Gun
    spawnmenu.AddToolMenuOption("Better Lights", "Weapons", "BL_GravityGun", "Gravity Gun", "", "", function(panel)
            panel:ClearControls()
            panel:Help("Warm orange light from the physcannon; wall-safe world placement")
            panel:CheckBox("Enable", "betterlights_gravitygun_enable")
            panel:NumSlider("Radius", "betterlights_gravitygun_size", 0, 300, 0)
            panel:NumSlider("Brightness", "betterlights_gravitygun_brightness", 0, 5, 2)
            panel:NumSlider("Decay", "betterlights_gravitygun_decay", 0, 5000, 0)
            panel:CheckBox("Add model elight", "betterlights_gravitygun_models_elight")
            panel:NumSlider("Model elight radius x", "betterlights_gravitygun_models_elight_size_mult", 0, 3, 2)
            panel:Help("Color (RGB)")
            panel:NumSlider("Red", "betterlights_gravitygun_color_r", 0, 255, 0)
            panel:NumSlider("Green", "betterlights_gravitygun_color_g", 0, 255, 0)
            panel:NumSlider("Blue", "betterlights_gravitygun_color_b", 0, 255, 0)
            addResetButton(panel, {
                betterlights_gravitygun_enable = 1,
                betterlights_gravitygun_size = 36,
                betterlights_gravitygun_brightness = 0.35,
                betterlights_gravitygun_decay = 2000,
                betterlights_gravitygun_models_elight = 1,
                betterlights_gravitygun_models_elight_size_mult = 1.0,
                betterlights_gravitygun_color_r = 255,
                betterlights_gravitygun_color_g = 140,
                betterlights_gravitygun_color_b = 40,
            })
        end)

        -- RPG (Held)
    spawnmenu.AddToolMenuOption("Better Lights", "Weapons", "BL_RPG_Held", "RPG (Held)", "", "", function(panel)
            panel:ClearControls()
            panel:Help("Subtle red light at the laser dot and on your left hand (ValveBiped.Bip01_L_Hand)")
            panel:CheckBox("Enable", "betterlights_rpg_hold_enable")
            panel:NumSlider("Radius", "betterlights_rpg_hold_size", 0, 300, 0)
            panel:NumSlider("Brightness", "betterlights_rpg_hold_brightness", 0, 5, 2)
            panel:NumSlider("Decay", "betterlights_rpg_hold_decay", 0, 5000, 0)
            panel:Help("Color (RGB)")
            panel:NumSlider("Red", "betterlights_rpg_hold_color_r", 0, 255, 0)
            panel:NumSlider("Green", "betterlights_rpg_hold_color_g", 0, 255, 0)
            panel:NumSlider("Blue", "betterlights_rpg_hold_color_b", 0, 255, 0)
            addResetButton(panel, {
                betterlights_rpg_hold_enable = 1,
                betterlights_rpg_hold_size = 24,
                betterlights_rpg_hold_brightness = 0.22,
                betterlights_rpg_hold_decay = 2000,
                betterlights_rpg_hold_color_r = 255,
                betterlights_rpg_hold_color_g = 60,
                betterlights_rpg_hold_color_b = 60,
            })
        end)

        -- Tool Gun
    spawnmenu.AddToolMenuOption("Better Lights", "Weapons", "BL_ToolGun", "Tool Gun", "", "", function(panel)
            panel:ClearControls()
            panel:Help("Small white light at the tip; wall-safe world placement")
            panel:CheckBox("Enable", "betterlights_toolgun_enable")
            panel:NumSlider("Radius", "betterlights_toolgun_size", 0, 300, 0)
            panel:NumSlider("Brightness", "betterlights_toolgun_brightness", 0, 5, 2)
            panel:NumSlider("Decay", "betterlights_toolgun_decay", 0, 5000, 0)
            panel:CheckBox("Add model elight", "betterlights_toolgun_models_elight")
            panel:NumSlider("Model elight radius x", "betterlights_toolgun_models_elight_size_mult", 0, 3, 2)
            panel:Help("Color (RGB)")
            panel:NumSlider("Red", "betterlights_toolgun_color_r", 0, 255, 0)
            panel:NumSlider("Green", "betterlights_toolgun_color_g", 0, 255, 0)
            panel:NumSlider("Blue", "betterlights_toolgun_color_b", 0, 255, 0)
            addResetButton(panel, {
                betterlights_toolgun_enable = 1,
                betterlights_toolgun_size = 28,
                betterlights_toolgun_brightness = 0.225,
                betterlights_toolgun_decay = 2000,
                betterlights_toolgun_models_elight = 1,
                betterlights_toolgun_models_elight_size_mult = 1.0,
                betterlights_toolgun_color_r = 255,
                betterlights_toolgun_color_g = 255,
                betterlights_toolgun_color_b = 255,
            })
        end)

        -- Helicopter Bombs
    spawnmenu.AddToolMenuOption("Better Lights", "Projectiles", "BL_HeliBomb", "Helicopter Bomb", "", "", function(panel)
            panel:ClearControls()
            panel:Help("Red glow on helicopter bombs and a brief flash on explosion")
            panel:CheckBox("Enable", "betterlights_heli_bomb_enable")
            panel:NumSlider("Radius", "betterlights_heli_bomb_size", 0, 400, 0)
            panel:NumSlider("Brightness", "betterlights_heli_bomb_brightness", 0, 5, 2)
            panel:NumSlider("Decay", "betterlights_heli_bomb_decay", 0, 5000, 0)
            panel:CheckBox("Add model elight", "betterlights_heli_bomb_models_elight")
            panel:NumSlider("Model elight radius x", "betterlights_heli_bomb_models_elight_size_mult", 0, 3, 2)
            panel:Help("Glow Color (RGB)")
            panel:NumSlider("Red", "betterlights_heli_bomb_color_r", 0, 255, 0)
            panel:NumSlider("Green", "betterlights_heli_bomb_color_g", 0, 255, 0)
            panel:NumSlider("Blue", "betterlights_heli_bomb_color_b", 0, 255, 0)
            panel:Help("Explosion Flash")
            panel:CheckBox("Flash on explosion", "betterlights_heli_bomb_flash_enable")
            panel:NumSlider("Flash radius", "betterlights_heli_bomb_flash_size", 0, 800, 0)
            panel:NumSlider("Flash brightness", "betterlights_heli_bomb_flash_brightness", 0, 10, 2)
            panel:NumSlider("Flash time (s)", "betterlights_heli_bomb_flash_time", 0, 1, 2)
            panel:Help("Flash Color (RGB)")
            panel:NumSlider("Red", "betterlights_heli_bomb_flash_color_r", 0, 255, 0)
            panel:NumSlider("Green", "betterlights_heli_bomb_flash_color_g", 0, 255, 0)
            panel:NumSlider("Blue", "betterlights_heli_bomb_flash_color_b", 0, 255, 0)
            addResetButton(panel, {
                betterlights_heli_bomb_enable = 1,
                betterlights_heli_bomb_size = 140,
                betterlights_heli_bomb_brightness = 1.4,
                betterlights_heli_bomb_decay = 2000,
                betterlights_heli_bomb_models_elight = 1,
                betterlights_heli_bomb_models_elight_size_mult = 1.0,
                betterlights_heli_bomb_color_r = 255,
                betterlights_heli_bomb_color_g = 60,
                betterlights_heli_bomb_color_b = 60,
                betterlights_heli_bomb_flash_enable = 1,
                betterlights_heli_bomb_flash_size = 320,
                betterlights_heli_bomb_flash_brightness = 5.0,
                betterlights_heli_bomb_flash_time = 0.18,
                betterlights_heli_bomb_flash_color_r = 255,
                betterlights_heli_bomb_flash_color_g = 210,
                betterlights_heli_bomb_flash_color_b = 120,
            })
        end)

        -- Magnusson Device (Strider Buster)
    spawnmenu.AddToolMenuOption("Better Lights", "Projectiles", "BL_Magnusson", "Magnusson Device", "", "", function(panel)
            panel:ClearControls()
            panel:Help("Light blue glow on Magnusson devices and a brief flash on explosion")
            panel:CheckBox("Enable", "betterlights_magnusson_enable")
            panel:NumSlider("Radius", "betterlights_magnusson_size", 0, 400, 0)
            panel:NumSlider("Brightness", "betterlights_magnusson_brightness", 0, 5, 2)
            panel:NumSlider("Decay", "betterlights_magnusson_decay", 0, 5000, 0)
            panel:CheckBox("Add model elight", "betterlights_magnusson_models_elight")
            panel:NumSlider("Model elight radius x", "betterlights_magnusson_models_elight_size_mult", 0, 3, 2)
            panel:Help("Glow Color (RGB)")
            panel:NumSlider("Red", "betterlights_magnusson_color_r", 0, 255, 0)
            panel:NumSlider("Green", "betterlights_magnusson_color_g", 0, 255, 0)
            panel:NumSlider("Blue", "betterlights_magnusson_color_b", 0, 255, 0)
            panel:Help("Explosion Flash")
            panel:CheckBox("Flash on explosion", "betterlights_magnusson_flash_enable")
            panel:NumSlider("Flash radius", "betterlights_magnusson_flash_size", 0, 800, 0)
            panel:NumSlider("Flash brightness", "betterlights_magnusson_flash_brightness", 0, 10, 2)
            panel:NumSlider("Flash time (s)", "betterlights_magnusson_flash_time", 0, 1, 2)
            panel:Help("Flash Color (RGB)")
            panel:NumSlider("Red", "betterlights_magnusson_flash_color_r", 0, 255, 0)
            panel:NumSlider("Green", "betterlights_magnusson_flash_color_g", 0, 255, 0)
            panel:NumSlider("Blue", "betterlights_magnusson_flash_color_b", 0, 255, 0)
            addResetButton(panel, {
                betterlights_magnusson_enable = 1,
                betterlights_magnusson_size = 130,
                betterlights_magnusson_brightness = 0.48,
                betterlights_magnusson_decay = 2000,
                betterlights_magnusson_models_elight = 1,
                betterlights_magnusson_models_elight_size_mult = 1.0,
                betterlights_magnusson_color_r = 130,
                betterlights_magnusson_color_g = 180,
                betterlights_magnusson_color_b = 255,
                betterlights_magnusson_flash_enable = 1,
                betterlights_magnusson_flash_size = 360,
                betterlights_magnusson_flash_brightness = 2.2,
                betterlights_magnusson_flash_time = 0.14,
                betterlights_magnusson_flash_color_r = 180,
                betterlights_magnusson_flash_color_g = 220,
                betterlights_magnusson_flash_color_b = 255,
            })
        end)

        -- Manhack
    spawnmenu.AddToolMenuOption("Better Lights", "NPCs", "BL_Manhack", "Manhack", "", "", function(panel)
            panel:ClearControls()
            panel:Help("Red glow for Combine Manhacks")
            panel:CheckBox("Enable", "betterlights_manhack_enable")
            panel:NumSlider("Radius", "betterlights_manhack_size", 0, 400, 0)
            panel:NumSlider("Brightness", "betterlights_manhack_brightness", 0, 5, 2)
            panel:NumSlider("Decay", "betterlights_manhack_decay", 0, 5000, 0)
            panel:CheckBox("Add model elight", "betterlights_manhack_models_elight")
            panel:NumSlider("Model elight radius x", "betterlights_manhack_models_elight_size_mult", 0, 3, 2)
            panel:Help("Color (RGB)")
            panel:NumSlider("Red", "betterlights_manhack_color_r", 0, 255, 0)
            panel:NumSlider("Green", "betterlights_manhack_color_g", 0, 255, 0)
            panel:NumSlider("Blue", "betterlights_manhack_color_b", 0, 255, 0)
            addResetButton(panel, {
                betterlights_manhack_enable = 1,
                betterlights_manhack_size = 70,
                betterlights_manhack_brightness = 0.6,
                betterlights_manhack_decay = 2000,
                betterlights_manhack_models_elight = 1,
                betterlights_manhack_models_elight_size_mult = 1.0,
                betterlights_manhack_color_r = 255,
                betterlights_manhack_color_g = 60,
                betterlights_manhack_color_b = 60,
            })
        end)

        -- Antlion Grub
    spawnmenu.AddToolMenuOption("Better Lights", "NPCs", "BL_AntlionGrub", "Antlion Grub", "", "", function(panel)
            panel:ClearControls()
            panel:Help("Subtle green glow on antlion grubs (abdomen)")
            panel:CheckBox("Enable", "betterlights_antlion_grub_enable")
            panel:NumSlider("Radius", "betterlights_antlion_grub_size", 0, 400, 0)
            panel:NumSlider("Brightness", "betterlights_antlion_grub_brightness", 0, 5, 2)
            panel:NumSlider("Decay", "betterlights_antlion_grub_decay", 0, 5000, 0)
            panel:Help("Color (RGB)")
            panel:NumSlider("Red", "betterlights_antlion_grub_color_r", 0, 255, 0)
            panel:NumSlider("Green", "betterlights_antlion_grub_color_g", 0, 255, 0)
            panel:NumSlider("Blue", "betterlights_antlion_grub_color_b", 0, 255, 0)
            addResetButton(panel, {
                betterlights_antlion_grub_enable = 1,
                betterlights_antlion_grub_size = 70,
                betterlights_antlion_grub_brightness = 0.35,
                betterlights_antlion_grub_decay = 2000,
                betterlights_antlion_grub_color_r = 120,
                betterlights_antlion_grub_color_g = 255,
                betterlights_antlion_grub_color_b = 120,
            })
        end)

        -- Antlion Guardian
    spawnmenu.AddToolMenuOption("Better Lights", "NPCs", "BL_AntlionGuardian", "Antlion Guardian", "", "", function(panel)
            panel:ClearControls()
            panel:Help("Green glow for Antlion Guardian (heuristic detection)")
            panel:CheckBox("Enable", "betterlights_antlion_guardian_enable")
            panel:NumSlider("Radius", "betterlights_antlion_guardian_size", 0, 800, 0)
            panel:NumSlider("Brightness", "betterlights_antlion_guardian_brightness", 0, 5, 2)
            panel:NumSlider("Decay", "betterlights_antlion_guardian_decay", 0, 5000, 0)
            panel:Help("Color (RGB)")
            panel:NumSlider("Red", "betterlights_antlion_guardian_color_r", 0, 255, 0)
            panel:NumSlider("Green", "betterlights_antlion_guardian_color_g", 0, 255, 0)
            panel:NumSlider("Blue", "betterlights_antlion_guardian_color_b", 0, 255, 0)
            addResetButton(panel, {
                betterlights_antlion_guardian_enable = 1,
                betterlights_antlion_guardian_size = 180,
                betterlights_antlion_guardian_brightness = 0.6,
                betterlights_antlion_guardian_decay = 2000,
                betterlights_antlion_guardian_color_r = 120,
                betterlights_antlion_guardian_color_g = 255,
                betterlights_antlion_guardian_color_b = 140,
            })
        end)

        -- Antlion Worker
        spawnmenu.AddToolMenuOption("Better Lights", "NPCs", "BL_AntlionWorker", "Antlion Worker", "", "", function(panel)
            panel:ClearControls()
            panel:Help("Subtle glow for Antlion Workers attached to Antlion.Back_Bone")
            panel:CheckBox("Enable", "betterlights_antlion_worker_enable")
            panel:NumSlider("Radius", "betterlights_antlion_worker_size", 0, 800, 0)
            panel:NumSlider("Brightness", "betterlights_antlion_worker_brightness", 0, 5, 2)
            panel:NumSlider("Decay", "betterlights_antlion_worker_decay", 0, 5000, 0)
            panel:Help("Color (RGB)")
            panel:NumSlider("Red", "betterlights_antlion_worker_color_r", 0, 255, 0)
            panel:NumSlider("Green", "betterlights_antlion_worker_color_g", 0, 255, 0)
            panel:NumSlider("Blue", "betterlights_antlion_worker_color_b", 0, 255, 0)
            addResetButton(panel, {
                betterlights_antlion_worker_enable = 1,
                betterlights_antlion_worker_size = 120,
                betterlights_antlion_worker_brightness = 0.55,
                betterlights_antlion_worker_decay = 2000,
                betterlights_antlion_worker_color_r = 180,
                betterlights_antlion_worker_color_g = 240,
                betterlights_antlion_worker_color_b = 120,
            })
        end)

        -- Rollermine
    spawnmenu.AddToolMenuOption("Better Lights", "NPCs", "BL_Rollermine", "Rollermine", "", "", function(panel)
            panel:ClearControls()
            panel:Help("Neutral blue glow for rollermines")
            panel:CheckBox("Enable", "betterlights_rollermine_enable")
            panel:NumSlider("Radius", "betterlights_rollermine_size", 0, 400, 0)
            panel:NumSlider("Brightness", "betterlights_rollermine_brightness", 0, 5, 2)
            panel:NumSlider("Decay", "betterlights_rollermine_decay", 0, 5000, 0)
            panel:CheckBox("Add model elight", "betterlights_rollermine_models_elight")
            panel:NumSlider("Model elight radius x", "betterlights_rollermine_models_elight_size_mult", 0, 3, 2)
            panel:Help("Colors (RGB) by skin")
            panel:Help("Skin 0 (Default)")
            panel:NumSlider("Red", "betterlights_rollermine_color_r", 0, 255, 0)
            panel:NumSlider("Green", "betterlights_rollermine_color_g", 0, 255, 0)
            panel:NumSlider("Blue", "betterlights_rollermine_color_b", 0, 255, 0)
            panel:Help("Skin 1 (Yellow)")
            panel:NumSlider("Red", "betterlights_rollermine_skin1_color_r", 0, 255, 0)
            panel:NumSlider("Green", "betterlights_rollermine_skin1_color_g", 0, 255, 0)
            panel:NumSlider("Blue", "betterlights_rollermine_skin1_color_b", 0, 255, 0)
            panel:Help("Skin 2 (Red)")
            panel:NumSlider("Red", "betterlights_rollermine_skin2_color_r", 0, 255, 0)
            panel:NumSlider("Green", "betterlights_rollermine_skin2_color_g", 0, 255, 0)
            panel:NumSlider("Blue", "betterlights_rollermine_skin2_color_b", 0, 255, 0)
            addResetButton(panel, {
                betterlights_rollermine_enable = 1,
                betterlights_rollermine_size = 110,
                betterlights_rollermine_brightness = 0.6,
                betterlights_rollermine_decay = 2000,
                betterlights_rollermine_models_elight = 1,
                betterlights_rollermine_models_elight_size_mult = 1.0,
                betterlights_rollermine_color_r = 110,
                betterlights_rollermine_color_g = 190,
                betterlights_rollermine_color_b = 255,
                betterlights_rollermine_skin1_color_r = 255,
                betterlights_rollermine_skin1_color_g = 220,
                betterlights_rollermine_skin1_color_b = 60,
                betterlights_rollermine_skin2_color_r = 255,
                betterlights_rollermine_skin2_color_g = 80,
                betterlights_rollermine_skin2_color_b = 80,
            })
        end)

        -- Rollermine (Hacked)
    spawnmenu.AddToolMenuOption("Better Lights", "NPCs", "BL_RollermineHacked", "Rollermine (Hacked)", "", "", function(panel)
            panel:ClearControls()
            panel:Help("Orange glow for hacked rollermines")
            panel:CheckBox("Enable", "betterlights_rollermine_hacked_enable")
            panel:NumSlider("Radius", "betterlights_rollermine_hacked_size", 0, 400, 0)
            panel:NumSlider("Brightness", "betterlights_rollermine_hacked_brightness", 0, 5, 2)
            panel:NumSlider("Decay", "betterlights_rollermine_hacked_decay", 0, 5000, 0)
            panel:CheckBox("Add model elight", "betterlights_rollermine_hacked_models_elight")
            panel:NumSlider("Model elight radius x", "betterlights_rollermine_hacked_models_elight_size_mult", 0, 3, 2)
            panel:Help("Color (RGB)")
            panel:NumSlider("Red", "betterlights_rollermine_hacked_color_r", 0, 255, 0)
            panel:NumSlider("Green", "betterlights_rollermine_hacked_color_g", 0, 255, 0)
            panel:NumSlider("Blue", "betterlights_rollermine_hacked_color_b", 0, 255, 0)
            addResetButton(panel, {
                betterlights_rollermine_hacked_enable = 1,
                betterlights_rollermine_hacked_size = 110,
                betterlights_rollermine_hacked_brightness = 0.6,
                betterlights_rollermine_hacked_decay = 2000,
                betterlights_rollermine_hacked_models_elight = 1,
                betterlights_rollermine_hacked_models_elight_size_mult = 1.0,
                betterlights_rollermine_hacked_color_r = 255,
                betterlights_rollermine_hacked_color_g = 160,
                betterlights_rollermine_hacked_color_b = 60,
            })
        end)

        -- Combine Scanner
    spawnmenu.AddToolMenuOption("Better Lights", "NPCs", "BL_CScanner", "Combine Scanner", "", "", function(panel)
            panel:ClearControls()
            panel:Help("Cool white/blue glow for Combine Scanners")
            panel:CheckBox("Enable", "betterlights_cscanner_enable")
            panel:NumSlider("Radius", "betterlights_cscanner_size", 0, 600, 0)
            panel:NumSlider("Brightness", "betterlights_cscanner_brightness", 0, 5, 2)
            panel:NumSlider("Decay", "betterlights_cscanner_decay", 0, 5000, 0)
            panel:CheckBox("Add model elight", "betterlights_cscanner_models_elight")
            panel:NumSlider("Model elight radius x", "betterlights_cscanner_models_elight_size_mult", 0, 3, 2)
            panel:Help("Glow Color (RGB)")
            panel:NumSlider("Red", "betterlights_cscanner_color_r", 0, 255, 0)
            panel:NumSlider("Green", "betterlights_cscanner_color_g", 0, 255, 0)
            panel:NumSlider("Blue", "betterlights_cscanner_color_b", 0, 255, 0)
            panel:Help("Searchlight (shadow-casting)")
            panel:CheckBox("Enable searchlight", "betterlights_cscanner_searchlight_enable")
            panel:CheckBox("Include npc_clawscanner", "betterlights_scanner_searchlight_include_clawscanner")
            panel:CheckBox("Cast shadows (expensive)", "betterlights_cscanner_searchlight_shadows")
            panel:NumSlider("Searchlight FOV", "betterlights_cscanner_searchlight_fov", 1, 175, 0)
            panel:NumSlider("Searchlight distance", "betterlights_cscanner_searchlight_distance", 0, 3000, 0)
            panel:NumSlider("Searchlight near Z", "betterlights_cscanner_searchlight_near", 0, 128, 0)
            panel:NumSlider("Searchlight brightness", "betterlights_cscanner_searchlight_brightness", 0, 2, 2)
            panel:Help("Searchlight Color (RGB)")
            panel:NumSlider("Red", "betterlights_cscanner_searchlight_color_r", 0, 255, 0)
            panel:NumSlider("Green", "betterlights_cscanner_searchlight_color_g", 0, 255, 0)
            panel:NumSlider("Blue", "betterlights_cscanner_searchlight_color_b", 0, 255, 0)
            addResetButton(panel, {
                betterlights_cscanner_enable = 1,
                betterlights_cscanner_size = 120,
                betterlights_cscanner_brightness = 0.7,
                betterlights_cscanner_decay = 2000,
                betterlights_cscanner_models_elight = 1,
                betterlights_cscanner_models_elight_size_mult = 1.0,
                betterlights_cscanner_color_r = 180,
                betterlights_cscanner_color_g = 230,
                betterlights_cscanner_color_b = 255,
                betterlights_cscanner_searchlight_enable = 1,
                betterlights_scanner_searchlight_include_clawscanner = 1,
                betterlights_cscanner_searchlight_shadows = 1,
                betterlights_cscanner_searchlight_fov = 38,
                betterlights_cscanner_searchlight_distance = 900,
                betterlights_cscanner_searchlight_near = 8,
                betterlights_cscanner_searchlight_brightness = 0.7,
                betterlights_cscanner_searchlight_color_r = 255,
                betterlights_cscanner_searchlight_color_g = 255,
                betterlights_cscanner_searchlight_color_b = 255,
            })
        end)

        -- Combine Soldier Face Glow
        spawnmenu.AddToolMenuOption("Better Lights", "Eye Glow", "BL_CombineSoldier", "Combine Soldier", "", "", function(panel)
            panel:ClearControls()
            panel:Help("Face glow for Combine Soldiers. Color varies by type:")
            panel:Help("• Elite: Red")
            panel:Help("• Prison Guard: Yellow (skin 0) or Red (skin 1)")
            panel:Help("• Standard: Blue (skin 0) or Orange (skin 1)")
            panel:CheckBox("Enable", "bl_combine_soldier_enable")
            panel:NumSlider("Radius", "bl_combine_soldier_size", 0, 200, 0)
            panel:NumSlider("Brightness", "bl_combine_soldier_brightness", 0, 5, 2)
            panel:NumSlider("Decay", "bl_combine_soldier_decay", 0, 5000, 0)
            panel:Help("Note: Colors are automatically determined by soldier variant")
            addResetButton(panel, {
                bl_combine_soldier_enable = 1,
                bl_combine_soldier_size = 40,
                bl_combine_soldier_brightness = 0.5,
                bl_combine_soldier_decay = 1500,
            })
        end)

        -- Pickups: AR2 alt-fire ammo
    spawnmenu.AddToolMenuOption("Better Lights", "Pickups", "BL_Pickup_AR2Alt", "AR2 Alt Ammo", "", "", function(panel)
            panel:ClearControls()
            panel:Help("Subtle glow for item_ammo_ar2_altfire")
            panel:CheckBox("Enable", "betterlights_item_ar2alt_enable")
            panel:NumSlider("Radius", "betterlights_item_ar2alt_size", 0, 300, 0)
            panel:NumSlider("Brightness", "betterlights_item_ar2alt_brightness", 0, 2, 2)
            panel:NumSlider("Decay", "betterlights_item_ar2alt_decay", 0, 5000, 0)
            panel:CheckBox("Add model elight", "betterlights_item_ar2alt_models_elight")
            panel:NumSlider("Elight radius x", "betterlights_item_ar2alt_models_elight_size_mult", 0, 3, 2)
            panel:Help("Color (RGB)")
            panel:NumSlider("Red", "betterlights_item_ar2alt_color_r", 0, 255, 0)
            panel:NumSlider("Green", "betterlights_item_ar2alt_color_g", 0, 255, 0)
            panel:NumSlider("Blue", "betterlights_item_ar2alt_color_b", 0, 255, 0)
            addResetButton(panel, {
                betterlights_item_ar2alt_enable = 1,
                betterlights_item_ar2alt_size = 60,
                betterlights_item_ar2alt_brightness = 0.25,
                betterlights_item_ar2alt_decay = 1800,
                betterlights_item_ar2alt_models_elight = 1,
                betterlights_item_ar2alt_models_elight_size_mult = 1.0,
                betterlights_item_ar2alt_color_r = 255,
                betterlights_item_ar2alt_color_g = 220,
                betterlights_item_ar2alt_color_b = 60,
            })
        end)

        -- Pickups: Battery
    spawnmenu.AddToolMenuOption("Better Lights", "Pickups", "BL_Pickup_Battery", "Battery", "", "", function(panel)
            panel:ClearControls()
            panel:Help("Subtle glow for item_battery")
            panel:CheckBox("Enable", "betterlights_item_battery_enable")
            panel:NumSlider("Radius", "betterlights_item_battery_size", 0, 300, 0)
            panel:NumSlider("Brightness", "betterlights_item_battery_brightness", 0, 2, 2)
            panel:NumSlider("Decay", "betterlights_item_battery_decay", 0, 5000, 0)
            panel:CheckBox("Add model elight", "betterlights_item_battery_models_elight")
            panel:NumSlider("Elight radius x", "betterlights_item_battery_models_elight_size_mult", 0, 3, 2)
            panel:Help("Color (RGB)")
            panel:NumSlider("Red", "betterlights_item_battery_color_r", 0, 255, 0)
            panel:NumSlider("Green", "betterlights_item_battery_color_g", 0, 255, 0)
            panel:NumSlider("Blue", "betterlights_item_battery_color_b", 0, 255, 0)
            addResetButton(panel, {
                betterlights_item_battery_enable = 1,
                betterlights_item_battery_size = 55,
                betterlights_item_battery_brightness = 0.2,
                betterlights_item_battery_decay = 1800,
                betterlights_item_battery_models_elight = 1,
                betterlights_item_battery_models_elight_size_mult = 1.0,
                betterlights_item_battery_color_r = 110,
                betterlights_item_battery_color_g = 190,
                betterlights_item_battery_color_b = 255,
            })
        end)

        -- Pickups: Health Vial
    spawnmenu.AddToolMenuOption("Better Lights", "Pickups", "BL_Pickup_Vial", "Health Vial", "", "", function(panel)
            panel:ClearControls()
            panel:Help("Subtle glow for item_healthvial")
            panel:CheckBox("Enable", "betterlights_item_healthvial_enable")
            panel:NumSlider("Radius", "betterlights_item_healthvial_size", 0, 300, 0)
            panel:NumSlider("Brightness", "betterlights_item_healthvial_brightness", 0, 2, 2)
            panel:NumSlider("Decay", "betterlights_item_healthvial_decay", 0, 5000, 0)
            panel:CheckBox("Add model elight", "betterlights_item_healthvial_models_elight")
            panel:NumSlider("Elight radius x", "betterlights_item_healthvial_models_elight_size_mult", 0, 3, 2)
            panel:Help("Color (RGB)")
            panel:NumSlider("Red", "betterlights_item_healthvial_color_r", 0, 255, 0)
            panel:NumSlider("Green", "betterlights_item_healthvial_color_g", 0, 255, 0)
            panel:NumSlider("Blue", "betterlights_item_healthvial_color_b", 0, 255, 0)
            addResetButton(panel, {
                betterlights_item_healthvial_enable = 1,
                betterlights_item_healthvial_size = 45,
                betterlights_item_healthvial_brightness = 0.18,
                betterlights_item_healthvial_decay = 1800,
                betterlights_item_healthvial_models_elight = 1,
                betterlights_item_healthvial_models_elight_size_mult = 1.0,
                betterlights_item_healthvial_color_r = 150,
                betterlights_item_healthvial_color_g = 255,
                betterlights_item_healthvial_color_b = 150,
            })
        end)

        -- Pickups: Health Kit
    spawnmenu.AddToolMenuOption("Better Lights", "Pickups", "BL_Pickup_HealthKit", "Health Kit", "", "", function(panel)
            panel:ClearControls()
            panel:Help("Subtle glow for item_healthkit")
            panel:CheckBox("Enable", "betterlights_item_healthkit_enable")
            panel:NumSlider("Radius", "betterlights_item_healthkit_size", 0, 300, 0)
            panel:NumSlider("Brightness", "betterlights_item_healthkit_brightness", 0, 2, 2)
            panel:NumSlider("Decay", "betterlights_item_healthkit_decay", 0, 5000, 0)
            panel:CheckBox("Add model elight", "betterlights_item_healthkit_models_elight")
            panel:NumSlider("Elight radius x", "betterlights_item_healthkit_models_elight_size_mult", 0, 3, 2)
            panel:Help("Color (RGB)")
            panel:NumSlider("Red", "betterlights_item_healthkit_color_r", 0, 255, 0)
            panel:NumSlider("Green", "betterlights_item_healthkit_color_g", 0, 255, 0)
            panel:NumSlider("Blue", "betterlights_item_healthkit_color_b", 0, 255, 0)
            addResetButton(panel, {
                betterlights_item_healthkit_enable = 1,
                betterlights_item_healthkit_size = 55,
                betterlights_item_healthkit_brightness = 0.2,
                betterlights_item_healthkit_decay = 1800,
                betterlights_item_healthkit_models_elight = 1,
                betterlights_item_healthkit_models_elight_size_mult = 1.0,
                betterlights_item_healthkit_color_r = 150,
                betterlights_item_healthkit_color_g = 255,
                betterlights_item_healthkit_color_b = 150,
            })
        end)

            -- Chargers (Suit/Health)
        spawnmenu.AddToolMenuOption("Better Lights", "Environment", "BL_Chargers", "Chargers", "", "", function(panel)
                panel:ClearControls()
                panel:Help("Subtle glows for suit and health wall chargers")
                -- Suit charger
                panel:CheckBox("Suit Charger", "betterlights_suitcharger_enable")
                panel:NumSlider("Suit Radius", "betterlights_suitcharger_size", 0, 300, 0)
                panel:NumSlider("Suit Brightness", "betterlights_suitcharger_brightness", 0, 2, 2)
                panel:NumSlider("Suit Decay", "betterlights_suitcharger_decay", 0, 5000, 0)
                panel:CheckBox("Suit model elight", "betterlights_suitcharger_models_elight")
                panel:NumSlider("Suit elight radius x", "betterlights_suitcharger_models_elight_size_mult", 0, 3, 2)
                panel:Help("Suit Color (RGB)")
                panel:NumSlider("Red", "betterlights_suitcharger_color_r", 0, 255, 0)
                panel:NumSlider("Green", "betterlights_suitcharger_color_g", 0, 255, 0)
                panel:NumSlider("Blue", "betterlights_suitcharger_color_b", 0, 255, 0)
                -- Health charger
                panel:CheckBox("Health Charger", "betterlights_healthcharger_enable")
                panel:NumSlider("Health Radius", "betterlights_healthcharger_size", 0, 300, 0)
                panel:NumSlider("Health Brightness", "betterlights_healthcharger_brightness", 0, 2, 2)
                panel:NumSlider("Health Decay", "betterlights_healthcharger_decay", 0, 5000, 0)
                panel:CheckBox("Health model elight", "betterlights_healthcharger_models_elight")
                panel:NumSlider("Health elight radius x", "betterlights_healthcharger_models_elight_size_mult", 0, 3, 2)
                panel:Help("Health Color (RGB)")
                panel:NumSlider("Red", "betterlights_healthcharger_color_r", 0, 255, 0)
                panel:NumSlider("Green", "betterlights_healthcharger_color_g", 0, 255, 0)
                panel:NumSlider("Blue", "betterlights_healthcharger_color_b", 0, 255, 0)
                addResetButton(panel, {
                    betterlights_suitcharger_enable = 1,
                    betterlights_suitcharger_size = 75,
                    betterlights_suitcharger_brightness = 0.25,
                    betterlights_suitcharger_decay = 1800,
                    betterlights_suitcharger_models_elight = 1,
                    betterlights_suitcharger_models_elight_size_mult = 1.0,
                    betterlights_suitcharger_color_r = 255,
                    betterlights_suitcharger_color_g = 180,
                    betterlights_suitcharger_color_b = 80,
                    betterlights_healthcharger_enable = 1,
                    betterlights_healthcharger_size = 75,
                    betterlights_healthcharger_brightness = 0.25,
                    betterlights_healthcharger_decay = 1800,
                    betterlights_healthcharger_models_elight = 1,
                    betterlights_healthcharger_models_elight_size_mult = 1.0,
                    betterlights_healthcharger_color_r = 110,
                    betterlights_healthcharger_color_g = 190,
                    betterlights_healthcharger_color_b = 255,
                })
            end)

    end

    -- About panel (credits + workshop link)
    local function addAboutPanel()
        spawnmenu.AddToolMenuOption("Better Lights", "About", "BL_About", "About", "", "", function(panel)
            panel:ClearControls()
            panel:Help("Author: Catsniffer")
            local btn = panel:Button("Steam Workshop Page")
            btn.DoClick = function()
                gui.OpenURL("https://steamcommunity.com/sharedfiles/filedetails/?id=3597784225")
            end
        end)
    end

    -- No server panels

    hook.Add("AddToolMenuTabs", "BetterLights_AddTab", function()
        spawnmenu.AddToolTab("Better Lights", "Better Lights", "icon16/lightbulb.png")
    end)

    hook.Add("PopulateToolMenu", "BetterLights_Populate", function()
        spawnmenu.AddToolCategory("Better Lights", "Weapons", "Weapons (Held)")
        spawnmenu.AddToolCategory("Better Lights", "Projectiles", "Projectiles & Explosives")
        spawnmenu.AddToolCategory("Better Lights", "NPCs", "NPCs & Traps")
        spawnmenu.AddToolCategory("Better Lights", "Eye Glow", "Eye Glow")
        spawnmenu.AddToolCategory("Better Lights", "Gunfire", "Gunfire")
        spawnmenu.AddToolCategory("Better Lights", "Environment", "Environment")
        spawnmenu.AddToolCategory("Better Lights", "Pickups", "Pickups")
        spawnmenu.AddToolCategory("Better Lights", "About", "About")
        addClientPanels()
        addAboutPanel()
    end)
end
