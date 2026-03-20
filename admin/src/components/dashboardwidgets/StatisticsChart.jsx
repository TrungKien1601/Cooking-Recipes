import { useEffect, useState } from "react";
import Chart from "react-apexcharts";
import axios from "axios";

export default function StatisticsChart() {
  const token = localStorage.getItem('admin_token') || sessionStorage.getItem('admin_token');
  const [chartData, setChartData] = useState({
    users: [],
    recipes: []
  });
  const [loading, setLoading] = useState(true);

  // Gọi API lấy dữ liệu biểu đồ
  useEffect(() => {
    const fetchChartData = async () => {
      try {
         const config = { headers: { "x-access-token" : token }};
        
        const res = await axios.get('/api/admin/dashboard/chart', config);

        if (res.data.success) {
          setChartData(res.data.data);
        }
      } catch (error) {
        console.error("Lỗi tải biểu đồ:", error);
      } finally {
        setLoading(false);
      }
    };

    fetchChartData();
  }, []);

  // Cấu hình Chart
  const options = {
    legend: {
      show: true,
      position: "top",
      horizontalAlign: "left",
    },
    colors: ["#465FFF", "#0baf42"], // Màu Xanh đậm (User), Xanh nhạt (Recipe)
    chart: {
      fontFamily: "Outfit, sans-serif",
      height: 310,
      type: "area", // Đổi thành Area cho đẹp hơn Line
      toolbar: { show: false },
    },
    stroke: {
      curve: "smooth",
      width: [2, 2],
    },
    fill: {
      type: "gradient",
      gradient: {
        opacityFrom: 0.55,
        opacityTo: 0,
      },
    },
    markers: { size: 4, strokeColors: "#fff", strokeWidth: 2, hover: { size: 6 } },
    grid: {
      xaxis: { lines: { show: false } },
      yaxis: { lines: { show: true } },
    },
    dataLabels: { enabled: false },
    tooltip: { enabled: true },
    xaxis: {
      type: "category",
      categories: [
        "Tháng 1", "Tháng 2", "Tháng 3", "Tháng 4", "Tháng 5", "Tháng 6",
        "Tháng 7", "Tháng 8", "Tháng 9", "Tháng 10", "Tháng 11", "Tháng 12",
      ],
      axisBorder: { show: false },
      axisTicks: { show: false },
    },
    yaxis: {
      labels: { style: { fontSize: "12px", colors: ["#6B7280"] } },
    },
  };

  // Dữ liệu hiển thị (Series)
  const series = [
    {
      name: "Người dùng mới",
      data: loading ? Array(12).fill(0) : chartData.users, // Dữ liệu từ API
    },
    {
      name: "Công thức mới",
      data: loading ? Array(12).fill(0) : chartData.recipes, // Dữ liệu từ API
    },
  ];

  return (
    <div className="rounded-2xl border border-gray-200 bg-white px-5 pb-5 pt-5 dark:border-gray-800 dark:bg-white/[0.03] sm:px-6 sm:pt-6">
      <div className="flex flex-col gap-5 mb-6 sm:flex-row sm:justify-between">
        <div className="w-full">
          <h3 className="text-lg font-semibold text-gray-800 dark:text-white/90">
            Tăng trưởng nội dung & Người dùng
          </h3>
          <p className="mt-1 text-gray-500 text-theme-sm dark:text-gray-400">
            Thống kê số lượng tạo mới theo từng tháng trong năm nay
          </p>
        </div>
      </div>

      <div className="max-w-full overflow-x-auto custom-scrollbar">
        <div className="min-w-[1000px] xl:min-w-full">
          <Chart options={options} series={series} type="area" height={310} />
        </div>
      </div>
    </div>
  );
}