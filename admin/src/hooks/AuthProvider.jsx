import { createContext, useContext, useState, useEffect, useLayoutEffect } from "react";
import axios from "axios";
import { useNavigate } from "react-router"; 

const AuthContext = createContext(null);

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  const navigate = useNavigate(); 

  // --- HÀM MỚI: Xử lý đăng xuất ---
  const logoutAction = () => {
    setUser(null);
    localStorage.removeItem("admin_token");
    sessionStorage.removeItem("admin_token");
    navigate("/admin/signin");
  };

  // --- HÀM LOAD USER ---
  const loadUser = async () => {
    const token = localStorage.getItem("admin_token") || sessionStorage.getItem("admin_token");
    if (!token) {
        setLoading(false);
        return;
    }

    try {
        const res = await axios.get('/api/admin/auth/me', {
            headers: { 'x-access-token': token }
        });
        if(res.data.success) {
            setUser(res.data.user);
        }
    } catch (err) {
        console.error("Token lỗi hoặc hết hạn", err);
        // Nếu load user lúc đầu mà lỗi quyền -> Logout luôn
        logoutAction(); 
    } finally {
        setLoading(false);
    }
  };
  
  const reloadUser = async () => {
    loadUser();
  }

  useEffect(() => {
    loadUser();
  }, []);

  // --- HÀM MỚI: Xử lý đăng nhập ---
  const loginAction = async (token, userData, isRemember) => {
    const storage = isRemember ? localStorage : sessionStorage;
    storage.setItem('admin_token', token);
    
    if (isRemember) sessionStorage.removeItem('admin_token');
    else localStorage.removeItem('admin_token');

    setUser(userData); 
    navigate('/admin'); 
  };

  // ============================================================
  // QUAN TRỌNG: AXIOS INTERCEPTOR - XỬ LÝ KHI BỊ HẠ QUYỀN
  // ============================================================
  useLayoutEffect(() => {
    // Tạo một interceptor để lắng nghe TẤT CẢ phản hồi từ API
    const authInterceptor = axios.interceptors.response.use(
      (response) => {
        return response; // Nếu API thành công, cho qua
      },
      (error) => {
        // Nếu API trả về lỗi 401 (Chưa đăng nhập) hoặc 403 (Không đủ quyền)
        if (error.response && (error.response.status === 401 || error.response.status === 403)) {
           // => Đuổi người dùng ra trang login ngay lập tức
           logoutAction();
        }
        return Promise.reject(error);
      }
    );

    // Dọn dẹp interceptor khi component unmount
    return () => {
      axios.interceptors.response.eject(authInterceptor);
    };
  }, [navigate]); // Chạy lại nếu navigate thay đổi (thực tế navigate ổn định)

  return (
    <AuthContext.Provider value={{ user, loading, loginAction, logoutAction, reloadUser }}>
      {!loading && children} 
    </AuthContext.Provider>
  );
};

export const useAuth = () => useContext(AuthContext);