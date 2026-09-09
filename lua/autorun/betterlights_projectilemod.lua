if SERVER or CLIENT then
    local BL = BetterLights
    local MF = BL.MuzzleFlash
    local WRAPPER_VERSION = 1

    MF._projectileModHook = MF._projectileModHook or {}
    local state = MF._projectileModHook

    local function getPredictedProjectileCount()
        local ply = LocalPlayer()
        if not IsValid(ply) or not istable(projectile_store) then return 0 end

        local store = projectile_store[ply:EntIndex()]
        return istable(store) and tonumber(store.received) or 0
    end

    local function installProjectileHook()
        if not istable(projectiles) then return end

        local bulletHooks = hook.GetTable().EntityFireBullets
        local original = bulletHooks and bulletHooks.projectiles
        if not isfunction(original) then return end
        if original == state.wrapper then
            if state.version == WRAPPER_VERSION then return end
            original = state.original
        end

        -- ProjectileMod+ cancels the engine bullet after creating its projectiles.
        -- Observe its own callback so another hook's cancellation cannot count as a shot.
        local wrapper
        wrapper = function(ent, bullet, ...)
            if SERVER then
                if not BL.IsServerEnabled() then return original(ent, bullet, ...) end
            elseif CLIENT then
                if not BL.IsEnabled() then return original(ent, bullet, ...) end
            end

            local before = CLIENT and getPredictedProjectileCount() or 0
            local function finish(...)
                local result = ...
                -- The client also returns false when prediction is skipped. Only
                -- a newly allocated projectile confirms a local predicted shot.
                if state.wrapper == wrapper and result == false
                    and istable(bullet) and (tonumber(bullet.Num) or 0) >= 1
                    and (SERVER or getPredictedProjectileCount() > before) then
                    hook.Run("BetterLights_FireBulletsMuzzleFlash", ent, bullet)
                end
                return ...
            end

            return finish(original(ent, bullet, ...))
        end

        state.original = original
        state.wrapper = wrapper
        state.version = WRAPPER_VERSION
        hook.Add("EntityFireBullets", "projectiles", wrapper)
    end

    hook.Add("BetterLights_ShouldSuppressMuzzleFlash", "BetterLights_ProjectileMod_ImpactReplay", function()
        if not istable(projectiles) then return end

        -- These short FireBullets calls apply damage/decals at a projectile impact.
        -- Impact lights still use the normal event path, but this is not a new shot.
        if projectiles.disable_fire_bullets or projectiles.currently_using_firebullets then
            return true
        end
    end)

    -- Shared autorun runs before the realm-specific muzzle handlers. Install once
    -- both addons have loaded, and reinstall if either hook is replaced by refresh.
    hook.Add("InitPostEntity", "BetterLights_ProjectileMod_Install", installProjectileHook)
    hook.Add("OnReloaded", "BetterLights_ProjectileMod_Install", installProjectileHook)
end
