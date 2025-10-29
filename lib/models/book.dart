class Book {
  final String id;
  final String title;
  final String author;
  final String filePath;
  final String? coverImage;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.filePath,
    this.coverImage,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'author': author,
        'filePath': filePath,
        'coverImage': coverImage,
      };

  factory Book.fromJson(Map<String, dynamic> json) => Book(
        id: json['id'],
        title: json['title'],
        author: json['author'],
        filePath: json['filePath'],
        coverImage: json['coverImage'],
      );
}