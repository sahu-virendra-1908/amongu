import 'package:among_us_gdsc/fetures/join_a_team/join_team.dart';
import 'package:among_us_gdsc/fetures/lobby/randomImposterOrCrewmateGen.dart';
import 'package:among_us_gdsc/fetures/waiting_area/wating_screen.dart';
import 'package:among_us_gdsc/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LobbyScreen extends StatelessWidget {
  LobbyScreen({super.key, required this.teamName});
  String teamName;
  int players = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(228, 223, 174, 1),
        actions: [
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(75, 62, 26, 1),
              ),
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection("Teams")
                    .doc(GlobalteamName)
                    .collection("players")
                    .doc(FirebaseAuth.instance.currentUser!.email!)
                    .delete();
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const JoinTeamScreen(),
                    ),
                    (route) => false);
              },
              child: const Text("Leave"))
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        elevation: 0,
        color: const Color.fromARGB(0, 0, 0, 0),
        child: ElevatedButton(
          onPressed: () async {
            if (players == 4) {
              String res = await RandomImpostorOrCrewmateGen(teamName: teamName)
                  .impostorOrCrewmate();

              if (res == "success") {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (ctx) => const WaitingScreen()),
                  (route) => false,
                );
              } else {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(res)));
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text("You need 4 players to join the game ")));
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromRGBO(75, 62, 26, 1),
            padding: const EdgeInsets.symmetric(
              horizontal: 40,
              vertical: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            "Join Game",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      backgroundColor: const Color.fromRGBO(228, 223, 174, 1),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(
              height: 80,
            ),
            Image.asset(
              "assets/group.png",
              height: 210,
            ),
            const SizedBox(
              height: 20,
            ),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: null,
                child: Text("Team Name : $teamName")),
            StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('Teams')
                  .doc(teamName)
                  .collection('players')
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }
                if (snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No players found for this team.'),
                  );
                }

                players = snapshot.data!.docs.length;
                return Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: SizedBox(
                    height: 400,
                    child: ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        DocumentSnapshot player = snapshot.data!.docs[index];
                        return Card(
                          color: const Color.fromARGB(255, 140, 130, 98),
                          child: ListTile(
                            title: Text(
                              player['name'],
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(player['email'],
                                style: const TextStyle(
                                    color: Color.fromARGB(142, 255, 255, 255))),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
