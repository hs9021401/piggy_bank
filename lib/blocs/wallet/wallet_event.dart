import 'package:equatable/equatable.dart';
import '../../models/wallet.dart';

abstract class WalletEvent extends Equatable {
  const WalletEvent();

  @override
  List<Object?> get props => [];
}

class LoadWallets extends WalletEvent {}

class AddWallet extends WalletEvent {
  final Wallet wallet;

  const AddWallet(this.wallet);

  @override
  List<Object?> get props => [wallet];
}

class UpdateWallet extends WalletEvent {
  final Wallet wallet;

  const UpdateWallet(this.wallet);

  @override
  List<Object?> get props => [wallet];
}

class DeleteWallet extends WalletEvent {
  final String id;

  const DeleteWallet(this.id);

  @override
  List<Object?> get props => [id];
}

class SelectWallet extends WalletEvent {
  final String? walletId;

  const SelectWallet(this.walletId);

  @override
  List<Object?> get props => [walletId];
}
