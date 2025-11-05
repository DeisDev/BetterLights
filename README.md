# BetterLights

A comprehensive dynamic lighting framework for Garry's Mod that adds realistic lights to entities, weapons, and effects.

## Features

- **Dynamic NPC Lights**: Manhacks, Rollermines (with hacked variant detection), Antlions (Guardian, Worker, Grub), Scanners, Combine Mines (hostile/resistance variants)
- **Weapon Effects**: Muzzle flashes, bullet impacts, crossbow bolts, RPG missiles, grenades, Magnusson devices
- **Physics Interactions**: Gravity Gun, Physics Gun, Tool Gun with hold/fire modes
- **Explosions**: Dynamic flashes for barrels, mines, RPG impacts, helicopter bombs, antlion spit
- **Pickup Glows**: Battery chargers, health chargers, item pickups
- **Entity Variant Detection**: Unified system for detecting friendly/hostile/hacked variants
- **Fully Configurable**: All lights controlled via ConVars (enable/disable, size, brightness, decay, RGB colors)
- **Performance Optimized**: Entity tracking, cached attachment lookups, unified Think aggregator
- **Extensible API**: Comprehensive framework for third-party mods

## API Documentation for Third-Party Mods

BetterLights provides a comprehensive framework for adding dynamic lights to entities. Third-party mods can use these functions to create their own light systems.

## Included Modules

BetterLights comes with lighting for 25+ entities and effects:

### NPCs and Creatures
- **Manhacks**: Oscillating red eye light
- **Rollermines**: Blue idle light, red when hostile, green when hacked/friendly
- **Antlion Grubs**: Soft green bioluminescent glow
- **Antlion Workers**: Yellow-green glow
- **Antlion Guardians**: Intense green glow with detection for cave guardian variants
- **City Scanners**: Blue/white scanning light with photograph flash
- **Combine Mines**: Blue idle, red proximity alert for hostile, green for resistance mines

### Weapons and Projectiles
- **Muzzle Flashes**: Dynamic flashes for all weapons with attachment detection
- **Bullet Impacts**: Brief impact flashes on world surfaces
- **Crossbow Bolts**: Glowing bolts with separate hold/fire lighting
- **RPG Missiles**: Bright rocket trail with explosion flash on impact
- **Grenades**: Pulsing fuse light, explosion flash
- **Combine Balls**: Crackling energy sphere light
- **Magnusson Devices**: Sticky bomb with explosion flash
- **Helicopter Bombs**: Dropped explosive with flash

### Physics Tools
- **Gravity Gun**: Blue hold light, orange/yellow fire blast
- **Physics Gun**: Adjustable beam color (default blue)
- **Tool Gun**: Color-coded beams per tool with hold/fire modes

### Environmental
- **Explosions**: Generic explosion flash system (barrels, props, etc.)
- **Fire**: Flickering orange flames
- **Antlion Spit**: Green acid projectile with splash flash
- **Chargers**: Soft glow for health/battery chargers when active
- **Pickups**: Subtle glow for health kits, batteries, ammo

All modules support:
- Enable/disable toggle
- Size, brightness, decay adjustment
- Full RGB color customization
- ConVar-based configuration

### Core Functions

#### `BL.AddThink(name, function)`
Register a Think callback that runs every frame.
- **name**: Unique string identifier for your think function
- **function**: The function to call each frame

**Example:**
```lua
BL.AddThink("MyMod_Lights", function()
    -- Your lighting code here
end)
```

#### `BL.RemoveThink(name)`
Unregister a Think callback.
- **name**: The identifier used in AddThink

#### `BL.ShouldTick(name, hz)`
Throttle updates to a specific rate. Useful for performance optimization.
- **name**: Unique identifier for this tick stream
- **hz**: Updates per second (0 or negative = every frame)
- **Returns**: true when it's time to update

**Example:**
```lua
BL.AddThink("MyMod_Lights", function()
    if BL.ShouldTick("MyLightUpdate", 30) then
        -- Update at 30 Hz instead of every frame
    end
end)
```

#### `BL.TrackClass(classname)`
Track entities of this class for efficient iteration. Automatically maintains a list of all entities of this class.
- **classname**: Entity class name (e.g., "npc_manhack")

#### `BL.ForEach(classname, function)`
Iterate over all tracked entities of a class. Automatically cleans up invalid entities.
- **classname**: Entity class name
- **function**: Called for each valid entity

**Example:**
```lua
BL.TrackClass("npc_manhack")
BL.AddThink("MyMod_ManhackLights", function()
    BL.ForEach("npc_manhack", function(ent)
        -- Process each manhack
    end)
end)
```

#### `BL.AddRemoveHandler(classname, function)`
Register a callback when an entity of this class is removed.
- **classname**: Entity class name
- **function**: Called with the removed entity

