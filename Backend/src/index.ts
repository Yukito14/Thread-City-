import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import * as dotenv from 'dotenv';
import { createServer } from 'http';

import authRoutes from './routes/authRoutes.js';
import postRoutes from './routes/postRoutes.js';
import userRoutes from './routes/userRoutes.js';
import searchRoutes from './routes/searchRoutes.js';
import notificationRoutes from './routes/notification.routes.js';
import messageRoutes from './routes/messageRoutes.js';

import { initSocket } from './socket.js';

dotenv.config();

const app = express();

app.use((req, res, next) => {
  console.log(`[REQ] ${req.method} ${req.originalUrl}`);
  next();
});

app.use(helmet());
app.use(cors());
app.use(morgan('dev'));
app.use(express.json());

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/posts', postRoutes);
app.use('/api/users', userRoutes);
app.use('/api/search', searchRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/messages', messageRoutes);

// API kiểm tra trạng thái Server
app.get('/', (req, res) => {
  res.send('Welcome to Thread City API! 🚀 Server is running.');
});

const PORT = process.env.PORT || 3000;

const server = createServer(app);

initSocket(server);

server.listen(Number(PORT), '0.0.0.0', () => {
  console.log(`🚀 Server is running on http://0.0.0.0:${PORT}`);
});