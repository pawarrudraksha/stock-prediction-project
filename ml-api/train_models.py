import yfinance as yf
import pandas as pd
import numpy as np
import pickle
from sklearn.ensemble import RandomForestRegressor
import xgboost as xgb
from sklearn.model_selection import train_test_split

# Function to fetch stock data
def fetch_stock_data(ticker):
    stock = yf.Ticker(ticker)
    df = stock.history(period="1y")  # 1 year of data
    df['Returns'] = df['Close'].pct_change()
    df.dropna(inplace=True)
    return df

# Train models
def train_models(ticker):
    df = fetch_stock_data(ticker)

    # Features & Labels
    X = df[['Close', 'Volume']].values  # Features: Close Price & Volume
    y = df['Close'].shift(-1).dropna().values  # Predict next day's Close price
    X = X[:-1]  # Align X with y

    # Split dataset
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

    # Train Random Forest
    rf_model = RandomForestRegressor(n_estimators=100, random_state=42)
    rf_model.fit(X_train, y_train)

    # Train XGBoost
    xgb_model = xgb.XGBRegressor(objective="reg:squarederror", n_estimators=100)
    xgb_model.fit(X_train, y_train)

    # Save models
    with open(f"AAPL_rf.pkl", "wb") as f:
        pickle.dump(rf_model, f)
    with open(f"AAPL_xgb.pkl", "wb") as f:
        pickle.dump(xgb_model, f)

    print(" Models trained and saved!")

if __name__ == "__main__":
    train_models("AAPL")  # Train on Apple stock
