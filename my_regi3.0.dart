
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
void main() => runApp(InventoryApp());
class InventoryApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'レジ管理システム',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: InventoryScreen(),
    );
  }
}
class InventoryScreen extends StatefulWidget {
  @override
  _InventoryScreenState createState() => _InventoryScreenState();
}
class _InventoryScreenState extends State<InventoryScreen> {
  bool _isEditMode = false;
  static const List<Map<String, dynamic>> _defaultProducts = [
    {"name": "商品1", "stock": 50, "price": 500},
    {"name": "商品2", "stock": 30, "price": 1000},
    {"name": "商品3", "stock": 20, "price": 800},
    {"name": "商品4", "stock": 15, "price": 1200},
    {"name": "商品5", "stock": 10, "price": 1500},
    {"name": "商品6", "stock": 40, "price": 300},
    {"name": "商品7", "stock": 25, "price": 2000},
  ];
  List<Map<String, dynamic>> products = _defaultProducts
      .map((p) => Map<String, dynamic>.from(p))
      .toList();
  final List<Color> itemColors = [
    const Color(0xFFF0F9FF), const Color(0xFFF0FFF4), const Color(0xFFFFFBEB),
    const Color(0xFFFAF5FF), const Color(0xFFF0FDFA), const Color(0xFFFFF1F2),
    const Color(0xFFF8FAFC),
  ];
  final List<Color> accentColors = [
    Colors.blue, Colors.green, Colors.orange,
    Colors.purple, Colors.teal, Colors.pink,
    Colors.blueGrey,
  ];
  Map<int, int> _cart = {};
  List<Map<String, dynamic>> _orderHistory = [];
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      String? pJson = prefs.getString('products');
      if (pJson != null) {
        final loaded = List<Map<String, dynamic>>.from(json.decode(pJson));
        products = _mergeWithDefaultProducts(loaded);
      }
      String? hJson = prefs.getString('history');
      if (hJson != null) _orderHistory = List<Map<String, dynamic>>.from(json.decode(hJson));
    });
  }
  List<Map<String, dynamic>> _mergeWithDefaultProducts(List<Map<String, dynamic>> loaded) {
    final merged = loaded.map((p) => Map<String, dynamic>.from(p)).toList();
    if (merged.length < _defaultProducts.length) {
      for (int i = merged.length; i < _defaultProducts.length; i++) {
        merged.add(Map<String, dynamic>.from(_defaultProducts[i]));
      }
    }
    return merged;
  }
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('products', json.encode(products));
    await prefs.setString('history', json.encode(_orderHistory));
  }
  int get totalSales => _orderHistory.fold(0, (sum, order) => sum + (order['totalPrice'] as int));
  int get cartTotal => _cart.entries.fold(0, (sum, entry) => sum + (products[entry.key]['price'] * entry.value as int));
  void _updateCart(int index, int delta) {
    setState(() {
      int currentInCart = _cart[index] ?? 0;
      int newQty = currentInCart + delta;
      if (newQty <= 0) {
        _cart.remove(index);
      } else {
        if (delta > 0 && products[index]['stock'] <= currentInCart) return;
        _cart[index] = newQty;
      }
    });
  }
  void _clearCart() {
    setState(() {
      _cart.clear();
    });
  }
  Future<void> _showPaymentDialog() async {
    if (_cart.isEmpty) return;
    TextEditingController amountController = TextEditingController();
    final result = await Navigator.of(context).push<Map<String, int>>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (pageContext) => StatefulBuilder(
          builder: (context, setPageState) {
            int receivedAmount = int.tryParse(amountController.text) ?? 0;
            int change = receivedAmount - cartTotal;
            bool isShort = receivedAmount < cartTotal;
            return Scaffold(
              resizeToAvoidBottomInset: true,
              appBar: AppBar(
                title: const Text('お支払い確認'),
                automaticallyImplyLeading: false,
              ),
              body: SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade100),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("合計金額", style: TextStyle(fontSize: 11, color: Colors.grey)),
                                Text("¥$cartTotal", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red)),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  height: 32,
                                  child: ElevatedButton(
                                    onPressed: () => setPageState(() => amountController.text = cartTotal.toString()),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.indigo.shade700,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    ),
                                    child: const Text("ちょうど", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(12, 0, 12, MediaQuery.of(context).viewInsets.bottom + 12),
                        child: Column(
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("販売商品内訳", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: _cart.entries.map((e) {
                                      final color = accentColors[e.key % accentColors.length];
                                      return _buildProductChip(products[e.key]['name'], e.value, color);
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: amountController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                                labelText: 'お預かり金額',
                                labelStyle: const TextStyle(fontSize: 13),
                                prefix: const Padding(
                                  padding: EdgeInsets.only(right: 6),
                                  child: Text(
                                    '¥',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                suffix: (amountController.text).isEmpty
                                    ? Padding(
                                        padding: const EdgeInsets.only(right: 6),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            SizedBox(
                                              height: 32,
                                              child: OutlinedButton(
                                                onPressed: () => setPageState(() => amountController.text = '5000'),
                                                style: OutlinedButton.styleFrom(
                                                  side: BorderSide(color: Colors.indigo.shade700),
                                                  backgroundColor: Colors.white,
                                                  foregroundColor: Colors.indigo.shade700,
                                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                ),
                                                child: const Text(
                                                  "5,000",
                                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            SizedBox(
                                              height: 32,
                                              child: OutlinedButton(
                                                onPressed: () => setPageState(() => amountController.text = '10000'),
                                                style: OutlinedButton.styleFrom(
                                                  side: BorderSide(color: Colors.indigo.shade700),
                                                  backgroundColor: Colors.white,
                                                  foregroundColor: Colors.indigo.shade700,
                                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                ),
                                                child: const Text(
                                                  "10,000",
                                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : null,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                              onChanged: (_) => setPageState(() {}),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              decoration: BoxDecoration(
                                color: isShort ? Colors.grey.shade100 : Colors.indigo.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("お釣り", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                  Text("¥ ${isShort ? 0 : change}", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isShort ? Colors.grey : Colors.indigo.shade900)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: Colors.grey.shade400),
                                    backgroundColor: Colors.grey.shade100,
                                    shape: const StadiumBorder(),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  ),
                                  child: const Text(
                                    'もどる',
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton(
                                  onPressed: isShort ? null : () {
                                    Navigator.pop(context, {"received": receivedAmount, "change": change});
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.indigo.shade800,
                                    foregroundColor: Colors.white,
                                    shape: const StadiumBorder(),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  ),
                                  child: const Text('次へ (お渡し確認)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
    if (result != null) {
      _showDeliveryConfirmDialog(result["received"] ?? 0, result["change"] ?? 0);
    }
  }
  void _showDeliveryConfirmDialog(int received, int change) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Transform.scale(
          scale: 1.1,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('お渡し内容の確認', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "以下の商品を正しくお渡ししましたか？",
                  style: TextStyle(fontSize: 10, color: Colors.black87),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade100),
                  ),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _cart.entries.map((e) {
                      final color = accentColors[e.key % accentColors.length];
                      return _buildProductChip(products[e.key]['name'], e.value, color, isLarge: true);
                    }).toList(),
                  ),
                ),
                if (change > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("お釣り", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        Text(
                          "¥ $change",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showPaymentDialog();
                },
                child: const Text('戻る', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ),
              ElevatedButton(
                onPressed: () {
                  _processCheckout(received, change);
                  Navigator.pop(context);
                  _showCompletionSnackBar(change);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade800,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text(
                  'お渡し完了・確定',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  void _processCheckout(int received, int change) {
    setState(() {
      List<Map<String, dynamic>> historyItems = [];
      _cart.forEach((index, qty) {
        historyItems.add({"productIndex": index, "name": products[index]['name'], "qty": qty, "price": products[index]['price']});
        products[index]['stock'] -= qty;
      });
      _orderHistory.insert(0, {
        "id": DateTime.now().millisecondsSinceEpoch,
        "time": DateFormat('HH:mm').format(DateTime.now()),
        "totalPrice": cartTotal,
        "received": received,
        "change": change,
        "items": historyItems,
      });
      _cart.clear();
      _saveData();
    });
  }
  void _showCompletionSnackBar(int change) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("会計完了：お釣り ¥$change"), backgroundColor: Colors.green.shade700, behavior: SnackBarBehavior.floating),
    );
  }
  void _editStockDirectly(int index) async {
    final result = await _showTextInputPage(
      title: '${products[index]['name']} の在庫数入力',
      initialValue: products[index]['stock'].toString(),
      keyboardType: TextInputType.number,
    );
    if (result == null) return;
    setState(() {
      products[index]['stock'] = int.tryParse(result) ?? products[index]['stock'];
      _saveData();
    });
  }
  void _editHistoryItemQty(int orderIndex, int itemIndex) async {
    final order = _orderHistory[orderIndex];
    final item = order['items'][itemIndex];
    final pIndex = item['productIndex'];
    final result = await _showTextInputPage(
      title: '${item['name']} の購入数を変更',
      initialValue: item['qty'].toString(),
      keyboardType: TextInputType.number,
    );
    if (result == null) return;
    int? newQty = int.tryParse(result);
    if (newQty != null && newQty >= 0) {
      setState(() {
        int oldQty = item['qty'];
        int diff = newQty - oldQty;
        item['qty'] = newQty;
        products[pIndex]['stock'] -= diff;
        order['totalPrice'] = (order['items'] as List).fold(0, (sum, i) => sum + (i['price'] * i['qty'] as int));
        _saveData();
      });
    }
  }
  void _editDetail(int index, bool isPrice) async {
    final result = await _showTextInputPage(
      title: isPrice ? '単価編集' : '名称編集',
      initialValue: isPrice ? products[index]['price'].toString() : products[index]['name'],
      keyboardType: isPrice ? TextInputType.number : TextInputType.text,
    );
    if (result == null) return;
    setState(() {
      if (isPrice) {
        products[index]['price'] = int.tryParse(result) ?? products[index]['price'];
      } else {
        products[index]['name'] = result;
      }
      _saveData();
    });
  }
  Future<void> _confirmDeleteHistory(int orderIndex) async {
    final int orderNo = _orderHistory.length - orderIndex;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('No.$orderNoを消去しますか？', style: const TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('いいえ', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
              ),
              child: const Text('はい', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      _deleteHistory(orderIndex);
    }
  }
  void _deleteHistory(int index) {
    setState(() {
      final order = _orderHistory[index];
      for (var item in order['items']) { products[item['productIndex']]['stock'] += item['qty']; }
      _orderHistory.removeAt(index);
      _saveData();
    });
  }
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Colors.white,
        appBar: AppBar(
          toolbarHeight: 50, elevation: 0,
          backgroundColor: _isEditMode ? Colors.orange.shade800 : Colors.indigo.shade800,
          foregroundColor: Colors.white,
          title: Text(_isEditMode ? '設定モード' : 'レジ管理', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          bottom: const TabBar(
            indicatorColor: Colors.white, labelColor: Colors.white, unselectedLabelColor: Colors.white70,
            tabs: [Tab(text: "レジ"), Tab(text: "履歴")],
          ),
          actions: [
            Row(children: [
              const Text("設定", style: TextStyle(fontSize: 12)),
              Switch(value: _isEditMode, onChanged: (val) => setState(() => _isEditMode = val), activeColor: Colors.white, activeTrackColor: Colors.orange.shade400),
            ]),
            const SizedBox(width: 10),
          ],
        ),
        body: TabBarView(children: [_buildSalesView(), _buildHistoryView()]),
        bottomNavigationBar: _isEditMode || _cart.isEmpty ? null : _buildCheckoutPanel(),
      ),
    );
  }
  Widget _buildSalesView() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final p = products[index];
        final cartQty = _cart[index] ?? 0;
        final colorIdx = index % itemColors.length;
        final bool isSoldOut = p['stock'] <= 0;
        final bool isSalesMode = !_isEditMode;
        return Opacity(
          opacity: isSalesMode && isSoldOut ? 0.4 : 1.0,
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: isSoldOut ? Colors.grey.shade200 : itemColors[colorIdx],
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              title: GestureDetector(
                onTap: _isEditMode ? () => _editDetail(index, false) : null,
                child: Text(
                  p['name'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    decoration: _isEditMode ? TextDecoration.underline : null,
                  ),
                ),
              ),
              subtitle: GestureDetector(
                onTap: _isEditMode ? () => _editDetail(index, true) : null,
                child: Text(
                  "¥${p['price']} (在庫:${p['stock']})",
                  style: TextStyle(
                    fontSize: 12,
                    decoration: _isEditMode ? TextDecoration.underline : null,
                    color: isSalesMode && isSoldOut ? Colors.grey : Colors.black87,
                  ),
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextRoundButton(
                    '-',
                    isSalesMode && isSoldOut
                        ? null
                        : () => _isEditMode
                            ? setState(() {
                                products[index]['stock']--;
                                _saveData();
                              })
                            : _updateCart(index, -1),
                    color: Colors.red,
                  ),
                  GestureDetector(
                    onTap: _isEditMode ? () => _editStockDirectly(index) : null,
                    child: SizedBox(
                      width: 60,
                      child: Center(
                        child: isSalesMode && isSoldOut
                            ? const Text(
                                "SOLD OUT",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.redAccent,
                                ),
                              )
                            : Text(
                                "${_isEditMode ? p['stock'] : cartQty}",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                  _buildTextRoundButton(
                    '+',
                    isSalesMode && isSoldOut
                        ? null
                        : () => _isEditMode
                            ? setState(() {
                                products[index]['stock']++;
                                _saveData();
                              })
                            : _updateCart(index, 1),
                    color: accentColors[colorIdx],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  Widget _buildHistoryView() {
    return Column(
      children: [
        Container(width: double.infinity, padding: const EdgeInsets.all(12), color: Colors.indigo.shade50.withOpacity(0.5), child: Text("本日の総売上: ¥$totalSales", style: const TextStyle(fontWeight: FontWeight.bold))),
        Expanded(
          child: _orderHistory.isEmpty 
            ? const Center(child: Text("履歴はありません"))
            : ListView.builder(
                padding: const EdgeInsets.all(10),
                itemCount: _orderHistory.length,
                itemBuilder: (context, orderIndex) {
                  final order = _orderHistory[orderIndex];
                  int orderNo = _orderHistory.length - orderIndex;
                  return Card(
                    elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey.shade100)),
                    child: ExpansionTile(
                      leading: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(6)),
                        child: Text("No.$orderNo", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo)),
                      ),
                      title: Text("${order['time']} 会計 - ¥${order['totalPrice']}", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      trailing: _isEditMode
                          ? TextButton(
                              onPressed: () => _confirmDeleteHistory(orderIndex),
                              child: const Text(
                                '消去',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            )
                          : const Text(
                              '詳細',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo,
                              ),
                            ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildDetailSummary("お預かり", "¥${order['received'] ?? '-'}"),
                                    _buildDetailSummary("お釣り", "¥${order['change'] ?? '-'}", color: Colors.indigo.shade900),
                                  ],
                                ),
                              ),
                              const Text("販売商品", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: (order['items'] as List).asMap().entries.map((entry) {
                                  int itemIndex = entry.key;
                                  var item = entry.value;
                                  int productIdx = item['productIndex'];
                                  final color = accentColors[productIdx % accentColors.length];
                                  
                                  return InkWell(
                                    onTap: _isEditMode ? () => _editHistoryItemQty(orderIndex, itemIndex) : null,
                                    child: _buildProductChip(item['name'], item['qty'], color, showEditIcon: _isEditMode),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
        ),
      ],
    );
  }
  Widget _buildDetailSummary(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
  Widget _buildCheckoutPanel() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade100))),
      padding: const EdgeInsets.fromLTRB(15, 10, 15, 25),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _cart.entries.map((e) {
              final color = accentColors[e.key % accentColors.length];
              return _buildProductChip(products[e.key]['name'], e.value, color);
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text("合計: ¥$cartTotal", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red)),
              const Spacer(),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: _clearCart,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        "クリア",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _showPaymentDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade800,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                ),
                child: const Text("会計する", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildProductChip(String name, int qty, Color color, {bool showEditIcon = false, bool isLarge = false}) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        isLarge ? 8 : 10, // 確認画面では左右も詰める
        isLarge ? 4 : 4, 
        isLarge ? 4 : 4, 
        isLarge ? 4 : 4
      ),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name, 
            style: TextStyle(
              color: Colors.white, 
              fontSize: isLarge ? 12 : 12, // 確認画面でもサイズを抑える
              fontWeight: FontWeight.bold
            )
          ),
          const SizedBox(width: 4),
          Container(
            width: isLarge ? 26 : 24, height: isLarge ? 26 : 24, // 円も少し小さく
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: Center(
              child: Text(
                "$qty", 
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: isLarge ? 14 : 13,
                  decoration: showEditIcon ? TextDecoration.underline : TextDecoration.none,
                  decorationStyle: TextDecorationStyle.dotted,
                  decorationColor: color,
                )
              )
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildTextRoundButton(String label, VoidCallback? onPressed, {required Color color}) {
    final bool enabled = onPressed != null;
    return InkWell(
      onTap: enabled ? onPressed : null,
      borderRadius: BorderRadius.circular(20), 
      child: Container(
        width: 36, height: 36, 
        decoration: BoxDecoration(
          color: enabled ? color.withOpacity(0.1) : Colors.grey.withOpacity(0.15),
          shape: BoxShape.circle,
        ), 
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: enabled ? color : Colors.grey,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      )
    );
  }
  Future<String?> _showTextInputPage({
    required String title,
    required String initialValue,
    required TextInputType keyboardType,
  }) async {
    final controller = TextEditingController(text: initialValue);
    return Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (pageContext) => Scaffold(
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
            title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            automaticallyImplyLeading: false,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(pageContext).viewInsets.bottom + 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: controller,
                    keyboardType: keyboardType,
                    autofocus: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(pageContext),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade400),
                            backgroundColor: Colors.grey.shade100,
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'キャンセル',
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(pageContext, controller.text),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade700,
                            foregroundColor: Colors.white,
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            '保存',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
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
