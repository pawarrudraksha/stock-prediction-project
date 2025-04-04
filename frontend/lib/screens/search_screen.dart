import 'package:flutter/material.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _searchResults = [];
  bool _isLoading = false;

  void _performSearch(String query) {
    setState(() {
      _isLoading = true;
    });

    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _isLoading = false;
        _searchResults =
            query.isEmpty
                ? []
                : [
                      'Reliance Industries',
                      'TCS',
                      'Infosys',
                      'HDFC Bank',
                      'ICICI Bank',
                    ]
                    .where(
                      (stock) =>
                          stock.toLowerCase().contains(query.toLowerCase()),
                    )
                    .toList();
      });
    });
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
                              return ListTile(
                                leading: const Icon(
                                  Icons.trending_up,
                                  color: Colors.green,
                                ),
                                title: Text(_searchResults[index]),
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
