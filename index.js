// ===== ISKORT BACKEND =====
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

// Serve static images
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Multer setup for file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, 'uploads/'),
  filename: (req, file, cb) =>
    cb(null, Date.now() + path.extname(file.originalname)),
});
const upload = multer({ storage });

// MySQL connection (Railway)
const db = mysql.createConnection({
  host: process.env.DB_HOST || 'switchyard.proxy.rlwy.net',
  user: process.env.DB_USER || 'root',
  password:
    process.env.DB_PASSWORD || 'nkAzvuvCsuhTymYgnMhwCTsqYqHlUBHX',
  database: process.env.DB_NAME || 'railway',
  port: process.env.DB_PORT || 43301,
});

db.connect((err) => {
  if (err) {
    console.error('MySQL connection failed:', err);
  } else {
    console.log('Connected to Railway MySQL successfully!');
  }
});

// ===== REGISTER (All roles register under admin first) =====
app.post('/api/admin/register', (req, res) => {
  const { name, email, password, role, phone_num, notif_preference } =
    req.body;

  db.query('SELECT * FROM admin WHERE email = ?', [email], (err, results) => {
    if (err) return res.status(500).json({ error: err });
    if (results.length > 0)
      return res.status(409).json({ message: 'Email already exists' });

    db.query(
      `INSERT INTO admin 
       (name, email, password, role, is_verified, phone_num, notif_preference, status, created_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, 'pending', NOW())`,
      [name, email, password, role, 0, phone_num, notif_preference || 'email'],
      (err, result) => {
        if (err) return res.status(500).json({ error: err });
        res.status(201).json({
          success: true,
          message:
            'Registration successful. Waiting for admin verification.',
        });
      }
    );
  });
});

// ===== LOGIN (Admin) =====
app.post('/api/admin/login', (req, res) => {
  const { email, password, role } = req.body;

  db.query(
    'SELECT * FROM admin WHERE email = ? AND password = ?',
    [email, password],
    (err, results) => {
      if (err) return res.status(500).json({ error: err });
      if (results.length === 0)
        return res
          .status(401)
          .json({ success: false, message: 'Invalid credentials' });

      const user = results[0];

      if (user.role !== role)
        return res.status(403).json({
          success: false,
          message: `You are not registered as a ${role.toUpperCase()}.`,
        });

      if (!user.is_verified)
        return res.status(403).json({
          success: false,
          message: 'Your account is not verified yet by admin.',
        });

      res.json({
        success: true,
        message: 'Login successful',
        user,
      });
    }
  );
});

// ===== GET ALL USERS =====
app.get('/api/admin/users', (req, res) => {
  const query = `
    SELECT admin_id AS id, name, email, phone_num, notif_preference,
           COALESCE(role, 'admin') AS role,
           COALESCE(status, 'pending') AS status,
           COALESCE(is_verified, 0) AS is_verified,
           created_at,
           'admin' AS table_name
    FROM admin
    UNION ALL
    SELECT user_id AS id, name, email, phone_num, notif_preference,
           COALESCE(role, 'user') AS role,
           COALESCE(status, 'pending') AS status,
           COALESCE(is_verified, 0) AS is_verified,
           created_at,
           'user' AS table_name
    FROM user
    UNION ALL
    SELECT owner_id AS id, name, email, phone_num, notif_preference,
           COALESCE(role, 'owner') AS role,
           COALESCE(status, 'pending') AS status,
           COALESCE(is_verified, 0) AS is_verified,
           created_at,
           'owner' AS table_name
    FROM owner
  `;

  db.query(query, (err, results) => {
    if (err) return res.status(500).json({ success: false, error: err });
    res.json({ success: true, users: results });
  });
});

