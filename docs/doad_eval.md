The model: `BTagging_network_8085e6c5717c`
The input data: `/global/homes/x/xju/m3443/data/AmSC_SUF_D3/BenchmarkData/cleaned_daod_BTagging_network_8085e6c5717c_31080evts.json`
Benchmark results: `/pscratch/sd/x/xju/code/amsc-suf-d3-client/benchmark_results`
The command:
```bash
IN_FILE="/global/homes/x/xju/m3443/data/AmSC_SUF_D3/BenchmarkData/cleaned_daod_BTagging_network_8085e6c5717c_31080evts.json"
./run_perf_analyzer.sh \
  --model BTagging_network_8085e6c5717c --host nid004208 \
  --input ${IN_FILE} \
  --output-dir benchmark_results/daod_BTagging_8085e6c5717c_x \
  --range 2:20:2 \
  --instances 8 \
  --gpus 0 \
  --measurement-ms 2000
```


The plan:
v1: using random input data, 8 model instances on one CPU node, concurrency: 2:12:2,
Results:
```text
With http protocol,
Concurrency: 2, throughput: 295.112 infer/sec, latency 6733 usec
Concurrency: 4, throughput: 594.109 infer/sec, latency 6694 usec
Concurrency: 6, throughput: 884.996 infer/sec, latency 6743 usec
Concurrency: 8, throughput: 1133.45 infer/sec, latency 7020 usec
Concurrency: 10, throughput: 1159.84 infer/sec, latency 8585 usec
Concurrency: 12, throughput: 1217.56 infer/sec, latency 9819 usec
Concurrency: 14, throughput: 1234.2 infer/sec, latency 11304 usec
Concurrency: 16, throughput: 1254.54 infer/sec, latency 12713 usec
Concurrency: 18, throughput: 1260.73 infer/sec, latency 14237 usec
Concurrency: 20, throughput: 1260.17 infer/sec, latency 15829 usec,

With grpc protocol,
Concurrency: 2, throughput: 256.882 infer/sec, latency 7747 usec
Concurrency: 4, throughput: 538.094 infer/sec, latency 7404 usec
Concurrency: 6, throughput: 809.618 infer/sec, latency 7389 usec
Concurrency: 8, throughput: 1163.48 infer/sec, latency 6857 usec
Concurrency: 10, throughput: 1235.28 infer/sec, latency 8078 usec
Concurrency: 12, throughput: 1255.39 infer/sec, latency 9540 usec
Concurrency: 14, throughput: 1251.48 infer/sec, latency 11165 usec
Concurrency: 16, throughput: 1164.08 infer/sec, latency 13721 usec
Concurrency: 18, throughput: 1228.36 infer/sec, latency 14630 usec
Concurrency: 20, throughput: 1177.8 infer/sec, latency 16950 usec
```
v2: using real input data, grpc, 8 model instances on one CPU node, concurrency: 2:20:2,
```bash
            --input-data random \
            --shape "track_features:2,24" \
            --shape "flow_features:6,5" \
            --shape "electron_features:1,28" \
```
```text
Concurrency: 2, throughput: 151.865 infer/sec, latency 13104 usec
Concurrency: 4, throughput: 322.425 infer/sec, latency 12346 usec
Concurrency: 6, throughput: 497.787 infer/sec, latency 12004 usec
Concurrency: 8, throughput: 656.138 infer/sec, latency 12148 usec
Concurrency: 10, throughput: 704.699 infer/sec, latency 14150 usec
Concurrency: 12, throughput: 697.134 infer/sec, latency 17169 usec
Concurrency: 14, throughput: 696.77 infer/sec, latency 20043 usec
Concurrency: 16, throughput: 687.359 infer/sec, latency 23242 usec
Concurrency: 18, throughput: 695.974 infer/sec, latency 25800 usec
Concurrency: 20, throughput: 727.229 infer/sec, latency 27451 usec
```
v3: using real input data, http, 8 model instances
```text
Concurrency: 2, throughput: 167.262 infer/sec, latency 11895 usec
Concurrency: 4, throughput: 342.013 infer/sec, latency 11640 usec
Concurrency: 6, throughput: 519.153 infer/sec, latency 11496 usec
Concurrency: 8, throughput: 698.267 infer/sec, latency 11387 usec
Concurrency: 10, throughput: 734.893 infer/sec, latency 13547 usec
Concurrency: 12, throughput: 711.314 infer/sec, latency 16797 usec
Concurrency: 14, throughput: 734.113 infer/sec, latency 19002 usec
Concurrency: 16, throughput: 731.329 infer/sec, latency 21824 usec
Concurrency: 18, throughput: 740.013 infer/sec, latency 24275 usec
Concurrency: 20, throughput: 740.487 infer/sec, latency 26959 usec
```
v4: same client config as v3, but remove the following in the server side:
```text
parameters {
  key: "enable_mem_arena"
  value: {
    string_value: "0"
  }
}

parameters {
  key: "intra_op_thread_count"
  value: {
    string_value: "1"
  }
}

parameters {
  key: "inter_op_thread_count"
  value: {
    string_value: "1"
  }
}
```
and this in the server launch command:
```bash
        --backend-config=onnxruntime,enable-global-threadpool=1 \
        --backend-config=onnxruntime,intra_op_thread_count=1, --backend-config=onnxruntime,inter_op_thread_count=1 \
```
Results:
```text
Concurrency: 2, throughput: 90.6507 infer/sec, latency 21959 usec
Concurrency: 4, throughput: 91.72 infer/sec, latency 43444 usec
Concurrency: 6, throughput: 109.837 infer/sec, latency 54340 usec
Concurrency: 8, throughput: 134.409 infer/sec, latency 59458 usec
Concurrency: 10, throughput: 151.151 infer/sec, latency 66056 usec
Concurrency: 12, throughput: 175.805 infer/sec, latency 67910 usec
Concurrency: 14, throughput: 179.92 infer/sec, latency 77792 usec
Concurrency: 16, throughput: 186.745 infer/sec, latency 85469 usec
Concurrency: 18, throughput: 171.233 infer/sec, latency 104774 usec
Concurrency: 20, throughput: 173.724 infer/sec, latency 114672 usec
```

