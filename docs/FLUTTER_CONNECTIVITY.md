# Flutter Frontend Connectivity Guide

## Backend Configuration

The CivicPulse backend has been configured with CORS support to enable communication with Flutter applications.

### Server Information

- **Backend URL**: `http://localhost:4000`
- **Protocol**: HTTP (for development)
- **MongoDB**: `mongodb://127.0.0.1:27017/civicpulse`

---

## CORS Configuration

### Allowed Origins

The backend accepts requests from the following origins (configured via `CORS_ORIGIN` environment variable):

1. **Flutter Web/Desktop Development**: `http://localhost:3000`, `http://localhost:4000`
2. **Android Emulator**: `http://10.0.2.2:4000`
3. **Physical Android Device**: `http://<YOUR-MAC-LAN-IP>:4000` (e.g., `http://192.168.1.100:4000`)

### Supported Methods

- GET
- POST
- PUT
- PATCH
- DELETE
- OPTIONS (for preflight requests)

### Allowed Headers

- `Content-Type`
- `Authorization`

### Authentication

All authenticated endpoints require:
```
Authorization: Bearer <JWT_TOKEN>
```

---

## Flutter Base URL Configuration

### Connecting from Different Environments

The Flutter app should use different base URLs depending on where it's running:

#### 1. Flutter Web (Chrome/Browser)
```dart
const String baseUrl = 'http://localhost:4000';
```

#### 2. Android Emulator
The Android emulator cannot reach `localhost` of your Mac directly. Use the special IP:
```dart
const String baseUrl = 'http://10.0.2.2:4000';
```

#### 3. Physical Android Device (Same Network)
When testing on a physical device, you need to use your Mac's local network IP address:

**Step 1**: Find your Mac's LAN IP:
```bash
# On macOS terminal:
ifconfig | grep "inet " | grep -v 127.0.0.1
```

Look for something like `192.168.1.x` or `192.168.0.x`

**Step 2**: Use that IP in your Flutter app:
```dart
const String baseUrl = 'http://192.168.1.100:4000'; // Replace with your actual IP
```

**Important**: Make sure both your Mac and Android device are on the same WiFi network.

#### 4. iOS Simulator
iOS Simulator can reach `localhost` directly:
```dart
const String baseUrl = 'http://localhost:4000';
```

#### 5. Physical iOS Device (Same Network)
Same as Android physical device - use your Mac's LAN IP:
```dart
const String baseUrl = 'http://192.168.1.100:4000'; // Replace with your actual IP
```

---

## Recommended Flutter Implementation

### Dynamic Base URL Configuration

Create a configuration file in your Flutter project:

```dart
// lib/config/api_config.dart

import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  // Development base URLs
  static const String _webBaseUrl = 'http://localhost:4000';
  static const String _androidEmulatorBaseUrl = 'http://10.0.2.2:4000';
  static const String _iosBaseUrl = 'http://localhost:4000';
  
  // TODO: Replace with your Mac's actual LAN IP when testing on physical devices
  static const String _physicalDeviceBaseUrl = 'http://192.168.1.100:4000';

  /// Get the appropriate base URL based on the platform and environment
  static String get baseUrl {
    if (kIsWeb) {
      return _webBaseUrl;
    }
    
    if (Platform.isAndroid) {
      // Check if running on emulator or physical device
      // For development, you might want to make this configurable
      return _androidEmulatorBaseUrl; // Change to _physicalDeviceBaseUrl for physical device
    }
    
    if (Platform.isIOS) {
      return _iosBaseUrl; // Change to _physicalDeviceBaseUrl for physical device
    }
    
    return _webBaseUrl;
  }
  
  // API endpoints
  static const String authRegister = '/api/auth/register';
  static const String authLogin = '/api/auth/login';
  static const String issuesMyIssues = '/api/issues/my-issues';
  static const String services = '/api/services';
  static const String notifications = '/api/notifications';
  // ... add more endpoints as needed
}
```

### Example HTTP Service

