import 'package:firebase_auth/firebase_auth.dart';

class Item {
  final bool? isOwner;
  final int? id;
  final int? userId;
  final String type;
  final String category;
  final String name;
  final String? imgUrl;
  final String? description;
  final double lat;
  final double long;
  final String status;
  final String? incidentDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? expiresAt;
  final bool? isReported;
  final String? posterName;


  Item({
   this.isOwner,
     this.id,
     this.userId,
    required this.type,
    required this.category,
    required this.name,
     this.imgUrl,
     this.description,
    required this.lat,
    required this.long,
    required this.status,
    this.incidentDate,
     this.createdAt,
     this.updatedAt,
     this.expiresAt,
    this.isReported,
    this.posterName
});


  Map<String , dynamic> toJson()=>{

    'type':type,
    'category':category,
    'name':name,
    'img_url':imgUrl,
    'description':description,
    'lat':lat,
    'long':long,
    'status':status,
    'incident_date':incidentDate,
    'created_at': createdAt?.toIso8601String(),
    'updated_at':updatedAt?.toIso8601String(),
    'expires_at':expiresAt?.toIso8601String(),
    'is_reported':isReported,

  };
  bool get isLost => type == 'Lost';
  factory Item.fromJson(Map<String , dynamic> json){
    return Item(
      isOwner: json['is_owner'],
      id: json['id'],
      userId: json['user_id'],
      type: json['type'] ?? '',
      category: json['category'] ?? '',
      name: json['name']?? '',
      imgUrl: json['img_url']?? '',
      description: json['description'] ?? '',
      lat:double.parse( json['lat'].toString()) ,
      long: double.parse(json['long'].toString()),
      status: json['status']?? '',
      incidentDate: json['incident_date']?? '',
      createdAt:  DateTime.parse(json['created_at']as String).toLocal() ,
      updatedAt: DateTime.parse(json['updated_at'] as String).toLocal(),
      expiresAt: json['expires_at'] !=null ? DateTime.parse(json['expires_at']as String).toLocal() :null,
      isReported: json['is_reported'] ?? '',
      posterName: json['poster_name']   ?? ''
    );
  }


  Item copyWith({
    String? status,
    String? type,
    String? category,
    String? name,
    double? lat,
    double? long,


  }){return Item(type: type ?? this.type , category:category ?? this.category ,
      name: name ??this.name, lat: lat ?? this.lat, long:long ?? this.long, status: status ?? this.status

  );}

}
