const multer = require('multer');
const path = require('path');

// ==========================================
// CẤU HÌNH UPLOAD ẢNH (Image)
// ==========================================
const imageStorage = multer.diskStorage({
    destination: function (req, file, cb) {
        cb(null, 'public/uploads/');
    },
    filename: function (req, file, cb) {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        cb(null, uniqueSuffix + path.extname(file.originalname));
    }
});

const imageFileFilter = (req, file, cb) => {
    const filetypes = /jpeg|jpg|png|gif|webp|bmp|heic|heif/i;
    // Check đuôi file
    const extname = filetypes.test(path.extname(file.originalname).substring(1).toLowerCase());
    
    // Check Mime type (cho phép cả octet-stream cho trường hợp HEIC đặc biệt)
    const checkMime = filetypes.test(file.mimetype) || 
                      file.mimetype === 'application/octet-stream'; 

    const isImageMime = file.mimetype.startsWith('image/') || 
                        file.mimetype.includes('heic') || 
                        file.mimetype.includes('heif');

    if (extname && isImageMime) {
        return cb(null, true);
    } else {
        console.error(`Blocked file: ${file.originalname} (Mime: ${file.mimetype})`);
        return cb(new Error('Chỉ chấp nhận file ảnh (JPG, PNG, WEBP, HEIC)!'), false);
    }
};

const uploadImage = multer({
    storage: imageStorage, 
    fileFilter: imageFileFilter,
    limits: {
        fileSize: 10 * 1024 * 1024 // 10MB cho ảnh
    }
});

// ==========================================
// CẤU HÌNH UPLOAD VIDEO
// ==========================================
const videoStorage = multer.diskStorage({
    destination: function (req, file, cb) {
        cb(null, 'public/videos/');
    },
    filename: function (req, file, cb) {
        // Thêm tiền tố 'video_' như file gốc của bạn
        const uniqueSuffix = 'video_' + Date.now() + '-' + Math.round(Math.random() * 1E9);
        cb(null, uniqueSuffix + path.extname(file.originalname));
    }
});

const videoFileFilter = (req, file, cb) => {
    const filetypes = /mp4|mov|avi|mkv|webm/i;
    const extname = filetypes.test(path.extname(file.originalname).substring(1).toLowerCase());
    
    const isVideo = file.mimetype.startsWith('video/');

    if (extname && isVideo) {
        return cb(null, true);
    } else {
        cb(new Error('Chỉ chấp nhận file video (MP4, MOV, AVI)!'), false);
    }
};

const uploadVideo = multer({
    storage: videoStorage,
    fileFilter: videoFileFilter,
    limits: {
        fileSize: 100 * 1024 * 1024 // 100MB cho video
    }
});

// ==========================================
// CẤU HÌNH UPLOAD HỖN HỢP (CẢ ẢNH VÀ VIDEO)
// ==========================================
const mixedStorage = multer.diskStorage({
    destination: function (req, file, cb) {
        // Tự động kiểm tra loại file để chọn thư mục
        if (file.mimetype.startsWith('image/')) {
            cb(null, 'public/uploads/');
        } else if (file.mimetype.startsWith('video/')) {
            cb(null, 'public/videos/');
        } else {
            cb(new Error('File không hợp lệ!'), false);
        }
    },
    filename: function (req, file, cb) {
        const prefix = file.mimetype.startsWith('video/') ? 'video_' : '';
        const uniqueSuffix = prefix + Date.now() + '-' + Math.round(Math.random() * 1E9);
        cb(null, uniqueSuffix + path.extname(file.originalname));
    }
});

const mixedFileFilter = (req, file, cb) => {
    // Regex cho cả ảnh và video
    const allowedTypes = /jpeg|jpg|png|gif|webp|heic|mp4|mov|avi|mkv|webm/i;
    const extname = allowedTypes.test(path.extname(file.originalname).substring(1).toLowerCase());
    
    // Check mime type chung
    const isImage = file.mimetype.startsWith('image/') || file.mimetype.includes('heic');
    const isVideo = file.mimetype.startsWith('video/');

    if (extname && (isImage || isVideo)) {
        return cb(null, true);
    } else {
        return cb(new Error('Chỉ chấp nhận file Ảnh hoặc Video!'), false);
    }
};

const uploadMixed = multer({
    storage: mixedStorage,
    fileFilter: mixedFileFilter,
    limits: {
        fileSize: 110 * 1024 * 1024 // Set theo limit lớn nhất (của Video là 110MB)
    }
});

// ==========================================
// EXPORT CẢ 2
// ==========================================
module.exports = {
    uploadImage,
    uploadVideo,
    uploadMixed
};