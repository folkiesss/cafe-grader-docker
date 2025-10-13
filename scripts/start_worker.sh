#!/bin/bash -l

# verify isolate environment check
isolate-check-environment

# restart grader workers
echo -e "Starting grader workers..."

cd /cafe-grader/web
RAILS_ENV=production rails r "Grader.restart(${GRADER_PROCESSES})"

# update crontab via whenever
whenever --update-crontab

echo -e "Grader workers started."