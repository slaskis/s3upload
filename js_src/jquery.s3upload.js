(function($){
	$.fn.s3upload = function( settings ) {
		var config = {
			text: "Select file...",
			path: "/s3upload.swf",
			prefix: "",
			signature_url: "/s3upload",
			required: false,
			submit_on_all_complete: true,
			error_class: "s3_error",
			file_types: []
		};
		if( settings ) $.extend( config , settings );

		// TODO Define settings for the default visuals (like progress percentage or bar)

		// if any element is a form find all :file inputs inside instead.
		var elements = this.map( function() {
			if( $(this).is("form") )
				return $(this).find(":file").toArray();
			return $(this);
		} );

		var s3uploaders = 0;
		var started = 0;
		var completed = 0;
		
		return elements.each( function() {
			s3uploaders++;
			var form = $(this).closest("form");
			var id = $(this).attr("id") || "s3upload_"+s3uploaders;
			var name = $(this).attr("name");
	
			// replace the element with a div (or maybe a span would be better?) with 
			// a "Select file..." text (customizable of course through settings)
			$(this).replaceWith("<div id='"+id+"'></div>");
			
			var el = $("#"+id);
			
			// create a div for the transparent flash button and absolute position it
			// above the created element.
			var flash_div = $( "<div id='s3upload_"+id+"'><div id='flash_"+id+"'></div></div>" ).appendTo( "body" );
	
			// "Serialize" the filters
			var filters = $.map( config.file_types , function(f,i) { return f.join("#"); }).join("|");
			
			console.log( filters );
	
			// instantiate a swfobject in that div with js callbacks for selected, start, cancel, progress, error and complete
			var fv = { 
				id: "flash_"+id,
				prefix: config.prefix,
				signatureURL: config.signature_url,
				filters: filters
			};
			var attr = { wmode: "transparent" };
		    swfobject.embedSWF(config.path, fv.id, "100%", "100%", "9.0.0" , false, fv, false, attr, function(e){
				if( e.success ) {
					var swf = e.ref;
					
					// Now that the flash has been initialized, show the initial text
					el.text(config.text);
					
					// Position the swf on top of the element
					flash_div.css({
						width: el.width(),
						height: el.height(),
						position: "absolute",
						top: el.offset().top,
						left: el.offset().left
					});
					// TODO A timer to keep the flash div aligned on top of the status text
					
					// add a submit listener to the elements form which starts the upload in the flash instances.
					var formSubmit = function(){
						if( config.required && !swf.info )
							swf.onerror( "Error: No file selected." );
						else
							swf.upload();
						return false;
					}
					form.submit(formSubmit);
					
					swf.onselect = function(name,size,type) {
						swf.info = {name: name, size: size, type: type};
						var def = true;
						if( $.isFunction( config.onselect ) )
							def = config.onselect.call(swf,swf.info);
						if( def ) {
							// Do default stuff: Replace the text of the div with the filename?
							el.text(name);
						}
					}
			
					swf.oncancel = function() {
						var def = true;
						if( $.isFunction( config.oncancel ) )
							def = config.oncancel.call(swf,swf.info);
						if( def ) {
							// Do default stuff: Show a message? Go back to "Select file..." text?
							el.text(config.text);
						}
						swf.info = null;
					}
			
					swf.onstart = function() {
						var def = true;
						if( $.isFunction( config.onstart ) )
							def = config.onstart.call(swf,swf.info);
						if( def ) {
							// Do default stuff: Replace the text of the div?
						}
						started++;
						swf.disable();
					}
			
			
					swf.onprogress = function(p) {
						var def = true;
						if( $.isFunction( config.onprogress ) )
							def = config.onprogress.call(swf,p,swf.info);
						if( def ) {
							// Do default stuff: Fill the background of the div?
							el.text( Math.ceil( p * 100 ) + "%" );
						}
					}
			
			
					swf.onerror = function(msg) {
						var def = true;
						if( $.isFunction( config.onerror ) )
							def = config.onerror.call(swf,msg,swf.info);
						if( def ) {
							// Do default stuff: Replace the text with the error message?
							el.html( "<span class='"+config.error_class+"'>" + msg + "</span>" );
						}
						swf.enable();
					}
			
			
					swf.oncomplete = function(key) {
						var def = true;
						if( $.isFunction( config.oncomplete ) )
							def = config.oncomplete.call(swf,swf.info);
						if( def ) {
							// Do default stuff...
						}
						
						swf.info.key = key;
						
						var el_info = el.nextAll("input[name^="+name+"]");
						if( el_info.length == 0 ) { 
							// Create the hidden inputs
							for( var k in swf.info )
								el.after( "<input type='hidden' name='"+name+"["+k+"]' value='"+swf.info[k]+"' />" );
						} else {
							// Update the hidden inputs
							for( var k in swf.info )
								el.siblings( "input[name="+name+"["+k+"]]" ).val( swf.info[k] );
						}
				
						// Add to the total upload complete counter, and if it matches the number of uploads we submit the form.
						completed++;
						
						// Remove the hijacking form submit event
						form.unbind("submit",formSubmit); 
						
						if( started == completed && submit_on_all_complete ) {
							// All Done! Do a regular form submit
							form.submit();
						}
					}
					
				}
			});
		} );
	};
})(jQuery);