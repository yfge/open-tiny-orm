local setmetatable = setmetatable
local cfg_fac = require('tiny.util.cfg')
local crc32Short = ngx.crc32_short
local redis = require("resty.redis")
local connector = {}
local mt = {__index = connector}
local cjson = require "cjson.safe"
function connector:new(config)
    local instance = cfg_fac:get_redis_cfg(config) 
    setmetatable(instance, mt)
    return instance
end

function connector:connect_by_key(key)
    local hostInfo = self:get_host(key)
    local host = hostInfo[1]
    local port = hostInfo[2]
    local red = redis:new()
    red:set_timeout(self.timeout)
    local ok, err = red:connect(host, port)
    if not ok then
        return nil, err
    end

    local count, err = red:get_reused_times()
    if 0 == count and self.password ~= nil then
        ok, err = red:auth(self.password)
    elseif err then
        return nil, err

    end
    if err then
        return nil
    end
    red:select(self.database)
    return red
end

function connector:get_host(key)
    local idx = crc32Short(key) % (#self.clusters) + 1
    return self.clusters[idx]
end

function connector:keep_alive(red)
    local ok, err = red:set_keepalive(self.pool.maxIdleTime, self.pool.size)
    if not ok then
        red:close()
    end
    return true
end


return connector
