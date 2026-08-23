import 'package:flutter/material.dart';
import 'package:personal_financial_assistant/core/utils/formatters.dart';

class MoneyText extends StatelessWidget {
  final double amount;
  final String? currencyCode;
  final String? locale;
  final TextStyle? style;
  final bool showSign;
  final TextOverflow overflow;
  final int maxLines;

  const MoneyText(
    this.amount, {
    super.key,
    this.currencyCode,
    this.locale,
    this.style,
    this.showSign = false,
    this.overflow = TextOverflow.ellipsis,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final formatted = showSign
        ? CurrencyFormatter.formatWithSign(
            amount,
            currencyCode: currencyCode ?? 'INR',
            locale: locale ?? 'en_IN',
          )
        : CurrencyFormatter.format(
            amount,
            currencyCode: currencyCode ?? 'INR',
            locale: locale ?? 'en_IN',
          );

    return Text(
      formatted,
      style: style,
      overflow: overflow,
      maxLines: maxLines,
    );
  }
}

enum FinancialStatusType {
  actual('ACTUAL', Colors.teal),
  planned('PLANNED', Colors.blue),
  forecast('FORECAST', Colors.purple),
  estimated('ESTIMATED', Colors.orange);

  final String label;
  final Color color;
  const FinancialStatusType(this.label, this.color);
}

class FinancialStatusChip extends StatelessWidget {
  final FinancialStatusType type;
  const FinancialStatusChip(this.type, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: type.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: type.color.withValues(alpha: 0.3),
          width: 0.8,
        ),
      ),
      child: Text(
        type.label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: type.color,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;

  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final titleWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 600;

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: titleWidget),
                if (action != null) ...[const SizedBox(width: 16), action!],
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleWidget,
              if (action != null) ...[
                const SizedBox(height: 12),
                Align(alignment: Alignment.centerLeft, child: action!),
              ],
            ],
          );
        },
      ),
    );
  }
}

class MoneyTextCompact extends StatelessWidget {
  final double amount;
  final String? currencyCode;
  final String? locale;
  final TextStyle? style;

  const MoneyTextCompact(
    this.amount, {
    super.key,
    this.currencyCode,
    this.locale,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final formatted = CurrencyFormatter.formatCompact(
      amount,
      currencyCode: currencyCode ?? 'INR',
      locale: locale ?? 'en_IN',
    );
    return Text(formatted, style: style);
  }
}

class CategoryChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;

  const CategoryChip({
    super.key,
    required this.label,
    required this.color,
    this.selected = false,
    this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = selected
        ? color.withValues(alpha: 0.2)
        : color.withValues(alpha: 0.1);
    final textColor = selected ? color : color.withValues(alpha: 0.8);

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
          ),
        ],
      ),
      selected: selected,
      onSelected: onTap != null ? (_) => onTap!() : null,
      backgroundColor: backgroundColor,
      selectedColor: backgroundColor,
      checkmarkColor: textColor,
      side: BorderSide(color: color.withValues(alpha: 0.3)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
}

class BalanceCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final VoidCallback? onTap;

  const BalanceCard({
    super.key,
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPositive = amount >= 0;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const Spacer(),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              MoneyText(
                amount,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isPositive
                      ? theme.colorScheme.primary
                      : theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class LoadingWidget extends StatelessWidget {
  final String? message;
  final double size;

  const LoadingWidget({super.key, this.message, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: const CircularProgressIndicator(),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

class AppErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const AppErrorWidget({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class PercentageIndicator extends StatelessWidget {
  final double percentage;
  final Color? color;
  final double height;
  final BorderRadius? borderRadius;

  const PercentageIndicator({
    super.key,
    required this.percentage,
    this.color,
    this.height = 8,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clampedPercentage = percentage.clamp(0.0, 1.0);
    final indicatorColor =
        color ?? _getColorForPercentage(clampedPercentage, theme);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: height,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: borderRadius ?? BorderRadius.circular(height / 2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: clampedPercentage,
            child: Container(
              decoration: BoxDecoration(
                color: indicatorColor,
                borderRadius: borderRadius ?? BorderRadius.circular(height / 2),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getColorForPercentage(double percentage, ThemeData theme) {
    if (percentage >= 1.0) return theme.colorScheme.error;
    if (percentage >= 0.8) return theme.colorScheme.tertiary;
    return theme.colorScheme.primary;
  }
}

class TransactionTypeIcon extends StatelessWidget {
  final String type;
  final double size;

  const TransactionTypeIcon({super.key, required this.type, this.size = 20});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    switch (type) {
      case 'income':
        return Icon(
          Icons.arrow_downward,
          color: theme.colorScheme.primary,
          size: size,
        );
      case 'expense':
        return Icon(
          Icons.arrow_upward,
          color: theme.colorScheme.error,
          size: size,
        );
      case 'transfer':
        return Icon(
          Icons.swap_horiz,
          color: theme.colorScheme.tertiary,
          size: size,
        );
      default:
        return Icon(
          Icons.help_outline,
          color: theme.colorScheme.onSurfaceVariant,
          size: size,
        );
    }
  }
}
