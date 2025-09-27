# Cafe Grader Docker

A containerized version of the [Cafe Grader](https://github.com/nattee/cafe-grader-web) competitive programming judging system.

## Table of Contents

- [Architecture](#architecture)
- [Platform Compatibility](#platform-compatibility)
- [Host System Requirements](#host-system-requirements)
- [Quick Start](#quick-start)
- [Supported Programming Languages](#supported-programming-languages)
- [Development](#development)
- [License](#license)

## Architecture

This Docker Compose setup consists of **3 containers** for scalabity:

- **cafe-grader-web**: Web interface for contest management
- **cafe-grader-worker**: Background worker for code compilation and judging
- **cafe-grader-db**: MySQL database for storing contest data

## Platform Compatibility

✅ **Fully Supported (Native Linux)**: Complete IOI Isolate functionality with memory limits  
⚠️ **Partial Support (WSL)**: Basic functionality, memory limits may be imprecise  
⚠️ **Limited Support (macOS/Windows Docker Desktop)**: Worker will start but ***<u>SUBMISSIONS CANNOT BE JUDGED</u>***

## Host System Requirements

### Linux Host Configuration

If deploying on a Linux server, you need to enable cgroup memory control and swap accounting:

#### 1. Turn off memory swap (for memory limit function)

```bash
sudo swapoff -a
```

#### 2. Enable Kernel Parameters

Edit `/etc/default/grub` and modify/add the following line:

```bash
GRUB_CMDLINE_LINUX_DEFAULT="cgroup_enable=memory swapaccount=1"
```

#### 3. Update GRUB and Reboot

```bash
sudo update-grub
sudo reboot
```

### Checking Worker Compatibility

To verify that the worker container and IOI Isolate are functioning correctly, you can run the environment check:

```bash
# Check IOI Isolate environment compatibility
docker exec -it cafe-grader-worker isolate-check-environment
```

### WSL
- TBA

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
   GRADER_WORKER_THREADS=4

   # Python Packages for Judge Environment
   # Space-separated list of Python packages to install in the grader virtual environment
   PYTHON_PACKAGES=numpy

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
   SECRET_KEY_BASE=GENERATE_A_SECURE_KEY_BASE_FOR_PRODUCTION  # using `openssl rand -hex 64`
   ```

3. **Build and run:**
   ```bash
   docker-compose up
   ```

4. **Access the application:**
   - Web interface: http://localhost:3000

## Supported Programming Languages

The worker container includes support for:

**Tested:**
- **Python**: Python 3 with numpy in virtual environment (`/venv/grader/`)

**To be tested:**
- **C/C++**: GCC compiler
- **Java**: OpenJDK 21 LTS
- **Ruby**: Ruby 3.4.4 via RVM
- **Pascal**: Free Pascal Compiler (FPC)
- **PHP**: PHP CLI
- **Go**: Go compiler
- **Rust**: Rust compiler (cargo)
- **Haskell**: Glasgow Haskell Compiler (GHC)

## Development

### Building Individual Services

```bash
# Build worker only
docker build -f Dockerfile.worker -t cafe-grader-worker .

# Build web only  
docker build -f Dockerfile.web -t cafe-grader-web .
```

### Accessing Container Logs

```bash
# View all logs
docker-compose logs

# Follow specific service logs
docker-compose logs -f cafe-grader-worker
```

## License

MIT License - see LICENSE file for details