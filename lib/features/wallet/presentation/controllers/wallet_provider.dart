import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turf_app/core/providers/api_client.dart';

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
  final Ref ref;

  WalletNotifier(this.ref) : super(const WalletState()) {
    loadWallet();
  }

  Future<void> loadWallet() async {
    try {
      final dio = ref.read(dioClientProvider);
      final walletResp = await dio.get('/users/wallet');
      final txResp = await dio.get('/users/wallet/transactions');

      final balance = (walletResp.data['balance'] as num?)?.toDouble() ?? 0.0;
      final coins = (walletResp.data['coins'] as num?)?.toInt() ?? 50;

      final txList = (txResp.data as List? ?? []).map((t) {
        final amountVal = (t['amount'] as num?)?.toDouble() ?? 0.0;
        final isCredit = t['transaction_type'] == 'credit';
        final title = t['title']?.toString() ?? (isCredit ? 'Wallet Top-Up' : 'Wallet Payment');
        final createdAtStr = t['created_at']?.toString() ?? '';
        return WalletTransaction(
          title: title,
          date: createdAtStr.isNotEmpty ? createdAtStr.split('T').first : 'Recent',
          amount: '${isCredit ? "+" : "-"}₹${amountVal.toInt()}',
          isCredit: isCredit,
        );
      }).toList();

      state = state.copyWith(
        balance: balance,
        coins: coins,
        transactions: txList,
      );
    } catch (e) {
      debugPrint('[LOAD WALLET ERROR] $e');
    }
  }

  void updateFromRealtime(double balance, int? coins) {
    state = state.copyWith(
      balance: balance,
      coins: coins ?? state.coins,
    );
  }

  Future<void> topUp(double amount) async {
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

    try {
      final dio = ref.read(dioClientProvider);
      final response = await dio.post('/users/wallet/add-money?amount=$amount');
      final newBalance = (response.data['balance'] as num?)?.toDouble();
      final newCoins = (response.data['coins'] as num?)?.toInt();
      if (newBalance != null) {
        state = state.copyWith(balance: newBalance, coins: newCoins ?? state.coins);
      }
    } catch (e) {
      debugPrint('[TOPUP WALLET ERROR] $e');
    }
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
  return WalletNotifier(ref);
});
