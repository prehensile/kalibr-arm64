 #!/bin/bash

set -e

BUILDER_NAME="kalibr-builder-arm64-$$"  # unique name using PID
TARBALL_FILE="kalibr-arm64.tar.gz"

# clone main kalibr repo and patch it
git submodule update 
patch < patches.diff

# Create temporary builder
docker buildx create --name $BUILDER_NAME --use

# build and export
docker buildx build --platform linux/arm64 -t kalibr:arm64 -f Dockerfile_ros1_20_04 --load .
docker save kalibr:arm64 | gzip > $TARBALL_FILE

# Cleanup
docker buildx rm $BUILDER_NAME

echo "Build complete. Image saved to $TARBALL_FILE"