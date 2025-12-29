const express = require('express');
const Ingredient = require('../../models/MasterIngredients');

const IngredientService = {
    //select
    async selectAll() {
        const result = await Ingredient.find().populate('tag').sort({ updatedAt: -1 }).exec()
        return result;
    },

    //create
    async createIngredient(newIngre) {
        const result = await Ingredient.create(newIngre);
        return result;
    },

    //update
    async updateIngredientById(_id, ingre) {
        const config = { new: true, runValidators: true };
        const result = await Ingredient.findByIdAndUpdate(_id, ingre, config).populate('tag').exec();
        return result;
    },

    //delete
    async deleteIngredientById(_id) {
        const result = await Ingredient.findByIdAndDelete(_id).populate('tag').exec();
        return result;
    }
}

module.exports = IngredientService;