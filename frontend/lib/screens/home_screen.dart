import 'package:flutter/material.dart';
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

  void _navigateToStockDetails(
    BuildContext context,
    String stockName,
    double stockPrice,
    double stockChange,
  ) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => StockDetailsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Predictor'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueAccent, Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome to Stock Predictor!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Market Overview:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: const [
                          Icon(Icons.show_chart, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            'Nifty 50: 19,800 ▲ 1.5%',
                            style: TextStyle(fontSize: 16, color: Colors.green),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: const [
                          Icon(Icons.bar_chart, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            'Sensex: 66,000 ▲ 1.2%',
                            style: TextStyle(fontSize: 16, color: Colors.green),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Trending Stocks:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.white, Colors.blue.shade100],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        blurRadius: 5,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ListView(
                    children: [
                      GestureDetector(
                        onTap:
                            () => _navigateToStockDetails(
                              context,
                              'Reliance Industries',
                              2480.50,
                              2.3,
                            ),
                        child: const Card(
                          elevation: 3,
                          margin: EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 5,
                          ),
                          child: ListTile(
                            leading: Icon(
                              Icons.trending_up,
                              color: Colors.green,
                            ),
                            title: Text('Reliance Industries'),
                            subtitle: Text('▲ 2.3%'),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap:
                            () => _navigateToStockDetails(
                              context,
                              'TCS',
                              3580.75,
                              -1.2,
                            ),
                        child: const Card(
                          elevation: 3,
                          margin: EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 5,
                          ),
                          child: ListTile(
                            leading: Icon(
                              Icons.trending_down,
                              color: Colors.red,
                            ),
                            title: Text('TCS'),
                            subtitle: Text('▼ 1.2%'),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap:
                            () => _navigateToStockDetails(
                              context,
                              'Infosys',
                              1505.30,
                              1.8,
                            ),
                        child: const Card(
                          elevation: 3,
                          margin: EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 5,
                          ),
                          child: ListTile(
                            leading: Icon(
                              Icons.trending_up,
                              color: Colors.green,
                            ),
                            title: Text('Infosys'),
                            subtitle: Text('▲ 1.8%'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
