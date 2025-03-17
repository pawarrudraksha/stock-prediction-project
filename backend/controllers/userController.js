const axios = require("axios");
const Prediction = require("../models/Prediction");
const Watchlist = require("../models/Watchlist");

exports.predictStock = async (req, res) => {
  const { ticker, model } = req.body;

  if (!ticker || !model) {
    return res.status(400).json({ error: "Ticker and model required" });
  }

  try {
    // Send request to Flask ML API
    const response = await axios.post("http://localhost:5001/predict", {
      ticker,
      model,
    });

    // Save prediction in MongoDB
    const prediction = new Prediction({
      userId: req.user.userId,
      ticker,
      current_price: response.data.current_price,
      predicted_price: response.data.predicted_price,
      model_used: model,
    });

    await prediction.save();
    res.json(prediction);
  } catch (err) {
    res.status(500).json({ error: "Prediction failed" });
  }
};

exports.searchStock = async (req, res) => {
  try {
    const { query } = req.query;
    if (!query)
      return res.status(400).json({ error: "Search query is required" });

    const response = await axios.get(
      `https://query1.finance.yahoo.com/v1/finance/search?q=${query}&quotesCount=5&newsCount=0`
    );

    if (!response.data.quotes.length)
      return res.status(404).json({ error: "No stocks found" });

    const stocks = response.data.quotes.map((stock) => ({
      ticker: stock.symbol,
      name: stock.longname || stock.shortname,
      exchange: stock.exchange,
    }));

    return res.json({ stocks });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Error fetching stock data" });
  }
};

// Add stock to watchlist
exports.addToWatchlist = async (req, res) => {
  try {
    const { ticker } = req.body;
    if (!ticker) return res.status(400).json({ error: "Ticker is required" });

    let watchlistItem = await Watchlist.findOne({
      userId: req.user.userId,
      ticker,
    });

    if (watchlistItem) {
      return res.status(400).json({ error: "Stock already in watchlist" });
    }

    watchlistItem = new Watchlist({ userId: req.user.userId, ticker });
    await watchlistItem.save();

    res.json({ message: "Stock added to watchlist", watchlistItem });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Error adding to watchlist" });
  }
};

// Get user watchlist
exports.getWatchlist = async (req, res) => {
  try {
    const watchlist = await Watchlist.find({ userId: req.user.userId });
    res.json(watchlist);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Error fetching watchlist" });
  }
};

exports.getUserPredictions = async (req, res) => {
  try {
    const userId = req.user.userId; // Extract user ID from the authenticated request

    const predictions = await Prediction.find({ userId }).sort({
      timestamp: -1,
    }); // Get latest predictions first

    res.json(predictions);
  } catch (error) {
    console.error("Error fetching predictions:", error);
    res.status(500).json({ error: "Error retrieving predictions" });
  }
};
