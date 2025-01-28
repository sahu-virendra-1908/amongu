import 'dart:async';

import 'package:among_us_gdsc/fetures/home/calculations/distance_calculator.dart';
import 'package:among_us_gdsc/main.dart';
import 'package:among_us_gdsc/provider/marker_provider.dart';
import 'package:among_us_gdsc/services/firestore_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NearbyPlayersListWidget extends StatefulWidget {
  const NearbyPlayersListWidget({Key? key}) : super(key: key);

  @override
  _NearbyPlayersListWidgetState createState() =>
      _NearbyPlayersListWidgetState();
}

class _NearbyPlayersListWidgetState extends State<NearbyPlayersListWidget> {
  Position? userLocation;
  bool isCooldownActive = false;
  late DateTime cooldownEndTime;
  bool _isButtonDisabled = true;

  @override
  void initState() {
    super.initState();
    initializeCooldownState();
    getUserLocation();
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

  Future<void> saveCooldownState(bool active, DateTime endTime) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isCooldownActive', active);
    await prefs.setInt('cooldownEndTimeMillis', endTime.millisecondsSinceEpoch);
  }

  void getUserLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      userLocation = position;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dbref = FirebaseDatabase.instance.ref('location');
    return Consumer(
      builder: (context, ref, child) {
        return Scaffold(
          appBar: AppBar(
            actions: [
              IconButton(
                  onPressed: () {
                    setState(() {});
                  },
                  icon: const Icon(Icons.refresh))
            ],
          ),
          backgroundColor: const Color.fromRGBO(255, 249, 219, 1),
          body: Padding(
            padding: const EdgeInsets.only(top: 15, left: 20, right: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isCooldownActive)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: CountdownTimer(
                      endTime: cooldownEndTime.millisecondsSinceEpoch,
                      textStyle: const TextStyle(fontSize: 18),
                      onEnd: () {
                        setState(() {
                          isCooldownActive = false;
                          saveCooldownState(false, DateTime.now());
                        });
                      },
                    ),
                  ),
                Expanded(
                  child: SingleChildScrollView(
                    child: StreamBuilder(
                      stream: dbref.onValue,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        // if (snapshot.hasError) {
                        //   return Center(
                        //     child: Text('Error: ${snapshot.error}'),
                        //   );
                        // }
                        if (!snapshot.hasData ||
                            snapshot.data == null ||
                            (snapshot.data! as DatabaseEvent).snapshot.value ==
                                null) {
                          return const Center(
                            child: Text("No Data Fetched"),
                          );
                        }

                        DataSnapshot dataSnapshot = snapshot.data!.snapshot;
                        Map<dynamic, dynamic> locationData =
                            dataSnapshot.value as Map<dynamic, dynamic>;

                        List<String> nearbyTeams = [];

                        locationData.forEach((key, value) {
                          num destinationLat = value["Lat"];
                          num destinationLong = value["Long"];

                          if (userLocation != null) {
                            if (isWithinRadius(
                              destinationLat,
                              destinationLong,
                              userLocation!.latitude,
                              userLocation!.longitude,
                              10,
                            )) {
                              if (!nearbyTeams.contains(value["Team"])) {
                                if (value["Team"] != GlobalteamName) {
                                  nearbyTeams.add(value["Team"]);
                                }
                              }
                            } else {
                              if (nearbyTeams.contains(value["Team"])) {
                                nearbyTeams.remove(value["Team"]);
                              }
                            }
                          }

                          ref
                              .read(teamMarkersProvider.notifier)
                              .state[value["Team"]] = Marker(
                            point: LatLng(value["Lat"], value["Long"]),
                            builder: (context) {
                              return const Image(
                                height: 1000,
                                width: 1000,
                                image: AssetImage("assets/locationPin.png"),
                              );
                            },
                          );
                        });

                        if (nearbyTeams.isNotEmpty) {
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: nearbyTeams.length,
                            itemBuilder: (context, index) {
                              String team = nearbyTeams[index];
                              return StreamBuilder(
                                stream: FirebaseFirestore.instance
                                    .collection("Teams")
                                    .doc(team)
                                    .collection("players")
                                    .snapshots(),
                                builder: (context, teamSnapshot) {
                                  if (teamSnapshot.hasError) {
                                    return Text(
                                        "Error fetching team data: ${teamSnapshot.error}");
                                  }

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 8),
                                      const Text(
                                        "Nearby Players",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20),
                                      ),
                                      const SizedBox(height: 10),
                                      ListView.builder(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemCount:
                                            teamSnapshot.data!.docs.length,
                                        itemBuilder: (context, playerIndex) {
                                          var playerDoc = teamSnapshot
                                              .data!.docs[playerIndex];
                                          return Card(
                                            elevation: 0,
                                            color: const Color.fromRGBO(
                                                29, 25, 11, 0.459),
                                            child: ListTile(
                                              title: Text(
                                                playerDoc["name"],
                                                style: const TextStyle(
                                                    color: Colors.black,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              subtitle:
                                                  Text(playerDoc["email"]),
                                              trailing: ElevatedButton(
                                                onPressed: () async {
                                                  // Disable the button immediately
                                                  setState(() {
                                                    _isButtonDisabled = true;
                                                  });

                                                  // Perform the Firebase operation in a microtask
                                                  Future.microtask(() async {
                                                    await handleKillPlayer(
                                                        team, playerDoc.id);
                                                    setState(() {
                                                      isCooldownActive = true;
                                                      cooldownEndTime =
                                                          DateTime.now().add(
                                                              const Duration(
                                                                  seconds: 10));
                                                    });
                                                    await saveCooldownState(
                                                        true, cooldownEndTime);
                                                  });
                                                },
                                                style: ButtonStyle(
                                                  shape:
                                                      MaterialStatePropertyAll(
                                                          RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          14))),
                                                  backgroundColor:
                                                      isCooldownActive
                                                          ? MaterialStateProperty
                                                              .all(const Color
                                                                  .fromRGBO(121,
                                                                  85, 72, 1))
                                                          : MaterialStateProperty
                                                              .all(const Color
                                                                  .fromRGBO(75,
                                                                  62, 26, 1)),
                                                ),
                                                child: !isCooldownActive
                                                    ? const Text(
                                                        "Kill",
                                                        style: TextStyle(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      )
                                                    : const Icon(
                                                        Icons.dangerous),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                  );
                                },
                              );
                            },
                          );
                        }
                        print(nearbyTeams);
                        return const Center(
                          child: Text("No teams Nearby !!"),
                        );
                      },
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
          // Imposter wants to delete the entire team
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
          // Non-imposter wants to delete only the player
          await fireStoreInstance
              .collection("Teams")
              .doc(team)
              .collection("players")
              .doc(playerId)
              .delete();

          await FirestoreServices().markPlayerAsDead(playerId);
        }
      } catch (e) {
        print("Error removing : $e");
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
    Timer.periodic(const Duration(seconds: 3), (timer) {
      setState(() {});
    });
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
