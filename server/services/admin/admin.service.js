const Users = require('../../models/User');

const AdminService = {
    //select
    async selectByEmail(email) {
        const query = { email: email};
        const admin = await Users.findOne(query).populate('role').exec();
        return admin;
    },
    async selectById(_id) {
        const admin = await Users.findById(_id).populate('role').exec();
        return admin;
    },

    //update
    async updatePictureById(_id, image) {
        const update = { image: image};
        const config = { new: true, runValidators: true };
        const adminUpdate = await Users.findByIdAndUpdate(_id, update, config).populate('role').exec();
        return adminUpdate;
    },
    async updatePassByEmail(email, newHashedPassword) {
        const filter = { email: email};
        const update = { password: newHashedPassword };
        const config = { new: true, runValidators: true };
        const adminUpdate = await Users.findOneAndUpdate(filter, update, config).populate('role').exec();
        return adminUpdate;
    },
    async updateUserById(_id, user) {
        const config = { new: true, runValidators: true }
        const admin = await Users.findByIdAndUpdate(_id, user, config).populate('role').exec();
        return admin;
    },
    async changeRoleById(_id, newRole) {
        const update = { role: newRole };
        const config = { new: true, runValidators: true };
        const newAdmin = await Users.findByIdAndUpdate(_id, update, config).exec();
        return newAdmin;
    },

    //delete
    async deleteUserById(_id) {
        const deletedUser = await Users.findByIdAndDelete(_id).exec();
        return deletedUser;
    }
};

module.exports = AdminService;