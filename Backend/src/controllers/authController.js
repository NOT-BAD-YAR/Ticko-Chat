const User = require('../models/User');
const generateToken = require('../utils/generateToken');
const { bucket } = require('../config/firebase');
const sendEmail = require('../services/emailService');

// @desc    Register a new user
// @route   POST /api/auth/signup
// @access  Public
const signup = async (req, res) => {
    try {
        const { fullName, email, password } = req.body;

        const userExists = await User.findOne({ email });

        if (userExists) {
            return res.status(400).json({ message: 'User already exists' });
        }

        let profilePic = req.body.profilePic || 'https://via.placeholder.com/150';

        if (req.file && bucket) {
            const fileName = `profile-pics/${Date.now()}_${req.file.originalname}`;
            const file = bucket.file(fileName);

            try {
                await file.save(req.file.buffer, {
                    metadata: { contentType: req.file.mimetype }
                });

                // Get signed URL (valid for a long time)
                const [url] = await file.getSignedUrl({
                    action: 'read',
                    expires: '03-01-2500'
                });
                profilePic = url;
            } catch (uploadError) {
                console.error("Firebase Upload Error:", uploadError);
                // Continue with default image if upload fails
            }
        }

        const user = await User.create({
            fullName,
            email,
            password,
            profilePic
        });

        if (user) {
            res.status(201).json({
                _id: user._id,
                fullName: user.fullName,
                email: user.email,
                profilePic: user.profilePic,
                token: generateToken(user._id),
                theme: user.theme
            });
        } else {
            res.status(400).json({ message: 'Invalid user data' });
        }
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: error.message });
    }
};

// @desc    Auth user & get token
// @route   POST /api/auth/login
// @access  Public
const login = async (req, res) => {
    try {
        const { email, password } = req.body;

        const user = await User.findOne({ email });

        if (user && (await user.matchPassword(password))) {
            res.json({
                _id: user._id,
                fullName: user.fullName,
                email: user.email,
                profilePic: user.profilePic,
                theme: user.theme,
                token: generateToken(user._id),
            });
        } else {
            res.status(401).json({ message: 'Invalid email or password' });
        }
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Get current user profile
// @route   GET /api/auth/me
// @access  Private
const getMe = async (req, res) => {
    const user = await User.findById(req.user._id);

    if (user) {
        res.json({
            _id: user._id,
            fullName: user.fullName,
            email: user.email,
            profilePic: user.profilePic,
            theme: user.theme,
        });
    } else {
        res.status(404).json({ message: 'User not found' });
    }
};

// @desc    Forgot Password - Send OTP
// @route   POST /api/auth/forgotpassword
// @access  Public
const forgotPassword = async (req, res) => {
    try {
        const { email } = req.body;
        const user = await User.findOne({ email });

        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        // Generate 6-digit OTP
        const otp = Math.floor(100000 + Math.random() * 900000).toString();

        // Save OTP to user (valid for 10 mins)
        user.resetPasswordOTP = otp;
        user.resetPasswordExpires = Date.now() + 10 * 60 * 1000;

        await user.save();

        // Send Email
        const emailContent = `
            <h3>Password Reset Request</h3>
            <p>Your password reset code is: <strong>${otp}</strong></p>
            <p>This code expires in 10 minutes.</p>
        `;

        try {
            await sendEmail(user.email, 'Ticko Chat - Password Reset', emailContent);
            res.status(200).json({ message: 'Password reset code sent to email' });
        } catch (emailError) {
            user.resetPasswordOTP = undefined;
            user.resetPasswordExpires = undefined;
            await user.save();
            res.status(500).json({ message: 'Email could not be sent' });
        }

    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Reset Password
// @route   POST /api/auth/resetpassword
// @access  Public
const resetPassword = async (req, res) => {
    try {
        const { email, otp, newPassword } = req.body;
        const user = await User.findOne({
            email,
            resetPasswordOTP: otp,
            resetPasswordExpires: { $gt: Date.now() }
        });

        if (!user) {
            return res.status(400).json({ message: 'Invalid or expired Code' });
        }

        // Set new password (pre-save hook will hash it)
        user.password = newPassword;
        user.resetPasswordOTP = undefined;
        user.resetPasswordExpires = undefined;

        await user.save();

        res.status(200).json({ message: 'Password Reset Successful' });

    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Update user profile
// @route   PUT /api/auth/update
// @access  Private
const updateProfile = async (req, res) => {
    try {
        const user = await User.findById(req.user._id);

        if (user) {
            user.fullName = req.body.fullName || user.fullName;
            user.email = req.body.email || user.email;

            if (req.body.password) {
                user.password = req.body.password;
            }

            if (req.body.profilePic) {
                user.profilePic = req.body.profilePic;
            }

            const updatedUser = await user.save();

            res.json({
                _id: updatedUser._id,
                fullName: updatedUser.fullName,
                email: updatedUser.email,
                profilePic: updatedUser.profilePic,
                theme: updatedUser.theme,
                token: generateToken(updatedUser._id),
            });
        } else {
            res.status(404).json({ message: 'User not found' });
        }
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

module.exports = {
    signup,
    login,
    getMe,
    forgotPassword,
    resetPassword,
    updateProfile
};
