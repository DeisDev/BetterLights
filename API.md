# BetterLights API Documentation

Complete API reference for developers building custom lighting modules or extending BetterLights.

For detailed examples and contribution guidelines, see [CONTRIBUTING.md](CONTRIBUTING.md).

## Table of Contents

- [Quick Start](#quick-start)
- [Core Functions](#core-functions)
- [Utility Functions](#utility-functions)
- [Complete Examples](#complete-examples)
- [Performance Best Practices](#performance-best-practices)

---

## Quick Start

The simplest way to add lights to your entities:

```lua
if CLIENT then
    local BL = BetterLights
    
    -- Create standard ConVars
    local cvars = BL.CreateConVarSet("mymod_light", {
        enable = 1, size = 100, brightness = 1.0, decay = 2000,
        r = 255, g = 128, b = 64
    })
    
    BL.TrackClass("my_custom_entity")
    
    BL.AddThink("MyMod_Lights", function()
        if not cvars.enable:GetBool() then return end
        
        local r, g, b = BL.GetColorFromCvars(cvars.r, cvars.g, cvars.b)
        
        BL.ForEach("my_custom_entity", function(ent)
            local pos = BL.GetEntityCenter(ent)
            if pos then
                BL.CreateDLight(ent:EntIndex(), pos, r, g, b, 
                    cvars.brightness:GetFloat(), cvars.decay:GetFloat(), 
                    cvars.size:GetFloat(), false)
            end
        end)
    end)
end
```

---

## Core Functions

### Think System

#### `BL.AddThink(name, function)`
Register a Think callback that runs every frame.
- **name** (string) - Unique identifier
- **function** (function) - Callback function

#### `BL.RemoveThink(name)`
Unregister a Think callback.

#### `BL.ShouldTick(name, hz)`
Throttle updates to a specific rate.
- **hz** (number) - Updates per second (0 = every frame)
- **Returns** true when it's time to update

```lua
BL.AddThink("MyMod", function()
    if BL.ShouldTick("Update", 30) then
        -- Update at 30 Hz instead of every frame
    end
end)
```

### Entity Tracking

#### `BL.TrackClass(classname)`
Track entities of this class for efficient iteration.

#### `BL.ForEach(classname, function)`
Iterate over all tracked entities. Automatically cleans up invalid entities.

```lua
BL.TrackClass("npc_manhack")
BL.ForEach("npc_manhack", function(ent)
    -- Process each manhack
end)
```

#### `BL.AddRemoveHandler(classname, function)`
Register a callback when an entity is removed.

---

## Utility Functions

### ConVar & Configuration

#### `BL.CreateConVarSet(prefix, defaults)`
**v3.0** - Create standard ConVars in one call.

```lua
local cvars = BL.CreateConVarSet("mymod_light", {
    enable = 1, size = 100, brightness = 1.0, decay = 2000,
    r = 255, g = 128, b = 64
})
```

#### `BL.GetColorFromCvars(r_cvar, g_cvar, b_cvar)`
Extract and clamp RGB values from ConVars (0-255 range).

### Flash Effects

#### `BL.CreateFlash(pos, r, g, b, size, brightness, duration, baseId)`
**v3.0** - Create a managed timed flash. Automatically rendered and cleaned up.

```lua
-- Explosion flash
BL.CreateFlash(pos, 255, 200, 100, 300, 4.0, 0.2, 65000)
```

### Entity Helpers

#### `BL.IsEntityClass(ent, classes)`
**v3.0** - Check if entity matches class(es).

```lua
if BL.IsEntityClass(ent, "npc_manhack") then end
if BL.IsEntityClass(ent, {"npc_cscanner", "npc_clawscanner"}) then end
```

#### `BL.MatchesModel(ent, pattern)`
**v3.0** - Check if entity model contains pattern (case-insensitive).

```lua
if BL.MatchesModel(ent, "barrel") then end
```

#### `BL.GetEntityCenter(ent)`
Get world-space center of entity (OBB center).

### Lighting

#### `BL.CreateDLight(index, pos, r, g, b, brightness, decay, size, isElight)`
Create a dynamic light with standardized settings.
- **index** (number) - Unique ID (typically ent:EntIndex())
- **isElight** (boolean) - true for model-only, false for world lights

```lua
BL.CreateDLight(ent:EntIndex(), pos, 255, 128, 64, 1.0, 2000, 100, false)
```

#### `BL.NewLightId(base)`
Generate unique light IDs for ephemeral effects.

### Effects

#### `BL.CreateFlickerEffect(baseValue, time, speed, amount, phase)`
Calculate natural-looking flicker using layered sine waves.

```lua
local size = BL.CreateFlickerEffect(100, CurTime(), 8, 0.15, ent:EntIndex())
```

#### `BL.LerpColor(r1, g1, b1, r2, g2, b2, t)`
Linearly interpolate between two RGB colors.

```lua
local r, g, b = BL.LerpColor(255, 0, 0, 0, 0, 255, t)
```

### Variant Detection

#### `BL.DetectEntityVariant(ent, options)`
Detect entity variants (friendly/hostile/hacked).

```lua
local isHacked = BL.DetectEntityVariant(rollermine, {
    nwBools = {"Hacked", "Friendly"},
    saveTableKeys = {"m_bHackedByAlyx"},
    checkDisposition = true
})
```

**Options:**
- `classes` - Array of class names
- `nwBools` - Array of networked bool keys
- `saveTableKeys` - Array of SaveTable keys
- `saveTableKeyword` - Keyword to search for
- `checkDisposition` - Check if entity likes player
- `skin` - Skin number or function
- `targetname` - String to search for

### Attachments

#### `BL.LookupAttachmentCached(ent, names)`
Find attachment ID by trying multiple names. Cached per model.

#### `BL.GetAttachmentPos(ent, names)`
Get attachment position by trying multiple names.

```lua
local pos = BL.GetAttachmentPos(weapon, {"muzzle", "muzzle_flash", "1"})
```

### Player

#### `BL.IsPlayerHoldingWeapon(weaponClass)`
Check if local player is holding specific weapon.

#### `BL.GetPlayerEyeTrace(distance, filter)`
Perform trace from player's eye position.

### Advanced

#### `BL.TraceLineReuse(key, data)`
Perform trace using reusable table to reduce GC.

---

## Complete Examples

### Basic Entity Light

```lua
if CLIENT then
    local BL = BetterLights
    
    local cvars = BL.CreateConVarSet("mymod_entity", {
        enable = 1, size = 100, brightness = 1.0, decay = 2000,
        r = 255, g = 128, b = 64
    })
    
    BL.TrackClass("my_custom_entity")
    
    BL.AddThink("MyMod_Light", function()
        if not cvars.enable:GetBool() then return end
        if not BL.ShouldTick("MyMod_Update", 60) then return end
        
        local r, g, b = BL.GetColorFromCvars(cvars.r, cvars.g, cvars.b)
        local size = cvars.size:GetFloat()
        local brightness = cvars.brightness:GetFloat()
        local decay = cvars.decay:GetFloat()
        
        BL.ForEach("my_custom_entity", function(ent)
            local pos = BL.GetEntityCenter(ent)
            if pos then
                BL.CreateDLight(ent:EntIndex(), pos, r, g, b, 
                    brightness, decay, size, false)
            end
        end)
    end)
    
    -- Explosion flash on removal
    hook.Add("EntityRemoved", "MyMod_Explosion", function(ent, fullUpdate)
        if fullUpdate then return end
        if not BL.IsEntityClass(ent, "my_custom_entity") then return end
        
        local pos = BL.GetEntityCenter(ent)
        if pos then
            BL.CreateFlash(pos, 255, 150, 50, 300, 3.0, 0.2, 70000)
        end
    end)
end
```

### Entity Variant Detection

```lua
if CLIENT then
    local BL = BetterLights
    
    BL.TrackClass("npc_turret_floor")
    
    BL.AddThink("MyMod_Turrets", function()
        BL.ForEach("npc_turret_floor", function(ent)
            local isFriendly = BL.DetectEntityVariant(ent, {
                checkDisposition = true,
                nwBools = {"Friendly", "PlayerAlly"}
            })
            
            local r = isFriendly and 0 or 255
            local g = isFriendly and 255 or 0
            local b = 0
            
            local pos = BL.GetEntityCenter(ent)
            if pos then
                BL.CreateDLight(ent:EntIndex(), pos, r, g, b, 1.0, 2000, 100, false)
            end
        end)
    end)
end
```

---

## Performance Best Practices

###  Use Unified Systems

```lua
-- Good: Unified flash system
BL.CreateFlash(pos, 255, 200, 100, 300, 3.0, 0.2, 65000)

-- Bad: Manual flash arrays (don't do this)
local myFlashes = {}
table.insert(myFlashes, {...})
```

###  Cache ConVar Reads

```lua
-- Good: Read once per frame
BL.AddThink("MyMod", function()
    local size = cvar_size:GetFloat()
    BL.ForEach("my_entity", function(ent)
        -- Use cached 'size'
    end)
end)

-- Bad: Read per entity
BL.ForEach("my_entity", function(ent)
    local size = cvar_size:GetFloat()  -- Don't!
end)
```

###  Use Update Throttling

```lua
-- Good: 30 Hz updates
BL.AddThink("MyMod", function()
    if BL.ShouldTick("Update", 30) then
        -- Update at 30 Hz
    end
end)
```

###  Use Entity Tracking

```lua
-- Good: Efficient iteration
BL.TrackClass("my_entity")
BL.ForEach("my_entity", function(ent) end)

-- Bad: Find every frame
for _, ent in ipairs(ents.FindByClass("my_entity")) do end
```

###  Use Helper Functions

```lua
-- Good: Use helpers
if BL.IsEntityClass(ent, "npc_manhack") then end

-- Bad: Manual validation
if IsValid(ent) and ent.GetClass and ent:GetClass() == "npc_manhack" then end
```

---

## Version 3.0 Features

- **Unified Flash System**: Automatic management, memory pooling, ~350 lines eliminated
- **Network Consolidation**: Single message with type routing, 66% overhead reduction
- **Memory Pooling**: Flash table recycling, reduces GC pressure
- **Helper Functions**: `CreateConVarSet()`, `IsEntityClass()`, `MatchesModel()`
- **Performance**: 26 total optimizations across framework

---

For more information:
- [README.md](README.md) - End-user documentation
- [CONTRIBUTING.md](CONTRIBUTING.md) - Detailed development guide
