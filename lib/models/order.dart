import 'dart:convert';

class Order {
  String item;
  String itemName;
  double price;
  String currency;
  int quantity;

  Order({
    required this.item,
    required this.itemName,
    required this.price,
    required this.currency,
    required this.quantity,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      item: (json['Item'] ?? json['item'] ?? '').toString(),
      itemName: (json['ItemName'] ?? json['itemName'] ?? '').toString(),
      price: double.tryParse((json['Price'] ?? json['price'] ?? 0).toString()) ?? 0.0,
      currency: (json['Currency'] ?? json['currency'] ?? 'USD').toString(),
      quantity: int.tryParse((json['Quantity'] ?? json['quantity'] ?? 1).toString()) ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Item': item,
      'ItemName': itemName,
      'Price': price % 1 == 0 ? price.toInt() : price,
      'Currency': currency,
      'Quantity': quantity,
    };
  }

  static List<Order> fromJsonList(String jsonString) {
    final dynamic decoded = jsonDecode(jsonString);
    if (decoded is List) {
      return decoded.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  static String toJsonListString(List<Order> orders) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(orders.map((o) => o.toJson()).toList());
  }

  @override
  String toString() {
    return 'Order(item: $item, itemName: $itemName, price: $price, currency: $currency, quantity: $quantity)';
  }
}
