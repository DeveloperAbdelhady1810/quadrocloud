class PostModel {
  final int id;
  final String title;
  final String content;
  final String? mediaPath;
  final String? mediaType;
  final String? publishedAt;

  PostModel({required this.id, required this.title, required this.content, this.mediaPath, this.mediaType, this.publishedAt});

  factory PostModel.fromJson(Map<String, dynamic> j) => PostModel(
    id: j['id'],
    title: j['title'],
    content: j['content'],
    mediaPath: j['media_path'],
    mediaType: j['media_type'],
    publishedAt: j['published_at'],
  );
}
