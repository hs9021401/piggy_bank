import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/database_service.dart';
import 'wallet_event.dart';
import 'wallet_state.dart';

class WalletBloc extends Bloc<WalletEvent, WalletState> {
  final DatabaseService _databaseService;

  WalletBloc(this._databaseService) : super(WalletInitial()) {
    on<LoadWallets>(_onLoadWallets);
    on<AddWallet>(_onAddWallet);
    on<UpdateWallet>(_onUpdateWallet);
    on<DeleteWallet>(_onDeleteWallet);
    on<SelectWallet>(_onSelectWallet);
  }

  Future<void> _onLoadWallets(
    LoadWallets event,
    Emitter<WalletState> emit,
  ) async {
    emit(WalletLoading());
    try {
      final wallets = await _databaseService.getWallets();
      final totalBalance = await _databaseService.getTotalBalance();
      emit(WalletLoaded(
        wallets: wallets,
        selectedWalletId: wallets.isNotEmpty ? wallets.first.id : null,
        totalBalance: totalBalance,
      ));
    } catch (e) {
      emit(WalletError(e.toString()));
    }
  }

  Future<void> _onAddWallet(
    AddWallet event,
    Emitter<WalletState> emit,
  ) async {
    try {
      await _databaseService.insertWallet(event.wallet);
      add(LoadWallets());
    } catch (e) {
      emit(WalletError(e.toString()));
    }
  }

  Future<void> _onUpdateWallet(
    UpdateWallet event,
    Emitter<WalletState> emit,
  ) async {
    try {
      await _databaseService.updateWallet(event.wallet);
      add(LoadWallets());
    } catch (e) {
      emit(WalletError(e.toString()));
    }
  }

  Future<void> _onDeleteWallet(
    DeleteWallet event,
    Emitter<WalletState> emit,
  ) async {
    try {
      await _databaseService.deleteWallet(event.id);
      add(LoadWallets());
    } catch (e) {
      emit(WalletError(e.toString()));
    }
  }

  Future<void> _onSelectWallet(
    SelectWallet event,
    Emitter<WalletState> emit,
  ) async {
    if (state is WalletLoaded) {
      final currentState = state as WalletLoaded;
      emit(currentState.copyWith(selectedWalletId: event.walletId));
    }
  }
}
