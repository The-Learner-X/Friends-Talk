apt update && apt upgrade -y
pkg install nodejs tmux wget proot fastfetch -y 

cat << 'EOF' >> /data/data/com.termux/files/usr/etc/bash.bashrc
clear
fastfetch
EOF

# --- Create and step into correct project folder structural hierarchy ---
mkdir -p /data/data/com.termux/files/home/Friends-Talk/public
cd /data/data/com.termux/files/home/Friends-Talk

echo "=========================================="
echo "Initialize Node.js and Install Dependencies ......"
echo "=========================================="
npm init -y
npm i express dotenv mysql2

echo "=========================================="
echo "Creating index.js (Secure Routing) ....."
echo "=========================================="
cat << 'EOF' > index.js

require('dotenv').config();
const express = require('express');
const mysql = require('mysql2');
const path = require('path');
const app = express();

app.use(express.json());

// --- Serve Static Files from 'public' folder ---
app.use(express.static(path.join(__dirname, 'public')));

// --- MariaDB Connection ---
const db = mysql.createConnection({
  host:'localhost',
  user:'root',
  password: process.env.DB_PASSWORD || 'mlp0', // Reads from .env or defaults
  database: 'friends_talk'
});

db.connect((err) => {
  if (err) {
    console.error("Database connection failed:", err.message);
  } else {
    console.log("Connected seamlessly to Termux MariaDB!");
    
    // Auto-create required tables if they don't exist
    const createUsersTable = `
      CREATE TABLE IF NOT EXISTS users (
        username VARCHAR(255) PRIMARY KEY,
        status VARCHAR(50) DEFAULT 'online',
        last_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      );
    `;
    const createChatLogsTable = `
      CREATE TABLE IF NOT EXISTS chat_logs (
        id INT AUTO_INCREMENT PRIMARY KEY,
        username VARCHAR(255),
        message TEXT,
        timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `;

    db.query(createUsersTable, (err) => {
      if (err) console.error("Error creating users table:", err.message);
    });
    db.query(createChatLogsTable, (err) => {
      if (err) console.error("Error creating chat_logs table:", err.message);
    });
  }
});

// Serve admin.html from ROOT project folder
app.get('/admin.html', (req, res) => {
  res.sendFile(path.join(__dirname, 'admin.html'));
});

// Serve index.html from 'public' directory
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// --- Endpoint to verify admin password securely ---
app.post('/verify-admin', (req, res) => {
  const { password } = req.body;
  const SECRET_ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || 'server.js'; // Reads from .env or defaults

  if (password === SECRET_ADMIN_PASSWORD) {
    res.json({ success: true });
  } else {
    res.json({ success: false });
  }
});

// --- Endpoint to clear all chat logs (Btn1) ---
app.post('/clear-chats', (req, res) => {
  const query = "DELETE FROM chat_logs";
  db.query(query, (err, result) => {
    if (err) return res.status(500).json({ success: false, error: err.message });
    res.json({ success: true, message: "Chat records wiped cleanly!" });
  });
});

// --- Endpoint to clear all online users (Btn2) ---
app.post('/clear-users', (req, res) => {
  const query = "DELETE FROM users";
  db.query(query, (err, result) => {
    if (err) return res.status(500).json({ success: false, error: err.message });
    res.json({ success: true, message: "User list reset completely!" });
  });
});

// --- Endpoint to log in a user ---
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

// --- Endpoint to get all logged-in users ---
app.get('/get-online-users', (req, res) => {
  const query = "SELECT username FROM users WHERE status = 'online' ORDER BY username ASC";
  
  db.query(query, (err, results) => {
    if (err) return res.status(500).json({ success: false, error: err.message });
    const userList = results.map(row => row.username);
    res.json({ success: true, users: userList });
  });
});

