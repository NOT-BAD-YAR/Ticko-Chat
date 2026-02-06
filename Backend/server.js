require('dotenv').config();
const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const mongoose = require('mongoose');
const cors = require('cors');

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
    cors: {
        origin: "*", // Allow all origins for development
        methods: ["GET", "POST", "PUT", "DELETE"],
        allowedHeaders: ["Content-Type", "Authorization"],
        credentials: true
    }
});

// Middlewares
const connectDB = require('./src/config/db');

// Middlewares
app.use(cors());
app.use(express.json());

// Database Connection
connectDB();

// Routes
app.use('/api/auth', require('./src/routes/authRoutes'));
app.use('/api/chat', require('./src/routes/chatRoutes'));
app.use('/api/message', require('./src/routes/messageRoutes'));
app.use('/api/user', require('./src/routes/userRoutes'));
app.use('/api/upload', require('./src/routes/uploadRoutes'));


// Basic Route
app.get('/', (req, res) => {
    res.send('Ticko Chat Backend Running');
});

// Socket.io Connection
// Socket.io Connection
require('./src/utils/socketHandler')(io);

const PORT = process.env.PORT || 5000;

server.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});
