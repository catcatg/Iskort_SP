const dotenv = require('dotenv');
dotenv.config({ path: __dirname + '/.env' });  // force load from root
console.log("EMAIL_FROM raw:", process.env.EMAIL_FROM);

const express = require('express');
const mysql = require('mysql2');

const sgMail = require('@sendgrid/mail');
sgMail.setApiKey(process.env.SENDGRID_API_KEY);
console.log("SENDGRID KEY EXISTS:", process.env.SENDGRID_API_KEY ? "YES" : "NO");
console.log("EMAIL_FROM:", process.env.EMAIL_FROM);

const axios = require('axios');

const bodyParser = require('body-parser');
const cors = require('cors');
const multer = require('multer');
const path = require('path');

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
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  user: process.env.DB_USER,
  password: process.env.DB_PASS,
  database: process.env.DB_NAME,
  ssl: {
    // Railway requires SSL, but self-signed certs need this flag
    rejectUnauthorized: false
  }
});

db.connect((err) => {
  if (err) {
    console.error('MySQL connection failed:', err.message);
  } else {
    console.log('Connected to Railway MySQL successfully!');
  }
});

// ===== BUSINESS VERIFICATION NOTIFICATIONS =====
const sendBusinessVerificationEmail = async (email, ownerName, businessName, type) => {
  const msg = {
    to: email,
    from: process.env.EMAIL_FROM,
    subject: `Your ${type} has been verified!`,
    html: `<p>Hi ${ownerName},</p>
           <p>Admin verified your ${type} "<b>${businessName}</b>".</p>
           <p>You can edit details in your Profile → Edit Business.</p>`
  };
  try { 
    await sgMail.send(msg); 
    console.log(`${type} verification email sent to`, email); 
  } catch (err) { 
    console.error(`Error sending ${type} verification email:`, err); 
  }
};

// ===== REGISTER (All roles register under admin first) =====
app.post('/api/admin/register', (req, res) => {
  const { name, email, password, role, phone_num, notif_preference } = req.body;

  db.query('SELECT * FROM admin WHERE email = ?', [email], (err, results) => {
    if (err) return res.status(500).json({ success: false, error: err.message });
    if (results.length > 0)
      return res.status(409).json({ success: false, message: 'Email already exists' });

    db.query(
      `INSERT INTO admin 
       (name, email, password, role, is_verified, phone_num, notif_preference, status, created_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, 'pending', NOW())`,
      [name, email, password, role, 0, phone_num, notif_preference || 'email'],
      (err2) => {
        if (err2) return res.status(500).json({ success: false, error: err2.message });
        res.status(201).json({
          success: true,
          message: 'Registration successful. Waiting for admin verification.',
        });
      }
    );
  });
});


