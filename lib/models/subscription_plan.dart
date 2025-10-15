class TrialStepModel {
  final String icon;
  final String iconBgColor;
  final String iconColor;
  final String title;
  final String description;
  final bool hasLine;

  TrialStepModel({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.hasLine,
  });
}



class ReviewModel {
  final int rating;
  final String reviewText;
  final String reviewerName;

  ReviewModel({
    required this.rating,
    required this.reviewText,
    required this.reviewerName,
  });
}




class SubscriptionPlanModel {
  final String name;
  final double yearlyPrice;
  final double monthlyPrice;
  final int trialDays;
  final String currency;

  SubscriptionPlanModel({
    required this.name,
    required this.yearlyPrice,
    required this.monthlyPrice,
    required this.trialDays,
    this.currency = 'Rs',
  });

  String get formattedYearlyPrice => '$currency ${yearlyPrice.toStringAsFixed(0)}/year';
  String get formattedMonthlyPrice => '$currency ${monthlyPrice.toStringAsFixed(0)}/month';
}



class StatsModel {
  final String happyCooks;
  final double starRating;

  StatsModel({
    required this.happyCooks,
    required this.starRating,
  });
}



