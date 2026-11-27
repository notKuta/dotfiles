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

### Gather variables from past script

part_root=$(sudo cat /root/partition-root.txt)

### Set up logging ###
exec 1> >(tee "stdout.log")
exec 2> >(tee "stderr.log")

case $(cat /etc/hostname) in
    "poseidon")
        # printf "Hello! This is Poseidon speaking! :D\n"
        ./post-install-stow.sh
        git reset --hard
        # This installs packages from a list, while not reinstalling previously
        # installed packages that are already up-to-date
        sudo pacman -Syu
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
        sudo ln -sf ../run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

        # Build Paru from the AUR
        # mkdir -p /home/$SUDO_USER/Projects
        # cd /home/$SUDO_USER/Projects
        mkdir -p ~/Projects
        cd ~/Projects
        git clone https://aur.archlinux.org/paru.git
        cd paru
        less PKGBUILD
        read -p "Press Enter to continue..." </dev/tty
        clear
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
        # Currently, Snapper config is stored in `/etc/snapper/config/*` and its global counterpart
        # is in `/etc/conf.d/snapper` where both are currently under version control w/ stow under
        # ~/dotfiles

        # sudo umount -R /.snapshots && sudo rm -r /.snapshots
        # sudo snapper -c root create-config /.snapshots
        # sudo umount -R /.snapshots && sudo btrfs subvolume delete /.snapshots
        # sudo mkdir /.snapshots && mount -o compress=zstd,subvol=/@snapshots /dev/mapper/root /.snapshots

        # Adds support OverlayFS in order for snapshots to act as a Live CD environment to
        # try out different packages or other things without affecting the current environment
        # as all changes exist within RAM
        desiredHookLine="HOOKS=(base systemd autodetect microcode modconf kms keyboard sd-vconsole block sd-encrypt filesystems sd-btrfs-overlayfs fsck)"
        sed "s/^HOOKS=.*/${desiredHookLine}/" /etc/mkinitcpio.conf > /etc/tmp4.conf && mv /etc/tmp4.conf /etc/mkinitcpio.conf

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

        ####### TPM ENCRYPTION #########

        clear

        printf "Generating recovery key for LUKS volume...\n\n"
        sudo systemd-cryptenroll ${part_root} --recovery-key

        printf "Make sure to store your recovery key in a secure location.\n"
        printf "This is what you will use if your TPM device cannot authenticate\n"
        printf "properly e.g. if one of the PCR policies gets triggered. If\n"
        printf "you do not store these, then you will be locked out of your computer.\n\n"

        read -p "Press Enter to continue IF everything looks good..." </dev/tty

        clear

        sudo systemd-cryptenroll ${part_root}

        printf "Which keyslots would you like to wipe before enrolling TPM?\n"
        printf "Enter the keyslot number ie '1', '2' etc. OR 'empty' if you\n"
        printf "do not want to wipe a keyslot: "
        read keyslotAnswer
        : ${keyslotAnswer:?"answer cannot be nothing"}

        sudo systemd-cryptenroll ${part_root} --wipe-slot=${keyslotAnswer} --tpm2-device=auto --tpm2-pcrs=4+12+15:sha256=0000000000000000000000000000000000000000000000000000000000000000

        # Konsave to apply Plasma settings
        konsave --import-profile ~/.config/main.knsv
        konsave --apply main

        clear

        printf "Installation is done!\n\nRestart the system!\n\n"
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

sudo rm /root/partition-root.txt
