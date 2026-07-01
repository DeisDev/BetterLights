BetterLights = BetterLights or {}

local BL = BetterLights

BL.NET_EVENT_MESSAGE = "BetterLights_Event"
BL.NET_FLASHLIGHT_CLIENT_ENABLE = "BetterLights_FlashlightClientEnable"
BL.NET_FLASHLIGHT_SOUND = "BetterLights_FlashlightSound"
BL.NET_SET_SERVER_BOOL = "BetterLights_SetServerBool"

BL.NET_MUZZLE_FLASH = 1
BL.NET_BULLET_IMPACT = 2
BL.NET_STRIDER_MUZZLE_FLASH = 3
BL.NET_STRIDER_BULLET_IMPACT = 4
BL.NET_HUNTER_CHOPPER_MUZZLE_FLASH = 5
BL.NET_HUNTER_CHOPPER_BULLET_IMPACT = 6
BL.NET_STUNSTICK_IMPACT = 7

BL.MUZZLE_FLASH_PAYLOAD_VERSION = 1
BL.MUZZLE_SOURCE_FIREBULLETS = 1
BL.MUZZLE_SOURCE_ADAPTER = 2
BL.MUZZLE_SOURCE_PREDICTED = 3

BL.MuzzleFlash = BL.MuzzleFlash or {}

do
    local MF = BL.MuzzleFlash

    MF.ColorTags = MF.ColorTags or {}
    MF.Profiles = MF.Profiles or {}
    MF.WeaponRules = MF.WeaponRules or {}
    MF.Adapters = MF.Adapters or {}

    local sourceRank = {
        builtin = 1,
        addon = 2,
        user = 3
    }

    local function copySequence(value)
        if type(value) ~= "table" then return nil end

        local out = {}
        for i = 1, #value do
            out[i] = value[i]
        end

        return out
    end

    local function normalizeString(value)
        if value == nil then return nil end

        value = tostring(value)
        if value == "" then return nil end

        return value
    end

    local function normalizeRule(def)
        if type(def) ~= "table" then return nil end

        local rule = {}
        rule.id = normalizeString(def.id)
        rule.class = normalizeString(def.class)
        rule.base = normalizeString(def.base)
        rule.ammo = normalizeString(def.ammo)
        rule.tracer = normalizeString(def.tracer)
        rule.profile = normalizeString(def.profile) or "default"
        rule.colorTag = normalizeString(def.colorTag)
        rule.priority = tonumber(def.priority) or 0
        rule.attachments = copySequence(def.attachments)
        rule.source = normalizeString(def.source) or "addon"
        rule.adapter = normalizeString(def.adapter)
        return rule
    end

    local function sortRules()
        table.sort(MF.WeaponRules, function(a, b)
            local ap = tonumber(a.priority) or 0
            local bp = tonumber(b.priority) or 0
            if ap ~= bp then return ap > bp end

            local as = sourceRank[a.source] or sourceRank.addon
            local bs = sourceRank[b.source] or sourceRank.addon
            if as ~= bs then return as > bs end

            return tostring(a.id or a.class or "") < tostring(b.id or b.class or "")
        end)
    end

    function MF.RegisterColorTag(tag, def)
        tag = normalizeString(tag)
        if not tag or type(def) ~= "table" then return nil end

        local color = {
            r = tonumber(def.r or def[1]) or 255,
            g = tonumber(def.g or def[2]) or 255,
            b = tonumber(def.b or def[3]) or 255,
            source = normalizeString(def.source) or "addon"
        }

        MF.ColorTags[tag] = color
        return color
    end

    function MF.RegisterProfile(id, def)
        id = normalizeString(id)
        if not id or type(def) ~= "table" then return nil end

        local profile = {}
        for k, v in pairs(def) do
            profile[k] = v
        end

        profile.id = id
        profile.source = normalizeString(profile.source) or "addon"
        MF.Profiles[id] = profile
        return profile
    end

    function MF.RegisterWeaponRule(def)
        local rule = normalizeRule(def)
        if not rule then return nil end

        MF.WeaponRules[#MF.WeaponRules + 1] = rule
        sortRules()
        return rule
    end

    function MF.RegisterAdapter(id, def)
        id = normalizeString(id)
        if not id or type(def) ~= "table" then return nil end

        def.id = id
        MF.Adapters[id] = def
        return def
    end

    function MF.ClearRulesBySource(source)
        source = normalizeString(source)
        if not source then return end

        for i = #MF.WeaponRules, 1, -1 do
            if MF.WeaponRules[i].source == source then
                table.remove(MF.WeaponRules, i)
            end
        end
    end

    function MF.ClearColorTagsBySource(source)
        source = normalizeString(source)
        if not source then return end

        for tag, def in pairs(MF.ColorTags) do
            if def.source == source then
                MF.ColorTags[tag] = nil
            end
        end
    end

    function MF.GetProfile(id)
        return MF.Profiles[id or "default"] or MF.Profiles.default
    end

    local function classMatches(ruleClass, ent)
        if not ruleClass then return true end
        if not (IsValid(ent) and ent.GetClass) then return false end

        return string.lower(ent:GetClass() or "") == string.lower(ruleClass)
    end

    local function baseMatches(ruleBase, ent)
        if not ruleBase then return true end
        if not IsValid(ent) then return false end

        local base = ent.Base
        if base == nil and ent.GetTable then
            local tab = ent:GetTable()
            base = tab and tab.Base
        end

        return string.lower(tostring(base or "")) == string.lower(ruleBase)
    end

    local function bulletMatches(rule, bullet)
        if not bullet then return not (rule.ammo or rule.tracer) end

        if rule.ammo and string.lower(tostring(bullet.AmmoType or "")) ~= string.lower(rule.ammo) then
            return false
        end

        if rule.tracer then
            local tracer = string.lower(tostring(bullet.TracerName or ""))
            if not string.find(tracer, string.lower(rule.tracer), 1, true) then
                return false
            end
        end

        return true
    end

    function MF.MatchWeaponRule(shooter, weapon, bullet, adapterId)
        for i = 1, #MF.WeaponRules do
            local rule = MF.WeaponRules[i]
            local classOk = classMatches(rule.class, weapon) or classMatches(rule.class, shooter)
            if classOk and baseMatches(rule.base, weapon) and bulletMatches(rule, bullet) and (not rule.adapter or rule.adapter == adapterId) then
                return rule
            end
        end

        return nil
    end
end
