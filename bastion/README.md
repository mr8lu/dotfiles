# Bastion Scripts & Cron

> **Note:** The broader `bastion/` module is being built on `feat/bastion-harness` and this README may be merged into it.

## DO spend check (billing-alert substitute)

DigitalOcean has no API or `doctl` command for configuring billing alerts. `bastion/bin/do-spend-check.sh` acts as a daily billing-alert substitute by querying month-to-date spend via `doctl balance get -o json` and comparing it against a configurable dollar threshold.

### Environment Variables

- `THRESHOLD`: Alert threshold in USD (default: `35`).
- `DRY_RUN=1`: Compute and print the decision (`DRY_RUN <timestamp> usage=<usage> threshold=<threshold> status=OK|ALERT`) without creating directories or writing any log, state, or alert files.

### Files

- `~/logs/do-spend-check.log`: Append-only log recording one status line (`<timestamp> usage=<usage> threshold=<threshold> status=OK|ALERT`) or error line (`<timestamp> ERROR: <reason>`) per run.
- `~/state/do-spend.json`: Atomically updated JSON snapshot (`{"checked_at": "...", "month_to_date_usage": <number>, "threshold": <number>, "over": true|false}`).
- `~/state/do-spend-ALERT`: Created with a human-readable alert message when spend exceeds `THRESHOLD`, and removed (`rm -f`) when spend is at or below `THRESHOLD`. Agents and automated routines poll this file to detect active spend alerts.

### Installation

1. Copy the script to `~/bin` and make it executable:
   ```bash
   mkdir -p ~/bin
   cp bastion/bin/do-spend-check.sh ~/bin/do-spend-check.sh
   chmod +x ~/bin/do-spend-check.sh
   ```
2. Append the cron entry:
   ```bash
   (crontab -l; cat bastion/cron/do-spend-check.cron) | crontab -
   ```

### Timezone Note

Ubuntu 24.04 `cron` (`3.0pl1`) ignores `CRON_TZ`, and the bastion clock runs in UTC. The crontab entry in `bastion/cron/do-spend-check.cron` triggers at both `13:00` and `14:00` UTC and guards execution with `[ "$(TZ=America/New_York date +\%H)" = 09 ]`, ensuring the check runs once daily at 9:00 AM `America/New_York` year-round across EST/EDT daylight saving transitions.
