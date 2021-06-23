import 'dart:async';

import 'package:flutter/material.dart';

import '../models/login_data.dart';

enum AuthMode { Signup, Login }

/// The result is an error message, callback successes if message is null
typedef AuthCallback = FutureOr<String?> Function(LoginData);

/// The result is an error message, callback successes if message is null
typedef RecoverCallback = FutureOr<String?> Function(String);

class Auth with ChangeNotifier {
  Auth({
    this.onLogin,
    this.onSignup,
    this.onRecoverPassword,
    this.values,
  });

  final AuthCallback? onLogin;
  final AuthCallback? onSignup;
  final RecoverCallback? onRecoverPassword;

  AuthMode _mode = AuthMode.Login;
  List<InputData>? values;

  AuthMode get mode => _mode;
  set mode(AuthMode value) {
    _mode = value;
    notifyListeners();
  }

  bool get isLogin => _mode == AuthMode.Login;
  bool get isSignup => _mode == AuthMode.Signup;
  bool isRecover = false;

  AuthMode opposite() {
    return _mode == AuthMode.Login ? AuthMode.Signup : AuthMode.Login;
  }

  AuthMode switchAuth() {
    if (mode == AuthMode.Login) {
      mode = AuthMode.Signup;
    } else if (mode == AuthMode.Signup) {
      mode = AuthMode.Login;
    }
    return mode;
  }

  String _email = '';
  String get email => _email;

  set email(String email) {
    _email = email;
    notifyListeners();
  }
}

class InputData with ChangeNotifier{

  InputData(this._value);

  String _value;

  String get value => _value;
  set value(v) {_value = v; notifyListeners();}
}