#!/bin/bash
set -e

# When a user runs a command we will run this code before theirs
# This will allow for using the manual focal length if it fails to init
# https://github.com/ethz-asl/kalibr/pull/346

export KALIBR_MANUAL_FOCAL_LENGTH_INIT=1
cd /catkin_ws
source /catkin_ws/devel/setup.bash

exec "$@"