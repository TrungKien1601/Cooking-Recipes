import { useState, useEffect } from "react";
import axios from "axios"; // Đảm bảo bạn đã cài axios: npm install axios
import {
  BoxIconLine,
  GroupIcon,
} from "../../icons";

export default function Statiscal() {
  const token = localStorage.getItem('admin_token') || sessionStorage.getItem('admin_token');
  // 1. Khởi tạo state để lưu trữ dữ liệu thống kê
  const [stats, setStats] = useState({
    users: 0,
    recipes: 0,
    ingredients: 0,
  });

  // State để hiển thị trạng thái đang tải
  const [loading, setLoading] = useState(true);

  // 2. Hàm gọi API lấy dữ liệu
  useEffect(() => {
    const fetchDashboardStats = async () => {
      try {
        
        if (!token) {
          console.warn("Không tìm thấy token đăng nhập");
          setLoading(false);
          return;
        }
        
        const config = { headers: { "x-access-token" : token }};
        
        const response = await axios.get('/api/admin/dashboard/stats', config);

        if (response.data.success) {
          setStats(response.data.data);
        }
      } catch (error) {
        console.error("Lỗi khi tải thống kê:", error);
      } finally {
        setLoading(false); // Tắt trạng thái loading dù thành công hay thất bại
      }
    };

    fetchDashboardStats();
  }, []);

  return (
    <div className="grid grid-cols-1 gap-4 sm:grid-cols-3 md:gap-6">
      {/* */}
      <div className="rounded-2xl border border-gray-200 bg-white p-5 dark:border-gray-800 dark:bg-white/[0.03] md:p-6">
        <div className="flex items-center justify-center w-12 h-12 bg-gray-100 rounded-xl dark:bg-gray-800">
          <GroupIcon className="text-gray-800 size-6 dark:text-white/90" />
        </div>

        <div className="flex items-end justify-between mt-5">
          <div>
            <span className="text-sm text-gray-500 dark:text-gray-400">
              Tổng người dùng
            </span>
            <h4 className="mt-2 font-bold text-gray-800 text-title-sm dark:text-white/90">
              {loading ? "..." : stats.users.toLocaleString('vi-VN')}
            </h4>
          </div>
        </div>
      </div>
      {/* */}

      {/* */}
      <div className="rounded-2xl border border-gray-200 bg-white p-5 dark:border-gray-800 dark:bg-white/[0.03] md:p-6">
        <div className="flex items-center justify-center w-12 h-12 bg-gray-100 rounded-xl dark:bg-gray-800">
          <BoxIconLine className="text-gray-800 size-6 dark:text-white/90" />
        </div>
        <div className="flex items-end justify-between mt-5">
          <div>
            <span className="text-sm text-gray-500 dark:text-gray-400">
              Tổng công thức
            </span>
            <h4 className="mt-2 font-bold text-gray-800 text-title-sm dark:text-white/90">
              {loading ? "..." : stats.recipes.toLocaleString('vi-VN')}
            </h4>
          </div>
        </div>
      </div>
      {/* */}

      {/* */}
      <div className="rounded-2xl border border-gray-200 bg-white p-5 dark:border-gray-800 dark:bg-white/[0.03] md:p-6">
        <div className="flex items-center justify-center w-12 h-12 bg-gray-100 rounded-xl dark:bg-gray-800">
          <BoxIconLine className="text-gray-800 size-6 dark:text-white/90" />
        </div>
        <div className="flex items-end justify-between mt-5">
          <div>
            <span className="text-sm text-gray-500 dark:text-gray-400">
              Tổng nguyên liệu
            </span>
            <h4 className="mt-2 font-bold text-gray-800 text-title-sm dark:text-white/90">
              {loading ? "..." : stats.ingredients.toLocaleString('vi-VN')}
            </h4>
          </div>
        </div>
      </div>
      {/* */}
    </div>
  );
}