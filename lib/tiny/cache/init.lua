local  cache = {
    redis = require('tiny.cache.redis'),
    shared = require('tiny.cache.shared'),
    sync = require('tiny.cache.sync')
}

local M = {}
M._VERSION="1.0"


function M.get(cache_type,cache_config)
    local ins = cache[cache_type]
    if ins ~= nil then
        return ins:new(cache_config)
    end
end


return M 

