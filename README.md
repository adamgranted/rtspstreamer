
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

        docker run --net host --name rtspstreamer -e DISPLAY=:0 -e XDG_RUNTIME_DIR=/run/user/1000 -v /tmp/.X11-unix:/tmp/.X11-unix:rw -v /etc/localtime:/etc/localtime:ro -v /dev/dri:/dev/dri -v /run/user/1000:/run/user/1000 --device /dev/dri:/dev/dri --privileged ghcr.io/adamgranted/rtspstreamer:latest



# Need to run on bare metal?

[I put together a guide with VLC and X11.](https://github.com/adamgranted/rtspstreamer/blob/main/BareMetal_README.md)

# Troubleshooting

- I set up an ENV flag to easily enable MPV logging within the container. Set the flag to true as needed.

        - ENABLE_LOGGING=false  # Enable or disable logging for MPV

View the logs using:

        docker exec -it rtspstreamer tail -f /home/mpvuser/mpv.log

- Check the Docker Compose logs using:

        docker compose logs


