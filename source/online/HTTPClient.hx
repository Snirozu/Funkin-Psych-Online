package online;

import haxe.io.Error;
import haxe.io.Eof;
import haxe.io.Bytes;
import haxe.io.Output;
import sys.net.Host;
import sys.net.Socket;

// feel free to use it in your own project
/**
 * @author snirozu
 */
class HTTPClient {
	var hostname(default, null):String;
	var port(default, null):Int = 80;
	var ssl(default, null):Bool = false;

    /**
     * 
     * @param host Host Name that you want to connect to
     */
    public function new(host:String, ?isSSL:Null<Bool>) {
        // URL parsing
        var protocolAHost = host.split("://");
		ssl = protocolAHost.length > 1 && protocolAHost[0] == "https";
        if (ssl) port = 443;
		var hostAPort = protocolAHost[protocolAHost.length - 1].split(":");
		hostname = hostAPort[0];
		if (hostAPort[1] != null)
			port = Std.parseInt(hostAPort[1]);

		if (isSSL != null)
		    ssl = isSSL;
    }

	public function request(request:HTTPRequest):HTTPResponse {
		var response:HTTPResponse = new HTTPResponse();
        try {
            var header:String = "";
			header += '\r\nHost: ${hostname}:${port}';
			header += '\r\nUser-Agent: haxe';
			if (request.body != null)
				header += '\r\nContent-Length: ' + Bytes.ofString(request.body).length;
            if (request.headers != null)
                for (key => value in request.headers)
					header += '\r\n$key: $value';

            //connecting to the server
            var socket:Socket;
            socket = ssl ? new sys.ssl.Socket() : new Socket();
            socket.setTimeout(5);
            socket.setBlocking(true);
            socket.connect(new Host(hostname), port);
			socket.write('${request.post ? "POST" : "GET"} ${request.path} HTTP/1.1${header}\r\n\r\n${request.body != null ? request.body : ""}');

            //read response status
            var status:Array<String> = socket.input.readLine().split(" ");
			status.shift();
			response.status = Std.parseInt(status.shift());
            response.body = status.join(" ");

            //read response headers
            response.headers = new Map<String, String>();
            while (true) {
                var readLine:String = socket.input.readLine();
                if (readLine.trim() == "")
                    break;
                var splitHeader = readLine.split(": ");
                response.headers.set(splitHeader[0].toLowerCase(), splitHeader[1]);
            }

            //forward to another location if it's specified
            if (response.headers.exists("location"))
                return this.request(request);

            var bodySize:Float = 0;
            if (response.headers.exists("content-length"))
                bodySize = Std.parseFloat(response.headers.get("content-length"));

            //read response body
            var buffer:Bytes = Bytes.alloc(1024);
            var _bytesWritten:Int = 0;
            var receivedContent:Float = 0;
            
            if (request.bodyOutput != null)
                while (receivedContent < bodySize) {
                    try {
                        _bytesWritten = socket.input.readBytes(buffer, 0, buffer.length);
                        request.bodyOutput.writeBytes(buffer, 0, _bytesWritten);
                        receivedContent += _bytesWritten;
                    }
                    catch (e:Dynamic) {
                        if (e is Eof || e == Error.Blocked) {
                            // Eof and Blocked will be ignored
                            continue;
                        }
                        request.bodyOutput.close();
                        throw e;
                    }
                }
            else {
				if (bodySize > 0)
                    response.body = "";
                while (receivedContent < bodySize) {
                    try {
                        _bytesWritten = socket.input.readBytes(buffer, 0, buffer.length);
                        response.body += buffer.getString(0, _bytesWritten);
                        receivedContent += _bytesWritten;
                    }
                    catch (e:Dynamic) {
                        if (e is Eof || e == Error.Blocked) {
                            // Eof and Blocked will be ignored
                            continue;
                        }
                        throw e;
                    }
                }
            }
        }
        catch (exc) {
			response.exception = exc;
        }

        return response;
    }

    public function getURL(path:String) {
		return (ssl ? "https://" : "http://") + hostname + (port != 80 && port != 443 ? ":" + port : "") + path;
    }
}

typedef HTTPRequest = {
    @:optional var post:Bool;
    var path:String;
	@:optional var headers:Map<String, String>;
    @:optional var body:String;
    
	@:optional var bodyOutput:Output;
}

class HTTPResponse {
	public var status:Int;
	public var headers:Map<String, String>;
	public var body:String;
    public var exception:Dynamic;

    public function new() {}

    public function isFailed() {
		return exception != null || (status >= 400 && status <= 599);
    }
}