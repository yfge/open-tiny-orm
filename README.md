# orm

One ORM for Openresty

## 更新记录

### v0.3 Apr 8th,2019

1. 加入了util.cfg以依赖注入的形式管理配置

2. nginx 变量管理默认配置路径

3. 加入缓存机制

4. orm.mysql.factory支持默认缓存

### v0.21 Mar 26th,2019

初始发布

## 目录

@[TOC]  

## 安装

推荐使用opm进行安装.

```bash
opm install yfge/open-tiny-orm
```

## 设置

### 依赖注入及约定

open-tiny-orm集成了orm,缓存等功能,为了方便使用和集成,这些组件在初始化时可以通过自定义的配置传入(传入table),也可以通过依赖注入的形式传入配置文件中的配置key.
并且这种配置是多层有效的.
如,当使用一个redis的缓存时,可以直接简单的应用如下：

1. 直接初始化缓存

```lua
    local cacheFac = require('tiny.cache')
    local config = {
        cache_type="redis",
        cache_cfg={
            key_pre="",
            expired=1000,
            redis={
                timeout=1000,
                pool = {
                    maxIdelTime = 129999,
                    size=200
                },
                clusters={
                    {   "127.0.0.1",6379 }
                },
                password="Pa88word",
                database=1,
            }
        },
    }
    local cache = cacheFac.get(config)
```

也可以在config/redis.lua下定义redis.lua的配置:
2. 定义config/redis.lua后初始化缓存
config/redis.lua

    ```lua
    return {
        default = {
        timeout=1000,
        pool = {
            maxIdelTime = 129999,
            size=200
            },
        clusters={
            {   "127.0.0.1",6379 }
        },
        password="Pa88word",
        database=1,
        }
    }
    ```
之后在缓存配置中直接引入redis的配置：

    ```lua
    local cacheFac = require('tiny.cache')
    local config = {
        cache_type="redis",
        cache_cfg={
            expired=1000,
            key_pre="",
            redis="default",
        },
    }
    local cache = cacheFac.get(config)
    ```
或是直接将这个配置存在config/cache.lua中：
3. 定义config/cache.lua后初始化缓存
config/cache.lua

    ```lua
    return {
        rediscache = {
            cache_type="redis",
            cache_cfg={
                expired=1000,
                key_pre="",
                redis="default"
                }
            }
    }
    ```

这时业务代码变为：

    ```lua
    local cacheFac = require('tiny.cache')
    local cache = cacheFac.get('rediscache')
    ```

### 配置文件的位置

所有的配置都以配置文件的形式存放，当可以通过nginx变量来更改配置文件的文件.

* open\_tiny\_mysql mysql配置文件,默认config.mysql

* open\_tiny\_redis redis配置文件,默认config.redis

* open\_tiny\_cache 缓存配置文件,默认config.cache

例:

```bash
    server {
            set $open_tiny_mysql "config.mysql";
            set $open_tiny_redis "config.redis";
            set $open_tiny_cache "config.cache";
            listen 8080;
            location  / {
                content_by_lua_file src/content_by_lua8080.lua;
                log_by_lua_file src/log_by_lua.lua;
                }
            }
```

### 配置文件的格式

1. config.mysql

    ```lua
    return {
        default  = {
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
            database = "open_tiny",
            user = "tiny",
            password = "Pa88word",
            charset = "utf8",
            maxPacketSize = 1024*1024,
        }
    }
    ```

2. config.redis

    ```lua
    return {
        default = {
        timeout=1000,
        pool = {
            maxIdelTime = 129999,
            size=200
            },
        clusters={
            {   "127.0.0.1",6379 }
        },
        password="Pa88word",
        database=1,
        }
    }
    ```

