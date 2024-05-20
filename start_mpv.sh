#!/bin/bash

# Export necessary environment variables for X11 and VAAPI
export DISPLAY=:0
export XDG_RUNTIME_DIR=/run/user/$(id -u)

# Log file for MPV
MPV_LOG_FILE="/home/mpvuser/mpv.log"

# Function to start MPV with VAAPI hardware acceleration
start_mpv() {
    mpv --fullscreen --hwdec=vaapi --vaapi-device=/dev/dri/renderD128 --rtsp-transport=tcp --demuxer-readahead-secs=1 --demuxer-max-bytes=50000000 --demuxer-max-back-bytes=50000000 --vd-lavc-o=threads=4 $RTSP_STREAM_URL --log-file=$MPV_LOG_FILE
}

# Clean up any previous X server instances and lock files
if [ -e /tmp/.X0-lock ]; then
    sudo rm -f /tmp/.X0-lock
fi

# Check if X server is running
if ! pgrep -x "Xorg" > /dev/null; then
    # Start X11 server using xinit with authorization
    xinit /usr/bin/openbox-session -- :0 vt7 &
    XORG_PID=$!
    sleep 5
else
    echo "X server already running"
fi

# Disable screen blanking and energy saving features
xset s off
xset -dpms
xset s noblank

# Loop to continuously restart MPV
while true; do
    echo "Starting MPV..."
    start_mpv
    MPV_EXIT_CODE=$?
    
    echo "MPV exited with exit code $MPV_EXIT_CODE. Restarting in 60 seconds..."
    sleep 60
done

# Wait for Xorg to finish if it was started in this script
if [ ! -z "$XORG_PID" ]; then
    wait $XORG_PID
fi