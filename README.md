
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
          - XDG_RUNTIME_DIR=/run/user/1000
          - RTSP_STREAM_URL=rtsp://localhost:8554  # Insert your RTSP stream URL
          - ENABLE_LOGGING=false  # Enable or disable logging for MPV
        volumes:
          - /tmp/.X11-unix:/tmp/.X11-unix:rw
          - /etc/localtime:/etc/localtime:ro
          - /dev/dri:/dev/dri
          - /run/user/1000:/run/user/1000
        network_mode: host
        devices:
          - /dev/dri:/dev/dri
        privileged: true



Or using Docker run:

    docker run --net host --name rtspstreamer -e DISPLAY=:0 -e XDG_RUNTIME_DIR=/run/user/1000 -e RTSP_STREAM_URL=rtsp://localhost:8554 -e ENABLE_LOGGING=false -v /tmp/.X11-unix:/tmp/.X11-unix:rw -v /etc/localtime:/etc/localtime:ro -v /dev/dri:/dev/dri -v /run/user/1000:/run/user/1000 --device /dev/dri:/dev/dri --privileged ghcr.io/adamgranted/rtspstreamer:latest


# Troubleshooting

1) Use the ENV flag to enable MPV logging within the container.

        - ENABLE_LOGGING=true  # Enable or disable logging for MPV

    View the logs using:

        docker exec -it rtspstreamer tail -f /home/mpvuser/mpv.log

2) Check the Docker Compose logs using:

        docker compose logs


# Not using Docker?

[I put together a bare metal guide with VLC and X11.](https://github.com/adamgranted/rtspstreamer/blob/main/BareMetal_README.md)

# Mise

- Why not VLC?
  VLC is preferred but I faced issues with it. RTSP is not supported with the apt version of VLC. Snap does support it but won't place nice with containers. Ultimately it was easier to switch to MPV instead of building VLC with the proper flags.

- Why not FFMPEG?
  Transcoding was my first route. I wanted the stream to be viewable within a browser for easier display management. The latency was terrible though, even with hardware acceleration I found my transcode time to be nearly 2 minutes by the time it was displaying in the browser. Too slow for my needs.
