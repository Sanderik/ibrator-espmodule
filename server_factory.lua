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

return server_factory
    
