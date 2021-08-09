import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ui/src/auth/auth_controller.dart';
import 'package:flutter/foundation.dart';

abstract class AuthState {}

class CredentialReceived extends AuthState {
  final AuthCredential credential;

  CredentialReceived(this.credential);
}

class CredentialLinked extends AuthState {}

class AuthFailed extends AuthState {
  final Exception exception;

  AuthFailed(this.exception);
}

class SignedIn extends AuthState {
  final User user;

  SignedIn(this.user);
}

abstract class AuthFlow extends ValueNotifier<AuthState>
    implements AuthController {
  @override
  final FirebaseAuth auth;

  @override
  AuthMethod method;

  AuthFlow({
    required this.auth,
    required AuthState initialState,
    required this.method,
  }) : super(initialState);

  void setCredential(AuthCredential credential) {
    onCredentialReceived(credential);
  }

  @override
  Future<User?> signIn(AuthCredential credential) async {
    try {
      return (await auth.signInWithCredential(credential)).user;
    } on Exception catch (err) {
      value = AuthFailed(err);
    }
  }

  @override
  Future<void> link(AuthCredential credential) async {
    final user = auth.currentUser;

    if (user != null) {
      try {
        await user.linkWithCredential(credential);
      } on Exception catch (err) {
        value = AuthFailed(err);
      }
    } else {
      throw Exception(
          "Can't link the credential: no user is currently signed in");
    }
  }

  Future<void> onCredentialReceived(AuthCredential credential) async {
    try {
      switch (method) {
        case AuthMethod.signIn:
          final user = await signIn(credential);
          value = SignedIn(user!);
          break;
        case AuthMethod.link:
          await link(credential);
          break;
        default:
          throw Exception('$method is not supported by $runtimeType');
      }
    } on Exception catch (err) {
      value = AuthFailed(err);
    }
  }
}