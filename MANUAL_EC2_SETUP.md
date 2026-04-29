# Complete Manual EC2 Setup Guide for GoondVR

## 🚀 Step-by-Step Setup

### **Step 1: Launch EC2 Instance**

1. **Go to AWS Console**: https://console.aws.amazon.com/ec2/
2. Click **"Launch Instance"**

3. **Configure Instance:**

   **Name and tags:**
   - Name: `goondvr-server`

   **Application and OS Images (AMI):**
   - Select: **Ubuntu Server 26.04 LTS** (or 22.04 LTS)
   - Architecture: **64-bit (x86)**

   **Instance type:**
   - Select: **m7i-flex.large** (Free tier eligible)
   - 2 vCPU, 8 GiB Memory

   **Key pair (login):**
   - Click **"Create new key pair"**
   - Key pair name: `goondvr-key`
   - Key pair type: **RSA**
   - Private key file format: **.pem** (for SSH) or **.ppk** (for PuTTY)
   - Click **"Create key pair"**
   - **IMPORTANT**: Save the downloaded .pem file securely!

   **Network settings:**
   - Click **"Edit"**
   - **Firewall (security groups)**: Create security group
   - Security group name: `goondvr-sg`
   - Description: `Security group for GoondVR`
   
   **Add security group rules:**
   - Rule 1 (SSH):
     - Type: **SSH**
     - Protocol: **TCP**
     - Port: **22**
     - Source: **My IP** (automatically detects your IP)
   
   - Click **"Add security group rule"**
   - Rule 2 (Web UI):
     - Type: **Custom TCP**
     - Protocol: **TCP**
     - Port: **8080**
     - Source: **My IP** (or 0.0.0.0/0 for public access)

   **Configure storage:**
   - Size: **30 GiB**
   - Volume type: **gp3**
   - Delete on termination: **Yes** (checked)

4. **Review Summary** on the right side panel

5. Click **"Launch instance"**

6. Wait for instance state to show **"Running"** (takes ~1-2 minutes)

7. **Note down the Public IPv4 address** (e.g., 54.123.45.67)

---

### **Step 2: Connect to EC2 Instance**

#### **Option A: Using Windows PowerShell/CMD**

1. **Open PowerShell** as Administrator

2. **Navigate to where you saved the .pem file:**
   ```powershell
   cd C:\Users\hp\Downloads
   ```

3. **Fix permissions on .pem file (Windows):**
   ```powershell
   icacls "goondvr-key.pem" /inheritance:r
   icacls "goondvr-key.pem" /grant:r "%username%:R"
   ```

4. **Connect via SSH:**
   ```powershell
   ssh -i "goondvr-key.pem" ubuntu@YOUR_EC2_PUBLIC_IP
   ```
   
   Replace `YOUR_EC2_PUBLIC_IP` with your actual IP (e.g., 54.123.45.67)

5. **Type "yes"** when asked about authenticity

#### **Option B: Using AWS Console (Browser-based SSH)**

1. Go to **EC2 Dashboard** → **Instances**
2. Select your instance
3. Click **"Connect"** button at the top
4. Choose **"EC2 Instance Connect"** tab
5. Click **"Connect"**
6. A new browser tab opens with terminal access

---

### **Step 3: Update System and Install Docker**

Once connected to your EC2 instance, run these commands one by one:

```bash
# Update package list
sudo apt-get update

# Upgrade existing packages
sudo apt-get upgrade -y

# Install required dependencies
sudo apt-get install -y ca-certificates curl gnupg lsb-release

# Add Docker's official GPG key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package list again
sudo apt-get update

# Install Docker
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start Docker service
sudo systemctl enable docker
sudo systemctl start docker

# Add ubuntu user to docker group (so you don't need sudo)
sudo usermod -aG docker ubuntu

# Verify Docker installation
docker --version
```

**IMPORTANT**: After adding user to docker group, you need to log out and log back in:

