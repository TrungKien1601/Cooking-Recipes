const ScanService = require('../../services/user/scan.service'); 
const fs = require("fs").promises; 

// --- HELPER FUNCTIONS ---

// SỬA: Cập nhật logic lấy ID từ req.decoded (theo JwtUtils)
const getUserId = (req) => {
    // Ưu tiên lấy từ decoded token
    if (req.decoded && req.decoded._id) return req.decoded._id;
    // Fallback cho các trường hợp khác
    if (req.user && req.user.id) return req.user.id;
    if (req.user && req.user._id) return req.user._id;
    return null;
};

const isValidObjectId = (id) => {
    return id && /^[0-9a-fA-F]{24}$/.test(id);
};

const allowedImageTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'];
const MAX_IMAGE_SIZE = 10 * 1024 * 1024; 

// --- SCAN CONTROLLERS ---

exports.scanBarcode = async (req, res) => {
    const { barcode } = req.body;
    
    if (!barcode || barcode.trim().length === 0) {
        return res.status(400).json({ success: false, message: "Thiếu mã vạch" });
    }

    try {
        const data = await ScanService.processBarcodeScan(barcode.trim());

        if (!data || data.found === false) {
            return res.status(200).json({
                success: true,
                data: { found: false, name: "Không tìm thấy thông tin", is_food: false }
            });
        }

        return res.status(200).json({ success: true, data });

    } catch (error) {
        console.error("❌ ScanBarcode Error:", error);
        return res.status(500).json({ success: false, message: "Lỗi Server khi quét mã" });
    }
};

exports.scanImage = async (req, res) => {
    let imagePath = null;
    try {
        if (!req.file) {
            return res.status(400).json({ success: false, message: "Thiếu ảnh minh họa" });
        }
        
        imagePath = req.file.path;

        if (!allowedImageTypes.includes(req.file.mimetype)) {
            return res.status(400).json({ success: false, message: "Chỉ chấp nhận file ảnh (JPEG, PNG, WebP)" });
        }
        
        const ingredients = await ScanService.processImageScan(imagePath, req.file.mimetype);
        
        return res.status(200).json({ success: true, data: ingredients });

    } catch (error) {
        console.error("❌ ScanImage Error:", error);
        let message = "AI không đọc được ảnh này, thử ảnh khác xem!";
        if (error.message && error.message.includes("format")) {
            message = "Không nhận diện được thực phẩm trong ảnh";
        }
        return res.status(500).json({ success: false, message });
    } finally {
        if (imagePath) {
            await fs.unlink(imagePath).catch(() => {}); 
        }
    }
};

exports.uploadFoodImage = async (req, res) => {
    try {
        if (!req.file) return res.status(400).json({ success: false, message: 'Chưa chọn file' });

        if (!allowedImageTypes.includes(req.file.mimetype)) {
            await fs.unlink(req.file.path).catch(() => {});
            return res.status(400).json({ success: false, message: "Sai định dạng ảnh" });
        }

        return res.status(200).json({ 
            success: true, 
            message: "Upload thành công", 
            filePath: `uploads/${req.file.filename}` 
        });

    } catch (error) {
        console.error("❌ UploadFoodImage Error:", error);
        return res.status(500).json({ success: false, message: "Lỗi upload file" });
    }
};

// --- PANTRY CONTROLLERS ---

exports.addToPantry = async (req, res) => {
    try {
        const userId = getUserId(req);
        if (!userId) return res.status(401).json({ success: false, message: "Phiên đăng nhập hết hạn" }); 
        
        const { quantity, weight, masterIngredientId, name } = req.body;
        
        const hasIdentity = (name && name.trim().length > 0) || masterIngredientId;
        if (!hasIdentity) {
             return res.status(400).json({ success: false, message: "Vui lòng nhập tên món ăn!" });
        }
        
        const hasQuantity = quantity !== undefined && Number(quantity) > 0;
        if (!hasQuantity && (!weight || weight <= 0)) {
             return res.status(400).json({ success: false, message: "Cần nhập số lượng hoặc khối lượng" });
        }

        const newItem = await ScanService.addToPantry(userId, req.body);
        
        return res.status(201).json({
            success: true, 
            message: "Đã thêm vào tủ lạnh!", 
            data: newItem 
        });

    } catch (error) {
        console.error("❌ AddToPantry Error:", error);
        return res.status(500).json({ 
            success: false, 
            message: "Không thể lưu món này. " + (error.message || "") 
        });
    }
};

exports.getPantry = async (req, res) => {
    try {
        const userId = getUserId(req);
        if (!userId) return res.status(401).json({ success: false, message: "Chưa đăng nhập" });

        const formattedItems = await ScanService.getPantryItems(userId);
        
        return res.status(200).json({ success: true, data: formattedItems });

    } catch (error) {
        console.error("❌ GetPantry Error:", error);
        return res.status(500).json({ success: false, message: "Lỗi lấy danh sách tủ lạnh" });
    }
};