// ===== LOGIN (Auto Role Detection) =====
app.post('/api/admin/login', (req, res) => {
  const { email, password } = req.body;

  db.query(
    'SELECT * FROM admin WHERE email = ? AND password = ?',
    [email, password],
    (err, results) => {
      if (err) 
        return res.status(500).json({ success: false, error: err.message });

      if (results.length === 0)
        return res.status(401).json({ success: false, message: 'Invalid credentials' });

      const user = results[0];

      if (!user.is_verified)
        return res.status(403).json({
          success: false,
          message: 'Your account is not verified yet by admin.',
        });

      return res.json({
        success: true,
        message: 'Login successful',
        user: {
          admin_id: user.admin_id,
          name: user.name,
          email: user.email,
          role: user.role,       // IMPORTANT
          phone_num: user.phone_num,
        },
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
    if (err) return res.status(500).json({ success: false, error: err.message });
    res.json({ success: true, users: results });
  });
});

// ===== SEND VERIFICATION SMS =====
const sendVerificationSMS = async (phoneNum, name) => {
  if (!phoneNum) return; // skip if no phone number

  const message = `Hi ${name}, your Iskort account has been verified! You can now log in.`;

  try {
    const res = await axios.post('https://api.semaphore.co/api/v4/messages', null, {
      params: {
        apikey: process.env.SEMAPHORE_API_KEY, // add this in your .env
        number: phoneNum,
        message: message,
        sendername: "Iskort", //placeholder since name application is pending
      }
    });
    console.log('Verification SMS sent to', phoneNum, res.data);
  } catch (err) {
    console.error('Error sending verification SMS:', err.response?.data || err.message);
  }
};

// ===== VERIFY ACCOUNT WITH EMAIL + SMS (Based on notif_preference) =====
app.put('/api/admin/verify/:id', (req, res) => {
  const { id } = req.params;

  db.query(`UPDATE admin SET is_verified = TRUE, status = 'verified' WHERE admin_id = ?`, [id], (err) => {
    if (err) return res.status(500).json({ success: false, error: err.message });

    db.query('SELECT * FROM admin WHERE admin_id = ?', [id], (err2, results) => {
      if (err2) return res.status(500).json({ success: false, error: err2.message });
      if (results.length === 0) return res.status(404).json({ success: false, message: 'User not found' });

      const user = results[0];

      // EMAIL FUNCTION (unchanged)
      const sendVerificationEmail = async (email, name) => {
        const msg = {
          to: email,
          from: process.env.EMAIL_FROM,
          subject: 'Your Iskort Account is Verified!',
          html: `<p>Hi ${name},</p><p>Your account has been successfully verified by the admin. You can now log in and start using Iskort!</p>`
        };
        try { await sgMail.send(msg); console.log('Verification email sent to', email); }
        catch (err) { console.error('Error sending verification email:', err); }
      };

      // If USER or OWNER → copy to their table
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
            user.created_at
          ],
          async (err3) => {
            if (err3) return res.status(500).json({ success: false, error: err3.message });

            // 🔥 SEND NOTIFICATIONS BASED ON PREFERENCE
            if (user.notif_preference === 'sms') {
              await sendVerificationSMS(user.phone_num, user.name);
            } else if (user.notif_preference === 'email') {
              await sendVerificationEmail(user.email, user.name);
            } else if (user.notif_preference === 'both') {
              await sendVerificationEmail(user.email, user.name);
              await sendVerificationSMS(user.phone_num, user.name);
            }

            return res.json({
              success: true,
              message: `${user.role} verified, copied, and notifications sent`
            });
          }
        );
      } else {
        // ADMIN
        (async () => {
          if (user.notif_preference === 'sms') {
            await sendVerificationSMS(user.phone_num, user.name);
          } else if (user.notif_preference === 'email') {
            await sendVerificationEmail(user.email, user.name);
          } else if (user.notif_preference === 'both') {
            await sendVerificationEmail(user.email, user.name);
            await sendVerificationSMS(user.phone_num, user.name);
          }

          return res.json({
            success: true,
            message: `Admin verified and notifications sent`
          });
        })();
      }
    });
  });
});

// ===== TEST EMAIL =====
app.get('/api/test-email', async (req, res) => {
  try {
  const msg = {
  to: process.env.EMAIL_FROM, // send to yourself for testing
  from: process.env.EMAIL_FROM,
  subject: 'Test Email from Iskort',
  text: 'Hello! This is a test email from your Iskort backend.',
  html: '<b>Hello! This is a test email from your Iskort backend.</b>',
  };

  await sgMail.send(msg);
  console.log('Test email sent to', process.env.EMAIL_FROM);
  res.json({ success: true, message: 'Test email sent' });

  } catch (err) {
  console.error('Test email error: ', err);
  res.status(500).json({ success: false, error: err.message });
  }
});

// ===== REJECT ACCOUNT WITH EMAIL NOTIFICATION =====
app.delete('/api/admin/reject/:id', (req, res) => {
const { id } = req.params;


db.query('SELECT * FROM admin WHERE admin_id = ?', [id], (err, results) => {
if (err) return res.status(500).json({ success: false, error: err.message });
if (results.length === 0) return res.status(404).json({ success: false, message: 'User not found' });


    const user = results[0];

    const sendRejectionEmail = async (email, name) => {
    const msg = {
    to: email,
    from: process.env.EMAIL_FROM,
    subject: 'Your Iskort Account Registration',
    html: `<p>Hi ${name},</p><p>We’re sorry to inform you that your account registration has been rejected by the admin.</p>`
    };
    try { await sgMail.send(msg); console.log('Rejection email sent to', email); }
    catch (err) { console.error('Error sending rejection email:', err); }
    };


    db.query('DELETE FROM admin WHERE admin_id = ?', [id], (err2) => {
    if (err2) return res.status(500).json({ success: false, error: err2.message });


    (async () => {
      await sendRejectionEmail(user.email, user.name);
        res.json({ success: true, message: `${user.role} rejected, deleted, and email sent` });
        })();
        });
      });
});

