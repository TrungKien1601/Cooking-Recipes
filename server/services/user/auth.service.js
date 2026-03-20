const { OAuth2Client } = require('google-auth-library');
const mongoose = require('mongoose');
const User = require('../../models/User');
const Otp = require('../../models/Otp');
const UserProfile = require('../../models/UserProfile');
const EmailUtil = require('../../config/mail');
const bcrypt = require('../../utils/BcryptUtils');
const jwt = require('../../utils/JwtUtils');

require("dotenv").config();

const GOOGLE_CLIENT_ID = process.env.GOOGLE_CLIENT_ID;
const client = new OAuth2Client(GOOGLE_CLIENT_ID);

const prepareUserForToken = (user) => {
    const userObj = user.toObject ? user.toObject() : user;
    // Tốt nhất nên xử lý default role trong Model, đây chỉ là fallback
    if (!userObj.role) {
        userObj.role = { _id: "user_role_id", roleName: "User" };
    }
    return userObj;
};

const AuthService = {
    async processGoogleLogin(idToken) {
        try {
            const ticket = await client.verifyIdToken({
                idToken: idToken,
                audience: [process.env.GOOGLE_CLIENT_ID, process.env.GOOGLE_CLIENT_ID_ANDROID],
            });
            const { email, name, picture, sub } = ticket.getPayload();
            
            let user = await User.findOne({ email });

            if (user) {
                // Update nhẹ nhàng chỉ khi cần thiết
                let hasChange = false;
                if (!user.googleid) { user.googleid = sub; hasChange = true; }
                if (picture && (!user.image || !user.image.startsWith('http'))) { 
                    user.image = picture; hasChange = true; 
                }
                if (hasChange) await user.save();
            } else {
                // Dùng Transaction để đảm bảo tạo cả User và Profile
                const session = await mongoose.startSession();
                session.startTransaction();
                try {
                    user = await User.create([{
                        email, 
                        username: name, 
                        image: picture, 
                        googleid: sub, 
                        isSurveyDone: false, 
                        isVerified: true
                        // Nên thêm default role ở đây
                    }], { session });
                    
                    user = user[0]; // create với session trả về array
                    await UserProfile.create([{ user: user._id }], { session });

                    await session.commitTransaction();
                } catch (err) {
                    await session.abortTransaction();
                    throw err;
                } finally {
                    session.endSession();
                }
            }

            return {
                token: jwt.genToken(prepareUserForToken(user)),
                userId: user._id,
                isSurveyDone: user.isSurveyDone,
                userData: { email: user.email, name: user.username, image: user.image }
            };
        } catch (error) {
            console.error("Google Login Error:", error);
            throw new Error("Google Login thất bại.");
        }
    },

    async processLogin(email, password) {
        const user = await User.findOne({ email });
        if (!user || !user.password) throw new Error("Email hoặc mật khẩu không đúng.");
        
        const isMatch = await bcrypt.compare(password, user.password);
        if (!isMatch) throw new Error("Email hoặc mật khẩu không đúng.");

        const [token, userProfile] = await Promise.all([
            Promise.resolve(jwt.genToken(prepareUserForToken(user))),
            UserProfile.findOne({ user: user._id }).lean()
        ]);

        const fullData = { ...user.toObject(), ...(userProfile || {}) };
        delete fullData.password;

        return { token, userId: user._id, isSurveyDone: user.isSurveyDone, data: fullData };
    },

    async sendOtpCode(email, type) {
        const user = await User.findOne({ email });
        if (type === 'register' && user) throw new Error("Tài khoản đã tồn tại!");
        if (type === 'forgot' && !user) throw new Error("Tài khoản chưa đăng ký.");

        const otpCode = Math.floor(100000 + Math.random() * 900000).toString();
        await Otp.findOneAndUpdate(
            { email },
            { otp: otpCode, createdAt: new Date() }, // Cập nhật thời gian để check TTL
            { upsert: true, new: true, setDefaultsOnInsert: true }
        );
        await EmailUtil.send(email, otpCode);
        return { success: true, message: "Đã gửi OTP qua Email" };
    },

    async verifyAndRegisterUser(data) {
        const { email, password, username, otp, phone } = data;
        
        // Check OTP trước để đỡ query User nếu OTP sai
        const validOtp = await Otp.findOne({ email, otp });
        if (!validOtp) throw new Error("OTP sai hoặc hết hạn!");
        
        const emailExists = await User.exists({ email });
        if (emailExists) throw new Error("Email đã được sử dụng!");

        const hashedPassword = await bcrypt.hash(password);

        // Transaction
        const session = await mongoose.startSession();
        session.startTransaction();
        let newUser;
        try {
            const users = await User.create([{
                username, email, phone,
                password: hashedPassword,
                isVerified: true,
                isSurveyDone: false
            }], { session });
            newUser = users[0];

            await UserProfile.create([{ user: newUser._id }], { session });
            await Otp.deleteOne({ email }).session(session);

            await session.commitTransaction();
        } catch (err) {
            await session.abortTransaction();
            throw err;
        } finally {
            session.endSession();
        }

        const token = jwt.genToken(prepareUserForToken(newUser));
        const { password: _, ...userData } = newUser.toObject();

        return { token, userData, userId: newUser._id };
    },

    async getUserProfile(identifier, req) {
        const query = mongoose.Types.ObjectId.isValid(identifier) 
            ? { _id: identifier } 
            : { email: identifier };
            
        const user = await User.findOne(query).select('-password');
        if (!user) throw new Error("Không tìm thấy User");
        const profile = await UserProfile.findOne({ user: user._id }).lean();
        let finalImage = user.image;

        if (user.image && !user.image.match(/^https?:\/\//)) {
            finalImage = `${req.protocol}://${req.get('host')}/${user.image}`;
        }
        return {
            ...user.toObject(),
            ...(profile || {}),
            _id: user._id,
            image: finalImage
        };
    },
    async updateUserProfile(userId, updateFields) {
        let { username, image, height, weight, ...otherData } = updateFields;
        const userUpdate = {};
        if (username) userUpdate.username = username;
        if (image) userUpdate.image = image;

        if (Object.keys(userUpdate).length > 0) {
            await User.findByIdAndUpdate(userId, userUpdate);
        }
        
        const profileUpdateData = { ...otherData };
        if (height !== undefined) profileUpdateData.height = (typeof height === 'number') ? { value: height, unit: 'cm' } : height;
        if (weight !== undefined) profileUpdateData.weight = (typeof weight === 'number') ? { value: weight, unit: 'kg' } : weight;

        return await UserProfile.findOneAndUpdate(
            { user: userId }, profileUpdateData, { new: true, upsert: true }
        );
    },
    
    async getMealPlanData(identifier) {
        let userIdToSearch = identifier;
        if (!mongoose.Types.ObjectId.isValid(identifier)) {
            const userObj = await User.findOne({ email: identifier }).select('_id'); // Chỉ lấy _id cho nhẹ
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
    
    async updateAvatar(userId, imagePath) {
        return await User.findByIdAndUpdate(userId, { image: imagePath }, { new: true });
    }
};

module.exports = AuthService;