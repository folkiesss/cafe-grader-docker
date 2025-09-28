#!/bin/bash
# Simple IOI Isolate CGroup Setup (non-daemon version)
# Sets up the cgroup hierarchy that isolate needs
set -e

echo "🔧 Setting up IOI Isolate cgroup hierarchy..."

# Create isolate slice directory structure
ISOLATE_SLICE_DIR="/sys/fs/cgroup/isolate.slice"
echo "📁 Creating isolate slice: ${ISOLATE_SLICE_DIR}"
mkdir -p "${ISOLATE_SLICE_DIR}"

# Set up cgroup v2 controllers
if [ -f "/sys/fs/cgroup/cgroup.controllers" ]; then
    echo "⚙️ Enabling cgroup v2 controllers..."
    
    # Enable controllers in root cgroup
    for controller in cpu memory pids io; do
        echo "+${controller}" > /sys/fs/cgroup/cgroup.subtree_control 2>/dev/null || echo "Note: ${controller} controller may not be available"
    done
    
    # Enable controllers in isolate slice
    for controller in cpu memory pids io; do
        echo "+${controller}" > "${ISOLATE_SLICE_DIR}/cgroup.subtree_control" 2>/dev/null || echo "Note: ${controller} controller may not be available in slice"
    done
fi

# Pre-create some box directories for better performance
echo "📦 Pre-creating box directories..."
for i in {0..99}; do
    mkdir -p "${ISOLATE_SLICE_DIR}/box-${i}" 2>/dev/null || true
done

# Verify setup
if [ -d "${ISOLATE_SLICE_DIR}" ]; then
    echo "✅ IOI Isolate cgroup hierarchy created successfully"
    echo "📊 Available at: ${ISOLATE_SLICE_DIR}"
else
    echo "❌ Failed to create isolate cgroup hierarchy"
    exit 1
fi