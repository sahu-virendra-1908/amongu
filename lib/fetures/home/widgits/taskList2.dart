import 'package:among_us_gdsc/provider/marker_provider.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

class TasksScreen2 extends ConsumerWidget {
  List<Map<String, dynamic>> tasks = [
    {
      'task': 'Icebreakers',
      'location': '4h',
    },
    {
      'task': 'Brick Crossing',
      'location': 'admin block',
    },
    {
      'task': 'PNC Password Guess',
      'location': 'Audi',
    },
    {
      'task': 'Angry Birds OpenCV',
      'location': 'cb',
    },
    {
      'task': 'Flappy Bird',
      'location': 'Ec',
    },
    {
      'task': 'Hill Climb',
      'location': 'juice bar',
    },
    {
      'task': 'Ball Game',
      'location': 'LH',
    },
    {
      'task': 'Tower of Hanoi',
      'location': 'OAT',
    },
    {
      'task': 'Ball and Brick',
      'location': 'Sac',
    },
    {
      'task': 'Flying Pen',
      'location': 'sp doc',
    },
  ];

  TasksScreen2({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(255, 249, 219, 1),
      body: Padding(
        padding: const EdgeInsets.only(top: 50),
        child: SingleChildScrollView(
          child: StreamBuilder(
            stream: FirebaseDatabase.instance.ref('location').onValue,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              DataSnapshot dataSnapshot = snapshot.data!.snapshot;
              Map<dynamic, dynamic> locationData =
                  dataSnapshot.value as Map<dynamic, dynamic>;

              locationData.forEach((key, value) {
                ref.read(teamMarkersProvider.notifier).state[value["Team"]] =
                    Marker(
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
                                crossAxisAlignment: CrossAxisAlignment.start,
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
    );
  }
}
