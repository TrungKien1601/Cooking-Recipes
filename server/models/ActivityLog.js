const mongoose = require('mongoose');

const activityLogSchema = new mongoose.Schema({
    adminId: {
        type: mongoose.Schema.ObjectId,
        ref: 'User',
        required: true,
    },
    adminName: {
        type: String,
        required: true,
    },
    adminRole: {
        type: String,
        required: true,
    },
    adminEmail: {
        type: String,
        required: true,
    },
    action: {
        type: String,
        enum: ['CREATE', 'UPDATE', 'DELETE', 'LOGIN'],
        required: true,
    },
    targetCollection: {
        type: String,
        required: true,
    },
    targetId: {
        type: mongoose.Schema.ObjectId,
        required: false,
    },
    targetName: {
        type: String,
        required: false,
    },
    description: {
        type: String,
        required: true,
    },
    ipAddress: String,
    userAgent: String,
}, { timestamps: true });

module.exports = mongoose.model('ActivityLog', activityLogSchema);