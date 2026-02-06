const express = require('express');
const multer = require('multer');
const bucket = require('../config/firebase');
const router = express.Router();

const upload = multer({
    storage: multer.memoryStorage(),
    limits: {
        fileSize: 5 * 1024 * 1024, // 5MB limit
    },
});

router.post('/', upload.single('file'), async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).send('No file uploaded.');
        }

        const fileName = `${Date.now()}_${req.file.originalname}`;
        const file = bucket.file(fileName);

        const stream = file.createWriteStream({
            metadata: {
                contentType: req.file.mimetype,
            },
            resumable: false,
        });

        stream.on('error', (err) => {
            console.error(err);
            res.status(500).send(err.message);
        });

        stream.on('finish', async () => {
            // Make the file public
            await file.makePublic();

            const publicUrl = `https://storage.googleapis.com/${bucket.name}/${fileName}`;
            res.status(200).json({ url: publicUrl });
        });

        stream.end(req.file.buffer);

    } catch (error) {
        console.error(error);
        res.status(500).send('Server Error');
    }
});

module.exports = router;
