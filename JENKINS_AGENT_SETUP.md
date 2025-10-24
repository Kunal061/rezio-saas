# Jenkins Agent Node Setup for Rezio SaaS

## Architecture Overview

You're using:
- **Jenkins Master**: Central Jenkins server (separate machine)
- **Jenkins Agent/Node**: Your EC2 instance (where the build executes)

The agent node needs Docker and the environment file, but NOT Jenkins itself.

---

## 🔧 Setup Commands for Jenkins Agent (EC2)

Run these commands on your **EC2 agent node**:

### Step 1: Install Docker

```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
rm get-docker.sh

# Verify installation
docker --version
```

### Step 2: Configure Docker Permissions

The Jenkins agent runs as a specific user. You need to find out which user and add them to the docker group.

```bash
# Option A: If agent runs as 'ubuntu' user
sudo usermod -aG docker ubuntu

# Option B: If agent runs as specific jenkins user
# (check your agent configuration in Jenkins master)
sudo usermod -aG docker <agent-user>

# Also add current user for manual testing
sudo usermod -aG docker $USER
```

### Step 3: Restart Docker

```bash
sudo systemctl restart docker

# Verify docker group membership
groups ubuntu  # or your agent user
```

### Step 4: Create Environment File

```bash
# Create directory
mkdir -p /home/ubuntu/rezio-saas

# Create .env file
cat > /home/ubuntu/rezio-saas/.env << 'EOF'
# Database
DATABASE_URL="postgresql://neondb_owner:npg_fZKhATH2F9vi@ep-ancient-paper-ah4ny73b-pooler.c-3.us-east-1.aws.neon.tech/neondb?sslmode=require"

# Clerk
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY="pk_test_ZGVzdGluZWQtYnVubnktMzQuY2xlcmsuYWNjb3VudHMuZGV2"
CLERK_SECRET_KEY="sk_test_6eLBVts1sPU8Bcv3jvwgL2pr1Gdr3nPXitnWU4wTJv"

# Cloudinary
NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME="dws3rdjj6"
NEXT_PUBLIC_CLOUDINARY_UPLOAD_PRESET="rezio_uploads"
CLOUDINARY_API_KEY="798874181292374"
CLOUDINARY_API_SECRET="Smkt19IRACPGLlDJx6nMYCCJzWk"

# Application
NODE_ENV=production
PORT=2000
EOF

# Secure the file
chmod 600 /home/ubuntu/rezio-saas/.env
```

### Step 5: Verify Setup

```bash
# Check Docker
docker ps

# Check environment file
ls -la /home/ubuntu/rezio-saas/.env
cat /home/ubuntu/rezio-saas/.env

# Test Docker works for your user
docker run hello-world
```

---

## 🔍 Find Your Jenkins Agent User

Run this on your EC2 to find which user the agent runs as:

```bash
# Check running Java processes (Jenkins agent)
ps aux | grep java

# Look for the USER column in the output
# Common users: ubuntu, jenkins, ec2-user, or custom user
```

The output will show something like:
```
ubuntu    12345  ... java -jar agent.jar ...
```

The first column is the username. Add that user to the docker group:
```bash
sudo usermod -aG docker <username>
```

---

## 🎯 Jenkins Master Configuration

On your **Jenkins Master UI**, ensure your agent node is configured correctly:

### 1. Go to Jenkins Master Dashboard
- Navigate to: `Manage Jenkins` → `Nodes` → `Your Agent Node`

### 2. Check Agent Configuration
- **Remote root directory**: Should be `/home/ubuntu` or similar
- **Labels**: Note the labels (you might need to add one for this project)
- **Usage**: "Use this node as much as possible"

### 3. Update Your Jenkinsfile (If Needed)

If your agent has a specific label, update the Jenkinsfile:

```groovy
pipeline {
    agent {
        label 'your-agent-label'  // Add your agent's label here
    }
    // ... rest of pipeline
}
```

Or if you want to run on any available agent:
```groovy
pipeline {
    agent any
    // ... rest of pipeline
}
```

---

## ✅ Complete Setup Script for Agent Node

Run this **ONE command** on your EC2 agent:

