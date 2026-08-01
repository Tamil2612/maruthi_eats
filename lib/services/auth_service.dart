import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../models/address_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  /// Starts phone OTP verification. Calls [codeSent] with the verificationId
  /// once the SMS has gone out, or [onError] if something goes wrong.
  /// On some Android devices Firebase can auto-verify without user input —
  /// that case is handled by [onAutoVerified].
  Future<void> sendOtp({
    required String phoneNumber, // must be in E.164 format, e.g. +91XXXXXXXXXX
    required void Function(String verificationId) codeSent,
    required void Function(String message) onError,
    required void Function(UserCredential credential) onAutoVerified,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        final result = await _auth.signInWithCredential(credential);
        onAutoVerified(result);
      },
      verificationFailed: (FirebaseAuthException e) {
        onError(e.message ?? 'Verification failed. Please try again.');
      },
      codeSent: (String verificationId, int? resendToken) {
        codeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  Future<UserCredential> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return _auth.signInWithCredential(credential);
  }

  /// Whether this user already has a name saved in /users (i.e. finished registration)
  Future<bool> hasProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.exists && (doc.data()?['name'] ?? '').toString().isNotEmpty;
  }

  /// Streams whether the user has a completed profile.
  Stream<bool> watchProfile(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      return doc.exists && (doc.data()?['name'] ?? '').toString().isNotEmpty;
    });
  }

  /// Streams the full user profile.
  Stream<AppUser?> watchUser(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return AppUser.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
    });
  }

  Future<void> saveProfile({
    required String uid,
    required String name,
    required String phone,
    String email = '',
    String dob = '',
    String address = '',
  }) async {
    await _db.collection('users').doc(uid).set({
      'name': name,
      'phone': phone,
      'email': email,
      'dob': dob,
      'address': address,
    }, SetOptions(merge: true));
  }

  Future<void> updateProfile({
    required String uid,
    String? name,
    String? address,
    String? email,
    String? dob,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (address != null) data['address'] = address;
    if (email != null) data['email'] = email;
    if (dob != null) data['dob'] = dob;

    if (data.isNotEmpty) {
      await _db.collection('users').doc(uid).update(data);
    }
  }

  // --- Address Management ---

  Stream<List<AddressModel>> watchAddresses(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('addresses')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AddressModel.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  Future<void> saveAddress({
    required String uid,
    String? addressId,
    required String label,
    required String fullAddress,
    required double latitude,
    required double longitude,
  }) async {
    final data = {
      'label': label,
      'full_address': fullAddress,
      'latitude': latitude,
      'longitude': longitude,
    };

    if (addressId == null) {
      await _db.collection('users').doc(uid).collection('addresses').add(data);
    } else {
      await _db
          .collection('users')
          .doc(uid)
          .collection('addresses')
          .doc(addressId)
          .set(data, SetOptions(merge: true));
    }
  }

  Future<void> deleteAddress(String uid, String addressId) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('addresses')
        .doc(addressId)
        .delete();
  }

  Future<void> signOut() => _auth.signOut();
}
