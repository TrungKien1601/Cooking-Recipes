import dayjs from "dayjs";
import { useAuth } from "../../hooks/AuthProvider";
import { useRef, useEffect, useState, useMemo } from "react"; // Thêm useMemo
import TableActionMenu from "./Action/TableActionMenu";
import axios from "axios";
import { useModal } from "../../hooks/useModal";
import { Modal } from "../ui/modal";
import Input from "../form/input/InputField";
import Label from "../form/Label";
import Button from "../ui/button/Button";
import Select from "../form/Select";
import { Dropdown } from "../ui/dropdown/Dropdown";
// import { DropdownItem } from "../ui/dropdown/DropdownItem"; // Không cần dùng component này nữa, dùng thẻ li/label trực tiếp cho linh hoạt
import Checkbox from "../form/input/Checkbox";

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

export default function Tags() {
  const { user } = useAuth();
  const { isOpen: modalIsOpen, openModal, closeModal } = useModal();
  const [ isLoading, setIsLoading ] = useState(false);
  
  const inputRef = useRef(null);
  const isAdmin = user.role._id === 1; //Logic kiểm tra quyền Admin
  const [ searchTerm, setSearchTerm ] = useState('');
  const [ tagData, setTagData ] = useState([]);
  
  // State cho Modal form
  const [ idTag, setIdTag ] = useState("");
  const [ nameTag, setNameTag ] = useState("");
  const [ typeTag, setTypeTag ] = useState("");

  // State cho Filter (Lưu các loại thẻ được check)
  const [ checkedTypes, setCheckedTypes ] = useState([]);

  // State Dropdown toggle
  const [ isOpen, setIsOpen ] = useState(false);
  function toggleDropdown() { setIsOpen(!isOpen); };
  // function closeDropdown() { setIsOpen(false); }; // Dropdown có sẵn onClose prop rồi

  const token = localStorage.getItem('admin_token') || sessionStorage.getItem('admin_token');

  // --- OPTIONS ---
  const typeOptions = [
    { "value" : "Vùng miền", "label" : "Vùng miền" },
    { "value" : "Cách chế biến", "label" : "Cách chế biến" },
    { "value" : "Loại nguyên liệu", "label" : "Loại nguyên liệu" },
    { "value" : "Giờ ăn", "label" : "Giờ ăn" },
    { "value" : "Chế độ ăn kiêng", "label" : "Chế độ ăn kiêng" },
    { "value" : "Tình trạng sức khoẻ", "label" : "Tình trạng sức khoẻ" },
    { "value" : "Danh mục thực phẩm", "label" : "Danh mục thực phẩm" },
    { "value" : "Dị ứng", "label" : "Dị ứng" },
    { "value" : "Thói quen", "label" : "Thói quen" },
    { "value" : "Mục tiêu dinh dưỡng", "label" : "Mục tiêu dinh dưỡng" },
  ];

  // ==========================================
  // LOGIC FILTERING & SEARCHING
  // ==========================================
  
  // Sử dụng useMemo để tối ưu hiệu năng khi render lại
  const filteredTags = useMemo(() => {
    return tagData.filter((tag) => {
      // 1. Logic Tìm kiếm text
      const lowerTerm = searchTerm.toLowerCase();
      const tagName = tag.name ? tag.name.toLowerCase() : "";
      const tagType = tag.type ? tag.type.toLowerCase() : "";
      const matchesSearch = !searchTerm || tagName.includes(lowerTerm) || tagType.includes(lowerTerm);

      // 2. Logic Lọc theo Checkbox
      // Nếu checkedTypes rỗng -> Lấy hết. Nếu có chọn -> Chỉ lấy item có type nằm trong list đã chọn
      const matchesType = checkedTypes.length === 0 || checkedTypes.includes(tag.type);

      return matchesSearch && matchesType;
    });
  }, [tagData, searchTerm, checkedTypes]);


  // ==========================================
  // LOGIC PHÂN TRANG
  // ==========================================
  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 15;

  // Reset trang về 1 khi search hoặc filter thay đổi
  useEffect(() => {
    setCurrentPage(1);
  }, [searchTerm, checkedTypes]);

  const totalPages = Math.ceil(filteredTags.length / itemsPerPage);
  const currentTags = filteredTags.slice(
    (currentPage - 1) * itemsPerPage,
    currentPage * itemsPerPage
  );

  const goToPage = (pageNumber) => {
    if (pageNumber >= 1 && pageNumber <= totalPages) {
      setCurrentPage(pageNumber);
    }
  };

  const handleSearchChange = (e) => {
    setSearchTerm(e.target.value);
  };

  // Hàm xử lý khi click checkbox trong dropdown
  const handleToggleType = (value) => {
    setCheckedTypes((prev) => 
      prev.includes(value) ? prev.filter(item => item !== value) : [...prev, value]
    );
  };

  // ==========================================
  // API CALLS
  // ==========================================

  const closeModalAndReset = () => {
    setIdTag("");
    setNameTag("");
    setTypeTag("");
    closeModal();
  };
  
  useEffect(() => {
      apiLoadTags();
  }, []);

  const apiLoadTags = async () => {
    try {
      setIsLoading(true);
      const config = { headers: { "x-access-token" : token }};
      const res = await axios.get('/api/admin/tag', config);
      const result = res.data;

      if (!result.success) return alert(result.message);
      setTagData(result.tags || []);
    } catch (err) {
      console.error("Có lỗi trong quá trình lấy dữ liệu", err);
    } finally {
      setIsLoading(false);
    }
  };

  const apiCreateTag = async() => {
    try {
      const tag = { name: nameTag, type: typeTag }
      const config = { headers: { "x-access-token" : token }};
      const res = await axios.post('/api/admin/tag', tag, config);
      const result = res.data;
      if (!result) return alert(result.message);

      apiLoadTags(); 
      return alert('Thêm thành công');
    } catch (err) {
      console.error("Có lỗi trong quá trình tạo mới dữ liệu", err);
    }
  };

  const handleCreate = async(e) => {
    e.preventDefault();
    if (!nameTag || !typeTag) {
      return alert('Vui lòng nhập đầy đủ tên và chọn loại tên');
    } else {
      apiCreateTag();
      closeModalAndReset();
    }
  }

  const apiUpdateTag = async(e) => {
    e.preventDefault();
    if (!idTag) return alert("Không tìm thấy ID thẻ!");
    try {
      const tag = { name: nameTag, type: typeTag };
      const config = { headers: { "x-access-token" : token }};
      const res = await axios.put('/api/admin/tag/' + idTag, tag, config);
      const result = res.data;

      if (!result.success) return res.json(result.message);
      apiLoadTags();
      closeModalAndReset()
      alert('Cập nhật thành công')
    } catch (err) {
      console.error("Lỗi cập nhật:", err);
    }
  }

  const handleEdit = (id) => {
    const tagToEdit = tagData.find(item => item._id === id);
    if (tagToEdit) {
      setIdTag(tagToEdit._id);
      setNameTag(tagToEdit.name);
      setTypeTag(tagToEdit.type);
      openModal();
    }
  }

  const apiDeleteTag = async(id) => {
    const confirm = window.confirm("Bạn có chắc muốn xoá?")
    if (!confirm) return;
    try {
      const config = { headers: { "x-access-token" : token }};
      const res = await axios.delete('/api/admin/tag/'+ id, config);
      const result = res.data;
      if (!result.success) return alert(result.message);

      await apiLoadTags();
      return alert('Xoá thành công');
    } catch (err) {
      console.error("Có lỗi trong quá trình xoá dữ liệu", err);
    }
  };
    
  return (
    <div className="max-w-full overflow-hidden rounded-2xl border border-gray-200 bg-white px-4 pb-3 pt-4 dark:border-gray-800 dark:bg-white/[0.03] sm:px-6">
      
      {/* HEADER TOOLBAR */}
      <div className="flex flex-col gap-2 mb-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h3 className="text-lg font-semibold text-gray-800 dark:text-white/90">
            Quản lý thẻ
          </h3>
        </div>

        {/* SEARCH BOX */}
        <div>
          <form onSubmit={(e) => e.preventDefault()}>
            <div className="relative">
              <span className="absolute -translate-y-1/2 pointer-events-none left-4 top-1/2">
                <svg className="fill-gray-500 dark:fill-gray-400" width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
                  <path fillRule="evenodd" clipRule="evenodd" d="M3.04175 9.37363C3.04175 5.87693 5.87711 3.04199 9.37508 3.04199C12.8731 3.04199 15.7084 5.87693 15.7084 9.37363C15.7084 12.8703 12.8731 15.7053 9.37508 15.7053C5.87711 15.7053 3.04175 12.8703 3.04175 9.37363ZM9.37508 1.54199C5.04902 1.54199 1.54175 5.04817 1.54175 9.37363C1.54175 13.6991 5.04902 17.2053 9.37508 17.2053C11.2674 17.2053 13.003 16.5344 14.357 15.4176L17.177 18.238C17.4699 18.5309 17.9448 18.5309 18.2377 18.238C18.5306 17.9451 18.5306 17.4703 18.2377 17.1774L15.418 14.3573C16.5365 13.0033 17.2084 11.2669 17.2084 9.37363C17.2084 5.04817 13.7011 1.54199 9.37508 1.54199Z" fill="" />
                </svg>
              </span>
              <input
                ref={inputRef}
                type="text"
                placeholder="Tìm kiếm theo tên hoặc loại thẻ..."
                value={searchTerm}
                onChange={handleSearchChange}
                className="dark:bg-dark-900 h-11 w-full rounded-lg border border-gray-200 bg-transparent py-2.5 pl-12 pr-14 text-sm text-gray-800 shadow-theme-xs placeholder:text-gray-400 focus:border-brand-300 focus:outline-none focus:ring focus:ring-brand-500/10 dark:border-gray-800 dark:bg-gray-900 dark:bg-white/[0.03] dark:text-white/90 dark:placeholder:text-white/30 dark:focus:border-brand-800 xl:w-[430px]"
              />
            </div>
          </form>
        </div>

        {/* ACTIONS & FILTER */}
        <div className="flex items-center gap-3">
          <button onClick={openModal} className="inline-flex items-center gap-1 rounded-lg border border-gray-300 bg-brand-500 px-4 py-2.5 text-theme-sm font-medium text-white shadow-theme-xs hover:bg-brand-600 hover:text-gray-200 dark:border-gray-700 dark:bg-gray-800 dark:text-gray-400 dark:hover:bg-white/[0.03] dark:hover:text-gray-200">
            <PlusIcon />
            Thêm thẻ
          </button>

          <div className="relative">
            <button 
              onClick={toggleDropdown} 
              className={`inline-flex items-center gap-2 rounded-lg border px-4 py-2.5 text-theme-sm font-medium shadow-theme-xs hover:bg-gray-50 dark:hover:bg-white/[0.03] ${
                checkedTypes.length > 0 
                ? "border-brand-500 text-brand-500 bg-brand-50 dark:bg-brand-500/10" 
                : "border-gray-300 text-gray-700 bg-white dark:border-gray-700 dark:bg-gray-800 dark:text-gray-400"
              }`}
            >
              <svg className="stroke-current fill-white dark:fill-gray-800" width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
                <path d="M2.29004 5.90393H17.7067" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
                <path d="M17.7075 14.0961H2.29085" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
                <path d="M12.0826 3.33331C13.5024 3.33331 14.6534 4.48431 14.6534 5.90414C14.6534 7.32398 13.5024 8.47498 12.0826 8.47498C10.6627 8.47498 9.51172 7.32398 9.51172 5.90415C9.51172 4.48432 10.6627 3.33331 12.0826 3.33331Z" strokeWidth="1.5"/>
                <path d="M7.91745 11.525C6.49762 11.525 5.34662 12.676 5.34662 14.0959C5.34661 15.5157 6.49762 16.6667 7.91745 16.6667C9.33728 16.6667 10.4883 15.5157 10.4883 14.0959C10.4883 12.676 9.33728 11.525 7.91745 11.525Z" strokeWidth="1.5"/>
              </svg>
              Lọc loại thẻ {checkedTypes.length > 0 && <span className="flex items-center justify-center w-5 h-5 ml-1 text-xs text-white rounded-full bg-brand-500">{checkedTypes.length}</span>}
            </button>
            
            {/* DROPDOWN MENU */}
            <Dropdown 
                isOpen={isOpen} 
                onClose={() => setIsOpen(false)} 
                className="absolute right-0 z-50 mt-2 w-64 flex flex-col rounded-xl border border-gray-200 bg-white p-2 shadow-theme-lg dark:border-gray-800 dark:bg-gray-900"
            >
               <div className="px-3 py-2 text-xs font-semibold text-gray-500 uppercase border-b border-gray-100 dark:border-gray-800 mb-2">
                 Chọn loại thẻ
               </div>
               <ul className="flex flex-col gap-1 max-h-60 overflow-y-auto custom-scrollbar">
                 {typeOptions.map((opt) => (
                   <li key={opt.value}>
                      <label className="flex items-center gap-3 px-3 py-2 rounded-lg cursor-pointer hover:bg-gray-100 dark:hover:bg-white/5 transition-colors">
                       <Checkbox 
                         checked={checkedTypes.includes(opt.value)} 
                         onChange={() => handleToggleType(opt.value)} 
                       />
                       <span className="text-sm text-gray-700 dark:text-gray-300">{opt.label}</span>
                      </label>
                   </li>
                 ))}
               </ul>
               
               {/* Nút Reset Filter nếu cần */}
               {checkedTypes.length > 0 && (
                 <div className="mt-2 pt-2 border-t border-gray-100 dark:border-gray-800 px-2">
                   <button 
                    onClick={() => setCheckedTypes([])}
                    className="w-full py-1.5 text-xs font-medium text-red-500 hover:bg-red-50 rounded dark:hover:bg-red-900/10"
                   >
                     Xóa bộ lọc
                   </button>
                 </div>
               )}
            </Dropdown>
          </div>
        </div> 
      </div>

      {/* TABLE */}
      <div className="p-4 border-t border-gray-100 dark:border-gray-800 sm:p-6">
        <div className="space-y-6">
          <div className="overflow-hidden rounded-xl border border-gray-200 bg-white dark:border-white/[0.05] dark:bg-white/[0.03]">
            
            <div className="max-w-full overflow-x-auto h-fit overflow-y-auto custom-scrollbar">
              <div className="min-w-[450px]">
                <Table>
                  <TableHeader className="sticky top-0 z-10 border-b border-gray-100 bg-white dark:border-white/[0.05] dark:bg-gray-800">
                    <TableRow>
                      <TableCell isHeader className="w-[5%] px-5 py-3 font-medium text-gray-500 text-start text-theme-sm dark:text-gray-400">#</TableCell>
                      <TableCell isHeader className="w-[35%] px-5 py-3 font-medium text-gray-500 text-start text-theme-sm dark:text-gray-400">Tên thẻ</TableCell>
                      <TableCell isHeader className="w-[30%] px-5 py-3 font-medium text-gray-500 text-center text-theme-sm dark:text-gray-400">Loại thẻ</TableCell>
                      <TableCell isHeader className="w-[20%] px-5 py-3 font-medium text-gray-500 text-center text-theme-sm dark:text-gray-400">Ngày tạo</TableCell>
                      <TableCell isHeader className="w-[10%] px-5 py-3 font-medium text-gray-500 text-start text-theme-sm dark:text-gray-400">Chi tiết</TableCell>
                    </TableRow>
                  </TableHeader>

                  <TableBody className="divide-y divide-gray-100 dark:divide-white/[0.05]">
                    {isLoading ? (
                        <TableRow>
                          <TableCell colSpan={5} className="px-5 py-8 text-center text-gray-500">
                            Đang tải dữ liệu...
                          </TableCell>
                        </TableRow>
                      ) : currentTags.length === 0 ? (
                        <TableRow>
                          <TableCell colSpan={5} className="px-5 py-8 text-center text-gray-500">
                            {searchTerm || checkedTypes.length > 0 ? "Không tìm thấy kết quả phù hợp." : "Không có dữ liệu."}
                          </TableCell>
                        </TableRow>
                      ) : (
                        currentTags.map((tag, index) => (
                          <TableRow key={tag._id} className="hover:bg-gray-100 dark:hover:bg-white/[0.03] transition-colors duration-200">
                            <TableCell className="px-4 py-3 sm:px-3 text-center font-medium text-gray-800 text-theme-sm dark:text-white/90">
                              {((currentPage - 1) * itemsPerPage) + index + 1}
                            </TableCell>

                            <TableCell className="px-4 py-3 sm:px-3 text-start font-medium text-gray-800 text-theme-sm dark:text-white/90">
                              {tag.name}
                            </TableCell>

                            <TableCell className="px-4 py-3 text-gray-500 text-center text-theme-sm dark:text-gray-400">
                              <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800 dark:bg-white/10 dark:text-gray-300">
                                {tag.type}
                              </span>
                            </TableCell>

                            <TableCell className="px-4 py-3 text-gray-500 text-center text-theme-sm dark:text-gray-400">
                              {dayjs(tag.updatedAt).format('DD/MM/YYYY')}
                            </TableCell>

                            <TableCell className="px-3 py-3 text-end text-theme-sm">
                              <TableActionMenu id={tag._id} onDelete={isAdmin ? apiDeleteTag : null} onEdit={handleEdit}/>
                            </TableCell>
                          </TableRow>
                        ))
                      )
                    }
                  </TableBody>
                </Table>
              </div>
            </div>

            {/* Pagination Controls */}
            <div className="flex items-center justify-between px-5 py-4 border-t border-gray-100 dark:border-white/[0.05]">
              <span className="text-sm text-gray-500 dark:text-gray-400">
                Hiển thị {filteredTags.length > 0 ? (currentPage-1)*itemsPerPage + 1 : 0} - {Math.min(currentPage*itemsPerPage, filteredTags.length)} trên {filteredTags.length}
              </span>
              <div className="flex items-center space-x-2">
                <button
                  onClick={() => goToPage(currentPage - 1)}
                  disabled={currentPage === 1}
                  className="p-2 rounded border border-gray-300 disabled:opacity-50 hover:bg-gray-50 dark:border-gray-700 dark:hover:bg-gray-800"
                >
                  <ChevronLeftIcon />
                </button>

                {Array.from({ length: totalPages }, (_, index) => index + 1)
                  .slice(Math.max(0, currentPage - 3), Math.min(totalPages, currentPage + 2))
                  .map(p => (
                  <button
                    key={p}
                    onClick={() => goToPage(p)}
                    className={`px-3 py-1 text-sm rounded border ${
                      currentPage === p
                        ? "bg-brand-600 text-white border-brand-600"
                        : "bg-white text-gray-700 border-gray-300 hover:bg-gray-50 dark:bg-gray-900 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-800"
                    }`}
                  >
                    {p}
                  </button>
                ))}

                <button
                  onClick={() => goToPage(currentPage + 1)}
                  disabled={currentPage === totalPages}
                  className="p-2 rounded border border-gray-300 disabled:opacity-50 hover:bg-gray-50 dark:border-gray-700 dark:hover:bg-gray-800"
                >
                  <ChevronLeftIcon className="rotate-180" />
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* MODAL */}
      <Modal isOpen={modalIsOpen} onClose={closeModalAndReset} className="max-w-[700px] m-4">
        <div className="no-scrollbar relative w-full max-w-[700px] overflow-y-auto rounded-3xl bg-white p-4 dark:bg-gray-900 lg:p-11">
          <div className="px-2 pr-14">
            <h4 className="mb-2 text-2xl font-semibold text-gray-800 dark:text-white/90">
              {idTag ? "Cập nhật thẻ" : "Thêm thẻ mới"}
            </h4>
            <p className="mb-6 text-sm text-gray-500 dark:text-gray-400 lg:mb-7">
              Thông tin thẻ
            </p>
          </div>
          <form className="flex flex-col">
            <div className="custom-scrollbar h-[150px] overflow-y-auto px-2 pb-3">
              <div className="mt-5">
                <div className="grid grid-cols-1 gap-x-6 gap-y-5 lg:grid-cols-2">
                  
                  <div className="col-span-2 lg:col-span-1">
                    <Label>Tên thẻ</Label>
                    <Input type="text" value={nameTag} placeholder="Nhập thẻ" onChange={(e) => setNameTag(e.target.value)} />
                  </div>

                  <div className="col-span-2 lg:col-span-1">
                    <Label>Loại thẻ</Label>
                      <Select options={typeOptions} defaultValue={typeTag} placeholder="Chọn thể loại của thẻ" onChange={(value) => setTypeTag(value)} />
                  </div>
                </div>
              </div>
            </div>
            <div className="flex items-center gap-3 px-2 mt-6 lg:justify-end">
              <Button size="sm" variant="outline" onClick={closeModalAndReset}>
                Đóng
              </Button>
              <Button size="sm" onClick={(e) => idTag ? apiUpdateTag(e) : handleCreate(e)}>
                {idTag ? "Cập nhật" : "Lưu"}
              </Button>
            </div>
          </form>
        </div>
      </Modal>
    </div>
  );
}