class ConversationModel {
  final String id;
  final DateTime createdAt;

  ConversationModel({
    required this.id,
    required this.createdAt,

  });


  factory ConversationModel.fromMap(Map<String, dynamic> json, String id) =>
      ConversationModel(
        id: id,
        createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      );
}



class MessageModel {
  final String id;
  final String text;
  final String? imageUrl;
  final DateTime createdAt;
  final bool isDeleted;
  MessageModel({
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

  factory MessageModel.fromMap(Map<String, dynamic> json, String id) =>
      MessageModel(
        id:        id,
        text:      json['text']      ?? '',
        imageUrl:  json['image_url'] ?? '',
        createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
        isDeleted: json['is_deleted'] ?? false,
      );
}