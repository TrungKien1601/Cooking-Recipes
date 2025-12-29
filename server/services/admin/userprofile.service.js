const UserProfile = require('../../models/UserProfile');
const User = require('../../models/User')
const AdminService = require('../../services/admin/admin.service')

const UserProfileService = {
    //Lấy dữ liệu
    async selectAll() {
        const users = await UserProfile.find().populate('user').sort({ updatedAt: -1 }).exec();
        return users;
    },
    async selectProfileById(profileId) {
        const userProfile = await UserProfile.findById(profileId).populate('user').exec();
        return userProfile;
    },

    // Cập nhật
    async changeUserRoleById(profileId, newRole) {
        const profile = await this.selectProfileById(profileId);
        if (!profile) return null;
        await AdminService.changeRoleById(profile.user, newRole);
        return await UserProfile.findById(profileId).populate('user');
    },
}

module.exports = UserProfileService;