// --- Fetch all chat logs ---
app.get('/get-messages', (req, res) => {
  const query = "SELECT username, message, DATE_FORMAT(timestamp, '%H:%i') as time FROM chat_logs ORDER BY id ASC";
  
  db.query(query, (err, results) => {
    if (err) return res.status(500).json({ success: false, error: err.message });
    res.json({ success: true, logs: results });
  });
});

// --- Insert new text directly into chat logs ---
app.post('/update-html', (req, res) => {
  const { username, message } = req.body;
  if (!username || !message) return res.status(400).json({ success: false, error: "Missing fields" });

  const query = "INSERT INTO chat_logs (username, message) VALUES (?, ?)";
  
  db.query(query, [username, message], (err, result) => {
    if (err) return res.status(500).json({ success: false, error: err.message });
    res.json({ success: true });
  });
});

// --- Dynamic Port Configuration ---
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Database server running flawlessly on http://localhost:${PORT}`);
});


EOF

# index.html

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
  
  <style type="text/css">

  
  @media (max-width: 768px) {
    
  .navbar{
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 0.5rem 1rem;
    font-size: 23px;
    background: rgb(150, 50, 130);
  }
  .navLinks{
    display: flex;
    font-size: 23px;
  }
  a{
    margin-left: 30px;
    border-radius: 50px;
  }
  
  a{
    text-decoration: none;
    color: black;
  }
  
  img{
    width: 40px;
    height: 40px;
  }
  
  a:hover{
    color: blue;
    box-shadow: 0px 0px 100px blue;
  }

  
  .home:hover{
    box-shadow: 0px 0px 100px blue;
    color: blue;
  }
  
  .admin:hover{
    box-shadow: 0px 0px 100px blue;
    color: blue;
  }
  
  h1{
    text-align: center;
    font-size: 33px;
  }
  
  h3{
    font-size: 23px;
  }
  
  .info{
    font-size: 23px;
  }
  
  input{
    height: 20px;
    width: 100px;
    font-size: 20px;
  }
  
  #chat-box{
    height: 80px;
    font-size: 20px;
  }
  
  .admin-panel{
    height: 60px;
    width: 250px;
    font-size: 20px;
  }
  
  .user{
    height: 50px;
    width: 150px;
    font-size: 20px;
  }
  
  .send{
    height: 60px;
    width: 250px;
    font-size: 20px;
  }
  
  .messege-section{
    display: flex;
    align-items: center;
    justify-content: center;
  }
  
  .AP{
    display: flex;
    align-items: center;
    justify-content: center;
  }
  
    #meg{
    font-size: 20px;
  }

  }
  
  @media (min-width: 768px){
    
    
  .navbar{
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 1rem 2rem;
    font-size: 40px;
    background: rgb(60, 70, 90);
  }
  .navLinks{
    display: flex
    font-size: 33px;
  }
  a{
    margin-left: 100px;
  }
  
  a{
    text-decoration: none;
    color: black;
    border-radius: 50px;
  }
  
  img{
    width: 80px;
    height: 80px;
  }
  
  a:hover{
    color: blue;
    box-shadow: 0px 0px 100px blue;
  }
  
  .home:hover{
    box-shadow: 0px 0px 100px blue;
    color: blue;
  }
  
  .admin:hover{
    box-shadow: 0px 0px 100px blue;
    color: blue;
  }
  
  h1{
    text-align: center;
    font-size: 45px;
  }
  
  h3{
    font-size: 33px;
  }
  
  .info{
    font-size: 40px;
  }
  
  input{
    height: 60px;
    width: 200px;
    font-size: 25px;
  }
  
  #chat-box{
    height: 80px;
    font-size: 33px;
  }
  
  .admin-panel{
    height: 60px;
    width: 250px;
    font-size: 20px;
  }
  
  .user{
    height: 60px;
    width: 150px;
    font-size: 20px;
  }
  
  .send{
    height: 60px;
    width: 250px;
    font-size: 20px;
  }
  
  .messege-section{
    display: flex;
    align-items: center;
    justify-content: center;
  }
  
  .AP{
    display: flex;
    align-items: center;
    justify-content: center;
  }
  
  #meg{
    font-size: 25px;
  }
  
  }
  
  </style>
  
  <script src="https://unpkg.com/piesocket-js@5"></script>
