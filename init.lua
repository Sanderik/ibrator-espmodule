local default_headers = 'Content-Type: application/json\r\n'

-- Server factory
local server_factory = {} 

server_factory.start_webserver = function(connection_token)
    print("creating webserver")
    server = net.createServer(net.TCP)
    server:listen(80,function(conn) 
        conn:on("receive", function(client,request)
            local buf = ""; 
            
            buf = buf.."<html><body><h2>Your connection token: </h2>"
            buf = buf..connection_token.."<br/><br/>"
            buf = buf.."<i>Use this token to connect your vibrator to your account</i>"
            
            client:send(buf);
            client:close();
            collectgarbage();
        end) 
    end)
end

-- Message Handler
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

-- WIFI setup.
wifi.setmode(wifi.STATIONAP)
wifi.ap.config({ssid="iBrator", auth=wifi.OPEN})

enduser_setup.manual(true)
enduser_setup.start( 
    function()
        print("Connected as :" .. wifi.sta.getip())
        wifi.setmode(wifi.STATION)
        enduser_setup.stop() 
 
        print(node.chipid()) 

        http.post("http://192.168.2.106:8080/device", default_headers, '{"chipId" : "'.. node.chipid()..'"}"',
            function(statuscode, data)
                print(data)
                print(statuscode)
                if(statuscode == 200) then
                    json = cjson.decode(data)

                    connectionToken = json["connectionToken"]
                    if(json["user"] == null) then
                        server_factory.start_webserver(connectionToken)
                    else
                        print("starting ws client") 
                        ws = websocket.createClient()
                        ws:on("connection", function(ws)
                          ws:send(cjson.encode({token = connectionToken}))
                          print("got ws connection")
                        end)
                        ws:on("receive", function(_, msg, opcode)
                          message_handler.handle(msg)
                          print('got message:', msg, opcode) 
                        end)
                        ws:on("close", function(_, status)
                          print('connection closed', status)
                          ws = nil 
                        end)
                        ws:connect("ws://192.168.2.106:8080/ws/vibrate")
                    end
                end
            end)

    end,
    function(err, str)
        print("Error: " .. err ": " .. str)
    end
);



