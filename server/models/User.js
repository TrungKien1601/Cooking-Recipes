const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  image: { type: String, default: 'uploads/default.png' },
  username: {
    type: String,
    required: true,
    trim: true
  },
  email: {
    type: String,
    required: true,
    unique: true,
    lowercase: true,
    trim: true
  },
  phone: {
    type: String,
    unique: true,
    required: true
  },
  password: {
    type: String,
    required: true
  },
  isVerified: {
    type: Boolean,
    default: false
  },
  role: {
    type: Number,
    ref: 'Role',
    default:3,
    required: true,
  },
  isSurveyDone: {
    type: Boolean,
    default: false
  }
}, { timestamps: true });

module.exports = mongoose.model('User', userSchema);