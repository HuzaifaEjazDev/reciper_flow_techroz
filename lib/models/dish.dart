class Dish {
  final String id;
  final String title;
  final String subtitle;
  final String imageAssetPath;
  final int minutes;
  final double? randomValue; // Add randomValue field for recommended recipes algorithm

  const Dish({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageAssetPath,
    required this.minutes,
    this.randomValue, // Add randomValue parameter
  });
}