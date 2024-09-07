import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:vivi_ride_app/pages/home_page.dart';
import 'package:vivi_ride_app/auth/sign_in_page.dart';
import 'package:vivi_ride_app/widgets/loading_dialog.dart';
import '../database/database.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController userPhoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final DatabaseService _databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _checkIfUserIsSignedIn();
  }

  Future<void> _checkIfUserIsSignedIn() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SignInPage()),
      );
    }
  }

  Future<void> signInWithGoogle() async {
    _showLoadingDialog("Please wait...");
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
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
        _hideLoadingDialog();
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      // Fetch sign-in methods for the email
      final userData = await FirebaseAuth.instance.fetchSignInMethodsForEmail(userCredential.user!.email!);

      if (userData.contains('google.com')) {
        // User is registered with Google, navigate to SignInPage
        _hideLoadingDialog();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SignInPage()),
        );
      } else {
        // Handle user registration
        await _handleUserRegistration(userCredential.user!);
      }
    } catch (e) {
      _handleError(e);
    }
  }


  Future<void> signInWithApple() async {
    _showLoadingDialog("Please wait...");

    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
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
        final userData = await FirebaseAuth.instance.fetchSignInMethodsForEmail(userCredential.user!.email!);
        if (userData.contains('apple.com')) {
          _hideLoadingDialog();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const SignInPage()),
          );
        } else {
          await _handleUserRegistration(userCredential.user!);
        }
      } else {
        _hideLoadingDialog();
        _showSnackBar("Sign in failed. User does not exist.");
      }
    } catch (e) {
      _handleError(e);
    }
  }

  void validateSignUpForm() {
    if (userNameController.text.trim().length < 4) {
      _showSnackBar("Name must be at least 4 characters");
    } else if (userPhoneController.text.trim().length < 7) {
      _showSnackBar("Phone number must be 7 or more digits");
    } else if (!emailController.text.contains("@")) {
      _showSnackBar("Email is not valid");
    } else if (passwordController.text.trim().length < 6) {
      _showSnackBar("Password must be at least 6 characters");
    } else {
      _signUpUserNow();
    }
  }

  Future<void> _signUpUserNow() async {
    _showLoadingDialog("Please wait...");

    try {
      final UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (userCredential.user != null) {
        await _handleUserRegistration(userCredential.user!);
      }
    } on FirebaseAuthException catch (e) {
      _handleError(e);
    }
  }

  Future<void> _handleUserRegistration(User user) async {
    try {
      await _databaseService.upsertUser(user.uid, {
        "name": user.displayName ?? userNameController.text.trim(),
        "email": user.email ?? emailController.text.trim(),
        "phone": user.phoneNumber ?? userPhoneController.text.trim(),
        "photoURL": user.photoURL ?? "No Photo URL",
        "blockStatus": "no",
      });

      _hideLoadingDialog();
      _showSnackBar("Account created successfully.");
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const HomePage()));
    } catch (e) {
      _handleError(e);
    }
  }

  void _handleError(dynamic e) {
    FirebaseAuth.instance.signOut();
    _hideLoadingDialog();
    _showSnackBar(e.toString());
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05, vertical: screenHeight * 0.02),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: screenHeight * 0.1),
                Image.asset(
                  "assets/images/ridesharing-high-resolution-logo-black-transparent.png",
                  width: screenWidth * 0.5,
                ),
                SizedBox(height: screenHeight * 0.03),
                const Text(
                  "Register New Account",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: screenHeight * 0.03),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: userNameController,
                        labelText: "User Name",
                        keyboardType: TextInputType.text,
                      ),
                      SizedBox(height: screenHeight * 0.03),
                      _buildTextField(
                        controller: userPhoneController,
                        labelText: "Phone No",
                        keyboardType: TextInputType.number,
                      ),
                      SizedBox(height: screenHeight * 0.03),
                      _buildTextField(
                        controller: emailController,
                        labelText: "User Email",
                        keyboardType: TextInputType.emailAddress,
                      ),
                      SizedBox(height: screenHeight * 0.03),
                      _buildTextField(
                        controller: passwordController,
                        labelText: "Password",
                        obscureText: true,
                      ),
                      SizedBox(height: screenHeight * 0.05),
                      ElevatedButton.icon(
                        onPressed: validateSignUpForm,
                        icon: const Icon(Icons.email_outlined),
                        label: const Text("Sign up with Email"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.2,
                            vertical: screenHeight * 0.02,
                          ),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.03),
                      const Text("Or", style: TextStyle(fontSize: 20, color: Colors.black)),
                      SizedBox(height: screenHeight * 0.02),
                      const Text("Sign In With", style: TextStyle(fontSize: 18, color: Colors.black)),
                      SizedBox(height: screenHeight * 0.03),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          buildGoogleSignInButton('assets/images/google_logo.png', signInWithGoogle),
                          SizedBox(width: screenWidth * 0.1),
                          buildAppleSignInButton('assets/images/apple_logo.png', signInWithApple),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.03),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (c) => const SignInPage()));
                  },
                  child: const Text(
                    "Already have an Account? Sign In here",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
}


