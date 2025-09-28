#!/bin/bash
# Manual IOI Isolate CGroup Keeper (equivalent to isolate-cg-keeper daemon)
# This script manually manages the cgroup hierarchy that isolate-cg-keeper would handle
set -e

echo "🔧 Starting manual IOI Isolate cgroup keeper setup..."

# Create isolate slice directory (equivalent to isolate.slice)
ISOLATE_SLICE_DIR="/sys/fs/cgroup/isolate.slice"
echo "📁 Creating isolate slice directory: ${ISOLATE_SLICE_DIR}"
mkdir -p "${ISOLATE_SLICE_DIR}"

# Enable cgroup controllers for isolate slice
echo "⚙️ Enabling cgroup controllers..."
if [ -f "/sys/fs/cgroup/cgroup.controllers" ]; then
    # cgroup v2 - enable controllers
    AVAILABLE_CONTROLLERS=$(cat /sys/fs/cgroup/cgroup.controllers 2>/dev/null || echo "")
    echo "Available controllers: ${AVAILABLE_CONTROLLERS}"
    
    # Enable controllers we need for isolate
    for controller in cpu memory pids io; do
        if echo "${AVAILABLE_CONTROLLERS}" | grep -q "${controller}"; then
            echo "+${controller}" > /sys/fs/cgroup/cgroup.subtree_control 2>/dev/null || echo "Note: Could not enable ${controller} controller"
            echo "+${controller}" > "${ISOLATE_SLICE_DIR}/cgroup.subtree_control" 2>/dev/null || echo "Note: Could not enable ${controller} in isolate slice"
        fi
    done
fi

# Set up cgroup delegation (equivalent to Delegate=true in systemd)
echo "🎯 Setting up cgroup delegation..."
if [ -f "${ISOLATE_SLICE_DIR}/cgroup.procs" ]; then
    # Make sure the slice can delegate to subgroups
    echo "Slice created successfully at ${ISOLATE_SLICE_DIR}"
else
    echo "⚠️ Warning: Could not verify slice creation"
fi

# Create initial box directories structure
echo "📦 Pre-creating box directories..."
for i in {0..999}; do
    BOX_DIR="${ISOLATE_SLICE_DIR}/box-${i}"
    mkdir -p "${BOX_DIR}" 2>/dev/null || true
    
    # Set up basic cgroup files if they don't exist
    if [ -f "${BOX_DIR}/cgroup.procs" ]; then
        # Directory created successfully
        continue
    fi
done

# Function to cleanup cgroups (equivalent to daemon cleanup)
cleanup_cgroups() {
    echo "🧹 Cleaning up isolate cgroups..."
    for box_dir in /sys/fs/cgroup/isolate.slice/box-*; do
        if [ -d "${box_dir}" ]; then
            # Kill any remaining processes in the cgroup
            if [ -f "${box_dir}/cgroup.procs" ]; then
                while read -r pid; do
                    [ -n "$pid" ] && kill -9 "$pid" 2>/dev/null || true
                done < "${box_dir}/cgroup.procs"
            fi
            
            # Remove the directory
            rmdir "${box_dir}" 2>/dev/null || true
        fi
    done
}

# Set up signal handlers for cleanup (equivalent to daemon lifecycle)
trap cleanup_cgroups EXIT INT TERM

echo "✅ Manual IOI Isolate cgroup keeper setup completed"
echo "📊 Isolate slice available at: ${ISOLATE_SLICE_DIR}"
echo "🔄 Cgroup hierarchy ready for IOI Isolate sandboxes"

# Keep the cgroup hierarchy alive (equivalent to the daemon staying running)
# In systemd, isolate-cg-keeper stays running to maintain the hierarchy
# We'll do a simple version here
while true; do
    # Check if isolate slice still exists
    if [ ! -d "${ISOLATE_SLICE_DIR}" ]; then
        echo "⚠️ Isolate slice disappeared, recreating..."
        mkdir -p "${ISOLATE_SLICE_DIR}"
    fi
    
    # Periodic cleanup of empty box directories
    for box_dir in /sys/fs/cgroup/isolate.slice/box-*; do
        if [ -d "${box_dir}" ] && [ -f "${box_dir}/cgroup.procs" ]; then
            # If no processes in this box, we can clean it up
            if [ ! -s "${box_dir}/cgroup.procs" ]; then
                rmdir "${box_dir}" 2>/dev/null || true
            fi
        fi
    done
    
    sleep 30  # Check every 30 seconds
done