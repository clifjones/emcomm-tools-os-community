#!/bin/bash
#
# Author  : Gaston Gonzalez
# Date    : 23 May 2023
# Updated : 16 August 2025
# Purpose : Offline HF prediction using voacapl

if [[ $# -ne 4 ]]; then
  echo "Usage $(basename $0) <callsign1> <callsign2> <power> <mode>"
  echo "  <callsign1>   Callsign of transmitting station"
  echo "  <callsign2>   Callsign of receiving station"
  echo "  <power>       Output power [5|100|500|1500]"
  echo "  <mode>        Mode         [AM|CW|FT8|SSB]"
  exit 1
fi

ET_SSN="${HOME}/.local/share/emcomm-tools/voacap/ssn.txt"
if [[ ! -e ${ET_SSN} ]]; then
  "Sunspot numbers not available: ${ET_SSN}. Exiting"
  exit 1
fi

ET_VOA_WORKING_DIR=$HOME/itshfbc/run
ET_VOA_REPORT=${ET_VOA_WORKING_DIR}/voacapl.txt
INP=${ET_VOA_WORKING_DIR}/voacapx.dat
OUT=${ET_VOA_WORKING_DIR}/voacapx.out

# Year = 2023
YEAR=$(echo $(date '+%Y'))

# Month (May) = 5.00
MONTH=$(date +'%m')
MONTH_FMT=$(date +'%-m.00')

#######################################################################
# TX Antenna
#######################################################################

TX_STATION=$1
TX_JSON=tx-station.json
curl -f -s http://localhost:1981/api/license?callsign=$TX_STATION > $TX_JSON
TL=$(cat $TX_JSON | jq .lat)
TK=$(cat $TX_JSON | jq .lon)

TL1=$( awk -v n1=$TL -v n2=90 -v n3=-90 'BEGIN {if (n1<n3 || n1>n2) printf ("%s", "a"); else printf ("%.2f", n1);}' )

# add North or South (N/S)
TLA=$( awk -v n1=$TL1 -v n2=0 'BEGIN {if (n1<n2) { n1=substr(n1,2); printf ("%6sS", n1); } else printf ("%6sN", n1);}' )

TK1=$( awk -v n1=$TK -v n2=180 -v n3=-180 'BEGIN {if (n1<n3 || n1>n2) printf ("%s", "a"); else printf ("%.2f", n1);}' )
		    
# add East or West (E/W)
TLO=$( awk -v n1=$TK1 -v n2=0 'BEGIN {if (n1<n2) { n1=substr(n1,2); printf ("%7sW", n1); } else printf ("%7sE", n1);}' )


#######################################################################
# RX Antenna
#######################################################################

RX_STATION=$2
RX_JSON=rx-station.json
curl -f -s http://localhost:1981/api/license?callsign=$RX_STATION > $RX_JSON
RL=$(cat $RX_JSON | jq .lat)
RK=$(cat $RX_JSON | jq .lon)

echo "RX ($RX_STATION):  $RL,$RK"
RL1=$( awk -v n1=$RL -v n2=90 -v n3=-90 'BEGIN {if (n1<n3 || n1>n2) printf ("%s", "a"); else printf ("%.2f", n1);}' )

# add North or South
RLA=$( awk -v n1=$RL1 -v n2=0 'BEGIN {if (n1<n2) { n1=substr(n1,2); printf ("%6sS", n1); } else printf ("%6sN", n1);}' )

RK1=$( awk -v n1=$RK -v n2=180 -v n3=-180 'BEGIN {if (n1<n3 || n1>n2) printf ("%s", "a"); else printf ("%.2f", n1);}' )

# add East or West
RLO=$( awk -v n1=$RK1 -v n2=0 'BEGIN {if (n1<n2) { n1=substr(n1,2); printf ("%7sW", n1); } else printf ("%7sE", n1);}' )

# Power settings
PWR=$3
PW="0.0800"
echo "TX Power: ${PWR} watts"
if [ "$PWR" = "5" ]; then
    PW="0.0040"
elif [ "$PWR" = "100" ]; then
    PW="0.0800"
elif [ "$PWR" = "500" ]; then
    PW="0.4000"
elif [ "$PWR" = "1500" ]; then
    PW="1.2000"
fi

# Mode
MODE=$4
MD="24.0"
echo "Mode: ${MODE}"
if [ "$MODE" = "FT8" ]; then
    MD="13.0"
elif [ "$MODE" = "CW" ]; then
    MD="24.0"
elif [ "$MODE" = "SSB" ]; then
    MD="38.0"
elif [ "$opt" = "AM" ]; then
    MD="49.0"
fi

# Format for 117
# NOTE: The card requires <SSN>. (117.)
ssn=`grep "$YEAR $MONTH" ${ET_SSN} | awk '{print $5}' | cut -d"." -f1`

# read more about fine-tuning your input file:
# http://www.voacap.com/voacapw.html
# http://www.voacap.com/frequency.html

echo -e "\n"

cat << END | tee $INP
LINEMAX     999       number of lines-per-page
COEFFS    CCIR
TIME          1   24    1    1
MONTH      $YEAR $MONTH_FMT
SUNSPOT    $ssn.
LABEL     $TX$RX
CIRCUIT  $TLA  $TLO   $RLA  $RLO  S     0
SYSTEM       1. 155. 3.00  90. $MD 3.00 0.10
FPROB      1.00 1.00 1.00 0.00
ANTENNA       1    1    2   30     0.000[samples/sample.00    ]  0.0    $PW
ANTENNA       2    2    2   30     0.000[samples/sample.00    ]  0.0    0.0000
FREQUENCY  3.60 5.30 7.1010.1014.1018.1021.1024.9028.20 0.00 0.00
METHOD       30    0
BOTLINES      8   12   21
TOPLINES      1    2    3    4    6
EXECUTE
QUIT

END

voacapl -s ~/itshfbc
echo "voacapl exited with $? using in=$INP and out=$OUT"

(tail -n +27 $OUT | head -n 5 &&  grep -e'-  REL' $OUT && grep -e'-  S DBW' $OUT) | ./rel.pl > ${ET_VOA_REPORT}
cat ${ET_VOA_REPORT}
