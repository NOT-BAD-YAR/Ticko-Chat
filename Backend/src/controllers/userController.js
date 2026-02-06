const User = require('../models/User');

const allUsers = async (req, res) => {
    const keyword = req.query.search
        ? {
            $or: [
                { fullName: { $regex: req.query.search, $options: 'i' } },
                { email: { $regex: req.query.search, $options: 'i' } },
            ],
        }
        : {};

    const users = await User.find(keyword).find({ _id: { $ne: req.user._id } }).select('-password');
    res.send(users);
};

module.exports = { allUsers };
