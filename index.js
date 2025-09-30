const express = require('express');
const mysql = require('mysql2');
const dotenv = require('dotenv');
const bodyParser = require('body-parser');
const cors = require('cors');

dotenv.config();
const app = express();

app.use(cors());
app.use(bodyParser.json());

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
      [name, email, password, role, 0], // default not verified
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

      // Role check
      if (user.role !== role) {
        return res.status(403).json({
          success: false,
          message: `You are not registered as a ${role.toUpperCase()}.`,
        });
      }

      // Verification check
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
           is_verified, created_at,
           'admin' AS table_name
    FROM admin
    UNION ALL
    SELECT user_id AS id, name, email,
           COALESCE(role, 'user') AS role,
           COALESCE(status, 'pending') AS status,
           is_verified, created_at,
           'user' AS table_name
    FROM user
    UNION ALL
    SELECT owner_id AS id, name, email,
           COALESCE(role, 'owner') AS role,
           COALESCE(status, 'pending') AS status,
           is_verified, created_at,
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




// ✅ VERIFY USER (set is_verified = TRUE depending on role)
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

// ❌ REJECT USER (Delete from correct table)
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



app.listen(3000, '0.0.0.0', () => {
  console.log('🚀 Server running at http://0.0.0.0:3000');
});
