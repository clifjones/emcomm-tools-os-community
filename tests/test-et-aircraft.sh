#!/bin/bash
# Author   : Gaston Gonzalez
# Date     : 9 July 2025
# Purpose  : Test et-aircraft installation

OUT=$(which et-aircraft && which et-aircraft-app)
exit $?
