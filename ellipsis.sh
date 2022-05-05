#!/usr/bin/env bash

# List of vscode extensions to install
extensions=(
    "ms-azuretools.vscode-docker"
    "github.copilot"
    "esbenp.prettier-vscode"
    "mechatroner.rainbow-csv"
    "ms-vscode-remote.remote-wsl"
);

pkg.install() {
    case $(os.platform) in
        osx)
            ## Install homebrew cask(s)
            if utils.cmd_exists brew; then
                brew install --cask visual-studio-code
                brew install jq
            fi
            VSCONFIGPATH="$HOME/Library/Application\ Support/Code/User"
            ;;
        wsl2)
            ## Install dot-chocolatey if it's not installed
            if ! utils.cmd_exists choco; then
                $ELLIPSIS_PATH/bin/ellipsis installed | grep 'chocolatey' >/dev/null 2>&1
                if [ $? -eq 0 ]; then
                    $ELLIPSIS_PATH/bin/ellipsis pull chocolatey
                    $ELLIPSIS_PATH/bin/ellipsis reinstall chocolatey
                else
                    $ELLIPSIS_PATH/bin/ellipsis install thomshouse-ellipsis/chocolatey
                fi
            fi
            ## Install choco package(s)
            if utils.cmd_exists choco; then
                choco install vscode -y
            fi
            ## Install apt-package(s)
            if utils.cmd_exists apt-get; then
                DEBIAN_FRONTEND=noninteractive sudo apt-get update -y && sudo apt-get install -y jq
            fi
            VSCONFIGPATH="$(wslpath -u "$(cmd.exe /C echo %APPDATA% 2> /dev/null | sed -e 's/\r//g')")/Code/User"
            ;;
        linux)
            ## Install apt-package(s)
            if utils.cmd_exists apt-get; then
                wget -O "${TMPDIR:-/tmp}/vscode.deb" https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64
                DEBIAN_FRONTEND=noninteractive sudo apt-get update -y && sudo apt install -y "${TMPDIR:-/tmp}/vscode.deb"
                DEBIAN_FRONTEND=noninteractive sudo apt-get install -y jq
            fi
            VSCONFIGPATH="$HOME/.config/Code/User"
            ;;
    esac

    # Merge the config files
    jq -s '.[0] * .[1] * .[2]' "$PKG_PATH/config/defaults.json" "$VSCONFIGPATH/settings.json" "$PKG_PATH/config/overrides.json" > "${TMPDIR:-/tmp}/vscode-settings.json"
    mv "${TMPDIR:-/tmp}/vscode-settings.json" "$VSCONFIGPATH/settings.json"

    # Install each vscode extension
    for extension in "${extensions[*]}"; do
        code --install-extension "$extension"
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
