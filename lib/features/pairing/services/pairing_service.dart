import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class PairingService with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generate a 6-digit code and link it to the parent
  Future<String> generatePairingCode(String parentUid) async {
    String code = '';
    bool exists = true;

    // Ensure uniqueness
    while (exists) {
      code = (Random().nextInt(900000) + 100000).toString();
      final doc = await _firestore.collection('pairing_codes').doc(code).get();
      exists = doc.exists;
    }

    await _firestore.collection('pairing_codes').doc(code).set({
      'parent_uid': parentUid,
      'created_at': FieldValue.serverTimestamp(),
      'status': 'waiting', // waiting, paired
      'child_device_id': null,
      'child_name': null,
    });

    return code;
  }

  // Child enters code to pair
  // Returns the parent UID if successful
  Future<String> pairDevice(
    String code,
    String childName,
    String deviceId,
  ) async {
    final docRef = _firestore.collection('pairing_codes').doc(code);

    // Transaction to ensure atomicity
    return await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);

      if (!snapshot.exists) {
        throw 'Invalid pairing code.';
      }

      final data = snapshot.data();
      if (data == null || data['status'] != 'waiting') {
        throw 'Code is already used or expired.';
      }

      // Update the pairing code status
      transaction.update(docRef, {
        'status': 'paired',
        'child_device_id': deviceId,
        'child_name': childName,
        'paired_at': FieldValue.serverTimestamp(),
      });

      // Also create/update a 'children' subcollection/document under the parent
      // This part depends on how we structure the DB.
      // For now, let's assume we link the child device ID to the parent in a 'children' collection
      final parentUid = data['parent_uid'] as String;

      final childRef = _firestore
          .collection('users')
          .doc(parentUid)
          .collection('children')
          .doc(deviceId);
      transaction.set(childRef, {
        'name': childName,
        'device_id': deviceId,
        'paired_at': FieldValue.serverTimestamp(),
        'last_active': FieldValue.serverTimestamp(),
      });

      return parentUid;
    });
  }
}
