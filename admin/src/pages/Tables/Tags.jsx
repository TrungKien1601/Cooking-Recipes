import PageBreadcrumb from "../../components/common/PageBreadCrumb";
import PageMeta from "../../components/common/PageMeta";
import Tags from "../../components/tables/Tags";


export default function BasicTables() {
  return (
    <>
      <PageMeta
        title="Thẻ"
        description="Trang quản lý thẻ"
      />
      <PageBreadcrumb pageTitle="Thẻ" />
      <div className="space-y-6">
        <Tags />
      </div>
    </>
  );
}
