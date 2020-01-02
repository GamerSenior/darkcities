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
        x = 50,
        y = 50
    }
}

function playerDraw()
    local pos = player.position
    local size = player.size
    love.graphics.circle('line', pos.x, pos.y, size.x)
    love.graphics.line(pos.x, pos.y, pos.x, pos.x + size.x)
end

function playingUpdate()
end

function playingDraw()
    playerDraw()
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
end

function love.update(dt)
    local updateFunc = getCorrectFunction('update')
    if (updateFunc) then
        updateFunc()
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

function love.quit()
    print("Quiting program")
end