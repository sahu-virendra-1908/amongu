import 'dart:async';

import 'package:among_us_gdsc/fetures/voting/result_screen.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PollingScreen extends StatefulWidget {
  final String email;
  const PollingScreen({Key? key, required this.email}) : super(key: key);

  @override
  _PollingScreenState createState() => _PollingScreenState();
}

class _PollingScreenState extends State<PollingScreen> {
  late WebViewController _webViewController;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _webViewController = WebViewController();
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer(const Duration(seconds: 120), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (ctx) => const PollingResult()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WebViewWidget(controller: _webViewController),
      ],
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadPollingPage();
  }

  void _loadPollingPage() {
    final pollingUrl =
        'https://amongus-poll-1ztb-tau.vercel.app/polls/${widget.email}';
    _webViewController.loadRequest(Uri.parse(pollingUrl));
  }
}
