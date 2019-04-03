local mysql = require 'resty.mysql'
local cjson = require 'cjson'
local connector = {
    modelMaster = "master",
    modelSlave = "slave",
}
connector.VERSION = "1.0"
local mt = {__index = connector}

local function get_host(self,model)
    local host
    local port
    if model == self.modelMaster then
        host = self.clusters.master[1]
        port = self.clusters.master[2]
    else
        local n = #self.clusters.slave
        if 1 == n then
            host = self.clusters.slave[1][1]
            port = self.clusters.slave[1][2]
        else
            local index = math.floor(ngx.now()) % n + 1
            host = self.clusters.slave[index][1]
            port = self.clusters.slave[index][2]
        end
    end
    return host, port
end


function connector.new(_,config)
    local instance = {
        timeout = config.timeout or 1000,
        pool = config.pool or {maxIdleTime = 120000, size = 200},
        clusters = config.clusters or {},
        database = config.database or 0,
        user = config.user or "",
        password = config.password or "",
    }
    setmetatable(instance, mt)
    return instance
end
function connector:connect_by_master()
    local db, err, errcode, ok, sqlState
    db, err = mysql:new()
    if not db then
        return
    end
    db:set_timeout(self.timeout)
    local host, port = get_host(self,self.modelMaster)
    ok, err, errcode, sqlState = db:connect({
        host = host,
        port = port,
        database = self.database,
        user = self.user,
        password = self.password,
        charset = self.charset,
        max_packet_size = self.maxPacketSize,
    })
    if not ok then
        return
    end
    return db
end

function connector:connect_by_slave()
    local db, err = mysql:new()
    if not db then
        return
    end
    db:set_timeout(self.timeout)
    local host, port = get_host(self,self.modelSlave)
    local ok, err, errcode, sqlState = db:connect({
        host = host,
        port = port,
        database = self.database,
        user = self.user,
        password = self.password,
        charset = self.charset,
        max_packet_size = self.maxPacketSize,
    })
    if not ok then
        return
    end
    return db
end

return connector
