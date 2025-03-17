#!/bin/bash

# Update system packages
sudo dnf update -y

# Install Docker
sudo dnf install -y docker
sudo systemctl enable --now docker

# Install AWS CLI (if needed)
sudo dnf install -y aws-cli

# Add ec2-user to docker group to allow docker commands without sudo
sudo usermod -aG docker ec2-user

# Validate required environment variables
if [[ -z "${ecr_repository_url}" || -z "${region}" || -z "${image_tag}" ]]; then
    echo "Error: Required environment variables (ecr_repository_url, region, image_tag) are not set."
    exit 1
fi

# Login to ECR
# shellcheck disable=SC2154
aws ecr get-login-password --region "${region}" | docker login --username AWS --password-stdin "${ecr_domain}"

# Pull Docker image from ECR
# shellcheck disable=SC2154
docker pull "${ecr_repository_url}":"${image_tag}"

# Start Docker container
docker run -d --name my-container -p 5000:5000 "${ecr_repository_url}":"${image_tag}"

# Ensure Docker container restarts on reboot
docker update --restart=always my-container
