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
    console.error('MySQL connection failed:', err);
    return;
  }
  console.log('Connected to MySQL');
});


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

      res.json({
        success: true,
        message: 'Login successful',
        user,
      });
    }
  );
});


app.post('/api/admin/register', (req, res) => {
  const { name, email, password, role } = req.body;

  db.query(
    'SELECT * FROM admin WHERE email = ?',
    [email],
    (err, results) => {
      if (err) return res.status(500).json({ error: err });
      if (results.length > 0) {
        return res.status(409).json({ message: 'Email already exists' });
      }

      db.query(
        'INSERT INTO admin (name, email, password, role) VALUES (?, ?, ?, ?)',
        [name, email, password, role],
        (err, result) => {
          if (err) return res.status(500).json({ error: err });
          res.json({ success: true, message: 'Admin registered successfully' });
        }
      );
    }
  );
});


app.listen(3000, '0.0.0.0', () => {
  console.log('Server running at http://0.0.0.0:3000 (accessible over network)');
});

