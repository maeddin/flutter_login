import 'package:flutter/foundation.dart';
import 'package:quiver/core.dart';

class LoginData {
  final List<String> data;

  LoginData(this.data);

  bool operator ==(Object other) {
    if (other is LoginData) {
      return data == other.data;
    }
    return false;
  }

  int get hashCode => data.hashCode;
}