const ScanService = require('../../services/user/scan.service');
const fs = require("fs").promises;
const path = require('path');

// --- Helpers Utilities (Giống Recipe Controller) ---
const getUserId = (req) => req.decoded?._id || req.user?._id || req.user?.id;

const normalizeFilePath = (file) => {
    if (!file) return undefined;
    // Thay thế dấu \ (Windows) thành / và bỏ prefix public/ nếu có
    let path = file.path.replace(/\\/g, "/");
    return path.startsWith('public/') ? path.replace('public/', '') : path;
};

const isValidObjectId = (id) => {
    return id && /^[0-9a-fA-F]{24}$/.test(id);
};

// Config riêng cho Scan
const allowedImageTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'];

const scanController = {

    // 1. SCANNING FEATURES
    scanBarcode: async (req, res) => {
        try {
            const { barcode } = req.body;
            if (!barcode || barcode.trim().length === 0) {
                return res.status(400).json({ success: false, message: "Vui lòng cung cấp mã vạch" });
            }

            const data = await ScanService.processBarcodeScan(barcode.trim());

            if (!data || data.found === false) {
                return res.status(200).json({
                    success: true,
                    data: { found: false, name: "Không tìm thấy thông tin", is_food: false }
                });
            }

            return res.status(200).json({ success: true, data });
        } catch (error) {
            console.error("Scan Barcode Error:", error);
            return res.status(500).json({ success: false, message: "Lỗi hệ thống khi quét mã" });
        }
    },

    scanImage: async (req, res) => {
        let imagePath = null;
        try {
            if (!req.file) {
                return res.status(400).json({ success: false, message: "Vui lòng chụp hoặc chọn ảnh" });
            }
            
            imagePath = req.file.path; // Giữ path gốc để xóa sau khi scan

            if (!allowedImageTypes.includes(req.file.mimetype)) {
                return res.status(400).json({ success: false, message: "Chỉ chấp nhận ảnh (JPG, PNG, WebP)" });
            }

            const ingredients = await ScanService.processImageScan(imagePath, req.file.mimetype);
            
            return res.status(200).json({ 
                success: true, 
                message: "Nhận diện thành công",
                data: ingredients 
            });

        } catch (error) {
            console.error("Scan Image Error:", error);
            let message = "AI đang bận, vui lòng thử lại ảnh rõ nét hơn!";
            if (error.message.includes("format") || error.message.includes("AI format")) {
                message = "Không nhận diện được thực phẩm nào trong ảnh.";
            }
            return res.status(500).json({ success: false, message });
        } finally {
            // Logic dọn dẹp file tạm (khác Recipe vì Recipe cần lưu file, Scan thì không)
            if (imagePath) {
                await fs.unlink(imagePath).catch((err) => console.warn("⚠️ File cleanup warning:", err.message)); 
            }
        }
    },

    // 2. UPLOADS (Helpers)
    uploadFoodImage: async (req, res) => {
        try {
            if (!req.file) return res.status(400).json({ success: false, message: 'Chưa chọn file' });

            if (!allowedImageTypes.includes(req.file.mimetype)) {
                // Xóa file nếu sai định dạng
                await fs.unlink(req.file.path).catch(() => {});
                return res.status(400).json({ success: false, message: "Định dạng ảnh không hỗ trợ" });
            }

            const clientPath = normalizeFilePath(req.file);
            return res.status(200).json({ 
                success: true, 
                message: "Upload thành công", 
                filePath: clientPath 
            });

        } catch (error) {
            return res.status(500).json({ success: false, message: error.message });
        }
    },

    uploadMultipleFoods: async (req, res) => {
        try {
            if (!req.files || req.files.length === 0) {
                return res.status(400).json({ success: false, message: 'Chưa gửi file ảnh nào' });
            }
            
            const filePaths = req.files.map(file => normalizeFilePath(file));
            
            return res.status(200).json({
                success: true,
                message: `Đã upload ${filePaths.length} ảnh`,
                filePaths: filePaths 
            });
        } catch (error) {
            return res.status(500).json({ success: false, message: error.message });
        }
    },

    // 3. PANTRY MANAGEMENT (CRUD)
    addToPantry: async (req, res) => {
        try {
            const userId = getUserId(req);
            if (!userId) return res.status(401).json({ success: false, message: "Phiên đăng nhập hết hạn" }); 
            
            const { name, masterIngredientId } = req.body;
            
            const hasIdentity = (name && name.trim().length > 0) || masterIngredientId;
            if (!hasIdentity) {
                 return res.status(400).json({ success: false, message: "Tên món ăn không được để trống" });
            }

            const newItem = await ScanService.addToPantry(userId, req.body);
            return res.status(201).json({
                success: true, 
                message: "Đã thêm vào tủ bếp!", 
                data: newItem 
            });

        } catch (error) {
            console.error("Add Pantry Error:", error);
            return res.status(500).json({ success: false, message: "Không thể lưu món này. Vui lòng thử lại." });
        }
    },

    getPantry: async (req, res) => {
        try {
            const userId = getUserId(req);
            if (!userId) return res.status(401).json({ success: false, message: "Chưa đăng nhập" });

            const formattedItems = await ScanService.getPantryItems(userId);
            return res.status(200).json({ success: true, data: formattedItems });
        } catch (error) {
            return res.status(500).json({ success: false, message: error.message });
        }
    },

    updateItem: async (req, res) => {
        try {
            const userId = getUserId(req);
            const { id } = req.params;
            
            if (!userId) return res.status(401).json({ success: false, message: "Phiên đăng nhập hết hạn" });
            if (!isValidObjectId(id)) return res.status(400).json({ success: false, message: "ID sản phẩm không hợp lệ" });
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
            if (error.message === "Item not found") {
                return res.status(404).json({ success: false, message: "Món này không còn trong tủ" });
            }
            return res.status(500).json({ success: false, message: error.message });
        }
    },

    deleteItem: async (req, res) => {
        try {
            const userId = getUserId(req);
            const { id } = req.params;

            if (!userId) return res.status(401).json({ success: false, message: "Phiên đăng nhập hết hạn" });
            if (!isValidObjectId(id)) return res.status(400).json({ success: false, message: "ID không hợp lệ" });
            
            const result = await ScanService.deletePantryItem(userId, id);
            if (!result) {
                 return res.status(404).json({ success: false, message: "Không tìm thấy món cần xóa" });
            }
            return res.status(200).json({ success: true, message: "Đã xóa thành công" });
        } catch (error) {
            return res.status(500).json({ success: false, message: error.message });
        }
    },

    // 4. RECIPE SUGGESTIONS
    suggestByIngredients: async (req, res) => {
        try {
            // Cho Guest (Không cần login)
            const { ingredients } = req.body; 
            
            if (!ingredients || !Array.isArray(ingredients) || ingredients.length === 0) {
                return res.status(400).json({ success: false, message: "Hãy nhập ít nhất 1 nguyên liệu" });
            }
            
            const recipes = await ScanService.getUserSuggestions(null, ingredients);
            return res.status(200).json({ success: true, data: recipes || [] });
        } catch (error) {
            console.error("Guest Suggestion Error:", error);
            return res.status(500).json({ success: false, message: "Đầu bếp AI đang bận, thử lại sau nhé!" });
        }
    },

    suggestRecipes: async (req, res) => {
        try {
            const userId = getUserId(req);
            if (!userId) return res.status(401).json({ success: false, message: "Vui lòng đăng nhập" });
            
            const { ingredients } = req.body; 
            const recipes = await ScanService.getUserSuggestions(userId, ingredients);
            
            return res.status(200).json({ success: true, data: recipes });
        } catch (error) {
            let message = "Đầu bếp AI đang bận!";
            if (error.message && error.message.includes("empty")) {
                message = "Tủ lạnh của bạn đang trống! Hãy thêm nguyên liệu vào trước nhé.";
            }
            return res.status(500).json({ success: false, message });
        }
    },

    // 5. HISTORY MANAGEMENT
    getRecipeHistory: async (req, res) => {
        try {
            const userId = getUserId(req);
            if (!userId) return res.status(401).json({ success: false, message: "Chưa đăng nhập" });
            
            const history = await ScanService.getHistory(userId);
            return res.status(200).json({ success: true, data: history });
        } catch (error) {
            return res.status(500).json({ success: false, message: error.message });
        }
    },

    clearRecipeHistory: async (req, res) => {
        try {
            const userId = getUserId(req);
            if (!userId) return res.status(401).json({ success: false, message: "Chưa đăng nhập" });
            
            await ScanService.clearAllHistory(userId);
            return res.status(200).json({ success: true, message: "Đã dọn sạch lịch sử" });
        } catch (error) {
            return res.status(500).json({ success: false, message: error.message });
        }
    },

    deleteHistoryItems: async (req, res) => {
        try {
            const userId = getUserId(req);
            const { ids } = req.body;
            
            if (!userId) return res.status(401).json({ success: false, message: "Chưa đăng nhập" });
            if (!ids || !Array.isArray(ids) || ids.length === 0) {
                return res.status(400).json({ success: false, message: "Chưa chọn mục xóa" });
            }

            const result = await ScanService.deleteHistoryByIds(userId, ids);
            return res.status(200).json({ success: true, message: `Đã xóa ${result.deletedCount} mục` });
        } catch (error) {
            return res.status(500).json({ success: false, message: error.message });
        }
    }
};

module.exports = scanController;