// ===== EATERY ROUTES (with JOIN) =====
app.post('/api/eatery', (req, res) => {
  const {
    owner_id, name, location, min_price = null, is_verified = 0,
    verified_by_admin_id = null, verified_time = null, eatery_photo = '',
    open_time, end_time,
    about_desc = '',   // NEW
    status = 'Open for tenants' // NEW default
  } = req.body;

  const sql = `INSERT INTO eatery 
    (owner_id, name, location, min_price, is_verified, verified_by_admin_id, verified_time, eatery_photo, open_time, end_time, about_desc, status) 
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`;

  db.query(sql, [owner_id, name, location, min_price, is_verified, verified_by_admin_id, verified_time, eatery_photo, open_time, end_time, about_desc, status], (err, result) => {
    if (err) return res.status(500).json({ success: false, error: err.message });
    res.json({ success: true, eatery_id: result.insertId });
  });
});

// GET EATERIES WITH OWNER INFO
app.get('/api/eatery', (req, res) => {
  const sql = `
    SELECT e.*, o.name AS owner_name, o.email AS owner_email, o.phone_num AS owner_phone
    FROM eatery e
    LEFT JOIN owner o ON e.owner_id = o.owner_id
  `;
  db.query(sql, (err, results) => {
    if (err) return res.status(500).json({ success: false, error: err.message });
    res.json({ success: true, eateries: results });
  });
});

// Update eatery
app.put('/api/eatery/:id', (req, res) => {
  const { id } = req.params;
  const { name, location, open_time, end_time, about_desc, status } = req.body;

  const sql = `UPDATE eatery SET name=?, location=?, open_time=?, end_time=?, about_desc=?, status=? WHERE eatery_id=?`;
  db.query(sql, [name, location, open_time, end_time, about_desc, status, id], (err, result) => {
    if (err) return res.status(500).json({ success: false, error: err.message });
    if (result.affectedRows === 0) return res.status(404).json({ success: false, message: 'Eatery not found' });
    res.json({ success: true, message: 'Eatery updated successfully' });
  });
});

//VERIFY EATERY
app.put('/api/admin/verify/eatery/:id', (req, res) => {
  const { id } = req.params;

  db.query('UPDATE eatery SET is_verified = 1, verified_time = NOW() WHERE eatery_id = ?', [id], (err) => {
    if (err) return res.status(500).json({ success: false, error: err.message });

    const sql = `
      SELECT e.*, o.name AS owner_name, o.email AS owner_email, o.phone_num AS owner_phone, o.notif_preference
      FROM eatery e
      LEFT JOIN owner o ON e.owner_id = o.owner_id
      WHERE e.eatery_id = ?`;
    db.query(sql, [id], async (err2, results) => {
      if (err2) return res.status(500).json({ success: false, error: err2.message });
      if (results.length === 0) return res.status(404).json({ success: false, message: 'Eatery not found' });

      const eatery = results[0];
      const ownerName = eatery.owner_name;
      const ownerEmail = eatery.owner_email;
      const ownerPhone = eatery.owner_phone;
      const notifPref = eatery.notif_preference;
      const businessName = eatery.name;

      // 🔹 Email function scoped inside the route
      const sendEateryVerificationEmail = async () => {
        const msg = {
          to: ownerEmail,
          from: process.env.EMAIL_FROM,
          subject: `Your eatery has been verified!`,
          html: `<p>Hi ${ownerName},</p>
                 <p>Admin verified your eatery "<b>${businessName}</b>".</p>
                 <p>You can edit details in your Profile → Edit Business.</p>`
        };
        try { await sgMail.send(msg); console.log('Eatery verification email sent to', ownerEmail); }
        catch (err) { console.error('Error sending eatery verification email:', err); }
      };

      // 🔹 SMS function scoped inside the route
      const sendEateryVerificationSMS = async () => {
        if (!ownerPhone) return;
        const message = `Hi ${ownerName}, your eatery "${businessName}" has been verified. Edit details in Profile → Edit Business.`;
        try {
          const resp = await axios.post('https://api.semaphore.co/api/v4/messages', null, {
            params: { apikey: process.env.SEMAPHORE_API_KEY, number: ownerPhone, message }
          });
          console.log('Eatery verification SMS sent to', ownerPhone, resp.data);
        } catch (err) {
          console.error('Error sending eatery verification SMS:', err.response?.data || err.message);
        }
      };

      // 🔹 Send based on preference
      if (notifPref === 'sms') {
        await sendEateryVerificationSMS();
      } else if (notifPref === 'email') {
        await sendEateryVerificationEmail();
      } else if (notifPref === 'both') {
        await sendEateryVerificationEmail();
        await sendEateryVerificationSMS();
      }

      res.json({ success: true, message: 'Eatery verified and owner notified', eatery });
    });
  });
});

