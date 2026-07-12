if SERVER then
    local BL = BetterLights
    local FL = BL.Flashlight

    util.AddNetworkString(BL.NET_FLASHLIGHT_CLIENT_SETTINGS)

    local INPUT_DEBOUNCE = 0.05
    local CUSTOM_SOUND_ON = "betterlights/flashlight_on.wav"
    local CUSTOM_SOUND_OFF = "betterlights/flashlight_off.wav"
    local DEFAULT_SOUND_ON = "HL2Player.FlashLightOn"
    local DEFAULT_SOUND_OFF = "HL2Player.FlashLightOff"
    local CUSTOM_SOUND_LEVEL = 77
    local DEFAULT_SOUND_LEVEL = 75
    local SOUND_PITCH = 100
    local SOUND_VOLUME = 1
    local SOUND_FLAGS = 0
    local SOUND_DSP = 1
    local REPLACEMENT_SETTING = "betterlights_flashlight_player_enable"
    local SOUNDS_SETTING = "betterlights_flashlight_custom_sounds"

    local PLAYER = FindMetaTable("Player")

    local function runIntegrationCallback(callbackName, ...)
        for _, integration in ipairs(FL.GetIntegrations()) do
            local callback = integration[callbackName]
            if isfunction(callback) then
                callback(...)
            end
        end
    end

    local function addSuppressedHook(output, seen, hookName)
        hookName = tostring(hookName or "")
        if hookName == "" or seen[hookName] then return end

        output[#output + 1] = hookName
        seen[hookName] = true
    end

    local function getSuppressedSwitchHooks(ply, state)
        local output = {}
        local seen = {}

        for _, integration in ipairs(FL.GetIntegrations()) do
            local getHooks = integration.GetSuppressedPlayerSwitchFlashlightHooks
            if isfunction(getHooks) then
                local hooks = getHooks(ply, state)

                if type(hooks) == "table" then
                    for i = 1, #hooks do
                        addSuppressedHook(output, seen, hooks[i])
                    end
                else
                    addSuppressedHook(output, seen, hooks)
                end
            end
        end

        return output
    end

    local function removePlayerSwitchFlashlightHooks(hookNames)
        local removed = {}
        local flashlightHooks = hook.GetTable().PlayerSwitchFlashlight
        if not flashlightHooks then return removed end

        for i = 1, #hookNames do
            local hookName = hookNames[i]
            local callback = flashlightHooks[hookName]

            if callback then
                hook.Remove("PlayerSwitchFlashlight", hookName)
                removed[#removed + 1] = {
                    name = hookName,
                    callback = callback
                }
            end
        end

        return removed
    end

    local function restorePlayerSwitchFlashlightHooks(removed)
        for i = 1, #removed do
            local hookData = removed[i]
            hook.Add("PlayerSwitchFlashlight", hookData.name, hookData.callback)
        end
    end

    local function runPlayerSwitchFlashlightHook(ply, state)
        local removedHooks = removePlayerSwitchFlashlightHooks(getSuppressedSwitchHooks(ply, state))
        local ok, allowed = pcall(hook.Run, "PlayerSwitchFlashlight", ply, state)
        restorePlayerSwitchFlashlightHooks(removedHooks)

        return ok, allowed
    end

    local function getFlashlightSoundFilters(pos)
        local audibleFilter = RecipientFilter()
        local customFilter = RecipientFilter()
        local defaultFilter = RecipientFilter()

        audibleFilter:AddPAS(pos)

        for _, listener in ipairs(audibleFilter:GetPlayers()) do
            local useCustomSounds = BL.IsEnabledForPlayer(listener)
                and BL.GetEffectiveServerFlashlightBool(SOUNDS_SETTING, listener.BetterLights_CustomFlashlightSounds)

            if useCustomSounds then
                customFilter:AddPlayer(listener)
            else
                defaultFilter:AddPlayer(listener)
            end
        end

        return customFilter, defaultFilter
    end

    local function emitFilteredSound(ply, soundName, soundLevel, filter)
        if filter:GetCount() <= 0 then return end

        ply:EmitSound(soundName, soundLevel, SOUND_PITCH, SOUND_VOLUME, CHAN_AUTO, SOUND_FLAGS, SOUND_DSP, filter)
    end

    local function emitFlashlightSound(ply, state)
        local customFilter, defaultFilter = getFlashlightSoundFilters(ply:GetPos())

        emitFilteredSound(ply, state and CUSTOM_SOUND_ON or CUSTOM_SOUND_OFF, CUSTOM_SOUND_LEVEL, customFilter)
        emitFilteredSound(ply, state and DEFAULT_SOUND_ON or DEFAULT_SOUND_OFF, DEFAULT_SOUND_LEVEL, defaultFilter)
    end

    local function isFlashlightOverrideDisabledFor(ply)
        for _, integration in ipairs(FL.GetIntegrations()) do
            local callback = integration.IsFlashlightOverrideDisabled
            if isfunction(callback) and callback(ply) == true then
                return true
            end
        end

        return false
    end

    local function isModuleEnabledFor(ply)
        return IsValid(ply)
            and BL.IsEnabledForPlayer(ply)
            and BL.GetEffectiveServerFlashlightBool(REPLACEMENT_SETTING, ply.BetterLights_FlashlightEnabled)
            and not isFlashlightOverrideDisabledFor(ply)
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

    local function integrationHandlesFlashlightImpulse(ply)
        for _, integration in ipairs(FL.GetIntegrations()) do
            local handlesFlashlightImpulse = integration.HandlesFlashlightImpulse
            if isfunction(handlesFlashlightImpulse) and handlesFlashlightImpulse(ply) == true then
                return true
            end
        end

        return false
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
            runIntegrationCallback("OnSetPlayerFlashlight", ply, state)
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

    local function reconcileFlashlightEligibility(ply)
        if not IsValid(ply) then return end

        if isModuleEnabledFor(ply) then
            if isVanillaFlashlightOn(ply) then
                setFlashlight(ply, true, true, true)
            end

            return
        end

        if not ply:GetNWBool("BetterLights_Flashlight", false) then return end

        setFlashlight(ply, false, true, true)
    end

    net.Receive(BL.NET_FLASHLIGHT_CLIENT_SETTINGS, function(len, ply)
        if not IsValid(ply) then return end
        if len < 6 then return end

        ply.BetterLights_ClientEnabled = net.ReadBool()
        ply.BetterLights_FlashlightEnabled = net.ReadBool()
        ply.BetterLights_CustomFlashlightSounds = net.ReadBool()
        ply.BetterLights_MWBaseFlashlightOverrideDisabled = net.ReadBool()
        ply.BetterLights_ArcCWFlashlightOverrideDisabled = net.ReadBool()
        ply.BetterLights_ARC9FlashlightOverrideDisabled = net.ReadBool()

        reconcileFlashlightEligibility(ply)
    end)

    hook.Add("StartCommand", "BetterLights_FlashlightImpulse", function(ply, cmd)
        if not isModuleEnabledFor(ply) then
            reconcileFlashlightEligibility(ply)
            return
        end

        if cmd:GetImpulse() ~= 100 then return end
        if integrationHandlesFlashlightImpulse(ply) then return end

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

    hook.Add("PlayerSwitchWeapon", "BetterLights_FlashlightIntegrationSwitch", function(ply)
        timer.Simple(0, function()
            reconcileFlashlightEligibility(ply)
        end)
    end)

    local function reconcileFlashlights()
        for _, ply in ipairs(player.GetAll()) do
            reconcileFlashlightEligibility(ply)
        end
    end

    cvars.AddChangeCallback("betterlights_enable", reconcileFlashlights, "BetterLights_FlashlightPolicyChanged")
    hook.Add("BetterLights_ServerSettingsChanged", "BetterLights_FlashlightServerSettingsChanged", reconcileFlashlights)

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
