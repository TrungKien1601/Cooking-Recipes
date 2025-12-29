const { GoogleGenerativeAI } = require("@google/generative-ai");
const fs = require("fs").promises; 
const axios = require('axios');
require("dotenv").config();
const PantryItem = require("../../models/PantryItem");
const ProductCache = require("../../models/ProductCache"); 
const RecipeHistory = require("../../models/RecipeHistory");
const MasterIngredient = require("../../models/MasterIngredients");
const { getBarcodePrompt, getImageScanPrompt, getRecipeSuggestionPrompt } = require("../../utils/scanPrompts");

// Config AI
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
const model = genAI.getGenerativeModel({ 
  model: "gemini-2.5-flash", 
  generationConfig: { responseMimeType: "application/json" },
});

// --- HELPER FUNCTIONS ---
const cleanAndParseJSON = (text) => {
    try {
        const cleanedText = text.replace(/```json|```/g, '').trim();
        return JSON.parse(cleanedText);
    } catch (error) {
        console.error("❌ JSON Parse Error:", text);
        return null; 
    }
};

// Map từ Enum tiếng Anh/Việt lộn xộn sang chuẩn
const mapStorageToVietnamese = (storageInput) => {
    if (!storageInput) return 'Ngăn mát';
    const s = storageInput.toString().toUpperCase().trim();
    if (s.includes('FREEZER') || s.includes('ĐÔNG')) return 'Ngăn đông';
    if (s.includes('PANTRY') || s.includes('BẾP') || s.includes('TỦ')) return 'Tủ bếp';
    return 'Ngăn mát'; 
};