**Example:**
```lua
BL.AddRemoveHandler("npc_manhack", function(ent)
    -- Cleanup or spawn effects when manhack is removed
end)
```

### Utility Functions

#### `BL.GetEntityCenter(ent)`
Get the world-space center of an entity (OBB center).
- **Returns**: Vector or nil

**Example:**
```lua
local pos = BL.GetEntityCenter(ent)
if pos then
    -- Use the center position
end
```

#### `BL.GetColorFromCvars(r_cvar, g_cvar, b_cvar)`
Extract and clamp color values from ConVars (0-255 range).
- **Returns**: r, g, b (integers 0-255)

**Example:**
```lua
local cvar_r = CreateClientConVar("mymod_color_r", "255", true, false)
local cvar_g = CreateClientConVar("mymod_color_g", "128", true, false)
local cvar_b = CreateClientConVar("mymod_color_b", "64", true, false)

local r, g, b = BL.GetColorFromCvars(cvar_r, cvar_g, cvar_b)
```

#### `BL.CreateDLight(index, pos, r, g, b, brightness, decay, size, isElight)`
Create a dynamic light with standardized settings.
- **index**: Unique light ID (typically ent:EntIndex())
- **pos**: Vector position
- **r, g, b**: Color (0-255)
- **brightness**: Brightness multiplier
- **decay**: Decay rate
- **size**: Light radius
- **isElight**: true for model-only lights, false for world lights
- **Returns**: DynamicLight object or nil

**Example:**
```lua
local pos = ent:GetPos()
BL.CreateDLight(ent:EntIndex(), pos, 255, 128, 64, 1.0, 2000, 100, false)
```

#### `BL.NewLightId(base)`
Generate unique light IDs for ephemeral effects (projectiles, flashes, etc.).
- **base**: Base ID (default 60000)
- **Returns**: Unique integer ID

**Example:**
```lua
-- For temporary explosion flashes
local lightId = BL.NewLightId(65000)
BL.CreateDLight(lightId, pos, 255, 200, 100, 2.0, 3000, 200, false)
```

#### `BL.IsPlayerHoldingWeapon(weaponClass)`
Check if the local player is currently holding a specific weapon.
- **weaponClass**: Weapon class name (e.g., "weapon_physcannon")
- **Returns**: true if player is holding that weapon

**Example:**
```lua
if BL.IsPlayerHoldingWeapon("weapon_physcannon") then
    -- Add gravity gun effects
end
```

#### `BL.GetPlayerEyeTrace(distance, filter)`
Perform a trace from the player's eye position in their look direction.
- **distance**: Trace distance (default 8192)
- **filter**: Filter entity (default is the player)
- **Returns**: Trace result table or nil

**Example:**
```lua
local tr = BL.GetPlayerEyeTrace(4096)
if tr and tr.Hit then
    local hitPos = tr.HitPos
    -- Use trace result
end
```

#### `BL.LerpColor(r1, g1, b1, r2, g2, b2, t)`
Linearly interpolate between two RGB colors.
- **r1, g1, b1**: Start color
- **r2, g2, b2**: End color
- **t**: Interpolation factor (0-1)
- **Returns**: r, g, b (interpolated color)

**Example:**
```lua
-- Fade from red to blue over time
local t = math.abs(math.sin(CurTime()))
local r, g, b = BL.LerpColor(255, 0, 0, 0, 0, 255, t)
```

#### `BL.CreateFlickerEffect(baseValue, time, speed, amount, phase)`
Calculate a natural-looking flicker effect using layered sine waves.
- **baseValue**: Base value to flicker around
- **time**: Current time (typically CurTime())
- **speed**: Flicker speed multiplier
- **amount**: Flicker intensity (0-1)
- **phase**: Phase offset for variation
- **Returns**: Flickered value

**Example:**
```lua
local baseSize = 100
local now = CurTime()
local flickerSize = BL.CreateFlickerEffect(baseSize, now, 8, 0.15, ent:EntIndex())
-- flickerSize will oscillate naturally around 100
```

#### `BL.DetectEntityVariant(ent, options)`
Unified system for detecting entity variants (friendly/hostile/hacked/guardian versions). Uses multiple detection methods for maximum reliability.
- **ent**: Entity to check
- **options**: Table with detection criteria (see below)
- **Returns**: true if entity matches any criteria

**Options:**
- `classes`: Array of class names to check
- `nwBools`: Array of networked bool keys to check
- `saveTableKeys`: Array of SaveTable keys to check
- `saveTableKeyword`: Keyword to search for in SaveTable keys
- `checkDisposition`: true to check if entity likes the player (D_LI)
- `skin`: Skin number or function(skinNumber) returning true/false
- `targetname`: String to search for in entity's targetname
- `debugName`: Name for debug output
- `debugCvar`: ConVar to enable debug output

