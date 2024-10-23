package online.util;

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
	public var hostname(default, null):String;
	public var port(default, null):Int = 80;
	public var ssl(default, null):Bool = false;

	public function request(request:HTTPRequest):HTTPResponse {
		var response:HTTPResponse = new HTTPResponse();
        try {
            var header:String = "";
			header += '\r\nHost: ${hostname}' + (port != 80 && port != 443 ? ':${port}' : '');
			header += '\r\nUser-Agent: haxe';
			if (request.body != null)
				header += '\r\nContent-Length: ' + Bytes.ofString(request.body).length;
            if (request.headers != null)
                for (key => value in request.headers)
					header += '\r\n$key: $value';

            if (request.path.length > 0 && request.path.charAt(0) != "/")
                request.path = "/" + request.path;

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
            var _bytesWritten:Int = 1;
            var receivedContent:Float = 0;
			var _lastLine = '';
            
            if (request.bodyOutput != null)
				if (bodySize > 0) {
					while (receivedContent < bodySize) {
                        try {
                            _bytesWritten = socket.input.readBytes(buffer, 0, buffer.length);
                            request.bodyOutput.writeBytes(buffer, 0, _bytesWritten);
                            receivedContent += _bytesWritten;
                        }
                        catch (e:Dynamic) {
                            if (e == Error.Blocked) {
                                // Blocked will be ignored
                                continue;
                            }
                            request.bodyOutput.close();
                            throw e;
                        }
                    }
                }
                else {
					//while (_bytesWritten > 0) {
					while (_lastLine != '0') {
						try {
							_bytesWritten = Std.parseInt('0x' + (_lastLine = socket.input.readLine()));
                            request.bodyOutput.writeBytes(socket.input.read(_bytesWritten), 0, _bytesWritten);
                            receivedContent += _bytesWritten;
                        }
                        catch (e:Dynamic) {
							if (e == Error.Blocked) {
								// Blocked will be ignored
								continue;
							}
							throw e;
						}
					}
                }
            else {
				response.body = "";
                if (bodySize > 0) {
					while (receivedContent < bodySize) {
						try {
							_bytesWritten = socket.input.readBytes(buffer, 0, buffer.length);
							response.body += buffer.getString(0, _bytesWritten);
							receivedContent += _bytesWritten;
						}
						catch (e:Dynamic) {
							if (e == Error.Blocked) {
								// Blocked will be ignored
								continue;
							}
							throw e;
						}
					}
                }
                else {
					// while (_bytesWritten > 0) {
					while (_lastLine != '0') {
						try {
							_bytesWritten = Std.parseInt('0x' + (_lastLine = socket.input.readLine()));
                            response.body += socket.input.readString(_bytesWritten, UTF8);
                            receivedContent += _bytesWritten;
                        }
                        catch (e:Dynamic) {
							if (e == Error.Blocked) {
								// Blocked will be ignored
								continue;
							}
							throw e;
						}
					}
                }
            }
        }
        catch (exc) {
            if (!(exc is Eof))
			    response.exception = exc;
        }

        return response;
    }

	/**
	 * 
	 * @param host Host Name that you want to connect to
	 */
	public function new(host:String, ?isSSL:Null<Bool>) {
		// URL parsing
		var protocolAHost = host.split("://");

		ssl = protocolAHost.length > 1 && protocolAHost[0] == "https";
		if (ssl)
			port = 443;

		var hostAPort = protocolAHost[protocolAHost.length - 1].split(":");
		hostname = hostAPort[0];

		if (hostAPort[1] != null)
			port = Std.parseInt(hostAPort[1]);

		if (isSSL != null)
			ssl = isSSL;
	}

	public static function requestURL(url:String, ?requestOptions:HTTPURLRequest) {
		var url = url;
		var ssl:Null<Bool> = null;
		if (url.startsWith("https://")) {
			ssl = true;
			url = url.substr("https://".length);
		}
		else if (url.startsWith("http://")) {
			url = url.substr("http://".length);
		}

		var host = "";
		var port = ssl ?? false ? 443 : 80;

		var portIndex = url.indexOf(':');
		var pathIndex = url.indexOf('/');
		if (portIndex != -1 && portIndex < pathIndex) {
			host = url.substr(0, portIndex);

			var portStr = url.substr(portIndex + 1, pathIndex - portIndex - 1);
			port = Std.parseInt(portStr);
		}
		else {
			host = url.substr(0, pathIndex);
		}

		var path = url.substr(pathIndex);

		return new HTTPClient(host + ":" + port, ssl).request({
			path: path,
			post: requestOptions?.post,
			headers: requestOptions?.headers,
			body: requestOptions?.body,
			bodyOutput: requestOptions?.bodyOutput
		});
	}

    public function getURL(path:String) {
		if (path.length > 0 && path.charAt(0) != "/")
			path = "/" + path;
		return (ssl ? "https://" : "http://") + hostname + (port != 80 && port != 443 ? ":" + port : "") + path;
    }
}

typedef HTTPURLRequest = {
	@:optional var post:Bool;
	@:optional var headers:Map<String, String>;
	@:optional var body:String;
	@:optional var bodyOutput:Output;
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