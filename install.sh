#!/bin/bash

echo "=========================================="
echo "Updating and installing packages ...."
echo "=========================================="
apt update && apt upgrade -y
pkg install nodejs tmux wget proot fastfetch mariadb -y 

cat << 'EOF' >> /data/data/com.termux/files/usr/etc/bash.bashrc
clear
fastfetch
EOF

echo "=========================================="
echo "--- Setup Server Directory ---"
echo "=========================================="
mkdir -p public

echo "=========================================="
echo "Initialize Node.js and Install Dependencies ......"
echo "=========================================="
npm init -y
npm i express mysql2 dotenv -y

# --- Password Setup Prompt ---
echo "=========================================="
echo "      SECURE CHAT SERVER SETUP            "
echo "=========================================="
read -p "Set your Termux MariaDB Database Password: " DB_PASS
read -p "Set your Admin Panel Secure Access Token: " ADMIN_PASS
echo "=========================================="

# Create the hidden environment file
cat << EOF > .env
DB_PASSWORD="$DB_PASS"
ADMIN_PASSWORD="$ADMIN_PASS"
EOF

echo "=========================================="
echo "Creating server.js (Secure Routing) ....."
echo "=========================================="
cat << 'EOF' > server.js
require('dotenv').config();
const express = require('express');
const mysql = require('mysql2');
const path = require('path');
const app = express();

app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

const db = mysql.createConnection({
  host: 'localhost',
  user: 'root',                  
  password: process.env.DB_PASSWORD, 
  database: 'friends_talk'
});

db.connect((err) => {
  if (err) console.error("Database connection failed:", err.message);
  else console.log("Connected seamlessly to Termux MariaDB!");
});

const validateAdmin = (req, res, next) => {
  const token = req.headers['x-admin-auth'] || req.body.password;
  if (token === process.env.ADMIN_PASSWORD) {
    next();
  } else {
    res.status(403).json({ success: false, error: "Access Denied!" });
  }
};

app.post('/verify-admin', validateAdmin, (req, res) => {
  res.sendFile(path.join(__dirname, 'admin.html'));
});

app.post('/clear-chats', (req, res) => {
  if (req.headers['x-admin-auth'] !== process.env.ADMIN_PASSWORD) return res.status(403).send("Unauthorized");
  const query = "DELETE FROM chat_logs";
  db.query(query, (err, result) => {
    if (err) return res.status(500).json({ success: false, error: err.message });
    res.json({ success: true, message: "Chat records wiped cleanly!" });
  });
});

app.post('/clear-users', (req, res) => {
  if (req.headers['x-admin-auth'] !== process.env.ADMIN_PASSWORD) return res.status(403).send("Unauthorized");
  const query = "DELETE FROM users";
  db.query(query, (err, result) => {
    if (err) return res.status(500).json({ success: false, error: err.message });
    res.json({ success: true, message: "User list reset completely!" });
  });
});

app.post('/login-user', (req, res) => {
  const { username } = req.body;
  if (!username) return res.status(400).json({ success: false, error: "Missing username" });

  const query = `
    INSERT INTO users (username, status) 
    VALUES (?, 'online') 
    ON DUPLICATE KEY UPDATE status='online', last_seen=CURRENT_TIMESTAMP
  `;

  db.query(query, [username], (err, result) => {
    if (err) return res.status(500).json({ success: false, error: err.message });
    res.json({ success: true });
  });
});

app.get('/get-online-users', (req, res) => {
  const query = "SELECT username FROM users WHERE status = 'online' ORDER BY username ASC";
  db.query(query, (err, results) => {
    if (err) return res.status(500).json({ success: false, error: err.message });
    const userList = results.map(row => row.username);
    res.json({ success: true, users: userList });
  });
});

app.get('/get-messages', (req, res) => {
  const query = "SELECT username, message, DATE_FORMAT(timestamp, '%H:%i') as time FROM chat_logs ORDER BY id ASC";
  db.query(query, (err, results) => {
    if (err) return res.status(500).json({ success: false, error: err.message });
    res.json({ success: true, logs: results });
  });
});

app.post('/update-html', (req, res) => {
  const { username, message } = req.body;
  if (!username || !message) return res.status(400).json({ success: false, error: "Missing fields" });

  const query = "INSERT INTO chat_logs (username, message) VALUES (?, ?)";
  db.query(query, [username, message], (err, result) => {
    if (err) return res.status(500).json({ success: false, error: err.message });
    res.json({ success: true });
  });
});

app.listen(3000, () => {
  console.log('Database server running flawlessly on http://localhost:3000');
});
EOF

