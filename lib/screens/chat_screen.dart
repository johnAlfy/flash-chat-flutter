import 'dart:collection';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

final Firestore _fireStoreAuth = Firestore.instance;
FirebaseUser _loggedInUser;
final Set<BubblesColors> usersBubblesColors = HashSet();

class BubblesColors {
  final String user;
  final Color color;
  BubblesColors(this.user, this.color);
}

class ChatScreen extends StatefulWidget {
  static String id = "chat_screen";
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final messageTextController = TextEditingController();
  FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;

  String _message = "";

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
                  MessageStream(),
                  Container(
                    decoration: kMessageContainerDecoration,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: messageTextController,
                            onChanged: (value) {
                              setState(() {
                                _message = value.trim();
                              });
                            },
                            decoration: kMessageTextFieldDecoration,
                          ),
                        ),
                        FlatButton(
                          onPressed: _message == ""
                              ? null
                              : () {
                                  messageTextController.clear();
                                  _fireStoreAuth.collection("messages").add({
                                    "text": _message,
                                    "sender": _loggedInUser.email,
                                    "timeStamp": FieldValue.serverTimestamp()
                                  });
                                  setState(() {
                                    _message = "";
                                  });
                                },
                          child: Text(
                            'Send',
                            style: _message == ""
                                ? kSendButtonTextStyle
                                : kSendButtonTextStyle.copyWith(
                                    color: Colors.lightBlueAccent),
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

class MessageStream extends StatelessWidget {
  Color colorGenerator() {
    return Color((Random().nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _fireStoreAuth
          .collection("messages")
          .orderBy("timeStamp", descending: false)
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
                backgroundColor: Colors.lightBlueAccent),
          );
        }
        final messages = snapshot.data.documents.reversed;
        List<MessageBubble> messageWidgets = [];
        for (var message in messages) {
          final messageText = message.data["text"];
          final messageSender = message.data["sender"];

          messageWidgets.add(MessageBubble(messageSender, messageText,
              messageSender == _loggedInUser.email));
        }
        return Expanded(
          child: ListView(
            reverse: true,
            padding: EdgeInsets.symmetric(vertical: 20, horizontal: 10),
            children: messageWidgets,
          ),
        );
      },
    );
  }
}

class MessageBubble extends StatelessWidget {
  final _sender;
  final _text;
  final bool isMe;
  MessageBubble(this._sender, this._text, this.isMe);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            _sender,
            style: kMessageBubbleStyle,
          ),
          Material(
            borderRadius: isMe
                ? BorderRadius.only(
                    bottomRight: Radius.circular(30),
                    bottomLeft: Radius.circular(30),
                    topLeft: Radius.circular(30))
                : BorderRadius.only(
                    topLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
            elevation: 5,
            color: isMe ? Colors.lightBlueAccent : Colors.white,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: Text(
                _text,
                style: isMe
                    ? kMessageBubbleTextStyle
                    : kMessageBubbleTextStyle.copyWith(color: Colors.black45),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
