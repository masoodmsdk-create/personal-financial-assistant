import 'package:flutter/material.dart';
import 'package:personal_financial_assistant/features/analytics/presentation/screens/analytics_screen.dart';
import 'package:personal_financial_assistant/features/forecast/presentation/screens/forecast_screen.dart';
import 'package:personal_financial_assistant/features/review/presentation/screens/monthly_review_screen.dart';

class InsightsHubScreen extends StatefulWidget {
  final int initialTabIndex;
  const InsightsHubScreen({super.key, this.initialTabIndex = 0});

  @override
  State<InsightsHubScreen> createState() => _InsightsHubScreenState();
}

class _InsightsHubScreenState extends State<InsightsHubScreen>
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
  void didUpdateWidget(covariant InsightsHubScreen oldWidget) {
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
                icon: Icon(Icons.show_chart_rounded, size: 18),
                text: 'Analytics',
              ),
              Tab(
                icon: Icon(Icons.event_note_rounded, size: 18),
                text: 'Monthly Review',
              ),
              Tab(
                icon: Icon(Icons.auto_graph_rounded, size: 18),
                text: 'Forecast',
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          AnalyticsScreen(),
          MonthlyReviewScreen(),
          ForecastScreen(),
        ],
      ),
    );
  }
}
