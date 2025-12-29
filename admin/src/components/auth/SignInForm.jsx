import { useEffect, useState } from "react";
import { Link, useNavigate } from "react-router";
import axios from "axios";
import { EyeCloseIcon, EyeIcon } from "../../icons";
import Label from "../form/Label";
import Input from "../form/input/InputField";
import Checkbox from "../form/input/Checkbox";
import Button from "../ui/button/Button";
import { useAuth } from "../../hooks/AuthProvider";

export default function SignInForm() {
  const [showPassword, setShowPassword] = useState(false);
  const [isChecked, setIsChecked] = useState(false);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const { loginAction } = useAuth();
  const navigate = useNavigate();
  
  useEffect(() => {
    const token = localStorage.getItem('admin_token') || sessionStorage.getItem('admin_token');
    if (token) {
      navigate('/admin');
    }
  }, [navigate])

  const apiLogin = async (account) => {
    const res = await axios.post('/api/admin/signin', account);
    const result = res.data;
    if(result.success) {
      await loginAction(result.token, result.user, isChecked);      
    } else {
      alert(result.message);
    }
  };

  const handleLogin = async (e) => {
    e.preventDefault();
    try {
      if (email && password) {
        const account = {email: email, password: password};
        await apiLogin(account);
      } else {
        alert("Vui lòng nhập đầy đủ email và mật khẩu!");
      }
    } catch(error) {
      console.error("Lỗi đăng nhập", error);
      alert("Có lỗi xảy ra từ server");
    }
  }

  return (
    <div className="flex flex-col flex-1">
      <div className="flex flex-col justify-center flex-1 w-full max-w-md mx-auto">
        <div>
          <div className="mb-5 sm:mb-8">
            <h1 className="mb-2 font-semibold text-gray-800 text-title-sm dark:text-white/90 sm:text-title-md">
              Đăng Nhập
            </h1>
            <p className="text-sm text-gray-500 dark:text-gray-400">
              Nhập đầy đủ email và password để truy cập
            </p>
          </div>
          <div>
            <form>
              <div className="space-y-6">
                <div>
                  <Label>
                    Email <span className="text-error-500">*</span>{" "}
                  </Label>
                  <Input placeholder="info@gmail.com" value={email} onChange={(e) => setEmail(e.target.value)}/>
                </div>
                <div>
                  <Label>
                    Mật khẩu <span className="text-error-500">*</span>{" "}
                  </Label>
                  <div className="relative">
                    <Input
                      type={showPassword ? "text" : "password"}
                      placeholder="Enter your password" 
                      onChange={(e) => setPassword(e.target.value)}
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
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <Checkbox id={"remember"} checked={isChecked} onChange={setIsChecked} />
                    <Label htmlFor={"remember"} className="block font-normal text-gray-700 text-theme-sm dark:text-gray-400 pt-2">
                      Ghi nhớ đăng nhập
                    </Label>
                  </div>
                  <Link
                    to="/admin/reset_password"
                    className="text-sm text-brand-500 hover:text-brand-600 dark:text-brand-400"
                  >
                    Quên mật khẩu?
                  </Link>
                </div>
                <div>
                  <Button onClick={(e) => handleLogin(e)} className="w-full" size="sm">
                    Đăng nhập
                  </Button>
                </div>
              </div>
            </form>
          </div>
        </div>
      </div>
    </div>
  );
}
