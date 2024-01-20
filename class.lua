--!native

--[[
Written by @math-rad(github)
Date: 1/19/2024
Script: class.luau
Description: Class implementation for lua with nice syntax
]]
local Class = {}


local InternalMembership = {}

local globalClasses = {}
local localClasses = {}

local errorTemplates = {
	["requireBody"] = [[class requires a body. class "%s"]],
	["requireName"] = [[class requires a name(string)]],
	["requirefunctionAsConstructor"] = [[A class must have the constructor property set to a function(received type %s)]],
	["alterExposedClassTypeReference"] = [[You may not alter the parent or root property of a class(attempt to alter %s)]],
	["editOrigin"] = [[You may not edit the origin property of a class]],
	["resetBodyReference"] = [[You may not reset the reference to the class body
	If you need change a property of the body, set the value directly to the class object(the table which has the "body" property)
	]]
}

local function markAsInternal(object, context: string) 
	InternalMembership[object] = context or true
	return object
end

local function isInternal(object, doUnmark)
	local internal = InternalMembership[object] ~= nil
	
	if internal and (doUnmark ~= nil and doUnmark == true) then
		InternalMembership[object] = nil
	end
	
	return InternalMembership[object] or internal
end

local function getScript(overideLevel: number?) 
	if not game then
		return
	end
	local path = debug.info(overideLevel or 3, "s")
	local pathSegments = string.split(path, '.')
	
	local service, index = game:GetService(table.remove(pathSegments, 1)), table.remove(pathSegments, 1)
	
	local instance
	
	while index do
		instance = (instance or service)[index]
		index = table.remove(pathSegments, 1)
	end
	
	return instance
end

function protectClass(class) 
	return setmetatable({}, {
		["__tostring"] = function()
			print(class)
			return ''
		end,
		["__index"] = function(self, index)
			local value = class[index]
			local internal = isInternal(value, false)
			if internal == "class" then
				return protectClass(value) -- ensures descendant class protection
			end

			return value or class.body[index]
		end,
		["__newindex"] = function(self, index, value)
			if index == "parent" or index == "root" then
				error(errorTemplates.alterExposedClassTypeReference:format(index))
			elseif index == "origin" then
				error(errorTemplates.editOrigin)
			elseif index == "body" then
				error(errorTemplates.resetBodyReference)
			else
				class.body[index] = value
			end
		end,
	})
end

local function makeClass(name) 
	assert(name, errorTemplates.requireName)
	
	local class = markAsInternal({
		["name"] = name,
		["origin"] = getScript()
	}, "class")
	
	
	local protectedClass = protectClass(class)
	
	localClasses[name] = class 
	return function(definition)
		if typeof(definition) == "table"  then
			class.body = definition
			class.constructor = definition.constructor
			return protectedClass
		elseif isInternal(definition) == "extends" then
			local extender = definition
			return function(definition)
				local classData = extender(definition)
				class.body = classData.body 
				class.constructor = classData.body.constructor
				class.parent = classData.parent
				class.root = classData.parent.parent or classData.parent
				return protectedClass
			end
		end
	end
end


function extends(name)
	local classParent = localClasses[name] or globalClasses[name]
	
	return markAsInternal(function(body: classBody) 
		local classData = {
			["parent"] = classParent,
			["body"] = body
		}
		return classData
	end, "extends")
end

function inherit(class, instance)
	for property, value in class.body do
		instance[property] = value
	end
end

local function new(name)
	local class = localClasses[name]
	local instance = {
		["super"] = class.parent and class.parent.constructor,
		["class"] = protectClass(class)
	}
	return function(...)
		local inheritenceTree = {class}
		local ancestor = class.parent
		
		while ancestor do
			table.insert(inheritenceTree, 1, ancestor)
			ancestor = ancestor.parent
		end
		
		for _, ancestor in inheritenceTree do
			inherit(ancestor, instance)
		end
		
		class.constructor(instance, ...)
		
		return instance
	end
end


local function getClass(name) 
	return  protectClass(localClasses[name] or globalClasses[name])
end


Class.class = makeClass 
Class.extends = extends
Class.new = new 
Class.getClass = getClass
Class.classes = localClasses
return Class
