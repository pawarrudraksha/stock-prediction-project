import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';

class DetailsScreen extends StatefulWidget {
  const DetailsScreen({Key? key}) : super(key: key);

  @override
  _DetailsScreenState createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen>
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Portfolio Details'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPortfolioSummary(),
              const SizedBox(height: 20),
              _buildSectionTitle('Investment Overview', Icons.pie_chart),
              _buildMetricTile('Net Investment', '\$50,000'),
              _buildMetricTile('Portfolio Value', '\$75,000'),
              _buildMetricTile('Total Gains/Losses', '+\$25,000'),
              const SizedBox(height: 20),
              _buildSectionTitle('Recent Transactions', Icons.history),
              _buildTransactionTile('Bought Tesla (TSLA)', '-\$2,000'),
              _buildTransactionTile('Sold Apple (AAPL)', '+\$3,500'),
              _buildTransactionTile('Dividends Received', '+\$200'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPortfolioSummary() {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Total Portfolio Value',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '\$75,000',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text('Net Investment: \$50,000 | Gains: +\$25,000'),
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

  Widget _buildTransactionTile(String transaction, String amount) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
      child: ListTile(
        leading: const Icon(Icons.swap_horiz, color: Colors.blue),
        title: Text(
          transaction,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          amount,
          style: TextStyle(
            color: amount.startsWith('+') ? Colors.green : Colors.red,
          ),
        ),
      ),
    );
  }
}
