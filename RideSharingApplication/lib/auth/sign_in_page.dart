import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:vivi_ride_app/auth/sign_up_page.dart';
import 'package:vivi_ride_app/pages/home_page.dart';
import '../database/database.dart';
import '../global.dart';
import '../widgets/loading_dialog.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final DatabaseService _databaseService = DatabaseService(); // Initialize DatabaseService

  // Google Sign-In
  Future<void> signInWithGoogle() async {
    try {
      _showLoadingDialog("Please wait...");

      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // User is already signed in
        _hideLoadingDialog();
        _showSnackBar("You are already signed in. Please sign out before signing up.");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SignInPage()),
        );
        return;
      }

      await GoogleSignIn().signOut(); // Sign out to force account selection

      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        // User canceled the sign-in
        _hideLoadingDialog();
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      if (userCredential.user != null) {
        await handleUserAuthentication(userCredential.user!);
      } else {
        // Handle case where userCredential.user is null
        _hideLoadingDialog();
        _showSnackBar("Sign in failed. User does not exist.");
      }
    } catch (e) {
      _handleError(e);
    }
  }



  // Apple Sign-In
  Future<void> signInWithApple() async {
    try {
      _showLoadingDialog("Please wait...");

      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // User is already signed in
        _hideLoadingDialog();
        _showSnackBar("You are already signed in. Please sign out before signing up.");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SignInPage()),
        );
        return;
      }

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
      );

      final oAuthCredential = OAuthProvider("apple.com").credential(
        idToken: credential.identityToken,
        accessToken: credential.authorizationCode,
      );

      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(oAuthCredential);

      if (userCredential.user != null) {
        await handleUserAuthentication(userCredential.user!);
      } else {
        // Handle case where userCredential.user is null
        _hideLoadingDialog();
        _showSnackBar("Sign in failed. User does not exist.");
      }
    } catch (e) {
      _handleError(e);
    }
  }



  // Validate Sign-In Form
  void validateSignInForm() {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (!email.contains("@")) {
      _showSnackBar("Email is not valid");
    } else if (password.length < 6) {
      _showSnackBar("Password must be at least 6 or more characters");
    } else {
      _signInUser();
    }
  }

  // Sign In User with Email/Password
  Future<void> _signInUser() async {
    _showLoadingDialog("Please wait...");

    try {
      final User? user = (await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      ))
          .user;

      if (user != null) {
        await handleUserAuthentication(user);
      }
    } on FirebaseAuthException catch (e) {
      _handleFirebaseAuthException(e);
    }
  }

  // Handle Firebase Authentication
  Future<void> handleUserAuthentication(User user) async {
    try {
      final userData = await _databaseService.getUserData(user.uid);

      if (userData != null) {
        if (userData["blockStatus"] == "no") {
          userName = userData["name"];
          userPhone = userData["phone"];
          _navigateToHome();
          _showSnackBar("Signed in successfully.");
        } else {
          _hideLoadingDialog();
          _signOutAndShowError("You are blocked. Contact vivigroup.inc@gmail.com");
        }
      } else {
        _signOutAndShowError("Your record does not exist as a User.");
      }
    } catch (e) {
      _showError(e);
    }
  }

  // Helper Methods
  void _showError(dynamic e) {
    _hideLoadingDialog();
    _showSnackBar(e.toString());
  }

  void _handleFirebaseAuthException(FirebaseAuthException e) {
    FirebaseAuth.instance.signOut();
    _hideLoadingDialog();
    _showSnackBar(e.message ?? "An error occurred");
  }

  void _signOutAndShowError(String message) {
    FirebaseAuth.instance.signOut();
    _hideLoadingDialog();
    _showSnackBar(message);
  }

  void _navigateToHome() {
    Navigator.push(context, MaterialPageRoute(builder: (c) => const HomePage()));
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) => LoadingDialog(messageTxt: message),
    );
  }

  void _hideLoadingDialog() {
    if (Navigator.canPop(context)) Navigator.pop(context);
  }

  void _showSnackBar(String message) {
    associateMethods.showSnackBarMsg(message, context);
  }

  void _handleError(dynamic e) {
    _hideLoadingDialog();
    _showSnackBar(e.toString());
  }


  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.signOut();
    checkSignInStatus(); // Sign out any existing sessions
  }

  void checkSignInStatus() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // User is signed in, navigate to HomePage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
            child: Column(
              children: [
                SizedBox(height: screenHeight * 0.1),
                Image.asset(
                  "assets/images/ridesharing-high-resolution-logo-black-transparent.png",
                  width: screenWidth * 0.5,
                ),
                SizedBox(height: screenHeight * 0.02),
                const Text(
                  "Login as User",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: screenHeight * 0.02),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: emailController,
                        labelText: "Email/Username",
                        keyboardType: TextInputType.emailAddress,
                      ),
                      SizedBox(height: screenHeight * 0.03),
                      _buildTextField(
                        controller: passwordController,
                        labelText: "Password",
                        obscureText: true,
                      ),
                      SizedBox(height: screenHeight * 0.04),
                      _buildElevatedButton("Login", validateSignInForm),
                      SizedBox(height: screenHeight * 0.03),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                        child: Column(
                          children: [
                            const Text("Or", style: TextStyle(fontSize: 20, color: Colors.black)),
                            SizedBox(height: screenHeight * 0.02),
                            const Text("Sign In With", style: TextStyle(fontSize: 18, color: Colors.black)),
                            SizedBox(height: screenHeight * 0.02),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                buildGoogleSignInButton('assets/images/google_logo.png', signInWithGoogle),
                                SizedBox(width: screenWidth * 0.1),
                                buildAppleSignInButton('assets/images/apple_logo.png', signInWithApple),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: screenHeight * 0.03),
                _buildSignUpTextButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper Widgets
  TextField _buildTextField({
    required TextEditingController controller,
    required String labelText,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: Colors.grey, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: Colors.blue, width: 2.0),
        ),
      ),
      style: const TextStyle(color: Colors.grey, fontSize: 15),
    );
  }

  ElevatedButton _buildElevatedButton(String text, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 120, vertical: 20),
      ),
      icon: const Icon(Icons.email_outlined, color: Colors.white),
      label: Text(text, style: const TextStyle(color: Colors.white, fontSize: 18)),
    );
  }

  Widget buildGoogleSignInButton(String assetPath, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Image.asset(assetPath, width: 50, height: 40),
    );
  }

  Widget buildAppleSignInButton(String assetPath, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Image.asset(assetPath, width: 60, height: 50),
    );
  }

  TextButton _buildSignUpTextButton() {
    return TextButton(
      onPressed: () {
        Navigator.push(context, MaterialPageRoute(builder: (c) => const SignUpPage()));
      },
      child: const Text(
        "Don't have an Account? Sign Up here",
        style: TextStyle(color: Colors.grey),
      ),
    );
  }
}

// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:sign_in_with_apple/sign_in_with_apple.dart';
// import 'package:vivi_ride_app/auth/sign_up_page.dart';
// import 'package:vivi_ride_app/pages/home_page.dart';
// import '../database/database.dart';
// import '../global.dart';
// import '../widgets/loading_dialog.dart';
//
// class SignInPage extends StatefulWidget {
//   const SignInPage({super.key});
//
//   @override
//   State<SignInPage> createState() => _SignInPageState();
// }
//
// class _SignInPageState extends State<SignInPage> {
//   final TextEditingController emailController = TextEditingController();
//   final TextEditingController passwordController = TextEditingController();
//   final DatabaseService _databaseService = DatabaseService(); // Initialize DatabaseService
//
//   // Google Sign-In
//   Future<void> signInWithGoogle() async {
//     _showLoadingDialog("Please wait...");
//     try {
//       await GoogleSignIn().signOut();
//
//       final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
//       _showLoadingDialog("Please wait...");
//       if (googleUser == null) return; // User cancelled the sign-in
//
//       final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
//       final credential = GoogleAuthProvider.credential(
//         accessToken: googleAuth.accessToken,
//         idToken: googleAuth.idToken,
//       );
//
//       final UserCredential userCredential =
//       await FirebaseAuth.instance.signInWithCredential(credential);
//       _showLoadingDialog("Please wait...");
//
//       if (userCredential.user != null) {
//         await handleUserAuthentication(userCredential.user!);
//
//
//       }
//     } catch (e) {
//       _showError(e);
//     }
//   }
//
//   // Apple Sign-In
//   Future<void> signInWithApple() async {
//     try {
//       final credential = await SignInWithApple.getAppleIDCredential(
//         scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
//       );
//
//       final oAuthCredential = OAuthProvider("apple.com").credential(
//         idToken: credential.identityToken,
//         accessToken: credential.authorizationCode,
//       );
//
//       final UserCredential userCredential =
//       await FirebaseAuth.instance.signInWithCredential(oAuthCredential);
//
//       if (userCredential.user != null) {
//         await handleUserAuthentication(userCredential.user!);
//       }
//     } catch (e) {
//       _showError(e);
//     }
//   }
//
//   // Validate Sign-In Form
//   void validateSignInForm() {
//     final email = emailController.text.trim();
//     final password = passwordController.text.trim();
//
//     if (!email.contains("@")) {
//       _showSnackBar("Email is not valid");
//     } else if (password.length < 6) {
//       _showSnackBar("Password must be at least 6 or more characters");
//     } else {
//       _signInUser();
//     }
//   }
//
//   // Sign In User with Email/Password
//   Future<void> _signInUser() async {
//     _showLoadingDialog("Please wait...");
//
//     try {
//       final User? user = (await FirebaseAuth.instance.signInWithEmailAndPassword(
//         email: emailController.text.trim(),
//         password: passwordController.text.trim(),
//       ))
//           .user;
//
//       if (user != null) {
//         await handleUserAuthentication(user);
//       }
//     } on FirebaseAuthException catch (e) {
//       _handleFirebaseAuthException(e);
//     }
//   }
//
//   // Handle Firebase Authentication
//   Future<void> handleUserAuthentication(User user) async {
//     try {
//       final userData = await _databaseService.getUserData(user.uid);
//
//       if (userData != null) {
//         if (userData["blockStatus"] == "no") {
//           userName = userData["name"];
//           userPhone = userData["phone"];
//           _navigateToHome();
//           _showSnackBar("Signed in successfully.");
//         } else {
//           _signOutAndShowError("You are blocked. Contact vivigroup.inc@gmail.com");
//         }
//       } else {
//         _signOutAndShowError("Your record does not exist as a User.");
//       }
//     } catch (e) {
//       _showError(e);
//     }
//   }
//
//   // Helper Methods
//   void _showError(dynamic e) {
//     _hideLoadingDialog();
//     _showSnackBar(e.toString());
//   }
//
//   void _handleFirebaseAuthException(FirebaseAuthException e) {
//     FirebaseAuth.instance.signOut();
//     _hideLoadingDialog();
//     _showSnackBar(e.message ?? "An error occurred");
//   }
//
//   void _signOutAndShowError(String message) {
//     FirebaseAuth.instance.signOut();
//     _hideLoadingDialog();
//     _showSnackBar(message);
//   }
//
//   void _navigateToHome() {
//     Navigator.push(context, MaterialPageRoute(builder: (c) => const HomePage()));
//   }
//
//   void _showLoadingDialog(String message) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) => LoadingDialog(messageTxt: message),
//     );
//   }
//
//   void _hideLoadingDialog() {
//     if (Navigator.canPop(context)) Navigator.pop(context);
//   }
//
//   void _showSnackBar(String message) {
//     associateMethods.showSnackBarMsg(message, context);
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     FirebaseAuth.instance.signOut();
//     checkSignInStatus(); // Sign out any existing sessions
//   }
//
//   void checkSignInStatus() async {
//     User? user = FirebaseAuth.instance.currentUser;
//     if (user != null) {
//       // User is signed in, navigate to HomePage
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (context) => const HomePage()),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final screenHeight = MediaQuery.of(context).size.height;
//
//     return Scaffold(
//       body: SingleChildScrollView(
//         child: Padding(
//           padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
//           child: Column(
//             children: [
//               SizedBox(height: screenHeight * 0.1),
//               Image.asset(
//                 "assets/images/ridesharing-high-resolution-logo-black-transparent.png",
//                 width: screenWidth * 0.5,
//               ),
//               SizedBox(height: screenHeight * 0.02),
//               const Text(
//                 "Login as User",
//                 textAlign: TextAlign.center,
//                 style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
//               ),
//               SizedBox(height: screenHeight * 0.02),
//               Padding(
//                 padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
//                 child: Column(
//                   children: [
//                     _buildTextField(
//                       controller: emailController,
//                       labelText: "Email/Username",
//                       keyboardType: TextInputType.emailAddress,
//                     ),
//                     SizedBox(height: screenHeight * 0.03),
//                     _buildTextField(
//                       controller: passwordController,
//                       labelText: "Password",
//                       obscureText: true,
//                     ),
//                     SizedBox(height: screenHeight * 0.04),
//                     _buildElevatedButton("Login", validateSignInForm),
//                     SizedBox(height: screenHeight * 0.03),
//                     Padding(
//                       padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
//                       child: Column(
//                         children: [
//                           const Text("Or", style: TextStyle(fontSize: 20, color: Colors.black)),
//                           SizedBox(height: screenHeight * 0.02),
//                           const Text("Sign In With", style: TextStyle(fontSize: 18, color: Colors.black)),
//                           SizedBox(height: screenHeight * 0.02),
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             crossAxisAlignment: CrossAxisAlignment.center,
//                             children: [
//                               buildGoogleSignInButton('assets/images/google_logo.png', signInWithGoogle),
//                               SizedBox(width: screenWidth * 0.1),
//                               buildAppleSignInButton('assets/images/apple_logo.png', signInWithApple),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               SizedBox(height: screenHeight * 0.03),
//               _buildSignUpTextButton(),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// // Your existing custom widget methods like _buildTextField, _buildElevatedButton, etc.
// // Helper Widgets
//   TextField _buildTextField({
//     required TextEditingController controller,
//     required String labelText,
//     TextInputType keyboardType = TextInputType.text,
//     bool obscureText = false,
//   }) {
//     return TextField(
//       controller: controller,
//       keyboardType: keyboardType,
//       obscureText: obscureText,
//       decoration: InputDecoration(
//         labelText: labelText,
//         labelStyle: const TextStyle(fontSize: 14),
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10.0),
//           borderSide: const BorderSide(color: Colors.grey, width: 1.5),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10.0),
//           borderSide: const BorderSide(color: Colors.blue, width: 2.0),
//         ),
//       ),
//       style: const TextStyle(color: Colors.grey, fontSize: 15),
//     );
//   }
//
//   ElevatedButton _buildElevatedButton(String text, VoidCallback onPressed) {
//     return ElevatedButton.icon(
//       onPressed: onPressed,
//
//       style: ElevatedButton.styleFrom(
//         backgroundColor: Colors.black,
//         padding: const EdgeInsets.symmetric(horizontal: 120, vertical: 20),
//       ),
//       icon: const Icon(Icons.email_outlined,color: Colors.white,),
//       label:  Text(text, style: const TextStyle(color: Colors.white, fontSize: 18)),
//     );
//   }
//
//   Widget buildGoogleSignInButton(String assetPath, VoidCallback onPressed) {
//     return GestureDetector(
//       onTap: onPressed,
//       child: Image.asset(assetPath, width: 50, height: 40),
//     );
//   }
//
//   Widget buildAppleSignInButton(String assetPath, VoidCallback onPressed) {
//     return
//       GestureDetector(
//         onTap: onPressed,
//         child: Image.asset(assetPath, width: 60, height: 50),
//       );
//   }
//
//   TextButton _buildSignUpTextButton() {
//     return TextButton(
//       onPressed: () {
//         Navigator.push(context, MaterialPageRoute(builder: (c) => const SignUpPage()));
//       },
//       child: const Text(
//         "Don't have an Account? Sign Up here",
//         style: TextStyle(color: Colors.grey),
//       ),
//     );
//   }
// }




// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter/material.dart';
// import 'package:vivi_ride_app/auth/sign_up_page.dart';
// import 'package:vivi_ride_app/pages/home_page.dart';
//
// import '../global.dart';
// import '../widgets/loading_dialog.dart';
//
// class SignInPage extends StatefulWidget {
//   const SignInPage({super.key});
//
//   @override
//   State<SignInPage> createState() => _SignInPageState();
// }
//
// class _SignInPageState extends State<SignInPage> {
//
//   TextEditingController emailtextEditingController = TextEditingController();
//   TextEditingController passwordtextEditingController = TextEditingController();
//
//
//   validateSignInForm()
//   {
//     if(!emailtextEditingController.text.contains("@"))
//     {
//       associateMethods.showSnackBarMsg("email is not valid", context);
//     }
//     else if(passwordtextEditingController.text.trim().length < 6)
//     {
//       associateMethods.showSnackBarMsg("Password must be atleast 6 or more characters", context);
//     }
//     else
//     {
//       signIpUserNow();
//     }
//   }
//
//   signIpUserNow() async {
//
//     showDialog(context: context,
//         builder: (BuildContext context) => LoadingDialog(messageTxt: "please wait... ")
//     );
//     try
//     {
//       final User? firebaseUser = (
//           await FirebaseAuth.instance.signInWithEmailAndPassword(
//               email: emailtextEditingController.text.trim(),
//               password: passwordtextEditingController.text.trim()
//           ).catchError((onError)
//           {
//             Navigator.pop(context);
//             associateMethods.showSnackBarMsg(onError.toString(), context);
//           })
//       ).user;
//
//       if(firebaseUser != null)
//       {
//         DatabaseReference ref = FirebaseDatabase.instance.ref().child("users").child(firebaseUser.uid);
//         await ref.once().then((dataSnapshot)
//         {
//           if(dataSnapshot.snapshot.value != null)
//           {
//             if((dataSnapshot.snapshot.value as Map)["blockStatus"] == "no")
//             {
//               userName = (dataSnapshot.snapshot.value as Map)["name"];
//               userPhone = (dataSnapshot.snapshot.value as Map)["phone"];
//
//               Navigator.push(context, MaterialPageRoute(builder: (c) => const HomePage()));
//
//               associateMethods.showSnackBarMsg("signed in successfully.", context);
//             }
//             else
//             {
//               Navigator.pop(context);
//               FirebaseAuth.instance.signOut();
//               associateMethods.showSnackBarMsg("you are blocked contact vivigroup.inc@gmail.com", context);
//
//             }
//
//           }
//           else
//             {
//               Navigator.pop(context);
//               FirebaseAuth.instance.signOut();
//               associateMethods.showSnackBarMsg("your record do not exist as a User ", context);
//             }
//
//
//         });
//       }
//
//     }
//     on FirebaseAuthException catch(e)
//     {
//       FirebaseAuth.instance.signOut();
//       Navigator.pop(context);
//       associateMethods.showSnackBarMsg(e.toString(), context);
//     }
//
//
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SingleChildScrollView(
//         child: Padding(padding: const EdgeInsets.all(12),
//           child: Column(
//             children: [
//               const SizedBox(height: 122,),
//
//               Image.asset("assets/images/ridesharing-high-resolution-logo-black-transparent.png",width: MediaQuery.of(context).size.width * .6,
//               ),
//
//               const SizedBox(height: 20,),
//
//               const Text(
//                 "Login as  User",
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   fontSize: 26,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//
//           Padding(padding: const EdgeInsets.all(12),
//             child: Column(
//               children: [
//
//                 TextField(
//                   controller: emailtextEditingController,
//                   keyboardType: TextInputType.emailAddress,
//                   decoration: InputDecoration(
//                     labelText: "Email/Username",
//                     labelStyle: const TextStyle(
//                       fontSize: 14,
//                     ),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(10.0),
//                       borderSide: const BorderSide(
//                         color: Colors.grey,
//                         width: 1.5,
//                       ),
//                     ),
//                     focusedBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(10.0),
//                       borderSide: const BorderSide(
//                         color: Colors.blue,
//                         width: 2.0,
//                       ),
//                     ),
//                   ),
//                   style: const TextStyle(
//                     color: Colors.grey,
//                     fontSize: 15,
//                   ),
//                 ),
//                 const SizedBox(height: 22,),
//                 TextField(
//                   controller: passwordtextEditingController,
//                   obscureText: true,
//                   keyboardType: TextInputType.emailAddress,
//                   decoration: InputDecoration(
//                     labelText: "Password",
//                     labelStyle: const TextStyle(
//                       fontSize: 14,
//                     ),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(10.0),
//                       borderSide: const BorderSide(
//                         color: Colors.grey,
//                         width: 1.5,
//                       ),
//                     ),
//                     focusedBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(10.0),
//                       borderSide: const BorderSide(
//                         color: Colors.blue,
//                         width: 2.0,
//                       ),
//                     ),
//                   ),
//                   style: const TextStyle(
//                     color: Colors.grey,
//                     fontSize: 15,
//                   ),
//                 ),
//
//
//                 // TextField(
//                 //   controller: passwordtextEditingController,
//                 //   obscureText: true,
//                 //   keyboardType: TextInputType.emailAddress,
//                 //   decoration: const InputDecoration(
//                 //     labelText: "Password",
//                 //     labelStyle: TextStyle(
//                 //       fontSize: 14,
//                 //     ),
//                 //   ),
//                 //   style: const TextStyle(
//                 //     color: Colors.grey,
//                 //     fontSize: 15,
//                 //   ),
//                 // ),
//
//                 const SizedBox(height: 32,),
//
//                 ElevatedButton(onPressed: ()
//                 {
//                   validateSignInForm();
//                 },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.green,
//                     padding: const EdgeInsets.symmetric(horizontal: 80,vertical: 10),
//                   ),
//                   child: const Text("Login",style: TextStyle(color: Colors.black),),
//                 ),
//
//               ],
//             ),
//           ),
//
//               const SizedBox(height: 12,),
//
//               TextButton(onPressed: (){
//                 Navigator.push(context, MaterialPageRoute(builder: (c) => const SignUpPage()));
//               },
//                   child: const Text(
//                       "Don't have an Account? Sign Up here",
//                     style: TextStyle(
//                       color: Colors.grey
//                     ),
//                   ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
