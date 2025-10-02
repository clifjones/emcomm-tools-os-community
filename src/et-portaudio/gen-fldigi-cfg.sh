#!/bin/bash
# Author  : Gaston Gonzalez
# Date    : 1 October 2025
# Purpose : Temporary script to fast-fail dynamic fldigi config for PnP
#
# NOTE:
#
# THIS IS JUST USED DURING DEVELOPMENT. AN XML PARSER WILL BE USED TO MODIFY
# THE FLDIGI CONFIG FOR THE FINAL PNP SOLUTION. SO THAT USER CHANGES CAN STILL
# BE PERSISTED.

CMD=et-portaudio
PORT_AUDIO_CONF=conf.tmp
FLDIGI_CONF_FILE="${HOME}/.fldigi/fldigi_def.xml"

# clean up temporary config that may exist
[[ -e ${PORT_AUDIO_CONF} ]] && rm ${PORT_AUDIO_CONF}

[[ ! -e ${CMD} ]] && make
./${CMD} 2>/dev/null > ${PORT_AUDIO_CONF}

if [[ $? -ne 0 ]]; then
  echo "No supported ET_AUDIO device found"
  exit 1
fi

DEVICE=$(jq -r -e '.device' ${PORT_AUDIO_CONF})
if [[ $? -ne 0 ]]; then
  echo "Error getting PulseAudio device name for ET_AUDIO device"
  exit 1
fi

INDEX=$(jq -r -e '.index' ${PORT_AUDIO_CONF})
if [[ $? -ne 0 ]]; then
  echo "Error getting PulseAudio device index for ET_AUDIO device"
  exit 1
fi

et-log "Copying fldigi template..."
cp -v ../../overlay/etc/skel/.fldigi/fldigi_def.xml ~/.fldigi/

et-log "Updating PortAudio devices..."
sed -i "s|^<AUDIOIO>.*|<AUDIOIO>1</AUDIOIO>|" ${FLDIGI_CONF_FILE}

sed -i "s|^<PORTINDEVICE>.*|<PORTINDEVICE>${DEVICE}</PORTINDEVICE>|" ${FLDIGI_CONF_FILE}
sed -i "s|^<PORTININDEX>.*|<PORTININDEX>${INDEX}</PORTININDEX>|" ${FLDIGI_CONF_FILE}

sed -i "s|^<PORTOUTDEVICE>.*|<PORTOUTDEVICE>${DEVICE}</PORTOUTDEVICE>|" ${FLDIGI_CONF_FILE}
sed -i "s|^<PORTOUTINDEX>.*|<PORTOUTINDEX>${INDEX}</PORTOUTINDEX>|" ${FLDIGI_CONF_FILE}
