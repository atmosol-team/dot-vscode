#!/usr/bin/env bash

# List of vscode extensions to install
extensions=(
);

pkg.install() {
    # Attempt to install vscode
    if ! utils.cmd_exists code; then
        case $(os.platform) in
            osx)
                if utils.cmd_exists brew; then
                    brew install --cask visual-studio-code
                fi
                ;;
            wsl2)
                ## Install dot-chocolatey if it's not installed
                if ! utils.cmd_exists choco; then
                    $ELLIPSIS_PATH/bin/ellipsis install thomshouse-ellipsis/chocolatey
                fi
                ## Install choco package(s)
                choco install vscode -y
                ;;
            linux)
                ## Install apt-package(s)
                if utils.cmd_exists apt-get; then
                    wget -O "${TMPDIR:-/tmp}/vscode.deb" "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64"
                    DEBIAN_FRONTEND=noninteractive sudo apt-get update -y && sudo apt install -y "${TMPDIR:-/tmp}/vscode.deb"
                fi
                ;;
        esac
    fi

    # Attempt to install jq for config sync
    if ! utils.cmd_exists jq; then
        case $(os.platform) in
            osx)
                if utils.cmd_exists brew; then
                    brew install jq
                fi
                ;;
            wsl2|linux)
                if utils.cmd_exists apt-get; then
                    DEBIAN_FRONTEND=noninteractive sudo apt-get update -y && sudo apt-get install -y jq
                fi
        esac
    fi

    # Merge the config files
    case $(os.platform) in
        osx)
            VSCONFIGPATH="$HOME/Library/Application\ Support/Code/User"
            ;;
        wsl2)
            VSCONFIGPATH="$(wslpath -u "$(cmd.exe /C echo %APPDATA% 2> /dev/null | sed -e 's/\r//g')")/Code/User"
            ;;
        linux)
            VSCONFIGPATH="$HOME/.config/Code/User"
            ;;
    esac

    # Merge the config files
    jq -s '.[0] * .[1] * .[2]' "$PKG_PATH/config/defaults.json" "$VSCONFIGPATH/settings.json" "$PKG_PATH/config/overrides.json" > "${TMPDIR:-/tmp}/vscode-settings.json"
    mv "${TMPDIR:-/tmp}/vscode-settings.json" "$VSCONFIGPATH/settings.json"

    # Install each vscode extension
    if [ $(os.platform) = "wsl2" ]; then
        # Install on Windows side for WSL installs
        # Check installed extensions
        INSTALLED_EXTS="$(cmd.exe /C code --list-extensions 2>/dev/null)"
        for extension in "${extensions[@]}"; do
            # Iterate through extensions and install if not installed
            if ! echo "$INSTALLED_EXTS" | grep -q "$extension"; then
                cmd.exe /C "code --install-extension $extension" 2> /dev/null
            fi
        done
    fi
    # Install in osx/linux/WSL environments
    INSTALLED_EXTS="$(code --list-extensions)"
    for extension in "${extensions[@]}"; do
        # Iterate through extensions and install if not installed
        if ! echo "$INSTALLED_EXTS" | grep -q "$extension"; then
            code --install-extension "$extension"
        fi
    done

    # Initialize the package
    pkg.init
}

pkg.init() {
    # Add package bin to $PATH
    if [ -d "$PKG_PATH/bin" ]; then
        export PATH=$PKG_PATH/bin:$PATH
    fi

    # Run init scripts
    for file in $(find "$PKG_PATH/init" -maxdepth 1 -type f -name "*.zsh" 2>/dev/null); do
        [ -e "$file" ] || continue
        . "$file"
    done
}

pkg.link() {
    # fs.link_files links;
    : # Package does not contain linkable files
}

pkg.unlink() {
    : # Package does not contain linkable files
}
