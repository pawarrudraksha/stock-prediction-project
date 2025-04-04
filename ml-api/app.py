from flask import Flask, request, jsonify
import pickle
import yfinance as yf
import numpy as np
import os
import requests
from transformers import pipeline
from train_models import train_models  # Import train_models function

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
        train_models(ticker)  # Train and save models
        model = load_model(ticker, model_type)  # Reload model after training
        if model is None:
            return jsonify({"error": f"Failed to train model for {ticker}"}), 500

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

NEWS_API_KEY = "2c4a6d975eb1457388c5d1c3e5f6051f"

@app.route('/sentiment', methods=['POST'])
def analyze_sentiment():
    """Handles sentiment analysis requests."""
    data = request.get_json()
    ticker = data.get("ticker")

    if not ticker:
        return jsonify({"error": "Ticker is required"}), 400

    # Fetch news articles
    news_url = f"https://newsapi.org/v2/everything?q={ticker}&apiKey={NEWS_API_KEY}"
    response = requests.get(news_url)

    if response.status_code != 200:
        return jsonify({"error": "Failed to fetch news"}), 500

    articles = response.json().get("articles", [])
    if not articles:
        return jsonify({"error": "No news found"}), 404

    sentiments = []
    for article in articles[:5]:  # Analyze first 5 articles
        text = article["title"] + ". " + article.get("description", "")
        sentiment = sentiment_pipeline(text)[0]
        sentiments.append({"text": text, "sentiment": sentiment["label"], "score": sentiment["score"]})

    return jsonify({"ticker": ticker, "sentiments": sentiments})

if __name__ == '__main__':
    app.run(debug=True, port=5001)
