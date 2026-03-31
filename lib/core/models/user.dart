import 'package:json_annotation/json_annotation.dart';


class User {
  final String id;
  final String phone;
  final String name;
  final String? photoUrl;
  final PaymentMethod preferredPayment;
  final Language lang;
  final String? fcmToken;
  final UserStatus status;
  final DateTime? createdAt;
  final DateTime? lastSeenAt;

  const User({
    required this.id,
    required this.phone,
    required this.name,
    this.photoUrl,
    required this.preferredPayment,
    required this.lang,
    this.fcmToken,
    required this.status,
    this.createdAt,
    this.lastSeenAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      phone: json['phone'] as String,
      name: json['name'] as String,
      photoUrl: json['photoUrl'] as String?,
      preferredPayment: PaymentMethod.values.firstWhere(
        (e) => e.name == json['preferredPayment'],
        orElse: () => PaymentMethod.wave,
      ),
      lang: Language.values.firstWhere(
        (e) => e.name == json['lang'],
        orElse: () => Language.fr,
      ),
      fcmToken: json['fcmToken'] as String?,
      status: UserStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => UserStatus.active,
      ),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      lastSeenAt: json['lastSeenAt'] != null
          ? DateTime.parse(json['lastSeenAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'name': name,
      'photoUrl': photoUrl,
      'preferredPayment': preferredPayment.name,
      'lang': lang.name,
      'fcmToken': fcmToken,
      'status': status.name,
      'createdAt': createdAt?.toIso8601String(),
      'lastSeenAt': lastSeenAt?.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? phone,
    String? name,
    String? photoUrl,
    PaymentMethod? preferredPayment,
    Language? lang,
    String? fcmToken,
    UserStatus? status,
    DateTime? createdAt,
    DateTime? lastSeenAt,
  }) {
    return User(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      preferredPayment: preferredPayment ?? this.preferredPayment,
      lang: lang ?? this.lang,
      fcmToken: fcmToken ?? this.fcmToken,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    );
  }
}

enum PaymentMethod {
  @JsonValue('wave')
  wave,
  @JsonValue('orange_money')
  orangeMoney,
}

enum Language {
  @JsonValue('fr')
  fr,
  @JsonValue('wo')
  wo,
}

enum UserStatus {
  @JsonValue('active')
  active,
  @JsonValue('suspended')
  suspended,
}
