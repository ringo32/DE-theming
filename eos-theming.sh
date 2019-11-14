#!/bin/bash

# EndeavourOS Theming installer
#
# Usage: $0 <DE-name>

MSG() {
    local title="$1"
    local text="$2"
    yad --title="$title" --text="$text" \
        --width=500 --height=100 --button=yad-quit:0
}

DIE() {
    MSG "Error" "$progname: $1"
    test -n "$workdir" && rm -rf $workdir
    exit 1
}

UserFiles_XFCE()
{
    local mousepaddconf=https://github.com/endeavouros-team/liveuser-desktop-settings/raw/master/dconf/mousepad.dconf
    wget -q --timeout=10 $mousepaddconf || DIE "sorry, unable to fetch mousepad.dconf."
    rm -rf ~/.config/Thunar ~/.config/qt5ct ~/.config/xfce4
    cp -rf $dotfiles_dirname/XFCE/. ~/
    dconf load / < mousepad.dconf
    # dbus-launch dconf load / < mousepad.dconf   # why this ???
}

UserFiles_CINNAMON()
{
    rm -f ~/.config/dbus/user
    rm -rf ~/.cinnamon ~/.fontconfig ~/.icons ~/.local/share/cinnamon
    cp -rf $dotfiles_dirname/CINNAMON/. ~/
    dconf load / < $dotfiles_dirname/cinnamon.dconf
}

Main() {
    local DE="$1"
    local progname="eos-theming.sh"
    case "$DE" in
        XFCE | CINNAMON) ;;
        "") DIE "give desktop name (one of: XFCE, CINNAMON)." ;;
        *) DIE "unsupported desktop '$DE'" ;;
    esac
    local dotfiles_dirname=DE-theming
    local dotfiles=https://github.com/endeavouros-team/$dotfiles_dirname.git
    local greeter=https://github.com/endeavouros-team/EndeavourOS-archiso/raw/master/airootfs/etc/lightdm/lightdm-gtk-greeter.conf
    local greeterfile=$(basename $greeter)
    local packages=()
    local required_pkgs=(
        arc-gtk-theme
        arc-x-icons-theme
        lightdm
        lightdm-gtk-greeter
        lightdm-gtk-greeter-settings
    )
    local sudo_cmds
    local workdir=$(mktemp -d)
    local xx

    # Check which of the required packages is not installed.
    for xx in "${required_pkgs[@]}" ; do
        pacman -Q $xx >& /dev/null || packages+=("$xx")
    done

    pushd $workdir >/dev/null           # do everything here at temporary folder

    echo "Fetching $DE theming files."
    wget -q --timeout=10 $greeter       || DIE "sorry, unable to fetch $greeterfile."

    git clone $dotfiles >& /dev/null    || DIE "sorry, unable to fetch theming dotfiles."

    # Now we have all the required files.

    if [ -n "$packages" ] ; then
        sudo_cmds="pacman -S ${packages[*]} --noconfirm >& /dev/null"       # install required packages
    fi
    diff $greeterfile /etc/lightdm/$greeterfile >& /dev/null || {
        test -n "$sudo_cmds" && sudo_cmds+=" ; "
        sudo_cmds+="cp $PWD/$greeterfile /etc/lightdm/"                     # put greeter in place
    }
    if [ ! -d /usr/share/endeavouros ] ; then
        test -n "$sudo_cmds" && sudo_cmds+=" ; "
        sudo_cmds+="mkdir -p /usr/share/endeavouros"                        # make sure folder exists
    fi
    for xx in $PWD/$dotfiles_dirname/endeavouros/* ; do
        diff $xx /usr/share/endeavouros >& /dev/null || {
            test -n "$sudo_cmds" && sudo_cmds+=" ; "
            sudo_cmds+="cp $xx /usr/share/endeavouros"                      # put pictures in place
        }
    done

    if [ -n "$sudo_cmds" ] ; then
        echo "Installing system files."
        su -c "$sudo_cmds"
    fi

    echo "Installing $DE user files."
    case "$DE" in
        XFCE)     UserFiles_XFCE ;;
        CINNAMON) UserFiles_CINNAMON ;;
    esac

    popd >/dev/null

    rm -rf $workdir

    echo "All done -- please reboot and enjoy the default EndeavourOS $DE Theming!"
}

Main "$@"
