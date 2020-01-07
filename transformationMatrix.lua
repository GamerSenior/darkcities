local inspect = require 'lib/inspect'

REFLECT_MATRIX = {
    {1, 0, 0},
    {0, -1, 0},
    {0, 0, 1}
}

TransformationMatrix = {
    result = {
        {1, 0, 0},
        {0, 1, 0},
        {0, 0, 1}
    }
}

function TransformationMatrix:new (...)
    local arg={...}
    o = {}
    setmetatable(o, self)
    self.__index = self
    for i, v in ipairs(arg) do
        o.result = multiply_matrix(o.result, v)
    end
    return o
end

function TransformationMatrix:translate(x, y)
    trans_matrix = {
        {1, 0, x},
        {0, 1, y},
        {0, 0, 1}
    }
    self.result = multiply_matrix(self.result, trans_matrix)
end

function TransformationMatrix:reflect_y()
    self.result = multiply_matrix(self.result, REFLECT_MATRIX)
end

function TransformationMatrix:rotate(angle)
    rotate_matrix = {
        {math.cos(angle), -math.sin(angle), 0},
        {math.sin(angle), math.cos(angle), 0},
        {0, 0, 1}
    }
    self.result = multiply_matrix(self.result, rotate_matrix)
end

function TransformationMatrix:transform(matrix)
    return multiply_matrix(self.result, matrix)
end

function multiply_matrix(m1, m2)
    local res = {}
    --print(inspect(m1))
    --print(inspect(m2))

    for i = 1, #m1 do
        res[i] = {}
        for j = 1, #m2[1] do
            res[i][j] = 0
            for k = 1, #m2 do
                --print("res[i][j]: " .. res[i][j])
                --print("m1[i][k]: " .. m1[i][k])
                --print("m2[k][j]: " .. m2[k][j])
                res[i][j] = res[i][j] + m1[i][k] * m2[k][j]
            end
        end
    end

    return res
end