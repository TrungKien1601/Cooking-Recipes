const express = require('express');
const router = express.Router();
const IngredientController = require('../../controllers/admin/ingredient.controller');

const JwtUtil = require('../../utils/JwtUtils');

router.get('/', JwtUtil.checkToken, IngredientController.getAndFilterIngredients);

router.post('/', JwtUtil.checkToken, IngredientController.createNewIngredient);

router.put('/:id', JwtUtil.checkToken, IngredientController.updateIngredientById);

router.delete('/:id', JwtUtil.checkToken, IngredientController.deleteIngredientById);

module.exports = router;