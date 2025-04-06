const yahooFinance = require("yahoo-finance2").default;
const Prediction = require("../models/Prediction");
const Watchlist = require("../models/Watchlist");
const axios = require("axios");

// Predict stock
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
    const query = req.query.query?.trim();
    if (!query)
      return res.status(400).json({ error: "Search query is required" });

    const result = await yahooFinance.search(query);

    if (!result.quotes || !result.quotes.length)
      return res.status(404).json({ error: "No stocks found" });

    const stocks = result.quotes.map((stock) => ({
      ticker: stock.symbol,
      name: stock.shortname || stock.longname || "Unnamed Stock",
      exchange: stock.exchange,
    }));

    return res.json({ stocks });
  } catch (error) {
    console.error("Error fetching stock data:", error);
    res.status(500).json({ error: "Error fetching stock data" });
  }
};

exports.getStockDetails = async (req, res) => {
  try {
    const { ticker } = req.query;
    if (!ticker) return res.status(400).json({ error: "Ticker is required" });

    const result = await yahooFinance.quoteSummary(ticker, {
      modules: ["price", "summaryDetail", "financialData"],
    });

    if (!result) return res.status(404).json({ error: "Stock not found" });

    const stockDetails = {
      ticker: ticker.toUpperCase(),
      name: result.price.longName,
      currentPrice: result.price.regularMarketPrice,
      high52Week: result.summaryDetail.fiftyTwoWeekHigh,
      low52Week: result.summaryDetail.fiftyTwoWeekLow,
      marketCap: result.price.marketCap,
      peRatio: result.summaryDetail.trailingPE,
      dividendYield: result.summaryDetail.dividendYield,
    };

    return res.json({ stockDetails });
  } catch (error) {
    console.error("Error fetching stock details:", error);
    res.status(500).json({ error: "Error fetching stock details" });
  }
};

// Get trending stocks
exports.getTrendingStocks = async (req, res) => {
  try {
    const trendingSymbols = ["AAPL", "TSLA", "VGT"];

    // Fetch each stock separately
    const stockPromises = trendingSymbols.map((symbol) =>
      yahooFinance.quote(symbol)
    );
    const stocksData = await Promise.all(stockPromises);

    const stocks = stocksData.map((stock) => ({
      ticker: stock.symbol,
      name: stock.longName || stock.shortName,
      price: stock.regularMarketPrice,
      change: stock.regularMarketChangePercent.toFixed(2),
    }));

    res.json(stocks);
  } catch (error) {
    console.error("Error fetching trending stocks:", error);
    res.status(500).json({ error: "Failed to fetch trending stocks" });
  }
};

// Get market overview (Nifty 50 & Sensex)
exports.getMarketOverview = async (req, res) => {
  try {
    const indices = ["^NSEI", "^BSESN"];

    // Fetch each index separately
    const indexPromises = indices.map((symbol) => yahooFinance.quote(symbol));
    const marketData = await Promise.all(indexPromises);

    const formattedMarketData = marketData.map((index) => ({
      name: index.shortName,
      price: index.regularMarketPrice,
      change: index.regularMarketChangePercent.toFixed(2),
    }));

    res.json(formattedMarketData);
  } catch (error) {
    console.error("Error fetching market data:", error);
    res.status(500).json({ error: "Failed to fetch market overview" });
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

    const enrichedWatchlist = await Promise.all(
      watchlist.map(async (item) => {
        try {
          const quote = await yahooFinance.quote(item.ticker);
          return {
            _id: item._id,
            ticker: item.ticker,
            stockName: quote.shortName || quote.longName || "N/A",
            addedAt: item.createdAt,
          };
        } catch (err) {
          console.error(
            `Error fetching stock info for ${item.ticker}:`,
            err.message
          );
          return {
            _id: item._id,
            ticker: item.ticker,
            stockName: "Unknown",
            addedAt: item.createdAt,
          };
        }
      })
    );

    res.json(enrichedWatchlist);
  } catch (error) {
    console.error("Error fetching watchlist:", error);
    res.status(500).json({ error: "Error fetching watchlist" });
  }
};

exports.removeFromWatchlist = async (req, res) => {
  try {
    const { stockId } = req.body;
    if (!stockId) {
      return res.status(400).json({ error: "Stock ID is required" });
    }

    const removed = await Watchlist.findOneAndDelete({
      _id: stockId,
      userId: req.user.userId,
    });

    if (!removed) {
      return res.status(404).json({ error: "Stock not found in watchlist" });
    }

    res.json({ message: "Stock removed from watchlist", removed });
  } catch (error) {
    console.error("Error removing from watchlist:", error);
    res.status(500).json({ error: "Error removing from watchlist" });
  }
};

// Get user predictions
exports.getUserPredictions = async (req, res) => {
  try {
    const userId = req.user.userId;
    const predictions = await Prediction.find({ userId }).sort({
      timestamp: -1,
    });

    res.json(predictions);
  } catch (error) {
    console.error("Error fetching predictions:", error);
    res.status(500).json({ error: "Error retrieving predictions" });
  }
};

// Get stock sentiment (ML API)
exports.getStockSentiment = async (req, res) => {
  try {
    const { ticker } = req.query;
    if (!ticker) return res.status(400).json({ error: "Ticker is required" });

    const response = await axios.post("http://localhost:5001/sentiment", {
      ticker,
    });

    res.json(response.data);
  } catch (error) {
    console.error("Error fetching sentiment:", error);
    res.status(500).json({ error: "Sentiment analysis failed" });
  }
};
