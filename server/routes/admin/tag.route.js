const express = require('express');
const router = express.Router();
const TagController = require('../../controllers/admin/tag.controller')

const JwtUtil = require('../../utils/JwtUtils');

//lấy toàn bộ dữ liệu, lọc dữ liệu
router.get('/', JwtUtil.checkToken, TagController.getTags);

//tạo mới thẻ
router.post('/', JwtUtil.checkToken, TagController.addNewTag);

//Cập nhật theo id
router.put('/:id', JwtUtil.checkToken, TagController.updateTagById);

//Xoá theo id
router.delete('/:id', JwtUtil.checkToken, TagController.deleteTagById);

module.exports = router;