class AddressModel
{
  String? humanReadableAddress;
  double? latitudePosition;
  double? longitudePosition;
  String? placeId;
  String? placeName;

  AddressModel({
    this.humanReadableAddress,
    this.latitudePosition,
    this.longitudePosition,
    this.placeId,
    this.placeName,
  });
}