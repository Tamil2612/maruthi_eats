import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/address_model.dart';
import '../services/auth_service.dart';

class AddressProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  List<AddressModel> _addresses = [];
  AddressModel? _selectedAddress;
  StreamSubscription? _subscription;
  late final StreamSubscription<User?> _authSubscription;

  List<AddressModel> get addresses => _addresses;
  AddressModel? get selectedAddress => _selectedAddress;

  AddressProvider() {
    _authSubscription = _authService.authStateChanges.listen(_bindUser);
  }

  void _bindUser(User? user) {
    _subscription?.cancel();
    _subscription = null;
    _addresses = [];
    _selectedAddress = null;

    if (user != null) {
      _subscription = _authService.watchAddresses(user.uid).listen((list) {
        _addresses = list;
        
        // Auto-select logic
        if (_selectedAddress == null && _addresses.isNotEmpty) {
          _selectedAddress = _addresses.first;
        } else if (_selectedAddress != null) {
          // If the selected address was deleted or updated, sync it
          final stillExists = _addresses.any((a) => a.id == _selectedAddress!.id);
          if (!stillExists) {
            _selectedAddress = _addresses.isNotEmpty ? _addresses.first : null;
          } else {
            // Update the selected address with latest data (e.g. if label changed)
            _selectedAddress = _addresses.firstWhere((a) => a.id == _selectedAddress!.id);
          }
        }
        notifyListeners();
      });
    }
    notifyListeners();
  }

  void selectAddress(AddressModel address) {
    _selectedAddress = address;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _authSubscription.cancel();
    super.dispose();
  }
}
