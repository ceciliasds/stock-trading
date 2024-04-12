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
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Symbol Not Found'),
              content: Text('The symbol $symbol was not found.'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("OK"),
                ),
              ],
            );
          },
        );
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

  void _openTradeModal(String symbol) {
    print('Opening trade modal'); // Debug print

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Trade $symbol'),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    isBuying = true;
                  });
                  _showBuyModal(symbol, _buySharesController);
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(Colors.green),
                ),
                child: Text(
                  'Buy',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    isBuying = false;
                  });
                  _showSellModal(symbol, _sellSharesController);
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(Colors.red),
                ),
                child: Text(
                  'Sell',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
            ),
          ],
        );
      },
    );
  }



  void _showBuyModal(String symbol, TextEditingController controller) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Buy Stocks"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter number of shares...',
                ),
              ),
              SizedBox(height: 10),
              FutureBuilder(
                future: fetchCurrentClosePrice(symbol),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else {
                    double currentClosePrice = snapshot.data ?? 0.0;
                    int numberOfShares = int.tryParse(controller.text) ?? 0;
                    double totalCost = _calculateCost(numberOfShares.toString(), currentClosePrice);
                    return Text('Total Cost: \$${totalCost.toStringAsFixed(2)}');
                  }
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                int shares = int.tryParse(controller.text) ?? 0;
                double currentClosePrice = await fetchCurrentClosePrice(symbol);
                double cost = _calculateCost(shares.toString(), currentClosePrice);

                // Check if the user has enough buying power to make the purchase
                double remainingBuyingPower = initialMoney - boughtStocks.fold(0, (sum, stock) {
                  if (stock['type'] == 'Buy') {
                    return sum + stock['cost'];
                  } else {
                    return sum;
                  }
                });

                if (shares > 0 && cost <= remainingBuyingPower) { // Check if cost is less than or equal to remainingBuyingPower
                  String formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
                  boughtStocks.add({
                    'symbol': symbol,
                    'shares': shares,
                    'cost': cost,
                    'pricePerStock': currentClosePrice,
                    'type': 'Buy',
                    'date': formattedDate,
                  });
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfilePage(
                        initialMoney: initialMoney,
                        boughtStocks: boughtStocks,
                        symbol: symbol,
                        shares: shares,
                        totalCost: cost,
                        type: 'Buy',
                        maxShares: maxShares,
                      ),
                    ),
                  );
                  setState(() {
                    canSell = true;
                    controller.clear();
                    symbol = '';
                  });
                } else {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text("Insufficient Buying Power"),
                        content: Text("You don't have enough buying power to make this purchase."),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text("OK"),
                          ),
                        ],
                      );
                    },
                  );
                }
                Navigator.of(context).pop();
              },
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(Colors.green),
              ),
              child: Text(
                'Buy',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }


  void _showSellModal(String symbol, TextEditingController controller) {
    int totalBoughtShares = boughtStocks.isEmpty
        ? 0
        : boughtStocks
        .where((stock) => stock['symbol'] == symbol && stock['type'] == 'Buy')
        .map<int>((stock) => stock['shares'])
        .fold(0, (previousValue, element) => previousValue + element);

    int totalSoldShares = boughtStocks.isEmpty
        ? 0
        : boughtStocks
        .where((stock) => stock['symbol'] == symbol && stock['type'] == 'Sell')
        .map<int>((stock) => stock['shares'])
        .fold(0, (previousValue, element) => previousValue + element);

    int maxShares = totalBoughtShares - totalSoldShares;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Sell Stocks"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter number of shares...',
                ),
              ),
              SizedBox(height: 10),
              Text('Max: $maxShares', style: TextStyle(color: Colors.grey)),
              SizedBox(height: 10),
              FutureBuilder(
                future: fetchCurrentClosePrice(symbol),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else {
                    double currentClosePrice = snapshot.data ?? 0.0;
                    int numberOfShares = int.tryParse(controller.text) ?? 0;
                    double totalCost = _calculateCost(numberOfShares.toString(), currentClosePrice);
                    return Text(
                      'Total Gain: \$${totalCost.toStringAsFixed(2)}', // Total gain for selling
                      style: TextStyle(fontWeight: FontWeight.bold),
                    );
                  }
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                int shares = int.tryParse(controller.text) ?? 0;
                double currentClosePrice = await fetchCurrentClosePrice(symbol);
                double totalCost = _calculateCost(shares.toString(), currentClosePrice);

                if (shares > 0 && shares <= maxShares) {
                  // Get the current date and format it
                  String formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

                  boughtStocks.add({
                    'symbol': symbol,
                    'shares': shares, // Negative shares indicate selling
                    'cost': totalCost, // Negative cost for selling
                    'pricePerStock': currentClosePrice,
                    'type': 'Sell',
                    'date': formattedDate, // Include the sell date
                  });
                  setState(() {
                    // Update state if necessary
                  });
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfilePage(
                        initialMoney: initialMoney,
                        boughtStocks: boughtStocks,
                        symbol: symbol,
                        shares: shares,
                        totalCost: -totalCost,
                        type: 'Sell',
                        maxShares: maxShares, // Pass maxShares here
                      ),
                    ),
                  );
                  Navigator.of(context).pop(); // Close the dialog
                } else {
                  // Show alert dialog if the number of shares exceeds the maximum
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text("Insufficient Shares"),
                        content: Text("You don't have enough shares to sell."),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text("OK"),
                          ),
                        ],
                      );
                    },
                  );
                }
              },
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(Colors.red),
              ),
              child: Text(
                'Sell',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }


  double _calculateCost(String shares, double currentClosePrice) {
    int numberOfShares = int.tryParse(shares) ?? 0;
    if (numberOfShares > 0 && currentClosePrice != null) {
      return numberOfShares * currentClosePrice;
    }
    return 0.0; // Return a double value
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 26, 67, 113),
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 48, 67, 83),
        title: SizedBox(
          height: 35, // Adjust the height here
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Enter company symbol...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30.0), // Adjust the roundness here
                borderSide: BorderSide(
                  color: Colors.grey, // Adjust the border color here
                ),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.fromLTRB(12, 4, 8, 4), // Adjust the padding here
              hintStyle: TextStyle(fontSize: 14), // Adjust the font size here
            ),
            style: TextStyle(fontSize: 14), // Adjust the font size here
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                fetchStockData(value);
                setState(() {
                  symbol = value; // Update the symbol variable
                });
              }
            },
          ),
        ),
        actions: <Widget>[
          Padding(
            padding: EdgeInsets.only(right: 8.0), // Add margin to the right
            child: SizedBox(
              width: 40, // Adjust the width here
              height: 40, // Adjust the height here
              child: CircleAvatar(
                backgroundColor: Colors.white, // Set background color to white
                child: IconButton(
                  icon: Icon(Icons.person),
                  color: Colors.black, // Set icon color to black
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfilePage(
                          initialMoney: 1000, // Provide the initial money here
                          boughtStocks: boughtStocks,
                          maxShares: maxShares,

                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
        automaticallyImplyLeading: false, // Disable back button
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // Adjust padding as needed
        child: symbol == null || symbol.isEmpty // Modify this line
            ? Center(
          // Display a placeholder if symbol is null
        )
            : SizedBox(
          width: double.infinity, // Set the width to match the parent width
          height: 300, // Set the desired height
          child: Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // Align children to the start (left side)
              children: <Widget>[
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, // Distribute children evenly along the row
                  children: <Widget>[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start, // Align children to the start (left side)
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CompanyPage(symbol: symbol),
                              ),
                            );
                          },
                          child: Text(
                            '$symbol',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),

                        SizedBox(height: 5), // Add some space between the text
                        FutureBuilder(
                          future: fetchCurrentClosePrice(symbol),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return CircularProgressIndicator();
                            } else if (snapshot.hasError) {
                              return Text('Error: ${snapshot.error}');
                            } else {
                              return Text(
                                '${snapshot.data != null ? snapshot.data : 'N/A'}',
                                style: TextStyle(fontSize: 16),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _openTradeModal(symbol); // Pass symbol as an argument
                      },
                      child: Text('Trade'),
                    ),

                  ],
                ),
                SizedBox(height: 10),
                Expanded(
                  child: Center(
                    child: stockData.isNotEmpty
                        ? SfCartesianChart(
                      primaryXAxis: CategoryAxis(),
                      series: <CandleSeries<Map<String, dynamic>, String>>[
                        CandleSeries<Map<String, dynamic>, String>(
                          dataSource: stockData,
                          xValueMapper: (Map<String, dynamic> data, _) => data['priceDate'],
                          lowValueMapper: (Map<String, dynamic> data, _) => data['low'],
                          highValueMapper: (Map<String, dynamic> data, _) => data['high'],
                          openValueMapper: (Map<String, dynamic> data, _) => data['open'],
                          closeValueMapper: (Map<String, dynamic> data, _) => data['close'],
                        )
                      ],
                    )
                        : SizedBox(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

    );




  }
}
