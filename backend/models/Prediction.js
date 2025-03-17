const mongoose = require("mongoose");

const PredictionSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
  ticker: { type: String, required: true },
  current_price: { type: Number, required: true },
  predicted_price: { type: Number, required: true },
  model_used: { type: String, required: true },
  timestamp: { type: Date, default: Date.now },
});

module.exports = mongoose.model("Prediction", PredictionSchema);
