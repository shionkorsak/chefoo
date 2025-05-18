class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final String? photoURL;
  final dynamic createdAt;

  UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoURL,
    required this.createdAt,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
        uid: map['uid'],
        email: map['email'],
        displayName: map['displayName'],
        photoURL: map['photoURL'],
        createdAt: map['createdAt'],
      );

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'email': email,
        'displayName': displayName,
        if (photoURL != null) 'photoURL': photoURL,
        'createdAt': createdAt,
      };
}
