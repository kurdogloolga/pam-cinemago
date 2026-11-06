import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

class ApiResponse {
  const ApiResponse(this.statusCode, this.headers, this.body);

  final int statusCode;
  final HttpHeaders headers;
  final Uint8List body;

  String get text => utf8.decode(body, allowMalformed: true);

  Map<String, dynamic>? get json {
    try {
      final decoded = jsonDecode(text);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }
}

class ConformanceRunner {
  ConformanceRunner(this.baseUrl);

  final String baseUrl;
  final HttpClient _client = HttpClient();
  int _passed = 0;
  int _failed = 0;

  String? _token;
  int? _noteId;
  int? _fileId;
  Map<String, dynamic>? _fileMetadata;
  String? _email;
  String? _fileText;

  Future<ApiResponse> _request(
    String method,
    String path, {
    Object? jsonBody,
    String? rawBody,
    Map<String, String> headers = const {},
    Uint8List? bytes,
  }) async {
    final request = await _client.openUrl(
      method,
      Uri.parse('$baseUrl$path'),
    );
    headers.forEach(request.headers.set);
    if (jsonBody != null) {
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(jsonBody));
    }
    if (rawBody != null) {
      request.headers.contentType = ContentType.json;
      request.write(rawBody);
    }
    if (bytes != null) request.add(bytes);
    final response = await request.close();
    final responseBytes = await response.fold<BytesBuilder>(
      BytesBuilder(copy: false),
      (builder, chunk) => builder..add(chunk),
    );
    return ApiResponse(
        response.statusCode, response.headers, responseBytes.takeBytes());
  }

  Future<ApiResponse> _upload(String boundary, String text) async {
    final headers = {'Authorization': 'Bearer $_token'};
    final content = [
      '--$boundary',
      'Content-Disposition: form-data; name="file"; filename="conformance.txt"',
      'Content-Type: text/plain',
      '',
      text,
      '--$boundary--',
      '',
    ].join('\r\n');
    final request = await _client.openUrl(
      'POST',
      Uri.parse('$baseUrl/files'),
    );
    headers.forEach(request.headers.set);
    request.headers.set(
      HttpHeaders.contentTypeHeader,
      'multipart/form-data; boundary=$boundary',
    );
    request.write(content);
    final response = await request.close();
    final responseBytes = await response.fold<BytesBuilder>(
      BytesBuilder(copy: false),
      (builder, chunk) => builder..add(chunk),
    );
    return ApiResponse(
        response.statusCode, response.headers, responseBytes.takeBytes());
  }

  Future<void> check(String description, Future<bool> Function() test) async {
    try {
      if (await test()) {
        _passed++;
        stdout.writeln('✓ $description');
      } else {
        _failed++;
        stderr.writeln('✗ $description');
      }
    } on Object catch (error) {
      _failed++;
      stderr.writeln('✗ $description ($error)');
    }
  }

