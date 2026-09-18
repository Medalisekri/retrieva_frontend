class ProfileModel {
  final int userId;
  final bool isVerified;
  final String fullName;
  final String? onesignalId;
  ProfileModel({
    required this.userId,
    required this.isVerified,
    required this.fullName,
    this.onesignalId
});


  factory ProfileModel.fromJson(Map<String , dynamic> json){
    return ProfileModel(
        userId: json['user_id'] ?? 0,
        isVerified: json['is_verified'] ?? false,
        fullName: json['full_name'] ?? '',
        onesignalId: json['onesignal_id'] ?? ''
    );
  }

}
