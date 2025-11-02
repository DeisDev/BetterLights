# BetterLights
Clientside lighting tweaks for Garry's Mod. Adds dynamic light to effects that normally don't cast real light.

Current features:
- Combine AR2 orb (`prop_combine_ball`) emits a blue/cyan dynamic light as it travels.
- Crossbow bolt (`crossbow_bolt`) emits a warm orange dynamic light while it flies and when pinned.
- Crossbow (`weapon_crossbow`) passively emits a small orange light while held (configurable: only when bolt loaded).
- RPG rocket (`rpg_missile`) emits a warm flame light while in flight.
- Burning entities (Ignite tool, fire damage, etc.) emit a warm flame light with optional flicker and a models-only elight so the burning model is lit.
- Frag grenade (`npc_grenade_frag`) emits a subtle red glow while it rolls/flies.
- Physgun (`weapon_physgun`) emits a light that matches your Weapon Color setting.
- Gravity Gun (`weapon_physcannon`) emits a warm orange light from the muzzle.
- Tool Gun (`gmod_tool`) emits a small white light at the tip.
- Combine Mine (`combine_mine`) glows blue when idle and red when you're within range.
- Helicopter Bomb (`grenade_helicopter`) emits a steady red glow and a brief flash on explosion.
- Magnusson Device (`weapon_striderbuster`) emits a light blue glow and a brief flash on explosion.
- Manhack (`npc_manhack`) emits a red glow.
- Rollermine (`npc_rollermine`) emits a neutral blue glow.
- Rollermine (Hacked) (same class `npc_rollermine`, detected as hacked/ally) emits an orange glow.
- Combine Scanner (`npc_cscanner`) emits a cool white/blue glow.
	- Optional directional, shadow-casting searchlight (projected texture) that follows the scanner.
 - Pickups: `item_ammo_ar2_altfire`, `item_battery`, `item_healthvial`, `item_healthkit` emit very subtle light.
 - Bullet impacts: subtle flashes at impact positions (AR2 = blue, all others = warm orange).
 

Client ConVars:
- `betterlights_combineball_enable` (1/0) — enable/disable orb lighting. Default: 1
- `betterlights_combineball_size` — light radius. Default: 320
- `betterlights_combineball_brightness` — brightness scalar. Default: 2.5
- `betterlights_combineball_decay` — fade speed. Default: 2000

- `betterlights_bolt_enable` (1/0) — enable/disable crossbow bolt lighting. Default: 1
- `betterlights_bolt_size` — light radius. Default: 220
- `betterlights_bolt_brightness` — brightness scalar. Default: 0.96
- `betterlights_bolt_decay` — fade speed. Default: 2000

- `betterlights_crossbow_hold_enable` (1/0) — enable/disable passive light while holding Crossbow. Default: 1
- `betterlights_crossbow_hold_size` — light radius. Default: 70
- `betterlights_crossbow_hold_brightness` — brightness scalar. Default: 0.32
- `betterlights_crossbow_hold_decay` — fade speed. Default: 2000
- `betterlights_crossbow_hold_require_loaded` (1/0) — only emit light when a bolt is loaded. Default: 1

- `betterlights_rpg_enable` (1/0) — enable/disable RPG rocket lighting. Default: 1
- `betterlights_rpg_size` — light radius. Default: 280
- `betterlights_rpg_brightness` — brightness scalar. Default: 2.2
- `betterlights_rpg_decay` — fade speed. Default: 2000

- `betterlights_fire_enable` (1/0) — enable/disable light for burning entities. Default: 1
- `betterlights_fire_size` — light radius. Default: 160
- `betterlights_fire_brightness` — brightness scalar. Default: 5.2
- `betterlights_fire_decay` — fade speed. Default: 2000
- `betterlights_fire_models_elight` (1/0) — also add an entity light to light models directly (helps the burning entity itself). Default: 1
- `betterlights_fire_models_elight_size_mult` — multiplier for the model-only elight radius. Default: 1.0
- `betterlights_fire_flicker_enable` (1/0) — enable/disable fire light flicker. Default: 1
- `betterlights_fire_flicker_amount` — flicker intensity as a fraction of brightness. Default: 0.35
- `betterlights_fire_flicker_size_amount` — flicker intensity applied to radius. Default: 0.12
- `betterlights_fire_flicker_speed` — flicker speed. Default: 11.5