**Example:**
```lua
-- Detect hacked rollermines
local isHacked = BL.DetectEntityVariant(rollermine, {
    nwBools = {"Hacked", "Friendly"},
    saveTableKeys = {"m_bHackedByAlyx"},
    checkDisposition = true,
    debugName = "hacked"
})

-- Detect antlion guardians
local isGuardian = BL.DetectEntityVariant(antlion, {
    saveTableKeyword = "guardian",
    skin = function(s) return s == 1 end,
    debugName = "guardian"
})

-- Detect resistance mines
local isResistance = BL.DetectEntityVariant(mine, {
    skin = function(s) return s == 1 or s == 2 end,
    debugName = "resistance"
})
```

### Attachment Helpers

#### `BL.LookupAttachmentCached(ent, names)`
Find an attachment ID by trying multiple names. Results are cached per model for performance.
- **ent**: Entity to check
- **names**: Array of attachment names to try
- **Returns**: Attachment ID or nil

**Example:**
```lua
-- Try common muzzle flash attachment names
local attId = BL.LookupAttachmentCached(weapon, {"muzzle", "muzzle_flash", "1"})
if attId then
    -- Use attachment
end
```

#### `BL.GetAttachmentPos(ent, names)`
Get attachment position by trying multiple names. Internally uses LookupAttachmentCached.
- **ent**: Entity to check
- **names**: Array of attachment names to try
- **Returns**: Vector or nil

**Example:**
```lua
local pos = BL.GetAttachmentPos(ent, {"muzzle", "muzzle_flash", "1"})
if pos then
    -- Spawn light at attachment position
    BL.CreateDLight(ent:EntIndex(), pos, 255, 200, 100, 2.0, 3000, 150, false)
end
```

### Advanced Functions

#### `BL.TraceLineReuse(key, data)`
Perform a trace line using a reusable trace table to reduce garbage collection.
- **key**: Unique string identifier for this trace (allows multiple concurrent traces)
- **data**: Trace parameters (start, endpos, filter, mask, etc.)
- **Returns**: Trace result

**Example:**
```lua
local tr = BL.TraceLineReuse("mymod_check", {
    start = startPos,
    endpos = endPos,
    filter = ent
})
```

## Complete Example

Here's a complete example of adding lights to a custom entity:

```lua
if CLIENT then
    local BL = BetterLights
    
    -- Create ConVars
    local cvar_enable = CreateClientConVar("mymod_light_enable", "1", true, false)
    local cvar_size = CreateClientConVar("mymod_light_size", "100", true, false)
    local cvar_brightness = CreateClientConVar("mymod_light_brightness", "1", true, false)
    local cvar_decay = CreateClientConVar("mymod_light_decay", "2000", true, false)
    local cvar_r = CreateClientConVar("mymod_light_r", "255", true, false)
    local cvar_g = CreateClientConVar("mymod_light_g", "128", true, false)
    local cvar_b = CreateClientConVar("mymod_light_b", "64", true, false)
    local cvar_flicker = CreateClientConVar("mymod_light_flicker", "0.15", true, false)
    
    -- Track the entity class
    BL.TrackClass("my_custom_entity")
    
    -- Add the lighting logic
    BL.AddThink("MyMod_CustomEntityLight", function()
        if not cvar_enable:GetBool() then return end
        
        -- Throttle to 60 Hz for performance
        if not BL.ShouldTick("MyMod_EntityUpdate", 60) then return end
        
        -- Cache settings once per update
        local size = math.max(0, cvar_size:GetFloat())
        local brightness = math.max(0, cvar_brightness:GetFloat())
        local decay = math.max(0, cvar_decay:GetFloat())
        local flickerAmount = math.Clamp(cvar_flicker:GetFloat(), 0, 1)
        local r, g, b = BL.GetColorFromCvars(cvar_r, cvar_g, cvar_b)
        local now = CurTime()
        
        BL.ForEach("my_custom_entity", function(ent)
            local pos = BL.GetEntityCenter(ent)
            if not pos then return end
            
            -- Optional: Add flicker effect
            local finalSize = size
            if flickerAmount > 0 then
                finalSize = BL.CreateFlickerEffect(size, now, 8, flickerAmount, ent:EntIndex())
            end
            
            -- Create the dynamic light
            BL.CreateDLight(ent:EntIndex(), pos, r, g, b, brightness, decay, finalSize, false)
        end)
    end)
    
    -- Optional: Add explosion flash when removed
    hook.Add("EntityRemoved", "MyMod_EntityExplosion", function(ent, fullUpdate)
        if fullUpdate then return end
        if not IsValid(ent) or ent:GetClass() ~= "my_custom_entity" then return end
        
        local pos = BL.GetEntityCenter(ent)
        if pos then
            local lightId = BL.NewLightId(70000)
            BL.CreateDLight(lightId, pos, 255, 150, 50, 3.0, 5000, 300, false)
        end
    end)
end
```

