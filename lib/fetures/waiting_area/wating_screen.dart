import 'dart:async';

import 'package:among_us_gdsc/core/geolocator_services.dart';
import 'package:among_us_gdsc/fetures/batch_allocation_screen/batch_allocation_imposter.dart';
import 'package:among_us_gdsc/fetures/batch_allocation_screen/batch_alocation_crewmate.dart';
import 'package:among_us_gdsc/main.dart';
import 'package:among_us_gdsc/services/firestore_services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class WaitingScreen extends StatefulWidget {
  const WaitingScreen({super.key});

  @override
  State<WaitingScreen> createState() => _WaitingScreenState();
}

class _WaitingScreenState extends State<WaitingScreen> {
  late GeolocatorServices geoservices;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    geoservices = GeolocatorServices();
    Timer(
      Duration.zero,
      () async {
        location = await geoservices.determinePosition();
        print(location);
      },
    );
    _playAudio();
    super.initState();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playAudio() async {
    var play = await _audioPlayer.play(AssetSource('waiting.mp3'));
    Timer(const Duration(seconds: 0), () async {
      play;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 600;

    var gameStatusInstance = FirebaseFirestore.instance
        .collection("GameStatus")
        .doc("Status")
        .snapshots();
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: StreamBuilder(
        stream: gameStatusInstance,
        builder: (context, snapshot) {
          if (snapshot.data!["status"] == false) {
            return Stack(
              children: [
                Image.asset(
                  "assets/Waiting screen (1).png",
                  height: screenSize.height,
                  width: screenSize.width,
                  fit: BoxFit.cover,
                ),
                // Positioned.fill(
                //   child: FittedBox(
                //     fit: BoxFit.contain,
                //     child: Image.asset(
                //       "assets/Component 6(1).png",
                //     ),
                //   ),
                // ),
                Positioned(
                  left: screenSize.width * 0.35,
                  top: screenSize.height * 0.37,
                  child: Image.asset(
                    'assets/among-us-twerk.gif',
                    height: screenSize.height * 0.1,
                  ),
                ),
                Positioned(
                  left: screenSize.width * 0.19,
                  right: screenSize.width * 0.19,
                  bottom: screenSize.height * 0.37,
                  // child: FittedBox(true

                  child: Text(
                    "Waiting for GDSC to start the game",
                    style: TextStyle(
                      fontSize: screenSize.width * 0.05,
                      fontWeight: FontWeight.bold,
                      color: Color.fromRGBO(110, 97, 62, 1),
                    ),
                    // ),
                  ),
                ),
              ],
            );
          } else {
            FirestoreServices()
                .isPlayerAliveImposter(
                    FirebaseAuth.instance.currentUser!.email!)
                .then((value) {
              if (value) {
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (ctx) => const BatchAllocationScreen()),
                    (route) => false);
              } else {
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (ctx) =>
                            const BatchAllocationCrewmateScreen()),
                    (route) => false);
              }
            });

            return Container();
          }
        },
      ),
    );
  }
}

void setTeamName(String email) async {
  String? teamName = (await FirestoreServices().getTeamNameByEmail(email));

  if (teamName == null) {
    GlobalteamName = "Null";
  } else {
    teamName = teamName;
  }
}
