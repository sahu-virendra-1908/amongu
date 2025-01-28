import 'dart:math' as maths;

import 'package:cloud_firestore/cloud_firestore.dart';

class RandomImpostorOrCrewmateGen {
  String teamName;
  RandomImpostorOrCrewmateGen({required this.teamName});
  var players = FirebaseFirestore.instance.collection('AllPlayers');

  //   Future<void> addPlayersData(String name, String character, String teamName, String email) {
  //   return players.add({
  //     "Name": name,
  //     "Email": email,
  //     "Character" : character,
  //     "TeamName" : teamName
  //   });
  // }

  Future<String> impostorOrCrewmate() async {
    int randomNum = maths.Random().nextInt(4) + 1;

    try {
      var playerInTeam = await FirebaseFirestore.instance
          .collection('Teams')
          .doc(teamName)
          .collection('players')
          .get();

      for (int i = 1; i <= 4; i++) {
        String character = randomNum == i ? "imposter" : "crewmate";
        players.doc(playerInTeam.docs[i - 1]["email"]).set({
          "Name": playerInTeam.docs[i - 1]["name"],
          "Email": playerInTeam.docs[i - 1]["email"],
          "Character": character,
          "TeamName": teamName,
          "IsAlive": true,
          "votes": 0
        });
      }

      return "success";
    } catch (e) {
      return "Error in Joining game : $e";
    }
  }
}
