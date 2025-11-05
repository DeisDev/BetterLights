# Contributing to BetterLights

Thank you for your interest in contributing to BetterLights! This document provides guidelines for adding new modules or improving existing code.

## Module Development Guidelines

### 1. Use Unified Systems

BetterLights provides several unified systems that reduce code duplication and improve performance:

**Flash Management:**
\\\lua
--  Good: Use BL.CreateFlash()
BL.CreateFlash(pos, r, g, b, size, brightness, duration, baseId)

--  Bad: Manual flash management
local myFlashes = {}
table.insert(myFlashes, {...})
-- Don't manually render in Think loop
\\\

**ConVar Creation:**
\\\lua
--  Good: Use BL.CreateConVarSet()
local cvars = BL.CreateConVarSet("mymod_light", {
    enable = 1, size = 100, brightness = 1.0,
    r = 255, g = 128, b = 64
})

--  Bad: Manual ConVar creation for every parameter
local cvar_enable = CreateClientConVar(...)
local cvar_size = CreateClientConVar(...)
-- ...etc (repetitive)
\\\

**Entity Detection:**
\\\lua
--  Good: Use helpers
if BL.IsEntityClass(ent, "npc_manhack") then end
if BL.MatchesModel(ent, "barrel") then end

--  Bad: Manual validation
if IsValid(ent) and ent.GetClass and ent:GetClass() == "npc_manhack" then end
\\\

### 2. Standard Module Pattern

Follow this structure for new modules:

\\\lua
-- BetterLights: [Module Name]
-- [Description]

if CLIENT then
    BetterLights = BetterLights or {}
    local BL = BetterLights
    
    -- ConVars
    local cvars = BL.CreateConVarSet("mymod_entity", {
        enable = 1,
        size = 100,
        brightness = 1.0,
        decay = 2000,
        r = 255, g = 128, b = 64
    })
    
    -- Track entity class
    if BL.TrackClass then BL.TrackClass("my_entity_class") end
    
    -- Main lighting logic
    local AddThink = BL.AddThink or function(name, fn) hook.Add("Think", name, fn) end
    AddThink("BetterLights_MyEntity", function()
        if not cvars.enable:GetBool() then return end
        
        -- Cache settings once per frame
        local r, g, b = BL.GetColorFromCvars(cvars.r, cvars.g, cvars.b)
        local size = math.max(0, cvars.size:GetFloat())
        local brightness = math.max(0, cvars.brightness:GetFloat())
        local decay = math.max(0, cvars.decay:GetFloat())
        
        local function update(ent)
            if not IsValid(ent) then return end
            local pos = BL.GetEntityCenter(ent)
            if not pos then return end
            
            BL.CreateDLight(ent:EntIndex(), pos, r, g, b, brightness, decay, size, false)
        end
        
        if BL.ForEach then
            BL.ForEach("my_entity_class", update)
        else
            for _, ent in ipairs(ents.FindByClass("my_entity_class")) do update(ent) end
        end
    end)
    
    -- Optional: Explosion flash on removal
    hook.Add("EntityRemoved", "BetterLights_MyEntity_Flash", function(ent, fullUpdate)
        if fullUpdate then return end
        if not BL.IsEntityClass(ent, "my_entity_class") then return end
        
        local pos = BL.GetEntityCenter(ent)
        if pos then
            local r, g, b = BL.GetColorFromCvars(cvars.r, cvars.g, cvars.b)
            BL.CreateFlash(pos, r, g, b, 300, 3.0, 0.2, 65000)
        end
    end)
end
\\\

### 3. Performance Best Practices

**Cache ConVar Reads:**
\\\lua
--  Good: Read once per frame
BL.AddThink("MyMod", function()
    local size = cvar_size:GetFloat()
    BL.ForEach("my_entity", function(ent)
        -- Use cached 'size' value
    end)
end)

