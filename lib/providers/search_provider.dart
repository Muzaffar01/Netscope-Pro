import 'package:flutter/material.dart';
import 'package:netscope/models/website_info.dart';
import 'package:netscope/services/api_service.dart';

enum SearchState { idle, loading, loaded, error }

class SearchProvider extends ChangeNotifier {
  SearchState _state = SearchState.idle;
  WebsiteInfo? _websiteInfo;
  String _errorMessage = '';
  String _currentDomain = '';
  double _loadingProgress = 0.0;

  SearchState get state => _state;
  WebsiteInfo? get websiteInfo => _websiteInfo;
  String get errorMessage => _errorMessage;
  String get currentDomain => _currentDomain;
  double get loadingProgress => _loadingProgress;

  final ApiService _apiService = ApiService();

  Future<void> searchWebsite(String domain) async {
    _currentDomain = _normalizeDomain(domain);
    _state = SearchState.loading;
    _loadingProgress = 0.0;
    _errorMessage = '';
    notifyListeners();

    try {
      // Simulate progress updates
      _updateProgress(0.1);
      final info = await _apiService.getWebsiteInfo(_currentDomain);
      _websiteInfo = info;
      _state = SearchState.loaded;
      _loadingProgress = 1.0;
    } catch (e) {
      _state = SearchState.error;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    }
    notifyListeners();
  }

  void _updateProgress(double value) {
    _loadingProgress = value;
    notifyListeners();
  }

  String _normalizeDomain(String input) {
    String domain = input.trim().toLowerCase();
    domain = domain.replaceAll(RegExp(r'^https?://'), '');
    domain = domain.replaceAll(RegExp(r'^www\.'), '');
    domain = domain.replaceAll(RegExp(r'/.*$'), '');
    return domain;
  }

  void reset() {
    _state = SearchState.idle;
    _websiteInfo = null;
    _errorMessage = '';
    _currentDomain = '';
    notifyListeners();
  }
}
