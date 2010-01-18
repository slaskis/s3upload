class S3Upload extends flash.display.Sprite {
	
	static var _id : String;
	var _signatureURL : String;
	var _prefix : String;
	var _fr : flash.net.FileReference;
	var _filters : Array<flash.net.FileFilter>;
	
	public function new() super()
	
	public function init() {
		_id = stage.loaderInfo.parameters.id;
		_signatureURL = stage.loaderInfo.parameters.signatureURL;
		_prefix = stage.loaderInfo.parameters.prefix;
		_filters = [];
		if( stage.loaderInfo.parameters.filters != null ) {
			for( filter in stage.loaderInfo.parameters.filters.split("|") ) {
				var f = filter.split("#");
				_filters.push( new flash.net.FileFilter( f[0] , f[1] ) );
			}
		}
		
		if( flash.external.ExternalInterface.available ) {
			flash.external.ExternalInterface.addCallback( "disable" , disable );
			flash.external.ExternalInterface.addCallback( "enable" , enable );
			flash.external.ExternalInterface.addCallback( "upload" , upload );
		}
		stage.addEventListener( "resize" , onStageResize );
		onStageResize();
		enable();
	}
	
	function onBrowse( e ) {
		var fr = new flash.net.FileReference();
		fr.addEventListener( "cancel" , function(e) { call( e.type , [] ); } );
		fr.addEventListener( "select" , function(e) { call( e.type , [fr.name,fr.size,extractType(fr)]); } );
		fr.browse( _filters );
		_fr = fr;
	}
	
	function enable() {
		buttonMode = true;
		addEventListener( "click" , onBrowse );
	}
	
	function disable() {
		buttonMode = false;
		removeEventListener( "click" , onBrowse );
	}
	
	function upload() {
		// No browse has been called
		if( _fr == null )
			return;
		
		// Fetch a signature and other good things from the backend
		var vars 			= new flash.net.URLVariables();
		vars.fileName 		= _fr.name;
		vars.fileSize 		= _fr.size;
		vars.contentType	= extractType( _fr );
		vars.key 			= _prefix + _fr.name;
		
		var req 			= new flash.net.URLRequest(_signatureURL);
		req.method			= flash.net.URLRequestMethod.GET;
		req.data			= vars;
		
		var load			= new flash.net.URLLoader();
		load.dataFormat		= flash.net.URLLoaderDataFormat.TEXT;
		load.addEventListener( "complete" , onSignatureComplete );
		load.addEventListener( "securityError" , onSignatureError );
		load.addEventListener( "ioError" , onSignatureError );
		load.load( req );
	}
	
	static function extractType( fr : flash.net.FileReference ) {
		if( fr.type == null || fr.type.indexOf( "/" ) == -1 ) {
			var ext = fr.name.split(".").pop();
			var mime = new MimeTypes().getMimeType( ext );
			if( mime == null )
				return "binary/octet-stream";
			else
				return mime;
		}
		return fr.type;
	}
	
	function onSignatureError(e) {
		call( "error" , ["Could not get signature because: " + e.message] );
	}
	
	function onSignatureComplete(e) {
		// Now that we have the signature we can send the file to S3.
		
		var load 			= cast( e.target , flash.net.URLLoader );
		var sign			= new haxe.xml.Fast( Xml.parse( load.data ).firstElement() );
		
		if( sign.has.error ) {
			call( "error" , ["There was an error while making the signature: " + sign.node.error.innerData] );
			return;
		}
		
		// Create an S3Options object from the signature xml
		var opts 			= {
			accessKeyId: sign.node.accessKeyId.innerData,
			acl: sign.node.acl.innerData,
			bucket: sign.node.bucket.innerData,
			contentType: sign.node.contentType.innerData,
			expires: sign.node.expires.innerData,
			key: sign.node.key.innerData,
			secure: sign.node.secure.innerData == "true",
			signature: sign.node.signature.innerData,
			policy: sign.node.policy.innerData
		};
		
		var fr = _fr;
		
		var req				= new S3Request( opts );
		req.onError 		= function(msg) { call( "error" , [msg] ); }
		req.onProgress 		= function(p) { call( "progress" , [p] ); }
		req.onComplete 		= function() { call( "complete" , [opts.key] ); }
		req.upload( _fr );
		call( "start" , [] );
	}
	
	static function call( eventType , args : Array<Dynamic> ) {
		var method = "on"+eventType;
		if( _id != null && flash.external.ExternalInterface.available ) {
			var c = "function(){
				var swf = document.getElementById('"+_id+"');
				if( swf )
					swf['"+method+"'].apply(swf,['"+args.join("','")+"']);
			}()";
			flash.external.ExternalInterface.call( c , [] );
		}
	}
	
	function onStageResize(e=null) {
		graphics.clear();
		graphics.beginFill( 0 , 0 );
		graphics.drawRect( 0 , 0 , stage.stageWidth , stage.stageHeight );
	}
	
	public static function main() {
		flash.Lib.current.stage.align = flash.display.StageAlign.TOP_LEFT;
		flash.Lib.current.stage.scaleMode = flash.display.StageScaleMode.NO_SCALE;
		
		var s = new S3Upload();
		flash.Lib.current.addChild( s );
		s.init();
	}
	
	
}

