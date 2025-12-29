const express = require('express');
const UserProfileService = require('../../services/admin/userprofile.service');
const ActivityLogService = require('../../services/admin/actlog.service')
const AdminService = require('../../services/admin/admin.service')

// Truy vấn dữ liệu
const getAndFilterUser = async (req, res) => {
    try {
        const user = await AdminService.selectById(req.decoded._id);
        if (user.role.roleName === 'User') {
            return res.status(403).json({
                success: false, 
                message: "Bạn không có quyền thực hiện hành động này."
            });
        }

        const resutl = await UserProfileService.selectAll();

        if (!resutl) return res.status(401).json({ success: false, message: "Không có dữ liệu người dùng"});

        return res.status(200).json({ success: true, message: "Lấy dữ liệu thành công", userProfiles: resutl});
    } catch (err) {
        console.error("Lỗi khi truy vấn dữ liệu", err);
        return res.status(500).json({ success: false, message: "Có lỗi ở phía server"});
    }
};

//Cập nhật Role
const changeUserRole = async (req, res) => {
    try {
        const user = await AdminService.selectById(req.decoded._id);
        if (user.role.roleName === 'User') {
            return res.status(403).json({
                success: false, 
                message: "Bạn không có quyền thực hiện hành động này."
            });
        }
        
        const _id = req.params.id;
        const role = req.body.role;

        if (!role || role <= 1 || role >= 4) return res.status(400).json({success: false, message: "Vui lòng nhập lại role"});

        const result = await UserProfileService.changeUserRoleById(_id, role);

        if (!result) return res.status(404).json({success: false, message: "Người dùng không tồn tại"});

        ActivityLogService.createLog({
            adminId: req.decoded._id,
            adminName: user.username,
            adminRole: user.role.roleName,
            adminEmail: user.email,
            action: "UPDATE",
            targetCollection: 'User',
            targetId: result._id,
            targetName: result.user.username,
            description: `${user.role.roleName} ${user.username} đã cập nhật role cho người dùng ${result.name} có id là ${result._id}`,
            req: req
        });

        return res.status(201).json({success: true, message: "Cập nhật role thành công", profile: result});
    } catch (err) {
        console.error("Có lỗi xảy ra trong quá trình cập nhật", err);
        return res.status(500).json({success: false, message: "Có lỗi xảy ra trong quá trình cập nhật role", error: err.message});
    }
};

module.exports = { getAndFilterUser, changeUserRole };