echo "=========================================="
echo "Creating frontend codes (index.html) ...."
echo "=========================================="
cat << 'EOF' > public/index.html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Friends Talk</title>
  <link rel="stylesheet" type="text/css" href="f-t.css">
</head>
<body>
  <nav class="navbar">
    <div class="navLogo"><img src="nature1.jpeg" alt="nature theme" /></div>
    <div class="navLinks">
      <a href="#home">Home</a>
      <a id="adminPortalBtn" style="cursor:pointer;">Admin Panel</a>
    </div>
  </nav>
  <hr>
  <h1 class="head">Welcome to Friends Talk</h1>
  <hr>
  <ol>
    <li>Make account</li>
    <details>
      <summary>Important Note</summary>
      Real live sync is active. Enter your name to connect!
    </details>
    <li>Format -> add-your-name:your-message</li>
  </ol>
  <hr />
  <div id="user-session-area">
    <h1>Create user:- 
      <input type="text" name="person" class="person" id="person" placeholder="Enter your name"> 
      <button type="button" class="user" id="addUserBtn">Add User</button> 
    </h1>
  </div>
  <hr />
  <h3>Live Chat Log:</h3>
  <div id="chat-box"></div>
  <hr />
  <div class="message-section">
    <textarea name="meg" id="meg" rows="8" cols="40" placeholder="Type your message here..."></textarea>
    <br />
    <button type="button" id="Send" class="send">Send Message</button>
  </div>
  <hr> 
  <script type="text/javascript" charset="utf-8" src="f-t.js"></script>
</body>
</html>
EOF

echo "=========================================="
echo "Creating f-t.css ...."
echo "=========================================="
cat << 'EOF' > public/f-t.css
body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #fcfcfc; color: #333; margin: 20px; font-size: 23px; }
h1, h2, h3 { color: #2c3e50; text-align: center; }
button { padding: 8px 15px; background-color: #3498db; color: white; border: none; border-radius: 4px; cursor: pointer; font-weight: bold; }
button:hover { background-color: #2980b9; }

@media (max-width: 768px) {
  .navbar{ display: flex; justify-content: space-between; align-items: center; padding: 0.5rem 1rem; font-size: 23px; background: rgb(150, 50, 130); }
  .navLinks{ display: flex; font-size: 23px; }
  a{ margin-left: 30px; border-radius: 50px; text-decoration: none; color: black; }
  img{ width: 40px; height: 40px; }
  #chat-box{ height: 120px; font-size: 20px; border: 2px solid #e2e8f0; overflow-y: auto; background: white; padding: 10px; }
  .message-section{ display: flex; flex-direction: column; align-items: center; }
  #meg { width: 100%; font-size: 20px; }
}
@media (min-width: 768px){
  body { margin: 30px; font-size: 33px; }
  .navbar{ display: flex; justify-content: space-between; align-items: center; padding: 1rem 2rem; font-size: 40px; background: rgb(60, 70, 90); }
  .navLinks{ display: flex; font-size: 33px; }
  a{ margin-left: 100px; text-decoration: none; color: black; }
  img{ width: 80px; height: 80px; }
  #chat-box { border: 2px solid #e2e8f0; padding: 15px; height: 300px; overflow-y: auto; background-color: #ffffff; }
  #meg { width: 900px; font-size: 24px; }
}
EOF

echo "=========================================="
echo "Creating f-t.js ...."
echo "=========================================="
cat << 'EOF' > public/f-t.js
let currentUser = "";
const userSessionArea = document.getElementById("user-session-area");
const messageInput = document.getElementById("meg");
const sendBtn = document.getElementById("Send");
const chatBox = document.getElementById("chat-box");

document.getElementById("adminPortalBtn").addEventListener("click", () => {
  const passwordInput = prompt("Enter Admin Secure Token Password:");
  if (!passwordInput) return;

  fetch('/verify-admin', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ password: passwordInput })
  })
  .then(res => {
    if(res.ok) {
      // FIX: Bind securely directly onto global window object state space context cleanly
      window.adminToken = passwordInput; 
      return res.text();
    }
    throw new Error("Access Denied!");
  })
  .then(htmlContent => {
    document.open();
    document.write(htmlContent);
    document.close();
  })
  .catch(err => alert(err.message));
});

function loadOnlineUsers() {
  fetch('/get-online-users')
    .then(res => res.json())
    .then(data => {
      if (data.success) {
        const otherUsers = data.users.filter(user => user !== currentUser);
        let presenceDiv = document.getElementById("db-presence-list");
        if (!presenceDiv) {
          presenceDiv = document.createElement("div");
          presenceDiv.id = "db-presence-list";
          userSessionArea.appendChild(presenceDiv);
        }
        presenceDiv.innerHTML = `Logged in users: <span style="color:#2980b9;">${otherUsers.length > 0 ? otherUsers.join(', ') : 'none'}</span>`;
      }
    });
}

