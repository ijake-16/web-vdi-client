#!/bin/bash

# Setup script for integrating IronRDP with React Web VDI Client
# Run this script from the web-vdi-client/client/client directory

echo "🚀 Setting up IronRDP integration for React Web VDI Client"
echo ""

# Determine the base directory
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IRONRDP_DIR="$BASE_DIR/../../../IronRDP/web-client"

# Check if IronRDP directory exists
if [ ! -d "$IRONRDP_DIR" ]; then
    echo "❌ Error: IronRDP directory not found at $IRONRDP_DIR"
    echo "Please adjust the path in this script or ensure IronRDP is cloned."
    exit 1
fi

echo "✅ Found IronRDP directory"

# Step 1: Build iron-remote-desktop-rdp
echo ""
echo "📦 Building iron-remote-desktop-rdp..."
cd "$IRONRDP_DIR/iron-remote-desktop-rdp"
if [ ! -d "node_modules" ]; then
    echo "Installing dependencies..."
    npm install
fi
npm run build

if [ $? -ne 0 ]; then
    echo "❌ Failed to build iron-remote-desktop-rdp"
    exit 1
fi
echo "✅ Built iron-remote-desktop-rdp"

# Step 2: Build iron-remote-desktop
echo ""
echo "📦 Building iron-remote-desktop..."
cd "$IRONRDP_DIR/iron-remote-desktop"
if [ ! -d "node_modules" ]; then
    echo "Installing dependencies..."
    npm install
fi
npm run build

if [ $? -ne 0 ]; then
    echo "❌ Failed to build iron-remote-desktop"
    exit 1
fi
echo "✅ Built iron-remote-desktop"

# Step 3: Copy files to public directory
echo ""
echo "📋 Copying built files to public directory..."
cd "$BASE_DIR"
mkdir -p public/iron-remote-desktop

# Copy the built files
cp -r "$IRONRDP_DIR/iron-remote-desktop/dist/"* public/iron-remote-desktop/ 2>/dev/null || true
cp -r "$IRONRDP_DIR/iron-remote-desktop-rdp/dist/"* public/iron-remote-desktop/ 2>/dev/null || true

echo "✅ Copied files to public/iron-remote-desktop"

# Step 4: Check if index.html needs updating
echo ""
echo "📝 Checking index.html..."
if grep -q "iron-remote-desktop.js" index.html; then
    echo "✅ index.html already has the web component script"
else
    echo "⚠️  You need to add the following line to index.html in the <head> section:"
    echo '    <script type="module" src="/iron-remote-desktop/iron-remote-desktop.js"></script>'
fi

# Step 5: Install npm dependencies
echo ""
echo "📦 Installing npm dependencies..."
npm install

echo ""
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Update index.html if needed (see above)"
echo "2. Run 'npm run dev' to start the development server"
echo "3. Open http://localhost:5173 in your browser"
echo ""
echo "For more information, see INTEGRATION.md"

