# Integration Guide: React Web VDI Client

This guide explains how to integrate the React-based web VDI client with IronRDP WASM modules.

## Overview

The React client (`/web-vdi-client/client/client/`) is designed to work with:
- IronRDP's `iron-remote-desktop` web component
- IronRDP's `iron-remote-desktop-rdp` WASM module

## Integration Steps

### 1. Build IronRDP WASM Modules

First, you need to build the IronRDP WASM modules from the main IronRDP directory:

```bash
cd /Users/jake/Desktop/KAIST/2025Fall/CS408\ CS\ Project/IronRDP/web-client/iron-remote-desktop-rdp
npm install
npm run build
```

```bash
cd /Users/jake/Desktop/KAIST/2025Fall/CS408\ CS\ Project/IronRDP/web-client/iron-remote-desktop
npm install
npm run build
```

### 2. Link or Copy WASM Modules

You have two options:

#### Option A: npm link (Development)

```bash
# In iron-remote-desktop-rdp directory
npm link

# In iron-remote-desktop directory
npm link

# In your React client directory
cd /Users/jake/Desktop/KAIST/2025Fall/CS408\ CS\ Project/web-vdi-client/client/client
npm link @devolutions/iron-remote-desktop-rdp
npm link @devolutions/iron-remote-desktop
```

#### Option B: Copy dist files (Simpler)

Create a `public/iron-remote-desktop/` directory and copy the built files:

```bash
cd /Users/jake/Desktop/KAIST/2025Fall/CS408\ CS\ Project/web-vdi-client/client/client

# Create directory
mkdir -p public/iron-remote-desktop

# Copy built files
cp -r ../../IronRDP/web-client/iron-remote-desktop/dist/* public/iron-remote-desktop/
cp -r ../../IronRDP/web-client/iron-remote-desktop-rdp/dist/* public/iron-remote-desktop/
```

### 3. Update Import Statements

Update the React component files to import the IronRDP modules:

**In `src/components/Login.tsx`:**

```typescript
// Replace the declare statements with actual imports
import { preConnectionBlob, displayControl, kdcProxyUrl, init } from '@devolutions/iron-remote-desktop-rdp';
```

**In `src/components/RemoteScreen.tsx`:**

```typescript
// Replace the declare statement with actual import
import { Backend } from '@devolutions/iron-remote-desktop-rdp';
```

### 4. Load Web Component

Add a script tag in `index.html` to load the iron-remote-desktop web component:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <link rel="icon" type="image/svg+xml" href="/vite.svg" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Web VDI Client</title>
    <!-- Load IronRDP Web Component -->
    <script type="module" src="/iron-remote-desktop/iron-remote-desktop.js"></script>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
```

### 5. Install Dependencies

```bash
cd /Users/jake/Desktop/KAIST/2025Fall/CS408\ CS\ Project/web-vdi-client/client/client
npm install
```

### 6. Run the Development Server

```bash
npm run dev
```

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     React Application                       │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Components (Login, RemoteScreen, Toast)             │  │
│  └──────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Contexts (SessionContext, ToastContext)             │  │
│  └──────────────────────────────────────────────────────┘  │
└──────────────────────┬──────────────────────────────────────┘
                       │ Uses
                       ▼
┌─────────────────────────────────────────────────────────────┐
│           IronRDP Web Component & WASM Modules              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  <iron-remote-desktop> (Svelte Web Component)        │  │
│  └──────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  iron-remote-desktop-rdp (WASM Backend)              │  │
│  └──────────────────────────────────────────────────────┘  │
└──────────────────────┬──────────────────────────────────────┘
                       │ Connects via WebSocket
                       ▼
┌─────────────────────────────────────────────────────────────┐
│              WebSocket Proxy (e.g., Gateway)                │
└──────────────────────┬──────────────────────────────────────┘
                       │ RDP Protocol
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                    RDP Server (Target)                      │
└─────────────────────────────────────────────────────────────┘
```

## Backend Server Setup

### Option 1: Use Devolutions Gateway

The easiest way is to use [Devolutions Gateway](https://github.com/Devolutions/devolutions-gateway/), which provides WebSocket proxy for RDP connections.

### Option 2: Custom Rust Server

You can also use the Rust server in `/web-vdi-client/server/` as a starting point to build a custom WebSocket proxy.

## Environment Variables

Create a `.env` file in the client directory:

```env
VITE_IRON_TOKEN_SERVER_URL=http://localhost:8080
```

This is optional. If not set, you'll need to manually provide authentication tokens.

## Testing

1. Start your WebSocket proxy/gateway
2. Run the React dev server: `npm run dev`
3. Open `http://localhost:5173` in your browser
4. Fill in the connection form:
   - Hostname: Your RDP server address
   - Username/Password: RDP credentials
   - Gateway Address: Your WebSocket proxy URL
5. Click "Connect"

## Troubleshooting

### WASM Module Not Found
- Ensure you've built the IronRDP modules
- Check that the paths in import statements are correct
- Verify the modules are in `node_modules` or `public` directory

### CORS Issues
- Make sure your WebSocket proxy allows CORS
- Check browser console for specific CORS errors

### Connection Fails
- Verify the WebSocket proxy is running
- Check that the RDP server is accessible
- Ensure authentication credentials are correct
- Check browser console for error messages

### Custom Element Not Defined
- Ensure the `iron-remote-desktop.js` script is loaded
- Check that the web component is properly registered
- Look for errors in browser console

## Production Build

```bash
npm run build
```

The production build will be in the `dist/` directory. You can serve it with any static file server.

## Additional Resources

- [IronRDP GitHub](https://github.com/Devolutions/IronRDP)
- [Devolutions Gateway](https://github.com/Devolutions/devolutions-gateway/)
- [React Documentation](https://react.dev/)
- [Vite Documentation](https://vitejs.dev/)

