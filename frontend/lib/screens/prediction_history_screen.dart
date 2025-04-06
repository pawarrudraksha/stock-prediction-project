import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:frontend/functions/user_services.dart';

class PredictionHistoryScreen extends StatefulWidget {
  const PredictionHistoryScreen({super.key});

  @override
  State<PredictionHistoryScreen> createState() =>
      _PredictionHistoryScreenState();
}

class _PredictionHistoryScreenState extends State<PredictionHistoryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  List<Map<String, dynamic>> predictionHistory = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();
    fetchPredictions();
  }

  Future<void> fetchPredictions() async {
    try {
      final data = await UserServices.getUserPredictions();
      setState(() {
        predictionHistory = List<Map<String, dynamic>>.from(
          data.map(
            (prediction) => {
              'ticker': prediction['ticker'],
              'model': prediction['model_used'].toString().toUpperCase(),
              'date': DateFormat(
                'yyyy-MM-dd',
              ).format(DateTime.parse(prediction['timestamp'])),
              'currentPrice':
                  '\$${prediction['current_price'].toStringAsFixed(2)}',
              'predictedPrice':
                  '\$${prediction['predicted_price'].toStringAsFixed(2)}',
            },
          ),
        );
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch predictions in screen')),
      );
    }
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
        title: const Text(
          'Prediction History',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blueAccent, Colors.white],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: predictionHistory.length,
                    itemBuilder: (context, index) {
                      final history = predictionHistory[index];
                      final currentPrice =
                          double.tryParse(
                            history['currentPrice'].toString().replaceAll(
                              RegExp(r'[^0-9\.]'),
                              '',
                            ),
                          ) ??
                          0.0;
                      final predictedPrice =
                          double.tryParse(
                            history['predictedPrice'].toString().replaceAll(
                              RegExp(r'[^0-9\.]'),
                              '',
                            ),
                          ) ??
                          0.0;
                      final isPositive = predictedPrice >= currentPrice;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.shade100,
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isPositive
                                      ? Icons.trending_up_rounded
                                      : Icons.trending_down_rounded,
                                  color: isPositive ? Colors.green : Colors.red,
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '${history['ticker']} (${history['model']})',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Date: ${history['date']}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Current Price: ${history['currentPrice']}',
                              style: const TextStyle(fontSize: 15),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Predicted Price: ${history['predictedPrice']}',
                              style: TextStyle(
                                fontSize: 15,
                                color: isPositive ? Colors.green : Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
    );
  }
}
