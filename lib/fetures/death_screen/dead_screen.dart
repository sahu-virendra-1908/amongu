import 'dart:async';

import 'package:among_us_gdsc/main.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class DeathScreen extends StatefulWidget {
  const DeathScreen({super.key});

  @override
  State<DeathScreen> createState() => _DeathScreenState();
}

class _DeathScreenState extends State<DeathScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    if (GlobalteamName != null) {
      FirebaseDatabase.instance.ref('location/$GlobalteamName').remove();
    }
    _playAudio();
    super.initState();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playAudio() async {
    await _audioPlayer.play(AssetSource('gettingKilled.mp3'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned(
            left: -25,
            top: 120,
            child: Image.asset(
              "assets/dead screen bg.png",
              height: 640,
              fit: BoxFit.fitWidth,
            ),
          ),
          Center(
            child: Image.asset(
              "assets/dead.gif",
              height: 200,
            ),
          ),
        ],
      ),
    );
  }
}
