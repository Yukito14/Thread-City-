const express = require('express');
const mysql = require('mysql2/promise');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const cors = require('cors');
require('dotenv').config();

const app = express();

app.use(cors());
app.use(express.json());

const pool = mysql.createPool({
  host: process.env.DB_HOST,
  port: Number(process.env.DB_PORT),
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  waitForConnections: true,
  connectionLimit: 10,
});

app.get('/', (req, res) => {
  res.json({
    message: 'ThreadCity backend is running',
  });
});

app.post('/auth/register', async (req, res) => {
  try {
    const { username, nickname, email, password } = req.body;

    if (!username || !nickname || !email || !password) {
      return res.status(400).json({
        message: 'Vui lòng nhập đầy đủ thông tin',
      });
    }

    if (password.length < 6) {
      return res.status(400).json({
        message: 'Mật khẩu phải có ít nhất 6 ký tự',
      });
    }

    const [existingUsers] = await pool.query(
      'SELECT id FROM users WHERE username = ? OR email = ?',
      [username, email]
    );

    if (existingUsers.length > 0) {
      return res.status(409).json({
        message: 'Username hoặc email đã tồn tại',
      });
    }

    const passwordHash = await bcrypt.hash(password, 10);

    const avatarUrl =
      `https://api.dicebear.com/7.x/avataaars/png?seed=${encodeURIComponent(username)}`;

    const [result] = await pool.query(
      `INSERT INTO users 
        (username, nickname, email, password_hash, bio, avatar_url) 
       VALUES (?, ?, ?, ?, ?, ?)`,
      [username, nickname, email, passwordHash, '', avatarUrl]
    );

    return res.status(201).json({
      message: 'Đăng ký thành công',
      user: {
        id: result.insertId,
        username,
        nickname,
        email,
        avatarUrl,
      },
    });
  } catch (error) {
    console.error('Register error:', error);
    return res.status(500).json({
      message: 'Lỗi server khi đăng ký',
    });
  }
});

app.post('/auth/login', async (req, res) => {
  try {
    const { usernameOrEmail, password } = req.body;

    if (!usernameOrEmail || !password) {
      return res.status(400).json({
        message: 'Vui lòng nhập username/email và mật khẩu',
      });
    }

    const [users] = await pool.query(
      `SELECT id, username, nickname, email, password_hash, avatar_url
       FROM users
       WHERE username = ? OR email = ?
       LIMIT 1`,
      [usernameOrEmail, usernameOrEmail]
    );

    if (users.length === 0) {
      return res.status(401).json({
        message: 'Tài khoản không tồn tại',
      });
    }

    const user = users[0];

    const isPasswordCorrect = await bcrypt.compare(
      password,
      user.password_hash
    );

    if (!isPasswordCorrect) {
      return res.status(401).json({
        message: 'Mật khẩu không đúng',
      });
    }

    const token = jwt.sign(
      {
        id: user.id,
        username: user.username,
        email: user.email,
      },
      process.env.JWT_SECRET,
      {
        expiresIn: '7d',
      }
    );

    return res.status(200).json({
      message: 'Đăng nhập thành công',
      token,
      user: {
        id: user.id,
        username: user.username,
        nickname: user.nickname,
        email: user.email,
        avatarUrl: user.avatar_url,
      },
    });
  } catch (error) {
    console.error('Login error:', error);
    return res.status(500).json({
      message: 'Lỗi server khi đăng nhập',
    });
  }
});

const port = process.env.PORT || 3000;

app.listen(port, () => {
  console.log(`Server is running at http://localhost:${port}`);
});