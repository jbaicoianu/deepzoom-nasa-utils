var exec = require('child_process').exec;

var DeepZoom = function () {
	this.filesystem = require('fs');
	this.mkdirp = require('mkdirp');
	this.imagemagick = require("imagemagick");
	this.execSync = require("exec-sync");
};

DeepZoom.prototype = {
	
	// returns the maximum zoom level given an image's width and height
	maxLevel: function ( width, height ) {
		// console.log("maxlevel", width, height)
		var size;
		
		if ( width > height ) {
			
			size = width;
			
		}
		else {
			
			size = height;
			
		}
		
		return Math.ceil(
			Math.log(size) / 0.6931471805599453 /* ln(2) precomputed 64 bit precision */
		);
		
	},
	
	scaleRatio: function ( width, height ) {
		
		var max = this.maxLevel(width, height);
		var size;
		
		if ( width > height ) {
			
			size = width;
			
		}
		else {
			
			size = height;
			
		}
		

		return Math.pow(2, max)/size;
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
	
	//
    // Recursively combines tiles from maxlevel to minlevel
	//
	combine: function ( fullWidth, fullHeight, tilesize, filePath, format ) {
		
		var convertCommand    = "convert -bordercolor none -border 1x1 -trim +repage",
			maxLevel          = this.maxLevel(fullWidth, fullHeight),
			maxLevelPath      = [filePath, "/", maxLevel].join(""),
			scaledWidth		  = 0,
			scaledHeight	  = 0,
			calculatedWidth   = 0,
			calculatedHeight  = 0,
			levelPath         = '',
			previousLevel     = 0;
			
			// console.info(maxLevel);
		
		for ( var level = maxLevel -1, levelLimit = -1; level > levelLimit; level -= 1 ) {

			previousLevel    = level + 1;
			scaledWidth      = Math.ceil( fullWidth / Math.pow(2, maxLevel - level));
			scaledHeight     = Math.ceil( fullHeight / Math.pow(2, maxLevel - level));
			calculatedWidth  = Math.ceil( scaledWidth / tilesize );
			calculatedHeight = Math.ceil( scaledHeight / tilesize );
			levelPath		 = [filePath, "/", level].join("");
			// TODO Make level path if not exist
			
			if (!this.filesystem.existsSync(levelPath)) {
				this.filesystem.mkdirSync(levelPath);
			}
			
			// Exit the loop if we are out of data to combine.
			if (calculatedWidth == 1 && calculatedHeight == 1) {
				level = levelLimit;
				// continue;
			}
			
			console.info([
				
				"\nLevel ", level,
				" - ❪ ", calculatedWidth, "x", calculatedHeight, " ❫"
				
			].join(""));
			
			var levelTotalCount = calculatedHeight * calculatedWidth;
			var progressCount = 0;
			for ( var row = 0, rowLimit = calculatedHeight; row < rowLimit; row += 1 ) {
				
				for ( var col = 0, colLimit = calculatedWidth; col < colLimit; col += 1 ) {
				
					var outputFile = [levelPath, "/", col, "_", row, ".", format].join("");

					// if ( !this.filesystem.existsSync(outputFile) ) { // TODO check if file path !exists
						
						var tilesX            = 0,
						    tilesY            = 0,
							previousLevelPath = [filePath, "/", previousLevel, "/"],
							tiles             = [];
							
							// Figure out which tiles exist, which tells us how to build the montage command
							
							
							// ---------
							// | o | • |
							// ---------
							// | • | • |
							// ---------
							var tileTopLeft = previousLevelPath.concat((col * 2), "_", (row * 2), ".", format).join("");
							if ( this.filesystem.existsSync( tileTopLeft ) ) {
								
								tiles.push( tileTopLeft );
								
								tilesX = 1;
								tilesY = 1;
								
							}
							
							// ---------
							// | • | o |
							// ---------
							// | • | • |
							// ---------
							var tileTopRight = previousLevelPath.concat(((col * 2) + 1), "_", (row * 2), ".", format).join("");
							if ( this.filesystem.existsSync( tileTopRight ) ) {
								
								tiles.push( tileTopRight );
								
								tilesX = 2;
								
							}
							
							// ---------
							// | • | • |
							// ---------
							// | o | • |
							// ---------
							var tileBottomLeft = previousLevelPath.concat((col * 2), "_", ((row * 2) + 1), ".", format).join("");
							if ( this.filesystem.existsSync( tileBottomLeft ) ) {
								
								tiles.push( tileBottomLeft );
								
								tilesY = 2;
								
							}
							
							// ---------
							// | • | • |
							// ---------
							// | • | o |
							// ---------
							var tileBottomRight = previousLevelPath.concat(((col * 2) + 1), "_", ((row * 2) + 1), ".", format).join("");
							if ( this.filesystem.existsSync( tileBottomRight ) ) {
								
								tiles.push( tileBottomRight );
								
							}
							
							montageCommand = ["montage"].concat(tiles).concat([
											 	"-tile", [tilesX, "x", tilesY].join(""),
											 	"-background", "none",
											 	"-gravity", "NorthWest",
											 	"-geometry", tilesize + "x" + tilesize + "+0+0"
											 ]);
												
							if ( tilesX > 0 && tilesY > 0 && !this.filesystem.existsSync(outputFile) ) {
								
								var command = montageCommand.concat(outputFile).join(" ");
								this.execSync(command);
							}
							
							// The code below is just extra to show progress of the work.
							// It has a performance cost but it's negligible.
							var percentBar = "\x1b[40m▩";
							var progressBarCount = (((++progressCount)/levelTotalCount) * 50);
							for (var pb = 0; pb < 50; pb += 1) {
								if (pb < progressBarCount) {
									percentBar += "\x1b[27;32;42m ";
								}
								else {
									percentBar += "\x1b[7;37;40m ";
								}
							}
							percentBar += "\x1b[30;40m▩\x1b[27;30;49m  ❪ ";
							percentBar += (Math.floor((progressBarCount * 20))/10) + "% ❫      ";
							process.stdout.write("\r" + percentBar);
							
							if (Math.floor((progressBarCount * 20))/10 == 100) {
								process.stdout.write("\r" + percentBar.split("\x1b[36;49m").join("\x1b[36;49m").replace("100%", "✔"));								
							}
						
					// }
				
				}

				
			}
				console.log("\n")			
		}
		process.stdout.write("\r\x1b[30;49m");		
		console.log("\nFinished.\n\n");

		
	},
	
	descriptor: function ( width, height, tilesize, basename ) {
		console.log(arguments);
	}
	
};

module.exports = DeepZoom;