
# Bare Metal RTSP Streamer using X11 and VLC
Don't need the containerized version? You can do it on bare metal using with VLC. This is a relatively comprehensive guide but it assumes you have some understanding of shell.

This guide may be behind the containerized version but I'll try to keep it up to date.

# Environment
 - OS: Ubuntu 24.04 LTS
 - Hardware: Beelink T5 Mini PC, Celeron N4020
 - [Snap version of VLC](https://snapcraft.io/install/vlc/ubuntu) (more on this below)

# How To

 1) Install Ubuntu, ensuring to expand the file system. Enable SSH and setup your user account. After reboot, login accordingly (SSH or otherwise).
 2) First we need to purge Ubuntu of the pre-packaged VLC as it [does not support RTSP streaming after 21.04](https://forum.videolan.org/viewtopic.php?f=13&t=158071&p=520527). 

        sudo apt purge vlc
        sudo apt purge vlc-data
        sudo apt purge vlc-bin
        sudo apt purge vlc-plugin-base
        sudo apt purge vlc-plugin-qt
        sudo apt purge vlc-plugin-video-output
        sudo apt purge vlc-l10n
    
3) Ensure Ubuntu Frame is disabled as it will interfere with X11:

        sudo systemctl stop snap.ubuntu-frame.daemon
        sudo systemctl disable snap.ubuntu-frame.daemon

5) Remove any remaining dependencies.

        sudo apt autoremove
    
6) Clean the package cache
 
        sudo apt clean

7) Install VLC via snap

         sudo snap install vlc
    
8) Install X11, Openbox, and related dependencies.

        sudo apt update
        sudo apt install xorg openbox
        sudo apt install python3-xdg
        sudo apt install x11-xserver-utils
        sudo apt install mesa-va-drivers

9) Configure Xorg for Non-Root Users
    
        sudo nano /etc/X11/Xwrapper.config

    Add or Modify the following:
   
        allowed_users=anybody
        needs_root_rights=yes

10) We need to create a valid menu file for Openbox

        sudo mkdir -p /var/lib/openbox
        sudo nano /var/lib/openbox/debian-menu.xml

    Add the following XML:

        <openbox_menu>
          <menu id="root-menu" label="Openbox 3">
            <item label="Terminal">
              <action name="Execute">
                <command>xterm</command>
              </action>
            </item>
            <item label="Restart">
              <action name="Restart"/>
            </item>
            <item label="Exit">
              <action name="Exit"/>
            </item>
          </menu>
        </openbox_menu>

11) Create a VLC startup script:

        nano ~/start_vlc.sh

    Add the following:

        #!/bin/bash
        
        # Export necessary environment variables for X11
        export DISPLAY=:0
        export XDG_RUNTIME_DIR=/run/user/$(id -u)
        
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
        
        # OPTIONAL Disable screen blanking and energy saving features
        # xset s off          # Don't activate screensaver
        # xset -dpms          # Disable DPMS (Energy Star) features
        # xset s noblank      # Don't blank the video device
        # setterm -blank 0 -powerdown 0
        
        # Start VLC with the desired options
        # Replace localhost with your RTSP stream
        /snap/bin/vlc -I dummy rtsp://ccsmsdocker:8554/birdseye --fullscreen --no-video-title-show --no-osd --no-audio --network-caching=2000 --rtsp-tcp --codec avcodec --avcodec-hw=none --file-caching=2000 --live-caching=2000 --realrtsp-caching=2000 --no-audio


        # Wait for VLC to finish if Xorg was started in this script
        if [ ! -z "$XORG_PID" ]; then
                wait $XORG_PID
        fi

    Make the script executable:

        chmod +x ~/start_vlc.sh

13) Create a systemd service in the user's home directory so VLC is not started as root:

        mkdir -p ~/.config/systemd/user/
        nano ~/.config/systemd/user/vlc.service

    Add the following to the service file ensuring to replace "your_username" with your user:

        [Unit]
        Description=VLC media player
        After=network.target
        
        [Service]
        ExecStart=/home/your_username/start_vlc.sh
        Restart=always
        RestartSec=5s
        StartLimitBurst=5
        StartLimitIntervalSec=60
        Environment=DISPLAY=:0
        Environment=XDG_RUNTIME_DIR=/run/user/%U
        
        [Install]
        WantedBy=default.target

    Enable and start the service:

        systemctl --user daemon-reload
        systemctl --user enable vlc.service
        systemctl --user start vlc.service

    Enable lingering to ensure that the user services start at boot regardless of login status. Replace "your_username" with your user:

        sudo loginctl enable-linger your_username

14) Reboot the system. If configured properly you should see the device load in the stream and display it on full screen after boot up.
   

# Testing the Script

If you're having issues after reboot, you can troubleshoot the script by manually starting it with

        ~/start_vlc.sh

# Troubleshooting

- It may not be necessary for you but I found my user was lacking access to /dev/tty0. To enable:

        sudo usermod -aG tty your_username

- You may need to ensure that your user has proper permissions to start Xserver and access the display:

        sudo usermod -aG video,input your_username

- Latency issues? You can play with the VLC flags within the ~/start_vlc.sh script. Expirement accordingly, you may need all, some, none, or a revised caching times.

        --network-caching=1000
        --rtsp-tcp
        --no-hw-decoding
        --codec avcodec
        --avcodec-hw=none
        --file-caching=2000
        --live-caching=2000
        --realrtsp-caching=2000
        --no-audio

- Still having issues? Check the VLC logs with the following command:

        journalctl --user -u vlc.service

- Still still having issues? Godspeed. Try using htop to see if your device is running low on resources:

        sudo apt-get install htop
        htop

# Misc
- Why not Wayland?

  This started out with Wayland with the intention to run Ubuntu Frame. Turns out VLC does not have a connector for Wayland. After trying and failing with Xwayland to add a compatibility layer, I ended up on X11. X11 is natively supported as a connector with VLC making it much easier to get it playing together.

- Why not [RTSP2Web](https://github.com/deepch/RTSPtoWeb)?

  I did try it. It's a great project and technically should do what I need but I found with what little resources this micro PC has, the stream was not working well within Wayland and it's Chromium view. Furthermore it just has far more than I needed. I already have Frigate as my NVR, I just need a way to distribute the view.

- Why VLC and not just through a browser?

  This was the preferred solution originally. At the time of writing this, no modern browsers directly supports an RTSP feed. I ran assorted tests using FFMPEG to transcode RTSP to M3U8 so I could play the stream using html5. The result was terrible latency. Even worse, while the stream worked on my desktop, the Beelink I'm using for the display wouldn't even attempt to play it via Chromium in Kiosk mode under Wayland.

- Enable VLC Logging with the following flags:

        -log-verbose=2 --file-logging --logfile=/home/vlcuser/vlc.log


