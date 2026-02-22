import 'package:equatable/equatable.dart';
import 'category.dart';

class Transaction extends Equatable {
  final String id;
  final double amount;
  final String note;
  final DateTime date;
  final String categoryId;
  final String walletId;
  final TransactionType type;
  final String? invoiceNumber;

  const Transaction({
    required this.id,
    required this.amount,
    required this.note,
    required this.date,
    required this.categoryId,
    required this.walletId,
    required this.type,
    this.invoiceNumber,
  });

  Transaction copyWith({
    String? id,
    double? amount,
    String? note,
    DateTime? date,
    String? categoryId,
    String? walletId,
    TransactionType? type,
    String? invoiceNumber,
  }) {
    return Transaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      date: date ?? this.date,
      categoryId: categoryId ?? this.categoryId,
      walletId: walletId ?? this.walletId,
      type: type ?? this.type,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'note': note,
      'date': date.millisecondsSinceEpoch,
      'categoryId': categoryId,
      'walletId': walletId,
      'type': type.index,
      'invoiceNumber': invoiceNumber,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as String,
      amount: map['amount'] as double,
      note: map['note'] as String,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      categoryId: map['categoryId'] as String,
      walletId: map['walletId'] as String,
      type: TransactionType.values[map['type'] as int],
      invoiceNumber: map['invoiceNumber'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, amount, note, date, categoryId, walletId, type, invoiceNumber];
}
