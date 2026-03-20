import { useEffect, useState, useMemo } from "react";
import axios from "axios";
import { useAuth } from "../../hooks/AuthProvider";
import { useModal } from "../../hooks/useModal";
import TableActionMenu from "./Action/TableActionMenu";

// UI Components
import {
  Table,
  TableBody,
  TableCell,
  TableHeader,
  TableRow,
} from "../ui/table";
import { 
  PlusIcon,
  ChevronLeftIcon,
  TrashBinIcon,
} from "../../icons";
import Badge from "../ui/badge/Badge";
import { Modal } from "../ui/modal";
import Input from "../form/input/InputField";
import Label from "../form/Label";
import Button from "../ui/button/Button";
import Select from "../form/Select";
import { Dropdown } from "../ui/dropdown/Dropdown";
import Checkbox from "../form/input/Checkbox";

// --- CẤU HÌNH URL ---
const BASE_MEDIA_URL = "http://localhost:5000/";

export default function Recipes() {
  const { user } = useAuth();
  const { isOpen: modalIsOpen, openModal, closeModal } = useModal();
  const [isLoading, setIsLoading] = useState(false);
  const isAdmin = user.role && user.role._id === 1; 
  const token = localStorage.getItem('admin_token') || sessionStorage.getItem('admin_token');

  // --- DATA STATE ---
  const [recipeData, setRecipeData] = useState([]);
  const [masterIngredients, setMasterIngredients] = useState([]); 
  const [tagsData, setTagsData] = useState([]); 
  const [searchTerm, setSearchTerm] = useState('');
  const [filterStatus, setFilterStatus] = useState([]);
  const [isOpenFilter, setIsOpenFilter] = useState(false);

  // --- FORM STATE ---
  const initialFormState = {
    id: "",
    name: "",
    description: "",
    servings: 1,
    cookTimeMinutes: 0,
    difficulty: "Trung bình",
    status: "Đã duyệt",
    ingredients: [], 
    steps: [],       
    nutritionAnalysis: { calories: 0, protein: 0, fat: 0, carbs: 0 },
    mealTimeTags: [],
    dietTags: [],
    regionTags: [],
    dishtypeTags: [],
    imageFile: null, 
    videoFile: null, 
    imagePreview: "", 
    videoPreview: "", 
  };

  const [formData, setFormData] = useState(initialFormState);

  const difficultyOptions = [
    { value: "Dễ", label: "Dễ" },
    { value: "Trung bình", label: "Trung bình" },
    { value: "Khó", label: "Khó" },
  ];

  const statusOptions = [
    { value: "Chờ duyệt", label: "Chờ duyệt" },
    { value: "Đã duyệt", label: "Đã duyệt" },
    { value: "Từ chối", label: "Từ chối" },
  ];

  // ==========================================
  // 1. LOGIC API
  // ==========================================

  const apiLoadRecipes = async () => {
    try {
      setIsLoading(true);
      const config = { headers: { "x-access-token": token } };
      const res = await axios.get('/api/admin/recipe', config);
      const result = res.data;
      setRecipeData(result.success ? (result.recipes || []) : []);
    } catch (err) {
      console.error("Lỗi lấy dữ liệu recipe:", err);
      setRecipeData([]);
    } finally {
      setIsLoading(false);
    }
  };

  const apiLoadMasterIngredients = async () => {
    try {
        const config = { headers: { "x-access-token": token } };
        const res = await axios.get('/api/admin/ingredient', config); 
        if(res.data.success) {
            setMasterIngredients(res.data.ingredients || []); 
        }
    } catch (err) {
        console.error("Lỗi tải nguyên liệu kho:", err);
    }
  }

  const apiLoadTags = async () => {
    try {
        const config = { headers: { "x-access-token": token } };
        const res = await axios.get('/api/admin/tag', config); 
        if(res.data.success) {
            setTagsData(res.data.tags || []); 
        }
    } catch (err) {
        console.error("Lỗi tải tags:", err);
    }
  }

  const categorizedTags = useMemo(() => {
    if (!tagsData || tagsData.length === 0) return {};
    const categorized = {};
    tagsData.forEach(tag => {
      if (!categorized[tag.type]) {
        categorized[tag.type] = [];
      }
      categorized[tag.type].push(tag);
    });
    return categorized;
  }, [tagsData]);

  useEffect(() => {
    apiLoadRecipes();
    apiLoadMasterIngredients();
    apiLoadTags();
  }, []);

  const apiDeleteRecipe = async (id) => {
    if (!window.confirm("Bạn có chắc muốn xoá món ăn này?")) return;
    try {
      const config = { headers: { "x-access-token": token } };
      const res = await axios.delete(`/api/admin/recipe/${id}`, config);
      if (res.data.success) {
        alert("Xoá thành công");
        apiLoadRecipes();
      } else {
        alert(res.data.message);
      }
    } catch (err) {
      console.error(err);
      alert("Lỗi khi xoá");
    }
  };

  // ==========================================
  // 2. LOGIC TỰ ĐỘNG TÍNH DINH DƯỠNG
  // ==========================================

  const calculateNutrition = (ingredientsList, servings) => {
    let totalCals = 0;
    let totalPro = 0;
    let totalFat = 0;
    let totalCarbs = 0;

    // Phân tích từng nguyên liệu trong form
    ingredientsList.forEach(ing => {
        // Chỉ tính khi nguyên liệu đó đã chọn ID từ kho Master
        if (ing.masterIngredient) {
            const masterData = masterIngredients.find(m => m._id === ing.masterIngredient);
            
            if (masterData && masterData.nutritionPer100g) {
                // Xác định khối lượng tính toán. 
                // Mặc định công thức nutritionPer100g là tính cho 100 gam.
                let weightInGrams = Number(ing.quantity) || 0;
                
                // (Mở rộng tuỳ chọn) Nếu bạn có hệ số chuyển đổi các đơn vị khác như 'muỗng', 'quả' sang 'gam'
                // thì có thể thêm logic ở đây. Tạm thời nếu khác g/ml thì giữ nguyên giá trị quantity.
                
                // Công thức: (Hàm lượng trong 100g) * (Khối lượng thực tế / 100)
                const multiplier = weightInGrams / 100;

                totalCals += (masterData.nutritionPer100g.calories || 0) * multiplier;
                totalPro += (masterData.nutritionPer100g.protein || 0) * multiplier;
                totalFat += (masterData.nutritionPer100g.fat || 0) * multiplier;
                totalCarbs += (masterData.nutritionPer100g.carbs || 0) * multiplier;
            }
        }
    });

    // Chia cho số khẩu phần (servings) để ra dinh dưỡng trên 1 khẩu phần (như thiết kế UI ghi 'trên khẩu phần')
    const servingDivider = Number(servings) > 0 ? Number(servings) : 1;

    return {
        calories: Number((totalCals / servingDivider).toFixed(1)),
        protein: Number((totalPro / servingDivider).toFixed(1)),
        fat: Number((totalFat / servingDivider).toFixed(1)),
        carbs: Number((totalCarbs / servingDivider).toFixed(1))
    };
  };

  // Effect chạy mỗi khi thay đổi danh sách nguyên liệu hoặc số khẩu phần
  useEffect(() => {
    if (masterIngredients.length > 0 && formData.ingredients.length >= 0) {
        const newNutrition = calculateNutrition(formData.ingredients, formData.servings);
        
        // Cập nhật state nếu có sự thay đổi để tránh loop re-render
        setFormData(prev => {
            if (prev.nutritionAnalysis.calories !== newNutrition.calories ||
                prev.nutritionAnalysis.protein !== newNutrition.protein ||
                prev.nutritionAnalysis.fat !== newNutrition.fat ||
                prev.nutritionAnalysis.carbs !== newNutrition.carbs) {
                return { ...prev, nutritionAnalysis: newNutrition };
            }
            return prev;
        });
    }
  }, [formData.ingredients, formData.servings, masterIngredients]);


  // ==========================================
  // 3. LOGIC XỬ LÝ FORM 
  // ==========================================

  const prepareRecipeFormData = () => {
    if (!formData.name) { alert("Vui lòng nhập tên món ăn"); return null; }
    if (formData.ingredients.length === 0) { alert("Vui lòng thêm ít nhất 1 nguyên liệu"); return null; }
    if (formData.steps.length === 0) { alert("Vui lòng thêm ít nhất 1 bước làm"); return null; }

    const cleanIngredients = formData.ingredients.map(ing => ({
        name: ing.name,
        quantity: Number(ing.quantity) || 0,
        unit: ing.unit,
        masterIngredient: ing.masterIngredient
    }));

    const cleanNutrition = {
        calories: Number(formData.nutritionAnalysis.calories) || 0,
        protein: Number(formData.nutritionAnalysis.protein) || 0,
        fat: Number(formData.nutritionAnalysis.fat) || 0,
        carbs: Number(formData.nutritionAnalysis.carbs) || 0,
    };

    const data = new FormData();
    data.append('name', formData.name);
    data.append('description', formData.description);
    data.append('servings', formData.servings);
    data.append('cookTimeMinutes', formData.cookTimeMinutes);
    data.append('difficulty', formData.difficulty);
    data.append('status', formData.status);
    
    data.append('ingredients', JSON.stringify(cleanIngredients));
    data.append('steps', JSON.stringify(formData.steps));
    data.append('nutritionAnalysis', JSON.stringify(cleanNutrition));
    
    data.append('mealTimeTags', JSON.stringify(formData.mealTimeTags));
    data.append('dietTags', JSON.stringify(formData.dietTags));
    data.append('regionTags', JSON.stringify(formData.regionTags));
    data.append('dishtypeTags', JSON.stringify(formData.dishtypeTags));

    if (formData.imageFile) data.append('image', formData.imageFile);
    if (formData.videoFile) data.append('video', formData.videoFile);

    return data;
  };

  const handleCreateRecipe = async () => {
    if (!formData.imageFile && !formData.imagePreview) { alert("Vui lòng chọn ảnh món ăn"); return; }
    const data = prepareRecipeFormData();
    if (!data) return; 

    try {
      const config = { headers: { "x-access-token": token, "Content-Type": "multipart/form-data" } };
      const res = await axios.post('/api/admin/recipe', data, config);
      if (res.data.success) {
        alert("Thêm mới thành công");
        closeModalAndReset();
        apiLoadRecipes();
      } else { alert(res.data.message); }
    } catch (err) { alert("Có lỗi xảy ra: " + (err.response?.data?.message || err.message)); }
  };

  const handleUpdateRecipe = async () => {
    const data = prepareRecipeFormData();
    if (!data) return; 

    try {
      const config = { headers: { "x-access-token": token, "Content-Type": "multipart/form-data" } };
      const res = await axios.put(`/api/admin/recipe/${formData.id}`, data, config);
      if (res.data.success) {
        alert("Cập nhật thành công");
        closeModalAndReset();
        apiLoadRecipes();
      } else { alert(res.data.message); }
    } catch (err) { alert("Có lỗi xảy ra: " + (err.response?.data?.message || err.message)); }
  };

  const handleSubmit = (e) => { e.preventDefault(); if (formData.id) { handleUpdateRecipe(); } else { handleCreateRecipe(); } };

  // ==========================================
  // 4. UI HANDLERS
  // ==========================================

  const closeModalAndReset = () => { setFormData(initialFormState); closeModal(); };

  const handleOpenEdit = (id) => {
    const item = recipeData.find(r => r._id === id);
    if (!item) return;

    setFormData({
      id: item._id,
      name: item.name,
      description: item.description || "",
      servings: item.servings || 1,
      cookTimeMinutes: item.cookTimeMinutes || 0,
      difficulty: item.difficulty || "Trung bình",
      status: item.status || "Đã duyệt",
      ingredients: item.ingredients.map(ing => ({
          name: ing.name,
          quantity: ing.quantity,
          unit: ing.unit,
          masterIngredient: ing.masterIngredient?._id || ing.masterIngredient || ""
      })) || [],
      steps: item.steps || [],
      nutritionAnalysis: item.nutritionAnalysis || { calories: 0, protein: 0, fat: 0, carbs: 0 },
      
      mealTimeTags: item.mealTimeTags?.map(t => t?._id || t) || [],
      dietTags: item.dietTags?.map(t => t?._id || t) || [],
      regionTags: item.regionTags?.map(t => t?._id || t) || [],
      dishtypeTags: item.dishtypeTags?.map(t => t?._id || t) || [],

      imageFile: null, videoFile: null,
      imagePreview: item.image || "", videoPreview: item.video || "",
    });
    openModal();
  };

  const handleInputChange = (field, value) => { setFormData(prev => ({ ...prev, [field]: value })); };

  const handleFileChange = (e, field) => {
    const file = e.target.files[0];
    if (file) {
      const previewUrl = URL.createObjectURL(file);
      setFormData(prev => ({ ...prev, [field]: file, [(field === 'imageFile' ? 'imagePreview' : 'videoPreview')]: previewUrl }));
    }
  };

  const addToArray = (field, newItem) => { setFormData(prev => ({ ...prev, [field]: [...prev[field], newItem] })); };
  
  const removeFromArray = (field, index) => {
    setFormData(prev => { const newArr = [...prev[field]]; newArr.splice(index, 1); return { ...prev, [field]: newArr }; });
  };
  
  const updateArrayItem = (field, index, subField, value) => {
    setFormData(prev => {
        const newArr = [...prev[field]];
        if(field === 'ingredients' && subField === 'masterIngredient') {
            newArr[index]['masterIngredient'] = value;
            const selectedMaster = masterIngredients.find(m => m._id === value);
            if(selectedMaster) { newArr[index]['name'] = selectedMaster.name; }
        } else if (subField) {
            newArr[index][subField] = value;
        } else {
            newArr[index] = { ...newArr[index], description: value }; 
        }
        return { ...prev, [field]: newArr };
    });
  };

  const handleTagToggle = (tagCategory, tagId) => {
    setFormData(prev => {
      const currentTags = prev[tagCategory];
      if (currentTags.includes(tagId)) {
        return { ...prev, [tagCategory]: currentTags.filter(id => id !== tagId) };
      } else {
        return { ...prev, [tagCategory]: [...currentTags, tagId] };
      }
    });
  };

  const filteredData = useMemo(() => {
    return recipeData.filter(item => {
      const matchSearch = item.name.toLowerCase().includes(searchTerm.toLowerCase());
      const matchStatus = filterStatus.length === 0 || filterStatus.includes(item.status);
      return matchSearch && matchStatus;
    });
  }, [recipeData, searchTerm, filterStatus]);

  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 10;
  const totalPages = Math.ceil(filteredData.length / itemsPerPage) || 1;
  
  useEffect(() => { setCurrentPage(1); }, [searchTerm, filterStatus]);

  const currentItems = filteredData.slice((currentPage - 1) * itemsPerPage, currentPage * itemsPerPage);

  const tagCategoriesList = [
    { label: "Bữa ăn", type: 'Giờ ăn', field: "mealTimeTags" },
    { label: "Chế độ ăn", type: 'Chế độ ăn kiêng', field: "dietTags" },
    { label: "Vùng miền", type: 'Vùng miền', field: "regionTags" },
    { label: "Loại món", type: 'Cách chế biến', field: "dishtypeTags" },
  ];

  // ==========================================
  // RENDER
  // ==========================================

  return (
    <div className="max-w-full overflow-hidden rounded-2xl border border-gray-200 bg-white px-4 pb-3 pt-4 dark:border-gray-800 dark:bg-white/[0.03] sm:px-6">
      
      {/* HEADER DANH SÁCH */}
      <div className="flex flex-col gap-2 mb-4 sm:flex-row sm:items-center sm:justify-between">
        <h3 className="text-lg font-semibold text-gray-800 dark:text-white/90">Quản lý công thức</h3>
        <div className="flex-1 max-w-md mx-4">
          <div className="relative">
             <input type="text" placeholder="Tìm kiếm theo tên món..." value={searchTerm} onChange={(e) => setSearchTerm(e.target.value)}
                className="dark:bg-dark-900 h-10 w-full rounded-lg border border-gray-200 bg-transparent py-2 pl-4 pr-10 text-sm focus:border-brand-300 focus:outline-none focus:ring focus:ring-brand-500/10 dark:border-gray-800 dark:text-white/90" />
          </div>
        </div>
        <div className="flex items-center gap-3">
          <button onClick={() => { setFormData(initialFormState); openModal(); }} className="inline-flex items-center gap-1 rounded-lg bg-brand-500 px-4 py-2.5 text-sm font-medium text-white hover:bg-brand-600 transition">
            <PlusIcon /> Thêm món
          </button>
          <div className="relative">
            <button onClick={() => setIsOpenFilter(!isOpenFilter)} className={`inline-flex items-center gap-2 rounded-lg border px-4 py-2.5 text-sm font-medium hover:bg-gray-50 dark:hover:bg-white/[0.03] ${filterStatus.length > 0 ? "border-brand-500 text-brand-500 bg-brand-50 dark:bg-brand-500/10" : "border-gray-300 text-gray-700 bg-white dark:border-gray-700 dark:bg-gray-800 dark:text-gray-400"}`}>
              Lọc Status
            </button>
            <Dropdown isOpen={isOpenFilter} onClose={() => setIsOpenFilter(false)} className="absolute right-0 z-50 mt-2 w-48 rounded-xl border border-gray-200 bg-white p-2 shadow-lg dark:bg-gray-900 dark:border-gray-700">
               {statusOptions.map(opt => (
                 <label key={opt.value} className="flex items-center gap-2 px-3 py-2 cursor-pointer hover:bg-gray-100 rounded dark:hover:bg-gray-800">
                   <Checkbox checked={filterStatus.includes(opt.value)} onChange={() => { setFilterStatus(prev => prev.includes(opt.value) ? prev.filter(p => p !== opt.value) : [...prev, opt.value]); }} />
                   <span className="text-sm dark:text-gray-300">{opt.label}</span>
                 </label>
               ))}
            </Dropdown>
          </div>
        </div>
      </div>

      {/* TABLE */}
      <div className="overflow-x-auto rounded-xl border border-gray-200 bg-white dark:border-gray-800 dark:bg-gray-900">
        <Table>
          <TableHeader className="bg-gray-50 dark:bg-gray-800">
            <TableRow>
              <TableCell isHeader className="px-5 py-3 font-medium text-gray-500 text-start text-theme-sm dark:text-gray-400">Món ăn</TableCell>
              <TableCell isHeader className="px-5 py-3 font-medium text-gray-500 text-start text-theme-sm dark:text-gray-400">Tác giả</TableCell>
              <TableCell isHeader className="px-5 py-3 font-medium text-gray-500 text-center text-theme-sm dark:text-gray-400">Thông tin</TableCell>
              <TableCell isHeader className="px-5 py-3 font-medium text-gray-500 text-center text-theme-sm dark:text-gray-400">Trạng thái</TableCell>
              <TableCell isHeader className="px-5 py-3 font-medium text-gray-500 text-start text-theme-sm dark:text-gray-400"></TableCell>
            </TableRow>
          </TableHeader>
          <TableBody className="divide-y divide-gray-100 dark:divide-gray-800">
            {isLoading ? ( <TableRow><TableCell colSpan={5} className="py-8 text-center text-gray-500">Đang tải...</TableCell></TableRow>
            ) : currentItems.length === 0 ? ( <TableRow><TableCell colSpan={5} className="py-8 text-center text-gray-500">Không có dữ liệu.</TableCell></TableRow>
            ) : (
              currentItems.map((item) => (
                <TableRow key={item._id} className="hover:bg-gray-50 dark:hover:bg-gray-800/50">
                  <TableCell className="px-4 py-3">
                    <div className="flex items-center gap-3">
                      <div className="w-12 h-12 flex-shrink-0 overflow-hidden rounded-lg bg-gray-100 border border-gray-200">
                        {item.image ? ( <img src={`/${item.image}`} alt={item.name} className="w-full h-full object-cover" /> ) : ( <div className="w-full h-full flex items-center justify-center text-xs text-gray-400">No Img</div> )}
                      </div>
                      <div>
                        <div className="font-medium text-gray-800 dark:text-white">{item.name}</div>
                        <div className="text-xs text-gray-500 truncate max-w-[150px]">{item.description}</div>
                      </div>
                    </div>
                  </TableCell>
                  <TableCell className="px-4 py-3">
                    <div className="text-sm text-gray-700 dark:text-gray-300">{item.author?.username || "Unknown"}</div>
                  </TableCell>
                  <TableCell className="px-4 py-3 text-center">
                     <div className="flex flex-col gap-1 text-xs text-gray-500">
                        <span className="bg-blue-50 text-blue-600 px-2 py-0.5 rounded border border-blue-100">{item.difficulty}</span>
                        <span>⏱ {item.cookTimeMinutes}p - 👥 {item.servings} người</span>
                     </div>
                  </TableCell>
                  <TableCell className="px-4 py-3 text-center">
                    <Badge size="sm" color={item.status === "Đã duyệt" ? "success" : item.status === "Chờ duyệt" ? "warning" : "error"}>{item.status}</Badge>
                  </TableCell>
                  <TableCell className="px-4 py-3 text-end">
                    <TableActionMenu id={item._id} onDelete={isAdmin ? apiDeleteRecipe : null} onEdit={handleOpenEdit} />
                  </TableCell>
                </TableRow>
              ))
            )}
          </TableBody>
        </Table>
      </div>
      
      {/* Pagination */}
      {totalPages > 1 && (
        <div className="flex justify-end mt-4 gap-2">
           <button onClick={() => setCurrentPage(p => Math.max(1, p - 1))} disabled={currentPage === 1} className="p-2 border rounded hover:bg-gray-100 disabled:opacity-50"><ChevronLeftIcon /></button>
           <span className="px-3 py-2 text-sm text-gray-600">Trang {currentPage} / {totalPages}</span>
           <button onClick={() => setCurrentPage(p => Math.min(totalPages, p + 1))} disabled={currentPage === totalPages} className="p-2 border rounded hover:bg-gray-100 disabled:opacity-50"><ChevronLeftIcon className="rotate-180"/></button>
        </div>
      )}

      {/* ================= MODAL FORM ================= */}
      <Modal isOpen={modalIsOpen} onClose={closeModalAndReset} className="max-w-[1000px] m-4 max-h-[90vh]">
        <div className="no-scrollbar relative w-full overflow-y-auto rounded-3xl bg-white p-4 dark:bg-gray-900 lg:p-11">
          
          <div className="flex flex-col sm:flex-row justify-between items-start px-2 pr-14 mb-6 gap-4">
            <div>
                <h4 className="mb-2 text-2xl font-semibold text-gray-800 dark:text-white/90">
                  {formData.id ? "Cập nhật món ăn" : "Thêm món ăn mới"}
                </h4>
                <p className="text-sm text-gray-500 dark:text-gray-400">
                  Thông tin chi tiết công thức
                </p>
            </div>
            
            <div className="flex flex-col sm:items-end z-20">
                <div className="relative">
                  <select
                      className={`appearance-none pl-4 pr-10 py-2.5 rounded-xl font-bold border-2 outline-none cursor-pointer shadow-sm transition-all
                          ${formData.status === 'Đã duyệt' ? 'bg-green-50 border-green-500 text-green-700' :
                            formData.status === 'Chờ duyệt' ? 'bg-yellow-50 border-yellow-500 text-yellow-700' :
                            'bg-red-50 border-red-500 text-red-700'}`}
                      value={formData.status}
                      onChange={(e) => handleInputChange('status', e.target.value)}
                  >
                      <option value="Chờ duyệt" className="bg-white text-gray-800 font-medium">Chờ duyệt</option>
                      <option value="Đã duyệt" className="bg-white text-gray-800 font-medium">Đã duyệt</option>
                      <option value="Từ chối" className="bg-white text-gray-800 font-medium">Từ chối</option>
                  </select>
                </div>
            </div>
          </div>
        
          <form id="recipe-form" onSubmit={handleSubmit} className="flex flex-col">
             
             <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
                
                {/* --- CỘT TRÁI --- */}
                <div className="lg:col-span-5 space-y-5">
                    <h4 className="font-semibold text-gray-800 dark:text-white text-sm border-b pb-2 mb-2">Thông tin chung</h4>
                    <div>
                       <Label className="text-sm">Tên món ăn <span className="text-red-500">*</span></Label>
                       <Input value={formData.name} onChange={(e) => handleInputChange('name', e.target.value)} placeholder="VD: Phở bò truyền thống" className="h-10" />
                    </div>
                    <div>
                       <Label className="text-sm">Mô tả ngắn</Label>
                       <textarea className="w-full p-2 border rounded-lg text-sm bg-transparent dark:border-gray-700 focus:border-brand-500 outline-none" rows={3} value={formData.description} onChange={(e) => handleInputChange('description', e.target.value)} placeholder="Giới thiệu sơ lược về món ăn..." />
                    </div>

                    <div className="flex gap-3">
                        <div className="flex-1 flex items-center gap-2 bg-gray-50 dark:bg-gray-800/[0.5] p-2 rounded-lg border border-gray-100 dark:border-gray-800">
                            <Label className="mb-0 text-xs text-gray-500 whitespace-nowrap">Thời gian (phút)</Label>
                            <Input type="number" min="0" className="h-8 text-sm bg-white dark:bg-gray-900 text-center font-medium" value={formData.cookTimeMinutes} onChange={(e) => handleInputChange('cookTimeMinutes', e.target.value)} />
                        </div>
                        <div className="flex-1 flex items-center gap-2 bg-gray-50 dark:bg-gray-800/[0.5] p-2 rounded-lg border border-gray-100 dark:border-gray-800">
                            <Label className="mb-0 text-xs text-gray-500 whitespace-nowrap">Khẩu phần</Label>
                            <Input type="number" min="1" className="h-8 text-sm bg-white dark:bg-gray-900 text-center font-medium" value={formData.servings} onChange={(e) => handleInputChange('servings', e.target.value)} />
                        </div>
                    </div>

                    <div>
                        <Label className="text-sm">Độ khó</Label>
                        <Select options={difficultyOptions} defaultValue={formData.difficulty} onChange={(val) => handleInputChange('difficulty', val)} className="h-fit text-sm w-1/2" />
                    </div>
                </div>

                {/* --- CỘT PHẢI --- */}
                <div className="lg:col-span-7 space-y-5 lg:border-l lg:pl-6 dark:border-gray-800">
                    <div>
                       <h4 className="font-semibold text-gray-800 dark:text-white text-sm mb-2 flex items-center gap-2">
                          Dinh dưỡng <span className="text-xs font-normal text-gray-500">(trên khẩu phần)</span>
                       </h4>
                       <div className="grid grid-cols-4 gap-2 bg-brand-50/50 dark:bg-gray-800/30 p-3 rounded-xl border border-brand-100/50 dark:border-gray-700">
                          {[
                             { label: 'Cal (kcal)', field: 'calories', color: 'text-orange-500' },
                             { label: 'Pro (g)', field: 'protein', color: 'text-red-500' },
                             { label: 'Fat (g)', field: 'fat', color: 'text-yellow-500' },
                             { label: 'Carb (g)', field: 'carbs', color: 'text-blue-500' }
                          ].map(nut => (
                             <div key={nut.field} className="flex flex-col items-center bg-white dark:bg-gray-900 p-1.5 rounded-lg border dark:border-gray-800 shadow-sm">
                                <label className={`text-[10px] font-semibold mb-1 ${nut.color}`}>{nut.label}</label>
                                {/* Đã tắt readonly đi, nếu người dùng muốn tự sửa thì sửa, nhưng mặc định sẽ tự tính */}
                                <input type="number" step={"any"} min="0" className="w-full h-7 text-center border-0 border-b border-gray-200 rounded-none text-sm bg-transparent focus:ring-0 focus:border-brand-500 p-0 font-medium text-gray-700 dark:text-gray-200"
                                   value={formData.nutritionAnalysis[nut.field]}
                                   onChange={(e) => setFormData(prev => ({...prev, nutritionAnalysis: {...prev.nutritionAnalysis, [nut.field]: e.target.value}}))} />
                             </div>
                          ))}
                       </div>
                    </div>

                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <div className="flex flex-col h-[280px] border rounded-xl overflow-hidden dark:border-gray-800 bg-gray-50/30 dark:bg-gray-800/20">
                            <div className="flex justify-between items-center p-2 border-b bg-gray-50 dark:bg-gray-800/80 dark:border-gray-700">
                                <h4 className="font-semibold text-sm text-gray-700 dark:text-gray-200">Nguyên liệu ({formData.ingredients.length})</h4>
                                <button type="button" onClick={() => addToArray('ingredients', { masterIngredient: "", name: "", quantity: 1, unit: "g" })} className="text-xs bg-brand-500 text-white px-2 py-1 rounded hover:bg-brand-600 transition shadow-sm">+ Thêm</button>
                            </div>
                            <div className="flex-1 overflow-y-auto p-2 space-y-2 custom-scrollbar">
                                {formData.ingredients.map((ing, idx) => (
                                    <div key={idx} className="flex flex-col gap-1 bg-white dark:bg-gray-900 p-2 rounded border shadow-sm dark:border-gray-700">
                                        <div className="flex gap-1">
                                            <select className="flex-1 min-w-0 p-1.5 border rounded text-xs bg-transparent dark:border-gray-700 focus:border-brand-500 outline-none" value={ing.masterIngredient || ""} onChange={(e) => updateArrayItem('ingredients', idx, 'masterIngredient', e.target.value)}>
                                                <option value="">Chọn NL từ kho</option>
                                                {masterIngredients.map(m => (<option key={m._id} value={m._id}>{m.name}</option>))}
                                            </select>
                                            <button type="button" onClick={() => removeFromArray('ingredients', idx)} className="text-gray-400 hover:text-red-500 p-1"><TrashBinIcon className="size-3.5" /></button>
                                        </div>
                                        <div className="flex gap-1">
                                            <input placeholder="Tên hiển thị" className="max-w-[120px] min-w-0 p-1.5 border rounded text-xs bg-transparent dark:border-gray-700 outline-none" value={ing.name} onChange={(e) => updateArrayItem('ingredients', idx, 'name', e.target.value)} />
                                            <input type="number" placeholder="SL" className="w-10 p-1.5 border rounded text-xs text-center bg-transparent dark:border-gray-700 outline-none" value={ing.quantity} onChange={(e) => updateArrayItem('ingredients', idx, 'quantity', e.target.value)} />
                                            <input placeholder="ĐV" className="w-10 p-1.5 border rounded text-xs text-center bg-transparent dark:border-gray-700 outline-none" value={ing.unit} onChange={(e) => updateArrayItem('ingredients', idx, 'unit', e.target.value)} />
                                        </div>
                                    </div>
                                ))}
                            </div>
                        </div>

                        <div className="flex flex-col h-[280px] border rounded-xl overflow-hidden dark:border-gray-800 bg-gray-50/30 dark:bg-gray-800/20">
                            <div className="flex justify-between items-center p-2 border-b bg-gray-50 dark:bg-gray-800/80 dark:border-gray-700">
                                <h4 className="font-semibold text-sm text-gray-700 dark:text-gray-200">Các bước ({formData.steps.length})</h4>
                                <button type="button" onClick={() => addToArray('steps', { description: "" })} className="text-xs bg-brand-500 text-white px-2 py-1 rounded hover:bg-brand-600 transition shadow-sm">+ Thêm</button>
                            </div>
                            <div className="flex-1 overflow-y-auto p-2 space-y-2 custom-scrollbar">
                                {formData.steps.map((step, idx) => (
                                    <div key={idx} className="flex gap-2 items-start group bg-white dark:bg-gray-900 p-2 rounded border shadow-sm dark:border-gray-700">
                                        <span className="flex-shrink-0 flex items-center justify-center w-5 h-5 rounded-full bg-brand-100 text-brand-600 text-[10px] font-bold mt-0.5">{idx + 1}</span>
                                        <textarea placeholder="Mô tả bước làm..." className="flex-1 min-w-0 p-1.5 border rounded text-xs bg-transparent dark:border-gray-700 focus:border-brand-500 outline-none resize-none" rows={2} value={step.description} onChange={(e) => updateArrayItem('steps', idx, null, e.target.value)} />
                                        <button type="button" onClick={() => removeFromArray('steps', idx)} className="text-gray-400 hover:text-red-500 p-1 opacity-0 group-hover:opacity-100 transition-opacity"><TrashBinIcon className="size-3.5" /></button>
                                    </div>
                                ))}
                            </div>
                        </div>
                    </div>
                </div>
             </div>

             {/* ================= PHẦN TAGS (CHIA LÀM 2 CỘT NHƯ HÌNH) ================= */}
             <div className="mt-6 border-t pt-4 border-gray-100 dark:border-gray-800">
                <h4 className="font-semibold text-gray-800 dark:text-white text-sm mb-3">Phân loại (Tags)</h4>
                
                {/* Đã thêm md:grid-cols-2 ở đây để dàn thành 2 cột */}
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    {tagCategoriesList.map(category => (
                      <div key={category.type} className="bg-gray-50/50 dark:bg-gray-800/30 p-3 rounded-lg border border-gray-100 dark:border-gray-800">
                          <Label className="text-xs font-semibold text-gray-600 mb-2 block">{category.label}</Label>
                          <div className="flex flex-wrap gap-2">
                              {categorizedTags[category.type]?.map(tag => {
                                  const isSelected = formData[category.field].includes(tag._id);
                                  return (
                                      <button
                                          key={tag._id}
                                          type="button"
                                          onClick={() => handleTagToggle(category.field, tag._id)}
                                          className={`px-3 py-1 text-xs rounded-full border transition-all ${
                                              isSelected 
                                              ? "bg-brand-100 border-brand-500 text-brand-700 dark:bg-brand-500/20 dark:text-brand-300 font-medium" 
                                              : "bg-white border-gray-200 text-gray-600 hover:border-brand-300 dark:bg-gray-900 dark:border-gray-700 dark:text-gray-400"
                                          }`}
                                      >
                                          {tag.name}
                                      </button>
                                  );
                              })}
                              {(!categorizedTags[category.type] || categorizedTags[category.type].length === 0) && <span className="text-xs text-gray-400 italic">Chưa có tag...</span>}
                          </div>
                      </div>
                    ))}
                </div>
             </div>

             {/* ================= PHẦN DƯỚI (MEDIA) ================= */}
             <div className="mt-6 pt-4 border-t border-gray-100 dark:border-gray-800">
                <h4 className="font-semibold text-gray-800 dark:text-white text-sm mb-4">Hình ảnh & Video</h4>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div className="flex flex-col gap-3">
                        <Label className="text-xs text-gray-500 mb-0">Ảnh đại diện <span className="text-red-500">*</span></Label>
                        <div className="border-2 border-dashed border-gray-200 dark:border-gray-700 rounded-xl p-4 flex flex-col items-center justify-center bg-gray-50 dark:bg-gray-800 hover:bg-gray-100 dark:hover:bg-gray-700/50 transition relative group">
                            <input type="file" accept="image/*" onChange={(e) => handleFileChange(e, 'imageFile')} className="absolute inset-0 w-full h-full opacity-0 cursor-pointer z-10"/>
                            {formData.imagePreview ? (
                                <div className="w-full h-48 relative rounded-lg overflow-hidden shadow-sm">
                                    <img src={formData.imagePreview.startsWith('blob') ? formData.imagePreview : `/${formData.imagePreview}`} alt="Preview" className="w-full h-full object-cover" />
                                    <div className="absolute inset-0 bg-black/40 flex items-center justify-center opacity-0 group-hover:opacity-100 transition text-white font-medium text-sm pointer-events-none">Thay đổi ảnh</div>
                                </div>
                            ) : (
                                <div className="flex flex-col items-center justify-center py-6 text-gray-400 pointer-events-none"><span className="text-sm">Nhấn để tải ảnh lên</span></div>
                            )}
                        </div>
                    </div>

                    <div className="flex flex-col gap-3">
                        <Label className="text-xs text-gray-500 mb-0">Video hướng dẫn</Label>
                        <div className="border-2 border-dashed border-gray-200 dark:border-gray-700 rounded-xl p-4 flex flex-col items-center justify-center bg-gray-50 dark:bg-gray-800 hover:bg-gray-100 dark:hover:bg-gray-700/50 transition relative group">
                            <input type="file" accept="video/*" onChange={(e) => handleFileChange(e, 'videoFile')} className="absolute inset-0 w-full h-full opacity-0 cursor-pointer z-10"/>
                            {formData.videoPreview ? (
                                <div className="w-full h-48 relative rounded-lg overflow-hidden shadow-sm bg-black">
                                    <video src={formData.videoPreview.startsWith('blob') ? formData.videoPreview : `/${formData.videoPreview}`} controls className="w-full h-full object-contain pointer-events-auto relative z-20" />
                                </div>
                            ) : (
                                <div className="flex flex-col items-center justify-center py-6 text-gray-400 pointer-events-none"><span className="text-sm">Nhấn để tải video lên</span></div>
                            )}
                        </div>
                    </div>
                </div>
             </div>

            <div className="flex items-center gap-3 px-2 mt-6 lg:justify-end">
              <Button variant="outline" onClick={closeModalAndReset} className="text-sm py-2">Huỷ bỏ</Button>
              <Button form="recipe-form" type={"submit"} className="text-sm py-2 bg-brand-500 hover:bg-brand-600">{formData.id ? "Lưu thay đổi" : "Hoàn tất & Tạo món"}</Button>
            </div>
          </form>

        </div>
      </Modal>
    </div>
  );
}