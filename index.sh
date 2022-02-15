#!/bin/bash

command -v jq >/dev/null 2>&1 || { echo >&2 "jq is not installed. Aborting."; exit 1; }
command -v lighthouse >/dev/null 2>&1 || { echo >&2 "lighthouse is not installed. Aborting."; exit 1; }
command -v chrome-debug >/dev/null 2>&1 || { echo >&2 "chrome-debug is not installed. Aborting."; exit 1; }

usage() {
	echo "Usage: index.sh --base_url=base_url --chrome_debug_port=chrome_debug_port [--passes=passes] [--condition_slug=condition_slug] [--output_location=output_location] [--remove_csv_header] [--add_uniqueness_to_url]"
}

passes="5"

for i in "$@"; do
	case $i in
		--passes=* )
			passes="${i#*=}"
			shift
			;;
		--base_url=* )
			base_url="${i#*=}"
			base_url=${base_url%/} # Remove trailing slash
			shift
			;;
		--condition_slug=* )
			condition_slug="${i#*=}"
			shift
			;;
		--chrome_debug_port=* )
			chrome_debug_port="${i#*=}"
			shift
			;;
		--output_location=* )
			output_location="${i/\~/$HOME}" # Expand tilde
			output_location="${output_location#*=}"
			output_location="${output_location%/}" # Remove trailing slash
			shift
			;;
		--remove_csv_header )
			remove_csv_header="1"
			shift
			;;
		--add_uniqueness_to_url )
			add_uniqueness_to_url="1"
			shift
			;;
		* )
			usage >&2
			exit 1
	esac
done

if [ -z "$base_url" ] || [ -z "$chrome_debug_port" ]; then
	usage
	exit 1
fi

admin_url="$base_url/wp-admin/"

if [ -z "$passes" ]; then
	passes="5"
fi

if [ -z "$condition_slug" ]; then
	condition_slug="$(date +%s)"
fi

do_output() {
	local output
	output=$(cat)
	echo "$output"
	if [ -n "$output_location" ]; then
		echo "$output" >> "$output_location/$condition_slug.csv"
	fi
}

views=("index.php" "edit-comments.php" "upload.php" "edit.php" "plugins.php")

jqKeys='[".condition",".view",".requestedUrl",".fetchTime", ".firstContentfulPaint", ".firstMeaningfulPaint", ".largestContentfulPaint", ".interactive", ".speedIndex", ".totalBlockingTime", ".maxPotentialFID", ".cumulativeLayoutShift", ".cumulativeLayoutShiftMainFrame", ".totalCumulativeLayoutShift", ".serverResponseTime"]'

if [ -z "$remove_csv_header" ]; then
	echo "$jqKeys" | jq '@csv' --raw-output | do_output
fi

jq_keys_processed="${jqKeys//\"/}"

for outer_index in "${!views[@]}";
do
	view="${views[$outer_index]}"
	view_url="${admin_url}${view}"

	for ((inner_index=1; inner_index<=passes; inner_index++)); do
		if [ -n "$add_uniqueness_to_url" ];
			then
				unique_time=$(date +%s);
				query_url="$view_url?lh_for_wp_uniq=$unique_time"
			else
				query_url="$view_url"
		fi

		lighthouse "$query_url" \
			--quiet \
			--disable-storage-reset \
			--port="$chrome_debug_port" \
			--only-categories=performance \
			--output=json | \
				jq "{ condition: \"$condition_slug\", view:\"$view\" } * {requestedUrl,fetchTime} * .audits.metrics.details.items[0] * {serverResponseTime: .audits[\"server-response-time\"].numericValue}" | \
				jq "$jq_keys_processed | @csv" --raw-output | do_output
	done
done
