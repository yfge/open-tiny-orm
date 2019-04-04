local M = {}
M._VERSION = "1.0"
local mt = { __index = M }
local cfg_fac = require('tiny.util.cfg')
local shared = require('tiny.cache.shared')
local message = require('tiny.redis.message')
local log = require('tiny.log.helper')
local function sync_cache(cfg,key,ob)
    local redis_cfg = cfg_fac:get_redis_cfg(cfg.config.redis)
    log.trace(redis_cfg)
    local redis = message:new(redis_cfg)
    
    redis:publish(cfg.config.channel,key)
end
function M.new(self,config)
    local ins = self or {}
    local ins_cfg = cfg_fac:get_cache_cfg(config)
    ins.shared = shared:new(ins_cfg)
    ins.config = ins_cfg 
    setmetatable(ins,mt)
    return ins
end


function M:set(key,ob)
    sync_cache(self,key,ob)
    self.shared:set(key,ob)
    
end


function M:get(key)
    return self.shared:get(key)
end
function M:del(key)
    local set_key = self.config.key_pre .. tostring(key)
    self.shared:del(key)

end
return M

