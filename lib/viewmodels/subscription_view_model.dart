import 'package:flutter/material.dart';
import '../models/subscription_plan.dart';

class SubscriptionViewModel extends ChangeNotifier {
  List<TrialStepModel> _trialSteps = [];
  List<ReviewModel> _reviews = [];
  SubscriptionPlanModel? _subscriptionPlan;
  List<SubscriptionPlanModel> _allPlans = [];
  StatsModel? _stats;

  bool _isLoading = false;
  String _selectedPlan = 'yearly';
  int _currentStepIndex = 0;

  // Getters
  List<TrialStepModel> get trialSteps => _trialSteps;
  List<ReviewModel> get reviews => _reviews;
  SubscriptionPlanModel? get subscriptionPlan => _subscriptionPlan;
  List<SubscriptionPlanModel> get allPlans => _allPlans;
  StatsModel? get stats => _stats;
  bool get isLoading => _isLoading;
  String get selectedPlan => _selectedPlan;
  int get currentStepIndex => _currentStepIndex;

  // Initialize data
  Future<void> initializeData() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    _trialSteps = [
      TrialStepModel(
        icon: 'lock_open_rounded',
        iconBgColor: '0xFF8B4513',
        iconColor: '0xFFFFFFFF',
        title: 'Today: Unlock Recipeflow',
        description: 'Get instant access and start organizing your recipes.',
        hasLine: true,
      ),
      TrialStepModel(
        icon: 'info_rounded',
        iconBgColor: '0xFFFFE4CC',
        iconColor: '0xFF8B4513',
        title: 'Day 1-6: Try for free',
        description: 'Decide if you want to continue.',
        hasLine: true,
      ),
      TrialStepModel(
        icon: 'star_rounded',
        iconBgColor: '0xFFFFE4CC',
        iconColor: '0xFF8B4513',
        title: 'Day 7: Trial Ends',
        description:
            'Your subscription will start 22-Oct-2025. Cancel anytime before.',
        hasLine: true,
      ),
    ];

    _reviews = [
      ReviewModel(
        rating: 5,
        reviewText:
            'Changed my life - now I can ogranize recipes effortlessly!',
        reviewerName: 'Sarah M.',
      ),
      ReviewModel(
        rating: 5,
        reviewText: 'RecipeFlow organizes my recipes perfectly. Love it!',
        reviewerName: 'John D.',
      ),
    ];

    _subscriptionPlan = SubscriptionPlanModel(
      name: 'Premium',
      yearlyPrice: 9900,
      monthlyPrice: 825,
      trialDays: 7,
      currency: 'Rs',
    );

    // Initialize all plans
    _allPlans = [
      _subscriptionPlan!,
      SubscriptionPlanModel(
        name: 'Basic',
        yearlyPrice: 5900,
        monthlyPrice: 492,
        trialDays: 7,
        currency: 'Rs',
      ),
      SubscriptionPlanModel(
        name: 'Family',
        yearlyPrice: 14900,
        monthlyPrice: 1242,
        trialDays: 7,
        currency: 'Rs',
      ),
    ];

    _stats = StatsModel(happyCooks: '5M+', starRating: 4.8);

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> startFreeTrial() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 2));
    print('Starting free trial...');

    _isLoading = false;
    notifyListeners();
    return true;
  }

  void viewAllPlans() {
    print('Navigating to all plans...');
  }

  void changeSelectedPlan(String plan) {
    _selectedPlan = plan;
    notifyListeners();
  }

  Future<bool> cancelTrial() async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(seconds: 1));
    print('Cancelling trial...');
    _isLoading = false;
    notifyListeners();
    return true;
  }

  // Progress update
  void updateTrialProgress(int index) {
    _currentStepIndex = index;
    notifyListeners();
  }

  // Select a plan
  void selectPlan(SubscriptionPlanModel plan) {
    _subscriptionPlan = plan;
    notifyListeners(); // This ensures UI updates immediately
  }

  // Check if a plan is currently selected
  bool isPlanSelected(SubscriptionPlanModel plan) {
    return _subscriptionPlan?.name == plan.name;
  }
}
