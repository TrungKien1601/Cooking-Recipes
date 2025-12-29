const Otp = require('../../models/Otp');

const OtpService = {
    async createOtp(email, otpCode) {
        const filter = {email: email};
        const update = {otp: otpCode, createAt: Date.now()};
        const option = {upsert: true, new: true, setDefaultsOnInsert: true};
        const result = await Otp.findOneAndUpdate(filter, update, option); //Hàm findOneAndUpdate yêu cầu 3 tham số riêng biệt
        return result;
    },
    async findOtpByEmail(email, otp) {
        const query = {email: email, otp: otp};
        const otpCheck  = await Otp.findOne(query).exec();
        return otpCheck;
    },
    async deleteOtpByEmail(email) {
        const result = await Otp.findOneAndDelete(email);
        return result;
    }
}

module.exports = OtpService;