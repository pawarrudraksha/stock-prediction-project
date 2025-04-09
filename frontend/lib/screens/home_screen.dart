import 'package:flutter/material.dart';
import 'package:frontend/functions/api_services.dart';
import 'stock_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  List<dynamic> trendingStocks = [];
  List<dynamic> marketOverview = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);
    _controller.forward();
    _fetchTrendingStocks();
    _fetchMarketOverview();
  }

  Future<void> _fetchTrendingStocks() async {
    final stocks = await ApiService.getTrendingStocks();
    if (mounted) {
      setState(() {
        trendingStocks = stocks;
      });
    }
  }

  Future<void> _fetchMarketOverview() async {
    final overview = await ApiService.getMarketOverview();
    if (mounted) {
      setState(() {
        marketOverview = overview;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateToStockDetails(BuildContext context, String ticker) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StockDetailsScreen(ticker: ticker),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '📈 StockGPT',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        backgroundColor: Colors.indigo.shade700,
        elevation: 4,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome to StockGPT! ',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📊 Market Overview',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      marketOverview.isEmpty
                          ? const Center(child: CircularProgressIndicator())
                          : Column(
                            children:
                                marketOverview.map((index) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          index["change"] >= 0
                                              ? Icons.trending_up
                                              : Icons.trending_down,
                                          color:
                                              index["change"] >= 0
                                                  ? Colors.green
                                                  : Colors.red,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '${index["name"]}: ${index["price"]}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          index["change"] >= 0
                                              ? "▲ ${index["change"]}%"
                                              : "▼ ${index["change"]}%",
                                          style: TextStyle(
                                            fontSize: 14,
                                            color:
                                                index["change"] >= 0
                                                    ? Colors.green
                                                    : Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                          ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '🔥 Trending Stocks',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Expanded(
                child:
                    trendingStocks.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.builder(
                          itemCount: trendingStocks.length,
                          itemBuilder: (context, index) {
                            final stock = trendingStocks[index];
                            return GestureDetector(
                              onTap:
                                  () => _navigateToStockDetails(
                                    context,
                                    stock["ticker"],
                                  ),
                              child: Card(
                                elevation: 4,
                                margin: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 4,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 16,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        stock["change"] >= 0
                                            ? Icons.trending_up
                                            : Icons.trending_down,
                                        color:
                                            stock["change"] >= 0
                                                ? Colors.green
                                                : Colors.red,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          stock["name"],
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        stock["change"] >= 0
                                            ? "▲ ${stock["change"].toStringAsFixed(2)}%"
                                            : "▼ ${stock["change"].toStringAsFixed(2)}%",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              stock["change"] >= 0
                                                  ? Colors.green
                                                  : Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
