#!/bin/bash

# *********PRE-STEPS WHICH MUST BE DONE*********
# Before continuing, make sure to have Git setup in order
# to clone this repo with SSH. The steps include:
#
# $ git config --global user.name "kuta"
# $ git config --global user.email "284247095+notKuta@users.noreply.github.com"
# $ git config --global core.editor nvim
# $ git config --global init.defaultBranch main
#
# $ ssh-keygen
# Then, after running `ssh-keygen`, make sure to save your new public key in
# GitHub, found under settings, in order to run:
# $ git clone ...
# **********************************************

### Set up logging ###
exec 1> >(tee "stdout.log")
exec 2> >(tee "stderr.log")

case $(cat /etc/hostname) in
    "poseidon")
        # printf "Hello! This is Poseidon speaking! :D\n"
        ./first-setup-stow.sh
        git reset --hard
        # This installs packages from a list, while not reinstalling previously
        # installed packages that are already up-to-date
        sudo pacman -S --needed - < ../pkgs/pkglist-poseidon.txt
        sudo pacman -S --asdeps ntsync-autoload

        # Systemd Units
        # Remember; not specifiying the end of a daemon implies
        # That is ends with `.service`
        sudo systemctl enable plasmalogin
        sudo systemctl enable cups --now
        sudo systemctl enable avahi-daemon --now
        sudo systemctl enable ufw --now
        sudo systemctl enable reflector.timer --now
        sudo systemctl enable fstrim.timer --now
        sudo systemctl enable btrfs-scrub@-.timer --now
        sudo systemctl enable systemd-timesyncd --now
        sudo systemctl enable snapper-cleanup --now

        # Firewall / Printer Set-up
        sudo ufw default deny
        sudo ufw allow from 192.168.4.0/24
        sudo ufw allow 5353/udp comment "Avahi; Printer Discovery"
        sudo ufw enable

        # SystemD Resolved DNS
        ln -sf ../run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

        # Build Paru from the AUR
        # mkdir -p /home/$SUDO_USER/Projects
        # cd /home/$SUDO_USER/Projects
        mkdir -p ~/Projects
        cd ~/Projects
        git clone https://aur.archlinux.org/paru.git
        cd paru
        less PKGBUILD
        makepkg -sirc

        # Install rest of AUR packages w/ Paru
        # Extra commands needed as `paru-debug` will show up in the list
        # which is not on the AUR which results in an error
        paru -Ta - < ../pkgs/foreignpkglist-poseidon.txt > ../pkgs/tmp.txt
        paru -S --needed - < ../pkgs/tmp.txt
        rm ../pkgs/tmp.txt

        # Needed to create new Snapper configuration as the @snapshots subvolume is already
        # mounted; in the initial script could not mount the snapshots subvolume 'til after this
        # step but need more time
        sudo umount -R /.snapshots && sudo rm -r /.snapshots
        sudo snapper -c root create-config /.snapshots
        sudo umount -R /.snapshots && sudo btrfs subvolume delete /.snapshots
        sudo mkdir /.snapshots && mount -o compress=zstd,subvol=/@snapshots /dev/mapper/root /.snapshots

        # Run *AFTER* installing arch-update i.e. after installing
        # our foreign, AUR packages
        arch-update --check --enable
        limine-install
        limine-update
        limine-snapper-sync

        # Create BTRFS swapfile for zswap use (zswap is automatically enabled in Arch kernels)
        sudo btrfs filesystem mkswapfile --size $(free -m | grep "Mem:" | awk '{print $2}')m --uuid clear /.swap/swapfile
        echo "/.swap/swapfile none swap defaults 0 0" | sudo tee -a /etc/fstab > /dev/null

        # Adds old kernel parameters to new ones and to be read from `/etc/kernel/cmdline`
        # Which is a more universal placement for kernel parameters
        KERNELCMDLINE=$( sudo cat /boot/EFI/arch-limine/limine.conf | grep "cmdline:" | sed -n -e 's/^.*:\ //p' )
        NEWKERNELCMDLINE="${KERNELCMDLINE} splash quiet zswap.max_pool_percent=30"
        echo ${NEWKERNELCMDLINE} | sudo tee /etc/kernel/cmdline > /dev/null

        # Removes obsolete EFI/boot entries *AFTER* `limine-mkinitcpio-hook` generates
        # its own, more organized entries
        sudo rm -r /boot/EFI/arch-limine

        # Automatically enable preloading of NVIDIA modules in order to see the plymouth
        # screen actually show up; NOTE: this breaks hibernation; also preloads the k10temp
        # module which is used for reading wattage / temperature of AMD CPUs thru MangoHud
        WANTEDMODULES="MODULES=( nvidia nvidia_modeset nvidia_uvm nvidia_drm k10temp )"
        sudo sed "s/^MODULES=.*/${WANTEDMODULES}/" /etc/mkinitcpio.conf | sudo tee /etc/tmp3.conf && sudo mv /etc/tmp3.conf /etc/mkinitcpio.conf

        konsave --import-profile ~/.config/main.knsv
        konsave --apply main

        printf "\nInstallation is done!\n\nRestart the system!\n"
        # reboot

        ;;
    "neptune")
        ;;
    *)
        printf "ERROR: hostname does not match with any of the preconfigured\n"
        printf "options. These include: "poseidon" (desktop) and "neptune" (laptop)\n."
        printf "Fix this if you wish to continue running this script.\n"
        exit 1
        ;;
esac

