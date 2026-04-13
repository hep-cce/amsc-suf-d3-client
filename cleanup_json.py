#!/usr/bin/env python

import json
import sys

def process_json(input_file, output_file=None):
    precision = 10  # Set your desired precision here

    try:
        with open(input_file, 'r') as f:
            data = json.load(f)

        filtered_entries = []

        for entry in data.get("data", []):
            # 1. Filter: Shape must be > 0
            features = ["electron_features", "flow_features", "track_features"]
            if not all(entry.get(f, {}).get("shape", [0])[0] > 0 for f in features):
                continue

            # 2. Transform content
            for key, feature_data in entry.items():
                if isinstance(feature_data, dict) and "content" in feature_data:
                    # Flatten the nested list
                    raw_content = feature_data["content"]
                    flat = [item for sublist in raw_content for item in (sublist if isinstance(sublist, list) else [sublist])]

                    # Convert to our custom RoundingFloat
                    feature_data["content"] = [round(float(x), precision) for x in flat]

            filtered_entries.append(entry)

        data["data"] = filtered_entries

        # Output minified JSON
        if output_file:
            with open(output_file, 'w') as f:
                json.dump(data, f, separators=(',', ':'))
            print(f"Processed JSON saved to {output_file}")
        else:
            print(json.dumps(data, separators=(',', ':')))

    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    # expect input file and output file as arguments
    import argparse
    parser = argparse.ArgumentParser(description="Clean up JSON data for perf_analyzer input")
    parser.add_argument("-i", "--input-file", required=True, help="Input JSON file to process")
    parser.add_argument("-o", "--output-file", required=False, help="Output file path for cleaned JSON data (if not provided, output to stdout)")
    args = parser.parse_args()

    process_json(args.input_file, args.output_file)