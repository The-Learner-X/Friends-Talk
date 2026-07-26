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
npm i express dotenv mysql2 -y
npm init -y

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
// Serves files inside the 'public' folder (HTML, CSS, JS, images)
app.use(express.static(path.join(__dirname, 'public')));

// --- MariaDB Connection ---
const db = mysql.createConnection({
  host:'localhost',
  user:'root',
  password: process.env.DB_PASSWORD || 'mlp0', // Reads from .env file or default empty
  database:'friends_talk'
});

db.connect((err) => {
  if (err) {
    console.error("Database connection failed:", err.message);
  } else {
    console.log("Connected seamlessly to Termux MariaDB!");
  }
});

// Route for default home page
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// --- Admin Endpoints ---
app.post('/clear-chats', (req, res) => {
  const query = "DELETE FROM chat_logs";
  db.query(query, (err, result) => {
    if (err) return res.status(500).json({ success: false, error: err.message });
    res.json({ success: true, message: "Chat records wiped cleanly!" });
  });
});

app.post('/clear-users', (req, res) => {
  const query = "DELETE FROM users";
  db.query(query, (err, result) => {
    if (err) return res.status(500).json({ success: false, error: err.message });
    res.json({ success: true, message: "User list reset completely!" });
  });
});

// --- User Endpoints ---
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

// --- Chat Endpoints ---
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

// Start listening on Port 3000
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
  <meta http-equiv="X-UA-Compatible" content="ie=edge">
  <title>Document</title>
  
  <link rel="stylesheet" href="friends.css" title="Looks" type="text/css" />
  
</head>
<body>
  
  <script type="text/javascript">

  </script>
  
  <main>
    <div class="circle">
      
    </div>
    <div class="circle">
      
    </div>
    <div class="circle">
      
    </div>
    <div class="circle">
      
    </div>
    <div class="circle">
      
    </div>
    <div class="circle">
      
    </div>
    <div class="circle">
      
    </div>
    <div class="circle">
      
    </div>
    <div class="circle">
      
    </div>
    <div class="circle">
      
    </div>
  </main>
  
  <section class="centerBody">
    <div class="page">
      
      <section id="userSection">
      Create User:- <input type="text" name="userName" id="userName" placeholder="Enter your name" />
      <button id="createUser">Create User</button>
      </section>
      
      <hr>
      <section id="onlineSection">
      User's Online:- <span> <!-- Created user names here --> </span>
      </section>
      
      <hr>
        <div id="chat-box">
          
        </div>
      <hr>
      
      <section id="messege">
        
        <textarea name="typeMessege" id="typeMessege" cols="30" rows="10"></textarea>
        
        <div id="align">
        <button id="send">Send Messege</button>
        </div>
        
      </section>
      
    </div>
  </section>
  
  <script src="friends.js"></script>
</body>
</html>
EOF

# friends.css

echo "=========================================="
echo "Creating friends.css ...."
echo "=========================================="
cat << 'EOF' > public/friends.css

#userName {
  /* Ensure proper box rendering for inline elements */
  display: inline-block;

  /* Set the background image */
  background-image: url("nature2.jpeg");
  background-size: cover;
  background-position: center;

  /* Clip the background to the text */
  -webkit-background-clip: text;
  background-clip: text;

  /* Fallback text color if clipping isn't supported */
  color: #333; 

  /* Makes the text transparent specifically for webkit/clipping */
  -webkit-text-fill-color: transparent; 

  /* Styling tip: thicker fonts show image patterns much better */
  font-weight: bold;
}

@media (max-height: 1100px ) {
  
  body{
    padding: 5px;
    margin: 0;
  }
  
  main{
    display: grid;
    grid-template-columns: repeat(10, 1fr);
    overflow-y: auto;
    box-shadow: inset 0px 0px 200px black;
  }
  .circle{
    width: 100px;
    height: 100px;
    margin: 10px;
    border-radius: 50%;
    background: rgb(200, 180, 100);
  }
  
  .centerBody{
    width: 100%;
    height: 800px;
    box-shadow: inset 0px 0px 200px red;
  }
  
  #userSection{
    display: grid;
    grid-template-columns: repeat(2);
    text-align: center;
    font-size: 33px;
  }
  
  #userName{
    
  }
  
  #userName:hover{
    box-shadow: 0px 0px 100px red;
  }
  
  button{
    height: 50px;
    border-radius: 50px;
    width: 250px;
    font-size: 30px;
  }
  
  #typeMessege{
    width: 100%;
    font-size: 15px;
  }
  
  #chat-box {
  border: 2px solid #e2e8f0;
  padding: 15px;
  margin: 15px;
  height: 300px;
  max-height: 400px;
  overflow-y: auto;
  background-color: #ffffff;
  border-radius: 8px;
  box-shadow: inset 0 2px 4px rgba(0,0,0,0.05);
  }
 
 #onlineSection{
   margin: 10px;
  }
 
 #align{
   display: flex;
   justify-content: end;
   align-items: end;
  }
 
 #createUser{
   margin-left: 30px;
   box-shadow: 0px 0px 10px red;
   border-top-width: 5px;
   border-bottom-width: 5px;
   border-left-width: 5px;
   border-right-width: 5px;
   border-color: green;
  }
 
 #createUser:hover{
   background: linear-gradient(
   45deg,
   rgb(251, 94, 51),
   rgb(192, 93, 251),
   rgb(180, 40, 200)
   );
   box-shadow: 0px 0px 10px black;
  }
 
 #send{
   box-shadow: 0px 0px 15px black;
   border-top-width: 5px;
   border-bottom-width: 5px;
   border-left-width: 5px;
   border-right-width: 5px;
  }
 
 #send:hover{
   border-color: green;
   box-shadow: 0px 0px 15px green;
  }
 
 #userName{
  height: 30px;
  font-size: 28px;
  margin: 10px;
  border-radius: 0px 50px 50px 0px;
 }
 #messege{
   margin: 10px;
 }
}

