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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Prediction - ${widget.ticker}'),
        backgroundColor: Colors.blue.shade800,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            Text(
              'Select Prediction Model:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 50,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.shade400),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedModel,
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color: Colors.blue.shade900,
                    ),
                    isExpanded: true,
                    items:
                        ['Random Forest', 'XGBoost']
                            .map(
                              (model) => DropdownMenuItem(
                                value: model,
                                child: Text(
                                  model,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.blue.shade900,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedModel = value!;
                      });
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _predictStockPrice,
              child:
                  isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                        'Predict using $selectedModel',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
            ),
            const SizedBox(height: 30),
            if (currentPrice != null || predictedPrice != null)
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      if (currentPrice != null) ...[
                        Text(
                          'Current Price:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          currentPrice!,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                      if (predictedPrice != null) ...[
                        const SizedBox(height: 20),
                        Text(
                          'Predicted Price:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          predictedPrice!,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
