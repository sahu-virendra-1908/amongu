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

class NearbyPlayersListWidget extends StatefulWidget {
  const NearbyPlayersListWidget({Key? key}) : super(key: key);

  @override
  _NearbyPlayersListWidgetState createState() => _NearbyPlayersListWidgetState();
}

class _NearbyPlayersListWidgetState extends State<NearbyPlayersListWidget> {
  bool isCooldownActive = false;
  late DateTime cooldownEndTime;
  bool _isButtonDisabled = true;
  List<Map<String, dynamic>> nearbyTeams = [];
  late WebSocketChannel _channel;
  Position? _currentPosition;
  Timer? _locationUpdateTimer;

  @override
  void initState() {
    super.initState();
    initializeCooldownState();
    _connectToWebSocket();
    _startLocationUpdates();
  }

  void _connectToWebSocket() {
    _channel = WebSocketChannel.connect(
      Uri.parse('wss://amongusbackend-ady5.onrender.com'), // Change to your server URL
    );

    _channel.stream.listen((message) {
      final data = jsonDecode(message);
      if (data['type'] == 'nearbyTeams' && mounted) {
        setState(() {
          nearbyTeams = List<Map<String, dynamic>>.from(data['nearbyTeams'] ?? []);
          print('Received nearby teams: $nearbyTeams');
        });
      }
    }, onError: (error) {
      print('WebSocket error: $error');
      // Add reconnection logic here if needed
    });

    // Send initial join message
    _sendTeamJoin();
  }

  Future<void> _startLocationUpdates() async {
    // Get initial position
    await _getCurrentPosition();
    
    // Set up periodic location updates
    _locationUpdateTimer = Timer.periodic(Duration(seconds: 5), (timer) async {
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
      if (_channel != null && _channel.sink != null) {
        _channel.sink.add(jsonEncode({
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
    if (_channel != null && _channel.sink != null && GlobalteamName != null) {
      _channel.sink.add(jsonEncode({
        'teamName': GlobalteamName,
      }));
      print('Sent team join: $GlobalteamName');
    }
  }

  Future<void> _fetchNearbyTeams() async {
    if (_currentPosition != null) {
      // Trigger a location update which will automatically broadcast nearby teams
      await _getCurrentPosition();
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
    return Consumer(
      builder: (context, ref, child) {
        return Scaffold(
          appBar: AppBar(
            actions: [
              IconButton(
                onPressed: _fetchNearbyTeams,
                icon: const Icon(Icons.refresh),
              )
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.only(top: 15, left: 20, right: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isCooldownActive)
                  CountdownTimer(
                    endTime: cooldownEndTime.millisecondsSinceEpoch,
                    textStyle: const TextStyle(fontSize: 16),
                    onEnd: () async {
                      SharedPreferences prefs = await SharedPreferences.getInstance();
                      await prefs.remove('isCooldownActive');
                      await prefs.remove('cooldownEndTimeMillis');
                      if (mounted) {
                        setState(() => isCooldownActive = false);
                      }
                    },
                  ),
                Expanded(
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
                              return StreamBuilder(
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
                                      return Card(
                                        child: ListTile(
                                          title: Text(playerDoc["name"]),
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
                                            child: const Text('Kill'),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          )
                        else
                          const Center(child: Text("No teams Nearby!")),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
      'Cooldown: ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
      style: widget.textStyle,
    );
  }
}