- `betterlights_grenade_enable` (1/0) — enable/disable grenade lighting. Default: 1
- `betterlights_grenade_size` — light radius. Default: 80
- `betterlights_grenade_brightness` — brightness scalar. Default: 0.9
- `betterlights_grenade_decay` — fade speed. Default: 1800
- `betterlights_grenade_models_elight` (1/0) — also add an entity light to light the grenade model. Default: 1
- `betterlights_grenade_models_elight_size_mult` — multiplier for grenade model elight radius. Default: 1.0

- `betterlights_combine_mine_enable` (1/0) — enable/disable Combine Mine lighting. Default: 1
- `betterlights_combine_mine_range` — distance to trigger alert glow (units). Default: 260
- `betterlights_combine_mine_size` — alert glow radius. Default: 140
- `betterlights_combine_mine_brightness` — alert glow brightness. Default: 1.2
- `betterlights_combine_mine_decay` — fade speed. Default: 2000
- `betterlights_combine_mine_idle_enable` (1/0) — enable a very dim idle glow when out of range. Default: 1
- `betterlights_combine_mine_idle_size` — idle glow radius. Default: 80
- `betterlights_combine_mine_idle_brightness` — idle glow brightness. Default: 0.25
- `betterlights_combine_mine_pulse_enable` (1/0) — subtle pulsing on alert. Default: 1
- `betterlights_combine_mine_pulse_amount` — pulse intensity fraction. Default: 0.15
- `betterlights_combine_mine_pulse_speed` — pulse speed. Default: 6.0
- `betterlights_combine_mine_models_elight` (1/0) — also add an entity light to light the mine model. Default: 1
- `betterlights_combine_mine_models_elight_size_mult` — multiplier for mine model elight radius. Default: 1.0

- `betterlights_physgun_enable` (1/0) — enable/disable physgun lighting matching your Weapon Color. Default: 1
- `betterlights_physgun_size` — light radius. Default: 33
- `betterlights_physgun_brightness` — brightness scalar. Default: 0.3
- `betterlights_physgun_decay` — fade speed. Default: 2000
- `betterlights_physgun_models_elight` (1/0) — also add an entity light to light the physgun model. Default: 1
- `betterlights_physgun_models_elight_size_mult` — multiplier for physgun model elight radius. Default: 1.0

- `betterlights_gravitygun_enable` (1/0) — enable/disable gravity gun lighting. Default: 1
- `betterlights_gravitygun_size` — light radius. Default: 36
- `betterlights_gravitygun_brightness` — brightness scalar. Default: 0.35
- `betterlights_gravitygun_decay` — fade speed. Default: 2000
- `betterlights_gravitygun_models_elight` (1/0) — also add an entity light to light the gravity gun model. Default: 1
- `betterlights_gravitygun_models_elight_size_mult` — multiplier for gravity gun model elight radius. Default: 1.0

- `betterlights_toolgun_enable` (1/0) — enable/disable Tool Gun lighting. Default: 1
- `betterlights_toolgun_size` — light radius. Default: 28
- `betterlights_toolgun_brightness` — brightness scalar. Default: 0.225
- `betterlights_toolgun_decay` — fade speed. Default: 2000
- `betterlights_toolgun_models_elight` (1/0) — also add an entity light to light the Tool Gun model. Default: 1
- `betterlights_toolgun_models_elight_size_mult` — multiplier for Tool Gun model elight radius. Default: 1.0

