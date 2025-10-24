# Rezio SaaS - Deployment Guide for EC2 with Jenkins CI/CD

This guide will help you set up automated CI/CD deployment for Rezio SaaS on your EC2 instance using Jenkins.

## 📋 Prerequisites

### On Your EC2 Instance:
- Ubuntu/Amazon Linux 2 (recommended)
- At least 2GB RAM, 2 vCPU
- Port 2000 open in security group for the application
- Port 8080 open for Jenkins (optional, can be restricted to your IP)
- SSH access configured

## 🚀 Initial EC2 Setup

### 1. Connect to Your EC2 Instance
```bash
ssh -i your-key.pem ubuntu@your-ec2-ip
```

### 2. Update System Packages
```bash
sudo apt update && sudo apt upgrade -y
```

### 3. Install Docker
```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add your user to docker group
sudo usermod -aG docker $USER
sudo usermod -aG docker ubuntu

# Start Docker service
sudo systemctl enable docker
sudo systemctl start docker

# Verify installation
docker --version
```

### 4. Install Jenkins
```bash
# Install Java (Jenkins requirement)
sudo apt install -y openjdk-17-jdk

# Add Jenkins repository
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null

echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

# Install Jenkins
sudo apt update
sudo apt install -y jenkins

# Start Jenkins
sudo systemctl enable jenkins
sudo systemctl start jenkins

# Get initial admin password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

### 5. Install Node.js (for Jenkins builds)
```bash
# Install Node.js 20.x
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Verify installation
node --version
npm --version
```

### 6. Configure Jenkins User for Docker
```bash
# Add jenkins user to docker group
sudo usermod -aG docker jenkins

# Restart Jenkins to apply changes
sudo systemctl restart jenkins
```

## 🔧 Jenkins Configuration

### 1. Access Jenkins
- Open browser: `http://your-ec2-ip:8080`
- Enter the initial admin password from step 4 above
- Install suggested plugins
- Create admin user

### 2. Install Required Plugins
Go to: `Manage Jenkins` → `Plugins` → `Available plugins`

Install:
- **Docker Pipeline**
- **Git**
- **Pipeline**
- **Credentials Binding**
- **Environment Injector**

### 3. Create Jenkins Pipeline Job

1. Click `New Item`
2. Enter name: `rezio-saas-deploy`
3. Select `Pipeline`
4. Click `OK`

#### Configure Pipeline:
- **General Section:**
  - ✓ Check "Discard old builds" → Keep last 10 builds

- **Build Triggers:**
  - ✓ "GitHub hook trigger for GITScm polling" (if using GitHub webhooks)
  - OR ✓ "Poll SCM" with schedule: `H/5 * * * *` (every 5 minutes)

- **Pipeline Section:**
  - Definition: `Pipeline script from SCM`
  - SCM: `Git`
  - Repository URL: `your-git-repository-url`
  - Credentials: Add your Git credentials if private repo
  - Branch: `*/main` (or your branch name)
  - Script Path: `Jenkinsfile`

### 4. Set Up Environment File on EC2

Create the environment file that the pipeline expects:

```bash
# Create directory
mkdir -p /home/ubuntu/rezio-saas

# Create .env file
sudo nano /home/ubuntu/rezio-saas/.env
```

Copy your environment variables (see `.env.example`):
```env
DATABASE_URL="postgresql://USER:PASSWORD@HOST:PORT/DBNAME?schema=public"
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY="pk_live_xxxxx"
CLERK_SECRET_KEY="sk_live_xxxxx"
NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME="your_cloud_name"
NEXT_PUBLIC_CLOUDINARY_UPLOAD_PRESET="unsigned_preset_name"
CLOUDINARY_API_KEY="your_api_key"
CLOUDINARY_API_SECRET="your_api_secret"
NODE_ENV=production
PORT=2000
```

Save and exit (Ctrl+X, Y, Enter).

### 5. Set Permissions
```bash
chmod 600 /home/ubuntu/rezio-saas/.env
```

## 🔐 Security Group Configuration

Ensure your EC2 security group has these inbound rules:

| Type | Port | Source | Description |
|------|------|--------|-------------|
| SSH | 22 | Your IP | SSH access |
| Custom TCP | 2000 | 0.0.0.0/0 | Application port |
| Custom TCP | 8080 | Your IP | Jenkins (optional) |
| HTTP | 80 | 0.0.0.0/0 | HTTP (optional) |
| HTTPS | 443 | 0.0.0.0/0 | HTTPS (optional) |

