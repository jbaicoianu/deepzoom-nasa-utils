#!/usr/bin/env node

var sys = require('sys')
var exec = require('child_process').exec;


var CommandLineUtility = function (config) {
	
	this.userProvidedArguments = process.argv.slice(2);
	this.help = config.help || "No help.";

	
	this.processUserProvidedArguments(config);
	
	config.processArguments.call(this);
	
};

CommandLineUtility.prototype = {
	
	systemOut: function (message) {
		
		console.log("\n    " + message + "\n");
		
	},
	
	processUserProvidedArguments: function (config) {
		
		this.requiredArguments = {};
		this.optionalArguments = {};
		
		for ( var i = 0, len = config.requiredArguments.length; i < len; i += 1 ) {
		
			var argument = config.requiredArguments[i];
		
			if ( this.userProvidedArguments.indexOf("-" + argument) > -1 ) {
				
				var value = this.userProvidedArguments[this.userProvidedArguments.indexOf("-" + argument) + 1];
				
				if ( value && value.indexOf("-") == -1 ) {
					
					this.requiredArguments[argument] = this.userProvidedArguments[this.userProvidedArguments.indexOf("-" + argument) + 1];					
					
				}
				else {

					this.systemOut(this.help);
					process.exit(1);

				}
				
			}
			else {
				
				this.systemOut(this.help);
				process.exit(1);
				
			}
		
		}
	
		for ( var i = 0, len = config.optionalArguments.length; i < len; i += 1 ) {
		
			var argument = config.optionalArguments[i];
		
			if (this.userProvidedArguments.indexOf("-" + argument) > -1) {
				

				
				var value = this.userProvidedArguments[this.userProvidedArguments.indexOf("-" + argument) + 1];
				
				if ( value && value.indexOf("-") == -1 ) {
					
					this.optionalArguments[argument] = this.userProvidedArguments[this.userProvidedArguments.indexOf("-" + argument) + 1];					
					
				}
				else {

					this.systemOut(this.help);
					process.exit(1);

				}
				
			}
			else if ( config.defaults && config.defaults[argument] ) {

				this.optionalArguments[argument] = config.defaults[argument];

			}
		
		}
	
	}
	
};










var DeepZoom = function () {
	this.filesystem = require('fs');
	this.mkdirp = require('mkdirp');
	this.imagemagick = require("imagemagick");
};

DeepZoom.prototype = {
	
	// returns the maximum zoom level given an image's width and height
	maxLevel: function ( width, height ) {
		
		var size;
		
		if ( width > height ) {
			
			size = width;
			
		}
		else {
			
			size = height;
			
		}
		
		return Math.ceil(
			Math.log(size) / 0.30102999566 /* Log(2) precomputed */
		);
		
	},
	
	split: function ( width, height, tilesize, basename, offsetColumn, offsetRow, format, sourceFile, cachesize ) {
		
		offsetColumn = offsetColumn || 0;
		offsetRow = offsetRow || 0;
		format = format;
		
		var filePath = basename + "_files",
			descriptor = basename + ".xml",
			maxLevel = this.maxLevel(width, height),
			maxLevelPath = filePath + "/" + maxLevel;
			
			
		this.mkdirp(filePath, function (error) {
		    if(!error){
				this.mkdirp(maxLevelPath, function (error) {
				    if(!error){
						// NOP
				    } else {
				        console.error(error);
						process.exit(1);
				    }
				});
		    } else {
		        console.error(error);
				process.exit(1);
		    }
		}.bind(this));
		
		var convertArguments = [
			  
			  "-limit", "area", cachesize,
			  "-sigmoidal-contrast", "4,0%",
			  "-background", "none"
			  
		];
			
		if (offsetColumn > 0 || offsetRow > 0) {
			
			convertArguments = convertArguments.concat([
  			  "-splice", offsetColumn + "x" + offsetRow,
  			  "-page", "+0+0",
			]);

		}
		
		// convertArguments = [sourceFile].concat(convertArguments);
		
		convertArguments = convertArguments.concat([
			
			"-crop", tilesize + "x" + tilesize,
			"-size", width + "x" + height,
			sourceFile,
  		  maxLevelPath + "/123." + format
		]);

		var out = "";
		for (var i = 0; i < convertArguments.length; i ++) {
			out += " " + convertArguments[i]
		}
		console.log(out)

		this.imagemagick.convert(
			convertArguments,
			function () {
		
				console.log(arguments);
		
			}
		);
		
		
		// console.log(arguments);
	},
	
	rename: function ( basename, columns, rows ) {
		console.log(arguments);
	},
	
	combine: function ( width, height, tilesize, basename ) {
		console.log(arguments);
	},
	
	descriptor: function ( width, height, tilesize, basename ) {
		console.log(arguments);
	}
	
};


