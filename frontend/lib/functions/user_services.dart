import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserServices {
  // static const String _baseUrl = 'http://10.0.2.2:3000/api/auth';
  // static const String _baseUrl2 = 'http://10.0.2.2:3000/api/stocks';
  static const String _baseUrl =
      'https://stock-prediction-project-ject.onrender.com/api/auth';
  static const String _baseUrl2 =
      'https://stock-prediction-project-ject.onrender.com/api/stocks';

  static Future<Map<String, dynamic>> getUserProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('jwt_token');

    if (token == null) {
      throw Exception("User not authenticated");
    }

    final url = Uri.parse('$_baseUrl/profile');
    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch user profile');
    }
  }

  static Future<List<dynamic>> getUserPredictions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('jwt_token');

    if (token == null) {
      throw Exception("User not authenticated");
    }

    final url = Uri.parse('$_baseUrl2/predictions'); // Adjust path if needed
    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );
    if (response.statusCode == 200) {
      return json.decode(response.body); // Ensure your backend returns this key
    } else {
      throw Exception("Failed to fetch user predictions");
    }
  }

  static Future<List<dynamic>> getWatchlist() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('jwt_token');

    if (token == null) {
      throw Exception("User not authenticated");
    }

    final url = Uri.parse('$_baseUrl2/watchlist');
    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch user profile');
    }
  }

  static Future<void> addToWatchlist(String ticker) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('jwt_token');

    if (token == null) {
      throw Exception("User not authenticated");
    }

    final url = Uri.parse('$_baseUrl2/watchlist/add');
    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({"ticker": ticker}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to add stock to watchlist');
    }
  }

  static Future<void> removeFromWatchlist(String stockId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('jwt_token');

    if (token == null) {
      throw Exception("User not authenticated");
    }

    final url = Uri.parse('$_baseUrl2/watchlist/remove');
    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({"stockId": stockId}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to remove stock from watchlist');
    }
  }
}
