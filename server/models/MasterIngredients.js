const mongoose = require('mongoose');

const masterIngredientSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    unique: true,
    trim: true // [cite: 43]
  },

  synonyms: [{ type: String }], // Tên đồng nghĩa [cite: 43]

  nutritionPer100g: { // Embedded Object cho dinh dưỡng [cite: 43]
    calories: { type: Number, default: 0 },
    protein: { type: Number, default: 0 },
    carbs: { type: Number, default: 0 },
    fat: { type: Number, default: 0 },
    sodium: { type: Number, default: 0 },
    sugars: { type: Number, default: 0 }
  },

  tag: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Tag' // Tham chiếu đến category (vd: Thịt, Rau) [cite: 43]
  }

}, { timestamps: true });

module.exports = mongoose.model('MasterIngredient', masterIngredientSchema);