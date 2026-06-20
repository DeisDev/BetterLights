if SERVER then
    util.AddNetworkString("BetterLights_FlashlightClientEnable")
    util.AddNetworkString("BetterLights_FlashlightSound")

    local INPUT_DEBOUNCE = 0.05

    local PLAYER = FindMetaTable("Player")

    local function emitFlashlightSound(ply, state)
        net.Start("BetterLights_FlashlightSound")
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
        local ok, allowed = pcall(hook.Run, "PlayerSwitchFlashlight", ply, state)
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

    net.Receive("BetterLights_FlashlightClientEnable", function(_, ply)
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

    cvars.AddChangeCallback("betterlights_enable", function(_, _, new)
        if new ~= "0" then return end

        for _, ply in ipairs(player.GetAll()) do
            setFlashlight(ply, false, true, true)
        end
    end, "BetterLights_FlashlightDisableOnGlobalDisable")

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
