const express = require('express');
const router = express.Router();
const ActivityLogController = require('../../controllers/admin/activitylog.controller');

const JwtUtil = require('../../utils/JwtUtils');

router.get('/', JwtUtil.checkToken, ActivityLogController.getActLogs);

module.exports = router;