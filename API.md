# BetterLights Developer Documentation (v3.0)

Complete, step-by-step guide for using the BetterLights framework in your own addons, plus a full API reference. This document shows you how to depend on the framework, structure your addon, and build dynamic lights quickly and correctly.

Links:
- End-user overview: README.md
- Contributing to this project: CONTRIBUTING.md

---

## What is BetterLights?

BetterLights is a client-side lighting framework for Garry’s Mod. It provides:

- A single, high-performance Think aggregator for all lighting logic
- A unified, pooled flash system for short-lived effects (explosions, impacts)
- Helpers for ConVars, entity tracking, attachment lookups, and variant detection
- A simple API so you can add dynamic lights to any entity in a few lines

You can use BetterLights as a dependency in a separate addon, or add a new module directly to this project.

---

## Getting Started

This section takes you from zero to a working addon that uses BetterLights.

### Requirements

- Garry’s Mod (x64 branch recommended for performance)
- BetterLights installed and enabled
  - For local development: place the BetterLights addon in `garrysmod/addons/`
  - For Workshop: add BetterLights as a “Required Item” on your Workshop page (Steam UI)

Note: Garry’s Mod does not enforce runtime dependencies via `addon.json`. Always perform a runtime check for the `BetterLights` global in your client code.

### Project Structure (Separate Addon)

Create a new addon alongside BetterLights:

```
garrysmod/
  addons/
	BetterLights/                       # This framework (dependency)
	MyLightingAddon/                    # Your addon
	  addon.json
	  README.md                         # Optional
	  lua/
		autorun/
		  client/
			mylights_init.lua           # Your lighting code (client)
		  server/
			mylights_server.lua         # Optional (only if you need server logic)
```

Example `addon.json` (metadata only – dependencies are managed on Workshop page):
```json
{
  "title": "My Lighting Addon (BetterLights)",
  "type": "ServerContent",
  "tags": ["effects"],
  "ignore": ["*.git*", "*.md", "*.psd"]
}
```

### Minimal Integration (Hello Light)

Create `lua/autorun/client/mylights_init.lua` in your addon:

```lua
if CLIENT then
	if not BetterLights then
		print("[MyLights] BetterLights not found. Please install/enable BetterLights.")
		return
	end

	local BL = BetterLights

	-- Standard, user-configurable ConVars for one light family
	local cvars = BL.CreateConVarSet("mylights_example", {
		enable = 1, size = 120, brightness = 1.2, decay = 2000,
		r = 255, g = 200, b = 100
	})

	-- Track an existing entity class (example: manhack)
	BL.TrackClass("npc_manhack")

	BL.AddThink("MyLights_Example", function()
		if not cvars.enable:GetBool() then return end

		local r, g, b = BL.GetColorFromCvars(cvars.r, cvars.g, cvars.b)
		local size = cvars.size:GetFloat()
		local brightness = cvars.brightness:GetFloat()
		local decay = cvars.decay:GetFloat()

		BL.ForEach("npc_manhack", function(ent)
			local pos = BL.GetEntityCenter(ent)
			if pos then
				BL.CreateDLight(ent:EntIndex(), pos, r, g, b, brightness, decay, size, false)
			end
		end)
	end)
end
```

Run the game, spawn a manhack, and tweak the `mylights_example_*` ConVars to see results.

### Declaring a Workshop Dependency

- On your Steam Workshop item, add BetterLights as a “Required Item”.
- In code, always check for the `BetterLights` global to avoid errors if a user disables it.

### When to use server code

Most BetterLights work is client-side. Only use server code if you:
- Need to send events to nearby clients (e.g., custom muzzle flash events)
- Need server validation for custom entities

For most addons, client-only is sufficient.

---

## Full Walkthrough: Build a Lighting Addon

We’ll build “My Turret Lights,” which lights up custom turrets and flashes on destruction.

Folder layout:
```
MyTurretLights/
  addon.json
  lua/
	autorun/
	  client/
		myturret_lights.lua
```

`addon.json`:
```json
{
  "title": "My Turret Lights (BetterLights)",
  "type": "ServerContent",
  "tags": ["effects", "fun"],
  "ignore": ["*.git*", "*.md"]
}
```

