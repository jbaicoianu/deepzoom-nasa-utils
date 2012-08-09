#!/bin/bash

. ~/procspawn-lib.sh

calc() {
  SCALE=8
  if [ ! -z $2 ]; then
    SCALE="$2"
  fi
  echo "scale=${SCALE}; $1" |bc -l
}
floor() {
  echo $(calc "($1) / 1" 0)
}
ceil() {
  echo $(calc "(($1) + .9999) / 1" 0)
}
deepzoom_maxlevel() {
  WIDTH=$1
  HEIGHT=$2
  if [ $WIDTH -gt $HEIGHT ]; then
    SIZE=$WIDTH
  else
    SIZE=$HEIGHT
  fi
  echo $(ceil $(calc "l($SIZE)/l(2)"))
}

FULLWIDTH=86400
FULLHEIGHT=43200
TILESIZE=256
MINLEVEL=6

while getopts w:h:t:m: o
do  case "$o" in
  w)  FULLWIDTH=$OPTARG ;;
  h)  FULLHEIGHT=$OPTARG ;;
  t)  TILESIZE=$OPTARG ;;
  m)  MINLEVEL=$OPTARG ;;
  [?])  print >&2 "Usage: $0 [-w width] [-h height] [-s tilesize] [-b basename]"
    exit 1;;
  esac
done

if [ $FULLWIDTH -gt $FULLHEIGHT ]; then
  FULLSIZE=$FULLWIDTH
else
  FULLSIZE=$FULLHEIGHT
fi

MAXLEVEL=$(deepzoom_maxlevel $FULLWIDTH $FULLHEIGHT)

if [ -d $MAXLEVEL ]; then
  for LEVEL in `seq $((MAXLEVEL-1)) -1 $MINLEVEL`; do
    PREVLEVEL=$(($LEVEL+1))
    SCALEDWIDTH=$(echo "scale=0; $FULLWIDTH / 2^($MAXLEVEL - $LEVEL)" |bc -l)
    SCALEDHEIGHT=$(echo "scale=0; $FULLHEIGHT / 2^($MAXLEVEL - $LEVEL)" |bc -l)
    WIDTH=$(echo "scale=0; ($SCALEDWIDTH / $TILESIZE)" |bc -l)
    HEIGHT=$(echo "scale=0; ($SCALEDHEIGHT / $TILESIZE)" |bc -l)
    if [ ! -d $LEVEL ]; then
      mkdir $LEVEL
    fi
    echo
    echo "Level $LEVEL (${WIDTH}x${HEIGHT})"
    for ROW in `seq 0 $(($HEIGHT - 0))`; do
      printf "%4d: " $ROW
      for COL in `seq 0 $(($WIDTH - 0))`; do
        OUTFILE=$LEVEL/${COL}_${ROW}.png
        if [ ! -e $OUTFILE ]; then
          TILES_X=0
          TILES_Y=0

          TILE_TL="$PREVLEVEL/$(($COL * 2))_$(($ROW * 2)).png"
          TILE_TR="$PREVLEVEL/$(($COL * 2 + 1))_$(($ROW * 2)).png"
          TILE_BL="$PREVLEVEL/$(($COL * 2))_$(($ROW * 2 + 1)).png"
          TILE_BR="$PREVLEVEL/$(($COL * 2 + 1))_$(($ROW * 2 + 1)).png"

          CONVERTCMD="convert -bordercolor none -border 1x1 -trim +repage"
          MONTAGECMD="montage "
          [ -e $TILE_TL ] && MONTAGECMD="$MONTAGECMD $TILE_TL" && TILES_X=1 && TILES_Y=1
          [ -e $TILE_TR ] && MONTAGECMD="$MONTAGECMD $TILE_TR" && TILES_X=2
          [ -e $TILE_BL ] && MONTAGECMD="$MONTAGECMD $TILE_BL" && TILES_Y=2
          [ -e $TILE_BR ] && MONTAGECMD="$MONTAGECMD $TILE_BR"
          MONTAGECMD="$MONTAGECMD -tile ${TILES_X}x${TILES_Y} -background none -gravity NorthWest -geometry 50%x50%+0+0"
          if [ $TILES_X -gt 0 ] && [ $TILES_Y -gt 0 ]; then
            #echo "$MONTAGECMD $OUTFILE && $CONVERTCMD $OUTFILE $OUTFILE"
            #$MONTAGECMD $OUTFILE && $CONVERTCMD $OUTFILE $OUTFILE && echo -n '.' || echo -n '!'
            procspawn_queue "$MONTAGECMD $OUTFILE && $CONVERTCMD $OUTFILE $OUTFILE && echo -n '.' || echo -n '!'"
          fi
        else
          echo -n o
        fi
      done
      procspawn_start 4
      echo
    done
  done
else
  echo "Couldn't find high-detail tile directory ($MAXLEVEL)"
fi

