import { useEffect, useState } from "react";
import {
  Table,
  TableBody,
  TableCell,
  TableHeader,
  TableRow,
} from "../ui/table";
import { 
  MoreDotIcon,
  TrashBinIcon,
  PlusIcon,
  ChevronLeftIcon
} from "../../icons";
import Badge from "../ui/badge/Badge";

// 1. Tạo dữ liệu giả lập khoảng 25 dòng để test (3 trang)
// Trang 1: 1-10, Trang 2: 11-20, Trang 3: 21-25
const tableData = Array.from({ length: 25 }, (_, i) => ({
  id: i + 1,
  user: {
    image: `/images/user/user-${(i % 10) + 17}.jpg`, // Giả lập ảnh xoay vòng
    name: `User Name ${i + 1}`,
    role: ["Web Designer", "Project Manager", "Developer", "Tester"][i % 4],
  },
  projectName: `Project ${i + 1}`,
  team: {
    images: ["/images/user/user-22.jpg", "/images/user/user-23.jpg"],
  },
  budget: `${(Math.random() * 10).toFixed(1)}K`,
  status: ["Active", "Pending", "Cancel"][i % 3],
}));

export default function Pantries() {
  // 2. Cấu hình phân trang
  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 10; // Mỗi trang có 10 dữ liệu

  // 3. Tính toán dữ liệu cho trang hiện tại
  const totalPages = Math.ceil(tableData.length / itemsPerPage);
  const indexOfLastItem = currentPage * itemsPerPage;
  const indexOfFirstItem = indexOfLastItem - itemsPerPage;
  
  // Dữ liệu hiển thị (chỉ lấy 10 dòng thuộc trang hiện tại)
  const currentItems = tableData.slice(indexOfFirstItem, indexOfLastItem);

  const goToPage = (pageNumber) => {
    if (pageNumber >= 1 && pageNumber <= totalPages) {
      setCurrentPage(pageNumber);
      // Tùy chọn: Cuộn lên đầu bảng khi chuyển trang (nếu muốn)
      // document.getElementById("table-container")?.scrollTo(0, 0);
    }
  };

  return (
    <div className="overflow-hidden rounded-2xl border border-gray-200 bg-white px-4 pb-3 pt-4 dark:border-gray-800 dark:bg-white/[0.03] sm:px-6">
      <div className="flex flex-col gap-2 mb-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h3 className="text-lg font-semibold text-gray-800 dark:text-white/90">
            Quản lý tủ đồ ăn
          </h3>
        </div>

        <div className="flex items-center gap-3">
          <button className="inline-flex items-center gap-1 rounded-lg border border-gray-300 bg-brand-500 px-4 py-2.5 text-theme-sm font-medium text-white shadow-theme-xs hover:bg-brand-600 hover:text-gray-200 dark:border-gray-700 dark:bg-gray-800 dark:text-gray-400 dark:hover:bg-white/[0.03] dark:hover:text-gray-200">
            <PlusIcon />
            Thêm thẻ
          </button>
          <button className="inline-flex items-center gap-2 rounded-lg border border-gray-300 bg-white px-4 py-2.5 text-theme-sm font-medium text-gray-700 shadow-theme-xs hover:bg-gray-50 hover:text-gray-800 dark:border-gray-700 dark:bg-gray-800 dark:text-gray-400 dark:hover:bg-white/[0.03] dark:hover:text-gray-200">
            <svg
              className="stroke-current fill-white dark:fill-gray-800"
              width="20"
              height="20"
              viewBox="0 0 20 20"
              fill="none"
              xmlns="http://www.w3.org/2000/svg"
            >
              <path
                d="M2.29004 5.90393H17.7067"
                stroke=""
                strokeWidth="1.5"
                strokeLinecap="round"
                strokeLinejoin="round"
              />
              <path
                d="M17.7075 14.0961H2.29085"
                stroke=""
                strokeWidth="1.5"
                strokeLinecap="round"
                strokeLinejoin="round"
              />
              <path
                d="M12.0826 3.33331C13.5024 3.33331 14.6534 4.48431 14.6534 5.90414C14.6534 7.32398 13.5024 8.47498 12.0826 8.47498C10.6627 8.47498 9.51172 7.32398 9.51172 5.90415C9.51172 4.48432 10.6627 3.33331 12.0826 3.33331Z"
                fill=""
                stroke=""
                strokeWidth="1.5"
              />
              <path
                d="M7.91745 11.525C6.49762 11.525 5.34662 12.676 5.34662 14.0959C5.34661 15.5157 6.49762 16.6667 7.91745 16.6667C9.33728 16.6667 10.4883 15.5157 10.4883 14.0959C10.4883 12.676 9.33728 11.525 7.91745 11.525Z"
                fill=""
                stroke=""
                strokeWidth="1.5"
              />
            </svg>
            Lọc
          </button>
        </div> 
      </div>
      <div className="p-4 border-t border-gray-100 dark:border-gray-800 sm:p-6">
        <div className="space-y-6">
          <div className="overflow-hidden rounded-xl border border-gray-200 bg-white dark:border-white/[0.05] dark:bg-white/[0.03]">
            
            {/* 4. Vùng chứa bảng có thanh cuộn (Scroll Container) */}
            {/* max-h-[420px]: Giới hạn chiều cao hiển thị khoảng 5 dòng + header */}
            {/* overflow-y-auto: Hiện thanh cuộn để xem hết 10 dòng của trang hiện tại */}
            <div 
              id="table-container"
              className="max-w-full overflow-x-auto max-h-[420px] overflow-y-auto custom-scrollbar"
            >
              <div className="min-w-[1050px]">
                <Table>
                  {/* Header dính (Sticky) để không bị trôi khi cuộn xem 10 dòng */}
                  <TableHeader className="sticky top-0 z-10 border-b border-gray-100 bg-white dark:border-white/[0.05] dark:bg-gray-800">
                    <TableRow>
                      <TableCell isHeader className="px-5 py-3 font-medium text-gray-500 text-start text-theme-sm dark:text-gray-400">User</TableCell>
                      <TableCell isHeader className="px-5 py-3 font-medium text-gray-500 text-start text-theme-sm dark:text-gray-400">Project Name</TableCell>
                      <TableCell isHeader className="px-5 py-3 font-medium text-gray-500 text-start text-theme-sm dark:text-gray-400">Team</TableCell>
                      <TableCell isHeader className="px-5 py-3 font-medium text-gray-500 text-start text-theme-sm dark:text-gray-400">Status</TableCell>
                      <TableCell isHeader className="px-5 py-3 font-medium text-gray-500 text-start text-theme-sm dark:text-gray-400">Budget</TableCell>
                      <TableCell isHeader className="px-5 py-3 font-medium text-gray-500 text-start text-theme-sm dark:text-gray-400"></TableCell>
                    </TableRow>
                  </TableHeader>

                  <TableBody className="divide-y divide-gray-100 dark:divide-white/[0.05]">
                    {currentItems.map((order) => (
                      <TableRow key={order.id}>
                        <TableCell className="px-5 py-4 sm:px-6 text-start">
                          <div className="flex items-center gap-3">
                            <div className="w-10 h-10 overflow-hidden rounded-full">
                              {/* Fallback ảnh nếu cần */}
                              <div className="w-full h-full bg-gray-200 flex items-center justify-center">
                                  <span className="text-xs">{order.id}</span>
                              </div>
                            </div>
                            <div>
                              <span className="block font-medium text-gray-800 text-theme-sm dark:text-white/90">
                                {order.user.name}
                              </span>
                              <span className="block text-gray-500 text-theme-xs dark:text-gray-400">
                                {order.user.role}
                              </span>
                            </div>
                          </div>
                        </TableCell>
                        <TableCell className="px-4 py-3 text-gray-500 text-start text-theme-sm dark:text-gray-400">
                          {order.projectName}
                        </TableCell>
                        <TableCell className="px-4 py-3 text-gray-500 text-start text-theme-sm dark:text-gray-400">
                          <div className="flex -space-x-2">
                            {order.team.images.map((teamImage, index) => (
                              <div
                                key={index}
                                className="w-6 h-6 overflow-hidden border-2 border-white rounded-full dark:border-gray-900 bg-gray-300"
                              >
                              </div>
                            ))}
                          </div>
                        </TableCell>
                        <TableCell className="px-4 py-3 text-gray-500 text-start text-theme-sm dark:text-gray-400">
                          <Badge
                            size="sm"
                            color={
                              order.status === "Active"
                                ? "success"
                                : order.status === "Pending"
                                  ? "warning"
                                  : "error"
                            }
                          >
                            {order.status}
                          </Badge>
                        </TableCell>
                        <TableCell className="px-4 py-3 text-gray-500 text-theme-sm dark:text-gray-400">
                          {order.budget}
                        </TableCell>
                        <TableCell className="pr-8 py-3 text-end text-theme-sm">
                          <button className="pr-10 py-0 mr-2 text-error-600 dark:text-error-500">
                            <TrashBinIcon className="size-5" />
                          </button>
                          <button className="pl-10 py-0 mx-2 text-gray-500 dark:text-gray-400">
                            <MoreDotIcon className="size-5" />
                          </button>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </div>
            </div>

            {/* 5. Điều khiển phân trang (Pagination Controls) */}
            <div className="flex items-center justify-between px-5 py-4 border-t border-gray-100 dark:border-white/[0.05]">
              <span className="text-sm text-gray-500 dark:text-gray-400">
                Showing {indexOfFirstItem + 1} to {Math.min(indexOfLastItem, tableData.length)} of {tableData.length} entries
              </span>
              <div className="flex items-center space-x-2">
                <button
                  onClick={() => goToPage(currentPage - 1)}
                  disabled={currentPage === 1}
                  className={`px-3 py-2 rounded border text-sm ${
                    currentPage === 1
                      ? "bg-gray-100 border-gray-300 text-gray-400 cursor-not-allowed dark:bg-gray-800 dark:border-gray-600 dark:text-gray-600"
                      : "bg-white border-gray-300 text-gray-700 hover:bg-gray-50 dark:bg-gray-900 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-800"
                  }`}
                >
                  <ChevronLeftIcon />
                </button>

                {Array.from({ length: totalPages }, (_, index) => (
                  <button
                    key={index + 1}
                    onClick={() => goToPage(index + 1)}
                    className={`px-3 py-[5px] rounded border text-sm ${
                      currentPage === index + 1
                        ? "bg-blue-600 text-white border-blue-300"
                        : "bg-white text-gray-700 border-gray-300 hover:bg-gray-50 dark:bg-gray-900 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-800"
                    }`}
                  >
                    {index + 1}
                  </button>
                ))}

                <button
                  onClick={() => goToPage(currentPage + 1)}
                  disabled={currentPage === totalPages}
                  className={`px-3 py-2 rounded border text-sm ${
                    currentPage === totalPages
                      ? "bg-gray-100 border-gray-300 text-gray-400 cursor-not-allowed dark:bg-gray-800 dark:border-gray-600 dark:text-gray-600"
                      : "bg-white border-gray-300 text-gray-700 hover:bg-gray-50 dark:bg-gray-900 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-800"
                  }`}
                >
                  <ChevronLeftIcon className="rotate-180" />
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}