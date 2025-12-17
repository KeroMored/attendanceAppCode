#!/bin/bash

# iOS App Store Build Script
# This script prepares and builds your Flutter app for App Store submission

echo "🍎 Starting iOS App Store Build Process..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean
flutter pub get

# Generate launcher icons
echo "📱 Generating app icons..."
dart run flutter_launcher_icons

# Generate splash screen
echo "🎨 Generating splash screen..."
dart run flutter_native_splash:create

# Build for iOS Release
echo "🔨 Building iOS release..."
flutter build ios --release --no-codesign

echo "✅ iOS build completed successfully!"
echo ""
echo "📋 Next steps for App Store submission:"
echo "1. Open ios/Runner.xcworkspace in Xcode"
echo "2. Set your development team and bundle identifier"
echo "3. Archive the app (Product → Archive)"
echo "4. Upload to App Store Connect via Xcode Organizer"
echo ""
echo "🔐 Required for submission:"
echo "- Valid Apple Developer account"
echo "- App Store Connect app configuration"
echo "- Proper code signing certificates"
echo "- App Store screenshots and metadata"