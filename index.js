const express = require('express');
const mysql = require('mysql2');
const dotenv = require('dotenv');
const bodyParser = require('body-parser');
const cors = require('cors');
const multer = require('multer');
const path = require('path');

dotenv.config();
const app = express();

const allowedOrigins = [
'[https://iskort-public-web.onrender.com](https://iskort-public-web.onrender.com)',
'[https://iskort-frontend.web.app](https://iskort-frontend.web.app)',
];

app.use(cors({
origin: function (origin, callback) {
if (!origin || origin.includes('localhost') || allowedOrigins.includes(origin)) {
callback(null, true);
} else {
console.warn(`CORS blocked request from: ${origin}`);
callback(new Error('Not allowed by CORS'));
}
},
methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
allowedHeaders: ['Content-Type', 'Authorization'],
credentials: true,
}));
app.options('*', cors());

app.use(bodyParser.json());

// Multer setup for file uploads
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));
const storage = multer.diskStorage({
destination: (req, file, cb) => cb(null, 'uploads/'),
filename: (req, file, cb) => cb(null, Date.now() + path.extname(file.originalname)),
});
const upload = multer({ storage });

// MySQL connection
const db = mysql.createConnection({
host: process.env.DB_HOST || 'switchyard.proxy.rlwy.net',
user: process.env.DB_USER || 'root',
password: process.env.DB_PASSWORD || 'nkAzvuvCsuhTymYgnMhwCTsqYqHlUBHX',
database: process.env.DB_NAME || 'railway',
port: process.env.DB_PORT || 43301,
});

db.connect((err) => {
if (err) console.error('MySQL connection failed:', err);
else console.log('Connected to Railway MySQL successfully!');
});

// ===== SIGNUP ROUTE =====
app.post('/api/register', (req, res) => {
const { role, name, email, password, phone_num, notif_preference } = req.body;
let table;

if (role === 'admin') table = 'admin';
else if (role === 'owner') table = 'owner';
else if (role === 'user') table = 'user';
else return res.status(400).json({ message: 'Invalid role' });

// Check if email exists
db.query(`SELECT * FROM ${table} WHERE email = ?`, [email], (err, results) => {
if (err) return res.status(500).json({ error: err });
if (results.length > 0) return res.status(409).json({ message: 'Email already exists' });

// Insert into the correct table
const query = `
  INSERT INTO ${table} 
    (name, email, password, role, is_verified, phone_num, notif_preference)
  VALUES (?, ?, ?, ?, ?, ?, ?)
`;

db.query(query, [name, email, password, role, 0, phone_num, notif_preference], (err, result) => {
  if (err) return res.status(500).json({ error: err });
  res.status(201).json({ message: `${role} registered successfully` });
});

// ===== LOGIN ROUTES =====
app.post('/api/admin/login', (req, res) => {
  const { email, password, role } = req.body;

  db.query(
    'SELECT * FROM admin WHERE email = ? AND password = ?',
    [email, password],
    (err, results) => {
      if (err) return res.status(500).json({ error: err });
      if (results.length === 0) return res.status(401).json({ message: 'Invalid credentials' });

      const user = results[0];
      if (user.role !== role) return res.status(403).json({ message: `You are not registered as a ${role}` });
      if (!user.is_verified) return res.status(403).json({ message: 'Account not verified yet' });

      res.json({ success: true, message: 'Login successful', user });
    }
  );
});

app.post('/api/user/login', (req, res) => {
  const { email, password } = req.body;

  db.query('SELECT * FROM user WHERE email = ?', [email], (err, results) => {
    if (err) return res.status(500).json({ error: err });
    if (results.length === 0) return res.status(401).json({ message: 'Invalid email or password' });

    const user = results[0];
    if (user.password !== password) return res.status(401).json({ message: 'Invalid email or password' });

    res.json({
      success: true,
      message: 'User login successful',
      data: { id: user.id, name: user.name, email: user.email, role: user.role },
    });
  });
});

app.post('/api/owner/login', (req, res) => {
  const { email, password } = req.body;

  db.query('SELECT * FROM owner WHERE email = ?', [email], (err, results) => {
    if (err) return res.status(500).json({ error: err });
    if (results.length === 0) return res.status(401).json({ message: 'Invalid email or password' });

    const owner = results[0];
    if (owner.password !== password) return res.status(401).json({ message: 'Invalid email or password' });

    res.json({
      success: true,
      message: 'Owner login successful',
      data: { id: owner.id, name: owner.name, email: owner.email, role: owner.role },
    });
  });
});


});
});

