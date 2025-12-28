console.log("✅ Using unified yehey /api/admin/register route");
// ===== Imports & Config =====
const dotenv = require('dotenv');
dotenv.config({ path: __dirname + '/.env' });

const express = require('express');
const mysql = require('mysql2');
const sgMail = require('@sendgrid/mail');
const axios = require('axios');
const bodyParser = require('body-parser');
const cors = require('cors');
const multer = require('multer');
const path = require('path');
const crypto = require('crypto');

sgMail.setApiKey(process.env.SENDGRID_API_KEY);
console.log("SENDGRID KEY EXISTS:", process.env.SENDGRID_API_KEY ? "YES" : "NO");
console.log("EMAIL_FROM:", process.env.EMAIL_FROM);

const app = express();
app.use(cors());
app.use(bodyParser.json());

// Static uploads
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Multer setup
const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, 'uploads/'),
  filename: (req, file, cb) => cb(null, Date.now() + path.extname(file.originalname)),
});
const upload = multer({ storage });

// ===== MySQL connection (Railway) =====
const db = mysql.createConnection({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  user: process.env.DB_USER,
  password: process.env.DB_PASS,
  database: process.env.DB_NAME,
  ssl: { rejectUnauthorized: false }
});

db.connect((err) => {
  if (err) {
    console.error('MySQL connection failed:', err.message);
  } else {
    console.log('Connected to Railway MySQL successfully!');
  }
});

// ===== Notification Helpers =====
const sendEmail = async ({ to, subject, html }) => {
  const msg = { to, from: process.env.EMAIL_FROM, subject, html };
  try {
    await sgMail.send(msg);
    console.log('Email sent to', to, subject);
  } catch (err) {
    console.error('Error sending email:', err);
  }
};

const sendSMS = async ({ number, message, sendername = "Iskort" }) => {
  if (!number) return;
  try {
    const res = await axios.post('https://api.semaphore.co/api/v4/messages', null, {
      params: {
        apikey: process.env.SEMAPHORE_API_KEY,
        number,
        message,
        sendername,
      }
    });
    console.log('SMS sent to', number, res.data);
  } catch (err) {
    console.error('Error sending SMS:', err.response?.data || err.message);
  }
};

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
  console.log('🔥 NEW REGISTER ENDPOINT HIT 🔥');
  const { name, email, password, role, phone_num, notif_preference } = req.body;

  if (!role) {
    return res.status(400).json({ success: false, message: 'Role is required' });
  }

  db.query(
    'SELECT admin_id FROM admin WHERE email = ?',
    [email],
    async (err, dup) => {
      if (err) return res.status(500).json({ success: false, error: err.message });
      if (dup.length > 0) {
        return res.status(409).json({ success: false, message: 'Email already exists' });
      }

      const normalizedRole = role.toLowerCase();
      const status =
        normalizedRole === 'user' ? 'pending_email' : 'pending_admin';

      db.query(
        `INSERT INTO admin 
         (name, email, password, role, phone_num, notif_preference, status, is_verified, created_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, 0, NOW())`,
        [name, email, password, normalizedRole, phone_num, notif_preference || 'email', status],
        async (err2, result) => {
          if (err2) {
            return res.status(500).json({ success: false, error: err2.message });
          }

          // USER → self email verification
          if (normalizedRole === 'user') {
            const token = require('crypto').randomBytes(32).toString('hex');
            const expires = new Date(Date.now() + 24 * 60 * 60 * 1000);

            db.query(
              `UPDATE admin 
               SET email_verification_token = ?, email_verification_expires = ?
               WHERE admin_id = ?`,
              [token, expires, result.insertId]
            );

            const link = `${process.env.FRONTEND_URL}/verify-email/${token}`;

            await sgMail.send({
              to: email,
              from: process.env.EMAIL_FROM,
              subject: 'Verify your Iskort account',
              html: `<p>Hi ${name},</p>
                     <p>Click <a href="${link}">here</a> to verify your account.</p>
                     <p>This link expires in 24 hours.</p>`
            });

            console.log('REGISTER FLOW → email_verification');
            return res.json({
              success: true,
              flow: 'email_verification'
            });
          }

          // OWNER / ADMIN → admin approval
          console.log('REGISTER FLOW → admin_approval');
          return res.json({
            success: true,
            flow: 'admin_approval'
          });
        }
      );
    }
  );
});