## 🚀 Running Your First Build

1. Go to Jenkins dashboard
2. Click on your pipeline job: `rezio-saas-deploy`
3. Click `Build Now`
4. Watch the build progress in `Console Output`

The pipeline will:
1. ✓ Clean workspace
2. ✓ Checkout code from Git
3. ✓ Install all dependencies from scratch
4. ✓ Generate Prisma client
5. ✓ Run linting
6. ✓ Build Docker image
7. ✓ Run database migrations
8. ✓ Deploy container on port 2000
9. ✓ Perform health checks
10. ✓ Clean up old images

## 🔍 Verification

After successful build, verify deployment:

```bash
# Check if container is running
docker ps -f name=rezio-saas-container

# Check application logs
docker logs rezio-saas-container

# Test the application
curl http://localhost:2000

# Check from your browser
http://your-ec2-ip:2000
```

## 🔄 Continuous Deployment

### Option 1: GitHub Webhooks (Recommended)
1. Go to your GitHub repository → Settings → Webhooks
2. Add webhook:
   - Payload URL: `http://your-ec2-ip:8080/github-webhook/`
   - Content type: `application/json`
   - Events: `Just the push event`
3. Save

Now every push to your repository will trigger an automatic build!

### Option 2: Polling
Jenkins will check for changes every 5 minutes (if configured).

## 🛠️ Useful Commands

### Docker Management
```bash
# View running containers
docker ps

# View all containers
docker ps -a

# View logs
docker logs rezio-saas-container

# Follow logs in real-time
docker logs -f rezio-saas-container

# Stop container
docker stop rezio-saas-container

# Remove container
docker rm rezio-saas-container

# View images
docker images

# Remove unused images
docker image prune -a
```

### Application Management
```bash
# Restart application
docker restart rezio-saas-container

# Execute command in container
docker exec -it rezio-saas-container sh

# Check Prisma migrations
docker exec rezio-saas-container npx prisma migrate status
```

### Jenkins Management
```bash
# Check Jenkins status
sudo systemctl status jenkins

# Restart Jenkins
sudo systemctl restart jenkins

# View Jenkins logs
sudo journalctl -u jenkins -f
```

## 🐛 Troubleshooting

### Build Fails - Docker Permission Denied
```bash
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

### Port 2000 Already in Use
```bash
# Find what's using the port
sudo lsof -i :2000

# Kill the process
sudo kill -9 <PID>
```

### Container Won't Start
```bash
# Check logs
docker logs rezio-saas-container

# Check environment file
cat /home/ubuntu/rezio-saas/.env

# Verify Docker image
docker images | grep rezio-saas
```

### Database Connection Issues
- Ensure `DATABASE_URL` in `.env` is correct
- Verify PostgreSQL is accessible from EC2
- Check security groups if using RDS/external DB

### Prisma Client Generation Fails
```bash
# Manually regenerate
cd /path/to/project
npx prisma generate
```

## 📊 Monitoring

### Set Up Health Checks
```bash
# Create a simple monitoring script
nano /home/ubuntu/health-check.sh
```

Add:
```bash
#!/bin/bash
if curl -f http://localhost:2000/ > /dev/null 2>&1; then
    echo "$(date): Application is healthy"
else
    echo "$(date): Application is DOWN - Restarting container"
    docker restart rezio-saas-container
fi
```

Make executable and add to crontab:
```bash
chmod +x /home/ubuntu/health-check.sh

# Run every 5 minutes
(crontab -l 2>/dev/null; echo "*/5 * * * * /home/ubuntu/health-check.sh >> /home/ubuntu/health.log 2>&1") | crontab -
```

## 🔒 Production Best Practices

1. **Use HTTPS**: Set up SSL with Let's Encrypt + Nginx reverse proxy
2. **Environment Secrets**: Use Jenkins credentials instead of plain .env file
3. **Database Backups**: Regular automated backups of PostgreSQL
4. **Monitoring**: Set up CloudWatch or Prometheus for metrics
5. **Log Management**: Configure log rotation and centralized logging
6. **Scaling**: Consider using Docker Compose or Kubernetes for scaling
7. **Security**: Regular security updates, fail2ban, firewall rules

## 📞 Support

For issues specific to:
- **Next.js**: Check Next.js documentation
- **Prisma**: Check Prisma documentation
- **Docker**: Check Docker documentation
- **Jenkins**: Check Jenkins documentation

---

**Created for**: Kunal Rohilla  
**Project**: Rezio SaaS  
**Date**: 2025-10-24