new CommandLineUtility({
	help: "Ussage: [-source source][-command command] [-width width] [-height height] [-tilesize tilesize] [-basename basename]",
	requiredArguments: [
		"command",
		"width",
		"height",
		"source"
	],
	optionalArguments: [
		"tilesize",
		"basename",
		"format",
		"column",
		"row",
		"cachesize"
	],
	defaults: {
		cachesize: "500mb",
		format: "png",
		tilesize: 256,
		minLevel: 6
	},
	// Called in the context of the command line utility.
	processArguments: function () {
		
		var deepZoom = new DeepZoom();
		
		if ( this.requiredArguments.command == "maxlevel" ) {
			
			deepZoom.maxLevel(
				this.requiredArguments.width,
				this.requiredArguments.height
			);
			
		}
		
		if ( this.requiredArguments.command == "split" ) {
			
			if ( !this.optionalArguments.tilesize || !this.optionalArguments.basename ) {
				
				this.systemOut("To split you must provide [-tilesize tilesize] [-basename basename]");
				process.exit(1);
				
			}
			

			
			deepZoom.split(
				this.requiredArguments.width,
				this.requiredArguments.height,
				this.optionalArguments.tilesize,
				this.optionalArguments.basename,
				this.optionalArguments.column,
				this.optionalArguments.row,
				this.optionalArguments.format,
				this.requiredArguments.source,
				this.optionalArguments.cachesize
			);
		}
		
		if ( this.requiredArguments.command == "rename" ) {
			
			if ( !this.optionalArguments.tilesize || !this.optionalArguments.basename ) {
				
				this.systemOut("To rename you must provide [-tilesize tilesize] [-basename basename]");
				process.exit(1);
				
			}
			
			deepZoom.rename(
				this.optionalArguments.basename,
				Math.ceil(
					this.requiredArguments.width/this.optionalArguments.tilesize
				),
				Math.ceil(
					this.requiredArguments.height/this.optionalArguments.tilesize
				),
				"png"
			);
			
		}
		
		if ( this.requiredArguments.command == "combine" ) {
			
			if ( !this.optionalArguments.tilesize || !this.optionalArguments.basename ) {
				
				this.systemOut("To combine you must provide [-tilesize tilesize] [-basename basename]");
				process.exit(1);
				
			}
			
			deepZoom.combine(
				this.requiredArguments.width,
				this.requiredArguments.height,
				this.optionalArguments.tilesize,
				this.optionalArguments.basename
			);
			
			
		}
		
		if ( this.requiredArguments.command == "descriptor" ) {
			
			if ( !this.optionalArguments.tilesize || !this.optionalArguments.basename ) {
				
				this.systemOut("To generate a descriptor you must provide [-tilesize tilesize] [-basename basename]");
				process.exit(1);
				
			}
			
			deepZoom.descriptor(
				this.optionalArguments.basename,
				this.requiredArguments.width,
				this.requiredArguments.height,
				this.optionalArguments.tilesize
			);
			
		}
		
	},
	

});


