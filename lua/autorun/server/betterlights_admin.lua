if SERVER then
    local cvar_enable = CreateConVar("betterlights_enable", "1", FCVAR_ARCHIVE + FCVAR_REPLICATED, "Enable Better Lights")
    util.AddNetworkString("BetterLights_SetServerBool")

    local SERVER_BOOL_CVARS = {
        betterlights_enable = true,
    }

    local function canChangeServerSettings(ply)
        return not IsValid(ply) or game.SinglePlayer() or ply:IsAdmin()
    end

    local function setServerBool(cvarName, value)
        if not SERVER_BOOL_CVARS[cvarName] then return end
        RunConsoleCommand(cvarName, value and "1" or "0")
    end

    net.Receive("BetterLights_SetServerBool", function(_, ply)
        if not canChangeServerSettings(ply) then return end

        local cvarName = net.ReadString()
        setServerBool(cvarName, net.ReadBool())
    end)

    concommand.Add("betterlights_toggle", function(ply)
        if not canChangeServerSettings(ply) then return end
        setServerBool("betterlights_enable", not cvar_enable:GetBool())
    end)
end
