const Tag = require('../../models/Tag');

const TagService = {
    //Lấy dữ liệu
    async selectAll() {
        const query = {};
        const tags = await Tag.find(query).sort({ updatedAt: -1}).exec();
        return tags;
    },

    //Tạo mới
    async createTag(tag) {
        const newTag = await Tag.create(tag);
        return newTag;
    },

    //Cập nhật
    async updateTagById(_id, tag) {
        const config = { new: true, runValidators: true };
        const updatedTag = await Tag.findByIdAndUpdate(_id, tag, config).exec();
        return updatedTag;
    },

    //Xoá
    async deleteTagById(_id) {
        const deletedTag = await Tag.findByIdAndDelete(_id).exec();
        return deletedTag;
    }
}

module.exports = TagService;