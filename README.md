# Lighthouse Comparisons for WordPress Sites

After a report from a user that installing a WordPress plugin adds seconds of load time to their wp-admin, [@dereksmart](https://github.com/dereksmart) and I wanted a way to compare before and after performance metrics for that site.

Because we would be testing a unique set of circumstances on this user's site and because we were more interested in the performance deltas a short window of time, rather than performance metrics over time, it seemed reasonable to just run many Lighthouse tests and then export the data to CSV for analyzing in Google Sheets. We did the first pass of this manually.

Afterwards, I worked on this script to make future testing much simpler.

## Requirments

This script expects that you have the following installed:

- jq
- [lighthouse](https://github.com/GoogleChrome/lighthouse#using-the-node-cli)
- [chrome-debug](https://github.com/GoogleChrome/lighthouse/blob/master/docs/authenticated-pages.md#option-4-open-a-debug-instance-of-chrome-and-manually-log-in)

## Usage

- Get Chrome debugging port
  - Open terminal window and run `chrome-debug`
  - In the Chrome window that pops up, log in to the wp-admin of the site that you want to test
  - After logging in, go back to terminal window where you called `chrome-debug` and copy the Chrome debugging port
- Run Script
  - Open new terminal window
  - Run script: `index.sh --base_url=base_url --chrome_debug_port=chrome_debug_port [--passes=passes] [--condition_slug=condition_slug] [--output_location=output_location]`
    - `base_url`: This is the `siteurl` value from the site, where the WordPress installation actually lives. The script will append `/wp-admin` to the URL to get the wp-admin URL used for testing.
    - `chrome_debug_port`: See above.
    - `passes`: How many times should a Lighthouse test be run for each URL? Default is 5.
    - `condition_slug`: This is used to build the filename and also in the resulting CSV output for analyzing later. Defaults to the timestamp when the script was started.
    - `output_location`: When set, will output a CSV file to this directory with a filename of `condition_slug.csv`.
