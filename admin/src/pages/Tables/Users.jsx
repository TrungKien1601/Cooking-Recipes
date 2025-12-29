import PageBreadcrumb from "../../components/common/PageBreadCrumb";
import PageMeta from "../../components/common/PageMeta";
import Users from "../../components/tables/Users";
import { BoxIconLine } from "../../icons";

export default function BasicTables() {
  return (
    <>
      <PageMeta
        title="Người dùng"
        description="Trang người dùng"
      />
      <PageBreadcrumb pageTitle="Người dùng" />
      <div className="space-y-6">
          <Users />
      </div>
    </>
  );
}
