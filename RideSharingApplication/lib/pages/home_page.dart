import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:vivi_ride_app/auth/sign_in_page.dart';
import 'package:vivi_ride_app/global.dart';
import 'package:vivi_ride_app/methods/google_map_methods.dart';
import 'package:vivi_ride_app/pages/select_destination_page.dart';
import '../appInfo/app_info.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double bottomMapPadding = 0;
  double searchContainerHeight = 220;
  GlobalKey<ScaffoldState> sKey = GlobalKey<ScaffoldState>();

  final Completer<GoogleMapController> googleMapCompleterController = Completer<GoogleMapController>();
  GoogleMapController? controllerGoogleMap;
  Position? currentPositionOfUser;

  @override
  void initState() {
    super.initState();
    getCurrentLocation();
  }

  Future<void> getCurrentLocation() async {
    try {
      LocationSettings locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
      );
      Position userPosition = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );
      currentPositionOfUser = userPosition;

      LatLng userLatLng = LatLng(currentPositionOfUser!.latitude, currentPositionOfUser!.longitude);

      CameraPosition positionCamera = CameraPosition(target: userLatLng, zoom: 15);
      controllerGoogleMap!.animateCamera(CameraUpdate.newCameraPosition(positionCamera));

      await GoogleMapsMethods.convertGeoGraphicCoOrdinatesIntoHumanReadableAddress(
          currentPositionOfUser!, context);

      await getUserInfoAndCheckBlockStatus();
    } catch (e) {
      _showSnackBar("Error fetching location: $e");
    }
  }

  Future<void> getUserInfoAndCheckBlockStatus() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        if (userData["blockStatus"] == "no") {
          setState(() {
            userName = userData["name"];
            userPhone = userData["phone"];
            userprofile = userData["photoURL"];
          });
        } else {
          FirebaseAuth.instance.signOut();
          _showSnackBar("You are blocked. For contact email: vivigroups.inc@gmail.com");
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const SignInPage()));
        }
      } else {
        FirebaseAuth.instance.signOut();
        _showSnackBar("No user data found. Please sign in again.");
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const SignInPage()));
      }
    } catch (e) {
      _showSnackBar("Error checking user status: $e");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      key: sKey,
      drawer: _buildDrawer(screenWidth),
      body: SafeArea(
        child: Stack(
          children: [
            _buildGoogleMap(),
            _buildDrawerButton(),
            _buildBottomContainer(screenHeight, screenWidth),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(double screenWidth) {
    return SizedBox(
      width: screenWidth * 0.7,
      child: Drawer(
        child: ListView(
          children: [
            _buildDrawerHeader(screenWidth),
            _buildDrawerItem(Icons.history, "History", () {}),
            _buildDrawerItem(Icons.info, "About", () {}),
            _buildDrawerItem(Icons.logout, "Logout", () {
              FirebaseAuth.instance.signOut();
              _showSnackBar("Logout successfully.");
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (c) => const SignInPage()));
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(double screenWidth) {
    return SizedBox(
      height: 200,
      child: DrawerHeader(
        decoration: const BoxDecoration(color: Colors.white),
        child: Row(
          children: [
            ClipOval(
              child: Image.network(
                userprofile,
                width: screenWidth * 0.13,
                height: screenWidth * 0.13,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset(
                    'assets/images/avatar.webp',
                    width: screenWidth * 0.13,
                    height: screenWidth * 0.13,
                    fit: BoxFit.cover,
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    userName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Profile",
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: ListTile(
        leading: Icon(icon, color: Colors.black),
        title: Text(title, style: const TextStyle(color: Colors.black)),
      ),
    );
  }

  Widget _buildGoogleMap() {
    return GoogleMap(
      padding: EdgeInsets.only(top: 26, bottom: bottomMapPadding),
      mapType: MapType.normal,
      myLocationEnabled: true,
      initialCameraPosition: kGooglePlex,
      onMapCreated: (GoogleMapController mapController) {
        controllerGoogleMap = mapController;
        googleMapCompleterController.complete(controllerGoogleMap);
        getCurrentLocation();
      },
    );
  }

  Widget _buildDrawerButton() {
    return Positioned(
      top: 37,
      left: 20,
      child: GestureDetector(
        onTap: () {
          sKey.currentState!.openDrawer();
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Colors.grey,
                blurRadius: 5,
                spreadRadius: 0.5,
                offset: Offset(0.7, 0.7),
              ),
            ],
          ),
          child: const CircleAvatar(
            backgroundColor: Colors.white,
            radius: 20,
            child: Icon(Icons.menu),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomContainer(double screenHeight, double screenWidth) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: AnimatedSize(
        curve: Curves.easeInOut,
        duration: const Duration(milliseconds: 122),
        child: Container(
          height: screenHeight * 0.25,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(21),
              topLeft: Radius.circular(21),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06, vertical: 18),
            child: Column(
              children: [
                _buildLocationRow(
                  Icons.location_on_outlined,
                  "From",
                  Provider.of<AppInfo>(context, listen: true).pickUpLocation?.placeName ?? "Please wait...",
                      () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (c) => const SelectDestinationPage()));
                  },
                ),
                const Divider(height: 1, thickness: 1, color: Colors.grey),
                SizedBox(height: screenHeight * 0.02),
                _buildLocationRow(
                  Icons.add_location_alt_outlined,
                  "To",
                  "Where to go",
                      () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (c) => const SelectDestinationPage()));
                  },
                ),
                const Divider(height: 1, thickness: 1, color: Colors.grey),
                SizedBox(height: screenHeight * 0.02),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (c) => const SelectDestinationPage()));
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.lightGreen),
                  child: const Text("Select Destination", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationRow(
      IconData icon,
      String label,
      String value,
      VoidCallback onTap,
      ) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Row(
      children: [
        Icon(icon, color: Colors.grey),
        const SizedBox(width: 13.0),
        GestureDetector(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 5),
              SizedBox(
                width: screenWidth * 0.7,
                child: Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


// import 'dart:async';
// import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:provider/provider.dart';
// import 'package:vivi_ride_app/auth/sign_in_page.dart';
// import 'package:vivi_ride_app/global.dart';
// import 'package:vivi_ride_app/methods/google_map_methods.dart';
// import 'package:vivi_ride_app/pages/select_destination_page.dart';
// import '../appInfo/app_info.dart';
//
// class HomePage extends StatefulWidget {
//   const HomePage({super.key});
//
//   @override
//   State<HomePage> createState() => _HomePageState();
// }
//
// class _HomePageState extends State<HomePage> {
//   double bottomMapPadding = 0;
//   double searchContainerHeight = 220;
//   GlobalKey<ScaffoldState> sKey = GlobalKey<ScaffoldState>();
//
//   final Completer<GoogleMapController> googleMapCompleterController =
//   Completer<GoogleMapController>();
//   GoogleMapController? controllerGoogleMap;
//   Position? currentPositionOfUser;
//
//   @override
//   void initState() {
//     super.initState();
//     getCurrentLocation();
//   }
//
//   Future<void> getCurrentLocation() async {
//     try {
//       LocationSettings locationSettings = const LocationSettings(
//         accuracy: LocationAccuracy.bestForNavigation,
//       );
//       Position userPosition = await Geolocator.getCurrentPosition(
//         locationSettings: locationSettings,
//       );
//       currentPositionOfUser = userPosition;
//
//       LatLng userLatLng =
//       LatLng(currentPositionOfUser!.latitude, currentPositionOfUser!.longitude);
//
//       CameraPosition positionCamera = CameraPosition(target: userLatLng, zoom: 15);
//       controllerGoogleMap!.animateCamera(CameraUpdate.newCameraPosition(positionCamera));
//
//       await GoogleMapsMethods.convertGeoGraphicCoOrdinatesIntoHumanReadableAddress(
//           currentPositionOfUser!, context);
//
//       await getUserInfoAndCheckBlockStatus();
//     } catch (e) {
//       _showSnackBar("Error fetching location: $e");
//     }
//   }
//
//   Future<void> getUserInfoAndCheckBlockStatus() async {
//     try {
//       DocumentSnapshot userDoc = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(FirebaseAuth.instance.currentUser!.uid)
//           .get();
//
//       if (userDoc.exists) {
//         final userData = userDoc.data() as Map<String, dynamic>;
//         if (userData["blockStatus"] == "no") {
//           setState(() {
//             userName = userData["name"];
//             userPhone = userData["phone"];
//             userprofile = userData["photoURL"];
//           });
//         } else {
//           FirebaseAuth.instance.signOut();
//           _showSnackBar("You are blocked. For contact email: vivigroups.inc@gmail.com");
//           Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const SignInPage()));
//         }
//       } else {
//         FirebaseAuth.instance.signOut();
//         _showSnackBar("No user data found. Please sign in again.");
//         Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const SignInPage()));
//       }
//     } catch (e) {
//       _showSnackBar("Error checking user status: $e");
//     }
//   }
//
//   void _showSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     // Get the device's screen size
//     final screenHeight = MediaQuery.of(context).size.height;
//     final screenWidth = MediaQuery.of(context).size.width;
//
//     return Scaffold(
//       key: sKey,
//       drawer: _buildDrawer(screenWidth),
//       body: Stack(
//         children: [
//           _buildGoogleMap(),
//           _buildDrawerButton(),
//           _buildBottomContainer(screenHeight, screenWidth),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildDrawer(double screenWidth) {
//     return SizedBox(
//       width: screenWidth * 0.7, // Drawer width is 70% of the screen width
//       child: Drawer(
//         child: ListView(
//           children: [
//             _buildDrawerHeader(screenWidth),
//             _buildDrawerItem(Icons.history, "History", () {}),
//             _buildDrawerItem(Icons.info, "About", () {}),
//             _buildDrawerItem(Icons.logout, "Logout", () {
//               FirebaseAuth.instance.signOut();
//               _showSnackBar("Logout successfully.");
//               Navigator.pushReplacement(
//                   context, MaterialPageRoute(builder: (c) => const SignInPage()));
//             }),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildDrawerHeader(double screenWidth) {
//     return SizedBox(
//       height: 200,
//       child: DrawerHeader(
//         decoration: const BoxDecoration(color: Colors.white),
//         child: Row(
//           children: [
//             ClipOval(
//               child: Image.network(
//                 userprofile,
//                 width: screenWidth * 0.13, // Responsive image width
//                 height: screenWidth * 0.13, // Responsive image height
//                 fit: BoxFit.cover,
//                 errorBuilder: (context, error, stackTrace) {
//                   return Image.asset(
//                     'assets/images/avatar.webp',
//                     width: screenWidth * 0.13,
//                     height: screenWidth * 0.13,
//                     fit: BoxFit.cover,
//                   );
//                 },
//               ),
//             ),
//             const SizedBox(width: 16),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Text(
//                     userName,
//                     style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                   ),
//                   const SizedBox(height: 4),
//                   const Text(
//                     "Profile",
//                     style: TextStyle(color: Colors.black54),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
//     return GestureDetector(
//       onTap: onTap,
//       child: ListTile(
//         leading: Icon(icon, color: Colors.black),
//         title: Text(title, style: const TextStyle(color: Colors.black)),
//       ),
//     );
//   }
//
//   Widget _buildGoogleMap() {
//     return GoogleMap(
//       padding: EdgeInsets.only(top: 26, bottom: bottomMapPadding),
//       mapType: MapType.normal,
//       myLocationEnabled: true,
//       initialCameraPosition: kGooglePlex,
//       onMapCreated: (GoogleMapController mapController) {
//         controllerGoogleMap = mapController;
//         googleMapCompleterController.complete(controllerGoogleMap);
//         getCurrentLocation();
//       },
//     );
//   }
//
//   Widget _buildDrawerButton() {
//     return Positioned(
//       top: 37,
//       left: 20,
//       child: GestureDetector(
//         onTap: () {
//           sKey.currentState!.openDrawer();
//         },
//         child: Container(
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(20),
//             boxShadow: const [
//               BoxShadow(
//                 color: Colors.grey,
//                 blurRadius: 5,
//                 spreadRadius: 0.5,
//                 offset: Offset(0.7, 0.7),
//               ),
//             ],
//           ),
//           child: const CircleAvatar(
//             backgroundColor: Colors.white,
//             radius: 20,
//             child: Icon(Icons.menu),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildBottomContainer(double screenHeight, double screenWidth) {
//     return Positioned(
//       bottom: 0,
//       left: 0,
//       right: 0,
//       child: AnimatedSize(
//         curve: Curves.easeInOut,
//         duration: const Duration(milliseconds: 122),
//         child: Container(
//           height: screenHeight * 0.25, // Responsive height (25% of screen height)
//           decoration: const BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.only(
//               topRight: Radius.circular(21),
//               topLeft: Radius.circular(21),
//             ),
//           ),
//           child: Padding(
//             padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06, vertical: 18), // Responsive padding
//             child: Column(
//               children: [
//                 _buildLocationRow(
//                   Icons.location_on_outlined,
//                   "From",
//                   Provider.of<AppInfo>(context, listen: true).pickUpLocation?.placeName ??
//                       "Please wait...",
//                       () {
//                     Navigator.push(context,
//                         MaterialPageRoute(builder: (c) => const SelectDestinationPage()));
//                   },
//                 ),
//                 const Divider(height: 1, thickness: 1, color: Colors.grey),
//                 SizedBox(height: screenHeight * 0.02), // Responsive spacing
//                 _buildLocationRow(
//                   Icons.add_location_alt_outlined,
//                   "To",
//                   "Where to go",
//                       () {
//                     Navigator.push(context,
//                         MaterialPageRoute(builder: (c) => const SelectDestinationPage()));
//                   },
//                 ),
//                 const Divider(height: 1, thickness: 1, color: Colors.grey),
//                 SizedBox(height: screenHeight * 0.02), // Responsive spacing
//                 ElevatedButton(
//                   onPressed: () {
//                     Navigator.push(context,
//                         MaterialPageRoute(builder: (c) => const SelectDestinationPage()));
//                   },
//                   style: ElevatedButton.styleFrom(backgroundColor: Colors.lightGreen),
//                   child: const Text("Select Destination", style: TextStyle(color: Colors.white)),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildLocationRow(
//       IconData icon,
//       String label,
//       String value,
//       VoidCallback onTap,
//       ) {
//     // Get the screen width for dynamic sizing
//     final screenWidth = MediaQuery.of(context).size.width;
//
//     return Row(
//       children: [
//         Icon(icon, color: Colors.grey),
//         const SizedBox(width: 13.0),
//         GestureDetector(
//           onTap: onTap,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(label, style: const TextStyle(fontSize: 12)),
//               const SizedBox(height: 5),
//               // Make the value Text widget responsive
//               SizedBox(
//                 width: screenWidth * 0.7, // Adjust width to 70% of the screen width
//                 child: Text(
//                   value,
//                   overflow: TextOverflow.ellipsis, // Handle overflow with ellipsis
//                   style: const TextStyle(fontSize: 12),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }
