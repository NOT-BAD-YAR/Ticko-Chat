const multer = require('multer');

const storage = multer.memoryStorage();

const upload = multer({
    storage: storage,
    limits: {
        fileSize: 5 * 1024 * 1024 // 5MB limit
    },
    fileFilter: (req, file, cb) => {
        console.log('Uploading file:', file.originalname, 'Mimetype:', file.mimetype);
        if (file.mimetype.startsWith('image/') || file.mimetype === 'application/octet-stream') {
            cb(null, true);
        } else {
            console.warn('Blocked file type:', file.mimetype);
            cb(new Error('Only images are allowed!'), false);
        }
    }
});

module.exports = upload;
