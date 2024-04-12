import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'variables.dart';
import 'package:flutter_web_browser/flutter_web_browser.dart';

class CompanyPage extends StatefulWidget {
  final String symbol;

  CompanyPage({Key? key, required this.symbol}) : super(key: key);

  @override
  _CompanyPageState createState() => _CompanyPageState();
}

class _CompanyPageState extends State<CompanyPage> {
  Map<String, dynamic>? companyInfo;

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

      if (responseData is List && responseData.isNotEmpty) {
        setState(() {
          companyInfo = responseData[0];
        });
      } else {
        throw Exception('Empty or invalid response data');
      }
    } else {
      throw Exception('Failed to load company information');
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Color.fromARGB(255, 26, 67, 113),
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 48, 67, 83),
        title: Text('Company Details'),
      ),
      body: companyInfo == null
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Center(
                      child: Text(
                        '${companyInfo!['companyName'] ?? 'N/A'} (${companyInfo!['symbol'] ?? 'N/A'})',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  RichText(
                    text: TextSpan(
                      text: 'CEO: ',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                      children: <TextSpan>[
                        TextSpan(
                          text: '${companyInfo!['ceo'] ?? 'N/A'}',
                          style: TextStyle(fontWeight: FontWeight.normal, color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  RichText(
                    text: TextSpan(
                      text: 'Address: ',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                      children: <TextSpan>[
                        TextSpan(
                          text: '${companyInfo!['address'] ?? 'N/A'}, ${companyInfo!['city'] ?? 'N/A'}, ${companyInfo!['state'] ?? 'N/A'}, ${companyInfo!['country'] ?? 'N/A'}',
                          style: TextStyle(fontWeight: FontWeight.normal),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  RichText(
                    text: TextSpan(
                      text: 'Exchange: ',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                      children: <TextSpan>[
                        TextSpan(
                          text: '${companyInfo!['exchange'] ?? 'N/A'}',
                          style: TextStyle(fontWeight: FontWeight.normal,  color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  RichText(
                    text: TextSpan(
                      text: 'Industry: ',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                      children: <TextSpan>[
                        TextSpan(
                          text: '${companyInfo!['industry'] ?? 'N/A'}',
                          style: TextStyle(fontWeight: FontWeight.normal, color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  RichText(
                    text: TextSpan(
                      text: 'Description: ',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,  color: Colors.black),
                      children: <TextSpan>[
                        TextSpan(
                          text: '${companyInfo!['longDescription'] ?? 'N/A'}',
                          style: TextStyle(fontWeight: FontWeight.normal,  color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  TextButton(
                    onPressed: () async {
                      String url = companyInfo!['website'] ?? '';
                      await FlutterWebBrowser.openWebPage(url: url); // Launch URL using flutter_web_browser package
                    },
                    child: Text(
                      'Website: ${companyInfo!['website'] ?? 'N/A'}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
