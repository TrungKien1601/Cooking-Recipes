import PageBreadcrumb from "../../components/common/PageBreadCrumb";
import PageMeta from "../../components/common/PageMeta";
import Recipes from "../../components/tables/Recipes";

export default function BasicTables() {
  return (
    <>
      <PageMeta
        title="Công thức"
        description="Trang công thức"
      />
      <PageBreadcrumb pageTitle="Công thức" />
      <div className="space-y-6">
        <Recipes />
      </div>
    </>
  );
}
