const mongoose = require('mongoose');

const userProfileSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    unique: true 
  },
  gender: { type: String },
  age: { type: Number },
  height: {
      value: { type: Number },
      unit: { type: String, default: 'cm' }
  }, 

  weight: {
    value: { type: Number },
    unit: { type: String, default: 'kg' }
  },

  targetWeight: { type: Number },

  healthConditions: [{ type: String }], 
  habits: [{ type: String }],
  exclusions: { 
        type: [String], 
        default: [] 
    },
  
  goal: { type: String },
  diets: [{ type: String }], 
  
  nutritionTargets: { type: Object }, 
  
  ai_meal_suggestions: { 
      type: Array, 
      default: []
  },

  ai_recommendations: { type: Array, default: [] },
  ai_foods_to_avoid: { type: Array, default: [] }

}, { timestamps: true });

module.exports = mongoose.model('UserProfile', userProfileSchema);