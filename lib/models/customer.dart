import 'json_helpers.dart';

class LoyaltyCard {
  final String number;
  final String level;
  final int points;
  final DateTime issuedAt;

  const LoyaltyCard({
    required this.number,
    required this.level,
    required this.points,
    required this.issuedAt,
  });

  LoyaltyCard copyWith({
    String? number,
    String? level,
    int? points,
    DateTime? issuedAt,
  }) {
    return LoyaltyCard(
      number: number ?? this.number,
      level: level ?? this.level,
      points: points ?? this.points,
      issuedAt: issuedAt ?? this.issuedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'level': level,
      'points': points,
      'issuedAt': issuedAt.toIso8601String(),
    };
  }

  factory LoyaltyCard.fromJson(
    Map<String, dynamic> json,
  ) {
    return LoyaltyCard(
      number: jsonString(json, 'number'),
      level: jsonString(
        json,
        'level',
        fallback: 'Silver',
      ),
      points: jsonInt(json, 'points'),
      issuedAt: jsonDate(json, 'issuedAt') ?? DateTime.now(),
    );
  }
}

class Customer {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;

  final LoyaltyCard loyaltyCard;

  final DateTime? deletedAt;

  const Customer({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.loyaltyCard,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  String get fullName => '$lastName $firstName';

  Customer copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    LoyaltyCard? loyaltyCard,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Customer(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      loyaltyCard: loyaltyCard ?? this.loyaltyCard,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'loyaltyCard': loyaltyCard.toJson(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  factory Customer.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawCard = json['loyaltyCard'];

    final cardMap = rawCard is Map
        ? Map<String, dynamic>.from(
            rawCard,
          )
        : <String, dynamic>{};

    return Customer(
      id: jsonInt(json, 'id'),
      firstName: jsonString(json, 'firstName'),
      lastName: jsonString(json, 'lastName'),
      email: jsonString(json, 'email'),
      phone: jsonString(json, 'phone'),
      loyaltyCard: LoyaltyCard.fromJson(cardMap),
      deletedAt: jsonDate(json, 'deletedAt'),
    );
  }
}
