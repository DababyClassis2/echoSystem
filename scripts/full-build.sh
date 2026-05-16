#!/bin/bash
set -e

echo "=== Building web client ==="
cd web-client
npm install
npm run build:android
cd ..

echo "=== Building Flutter APK ==="
flutter build apk --release

echo "=== Done ==="
echo "APK: build/app/outputs/flutter-apk/app-release.apk"
