import 'package:flutter/material.dart';
import 'package:personal_financial_assistant/features/budgets/presentation/screens/budget_screen.dart';
import 'package:personal_financial_assistant/features/goals/presentation/screens/goals_screen.dart';
import 'package:personal_financial_assistant/features/loans/presentation/screens/loans_screen.dart';
import 'package:personal_financial_assistant/features/trade_off/presentation/screens/trade_off_screen.dart';

class PlansHubScreen extends StatefulWidget {
  final int initialTabIndex;
  const PlansHubScreen({super.key, this.initialTabIndex = 0});

  @override
  State<PlansHubScreen> createState() => _PlansHubScreenState();
}

class _PlansHubScreenState extends State<PlansHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 3),
    );
  }

  @override
  void didUpdateWidget(covariant PlansHubScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTabIndex != oldWidget.initialTabIndex) {
      _tabController.animateTo(widget.initialTabIndex.clamp(0, 3));
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
            isScrollable: true,
            tabAlignment: TabAlignment.start,
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
                icon: Icon(Icons.pie_chart_outline_rounded, size: 18),
                text: 'Budgets',
              ),
              Tab(icon: Icon(Icons.flag_outlined, size: 18), text: 'Goals'),
              Tab(
                icon: Icon(Icons.account_balance_outlined, size: 18),
                text: 'Loans & Debt',
              ),
              Tab(
                icon: Icon(Icons.balance_rounded, size: 18),
                text: 'Trade-Offs',
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          BudgetScreen(),
          GoalsScreen(),
          LoansScreen(),
          TradeOffScreen(),
        ],
      ),
    );
  }
}
