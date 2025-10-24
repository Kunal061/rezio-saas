# 🚀 Complete Setup Guide - Starting from Scratch

## Overview
Since you cloned this project and don't have access to the original database or API keys, you'll need to create your own accounts and configure everything. This guide walks you through every step.

---

## 📋 Step 1: Create Required Accounts (All FREE)

### 1.1 Create Neon Database Account (FREE)
**What it is:** PostgreSQL database hosting  
**Why you need it:** Store video metadata

1. Go to: https://neon.tech
2. Click "Sign Up" (use your GitHub account for easy signup)
3. Create a new project:
   - Project Name: `rezio-saas`
   - Region: Choose closest to you (e.g., `US East (Ohio)`)
   - Postgres Version: 16 (latest)
4. Click "Create Project"
5. **IMPORTANT:** Copy the connection string that appears
   - It looks like: `postgresql://username:password@ep-xxx.us-east-2.aws.neon.tech/dbname`
   - Save this - you'll need it later!

### 1.2 Create Clerk Account (FREE)
**What it is:** Authentication service  
**Why you need it:** User login/signup

1. Go to: https://clerk.com
2. Click "Start Building for Free"
3. Sign up with your email or GitHub
4. Create a new application:
   - Application Name: `Rezio SaaS`
   - Select: Email, Google, GitHub (or any you prefer)
5. Click "Create Application"
6. Go to "API Keys" section:
   - Copy `Publishable Key` (starts with `pk_test_`)
   - Copy `Secret Key` (starts with `sk_test_`)
   - **Save both keys!**

### 1.3 Create Cloudinary Account (FREE)
**What it is:** Media storage and optimization  
**Why you need it:** Store and compress videos

1. Go to: https://cloudinary.com
2. Click "Sign Up for Free"
3. Fill in your details (or use GitHub)
4. After signup, go to Dashboard
5. Note down from the dashboard:
   - **Cloud Name** (e.g., `dxxx123`)
   - **API Key** (e.g., `123456789012345`)
   - **API Secret** (click "reveal" to see it)
6. **Create Upload Preset:**
   - Go to Settings → Upload
   - Scroll to "Upload presets"
   - Click "Add upload preset"
   - Preset name: `rezio_uploads`
   - Signing Mode: **Unsigned** (IMPORTANT!)
   - Folder: `video-uploads`
   - Resource type: Allow **Video**
   - Click "Save"

---

## 📝 Step 2: Create Your Environment File

Now let's create your `.env` file with the credentials you just obtained.

### On Your Local Machine (for development):

Create a file named `.env` in your project root:

```bash
# Database (from Neon.tech - Step 1.1)
DATABASE_URL="postgresql://username:password@ep-xxx.us-east-2.aws.neon.tech/dbname?schema=public"

# Clerk Authentication (from Clerk.com - Step 1.2)
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY="pk_test_xxxxxxxxxxxxxxxx"
CLERK_SECRET_KEY="sk_test_xxxxxxxxxxxxxxxx"

# Cloudinary (from Cloudinary.com - Step 1.3)
NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME="your_cloud_name_here"
NEXT_PUBLIC_CLOUDINARY_UPLOAD_PRESET="rezio_uploads"
CLOUDINARY_API_KEY="123456789012345"
CLOUDINARY_API_SECRET="your_secret_here"

# Application Settings
NODE_ENV=development
PORT=3000
```

**Replace:**
- Line 2: Your actual Neon database connection string
- Line 5: Your Clerk publishable key
- Line 6: Your Clerk secret key
- Line 9: Your Cloudinary cloud name
- Line 11: Your Cloudinary API key
- Line 12: Your Cloudinary API secret

### Example with Real (but fake) Values:

```bash
# Database
DATABASE_URL="postgresql://kunalrohilla:bX9kP2mQ4@ep-cool-breeze-12345678.us-east-2.aws.neon.tech:5432/rezio_db?schema=public"

# Clerk
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY="pk_test_Y2xlcmsubmV0JDEyMzQ1Njc4OTA"
CLERK_SECRET_KEY="sk_test_AbCdEfGhIjKlMnOpQrStUvWxYz1234567890"

# Cloudinary
NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME="dkunalrohilla"
NEXT_PUBLIC_CLOUDINARY_UPLOAD_PRESET="rezio_uploads"
CLOUDINARY_API_KEY="987654321098765"
CLOUDINARY_API_SECRET="ZyXwVuTsRqPoNmLkJiHgFeDcBa"

# Application
NODE_ENV=development
PORT=3000
```

---

## 🔧 Step 3: Initialize Your Database

Now set up the database schema:

```bash
# 1. Install dependencies
npm install

# 2. Generate Prisma client
npx prisma generate

# 3. Push schema to your Neon database
npx prisma db push

# This creates the Video table in your database
```

**Expected Output:**
```
✔ Generated Prisma Client
Your database is now in sync with your Prisma schema.
```

---

## 🧪 Step 4: Test Locally

```bash
# Start development server
npm run dev
```

Open browser: http://localhost:3000

