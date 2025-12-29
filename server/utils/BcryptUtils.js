const bcrypt = require('bcrypt');

const BcrytUtil = {
    /**
     * Mã hóa mật khẩu. Dùng khi đăng ký tài khoản.
     * @param {string} password - Mật khẩu thuần (plain text)
     * @returns {Promise<string>} - Mật khẩu đã được hash
     */
    async hash(password) {
        // 10 là "salt rounds" - số vòng lặp mã hóa.
        // Con số càng cao, càng an toàn nhưng càng tốn thời gian. 10 là mức tiêu chuẩn.
        const saltRounds = 10;
        const hash = await bcrypt.hash(password, saltRounds);
        return hash;
    },

    /**
     * So sánh mật khẩu thuần với hash trong database. Dùng khi đăng nhập.
     * @param {string} password - Mật khẩu thuần người dùng nhập
     * @param {string} hash - Chuỗi hash lưu trong database
     * @returns {Promise<boolean>} - True nếu khớp, false nếu không
     */
    async compare(password, hash) {
        const isMatch = await bcrypt.compare(password, hash);
        return isMatch;
    }
}
module.exports = BcrytUtil;