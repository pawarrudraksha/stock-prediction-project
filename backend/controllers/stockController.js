const Stock = require("../models/Stock");

const axios = require("axios");

const predictStockPrice = async (req, res) => {
  try {
    const { currentPrice } = req.body;

    if (!currentPrice) {
      return res.status(400).json({ error: "currentPrice is required" });
    }

    // Call ML API
    const response = await axios.post("http://localhost:5001/predict", {
      currentPrice,
    });

    return res.json({
      originalPrice: currentPrice,
      predictedPrice: response.data.predictedPrice,
    });
  } catch (error) {
    console.error(error);
    return res.status(500).json({ error: "Error in ML prediction" });
  }
};

module.exports = { predictStockPrice };

// @desc Get all stocks
const getStocks = async (req, res) => {
  try {
    const stocks = await Stock.find();
    res.json(stocks);
  } catch (error) {
    res.status(500).json({ message: "Server Error" });
  }
};

// @desc Add a stock
const addStock = async (req, res) => {
  const { symbol, name, currentPrice } = req.body;
  try {
    const newStock = new Stock({ symbol, name, currentPrice });
    await newStock.save();
    res.status(201).json(newStock);
  } catch (error) {
    res.status(500).json({ message: "Server Error" });
  }
};

// @desc Update stock price
const updateStock = async (req, res) => {
  const { id } = req.params;
  const { currentPrice, predictedPrice } = req.body;
  try {
    const stock = await Stock.findByIdAndUpdate(
      id,
      { currentPrice, predictedPrice },
      { new: true }
    );
    res.json(stock);
  } catch (error) {
    res.status(500).json({ message: "Server Error" });
  }
};

// @desc Delete a stock
const deleteStock = async (req, res) => {
  const { id } = req.params;
  try {
    await Stock.findByIdAndDelete(id);
    res.json({ message: "Stock deleted" });
  } catch (error) {
    res.status(500).json({ message: "Server Error" });
  }
};

module.exports = {
  getStocks,
  addStock,
  updateStock,
  deleteStock,
  predictStockPrice,
};
