if SERVER then
    local cvar_enable = CreateConVar("betterlights_flashlight_enable", "1", FCVAR_ARCHIVE + FCVAR_REPLICATED, "Replace player flashlights with BetterLights projected flashlights")
    local SOUND_ON = "betterlights/flashlight_on.wav"
    local SOUND_OFF = "betterlights/flashlight_off.wav"
    local SOUND_LEVEL = 77

    local function canUseFlashlight(ply, state)
        if not cvar_enable:GetBool() then return false end
        if not IsValid(ply) or not ply:Alive() then return false end
        if GetConVar("mp_flashlight") and not GetConVar("mp_flashlight"):GetBool() then return false end

        local allowed = hook.Run("PlayerCanSwitchFlashlight", ply, state)
        return allowed ~= false
    end

    local function setFlashlight(ply, state, silent)
        if not IsValid(ply) then return false end

        state = state and true or false
        if state and not canUseFlashlight(ply, state) then return false end

        if ply:GetNWBool("BetterLights_Flashlight", false) == state then return true end

        ply:SetNWBool("BetterLights_Flashlight", state)

        if not silent then
            ply:EmitSound(state and SOUND_ON or SOUND_OFF, SOUND_LEVEL)
        end

        return true
    end

    local function toggleFlashlight(ply)
        return setFlashlight(ply, not ply:GetNWBool("BetterLights_Flashlight", false))
    end

    hook.Add("StartCommand", "BetterLights_FlashlightImpulse", function(ply, cmd)
        if not cvar_enable:GetBool() then return end
        if cmd:GetImpulse() ~= 100 then return end

        cmd:SetImpulse(0)
        toggleFlashlight(ply)
    end)

    hook.Add("PlayerSwitchFlashlight", "BetterLights_FlashlightSwitch", function(ply, state)
        if not cvar_enable:GetBool() then return end

        if state == nil then
            toggleFlashlight(ply)
        else
            setFlashlight(ply, state)
        end

        return false
    end)

    hook.Add("PlayerSpawn", "BetterLights_FlashlightSpawn", function(ply)
        setFlashlight(ply, false, true)
    end)

    hook.Add("PlayerDeath", "BetterLights_FlashlightDeath", function(ply)
        setFlashlight(ply, false, true)
    end)

    cvars.AddChangeCallback("betterlights_flashlight_enable", function(_, _, new)
        if new ~= "0" then return end

        for _, ply in ipairs(player.GetAll()) do
            setFlashlight(ply, false, true)
        end
    end, "BetterLights_FlashlightEnable")

    local PLAYER = FindMetaTable("Player")
    if PLAYER and not PLAYER.BetterLights_OldFlashlight then
        PLAYER.BetterLights_OldFlashlight = PLAYER.Flashlight
        PLAYER.BetterLights_OldFlashlightIsOn = PLAYER.FlashlightIsOn

        function PLAYER:Flashlight(state)
            if not cvar_enable:GetBool() then
                return self:BetterLights_OldFlashlight(state)
            end

            if state == nil then
                return toggleFlashlight(self)
            end

            return setFlashlight(self, state)
        end

        function PLAYER:FlashlightIsOn()
            if not cvar_enable:GetBool() then
                return self:BetterLights_OldFlashlightIsOn()
            end

            return self:GetNWBool("BetterLights_Flashlight", false)
        end
    end
end
