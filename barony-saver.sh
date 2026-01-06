#!/bin/bash

_argRestore=${1}
_argFilesBack=${2:-1}

GAME_SAVE_DIR="$HOME/.barony/savegames"

GAME_SAVE_NAME="savegame0"
GAME_SAVE_EXT="baronysave"
GAME_SAVE_FILENAME="$GAME_SAVE_NAME.$GAME_SAVE_EXT"
GAME_SAVE_FILEPATH="$GAME_SAVE_DIR/$GAME_SAVE_FILENAME"

ARCHIVE_DIR="$HOME/Programs/barony-saver/archive"
CHECKSUM_PATH="$ARCHIVE_DIR/checksum.md5"

cd $GAME_SAVE_DIR

if [ "$_argRestore" == "-r" ]; then
    # Restore Mode
    restoreFilePath="$ARCHIVE_DIR/$(ls $ARCHIVE_DIR -r --ignore=checksum.md5 | sed -n $_argFilesBack"p")"
    cp $restoreFilePath $GAME_SAVE_FILEPATH
else
    # Archive Mode
    md5sum --quiet -c $CHECKSUM_PATH
    status="$?"

    if [ $status == 1 ]; then
        # Archive File and Checksum
        timestamp=$(date +%Y-%m-%d_T%H%M)
        newArchiveFilePath="$ARCHIVE_DIR/$GAME_SAVE_NAME"_"$timestamp.$GAME_SAVE_EXT"

        cp $GAME_SAVE_FILEPATH $newArchiveFilePath
        md5sum $GAME_SAVE_FILENAME >$CHECKSUM_PATH
    fi
fi