```bash
exit
```

Then reconnect:
```bash
ssh -i "goondvr-key.pem" ubuntu@YOUR_EC2_PUBLIC_IP
```

**Verify Docker works without sudo:**
```bash
docker ps
docker compose version
```

---

### **Step 4: Create Application Directory**

```bash
# Create main directory
mkdir -p ~/goondvr
cd ~/goondvr

# Create subdirectories
mkdir -p videos conf
```

---

### **Step 5: Create Environment Configuration File**

```bash
# Create .env file
nano .env
```

**Copy and paste this content** (update with your actual values):

```env
# GoFile Configuration
GOFILE_API_KEY=AjiBq8d9UPWFSSaBe1YKfomxBjTJXT1i
GOFILE_DELETE_AFTER_UPLOAD=true

# Supabase Configuration
SUPABASE_URL=https://iktbuxgnnuebuoqaywev.supabase.co
SUPABASE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlrdGJ1eGdubnVlYnVvcWF5d2V2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY3NTcwMjcsImV4cCI6MjA5MjMzMzAyN30.Tl5VJdAnUSVzcbMd4k5IMqQltcJjvVUMR5fHoNO-BVw

# Discord Notifications (Optional)
DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/1497660499670863966/GjrVGaCdXCBgvYrnSM-pIepKHqSIA_HgyiIb7NM8rn4i9L5xHM7QlZJpqD60PAtQiOa-

# Chaturbate Cookies
CHATURBATE_COOKIES=jZcKVhbRNIWIisSY0xRsgC_2J1RUc6BnEl.V7CdohIw-1777442158-1.2.1.1-tLXuiJSDY6mfuZ1_rP_i_OCKuYoK4IPTjESVDag73.qdehisLULg2WXXp_ui_GRv4YXjBsDU9Gl3I.AAX79Ka1R0W2hQfY7XIBNn_dnDNf_PbK6jJs2n5ixR5EycKo6BaEODQI30i0oFJY6YAhNb6dDN9tsT__AyMQsrNCpFqumvYNDACYrGadOfyi4T4YTqkWkMyscwEtkNTLt6QHAW5XZNIr7PdV0X9FN8TACzG2udofsiFJeadZNO7r2W24ot6cpQRRXNNWhZsfqsE8bNO6NR0i1Ulgcy_qsKPd72xmC0407ip0OS4Nbum9FS_bQWu3EMl_6106mQb9WSalICMw

# User Agent
USER_AGENT=Mozilla/5.0 (iPhone; CPU iPhone OS 18_1_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Brave/1 Mobile/15E148 Safari/E7FBAF

# Admin Credentials
ADMIN_USERNAME=admin
ADMIN_PASSWORD=Basudevkr@123
```

**Save the file:**
- Press `Ctrl + X`
- Press `Y` (yes to save)
- Press `Enter` (confirm filename)

---

### **Step 6: Create Docker Compose Configuration**

```bash
# Create docker-compose.yml file
nano docker-compose.yml
```

**Copy and paste this content:**

```yaml
version: '3.8'

services:
  goondvr:
    image: ghcr.io/heapofchaos/goondvr:latest
    container_name: goondvr
    restart: unless-stopped
    ports:
      - "8080:8080"
    volumes:
      - ./videos:/usr/src/app/videos
      - ./conf:/usr/src/app/conf
    env_file:
      - .env
    environment:
      - GOFILE_ENABLED=true
      - SUPABASE_ENABLED=true
```

**Save the file:**
- Press `Ctrl + X`
- Press `Y`
- Press `Enter`

---

### **Step 7: Start the Application**

```bash
# Pull the Docker image (this may take a few minutes)
docker compose pull

# Start the application in background
docker compose up -d

# Check if container is running
docker compose ps

# View logs (press Ctrl+C to exit)
docker compose logs -f
```

**You should see:**
- Container status: "Up"
- Logs showing application starting
- Message about web server listening on port 8080

