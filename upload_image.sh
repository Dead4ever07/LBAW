#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# LBAW Laravel Image Build & Upload Script
#
# Purpose:
#   - Installs PHP dependencies (via Composer + Artisan)
#   - Builds a multi-architecture Docker image (amd64 + arm64)
#   - Pushes the image to GitLab’s Container Registry
#
# Usage:
#   1. Make sure you are logged in: docker login gitlab.up.pt:5050
#   2. Update IMAGE_NAME with your group’s registry path
#   3. Run: ./upload_image.sh
#
# Notes:
#   - Fails immediately on errors (set -euo pipefail)
#   - Uses ./Dockerfile to define the build
#   - Requires Docker Buildx to be enabled
# -----------------------------------------------------------------------------

# Stop execution if a step fails
set -euo pipefail

# Replace with your group's image name
IMAGE_NAME=gitlab.up.pt:5050/lbaw/lbawYYYY/lbawYYXX

# Ensure that dependencies are available
composer install
php artisan config:clear
php artisan clear-compiled
php artisan optimize

# Build & push image
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --push \
  -t "$IMAGE_NAME" \
  .
