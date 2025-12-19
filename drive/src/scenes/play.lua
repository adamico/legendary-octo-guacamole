local Play = SceneManager:addState("Play")

world = eggs()

function Play:enteredState()
    Log.trace("Entered Play scene")
end

function Play:update()
    -- update game logic here
end

function Play:draw()
    cls(0)
    map()
    print("Play Scene", 10, 10, 7)
    -- draw game elements here
end

function Play:exitedState()
    Log.trace("Exited Play scene")
end

return Play