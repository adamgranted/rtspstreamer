# Use an official Ubuntu base image
FROM ubuntu:22.04

# Set environment variables to avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install necessary packages
RUN apt-get update && apt-get install -y \
    snapd \
    x11-xserver-utils \
    openbox \
    python3-xdg \
    --no-install-recommends

# Enable and start snapd service
RUN systemctl enable snapd
RUN systemctl start snapd

# Install VLC from Snap
RUN snap install core
RUN snap install vlc

# Remove default VLC package and related packages
RUN apt-get purge -y vlc vlc-data vlc-bin vlc-plugin-base vlc-plugin-qt vlc-plugin-video-output vlc-l10n && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get autoremove -y && \
    apt-get clean

# Add user for running VLC
RUN useradd -ms /bin/bash vlcuser

# Set environment variables for Snap
ENV PATH="/snap/bin:$PATH"

# Switch to the new user
USER vlcuser
WORKDIR /home/vlcuser

# Copy the startup script
COPY start_vlc.sh .

# Make the startup script executable
RUN chmod +x start_vlc.sh

# Run the startup script
CMD ["./start_vlc.sh"]