</head>
<body>
  
  <nav class="navbar">
    <div class="navLogo"><img src="nature3.jpeg" alt="nature theme" /></div>
    <div class="navLinks">
      <a href="#home">Home</a>
      <a id="adminPortalBtn">Admin Panel</a>
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


  <div id="presence-area" class="presence-box" style="display: none;">
    <strong>Connected Users:</strong>
    <ul id="online-users-list"></ul>
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
  <!--
  <div style="margin-top: 15px;">
  <button type="button" id="adminPortalBtn" class="admin">
    Open Admin Panel 🔒
  </button>
</div>
  -->

  <script type="text/javascript" charset="utf-8" src="f-t.js"></script>
</body>
</html>

EOF

# friends.css

echo "=========================================="
echo "Creating f-t.css ...."
echo "=========================================="
cat << 'EOF' > public/f-t.css

@media (min-width: 768px){
  
  /* Base Layout Styles */
body {
  font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
  margin: 30px;
  background-color: #fcfcfc;
  color: #333;
  font-size: 33px;
}


.head{
  text-align: center;
}

h1, h2, h3 {
  color: #2c3e50;
}

textarea {
  width: 900px;
  padding: 10px;
  border: 1px solid #bdc3c7;
  border-radius: 6px;
  resize: vertical;
  font-size: 24px;
}

button {
  padding: 8px 15px;
  background-color: #3498db;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-weight: bold;
}

button:hover {
  background-color: #2980b9;
}

/* Chat Log Box */
#chat-box {
  border: 2px solid #e2e8f0;
  padding: 15px;
  margin-top: 15px;
  height: 100px;
  max-height: 400px;
  overflow-y: auto;
  background-color: #ffffff;
  border-radius: 8px;
  box-shadow: inset 0 2px 4px rgba(0,0,0,0.05);
}

.chat-message {
  margin-bottom: 10px;
  padding-bottom: 5px;
  border-bottom: 1px dashed #f0f0f0;
}

/* User Live Badge UI */
.status-badge {
  display: inline-flex;
  align-items: center;
  font-size: 0.85rem;
  padding: 4px 10px;
  border-radius: 12px;
  font-weight: bold;
  background: #d4edda;
  color: #155724;
  border: 1px solid #c3e6cb;
}

.status-dot {
  width: 8px;
  height: 8px;
  background-color: #2ecc71;
  border-radius: 50%;
  margin-right: 6px;
  box-shadow: 0 0 8px #2ecc71;
}

#logoutBtn {
  background-color: #e74c3c;
  padding: 4px 10px;
  font-size: 0.8rem;
}

#logoutBtn:hover {
  background-color: #c0392b;
}

.person{
  height: 60px;
  font-size: 33px;
}

.user{
  height: 60px;
  width: 150px;
  font-size: 20px;
}

.send{
  height: 60px;
  width: 200px;
  font-size: 20px;
}

.admin{
  background-color: #34495e; 
  color: white; 
  padding: 8px 12px; 
  border: none; 
  border-radius: 4px; 
  cursor: pointer; 
  font-weight: bold;
  width: 400px;
  height: 80px;
  font-size: 33px;
  text-align: center;
  position: relative;
  left: ;
}
  
}