---

### **Step 8: Access the Web Interface**

1. **Open your web browser**

2. **Go to:**
   ```
   http://YOUR_EC2_PUBLIC_IP:8080
   ```
   
   Example: `http://54.123.45.67:8080`

3. **Login with:**
   - Username: `admin`
   - Password: `Basudevkr@123`

4. **You should see the GoondVR dashboard!**

---

### **Step 9: Add Recording Channels**

1. Click **"Add Channel"** button

2. **Fill in the form:**
   - **Username**: The streamer's username (e.g., "exampleuser")
   - **Site**: Select "Chaturbate" or "Stripchat"
   - **Resolution**: 1080 (recommended)
   - **Framerate**: 30 (recommended)

3. Click **"Add"** or **"Save"**

4. **Repeat** for each channel you want to record

---

## 🔧 Useful Commands

### **View Application Logs**
```bash
cd ~/goondvr
docker compose logs -f
```
Press `Ctrl+C` to exit

### **Restart Application**
```bash
cd ~/goondvr
docker compose restart
```

### **Stop Application**
```bash
cd ~/goondvr
docker compose down
```

### **Start Application**
```bash
cd ~/goondvr
docker compose up -d
```

### **Update to Latest Version**
```bash
cd ~/goondvr
docker compose pull
docker compose up -d
```

### **Check Container Status**
```bash
docker ps
```

### **Check Disk Space**
```bash
df -h
```

### **Check Videos Directory Size**
```bash
du -sh ~/goondvr/videos
```

### **List Recorded Videos**
```bash
ls -lh ~/goondvr/videos/
```

### **Delete Old Recordings (older than 7 days)**
```bash
find ~/goondvr/videos -name "*.mp4" -mtime +7 -delete
```

### **View System Resources**
```bash
# Install htop first
sudo apt install htop -y

# Run htop
htop
```
Press `q` to quit

### **Check Memory Usage**
```bash
free -h
```

### **Check CPU Usage**
```bash
top
```
Press `q` to quit

---

## 🔄 Setup Auto-Restart on Reboot

The `restart: unless-stopped` policy in docker-compose.yml ensures the container automatically starts when EC2 reboots.

**To test:**
```bash
# Reboot EC2
sudo reboot

# Wait 2-3 minutes, then reconnect
ssh -i "goondvr-key.pem" ubuntu@YOUR_EC2_PUBLIC_IP

# Check if container is running
docker ps
```

---

## 🔐 Setup GitHub Actions CI/CD

### **Step 1: Add GitHub Secrets**

1. Go to your GitHub repository: https://github.com/vasud3v/record-v3

2. Click **Settings** → **Secrets and variables** → **Actions**

3. Click **"New repository secret"**

4. **Add these 3 secrets:**

   **Secret 1:**
   - Name: `EC2_HOST`
   - Value: Your EC2 public IP (e.g., `54.123.45.67`)

   **Secret 2:**
   - Name: `EC2_USERNAME`
   - Value: `ubuntu`

   **Secret 3:**
   - Name: `EC2_SSH_KEY`
   - Value: Content of your `goondvr-key.pem` file
   
   To get the content:
   ```powershell
   # On Windows
   Get-Content C:\Users\hp\Downloads\goondvr-key.pem | clip
   ```
   Then paste into GitHub secret

### **Step 2: Test CI/CD**

The workflow is already in your repo at `.github/workflows/deploy-ec2.yml`

**To trigger deployment:**
1. Make any change to your code
2. Commit and push to `main` branch
3. Go to **Actions** tab in GitHub
4. Watch the deployment run

**Or manually trigger:**
1. Go to **Actions** tab
2. Click **"Deploy to EC2"** workflow
3. Click **"Run workflow"**
4. Select `main` branch
5. Click **"Run workflow"**

---

## 📊 Monitoring

### **View Live Logs**
```bash
cd ~/goondvr
docker compose logs -f goondvr
```

