 #!/bin/bash

set -e

BUILDER_NAME="kalibr-builder-arm64-$$"  # unique name using PID
TARBALL_FILE="kalibr-arm64.tar.gz"
IMAGE_TAG="kalibr:arm64"
PATCH_FILE="patches.diff"


# Parse arguments
while getopts "t:o:" opt; do
  case $opt in
    t)
      IMAGE_TAG="$OPTARG"
      ;;
    o)
      TARBALL_FILE="$OPTARG"
      ;;
    \?)
      echo "Usage: $0 [-t tag] [-o output file]" >&2
      exit 1
      ;;
  esac
done



# clone main kalibr repo and patch it
git submodule update
echo "Patching kalibr Python files to fix cv_bridge import issues..."
patch -p0 -N < $PATCH_FILE 2>/dev/null || echo "Skipped patches!"

# Create temporary builder
docker buildx create --name $BUILDER_NAME --use

# build and export
echo "Building Docker image with tag $IMAGE_TAG..." 
docker buildx build --platform linux/arm64 -t "$IMAGE_TAG" -f Dockerfile_ros1_20_04 --load .
docker save "$IMAGE_TAG" | gzip > $TARBALL_FILE

# Cleanup
docker buildx rm $BUILDER_NAME

echo "Build complete. Image saved to $TARBALL_FILE"