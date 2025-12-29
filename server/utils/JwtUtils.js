const jwt = require('jsonwebtoken');

const JwtUtil = {
    /**
     * Tạo token. Chỉ chứa thông tin định danh (ID, username), KHÔNG BAO GIỜ chứa mật khẩu.
     * @param {object} userData - Thông tin user (ví dụ: { _id: '...', username: '...' })
     */
    genToken(userData) {
        // Chỉ lấy các trường an toàn để đưa vào payload
        const payload = {
            _id: userData._id,
            email: userData.email,
            role: {
                _id: userData.role._id,
                roleName: userData.role.roleName
            },
        };

        const token = jwt.sign(
            payload,
            process.env.JWT_SECRET, // Đọc từ .env
            { expiresIn: process.env.JWT_EXPIRES } // Đọc từ .env
        );
        return token;
    },

    /**
     * Middleware kiểm tra token (bảo vệ route)
     */
    checkToken(req, res, next) {
        let token = req.headers['x-access-token'] || req.headers['authorization'];

        if (!token) {
            return res.status(401).json({ // Dùng 401 Unauthorized
                success: false,
                message: 'Auth token is not supplied'
            });
        }

        // Xử lý chuẩn "Bearer <token>"
        if (token.startsWith('Bearer ')) {
            token = token.slice(7, token.length); // Tách lấy phần token
        }

        if (token) {
            jwt.verify(token, process.env.JWT_SECRET, (err, decoded) => {
                if (err) {
                    // Nếu token sai hoặc hết hạn
                    return res.status(401).json({
                        success: false,
                        message: 'Token is not valid or has expired'
                    });
                } else {
                    // Token hợp lệ, lưu thông tin đã giải mã vào req
                    // để các route handler sau có thể dùng (ví dụ: req.decoded._id)
                    req.decoded = decoded;
                    next(); // Cho phép đi tiếp
                }
            });
        }
    }
};
module.exports = JwtUtil;