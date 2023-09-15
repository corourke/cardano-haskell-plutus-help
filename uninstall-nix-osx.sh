#!/bin/bash


# !!WARNING!!
# This will DELETE all efforts you have put into configuring nix
# Have a look through everything that gets deleted / copied over

# derived from https://github.com/renzwo/cardano-plutus-apps-install-m1/blob/main/uninstall-nix-osx.sh
# updated 14-Sept-2023 by https://github.com/corourke
# See: https://nixos.org/manual/nix/stable/installation/uninstall

set -x
nix-env -e '.*'

rm -rf $HOME/.nix-*
rm -rf $HOME/.config/nixpkgs
rm -rf $HOME/.cache/nix
rm -rf $HOME/.nixpkgs

sudo rm -rf /etc/nix 

# Nix was installed single user, we are done
[ ! -f /Library/LaunchDaemons/org.nixos.nix-daemon.plist ] && exit 0


if [ -f /Library/LaunchDaemons/org.nixos.nix-daemon.plist ]; then
    sudo launchctl unload /Library/LaunchDaemons/org.nixos.nix-daemon.plist
    sudo rm /Library/LaunchDaemons/org.nixos.nix-daemon.plist
fi

if [ -f /Library/LaunchDaemons/org.nixos.nix-daemon.plist ]; then
    sudo launchctl unload /Library/LaunchDaemons/org.nixos.darwin-store.plist
    sudo rm /Library/LaunchDaemons/org.nixos.darwin-store.plist
fi

if [ -f /etc/profile.backup-before-nix ]; then
    sudo mv /etc/profile.backup-before-nix /etc/profile
fi

if [ -f /etc/bashrc.backup-before-nix ]; then
    sudo mv /etc/bashrc.backup-before-nix /etc/bashrc
fi

if [ -f /etc/bash.bashrc.backup-before-nix ]; then
    sudo mv /etc/bash.bashrc.backup-before-nix /etc/bash.bashrc
fi

if [ -f /etc/zshrc.backup-before-nix ]; then
    sudo mv /etc/zshrc.backup-before-nix /etc/zshrc
fi

USERS=$(sudo dscl . list /Users | grep _nixbld)

for USER in $USERS; do
    sudo /usr/bin/dscl . -delete "/Users/$USER"
    sudo /usr/bin/dscl . -delete /Groups/staff GroupMembership $USER;
done

sudo /usr/bin/dscl . -delete "/Groups/nixbld"
sudo rm -rf /var/root/.nix-*
sudo rm -rf /var/root/.cache/nix

sudo diskutil apfs deleteVolume /nix


# useful for finding hanging links
# $ find . -type l -maxdepth 5 ! -exec test -e {} \; -print 2>/dev/null | xargs -I {} sh -c 'file -b {} | grep nix && echo {}'

# Manual steps
# Edit fstab using sudo vifs to remove the line mounting the Nix Store volume on /nix, 
# which looks like:
#   UUID=<uuid> /nix apfs rw,noauto,nobrowse,suid,owners or 
#   LABEL=Nix\040Store /nix apfs rw,nobrowse. 
# This will prevent automatic mounting of the Nix Store volume.
#
# Edit /etc/synthetic.conf to remove the nix line. 
# If this is the only line in the file you can remove it entirely, sudo rm /etc/synthetic.conf. 
# This will prevent the creation of the empty /nix directory to provide a mountpoint 
# for the Nix Store volume.
