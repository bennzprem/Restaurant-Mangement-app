// lib/models.dart
import 'package:restaurant_app/models.dart' as app_models;

class MenuItem {
  final int id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final bool isAvailable;
  final bool isVegan; // <-- ADD THIS
  final bool isGlutenFree; // <-- ADD THIS
  final bool containsNuts; // <-- ADD THIS

  MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.isAvailable,
    required this.isVegan, // <-- ADD THIS
    required this.isGlutenFree, // <-- ADD THIS
    required this.containsNuts, // <-- ADD THIS
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: (json['price'] as num).toDouble(),
      imageUrl: json['image_url'],
      isAvailable: json['is_available'] ?? true,
      isVegan: json['is_vegan'] ?? false, // <-- ADD THIS
      isGlutenFree: json['is_gluten_free'] ?? false, // <-- ADD THIS
      containsNuts: json['contains_nuts'] ?? false, // <-- ADD THIS
    );
  }
}

class MenuCategory {
  final int id;
  final String name;
  final List<MenuItem> items;

  MenuCategory({required this.id, required this.name, required this.items});

  factory MenuCategory.fromJson(Map<String, dynamic> json) {
    var itemsList = json['items'] as List;
    List<MenuItem> menuItems = itemsList
        .map((i) => MenuItem.fromJson(i))
        .toList();

    return MenuCategory(
      id: json['category_id'],
      name: json['category_name'],
      items: menuItems,
    );
  }
}

class CartItem {
  final MenuItem menuItem;
  int quantity;

  CartItem({required this.menuItem, this.quantity = 1});
}

// At the bottom of lib/models.dart
class Order {
  final int id;
  final double totalAmount;
  final String status;
  final DateTime createdAt;
  final String deliveryAddress;

  Order({
    required this.id,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    required this.deliveryAddress,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      totalAmount: (json['total_amount'] as num).toDouble(),
      status: json['status'] ?? 'Unknown',
      createdAt: DateTime.parse(json['created_at']),
      deliveryAddress: json['delivery_address'] ?? 'No address provided',
    );
  }
}
// In lib/models.dart...

class AddressDetails {
  String houseNo;
  String area;
  String city;
  String state;
  String pincode;

  AddressDetails({
    this.houseNo = '',
    this.area = '',
    this.city = '',
    this.state = '',
    this.pincode = '',
  });

  // A helper to convert the details into a single string for saving
  @override
  String toString() {
    return '$houseNo, $area, $city, $state - $pincode';
  }
}

// Add this class to your models.dart file
class Table {
  final String id;
  final int tableNumber;
  final int capacity;
  final String? locationPreference;

  Table({
    required this.id,
    required this.tableNumber,
    required this.capacity,
    this.locationPreference,
  });

  factory Table.fromJson(Map<String, dynamic> json) {
    return Table(
      id: json['id'],
      tableNumber: json['table_number'],
      capacity: json['capacity'],
      locationPreference: json['location_preference'],
    );
  }
}

class Reservation {
  final String id;
  final DateTime reservationTime;
  final int partySize;
  final String status;
  final String specialOccasion;
  final bool addOnsRequested;
  final app_models.Table table; // The nested table object

  Reservation({
    required this.id,
    required this.reservationTime,
    required this.partySize,
    required this.status,
    required this.specialOccasion,
    required this.addOnsRequested,
    required this.table,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: json['id'],
      reservationTime: DateTime.parse(json['reservation_time']),
      partySize: json['party_size'],
      status: json['status'],
      specialOccasion: json['special_occasion'] ?? 'None',
      addOnsRequested: json['add_ons_requested'] ?? false,
      table: app_models.Table.fromJson(
        json['tables'],
      ), // Supabase uses the table name as the key
    );
  }
}
