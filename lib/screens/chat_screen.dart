import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatScreen extends StatefulWidget {
  static String id = "chat_screen";
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseUser _loggedInUser;
  bool _isLoading = false;
  String _message;
  Firestore _firestoreAuth = Firestore.instance;

  void getMessages() async {
    await for (var snapShot
        in _firestoreAuth.collection("messages").snapshots()) {
      for (var message in snapShot.documents) {
        print(message.data);
      }
    }
  }

  void getCurrentUser() async {
    try {
      final user = await _auth.currentUser();
      if (user != null) {
        _loggedInUser = user;
      }
      if (user == null) {
        Navigator.pop(context);
      }
    } catch (e) {
      showToast(e.toString());
    }
  }

  @override
  void initState() {
    getCurrentUser();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? SpinKitDoubleBounce(
            color: Colors.lightBlue,
            size: 100,
          )
        : Scaffold(
            appBar: AppBar(
              leading: null,
              actions: <Widget>[
                IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () async {
                      setState(() {
                        _isLoading = true;
                      });
                      try {
                        _auth.signOut();
                        if (await _auth.currentUser() == null) {
                          Navigator.pop(context);
                        }
                      } catch (e) {
                        showToast(e.toString().split(",")[1]);
                      }
                      setState(() {
                        _isLoading = false;
                      });
                    }),
              ],
              title: Text('⚡️Chat'),
              backgroundColor: Colors.lightBlueAccent,
            ),
            body: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Container(
                    decoration: kMessageContainerDecoration,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            onChanged: (value) {
                              _message = value;
                            },
                            decoration: kMessageTextFieldDecoration,
                          ),
                        ),
                        FlatButton(
                          onPressed: () {
                            _firestoreAuth.collection("messages").add({
                              "text": _message,
                              "sender": _loggedInUser.email
                            });
                          },
                          child: Text(
                            'Send',
                            style: kSendButtonTextStyle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
  }
}
