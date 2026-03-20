import { useState, useEffect } from "react";
import axios from "axios";
import { Link, useNavigate } from "react-router-dom"; // Sửa lại thành react-router-dom cho chuẩn
import { Dropdown } from "../ui/dropdown/Dropdown";
import { DropdownItem } from "../ui/dropdown/DropdownItem";

// Hàm helper để định dạng thời gian (VD: 5 phút trước)
const formatTimeAgo = (dateString) => {
  const date = new Date(dateString);
  const now = new Date();
  const seconds = Math.floor((now - date) / 1000);
  
  if (seconds < 60) return "Vừa xong";
  const minutes = Math.floor(seconds / 60);
  if (minutes < 60) return `${minutes} phút trước`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours} giờ trước`;
  return date.toLocaleDateString('vi-VN');
};

export default function NotificationDropdown() {
  const [isOpen, setIsOpen] = useState(false);
  
  // State dữ liệu
  const [notifications, setNotifications] = useState([]);
  const [unreadCount, setUnreadCount] = useState(0);
  const navigate = useNavigate();

  // Lấy token từ storage (kiểm tra key bạn đang dùng là gì)
  const token = localStorage.getItem('admin_token') || sessionStorage.getItem('admin_token');

  // URL API (Sửa lại port nếu server bạn khác 3000)
  const API_URL = '/api/admin/notification';

  // --- 1. Gọi API lấy thông báo ---
  const fetchNotifications = async () => {
    try {
      const res = await axios.get(API_URL, {
        headers: { "x-access-token": token } // Header khớp với JwtUtil backend
      });
      if (res.data.success) {
        setNotifications(res.data.notifications);
        setUnreadCount(res.data.unreadCount);
      }
    } catch (err) {
      console.error("Lỗi tải thông báo:", err);
    }
  };

  // --- 2. Gọi API đánh dấu đã đọc ---
  const markAllAsRead = async () => {
    try {
        await axios.put(`${API_URL}/read`, {}, {
             headers: { "x-access-token": token }
        });
        setUnreadCount(0);
        // Cập nhật giao diện ngay lập tức
        setNotifications(prev => prev.map(n => ({...n, isRead: true})));
    } catch (err) { console.error(err); }
  };

  // --- 3. Polling: Tự động cập nhật mỗi 30s ---
  useEffect(() => {
    fetchNotifications();
    const interval = setInterval(fetchNotifications, 30000);
    return () => clearInterval(interval);
  }, []);

  // --- 4. Xử lý UI ---
  function toggleDropdown() {
    setIsOpen(!isOpen);
    // Nếu mở ra và có tin chưa đọc -> Đánh dấu đã đọc
    if (!isOpen && unreadCount > 0) {
       markAllAsRead();
    }
  }

  function closeDropdown() {
    setIsOpen(false);
  }

  const handleItemClick = (noti) => {
    closeDropdown();
    // Điều hướng tùy loại thông báo
    if (noti.type === 'RECIPE_NEW') {
        navigate('/admin/recipes'); // Đến trang quản lý món ăn
    } else if (noti.type === 'USER_NEW') {
        navigate('/admin/users'); // Đến trang quản lý người dùng
    }
  };

  return (
    <div className="relative">
      <button
        className="relative flex items-center justify-center text-gray-500 transition-colors bg-white border border-gray-200 rounded-full dropdown-toggle hover:text-gray-700 h-11 w-11 hover:bg-gray-100 dark:border-gray-800 dark:bg-gray-900 dark:text-gray-400 dark:hover:bg-gray-800 dark:hover:text-white"
        onClick={toggleDropdown}
      >
        {/* Chấm đỏ báo tin chưa đọc */}
        <span
          className={`absolute right-0 top-0.5 z-10 h-2.5 w-2.5 rounded-full bg-orange-400 ${
            unreadCount === 0 ? "hidden" : "flex"
          }`}
        >
          <span className="absolute inline-flex w-full h-full bg-orange-400 rounded-full opacity-75 animate-ping"></span>
        </span>
        
        {/* Icon Chuông */}
        <svg
          className="fill-current"
          width="20"
          height="20"
          viewBox="0 0 20 20"
          xmlns="http://www.w3.org/2000/svg"
        >
          <path
            fillRule="evenodd"
            clipRule="evenodd"
            d="M10.75 2.29248C10.75 1.87827 10.4143 1.54248 10 1.54248C9.58583 1.54248 9.25004 1.87827 9.25004 2.29248V2.83613C6.08266 3.20733 3.62504 5.9004 3.62504 9.16748V14.4591H3.33337C2.91916 14.4591 2.58337 14.7949 2.58337 15.2091C2.58337 15.6234 2.91916 15.9591 3.33337 15.9591H4.37504H15.625H16.6667C17.0809 15.9591 17.4167 15.6234 17.4167 15.2091C17.4167 14.7949 17.0809 14.4591 16.6667 14.4591H16.375V9.16748C16.375 5.9004 13.9174 3.20733 10.75 2.83613V2.29248ZM14.875 14.4591V9.16748C14.875 6.47509 12.6924 4.29248 10 4.29248C7.30765 4.29248 5.12504 6.47509 5.12504 9.16748V14.4591H14.875ZM8.00004 17.7085C8.00004 18.1228 8.33583 18.4585 8.75004 18.4585H11.25C11.6643 18.4585 12 18.1228 12 17.7085C12 17.2943 11.6643 16.9585 11.25 16.9585H8.75004C8.33583 16.9585 8.00004 17.2943 8.00004 17.7085Z"
            fill="currentColor"
          />
        </svg>
      </button>

      <Dropdown
        isOpen={isOpen}
        onClose={closeDropdown}
        className="absolute -right-[240px] mt-[17px] flex h-[480px] w-[350px] flex-col rounded-2xl border border-gray-200 bg-white p-3 shadow-theme-lg dark:border-gray-800 dark:bg-gray-dark sm:w-[361px] lg:right-0"
      >
        <div className="flex items-center justify-between pb-3 mb-3 border-b border-gray-100 dark:border-gray-700">
          <h5 className="text-lg font-semibold text-gray-800 dark:text-gray-200">
            Thông báo ({unreadCount})
          </h5>
          <button onClick={toggleDropdown} className="text-gray-500 hover:text-gray-700">
             <svg className="fill-current" width="24" height="24" viewBox="0 0 24 24"><path fillRule="evenodd" clipRule="evenodd" d="M6.21967 7.28131C5.92678 6.98841 5.92678 6.51354 6.21967 6.22065C6.51256 5.92775 6.98744 5.92775 7.28033 6.22065L11.999 10.9393L16.7176 6.22078C17.0105 5.92789 17.4854 5.92788 17.7782 6.22078C18.0711 6.51367 18.0711 6.98855 17.7782 7.28144L13.0597 12L17.7782 16.7186C18.0711 17.0115 18.0711 17.4863 17.7782 17.7792C17.4854 18.0721 17.0105 18.0721 16.7176 17.7792L11.999 13.0607L7.28033 17.7794C6.98744 18.0722 6.51256 18.0722 6.21967 17.7794C5.92678 17.4865 5.92678 17.0116 6.21967 16.7187L10.9384 12L6.21967 7.28131Z" fill="currentColor"/></svg>
          </button>
        </div>

        <ul className="flex flex-col h-auto overflow-y-auto custom-scrollbar">
          {notifications.length === 0 ? (
             <div className="flex flex-col items-center justify-center h-32 text-gray-500 text-sm">
                Không có thông báo mới
             </div>
          ) : (
            notifications.map((noti) => (
              <li key={noti._id}>
                <DropdownItem
                  onItemClick={() => handleItemClick(noti)}
                  className={`flex gap-3 rounded-lg border-b border-gray-100 p-3 px-4.5 py-3 hover:bg-gray-100 dark:border-gray-800 dark:hover:bg-white/5 cursor-pointer ${!noti.isRead ? 'bg-orange-50/50 dark:bg-white/5' : ''}`}
                >
                  {/* Avatar User hoặc Ảnh Recipe */}
                  <span className="relative block w-10 h-10 rounded-full z-1 max-w-10 flex-shrink-0 border border-gray-100 dark:border-gray-700">
                    {/* Logic hiển thị ảnh: Nếu có ảnh từ referenceId (Recipe/User) thì hiển thị, nếu không thì dùng icon fallback */}
                    {noti.referenceId && noti.referenceId.image ? (
                        <img
                          src={`/${noti.referenceId.image}`}
                          alt="Img"
                          className="w-full h-full overflow-hidden rounded-full object-cover"
                          onError={(e) => {e.target.onerror = null; e.target.src = "/uploads/default.png"}} // Fallback nếu ảnh lỗi
                        />
                    ) : (
                        <div className={`w-full h-full rounded-full flex items-center justify-center text-white font-bold text-sm ${noti.type === 'RECIPE_NEW' ? 'bg-blue-400' : 'bg-green-400'}`}>
                           {noti.type === 'RECIPE_NEW' ? 'R' : 'U'}
                        </div>
                    )}

                    {!noti.isRead && (
                        <span className="absolute bottom-0 right-0 z-10 h-2.5 w-2.5 rounded-full border-[1.5px] border-white bg-red-500 dark:border-gray-900"></span>
                    )}
                  </span>

                  <span className="block flex-1">
                    <span className="mb-1 block text-theme-sm text-gray-500 dark:text-gray-400">
                      <span className="font-semibold text-gray-800 dark:text-white/90">
                        {noti.type === 'RECIPE_NEW' ? "Công thức mới" : "Người dùng mới"}
                      </span>
                      <span className="ml-1 text-sm block line-clamp-2 mt-0.5">
                        {noti.message}
                      </span>
                    </span>

                    <span className="flex items-center gap-2 text-xs text-gray-400 dark:text-gray-500">
                      <span>{noti.type === 'RECIPE_NEW' ? 'Recipes' : 'System'}</span>
                      <span className="w-1 h-1 bg-gray-400 rounded-full"></span>
                      <span>{formatTimeAgo(noti.createdAt)}</span>
                    </span>
                  </span>
                </DropdownItem>
              </li>
            ))
          )}
        </ul>

        <div className="pt-2 mt-auto border-t dark:border-gray-700">
            <Link
            to="/admin/notifications"
            className="block w-full py-2 text-sm font-medium text-center text-gray-700 bg-gray-50 border border-gray-200 rounded-lg hover:bg-gray-100 dark:bg-gray-800 dark:text-gray-300 dark:border-gray-700 dark:hover:bg-gray-700"
            onClick={closeDropdown}
            >
            Xem tất cả
            </Link>
        </div>
      </Dropdown>
    </div>
  );
}