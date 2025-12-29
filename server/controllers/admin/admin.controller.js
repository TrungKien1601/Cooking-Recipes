const express = require('express');
const OtpService = require('../../services/admin/otp.service');
const AdminService = require('../../services/admin/admin.service');
const ActivityLogService = require('../../services/admin/actlog.service')

const JwtUtil = require('../../utils/JwtUtils');
const BcryptUtil = require('../../utils/BcryptUtils');
const EmailUtil = require('../../config/mail');

//Đăng nhập
const sigin = async (req, res) => {
    const email = req.body.email;
    const password = req.body.password;
    if (email && password) {
        try {
            const user = await AdminService.selectByEmail(email);
            if (!user || !await BcryptUtil.compare(password, user.password)) {
                return res.json({success: false, message: 'Xác thực thất bại. Email hoặc tài khoản không hợp lệ.'});
            }
            
            const roleId = user.role._id;
            if ( roleId !== 1 && roleId !== 2) {
                return res.json({ success: false, message: 'Xác thực thất bại. Chỉ Admin hoặc Moder mới được đăng nhập'});
            }
            
            const token = JwtUtil.genToken(user);

            ActivityLogService.createLog({
                adminId: user._id,
                adminName: user.username,
                adminRole: user.role.roleName,
                adminEmail: user.email,
                action: "LOGIN",
                targetCollection: 'User',
                targetId: null,
                targetName: null,
                description: `${user.role.roleName} ${user.username} đã đăng nhập`,
                req: req
            });

            res.json({
                success: true,
                message: 'Authentication successful',
                user: user,
                token: token,
            });

        } catch (error) {
            res.status(500).json({
                success: false,
                message: 'Internal server error',
                error: error.message
            });
        }
    } else {
        res.json({
            success: false,
            message: 'Email and password are required.'
        });
    }
};

const checkToken = async (req, res) => {
    const token = req.headers['x-access-token'] || req.headers['authorization'];
    res.json({
        success: true,
        message: 'Token is valid',
        token: token
    });
};


// Quên mật khẩu
const sentOtp = async (req, res) => {
    const email = req.body.email;
    const otpCode = Math.floor(100000 + Math.random() * 900000).toString();

    if (!email) {
        return res.json({success: false, message: "Vui lòng nhập email"});
    }

    try {
        const user = await AdminService.selectByEmail(email);
        if (!user) {
            return res.json({success: false, message: "Không tìm thấy tài khoản hoặc tài khoản không có quyền truy cập"});
        }

        await OtpService.createOtp(email, otpCode);

        const sendResult = await EmailUtil.send(email, otpCode);

        if (sendResult) {
            return res.json({success: true, message: "Mã Otp đã được gửi đến email của bạn", otp: otpCode});
        } else {
            return res.json({success: false, message: "Lỗi khi gửi mail"});
        }
    } catch (err) {
        console.error(err);
        res.status(500).json({success: false, message: "Lỗi server", error: err});
    }
};

const verifyOtp = async (req, res) => {
    const email = req.body.email;
    const otp = req.body.otp;
    
    if (!otp || !email) {
        return res.json({success: false, message: "Vui lòng nhập đầy đủ thông tin."});
    }

    try {
        const validOtp = await OtpService.findOtpByEmail(email, otp);
        if (validOtp) {
            await OtpService.deleteOtpByEmail(email);

            res.json({success: true, message: "Xác thực Otp thành công."});
        } else {
            res.json({success: false, message: "Mã Otp không đúng hoặc đã hết hạn."});
        }
    } catch (err) {
        console.error(err);
        res.status(500).json({success: false, message: "Lỗi server", error: err});
    }
};

const resetPassword = async (req, res) => {
    const email = req.body.email;
    const newPassword = req.body.password;

    if (!email || !newPassword) {
        return res.json({success: false, message: "Vui lòng điền đầy đủ."})
    }

    try {
        const admin = await AdminService.selectByEmail(email);
        const result = await BcryptUtil.compare(newPassword, admin.password)
        if (admin && !result) {
            const newHashedPassword = await BcryptUtil.hash(newPassword);
            await AdminService.updatePassByEmail(email, newHashedPassword);

            return res.json({success: true, message: "Mật khẩu đã được cập nhật."})
        } else {
            return res.json({success: false, message: "Mật khẩu này đã tồn tại."})
        }
    } catch (err) {
        console.error(err);
        res.status(500).json({success: false, message: "Lỗi server", error: err});
    }
};


//User-Function
const authMe = async (req, res) => {
    try{
        const user = await AdminService.selectById(req.decoded._id);
        
        if (!user) {
            return res.status(401);
        } else if (user.role.roleName === 'User') {
            return res.status(403).json({
                success: false, 
                message: "Bạn không có quyền thực hiện hành động này."
            });
        } else {
            return res.json({success: true, user: user});
        }
    } catch (err) {
        return res.status(500).json({success: false, message: err.message});
    }
};

const updateUser = async (req, res) => {
    const _id = req.decoded._id;
    const username = req.body.username;
    const phone = req.body.phone;
    const userData = { username: username, phone: phone};
    try {
        const user = await AdminService.updateUserById(_id, userData);
        if(!user || user.role.roleName === 'User') {
            return res.status(403).json({
                success: false, 
                message: "Bạn không có quyền thực hiện hành động này."
            });
        } else {
            ActivityLogService.createLog({
                adminId: user._id,
                adminName: user.username,
                adminRole: user.role.roleName,
                adminEmail: user.email,
                action: "UPDATE",
                targetCollection: 'User',
                targetId: null,
                targetName: null,
                description: `${user.role.roleName} ${user.username} đã thay đổi thông tin cá nhân`,
                req: req
            });
            return res.json({success: true, message: "Cập nhật thành công", user: user});
        }
    } catch (err) {
        return res.status(500).json({success: false, message: err.message});
    }
};


//xử lý hình ảnh
const uploadAvatar = async (req, res) => {
    try {
        const _id = req.decoded._id

        const user = await AdminService.selectById(_id);
        if (user.role.roleName === 'User') return res.status(403);

        if (!req.file) {
            return res.status(400).json({ success: false, message: 'Chưa chọn file'});
        } else {
            const newFileName = req.file.filename;

            const webPath = 'uploads/' + newFileName;

            const user = await AdminService.updatePictureById(_id, webPath); //Sửa để lưu lại dữ liệu vào database

            if (!user) {
                return res.json({success: false, message: "Không tìm thấy tài khoản"});
            }
            
            return res.json({
                success: true,
                message: 'Upload thành công',
                user: user,
                filePath: webPath,
            });
        }
    } catch (err) {
        console.error("Lỗi khi upload hình ảnh", err);
    }
};

module.exports = { sigin, checkToken, sentOtp, verifyOtp, resetPassword, authMe, updateUser, uploadAvatar };