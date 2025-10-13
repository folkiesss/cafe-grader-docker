#!/bin/bash -l

# Export Docker environment variables to a file for systemd services
mkdir -p /etc/cafe-grader
{
  echo "SECRET_KEY_BASE=${SECRET_KEY_BASE}"
  echo "MYSQL_USER=${MYSQL_USER}"
  echo "MYSQL_PASSWORD=${MYSQL_PASSWORD}"
  echo "SQL_DATABASE_CONTAINER_HOST=${SQL_DATABASE_CONTAINER_HOST}"
  echo "SQL_DATABASE_PORT=${SQL_DATABASE_PORT}"
} > /etc/cafe-grader/environment

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
