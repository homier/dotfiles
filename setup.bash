#!/bin/bash

set -e

dnfpackages=(
    alacritty
    emacs
    flatpak
    firefox
    git
    golang
    htop
    jq
    net-tools
    python3
    python3
    rsync
    telegram-desktop
    the_silver_searcher
    wget
    wireguard-tools
    zsh
)

flatpackages=(
    flathub
    com.spotify.Client
)

gomodes=(
    github.com/cweill/gotests/...@latest
    github.com/davidrjenni/reftools/cmd/fillstruct@latest
    github.com/fatih/gomodifytags@latest
    github.com/godoctor/godoctor@latest
    github.com/haya14busa/gopkgs/cmd/gopkgs@latest
    github.com/josharian/impl@latest
    github.com/mdempsky/gocode@latest
    github.com/rogpeppe/godef@latest
    github.com/zmb3/gogetdoc@latest
    golang.org/x/tools/cmd/godoc@latest
    golang.org/x/tools/cmd/goimports@latest
    golang.org/x/tools/cmd/gorename@latest
    golang.org/x/tools/cmd/guru@latest
)

fonts_hack_version=v3.1.1

preinstall() {
    echo "[INFO] Installing RPM Fusion repositories..."
    sudo dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
    sudo dnf install -y https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm 
    echo "[INFO] RPM Fusion repositories have been installed"
}

installdnf () {
    echo "[INFO] Performming DNF upgrade..."
    sudo dnf upgrade -y 
    echo "[INFO] DNF system upgrade has been completed"

    echo "[INFO] Installing DNF packages..."
    sudo dnf install -y "${dnfpackages[@]}"
    echo "[INFO] DNF packages have been installed"
}

installflatpaks() {
    echo "[INFO] Adding flathub repo..."
    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    echo "[INFO] Flathub repo has been added"

    echo "[INFO] Installing flatpak packages..."
    flatpak install -y "${flatpackages[@]}"
    echo "[INFO] Flatpak packages have been installed"
}

installomz() {
    echo "[INFO] Installing oh-my-zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || \
        echo "[INFO] omz is already present"
    echo "[INFO] oh-my-zsh has been installed"

    echo "[INFO] Changing default shell to zsh"
    sudo usermod -s $(which zsh) $USER
    echo "[INFO] Default sheel has been changed to zsh"

    echo "[INFO] Downloading simplerich zsh theme..."
    rm -rf /tmp/simplerich

    mkdir -p /tmp/simplerich
    mkdir -p ~/.oh-my-zsh/themes/

    git clone --recursive https://github.com/philip82148/simplerich-zsh-theme /tmp/simplerich
    cp -f /tmp/simplerich/simplerich.zsh-theme ~/.oh-my-zsh/themes/simplerich.zshrc.s

    echo "[INFO] simplerich zsh theme has been downloaded"

    echo "[INFO] Copying .zshrc config file..."
    cp -f ./zshrc ~/.zshrc
    echo "[INFO] .zshrc file has been applied"
}

installfonts() {
    echo "[INFO] Installing fonts..."
    echo "[INFO] Downloading hack font..."
    wget https://github.com/ryanoasis/nerd-fonts/releases/download/${fonts_hack_version}/Hack.tar.xz -O /tmp/hack.tar.xz
    echo "[INFO] Hack font has been downloaded"

    echo "[INFO] Unpacking hack font..."
    mkdir -p ~/.local/share/fonts/hack-nerd-font
    tar -xf /tmp/hack.tar.xz -C ~/.local/share/fonts/hack-nerd-font
    echo "[INFO] Hack font has been installed"
}

installemacs() {
    echo "[INFO] Installing doom emacs..."

    echo "[INFO] Downloading doom emacs..."
    git clone --depth 1 https://github.com/doomemacs/doomemacs ~/.config/emacs || \
        echo "[INFO] Doom emacs is already existing"
    echo "[INFO] Doom emacs has been downloaded"

    echo "[INFO] Altering PATH in .zshenv to include doom binaries..."
    grep -qxF 'export PATH=$PATH:~/.config/emacs/bin' ~/.zshenv || \
        echo 'export PATH=$PATH:~/.config/emacs/bin' >> ~/.zshenv

    echo "[INFO] Running doom sync..."
    source ~/.zshenv &&  ~/.config/emacs/bin/doom install --no-config --env

    echo "[INFO] Applying doom emacs config..."
    mkdir -p ~/.config/doom
    cp -a ./doom/* ~/.config/doom/

    echo "[INFO] Syncing doom emacs..."
    ~/.config/emacs/bin/doom sync -e

    echo "[INFO] Doom emacs has been installed"
}

installrust() {
    echo "[INFO] Installing rust..."

    echo "[INFO] Installing rustup..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    echo "[INFO] rustup has been installed"

    echo "[INFO] Updating rust toolchain..."
    $HOME/.cargo/bin/rustup update
    echo "[INFO] Rust toolchain has been updated"

    echo "[INFO] Installing rust-analyzer..."
    $HOME/.cargo/bin/rustup component add rust-analyzer
    echo "[INFO] Rust-analyzer has been added"

    echo "[INFO] Rust has been installed"
}

installgo() {
    echo "[INFO] Installing go modules..."

    GO111MODULE=on go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
    GO111MODULE=on go install golang.org/x/tools/gopls@latest

    for module in ${gomodes[@]}
    do
        go install $module
    done

    echo "[INFO] Go modules have been installed"

    echo "[INFO] Adding GOPATH to .zshenv file..."
    grep -qxF 'export GOPATH="$HOME/go"' ~/.zshenv || echo 'export GOPATH="$HOME/go"' >> ~/.zshenv
    echo "[INFO] GOPATH has been added"

    echo "[INFO] Altering PATH in .zshenv to include go binaries..."
    grep -qxF 'export PATH=$PATH:$GOPATH/bin' ~/.zshenv || echo 'export PATH=$PATH:$GOPATH/bin' >> ~/.zshenv

    echo "[INFO] PATH has been added"
}

configurealacritty() {
    echo "[INFO] Setting up alacritty..."

    mkdir -p ~/.config/alacritty

    echo "[INFO] Downloading alacritty themes..."
    git clone https://github.com/alacritty/alacritty-theme ~/.config/alacritty/themes || \
        echo "[INFO] Alacritty themes are already present"
    echo "[INFO] Alacritty themes have been downloaded"

    echo "[INFO] Applying alacritty configuration..."
    cp $(realpath alacritty.toml) ~/.config/alacritty/alacritty.toml
    echo "[INFO] Alacritty configuration has been applied"

    echo "[INFO] Alacritty has been set up"
}

preinstall
installdnf
installflatpaks
installfonts
installomz
installrust
installgo
installemacs
configurealacritty