// Email token for users
app.get('/api/admin/verify-email/:token', (req, res) => {
  const { token } = req.params;

  db.query(
    `SELECT * FROM admin 
     WHERE email_verification_token = ?
     AND email_verification_expires > NOW()
     AND role = 'user'`,
    [token],
    (err, results) => {
      if (err) return res.status(500).send('Server error');
      if (results.length === 0) {
        return res.status(400).send('Invalid or expired verification link.');
      }

      const u = results[0];

      db.query(
        `UPDATE admin 
         SET is_verified = 1,
             status = 'verified',
             email_verification_token = NULL,
             email_verification_expires = NULL
         WHERE admin_id = ?`,
        [u.admin_id],
        (err2) => {
          if (err2) return res.status(500).send('Verification failed');

          db.query(
            `INSERT INTO user
             (name, email, password, role, status, is_verified, notif_preference, created_at)
             VALUES (?, ?, ?, 'user', 'verified', 1, ?, NOW())`,
            [u.name, u.email, u.password, u.notif_preference],
            (err3) => {
              if (err3) return res.status(500).send('User creation failed');
              res.send('Email verified. You may now log in.');
            }
          );
        }
      );
    }
  );
});


app.post('/api/admin/send-verification', (req, res) => {
  const { email } = req.body;

  db.query('SELECT * FROM admin WHERE email=? AND role="user"', [email], (err, results) => {
    if (err) return res.status(500).json({ success: false, error: err.message });
    if (results.length === 0) return res.status(404).json({ success: false, message: 'User not found' });

    const user = results[0];
    const token = crypto.randomBytes(32).toString('hex');
    const expires = new Date(Date.now() + 24 * 60 * 60 * 1000);

    db.query(
      `UPDATE admin SET email_verification_token=?, email_verification_expires=? WHERE admin_id=?`,
      [token, expires, user.admin_id],
      async (err2) => {
        if (err2) return res.status(500).json({ success: false, error: err2.message });

        const link = `${process.env.FRONTEND_URL}/verify-email/${token}`;

        await sendEmail({
          to: email,
          subject: 'Verify your Iskort account',
          html: `<p>Hi ${user.name},</p>
                 <p>Click <a href="${link}">this link</a> to verify your account. It expires in 24 hours.</p>`
        });

        res.json({ success: true, message: 'Verification email sent' });
      }
    );
  });
});

// ===== Admin: Get all users for dashboard (no action buttons for user) =====
app.get('/api/admin/users', (req, res) => {
  const query = `
    SELECT owner_id AS id, name, email, phone_num, notif_preference,
           'owner' AS role, COALESCE(status, 'pending') AS status,
           COALESCE(is_verified, 0) AS is_verified, created_at,
           'owner' AS table_name
    FROM owner
    UNION ALL
    SELECT user_id AS id, name, email, NULL AS phone_num, 'email' AS notif_preference,
           'user' AS role, COALESCE(status, 'pending') AS status,
           COALESCE(is_verified, 0) AS is_verified, created_at,
           'user' AS table_name
    FROM user
    UNION ALL
    SELECT admin_id AS id, name, email, phone_num, notif_preference,
           COALESCE(role, 'admin') AS role, COALESCE(status, 'pending') AS status,
           COALESCE(is_verified, 0) AS is_verified, created_at,
           'admin' AS table_name
    FROM admin
  `;
  db.query(query, (err, results) => {
    if (err) return res.status(500).json({ success: false, error: err.message });
    res.json({ success: true, users: results });
  });
});

