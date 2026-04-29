#!/bin/bash
set -e

echo "=========================================="
echo "GoondVR Setup Script"
echo "=========================================="
echo ""

# Create application directory
echo "Creating application directory..."
mkdir -p ~/goondvr
cd ~/goondvr
mkdir -p videos conf

# Create .env file
echo "Creating environment configuration..."
cat > .env <<'EOF'
# GoFile Configuration
GOFILE_API_KEY=AjiBq8d9UPWFSSaBe1YKfomxBjTJXT1i
GOFILE_DELETE_AFTER_UPLOAD=true

# Supabase Configuration
SUPABASE_URL=https://iktbuxgnnuebuoqaywev.supabase.co
SUPABASE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlrdGJ1eGdubnVlYnVvcWF5d2V2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY3NTcwMjcsImV4cCI6MjA5MjMzMzAyN30.Tl5VJdAnUSVzcbMd4k5IMqQltcJjvVUMR5fHoNO-BVw

# Discord Notifications
DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/1497660499670863966/GjrVGaCdXCBgvYrnSM-pIepKHqSIA_HgyiIb7NM8rn4i9L5xHM7QlZJpqD60PAtQiOa-

# Chaturbate Cookies
CHATURBATE_COOKIES=jZcKVhbRNIWIisSY0xRsgC_2J1RUc6BnEl.V7CdohIw-1777442158-1.2.1.1-tLXuiJSDY6mfuZ1_rP_i_OCKuYoK4IPTjESVDag73.qdehisLULg2WXXp_ui_GRv4YXjBsDU9Gl3I.AAX79Ka1R0W2hQfY7XIBNn_dnDNf_PbK6jJs2n5ixR5EycKo6BaEODQI30i0oFJY6YAhNb6dDN9tsT__AyMQsrNCpFqumvYNDACYrGadOfyi4T4YTqkWkMyscwEtkNTLt6QHAW5XZNIr7PdV0X9FN8TACzG2udofsiFJeadZNO7r2W24ot6cpQRRXNNWhZsfqsE8bNO6NR0i1Ulgcy_qsKPd72xmC0407ip0OS4Nbum9FS_bQWu3EMl_6106mQb9WSalICMw

# User Agent
USER_AGENT=Mozilla/5.0 (iPhone; CPU iPhone OS 18_1_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Brave/1 Mobile/15E148 Safari/E7FBAF

# Admin Credentials
ADMIN_USERNAME=admin
ADMIN_PASSWORD=Basudevkr@123
EOF

# Create docker-compose.yml
echo "Creating Docker Compose configuration..."
cat > docker-compose.yml <<'EOF'
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
EOF

# Verify Docker is working
echo "Verifying Docker installation..."
docker --version
docker compose version

# Pull Docker image
echo "Pulling GoondVR Docker image..."
docker compose pull

# Start application
echo "Starting GoondVR application..."
docker compose up -d

# Wait for container to start
echo "Waiting for application to start..."
sleep 5

# Install ffmpeg in container
echo "Installing ffmpeg for video processing..."
docker exec -u root goondvr sh -c 'apk add --no-cache ffmpeg' || true

# Restart to apply changes
echo "Restarting application..."
docker compose restart
sleep 3

# Check status
echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
docker compose ps
echo ""
echo "Web Interface: http://54.210.37.19:8080"
echo "Username: admin"
echo "Password: Basudevkr@123"
echo ""
echo "To view logs: docker compose logs -f"
echo "To restart: docker compose restart"
echo "To stop: docker compose down"
echo ""
