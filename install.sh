#!/bin/bash

function e_header(){
    printf "\e[1;4;34m%s\e[0m\n" "exe ${*}"
}

function e_fail(){
    printf "\e[1;4;31m%s\e[0m\n" "✖ ${*} Fail!" 1>&2
}

function e_success(){
    printf "\e[1;4;32m%s\e[0m\n" "✔ ${*} Success!"
}

function e_indent(){
    for ((i=0; i<${1:-0}; i++)); do
        printf " "
    done
}

function e_cmd(){
    local n=${2:-0}
    e_indent ${n}
    if [ ${#1} -gt 100 ]; then
        local msg="${1:0:120}..."
    else
        local msg="${1}"
    fi
    e_header ${msg}
    eval ${1}
    local ret=${?}
    if [ "${ret}" = "0" ]; then
        e_indent ${n}
        e_success ${msg}
    else
        e_indent ${n}
        e_fail ${msg}
    fi
    return ${ret}
}

function cmd_exists(){
    which "$1" > /dev/null 2>&1
    return $?
}

function package_install(){
    function git_install(){
        e_cmd "sudo apt-get -y install git > /dev/null" 4
        e_cmd "curl -s https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash -o ~/.git-completion.bash > /dev/null" 4
        chmod a+x ~/.git-completion.bash
        e_cmd "curl -s https://raw.githubusercontent.com/no1986/init/main/dotfiles/gitconfig -o ~/.gitconfig > /dev/null" 4
    }
    function common_install(){
        e_cmd """sudo apt-get -y install \
             build-essential libffi-dev libssl-dev libreadline-dev libsqlite3-dev libbz2-dev zlib1g-dev \
             liblzma-dev autoconf automake autotools-dev build-essential dpkg-dev gnupg imagemagick ispell \
             libacl1-dev libasound2-dev libcanberra-gtk3-module liblcms2-dev libdbus-1-dev libgif-dev \
             libgnutls28-dev libgpm-dev libgtk-3-dev libjansson-dev libjpeg-dev liblockfile-dev libm17n-dev \
             libmagick++-6.q16-dev libncurses5-dev libotf-dev libpng-dev librsvg2-dev libselinux1-dev libtiff-dev \
             libxaw7-dev libxml2-dev openssh-client texinfo xaw3dg-dev zlib1g-dev ruby cmigemo p7zip-full \
             ripgrep direnv peco \
             > /dev/null""" 4
    }
    e_cmd "sudo apt-get update > /dev/null" 2
    e_cmd "git_install" 2
    e_cmd "common_install" 2
}

function env_install(){
    function anyenv_install(){
        if [ ! -e ~/.anyenv ]; then
            e_cmd "git clone https://github.com/anyenv/anyenv ~/.anyenv > /dev/null" 4
        fi
        export PATH=~/.anyenv/bin:${PATH}
        if [ ! -e ~/.config/anyenv/anyenv-install ]; then
            e_cmd "echo y | anyenv install --init > /dev/null" 4
        fi
        e_cmd 'eval "$(anyenv init -)" > /dev/null' 4

        mkdir -p $(anyenv root)/plugins
        if [ ! -e $(anyenv root)/plugins/anyenv-update ]; then
            e_cmd "git clone https://github.com/znz/anyenv-update.git $(anyenv root)/plugins/anyenv-update > /dev/null" 4
        fi
    }
    function pyenv_install(){
        e_cmd "anyenv install pyenv -s > /dev/null" 4

        export PYENV_ROOT=${HOME}/.anyenv/envs/pyenv
        export PATH=${PYENV_ROOT}/bin:${PATH}

        local ver=${1:-"3.11.0"}
        e_cmd "pyenv install ${ver} -s > /dev/null" 4
        e_cmd "pyenv global ${ver} > /dev/null" 4

        e_cmd 'eval "$(pyenv init -)" > /dev/null' 4

        e_cmd "pip install --upgrade pip > /dev/null" 4
        e_cmd "pip install poetry powerline-shell > /dev/null" 4
        e_cmd "poetry config virtualenvs.in-project true > /dev/null" 4
    }
    function goenv_install(){
        e_cmd "anyenv install goenv -s > /dev/null" 4

        export GOENV_ROOT=~/.anyenv/envs/goenv
        export PATH=${GOENV_ROOT}/bin:${PATH}

        local ver=${1:-"1.19.2"}
        e_cmd "goenv install ${ver} -s > /dev/null" 4
        e_cmd "goenv global ${ver} > /dev/null" 4

        e_cmd 'eval "$(goenv init -)" > /dev/null' 4
        export PATH=${GOPATH}/bin:${PATH}

        e_cmd "go install github.com/x-motemen/ghq@latest > /dev/null" 4
        e_cmd "go install golang.org/x/tools/gopls@latest > /dev/null" 4
        e_cmd "go install golang.org/x/tools/cmd/goimports@latest > /dev/null" 4
    }
    function nodenv_install(){
        e_cmd "anyenv install nodenv -s > /dev/null" 4

        export NODENV_ROOT=${HOME}/.anyenv/envs/nodenv
        export PATH=${NODENV_ROOT}/bin:${PATH}

        local ver=${1:-"19.0.0"}
        e_cmd "nodenv install ${ver} -s > /dev/null" 4
        e_cmd "nodenv global ${ver} > /dev/null" 4

        e_cmd 'eval "$(nodenv init -)"  > /dev/null' 4
    }

    e_cmd "anyenv_install" 2
    e_cmd 'pyenv_install "3.11.0"' 2
    e_cmd 'goenv_install "1.19.2"' 2
    e_cmd 'nodenv_install "19.0.0"' 2
}

function emacs_install(){
    local ver=${1:-"28.1"}

    if cmd_exists emacs; then
        c_ver=`emacs --version | head -n1 | awk '{print $3}'`
        if [ "${c_ver}" = "${ver}" ]; then
            return 0
        fi
    fi

    local pwd=$(pwd)
    if [ ! -e ~/tmp ]; then
        mkdir ~/tmp
    fi
    e_cmd "curl -s http://ftp.jaist.ac.jp/pub/GNU/emacs/emacs-${ver}.tar.gz -o ~/tmp/emacs-${ver}.tar.gz > /dev/null" 2
    e_cmd "tar -zxf ~/tmp/emacs-${ver}.tar.gz -C ~/tmp > /dev/null" 2
    cd ~/tmp/emacs-${ver}
    e_cmd "./configure --with-cairo > /dev/null" 2
    local jobs=`grep cpu.cores /proc/cpuinfo | wc -l`
    e_cmd "make -j${jobs} > /dev/null" 2
    e_cmd "sudo make install > /dev/null" 2
    cd ${pwd}
    rm -rf ~/tmp
}

function repo_get(){
    ghq get https://github.com/no1986/init.git > /dev/null
}

function set_xterm24bit(){
    init_path="$(ghq root)/$(ghq list | grep no1986/init)"
    tic -x -o ~/.terminfo ${init_path}/src/terminfo-24bit.src
}

function dotfiles(){
    local pwd=$(pwd)
    init_path="$(ghq root)/$(ghq list | grep no1986/init)"
    cd ${init_path}/dotfiles
    files=`find ${init_path}/dotfiles -type f`
    for p in ${files}; do
        f=$(basename ${p})
        if [ ! -L ~/${f} -a -f ~/${f} ]; then
            mkdir -p ~/backup
            cp ~/${f} ~/backup/
        fi
        e_cmd "ln -snf ${p} ~/.${f}" 2
    done
    cd ${pwd}
}

function dotemacs(){
    local pwd=$(pwd)
    init_path="$(ghq root)/$(ghq list | grep no1986/init)"
    files=`find ${init_path}/dotemacs -type f`
    mkdir -p ~/.emacs.d
    for p in ${files}; do
        f=$(basename ${p})
        e_cmd "ln -snf ${p} ~/.emacs.d/${f}" 2
    done
}

function dotconfig(){
    init_path="$(ghq root)/$(ghq list | grep no1986/init)"
    function powershell(){
        files=`find ${init_path}/dotconfig -type f`
        mkdir -p ~/.config/powerline-shell
        for p in ${files}; do
            f=$(basename ${p})
            e_cmd "ln -snf ${p} ~/.config/powerline-shell/${f}" 4
        done
    }

    e_cmd "powershell" 2
}

function font(){
    e_cmd "ghq get https://github.com/iij/fontmerger.git > /dev/null" 2
    path="$(ghq root)/$(ghq list | grep iij/fontmerger)"
    e_cmd "sudo cp $path/sample/Ricty* /usr/local/share/fonts/" 2
    e_cmd "fc-cache" 2
    e_cmd "sudo apt-get -y install gnome-tweaks" 2
}

e_cmd "package_install"
e_cmd "env_install"
e_cmd 'emacs_install "28.1"'
e_cmd "repo_get"
e_cmd "set_xterm24bit"
e_cmd "dotfiles"
e_cmd "dotemacs"
e_cmd "dotconfig"
if [ `sudo systemctl get-default` == "graphical.target" ];
then
    e_cmd "font"
fi

