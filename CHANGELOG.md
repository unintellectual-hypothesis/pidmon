# v3.1
* Opt: Set default swappiness value to 200 IF AND ONLY IF: ZRAM size ≤ 50% of RAM, ZRAM compression algorithm is lz4, and hybrid swap is turned off
* Opt: Disable ro.lmk.thrashing_limit_critical on some custom ROMS; use default thrashing limit userspace LMKD configuration parameter
* Add: Support for /proc/sys/vm/swappiness_nosys parameter on some kernels | Thanks to @Marianauwul


# v3.0
* Opt: Rewritten features that run in the background using C++ and compiled with O3 + LTO for improved execution performance (Still an early phase)
* Opt: [Readjust Userspace LMKD and vm.swappiness values](https://blog.51cto.com/u_16213570/9370516)
* Opt: [Swappiness is set to 60 and page-cluster is set to 3 if user only uses swapfile](https://www.slideshare.net/slideshow/extreme-linux-performance-monitoring-and-tuning/9822577) (If dynamic memory system is enabled, swappiness/vfs_cache_pressure is set to: 40/180 on high load; 60/150 on medium load; 85/110 on low load).
* Opt: Use LZ4 as default ZRAM compression algorithm; LZ0 is only sufficient on MIUI/HyperOS-based ROMS
* Opt: Don't change the vm.min_free_kbytes parameter and just let the system handle it
* Fixed: Swapfile size doesn't change when changing it on the configuration file after reboot
* Fixed: Filesystem Cache Control doesn't start
* Fixed: LMKD minfree levels doesn't execute properly
* Fixed: ZRAM size doesn't change from the configuration file due to late unlock
* Add: New option in configuration file to disable mi_reclaim parameter on MIUI/HyperOS-based ROMS to reduce CPU overhead (mi_reclaim may improve swapping efficiency, so try experimenting with it and see what's the best option for your workload)
* Add: New option in the configuration file to disable Dynamic Swappiness and VFS Cache Pressure based on CPU and I/O load
* Add: New ZRAM size option 3.5GB; 33% of 4GB is ~1.3GB, if we multiply it by the compression ratio 2.8 we get ~3.7GB, personally 3.5GB will be enough for 4GB variants in most cases.
