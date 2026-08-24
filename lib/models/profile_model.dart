class ProfileModel {
  final bool isVerified;
  final String fullName;
  ProfileModel({
    required this.isVerified,
    required this.fullName
});
  Map<String , dynamic> toJson()=>{
    'isVerified':isVerified,
    'fullName': fullName
  };

  factory ProfileModel.fromJson(Map<String , dynamic> json){
    return ProfileModel(
        isVerified: json['is_verified'],
        fullName: json['full_name'],
    );
  }

}
