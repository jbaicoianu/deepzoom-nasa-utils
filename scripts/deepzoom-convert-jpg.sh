#!/bin/bash

. ~/procspawn-lib.sh

DIRNAME="."
[ ! -z $1 ] && DIRNAME=$1

for I in `find ${DIRNAME} -name "*.png"`; do
  procspawn_queue "convert $I ${I/png/jpg} && echo -n ."; 
done
procspawn_start 4
echo done