`lua/autorun/client/myturret_lights.lua`:
```lua
if CLIENT then
	if not BetterLights then
		print("[MyTurretLights] BetterLights is missing. Install the dependency.")
		return
	end
	local BL = BetterLights

	-- Config ConVars (hostile color defaults to red)
	local cvars = BL.CreateConVarSet("myturret", {
		enable = 1, size = 150, brightness = 1.5, decay = 2000,
		r = 255, g = 64, b = 64
	})
	-- Optional extra ConVars
	local cvar_friendly_r = CreateClientConVar("myturret_friendly_r", "64", true, false)
	local cvar_friendly_g = CreateClientConVar("myturret_friendly_g", "255", true, false)
	local cvar_friendly_b = CreateClientConVar("myturret_friendly_b", "64", true, false)
	local cvar_flicker    = CreateClientConVar("myturret_flicker", "0.10", true, false)
	local cvar_flash      = CreateClientConVar("myturret_explosion_flash", "1", true, false)

	-- Track your turret class (replace with your SENT/NextBot class)
	BL.TrackClass("sent_my_custom_turret")

	BL.AddThink("MyTurretLights", function()
		if not cvars.enable:GetBool() then return end
		if not BL.ShouldTick("MyTurret_Update", 30) then return end -- 30 Hz

		local size       = math.max(0, cvars.size:GetFloat())
		local brightness = math.max(0, cvars.brightness:GetFloat())
		local decay      = math.max(0, cvars.decay:GetFloat())
		local fr, fg, fb = BL.GetColorFromCvars(cvar_friendly_r, cvar_friendly_g, cvar_friendly_b)
		local hr, hg, hb = BL.GetColorFromCvars(cvars.r, cvars.g, cvars.b)
		local now        = CurTime()
		local flickerAmt = math.Clamp(cvar_flicker:GetFloat(), 0, 1)

		BL.ForEach("sent_my_custom_turret", function(ent)
			-- Attachment or center
			local pos = BL.GetAttachmentPos(ent, {"light", "eye", "muzzle"}) or BL.GetEntityCenter(ent)
			if not pos then return end

			-- Friendly vs hostile color
			local isFriendly = BL.DetectEntityVariant(ent, {
				checkDisposition = true,
				nwBools = {"Friendly", "PlayerAlly"},
				saveTableKeys = {"m_bFriendly"},
				targetname = "friendly"
			})
			local r, g, b = isFriendly and fr or hr, isFriendly and fg or hg, isFriendly and fb or hb

			local finalSize = size
			if flickerAmt > 0 then
				finalSize = BL.CreateFlickerEffect(size, now, 8, flickerAmt, ent:EntIndex())
			end

			BL.CreateDLight(ent:EntIndex(), pos, r, g, b, brightness, decay, finalSize, false)
		end)
	end)

	-- Flash when a turret is removed (e.g., destroyed)
	hook.Add("EntityRemoved", "MyTurretLights_Flash", function(ent, fullUpdate)
		if fullUpdate then return end
		if not BL.IsEntityClass(ent, "sent_my_custom_turret") then return end
		if not cvar_flash:GetBool() then return end
		local pos = BL.GetEntityCenter(ent)
		if pos then
			BL.CreateFlash(pos, 255, 200, 100, 400, 4.0, 0.3, 70000)
		end
	end)
end
```

Testing checklist:
- Subscribe to BetterLights on Workshop (or drop it into `addons/`)
- Place this addon into `addons/MyTurretLights`
- Launch GMod (x64 branch recommended)
- Spawn your entity class `sent_my_custom_turret`
- Use console ConVars to adjust size/brightness/colors

---

## Do’s and Don’ts

### Do
- Use `BL.AddThink` for your logic instead of adding many global hooks
- Track entities with `BL.TrackClass` and iterate with `BL.ForEach`
- Cache ConVar reads once per frame; don’t read them per-entity
- Throttle with `BL.ShouldTick("Name", 30)` when 30 Hz is enough
- Use `BL.CreateFlash` for short-lived effects instead of rolling your own arrays
- Prefer `BL.LookupAttachmentCached` / `BL.GetAttachmentPos` for attachment positions

### Don’t
- Don’t call `ents.FindByClass` every frame; register once and use `BL.ForEach`
- Don’t re-implement flash arrays/render loops — use `BL.CreateFlash`
- Don’t generate random/new light IDs each frame for persistent lights; use `ent:EntIndex()`
- Don’t keep stale references; always verify with `IsValid(ent)` where needed
- Don’t spam network messages for effects already handled client-side

