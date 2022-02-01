# Lighthouse Comparisons for WordPress Sites

After a report from a user that installing a WordPress plugin adds seconds of load time to their wp-admin, I wanted a way to compare before and after performance metrics for that site.

@dereksmart and I worked together for a few hours to come up with a process that involved manually running Lighthouse reports and then post-processing that data such that we could pull it into a spreadsheet.

This script is meant to automate much of that work to simplify future testing.

It is very much still in progress.

## Requirments

This script expects that you have the following installed:

- jq
- [lighthouse](https://github.com/GoogleChrome/lighthouse#using-the-node-cli)
- [chrome-debug](https://github.com/GoogleChrome/lighthouse/blob/master/docs/authenticated-pages.md#option-4-open-a-debug-instance-of-chrome-and-manually-log-in)
