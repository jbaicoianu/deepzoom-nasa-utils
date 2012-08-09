#!/bin/bash

calc() {
  # use bc to perform advanced shell math
  SCALE=8
  if [ ! -z $2 ]; then
    SCALE="$2"
  fi
  echo "scale=${SCALE}; $1" |bc -l
}
floor() {
  RESULT=$(calc "$1")
  echo $(calc "$RESULT / 1" 0)
}
ceil() {
  RESULT=$(calc "$1")
  echo $(calc "( $RESULT + .99999) / 1" 0)
}
deepzoom_maxlevel() {
  # returns the maximum zoom level given an image's width and height
  WIDTH=$1
  HEIGHT=$2
  if [ $WIDTH -gt $HEIGHT ]; then
    SIZE=$WIDTH
  else
    SIZE=$HEIGHT
  fi
  echo $(ceil "l($SIZE)/l(2)")
}
deepzoom_exec() {
  # executes a command, or just echo it if debug mode is set
  CMD=$*
  if [ "$DEEPZOOMDEBUG" = "1" ]; then
    echo $CMD
  else
    $CMD
  fi
}
deepzoom_split() {
  # splits an image into its highest level of tiles
  FULLWIDTH=$1
  FULLHEIGHT=$2
  TILESIZE=$3
  SOURCEFILE=$4
  FORMAT=$7
  OFFSETCOL=$5
  OFFSETROW=$6

  [ -z "$OFFSETCOL" ] && OFFSETCOL=0
  [ -z "$OFFSETROW" ] && OFFSETROW=0
  [ -z "$FORMAT" ] && FORMAT="png"

  FILEBASE=$(basename ${SOURCEFILE%.*})
  FILEPATH="${FILEBASE}_files"
  DESCRIPTOR="${FILEBASE}.xml"
  MAXLEVEL=$(deepzoom_maxlevel $FULLWIDTH $FULLHEIGHT)
  MAXLEVELPATH="${FILEPATH}/${MAXLEVEL}"

  CONVERTCMD="convert"
  [ ! -z "$CACHESIZE" ] && CONVERTCMD="$CONVERTCMD -limit area $CACHESIZE"
  [ ! -z "$IMAGEFILTERS" ] && CONVERTCMD="$CONVERTCMD $IMAGEFILTERS"
  
  if [ $OFFSETCOL -gt 0 ] || [ $OFFSETROW -gt 0 ]; then
    CONVERTCMD="$CONVERTCMD -background none -splice ${OFFSETCOL}x${OFFSETROW} -page +0+0"
  fi

  [ ! -d "$FILEPATH" ] && deepzoom_exec mkdir -p "$FILEPATH"
  [ ! -d "$MAXLEVELPATH" ] && deepzoom_exec mkdir "$MAXLEVELPATH"

  CONVERTCMD="$CONVERTCMD -crop ${TILESIZE}x${TILESIZE} ${SOURCEFILE} ${MAXLEVELPATH}/%d.${FORMAT}"
  deepzoom_exec $CONVERTCMD

  COLS=$(ceil "$FULLWIDTH / $TILESIZE")
  ROWS=$(ceil "$FULLHEIGHT / $TILESIZE")

  deepzoom_rename $MAXLEVELPATH $ROWS $COLS $FORMAT
  deepzoom_combine $FILEPATH $FULLWIDTH $FULLHEIGHT $TILESIZE $FORMAT
  deepzoom_descriptor $DESCRIPTOR $FULLWIDTH $FULLHEIGHT $TILESIZE $FORMAT
}
deepzoom_rename() {
  TILEPATH=$1
  ROWS=$2
  COLS=$3
  FORMAT=$4

  ROWSTART=0
  COLSTART=0
  TILEOFFSETROW=0
  TILEOFFSETCOL=0
  KEEPFILES=0

  for ROW in `seq 0 $(($ROWS-1))`; do
    for COL in `seq 0 $(($COLS-1))`; do
      TILENUM=$(($ROW * $COLS + $COL))
      WRONGFNAME="$TILEPATH/${TILENUM}.$FORMAT"
      RIGHTFNAME="$TILEPATH/$(($COL + $COLSTART - $TILEOFFSETCOL))_$(($ROW + $ROWSTART - $TILEOFFSETROW)).${FORMAT}"
      if [ -e $RIGHTFNAME ]; then
        deepzoom_exec convert -background none -extent ${TILESIZE}x${TILESIZE} -composite $WRONGFNAME $RIGHTFNAME $RIGHTFNAME
        if [ $KEEPFILES != 1 ]; then
          deepzoom_exec rm $WRONGFNAME
        fi
        echo -n "*"
        #echo "* $(($ROW * $TILECOLS + $COL)) => $RIGHTFNAME"
      else
        if [ $KEEPFILES != 1 ]; then
          deepzoom_exec mv $WRONGFNAME $RIGHTFNAME && echo -n '' || echo -n '!'
        else
          deepzoom_exec cp $WRONGFNAME $RIGHTFNAME && echo -n '' || echo -n '!'
        fi
        echo -n .
        #echo " $(($ROW * $TILECOLS + $COL)) => $RIGHTFNAME"
      fi
    done
  done
}
deepzoom_combine() {
  # recursively combines tiles from maxlevel to minlevel
  FILEPATH=$1
  FULLWIDTH=$2
  FULLHEIGHT=$3
  TILESIZE=$4
  FORMAT=$5
  [ -z "$FORMAT" ] && FORMAT="png"

  MAXLEVEL=$(deepzoom_maxlevel $FULLWIDTH $FULLHEIGHT)
  MAXLEVELPATH="${FILEPATH}/${MAXLEVEL}"

  if [ -d $MAXLEVELPATH ]; then
    for LEVEL in `seq $((MAXLEVEL-1)) -1 $MINLEVEL`; do
      PREVLEVEL=$(($LEVEL+1))
      SCALEDWIDTH=$(floor "$FULLWIDTH / 2^($MAXLEVEL - $LEVEL)")
      SCALEDHEIGHT=$(floor "$FULLHEIGHT / 2^($MAXLEVEL - $LEVEL)")
      WIDTH=$(floor "$SCALEDWIDTH / $TILESIZE")
      HEIGHT=$(floor "$SCALEDHEIGHT / $TILESIZE")
      LEVELPATH="${FILEPATH}/${LEVEL}"
      if [ ! -d "$LEVELPATH" ]; then
        deepzoom_exec mkdir -p "$LEVELPATH"
      fi
      echo
      echo "Level $LEVEL (${WIDTH}x${HEIGHT})"
      for ROW in `seq 0 $(($HEIGHT - 0))`; do
        printf "%4d: " $ROW
        for COL in `seq 0 $(($WIDTH - 0))`; do
          OUTFILE=${LEVELPATH}/${COL}_${ROW}.${FORMAT}
          if [ ! -e $OUTFILE ]; then
            TILES_X=0
            TILES_Y=0

            # figure out which tiles exist, which tells us how to build the montage command
            TILE_TL="$FILEPATH/$PREVLEVEL/$(($COL * 2))_$(($ROW * 2)).${FORMAT}"
            TILE_TR="$FILEPATH/$PREVLEVEL/$(($COL * 2 + 1))_$(($ROW * 2)).${FORMAT}"
            TILE_BL="$FILEPATH/$PREVLEVEL/$(($COL * 2))_$(($ROW * 2 + 1)).${FORMAT}"
            TILE_BR="$FILEPATH/$PREVLEVEL/$(($COL * 2 + 1))_$(($ROW * 2 + 1)).${FORMAT}"

            CONVERTCMD="convert -bordercolor none -border 1x1 -trim +repage"
            MONTAGECMD="montage "
            [ -e $TILE_TL ] && MONTAGECMD="$MONTAGECMD $TILE_TL" && TILES_X=1 && TILES_Y=1
            [ -e $TILE_TR ] && MONTAGECMD="$MONTAGECMD $TILE_TR" && TILES_X=2
            [ -e $TILE_BL ] && MONTAGECMD="$MONTAGECMD $TILE_BL" && TILES_Y=2
            [ -e $TILE_BR ] && MONTAGECMD="$MONTAGECMD $TILE_BR"
            MONTAGECMD="$MONTAGECMD -tile ${TILES_X}x${TILES_Y} -background none -gravity NorthWest -geometry 50%x50%+0+0"
            if [ $TILES_X -gt 0 ] && [ $TILES_Y -gt 0 ]; then
              if [ $DEEPZOOMDEBUG = "1" ]; then
                echo "$MONTAGECMD $OUTFILE && $CONVERTCMD $OUTFILE $OUTFILE && echo -n '.' || echo -n '!'"
              else
                procspawn_queue "$MONTAGECMD $OUTFILE && $CONVERTCMD $OUTFILE $OUTFILE && echo -n '.' || echo -n '!'"
              fi
            fi
          else
            echo -n o
          fi
        done
        deepzoom_exec procspawn_start 4
        echo
      done
    done
  else
    echo "Couldn't find high-detail tile directory ($MAXLEVEL)"
  fi
}
deepzoom_descriptor() {
  FILENAME=$1
  FULLWIDTH=$2
  FULLHEIGHT=$3
  TILESIZE=$4
  FORMAT=$5
  OVERLAP=$6
  [ -z "$FORMAT" ] && FORMAT="png"
  [ -z "$OVERLAP" ] && OVERLAP=0

  OUTPUT=$(cat <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<Image TileSize="${TILESIZE}" Overlap="${OVERLAP}" Format="${FORMAT}" xmlns="http://schemas.microsoft.com/deepzoom/2008">
    <Size Width="${FULLWIDTH}" Height="${FULLHEIGHT}"/>
</Image>
EOF
)
  if [ "$FILENAME" = "-" ]; then
    echo -e "$OUTPUT"
  else
    echo -e "$OUTPUT" >$FILENAME
  fi
}