### **Check Recording Status**
Access web UI at `http://YOUR_EC2_IP:8080` to see:
- Active recordings
- Channel status (online/offline)
- Upload status
- Disk usage

### **Check GoFile Uploads**
- Login to https://gofile.io
- Check your files/folders
- Download links are also in the web UI logs

### **Check Supabase Database**
- Login to https://supabase.com
- Go to your project
- Click **Table Editor**
- View `recordings` table

---

## 🛑 Stopping/Starting EC2 Instance

### **Stop Instance (to save costs when not recording)**
1. Go to EC2 Console
2. Select your instance
3. Click **Instance state** → **Stop instance**

**Note:** Your Elastic IP (if assigned) may change when you stop/start

### **Start Instance**
1. Go to EC2 Console
2. Select your instance
3. Click **Instance state** → **Start instance**
4. Wait for it to be "Running"
5. Note the new public IP (if it changed)
6. Update GitHub secret `EC2_HOST` if IP changed

---

## 🗑️ Complete Cleanup (Delete Everything)

**To delete all AWS resources:**

1. **Terminate EC2 Instance:**
   - EC2 Console → Instances
   - Select instance → Instance state → Terminate instance

2. **Delete Security Group:**
   - EC2 Console → Security Groups
   - Select `goondvr-sg` → Actions → Delete security group

3. **Delete Key Pair:**
   - EC2 Console → Key Pairs
   - Select `goondvr-key` → Actions → Delete

4. **Release Elastic IP (if you created one):**
   - EC2 Console → Elastic IPs
   - Select IP → Actions → Release Elastic IP address

---

## 💰 Cost Estimate

**With m7i-flex.large (Free Tier Eligible):**
- First 750 hours/month: **FREE** (if within free tier limits)
- After free tier: ~$0.10/hour (~$73/month if running 24/7)
- Storage (30 GB): **FREE** (within 30 GB free tier)
- Data transfer: First 100 GB/month **FREE**

**Tips to stay in free tier:**
- Stop instance when not recording
- Use GoFile delete-after-upload to minimize storage
- Monitor your AWS billing dashboard

---

## 🆘 Troubleshooting

### **Can't connect via SSH**
- Check security group allows SSH (port 22) from your IP
- Verify you're using correct .pem file
- Check instance is in "Running" state
- Try EC2 Instance Connect from AWS Console

### **Can't access web UI**
- Check security group allows port 8080 from your IP
- Verify container is running: `docker ps`
- Check logs: `docker compose logs`
- Try accessing from EC2 itself: `curl localhost:8080`

### **Container not starting**
```bash
# Check logs
docker compose logs

# Check if port is already in use
sudo netstat -tulpn | grep 8080

# Restart Docker
sudo systemctl restart docker
docker compose up -d
```

### **Out of disk space**
```bash
# Check disk usage
df -h

# Clean up old recordings
find ~/goondvr/videos -name "*.mp4" -mtime +7 -delete

# Clean up Docker
docker system prune -a
```

### **Recording not starting**
- Check channel is actually online
- Verify cookies are valid (may need to update)
- Check logs for errors
- Verify GoFile API token is valid

---

## 📞 Support

- **GitHub Issues**: https://github.com/vasud3v/record-v3/issues
- **Check Logs**: Always check `docker compose logs` first
- **AWS Support**: https://console.aws.amazon.com/support/

---

## ✅ Quick Reference

**SSH Connect:**
```bash
ssh -i "goondvr-key.pem" ubuntu@YOUR_EC2_IP
```

**Start App:**
```bash
cd ~/goondvr && docker compose up -d
```

**View Logs:**
```bash
cd ~/goondvr && docker compose logs -f
```

**Update App:**
```bash
cd ~/goondvr && docker compose pull && docker compose up -d
```

**Web UI:**
```
http://YOUR_EC2_IP:8080
```

---

**🎉 You're all set! Happy recording!**
