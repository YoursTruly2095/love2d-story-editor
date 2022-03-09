
require("viewer")

function love.load(arg)
  -- stuff for debugging in zerobrane
  require("mobdebug").start()
  io.stdout:setvbuf("no")
    
  viewer:load()
  
  --testing
  printx = 0
  printy = 0
end

function love.update(dt)
  viewer:update(dt)
end

function love.draw()
  viewer:draw()
  
  --testing
  love.graphics.print(printx .. " " .. printy)
end 

function love.mousereleased(x, y, button, istouch)
    --log button
  if x > 320 and x < 390 and y > 420 and y < 450 and button == 1 then
    viewer:setMode("log") 
  
  --star button  
  elseif x > 450 and x < 515 and y > 415 and y < 440 and button == 1 then
    viewer:setMode("stars")
    
  --comms button  
  elseif x > 575 and x < 640 and y > 420 and y < 450 and button == 1 then
    viewer:setMode("coms")
    
  --journal
  elseif x > 790 and x < 925 and y > 350 and y < 510 and button == 1 then
    viewer:setMode("journal")
  
  --everywhere else
  else
    viewer:setMode("system")
  end
  
  --testing
  if button == 1 then
      printx = x
      printy = y
  end
end
