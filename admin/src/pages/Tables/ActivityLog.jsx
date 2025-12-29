import PageBreadcrumb from "../../components/common/PageBreadCrumb";
import PageMeta from "../../components/common/PageMeta";
import ActivityLogs from "../../components/tables/ActivityLog";


export default function BasicTables() {
  return (
    <>
      <PageMeta
        title="Hoạt động hệ thống"
        description="Trang hoạt động hệ thống"
      />
      <PageBreadcrumb pageTitle="Hoạt động hệ thống" />
      <div className="space-y-6">
        <ActivityLogs />
      </div>
    </>
  );
}
