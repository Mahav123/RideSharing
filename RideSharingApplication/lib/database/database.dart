import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Reference to the users collection
  CollectionReference get _usersCollection => _firestore.collection('users');

  // Add or update user data
  Future<void> upsertUser(String userId, Map<String, dynamic> userInfoMap) async {
    try {
      await _usersCollection.doc(userId).set(userInfoMap, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      print("Firebase Error while adding/updating user: ${e.message}");
      throw e;
    } catch (e) {
      print("Unexpected Error while adding/updating user: $e");
      throw e;
    }
  }

  // Get user data
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      DocumentSnapshot doc = await _usersCollection.doc(userId).get();
      return doc.exists ? doc.data() as Map<String, dynamic>? : null;
    } on FirebaseException catch (e) {
      print("Firebase Error fetching user: ${e.message}");
      throw e;
    } catch (e) {
      print("Unexpected Error fetching user: $e");
      throw e;
    }
  }

  // Delete user data
  Future<void> deleteUser(String userId) async {
    try {
      await _usersCollection.doc(userId).delete();
    } on FirebaseException catch (e) {
      print("Firebase Error deleting user: ${e.message}");
      throw e;
    } catch (e) {
      print("Unexpected Error deleting user: $e");
      throw e;
    }
  }

  // Listen for changes to user data
  Stream<Map<String, dynamic>?> userStream(String userId) {
    return _usersCollection.doc(userId).snapshots().map((snapshot) {
      return snapshot.exists ? snapshot.data() as Map<String, dynamic>? : null;
    }).handleError((e) {
      print("Error listening to user stream: $e");
    });
  }
}
