#!/bin/bash

# Helper script to verify entitlements are properly configured

echo "Checking ZeroDevCleaner entitlements configuration..."
echo ""

# Check if entitlements file exists
if [ -f "ZeroDevCleaner/ZeroDevCleaner.entitlements" ]; then
    echo "✅ Entitlements file exists"
    echo "   Location: ZeroDevCleaner/ZeroDevCleaner.entitlements"
else
    echo "❌ Entitlements file NOT found"
    exit 1
fi

echo ""
echo "Entitlements content:"
echo "---"
cat ZeroDevCleaner/ZeroDevCleaner.entitlements
echo "---"
echo ""

# Check build settings
echo "Checking if entitlements are configured in Xcode project..."
if grep -q "CODE_SIGN_ENTITLEMENTS" ZeroDevCleaner.xcodeproj/project.pbxproj; then
    echo "✅ CODE_SIGN_ENTITLEMENTS found in project"
    echo "   Value:"
    grep "CODE_SIGN_ENTITLEMENTS" ZeroDevCleaner.xcodeproj/project.pbxproj | head -1
else
    echo "⚠️  CODE_SIGN_ENTITLEMENTS not yet configured"
    echo "   You need to add it in Xcode Build Settings"
    echo ""
    echo "Steps:"
    echo "1. Open ZeroDevCleaner.xcodeproj in Xcode"
    echo "2. Click project → ZeroDevCleaner target → Build Settings"
    echo "3. Search for 'Code Signing Entitlements'"
    echo "4. Set to: ZeroDevCleaner/ZeroDevCleaner.entitlements"
fi

echo ""
echo "After configuring entitlements:"
echo "1. Clean Build Folder (⇧⌘K)"
echo "2. Rebuild (⌘B)"
echo "3. Run and test file deletion"
