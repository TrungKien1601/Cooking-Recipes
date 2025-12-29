import PageBreadcrumb from "../../components/common/PageBreadCrumb";
import PageMeta from "../../components/common/PageMeta";
import Pantries from "../../components/tables/Pantries";

export default function BasicTables() {
  return (
    <>
      <PageMeta
        title="Tủ đồ ăn"
        description="Trang tủ đồ ăn"
      />
      <PageBreadcrumb pageTitle="Tủ đồ ăn" />
      <div className="space-y-6">
          <Pantries />
      </div>
    </>
  );
}
