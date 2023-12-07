#!/bin/bash
#
# Utilities for launch_webviewer.sh
#

################################################################################
## Constants
################################################################################

# Where to store data locally. Paths are with respect to the directory
# containing this script.
ROOT_SCENES_DIR="scenes"
MIPNERF360_SCENES_SUBDIR="nov_15"

# Web viewer config.
SCENE_NAME="bicycle"
QUALITY="high"
COMBINE_MODE="concat_and_sum"
VERTICAL_FOV="40.038544"
RESOLUTION="1245,825"
NEAR=0.2
USE_DISTANCE_GRID="true"
PORT=8000

################################################################################
## Functions
################################################################################

# Copies mipnerf360 scenes to local machine.
function prepare_mipnerf360_scenes() {
  local SCENES_DIR="${ROOT_SCENES_DIR}/${MIPNERF360_SCENES_SUBDIR}"

  # Move into target directory.
  mkdir -p ${SCENES_DIR}
  pushd ${SCENES_DIR}

  local CNS_ROOT_DIR="/cns/oz-d/home/nsr-moonshot/merf_v2/models/20231112_1522-mipnerf360_scenes"
  local SCENE_INFOS=(
    "bicycle;${CNS_ROOT_DIR}/0112/baked"
    "flowerbed;${CNS_ROOT_DIR}/0116/baked"
    "fulllivingroom;${CNS_ROOT_DIR}/0120/baked"
    "gardenvase;${CNS_ROOT_DIR}/0124/baked"
    "kitchencounter;${CNS_ROOT_DIR}/0128/baked"
    "kitchenlego;${CNS_ROOT_DIR}/0132/baked"
    "officebonsai;${CNS_ROOT_DIR}/0136/baked"
    "stump;${CNS_ROOT_DIR}/0140/baked"
    "treehill;${CNS_ROOT_DIR}/0144/baked"
  )
  for SCENE_INFO in ${SCENE_INFOS[@]}; do
    IFS=";" read -r -a PARSED_SCENE_INFO <<< "${SCENE_INFO}"
    local SCENE="${PARSED_SCENE_INFO[0]}"
    local CNS_URL="${PARSED_SCENE_INFO[1]}"

    if [ ! -d "./${SCENE}" ]; then
      fileutil cp -R --parallelism=100 "${CNS_URL}" "./${SCENE}"
    else
      echo "'${SCENE}' found at ${SCENES_DIR}/${SCENE}. Skipping download..."
    fi
  done

  # Return to previous directory.
  popd
}


# Installs http-server using platform-specific tools.
function install_dependencies() {
  # Check if this command exists
  command -v http-server

  # If not, install it.
  if [ $? -eq 1 ]; then
    UNAME_OUTPUTS="$(uname -s)"
    case "${UNAME_OUTPUTS}" in
        Linux*)     install_dependencies_linux;;
        Darwin*)    install_dependencies_osx;;
        *)          echo "Unrecognized platform: ${UNAME_OUTPUTS}"
    esac
    echo ${machine}
  else
    echo "http-server is already installed. Skipping installation..."
  fi
}


# Installs http-server on OSX
function install_dependencies_osx() {
  # Check if this command exists
  command -v brew

  # Install http-server
  if [ $? -eq 0 ]; then
    brew install http-server
  else
   echo "Homebrew is required to install http-server."
   exit 1
  fi
}


# Installs http-server on Linux
function install_dependencies_linux() {
  sudo apt install node-http-server node-opener
}


# Launches web viewer
function launch_webviewer() {
  local DATA_DIR="${ROOT_SCENES_DIR}/${MIPNERF360_SCENES_SUBDIR}/${SCENE_NAME}/sm_000"

  echo "Open the following link:"
  echo "Link      = http://localhost:${PORT}/"\
"?dir=${DATA_DIR}"\
"&quality=${QUALITY}"\
"&combineMode=${COMBINE_MODE}"\
"&s=${RESOLUTION}"\
"&vfovy=${VERTICAL_FOV}"\
"&useDistanceGrid=${USE_DISTANCE_GRID}"
  echo "PWD       = $(pwd)"

  # Launch server with the following arguments.
  # -c-1    : disable caching
  # --gzip  : use *.gz version of a file if possible.
  http-server $(pwd) --gzip -c-1 --port=${PORT}
}