/// realtime database

// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter/material.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:sign_in_with_apple/sign_in_with_apple.dart';
// import 'package:vivi_ride_app/pages/home_page.dart';
// import 'package:vivi_ride_app/auth/sign_in_page.dart';
// import 'package:vivi_ride_app/global.dart';
// import 'package:vivi_ride_app/widgets/loading_dialog.dart';
//
// class SignUpPage extends StatefulWidget {
//   const SignUpPage({super.key});
//
//   @override
//   State<SignUpPage> createState() => _SignUpPageState();
// }
//
// class _SignUpPageState extends State<SignUpPage> {
//   TextEditingController userNameController = TextEditingController();
//   TextEditingController userPhoneController = TextEditingController();
//   TextEditingController emailController = TextEditingController();
//   TextEditingController passwordController = TextEditingController();
//
//   Future<void> signInWithGoogle() async {
//     try {
//       await GoogleSignIn().signOut(); // Sign out to force account selection
//
//       final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
//       if (googleUser == null) return; // User canceled the sign-in
//
//       final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
//
//       final credential = GoogleAuthProvider.credential(
//         accessToken: googleAuth.accessToken,
//         idToken: googleAuth.idToken,
//       );
//
//       final UserCredential userCredential =
//       await FirebaseAuth.instance.signInWithCredential(credential);
//
//       if (userCredential.user != null) {
//         await handleUserRegistration(userCredential.user!);
//       }
//     } catch (e) {
//       _showError(e);
//     }
//   }
//
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
//         await handleUserRegistration(userCredential.user!);
//       }
//     } catch (e) {
//       _showError(e);
//     }
//   }
//
//   void validateSignUpForm() {
//     if (userNameController.text.trim().length < 3) {
//       _showSnackBar("Name must be at least 4 characters");
//     } else if (userPhoneController.text.trim().length < 7) {
//       _showSnackBar("Phone number must be 7 or more digits");
//     } else if (!emailController.text.contains("@")) {
//       _showSnackBar("Email is not valid");
//     } else if (passwordController.text.trim().length < 6) {
//       _showSnackBar("Password must be at least 6 characters");
//     } else {
//       signUpUserNow();
//     }
//   }
//
//   Future<void> signUpUserNow() async {
//     _showLoadingDialog("Please wait...");
//
//     try {
//       final User? firebaseUser = (await FirebaseAuth.instance.createUserWithEmailAndPassword(
//         email: emailController.text.trim(),
//         password: passwordController.text.trim(),
//       ).catchError((onError) {
//         _hideLoadingDialog();
//         _showSnackBar(onError.toString());
//       })).user;
//
//       Map<String, String> userDataMap = {
//         "name": userNameController.text.trim(),
//         "email": emailController.text.trim(),
//         "phone": userPhoneController.text.trim(),
//         "id": firebaseUser!.uid,
//         "photoURL": firebaseUser.photoURL ?? "No Photo URL",
//         "blockStatus": "no",
//       };
//       await FirebaseDatabase.instance.ref().child("users").child(firebaseUser.uid).set(userDataMap);
//
//       _hideLoadingDialog();
//       _showSnackBar("Account created successfully.");
//       Navigator.push(context, MaterialPageRoute(builder: (c) => const HomePage()));
//     } on FirebaseAuthException catch (e) {
//       FirebaseAuth.instance.signOut();
//       _hideLoadingDialog();
//       _showSnackBar(e.toString());
//     }
//   }
//
//   Future<void> handleUserRegistration(User user) async {
//     Map<String, String> userDataMap = {
//       "name": user.displayName ?? "No Name",
//       "email": user.email ?? "No Email",
//       "phone": user.phoneNumber ?? "No Phone",
//       "id": user.uid,
//       "photoURL": user.photoURL ?? "No Photo URL",
//       "blockStatus": "no",
//     };
//
//     await FirebaseDatabase.instance.ref().child("users").child(user.uid).set(userDataMap);
//
//     Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const HomePage()));
//   }
//
//   void _showError(dynamic e) {
//     _hideLoadingDialog();
//     _showSnackBar(e.toString());
//   }
//
//   void _showSnackBar(String message) {
//     associateMethods.showSnackBarMsg(message, context);
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
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.all(12),
//           child: Column(
//             children: [
//               const SizedBox(height: 122),
//               Image.asset(
//                 "assets/images/ridesharing-high-resolution-logo-black-transparent.png",
//                 width: MediaQuery.of(context).size.width * .6,
//               ),
//               const SizedBox(height: 20),
//               const Text(
//                 "Register New Account",
//                 textAlign: TextAlign.center,
//                 style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
//               ),
//               Padding(
//                 padding: const EdgeInsets.all(12),
//                 child: Column(
//                   children: [
//                     _buildTextField(
//                       controller: userNameController,
//                       labelText: "User Name",
//                       keyboardType: TextInputType.text,
//                     ),
//                     const SizedBox(height: 22),
//                     _buildTextField(
//                       controller: userPhoneController,
//                       labelText: "Phone No",
//                       keyboardType: TextInputType.number,
//                     ),
//                     const SizedBox(height: 22),
//                     _buildTextField(
//                       controller: emailController,
//                       labelText: "User Email",
//                       keyboardType: TextInputType.emailAddress,
//                     ),
//                     const SizedBox(height: 22),
//                     _buildTextField(
//                       controller: passwordController,
//                       labelText: "Password",
//                       obscureText: true,
//                     ),
//                     const SizedBox(height: 32),
//                     ElevatedButton(
//                       onPressed: validateSignUpForm,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.green,
//                         padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 10),
//                       ),
//                       child: const Text("Sign Up", style: TextStyle(color: Colors.black)),
//                     ),
//                     const SizedBox(height: 20),
//                     _buildGoogleSignInButton(),
//                     const SizedBox(height: 10),
//                     _buildAppleSignInButton(),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 12),
//               TextButton(
//                 onPressed: () {
//                   Navigator.push(context, MaterialPageRoute(builder: (c) => const SignInPage()));
//                 },
//                 child: const Text(
//                   "Already have an Account? Sign In here",
//                   style: TextStyle(color: Colors.grey),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
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
//   Widget _buildGoogleSignInButton() {
//     return ElevatedButton(
//       onPressed: signInWithGoogle,
//       style: ElevatedButton.styleFrom(
//         backgroundColor: Colors.white,
//         padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 10),
//       ),
//       child: const Text("Sign In with Google", style: TextStyle(color: Colors.white)),
//     );
//   }
//
//   Widget _buildAppleSignInButton() {
//     return ElevatedButton(
//       onPressed: signInWithApple,
//       style: ElevatedButton.styleFrom(
//         backgroundColor: Colors.black,
//         padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 10),
//       ),
//       child: const Text("Sign In with Apple", style: TextStyle(color: Colors.white)),
//     );
//   }
// }


// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter/material.dart';
// import 'package:vivi_ride_app/auth/sign_in_page.dart';
// import 'package:vivi_ride_app/global.dart';
// import 'package:vivi_ride_app/widgets/loading_dialog.dart';
//
// import '../pages/home_page.dart';
//
// class SignUpPage extends StatefulWidget {
//   const SignUpPage({super.key});
//
//   @override
//   State<SignUpPage> createState() => _SignUpPageState();
// }
//
// class _SignUpPageState extends State<SignUpPage> {
//
//   TextEditingController userNametextEditingController = TextEditingController();
//   TextEditingController userPhonetextEditingController = TextEditingController();
//   TextEditingController emailtextEditingController = TextEditingController();
//   TextEditingController passwordtextEditingController = TextEditingController();
//
//   validateSignUpForm()
//   {
//     if(userNametextEditingController.text.trim().length < 3)
//       {
//         associateMethods.showSnackBarMsg("Name must be atleast 4 or more characters", context);
//       }
//     else if(userPhonetextEditingController.text.trim().length < 7)
//       {
//         associateMethods.showSnackBarMsg("Phone number must be 7 or more numbers", context);
//       }
//     else if(!emailtextEditingController.text.contains("@"))
//     {
//       associateMethods.showSnackBarMsg("email is not valid", context);
//     }
//     else if(passwordtextEditingController.text.trim().length < 6)
//     {
//       associateMethods.showSnackBarMsg("Password must be atleast 6 or more characters", context);
//     }
//     else
//       {
//         signUpUserNow();
//       }
//   }
//
//   signUpUserNow() async
//   {
//
//     showDialog(context: context,
//         builder: (BuildContext context) => const LoadingDialog(messageTxt: "please wait... ")
//     );
//     try
//     {
//       final User? firebaseUser = (
//       await FirebaseAuth.instance.createUserWithEmailAndPassword(
//           email: emailtextEditingController.text.trim(),
//           password: passwordtextEditingController.text.trim()
//       ).catchError((onError)
//       {
//         Navigator.pop(context);
//         associateMethods.showSnackBarMsg(onError.toString(), context);
//       })
//       ).user;
//
//       Map userDataMap = {
//         "name": userNametextEditingController.text.trim(),
//         "email": emailtextEditingController.text.trim(),
//         "phone": userPhonetextEditingController.text.trim(),
//         "id": firebaseUser!.uid,
//         "blockStatus": "no",
//       };
//       FirebaseDatabase.instance.ref().child("users").child(firebaseUser.uid).set(userDataMap);
//
//       Navigator.pop(context);
//       associateMethods.showSnackBarMsg("Account created successfully.", context);
//       Navigator.push(context, MaterialPageRoute(builder: (c) => const HomePage()));
//     }
//     on FirebaseAuthException catch(e)
//     {
//       FirebaseAuth.instance.signOut();
//       Navigator.pop(context);
//       associateMethods.showSnackBarMsg(e.toString(), context);
//     }
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
//                   "Register New Account",
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   fontSize: 26,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//
//               Padding(padding: const EdgeInsets.all(12),
//                 child: Column(
//                   children: [
//
//                     TextField(
//                       controller: userNametextEditingController,
//                       keyboardType: TextInputType.text,
//                       decoration: InputDecoration(
//                         labelText: "User Name",
//                         labelStyle: const TextStyle(
//                           fontSize: 14,
//                         ),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(10.0),
//                           borderSide: const BorderSide(
//                             color: Colors.grey,
//                             width: 1.5,
//                           ),
//                         ),
//                         focusedBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(10.0),
//                           borderSide: const BorderSide(
//                             color: Colors.blue,
//                             width: 2.0,
//                           ),
//                         ),
//                       ),
//                       style: const TextStyle(
//                         color: Colors.grey,
//                         fontSize: 15,
//                       ),
//                     ),
//                     const SizedBox(height: 22),
//
//                     TextField(
//                       controller: userPhonetextEditingController,
//                       keyboardType: TextInputType.number,
//                       decoration: InputDecoration(
//                         labelText: "Phone No",
//                         labelStyle: const TextStyle(
//                           fontSize: 14,
//                         ),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(10.0),
//                           borderSide: const BorderSide(
//                             color: Colors.grey,
//                             width: 1.5,
//                           ),
//                         ),
//                         focusedBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(10.0),
//                           borderSide: const BorderSide(
//                             color: Colors.blue,
//                             width: 2.0,
//                           ),
//                         ),
//                       ),
//                       style: const TextStyle(
//                         color: Colors.grey,
//                         fontSize: 15,
//                       ),
//                     ),
//                     const SizedBox(height: 22),
//
//                     TextField(
//                       controller: emailtextEditingController,
//                       keyboardType: TextInputType.emailAddress,
//                       decoration: InputDecoration(
//                         labelText: "User Email",
//                         labelStyle: const TextStyle(
//                           fontSize: 14,
//                         ),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(10.0),
//                           borderSide: const BorderSide(
//                             color: Colors.grey,
//                             width: 1.5,
//                           ),
//                         ),
//                         focusedBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(10.0),
//                           borderSide: const BorderSide(
//                             color: Colors.blue,
//                             width: 2.0,
//                           ),
//                         ),
//                       ),
//                       style: const TextStyle(
//                         color: Colors.grey,
//                         fontSize: 15,
//                       ),
//                     ),
//                     const SizedBox(height: 22),
//
//                     TextField(
//                       controller: passwordtextEditingController,
//                       obscureText: true,
//                       keyboardType: TextInputType.text,
//                       decoration: InputDecoration(
//                         labelText: "Password",
//                         labelStyle: const TextStyle(
//                           fontSize: 14,
//                         ),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(10.0),
//                           borderSide: const BorderSide(
//                             color: Colors.grey,
//                             width: 1.5,
//                           ),
//                         ),
//                         focusedBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(10.0),
//                           borderSide: const BorderSide(
//                             color: Colors.blue,
//                             width: 2.0,
//                           ),
//                         ),
//                       ),
//                       style: const TextStyle(
//                         color: Colors.grey,
//                         fontSize: 15,
//                       ),
//                     ),
//                     const SizedBox(height: 22),
//
//
//                     const SizedBox(height: 32,),
//
//                     ElevatedButton(onPressed: (){
//                       validateSignUpForm();
//                     },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.green,
//                         padding: const EdgeInsets.symmetric(horizontal: 80,vertical: 10),
//                       ),
//                       child: const Text("Sign Up",style: TextStyle(color: Colors.black),),
//                     ),
//
//                   ],
//                 ),
//               ),
//
//               const SizedBox(height: 12,),
//
//               TextButton(onPressed: (){
//                 Navigator.push(context, MaterialPageRoute(builder: (c) => const SignInPage()));
//               },
//                 child: const Text(
//                   "Already have an Account? Sign In here",
//                   style: TextStyle(
//                       color: Colors.grey
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
