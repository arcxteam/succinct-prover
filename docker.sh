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

exec > >(tee -a /root/install_docker.log) 2>&1
print_message "Starting script execution. Log saved to /root/install_docker.log"

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

# Install Docker if not already installed
if ! command -v docker &> /dev/null; then
    print_message "Docker not found. Installing Docker..."
    
    for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
        apt-get remove -y $pkg || true
    done
    check_status "Removal of conflicting packages"

    # Install prerequisites
    apt-get install -y ca-certificates curl gnupg software-properties-common lsb-release
    check_status "Docker prerequisites installation"

    # Add Docker’s GPG key with error checking
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    check_status "Docker GPG key setup"
    chmod a+r /etc/apt/keyrings/docker.gpg

    # Add Docker repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs 2>/dev/null || echo 'jammy') stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null
    check_status "Docker repository setup"

    # Update and install Docker
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    check_status "Docker installation"

    # Start and enable Docker service
    systemctl start docker
    systemctl enable docker
    check_status "Docker service setup"
else
    print_message "Docker already installed, skipping Docker installation"
    systemctl restart docker
    check_status "Docker service restart"
fi

# Verify Docker is working
print_message "Verifying Docker installation..."
if ! docker ps -a > /dev/null 2>&1; then
    print_message "Warning: Docker is installed but not working correctly. Skipping verification."
else
    print_message "Success: Docker verification"
fi

# Handle user for Docker group
if [ -n "$SUDO_USER" ]; then
    TARGET_USER="$SUDO_USER"
elif [ -n "$DOCKER_USER" ]; then
    TARGET_USER="$DOCKER_USER"
else
    TARGET_USER=$(logname 2>/dev/null || echo "")
    if [ -z "$TARGET_USER" ]; then
        print_message "Warning: No non-root user detected. Skipping Docker group configuration."
    fi
fi

# Add user to docker group if applicable
if [ -n "$TARGET_USER" ]; then
    if ! id -nG "$TARGET_USER" | grep -q docker; then
        print_message "Adding user $TARGET_USER to docker group..."
        usermod -aG docker "$TARGET_USER"
        check_status "Adding user to docker group"
        print_message "IMPORTANT: Log out and back in, or run 'newgrp docker' as $TARGET_USER to apply group changes."
    else
        print_message "User $TARGET_USER is already in the docker group."
    fi
else
    print_message "No user specified for Docker group. Skipping Docker group configuration."
fi

# Optional: Verify Docker Compose
if ! docker compose version > /dev/null 2>&1; then
    print_message "Docker Compose not found. Installing docker-compose-plugin..."
    apt-get install -y docker-compose-plugin
    check_status "Docker Compose installation"
else
    print_message "Docker Compose already installed, skipping."
fi

print_message "Setup complete! Docker and additional tools are ready."