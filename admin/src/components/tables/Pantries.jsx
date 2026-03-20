import { useEffect, useState, useMemo } from "react";
import axios from "axios";
import dayjs from "dayjs";
import { useAuth } from "../../hooks/AuthProvider";
import { useModal } from "../../hooks/useModal";

// UI Components
import {
  Table,
  TableBody,
  TableCell,
  TableHeader,
  TableRow,
} from "../ui/table";
import { 
  EyeIcon, // Icon con mắt để xem chi tiết
  TrashBinIcon,
  ChevronLeftIcon,
} from "../../icons";
import Badge from "../ui/badge/Badge";
import { Modal } from "../ui/modal";
import Button from "../ui/button/Button";

// Cấu hình đường dẫn ảnh
const BASE_MEDIA_URL = "http://localhost:5000/";

export default function Pantries() {
  const { user } = useAuth();
  const { isOpen: modalIsOpen, openModal, closeModal } = useModal();
  const [isLoading, setIsLoading] = useState(false);
  
  // State dữ liệu chính (Thống kê)
  const [pantryStats, setPantryStats] = useState([]);
  const [searchTerm, setSearchTerm] = useState('');

  // State cho Modal Chi tiết
  const [selectedUser, setSelectedUser] = useState(null); // Lưu info user đang xem
  const [userItems, setUserItems] = useState([]);       // Lưu danh sách đồ ăn của user đó
  const [isDetailLoading, setIsDetailLoading] = useState(false);

  const token = localStorage.getItem('admin_token') || sessionStorage.getItem('admin_token');
  const isAdmin = user.role && user.role._id === 1;

  // ==========================================
  // 1. API: LẤY DANH SÁCH THỐNG KÊ (MAIN TABLE)
  // ==========================================
  const apiLoadPantryStats = async () => {
    try {
      setIsLoading(true);
      const config = { headers: { "x-access-token": token } };
      const res = await axios.get('/api/admin/pantry', config);
      const result = res.data;
      
      if (result.success) {
        setPantryStats(result.data || []);
      } else {
        setPantryStats([]);
      }
    } catch (err) {
      console.error("Lỗi lấy dữ liệu pantry:", err);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    apiLoadPantryStats();
  }, []);

  // ==========================================
  // 2. API: LẤY CHI TIẾT & XOÁ (MODAL ACTIONS)
  // ==========================================
  
  // Hàm mở Modal và load dữ liệu chi tiết
  const handleViewDetails = async (userData) => {
    setSelectedUser(userData);
    openModal();
    setIsDetailLoading(true);
    setUserItems([]); // Reset list cũ

    try {
      const config = { headers: { "x-access-token": token } };
      // Gọi API lấy list đồ của user này
      const res = await axios.get(`/api/admin/pantry/user/${userData._id}`, config);
      if (res.data.success) {
        setUserItems(res.data.items || []);
      }
    } catch (err) {
      console.error("Lỗi lấy chi tiết:", err);
      alert("Không tải được dữ liệu chi tiết.");
    } finally {
      setIsDetailLoading(false);
    }
  };

  // Hàm xoá 1 món đồ cụ thể (trong Modal)
  const handleDeleteItem = async (itemId) => {
    if (!window.confirm("Bạn chắc chắn muốn xoá món đồ này của người dùng?")) return;

    try {
      const config = { headers: { "x-access-token": token } };
      const res = await axios.delete(`/api/admin/pantry/${itemId}`, config);
      
      if (res.data.success) {
        alert("Đã xoá thành công!");
        // Cập nhật lại list trong modal
        setUserItems(prev => prev.filter(item => item._id !== itemId));
        // Cập nhật lại số lượng ngoài bảng chính (giảm đi 1)
        setPantryStats(prev => prev.map(u => 
            u._id === selectedUser._id ? {...u, totalProducts: u.totalProducts - 1} : u
        ));
      } else {
        alert(res.data.message);
      }
    } catch (err) {
      console.error(err);
      alert("Lỗi khi xoá món đồ.");
    }
  };

  // ==========================================
  // 3. SEARCH & PAGINATION (MAIN TABLE)
  // ==========================================
  
  const filteredData = useMemo(() => {
    return pantryStats.filter(item => 
      item.username?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      item.email?.toLowerCase().includes(searchTerm.toLowerCase())
    );
  }, [pantryStats, searchTerm]);

  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 10;
  const totalPages = Math.ceil(filteredData.length / itemsPerPage) || 1;
  
  // Reset trang khi search
  useEffect(() => { setCurrentPage(1); }, [searchTerm]);

  const currentItems = filteredData.slice(
    (currentPage - 1) * itemsPerPage,
    currentPage * itemsPerPage
  );

  const getMediaPath = (path) => {
    if (!path) return "";
    return path.startsWith('blob') || path.startsWith('http') ? path : `${BASE_MEDIA_URL}${path}`;
  };

  // Helper check hạn sử dụng
  const getExpiryStatus = (date) => {
      const today = dayjs();
      const expiry = dayjs(date);
      const diffDays = expiry.diff(today, 'day');

      if (diffDays < 0) return <Badge color="error" size="sm">Đã hết hạn</Badge>;
      if (diffDays <= 3) return <Badge color="warning" size="sm">Sắp hết ({diffDays} ngày)</Badge>;
      return <span className="text-gray-500 text-xs">{expiry.format('DD/MM/YYYY')}</span>;
  };

  return (
    <div className="max-w-full overflow-hidden rounded-2xl border border-gray-200 bg-white px-4 pb-3 pt-4 dark:border-gray-800 dark:bg-white/[0.03] sm:px-6">
      
      {/* HEADER */}
      <div className="flex flex-col gap-2 mb-4 sm:flex-row sm:items-center sm:justify-between">
        <h3 className="text-lg font-semibold text-gray-800 dark:text-white/90">
          Quản lý lạnh người dùng
        </h3>
        
        {/* Search */}
        <div className="relative max-w-md w-full sm:w-auto">
             <input
                type="text"
                placeholder="Tìm user hoặc email..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="dark:bg-dark-900 h-10 w-full rounded-lg border border-gray-200 bg-transparent py-2 pl-4 pr-10 text-sm focus:border-brand-300 focus:outline-none focus:ring focus:ring-brand-500/10 dark:border-gray-800 dark:text-white/90"
              />
        </div>
      </div>

      {/* TABLE CHÍNH: DANH SÁCH USER & THỐNG KÊ */}
      <div className="overflow-x-auto rounded-xl border border-gray-200 bg-white dark:border-gray-800 dark:bg-gray-900">
        <Table>
          <TableHeader className="bg-gray-50 dark:bg-gray-800">
            <TableRow>
              <TableCell isHeader className="px-5 py-3 font-medium text-gray-500 text-start text-theme-sm dark:text-gray-400">Người dùng</TableCell>
              <TableCell isHeader className="px-5 py-3 font-medium text-gray-500 text-center text-theme-sm dark:text-gray-400">Tổng sản phẩm</TableCell>
              <TableCell isHeader className="px-5 py-3 font-medium text-gray-500 text-center text-theme-sm dark:text-gray-400">Cập nhật lần cuối</TableCell>
              <TableCell isHeader className="px-5 py-3 font-medium text-gray-500 text-start text-theme-sm dark:text-gray-400"></TableCell>
            </TableRow>
          </TableHeader>

          <TableBody className="divide-y divide-gray-100 dark:divide-gray-800">
            {isLoading ? (
               <TableRow><TableCell colSpan={4} className="py-8 text-center text-gray-500">Đang tải thống kê...</TableCell></TableRow>
            ) : currentItems.length === 0 ? (
               <TableRow><TableCell colSpan={4} className="py-8 text-center text-gray-500">Không có dữ liệu.</TableCell></TableRow>
            ) : (
              currentItems.map((userStats) => (
                <TableRow key={userStats._id} className="hover:bg-gray-50 dark:hover:bg-gray-800/50">
                  {/* Cột User */}
                  <TableCell className="px-5 py-3">
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 rounded-full overflow-hidden bg-gray-100 border border-gray-200">
                        {userStats.avatar ? (
                            <img src={getMediaPath(userStats.avatar)} alt="Avt" className="w-full h-full object-cover"/>
                        ) : (
                            <div className="w-full h-full flex items-center justify-center bg-brand-100 text-brand-600 font-bold text-xs">
                                {userStats.username?.charAt(0).toUpperCase()}
                            </div>
                        )}
                      </div>
                      <div>
                        <div className="font-medium text-gray-800 dark:text-white">{userStats.username}</div>
                        <div className="text-xs text-gray-500">{userStats.email}</div>
                      </div>
                    </div>
                  </TableCell>

                  {/* Cột Tổng số lượng */}
                  <TableCell className="px-5 py-3 text-center">
                    <span className="inline-flex items-center justify-center px-2.5 py-0.5 rounded-full text-sm font-medium bg-blue-50 text-blue-700">
                        {userStats.totalProducts} món
                    </span>
                  </TableCell>

                  {/* Cột Thời gian */}
                  <TableCell className="px-5 py-3 text-center text-sm text-gray-500">
                     {userStats.lastUpdated ? dayjs(userStats.lastUpdated).format("HH:mm DD/MM/YYYY") : "-"}
                  </TableCell>

                  {/* Cột Hành động */}
                  <TableCell className="px-5 py-3 text-end">
                    <button 
                        onClick={() => handleViewDetails(userStats)}
                        className="inline-flex items-center gap-1 px-3 py-1.5 text-xs font-medium text-brand-600 bg-brand-50 rounded-lg hover:bg-brand-100 transition"
                    >
                        <EyeIcon className="size-4"/> Chi tiết
                    </button>
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


      {/* ================= MODAL CHI TIẾT ================= */}
      <Modal isOpen={modalIsOpen} onClose={closeModal} className="max-w-[900px] m-4 max-h-[90vh] flex flex-col">
         {/* Modal Header */}
         <div className="p-5 border-b border-gray-100 dark:border-gray-800 flex justify-between items-center bg-gray-50 dark:bg-gray-800/50 rounded-t-2xl">
            <div>
                <h3 className="text-lg font-bold text-gray-800 dark:text-white">Chi tiết tủ đồ</h3>
                {selectedUser && (
                    <p className="text-sm text-gray-500">Của người dùng: <span className="font-medium text-brand-600">{selectedUser.username}</span> ({userItems.length} món)</p>
                )}
            </div>
          </div>

         {/* Modal Body: Danh sách Items */}
         <div className="p-0 overflow-y-auto custom-scrollbar flex-1 bg-white dark:bg-gray-900 min-h-[300px]">
            {isDetailLoading ? (
                <div className="flex items-center justify-center h-40 text-gray-500">Đang tải dữ liệu chi tiết...</div>
            ) : userItems.length === 0 ? (
                <div className="flex flex-col items-center justify-center h-60 text-gray-400">
                    <p>Tủ đồ của người dùng này đang trống.</p>
                </div>
            ) : (
                <Table>
                    <TableHeader className="bg-gray-50 dark:bg-gray-800 sticky top-0 z-10">
                        <TableRow>
                            <TableCell isHeader className="px-5 py-3 font-medium text-gray-500 text-start text-theme-sm dark:text-gray-400">Sản phẩm</TableCell>
                            <TableCell isHeader className="px-5 py-3 font-medium text-gray-500 text-start text-theme-sm dark:text-gray-400">Số lượng</TableCell>
                            <TableCell isHeader className="px-5 py-3 font-medium text-gray-500 text-start text-theme-sm dark:text-gray-400">Bảo quản</TableCell>
                            <TableCell isHeader className="px-5 py-3 font-medium text-gray-500 text-start text-theme-sm dark:text-gray-400">Hạn sử dụng</TableCell>
                            {isAdmin && <TableCell isHeader className="px-5 py-3 font-medium text-gray-500 text-start text-theme-sm dark:text-gray-400">Xoá</TableCell>}
                        </TableRow>
                    </TableHeader>
                    <TableBody>
                        {userItems.map(item => (
                            <TableRow key={item._id} className="hover:bg-gray-50 dark:hover:bg-gray-800/50">
                                <TableCell className="px-4 py-3">
                                    <div className="flex items-center gap-3">
                                        <div className="w-12 h-12 rounded-lg border overflow-hidden bg-gray-100 shrink-0">
                                            {item.image_url ? (
                                                <img src={getMediaPath(item.image_url)} alt={item.name} className="w-full h-full object-cover"/>
                                            ) : (
                                                <div className="w-full h-full flex items-center justify-center text-xs text-gray-400">No Img</div>
                                            )}
                                        </div>
                                        <div>
                                            <div className="font-medium text-gray-800 dark:text-white text-sm">{item.name}</div>
                                            <div className="text-[10px] text-gray-400 uppercase">{item.addMethod}</div>
                                        </div>
                                    </div>
                                </TableCell>
                                <TableCell className="px-4 py-3 text-center text-sm">
                                    {item.quantity} {item.unit}
                                </TableCell>
                                <TableCell className="px-4 py-3 text-center">
                                    <span className="text-xs bg-gray-100 px-2 py-1 rounded text-gray-600 border border-gray-200">
                                        {item.storage}
                                    </span>
                                </TableCell>
                                <TableCell className="px-4 py-3 text-center">
                                    {getExpiryStatus(item.expiryDate)}
                                </TableCell>
                                {isAdmin && (
                                    <TableCell className="px-4 py-3 text-end">
                                        <button 
                                            onClick={() => handleDeleteItem(item._id)}
                                            className="text-gray-400 hover:text-red-500 p-1 transition"
                                            title="Xoá món này"
                                        >
                                            <TrashBinIcon className="size-5 text-error-600 dark:text-error-500" />
                                        </button>
                                    </TableCell>
                                )}
                            </TableRow>
                        ))}
                    </TableBody>
                </Table>
            )}
         </div>
         
         {/* Footer */}
         <div className="p-4 border-t border-gray-100 dark:border-gray-800 flex justify-end bg-gray-50 dark:bg-gray-800/50 rounded-b-2xl">
            <Button variant="outline" onClick={closeModal} className="text-sm py-2">Đóng</Button>
         </div>
      </Modal>
    </div>
  );
}