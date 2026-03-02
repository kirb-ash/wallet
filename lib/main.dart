import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() async {
  // CRITICAL: This stops the "infinite rotation" on startup
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RedBlackWallet());
}

class RedBlackWallet extends StatelessWidget {
  const RedBlackWallet({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Wallet',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        cardColor: const Color(0xFF121212), // Sleek Matte Black
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
  double dailyLimit = 2000.0; // Your daily budget threshold
  List<Map<String, dynamic>> history = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // --- LOCAL DATA LOGIC ---
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('balance', balance);
    await prefs.setString('history', json.encode(history));
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      balance = prefs.getDouble('balance') ?? 0.0;
      String? historyString = prefs.getString('history');
      if (historyString != null) {
        history = List<Map<String, dynamic>>.from(json.decode(historyString));
      }
    });
  }

  void _addTransaction(String title, double amount, bool isIncome) {
    setState(() {
      if (isIncome) {
        balance += amount;
      } else {
        balance -= amount;
      }
      history.insert(0, {
        "title": title.isEmpty ? (isIncome ? "Income" : "Expense") : title,
        "amount": "${isIncome ? '+' : '-'} ₹$amount",
        "isIncome": isIncome,
        "time": "Just now"
      });
    });
    _saveData();
  }

  // --- UI LOGIC ---
  Color getStatusColor(double percent) {
    if (percent > 0.6) return Colors.greenAccent;
    if (percent > 0.3) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    // Calculates how much is left from right-to-left
    double progress = (balance / dailyLimit).clamp(0.0, 1.0);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // VIRTUAL DYNAMIC ISLAND (The progress pill)
              Center(
                child: Container(
                  height: 38,
                  width: 180,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Stack(
                    children: [
                      FractionallySizedBox(
                        widthFactor: progress,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [getStatusColor(progress), getStatusColor(progress).withOpacity(0.4)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                      const Center(
                        child: Text("CAPACITY", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 50),
              const Text("Wallet", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                "₹${balance.toStringAsFixed(2)}", 
                style: TextStyle(fontSize: 28, color: getStatusColor(progress), fontWeight: FontWeight.w300)
              ),
              const SizedBox(height: 40),
              const Text("TRANSACTION HISTORY", style: TextStyle(fontSize: 12, color: Colors.redAccent, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              // BENTO HISTORY LIST
              Expanded(
                child: ListView.builder(
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final item = history[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F0F0F),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['title'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                              const Text("Personal", style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                          Text(
                            item['amount'], 
                            style: TextStyle(
                              color: item['isIncome'] ? Colors.greenAccent : Colors.redAccent, 
                              fontSize: 18, 
                              fontWeight: FontWeight.bold
                            )
                          ),
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
        child: const Icon(Icons.add, size: 30, color: Colors.black),
      ),
    );
  }

  void _showInputSheet() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController amountController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 30, right: 30, top: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Add Entry", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(controller: titleController, decoration: const InputDecoration(hintText: "Item name (e.g., Lunch)")),
            TextField(controller: amountController, decoration: const InputDecoration(hintText: "Amount in ₹"), keyboardType: TextInputType.number),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red.withOpacity(0.2)),
                    onPressed: () { 
                      _addTransaction(titleController.text, double.tryParse(amountController.text) ?? 0, false); 
                      Navigator.pop(context); 
                    }, 
                    child: const Text("SPENT", style: TextStyle(color: Colors.redAccent)),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green.withOpacity(0.2)),
                    onPressed: () { 
                      _addTransaction(titleController.text, double.tryParse(amountController.text) ?? 0, true); 
                      Navigator.pop(context); 
                    }, 
                    child: const Text("EARNED", style: TextStyle(color: Colors.greenAccent)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}