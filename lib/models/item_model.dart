import 'package:firebase_auth/firebase_auth.dart';

class Item {
  final int? userId;
  final String type;
  final String category;
  final String name;
  final String imgUrl;
  final String description;
  final double lat;
  final double long;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? expiresAt;
  final bool? isReported;


  Item({
     this.userId,
    required this.type,
    required this.category,
    required this.name,
    required this.imgUrl,
    required this.description,
    required this.lat,
    required this.long,
    required this.status,
     this.createdAt,
     this.updatedAt,
     this.expiresAt,
    this.isReported
});

  Map<String , dynamic> toJson()=>{
    'userId' : userId,
    'type':type,
    'category':category,
    'name':name,
    'imgUrl':imgUrl,
    'description':description,
    'lat':lat,
    'long':long,
    'status':status,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt':updatedAt?.toIso8601String(),
    'expiresAt':expiresAt?.toIso8601String(),
    'isReported':isReported,

  };
  bool get isLost => type == 'Lost';
  factory Item.fromJson(Map<String , dynamic> json){
    return Item(
      userId: json['userId'],
      type: json['type'],
      category: json['category'],
      name: json['name'],
      imgUrl: json['img_url'],
      description: json['description'],
      lat:double.parse( json['lat'].toString()),
      long: double.parse(json['long'].toString()),
      status: json['status'],
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toLocal(),
      expiresAt: DateTime.parse(json['expires_at'] as String).toLocal(),
      isReported: json['is_reported']
    );
  }



}