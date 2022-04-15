# Debugging
Alright, hopefully this will be one of the more fleshed out categories. We'll touch on shortcuts and gotchas for debugging the Linux kernel, as well as including some curated resources.

## Contents
* [Getting Set Up (GDB)](#getting-set-up-gdb)
  * [GDB + VM](#gdb-vm)
    * [QEMU](#qemu)
    * [VMWare](#vmware)
  * [Symbols & KASLR](#symbols-kaslr)
    * [Loadable Modules](#loadable-modules)
* [Useful GDB Commands](#useful-gdb-commands)
* [Resources](#resources)

## Getting Set Up (GDB)
First things, we want to get our kernel debugging environment setup!

As always, I'll recommend [GEF](https://gef.readthedocs.io/en/master/) (GDB Enhanced Features) cos let's not forget gdb is like 36 years old and your boy needs some colours up in his CLI. Beyond just colours, gef has a suite of QoL features.

### GDB + VM
The easiest way to do this is debugging a guest VM, using the included gdbstub (picture a mini gdb sever included in your guest).

Sidenote: if your guest is a different architecture to your host, don't forget to use `gdb-multiarch`! 

##### QEMU
On QEMU, you just need to add the `-s` flag to your QEMU launch options.
* `-s`: listens for an incoming gdb connection on your host's localhost:1234
* `-gdb tcp:127.0.0.1:1234`: `-s` is actually an alias for this command, which can be used to tweak interface & port
* `-S`: QEMU will not start the guest until you `continue` via gdb with this option enabled

The flexibility of the `-gdb` command means you can put the listener on your vmnet interface, meaning you can debug one guess from another guess. For example, my work laptop is an M1 MacBook and there's no gdb build, so I debug guest-to-guest this way.

##### VMWare
For VMWare, you need to edit your VM's config and add some options. This is the `*.vmx` in your VMs directory, options are:
* `debugStub.listen.guest32 = "TRUE"`: setup gdb listener for 32-bit guest, defaults to `localhost:8832`
* `debugStub.listen.guest64 = "TRUE"`: setup gdb listener for 64-bit guest, defaults to `localhost:8864`

There's also the following additional options:
* `debugStub.listen.guest32.remote = "TRUE"`: enable remote debugging, i.e from another VM/machine (guess this switches interface)
* `debugStub.listen.guest64.remote = "TRUE"`: enable remote debugging, i.e from another VM/machine (guess this switches interface)
* `debugStub.port.guest32 = "55555"`: specify listener port for 32-bit guest
* `debugStub.port.guest64 = "55555"`: specify listener port for 64-bit guest
* `monitor.debugOnStartGuest32 = "TRUE"`: start debugging on BIOS load for 32-bit guest
* `monitor.debugOnStartGuest64 = "TRUE"`: start debugging on BIOS load for 32-bit guest
* `debugStub.hideBreakpoints = "TRUE"`: enables hardware breakpoints instead of software breakpoints

### Symbols & KASLR
To keep our sanity, we'll also want symbols when debugging, so we need to grab a `vmlinux` with symbols. You got options:
* If you're building from source, just include `CONFIG_DEBUG_INFO=y` and optionally `CONFIG_GDB_SCRIPTS=y` and you'll find your vmlinux with debug symbols in your build root (see [compiling/README.md](compiling/README.md) for more info on building)
  * `./scripts/config -e DEBUG_INFO -e GDB_SCRIPTS` will enable these in your config with minimal fiddling
* If you're running a distro kernel, you can check your distro's repositories to see if you can pull debug symbols
  * On Ubuntu, if you update your sources and keyring [[2]](https://wiki.ubuntu.com/Debug%20Symbol%20Packages), you can pull the debug symbols by running `$ sudo apt-get install linux-image-$(uname -r)-dbgsym` and should find your `vmlinux` @ `/usr/lib/debug/boot/vmlinux-$(uname-r)`
* If for some reason you just have the compressed `vmlinuz`, that somehow has symbols, you can use the kernel source's `./scripts/extract-vmlinux /your/vmlinuz > /your/vmlinux` 

**Finally** don't forget to turn off KASLR on your *guest*! The amount of times I've forgotten this ... 
  * Add `nokaslr` to your boot options, typically via grub menu at boot 
    * grub menu can be reached by hold shift at boot, then on your kernel selection pressing `e` will allow you to edit params (these changes don't persist), and you'll want to add it to the line with other booth options like `nosplash`
  * or by editing `/etc/default/grub` and including `nokaslr` in `GRUB_CMDLINE_LINUX_DEFAULT`

#### Loadable Modules
You might notice when debugging some modules that, despire having a `vmlinux` with debug syms, you can't seem to find certain symbols. 

If the module wasn't compiled in kernel, i.e `CONFIG_YOUR_MODULE=m` instead of `=y`, then the module's base address changes each time it is loaded in (e.g. via `modprobe`). To add symbols to gdb, we need to do a couple of extra steps, **in addition to above**:
* Copy the module's `your_module.ko` from your debugging target; try `/lib/modules/$(uname -r)/kernel/`
* On your debugging target, find out the base address of the module; try `sudo grep -e "^your_module" /proc/modules`
* In your gdb session, you can now load in the module by `(gdb) add-symbol-file your_module.ko 0xAddressFromProc` - voila!

**Note:** the base address will change *each* time the module is loaded, even with KASLR disabled! 

## Useful GDB Commands 
General:
* First things first: GDB uses a C-like syntax

Structs:
* `(gdb) info types regexp` will search all type symbols matching your regex; showing which file they're defined
* `(gdb) ptype struct kernel_struct` will print out the struct definition for your kernel image 
* `(gdb) ptype /o struct kernel_struct` will also include size and offsets for each member! 
* `(gdb) p (int)&((struct kernel_struct*)0)->field_name` will print the offset in bytes for specific `field_name` in `kernel_struct`
* `(gdb) p (int)&((struct kernel_struct*)0)->field_name` will print the offset in bytes for specific `field_name` in `kernel_struct`
* `(gdb) p *(struct msg_msg*) 0xffffffff82e03db8`: cast and pretty print a `kernel_struct`  from a given address
  * `(gdb) p *(struct msg_msg*) $RAX`: or from a specific register

## Resources
1. [GEF](https://gef.readthedocs.io/en/master/)
2. [Ubuntu Wiki: Debug Symbol Packages](https://wiki.ubuntu.com/Debug%20Symbol%20Packages)
3. [OSDev Wiki: VMWare](https://wiki.osdev.org/VMware)
4. [OSDev Wiki: QEMU](https://wiki.osdev.org/QEMU)
