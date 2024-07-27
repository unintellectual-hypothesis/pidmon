# v3.0
* Opt: Rewrote the whole mem-features files with C++ and compiled with clang++ -O3 + LTO
* Opt: [Readjust Userspace LMKD and vm.swappiness values](https://blog.51cto.com/u_16213570/9370516)
* Opt: Use LZ4 as default ZRAM compression algorithm; LZ0 is only sufficient on MIUI/HyperOS based ROMS
* Opt: Don't change the vm.min_free_kbytes parameter and just let the system handle it
* Fixed: Swapfile size doesn't change changing in on the configuration file after reboot
* Fixed: Filesystem Cache Control doesn't start
* Fixed: LMKD minfree levels doesn't execute properly
* Fixed: ZRAM size doesn't change from the configuration file due to late unlock
* Add: New option in configuration file to disable mi_reclaim parameter on MIUI/HyperOS based ROMS to reduce CPU overhead (mi_reclaim may improve swapping efficiency, so try experimenting with it and see what's the best option for your workload)
* Add: New option in the configuration file to disable Dynamic Swappiness and VFS Cache Pressure based on CPU and I/O load