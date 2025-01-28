import 'package:among_us_gdsc/fetures/join_a_team/join_team.dart';
import 'package:among_us_gdsc/fetures/landing/screen/landing_page.dart';
import 'package:among_us_gdsc/services/firebase_services.dart';
import 'package:flutter/material.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  // SystemChrome.setPreferredOrientations([
  //   DeviceOrientation.portraitUp,
  // ]);
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );
  runApp(MaterialApp(
    home: Scaffold(
      body: SignUp(),
    ),
  ));
}

class SignUp extends StatelessWidget {
  SignUp({
    super.key,
  });
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late String _email;
  late String _password;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
            image: DecorationImage(
                image: AssetImage("assets/background 2.png"),
                fit: BoxFit.cover)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 190),
                buildTextFieldWithIcon("Email", Icons.email, (value) {
                  _email = value!;
                }, (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an email';
                  }
                  // Basic email format check
                  if (!value.contains('@') || !value.contains('.')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                }),
                const SizedBox(height: 16.0),
                buildPasswordFieldWithIcon("Password", Icons.lock, (value) {
                  _password = value!;
                }, (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (value.length < 6) {
                    return "Password length can not be less than 6";
                  }
                  return null;
                }),
                const SizedBox(height: 16.0),
                buildPasswordFieldWithIcon(
                    "Confirm Password", Icons.lock, (value) {}, (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password password';
                  }
                  if (value != _password) {
                    return 'Passwords do not match';
                  }
                  return null;
                }),
                const SizedBox(height: 32.0),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(
                          const Color.fromRGBO(17, 24, 40, 1)),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                        const EdgeInsets.all(16.0),
                      ),
                    ),
                    child: const Text(
                      "Sign Up",
                      style: TextStyle(fontSize: 18.0, color: Colors.white),
                    ),
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        // Handle sign up logic here
                        // You can access _email and _password variables here
                        showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) {
                              return const PopScope(
                                canPop: false,
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            });
                        var email = _email.trim();
                        print("email - $email");

                        var res = await FirebaseServices()
                            .createAccount(email, _password.trim(), context);
                        if (res == "Success") {
                          Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const JoinTeamScreen()),
                              (route) => false);
                        } else {
                          Navigator.pop(context);
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account ?'),

                    const SizedBox(
                        width: 5), // Adjust the spacing between texts
                    GestureDetector(
                      onTap: () {
                        // Handle navigation to sign-up page
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (ctx) => LandingPage()),
                        );
                      },
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildTextFieldWithIcon(String labelText, IconData icon,
      Function(String?) onChanged, String? Function(String?)? validator) {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromRGBO(
            45, 54, 81, 1), // Set background color to white
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color.fromARGB(158, 0, 0, 0),
            spreadRadius: 1,
            blurRadius: 2,
            offset: Offset(0, 2), // changes position of shadow
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: [
            const SizedBox(width: 8.0),
            Expanded(
              child: TextFormField(
                style: const TextStyle(
                    color: Colors.white), // Set text color to black
                decoration: InputDecoration(
                  labelText: labelText,
                  labelStyle: const TextStyle(
                      color: Color.fromARGB(255, 188, 210, 228)),
                  border: InputBorder.none,
                ),
                onChanged: onChanged,
                validator: validator,
              ),
            ),
            Icon(icon),
          ],
        ),
      ),
    );
  }

  Widget buildPasswordFieldWithIcon(String labelText, IconData icon,
      Function(String?) onChanged, String? Function(String?)? validator) {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromRGBO(
            45, 54, 81, 1), // Set background color to white
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            spreadRadius: 1,
            blurRadius: 2,
            offset: Offset(0, 2), // changes position of shadow
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: [
            const SizedBox(width: 8.0),
            Expanded(
              child: TextFormField(
                style: const TextStyle(
                    color: Colors.black), // Set text color to black
                decoration: InputDecoration(
                  labelText: labelText,
                  labelStyle: const TextStyle(
                      color: Color.fromARGB(255, 188, 210, 228)),
                  border: InputBorder.none,
                ),
                obscureText: true,
                onChanged: onChanged,
                validator: validator,
              ),
            ),
            Icon(icon),
          ],
        ),
      ),
    );
  }
}
