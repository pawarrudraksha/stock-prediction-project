from flask import Flask, request, jsonify
from flask_cors import CORS  # Optional: Enable this if you're using a frontend
import pickle
import yfinance as yf
import numpy as np
import os
import requests
from transformers import pipeline
from train_models import train_models
from dotenv import load_dotenv
import random
from collections import defaultdict
import pandas as pd
import json

from datetime import datetime, timedelta


load_dotenv()

app = Flask(__name__)
CORS(app)  # Enable cross-origin requests

# Directory for storing trained models
MODEL_DIR = "models/"
os.makedirs(MODEL_DIR, exist_ok=True)
def save_q_table(ticker, q_table):
    model_path = os.path.join(MODEL_DIR, f"{ticker}_qtable.pkl")
    with open(model_path, 'wb') as f:
        pickle.dump(dict(q_table), f)

def load_q_table(ticker):
    model_path = os.path.join(MODEL_DIR, f"{ticker}_qtable.pkl")
    if os.path.exists(model_path):
        with open(model_path, 'rb') as f:
            q_table_data = pickle.load(f)
            return defaultdict(lambda: np.random.uniform(-1, 1, 3), q_table_data)
    return None

# Load FinBERT sentiment model
sentiment_pipeline = pipeline("sentiment-analysis", model="ProsusAI/finbert")

NEWS_API_KEY = os.getenv("NEWS_API_KEY")

def load_model(ticker, model_type):
    model_path = os.path.join(MODEL_DIR, f"{ticker}_{model_type}.pkl")
    if os.path.exists(model_path):
        with open(model_path, "rb") as f:
            return pickle.load(f)
    return None

def get_stock_price(ticker):
    try:
        stock = yf.Ticker(ticker)
        current_price = stock.history(period="1d")['Close'].iloc[-1]
        return current_price
    except Exception as e:
        print(f"❌ Error fetching stock price for {ticker}: {e}")
        return None

def predict_stock_price(model, current_price):
    input_features = np.array([[current_price, current_price * 0.95]])
    return float(round(model.predict(input_features)[0], 2))

@app.route('/predict', methods=['POST'])
def predict():
    data = request.get_json()
    ticker = data.get("ticker")
    model_type = data.get("model", "rf")

    if not ticker:
        return jsonify({"error": "Missing ticker"}), 400
    if model_type not in ["rf", "xgb"]:
        return jsonify({"error": "Invalid model type"}), 400

    model = load_model(ticker, model_type)

    if model is None:
        print(f"⚠️ Model for {ticker} not found! Training now...")
        result = train_models(ticker)
        if result is None:
            return jsonify({"error": f"Model training failed for {ticker}"}), 500
        elif result[0] == "fallback":
            fallback_price = result[1]
            return jsonify({
                "ticker": ticker,
                "current_price": round(fallback_price / 1.01, 2),
                "predicted_price": fallback_price,
                "model_used": "fallback (+1% rule)"
            })
        model = load_model(ticker, model_type)
        if model is None:
            return jsonify({"error": f"Model training failed for {ticker}"}), 500

    current_price = get_stock_price(ticker)
    if current_price is None:
        return jsonify({"error": "Unable to fetch stock price"}), 500

    predicted_price = predict_stock_price(model, current_price)

    return jsonify({
        "ticker": ticker,
        "current_price": current_price,
        "predicted_price": predicted_price,
        "model_used": model_type
    })

@app.route('/sentiment', methods=['POST'])
def analyze_sentiment():
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
            continue

        sentiment_label = sentiment_pipeline(text)[0]["label"].upper()
        if sentiment_label in sentiment_counts:
            sentiment_counts[sentiment_label] += 1

    overall_sentiment = max(sentiment_counts, key=sentiment_counts.get)
    return jsonify({"ticker": ticker, "sentiment": overall_sentiment.capitalize()})

# RL ENDPOINT

class EnhancedTradingEnvironment:
    def __init__(self, data):
        self.data = data
        self.reset()
    
    def reset(self):
        self.current_step = 30  # Start after we have enough data for all indicators
        self.cash = 10000.0
        self.shares = 0.0
        self.portfolio_history = [10000.0]
        self.entry_price = 0.0
        self.returns = []
        self.consecutive_holds = 0
        return self._get_state()
    
    def _get_state(self):
        # Convert all values to native Python types
        try:
            features = {
                'price_ma5_ratio': float(self.data['Close'].iloc[self.current_step] / self.data['MA20'].iloc[self.current_step]),
                'rsi': float(self.data['RSI'].iloc[self.current_step]) / 100,
                'volatility': float(self.data['Volatility'].iloc[self.current_step] * 100),
                'position': 1 if self.shares > 0 else 0,
                'hold_duration': float(min(self.consecutive_holds / 10, 1))
            }
            # Create hashable tuple with rounded values
            return tuple(round(x, 2) for x in features.values())
        except Exception as e:
            print(f"Error creating state: {e}")
            return (0, 0, 0, 0, 0)
    
    def step(self, action):
        try:
            current_price = float(self.data['Close'].iloc[self.current_step])
            reward = 0.0
            done = False
            
            if action == 0:  # Hold
                self.consecutive_holds += 1
                reward -= 0.001 * self.consecutive_holds
            else:
                self.consecutive_holds = 0

            if action == 1 and self.shares == 0:  # Buy
                self.shares = float(self.cash / current_price)
                self.cash = 0.0
                self.entry_price = current_price
                reward -= 0.002
            elif action == 2 and self.shares > 0:  # Sell
                self.cash = float(self.shares * current_price)
                trade_return = float((current_price - self.entry_price) / self.entry_price)
                reward += trade_return * 2
                reward -= 0.002
                self.returns.append(trade_return)
                self.shares = 0.0

            new_value = float(self.cash + (self.shares * current_price))
            self.portfolio_value = new_value
            self.portfolio_history.append(new_value)
            
            if len(self.portfolio_history) > 1:
                reward += float((new_value - self.portfolio_history[-2]) / self.portfolio_history[-2])
            
            self.current_step += 1
            done = self.current_step >= len(self.data) - 1
            
            next_state = self._get_state() if not done else None
            return next_state, reward, done
        except Exception as e:
            print(f"Error in step: {e}")
            return None, 0.0, True

