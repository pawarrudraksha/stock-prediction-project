import 'package:flutter/material.dart';
import 'package:frontend/functions/api_services.dart';

class PredictionScreen extends StatefulWidget {
  final String ticker;

  const PredictionScreen({Key? key, required this.ticker}) : super(key: key);

  @override
  _PredictionScreenState createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  String selectedModel = 'Random Forest';
  String? predictedPrice;
  String? currentPrice;
  bool isLoading = false;

  Future<void> _predictStockPrice() async {
    setState(() {
      isLoading = true;
      predictedPrice = null;
      currentPrice = null;
    });

    try {
      final data = await ApiService.predictStock(widget.ticker, selectedModel);
      double current = double.tryParse(data['current_price'].toString()) ?? 0.0;
      double predicted =
          double.tryParse(data['predicted_price'].toString()) ?? 0.0;

      setState(() {
        currentPrice = '₹ ${current.toStringAsFixed(2)}';
        predictedPrice = '₹ ${predicted.toStringAsFixed(2)}';
      });
    } catch (e) {
      setState(() {
        currentPrice = 'Error fetching data';
        predictedPrice = null;
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  Widget _buildPriceCard() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      child:
          (currentPrice != null || predictedPrice != null)
              ? Card(
                key: ValueKey('$currentPrice-$predictedPrice'),
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      if (currentPrice != null) ...[
                        const Text(
                          'Current Price:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.indigo,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currentPrice!,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                      ],
                      if (predictedPrice != null) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Predicted Price:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.indigo,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          predictedPrice!,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              )
              : const SizedBox.shrink(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Prediction - ${widget.ticker}',
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        backgroundColor: Colors.indigo.shade700,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        color: Colors.indigo.shade50,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Select Prediction Model:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.indigo.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedModel,
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.indigo),
                  isExpanded: true,
                  items:
                      ['Random Forest', 'XGBoost'].map((model) {
                        return DropdownMenuItem(
                          value: model,
                          child: Text(
                            model,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.indigo,
                            ),
                          ),
                        );
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedModel = value!;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo.shade700,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _predictStockPrice,
              child:
                  isLoading
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : Text(
                        'Predict using $selectedModel',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
            ),
            const SizedBox(height: 20),
            _buildPriceCard(),
          ],
        ),
      ),
    );
  }
}
