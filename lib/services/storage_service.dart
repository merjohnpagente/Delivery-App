import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

/// Uploads images to Firebase Storage.
/// (Used by the separate admin app; kept here so both apps share logic.)
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload [file] to `foods/<fileName>` and return its download URL.
  Future<String> uploadFoodImage(File file, String fileName) async {
    final ref = _storage.ref().child('foods/$fileName');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  /// Upload a user avatar to `avatars/<uid>.jpg`.
  Future<String> uploadAvatar(File file, String uid) async {
    final ref = _storage.ref().child('avatars/$uid.jpg');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }
}
