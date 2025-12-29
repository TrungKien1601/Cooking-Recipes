import { useState, useEffect } from "react";
import { Link, useNavigate } from "react-router";
import { ChevronLeftIcon, EyeCloseIcon, EyeIcon } from "../../icons";
import Label from "../form/Label";
import Input from "../form/input/InputField";
import Button from "../ui/button/Button";
import axios from "axios";

export default function ResetPassForm() {
  // --- States ---
  const [step, setStep] = useState(1); // 1: Email, 2: OTP, 3: New Password
  const [isLoading, setIsLoading] = useState(false);
  
  // Data States
  const [email, setEmail] = useState("");
  const [otp, setOtp] = useState("");
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");

  // UI States
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const [countdown, setCountdown] = useState(30);

  const navigate = useNavigate();

  // --- Effects ---
  // Đếm ngược cho nút gửi lại OTP ở Step 2
  useEffect(() => {
    let timer;
    if (step === 2 && countdown > 0) {
      timer = setInterval(() => {
        setCountdown((prev) => prev - 1);
      }, 1000);
    }
    return () => clearInterval(timer);
  }, [step, countdown]);

  // --- Handlers ---

  // Xử lý gửi Email (Step 1 -> 2)
  const handleSendOtp = async (e) => {
    e.preventDefault();
    if (!email) return alert("Vui lòng nhập email!");

    // 2. Kiểm tra đuôi @gmail.com
    if (!email.endsWith("@gmail.com")) {
        return alert("Vui lòng nhập đúng định dạng email Google (@gmail.com)!");
    }

    setIsLoading(true);

    try{
      await apiSendOtp({ email });
    } catch (err) {
      console.error("Lỗi gửi OTP: ", err);
      alert(err.response?.data?.message || "Có lỗi xảy ra từ phía Server")
    } finally {
      setIsLoading(false);
    }
  };

  // Xử lý xác thực OTP (Step 2 -> 3)
  const handleVerifyOTP = async (e) => {
    e.preventDefault();
    if (otp.length !== 6) return alert("Mã OTP phải có 6 chữ số!");

    setIsLoading(true);

    try {
      const validOtp = { email: email, otp: otp}
      await apiVerifyOtp(validOtp);
    } catch (err) {
      console.error("Lỗi gửi OTP: ", err);
      alert(err.response?.data?.message || "Có lỗi xảy ra từ phía Server");
    } finally {
      setIsLoading(false);
    }
  };

  // Xử lý đổi mật khẩu (Step 3 -> Finish)
  const handleResetPassword = async (e) => {
    e.preventDefault();
    if (!newPassword || !confirmPassword) return alert("Vui lòng nhập đầy đủ thông tin!");
    if (newPassword !== confirmPassword) return alert("Mật khẩu xác nhận không khớp!");

    setIsLoading(true);

    try {
      const validPassword = { email: email, password: newPassword};
      await apiResetPassword(validPassword);
    } catch (err) {
      console.error("Lỗi gửi OTP: ", err);
      alert(err.response?.data?.message || "Có lỗi xảy ra từ phía Server");
    } finally {
      setIsLoading(false);
    }
  };

  // Quay lại bước trước
  const handleBack = () => {
    if (step === 1) {
      navigate("/admin/signin"); // Về trang login
    } else {
      setStep(step - 1); // Lùi 1 bước
    }
  };


  // --- Render Functions ---
  const apiSendOtp = async (email) => {
    const res = await axios.post('/api/admin/send-otp', email);
    const result = res.data;
    if (result.success) {
      setIsLoading(false);
      setStep(2);
      setCountdown(30);
    } else {
      alert(result.message)
    }
  };

  const apiVerifyOtp = async (validOtp) => {
    const res = await axios.post('/api/admin/verify-otp', validOtp);
    const result = res.data;
    if (result.success) {
      setIsLoading(false);
      setStep(3);
    } else {
      alert(result.message);
    }
  };

  const apiResetPassword = async (validPassword) => {
    const res = await axios.put('/api/admin/reset-password', validPassword);
    const result = res.data;
    if (result.success) {
      setIsLoading(false);
      alert("Đổi mật khẩu thành công! Vui lòng đăng nhập lại.");
      navigate('/admin/signin');
    } else {
      alert(result.message);
    }
  }

  // Tiêu đề và Mô tả thay đổi theo Step
  const renderHeader = () => {
    switch (step) {
      case 1:
        return {
          title: "Quên mật khẩu?",
          desc: "Nhập email của bạn để nhận mã xác nhận đặt lại mật khẩu.",
        };
      case 2:
        return {
          title: "Xác thực OTP",
          desc: `Mã xác nhận 6 số đã được gửi tới ${email}.`,
        };
      case 3:
        return {
          title: "Đặt lại mật khẩu",
          desc: "Tạo mật khẩu mới cho tài khoản của bạn.",
        };
      default:
        return { title: "", desc: "" };
    }
  };

  const headerContent = renderHeader();

  return (
    <div className="flex flex-col flex-1">
      {/* Back Link Wrapper */}
      <div className="w-full max-w-md pt-10 mx-auto">
        <button
          onClick={handleBack}
          type="button"
          className="inline-flex items-center text-sm text-gray-500 transition-colors hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-300"
        >
          <ChevronLeftIcon className="size-5" />
          {step === 1 ? "Trở lại đăng nhập" : "Quay lại"}
        </button>
      </div>

      <div className="flex flex-col justify-center flex-1 w-full max-w-md mx-auto">
        <div>
          {/* Header Section */}
          <div className="mb-5 sm:mb-8">
            <h1 className="mb-2 font-semibold text-gray-800 text-title-sm dark:text-white/90 sm:text-title-md">
              {headerContent.title}
            </h1>
            <p className="text-sm text-gray-500 dark:text-gray-400">
              {headerContent.desc}
            </p>
          </div>

          {/* Form Section */}
          <form>
            <div className="space-y-6">
              
              {/* STEP 1: EMAIL INPUT */}
              {step === 1 && (
                <div>
                  <Label>
                    Email <span className="text-error-500">*</span>
                  </Label>
                  <Input
                    placeholder="info@gmail.com"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    disabled={isLoading}
                    className="border-gray-200 dark:border-gray-800"
                  />
                </div>
              )}

              {/* STEP 2: OTP INPUT */}
              {step === 2 && (
                <div>
                  <Label>
                    Mã OTP <span className="text-error-500">*</span>
                  </Label>
                  <Input
                    type="text"
                    placeholder="______"
                    maxLength={6}
                    value={otp}
                    onChange={(e) => {
                        // Chỉ cho phép nhập số
                        const val = e.target.value;
                        if (!isNaN(val)) setOtp(val);
                    }}
                    className="text-center tracking-[0.5em] text-lg font-bold border-gray-200 dark:border-gray-800" 
                    disabled={isLoading}
                  />
                  <div className="mt-3 text-right">
                    <p className="text-sm text-gray-500 dark:text-gray-400">
                      Chưa nhận được mã?{" "}
                      {countdown > 0 ? (
                        <span className="text-gray-400">Gửi lại sau {countdown}s</span>
                      ) : (
                        <button
                          type="button"
                          onClick={(e) => {
                            handleSendOtp(e)
                            setCountdown(30);
                            alert("Đã gửi lại mã!");
                          }}
                          className="text-brand-500 hover:text-brand-600 dark:text-brand-400 font-medium"
                        >
                          Gửi lại
                        </button>
                      )}
                    </p>
                  </div>
                </div>
              )}

              {/* STEP 3: NEW PASSWORD INPUT */}
              {step === 3 && (
                <>
                  <div>
                    <Label>
                      Mật khẩu mới <span className="text-error-500">*</span>
                    </Label>
                    <div className="relative">
                      <Input
                        type={showPassword ? "text" : "password"}
                        placeholder="Nhập mật khẩu mới"
                        value={newPassword}
                        onChange={(e) => setNewPassword(e.target.value)}
                        disabled={isLoading}
                        className="border-gray-200 dark:border-gray-800"
                      />
                      <span
                        onClick={() => setShowPassword(!showPassword)}
                        className="absolute z-30 -translate-y-1/2 cursor-pointer right-4 top-1/2"
                      >
                        {showPassword ? (
                          <EyeIcon className="fill-gray-500 dark:fill-gray-400 size-5" />
                        ) : (
                          <EyeCloseIcon className="fill-gray-500 dark:fill-gray-400 size-5" />
                        )}
                      </span>
                    </div>
                  </div>

                  <div>
                    <Label>
                      Xác nhận mật khẩu <span className="text-error-500">*</span>
                    </Label>
                    <div className="relative">
                      <Input
                        type={showConfirmPassword ? "text" : "password"}
                        placeholder="Nhập lại mật khẩu"
                        value={confirmPassword}
                        onChange={(e) => setConfirmPassword(e.target.value)}
                        disabled={isLoading}
                        className="border-gray-200 dark:border-gray-800"
                      />
                      <span
                        onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                        className="absolute z-30 -translate-y-1/2 cursor-pointer right-4 top-1/2"
                      >
                        {showConfirmPassword ? (
                          <EyeIcon className="fill-gray-500 dark:fill-gray-400 size-5" />
                        ) : (
                          <EyeCloseIcon className="fill-gray-500 dark:fill-gray-400 size-5" />
                        )}
                      </span>
                    </div>
                  </div>
                </>
              )}

              {/* Action Buttons */}
              <div>
                <Button
                  onClick={(e) => {
                    if (step === 1) handleSendOtp(e);
                    if (step === 2) handleVerifyOTP(e);
                    if (step === 3) handleResetPassword(e);
                  }}
                  className="w-full"
                  disabled={isLoading}
                >
                  {isLoading ? "Đang xử lý..." : (
                    step === 1 ? "Gửi mã xác nhận" :
                    step === 2 ? "Xác nhận" :
                    "Đổi mật khẩu"
                  )}
                </Button>
              </div>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
}