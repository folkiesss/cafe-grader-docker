# Cafe Grader Docker

A containerized of the [Cafe Grader](https://github.com/nattee/cafe-grader-web).

## Architecture

This Docker Compose setup consists of **3 containers** working together:

- **cafe-grader-web**: Web interface for contest management
- **cafe-grader-worker**: Background worker for code compilation and judging
- **cafe-grader-db**: MySQL database for storing contest data

## Platform Compatibility

✅ **Fully Supported (Linux/WSL)**: Complete IOI Isolate functionality with memory limits  
⚠️ **Partial Support (macOS/Windows)**: Basic functionality, memory limits may be imprecise

## Host System Requirements

**Note**: The following kernel parameter configuration **only works on Linux and WSL**. Docker Desktop on macOS/Windows will show warnings but the system will still function.



### Linux Host Configuration

If deploying on a Linux server, you need to enable cgroup memory control and swap accounting:

#### 1. Enable Kernel Parameters

Edit `/etc/default/grub` and modify/add the following line:

```bash
GRUB_CMDLINE_LINUX_DEFAULT="cgroup_enable=memory swapaccount=1"
```

#### 2. Update GRUB and Reboot

```bash
sudo update-grub
sudo reboot
```

#### 3. Verify Configuration

After reboot, verify the parameters are active:

```bash
cat /proc/cmdline | grep -E "(cgroup_enable=memory|swapaccount=1)"
```

You should see both parameters in the output.

### macOS/Windows with Docker Desktop

**Important**: The cgroup settings above **cannot be applied** in Docker Desktop environments. However, the system will still work with these limitations:

- ⚠️ **Memory limits may be imprecise** - IOI Isolate cannot enforce strict memory limits
- ⚠️ **Warning messages** - You'll see swap accounting warnings during startup
- ✅ **Core functionality works** - Code compilation and basic judging still function
- ✅ **Development ready** - Perfect for development and testing

For **production use**, deploy on a Linux server or use WSL on Windows.

## Quick Start

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd cafe-grader-docker
   ```

2. **Create environment file:**
   ```bash
   cp .env.example .env
   # Edit .env with your database credentials
   ```

3. **Build and run:**
   ```bash
   docker-compose up --build
   ```

4. **Access the application:**
   - Web interface: http://localhost:3000
   - Database: localhost:3306

## Environment Variables

Create a `.env` file with the following variables:

```bash
# Database Configuration
MYSQL_ROOT_PASSWORD=rootpassword
MYSQL_DATABASE=cafe_grader_production
MYSQL_USER=cafe_grader
MYSQL_PASSWORD=password
SQL_DATABASE_PORT=3306

# Rails Configuration
RAILS_TIME_ZONE=Asia/Bangkok
SECRET_KEY_BASE=your_secret_key_here

# Optional Worker Configuration
CAFE_GRADER_SERVER_KEY=c2f7966dee
CAFE_GRADER_WORKER_ID=1
CAFE_GRADER_WORKER_PASSCODE=your_worker_passcode
```

## Supported Programming Languages

The worker container includes support for:

- **C/C++**: GCC compiler
- **Java**: OpenJDK 21 LTS
- **Python**: Python 3 with numpy in virtual environment (`/venv/grader/`)
- **Ruby**: Ruby 3.4.4 via RVM
- **Pascal**: Free Pascal Compiler (FPC)
- **PHP**: PHP CLI
- **Go**: Go compiler
- **Rust**: Rust compiler (cargo)
- **Haskell**: Glasgow Haskell Compiler (GHC)

## IOI Isolate

The system uses IOI Isolate for secure code execution with:

- Memory limits enforcement
- CPU time limits
- Filesystem isolation
- Network isolation
- Process limits

### Known Limitations

- **Swap accounting**: May not be available in all Docker environments
- **Memory limits**: May be less precise without swap accounting
- **Privileged container**: Required for isolate functionality

## Troubleshooting

### Swap Accounting Warnings

If you see warnings about swap accounting:

```
WARNING: swap is enabled, but swap accounting is not. isolate will not be able to enforce memory limits.
```

**Platform-specific guidance:**

- **Linux/WSL**: Follow the kernel parameter configuration above to fix this
- **macOS/Windows Docker Desktop**: This is expected and cannot be fixed - the system will still work
- **Production**: Always use Linux servers with proper cgroup configuration

### IOI Isolate Check Failures

The `isolate-check-environment` command may show warnings during startup. This is normal in containerized environments where some system-level features are managed by the host.

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

## Production Deployment

1. **Configure host system** (Linux only) - see Host System Requirements
2. **Set strong passwords** in environment variables
3. **Configure SSL/TLS** for web interface
4. **Set up backup** for database volume
5. **Monitor resource usage** for worker containers

## License

MIT License - see LICENSE file for details