//REJECT EATERY
app.delete('/api/admin/reject/eatery/:id', (req, res) => {
  const { id } = req.params;

  const sql = `
    SELECT e.*, o.name AS owner_name, o.email AS owner_email, o.phone_num AS owner_phone, o.notif_preference
    FROM eatery e
    LEFT JOIN owner o ON e.owner_id = o.owner_id
    WHERE e.eatery_id = ?`;

  db.query(sql, [id], async (err, results) => {
    if (err) return res.status(500).json({ success: false, error: err.message });
    if (results.length === 0) return res.status(404).json({ success: false, message: 'Eatery not found' });

    const eatery = results[0];
    const ownerName = eatery.owner_name;
    const ownerEmail = eatery.owner_email;
    const ownerPhone = eatery.owner_phone;
    const notifPref = eatery.notif_preference;
    const businessName = eatery.name;

    // 🔹 Email function scoped inside
    const sendEateryRejectionEmail = async () => {
      const msg = {
        to: ownerEmail,
        from: process.env.EMAIL_FROM,
        subject: `Your eatery was rejected`,
        html: `<p>Hi ${ownerName},</p>
               <p>We’re sorry to inform you that your eatery "<b>${businessName}</b>" was rejected by the admin.</p>
               <p>You may reapply or contact support for clarification.</p>`
      };
      try { await sgMail.send(msg); console.log('Eatery rejection email sent to', ownerEmail); }
      catch (err) { console.error('Error sending eatery rejection email:', err); }
    };

    // 🔹 SMS function scoped inside
    const sendEateryRejectionSMS = async () => {
      if (!ownerPhone) return;
      const message = `Hi ${ownerName}, your eatery "${businessName}" was rejected by admin.`;
      try {
        const resp = await axios.post('https://api.semaphore.co/api/v4/messages', null, {
          params: { apikey: process.env.SEMAPHORE_API_KEY, number: ownerPhone, message }
        });
        console.log('Eatery rejection SMS sent to', ownerPhone, resp.data);
      } catch (err) {
        console.error('Error sending eatery rejection SMS:', err.response?.data || err.message);
      }
    };

    // 🔹 Send based on preference
    if (notifPref === 'sms') {
      await sendEateryRejectionSMS();
    } else if (notifPref === 'email') {
      await sendEateryRejectionEmail();
    } else if (notifPref === 'both') {
      await sendEateryRejectionEmail();
      await sendEateryRejectionSMS();
    }

    // Delete after notifying
    db.query('DELETE FROM eatery WHERE eatery_id = ?', [id], (err2) => {
      if (err2) return res.status(500).json({ success: false, error: err2.message });
      res.json({ success: true, message: 'Eatery rejected, deleted, and owner notified' });
    });
  });
});

