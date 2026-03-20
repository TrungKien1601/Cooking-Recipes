import { useEffect, useState } from "react";
import Chart from "react-apexcharts";
import axios from "axios";

export default function RecipeDifficultyChart() {
  const [series, setSeries] = useState([]); // Dữ liệu số lượng (VD: [10, 5, 2])
  const [loading, setLoading] = useState(true);

  // Nhãn hiển thị tương ứng
  const labels = ["Dễ", "Trung bình", "Khó"];

  useEffect(() => {
    const fetchData = async () => {
      try {
        const token = localStorage.getItem("admin_token") || sessionStorage.getItem("admin_token");
        const config = { headers: { "x-access-token": token } };
        
        // Gọi API lấy danh sách công thức
        const res = await axios.get("/api/admin/recipe", config);

        if (res.data.success) {
          const recipes = res.data.recipes || [];

          // Khởi tạo bộ đếm
          let countEasy = 0;
          let countMedium = 0;
          let countHard = 0;

          // Duyệt qua từng món ăn để đếm
          recipes.forEach((recipe) => {
            // Chuẩn hóa string về chữ thường để so sánh cho chính xác nếu cần
            const diff = recipe.difficulty; 
            if (diff === "Dễ") countEasy++;
            else if (diff === "Trung bình") countMedium++;
            else if (diff === "Khó") countHard++;
          });

          // Cập nhật state theo thứ tự của labels: [Dễ, TB, Khó]
          setSeries([countEasy, countMedium, countHard]);
        }
      } catch (err) {
        console.error("Lỗi tải dữ liệu biểu đồ:", err);
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, []);

  // Cấu hình biểu đồ (Options)
  const options = {
    chart: {
      type: "donut", // Dùng 'donut' nhìn sẽ hiện đại hơn 'pie', bạn có thể đổi thành 'pie' nếu thích đặc ruột
      fontFamily: "Outfit, sans-serif",
    },
    labels: labels,
    colors: ["#10B981", "#F59E0B", "#EF4444"], // Màu sắc: Xanh (Dễ), Vàng (TB), Đỏ (Khó)
    legend: {
      position: "bottom",
      fontFamily: "Outfit, sans-serif",
      markers: {
        radius: 12,
      },
      itemMargin: {
        horizontal: 10,
        vertical: 5
      }
    },
    plotOptions: {
      pie: {
        donut: {
          size: "65%", // Độ dày của vòng donut
          labels: {
            show: true,
            total: {
              show: true,
              label: "Tổng món",
              fontSize: "16px",
              fontFamily: "Outfit, sans-serif",
              fontWeight: 600,
              color: "#6B7280",
              formatter: function (w) {
                // Tính tổng số lượng hiển thị ở giữa
                return w.globals.seriesTotals.reduce((a, b) => a + b, 0);
              }
            }
          }
        }
      }
    },
    dataLabels: {
      enabled: true, // Hiển thị % trên biểu đồ
    },
    tooltip: {
      enabled: true,
      y: {
        formatter: function (val) {
          return val + " món";
        }
      }
    },
    stroke: {
        show: false // Tắt viền trắng giữa các miếng cho mượt
    }
  };

  return (
    // Wrapper class giống hệt RecipeTable.jsx để kích thước và khung viền đồng bộ
    <div className="flex flex-col h-full overflow-hidden rounded-2xl border border-gray-200 bg-white px-4 pb-3 pt-4 dark:border-gray-800 dark:bg-white/[0.03] sm:px-6">
      
      {/* Header Title */}
      <div className="flex flex-col gap-2 mb-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h3 className="text-lg font-semibold text-gray-800 dark:text-white/90">
            Phân bố độ khó
          </h3>
          <p className="text-xs text-gray-500 mt-1">
            Tỷ lệ các mức độ chế biến món ăn
          </p>
        </div>
      </div>

      {/* Chart Container */}
      <div className="flex-1 flex items-center justify-center min-h-[300px]">
        {loading ? (
           <div className="text-gray-400 text-sm animate-pulse">Đang phân tích dữ liệu...</div>
        ) : series.every(val => val === 0) ? (
           <div className="text-gray-400 text-sm">Chưa có dữ liệu món ăn</div>
        ) : (
           <div className="w-full max-w-[350px]">
              <Chart options={options} series={series} type="donut" height={320} />
           </div>
        )}
      </div>
    </div>
  );
}