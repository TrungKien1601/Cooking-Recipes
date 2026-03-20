// utils/scanPrompts.js

const getTodayDate = () => new Date().toISOString().split('T')[0];

// 1. BARCODE PROMPT
const getBarcodePrompt = (barcode, productName = null) => {
  if (productName) {
    return `
    Sản phẩm: "${productName}" (Barcode: ${barcode}).
    VAI TRÒ: Chuyên gia dinh dưỡng và quản lý kho.
    NHIỆM VỤ: Phân tích sản phẩm này để lưu vào kho.
    
    OUTPUT JSON (Chỉ trả về JSON):
    { 
      "found": true, 
      "is_food": true, 
      "name": "${productName}", 
      "category": "Hãy tự chọn 1 trong: [Thịt, Hải sản, Rau củ, Trái cây, Trứng/Sữa, Gia vị/Đồ khô, Đồ uống, Khác]", 
      "image_url": "", 
      "unit": "gói/chai/hộp", 
      "storage": "Tủ bếp/Ngăn mát", 
      "nutrients": { "calories": 0, "fat": 0, "carbs": 0, "protein": 0 }, 
      "description": "Mô tả ngắn gọn về sản phẩm" 
    }`;
  }
  return `Barcode "${barcode}". Return { "found": false } if unknown.`;
};

// 2. IMAGE SCAN PROMPT
const getImageScanPrompt = (detectedHints = []) => {
  const today = getTodayDate();
  const hintsText = detectedHints.length > 0 
    ? `THÔNG TIN THAM KHẢO TỪ HỆ THỐNG KHÁC (CÓ THỂ SAI): "${detectedHints.join(", ")}".`
    : "";

  return `
  VAI TRÒ: Chuyên gia thực phẩm và đi chợ người Việt Nam.
  NHIỆM VỤ: Nhìn ảnh và xác định chính xác các nguyên liệu.
  
  ${hintsText}
  
  CHIẾN THUẬT NHẬN DIỆN (CHAIN OF THOUGHT):
  1. Nhìn kỹ ảnh thật: Đừng tin hoàn toàn vào "THÔNG TIN THAM KHẢO". Nếu ảnh là "Con mực" mà tham khảo bảo là "Bí đao" -> Hãy chọn "Con mực".
  2. Xác định đơn vị tự nhiên:
     - Rau củ tròn (Hành, Tỏi, Khoai...): Dùng đơn vị "củ".
     - Trái cây/Rau quả (Bí, Cà, Chanh...): Dùng đơn vị "trái" hoặc "quả".
     - Hải sản nguyên con (Mực, Cá, Tôm...): Dùng đơn vị "con".
     - Rau lá (Cải, Muống...): Dùng đơn vị "bó".
     - Thịt tảng: Dùng đơn vị "kg".
     -> Ưu tiên đơn vị đếm được (củ/trái/con) trước, bí quá mới dùng "kg" hoặc "cái".

  QUY TẮC HẠN SỬ DỤNG (TÍNH TỪ ${today}):
  - Thịt/Cá tươi: +2 ngày.
  - Rau lá: +4 ngày.
  - Củ/Quả: +10 ngày.
  - Đồ khô: +6 tháng.

  OUTPUT JSON ARRAY:
  [{ 
    "name": "Tên tiếng Việt (Viết hoa chữ cái đầu)", 
    "category": "Thịt/Hải sản/Rau củ/Trái cây/Gia vị...", 
    "quantity": 1, 
    "unit": "củ/trái/con/bó/kg/hộp", 
    "weight": 0, 
    "calories": 100, 
    "expiryDate": "YYYY-MM-DD", 
    "storage": "Ngăn mát/Ngăn đông/Tủ bếp", 
    "image_url": "",
    "note": "Gợi ý bảo quản nhanh"
  }]
  `;
};

// 3. RECIPE SUGGESTION PROMPT (Đã Fix JSON Example để tránh lỗi)
const getRecipeSuggestionPrompt = (ingredients, userContext = "", excludedRecipes = [], count = 5) => {
  const listStr = Array.isArray(ingredients) ? ingredients.join(", ") : ingredients;
  
  const avoidStr = excludedRecipes.length > 0 
      ? `⛔️ TRÁNH TRÙNG: Không gợi ý các món: "${excludedRecipes.join(", ")}".` 
      : "";

  return `
  NGUYÊN LIỆU HIỆN CÓ: "${listStr}".
  CONTEXT: "${userContext}".
  
  VAI TRÒ: Bếp trưởng nhà hàng Cơm Niêu Việt Nam lâu năm.
  NHIỆM VỤ: Gợi ý ${count} món ăn ĐẬM CHẤT CƠM NHÀ, DÂN DÃ, HỢP KHẨU VỊ NGƯỜI VIỆT từ nguyên liệu trên.

  ${avoidStr}
  VAI TRÒ: Tổng quản bếp trưởng thực tế & thông minh.
  NHIỆM VỤ: Xây dựng thực đơn 4 món ngon, tối ưu hóa nguyên liệu đang có.

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

  ⚠️ YÊU CẦU BẮT BUỘC VỀ SỐ LIỆU (QUAN TRỌNG):
  1. THỜI GIAN NẤU: Phải ước lượng chính xác (VD: Trứng chiên 10 phút, Kho thịt 45 phút). KHÔNG mặc định 30 phút.
  2. DINH DƯỠNG: Phải ước tính con số cụ thể cho 1 khẩu phần ăn trung bình. TUYỆT ĐỐI KHÔNG ĐỂ 0. Nếu không rõ, hãy ước lượng dựa trên dữ liệu khoa học.
  3. ĐỘ KHÓ: Dễ / Trung bình / Khó.

  OUTPUT FORMAT (JSON ARRAY ONLY ):
  [
    {
      "name": "Tên món ăn (Tiếng Việt)",
      "description": "Mô tả ngắn hấp dẫn khoảng 20 từ.",
      "cooking_time": "15 phút", 
      "difficulty": "Dễ",
      "calories": 350, Lưu ý: phải tính kcalo ra
      "macros": { 
          "protein": 15, 
          "carbs": 40, 
          "fat": 10 
      },
      "all_ingredients": ["Nguyên liệu A", "Nguyên liệu B", "Gia vị cơ bản"],
      "ingredients_used": ["${listStr}"], 
      "ingredients_missing": ["Các loại rau thơm hoặc gia vị còn thiếu"], 
      "steps": [
        "Bước 1: Sơ chế nguyên liệu...", 
        "Bước 2: Chế biến...",
        "Bước 3: Hoàn thiện..."
      ],
      "chef_tips": "Mẹo nhỏ để món này ngon hơn (VD: Khử tanh bằng rượu...)"
    }
  ]
  `;
};


module.exports = { 
    getBarcodePrompt, 
    getImageScanPrompt, 
    getRecipeSuggestionPrompt
};