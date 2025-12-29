import { Navigate } from "react-router";
import { AuthProvider, useAuth } from "./hooks/AuthProvider";

export default function ProtectedRoute({ children }) {
    const { user, loading } = useAuth();

    if (loading) {
        return <div className="flex items-center justify-center h-screen">Đang tải...</div>;
    }

    if (!user) {
        // 3. Thêm thuộc tính `replace`
        // `replace`: Giúp xóa lịch sử duyệt web, để khi user bấm nút Back
        // họ không bị quay lại trang admin rồi lại bị đá ra login (vòng lặp vô tận).
        return <Navigate to="/admin/signin" replace/>;    
    }
    return children;
}