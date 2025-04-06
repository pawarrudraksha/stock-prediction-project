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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          stockData != null
              ? '${stockData!['name']} (${widget.ticker})'
              : 'Stock Details',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade700,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_add),
            onPressed: _addToWatchlist,
          ),
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStockInfo(),
                      const SizedBox(height: 20),
                      _buildSectionTitle('Key Metrics', Icons.analytics),
                      _buildMetricTile(
                        'Market Cap',
                        stockData?["marketCap"].toString() ?? 'N/A',
                      ),
                      _buildMetricTile(
                        'P/E Ratio',
                        stockData?["peRatio"].toString() ?? 'N/A',
                      ),
                      _buildMetricTile(
                        'Dividend Yield',
                        stockData?["dividendYield"].toString() ?? 'N/A',
                      ),
                      const SizedBox(height: 20),
                      _buildSectionTitle(
                        'Recent Performance',
                        Icons.trending_up,
                      ),
                      _buildPerformanceCard(),
                      const SizedBox(height: 20),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: _navigateToPredictionScreen,
                          icon: const Icon(
                            Icons.trending_up,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Predict Stock Price',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
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
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              stockData?["name"] ?? 'Unknown Stock',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Current Price: \$${stockData?["currentPrice"] ?? 'N/A'}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildMetricTile(String title, String value) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
      child: ListTile(
        leading: const Icon(Icons.bar_chart, color: Colors.blue),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(value),
      ),
    );
  }

  Widget _buildPerformanceCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Past 7 Days Performance',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Highest: \$${stockData?["high52Week"] ?? 'N/A'}  |  Lowest: \$${stockData?["low52Week"] ?? 'N/A'}',
            ),
            const SizedBox(height: 8),
            Text('Volatility: ${stockData?["volatility"] ?? 'N/A'}%'),
          ],
        ),
      ),
    );
  }
}
