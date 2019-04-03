-- mysql 的配置读取工具
-- 支持从配置读取或是串读取

local cfg = {}
function cfg:get_mysql_cfg(config)
    local mysql_cfg = nil 
    if type(config) == 'string' then
        mysql_cfg = require('config.mysql')[config]
    else
        mysql_cfg = config 
    end

    local instance = {
            timeout = mysql_cfg.timeout or 1000,
            pool = mysql_cfg.pool or {maxIdleTime = 120000, size = 200},
            clusters = mysql_cfg.clusters or {},
            database = mysql_cfg.database or 0,
            user = mysql_cfg.user or "",
            password = mysql_cfg.password or "",
            charset = mysql_cfg.charset or "UTF8",
            maxPacketSize = mysql_cfg.maxPacketSize or 1024*1024,
            }
    return instance 
end

function cfg:get_redis_cfg(config)
    local redis_config = nil 
    if type(config) == "string" then
        redis_config = require('config.redis')[config]
    else
        redis_config = config
    end
    local instance = {
        timeout = redis_config.timeout or 1000,
        pool = redis_config.pool or {maxIdleTime = 120000, size = 200},
        clusters = redis_config.clusters or {},
        database = redis_config.database or 0,
        password = redis_config.password or "",
    }
    return instance
end

return cfg 
