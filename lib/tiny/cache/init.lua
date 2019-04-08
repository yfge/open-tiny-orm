local log = require('tiny.log.helper')
local  cache = {
    redis = require('tiny.cache.redis'),
    shared = require('tiny.cache.shared'),
    sync = require('tiny.cache.sync')
}
local cfg = require('tiny.util.cfg')

local M = {}
M._VERSION="0.3b"

function M.get(config)
    local cache_cfg = cfg:get_cache_cfg(config)
    local ins = cache[cache_cfg.cache_type]
    if ins ~= nil then
        return ins:new(cache_cfg.cache_cfg)
    end
end


return M 

