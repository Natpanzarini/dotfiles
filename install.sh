#!/bin/bash
here=$(pwd)
logfile=$here/install.log

# groups to add the user to
groups=(wheel dialout libvirt vboxusers wireshark)

# apps to install in all distributions
applist="tree \
    make \
    cmake \
    clang \
    pdftk \
    gcc \
    meld \
    curl \
    pinta \
    git \
    wireshark \
    htop \
    bison \
    dropbear \
    neofetch \
    flex \
    sshfs \
    wine \
    feh \
    ccrypt \
    vim \
    rst2pdf \
    patch \
    ctags \
    terminator \
    tmux \
    lynx
    "

# apps to install if using centos
centosApps="perl-Tk-devel.x86_64 \
    perl-Thread-Queue \
    gcc-c++ \
    ncurses-devel \
    openssl-devel \
    xpdf \
    geany-plugins-geanygendoc \
    perl-ExtUtils-MakeMaker
    "

# apps to install if using ubuntu
ubuntuApps="docutils-common \
    g++ \
    yakuake
    "

# apps to install if using arch
archApps="kakuake"

# arch AUR apps to install
archAurRepos=(https://aur.archlinux.org/xrdp.git \
    https://aur.archlinux.org/rst2pdf.git \
    https://aur.archlinux.org/spotify.git \
    https://aur.archlinux.org/ncurses5-compat-libs.git
)

echon ()
{
    echo -e "\n################################################################################" | tee -a $logfile
    echo -e "$1" | tee -a $logfile
    echo -e "################################################################################\n" | tee -a $logfile
    sleep 1
}

backup ()
{
    here=$(pwd)
    backupdir=$here/backup
    if [ -d $backupdir ]; then
        read -r -p "Overwrite current contents of $backupdir (if no then dotfiles will still be installed press ctrl+c to prevent this) ? [y/n] : " response
        case "$response" in
            [yY][eE][sS]|[yY])
                echon "OVERWRITING CURRENT CONTENTS OF $backupdir"
                overwrite=1
                ;;
            *)
                overwrite=0
                ;;
        esac
    fi
    echon "Backing up current existing dot files to $backupdir ..."
    cd files
    all=$(find . -maxdepth 100 -type f -not -path '/*\.*' | sort)
    if [ ! -d $here/backup ]; then
        mkdir $here/backup
    fi
    for i in $all; do
        cp --verbose --parents $i $here/backup | tee -a $logfile
    done
    cd $here
}

addGroup() {
    user=$(whoami)
    # check to see if the group exists first
    getent group | grep $1 > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echon "adding user $user to $1 ..."
        sudo usermod -a -G $1 $user
    fi
}

archAurInstall() {
    here=$(pwd)
    gr=$here/archAurPkgs
    repos=$1

    echon "Installing ARCH AUR Repos..."

    # create directory for repos
    if [ ! -d $gr ]; then
        mkdir $gr
    fi
    cd $gr

    # clone all the repos
    for i in ${repos[@]}; do
        git clone $i | tee -a $logfile
    done

    # go in each one and install it
    d=$(find . -maxdepth 1 -type d)
    echo $d
    init=0 # ignore the first entry which is ./
    for i in $d; do
        if [ $init -ne 0 ]; then
            cd $i
            makepkg -si --skippgpcheck | tee -a $logfile
            cd ..
        else
            let init=1
        fi
    done
    cd $here
}

