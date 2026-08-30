import 'package:flutter/material.dart';
import '../models/review.dart';

class ReviewCard extends StatelessWidget {
  final Review review;
  final bool showFullText;

  const ReviewCard({
    super.key,
    required this.review,
    this.showFullText = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = review.isAnonymous
        ? 'Anonimo'
        : (review.userName ?? 'Utente');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  displayName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < review.rating
                          ? Icons.star
                          : Icons.star_border,
                      size: 18,
                      color: Colors.amber,
                    );
                  }),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (review.reviewText != null && review.reviewText!.isNotEmpty)
              Text(
                review.reviewText!,
                maxLines: showFullText ? null : 3,
                overflow: showFullText
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
              ),
            if (review.categoryDetail != null &&
                review.categoryDetail!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    review.categoryDetail!,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              _formatDate(review.createdAt),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 0) {
      return '${diff.inDays} giorni fa';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} ore fa';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} minuti fa';
    }
    return 'Adesso';
  }
}
