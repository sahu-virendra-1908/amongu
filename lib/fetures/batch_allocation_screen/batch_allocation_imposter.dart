// import 'dart:async';

// import 'package:among_us_gdsc/fetures/home/home_screen.dart';
// import 'package:among_us_gdsc/main.dart';
// import 'package:flutter/material.dart';

// void main(List<String> args) {
//   runApp(const MaterialApp(
//     home: BatchAllocationScreen(),
//   ));
// }

// class BatchAllocationScreen extends StatefulWidget {
//   const BatchAllocationScreen({Key? key}) : super(key: key);

//   @override
//   _BatchAllocationScreenState createState() => _BatchAllocationScreenState();
// }

// class _BatchAllocationScreenState extends State<BatchAllocationScreen> {
//   int _countdown = 10;
//   late Timer _timer;

//   @override
//   void initState() {
//     super.initState();

//     _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       setState(() {
//         if (_countdown > 0) {
//           _countdown--;
//         } else {
//           _timer.cancel();
//           // Navigate to HomeScreen after countdown
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(
//               builder: (ctx) => HomeScreen(
//                 teamName: GlobalteamName,
//               ),
//             ),
//           );
//         }
//       });
//     });
//   }

//   @override
//   void dispose() {
//     _timer.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         backgroundColor: const Color.fromRGBO(255, 249, 219, 1),
//         body: Stack(
//           children: [
//             Center(
//               // Adjust the values below to position "Component 6.png" as desired
//               // Change this value to position vertically
//               child: Image.asset(
//                 "assets/BadgeAllocation (1).png",
//                 height: 1000, // Adjust the height as needed
//                 fit: BoxFit.cover,
//               ),
//             ),
//             Positioned(
//               left: 150,
//               top: 255,
//               child: Image.asset(
//                 'assets/imposter.gif',
//                 height: 90,
//               ),
//             ),
//             Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: <Widget>[
//                   // const CircularProgressIndicator(), // Display circular progress indicator
//                   const SizedBox(height: 20),
//                   Text(
//                     '$_countdown', // Show countdown value
//                     style: const TextStyle(
//                       fontSize: 24,
//                       fontWeight: FontWeight.bold,
//                       color: Color.fromRGBO(110, 97, 62, 1),
//                     ),
//                   ),
//                   const Text(
//                     'You are an Imposter !!', // Show countdown value
//                     style: TextStyle(
//                       fontSize: 24,
//                       fontWeight: FontWeight.bold,
//                       color: Color.fromRGBO(110, 97, 62, 1),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             const Positioned(
//                 left: 60,
//                 right: 30,
//                 bottom: 130,
//                 child: Text(
//                   "Use your abilities and save yourself and your team from other teams...",
//                   style: TextStyle(
//                     fontSize: 24,
//                     fontWeight: FontWeight.bold,
//                     color: Color.fromRGBO(110, 97, 62, 1),
//                   ),
//                 )),
//           ],
//         ));
//   }
// }

import 'dart:async';
import 'package:among_us_gdsc/fetures/home/home_screen.dart';
import 'package:among_us_gdsc/main.dart';
import 'package:flutter/material.dart';

void main(List<String> args) {
  runApp(const MaterialApp(
    home: BatchAllocationScreen(),
  ));
}

class BatchAllocationScreen extends StatefulWidget {
  const BatchAllocationScreen({Key? key}) : super(key: key);

  @override
  _BatchAllocationScreenState createState() => _BatchAllocationScreenState();
}

class _BatchAllocationScreenState extends State<BatchAllocationScreen> {
  int _countdown = 10;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_countdown > 0) {
          _countdown--;
        } else {
          _timer.cancel();
          // Navigate to HomeScreen after countdown
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (ctx) => HomeScreen(
                teamName: GlobalteamName!,
              ),
            ),
          );
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
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color.fromRGBO(255, 249, 219, 1),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final screenHeight = constraints.maxHeight;
            final isPortrait = screenHeight > screenWidth;

            return Stack(
              children: [
                Center(
                  child: Image.asset(
                    "assets/BadgeAllocation (1).png",
                    width: screenWidth * 1.3,
                    height: screenHeight * 1.3,
                    fit: BoxFit.contain,
                  ),
                ),
                Positioned(
                  left: screenWidth * 0.38,
                  top: screenHeight * 0.34,
                  child: Image.asset(
                    'assets/imposter.gif',
                    height: screenHeight * 0.1,
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const SizedBox(height: 60),
                      Text(
                        '$_countdown',
                        style: TextStyle(
                          fontSize: screenWidth * 0.06,
                          fontWeight: FontWeight.bold,
                          color: const Color.fromRGBO(110, 97, 62, 1),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Text('You are an Imposter !!',
                          style:
                              Theme.of(context).textTheme.titleLarge!.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: const Color.fromRGBO(110, 97, 62, 1),
                                  )),
                    ],
                  ),
                ),
                Positioned(
                  left: screenWidth * 0.06,
                  right: screenWidth * 0.03,
                  bottom: screenHeight * 0.16,
                  child: Text(
                    "Use your abilities and save yourself and your team from other teams...",
                    style: TextStyle(
                      fontSize: screenWidth * 0.054,
                      fontWeight: FontWeight.bold,
                      color: const Color.fromRGBO(110, 97, 62, 1),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
