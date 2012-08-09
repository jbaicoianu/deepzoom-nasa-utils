A collection of tools for turning raw NASA data into DeepZoom tiles.

Contents
--------
* scripts/
  * bluemarble-combine.sh     # merges 8-panel BMNG tiles into one deepzoom
  * bluemarble-split.sh       # splits 8-panel BMNG images into tiles
  * deepzoom-convert-jpg.sh   # convert all images in a deepzoom to jpegs
  * procspawn-lib.sh          # utility library for parallelizing shell scripts
* src/
  * tile-dem-srtm/            # splits raw BMNG/MEGDR elevation data into DEM heightmap image tiles


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

