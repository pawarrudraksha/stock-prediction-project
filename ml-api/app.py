from flask import Flask, request, jsonify
import pickle
import yfinance as yf
import numpy as np
import os

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

if __name__ == '__main__':
    app.run(debug=True, port=5001)