// ===== Admin: Verify Owner (send notifications per preference) =====
app.put('/api/admin/verify/owner/:id', (req, res) => {
  const { id } = req.params;

  db.query('SELECT * FROM admin WHERE admin_id = ? AND role = "owner"', [id], (err, results) => {
    if (err) return res.status(500).json({ success: false, error: err.message });
    if (results.length === 0) return res.status(404).json({ success: false, message: 'Owner not found' });

    const owner = results[0];

    db.query(
      `UPDATE admin SET is_verified = 1, status = 'verified' WHERE admin_id = ?`,
      [id],
      (err2) => {
        if (err2) return res.status(500).json({ success: false, error: err2.message });

        // Copy to owner table
        db.query(
          `INSERT INTO owner (name, email, password, role, phone_num, notif_preference, status, is_verified, created_at)
           VALUES (?, ?, ?, 'owner', ?, ?, 'verified', 1, NOW())`,
          [owner.name, owner.email, owner.password, owner.phone_num, owner.notif_preference],
          async (err3) => {
            if (err3) return res.status(500).json({ success: false, error: err3.message });

            // Send notifications
            if (owner.notif_preference === 'email') {
              await sendEmail({ to: owner.email, subject: 'Your Iskort Owner Account is Verified!', html: `<p>Hi ${owner.name},</p><p>Your owner account has been verified by the admin.</p>` });
            } else if (owner.notif_preference === 'sms') {
              await sendSMS({ number: owner.phone_num, message: 'Your owner account has been verified. You can now log in.' });
            } else if (owner.notif_preference === 'both') {
              await sendEmail({ to: owner.email, subject: 'Your Iskort Owner Account is Verified!', html: `<p>Hi ${owner.name},</p><p>Your owner account has been verified by the admin.</p>` });
              await sendSMS({ number: owner.phone_num, message: 'Your owner account has been verified. You can now log in.' });
            }

            res.json({ success: true, message: 'Owner verified and notifications sent' });
          }
        );
      }
    );
  });
});

// ===== Admin: Reject Owner (notify via email) =====
app.delete('/api/admin/reject/owner/:id', (req, res) => {
  const { id } = req.params;

  db.query('SELECT * FROM owner WHERE owner_id = ?', [id], async (err, results) => {
    if (err) return res.status(500).json({ success: false, error: err.message });
    if (results.length === 0) return res.status(404).json({ success: false, message: 'Owner not found' });

    const owner = results[0];

    db.query('DELETE FROM owner WHERE owner_id = ?', [id], async (err2) => {
      if (err2) return res.status(500).json({ success: false, error: err2.message });

      await sendEmail({
        to: owner.email,
        subject: 'Your Iskort Owner Registration',
        html: `<p>Hi ${owner.name},</p><p>Your owner registration was rejected by the admin.</p>`
      });

      res.json({ success: true, message: 'Owner rejected, deleted, and email sent' });
    });
  });
});

// ===== Admin Login (optional, keep your existing if needed) =====
app.post('/api/admin/login', (req, res) => {
  const { email, password } = req.body;
  db.query('SELECT * FROM admin WHERE email = ? AND password = ?', [email, password], (err, results) => {
    if (err) return res.status(500).json({ success: false, error: err.message });
    if (results.length === 0) return res.status(401).json({ success: false, message: 'Invalid credentials' });

    const admin = results[0];
    if (!admin.is_verified) {
      return res.status(403).json({ success: false, message: 'Your account is not verified yet by admin.' });
    }

    res.json({
      success: true,
      message: 'Login successful',
      user: {
        admin_id: admin.admin_id,
        name: admin.name,
        email: admin.email,
        role: admin.role,
        phone_num: admin.phone_num,
      },
    });
  });
});

