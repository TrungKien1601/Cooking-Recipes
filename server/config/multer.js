const multer = require('multer');
const path = require('path');

const storage = multer.diskStorage({
    destination: function (req, file, cb) {
        cb(null, 'public/uploads/');
    },
    filename: function (req, file, cb) {
        // Giữ nguyên logic đặt tên file
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        cb(null, uniqueSuffix + path.extname(file.originalname));
    }
});

const fileFilter = (req, file, cb) => {
    // 1. Danh sách các định dạng cho phép (Whitelist)
    // Lưu ý: Không nên cho phép SVG trừ khi bạn có cơ chế sanitize kỹ.
    const filetypes = /jpeg|jpg|png|gif|webp|bmp|heic|heif/i;

    // 2. Kiểm tra đuôi file (Extension)
    // path.extname lấy cả dấu chấm (ví dụ .jpg), ta bỏ dấu chấm đi để check regex
    const extname = filetypes.test(path.extname(file.originalname).substring(1).toLowerCase());

    // 3. Kiểm tra Mime-type
    // Cho phép các mime chuẩn HOẶC các trường hợp đặc biệt của HEIC
    const checkMime = filetypes.test(file.mimetype) || 
                      file.mimetype === 'application/octet-stream'; 
                      // Lưu ý: HEIC đôi khi được gửi dưới dạng octet-stream từ một số device, 
                      // nhưng an toàn nhất là check magic number (phức tạp hơn). 
                      // Nếu chỉ tin tưởng client thì check mimetype chứa 'image' hoặc 'heic' là tạm ổn.

    // Logic kiểm tra chặt chẽ hơn:
    const isImageMime = file.mimetype.startsWith('image/') || 
                        file.mimetype.includes('heic') || 
                        file.mimetype.includes('heif');

    // 4. ĐIỀU KIỆN QUYẾT ĐỊNH: Phải thỏa mãn CẢ HAI (Đuôi file OK VÀ Mime-type OK)
    if (extname && isImageMime) {
        return cb(null, true);
    } else {
        // Log lỗi để debug
        console.error(`Blocked file: ${file.originalname} (Mime: ${file.mimetype})`);
        return cb(new Error('Chỉ chấp nhận file ảnh (JPG, PNG, WEBP, HEIC)!'), false);
    }
};

const uploadPicture = multer({
    storage: storage, 
    fileFilter: fileFilter,
    limits: {
        fileSize: 10 * 1024 * 1024 // Tăng lên 10MB vì ảnh HEIC/Raw thường nặng
    }
});

module.exports = uploadPicture;