@media (max-width: 768px) {
  
  body {
  font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
  margin: 20px;
  background-color: #fcfcfc;
  color: #333;
  font-size: 23px;
}



button {
  padding: 8px 15px;
  background-color: #3498db;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-weight: bold;
}

  button:hover {
  box-shadow: 0px 0px 100px purple;
  }
  
  .home:hover{
    box-shadow: 0px 0px 100px blue;
    color: blue;
  }
  
  .admin:hover{
    box-shadow: 0px 0px 100px blue;
    color: blue;
  }
  
  h1{
    text-align: center;
    font-size: 33px;
  }
  
  h3{
    font-size: 23px;
  }
  
  .info{
    font-size: 23px;
  }
  
  input{
    height: 20px;
    width: 100px;
    font-size: 20px;
  }
  
  #chat-box{
  border: 2px solid #e2e8f0;
  padding: 15px;
  margin-top: 15px;
  height: 100px;
  overflow-y: auto;
  background-color: #ffffff;
  border-radius: 8px;
  box-shadow: inset 0 2px 4px rgba(0,0,5,0.05);
  height: 80px;
  font-size: 20px;
  }
  
  .admin-panel{
    height: 60px;
    width: 250px;
    font-size: 20px;
  }
  
  .user{
    height: 50px;
    width: 150px;
    font-size: 20px;
  }
  
  .send{
    height: 60px;
    width: 250px;
    font-size: 20px;
  }
  
  .messege-section{
    display: flex;
    align-items: center;
    justify-content: center;
  }
  
  .AP{
    display: flex;
    align-items: center;
    justify-content: center;
  }
  
    #meg{
    font-size: 20px;
    width: 100%;
  }

  }

EOF


echo "=========================================="
echo "Creating f-t.js ...."
echo "=========================================="
cat << 'EOF' > public/f-t.js

// --- Global Variables ---
let currentUser = "";
let lastMessageCount = 0; 
const userSessionArea = document.getElementById("user-session-area");
const messageInput = document.getElementById("meg");
const sendBtn = document.getElementById("Send");
const chatBox = document.getElementById("chat-box");

// --- Fail-Safe Notification Permission Request ---
function requestNotificationPermission() {
  if ("Notification" in window) {
    try {
      Notification.requestPermission().then(permission => {
        if (permission === "granted") console.log("Notification access allowed!");
      }).catch(err => console.log("Notifications blocked or unsecure context."));
    } catch (e) {
      console.log("Skipping notifications on unsecure context layout.");
    }
  }
}

// --- Secure Admin Portal Access Router ---
document.getElementById("adminPortalBtn").addEventListener("click", () => {
  const passwordInput = prompt("Enter Admin Secure Token Password:");
  if (!passwordInput) return;

  fetch('/verify-admin', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ password: passwordInput })
  })
  .then(res => res.json())
  .then(data => {
    if (data.success) {
      window.location.href = "/admin.html";
    } else {
      alert("Access Denied! Incorrect admin password.");
    }
  })
  .catch(err => console.error("Admin verification connection lost:", err));
});

// --- Trigger System Notification ---
function triggerNotification(sender, messageBody) {
  if ("Notification" in window && Notification.permission === "granted" && document.hidden) {
    new Notification(`New message from ${sender}`, {
      body: messageBody,
      icon: "https://cdn-icons-png.flaticon.com/512/5962/5962463.png"
    });
  }
}

// --- Fetch Online Users ---
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
          presenceDiv.style.marginTop = "5px";
          presenceDiv.style.fontWeight = "bold";
          userSessionArea.appendChild(presenceDiv);
        }
        presenceDiv.innerHTML = `Logined in usr = <span style="color:#2980b9;">${otherUsers.length > 0 ? otherUsers.join(', ') : 'none'}</span>`;
      }
    });
}

// --- Fetch Chat Logs ---
function loadChatLogs() {
  fetch('/get-messages')
    .then(res => res.json())
    .then(data => {
      if (data.success) {
        if (lastMessageCount > 0 && data.logs.length > lastMessageCount) {
          const latestChat = data.logs[data.logs.length - 1];
          if (latestChat.username !== currentUser) {
            triggerNotification(latestChat.username, latestChat.message);
          }
        }
        lastMessageCount = data.logs.length;

        chatBox.innerHTML = "";
        data.logs.forEach(log => {
          const messageElement = document.createElement("div");
          messageElement.style.marginBottom = "10px";
          
          const isMe = log.username === currentUser;
          const labelColor = isMe ? "#27ae60" : "#2980b9";
          
          messageElement.innerHTML = `
            <strong style="color: ${labelColor};">${log.username}</strong>: 
            <div style="display:inline-block;">${log.message}</div>
            <span style="color: #95a5a6; font-size: 0.75rem; margin-left: 6px;">(${log.time})</span>
          `;
          chatBox.appendChild(messageElement);
        });
        chatBox.scrollTop = chatBox.scrollHeight;
      }
    })
    .catch(err => console.error("Error fetching logs:", err));
}

