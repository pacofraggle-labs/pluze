#!/bin/bash

shfolder=`dirname $0`
. "$shfolder/pluze_bootstrap"

pluze_load "git"

pluze_run $*
