import 'package:among_us_gdsc/fetures/join_a_team/join_team.dart';
import 'package:among_us_gdsc/fetures/landing/forget_password.dart';
import 'package:among_us_gdsc/fetures/signup/screen/signup_page.dart';
import 'package:among_us_gdsc/fetures/waiting_area/wating_screen.dart';
import 'package:among_us_gdsc/main.dart';
import 'package:among_us_gdsc/services/firebase_services.dart';
import 'package:among_us_gdsc/services/firestore_services.dart';
import 'package:flutter/material.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();

  final _passwordController = TextEditingController();

  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
            image: DecorationImage(
                image: AssetImage("assets/landingImage.png"),
                fit: BoxFit.cover)),
        child: Form(
          key: _formKey,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: _emailController,
                    labelText: 'Email',
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: _passwordController,
                    labelText: 'Password',
                    isPassword: true,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 54,
                    width: double.infinity,
                    child: (loading)
                        ? const Center(
                            child: CircularProgressIndicator(),
                          )
                        : ElevatedButton(
                            onPressed: () async {
                              // Handle login logic here
                              if (_formKey.currentState!.validate()) {
                                setState(() {
                                  loading = true;
                                });

                                // showDialog(
                                //     context: context,
                                //     barrierDismissible: false,
                                //     builder: (context) {
                                //       return const PopScope(
                                //         canPop: false,
                                //         child: Center(
                                //           child: CircularProgressIndicator(),
                                //         ),
                                //       );
                                // });

                                var res = await FirebaseServices().LogIn(
                                    _emailController.text.trim(),
                                    _passwordController.text.trim(),
                                    context);
                                if (res == "Success") {
                                  bool isPlayerRegestered =
                                      await FirestoreServices()
                                          .isPlayerRegistered(
                                              _emailController.text);

                                  if (isPlayerRegestered) {
                                    String temaName = (await FirestoreServices()
                                        .getTeamNameByEmail(
                                            _emailController.text))!;
                                    GlobalteamName = temaName;
                                    setState(() {
                                      loading = false;
                                    });
                                    Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const WaitingScreen(),
                                        ),
                                        (route) => false);
                                    print("going to waitinfg scren");
                                  } else {
                                    setState(() {
                                      loading = false;
                                    });
                                    Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const JoinTeamScreen(),
                                        ),
                                        (route) => false);
                                    print("going to join team scrteen");
                                  } // todo
                                }
                              }
                            },
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all<Color>(
                                const Color.fromRGBO(17, 24, 40, 1),
                              ),
                              shape: MaterialStateProperty.all<
                                  RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      10), // Adjust the radius as needed
                                ),
                              ),
                            ),
                            child: const Text(
                              'Log in',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      TextButton(
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (ctx) => const ForgotPassWord()));
                          },
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(color: Colors.blue),
                          ))
                    ],
                  ),
                  const SizedBox(height: 20),
                  // const Text('Do not have a account ?'),
                  // SizedBox(width: 5), // Adjust the spacing between texts
                  // GestureDetector(
                  //   onTap: () {
                  //     // Handle navigation to sign-up page
                  //     Navigator.push(
                  //       context,
                  //       MaterialPageRoute(builder: (ctx) => SignUp()),
                  //     );
                  //   },
                  //   child: Text(
                  //     'Sign Up',
                  //     style: TextStyle(
                  //       color: Colors.blue,
                  //       fontWeight: FontWeight.bold,
                  //     ),
                  //   ),
                  // ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Do not have an account?'),
                      GestureDetector(
                        onTap: () {
                          // Handle navigation to sign-up page
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (ctx) => SignUp()),
                          );
                        },
                        child: const Text(
                          ' Sign Up',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  const Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: Image(image: AssetImage("assets/gdsc2.png")),
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    bool isPassword = false,
  }) {
    return Card(
      elevation: 4, // Adjust elevation as needed
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: labelText,
          hintStyle: const TextStyle(color: Color.fromARGB(255, 188, 210, 228)),
          filled: true,
          fillColor: const Color.fromRGBO(45, 54, 81, 1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
        obscureText: isPassword,
        style: const TextStyle(
          color: Colors.white,
        ),
      ),
    );
  }
}
