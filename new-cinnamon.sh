#bin/bash

Main() {
    local dotfiles=https://github.com/endeavouros-team/DE-theming.git
    local greeter=https://github.com/endeavouros-team/EndeavourOS-archiso/raw/master/airootfs/etc/lightdm/lightdm-gtk-greeter.conf
    local packages=(
        arc-gtk-theme
        arc-x-icons-theme
        kalu
        lightdm
        lightdm-gtk-greeter
        lightdm-gtk-greeter-settings
    )
    local greeterfile=$(basename $greeter)

    local workdir=$(mktemp)
    pushd $workdir >/dev/null           # doing all here at remporary folder

    echo "******* Installing EndeavourOS Theming for Cinnamon *******"

    # echo "******* Getting theme packages installed now: *******" && sleep 1
    sudo pacman -S "${packages[@]}" --noconfirm --needed >& /dev/null

    # echo "******* setting up theme for Light-DM: *******" && sleep 1
    wget -q --timeout=10 $greeter && {
        sudo cp $greeterfile /etc/lightdm/
        rm $greeterfile
    } || {
        echo "Error: sorry, unable to fetch $greeterfile" >&2
        return 1
    }

    # echo "******* cloning dotfiles for EndeavourOS - Cinnamon Theming *******" && sleep 1
    git clone $dotfiles >& /dev/null
    cd dotfiles
    sudo cp -R endeavouros /usr/share/
    rm -R rm ~/.config/dbus/user ~/.cinnamon ~/.fontconfig ~/.icons ~/.local/share/cinnamon
    cp -R CINNAMON/. ~/
    dconf load / /dev/null
    rm -rf $workdir

    # echo "******* All Done --- restarting Desktop Manager *******"
    # echo "******* Please login again and enjoy EndeavourOS Theming! *******"

    yad --title="Restarting Desktop Manager" \
        --text="All done --- please login again and enjoy new EndeavourOS Theming!" \
        --width=400 --height=100 \
        --button="Restart Desktop Manager":0

    sudo systemctl restart lightdm

}

Main "$@"