v5: same client config as v3, same server config as v4. Now I add the following back to check the impact of the memory arena:
```text
parameters {
  key: "enable_mem_arena"
  value: {
    string_value: "0"
  }
}
```
Results:
```text
Concurrency: 2, throughput: 97.0482 infer/sec, latency 20541 usec
Concurrency: 4, throughput: 102.837 infer/sec, latency 38751 usec
Concurrency: 6, throughput: 122.453 infer/sec, latency 48820 usec
Concurrency: 8, throughput: 140.598 infer/sec, latency 56593 usec
Concurrency: 10, throughput: 161.665 infer/sec, latency 61996 usec
Concurrency: 12, throughput: 172.252 infer/sec, latency 69495 usec
Concurrency: 14, throughput: 166.105 infer/sec, latency 83865 usec
Concurrency: 16, throughput: 171.347 infer/sec, latency 93257 usec
Concurrency: 18, throughput: 176.893 infer/sec, latency 101682 usec
Concurrency: 20, throughput: 173.31 infer/sec, latency 115340 usec
```

v6: same as v5, but add the following to the server launch command to check the impact of the global thread pool:
```bash
        --backend-config=onnxruntime,enable-global-threadpool=1 \
```
Results:
```text
Concurrency: 2, throughput: 212.356 infer/sec, latency 9360 usec
Concurrency: 4, throughput: 425.869 infer/sec, latency 9336 usec
Concurrency: 6, throughput: 608.419 infer/sec, latency 9804 usec
Concurrency: 8, throughput: 743.745 infer/sec, latency 10695 usec
Concurrency: 10, throughput: 746.466 infer/sec, latency 13337 usec
Concurrency: 12, throughput: 814.59 infer/sec, latency 14673 usec
Concurrency: 14, throughput: 870.396 infer/sec, latency 16026 usec
Concurrency: 16, throughput: 848.497 infer/sec, latency 18794 usec
Concurrency: 18, throughput: 833.101 infer/sec, latency 21550 usec
Concurrency: 20, throughput: 831.788 infer/sec, latency 23986 usec
```

