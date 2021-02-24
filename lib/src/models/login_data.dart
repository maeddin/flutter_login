import 'package:flutter/foundation.dart';
import 'package:quiver/core.dart';

class LoginData {
  final List<String> values;

  LoginData({
    this.values,
  });

  bool operator ==(Object other) {
    if (other is LoginData) {
      return values == other.values;
    }
    return false;
  }

  int get hashCode => values.hashCode;
}