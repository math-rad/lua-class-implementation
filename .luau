local module = {}

local classes = {}

function getTypeAsserter(type)
    return function(value)
        return typeof(value) == type 
    end
end

function getNegatedTypeAsserter(type)
    return function(value)
        return typeof(value) ~= type
    end
end

local assertString = getTypeAsserter "string"
local negateAssertTable = getNegatedTypeAsserter "table"

local internals = setmetatable({}, {
    ["__mode"] = "k"
})

function makeInternal(label)
    local object = {}
    internals[object] = label 
    
    return object
end

-- literally just syntax sugar

function extends(name)
    assert(classes[name])

    local extender = makeInternal "extender"
    extender.class = name 

    return extender
end

local classMeta = {
    ["__call"] = function(self, argument)
        negateAssertTable(argument)

        if not internals[argument] then
            local body = argument

            if body.meta then 
                self.meta = body.meta 
                body.meta = nil 
            end 
    
            self.body = body 
    
            classes[self.name] = self
        elseif internals[argument] == "extender" then
            local extender = argument

            assert(classes[extender.class])

            self.parent = classes[extender.class]
            self.root = self.parent.root or self.parent 

            if self.parent then
                self.body.super = self.parent.body.constructor
            end

            setmetatable(self.body, {
                ["__index"] = self.parent.body
            })
        end
        
        return self
    end
}


function Class(name)
    assertString(name)

    local class = makeInternal "class"
    class.name = name 
    
    return setmetatable(class, classMeta)
end

function new(name)
    assert(classes[name])

    local class = classes[name]
    local instance = makeInternal "instance"

    for key, value in class.body do 
        instance[key] = value 
    end

    local meta = {}

    if class.meta and class.meta.__index then 
        local __index = class.meta.__index
        function meta.__index(self, index)
            return class.body[index] or __index(self, index)
        end
    else 
        meta.__index = class.body 
    end

    if class.meta then
        for metamethod, value in class.meta do 
            if meta[metamethod] then
                continue
            end
        end    
    end
   
    if next(meta) ~= nil then
        setmetatable(instance, meta)
    end

    return function(...)

        if instance.constructor then
            local response = table.pack(instance:constructor(...))
            if #response > 0 then
                return table.unpack(response)
            end
        end

        return instance 
    end
end

Class "person" {
    constructor = function(self, name)
        self.name = name 
    end,
    getName = function(self)
        print(self.name)
    end
}

Class "worker" {
    constructor = function(self, ...)
        self.type = "worker"
        self:super(...)
    end,
    getType = function(self)
        print(self.type)
    end
} (extends "person")

local alex = new "worker" ("alex")

alex:getName()
alex:getType()
