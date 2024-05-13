--[[
    Date created: 8:18 PM 5/12/2024
    script: class.lua
    description: a reimplementation of my class module for lua with nice syntax sugar 
]]

local signedCompontents = setmetatable({}, {
	["__mode"] = "k"
})

local TYPE = typeof or type

local classes = {}

local function sign(object)
	return function(symbol) 
		signedCompontents[object] = symbol
		return object
	end
end


local function inverse(array)
	local dictionary = {}

	for index, value in pairs(array) do
		dictionary[value] = index
	end

	return dictionary
end

local function of(t)
	local map = inverse(t)
	return function(v)
		return map[v] ~= nil
	end
end


local Default = sign {} "SWITCH:DEFAULT"

local function switch(value)
	return function(conditionFunctions) 
		local returned

		local active = true
		local function Break(...)
			active = false
			return ...
		end

		local lastindex
		local default
		local returns
		while active do 
			local conditionalFunction, callback = next(conditionFunctions, lastindex)
			if not callback then
				if default then
					returns = {default()}
					break
				end
				break
			end

			if TYPE(conditionalFunction) == "function" and conditionalFunction(value) then
				returns = {callback(Break)}
			elseif signedCompontents[conditionalFunction] == "SWITCH:DEFAULT" then
				default = callback
			elseif conditionalFunction == value then
				returns = {callback(Break)}
			end
			lastindex = conditionalFunction
		end

		return table.unpack(returns or {})
	end
end


local function wrap(f, ...)
	local arguments = {...}
	local n = #arguments
	return function(...) 
		for i, v in pairs{...} do
			arguments[n + i] = v
		end
		return f(table.unpack(arguments))
	end
end

local function ommit(f, i)
	return function(...)
		return f(select(i + 1, ...))
	end
end

local throw = wrap(error)

local function cut(index, source, to)
	to[index] = source[index]
	source[index] = nil
end

local CLASS = {}
local placeholder = sign {} "META:PLACEHOLDER"


local META = {
	["__call"] = function(self, value)
		switch(value) {
			[of{"get", "set", "static", "private", "readonly"}] = function(Break)
				assert(not self.named)
				self[value] = placeholder
				return Break()
			end,
			[Default] = function()
				assert(not self.named)
				self.named = true
				for index, V in pairs(self) do
					if V == placeholder then
						self[index] = value
					end
				end
			end,
		}
		return self
	end,
}

local function setMeta(meta)
	return setmetatable(meta, META)
end

CLASS.meta = function(meta)
	return setMeta(sign {} "META")(meta)
end

function CLASS.get(index)
	return sign {} "META"
end

function CLASS.set(index)
	return sign (setMeta{set = index, index = index}) "META"
end



function CLASS.class(name)
	return function(body) 
		local class = sign {} "CLASS:INTERNAL"
		class.constructor = body.constructor
		class.body = body
		class.classname = name

		if name then
			classes[name] = class
		end

		return setmetatable(sign {} "CLASS:EXPOSED", {
			["__metatable"] = ""
		})


	end

end

function CLASS.new(name)
	assert(classes[name], "class does not exist")
	return function(...)
		local object = sign {} "OBJECT:INTERNAL"

		local class = classes[name]
		
		if class.constructor then
			class.constructor(object, ...)
		end

		return setmetatable(sign {} "OBJECT:EXPOSED", {
			["__metatable"] = "",
			["__index"] = function(self, index) 
				return switch(index) {
					class = function(Break)
						return Break(class)
					end,
					classname = function(Break)
						return Break(class.classname)
					end,
					[Default] = function()
						return object[index] or class.body[index]
					end
				}
			end,
			["__newindex"] = function(self, index, value)
				return switch(index) {
					class = throw "cannot modify class property of object",
					classname = throw "cannot modify class name of object",
					[Default] = function()
						object[index] = value
					end
				}
			end
		})
	end
end


function CLASS.extends(name)

end 

function CLASS.with(meta)

end

local class, new = CLASS.class, CLASS.new
local meta = CLASS.meta 

local get = CLASS.get

class "test" {
	[meta "readonly" "get" "asdf"] = 2
}
