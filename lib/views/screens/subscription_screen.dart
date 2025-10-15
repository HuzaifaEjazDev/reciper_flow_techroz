import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/subscription_plan.dart';
import '../../viewmodels/subscription_view_model.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubscriptionViewModel>().initializeData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading && viewModel.subscriptionPlan == null) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFFFF6B1A)),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Stack(
              children: [
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 60, 24, 200),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeaderSection(),
                        const SizedBox(height: 20),
                        _buildTrialSection(viewModel),
                        const SizedBox(height: 20),
                        _buildStatsSection(viewModel),
                        const SizedBox(height: 20),
                        _buildReviewsSection(viewModel),
                      ],
                    ),
                  ),
                ),
                _buildCloseButton(context),
                _buildBottomFixedSection(viewModel),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCloseButton(BuildContext context) {
    return Positioned(
      top: 16,
      right: 16,
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: const Icon(Icons.close, color: Color(0xFF9E9E9E), size: 24),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              children: [
                TextSpan(text: 'Get ', style: TextStyle(color: Color(0xFF37474F))),
                TextSpan(text: 'Unlimited Imports', style: TextStyle(color: Color(0xFFFF8C00))),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Center(
          child: Text(
            'from Instagram, TikTok & more',
            style: TextStyle(
              fontSize: 19,
              color: Color(0xFF37474F),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // Dynamic trial section
  Widget _buildTrialSection(SubscriptionViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'How your free trial works:',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF37474F),
          ),
        ),
        const SizedBox(height: 8),
        ...List.generate(viewModel.trialSteps.length, (index) {
          final step = viewModel.trialSteps[index];
          final isCompleted = index <= viewModel.currentStepIndex;

          return _buildTimelineStep(
            icon: _getIconData(step.icon),
            isCompleted: isCompleted,
            title: step.title,
            description: step.description,
            hasLine: step.hasLine,
          );
        }),
      ],
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'lock_open_rounded':
        return Icons.lock_open_rounded;
      case 'notifications_rounded':
        return Icons.notifications_rounded;
      case 'star_rounded':
        return Icons.star_rounded;
      default:
        return Icons.circle;
    }
  }

  Widget _buildTimelineStep({
    required IconData icon,
    required bool isCompleted,
    required String title,
    required String description,
    required bool hasLine,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: isCompleted ? Colors.black : const Color(0xFFF1D1D6),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isCompleted ? Colors.white : Colors.black, size: 18),
            ),
            if (hasLine)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 4,
                height: 60,
                color: isCompleted ? Colors.black : const Color(0xFFF1D1D6),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 4, bottom: hasLine ? 20 : 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF37474F),
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF616161),
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection(SubscriptionViewModel viewModel) {
    final stats = viewModel.stats;
    if (stats == null) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Column(
          children: [
            Text(stats.happyCooks,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF37474F))),
            const Text('Happy Cooks', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF616161))),
          ],
        ),
        Column(
          children: [
            Text('${stats.starRating} STAR RATING',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF37474F))),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) => const Icon(Icons.star, color: Color(0xFFFFB900), size: 22)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReviewsSection(SubscriptionViewModel viewModel) {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: viewModel.reviews.length,
        itemBuilder: (context, index) {
          final review = viewModel.reviews[index];
          return Padding(
            padding: EdgeInsets.only(right: index < viewModel.reviews.length - 1 ? 16 : 0),
            child: _buildReviewCard(review),
          );
        },
      ),
    );
  }

  Widget _buildReviewCard(ReviewModel review) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: List.generate(5, (index) => const Icon(Icons.star, color: Color(0xFFFFB900), size: 20))),
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              review.reviewText,
              style: const TextStyle(fontSize: 12, color: Color(0xFF424242), height: 1.4),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text('- ${review.reviewerName}',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF616161))),
        ],
      ),
    );
  }

  Widget _buildBottomFixedSection(SubscriptionViewModel viewModel) {
    final plan = viewModel.subscriptionPlan;
    if (plan == null) return const SizedBox.shrink();

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            const Text('No Payment Now', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF616161))),
            const SizedBox(height: 5),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: viewModel.isLoading
                    ? null
                    : () async {
                  final success = await viewModel.startFreeTrial();
                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Free trial started successfully!'),
                        backgroundColor: Color(0xFFFF6B1A),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B1A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: viewModel.isLoading
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : const Text(
                  'Start Your FREE Week',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text('Free for ${plan.trialDays} days, then',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF37474F))),
            Text('${plan.formattedYearlyPrice} (${plan.formattedMonthlyPrice})',
                style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF37474F))),
            TextButton(
              onPressed: () => _showPlansBottomSheet(context, viewModel),
              child: const Text('View All Plans',
                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }

  // --- Bottom Sheet for Plans ---
  void _showPlansBottomSheet(BuildContext context, SubscriptionViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final plans = viewModel.allPlans;
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'Choose Your Plan',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF37474F)),
                ),
              ),
              const SizedBox(height: 20),
              ...plans.map((plan) => Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDF6EE),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(plan.name,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF37474F))),
                    const SizedBox(height: 6),
                    // Use formatted price instead of missing description
                    Text('${plan.formattedYearlyPrice} per year',
                        style: const TextStyle(fontSize: 14, color: Color(0xFF616161))),
                    const SizedBox(height: 8),
                    Text('${plan.formattedMonthlyPrice}/month',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF6B1A))),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          viewModel.selectPlan(plan);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B1A),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          'Select Plan',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ],
          ),
        );
      },
    );
  }
}