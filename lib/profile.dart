import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  final double initialMoney;
  final List<Map<String, dynamic>> boughtStocks;
  final String? symbol;
  final int? shares;
  final double? totalCost;
  final String? type;
  final int maxShares; // Add maxShares

  ProfilePage({
    required this.initialMoney,
    required this.boughtStocks,
    required this.maxShares,
    this.symbol,
    this.shares,
    this.totalCost,
    this.type,
  });

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late double money;
  late double buyingPower; // New variable to represent buying power
  late double profit; // New variable to represent profit

  @override
  void initState() {
    super.initState();
    _updateMoney(); // Update money, buying power, and profit when the widget initializes
  }

void _updateMoney() {
  // Calculate the total cost of bought stocks
  double totalCost = widget.boughtStocks.fold(0, (sum, stock) {
    if (stock['type'] == 'Buy') {
      return sum + stock['cost'];
    } else {
      return sum;
    }
  });

  // Calculate the total cost of sold stocks
  double totalSoldCost = widget.boughtStocks.fold(0, (sum, stock) {
    if (stock['type'] == 'Sell') {
      return sum + stock['cost']; // Add the cost for sold stocks
    } else {
      return sum;
    }
  });

  // Adjust the buying power calculation
  double updatedBuyingPower = widget.initialMoney + totalSoldCost - totalCost;
  buyingPower = updatedBuyingPower >= 0 ? updatedBuyingPower : 0; // Ensure buying power is not negative

  // Set money to the initial amount (initial money)
  money = widget.initialMoney;

  // Calculate profit using purchase date
  profit = widget.boughtStocks.fold(0, (total, stock) {
    if (stock['type'] == 'Buy') {
      double initialCost = stock['pricePerStock'] * stock['shares'];
      double currentCost = stock['pricePerStock'] * stock['shares'];
      
      // Get the purchase date
      DateTime purchaseDate = DateTime.parse(stock['date']);
      // Get the current date
      DateTime currentDate = DateTime.now();
      
      // Calculate the difference in days
      int differenceInDays = currentDate.difference(purchaseDate).inDays;

      // Adjust the profit based on the number of days held
      double adjustedProfit = (currentCost - initialCost) * (1 - differenceInDays * 0.001);

      return total + adjustedProfit;
    }
    return total;
  });
}

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Color.fromARGB(255, 26, 67, 113),
    appBar: AppBar(
      backgroundColor: Color.fromARGB(255, 48, 67, 83),
      title: Text('Profile'),
    ),
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.all(8.0),
                margin: EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Balance \$${money.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Row(
                        children: [
                          Text(
                            'Profit ',
                            style: TextStyle(fontSize: 10, color: profit >= 0 ? Colors.green : Colors.red),
                          ),
                          Text(
                            '\$${profit.abs().toStringAsFixed(2)}',
                            style: TextStyle(fontSize: 10, color: profit >= 0 ? Colors.green : Colors.red),
                          ),
                          Icon(
                            profit >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                            color: profit >= 0 ? Colors.green : Colors.red,
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Buying Power: \$${buyingPower.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(8.0),
                margin: EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5), 
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Text(
                        'Assets',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: widget.boughtStocks.map((stock) {
                        if (stock['type'] == 'Buy') {
                          int totalBoughtShares = widget.boughtStocks
                              .where((s) => s['symbol'] == stock['symbol'] && s['type'] == 'Buy')
                              .map<int>((s) => s['shares'])
                              .fold(0, (prev, el) => prev + el);
                          int totalSoldShares = widget.boughtStocks
                              .where((s) => s['symbol'] == stock['symbol'] && s['type'] == 'Sell')
                              .map<int>((s) => s['shares'])
                              .fold(0, (prev, el) => prev + el);
                          int remainingShares = totalBoughtShares - totalSoldShares;

                          if (remainingShares > 0) {
                            double currentValue = stock['pricePerStock'] * remainingShares;
                            double profitPerStock = currentValue - (stock['pricePerStock'] * remainingShares);

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${stock['symbol']}: $remainingShares stocks',
                                  style: TextStyle(fontSize: 14),
                                ),
                                Text(
                                  '\$${currentValue.toStringAsFixed(2)}',
                                  style: TextStyle(fontSize: 12),
                                ),
                                Text(
                                  '\$${profitPerStock.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: profitPerStock >= 0 ? Colors.green : Colors.red,
                                  ),
                                ),
                              ],
                            );
                          } else {
                            return SizedBox();
                          }
                        } else {
                          return SizedBox();
                        }
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Scrollbar(
                isAlwaysShown: true,
                child: DataTable(
                  headingRowColor: MaterialStateColor.resolveWith((states) => Colors.blueGrey),
                  dataRowColor: MaterialStateColor.resolveWith((states) => Colors.white),
                  columns: [
                    DataColumn(label: Text('Symbol', style: TextStyle(color: Colors.white))),
                    DataColumn(label: Text('Type', style: TextStyle(color: Colors.white))),
                    DataColumn(label: Text('Price', style: TextStyle(color: Colors.white))),
                    DataColumn(label: Text('Stock', style: TextStyle(color: Colors.white))),
                    DataColumn(label: Text('Total Cost', style: TextStyle(color: Colors.white))),
                    DataColumn(label: Text('Purchase Date', style: TextStyle(color: Colors.white))),
                  ],
                  rows: widget.boughtStocks.map((stock) {
                    return DataRow(cells: [
                      DataCell(Text(stock['symbol'])),
                      DataCell(
                        Text(
                          stock['type'],
                          style: TextStyle(color: stock['type'] == 'Buy' ? Colors.green : Colors.red),
                        ),
                      ),
                      DataCell(Text('\$${stock['pricePerStock'].toStringAsFixed(2)}')),
                      DataCell(Text(stock['shares'].toString())),
                      DataCell(Text('\$${stock['cost'].toStringAsFixed(2)}')),
                      DataCell(Text(stock['date'])),
                    ]);
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

}
