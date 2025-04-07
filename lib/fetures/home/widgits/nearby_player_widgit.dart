import 'dart:async';
import 'dart:convert';
import 'package:among_us_gdsc/main.dart';
import 'package:among_us_gdsc/provider/marker_provider.dart';
import 'package:among_us_gdsc/services/firestore_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class NearbyPlayersListWidget extends ConsumerStatefulWidget {
  const NearbyPlayersListWidget({Key? key}) : super(key: key);

  @override
  ConsumerState<NearbyPlayersListWidget> createState() => _NearbyPlayersListWidgetState();
}

class _NearbyPlayersListWidgetState extends ConsumerState<NearbyPlayersListWidget> {
  bool isCooldownActive = false;
  late DateTime cooldownEndTime;
  bool _isButtonDisabled = true;
  List<Map<String, dynamic>> nearbyTeams = [];
  late WebSocketChannel _channel;
  Position? _currentPosition;
  Timer? _locationUpdateTimer;
  Map<String, Marker> teamMarkers = {};

  @override
  void initState() {
    super.initState();
    initializeCooldownState();
    _connectToWebSocket();
    _startLocationUpdates();
  }

  void _connectToWebSocket() {
    _channel = WebSocketChannel.connect(
      Uri.parse('wss://amongusbackend-ady5.onrender.com'), // Your server URL
    );

    _channel.stream.listen((message) {
      final data = jsonDecode(message);
      if (data['type'] == 'nearbyTeams' && mounted) {
        setState(() {
          nearbyTeams = List<Map<String, dynamic>>.from(data['nearbyTeams'] ?? []);
          print('Received nearby teams: $nearbyTeams');
          
          // Update markers for each team
          _updateTeamMarkers(data);
        });
      } else if (data['type'] == 'locationUpdates' && mounted) {
        // Handle location updates from all players
        _updateLocationMarkers(data['locations']);
      }
    }, onError: (error) {
      print('WebSocket error: $error');
      // Add reconnection logic here if needed
    });

    // Send initial join message
    _sendTeamJoin();
  }
  
  void _updateTeamMarkers(Map<String, dynamic> data) {
    // Clear existing markers if needed
    teamMarkers.clear();
    
    // Add markers for each team location
    if (data.containsKey('teamsLocations')) {
      Map<String, dynamic> locations = data['teamsLocations'];
      locations.forEach((teamName, location) {
        if (location is Map && location.containsKey('latitude') && location.containsKey('longitude')) {
          double lat = location['latitude'];
          double lng = location['longitude'];
          
          teamMarkers[teamName] = Marker(
            point: LatLng(lat, lng),
            builder: (context) {
              return const Image(
                height: 40,
                width: 40,
                image: AssetImage("assets/locationPin.png"),
              );
            },
          );
        }
      });
      
      // Update the marker provider
      if (mounted) {
        ref.read(teamMarkersProvider.notifier).state = Map.from(teamMarkers);
      }
    }
  }
  
  void _updateLocationMarkers(List<dynamic> locations) {
    if (locations == null) return;
    
    for (var location in locations) {
      if (location is Map && 
          location.containsKey('teamName') && 
          location.containsKey('latitude') && 
          location.containsKey('longitude')) {
        
        String teamName = location['teamName'];
        double lat = location['latitude'];
        double lng = location['longitude'];
        
        teamMarkers[teamName] = Marker(
          point: LatLng(lat, lng),
          builder: (context) {
            return const Image(
              height: 40,
              width: 40,
              image: AssetImage("assets/locationPin.png"),
            );
          },
        );
      }
    }
    
    // Update the marker provider with all markers
    if (mounted) {
      ref.read(teamMarkersProvider.notifier).state = Map.from(teamMarkers);
    }
  }

