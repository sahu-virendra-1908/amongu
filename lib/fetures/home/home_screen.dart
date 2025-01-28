import 'dart:async';

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
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sliding_sheet2/sliding_sheet2.dart';

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

  late final GeolocatorServices _geolocatorServices;
  late final StreamSubscription<DocumentSnapshot> _playerDataSubscription;
  Position? _currentLocation;
  String _playerRole = '';

  @override
  void initState() {
    super.initState();
    _geolocatorServices = GeolocatorServices();
    _subscribeToPlayerData();

    // Initialize the timer in initState
    _locationUpdateTimer =
        Timer.periodic(const Duration(milliseconds: 50), (timer) {
      _updatePlayerLocation();
    });
  }

  @override
  void dispose() {
    // Cancel the timer and subscription in dispose method
    _locationUpdateTimer.cancel();
    _playerDataSubscription.cancel();
    super.dispose();
  }

  void _subscribeToPlayerData() {
    _playerDataSubscription = _allPlayersCollection
        .doc(FirebaseAuth.instance.currentUser!.email)
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return; // Check if the widget is still mounted

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
        setState(() {}); // Update the UI with the player's role
      }
    });
  }

  void _updatePlayerLocation() async {
    if (!mounted) return; // Check if the widget is still mounted

    DatabaseReference databaseRef =
        FirebaseDatabase.instance.ref('location/${widget.teamName}');

    _currentLocation = await _geolocatorServices.determinePosition();

    // Update the location for both Imposter and Crewmate players if they are alive
    if (_playerRole == "Imposter") {
      await databaseRef.set({
        'Lat': _currentLocation!.latitude,
        'Long': _currentLocation!.longitude,
        'Team': widget.teamName,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var gameStatusInstance = FirebaseFirestore.instance
        .collection("GameStatus")
        .doc("Status")
        .snapshots();

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
                      const SizedBox(
                        width: 8,
                      ),
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
      body: StreamBuilder(
        stream: gameStatusInstance,
        builder: (context, snapshot) {
          if (snapshot.data!["voting"] == false) {
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
                      if (snapshot.data!["randomTask"] == "1") {
                        return const SizedBox(
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
