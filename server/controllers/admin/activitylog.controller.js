const express = require('express');
const ActivityLogService = require('../../services/admin/actlog.service');
const AdminService = require('../../services/admin/admin.service');

const getActLogs = async (req, res) => {
    try {
        const user = await AdminService.selectById(req.decoded._id);
        if (user.role.roleName === 'User') {
            return res.status(403).json({
                success: false, 
                message: "Bạn không có quyền thực hiện hành động này."
            });
        }
        
        let result;
        result = await ActivityLogService.selectAll();
        if (!result || result.length === 0) {
            return res.status(201).json({success: false, message: "Không có dữ liệu"});
        }
        return res.status(201).json({success: true, message: "Lấy thành công", actlogs: result});
    } catch (err) {
        console.error("Lỗi khi truy vấn dữ liện", err)
        return res.status(500).json({success: false, message: "Có lỗi xảy ra trong quá trình truy vấn dữ liệu", error: err.message});
    }
};

module.exports = { getActLogs};