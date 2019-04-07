local M = {}
M._VERSION = "1.0"
local mt = { __index = M }
local cfg_fac = require('tiny.util.cfg')
local shared = require('tiny.cache.shared')
local message = require('tiny.redis.message')
local log = require('tiny.log.helper')

local op = {
    DEL = 'del',
    SET = 'set'
    }
local function sync_cache(cfg,key,op,ob)
    local redis_cfg = cfg_fac:get_redis_cfg(cfg.config.redis)
    local redis = message:new(redis_cfg)
    local set_key = cfg.key_pre .. tostring(key)
    redis:publish(cfg.config.channel,{key=set_key,cat=cfg.config.catlog,op=op,ob=ob,expired = cfg.config.expired})
end
function M.new(self,config)
    local ins = self or {}
    local ins_cfg = cfg_fac:get_cache_cfg(config)
    ins.expred = config.exprired or 0
    ins.key_pre = config.key_pre or ""
    ins.shared = shared:new(ins_cfg)
    ins.config = ins_cfg 
    setmetatable(ins,M)
    return ins
end

function M:set(key,ob)
    sync_cache(self,key,op.SET,ob)
    self.shared:set(key,ob)
end


function M:get(key)
    return self.shared:get(key)
end
function M:del(key)
    local set_key = self.config.key_pre .. tostring(key)
    self.shared:del(key)
    sync_cache(self,key,op.DEL)
end

function M:sync()
    local redis_cfg = cfg_fac:get_redis_cfg(self.config.redis)
    local work_id = ngx.worker.id()
    if work_id == 0 then 
        ngx.timer.at(0,function()
            local redis = message:new(redis_cfg)
            redis:subscribe(self.config.channel,
                function(msg)
                    local operation = msg.op
                    local key = msg.key 
                    local catlog = msg.cat
                    local ob = msg.ob
                    local expired = msg.expired
                    local shared_ins = shared:new(
                        {
                            catlog = catlog,
                            key_pre = "",
                            expired = expired,
                        })
                    if shared_ins then
                        if operation == op.DEL then
                            shared_ins:del(key)
                        elseif operation == op.SET then
                            shared_ins:set(key,ob)
                        end
                    end
                return true
                end
            )

        end)
    end
end
return M

