const mongoose = require("mongoose");

const stockSchema = new mongoose.Schema(
  {
    symbol: { type: String, required: true },
    name: { type: String, required: true },
    currentPrice: { type: Number, required: true },
    predictedPrice: { type: Number, default: null }, // Placeholder for ML prediction
  },
  { timestamps: true }
);

module.exports = mongoose.model("Stock", stockSchema);
