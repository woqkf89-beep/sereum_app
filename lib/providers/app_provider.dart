import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/storage_service.dart';
import '../config/app_config.dart';

class AppProvider extends ChangeNotifier {
  UserProfile? _userProfile;
  final StorageService _storageService = StorageService();

  UserProfile? get userProfile => _userProfile;

  Future<void> loadUserProfile() async {
    final json = await _storageService.getJson('user_profile');
    if (json != null) {
      _userProfile = UserProfile.fromJson(json);
    } else {
      _userProfile = UserProfile(
        id: 'default_user',
        name: '관령이',
        hearts: AppConfig.initialHearts,
        isPremium: false,
      );
      await saveUserProfile();
    }
    notifyListeners();
  }

  Future<void> saveUserProfile() async {
    if (_userProfile != null) {
      await _storageService.saveJson('user_profile', _userProfile!.toJson());
    }
  }

  bool useHeart(int count) {
    if (_userProfile == null) return false;
    if (_userProfile!.hearts >= count) {
      _userProfile!.hearts -= count;
      saveUserProfile();
      notifyListeners();
      return true;
    }
    return false;
  }

  void addHearts(int count) {
    if (_userProfile == null) return;
    _userProfile!.hearts += count;
    saveUserProfile();
    notifyListeners();
  }

  void setPremium(bool premium) {
    if (_userProfile == null) return;
    _userProfile = UserProfile(
      id: _userProfile!.id,
      name: _userProfile!.name,
      hearts: _userProfile!.hearts,
      isPremium: premium,
      lastChatDate: _userProfile!.lastChatDate,
      dailyChatCount: _userProfile!.dailyChatCount,
    );
    saveUserProfile();
    notifyListeners();
  }
}