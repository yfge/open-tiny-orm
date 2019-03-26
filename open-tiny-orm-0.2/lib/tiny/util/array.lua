-- 封装一些与数组有关的操作
-- @verson 1.0
-- @author 拐 <geyunfei@gmail.com>
-- @date Oct 10th,2018

local M = {}
M._VERSION = "1.0"

local mt = { __index = M }


-- 取一个table中每个元素的key值
function M:get_by_key (array ,key )
	local res = {}
	for i , v in ipairs(array) do 
		res[i] = v[key]
	end
	return res
end

function M:group_by_key(array,col)
	local res = {}
	for i , v in ipairs(array) do 
		local key = v[col] 
		if res [key] ==  nil then 
			res[key] = {}
		end
		res[key][#(res[key])+1]=v
	end 
	return res
end

function M:fill_by_key(array,col)
	local res = {}
	for i, v in ipairs(array) do 
		res[v[col]]=v
	end
	return res
end
function M:get_keys(array)
	local res = {}
	for i,v in pairs(array) do
		res[#res+1]=i
	end
	return res
end
return M	
	


