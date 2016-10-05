print("Setting up access point")

wifi.setmode(wifi.STATIONAP)
wifi.ap.config({ssid="iBrator", auth=wifi.OPEN})

function register_device()
    http.get("http://www.google.com", nil, function(code, data)
        print(code)
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



