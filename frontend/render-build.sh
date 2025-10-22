#!/usr/bin/env bash
# Exit the script if any command fails
set -o errexit

# Clone the Flutter SDK from GitHub
echo "Cloning Flutter repository..."
git clone https://github.com/flutter/flutter.git --depth 1

# Add the Flutter tool to your path
export PATH="$PATH:`pwd`/flutter/bin"

# Confirm Flutter is installed
echo "Running flutter doctor..."
flutter doctor

# Get your project's dependencies
echo "Fetching dependencies..."
flutter pub get

# Build the web app for release
echo "Building Flutter web app..."
flutter build web --release