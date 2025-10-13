// lib/models.dart

class MenuItem {
  final int id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final bool isAvailable;
  final bool isVegan; // <-- ADD THIS
  final bool isVegetarian; // <-- NEW: explicitly vegetarian (non-vegan)
  final bool isGlutenFree; // <-- ADD THIS
  final bool containsNuts; // <-- ADD THIS
  final int? categoryId; // <-- ADD THIS
  final bool isBestseller;
  final bool isChefSpecial;
  final bool isSeasonal;

  MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.isAvailable,
    required this.isVegan, // <-- ADD THIS
    this.isVegetarian = false,
    required this.isGlutenFree, // <-- ADD THIS
    required this.containsNuts, // <-- ADD THIS
    this.categoryId, // <-- ADD THIS
    this.isBestseller = false,
    this.isChefSpecial = false,
    this.isSeasonal = false,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'] ?? -1,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: (json['price'] is num)
          ? (json['price'] as num).toDouble()
          : double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      imageUrl: json['image_url']?.toString() ?? '',
      isAvailable: json['is_available'] ?? true,
      isVegan: json['is_vegan'] ?? false, // <-- ADD THIS
      isVegetarian: (json['is_veg'] ?? json['is_vegetarian']) ?? false,
      isGlutenFree: json['is_gluten_free'] ?? false, // <-- ADD THIS
      containsNuts: json['contains_nuts'] ?? false, // <-- ADD THIS
      categoryId: json['category_id'] as int?, // <-- ADD THIS
      isBestseller: json['is_bestseller'] ?? false,
      isChefSpecial: (json['is_chef_spl'] ?? json['is_chef_special']) ?? false,
      isSeasonal: json['is_seasonal'] ?? false,
    );
  }
}

class MenuCategory {
  final int id;
  final String name;
  final List<MenuItem> items;

  MenuCategory({required this.id, required this.name, required this.items});

  factory MenuCategory.fromJson(Map<String, dynamic> json) {
    var itemsList = (json['items'] as List?) ?? const [];
    List<MenuItem> menuItems =
        itemsList.map((i) => MenuItem.fromJson(i)).toList();

    return MenuCategory(
      id: (json['category_id'] as int?) ?? (json['id'] as int?) ?? -1,
      name: (json['category_name'] ?? json['name'] ?? '').toString(),
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
  final String? userId;

  Order({
    required this.id,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    required this.deliveryAddress,
    this.userId,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      totalAmount: (json['total_amount'] as num).toDouble(),
      status: json['status'] ?? 'Unknown',
      createdAt: DateTime.parse(json['created_at']),
      deliveryAddress:
          json['delivery_address'] ?? json['address'] ?? 'No address provided',
      userId: json['user_id'],
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

// New model for saved addresses in user profile
class SavedAddress {
  final String id;
  final String userId;
  final String houseNo;
  final String area;
  final String city;
  final String state;
  final String pincode;
  final String? contactName;
  final String? contactPhone;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  SavedAddress({
    required this.id,
    required this.userId,
    required this.houseNo,
    required this.area,
    required this.city,
    required this.state,
    required this.pincode,
    this.contactName,
    this.contactPhone,
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SavedAddress.fromJson(Map<String, dynamic> json) {
    return SavedAddress(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      houseNo: json['house_no'] ?? '',
      area: json['area'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode'] ?? '',
      contactName: json['contact_name'],
      contactPhone: json['contact_phone'],
      isDefault: json['is_default'] ?? false,
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(
          json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'house_no': houseNo,
      'area': area,
      'city': city,
      'state': state,
      'pincode': pincode,
      'contact_name': contactName,
      'contact_phone': contactPhone,
      'is_default': isDefault,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Convert to AddressDetails for compatibility
  AddressDetails toAddressDetails() {
    return AddressDetails(
      houseNo: houseNo,
      area: area,
      city: city,
      state: state,
      pincode: pincode,
    );
  }

  // Create from AddressDetails
  factory SavedAddress.fromAddressDetails({
    required String id,
    required String userId,
    required AddressDetails address,
    String? contactName,
    String? contactPhone,
    bool isDefault = false,
  }) {
    final now = DateTime.now();
    return SavedAddress(
      id: id,
      userId: userId,
      houseNo: address.houseNo,
      area: address.area,
      city: address.city,
      state: address.state,
      pincode: address.pincode,
      contactName: contactName,
      contactPhone: contactPhone,
      isDefault: isDefault,
      createdAt: now,
      updatedAt: now,
    );
  }

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
  final Table table; // The nested table object

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
      table: Table.fromJson(
        json['tables'],
      ), // Supabase uses the table name as the key
    );
  }
}
