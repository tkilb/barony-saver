#!/bin/bash


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

echo $_argGameSlot
echo $_argFilesBack
echo $_argRestore

exit 0

GAME_SAVE_DIR="$HOME/.barony/savegames"

GAME_SAVE_NAME="savegame"
GAME_SAVE_EXT="baronysave"
GAME_SAVE_FILENAME="$GAME_SAVE_NAME.$GAME_SAVE_EXT"
GAME_SAVE_FILEPATH="$GAME_SAVE_DIR/$GAME_SAVE_FILENAME"

ARCHIVE_DIR="$HOME/Programs/barony-saver/archive"
CHECKSUM_PATH="$ARCHIVE_DIR/checksum.md5"

cd $GAME_SAVE_DIR

indexes=""
for fileName in $(ls "$GAME_SAVE_DIR" | grep "$GAME_SAVE_EXT"); do
    noPrefix="${fileName/$GAME_SAVE_NAME/}"
    potentialIndex="${noPrefix/.$GAME_SAVE_EXT/}"
    if [[ "$potentialIndex" =~ ^[+-]?[0-9]+$ ]]; then
        indexes="$indexes $potentialIndex"
        echo "$potentialIndex is an integer."
    fi
done

if [ "$_argRestore" == 1 ]; then
    # Restore Mode
    gameSaveFilePath="$GAME_SAVE_DIR/$GAME_SAVE_FILENAME"
    $gameSlot="$GAME_SAVE_NAME$i"
    restoreFilePath="$ARCHIVE_DIR/$(ls $ARCHIVE_DIR -r --ignore=checksum.md5 | grep $gameSlot | sed -n $_argFilesBack"p")"
    cp $restoreFilePath $gameSaveFilePath
else
    for i in $indexes; do
        # Archive Mode
        md5sum --quiet -c $CHECKSUM_PATH
        status="$?"

        if [ $status == 1 ]; then
            # Archive File and Checksum
            gameSaveFileName="$GAME_SAVE_NAME$i.$GAME_SAVE_EXT"
            gameSaveFilePath="$GAME_SAVE_DIR/$gameSaveFileName"

            timestamp=$(date +%Y-%m-%d_T%H%M)
            newArchiveFilePath="$ARCHIVE_DIR/$GAME_SAVE_NAME$i"_"$timestamp.$GAME_SAVE_EXT"

            cp $gameSaveFilePath $newArchiveFilePath
            md5sum $gameSaveFileName >$CHECKSUM_PATH
        fi
    done
fi
