import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_financial_assistant/core/widgets/financial_widgets.dart';
import 'package:personal_financial_assistant/core/widgets/responsive_center.dart';
import 'package:personal_financial_assistant/features/trade_off/presentation/widgets/trade_off_comparison_card.dart';

class TradeOffScreen extends ConsumerWidget {
  const TradeOffScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trade-Off Intelligence')),
      body: SingleChildScrollView(
        child: ResponsiveCenter(
          maxWidth: 1000,
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 48.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(
                title: 'Loan vs Goal Trade-Offs',
                subtitle: 'Simulate and compare how extra cash flow impacts your debt payoff timeline versus savings growth.',
                action: Wrap(
                  spacing: 8,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: () => context.push('/loans'),
                      icon: const Icon(
                        Icons.account_balance_outlined,
                        size: 16,
                      ),
                      label: const Text('Loans'),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () => context.push('/goals'),
                      icon: const Icon(Icons.flag_outlined, size: 16),
                      label: const Text('Goals'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const TradeOffComparisonCard(),
            ],
          ),
        ),
      ),
    );
  }
}
