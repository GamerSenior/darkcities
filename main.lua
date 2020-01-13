require('transformationMatrix')
local vector = require('lib/vector')
local inspect = require('lib/inspect')
local Signal = require('lib/signal')

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
    body = nil,
    rotation = 0,
    position = {
        x = 0,
        y = 0
    },
    size = {
        x = 10,
        y = 10
    }
}

renderPlane = { x = 0, y = love.graphics.getHeight() }

local renderTransformation = TransformationMatrix:new()
renderTransformation:translate(renderPlane.x, renderPlane.y)
renderTransformation:reflect_y()

local rotationTransformation = TransformationMatrix:new()


function playerControls()
    local vx, vy = player.body:getLinearVelocity()
    --print(vx .. " " .. vy)

    if love.keyboard.isDown('d') then
        if vx < 100 then
            player.body:applyForce(500, 0)
        end
    end
    if love.keyboard.isDown('a') then
        if vx > -100 then
            player.body:applyForce(-500, 0)
        end
    end
    if love.keyboard.isDown('w') then
        if vy < 100 then
            player.body:applyForce(0, 500)
        end
    end
    if love.keyboard.isDown('s') then
        if vy > -100 then
            player.body:applyForce(0, -500)
        end
    end

    if love.mouse.isDown(1) then
        local x, y  = player.position:unpack()
        local angle = player.rotation
        Signal.emit('shoot', x, y, angle)
    end
end

function playingUpdate(dt)
    game.world:update(dt)

    playerControls()
end

function drawPlayerAngle()
    local mouseX, mouseY = love.mouse.getPosition()
    --print('Mouse X: ', mouseX, ' Y: ', mouseY)
    local position = player.position
    print('playerX: ', position.x, 'playerY: ', position.y)
    local deltaX = mouseX - position.x
    local deltaY = (position.y - mouseY)
    -- Calculates angle betweeen player and mouse
    local radians = -math.atan2(deltaY, deltaX) - (math.pi / 2)
    print('Radians: ', radians)
    local line = {
        p1 = vector(position.x, position.y),
        p2 = vector(position.x, position.y + player.size.x)
    }
    line.p2 = (line.p2 - line.p1):rotated(radians) + line.p1
    love.graphics.line(line.p1.x, line.p1.y, line.p2.x, line.p2.y)
end

function playingDraw()
    -- Draw some world shapes for collision debugging
    for _, body in pairs(game.world:getBodies()) do
        for i, fixture in pairs(body:getFixtures()) do
            local shape = fixture:getShape()
            --print('Drawing ' .. shape:type())

            if shape:typeOf("CircleShape") then
                local cx, cy = body:getWorldPoints(shape:getPoint())
                local renderMatrix = renderTransformation:transform({{cx}, {cy}, {1}})
                local position = {x = renderMatrix[1][1], y = renderMatrix[2][1]}
                player.position = vector(position.x, position.y)
                --print(inspect(position))
                love.graphics.circle("line", position.x, position.y, shape:getRadius())
                if body:getUserData() == 'player' then
                    drawPlayerAngle()
                end
            elseif shape:typeOf("PolygonShape") then
                love.graphics.polygon("line", body:getWorldPoints(shape:getPoints()))
            else 
                x1, y1, x2, y2 = shape:getPoints()
                --print('BT Point A', x1, y1, 'Point B', x2, y2)
                local pointA = renderTransformation:transform_to_point({{x1}, {y1}, {1}})
                local pointB = renderTransformation:transform_to_point({{x2}, {y2}, {1}})
                --print('AT Point A', inspect(pointA), 'Point B', inspect(pointB))
                love.graphics.line(pointA.x, pointA.y, pointB.x, pointB.y)
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
    game.width = love.graphics.getWidth()
    game.height = love.graphics.getHeight()
    print('Game width[' .. game.width .. '] height[' .. game.height .. ']')

    game.world = love.physics.newWorld(0, 0, true)
    createPlayerPhysics()
    createPlayerHandlers()
    createWorldBoundries()
end

function createPlayerPhysics()
    player.body = love.physics.newBody(game.world, game.width / 2, game.height / 2, 'dynamic')
    player.body:setLinearDamping(5)
    player.body:setUserData('player')
    local pShape = love.physics.newCircleShape(player.size.x)
    local pFixture = love.physics.newFixture(player.body, pShape, 1)
end

function createPlayerHandlers()
    Signal.register('shoot', function(x, y, angle)
        local bulletBody = love.physics.newBody(game.world, x, y, 'dynamic')
        local bulletShape = love.physics.newCircleShape(5)
        love.physics.newFixture(bulletBody, bulletShape)
        local impulseVector = vector.fromPolar(angle, 10)
        bulletBody:applyLinearImpulse(impulseVector:unpack())
    end)
end

function createWorldBoundries()
    local pA = createPoint(0, 0)
    local pB = createPoint(0, 600)
    local pC = createPoint(800, 600)
    local pD = createPoint(800, 0)

    createLine(pA, pB)
    createLine(pA, pD)
    createLine(pB, pC)
    createLine(pC, pD)
end

function createPoint(x, y)
    return {x = x, y = y}
end

function createLine(pointA, pointB)
    print(inspect(pointA))
    print(inspect(pointB))
    local lineBody = love.physics.newBody(game.world, pointA.x, pointA.y, 'static')
    local lineShape = love.physics.newEdgeShape(pointA.x, pointA.y, pointB.x, pointB.y)
    local lineFixture = love.physics.newFixture(lineBody, lineShape, 1)

    print(lineBody:getWorldPoints(lineShape:getPoints()))
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
    --print("mouse: x[" .. x .. "] y[" .. y .."]")
end

function love.quit()
    game.world:destroy()
    print("Quiting program")
end