import 'package:flutter/material.dart';
import 'package:frontend/functions/user_services.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  List<Map<String, dynamic>> watchlistStocks = [];
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
    fetchWatchlist();
  }

  Future<void> fetchWatchlist() async {
    try {
      final data = await UserServices.getWatchlist();
      setState(() {
        watchlistStocks = List<Map<String, dynamic>>.from(data);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Failed to fetch watchlist')),
      );
    }
  }

  Future<void> removeFromWatchlist(String stockId) async {
    try {
      await UserServices.removeFromWatchlist(stockId);
      setState(() {
        watchlistStocks.removeWhere(
          (stock) => stock['id'] == stockId || stock['_id'] == stockId,
        );
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('✅ Removed from watchlist')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Failed to remove from watchlist')),
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
          ' Watchlist',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        backgroundColor: Colors.indigo.shade700,
        elevation: 4,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          color: Colors.grey.shade100,
          padding: const EdgeInsets.all(16.0),
          child:
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : watchlistStocks.isEmpty
                  ? const Center(
                    child: Text(
                      '🔍 Your watchlist is empty.',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                  : ListView.builder(
                    itemCount: watchlistStocks.length,
                    itemBuilder: (context, index) {
                      final stock = watchlistStocks[index];
                      final stockId = stock['id'] ?? stock['_id'];
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        padding: const EdgeInsets.symmetric(
                          vertical: 18,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.indigo.shade100,
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.indigo.shade200,
                              child: Text(
                                stock['ticker'][0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    stock['stockName'],
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    stock['ticker'],
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_forever,
                                color: Colors.redAccent,
                              ),
                              onPressed: () => removeFromWatchlist(stockId),
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
