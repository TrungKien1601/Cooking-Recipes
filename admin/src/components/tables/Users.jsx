import dayjs from "dayjs";
import { useAuth } from "../../hooks/AuthProvider";
import { useEffect, useState, useMemo } from "react";
import axios from "axios";
import { useModal } from "../../hooks/useModal";
import { Modal } from "../ui/modal";
import Input from "../form/input/InputField";
import Button from "../ui/button/Button";
import Select from "../form/Select";
import { Dropdown } from "../ui/dropdown/Dropdown";
import Checkbox from "../form/input/Checkbox";
import ShowDetail from "./Action/ShowDetail";
import InfoBlock from "../ui/info/InfoBlock"; // Đảm bảo đường dẫn import đúng file bạn vừa tạo

import {
  Table,
  TableBody,
  TableCell,
  TableHeader,
  TableRow,
} from "../ui/table";
import { 
  ChevronLeftIcon,
} from "../../icons";
import Badge from "../ui/badge/Badge";

export default function Users() {
  const { user } = useAuth();
  const isAdmin = user.role._id === 1;
  // --- STATE ---
  const token = localStorage.getItem('admin_token') || sessionStorage.getItem('admin_token');
  const { isOpen: modalIsOpen, openModal, closeModal } = useModal();
 
  const [userData, setUserData] = useState([]); 
  const [isLoading, setIsLoading] = useState(false);

  // State Filter & Search
  const [searchTerm, setSearchTerm] = useState("");
  const [isFilterOpen, setIsFilterOpen] = useState(false);
  const [checkedStatus, setCheckedStatus] = useState([]); 

  // State cho Modal Detail
  const [selectedProfile, setSelectedProfile] = useState(null);
  
  // *** State mới: Quản lý Tab cho phần AI ***
  const [aiTab, setAiTab] = useState("meals"); 

  // Options
  const filterOptions = [
    { value: 'verified', label: 'Đã xác thực' },
    { value: 'unverified', label: 'Chưa xác thực' },
    { value: 'survey_done', label: 'Đã khảo sát' },
    { value: 'survey_pending', label: 'Chưa khảo sát' },
  ];

  const roleOptions = [
    { value: 2, label: "Moderator" },
    { value: 3, label: "User" },
  ];

  // --- API LOAD DATA ---
  useEffect(() => {
    apiLoadUsers();
  }, []);

  const apiLoadUsers = async () => {
    try {
      setIsLoading(true);
      const config = { headers: { 'x-access-token' : token } };
      const res = await axios.get('/api/admin/user-profile', config);
      const result = res.data;
      if (!result.success) return alert(result.message);
      setUserData(result.userProfiles || []); 
    } catch (err) {
      console.error("Lỗi lấy dữ liệu:", err);
    } finally {
      setIsLoading(false);
    }
  };

  // --- LOGIC SEARCH & FILTER ---
  const filteredData = useMemo(() => {
    let data = userData;
    if (searchTerm.trim() !== "") {
      const lowerTerm = searchTerm.toLowerCase();
      data = data.filter((item) => 
        (item.user.username && item.user.username.toLowerCase().includes(lowerTerm)) ||
        (item.user.email && item.user.email.toLowerCase().includes(lowerTerm))
      );
    }
    if (checkedStatus.length > 0) {
      data = data.filter((item) => {
        let matchVerify = true;
        let matchSurvey = true;
        const hasVerifyFilter = checkedStatus.includes('verified') || checkedStatus.includes('unverified');
        if (hasVerifyFilter) {
          const isVerified = item.user.isVerified;
          matchVerify = (checkedStatus.includes('verified') && isVerified) || 
                        (checkedStatus.includes('unverified') && !isVerified);
        }
        const hasSurveyFilter = checkedStatus.includes('survey_done') || checkedStatus.includes('survey_pending');
        if (hasSurveyFilter) {
            const isSurveyDone = item.user.isSurveyDone;
            matchSurvey = (checkedStatus.includes('survey_done') && isSurveyDone) ||
                          (checkedStatus.includes('survey_pending') && !isSurveyDone);
        }
        return matchVerify && matchSurvey;
      });
    }
    return data;
  }, [userData, searchTerm, checkedStatus]);

  // --- PAGINATION ---
  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 15;
  const totalPages = Math.ceil(filteredData.length / itemsPerPage);
  
  useEffect(() => { setCurrentPage(1); }, [searchTerm, checkedStatus]);

  const currentItems = filteredData.slice(
    (currentPage - 1) * itemsPerPage,
    currentPage * itemsPerPage
  );

  const goToPage = (page) => {
    if (page >= 1 && page <= totalPages) setCurrentPage(page);
  };

  // --- HANDLERS ---
  const handleToggleStatus = (value) => {
    setCheckedStatus((prev) => 
      prev.includes(value) ? prev.filter(item => item !== value) : [...prev, value]
    );
  };

  const handleView = (_id) => {
    const userToView = userData.find(item => item._id === _id);
    if (userToView) {
      setSelectedProfile(userToView);
      setAiTab("meals"); 
      openModal();
    }
  };

  const closeModalAndReset = () => {
    setSelectedProfile(null);
    closeModal();
  };

  const apiChangeRole = async (profileId, role) => {
    const confirm = window.confirm('Bạn có chắc muốn đổi vai trò của người dùng này?');
    if (!confirm) return;
    try {
      const newRole = {role: role};
      const config = { headers: { "x-access-token" : token }};
      const res = await axios.put('/api/admin/user-profile/change-role/' + profileId, newRole, config);
      if (res.data.success) {
        apiLoadUsers();
      } else {
        alert(res.data.message);
      }
    } catch (err) {
      console.error(err);
      alert("Lỗi cập nhật role");
    }
  };

  // Helper để lấy label từ value role (dùng cho chế độ xem)
  const getRoleLabel = (roleVal) => {
      const option = roleOptions.find(opt => opt.value === roleVal);
      return option ? option.label : (roleVal === 1 ? "Admin" : "Unknown");
  };

  return (
    <div className="max-w-full overflow-hidden rounded-2xl border border-gray-200 bg-white px-4 pb-3 pt-4 dark:border-gray-800 dark:bg-white/[0.03] sm:px-6">
      
      {/* HEADER TOOLBAR - ĐÃ CHỈNH SỬA: TITLE - SEARCH - FILTER */}
      <div className="flex flex-col gap-4 mb-4 sm:flex-row sm:items-center sm:justify-between">
        
        {/* 1. Title (Bên trái) */}
        <h3 className="text-lg font-semibold text-gray-800 dark:text-white/90 shrink-0">
          Quản lý người dùng
        </h3>

        {/* 2. Search Box (Ở giữa - Tự động co giãn) */}
        <div className="relative sm:flex-1 sm:max-w-md sm:mx-auto w-full">
            <span className="absolute -translate-y-1/2 pointer-events-none left-4 top-1/2">
              <svg className="fill-gray-500 dark:fill-gray-400" width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
                <path fillRule="evenodd" clipRule="evenodd" d="M3.04175 9.37363C3.04175 5.87693 5.87711 3.04199 9.37508 3.04199C12.8731 3.04199 15.7084 5.87693 15.7084 9.37363C15.7084 12.8703 12.8731 15.7053 9.37508 15.7053C5.87711 15.7053 3.04175 12.8703 3.04175 9.37363ZM9.37508 1.54199C5.04902 1.54199 1.54175 5.04817 1.54175 9.37363C1.54175 13.6991 5.04902 17.2053 9.37508 17.2053C11.2674 17.2053 13.003 16.5344 14.357 15.4176L17.177 18.238C17.4699 18.5309 17.9448 18.5309 18.2377 18.238C18.5306 17.9451 18.5306 17.4703 18.2377 17.1774L15.418 14.3573C16.5365 13.0033 17.2084 11.2669 17.2084 9.37363C17.2084 5.04817 13.7011 1.54199 9.37508 1.54199Z" fill="" />
              </svg>
            </span>
            <input
              type="text"
              placeholder="Tìm kiếm username, email..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="dark:bg-dark-900 h-10 w-full rounded-lg border border-gray-200 bg-transparent py-2.5 pl-12 pr-4 text-sm text-gray-800 shadow-theme-xs placeholder:text-gray-400 focus:border-brand-300 focus:outline-none focus:ring focus:ring-brand-500/10 dark:border-gray-800 dark:bg-gray-900 dark:bg-white/[0.03] dark:text-white/90 dark:placeholder:text-white/30 dark:focus:border-brand-800"
            />
        </div>

        {/* 3. Filter Button (Bên phải) */}
        <div className="relative shrink-0 flex justify-end">
            <div className="relative">
              <button 
                onClick={() => setIsFilterOpen(!isFilterOpen)}
                className={`inline-flex items-center gap-2 h-10 rounded-lg border px-4 py-2 text-theme-sm font-medium shadow-theme-xs hover:bg-gray-50 dark:hover:bg-white/[0.03] ${
                  checkedStatus.length > 0 
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
                Lọc {checkedStatus.length > 0 && <span className="flex items-center justify-center w-5 h-5 ml-1 text-xs text-white rounded-full bg-brand-500">{checkedStatus.length}</span>}
              </button>
               
              <Dropdown 
                isOpen={isFilterOpen} 
                onClose={() => setIsFilterOpen(false)} 
                className="absolute right-0 z-50 mt-2 w-56 flex flex-col rounded-xl border border-gray-200 bg-white p-2 shadow-theme-lg dark:border-gray-800 dark:bg-gray-900"
              >
                  <div className="px-3 py-2 text-xs font-semibold text-gray-500 uppercase">Trạng thái</div>
                  <ul className="flex flex-col gap-1 mb-2">
                    {filterOptions.slice(0, 2).map((opt) => (
                      <li key={opt.value}>
                          <label className="flex items-center gap-3 px-3 py-2 rounded-lg cursor-pointer hover:bg-gray-100 dark:hover:bg-white/5">
                          <Checkbox 
                            checked={checkedStatus.includes(opt.value)} 
                            onChange={() => handleToggleStatus(opt.value)} 
                          />
                          <span className="text-sm text-gray-700 dark:text-gray-300">{opt.label}</span>
                          </label>
                      </li>
                    ))}
                  </ul>
                  <div className="border-t border-gray-100 dark:border-gray-800 my-1"></div>
                  <div className="px-3 py-2 text-xs font-semibold text-gray-500 uppercase">Khảo sát</div>
                  <ul className="flex flex-col gap-1">
                    {filterOptions.slice(2, 4).map((opt) => (
                      <li key={opt.value}>
                          <label className="flex items-center gap-3 px-3 py-2 rounded-lg cursor-pointer hover:bg-gray-100 dark:hover:bg-white/5">
                          <Checkbox 
                            checked={checkedStatus.includes(opt.value)} 
                            onChange={() => handleToggleStatus(opt.value)} 
                          />
                          <span className="text-sm text-gray-700 dark:text-gray-300">{opt.label}</span>
                          </label>
                      </li>
                    ))}
                  </ul>

                  {/* Nút Reset Filter nếu cần */}
                  {checkedStatus.length > 0 && (
                    <div className="mt-2 pt-2 border-t border-gray-100 dark:border-gray-800 px-2">
                      <button 
                        onClick={() => setCheckedStatus([])}
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

      {/* TABLE DATA - GIỮ NGUYÊN ... */}
      <div className="p-4 border-t border-gray-100 dark:border-gray-800 sm:p-6">
        <div className="overflow-hidden rounded-xl border border-gray-200 bg-white dark:border-white/[0.05] dark:bg-white/[0.03]">
            <div className="max-w-full overflow-x-auto h-fit overflow-y-auto custom-scrollbar">
              <Table>
                <TableHeader className="sticky top-0 z-10 border-b border-gray-100 bg-white dark:border-white/[0.05] dark:bg-gray-800">
                  <TableRow>
                    <TableCell isHeader className="px-5 py-3 font-medium text-gray-500 text-start text-theme-sm dark:text-gray-400">Người dùng</TableCell>
                    <TableCell isHeader className="px-5 py-3 font-medium text-gray-500 text-start text-theme-sm dark:text-gray-400">Vai trò</TableCell>
                    <TableCell isHeader className="px-5 py-3 font-medium text-gray-500 text-start text-theme-sm dark:text-gray-400">Trạng thái</TableCell>
                    <TableCell isHeader className="px-5 py-3 font-medium text-gray-500 text-start text-theme-sm dark:text-gray-400">Khảo sát</TableCell>
                    <TableCell isHeader className="px-5 py-3 font-medium text-gray-500 text-start text-theme-sm dark:text-gray-400">Ngày cập nhật</TableCell>
                    <TableCell isHeader className="px-5 py-3 font-medium text-gray-500 text-start text-theme-sm dark:text-gray-400">Chi tiết</TableCell>
                  </TableRow>
                </TableHeader>
                <TableBody className="divide-y divide-gray-100 dark:divide-white/[0.05]">
                  {isLoading ? (
                    <TableRow><TableCell colSpan={6} className="text-center py-8">Đang tải...</TableCell></TableRow>
                  ) : currentItems.length === 0 ? (
                    <TableRow><TableCell colSpan={6} className="text-center py-8">Không tìm thấy người dùng phù hợp.</TableCell></TableRow>
                  ) : (
                    currentItems.map((profile) => (
                      <TableRow key={profile._id} className="hover:bg-gray-50 dark:hover:bg-white/[0.03]">
                        <TableCell className="px-5 py-4">
                          <div className="flex items-center gap-3">
                            <img 
                                src={`/${profile.user.image}`} 
                                alt="" 
                                className="w-10 h-10 rounded-full object-cover bg-gray-100"
                                onError={(e) => {e.target.style.display='none'}}
                            />
                            <div>
                              <div className="font-medium text-gray-800 dark:text-white">{profile.user.username}</div>
                              <div className="text-xs text-gray-500">{profile.user.email}</div>
                            </div>
                          </div>
                        </TableCell>
                        <TableCell className="px-5 py-3">
                            {/* 4. Logic hiển thị Role */}
                            {isAdmin ? (
                                // Nếu là Admin: Hiện Select để đổi quyền
                                <Select 
                                    options={roleOptions} 
                                    defaultValue={profile.user.role} 
                                    onChange={(val) => apiChangeRole(profile._id, val)}
                                    className="!py-1 !text-sm w-32"
                                />
                            ) : (
                                // Nếu là Moderator: Chỉ hiện text (Badge cho đẹp)
                                <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium border ${
                                    profile.user.role === 1 ? "bg-purple-50 text-purple-700 border-purple-200" :
                                    profile.user.role === 2 ? "bg-blue-50 text-blue-700 border-blue-200" :
                                    "bg-gray-50 text-gray-700 border-gray-200"
                                }`}>
                                    {getRoleLabel(profile.user.role)}
                                </span>
                            )}
                        </TableCell>
                        <TableCell className="px-5 py-3">
                          <Badge size="sm" color={profile.user.isVerified ? "success" : "warning"}>
                            {profile.user.isVerified ? "Đã xác thực" : "Chưa xác thực"}
                          </Badge>
                        </TableCell>
                        <TableCell className="px-5 py-3">
                          <Badge size="sm" color={profile.user.isSurveyDone ? "success" : "warning"}>
                            {profile.user.isSurveyDone ? "Đã hoàn thành" : "Chưa thực hiện"}
                          </Badge>
                        </TableCell>
                        <TableCell className="px-5 py-3 text-sm text-gray-500">
                          {dayjs(profile.user.updatedAt).format('DD/MM/YYYY')}
                        </TableCell>
                        <TableCell className="px-5 py-3 text-center">
                          <ShowDetail id={profile._id} onShow={handleView}/>
                        </TableCell>
                      </TableRow>
                    ))
                  )}
                </TableBody>
              </Table>
            </div>
            
            {/* Pagination Controls */}
            <div className="flex items-center justify-between px-5 py-4 border-t border-gray-100 dark:border-white/[0.05]">
               <span className="text-sm text-gray-500">
                 Hiển thị {(currentPage-1)*itemsPerPage + 1} - {Math.min(currentPage*itemsPerPage, filteredData.length)} trên {filteredData.length}
               </span>
               <div className="flex gap-2">
                 <button 
                    onClick={() => goToPage(currentPage - 1)} 
                    disabled={currentPage===1}
                    className="p-2 rounded border border-gray-300 disabled:opacity-50 hover:bg-gray-50 dark:border-gray-700 dark:hover:bg-gray-800"
                 >
                    <ChevronLeftIcon className="w-4 h-4"/>
                 </button>
                 {Array.from({length: totalPages}, (_, i) => i+1).slice(
                    Math.max(0, currentPage - 3), 
                    Math.min(totalPages, currentPage + 2)
                 ).map(p => (
                   <button 
                      key={p} 
                      onClick={() => goToPage(p)}
                      className={`px-3 py-1 text-sm rounded border ${currentPage === p ? 'bg-brand-600 text-white border-brand-600' : 'border-gray-300 hover:bg-gray-50 dark:border-gray-700 dark:hover:bg-gray-800 dark:text-gray-300'}`}
                   >
                     {p}
                   </button>
                 ))}
                 <button 
                    onClick={() => goToPage(currentPage + 1)} 
                    disabled={currentPage===totalPages}
                    className="p-2 rounded border border-gray-300 disabled:opacity-50 hover:bg-gray-50 dark:border-gray-700 dark:hover:bg-gray-800"
                 >
                    <ChevronLeftIcon className="w-4 h-4 rotate-180"/>
                 </button>
               </div>
            </div>
        </div>
      </div>

      {/* --- MODAL DETAIL (GIỮ NGUYÊN PHẦN BẠN ĐÃ ĐỒNG Ý) --- */}
      <Modal isOpen={modalIsOpen} onClose={closeModalAndReset} className="max-w-5xl m-4 h-[90vh]">
        {selectedProfile && (
            <div className="flex flex-col h-full bg-white dark:bg-gray-900 overflow-hidden rounded-2xl">
                {/* Modal Header */}
                <div className="px-6 py-5 border-b border-gray-100 dark:border-gray-800 flex items-center justify-between bg-gray-50/50 dark:bg-white/[0.02]">
                    <div className="flex items-center gap-4">
                        <div className="w-16 h-16 rounded-full border-2 border-white shadow-sm overflow-hidden bg-gray-200">
                            <img src={`/${selectedProfile.user.image}`} className="w-full h-full object-cover" alt="avatar" onError={(e) => {e.target.style.display='none'}}/>
                        </div>
                        <div>
                            <h4 className="text-xl font-bold text-gray-800 dark:text-white">{selectedProfile.user.username}</h4>
                            <div className="flex items-center gap-2 mt-1">
                                <span className="text-sm text-gray-500">{selectedProfile.user.email}</span>
                                <span className="text-gray-300">•</span>
                                <Badge size="sm" color={selectedProfile.user.isVerified ? "success" : "warning"}>
                                    {selectedProfile.user.isVerified ? "Verified" : "Unverified"}
                                </Badge>
                            </div>
                        </div>
                    </div>
                </div>

                {/* Modal Body */}
                <div className="flex-1 overflow-y-auto custom-scrollbar p-6 bg-gray-50/30 dark:bg-gray-900">
                    <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 h-full">
                        
                        {/* Cột 1 */}
                        <div className="lg:col-span-1 flex flex-col gap-6">
                            <div className="bg-white dark:bg-gray-800 p-5 rounded-xl border border-gray-200 dark:border-gray-700 shadow-sm">
                                <h5 className="font-semibold text-gray-800 dark:text-white mb-4 flex items-center gap-2">
                                    <svg className="w-5 h-5 text-brand-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" /></svg>
                                    Thông tin vật lý
                                </h5>
                                <div className="grid grid-cols-2 gap-y-4 gap-x-2">
                                    <InfoBlock label="Giới tính" value={selectedProfile.gender} />
                                    <InfoBlock label="Tuổi" value={selectedProfile.age} />
                                    <InfoBlock label="Chiều cao" value={`${selectedProfile.height?.value || 0} ${selectedProfile.height?.unit || 'cm'}`} />
                                    <InfoBlock label="Cân nặng" value={`${selectedProfile.weight?.value || 0} ${selectedProfile.weight?.unit || 'kg'}`} />
                                    <InfoBlock label="Cân nặng mục tiêu" value={selectedProfile.targetWeight} />
                                    <InfoBlock label="SĐT" value={selectedProfile.user.phone} />
                                </div>
                            </div>
                            <div className="bg-white dark:bg-gray-800 p-5 rounded-xl border border-gray-200 dark:border-gray-700 shadow-sm flex-1">
                                <h5 className="font-semibold text-gray-800 dark:text-white mb-4">Mục tiêu</h5>
                                <div className="p-4 bg-brand-50 dark:bg-brand-900/20 rounded-lg border border-brand-100 dark:border-brand-800">
                                    <p className="text-brand-800 dark:text-brand-300 font-medium">
                                        {selectedProfile.goal || "Chưa thiết lập mục tiêu"}
                                    </p>
                                </div>
                            </div>
                        </div>

                        {/* Cột 2 */}
                        <div className="lg:col-span-1">
                            <div className="bg-white dark:bg-gray-800 p-5 rounded-xl border border-gray-200 dark:border-gray-700 shadow-sm h-full">
                                <h5 className="font-semibold text-gray-800 dark:text-white mb-4 flex items-center gap-2">
                                    <svg className="w-5 h-5 text-brand-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>
                                    Hồ sơ sức khỏe
                                </h5>
                                <div className="space-y-6">
                                    <InfoBlock label="Tình trạng sức khỏe" isTag tags={selectedProfile.healthConditions} tagColor="red" />
                                    <InfoBlock label="Dị ứng / Cần tránh" isTag tags={selectedProfile.exclusions} tagColor="orange"/>
                                    <InfoBlock label="Thói quen sinh hoạt" isTag tags={selectedProfile.habits} tagColor="brand"/>
                                    <InfoBlock label="Phương pháp ăn kiêng" isTag tags={selectedProfile.diets} tagColor="brand"/>
                                </div>
                            </div>
                        </div>

                        {/* Cột 3 (Tabs) */}
                        <div className="lg:col-span-1">
                            <div className="bg-white dark:bg-gray-800 p-1 rounded-xl border border-gray-200 dark:border-gray-700 shadow-sm h-full flex flex-col overflow-hidden">
                                <div className="p-4 bg-brand-50 dark:bg-brand-900/10 border-b border-brand-100 dark:border-brand-800/30">
                                   <div className="flex items-center gap-2 mb-3 text-brand-700 dark:text-brand-400 font-semibold">
                                      <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M13 10V3L4 14h7v7l9-11h-7z" /></svg>
                                      AI Phân tích
                                   </div>
                                   <div className="flex p-1 bg-white/60 dark:bg-gray-700/50 rounded-lg">
                                      <button 
                                        onClick={() => setAiTab("meals")}
                                        className={`flex-1 py-1.5 text-xs font-medium rounded-md transition-all ${aiTab === 'meals' ? 'bg-white text-brand-600 shadow-sm dark:bg-gray-600 dark:text-white' : 'text-gray-500 hover:text-brand-600 dark:text-gray-400'}`}
                                      >
                                        Đề xuất
                                      </button>
                                      <button 
                                        onClick={() => setAiTab("avoid")}
                                        className={`flex-1 py-1.5 text-xs font-medium rounded-md transition-all ${aiTab === 'avoid' ? 'bg-white text-orange-600 shadow-sm dark:bg-gray-600 dark:text-white' : 'text-gray-500 hover:text-orange-600 dark:text-gray-400'}`}
                                      >
                                        Cần tránh
                                      </button>
                                      <button 
                                        onClick={() => setAiTab("advice")}
                                        className={`flex-1 py-1.5 text-xs font-medium rounded-md transition-all ${aiTab === 'advice' ? 'bg-white text-blue-600 shadow-sm dark:bg-gray-600 dark:text-white' : 'text-gray-500 hover:text-blue-600 dark:text-gray-400'}`}
                                      >
                                        Lời khuyên
                                      </button>
                                   </div>
                                </div>

                                <div className="p-5 overflow-y-auto flex-1 custom-scrollbar min-h-[300px] max-h-[500px]">
                                    {aiTab === 'meals' && (
                                      <div className="animate-fade-in">
                                          <span className="text-xs font-bold text-gray-400 uppercase tracking-wide mb-3 block">Thực đơn gợi ý</span>
                                          <div className="space-y-3">
                                              {selectedProfile.ai_meal_suggestions && selectedProfile.ai_meal_suggestions.length > 0 ? (
                                                  selectedProfile.ai_meal_suggestions.map((meal, idx) => (
                                                      <div key={idx} className="flex gap-3 p-3 bg-brand-50/50 dark:bg-brand-900/10 rounded-lg border border-brand-100 dark:border-brand-800/30">
                                                          <div className="w-8 h-8 rounded-full bg-brand-100 text-brand-600 flex items-center justify-center shrink-0 text-xs font-bold">
                                                            {idx + 1}
                                                          </div>
                                                          <div>
                                                            <p className="text-sm font-medium text-gray-800 dark:text-gray-200">{meal.name || meal}</p>
                                                          </div>
                                                      </div>
                                                  ))
                                              ) : (
                                                <div className="text-center py-10 text-gray-400 text-sm">Chưa có đề xuất</div>
                                              )}
                                          </div>
                                      </div>
                                    )}

                                    {aiTab === 'avoid' && (
                                      <div className="animate-fade-in">
                                          <span className="text-xs font-bold text-gray-400 uppercase tracking-wide mb-3 block">Hạn chế sử dụng</span>
                                          <div className="flex flex-wrap gap-2">
                                              {selectedProfile.ai_foods_to_avoid && selectedProfile.ai_foods_to_avoid.length > 0 ? (
                                                selectedProfile.ai_foods_to_avoid.map((f, i) => (
                                                  <span key={i} className="px-3 py-1.5 bg-orange-50 dark:bg-orange-900/10 border border-orange-100 dark:border-orange-900/30 text-sm text-orange-700 dark:text-orange-300 rounded-lg">
                                                      {f}
                                                  </span>
                                                ))
                                              ) : (
                                                <div className="text-center w-full py-10 text-gray-400 text-sm">Không có cảnh báo</div>
                                              )}
                                          </div>
                                      </div>
                                    )}

                                    {aiTab === 'advice' && (
                                      <div className="animate-fade-in">
                                          <span className="text-xs font-bold text-gray-400 uppercase tracking-wide mb-3 block">Lời khuyên chi tiết</span>
                                          <ul className="space-y-4">
                                              {selectedProfile.ai_recommendations && selectedProfile.ai_recommendations.length > 0 ? (
                                                selectedProfile.ai_recommendations.map((rec, i) => (
                                                  <li key={i} className="flex gap-3 text-sm text-gray-600 dark:text-gray-300">
                                                      <span className="mt-1.5 w-1.5 h-1.5 rounded-full bg-blue-400 shrink-0"></span>
                                                      <span className="leading-relaxed">{rec}</span>
                                                  </li>
                                                ))
                                              ) : (
                                                <div className="text-center py-10 text-gray-400 text-sm">Chưa có lời khuyên</div>
                                              )}
                                          </ul>
                                      </div>
                                    )}
                                </div>
                            </div>
                        </div>

                    </div>
                </div>

                {/* Modal Footer */}
                <div className="px-6 py-4 border-t border-gray-100 dark:border-gray-800 flex justify-end gap-3 bg-white dark:bg-gray-900">
                    <Button size="sm" variant="outline" onClick={closeModalAndReset}>
                        Đóng
                    </Button>
                </div>
            </div>
        )}
      </Modal>
    </div>
  );
}