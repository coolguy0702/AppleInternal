#!/bin/sh
#
# script to move coreduet_resources to the unit test bundle, while at the same time
# shifting the timestamps in the database
#

RESOURCES_FLDR="${BUILT_PRODUCTS_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
COREDUET_FLDR="$RESOURCES_FLDR/CoreDuet"
TARBALL_FLDR="$RESOURCES_FLDR/coreduet_resources"

SHIFT_DBS="$RESOURCES_FLDR/coreduet_resources/shiftdbs.sh"

if [ ${PLATFORM_NAME} != "watchos" ]; then

	echo "Shifting database from $TARBALL_FLDR into $RESOURCES_FLDR"

	mkdir -p "$COREDUET_FLDR"

	"$SHIFT_DBS" "$TARBALL_FLDR" "$RESOURCES_FLDR"

	echo "Removing empty files from $COREDUET_FLDR"

	find "$COREDUET_FLDR" -empty -type f -delete

fi

echo "Removing $TARBALL_FLDR"

rm -rf "$TARBALL_FLDR"
