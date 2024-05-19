#!/bin/bash

# Export necessary environment variables for X11
export DISPLAY=:0
export XDG_RUNTIME_DIR=/run/user/$(id -u)

# Function to start VLC
start_vlc() {
    /snap/bin/vlc -I dummy rtsp://ccsmsdocker:8554/birdseye --fullscreen --no-video-title-show --no-osd --no-audio --network-caching=2000 --rtsp-tcp --codec avcodec --avcodec-hw=none --file-caching=2000 --live-caching=2000 --realrtsp-caching=2000 --log-verbose=2 --file-logging --logfile=/home/vlcuser/vlc.log
}

# Check if X server is running
if ! pgrep -x "Xorg" > /dev/null
then
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

# Loop to restart VLC if it crashes
while true; do
    echo "Starting VLC..."
    start_vlc
    VLC_EXIT_CODE=$?
    
    if [ $VLC_EXIT_CODE -eq 0 ]; then
        echo "VLC exited normally. Exiting script."
        break
    else
        echo "VLC crashed with exit code $VLC_EXIT_CODE. Restarting in 60 seconds..."
        sleep 60
    fi
done

# Wait for Xorg to finish if it was started in this script
if [ ! -z "$XORG_PID" ]; then
    wait $XORG_PID
fi