// --- Handle User Session Creation ---
function handleUserCreation() {
  const userInput = document.getElementById("person");
  if (!userInput) return alert("Input element missing!");

  const nameValue = userInput.value.trim();
  if (nameValue === "") {
    alert("Please enter a name!");
    return;
  }
  
  currentUser = nameValue;

  fetch('/login-user', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username: currentUser })
  })
  .then(res => res.json())
  .then(data => {
    if (data.success) {
      userSessionArea.innerHTML = `<h2>Active usr = <span style="color:#3498db;">${currentUser}</span></h2>`;
      
      requestNotificationPermission();
      loadChatLogs();
      loadOnlineUsers();
      
      setInterval(loadChatLogs, 2000);
      setInterval(loadOnlineUsers, 2000);
    }
  })
  .catch(err => {
    console.error("Login route error:", err);
    alert("Failed to connect to backend server.");
  });
}

// --- Handle Message Submission ---
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

// --- Direct Event Binding ---
document.getElementById("addUserBtn").addEventListener("click", handleUserCreation);

EOF

cd $HOME

cat << 'EOF' > admin.html

<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta http-equiv="X-UA-Compatible" content="ie=edge">
  <title>History</title>
  
  <style type="text/css">
    
      h1{
      text-align: center;
      font-size: 60px;
    }
    
    button{
      text-align: center;
      font-size: 20px;
    }
    
    .COU{
      background-color: #c0392b; 
      color: white; 
      padding: 8px 12px; 
      border: none; 
      border-radius: 4px; 
      cursor: pointer;
      width: 500px;
      height: 100px;
      font-size: 33px;
    }
    
    .CCB{
      background-color: #e74c3c; 
      color: white; 
      padding: 8px 12px; 
      border: none; 
      border-radius: 4px; 
      cursor: pointer;
      width: 500px;
      height: 100px;
      font-size: 33px;
    }

    #chat-box {
      min-height: 150px;
      max-height: 400px;
      overflow-y: auto;
      padding: 15px;
      border: 1px solid #ccc;
      background: #f9f9f9;
      border-radius: 8px;
    }

    #db-presence-list {
      font-size: 24px;
      margin: 15px 0;
      font-weight: bold;
    }
    
  </style>
