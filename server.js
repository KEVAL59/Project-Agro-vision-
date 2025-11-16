const express = require('express');
const fs = require('fs');
const bodyParser = require('body-parser');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(bodyParser.json());

const USERS_FILE = 'users.json';
const PORT = process.env.PORT || 3000;

// Route for checking if the server is running
app.get('/', (req, res) => {
  res.send("Server is running ✔️");
});

// Read users from file
function readUsers() {
  if (!fs.existsSync(USERS_FILE)) return [];
  return JSON.parse(fs.readFileSync(USERS_FILE, 'utf-8'));
}

// Write users to file
function writeUsers(users) {
  fs.writeFileSync(USERS_FILE, JSON.stringify(users, null, 2));
}

// Signup route
app.post('/signup', (req, res) => {
  const { fullName, email, mobile, city, password } = req.body;
  let users = readUsers();

  if (users.find(u => u.email === email || u.mobile === mobile)) {
    return res.status(400).json({ message: 'User already exists' });
  }

  users.push({ fullName, email, mobile, city, password });
  writeUsers(users);
  res.json({ message: 'Signup successful' });
});``````````````

// Login route
app.post('/login', (req, res) => {
  const { credential, password } = req.body;
  const users = readUsers();

  const user = users.find(u =>
    (u.email === credential || u.mobile === credential) &&
    u.password === password
  );

  if (user) {
    res.json({ message: 'Login successful', user });
  } else {
    res.status(401).json({ message: 'Invalid credentials' });
  }
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`✅ Server running on http://0.0.0.0:${PORT}`);
});
