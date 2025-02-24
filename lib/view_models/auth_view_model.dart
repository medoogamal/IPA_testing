import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mstra/models/login_response_model.dart';
import 'package:mstra/models/user_model_auth.dart';
import 'package:mstra/res/app_url.dart';
import 'package:mstra/routes/routes_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:device_info_plus/device_info_plus.dart';

class AuthViewModel with ChangeNotifier {
  User? _user;
  String? _accessToken;
  String? _userRole;
  bool _isLoading = false; // Loading state

  User? get user => _user;
  String? get accessToken => _accessToken;
  String? get userRole => _userRole;
  bool get isLoading => _isLoading; // Getter for loading state

  // Set loading state and notify listeners
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<String?> getAndroidId() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    return androidInfo.id; // Returns the Android ID
  }

  // Login with loading indicator
  Future<void> login({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    setLoading(true); // Start loading

    try {
      String? androidId = await getAndroidId();
      final url = Uri.parse(AppUrl.loginEndPoint);
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json', // Ensure the content type is JSON
        },
        body: json.encode({
          'email': email,
          'password': password,
          "ip_adress": androidId,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final loginResponse = LoginResponse.fromJson(responseData);

        // Extract data
        final createdCourses =
            responseData['data']['created_courses'] as List<dynamic>;
        final purchasedCourses =
            responseData['data']['purchased_courses'] as List<dynamic>;

        _userRole = responseData['data']['role'];
        _user = loginResponse.user;
        _accessToken = loginResponse.accessToken;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', _accessToken!);
        await prefs.setInt('id', _user!.id ?? 0);
        await prefs.setString('name', _user!.name);
        await prefs.setString('email', _user!.email);
        await prefs.setString('phone', _user!.phone);
        await prefs.setString('user_image', _user!.image ?? "");
        await prefs.setString('role', _userRole ?? "");

        // Save created_courses and purchased_courses as JSON strings
        await prefs.setString('created_courses', json.encode(createdCourses));
        await prefs.setString(
            'purchased_courses', json.encode(purchasedCourses));

        // Display a success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login successful'),
            backgroundColor: Colors.green,
          ),
        );

        notifyListeners();
        Navigator.pushReplacementNamed(context, RoutesManager.homePage);
      } else {
        final responseData = json.decode(response.body);
        final errorMessage = responseData['message'] ?? 'Unknown error';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(errorMessage), // Display the exact message from the API
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setLoading(false); // End loading
    }
  }

  // Future<void> register({
  //   required String name,
  //   required String email,
  //   required String phone,
  //   required String password,
  //   required String passwordConfirmation,
  //   required BuildContext context,
  //   File? imageFile, // Add this parameter
  // }) async {
  //   setLoading(true); // Start loading

  //   try {
  //     String? androidId = await getAndroidId();
  //     final url = Uri.parse(AppUrl.registerEndPoint);

  //     final request = http.MultipartRequest('POST', url)
  //       ..headers['Content-Type'] = 'multipart/form-data'
  //       ..fields['name'] = name
  //       ..fields['email'] = email
  //       ..fields['phone'] = phone
  //       ..fields['password'] = password
  //       ..fields['password_confirmation'] = passwordConfirmation
  //       ..fields['ip_adress'] = androidId!;

  //     if (imageFile != null) {
  //       request.files.add(
  //         await http.MultipartFile.fromPath('image', imageFile.path),
  //       );
  //     }

  //     final response = await request.send();

  //     final responseBody = await response.stream.bytesToString();
  //     if (response.statusCode == 200) {
  //       final Map<String, dynamic> responseData = json.decode(responseBody);
  //       final loginResponse = LoginResponse.fromJson(responseData);
  //       _userRole = responseData['data']['role'];

  //       _user = loginResponse.user;
  //       _accessToken = loginResponse.accessToken;
  //       notifyListeners();
  //       Navigator.pushReplacementNamed(context, RoutesManager.homePage);

  //       final prefs = await SharedPreferences.getInstance();
  //       await prefs.setString('access_token', _accessToken!);
  //       await prefs.setInt('id', _user!.id ?? 0);
  //       await prefs.setString('name', _user!.name);
  //       await prefs.setString('email', _user!.email);
  //       await prefs.setString('phone', _user!.phone);
  //       await prefs.setString('user_image', _user!.image ?? "");
  //       await prefs.setString('role', _userRole ?? "");
  //     } else {
  //       final responseData = json.decode(responseBody);

  //       final errorMessage = responseData['message'] ?? 'Unknown error';
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content:
  //               Text(errorMessage), // Display the exact message from the API
  //           backgroundColor: Colors.red,
  //         ),
  //       );
  //     }
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('An error occurred: $e'),
  //         backgroundColor: Colors.red,
  //       ),
  //     );
  //   } finally {
  //     setLoading(false); // End loading
  //   }
  // }

  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
    required BuildContext context,
    File? imageFile,
  }) async {
    setLoading(true);

    try {
      String? androidId = await getAndroidId();
      final url = Uri.parse(AppUrl.registerEndPoint);

      // Create a new HTTP client to disable automatic redirects
      final http.Client client = http.Client();
      final request = http.MultipartRequest('POST', url)
        ..headers['Content-Type'] = 'multipart/form-data'
        ..fields['name'] = name
        ..fields['email'] = email
        ..fields['phone'] = phone
        ..fields['password'] = password
        ..fields['password_confirmation'] = passwordConfirmation
        ..fields['ip_adress'] = androidId!;

      if (imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image', imageFile.path),
        );
      }

      // Send the request without automatic redirection handling
      final response = await client.send(request);
      final responseBody = await response.stream.bytesToString();

      print("Response Status: ${response.statusCode}");
      print("Response Body: ${responseBody.substring(0, 200)}");

      // Check for 200 status code, meaning success
      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> responseData = json.decode(responseBody);
          final loginResponse = LoginResponse.fromJson(responseData);
          _userRole = responseData['data']['role'];

          _user = loginResponse.user;
          _accessToken = loginResponse.accessToken;
          notifyListeners();
          Navigator.pushReplacementNamed(context, RoutesManager.homePage);

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('access_token', _accessToken!);
          await prefs.setInt('id', _user!.id ?? 0);
          await prefs.setString('name', _user!.name);
          await prefs.setString('email', _user!.email);
          await prefs.setString('phone', _user!.phone);
          await prefs.setString('user_image', _user!.image ?? "");
          await prefs.setString('role', _userRole ?? "");
        } catch (e) {
          print('Error parsing JSON: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to parse server response.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else if (response.statusCode == 422 || response.statusCode == 302) {
        // Handle specific errors like "username already exists"
        try {
          final Map<String, dynamic> responseData = json.decode(responseBody);
          final errorMessage = responseData['message'] ?? 'Unknown error';

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('البريد الالكترونى مسجل بالفعل'),
              backgroundColor: Colors.red,
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('البريد الالكترونى مسجل بالفعل'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // Handle other non-200 responses
        print('Unexpected response status: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed. Please try again later.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // General error handling
      print('Exception occurred: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setLoading(false);
    }
  }

  // Logout with loading indicator
  Future<void> logout(BuildContext context) async {
    setLoading(true); // Start loading

    try {
      final prefs = await SharedPreferences.getInstance();
      _accessToken = prefs.getString('access_token');

      if (_accessToken != null) {
        final url = Uri.parse(AppUrl.logoutEndPoint);
        final response = await http.post(
          url,
          headers: {
            'Authorization': 'Bearer $_accessToken',
          },
        );

        if (response.statusCode == 200) {
          _user = null;
          _accessToken = null;
          await prefs.clear(); // Clear all preferences
          print(
              "=============================================================logedout success");
          notifyListeners();
          Navigator.pushReplacementNamed(context, RoutesManager.homePage);
        } else {
          throw Exception('Failed to log out');
        }
      } else {
        // notifyListeners();
        Navigator.pushReplacementNamed(context, RoutesManager.homePage);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setLoading(false); // End loading
    }
  }
  // Future<void> logout(BuildContext context) async {
  //   setLoading(true); // Start loading

  //   try {
  //     final prefs = await SharedPreferences.getInstance();
  //     _accessToken = prefs.getString('access_token');

  //     // Clear preferences and reset user regardless of token status
  //     // _user = null;
  //     // _accessToken = null;
  //     // await prefs.clear(); // Clear all preferences

  //     // Check if the token exists, then attempt a server-side logout
  //     if (_accessToken != null) {
  //       final url = Uri.parse(AppUrl.logoutEndPoint);
  //       final response = await http.post(
  //         url,
  //         headers: {
  //           'Authorization': 'Bearer $_accessToken',
  //         },
  //       );

  //       // If logout is successful, navigate to the home page
  //       if (response.statusCode == 200) {
  //         final responseData = json.decode(response.body);
  //         final message = responseData['message'] ?? 'Logged out successfully';
  //         print(
  //             "=======================================================================loggedout success");
  //         // Show success message in a SnackBar
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(
  //             content: Text(message),
  //             backgroundColor: Colors.green,
  //           ),
  //         );
  //         notifyListeners();
  //         Navigator.pushReplacementNamed(context, RoutesManager.homePage);
  //       } else {
  //         throw Exception('Failed to log out from the server');
  //       }
  //     } else {
  //       // No access token found (already logged out), navigate to home page
  //       // Navigator.pushReplacementNamed(context, RoutesManager.homePage);
  //     }
  //   } catch (e) {
  //     // Show error message in case of any issues
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('An error occurred: $e'),
  //         backgroundColor: Colors.red,
  //       ),
  //     );
  //   } finally {
  //     setLoading(false); // End loading
  //   }
  // }

  Future<void> loadAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
    if (_accessToken != null) {
      _user = User(
        id: prefs.getInt('id') ?? 0,
        name: prefs.getString('name') ?? '',
        email: prefs.getString('email') ?? '',
        phone: prefs.getString('phone') ?? "",
        image: prefs.getString('image'),
        emailVerifiedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        password: '',
        passwordConfirmation: '',
      );

      notifyListeners();
    }
  }

  void updateUser(User updatedUser) {
    _user = updatedUser;

    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt('id', _user!.id ?? 0);
      prefs.setString('name', _user!.name);
      prefs.setString('email', _user!.email);
      prefs.setString('phone', _user!.phone);
      prefs.setString('image', _user!.image ?? "");
    });

    notifyListeners();
  }
}

// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:mstra/models/login_response_model.dart';
// import 'package:mstra/models/user_model_auth.dart';
// import 'package:mstra/res/app_url.dart';
// import 'package:mstra/routes/routes_manager.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:device_info_plus/device_info_plus.dart';

// class AuthViewModel with ChangeNotifier {
//   User? _user;
//   String? _accessToken;
//   String? _userRole;

//   User? get user => _user;
//   String? get accessToken => _accessToken;
//   String? get userRole => _userRole;

//   Future<String?> getAndroidId() async {
//     DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
//     AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
//     return androidInfo.id; // Returns the Android ID
//   }

//   Future<void> login({
//     required String email,
//     required String password,
//     required BuildContext context,
//   }) async {
//     String? androidId = await getAndroidId();
//     final url = Uri.parse(AppUrl.loginEndPoint);
//     final response = await http.post(
//       url,
//       headers: {
//         'Content-Type': 'application/json', // Ensure the content type is JSON
//       },
//       body: json.encode({
//         'email': email,
//         'password': password,
//         "ip_adress": androidId,
//       }),
//     );

//     print('Response status: ${response.statusCode}');
//     print('Response body: ${response.body}');

//     if (response.statusCode == 200) {
//       final Map<String, dynamic> responseData = json.decode(response.body);
//       final loginResponse = LoginResponse.fromJson(responseData);

//       // Extract data
//       final createdCourses =
//           responseData['data']['created_courses'] as List<dynamic>;
//       final purchasedCourses =
//           responseData['data']['purchased_courses'] as List<dynamic>;

//       _userRole = responseData['data']['role'];
//       _user = loginResponse.user;
//       _accessToken = loginResponse.accessToken;

//       final prefs = await SharedPreferences.getInstance();
//       await prefs.setString('access_token', _accessToken!);
//       await prefs.setInt('id', _user!.id ?? 0);
//       await prefs.setString('name', _user!.name);
//       await prefs.setString('email', _user!.email);
//       await prefs.setString('phone', _user!.phone);
//       await prefs.setString('user_image', _user!.image ?? "");
//       await prefs.setString('role', _userRole ?? "");

//       // Save created_courses and purchased_courses as JSON strings
//       await prefs.setString('created_courses', json.encode(createdCourses));
//       await prefs.setString('purchased_courses', json.encode(purchasedCourses));

//       // Display a success message
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Login successful'),
//           backgroundColor: Colors.green,
//         ),
//       );

//       notifyListeners();
//       Navigator.pushReplacementNamed(context, RoutesManager.homePage);
//     } else {
//       final responseData = json.decode(response.body);
//       final errorMessage = responseData['message'] ?? 'Unknown error';

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(errorMessage), // Display the exact message from the API
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

//   // Future<void> login({
//   //   required String email,
//   //   required String password,
//   //   required BuildContext context,
//   // }) async {
//   //   final url = Uri.parse(AppUrl.loginEndPoint);
//   //   final response = await http.post(url,
//   //       headers: {
//   //         'Content-Type': 'application/json', // Ensure the content type is JSON
//   //       },
//   //       body: json.encode({
//   //         'email': email,
//   //         'password': password,
//   //       }));

//   //   print('Response status: ${response.statusCode}');
//   //   print('Response body: ${response.body}');

//   //   if (response.statusCode == 200) {
//   //     final Map<String, dynamic> responseData = json.decode(response.body);
//   //     final loginResponse = LoginResponse.fromJson(responseData);
//   //     _userRole = jsonDecode(response.body)['data']['role'];

//   //     _user = loginResponse.user;
//   //     _accessToken = loginResponse.accessToken;

//   //     final prefs = await SharedPreferences.getInstance();
//   //     await prefs.setString('access_token', _accessToken!);
//   //     await prefs.setInt('id', _user!.id ?? 0);
//   //     await prefs.setString('name', _user!.name);
//   //     await prefs.setString('email', _user!.email);
//   //     await prefs.setString('phone', _user!.phone);
//   //     await prefs.setString('image', _user!.image ?? "");
//   //     await prefs.setString('role', _userRole ?? "");

//   //     // Display a success message
//   //     ScaffoldMessenger.of(context).showSnackBar(
//   //       SnackBar(
//   //         content: Text('Login successful'),
//   //         backgroundColor: Colors.green,
//   //       ),
//   //     );

//   //     notifyListeners();
//   //     Navigator.pushReplacementNamed(context, RoutesManager.homePage);
//   //   } else {
//   //     final responseData = json.decode(response.body);
//   //     final errorMessage = responseData['message'] ?? 'Unknown error';

//   //     ScaffoldMessenger.of(context).showSnackBar(
//   //       SnackBar(
//   //         content: Text(errorMessage), // Display the exact message from the API
//   //         backgroundColor: Colors.red,
//   //       ),
//   //     );
//   //   }
//   // }

//   Future<void> register({
//     required String name,
//     required String email,
//     required String phone,
//     required String password,
//     required String passwordConfirmation,
//     required BuildContext context,
//   }) async {
//     String? androidId = await getAndroidId();
//     final url = Uri.parse(AppUrl
//         .registerEndPoint); // Replace with your actual registration endpoint
//     final response = await http.post(url,
//         headers: {
//           'Content-Type': 'application/json', // Ensure the content type is JSON
//         },
//         body: json.encode({
//           'name': name,
//           'email': email,
//           'phone': phone,
//           'password': password,
//           "password_confirmation": passwordConfirmation,
//           "ip_adress": androidId,
//         }));

//     print('Response status: ${response.statusCode}');
//     print('Response body: ${response.body}');

//     if (response.statusCode == 200) {
//       final Map<String, dynamic> responseData = json.decode(response.body);
//       final loginResponse = LoginResponse.fromJson(responseData);
//       _userRole = jsonDecode(response.body)['data']['role'];

//       _user = loginResponse.user;
//       _accessToken = loginResponse.accessToken;
//       notifyListeners();
//       Navigator.pushReplacementNamed(context, RoutesManager.homePage);

//       final prefs = await SharedPreferences.getInstance();
//       await prefs.setString('access_token', _accessToken!);
//       await prefs.setInt('id', _user!.id ?? 0);
//       await prefs.setString('name', _user!.name);
//       await prefs.setString('email', _user!.email);
//       await prefs.setString('phone', _user!.phone);
//       await prefs.setString('user_image', _user!.image ?? "");
//       await prefs.setString('role', _userRole ?? "");
//     } else {
//       final responseData = json.decode(response.body);
//       final errorMessage = responseData['message'] ?? 'Unknown error';
//       throw Exception('Registration failed: $errorMessage');
//     }
//   }

//   Future<void> loadAccessToken() async {
//     final prefs = await SharedPreferences.getInstance();
//     _accessToken = prefs.getString('access_token');
//     if (_accessToken != null) {
//       _user = User(
//         id: prefs.getInt('id') ?? 0,
//         name: prefs.getString('name') ?? '',
//         email: prefs.getString('email') ?? '',
//         phone: prefs.getString('phone') ?? "",
//         image: prefs.getString('image'),
//         emailVerifiedAt: DateTime.now(),
//         createdAt: DateTime.now(),
//         updatedAt: DateTime.now(),
//         password: '',
//         passwordConfirmation: '',
//       );

//       // Optionally, you can fetch the user data with the stored token
//       // and set the _user property if needed.

//       notifyListeners();
//     }
//   }

//   void updateUser(User updatedUser) {
//     _user = updatedUser;

//     // Save the updated user details to SharedPreferences
//     SharedPreferences.getInstance().then((prefs) {
//       prefs.setInt('id', _user!.id ?? 0);
//       prefs.setString('name', _user!.name);
//       prefs.setString('email', _user!.email);
//       prefs.setString('phone', _user!.phone);
//       prefs.setString('image', _user!.image ?? "");
//     });

//     notifyListeners();
//   }

//   Future<void> logout(BuildContext context) async {
//     final prefs = await SharedPreferences.getInstance();
//     _accessToken = prefs.getString('access_token');

//     if (_accessToken != null) {
//       final url = Uri.parse(AppUrl.logoutEndPoint);
//       final response = await http.post(
//         url,
//         headers: {
//           'Authorization': 'Bearer $_accessToken',
//         },
//       );

//       print("access token $_accessToken");

//       if (response.statusCode == 200) {
//         _user = null;
//         _accessToken = null;

//         await prefs
//             .clear(); // Clear all preferences instead of removing individual items

//         notifyListeners();
//         Navigator.pushReplacementNamed(context, RoutesManager.loginPage);
//       } else {
//         throw Exception('Failed to log out');
//       }
//     } else {
//       throw Exception('No access token found');
//     }
//   }
// }
