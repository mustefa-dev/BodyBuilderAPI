import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/secure_storage.dart';
import '../data/auth_repository.dart';

class AuthState {
  final bool isLoggedIn;
  final String? userName;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.isLoggedIn = false,
    this.userName,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({bool? isLoggedIn, String? userName, bool? isLoading, String? error}) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      userName: userName ?? this.userName,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  Future<void> checkAuth() async {
    final token = await SecureStorage.getToken();
    final name = await SecureStorage.getUserName();
    if (token != null) {
      state = AuthState(isLoggedIn: true, userName: name);
    }
  }

  Future<bool> login(String phone, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = ref.read(authRepositoryProvider);
      final response = await repo.login(phone, password);
      await SecureStorage.saveAuth(
        token: response.token,
        fullName: response.fullName,
        userId: response.id,
      );
      state = AuthState(isLoggedIn: true, userName: response.fullName);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
      return false;
    }
  }

  Future<bool> register(String fullName, String phone, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.register(fullName, phone, password);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
      return false;
    }
  }

  Future<void> logout() async {
    await SecureStorage.clearAll();
    state = const AuthState();
  }

  String _parseError(dynamic e) {
    final str = e.toString();
    if (str.contains('Invalid phone number or password')) return 'Invalid phone number or password';
    if (str.contains('Phone number already registered')) return 'Phone number already registered';
    if (str.contains('SocketException') || str.contains('connection')) return 'No internet connection';
    return 'Something went wrong. Try again.';
  }
}
