import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:frontend/functions/api_services.dart';
import 'package:intl/intl.dart';

class RLTradingSimulatorScreen extends StatefulWidget {
  const RLTradingSimulatorScreen({super.key});

  @override
  State<RLTradingSimulatorScreen> createState() =>
      _RLTradingSimulatorScreenState();
}

class _RLTradingSimulatorScreenState extends State<RLTradingSimulatorScreen> {
  final TextEditingController _searchController = TextEditingController();
  Future<Map<String, dynamic>?>? simulationFuture;
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  void _onSearchChanged(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final data = await ApiService.searchStocks(query);
      setState(() {
        _searchResults = List<Map<String, dynamic>>.from(data['stocks']);
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    }
  }

  void _simulate(String ticker) {
    if (ticker.isNotEmpty) {
      setState(() {
        simulationFuture = ApiService.fetchRLSimulation(ticker);
        _searchResults = [];
        _searchController.text = ticker;
      });
    }
  }

  List<FlSpot> _buildPriceSpots(List<Map<String, dynamic>> history) {
    return List<FlSpot>.generate(history.length, (index) {
      final price = history[index]['price']?.toDouble() ?? 0.0;
      return FlSpot(index.toDouble(), price);
    });
  }

  String _formatDate(String date) {
    try {
      // Parse the date string into a DateTime object
      final dateTime = DateTime.parse(date);
      // Format it to a readable string like "Jun 26, 2024"
      return "${dateTime.day} ${_monthToString(dateTime.month)}, ${dateTime.year}";
    } catch (e) {
      return date; // In case the date format is invalid, return the raw date string
    }
  }

  String _monthToString(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  List<Widget> _buildTradeSummaries(List<Map<String, dynamic>> history) {
    List<Widget> tradeTiles = [];
    double accumulatedProfit = 0;
    List<Map<String, dynamic>> holdings = [];
    double initialCash = 0;

    for (var trade in history) {
      final price = trade['price']?.toDouble() ?? 0.0;
      final action = trade['action'] ?? '';
      final shares = trade['shares']?.toDouble() ?? 0.0;
      final date = trade['date'] ?? ''; // Get the date from the trade history

      // Format the date to a more readable format
      final formattedDate = _formatDate(date);

      if (action == 'Buy') {
        initialCash -= price * shares;
        holdings.add({'price': price, 'shares': shares});

        tradeTiles.add(
          ListTile(
            leading: const Icon(Icons.shopping_cart, color: Colors.blue),
            title: Text('Buy @ ${_formatCurrency(price)}'),
            subtitle: Text(
              'Date: $formattedDate',
            ), // Display the formatted date
          ),
        );
      } else if (action == 'Sell') {
        double totalProfit = 0;
        double remainingShares = shares;
        while (holdings.isNotEmpty && remainingShares > 0) {
          final buy = holdings.removeAt(0);
          final buyShares = buy['shares']?.toDouble() ?? 0.0;
          final buyPrice = buy['price']?.toDouble() ?? 0.0;
          final matchedShares =
              buyShares <= remainingShares ? buyShares : remainingShares;
          totalProfit += (price - buyPrice) * matchedShares;
          if (buyShares > matchedShares) {
            holdings.insert(0, {
              'price': buyPrice,
              'shares': buyShares - matchedShares,
            });
          }
          remainingShares -= matchedShares;
        }
        accumulatedProfit += totalProfit;
        initialCash += price * shares;

        tradeTiles.add(
          ListTile(
            leading: Icon(
              Icons.shopping_cart_checkout,
              color: totalProfit >= 0 ? Colors.green : Colors.red,
            ),
            title: Text('Sell @ ${_formatCurrency(price)}'),
            subtitle: Text(
              'Date: $formattedDate',
            ), // Display the formatted date
          ),
        );
      } else {
        tradeTiles.add(
          ListTile(
            leading: const Icon(Icons.pause_circle_outline, color: Colors.blue),
            title: Text('Hold @ ${_formatCurrency(price)}'),
            subtitle: Text(
              'Date: $formattedDate',
            ), // Display the formatted date
          ),
        );
      }
    }

    return tradeTiles;
  }

  double _calculateTotalProfit(List<Map<String, dynamic>> history) {
    double profit = 0;
    List<Map<String, dynamic>> holdings = [];

    for (var trade in history) {
      final action = trade['action'];
      final price = trade['price']?.toDouble() ?? 0.0;
      final shares = trade['shares']?.toDouble() ?? 0.0;

      if (action == 'Buy') {
        holdings.add({'price': price, 'shares': shares});
      } else if (action == 'Sell') {
        double remainingShares = shares;
        while (holdings.isNotEmpty && remainingShares > 0) {
          final buy = holdings.removeAt(0);
          final buyShares = buy['shares']?.toDouble() ?? 0.0;
          final buyPrice = buy['price']?.toDouble() ?? 0.0;
          final matchedShares =
              buyShares <= remainingShares ? buyShares : remainingShares;
          profit += (price - buyPrice) * matchedShares;
          if (buyShares > matchedShares) {
            holdings.insert(0, {
              'price': buyPrice,
              'shares': buyShares - matchedShares,
            });
          }
          remainingShares -= matchedShares;
        }
      }
    }

    return profit;
  }

  String _formatCurrency(num amount) {
    return '₹${NumberFormat('#,##0.00').format(amount)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'RL Trading Simulator',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        backgroundColor: Colors.indigo.shade700,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: const InputDecoration(
                labelText: 'Search Stock Ticker',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            if (_isSearching) const LinearProgressIndicator(),
            if (_searchResults.isNotEmpty)
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final stock = _searchResults[index];
                    final name = stock['name'] ?? 'Unnamed Stock';
                    final ticker = stock['ticker'] ?? '';
                    return ListTile(
                      leading: const Icon(
                        Icons.show_chart,
                        color: Colors.indigo,
                      ),
                      title: Text(name, style: const TextStyle(fontSize: 14)),
                      subtitle: Text(
                        ticker,
                        style: const TextStyle(fontSize: 13),
                      ),
                      onTap: () => _simulate(ticker),
                    );
                  },
                ),
              ),
            const SizedBox(height: 12),
            if (simulationFuture == null)
              const Text('Search and select a stock to run the simulation.')
            else
              FutureBuilder<Map<String, dynamic>?>(
                future: simulationFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data == null) {
                    return const Center(child: Text('No data available'));
                  }

