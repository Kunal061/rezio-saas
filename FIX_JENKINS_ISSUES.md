# 🔧 Fixing Jenkins Deployment Issues

## Issues Found in Your Build Log

1. ❌ **Docker not found** - Jenkins can't find Docker
2. ❌ **Environment file missing** - `/home/ubuntu/rezio-saas/.env` doesn't exist

---

## 🐳 Fix 1: Install Docker on Jenkins Server

SSH into your EC2 instance where Jenkins is running:

```bash
ssh -i your-key.pem ubuntu@your-ec2-ip
```

### Install Docker:

```bash
# Update package list
sudo apt update

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Verify Docker installation
docker --version
```

### Add Jenkins User to Docker Group (CRITICAL):

```bash
# Add jenkins user to docker group
sudo usermod -aG docker jenkins

# Add ubuntu user too (for your manual access)
sudo usermod -aG docker ubuntu

# Restart Docker service
sudo systemctl restart docker

# IMPORTANT: Restart Jenkins to apply group changes
sudo systemctl restart jenkins
```

### Verify Jenkins Can Access Docker:

```bash
# Switch to jenkins user
sudo su - jenkins

# Test docker command
docker ps

# If it works, you'll see a list (might be empty)
# Exit back to ubuntu user
exit
```

---

## 📝 Fix 2: Create Environment File on EC2

Your `.env` file needs to be at `/home/ubuntu/rezio-saas/.env` on your EC2 server.

### Create the Directory and File:

```bash
# Create directory
mkdir -p /home/ubuntu/rezio-saas

# Create and edit .env file
nano /home/ubuntu/rezio-saas/.env
```

### Paste Your Credentials:

**IMPORTANT:** I noticed your Clerk key has a `$` at the end which might be a typo. Copy this exactly:

```bash
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
```

**Changes I made:**
1. Removed `?channel_binding=require` from DATABASE_URL (can cause connection issues)
2. Removed `$` from end of Clerk publishable key (looks like a typo)

### Save and Secure:

```bash
# Save the file:
# Press: Ctrl + X
# Press: Y
# Press: Enter

# Secure the file permissions
chmod 600 /home/ubuntu/rezio-saas/.env

# Verify it was created
ls -la /home/ubuntu/rezio-saas/.env

# Should show: -rw------- 1 ubuntu ubuntu ... .env
```

---

## ✅ Verification Steps

### 1. Verify Docker Installation:

```bash
# As ubuntu user
docker --version
docker ps

# As jenkins user
sudo su - jenkins
docker --version
docker ps
exit
```

### 2. Verify Environment File:

```bash
# Check file exists
test -f /home/ubuntu/rezio-saas/.env && echo "✓ File exists" || echo "✗ File missing"

# Check file has content (should show your env vars)
cat /home/ubuntu/rezio-saas/.env

# Check permissions (should be -rw-------)
ls -l /home/ubuntu/rezio-saas/.env
```

### 3. Test Database Connection:

```bash
# Install postgresql-client (optional, for testing)
sudo apt install -y postgresql-client

# Test connection (replace with your DATABASE_URL values)
psql "postgresql://neondb_owner:npg_fZKhATH2F9vi@ep-ancient-paper-ah4ny73b-pooler.c-3.us-east-1.aws.neon.tech/neondb?sslmode=require"

# Type \q to quit if connection works
```

---

## 🚀 Run Jenkins Build Again

After fixing both issues:

1. Go to Jenkins: `http://your-ec2-ip:8080`
2. Click on your pipeline job: `rezio-saas-deploy`
3. Click **"Build Now"**

The build should now:
- ✅ Find Docker
- ✅ Find environment file
- ✅ Install dependencies
- ✅ Build Docker image
- ✅ Deploy on port 2000

---

## 🔍 Expected Output

After successful build, you should see:

```
✓ Pipeline completed successfully!
Application deployed and running on http://localhost:2000

═══════════════════════════════════════════════════
Deployment Summary:
───────────────────────────────────────────────────
Build Number: 6
Container Name: rezio-saas-container
Image: rezio-saas:6
Port: 2000
Status: RUNNING
═══════════════════════════════════════════════════
```

---

## 🆘 Troubleshooting

### Docker Still Not Found After Install:

```bash
# Make sure jenkins was restarted
sudo systemctl restart jenkins

# Wait 2-3 minutes for Jenkins to fully restart
# Then try the build again
```

### Environment File Not Found:

```bash
# Double-check the path
ls -la /home/ubuntu/rezio-saas/.env

# Ensure it's exactly at this path (no typos)
# Jenkins expects: /home/ubuntu/rezio-saas/.env
```

### Database Connection Error:

```bash
# Your DATABASE_URL should have sslmode=require
# Remove channel_binding parameter if it causes issues
DATABASE_URL="postgresql://neondb_owner:npg_fZKhATH2F9vi@ep-ancient-paper-ah4ny73b-pooler.c-3.us-east-1.aws.neon.tech/neondb?sslmode=require"
```

### Clerk Key Issues:

```bash
# Make sure there's NO $ at the end of your Clerk key
# Correct:
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY="pk_test_ZGVzdGluZWQtYnVubnktMzQuY2xlcmsuYWNjb3VudHMuZGV2"

# Wrong:
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY="pk_test_ZGVzdGluZWQtYnVubnktMzQuY2xlcmsuYWNjb3VudHMuZGV2$"
```

### Port 2000 Already in Use:

```bash
# Check what's using port 2000
sudo lsof -i :2000

# If something is there, stop it
docker stop rezio-saas-container
docker rm rezio-saas-container
```

---

## 📋 Complete Fix Checklist

- [ ] SSH into EC2 instance
- [ ] Install Docker (`curl -fsSL https://get.docker.com -o get-docker.sh && sudo sh get-docker.sh`)
- [ ] Add jenkins to docker group (`sudo usermod -aG docker jenkins`)
- [ ] Restart Jenkins (`sudo systemctl restart jenkins`)
- [ ] Create directory (`mkdir -p /home/ubuntu/rezio-saas`)
- [ ] Create .env file (`nano /home/ubuntu/rezio-saas/.env`)
- [ ] Paste correct environment variables (without `$` in Clerk key)
- [ ] Save file (Ctrl+X, Y, Enter)
- [ ] Set permissions (`chmod 600 /home/ubuntu/rezio-saas/.env`)
- [ ] Verify file exists (`ls -la /home/ubuntu/rezio-saas/.env`)
- [ ] Wait 2-3 minutes for Jenkins to fully restart
- [ ] Run Jenkins build again

---

## 🎯 Quick Command Summary

Run these commands in order on your EC2 instance:

```bash
# 1. Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# 2. Add users to docker group
sudo usermod -aG docker jenkins
sudo usermod -aG docker ubuntu

# 3. Restart services
sudo systemctl restart docker
sudo systemctl restart jenkins

# 4. Create environment file directory
mkdir -p /home/ubuntu/rezio-saas

# 5. Create .env file
nano /home/ubuntu/rezio-saas/.env
# (Paste your environment variables, save with Ctrl+X, Y, Enter)

# 6. Secure the file
chmod 600 /home/ubuntu/rezio-saas/.env

# 7. Verify everything
docker --version
ls -la /home/ubuntu/rezio-saas/.env

# 8. Wait 2-3 minutes, then trigger Jenkins build
```

---

## ✅ After Successful Deployment

Access your application:
```
http://your-ec2-ip:2000
```

Check logs:
```bash
docker logs -f rezio-saas-container
```

Check status:
```bash
docker ps -f name=rezio-saas-container
```

---

**You're almost there!** Just need to install Docker and create the environment file properly. 🚀
