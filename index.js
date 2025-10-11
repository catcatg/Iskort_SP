const express = require('express');
const mysql = require('mysql2');
const dotenv = require('dotenv');
const bodyParser = require('body-parser');
const cors = require('cors');
const multer = require('multer');
const path = require('path');

dotenv.config();
const app = express();

app.use(cors());
app.use(bodyParser.json());

// ✅ Serve static images
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// ✅ Multer setup for file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, 'uploads/'),
  filename: (req, file, cb) => cb(null, Date.now() + path.extname(file.originalname)),
});
const upload = multer({ storage });

const db = mysql.createConnection({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASS,
  database: process.env.DB_NAME,
});

db.connect(err => {
  if (err) {
    console.error('❌ MySQL connection failed:', err);
    return;
  }
  console.log('✅ Connected to MySQL');
});

// ======================================================
// 🔑 REGISTER + LOGIN (your existing logic)
// ======================================================

// ✅ REGISTER
app.post('/api/admin/register', (req, res) => {
  const { name, email, password, role } = req.body;

  db.query('SELECT * FROM admin WHERE email = ?', [email], (err, results) => {
    if (err) return res.status(500).json({ error: err });
    if (results.length > 0) {
      return res.status(409).json({ message: 'Email already exists' });
    }

    db.query(
      'INSERT INTO admin (name, email, password, role, is_verified) VALUES (?, ?, ?, ?, ?)',
      [name, email, password, role, 0],
      (err, result) => {
        if (err) return res.status(500).json({ error: err });

        res.status(201).json({
          success: true,
          message: 'Registration successful. Please log in with your new account.',
        });
      }
    );
  });
});

// ✅ LOGIN
app.post('/api/admin/login', (req, res) => {
  const { email, password, role } = req.body;

  db.query(
    'SELECT * FROM admin WHERE email = ? AND password = ?',
    [email, password],
    (err, results) => {
      if (err) return res.status(500).json({ error: err });
      if (results.length === 0) {
        return res.status(401).json({ success: false, message: 'Invalid credentials' });
      }

      const user = results[0];

      if (user.role !== role) {
        return res.status(403).json({
          success: false,
          message: `You are not registered as a ${role.toUpperCase()}.`,
        });
      }

      if (!user.is_verified) {
        return res.status(403).json({
          success: false,
          message: '⏳ Your account is not verified yet by admin.',
        });
      }

      res.json({
        success: true,
        message: 'Login successful',
        user,
      });
    }
  );
});

// ✅ GET ALL USERS (Admin Dashboard: admins + owners + users)
app.get('/api/admin/users', (req, res) => {
  const query = `
    SELECT admin_id AS id, name, email,
           COALESCE(role, 'admin') AS role,
           COALESCE(status, 'pending') AS status,
           COALESCE(is_verified, 0) AS is_verified,
           created_at,
           'admin' AS table_name
    FROM admin
    UNION ALL
    SELECT user_id AS id, name, email,
           COALESCE(role, 'user') AS role,
           COALESCE(status, 'pending') AS status,
           COALESCE(is_verified, 0) AS is_verified,
           created_at,
           'user' AS table_name
    FROM user
    UNION ALL
    SELECT owner_id AS id, name, email,
           COALESCE(role, 'owner') AS role,
           COALESCE(status, 'pending') AS status,
           COALESCE(is_verified, 0) AS is_verified,
           created_at,
           'owner' AS table_name
    FROM owner
  `;

  db.query(query, (err, results) => {
    if (err) return res.status(500).json({ success: false, error: err });
    res.json({
      success: true,
      users: results,
    });
  });
});


// ✅ VERIFY
app.put('/api/admin/verify/:role/:id', (req, res) => {
  const { role, id } = req.params;
  let table;
  if (role === 'admin') table = 'admin';
  else if (role === 'user') table = 'user';
  else if (role === 'owner') table = 'owner';
  else return res.status(400).json({ success: false, message: 'Invalid role' });

  db.query(
    `UPDATE ${table} SET is_verified = TRUE WHERE ${role}_id = ?`,
    [id],
    (err, result) => {
      if (err) return res.status(500).json({ success: false, error: err });
      res.json({ success: true, message: `${role} verified successfully` });
    }
  );
});

// ❌ REJECT
app.delete('/api/admin/reject/:role/:id', (req, res) => {
  const { role, id } = req.params;
  let table;
  if (role === 'admin') table = 'admin';
  else if (role === 'user') table = 'user';
  else if (role === 'owner') table = 'owner';
  else return res.status(400).json({ success: false, message: 'Invalid role' });

  db.query(
    `DELETE FROM ${table} WHERE ${role}_id = ?`,
    [id],
    (err, result) => {
      if (err) return res.status(500).json({ success: false, error: err });
      res.json({ success: true, message: `${role} rejected and deleted` });
    }
  );
});


// Add Eatery
app.post('/api/eatery', (req, res) => {
  const { owner_id, name, location, open_time, end_time } = req.body;
  const sql = `INSERT INTO eateries (owner_id, name, location, open_time, end_time) VALUES (?, ?, ?, ?, ?)`;
  db.query(sql, [owner_id, name, location, open_time, end_time], (err, result) => {
    if (err) return res.status(500).send(err);
    res.send({ success: true, eatery_id: result.insertId });
  });
});

// Add Food
app.post('/api/food', (req, res) => {
  const { name, eatery_id, classification, price, photo } = req.body;
  const sql = `INSERT INTO foods (name, eatery_id, classification, price, photo) VALUES (?, ?, ?, ?, ?)`;
  db.query(sql, [name, eatery_id, classification, price, photo], (err, result) => {
    if (err) return res.status(500).send(err);
    res.send({ success: true, food_id: result.insertId });
  });
});

// Get Foods by Eatery
app.get('/api/foods/:eatery_id', (req, res) => {
  const { eatery_id } = req.params;
  const sql = `SELECT * FROM foods WHERE eatery_id = ?`;
  db.query(sql, [eatery_id], (err, results) => {
    if (err) return res.status(500).send(err);
    res.send({ success: true, foods: results });
  });
});

// ✅ Get all Eateries (for homepage)
app.get('/api/eateries', (req, res) => {
  const sql = `SELECT * FROM eateries`;
  db.query(sql, (err, results) => {
    if (err) {
      console.error("❌ Error fetching eateries:", err);
      return res.status(500).json({ success: false, error: err });
    }
    res.json({ success: true, eateries: results });
  });
});


app.listen(3000, '0.0.0.0', () => {
  console.log('🚀 Server running at http://0.0.0.0:3000');
});
