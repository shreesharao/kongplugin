local typedefs = require "kong.db.schema.typedefs"

local PLUGIN_NAME = "license-manager"

local schema = {
    name = PLUGIN_NAME,
    fields = { -- the 'fields' array is the top-level entry with fields defined by Kong
    {
        consumer = typedefs.no_consumer
    }, -- this plugin cannot be configured on a consumer (typical for auth plugins)
    {
        protocols = typedefs.protocols_http
    }, {
        config = {
            -- The 'config' record is the custom part of the plugin schema
            type = "record",
            fields = { -- self defined field
            {
                license_id = {
                    type = "string",
                    required = true
                }
            }, {
                lmagent_service = {
                    type = "string",
                    required = true
                }
            }, {
                license_endpoint = {
                    type = "string",
                    required = true
                }
            }, {
                status_cache_ttl_seconds = {
                    type = "number",
                    required = true
                }
            }, {
                redirect_uri_path = {
                    type = "string",
                    required = true
                }
            }, {
                logout_uri_path = {
                    type = "string",
                    required = true
                }
            }, {
                valid_license_modes = {
                    type = "array",
                    default = {},
                    required = true,
                    elements = {
                        type = "string"
                    }
                }
            }, {
                redirected_roles_allowed_urls = {
                    type = "array",
                    default = {},
                    elements = {
                        type = "string"
                    }
                }
            }, {
                blocked_roles_allowed_urls = {
                    type = "array",
                    default = {},
                    elements = {
                        type = "string"
                    }
                }
            }, {
                allowed_roles = {
                    type = "array",
                    default = {},
                    elements = {
                        type = "string"
                    }
                }
            }, {
                redirected_roles = {
                    type = "array",
                    default = {},
                    elements = {
                        type = "string"
                    }
                }
            }}
        }
    }}
}

return schema
