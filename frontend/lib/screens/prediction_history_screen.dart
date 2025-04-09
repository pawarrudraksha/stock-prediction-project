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
        const SnackBar(content: Text('Failed to fetch predictions')),
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
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.indigo.shade700,
        elevation: 0,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  color: Colors.indigo.shade50,
                  padding: const EdgeInsets.all(16),
                  child:
                      predictionHistory.isEmpty
                          ? const Center(
                            child: Text(
                              'No prediction history available.',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )
                          : ListView.builder(
                            itemCount: predictionHistory.length,
                            itemBuilder: (context, index) {
                              final history = predictionHistory[index];
                              final currentPrice =
                                  double.tryParse(
                                    history['currentPrice']
                                        .toString()
                                        .replaceAll(RegExp(r'[^0-9\.]'), ''),
                                  ) ??
                                  0.0;
                              final predictedPrice =
                                  double.tryParse(
                                    history['predictedPrice']
                                        .toString()
                                        .replaceAll(RegExp(r'[^0-9\.]'), ''),
                                  ) ??
                                  0.0;
                              final isPositive = predictedPrice >= currentPrice;

                              return Card(
                                elevation: 3,
                                margin: const EdgeInsets.symmetric(
                                  vertical: 6,
                                  horizontal: 4,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            isPositive
                                                ? Icons.trending_up
                                                : Icons.trending_down,
                                            color:
                                                isPositive
                                                    ? Colors.green
                                                    : Colors.red,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              '${history['ticker']} (${history['model']})',
                                              style: const TextStyle(
                                                fontSize: 14,
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
                                          fontSize: 13,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Current Price: ${history['currentPrice']}',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Predicted Price: ${history['predictedPrice']}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color:
                                              isPositive
                                                  ? Colors.green
                                                  : Colors.red,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                ),
              ),
    );
  }
}
