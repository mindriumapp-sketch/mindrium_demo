import 'package:gad_app_team/data/user_data_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserDataStorage {
  /// 사용자 데이터 저장 (Firebase Firestore)
  static Future<void> saveUserData(UserData userData) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('로그인이 필요합니다');
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
            'coreValue': userData.coreValue,
            'valueUpdatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('사용자 데이터 저장 실패: $e');
    }
  }

  /// 사용자 데이터 로드 (Firebase Firestore)
  static Future<UserData?> loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return null;
      }

      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data()!;
      return UserData(
        name: data['name'] ?? '',
        coreValue: data['coreValue'] ?? '',
        createdAt:
            data['createdAt'] != null
                ? (data['createdAt'] as Timestamp).toDate()
                : DateTime.now(),
        updatedAt:
            data['valueUpdatedAt'] != null
                ? (data['valueUpdatedAt'] as Timestamp).toDate()
                : null,
      );
    } catch (e) {
      throw Exception('사용자 데이터 로드 실패: $e');
    }
  }

  /// 사용자 데이터 업데이트
  static Future<void> updateUserData(UserData userData) async {
    try {
      await saveUserData(userData);
    } catch (e) {
      throw Exception('사용자 데이터 업데이트 실패: $e');
    }
  }

  /// 사용자 데이터 삭제
  static Future<void> deleteUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('로그인이 필요합니다');
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {
          'coreValue': FieldValue.delete(),
          'valueUpdatedAt': FieldValue.delete(),
        },
      );
    } catch (e) {
      throw Exception('사용자 데이터 삭제 실패: $e');
    }
  }

  /// 사용자 데이터 존재 여부 확인 (Firebase Firestore)
  static Future<bool> hasUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return false;
      }

      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (!doc.exists) {
        return false;
      }

      final data = doc.data()!;
      return data['coreValue'] != null &&
          data['coreValue'].toString().isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// 사용자 이름만 가져오기 (Firebase Firestore)
  static Future<String?> getUserName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return null;
      }

      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data()!;
      return data['name'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// 사용자 핵심 가치만 가져오기 (Firebase Firestore)
  static Future<String?> getUserCoreValue() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return null;
      }

      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data()!;
      return data['coreValue'] as String?;
    } catch (e) {
      return null;
    }
  }
}
