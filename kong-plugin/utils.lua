local cjson = require("cjson")
local http = require("socket.http")
local ltn12 = require("ltn12")

local M = {}

-- Extracts user details from X-Userinfo request header
function M.get_user_from_userinfo(ngx)
    local userinfo_header = ngx.req.get_headers()['X-Userinfo']

    if not userinfo_header then
        return nil, "X-Userinfo header is not found"
    end

    local userinfo = cjson.decode(ngx.decode_base64(userinfo_header))
    return userinfo, nil
end

-- Terminates the request
function M.exit(httpStatusCode, message, ngxCode)
    ngx.status = httpStatusCode
    ngx.say(message)
    ngx.exit(ngxCode)
end

local function parse_urls(csv_urls)
    local urls = {}
    if csv_urls then
        for url in string.gmatch(csv_urls, "[^,]+") do
            table.insert(urls, url)
        end
    end
    return urls
end
-- Returns license manager plugin configuration
function M.get_lm_config(config)
    return {
        license_id = config.license_id,
        lmagent_service = config.lmagent_service,
        license_endpoint = config.license_endpoint,
        status_cache_ttl_seconds = config.status_cache_ttl_seconds,
        redirect_uri_path = config.redirect_uri_path,
        logout_uri_path = config.logout_uri_path,
        valid_license_modes = config.valid_license_modes,
        redirected_roles_allowed_urls = config.redirected_roles_allowed_urls,
        blocked_roles_allowed_urls = config.blocked_roles_allowed_urls,
        allowed_roles = config.allowed_roles,
        redirected_roles = config.redirected_roles
    }
end

-- Checks if the table has specified value or not
function M.table_has_value(tab, val)
    for index, value in ipairs(tab) do
        if string.lower(value) == string.lower(val) then
            return true
        end
    end
    return false
end

-- Checks if the role has a particular privilege
function M.check_role_privilege(roles, privileges)
    for index, role in ipairs(roles) do
        if M.table_has_value(privileges, role) then
            return true
        end
    end
    return false
end

-- Returns license status
function M.get_license_status(lmconfig, user_id)

    local endpoint = lmconfig.license_endpoint

    local url = lmconfig.lmagent_service .. "/" .. endpoint
    kong.log.info("license_service_url - ", url)

    local reqbody = "{\"id\": \"{id}\",\"userId\": \"{user_id}\"}"
    reqbody = reqbody:gsub("{id}", lmconfig.license_id)
    reqbody = reqbody:gsub("{user_id}", user_id)

    local respbody = {} -- for the response body
    kong.log.info("Making a POST request to " .. url .. "with body" .. reqbody)
    local result, respcode, respheaders, respstatus = http.request {
        method = "POST",
        url = url,
        source = ltn12.source.string(reqbody),
        headers = {
            ["content-type"] = "application/json",
            ["accept"] = "text/plain",
            ["content-length"] = string.len(reqbody),
            ["X-Userinfo"] = ngx.req.get_headers()['X-Userinfo']
        },
        sink = ltn12.sink.table(respbody)
    }

    kong.log.info("POST request response code " .. respcode)
    if result ~= 1 then
        return nil, "HTTP request failed. Response " .. respstatus
    end

    respbody = table.concat(respbody)
    local status = cjson.decode(respbody)
    return status, nil;
end

-- Injects the license details in requests
function M.inject_license_details(lmconfig)
    kong.service.request.set_header("license-id", lmconfig.license_id)
end
return M
