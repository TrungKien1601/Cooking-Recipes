import PageMeta from "../../components/common/PageMeta";
import AuthLayout from "./AuthPageLayout";
import ResetPassForm from "../../components/auth/ResetPassForm";

export default function SignIn() {
  return (
    <>
      <PageMeta
        title="Đổi mật khẩu"
        description="Trang thay đổi mật khẩu"
      />
      <AuthLayout>
        <ResetPassForm />
      </AuthLayout>
    </>
  );
}