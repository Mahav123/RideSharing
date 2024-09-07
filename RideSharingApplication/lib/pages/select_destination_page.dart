import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vivi_ride_app/appInfo/app_info.dart';
import 'package:vivi_ride_app/global.dart';
import 'package:vivi_ride_app/methods/google_map_methods.dart';
import 'package:vivi_ride_app/model/prediction_model.dart';
import 'package:vivi_ride_app/widgets/prediction_places_ui.dart';

class SelectDestinationPage extends StatefulWidget {
  const SelectDestinationPage({super.key});

  @override
  State<SelectDestinationPage> createState() => _SelectDestinationPageState();
}

class _SelectDestinationPageState extends State<SelectDestinationPage> {

  TextEditingController pickUpTextEditingController = TextEditingController();
  TextEditingController destinationTextEditingController = TextEditingController();
  List<PredictionModel> dropOffPredictionsPlaceList = [];

  /// Places-api search places autocomplete
  searchLocation(String userInput) async
  {
    if(userInput.length > 1)
    {
      String placeAPIUrl = "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$userInput&key=$googleMapKey&components=country:IN";
      var responseFromPlacesAPI = await GoogleMapsMethods.sendRequestToAPI(placeAPIUrl);

      if(responseFromPlacesAPI == "error")
      {
        return;
      }

      if(responseFromPlacesAPI["status"] == "OK")
      {
       var predictionsResultInJson = responseFromPlacesAPI["predictions"];
       var predictionsResultInNormalForm = (predictionsResultInJson as List).map((eachPredictedPlace) => PredictionModel.fromJson(eachPredictedPlace)).toList();

       setState(() {
         dropOffPredictionsPlaceList = predictionsResultInNormalForm;
       });

      }
    }

  }

  @override
  Widget build(BuildContext context) {

    String pickUpAddressOfUser = Provider.of<AppInfo>(context, listen: true).pickUpLocation!.humanReadableAddress ?? "";
    pickUpTextEditingController.text = pickUpAddressOfUser;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Card(
              elevation: 14,
              child: Container(
                height: 232,
                decoration: const BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white,
                      blurRadius: 5.0,
                      spreadRadius: 0.5,
                      offset: Offset(0.7, 0.7)
                    )
                  ]
                ),
                child: Padding(
                    padding: const EdgeInsets.only(left: 24, top: 28, right: 24, bottom: 20),
                  child: Column(
                    children: [

                      const SizedBox(height: 6,),


                      Stack(
                        children: [
                          /// back button
                          GestureDetector(
                            onTap: ()
                            {
                              Navigator.pop(context);
                            },
                            child: const Icon(Icons.arrow_back, color: Colors.black,),
                          ),

                          /// Title
                          const Center(
                            child: Text(
                              "Search Destination",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18,),

                      ///Pickup Textfield
                      Row(
                        children: [
                          Image.asset(
                            "assets/images/initial.png",
                            width: 16,
                            height: 16,
                          ),
                          const SizedBox(width: 18,),
                          Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white60,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(2),
                                  child: TextField(
                                    controller: pickUpTextEditingController,
                                    decoration: const InputDecoration(
                                      hintText: "PickUp Address",
                                      fillColor: Colors.white12,
                                      filled: true,
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.only(left: 11, top: 9, bottom: 9,),
                                    ),
                                  ),
                                ),
                              ),
                          ),

                        ],
                      ),

                      const SizedBox(height: 10,),

                      /// Destination Textfield
                      Row(
                        children: [
                          Image.asset(
                            "assets/images/final.png",
                            width: 16,
                            height: 16,
                          ),
                          const SizedBox(width: 18,),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(2),
                                child: TextField(
                                  controller: destinationTextEditingController,
                                  onChanged: (userInput)
                                  {
                                    searchLocation(userInput);
                                  },
                                  decoration: const InputDecoration(
                                    hintText: "Search here..",
                                    fillColor: Colors.white12,
                                    filled: true,
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.only(left: 11, top: 9, bottom: 9,),
                                  ),
                                ),
                              ),
                            ),
                          ),

                        ],
                      ),


                    ],
                  ),
                ),
              ),
            ),

            /// display Prediction result for the search place
            (dropOffPredictionsPlaceList.length > 0)
                ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                      itemBuilder: (context, index)
                      {
                        return Card(
                          elevation: 4,
                          child: PredictionPlacesUi(
                            predictionPlacesData: dropOffPredictionsPlaceList[index],
                          ),
                        );
                      },
                      separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 3,),
                      itemCount: dropOffPredictionsPlaceList.length),
                  )
                : Container(),
          ],
        ),
      ),
    );
  }
}
