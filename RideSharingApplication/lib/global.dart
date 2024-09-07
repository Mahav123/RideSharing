import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:vivi_ride_app/methods/associate_methods.dart';

AssociateMethods associateMethods = AssociateMethods();

String userName = "";
String userPhone = "";
String userprofile = "";

String googleMapKey = "AIzaSyCY3m7QixbP1m4LHeIbRZnvdm3xBSxepPM";

const CameraPosition kGooglePlex = CameraPosition(
  target: LatLng(37.42796133580664, -122.085749655962),
  zoom: 14.4746,
);
