import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baithi/main.dart';
import 'package:baithi/models/order.dart';

void main() {
  group('Order Model Tests', () {
    test('1. Create class Order and JSON serialization', () {
      final order = Order(
        item: 'A1000',
        itemName: 'Iphone 15',
        price: 1200,
        currency: 'USD',
        quantity: 1,
      );

      expect(order.item, 'A1000');
      expect(order.itemName, 'Iphone 15');
      expect(order.price, 1200.0);
      expect(order.currency, 'USD');
      expect(order.quantity, 1);

      final json = order.toJson();
      expect(json['Item'], 'A1000');
      expect(json['ItemName'], 'Iphone 15');
      expect(json['Price'], 1200);
      expect(json['Currency'], 'USD');
      expect(json['Quantity'], 1);

      final fromJson = Order.fromJson(json);
      expect(fromJson.item, order.item);
      expect(fromJson.itemName, order.itemName);
    });

    test('2. Read string and save objects to list orders', () {
      const jsonString =
          '[{"Item": "A1000","ItemName": "Iphone 15","Price": 1200,"Currency": "USD","Quantity":1},'
          '{"Item": "A1001","ItemName": "Iphone 16","Price": 1500,"Currency": "USD","Quantity":1}]';

      final orders = Order.fromJsonList(jsonString);
      expect(orders.length, 2);
      expect(orders[0].item, 'A1000');
      expect(orders[0].itemName, 'Iphone 15');
      expect(orders[1].item, 'A1001');
      expect(orders[1].itemName, 'Iphone 16');
    });

    test('3. Search order by ItemName', () {
      final orders = [
        Order(item: 'A1000', itemName: 'Iphone 15', price: 1200, currency: 'USD', quantity: 1),
        Order(item: 'A1001', itemName: 'Iphone 16', price: 1500, currency: 'USD', quantity: 1),
        Order(item: 'A1002', itemName: 'Samsung S24', price: 1100, currency: 'USD', quantity: 1),
      ];

      final searchResults = orders
          .where((o) => o.itemName.toLowerCase().contains('iphone 16'.toLowerCase()))
          .toList();

      expect(searchResults.length, 1);
      expect(searchResults.first.item, 'A1001');
    });
  });

  group('Widget UI Tests', () {
    testWidgets('Renders My Order screen with initial items and UI elements', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Check title
      expect(find.text('My Order'), findsOneWidget);

      // Check table headers
      expect(find.text('Id'), findsOneWidget);
      expect(find.text('Item'), findsWidgets);
      expect(find.text('Item Name'), findsWidgets);
      expect(find.text('Quantity'), findsWidgets);
      expect(find.text('Price'), findsWidgets);
      expect(find.text('Currency'), findsWidgets);

      // Check Add Item button
      expect(find.text('Add Item to Cart'), findsOneWidget);

      // Check initial sample orders rendered
      expect(find.text('A1000'), findsOneWidget);
      expect(find.text('A1001'), findsOneWidget);
    });

    testWidgets('Search Order by ItemName dynamically filters list', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      final searchField = find.widgetWithText(TextField, 'Search Order by ItemName...');
      expect(searchField, findsOneWidget);

      // Enter search query
      await tester.enterText(searchField, 'Iphone 16');
      await tester.pumpAndSettle();

      // Only Iphone 16 should be visible
      expect(find.text('A1001'), findsOneWidget);
      expect(find.text('A1000'), findsNothing);

      // Clear search
      await tester.enterText(searchField, '');
      await tester.pumpAndSettle();

      expect(find.text('A1000'), findsOneWidget);
      expect(find.text('A1001'), findsOneWidget);
    });
  });
}
