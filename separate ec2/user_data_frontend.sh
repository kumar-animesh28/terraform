#!/bin/bash
set -e

# Update packages
apt-get update -y
apt-get upgrade -y

# Install dependencies
apt-get install -y curl git nginx

# --- Install Node.js 20 ---
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

# --- Express frontend setup ---
mkdir -p /opt/express-app
cat > /opt/express-app/server.js << 'JSEOF'
const express = require('express');
const app = express();

app.get('/', (req,res) => {
  res.send('<h1>Hello from Express Frontend</h1><p>Backend API: <a href="/api/hello">/api/hello</a></p>');
});

app.listen(3000, '0.0.0.0', () => console.log(`Express running on 3000`));
JSEOF

cd /opt/express-app
npm init -y
npm install express

# --- Express systemd service ---
cat > /etc/systemd/system/express-app.service << 'EOF'
[Unit]
Description=Express Frontend
After=network.target

[Service]
WorkingDirectory=/opt/express-app
ExecStart=/usr/bin/node /opt/express-app/server.js
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable express-app.service
systemctl start express-app.service

# --- Nginx reverse proxy ---
cat > /etc/nginx/sites-available/express-front <<EOF
server {
    listen 80;

    # Frontend
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }

    # Backend API (private backend IP)
    location /api/ {
        proxy_pass http://${backend_ip}:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF

ln -s /etc/nginx/sites-available/express-front /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
systemctl restart nginx
