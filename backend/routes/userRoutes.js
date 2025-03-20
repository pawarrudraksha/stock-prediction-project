const express = require("express");
const router = express.Router();
const userController = require("../controllers/userController");
const auth = require("../middleware/authMiddleware");

// Stock search and prediction routes
router.get("/search", userController.searchStock);
router.post("/predict", auth, userController.predictStock);

// Watchlist routes
router.post("/watchlist/add", auth, userController.addToWatchlist);
router.get("/watchlist", auth, userController.getWatchlist);
router.get("/sentiment", auth, userController.getStockSentiment);

// User prediction history
router.get("/predictions", auth, userController.getUserPredictions);

module.exports = router;