typedef S3Options = {
	var accessKeyId : String;
	var acl : String;
	var bucket : String;
	var contentType : String;
	var expires : String;
	var key : String;
	var secure : Bool;
	var signature : String;
	var policy : String;
}

class S3Request {
	
	static inline var AMAZON_BASE_URL = "s3.amazonaws.com";
	
	var _opts : S3Options;
	var _httpStatus : Bool;
	
	public var onComplete : Void -> Void;
	public var onProgress : Float -> Void;
	public var onError : String -> Void;
	
	public function new( opts : S3Options ) {
		_opts = opts;
		_httpStatus = false;
	}
	
	function getUrl() {
		var vanity = canUseVanityStyle();
		
		if( _opts.secure && vanity && _opts.bucket.indexOf( "." ) > -1 )
			throw new flash.errors.IllegalOperationError( "Cannot use SSL with bucket name containing '.': " + _opts.bucket );
			
		var url = "http" + ( _opts.secure ? "s" : "" ) + "://";
		
		if( vanity )
			url += _opts.bucket + "." + AMAZON_BASE_URL;
		else
			url += AMAZON_BASE_URL + "/" + _opts.bucket;
			
		return url;
	}
	
	function getVars() {
		var vars 			 = new flash.net.URLVariables();
        vars.key             = _opts.key;
        vars.acl             = _opts.acl;
        vars.AWSAccessKeyId  = _opts.accessKeyId;
        vars.signature       = _opts.signature;
		Reflect.setField( vars , "Content-Type" , _opts.contentType );
        vars.policy          = _opts.policy;
        vars.success_action_status = "201";
		return vars;
	}
	
	function canUseVanityStyle() {
		if( _opts.bucket.length < 3 || _opts.bucket.length > 63 )
			return false;
		
		var periodPosition = _opts.bucket.indexOf( "." );
		if( periodPosition == 0 && periodPosition == _opts.bucket.length - 1 )
			return false;
			
		if( ~/^[0-9]|+\.[0-9]|+\.[0-9]|+\.[0-9]|+$/.match( _opts.bucket ) )
			return false;
		
		if( _opts.bucket.toLowerCase() != _opts.bucket )
			return false;
		
		return true;
	}
	
	public function upload( fr : flash.net.FileReference ) {
		var url = getUrl();
        flash.system.Security.loadPolicyFile(url + "/crossdomain.xml");
		
		var req = new flash.net.URLRequest( url );
        req.method = flash.net.URLRequestMethod.POST;
        req.data = getVars();            
        
		fr.addEventListener( "uploadCompleteData" , onUploadComplete );
		fr.addEventListener( "securityError" , onUploadError );
		fr.addEventListener( "ioError" , onUploadError );
        fr.addEventListener( "progress" , onUploadProgress);
        fr.addEventListener( "httpStatus", onUploadHttpStatus);

        fr.upload(req, "file", false);
	}
	
	function onUploadComplete( e ) {
		if( isError( e.data ) )
			onError( "Amazon S3 returned an error: " + e.data );
		else
			onComplete();
	}
	
	function onUploadHttpStatus( e ) {
		_httpStatus = true;
		if( e.status >= 200 && e.status < 300 )
			onComplete();
		else
			onError( "Amazon S3 returned an error: " + e.status );
	}
	
	function onUploadProgress( e ) {
		onProgress( e.bytesLoaded / e.bytesTotal );
	}
	
	function onUploadError( e ) {
		if( !_httpStatus ) // ignore io errors if we already had a valid http status
			onError( "Amazon S3 returned an error: " + e.message );
	}
	
	function isError(responseText:String):Bool {
        var xml = Xml.parse(responseText);
        var root = xml.firstChild();
        return root != null && root.nodeName == "Error";
    }
	
}