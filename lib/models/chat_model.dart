class Conversation {
  final int id;
  final int item;
  final String itemName;
  final int participant1;
  final int participant2;
  final String participant1Username;
  final String participant2Username;
  final DateTime createdAt;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final bool isBlocked;

  Conversation({
    required this.id,
    required this.item,
    required this.itemName,
    required this.participant1,
    required this.participant2,
    required this.participant1Username,
    required this.participant2Username,
    required this.createdAt,
    this.lastMessage,
    this.lastMessageTime,
    required this.isBlocked,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] ?? 0,
      item: json['item'] ?? 0,
      itemName: json['item_name'] ?? '',
      participant1: json['participant1'] ?? 0,
      participant2: json['participant2'] ?? 0,
      participant1Username: json['participant1_username'] ?? '',
      participant2Username: json['participant2_username'] ?? '',
      createdAt: DateTime.tryParse(json['created_at']) ?? DateTime.now(),
      lastMessage: json['last_message'] ?? '',
      lastMessageTime: json['last_message_time'] != null
          ? DateTime.tryParse(json['last_message_time'])
          : null,
      isBlocked: json['is_blocked'] ?? false,
    );
  }

  // Get the OTHER person's info
  String getOtherName(int myUserId) {
    return participant1 == myUserId ? participant2Username : participant1Username;
  }

  int getOtherId(int myUserId) {
    return participant1 == myUserId ? participant2 : participant1;
  }

  Conversation copyWith({
    int? id,
    int? item,
    String? itemName,
    int? participant1,
    int? participant2,
    String? participant1Username,
    String? participant2Username,
    DateTime? createdAt,
    bool? isBlocked,
    String? lastMessage,
    DateTime? lastMessageTime
  }) {
    return Conversation(
      id: id ?? this.id, item: item ?? this.item
      ,createdAt: createdAt ?? this.createdAt ,isBlocked: isBlocked ?? this.isBlocked,
      participant1: participant1 ?? this.participant1, participant2: participant2 ?? this.participant2,
      participant1Username: participant1Username ?? this.participant1Username , participant2Username:
        participant2Username ?? this.participant2Username, itemName: itemName ?? this.itemName
     , lastMessage: lastMessage ?? this.lastMessage, lastMessageTime: lastMessageTime ?? this.lastMessageTime
    );
  }
}



class Message {
  final int id;
  final String text;
  final String? imgUrl;
  final DateTime createdAt;
  final bool isDeleted;
  final bool isMine;
  Message({
    required this.id,
    required this.text,
    this.imgUrl,
    required this.createdAt,
    this.isDeleted = false,
    required this.isMine
  });

  bool get hasImage => imgUrl != null && imgUrl!.isNotEmpty;



  factory Message.fromJson(Map<String, dynamic> json) =>
      Message(
        id:        json['id'] ?? 0,
        text:      json['text']      ?? '',
        imgUrl:  json['img_url'] ?? '',
        createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
        isDeleted: json['is_deleted'] ?? false,
        isMine: json['is_mine'] ?? false
      );

  Message copyWith({
    int? id,
    String? text,
    DateTime? createdAt,
    bool? isMine,
}) {
    return Message(
      id: id ?? this.id, text: text ?? this.text
      ,createdAt: createdAt ?? this.createdAt ,isMine: isMine ?? this.isMine,
    );
  }
}