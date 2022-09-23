#!/usr/bin/env bash
: '
This is a small script to run on an Ubuntu guest
to download debugging symbols for the current kernel image.

The vmlinux w/ debugging symbols, which you want to open in gdb
on your host, is copied to your guests $HOME/vmlinux-$(uname -r)

No faff, just $ ./install_ksysms.sh
'

# vars
DDEBS=/etc/apt/sources.list.d/ddebs.list
KSYMS=linux-image-$(uname -r)-dbgsym

# exit_on_fail(str error_message)
exit_on_fail() {
    if [ $? -ne 0 ]; then
        echo $1
        exit 1
    fi
}

printf "[+] Adding dbysm repos to $DDEBS:\n"
echo "deb http://ddebs.ubuntu.com $(lsb_release -cs) main restricted universe multiverse
deb http://ddebs.ubuntu.com $(lsb_release -cs)-updates main restricted universe multiverse
deb http://ddebs.ubuntu.com $(lsb_release -cs)-proposed main restricted universe multiverse" | \
sudo tee -a $DDEBS
exit_on_fail "[!] error: sudo tee -a $DDEBS"

printf "\n\n[+] Importing the debug symbol archive signing key\n"
sudo apt install ubuntu-dbgsym-keyring
exit_on_fail "[!] error: sudo apt install ubuntu-dbgsym-keyring"

printf "\n\n[+] Updating package list with new debug packages\n"
sudo apt-get update
exit_on_fail "[!] error: sudo apt-get update"

printf "\n\n[+] Installing $KSYMS\n"
sudo apt-get install $KSYMS
exit_on_fail "[!] error: sudo apt-get install $KSYMS"

printf "\n\n[+] Copying user owned vmlinux to $HOME/vmlinux-$(uname -r)\n"
cp /usr/lib/debug/boot/vmlinux-$(uname -r) $HOME
exit_on_fail "[!] error: failed to copy vmlinux"
sudo chown $USER $HOME/vmlinux-$(uname -r)
exit_on_fail "[!] error: failed to chown vmlinux"