// ===== VERIFY ACCOUNT =====
app.put('/api/admin/verify/:id', (req, res) => {
  const { id } = req.params;

  // Mark verified
  db.query(
    `UPDATE admin SET is_verified = TRUE, status = 'verified' WHERE admin_id = ?`,
    [id],
    (err) => {
      if (err) return res.status(500).json({ success: false, error: err });

      // Get the user details to copy
      db.query('SELECT * FROM admin WHERE admin_id = ?', [id], (err, results) => {
        if (err) return res.status(500).json({ success: false, error: err });
        if (results.length === 0)
          return res.status(404).json({ success: false, message: 'User not found' });

        const user = results[0];

        // Copy to the appropriate table based on role
        if (user.role === 'owner' || user.role === 'user') {
          const table = user.role;
          db.query(
            `INSERT INTO ${table} (name, email, password, role, phone_num, is_verified, status, notif_preference, created_at)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
            [
              user.name,
              user.email,
              user.password,
              user.role,
              user.phone_num,
              1,
              'verified',
              user.notif_preference,
              user.created_at,
            ],
            (err2) => {
              if (err2) return res.status(500).json({ success: false, error: err2 });
              console.log(`${user.role} account copied to ${table} table`);
              res.json({
                success: true,
                message: `${user.role} verified and copied successfully`,
              });
            }
          );
        } else {
          res.json({
            success: true,
            message: `Admin account verified successfully (no copy needed)`,
          });
        }
      });
    }
  );
});

// ===== REJECT ACCOUNT =====
app.delete('/api/admin/reject/:id', (req, res) => {
  const { id } = req.params;

  db.query('SELECT * FROM admin WHERE admin_id = ?', [id], (err, results) => {
    if (err) return res.status(500).json({ success: false, error: err });
    if (results.length === 0)
      return res.status(404).json({ success: false, message: 'User not found' });

    const user = results[0];
    db.query('DELETE FROM admin WHERE admin_id = ?', [id], (err2) => {
      if (err2) return res.status(500).json({ success: false, error: err2 });

      console.log(`${user.role} (${user.email}) rejected and removed`);
      res.json({
        success: true,
        message: `${user.role} rejected and deleted`,
      });
    });
  });
});

// ===== EATERY ROUTES =====
app.post('/api/eatery', (req, res) => {
  const { owner_id, name, location, open_time, end_time } = req.body;
  const sql = `INSERT INTO eatery (owner_id, name, location, open_time, end_time) VALUES (?, ?, ?, ?, ?)`;
  db.query(sql, [owner_id, name, location, open_time, end_time], (err, result) => {
    if (err) return res.status(500).send(err);
    res.send({ success: true, eatery_id: result.insertId });
  });
});

app.get('/api/eatery', (req, res) => {
  db.query('SELECT * FROM eatery', (err, results) => {
    if (err) return res.status(500).json({ success: false, error: err });
    res.json({ success: true, eateries: results });
  });
});

// 🔹 Get eatery owner info
app.get('/api/eatery/owner/:owner_id', (req, res) => {
  const { owner_id } = req.params;
  const sql = `SELECT owner_id, name, email, phone_num FROM owner WHERE owner_id = ?`;
  db.query(sql, [owner_id], (err, results) => {
    if (err) return res.status(500).json({ success: false, error: err });
    if (results.length === 0)
      return res.status(404).json({ success: false, message: 'Owner not found' });
    res.json({ success: true, owner: results[0] });
  });
});


// ===== HOUSING ROUTES =====
app.post('/api/housing', (req, res) => {
  const { owner_id, name, address, rent_price, room_count, contact_number } = req.body;
  const sql = `INSERT INTO housing (owner_id, name, address, rent_price, room_count, contact_number) VALUES (?, ?, ?, ?, ?, ?)`;
  db.query(sql, [owner_id, name, address, rent_price, room_count, contact_number], (err, result) => {
    if (err) return res.status(500).send(err);
    res.send({ success: true, housing_id: result.insertId });
  });
});

app.get('/api/housing', (req, res) => {
  db.query('SELECT * FROM housing', (err, results) => {
    if (err) return res.status(500).json({ success: false, error: err });
    res.json({ success: true, housings: results });
  });
});

// 🔹 Get housing owner info
app.get('/api/housing/owner/:owner_id', (req, res) => {
  const { owner_id } = req.params;
  const sql = `SELECT owner_id, name, email, phone_num FROM owner WHERE owner_id = ?`;
  db.query(sql, [owner_id], (err, results) => {
    if (err) return res.status(500).json({ success: false, error: err });
    if (results.length === 0)
      return res.status(404).json({ success: false, message: 'Owner not found' });
    res.json({ success: true, owner: results[0] });
  });
});

// ===== FOOD ROUTES =====
app.post('/api/food', (req, res) => {
  const { name, eatery_id, classification, price, photo } = req.body;
  const sql = `INSERT INTO foods (name, eatery_id, classification, price, photo) VALUES (?, ?, ?, ?, ?)`;
  db.query(sql, [name, eatery_id, classification, price, photo], (err, result) => {
    if (err) return res.status(500).send(err);
    res.send({ success: true, food_id: result.insertId });
  });
});

app.get('/api/foods/:eatery_id', (req, res) => {
  const { eatery_id } = req.params;
  const sql = `SELECT * FROM foods WHERE eatery_id = ?`;
  db.query(sql, [eatery_id], (err, results) => {
    if (err) return res.status(500).send(err);
    res.send({ success: true, foods: results });
  });
});

// ===== OWNER ROUTES =====

// Get ALL owners
app.get('/api/owner', (req, res) => {
  const sql = `SELECT owner_id AS id, name, email, phone_num, notif_preference, created_at FROM owner`;
  db.query(sql, (err, results) => {
    if (err) return res.status(500).json({ success: false, error: err });
    res.json({ success: true, owners: results });
  });
});

// Get ONE owner by ID
app.get('/api/owner/:id', (req, res) => {
  const { id } = req.params;
  const sql = `SELECT owner_id AS id, name, email, phone_num, notif_preference, created_at 
               FROM owner WHERE owner_id = ?`;
  db.query(sql, [id], (err, results) => {
    if (err) return res.status(500).json({ success: false, error: err });
    if (results.length === 0)
      return res.status(404).json({ success: false, message: 'Owner not found' });

    res.json({ success: true, owner: results[0] });
  });
});


// ===== BASE ROUTE =====
app.get('/', (req, res) => {
  res.send('Iskort API is live and ready for use!');
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on port ${PORT}`);
});
