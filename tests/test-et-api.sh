#!/bin/bash
# Author   : Gaston Gonzalez
# Date     : 13 August 2025
# Purpose  : Test et-api installation

OUT=$(ls /opt/emcomm-tools-api/bin/et-api 2>/dev/null)
exit $?
