#!/bin/bash -l

# turn off swap and address space layout randomization
swapoff -a
echo 0 > /proc/sys/kernel/randomize_va_space

# start isolate
systemctl daemon-reload
systemctl start set-ioi-isolate.service
systemctl start isolate.service

# verify isolate environment check
isolate-check-environment

# start cron
# service cron start

echo -e "Installing language support packages..."
# Language support setup
source /venv/grader/bin/activate

if [ -n "${PYTHON_PACKAGES:-}" ]; then
    pip install ${PYTHON_PACKAGES}
else
    echo "No Python packages to install."
fi

echo -e "Language support packages installed."

# restart grader workers
echo -e "Starting grader workers..."

cd /cafe-grader/web
RAILS_ENV=production rails r "Grader.restart(${GRADER_PROCESSES})"

# update crontab via whenever
whenever --update-crontab

# start solid_queue
rails solid_queue:start

echo -e "Grader workers started."