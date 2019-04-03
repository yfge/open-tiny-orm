-- orm 的操作基类
-- @version 1.0 
-- @auth 拐 <geyunfei@gmail.com>
-- @date Sep 29th ,2018
-- 目前只实现查询功能
local qtx = require('tiny.orm.mysql.query')
local log = require 'tiny.log.helper'
local cache_fac = require('tiny.cache')
local _M = {} _M.VERSION = "1.0"
local mt = { __index = _M }
-- 构造函数
--
function _M:new(model,cache_cfg)
   
	local _ins= { _model = model,_cache=cache_cfg}
	if cache_cfg ~= nil then 
        local cache = cache_fac.get(cache_cfg)
        if cache ~= nil then
            _ins._cache =cache 
        end
    end
    setmetatable(_ins , mt )
	return _ins
end

-- 新建 
function _M:create(item)
    local q = qtx:new(self._model,self._con)
    return q:create_insert(item)
end

function _M:new_item()
    local item = {}
    for i,v in pairs(self._model._cols) do
        item[v] = nil
    end
    return item 
end

-- 保存
function _M:save(item)
    local q = qtx:new(self._model,self._con)
    return q:create_update(item)
end

-- 删除
function _M:delete(item)
    local q = qtx:new(self._model,self._con)
    return q:create_delete(item)
end

function _M:get_query()
	return qtx:new(self._model,self._con)
end

function _M:get_by_id(id)
    local ob = nil  
    if self._cache then
        ob = self._cache:get(id)
    end
    if ob then
        return ob 
    end
	local query =self:get_query()
	query = query : where(self._model._id_col,id)
	local items =  query:get()
	if #items >= 1 then
        if self._cache then
            self._cache:set(id,items[1])
        end
		return items[1]
	else 
		return nil
	end
end


function _M.get_by_ids(self,ids)
	local query = self:get_query()
	query = query : where_in(self._model._id_col,ids)
	return query:get()
end
return _M
