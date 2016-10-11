local server_factory = require("server_factory")
local default_headers = 'Content-Type: application/json\r\n'

wifi.setmode(wifi.STATIONAP)
wifi.ap.config({ssid="iBrator", auth=wifi.OPEN})

enduser_setup.manual(true)
enduser_setup.start(
    function()
        print("Connected as :" .. wifi.sta.getip())
        wifi.setmode(wifi.STATION)
        enduser_setup.stop()

        ws = websocket.createClient()
        ws:on("connection", function(ws)
          ws:send(cjson.encode({name = "henk"}))
          ws:send("yooo")
          print("got ws connection")
        end)
        ws:on("receive", function(_, msg, opcode)
          print('got message:', msg, opcode) 
        end)
        ws:on("close", function(_, status)
          print('connection closed', status)
          ws = nil -- required to lua gc the websocket client
        end)
        ws:connect("ws://192.168.2.106/ws/vibrate")
       
--        http.post("http://192.168.2.106/device", default_headers, '{"chipId" : "'.. node.chipid()..'"}"',
--            function(statuscode, data)
--                json = cjson.decode(data)
--                server_factory.start_webserver(json["connectionToken"])
--            end)
    end,
    function(err, str)
        print("Error: " .. err ": " .. str)
    end
);

