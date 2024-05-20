
# Containerized Full Screen RTSP Streamer
I was surprised to find there's no simple way to continuously display an RTSP stream, full screen on a display. I needed something with low latency so transcoding was not an option. This is intended to be used on devices with Intel integrated graphics.

# Installation

Deploy using Docker Compose:

version: '3.8'

services:
  mpv:
    image: ghcr.io/adamgranted/rtspstreamer:latest
    container_name: rtspstreamer
    environment:
      - DISPLAY=:0  # Set DISPLAY variable explicitly
      - XDG_RUNTIME_DIR=/run/user/1000  # Set XDG_RUNTIME_DIR explicitly
    volumes:
      - /tmp/.X11-unix:/tmp/.X11-unix:rw
      - /etc/localtime:/etc/localtime:ro
      - /dev/dri:/dev/dri  # Mount the DRI device for VAAPI
      - /run/user/1000:/run/user/1000  # Mount the XDG runtime directory
    network_mode: host
    devices:
      - /dev/dri:/dev/dri
    privileged: true  # Add this line to run the container with extended privileges


Or using Docker run:

        docker run --net host --name rtspstreamer -e DISPLAY=:0 -e XDG_RUNTIME_DIR=/run/user/1000 -v /tmp/.X11-unix:/tmp/.X11-unix:rw -v /etc/localtime:/etc/localtime:ro -v /dev/dri:/dev/dri -v /run/user/1000:/run/user/1000 --device /dev/dri:/dev/dri --privileged ghcr.io/adamgranted/rtspstreamer:latest


# Need to run on Bare Metal?

[I put together a bare metal guide with VLC and X11.](https://github.com/adamgranted/rtspstreamer/blob/main/BareMetal_README.md)