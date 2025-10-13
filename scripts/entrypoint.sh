#!/bin/bash -l

# turn off swap and address space layout randomization
swapoff -a
echo 0 > /proc/sys/kernel/randomize_va_space

echo -e "Installing language support packages..."
# Language support setup
source /venv/grader/bin/activate

if [ -n "${PYTHON_PACKAGES:-}" ]; then
    pip install ${PYTHON_PACKAGES}
else
    echo "No Python packages to install."
fi

echo -e "Language support packages installed."

exec /usr/sbin/init
