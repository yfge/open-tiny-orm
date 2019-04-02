local M = {}
M._VERSION = "1.0"
local mt = { __index = M }

function M.new(self,config)
    local ins = self or {}
    ins.config = config 
    setmetatable(ins,mt)
    return ins
end

function M:set(key,value,timeout)
    
end


function M:get(key)


end

return M

