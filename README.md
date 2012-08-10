A collection of tools for turning raw NASA data into DeepZoom tiles.

Table of Contents
--------
* `scripts/`
  * `bluemarble-combine.sh`   - merges 8-panel BMNG tiles into one deepzoom
  * `bluemarble-split.sh `    - splits 8-panel BMNG images into tiles
  * `deepzoom.sh`             - command-line script for generating deepzoom images
  * `deepzoom-lib.sh`         - library of deepzoom-related functions
  * `procspawn-lib.sh`        - utility library for parallelizing shell scripts
* `src/`
  * `tile-dem-srtm/`          - splits raw BMNG/MEGDR elevation data into DEM heightmap image tiles


Datasets
--------
Earth:
 * BMNG
     http://visibleearth.nasa.gov/view.php?id=73570

 * CGIAR SRTM digital elevation data v4
     http://srtm.csi.cgiar.org/

Mars:
 * HiRISE
     http://hirise.lpl.arizona.edu/

 * MOLA MEGDR digital elevation data 
     http://pds-geosciences.wustl.edu/missions/mgs/megdr.html

Examples
========

Simple Deepzoom Image
---------------------
For general high-resolution imagery.  Generates all deepzoom levels and the
matching XML descriptor file automatically.

    ./scripts/deepzoom.sh -w [width] -h [height] -s [tilesize] split [imagename]


Mars Elevation
--------------
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


Earth Elevation
---------------
Earth elevation data is available in the CGIAR SRTM v4 dataset.  This data is
stored in a single 7gb raw file, so processing is pretty straightforward.

    $ cd $(deepzoom.sh -w 86400 -h 43200 maxlevel)
    $ tile-dem-srtm -f ../srtm_ramp2.world.86400x43200.bin -w 86400 -h 43200 -s 256 -c
    $ cd ..
    $ deepzoom.sh -w 86400 -h 43200 -s 256 combine


