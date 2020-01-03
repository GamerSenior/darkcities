require('rendermath')
local inspect = require('lib/inspect')

states = {
    MAIN_MENU = 0,
    PLAYING = 1,
    PAUSED = 2,
    CONFIGURATION = 3,
}

stateHandler = {}

function mainMenuUpdate()
end

function mainMenuDraw()
    love.graphics.print("PLAY THE GAME", 50, 50)
    love.graphics.print("Press enter to start", 50, 60)
end

function mainMenuKeyPressed(key)
    if key == 'return' then
        game.state = states.PLAYING
    end
end

stateHandler[states.MAIN_MENU] = {
    update = mainMenuUpdate,
    draw = mainMenuDraw,
    keypressed = mainMenuKeyPressed,
}

player = {
    position = {
        x = 100,
        y = 100
    },
    rotation = 0,
    size = {
        x = 10,
        y = 10
    }
}

function playerDraw()
    local x, y = player.body:getPosition()
    print("X[" ..x.. "] Y[" ..y.."]")
    local pos = {x = x, y = y}
    local size = player.size
    love.graphics.circle('line', pos.x, pos.y, size.x)
    local p2_line = rotate_point(pos, {x = pos.x, y = pos.x + size.x}, player.rotation)
    love.graphics.line(pos.x, pos.y, p2_line.x, p2_line.y)
end

function playerControls()
    local vx, vy = player.body:getLinearVelocity()
    print(vx .. " " .. vy)

    if love.keyboard.isDown('d') then
        if vx < 100 then
            player.body:applyForce(500, 0)
        end
    elseif love.keyboard.isDown('a') then
        if vx > -100 then
            player.body:applyForce(-500, 0)
        end
    elseif love.keyboard.isDown('w') then
        if vy < 100 then
            player.body:applyForce(0, 500)
        end
    elseif love.keyboard.isDown('s') then
        if vy > -100 then
            player.body:applyForce(0, -500)
        end
    end
end

function playingUpdate(dt)
    game.world:update(dt)

    playerControls()
end

function playingDraw()
    --playerDraw()

    -- Draw some world shapes for collision debugging
    for _, body in pairs(game.world:getBodies()) do
        for _, fixture in pairs(body:getFixtures()) do
            local shape = fixture:getShape()

            if shape:typeOf("CircleShape") then
                local cx, cy = body:getWorldPoints(shape:getPoint())
                love.graphics.circle("line", cx, cy, shape:getRadius())
            elseif shape:typeOf("PolygonShape") then
                love.graphics.polygon("line", body:getWorldPoints(shape:getPoints()))
            else 
                love.graphics.line(body:getWorldPoints(shape:getPoints()))
            end
        end
    end
end

function playingKeypressed(key)
end

stateHandler[states.PLAYING] = {
    update = playingUpdate,
    draw = playingDraw,
    keypressed = playingKeypressed
}

game = {
    state = states.MAIN_MENU,
    world = nil,
}

function getCorrectFunction(operation)
    local handler = stateHandler[game.state]
    if handler == nil then 
        return nil 
    else 
        return handler[operation]
    end
end 


function love.load()
    game.world = love.physics.newWorld(0, 0, true)
    player.body = love.physics.newBody(game.world, 100, 100, 'dynamic')
    player.body:setLinearDamping(1)
    pShape = love.physics.newCircleShape(player.size.x)
    pFixture = love.physics.newFixture(player.body, pShape, 1)
end

function love.update(dt)
    local updateFunc = getCorrectFunction('update')
    if (updateFunc) then
        updateFunc(dt)
    else
        print("Error: Update function doesn't exist")
    end
end

function love.draw()
    local drawFunc = getCorrectFunction('draw')
    if (drawFunc) then
        drawFunc()
    else 
        print("Error: Draw function doesn't exist")
    end
end

function love.keypressed(key)
    local keyFunc = getCorrectFunction('keypressed')
    if keyFunc then
        keyFunc(key)
    end
end

function love.keyreleased(key)
end

function love.mousemoved(x, y, dx, dy, isTouch)
    --print("player: x[" .. player.position.x .."] y[" .. player.position.y .. "]")
    --print("mouse: x[" .. x .. "] y[" .. y .."]")
    if game.state == states.PLAYING then
       local theta = get_angle(player.position, {x = x, y = y})
       player.rotation = theta
    end
end

function love.quit()
    game.world:destroy()
    print("Quiting program")
end