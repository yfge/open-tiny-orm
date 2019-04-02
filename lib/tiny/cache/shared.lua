local M = {}
M._VERSION = "1.0"
local cjson = require('cjson')
function M.new(self,config)
    local ins = self or {}
    local catlog = config.catlog
    if catlog ~= nil then 
        local shared = ngx.shared[catlog]
        ins.shared = shared 
        if config.expired ~=nil then
            ins.expired = config.expired
        end
        if config.key_pre ~= nil then
            ins.key_pre = config.key_pre
        end
        setmetatable(ins,M)
        return ins
    else 
        return nil
    end
end

function M:set(key,ob)
    local set_key = tostring(key)
    if self.key_pre then
        set_key = self.key_pre .. set_key
    end
    local timeout = self.expired or 0
    local success,err,forcible self.shared:set(key,cjson.encode(ob),timeout)
    return success 
end


function M:get(key)
    local set_key = tostring(key)
    if self.key_pre then
        set_key = self.key_pre .. set_key
    end
    local str = self.shared:get(set_key)
    if str then
        return cjson.decode(str)
    else
        return nil
    end
end



return M

