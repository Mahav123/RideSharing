import 'package:flutter/cupertino.dart';
import 'package:vivi_ride_app/model/address_model.dart';

class AppInfo extends ChangeNotifier
{
  AddressModel? pickUpLocation;
  AddressModel? dropOffLocation;

  void updatePickUPLocation(AddressModel pickUpModel)
  {
    pickUpLocation = pickUpModel;
    notifyListeners();
  }

  void updateDropOffLocation(AddressModel dropOffModel)
  {
    dropOffLocation = dropOffModel;
    notifyListeners();
  }
}