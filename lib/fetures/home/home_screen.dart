import 'dart:async';
import 'dart:convert';
import 'package:among_us_gdsc/core/geolocator_services.dart';
import 'package:among_us_gdsc/fetures/death_screen/dead_screen.dart';
import 'package:among_us_gdsc/fetures/home/widgits/map_widgit.dart';
import 'package:among_us_gdsc/fetures/home/widgits/nearby_player_widgit.dart';
import 'package:among_us_gdsc/fetures/home/widgits/taskList1.dart';
import 'package:among_us_gdsc/fetures/home/widgits/taskList2.dart';
import 'package:among_us_gdsc/fetures/voting/voting_screen.dart';
import 'package:among_us_gdsc/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:sliding_sheet2/sliding_sheet2.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.teamName});

  final String teamName;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CollectionReference _allPlayersCollection =
      FirebaseFirestore.instance.collection("AllPlayers");
  late Timer _locationUpdateTimer;
  late WebSocketChannel _channel;
  bool _isSocketConnected = false;

  late final GeolocatorServices _geolocatorServices;
  late final StreamSubscription<DocumentSnapshot> _playerDataSubscription;
  Position? _currentLocation;
  String _playerRole = '';

  @override
  void initState() {
    super.initState();
    _geolocatorServices = GeolocatorServices();
    _subscribeToPlayerData();
    _connectToWebSocket();

    _locationUpdateTimer =
        Timer.periodic(const Duration(seconds: 2), (timer) {
      _updatePlayerLocation();
    });
  }

  void _connectToWebSocket() {
    _channel = WebSocketChannel.connect(
      Uri.parse('wss://amongusbackend-ady5.onrender.com/ws'), // Your WebSocket URL
    );

    _channel.stream.listen(
      (message) {
        final data = jsonDecode(message);
        if (data['type'] == 'emergencyMeeting') {
          _handleEmergencyMeeting(data);
        } else if (data['type'] == 'playerKilled') {
          _handlePlayerKilled(data);
        }
      },
      onError: (error) {
        print('WebSocket error: $error');
        setState(() => _isSocketConnected = false);
        Future.delayed(const Duration(seconds: 5), _connectToWebSocket);
      },
      onDone: () {
        print('WebSocket connection closed');
        setState(() => _isSocketConnected = false);
        _connectToWebSocket();
      },
    );

    // Send initial join message
    _channel.sink.add(jsonEncode({
      'type': 'join',
      'teamName': widget.teamName,
      'email': FirebaseAuth.instance.currentUser!.email,
    }));

    setState(() => _isSocketConnected = true);
  }

  void _handleEmergencyMeeting(Map<String, dynamic> data) {
    print('Emergency meeting called: $data');
    // Navigate to voting screen if needed
  }

  void _handlePlayerKilled(Map<String, dynamic> data) {
    print('Player killed: $data');
    if (data['email'] == FirebaseAuth.instance.currentUser!.email) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (ctx) => const DeathScreen()),
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _locationUpdateTimer.cancel();
    _playerDataSubscription.cancel();
    _channel.sink.close();
    super.dispose();
  }

  void _subscribeToPlayerData() {
    _playerDataSubscription = _allPlayersCollection
        .doc(FirebaseAuth.instance.currentUser!.email)
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;

      if (snapshot.data() != null) {
        final data = snapshot.data()! as Map<String, dynamic>;
        if (data["IsAlive"] == true && data["Character"] == "imposter") {
          _playerRole = "Imposter";
        } else if (data["IsAlive"] == true && data["Character"] == "crewmate") {
          _playerRole = "Crewmate";
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (ctx) => const DeathScreen()),
            (route) => false,
          );
        }
        setState(() {});
      }
    });
  }

  Future<void> _updatePlayerLocation() async {
    if (!mounted || _playerRole != "Imposter") return;

    _currentLocation = await _geolocatorServices.determinePosition();

    if (_isSocketConnected) {
      _sendSocketLocationUpdate();
    } else {
      _sendHttpLocationUpdate();
    }
  }

  void _sendSocketLocationUpdate() {
    try {
      _channel.sink.add(jsonEncode({
        'type': 'locationUpdate',
        'teamName': widget.teamName,
        'latitude': _currentLocation!.latitude,
        'longitude': _currentLocation!.longitude,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      }));
    } catch (e) {
      print('WebSocket location update error: $e');
      _sendHttpLocationUpdate();
    }
  }

  Future<void> _sendHttpLocationUpdate() async {
    try {
      final response = await http.post(
        Uri.parse('https://amongus-backend.onrender.com/api/teams/location'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'teamName': widget.teamName,
          'latitude': _currentLocation!.latitude,
          'longitude': _currentLocation!.longitude,
        }),
      );
      if (response.statusCode != 200) {
        print('Failed to update location: ${response.body}');
      }
    } catch (e) {
      print('HTTP Failed to update location: $e');
    }
  }

  Future<void> _callEmergencyMeeting() async {
    try {
      if (_isSocketConnected) {
        _channel.sink.add(jsonEncode({
          'type': 'emergencyMeeting',
          'teamName': widget.teamName,
          'caller': FirebaseAuth.instance.currentUser!.email,
        }));
      } else {
        final response = await http.post(
          Uri.parse('https://amongus-backend.onrender.com/api/game/emergency'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'teamName': widget.teamName,
            'caller': FirebaseAuth.instance.currentUser!.email,
          }),
        );
        print('Emergency meeting called: ${response.body}');
      }
    } catch (e) {
      print('Error calling emergency meeting: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(255, 249, 219, 1),
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(255, 249, 219, 1),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Card(
                elevation: 0,
                color: const Color.fromRGBO(29, 25, 11, 0.459),
                child: SizedBox(
                  height: 40,
                  child: Row(
                    children: [
                      const SizedBox(width: 8),
                      if (_playerRole.isNotEmpty)
                        Text(
                          _playerRole,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Colors.black),
                        ),
                      if (_playerRole == "Imposter")
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Image(
                            image: AssetImage("assets/imposter.gif"),
                            height: 40,
                          ),
                        )
                      else if (_playerRole == "Crewmate")
                        const Padding(
                          padding: EdgeInsets.all(0.0),
                          child: Image(
                            image: AssetImage("assets/crewmate.gif"),
                            height: 300,
                          ),
                        )
                    ],
                  ),
                )),
          )
        ],
        title: const Card(
          elevation: 0,
          color: Color.fromRGBO(29, 25, 11, 0.459),
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: SizedBox(
              width: 250,
              height: 30,
              child: Text(
                'IRL Among Us',
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 20),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: _playerRole == "Crewmate"
          ? FloatingActionButton(
              onPressed: _callEmergencyMeeting,
              child: const Icon(Icons.emergency),
            )
          : null,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("GameStatus")
            .doc("Status")
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final gameStatus = snapshot.data!.data() as Map<String, dynamic>;
          if (gameStatus["voting"] == false) {
            return SlidingSheet(
              elevation: 8,
              cornerRadius: 16,
              snapSpec: const SnapSpec(
                snap: true,
                snappings: [0.1, 0.7, 1.0],
                positioning: SnapPositioning.relativeToAvailableSpace,
              ),
              body: const MapWidget(),
              builder: (context, state) {
                if (_playerRole == 'Imposter') {
                  return const SizedBox(
                    height: 500,
                    child: Center(
                      child: NearbyPlayersListWidget(),
                    ),
                  );
               } else {
                  return FutureBuilder(
                    future: FirebaseFirestore.instance
                        .collection("Teams")
                        .doc(GlobalteamName)
                        .get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                        return const Center(child: Text('Error loading tasks'));
                      }
                      final teamData = snapshot.data!.data() as Map<String, dynamic>;
                      if (teamData["randomTask"] == 1) {
                        return  SizedBox(
                            height: 500, child: Center(child: TasksScreen1()));
                      } else {
                        return SizedBox(
                            height: 500, child: Center(child: TasksScreen2()));
                      }
                    },
                  );
                }
              },
            );
          } else {
            return PollingScreen(email: GlobalteamName!);
          }
        },
      ),
    );
  }
}