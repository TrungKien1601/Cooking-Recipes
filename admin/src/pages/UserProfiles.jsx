import PageBreadcrumb from "../components/common/PageBreadCrumb";
import UserMetaCard from "../components/UserProfile/UserMetaCard";
import UserInfoCard from "../components/UserProfile/UserInfoCard";
// import UserAddressCard from "../components/UserProfile/UserAddressCard";
import PageMeta from "../components/common/PageMeta";

import { useLocation } from "react-router";

export default function UserProfiles() {
  const location = useLocation();

  const profileSettings = location.state?.openSettings;

  return (
    <>
      <PageMeta
        title="Tài khoản người dùng"
        description="Trang tài khoản"
      />
      <PageBreadcrumb pageTitle="Cài đặt tài khoản" />
      <div className="rounded-2xl border border-gray-200 bg-white p-5 dark:border-gray-800 dark:bg-white/[0.03] lg:p-6">
        <h3 className="mb-5 text-lg font-semibold text-gray-800 dark:text-white/90 lg:mb-7">
           Tài khoản
        </h3>
        <div className="space-y-6">
          <UserMetaCard />
          <UserInfoCard />
          {/* <UserAddressCard /> */}
        </div>
      </div>
    </>
  );
}
