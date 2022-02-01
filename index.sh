#!/bin/bash

command -v jq >/dev/null 2>&1 || { echo >&2 "jq is not installed. Aborting."; exit 1; }
command -v lighthouse >/dev/null 2>&1 || { echo >&2 "lighthouse is not installed. Aborting."; exit 1; }
command -v chrome-debug >/dev/null 2>&1 || { echo >&2 "chrome-debug is not installed. Aborting."; exit 1; }

echo "What is the base URL of the site that you want to test?"
read -r baseUrlInput

baseUrl=${baseUrlInput%/} # Remove trailing slash from argument
adminUrl="$baseUrl/wp-admin/"

echo ""
echo "In a separate terminal window run chrome-debug and then log in to your site at $adminUrl"
echo ""
echo "What is the Chrome debugging port?"
read -r chromeDebugPort

views=("index.php" "edit-comments.php" "upload.php" "edit.php" "plugins.php")


jqKeys="[.requestedUrl, .fetchTime, .firstContentfulPaint, .firstMeaningfulPaint, .largestContentfulPaint, .interactive, .speedIndex, .totalBlockingTime, .maxPotentialFID, .cumulativeLayoutShift, .cumulativeLayoutShiftMainFrame, .totalCumulativeLayoutShift, .serverResponseTime]"

# TODO: echo keys as header

for outerIndex in "${!views[@]}";
do
	view="${views[$outerIndex]}"
	fullUrl="${adminUrl}${view}"

	for innerIndex in {1..5};
	do
		lighthouse "$fullUrl" \
		--quiet \
		--disable-storage-reset \
		--port="$chromeDebugPort" \
		--only-categories=performance \
		--output=json | \
			jq '{requestedUrl,fetchTime} * .audits.metrics.details.items[0] * {serverResponseTime: .audits["server-response-time"].numericValue}' | \
			jq "$jqKeys | @csv"
	done
done
