# 🔧 Fix: Jenkins Agent Going Offline

## Problem
Your Jenkins agent goes offline during the build, likely because:
1. The agent user doesn't have Docker permissions
2. Docker commands are failing and causing the agent to disconnect

## 🚨 Quick Fix

### On Your EC2 Agent, Run These Commands:

```bash
# 1. Find out which user is running the Jenkins agent
ps aux | grep agent.jar

# Look for the USER column - it's usually 'ubuntu' or 'jenkins'
# Example output:
# ubuntu    12345  ... java -jar agent.jar ...
#  ^^^^^
#  This is your agent user
```

### 2. Add That User to Docker Group:

```bash
# Replace 'ubuntu' with your actual agent user if different
sudo usermod -aG docker ubuntu

# Also verify docker group exists
getent group docker

# Verify the user was added
groups ubuntu
# Should show: ubuntu ... docker ...
```

### 3. Restart Docker Service:

```bash
sudo systemctl restart docker
```

### 4. Test Docker Access:

```bash
# Switch to the agent user
sudo su - ubuntu

# Test docker command (should work without sudo)
docker ps

# If it works, you'll see a list (might be empty)
# If it fails with "permission denied", the group change didn't work

# Exit back to your user
exit
```

### 5. Reconnect Jenkins Agent:

**On Jenkins Master UI:**
1. Go to: `Manage Jenkins` → `Nodes`
2. Click on your agent: `pop`
3. Click **"Disconnect"**
4. Wait 10 seconds
5. Click **"Launch agent"**

---

## ✅ Verify Agent Can Use Docker

After reconnecting, run a test build or execute this on the agent:

```bash
# As the agent user (usually ubuntu)
docker run hello-world

# Should download and run successfully
```

---

## 🔍 Alternative: Check Agent Logs

If the agent keeps going offline, check the logs:

### On EC2 Agent:

```bash
# Check if agent process is running
ps aux | grep agent.jar

# If using systemd service
journalctl -u jenkins-agent -f

# Or check the agent log file (location varies)
tail -f /var/log/jenkins/agent.log
```

### On Jenkins Master UI:

1. Go to: `Manage Jenkins` → `Nodes` → `pop`
2. Click **"Log"**
3. Look for error messages

Common errors:
- `permission denied` → Docker group issue
- `connection refused` → Network issue
- `timeout` → Agent can't reach master

---

## 🎯 Most Common Solution

**99% of the time, this fixes it:**

```bash
# On EC2 agent
sudo usermod -aG docker ubuntu
sudo systemctl restart docker

# Wait 30 seconds

# Then on Jenkins Master UI:
# Disconnect and reconnect the agent
```

---

## 🧪 Test the Fixed Jenkinsfile

After fixing Docker permissions, your updated Jenkinsfile will:
1. ✅ Clean old containers safely
2. ✅ Clean old images safely
3. ✅ Not cause agent to go offline
4. ✅ Clone fresh from GitHub
5. ✅ Build and deploy successfully

---

## 📋 Complete Fix Checklist

- [ ] Identified agent user (usually `ubuntu`)
- [ ] Added agent user to docker group
- [ ] Restarted Docker service
- [ ] Tested docker commands as agent user
- [ ] Disconnected agent in Jenkins UI
- [ ] Reconnected agent in Jenkins UI
- [ ] Agent shows "In sync" and online
- [ ] Triggered a test build
- [ ] Build completes successfully

---

## 🆘 If Still Going Offline

### Check Security Groups (AWS):
```bash
# Ensure Jenkins master can reach agent
# In AWS Console → EC2 → Security Groups
# Allow inbound from Jenkins master IP on agent port (usually random high port)
```

### Check Agent Configuration:
In Jenkins Master UI → Nodes → pop → Configure:
- **Remote root directory**: `/home/ubuntu` (or your agent user's home)
- **Launch method**: Should match your setup (SSH, JNLP, etc.)
- **Availability**: "Keep this agent online as much as possible"

### Increase Agent Timeout:
In Jenkins Master UI → Manage Jenkins → Configure System:
- Look for "Agent protocols" or "TCP port for inbound agents"
- Increase timeout values if available

---

## 💡 Pro Tip

Add this verification stage at the start of your Jenkinsfile to catch Docker permission issues early:

```groovy
stage('Verify Docker Access') {
    steps {
        echo 'Verifying Docker access...'
        sh '''
            # Test docker command
            if docker ps > /dev/null 2>&1; then
                echo "✓ Docker access confirmed"
            else
                echo "✗ Docker permission denied!"
                echo "Run on agent: sudo usermod -aG docker $(whoami)"
                exit 1
            fi
        '''
    }
}
```

---

**Bottom line:** Your agent user needs to be in the `docker` group, and the agent needs to be reconnected after adding the group. That's it! 🚀
