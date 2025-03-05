# AutoProgrammer with Cursor Integration

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

A modular, microservices-based integration solution for AutoProgrammer and Cursor, providing seamless transfer of AI outputs into your coding environment.

## 🚀 Quick Start

For the fastest setup:

```bash
git clone https://github.com/yourusername/AutoProgrammer.git
cd AutoProgrammer
chmod +x setup.sh
./setup.sh
npm start
```

Then start the Cursor integration:

```bash
# In another terminal window or by double-clicking in Finder:
./last-resort.command
```

## 🌟 Features

- **Ultra-Simple Integration**: Zero-dependency scripts that just work
- **Microservices Architecture**: Modular design with separate services
- **Multiple Setup Options**: From one-click to full Docker deployment
- **Cross-Platform Support**: Works on macOS, Linux, and Windows
- **Automatic Output Detection**: Continuously monitors for new outputs
- **Real-Time Updates**: Instantly displays and copies new content

## 🔧 Setup & Installation

We provide multiple setup options to fit your needs:

1. **[Quick Start Guide](QUICKSTART.md)** - Get running in 60 seconds
2. **[GitHub Setup](GITHUB-SETUP.md)** - Detailed setup from GitHub
3. **[Installation Guide](INSTALL.md)** - Complete installation instructions

### Minimum Requirements

- **For Simple Integration**: macOS, Linux, or Windows with Bash
- **For Full Application**: Node.js 14+ and npm

## 🏗️ System Architecture

AutoProgrammer integration uses a microservices architecture:

```
┌───────────────────┐      ┌───────────────────┐
│                   │      │                   │
│  AutoProgrammer   │─────▶│  Output Service   │
│                   │      │                   │
└───────────────────┘      └─────────┬─────────┘
                                     │
                                     ▼
                           ┌───────────────────┐
                           │                   │
                           │ Cursor Integration│
                           │                   │
                           └─────────┬─────────┘
                                     │
                                     ▼
                           ┌───────────────────┐
                           │                   │
                           │      Cursor       │
                           │                   │
                           └───────────────────┘
```

## 📊 Usage Examples

### Basic Usage

1. Run AutoProgrammer and generate an output
2. The integration automatically detects the new output
3. Content appears in your terminal and is copied to clipboard
4. Paste into Cursor

### Testing the Integration

Edit and save the test file:
```bash
echo "This is a test" >> test-output.txt
```

## 📚 Documentation

- [QUICKSTART.md](QUICKSTART.md) - Get up and running fast
- [GITHUB-SETUP.md](GITHUB-SETUP.md) - Setting up from GitHub
- [INSTALL.md](INSTALL.md) - Detailed installation guide
- [EMERGENCY-FIX.md](EMERGENCY-FIX.md) - If you're having problems

## 🤝 Contributing

Contributions are welcome! Please see our [Contributing Guide](.github/CONTRIBUTING.md) for details.

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgements

- AutoProgrammer community
- Cursor development team
- All contributors to this project 