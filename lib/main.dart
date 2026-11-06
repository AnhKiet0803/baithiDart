import 'package:flutter/material.dart';
import 'models/order.dart';
import 'services/storage_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Order',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFC05035),
          primary: const Color(0xFFC05035),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFAFAFA),
        inputDecorationTheme: InputDecorationTheme(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(6)),
            borderSide: BorderSide(color: Color(0xFFC05035), width: 1.5),
          ),
        ),
      ),
      home: const OrderScreen(),
    );
  }
}

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  static const String initialJsonString =
      '[{"Item": "A1000","ItemName": "Iphone 15","Price": 1200,"Currency": "USD","Quantity":1},'
      '{"Item": "A1001","ItemName": "Iphone 16","Price": 1500,"Currency": "USD","Quantity":1}]';

  final StorageService _storageService = createStorageService();

  List<Order> _orders = Order.fromJsonList(initialJsonString);
  String _searchQuery = '';
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _currencyController = TextEditingController(text: 'USD');
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInitialOrders();
  }

  @override
  void dispose() {
    _itemController.dispose();
    _itemNameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _currencyController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialOrders() async {
    try {
      final savedData = await _storageService.loadOrderJson();
      if (savedData != null && savedData.trim().isNotEmpty) {
        final loaded = Order.fromJsonList(savedData);
        if (loaded.isNotEmpty && mounted) {
          setState(() {
            _orders = loaded;
          });
        }
      } else {
        await _saveOrdersToJsonFile();
      }
    } catch (_) {}
  }

  Future<void> _saveOrdersToJsonFile() async {
    final jsonString = Order.toJsonListString(_orders);
    await _storageService.saveOrderJson(jsonString);
  }

  void _addOrder() async {
    if (_formKey.currentState!.validate()) {
      final item = _itemController.text.trim();
      final itemName = _itemNameController.text.trim();
      final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
      final quantity = int.tryParse(_quantityController.text.trim()) ?? 1;
      final currency = _currencyController.text.trim().isEmpty
          ? 'USD'
          : _currencyController.text.trim();

      final newOrder = Order(
        item: item,
        itemName: itemName,
        price: price,
        currency: currency,
        quantity: quantity,
      );

      setState(() {
        _orders.add(newOrder);
      });

      await _saveOrdersToJsonFile();

      _itemController.clear();
      _itemNameController.clear();
      _priceController.clear();
      _quantityController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order "$itemName" added and saved to order.json!'),
            backgroundColor: const Color(0xFFC05035),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _deleteOrder(int originalIndex) async {
    final removed = _orders[originalIndex];
    setState(() {
      _orders.removeAt(originalIndex);
    });
    await _saveOrdersToJsonFile();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed "${removed.itemName}" from orders'),
          backgroundColor: Colors.grey.shade800,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Undo',
            textColor: const Color(0xFFE28723),
            onPressed: () async {
              setState(() {
                _orders.insert(originalIndex, removed);
              });
              await _saveOrdersToJsonFile();
            },
          ),
        ),
      );
    }
  }

  String _formatPrice(double price) {
    if (price == price.roundToDouble()) {
      final str = price.toInt().toString();
      final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
      return str.replaceAllMapped(reg, (Match m) => '${m[1]}.');
    } else {
      return price.toStringAsFixed(2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredOrdersWithIndex = <MapEntry<int, Order>>[];
    for (int i = 0; i < _orders.length; i++) {
      if (_searchQuery.isEmpty ||
          _orders[i].itemName.toLowerCase().contains(_searchQuery.toLowerCase())) {
        filteredOrdersWithIndex.add(MapEntry(i, _orders[i]));
      }
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'My Order',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFE28723),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 28),

                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 1,
                              child: _buildFormField(
                                label: 'Item',
                                hint: 'Item',
                                controller: _itemController,
                                validator: (val) =>
                                    (val == null || val.trim().isEmpty) ? 'Required' : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: _buildFormField(
                                label: 'Item Name',
                                hint: 'Item',
                                controller: _itemNameController,
                                validator: (val) =>
                                    (val == null || val.trim().isEmpty) ? 'Required' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildFormField(
                                label: 'Price',
                                hint: 'Price',
                                controller: _priceController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) return 'Required';
                                  if (double.tryParse(val.trim()) == null) return 'Invalid';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildFormField(
                                label: 'Quantity',
                                hint: 'Quantity',
                                controller: _quantityController,
                                keyboardType: TextInputType.number,
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) return 'Required';
                                  if (int.tryParse(val.trim()) == null) return 'Invalid';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildFormField(
                                label: 'Currency',
                                hint: 'USD',
                                controller: _currencyController,
                                validator: (val) =>
                                    (val == null || val.trim().isEmpty) ? 'Required' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: _addOrder,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFC05035),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                            ),
                            child: const Text(
                              'Add Item to Cart',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val.trim();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search Order by ItemName...',
                        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                        prefixIcon: const Icon(Icons.search, color: Color(0xFFC05035), size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        Container(
                          color: const Color(0xFFC05035),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: const Row(
                            children: [
                              SizedBox(
                                width: 40,
                                child: Text(
                                  'Id',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Item',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'Item Name',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Quantity',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Price',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Currency',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              SizedBox(width: 40),
                            ],
                          ),
                        ),

                        if (filteredOrdersWithIndex.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 36),
                            child: Text(
                              _searchQuery.isEmpty
                                  ? 'No orders in cart.'
                                  : 'No orders found matching "$_searchQuery".',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredOrdersWithIndex.length,
                            separatorBuilder: (context, index) => Divider(
                              height: 1,
                              thickness: 1,
                              color: Colors.grey.shade100,
                            ),
                            itemBuilder: (context, displayIndex) {
                              final entry = filteredOrdersWithIndex[displayIndex];
                              final originalIndex = entry.key;
                              final order = entry.value;

                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 40,
                                      child: Text(
                                        '${displayIndex + 1}',
                                        style: TextStyle(
                                          color: Colors.grey.shade800,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    // Item
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        order.item,
                                        style: TextStyle(
                                          color: Colors.grey.shade800,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    // Item Name
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        order.itemName,
                                        style: TextStyle(
                                          color: Colors.grey.shade800,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    // Quantity
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        '${order.quantity}',
                                        style: TextStyle(
                                          color: Colors.grey.shade800,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        _formatPrice(order.price),
                                        style: TextStyle(
                                          color: Colors.grey.shade800,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    // Currency
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        order.currency,
                                        style: TextStyle(
                                          color: Colors.grey.shade800,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    // Delete Action Button
                                    SizedBox(
                                      width: 40,
                                      child: IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        icon: const Icon(
                                          Icons.delete_outline_rounded,
                                          color: Color(0xFF8FA3B8),
                                          size: 20,
                                        ),
                                        tooltip: 'Delete order',
                                        onPressed: () => _deleteOrder(originalIndex),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Current order.json'),
                              content: SingleChildScrollView(
                                child: SelectableText(
                                  Order.toJsonListString(_orders),
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Close'),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    _storageService.downloadOrExportJson(
                                      Order.toJsonListString(_orders),
                                      'order.json',
                                    );
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('order.json exported / saved!'),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.download, size: 16),
                                  label: const Text('Download order.json'),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.code, size: 16, color: Color(0xFFC05035)),
                        label: const Text(
                          '',
                          style: TextStyle(color: Color(0xFFC05035)),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          setState(() {
                            _orders = Order.fromJsonList(initialJsonString);
                          });
                          await _saveOrdersToJsonFile();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Reset to initial sample orders!'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.refresh, size: 16, color: Colors.grey),
                        label: const Text(
                          'Reset Initial Data',
                          style: TextStyle(color: Colors.grey),
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

  Widget _buildFormField({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
