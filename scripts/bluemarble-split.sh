#!/bin/sh

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
TILESIZE=128
FORMAT=png
BASENAME="world.topo.200408.3x21600x21600"
CACHESIZE=500mb
IMAGEFILTERS="-sigmoidal-contrast 4,0%"
KEEPFILES=0

while getopts w:h:t:b:k o
do  case "$o" in
  w)  FULLWIDTH=$OPTARG ;;
  h)  FULLHEIGHT=$OPTARG ;;
  t)  TILESIZE=$OPTARG ;;
  b)  BASENAME=$OPTARG ;;
  k)  KEEPFILES=1 ;;
  [?])  print >&2 "Usage: $0 [-w width] [-h height] [-s tilesize] [-b basename] [-k]"
    exit 1;;
  esac
done

MAXLEVEL=$(deepzoom_maxlevel "$FULLWIDTH" "$FULLHEIGHT")

TILECOLS_FLOAT=$(calc "${FULLWIDTH} / 4 / ${TILESIZE}")
TILEROWS_FLOAT=$(calc "${FULLHEIGHT} / 2 / ${TILESIZE}")

TILECOLS=$(ceil $TILECOLS_FLOAT)
TILEROWS=$(ceil $TILEROWS_FLOAT)

FULLCOLS=$(ceil "$TILECOLS_FLOAT * 4")
FULLROWS=$(ceil "$TILEROWS_FLOAT * 2")

TILETOTAL=$(calc "$FULLCOLS * $FULLROWS" 0)

LEFTOVER_ROW=$(floor "($TILEROWS - $TILEROWS_FLOAT) * $TILESIZE")
LEFTOVER_COL=$(floor "($TILECOLS - $TILECOLS_FLOAT) * $TILESIZE")

echo "Splitting ${BASENAME}.*.${FORMAT} (${FULLWIDTH}x${FULLHEIGHT}) into ${TILETOTAL} ${TILESIZE}x${TILESIZE} tiles (level ${MAXLEVEL}, ${FULLCOLS}x${FULLROWS})"

if [ ! -d $MAXLEVEL ]; then
  mkdir $MAXLEVEL
fi
OFFSETROW=0
OFFSETCOL=0
LNUM=0
echo Splitting source files
for LETTER in A B C D; do
  LNUM=$(($LNUM + 1))
  for NUM in 1 2; do
    SOURCEFILE="${BASENAME}.${LETTER}${NUM}.${FORMAT}"
    echo -n "${LETTER}${NUM}: "
    if [ -e $SOURCEFILE ]; then
      OFFSETROW=$((($NUM - 1) * ($TILESIZE - $LEFTOVER_ROW))) 
      OFFSETCOL=$((($LNUM - 1) * ($TILESIZE - $LEFTOVER_COL)))

      TILEOFFSETROW=$(floor "$OFFSETROW / $TILESIZE")
      TILEOFFSETCOL=$(floor "$OFFSETCOL / $TILESIZE")

      #echo $OFFSETROW $TILEOFFSETROW $OFFSETCOL $TILEOFFSETCOL

      convert -limit area ${CACHESIZE} ${IMAGEFILTERS} -background none -splice ${OFFSETCOL}x${OFFSETROW} -page +0+0 -crop ${TILESIZE}x${TILESIZE} ${SOURCEFILE} $MAXLEVEL/tiles_${LETTER}${NUM}_%d.${FORMAT}

      echo -n "done.  "
      if [ $KEEPFILES != 1 ]; then
        echo -n "Moving: "
      else
        echo -n "Copying: "
      fi

      #deepzoom_renametiles()

      COLSTART=$(floor "$TILECOLS_FLOAT * ($LNUM - 1)")
      COLEND=$(floor "$TILECOLS_FLOAT * $LNUM")
      ROWSTART=$(floor "$TILEROWS_FLOAT * ($NUM - 1)")
      ROWEND=$(floor "$TILEROWS_FLOAT * $NUM")
      echo "($COLSTART $ROWSTART) => ($COLEND $ROWEND) offset ($TILEOFFSETCOL $TILEOFFSETROW) ($OFFSETCOL $OFFSETROW)"

      REALTILEROWS=$(($ROWEND - $ROWSTART + $TILEOFFSETROW))
      REALTILECOLS=$(($COLEND - $COLSTART + $TILEOFFSETCOL))

      echo "($COLSTART $ROWSTART) => ($COLEND $ROWEND) = ($REALTILECOLS $REALTILEROWS), offset ($TILEOFFSETCOL $TILEOFFSETROW) ($OFFSETCOL $OFFSETROW)"

      if true; then
        for ROW in `seq 0 $(($REALTILEROWS))`; do
          for COL in `seq 0 $(($REALTILECOLS))`; do
            TILENUM=$(($ROW * ($REALTILECOLS + 1) + $COL))
            WRONGFNAME="$MAXLEVEL/tiles_${LETTER}${NUM}_${TILENUM}.$FORMAT"
            RIGHTFNAME="$MAXLEVEL/$(($COL + $COLSTART - $TILEOFFSETCOL))_$(($ROW + $ROWSTART - $TILEOFFSETROW)).${FORMAT}"
            if [ -e $RIGHTFNAME ]; then
              convert -background none -extent ${TILESIZE}x${TILESIZE} -composite $WRONGFNAME $RIGHTFNAME $RIGHTFNAME
              if [ $KEEPFILES != 1 ]; then
                rm $WRONGFNAME
              fi
              echo -n "*"
              #echo "* $(($ROW * $TILECOLS + $COL)) => $RIGHTFNAME"
            else
              if [ $KEEPFILES != 1 ]; then
                mv $WRONGFNAME $RIGHTFNAME && echo -n ' ' || echo -n !
              else
                cp $WRONGFNAME $RIGHTFNAME && echo -n ' ' || echo -n !
              fi
              echo -n $TILENUM
              #echo " $(($ROW * $TILECOLS + $COL)) => $RIGHTFNAME"
            fi
          done
        done
      fi
      echo
    else
      echo NOT FOUND
    fi
  done
done
