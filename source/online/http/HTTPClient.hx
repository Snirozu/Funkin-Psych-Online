package online.http;

import haxe.ValueException;
import online.util.OneOf;
import haxe.Exception;
import haxe.io.Error;
// import haxe.io.Eof; avoid using that, unreliable
import haxe.io.Bytes;
import haxe.io.Output;
import sys.net.Host;
import sys.net.Socket;
import haxe.io.BytesOutput;
import haxe.ds.Either;

class HTTPClient {
	public var address(default, null):HTTPAddress;
	public var requestData(default, null):HTTPRequest;
	public var response(default, null):HTTPResponse;

	public var cancelRequested(default, null):Bool = false;

	var socket:Socket;

	public var status(default, set):Null<ClientStatus>;
	function set_status(v:Null<ClientStatus>) {
		status = v;
		if (onStatus != null)
			onStatus(status);
		return status;
	}
	public var contentLength(default, null):Float = 0;
	public var receivedBytes(default, null):Float = 0;

	public var onStatus:Null<ClientStatus>->Void;
	
	/**
	 * @param address Can be either a `HTTPAddress` or a URL string.
	 */
	public function new(address:OneOf<HTTPAddress, String>) {
		switch (address) {
			case Left(v):
				this.address = v;
			case Right(v):
				this.address = parseStringToAddress(v);
			case null:
				throw new Exception('Null Argument');
		}
    }

	public function request(?data:OneOf<HTTPRequest, String>):HTTPResponse {
		if (socket != null)
			throw new Exception('Socket Still Open');

		cancelRequested = false;
		contentLength = 0;
		receivedBytes = 0;
		status = CONNECTING;

		switch (data) {
			case Left(v):
				requestData = v;
			case Right(v):
				requestData = {
					path: v
				};
			case null:
				requestData = {};
		}

		if (requestData.path == null)
			requestData.path = address.path;

		response = new HTTPResponse();

		if (requestData.output != null)
			response.output = requestData.output;
		else
			response.output = new BytesOutput();

		try {
			var header:String = "";
			header += '\r\nHost: ${address.host}' + (address.port != 80 && address.port != 443 ? ':${address.port}' : '');
			header += '\r\nUser-Agent: haxe';
			if (requestData.body != null)
				header += '\r\nContent-Length: ' + Bytes.ofString(requestData.body).length;
			if (requestData.headers != null)
				for (key => value in requestData.headers)
					header += '\r\n$key: $value';

			if (requestData.path.length > 0 && requestData.path.charAt(0) != "/")
				requestData.path = "/" + requestData.path;

			// connecting to the server
			socket = address.ssl ? new sys.ssl.Socket() : new Socket();
			socket.setTimeout(5);
			socket.setBlocking(true);
			while (!cancelRequested) {
				try {
					socket.connect(new Host(address.host), address.port);
					socket.write('${requestData.post ? "POST" : "GET"} ${requestData.path} HTTP/1.1${header}\r\n\r\n${requestData.body != null ? requestData.body : ""}');
					break;
				}
				catch (e:Dynamic) {
					if (e == Error.Blocked) {
						// Blocked will be ignored
						continue;
					}
					if (ClientPrefs.isDebug())
						trace('Failed to connect!');
					throw e;
				}
			}
			if (cancelRequested) throw null;

			// read response status
			var _connectTries:Int = 3;
			var httpStatus:Array<String> = null;
			while (!cancelRequested && httpStatus == null) {
				try {
					httpStatus = socket.input.readLine().split(" ");
				}
				catch (e:Dynamic) {
					if (e == Error.Blocked) {
						// Blocked will be ignored
						continue;
					}

					if (_connectTries > 0 && Std.string(e).toLowerCase() == "eof") {
						_connectTries--;
						Sys.sleep(3);
						continue;
					}

					if (ClientPrefs.isDebug())
						trace('Failed to read header!');
					throw e;
				}
			}
			if (cancelRequested) throw null;

			response.statusLine = httpStatus.join(" ");
			httpStatus.shift();
			response.status = Std.parseInt(httpStatus.shift());

			status = READING_HEADERS;

			// read response headers
			response.headers = new Map<String, String>();
			while (!cancelRequested) {
				try {
					var readLine:String = socket.input.readLine();
					if (readLine.trim() == "")
						break;
					var splitHeader = readLine.split(": ");
					response.headers.set(splitHeader[0].toLowerCase(), splitHeader[1]);
				}
				catch (e:Dynamic) {
					if (e == Error.Blocked) {
						// Blocked will be ignored
						continue;
					}
					if (isEOF(e)) {
						// End of Request (early?) (previous ones will catch eof because http status header is required for http servers)
						break;
					}
					if (ClientPrefs.isDebug())
						trace('Failed to read headers!');
					throw e;
				}
			}
			if (cancelRequested) throw null;

			// forward to another location if it's specified
			if (response.headers.exists("location")) {
				if (socket != null) {
					socket.close();
					socket = null;
				}

				address = parseStringToAddress(response.headers.get("location"));
				return this.request({
					output: response.output
				});
			}

			if (response.headers.exists("content-length"))
				contentLength = Std.parseFloat(response.headers.get("content-length"));

			status = READING_BODY;

			// read response body
			var _gotLength:Int = 1;

			if (contentLength > 0) {
				var _buffer:Bytes = Bytes.alloc(1024);
				while (!cancelRequested && receivedBytes < contentLength) {
					try {
						_gotLength = socket.input.readBytes(_buffer, 0, _buffer.length);
						response.output.writeBytes(_buffer, 0, _gotLength);
						receivedBytes += _gotLength;
					}
					catch (e:Dynamic) {
						if (e == Error.Blocked) {
							// Blocked will be ignored
							continue;
						}
						response.output.close();
						if (isEOF(e)) {
							// End of Request
							break;
						}
						throw e;
					}
				}
				
			}
			else {
				var _lastLine = '';
				// while (_gotLength > 0) {
				while (!cancelRequested && _lastLine != '0') {
					try {
						_gotLength = Std.parseInt('0x' + (_lastLine = socket.input.readLine()));
						response.output.writeBytes(socket.input.read(_gotLength), 0, _gotLength);
						receivedBytes += _gotLength;
					}
					catch (e:Dynamic) {
						if (e == Error.Blocked) {
							// Blocked will be ignored
							continue;
						}
						response.output.close();
						if (isEOF(e)) {
							// End of Request
							break;
						}
						throw e;
					}
				}
			}
			if (cancelRequested) throw null;
			status = COMPLETED;
		}
		catch (exc) {
			if (cancelRequested || exc == null || (exc is ValueException && (cast exc).value == null))
				exc = new Exception('Socket Closed');

			if (ClientPrefs.isDebug())
				trace('Status: $status ' + ShitUtil.prettyError(exc) + "\nLine: " + response.statusLine);

			response.exception = exc;
		}

		if (socket != null) {
			socket.close();
			socket = null;
		}

		if (status != COMPLETED)
			status = FAILED(response.exception);

		return response;
	}

