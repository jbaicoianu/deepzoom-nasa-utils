#!/bin/bash

SCRIPTPATH=$(dirname "$0")

. $SCRIPTPATH/procspawn-lib.sh
. $SCRIPTPATH/deepzoom-lib.sh

FULLWIDTH=0
FULLHEIGHT=0
TILESIZE=256
MINLEVEL=6
export DEEPZOOMDEBUG=0

USAGESTR="Usage: $0 [-w width] [-h height] [-s tilesize] [-b basename] [-d] command"

while getopts w:h:s:m:d o
do  case "$o" in
  w)  FULLWIDTH=$OPTARG ;;  # full image width
  h)  FULLHEIGHT=$OPTARG ;; # full image height
  s)  TILESIZE=$OPTARG ;;   # tile size
  m)  MINLEVEL=$OPTARG ;;   # minimum deepzoom level
  d)  export DEEPZOOMDEBUG=1 ;; # debug
  [?])  echo "$USAGESTR"
    exit 1;;
  esac
done
shift $(($OPTIND-1))

if [ $FULLWIDTH = 0 ] || [ $FULLHEIGHT = 0 ]; then
  echo >&2 "$USAGESTR"
  exit 1
fi

COMMAND=$1

case "$COMMAND" in
  maxlevel)
    deepzoom_maxlevel $FULLWIDTH $FULLHEIGHT
    ;;
  split)
    FILENAME=$2
    deepzoom_split $FULLWIDTH $FULLHEIGHT $TILESIZE $FILENAME
    ;;
  rename)
    FILEPATH=$2
    [ -z "$FILEPATH" ] && FILEPATH="."
    COLS=$(ceil "$FULLWIDTH / $TILESIZE")
    ROWS=$(ceil "$FULLHEIGHT / $TILESIZE")
    deepzoom_rename $FILEPATH $ROWS $COLS "png"
    ;;
  combine)
    FILEPATH=$2
    [ -z "$FILEPATH" ] && FILEPATH="."
    deepzoom_combine $FILEPATH $FULLWIDTH $FULLHEIGHT $TILESIZE
    ;;
  descriptor)
    FILENAME=$2
    [ -z "$FILENAME" ] && FILENAME="-"
    deepzoom_descriptor $FILENAME $FULLWIDTH $FULLHEIGHT $TILESIZE
    ;;
esac