const ScanService = {

    // 1. Process Barcode Scan
    async processBarcodeScan(barcode) {
        const cachedProduct = await ProductCache.findOne({ barcode });
        if (cachedProduct) {
            return { ...cachedProduct.toObject(), found: true, is_food: true, source: "Cache" };
        }

        let aiData = null; 
        let knownName = ""; 

        try {
            const apiResponse = await axios.get(
                `https://world.openfoodfacts.org/api/v0/product/${barcode}.json`, 
                { timeout: 3000 }
            );
            const data = apiResponse.data;
            if (data.status === 1 && data.product) { 
                const p = data.product;
                knownName = p.product_name_vi || p.product_name || "";
                aiData = {
                    found: true, 
                    is_food: true, 
                    name: knownName,
                    image_url: p.image_url || "",
                    unit: "cái",
                    source: "OpenFoodFacts"
                };
            }
        } catch (e) { 
            console.log("OpenFoodFacts API failed, falling back to Gemini");
        }

        if (!aiData) {
            const prompt = getBarcodePrompt(barcode, knownName); 
            const result = await model.generateContent(prompt);
            aiData = cleanAndParseJSON(result.response.text());
            if (aiData) aiData.source = "Gemini AI";
        }

        if (aiData && aiData.found !== false) {
            ProductCache.updateOne({ barcode }, { $set: aiData }, { upsert: true }).catch(() => {});
        }

        return aiData;
    },

    // 2. Process Image Scan
    async processImageScan(filePath, mimeType) {
        const imageBase64 = (await fs.readFile(filePath)).toString("base64");
        
        const result = await model.generateContent([
            getImageScanPrompt(), 
            { inlineData: { data: imageBase64, mimeType: mimeType } }
        ]);
        
        const ingredients = cleanAndParseJSON(result.response.text());
        if (!ingredients) throw new Error("AI format error");
        
        return ingredients;
    },

    // 3. Add to Pantry
    async addToPantry(userId, itemData) {
        let { 
            name, quantity, weight, unit, image_url, 
            calories, expiryDate, storage, note, addMethod,
            masterIngredientId 
        } = itemData;

        // A. Tìm hoặc tạo MasterIngredient
        let masterItem = null;
        if (masterIngredientId) {
            masterItem = await MasterIngredient.findById(masterIngredientId);
        } else if (name) {
            masterItem = await MasterIngredient.findOne({
                $or: [
                    { name: { $regex: new RegExp(`^${name}$`, 'i') } },
                    { synonyms: { $regex: new RegExp(`^${name}$`, 'i') } }
                ]
            });
        }
    
        if (!masterItem) {
            masterItem = await MasterIngredient.findOne({ name: "Other" }); 
            if (!masterItem) {
                masterItem = await MasterIngredient.create({
                    name: "Other", category: "Khác",
                    nutritionPer100g: { calories: 0, protein: 0, carbs: 0, fat: 0 }
                });
            }
        }

        // B. Tính Calories
        if ((!calories || calories === 0) && masterItem?.nutritionPer100g?.calories) {
            let totalGrams = 0;
            if (weight > 0) totalGrams = weight; 
            else if (['gram','ml','g'].includes(unit)) totalGrams = quantity;
            else totalGrams = (quantity || 1) * 100; 
            
            calories = Math.round((totalGrams / 100) * masterItem.nutritionPer100g.calories);
        }

        // C. Tạo Item
        const newItem = new PantryItem({
            user: userId,
            name: name || masterItem.name || "Món không tên", 
            masterIngredient: masterItem._id,
            quantity: Math.max(0, quantity || 1),
            weight: Math.max(0, weight || 0),
            unit: unit || 'cái',
            calories: Math.max(0, calories || 0),
            expiryDate: expiryDate ? new Date(expiryDate) : null,
            storage: mapStorageToVietnamese(storage),
            addMethod: addMethod || 'MANUAL',
            image_url: image_url || "",
            note: (note || "")
        });

        return await newItem.save();
    },

    // 4. Get Pantry Items
    async getPantryItems(userId) {
        const items = await PantryItem.find({ user: userId, quantity: { $gt: 0 } })
            .populate('masterIngredient', 'name category image nutritionPer100g synonyms') 
            .sort({ expiryDate: 1, createdAt: -1 });

        return items.map(item => {
            let daysLeft = null;
            if (item.expiryDate) {
                const now = new Date();
                const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
                const expiry = new Date(item.expiryDate.getFullYear(), item.expiryDate.getMonth(), item.expiryDate.getDate());
                const diffTime = expiry - today;
                daysLeft = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
            }

            let statusLabel = "GOOD";
            if (daysLeft !== null) {
                if (daysLeft < 0) statusLabel = "EXPIRED";
                else if (daysLeft <= 2) statusLabel = "WARNING";
            }

            return {
                ...item.toObject(),
                // Ưu tiên hiển thị tên riêng, nếu không có thì lấy tên Master
                name: item.name || item.masterIngredient?.name || "Món không tên",
                image_url: item.image_url || item.masterIngredient?.image || "",
                category: item.masterIngredient?.category || "Khácr",
                days_left: daysLeft,
                status_label: statusLabel
            };
        });
    },

    // 5. Update Pantry Item
    async updatePantryItem(userId, itemId, updates) {
        if (updates.storage) {
            updates.storage = mapStorageToVietnamese(updates.storage);
        }
        const item = await PantryItem.findOne({ _id: itemId, user: userId });
        if (!item) throw new Error("Item not found");

        Object.keys(updates).forEach((key) => {
            item[key] = updates[key];
        });

        await item.save();
        return item;
    },

    // 6. Delete Pantry Item
    async deletePantryItem(userId, itemId) {
        return await PantryItem.findOneAndDelete({ _id: itemId, user: userId });
    },

    // 7. Suggest Recipes (ĐÃ FIX: Ưu tiên tên user đặt để tránh lỗi "Other")
    async getUserSuggestions(userId, ingredientsInput) {
        let ingredientsListForAI = [];
        
        // Logic lấy nguyên liệu
        if (!ingredientsInput || ingredientsInput.length === 0) {
            const items = await PantryItem.find({ user: userId, quantity: { $gt: 0 } })
                .populate('masterIngredient', 'name synonyms');
            
            ingredientsListForAI = items.map(item => {
                // 👇 [FIX QUAN TRỌNG] Ưu tiên lấy tên user lưu (VD: "Bí đao") trước
                const finalName = item.name || item.masterIngredient?.name || "";
                const synonyms = item.masterIngredient?.synonyms || [];
                
                // Nếu Master là "Other", chỉ gửi tên finalName (Bí đao), không gửi chữ "Other"
                if (item.masterIngredient?.name === "Other") {
                    return finalName; 
                }

                return finalName + (synonyms.length ? ` (${synonyms.join(', ')})` : "");
            });
        } else {
            ingredientsListForAI = ingredientsInput;
        }
        
        console.log("Sending to AI:", ingredientsListForAI);

        // Gọi AI
        const prompt = getRecipeSuggestionPrompt(ingredientsListForAI, "");
        const result = await model.generateContent(prompt);
        const rawRecipes = cleanAndParseJSON(result.response.text());

        if (!rawRecipes) throw new Error("AI không trả về công thức nào hợp lệ");

        // Map dữ liệu để lưu DB
        const formattedRecipes = rawRecipes.map(r => {
            let fullDescription = r.description || "";
            if (r.difficulty) fullDescription += `\n(Độ khó: ${r.difficulty})`;
            if (r.chef_tips) fullDescription += `\n💡 Mẹo: ${r.chef_tips}`;

            return {
                name: r.name,
                description: fullDescription, 
                calories: Number(r.calories) || 0,
                cooking_time: r.cooking_time || "30 phút",
                
                // Trả về frontend dùng luôn
                difficulty: r.difficulty || "Trung bình",
                chef_tips: r.chef_tips || "",
                
                ingredients_used: r.ingredients_used || [],
                all_ingredients: r.all_ingredients || [],
                
                steps: r.steps || [],
                instructions: r.steps || [], 
                
                macros: {
                    protein: Number(r.macros?.protein) || 0,
                    carbs: Number(r.macros?.carbs) || 0,
                    fat: Number(r.macros?.fat) || 0
                },
                
                image_url: r.image_url || "" 
            };
        });

        // Lưu History
        RecipeHistory.create({ 
            user: userId, 
            recipes: formattedRecipes 
        }).catch(e => console.error("❌ History Save Error:", e.message));

        return formattedRecipes;
    },
    
    // 9, 10, 11 History
    async getHistory(userId) { return await RecipeHistory.find({ user: userId }).sort({ createdAt: -1 }); },
    async clearAllHistory(userId) { return await RecipeHistory.deleteMany({ user: userId }); },
    async deleteHistoryByIds(userId, ids) { return await RecipeHistory.deleteMany({ _id: { $in: ids }, user: userId }); }
};

module.exports = ScanService;