// ===== User Login (requires email verification) =====
app.post('/api/user/login', (req, res) => {
  const { email, password } = req.body;

  db.query(
    'SELECT * FROM user WHERE email = ? AND password = ?',
    [email, password],
    (err, results) => {
      if (err) return res.status(500).json({ success: false, error: err.message });
      if (results.length === 0) return res.status(401).json({ success: false, message: 'Invalid credentials' });

      const user = results[0];
      if (!user.is_verified) {
        return res.status(403).json({ success: false, message: 'Please verify your email to log in.' });
      }

      res.json({
        success: true,
        message: 'Login successful',
        user: {
          user_id: user.user_id,
          name: user.name,
          email: user.email,
          role: user.role,
        }
      });
    }
  );
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


// ===== EATERY ROUTE =====
app.post('/api/eatery', (req, res) => {
  const {
    owner_id, name, location, min_price = null, is_verified = 0,
    verified_by_admin_id = null, verified_time = null,
    eatery_photo = '',
    valid_id_base64 = '',
    business_permit_base64 = '',
    dti_certificate_base64 = '',
    health_permit_base64 = '',
    open_time, end_time,
    about_desc = '',
    status = 'Open for tenants'
  } = req.body;

  const sql = `INSERT INTO eatery 
    (owner_id, name, location, min_price, is_verified, verified_by_admin_id, verified_time,
     eatery_photo, valid_id_base64, business_permit_base64, dti_certificate_base64, health_permit_base64,
     open_time, end_time, about_desc, status) 
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`;

  db.query(sql, [
    owner_id, name, location, min_price, is_verified, verified_by_admin_id, verified_time,
    eatery_photo, valid_id_base64, business_permit_base64, dti_certificate_base64, health_permit_base64,
    open_time, end_time, about_desc, status
  ], (err, result) => {
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

// UPDATE EATERY
app.put('/api/eatery/:eatery_id', (req, res) => {
  const eatery_id = req.params.eatery_id;
  const updates = req.body;

  db.query(
    "SELECT is_verified FROM eatery WHERE eatery_id = ?",
    [eatery_id],
    (err, rows) => {
      if (err) return res.status(500).json({ success: false, error: err.message });
      if (rows.length === 0)
        return res.status(404).json({ success: false, message: "Eatery not found" });

      if (rows[0].is_verified !== 1) {
        return res.status(403).json({
          success: false,
          message: "Eatery is NOT verified. Editing is not allowed."
        });
      }

      const allowedFields = [
        "name",
        "location",
        "price_range",
        "owner_name",
        "owner_email",
        "owner_phone",
        "about_desc",
        "open_time",
        "end_time",
        "curfew",
        "status",
        "eatery_photo"
      ];

      const fields = [];
      const values = [];

      for (const key of allowedFields) {
        if (updates[key] !== undefined) {
          fields.push(`${key} = ?`);
          values.push(updates[key]);
        }
      }

      if (fields.length === 0) {
        return res.status(400).json({
          success: false,
          message: "No valid fields provided"
        });
      }

      values.push(eatery_id);

      // 3. Perform update
      db.query(
        `UPDATE eatery SET ${fields.join(", ")} WHERE eatery_id = ?`,
        values,
        (err) => {
          if (err) return res.status(500).json({ success: false, error: err.message });

          return res.json({
            success: true,
            message: "Eatery updated successfully"
          });
        }
      );
    }
  );
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

// ===== HOUSING ROUTE =====
app.post('/api/housing', (req, res) => {
  const {
    owner_id, name, location, price = null, curfew = null,
    housing_photo = '',
    valid_id_base64 = '',
    proof_of_ownership_base64 = '',
    is_verified = 0, verified_by_admin_id = null, verified_time = null,
    about_desc = '',
    status = 'Open for tenants'
  } = req.body;

  const sql = `INSERT INTO housing 
    (owner_id, name, location, price, curfew,
     housing_photo, valid_id_base64, proof_of_ownership_base64,
     is_verified, verified_by_admin_id, verified_time, about_desc, status) 
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`;

  db.query(sql, [
    owner_id, name, location, price, curfew,
    housing_photo, valid_id_base64, proof_of_ownership_base64,
    is_verified, verified_by_admin_id, verified_time, about_desc, status
  ], (err, result) => {
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

// UPDATE HOUSING
app.put('/api/housing/:housing_id', (req, res) => {
  const housing_id = req.params.housing_id;
  const updates = req.body;

  db.query(
    "SELECT is_verified FROM housing WHERE housing_id = ?",
    [housing_id],
    (err, rows) => {
      if (err) return res.status(500).json({ success: false, error: err.message });
      if (rows.length === 0)
        return res.status(404).json({ success: false, message: "Housing not found" });

      if (rows[0].is_verified !== 1) {
        return res.status(403).json({
          success: false,
          message: "Housing is NOT verified. Editing is not allowed."
        });
      }

      // 2. Build update fields dynamically
      const allowedFields = [
        "name",
        "location",
        "owner_name",
        "owner_email",
        "owner_phone",
        "about_desc",
        "curfew",
        "status",
        "housing_photo",
        "price_range"
      ];

      const fields = [];
      const values = [];

      for (const key of allowedFields) {
        if (updates[key] !== undefined) {
          fields.push(`${key} = ?`);
          values.push(updates[key]);
        }
      }

      if (fields.length === 0) {
        return res.status(400).json({
          success: false,
          message: "No valid fields provided"
        });
      }

      values.push(housing_id);

      // 3. Perform update
      db.query(
        `UPDATE housing SET ${fields.join(", ")} WHERE housing_id = ?`,
        values,
        (err) => {
          if (err) return res.status(500).json({ success: false, error: err.message });

          return res.json({
            success: true,
            message: "Housing updated successfully"
          });
        }
      );
    }
  );
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
  const { name, eatery_id, classification, price, food_pic, availability } = req.body;
  const sql = `INSERT INTO food (name, eatery_id, classification, price, food_pic, availability) VALUES (?, ?, ?, ?, ?, ?)`; 
  db.query(sql, [name, eatery_id, classification, price, food_pic, availability], (err, result) => {
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
  const { name, eatery_id, classification, price, food_pic, availability } = req.body;

  if (!eatery_id) {
    return res.status(400).json({ success: false, message: 'eatery_id is required' });
  }

  const sql = `
    UPDATE food
    SET name = ?, eatery_id = ?, classification = ?, price = ?, food_pic = ?, availability = ?
    WHERE food_id = ?
  `;

  db.query(sql, [name, eatery_id, classification, price, food_pic, availability, food_id], (err, result) => {
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
    additional_info,
    availability, avail_room
  } = req.body;

  const sql = `
    INSERT INTO facility 
    (name, housing_id, facility_pic, price, has_ac, has_cr, type, has_kitchen, additional_info, availability, avail_room)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `;

  db.query(sql, [name, housing_id, facility_pic, price, has_ac, has_cr, type, has_kitchen, additional_info, availability, avail_room], (err, result) => {
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
    additional_info, 
    availability, 
    avail_room
  } = req.body;

  const sql = `
    UPDATE facility
    SET name=?, housing_id=?, facility_pic=?, price=?, has_ac=?, has_cr=?, type=?, has_kitchen=?, additional_info=?, availability=?, avail_room=?
    WHERE facility_id=?
  `;
  db.query(sql, [name, housing_id, facility_pic, price, has_ac, has_cr, type, has_kitchen, additional_info, availability, avail_room, facility_id], (err, result) => {
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

app.post('/api/eatery_reviews', (req, res) => {
  const { user_id, eatery_id, rating, comment } = req.body;
  const sql = `INSERT INTO eatery_reviews (user_id, eatery_id, rating, comment, created_at)
               VALUES (?, ?, ?, ?, NOW())`;
  db.query(sql, [user_id, eatery_id, rating, comment], (err, result) => {
    if (err) return res.status(500).json({ success: false, error: err.message });
    res.json({ success: true, review_id: result.insertId });
  });
});

// Getting reviews from user
app.get('/api/user/:id/reviews', (req, res) => {
  const { id } = req.params;
  const sql = `
    SELECT r.review_id, r.user_id, r.eatery_id AS place_id, r.rating, r.comment, r.created_at,
           e.name AS place_name, 'eatery' AS type
    FROM eatery_reviews r
    JOIN eatery e ON r.eatery_id = e.eatery_id
    WHERE r.user_id = ?
    UNION ALL
    SELECT r.review_id, r.user_id, r.housing_id AS place_id, r.rating, r.comment, r.created_at,
           h.name AS place_name, 'housing' AS type
    FROM housing_reviews r
    JOIN housing h ON r.housing_id = h.housing_id
    WHERE r.user_id = ?
    ORDER BY created_at DESC
  `;
  db.query(sql, [id, id], (err, results) => {
    if (err) return res.status(500).json({ success: false, error: err.message });
    res.json({ success: true, reviews: results });
  });
});

// Eatery reviews
app.post('/api/eatery_reviews', (req, res) => {
  const { user_id, eatery_id, rating, comment } = req.body;
  const sql = `INSERT INTO eatery_reviews (user_id, eatery_id, rating, comment, created_at)
               VALUES (?, ?, ?, ?, NOW())`;
  db.query(sql, [user_id, eatery_id, rating, comment], (err, result) => {
    if (err) return res.status(500).json({ success: false, error: err.message });
    res.json({ success: true, review_id: result.insertId });
  });
});

// Housing review
app.post('/api/housing_reviews', (req, res) => {
  const { user_id, housing_id, rating, comment } = req.body;
  const sql = `INSERT INTO housing_reviews (user_id, housing_id, rating, comment, created_at)
               VALUES (?, ?, ?, ?, NOW())`;
  db.query(sql, [user_id, housing_id, rating, comment], (err, result) => {
    if (err) return res.status(500).json({ success: false, error: err.message });
    res.json({ success: true, review_id: result.insertId });
  });
});

// Edit an eatery review
app.put('/api/eatery_reviews/:id', (req, res) => {
  const { id } = req.params;
  const { rating, comment } = req.body;

  // Optional validation
  if (rating < 1 || rating > 5) {
    return res.status(400).json({ success: false, message: 'Rating must be between 1 and 5' });
  }

  const sql = `UPDATE eatery_reviews SET rating = ?, comment = ? WHERE review_id = ?`;
  db.query(sql, [rating, comment, id], (err, result) => {
    if (err) return res.status(500).json({ success: false, error: err.message });
    if (result.affectedRows === 0) {
      return res.status(404).json({ success: false, message: 'Review not found' });
    }
    res.json({ success: true, message: 'Eatery review updated successfully' });
  });
});

// Delete an eatery review
app.delete('/api/eatery_reviews/:id', (req, res) => {
  const { id } = req.params;

  const sql = `DELETE FROM eatery_reviews WHERE review_id = ?`;
  db.query(sql, [id], (err, result) => {
    if (err) return res.status(500).json({ success: false, error: err.message });
    if (result.affectedRows === 0) {
      return res.status(404).json({ success: false, message: 'Review not found' });
    }
    res.json({ success: true, message: 'Eatery review deleted successfully' });
  });
});


// Edit a housing review
app.put('/api/housing_reviews/:id', (req, res) => {
  const { id } = req.params;
  const { rating, comment } = req.body;

  if (rating < 1 || rating > 5) {
    return res.status(400).json({ success: false, message: 'Rating must be between 1 and 5' });
  }

  const sql = `UPDATE housing_reviews SET rating = ?, comment = ? WHERE review_id = ?`;
  db.query(sql, [rating, comment, id], (err, result) => {
    if (err) return res.status(500).json({ success: false, error: err.message });
    if (result.affectedRows === 0) {
      return res.status(404).json({ success: false, message: 'Review not found' });
    }
    res.json({ success: true, message: 'Housing review updated successfully' });
  });
});

// Delete a housing review
app.delete('/api/housing_reviews/:id', (req, res) => {
  const { id } = req.params;

  const sql = `DELETE FROM housing_reviews WHERE review_id = ?`;
  db.query(sql, [id], (err, result) => {
    if (err) return res.status(500).json({ success: false, error: err.message });
    if (result.affectedRows === 0) {
      return res.status(404).json({ success: false, message: 'Review not found' });
    }
    res.json({ success: true, message: 'Housing review deleted successfully' });
  });
});

// Get all reviews for an establishment
app.get('/api/eatery_reviews/:eateryId', (req, res) => {
  const { eateryId } = req.params;
  const sql = `
    SELECT er.*, u.username 
    FROM eatery_reviews er 
    JOIN users u ON er.user_id = u.user_id 
    WHERE er.eatery_id = ? 
    ORDER BY er.created_at DESC
  `;
  
  db.query(sql, [eateryId], (err, result) => {
    if (err) return res.status(500).json({ success: false, error: err.message });
    res.json({ success: true, reviews: result });
  });
});

app.get('/api/housing_reviews/:housingId', (req, res) => {
  const { housingId } = req.params;
  const sql = `
    SELECT hr.*, u.username 
    FROM housing_reviews hr 
    JOIN users u ON hr.user_id = u.user_id 
    WHERE hr.housing_id = ? 
    ORDER BY hr.created_at DESC
  `;
  
  db.query(sql, [housingId], (err, result) => {
    if (err) return res.status(500).json({ success: false, error: err.message });
    res.json({ success: true, reviews: result });
  });
});

// ===== Test Email =====
app.get('/api/test-email', async (req, res) => {
  try {
    await sendEmail({
      to: process.env.EMAIL_FROM,
      subject: 'Test Email from Iskort',
      html: '<b>Hello! This is a test email from your Iskort backend.</b>'
    });
    res.json({ success: true, message: 'Test email sent' });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// ===== Base Route =====
app.get('/', (req, res) => {
  res.send('Iskort API is live and ready for use!');
});

// ===== Listen =====
const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on port ${PORT}`);
});
