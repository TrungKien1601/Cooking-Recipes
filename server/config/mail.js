const nodemailer = require('nodemailer');
const transporter = nodemailer.createTransport({
    service: "gmail", // Server của Microsoft (dùng cho cả hotmail, outlook, live)
    // port: 587, // Port bảo mật
    // secure: false, // Dùng 'false' vì port 587 sử dụng STARTTLS
    auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS
    }
});

const EmailUtil = {
    async send(email, otp) {
        const htmlBody = `
            <div style="font-family: Arial, sans-serif; padding: 20px;">
                <h2>Xác thực tài khoản Cooking Recipes 🍳</h2>
                <p>Mã xác thực của bạn là:</p>
                <h1 style="color: #4CAF50; letter-spacing: 5px;">${otp}</h1>
                <p>Mã này sẽ hết hạn sau 2 phút.</p>
            </div>
        `;

        const mailOptions = {
            from: `"Cooking Recipes Support" <${process.env.EMAIL_USER}>`,
            to: email,
            subject: 'MÃ XÁC THỰC OTP (Cooking Recipes)',
            html: htmlBody
        };
        try {
            await transporter.sendMail(mailOptions);
            return true;
        } catch (err) {
            console.error("Lỗi khi gửi mail", err)
            return false;
        }
    }
};

module.exports = EmailUtil;