  Future<void> _startLocationUpdates() async {
    // Get initial position
    await _getCurrentPosition();
    
    // Set up periodic location updates
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      await _getCurrentPosition();
    });
  }

  Future<void> _getCurrentPosition() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
      
      // Send location update to server
      if (_channel.sink != null) {
        _channel.sink.add(jsonEncode({
          'type': 'locationUpdate',
          'teamName': GlobalteamName,
          'latitude': position.latitude,
          'longitude': position.longitude,
        }));
        print('Sent location update: ${position.latitude}, ${position.longitude}');
      }
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  void _sendTeamJoin() {
    if (_channel.sink != null && GlobalteamName != null) {
      _channel.sink.add(jsonEncode({
        'type': 'joinTeam',
        'teamName': GlobalteamName,
      }));
      print('Sent team join: $GlobalteamName');
    }
  }

  Future<void> _fetchNearbyTeams() async {
    if (_currentPosition != null) {
      // Request nearby teams explicitly
      _channel.sink.add(jsonEncode({
        'type': 'getNearbyTeams',
        'teamName': GlobalteamName,
        'latitude': _currentPosition!.latitude,
        'longitude': _currentPosition!.longitude,
      }));
    }
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    _channel.sink.close();
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
    await prefs.setInt('cooldownEndTimeMillis', cooldownEndTime.millisecondsSinceEpoch);
  }

  @override
  Widget build(BuildContext context) {
    final markers = ref.watch(teamMarkersProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Enemies'),
        actions: [
          IconButton(
            onPressed: _fetchNearbyTeams,
            icon: const Icon(Icons.refresh),
          )
        ],
      ),
      body: Column(
        children: [
          // Map section to show markers
          SizedBox(
            height: 200,
            child: FlutterMap(
              options: MapOptions(
                center: _currentPosition != null
                    ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                    : LatLng(0, 0),
                zoom: 15,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                ),
                MarkerLayer(
                  markers: [
                    // Current user marker
                    if (_currentPosition != null)
                      Marker(
                        point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                        builder: (ctx) => const Icon(
                          Icons.location_on,
                          color: Colors.blue,
                          size: 40,
                        ),
                      ),
                    // All team markers
                    ...markers.values.toList(),
                  ],
                ),
              ],
            ),
          ),
          
          // Cooldown timer if active
          if (isCooldownActive)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: CountdownTimer(
                endTime: cooldownEndTime.millisecondsSinceEpoch,
                textStyle: const TextStyle(
                  fontSize: 18,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
                onEnd: () async {
                  SharedPreferences prefs = await SharedPreferences.getInstance();
                  await prefs.remove('isCooldownActive');
                  await prefs.remove('cooldownEndTimeMillis');
                  if (mounted) {
                    setState(() => isCooldownActive = false);
                  }
                },
              ),
            ),
            
          // Nearby players list
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 15, left: 20, right: 20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Nearby Players",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20),
                    ),
                    if (nearbyTeams.isNotEmpty)
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: nearbyTeams.length,
                        itemBuilder: (context, index) {
                          String team = nearbyTeams[index]['teamName'];
                          double distance = nearbyTeams[index]['distance'];
                          return Card(
                            elevation: 3,
                            margin: const EdgeInsets.only(bottom: 10),
                            color: const Color.fromRGBO(255, 200, 200, 1),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    "Team: $team",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
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
                                      return const CircularProgressIndicator();
                                    }
                                    return ListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: teamSnapshot.data!.docs.length,
                                      itemBuilder: (context, playerIndex) {
                                        var playerDoc = teamSnapshot.data!.docs[playerIndex];
                                        return ListTile(
                                          title: Text(
                                            playerDoc["name"],
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          subtitle: Text("${distance.toStringAsFixed(1)}m away"),
                                          trailing: ElevatedButton(
                                            onPressed: isCooldownActive
                                                ? null
                                                : () {
                                                    _channel.sink.add(jsonEncode({
                                                      'type': 'killPlayer',
                                                      'teamName': team,
                                                      'playerId': playerDoc.id,
                                                    }));
                                                    handleKillPlayer(team, playerDoc.id);
                                                    _startCooldown();
                                                  },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(14),
                                              ),
                                            ),
                                            child: const Text(
                                              "Kill",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
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
                      )
                    else
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text(
                            "No teams nearby!",
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
      } catch (e) {
        print("Error removing player: $e");
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
    return Text(
      'Kill Cooldown: ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
      style: widget.textStyle,
    );
  }
}