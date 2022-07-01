-- If you're not sure your plugin is executing, uncomment the line below and restart Kong
-- then it will throw an error which indicates the plugin is being loaded at least.
-- assert(ngx.get_phase() == "timer", "The world is coming to an end!")
---------------------------------------------------------------------------------------------
-- In the code below, just remove the opening brackets; `[[` to enable a specific handler
--
-- The handlers are based on the OpenResty handlers, see the OpenResty docs for details
-- on when exactly they are invoked and what limitations each handler has.
---------------------------------------------------------------------------------------------
local plugin = {
    -- We want license-manager plugin to execute after oidc plugin which has priority 1000. So setting it to 100
    PRIORITY = 100, -- set the plugin priority, which determines plugin execution order

    VERSION = "1.0.0" -- version in X.Y.Z format. Check hybrid-mode compatibility requirements.
}

local lrucache = require "resty.lrucache"
local utils = require("kong.plugins.license-manager.utils")
local filters = require("kong.plugins.license-manager.filters")

-- we need to initialize the cache on the lua module level so that
-- it can be shared by all the requests served by each nginx worker process:
local cache, err = lrucache.new(10) -- allow up to 10 items in the cache
if not cache then
    kong.log.err("failed to create the cache: " .. (err or "unknown"))
end

-- runs in the 'access_by_lua_block'
function plugin:access(plugin_conf)

    -- for testing - service role
    -- ngx.req.set_header("X-Userinfo",
    --    "eyJ1cG4iOiJzZXJ2aWNlIiwiaWQiOiIyODQ0MWRhMC0wYWZhLTRmMzUtYTYxMC00ZjZkMDNmNTc1NmMiLCJyb2xlIjpbIkNMSU5JQ0FMIiwib2ZmbGluZV9hY2Nlc3MiLCJ1bWFfYXV0aG9yaXphdGlvbiJdLCJuYW1lIjoic2VydmljZSBzZXJ2aWNlIiwidXNlcm5hbWUiOiJzZXJ2aWNlIiwiZW1haWwiOiJzZXJ2aWNlQHVzZXIudGVzdCIsImdyb3VwcyI6WyJTZXJ2aWNlIl0sInN1YiI6IjI4NDQxZGEwLTBhZmEtNGYzNS1hNjEwLTRmNmQwM2Y1NzU2YyIsImVtYWlsX3ZlcmlmaWVkIjpmYWxzZSwiZ2l2ZW5fbmFtZSI6InNlcnZpY2UiLCJwcmVmZXJyZWRfdXNlcm5hbWUiOiJzZXJ2aWNlIiwiZmFtaWx5X25hbWUiOiJzZXJ2aWNlIn0=")
    -- test block end

    -- for testing - admin role
    ngx.req.set_header("X-Userinfo",
        "eyJ1cG4iOiJzZXJ2aWNlIiwiaWQiOiIyODQ0MWRhMC0wYWZhLTRmMzUtYTYxMC00ZjZkMDNmNTc1NmMiLCJyb2xlIjpbIkNMSU5JQ0FMIiwib2ZmbGluZV9hY2Nlc3MiLCJBRE1JTiIsInVtYV9hdXRob3JpemF0aW9uIl0sIm5hbWUiOiJzZXJ2aWNlIHNlcnZpY2UiLCJ1c2VybmFtZSI6InNlcnZpY2UiLCJlbWFpbCI6InNlcnZpY2VAdXNlci50ZXN0IiwiZ3JvdXBzIjpbIlNlcnZpY2UiXSwic3ViIjoiMjg0NDFkYTAtMGFmYS00ZjM1LWE2MTAtNGY2ZDAzZjU3NTZjIiwiZW1haWxfdmVyaWZpZWQiOmZhbHNlLCJnaXZlbl9uYW1lIjoic2VydmljZSIsInByZWZlcnJlZF91c2VybmFtZSI6InNlcnZpY2UiLCJmYW1pbHlfbmFtZSI6InNlcnZpY2UifQ==")
    -- test block end

    -- for testing - any other role
    -- ngx.req.set_header("X-Userinfo",
    --    "eyJ1cG4iOiJzZXJ2aWNlIiwiaWQiOiIyODQ0MWRhMC0wYWZhLTRmMzUtYTYxMC00ZjZkMDNmNTc1NmMiLCJyb2xlIjpbIkNMSU5JQ0FMIiwib2ZmbGluZV9hY2Nlc3MiLCJ1bWFfYXV0aG9yaXphdGlvbiJdLCJuYW1lIjoic2VydmljZSBzZXJ2aWNlIiwidXNlcm5hbWUiOiJzZXJ2aWNlIiwiZW1haWwiOiJzZXJ2aWNlQHVzZXIudGVzdCIsImdyb3VwcyI6WyJTZXJ2aWNlIl0sInN1YiI6IjI4NDQxZGEwLTBhZmEtNGYzNS1hNjEwLTRmNmQwM2Y1NzU2YyIsImVtYWlsX3ZlcmlmaWVkIjpmYWxzZSwiZ2l2ZW5fbmFtZSI6InNlcnZpY2UiLCJwcmVmZXJyZWRfdXNlcm5hbWUiOiJzZXJ2aWNlIiwiZmFtaWx5X25hbWUiOiJzZXJ2aWNlIn0=")
    -- test block end

    kong.log.info("Executing license-manager plugin")

    kong.log.info("Getting user details from X-userinfo header")
    local user, err = utils.get_user_from_userinfo(ngx)
    if err then
        kong.log.err("Error getting user details - " .. err)
        utils.exit(500, err, ngx.HTTP_INTERNAL_SERVER_ERROR)
    end
    kong.log.info("User has roles - ", table.concat(user.role, ","))

    kong.log.info("Getting license manager plugin configuration")
    local lm_config = utils.get_lm_config(plugin_conf)

    kong.log.info("Getting license status from cache")
    local license_status = cache:get("license_status")
    if not license_status then
        kong.log.info("license status cache is expired")

        license_status, err = utils.get_license_status(lm_config, user.username)
        if err then
            kong.log.err("Error getting license status - " .. err)
            utils.exit(500, err, ngx.HTTP_INTERNAL_SERVER_ERROR)
        end

        kong.log.info("Caching license status with TTL seconds " .. lm_config.status_cache_ttl_seconds)
        cache:set("license_status", license_status, lm_config.status_cache_ttl_seconds)
    end

    kong.log.info("License status mode - ", license_status.mode)
    if utils.table_has_value(lm_config.valid_license_modes, license_status.mode) then
        kong.log.info("License is valid. Forwarding the requests")
        utils.inject_license_details(lm_config)
    else
        kong.log.info("License is invalid.")

        if utils.check_role_privilege(user.role, lm_config.allowed_roles) then
            kong.log.info("User role is found in allowed roles. Forwarding the requests")
            utils.inject_license_details(lm_config)
        elseif utils.check_role_privilege(user.role, lm_config.redirected_roles) then
            if filters.should_allow_url(lm_config.redirected_roles_allowed_urls) then
                kong.log.info(
                    "User role is found in redirected roles. Found the request url in allowed list. Forwarding the request")
                utils.inject_license_details(lm_config)
            else
                kong.log.info("User role is found in redirected roles. Redirecting the user to " ..
                                  lm_config.redirect_uri_path)
                ngx.redirect(lm_config.redirect_uri_path)
            end
        else
            if filters.should_allow_url(lm_config.blocked_roles_allowed_urls) then
                kong.log.info(
                    "User role is found blocked. Found the request url in allowed list. Forwarding the request")
            else
                kong.log.info("User role is found blocked. Redirecting the user to " .. lm_config.logout_uri_path)
                ngx.redirect(lm_config.logout_uri_path)
            end
        end
    end

    kong.log.info("License-manager plugin execution ends.")
end

-- return our plugin object
return plugin
