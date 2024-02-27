A lua class implementation with syntactic sugar

Example:

```lua
local CM = require(script.Parent["class.lua"])

local class, extends, new = CM.class, CM.extends, CM.new

class "myClass" {
    constructor = function(self, n)
        self.n = n
    end,
    foo = function(self)
        print(self.n)
    end,
}

class "class" (extends "myClass") {
    constructor = function(self, n)
        self:super(n)
        self.n += 1
        
    end,
    hello = "world"
}

local inst = new "class"(2)

inst:foo()
print(inst)
```

Output:

```
3 

▼  {
  ["constructor"] = "function",
  ["foo"] = "function",
  ["hello"] = "world",
  ["n"] = 3,
  ["super"] = "function"
} 
```