@media (min-height: 1100px ) {
  
  body{
    padding: 5px;
    margin: 0;
  }
  
  main{
    display: grid;
    grid-template-columns: repeat(10, 1fr);
    overflow-y: auto;
    box-shadow: inset 0px 0px 200px black;
  }
  .circle{
    width: 250px;
    height: 250px;
    margin: 10px;
    border-radius: 50%;
    background: rgb(200, 180, 100);
  }
  
  .centerBody{
    width: 100%;
    height: 1600px;
    box-shadow: inset 0px 0px 200px red;
  }
  
  #userSection{
    display: grid;
    grid-template-columns: repeat(2);
    text-align: center;
    font-size: 55px;
  }
  
  #userName{
    height: 80px;
    font-size: 53px;
    margin: 10px;
    border-radius: 0px 50px 50px 0px;
  }
  
  #userName:hover{
    box-shadow: 0px 0px 100px red;
  }
  
  button{
    height: 70px;
    border-radius: 50px;
    width: 350px;
    font-size: 53px;
  }
  
  #typeMessege{
    width: 100%;
    font-size: 43px;
  }
  
  #chat-box {
  border: 2px solid #e2e8f0;
  padding: 5px;
  margin: 15px;
  height: 600px;
  max-height: 600px;
  overflow-y: auto;
  background-color: #ffffff;
  border-radius: 8px;
  box-shadow: inset 0 2px 4px rgba(0,0,0,0.07);
  font-size: 43px;
  }
 
 #onlineSection{
   margin: 10px;
   font-size: 53px;
  }
 
 #align{
   display: flex;
   justify-content: end;
   align-items: end;
  }
 
 #createUser{
   margin-left: 30px;
   box-shadow: 0px 0px 10px red;
   border-top-width: 5px;
   border-bottom-width: 5px;
   border-left-width: 5px;
   border-right-width: 5px;
   border-color: green;
  }
 
 #createUser:hover{
   background: linear-gradient(
   45deg,
   rgb(251, 94, 51),
   rgb(192, 93, 251),
   rgb(180, 40, 200)
   );
   box-shadow: 0px 0px 10px black;
  }
 
 #send{
   box-shadow: 0px 0px 15px black;
   border-top-width: 5px;
   border-bottom-width: 5px;
   border-left-width: 5px;
   border-right-width: 5px;
   width: 450px;
  }
 
 #send:hover{
   border-color: green;
   box-shadow: 0px 0px 15px green;
  }
  
 #messege{
   margin: 10px;
 }

}

EOF


echo "=========================================="
echo "Creating friends.js ...."
echo "=========================================="
cat << 'EOF' > public/friends.js

