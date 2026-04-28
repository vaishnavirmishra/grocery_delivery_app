import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GeocodingService {
  static const String apiKey = "AIzaSyDFlj9etT4eiz8SlziZnN-J-DF2dCnmR5M";

  static Future<LatLng?> getLatLng(String address) async {
    final url =
        "https://maps.googleapis.com/maps/api/geocode/json?address=$address&key=$apiKey";

    final res = await http.get(Uri.parse(url));

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);

      if (data["results"] != null && data["results"].isNotEmpty) {
        final loc = data["results"][0]["geometry"]["location"];

        return LatLng(
          loc["lat"],
          loc["lng"],
        );
      }
    }
    return null;
  }
}