non_pacman_apps () {
    use_git=0
    ################################################################################
    # install non-pacman apps option
    ################################################################################
    read -r -p "use git to source latest builds? If not tarballs will be used [y/n] : " response
    case "$response" in
        [yY][eE][sS]|[yY])
            use_git=1
            ;;
        [nN][oO]|[nN])
            use_git=0
            ;;
        *)
            echo "Must choose y/n..."
            exit 1
            ;;
    esac

    ################################################################################
    # fzf
    ################################################################################
    tmp=$(which fzf > /dev/null 2>&1)
    if [ $? -ne 0 ]; then
        if [ $arch -eq 1 ]; then
            sudo pacman -S fzf
        else
            echon "installing fzf ..."
            if [ $use_git -eq 1 ]; then
                git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf | tee -a $logfile
                ~/.fzf/install | tee -a $logfile
            else
                mkdir -pv ~/.fzf
                cd ~/.fzf
                curl -LO https://github.com/junegunn/fzf/archive/0.21.1.zip | tee -a $logfile
                unzip 0.21.1.zip | tee -a $logfile
                ./fzf-0.21.1/install | tee -a $logfile
            fi
            cd $here
        fi
    fi

    ################################################################################
    # rcm
    ################################################################################
    tmp=$(which rcup > /dev/null 2>&1)
    if [ $? -ne 0 ]; then
        echon "installing rcm ..."
        if [ $debian -eq 1 ]; then
            wget -qO - https://apt.thoughtbot.com/thoughtbot.gpg.key | sudo apt-key add - | tee -a $logfile
            echo "deb https://apt.thoughtbot.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/thoughtbot.list | tee -a $logfile
            sudo apt-get update | tee -a $logfile
            sudo apt-get install rcm | tee -a $logfile
        else
            mkdir -p ~/.rcm
            cd ~/.rcm
            curl -LO https://thoughtbot.github.io/rcm/dist/rcm-1.3.3.tar.gz | tee -a $logfile
            tar -xvf rcm-1.3.3.tar.gz | tee -a $logfile
            cd rcm-1.3.3
            ./configure | tee -a $logfile
            make | tee -a $logfile
            sudo make install | tee -a $logfile
            cd $here
        fi
    fi

    ################################################################################
    # ranger
    ################################################################################
     tmp=$(which ranger > /dev/null 2>&1)
     if [ $? -ne 0 ]; then
        echon "installing ranger ..."
        if [ $use_git -eq 1 ]; then
            git clone git@github.com:ranger/ranger.git ~/.ranger | tee -a $logfile
            sudo make -C ~/.ranger install | tee -a $logfile
        else
            mkdir -p ~/.ranger
            cd ~/.ranger
            curl -LO https://github.com/ranger/ranger/archive/v1.9.3.zip | tee -a $logfile
            unzip v1.9.3.zip | tee -a $logfile
            cd ranger-1.9.3
        fi
        sudo make install | tee -a $logfile
        cd $here
     fi
}

################################################################################
# start main
################################################################################
if [ ! -f $logfile ]; then
    touch $logfile
fi
echon "$0 ran @ $(date)..."

################################################################################
# get linux distro
################################################################################
distro=""
tool=""
debian=0
centos=0
arch=0
tmp=$(which apt > /dev/null 2>&1)
if [ $? -eq 0 ]; then
    distro="debian"
    debian=1
    tool=apt
    applist+=" "$ubuntuApps
fi

tmp=$(which yum > /dev/null 2>&1)
if [ $? -eq 0 ]; then
    distro="centos"
    centos=1
    tool=yum
    applist+=" "$centosApps
fi

tmp=$(which pacman > /dev/null 2>&1)
if [ $? -eq 0 ]; then
    distro="arch"
    arch=1
    tool=pacman
    applist+=" "$archApps
fi

if [ $distro == "" ]; then
    echon "unknown distro"
    exit 1
fi

################################################################################
# install pacman apps
################################################################################
echon "Installing on $distro ..."

echon "installing and updating apps with $tool ..."
if [ $arch -eq 1 ]; then
    sudo pacman -S $applist | tee -a $logfile
elif [ $debian -eq 1 ]; then
    sudo $tool update -y | tee -a $logfile
    sudo $tool upgrade -y | tee -a $logfile
    sudo $tool install -y $applist | tee -a $logfile
elif [ $centos -eq 1 ]; then
    sudo $tool update -y | tee -a $logfile
    sudo $tool upgrade -y | tee -a $logfile
    sudo $tool install -y --skip-broken $applist | tee -a $logfile
else
    exit 1
fi

################################################################################
# Install non package manager apps
################################################################################
non_pacman_apps

################################################################################
# install all arch AUR apps
################################################################################
if [ $arch -eq 1 ]; then
    read -r -p "Install AUR packages $archAurRepos ? [y/n] : " response
    case "$response" in
        [yY][eE][sS]|[yY])
            echon "Installing ARCH AUR packages"
            archAurInstall $archAurRepos
            ;;
        *)
            ;;
    esac
fi

################################################################################
# update dotfiles
################################################################################
read -r -p "Replace local dotfiles? (current versions will be backed up) [y/n] : " response
case "$response" in
    [yY][eE][sS]|[yY])
        backup
        echon "updating dotfiles ..."
        rcup -v -d $here/files | tee -a $logfile
        source ~/.bashrc
        ###################################
        # install vim dotfiles and packages
        ###################################
        echon "installing vim settings ... "
        vim -c 'PlugClean' +qa
        vim -c 'PlugInstall' +qa
        vim ~/.vim/vbas/Align.vba 'source %' +qa
        ;;
    *)
        echon "NOT replacing dotfiles"
        ;;
esac

################################################################################
# Add user to groups
################################################################################
echon "Adding user to groups..."
for i in ${groups[@]}; do
    addGroup $i
done

################################################################################
# clean up
################################################################################
read -r -p "Clean unused packages ($tool autoremove)? [y/n] : " response
case "$response" in
    [yY][eE][sS]|[yY])
        sudo $tool autoremove
        ;;
    *)
        echon "Not cleaning packages"
        ;;
esac
