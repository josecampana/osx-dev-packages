# dev-packages

This project provides an interactive menu to install and configure development tools on macOS using Bash scripts. The menu auto-discovers scripts in `./packages` and lets you run them in isolated child processes.

## Requirements

- Bash 3.2+ (macOS ships 3.2; this is sufficient)
- Git (required by some packages)
- Executable permissions on scripts

## Usage

Clone this repository:

```bash
  git clone git@github.com:josecampana/dev-packages.git
```

And run the installer:

```bash
cd dev-packages
./install.sh
```

### Problems with permissions?

Try this:

```bash
chmod 755 install.sh
chmod 755 lib/common.sh
chmod 755 packages/*.sh
```

## Disclaimer

This repo is shared to simplify developer environment setup, inspired by Jose Luis Campaña's vision to create a better everyday life for the many (for the many lazy developers). Use and adapt internally as needed but check license terms for redistribution. No warranties; use at your own risk.

## LICENSE

[Mozilla Public License 2.0](LICENSE)