- `betterlights_heli_bomb_enable` (1/0) — enable/disable helicopter bomb lighting. Default: 1
- `betterlights_heli_bomb_size` — light radius. Default: 140
- `betterlights_heli_bomb_brightness` — brightness scalar. Default: 1.4
- `betterlights_heli_bomb_decay` — fade speed. Default: 2000
- `betterlights_heli_bomb_models_elight` (1/0) — also add an entity light to light the bomb model. Default: 1
- `betterlights_heli_bomb_models_elight_size_mult` — multiplier for bomb model elight radius. Default: 1.0
 - `betterlights_heli_bomb_flash_enable` (1/0) — add a brief light flash on explosion. Default: 1
 - `betterlights_heli_bomb_flash_size` — explosion flash radius. Default: 320
 - `betterlights_heli_bomb_flash_brightness` — explosion flash brightness. Default: 5.0
 - `betterlights_heli_bomb_flash_time` — explosion flash duration (seconds). Default: 0.18

- `betterlights_magnusson_enable` (1/0) — enable/disable Magnusson device lighting. Default: 1
- `betterlights_magnusson_size` — light radius. Default: 130
- `betterlights_magnusson_brightness` — brightness scalar. Default: 0.48
- `betterlights_magnusson_decay` — fade speed. Default: 2000
- `betterlights_magnusson_models_elight` (1/0) — also add an entity light to light the device model. Default: 1
- `betterlights_magnusson_models_elight_size_mult` — multiplier for device model elight radius. Default: 1.0
- `betterlights_magnusson_flash_enable` (1/0) — add a brief light flash on explosion. Default: 1
- `betterlights_magnusson_flash_size` — explosion flash radius. Default: 360
- `betterlights_magnusson_flash_brightness` — explosion flash brightness. Default: 2.2
- `betterlights_magnusson_flash_time` — explosion flash duration (seconds). Default: 0.14

- `betterlights_manhack_enable` (1/0) — enable/disable Manhack lighting. Default: 1
- `betterlights_manhack_size` — light radius. Default: 70
- `betterlights_manhack_brightness` — brightness scalar. Default: 0.6
- `betterlights_manhack_decay` — fade speed. Default: 2000
- `betterlights_manhack_models_elight` (1/0) — also add an entity light to light the Manhack model. Default: 1
- `betterlights_manhack_models_elight_size_mult` — multiplier for Manhack model elight radius. Default: 1.0

- `betterlights_rollermine_enable` (1/0) — enable/disable Rollermine lighting. Default: 1
- `betterlights_rollermine_size` — light radius. Default: 110
- `betterlights_rollermine_brightness` — brightness scalar. Default: 0.6
- `betterlights_rollermine_decay` — fade speed. Default: 2000
- `betterlights_rollermine_models_elight` (1/0) — also add an entity light to light the rollermine model. Default: 1
- `betterlights_rollermine_models_elight_size_mult` — multiplier for rollermine model elight radius. Default: 1.0

- `betterlights_rollermine_hacked_enable` (1/0) — enable/disable Hacked Rollermine lighting. Default: 1
- `betterlights_rollermine_hacked_size` — light radius. Default: 110
- `betterlights_rollermine_hacked_brightness` — brightness scalar. Default: 0.6
- `betterlights_rollermine_hacked_decay` — fade speed. Default: 2000
- `betterlights_rollermine_hacked_models_elight` (1/0) — also add an entity light to light the hacked rollermine model. Default: 1
- `betterlights_rollermine_hacked_models_elight_size_mult` — multiplier for hacked rollermine model elight radius. Default: 1.0

- `betterlights_cscanner_enable` (1/0) — enable/disable Combine Scanner lighting. Default: 1
- `betterlights_cscanner_size` — light radius. Default: 120
- `betterlights_cscanner_brightness` — brightness scalar. Default: 0.7
- `betterlights_cscanner_decay` — fade speed. Default: 2000
- `betterlights_cscanner_models_elight` (1/0) — also add an entity light to light the scanner model. Default: 1
- `betterlights_cscanner_models_elight_size_mult` — multiplier for scanner model elight radius. Default: 1.0
Pickups:
- `betterlights_item_ar2alt_enable` (1/0) — enable AR2 alt-fire ammo glow. Default: 1
- `betterlights_item_ar2alt_size` — radius. Default: 60
- `betterlights_item_ar2alt_brightness` — brightness. Default: 0.25
- `betterlights_item_ar2alt_decay` — decay. Default: 1800
- `betterlights_item_ar2alt_models_elight` (1/0) — add elight. Default: 1
- `betterlights_item_ar2alt_models_elight_size_mult` — elight size multiplier. Default: 1.0