// ===== HOUSING ROUTES (with JOIN) =====
app.post('/api/housing', (req, res) => {
  const {
    owner_id, name, location, price = null, curfew = null, housing_photo = '',
    is_verified = 0, verified_by_admin_id = null, verified_time = null,
    about_desc = '',   // NEW
    status = 'Open for tenants' // NEW default
  } = req.body;

  const sql = `INSERT INTO housing 
    (owner_id, name, location, price, curfew, housing_photo, is_verified, verified_by_admin_id, verified_time, about_desc, status) 
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`;

  db.query(sql, [owner_id, name, location, price, curfew, housing_photo, is_verified, verified_by_admin_id, verified_time, about_desc, status], (err, result) => {
    if (err) return res.status(500).json({ success: false, error: err.message });
    res.json({ success: true, housing_id: result.insertId });
  });
});

// 🔹 UPDATED GET HOUSINGS WITH OWNER INFO
app.get('/api/housing', (req, res) => {
  const sql = `
    SELECT h.*, o.name AS owner_name, o.email AS owner_email, o.phone_num AS owner_phone
    FROM housing h
    LEFT JOIN owner o ON h.owner_id = o.owner_id
  `;
  db.query(sql, (err, results) => {
    if (err) return res.status(500).json({ success: false, error: err.message });
    res.json({ success: true, housings: results });
  });
});

// Update housing
app.put('/api/housing/:id', (req, res) => {
  const { id } = req.params;
  const { name, location, price, curfew, about_desc, status } = req.body;

  const sql = `UPDATE housing SET name=?, location=?, price=?, curfew=?, about_desc=?, status=? WHERE housing_id=?`;
  db.query(sql, [name, location, price, curfew, about_desc, status, id], (err, result) => {
    if (err) return res.status(500).json({ success: false, error: err.message });
    if (result.affectedRows === 0) return res.status(404).json({ success: false, message: 'Housing not found' });
    res.json({ success: true, message: 'Housing updated successfully' });
  });
});

// ===== VERIFY HOUSING =====
app.put('/api/admin/verify/housing/:id', (req, res) => {
  const { id } = req.params;

  db.query('UPDATE housing SET is_verified = 1, verified_time = NOW() WHERE housing_id = ?', [id], (err) => {
    if (err) return res.status(500).json({ success: false, error: err.message });

    const sql = `
      SELECT h.*, o.name AS owner_name, o.email AS owner_email, o.phone_num AS owner_phone, o.notif_preference
      FROM housing h
      LEFT JOIN owner o ON h.owner_id = o.owner_id
      WHERE h.housing_id = ?`;
    db.query(sql, [id], async (err2, results) => {
      if (err2) return res.status(500).json({ success: false, error: err2.message });
      if (results.length === 0) return res.status(404).json({ success: false, message: 'Housing not found' });

      const housing = results[0];
      const ownerName = housing.owner_name;
      const ownerEmail = housing.owner_email;
      const ownerPhone = housing.owner_phone;
      const notifPref = housing.notif_preference;
      const businessName = housing.name;

      const sendHousingVerificationEmail = async () => {
        const msg = {
          to: ownerEmail,
          from: process.env.EMAIL_FROM,
          subject: `Your housing has been verified!`,
          html: `<p>Hi ${ownerName},</p>
                 <p>Admin verified your housing "<b>${businessName}</b>".</p>
                 <p>You can edit details in your Profile → Edit Business.</p>`
        };
        try { await sgMail.send(msg); console.log('Housing verification email sent to', ownerEmail); }
        catch (err) { console.error('Error sending housing verification email:', err); }
      };

      const sendHousingVerificationSMS = async () => {
        if (!ownerPhone) return;
        const message = `Hi ${ownerName}, your housing "${businessName}" has been verified. Edit details in Profile → Edit Business.`;
        try {
          const resp = await axios.post('https://api.semaphore.co/api/v4/messages', null, {
            params: { apikey: process.env.SEMAPHORE_API_KEY, number: ownerPhone, message }
          });
          console.log('Housing verification SMS sent to', ownerPhone, resp.data);
        } catch (err) {
          console.error('Error sending housing verification SMS:', err.response?.data || err.message);
        }
      };

      if (notifPref === 'sms') {
        await sendHousingVerificationSMS();
      } else if (notifPref === 'email') {
        await sendHousingVerificationEmail();
      } else if (notifPref === 'both') {
        await sendHousingVerificationEmail();
        await sendHousingVerificationSMS();
      }

      res.json({ success: true, message: 'Housing verified and owner notified', housing });
    });
  });
});

