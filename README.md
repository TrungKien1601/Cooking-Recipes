# 🍳 Cooking Recipes App - Trợ lý ẩm thực thông minh

![Banner](https://placehold.co/800x400/568C4C/FFFFFF?text=Cooking+Recipes+App)

> Ứng dụng di động giúp bạn giải quyết câu hỏi "Hôm nay ăn gì?" và quản lý nguyên liệu tủ lạnh thông minh với sự hỗ trợ của Trí tuệ nhân tạo (AI).

## ✨ Tính năng nổi bật

* 🤖 **Đầu bếp AI thông minh:** Quét hình ảnh nguyên liệu bằng camera và tự động nhận diện món đồ bằng Google Gemini AI.
* 🧊 **Quản lý tủ lạnh (Pantry):** Theo dõi hạn sử dụng nguyên liệu, cảnh báo sắp hết hạn (Xanh/Vàng/Đỏ).
* 💡 **Gợi ý món ăn siêu tốc:** Tự động đề xuất thực đơn 5 món dựa trên chính xác những nguyên liệu bạn đang có trong tủ lạnh.
* 📚 **Cộng đồng chia sẻ:** Đăng tải, duyệt và chia sẻ công thức nấu ăn với cộng đồng.
* 📊 **Tính toán dinh dưỡng:** Tự động tính toán lượng Calo và Macros (Protein, Carbs, Fat) cho từng khẩu phần ăn.
* 📱 **Trải nghiệm mượt mà:** Tính năng cuộn vô hạn (Infinite Scrolling), đánh dấu lưu công thức (Bookmark) và xem lịch sử quét AI.

## 🛠 Công nghệ sử dụng

**Frontend (Mobile App):**
* [Flutter](https://flutter.dev/) & Dart
* Quản lý State: (Điền state management bạn dùng, vd: Provider / GetX / setState)
* Packages: `http`, `shared_preferences`, `google_fonts`...

**Backend (API Server):**
* [Node.js](https://nodejs.org/) & [Express.js](https://expressjs.com/)
* Database: [MongoDB](https://www.mongodb.com/) & Mongoose
* AI Integration: Google Generative AI (Gemini 2.5 Flash)
* Image Processing: Multer, Form-data

## 🚀 Hướng dẫn cài đặt (Chạy ở môi trường Local)

### Yêu cầu hệ thống:
* Flutter SDK (>= 3.0.0)
* Node.js (>= 16.x)
* MongoDB (Local hoặc Atlas)
* Tài khoản Google AI Studio (để lấy API Key)

### 1. Cài đặt Backend
\`\`\`bash
# Di chuyển vào thư mục server
cd server

# Cài đặt các thư viện
npm install

# Tạo file .env và điền các thông tin sau:
# PORT=3000
# MONGODB_URI=your_mongodb_connection_string
# GEMINI_API_KEY=your_gemini_api_key

# Khởi động server
npm start
\`\`\`

### 2. Cài đặt Frontend (Flutter App)
\`\`\`bash
# Di chuyển vào thư mục app
cd app

# Tải các packages
flutter pub get

# Lưu ý: Đổi URL API trong file `lib/services/recipe_service.dart` thành IP máy bạn hoặc ngrok URL.
# Ví dụ: static const String domain = "http://192.168.x.x:3000";

# Chạy ứng dụng
flutter run
\`\`\`

## 📸 Ảnh chụp màn hình (Screenshots)

| Trang chủ | Quản lý tủ lạnh | Gợi ý AI |
| :---: | :---: | :---: |
| <img src="link_anh_trang_chu.jpg" width="200"/> | <img src="link_anh_tu_lanh.jpg" width="200"/> | <img src="link_anh_ai.jpg" width="200"/> |

*(Ghi chú: Cập nhật đường dẫn ảnh thực tế của ứng dụng vào đây)*

## 👥 Nhóm phát triển

* **Nguyễn Trung Kiên** - *Developer* - [GitHub](https://github.com/your-username)
* **Lương Nhật Quang** - *Developer* - [GitHub](https://github.com/your-username)

Đồ án tốt nghiệp năm 2025 - Trường Đại học Văn Lang.

## 📄 Giấy phép (License)
Dự án này được cấp phép theo giấy phép MIT - xem file [LICENSE](LICENSE) để biết thêm chi tiết.