Bad example (don’t do this):
```lua
-- Reads ConVar per entity and searches entities every frame
hook.Add("Think", "MyLaggyLights", function()
	for _, ent in ipairs(ents.FindByClass("npc_manhack")) do
		local size = GetConVar("mylights_size"):GetFloat() -- slow repeated lookup
		-- ...
	end
end)
```

Good example:
```lua
BL.TrackClass("npc_manhack")
BL.AddThink("MyFastLights", function()
	local size = GetConVar("mylights_size"):GetFloat()
	BL.ForEach("npc_manhack", function(ent)
		-- use cached size
	end)
end)
```

---

## API Reference

This is the public, stable surface intended for addon authors.

### Think & Scheduling

#### BL.AddThink(name, fn)
Register a function to be executed from the BetterLights Think aggregator each frame.
- name: string, unique identifier
- fn: function()

#### BL.RemoveThink(name)
Unregister a previously registered Think function.

#### BL.ShouldTick(name, hz)
Return true only at the requested rate (updates per second). Use to throttle work.
- name: string, unique ID for this throttle stream
- hz: number, e.g., 30 for 30 Hz; 0 or negative means every frame
- returns: boolean

### Entity Tracking

#### BL.TrackClass(classname)
Start tracking all entities of a class. Recommended before using `BL.ForEach`.

#### BL.ForEach(classname, fn)
Iterate over all currently tracked, valid entities of a class.
- fn(ent): called for each valid entity

#### BL.AddRemoveHandler(classname, fn)
Run a callback when entities of a class are removed.

### Flash Effects

#### BL.CreateFlash(pos, r, g, b, size, brightness, duration, baseId)
Create a short-lived, pooled flash that’s rendered and cleaned up automatically.
- pos: Vector
- r,g,b: integers 0–255
- size: number (radius)
- brightness: number
- duration: seconds
- baseId: base light ID (default 60000)
- returns: flash object (advanced)

### Lights

#### BL.CreateDLight(index, pos, r, g, b, brightness, decay, size, isElight)
Create a dynamic light with standard fields populated.
- index: number, use `ent:EntIndex()` for persistent per-entity lights
- pos: Vector
- r,g,b: integers 0–255
- brightness, decay, size: numbers
- isElight: boolean (true = model-only, false = world light)
- returns: DynamicLight struct or nil

#### BL.NewLightId(base)
Generate a unique ID for ephemeral effects you manage manually.
- base: number (default 60000)

### ConVars & Colors

#### BL.CreateConVarSet(prefix, defaults)
Create a standard set of ConVars in one call.
- prefix: string (e.g., "mymod_weapon")
- defaults: table { enable, size, brightness, decay, r, g, b, ...Desc }
- returns: table of ConVar objects

#### BL.GetColorFromCvars(r_cvar, g_cvar, b_cvar)
Clamp and return integer RGB values from ConVars.
- returns: r, g, b (0–255)

### Entity Helpers

#### BL.IsEntityClass(ent, classes)
Return true if ent is valid and its class matches a string or any string in a table.

#### BL.MatchesModel(ent, pattern)
Case-insensitive substring check against `ent:GetModel()`.

#### BL.GetEntityCenter(ent)
Return the world-space OBB center of an entity, or nil.

### Attachments

#### BL.LookupAttachmentCached(ent, names)
Try a list of attachment names; returns ID or nil. Results cached per model.

#### BL.GetAttachmentPos(ent, names)
Return attachment world position if found, otherwise nil.

### Player / Traces / Math

#### BL.IsPlayerHoldingWeapon(weaponClass)
Return true if the local player is holding the specified weapon.

#### BL.GetPlayerEyeTrace(distance, filter)
Trace forward from player view; returns a trace table or nil.

#### BL.TraceLineReuse(key, data)
Run util.TraceLine with a reusable table to reduce allocations.

#### BL.LerpColor(r1, g1, b1, r2, g2, b2, t)
Linear interpolate between two colors; return r,g,b.

#### BL.CreateFlickerEffect(baseValue, time, speed, amount, phase)
Layered-sine flicker helper; returns a new value around baseValue.

### Variant Detection

#### BL.DetectEntityVariant(ent, options)
Heuristics to detect entity “variants” (e.g., friendly vs hostile) using multiple signals.
Options may include: `classes`, `nwBools`, `saveTableKeys`, `saveTableKeyword`, `checkDisposition`, `skin`, `targetname`, `debugName`, `debugCvar`.

---

## Advanced Examples

