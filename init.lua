local server_factory  = require("server_factory")
local message_handler = require("message_handler") 
local default_headers = 'Content-Type: application/json\r\n'

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



