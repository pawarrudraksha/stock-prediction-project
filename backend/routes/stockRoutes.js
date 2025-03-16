const express = require("express");
const {
  getStocks,
  addStock,
  updateStock,
  deleteStock,
} = require("../controllers/stockController");

const router = express.Router();

router.get("/", getStocks);
router.post("/add", addStock);
router.put("/update/:id", updateStock);
router.delete("/delete/:id", deleteStock);

module.exports = router;
