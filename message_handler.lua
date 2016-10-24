local message_handler = {} 
local pin = 4
local value = gpio.LOW

function toggleLED ()
    if value == gpio.LOW then
        value = gpio.HIGH
    else
        value = gpio.LOW
    end
 
    gpio.write(pin, value)
end

 
message_handler.handle = function(msg)
    value = gpio.LOW
    gpio.mode(pin, gpio.OUTPUT)
    gpio.write(pin, value)
  
    json = cjson.decode(msg)

    if(json["duration"] == nil) then
        print("nill")
    else 
        duration = json["duration"]
        print(duration)
        if not tmr.alarm(0, duration * 1000, tmr.ALARM_SINGLE, function() toggleLED() end) then print("error") end
    end
    
end 

return message_handler
