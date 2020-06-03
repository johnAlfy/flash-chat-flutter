import 'dart:io';

import 'package:flash_chat/components/rounded_bbutton.dart';
import 'package:flash_chat/constants.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:email_validator/email_validator.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'chat_screen.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class RegistrationScreen extends StatefulWidget {
  static String id = "registration_screen";
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen>
    with SingleTickerProviderStateMixin {
  String _email;
  String _password;
  final _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  bool emailAndPasswordValidation(String _email, String _password) {
    if ((_email == null) | (_password == null)) {
      showToast("Please fill all fields ! ");
      return false;
    }
    final bool emailIsValid = EmailValidator.validate(_email);
    final bool passwordIsValid = _password.length >= 6 ? true : false;
    if (emailIsValid & passwordIsValid) {
      return true;
    } else if (!emailIsValid) {
      showToast("Invalid email !");
      return false;
    } else if (!passwordIsValid) {
      showToast("password must be 6 or more characters !");
      return false;
    } else {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              flex: 5,
              child: Hero(
                tag: "Logo",
                child: Container(
                  height: 200.0,
                  child: Image.asset('images/logo.png'),
                ),
              ),
            ),
            SizedBox(
              height: 48.0,
            ),
            TextField(
              keyboardType: TextInputType.emailAddress,
              textAlign: TextAlign.center,
              onChanged: (value) {
                _email = value;
              },
              decoration:
                  kTextFieldDecoration.copyWith(hintText: 'Enter your email.'),
            ),
            SizedBox(
              height: 8.0,
            ),
            TextField(
              minLines: 1,
              textAlign: TextAlign.center,
              obscureText: true,
              onChanged: (value) {
                _password = value;
              },
              decoration: kTextFieldDecoration.copyWith(
                  hintText: 'Enter your password.'),
            ),
            SizedBox(
              height: 24.0,
            ),
            Visibility(
              visible: !_isLoading ? true : false,
              child: RoundedButton(
                text: 'Register',
                color: Colors.blueAccent,
                onPressed: () async {
                  _email = _email.trim();
                  if (emailAndPasswordValidation(_email, _password)) {
                    try {
                      setState(() {
                        _isLoading = true;
                      });
                      final newUser =
                          await _auth.createUserWithEmailAndPassword(
                              email: _email, password: _password);
                      if (newUser != null) {
                        Navigator.pushNamed(context, ChatScreen.id);
                      }
                    } catch (e) {
                      showToast(e.toString().split(",")[1]);
                    }
                    setState(() {
                      _isLoading = false;
                    });
                  }
                },
              ),
            ),
            Expanded(
              child: _isLoading
                  ? SpinKitDoubleBounce(
                      color: Colors.lightBlue,
                      size: 100,
                    )
                  : Column(),
            ),
          ],
        ),
      ),
    );
  }
}
