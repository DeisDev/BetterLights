if SERVER then
    local BL = BetterLights

    util.AddNetworkString(BL.NET_FLASHLIGHT_CLIENT_ENABLE)
    util.AddNetworkString(BL.NET_FLASHLIGHT_SOUND)

    local INPUT_DEBOUNCE = 0.05
    local MWBASE_FLASHLIGHT_HOOK = "MW19_PlayerSwitchFlashlight"

    local PLAYER = FindMetaTable("Player")

    local function getWeaponBase(weapon)
        if not IsValid(weapon) then return "" end

        local base = weapon.Base
        if base == nil and weapon.GetTable then
            local tab = weapon:GetTable()
            base = tab and tab.Base
        end

        return string.lower(tostring(base or ""))
    end

    local function isMwBaseWeapon(weapon)
        if not IsValid(weapon) then return false end
        if getWeaponBase(weapon) == "mg_base" then return true end

        if weapons and weapons.IsBasedOn and weapon.GetClass then
            local className = weapon:GetClass()
            if className ~= "" and weapons.IsBasedOn(className, "mg_base") then return true end
        end

        return isfunction(weapon.GetStoredAttachment)
            and isfunction(weapon.PlayViewModelAnimation)
            and isfunction(weapon.GetAllAttachmentsInUse)
    end

    local function hasMwBaseFlashlightAttachment(weapon)
        if not isMwBaseWeapon(weapon) then return false end
        if not isfunction(weapon.GetFlashlightAttachment) then return false end

        local ok, attachment = pcall(weapon.GetFlashlightAttachment, weapon)
        return ok and attachment ~= nil
    end

    local function clearMwBaseFlashlightFlag(weapon)
        if not hasMwBaseFlashlightAttachment(weapon) then return end
        if not isfunction(weapon.RemoveFlag) then return end

        pcall(weapon.RemoveFlag, weapon, "FlashlightOn")
    end

    local function clearActiveMwBaseFlashlightFlag(ply)
        if not (IsValid(ply) and ply.GetActiveWeapon) then return end

        clearMwBaseFlashlightFlag(ply:GetActiveWeapon())
    end

    local function shouldSkipMwBaseFlashlightHook(ply, state)
        if state ~= true then return false end
        if not (IsValid(ply) and ply.GetActiveWeapon) then return false end

        return hasMwBaseFlashlightAttachment(ply:GetActiveWeapon())
    end

    local function runPlayerSwitchFlashlightHook(ply, state)
        local skipMwBase = shouldSkipMwBaseFlashlightHook(ply, state)
        local flashlightHooks = hook.GetTable().PlayerSwitchFlashlight
        local mwBaseHook = skipMwBase and flashlightHooks and flashlightHooks[MWBASE_FLASHLIGHT_HOOK] or nil

        if mwBaseHook then
            hook.Remove("PlayerSwitchFlashlight", MWBASE_FLASHLIGHT_HOOK)
        end

        local ok, allowed = pcall(hook.Run, "PlayerSwitchFlashlight", ply, state)

        if mwBaseHook then
            hook.Add("PlayerSwitchFlashlight", MWBASE_FLASHLIGHT_HOOK, mwBaseHook)
        end

        return ok, allowed
    end

    local function emitFlashlightSound(ply, state)
        net.Start(BL.NET_FLASHLIGHT_SOUND)
            net.WriteEntity(ply)
            net.WriteBool(state)
        net.SendPVS(ply:GetPos())
    end

    local function isModuleEnabledFor(ply)
        local globalCvar = GetConVar("betterlights_enable")
        return (not globalCvar or globalCvar:GetBool()) and IsValid(ply) and ply.BetterLights_FlashlightEnabled == true
    end

    local function recentlyHandledInput(ply)
        local lastInput = ply.BetterLights_LastFlashlightInput
        if not lastInput then return false end

        local elapsed = CurTime() - lastInput
        return elapsed >= 0 and elapsed < INPUT_DEBOUNCE
    end

    local function markHandledInput(ply)
        ply.BetterLights_LastFlashlightInput = CurTime()
    end

    local function isVanillaFlashlightOn(ply)
        local oldIsOn = PLAYER and PLAYER.BetterLights_OldFlashlightIsOn
        if not oldIsOn then return false end

        local ok, isOn = pcall(oldIsOn, ply)
        return ok and isOn == true
    end

    local function turnOffVanillaFlashlight(ply)
        local oldFlashlight = PLAYER and PLAYER.BetterLights_OldFlashlight
        if not oldFlashlight or not isVanillaFlashlightOn(ply) then return end

        ply.BetterLights_SuppressFlashlightHook = true
        pcall(oldFlashlight, ply, false)
        ply.BetterLights_SuppressFlashlightHook = nil
    end

    local function canUseFlashlight(ply)
        if not isModuleEnabledFor(ply) then return false end
        if not IsValid(ply) or not ply:Alive() then return false end
        if GetConVar("mp_flashlight") and not GetConVar("mp_flashlight"):GetBool() then return false end

        if ply.CanUseFlashlight then
            local ok, allowed = pcall(ply.CanUseFlashlight, ply)
            if not ok or allowed ~= true then return false end
        end

        return true
    end

    local function canSwitchFlashlight(ply, state)
        if not canUseFlashlight(ply) then return false end

        ply.BetterLights_CheckingSwitchHook = true
        local ok, allowed = runPlayerSwitchFlashlightHook(ply, state)
        ply.BetterLights_CheckingSwitchHook = nil

        if not ok then
            ErrorNoHaltWithStack("[BetterLights] PlayerSwitchFlashlight hook failed: " .. tostring(allowed) .. "\n")
            return false
        end

        return allowed ~= false
    end

    local function setFlashlight(ply, state, silent, skipPermission)
        if not IsValid(ply) then return false end

        state = state and true or false
        if not skipPermission and not canSwitchFlashlight(ply, state) then return false end
        if isModuleEnabledFor(ply) then
            turnOffVanillaFlashlight(ply)
            clearActiveMwBaseFlashlightFlag(ply)
        end

        if ply:GetNWBool("BetterLights_Flashlight", false) == state then return true end

        ply:SetNWBool("BetterLights_Flashlight", state)

        if not silent then
            emitFlashlightSound(ply, state)
        end

        return true
    end

    local function toggleFlashlight(ply)
        return setFlashlight(ply, not ply:GetNWBool("BetterLights_Flashlight", false))
    end

    net.Receive(BL.NET_FLASHLIGHT_CLIENT_ENABLE, function(_, ply)
        if not IsValid(ply) then return end

        ply.BetterLights_FlashlightEnabled = net.ReadBool()

        if ply.BetterLights_FlashlightEnabled == false then
            setFlashlight(ply, false, true, true)
        end
    end)

    hook.Add("StartCommand", "BetterLights_FlashlightImpulse", function(ply, cmd)
        if not isModuleEnabledFor(ply) then return end
        if cmd:GetImpulse() ~= 100 then return end

        cmd:SetImpulse(0)
        if recentlyHandledInput(ply) then return false end

        toggleFlashlight(ply)
        markHandledInput(ply)
        return false
    end)

    hook.Add("PlayerSwitchFlashlight", "BetterLights_FlashlightSwitch", function(ply, state)
        if not isModuleEnabledFor(ply) then return end
        if ply.BetterLights_CheckingSwitchHook then return end
        if ply.BetterLights_SuppressFlashlightHook then return end

        if not recentlyHandledInput(ply) then
            setFlashlight(ply, state, false, true)
            markHandledInput(ply)
        end

        return false
    end)

    hook.Add("PlayerSpawn", "BetterLights_FlashlightSpawn", function(ply)
        setFlashlight(ply, false, true, true)
    end)

    hook.Add("PlayerDeath", "BetterLights_FlashlightDeath", function(ply)
        setFlashlight(ply, false, true, true)
    end)

    hook.Add("PlayerSilentDeath", "BetterLights_FlashlightSilentDeath", function(ply)
        setFlashlight(ply, false, true, true)
    end)

    cvars.AddChangeCallback("betterlights_enable", function(_, _, new)
        if new ~= "0" then return end

        for _, ply in ipairs(player.GetAll()) do
            setFlashlight(ply, false, true, true)
        end
    end, "BetterLights_FlashlightDisableOnGlobalDisable")

    cvars.AddChangeCallback("mp_flashlight", function(_, _, new)
        if new ~= "0" then return end

        for _, ply in ipairs(player.GetAll()) do
            setFlashlight(ply, false, true, true)
        end
    end, "BetterLights_FlashlightDisableOnMpFlashlightDisable")

    if PLAYER then
        if not PLAYER.BetterLights_OldFlashlight then
            PLAYER.BetterLights_OldFlashlight = PLAYER.Flashlight
        end

        if not PLAYER.BetterLights_OldFlashlightIsOn then
            PLAYER.BetterLights_OldFlashlightIsOn = PLAYER.FlashlightIsOn
        end

        function PLAYER:Flashlight(state)
            if not isModuleEnabledFor(self) then
                return self:BetterLights_OldFlashlight(state)
            end

            if state == nil then
                return toggleFlashlight(self)
            end

            return setFlashlight(self, state)
        end

        function PLAYER:FlashlightIsOn()
            if not isModuleEnabledFor(self) then
                return self:BetterLights_OldFlashlightIsOn()
            end

            return self:GetNWBool("BetterLights_Flashlight", false)
        end
    end
end
