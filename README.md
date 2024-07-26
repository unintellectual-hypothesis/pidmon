# Redmi 10/10C/10 Power Memory Management Optimization
Supports fog devices for 3GB/4GB/6GB and more variants (it may work well on other devices)
 
"Standing on the shoulders of giants"

## Features?
- Dynamic vm.swappiness and vm.vfs_cache_pressure based on CPU and I/O load, supports both kernel with swappiness over 100 and swappiness less than 100 like the fog-kribo kernel (Configurable)
- Optimizes LMKD to reduce the chance of background apps being killed
- If ROM supports Xiaomi RAM Extension and /sys/block/zram0/writeback, perform small ZRAM Writeback after opening more than a certain number of apps and perform large ZRAM writeback when the phone is off (Configurable)
- Higher low pages-free zone with vm.extra_free_kbytes to reduce the probability of direct memory allocation (reduce random freezes during memory pressure)
- Injects essential libs and SystemUI to cache and prevent them from being swapped out to ZRAM or Swapfile by the kernel which makes the system unresponsive
- At least an ideal 2.8x ZRAM Compression Ratio, regardless of compression algorithm
- Configure hybrid swap setup on /data/lswap/swapfile with swapfile being a lower priority than ZRAM, utilizing Qualcomm's PPR (Hybrid swap setup is by default turned off and can be turned on in the config file)
-  Change the affinity of kswapd and oom_reaper to use power-efficient CPUs with renice, and use number of maximum CPU core to run kswapd to improve swapping performance
- Automatic ZRAM disksize based on RAM variants 3GB/4GB/6GB (ZRAM disksize is customizable, but setting it too high will add a CPU overhead and inefficient compressed pagecache)
- Set higher CUR_MAX_CACHED_PROCESSES. For more info check out [here](https://github.com/agnostic-apollo/Android-Docs/blob/master/en/docs/apps/processes/phantom-cached-and-empty-processes.md).

## 특징?
- CPU 및 I/O 부하에 기반한 동적 vm.swappiness 및 vm.vfs_cache_pressure, 100 이상의 스와핑을 가진 커널과 fog-kribo 커널과 같은 100 미만의 스와핑을 모두 지원 (구성 가능).
- 백그라운드 앱이 종료될 가능성을 줄이기 위해 LMKD 최적화
- ROM이 Xiaomi RAM 확장 및 /sys/block/zram0/writeback을 지원하는 경우, 일정 수 이상의 앱을 연 후 작은 ZRAM 쓰기백을 수행하고 전화기가 꺼져있을 때 큰 ZRAM 쓰기백을 수행합니다(구성 가능).
- 직접 메모리 할당 확률을 줄이기 위해 vm.extra_free_kbytes로 낮은 페이지 프리 영역을 높여 메모리 압박 시 무작위 정지 감소
- 필수 라이브러리, SystemUI 및 디스플레이 내 키보드를 캐싱하여 시스템에서 ZRAM 또는 스왑파일로 교체하여 응답하지 않는 것을 방지합니다.
- 압축 알고리즘에 관계없이 최소 2.8배의 이상적인 ZRAM 압축률 제공
- 데이터/lswap/swap파일에 하이브리드 스왑 설정을 구성하고 스왑파일의 우선순위를 ZRAM보다 낮게 설정하여 Qualcomm의 PPR을 활용 (하이브리드 스왑 설정은 기본적으로 꺼져 있으며 구성 파일에서 켜기 가능).
- 전력 효율이 높은 CPU를 사용하도록 kswapd 및 oom_reaper의 선호도를 변경하고, 최대 CPU 코어 수를 사용하여 kswapd를 실행하여 스왑 성능을 개선합니다.
- 3GB/4GB/6GB RAM 변형에 따른 자동 ZRAM 디스크 크기 설정 (ZRAM 디스크 크기는 사용자 지정 가능하지만 너무 높게 설정하면 CPU 오버헤드와 비효율적인 압축 페이지 캐시가 추가됩니다.)
- CUR_MAX_CACHED_PROCESSES를 높게 설정합니다. 자세한 내용은 [여기](https://github.com/agnostic-apollo/Android-Docs/blob/master/en/docs/apps/processes/phantom-cached-and-empty-processes.md)를 참조하세요.

## Q&A
Q: I want to change my ZRAM size, how can I do that?
 
A: You can change the ZRAM size on the configuration file located in /sdcard/Android/fog_mem_config.txt

<br>

Q: Can I just use swapfile and turn off my ZRAM? If so, how can I do it?
 
A: You can, but it is NOT recommended due to wear-out problems. Turn on Hybrid Swap and set ZRAM size to 0. You may change your swapfile size as well at maximum 3GB.

<br>

Q: What does "High Load Threshold" and "Medium Load Threshold" mean?

A: High and Medium Load Threshold are the threshold wherein if the CPU & I/O is greater than the initialized number, it will change swappiness based on the load.

## 질의응답

Q: ZRAM 크기를 변경하고 싶은데 어떻게 하나요?
 
A: /sdcard/Android/fog_mem_config.txt>에 있는 구성 파일에서 ZRAM 크기를 변경할 수 있습니다.

<br>

Q: 스왑파일만 사용하고 ZRAM을 끌 수 있나요? 그렇다면 어떻게 해야 하나요?
 
A: 가능하지만 마모 문제로 인해 권장되지 않습니다. 하이브리드 스왑을 켜고 ZRAM 크기를 0으로 설정하세요. 스왑파일 크기도 최대 3GB까지 변경할 수 있습니다.

<br>

Q: “높은 부하 임계값”과 “중간 부하 임계값”은 무엇을 의미하나요?

A: 높은 부하 임계값과 중간 부하 임계값은 CPU 및 I/O가 초기화된 수치보다 클 경우 부하에 따라 스왑을 변경하는 임계값입니다.
