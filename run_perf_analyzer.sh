#!/bin/bash


uname -a

# Default configurations
DEFAULT_N_INSTANCE_PER_GPU=1
DEFAULT_N_GPUS=1
DEFAULT_OUTPUT_CSV_NAME="perf_analyzer"
DEFAULT_MEASUREMENT_INTERVAL=120000
DEFAULT_OUTPUT_DIR="data/traccc_g200_v26_10event_v1p3/"
DEFAULT_CONCURRENCY_START=1
DEFAULT_CONCURRENCY_END=8
DEFAULT_CONCURRENCY_STEP=1
DEFAULT_INPUT_DATA="data/perf_data_itk_10events.json"
DEFAULT_REMOTE_SERVER="true"
DEFAULT_MAX_ATTEMPTS=5

n_instance_per_gpu=${DEFAULT_N_INSTANCE_PER_GPU}
n_gpus=${DEFAULT_N_GPUS}
output_csv_name=${DEFAULT_OUTPUT_CSV_NAME}
_measurement_interval=${DEFAULT_MEASUREMENT_INTERVAL}
output_dir=${DEFAULT_OUTPUT_DIR}
concurrency_start=${DEFAULT_CONCURRENCY_START}
concurrency_end=${DEFAULT_CONCURRENCY_END}
concurrency_step=${DEFAULT_CONCURRENCY_STEP}
input_data=${DEFAULT_INPUT_DATA}
remote_server=${DEFAULT_REMOTE_SERVER}
max_attempts=${DEFAULT_MAX_ATTEMPTS}

# Display help information
help_function() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -n, --n-instance-per-gpu <int> Number of instances per GPU (default: ${DEFAULT_N_INSTANCE_PER_GPU})"
    echo "  -g, --n-gpus <int>             Number of GPUs (default: ${DEFAULT_N_GPUS})"
    echo "  -c, --output-csv-name <name>   Base name for output CSV files (default: ${DEFAULT_OUTPUT_CSV_NAME})"
    echo "  -m, --measurement-interval <ms> Initial measurement interval in milliseconds (default: ${DEFAULT_MEASUREMENT_INTERVAL})"
    echo "  -o, --output-dir <path>        Directory to store output CSV files (default: ${DEFAULT_OUTPUT_DIR})"
    echo "  -s, --concurrency-start <int>  Start value for concurrency range (default: ${DEFAULT_CONCURRENCY_START})"
    echo "  -e, --concurrency-end <int>    End value for concurrency range (default: ${DEFAULT_CONCURRENCY_END})"
    echo "  -p, --concurrency-step <int>   Step value for concurrency range (default: ${DEFAULT_CONCURRENCY_STEP})"
    echo "  -i, --input-data <path>        Input JSON for perf_analyzer (default: ${DEFAULT_INPUT_DATA})"
    echo "  -r, --remote-server <bool>     Skip readiness checks when true (default: ${DEFAULT_REMOTE_SERVER})"
    echo "  -a, --max-attempts <int>       Number of retries for CSV generation (default: ${DEFAULT_MAX_ATTEMPTS})"
    echo "  -h, --help                    Show this help and exit"
    echo ""
    echo "Backward-compatible positional args are still accepted in this order:"
    echo "  n_instance_per_gpu n_gpus output_csv_name measurement_interval output_dir concurrency_start concurrency_end concurrency_step input_data remote_server"
}

require_option_value() {
    local option_name=$1
    local option_value=$2

    if [[ -z "${option_value}" || "${option_value}" == -* ]]; then
        echo "Missing value for option: ${option_name}" >&2
        echo "Use --help for usage details." >&2
        exit 1
    fi
}

# Parse command-line options (supports both named options and legacy positional args)
positional_args=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            help_function
            exit 0
            ;;
        -n|--n-instance-per-gpu)
            require_option_value "$1" "$2"
            n_instance_per_gpu="$2"
            shift 2
            ;;
        -g|--n-gpus)
            require_option_value "$1" "$2"
            n_gpus="$2"
            shift 2
            ;;
        -c|--output-csv-name)
            require_option_value "$1" "$2"
            output_csv_name="$2"
            shift 2
            ;;
        -m|--measurement-interval)
            require_option_value "$1" "$2"
            _measurement_interval="$2"
            shift 2
            ;;
        -o|--output-dir)
            require_option_value "$1" "$2"
            output_dir="$2"
            shift 2
            ;;
        -s|--concurrency-start)
            require_option_value "$1" "$2"
            concurrency_start="$2"
            shift 2
            ;;
        -e|--concurrency-end)
            require_option_value "$1" "$2"
            concurrency_end="$2"
            shift 2
            ;;
        -p|--concurrency-step)
            require_option_value "$1" "$2"
            concurrency_step="$2"
            shift 2
            ;;
        -i|--input-data)
            require_option_value "$1" "$2"
            input_data="$2"
            shift 2
            ;;
        -r|--remote-server)
            require_option_value "$1" "$2"
            remote_server="$2"
            shift 2
            ;;
        -a|--max-attempts)
            require_option_value "$1" "$2"
            max_attempts="$2"
            shift 2
            ;;
        --)
            shift
            while [[ $# -gt 0 ]]; do
                positional_args+=("$1")
                shift
            done
            ;;
        -* )
            echo "Unknown option: $1" >&2
            echo "Use --help for usage details." >&2
            exit 1
            ;;
        *)
            positional_args+=("$1")
            shift
            ;;
    esac
done

# Backward-compatible positional argument parsing
if [[ ${#positional_args[@]} -gt 0 ]]; then
    n_instance_per_gpu=${positional_args[0]:-${n_instance_per_gpu}}
    n_gpus=${positional_args[1]:-${n_gpus}}
    output_csv_name=${positional_args[2]:-${output_csv_name}}
    _measurement_interval=${positional_args[3]:-${_measurement_interval}}
    output_dir=${positional_args[4]:-${output_dir}}
    concurrency_start=${positional_args[5]:-${concurrency_start}}
    concurrency_end=${positional_args[6]:-${concurrency_end}}
    concurrency_step=${positional_args[7]:-${concurrency_step}}
    input_data=${positional_args[8]:-${input_data}}
    remote_server=${positional_args[9]:-${remote_server}}
fi


# Update model repository configuration
output_dir=$output_dir/${n_instance_per_gpu}insts_${n_gpus}gpus

if [ ! -d "$output_dir" ];
then
    mkdir -p "$output_dir"
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
    local output_csv="${output_dir}/${output_csv_name}_${processor}_${n_instance_per_gpu}instance_${mode}.csv"
    local attempt=0
    local measurement_interval=${_measurement_interval}
    local mode_flag=""
    echo "Concurrency Range: ${concurrency_start}:${concurrency_end}:${concurrency_step}"


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
          --concurrency-range ${concurrency_start}:${concurrency_end}:${concurrency_step} \
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