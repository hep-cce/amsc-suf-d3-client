#!/usr/bin/env python3

import argparse
import csv
import sys
from pathlib import Path
from typing import List, Tuple


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Plot inference/sec as a function of concurrency from a perf_analyzer CSV."
    )
    parser.add_argument(
        "csv_path",
        nargs="?",
        default="benchmark_results/daod_BTagging_8085e6c5717c_v10/8insts_0gpus/sync.csv",
        help="Path to the input CSV file.",
    )
    parser.add_argument(
        "-o",
        "--output",
        help="Path to the output image. Defaults to <csv_stem>_inference_vs_concurrency.png.",
    )
    parser.add_argument(
        "--title",
        default="Inference/sec vs Concurrency",
        help="Plot title.",
    )
    return parser.parse_args()


def load_data(csv_path: Path) -> Tuple[List[int], List[float]]:
    with csv_path.open(newline="") as handle:
        reader = csv.DictReader(handle)
        required_columns = {"Concurrency", "Inferences/Second"}
        missing = required_columns - set(reader.fieldnames or [])
        if missing:
            missing_str = ", ".join(sorted(missing))
            raise ValueError(f"Missing required column(s): {missing_str}")

        rows = []
        for row in reader:
            concurrency = int(row["Concurrency"])
            inferences_per_second = float(row["Inferences/Second"])
            rows.append((concurrency, inferences_per_second))

    if not rows:
        raise ValueError(f"No data rows found in {csv_path}")

    rows.sort(key=lambda item: item[0])
    concurrency_values = [item[0] for item in rows]
    throughput_values = [item[1] for item in rows]
    return concurrency_values, throughput_values


def plot_data(
    concurrency_values: List[int],
    throughput_values: List[float],
    output_path: Path,
    title: str,
) -> None:
    try:
        import matplotlib.pyplot as plt
    except ModuleNotFoundError as exc:
        raise SystemExit(
            "matplotlib is required to generate the plot. "
            "Install it in this environment, for example with `uv add matplotlib`."
        ) from exc

    peak_index = max(range(len(throughput_values)), key=throughput_values.__getitem__)
    peak_concurrency = concurrency_values[peak_index]
    peak_throughput = throughput_values[peak_index]

    fig, ax = plt.subplots(figsize=(8, 5))
    ax.plot(
        concurrency_values,
        throughput_values,
        marker="o",
        linewidth=2,
        markersize=5,
    )
    ax.scatter(
        [peak_concurrency],
        [peak_throughput],
        color="tab:red",
        zorder=3,
        label=f"peak: {peak_throughput:.2f} @ {peak_concurrency}",
    )
    ax.set_title(title)
    ax.set_xlabel("Concurrency")
    ax.set_ylabel("Inferences / second")
    ax.grid(True, linestyle="--", alpha=0.4)
    ax.legend()
    fig.tight_layout()
    fig.savefig(output_path, dpi=200)
    plt.close(fig)


def main() -> int:
    args = parse_args()
    csv_path = Path(args.csv_path)
    if not csv_path.is_file():
        print(f"CSV file not found: {csv_path}", file=sys.stderr)
        return 1

    output_path = (
        Path(args.output)
        if args.output
        else csv_path.with_name(f"{csv_path.stem}_inference_vs_concurrency.png")
    )

    try:
        concurrency_values, throughput_values = load_data(csv_path)
    except ValueError as exc:
        print(str(exc), file=sys.stderr)
        return 1

    plot_data(concurrency_values, throughput_values, output_path, args.title)
    print(f"Wrote plot to {output_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
