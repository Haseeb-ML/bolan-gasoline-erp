import 'dart:convert';

import 'package:http/http.dart' as http;

class CloudStateSnapshot {
  const CloudStateSnapshot({
    required this.payloadJson,
    required this.updatedAtMs,
  });

  final String payloadJson;
  final int updatedAtMs;
}

/// Pure-Dart Cloud Firestore REST API sync adapter.
/// Works identically on Web, Windows Desktop, Android & iOS with zero native plugin overhead.
class FirestoreSyncService {
  FirestoreSyncService({
    this.projectId = 'bolan-gasoline-erp',
    this.collection = 'bolan_erp',
    this.documentId = 'main_state',
    this.enabled = true,
  });

  final String projectId;
  final String collection;
  final String documentId;
  final bool enabled;

  Uri get _docUri => Uri.parse(
        'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/$collection/$documentId',
      );

  Future<CloudStateSnapshot?> fetch() async {
    if (!enabled) return null;
    try {
      final res = await http.get(_docUri).timeout(const Duration(seconds: 8));
      if (res.statusCode == 404) return null;
      if (res.statusCode != 200) return null;

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final fields = body['fields'] as Map<String, dynamic>?;
      if (fields == null) return null;

      final payloadField = fields['payload'] as Map<String, dynamic>?;
      final updatedField = fields['updatedAtMs'] as Map<String, dynamic>?;
      final payload = payloadField?['stringValue'] as String?;
      final updatedRaw = updatedField?['integerValue']?.toString();
      if (payload == null || payload.isEmpty) return null;

      return CloudStateSnapshot(
        payloadJson: payload,
        updatedAtMs: int.tryParse(updatedRaw ?? '') ?? 0,
      );
    } catch (_) {
      return null;
    }
  }

  Future<bool> push(String payloadJson, int updatedAtMs) async {
    if (!enabled) return false;
    try {
      final body = jsonEncode({
        'fields': {
          'payload': {'stringValue': payloadJson},
          'updatedAtMs': {'integerValue': updatedAtMs.toString()},
          'app': {'stringValue': 'Bolan Gasoline ERP'},
        },
      });

      final res = await http
          .patch(
            _docUri,
            headers: const {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 10));

      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return false;
    }
  }
}
