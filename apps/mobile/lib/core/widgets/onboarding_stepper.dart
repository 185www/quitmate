import 'package:flutter/material.dart';

class OnboardingStepper extends StatelessWidget {
  final int currentStep; // 0-indexed
  final int totalSteps;

  const OnboardingStepper({super.key, required this.currentStep, this.totalSteps = 4});

  static const _stepData = [
    {'icon': Icons.assignment, 'label': '评估'},
    {'icon': Icons.menu_book, 'label': '了解'},
    {'icon': Icons.favorite_border, 'label': '动力'},
    {'icon': Icons.flag, 'label': '开始'},
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: List.generate(totalSteps * 2 - 1, (i) {
          if (i.isOdd) {
            final lineIndex = i ~/ 2;
            return Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.only(bottom: 18),
                color: lineIndex < currentStep
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.2),
              ),
            );
          }
          final stepIndex = i ~/ 2;
          final step = _stepData[stepIndex];
          final isDone = stepIndex < currentStep;
          final isActive = stepIndex == currentStep;
          final color = isDone
              ? Theme.of(context).colorScheme.primary
              : isActive
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.7)
                  : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.3);

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone ? Theme.of(context).colorScheme.primary : Colors.transparent,
                  border: Border.all(color: color, width: 2),
                ),
                child: isDone
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : Icon(step['icon'] as IconData, size: 16, color: color),
              ),
              const SizedBox(height: 3),
              Text(
                step['label'] as String,
                style: TextStyle(fontSize: 10, color: color, fontWeight: isActive ? FontWeight.w600 : FontWeight.normal),
              ),
            ],
          );
        }),
      ),
    );
  }
}