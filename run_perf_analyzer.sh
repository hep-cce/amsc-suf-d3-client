# Description: This script is used to run the perf_analyzer tool for the traccc-aaS model.

# Author: Haoran Zhao
# Edits: Miles Cochran-Branson
# Date: 2024-07-19

#!/bin/bash
uname -a

# Default configurations
n_instance_per_gpu=${1:-1}
n_gpus=${2:-1}
output_csv_name=${3:-"perf_analyzer"}
_measurement_interval=${4:-10000}
output_dir=${5:-"data/traccc_g200_v26_10event_v1p3/"}
concurrency_start=${6:-1}
concurrency_end=${7:-8}
concurrency_step=${8:-1}
input_data=${9:-"data/perf_data_itk_10events.json"}
remote_server=${10:-"true"}
max_attempts=5

# Display help information
help_function() {
    echo "Usage: $0 [n_instance_per_gpu] [n_gpus] [output_csv_name] [measurement_interval] [output_dir] [concurrency_end] [concurrency_step]"
    echo ""
    echo "n_instance_per_gpu:     Number of instances per GPU (default: 1)"
    echo "n_gpus:                 Number of GPUs (default: 1)"
    echo "output_csv_name:        Base name for the output CSV files (default: 'perf_analyzer')"
    echo "measurement_interval:   Initial measurement interval in milliseconds (default: 120000)"
    echo "output_dir:             Directory to store the output CSV files (default: '/workspace/evaluate/slurm/')"
    echo "concurrency_end:        End value for concurrency range (default: 16)"
    echo "concurrency_step:       Step value for concurrency range (default: 1)"
}

# If help is requested, display help and exit
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    help_function
    exit 0
fi


# Update model repository configuration
output_dir=$output_dir/${n_instance_per_gpu}insts_${n_gpus}gpus

if [ ! -d $output_dir ];
then
    mkdir -p $output_dir
fi

# mkdir -p $output_dir

HOST_IP="128.55.82.91"
MODEL_NAME="DoubleMetricLearning"


# sed -i "s/count: 1/count: ${n_instance_per_gpu}/" $output_dir/${model_repo_name}/traccc-gpu/config.pbtxt
# gpus_array=$(seq 0 $((n_gpus - 1)) | tr '\n' ',' | sed 's/,$//')
# sed -i "/gpus:/c\    gpus: [ $gpus_array ]" $output_dir/${model_repo_name}/traccc-gpu/config.pbtxt

check_server_ready() {
    local max_retries=100
    local retry_interval=20  # wait 10 seconds before re-trying
    local retry_count=0
    local server_ready=0

    echo "Checking if server is ready..."

    while [[ $retry_count -lt $max_retries && $server_ready -eq 0 ]]; do
        # Use curl to check the server's status. The -s flag silences curl's output, and -o /dev/null discards the actual content.
        local response=$(curl -s -o /dev/null -w "%{http_code}" ${HOST_IP}:8000/v2/health/ready)
        echo "Response: $response"
        if [[ "$response" == "200" || "$remote_server" == "true" ]]; then
            server_ready=1
            echo "Server is ready!"
            echo ""
        else
            echo "Server not ready, retrying in $retry_interval seconds..."
            echo ""
            retry_count=$((retry_count + 1))
            sleep $retry_interval
        fi
    done

    if [[ $server_ready -eq 0 ]]; then
        echo "Server didn't become ready after $max_retries attempts. Exiting..."
        exit 1
    fi
}


# Check server's readiness
check_server_ready

# # Check for .csv files in the target directory and delete them
# find "$output_dir" -type f -name "*.csv" -exec rm -f {} \;

# Function to run perf_analyzer
run_perf_analyzer() {
    local mode=$1  # sync or async
    local processor=$2 # cpu or gpu
    local output_csv="${output_dir}/${processor}_${n_instance_per_gpu}instance_${mode}.csv"
    local attempt=0
    local measurement_interval=${_measurement_interval}
    local mode_flag=""
    local concurrency_range=$((n_instance_per_gpu + 3))
    local concurrency_step=1
    local concurrency_start=$n_instance_per_gpu
    echo "Concurrency Range: $concurrency_start:$concurrency_range:$concurrency_step"


    # Set the mode flag based on sync or async
    if [[ "$mode" == "sync" ]]; then
        mode_flag="--sync"
    elif [[ "$mode" == "async" ]]; then
        mode_flag="--async"
    fi

    while [[ ! -f ${output_csv} && $attempt -lt $max_attempts ]]; do
        echo "Running perf_analyzer (${mode}) with measurement_interval: $measurement_interval..."
        perf_analyzer -m ${MODEL_NAME} -i grpc \
          -u ${HOST_IP}:8001 \
          --input-data $input_data \
          --measurement-interval ${measurement_interval} $mode_flag \
          --concurrency-range $concurrency_start:$concurrency_range:$concurrency_step \
          -f ${output_csv} -r 30 --collect-metrics --verbose-csv --percentile=95 --metrics-interval=250 -b 1

        # If the file isn't generated, double the measurement_interval and retry
        if [[ ! -f ${output_csv} ]]; then
            echo ""
            echo "File not generated. Doubling the measurement_interval and retrying..."
            echo ""
            measurement_interval=$((measurement_interval * 2))
            attempt=$((attempt + 1))
        fi
    done

    # Check if file was not created after all attempts
    if [[ ! -f ${output_csv} ]]; then
        echo "Failed to generate the file ${output_csv} after $max_attempts attempts."
        exit 1
    fi
}

echo "Warm up"
perf_analyzer -m $MODEL_NAME -i grpc -b 1 \
    -u ${HOST_IP}:8001 \
    --input-data $input_data \
    --concurrency 2:2:1

echo "Warm up done"

# Run the perf_analyzer for both sync and async modes
echo ""
echo "Running perf_analyzer for the sync mode with GPU"
run_perf_analyzer "sync" "gpu"
echo "Sync mode GPU done"


echo "All Done!"