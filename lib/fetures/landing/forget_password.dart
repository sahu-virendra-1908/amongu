import 'package:among_us_gdsc/fetures/landing/screen/landing_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
      body: ForgotPassWord(),
    ),
  ));
}

class ForgotPassWord extends StatefulWidget {
  const ForgotPassWord({super.key});

  @override
  State<ForgotPassWord> createState() => _ForgotPassWordState();
}

class _ForgotPassWordState extends State<ForgotPassWord> {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  bool isEmailSend = true;
  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
            image: DecorationImage(
                image: AssetImage("assets/background 2.png"),
                fit: BoxFit.cover)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Center(
            child: Form(
              key: formKey,
              child: (isEmailSend)
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: 70),

                        /// Verify Text
                        Text(
                          'Trouble Logging In?',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const Divider(),

                        const SizedBox(height: 20),

                        /// Verify Text
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 7.0),
                          child: Text(
                            'Enter your email and we’ll send you a link to get back into your account.',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),

                        /// Roll Number
                        Container(
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(
                                45, 54, 81, 1), // Set background color to white
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: const Color.fromARGB(158, 0, 0, 0),
                                spreadRadius: 1,
                                blurRadius: 2,
                                offset: const Offset(
                                    0, 2), // changes position of shadow
                              ),
                            ],
                          ),
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Row(
                              children: [
                                const SizedBox(width: 8.0),
                                Expanded(
                                  child: TextFormField(
                                    style: const TextStyle(
                                        color: Colors
                                            .white), // Set text color to black
                                    decoration: const InputDecoration(
                                      labelText: "Email",
                                      labelStyle: TextStyle(
                                          color: Color.fromARGB(
                                              255, 188, 210, 228)),
                                      border: InputBorder.none,
                                    ),
                                    controller: emailController,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter an email';
                                      }
                                      // Basic email format check
                                      if (!value.contains('@') ||
                                          !value.contains('.')) {
                                        return 'Please enter a valid email';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const Icon(Icons.email),
                              ],
                            ),
                          ),
                        ),

                        /// Resent Button
                        ///
                        SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 17.0),
                          child: Center(
                            child: SizedBox(
                              width: size.width,
                              height: size.height * .06,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    // splashFactory: NoSplash.splashFactory,
                                    backgroundColor:
                                        Color.fromRGBO(17, 24, 40, 1),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10.0))),
                                onPressed: () async {
                                  if (formKey.currentState!.validate()) {
                                    final res = await resetPassword();
                                    if (res == "Success") {
                                      setState(() {
                                        isEmailSend = false;
                                      });
                                    }
                                  }
                                },
                                child: Center(
                                  child: SizedBox(
                                    child: FittedBox(
                                      fit: BoxFit.contain,
                                      child: Text("Next",
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineMedium!
                                              .apply(
                                                  color: Colors.white,
                                                  fontFamily: 'NimbusMedium',
                                                  fontSizeFactor: 0.7)),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 100,
                        )
                      ],
                    )
                  : Container(
                      margin: const EdgeInsets.only(top: 300),
                      height: size.height * 0.25,
                      width: size.width * 0.7,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: Colors.black,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Column(
                          children: [
                            const SizedBox(
                              height: 20,
                            ),
                            Text(
                              '''  An email to reset your 
        password has been sent
         to your entered email
                  address ''',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge!
                                  .apply(color: Colors.white),
                            ),
                            const Divider(
                              indent: 20,
                              endIndent: 20,
                              thickness: 2,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.arrow_back,
                                  color: Colors.blue,
                                ),
                                TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pushAndRemoveUntil(
                                          MaterialPageRoute(
                                              builder: (ctx) => LandingPage()),
                                          (route) => false);
                                    },
                                    child: Text("Back to Sign In",
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineMedium!
                                            .apply(
                                                color: Colors.blue,
                                                fontFamily: 'NimbusMedium',
                                                fontSizeFactor: 0.87))),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Future resetPassword() async {
    // showDialog(
    //     context: context,
    //     barrierDismissible: false,
    //     builder: (context) => const Center(
    //           child: CircularProgressIndicator(),
    //         ));
    try {
      var email = emailController.text.trim();
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      // Utils.showSnackBar('Password Reset Email Sent');
      return "Success";
    } on FirebaseAuthException catch (e) {
      print(e);
      // showSnackBar(context, "Oops", e.toString(), ContentType.failure);
      // Utils.showSnackBar(e.message);
      Navigator.of(context).pop();
    }
  }
}
