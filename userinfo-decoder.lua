local core = require("apisix.core")
local json = require("apisix.core.json")

local plugin_name = "userinfo-decoder"

local schema = {
    type = "object",
    properties = {
        headers = {
            type = "array",
            minItems = 1,
            items = {
                type = "object",
                minProperties = 1,
                maxProperties = 1,
                patternProperties = {
                    ["^[%w-]+$"] = { type = "string", pattern = "^%$userinfo[%.%w_]*$" }
                }
            }
        }
    },
    required = {"headers"},
}

local _M = {
    version = 0.2,
    priority = 1001,
    name = plugin_name,
    schema = schema,
}

local function extract_userinfo_value(userinfo, expr)
    local path = expr:gsub("^%$userinfo%.?", "")
    local value = userinfo

    for key in path:gmatch("[^%.]+") do
        if type(value) ~= "table" then
            return nil
        end
        value = value[key]
    end
    return value
end

function _M.check_schema(conf)
    return core.schema.check(schema, conf)
end

function _M.access(conf, ctx)
    local header_val = core.request.header(ctx, "X-Userinfo")
    if not header_val then
        core.log.warn("X-Userinfo header not found")
        return
    end

    local decoded = ngx.decode_base64(header_val)
    if not decoded then
        core.log.error("Failed to base64 decode X-Userinfo header")
        return 500, "Invalid X-Userinfo encoding"
    end

    local userinfo, err = json.decode(decoded)
    if not userinfo then
        core.log.error("Failed to decode JSON from X-Userinfo: ", err)
        return 500, "Invalid X-Userinfo JSON"
    end

    for _, header_map in ipairs(conf.headers) do
        for k, expr in pairs(header_map) do
            local val = extract_userinfo_value(userinfo, expr)
            if val ~= nil then
                if type(val) == "table" then
                    val = table.concat(val, ",")
                end
                core.request.set_header("X-" .. k, val)
            end
        end
    end

    core.request.set_header("X-Userinfo", nil)
end

return _M