**Test these:**
1. ✅ Sign up / Sign in (Clerk)
2. ✅ Upload a video (Cloudinary)
3. ✅ View uploaded videos (Database)
4. ✅ Download video

If everything works, you're ready for deployment! 🎉

---

## ☁️ Step 5: Deploy to EC2

### 5.1 Create `.env` for Production on EC2

SSH into your EC2 instance:
```bash
ssh -i your-key.pem ubuntu@your-ec2-ip
```

Create production environment file:
```bash
# Create directory
mkdir -p /home/ubuntu/rezio-saas

# Create .env file
nano /home/ubuntu/rezio-saas/.env
```

**Paste this (with YOUR values):**
```bash
# Database (SAME as your local .env)
DATABASE_URL="postgresql://username:password@ep-xxx.us-east-2.aws.neon.tech/dbname?schema=public"

# Clerk - IMPORTANT: Use PRODUCTION keys!
# Go to Clerk Dashboard → "Go Live" → Get production keys
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY="pk_live_xxxxxxxxxxxxxxxx"
CLERK_SECRET_KEY="sk_live_xxxxxxxxxxxxxxxx"

# Cloudinary (SAME as local)
NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME="your_cloud_name"
NEXT_PUBLIC_CLOUDINARY_UPLOAD_PRESET="rezio_uploads"
CLOUDINARY_API_KEY="your_api_key"
CLOUDINARY_API_SECRET="your_api_secret"

# Application - IMPORTANT: Production mode!
NODE_ENV=production
PORT=2000
```

**Save:** Ctrl+X → Y → Enter

**Secure it:**
```bash
chmod 600 /home/ubuntu/rezio-saas/.env
```

### 5.2 Configure Clerk for Production

**IMPORTANT:** Update allowed URLs in Clerk:

1. Go to Clerk Dashboard
2. Go to your application → "Domains"
3. Add your EC2 URL:
   - **Frontend API**: `http://your-ec2-ip:2000`
   - **Redirect URLs**: `http://your-ec2-ip:2000/*`
4. Click "Save"

---

## 🎯 Step 6: Deploy with Jenkins

Now your Jenkins pipeline will work because:
- ✅ Environment file exists at `/home/ubuntu/rezio-saas/.env`
- ✅ All API keys are your own
- ✅ Database is accessible
- ✅ Clerk is configured

**Run your Jenkins build:**
1. Go to Jenkins: `http://your-ec2-ip:8080`
2. Click your pipeline job
3. Click "Build Now"

Jenkins will:
1. Install dependencies
2. Build Docker image
3. Run database migrations
4. Deploy on port 2000

**Access your app:**
```
http://your-ec2-ip:2000
```

---

## 🔍 Verification Checklist

After deployment, verify:

```bash
# Check container is running
docker ps -f name=rezio-saas-container

# Check logs
docker logs rezio-saas-container

# Test endpoint
curl http://localhost:2000

# View from browser
# http://your-ec2-ip:2000
```

---

## 🆘 Troubleshooting

### Database Connection Error
```
Error: Can't reach database server
```
**Fix:**
- Verify DATABASE_URL is correct
- Check Neon database is active (go to Neon dashboard)
- Ensure connection string has `?schema=public` at the end

### Clerk Authentication Error
```
Clerk: Missing publishable key
```
**Fix:**
- Verify NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY is set
- Check key starts with `pk_test_` or `pk_live_`
- Ensure you added EC2 URL to Clerk domains

### Cloudinary Upload Error
```
Upload failed: Invalid preset
```
**Fix:**
- Verify upload preset is created in Cloudinary
- Ensure preset is **unsigned**
- Check preset allows video uploads

### Port Already in Use
```
Error: Port 2000 is already allocated
```
**Fix:**
```bash
# Stop existing container
docker stop rezio-saas-container
docker rm rezio-saas-container

# Or find what's using the port
sudo lsof -i :2000
sudo kill -9 <PID>
```

---

## 📞 Quick Reference

### Your Service Dashboards:
- **Neon Database**: https://console.neon.tech
- **Clerk Auth**: https://dashboard.clerk.com
- **Cloudinary**: https://console.cloudinary.com

### Important Files:
- Local `.env`: `/Users/kunalrohilla/Documents/projects/rezio-saas/.env`
- Server `.env`: `/home/ubuntu/rezio-saas/.env`
- Deployment guide: `DEPLOYMENT.md`

### Useful Commands:
```bash
# View logs
docker logs -f rezio-saas-container

# Restart app
docker restart rezio-saas-container

# Run migrations
docker exec rezio-saas-container npx prisma migrate deploy

# Management menu
./scripts/manage.sh
```

---

## 🎉 You're Done!

You now have:
- ✅ Your own database (Neon)
- ✅ Your own authentication (Clerk)
- ✅ Your own media storage (Cloudinary)
- ✅ Working local development
- ✅ Production deployment on EC2

**Everything is under YOUR control!**

---

**Created for:** Kunal Rohilla  
**Email:** kunalr.tech@gmail.com  
**Date:** 2025-10-24
