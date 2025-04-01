import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:buapp/models/profile.dart';
import 'package:buapp/utils/constants.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // Authentication
  static Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }
  
  static Future<UserCredential> createUserWithEmailAndPassword(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }
  
  static Future<void> signOut() async {
    await _auth.signOut();
  }
  
  static Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
  
  static User? getCurrentUser() {
    return _auth.currentUser;
  }
  
  // Firestore
  static Future<void> createUserProfile(Profile profile) async {
    await _firestore.collection('profiles').doc(profile.id).set(profile.toJson());
  }
  
  static Future<Profile?> getUserProfile(String userId) async {
    final doc = await _firestore.collection('profiles').doc(userId).get();
    if (doc.exists) {
      return Profile.fromJson(doc.data()!);
    }
    return null;
  }
  
  static Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    await _firestore.collection('profiles').doc(userId).update(data);
  }
  
  static Stream<QuerySnapshot> getAnnouncements() {
    return _firestore
        .collection('announcements')
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots();
  }
  
  static Stream<QuerySnapshot> getEvents() {
    return _firestore
        .collection('events')
        .where('eventDate', isGreaterThanOrEqualTo: DateTime.now())
        .orderBy('eventDate')
        .limit(10)
        .snapshots();
  }
  
  static Stream<QuerySnapshot> getCourses(String userId, String role) {
    if (role == Constants.roleStudent) {
      return _firestore
          .collection('enrollments')
          .where('studentId', isEqualTo: userId)
          .snapshots();
    } else if (role == Constants.roleLecturer) {
      return _firestore
          .collection('courses')
          .where('lecturerId', isEqualTo: userId)
          .snapshots();
    } else {
      return _firestore.collection('courses').snapshots();
    }
  }
  
  // Storage
  static Future<String> uploadFile(File file, String path) async {
    final ref = _storage.ref().child(path);
    final uploadTask = ref.putFile(file);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }
  
  static Future<void> deleteFile(String path) async {
    await _storage.ref().child(path).delete();
  }
  
  // Messaging
  static Future<void> sendMessage(String senderId, String receiverId, String content) async {
    final message = {
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    };
    
    await _firestore.collection('messages').add(message);
    
    // Update last message in chat
    final chatId = [senderId, receiverId]..sort();
    final chatDocId = chatId.join('_');
    
    await _firestore.collection('chats').doc(chatDocId).set({
      'participants': [senderId, receiverId],
      'lastMessage': content,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastSenderId': senderId,
    }, SetOptions(merge: true));
  }
  
  static Stream<QuerySnapshot> getMessages(String userId, String otherUserId) {
    final chatId = [userId, otherUserId]..sort();
    final chatDocId = chatId.join('_');
    
    return _firestore
        .collection('messages')
        .where('chatId', isEqualTo: chatDocId)
        .orderBy('timestamp')
        .snapshots();
  }
  
  static Stream<QuerySnapshot> getChats(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }
  
  // Mark messages as read
  static Future<void> markMessagesAsRead(String chatId, String userId) async {
    final batch = _firestore.batch();
    final messages = await _firestore
        .collection('messages')
        .where('chatId', isEqualTo: chatId)
        .where('receiverId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();
    
    for (var doc in messages.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    
    await batch.commit();
  }
}

