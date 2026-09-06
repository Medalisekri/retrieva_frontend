class Conversation {
  final String id;
  final DateTime createdAt;

  Conversation({
    required this.id,
    required this.createdAt,

  });

  factory Conversation.fromJson(Map<String, dynamic> json) =>
      Conversation(
        id: json['id'],
        createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      );
}



class Message {
  final int? id;
  final String text;
  final String? imageUrl;
  final DateTime createdAt;
  final bool isDeleted;
  Message({
    required this.id,
    required this.text,
    this.imageUrl,
    required this.createdAt,
    this.isDeleted = false,
  });

  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  Map<String, dynamic> toJson() => {
    'text':      text,
    'imageUrl':  imageUrl ?? '',
    'is_deleted': isDeleted,
  };

  factory Message.fromJson(Map<String, dynamic> json) =>
      Message(
        id:        json['id'] ?? '',
        text:      json['text']      ?? '',
        imageUrl:  json['image_url'] ?? '',
        createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
        isDeleted: json['is_deleted'] ?? false,
      );
}