#!/usr/bin/env node

var sys = require('sys')
var CommandLineUtility = require('./commandline-utils.js');


var DeepZoom = require('./deep-zoom-lib.js');




new CommandLineUtility({
	help: "Ussage: [-command command] [-width width] [-height height] [-tilesize tilesize] [-basename basename]\n    Optional: [-source source]",
	requiredArguments: [
		"command",
		"width",
		"height"
	],
	optionalArguments: [
		"tilesize",
		"basename",
		"format",
		"column",
		"row",
		"cachesize",
		"source",
		"filepath"
	],
	defaults: {
		cachesize: "500mb",
		format: "png",
		tilesize: 256,
		minLevel: 6,
		filepath: "./"
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
			
			if ( !this.optionalArguments.tilesize ) {
				
				this.systemOut("To combine you must provide [-tilesize tilesize]");
				process.exit(1);
				
			}
			
			deepZoom.combine(
				this.requiredArguments.width,
				this.requiredArguments.height,
				this.optionalArguments.tilesize,
				this.optionalArguments.filepath,
				this.optionalArguments.format
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


