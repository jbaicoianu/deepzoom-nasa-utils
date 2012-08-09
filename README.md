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

 * MEGDR digital elevation data 
     http://pds-geosciences.wustl.edu/missions/mgs/megdr.html

Examples
========

Simple Deepzoom Image
---------------------

> ./scripts/deepzoom.sh -w <width> -h <height> -s <tilesize> split <imagename>


Mars Elevation
--------------

> $ for F in megt*.img; do 
>     DIR=`basename ${F/.img/}`
>     [ ! -d $DIR ] && mkdir $DIR
>     cd $DIR
>     tile-dem-srtm -f ../$F -w 11520 -h 5632 -s 256 -c 
>     cd ..
>   done


Earth Elevation
---------------

> $ cd $(deepzoom.sh -w 86400 -h 43200 maxlevel)
> $ tile-dem-srtm -f ../srtm_ramp2.world.86400x43200.bin -w 86400 -h 43200 -s 256 -c
> $ cd ..
> $ deepzoom.sh -w 86400 -h 43200 -s 256 combine
