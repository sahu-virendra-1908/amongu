import 'package:among_us_gdsc/fetures/death_screen/dead_screen.dart';
import 'package:among_us_gdsc/fetures/join_a_team/join_team.dart';
import 'package:among_us_gdsc/fetures/landing/screen/landing_page.dart';
import 'package:among_us_gdsc/fetures/waiting_area/wating_screen.dart';
import 'package:among_us_gdsc/firebase_options.dart';
import 'package:among_us_gdsc/services/firestore_services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

var globalMessengerKey = GlobalKey<ScaffoldMessengerState>();
String? GlobalteamName;
Position? location = Position(
    longitude: 0.00,
    latitude: 0.00,
    timestamp: DateTime.now(),
    accuracy: 0.00,
    altitude: 0.00,
    altitudeAccuracy: 0.00,
    heading: 0.00,
    headingAccuracy: 0.00,
    speed: 0.00,
    speedAccuracy: 0.00);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, AsyncSnapshot<User?> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          } else if (snapshot.hasError) {
            return const Scaffold(
              body: Center(
                child: Text("Something went wrong!"),
              ),
            );
          } else {
            User? user = snapshot.data;
            bool isAuthenticated = user != null;

            if (!isAuthenticated) {
              return LandingPage();
            } else {
              return FutureBuilder<bool>(
                future: FirestoreServices().isPlayerRegistered(user.email!),
                builder: (context, AsyncSnapshot<bool> registrationSnapshot) {
                  if (registrationSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  } else if (registrationSnapshot.hasError) {
                    return const Scaffold(
                      body: Center(
                        child: Text("Error checking player registration"),
                      ),
                    );
                  } else {
                    bool isRegistered = registrationSnapshot.data!;

                    if (isRegistered) {
                      print("is regestered is true ");
                      return FutureBuilder<bool>(
                        future: FirestoreServices().isPlayerAlive(user.email!),
                        builder: (context, AsyncSnapshot<bool> aliveSnapshot) {
                          if (aliveSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Scaffold(
                              body: Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          } else if (aliveSnapshot.hasError) {
                            return const Scaffold(
                              body: Center(
                                child: Text("Error checking player status"),
                              ),
                            );
                          } else {
                            bool isAlive = aliveSnapshot.data ?? false;

                            if (isAlive) {
                              addingUser(user.email!);
                              return const WaitingScreen();
                            } else {
                              // Navigate to DeadScreen if player is dead
                              return const DeathScreen();
                            }
                          }
                        },
                      );
                    } else {
                      print("is regestered is false");
                      // Navigate to JoinTeamScreen if player is not registered
                      return const JoinTeamScreen();
                    }
                  }
                },
              );
            }
          }
        },
      ),
    );
  }
}

void addingUser(String email) async {
  GlobalteamName = await FirestoreServices().playerTeam(email);
}
