#!/bin/bash

# create_scripting_shortcuts.sh
# MultitouchStreaming

if [ "$EUID" != "0" ]
then
echo "This script needs to modify system library files. Please run with sudo."
exit 1
fi

FRAMEWORK_NAME="MultitouchStreaming"
FRAMEWORK_DIR="/AppleInternal/Library/Frameworks/${FRAMEWORK_NAME}.framework"

if ! [ -d "${FRAMEWORK_DIR}" ]
then
echo "Cannot find ${FRAMEWORK_DIR}"
exit 1
fi

FW_SCRIPTING_PATH="${FRAMEWORK_DIR}/Resources/Scripting"

# Python
PYTHON_INSTALL_PATH=`python -c "from distutils.sysconfig import get_python_lib; print get_python_lib()"`

rm -rf "${PYTHON_INSTALL_PATH}/${FRAMEWORK_NAME}"

ln -fs "${FW_SCRIPTING_PATH}/python/${FRAMEWORK_NAME}" "${PYTHON_INSTALL_PATH}/"

echo "Python libraries installed in '${PYTHON_INSTALL_PATH}'"
