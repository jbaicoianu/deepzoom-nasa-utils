# DeepZoom Utilities

A collection of tools for turning raw NASA data into DeepZoom tiles.

##Package Contents

* `scripts/`
	* `bluemarble-combine.sh`   - merges 8-panel BMNG tiles into one deepzoom
	* `bluemarble-split.sh `    - splits 8-panel BMNG images into tiles
	* `deepzoom.sh`             - command-line script for generating deepzoom images
	* `deepzoom-lib.sh`         - library of deepzoom-related functions
	* `procspawn-lib.sh`        - utility library for parallelizing shell scripts
  
* `src/`
	* `deep-zoom/`                - node.js port of deepzoom command-line script for generating deepzoom images
	  * `deepzoom`              - The command line utility
	  * `deep-zoom-lib.js`      - Core libraries required for the utility to perform its operations
	  * `commandline-utils.js`  - Library for creating command line utlities with node.js
	* `tile-dem-srtm/`          - splits raw SRTM/MEGDR elevation data into DEM heightmap image tiles
	  * `linux/`              - linux source
	  * `osx/`                - Xcode project for OSX
  
  
##Datasets

###Earth:
 * BMNG
     http://visibleearth.nasa.gov/view.php?id=73570

 * CGIAR SRTM digital elevation data v4
     http://srtm.csi.cgiar.org/

###Mars:
 * HiRISE
     http://hirise.lpl.arizona.edu/

 * MOLA MEGDR digital elevation data 
     http://pds-geosciences.wustl.edu/missions/mgs/megdr.html


##Examples

###Simple Deepzoom Image

For general high-resolution imagery.  Generates all deepzoom levels and the
matching XML descriptor file automatically.

    ./scripts/deepzoom.sh -w [width] -h [height] -s [tilesize] split [imagename]


###Mars Elevation

Mars elevation data is available in the MEGDR dataset, with a resolution of up
to 128 pixels per degree.  This data is split into 12 files, so extra steps are
needed to merge the panels together

    $ for F in megt*.img; do 
        DIR=`basename ${F/.img/}`
        [ ! -d $DIR ] && mkdir $DIR
        cd $DIR
        tile-dem-srtm -f ../$F -w 11520 -h 5632 -s 256 -c 
        cd ..
      done


###Earth Elevation

Earth elevation data is available in the CGIAR SRTM v4 dataset.  This data is
stored in a single 7gb raw file, so processing is pretty straightforward.

```

    $ cd $(deepzoom.sh -w 86400 -h 43200 maxlevel)
    $ tile-dem-srtm -f ../srtm_ramp2.world.86400x43200.bin -w 86400 -h 43200 -s 256 -c
    $ cd ..
    $ deepzoom.sh -w 86400 -h 43200 -s 256 combine
	
```


## Utilities

The project consists of two main utilities for working with datasets. First *deepzoom* is a commandline utility for splitting and combining images into deepzoom tiles. Second is *tile-dem-srtm* for working with the *CGIAR SRTM v4* dataset.

##### Dependencies

The utlilities for working working with deepzoom tiles requires the use of ImageMagick to perform its operations.

###### OSX

```

sudo port install imagemagick

```


### DeepZoom

#### Package Contents

* `src/`
  * `deep-zoom/`                - node.js port of deepzoom command-line script for generating deepzoom images
	  * `deepzoom`              - The command line utility
	  * `deep-zoom-lib.js`      - Core libraries required for the utility to perform its operations
	  * `commandline-utils.js`  - Library for creating command line utlities with node.js



#### Dependencies

DeepZoom is built ontop of node.js and will require node.js to be installed to run.

* http://nodejs.org/

######Node.js Libraries

```

npm install mkdirp

```


#### Ussage

The combine command will require your /path/to/base/tiles to contain a numbered directory that represents you highest zoom level.
In the example below our highest zoom level will be 17 as determined by ceil( log( 86400 ) / log( 2 ) ). For each zoom level (power of 2) approaching zero a new folder will be created numberd with that zoom level into which the composite tiles will be deposited.

```bash

	$ ./deepzoom -command combine -width 86400 -height 43200 -tilesize 256 -filepath /path/to/base/tiles

```


### SRTM to DEM Tiles

#### Compiling tile-dem-srtm

```bash

g++ -Wall -pedantic -I/usr/include/ImageMagick/ -lMagick++ tile-dem-srtm.cpp -o tile-dem-srtm 

```

