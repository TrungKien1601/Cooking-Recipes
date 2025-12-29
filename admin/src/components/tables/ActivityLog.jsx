import dayjs from "dayjs";
import { useEffect, useState, useMemo } from "react";
import axios from "axios";
import { useModal } from "../../hooks/useModal";
import { Modal } from "../ui/modal";
import Input from "../form/input/InputField"; // Vẫn giữ import nếu muốn dùng, hoặc thay bằng div text
import Button from "../ui/button/Button";
import { Dropdown } from "../ui/dropdown/Dropdown";
import Checkbox from "../form/input/Checkbox";
import ShowDetail from "./Action/ShowDetail";

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

// Helper component để hiển thị thông tin trong Modal cho đẹp (tương tự InfoBlock)
const DetailRow = ({ label, value }) => (
  <div className="flex flex-col gap-1">
    <span className="text-xs font-medium text-gray-500 uppercase tracking-wider dark:text-gray-400">
      {label}
    </span>
    <span className="text-sm font-medium text-gray-900 dark:text-white/90 break-words">
      {value || "--"}
    </span>
  </div>
);

export default function ActivityLog() {
  const token = localStorage.getItem('admin_token') || sessionStorage.getItem('admin_token');
  const { isOpen: modalIsOpen, openModal, closeModal } = useModal();
  const [ isLoading, setIsLoading ] = useState(false);
  const [ actLogData, setActLogData ] = useState([]);

  // --- STATE CHO FILTER & SEARCH ---
  const [ searchTerm, setSearchTerm ] = useState("");
  const [ isFilterOpen, setIsFilterOpen ] = useState(false);
  const [ checkedFilters, setCheckedFilters ] = useState([]); 

  // --- STATE CHO MODAL ---
  const [ selectedLog, setSelectedLog ] = useState(null);

  // --- OPTIONS ---
  const roleOptions = [
    { value: 'Administrator', label: 'Administrator' },
    { value: 'Moderator', label: 'Moderator' },
    { value: 'User', label: 'User' },
  ];

  const actionOptions = [
    { value: 'LOGIN', label: 'Login' },
    { value: 'CREATE', label: 'Create' },
    { value: 'UPDATE', label: 'Update' },
    { value: 'DELETE', label: 'Delete' },
  ];

  // --- API LOAD DATA ---
  useEffect(() => {
      apiLoadActivityLogs();
  }, []);

  const apiLoadActivityLogs = async () => {
    try {
      setIsLoading(true);
      const config = { headers: { "x-access-token" : token } };
      // Lấy toàn bộ dữ liệu về rồi lọc client-side cho mượt
      const res = await axios.get('/api/admin/activity-log', config);
      const result = res.data;

      if (!result.success) return alert(result.message);
      setActLogData(result.actlogs || []);
    } catch (err) {
      console.error("Lỗi lấy dữ liệu:", err);
    } finally {
      setIsLoading(false);
    }
  };

  // --- LOGIC FILTER & SEARCH (Core logic) ---
  const filteredLogs = useMemo(() => {
    let data = actLogData;

    // 1. Tìm kiếm (Search)
    if (searchTerm.trim() !== "") {
      const lowerTerm = searchTerm.toLowerCase();
      data = data.filter((log) => 
        (log.adminName && log.adminName.toLowerCase().includes(lowerTerm)) ||
        (log.targetName && log.targetName.toLowerCase().includes(lowerTerm)) ||
        (log.description && log.description.toLowerCase().includes(lowerTerm))
      );
    }

    // 2. Lọc (Filter)
    if (checkedFilters.length > 0) {
      data = data.filter((log) => {
        // Tách các filter đang chọn ra 2 nhóm: Role và Action
        const selectedRoles = checkedFilters.filter(f => ['Administrator', 'Moderator', 'User'].includes(f));
        const selectedActions = checkedFilters.filter(f => ['LOGIN', 'CREATE', 'UPDATE', 'DELETE'].includes(f));

        // Logic: (Thỏa mãn Role HOẶC không chọn Role nào) VÀ (Thỏa mãn Action HOẶC không chọn Action nào)
        const matchRole = selectedRoles.length === 0 || selectedRoles.includes(log.adminRole);
        const matchAction = selectedActions.length === 0 || selectedActions.includes(log.action);

        return matchRole && matchAction;
      });
    }

    return data;
  }, [actLogData, searchTerm, checkedFilters]);


  // --- PAGINATION ---
  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 15;
  
  // Reset về trang 1 khi search/filter
  useEffect(() => { setCurrentPage(1); }, [searchTerm, checkedFilters]);

  const totalPages = Math.ceil(filteredLogs.length / itemsPerPage);
  const currentActLogs = filteredLogs.slice(
    (currentPage - 1) * itemsPerPage,
    currentPage * itemsPerPage
  );

  const goToPage = (page) => {
    if (page >= 1 && page <= totalPages) setCurrentPage(page);
  };

  // --- HANDLERS ---
  const handleToggleFilter = (value) => {
    setCheckedFilters((prev) => 
      prev.includes(value) ? prev.filter(item => item !== value) : [...prev, value]
    );
  };

  const handleView = (id) => {
    const log = actLogData.find(item => item._id === id);
    if (log) {
      setSelectedLog(log);
      openModal();
    }
  };

  const closeModalAndReset = () => {
    setSelectedLog(null);
    closeModal();
  };
    
  return (
    <div className="max-w-full overflow-hidden rounded-2xl border border-gray-200 bg-white px-4 pb-3 pt-4 dark:border-gray-800 dark:bg-white/[0.03] sm:px-6">
      
      {/* HEADER: Title - Search - Filter */}
      <div className="flex flex-col gap-4 mb-4 sm:flex-row sm:items-center sm:justify-between">
        <h3 className="text-lg font-semibold text-gray-800 dark:text-white/90 shrink-0">
          Hoạt động hệ thống
        </h3>

        {/* Search Bar (Centered) */}
        <div className="relative sm:flex-1 sm:max-w-md sm:mx-auto w-full">
            <span className="absolute -translate-y-1/2 pointer-events-none left-4 top-1/2">
              <svg className="fill-gray-500 dark:fill-gray-400" width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
                <path fillRule="evenodd" clipRule="evenodd" d="M3.04175 9.37363C3.04175 5.87693 5.87711 3.04199 9.37508 3.04199C12.8731 3.04199 15.7084 5.87693 15.7084 9.37363C15.7084 12.8703 12.8731 15.7053 9.37508 15.7053C5.87711 15.7053 3.04175 12.8703 3.04175 9.37363ZM9.37508 1.54199C5.04902 1.54199 1.54175 5.04817 1.54175 9.37363C1.54175 13.6991 5.04902 17.2053 9.37508 17.2053C11.2674 17.2053 13.003 16.5344 14.357 15.4176L17.177 18.238C17.4699 18.5309 17.9448 18.5309 18.2377 18.238C18.5306 17.9451 18.5306 17.4703 18.2377 17.1774L15.418 14.3573C16.5365 13.0033 17.2084 11.2669 17.2084 9.37363C17.2084 5.04817 13.7011 1.54199 9.37508 1.54199Z" fill="" />
              </svg>
            </span>
            <input
              type="text"
              placeholder="Tìm kiếm hành động, đối tượng..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="dark:bg-dark-900 h-10 w-full rounded-lg border border-gray-200 bg-transparent py-2.5 pl-12 pr-4 text-sm text-gray-800 shadow-theme-xs placeholder:text-gray-400 focus:border-brand-300 focus:outline-none focus:ring focus:ring-brand-500/10 dark:border-gray-800 dark:bg-gray-900 dark:bg-white/[0.03] dark:text-white/90 dark:placeholder:text-white/30 dark:focus:border-brand-800"
            />
        </div>

        {/* Filter Dropdown */}
        <div className="relative shrink-0 flex justify-end">
            <div className="relative">
              <button 
                onClick={() => setIsFilterOpen(!isFilterOpen)}
                className={`inline-flex items-center gap-2 h-10 rounded-lg border px-4 py-2 text-theme-sm font-medium shadow-theme-xs hover:bg-gray-50 dark:hover:bg-white/[0.03] ${
                  checkedFilters.length > 0 
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
                Lọc {checkedFilters.length > 0 && <span className="flex items-center justify-center w-5 h-5 ml-1 text-xs text-white rounded-full bg-brand-500">{checkedFilters.length}</span>}
              </button>
               
              <Dropdown 
                isOpen={isFilterOpen} 
                onClose={() => setIsFilterOpen(false)} 
                className="absolute right-0 z-50 mt-2 w-56 flex flex-col rounded-xl border border-gray-200 bg-white p-2 shadow-theme-lg dark:border-gray-800 dark:bg-gray-900"
              >
                  {/* Role Filter Section */}
                  <div className="px-3 py-2 text-xs font-semibold text-gray-500 uppercase">Vai trò</div>
                  <ul className="flex flex-col gap-1 mb-2">
                    {roleOptions.map((opt) => (
                      <li key={opt.value}>
                          <label className="flex items-center gap-3 px-3 py-2 rounded-lg cursor-pointer hover:bg-gray-100 dark:hover:bg-white/5">
                          <Checkbox 
                            checked={checkedFilters.includes(opt.value)} 
                            onChange={() => handleToggleFilter(opt.value)} 
                          />
                          <span className="text-sm text-gray-700 dark:text-gray-300">{opt.label}</span>
                          </label>
                      </li>
                    ))}
                  </ul>
                  
                  <div className="border-t border-gray-100 dark:border-gray-800 my-1"></div>
                  
                  {/* Action Filter Section */}
                  <div className="px-3 py-2 text-xs font-semibold text-gray-500 uppercase">Hành động</div>
                  <ul className="flex flex-col gap-1">
                    {actionOptions.map((opt) => (
                      <li key={opt.value}>
                          <label className="flex items-center gap-3 px-3 py-2 rounded-lg cursor-pointer hover:bg-gray-100 dark:hover:bg-white/5">
                          <Checkbox 
                            checked={checkedFilters.includes(opt.value)} 
                            onChange={() => handleToggleFilter(opt.value)} 
                          />
                          <span className="text-sm text-gray-700 dark:text-gray-300">{opt.label}</span>
                          </label>
                      </li>
                    ))}
                  </ul>

                  {/* Nút Reset Filter nếu cần */}
                  {checkedFilters.length > 0 && (
                    <div className="mt-2 pt-2 border-t border-gray-100 dark:border-gray-800 px-2">
                      <button 
                        onClick={() => setCheckedFilters([])}
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

      <div className="p-4 border-t border-gray-100 dark:border-gray-800 sm:p-6">
        <div className="space-y-6">
          <div className="overflow-hidden rounded-xl border border-gray-200 bg-white dark:border-white/[0.05] dark:bg-white/[0.03]">
            <div className="max-w-full overflow-x-auto h-fit overflow-y-auto custom-scrollbar">
              <Table>
                <TableHeader className="sticky top-0 z-10 border-b border-gray-100 bg-white dark:border-white/[0.05] dark:bg-gray-800">
                  <TableRow>
                    <TableCell isHeader className="w-[5%] px-5 py-3 font-medium text-gray-500 text-start text-theme-sm dark:text-gray-400">#</TableCell>
                    <TableCell isHeader className="w-[30%] px-5 py-3 font-medium text-gray-500 text-start text-theme-sm dark:text-gray-400">Người thực hiện</TableCell>
                    <TableCell isHeader className="w-[15%] px-5 py-3 font-medium text-gray-500 text-center text-theme-sm dark:text-gray-400">Hành động</TableCell>
                    <TableCell isHeader className="w-[15%] px-5 py-3 font-medium text-gray-500 text-center text-theme-sm dark:text-gray-400">Tên đối tượng</TableCell>
                    <TableCell isHeader className="w-[25%] px-5 py-3 font-medium text-gray-500 text-center text-theme-sm dark:text-gray-400">Thời gian</TableCell>
                    <TableCell isHeader className="w-[10%] px-5 py-3 font-medium text-gray-500 text-start text-theme-sm dark:text-gray-400">Chi tiết</TableCell>
                  </TableRow>
                </TableHeader>

                <TableBody className="divide-y divide-gray-100 dark:divide-white/[0.05]">
                  {isLoading ? (
                      <TableRow>
                        <TableCell colSpan={6} className="px-5 py-8 text-center text-gray-500">Đang tải dữ liệu...</TableCell>
                      </TableRow>
                    ) : currentActLogs.length === 0 ? (
                      <TableRow>
                        <TableCell colSpan={6} className="px-5 py-8 text-center text-gray-500">Không tìm thấy dữ liệu.</TableCell>
                      </TableRow>
                    ) : (
                      currentActLogs.map((log, index) => (
                        <TableRow key={log._id} className="hover:bg-gray-50 dark:hover:bg-white/[0.03] transition-colors duration-200">
                          <TableCell className="px-4 py-3 sm:px-3 text-center text-gray-500">
                            {(currentPage - 1) * itemsPerPage + index + 1}
                          </TableCell>

                          <TableCell className="px-4 py-3 sm:px-3 text-start">
                            <div className="flex flex-col">
                                <span className="font-medium text-gray-800 dark:text-white">{log.adminName}</span>
                                <span className="text-xs text-gray-400">{log.adminRole}</span>
                            </div>
                          </TableCell>

                          <TableCell className="px-4 py-3 text-center">
                            <Badge size="sm" color={
                              log.action === 'CREATE' ? "success" : 
                              log.action === "UPDATE" ? "warning" : 
                              log.action === "LOGIN" ? "brand" : "error" 
                            }>
                              {log.action}
                            </Badge>
                          </TableCell>

                          <TableCell className="px-4 py-3 text-center">
                            <div className="flex flex-col items-center">
                              <span className="text-sm text-gray-700 dark:text-gray-300">
                                {log.targetName || "N/A"}
                              </span>
                              <span className="text-xs text-gray-400">
                                {log.targetCollection ? `(${log.targetCollection})` : ""}
                              </span>
                            </div>
                          </TableCell>

                          <TableCell className="px-4 py-3 text-gray-500 text-center text-theme-sm dark:text-gray-400">
                            {dayjs(log.createdAt).format('DD/MM/YYYY - HH:mm')}
                          </TableCell>

                          <TableCell className="px-3 py-3 text-center">
                            <ShowDetail id={log._id} onShow={handleView} />
                          </TableCell>
                        </TableRow>
                      ))
                    )
                  }
                </TableBody>
              </Table>
            </div>

            {/* Pagination Controls */}
            <div className="flex items-center justify-between px-5 py-4 border-t border-gray-100 dark:border-white/[0.05]">
              <span className="text-sm text-gray-500 dark:text-gray-400">
                Hiển thị {filteredLogs.length > 0 ? (currentPage-1)*itemsPerPage + 1 : 0} - {Math.min(currentPage*itemsPerPage, filteredLogs.length)} trên {filteredLogs.length}
              </span>
              <div className="flex items-center space-x-2">
                <button
                  onClick={() => goToPage(currentPage - 1)}
                  disabled={currentPage === 1}
                  className="p-2 rounded border border-gray-300 disabled:opacity-50 hover:bg-gray-50 dark:border-gray-700 dark:hover:bg-gray-800"
                >
                  <ChevronLeftIcon className="w-4 h-4"/>
                </button>

                {/* Simplified Pagination for long lists */}
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
                  <ChevronLeftIcon className="w-4 h-4 rotate-180" />
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* MODAL CHI TIẾT */}
      <Modal isOpen={modalIsOpen} onClose={closeModalAndReset} className="max-w-3xl m-4 mt-20">
        <div className="bg-white dark:bg-gray-900 rounded-2xl overflow-hidden flex flex-col max-h-[90vh]">
          {/* Header */}
          <div className="px-6 py-5 border-b border-gray-100 dark:border-gray-800 bg-gray-50/50 dark:bg-white/[0.02] flex justify-between items-center">
            <div>
                <h4 className="text-xl font-bold text-gray-800 dark:text-white">Chi tiết hoạt động</h4>
                <p className="text-sm text-gray-500 mt-1">ID: {selectedLog?._id}</p>
            </div>
            <button onClick={closeModalAndReset} className="text-gray-400 hover:text-gray-600 dark:hover:text-gray-300">
                <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" /></svg>
            </button>
          </div>
          
          {/* Body */}
          {selectedLog && (
              <div className="p-6 overflow-y-auto custom-scrollbar">
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                      <div className="bg-gray-50 dark:bg-gray-800/50 p-4 rounded-xl space-y-4">
                          <h5 className="font-semibold text-brand-600 dark:text-brand-400 mb-2 border-b border-gray-200 dark:border-gray-700 pb-2">Người thực hiện</h5>
                          <DetailRow label="Tên tài khoản" value={selectedLog.adminName} />
                          <DetailRow label="Vai trò" value={selectedLog.adminRole} />
                          <DetailRow label="Email" value={selectedLog.adminEmail} />
                          <DetailRow label="IP Address" value={selectedLog.ipAddress} />
                      </div>

                      <div className="bg-gray-50 dark:bg-gray-800/50 p-4 rounded-xl space-y-4">
                          <h5 className="font-semibold text-brand-600 dark:text-brand-400 mb-2 border-b border-gray-200 dark:border-gray-700 pb-2">Hành động & Đối tượng</h5>
                          <DetailRow label="Hành động" value={selectedLog.action} />
                          <DetailRow label="Collection" value={selectedLog.targetCollection} />
                          <DetailRow label="Tên đối tượng" value={selectedLog.targetName} />
                          <DetailRow label="ID Đối tượng" value={selectedLog.targetId} />
                      </div>

                      <div className="md:col-span-2 bg-white dark:bg-gray-800 border border-gray-100 dark:border-gray-700 p-4 rounded-xl space-y-4">
                          <DetailRow label="Mô tả chi tiết" value={selectedLog.description} />
                          <DetailRow label="User Agent" value={selectedLog.userAgent} />
                      </div>
                  </div>
              </div>
          )}

          {/* Footer */}
          <div className="px-6 py-4 border-t border-gray-100 dark:border-gray-800 bg-gray-50/50 dark:bg-white/[0.02] flex justify-end">
             <Button size="sm" variant="outline" onClick={closeModalAndReset}>Đóng</Button>
          </div>
        </div>
      </Modal>
    </div>
  );
}