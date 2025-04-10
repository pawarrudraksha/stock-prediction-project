from flask import Flask, request, jsonify
import pickle
import yfinance as yf
import numpy as np
import os
import requests
from transformers import pipeline
from train_models import train_models  # Import train_models function
from dotenv import load_dotenv  # 🔒 Added for environment variable support

load_dotenv()  # 🔒 Load .env file

app = Flask(__name__)

# Base directory where models are stored
MODEL_DIR = "models/"
os.makedirs(MODEL_DIR, exist_ok=True)  # Ensure the directory exists

def load_model(ticker, model_type):
    """Loads the trained model if it exists."""
    model_path = os.path.join(MODEL_DIR, f"{ticker}_{model_type}.pkl")
    if os.path.exists(model_path):
        with open(model_path, "rb") as f:
            return pickle.load(f)
    return None

def get_stock_price(ticker):
    """Fetches the latest stock price from Yahoo Finance."""
    try:
        stock = yf.Ticker(ticker)
        current_price = stock.history(period="1d")['Close'].iloc[-1]
        return current_price
    except Exception as e:
        print(f"❌ Error fetching stock price for {ticker}: {e}")
        return None

def predict_stock_price(model, current_price):
    """Uses the model to predict the next stock price."""
    input_features = np.array([[current_price, current_price * 0.95]])
    return float(round(model.predict(input_features)[0], 2))

@app.route('/predict', methods=['POST'])
def predict():
    """Handles stock price prediction requests."""
    data = request.get_json()
    ticker = data.get("ticker")
    model_type = data.get("model", "rf")  # Default to Random Forest

    if not ticker:
        return jsonify({"error": "Missing ticker"}), 400

    if model_type not in ["rf", "xgb"]:
        return jsonify({"error": "Invalid model type"}), 400

    # Check if model exists, else train it dynamically
    model = load_model(ticker, model_type)

    if model is None:
        print(f"⚠️ Model for {ticker} not found! Training now...")
    result = train_models(ticker)
    if result == None:
        return jsonify({"error": f"Model training failed for {ticker}"}), 500
    elif result[0] == "fallback":
        fallback_price = result[1]
        return jsonify({
            "ticker": ticker,
            "current_price": fallback_price / 1.01,
            "predicted_price": fallback_price,
            "model_used": "fallback (+1% rule)"
        })


    model = load_model(ticker, model_type)
    if model is None:
        return jsonify({"error": f"Model training failed for {ticker}"}), 500


    # Fetch current stock price
    current_price = get_stock_price(ticker)
    if current_price is None:
        return jsonify({"error": "Unable to fetch stock price"}), 500

    # Predict stock price
    predicted_price = predict_stock_price(model, current_price)

    return jsonify({
        "ticker": ticker,
        "current_price": current_price,
        "predicted_price": predicted_price,
        "model_used": model_type
    })

# Load FinBERT model for sentiment analysis
sentiment_pipeline = pipeline("sentiment-analysis", model="ProsusAI/finbert")

NEWS_API_KEY = os.getenv("NEWS_API_KEY")  # 🔒 Loaded from .env

@app.route('/sentiment', methods=['POST'])
def analyze_sentiment():
    """Handles sentiment analysis requests."""
    data = request.get_json()
    ticker = data.get("ticker")

    if not ticker:
        return jsonify({"error": "Ticker is required"}), 400

    news_url = f"https://newsapi.org/v2/everything?q={ticker}&apiKey={NEWS_API_KEY}"
    response = requests.get(news_url)

    if response.status_code != 200:
        return jsonify({"error": "Failed to fetch news"}), 500

    articles = response.json().get("articles", [])
    if not articles:
        return jsonify({"error": "No news found"}), 404

    sentiment_counts = {"POSITIVE": 0, "NEGATIVE": 0, "NEUTRAL": 0}

    for article in articles[:5]:
        title = article.get("title") or ""
        description = article.get("description") or ""
        text = title + ". " + description

        if text.strip() == ".":
            continue  # skip empty articles

        sentiment_label = sentiment_pipeline(text)[0]["label"].upper()
        if sentiment_label in sentiment_counts:
            sentiment_counts[sentiment_label] += 1

    overall_sentiment = max(sentiment_counts, key=sentiment_counts.get)
    return jsonify({"ticker": ticker, "sentiment": overall_sentiment.capitalize()})


if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=int(os.environ.get("PORT", 8080)))
