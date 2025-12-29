import { useModal } from "../../hooks/useModal";
import { Modal } from "../ui/modal";
import Button from "../ui/button/Button";
import FileInput from "../form/input/FileInput";
import { useEffect, useState } from "react";
import { useAuth } from "../../hooks/AuthProvider";
import axios from "axios";

export default function UserMetaCard() {
  const { isOpen, openModal, closeModal } = useModal();
  const { user, reloadUser } = useAuth();

  const [ image, setImage ] = useState("")

  useEffect(() => {
    if (user) {
      setImage(user.image);
    }
  }, [user, isOpen]);

  const handleSave = async (e) => {
    e.preventDefault();
    
    if (!image) {
      alert('Vui lòng chọn ảnh mới trước khi lưu.');
      return;
    }

    const formData = new FormData();
    formData.append('image', image);// 'image' phải trùng với uploadPicture.single('image'). Không được đặt tên khác
    const token = localStorage.getItem('admin_token') || sessionStorage.getItem('admin_token');

    try {
      const res = await axios.put('/api/admin/upload-avatar', formData, {
        headers: { "x-access-token" : token },
      });

      const result = res.data;

      if (result.success) {
        alert(result.message);
        await reloadUser();
        closeModal();
      } else {
        alert(result.message);
      }
    } catch (err) {
      console.error("Có lỗi trong quá trình Upload", err);
      alert("Có lỗi xảy ra trong quá trình tải ảnh lên! Vui lòng thử lại");
    }
  };

  return (
    <>
      <div className="p-5 border border-gray-200 rounded-2xl dark:border-gray-800 lg:p-6">
        <div className="flex flex-col gap-5 xl:flex-row xl:items-center xl:justify-between">
          <div className="flex flex-col items-center w-full gap-6 xl:flex-row">
            
            {/*TODO: Phân tích kỹ các file xử lý ảnh đại diện này*/}
            <div onClick={openModal} className="group relative w-20 h-20 cursor-pointer">
              <img src={`/${image}`} alt="avatar" className="w-full h-full object-cover overflow-hidde border border-gray-200 dark:border-gray-800 rounded-full" />
              
              <div className="absolute bottom-0 right-0 z-10 flex items-center justify-center w-7 h-7 bg-gray-200 rounded-full border-2 border-white shadow-sm dark:bg-gray-700 dark:border-gray-900 text-gray-600 dark:text-gray-200 transition-transform group-hover:scale-110">
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth="1.5" stroke="currentColor" className="size-4">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M6.827 6.175A2.31 2.31 0 0 1 5.186 7.23c-.38.054-.757.112-1.134.175C2.999 7.58 2.25 8.507 2.25 9.574V18a2.25 2.25 0 0 0 2.25 2.25h15A2.25 2.25 0 0 0 21.75 18V9.574c0-1.067-.75-1.994-1.802-2.169a47.865 47.865 0 0 0-1.134-.175 2.31 2.31 0 0 1-1.64-1.055l-.822-1.316a2.192 2.192 0 0 0-1.736-1.039 48.774 48.774 0 0 0-5.232 0 2.192 2.192 0 0 0-1.736 1.039l-.821 1.316Z" />
                  <path strokeLinecap="round" strokeLinejoin="round" d="M16.5 12.75a4.5 4.5 0 1 1-9 0 4.5 4.5 0 0 1 9 0ZM18.75 10.5h.008v.008h-.008V10.5Z" />
                </svg>
              </div>
            </div>

            <div className="order-3 xl:order-2">
              <h4 className="mb-2 text-lg font-semibold text-center text-gray-800 dark:text-white/90 xl:text-left">
                {user.username}
              </h4>
              <div className="flex flex-col items-center gap-1 text-center xl:flex-row xl:gap-3 xl:text-left">
                <p className="text-sm text-gray-500 dark:text-gray-400">
                  {user._id}
                </p>
                <div className="hidden h-3.5 w-px bg-gray-300 dark:bg-gray-700 xl:block"></div>
                <p className="text-sm text-gray-500 dark:text-gray-400">
                  {user.isAdmin ? "admin" : ""}
                </p>
              </div>
            </div>

            <Modal isOpen={isOpen} onClose={closeModal} className="max-w-[700px] m-4">
              <div className="no-scrollbar relative w-full max-w-[700px] overflow-y-auto rounded-3xl bg-white p-4 dark:bg-gray-900 lg:p-11">
                <div className="px-2 pr-14">
                  <h4 className="mb-2 text-2xl font-semibold text-gray-800 dark:text-white/90">
                    Chỉnh sửa ảnh đại diện
                  </h4>
                  <p className="mb-6 text-sm text-gray-500 dark:text-gray-400 lg:mb-7">
                    Cập nhật ảnh đại diện.
                  </p>
                </div>
                <form className="flex flex-col">
                  <div className="custom-scrollbar h-[100px] overflow-y-auto px-2 pb-3">
                    <div className="mt-5">
                      <div className="grid grid-cols-1 gap-x-6 gap-y-5 lg:grid-cols-2">
                        
                        <div className="col-span-2 lg:col-span-2">
                          <FileInput onChange={(e) => setImage(e.target.files[0])}/>
                        </div>

                      </div>
                    </div>
                  </div>
                  <div className="flex items-center gap-3 px-2 mt-6 lg:justify-end">
                    <Button size="sm" variant="outline" onClick={closeModal}>
                      Đóng
                    </Button>
                    <Button size="sm" onClick={(e) => handleSave(e)}>
                      Lưu
                    </Button>
                  </div>
                </form>
              </div>
            </Modal>
          </div>
        </div>
      </div>
    </>
  );
}
