import Statiscal from "../../components/dashboardwidgets/Statistical";
import StatisticsChart from "../../components/dashboardwidgets/StatisticsChart";
import PendingRecipes from "../../components/dashboardwidgets/PendingRecipes";
import RecipeDifficultyChart from "../../components/dashboardwidgets/RecipeDifficultyChart";
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
          <Statiscal />
        </div>

        <div className="col-span-12">
          <StatisticsChart />
        </div>

        <div className="col-span-12 xl:col-span-6">
          <PendingRecipes />
        </div>

        <div className="col-span-12 xl:col-span-6">
          <RecipeDifficultyChart/>
        </div>
      </div>
    </>
  );
}