exports.updateItem = async (req, res) => {
    try {
        const userId = getUserId(req);
        const { id } = req.params;
        
        if (!userId) return res.status(401).json({ success: false, message: "Phiên đăng nhập hết hạn" });
        if (!isValidObjectId(id)) return res.status(400).json({ success: false, message: "ID không hợp lệ" });

        if (!req.body || Object.keys(req.body).length === 0) {
            return res.status(400).json({ success: false, message: "Không có dữ liệu để cập nhật" });
        }
        
        const updatedItem = await ScanService.updatePantryItem(userId, id, req.body);
        
        return res.status(200).json({ 
            success: true, 
            message: "Cập nhật thành công!", 
            data: updatedItem 
        });

    } catch (error) {
        console.error("❌ UpdateItem Error:", error);
        if (error.message === "Item not found") {
            return res.status(404).json({ success: false, message: "Món này không còn tồn tại" });
        }
        return res.status(500).json({ success: false, message: "Lỗi server khi cập nhật" });
    }
};

exports.deleteItem = async (req, res) => {
    try {
        const userId = getUserId(req);
        const { id } = req.params;
        
        if (!userId) return res.status(401).json({ success: false, message: "Phiên đăng nhập hết hạn" });
        if (!isValidObjectId(id)) return res.status(400).json({ success: false, message: "ID không hợp lệ" });
        
        const result = await ScanService.deletePantryItem(userId, id);
        
        if (!result) {
             return res.status(404).json({ success: false, message: "Không tìm thấy món cần xóa" });
        }
        
        return res.status(200).json({ success: true, message: "Đã xóa món ăn" });

    } catch (error) {
        console.error("❌ DeleteItem Error:", error);
        return res.status(500).json({ success: false, message: "Lỗi server khi xóa" });
    }
};

// --- RECIPE SUGGESTION & HISTORY ---

exports.suggestByIngredients = async (req, res) => {
    try {
        const { ingredients } = req.body;
        if (!ingredients || !Array.isArray(ingredients) || ingredients.length === 0) {
            return res.status(400).json({ success: false, message: "Cần nhập ít nhất 1 nguyên liệu" });
        }
        
        // SỬA: Trong service cũ chưa có getGuestSuggestions
        // Nếu bạn muốn dùng, hãy thêm hàm đó vào service.
        // Tạm thời mình trỏ nó về getUserSuggestions với userId giả hoặc xử lý lỗi
        if (typeof ScanService.getGuestSuggestions !== 'function') {
             // Fallback: Gọi hàm của user nhưng truyền userId null (nếu service hỗ trợ)
             // Hoặc báo lỗi để bạn biết đường thêm vào Service
             throw new Error("Tính năng gợi ý khách chưa được định nghĩa trong Service");
        }

        const data = await ScanService.getGuestSuggestions(ingredients);
        return res.status(200).json({ success: true, data: data || [] });
    } catch (error) {
        console.error("❌ Guest Suggestion Error:", error.message);
        return res.status(500).json({ success: false, message: "Đầu bếp AI đang bận hoặc tính năng chưa sẵn sàng" });
    }
};

exports.suggestRecipes = async (req, res) => {
    try {
        const userId = getUserId(req);
        if (!userId) return res.status(401).json({ success: false, message: "Vui lòng đăng nhập" });
        
        const { ingredients } = req.body; 
        const recipes = await ScanService.getUserSuggestions(userId, ingredients);
        
        return res.status(200).json({ success: true, data: recipes });
    } catch (error) {
        console.error("❌ SuggestRecipes Error:", error);
        let message = "Đầu bếp AI đang bận!";
        if (error.message.includes("empty")) message = "Tủ lạnh trống trơn! Hãy thêm đồ vào nhé.";
        return res.status(500).json({ success: false, message });
    }
};

exports.getRecipeHistory = async (req, res) => {
    try {
        const userId = getUserId(req);
        if (!userId) return res.status(401).json({ success: false, message: "Chưa đăng nhập" });
        const history = await ScanService.getHistory(userId);
        return res.status(200).json({ success: true, data: history });
    } catch (error) {
        return res.status(500).json({ success: false, message: "Lỗi server" });
    }
};

exports.clearRecipeHistory = async (req, res) => {
    try {
        const userId = getUserId(req);
        if (!userId) return res.status(401).json({ success: false, message: "Chưa đăng nhập" });
        const result = await ScanService.clearAllHistory(userId);
        return res.status(200).json({ success: true, message: `Đã xóa ${result.deletedCount} mục` });
    } catch (error) {
        return res.status(500).json({ success: false, message: "Lỗi server" });
    }
};

exports.deleteHistoryItems = async (req, res) => {
    try {
        const userId = getUserId(req);
        const { ids } = req.body;
        if (!userId) return res.status(401).json({ success: false, message: "Chưa đăng nhập" });
        if (!ids || !Array.isArray(ids) || ids.length === 0) return res.status(400).json({ success: false, message: "Chưa chọn mục xóa" });

        const result = await ScanService.deleteHistoryByIds(userId, ids);
        return res.status(200).json({ success: true, message: `Đã xóa ${result.deletedCount} mục` });
    } catch (error) {
        return res.status(500).json({ success: false, message: "Lỗi server" });
    }
};