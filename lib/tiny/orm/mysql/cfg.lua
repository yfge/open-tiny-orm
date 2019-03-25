-- mysql 的配置读取工具

local cfg = {}
function cfg:get(config)
    if type(config) == 'string' then
        return require('config.mysql')[config]
    else
        return config 
    end
end
return cfg 
