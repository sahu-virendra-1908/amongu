import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FirestoreServices {
  var teams = FirebaseFirestore.instance.collection('Teams');
  var allplayers = FirebaseFirestore.instance.collection("AllPlayers");

  Future<num> getTaskValue(String teamName) async {
    DocumentSnapshot snapshot = await teams.doc(teamName).get();

    if (snapshot.exists) {
      final data = snapshot.data() as Map<String, dynamic>;
      final fieldValue = data['Task'];
      print("task 1");
      return fieldValue;
    } else {
      print("task 2");
      return 0;
    }
  }

  Future<String> removePlayerFromTeam(
      String teamName, String playerEmail) async {
    try {
      // Get the reference to the team document in Firestore

      // Check if the team exists
      var teamSnapshot = teams.doc(teamName).collection("players");

      teamSnapshot.doc(playerEmail).delete();

      return "success";
    } catch (e) {
      print("Error removing player from team: $e");
      return "An error occurred"; // Return error message
    }
  }

  // Future<void> addUsersData(String name, String age, String gender,
  //     String contactNo, String address, String email) {
  //   return users.add({
  //     "Name": name,
  //     "Age": age,
  //     "Gender": gender,
  //     "ContactNo": contactNo,
  //     "Address": address,
  //     "Email": email,
  //     "timestamp": Timestamp.now(),
  //   });
  // }

  // Future<String> addPlayerToGame(
  //     String name, String email, String teamName, String character) async {
  //   try {
  //     allplayers.add({
  //       "Name": name,
  //       "Email": email,
  //       "Character": character,
  //       "TeamName": teamName,
  //       "isAlive": true
  //     });

  //     return "success";

  //   } catch (e) {
  //     return "Can't join : $e";
  //   }
  // }

  Future<String?> getTeamNameByEmail(String email) async {
    try {
      // Query Firestore to find the player document by email
      var querySnapshot = await FirebaseFirestore.instance
          .collection('AllPlayers') // Assuming 'Players' is the collection name
          .doc(email) // Assuming email is the document ID
          .get();

      // Check if a player document with the provided email exists
      if (querySnapshot.exists) {
        // Extract the 'TeamName' field from the player document
        var playerData = querySnapshot.data() as Map<String, dynamic>;
        String teamName = playerData['TeamName'];
        return teamName;
      } else {
        // No player found with the provided email
        return null; // Return null to indicate no team name found
      }
    } catch (e) {
      // Error occurred while fetching player by email
      print('Error fetching player by email: $e');
      return null; // Return null on error
    }
  }

  Future<String?> getFirstAlivePlayerEmailByTeam(String teamName) async {
    try {
      // Query Firestore to get the first alive player of a specific team
      var querySnapshot = await FirebaseFirestore.instance
          .collection('AllPlayers') // Assuming 'Players' is the collection name
          .where('IsAlive', isEqualTo: true)
          .where('TeamName', isEqualTo: teamName)
          .limit(1) // Limit the query to retrieve only the first result
          .get();

      // Check if any player document was found
      if (querySnapshot.docs.isNotEmpty) {
        // Get the first document and extract the email (assuming email is the document ID)
        var playerDoc = querySnapshot.docs.first;
        String playerEmail = playerDoc.id; // Assuming email is the document ID
        return playerEmail;
      } else {
        // No alive player found for the specified team
        return null; // Return null to indicate no player found
      }
    } catch (e) {
      // Error occurred while fetching alive player by team
      print('Error fetching first alive player by team: $e');
      return null; // Return null on error
    }
  }

  Future<bool> isPlayerAlive(String email) async {
    try {
      // Query Firestore to get player's document based on email
      var playerDoc = await allplayers.doc(email).get();

      // Check if the document exists and retrieve the 'isAlive' field
      if (playerDoc.exists) {
        bool isAlive = playerDoc.data()?['IsAlive'];
        return isAlive;
      } else {
        // Player document not found, assume player is dead
        return false;
      }
    } catch (e) {
      // Error occurred while fetching player status
      print('Error checking player status: $e');
      return false; // Assume player is dead on error
    }
  }

  Future<void> markPlayerAsDead(String email) async {
    try {
      // Reference the player document in Firestore
      var playerRef = allplayers.doc(email);

      // Update the 'isAlive' field to false
      await playerRef.update({'IsAlive': false});

      print('Player marked as dead: $email');
    } catch (e) {
      // Error occurred while updating player status
      print('error marking player as dead : $e');
    }
  }

  //   Future<String> playerTeam(String email) async {
  //   try {
  //     // Query Firestore to get player's document based on email
  //     var playerDoc = await allplayers.doc(email).get();

  //     // Check if the document exists and retrieve the 'isAlive' field
  //       String team = playerDoc.data()?['TeamName'];
  //       return team;

  //   } catch (e) {
  //     // Error occurred while fetching player status
  //     print('Error checking player status: $e');
  //     return false; // Assume player is dead on error
  //   }
  // }

  Future<bool> isPlayerAliveImposter(String email) async {
    try {
      // Query Firestore to get player's document based on email
      var playerDoc = await allplayers.doc(email).get();

      // Check if the document exists and retrieve the 'isAlive' field
      if (playerDoc.exists) {
        bool isImposter =
            playerDoc.data()!['Character'] == "imposter" ? true : false;
        return isImposter;
      } else {
        // Player document not found, assume player is dead
        return false;
      }
    } catch (e) {
      // Error occurred while fetching player status
      print('Error checking player status: $e');
      return false; // Assume player is dead on error
    }
  }

  Future<String> addPlayerToTeam(
      String teamId, String name, String email) async {
    try {
      var players = await teams.doc(teamId).collection('players').get();
      int noOfPlayers = players.size;

      if (noOfPlayers < 4) {
        // Get reference to Firestore collection "teams"

        // Get reference to the specific team document
        DocumentReference teamDocRef = teams.doc(teamId);

        // Add the player to the "players" subcollection of the team

        await teamDocRef.collection('players').doc(email).set({
          'name': name,
          'email': email,
        });

        final random = Random();
        int randomNumber = (random.nextInt(2) + 1);

        await teamDocRef.set({
          "TeamName": teamId,
          "isAlive": true,
          "score": 0,
          "tasks": [],
          "randomTask": randomNumber
        });

        return "success";
      } else {
        var teamPlayerRef =
            await teams.doc(teamId).collection('players').doc(email).get();
        print("email $email");
        if (teamPlayerRef.exists) {
          print("andar aa agaya .........");
          DocumentReference teamDocRef = teams.doc(teamId);

          // Add the player to the "players" subcollection of the team

          await teamDocRef.collection('players').doc(email).set({
            'name': name,
            'email': email,
          });

          return "success";
        } else {
          return "This lobby alredy have 4 Players  ";
        }
      }
    } catch (e) {
      print('Error adding player to team: $e');
      // Handle error accordingly
      return "Error try again : $e";
    }
  }

  Future<Widget> GetListNearby(String TeamName) async {
    var playersInstance = await teams.doc(TeamName).collection("players").get();

    List<Widget> teamPlayerList = [];

    for (var i = 0; i < playersInstance.size; i++) {
      teamPlayerList.add(ListTile(
        title: playersInstance.docs[0]["name"],
        subtitle: playersInstance.docs[0]["email"],
        trailing: ElevatedButton(onPressed: () {}, child: const Text("Kill")),
      ));
    }

    return Expanded(
        child: Column(
      children: teamPlayerList,
    ));
  }

  // Future<Map<String, dynamic>?> teamNameMatch(String teamName) async {
  //   QuerySnapshot<Map<String, dynamic>> querySnapshot =
  //       await allplayers.where('TeamName', isEqualTo: teamName).get();
  //    var wd =  querySnapshot.docs;
  //   if (querySnapshot.docs.isNotEmpty) {
  //     return querySnapshot.docs.data();
  //   } else {
  //     return null;
  //   }
  // }

  Future<bool> isPlayerRegistered(String userEmail) async {
    try {
      // Query the Firestore collection 'AllPlayers' based on the user's email
      var playerQuery = await FirebaseFirestore.instance
          .collection('AllPlayers')
          .where('Email', isEqualTo: userEmail)
          .get();

      if (playerQuery.docs[0]['Email'] == userEmail) {
        print("Player alredy exists");

        return true;
      } else {
        print("player do no exist");
        return false;
      }
    } catch (e) {
      print('Error checking player registration: $e');
      return false;
    }
  }

  Future<String> playerTeam(String userEmail) async {
    try {
      // Query the Firestore collection 'AllPlayers' based on the user's email
      var playerQuery = await FirebaseFirestore.instance
          .collection('AllPlayers')
          .doc(userEmail)
          .get();

      // Check if any document exists with the given user's email
      return playerQuery["TeamName"];
    } catch (e) {
      print('Error checking player registration: $e');
      return "NO";
    }
  }
}
