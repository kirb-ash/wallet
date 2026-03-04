import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:home_widget/home_widget.dart';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RedBlackWallet());
}

class RedBlackWallet extends StatelessWidget {
  const RedBlackWallet({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sleek Wallet',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        cardColor: const Color(0xFF121212),
      ),
      home: const WalletScreen(),
    );
  }
}

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  double balance = 0.0;
  double dailyLimit = 2000.0; 
  List<Map<String, dynamic>> history = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    // Connects Flutter to the iOS Dynamic Island Tunnel
    HomeWidget.setAppGroupId('group.com.pala.wallet');
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('balance', balance);
    await prefs.setString('history', json.encode(history));
    
    // UPDATING THE REAL DYNAMIC ISLAND
    double spent = dailyLimit - balance;
    await HomeWidget.saveWidgetData<double>('spent_today', spent);
    await HomeWidget.updateWidget(iOSName: 'WalletIsland'); 
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      balance = prefs.getDouble('balance') ?? 0.0;
      String? historyStr = prefs.getString('history');
      if (historyStr != null) {
        history = List<Map<String, dynamic>>.from(json.decode(historyStr));
      }
    });
  }

  void _addTransaction(String title, double amount, bool isIncome) {
    setState(() {
      isIncome ? balance += amount : balance -= amount;
      history.insert(0, {
        "title": title.isEmpty ? (isIncome ? "Income" : "Expense") : title,
        "amount": "${isIncome ? '+' : '-'} ₹$amount",
        "isIncome": isIncome,
        "time": "Just now"
      });
    });
    _saveData();
  }

  Color getStatusColor(double progress) {
    if (progress > 0.8) return Colors.greenAccent;
    if (progress > 0.4) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    double progress = (balance / dailyLimit).clamp(0.0, 1.0);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // THE PILL UI
              Center(
                child: Container(
                  height: 38, width: 180,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Stack(
                    children: [
                      FractionallySizedBox(
                        widthFactor: progress,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          decoration: BoxDecoration(
                            color: getStatusColor(progress).withOpacity(0.5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                      const Center(child: Text("CAPACITY", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 50),
              const Text("Wallet", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
              Text("₹${balance.toStringAsFixed(2)}", style: TextStyle(fontSize: 32, color: getStatusColor(progress))),
              const SizedBox(height: 40),
              Expanded(
                child: ListView.builder(
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final item = history[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: const Color(0xFF121212), borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(item['title'], style: const TextStyle(fontSize: 18)),
                          Text(item['amount'], style: TextStyle(color: item['isIncome'] ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.redAccent,
        onPressed: () => _showInputSheet(),
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  void _showInputSheet() {
    final title = TextEditingController();
    final amount = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121212),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            TextField(controller: title, decoration: const InputDecoration(hintText: "Item")),
            TextField(controller: amount, decoration: const InputDecoration(hintText: "₹"), keyboardType: TextInputType.number),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: ElevatedButton(onPressed: () { _addTransaction(title.text, double.parse(amount.text), false); Navigator.pop(ctx); }, child: const Text("SPENT"))),
                const SizedBox(width: 10),
                Expanded(child: ElevatedButton(onPressed: () { _addTransaction(title.text, double.parse(amount.text), true); Navigator.pop(ctx); }, child: const Text("EARNED"))),
              ],
            )
          ],
        ),
      ),
    );
  }
}
