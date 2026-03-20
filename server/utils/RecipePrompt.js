const getNutritionAnalysisPrompt = (ingredients, servings = 1) => {
  const ingredientsText = ingredients.map(i => {
    // Ép kiểu số cho an toàn
    const weight = parseFloat(i.weight) || 0;
    const quantity = parseFloat(i.quantity) || 0;
    let unit = i.unit ? i.unit.trim() : '';

    if (weight > 0) {
       // Nếu user quên nhập đơn vị cho khối lượng, mặc định là 'g'
       if (!unit) unit = 'g'; 
       return `- ${weight}${unit} ${i.name}`;
    }
    if (quantity > 0) {
       return `- ${quantity} ${unit} ${i.name}`;
    }
    return `- ${i.name}`;
  }).join('\n');

  return `
    Bạn là chuyên gia dinh dưỡng chuyên nghiệp. Hãy phân tích danh sách nguyên liệu dưới đây:
    ${ingredientsText}

    Thông tin bổ sung: Món ăn này dành cho ${servings} người ăn.

    Yêu cầu tính toán:
    1. Đầu tiên, tính TỔNG dinh dưỡng của toàn bộ nguyên liệu trên dựa theo cơ sở dữ liệu chuẩn (như USDA). 
       *Lưu ý quan trọng*: 
       - Nếu đơn vị là 'g' hoặc 'gram', hãy tính chính xác theo khối lượng.
       - Nếu đơn vị là ĐỊNH TÍNH (ví dụ: củ, trái, quả, thìa, muỗng, bát, chén...), hãy tự ước lượng khối lượng trung bình thực tế (VD: 1 củ khoai tây ~ 150g).
       - Nếu không có khối lượng, hãy ước lượng trung bình theo số lượng (VD: 1 quả trứng ~ 50g).
       - Đừng phóng đại số liệu. Ví dụ: Thịt ba rọi (Pork Belly) sống trung bình khoảng 518 calo/100g.
       
    2. Sau đó, CHIA TỔNG ĐÓ cho ${servings} để ra dinh dưỡng cho 1 KHẨU PHẦN (1 người ăn).
    
    Output bắt buộc (JSON thuần, chỉ trả về số liệu CHO 1 NGƯỜI ĂN):
    {
      "calories": number, // Calo cho 1 người (Làm tròn số nguyên)
      "protein": number,  // Grams
      "carbs": number,    // Grams
      "fat": number,      // Grams
      "sodium": number,   // Milligrams
      "sugars": number    // Grams
    }

    Nếu không xác định được, trả về 0. Không giải thích thêm, chỉ trả về JSON.
  `;
};

module.exports = { getNutritionAnalysisPrompt };