class ImprovedRLAgent:
    def __init__(self, actions):
        self.actions = actions
        self.q_table = defaultdict(lambda: np.random.uniform(-1, 1, len(actions)))  # Random initialization
        self.alpha = 0.3  # Faster learning
        self.gamma = 0.9
        self.epsilon = 0.5  # More exploration
        self.epsilon_min = 0.1
        self.epsilon_decay = 0.98
    
    def choose_action(self, state):
        if np.random.random() < self.epsilon:
            return np.random.choice(self.actions)
        return np.argmax(self.q_table[state])
    
    def learn(self, state, action, reward, next_state):
        current_q = self.q_table[state][action]
        next_max = np.max(self.q_table[next_state]) if next_state is not None else 0
        new_q = current_q + self.alpha * (reward + self.gamma * next_max - current_q)
        self.q_table[state][action] = new_q
        self.epsilon = max(self.epsilon_min, self.epsilon * self.epsilon_decay)

def preprocess_data(data):
    try:
        data['MA5'] = data['Close'].rolling(5).mean().astype(float)
        data['MA20'] = data['Close'].rolling(20).mean().astype(float)
        data['Volatility'] = data['Close'].pct_change().rolling(20).std().astype(float)
        
        delta = data['Close'].diff().astype(float)
        gain = delta.where(delta > 0, 0.0)
        loss = -delta.where(delta < 0, 0.0)
        avg_gain = gain.rolling(14).mean().astype(float)
        avg_loss = loss.rolling(14).mean().astype(float)
        rs = avg_gain / avg_loss
        data['RSI'] = (100 - (100 / (1 + rs))).astype(float)
        
        return data.dropna()
    except Exception as e:
        print(f"Error preprocessing data: {e}")
        return pd.DataFrame()
   
      
@app.route('/simulate', methods=['POST'])
def simulate_trading():
    try:
        ticker = request.json.get('ticker', 'AAPL')
        
        end_date = datetime.now()
        start_date = end_date - timedelta(days=365)
        data = yf.download(ticker, start=start_date, end=end_date)
        
        if data.empty:
            return jsonify({'error': 'No data available for this ticker'}), 400
        
        data = preprocess_data(data)
        if len(data) < 50:
            return jsonify({'error': 'Not enough data points'}), 400
        
        env = EnhancedTradingEnvironment(data)
        agent = ImprovedRLAgent(actions=[0, 1, 2])
        loaded_q = load_q_table(ticker)
        
        if loaded_q:
            agent.q_table = loaded_q
            print(f"✅ Loaded existing Q-table for {ticker}")
        else:
            print(f"🛠️ No saved Q-table for {ticker}. Training now...")
            # Train the agent
            for episode in range(50):
                state = env.reset()
                done = False
                while not done:
                    action = agent.choose_action(state)
                    next_state, reward, done = env.step(action)
                    agent.learn(state, action, reward, next_state)
                    state = next_state
            save_q_table(ticker, agent.q_table)

        # Now simulate using the trained or loaded model
        env.reset()
        done = False
        portfolio_history = []
        actions_taken = []
        daily_log = []
        dates = list(data.index[-(len(data) - 30):])  # match env.start_step

        step = 0
        while not done:
            state = env._get_state()
            action = np.argmax(agent.q_table[state])
            _, _, done = env.step(action)
            
            date = str(dates[step].date()) if step < len(dates) else "N/A"
            current_price = float(data['Close'].iloc[env.current_step - 1]) if env.current_step - 1 < len(data) else 0.0
            
            portfolio_history.append(env.portfolio_value)
            actions_taken.append(int(action))
            
            daily_log.append({
                "date": date,
                "action": {0: "Hold", 1: "Buy", 2: "Sell"}.get(action, "Unknown"),
                "price": round(current_price, 2),
                "portfolio_value": round(env.portfolio_value, 2)
            })
            step += 1

        # Metrics
        returns = np.array(env.returns)
        sharpe = returns.mean() / returns.std() * np.sqrt(252) if len(returns) > 1 else 0.0
        win_rate = float(np.mean(returns > 0)) if len(returns) > 0 else 0.0
        final_value = float(env.portfolio_value)
        total_return = float((final_value - 10000) / 10000)

        response = {
            "ticker": ticker,
            "status": "success",
            "start_date": str(start_date.date()),
            "end_date": str(end_date.date()),
            "episode_count": 0 if loaded_q else 50,

            # 📈 Summary
            "summary": {
                "initial_value": 10000.0,
                "final_value": round(final_value, 2),
                "return": round(total_return * 100, 2),
                "sharpe_ratio": round(sharpe, 2),
                "win_rate": round(win_rate * 100, 2),
                "trade_count": sum(1 for a in actions_taken if a != 0)
            },

            # 📊 Detailed daily log for table or chart
            "daily_log": daily_log
        }


        return jsonify(response)
    
    except Exception as e:
        return jsonify({'error': str(e), 'status': 'error'}), 500



if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=int(os.environ.get("PORT", 8080)))
