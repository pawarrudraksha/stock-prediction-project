import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // static const String _baseUrl = 'http://10.0.2.2:3000/api/stocks';
  static const String _baseUrl =
      'https://stock-prediction-project-ject.onrender.com/api/stocks';

  static Future<List<dynamic>> getTrendingStocks() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('jwt_token');

      if (token == null) {
        throw Exception("User not authenticated");
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/trending'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((item) {
          return {
            "ticker": item["ticker"],
            "name": item["name"],
            "price": item["price"],
            "change": double.tryParse(item["change"].toString()) ?? 0.0,
          };
        }).toList();
      } else {
        throw Exception(
          "Failed to load trending stocks: ${response.statusCode}",
        );
      }
    } catch (e) {
      print("Error fetching trending stocks: $e");
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getSentiment(String ticker) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('jwt_token');

      if (token == null) {
        throw Exception("User not authenticated");
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/sentiment?ticker=$ticker'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        return {"sentiment": data["sentiment"], "summary": data["summary"]};
      } else {
        throw Exception("Failed to fetch sentiment: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching sentiment for $ticker: $e");
      return null;
    }
  }

  static Future<List<dynamic>> getMarketOverview() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('jwt_token');

      if (token == null) {
        throw Exception("User not authenticated");
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/overview'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((item) {
          return {
            "name": item["name"],
            "price": item["price"],
            "change":
                double.tryParse(item["change"].toString()) ??
                0.0, // Convert change to double
          };
        }).toList();
      } else {
        throw Exception(
          'Failed to load market overview: ${response.statusCode}',
        );
      }
    } catch (error) {
      print("Error fetching market overview: $error");
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getStockDetails(String ticker) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('jwt_token');

      if (token == null) {
        throw Exception("User not authenticated");
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/stock-details?ticker=$ticker'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception("Failed to load stock details: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching stock details: $e");
      return null;
    }
  }

  static Future<Map<String, dynamic>> predictStock(
    String ticker,
    String model,
  ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('jwt_token');

    if (token == null) {
      throw Exception("User not authenticated");
    }

    // Convert model name
    String formattedModel =
        model == 'Random Forest'
            ? 'rf'
            : model == 'XGBoost'
            ? 'xgb'
            : model;

    final url = Uri.parse('$_baseUrl/predict');
    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({"ticker": ticker, "model": formattedModel}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get prediction');
    }
  }

  static Future<Map<String, dynamic>> searchStocks(String query) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('jwt_token');

    if (token == null) {
      throw Exception("User not authenticated");
    }

    final url = Uri.parse('$_baseUrl/search?query=$query');
    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body); // Now returns a Map with "stocks" key
    } else {
      throw Exception('Failed to load stock search results');
    }
  }

  static Future<Map<String, dynamic>?> fetchRLSimulation(
    String stockSymbol,
  ) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('jwt_token');

      if (token == null) {
        throw Exception("User not authenticated");
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/simulate/$stockSymbol'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);

        // Convert all numeric values to double
        List<Map<String, dynamic>> history = [];
        if (data['daily_log'] != null) {
          history =
              (data['daily_log'] as List).map((item) {
                return {
                  'action': item['action'],
                  'date': item['date'],
                  'portfolio_value':
                      (item['portfolio_value'] as num).toDouble(),
                  'price': (item['price'] as num).toDouble(),
                  'shares':
                      item['shares'] != null
                          ? (item['shares'] as num).toDouble()
                          : 0.0,
                };
              }).toList();
        }

        // Extract initial_cash and final_cash from the summary
        double initialCash =
            (data['summary']['initial_value'] as num).toDouble();
        double finalCash = (data['summary']['final_value'] as num).toDouble();
        double totalProfit = finalCash - initialCash;
        return {
          "history": history,
          "initial_cash": initialCash, // Corresponding to initial_value
          "final_cash": finalCash, // Corresponding to final_value
          "total_profit": totalProfit,
        };
      } else {
        throw Exception(
          "Failed to fetch RL simulation: ${response.statusCode}",
        );
      }
    } catch (e) {
      print("Error fetching RL simulation for $stockSymbol: $e");
      return null;
    }
  }
}
