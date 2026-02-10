# AI-Powered Stock Prediction & Trading Simulator

## Overview

This project is a full-stack stock analysis and trading simulation platform that integrates machine learning, natural language processing, and reinforcement learning to help users analyze markets, predict stock prices, and evaluate trading strategies.

The system is built using a microservices-style architecture:

**Flutter Web Frontend → Node.js Backend (Auth & User Data) → Flask ML API (Prediction, Sentiment, RL Simulation)**

### *Users can:*

-Predict future stock prices

-Analyze market sentiment from financial news

-Simulate trading strategies using reinforcement learning

-Track portfolio performance metrics

-Authenticate and manage watchlists

## Features

### *Price Prediction API*

-Supports Random Forest and XGBoost models

-Automatically trains models if none exist for a ticker

-Includes fallback logic if training fails

-Fetches real-time stock prices from Yahoo Finance

### *Sentiment Analysis*

-Retrieves recent financial news using NewsAPI

-Processes headlines through FinBERT

-Produces an aggregated market sentiment score for a stock

### *Reinforcement Learning Trading Simulator*

-Implements a Q-Learning agent

-Uses a custom trading environment

-Incorporates technical indicators such as:

-Relative Strength Index (RSI)

-Moving Averages

-Volatility

-Saves trained strategies per stock ticker

-Computes performance metrics including:

-Sharpe Ratio

-Win Rate

-Portfolio Return

### *Node.js Backend*

Responsible for:

-User authentication and authorization

-MongoDB storage

-Watchlists and tracked stocks

-Portfolio management

-API gateway between frontend and ML services

### *Flutter Web Frontend*

-Communicates with Node.js and Flask APIs

-Serves the web build through index.html

-Provides interactive dashboards and charts

-Includes authentication screens

-Displays portfolio and trading metrics

## Tech Stack

### *Machine Learning Backend*

-Flask

-Scikit-Learn

-XGBoost

-Transformers (FinBERT)

-PyTorch

-Yahoo Finance API

-Stable-Baselines3

### *Backend API / Authentication Server*

-Node.js

-Express

-MongoDB

-Mongoose

### *Frontend*

-Flutter Web
