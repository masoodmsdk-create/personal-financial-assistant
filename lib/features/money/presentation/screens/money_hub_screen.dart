import 'package:flutter/material.dart';
import 'package:personal_financial_assistant/features/accounts/presentation/screens/accounts_screen.dart';
import 'package:personal_financial_assistant/features/recurring_transactions/presentation/screens/recurring_transactions_screen.dart';
import 'package:personal_financial_assistant/features/transactions/presentation/screens/transactions_screen.dart';

class MoneyHubScreen extends StatefulWidget {
  final int initialTabIndex;
  const MoneyHubScreen({super.key, this.initialTabIndex = 0});

  @override
  State<MoneyHubScreen> createState() => _MoneyHubScreenState();
}

class _MoneyHubScreenState extends State<MoneyHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 2),
    );
  }

  @override
  void didUpdateWidget(covariant MoneyHubScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTabIndex != oldWidget.initialTabIndex) {
      _tabController.animateTo(widget.initialTabIndex.clamp(0, 2));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          color: colorScheme.surface,
          child: TabBar(
            controller: _tabController,
            isScrollable: false,
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: colorScheme.primary,
            unselectedLabelColor: colorScheme.onSurfaceVariant,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 13,
            ),
            tabs: const [
              Tab(
                icon: Icon(Icons.account_balance_wallet_outlined, size: 18),
                text: 'Accounts',
              ),
              Tab(
                icon: Icon(Icons.receipt_long_outlined, size: 18),
                text: 'Transactions',
              ),
              Tab(
                icon: Icon(Icons.repeat_rounded, size: 18),
                text: 'Recurring Rules',
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          AccountsScreen(),
          TransactionsScreen(),
          RecurringTransactionsScreen(),
        ],
      ),
    );
  }
}
