# Scripts Directory

This directory contains helper scripts for managing your Rezio SaaS deployment.

## 🚀 Available Scripts

### 1. **setup-env.sh** - Interactive Environment Setup
**Purpose:** Create `.env` file with guided wizard  
**Use when:** First time setup or when you need to reconfigure

```bash
./scripts/setup-env.sh
```

**What it does:**
- Guides you through creating accounts (Neon, Clerk, Cloudinary)
- Prompts for all required credentials
- Creates secure `.env` file
- Optionally initializes database

---

### 2. **deploy.sh** - Manual Deployment
**Purpose:** Build and deploy application manually  
**Use when:** You want to deploy without Jenkins

```bash
./scripts/deploy.sh
```

**What it does:**
- Stops existing container
- Builds fresh Docker image
- Runs database migrations
- Starts new container on port 2000
- Performs health checks

---

### 3. **rollback.sh** - Version Rollback
**Purpose:** Rollback to previous deployment  
**Use when:** New deployment has issues

```bash
./scripts/rollback.sh
```

**What it does:**
- Lists available Docker images
- Prompts you to select version
- Stops current container
- Starts container with selected version
- Verifies deployment

---

### 4. **manage.sh** - Interactive Management Menu
**Purpose:** Easy access to common management tasks  
**Use when:** You need to check status, view logs, or manage the app

```bash
./scripts/manage.sh
```

**Features:**
1. Show container status
2. View application logs
3. Follow logs in real-time
4. Restart container
5. Stop container
6. Start container
7. Check health
8. Enter container shell
9. View Docker images
10. Clean up Docker resources
11. Run Prisma migrations
12. View Prisma migration status

---

## 📋 Typical Workflow

### First Time Setup:
```bash
# 1. Create environment configuration
./scripts/setup-env.sh

# 2. Test locally first
npm run dev

# 3. If working, deploy manually or use Jenkins
./scripts/deploy.sh
```

### Regular Deployment:
```bash
# Option 1: Jenkins (automated)
# Just push to Git, Jenkins handles everything

# Option 2: Manual deployment
./scripts/deploy.sh
```

### Managing Application:
```bash
# Interactive menu (easiest)
./scripts/manage.sh

# Or use specific commands
docker logs -f rezio-saas-container  # View logs
docker restart rezio-saas-container   # Restart
```

### Emergency Rollback:
```bash
./scripts/rollback.sh
```

---

## 🔧 Requirements

All scripts require:
- **Docker** installed and running
- **Node.js** and npm (for local development)
- **Bash** shell (available on Linux, macOS, WSL)

---

## 🆘 Troubleshooting

### Permission Denied
```bash
chmod +x scripts/*.sh
```

### Script Not Found
```bash
# Make sure you're in project root
cd /path/to/rezio-saas
./scripts/script-name.sh
```

### Docker Not Running
```bash
# Start Docker
sudo systemctl start docker  # Linux
# or open Docker Desktop on macOS/Windows
```

---

## 📚 More Information

- **Complete Setup Guide:** `../SETUP_FROM_SCRATCH.md`
- **Deployment Guide:** `../DEPLOYMENT.md`
- **Quick Reference:** `../QUICK_REFERENCE.md`

---

**All scripts are production-ready and tested!** 🚀
