import PageBreadcrumb from "../../components/common/PageBreadCrumb";
import PageMeta from "../../components/common/PageMeta";
import Tags from "../../components/tables/Tags";


export default function BasicTables() {
  return (
    <>
      <PageMeta
        title="Nguyên liệu"
        description="Trang nguyên liệu"
      />
      <PageBreadcrumb pageTitle="Nguyên liệu" />
      <div className="space-y-6">
        <Tags />
      </div>
    </>
  );
}
