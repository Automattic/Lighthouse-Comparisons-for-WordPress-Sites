#!/bin/bash

command -v jq >/dev/null 2>&1 || { echo >&2 "jq is not installed. Aborting."; exit 1; }
command -v lighthouse >/dev/null 2>&1 || { echo >&2 "lighthouse is not installed. Aborting."; exit 1; }
command -v chrome-debug >/dev/null 2>&1 || { echo >&2 "chrome-debug is not installed. Aborting."; exit 1; }

PASSES="5"

for i in "$@"; do
	case $i in
		--passes=* )
			PASSES="${i#*=}"
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
		echo "$output" >> "$output_location/$conditionSlug.csv"
	fi
}

echo "What is the base URL of the site that you want to test?"
read -r baseUrlInput

echo ""
echo "What is the slug for the condition that you're testing?"
read -r conditionSlug

baseUrl=${baseUrlInput%/} # Remove trailing slash from argument
adminUrl="$baseUrl/wp-admin/"

echo ""
echo "In a separate terminal window run chrome-debug and then log in to your site at $adminUrl"
echo ""
echo "What is the Chrome debugging port?"
read -r chromeDebugPort

views=("index.php" "edit-comments.php" "upload.php" "edit.php" "plugins.php")

jqKeys='[".condition,.requestedUrl",".fetchTime", ".firstContentfulPaint", ".firstMeaningfulPaint", ".largestContentfulPaint", ".interactive", ".speedIndex", ".totalBlockingTime", ".maxPotentialFID", ".cumulativeLayoutShift", ".cumulativeLayoutShiftMainFrame", ".totalCumulativeLayoutShift", ".serverResponseTime"]'
echo "$jqKeys" | jq '@csv' --raw-output | do_output

jqKeysProcessed="${jqKeys//\"/}"

for outerIndex in "${!views[@]}";
do
	view="${views[$outerIndex]}"
	fullUrl="${adminUrl}${view}"

	for ((innerLoop=1; innerLoop<=PASSES; innerLoop++)); do
		lighthouse "$fullUrl" \
			--quiet \
			--disable-storage-reset \
			--port="$chromeDebugPort" \
			--only-categories=performance \
			--output=json | \
				jq "{ condition: \"$conditionSlug\" } * {requestedUrl,fetchTime} * .audits.metrics.details.items[0] * {serverResponseTime: .audits[\"server-response-time\"].numericValue}" | \
				jq "$jqKeysProcessed | @csv" --raw-output | do_output
	done
done
