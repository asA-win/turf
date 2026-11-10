import 'package:flutter_riverpod/flutter_riverpod.dart';

class WalletTransaction {
  final String title;
  final String date;
  final String amount;
  final bool isCredit;

  const WalletTransaction({
    required this.title,
    required this.date,
    required this.amount,
    required this.isCredit,
  });
}

class WalletState {
  final double balance;
  final int coins;
  final int gems;
  final List<WalletTransaction> transactions;

  const WalletState({
    this.balance = 0.0,
    this.coins = 50,
    this.gems = 10,
    this.transactions = const [],
  });

  WalletState copyWith({
    double? balance,
    int? coins,
    int? gems,
    List<WalletTransaction>? transactions,
  }) {
    return WalletState(
      balance: balance ?? this.balance,
      coins: coins ?? this.coins,
      gems: gems ?? this.gems,
      transactions: transactions ?? this.transactions,
    );
  }
}

class WalletNotifier extends StateNotifier<WalletState> {
  WalletNotifier() : super(const WalletState());

  void topUp(double amount) {
    final newTx = WalletTransaction(
      title: 'Wallet Top-Up (UPI)',
      date: 'Just now',
      amount: '+₹${amount.toInt()}',
      isCredit: true,
    );
    state = state.copyWith(
      balance: state.balance + amount,
      coins: state.coins + (amount * 0.1).toInt(),
      transactions: [newTx, ...state.transactions],
    );
  }

  void deduct(double amount, String reason) {
    final newTx = WalletTransaction(
      title: reason,
      date: 'Just now',
      amount: '-₹${amount.toInt()}',
      isCredit: false,
    );
    state = state.copyWith(
      balance: (state.balance - amount).clamp(0.0, double.infinity),
      transactions: [newTx, ...state.transactions],
    );
  }
}

final walletProvider = StateNotifierProvider<WalletNotifier, WalletState>((ref) {
  return WalletNotifier();
});
