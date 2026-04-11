import 'package:firebase_database/firebase_database.dart';
import '../models/iot_data.dart';
class FirebaseService {
  final DatabaseReference ref =
      FirebaseDatabase.instance.ref().child("iot_data");
  Stream<IoTData> getSensorStream() {
    return ref.onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      return IoTData.fromMap(data);
    });
  }
}
