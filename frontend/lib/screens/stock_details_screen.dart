import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
import 'prediction_screen.dart';

class StockDetailsScreen extends StatefulWidget {
  const StockDetailsScreen({Key? key}) : super(key: key);

  @override
  _StockDetailsScreenState createState() => _StockDetailsScreenState();
}

class _StockDetailsScreenState extends State<StockDetailsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateToPredictionScreen() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const PredictionScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Details'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStockInfo(),
              const SizedBox(height: 20),
              _buildSectionTitle('Key Metrics', Icons.analytics),
              _buildMetricTile('Market Cap', '\$1.2T'),
              _buildMetricTile('P/E Ratio', '25.4'),
              _buildMetricTile('Dividend Yield', '1.8%'),
              const SizedBox(height: 20),
              _buildSectionTitle('Recent Performance', Icons.trending_up),
              _buildPerformanceCard(),
              const SizedBox(height: 20),
              _buildSectionTitle('News & Insights', Icons.article),
              _buildNewsTile(
                'Tesla stock surges 5% after strong earnings report',
                '5h ago',
              ),
              _buildNewsTile(
                'Analysts predict bullish trend for TSLA',
                '1d ago',
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _navigateToPredictionScreen,
                  child: const Text('Predict Stock Price'),
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
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Tesla Inc. (TSLA)',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Current Price: \$755.00',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text('52-Week High: \$900.00   |   52-Week Low: \$550.00'),
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
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Past 7 Days Performance',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Highest: \$780.00  |  Lowest: \$730.00'),
            SizedBox(height: 8),
            Text('Volatility: 4.5%'),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsTile(String headline, String timeAgo) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
      child: ListTile(
        leading: const Icon(Icons.article, color: Colors.blue),
        title: Text(
          headline,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(timeAgo),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
      ),
    );
  }
}
