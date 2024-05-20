
# Containerized RTSP Streamer using X11 and MPV for Intel Graphics
I was surprised to find there's no simple way to continuously display an RTSP stream, full screen on a display. There's plenty of libraries to manage streams, transcode, etc but I found that either: A) They did more than I needed (adding bloat to an already underpowered micro pc) or B) the latency was too high.

For my use case, I'm running Frigate as my main NVR and displaying the "Birdseye" view via a restream although this guide should work for any RTSP stream that needs to be full screen. The restream already has an inherit level of latency to it so the solution needed to be as fast as possible. 

This guide is geared towards LAN use but it can easiliy be used in conjunction with Tailscale if your devices are on different WANs.

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

[I put together a version with VLC.]