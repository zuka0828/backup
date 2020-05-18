#!/bin/sh

SRC_DIR=${HOME}/data
DST_DIR=${HOME}/backup
EXCLUDES=" \
	--exclude=lost+found \
	--exclude=.Trash* \
	--exclude=NOSYNC \
"

LOG=./backup_$(date +"%Y-%m%d-%H%M%S").log
# Temporal file to check deleted files
DRYRUN_OUT=./backup_dryrun.out

RSYNC_ARGS="-avP --delete ${EXCLUDES} --log-file=${LOG} ${SRC_DIR}/ ${DST_DIR}/"

die() {
	echo "ERROR: ${@}"
	exit 1
}

# Check the directories
if [ ! -d ${SRC_DIR} ]; then
	die "${SRC_DIR} not found"
fi
if [ ! -d ${DST_DIR} ]; then
	die "${DST_DIR} not found"
fi

echo "Source directory: ${SRC_DIR}"
echo "Destination directory: ${DST_DIR}"
echo "Command: rsync ${RSYNC_ARGS}"

# Dry-run to check deleted files
echo "Running dry-run..."
if ! rsync -n ${RSYNC_ARGS} --log-file="" > ${DRYRUN_OUT}; then
	die "rsync (dry-run) failed"
fi
echo "Done"
# Unfortunately, deleted files are not printed in the log file
# when the dry-run is enabled (-n). Need to check stdout.
if grep -q "^deleting " ${DRYRUN_OUT}; then
	printf "\033[31m"
	echo "NOTE: The following files will be DELETED:"
	grep "^deleting " ${DRYRUN_OUT} | sed "s@^deleting \(.*\)@  \1@"
	printf "\033[m"
else
	echo "NOTE: No file will be DELETED"
fi
echo "(You can check the dry-run output: ${DRYRUN_OUT})"

# Confirmation
echo -n "Are you sure? [y/n]: "
read answer
rm -f ${DRYRUN_OUT}
if [ "${answer}" != "y" ]; then
	die "Abort"
fi

# Sync
if ! rsync ${RSYNC_ARGS}; then
	die "rsync failed"
fi

echo "Done"
