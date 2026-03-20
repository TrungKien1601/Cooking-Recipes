import { useEffect, useState } from "react";
import axios from "axios";
import {
  Table,
  TableBody,
  TableCell,
  TableHeader,
  TableRow,
} from "../ui/table";
import Badge from "../ui/badge/Badge";

export default function PendingRecipes() {
  const [recipes, setRecipes] = useState([]);
  const [isLoading, setIsLoading] = useState(true);

  // Lấy token giống cách làm bên file Recipes.jsx
  const token = localStorage.getItem('admin_token') || sessionStorage.getItem('admin_token');

  useEffect(() => {
    const fetchPendingRecipes = async () => {
      try {
        const config = { headers: { "x-access-token": token } };
        // Gọi API lấy danh sách công thức
        const res = await axios.get('/api/admin/recipe', config);
        
        if (res.data.success) {
          // Lọc lấy các món đang "Chờ duyệt" và lấy 5 món mới nhất
          // (Giả sử danh sách trả về đã sắp xếp theo thời gian, nếu chưa bạn có thể sort thêm)
          const pendingList = (res.data.recipes || [])
            .filter(r => r.status === "Chờ duyệt")
            .slice(0, 5); // Giới hạn 5 dòng để bảng không quá dài
            
          setRecipes(pendingList);
        }
      } catch (err) {
        console.error("Lỗi lấy dữ liệu dashboard:", err);
      } finally {
        setIsLoading(false);
      }
    };

    fetchPendingRecipes();
  }, [token]);

  return (
    <div className="overflow-hidden rounded-2xl border border-gray-200 bg-white px-4 pb-3 pt-4 dark:border-gray-800 dark:bg-white/[0.03] sm:px-6">
      <div className="flex flex-col gap-2 mb-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h3 className="text-lg font-semibold text-gray-800 dark:text-white/90">
            Công thức chờ duyệt
          </h3>
          <p className="text-xs text-gray-500 mt-1">Danh sách các món ăn đang đợi xét duyệt</p>
        </div>
      </div>
      
      <div className="max-w-full overflow-x-auto max-h-[400px] overflow-y-auto custom-scrollbar">
        <Table>
          {/* Table Header */}
          <TableHeader className="border-gray-100 dark:border-gray-800 border-y sticky top-0 z-10 bg-white dark:bg-gray-900">
            <TableRow>
              <TableCell isHeader className="py-3 font-medium text-gray-500 text-start text-theme-xs dark:text-gray-400">
                Công thức
              </TableCell>
              <TableCell isHeader className="py-3 font-medium text-gray-500 text-start text-theme-xs dark:text-gray-400">
                Người tạo
              </TableCell>
              <TableCell isHeader className="py-3 font-medium text-gray-500 text-start text-theme-xs dark:text-gray-400">
                Thời gian nấu
              </TableCell>
              <TableCell isHeader className="py-3 font-medium text-gray-500 text-start text-theme-xs dark:text-gray-400">
                Tình trạng
              </TableCell>
            </TableRow>
          </TableHeader>

          {/* Table Body */}
          <TableBody className="divide-y divide-gray-100 dark:divide-gray-800">
            {isLoading ? (
               <TableRow>
                 <TableCell colSpan={4} className="py-4 text-center text-gray-500 text-sm">Đang tải dữ liệu...</TableCell>
               </TableRow>
            ) : recipes.length === 0 ? (
               <TableRow>
                 <TableCell colSpan={4} className="py-4 text-center text-gray-500 text-sm">Không có công thức nào đang chờ duyệt.</TableCell>
               </TableRow>
            ) : (
              recipes.map((product) => (
                <TableRow key={product._id} className="">
                  <TableCell className="py-3">
                    <div className="flex items-center gap-3">
                      <div className="h-[50px] w-[50px] overflow-hidden rounded-md border border-gray-100 dark:border-gray-700">
                        {product.image ? (
                            <img
                              src={`/${product.image}`} // Logic đường dẫn ảnh từ Recipes.jsx
                              className="h-full w-full object-cover"
                              alt={product.name}
                            />
                        ) : (
                            <div className="h-full w-full bg-gray-100 flex items-center justify-center text-xs text-gray-400">No img</div>
                        )}
                      </div>
                      <div>
                        <p className="font-medium text-gray-800 text-theme-sm dark:text-white/90 line-clamp-1">
                          {product.name}
                        </p>
                        <span className="text-gray-500 text-theme-xs dark:text-gray-400">
                          {product.servings} người ăn
                        </span>
                      </div>
                    </div>
                  </TableCell>
                  <TableCell className="py-3 text-gray-500 text-theme-sm dark:text-gray-400">
                    {product.author?.username || "Ẩn danh"}
                  </TableCell>
                  <TableCell className="py-3 text-gray-500 text-theme-sm dark:text-gray-400">
                    {product.cookTimeMinutes} phút
                  </TableCell>
                  <TableCell className="py-3 text-gray-500 text-theme-sm dark:text-gray-400">
                    <Badge
                      size="sm"
                      color="warning" // Vì đang lọc 'Chờ duyệt' nên mặc định là warning
                    >
                      {product.status}
                    </Badge>
                  </TableCell>
                </TableRow>
              ))
            )}
          </TableBody>
        </Table>
      </div>
    </div>
  );
}