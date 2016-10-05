wifi.setmode(wifi.STATIONAP)
wifi.ap.config({ssid="iBrator", auth=wifi.OPEN})

default_headers = 'Content-Type: application/json\r\n'
base_url = "http://192.168.2.102/ibrator-server/web/app_dev.php/api"

function register_device()
    body = '{"hostname": "' .. wifi.sta.getmac() .. '"}'
   
    http.post(base_url .. "/device", default_headers, body,
        function(code, data)
            if(code == 201) then
                print(data)
            else
                print("something went wrong")
            end
    end)
end

function check_updates()
    http.get(base_url .. "/update", default_headers, 
        function(code,data)
            --TODO : this
    end) 
end

enduser_setup.manual(true)
enduser_setup.start(
    function()
        print("Connected as :" .. wifi.sta.getip())
        wifi.setmode(wifi.STATION)
        register_device()
    end,
    function(err, str)
        print("Error: " .. err ": " .. str)
    end
);



