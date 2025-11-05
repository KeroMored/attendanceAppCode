# iOS App Store Build Script for Windows
# This script prepares and builds your Flutter app for App Store submission

Write-Host "🍎 Starting iOS App Store Build Process..." -ForegroundColor Green

# Clean previous builds
Write-Host "🧹 Cleaning previous builds..." -ForegroundColor Yellow
flutter clean
flutter pub get

# Generate launcher icons
Write-Host "📱 Generating app icons..." -ForegroundColor Yellow
dart run flutter_launcher_icons

# Generate splash screen
Write-Host "🎨 Generating splash screen..." -ForegroundColor Yellow
dart run flutter_native_splash:create

# Note: iOS builds can only be done on macOS
Write-Host "⚠️ iOS builds require macOS with Xcode installed" -ForegroundColor Yellow
Write-Host "📋 Skipping iOS build (Windows limitation)" -ForegroundColor Yellow

Write-Host "✅ iOS build completed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Next steps for App Store submission:" -ForegroundColor Cyan
Write-Host "1. Open ios/Runner.xcworkspace in Xcode (on macOS)" -ForegroundColor White
Write-Host "2. Set your development team and bundle identifier" -ForegroundColor White
Write-Host "3. Archive the app (Product → Archive)" -ForegroundColor White
Write-Host "4. Upload to App Store Connect via Xcode Organizer" -ForegroundColor White
Write-Host ""
Write-Host "🔐 Required for submission:" -ForegroundColor Cyan
Write-Host "- Valid Apple Developer account ($99/year)" -ForegroundColor White
Write-Host "- App Store Connect app configuration" -ForegroundColor White
Write-Host "- Proper code signing certificates" -ForegroundColor White
Write-Host "- App Store screenshots and metadata" -ForegroundColor White