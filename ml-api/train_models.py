import yfinance as yf
import pandas as pd
import numpy as np
import pickle
import os
from sklearn.ensemble import RandomForestRegressor
import xgboost as xgb
from sklearn.model_selection import train_test_split

# Base directory to save trained models
MODEL_DIR = "models/"
os.makedirs(MODEL_DIR, exist_ok=True)  # Create directory if it doesn't exist

# Function to fetch stock data
def fetch_stock_data(ticker):
    stock = yf.Ticker(ticker)
    df = stock.history(period="1y")  # 1 year of data
    if df.empty:
        print(f"No data found for {ticker}. Please check the ticker symbol.")
        return None
    df['Returns'] = df['Close'].pct_change()
    df.dropna(inplace=True)
    return df

# Train models dynamically or fallback
def train_models(ticker):
    df = fetch_stock_data(ticker)
    if df is None or len(df) < 10:
        print(f"📉 Not enough data to train model for {ticker}. Using fallback strategy.")
        try:
            fallback_price = yf.Ticker(ticker).history(period="1d")['Close'].iloc[-1] * 1.01  # +1% estimate
            return "fallback", round(fallback_price, 2)
        except Exception as e:
            print(f"❌ Fallback price fetch failed for {ticker}: {e}")
            return None

    # Features & Labels
    X = df[['Close', 'Volume']].values
    y = df['Close'].shift(-1).dropna().values
    X = X[:-1]  # Align X with y

    if len(X) < 2:
        print(f"❌ Not enough data to train model for {ticker}. Required at least 2 rows, got {len(X)}.")
        return None

    # Split dataset
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42
    )

    # Train Random Forest
    rf_model = RandomForestRegressor(n_estimators=100, random_state=42)
    rf_model.fit(X_train, y_train)

    # Train XGBoost
    xgb_model = xgb.XGBRegressor(objective="reg:squarederror", n_estimators=100)
    xgb_model.fit(X_train, y_train)

    # Save models
    rf_path = os.path.join(MODEL_DIR, f"{ticker}_rf.pkl")
    xgb_path = os.path.join(MODEL_DIR, f"{ticker}_xgb.pkl")

    with open(rf_path, "wb") as f:
        pickle.dump(rf_model, f)
    with open(xgb_path, "wb") as f:
        pickle.dump(xgb_model, f)

    print(f"✅ Models trained and saved for {ticker}!")
    return "success", None

if __name__ == "__main__":
    user_ticker = input("Enter the stock ticker: ").upper()
    train_models(user_ticker)
