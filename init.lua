local server_factory = require("server_factory")
local default_headers = 'Content-Type: application/json\r\n'

wifi.setmode(wifi.STATIONAP)
wifi.ap.config({ssid="iBrator", auth=wifi.OPEN})

--TODO : Use cjson to filter the connectionToken
enduser_setup.manual(true)
enduser_setup.start(
    function()
        print("Connected as :" .. wifi.sta.getip())
        wifi.setmode(wifi.STATION)
        enduser_setup.stop()
        http.post("http://192.168.2.106/device", default_headers, '{"chipId" : "'.. node.chipid()..'"}"',
            function(statuscode, data)
                print(data)
                server_factory.start_webserver(data)
            end)
    end,
    function(err, str)
        print("Error: " .. err ": " .. str)
    end
);