  Future<int> run() async {
    final stamp = DateTime.now().microsecondsSinceEpoch;
    _email = 'cinemago-$stamp@example.test';
    final password = 'Test-pass-$stamp';
    final noteTitle = 'CinemaGo conformance $stamp';
    final noteContent = 'backend contract check $stamp';
    _fileText = 'CinemaGo backend upload check $stamp';
    final authHeaders = () => {'Authorization': 'Bearer $_token'};

    await check('GET /health responds with 200', () async {
      final response = await _request('GET', '/health');
      return response.statusCode == 200;
    });
    await check('GET /health returns status=ok', () async {
      final response = await _request('GET', '/health');
      return response.json?['status'] == 'ok';
    });
    await check('unknown route responds with 404', () async {
      final response = await _request('GET', '/conformance-missing-route');
      return response.statusCode == 404;
    });
    await check('unknown route uses the standard NOT_FOUND error envelope',
        () async {
      final response = await _request('GET', '/conformance-missing-route');
      return response.json?['error']?['code'] == 'NOT_FOUND';
    });
    await check('GET /notes rejects requests without a token', () async {
      final response = await _request('GET', '/notes');
      return response.statusCode == 401;
    });
    await check('unauthorized response uses the standard error envelope',
        () async {
      final response = await _request('GET', '/notes');
      return response.json?['error']?['code'] == 'UNAUTHORIZED';
    });
    await check('GET /me rejects requests without a token', () async {
      final response = await _request('GET', '/me');
      return response.statusCode == 401;
    });
    await check('registration rejects an invalid email', () async {
      final response = await _request('POST', '/auth/register', jsonBody: {
        'email': 'not-an-email',
        'password': password,
        'name': 'CinemaGo Test',
      });
      return response.statusCode == 400;
    });
    await check('invalid registration uses VALIDATION_ERROR', () async {
      final response = await _request('POST', '/auth/register', jsonBody: {
        'email': 'not-an-email',
        'password': password,
        'name': 'CinemaGo Test',
      });
      return response.json?['error']?['code'] == 'VALIDATION_ERROR';
    });
    await check('registration requires a name', () async {
      final response = await _request('POST', '/auth/register', jsonBody: {
        'email': _email,
        'password': password,
      });
      return response.statusCode == 400;
    });
    await check('valid registration responds with 201', () async {
      final response = await _request('POST', '/auth/register', jsonBody: {
        'email': _email,
        'password': password,
        'name': 'CinemaGo Test',
      });
      _token = response.json?['token'] as String?;
      return response.statusCode == 201;
    });
    await check('registration returns a three-part JWT', () async {
      return (_token?.split('.').length ?? 0) == 3;
    });
    await check('registration returns the created user identity', () async {
      final response = await _request('POST', '/auth/login', jsonBody: {
        'email': _email,
        'password': password,
      });
      final user = response.json?['user'];
      return user is Map<String, dynamic> &&
          user['email'] == _email &&
          user['name'] == 'CinemaGo Test';
    });
    await check('duplicate registration responds with 409', () async {
      final response = await _request('POST', '/auth/register', jsonBody: {
        'email': _email,
        'password': password,
        'name': 'CinemaGo Test',
      });
      return response.statusCode == 409;
    });
    await check('duplicate registration uses EMAIL_TAKEN', () async {
      final response = await _request('POST', '/auth/register', jsonBody: {
        'email': _email,
        'password': password,
        'name': 'CinemaGo Test',
      });
      return response.json?['error']?['code'] == 'EMAIL_TAKEN';
    });
    await check('valid login responds with 200', () async {
      final response = await _request('POST', '/auth/login', jsonBody: {
        'email': _email,
        'password': password,
      });
      _token = response.json?['token'] as String?;
      return response.statusCode == 200;
    });
    await check('login returns a three-part JWT', () async {
      return (_token?.split('.').length ?? 0) == 3;
    });
    await check('login rejects an incorrect password', () async {
      final response = await _request('POST', '/auth/login', jsonBody: {
        'email': _email,
        'password': 'incorrect-$password',
      });
      return response.statusCode == 401;
    });
    await check('incorrect login uses UNAUTHORIZED', () async {
      final response = await _request('POST', '/auth/login', jsonBody: {
        'email': _email,
        'password': 'incorrect-$password',
      });
      return response.json?['error']?['code'] == 'UNAUTHORIZED';
    });
    await check('GET /me accepts the issued token', () async {
      final response = await _request('GET', '/me', headers: authHeaders());
      return response.statusCode == 200;
    });
    await check('GET /me returns the authenticated user', () async {
      final response = await _request('GET', '/me', headers: authHeaders());
      return response.json?['email'] == _email;
    });
    await check('GET /notes accepts the issued token', () async {
      final response = await _request('GET', '/notes', headers: authHeaders());
      return response.statusCode == 200;
    });
    await check('GET /notes returns the paginated envelope', () async {
      final response = await _request('GET', '/notes', headers: authHeaders());
      final data = response.json;
      return data?['items'] is List &&
          data?['page'] == 1 &&
          data?['limit'] == 20 &&
          data?['total'] is int;
    });
    await check('POST /notes creates a note with 201', () async {
      final response = await _request(
        'POST',
        '/notes',
        headers: authHeaders(),
        jsonBody: {'title': noteTitle, 'content': noteContent},
      );
      _noteId = response.json?['id'] as int?;
      return response.statusCode == 201;
    });
    await check('created note has a server id and submitted fields', () async {
      final response = await _request(
        'GET',
        '/notes/$_noteId',
        headers: authHeaders(),
      );
      final data = response.json;
      return _noteId != null &&
          data?['id'] == _noteId &&
          data?['title'] == noteTitle &&
          data?['content'] == noteContent;
    });
    await check('notes list includes the created note', () async {
      final response = await _request('GET', '/notes', headers: authHeaders());
      final items = response.json?['items'];
      return items is List &&
          items.any((item) => item is Map && item['id'] == _noteId);
    });
    await check('pagination returns the requested page and limit', () async {
      final response = await _request(
        'GET',
        '/notes?page=1&limit=1',
        headers: authHeaders(),
      );
      final data = response.json;
      return data?['page'] == 1 && data?['limit'] == 1 && data?['total'] is int;
    });
    await check('server-side search finds the matching note', () async {
      final uri = Uri.parse('$baseUrl/notes').replace(
        queryParameters: {'search': noteTitle},
      );
      final response = await _request(
        'GET',
        '${uri.path}${uri.hasQuery ? '?${uri.query}' : ''}',
        headers: authHeaders(),
      );
      final items = response.json?['items'];
      return items is List &&
          items.any((item) => item is Map && item['id'] == _noteId);
    });
    await check('server-side search excludes non-matching notes', () async {
      final response = await _request(
        'GET',
        '/notes?search=definitely-no-match-$stamp',
        headers: authHeaders(),
      );
      final data = response.json;
      return response.statusCode == 200 &&
          data?['items'] is List &&
          (data!['items'] as List).isEmpty &&
          data['total'] == 0;
    });
    await check('GET /notes/{id} returns the requested note', () async {
      final response = await _request(
        'GET',
        '/notes/$_noteId',
        headers: authHeaders(),
      );
      return response.statusCode == 200 && response.json?['id'] == _noteId;
    });
    await check('PUT /notes/{id} updates a note', () async {
      final response = await _request(
        'PUT',
        '/notes/$_noteId',
        headers: authHeaders(),
        jsonBody: {'title': '$noteTitle updated', 'content': 'updated content'},
      );
      return response.statusCode == 200;
    });
    await check('updated note returns the updated values', () async {
      final response = await _request(
        'GET',
        '/notes/$_noteId',
        headers: authHeaders(),
      );
      return response.json?['title'] == '$noteTitle updated' &&
          response.json?['content'] == 'updated content';
    });
    await check('PUT /notes/{id} validates the title', () async {
      final response = await _request(
        'PUT',
        '/notes/$_noteId',
        headers: authHeaders(),
        jsonBody: {'title': '  ', 'content': 'invalid'},
      );
      return response.statusCode == 400 &&
          response.json?['error']?['code'] == 'VALIDATION_ERROR';
    });
    await check('GET missing note responds with standard 404', () async {
      final response = await _request(
        'GET',
        '/notes/9223372036854775807',
        headers: authHeaders(),
      );
      return response.statusCode == 404 &&
          response.json?['error']?['code'] == 'NOT_FOUND';
    });
    await check('DELETE /notes/{id} responds with 204', () async {
      final response = await _request(
        'DELETE',
        '/notes/$_noteId',
        headers: authHeaders(),
      );
      return response.statusCode == 204 && response.body.isEmpty;
    });
    await check('deleted note is no longer available', () async {
      final response = await _request(
        'GET',
        '/notes/$_noteId',
        headers: authHeaders(),
      );
      return response.statusCode == 404 &&
          response.json?['error']?['code'] == 'NOT_FOUND';
    });
    await check('POST /files rejects requests without a token', () async {
      final response = await _request('POST', '/files');
      return response.statusCode == 401;
    });
    await check('POST /files requires multipart form data', () async {
      final response = await _request(
        'POST',
        '/files',
        headers: authHeaders(),
        jsonBody: {'name': 'conformance.txt'},
      );
      return response.statusCode == 400 &&
          response.json?['error']?['code'] == 'VALIDATION_ERROR';
    });
    await check('multipart upload responds with 201', () async {
      final response = await _upload('cinemago-$stamp', _fileText!);
      _fileId = response.json?['id'] as int?;
      _fileMetadata = response.json;
      return response.statusCode == 201;
    });
    await check('upload returns file metadata and a relative URL', () async {
      return _fileMetadata?['id'] == _fileId &&
          _fileMetadata?['url'] == '/files/$_fileId' &&
          _fileMetadata?['name'] == 'conformance.txt' &&
          _fileMetadata?['size'] == utf8.encode(_fileText!).length &&
          _fileMetadata?['mimeType'] == 'text/plain';
    });
    await check('GET /files/{id} returns the uploaded bytes', () async {
      final response = await _request('GET', '/files/$_fileId');
      return _fileId != null &&
          response.statusCode == 200 &&
          response.text == _fileText &&
          response.headers.contentType?.mimeType == 'text/plain';
    });
    await check('file download includes safe download headers', () async {
      final response = await _request('GET', '/files/$_fileId');
      return response.headers.value('content-disposition') == 'attachment' &&
          response.headers.value('x-content-type-options') == 'nosniff' &&
          response.headers.value('content-security-policy') ==
              "default-src 'none'; sandbox";
    });
    await check('GET missing file responds with standard 404', () async {
      final response = await _request('GET', '/files/9223372036854775807');
      return response.statusCode == 404 &&
          response.json?['error']?['code'] == 'NOT_FOUND';
    });
    await check('malformed JSON returns a contract-shaped 400', () async {
      final response = await _request(
        'POST',
        '/notes',
        headers: authHeaders(),
        rawBody: '{invalid json',
      );
      return response.statusCode == 400 &&
          response.json?['error']?['code'] == 'VALIDATION_ERROR' &&
          response.json?['error']?['message'] is String;
    });

    _client.close(force: true);
    stdout.writeln('');
    stdout.writeln(
        '$_passed passed; $_failed failed; ${_passed + _failed} total.');
    if (_failed == 0) {
      stdout.writeln(
          'PASS — ${_passed}/${_passed + _failed} local checks passed.');
      return 0;
    }
    stderr.writeln('FAIL — $_failed local check(s) failed.');
    return 1;
  }
}

Future<void> main(List<String> args) async {
  final baseUrlIndex = args.indexOf('--base-url');
  if (baseUrlIndex < 0 ||
      baseUrlIndex + 1 >= args.length ||
      args[baseUrlIndex + 1].startsWith('--')) {
    stderr.writeln(
      'Usage: dart run bin/conformance.dart --base-url http://localhost:8080',
    );
    exitCode = 64;
    return;
  }

  final baseUrl = args[baseUrlIndex + 1].replaceFirst(RegExp(r'/$'), '');
  exitCode = await ConformanceRunner(baseUrl).run();
}
