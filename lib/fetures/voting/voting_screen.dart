import 'dart:async';
import 'package:among_us_gdsc/fetures/voting/result_screen.dart';
import 'package:among_us_gdsc/fetures/waiting_area/wating_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  Timer? _chatTimer;
  Timer? _voteTimer;
  bool _isLoading = true;
  bool _isVotingPhase = false;
  String _errorMessage = "";
  int _remainingTime = 90; // 90 seconds for chat phase

  @override
  void initState() {
    super.initState();
    _initWebView();
    _startChatPhase();
  }

  void _initWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
            print('Page started loading: $url');
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            print('Page finished loading: $url');

            // Inject JavaScript to detect page state
            _webViewController.runJavaScript('''
              if (document.body.innerText.includes('404') || 
                  document.body.innerText.includes('not found')) {
                Flutter.postMessage('error:404 page not found');
              } else {
                Flutter.postMessage('loaded:success');
              }
            ''');
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _isLoading = false;
              _errorMessage = "${error.errorCode}: ${error.description}";
            });
            print('WebView error: ${error.errorCode} - ${error.description}');
          },
        ),
      )
      ..addJavaScriptChannel(
        'Flutter',
        onMessageReceived: (JavaScriptMessage message) {
          print('JS message: ${message.message}');
          if (message.message.startsWith('error:')) {
            setState(() {
              _errorMessage = message.message.substring(6);
            });
          }
        },
      );

    _loadPollingPage();
  }

  @override
  void dispose() {
    _chatTimer?.cancel();
    _voteTimer?.cancel();
    super.dispose();
  }

  void _startChatPhase() {
    setState(() {
      _remainingTime = 90;
      _isVotingPhase = false;
    });

    _chatTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTime > 0) {
          _remainingTime--;
        } else {
          _chatTimer?.cancel();
          _startVotingPhase();
        }
      });
    });
  }

  void _startVotingPhase() {
    setState(() {
      _remainingTime = 30;
      _isVotingPhase = true;
    });

    // Inject JavaScript to trigger voting phase in the web app
    _webViewController.runJavaScript('''
      if (typeof startVotingPhase === 'function') {
        startVotingPhase();
      }
    ''');

    _voteTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTime > 0) {
          _remainingTime--;
        } else {
          _voteTimer?.cancel();
          _endVoting();
        }
      });
    });
  }

  void _endVoting() async {
    // Tell web app to submit final votes
    await _webViewController.runJavaScript('''
      if (typeof submitFinalVotes === 'function') {
        submitFinalVotes();
      }
    ''');

    // Navigate to results screen
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (ctx) => const PollingResult()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(255, 249, 219, 1),
        title: Text(
            _isVotingPhase ? 'Emergency Voting' : 'Emergency Discussion',
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPollingPage,
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              if (_errorMessage.isNotEmpty)
                Container(
                  color: Colors.red.withOpacity(0.1),
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Error: $_errorMessage\nURL: https://amongus-poll-eight.vercel.app/?email=${widget.email}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.red),
                        onPressed: _loadPollingPage,
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: WebViewWidget(controller: _webViewController),
              ),
            ],
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _isVotingPhase
                      ? Colors.red.withOpacity(0.7)
                      : Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isVotingPhase ? Icons.how_to_vote : Icons.chat,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isVotingPhase
                          ? 'Vote now! ${_remainingTime}s remaining'
                          : 'Discussion: ${_remainingTime}s remaining',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _loadPollingPage() {
    try {
      final String encodedEmail = Uri.encodeComponent(widget.email);
      final String pollingUrl =
          'https://amongus-poll-eight.vercel.app/?email=$encodedEmail';

      print('Loading polling URL: $pollingUrl');

      _webViewController.loadRequest(Uri.parse(pollingUrl));
    } catch (e) {
      setState(() {
        _errorMessage = "Error loading page: $e";
      });
      print('Error loading polling page: $e');
    }
  }
}
