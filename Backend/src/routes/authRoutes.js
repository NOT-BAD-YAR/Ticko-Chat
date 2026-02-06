const express = require('express');
const router = express.Router();
const { signup, login, getMe, forgotPassword, resetPassword, updateProfile } = require('../controllers/authController');
const { protect } = require('../middlewares/authMiddleware');
const upload = require('../middlewares/uploadMiddleware');

router.post('/signup', upload.single('profilePic'), signup);
router.post('/login', login);
router.post('/forgotpassword', forgotPassword);
router.post('/resetpassword', resetPassword);
router.get('/me', protect, getMe);
router.put('/update', protect, updateProfile);

module.exports = router;
