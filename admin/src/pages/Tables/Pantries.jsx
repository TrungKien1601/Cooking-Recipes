import PageBreadcrumb from "../../components/common/PageBreadCrumb";
import PageMeta from "../../components/common/PageMeta";
import Pantries from "../../components/tables/Pantries";

export default function BasicTables() {
  return (
    <>
      <PageMeta
        title="Tủ lạnh người dùng"
        description="Trang tủ lạnh người dùng"
      />
      <PageBreadcrumb pageTitle="Tủ lạnh người dùng" />
      <div className="space-y-6">
          <Pantries />
      </div>
    </>
  );
}
