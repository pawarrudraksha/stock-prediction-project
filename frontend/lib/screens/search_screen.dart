import 'package:flutter/material.dart';
import 'package:frontend/functions/api_services.dart';
import 'package:frontend/screens/stock_details_screen.dart'; // Replace with your actual path

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final data = await ApiService.searchStocks(query);
      setState(() {
        _searchResults = List<Map<String, dynamic>>.from(data['stocks']);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
    }
  }

  void _navigateToDetails(String ticker) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StockDetailsScreen(ticker: ticker),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Stocks'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search for a stock',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _performSearch(_searchController.text),
                ),
              ),
              onChanged: _performSearch,
            ),
            const SizedBox(height: 10),
            _isLoading
                ? const CircularProgressIndicator()
                : Expanded(
                  child:
                      _searchResults.isEmpty
                          ? const Center(child: Text('No stocks found'))
                          : ListView.builder(
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final stock = _searchResults[index];
                              final name = stock['name'] ?? 'Unnamed Stock';
                              final ticker = stock['ticker'] ?? '';

                              return ListTile(
                                leading: const Icon(
                                  Icons.trending_up,
                                  color: Colors.green,
                                ),
                                title: Text(name),
                                subtitle: Text(ticker),
                                onTap: () {
                                  if (ticker.isNotEmpty) {
                                    _navigateToDetails(ticker);
                                  }
                                },
                              );
                            },
                          ),
                ),
          ],
        ),
      ),
    );
  }
}