```dart
// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiService {
  final String _baseUrl = ApiConfig.baseUrl;
  String? _token;

  void setToken(String token) {
    _token = token;
  }

  Map<String, String> _getHeaders({bool includeAuth = true}) {
    final headers = {
      'Content-Type': 'application/json',
    };

    if (includeAuth && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }

    return headers;
  }

  Future<http.Response> get(String endpoint, {bool requireAuth = true}) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    return await http.get(url, headers: _getHeaders(includeAuth: requireAuth));
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> body, {bool requireAuth = false}) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    return await http.post(
      url,
      headers: _getHeaders(includeAuth: requireAuth),
      body: json.encode(body),
    );
  }

  // Example: Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await post(
      ApiConfig.authLogin,
      {'email': email, 'password': password},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _token = data['token'];
      return data;
    } else {
      throw Exception('Login failed: ${response.body}');
    }
  }

  // Example: Get my issues
  Future<List<dynamic>> getMyIssues() async {
    final response = await get(ApiConfig.issuesMyIssues);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['issues'];
    } else {
      throw Exception('Failed to load issues');
    }
  }
}
```

---

## Testing CORS from Flutter

### Quick Test

You can test the connection from Flutter with this simple snippet:

```dart
import 'package:http/http.dart' as http;

Future<void> testBackendConnection() async {
  try {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:4000/'), // Adjust URL as needed
    );
    
    if (response.statusCode == 200) {
      print('✅ Backend connection successful!');
      print('Response: ${response.body}');
    } else {
      print('❌ Backend returned status: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ Connection failed: $e');
  }
}
```

---

## Important Notes

### Security

1. **JWT Tokens**: All authenticated endpoints require a valid JWT token in the `Authorization` header
2. **Never expose tokens**: Store tokens securely using `flutter_secure_storage` or similar
3. **Production**: This CORS configuration is for development only. Production should use proper HTTPS and specific origins

### Multipart Form Data

The backend supports `multipart/form-data` for file uploads (civic issue images, resolution evidence). Use the `http` or `dio` package to send multipart requests:

```dart
import 'package:http/http.dart' as http;
import 'dart:io';

Future<void> uploadImage(File imageFile, String token) async {
  final request = http.MultipartRequest(
    'POST',
    Uri.parse('${ApiConfig.baseUrl}/api/issues'),
  );
  
  request.headers['Authorization'] = 'Bearer $token';
  request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
  
  final response = await request.send();
  // Handle response...
}
```

### Error Handling

The backend returns appropriate HTTP status codes:
- `200`: Success
- `201`: Created
- `400`: Bad Request (validation errors)
- `401`: Unauthorized (missing/invalid token)
- `403`: Forbidden (insufficient permissions)
- `404`: Not Found
- `409`: Conflict (e.g., duplicate email)
- `500`: Server Error

---

## Troubleshooting

### Connection Refused

**Problem**: Cannot connect to backend from Android emulator

**Solution**: 
- Use `http://10.0.2.2:4000` instead of `http://localhost:4000`
- Make sure backend is running: `npm run dev`
- Check backend is listening on port 4000

### CORS Error

**Problem**: "CORS policy blocked" error

**Solution**:
- Verify the origin is in the `CORS_ORIGIN` list in backend `.env`
- For physical devices, add your Mac's LAN IP to `CORS_ORIGIN`
- Restart the backend after changing `.env`

### Network Error on Physical Device

**Problem**: Cannot connect from physical device

**Solution**:
1. Find your Mac's IP: `ifconfig | grep "inet " | grep -v 127.0.0.1`
2. Make sure Mac and device are on same WiFi network
3. Update Flutter app to use Mac's IP: `http://192.168.x.x:4000`
4. Add that IP to backend's `CORS_ORIGIN` in `.env`
5. Restart backend

### Timeout Issues

**Problem**: Requests timeout

**Solution**:
- Increase timeout in Flutter HTTP client
- Check Mac firewall settings (System Preferences > Security > Firewall)
- Ensure backend MongoDB is running

---

## Production Considerations

When deploying to production:

1. **Use HTTPS**: Deploy backend with SSL/TLS certificates
2. **Update CORS**: Set `CORS_ORIGIN` to your production Flutter web domain
3. **Environment Variables**: Use different base URLs for dev/staging/production
4. **API Security**: Implement rate limiting, API key validation
5. **Token Refresh**: Implement refresh token logic for long-lived sessions

---

## Backend Status

Current status: ✅ CORS configured and tested
- Preflight requests: ✅ Working
- Authorization headers: ✅ Accepted
- JSON requests: ✅ Working
- Multipart uploads: ✅ Supported
- Authentication: ✅ Enforced

---

## Next Steps

1. Create Flutter project
2. Install dependencies: `http` or `dio` package
3. Configure base URL based on your development environment
4. Implement authentication flow (register/login)
5. Test API calls
6. Build your UI

For questions or issues, refer to the backend test scripts in the `/backend` directory.
