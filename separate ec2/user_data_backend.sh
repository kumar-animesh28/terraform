#!/bin/bash
set -e

# --- Update packages ---
apt-get update -y
apt-get upgrade -y

# --- Install Python and dependencies ---
apt-get install -y python3 python3-venv python3-pip git

# --- Flask backend setup ---
mkdir -p /opt/flask-app
python3 -m venv /opt/flask-app/venv
/opt/flask-app/venv/bin/pip install flask

cat > /opt/flask-app/app.py << 'EOF'
from flask import Flask, jsonify
app = Flask(__name__)

@app.get('/api/hello')
def hello():
    return jsonify({'app': 'flask', 'msg': 'Hello from Flask backend!'})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOF

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

# --- Enable and start Flask service ---
systemctl daemon-reload
systemctl enable flask-app
systemctl start flask-app
