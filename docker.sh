#!/bin/bash

# Define helper functions
print_message() {
    echo "[INFO] $1"
}

check_status() {
    if [ $? -eq 0 ]; then
        print_message "Success: $1"
    else
        print_message "Error: $1 failed. Exiting..."
        exit 1
    fi
}

# Install additional packages
print_message "Installing additional packages..."
sudo apt update
sudo apt install -y curl openssl iptables build-essential protobuf-compiler git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev tar clang bsdmainutils ncdu unzip libleveldb-dev libclang-dev ninja-build
check_status "Additional packages installation"

# Install Docker if not already installed
if ! command -v docker &> /dev/null; then
    print_message "Docker not found. Installing Docker..."
    
    # Remove any conflicting packages
    for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
        sudo apt remove -y $pkg || true
    done
    check_status "Removal of conflicting packages"

    # Install prerequisites
    sudo apt install -y ca-certificates curl gnupg software-properties-common
    check_status "Docker prerequisites installation"

    # Add Docker’s GPG key with error checking
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    check_status "Docker GPG key setup"
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    # Add Docker repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    check_status "Docker repository setup"

    # Update and install Docker
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    check_status "Docker installation"

    # Start and enable Docker service
    sudo systemctl start docker
    sudo systemctl enable docker
    check_status "Docker service setup"
else
    print_message "Docker already installed, skipping Docker installation"
    # Ensure Docker service is running
    sudo systemctl restart docker
fi

# Verify Docker is working
print_message "Verifying Docker installation..."
if ! docker ps -a > /dev/null 2>&1; then
    print_message "Error: Docker is installed but not working correctly."
    exit 1
fi
check_status "Docker verification"

# Add current user to docker group if not already added
if [ -z "$SUDO_USER" ]; then
    print_message "Error: SUDO_USER is not set. Please run the script with sudo."
    exit 1
fi
if ! groups "$SUDO_USER" | grep -q docker; then
    print_message "Adding user $SUDO_USER to docker group..."
    sudo usermod -aG docker "$SUDO_USER"
    check_status "Adding user to docker group"
    print_message "IMPORTANT: Log out and back in to your VPS, or run 'newgrp docker' in the current session to apply group changes."
else
    print_message "User $SUDO_USER is already in the docker group."
fi

# Optional: Verify Docker Compose (if you want to ensure it's installed)
if ! command -v docker-compose &> /dev/null; then
    print_message "Docker Compose not found. Installing docker-compose-plugin..."
    sudo apt install -y docker-compose-plugin
    check_status "Docker Compose installation"
else
    print_message "Docker Compose already installed, skipping."
fi

print_message "Setup complete! Docker and additional tools are ready."