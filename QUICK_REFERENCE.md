# Rezio SaaS - Quick Reference

## 🚀 Quick Start Commands

### Local Development
```bash
npm install
npm run dev
```

### Docker Deployment
```bash
# Build and run with Docker
docker build -t rezio-saas .
docker run -d -p 2000:2000 --env-file .env --name rezio-saas-container rezio-saas

# Or use Docker Compose
docker-compose up -d
```

### Manual Deployment Script
```bash
./scripts/deploy.sh
```

### Management Menu
```bash
./scripts/manage.sh
```

## 📋 Jenkins Pipeline Stages

1. **Cleanup Workspace** - Fresh start for each build
2. **Checkout Code** - Pull latest code from Git
3. **Verify Environment** - Check all dependencies
4. **Install Dependencies** - Fresh npm install
5. **Prisma Setup** - Generate Prisma client
6. **Lint Code** - Run ESLint
7. **Build Docker Image** - Create production image
8. **Database Migration** - Apply schema changes
9. **Deploy Application** - Run container on port 2000
10. **Health Check** - Verify deployment
11. **Cleanup Old Images** - Remove old builds

## 🔧 Useful Commands

### Docker
```bash
# View logs
docker logs rezio-saas-container

# Restart application
docker restart rezio-saas-container

# Stop and remove
docker stop rezio-saas-container
docker rm rezio-saas-container

# Clean up
docker system prune -a
```

### Prisma
```bash
# Inside container
docker exec rezio-saas-container npx prisma migrate deploy
docker exec rezio-saas-container npx prisma migrate status
docker exec rezio-saas-container npx prisma generate
```

### Application
```bash
# Test endpoint
curl http://localhost:2000

# Check health
curl http://localhost:2000/api/videos
```

## 🔐 Environment Variables Required

```env
DATABASE_URL=postgresql://...
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_live_...
CLERK_SECRET_KEY=sk_live_...
NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME=...
NEXT_PUBLIC_CLOUDINARY_UPLOAD_PRESET=...
CLOUDINARY_API_KEY=...
CLOUDINARY_API_SECRET=...
NODE_ENV=production
PORT=2000
```

## 📂 Important Files

- `Dockerfile` - Multi-stage Docker build
- `Jenkinsfile` - Complete CI/CD pipeline
- `docker-compose.yml` - Docker Compose configuration
- `.dockerignore` - Files excluded from Docker build
- `.env.example` - Environment variables template
- `DEPLOYMENT.md` - Full deployment guide
- `scripts/deploy.sh` - Manual deployment script
- `scripts/rollback.sh` - Rollback to previous version
- `scripts/manage.sh` - Interactive management menu

## 🎯 Port Configuration

- **Application**: 2000
- **Jenkins**: 8080 (default)
- **PostgreSQL**: 5432 (if using local DB)

## 🔄 Rollback Process

```bash
# List available versions
docker images rezio-saas

# Rollback using script
./scripts/rollback.sh

# Or manually
docker stop rezio-saas-container
docker rm rezio-saas-container
docker run -d -p 2000:2000 --env-file .env --name rezio-saas-container rezio-saas:TAG
```

## ⚡ Troubleshooting

### Build fails
- Check `.env` file exists
- Verify DATABASE_URL is correct
- Ensure all required env vars are set

### Container won't start
- Check logs: `docker logs rezio-saas-container`
- Verify port 2000 is available
- Check environment variables

### Database connection issues
- Verify DATABASE_URL
- Check network connectivity to database
- Ensure database exists and migrations are applied

### Jenkins permission issues
```bash
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

## 📞 Support

See `DEPLOYMENT.md` for detailed deployment instructions.
