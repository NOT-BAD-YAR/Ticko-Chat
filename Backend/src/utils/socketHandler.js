const onlineUsers = new Map(); // Stores userId -> socketId

module.exports = (io) => {
    io.on('connection', (socket) => {
        console.log('Connected to socket.io:', socket.id);

        socket.on('setup', (userData) => {
            if (!userData || !userData._id) return;

            socket.join(userData._id);
            onlineUsers.set(userData._id, socket.id);
            console.log(`User ${userData._id} is online`);

            // Broadcast online users list to everyone
            io.emit('online users', Array.from(onlineUsers.keys()));
            socket.emit('connected');
        });

        socket.on('join chat', (room) => {
            socket.join(room);
            console.log('User Joined Room: ' + room);
        });

        socket.on('typing', (room) => socket.in(room).emit('typing'));
        socket.on('stop typing', (room) => socket.in(room).emit('stop typing'));

        socket.on('new message', (newMessageReceived) => {
            var chat = newMessageReceived.chat;

            if (!chat.users) return console.log('chat.users not defined');

            chat.users.forEach((user) => {
                if (user._id == newMessageReceived.sender._id) return;
                socket.in(user._id).emit('message received', newMessageReceived);
            });
        });

        socket.on('disconnect', () => {
            console.log('USER DISCONNECTED:', socket.id);
            // Remove user from onlineUsers map
            for (let [userId, socketId] of onlineUsers.entries()) {
                if (socketId === socket.id) {
                    onlineUsers.delete(userId);
                    io.emit('online users', Array.from(onlineUsers.keys())); // Update everyone
                    break;
                }
            }
        });

        socket.off('setup', (userData) => {
            console.log('USER LOGGED OUT');
            if (userData && userData._id) {
                socket.leave(userData._id);
                onlineUsers.delete(userData._id);
                io.emit('online users', Array.from(onlineUsers.keys()));
            }
        });
    });
};