// ===== REJECT HOUSING =====
app.delete('/api/admin/reject/housing/:id', (req, res) => {
  const { id } = req.params;

  const sql = `
    SELECT h.*, o.name AS owner_name, o.email AS owner_email, o.phone_num AS owner_phone, o.notif_preference
    FROM housing h
    LEFT JOIN owner o ON h.owner_id = o.owner_id
    WHERE h.housing_id = ?`;

  db.query(sql, [id], async (err, results) => {
    if (err) return res.status(500).json({ success: false, error: err.message });
    if (results.length === 0) return res.status(404).json({ success: false, message: 'Housing not found' });

    const housing = results[0];
    const ownerName = housing.owner_name;
    const ownerEmail = housing.owner_email;
    const ownerPhone = housing.owner_phone;
    const notifPref = housing.notif_preference;
    const businessName = housing.name;

    const sendHousingRejectionEmail = async () => {
      const msg = {
        to: ownerEmail,
        from: process.env.EMAIL_FROM,
        subject: `Your housing was rejected`,
        html: `<p>Hi ${ownerName},</p>
               <p>We’re sorry to inform you that your housing "<b>${businessName}</b>" was rejected by the admin.</p>
               <p>You may reapply or contact support for clarification.</p>`
      };
      try { await sgMail.send(msg); console.log('Housing rejection email sent to', ownerEmail); }
      catch (err) { console.error('Error sending housing rejection email:', err); }
    };

    const sendHousingRejectionSMS = async () => {
      if (!ownerPhone) return;
      const message = `Hi ${ownerName}, your housing "${businessName}" was rejected by admin.`;
      try {
        const resp = await axios.post('https://api.semaphore.co/api/v4/messages', null, {
          params: { apikey: process.env.SEMAPHORE_API_KEY, number: ownerPhone, message }
        });
        console.log('Housing rejection SMS sent to', ownerPhone, resp.data);
      } catch (err) {
        console.error('Error sending housing rejection SMS:', err.response?.data || err.message);
      }
    };

    if (notifPref === 'sms') {
      await sendHousingRejectionSMS();
    } else if (notifPref === 'email') {
      await sendHousingRejectionEmail();
    } else if (notifPref === 'both') {
      await sendHousingRejectionEmail();
      await sendHousingRejectionSMS();
    }

    db.query('DELETE FROM housing WHERE housing_id = ?', [id], (err2) => {
      if (err2) return res.status(500).json({ success: false, error: err2.message });
      res.json({ success: true, message: 'Housing rejected, deleted, and owner notified' });
    });
  });
});

// ===== FOOD ROUTES =====
app.post('/api/food', (req, res) => {
  const { name, eatery_id, classification, price, food_pic } = req.body;
  const sql = `INSERT INTO food (name, eatery_id, classification, price, food_pic) VALUES (?, ?, ?, ?, ?)`; 
  db.query(sql, [name, eatery_id, classification, price, food_pic], (err, result) => {
    if (err) return res.status(500).json({ success: false, error: err.message });
    res.json({ success: true, food_id: result.insertId });
  });
});

app.get('/api/food/:eatery_id', (req, res) => {
  const { eatery_id } = req.params;
  const sql = `SELECT * FROM food WHERE eatery_id = ?`; 
  db.query(sql, [eatery_id], (err, results) => {
    if (err) return res.status(500).json({ success: false, error: err.message });
    res.json({ success: true, foods: results });
  });
});

app.put('/api/food/:food_id', (req, res) => {
  const { food_id } = req.params;
  const { name, eatery_id, classification, price, food_pic } = req.body;

  if (!eatery_id) {
    return res.status(400).json({ success: false, message: 'eatery_id is required' });
  }

  const sql = `
    UPDATE food
    SET name = ?, eatery_id = ?, classification = ?, price = ?, food_pic = ?
    WHERE food_id = ?
  `;

  db.query(sql, [name, eatery_id, classification, price, food_pic, food_id], (err, result) => {
    if (err) return res.status(500).json({ success: false, error: err.message });
    if (result.affectedRows === 0) {
      return res.status(404).json({ success: false, message: 'Food not found' });
    }
    res.json({ success: true, message: 'Food updated successfully' });
  });
});

