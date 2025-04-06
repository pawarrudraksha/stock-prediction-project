const express = require("express");
const {
  signup,
  login,
  getUserProfile,
} = require("../controllers/authController");
const router = express.Router();

const auth = require("../middleware/authMiddleware");

router.post("/signup", signup);
router.post("/login", login);
router.get("/profile", auth, getUserProfile);

module.exports = router;
