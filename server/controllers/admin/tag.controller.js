const express = require('express');
const TagService = require('../../services/admin/tag.service');
const ActivityLogService = require('../../services/admin/actlog.service');
const AdminService = require('../../services/admin/admin.service');


//lấy toàn bộ dữ liệu, lọc dữ liệu
const getTags = async (req, res) => {
    try {
        const user = await AdminService.selectById(req.decoded._id);
        if (user.role.roleName === 'User') {
            return res.status(403).json({
                success: false, 
                message: "Bạn không có quyền thực hiện hành động này."
            });
        }

        const result = await TagService.selectAll();
        if (!result || result.length === 0) {
            return res.status(200).json({success: false, message: "Không có dữ liệu"});
        }
        return res.status(200).json({success: true, message: "Lấy thành công", tags: result});
    } catch (err) {
        console.error("Lỗi khi truy vấn dữ liện", err)
        return res.status(500).json({success: false, message: "Có lỗi xảy ra trong quá trình truy vấn dữ liệu", error: err.message});
    }  
};

//tạo mới thẻ
const addNewTag = async (req, res) => {
    try{
        const user = await AdminService.selectById(req.decoded._id);
        if (user.role.roleName === 'User') {
            return res.status(403).json({
                success: false, 
                message: "Bạn không có quyền thực hiện hành động này."
            });
        }

        const name = req.body.name;
        const type = req.body.type;

        if (!name || ! type) {
            return res.status(200).json({success: false, message: "Vui lòng nhập đầu đủ tên thẻ và loại thẻ"});
        }

        const newTag = {name: name, type: type};
        const result = await TagService.createTag(newTag);

        ActivityLogService.createLog({
            adminId: req.decoded._id,
            adminName: user.username,
            adminRole: user.role.roleName,
            adminEmail: user.email,
            action: "CREATE",
            targetCollection: 'Tag',
            targetId: result._id,
            targetName: result.name,
            description: `${user.role.roleName} ${user.username} đã tạo thẻ mới ${result.name} có id là ${result._id}`,
            req: req
        });

        return res.status(201).json({ success: true, message: "Thêm thẻ mới thành công", tag: result});
    } catch (err) {
        console.error("Lỗi khi lưu thẻ", err)
        return res.status(500).json({success: false, message: "Có lỗi xảy ra trong quá trình lưu thẻ", error: err.message});
    }
};

//Cập nhật theo id
const updateTagById = async (req, res) => {
    try {
        const user = await AdminService.selectById(req.decoded._id);
        if (user.role.roleName === 'User') {
            return res.status(403).json({
                success: false, 
                message: "Bạn không có quyền thực hiện hành động này."
            });
        }

        const tag_id = req.params.id;
        const tag_name = req.body.name;
        const tag_type = req.body.type;

        const tag = {name: tag_name, type: tag_type};
        const updatedTag = await TagService.updateTagById(tag_id, tag);

        if (!updatedTag) return res.status(404).json({success: false, message: "Thẻ không tồn tại"});

        ActivityLogService.createLog({
            adminId: req.decoded._id,
            adminName: user.username,
            adminRole: user.role.roleName,
            adminEmail: user.email,
            action: "UPDATE",
            targetCollection: 'Tag',
            targetId: updatedTag._id,
            targetName: updatedTag.name,
            description: `${user.role.roleName} ${user.username} đã cập nhật thông tin thẻ ${updatedTag.name} có id là ${updatedTag._id}`,
            req: req
        });

        return res.status(201).json({success: true, message: "Cập nhật dữ liệu thành công", tag: updatedTag});
    } catch (err) {
        console.error("Có lỗi xảy ra trong quá trình cập nhật", err);
        return res.status(500).json({success: false, message: "Có lỗi xảy ra trong quá trình cập nhật thẻ", error: err.message});
    }
};

//Xoá theo id
const deleteTagById = async (req, res) => {
    try{
        const user = await AdminService.selectById(req.decoded._id);
        if (user.role.roleName === 'User') {
            return res.status(403).json({
                success: false, 
                message: "Bạn không có quyền thực hiện hành động này."
            });
        }

        const tag_id = req.params.id;

        const deletedTag = await TagService.deleteTagById(tag_id);
        if(!deletedTag) return res.status(404).json({success: false, message: "Thẻ không tồn tại"});

        ActivityLogService.createLog({
            adminId: req.decoded._id,
            adminName: user.username,
            adminRole: user.role.roleName,
            adminEmail: user.email,
            action: "DELETE",
            targetCollection: 'Tag',
            targetId: deletedTag._id,
            targetName: deletedTag.name,
            description: `${user.role.roleName} ${user.username} đã xoá thông tin thẻ ${deletedTag.name} có id là ${deletedTag._id}`,
            req: req
        });

        return res.status(201).json({success: true, message: "Xoá dữ liệu thành công", tag: deletedTag});
    } catch (err) {
        console.error("Có lỗi xảy ra trong quá trình xoá", err);
        return res.status(500).json({success: false, message: "Có lỗi xảy ra trong quá trình xoá thẻ", error: err.message});
    }
};

module.exports = { getTags, addNewTag, updateTagById, deleteTagById, };