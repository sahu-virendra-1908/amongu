import 'dart:math';

import 'package:flutter_map_math/flutter_geo_math.dart';
import 'package:graphx/graphx.dart';
import 'package:latlong2/latlong.dart';

// Function to calculate the distance between two points using the Haversine formula
num calculateDistance(num lat1, num lon1, num lat2, num lon2) {
  const num earthRadius = 6371; // Radius of the earth in kilometers

  // Convert degrees to radians
  num toRadians(num degrees) {
    return degrees * pi / 180;
  }

  // Haversine formula
  num dLat = toRadians(lat2 - lat1);
  num dLon = toRadians(lon2 - lon1);

  num a = pow(sin(dLat / 2), 2) +
      cos(toRadians(lat1)) * cos(toRadians(lat2)) * pow(sin(dLon / 2), 2);
  num c = 2 * atan2(sqrt(a), sqrt(1 - a));

  return earthRadius * c * 1000; // Distance in meter
}

double getDistanceFromLatLonInKm(lat1, lon1, lat2, lon2) {
  var R = 6371; // Radius of the earth in km
  var dLat = deg2rad(lat2 - lat1); // deg2rad below
  var dLon = deg2rad(lon2 - lon1);
  var a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(deg2rad(lat1)) *
          Math.cos(deg2rad(lat2)) *
          Math.sin(dLon / 2) *
          Math.sin(dLon / 2);
  var c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  var d = R * c; // Distance in km
  return d * 1000;
}

double deg2rad(deg) {
  return deg * (Math.PI / 180);
}

// Function to check if a destination point is within a specified radius of a source point
bool isWithinRadius(
    num destLat, num destLon, num sourceLat, num sourceLon, num radius) {
  // Calculate the distance between the source and destination points
  final func = FlutterMapMath();
  num distance = func.distanceBetween(sourceLat.toDouble(),
      sourceLon.toDouble(), destLat.toDouble(), destLon.toDouble(), "meters");

  // Check if the distance is less than or equal to the specified radius
  return distance <= radius;
}
