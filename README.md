# fog-mem-opt
Reconstructs the RAM Management of fog/wind/rain devices

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <h1>Redmi 10C Memory Management Optimization</h1>
</head>
<body>
    <div class="container">
        <div>Supports fog/wind/rain devices for 3GB/4GB/6GB and more variants (it may work well on other devices)</div>
        <br>
        <ul>
            <li>Dynamic vm.swappiness and vm.vfs_cache_pressure based on CPU and I/O load, supports both kernel with swappiness over 100 and swappiness less than 100 like the fog-kribo kernel (Configurable)</li>
            <li>Optimizes LMKD to reduce the chance of background apps being killed</li>
            <li>If ROM supports Xiaomi RAM Extension, perform small ZRAM Writeback after opening more than a certain number of apps and perform large ZRAM writeback when the phone is off (Configurable)</li>
            <li>Higher low pages-free zone with vm.extra_free_kbytes to reduce the probability of direct memory allocation (reduce random freezes during memory pressure)</li>
            <li>Injects essential libs, SystemUI, and in-display keyboard to cache and prevent it from being swapped out to ZRAM or Swapfile by the system which makes it unresponsive</li>
            <li>At least an ideal 2.8x ZRAM Compression Ratio, regardless of compression algorithm</li>
            <li><b>IF AND ONLY IF</b> UFS Health is okay, configure hybrid swap setup on /data/lswap/swapfile with swapfile being a lower priority than ZRAM, utilizing Qualcomm's PPR (swapfile size is based on RAM variants and can be turned off)</li>
            <li>Change the affinity of kswapd and oom_reaper to use power-efficient CPUs with renice, and use number of maximum CPU core to run kswapd to improve swapping performance</li>
            <li>Automatic ZRAM disksize based on RAM variants 3GB/4GB/6GB (ZRAM disksize is customizable, although setting it too high will add a CPU overhead and inefficient compressed pagecache, feel free to experiment and see which one works best for your workload)</li>
        <hr>
        <div>"Standing on the shoulders of giants"</div>
    </div>
</body>
</html>