```bash
#!/bin/bash
# Complete setup for Jenkins agent node

# Install Docker
curl -fsSL https://get.docker.com | sudo sh

# Add users to docker group (adjust 'ubuntu' if your agent uses different user)
sudo usermod -aG docker ubuntu
sudo usermod -aG docker $USER

# Restart Docker
sudo systemctl restart docker

# Create environment directory
mkdir -p /home/ubuntu/rezio-saas

# Create .env file
cat > /home/ubuntu/rezio-saas/.env << 'EOF'
# Database
DATABASE_URL="postgresql://neondb_owner:npg_fZKhATH2F9vi@ep-ancient-paper-ah4ny73b-pooler.c-3.us-east-1.aws.neon.tech/neondb?sslmode=require"

# Clerk
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY="pk_test_ZGVzdGluZWQtYnVubnktMzQuY2xlcmsuYWNjb3VudHMuZGV2"
CLERK_SECRET_KEY="sk_test_6eLBVts1sPU8Bcv3jvwgL2pr1Gdr3nPXitnWU4wTJv"

# Cloudinary
NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME="dws3rdjj6"
NEXT_PUBLIC_CLOUDINARY_UPLOAD_PRESET="rezio_uploads"
CLOUDINARY_API_KEY="798874181292374"
CLOUDINARY_API_SECRET="Smkt19IRACPGLlDJx6nMYCCJzWk"

# Application
NODE_ENV=production
PORT=2000
EOF

# Secure the file
chmod 600 /home/ubuntu/rezio-saas/.env

# Verify
echo "✓ Docker version: $(docker --version)"
echo "✓ Environment file created at: /home/ubuntu/rezio-saas/.env"
echo "✓ Setup complete!"
echo ""
echo "⚠ IMPORTANT: You may need to reconnect the Jenkins agent for docker group changes to take effect"
echo "Go to Jenkins Master → Nodes → Your Agent → Disconnect → Launch Agent"
```

---

## 🔄 After Setup: Reconnect Jenkins Agent

**Important**: Docker group changes require the agent process to restart.

### On Jenkins Master UI:

1. Go to: `Manage Jenkins` → `Nodes`
2. Click on your agent node
3. Click **"Disconnect"**
4. Wait a few seconds
5. Click **"Launch agent"** (or it may auto-reconnect)

### Or via Command Line on EC2:

If you're using SSH-based agent:
```bash
# Just restart the agent process
# The exact command depends on how your agent is launched
# Usually Jenkins master will auto-reconnect
```

---

## 🧪 Test the Setup

### On Jenkins Master:

1. Go to your pipeline job: `rezio-saas-deploy`
2. Click **"Build Now"**
3. Watch the console output

### Expected Success Output:

```
[Pipeline] Start of Pipeline
[Pipeline] node
Running on <your-agent-name> in /home/ubuntu/workspace/rezio-saas-deploy
...
[Pipeline] { (Verify Environment)
Docker version: Docker version 24.x.x, build xxxxx
✓ Environment file found at /home/ubuntu/rezio-saas/.env
...
[Pipeline] { (Build Docker Image)
Building Docker image...
✓ Docker image built successfully
...
✓ Pipeline completed successfully!
Application deployed and running on http://localhost:2000
```

---

## 🆘 Troubleshooting

### Docker Permission Denied (for Agent User)

```bash
# Find the agent user
ps aux | grep agent.jar

# Add that user to docker group
sudo usermod -aG docker <agent-user>

# Reconnect agent from Jenkins master UI
```

### Environment File Not Found

```bash
# Verify path
ls -la /home/ubuntu/rezio-saas/.env

# Check permissions
stat /home/ubuntu/rezio-saas/.env

# Ensure path in Jenkinsfile matches
# ENV_FILE = '/home/ubuntu/rezio-saas/.env'
```

### Agent Can't Connect After Changes

```bash
# Check agent process is running
ps aux | grep agent.jar

# Check network connectivity to master
ping <jenkins-master-ip>
telnet <jenkins-master-ip> <agent-port>

# Check agent logs on EC2
# Location depends on how agent was started
```

### Port 2000 Already in Use

```bash
# Find what's using port 2000
sudo lsof -i :2000

# Stop old container
docker stop rezio-saas-container
docker rm rezio-saas-container
```

---

## 📋 Agent Setup Checklist

- [ ] Docker installed on agent EC2
- [ ] Agent user added to docker group
- [ ] Docker service restarted
- [ ] Environment file created at `/home/ubuntu/rezio-saas/.env`
- [ ] File permissions set to 600
- [ ] Jenkins agent disconnected and reconnected
- [ ] Test build triggered from master
- [ ] Application accessible on port 2000

---

## 🎯 Key Differences: Master-Agent vs Standalone

| Aspect | Standalone Jenkins | Master-Agent |
|--------|-------------------|--------------|
| Jenkins Installation | On same EC2 | Master separate, Agent on EC2 |
| User to add to docker | `jenkins` | Agent user (often `ubuntu`) |
| Restart Jenkins | `sudo systemctl restart jenkins` | Reconnect agent from master UI |
| Configuration | Local | Via master UI |

---

## 📞 Quick Commands Reference

```bash
# Install Docker
curl -fsSL https://get.docker.com | sudo sh

# Add agent user to docker (replace 'ubuntu' with your agent user)
sudo usermod -aG docker ubuntu

# Restart Docker
sudo systemctl restart docker

# Create env file
mkdir -p /home/ubuntu/rezio-saas && \
nano /home/ubuntu/rezio-saas/.env  # paste your credentials

# Set permissions
chmod 600 /home/ubuntu/rezio-saas/.env

# Verify
docker --version
ls -la /home/ubuntu/rezio-saas/.env
docker ps
```

---

**After running these commands, reconnect your agent in Jenkins Master UI and trigger a new build!** 🚀