- `betterlights_item_battery_enable` (1/0) — enable Battery glow. Default: 1
- `betterlights_item_battery_size` — radius. Default: 55
- `betterlights_item_battery_brightness` — brightness. Default: 0.2
- `betterlights_item_battery_decay` — decay. Default: 1800
- `betterlights_item_battery_models_elight` (1/0) — add elight. Default: 1
- `betterlights_item_battery_models_elight_size_mult` — elight size multiplier. Default: 1.0

- `betterlights_item_healthvial_enable` (1/0) — enable Health Vial glow. Default: 1
- `betterlights_item_healthvial_size` — radius. Default: 45
- `betterlights_item_healthvial_brightness` — brightness. Default: 0.18
- `betterlights_item_healthvial_decay` — decay. Default: 1800
- `betterlights_item_healthvial_models_elight` (1/0) — add elight. Default: 1
- `betterlights_item_healthvial_models_elight_size_mult` — elight size multiplier. Default: 1.0

- `betterlights_item_healthkit_enable` (1/0) — enable Health Kit glow. Default: 1
- `betterlights_item_healthkit_size` — radius. Default: 55
- `betterlights_item_healthkit_brightness` — brightness. Default: 0.2
- `betterlights_item_healthkit_decay` — decay. Default: 1800
- `betterlights_item_healthkit_models_elight` (1/0) — add elight. Default: 1
- `betterlights_item_healthkit_models_elight_size_mult` — elight size multiplier. Default: 1.0

 

Searchlight (Combine Scanner):
- `betterlights_cscanner_searchlight_enable` (1/0) — enable the directional searchlight. Default: 1
- `betterlights_scanner_searchlight_include_clawscanner` (1/0) — also attach to `npc_clawscanner` if present. Default: 1
- `betterlights_cscanner_searchlight_shadows` (1/0) — cast dynamic shadows (expensive). Default: 1
- `betterlights_cscanner_searchlight_fov` — searchlight FOV in degrees. Default: 38
- `betterlights_cscanner_searchlight_distance` — searchlight distance (FarZ). Default: 900
- `betterlights_cscanner_searchlight_near` — searchlight near plane (NearZ). Default: 8
- `betterlights_cscanner_searchlight_brightness` — searchlight brightness (0–1+). Default: 0.7

Performance note: Source allows only ~8 shadow-casting projected textures at once (shared with other lights/flashlights). Enabling shadows for many scanners can be expensive.

Notes:
- Only ~32 dynamic lights can be active at once. The scripts refresh lights every frame with a short `dietime`.
- All logic runs clientside under `lua/autorun/client/` to avoid server overhead.
 - Hacked Rollermine detection uses several heuristics available clientside: alternate skin (>0), common NWBools (`hacked`, `m_bHacked`, `friendly`), and a relationship check to the local player when accessible. If your friendly rollermine still appears blue, enable `betterlights_rollermine_debug 1` to print detection info, and report the skin/NW values.

Bullet Impacts:
- `betterlights_bullet_impact_enable` (1/0) — enable/disable subtle flashes at bullet impacts. Default: 1
- `betterlights_bullet_impact_size` — generic impact radius. Default: 60
- `betterlights_bullet_impact_brightness` — generic impact brightness. Default: 0.25
- `betterlights_bullet_impact_decay` — fade speed. Default: 1800
- `betterlights_bullet_impact_ar2_enable` (1/0) — use blue tint for AR2 impacts. Default: 1
- `betterlights_bullet_impact_ar2_size` — AR2 impact radius. Default: 70
- `betterlights_bullet_impact_ar2_brightness` — AR2 impact brightness. Default: 0.3

Installation:
- Place the `BetterLights` folder into `garrysmod/addons/`. Restart the game or reload Lua.
