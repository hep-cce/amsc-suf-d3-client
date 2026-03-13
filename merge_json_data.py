#!/usr/bin/env python
"""Merge JSON data from multiple files into a single file for perf_analyzer input."""

import json
import glob
import tqdm


def main(input_dir, output_file):
    # Find all JSON files in the input directory
    json_files = glob.glob(f"{input_dir}/*.json")

    if not json_files:
        print(f"No JSON files found in {input_dir}")
        return

    merged_data = {"data": []}
    num_files = len(json_files)
    print(f"Found {num_files} JSON files to merge.")

    # Read and merge data from each JSON file
    for json_file in tqdm.tqdm(json_files, desc="Merging JSON files"):
        with open(json_file, 'r') as f:
            data = json.loads(f.read())
            merged_data["data"].append(data)

    # Write the merged data to a new JSON file
    # add f"{num_files}evts" to the output file name.
    output_file = output_file.replace(".json", f"_{num_files}evts.json")

    with open(output_file, 'w') as f:
        json.dump(merged_data, f, indent=2)

    print(f"Merged {num_files} files into {output_file}")


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="Merge JSON files for perf_analyzer input")
    parser.add_argument("-i", "--input-dir", required=True, help="Directory containing JSON files to merge")
    parser.add_argument("-o", "--output-file", required=True, help="Output file path for merged JSON data")

    args = parser.parse_args()
    main(args.input_dir, args.output_file)
