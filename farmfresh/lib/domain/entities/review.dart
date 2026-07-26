/// A customer review shown on the product detail screen.
class Review {
  const Review({
    required this.initials,
    required this.author,
    required this.area,
    required this.rating,
    required this.text,
  });

  final String initials;
  final String author;
  final String area;
  final int rating; // 1..5
  final String text;
}
