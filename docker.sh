#!/bin/bash

print_message() {
    echo "[INFO] $1"
}

check_status() {
    if [ $? -eq 0 ]; then
        print_message "Success: $1"
    else
        print_message "Warning: $1 failed. Skipping..."
    fi
}

if [ "$EUID" -ne 0 ]; then
    print_message "Error: This script must be run with sudo. Exiting..."
    exit 1
fi

LOG_FILE="/var/log/install_docker.log"
exec > >(tee -a "$LOG_FILE") 2>&1
print_message "Starting script execution. Log saved to $LOG_FILE"

print_message "Checking internet connectivity..."
if ! ping -c 1 google.com > /dev/null 2>&1; then
    print_message "Warning: No internet connection detected. Some steps may fail."
else
    print_message "Success: Internet connection verified"
fi

# Install additional packages
print_message "Installing additional packages..."
apt-get update
apt-get install -y curl openssl iptables build-essential protobuf-compiler git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev tar clang bsdmainutils ncdu unzip libleveldb-dev libclang-dev ninja-build
check_status "Additional packages installation"

if ! command -v docker &> /dev/null; then
    print_message "Docker not found. Installing Docker..."

    for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
        apt-get remove -y $pkg || true
    done
    check_status "Removal of conflicting packages"

    apt-get update
    apt-get install -y ca-certificates curl gnupg software-properties-common lsb-release
    check_status "Docker prerequisites installation"

    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    check_status "Docker GPG key setup"
    chmod a+r /etc/apt/keyrings/docker.gpg

    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs 2>/dev/null || echo 'jammy') stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null
    check_status "Docker repository setup"

    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    check_status "Docker installation"

    systemctl start docker
    systemctl enable docker
    check_status "Docker service setup"
else
    print_message "Docker already installed, skipping Docker installation"
    systemctl restart docker
    check_status "Docker service restart"
fi

print_message "Verifying Docker installation..."
if ! docker ps -a > /dev/null 2>&1; then
    print_message "Warning: Docker is installed but not working correctly. Check logs in $LOG_FILE."
else
    print_message "Success: Docker verification"
fi

if [ -n "$SUDO_USER" ]; then
    TARGET_USER="$SUDO_USER"
else
    TARGET_USER=$(logname 2>/dev/null || echo "")
    if [ -z "$TARGET_USER" ]; then
        print_message "Warning: No non-root user detected. Skipping Docker group configuration."
    fi
fi

if [ -n "$TARGET_USER" ]; then
    if ! id -nG "$TARGET_USER" | grep -q docker; then
        print_message "Adding user $TARGET_USER to docker group..."
        usermod -aG docker "$TARGET_USER"
        check_status "Adding user to docker group"
        print_message "IMPORTANT: User $TARGET_USER must log out and back in, or run 'newgrp docker' to apply group changes."
    else
        print_message "User $TARGET_USER is already in the docker group."
    fi
else
    print_message "No user specified for Docker group. Skipping Docker group configuration."
fi

if ! docker compose version > /dev/null 2>&1; then
    print_message "Docker Compose not found. Installing docker-compose-plugin..."
    apt-get install -y docker-compose-plugin
    check_status "Docker Compose installation"
else
    print_message "Docker Compose already installed, skipping."
fi

print_message "Setup complete! Docker and Docker Compose are ready."
print_message "To use Docker without sudo, log out and back in, or run 'newgrp docker' as $TARGET_USER."
print_message "Check logs in $LOG_FILE for details."
