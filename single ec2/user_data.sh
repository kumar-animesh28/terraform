#!/bin/bash
set -e

# --- Update packages ---
apt-get update -y
apt-get upgrade -y

# --- Install dependencies ---
apt-get install -y python3 python3-venv python3-pip curl git nginx

# --- Install Node.js 20 ---
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

# --- Flask backend setup ---
mkdir -p /opt/flask-app
python3 -m venv /opt/flask-app/venv
/opt/flask-app/venv/bin/pip install flask

cat > /opt/flask-app/app.py << 'PYEOF'
from flask import Flask, jsonify
app = Flask(__name__)

@app.get('/api/hello')
def hello():
    return jsonify({'app': 'flask', 'msg': 'Hello from Flask backend!'})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
PYEOF

# --- Flask systemd service ---
cat > /etc/systemd/system/flask-app.service << 'EOF'
[Unit]
Description=Flask Backend
After=network.target

[Service]
WorkingDirectory=/opt/flask-app
Environment="PATH=/opt/flask-app/venv/bin"
ExecStart=/opt/flask-app/venv/bin/python /opt/flask-app/app.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# --- Express frontend setup ---
mkdir -p /opt/express-app
cat > /opt/express-app/server.js << 'JSEOF'
const express = require('express');
const app = express();
const port = 3000;

app.get('/', (req,res)=> res.send('<h1>Hello from Express Frontend</h1><p>Go to <a href="/api/hello">/api/hello</a> for backend response</p>'));

app.listen(port,'0.0.0.0',()=>console.log(`Express running on ${port}`));
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

# --- Enable and start services ---
systemctl daemon-reload
systemctl enable flask-app.service
systemctl enable express-app.service
systemctl start flask-app.service
systemctl start express-app.service

# --- Nginx reverse proxy ---
cat > /etc/nginx/sites-available/flask-express << 'NGX'
server {
    listen 80;

    location /api/ {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
NGX

ln -s /etc/nginx/sites-available/flask-express /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
systemctl restart nginx