local default_headers = 'Content-Type: application/json\r\n'
local version = 1
local base_url = "https://sanderdewinter.me:8443"
local connectionToken = nil

-- Webserver 
function start_webserver(connection_token)
    server = net.createServer(net.TCP)
    server:listen(80, function(conn) 
        conn:on("receive", function(client,request)           
            local buf = "<html><body><h2>Your connection token: </h2>"
            buf = buf..connection_token.."<br/><br/>"
            buf = buf.."<i>Use this token to connect your vibrator to your account</i>"
            
            client:send(buf);
            client:close();
            collectgarbage();
        end) 
    end)
end

-- Message Handler
local pin = 1
local value = gpio.LOW

function toggleLED ()
    if value == gpio.LOW then
        value = gpio.HIGH
    else
        value = gpio.LOW
    end
 
    gpio.write(pin, value)
end 

 
function handle_socket_msg(msg)
    value = gpio.HIGH
    gpio.mode(pin, gpio.OUTPUT)
    gpio.write(pin, value)
  
    json = cjson.decode(msg)

    if(json["duration"] == nil) then
        print("nill")
    else 
        duration = json["duration"]
        if (duration == 0) then 
            print("stop timer")
            tmr.stop(0)
            toggleLED()
        else 
            tmr.start(0)
            interval = (100 - duration + 1) * 10
            print(interval)
            if not tmr.alarm(0, interval, tmr.ALARM_AUTO, function() toggleLED() end) then print("error") end
        end
    end
end 

-- Update mechanism 
function check_for_updates() 
    headers = default_headers .. 'Authorization:' .. connectionToken .. '\r\n'
    http.get(base_url .. "/firmware/version/" .. version, headers, function(code, data) 

        -- If a new version is available, replace it with the old version, but save a backup.
        if(code == 200) then
            file.remove("init-new.lua")
            file.remove("init-old.lua")

            if file.open("init-new.lua", "w") then
                file.write(data)
                file.close()

                -- Save a backup 
                if not file.rename("init.lua", "init-old.lua") then
                    print("something went wrong")
                end

                -- Replace old init.lua with the new one.
                if not file.rename("init-new.lua", "init.lua") then
                    print("something went wrong here")
                end

                -- Restart
                print("Update success restarting now...")
                node.restart()
            else
                print("cannot open")
            end
        end
    end) 
end  

-- Web sockets 
function create_socket_connection()
    ws = websocket.createClient()
    ws:on("connection", function(ws)
      ws:send(cjson.encode({token = connectionToken}))
      print("got ws connection")
    end)
    ws:on("receive", function(_, msg, opcode)
      handle_socket_msg(msg)
      print('got message:', msg, opcode) 
    end)
    ws:on("close", function(_, status)
      print('connection closed', status)
      ws = nil 
    end)
    ws:connect("wss://sanderdewinter.me:8443/ws/vibrate")
end

function initialize_device()
    http.post(base_url .. "/device", default_headers, '{"chipId" : "'.. node.chipid()..'"}"',
        function(statuscode, data)
            if(statuscode == 200) then
                json = cjson.decode(data)
                connectionToken = json["connectionToken"]
                if(json["hasUser"] == false) then
                    start_webserver(connectionToken)
                else 
                    create_socket_connection(connectionToken)
                    node.task.post(check_for_updates)
                end
            end
        end)
end

-- WIFI setup.
wifi.setmode(wifi.STATIONAP) 
wifi.ap.config({ssid="iBrator", auth=wifi.WPA2_PSK, pwd="12345678"})

enduser_setup.manual(true)
enduser_setup.start( 
    function()
        print("Connected as :" .. wifi.sta.getip())
        wifi.setmode(wifi.STATION)
        
        enduser_setup.stop() 
        initialize_device()
    end,
    function(err, str)
        print("Error: " .. err ": " .. str)
    end
);



