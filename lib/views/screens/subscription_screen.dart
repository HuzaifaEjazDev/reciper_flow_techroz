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
                    padding: const EdgeInsets.fromLTRB(16, 60, 16, 220),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeaderSection(),
                        const SizedBox(height: 6),
                        _buildTrialSection(viewModel),
                        const SizedBox(height: 24),
                        _buildStatsSection(viewModel),
                        const SizedBox(height: 24),
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
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const Icon(Icons.close, color: Color(0xFF9E9E9E), size: 24),
        ),
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
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              children: [
                TextSpan(
                  text: 'Get ',
                  style: TextStyle(color: Color(0xFF37474F)),
                ),
                TextSpan(
                  text: 'Unlimited Recipes',
                  style: TextStyle(color: Color(0xFFFF6B1A)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // const Center(
        //   child: Text(
        //     'from various sources & more',
        //     style: TextStyle(
        //       fontSize: 18,
        //       color: Color(0xFF37474F),
        //       fontWeight: FontWeight.w600,
        //     ),
        //     textAlign: TextAlign.center,
        //   ),
        // ),
      ],
    );
  }

  // Dynamic trial section
  Widget _buildTrialSection(SubscriptionViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(20),

      child: Column(
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
          const SizedBox(height: 16),
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
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'lock_open_rounded':
        return Icons.lock_open_rounded;
      case 'notifications_rounded':
        return Icons.notifications_rounded;
      case 'info_rounded':
        return Icons.info_rounded;
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
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isCompleted
                    ? const Color(0xFFFF6B1A)
                    : const Color(0xFFF1D1D6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isCompleted ? Colors.white : Colors.black,
                size: 18,
              ),
            ),
            if (hasLine)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 4,
                height: 60,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFFFF6B1A)
                      : const Color(0xFFF1D1D6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 8, bottom: hasLine ? 20 : 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isCompleted ? FontWeight.bold : FontWeight.w600,
                    color: isCompleted
                        ? const Color(0xFF37474F)
                        : const Color(0xFF616161),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF616161),
                    height: 1.4,
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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        // border: Border.all(color: const Color(0xFFE9ECEF)),
        // boxShadow: [
        //   BoxShadow(
        //     color: Colors.black.withOpacity(0.03),
        //     blurRadius: 8,
        //     offset: const Offset(0, 2),
        //   ),
        // ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Column(
            children: [
              Text(
                stats.happyCooks,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF37474F),
                ),
              ),
              const Text(
                'Happy Cooks',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF616161),
                ),
              ),
            ],
          ),
          Container(height: 40, width: 1, color: const Color(0xFFE0E0E0)),
          Column(
            children: [
              Text(
                '${stats.starRating} STAR RATING',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF37474F),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (index) => const Icon(
                    Icons.star,
                    color: Color(0xFFFFB900),
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection(SubscriptionViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What Our Users Say',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF37474F),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: viewModel.reviews.length,
            itemBuilder: (context, index) {
              final review = viewModel.reviews[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index < viewModel.reviews.length - 1 ? 16 : 0,
                ),
                child: _buildReviewCard(review),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReviewCard(ReviewModel review) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(
              5,
              (index) =>
                  const Icon(Icons.star, color: Color(0xFFFFB900), size: 20),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Text(
              review.reviewText,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF424242),
                height: 1.4,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '- ${review.reviewerName}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF616161),
            ),
          ),
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
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),

        child: Column(
          children: [
            const SizedBox(height: 3),
            const Text(
              'No Payment Now',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF616161),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 50,
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: viewModel.isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      )
                    : const Text(
                        'Start Your FREE Week',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF37474F),
                    fontSize: 14,
                  ),
                  children: [
                    TextSpan(
                      text: 'Free for ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF37474F),
                      ),
                    ),
                    TextSpan(
                      text: '7 days',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF37474F),
                      ),
                    ),
                    TextSpan(
                      text: ' then,\n',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF37474F),
                      ),
                    ),
                    TextSpan(
                      text: 'Rs 9,900',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF37474F),
                      ),
                    ),
                    TextSpan(
                      text: '/year (',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF37474F),
                      ),
                    ),
                    TextSpan(
                      text: 'Rs 825',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF37474F),
                      ),
                    ),
                    TextSpan(
                      text: '/month)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF37474F),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            TextButton(
              onPressed: () => _showPlansBottomSheet(context, viewModel),
              child: const Text(
                'View All Plans',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Bottom Sheet for Plans ---
  void _showPlansBottomSheet(
    BuildContext context,
    SubscriptionViewModel viewModel,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Consumer<SubscriptionViewModel>(
          builder: (context, viewModel, child) {
            final plans = viewModel.allPlans;
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0E0E0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Title
                  const Center(
                    child: Text(
                      'Choose a plan',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF37474F),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Annual Plan
                  GestureDetector(
                    onTap: () {
                      // Select annual plan logic
                      if (plans.isNotEmpty) {
                        viewModel.selectPlan(plans.first);
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: viewModel.isPlanSelected(plans.first)
                            ? const Color.fromARGB(255, 255, 217, 194)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: viewModel.isPlanSelected(plans.first)
                              ? Colors.deepOrange
                              : Colors.black,
                          width: viewModel.isPlanSelected(plans.first) ? 2 : 1,
                        ),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Row(
                            children: [
                              // Plan details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Annual',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF37474F),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Rs 9,900 / year',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF616161),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Price
                              const Text(
                                'Rs 825 / month',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF37474F),
                                ),
                              ),
                            ],
                          ),
                          // 7-Day Free Trial badge - positioned on the border line
                          Positioned(
                            top: -27,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF6B1A),
                                  borderRadius: BorderRadius.circular(12),
                                  // boxShadow: [
                                  //   BoxShadow(
                                  //     color: Colors.black.withOpacity(0.1),
                                  //     blurRadius: 4,
                                  //     offset: const Offset(0, 2),
                                  //   ),
                                  // ],
                                ),
                                child: const Text(
                                  '7-Day Free Trial',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Monthly Plan
                  GestureDetector(
                    onTap: () {
                      // Select monthly plan logic
                      if (plans.length > 1) {
                        viewModel.selectPlan(plans[1]);
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color:
                            viewModel.isPlanSelected(
                              plans.length > 1 ? plans[1] : plans.first,
                            )
                            ? const Color.fromARGB(255, 255, 217, 194)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              viewModel.isPlanSelected(
                                plans.length > 1 ? plans[1] : plans.first,
                              )
                              ? Colors.deepOrange
                              : Colors.black,
                          width:
                              viewModel.isPlanSelected(
                                plans.length > 1 ? plans[1] : plans.first,
                              )
                              ? 2
                              : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Plan details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Column(
                                  children: [
                                    const Text(
                                      'Monthly',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF37474F),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'No Free Trial',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF37474F),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Price
                          const Text(
                            'Rs 1,900 / month',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF37474F),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Start button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: viewModel.isLoading
                          ? null
                          : () async {
                              Navigator.pop(context);
                              final success = await viewModel.startFreeTrial();
                              if (success && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Free trial started successfully!',
                                    ),
                                    backgroundColor: Color(0xFFFF6B1A),
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B1A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: viewModel.isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            )
                          : const Text(
                              'Start Your FREE Week',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Pricing info
                  Center(
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF616161),
                          height: 1.4,
                        ),
                        children: [
                          TextSpan(
                            text: 'Free for ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF37474F),
                            ),
                          ),
                          TextSpan(
                            text: '7 days',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF37474F),
                            ),
                          ),
                          TextSpan(
                            text: ' then,\n',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF37474F),
                            ),
                          ),
                          TextSpan(
                            text: 'Rs 9,900',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF37474F),
                            ),
                          ),
                          TextSpan(
                            text: '/year (',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF37474F),
                            ),
                          ),
                          TextSpan(
                            text: 'Rs 825',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF37474F),
                            ),
                          ),
                          TextSpan(
                            text: '/month)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF37474F),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
