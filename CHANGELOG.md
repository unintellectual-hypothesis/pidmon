# v3.0
* Opt: Rewritten features that run in the background using C++ and compiled with O3 + LTO (I might rewrite the whole module script with C++ for performance purposes but this is just an early phase)
* Opt: [Readjust Userspace LMKD and vm.swappiness values](https://blog.51cto.com/u_16213570/9370516)
* Opt: Use LZ4 as default ZRAM compression algorithm; LZ0 is only sufficient on MIUI/HyperOS-based ROMS
* Opt: Don't change the vm.min_free_kbytes parameter and just let the system handle it
* Fixed: Swapfile size doesn't change when changing it on the configuration file after reboot
* Fixed: Filesystem Cache Control doesn't start
* Fixed: LMKD minfree levels doesn't execute properly
* Fixed: ZRAM size doesn't change from the configuration file due to late unlock
* Add: New option in configuration file to disable mi_reclaim parameter on MIUI/HyperOS-based ROMS to reduce CPU overhead (mi_reclaim may improve swapping efficiency, so try experimenting with it and see what's the best option for your workload)
* Add: New option in the configuration file to disable Dynamic Swappiness and VFS Cache Pressure based on CPU and I/O load
* Add: New ZRAM size option 3.5GB; 33% of 4GB is ~1.3GB, if we multiply it by the compression ratio 2.8 we get ~3.7GB, personally 3.5GB will be enough for 4GB variants in most cases.
