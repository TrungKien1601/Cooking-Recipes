import EcommerceMetrics from "../../components/dashboardwidgets/Statistical";
import StatisticsChart from "../../components/dashboardwidgets/StatisticsChart";
import IngreTable from "../../components/dashboardwidgets/IngreTable";
import RecipeTable from "../../components/dashboardwidgets/RecipeTable";
import PageMeta from "../../components/common/PageMeta";

export default function Home() {
  return (
    <>
      <PageMeta
        title="Tổng quan"
        description="Trang tổng quan thông tin"
      />
      <div className="grid grid-cols-12 gap-4 md:gap-6">
        <div className="col-span-12">
          <EcommerceMetrics />
        </div>

        <div className="col-span-12">
          <StatisticsChart />
        </div>

        <div className="col-span-12 xl:col-span-6">
          <IngreTable />
        </div>

        <div className="col-span-12 xl:col-span-6">
          <RecipeTable />
        </div>
      </div>
    </>
  );
}
