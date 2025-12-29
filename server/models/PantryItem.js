// const mongoose = require('mongoose');

// const pantryItemSchema = new mongoose.Schema({
//   user: {
//     type: mongoose.Schema.Types.ObjectId,
//     ref: 'User',
//     required: true,
//     index: true  // Optimize query by user
//   },
//   masterIngredient: {
//     type: mongoose.Schema.Types.ObjectId,
//     ref: 'MasterIngredient',
//     required: true
//   },
//   image_url: { 
//     type: String, 
//     default: "" 
//   },
//   quantity: { 
//     type: Number, 
//     required: true,
//     min: 0
//   },
//   weight: { 
//     type: Number, 
//     default: 0,
//     min: 0 
//   },
//   unit: { 
//     type: String, 
//     default: 'cái'
//   },
//   calories: { 
//     type: Number, 
//     default: 0,
//     min: 0
//   },
  
//   // --- THÔNG TIN KHÁC ---
//   expiryDate: { 
//     type: Date,
//     index: true  // Optimize sort/query expiry
//   },
  
//   // Thông tin bổ sung (nếu cần)
//   storage: {
//       type: String,
//       default: "Ngăn mát" // Ngăn mát, Ngăn đông, Tủ bếp
//   },
//   note: {
//       type: String,
//       default: ""
//   },
//   addMethod: {
//     type: String,
//     enum: ['BARCODE', 'SCAN_IMAGE', 'MANUAL'],
//     default: 'MANUAL'
//   }
// }, { timestamps: true });

// module.exports = mongoose.model('PantryItem', pantryItemSchema);


const mongoose = require('mongoose');

const pantryItemSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true  // Optimize query by user
  },
  name: {
    type: String,
    required: true, 
    trim: true 
  },
  masterIngredient: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'MasterIngredient',
    required: true
  },
  image_url: { 
    type: String, 
    default: "" 
  },
  quantity: { 
    type: Number, 
    required: true,
    min: 0
  },
  weight: { 
    type: Number, 
    default: 0,
    min: 0 
  },
  unit: { 
    type: String, 
    default: 'cái'
  },
  calories: { 
    type: Number, 
    default: 0,
    min: 0
  },
  
  // --- THÔNG TIN KHÁC ---
  expiryDate: { 
    type: Date,
    index: true  // Optimize sort/query expiry
  },
  
  // Thông tin bổ sung (nếu cần)
  storage: {
      type: String,
      default: "Ngăn mát" // Ngăn mát, Ngăn đông, Tủ bếp
  },
  note: {
      type: String,
      default: ""
  },
  addMethod: {
    type: String,
    enum: ['BARCODE', 'SCAN_IMAGE', 'MANUAL'],
    default: 'MANUAL'
  }
}, { timestamps: true });

module.exports = mongoose.model('PantryItem', pantryItemSchema);