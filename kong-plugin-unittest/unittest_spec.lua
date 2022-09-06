require 'busted.runner'()
local utils = require("utils")

function safe_divide(a, b)
    if b > 0 then -- buggy! should be b ~= 0 
        return a / b
    else
        return false, "division by zero"
    end
end

describe("safe_divide", function()
    it("can divide by positive numbers", function()
        local ok, err = safe_divide(10.0, 5.0)
        assert.truthy(ok)
        assert.are.same(2.0, ok)
    end)

    it("errors when dividing by zero", function()
        local ok, err = safe_divide(10.0, 0.0)
        assert.not_truthy(ok)
        assert.are.same("division by zero", err)
    end)

    it("can divide by negative numbers", function()
        local ok, err = safe_divide(-10.0, -5.0)
        assert.truthy(ok)
        assert.are.same(2.0, ok)
    end)
end)

describe("table_has_value", function()
    it("table has value returns true", function()
        table = {1, 2, 3, 4}
        val = 2
        local ok, err = utils.table_has_value(table, val)
        assert.truthy(ok)
    end)

    it("table has value returns false", function()
        table = {1, 2, 3, 4}
        val = 5
        local ok, err = utils.table_has_value(table, val)
        assert.not_truthy(ok)

    end)
end)