### Attachment-first light with distance culling
```lua
BL.TrackClass("npc_cscanner")
BL.AddThink("ScannerLights", function()
	local r, g, b = 180, 200, 255
	local size, brightness, decay = 140, 1.2, 2000
	local viewer = LocalPlayer()
	local vpos = IsValid(viewer) and viewer:GetPos() or nil

	BL.ForEach("npc_cscanner", function(ent)
		if vpos and ent:GetPos():DistToSqr(vpos) > (2000*2000) then return end
		local pos = BL.GetAttachmentPos(ent, {"light", "muzzle"}) or BL.GetEntityCenter(ent)
		if pos then BL.CreateDLight(ent:EntIndex(), pos, r, g, b, brightness, decay, size, false) end
	end)
end)
```

### Impact flash on bullet traces (client-only demo)
```lua
hook.Add("EntityFireBullets", "MyImpactFlash", function(ply, data)
	timer.Simple(0, function()
		local tr = util.TraceLine({start = data.Src, endpos = data.Src + data.Dir * 4096, filter = ply})
		if tr.Hit then
			BetterLights.CreateFlash(tr.HitPos, 255, 220, 180, 160, 2.0, 0.08, 65000)
		end
	end)
end)
```

---

## Contributing to BetterLights (Using the API)

You can contribute a new module to this project using the same APIs your addon would use. Keep modules self-contained, client-side, and consistent with existing style.

### Where to put files
- Create a new client module in `lua/autorun/client/`
- File name: `betterlights_<feature>.lua` (e.g., `betterlights_turret.lua`)

### Module template
```lua
-- BetterLights: Turret Lights
-- Adds dynamic lights to turrets

if CLIENT then
	local BL = BetterLights
	if not BL then return end

	local cvars = BL.CreateConVarSet("bl_turret", {
		enable = 1, size = 140, brightness = 1.2, decay = 2000,
		r = 255, g = 80, b = 60
	})

	BL.TrackClass("npc_turret_floor")

	BL.AddThink("BetterLights_Turret", function()
		if not cvars.enable:GetBool() then return end
		local r, g, b = BL.GetColorFromCvars(cvars.r, cvars.g, cvars.b)
		BL.ForEach("npc_turret_floor", function(ent)
			local pos = BL.GetEntityCenter(ent)
			if pos then BL.CreateDLight(ent:EntIndex(), pos, r, g, b, cvars.brightness:GetFloat(), cvars.decay:GetFloat(), cvars.size:GetFloat(), false) end
		end)
	end)
end
```

### Style & performance checklist
- Use `BL.AddThink` (one Think per module)
- Read ConVars once per frame, not per entity
- Use `BL.TrackClass` + `BL.ForEach` (never `ents.FindByClass` every frame)
- Use `BL.CreateFlash` for temporary effects
- Consider `BL.ShouldTick(…, 30)` for throttling
- Add comments for non-obvious logic

### Testing before PR
- No Lua errors in console
- Works with and without other popular addons (basic sanity)
- Performance acceptable in busy scenes (use `developer 1`)
- ConVars behave as expected

Submit a PR with:
- Clear description and screenshots/GIFs
- Notes on any variant detection heuristics
- Link to discussion/issue if relevant

---

## Troubleshooting

### “BetterLights not found”
- Ensure the BetterLights addon is installed and enabled
- Add a short delay on Initialize if needed
```lua
hook.Add("Initialize", "MyAddon_WaitBL", function()
	if not BetterLights then timer.Simple(1, function() if not BetterLights then print("[MyAddon] BetterLights missing") end end) end
end)
```

### Lights don’t show up
- Verify entity class names (print `ent:GetClass()`)
- Check positions (print `BL.GetEntityCenter(ent)`)
- Ensure `r_dynamic 1`
- Ensure your `*_enable` ConVar is 1

### Flicker/disappear
- Keep a stable ID: use `ent:EntIndex()` for persistent lights
- Avoid per-frame random IDs
- Use `BL.ShouldTick` to prevent thrashing

### Slow performance
- Throttle to 30–60 Hz
- Cache ConVars per frame
- Distance cull with `DistToSqr`

---

## Version 3.0 Highlights

- Unified flash system (pooled, auto cleanup)
- Single Think aggregator (less overhead)
- Entity tracking + attachment caching
- Network consolidation for built-in effects
- Helper functions: ConVars, variants, color math

---

Happy hacking. If you build something cool with BetterLights, consider releasing it as a separate addon and adding BetterLights as a Required Item — or contribute it here as a new module!

