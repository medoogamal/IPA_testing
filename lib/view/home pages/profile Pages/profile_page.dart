import 'package:flutter/material.dart';
import 'package:mstra/core/utilis/assets_manager.dart';
import 'package:mstra/core/utilis/gradient_background_color.dart';
import 'package:mstra/core/utilis/space_widgets.dart';
import 'package:mstra/res/app_url.dart';
import 'package:mstra/routes/routes_manager.dart';
import 'package:mstra/view/corses%20pages/quizes/quize_screen.dart';
import 'package:mstra/view/home%20pages/profile%20Pages/componenets.dart';
import 'package:mstra/view/corses%20pages/quizes/quizzes_results.dart';
import 'package:mstra/view_models/auth_view_model.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatelessWidget {
  ProfilePage({Key? key}) : super(key: key);

  Future<bool> _isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');
    return accessToken != null; // Returns true if logged in, false otherwise
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);

    return FutureBuilder<bool>(
      future: _isLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            body: GradientBackground(
              child: Center(
                child: Text('Error checking login status'),
              ),
            ),
          );
        } else if (snapshot.data == true) {
          // User is logged in, show the profile page
          return FutureBuilder<Map<String, dynamic>>(
            future: _loadUserData(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: GradientBackground(
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                );
              } else if (snapshot.hasError) {
                return Scaffold(
                  body: GradientBackground(
                    child: Center(
                      child: Text('Error loading user data'),
                    ),
                  ),
                );
              } else {
                final userData = snapshot.data!;
                final name = userData['name'] ?? 'User';
                final image = userData["user_image"];
                final id = userData["id"];
                final userRole = userData["role"];

                return Scaffold(
                  body: GradientBackground(
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: ListView(
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                        children: [
                          Center(
                            child: Container(
                              height: MediaQuery.of(context).size.height * 0.15,
                              width: MediaQuery.of(context).size.height *
                                  0.15, // Square container
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.blueAccent,
                                    Colors.lightBlueAccent,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    spreadRadius: 2,
                                    blurRadius: 5,
                                    offset: Offset(0, 3), // Shadow position
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: image != null
                                    ? Image.network(
                                        AppUrl.NetworkStorage + image,
                                        fit: BoxFit.cover,
                                        height:
                                            MediaQuery.of(context).size.height *
                                                0.15,
                                        width:
                                            MediaQuery.of(context).size.height *
                                                0.15,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          // Display a fallback icon if the image fails to load
                                          return Icon(
                                            Icons.person,
                                            size: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.10,
                                            color: Colors.white,
                                          );
                                        },
                                      )
                                    : Icon(
                                        Icons.person,
                                        size:
                                            MediaQuery.of(context).size.height *
                                                0.10,
                                        color: Colors.white,
                                      ),
                              ),
                            ),
                          ),
                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.03),
                          Center(
                            child: Text(
                              " ${name.toUpperCase()} مرحبا",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.03),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.3),
                                  spreadRadius: 2,
                                  blurRadius: 5,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                ListTile(
                                  onTap: () {
                                    Navigator.pushNamed(context,
                                        RoutesManager.userProfileScreen);
                                  },
                                  leading: Icon(Icons.account_circle,
                                      color: Colors.blueAccent),
                                  title: Text('تغيير بيانات حسابك',
                                      style: TextStyle(fontSize: 18)),
                                  trailing: Icon(Icons.arrow_forward_ios,
                                      color: Colors.grey),
                                ),
                                Divider(color: Colors.grey[300], height: 1),
                                ListTile(
                                  onTap: () async {
                                    try {
                                      authViewModel
                                          .setLoading(true); // Start loading
                                      await authViewModel.logout(context);
                                    } catch (e) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Logout failed: ${e.toString()}'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    } finally {
                                      authViewModel
                                          .setLoading(false); // End loading
                                    }
                                  },
                                  leading: authViewModel.isLoading
                                      ? const CircularProgressIndicator()
                                      : const Icon(
                                          Icons.exit_to_app,
                                          color: Colors.redAccent,
                                        ),
                                  title: const Text(
                                    'تسجيل الخروج',
                                    style: TextStyle(fontSize: 18),
                                  ),
                                  trailing: const Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.grey,
                                  ),
                                ),
                                Divider(color: Colors.grey[300], height: 1),
                                userRole == "user"
                                    ? ListTile(
                                        onTap: () {
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      QuizResultsPage(
                                                          userId: id)));
                                        },
                                        leading: Icon(Icons.info,
                                            color: Colors.greenAccent),
                                        title: Text("نتائج الاختبارات",
                                            style: TextStyle(fontSize: 18)),
                                        trailing: Icon(Icons.arrow_forward_ios,
                                            color: Colors.grey),
                                      )
                                    : SizedBox(
                                        width: 0,
                                        height: 0,
                                      ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
            },
          );
        } else {
          // User is logged out, show the alternative screen
          return Scaffold(
            body: GradientBackground(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: MediaQuery.of(context).size.height * 0.4,
                      width: MediaQuery.of(context).size.width,
                      child: Center(
                          child: Image.asset(
                              fit: BoxFit.contain,
                              height: MediaQuery.of(context).size.height * 0.4,
                              width: double.infinity,
                              ImageAssets.notloggedin)),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, RoutesManager.loginPage);
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: const Color.fromARGB(255, 93, 142, 92),
                        padding:
                            EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12), // Rounded corners
                        ),
                        elevation: 5, // Text color
                      ),
                      child: const Text('اذهب الى صفحة تسجيل الدخول'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      },
    );
  }

  Future<Map<String, dynamic>> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('name');
    final id = prefs.getInt("id");
    final image = prefs.getString("user_image");
    final userRole = prefs.getString("role");
    return {'name': name, "user_image": image, "id": id, "role": userRole};
  }
}
