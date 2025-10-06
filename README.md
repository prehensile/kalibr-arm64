# kalibr-arm64

A Docker image containing [Kalibr](https://github.com/ethz-asl/kalibr) patched and built for ARM64 platforms, with some minor quality of life enhancements [detailed below](#quality-of-life-enhancements).

## Supported platforms
Tested and verified on:
- Apple Silicon (Macbook Air M4)
- Raspberry Pi 5

It should theoretically work on other ARM64 platforms, but hasn't been tested on any yet. If you find it works on another platform, please let me know by [filing in issue on this Github repository](https://github.com/prehensile/kalibr-arm64/issues/new/choose)!

## Installation

This image can be used directly from [Docker Hub](https://hub.docker.com/r/prehensile/kalibr):

```bash
docker run -it prehensile/kalibr:arm64
```

or built from scratch using the build files supplied in this repository, as [detailed below](#building-from-scratch).

## Usage

This image can be used in exactly the same way as the Docker images described in the [Kalibr documentation](https://github.com/ethz-asl/kalibr/wiki/installation). Note that by default this ARM64 image is tagged `prehensile/kalibr:arm64` as opposed to `kalibr`. Here's the first example from the Kalibr documentation, amended to use the different image tag:

```bash
FOLDER=/path/to/your/data/on/host
xhost +local:root
docker run -it -e "DISPLAY" -e "QT_X11_NO_MITSHM=1" \
    -v "/tmp/.X11-unix:/tmp/.X11-unix:rw" \
    -v "$FOLDER:/data" prehensile/kalibr:arm64
```

Here's a more complex example, using data stored on the host machine, mapped to a volume in the Docker container:

```bash
FOLDER=/path/to/your/data/on/host
docker run --rm -ti \
  -v "$FOLDER:/data" \
  prehensile/kalibr:arm64 \ 
  rosrun kalibr kalibr_calibrate_cameras \
  --bag /data/cam_april_compressed.bag \ 
  --target /data/april_6x6.yaml \
  --models pinhole-radtan pinhole-radtan \
  --topics /cam0/image_raw /cam1/image_raw
```

## Quality of life enhancements

### Improved entrypoint script
The [entrypot script](entrypoint.sh) for this container takes care of running `source /catkin_ws/devel/setup.bash` to load the ROS environment for you, before anything passed to `docker run` is executed. This includes, for example, `bash`.

### xvfb
If you intend to use ROS / Kalibr for offline processing, you may find that some tools fail because they are expecting an X display to be available. This can be worked around using [xvfb](https://www.x.org/releases/X11R7.6/doc/man/man1/Xvfb.1.xhtml), which makes a virtual display available to processes that expect one.

xvfb is installed in this Docker image, and can be used by prefixing commands with `xfvb-run`. For example, while running a command prompt inside the container:
```
root@d2f198fb4549:/catkin_ws# xvfb-run rosrun kalibr kalibr_calibrate_cameras
```

## Building from scratch

### Dependencies
- Docker with buildx support
- git

### Requirements

The ROS / Kalibr build process which happens while building this image is resource-intensive:
- 12GB RAM or more is required. This means that it will crash out on a Raspberry Pi 5. 
- the high memory requirement means that you may need to increase Docker's memory limit on some systems (e.g. macOS)
- 4 or more CPU cores are strongly recommended. It will likely run very slowly or not at all on a single-core system.

This image was built on an Apple Macbook Air M4 with 16GB RAM and run on a Raspberry Pi 5 4GB.

#### Cross-compilation

Note that Apple M4 is an ARM64 platform: this image was built on its native architecture. Docker buildx should handle cross-compilation on other architectures (e.g. `amd64`), but buildx is also known to silently fall back to other architectures during the build process.

Be careful when building this image on architectures other than ARM64, and check that it runs as expected on your target platform. 

## Running the build script

```bash
./build.sh
```

This will:
1. Clone Kalibr as a submodule of this repository,
2. Apply Python [cv_bridge compatibility patches](patches.diff), as outlined in [this Stack Overflow answer](https://stackoverflow.com/a/79695710/284475),
3. Build an ARM64 Docker image:
   1. based on [arm64v8/ros:noetic](https://hub.docker.com/layers/arm64v8/ros/noetic/), as described in this [Raspberry Pi Forum post](https://forums.raspberrypi.com/viewtopic.php?t=388022#p2315851),
   2. tagged `kalibr:arm64` (a different tag can be specified with the `-t` flag to the `build.sh` script, for example `./build.sh -t some_tag` ),
4. Save the image to the current working directory as `kalibr-arm64.tar.gz`

## Loading the built image
To load the image on a different ARM64 system (e.g. a Raspberry Pi 5), transfer it over and then run the following command on the target:
```bash
gunzip -c kalibr-arm64.tar.gz | docker load
```
Then you can use the image as [described above](#usage).