## Advanced Example: Entity Variant Detection

Here's an example detecting friendly vs hostile variants:

```lua
if CLIENT then
    local BL = BetterLights
    
    local cvar_enable = CreateClientConVar("mymod_turret_enable", "1", true, false)
    local cvar_hostile_r = CreateClientConVar("mymod_turret_hostile_r", "255", true, false)
    local cvar_hostile_g = CreateClientConVar("mymod_turret_hostile_g", "0", true, false)
    local cvar_hostile_b = CreateClientConVar("mymod_turret_hostile_b", "0", true, false)
    local cvar_friendly_r = CreateClientConVar("mymod_turret_friendly_r", "0", true, false)
    local cvar_friendly_g = CreateClientConVar("mymod_turret_friendly_g", "255", true, false)
    local cvar_friendly_b = CreateClientConVar("mymod_turret_friendly_b", "0", true, false)
    
    BL.TrackClass("npc_turret_floor")
    
    BL.AddThink("MyMod_TurretLights", function()
        if not cvar_enable:GetBool() then return end
        
        local hr, hg, hb = BL.GetColorFromCvars(cvar_hostile_r, cvar_hostile_g, cvar_hostile_b)
        local fr, fg, fb = BL.GetColorFromCvars(cvar_friendly_r, cvar_friendly_g, cvar_friendly_b)
        
        BL.ForEach("npc_turret_floor", function(ent)
            -- Detect if turret is friendly
            local isFriendly = BL.DetectEntityVariant(ent, {
                checkDisposition = true,
                nwBools = {"Friendly", "PlayerAlly"},
                targetname = "friendly"
            })
            
            local r, g, b = isFriendly and fr, fg, fb or hr, hg, hb
            local pos = BL.GetEntityCenter(ent)
            if pos then
                BL.CreateDLight(ent:EntIndex(), pos, r, g, b, 1.0, 2000, 100, false)
            end
        end)
    end)
end
```

## Configuration

All lights can be configured through ConVars. Use the in-game console or the Options menu to adjust settings:

**Common ConVar Patterns:**
- `<module>_enable` - Enable/disable the light system (0 or 1)
- `<module>_size` - Light radius in units
- `<module>_brightness` - Brightness multiplier (0.0 to 10.0+)
- `<module>_decay` - How quickly light fades (lower = faster fade)
- `<module>_r/g/b` - Red/Green/Blue color values (0-255)

**Examples:**
```
// Disable manhack lights
bl_manhack_enable 0

// Make rollermine lights brighter and larger
bl_rollermine_brightness 2
bl_rollermine_size 150

// Change gravity gun color to purple
bl_gravitygun_r 255
bl_gravitygun_g 0
bl_gravitygun_b 255

// Adjust muzzle flash duration
bl_muzzleflash_time 0.05
```

Access the BetterLights menu via: **Options → BetterLights** for GUI-based configuration.

## Performance

BetterLights is designed for optimal performance with several built-in optimizations:

### Entity Tracking System
- **Class-based tracking**: Only iterates over registered entity classes
- **Automatic cleanup**: Invalid entities are removed automatically
- **On-demand registration**: Entities register when created via OnEntityCreated hook

### Caching
- **Attachment lookups**: Cached per model to avoid repeated LookupAttachment calls
- **Reusable trace tables**: Reduces garbage collection from frequent traces

### Throttling
- **BL.ShouldTick()**: Allows modules to run at specific Hz rates instead of every frame
- **Example**: Update lights at 30-60 Hz instead of 60+ fps for significant performance gains

### Unified Think Aggregator
- **Single Think hook**: All modules register callbacks instead of creating separate hooks
- **Error handling**: Failed Think functions are automatically unregistered
- **Centralized execution**: Reduces overhead from multiple hook calls

### Smart Effect Spawning
- **Distance checks**: Many effects check distance before spawning
- **Conditional rendering**: Effects respect enable/disable cvars

**Performance Tips for Mod Authors:**
```lua
-- Good: Throttled updates
BL.AddThink("MyMod", function()
    if BL.ShouldTick("MyModUpdate", 30) then
        -- Update at 30 Hz
    end
end)

-- Good: Cache ConVar reads
local size, brightness
if BL.ShouldTick("MyModCache", 10) then
    size = cvar_size:GetFloat()
    brightness = cvar_brightness:GetFloat()
end

-- Bad: Reading ConVars every frame per entity
BL.ForEach("my_entity", function(ent)
    local size = cvar_size:GetFloat()  -- Don't do this!
end)
```

## License

See the addon.json file for licensing information.
