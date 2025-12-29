const mongoose = require('mongoose');

const roleSchema = new mongoose.Schema({
    _id: {
        type: Number,
        required: true,
    },
    roleName: {
        type: String,
        required: true,
    },
}, {_id: false})

module.exports = mongoose.model('Role', roleSchema);