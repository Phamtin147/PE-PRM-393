import 'dart:convert';
import 'dart:io';

/// Script tự động làm sạch Firestore Database cho tài khoản chấm thi
/// Sử dụng trực tiếp Firebase REST API với truy vấn có filter userId, tuân thủ đúng Firestore Security Rules.
///
/// Cách dùng:
///   dart run tool/clean_firebase.dart [collectionName]
/// Mặc định collectionName là 'books'.

const String apiKey = 'AIzaSyAr35bKVlcB_DoIxHqjum28ANbMs-X3OFE';
const String projectId = 'pe-prn-393';
const String defaultEmail = 'grader.qe190087@example.com';
const String defaultPassword = 'Test1234!';

Future<void> main(List<String> args) async {
  final collection = args.isNotEmpty ? args[0] : 'books';
  final email = args.length > 1 ? args[1] : defaultEmail;
  final password = args.length > 2 ? args[2] : defaultPassword;

  stdout.writeln('==============================================');
  stdout.writeln('CLEAN FIREBASE DATABASE TOOL (PRM EXAM)');
  stdout.writeln('Project: $projectId');
  stdout.writeln('Collection to clean: $collection');
  stdout.writeln('User: $email');
  stdout.writeln('==============================================\n');

  final client = HttpClient();

  try {
    // 1. Đăng nhập để lấy ID Token và UID
    stdout.write('1. Authenticating test account... ');
    final authUri = Uri.parse(
        'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$apiKey');
    final authRequest = await client.postUrl(authUri);
    authRequest.headers.contentType = ContentType.json;
    authRequest.write(jsonEncode({
      'email': email,
      'password': password,
      'returnSecureToken': true,
    }));

    final authResponse = await authRequest.close();
    final authBody = await authResponse.transform(utf8.decoder).join();
    final authData = jsonDecode(authBody) as Map<String, dynamic>;

    if (authResponse.statusCode != 200) {
      stderr.writeln('\n❌ Authentication failed: ${authData['error']?['message'] ?? authBody}');
      exitCode = 1;
      return;
    }

    final idToken = authData['idToken'] as String;
    final uid = authData['localId'] as String;
    stdout.writeln('OK! (UID: $uid)');

    // 2. Chạy structured query với filter userId == uid (đáp ứng đúng Firestore Security Rules)
    stdout.write('2. Querying documents in collection "$collection" for user $uid... ');
    final queryUri = Uri.parse(
        'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents:runQuery');
    final queryRequest = await client.postUrl(queryUri);
    queryRequest.headers.contentType = ContentType.json;
    queryRequest.headers.set(HttpHeaders.authorizationHeader, 'Bearer $idToken');
    queryRequest.write(jsonEncode({
      'structuredQuery': {
        'from': [
          {'collectionId': collection}
        ],
        'where': {
          'fieldFilter': {
            'field': {'fieldPath': 'userId'},
            'op': 'EQUAL',
            'value': {'stringValue': uid}
          }
        }
      }
    }));

    final queryResponse = await queryRequest.close();
    final queryBody = await queryResponse.transform(utf8.decoder).join();
    final queryResults = jsonDecode(queryBody) as List<dynamic>;

    final List<String> docPathsToDelete = [];
    for (final res in queryResults) {
      if (res is Map<String, dynamic> && res.containsKey('document')) {
        final doc = res['document'] as Map<String, dynamic>;
        final docName = doc['name'] as String;
        docPathsToDelete.add(docName);
      }
    }

    stdout.writeln('Found ${docPathsToDelete.length} document(s).');

    if (docPathsToDelete.isEmpty) {
      stdout.writeln('✨ Collection "$collection" for this user is already clean.');
      return;
    }

    // 3. Xóa từng document
    stdout.writeln('3. Deleting documents...');
    int deletedCount = 0;
    for (final docName in docPathsToDelete) {
      final deleteUri = Uri.parse('https://firestore.googleapis.com/v1/$docName');
      final deleteRequest = await client.deleteUrl(deleteUri);
      deleteRequest.headers.set(HttpHeaders.authorizationHeader, 'Bearer $idToken');

      final deleteResponse = await deleteRequest.close();
      if (deleteResponse.statusCode == 200 || deleteResponse.statusCode == 204) {
        deletedCount++;
        stdout.writeln('   - Deleted: ${docName.split('/').last}');
      } else {
        final err = await deleteResponse.transform(utf8.decoder).join();
        stderr.writeln('   ⚠️ Failed to delete ${docName.split('/').last}: $err');
      }
    }

    stdout.writeln('\n✅ Done! Successfully deleted $deletedCount/${docPathsToDelete.length} documents.');
    stdout.writeln('🎉 Firestore collection "$collection" is completely clean for the next exam.');
  } finally {
    client.close();
  }
}