function loadChatLogs() {
  fetch('/get-messages')
    .then(res => res.json())
    .then(data => {
      if (data.success) {
        chatBox.innerHTML = "";
        data.logs.forEach(log => {
          const messageElement = document.createElement("div");
          const isMe = log.username === currentUser;
          const labelColor = isMe ? "#27ae60" : "#2980b9";
          messageElement.innerHTML = `<strong style="color: ${labelColor};">${log.username}</strong>: ${log.message} <span style="color: #95a5a6; font-size: 0.75rem;">(${log.time})</span>`;
          chatBox.appendChild(messageElement);
        });
        chatBox.scrollTop = chatBox.scrollHeight;
      }
    });
}

function handleUserCreation() {
  const userInput = document.getElementById("person");
  const nameValue = userInput ? userInput.value.trim() : "";
  if (nameValue === "") return alert("Please enter a name!");
  
  currentUser = nameValue;
  fetch('/login-user', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username: currentUser })
  })
  .then(res => res.json())
  .then(data => {
    if (data.success) {
      userSessionArea.innerHTML = `<h2>Active user: <span style="color:#3498db;">${currentUser}</span></h2>`;
      loadChatLogs();
      setInterval(loadChatLogs, 2000);
      setInterval(loadOnlineUsers, 2000);
    }
  });
}

sendBtn.addEventListener("click", () => {
  if (!currentUser) return alert("Please create a user first!");
  const textValue = messageInput.value.trim();
  if (textValue === "") return;

  fetch('/update-html', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username: currentUser, message: textValue })
  })
  .then(res => res.json())
  .then(data => {
    if (data.success) {
      messageInput.value = "";
      loadChatLogs();
    }
  });
});

document.getElementById("addUserBtn").addEventListener("click", handleUserCreation);
EOF

