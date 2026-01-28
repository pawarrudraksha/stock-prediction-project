**📈 AI-Powered Stock Prediction & Trading Simulator**

This project is a full-stack stock analysis platform that combines:

🔮 Machine Learning price prediction (Random Forest & XGBoost)

📰 Financial news sentiment analysis using FinBERT

🤖 Reinforcement Learning trading simulator

🌐 Flask ML API

🔐 Node.js + MongoDB auth server

📱 Flutter web frontend

*It allows users to:*

Predict stock prices

Analyze market sentiment

Simulate trading strategies

Track performance metrics

Authenticate users and manage portfolios

Frontend (Flutter Web)
        |
        v
Node.js Server (Auth + User Data)
        |
        v
Flask ML API (Prediction, Sentiment, RL Simulation)

**🚀 Features**
*🔮 Price Prediction API*

Uses Random Forest or XGBoost

Automatically trains models if missing

Fallback rule if training fails

Real-time prices fetched from Yahoo Finance

*📰 Sentiment Analysis*

Fetches latest news using NewsAPI

Runs headlines through FinBERT

Returns overall market sentiment

*🤖 Reinforcement Learning Trading Simulator*

Q-Learning agent

Custom trading environment

Technical indicators:

RSI

Moving Averages

Volatility

Saves learned strategies per ticker

Computes:

Sharpe Ratio

Win Rate

Portfolio Return

*🔐 Node.js Backend*

Handles:

User authentication

MongoDB storage

Watchlists & stock data

Portfolio tracking

*📱 Flutter Web Frontend*

Calls Node + Flask APIs

Web-build served using index.html

Interactive dashboards & charts

Authentication UI

**🛡️ Tech Stack**
*Backend (ML)*

Flask

Scikit-Learn

XGBoost

Transformers (FinBERT)

PyTorch

Yahoo Finance

Stable-Baselines3

*Backend (API/Auth)*

Node.js

Express

MongoDB

Mongoose

*Frontend*

Flutter Web
