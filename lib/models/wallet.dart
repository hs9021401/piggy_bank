import 'package:equatable/equatable.dart';

enum WalletType { cash, bank, creditCard, digital }

class Wallet extends Equatable {
  final String id;
  final String name;
  final double balance;
  final int color;
  final WalletType type;

  const Wallet({
    required this.id,
    required this.name,
    required this.balance,
    required this.color,
    required this.type,
  });

  Wallet copyWith({
    String? id,
    String? name,
    double? balance,
    int? color,
    WalletType? type,
  }) {
    return Wallet(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      color: color ?? this.color,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'balance': balance,
      'color': color,
      'type': type.index,
    };
  }

  factory Wallet.fromMap(Map<String, dynamic> map) {
    return Wallet(
      id: map['id'] as String,
      name: map['name'] as String,
      balance: map['balance'] as double,
      color: map['color'] as int,
      type: WalletType.values[map['type'] as int],
    );
  }

  @override
  List<Object?> get props => [id, name, balance, color, type];
}
