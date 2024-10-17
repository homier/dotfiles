#!/bin/bash

set -e

ROOTPATH=$(dirname $(realpath "$0"))
CONFIGPATH=$ROOTPATH/config

dnfcoprs=(
    erikreider/SwayNotificationCenter
)

dnfpackages=(
    SwayNotificationCenter
    alacritty
    firefox
    flatpak
    git
    golang
    htop
    hyprland
    jq
    neovim
    net-tools
    network-manager-applet
    python3
    python3-neovim
    ripgrep
    rsync
    waybar
    wget
    wireguard-tools
    zsh
)

flatpackages=(
    com.spotify.Client
    flathub
    org.telegram.desktop
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

installdnf () {
    echo "[INFO] dnf: installing RPM fusion"
    sudo dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
    sudo dnf install -y https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm 
    echo "[INFO] dnf: RPM fusion installed"

    sudo dnf upgrade -y 

    echo "[INFO] dnf: installing copr repositories"
    sudo dnf copr enable -y "${dnfcoprs[@]}"
    echo "[INFO] dnf: copr repositories installed"

    echo "[INFO] dnf: installing packages"
    sudo dnf install -y "${dnfpackages[@]}"
    echo "[INFO] dnf: done"
}

installflatpaks() {
    echo "[INFO] flatpak: installing flathub repository"
    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    echo "[INFO] flatpak: flathub installed"

    echo "[INFO] flatpak: installing packages"
    flatpak install -y "${flatpackages[@]}"
    echo "[INFO] flatpak: done"
}

installomz() {
    echo "[INFO] omz: installing"

    [[ -x $HOME/.oh-my-zsh ]] || ZSH= sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

    echo "[INFO] omz: installed"

    echo "[INFO] omz: changing shell to zsh"
    sudo usermod -s $(which zsh) $USER

    echo "[INFO] omz: downloading themes"

    rm -rf /tmp/simplerich
    mkdir -p ~/.oh-my-zsh/themes/

    git clone --recursive https://github.com/philip82148/simplerich-zsh-theme /tmp/simplerich
    cp -f /tmp/simplerich/simplerich.zsh-theme ~/.oh-my-zsh/themes/simplerich.zsh-theme

    echo "[INFO] omz: done"
}

installfonts() {
    echo "[INFO] fonts: installing"
    echo "[INFO] fonts: installing Hack Nerd Font Mono"
    wget https://github.com/ryanoasis/nerd-fonts/releases/download/${fonts_hack_version}/Hack.tar.xz -O /tmp/hack.tar.xz

    mkdir -p ~/.local/share/fonts/hack-nerd-font
    tar -xf /tmp/hack.tar.xz -C ~/.local/share/fonts/hack-nerd-font
    echo "[INFO] fonts: done"
}

installneovim() {
    echo "[INFO] neovim: bootstrapping config..."

    mkdir -p ~/.config/nvim

    git clone https://github.com/homier/kickstart.nvim ~/.config/nvim || \
        echo "[INFO] nvim: dotfiles are already present"

    cd ~/.config/nvim \
        && git stash \
        && git pull --rebase \
        || git stash pop \
        || cd $ROOTPATH

    echo "[INFO] nvim: done"
}

installrust() {
    echo "[INFO] rust: installing"

    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

    $HOME/.cargo/bin/rustup update
    $HOME/.cargo/bin/rustup component add rust-analyzer

    echo "[INFO] rust: done"
}

installgo() {
    echo "[INFO] go: installing modules"

    go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
    go install golang.org/x/tools/gopls@latest

    for module in ${gomodes[@]}
    do
        go install $module
    done


    echo "[INFO] go: adding GOPATH to environment"

    grep -qxF 'export GOPATH="$HOME/go"' ~/.zshenv || echo 'export GOPATH="$HOME/go"' >> ~/.zshenv
    grep -qxF 'export PATH=$PATH:$GOPATH/bin' ~/.zshenv || echo 'export PATH=$PATH:$GOPATH/bin' >> ~/.zshenv

    echo "[INFO] go: done"
}

configs() {
    echo "[INFO] configs: applying $HOME/.config"
    rsync -a $CONFIGPATH/ $HOME/.config

    echo "[INFO] configs: applying zsh config"
    cp -a $ROOTPATH/zshrc $HOME/.zshrc
    echo "[INFO] configs: done"
}

configuresystemd() {
    echo "[INFO] systemd: enabling services"
    systemctl enable --now --user gpg-agent
    systemctl enable --now --user ssh-agent
    systemctl enable --now --user plasma-polkit-agent
    echo "[INFO] systemd: done"
}

configuregit() {
    echo "[INFO] git: applying global configs"
    git config --global user.name "Dzmitry Mikhalapau"
    git config --global user.email "dzmitry.mikhalapau@gmail.com"
    git config --global commit.gpgsign true
    git config --global core.editor vim
    echo "[INFO] git: done"
}

installdnf
installflatpaks
installfonts
installomz
installrust
installgo

installneovim

configs
configuresystemd
configuregit
