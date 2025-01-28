import 'package:among_us_gdsc/provider/marker_provider.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

class TasksScreen1 extends ConsumerWidget {
  const TasksScreen1({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    List<Map<String, String>> tasks = [
      {
        'task': 'Scribble',
        'location': '4H',
      },
      {
        'task': 'Code Blocks',
        'location': 'admin block',
      },
      {
        'task': 'Image Puzzle',
        'location': 'Audi',
      },
      {
        'task': 'Minefield',
        'location': 'CB',
      },
      {
        'task': 'Space Wars',
        'location': 'EC departnment',
      },
      {
        'task': 'Breadboard',
        'location': 'juice bar',
      },
      {
        'task': 'Hurdles',
        'location': 'LH',
      },
      {
        'task': 'Hangman',
        'location': 'OAT',
      },
      {
        'task': 'Connect 4',
        'location': 'SAC',
      },
      {
        'task': 'Dumb Charades',
        'location': 'Students Park',
      },
    ];

    return Scaffold(
      backgroundColor: const Color.fromRGBO(255, 249, 219, 1),
      body: Padding(
        padding: const EdgeInsets.only(top: 50),
        child: Column(
          children: [
            const Icon(Icons.swipe_up_rounded),
            Expanded(
              child: SingleChildScrollView(
                child: StreamBuilder(
                  stream: FirebaseDatabase.instance.ref('location').onValue,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (!snapshot.hasData) {
                      return const Center(
                        child: Text("No players nearby."),
                      );
                    }

                    DataSnapshot dataSnapshot = snapshot.data!.snapshot;
                    Map<dynamic, dynamic> locationData =
                        dataSnapshot.value as Map<dynamic, dynamic>;

                    locationData.forEach((key, value) {
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

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: tasks
                          .map((task) => Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8.0, horizontal: 16.0),
                                child: Card(
                                  color: const Color.fromARGB(255, 140, 130,
                                      98), // Background color of the card
                                  elevation: 4, // Card elevation
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          task['location'] ?? '',
                                          style: const TextStyle(
                                            color: Colors
                                                .white, // Text color of the location
                                            fontWeight: FontWeight
                                                .bold, // Font weight of the location
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          task['task'] ?? '',
                                          style: const TextStyle(
                                            color: Colors
                                                .white, // Text color of the task
                                            fontWeight: FontWeight
                                                .normal, // Font weight of the task
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ))
                          .toList(),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
