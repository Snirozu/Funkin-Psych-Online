package online.http;

import online.http.HTTPClient;
import online.util.OneOf;
import haxe.ds.Either;
import haxe.Exception;

class HTTPHandler {
	public var address(default, null):HTTPAddress;

	public function new(address:OneOf<HTTPAddress, String>) {
		switch (address) {
			case Left(v):
				this.address = v;
			case Right(v):
				this.address = HTTPClient.parseStringToAddress(v);
			case null:
				throw new Exception('Null Argument');
		}
	}

	public function request(?data:OneOf<HTTPRequest, String>) {
		return new HTTPClient(address).request(data);
	}

	public function getURL(path:String) {
		if (path.length > 0 && path.charAt(0) != "/")
			path = "/" + path;
		return (address.ssl ? "https://" : "http://")
			+ address.host
			+ (address.port != 80 && address.port != 443 ? ":" + address.port : "")
			+ path;
	}
}