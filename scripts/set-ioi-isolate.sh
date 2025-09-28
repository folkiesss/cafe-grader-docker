#!/bin/bash
# Set Transparent Hugepage and Core Pattern Settings for IOI isolate
set -e

# Disable transparent hugepages
echo "Disabling transparent hugepages..."
echo never > /sys/kernel/mm/transparent_hugepage/enabled 2>/dev/null || echo "Note: Could not disable transparent hugepages"
echo never > /sys/kernel/mm/transparent_hugepage/defrag 2>/dev/null || echo "Note: Could not disable transparent hugepage defrag"
echo 0 > /sys/kernel/mm/transparent_hugepage/khugepaged/defrag 2>/dev/null || echo "Note: Could not disable khugepaged defrag"

# Set core pattern
echo "Setting core pattern..."
echo core > /proc/sys/kernel/core_pattern 2>/dev/null || echo "Note: Could not set core pattern"