                  final simulation = snapshot.data!;
                  final history = List<Map<String, dynamic>>.from(
                    simulation['history'] ?? [],
                  );

                  // Extract total_profit from the received data
                  final totalProfit =
                      simulation['total_profit']?.toDouble() ?? 0.0;

                  final initialCash =
                      simulation['initial_cash']?.toDouble() ?? 0.0;
                  final finalCash = simulation['final_cash']?.toDouble() ?? 0.0;
                  final profitColor =
                      totalProfit >= 0 ? Colors.green : Colors.red;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Card(
                        color: profitColor.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: Icon(
                            totalProfit >= 0
                                ? Icons.check_circle
                                : Icons.warning_amber_rounded,
                            color: profitColor,
                          ),
                          title: Text(
                            totalProfit >= 0
                                ? 'Simulation Successful'
                                : 'Simulation Complete',
                            style: TextStyle(
                              color: profitColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            'Total ${totalProfit >= 0 ? 'Profit' : 'Loss'}: ${_formatCurrency(totalProfit)}',
                            style: TextStyle(color: profitColor, fontSize: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Text(
                            'Initial Cash: ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _formatCurrency(initialCash),
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            'Final Cash: ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _formatCurrency(finalCash),
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      const Text(
                        'Price Trend Over Time',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: 16,
                        ), // Add space below the text
                        child: Text(
                          'The chart below represents the stock price movements at each step of the simulation.',
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                Colors
                                    .indigo, // Change text color to indigo or any color you prefer
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),
                      SizedBox(
                        height: 220,
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(show: true),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  interval: 50,
                                  getTitlesWidget:
                                      (value, _) => Text('₹${value.toInt()}'),
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 50,
                                  getTitlesWidget:
                                      (value, _) => Transform.rotate(
                                        angle: -0.5,
                                        child: Text('T${value.toInt()}'),
                                      ),
                                ),
                              ),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            borderData: FlBorderData(show: true),
                            lineBarsData: [
                              LineChartBarData(
                                spots: _buildPriceSpots(history),
                                isCurved: true,
                                color: Colors.indigo,
                                barWidth: 2,
                                dotData: FlDotData(show: false),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Trade History',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),
                      if (history.isEmpty)
                        const Text(
                          'No trades executed during simulation.',
                          style: TextStyle(color: Colors.grey),
                        )
                      else
                        Column(children: _buildTradeSummaries(history)),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
