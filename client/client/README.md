# Web VDI Client - React

A React-based web client for remote desktop connections using IronRDP, inspired by the IronRDP Svelte client.

## Features

- 🖥️ Remote Desktop Protocol (RDP) connection
- 🔐 Secure authentication with token support
- 📋 Clipboard integration support
- 🎨 Modern, responsive UI with gradient design
- ⚙️ Configurable desktop size and connection parameters
- 🔧 Debug panel for development
- 📱 Mobile-friendly responsive design

## Architecture

The application is built with:

- **React 19** - UI framework
- **TypeScript** - Type safety
- **Vite** - Build tool and dev server
- **Context API** - State management for sessions and toasts
- **IronRDP WASM** - WebAssembly-based RDP client

### Project Structure

```
src/
├── components/          # React components
│   ├── Login.tsx       # Login form for RDP connection
│   ├── RemoteScreen.tsx # Remote desktop display
│   ├── Toast.tsx       # Notification system
│   └── *.css          # Component styles
├── contexts/           # React Context providers
│   ├── SessionContext.tsx  # Session management
│   └── ToastContext.tsx    # Toast notifications
├── models/            # Data models
│   └── Session.ts     # Session model
├── types/             # TypeScript type definitions
│   └── index.ts       # Type definitions
├── App.tsx            # Main app component
└── main.tsx           # App entry point
```

## Setup

### Prerequisites

- Node.js 18+ 
- npm or yarn

### Installation

1. Install dependencies:
```bash
npm install
```

2. Create a `.env` file (optional):
```bash
cp .env.example .env
```

3. Configure environment variables (optional):
```
VITE_IRON_TOKEN_SERVER_URL=http://localhost:8080
```

## Development

Start the development server:

```bash
npm run dev
```

The application will be available at `http://localhost:5173`

## Build

Build for production:

```bash
npm run build
```

The built files will be in the `dist/` directory.

## Usage

1. **Launch the application** - Open in your browser
2. **Enter connection details**:
   - **Hostname**: Target RDP server (e.g., `10.10.0.3:3389`)
   - **Domain**: Windows domain (optional)
   - **Username**: RDP username
   - **Password**: RDP password
   - **Gateway Address**: WebSocket proxy address (e.g., `ws://localhost:7171/jet/rdp`)
   - **Auth Token**: Authentication token (optional, can be auto-generated)
   - **Desktop Size**: Screen resolution (default: 1280x720)
3. **Click Connect** - Establish the RDP session
4. **Use the toolbar** to control the session:
   - Scale options (Fit, Full, Real)
   - Send special key combinations (Ctrl+Alt+Del, Meta key)
   - Toggle cursor style
   - Enable/disable Unicode keyboard mode
   - Terminate session

## Configuration Options

### Desktop Size
Set the initial remote desktop resolution. Can be adjusted in the login form.

### Clipboard Support
Enable bidirectional clipboard sharing between local and remote desktops.

### Pop-up Mode
Open the remote session in a new window (useful for multi-monitor setups).

### Pre-Connection Blob (PCB)
Advanced: Specify a pre-connection blob for load balancing scenarios.

### KDC Proxy URL
Advanced: Kerberos proxy URL for authentication.

## Integration with IronRDP

This client uses IronRDP's WebAssembly modules:
- `iron-remote-desktop` - Core web component
- `iron-remote-desktop-rdp` - RDP protocol implementation

To integrate with IronRDP WASM modules, ensure they are available in your project.

## Notes

- The client requires a WebSocket proxy (like Devolutions Gateway) to connect to RDP servers
- For production use, consider implementing proper token management and security measures
- The debug panel is available for development and troubleshooting

## License

This project is part of the CS408 project at KAIST.

## References

- [IronRDP](https://github.com/Devolutions/IronRDP)
- [IronRDP Web Client Examples](https://github.com/Devolutions/IronRDP/tree/master/web-client)
