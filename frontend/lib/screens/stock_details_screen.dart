import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
import 'prediction_screen.dart';
import 'package:frontend/functions/api_services.dart';
import 'package:frontend/functions/user_services.dart';

class StockDetailsScreen extends StatefulWidget {
  final String ticker;

  const StockDetailsScreen({Key? key, required this.ticker}) : super(key: key);

  @override
  _StockDetailsScreenState createState() => _StockDetailsScreenState();
}

class _StockDetailsScreenState extends State<StockDetailsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  Map<String, dynamic>? stockData;
  bool isLoading = true;
  Map<String, dynamic>? sentimentData;
  bool isSentimentLoading = true;
  bool isSentimentError = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);
    _controller.forward();
    _fetchStockDetails();
    _fetchSentiment();
  }

  Future<void> _fetchStockDetails() async {
    final data = await ApiService.getStockDetails(widget.ticker);
    if (mounted) {
      setState(() {
        stockData = data?['stockDetails'] ?? {};
        isLoading = false;
      });
    }
  }

  Future<void> _fetchSentiment() async {
    try {
      final data = await ApiService.getSentiment(widget.ticker);
      if (mounted) {
        setState(() {
          sentimentData = {"sentiment": data?["sentiment"] ?? "Unknown"};
          isSentimentLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isSentimentError = true;
          isSentimentLoading = false;
        });
      }
    }
  }

  Future<void> _addToWatchlist() async {
    try {
      await UserServices.addToWatchlist(widget.ticker);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Stock added to watchlist')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Stock already added to watchlist')),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateToPredictionScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PredictionScreen(ticker: widget.ticker),
      ),
    );
  }

  String formatLargeNumber(dynamic number) {
    if (number == null) return 'N/A';
    double value = double.tryParse(number.toString()) ?? 0;

    if (value >= 1e12) return '${(value / 1e12).toStringAsFixed(2)}T';
    if (value >= 1e9) return '${(value / 1e9).toStringAsFixed(2)}B';
    if (value >= 1e6) return '${(value / 1e6).toStringAsFixed(2)}M';
    if (value >= 1e3) return '${(value / 1e3).toStringAsFixed(2)}K';
    return value.toStringAsFixed(2);
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          stockData != null
              ? '${stockData!['name']} (${widget.ticker})'
              : 'Stock Details',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        backgroundColor: Colors.indigo.shade700,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_add),
            onPressed: _addToWatchlist,
          ),
        ],
      ),
      body:
          isSentimentLoading
              ? const Center(
                child: CircularProgressIndicator(),
              ) // Show loading until sentiment is fetched
              : FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStockInfo(),
                      const SizedBox(height: 12),
                      _buildSentimentCard(),
                      const SizedBox(height: 24),
                      _buildSectionTitle('📊 Key Metrics'),
                      _buildMetricTile(
                        'Market Cap',
                        formatLargeNumber(stockData?['marketCap']),
                      ),
                      _buildMetricTile(
                        'P/E Ratio',
                        stockData?['peRatio']?.toString() ?? 'N/A',
                      ),
                      _buildMetricTile(
                        'Dividend Yield',
                        '${stockData?['dividendYield']?.toStringAsFixed(2) ?? 'N/A'}%',
                      ),
                      const SizedBox(height: 24),
                      _buildSectionTitle('📈 Recent Performance'),
                      _buildPerformanceCard(),
                      const SizedBox(height: 30),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: _navigateToPredictionScreen,
                          icon: const Icon(
                            Icons.trending_up,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Predict Stock Price',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo.shade700,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(32),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildStockInfo() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stockData?['name'] ?? 'Unknown Stock',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '(${widget.ticker})',
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'Current Price',
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                Text(
                  '\$${stockData?['currentPrice'] ?? 'N/A'}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSentimentCard() {
    if (isSentimentLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (isSentimentError || sentimentData == null) {
      return const Text(
        "❌ Sentiment data unavailable",
        style: TextStyle(fontSize: 16, color: Colors.redAccent),
      );
    } else {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: ListTile(
          leading: const Icon(Icons.sentiment_satisfied, color: Colors.indigo),
          title: const Text(
            "Market Sentiment",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            sentimentData?['sentiment'] ?? "N/A",
            style: const TextStyle(fontSize: 16),
          ),
        ),
      );
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildMetricTile(String title, String value) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: ListTile(
        leading: const Icon(Icons.bar_chart_rounded, color: Colors.indigo),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Text(value, style: const TextStyle(fontSize: 14)),
      ),
    );
  }

  Widget _buildPerformanceCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Past 52 Days Performance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RichText(
                  text: TextSpan(
                    text: 'Highest: ',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                    children: [
                      TextSpan(
                        text: '\$${stockData?['high52Week'] ?? 'N/A'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.normal,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                RichText(
                  text: TextSpan(
                    text: 'Lowest: ',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                    children: [
                      TextSpan(
                        text: '\$${stockData?['low52Week'] ?? 'N/A'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.normal,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
