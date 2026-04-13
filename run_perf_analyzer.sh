#!/usr/bin/env bash

set -euo pipefail

HOST=localhost
PORT=8001
MODEL=DoubleMetricLearning
INPUT=data/perf_data_itk_10events.json
OUTPUT_DIR=data/traccc_g200_v26_10event_v1p3
RANGE=1:8:1
MODE=sync
INSTANCES=1
GPUS=1
MEASUREMENT_MS=120000
ATTEMPTS=5
WARMUP=2
USE_SSL=0

usage() {
    cat <<EOF
Usage: $(basename "$0") [options]

Options:
  --host HOST
  --port PORT
  --model NAME
  --input FILE
  --output-dir DIR
  --output-prefix NAME
  --range START:END:STEP
  --mode sync|async|both
  --instances N
  --gpus N
  --measurement-ms N
  --attempts N
  --warmup N
  --skip-warmup
  --use-ssl
  -h, --help
EOF
}

SKIP_WARMUP=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --host) HOST=$2; shift 2 ;;
        --port) PORT=$2; shift 2 ;;
        --model) MODEL=$2; shift 2 ;;
        --input) INPUT=$2; shift 2 ;;
        --output-dir) OUTPUT_DIR=$2; shift 2 ;;
        --range) RANGE=$2; shift 2 ;;
        --mode) MODE=$2; shift 2 ;;
        --instances) INSTANCES=$2; shift 2 ;;
        --gpus) GPUS=$2; shift 2 ;;
        --measurement-ms) MEASUREMENT_MS=$2; shift 2 ;;
        --attempts) ATTEMPTS=$2; shift 2 ;;
        --warmup) WARMUP=$2; shift 2 ;;
        --skip-warmup) SKIP_WARMUP=1; shift ;;
        --use-ssl) USE_SSL=1; shift ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
    esac
done

RUN_DIR="${OUTPUT_DIR%/}/${INSTANCES}insts_${GPUS}gpus"
mkdir -p "${RUN_DIR}"

echo "Input: ${INPUT}"
echo "Output directory: ${RUN_DIR}"
echo "Model: ${MODEL}"
echo "Host: ${HOST}"
echo "Port: ${PORT}"
echo "Mode: ${MODE}"
echo "Instances: ${INSTANCES}"
echo "GPUs: ${GPUS}"
echo "Measurement interval (ms): ${MEASUREMENT_MS}"
echo "Concurrency range: ${RANGE}"
echo "Warmup iterations: ${WARMUP}"
echo "Skip warmup: ${SKIP_WARMUP}"
echo "Use SSL: ${USE_SSL}"

wait_for_ready() {
    until curl -fsS "http://${HOST}:8000/v2/health/ready" >/dev/null; do
        sleep 20
    done
}

warmup() {
    uv run perf_analyzer \
        -m "${MODEL}" \
        --input-data "${INPUT}" \
        -i grpc \
        -u "${HOST}:${PORT}" \
        --concurrency-range "${WARMUP}:${WARMUP}:1" \
        --measurement-interval "${MEASUREMENT_MS}" \
        -b 1 >/dev/null
}

run_mode() {
    local mode=$1
    local flag=
    local csv="${RUN_DIR}/${mode}.csv"
    local measurement_ms=${MEASUREMENT_MS}
    local attempt

    [[ "${mode}" == "sync" ]] && flag=--sync
    [[ "${mode}" == "async" ]] && flag=--async
    [[ ${USE_SSL} -eq 1 ]] && flag="${flag} --ssl-grpc-use-ssl"

    rm -f "${csv}"

    for ((attempt = 1; attempt <= ATTEMPTS; attempt++)); do
        uv run perf_analyzer \
            -m "${MODEL}" \
            -i grpc \
            -u "${HOST}:${PORT}" \
            --input-data "${INPUT}" \
            --measurement-interval "${measurement_ms}" \
            "${flag}" \
            --concurrency-range "${RANGE}" \
            -f "${csv}" \
            -r 30 \
            --collect-metrics \
            --verbose-csv \
            --percentile=95 \
            --metrics-interval=250 \
            -b 1 || true

        [[ -s "${csv}" ]] && return 0
        measurement_ms=$((measurement_ms * 2))
    done

    echo "Failed to produce ${csv}" >&2
    exit 1
}

wait_for_ready
echo "Server is ready. Starting benchmark..."

if [[ ${SKIP_WARMUP} -eq 0 ]]; then
    warmup
fi

case "${MODE}" in
    sync|async) run_mode "${MODE}" ;;
    both)
        run_mode sync
        run_mode async
        ;;
    *)
        echo "Invalid mode: ${MODE}" >&2
        exit 1
        ;;
esac
