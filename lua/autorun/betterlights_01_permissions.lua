if SERVER then
    AddCSLuaFile("betterlights/vendor/cami.lua")
end

include("betterlights/vendor/cami.lua")

local BL = BetterLights

BL.CAMI_PRIVILEGE_MANAGE_SERVER_SETTINGS = "Better Lights - Manage Server Settings"

CAMI.RegisterPrivilege({
    Name = BL.CAMI_PRIVILEGE_MANAGE_SERVER_SETTINGS,
    MinAccess = "admin",
    Description = CLIENT and language.GetPhrase("betterlights.permission.manage_server_settings") or nil
})

function BL.CheckServerSettingsAccess(ply, callback)
    if not isfunction(callback) then return false end

    if SERVER and not IsValid(ply) then
        callback(true, "server console")
        return true
    end

    if not IsValid(ply) then
        callback(false, "invalid player")
        return true
    end

    if game.SinglePlayer() or ply:IsListenServerHost() then
        callback(true, "local server")
        return true
    end

    local answered = false
    local function finish(allowed, reason)
        if answered then return end

        answered = true
        if not IsValid(ply) then
            callback(false, "invalid player")
            return
        end
        callback(allowed == true, reason)
    end

    local ok, err = pcall(
        CAMI.PlayerHasAccess,
        ply,
        BL.CAMI_PRIVILEGE_MANAGE_SERVER_SETTINGS,
        finish,
        nil,
        { Fallback = "admin" }
    )
    if not ok then
        if answered then error(err, 0) end

        ErrorNoHaltWithStack("[BetterLights] CAMI access query failed: " .. tostring(err) .. "\n")
        finish(false, "CAMI access query failed")
    end

    return true
end