// Delete food
app.delete('/api/food/:food_id', (req, res) => {
  const { food_id } = req.params;

  db.query(
    'DELETE FROM food WHERE food_id = ?',
    [food_id],
    (err, result) => {
      if (err) {
        return res.status(500).json({
          success: false,
          message: 'Database error while deleting food.',
          error: err.message
        });
      }

      // Check if the row actually existed
      if (result.affectedRows === 0) {
        return res.status(404).json({
          success: false,
          message: 'Food item not found. No deletion performed.'
        });
      }

      res.json({
        success: true,
        message: 'Food deleted successfully.'
      });
    }
  );
});


// ===== FACILITY ROUTES =====
// Create facility
app.post('/api/facility', (req, res) => {
  const {
    name,
    housing_id,
    facility_pic,
    price,
    has_ac,
    has_cr,
    type,
    has_kitchen,
    additional_info
  } = req.body;

  const sql = `
    INSERT INTO facility 
    (name, housing_id, facility_pic, price, has_ac, has_cr, type, has_kitchen, additional_info)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
  `;
  db.query(sql, [name, housing_id, facility_pic, price, has_ac, has_cr, type, has_kitchen, additional_info], (err, result) => {
    if (err) return res.status(500).json({ success: false, error: err.message });
    res.json({ success: true, facility_id: result.insertId });
  });
});

// Get facilities by housing_id
app.get('/api/facility/:housing_id', (req, res) => {
  const { housing_id } = req.params;
  const sql = `SELECT * FROM facility WHERE housing_id = ?`;
  db.query(sql, [housing_id], (err, results) => {
    if (err) return res.status(500).json({ success: false, error: err.message });
    res.json({ success: true, facilities: results });
  });
});

// Update facility
app.put('/api/facility/:facility_id', (req, res) => {
  const { facility_id } = req.params;
  const {
    name,
    housing_id,
    facility_pic,
    price,
    has_ac,
    has_cr,
    type,
    has_kitchen,
    additional_info
  } = req.body;

  const sql = `
    UPDATE facility
    SET name=?, housing_id=?, facility_pic=?, price=?, has_ac=?, has_cr=?, type=?, has_kitchen=?, additional_info=?
    WHERE facility_id=?
  `;
  db.query(sql, [name, housing_id, facility_pic, price, has_ac, has_cr, type, has_kitchen, additional_info, facility_id], (err, result) => {
    if (err) return res.status(500).json({ success: false, error: err.message });
    if (result.affectedRows === 0) return res.status(404).json({ success: false, message: 'Facility not found' });
    res.json({ success: true, message: 'Facility updated successfully' });
  });
});

// Delete facility
app.delete('/api/facility/:facility_id', (req, res) => {
  const { facility_id } = req.params;

  db.query(
    'DELETE FROM facility WHERE facility_id = ?',
    [facility_id],
    (err, result) => {
      if (err) {
        return res.status(500).json({
          success: false,
          message: 'Database error while deleting facility.',
          error: err.message
        });
      }

      // result.affectedRows tells if a row was deleted
      if (result.affectedRows === 0) {
        return res.status(404).json({
          success: false,
          message: 'Facility not found. No deletion performed.'
        });
      }

      res.json({
        success: true,
        message: 'Facility deleted successfully.'
      });
    }
  );
});

// ===== OWNER ROUTES =====
app.get('/api/owner', (req, res) => {
  const sql = `SELECT owner_id AS id, name, email, phone_num, notif_preference, created_at FROM owner`;
  db.query(sql, (err, results) => {
    if (err) return res.status(500).json({ success: false, error: err.message });
    res.json({ success: true, owners: results });
  });
});

app.get('/api/owner/:id', (req, res) => {
  const { id } = req.params;
  const sql = `SELECT owner_id AS id, name, email, phone_num, notif_preference, created_at FROM owner WHERE owner_id = ?`;
  db.query(sql, [id], (err, results) => {
    if (err) return res.status(500).json({ success: false, error: err.message });
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
