import 'dart:async';
import 'dart:convert';
import 'dart:math' as Math;
import 'package:among_us_gdsc/main.dart';
import 'package:among_us_gdsc/provider/marker_provider.dart';
import 'package:among_us_gdsc/services/firestore_services.dart';
import 'package:among_us_gdsc/websocket_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

// Create a separate provider for WebSocket markers to avoid mixing with Firebase markers
final webSocketTeamMarkersProvider =
    StateProvider<Map<String, Marker>>((ref) => {});

// Keep the original provider for Firebase markers only
final playerRolesProvider = StateProvider<Map<String, String>>((ref) => {});

class NearbyPlayersListWidget extends ConsumerStatefulWidget {
  const NearbyPlayersListWidget({Key? key}) : super(key: key);

  @override
  ConsumerState<NearbyPlayersListWidget> createState() =>
      _NearbyPlayersListWidgetState();
}

class _NearbyPlayersListWidgetState
    extends ConsumerState<NearbyPlayersListWidget> {
  bool isCooldownActive = false;
  late DateTime cooldownEndTime;
  final bool _isButtonDisabled = true;
  List<Map<String, dynamic>> nearbyTeams = [];
  final WebSocketService _webSocketService =
      WebSocketService(); // Use singleton
  late StreamSubscription<Map<String, dynamic>> _socketSubscription;
  Position? _currentPosition;
  Timer? _locationUpdateTimer;
  Map<String, Marker> webSocketMarkers =
      {}; // Store WebSocket markers separately
  Map<String, Marker> firebaseMarkers = {}; // Store Firebase markers separately
  final MapController _mapController = MapController();
  Map<String, Map<String, String>> teamPlayerRoles = {};
  final DatabaseReference _firebaseLocationRef =
      FirebaseDatabase.instance.ref('location');
  StreamSubscription<DatabaseEvent>? _firebaseLocationSubscription;

  @override
  void initState() {
    super.initState();
    initializeCooldownState();
    _connectToWebSocket();
    _startLocationUpdates();
    _loadTeamPlayerRoles();
    _setupFirebaseLocationListener();
  }

  void _setupFirebaseLocationListener() {
    _firebaseLocationSubscription =
        _firebaseLocationRef.onValue.listen((event) {
      if (!mounted) return;

      final data = event.snapshot.value;
      if (data != null && data is Map) {
        firebaseMarkers.clear(); // Clear existing Firebase markers
        final locations = data;

        locations.forEach((key, value) {
          if (value is Map &&
              value.containsKey('Team') &&
              value.containsKey('Lat') &&
              value.containsKey('Long')) {
            String teamName = value['Team'];
            double lat = value['Lat'].toDouble();
            double lng = value['Long'].toDouble();

            firebaseMarkers[teamName] = _createMarker(
                teamName, LatLng(lat, lng),
                isCurrentTeam: teamName == GlobalteamName);
          }
        });

        if (mounted) {
          // Update the Firebase markers provider
          ref.read(teamMarkersProvider.notifier).state =
              Map.from(firebaseMarkers);
        }
      }
    }, onError: (error) {
      print('Firebase location error: $error');
    });
  }

  Future<void> _loadTeamPlayerRoles() async {
    var teams = await FirebaseFirestore.instance.collection("Teams").get();

    for (var team in teams.docs) {
      var players = await team.reference.collection("players").get();

      if (!teamPlayerRoles.containsKey(team.id)) {
        teamPlayerRoles[team.id] = {};
      }

      for (var player in players.docs) {
        var playerData = await FirebaseFirestore.instance
            .collection("AllPlayers")
            .doc(player.id)
            .get();

        if (playerData.exists) {
          String role = playerData.data()?["Character"] ?? "crewmate";
          teamPlayerRoles[team.id]![player.id] = role;
        }
      }
    }

    ref.read(playerRolesProvider.notifier).state = Map.from(teamPlayerRoles
        .values
        .fold({}, (map, element) => map..addAll(element)));
  }

  void _connectToWebSocket() {
    if (GlobalteamName != null) {
      // Connect using the singleton service
      _webSocketService.connect(GlobalteamName!);
      _webSocketService.addListener();

      // Listen for messages
      _socketSubscription = _webSocketService.messageStream.listen((data) {
        print(data);
        if (data['type'] == 'nearbyTeams' && mounted) {
          setState(() {
            // Get the original teams array
            List<dynamic> teamsData = data['teams'] ?? [];

            // Create a Map to track unique teams by name
            Map<String, Map<String, dynamic>> uniqueTeams = {};

            // Process each team, keeping only the most recent entry for each team name
            for (var team in teamsData) {
              String teamName = team['teamName'];
              uniqueTeams[teamName] = team;
            }

            // Convert back to List
            nearbyTeams =
                uniqueTeams.values.toList().cast<Map<String, dynamic>>();

            _updateWebSocketMarkers(
                data); // Use a separate method for WebSocket markers
          });
        } else if (data['type'] == 'locationUpdates' && mounted) {
          _updateWebSocketLocationMarkers(data['locations']);
        }
      });

      // Send initial join message
      _sendTeamJoin();
    }
  }

  void _updateWebSocketMarkers(Map<String, dynamic> data) {
    webSocketMarkers.clear(); // Clear existing WebSocket markers

    if (_currentPosition != null) {
      webSocketMarkers[GlobalteamName!] = _createMarker(GlobalteamName!,
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          isCurrentTeam: true);
    }

    // Use the unique nearby teams list to update markers
    for (var team in nearbyTeams) {
      String teamName = team['teamName'];
      // Check if location exists in team data or use distance-based approach
      if (team.containsKey('location')) {
        double lat = team['location']['latitude'];
        double lng = team['location']['longitude'];

        webSocketMarkers[teamName] = _createMarker(teamName, LatLng(lat, lng));
      } else if (_currentPosition != null) {
        // If no exact location, but we have distance, we can approximate
        // this is a simple approach that places markers in a circle around the player
        double distance = team['distance'].toDouble();
        double bearing =
            nearbyTeams.indexOf(team) * 45.0; // spread teams around

        // This is a simple approximation - for real geodesic calculations you'd use a proper algorithm
        double lat = _currentPosition!.latitude +
            (distance / 111320) * Math.cos(bearing * Math.pi / 180);
        double lng = _currentPosition!.longitude +
            (distance /
                    (111320 *
                        Math.cos(_currentPosition!.latitude * Math.pi / 180))) *
                Math.sin(bearing * Math.pi / 180);

        webSocketMarkers[teamName] = _createMarker(teamName, LatLng(lat, lng));
      }
    }

    if (mounted) {
      // Update the WebSocket markers provider only
      ref.read(webSocketTeamMarkersProvider.notifier).state =
          Map.from(webSocketMarkers);
    }
  }

  Marker _createMarker(String teamName, LatLng position,
      {bool isCurrentTeam = false}) {
    bool hasImposter = teamPlayerRoles.containsKey(teamName) &&
        teamPlayerRoles[teamName]!.values.contains("imposter");

    return Marker(
      point: position,
      builder: (context) {
        return SizedBox(
            height: 40,
            width: 40,
            child: const Image(image: AssetImage("assets/locationPin.png")));
      },
    );
  }

  void _updateWebSocketLocationMarkers(List<dynamic> locations) {
    for (var location in locations) {
      if (location is Map &&
          location.containsKey('teamName') &&
          location.containsKey('latitude') &&
          location.containsKey('longitude')) {
        String teamName = location['teamName'];
        double lat = location['latitude'];
        double lng = location['longitude'];

        webSocketMarkers[teamName] = _createMarker(teamName, LatLng(lat, lng),
            isCurrentTeam: teamName == GlobalteamName);
      }
    }

    if (mounted) {
      // Update the WebSocket markers provider only
      ref.read(webSocketTeamMarkersProvider.notifier).state =
          Map.from(webSocketMarkers);
    }
  }

  Future<void> _startLocationUpdates() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    await _getCurrentPosition();

    _locationUpdateTimer =
        Timer.periodic(const Duration(seconds: 5), (timer) async {
      await _getCurrentPosition();
    });
  }

  Future<void> _getCurrentPosition() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() => _currentPosition = position);

        if (webSocketMarkers.isEmpty) {
          _mapController.move(
              LatLng(position.latitude, position.longitude), 15.0);
        }
      }

      // Send location update through WebSocket service
      _webSocketService.send({
        'type': 'locationUpdate',
        'teamName': GlobalteamName,
        'latitude': position.latitude,
        'longitude': position.longitude,
      });
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  void _sendTeamJoin() {
    if (GlobalteamName != null) {
      _webSocketService.send({
        'type': 'joinTeam',
        'teamName': GlobalteamName,
      });
    }
  }

  Future<void> _fetchNearbyTeams() async {
    if (_currentPosition != null) {
      _webSocketService.send({
        'type': 'getNearbyTeams',
        'teamName': GlobalteamName,
        'latitude': _currentPosition!.latitude,
        'longitude': _currentPosition!.longitude,
      });
      await _loadTeamPlayerRoles();
    }
  }

  @override
  void dispose() {
    _firebaseLocationSubscription?.cancel();
    _locationUpdateTimer?.cancel();
    _socketSubscription.cancel();
    _webSocketService.removeListener(); // Properly unregister
    super.dispose();
  }

  Future<void> initializeCooldownState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isCooldownActive = prefs.getBool('isCooldownActive') ?? false;
      int? endTimeMillis = prefs.getInt('cooldownEndTimeMillis');
      cooldownEndTime = endTimeMillis != null
          ? DateTime.fromMillisecondsSinceEpoch(endTimeMillis)
          : DateTime.now();
    });
  }

  Future<void> _startCooldown() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isCooldownActive = true;
      cooldownEndTime = DateTime.now().add(const Duration(minutes: 1));
    });
    await prefs.setBool('isCooldownActive', true);
    await prefs.setInt(
        'cooldownEndTimeMillis', cooldownEndTime.millisecondsSinceEpoch);
  }

  @override
  Widget build(BuildContext context) {
    final markers =
        ref.watch(webSocketTeamMarkersProvider); // Use WebSocket markers for UI

    return Scaffold(
      appBar: AppBar(
        title: const Text('Keep refreshing!',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color.fromRGBO(255, 249, 219, 1),
        foregroundColor: Colors.black,
        actions: [
          IconButton(
              onPressed: _fetchNearbyTeams, icon: const Icon(Icons.refresh))
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromRGBO(255, 249, 219, 1),
              Color.fromRGBO(110, 97, 62, 1)
            ],
          ),
        ),
        child: Column(
          children: [
            if (isCooldownActive)
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: CountdownTimer(
                  endTime: cooldownEndTime.millisecondsSinceEpoch,
                  textStyle: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  onEnd: () async {
                    SharedPreferences prefs =
                        await SharedPreferences.getInstance();
                    await prefs.remove('isCooldownActive');
                    await prefs.remove('cooldownEndTimeMillis');
                    if (mounted) setState(() => isCooldownActive = false);
                  },
                ),
              ),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color.fromRGBO(110, 97, 62, 1),
                            const Color.fromRGBO(110, 97, 62, 0.8)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.people_alt, color: Colors.white, size: 24),
                          SizedBox(width: 10),
                          Text(
                            "Nearby Players",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: nearbyTeams.isEmpty
                          ? Center(
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.grey[300]!,
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.search_off,
                                        size: 48, color: Colors.grey[500]),
                                    const SizedBox(height: 16),
                                    const Text(
                                      "No teams nearby!",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Keep exploring to find enemies",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: nearbyTeams.length,
                              itemBuilder: (context, index) {
                                String team = nearbyTeams[index]['teamName'];
                                double distance =
                                    nearbyTeams[index]['distance'];
                                bool hasImposter =
                                    teamPlayerRoles.containsKey(team) &&
                                        teamPlayerRoles[team]!
                                            .values
                                            .contains("imposter");

                                return Card(
                                  elevation: 4,
                                  margin: const EdgeInsets.symmetric(
                                      vertical: 8, horizontal: 4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(
                                      color: hasImposter
                                          ? const Color.fromRGBO(110, 97, 62, 1)
                                              .withOpacity(0.5)
                                          : const Color.fromRGBO(
                                                  255, 249, 219, 1)
                                              .withOpacity(0.5),
                                      width: 2,
                                    ),
                                  ),
                                  color: hasImposter
                                      ? const Color.fromRGBO(255, 249, 219, 0.8)
                                      : const Color.fromRGBO(255, 249, 219, 1),
                                  child: Column(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          color: hasImposter
                                              ? const Color.fromRGBO(
                                                  110, 97, 62, 1)
                                              : const Color.fromRGBO(
                                                  110, 97, 62, 0.8),
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(14),
                                            topRight: Radius.circular(14),
                                          ),
                                        ),
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10, horizontal: 16),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              hasImposter
                                                  ? Icons.warning
                                                  : Icons.groups,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              "Team: $team",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                                color: Colors.white,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                      StreamBuilder(
                                        stream: FirebaseFirestore.instance
                                            .collection("Teams")
                                            .doc(team)
                                            .collection("players")
                                            .snapshots(),
                                        builder: (context, teamSnapshot) {
                                          if (!teamSnapshot.hasData) {
                                            return const Center(
                                              child: Padding(
                                                padding: EdgeInsets.all(20.0),
                                                child:
                                                    CircularProgressIndicator(),
                                              ),
                                            );
                                          }
                                          return ListView.builder(
                                            shrinkWrap: true,
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            itemCount:
                                                teamSnapshot.data!.docs.length,
                                            itemBuilder:
                                                (context, playerIndex) {
                                              var playerDoc = teamSnapshot
                                                  .data!.docs[playerIndex];
                                              bool isImposter = teamPlayerRoles
                                                      .containsKey(team) &&
                                                  teamPlayerRoles[team]!
                                                      .containsKey(
                                                          playerDoc.id) &&
                                                  teamPlayerRoles[team]![
                                                          playerDoc.id] ==
                                                      "imposter";

                                              return Container(
                                                decoration: BoxDecoration(
                                                  border: Border(
                                                    bottom: BorderSide(
                                                      color: Colors.grey[300]!,
                                                      width: playerIndex <
                                                              teamSnapshot
                                                                      .data!
                                                                      .docs
                                                                      .length -
                                                                  1
                                                          ? 1
                                                          : 0,
                                                    ),
                                                  ),
                                                ),
                                                child: ListTile(
                                                  contentPadding:
                                                      const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 16,
                                                          vertical: 6),
                                                  leading: Container(
                                                    width: 40,
                                                    height: 40,
                                                    decoration: BoxDecoration(
                                                      color: isImposter
                                                          ? const Color
                                                              .fromRGBO(
                                                              110, 97, 62, 0.2)
                                                          : const Color
                                                              .fromRGBO(255,
                                                              249, 219, 0.5),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Icon(
                                                      isImposter
                                                          ? Icons.dangerous
                                                          : Icons.person,
                                                      color: isImposter
                                                          ? const Color
                                                              .fromRGBO(
                                                              110, 97, 62, 1)
                                                          : const Color
                                                              .fromRGBO(
                                                              110, 97, 62, 0.8),
                                                      size: 24,
                                                    ),
                                                  ),
                                                  title: Text(
                                                    playerDoc["name"],
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                      color: isImposter
                                                          ? const Color
                                                              .fromRGBO(
                                                              110, 97, 62, 1)
                                                          : Colors.black,
                                                    ),
                                                  ),
                                                  subtitle: Row(
                                                    children: [
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        "Kill this ant !",
                                                        style: TextStyle(
                                                            color: Colors
                                                                .grey[700]),
                                                      ),
                                                    ],
                                                  ),
                                                  trailing: isCooldownActive
                                                      ? const Padding(
                                                          padding: EdgeInsets
                                                              .symmetric(
                                                                  horizontal:
                                                                      8.0),
                                                          child: Icon(
                                                              Icons.timer,
                                                              color:
                                                                  Colors.grey,
                                                              size: 28),
                                                        )
                                                      : Container(
                                                          width: 80,
                                                          height: 40,
                                                          decoration:
                                                              BoxDecoration(
                                                            gradient:
                                                                const LinearGradient(
                                                              colors: [
                                                                Color.fromRGBO(
                                                                    110,
                                                                    97,
                                                                    62,
                                                                    1),
                                                                Color.fromRGBO(
                                                                    110,
                                                                    97,
                                                                    62,
                                                                    0.8)
                                                              ],
                                                              begin: Alignment
                                                                  .topCenter,
                                                              end: Alignment
                                                                  .bottomCenter,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12),
                                                            boxShadow: [
                                                              BoxShadow(
                                                                color: const Color
                                                                        .fromRGBO(
                                                                        110,
                                                                        97,
                                                                        62,
                                                                        1)
                                                                    .withOpacity(
                                                                        0.4),
                                                                spreadRadius: 1,
                                                                blurRadius: 4,
                                                                offset:
                                                                    const Offset(
                                                                        0, 2),
                                                              ),
                                                            ],
                                                          ),
                                                          child: Material(
                                                            color: Colors
                                                                .transparent,
                                                            child: InkWell(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          12),
                                                              onTap:
                                                                  isCooldownActive
                                                                      ? null
                                                                      : () {
                                                                          _webSocketService
                                                                              .send({
                                                                            'type':
                                                                                'killPlayer',
                                                                            'teamName':
                                                                                team,
                                                                            'playerId':
                                                                                playerDoc.id,
                                                                          });
                                                                          handleKillPlayer(
                                                                              team,
                                                                              playerDoc.id);
                                                                          _startCooldown();
                                                                        },
                                                              child:
                                                                  const Center(
                                                                child: Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .center,
                                                                  children: [
                                                                    Icon(
                                                                        Icons
                                                                            .local_fire_department,
                                                                        color: Colors
                                                                            .white,
                                                                        size:
                                                                            20),
                                                                    SizedBox(
                                                                        width:
                                                                            4),
                                                                    Text(
                                                                      "Kill",
                                                                      style:
                                                                          TextStyle(
                                                                        color: Colors
                                                                            .white,
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        fontSize:
                                                                            16,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> handleKillPlayer(String team, String playerId) async {
    if (!isCooldownActive) {
      try {
        var fireStoreInstance = FirebaseFirestore.instance;
        bool isImposter =
            await FirestoreServices().isPlayerAliveImposter(playerId);
        if (isImposter) {
          await fireStoreInstance
              .collection("Teams")
              .doc(team)
              .collection("players")
              .doc(playerId)
              .delete();

          await FirestoreServices().markPlayerAsDead(playerId);

          String? newImposter =
              await FirestoreServices().getFirstAlivePlayerEmailByTeam(team);

          if (newImposter != null) {
            await fireStoreInstance
                .collection("AllPlayers")
                .doc(newImposter)
                .update({"Character": "imposter"});

            if (teamPlayerRoles.containsKey(team)) {
              teamPlayerRoles[team]![newImposter] = "imposter";
              ref.read(playerRolesProvider.notifier).state = Map.from(
                  teamPlayerRoles.values
                      .fold({}, (map, element) => map..addAll(element)));
            }
          }
        } else {
          await fireStoreInstance
              .collection("Teams")
              .doc(team)
              .collection("players")
              .doc(playerId)
              .delete();

          await FirestoreServices().markPlayerAsDead(playerId);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 10),
                Text("Player eliminated from $team!"),
              ],
            ),
            backgroundColor: const Color.fromRGBO(110, 97, 62, 1),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );

        await _loadTeamPlayerRoles();
      } catch (e) {
        print("Error removing player: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 10),
                Text("Failed to eliminate player"),
              ],
            ),
            backgroundColor: Colors.grey[800],
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }
}

class CountdownTimer extends StatefulWidget {
  final int endTime;
  final TextStyle textStyle;
  final Function()? onEnd;

  const CountdownTimer({
    required this.endTime,
    required this.textStyle,
    this.onEnd,
    Key? key,
  }) : super(key: key);

  @override
  _CountdownTimerState createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late Timer _timer;
  late int _remainingSeconds;

  @override
  void initState() {
    super.initState();
    _remainingSeconds =
        ((widget.endTime - DateTime.now().millisecondsSinceEpoch) / 1000)
            .floor();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingSeconds -= 1;
        if (_remainingSeconds <= 0) {
          _timer.cancel();
          widget.onEnd?.call();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int minutes = (_remainingSeconds / 60).floor();
    int seconds = _remainingSeconds % 60;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color.fromRGBO(110, 97, 62, 1),
            const Color.fromRGBO(110, 97, 62, 0.8)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(110, 97, 62, 1).withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.timer, color: Colors.white, size: 22),
          const SizedBox(width: 8),
          Text(
            'Kill Cooldown: ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
