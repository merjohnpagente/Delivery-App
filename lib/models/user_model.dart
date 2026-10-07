/// App user profile stored in the `users` collection.
/// [role] is 'customer' (default) or 'admin' (separate admin UI).
class AppUser {
  final String uid;
  final String name;
  final String email;
  final String? phone;
  final String? address;
  final String? photoUrl;
  final String role;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.phone,
    this.address,
    this.photoUrl,
    this.role = 'customer',
  });

  bool get isAdmin => role == 'admin';

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] ?? '',
      name: map['name'] ?? 'Dodo User',
      email: map['email'] ?? '',
      phone: map['phone'],
      address: map['address'],
      photoUrl: map['photoUrl'],
      role: map['role'] ?? 'customer',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
      if (photoUrl != null) 'photoUrl': photoUrl,
    };
  }
}
