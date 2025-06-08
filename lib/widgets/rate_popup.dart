import 'package:flutter/material.dart';
import 'package:chefoo/commons.dart';
import 'package:chefoo/screens/rating/rating_screen.dart';
import 'package:chefoo/providers/rating_session.dart';

class RatePopup extends StatelessWidget {
  final VoidCallback onDismissed;
  final String restaurantName;

  const RatePopup({
    super.key,
    required this.onDismissed,
    required this.restaurantName,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: const ValueKey('rate-popup'),
      direction: DismissDirection.horizontal,
      onDismissed: (_) => onDismissed(),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rate your last meal!',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.surface,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text.rich(
                    TextSpan(
                      text: 'How was the meal at ',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.surface,
                        ),
                      children: [
                        TextSpan(
                          text: restaurantName,
                          // style: const TextStyle(
                          //   decoration: TextDecoration.underline,
                          //   decorationColor: Colors.purpleAccent,
                          // ),
                        ),
                        const TextSpan(text: '?'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                onDismissed();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RatingScreen()),
                );
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surface, width: 2),
                ),
                child: const Center(
                  child: Icon(Icons.arrow_forward_ios, color: AppColors.surface, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}