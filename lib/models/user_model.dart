class UserModel {
  final String userId;
  final String name;
  final String usericon;
  final String chatBg;
  final String? introduction;

  UserModel({
    required this.userId,
    required this.name,
    required this.usericon,
    required this.chatBg,
    this.introduction,
  });

  // 从JSON数据创建UserModel
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['name'] ?? 'unknown_user',
      name: json['name'] ?? 'Unknown User',
      usericon: json['userpic'] ?? 'assets/images/default_avatar.png',
      chatBg: json['userpicBg'] ?? 'assets/images/xvibe_bg1.png',
      introduction: json['introduction'],
    );
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'usericon': usericon,
      'chatBg': chatBg,
      'introduction': introduction,
    };
  }
} 