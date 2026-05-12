import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../db/database_helper.dart';

class ProfileProvider extends ChangeNotifier {
  List<Profile> _profiles = [];
  int _activeProfileId = 1;

  List<Profile> get profiles => _profiles;
  int get activeProfileId => _activeProfileId;
  Profile? get activeProfile =>
      _profiles.isEmpty ? null : _profiles.firstWhere(
        (p) => p.id == _activeProfileId,
        orElse: () => _profiles.first,
      );

  Future<void> load() async {
    _profiles = await DbHelper().getProfiles();
    final prefs = await SharedPreferences.getInstance();
    _activeProfileId = prefs.getInt('active_profile_id') ?? (_profiles.isNotEmpty ? _profiles.first.id! : 1);
    notifyListeners();
  }

  Future<void> setActive(int id) async {
    _activeProfileId = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('active_profile_id', id);
    notifyListeners();
  }

  Future<void> addProfile(String name, String emoji) async {
    final p = await DbHelper().insertProfile(Profile(name: name, emoji: emoji));
    _profiles.add(p);
    notifyListeners();
  }

  Future<void> deleteProfile(int id) async {
    if (_profiles.length <= 1) return;
    await DbHelper().deleteProfile(id);
    _profiles.removeWhere((p) => p.id == id);
    if (_activeProfileId == id) {
      await setActive(_profiles.first.id!);
    }
    notifyListeners();
  }
}
