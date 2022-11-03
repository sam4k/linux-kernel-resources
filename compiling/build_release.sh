#!/usr/bin/env bash

set -u # exit if we use undefined vars
# default value for kernel version is latest release, pulled from kernel.org homepage (yikes, ik)
KVERS=$(curl -s https://www.kernel.org | grep -A1 latest_link | tail -n1 | egrep -o '>[^<]+' | egrep -o '[^>]+')
CONFIG="defconfig"
OUT=$KVERS

# exit_on_fail(str error_message)
exit_on_fail() {
    if [ $? -ne 0 ]; then
        echo $1
        exit 1
    fi
}

sanitise_config() {
    echo "[+] Sanitising Ubuntu kconfig for self compilation"
    sed -i -e '/CONFIG_SYSTEM_TRUSTED_KEYS=/ s/=.*/=""/' .config
    sed -i -e '/CONFIG_SYSTEM_REVOCATION_KEYS=/ s/=.*/=""/' .config
}

# parse our arguments
while getopts o:v:c: flag
do
    case "${flag}" in
        o) OUT=${OPTARG};;    # output: folder to download & build source in
        v) KVERS=${OPTARG};;  # kernel version: optionally specify a kernel version
        c) CONFIG=${OPTARG};; # kernel config: optionally specify an ABSOLUTE path to kernel config to use
    esac
done

MAJOR=${KVERS%%.*} # grabs the major version, i.e first number before the first dot
KURL=https://cdn.kernel.org/pub/linux/kernel/v$MAJOR.x/linux-$KVERS.tar.xz

echo "[+] Entering $OUT"
mkdir -p $OUT
cd $OUT

echo "[+] Downloading release from $KURL"
wget -q $KURL
exit_on_fail "[!] error: wget $KURL"

echo "[+] Extracting linux-$KVERS.tar.xz & entering build root"
tar xf linux-$KVERS.tar.xz && cd linux-$KVERS

if [ "$CONFIG" = "defconfig" ]; then
    echo "[+] Using defconfig"
    make defconfig
    exit_on_fail "[!] error: make defconfig"
else
    echo "[+] Using .config from $CONFIG"
    cp $CONFIG .config
    exit_on_fail "[!] error: cp $CONFIG .config"

    # if we use an ubuntu kconfig, let's sanitise it
    if [[ "$CONFIG" == "/boot/config-"*"-generic" ]]; then
      sanitise_config
    fi

    make oldconfig
    exit_on_fail "[!] error: make oldconfig"
fi

echo "[+] Building the kernel"
make -j$(nproc)
