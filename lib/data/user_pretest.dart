import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserDatabase {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static String? get _uid => _auth.currentUser?.uid;

  static DocumentReference<Map<String, dynamic>> get _userDoc {
    final uid = _uid;
    return _firestore.collection('users').doc(uid);
  }

  /// 설문 완료 여부 확인
  static Future<bool> hasCompletedSurvey() async {
    if (_uid == null) return false;
    final snapshot = await _userDoc.get();
    return snapshot.data()?['before_survey_completed'] == true;
  }
}
