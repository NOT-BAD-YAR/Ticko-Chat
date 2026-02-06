const mongoose = require('mongoose');

const connectDB = async () => {
    try {
        await mongoose.connect(process.env.MONGO_URI);
        console.log('MongoDB Connected');
    } catch (err) {
        console.error('MongoDB Connection Error: ', err.message);
        // process.exit(1); // Don't exit, just log for now to keep server checking
    }
};

module.exports = connectDB;