</head>
<body>
  
  <button type="button" onclick="window.location.href='index.html'" style="padding: 10px 20px; margin-top: 10px; cursor: pointer;">← Back to Chat</button>
  <hr>

  <h1>Welcome Admin</h1>

  <hr>

  <div id="db-presence-list">Logined in usr = <span style="color:#2980b9;">loading...</span></div>

  <h3>Live Chat Log:</h3>
  <div id="chat-box"></div>

  <hr>

  <div class="admin-section" style="margin-top: 15px; display: flex; gap: 10px;">
    <button type="button" id="clearChatsBtn" class="CCB">
      Clear Chat Logs
    </button>
    <button type="button" id="clearUsersBtn" class="COU">
      Clear Online Users
    </button>
  </div>

  <hr>

  <script type="text/javascript" charset="utf-8">
    const chatBox = document.getElementById("chat-box");
    const presenceList = document.getElementById("db-presence-list");

    // --- Fetch & Render Chat Logs directly from MariaDB ---
    function loadChatLogs() {
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
              const messageElement = document.createElement("div");
              messageElement.style.marginBottom = "10px";
              messageElement.style.fontSize = "20px";
              
              messageElement.innerHTML = `
                <strong style="color: #2980b9;">${log.username}</strong>: 
                <div style="display:inline-block;">${log.message}</div>
                <span style="color: #95a5a6; font-size: 0.85rem; margin-left: 6px;">(${log.time})</span>
              `;
              chatBox.appendChild(messageElement);
            });
            chatBox.scrollTop = chatBox.scrollHeight;
          }
        })
        .catch(err => console.error("Error fetching logs for admin:", err));
    }

    // --- Fetch & Render Currently Logged-in Users list ---
    function loadOnlineUsers() {
      fetch('/get-online-users')
        .then(res => res.json())
        .then(data => {
          if (data.success) {
            if (data.users.length > 0) {
              presenceList.innerHTML = `Logined in usr = <span style="color:#2980b9;">${data.users.join(', ')}</span>`;
            } else {
              presenceList.innerHTML = `Logined in usr = <span style="color:#7f8c8d;">none</span>`;
            }
          }
        })
        .catch(err => console.error("Error fetching online users for admin:", err));
    }

    // --- Admin Database Clear Handlers ---

    // Handle Button 1: Delete all chat entries
    document.getElementById("clearChatsBtn").addEventListener("click", () => {
      if (!confirm("Are you sure you want to clear the entire chat log history?")) return;

      fetch('/clear-chats', { method: 'POST' })
        .then(res => res.json())
        .then(data => {
          if (data.success) {
            alert(data.message);
            loadChatLogs(); // Instantly clears out the display view layout cleanly
          }
        })
        .catch(err => console.error("Failed to clear chat log records:", err));
    });

    // Handle Button 2: Delete all registered online users
    document.getElementById("clearUsersBtn").addEventListener("click", () => {
      if (!confirm("Are you sure you want to drop all active logged-in profiles?")) return;

      fetch('/clear-users', { method: 'POST' })
        .then(res => res.json())
        .then(data => {
          if (data.success) {
            alert(data.message);
            loadOnlineUsers(); // Instantly update online tracker string layout
          }
        })
        .catch(err => console.error("Failed to clear online database list:", err));
    });

    // --- Initial Auto-Load and live loop setup ---
    loadChatLogs();
    loadOnlineUsers();
    
    // Auto-refresh the admin panel dashboard state data every 2 seconds
    setInterval(loadChatLogs, 2000);
    setInterval(loadOnlineUsers, 2000);
  </script>
  
</body>
</html>


EOF


echo "=========================================="
echo "Creating LocalHost Command ....."
echo "=========================================="
cat << 'EOF' > $PREFIX/bin/Lstart
node $HOME/Friends-Talk/index.js
EOF
chmod +x $PREFIX/bin/Lstart
echo "=========================================="
echo "CMD :- Lstart"
echo "=========================================="

echo "=========================================="
echo "Installing NGROK ...."
echo "=========================================="
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
    url: $USER_DOMAIN
EOF

mv ngrok $PREFIX/bin/
echo "ngrok start webapp" > $PREFIX/bin/Pstart
chmod +x $PREFIX/bin/Pstart
echo "=========================================="
echo "Pstart"
echo "=========================================="

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

# --Adding image to Friends-Talk/public---
mv nature3.jpeg $HOME/Friends-Talk/public
echo "=========================================="
echo "Moving Nature3.jpeg successful"
echo "=========================================="

# --- Password Setup Prompt ---
echo "=========================================="
echo "      SECURE CHAT SERVER SETUP            "
echo "=========================================="
read -p "Set your Termux MariaDB Database Password: "DB_PASS"
read -p "Set your Admin Panel Password: "admin_pass"
# Create the hidden environment file cleanly
cat << EOF > .env
DB_PASSWORD=${DB_PASS}
ADMIN_PASSWORD=${admin_pass}
EOF
echo "=========================================="
echo "$DB_PASS"
echo "=========================================="

echo "=================================================="
echo "Setup complete! Type 'server' to start everything."
echo "=================================================="
echo "------- You have to install Mariadb manualy ------"