--  Bad: Read per entity
BL.ForEach("my_entity", function(ent)
    local size = cvar_size:GetFloat()  -- Don't do this!
end)
\\\

**Use Update Throttling:**
\\\lua
--  Good: Update at reasonable rate
BL.AddThink("MyMod", function()
    if BL.ShouldTick("MyModUpdate", 30) then
        -- Update at 30 Hz instead of 60+ fps
    end
end)
\\\

**Use Entity Tracking:**
\\\lua
--  Good: Efficient iteration
BL.TrackClass("my_entity")
BL.ForEach("my_entity", function(ent) ... end)

--  Bad: Find all entities every frame
for _, ent in ipairs(ents.FindByClass("my_entity")) do ... end
\\\

### 4. Naming Conventions

- **Module files**: \etterlights_[module_name].lua\
- **ConVar prefix**: \etterlights_[module]_*\ (or your mod's prefix)
- **Think callbacks**: \BetterLights_[Module]_[Purpose]\
- **Hooks**: \BetterLights_[Module]_[Purpose]\

### 5. Code Style

- **Indentation**: 4 spaces (no tabs)
- **Comments**: Explain non-obvious logic
- **Localize globals**: Cache frequently-used globals at top of file
- **Error handling**: Check \IsValid()\ before accessing entities
- **Fallbacks**: Provide fallbacks if BL functions aren't available

Example:
\\\lua
-- Localize globals
local CurTime = CurTime
local IsValid = IsValid
local DynamicLight = DynamicLight

-- Fallback for AddThink
local AddThink = BL.AddThink or function(name, fn) hook.Add("Think", name, fn) end
\\\

### 6. Testing Checklist

Before submitting a module:

- [ ] No Lua errors in console
- [ ] Lights appear and update correctly
- [ ] ConVars work (enable/disable, size, brightness, color)
- [ ] Performance is acceptable (use \developer 1\ to check frame times)
- [ ] Works with and without BetterLights core (has fallbacks)
- [ ] Cleans up properly (lights removed when entities removed)
- [ ] Respects ConVar settings (e.g., disabled lights don't appear)

### 7. Documentation

Include comments in your module:

\\\lua
-- BetterLights: [Module Name]
-- [Brief description of what this module does]
-- Entities: [entity classes it affects]
-- Special behavior: [any unique features or quirks]
\\\

Add your module to the README.md:
- Add to the module list with description
- Document any unique ConVars or features
- Provide example configuration if complex

### 8. Pull Request Process

1. **Fork** the repository
2. **Create a branch** for your feature: \git checkout -b feature/my-new-module\
3. **Commit** your changes with clear messages
4. **Test** thoroughly (see checklist above)
5. **Push** to your fork: \git push origin feature/my-new-module\
6. **Create a Pull Request** with:
   - Clear title describing the feature
   - Description of what the module does
   - Any special configuration or notes
   - Screenshots/video if applicable

### 9. Common Patterns

**Flickering Effect:**
\\\lua
local now = CurTime()
local flickerSize = BL.CreateFlickerEffect(baseSize, now, 8, 0.15, ent:EntIndex())
\\\

**Color Interpolation:**
\\\lua
local t = math.abs(math.sin(CurTime()))
local r, g, b = BL.LerpColor(255, 0, 0, 0, 0, 255, t)
\\\

**Variant Detection:**
\\\lua
local isFriendly = BL.DetectEntityVariant(ent, {
    checkDisposition = true,
    nwBools = {"Friendly"},
    targetname = "friendly"
})
\\\

**Attachment-based Position:**
\\\lua
local pos = BL.GetAttachmentPos(ent, {"muzzle", "muzzle_flash", "1"})
    or BL.GetEntityCenter(ent)
\\\

## Questions?

If you have questions about contributing, feel free to:
- Open an issue for discussion
- Check existing modules for examples
- Review the README.md API documentation

Thank you for helping make BetterLights better!
