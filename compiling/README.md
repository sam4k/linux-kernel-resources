# Compiling
General notes and resources on compiling the Linux kernel from source.

## Contents
* [Files](#files)
* [Kernel Build Process](#kernel-build-process)
  * [Cleanup](#cleanup)
  * [Recompiling In-Tree Modules](#recompiling-in-tree-modules)
* [Building External Modules](#building-external-modules)
* [Resources](#resources)

## Files
* [build_release.sh](compiling/build_release.sh): little script that by default fetches & builds the latest kernel release using defconfig. additional argument to specify a specific kernel version or supply a kernel config.

## Kernel Build Process
1. Install the dependencies  
  * Debian: `$ sudo apt-get install git fakeroot build-essential ncurses-dev xz-utils libssl-dev bc flex libelf-dev bison dwarves`  
2. Grab a kernel release from [kernel.org](https://kernel.org)  
  * `$ wget https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.17.3.tar.xz`
3. Extract & change into release directory  
  * `$ tar xvf linux-5.17.3.tar.xz && cd linux-5.17.3.tar.xz`
4. Decide on your kernel config, saving it as `.config` in your build root  
  * you can copy your current `.config`; can be found at `/boot/config`, `/boot/config-$(uname -r)` or `/proc/config.gz`
  * `make defconfig` creates a `.config` file with default options for your `$ARCH`; typically stored in `arch/$ARCH/configs/`
  * `make menuconfig` will let you tweak your `.config` with an ncurses GUI; if no `.config` exists it'll use `defconfig`
  * there's several more options include `make config`, `make oldconfig`, `make savedefconfig` etc.
5. Now it's time to start building the kernel!  
  * `$ make -j($nproc)`
  * `-j` lets us specify number of simultaneous jobs & `nproc` returns the number of processing units available
   
At this point everything is compiled and built, you can find your image over in `arch/x86/boot/bzImage`. 
So if you want to use this image for a VM or other shenanigans, gg, we're done here!

6. If you want to boot this kernel on the host, let's first install the modules and then the kernel:  
  * `$ sudo make modules_install && sudo make install`

### Cleanup
If at any point you've scuffed up or want to start from a blank slate:  
  * `$ make clean` will "remove most generated files but keep the config and enough build support to build external modules"
  * `$ make mrproper` will "delete the current configuration, and all generated files"

### Recompiling In-Tree Modules
Working from "Kernel Build Process" step 5 (to avoid taint & signing issues), if we want to recompile a particular module, we can do so by running the same commands but target the module we're interested in:  
  1. `$ make M=net/tipc` to compile the module
  2. `$ sudo make M=net/tipc modules_install` to install it 

### Building An External Module
WIP. For now, consult [kernel.org/doc "Building External Modules"](https://www.kernel.org/doc/html/latest/kbuild/modules.html).

## Resources
* [kernel.org](https://kernel.org) for Linux kernel releases
* [kernel.org/doc "Building External Modules"](https://www.kernel.org/doc/html/latest/kbuild/modules.html) (latest)
