from flask import Flask, request, jsonify
import pickle
import yfinance as yf
import numpy as np
import os
import requests
from transformers import pipeline

app = Flask(__name__)

app = Flask(__name__)

# Base directory where models are stored
MODEL_DIR = "models/"

# Function to load model dynamically
def load_model(ticker, model_type):
    model_path = os.path.join(MODEL_DIR, f"{ticker}_{model_type}.pkl")
    if os.path.exists(model_path):
        with open(model_path, "rb") as f:
            return pickle.load(f)
    return None

# Function to fetch real-time stock price
def get_stock_price(ticker):
    try:
        stock = yf.Ticker(ticker)
        current_price = stock.history(period="1d")['Close'].iloc[-1]
        return current_price
    except Exception as e:
        return None

# Function to predict stock price
def predict_stock_price(model, current_price):
    input_features = np.array([[current_price, current_price * 0.95]])  # Example features
    return round(model.predict(input_features)[0], 2)

# Endpoint to fetch stock price & predict
@app.route('/predict', methods=['POST'])
def predict():
    data = request.get_json()
    ticker = data.get("ticker")
    model_type = data.get("model", "rf")  # Default: Random Forest

    if not ticker:
        return jsonify({"error": "Missing ticker"}), 400

    if model_type not in ["rf", "xgb"]:
        return jsonify({"error": "Invalid model type"}), 400

    # Load model for the requested stock
    model = load_model(ticker, model_type)
    if model is None:
        return jsonify({"error": f"No trained model found for {ticker} with {model_type}"}), 404

    # Get stock price
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

# News API Key

@app.route('/sentiment', methods=['POST'])
def analyze_sentiment():
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


if __name__ == '__main__':
    app.run(debug=True, port=5001)
