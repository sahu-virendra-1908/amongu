// import 'dart:async';

// import 'package:among_us_gdsc/fetures/home/home_screen.dart';
// import 'package:among_us_gdsc/main.dart';
// import 'package:flutter/material.dart';

// void main(List<String> args) {
//   runApp(const MaterialApp(
//     home: BatchAllocationCrewmateScreen(),
//   ));
// }

// class BatchAllocationCrewmateScreen extends StatefulWidget {
//   const BatchAllocationCrewmateScreen({super.key});

//   @override
//   State<BatchAllocationCrewmateScreen> createState() =>
//       _BatchAllocationCrewmateScreenState();
// }

// class _BatchAllocationCrewmateScreenState
//     extends State<BatchAllocationCrewmateScreen> {
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
//               left: 50,
//               top: 210,
//               child: Image.asset(
//                 'assets/crewmate.gif',
//                 height: 170,
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
//                     'You are a Crewmate !!', // Show countdown value
//                     style: TextStyle(
//                       fontSize: 24,
//                       fontWeight: FontWeight.bold,
//                       color: Color.fromRGBO(110, 97, 62, 1),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             Positioned(
//                 left: 60,
//                 right: 30,
//                 bottom: 130,
//                 child: const Text(
//                   "Use your abilities and save yourself and your team's imposter from other teams...",
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
    home: BatchAllocationCrewmateScreen(),
  ));
}

class BatchAllocationCrewmateScreen extends StatefulWidget {
  const BatchAllocationCrewmateScreen({super.key});

  @override
  State<BatchAllocationCrewmateScreen> createState() =>
      _BatchAllocationCrewmateScreenState();
}

class _BatchAllocationCrewmateScreenState
    extends State<BatchAllocationCrewmateScreen> {
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color.fromRGBO(255, 249, 219, 1),
      body: Stack(
        children: [
          Center(
            child: Image.asset(
              "assets/BadgeAllocation (1).png",
              width: screenWidth * 1.2,
              height: screenHeight * 1.2,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            left: screenWidth * 0.1,
            top: screenHeight * 0.27,
            child: Image.asset(
              'assets/crewmate.gif',
              height: screenHeight * 0.2,
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const SizedBox(height: 40),
                Text(
                  '$_countdown',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 22 : 26,
                    fontWeight: FontWeight.bold,
                    color: const Color.fromRGBO(110, 97, 62, 1),
                  ),
                ),
                const SizedBox(height: 35),
                Text('You are a Crewmate !!',
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color.fromRGBO(110, 97, 62, 1),
                        )),
              ],
            ),
          ),
          Positioned(
            left: screenWidth * 0.16,
            right: screenWidth * 0.1,
            bottom: screenHeight * 0.16,
            child: Text(
              "Use your abilities and save yourself and your team's imposter from other teams...",
              style: TextStyle(
                fontSize: screenWidth * 0.053,
                fontWeight: FontWeight.bold,
                color: const Color.fromRGBO(110, 97, 62, 1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
