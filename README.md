# orm
One ORM for Openresty
# 安装
```bash
opm install yfge/open-tiny-orm
```
# 设置

# model

* 用现有的配置定义,需要可以 `require ('config.mysql') `
```lua  
    local model = require('tiny.orm.mysql.model')
    local m = model:new (
        'table_test', -- 表名
        {
            'id',
            'name',
            'short',
            'remark',
            'date'
        },          -- 列的定义
        'tiny',     -- 使用 config/mysql 中的 tiny 配置字段作为连接配置
        'id', --自增 id
    )
```

* 从其他的地方加入配置文件 
```lua
local model = require('tiny.orm.mysql.model')
local config = {
 	timeout = 3000,
        pool = {
            maxIdleTime = 120000,
            size = 800,
        },
        clusters = {
            master = {"127.0.0.1", "3306"},
            slave = {
                {"127.0.0.1", "3306"},
            }
        },
        database = "tiny",
        user = "test",
        password = "123456",
        charset = "utf8",
        maxPacketSize = 1024*1024,
}
local m = model:new(
    'tiny_user',
    {
        'id',
        'name',
        'passwd'
    },
    config,
    'id'
)
```
# 增删改查
```lua
    --- 增删改查
    --- 引入 data
    local mysql_fac = require('tiny.orm.mysqlfactory')
    local fac = mysql_fac:new (m)
    --- 新建
    local item = fac:new_item()
    item.name = 'hello world'
    item.show = 'hw'
    fac:create(item)
    --- item.id 已经被赋值
    --- 按 id 查询
    local id = 1
    local item2 = fac:get_by_id(id)
    if (item2~=nil) then
        item2.name = 'new world '
        fac:save(item2) ---- 保存
    end
    --- 删除
    if item2 ~= nil then
        fac：delete(item2)
    end

```

# 分页 
```lua
     cal items = nil
     local query = fac:get_query()
     --- select ... from  .. where id = 1
     items = query:where('id',1)
                  :first()
     query = fac:get_query()
     --- select .. from .. where name = 'hello ' limit 10,off 10 ;
     local items2 = query:where('name','hello')
                         :skip(0)
                         :take(10)
                         :get()
     query = fac:get_query()
     --- select  ... from where name = 'hello ' and id in (1,2,3,4)
     local items3 = query:where (name ,'hello')
                         :where_in('id',{1,2,3,4})
                         :get()
     query = fac:get_query()
     --- select .. from .. where .. order by ..
     local items4 = query:order_by('id','asc')
                         :order_by('name')
                         :get()


```

# 事务 

```lua
    local trans = require('libs.mysql.mysql_transaction')
    local t = trans:new()
    t:start()
    --- 各种操作
    t:submit()
    --  提交
    t:rollback()
    -- 回滚
```


# todo 
1. 返回查询总数
2. 缓存 
3. Mapping
