#!/bin/bash

##################################################
### Arguments
##################################################

while getopts ":g:i:r" opt; do
  case $opt in
    g) _argGameSlot="$OPTARG"
    ;;
    i) _argFilesBack="$OPTARG"
    ;;
    r) _argRestore=1
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    exit 1
    ;;
  esac

  case $OPTARG in
    -*) echo "Option $opt needs a valid argument"
    exit 1
    ;;
  esac
done

##################################################
### Utils
##################################################
DIR_ARCHIVE="$HOME/Programs/barony-saver/archive"
DIR_SAVES="$HOME/.barony/savegames"
SAVE_PREFIX="savegame"
SAVE_EXT="baronysave"

CHECKSUM_FILE_NAME="checksum.md5"
CHECKSUM_PATH="$DIR_ARCHIVE/$CHECKSUM_FILE_NAME"

function deriveSaveFileName {
  local slot=${1:-0}
  local timestamp=$2
  local timestampDelimiter=""

  if [ -n "$timestamp" ]; then
    timestampDelimiter="_"
  fi

  echo "$SAVE_PREFIX$slot$timestampDelimiter$timestamp.$SAVE_EXT"
}

function areAllChecksumsValid {
  md5sum --quiet -c $CHECKSUM_PATH >/dev/null
  local status="$?"

  if [[ "$status" == "1" ]]; then
    echo 0
    return
  fi

  local actualSlotCount=$(ls -1 | wc -l)
  local checkSumSlotCount=$(wc -l $CHECKSUM_PATH | awk '{print $1}')
  if [[ "$actualSlotCount" != "$checkSumSlotCount" ]]; then
    echo 0
    return
  fi

  echo 1
}

##################################################
### Program
##################################################

# Set to saves directory
cd $DIR_SAVES

if [ "$_argRestore" == 1 ]; then
  ##### Restore Mode #####

  archiveFilePath="$DIR_ARCHIVE/$(ls $DIR_ARCHIVE -r --ignore=$CHECKSUM_FILE_NAME | grep $_argGameSlot | sed -n $_argFilesBack"p")"
  saveFilePath="$DIR_SAVES/$(deriveSaveFileName $_argGameSlot)"
      
  cp $archiveFilePath $saveFilePath
else
  ##### Archive Mode #####

  # Determine Indexes
  slots=""
  for fileName in $(ls "$DIR_SAVES" | grep "$SAVE_EXT"); do
    noPrefix="${fileName/$SAVE_PREFIX/}"
    potentialIndex="${noPrefix/.$SAVE_EXT/}"
    if [[ "$potentialIndex" =~ ^[+-]?[0-9]+$ ]]; then
        slots="$slots $potentialIndex"
    fi
  done

  # Loop and archive if checksum fails
  if [[ $(areAllChecksumsValid) == 0 ]]; then
    for slot in $slots; do
      saveFileName="$(deriveSaveFileName $slot)"
      existingHash=$(cat $CHECKSUM_PATH | grep $saveFileName | awk '{print $1}')

      [[ "$(md5sum < $saveFileName)" = "$existingHash  -" ]] && isCheckValid=1 || isCheckValid=0

      if [ $isCheckValid == 0 ]; then
        # Archive file, set new checksum
        timestamp=$(date +%Y-%m-%d_T%H%M)
        
        saveFilePath="$DIR_SAVES/$saveFileName"
        archiveFilePath="$DIR_ARCHIVE/$(deriveSaveFileName $slot $timestamp)"

        mkdir -p $DIR_ARCHIVE
        cp $saveFilePath $archiveFilePath
      fi
    done

    # Create new checksum
    md5sum * >$CHECKSUM_PATH
  fi
fi