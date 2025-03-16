from flask import Flask, request, jsonify
import numpy as np

app = Flask(__name__)

# Dummy ML function for stock price prediction
def predict_stock_price(current_price):
    return round(current_price * np.random.uniform(1.01, 1.10), 2)  # Small % increase

@app.route('/predict', methods=['POST'])
def predict():
    data = request.get_json()
    current_price = data.get("currentPrice")

    if current_price is None:
        return jsonify({"error": "Missing currentPrice"}), 400

    predicted_price = predict_stock_price(current_price)

    return jsonify({"predictedPrice": predicted_price})

if __name__ == '__main__':
    app.run(debug=True, port=5001)