	public function close() {
		if (socket != null) {
			socket.close();
			socket = null;
		}
		try {
			response.output.close();
		} catch (_) {}
	}
	
	public function cancel() {
		cancelRequested = true;
	}

	public function isFetching() {
		return socket != null;
	}

	public static function parseStringToAddress(url:String):HTTPAddress {
		var url = url;
		var ssl:Bool = false;
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
		if (pathIndex == -1)
			pathIndex = url.length;

		if (portIndex != -1 && portIndex < pathIndex) {
			host = url.substr(0, portIndex);

			var portStr = url.substr(portIndex + 1, pathIndex - portIndex - 1);
			port = Std.parseInt(portStr);
		}
		else {
			host = url.substr(0, pathIndex);
		}

		var path = url.substr(pathIndex);

		return {
			host: host,
			port: port,
			path: path,
			ssl: ssl
		};
	}

	public static inline function isEOF(exc:Dynamic) {
		return Std.string(exc).toLowerCase() == "eof";
	}
}

typedef HTTPAddress = {
	var host:String;
	var port:Int;
	var path:String;
	@:optional var ssl:Bool;
}

typedef HTTPRequest = {
	@:optional var headers:Map<String, String>;
	@:optional var body:String; // can be changed to output but like, why would i need it rn?
	@:optional var post:Bool;
	
	@:optional var path:String;
	@:optional var output:Output;
}

class HTTPResponse {
	public var status:Int;
	public var statusLine:String;
	public var headers:Map<String, String>;
	public var exception:Dynamic;
	public var output:Output;

	var __bytes:Bytes;

	public function new() {}

	public function isFailed() {
		return exception != null || (status >= 400 && status <= 599);
	}

	public function getBytes():Bytes {
		if (output != null && output is BytesOutput) {
			try { // yes this does crash for some reason, no matter the null checks lol
				__bytes = cast(output, BytesOutput).getBytes();
				output.close();
			} catch (_) {}
		}
		return __bytes;
	}

	public function getString():String {
		getBytes(); //init __bytes
		if (__bytes != null)
			return __bytes.toString();
		return null;
	}
}

enum ClientStatus {
	CONNECTING;
	READING_HEADERS;
	READING_BODY;
	COMPLETED;
	FAILED(exc:Exception);
}