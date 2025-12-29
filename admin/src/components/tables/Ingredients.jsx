import dayjs from "dayjs";
import { useAuth } from "../../hooks/AuthProvider";
import { useEffect, useState, useMemo } from "react";
import axios from "axios";
import { useModal } from "../../hooks/useModal";
import { Modal } from "../ui/modal";
import Input from "../form/input/InputField";
import Label from "../form/Label";
import Button from "../ui/button/Button";
import Select from "../form/Select";
import { Dropdown } from "../ui/dropdown/Dropdown";
import Checkbox from "../form/input/Checkbox";
import TableActionMenu from "./Action/TableActionMenu";

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
} from "../../icons";

export default function Ingredients() {
  const { user } = useAuth();
  const isAdmin = user.role._id === 1;
  // --- STATE ---
  const token = localStorage.getItem('admin_token') || sessionStorage.getItem('admin_token');
  const { isOpen: modalIsOpen, openModal, closeModal } = useModal();
  const [isLoading, setIsLoading] = useState(false);
  
  const [ingredientData, setIngredientData] = useState([]); 
  const [tagOptions, setTagOptions] = useState([]); 

  // State Modal
  const [currentId, setCurrentId] = useState(""); 
  const [name, setName] = useState("");
  const [synonyms, setSynonyms] = useState(""); 
  const [selectedTag, setSelectedTag] = useState(""); 
  const [nutrition, setNutrition] = useState({
    calories: 0, protein: 0, carbs: 0, fat: 0, sodium: 0, sugars: 0
  });

  // State Search & Filter & Pagination
  const [searchTerm, setSearchTerm] = useState("");
  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 10;
  
  // State Filter Dropdown
  const [isFilterOpen, setIsFilterOpen] = useState(false);
  const [checkedTags, setCheckedTags] = useState([]); 

  // --- API CALLS ---
  
  // 1. Load Tags và chỉ lọc lấy 'Loại nguyên liệu'
  useEffect(() => {
    const apiLoadTags = async () => {
      try {
        const config = { headers: { "x-access-token": token } };
        const res = await axios.get('/api/admin/tag', config);
        if (res.data.success) {
          // LỌC Ở ĐÂY: Chỉ lấy tag có type là "Loại nguyên liệu"
          const materialTags = res.data.tags.filter(tag => tag.type === "Loại nguyên liệu");
          
          setTagOptions(materialTags.map(tag => ({ value: tag._id, label: tag.name })));
        }
      } catch (err) {
        console.error("Lỗi lấy danh sách thẻ:", err);
      }
    };
    apiLoadTags();
  }, [token]);

  // 2. Load Ingredients
  useEffect(() => {
    apiLoadIngredients();
  }, []);

  const apiLoadIngredients = async () => {
    try {
      setIsLoading(true);
      const config = { headers: { "x-access-token": token } };
      const res = await axios.get('/api/admin/ingredient', config);
      if (res.data.success) {
        setIngredientData(res.data.ingredients || []);
      }
    } catch (err) {
      console.error("Lỗi lấy dữ liệu:", err);
    } finally {
      setIsLoading(false);
    }
  };

  const apiCreateIngredient = async () => {
    try {
      const synonymsArray = synonyms.split(',').map(s => s.trim()).filter(s => s !== "");
      const payload = { name, synonyms: synonymsArray, tag: selectedTag, nutritionPer100g: nutrition };
      const config = { headers: { "x-access-token": token } };
      const res = await axios.post('/api/admin/ingredient', payload, config);
      if (res.data.success) {
        alert("Thêm thành công!");
        apiLoadIngredients();
        closeModalAndReset();
      } else {
        alert(res.data.message);
      }
    } catch (err) {
      console.error(err);
      alert("Lỗi thêm mới");
    }
  };

  const apiUpdateIngredient = async () => {
    try {
      const synonymsArray = synonyms.split(',').map(s => s.trim()).filter(s => s !== "");
      const payload = { name, synonyms: synonymsArray, tag: selectedTag, nutritionPer100g: nutrition };
      const config = { headers: { "x-access-token": token } };
      const res = await axios.put(`/api/admin/ingredient/${currentId}`, payload, config);
      if (res.data.success) {
        alert("Cập nhật thành công!");
        apiLoadIngredients();
        closeModalAndReset();
      } else {
        alert(res.data.message);
      }
    } catch (err) {
      console.error(err);
      alert("Lỗi cập nhật");
    }
  };

  const apiDeleteIngredient = async (id) => {
    if (!window.confirm("Bạn có chắc chắn muốn xóa?")) return;
    try {
      const config = { headers: { "x-access-token": token } };
      const res = await axios.delete(`/api/admin/ingredient/${id}`, config);
      if (res.data.success) {
        alert("Xóa thành công!");
        apiLoadIngredients();
      } else {
        alert(res.data.message);
      }
    } catch (err) {
      console.error(err);
      alert("Lỗi xóa");
    }
  };

  // --- HANDLERS ---
  const handleSave = (e) => {
    e.preventDefault();
    if (!name || !selectedTag) return alert("Vui lòng nhập tên và chọn danh mục!");
    currentId ? apiUpdateIngredient() : apiCreateIngredient();
  };

  const handleEdit = (id) => {
    const ingreToEdit = ingredientData.find(item => item._id === id);
    setCurrentId(ingreToEdit._id);
    setName(ingreToEdit.name);
    setSynonyms(ingreToEdit.synonyms ? ingreToEdit.synonyms.join(', ') : "");
    setSelectedTag(ingreToEdit.tag ? ingreToEdit.tag._id : ""); 
    setNutrition(ingreToEdit.nutritionPer100g || { calories: 0, protein: 0, carbs: 0, fat: 0, sodium: 0, sugars: 0 });
    openModal();
  };

  const closeModalAndReset = () => {
    setCurrentId(""); setName(""); setSynonyms(""); setSelectedTag("");
    setNutrition({ calories: 0, protein: 0, carbs: 0, fat: 0, sodium: 0, sugars: 0 });
    closeModal();
  };

  const handleToggleTagFilter = (tagId) => {
    setCheckedTags(prev => prev.includes(tagId) ? prev.filter(id => id !== tagId) : [...prev, tagId]);
  };

  // *** HÀM MỚI: Xử lý nhập liệu dinh dưỡng an toàn ***
  const handleNutritionInput = (key, value) => {
    // Nếu người dùng xóa hết (chuỗi rỗng), gán tạm là 0 hoặc để rỗng tùy logic (ở đây để 0)
    if (value === "") {
        setNutrition(prev => ({ ...prev, [key]: 0 }));
        return;
    }
    
    const floatVal = parseFloat(value);
    // Chỉ cập nhật nếu là số và >= 0
    if (!isNaN(floatVal) && floatVal >= 0) {
        setNutrition(prev => ({ ...prev, [key]: floatVal }));
    }
  };

  // --- FILTER & PAGINATION ---
  const filteredData = useMemo(() => {
    let data = ingredientData;
    if (searchTerm) {
      const lower = searchTerm.toLowerCase();
      data = data.filter(item => item.name.toLowerCase().includes(lower) || (item.tag && item.tag.name.toLowerCase().includes(lower)));
    }
    if (checkedTags.length > 0) {
      data = data.filter(item => item.tag && checkedTags.includes(item.tag._id));
    }
    return data;
  }, [ingredientData, searchTerm, checkedTags]);

  useEffect(() => { setCurrentPage(1); }, [searchTerm, checkedTags]);

  const totalPages = Math.ceil(filteredData.length / itemsPerPage);
  const currentItems = filteredData.slice((currentPage - 1) * itemsPerPage, currentPage * itemsPerPage);
  const goToPage = (p) => { if (p >= 1 && p <= totalPages) setCurrentPage(p); };

  return (
    <div className="max-w-full overflow-hidden rounded-2xl border border-gray-200 bg-white px-4 pb-3 pt-4 dark:border-gray-800 dark:bg-white/[0.03] sm:px-6">
      
      {/* HEADER */}
      <div className="flex flex-col gap-2 mb-4 sm:flex-row sm:items-center sm:justify-between">
        <h3 className="text-lg font-semibold text-gray-800 dark:text-white/90">Quản lý nguyên liệu</h3>
        
        {/* Search */}
        <div className="relative sm:w-[350px]">
           <span className="absolute -translate-y-1/2 pointer-events-none left-4 top-1/2">
             <svg className="fill-gray-500 dark:fill-gray-400" width="20" height="20" viewBox="0 0 20 20" fill="none"><path fillRule="evenodd" clipRule="evenodd" d="M3.04175 9.37363C3.04175 5.87693 5.87711 3.04199 9.37508 3.04199C12.8731 3.04199 15.7084 5.87693 15.7084 9.37363C15.7084 12.8703 12.8731 15.7053 9.37508 15.7053C5.87711 15.7053 3.04175 12.8703 3.04175 9.37363ZM9.37508 1.54199C5.04902 1.54199 1.54175 5.04817 1.54175 9.37363C1.54175 13.6991 5.04902 17.2053 9.37508 17.2053C11.2674 17.2053 13.003 16.5344 14.357 15.4176L17.177 18.238C17.4699 18.5309 17.9448 18.5309 18.2377 18.238C18.5306 17.9451 18.5306 17.4703 18.2377 17.1774L15.418 14.3573C16.5365 13.0033 17.2084 11.2669 17.2084 9.37363C17.2084 5.04817 13.7011 1.54199 9.37508 1.54199Z"/></svg>
           </span>
           <input type="text" placeholder="Tìm kiếm nguyên liệu, danh mục..." value={searchTerm} onChange={(e) => setSearchTerm(e.target.value)} className="dark:bg-dark-900 h-10 w-full rounded-lg border border-gray-200 bg-transparent py-2.5 pl-12 pr-14 text-sm text-gray-800 shadow-theme-xs placeholder:text-gray-400 focus:border-brand-300 focus:outline-none focus:ring focus:ring-brand-500/10 dark:border-gray-800 dark:bg-gray-900 dark:bg-white/[0.03] dark:text-white/90 dark:placeholder:text-white/30 dark:focus:border-brand-800"/>
        </div>

        <div className="flex items-center gap-3">
          <button onClick={() => { closeModalAndReset(); openModal(); }} className="inline-flex items-center gap-1 rounded-lg border border-gray-300 bg-brand-500 px-4 py-2 text-theme-sm font-medium text-white shadow-theme-xs hover:bg-brand-600 hover:text-gray-200 dark:border-gray-700 dark:bg-gray-800 dark:text-gray-400">
            <PlusIcon /> Thêm
          </button>
          
          {/* FILTER DROPDOWN */}
          <div className="relative">
            <button onClick={() => setIsFilterOpen(!isFilterOpen)} className={`inline-flex items-center gap-2 rounded-lg border px-4 py-2 text-theme-sm font-medium shadow-theme-xs hover:bg-gray-50 dark:hover:bg-white/[0.03] ${checkedTags.length > 0 ? "border-brand-500 text-brand-500 bg-brand-50 dark:bg-brand-500/10" : "border-gray-300 text-gray-700 bg-white dark:border-gray-700 dark:bg-gray-800 dark:text-gray-400"}`}>
               <svg className="stroke-current fill-white dark:fill-gray-800" width="20" height="20" viewBox="0 0 20 20" fill="none"><path d="M2.29004 5.90393H17.7067" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/><path d="M17.7075 14.0961H2.29085" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/><path d="M12.0826 3.33331C13.5024 3.33331 14.6534 4.48431 14.6534 5.90414C14.6534 7.32398 13.5024 8.47498 12.0826 8.47498C10.6627 8.47498 9.51172 7.32398 9.51172 5.90415C9.51172 4.48432 10.6627 3.33331 12.0826 3.33331Z" strokeWidth="1.5"/><path d="M7.91745 11.525C6.49762 11.525 5.34662 12.676 5.34662 14.0959C5.34661 15.5157 6.49762 16.6667 7.91745 16.6667C9.33728 16.6667 10.4883 15.5157 10.4883 14.0959C10.4883 12.676 9.33728 11.525 7.91745 11.525Z" strokeWidth="1.5"/></svg>
               Lọc danh mục {checkedTags.length > 0 && <span className="flex items-center justify-center w-5 h-5 ml-1 text-xs text-white rounded-full bg-brand-500">{checkedTags.length}</span>}
            </button>
            <Dropdown isOpen={isFilterOpen} onClose={() => setIsFilterOpen(false)} className="absolute right-0 z-50 mt-2 w-64 flex flex-col rounded-xl border border-gray-200 bg-white p-2 shadow-theme-lg dark:border-gray-800 dark:bg-gray-900">
               <div className="px-3 py-2 text-xs font-semibold text-gray-500 uppercase border-b border-gray-100 dark:border-gray-800 mb-2">Chọn danh mục</div>
               <ul className="flex flex-col gap-1 max-h-60 overflow-y-auto custom-scrollbar">
                 {tagOptions.length > 0 ? tagOptions.map((opt) => (
                    <li key={opt.value}>
                        <label className="flex items-center gap-3 px-3 py-2 rounded-lg cursor-pointer hover:bg-gray-100 dark:hover:bg-white/5 transition-colors">
                        <Checkbox checked={checkedTags.includes(opt.value)} onChange={() => handleToggleTagFilter(opt.value)} />
                        <span className="text-sm text-gray-700 dark:text-gray-300">{opt.label}</span>
                        </label>
                    </li>
                 )) : <li className="px-3 py-2 text-sm text-gray-400 italic">Chưa có danh mục</li>}
               </ul>
               {checkedTags.length > 0 && (
                 <div className="mt-2 pt-2 border-t border-gray-100 dark:border-gray-800 px-2">
                   <button onClick={() => setCheckedTags([])} className="w-full py-1.5 text-xs font-medium text-red-500 hover:bg-red-50 rounded dark:hover:bg-red-900/10">Xóa bộ lọc</button>
                 </div>
               )}
            </Dropdown>
          </div>
        </div> 
      </div>

      {/* TABLE */}
      <div className="p-4 border-t border-gray-100 dark:border-gray-800 sm:p-6">
        <div className="overflow-hidden rounded-xl border border-gray-200 bg-white dark:border-white/[0.05] dark:bg-white/[0.03]">
            <div className="max-w-full overflow-x-auto h-fit overflow-y-auto custom-scrollbar">
              <Table>
                <TableHeader className="sticky top-0 z-10 border-b border-gray-100 bg-white dark:border-white/[0.05] dark:bg-gray-800">
                  <TableRow>
                    <TableCell isHeader className="w-[5%] px-5 py-3 font-medium text-gray-500 text-start text-theme-sm dark:text-gray-400">#</TableCell>
                    <TableCell isHeader className="w-[20%] px-5 py-3 font-medium text-gray-500 text-start text-theme-sm dark:text-gray-400">Tên nguyên liệu</TableCell>
                    <TableCell isHeader className="w-[15%] px-5 py-3 font-medium text-gray-500 text-center text-theme-sm dark:text-gray-400">Danh mục</TableCell>
                    <TableCell isHeader className="w-[15%] px-5 py-3 font-medium text-gray-500 text-center text-theme-sm dark:text-gray-400">Calories (100g)</TableCell>
                    <TableCell isHeader className="w-[25%] px-5 py-3 font-medium text-gray-500 text-start text-theme-sm dark:text-gray-400">Tên đồng nghĩa</TableCell>
                    <TableCell isHeader className="w-[10%] px-5 py-3 font-medium text-gray-500 text-start text-theme-sm dark:text-gray-400">Ngày tạo</TableCell>
                    <TableCell isHeader className="w-[10%] px-5 py-3 font-medium text-gray-500 text-start text-theme-sm dark:text-gray-400"></TableCell>
                  </TableRow>
                </TableHeader>
                <TableBody className="divide-y divide-gray-100 dark:divide-white/[0.05]">
                  {isLoading ? <TableRow>
                    <TableCell colSpan={7} className="text-center py-8">Đang tải...</TableCell>
                    </TableRow> 
                  : currentItems.length === 0 ? <TableRow>
                    <TableCell colSpan={7} className="text-center py-8">Không có dữ liệu</TableCell>
                    </TableRow>
                  : currentItems.map((item, index) => (
                    <TableRow key={item._id} className="hover:bg-gray-50 dark:hover:bg-white/[0.03]">
                      
                      <TableCell className="px-5 py-3 font-medium">{(currentPage - 1) * itemsPerPage + index + 1}</TableCell>

                      <TableCell className="px-5 py-3 font-medium text-gray-800 dark:text-white">{item.name}</TableCell>

                      <TableCell className="px-5 py-3 text-center">
                         {item.tag ? (
                            <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-brand-50 text-brand-700 border border-brand-200 dark:bg-brand-500/10 dark:text-brand-400">
                                {item.tag.name}
                            </span>
                         ) : <span className="text-gray-400 italic">--</span>}
                      </TableCell>

                      <TableCell className="px-5 py-3 text-center text-gray-600 dark:text-gray-300 font-medium">
                         {item.nutritionPer100g?.calories || 0}
                      </TableCell>

                      <TableCell className="px-5 py-3 text-sm text-gray-500 truncate max-w-[200px]">{item.synonyms?.join(', ') || '--'}</TableCell>

                      <TableCell className="px-5 py-3 text-center text-xs text-gray-400">{dayjs(item.createdAt).format('DD/MM/YYYY')}</TableCell>

                      <TableCell className="px-5 py-3 text-end">
                        <TableActionMenu id={item._id} onDelete={isAdmin ? apiDeleteIngredient : null} onEdit={handleEdit} />
                      </TableCell>

                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </div>
            
            {/* Pagination */}
            <div className="flex items-center justify-between px-5 py-4 border-t border-gray-100 dark:border-white/[0.05]">
               <span className="text-sm text-gray-500">Hiển thị {(currentPage-1)*itemsPerPage + 1} - {Math.min(currentPage*itemsPerPage, filteredData.length)} trên {filteredData.length}</span>
               <div className="flex gap-2">
                 <button onClick={() => goToPage(currentPage - 1)} disabled={currentPage===1} className="p-2 rounded border border-gray-300 disabled:opacity-50 hover:bg-gray-50 dark:border-gray-700 dark:hover:bg-gray-800"><ChevronLeftIcon className="w-4 h-4"/></button>
                 {Array.from({length: totalPages}, (_, i) => i+1).slice(Math.max(0, currentPage - 3), Math.min(totalPages, currentPage + 2)).map(p => (
                   <button key={p} onClick={() => goToPage(p)} className={`px-3 py-1 text-sm rounded border ${currentPage === p ? 'bg-brand-600 text-white border-brand-600' : 'border-gray-300 hover:bg-gray-50 dark:border-gray-700 dark:hover:bg-gray-800'}`}>{p}</button>
                 ))}
                 <button onClick={() => goToPage(currentPage + 1)} disabled={currentPage===totalPages} className="p-2 rounded border border-gray-300 disabled:opacity-50 hover:bg-gray-50 dark:border-gray-700 dark:hover:bg-gray-800"><ChevronLeftIcon className="w-4 h-4 rotate-180"/></button>
               </div>
            </div>
        </div>
      </div>

      {/* IMPROVED MODAL UI */}
      <Modal isOpen={modalIsOpen} onClose={closeModalAndReset} className="max-w-[850px] m-4">
        <div className="relative w-full overflow-y-auto rounded-3xl bg-white p-6 dark:bg-gray-900 lg:p-8 max-h-[90vh] custom-scrollbar">
          <div className="mb-6 flex justify-between items-start">
            <div>
                <h4 className="text-2xl font-bold text-gray-800 dark:text-white">
                {currentId ? "Cập nhật nguyên liệu" : "Thêm nguyên liệu mới"}
                </h4>
                <p className="text-sm text-gray-500 mt-1 dark:text-gray-400">
                Điền thông tin chi tiết về nguyên liệu và thành phần dinh dưỡng.
                </p>
            </div>
            <button onClick={closeModalAndReset} className="p-2 hover:bg-gray-100 rounded-full dark:hover:bg-gray-800 text-gray-400 hover:text-gray-600">
                <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" /></svg>
            </button>
          </div>

          <form className="flex flex-col gap-6">
            {/* Section 1: Thông tin chung */}
            <div className="bg-gray-50 dark:bg-gray-800/50 p-5 rounded-xl border border-gray-100 dark:border-gray-700/50">
               <h5 className="text-sm font-bold text-brand-700 dark:text-brand-400 uppercase tracking-wider mb-4 flex items-center gap-2">
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>
                  Thông tin cơ bản
               </h5>
               <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
                   <div>
                        <Label className="mb-1.5">Tên nguyên liệu <span className="text-red-500">*</span></Label>
                        <Input type="text" value={name} onChange={(e) => setName(e.target.value)} placeholder="Nhập tên nguyên liệu" className="bg-white dark:bg-gray-800" />
                   </div>
                   <div>
                        <Label className="mb-1.5">Danh mục <span className="text-red-500">*</span></Label>
                        <Select options={tagOptions} onChange={(val) => setSelectedTag(val)} defaultValue={selectedTag} placeholder="Chọn danh mục" className="bg-white dark:bg-gray-800"/>
                   </div>
                   <div className="md:col-span-2">
                        <Label className="mb-1.5">Tên đồng nghĩa (cách nhau bởi dấu phẩy)</Label>
                        <Input type="text" value={synonyms} onChange={(e) => setSynonyms(e.target.value)} placeholder="Ví dụ: Thịt lợn, Pork, Heo..." className="bg-white dark:bg-gray-800"/>
                   </div>
               </div>
            </div>

            {/* Section 2: Dinh dưỡng */}
            <div className="bg-brand-50/50 dark:bg-brand-900/10 p-5 rounded-xl border border-brand-100 dark:border-brand-800/30">
                <h5 className="text-sm font-bold text-brand-700 dark:text-brand-400 uppercase tracking-wider mb-4 flex items-center gap-2">
                   <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" /></svg>
                   Giá trị dinh dưỡng (trên 100g)
                </h5>
                <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4">
                    {[
                        { label: "Calories", key: "calories", unit: "kcal" },
                        { label: "Protein", key: "protein", unit: "g" },
                        { label: "Carbs", key: "carbs", unit: "g" },
                        { label: "Fat", key: "fat", unit: "g" },
                        { label: "Sodium", key: "sodium", unit: "mg" },
                        { label: "Sugar", key: "sugars", unit: "g" },
                    ].map((item) => (
                        <div key={item.key} className="bg-white dark:bg-gray-800 p-3 rounded-lg border border-gray-100 dark:border-gray-700 shadow-sm text-center">
                            <label className="text-xs font-semibold text-gray-500 uppercase block mb-1">{item.label}</label>
                            <div className="relative">
                                <input 
                                    type="number" 
                                    min="0"
                                    value={nutrition[item.key]} 
                                    onChange={(e) => handleNutritionInput(item.key, e.target.value)}
                                    className="w-full text-center font-bold text-gray-800 dark:text-white bg-transparent outline-none border-b border-transparent focus:border-brand-500 py-1"
                                />
                                <span className="text-xs text-gray-400 absolute right-0 bottom-1 pointer-events-none">{item.unit}</span>
                            </div>
                        </div>
                    ))}
                </div>
            </div>

            <div className="flex justify-end gap-3 pt-4 border-t border-gray-100 dark:border-gray-800">
              <Button size="sm" variant="outline" onClick={closeModalAndReset} className="hover:bg-gray-100">Hủy</Button>
              <Button size="sm" onClick={handleSave} className="bg-brand-600 hover:bg-brand-700 text-white shadow-md shadow-brand-500/20">{currentId ? "Lưu thay đổi" : "Tạo mới"}</Button>
            </div>
          </form>
        </div>
      </Modal>
    </div>
  );
}