echo "=========================================="
echo "Creating Admin Panel page OUTSIDE public folder ....."
echo "=========================================="
cat << 'EOF' > admin.html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Admin Dashboard</title>
  <style type="text/css">
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; padding: 20px; background: #f4f6f9; color: #333;}
    h1 { text-align: center; margin: 20px 0; color: #2c3e50;}
    hr { border: 0; height: 1px; background: #ddd; margin: 20px 0; }
    #db-presence-list { margin: 15px 0; font-weight: bold; }
    #chat-box { min-height: 200px; max-height: 400px; overflow-y: auto; background: white; border: 2px solid #e2e8f0; padding: 15px; border-radius: 8px; box-shadow: inset 0 2px 4px rgba(0,0,0,0.05); margin-bottom: 20px;}
    .admin-section { display: flex; flex-wrap: wrap; gap: 15px; justify-content: center; margin-bottom: 20px; }
    .btn { padding: 12px 24px; color: white; border: none; border-radius: 6px; cursor: pointer; font-weight: bold; transition: background 0.2s ease, transform 0.1s ease; }
    .btn:active { transform: scale(0.98); }
    .btn-danger-primary { background-color: #c0392b; }
    .btn-danger-primary:hover { background-color: #a93226; }
    .btn-danger-secondary { background-color: #e74c3c; }
    .btn-danger-secondary:hover { background-color: #cd6155; }
    .btn-exit { width: 100%; padding: 15px; font-size: 1.1rem; background-color: #7f8c8d; }
    .btn-exit:hover { background-color: #95a5a6; }
    @keyframes colorShift { 0% { border-color: #27ae60; } 50% { border-color: #8e44ad; } 100% { border-color: #c0392b; } }
    .backBtn-container { padding: 5px; border: 3px solid #27ae60; border-radius: 8px; animation: colorShift 4s ease infinite; }
    @media (max-width: 768px) { body { font-size: 16px; padding: 15px; } h1 { font-size: 28px; } .btn { width: 100%; padding: 15px; font-size: 18px; } }
    @media (min-width: 768px) { body { font-size: 18px; max-width: 900px; margin: 0 auto; } h1 { font-size: 42px; } .btn { min-width: 200px; font-size: 18px; } }
  </style>
</head>
<body>
  <hr>
  <h1>Admin Management Suite</h1>
  <hr>
  <div id="db-presence-list">Logged in users: <span style="color:#2980b9;" id="presence">loading...</span></div>
  <h3>Live Chat Log Database:</h3>
  <div id="chat-box"></div>
  <div class="admin-section">
    <button type="button" id="clearChatsBtn" class="btn btn-danger-primary">Clear Chat Logs</button>
    <button type="button" id="clearUsersBtn" class="btn btn-danger-secondary">Clear Online Users</button>
  </div>
  <hr>
  <div class="backBtn-container">
    <button type="button" onclick="window.location.reload();" class="btn btn-exit">Exit Panel / Go Home</button>
  </div>
  <script type="text/javascript" charset="utf-8">
    const token = window.adminToken; 
    const chatBox = document.getElementById("chat-box");
    const presenceList = document.getElementById("presence");

    function loadAdminView() {
      fetch('/get-messages')
        .then(res => res.json())
        .then(data => {
          if (data.success) {
            chatBox.innerHTML = "";
            if (data.logs.length === 0) {
              chatBox.innerHTML = "<em style='color: #7f8c8d;'>No chat history found in database.</em>";
              return;
            }
            data.logs.forEach(log => {
              const div = document.createElement("div");
              div.style.marginBottom = "8px";
              div.innerHTML = `<strong style="color: #2980b9;">${log.username}</strong>: <span>${log.message}</span>`;
              chatBox.appendChild(div);
            });
            chatBox.scrollTop = chatBox.scrollHeight;
          }
        });
    }

    function loadOnlineUsers() {
      fetch('/get-online-users')
        .then(res => res.json())
        .then(data => {
          if (data.success) {
            presenceList.textContent = data.users.length > 0 ? data.users.join(', ') : 'none';
          }
        });
    }

    document.getElementById("clearChatsBtn").addEventListener("click", () => {
      if (!confirm("Are you sure you want to clear the database history logs?")) return;
      fetch('/clear-chats', { 
        method: 'POST',
        headers: { 'x-admin-auth': token }
      }).then(() => loadAdminView());
    });

    document.getElementById("clearUsersBtn").addEventListener("click", () => {
      if (!confirm("Are you sure you want to clear all active logged-in profiles?")) return;
      fetch('/clear-users', { 
        method: 'POST',
        headers: { 'x-admin-auth': token }
      }).then(() => loadOnlineUsers());
    });

    loadAdminView();
    loadOnlineUsers();
    setInterval(loadAdminView, 2000);
    setInterval(loadOnlineUsers, 2000);
  </script>
</body>
</html>
EOF

echo "=========================================="
echo "Creating LocalHost Command ....."
echo "=========================================="
cat << 'EOF' > $PREFIX/bin/Lstart
#!/bin/bash
# Automatically spin up the DB daemon if it isn't running before turning on node server
pgrep mysqld > /dev/null || mysqld_safe --datadir=${IS_AM_NOT_ROOT:+$PREFIX/var/lib/mysql} 2>&1 >/dev/null &
sleep 2
node /Friends-Talk/server.js
EOF
chmod +x $PREFIX/bin/Lstart

echo "=========================================="
echo "Installing NGROK ...."
echo "=========================================="
cd $HOME
wget https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-arm64.tgz
tar -xvzf ngrok-v3-stable-linux-arm64.tgz
chmod +x ngrok

echo "==========================="
echo "--- Ngrok Configuration ---"
echo "==========================="
read -p "Enter your Ngrok Authtoken: " USER_TOKEN
read -p "Enter your Port [Default: 3000]: " USER_PORT
USER_PORT=${USER_PORT:-3000}
read -p "Enter your Ngrok Static Domain Name: " USER_DOMAIN
echo "==========================="

mkdir -p ~/.config/ngrok
cat << EOF > ~/.config/ngrok/ngrok.yml
version: "3"
agent:
    authtoken: $USER_TOKEN
tunnels:
  webapp:
    proto: http
    addr: $USER_PORT
    domain: $USER_DOMAIN
EOF

mv ngrok $PREFIX/bin/
echo "ngrok start webapp" > $PREFIX/bin/Pstart
chmod +x $PREFIX/bin/Pstart

# Create the Master Runner
cat << 'EOF' > $PREFIX/bin/server
#!/bin/bash
SESSION="web_server"
tmux new-session -d -s $SESSION
tmux split-window -v
tmux send-keys -t $SESSION:0.0 "Lstart" C-m
tmux send-keys -t $SESSION:0.1 "termux-chroot" C-m
sleep 2
tmux send-keys -t $SESSION:0.1 "Pstart" C-m
tmux attach-session -t $SESSION
EOF
chmod +x $PREFIX/bin/server

echo "=================================================="
echo "Setup complete! Type 'server' to start everything."
echo "=================================================="
