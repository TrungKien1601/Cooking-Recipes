// utils/scanPrompts.js

const getTodayDate = () => new Date().toISOString().split('T')[0];

// 1. BARCODE PROMPT (Giữ nguyên)
const getBarcodePrompt = (barcode, productName = null) => {
  if (productName) {
    return `
    Sản phẩm: "${productName}" (Barcode: ${barcode}).
    VAI TRÒ: Chuyên gia dinh dưỡng.
    NHIỆM VỤ: Phân tích sản phẩm này.
    OUTPUT JSON:
    { "found": true, "is_food": true, "name": "${productName}", "category": "Gia vị/Thực phẩm khô", "image_url": "", "unit": "gói", "storage": "Tủ bếp", "nutrients": { "calories": 0, "fat": 0, "carbs": 0, "protein": 0 }, "description": "Mô tả ngắn" }`;
  }
  return `Barcode "${barcode}". Return { "found": false } if unknown.`;
};

// 2. IMAGE SCAN PROMPT (Giữ nguyên)
const getImageScanPrompt = () => {
  const today = getTodayDate();
  return `
  VAI TRÒ: Chuyên gia thực phẩm Việt Nam.
  NHIỆM VỤ: Nhìn ảnh nhận diện nguyên liệu.
  QUY TẮC PHÂN LOẠI (CATEGORY):
  Chỉ được chọn 1 trong các nhóm sau (Tuyệt đối không sáng tạo thêm):
  - "Thịt" (Heo, Bò, Gà, Vịt...)
  - "Hải sản" (Cá, Tôm, Cua, Ốc, Mực...)
  - "Rau củ" (Rau, Củ, Quả, Nấm...)
  - "Trái cây"
  - "Trứng/Sữa"
  - "Gia vị/Đồ khô"
  - "Đồ uống"
  - "Khác"
  OUTPUT JSON ARRAY:
  [{ "name": "Tên tiếng Việt", "category": "Phân loại", "quantity": 1, "weight": 500, "unit": "gram", "calories": 250, "expiryDate": "YYYY-MM-DD", "storage": "Ngăn mát", "image_url": "" }]
  `;
};

// ============================================================
// 3. RECIPE SUGGESTION PROMPT (ULTIMATE: KỶ LUẬT + SÀNG LỌC)
// ============================================================
const getRecipeSuggestionPrompt = (ingredients, userContext = "") => {
  const listStr = Array.isArray(ingredients) ? ingredients.join(", ") : ingredients;
  
  return `
  KHO NGUYÊN LIỆU: "${listStr}".
  CONTEXT: "${userContext}".
  
  VAI TRÒ: Tổng quản bếp trưởng thực tế & thông minh.
  NHIỆM VỤ: Xây dựng thực đơn 3 món ngon, tối ưu hóa nguyên liệu đang có.

  🧠 CHIẾN THUẬT TƯ DUY (CHAIN OF THOUGHT):
  1. SÀNG LỌC (Filtering):
     - Nếu danh sách quá dài (>5 món): Hãy ưu tiên dùng Đồ tươi sống (Thịt/Cá/Rau) trước vì dễ hỏng. Đồ khô/Snack để lại sau.
     - Tìm "Cặp đôi hoàn hảo": Ghép Đạm + Rau có sẵn (VD: Có Sườn & Bầu -> Canh sườn bầu).
  
  2. PHÂN BỔ (Distribution):
     - Đừng dồn hết vào 1 món. Hãy chia ra: 1 Món Mặn chủ lực, 1 Món Canh/Xào, 1 Món phụ.
     - Nếu có nhiều loại Đạm (VD: Cá & Thịt), hãy chia ra mỗi món dùng 1 loại.

  ⛔️ QUY TẮC CẤM TUYỆT ĐỐI (STRICT RULES):
  1. KHÔNG BỊA NGUYÊN LIỆU CHÍNH (NO Ghost Ingredients):
     - Không thấy "Bò" -> CẤM gợi ý món Bò.
     - Không thấy "Gà" -> CẤM gợi ý món Gà.
     - Chỉ được dùng: Nguyên liệu trong list + Gia vị cơ bản (Mắm, Muối, Đường, Dầu, Hành, Tỏi, Tiêu, Ớt).
  
  2. XỬ LÝ KHI THIẾU:
     - Nếu thiếu rau gia vị (Hành lá, Ngò...) -> Cứ gợi ý món và ghi vào "ingredients_missing".
     - Đừng vì thiếu hành lá mà đổi sang làm món khác không liên quan.

  OUTPUT FORMAT (JSON ONLY):
  [
    {
      "name": "Tên món (Hấp dẫn)",
      "description": "Mô tả hương vị và lý do chọn (VD: 'Món này giúp xử lý hết phần Mực và Cà chua bạn đang có').",
      "cooking_time": "30 phút",
      "difficulty": "Trung bình",
      "calories": 500,
      
      "all_ingredients": [
        "Nguyên liệu chính (Lấy từ kho)",
        "Gia vị cơ bản"
      ],
      
      "ingredients_used": ["Liệt kê các nguyên liệu TỪ KHO được dùng"], 
      "ingredients_missing": ["Gia vị/Rau thơm cần mua thêm"], 
      
      "steps": ["Bước 1...", "Bước 2..."],
      "chef_tips": "Mẹo nhỏ để món ăn ngon hơn...",
      "macros": { "protein": 0, "carbs": 0, "fat": 0 }
    }
  ]
  `;
};

module.exports = { getBarcodePrompt, getImageScanPrompt, getRecipeSuggestionPrompt };