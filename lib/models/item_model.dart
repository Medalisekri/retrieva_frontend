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
    'expires_at':expiresAt?.toIso8601String(),
    'is_reported':isReported,

  };

  bool get isLost => type == 'lost';
  factory Item.fromJson(Map<String , dynamic> json){
    return Item(
      isOwner: json['is_owner'],
      id: json['id'],
      userId: json['user'],
      type: json['type'] ?? '',
      category: json['category'] ?? '',
      name: json['name']?? '',
      imgUrl: json['img_url']?? '',
      description: json['description'] ?? '',
      lat:double.tryParse( json['lat'].toString() ) ?? 0.0 ,
      long: double.tryParse(json['long'].toString()) ?? 0.0,
      status: json['status']?? '',
      incidentDate: json['incident_date']?? '',
      createdAt:  DateTime.tryParse(json['created_at']as String) ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] as String) ?? DateTime.now(),
      expiresAt: json['expires_at'] !=null ? DateTime.tryParse(json['expires_at']as String) :null,
      isReported: json['is_reported'] ??false,
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
