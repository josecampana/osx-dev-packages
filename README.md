# osx-dev-packages

This project provides an interactive menu to install and configure development tools on macOS using Bash scripts. The menu auto-discovers scripts in `./packages` and lets you run them in isolated child processes.

## Requirements

- Bash 3.2+ (macOS ships 3.2; this is sufficient)
- Git (required by some packages)
- Executable permissions on scripts

## Usage

Type:

```bash
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/tuusuario/osx-dev-packages/main/bootstrap.sh)"
```

## Disclaimer

This repo is shared to simplify developer environment setup, inspired by Jose Luis Campaña's vision to create a better everyday life for the many (for the many lazy developers). Use and adapt internally as needed but check license terms for redistribution. No warranties; use at your own risk.

## LICENSE

[Mozilla Public License 2.0](LICENSE)
