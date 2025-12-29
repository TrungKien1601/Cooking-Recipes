const express = require('express');
const router = express.Router();
const UserProfileController = require('../../controllers/admin/userprofile.controller')

const JwtUtil = require('../../utils/JwtUtils');

router.get('/', JwtUtil.checkToken, UserProfileController.getAndFilterUser);

router.put('/change-role/:id', JwtUtil.checkToken, UserProfileController.changeUserRole)

module.exports = router;