document.addEventListener('DOMContentLoaded', () => {
  const userNameInput = document.getElementById('userName');
  const createUserBtn = document.getElementById('createUser');
  const onlineSpan = document.querySelector('#onlineSection span');
  const chatBox = document.getElementById('chat-box');
  const typeMessageTextarea = document.getElementById('typeMessege');
  const sendBtn = document.getElementById('send');

  let currentUser = '';

  function scrollToBottom() {
    chatBox.scrollTop = chatBox.scrollHeight;
  }

  // --- 1. Fetch Chat Logs ---
  async function fetchMessages() {
    try {
      const response = await fetch('/get-messages');
      const data = await response.json();

      if (data.success) {
        chatBox.innerHTML = '';
        data.logs.forEach(log => {
          const isSelf = log.username === currentUser;
          appendMessageUI(log.username, log.message, log.time, isSelf);
        });
      }
    } catch (err) {
      console.error('Error fetching chat logs:', err);
    }
  }

  // --- 2. Fetch Online Users ---
  async function fetchOnlineUsers() {
    try {
      const response = await fetch('/get-online-users');
      const data = await response.json();

      if (data.success) {
        onlineSpan.textContent = data.users.length > 0 ? data.users.join(', ') : 'None';
      }
    } catch (err) {
      console.error('Error fetching online users:', err);
    }
  }

  // --- 3. Render Message UI ---
  function appendMessageUI(sender, messageText, time, isSelf) {
    const msgContainer = document.createElement('div');
    msgContainer.style.display = 'flex';
    msgContainer.style.flexDirection = 'column';
    msgContainer.style.alignItems = isSelf ? 'flex-end' : 'flex-start';
    msgContainer.style.marginBottom = '12px';

    const msgBubble = document.createElement('div');
    msgBubble.style.maxWidth = '70%';
    msgBubble.style.padding = '10px 14px';
    msgBubble.style.borderRadius = '12px';
    msgBubble.style.wordBreak = 'break-word';
    msgBubble.style.boxShadow = '0 1px 3px rgba(0,0,0,0.1)';
    msgBubble.style.backgroundColor = isSelf ? '#3182ce' : '#edf2f7';
    msgBubble.style.color = isSelf ? '#ffffff' : '#2d3748';

    const header = document.createElement('strong');
    header.style.fontSize = '0.8em';
    header.style.display = 'block';
    header.style.marginBottom = '4px';
    header.textContent = isSelf ? 'You' : sender;

    const body = document.createElement('span');
    body.textContent = messageText;

    const timeStamp = document.createElement('small');
    timeStamp.style.display = 'block';
    timeStamp.style.textAlign = 'right';
    timeStamp.style.fontSize = '0.7em';
    timeStamp.style.marginTop = '4px';
    timeStamp.style.opacity = '0.75';
    timeStamp.textContent = time || new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });

    msgBubble.appendChild(header);
    msgBubble.appendChild(body);
    msgBubble.appendChild(timeStamp);
    msgContainer.appendChild(msgBubble);

    chatBox.appendChild(msgContainer);
    scrollToBottom();
  }

  // --- 4. User Login Handler ---
  createUserBtn.addEventListener('click', async () => {
    const name = userNameInput.value.trim();

    if (!name) {
      alert('Please enter your name!');
      return;
    }

    try {
      const response = await fetch('/login-user', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ username: name })
      });

      const data = await response.json();

      if (data.success) {
        currentUser = name;
        userNameInput.disabled = true;
        createUserBtn.disabled = true;
        createUserBtn.textContent = 'User Active';
        createUserBtn.style.opacity = '0.6';

        fetchOnlineUsers();
        fetchMessages();
      } else {
        alert('Failed to register user: ' + data.error);
      }
    } catch (err) {
      console.error('Error logging in user:', err);
      alert('Server error connecting to MariaDB!');
    }
  });

  // --- 5. Send Message Handler ---
  async function sendMessage() {
    if (!currentUser) {
      alert('Please click "Create User" first!');
      return;
    }

    const messageText = typeMessageTextarea.value.trim();
    if (!messageText) return;

    try {
      const response = await fetch('/update-html', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          username: currentUser,
          message: messageText
        })
      });

      const data = await response.json();

      if (data.success) {
        typeMessageTextarea.value = '';
        fetchMessages();
      } else {
        alert('Error saving message: ' + data.error);
      }
    } catch (err) {
      console.error('Error sending message:', err);
    }
  }

  sendBtn.addEventListener('click', sendMessage);

  typeMessageTextarea.addEventListener('keydown', (e) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      sendMessage();
    }
  });

  // Initial fetch and auto-polling every 2 seconds
  fetchMessages();
  fetchOnlineUsers();

  setInterval(() => {
    fetchMessages();
    fetchOnlineUsers();
  }, 2000);
});

EOF


echo "=========================================="
echo "Creating LocalHost Command ....."
echo "=========================================="
cat << 'EOF' > $PREFIX/bin/Lstart
mysqld_safe --datadir=$PREFIX/var/lib/mysql & 
sleep 4
node $HOME/Friends-Talk/index.js
EOF
chmod +x $PREFIX/bin/Lstart
echo "=========================================="
echo "CMD :- Lstart"
echo "=========================================="

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

cd 

# --Adding image to Friends-Talk/public---
mv nature2.jpeg $HOME/Friends-Talk/public
echo "=========================================="
echo "Moving Nature2.jpeg successful"
echo "=========================================="

# --- Password Setup Prompt ---
echo "=========================================="
echo "      SECURE CHAT SERVER SETUP            "
echo "=========================================="
read -p "Set your Termux MariaDB Database Password: " DB_PASS
# Create the hidden environment file cleanly
cat << EOF > .env
DB_PASSWORD=${DB_PASS}
EOF
echo "=========================================="
echo "$DB_PASS"
echo "=========================================="

echo "=================================================="
echo "Setup complete! Type 'server' to start everything."
echo "=================================================="
echo "------- You have to install Mariadb manualy ------"
