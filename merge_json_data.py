#!/usr/bin/env python
"""Merge JSON data from multiple files into a single file for perf_analyzer input."""

import sys
import json
import glob
import tqdm


def main(input_dir, output_file, max_evts=None, filter_shape=False):
    # Find all JSON files in the input directory
    json_files = glob.glob(f"{input_dir}/*.json")

    if not json_files:
        print(f"No JSON files found in {input_dir}")
        return

    merged_data = {"data": []}
    num_files = len(json_files)
    print(f"Found {num_files} JSON files to merge.")

    if max_evts is not None:
        json_files = json_files[:max_evts]
        print(f"Limiting to {max_evts} events.")

    features = ["electron_features", "flow_features", "track_features"]

    # Read and merge data from each JSON file
    num_saved_files = 0
    num_skipped_shape = 0
    for json_file in tqdm.tqdm(json_files, desc="Merging JSON files"):
        with open(json_file, 'r') as f:
            try:
                data = json.loads(f.read())
            except json.JSONDecodeError as e:
                print(f"Error decoding JSON from {json_file}: {e}")
                print("Error message:", e.msg)
                continue

        # Filter: all feature shapes must be > 0
        if filter_shape and not all(data.get(feat, {}).get("shape", [0])[0] > 0 for feat in features):
            num_skipped_shape += 1
            continue

        # Flatten content and convert to float
        for feature_data in data.values():
            if isinstance(feature_data, dict) and "content" in feature_data:
                raw = feature_data["content"]
                feature_data["content"] = [
                    float(item)
                    for sublist in raw
                    for item in (sublist if isinstance(sublist, list) else [sublist])
                ]

        merged_data["data"].append(data)
        num_saved_files += 1

    # Write the merged data to a new JSON file
    # add f"{num_saved_files}evts" to the output file name.
    output_file = output_file.replace(".json", f"_{num_saved_files}evts.json")

    with open(output_file, 'w') as f:
        json.dump(merged_data, f, separators=(',', ':'))

    if num_skipped_shape:
        print(f"Skipped {num_skipped_shape} files due to zero-size feature shapes.")

    print(f"Merged {num_saved_files} files into {output_file}")
    print(f"Skipped {num_files - num_saved_files - num_skipped_shape} files due to JSON decoding errors.")


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="Merge JSON files for perf_analyzer input")
    parser.add_argument("-i", "--input-dir", required=True, help="Directory containing JSON files to merge")
    parser.add_argument("-o", "--output-file", required=True, help="Output file path for merged JSON data")
    parser.add_argument("-n", "--max-evts", type=int, default=None, help="Maximum number of events to merge")
    parser.add_argument("-f", "--filter-shape", action="store_true", help="Skip entries where any feature shape is zero")

    args = parser.parse_args()
    main(args.input_dir, args.output_file, args.max_evts, args.filter_shape)
