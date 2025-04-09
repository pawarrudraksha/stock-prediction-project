import 'package:flutter/material.dart';
import 'package:frontend/functions/api_services.dart';
import 'package:frontend/screens/stock_details_screen.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

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
        title: const Text(
          'Search Stocks',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        backgroundColor: Colors.indigo.shade700,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Container(
        color: Colors.indigo.shade50,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Search for a stock',
                labelStyle: const TextStyle(fontSize: 14),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search, color: Colors.indigo),
                  onPressed:
                      () => _performSearch(_searchController.text.trim()),
                ),
              ),
              onChanged: _performSearch,
            ),
            const SizedBox(height: 12),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Expanded(
                  child:
                      _searchResults.isEmpty
                          ? Center(
                            child: Text(
                              _hasSearched
                                  ? 'No stocks found'
                                  : 'Search to see stocks',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )
                          : ListView.builder(
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final stock = _searchResults[index];
                              final name = stock['name'] ?? 'Unnamed Stock';
                              final ticker = stock['ticker'] ?? '';

                              return Card(
                                elevation: 3,
                                margin: const EdgeInsets.symmetric(
                                  vertical: 6,
                                  horizontal: 4,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  leading: const Icon(
                                    Icons.show_chart,
                                    color: Colors.indigo,
                                  ),
                                  title: Text(
                                    name,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  subtitle: Text(
                                    ticker,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  onTap: () {
                                    if (ticker.isNotEmpty) {
                                      _navigateToDetails(ticker);
                                    }
                                  },
                                ),
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
