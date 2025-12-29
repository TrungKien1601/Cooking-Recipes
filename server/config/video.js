const multer = require('multer');
const path = require('path');

const storage = multer.diskStorage({
    destination: function (req, file, cb) {// Tự tạo folder public/uploads/videos
        cb(null, 'public/videos/');
    },
    filename: function (req, file, cb) {
        const uniqueSuffix = 'video_' + Date.now() + '-' + Math.round(Math.random() * 1E9);
        cb(null, uniqueSuffix + path.extname(file.originalname));
    }
});

const fileFilter = (req, file, cb) => {
    // 1. Chỉ chấp nhận các đuôi video phổ biến
    const filetypes = /mp4|mov|avi|mkv|webm/i;
    const extname = filetypes.test(path.extname(file.originalname).substring(1).toLowerCase());
    
    // 2. Check Mime type bắt đầu bằng 'video/'
    const isVideo = file.mimetype.startsWith('video/');

    if (extname && isVideo) {
        return cb(null, true);
    } else {
        cb(new Error('Chỉ chấp nhận file video (MP4, MOV, AVI)!'), false);
    }
};

const uploadVideo = multer({
    storage: storage,
    fileFilter: fileFilter,
    limits: {
        fileSize: 100 * 1024 * 1024 // Giới hạn 100MB cho video
    }
});

module.exports = uploadVideo;