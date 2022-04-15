# Patching
A (currently) minimal set of resources on patching the Linux kernel; with a sprinkle on submissions/vuln disclosure etc.

## Contents
* [diff 101](#diff-101)  
  * [unified-format](#unified-format)
* [Resources](#resources)

## diff 101
* `diff -u old.c new.c > new.patch`: generate a diff between 2 files, storing the result in `new.patch`
  * `-u` tells `diff` to use the unified format, providing default 3 lines of context to changes
* `diff -Naur old/ new/`: diff an entire dir, recursively
  * `-N` treats missing files as empty for diff purposes
  * `-a` treats all files as text
  * `-r` recursively compares sub directories
* `patch -p0 < new.patch` will apply the new patch from the current directory, stripping 0 directories from unified format header
  * `-p0`: patches are applied from the current dir, using the path in the unified format header; this arg lets us strip directory levels by specifying the number to strip 

### Unified Format
Using `diff -u` will output patches using the unified format, which looks like this:

``` sh
$ diff -u monitor.c monitor_patched.c 
--- monitor.c   2021-03-11 13:19:18.000000000 +0000
+++ monitor_patched.c 2022-04-06 19:25:27.449661568 +0100
@@ -503,8 +503,10 @@
        /* Cache current domain record for later use */
        dom_bef.member_cnt = 0;
        dom = peer->domain;
-       if (dom)
+       if (dom) {
+               printk("printk debugging ftw!\n")
                memcpy(&dom_bef, dom, dom->len);
+       }
 
        /* Transform and store received domain record */
        if (!dom || (dom->len < new_dlen)) {
```

* `---` prefix indicates header, showing original file & metadata
* `+++` prefix indicates header, showing the new file & metadata
* `@@ ... @@` indicates the start of a new hunk of changes
  * `-503,8` the first set tells us this hunk starts from line 503 from the original file and shows 8 lines from it
  * `+_503,10` the second set tells us this hunk starts from line 503 from the new file and shows 10 lines from it
  * `-` prefix indicates lines removed from original file
  * `+` prefix indicates lines new to the new file

## Resources
* [kernel.org/docs: "Submitting patches: the essential guide to getting your code into the kernel"](https://www.kernel.org/doc/html/latest/process/submitting-patches.html)
* [sam4k.com: "A Dummy's Guide to Disclosing Linux Kernel Vulnerabilities"](https://sam4k.com/a-dummys-guide-to-disclosing-linux-kernel-vulnerabilities/)
