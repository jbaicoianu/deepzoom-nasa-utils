#!/bin/bash

SCRIPTPATH=$(dirname "$0")

. $SCRIPTPATH/procspawn-lib.sh
. $SCRIPTPATH/deepzoom-lib.sh

FULLWIDTH=0
FULLHEIGHT=0
TILESIZE=256
MINLEVEL=6
DEBUG=0

USAGESTR="Usage: $0 [-w width] [-h height] [-s tilesize] [-b basename] [-d]"

while getopts w:h:t:m:d o
do  case "$o" in
  w)  FULLWIDTH=$OPTARG ;;
  h)  FULLHEIGHT=$OPTARG ;;
  t)  TILESIZE=$OPTARG ;;
  m)  MINLEVEL=$OPTARG ;;
  d)  DEBUG=1 ;;
  [?])  echo "$USAGESTR"
    exit 1;;
  esac
done

if [ $FULLWIDTH = 0 ] || [ $FULLHEIGHT = 0 ]; then
  echo >&2 "$USAGESTR"
  exit 1
fi

#echo $(deepzoom_combine $FULLWIDTH $FULLHEIGHT $TILESIZE)
echo $(deepzoom_maxlevel $FULLWIDTH $FULLHEIGHT)
