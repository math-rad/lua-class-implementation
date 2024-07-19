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
    "__mode": "k"
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
end

local classMeta = {
    ["__call"] = function(self, extender)
        assert(internals[extender] == "extender")
        assert(classes[extender.class])

        self.parent = classes[extender.class]
        self.root = self.parent.root or self.parent

        setmetatable(self.body, {
            "__index" = self.parent.body
        })
    end
}

function class(name)
    assertString(name)

    local class = makeInternal "class"
    class.name = name 
    
    setmetatable(class, classMeta)

    return function(body)
        negateAssertTable(body)

        if body.constructor then 
            class.constructor = body.constructor
            body.constructor = nil 
        end

        if body.meta then 
            class.meta = body.meta 
            body.meta = nil 
        end 

        for key, value in body do 
            if key:sub(1, 1) == "*" then 
                if not class.reference then 
                    class.reference = makeInternal "reference"
                end

                class[key] = nil
                class.inherit[key:sub(1, #key)] = value 
            end
        end

        class.body = body 

        setmetatable(class, classMeta)

        return class
    end
end

function new(name)
    assert(classes[name])

    local class = classes[name]
    local instance = makeInternal "instance"

    for key, value in class.body do 
        instance[key] = value 
    end

    if class.meta or class.inherit then 
        local meta = {}
        
    end
end
