import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'variables.dart';

class CompanyPage extends StatefulWidget {
  final String symbol;

  CompanyPage({Key? key, required this.symbol}) : super(key: key);


  @override
  _CompanyPageState createState() => _CompanyPageState();
}

class _CompanyPageState extends State<CompanyPage> {
  Map<String, dynamic>? companyInfo; // Make companyInfo nullable

  @override
  void initState() {
    super.initState();
    fetchCompanyInfo();
  }

 Future<void> fetchCompanyInfo() async {
  final response = await http.get(
    Uri.parse('${Variables.iexCloudBaseUrl}/data/core/company/${widget.symbol}?token=${Variables.iexCloudToken}'),
  );

  if (response.statusCode == 200) {
    final responseData = json.decode(response.body);
    setState(() {
      companyInfo = responseData;
    });
  } else {
    throw Exception('Failed to load company information');
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Company Details'),
      ),
      body: companyInfo == null
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Company Name: ${companyInfo!['companyName']}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text('Symbol: ${companyInfo!['symbol']}'),
                  SizedBox(height: 10),
                ],
              ),
            ),
    );
  }
}
