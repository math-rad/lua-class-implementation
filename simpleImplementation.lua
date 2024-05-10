local classes = {}

TYPE = typeof or type

function Enumerate(array) 
    local dictionary = {}
    for _, value in ipairs(array) do 
        dictionary[value] = true
    end
end

local protectedInstanceProperties = Enumerate {"class", "base", "new"}

function Switch(value, conditionalFunctions) 
    local broken = false 
    function Break() 
        broken = true
    end
    for conditionalFunction, callback in pairs(conditionalFunctions) do
        if TYPE(conditionalFunction) == "funciton" and conditionalFunction(value) then
            callback(value, Break)
        elseif value == conditionalFunction then
            callback(value, Break) 
        end
        if broken then 
            break
        end
    end
end

function Class(classname)
    local class = {}

    return function(body) 
        class.body = body
        class.constructor = body.constructor
        class.meta = {
            ["__index"] = function(self, index) 
            end
        }

        if classname then
            classes[classname] = class
        end

        return class
    end
end

function New(classname) 
    if classes[classname] then
        return function (parameters)
            local class = classes[classname]

            local object = {}
        end
    end
end