3. config.cache

    ```lua
    return {
        redis = {
            cache_type="redis",
            cache_cfg={
                catlog="user",
                expired=1000,
                redis="default"
                }
            },
        user = {
            cache_type="shared",
            cache_cfg={
                catlog="user",
                expired=10
                }
            },
        sync = {
            cache_type = "sync",
            cache_cfg ={
                redis="default",
                catlog="user",
                expired=1000,
                channel="lua:sync:cache",
            }
        },
        sync_redis ={
            cache_type = "sync",
            cache_cfg ={
                redis={
                    timeout=1000,
                    pool = {
                        maxIdelTime = 129999,
                        size=200
                    },
                    clusters={
                        {   "127.0.0.1",6379 }
                    },
                    password="Pa88word",
                },
                catlog="user",
                expired=1000,
                channel="lua:sync:cache",
            }
        }
    }
    ```

## 快速开始

### 定义model

* 用现有的配置定义,配置字段的含义参考配置一节

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

### 实现增删改查

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

### 分页

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

### 事务

```lua
    local trans = require('tiny.orm.mysql.transaction')
    local t = trans:new()
    t:start()
    --- 各种操作
    t:submit()
    --  提交
    t:rollback()
    -- 回滚
```

## 缓存的使用

### 在factory中使用缓存

可以在factory实例化时传入第二个参数为缓存配置参数,这时当进行get_by_id的操作时时会先从缓存中进行查找，如果没有会查询mysql之后同步缓存.

```lua
    local model = require('tiny.orm.mysql.model')
    local factory = require('tiny.orm.mysql.factory')
    local cacheFac = require('tiny.cache')
    local user = model:new (
    'auth_user',
    {
        'id',
        'name',
        'passwd',
        'created_at',
        'updated_at',
    },
    'default',
    'id')
    local user_fac = factory:new(user,{cache_type="shared",cache_cfg={catlog="user",expired=10}})
    local user_ins = user_fac: get_by_id ( 3) -- 这里会先在ngx.shared.user中查询是否有相应的缓存
    user_ins.name='namechanged'
    user_fac:save(user_ins) -- 这里会先将数据保存在缓存中。
```

### 单独使用缓存

```lua
local cacheFac = require('tiny.cache')
local str = 'hello word '
local cache = cacheFac.get('sync')

cache:set (1,str)
local h = cache:get(1)
```

### 缓存的类型及配置

一个open-tiny-orm的标准配置如下:

```lua
    local cache_config = {
            cache_type="redis",
            cache_cfg={
                expired=1000,
                key_pre="",
                redis="default"
                }
            }
```

其中:
cache_type: 表示缓存类型,目前支持:

1. shared nginx.shared.DICT 缓存
2. redis redis共享缓存
3. sync shared+redis订阅的同步缓存

cache_cfg: 表示缓存的配置。

1. cache_cfg.expired 超时的时间,不传的话则默认为0,即永久存储
2. cache_cfg.key_pre key的前缀,不传默认为""
3. cache_cfg.catlog 用于缓存的ngx.shared.DICT 中的dict值,当cache_type 为shared和sync时需要设置
4. cache_cfg.redis 用于缓存的redis配置,当cache_type为sync和redis时需要设置
5. cache_cfg.channel 用于缓存步的redis channel,当cache_type为sync时需要设置

### sync缓存的同步

sync缓存是open-tiny-orm在ngx.shared.DICT基础上加入redis pubscribe/publish 机制的一种多机同步的缓存,在其正常的使用下,为了保证同步机制的运行，必须要在init\_周期内加入同步的调用，具体方式如下:

init_worker_by_lua_file内的内容:

```lua
local cacheFac = require('tiny.cache') ---缓存fac
local sync_ins = cacheFac.get('sync') -- 要同步的缓存 
sync_ins:sync()--开馆始同步
```

**注意** 由于openresty在init周期中对ngx.var.VARIABLE的限制,如果人为定义了open\_tiny\_redis 及open\_tiny\_cache的路径，则在这里是不可用的，在这种情况下，请手工引入相应的配置,即传入对应的table 而不是配置串
