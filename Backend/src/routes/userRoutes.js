const express = require('express');
const { protect } = require('../middlewares/authMiddleware');
const { allUsers } = require('../controllers/userController');

const router = express.Router();

router.route('/').get(protect, allUsers);

module.exports = router;
