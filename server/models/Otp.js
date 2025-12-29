const mongoose = require('mongoose');
const { create } = require('./MasterIngredients');

const OtpSchema = new mongoose.Schema({
    email: {
        type: String,
        require: true,
    },
    otp: {
        type: String,
        require: true,
    },
    createAt: {
        type: Date,
        default: Date.now,
        expires: 120,
    }
});

module.exports = mongoose.model('Otp', OtpSchema);