v7: same as v6, but add the following to the server launch command to check the impact of the intra/inter op thread count:
```bash
        --backend-config=onnxruntime,intra_op_thread_count=1, --backend-config=onnxruntime,inter_op_thread_count=1 \
```
Results:
```text
Concurrency: 2, throughput: 173.402 infer/sec, latency 11463 usec
Concurrency: 4, throughput: 354.539 infer/sec, latency 11222 usec
Concurrency: 6, throughput: 543.494 infer/sec, latency 10978 usec
Concurrency: 8, throughput: 727.468 infer/sec, latency 10927 usec
Concurrency: 10, throughput: 771.044 infer/sec, latency 12923 usec
Concurrency: 12, throughput: 777.509 infer/sec, latency 15379 usec
Concurrency: 14, throughput: 770.603 infer/sec, latency 18111 usec
Concurrency: 16, throughput: 772.489 infer/sec, latency 20648 usec
```

v8: same as v7, but increase the op_thread_count to 2 to check the impact of that:
```bash
        --backend-config=onnxruntime,intra_op_thread_count=2, --backend-config=onnxruntime,inter_op_thread_count=2 \
```
Results:
```text
Concurrency: 2, throughput: 191.927 infer/sec, latency 10367 usec
Concurrency: 4, throughput: 334.117 infer/sec, latency 11913 usec
Concurrency: 6, throughput: 491.433 infer/sec, latency 12155 usec
Concurrency: 8, throughput: 644.18 infer/sec, latency 12365 usec
Concurrency: 10, throughput: 689.032 infer/sec, latency 14455 usec
Concurrency: 12, throughput: 706.331 infer/sec, latency 16932 usec
Concurrency: 14, throughput: 710.84 infer/sec, latency 19644 usec
Concurrency: 16, throughput: 703.299 infer/sec, latency 22694 usec
Concurrency: 18, throughput: 640.592 infer/sec, latency 28021 usec
Concurrency: 20, throughput: 637.799 infer/sec, latency 31303 usec
```

v9: max-batch-size to 100,
```bash
            --max-batch-size 100 \
```
Not working. The model does not support batching.

v10: 64 model instances, concurrency: 2:128:2, intra_op_thread_count=1, inter_op_thread_count=1, global thread pool = 1. This is to check if we can further increase the throughput by increasing the number of model instances on the same CPU node that has 256 cores.

