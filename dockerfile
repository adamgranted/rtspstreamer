# Use an official Ubuntu base image
FROM ubuntu:22.04

# Set environment variables to avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install necessary packages and drivers
RUN apt-get update && apt-get install -y \
    mpv \
    xinit \
    openbox \
    x11-xserver-utils \
    xdotool \
    vainfo \
    i965-va-driver \
    intel-media-va-driver-non-free \
    libva2 \
    libva-glx2 \
    libva-drm2 \
    python3-xdg \
    sudo \
    && apt-get clean

# Add user for running MPV
RUN useradd -ms /bin/bash mpvuser && \
    echo 'mpvuser ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Copy mpv_inhibit_gnome.so to the specified directory
# Credit to https://github.com/Guldoman/mpv_inhibit_gnome
COPY mpv_inhibit_gnome.so /home/mpvuser/.config/mpv/scripts/mpv_inhibit_gnome.so

# Switch to root to copy the script and set permissions
USER root

# Create the XDG runtime directory
RUN mkdir -p /run/user/1000 && chown -R mpvuser:mpvuser /run/user/1000

# Create the Openbox menu directory and file
RUN mkdir -p /var/lib/openbox && echo '<openbox_menu><menu id="root-menu" label="Openbox 3"><item label="Terminal"><action name="Execute"><command>xterm</command></action></item></menu></openbox_menu>' > /var/lib/openbox/debian-menu.xml

# Copy the Xwrapper configuration file
COPY Xwrapper.config /etc/X11/Xwrapper.config

# Copy the startup script
COPY start_mpv.sh /home/mpvuser/start_mpv.sh

# Make the startup script executable
RUN chmod +x /home/mpvuser/start_mpv.sh

# Change ownership of the home directory to mpvuser
RUN chown -R mpvuser:mpvuser /home/mpvuser

# Switch to the new user
USER mpvuser
WORKDIR /home/mpvuser

# Run the MPV start script
CMD ["/home/mpvuser/start_mpv.sh"]

# Labels
LABEL org.opencontainers.image.source=https://github.com/adamgranted/rtspstreamer
LABEL org.opencontainers.image.description="RTSP Streamer"
LABEL org.opencontainers.image.licenses=MIT