// ===== GET ALL USERS (admin view) =====
app.get('/api/admin/users', (req, res) => {
const query = `     SELECT admin_id AS id, name, email, phone_num, notif_preference, COALESCE(role,'admin') AS role,
           COALESCE(status,'pending') AS status, COALESCE(is_verified,0) AS is_verified,
           created_at, 'admin' AS table_name
    FROM admin
    UNION ALL
    SELECT user_id AS id, name, email, phone_num, notif_preference, COALESCE(role,'user') AS role,
           COALESCE(status,'pending') AS status, COALESCE(is_verified,0) AS is_verified,
           created_at, 'user' AS table_name
    FROM user
    UNION ALL
    SELECT owner_id AS id, name, email, phone_num, notif_preference, COALESCE(role,'owner') AS role,
           COALESCE(status,'pending') AS status, COALESCE(is_verified,0) AS is_verified,
           created_at, 'owner' AS table_name
    FROM owner
  `;
db.query(query, (err, results) => {
if (err) return res.status(500).json({ error: err });
res.json({ success: true, users: results });
});
});

// ===== VERIFY / REJECT USERS =====
app.put('/api/admin/verify/:role/:id', (req, res) => {
const { role, id } = req.params;
let table = role === 'admin' ? 'admin' : role === 'user' ? 'user' : role === 'owner' ? 'owner' : null;
if (!table) return res.status(400).json({ message: 'Invalid role' });

db.query(`UPDATE ${table} SET is_verified = TRUE WHERE ${role}_id = ?`, [id], (err) => {
if (err) return res.status(500).json({ error: err });
res.json({ success: true, message: `${role} verified successfully` });
});
});

app.delete('/api/admin/reject/:role/:id', (req, res) => {
const { role, id } = req.params;
let table = role === 'admin' ? 'admin' : role === 'user' ? 'user' : role === 'owner' ? 'owner' : null;
if (!table) return res.status(400).json({ message: 'Invalid role' });

db.query(`DELETE FROM ${table} WHERE ${role}_id = ?`, [id], (err) => {
if (err) return res.status(500).json({ error: err });
res.json({ success: true, message: `${role} rejected and deleted` });
});
});

// ===== Eateries & Foods =====
app.post('/api/eatery', (req, res) => {
const { owner_id, name, location, open_time, end_time } = req.body;
db.query(
'INSERT INTO eatery (owner_id, name, location, open_time, end_time) VALUES (?, ?, ?, ?, ?)',
[owner_id, name, location, open_time, end_time],
(err, result) => {
if (err) return res.status(500).send(err);
res.json({ success: true, eatery_id: result.insertId });
}
);
});

app.post('/api/food', (req, res) => {
const { name, eatery_id, classification, price, photo } = req.body;
db.query(
'INSERT INTO foods (name, eatery_id, classification, price, photo) VALUES (?, ?, ?, ?, ?)',
[name, eatery_id, classification, price, photo],
(err, result) => {
if (err) return res.status(500).send(err);
res.json({ success: true, food_id: result.insertId });
}
);
});

app.get('/api/foods/:eatery_id', (req, res) => {
const { eatery_id } = req.params;
db.query('SELECT * FROM foods WHERE eatery_id = ?', [eatery_id], (err, results) => {
if (err) return res.status(500).send(err);
res.json({ success: true, foods: results });
});
});

app.get('/api/eatery', (req, res) => {
db.query('SELECT * FROM eatery', (err, results) => {
if (err) return res.status(500).json({ error: err });
res.json({ success: true, eateries: results });
});
});

app.get('/', (req, res) => res.send('Iskort API is live!'));

const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => console.log(`Server running on port ${PORT}`));
