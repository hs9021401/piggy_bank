import 'package:equatable/equatable.dart';
import '../../models/wallet.dart';

abstract class WalletState extends Equatable {
  const WalletState();

  @override
  List<Object?> get props => [];
}

class WalletInitial extends WalletState {}

class WalletLoading extends WalletState {}

class WalletLoaded extends WalletState {
  final List<Wallet> wallets;
  final String? selectedWalletId;
  final double totalBalance;

  const WalletLoaded({
    required this.wallets,
    this.selectedWalletId,
    required this.totalBalance,
  });

  Wallet? get selectedWallet {
    if (selectedWalletId == null) return null;
    try {
      return wallets.firstWhere((w) => w.id == selectedWalletId);
    } catch (_) {
      return null;
    }
  }

  WalletLoaded copyWith({
    List<Wallet>? wallets,
    String? selectedWalletId,
    double? totalBalance,
  }) {
    return WalletLoaded(
      wallets: wallets ?? this.wallets,
      selectedWalletId: selectedWalletId ?? this.selectedWalletId,
      totalBalance: totalBalance ?? this.totalBalance,
    );
  }

  @override
  List<Object?> get props => [wallets, selectedWalletId, totalBalance];
}

class WalletError extends WalletState {
  final String message;

  const WalletError(this.message);

  @override
  List<Object?> get props => [message];
}
