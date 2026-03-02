import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(MaterialApp(home: PesBentoApp(), theme: ThemeData.dark(), debugShowCheckedModeBanner: false));

class PesBentoApp extends StatefulWidget {
  @override
  _PesBentoAppState createState() => _PesBentoAppState();
}

class _PesBentoAppState extends State<PesBentoApp> {
  Map<String, dynamic> data = {"current_balance": 0.0, "today_spent": 0.0, "daily_limit": 1000.0};
  bool loading = true;

  @override
  void initState() { super.initState(); refresh(); }

  Future<void> refresh() async {
    final res = await http.get(Uri.parse('https://kirbyisfun.pythonanywhere.com/dashboard'));
    if (res.statusCode == 200) setState(() { data = json.decode(res.body); loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    double progress = (data['today_spent'] / data['daily_limit']).clamp(0.0, 1.0);
    return Scaffold(
      backgroundColor: Color(0xFF0F172A),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: Text("PES Wallet")),
      body: loading ? Center(child: CircularProgressIndicator()) : RefreshIndicator(
        onRefresh: refresh,
        child: ListView(
          padding: EdgeInsets.all(20),
          children: [
            // Balance Card
            Container(
              padding: EdgeInsets.all(25),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.indigoAccent, Colors.blueAccent]),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(children: [
                Text("Total Balance", style: TextStyle(color: Colors.white70)),
                Text("₹${data['current_balance']}", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
              ]),
            ),
            SizedBox(height: 20),
            // Progress Section
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(24)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text("Daily Budget"),
                  Text("₹${data['today_spent']} spent"),
                ]),
                SizedBox(height: 12),
                LinearProgressIndicator(value: progress, minHeight: 8, borderRadius: BorderRadius.circular(10)),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}