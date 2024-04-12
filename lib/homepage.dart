import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'variables.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'profile.dart';
import 'package:intl/intl.dart';
import 'company.dart';


class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> stockData = [];
  String symbol = '';
  List<Map<String, dynamic>> boughtStocks = []; // List to store bought stocks
  bool canSell = false; // Flag to determine if selling is allowed

  TextEditingController _buySharesController = TextEditingController();
  TextEditingController _sellSharesController = TextEditingController();

  bool isBuying = true; // Define isBuying variable

  double initialMoney = 10000; // Define initialMoney variable
  int maxShares = 0;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      // Empty the stockData list when user starts typing in the search bar
      setState(() {
        stockData.clear();
      });
    });
  }

  Future<void> fetchStockData(String symbol) async {
    final response = await http.get(
      Uri.parse('${Variables.iexCloudBaseUrl}/data/core/historical_prices/$symbol?range=2m&token=${Variables.iexCloudToken}'),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData.isNotEmpty) {
        // Check if the list is not empty
        setState(() {
          stockData = responseData.cast<Map<String, dynamic>>();
          this.symbol = responseData[0]['symbol'];
        });
      } else {
        // Handle the case when responseData is empty
        setState(() {
          stockData = []; // Clear the stockData list
          this.symbol = ''; // Reset the symbol
        });
      }
    } else {
      throw Exception('Failed to load stock data');
    }
  }

  Future<double> fetchCurrentClosePrice(String symbol) async {
    final response = await http.get(
      Uri.parse('https://api.iex.cloud/v1/data/core/quote/$symbol?token=${Variables.iexCloudToken}'),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData is List && responseData.isNotEmpty) {
        final firstElement = responseData.first;
        if (firstElement is Map<String, dynamic> && firstElement.containsKey('latestPrice')) {
          return firstElement['latestPrice'];
        } else {
          throw Exception('Invalid response structure for current close price');
        }
      } else {
        throw Exception('Empty or invalid response array for current close price');
      }
    } else {
      throw Exception('Failed to load current close price: ${response.statusCode}');
    }
  }

 

//modals

  double _calculateCost(String shares, double currentClosePrice) {
    int numberOfShares = int.tryParse(shares) ?? 0;
    if (numberOfShares > 0 && currentClosePrice != null) {
      return numberOfShares * currentClosePrice;
    }
    return 0.0; // Return a double value
  }

//override
}
