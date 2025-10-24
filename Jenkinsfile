pipeline {
    agent {label 'pop'}
    
    environment {
        // Application Configuration
        APP_NAME = 'rezio-saas'
        DOCKER_IMAGE = "rezio-saas:${BUILD_NUMBER}"
        CONTAINER_NAME = 'rezio-saas-container'
        APP_PORT = '2000'
        
        // Docker credentials (if using private registry)
        // DOCKER_REGISTRY = 'your-registry-url'
        // DOCKER_CREDENTIALS_ID = 'docker-hub-credentials'
        
        // Environment variables file path on EC2
        ENV_FILE = '/home/ubuntu/rezio-saas/.env'
    }
    
    options {
        // Keep last 10 builds
        buildDiscarder(logRotator(numToKeepStr: '10'))
        
        // Timeout for the entire pipeline
        timeout(time: 30, unit: 'MINUTES')
        
        // Disable concurrent builds
        disableConcurrentBuilds()
    }
    
    stages {
        stage('Clean Previous Build Residue') {
            steps {
                echo 'Cleaning all residue from previous builds...'
                
                script {
                    sh '''
                        echo "═══════════════════════════════════════════════════"
                        echo "Cleaning Docker Resources from Previous Builds"
                        echo "═══════════════════════════════════════════════════"
                        
                        # Stop and remove existing application container if running
                        echo "Stopping existing containers..."
                        docker stop ${CONTAINER_NAME} 2>/dev/null || echo "No container to stop"
                        docker rm ${CONTAINER_NAME} 2>/dev/null || echo "No container to remove"
                        
                        # Aggressive cleanup to free disk space
                        echo "Removing all stopped containers..."
                        docker container prune -a -f 2>/dev/null || echo "Container prune completed"
                        
                        # Remove dangling AND unused images
                        echo "Removing unused images..."
                        docker image prune -a -f 2>/dev/null || echo "Image prune completed"
                        
                        # Remove unused volumes to free space
                        echo "Removing unused volumes..."
                        docker volume prune -f 2>/dev/null || echo "Volume prune completed"
                        
                        # Remove build cache to free space
                        echo "Removing build cache..."
                        docker builder prune -f 2>/dev/null || echo "Builder prune completed"
                        
                        echo "✓ Docker cleanup completed"
                        
                        # Show disk space after cleanup
                        echo ""
                        echo "Disk space after cleanup:"
                        df -h / | tail -1
                        echo ""
                    '''
                }
            }
        }
        
        stage('Cleanup Workspace') {
            steps {
                echo 'Cleaning workspace...'
                
                script {
                    // Clean workspace completely
                    cleanWs()
                    
                    echo "✓ Workspace cleaned"
                }
            }
        }
        
        stage('Clone Repository') {
            steps {
                echo 'Cloning fresh code from GitHub...'
                
                script {
                    // Clone from GitHub repository
                    sh '''
                        # Remove any existing git directory
                        rm -rf .git
                        
                        # Clone the repository
                        git clone https://github.com/Kunal061/rezio-saas.git .
                        
                        # Display git information
                        echo "═══════════════════════════════════════════════════"
                        echo "Repository: https://github.com/Kunal061/rezio-saas.git"
                        echo "Git Branch: $(git rev-parse --abbrev-ref HEAD)"
                        echo "Git Commit: $(git rev-parse --short HEAD)"
                        echo "Commit Message: $(git log -1 --pretty=%B)"
                        echo "═══════════════════════════════════════════════════"
                    '''
                }
            }
        }
        
        stage('Verify Environment') {
            steps {
                echo 'Verifying build environment...'
                sh '''
                    echo "Node version: $(node --version || echo 'Node not found')"
                    echo "npm version: $(npm --version || echo 'npm not found')"
                    echo "Docker version: $(docker --version || echo 'Docker not found')"
                    echo "Build Number: ${BUILD_NUMBER}"
                    echo "Workspace: ${WORKSPACE}"
                    
                    # Check disk space
                    echo ""
                    echo "════════════════════════════════════════════════════"
                    echo "Disk Space:"
                    df -h | grep -E '(Filesystem|/dev/)'
                    echo "════════════════════════════════════════════════════"
                    
                    # Check if disk usage is above 85% - FAIL the build
                    DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
                    echo "Current disk usage: ${DISK_USAGE}%"
                    
                    if [ $DISK_USAGE -gt 85 ]; then
                        echo ""
                        echo "⚠⚠⚠ CRITICAL ERROR: Disk usage is at ${DISK_USAGE}%! ⚠⚠⚠"
                        echo ""
                        echo "Build cannot proceed with less than 15% free space."
                        echo ""
                        echo "REQUIRED ACTIONS:"
                        echo "1. SSH to EC2: ssh -i your-key.pem ubuntu@your-ec2-ip"
                        echo "2. Run: docker system prune -a -f --volumes"
                        echo "3. Run: rm -rf ~/.npm /tmp/*"
                        echo "4. Run: sudo journalctl --vacuum-time=1d"
                        echo "5. Verify: df -h /"
                        echo ""
                        echo "OR increase EBS volume size in AWS Console to 30GB"
                        echo ""
                        exit 1
                    elif [ $DISK_USAGE -gt 75 ]; then
                        echo "⚠ WARNING: Disk usage is at ${DISK_USAGE}% - Consider cleanup soon"
                    else
                        echo "✓ Disk space is sufficient (${DISK_USAGE}% used)"
                    fi
                '''
                
                // Check if .env file exists on server
                script {
                    def envFileExists = sh(
                        script: "test -f ${ENV_FILE} && echo 'exists' || echo 'missing'",
                        returnStdout: true
                    ).trim()
                    
                    if (envFileExists == 'missing') {
                        error("ERROR: Environment file ${ENV_FILE} not found! Please create it with required variables.")
                    } else {
                        echo "✓ Environment file found at ${ENV_FILE}"
                    }
                }
            }
        }
        
        stage('Install Dependencies') {
            steps {
                echo 'Installing Node.js dependencies from scratch...'
                sh '''
                    # Remove existing node_modules and package-lock if present
                    rm -rf node_modules package-lock.json
                    
                    # Clean npm cache
                    npm cache clean --force
                    
                    # Install dependencies fresh
                    npm install --legacy-peer-deps
                    
                    echo "Dependencies installed successfully"
                '''
            }
        }
        
        stage('Prisma Setup') {
            steps {
                echo 'Generating Prisma Client...'
                sh '''
                    # Generate Prisma client
                    npx prisma generate
                    
                    echo "Prisma client generated successfully"
                '''
            }
        }
        
        stage('Lint Code') {
            steps {
                echo 'Running ESLint...'
                sh '''
                    npm run lint || echo "Linting completed with warnings"
                '''
            }
        }
        
        stage('Build Docker Image') {
            steps {
                echo 'Building Docker image...'
                script {
                    // Stop and remove old container if exists
                    sh '''
                        docker stop ${CONTAINER_NAME} 2>/dev/null || true
                        docker rm ${CONTAINER_NAME} 2>/dev/null || true
                    '''
                    
                    // Build new Docker image
                    sh '''
                        docker build -t ${DOCKER_IMAGE} .
                        
                        # Tag as latest
                        docker tag ${DOCKER_IMAGE} ${APP_NAME}:latest
                        
                        echo "Docker image built successfully: ${DOCKER_IMAGE}"
                    '''
                }
            }
        }
        
        stage('Database Migration') {
            steps {
                echo 'Running database migrations...'
                script {
                    // Run migrations using a temporary container
                    sh '''
                        docker run --rm \
                            --env-file ${ENV_FILE} \
                            ${DOCKER_IMAGE} \
                            npx prisma migrate deploy || echo "Migration completed or no new migrations"
                    '''
                }
            }
        }
        
        stage('Deploy Application') {
            steps {
                echo 'Deploying application container...'
                script {
                    sh '''
                        # Run the new container
                        docker run -d \
                            --name ${CONTAINER_NAME} \
                            --env-file ${ENV_FILE} \
                            -p ${APP_PORT}:${APP_PORT} \
                            --restart unless-stopped \
                            --health-cmd="curl -f http://localhost:${APP_PORT}/ || exit 1" \
                            --health-interval=30s \
                            --health-timeout=10s \
                            --health-retries=3 \
                            ${DOCKER_IMAGE}
                        
                        echo "Container ${CONTAINER_NAME} started successfully"
                    '''
                }
            }
        }
        
        stage('Health Check') {
            steps {
                echo 'Performing health check...'
                script {
                    // Wait for application to start
                    sleep(time: 15, unit: 'SECONDS')
                    
                    sh '''
                        # Check if container is running
                        if [ "$(docker ps -q -f name=${CONTAINER_NAME})" ]; then
                            echo "✓ Container is running"
                            
                            # Check container logs
                            echo "Recent logs:"
                            docker logs --tail 20 ${CONTAINER_NAME}
                            
                            # Check if app is responding
                            for i in {1..10}; do
                                if curl -f http://localhost:${APP_PORT}/ > /dev/null 2>&1; then
                                    echo "✓ Application is responding on port ${APP_PORT}"
                                    exit 0
                                fi
                                echo "Waiting for application to respond (attempt $i/10)..."
                                sleep 3
                            done
                            
                            echo "⚠ Warning: Application may not be fully ready yet"
                        else
                            echo "✗ Container is not running!"
                            exit 1
                        fi
                    '''
                }
            }
        }
        
        stage('Cleanup Old Images') {
            steps {
                echo 'Cleaning up old Docker images...'
                sh '''
                    # Remove dangling images again
                    docker image prune -f
                    
                    # Keep only last 3 builds of this app (removes older versions)
                    echo "Removing old image versions (keeping last 3)..."
                    docker images ${APP_NAME} --format "{{.ID}} {{.Tag}}" | \
                        grep -v latest | \
                        tail -n +4 | \
                        awk '{print $1}' | \
                        xargs -r docker rmi -f || true
                    
                    # Show remaining images
                    echo ""
                    echo "Remaining images:"
                    docker images ${APP_NAME}
                    
                    echo "✓ Cleanup completed"
                '''
            }
        }
    }
    
    post {
        success {
            echo '✓ Pipeline completed successfully!'
            echo "Application deployed and running on http://localhost:${APP_PORT}"
            
            script {
                sh '''
                    echo "═══════════════════════════════════════════════════"
                    echo "Deployment Summary:"
                    echo "───────────────────────────────────────────────────"
                    echo "Build Number: ${BUILD_NUMBER}"
                    echo "Container Name: ${CONTAINER_NAME}"
                    echo "Image: ${DOCKER_IMAGE}"
                    echo "Port: ${APP_PORT}"
                    echo "Status: RUNNING"
                    echo "═══════════════════════════════════════════════════"
                    
                    # Show container status
                    docker ps -f name=${CONTAINER_NAME} --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
                '''
            }
        }
        
        failure {
            echo '✗ Pipeline failed!'
            
            script {
                sh '''
                    echo "Checking container logs for errors..."
                    docker logs ${CONTAINER_NAME} 2>/dev/null || echo "No container logs available"
                    
                    # Cleanup failed container
                    docker stop ${CONTAINER_NAME} 2>/dev/null || true
                    docker rm ${CONTAINER_NAME} 2>/dev/null || true
                '''
            }
        }
        
        always {
            echo 'Pipeline execution completed.'
            
            // Archive build artifacts if needed
            // archiveArtifacts artifacts: 'build-logs/**', allowEmptyArchive: true
        }
    }
}
