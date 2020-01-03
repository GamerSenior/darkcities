local inspect = require('lib/inspect')

function rotate_point(p1, p2, angle)
    rotation_matrix = {
        {math.cos(angle), -math.sin(angle), -p1.x * math.cos(angle) + p1.y * math.sin(angle) + p1.x},
        {math.sin(angle), math.cos(angle), -p1.x * math.sin(angle) - p1.y * math.cos(angle) + p1.x},
        {0, 0, 1}
    }
    point_to_rotate = {
        {p2.x},
        {p2.y},
        {1}
    }
    rotated_point = multiply_matrix(rotation_matrix, point_to_rotate)
    return {x = rotated_point[1][1], y = rotated_point[2][1]}
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

function get_angle(p1, p2)
    local delta_x = p1.x - p2.x
    -- Inverted because y axis is from top to bottom
    local delta_y = p2.y - p1.y
    theta_radians = - math.atan2(delta_y, delta_x) + (math.pi/2)
    --print(theta_radians)
    return theta_radians
end