const { OAuth2Client } = require('google-auth-library');
const mongoose = require('mongoose');
const User = require('../../models/User');
const Otp = require('../../models/Otp');
const UserProfile = require('../../models/UserProfile');
const EmailUtil = require('../../config/mail');
// Import Utils
const bcrypt = require('../../utils/BcryptUtils');
const jwt = require('../../utils/JwtUtils');

require("dotenv").config();

// --- CONFIG & HELPER ---
const GOOGLE_CLIENT_ID = process.env.GOOGLE_CLIENT_ID;
const client = new OAuth2Client(GOOGLE_CLIENT_ID);

// Helper để đảm bảo dữ liệu đưa vào jwt.genToken không bị crash
// Vì JwtUtils của bạn bắt buộc phải đọc userData.role._id
const prepareUserForToken = (user) => {
    const userObj = user.toObject ? user.toObject() : user;
    // Nếu user chưa có role, tạo role giả để JwtUtils không bị lỗi
    if (!userObj.role) {
        userObj.role = { _id: "user_role_id", roleName: "User" };
    }
    return userObj;
};

// ==========================================
// AUTH SERVICE OBJECT
// ==========================================
const AuthService = {
    // 1. Xử lý đăng nhập Google
    async processGoogleLogin(idToken) {
        try {
            const ticket = await client.verifyIdToken({
                idToken: idToken,
                audience: [
                    process.env.GOOGLE_CLIENT_ID,
                    process.env.GOOGLE_CLIENT_ID_ANDROID
                ],
            });

            const payload = ticket.getPayload();
            const { email, name, picture, sub } = payload;

            // Bước 2: Tìm user theo email
            let user = await User.findOne({ email });

            if (user) {
                // CASE: User đã tồn tại -> Cập nhật thông tin
                let hasChange = false;

                if (!user.googleid) {
                    user.googleid = sub;
                    hasChange = true;
                }
                if (picture && (!user.image || user.image.trim() === '')) {
                    user.image = picture;
                    hasChange = true;
                }

                if (hasChange) await user.save();

            } else {
                // CASE: User chưa tồn tại -> Tạo mới
                user = await User.create({
                    email: email,
                    username: name,
                    image: picture,
                    googleid: sub,
                    isSurveyDone: false,
                    isVerified: true,
                });
                await UserProfile.create({ user: user._id });
            }

            // Bước 3: Tạo App Token
            // SỬA: Truyền object user thay vì chỉ truyền _id
            const appToken = jwt.genToken(prepareUserForToken(user));

            return {
                token: appToken,
                userId: user._id,
                isSurveyDone: user.isSurveyDone,
                userData: {
                    email: user.email,
                    name: user.username,
                    image: user.image
                }
            };

        } catch (error) {
            console.error("Google Login Error:", error);
            throw new Error("Google Token không hợp lệ hoặc đã hết hạn.");
        }
    },

    // 2. Xử lý đăng nhập Email/Pass
    async processLogin(email, password) {
        const user = await User.findOne({ email });

        if (!user || !user.password) {
            throw new Error("Email hoặc mật khẩu không đúng.");
        }
        
        // SỬA: BcryptUtils.compare trả về Promise<boolean>
        const isMatch = await bcrypt.compare(password, user.password);
        if (!isMatch) {
            throw new Error("Email hoặc mật khẩu không đúng.");
        }

        // SỬA: Truyền user object vào genToken
        const token = jwt.genToken(prepareUserForToken(user));
        
        const userProfile = await UserProfile.findOne({ user: user._id });
        const fullData = {
            ...user.toObject(),
            ...(userProfile ? userProfile.toObject() : {}),
        };
        delete fullData.password;
        
        return {
            token,
            userId: user._id,
            isSurveyDone: user.isSurveyDone,
            data: fullData
        };
    },

    // 3. Gửi OTP
    async sendOtpCode(email, type) {
        const filterUser = { email };
        const user = await User.findOne(filterUser);

        if (type === 'register' && user) throw new Error("Tài khoản đã tồn tại!");
        if (type === 'forgot' && !user) throw new Error("Tài khoản chưa đăng ký.");

        const otpCode = Math.floor(100000 + Math.random() * 900000).toString();

        await Otp.findOneAndUpdate(
            filterUser,
            { otp: otpCode },
            { upsert: true, new: true, setDefaultsOnInsert: true }
        );

        await EmailUtil.send(email, otpCode);
        return { success: true, message: "Đã gửi OTP qua Email" };
    },

    // 4. Verify & Register
    async verifyAndRegisterUser(registrationData) {
        const { email, password, username, otp, phone } = registrationData;

        const emailExists = await User.findOne({ email });
        if (emailExists) throw new Error("Email đã được sử dụng!");

        const validOtp = await Otp.findOne({ email, otp });
        if (!validOtp) throw new Error("OTP sai hoặc hết hạn!");

        // SỬA: Xóa bỏ genSalt, BcryptUtils.hash tự xử lý salt bên trong
        const hashedPassword = await bcrypt.hash(password);

        const newUser = new User({
            username, email, phone,
            password: hashedPassword,
            isVerified: true,
            isSurveyDone: false
        });
        await newUser.save();
        await UserProfile.create({ user: newUser._id });

        await Otp.deleteOne({ email });
        
        // SỬA: Truyền object user
        const token = jwt.genToken(prepareUserForToken(newUser));
        const { password: _, ...userData } = newUser.toObject();

        return { token, userData, userId: newUser._id };
    },

    // 5. Reset Password
    async processPasswordReset(email, otp, newPassword) {
        const validOtp = await Otp.findOne({ email, otp });
        if (!validOtp) throw new Error("OTP sai!");

        // SỬA: Bỏ genSalt, chỉ dùng hash
        const hashedPassword = await bcrypt.hash(newPassword);

        const user = await User.findOneAndUpdate({ email }, { password: hashedPassword }, { new: true });
        if (!user) throw new Error("User not found");

        await Otp.deleteOne({ email });
        
        // SỬA: Gọi đúng hàm jwt.genToken và truyền user object
        const token = jwt.genToken(prepareUserForToken(user));
        return { token };
    },

    // 6. Get User Profile (Giữ nguyên)
    async getUserProfile(identifier, req) {
        let user;
        if (mongoose.Types.ObjectId.isValid(identifier)) {
            user = await User.findById(identifier).select('-password');
        } else {
            user = await User.findOne({ email: identifier }).select('-password');
        }

        if (!user) throw new Error("Không tìm thấy User");

        const profile = await UserProfile.findOne({ user: user._id });

        let finalImage = user.image;
        if (user.image && !user.image.startsWith('http')) {
            const protocol = req.protocol;
            const host = req.get('host');
            finalImage = `${protocol}://${host}/${user.image}`;
        }

        const fullData = {
            ...user.toObject(),
            ...(profile ? profile.toObject() : {}),
            _id: user._id,
            email: user.email,
            username: user.username,
            image: finalImage
        };
        return fullData;
    },

    // 7. Update User Profile (Giữ nguyên)
    async updateUserProfile(userId, updateFields) {
        let { username, image, height, weight, ...otherData } = updateFields;

        const userUpdate = {};
        if (username) userUpdate.username = username;
        if (image) userUpdate.image = image;

        if (Object.keys(userUpdate).length > 0) {
            await User.findByIdAndUpdate(userId, userUpdate);
        }

        const profileUpdateData = { ...otherData };
        if (height !== undefined) {
            profileUpdateData.height = (typeof height === 'number') ? { value: height, unit: 'cm' } : height;
        }
        if (weight !== undefined) {
            profileUpdateData.weight = (typeof weight === 'number') ? { value: weight, unit: 'kg' } : weight;
        }

        return await UserProfile.findOneAndUpdate(
            { user: userId }, profileUpdateData, { new: true, upsert: true }
        );
    },

    // 8. Get Meal Plan (Giữ nguyên)
    async getMealPlanData(identifier) {
        let userIdToSearch = identifier;
        if (!mongoose.Types.ObjectId.isValid(identifier)) {
            const userObj = await User.findOne({ email: identifier });
            if (!userObj) throw new Error("User không tồn tại");
            userIdToSearch = userObj._id;
        }

        const profile = await UserProfile.findOne({ user: userIdToSearch }).lean();
        if (!profile) throw new Error("Chưa có hồ sơ sức khỏe");

        return {
            nutrition: profile.nutritionTargets,
            meals: profile.ai_meal_suggestions || [],
            recommendations: profile.ai_recommendations || []
        };
    },

    // 9. Update Avatar (Giữ nguyên)
    async updateAvatar(userId, imagePath) {
        return await User.findByIdAndUpdate(
            userId, { image: imagePath }, { new: true }
        );
    }
};

module.exports = AuthService;