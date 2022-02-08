#!/bin/bash

command -v jq >/dev/null 2>&1 || { echo >&2 "jq is not installed. Aborting."; exit 1; }
command -v lighthouse >/dev/null 2>&1 || { echo >&2 "lighthouse is not installed. Aborting."; exit 1; }
command -v chrome-debug >/dev/null 2>&1 || { echo >&2 "chrome-debug is not installed. Aborting."; exit 1; }

passes="5"

for i in "$@"; do
	case $i in
		--passes=* )
			passes="${i#*=}"
			shift
			;;
		--output_location=* )
			output_location="${i/\~/$HOME}"
			output_location="${output_location#*=}"
			shift
			;;
	esac
done

do_output() {
	local output
	output=$(cat)
	echo "$output"
	if [ -n "$output_location" ]; then
		echo "$output" >> "$output_location/$condition_slug.csv"
	fi
}

echo "What is the base URL of the site that you want to test?"
read -r base_url_input

echo ""
echo "What is the slug for the condition that you're testing?"
read -r condition_slug

base_url=${base_url_input%/} # Remove trailing slash from argument
admin_url="$base_url/wp-admin/"

echo ""
echo "In a separate terminal window run chrome-debug and then log in to your site at $admin_url"
echo ""
echo "What is the Chrome debugging port?"
read -r chrome_debug_port

views=("index.php" "edit-comments.php" "upload.php" "edit.php" "plugins.php")

jqKeys='[".condition,.requestedUrl",".fetchTime", ".firstContentfulPaint", ".firstMeaningfulPaint", ".largestContentfulPaint", ".interactive", ".speedIndex", ".totalBlockingTime", ".maxPotentialFID", ".cumulativeLayoutShift", ".cumulativeLayoutShiftMainFrame", ".totalCumulativeLayoutShift", ".serverResponseTime"]'
echo "$jqKeys" | jq '@csv' --raw-output | do_output

jq_keys_processed="${jqKeys//\"/}"

for outer_index in "${!views[@]}";
do
	view="${views[$outer_index]}"
	fullUrl="${admin_url}${view}"

	for ((inner_index=1; inner_index<=passes; inner_index++)); do
		lighthouse "$fullUrl" \
			--quiet \
			--disable-storage-reset \
			--port="$chrome_debug_port" \
			--only-categories=performance \
			--output=json | \
				jq "{ condition: \"$condition_slug\" } * {requestedUrl,fetchTime} * .audits.metrics.details.items[0] * {serverResponseTime: .audits[\"server-response-time\"].numericValue}" | \
				jq "$jq_keys_processed | @csv" --raw-output | do_output
	done
done
