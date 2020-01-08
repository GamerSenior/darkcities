require('rendermath')
require('transformationMatrix')
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
    body = nil,
    rotation = 0,
    size = {
        x = 10,
        y = 10
    }
}

renderPlane = { x = 0, y = love.graphics.getHeight() }
local renderTransformation = TransformationMatrix:new()
renderTransformation:translate(renderPlane.x, renderPlane.y)
renderTransformation:reflect_y()

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
end

function playingUpdate(dt)
    game.world:update(dt)

    playerControls()
end

function playingDraw()
    -- Draw some world shapes for collision debugging
    for _, body in pairs(game.world:getBodies()) do
        for i, fixture in pairs(body:getFixtures()) do
            local shape = fixture:getShape()

            if shape:typeOf("CircleShape") then
                local cx, cy = body:getWorldPoints(shape:getPoint())
                local renderMatrix = renderTransformation:transform({{cx}, {cy}, {1}})
                local position = {x = renderMatrix[1][1], y = renderMatrix[2][1]}
                print(inspect(position))
                love.graphics.circle("line", position.x, position.y, shape:getRadius())
            elseif shape:typeOf("PolygonShape") then
                love.graphics.polygon("line", body:getWorldPoints(shape:getPoints()))
            else 
                print('Drawing ' .. shape:type())
                x1, y1, x2, y2 = body:getWorldPoints(shape:getPoints())
                print('Point A', x1, y1, 'Point B', x2, y2)
                local pointA = renderTransformation:transform_to_point({{x1}, {y1}, {1}})
                local pointB = renderTransformation:transform_to_point({{x2}, {y2}, {1}})
                print('Point A', inspect(pointA), 'Point B', inspect(pointB))
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
    createWorldBoundries()
end

function createPlayerPhysics()
    player.body = love.physics.newBody(game.world, 0, 0, 'dynamic')
    player.body:setLinearDamping(5)
    local pShape = love.physics.newCircleShape(player.size.x)
    local pFixture = love.physics.newFixture(player.body, pShape, 1)
end

function createWorldBoundries()
    createLine(createPoint(0, 0), createPoint(game.width, 0))
    --createLine(createPoint(game.width, 0), createPoint(game.width, game.height))
    --createLine(createPoint(game.width, game.height), createPoint(0, game.height))
    --createLine(createPoint(0, game.height), createPoint(0, 0))
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
    local px, py = player.body:getPosition()
    if game.state == states.PLAYING then
       local theta = get_angle({x = px, y = py}, {x = x, y = y})
       player.rotation = theta
    end
end

function love.quit()
    game.world:destroy()
    print("Quiting program")
end