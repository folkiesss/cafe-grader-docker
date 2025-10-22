# Cafe Grader Docker

A containerized version of the [CU Cafe Grader](https://github.com/nattee/cafe-grader-web) competitive programming judging system.

## Table of Contents

- [Docker Architecture](#docker-architecture)
- [Platform Compatibility](#platform-compatibility)
- [Host Machine Setup](#host-machine-setup)
- [Quick Start](#quick-start)
- [Default Credential](#default-credential)
- [Language Setup](#language-setup)
- [Data Persistence](#data-persistence)
- [Development](#development)
- [Logging](#logging)
- [Acknowledgements](#acknowledgements)
- [Source](#source)
- [License](#license)

## Docker Architecture

This Docker Compose setup consists of **3 containers**:

- **cafe-grader-web**: Web interface for Cafe Grader management
- **cafe-grader-worker**: Background worker for submission compilation and judging
- **cafe-grader-db**: MySQL database for storing data

## Platform Compatibility

- ✅ **Fully Supported**:
   - **Native Linux**: Fully functionbility (requires kernel cgroup configuration)
   - **macOS**: Full functionality with Docker
- ⚠️ **Limited Support**: 
   - **WSL (Windows Subsystem for Linux)**: Works but may affect some binary integrations like VS Code due to systemd compatibility issues
- ❓ **Untested**:
   - **Windows Docker Desktop**: Compatibility not yet verified

## Host Machine Setup

Since Docker uses the host's kernel, we need to enable memory cgroups for proper isolation and resource management. This is required for IOI Isolate to function correctly.

> **Note**: This step is only required for Linux machines. macOS and Windows(WSL) users can skip this section.

### **Linux Machine**

1. Edit the GRUB configuration file:
   ```bash
   sudo vi /etc/default/grub
   ```

2. Add `cgroup_enable=memory` to the `GRUB_CMDLINE_LINUX_DEFAULT` line:
   ```bash
   GRUB_CMDLINE_LINUX_DEFAULT="cgroup_enable=memory"
   ```

3. Update GRUB and reboot:
   ```bash
   sudo update-grub
   sudo reboot
   ```

### **Raspberry Pi**

1. Edit the boot configuration:
   ```bash
   sudo vi /boot/firmware/cmdline.txt
   ```

2. Add `cgroup_enable=memory` to the existing line:
   ```
   console=serial0,115200 multipath=off ... fixrtc cgroup_enable=memory
   ```

3. Reboot the system:
   ```bash
   sudo reboot
   ```
Then reboot using `sudo reboot`.


## Quick Start

1. **Clone the repository:**
   ```bash
   git clone --recurse-submodules https://github.com/folkiesss/cafe-grader-docker.git
   cd cafe-grader-docker
   ```

2. **Create environment file:**
   Create a `.env` file with the following variables:
   ```bash
   # Grader
   GRADER_PROCESSES=2

   # Python Packages for Judge Environment
   # Space-separated list of Python packages to install in the grader virtual environment
   # For example: PYTHON_PACKAGES=numpy pandas matplotlib scipy
   PYTHON_PACKAGES=

   # MYSQL
   MYSQL_ROOT_PASSWORD=superStr@ngP@ssw0rd
   MYSQL_DATABASE=grader
   MYSQL_USER=grader_user
   MYSQL_PASSWORD=superStr@ngP@ssw0rd

   # Database Connection
   SQL_DATABASE_CONTAINER_HOST=cafe-grader-db
   SQL_DATABASE_PORT=3306

   # Rails Configuration
   RAILS_TIME_ZONE=Asia/Bangkok
   SECRET_KEY_BASE=GENERATE_A_SECURE_KEY_BASE_FOR_PRODUCTION  # can generate using `openssl rand -hex 64`
   ```

3. **Build and run:**
   ```bash
   docker compose build
   docker compose up -d
   ```

4. **Access the application:**
   Web interface: http://localhost:3000. 

## Default Credential

- User: `root`
- Password: `ioionrails`

## Language Setup

The worker container includes support for:

**Tested:**
- **Python**
- **C/C++**
- **Ruby**
- **Go**
- **Rust**

**To be tested (and updated for some languages):**
- **Java**
- **Pascal**
- **PHP**
- **Haskell**

Please refer to https://github.com/cafe-grader-team/cafe-grader-web/wiki/Language-Setup for specific details

## Data Persistence

The setup uses Docker volumes for data persistence:

- **Database data**: Stored in `cafe-grader-db` volume
- **Storage data**: Stored in `cafe-grader-storage` volume (test cases, problem files, uploads)
- **Cache data**: Stored in `cafe-grader-cache` volume (judge working directory)
- **Logs**: Optional volume mounting (uncomment in `compose.yaml`)

### Backup and Restore

This repository includes automated backup and restore scripts for easy data management.

#### **Create a Backup**

```bash
./backup.sh
```

This will create a timestamped backup archive in the `backups/` directory:

```
cafe-grader-docker/
├── backup.sh
├── restore.sh
└── backups/
    └── cafe-grader-backup-dd-mm-yyyy-hhmmss.tar.gz
```

The backup archive contains:
- Database (SQL dump)
- Storage volume (test cases, problem files, Active Storage files)
- Cache volume (judge data, compiled submissions)

#### **List Available Backups**

```bash
./restore.sh
```

This shows all available backup archives.

#### **Restore from Backup**

```bash
./restore.sh <archive_file>
```

> **Note**: The `MYSQL_ROOT_PASSWORD` in your `.env` file must match the password used when the backup was created.

#### **Migrate to Another Machine**

1. Copy the backup archive to the target machine's `backups/` directory (using any method: USB drive, network transfer, cloud storage, etc.)

2. **Place the backup** in the `backups/` directory.

3. Restore the backup.

## Development

### Building Individual Services

```bash
# Build worker only
docker build -f worker.Dockerfile -t cafe-grader-worker .

# Build web only  
docker build -f web.Dockerfile -t cafe-grader-web .
```

### Fallback

Both `Dockerfile`s (`*.Dockerfile`) use `git clone` to clone the latest version of Cafe Grader from https://github.com/nattee/cafe-grader-web. However, in case the newer version can't be built, please try to follow the following instructions.

1. **Update submodule (in case this repo is outdated):**

   ```bash
   git submodule update --remote
   ```

2. **Check out to a specific version that still works:**
   ```bash
   cd cafe-grader-web
   git checkout <commit_sha>
   ```

3. **Edit this section in both `Dockerfile` then try to rebuild:**
   ```Dockerfile
   # clone cafe-grader-web
   RUN git clone https://github.com/nattee/cafe-grader-web.git /cafe-grader/web

   # fallback if the latest version of cafe-grader-web is not compatible
   # COPY cafe-grader-web /cafe-grader/web
   ```

   It should look like this:
   ```Dockerfile
   # clone cafe-grader-web
   # RUN git clone https://github.com/nattee/cafe-grader-web.git /cafe-grader/web

   # fallback if the latest version of cafe-grader-web is not compatible
   COPY cafe-grader-web /cafe-grader/web
   ```

## Logging

Please uncomment the logs volume in the [`compose.yaml`](compose.yaml) file for saving logs.

## Acknowledgements

This containerization wouldn't be complete without the efforts of these people:

- **My greatest TA of all time** ([PongDev](https://github.com/PongDev)): For advice during the [isolate](https://github.com/ioi/isolate) cgroup debugging process.

## Source

- [Cafe Grader](https://github.com/nattee/cafe-grader-web) - The cafe-grader forks at Chula
- [IOI Isolate](https://github.com/ioi/isolate) - Secure sandbox system

## License

This Docker containerization setup (Dockerfiles, compose configuration, and related scripts) is licensed under the **MIT License**. See the [LICENSE](LICENSE) file for details.

This containerization is provided as-is for educational and development purposes. Please refer to the [Cafe Grader project](https://github.com/nattee/cafe-grader-web) for licensing information about the main application.