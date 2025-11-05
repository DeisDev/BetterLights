# BetterLights

A comprehensive dynamic lighting framework for Garry's Mod that adds realistic lights to entities, weapons, and effects.

## Features

- **Dynamic NPC Lights**: Manhacks, Rollermines, Antlions, Scanners, Combine Mines
- **Weapon Effects**: Muzzle flashes, bullet impacts, crossbow bolts, RPG missiles, grenades
- **Physics Tools**: Gravity Gun, Physics Gun, Tool Gun
- **Explosions & Effects**: Barrels, mines, helicopter bombs, antlion spit, fire
- **Pickup Glows**: Chargers and item pickups
- **Fully Configurable**: All lights controlled via ConVars
- **Performance Optimized**: Entity tracking, unified flash system, memory pooling
- **Extensible Framework**: Build your own lighting modules (see [API.md](API.md))

## Installation

1. Subscribe to the addon on Steam Workshop, or
2. Download and extract to `garrysmod/addons/BetterLights`
3. Restart Garry's Mod
4. Configure via **Options → BetterLights** or console

## Included Modules

### NPCs
- **Manhacks** - Oscillating red eye light
- **Rollermines** - Blue (idle), red (hostile), green (hacked)
- **Antlion Grubs** - Soft green bioluminescent glow
- **Antlion Workers** - Yellow-green glow
- **Antlion Guardians** - Intense green glow
- **City Scanners** - Blue/white scanning light with photograph flash
- **Combine Mines** - Blue (idle), red (proximity), green (resistance)

### Weapons & Projectiles
- **Muzzle Flashes** - Dynamic flashes with attachment detection
- **Bullet Impacts** - Brief impact flashes on surfaces
- **Crossbow Bolts** - Glowing projectiles with hold/fire modes
- **RPG Missiles** - Bright rocket trails with explosion flashes
- **Grenades** - Pulsing fuse light + explosion flash
- **Combine Balls** - Crackling energy sphere
- **Magnusson Devices** - Sticky bomb with explosion
- **Helicopter Bombs** - Dropped explosives

### Tools
- **Gravity Gun** - Blue hold light, orange/yellow fire blast
- **Physics Gun** - Adjustable beam color (default blue)
- **Tool Gun** - Color-coded per tool with hold/fire modes

### Environmental
- **Explosions** - Generic explosion flash system
- **Fire** - Flickering orange flames
- **Antlion Spit** - Green acid projectile with splash
- **Chargers** - Soft glow when active
- **Pickups** - Subtle glow for items

## Configuration

All lights can be configured through ConVars in the console or via **Options → BetterLights**.

**Common ConVar Pattern:**
```
<module>_enable     - Enable/disable (0 or 1)
<module>_size       - Light radius
<module>_brightness - Brightness multiplier
<module>_decay      - Fade rate (lower = faster)
<module>_r/g/b      - RGB color (0-255)
```

**Examples:**
```
bl_manhack_enable 0              // Disable manhack lights
bl_rollermine_brightness 2       // Make rollermines brighter
bl_gravitygun_r 255              // Change gravity gun to purple
bl_gravitygun_g 0
bl_gravitygun_b 255
bl_muzzleflash_time 0.05         // Shorter muzzle flashes
```

## Performance

BetterLights v3.0 includes extensive optimizations:

- **Unified Flash System**: Single rendering loop, memory pooling (~350 lines eliminated)
- **Network Consolidation**: 66% reduction in network overhead
- **Entity Tracking**: Efficient iteration without repeated `ents.FindByClass()` calls
- **Smart Throttling**: Use `BL.ShouldTick()` to control update rates
- **Attachment Caching**: Model attachments cached per lookup

## For Developers

Want to add lighting to your own entities? See the comprehensive developer documentation:

- **[API.md](API.md)** - Complete API reference with examples
- **[CONTRIBUTING.md](CONTRIBUTING.md)** - Development guidelines and best practices

**Quick Example:**
```lua
local BL = BetterLights
local cvars = BL.CreateConVarSet("mymod_light", {
    enable = 1, size = 100, brightness = 1.0, decay = 2000,
    r = 255, g = 128, b = 64
})

BL.TrackClass("my_entity")
BL.AddThink("MyMod", function()
    if not cvars.enable:GetBool() then return end
    BL.ForEach("my_entity", function(ent)
        local pos = BL.GetEntityCenter(ent)
        if pos then
            BL.CreateDLight(ent:EntIndex(), pos, 
                BL.GetColorFromCvars(cvars.r, cvars.g, cvars.b),
                cvars.brightness:GetFloat(), cvars.decay:GetFloat(),
                cvars.size:GetFloat(), false)
        end
    end)
end)
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on:
- Module development patterns
- Performance best practices
- Code style and conventions
- Testing checklist

## License

See LICENSE for licensing information.