Results:
```text
Concurrency: 2, throughput: 164.389 infer/sec, latency 12098 usec
Concurrency: 4, throughput: 313.916 infer/sec, latency 12677 usec
Concurrency: 6, throughput: 458.536 infer/sec, latency 13022 usec
Concurrency: 8, throughput: 584.881 infer/sec, latency 13625 usec
Concurrency: 10, throughput: 729.683 infer/sec, latency 13649 usec
Concurrency: 12, throughput: 879.477 infer/sec, latency 13595 usec
Concurrency: 14, throughput: 1020.27 infer/sec, latency 13669 usec
Concurrency: 16, throughput: 1134.26 infer/sec, latency 14047 usec
Concurrency: 18, throughput: 1262.56 infer/sec, latency 14206 usec
Concurrency: 20, throughput: 1393.07 infer/sec, latency 14313 usec
Concurrency: 22, throughput: 1549.25 infer/sec, latency 14152 usec
Concurrency: 24, throughput: 1674.32 infer/sec, latency 14278 usec
Concurrency: 26, throughput: 1786.86 infer/sec, latency 14495 usec
Concurrency: 28, throughput: 1878.37 infer/sec, latency 14858 usec
Concurrency: 30, throughput: 2016.54 infer/sec, latency 14825 usec
Concurrency: 32, throughput: 2160.52 infer/sec, latency 14764 usec
Concurrency: 34, throughput: 2287.09 infer/sec, latency 14816 usec
Concurrency: 36, throughput: 2410.21 infer/sec, latency 14888 usec
Concurrency: 38, throughput: 2554.68 infer/sec, latency 14825 usec
Concurrency: 40, throughput: 2672.04 infer/sec, latency 14922 usec
Concurrency: 42, throughput: 2790.03 infer/sec, latency 15004 usec
Concurrency: 44, throughput: 2894.9 infer/sec, latency 15152 usec
Concurrency: 46, throughput: 3048.12 infer/sec, latency 15043 usec
Concurrency: 48, throughput: 3110.73 infer/sec, latency 15384 usec
Concurrency: 50, throughput: 3225.99 infer/sec, latency 15449 usec
Concurrency: 52, throughput: 3328.86 infer/sec, latency 15574 usec
Concurrency: 54, throughput: 3452.89 infer/sec, latency 15592 usec
Concurrency: 56, throughput: 3532.11 infer/sec, latency 15806 usec
Concurrency: 58, throughput: 3476.74 infer/sec, latency 16632 usec
Concurrency: 60, throughput: 3553.82 infer/sec, latency 16833 usec
Concurrency: 62, throughput: 3568.66 infer/sec, latency 17336 usec
Concurrency: 64, throughput: 3578.22 infer/sec, latency 17839 usec
Concurrency: 66, throughput: 3612.2 infer/sec, latency 18227 usec
Concurrency: 68, throughput: 3615.44 infer/sec, latency 18758 usec
Concurrency: 70, throughput: 3629.77 infer/sec, latency 19235 usec
Concurrency: 72, throughput: 3586.54 infer/sec, latency 20026 usec
Concurrency: 74, throughput: 3539.08 infer/sec, latency 20857 usec
Concurrency: 76, throughput: 3445.53 infer/sec, latency 22014 usec
Concurrency: 78, throughput: 3417.95 infer/sec, latency 22772 usec
Concurrency: 80, throughput: 3397.24 infer/sec, latency 23499 usec
Concurrency: 82, throughput: 3435.81 infer/sec, latency 23808 usec
Concurrency: 84, throughput: 3379.11 infer/sec, latency 24805 usec
Concurrency: 86, throughput: 3379.67 infer/sec, latency 25392 usec
Concurrency: 88, throughput: 3416.84 infer/sec, latency 25701 usec
Concurrency: 90, throughput: 3402.92 infer/sec, latency 26394 usec
Concurrency: 92, throughput: 3433.82 infer/sec, latency 26742 usec
Concurrency: 94, throughput: 3453.09 infer/sec, latency 27174 usec
Concurrency: 96, throughput: 3466.46 infer/sec, latency 27653 usec
Concurrency: 98, throughput: 3476.1 infer/sec, latency 28139 usec
Concurrency: 100, throughput: 3497.31 infer/sec, latency 28549 usec
Concurrency: 102, throughput: 3502.1 infer/sec, latency 29076 usec
Concurrency: 104, throughput: 3504.71 infer/sec, latency 29620 usec
Concurrency: 106, throughput: 3474.61 infer/sec, latency 30466 usec
Concurrency: 108, throughput: 3540.48 infer/sec, latency 30465 usec
Concurrency: 110, throughput: 3534.46 infer/sec, latency 31068 usec
Concurrency: 112, throughput: 3550.01 infer/sec, latency 31504 usec
Concurrency: 114, throughput: 3552.68 infer/sec, latency 32035 usec
Concurrency: 116, throughput: 3561.25 infer/sec, latency 32513 usec
Concurrency: 118, throughput: 3533.65 infer/sec, latency 33349 usec
Concurrency: 120, throughput: 3503.25 infer/sec, latency 34194 usec
Concurrency: 122, throughput: 3411.07 infer/sec, latency 35708 usec
Concurrency: 124, throughput: 3412.29 infer/sec, latency 36298 usec
Concurrency: 126, throughput: 3470.49 infer/sec, latency 36250 usec
Concurrency: 128, throughput: 3441.74 infer/sec, latency 37149 usec
```